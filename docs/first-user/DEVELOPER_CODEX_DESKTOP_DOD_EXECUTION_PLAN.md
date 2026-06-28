# Evida — Developer/Codex Execution Plan for Complete Desktop DoD

## Purpose

This document gives developers and Codex a step-by-step implementation and verification plan to complete Evida Desktop DoD for real client-data use.

## Operating rule

Do not optimize for looking green. Optimize for verified green.

Every meaningful transition must update the `status_bundle`.

## Required status files

Every PR that affects DoD must update or explicitly confirm no change to:

```text
artifacts/first-user/status_bundle.first_user.final.json
artifacts/first-user/evidence.first_user.current.json
artifacts/first-user/invariant_evaluation.first_user.json
docs/first-user/FIRST_USER_READINESS_MATRIX.md
```

## PR response format

Every PR must include:

```markdown
## What changed
## Why
## Tests
## Evidence artifacts
## Invariants affected
## Status bundle update
## Residual risk
## Rollback path
## Repo-health verdict
## Recommended next action
## Fallback action
```

## Repo-health rule

A PR cannot be clean success if it:

```text
- introduces duplicate auth/policy/audit/AI-provider ownership,
- creates another incompatible status object,
- bypasses canonical schemas/contracts,
- hides a blocker,
- marks skipped checks as pass,
- adds broad helpers/misc/temp modules,
- leaves dead code or ambiguous ownership,
- weakens document upload or AI source control.
```

---

# Execution Phases

## Phase 0 — Lock DoD Contract

### Goal

Make missing work explicit and machine-readable.

### Tasks

```text
1. Add or update docs/first-user/CLIENT_DATA_DESKTOP_DOD.md.
2. Add or update docs/first-user/DEVELOPER_CODEX_DESKTOP_DOD_EXECUTION_PLAN.md.
3. Add DoD P0 rows to docs/first-user/FIRST_USER_READINESS_MATRIX.md.
4. Add/update critical invariants in docs/first-user/PRODUCT_INVARIANTS.md.
5. Add/update artifacts/first-user/invariant_evaluation.first_user.json.
6. Add/update artifacts/first-user/evidence.first_user.current.json.
7. Update artifacts/first-user/status_bundle.first_user.final.json.
```

