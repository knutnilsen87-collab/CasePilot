param(
    [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
)

$ErrorActionPreference = "Stop"

$firstUserDir = Join-Path $Root "artifacts\first-user"
$releaseDir = Join-Path $Root "Evida Release"
New-Item -ItemType Directory -Force -Path $firstUserDir | Out-Null

function Write-JsonNoBom {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)]$Data
    )

    $json = $Data | ConvertTo-Json -Depth 12
    $encoding = [System.Text.UTF8Encoding]::new($false)
    [System.IO.File]::WriteAllText($Path, $json, $encoding)
}

function Read-JsonIfPresent {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) {
        return $null
    }

    return Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
}

function Get-StatusFromBool {
    param([bool]$Value)
    if ($Value) { return "pass" }
    return "blocked"
}

$timestamp = (Get-Date).ToUniversalTime().ToString("o")
$manifestPath = Join-Path $releaseDir "release-manifest.json"
$manifest = Read-JsonIfPresent -Path $manifestPath

$manifestChecks = [ordered]@{
    exists = [bool]$manifest
    product_is_evida = $false
    real_client_data_allowed_false = $false
    has_sha256sums = $false
    raw_app_field_present = $false
}

if ($manifest) {
    $manifestChecks.product_is_evida = ($manifest.PSObject.Properties.Name -contains "product") -and ($manifest.product -eq "Evida")
    $manifestChecks.real_client_data_allowed_false = ($manifest.PSObject.Properties.Name -contains "real_client_data_allowed") -and ($manifest.real_client_data_allowed -eq $false)
    $manifestChecks.has_sha256sums = ($manifest.PSObject.Properties.Name -contains "sha256sums") -and [bool]$manifest.sha256sums
    $manifestChecks.raw_app_field_present = ($manifest.PSObject.Properties.Name -contains "app")
}

$releaseCandidates = @(
    "Evida.exe",
    "Evida installer.exe",
    "Evida installer.msi",
    "Evida_0.1.0_x64-setup.exe",
    "Evida_0.1.0_x64_en-US.msi"
)

$signatureResults = foreach ($candidate in $releaseCandidates) {
    $path = Join-Path $releaseDir $candidate
    if (-not (Test-Path -LiteralPath $path)) {
        [ordered]@{
            file = $candidate
            exists = $false
            status = "missing"
            signer = $null
            timestamp = $null
        }
        continue
    }

    $signature = Get-AuthenticodeSignature -LiteralPath $path
    [ordered]@{
        file = $candidate
        exists = $true
        status = [string]$signature.Status
        signer = if ($signature.SignerCertificate) { $signature.SignerCertificate.Subject } else { $null }
        timestamp = if ($signature.TimeStamperCertificate) { $signature.TimeStamperCertificate.Subject } else { $null }
    }
}

$existingSignatures = @($signatureResults | Where-Object { $_.exists })
$allExistingSigned = ($existingSignatures.Count -gt 0) -and -not [bool]($existingSignatures | Where-Object { $_.status -ne "Valid" } | Select-Object -First 1)

$releaseRoot = if (Test-Path -LiteralPath $releaseDir) { [System.IO.Path]::GetPathRoot((Resolve-Path -LiteralPath $releaseDir).Path) } else { $null }
$localDiskCheck = [ordered]@{
    release_dir = $releaseDir
    exists = Test-Path -LiteralPath $releaseDir
    root = $releaseRoot
    is_local_drive_shape = if ($releaseRoot) { $releaseRoot -match "^[A-Za-z]:\\$" } else { $false }
}

$defenderProbe = [ordered]@{
    collected = $false
    status = "not_available"
    am_service_enabled = $null
    real_time_protection_enabled = $null
}

try {
    $defender = Get-MpComputerStatus -ErrorAction Stop
    $defenderProbe.collected = $true
    $defenderProbe.status = "collected"
    $defenderProbe.am_service_enabled = [bool]$defender.AMServiceEnabled
    $defenderProbe.real_time_protection_enabled = [bool]$defender.RealTimeProtectionEnabled
}
catch {
    $defenderProbe.status = "blocked_or_unavailable"
}

