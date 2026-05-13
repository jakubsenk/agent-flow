# Brainstorm: Contract Design Architect

## Approach Summary

v6.7.2 is a PATCH release: zero behavioral changes, zero new config keys, zero output format changes. The four work items reduce duplication, fix webhook protocol drift, remove a contradictory inline override, and correct stale documentation. Every change must be mechanically verifiable as behavior-preserving (or, where the inline had bugs, behavior-correcting toward the already-canonical core contract).

---

## WI1: Tracker Subtask Extraction

### Design Decision: New Core Contract `core/tracker-subtask-creator.md`

**Rationale:** Three identical ~153-line pseudocode blocks across fix-ticket (L223-360), fix-bugs (L240-377), and implement-feature (L282-419) violate DRY. The triple gate, idempotency loop, per-tracker MCP dispatch, dual-store write, GitHub/Gitea checklist, YAML commit, and result display are word-for-word identical. Zero reconciliation needed.

### Exact Structure of `core/tracker-subtask-creator.md`

Follow the established pattern from `core/block-handler.md` and `core/post-publish-hook.md`:

```
# Tracker Subtask Creator

## Purpose

Create tracker sub-issues for decomposition subtasks. Includes triple gate, idempotency, per-tracker MCP dispatch, dual-store persistence, and GitHub/Gitea parent checklist.

## Input Contract

| Field | Type | Default | Notes |
|-------|------|---------|-------|
| issue_id | string | required | Parent issue ID |
| tracker_type | string | required | From config: youtrack/github/jira/linear/gitea/redmine |
| tracker_project | string | required | Project key/ID from config |
| subtask_list | object[] | required | Subtask objects from decomposition (in topological order) |
| yaml_path | string | required | `.claude/decomposition/{ISSUE-ID}.yaml` |
| state_json_path | string | required | Path to state.json for this run |
| decomposition_decision | string | required | `"DECOMPOSE"` or `"SINGLE_PASS"` |
| create_tracker_subtasks_config | string | `"enabled"` | From Decomposition config section |
| tracker_effective_status | string | required | `"ready"` (MCP available) or `"unavailable"` (MCP not available). Set by caller from MCP pre-flight output (core/mcp-preflight.md). |

## Process

### Triple Gate

Skip this procedure entirely (no WARN, expected behavior) if ANY of:
1. `decomposition_decision != "DECOMPOSE"`
2. `create_tracker_subtasks_config == "disabled"`
3. `tracker_effective_status != "ready"`

### Subtask Creation Loop

[Full pseudocode block — verbatim from existing copies, lines 228-360 of fix-ticket]

### Per-Tracker Issue Creation Parameters

[The 6-row reference table — verbatim from existing copies]

### Issue Description Template

[The template block + conditional rules — verbatim from existing copies]

## Output Contract

- `success_count` (integer): number of tracker issues created or recovered
- `failure_count` (integer): number of creation failures
- `created_issues` (list): `{subtask_id, tracker_issue_id, title}` tuples

Pipeline continues regardless of outcome. NEVER block here.

## Failure Handling

- Individual subtask creation failure: log warning, increment failure_count, continue loop.
- GitHub/Gitea checklist update failure: log warning, continue (standalone sub-issues still exist).
- All creations failed: display warning message, pipeline continues.
- YAML commit failure: log warning, continue (tracker issues exist, YAML linkage lost — recoverable on resume via state.json fallback).
```

### What Each Caller Looks Like After Refactoring

**fix-ticket (step 4b-tracker):**
```markdown
### 4b-tracker. Create tracker subtasks

Follow `core/tracker-subtask-creator.md`.

Input values:
- `issue_id`: `{ISSUE_ID}`
- `tracker_type`: from Automation Config -> Issue Tracker -> Type
- `tracker_project`: from Automation Config -> Issue Tracker -> Project
- `subtask_list`: decomposition subtasks from previous step
- `yaml_path`: `.claude/decomposition/{ISSUE-ID}.yaml`
- `state_json_path`: `.ceos-agents/{ISSUE-ID}/state.json`
- `decomposition_decision`: from state.json
- `create_tracker_subtasks_config`: from Automation Config -> Decomposition -> Create tracker subtasks
- `tracker_effective_status`: from MCP pre-flight result
```

