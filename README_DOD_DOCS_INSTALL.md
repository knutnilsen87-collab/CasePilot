# How to install these docs into the repo

From repo root:

```bash
unzip evida_client_data_desktop_dod_repo_docs.zip -d .
git add docs/first-user artifacts/first-user README_DOD_DOCS_INSTALL.md
git commit -m "Add client-data desktop DoD execution plan"
```

If any files already exist, merge manually instead of overwriting important current evidence.

## Recommended first follow-up

After adding the docs, update:

```text
docs/first-user/FIRST_USER_READINESS_MATRIX.md
docs/first-user/PRODUCT_INVARIANTS.md
artifacts/first-user/status_bundle.first_user.final.json
artifacts/first-user/evidence.first_user.current.json
artifacts/first-user/invariant_evaluation.first_user.json
```

Then run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ops\Test-EvidaFirstUserReadiness.ps1
```

Expected result after the documentation PR:

```yaml
verdict: BLOCKED
first_user_allowed: false
real_client_data_allowed: false
production_ready: false
```

That is correct until all P0 gates pass.
