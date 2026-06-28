# Evida — Client-Data Desktop DoD

## Purpose

This document defines the complete Definition of Done for Evida as a desktop application that may be used with real legal client data.

This is stricter than an internal demo, testdata pilot, or synthetic evaluation build.

Evida is not DoD-complete for client data until all P0 gates in this document are `PASS`, all critical invariants are verified, and the final `status_bundle` explicitly allows real client data.

## Current default stance

Until proven otherwise:

```yaml
first_user_allowed: false
real_client_data_allowed: false
production_ready: false
external_ai_raw_document_upload_allowed: false
```

## Production-ready-only policy

Evida skal ikke bygges etter minimumskrav for klientdata. Hvis en funksjon ikke er produksjonsklar, skal den ikke være tilgjengelig for klientdata.

```yaml
policy:
  minimum_acceptable: none
  partial_for_client_data: not_allowed
  fallback_for_user: block_or_disable_feature
  release_standard: production_ready_only
```

For klientdata gjelder:

```text
PASS means production-ready and verified.
PARTIAL means BLOCKED.
SKIPPED means BLOCKED.
UNKNOWN means BLOCKED.
```

Allowed fallback is only:

```text
- block release
- disable feature
- show safe error message
- keep the document outside the source basis
- keep status_bundle BLOCKED
```

Not allowed:

```text
- temporary workaround
- good enough for now
- acceptable for pilot with client data
- manual user cleanup around a known defect
- duplicate import as replacement
```

## Non-negotiable rules

1. Do not set `first_user_allowed=true` until all first-user P0 gates are `PASS`.
2. Do not set `real_client_data_allowed=true` until all client-data P0 gates are `PASS`.
3. Do not mark a P0 row as `PASS` without evidence.
4. Treat `PARTIAL`, `SKIPPED`, and `UNKNOWN` as `BLOCKED` for client data.
5. Do not use real client data before client-data gates are complete and approved.
6. Do not bypass Braathe, Jussys, Windows, AppLocker, WDAC, Defender, Intune, or any managed workstation policy.
7. Do not send raw client documents to external AI unless explicitly approved in writing.
8. Always update the `status_bundle` when DoD status, evidence, blockers, approvals, policy, or release artifacts change.
9. If production-grade document replacement is not complete, disable `Erstatt fil` in client-data mode and keep client-data status `BLOCKED`.

## Full DoD terminal condition

Evida is complete for desktop client-data use only when this is true:

```json
{
  "first_user_allowed": true,
  "real_client_data_allowed": true,
  "production_ready": true,
  "closure_decision": "succeeded",
  "p0_status": "PASS",
  "broken_invariants": [],
  "untested_critical_invariants": [],
  "manual_approvals": {
    "engineering": "approved",
    "product": "approved",
    "security_privacy": "approved",
    "braathe_or_it": "approved"
  }
}
```

If any item above is false, final status must remain `BLOCKED`, `PARTIAL`, or `NOT_READY`.

---

# P0 DoD Gates

## WIN-MANAGED-001 — Managed Windows / Braathe / Jussys compatibility

### Requirement

Evida must install and run on the target managed legal workstation without bypassing security policy.

### Must be true

```text
[ ] Evida.exe is signed.
[ ] Installer is signed.
[ ] Windows does not show “Unknown publisher”.
[ ] Installer is launched from local disk, not USB/DFS/network share.
[ ] Braathe/IT approval or allowlisting exists.
[ ] Evida remains discoverable after Jussys/Braathe environment starts.
[ ] Evida can start while Jussys is running.
[ ] Evida can import from neutral local folder while Jussys is running.
[ ] Locked-file behavior is safe and user-readable.
```

### Evidence artifacts

```text
artifacts/first-user/windows_policy_diagnostics.current.json
artifacts/first-user/windows_managed_workstation_smoke.json
artifacts/first-user/signature_verification.json
artifacts/first-user/braathe_approval.json
release-manifest.json
SHA256SUMS
```

### Fail condition

Any block from Braathe, Windows application control, unknown publisher, unsigned binary, admin-required installer without IT approval, or inability to launch in the target workstation keeps the gate `BLOCKED`.

---

## DATA-ENC-001 — Local client-data storage protection

### Requirement

Local case data, documents, cache, indexes, source objects, and derived artifacts must not be stored in unsafe plaintext locations.

### Must be true

