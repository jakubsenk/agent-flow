# Edit Examples: skills/implement-feature/SKILL.md

Concrete changes with exact line references from the current file.

---

## Area 1: Mode prefix injection (fixer, reviewer, test-engineer)

### 1a. Fixer dispatch (Step 6b, lines 447-449)

CURRENT (lines 447-449):
> Run the fixer agent (Task tool, model: opus):
> - Context: architectural design + subtask scope + acceptance criteria
> - After completion: run Build command

PROPOSED:
> Run the fixer agent (Task tool, model: opus):
> - Context: `Mode: feature. Pipeline: implement-feature.` + architectural design + subtask scope + acceptance criteria
> - After completion: run Build command

WHY: The fixer agent definition supports both bug-fix and feature-implementation modes. Without the `Mode: feature` prefix, fixer defaults to bug-fix behavior (smaller diffs, defensive changes). With the prefix, fixer knows it can create new files, add larger code blocks, and follow the architectural plan rather than minimizing change surface. fix-ticket uses `Mode: bugfix` implicitly through its triage/code-analyst context. The feature pipeline needs the explicit signal.

### 1b. Reviewer dispatch (Step 6d, lines 459-461)

CURRENT (lines 459-461):
> Run the reviewer agent (Task tool, model: opus):
> - Context: diff from fixer + acceptance criteria from spec-analyst

PROPOSED:
> Run the reviewer agent (Task tool, model: opus):
> - Context: `Mode: feature. Pipeline: implement-feature.` + diff from fixer + acceptance criteria from spec-analyst

WHY: Reviewer applies different review criteria for features vs bugs. For features, reviewer should check architectural alignment with the spec (not just "does this fix the bug"). The mode prefix tells the reviewer to evaluate against the architectural design, not just code correctness.

### 1c. Test-engineer dispatch (Step 6e, lines 484-485)

CURRENT (lines 484-485):
> Run the test-engineer agent (Task tool, model: sonnet):
> - Context: changed files, acceptance criteria

PROPOSED:
> Run the test-engineer agent (Task tool, model: sonnet):
> - Context: `Mode: feature. Pipeline: implement-feature.` + changed files, acceptance criteria

WHY: Test-engineer in feature mode should write tests that cover the full feature surface (including integration tests for new APIs), not just regression tests. The mode prefix steers test generation toward comprehensive feature coverage.

---

## Area 2: NEEDS_DECOMPOSITION handler in fixer (Step 6b)

CURRENT (lines 446-453):
> #### 6b. Fixer
>
> Run the fixer agent (Task tool, model: opus):
> - Context: architectural design + subtask scope + acceptance criteria
> - After completion: run Build command
>
> If build fails -> fixer fixes it (max Build retries attempts).
> If build still fails -> proceed to step X.

There is NO NEEDS_DECOMPOSITION handler here. Compare with fix-ticket lines 447-452, which has a full handler:

```
If fixer output contains `## NEEDS_DECOMPOSITION`:
  1. Authoritative revert: git checkout . && git clean -fd
  2. If decompose_mode = DISABLED -> Block
  3. If this ticket has already been decomposed once -> Block
  4. Run architect agent for decomposition (same as step 4b with FORCE)
  5. Continue with subtask execution (step 4c)
```

PROPOSED (insert after line 453 "If build still fails -> proceed to step X."):
> If fixer output contains `## NEEDS_DECOMPOSITION`:
>   - **Always Block.** Feature pipeline fixer operates within an already-decomposed subtask (or a single-pass backed by architect design). Re-decomposition is not supported.
>   - Proceed to step X (Block handler) with: agent = `fixer`, step = `6b`, reason = `Fixer signaled NEEDS_DECOMPOSITION but the feature pipeline does not support re-decomposition. The architect design or subtask scope may need manual revision.`

WHY: In the bug pipeline, NEEDS_DECOMPOSITION is a valid escape hatch because bugs start without architectural design. In the feature pipeline, the architect already designed the solution and decomposed it. If the fixer still cannot handle a subtask, it is an architect design problem, not something re-decomposition can fix. The always-Block approach forces a human to revise the architectural plan instead of entering an infinite decomposition loop. Without this handler, NEEDS_DECOMPOSITION output from fixer would be silently ignored.

---

## Area 3: Webhook format inconsistencies

### 3a. PR-created webhook (Step 10a, lines 580-583)

CURRENT (lines 580-583):
> If Notifications -> Webhook URL exists and On events contains `pr-created`:
> ```bash
> curl -X POST {webhook_url} -H "Content-Type: application/json" -d '{"event":"pr-created","issue":"{issue_id}","pr":"{pr_url}"}'
> ```

Compare with `core/post-publish-hook.md` (lines 17-22), which is the canonical format:
```bash
curl --max-time 5 --retry 0 -X POST -H "Content-Type: application/json" \
  --data-binary @- "{Webhook URL}" <<EOF
{"event":"pr-created","issue_id":"${issue_id}","pr_url":"${pr_url}","timestamp":"${ISO8601}"}
EOF
```

