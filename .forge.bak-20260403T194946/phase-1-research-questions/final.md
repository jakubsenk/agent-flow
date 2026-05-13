# Phase 1 — Research Synthesis

## Executive Summary

Two bugs in `skills/implement-feature/SKILL.md` confirmed with 6 specific gaps identified. The confirmation flow is actually well-designed; the real problem is subtask persistence.

## Bug 1: Subtask Persistence Failure — CONFIRMED, 4 gaps

### Gap 1 (HIGH): No per-subtask status update during execution
- **Location:** Step 6h (lines 316-323)
- **Problem:** After committing a subtask, only `commit_hash` and `restore_point` are saved to the YAML file. No instruction to set `status = "completed"` in either YAML or `state.json`.
- **Impact:** Step 6 checks `depends_on` have status "completed" but this status is never written. The dependency check has no reliable data source.
- **Fix reference:** `agents/architect.md` line 72 explicitly says "The orchestrating command adds runtime fields (status, commit_hash, restore_point)" — the skill fails to do this for `status`.

### Gap 2 (MEDIUM): SINGLE_PASS path bypasses all decomposition writes
- **Location:** Step 5, line 193 — "single-pass (step 6 directly)"
- **Problem:** When decompose_mode = DISABLED or AUTO→SINGLE_PASS, Step 5 is skipped entirely. `decomposition.status` stays "pending", `decomposition.decision` stays null.
- **Fix:** Add a minimal write before the jump: set `decomposition.status = "completed"`, `decomposition.decision = "SINGLE_PASS"`.

### Gap 3 (MEDIUM): Step 6h underspecified for LLM executor
- **Location:** Step 6h (lines 316-323)
- **Problem:** "Update the task tree state on disk (.claude/decomposition/)" specifies directory but not filename, not field schema, no atomic write protocol reference, no `state.json` update.
- **Fix reference:** Needs explicit instruction like: "Read `.claude/decomposition/{ISSUE-ID}.yaml`, update current subtask with `status: completed`, `commit_hash: {hash}`, `restore_point: {hash}`. Write back. Also update `state.json` `decomposition.subtasks[N]` with same fields."

### Gap 4 (LOW): No explicit `mkdir` for `.claude/decomposition/`
- **Location:** Step 5, line 235
- **Problem:** Step 5 writes to `.claude/decomposition/{ISSUE-ID}.yaml` but never creates the directory.
- **Fix:** Add `mkdir -p .claude/decomposition/` before the write instruction.

## Bug 2: Confirmation Flow — NOT A BUG (minor doc gap only)

### Finding: All 5 confirmation points are correctly implemented

| # | Step | Prompt | YOLO Behavior | Verdict |
|---|------|--------|---------------|---------|
| 1 | 0c | `Create anyway? [y/N]` (duplicate) | Skips check entirely | Correct |
| 2 | 0c | `Create this card? [Y/n]` (preview) | Auto-creates | Correct |
| 3 | 5 | `Continue anyway? [Y/n]` (unmapped AC) | BLOCK (stricter) | Correct |
| 4 | 5 | `Continue? [Y/n]` (decomposition plan) | Auto-approves | Correct |
| 5 | 9 | `Create PR? [Y/n]` (publish) | Auto-creates PR | Correct |

### Minor doc gap: YOLO scope not documented in implement-feature
- fix-ticket explicitly documents YOLO scope in its preamble (line 16-17)
- implement-feature only has YOLO in the argument-hint, not in the intro
- The unmapped-AC BLOCK behavior is not mentioned in the argument-hint

## Secondary Findings

### fix-ticket has the same Step 4c underspecification
- fix-ticket Step 4b saves YAML but has NO state.json decomposition writes at all
- fix-ticket Step 4c per-subtask update is equally vague
- Both skills share the same root cause for persistence gaps

### State schema gap
- `state/schema.md` defines `decomposition.subtasks` as `object[]` but never specifies the runtime subtask object shape (status, commit_hash, restore_point)
- `agents/architect.md` references these fields but the schema doesn't document them

### Stale cross-reference
- `core/decomposition-heuristics.md` Output Contract references "see fix-ticket steps 4b-4c" for execution, but the full decomposition loop is in implement-feature

## Scope Decision for This Fix

**In-scope (implement-feature only):**
1. Fix Gap 1: Add per-subtask status update to Step 6h
2. Fix Gap 2: Add SINGLE_PASS decomposition writes
3. Fix Gap 3: Make Step 6h explicit with filename, fields, protocol
4. Fix Gap 4: Add mkdir instruction to Step 5
5. Add YOLO scope documentation to implement-feature intro

**Out-of-scope (separate tickets):**
- fix-ticket parallel gaps (same root cause, different file)
- state/schema.md subtask object shape definition
- core/decomposition-heuristics.md stale cross-reference
