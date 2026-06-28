param(
    [string]$SuiteRoot = (Join-Path (Resolve-Path (Join-Path $PSScriptRoot "..")).Path "testpakker\Evida_document_upload_stress_suite_medium_to_extreme"),
    [string]$ZipPath = (Join-Path (Resolve-Path (Join-Path $PSScriptRoot "..")).Path "testpakker\Evida_document_upload_stress_suite_medium_to_extreme.zip"),
    [string]$Level = "02_hard_volume_and_mixed_formats",
    [string]$ManifestPath = "",
    [string]$ReportPath = (Join-Path (Resolve-Path (Join-Path $PSScriptRoot "..")).Path "artifacts\document-upload-stress\evida-document-upload-stress-level02-report.json")
)

$ErrorActionPreference = "Stop"

$Root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$Desktop = Join-Path $Root "evida-core\desktop-tauri"

if (-not (Test-Path -LiteralPath $SuiteRoot)) {
    if (Test-Path -LiteralPath $ZipPath) {
        $SuiteParent = Split-Path -Parent $SuiteRoot
        New-Item -ItemType Directory -Force -Path $SuiteParent | Out-Null
        Expand-Archive -LiteralPath $ZipPath -DestinationPath $SuiteParent -Force
    }
}

if (-not (Test-Path -LiteralPath $SuiteRoot)) {
    throw "Stress suite not found. Place or extract it at: testpakker\Evida_document_upload_stress_suite_medium_to_extreme\"
}

if ([string]::IsNullOrWhiteSpace($ManifestPath)) {
    $ManifestPath = Join-Path $SuiteRoot "stress_suite_truth_manifest.json"
}
if (-not (Test-Path -LiteralPath $ManifestPath)) {
    throw "Stress truth manifest not found: $ManifestPath"
}

$Manifest = Get-Content -LiteralPath $ManifestPath -Raw | ConvertFrom-Json
$Expected = $Manifest.levels.$Level
if ($null -eq $Expected) {
    throw "Stress level '$Level' not found in $ManifestPath"
}

New-Item -ItemType Directory -Force -Path (Split-Path -Parent $ReportPath) | Out-Null
$env:EVIDA_DOCUMENT_STRESS_SUITE_DIR = (Resolve-Path $SuiteRoot).Path
$env:EVIDA_DOCUMENT_STRESS_LEVEL = $Level
$env:EVIDA_DOCUMENT_STRESS_REPORT = $ReportPath

Push-Location $Desktop
try {
    cargo test --manifest-path src-tauri\Cargo.toml evida_document_upload_stress_suite_matches_truth_manifest -- --ignored --nocapture
    if ($LASTEXITCODE -ne 0) {
        throw "Document upload stress test failed. See $ReportPath"
    }
}
finally {
    Pop-Location
    Remove-Item Env:\EVIDA_DOCUMENT_STRESS_LEVEL -ErrorAction SilentlyContinue
}

if (-not (Test-Path -LiteralPath $ReportPath)) {
    throw "Stress report was not produced: $ReportPath"
}

$Report = Get-Content -LiteralPath $ReportPath -Raw | ConvertFrom-Json
$Failures = @()

if ([int]$Report.files_tested -ne [int]$Expected.file_count) {
    $Failures += "files_tested expected $($Expected.file_count), actual $($Report.files_tested)"
}
if ([Math]::Abs([int]$Report.total_pages - [int]$Expected.expected_pages) -gt 2) {
    $Failures += "total_pages expected close to $($Expected.expected_pages), actual $($Report.total_pages)"
}
if ([int]$Report.pages_requires_ocr -ne [int]$Expected.expected_ocr_pages) {
    $Failures += "pages_requires_ocr expected $($Expected.expected_ocr_pages), actual $($Report.pages_requires_ocr)"
}
if ([Math]::Abs([int]$Report.pages_with_text - [int]$Expected.expected_text_layer_pages) -gt 2) {
    $Failures += "pages_with_text expected close to $($Expected.expected_text_layer_pages), actual $($Report.pages_with_text)"
}
if ([int]$Report.problem_files -ne [int]$Expected.expected_problem_files) {
    $Failures += "problem_files expected $($Expected.expected_problem_files), actual $($Report.problem_files)"
}
if ([int]$Report.user_attention_count -ne [int]$Expected.expected_problem_files) {
    $Failures += "user_attention_count expected true exceptions $($Expected.expected_problem_files), actual $($Report.user_attention_count)"
}
if ([int]$Report.source_ready_files -lt 100) {
    $Failures += "source_ready_files expected at least 100, actual $($Report.source_ready_files)"
}
if ([double]$Report.source_coverage_percent -lt 90) {
    $Failures += "source_coverage_percent expected above 90, actual $($Report.source_coverage_percent)"
}
if ([int]$Report.deviation_count -ne 0) {
    $Failures += "deviation_count expected 0, actual $($Report.deviation_count)"
}

$UnsupportedFiles = 0
if ($null -ne $Report.actual_status_counts -and $null -ne $Report.actual_status_counts.unsupported) {
    $UnsupportedFiles = [int]$Report.actual_status_counts.unsupported
}

$Summary = [ordered]@{
    level = $Level
    total_files_seen = [int]$Report.files_tested
    total_files_accounted_for = [int]$Report.files_tested
    total_pages = [int]$Report.total_pages
    text_layer_pages = [int]$Report.pages_with_text
    ocr_needed_pages = [int]$Report.pages_requires_ocr
    ocr_succeeded_pages = 0
    source_ready_files = [int]$Report.source_ready_files
    source_ready_pages = [int]$Report.source_ready_pages
    exception_problem_files = [int]$Report.problem_files
    unsupported_files = $UnsupportedFiles
    kildedekning = [double]$Report.source_coverage_percent
    user_attention_count = [int]$Report.user_attention_count
    report_path = $ReportPath
}

if ($Failures.Count -gt 0) {
    $Summary.failures = $Failures
    $Summary | ConvertTo-Json -Depth 8
    throw "Document upload stress level '$Level' failed acceptance: $($Failures -join '; ')"
}

$Summary.status = "PASS"
$Summary | ConvertTo-Json -Depth 8
