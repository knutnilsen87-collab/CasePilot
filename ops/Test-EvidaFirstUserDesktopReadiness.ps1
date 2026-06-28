param(
    [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path,
    [switch]$SkipOptionalStacks
)

$ErrorActionPreference = "Stop"

$results = New-Object System.Collections.Generic.List[object]

function Add-Result {
    param(
        [string]$Name,
        [string]$Command,
        [string]$WorkingDirectory,
        [string]$Status,
        [bool]$Required,
        [string]$Summary
    )

    $results.Add([pscustomobject]@{
        name = $Name
        command = $Command
        working_directory = $WorkingDirectory
        status = $Status
        required = $Required
        summary = $Summary
    })
}

function Invoke-ReadinessCommand {
    param(
        [string]$Name,
        [string]$WorkingDirectory,
        [scriptblock]$Script,
        [string]$CommandLabel,
        [bool]$Required = $true
    )

    Push-Location $WorkingDirectory
    try {
        & $Script
        if ($LASTEXITCODE -ne $null -and $LASTEXITCODE -ne 0) {
            throw "exit code $LASTEXITCODE"
        }
        Add-Result -Name $Name -Command $CommandLabel -WorkingDirectory $WorkingDirectory -Status "PASS" -Required $Required -Summary "passed"
    }
    catch {
        Add-Result -Name $Name -Command $CommandLabel -WorkingDirectory $WorkingDirectory -Status "FAIL" -Required $Required -Summary $_.Exception.Message
        if ($Required) {
            throw
        }
    }
    finally {
        Pop-Location
    }
}

function Test-FilePattern {
    param(
        [string]$Name,
        [string]$RelativePath,
        [string]$Pattern,
        [string]$Summary
    )

    $path = Join-Path $Root $RelativePath
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        Add-Result -Name $Name -Command "read $RelativePath" -WorkingDirectory $Root -Status "FAIL" -Required $true -Summary "missing file"
        throw "Missing required file: $RelativePath"
    }
    $content = Get-Content -LiteralPath $path -Raw
    if ($content -notmatch $Pattern) {
        Add-Result -Name $Name -Command "read $RelativePath" -WorkingDirectory $Root -Status "FAIL" -Required $true -Summary $Summary
        throw $Summary
    }
    Add-Result -Name $Name -Command "read $RelativePath" -WorkingDirectory $Root -Status "PASS" -Required $true -Summary $Summary
}

$desktop = Join-Path $Root "evida-core\desktop-tauri"
$tauri = Join-Path $desktop "src-tauri"

Invoke-ReadinessCommand -Name "desktop_tests" -WorkingDirectory $desktop -CommandLabel "npm.cmd test" -Script { npm.cmd test }
Invoke-ReadinessCommand -Name "desktop_build" -WorkingDirectory $desktop -CommandLabel "npm.cmd run build" -Script { npm.cmd run build }
Invoke-ReadinessCommand -Name "rust_check" -WorkingDirectory $tauri -CommandLabel "cargo check --locked" -Script { cargo check --locked }
Invoke-ReadinessCommand -Name "rust_tests" -WorkingDirectory $tauri -CommandLabel "cargo test --locked" -Script { cargo test --locked }
Invoke-ReadinessCommand -Name "release_artifact_verification" -WorkingDirectory $Root -CommandLabel "powershell -ExecutionPolicy Bypass -File ops\Test-EvidaRelease.ps1" -Script {
    powershell -ExecutionPolicy Bypass -File (Join-Path $Root "ops\Test-EvidaRelease.ps1")
}
Invoke-ReadinessCommand -Name "production_boundary" -WorkingDirectory $Root -CommandLabel "powershell -ExecutionPolicy Bypass -File ops\Verify-ProductionBoundary.ps1" -Script {
    powershell -ExecutionPolicy Bypass -File (Join-Path $Root "ops\Verify-ProductionBoundary.ps1")
}
Invoke-ReadinessCommand -Name "hardening_gate" -WorkingDirectory $Root -CommandLabel "powershell -ExecutionPolicy Bypass -File ops\Test-EvidaHardening.ps1" -Script {
    powershell -ExecutionPolicy Bypass -File (Join-Path $Root "ops\Test-EvidaHardening.ps1")
}