**fix-bugs (step 3b-tracker):** Identical structure, but `state_json_path` uses `.ceos-agents/{ISSUE-ID}/state.json` (per-issue path in batch context). No other difference.

**implement-feature (step 5a):** Identical structure, `state_json_path` uses `.ceos-agents/{ISSUE-ID}/state.json`.

### Caller Residue

Each caller retains ONLY:
1. The step heading (e.g., `### 4b-tracker. Create tracker subtasks`)
2. A single `Follow core/tracker-subtask-creator.md.` delegation line
3. An `Input values:` block mapping 9 fields from caller-local variables to contract inputs

The pseudocode block, per-tracker table, and issue description template are ALL removed from callers.

### `tracker_effective_status` Definition

The new contract formally owns the definition of `tracker_effective_status` in its Input Contract notes column. Callers are responsible for setting it from the MCP pre-flight output:
- `"ready"` when `core/mcp-preflight.md` returns `mcp_available: true`
- `"unavailable"` when `core/mcp-preflight.md` returns `mcp_available: false` or when MCP pre-flight was skipped

This resolves the current gap where the variable exists in all three callers but is defined nowhere.

### fix-bugs YOLO Latent Bug

The YOLO reference in fix-bugs step 3b (AC coverage check, L221) references a mode that fix-bugs does not support (`--yolo` is not in its argument-hint). This is a **separate bug outside the tracker-subtask-creator scope** — the AC coverage check is in the step before tracker subtask creation. The new core contract does not interact with YOLO mode at all (YOLO affects the plan display/AC coverage check, not subtask creation). The latent bug should be noted in the changelog as a known issue but NOT fixed in this PATCH (fixing it changes behavior — removing a code path that currently cannot be reached is safe, but touching another skill's step exceeds scope).

### mcp-body-formatting Reference Normalization

fix-ticket uses `- Follow core/mcp-body-formatting.md...` (list-item format) while fix-bugs and implement-feature use `Follow core/mcp-body-formatting.md...` (plain paragraph). This cosmetic difference lives in the description template section which moves into the core contract. The core contract will use the plain paragraph form (matches 2 of 3 callers and matches the style of core/block-handler.md L38).

---

## WI2: Webhook Format Alignment

### Design Decision: Remove All Inline Webhooks, Delegate Exclusively to Core

**Rationale:** The canonical webhook formats live in `core/block-handler.md` (issue-blocked) and `core/post-publish-hook.md` (pr-created). Skills should reference these, not duplicate them. Every inline copy has drifted.

### Scope: implement-feature AND fix-bugs

Both skills have duplicate-firing patterns (delegate to core, then fire inline). fix-ticket is already clean.

### Exact Changes

**implement-feature step 10a (L617-623) — pr-created:**

Before:
```markdown
#### 10a. Post-publish hook + webhook

Follow `core/post-publish-hook.md`. If Hooks -> Post-publish exists: run the command via Bash.
If Notifications -> Webhook URL exists and On events contains `pr-created`:
\```bash
curl -X POST {webhook_url} -H "Content-Type: application/json" -d '{"event":"pr-created","issue":"{issue_id}","pr":"{pr_url}"}'
\```
```

After:
```markdown
#### 10a. Post-publish hook + webhook

Follow `core/post-publish-hook.md` for hook execution and webhook firing.
```

This is the fix-ticket pattern (L587-589). The inline curl with wrong keys (`issue` instead of `issue_id`, `pr` instead of `pr_url`), missing `--max-time 5`, missing `--retry 0`, missing `timestamp`, and bare URL is removed. core/post-publish-hook.md already handles the hook command, custom agent, and webhook — the "If Hooks -> Post-publish exists" sentence was also redundant.

**implement-feature step X (L661-664) — issue-blocked:**

The entire inline block handler (WI3) is being replaced. The inline webhook within it disappears as a natural consequence. No separate action needed — WI3 subsumes this.

**fix-bugs step 8b (L610-618) — pr-created:**

Before:
```markdown
### 8b. Webhook -- PR created

If Notifications -> Webhook URL exists and `pr-created` is in On events:
\```bash
curl --max-time 5 --retry 0 -X POST -H "Content-Type: application/json" \
  -d '{"event":"pr-created","issue_id":"{issue}","pr_url":"{url}","timestamp":"{ISO8601}"}' \
  "{Webhook URL}"
\```
Failure -> warning, must not stop the pipeline.
```

After:
```markdown
### 8b. Webhook -- PR created

Handled by `core/post-publish-hook.md` in step 8a. No additional action.
```

The inline has two key deviations: `"issue_id":"{issue}"` (should be `"{issue_id}"`) and `"pr_url":"{url}"` (should be `"{pr_url}"`). Step 8a already delegates to core/post-publish-hook.md which fires the webhook. Removing step 8b eliminates the double-fire.

Alternative: Remove the step heading entirely. But keeping it as a no-op with an explanation ("Handled by...") is clearer for readers scanning the step numbering — it explains WHY there is no 8b content without requiring them to read 8a carefully.

**fix-bugs step X — issue-blocked (L697-701):**

The fix-bugs block handler (L667-710) already delegates to core at L669, then re-lists steps including an inline webhook. The inline has `"issue_id":"{issue}"` (should be `"{issue_id}"`) and `{agent}` (should be `{agent_name}`). However, fix-bugs has legitimate skill-specific addenda (worktree rollback context, per-issue state path, block counter). The fix is:

1. Remove steps 4-5 (block comment + inline webhook, L685-702) — these duplicate what core/block-handler.md already does at steps 4-5.
2. Keep steps 1-3 (rollback with worktree context, set issue state with status-verification, on-block-action) as skill-specific overrides of the core's generic versions? NO — steps 1-3 are ALSO handled by core. The only genuinely skill-specific items are:
   - Rollback context string includes `Execution context: {worktree_path if worktree mode} | CWD (if sequential).`
   - State.json path is `.ceos-agents/{ISSUE-ID}/state.json` (per-issue)
   - Block counter logic (steps 7-8)

The cleanest approach: Keep the core delegation line, then list ONLY the skill-specific overrides as addenda:

```markdown
### X. Block handler

Follow `core/block-handler.md` for the block protocol.

**Skill-specific context:**
- Rollback execution context: `{worktree_path}` (parallel mode) or `CWD` (sequential mode). Pass this in the rollback-agent Task context string.
- State path: `.ceos-agents/{ISSUE-ID}/state.json` (per-issue, not per-run).
- Block counter: After core block protocol completes, increment `block_count`. If `Max blocked per run` is not `unlimited` and `block_count >= Max blocked per run`:
  - Display: "Max blocked per run ({N}) reached. Remaining {M} bugs skipped."
  - Skip to step 9 (Summary) -- DO NOT process remaining bugs.
- Continue with next bug.
```

This removes the duplicate comment, webhook, and state.json write (all handled by core), while preserving the three genuinely unique items.

### Webhook Deviations Fixed

| Source | Deviation | Resolution |
|--------|-----------|------------|
| implement-feature 10a | `issue`/`pr`, no `--max-time`/`--retry`, no `timestamp`, bare URL | Removed; core handles |
| implement-feature X | `issue`, `{agent}`, no `--max-time`/`--retry`, no `timestamp`, bare URL | Removed; core handles (via WI3) |
| fix-bugs 8b | `{issue}` in issue_id value, `{url}` in pr_url value | Removed; core handles (via 8a) |
| fix-bugs X | `{issue}` in issue_id value, `{agent}` placeholder | Removed; core handles |

### pipeline-complete Webhook (fix-bugs step 9a)

This webhook is NOT a deviation — it is a fix-bugs-only event (`pipeline-complete`) with no canonical equivalent in core. It stays as-is. No core contract exists for it and creating one would be scope creep for a PATCH.

---

## WI3: Block Handler Inline Removal

### Design Decision: Replace implement-feature Inline with fix-ticket-Style Delegation

**Rationale:** implement-feature L642-666 says "Follow `core/block-handler.md`:" then immediately re-lists all 6 steps — contradictory and buggy (missing rollback guard, missing status-verification, old curl format, no mcp-body-formatting reference, no failure handling). Removing the inline and delegating to core automatically fixes the behavioral bug (unconditional rollback even for read-only agents).

### Exact Replacement

Before (implement-feature L642-666, 25 lines):
```markdown
### X. Block handler

Follow `core/block-handler.md`:

1. Run `ceos-agents:rollback-agent` (Task tool, model: haiku) -- revert git changes
2. Set issue state to Blocked (State transitions -> Blocked)
3. **On block action** (per Error Handling -> On block):
   - `comment` (default): Add a Block comment to the issue tracker (see below)
   - `close`: Add a Block comment + close the issue
   - Other value: interpret as a custom action (always add a comment)
4. Add Block comment to the issue tracker:
   \```
   [ceos-agents] ... Pipeline Block
   Agent: {agent name}
   Step: {pipeline step}
   Reason: {max 2 sentences}
   Detail: {error output}
   Recommendation: {what human should do}
   \```
5. If Notifications -> Webhook URL exists and On events contains `issue-blocked`:
   \```bash
   curl -X POST {webhook_url} -H "Content-Type: application/json" -d '{"event":"issue-blocked","issue":"{issue_id}","agent":"{agent}","reason":"{reason}"}'
   \```

6. Update `state.json`: set top-level `status` to `"blocked"`, write `block` object with `{agent, step, reason, detail, recommendation}`. Follow atomic write protocol from `core/state-manager.md`.
```

After (matching fix-ticket L605-609 pattern):
```markdown
### X. Block handler

Follow `core/block-handler.md` for the block protocol.

Update `state.json`: set top-level `status` to `"blocked"`, write `block` object with `{agent, step, reason, detail, recommendation}`. Follow atomic write protocol from `core/state-manager.md`.
```

### Behavioral Bug Fix (Acceptable in PATCH)

The inline at L646 calls rollback-agent unconditionally. `core/block-handler.md` L21 has the correct guard: only rollback for `fixer`, `reviewer`, `test-engineer`, `e2e-test-engineer`, or `smoke-check`. In implement-feature, `spec-analyst` and `architect` can both block — the inline would incorrectly trigger rollback for these read-only agents. Delegating to core fixes this automatically.

This is a bug fix, not a behavioral change — the core contract already specifies the correct behavior, and the inline was supposed to follow it (the header says "Follow core/block-handler.md"). The fix is restoring intended semantics.

### State.json Reminder Line

The state.json update line is kept in the caller (matching fix-ticket L609) even though `core/block-handler.md` L45 also mandates it. This is intentional redundancy — it serves as a visual reminder to the LLM that state.json must be updated, and it is harmless (the core contract and the caller agree on the action). Both fix-ticket and the new implement-feature will have this line.

### fix-bugs Block Handler Cleanup

As detailed in WI2 above, fix-bugs step X gets cleaned to: core delegation line + three skill-specific addenda (worktree context, per-issue state path, block counter). The duplicate steps 4-5 (comment + webhook) are removed. Steps 1-3 are also removed because they duplicate core — only the worktree context override modifies step 1's behavior.

### Whether to Clean fix-bugs (Scope Decision)

YES, clean fix-bugs step X as part of WI2+WI3 combined. The duplicate webhook in fix-bugs X is a WI2 issue, and the duplicate block handler steps are a WI3 issue. Treating them together is cleaner than doing WI2 webhook removal and leaving contradictory inline steps behind.

---

## WI4: Documentation Fixes

### Fix 1 — `core/fix-verification.md` L21: Remove "Fix" from success comment

Before:
```
[ceos-agents] ... Fix verified. Verify command: `{command}`. Output: {first 500 chars}.
```

After:
```
[ceos-agents] ... Verified. Verify command: `{command}`. Output: {first 500 chars}.
```

Rationale: This contract is used by implement-feature (feature pipeline) and fix-ticket/fix-bugs (bug-fix pipeline). "Fix verified" is misleading for features.

### Fix 2 — `core/fix-verification.md` L26: Remove "Fix" from failure comment

Before:
```
[ceos-agents] ... Fix verification failed.
```

After:
```
[ceos-agents] ... Verification failed.
```

Same rationale.

### Fix 3 — `core/state-manager.md` L41-43: Inline heuristic detection table

Before:
```markdown
2. If state.json does not exist:
   - Fall back to heuristic detection (see resume-ticket.md existing logic)
   - Return resume_point from heuristic with reduced context
```

After:
```markdown
2. If state.json does not exist:
   - Fall back to heuristic detection by reading issue tracker comments, branch state, and git log:
     - PR open for branch -> `PUBLISHED`
     - `.claude/decomposition/{ISSUE-ID}.yaml` exists -> `DECOMPOSE_PARTIAL`
     - Branch with commits above base -> `POST_FIX` (or `POST_REVIEW` if reviewer approval comment present)
     - Branch exists + `[ceos-agents] Triage completed.` comment -> `POST_ANALYSIS`
     - `[ceos-agents] Triage completed.` comment only -> `POST_TRIAGE`
     - Otherwise -> `FRESH`
   - Return resume_point from heuristic with reduced context (no AC list, no iteration counts)
```

Rationale: A core contract must be self-contained. Forward-referencing a skill (resume-ticket) from a core contract creates an architectural inversion. The heuristic table is stable (6 checkpoints) and small enough to inline.

### Fix 4 — `state/schema.md` L104-106 + L225-226: Add missing e2e_test fields

**JSON example (L104-106):**

Before:
```json
  "e2e_test": {
    "status": "pending"
  },
```

After:
```json
  "e2e_test": {
    "status": "pending",
    "attempts": 0,
    "max_attempts": 3,
    "last_result": null
  },
```

**Field definition table (after L226, add 3 rows):**

Before:
```
| `e2e_test` | object | Yes | -- | E2E-test-engineer phase state. |
| `e2e_test.status` | string | Yes | `"pending"` | Phase status. See Step Status Enum. |
| `browser_verification` | ...
```

After:
```
| `e2e_test` | object | Yes | -- | E2E-test-engineer phase state. |
| `e2e_test.status` | string | Yes | `"pending"` | Phase status. See Step Status Enum. |
| `e2e_test.attempts` | integer | Yes | `0` | Number of completed E2E test attempts. |
| `e2e_test.max_attempts` | integer | Yes | `3` | Maximum allowed attempts (from retry limits). |
| `e2e_test.last_result` | string or null | No | `null` | Most recent E2E test outcome: `PASSED` or `FAILED`. |
| `browser_verification` | ...
```

Rationale: The `test` section has `attempts`, `max_attempts`, and `last_result`. The `e2e_test` section is structurally parallel but missing these three fields. Resume logic and metrics both need them.

### Fix 5 — `core/fixer-reviewer-loop.md` L44: Document all three callers

Before:
```
- `NEEDS_DECOMPOSITION` -> returned to caller; caller handles decomposition logic (see `core/decomposition-heuristics.md` and `skills/fix-ticket/SKILL.md` step 5).
```

After:
```
- `NEEDS_DECOMPOSITION` -> returned to caller; caller handles decomposition logic (see `core/decomposition-heuristics.md`). Enforcement varies by caller: `fix-ticket` and `fix-bugs` each enforce a one-decomposition-per-ticket limit (Block if already decomposed); `implement-feature` always Blocks (decomposition mode Blocks the subtask; single-pass mode Blocks the issue).
```

Rationale: The previous text referenced only fix-ticket, omitting fix-bugs and implement-feature. All three skills consume this contract. The "once per ticket" claim on L21 is correct for fix-ticket/fix-bugs (counter-based enforcement) but imprecise for implement-feature (which always blocks on the signal with no counter). The replacement text documents the actual behavior of all three callers.

---

## Implementation Order

1. **WI1 first** (new file + 3 caller edits) — largest change, highest deduplication value, zero behavioral risk.
2. **WI3 second** (implement-feature block handler replacement) — directly depends on understanding the step numbering.
3. **WI2 third** (webhook cleanup in implement-feature + fix-bugs) — implement-feature's webhook is inside the block handler removed in WI3, so WI3 must land first. fix-bugs webhook cleanup can be combined with the fix-bugs block handler cleanup.
4. **WI4 last** (5 independent doc fixes) — no dependencies on WI1-3; can be verified independently.

## Risk Assessment

- **WI1:** Zero risk. Three verbatim-identical blocks extracted to one contract. Callers gain a delegation pattern identical to existing core contracts. The per-tracker table moves to the core contract where it belongs.
- **WI2:** Low risk. Removing inline webhooks that duplicate core. The only subtle point is fix-bugs step 8b — we must verify step 8a actually delegates to core/post-publish-hook.md (confirmed: L604).
- **WI3:** Low risk with a positive side effect (fixes the unconditional rollback bug). The replacement is a proven pattern from fix-ticket.
- **WI4:** Zero risk. Text-only documentation fixes with exact before/after strings.

## Files Modified

| File | WI | Action |
|------|-----|--------|
| `core/tracker-subtask-creator.md` | WI1 | **NEW** (15th core contract) |
| `skills/fix-ticket/SKILL.md` | WI1 | Replace L207-388 with delegation block (~10 lines) |
| `skills/fix-bugs/SKILL.md` | WI1, WI2 | Replace L224-406 with delegation block; replace L610-618 with no-op note; replace L667-710 with clean delegation + addenda |
| `skills/implement-feature/SKILL.md` | WI1, WI2, WI3 | Replace L266-448 with delegation block; replace L617-623 with one-liner; replace L642-666 with 4-line delegation |
| `core/fix-verification.md` | WI4 | L21 and L26 text edits |
| `core/state-manager.md` | WI4 | L41-43 inline heuristic table |
| `core/fixer-reviewer-loop.md` | WI4 | L44 caller documentation |
| `state/schema.md` | WI4 | L104-106 JSON example + L226 field table (add 3 rows) |

Total: 1 new file, 7 modified files.

## Verification Criteria

1. `core/tracker-subtask-creator.md` follows the Purpose/Input Contract/Process/Output Contract/Failure Handling structure exactly.
2. All three callers' delegation blocks list exactly 9 input fields.
3. No inline curl commands remain in implement-feature.
4. fix-bugs retains exactly 3 skill-specific items in step X (worktree context, per-issue state path, block counter).
5. The fix-bugs step 8b no longer fires an inline webhook.
6. implement-feature step X is <= 5 lines.
7. `core/fix-verification.md` contains "Verified" (not "Fix verified") in both comments.
8. `core/state-manager.md` L41+ contains 6 heuristic checkpoints and no forward reference to resume-ticket.
9. `state/schema.md` e2e_test section has 4 fields (status, attempts, max_attempts, last_result) in both JSON example and field table.
10. `core/fixer-reviewer-loop.md` L44 references all three callers with their distinct enforcement strategies.
11. All existing tests pass (run `./tests/harness/run-tests.sh`).