```text
[ ] Local database encryption verified.
[ ] Document store encryption or approved protection verified.
[ ] Cache/index/source-object storage inspected.
[ ] Key material stored in OS keychain / Windows Credential Manager.
[ ] Prod/client-data mode blocks unsafe fallback key files.
[ ] Raw storage inspection finds no sensitive document text.
[ ] Backup/restore preserves protected data correctly.
[ ] Delete/retention behavior is defined and tested.
```

### Evidence artifacts

```text
artifacts/first-user/encryption_verification.json
artifacts/first-user/raw_storage_inspection.json
artifacts/first-user/backup_restore_result.json
artifacts/first-user/deletion_retention_result.json
```

### Fail condition

Any readable raw client document body, unsafe key fallback, unclear backup/restore behavior, or unverified delete/retention keeps the gate `BLOCKED`.

---

## DATA-LOG-001 — Runtime sensitive log safety

### Requirement

Evida must not log raw client documents, sensitive markers, prompts containing client text, retrieval chunks, or privileged notes.

### Must be true

```text
[ ] App flow executed with marker documents.
[ ] Import logs scanned.
[ ] AI/Saksrom logs scanned.
[ ] Worker logs scanned.
[ ] Crash/error logs scanned.
[ ] Diagnostics package scanned.
[ ] Audit payloads scanned.
[ ] Failure paths scanned.
[ ] Zero sensitive markers found.
```

### Required test markers

```text
EVIDA_SECRET_MARKER_CLIENT_NAME_123
EVIDA_SECRET_MARKER_CASE_FACT_456
EVIDA_SECRET_MARKER_PERSONAL_NUMBER_789
EVIDA_SECRET_MARKER_PRIVILEGED_NOTE_ABC
```

### Evidence artifact

```text
artifacts/first-user/runtime_sensitive_log_scan.json
```

### Fail condition

Any sensitive marker, raw document chunk, privileged note, or raw prompt in logs keeps the gate `BLOCKED`.

---

## DOC-UPLOAD-001 — Document upload final closure

### Requirement

Document upload must be safe, understandable, and source-controlled.

### Must be true

```text
[ ] Valid PDF upload reaches source_ready.
[ ] Valid DOCX upload reaches source_ready.
[ ] Valid TXT upload reaches source_ready.
[ ] Corrupt PDF fails safe.
[ ] Password PDF fails safe or requires password explicitly.
[ ] Wrong MIME is rejected.
[ ] Unsupported file type is rejected.
[ ] Image-only scan becomes ocr_needed or manual review.
[ ] Duplicate detection works.
[ ] Import ETA is visible.
[ ] User sees one clear next action.
[ ] Manual review list shows only documents needing action.
[ ] Preview link opens the correct document.
[ ] Approval checkbox is required before approving as source.
[ ] Documents that are not source_ready are excluded from AI.
```

### Evidence artifacts

```text
artifacts/first-user/document_upload_final_result.json
artifacts/first-user/manual_review_result.json
artifacts/first-user/import_eta_result.json
```

### Fail condition

Any failed, rejected, OCR-needed, or manual-review document used by AI keeps the gate `BLOCKED`.

---

## AI-SOURCE-001 — Multi-document source-bound AI

### Requirement

Saksrom must answer from eligible source objects only and must not present unsupported legal/factual claims as established facts.

### Must be true

```text
[ ] One-document source-bound answer test passes.
[ ] Multi-document source-bound answer test passes.
[ ] Conflicting document evidence is surfaced or marked.
[ ] Missing source answer is refused or marked unsupported.
[ ] Uploaded-document prompt injection is ignored.
[ ] Failed documents are excluded from retrieval.
[ ] OCR-needed documents are excluded until ready.
[ ] Manual-review documents are excluded until approved.
[ ] Retrieval snapshot exists for every AI answer.
[ ] Unsupported claim block rate is 1.0.
[ ] Prompt injection bypass rate is 0.
```

### Evidence artifacts

```text
artifacts/first-user/ai_multi_doc_eval.json
artifacts/first-user/prompt_injection_eval.json
artifacts/first-user/unsupported_claim_eval.json
artifacts/first-user/retrieval_snapshot_eval.json
```

### Fail condition

Any unsupported claim presented as fact, any prompt-injection policy bypass, or any non-ready document used by AI keeps the gate `BLOCKED`.

---

## AUDIT-ALL-001 — Full audit coverage

### Requirement

Every important action must be auditable without leaking sensitive document text.

### Must audit