Test-FilePattern `
    -Name "replace_feature_disabled" `
    -RelativePath "evida-core\desktop-tauri\src\features\documentControl\documentControl.logic.ts" `
    -Pattern "PRODUCTION_GRADE_DOCUMENT_REPLACE_ENABLED\s*=\s*false" `
    -Summary "Erstatt fil remains disabled until production-grade supersede is approved."

Test-FilePattern `
    -Name "real_client_data_blocked" `
    -RelativePath "artifacts\first-user\status_bundle.first_user.final.json" `
    -Pattern '"real_client_data_allowed"\s*:\s*false' `
    -Summary "First-user status bundle keeps real client data blocked."

Test-FilePattern `
    -Name "visible_replace_disabled_copy" `
    -RelativePath "evida-core\desktop-tauri\src\App.tsx" `
    -Pattern "Erstatt fil er blokkert for denne testutgaven" `
    -Summary "UI includes visible disabled replacement copy."

Test-FilePattern `
    -Name "manual_runtime_smoke_checklist" `
    -RelativePath "docs\ACCEPTANCE_SMOKE_TEST.md" `
    -Pattern 'Current status:\s*`manual_required`' `
    -Summary "Runtime smoke is honestly marked manual_required until a human run attaches evidence."

Test-FilePattern `
    -Name "manual_runtime_screenshot_targets" `
    -RelativePath "docs\ACCEPTANCE_SMOKE_TEST.md" `
    -Pattern "05_document_control_replace_disabled\.png" `
    -Summary "Manual smoke checklist includes disabled replacement screenshot evidence."

Test-FilePattern `
    -Name "manual_smoke_template_exists" `
    -RelativePath "docs\first-user\manual-smoke-evidence-template.md" `
    -Pattern "smoke_result: blocked # pass \| fail \| blocked" `
    -Summary "Human-fillable manual smoke evidence template exists."

Test-FilePattern `
    -Name "manual_smoke_result_exists" `
    -RelativePath "docs\first-user\manual-smoke-evidence-result.md" `
    -Pattern "smoke_result:\s*(pass|fail|blocked)" `
    -Summary "Manual smoke evidence result file exists and declares a result state."

$manualSmokeResultPath = Join-Path $Root "docs\first-user\manual-smoke-evidence-result.md"
$manualSmokeResultText = Get-Content -LiteralPath $manualSmokeResultPath -Raw
$manualSmokeMatch = [regex]::Match($manualSmokeResultText, "(?m)^\s*smoke_result:\s*(pass|fail|blocked)\s*$")
if (-not $manualSmokeMatch.Success) {
    throw "manual-smoke-evidence-result.md must contain smoke_result: pass|fail|blocked"
}
$manualSmokeResult = $manualSmokeMatch.Groups[1].Value
foreach ($field in @("evaluator_name:", "date:", "build_manifest_timestamp:", "release_manifest_sha256:", "app_version:", "machine:", "windows_version:", "screenshots_folder:", "failed_step:", "notes:")) {
    if ($manualSmokeResultText -notmatch [regex]::Escape($field)) {
        throw "manual-smoke-evidence-result.md missing required field: $field"
    }
}
if ($manualSmokeResult -eq "pass") {
    $screenshotsFolderMatch = [regex]::Match($manualSmokeResultText, "(?m)^\s*screenshots_folder:\s*(\S.+)$")
    if (-not $screenshotsFolderMatch.Success) {
        throw "manual smoke cannot pass without screenshots_folder"
    }
    if ($manualSmokeResultText -match "(?m)^\s*status:\s*(fail|blocked)\s*$") {
        throw "manual smoke cannot pass while checklist contains fail/blocked statuses"
    }
    Add-Result -Name "manual_runtime_smoke_result" -Command "read docs\first-user\manual-smoke-evidence-result.md" -WorkingDirectory $Root -Status "PASS" -Required $false -Summary "manual smoke result file declares pass"
}
else {
    Add-Result -Name "manual_runtime_smoke_result" -Command "read docs\first-user\manual-smoke-evidence-result.md" -WorkingDirectory $Root -Status "BLOCKED" -Required $false -Summary "manual smoke result is $manualSmokeResult"
}