There are **4 differences**:
1. Missing `--max-time 5 --retry 0` (could hang indefinitely on unresponsive webhook)
2. JSON key `"issue"` should be `"issue_id"` (core contract uses `issue_id`)
3. JSON key `"pr"` should be `"pr_url"` (core contract uses `pr_url`)
4. Missing `"timestamp":"{ISO8601}"` field
5. Using `-d` inline instead of heredoc (fragile with special chars in PR URL)

PROPOSED (replace lines 580-583):
> If Notifications -> Webhook URL exists and On events contains `pr-created`:
>
> Follow `core/post-publish-hook.md` for hook execution and webhook firing.

WHY: implement-feature already references `core/post-publish-hook.md` on line 579, but then duplicates the webhook logic inline with incorrect JSON keys. The fix is to remove the inline duplication and rely solely on the core contract (which fix-ticket already does at its step 9b, line 584). This eliminates the key mismatch (`issue` vs `issue_id`, `pr` vs `pr_url`), adds timeout protection, adds timestamp, and uses the heredoc pattern for shell safety.

### 3b. Block handler webhook (Step X, lines 621-625)

CURRENT (lines 621-625):
> 5. If Notifications -> Webhook URL exists and On events contains `issue-blocked`:
>    ```bash
>    curl -X POST {webhook_url} -H "Content-Type: application/json" -d '{"event":"issue-blocked","issue":"{issue_id}","agent":"{agent}","reason":"{reason}"}'
>    ```

Compare with `core/block-handler.md` (lines 37-42), which is the canonical format:
```bash
curl --max-time 5 --retry 0 -X POST -H "Content-Type: application/json" \
  -d '{"event":"issue-blocked","issue_id":"{issue_id}","agent":"{agent_name}","reason":"{reason}","timestamp":"{ISO8601}"}' \
  "{Webhook URL}"
```

Differences:
1. Missing `--max-time 5 --retry 0`
2. JSON key `"issue"` should be `"issue_id"`
3. Missing `"timestamp":"{ISO8601}"` field

PROPOSED (replace lines 604-626 -- the entire block handler step X):
> ### X. Block handler
>
> Follow `core/block-handler.md`:
>
> 1. Run `ceos-agents:rollback-agent` (Task tool, model: haiku) -- revert git changes
> 2. Set issue state to Blocked (State transitions -> Blocked)
> 3. **On block action** (per Error Handling -> On block):
>    - `comment` (default): Add a Block comment to the issue tracker (see below)
>    - `close`: Add a Block comment + close the issue
>    - Other value: interpret as a custom action (always add a comment)
> 4. Add Block comment to the issue tracker (format from `core/block-handler.md`)
> 5. Fire webhook if configured (format from `core/block-handler.md`)
>
> 6. Update `state.json`: set top-level `status` to `"blocked"`, write `block` object with `{agent, step, reason, detail, recommendation}`. Follow atomic write protocol from `core/state-manager.md`.

WHY: The block handler in implement-feature inlines the webhook curl command with stale JSON keys. fix-ticket (lines 600-604) already delegates to `core/block-handler.md` without inlining the curl. implement-feature should match. The alternative (less invasive) approach: just fix the inline curl to match core format. The delegating approach is better because it prevents future drift.

---

## Area 4: Single-pass acceptance gate gap (Step 6h)

CURRENT (lines 517-527):
> #### 6h. Acceptance gate (always for features)
>
> For features, the acceptance gate always runs within the subtask loop (no threshold condition -- unlike bugs, which require >=3 AC or complexity >=M). In single-pass mode (no decomposition), this step is skipped.
>
> Run `ceos-agents:acceptance-gate` (Task tool, model: sonnet):
>   Context: `Acceptance criteria: {AC from spec-analyst -- full feature AC, not just per-subtask AC}. Changed files: {list of files modified by fixer}.`
>
> If REQUEST_CHANGES -> back to fixer for the LAST subtask (or single-pass) with feedback.
> If APPROVE -> continue to step 6i.
>
> Update `state.json`: set `acceptance_gate.status` to `"completed"` (or `"skipped"` for single-pass), write `acceptance_gate.verdict`. Follow atomic write protocol from `core/state-manager.md`.

The problem: Line 519 says "In single-pass mode (no decomposition), this step is skipped." This means a feature implemented without decomposition gets NO acceptance gate at all. In contrast, the bug pipeline (fix-ticket step 8c, lines 547-549) has a conditional gate: "Run this step ONLY when: Bug has >= 3 acceptance criteria (from triage), OR Bug complexity >= M". Features always have spec-analyst AC, so single-pass features should also get the gate.