### Validation

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ops\Test-EvidaFirstUserReadiness.ps1
```

### Success condition

```text
- Validator OK.
- DoD gates are visible.
- Verdict remains BLOCKED if any P0 is missing.
```

---

## Phase 1 — Managed Windows / Braathe / Jussys Compatibility

### Goal

Evida can install and run on the target managed lawyer workstation.

### Tasks

```text
1. Implement code signing for Evida.exe.
2. Sign Windows installer.
3. Generate SHA256SUMS.
4. Generate release-manifest.json.
5. Create Braathe allowlist package.
6. Add docs/first-user/WINDOWS_MANAGED_WORKSTATION_COMPATIBILITY.md.
7. Add ops/Test-EvidaWindowsPolicyDiagnostics.ps1.
8. Run diagnostics before and after Jussys/Braathe environment starts.
9. Verify Evida remains discoverable.
10. Verify app starts while Jussys is running.
11. Verify import from neutral local folder.
```

### Evidence artifacts

```text
artifacts/first-user/windows_policy_diagnostics.current.json
artifacts/first-user/windows_managed_workstation_smoke.json
artifacts/first-user/signature_verification.json
artifacts/first-user/braathe_approval.json
```

### Do not

```text
- Do not ask user to bypass Braathe policy.
- Do not run from USB/DFS/network share as final pilot path.
- Do not treat unmanaged-machine demo as managed-workstation proof.
```

### status_bundle update

Add or update:

```json
{
  "managed_windows_status": "pass_or_blocked",
  "blockers": [
    "windows_managed_workstation_policy_block"
  ],
  "evidence_refs": [
    "artifacts/first-user/windows_policy_diagnostics.current.json",
    "artifacts/first-user/signature_verification.json",
    "artifacts/first-user/braathe_approval.json"
  ]
}
```

---

## Phase 2 — Client-Data Local Safety

### Goal

Evida can handle real client data locally without unacceptable leakage or loss.

### Tasks

```text
1. Verify encrypted local database.
2. Verify encrypted/protected document store.
3. Inspect cache/index/source-object storage.
4. Store key material in OS keychain / Windows Credential Manager.
5. Block unsafe fallback key file in prod/client-data mode.
6. Add raw storage inspection test.
7. Add backup/restore test.
8. Add deletion/retention test.
9. Ensure external AI is off by default.
10. Ensure provider policy changes require audit.
```

### Required tests

```text
data_local_db_encrypted
data_document_store_encrypted
data_cache_index_no_plaintext
data_key_stored_in_os_keychain
data_fallback_key_file_blocked_in_prod
data_raw_storage_inspection_has_no_plaintext
data_backup_restore_preserves_case_docs_sources_audit
data_delete_removes_or_tombstones_docs_and_audit_correctly
external_ai_disabled_by_default
provider_policy_change_requires_audit
```

### Evidence artifacts

```text
artifacts/first-user/encryption_verification.json
artifacts/first-user/raw_storage_inspection.json
artifacts/first-user/backup_restore_result.json
artifacts/first-user/deletion_retention_result.json
artifacts/first-user/provider_policy_result.json
```

### status_bundle update

Add or update:

```json
{
  "data_policy": {
    "real_client_data_requested": true,
    "real_client_data_allowed": false,
    "external_ai_raw_document_upload_allowed": false
  },
  "verification_layer": {
    "local_encryption_status": "pass_or_blocked",
    "backup_restore_status": "pass_or_blocked",
    "deletion_retention_status": "pass_or_blocked"
  }
}
```

---

## Phase 3 — Runtime Sensitive Log Scan

### Goal

Prove that client text and sensitive markers do not appear in logs.

### Tasks

```text
1. Create marker documents.
2. Run full app flow with marker documents.
3. Trigger success and failure paths.
4. Collect all logs and diagnostic outputs.
5. Scan for markers.
6. Fail if any marker or raw document body appears.
```

### Required markers

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

### status_bundle update

```json
{
  "invariant_layer": {
    "INV-DATA-001": {
      "status": "pass_or_blocked",
      "evidence_ref": "artifacts/first-user/runtime_sensitive_log_scan.json"
    }
  }
}
```

---

## Phase 4 — Document Upload Final Closure

### Goal

Document upload is safe enough for real client data.

### Tasks

```text
1. Verify valid PDF/DOCX/TXT upload.
2. Verify corrupt PDF safe failure.
3. Verify password PDF safe failure or explicit password-required state.
4. Verify wrong MIME rejection.
5. Verify image-only scan OCR/manual-review state.
6. Verify duplicate detection.
7. Verify import ETA.
8. Verify only action-required docs appear in manual review.
9. Verify preview links.
10. Verify approval checkbox.
11. Verify only source_ready docs can be used by AI.
```

### Evidence artifacts

```text
artifacts/first-user/document_upload_final_result.json
artifacts/first-user/manual_review_result.json
artifacts/first-user/import_eta_result.json
```

### status_bundle update

```json
{
  "verification_layer": {
    "document_upload_status": "pass_or_blocked",
    "manual_review_status": "pass_or_blocked",
    "import_eta_status": "pass_or_blocked"
  }
}
```

---

## Phase 5 — Multi-Document Source-Bound AI

### Goal

Saksrom answers safely across multiple real-case documents.

### Tasks

```text
1. Build multi-document eval set.
2. Test one-document questions.
3. Test multi-document questions.
4. Test conflicting evidence.
5. Test missing-source questions.
6. Test uploaded-document prompt injection.
7. Verify failed docs excluded.
8. Verify OCR/manual-review docs excluded until ready.
9. Verify retrieval snapshot for every answer.
10. Verify unsupported claim blocking.
```

### Evidence artifacts

```text
artifacts/first-user/ai_multi_doc_eval.json
artifacts/first-user/prompt_injection_eval.json
artifacts/first-user/unsupported_claim_eval.json
artifacts/first-user/retrieval_snapshot_eval.json
```

### status_bundle update

```json
{
  "verification_layer": {
    "ai_source_control_status": "pass_or_blocked",
    "multi_doc_eval_status": "pass_or_blocked",
    "prompt_injection_status": "pass_or_blocked",
    "unsupported_claim_status": "pass_or_blocked"
  }
}
```

---

## Phase 6 — Full Audit Coverage

### Goal

All important actions are auditable.

### Tasks

Add or verify audit events for:

```text
- app/session start
- case create
- document upload
- document failure/rejection
- manual source approval
- manual source rejection
- source object creation
- AI answer
- retrieval snapshot
- export
- document deletion/tombstone
- provider policy change
- security setting change
- audit verification
```

### Evidence artifact

```text
artifacts/first-user/audit_coverage_result.json
```

### status_bundle update

```json
{
  "verification_layer": {
    "audit_status": "pass_or_blocked"
  }
}
```

---

## Phase 7 — Export with Source Basis

### Goal

User can export a report that is traceable and safe.

### Tasks

```text
1. Implement or finish report export.
2. Include case id.
3. Include timestamp.
4. Include source basis.
5. Mark AI-generated draft clearly.
6. Block or mark unsupported claims.
7. Write export audit event.
8. Test export after restart.
```

### Evidence artifact

```text
artifacts/first-user/export_smoke_result.json
```

### status_bundle update

```json
{
  "verification_layer": {
    "export_status": "pass_or_blocked"
  }
}
```

---

## Phase 8 — Release Security Gate

### Goal

The build is safe and verifiable to distribute.

### Tasks

```text
1. Run full CI.
2. Run secret scan.
3. Run SCA/dependency scan.
4. Run SAST.
5. Generate SBOM.
6. Sign SBOM.
7. Sign app.
8. Sign installer.
9. Generate SHA256SUMS.
10. Generate release-manifest.json.
11. Verify all release artifacts.
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

### status_bundle update