$releaseManifestPath = Join-Path $Root "Evida Release\release-manifest.json"
if (-not (Test-Path -LiteralPath $releaseManifestPath -PathType Leaf)) {
    throw "Missing release manifest: $releaseManifestPath"
}
$releaseManifest = Get-Content -LiteralPath $releaseManifestPath -Raw | ConvertFrom-Json
if ($releaseManifest.real_client_data_allowed -ne $false) {
    throw "release-manifest.json must keep real_client_data_allowed=false"
}
Add-Result -Name "release_manifest_real_client_data_blocked" -Command "read Evida Release\release-manifest.json" -WorkingDirectory $Root -Status "PASS" -Required $true -Summary "release manifest exists and real_client_data_allowed=false"

$trackedSecretFiles = @(
    git -C $Root ls-files ".env*" "*.env" "*.key" "*.pem" "*.pfx" "*.crt" 2>$null
)
if ($trackedSecretFiles.Count -gt 0) {
    Add-Result -Name "tracked_secret_file_check" -Command "git ls-files .env* *.env *.key *.pem *.pfx *.crt" -WorkingDirectory $Root -Status "FAIL" -Required $true -Summary ($trackedSecretFiles -join ", ")
    throw "Tracked secret-like files found."
}
Add-Result -Name "tracked_secret_file_check" -Command "git ls-files .env* *.env *.key *.pem *.pfx *.crt" -WorkingDirectory $Root -Status "PASS" -Required $true -Summary "no tracked env/key/certificate files matched"

if ($SkipOptionalStacks) {
    Add-Result -Name "python_ai_tests" -Command "python -m pytest" -WorkingDirectory (Join-Path $Root "evida-core\ai-engine") -Status "NOT_RUN" -Required $false -Summary "skipped by parameter"
    Add-Result -Name "spring_maven_tests" -Command "mvn test" -WorkingDirectory (Join-Path $Root "evida-core\services\saksrom-api") -Status "NOT_RUN" -Required $false -Summary "skipped by parameter"
}
else {
    Invoke-ReadinessCommand -Name "python_ai_tests" -WorkingDirectory (Join-Path $Root "evida-core\ai-engine") -CommandLabel "python -m pytest" -Required $false -Script { python -m pytest }
    $mvn = Get-Command mvn -ErrorAction SilentlyContinue
    if ($mvn) {
        Invoke-ReadinessCommand -Name "spring_maven_tests" -WorkingDirectory (Join-Path $Root "evida-core\services\saksrom-api") -CommandLabel "mvn test" -Required $false -Script { mvn test }
    }
    else {
        Add-Result -Name "spring_maven_tests" -Command "mvn test" -WorkingDirectory (Join-Path $Root "evida-core\services\saksrom-api") -Status "BLOCKED" -Required $false -Summary "mvn not found on PATH"
    }
}

$requiredFailures = @($results | Where-Object { $_.required -and $_.status -ne "PASS" })
$verdict = if ($requiredFailures.Count -eq 0) { "PASS_CORE_TEST_DATA_READY_CHECKS" } else { "FAIL_REQUIRED_CHECKS" }

[pscustomobject]@{
    gate = "first-user-desktop-readiness"
    verdict = $verdict
    first_user_scope = "test-data-only"
    real_client_data_allowed = $false
    replacement_enabled = $false
    generated_at = (Get-Date).ToString("o")
    results = $results
} | ConvertTo-Json -Depth 8

if ($requiredFailures.Count -gt 0) {
    exit 1
}