PROPOSED (replace lines 517-527):
> #### 6h. Acceptance gate
>
> **Decomposition mode:** The acceptance gate always runs for each subtask within the subtask loop (no threshold condition -- unlike bugs, which require >=3 AC or complexity >=M).
>
> **Single-pass mode:** Run the acceptance gate ONLY when spec-analyst produced >= 3 acceptance criteria. If fewer than 3 AC, skip (the reviewer's AC Fulfillment section provides sufficient coverage for simple features).
>
> Run `ceos-agents:acceptance-gate` (Task tool, model: sonnet):
>   Context: `Acceptance criteria: {AC from spec-analyst -- full feature AC}. Changed files: {list of files modified by fixer}.`
>
> If REQUEST_CHANGES -> back to fixer with feedback (counts toward same Fixer iterations limit).
> If APPROVE -> continue to step 6i (decomposition) or step 8 (single-pass).
>
> Update `state.json`: set `acceptance_gate.status` to `"completed"` (or `"skipped"` if condition not met), write `acceptance_gate.verdict`. Follow atomic write protocol from `core/state-manager.md`.

WHY: The current design creates a quality gap: single-pass features skip the acceptance gate entirely, relying only on the reviewer's AC Fulfillment section. For trivial features (1-2 AC) this is fine. But for substantial single-pass features (3+ AC), there is no independent AC verification. The proposed change adds a threshold gate similar to fix-ticket's conditional gate, ensuring single-pass features with enough AC get the same verification rigor as decomposed features.

---

## Area 5: Smoke-check rollback behavior (Step 6d-smoke)

CURRENT (lines 471-478):
> #### 6d-smoke. Smoke check (build + test)
>
> After fixer<->reviewer approval, verify the codebase still builds and existing tests pass before proceeding to test-engineer.
>
> 1. Read `Build command` and `Test command` from Automation Config.
> 2. Run Build command via Bash. If it fails -> Block handler (step X) with `agent = smoke-check, Step = 6d-smoke, Reason = Build command failed after fixer<->reviewer approval`.
> 3. Run Test command via Bash. If it fails -> Block handler (step X) with `agent = smoke-check, Step = 6d-smoke, Reason = Existing tests failed after fixer<->reviewer approval`.
> 4. Both pass -> continue to step 6e.

The issue: When smoke-check fails and calls Block handler (step X), the block handler (line 606) dispatches `ceos-agents:rollback-agent` which "reverts git changes". But core/block-handler.md line 21 says rollback only triggers for agents `fixer`, `reviewer`, or `test-engineer`. The agent name here is `smoke-check`, which is NOT in that list. This means a smoke-check failure would NOT trigger rollback, leaving the branch in a broken state.

PROPOSED (replace lines 471-478):
> #### 6d-smoke. Smoke check (build + test)
>
> After fixer<->reviewer approval, verify the codebase still builds and existing tests pass before proceeding to test-engineer.
>
> 1. Read `Build command` and `Test command` from Automation Config.
> 2. Run Build command via Bash. If it fails -> Block handler (step X) with `agent = fixer, Step = 6d-smoke, Reason = Build command failed after fixer<->reviewer approval, Detail = {build error output}`.
> 3. Run Test command via Bash. If it fails -> Block handler (step X) with `agent = fixer, Step = 6d-smoke, Reason = Existing tests failed after fixer<->reviewer approval, Detail = {test error output}`.
> 4. Both pass -> continue to step 6e.
>
> Note: `agent = fixer` (not `smoke-check`) ensures `core/block-handler.md` triggers rollback, since rollback only activates for `fixer`, `reviewer`, or `test-engineer`. The smoke-check failure occurs in fixer-produced code.

WHY: The smoke-check validates fixer's output. If it fails, the fixer's changes are broken and should be rolled back. Using `agent = smoke-check` as the agent name bypasses the rollback guard in core/block-handler.md. Using `agent = fixer` correctly attributes the failure to fixer code and ensures rollback fires. This is the same pattern fix-ticket uses at step 7a (lines 486-492), where the smoke check uses `agent = smoke-check` -- which has the SAME bug. Both should be fixed together.

### 5b. Same issue in fix-ticket (Step 7a, lines 486-492)

For reference, fix-ticket has the identical problem at step 7a (lines 486-492):
> 1. Run Build command. If fails -> proceed to Block handler (step X).
>    Block context: agent = `smoke-check`, step = `post-review smoke check`, detail = build error output.

This should also use `agent = fixer` to trigger rollback. Both files should be fixed in the same commit.

---

## Summary of all changes

| # | Area | File | Lines | Severity |
|---|------|------|-------|----------|
| 1a | Mode prefix: fixer | implement-feature | 448 | Medium -- behavioral drift |
| 1b | Mode prefix: reviewer | implement-feature | 460-461 | Medium -- behavioral drift |
| 1c | Mode prefix: test-engineer | implement-feature | 484-485 | Medium -- behavioral drift |
| 2 | NEEDS_DECOMPOSITION handler | implement-feature | after 453 | High -- silent data loss |
| 3a | Webhook: pr-created format | implement-feature | 580-583 | Medium -- wrong JSON keys |
| 3b | Webhook: block handler format | implement-feature | 621-625 | Medium -- wrong JSON keys |
| 4 | Single-pass AC gate | implement-feature | 517-527 | Medium -- quality gap |
| 5a | Smoke-check rollback agent name | implement-feature | 476-477 | High -- rollback bypass |
| 5b | Smoke-check rollback agent name | fix-ticket | 488-489 | High -- rollback bypass (same bug) |
