# v6.5.2 Technical Design — Redmine + Publisher Fixes

**Version:** v6.5.2 (PATCH)
**Date:** 2026-04-15

---

## 1. core/status-verification.md — Full Content Specification

This is a new advisory core contract. It is a leaf-node contract (no dependencies on other core contracts). It is referenced by 3 call sites in this version, with 4 more planned for v6.6.0.

### Full Contract Content

```markdown
# Status Verification

## Purpose

Advisory post-update verification for issue tracker state transitions. After any status-set MCP call, read back the issue state and compare to the expected value. Fire-and-warn only — NEVER blocks the pipeline.

## Input Contract

| Field | Type | Notes |
|-------|------|-------|
| issue_id | string | Issue tracker ID |
| expected_state | string | The state value that was just set (e.g., `status_id:2`, `State: In Progress`) |
| tracker_type | string | Tracker type from Automation Config (youtrack/github/jira/linear/gitea/redmine) |

## Process

1. **Read back issue state:** After the status-set MCP call completes, fetch the current issue state using the tracker's get-issue MCP tool (e.g., `redmine_get_issue`, `youtrack_get_issue`).

2. **Compare:** Extract the current status from the response and compare to `expected_state`.
   - For Redmine: compare the `status.id` field from the response to the numeric ID in `expected_state` (e.g., if `expected_state` is `status_id:2`, check that `status.id == 2`).
   - For other trackers: compare the status name/label from the response to the expected value using case-insensitive string matching.

3. **Verdict:**
   - **Match** → log: `[OK] Status verified: {issue_id} → {expected_state}`
   - **Mismatch** → log: `[WARN] Status verification failed: expected {expected_state} but got {actual_state}. Check tracker workflow permissions or status ID validity.`
   - **Read-back failure** (network error, timeout, permission error, MCP tool not available) → log: `[WARN] Status verification skipped: could not read back issue {issue_id} ({error_type}). Status-set was attempted but not confirmed.`

## Output Contract

Verification result is logged only — no structured output, no return value consumed by callers. The calling process continues unconditionally regardless of verdict.

## Constraints

- NEVER block the pipeline on verification failure — always continue.
- NEVER retry the read-back — one attempt only.
- NEVER retry the status-set based on verification outcome — the set was already attempted.
- Verification is best-effort: caching delays, eventual consistency, or permission mismatches may cause false negatives.
- If the tracker MCP get-issue tool is not available (e.g., MCP server does not expose it), skip verification silently: `[WARN] Status verification skipped: get-issue tool not available for {tracker_type}.`

## Failure Handling

All failure modes produce WARN log entries and allow the pipeline to continue:

| Failure Mode | Log Message |
|-------------|-------------|
| Status mismatch | `[WARN] Status verification failed: expected {expected} but got {actual}...` |
| Network/timeout error | `[WARN] Status verification skipped: could not read back issue...` |
| Permission error | `[WARN] Status verification skipped: could not read back issue...` |
| MCP tool unavailable | `[WARN] Status verification skipped: get-issue tool not available...` |
| Unparseable response | `[WARN] Status verification skipped: could not parse status from response...` |
```

### Design Rationale

- **Advisory only:** The contract is explicitly fire-and-warn. This addresses Agent 3's concerns about verification false positives (caching delays, race conditions, permission mismatches). All failure modes produce noise at worst, never pipeline failures.
- **Universal:** Works for all 6 tracker types, not just Redmine. The Redmine-specific numeric ID comparison is one branch in the compare step.
- **Leaf node:** No dependencies on other core contracts. Does not modify state.json — it produces log output only.
- **Single attempt:** No retries on read-back. This keeps the contract simple and avoids amplifying transient failures.

---

## 2. Newline NEVER-Rule — Exact Text

The following text is used at all 5 vulnerable call sites. The exact formulation was selected from Agent 3's proposal as the most haiku-friendly negative constraint:

### For Constraints sections (publisher.md):

