# Phase 1 — Research Questions

## Context

Prior research (Phase 2 audit) has already been completed and is available at:
- `docs/plans/implement-feature-agent-audit-REVIEW.md` — 12 CRQs, all CONFIRMED
- The audit identified 4 BLOCKING + 4 HIGH + 4 MEDIUM issues across 10 files

This phase focuses on **residual unknowns** not covered by the prior audit.

## Research Questions

### RQ-1: Scaffold pipeline agent dispatch overlap
**Question:** Does the scaffold pipeline (`skills/scaffold/SKILL.md`) dispatch fixer, reviewer, or test-engineer in a way that would be affected by the mode-aware changes we're adding?
**Why it matters:** If scaffold passes different context shapes, our mode-branch logic in fixer/reviewer/test-engineer must handle three modes (bug, feature, scaffold) not just two.
**Search strategy:** Read `skills/scaffold/SKILL.md`, grep for `fixer`, `reviewer`, `test-engineer` dispatch points. Check what context is passed.

### RQ-2: Test harness coverage of agent definitions
**Question:** Which tests in `tests/harness/` validate agent file structure? Will our edits (adding mode-branch paragraphs to Process steps) trigger any structural validation failures?
**Why it matters:** Need to understand test constraints before making changes.
**Search strategy:** Read `tests/harness/run-tests.sh` and all test scenario files. Identify structural validation rules.

### RQ-3: Existing mode-branch patterns in agents
**Question:** Are there any existing agents that already implement mode-aware branching? What pattern do they use?
**Search strategy:** Grep all `agents/*.md` files for "mode", "feature", "bug-fix", "pipeline". Read `agents/acceptance-gate.md` line 21 as known example.

### RQ-4: fix-bugs skill NEEDS_DECOMPOSITION handling
**Question:** Does `skills/fix-bugs/SKILL.md` have a NEEDS_DECOMPOSITION handler, or does it delegate to fix-ticket? Need to verify we don't need to add a handler there too.
**Search strategy:** Read `skills/fix-bugs/SKILL.md`, grep for NEEDS_DECOMPOSITION.

### RQ-5: State schema consumers
**Question:** Which files read `triage.acceptance_criteria` from state.json? Adding `triage.ac_source` field — need to verify no consumer will break.
**Search strategy:** Grep for `acceptance_criteria`, `ac_source`, `triage.` across skills/ and core/.

### RQ-6: Block-handler smoke-check invocation path
**Question:** In the implement-feature skill, Step 6d-smoke passes `agent = smoke-check` to the block handler. Verify the exact string used and ensure our rollback-agent allowlist addition matches.
**Search strategy:** Read `skills/implement-feature/SKILL.md` Step 6d-smoke. Also check `skills/fix-ticket/SKILL.md` for any smoke-check invocation.

## Output Format

For each RQ, provide:
- **Answer:** Direct answer to the question
- **Evidence:** File:line references
- **Impact on plan:** How this affects the edit plan (no change / adjust approach / new file needed)
