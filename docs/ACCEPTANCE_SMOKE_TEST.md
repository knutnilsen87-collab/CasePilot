# Evida Acceptance Smoke Test

Run before handing a build to a first evaluator.

Canonical e2e smoke path:

```text
import -> Saksrom -> source -> workroom
```

## Release Verification

- Run `powershell -ExecutionPolicy Bypass -File ops/New-EvidaRelease.ps1`.
- Run `powershell -ExecutionPolicy Bypass -File ops/Test-EvidaRelease.ps1`.
- Confirm `Evida Release/Evida.exe` timestamp is current.
- Confirm `SHA256SUMS.txt` and `release-manifest.json` exist.

## App Smoke Test

- Start via `Start Evida.bat`.
- Intro screen is only the vignette/video.
- Clicking intro opens the app without login.
- Header says `PRE-ALPHA · testdata only` and `Sikker lokalmodus`.
- No broken Norwegian text is visible.

## Runtime Smoke Evidence Status

Current status: `manual_required`

Codex/static checks do not count as a passed runtime smoke. A human evaluator must run the desktop app and attach screenshots or notes before this gate can move from `manual_required` to `pass`.

Evidence files:

- Template: `docs/first-user/manual-smoke-evidence-template.md`
- Current result file: `docs/first-user/manual-smoke-evidence-result.md`

The current result file is intentionally `smoke_result: blocked` until a human evaluator fills it in.

### Required screenshot targets

- `01_intro_launch.png` - Evida opens from `Start Evida.bat` or `Evida Release\Evida.exe`; intro/vignette is visible.
- `02_case_created.png` - a synthetic/redacted test case is created or opened.
- `03_document_import_idle.png` - Dokumenter screen shows local/test-data status and import actions.
- `04_import_progress.png` - import progress shows current file, progress, ETA/status if available.
- `05_document_control_replace_disabled.png` - Dokumentkontroll shows `Erstatt fil` disabled with visible reason.
- `06_source_preview.png` - source preview/search/drawer opens from a controlled source.
- `07_saksrom_source_answer.png` - Saksrom answer is source-bound or clearly says source basis is missing.
- `08_settings_security.png` - settings/security tab shows local/test-data/privacy limits.
- `09_dark_mode_or_theme.png` - dark/light toggle or theme state is verified if available.
- `10_keyboard_focus.png` - visible keyboard focus is shown on a primary control.

### Manual pass/fail checklist

Use only synthetic, redacted, or approved test data.

| Step | Expected result | Pass/Fail | Evidence |
|---|---|---|---|
| Launch app | App opens without terminal-only failure | [ ] PASS / [ ] FAIL | screenshot/log |
| Intro | Intro/vignette is understandable and not a login gate | [ ] PASS / [ ] FAIL | screenshot |
| Create/open case | Active test case is visible | [ ] PASS / [ ] FAIL | screenshot |
| Import documents | PDF/DOCX/TXT or approved test docs can be selected/imported | [ ] PASS / [ ] FAIL | screenshot |
| Import progress | Progress/status is understandable and not duplicated/noisy | [ ] PASS / [ ] FAIL | screenshot |
| Needs review | Documents needing OCR/manual control are clearly marked | [ ] PASS / [ ] FAIL | screenshot |
| Erstatt fil | Button remains disabled and visible reason is present | [ ] PASS / [ ] FAIL | screenshot |
| Source preview/search | Controlled source can be opened and traced to document/page | [ ] PASS / [ ] FAIL | screenshot |
| Saksrom | Answer is source-bound or gives safe missing-source response | [ ] PASS / [ ] FAIL | screenshot |
| Settings/security | UI clearly says test-data/local/privacy limits; real client data is not allowed | [ ] PASS / [ ] FAIL | screenshot |
| Keyboard basics | Tab focus is visible for import/control/settings primary controls | [ ] PASS / [ ] FAIL | screenshot/notes |
| Dark/light | Theme remains readable in checked mode(s) | [ ] PASS / [ ] FAIL | screenshot |

### Stop conditions

- Any real client data is present or requested.
- `Erstatt fil` appears enabled.
- The app sends raw document content to external AI without explicit test policy.
- Import/source status looks green for unsupported, failed, unsafe OCR, or manual-review documents.
- The evaluator cannot tell what the next action is after import.
- Text is visibly broken or unreadable.
- Keyboard users cannot reach import, document control, settings, or drawer close controls.

## Workflow Smoke Test

- Create a test case.
- Import a PDF, DOCX or TXT test document.
- Import several documents in one selection.
- Import a folder with approved test documents and confirm nested supported files are queued.
- Drag and drop several documents at once.
- Drag and drop a folder with approved test documents.
- Import queue shows:
  - Valgt
  - Sjekker fil
  - Beregner hash
  - Leser tekst
  - Lager kildegrunnlag
  - Klar or Krever oppmerksomhet
- Evida opens Saksrom after import.
- Saksrom shows summary and chat, not a technical dashboard.
- Ask one question.
- Answer shows sources or a missing-source notice.
- Answer shows uncertainty, missing basis, and next step.
- Source opens in drawer/modal.
- Use one suggested workroom action from Saksrom, for example chronology, evidence, contradictions or risk.
- Workroom opens with the same active case and no duplicate write window.
- Kontrollgrunnlag shows OCR, coverage, sources, audit and database/security status.
- Delete the test case and confirm it is removed from active cases.

## Automated Preflight

Run the non-GUI preflight before manual app smoke:

```powershell
powershell -ExecutionPolicy Bypass -File ops/Test-EvidaSmokePreflight.ps1
```

This does not replace the manual app smoke. It verifies that the release boundary, backend decision, smoke runbook and known limitations are present before a build is handed over.

## Security Smoke Test

- No real client data is used.
- OpenAI key is not required for local mode.
- If OpenAI is configured, answer sources must validate against local source IDs.
- Production Spring profile must fail without JWT issuer or JWK set URI.

## Known Non-Prod Limits

- Build is not code-signed.
- Full database-file encryption is not complete SQLCipher; sensitive fields are encrypted.
- Maven is not bundled locally in this repo; Spring tests run in CI or on machines with Maven.
- External AI should not be used with real client data without a signed data processing setup.
