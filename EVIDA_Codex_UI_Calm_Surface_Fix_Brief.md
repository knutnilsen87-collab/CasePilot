# EVIDA Codex Brief: Calm Surface Fix for Document Import

**Purpose:** Fix visual noise, broken Norwegian text, unclear source coverage, and raw technical errors  
**Date:** 2026-06-03  
**Target:** `evida-core/desktop-tauri` only

---

## 1. Context

Current screenshots show the document import and document list screens are visually noisy and unclear for a normal user. The app exposes too many colors, repeated badges, raw SQL/database errors, low-level OCR/source terminology, and broken Norwegian characters.

This is a **user-readiness / calm surface patch**, not a backend feature expansion.

The existing status bundle says the repo is already dirty and replacement/OCR readiness is not approved for production exposure. Therefore this patch must not enable `Erstatt fil`, must not change replacement logic, and must not expand OCR behavior.

---

## 2. Problem Statement

The current UI creates avoidable user confusion:

1. Too many colors and badges compete for attention.
2. Sidebar repeats `OCR gjenstår` across many sections, making the whole app feel alarming.
3. The import result says both `Import fullført` and `trenger oppmerksomhet` without a clear next action.
4. `Kildedekning 39 %` is technical and does not explain what the user should do next.
5. Raw SQL/database errors are visible in the document list.
6. Norwegian characters are broken in labels/buttons, for example `Å...pne Saksrom`.
7. The user cannot easily answer: “What is done, what needs attention, and what should I click next?”

---

## 3. Product Goal

After the patch, the user should see one calm, understandable import result:

> **Import fullført. 85 av 218 dokumenter kan brukes som kilder. 133 dokumenter trenger kontroll før trygg analyse.**

The UI must then offer one primary next action:

> **Gå gjennom dokumenter som trenger kontroll**

Raw technical details must be hidden behind an explicit technical details affordance.

---

## 4. Scope Lock

### In scope

- Desktop UI wording and layout in document import/document list/document control surfaces.
- Status mapping from technical import states to user-safe labels.
- CSS simplification for status colors and badges.
- Hiding raw technical errors behind a collapsed/details-only view.
- Fixing broken Norwegian characters in visible UI strings.
- Creating or updating targeted frontend tests for the new display rules.

### Out of scope

- Do not enable `PRODUCTION_GRADE_DOCUMENT_REPLACE_ENABLED`.
- Do not change backend document replacement behavior.
- Do not change OCR extraction behavior.
- Do not change database schema/migrations unless a very narrow frontend-visible encoding source bug proves it is required.
- Do not refactor unrelated sidebar/navigation architecture.
- Do not introduce new broad utility/helper files unless ownership is clearly better than extending the existing module.

---

## 5. Desired User-Facing Copy

Use this copy or very close equivalents.

### Import summary

Replace ambiguous mixed status with:

- **Title:** `Import fullført`
- **Body:** `85 av 218 dokumenter kan brukes som kilder. 133 dokumenter trenger kontroll før trygg analyse.`
- **Secondary note:** `Du kan åpne Saksrom nå, men analysen blir tryggere etter kontroll.`
- **Primary action:** `Gå gjennom dokumenter som trenger kontroll`
- **Secondary action:** `Åpne Saksrom`

When all documents are source-ready:

- **Title:** `Import fullført`
- **Body:** `Alle dokumenter er klare for Saksrom.`
- **Primary action:** `Åpne Saksrom`

When technical failures exist:

- **Title:** `Noen dokumenter kunne ikke leses`
- **Body:** `Dokumentene er importert, men noen filer må kontrolleres manuelt.`
- **Primary action:** `Vis dokumenter som trenger kontroll`

### Replace `Kildedekning 39 %`

Avoid showing percentage as the main message. Prefer:

- `85 av 218 dokumenter kan brukes som kilder`
- `133 dokumenter trenger kontroll`
- `Ikke klar for trygg analyse ennå`

A percentage may remain in technical/details view, but not as the primary user-facing guidance.

### Document row labels

Map low-level states to calm user labels:

| Current / technical condition | User-facing label | User-facing explanation |
|---|---|---|
| source-ready | `Klar for Saksrom` | `Kan brukes som kilde` |
| OCR/manual review needed | `Trenger kontroll` | `Kontroller teksten før dokumentet brukes som kilde` |
| extraction failed | `Kunne ikke leses` | `Dokumentet må kontrolleres manuelt` |
| unsupported/corrupt file | `Kan ikke brukes som kilde` | `Filformatet eller innholdet kunne ikke leses trygt` |
| raw DB/SQL error | `Teknisk feil under import` | `Detaljer er skjult. Åpne tekniske detaljer ved behov.` |

---

## 6. Raw Error Handling Rule

Never show raw database, SQL, stack trace, Rust error, or internal schema text in the normal document list.

Examples that must not be visible by default:

- `no such column: lifecycle_status`
- `CREATE INDEX IF NOT EXISTS`
- `at offset 87`
- stack traces
- full SQL fragments
- raw panic/debug output

Instead show:

> `Teknisk feil under import`

and provide a collapsed link/button:

> `Vis tekniske detaljer`

The technical details area may show the raw message for developer/support use, but it must be collapsed by default and visually secondary.

---

## 7. Visual Design Rules

Use fewer colors and fewer simultaneous alarms.

### Recommended color semantics

- Green: ready / completed / safe
- Amber: needs user control
- Red: failed / cannot be used
- Neutral: informational / inactive / technical detail

### Specific changes

- Remove repeated `OCR gjenstår` badges from every sidebar item.
- Replace sidebar alarm badges with at most one global calm status near the active case/import summary.
- Make the primary action visually dominant and only one primary action per panel.
- Avoid white high-contrast blocks inside dark cards unless they are editable fields.
- Keep technical details in neutral styling.
- Do not use green for “completed but unsafe/incomplete”; use amber if attention is required.

