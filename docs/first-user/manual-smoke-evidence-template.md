# Evida Manual Runtime Smoke Evidence Template

Purpose: capture human evidence for the first-user/test-data desktop release candidate.

Do not use real client data. Use only synthetic, redacted, or approved test documents.

This template does not approve production use, client data, external AI with raw documents, or `Erstatt fil`.

## Metadata

```yaml
evaluator_name:
date:
build_manifest_timestamp:
release_manifest_sha256:
app_version:
machine:
windows_version:
smoke_result: blocked # pass | fail | blocked
screenshots_folder:
failed_step:
notes:
```

## Build Evidence

- Release manifest: `Evida Release/release-manifest.json`
- Start command: `Start Evida.bat`
- Direct app command: `Evida Release\Evida.exe`
- Required manifest truth: `real_client_data_allowed=false`
- Required replacement truth: `Erstatt fil` disabled

## Checklist

Fill every status as `pass`, `fail`, `blocked`, or `not_applicable`.

```yaml
checklist:
  launch:
    status:
    screenshot: 01_intro_launch.png
    notes:
  first_user_orientation:
    status:
    screenshot: 02_first_user_orientation.png
    notes:
  case_creation_or_opening:
    status:
    screenshot: 03_case_created.png
    notes:
  document_import:
    status:
    screenshot: 04_document_import_progress.png
    notes:
  ocr_or_manual_review_state:
    status:
    screenshot: 05_ocr_manual_review_state.png
    notes:
  document_control_replace_disabled:
    status:
    screenshot: 06_document_control_replace_disabled.png
    notes:
  source_overview_or_search:
    status:
    screenshot: 07_source_overview_search.png
    notes:
  saksrom_source_bound_dialogue:
    status:
    screenshot: 08_saksrom_source_answer.png
    notes:
  settings_security_privacy:
    status:
    screenshot: 09_settings_security_privacy.png
    notes:
  theme_accessibility_basics:
    status:
    screenshot: 10_keyboard_focus_or_theme.png
    notes:
  export_or_diagnostics:
    status:
    screenshot: 11_export_diagnostics.png
    notes:
```

## Expected User-Visible Evidence

### 1. Launch

- Start with `Start Evida.bat` or `Evida Release\Evida.exe`.
- Expected: Evida opens without terminal-only failure.
- Screenshot: `01_intro_launch.png`.

### 2. First-User Orientation

- Expected: UI clearly says this is test-data/pre-alpha/evaluation/local mode and not approved for real client data.
- Screenshot: `02_first_user_orientation.png`.

### 3. Case Creation or Opening

- Create or open a synthetic/redacted test case.
- Expected: active case is visible and navigation is understandable.
- Screenshot: `03_case_created.png`.

### 4. Document Import

- Import safe test documents only.
- Expected: progress/status is visible and understandable.
- Screenshot: `04_document_import_progress.png`.

### 5. OCR or Manual Review State

- Use at least one image/scan/unsupported/corrupt-safe test fixture if available.
- Expected: incomplete/needs-review state is explicit; unsafe material is not source-ready.
- Screenshot: `05_ocr_manual_review_state.png`.

### 6. Document Control

- Open Dokumentkontroll.
- Expected: `Erstatt fil` is disabled and the visible disabled reason is present.
- Screenshot: `06_document_control_replace_disabled.png`.

### 7. Source Overview/Search

- Open a source list, source preview, or source search result.
- Expected: source traceability is understandable.
- Screenshot: `07_source_overview_search.png`.

### 8. Saksrom / Source-Bound Dialogue

- Ask one safe test-data question.
- Expected: answer cites available sources or clearly says the source basis is missing.
- Screenshot: `08_saksrom_source_answer.png`.

### 9. Settings / Security / Privacy

- Open settings/security/privacy-related tab.
- Expected: test-data/local/privacy limits are visible and understandable.
- Screenshot: `09_settings_security_privacy.png`.

### 10. Theme / Accessibility Basics

- Toggle light/dark mode if available.
- Tab through primary controls.
- Expected: visible focus is present and no keyboard trap appears.
- Screenshot or notes: `10_keyboard_focus_or_theme.png`.

### 11. Export / Diagnostics

- Open export/diagnostics if visible.
- Expected: no production/client-data readiness claim appears.
- Screenshot: `11_export_diagnostics.png`.

## Stop Conditions

Stop and mark `smoke_result: fail` if any of these happen:

- App crashes or cannot launch.
- Import fails without a clear user-facing message.
- Saksrom uses stale/missing/unsafe sources as if they were ready.
- Any UI claims real-client-data readiness.
- `Erstatt fil` appears enabled.
- Test-data/pre-alpha/local/privacy warning is missing.
- Keyboard focus is invisible or trapped in the primary flow.
- Real client data is requested or used.

## After Completion

1. Save filled result as `docs/first-user/manual-smoke-evidence-result.md`.
2. Put screenshots in the folder named in `screenshots_folder`.
3. Run:

```powershell
powershell -ExecutionPolicy Bypass -File ops\Test-EvidaFirstUserDesktopReadiness.ps1 -SkipOptionalStacks
```

4. Ask Codex to update `status_bundle.txt` from the completed evidence.
