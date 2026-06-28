# Codex Task — Complete Evida Desktop DoD for Client Data

## Objective

Complete Evida Desktop DoD so the app can safely be used with real legal client data.

## Scope lock

Do not solve this by building an open web demo. This task is about the desktop app.

The app must work in a managed Windows legal workstation environment and preserve local-first client-data safety.

## Mandatory rule

Always update the status bundle as part of the work.

Relevant files:

```text
artifacts/first-user/status_bundle.first_user.final.json
artifacts/first-user/evidence.first_user.current.json
artifacts/first-user/invariant_evaluation.first_user.json
docs/first-user/FIRST_USER_READINESS_MATRIX.md
```

## Work sequence

Follow this sequence unless new evidence changes the risk:

```text
1. Lock DoD contract.
2. Managed Windows/Braathe/Jussys compatibility.
3. Client-data local safety.
4. Runtime sensitive log scan.
5. Document upload final closure.
6. Multi-document source-bound AI.
7. Full audit coverage.
8. Export with source basis.
9. Release security gates.
10. Clean-machine smoke.
11. Manual approvals.
12. Final status_bundle closure.
```

## Immediate next PR

### PR title

```text
Add client-data desktop DoD contract and status-bundle rules
```

### Files to add

```text
docs/first-user/CLIENT_DATA_DESKTOP_DOD.md
docs/first-user/DEVELOPER_CODEX_DESKTOP_DOD_EXECUTION_PLAN.md
docs/first-user/STATUS_BUNDLE_UPDATE_RULE.md
docs/first-user/CODEX_TASK_CLIENT_DATA_DESKTOP_DOD.md
```

### Files to update

```text
docs/first-user/FIRST_USER_READINESS_MATRIX.md
docs/first-user/PRODUCT_INVARIANTS.md
artifacts/first-user/status_bundle.first_user.final.json
artifacts/first-user/evidence.first_user.current.json
artifacts/first-user/invariant_evaluation.first_user.json
```

### Required status

The first PR must not make the product green.

Expected result:

```yaml
first_user_allowed: false
real_client_data_allowed: false
production_ready: false
closure_decision: blocked
```

## Validation command

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ops\Test-EvidaFirstUserReadiness.ps1
```

If available, also run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ops\Test-EvidaProductionDoD.ps1
```

## Success condition for first PR

```text
- DoD docs exist.
- Missing gates are explicit.
- Matrix contains new P0 rows.
- Status bundle references current blockers.
- Validator OK.
- Verdict remains BLOCKED.
```

## Do not

```text
- Do not mark manual approvals as pass.
- Do not mark Braathe approval as pass.
- Do not set real_client_data_allowed=true.
- Do not treat testdata success as client-data readiness.
- Do not bypass Windows security controls.
- Do not add broad unowned helper modules.
```

## Final success condition

Only after all phases:

```yaml
first_user_allowed: true
real_client_data_allowed: true
production_ready: true
closure_decision: succeeded
broken_invariants: []
untested_critical_invariants: []
```
