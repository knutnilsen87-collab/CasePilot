# Evida — Status Bundle Update Rule

## Purpose

The `status_bundle` is the operational truth for Evida readiness.

Do not rely on README text, comments, screenshots, or informal messages as the source of truth. Every meaningful readiness change must be reflected in the status bundle.

## Files

Primary status files:

```text
artifacts/first-user/status_bundle.first_user.final.json
artifacts/first-user/evidence.first_user.current.json
artifacts/first-user/invariant_evaluation.first_user.json
docs/first-user/FIRST_USER_READINESS_MATRIX.md
```

## Mandatory update triggers

Update the status bundle when any of these happen:

```text
- New blocker found.
- Existing blocker resolved.
- Test status changes.
- Evidence artifact is added.
- Evidence artifact is invalidated.
- Critical invariant changes.
- Manual approval is received.
- Manual approval is rejected.
- Braathe/IT policy status changes.
- Client-data policy changes.
- AI-provider policy changes.
- Release artifact changes.
- Signing status changes.
- SBOM/SCA/SAST status changes.
- Clean-machine smoke is run.
- Audit/export/document upload/AI status changes.
```

## Required fields

The bundle must always make these clear:

```json
{
  "quality_policy": {
    "quality_bar": "production_ready_only",
    "minimum_viable_mode": false,
    "partial_allowed_for_client_data": false,
    "fallback_policy": "block_or_disable_not_workaround"
  },
  "current_state": {
    "status": "blocked_or_partial_or_succeeded",
    "first_user_allowed": false,
    "real_client_data_allowed": false,
    "production_ready": false
  },
  "verification_layer": {
    "p0_status": "PASS_or_PARTIAL_or_BLOCKED",
    "document_upload_status": "PASS_or_PARTIAL_or_BLOCKED",
    "ai_source_control_status": "PASS_or_PARTIAL_or_BLOCKED",
    "audit_status": "PASS_or_PARTIAL_or_BLOCKED",
    "client_data_safety_status": "PASS_or_PARTIAL_or_BLOCKED",
    "managed_windows_status": "PASS_or_PARTIAL_or_BLOCKED",
    "release_security_status": "PASS_or_PARTIAL_or_BLOCKED"
  },
  "invariant_layer": {
    "broken_invariants": [],
    "untested_invariants": []
  },
  "evidence_layer": {
    "artifact_refs": [],
    "evidence_gaps": []
  },
  "closure_layer": {
    "closure_decision": "blocked_or_partial_or_succeeded",
    "approved_by_review": false,
    "remaining_unknowns": []
  }
}
```

## Green-status rule

Do not set:

```json
{
  "first_user_allowed": true,
  "real_client_data_allowed": true,
  "production_ready": true
}
```

unless:

```text
[ ] All P0 readiness rows are PASS.
[ ] No broken critical invariants.
[ ] No untested critical invariants.
[ ] Required evidence artifacts exist.
[ ] Manual approvals exist.
[ ] Braathe/IT approval exists.
[ ] Client-data approval exists.
[ ] Clean-machine smoke passed.
[ ] Runtime sensitive log scan passed.
[ ] Release security gates passed.
```

For client data, `partial`, `skipped`, and `unknown` always count as `blocked`. A P0 gate can only contribute to release approval when it is production-ready and verified as `PASS`.

## Production-ready-only closure rule

Use this policy for every status bundle that touches client data:

```json
{
  "quality_bar": "production_ready_only",
  "minimum_viable_mode": false,
  "partial_allowed_for_client_data": false,
  "fallback_policy": "block_or_disable_not_workaround",
  "closure_rule": {
    "pass_requires_all_p0": true,
    "partial_counts_as_blocked": true,
    "skipped_counts_as_blocked": true,
    "unknown_counts_as_blocked": true,
    "manual_approval_required": true,
    "status_bundle_update_required": true
  }
}
```

## If evidence is inconclusive

Use:

```json
{
  "status": "blocked",
  "ambiguity_flags": [
    "verification_inconclusive"
  ]
}
```

Do not use `PASS`.

## If a test is skipped

Use:

```json
{
  "status": "blocked",
  "reason": "required_test_not_run"
}
```

Do not use `PASS`.

## PR checklist

Every PR touching DoD must answer:

```markdown
## Status Bundle
- [ ] Updated
- [ ] No update needed because:
- Bundle path:
- Evidence refs added:
- Invariants changed:
- Closure changed:
```
