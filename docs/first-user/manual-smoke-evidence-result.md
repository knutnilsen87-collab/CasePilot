# Evida Manual Runtime Smoke Evidence Result

Status: not yet executed by a human evaluator.

This file is intentionally not a pass record. It exists so the readiness script can verify that the manual evidence structure is present before handoff.

## Metadata

```yaml
evaluator_name:
date:
build_manifest_timestamp: 2026-05-21T16:06:59.8382867Z
release_manifest_sha256: c432492129df6abe3c16a75ca407d6f4435a78d27dff20a60cd7ae09416da0ea
app_version: 0.1.0-alpha
machine:
windows_version:
smoke_result: blocked
screenshots_folder:
failed_step: manual_runtime_smoke_not_run
notes: Manual runtime GUI smoke is still required. No human evaluator has completed this checklist yet.
```

## Checklist

```yaml
checklist:
  launch:
    status: blocked
    screenshot: 01_intro_launch.png
    notes: Not run.
  first_user_orientation:
    status: blocked
    screenshot: 02_first_user_orientation.png
    notes: Not run.
  case_creation_or_opening:
    status: blocked
    screenshot: 03_case_created.png
    notes: Not run.
  document_import:
    status: blocked
    screenshot: 04_document_import_progress.png
    notes: Not run.
  ocr_or_manual_review_state:
    status: blocked
    screenshot: 05_ocr_manual_review_state.png
    notes: Not run.
  document_control_replace_disabled:
    status: blocked
    screenshot: 06_document_control_replace_disabled.png
    notes: Not run.
  source_overview_or_search:
    status: blocked
    screenshot: 07_source_overview_search.png
    notes: Not run.
  saksrom_source_bound_dialogue:
    status: blocked
    screenshot: 08_saksrom_source_answer.png
    notes: Not run.
  settings_security_privacy:
    status: blocked
    screenshot: 09_settings_security_privacy.png
    notes: Not run.
  theme_accessibility_basics:
    status: blocked
    screenshot: 10_keyboard_focus_or_theme.png
    notes: Not run.
  export_or_diagnostics:
    status: blocked
    screenshot: 11_export_diagnostics.png
    notes: Not run.
```

## Human Completion Rule

Only change `smoke_result` to `pass` after a human evaluator has completed all required first-user/test-data steps, attached screenshots/notes, and confirmed:

- no real client data was used,
- `Erstatt fil` remained disabled,
- test-data/local/privacy limits were visible,
- source-bound Saksrom behavior was understandable,
- keyboard focus was visible in the primary flow.

If any stop condition occurs, set `smoke_result: fail` and fill `failed_step`.