```
- NEVER use the literal characters `\n` in any MCP tool parameter that accepts multi-line text (PR description, issue comments). Always use actual line breaks (real newlines) in the string. The MCP tool receives the parameter value as-is — escaped sequences are rendered literally, not as newlines.
```

### For inline instructions (all other sites):

```
When passing the [issue description / block comment] to the MCP [create-issue / update-issue] tool, use real line breaks between [sections / fields] — NEVER use the literal characters `\n` as line separators.
```

### Rationale

- Negative constraints (`NEVER`) are the strongest instruction-following signal for haiku-model agents.
- The explanation ("rendered literally, not as newlines") prevents the model from reasoning its way out of the constraint.
- The constraint is short enough (1-2 lines) to be added per-site without scope creep.

---

## 3. trackers.md Format Changes — Exact Table Rows

### State Transition Syntax Table

| Tracker | Format | Example: In Progress | Example: Done |
|---------|--------|---------------------|---------------|
| redmine | `status_id:{id}` | `status_id:2` | `status_id:5` |

(All other rows unchanged.)

### On Start Set Defaults Table

| Tracker | Default On start set |
|---------|---------------------|
| redmine | `status_id:2` |

(All other rows unchanged.)

### Validation Rules Table

| Tracker | Query validation | State transition format | Instance validation |
|---------|-----------------|------------------------|---------------------|
| redmine | Must contain `project_id=` | `status_id:{id}` or `status:{name}` (legacy) | Any URL |

(All other rows unchanged.)

### Redmine Note (after State Transition Syntax table)

> **Redmine note:** The `status_id:{id}` format uses the numeric ID from your Redmine instance. Common defaults: 1=New, 2=In Progress, 3=Resolved, 4=Feedback, 5=Closed, 6=Rejected. Verify your instance's IDs via `GET /issue_statuses.json`. The legacy `status:{name}` format (e.g., `status:In Progress`) is accepted but unreliable — it depends on LLM translation at runtime, which may fail silently. Use `status_id:{id}` for deterministic behavior.

---

## 4. Onboard Wizard Redmine Sub-Step Design

### Trigger Condition

Only when the user selects `redmine` as tracker type in Step 2 item 1.

### Position

Between Step 2 item 6 (State transitions) and Step 2 item 7 (On start set). Numbered as item 6a.

### User Interaction Flow

```
1. Display guidance text (common defaults, curl command)
2. Accept 4 numeric IDs interactively:
   - In Progress ID (default: 2)
   - Blocked ID (default: 4)
   - For Review ID (default: 4)
   - Done/Closed ID (default: 5)
3. Use the IDs to compose State transitions value:
   "In Progress: `status_id:{in_progress}`, Blocked: `status_id:{blocked}`, For Review: `status_id:{for_review}`, Done: `status_id:{done}`"
```

### No MCP Access Required

The sub-step displays a curl command for the user to run in a separate terminal. The onboard wizard itself does NOT make MCP calls — it accepts the user's input as-is. This respects the `allowed-tools: Read, Glob, Write, Edit` constraint.

### Default Handling

If the user presses Enter for all prompts, the defaults from trackers.md are used. This produces a valid config for standard Redmine installations.

---

## 5. migrate-config Deprecated Pattern Rule Design

### Detection Logic

```
IF Type == "redmine"
AND (State transitions contains "status:" without "status_id:")
   OR (On start set contains "status:" without "status_id:")
THEN → trigger interactive conversion
```

### Interactive Conversion

The rule is skippable — the user can press Enter to keep the legacy format. This addresses the constraint that IDs are instance-specific and cannot be auto-resolved.

If the user provides IDs:
- Each `status:{name}` in State transitions is replaced with `status_id:{id}`
- `On start set` value is replaced with `status_id:{id}`

If the user skips:
- No changes made
- WARN logged: `[WARN] Redmine legacy status format retained — pipeline may fail silently on status transitions`

### Why Interactive

Unlike existing migrate-config patterns (bullet-point → table, add missing Type), this conversion cannot be automated because:
1. Status IDs are instance-specific (not universal)
2. The wizard has no MCP access to look them up
3. A wrong numeric ID silently corrupts data (worse than text format)

