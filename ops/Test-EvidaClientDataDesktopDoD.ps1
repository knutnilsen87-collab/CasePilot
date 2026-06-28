param(
    [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path,
    [switch]$SkipWindowsDiagnostics
)

$ErrorActionPreference = "Stop"

$firstUserDir = Join-Path $Root "artifacts\first-user"
New-Item -ItemType Directory -Force -Path $firstUserDir | Out-Null

function Write-JsonNoBom {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)]$Data
    )

    $json = $Data | ConvertTo-Json -Depth 14
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

function New-BlockedArtifact {
    param(
        [string]$Name,
        [string]$Reason,
        [string[]]$RequiredEvidence = @()
    )

    return [ordered]@{
        generated_at = $script:timestamp
        status = "blocked"
        verdict = "blocked"
        name = $Name
        blocker = $Reason
        required_evidence = $RequiredEvidence
        real_client_data_allowed = $false
    }
}

function Write-NamedArtifact {
    param(
        [string]$FileName,
        $Data
    )

    Write-JsonNoBom -Path (Join-Path $firstUserDir $FileName) -Data $Data
    return "artifacts/first-user/$FileName"
}

function Test-ContainsText {
    param(
        [string]$Path,
        [string]$Pattern
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        return $false
    }

    $match = Select-String -LiteralPath $Path -Pattern $Pattern -SimpleMatch -Quiet -ErrorAction SilentlyContinue
    return [bool]$match
}

$script:timestamp = (Get-Date).ToUniversalTime().ToString("o")

if (-not $SkipWindowsDiagnostics) {
    & (Join-Path $PSScriptRoot "Test-EvidaWindowsPolicyDiagnostics.ps1") -Root $Root | Out-Null
}

$artifactRefs = New-Object System.Collections.Generic.List[string]

$dbSource = Join-Path $Root "evida-core\desktop-tauri\src-tauri\src\db.rs"
$sqlCipherMention = Test-ContainsText -Path $dbSource -Pattern "SQLCipher"
$fieldEncryptionMention = Test-ContainsText -Path $dbSource -Pattern "AES-256-GCM"
$rawStorage = [ordered]@{
    generated_at = $timestamp
    status = "blocked"
    verdict = "blocked"
    inspected_database = $false
    marker_client_data_used = $false
    source_static_checks = [ordered]@{
        db_rs_exists = Test-Path -LiteralPath $dbSource
        sqlcipher_mentioned = $sqlCipherMention
        field_encryption_mentioned = $fieldEncryptionMention
    }
    blocker = "No raw-storage inspection was run against a synthetic client-data database with required markers."
    required_markers = @(
        "EVIDA_SECRET_MARKER_CLIENT_NAME_123",
        "EVIDA_SECRET_MARKER_CASE_FACT_456",
        "EVIDA_SECRET_MARKER_PERSONAL_NUMBER_789",
        "EVIDA_SECRET_MARKER_PRIVILEGED_NOTE_ABC"
    )
}
$artifactRefs.Add((Write-NamedArtifact -FileName "raw_storage_inspection.json" -Data $rawStorage))

$encryption = [ordered]@{
    generated_at = $timestamp
    status = "blocked"
    verdict = "blocked"
    field_encryption_source_present = $fieldEncryptionMention
    sqlcipher_requirement_source_present = $sqlCipherMention
    os_keychain_or_managed_secret_verified = $false
    database_file_encryption_verified = $false
    blocker = "Field-encryption code exists, but full client-data storage encryption and key-management proof is not complete."
}
$artifactRefs.Add((Write-NamedArtifact -FileName "encryption_verification.json" -Data $encryption))

$artifactRefs.Add((Write-NamedArtifact -FileName "backup_restore_result.json" -Data ([ordered]@{
    generated_at = $timestamp
    status = "partial"
    verdict = "blocked"
    automated_tests_referenced = @("cargo db backup/restore tests when available through desktop validation")
    client_data_marker_restore_verified = $false
    blocker = "Backup/restore needs a documented synthetic client-data marker run before real client data."
})))

$artifactRefs.Add((Write-NamedArtifact -FileName "deletion_retention_result.json" -Data (New-BlockedArtifact -Name "deletion_retention" -Reason "Client-data deletion, retention, and audit proof has not been executed end-to-end." -RequiredEvidence @("delete imported case", "verify source/text/index removal", "verify audit trail", "verify retention policy"))))

$artifactRefs.Add((Write-NamedArtifact -FileName "provider_policy_result.json" -Data ([ordered]@{
    generated_at = $timestamp
    status = "partial"
    verdict = "blocked"
    external_ai_default_off = "referenced by first-user invariants"
    client_data_provider_allowlist_verified = $false
    blocker = "Provider routing is not yet approved for real client data."
    real_client_data_allowed = $false
})))

