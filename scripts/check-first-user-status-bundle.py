#!/usr/bin/env python3
import json
import sys
from pathlib import Path

REQUIRED_TOP = [
    "bundle_id",
    "bundle_version",
    "release_candidate_id",
    "commit_sha",
    "quality_policy",
    "current_state",
    "scope_lock",
    "invariant_layer",
    "verification_layer",
    "closure_layer",
]

def fail(msg: str) -> None:
    print(f"ERROR: {msg}", file=sys.stderr)
    sys.exit(1)

def main() -> None:
    if len(sys.argv) != 2:
        fail("Usage: check-first-user-status-bundle.py <bundle.json>")

    path = Path(sys.argv[1])
    if not path.exists():
        fail(f"Bundle not found: {path}")

    data = json.loads(path.read_text(encoding="utf-8"))

    for key in REQUIRED_TOP:
        if key not in data:
            fail(f"Missing required key: {key}")

    current = data["current_state"]
    policy = data["quality_policy"]
    verification = data["verification_layer"]
    invariants = data["invariant_layer"]
    closure = data["closure_layer"]

    if policy.get("quality_bar") != "production_ready_only":
        fail("quality_policy.quality_bar must be production_ready_only")
    if policy.get("minimum_viable_mode") is not False:
        fail("quality_policy.minimum_viable_mode must be false")
    if policy.get("partial_allowed_for_client_data") is not False:
        fail("quality_policy.partial_allowed_for_client_data must be false")
    if policy.get("fallback_policy") != "block_or_disable_not_workaround":
        fail("quality_policy.fallback_policy must be block_or_disable_not_workaround")

    closure_rule = policy.get("closure_rule", {})
    for key in [
        "pass_requires_all_p0",
        "partial_counts_as_blocked",
        "skipped_counts_as_blocked",
        "unknown_counts_as_blocked",
        "manual_approval_required",
        "status_bundle_update_required",
    ]:
        if closure_rule.get(key) is not True:
            fail(f"quality_policy.closure_rule.{key} must be true")

    if current.get("real_client_data_allowed") is True or current.get("production_ready") is True:
        if current.get("status") != "pass":
            fail("client-data or production readiness requires current_state.status=pass")
        if verification.get("p0_status") != "pass":
            fail("client-data or production readiness requires p0_status=pass")
        blocked_values = {"partial", "skipped", "unknown", "blocked", "deferred"}
        for key, value in verification.items():
            if isinstance(value, str) and value.lower() in blocked_values:
                fail(f"client-data or production readiness cannot pass with {key}={value}")

    if current.get("first_user_allowed") is True:
        if current.get("status") != "pass":
            fail("first_user_allowed=true requires current_state.status=pass")
        if verification.get("p0_status") != "pass":
            fail("first_user_allowed=true requires verification_layer.p0_status=pass")
        if verification.get("document_upload_status") != "pass":
            fail("first_user_allowed=true requires document_upload_status=pass")
        if verification.get("ai_source_control_status") != "pass":
            fail("first_user_allowed=true requires ai_source_control_status=pass")
        if verification.get("audit_status") != "pass":
            fail("first_user_allowed=true requires audit_status=pass")
        if invariants.get("broken_invariants"):
            fail("first_user_allowed=true requires zero broken invariants")
        if invariants.get("untested_invariants"):
            fail("first_user_allowed=true requires zero untested invariants")
        if closure.get("closure_decision") != "approved_for_controlled_first_user":
            fail("first_user_allowed=true requires approved_for_controlled_first_user")
        if closure.get("approved_by_review") is not True:
            fail("first_user_allowed=true requires approved_by_review=true")

    print("OK: first-user status bundle structure is valid")

if __name__ == "__main__":
    main()