```text
[ ] App/session started.
[ ] Case created.
[ ] Document uploaded.
[ ] Document failed/rejected.
[ ] Document approved as source.
[ ] Document rejected as source.
[ ] Source object created.
[ ] AI answer generated.
[ ] Retrieval snapshot created.
[ ] Export generated.
[ ] Document deleted/tombstoned.
[ ] Provider policy changed.
[ ] Security setting changed.
[ ] Audit verification run.
```

### Evidence artifact

```text
artifacts/first-user/audit_coverage_result.json
```

### Fail condition

Missing audit for upload, AI answer, export, deletion, or provider-policy change keeps the gate `BLOCKED`.

---

## EXPORT-001 — Export with source basis

### Requirement

Evida must export a safe, traceable report.

### Must be true

```text
[ ] Export report is created.
[ ] Export includes case id.
[ ] Export includes timestamp.
[ ] Export includes source basis.
[ ] AI-generated draft status is visible.
[ ] Unsupported claims are blocked or marked.
[ ] Export audit event is created.
[ ] Export still works after restart.
```

### Evidence artifact

```text
artifacts/first-user/export_smoke_result.json
```

### Fail condition

Any export without source basis or audit event keeps the gate `BLOCKED`.

---

## RELEASE-SECURITY-001 — Release security and provenance

### Requirement

Release artifacts must be verifiable, signed, and security-scanned.

### Must be true

```text
[ ] Full CI passes.
[ ] Gitleaks/secret scan passes.
[ ] SCA/dependency scan passes.
[ ] SAST passes.
[ ] SBOM is generated.
[ ] SBOM is signed.
[ ] Evida.exe is signed.
[ ] Installer is signed.
[ ] SHA256SUMS exists.
[ ] release-manifest.json exists.
[ ] Release artifact verification passes.
```

### Evidence artifacts

```text
artifacts/release/ci_result.json
artifacts/release/gitleaks_result.json
artifacts/release/sca_result.json
artifacts/release/sast_result.json
artifacts/release/sbom.json
artifacts/release/sbom.signature
artifacts/release/signature_verification.json
artifacts/release/release_manifest.json
artifacts/release/SHA256SUMS
```

### Fail condition

Unsigned executable, unsigned installer, missing SBOM, missing CI SCA/SAST, or unverified release artifact keeps the gate `BLOCKED`.

---

## SMOKE-001 — Clean-machine install/start/restart smoke

### Requirement

The release build must work on a clean Windows profile or separate clean test machine.

### Smoke steps

```text
[ ] Install Evida from local disk.
[ ] Start Evida.
[ ] Create case.
[ ] Upload fictional test case.
[ ] Verify import ETA.
[ ] Approve manual-review documents.
[ ] Open Saksrom.
[ ] Ask source-bound multi-document question.
[ ] Export report.
[ ] Close app.
[ ] Restart app or PC.
[ ] Verify case persists.
[ ] Verify documents persist.
[ ] Verify source objects persist.
[ ] Verify audit persists.
[ ] Run audit verification.
[ ] Run runtime log scan.
```

### Evidence artifact

```text
artifacts/first-user/clean_machine_smoke_result.json
```

### Fail condition

Any install/start/persistence/upload/AI/export/audit failure keeps the gate `BLOCKED`.

---

## APPROVAL-001 — Manual approvals

### Requirement

No final client-data release without explicit approvals tied to a concrete `status_bundle` version.

### Required approvals

```text
[ ] Engineering approval.
[ ] Product approval.
[ ] Security/privacy approval.
[ ] Braathe/IT approval.
[ ] Client-data pilot approval.
```

### Evidence artifacts

```text
artifacts/first-user/engineering_approval.json
artifacts/first-user/product_approval.json
artifacts/first-user/security_privacy_approval.json
artifacts/first-user/braathe_it_approval.json
artifacts/first-user/client_data_pilot_approval.json
```

### Fail condition

Any missing approval keeps `first_user_allowed=false` and `real_client_data_allowed=false`.

---

# Final closure checklist

Before setting any final green status:

```text
[ ] All P0 rows in readiness matrix are PASS.
[ ] All required evidence artifacts exist.
[ ] Broken invariants list is empty.
[ ] Untested critical invariants list is empty.
[ ] Residual risk is accepted.
[ ] False-green risk is low/accepted.
[ ] Clean-machine smoke passes.
[ ] Braathe/IT approval exists.
[ ] Client-data approval exists.
[ ] Engineering/product/security approvals exist.
[ ] status_bundle.final is updated.
```

If all are true, update final `status_bundle` and close as `succeeded`.

If not, keep closure as `blocked`, `partial`, or `not_ready`.