```json
{
  "verification_layer": {
    "release_security_status": "pass_or_blocked",
    "signing_status": "pass_or_blocked",
    "sbom_status": "pass_or_blocked",
    "sca_status": "pass_or_blocked",
    "sast_status": "pass_or_blocked"
  }
}
```

---

## Phase 9 — Clean-Machine Smoke

### Goal

The release works on a clean Windows profile/machine.

### Tasks

```text
1. Install Evida from local disk.
2. Start Evida.
3. Create case.
4. Upload fictional test case.
5. Verify ETA.
6. Approve manual-review documents.
7. Open Saksrom.
8. Ask source-bound multi-doc question.
9. Export report.
10. Close app.
11. Restart app or PC.
12. Verify persistence.
13. Run audit verify.
14. Run log scan.
```

### Evidence artifact

```text
artifacts/first-user/clean_machine_smoke_result.json
```

### status_bundle update

```json
{
  "verification_layer": {
    "clean_machine_smoke_status": "pass_or_blocked"
  }
}
```

---

## Phase 10 — Client-Data Pilot Approval

### Goal

Get explicit approval before real client data is used.

### Tasks

```text
1. Get Braathe/IT approval.
2. Get written client-data pilot approval.
3. Document data policy.
4. Document external AI policy.
5. Document support/incident contact.
6. Document deletion after pilot.
7. Document technical access rules.
8. Tie approvals to status_bundle version.
```

### Evidence artifacts

```text
artifacts/first-user/braathe_it_approval.json
artifacts/first-user/client_data_pilot_approval.json
artifacts/first-user/client_data_policy.json
artifacts/first-user/external_ai_policy.json
artifacts/first-user/deletion_after_pilot_plan.json
```

### status_bundle update

```json
{
  "approval_layer": {
    "engineering": "approved_or_missing",
    "product": "approved_or_missing",
    "security_privacy": "approved_or_missing",
    "braathe_or_it": "approved_or_missing",
    "client_data_pilot": "approved_or_missing"
  }
}
```

---

## Phase 11 — Final Review and Closure

### Goal

Close DoD without false green.

### Tasks

```text
1. Run all DoD scripts.
2. Collect all evidence refs.
3. Update invariant evaluation.
4. Update readiness matrix.
5. Update evidence_current.
6. Update final status_bundle.
7. Engineering review.
8. Product review.
9. Security/privacy review.
10. Braathe/IT review.
11. Create closure decision.
12. Only if all P0 pass: set first_user_allowed=true and real_client_data_allowed=true.
```

### Final gate

```text
[ ] All P0 readiness rows PASS.
[ ] All required evidence artifacts exist.
[ ] broken_invariants = [].
[ ] untested_critical_invariants = [].
[ ] residual_risk accepted.
[ ] false_green_risk accepted.
[ ] clean-machine smoke PASS.
[ ] Braathe/IT approval PASS.
[ ] client-data approval PASS.
[ ] engineering/product/security approvals PASS.
[ ] status_bundle.final updated.
```

### Final bundle target

```json
{
  "current_state": {
    "status": "succeeded",
    "first_user_allowed": true,
    "real_client_data_allowed": true,
    "production_ready": true
  },
  "verification_layer": {
    "p0_status": "PASS",
    "document_upload_status": "PASS",
    "ai_source_control_status": "PASS",
    "audit_status": "PASS",
    "client_data_safety_status": "PASS",
    "managed_windows_status": "PASS",
    "release_security_status": "PASS"
  },
  "invariant_layer": {
    "broken_invariants": [],
    "untested_invariants": []
  },
  "closure_layer": {
    "closure_decision": "succeeded",
    "approved_by_review": true,
    "remaining_unknowns": [],
    "failure_to_asset_required": false
  }
}
```

---

# Recommended PR order

## PR 1 — DoD contract and status-bundle discipline

```text
- Add DoD docs.
- Add missing readiness matrix rows.
- Add invariant/evidence/status_bundle fields.
- Verdict must remain BLOCKED.
```

## PR 2 — Windows signing and Braathe compatibility

```text
- Signing.
- Allowlist package.
- Windows diagnostics.
- Managed workstation smoke.
```

## PR 3 — Client-data local safety

```text
- Encryption verification.
- Raw storage inspection.
- Backup/restore.
- Deletion/retention.
- External AI off by default.
```

## PR 4 — Sensitive log scan

```text
- Marker documents.
- Runtime flow.
- Log scan.
- Failure-path scan.
```

## PR 5 — Document upload final closure

```text
- ETA.
- Manual review.
- Failure states.
- AI exclusion.
```

## PR 6 — Multi-document AI eval

```text
- Source-bound multi-doc.
- Prompt injection.
- Unsupported claim blocking.
- Retrieval snapshots.
```

## PR 7 — Audit/export closure

```text
- Full audit coverage.
- Export source basis.
```

## PR 8 — Release security

```text
- SBOM.
- SCA/SAST.
- Signing verification.
- Release manifest.
```

## PR 9 — Clean-machine smoke and approvals

```text
- Clean-machine smoke.
- Manual approvals.
- Final status_bundle closure.
```