---

## 8. Norwegian Text Integrity

Visible UI must render these exact characters correctly:

- `Åpne Saksrom`
- `Kildedekning`
- `Trenger kontroll`
- `Velg mappe`
- `Ny sak`
- `Dokumenter`
- `Kildeutdrag`
- `Saksoversikt`
- `Bevismatrise`
- `Rettsimulering`

Acceptance check: no replacement glyphs, mojibake, missing first letter, ellipsis replacing letters, or broken `Å/Ø/Æ/å/ø/æ`.

Likely causes to inspect:

- string truncation/ellipsis CSS
- fixed-width button too narrow
- text-overflow clipping
- font fallback/rendering in Tauri
- malformed string literal or encoding in TSX/CSS
- pseudo-element overlay hiding first characters

Do not “fix” by avoiding Norwegian letters. The correct fix is to render Norwegian correctly.

---

## 9. Suggested Files to Inspect First

Start with existing owned surfaces before creating new files:

- `evida-core/desktop-tauri/src/App.tsx`
- `evida-core/desktop-tauri/src/lib/api.ts`
- `evida-core/desktop-tauri/src/components/DocumentPreviewDrawer.tsx`
- `evida-core/desktop-tauri/src/components/documents/ImportStatusCard.tsx`
- `evida-core/desktop-tauri/src/features/documentControl/documentControl.logic.ts`
- `evida-core/desktop-tauri/src/styles.css`

Only create a new file if it clearly improves ownership, for example:

- `src/features/documents/documentStatusPresentation.ts`

Do not create generic files like `helpers.ts`, `utils.ts`, `misc.ts`, `newStatus.ts`, or `v2.ts`.

---

## 10. Recommended Implementation Plan for Codex

### Step 1 — Reproduce and locate UI ownership

Find where the import summary, document row status text, sidebar badges, and `Åpne Saksrom` button are rendered.

### Step 2 — Add a presentation mapping

Create or extend a narrowly owned function that converts technical import/source/OCR states into user-facing presentation data:

```ts
type DocumentUserStatus =
  | "ready"
  | "needs_control"
  | "failed"
  | "not_source";

type DocumentStatusPresentation = {
  label: string;
  explanation: string;
  severity: "success" | "attention" | "danger" | "neutral";
  technicalDetails?: string;
};
```

Keep raw technical details separate from user-facing text.

### Step 3 — Change import summary hierarchy

Replace mixed status panels with one summary card:
- one title
- one explanatory sentence
- one primary action
- one secondary action if needed
- one collapsed technical details area

### Step 4 — Reduce sidebar noise

Remove repeated OCR badges from inactive sections. Show one case-level status only.

### Step 5 — Fix Norwegian rendering

Find why `Åpne Saksrom` renders as `Å...pne Saksrom`. Fix the actual rendering/clipping/encoding issue. Verify all Norwegian strings listed above.

### Step 6 — Add tests

Add focused tests for:
- raw SQL error is not visible in normal row rendering
- technical details are hidden by default
- import summary shows counts and primary next action
- Norwegian labels are present as complete strings
- sidebar does not repeat OCR badges across every section

---

## 11. Verification Required

Run from `evida-core/desktop-tauri`:

```powershell
npm.cmd test
npm.cmd run build
```

Manual smoke required:

1. Start the desktop app.
2. Import the same 218-document test pack shown in screenshots.
3. Confirm the import summary is calm and has one clear next action.
4. Confirm raw SQL errors are hidden by default.
5. Confirm `Åpne Saksrom` and other Norwegian labels render correctly.
6. Confirm sidebar does not show repeated `OCR gjenstår` badges on every section.
7. Confirm `Erstatt fil` remains disabled.

---

## 12. Acceptance Criteria

The patch is accepted only if all are true:

- No raw SQL/database/internal errors visible in the default document list.
- Import summary tells the user what happened and what to do next.
- `Kildedekning 39 %` is not the primary user-facing message.
- User sees counts: documents ready vs documents needing control.
- Only one primary action is visually dominant in the import result panel.
- Sidebar no longer repeats OCR alarm badges for every workflow section.
- Norwegian characters render correctly.
- `PRODUCTION_GRADE_DOCUMENT_REPLACE_ENABLED` remains `false`.
- `npm.cmd test` passes.
- `npm.cmd run build` passes.
- Repo health is preserved: no broad utility dumping, no unrelated refactor, no backend behavior change.

---

## 13. Fallback Plan

If the full calm-surface patch is too large, do the smallest safe fallback:

1. Hide raw technical errors behind `Vis tekniske detaljer`.
2. Replace `Kildedekning 39 %` with `85 av 218 dokumenter kan brukes som kilder`.
3. Fix `Åpne Saksrom`.
4. Remove repeated sidebar OCR badges.

Do not proceed to broader styling changes until these four are verified.

---

## 14. Stop Signals

Stop and replan if:

- fixing text rendering requires broad framework/style refactor
- a database migration appears necessary
- tests reveal source readiness logic is wrong
- hiding raw errors would also hide all user guidance
- the patch starts touching replacement/OCR backend logic
- `Erstatt fil` becomes enabled accidentally

---

## 15. Closure Statement Codex Should Produce

At completion, Codex should report:

```text
Changed:
- files modified
- what user-facing behavior changed

Verified:
- npm.cmd test result
- npm.cmd run build result
- manual smoke result or explicit not-run

Not changed:
- replacement/OCR backend behavior
- PRODUCTION_GRADE_DOCUMENT_REPLACE_ENABLED remains false

Repo health:
- improved/preserved/degraded
- any follow-up required
```
