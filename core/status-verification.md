# Status Verification

## Purpose

Advisory post-update verification for issue tracker status transitions. After any status-set MCP call, read back the issue state and compare to the expected value. All failure modes produce WARN log entries only — the pipeline NEVER blocks on verification failure.

## Input Contract

| Field | Type | Notes |
|-------|------|-------|
| issue_id | string | Issue tracker ID |
| expected_state | string | The state value that was just set (e.g., `status_id:2`, `State: In Progress`) |
| tracker_type | string | From Automation Config → Issue Tracker → Type |

## Process

1. **Read back:** After the status-set MCP call completes, call the tracker's get-issue MCP tool to read the current issue state.
   - YouTrack: read issue state field
   - GitHub/Gitea: read issue state and labels
   - Jira: read issue status
   - Linear: read issue state
   - Redmine: read issue status (compare `status.id` from response to expected numeric ID)

2. **Compare:** Compare the read-back state to `expected_state`.
   - For Redmine `status_id:{id}` format: extract numeric ID from response `status.id` field, compare to expected ID.
   - For Redmine legacy `status:{name}` format: compare response `status.name` to expected name (case-insensitive).
   - For other trackers: compare using the tracker's native format.

3. **Verdict:**
   - Match → log `[INFO] Status verification passed: {issue_id} → {expected_state}`
   - Mismatch → log `[WARN] Status transition failed: expected {expected_state} but got {actual_state} for {issue_id}. Check {tracker_type} workflow permissions.`
   - Continue pipeline in ALL cases.

## Output Contract

Log-only. No return value. No state.json write. No issue tracker modification.

## Constraints

- NEVER block the pipeline on verification failure — always continue
- NEVER retry the status-set call — verification is advisory only
- NEVER modify the issue state during verification — read-only
- NEVER skip verification silently — always log the result (INFO or WARN)
- NEVER add verification overhead for non-status MCP calls — this contract applies only to status-set operations

## Failure Handling

| Failure Mode | Action |
|---|---|
| Read-back MCP call fails (network, timeout) | Log `[WARN] Status verification skipped: could not read back {issue_id} ({error}). Pipeline continues.` |
| Read-back returns unexpected format | Log `[WARN] Status verification skipped: could not parse {tracker_type} response for {issue_id}. Pipeline continues.` |
| MCP tool not available | Log `[WARN] Status verification skipped: {tracker_type} get-issue tool not available. Pipeline continues.` |
| Permission error on read | Log `[WARN] Status verification skipped: permission denied reading {issue_id}. Pipeline continues.` |
| Race condition (status changed by another user) | Log `[WARN] Status transition failed: expected {expected_state} but got {actual_state} for {issue_id}. This may indicate a concurrent modification or workflow restriction.` |