---

## 6. Integration Points — Verification Wiring

Three call sites get `core/status-verification.md` wiring in v6.5.2:

| # | File | Location | Status-Set Context |
|---|------|----------|-------------------|
| 1 | `agents/publisher.md` | Step 7 | Sets "For Review" after PR creation |
| 2 | `core/block-handler.md` | Step 2 | Sets "Blocked" on pipeline block |
| 3 | `skills/fix-ticket/SKILL.md` | Step 1 | Sets "On start set" at pipeline start |

### Why These Three

These cover the most common pipeline paths:
- **Start** (fix-ticket Step 1): every bug pipeline execution
- **Block** (block-handler Step 2): every pipeline failure
- **Publish** (publisher Step 7): every successful pipeline execution

### Wiring Pattern

Each site adds a single sentence after the status-set instruction:

```
After the status-set MCP call, follow `core/status-verification.md` to verify the transition succeeded.
```

### Four Deferred Call Sites (v6.6.0)

| # | File | Location | Reason for Deferral |
|---|------|----------|---------------------|
| 1 | `skills/implement-feature/SKILL.md` | Step 1 | Keep PATCH scope manageable |
| 2 | `core/fix-verification.md` | Step 6 | Re-open path, lower frequency |
| 3 | `skills/fix-bugs/SKILL.md` | Step X item 2 | Inline block handler, covered by core |
| 4 | `skills/scaffold/SKILL.md` | Step 8b | Scaffold path, lowest frequency |

---

## 7. Deferred Items for Roadmap

### v6.6.0 Items

| Item | Rationale | Effort |
|------|-----------|--------|
| Status verification — remaining 4 call sites | Keep PATCH scope to 3 high-value sites | ~4 one-line edits |
| `core/mcp-body-formatting.md` centralized contract | Good design but MINOR scope; per-site instructions sufficient for PATCH | New file + update 5 refs |
| fix-bugs "On start set" step | New feature, not a bug fix; pre-existing functional gap | ~10 lines in fix-bugs |

### Not Planned Items

| Item | Rationale |
|------|-----------|
| config-reader Redmine normalization | Requires MCP access during config-reader execution; format change in trackers.md makes this unnecessary |
| Onboard wizard MCP access | allowed-tools expansion is a deliberate design choice beyond PATCH scope; interactive ID collection achieves the same goal |

---

## 8. Test Design — mcp-newline-handling.sh

### Structure

```bash
#!/usr/bin/env bash
# Test: All MCP multi-line call sites contain newline encoding instruction
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

FAIL=0
fail() { echo "FAIL: $1"; FAIL=1; }

MARKER='NEVER use the literal characters'

# 5 vulnerable files that must contain the marker
check_file() {
  local file="$1"
  local desc="$2"
  if [ ! -f "$REPO_ROOT/$file" ]; then
    fail "$desc: file not found ($file)"
    return
  fi
  if ! grep -q "$MARKER" "$REPO_ROOT/$file"; then
    fail "$desc: missing newline encoding instruction ($file)"
  fi
}

check_file "agents/publisher.md" "Publisher PR description"
check_file "core/block-handler.md" "Block handler comment"
check_file "skills/fix-ticket/SKILL.md" "fix-ticket subtask description"
check_file "skills/implement-feature/SKILL.md" "implement-feature subtask description"
check_file "skills/fix-bugs/SKILL.md" "fix-bugs block comment + subtask description"

[ "$FAIL" -eq 0 ] && echo "PASS: All 5 MCP multi-line call sites contain newline encoding instruction"
exit "$FAIL"
```

### What It Catches

- Future regressions if someone removes the newline instruction from any of the 5 files.
- Missing instructions if a new vulnerable site is added without the constraint (would need to be added to this test).

### Convention Compliance

- Uses the same harness structure as existing tests (`set -euo pipefail`, `FAIL` counter, `fail()` function, `PASS`/`FAIL` output).
- Checks file existence before grep (defensive).
- Single marker string used across all assertions for consistency.