$markers = @(
    "EVIDA_SECRET_MARKER_CLIENT_NAME_123",
    "EVIDA_SECRET_MARKER_CASE_FACT_456",
    "EVIDA_SECRET_MARKER_PERSONAL_NUMBER_789",
    "EVIDA_SECRET_MARKER_PRIVILEGED_NOTE_ABC"
)

$scanFiles = @()
$desktopRoot = Join-Path $Root "evida-core\desktop-tauri"
if (Test-Path -LiteralPath $desktopRoot) {
    $scanFiles += Get-ChildItem -LiteralPath $desktopRoot -File -Filter "*.log" -ErrorAction SilentlyContinue
    $scanFiles += Get-ChildItem -LiteralPath $desktopRoot -File -Filter "*.txt" -ErrorAction SilentlyContinue
}

$artifactRuntimeRoots = @(
    (Join-Path $Root "artifacts\production-dod"),
    (Join-Path $Root "artifacts\security")
)

foreach ($runtimeRoot in $artifactRuntimeRoots) {
    if (Test-Path -LiteralPath $runtimeRoot) {
        $scanFiles += Get-ChildItem -LiteralPath $runtimeRoot -Recurse -File -Filter "*.log" -ErrorAction SilentlyContinue
        $scanFiles += Get-ChildItem -LiteralPath $runtimeRoot -Recurse -File -Filter "*.json" -ErrorAction SilentlyContinue
        $scanFiles += Get-ChildItem -LiteralPath $runtimeRoot -Recurse -File -Filter "*.txt" -ErrorAction SilentlyContinue
    }
}