$appLockerProbe = [ordered]@{
    collected = $false
    status = "not_available"
    rule_collections = @()
}

try {
    $policy = Get-AppLockerPolicy -Effective -ErrorAction Stop
    $appLockerProbe.collected = $true
    $appLockerProbe.status = "collected"
    $appLockerProbe.rule_collections = @($policy.RuleCollections | ForEach-Object { $_.CollectionType.ToString() })
}
catch {
    $appLockerProbe.status = "blocked_or_unavailable"
}

$manifestPass = $manifestChecks.exists -and $manifestChecks.product_is_evida -and $manifestChecks.real_client_data_allowed_false -and $manifestChecks.has_sha256sums
$signatureStatus = if ($allExistingSigned) { "pass" } else { "blocked" }
$policyStatus = if ($localDiskCheck.exists -and $localDiskCheck.is_local_drive_shape -and $manifestPass -and $allExistingSigned -and $appLockerProbe.collected) { "pass" } else { "blocked" }

$signatureArtifact = [ordered]@{
    generated_at = $timestamp
    status = $signatureStatus
    verdict = $signatureStatus
    release_dir = $releaseDir
    signatures = @($signatureResults)
    required_for_client_data = "All distributable executables/installers must have a valid publisher signature before real client data."
    blocker = if ($signatureStatus -eq "blocked") { "One or more release binaries are missing or not Authenticode Valid." } else { $null }
}

$diagnosticsArtifact = [ordered]@{
    generated_at = $timestamp
    status = $policyStatus
    verdict = $policyStatus
    release_manifest = [ordered]@{
        path = $manifestPath
        checks = $manifestChecks
    }
    release_location = $localDiskCheck
    defender = $defenderProbe
    applocker = $appLockerProbe
    wdac = [ordered]@{
        collected = $false
        status = "manual_required"
        note = "WDAC/Intune/Braathe policy validation must be captured on the managed target workstation."
    }
    blockers = @(
        if (-not $manifestPass) { "Release manifest is missing required client-data fields or checksum metadata." }
        if (-not $allExistingSigned) { "Release binaries are not all Authenticode Valid." }
        if (-not $appLockerProbe.collected) { "Effective AppLocker/managed execution policy was not collected." }
    )
}

$managedSmokeArtifact = [ordered]@{
    generated_at = $timestamp
    status = "blocked"
    verdict = "blocked"
    target = "managed Windows workstation with Jussys/Braathe policy"
    executed_on_target = $false
    steps = @(
        [ordered]@{ name = "install signed release"; status = "not_run" },
        [ordered]@{ name = "launch under policy"; status = "not_run" },
        [ordered]@{ name = "import synthetic case package"; status = "not_run" },
        [ordered]@{ name = "verify no client data leaves approved storage"; status = "not_run" }
    )
    blocker = "Requires access to the managed target workstation and organization policy context."
}

$approvalArtifact = [ordered]@{
    generated_at = $timestamp
    status = "missing"
    approved = $false
    authority = "Braathe/Jussys IT"
    required_before_real_client_data = $true
    blocker = "No signed managed-workstation approval artifact is present."
}

Write-JsonNoBom -Path (Join-Path $firstUserDir "signature_verification.json") -Data $signatureArtifact
Write-JsonNoBom -Path (Join-Path $firstUserDir "windows_policy_diagnostics.current.json") -Data $diagnosticsArtifact
Write-JsonNoBom -Path (Join-Path $firstUserDir "windows_managed_workstation_smoke.json") -Data $managedSmokeArtifact
Write-JsonNoBom -Path (Join-Path $firstUserDir "braathe_approval.json") -Data $approvalArtifact

$result = [ordered]@{
    generated_at = $timestamp
    verdict = $policyStatus
    artifacts = @(
        "artifacts/first-user/signature_verification.json",
        "artifacts/first-user/windows_policy_diagnostics.current.json",
        "artifacts/first-user/windows_managed_workstation_smoke.json",
        "artifacts/first-user/braathe_approval.json"
    )
}

Write-Output ($result | ConvertTo-Json -Depth 8)