$leaks = @()
foreach ($file in $scanFiles) {
    foreach ($marker in $markers) {
        if (Select-String -LiteralPath $file.FullName -Pattern $marker -SimpleMatch -Quiet -ErrorAction SilentlyContinue) {
            $leaks += [ordered]@{
                file = $file.FullName.Replace($Root, "").TrimStart("\")
                marker = $marker
            }
        }
    }
}

$runtimeLogScan = [ordered]@{
    generated_at = $timestamp
    status = if ($leaks.Count -eq 0) { "blocked" } else { "fail" }
    verdict = if ($leaks.Count -eq 0) { "blocked" } else { "fail" }
    scanned_files = @($scanFiles | ForEach-Object { $_.FullName.Replace($Root, "").TrimStart("\") })
    marker_leaks_found = @($leaks)
    marker_flow_executed = $false
    blocker = if ($leaks.Count -eq 0) { "No leaks found in scanned runtime artifacts, but the required synthetic marker import flow has not been executed." } else { "Sensitive marker text was found in runtime artifacts." }
}
$artifactRefs.Add((Write-NamedArtifact -FileName "runtime_sensitive_log_scan.json" -Data $runtimeLogScan))

$artifactRefs.Add((Write-NamedArtifact -FileName "document_upload_final_result.json" -Data ([ordered]@{
    generated_at = $timestamp
    status = "partial"
    verdict = "blocked"
    referenced_evidence = @(
        "artifacts/first-user/document-upload-stress-report.json",
        "artifacts/first-user/evidence.first_user.current.json"
    )
    remaining_blockers = @(
        "manual desktop smoke with client-data-shaped synthetic package",
        "source coverage and failed-document AI exclusion proof",
        "password/corrupt/OCR-needed flows captured as current evidence"
    )
    real_client_data_allowed = $false
})))

$artifactRefs.Add((Write-NamedArtifact -FileName "manual_review_result.json" -Data (New-BlockedArtifact -Name "manual_review" -Reason "Manual review flow has not been captured on the release desktop build." -RequiredEvidence @("open imported package", "inspect sources", "review warnings", "confirm no unsupported AI claims"))))

$artifactRefs.Add((Write-NamedArtifact -FileName "import_eta_result.json" -Data ([ordered]@{
    generated_at = $timestamp
    status = "partial"
    verdict = "blocked"
    ui_support_present = "referenced by current frontend import status work"
    release_build_eta_smoke_verified = $false
    blocker = "ETA/status UX must be captured from a release build import smoke."
})))

$artifactRefs.Add((Write-NamedArtifact -FileName "ai_multi_doc_eval.json" -Data (New-BlockedArtifact -Name "ai_multi_doc_eval" -Reason "Multi-document grounded-answer evaluation has not passed with current release evidence." -RequiredEvidence @("multi-document case", "conflicting facts", "missing source refusal", "citation/source coverage snapshot"))))

$artifactRefs.Add((Write-NamedArtifact -FileName "prompt_injection_eval.json" -Data ([ordered]@{
    generated_at = $timestamp
    status = "partial"
    verdict = "blocked"
    existing_invariant_reference = "INV-AI-004 is currently pass in first-user invariant evaluation"
    release_client_data_eval_verified = $false
    blocker = "Prompt injection behavior still needs release-client-data evaluation evidence."
})))

$artifactRefs.Add((Write-NamedArtifact -FileName "unsupported_claim_eval.json" -Data ([ordered]@{
    generated_at = $timestamp
    status = "partial"
    verdict = "blocked"
    existing_invariant_reference = "source-bound AI behavior is covered by first-user invariants"
    multi_doc_release_eval_verified = $false
    blocker = "Unsupported-claim behavior must be verified in the multi-document release evaluation."
})))

$artifactRefs.Add((Write-NamedArtifact -FileName "retrieval_snapshot_eval.json" -Data ([ordered]@{
    generated_at = $timestamp
    status = "partial"
    verdict = "blocked"
    source_coverage_snapshot_present = "referenced by first-user evidence where available"
    release_snapshot_current = $false
    blocker = "Retrieval/source coverage snapshot must be regenerated from the release build and documented."
})))

$artifactRefs.Add((Write-NamedArtifact -FileName "audit_coverage_result.json" -Data (New-BlockedArtifact -Name "audit_coverage" -Reason "Client-data audit coverage is not complete across import, AI answer, export, delete, and policy changes." -RequiredEvidence @("import audit", "AI answer audit", "export audit", "delete audit", "provider policy audit"))))

$artifactRefs.Add((Write-NamedArtifact -FileName "export_smoke_result.json" -Data (New-BlockedArtifact -Name "export_smoke" -Reason "Export/redaction smoke has not been captured on a release build." -RequiredEvidence @("export allowed content", "redaction policy", "audit event", "no hidden source leakage"))))

$approvalFiles = @{
    "client_data_pilot_approval.json" = "Client/data owner pilot approval"
    "engineering_approval.json" = "Engineering approval"
    "product_approval.json" = "Product approval"
    "security_privacy_approval.json" = "Security/privacy approval"
}

foreach ($entry in $approvalFiles.GetEnumerator()) {
    $artifactRefs.Add((Write-NamedArtifact -FileName $entry.Key -Data ([ordered]@{
        generated_at = $timestamp
        status = "missing"
        approved = $false
        authority = $entry.Value
        required_before_real_client_data = $true
        blocker = "No approval artifact is present."
    })))
}

$artifactRefs.Add("artifacts/first-user/signature_verification.json")
$artifactRefs.Add("artifacts/first-user/windows_policy_diagnostics.current.json")
$artifactRefs.Add("artifacts/first-user/windows_managed_workstation_smoke.json")
$artifactRefs.Add("artifacts/first-user/braathe_approval.json")

$phaseResults = @(
    [ordered]@{ phase = 0; name = "contract installed"; status = "pass" },
    [ordered]@{ phase = 1; name = "windows policy and signing diagnostics"; status = "blocked" },
    [ordered]@{ phase = 2; name = "client data storage safety"; status = "blocked" },
    [ordered]@{ phase = 3; name = "runtime log marker scan"; status = $runtimeLogScan.status },
    [ordered]@{ phase = 4; name = "document upload final closure"; status = "blocked" },
    [ordered]@{ phase = 5; name = "multi-document source-bound AI"; status = "blocked" },
    [ordered]@{ phase = 6; name = "audit/provenance coverage"; status = "blocked" },
    [ordered]@{ phase = 7; name = "export/redaction"; status = "blocked" },
    [ordered]@{ phase = 8; name = "security/release gate"; status = "blocked" },
    [ordered]@{ phase = 9; name = "clean machine smoke"; status = "blocked" },
    [ordered]@{ phase = 10; name = "approvals"; status = "blocked" },
    [ordered]@{ phase = 11; name = "final readiness gate"; status = "blocked" }
)

$result = [ordered]@{
    generated_at = $timestamp
    verdict = "blocked"
    real_client_data_allowed = $false
    production_ready = $false
    phase_results = $phaseResults
    artifacts = @($artifactRefs | Select-Object -Unique)
    next_unblockers = @(
        "Sign all Windows release binaries/installers.",
        "Run managed Windows workstation smoke under Jussys/Braathe policy.",
        "Run synthetic client-data marker import and raw-storage/log inspections.",
        "Complete multi-document AI, audit, export, release security, and formal approvals."
    )
}

Write-NamedArtifact -FileName "client_data_desktop_dod_result.json" -Data $result | Out-Null
Write-Output ($result | ConvertTo-Json -Depth 12)
