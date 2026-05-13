# Phase 2 — Research Answers: Final Synthesis

## RQ-1: Scaffold Pipeline Dispatch — THREE-WAY BRANCH REQUIRED
**Verdict:** Validated. Scaffold dispatches fixer (line 674), reviewer (681), test-engineer (691) with structurally different context: no issue ID, no Mode prefix, hooks suppressed, per-subtask commits, rollback-agent gets "No issue tracker context" instruction.
**Decision:** Three-way branch (bug-fix / feature / scaffold). Cannot collapse scaffold into feature mode.
**Approach:** Inject `Mode: {bug-fix|feature|scaffold}` at skill dispatch time. Agent Step 1 uses inline conditional to branch behavior.

## RQ-2: Test Harness Constraints — SAFE WITH ONE CONSTRAINT
**Verdict:** Validated. 53 test scenarios; 4 check agent structure.
**Constraints:**
- `read-only-agents.sh`: reviewer Process section must NOT contain "Write tool", "Edit tool", "write to file", "create file", "save file"
- `section-order.sh`: ## headers must be Goal → Expertise → Process → Constraints in order. ### subsections are safe.
- No test checks specific numbered step wording or content
**Decision:** Use inline conditionals within existing Process steps. No new ## sections. Safe.

## RQ-3: Mode-Branch Pattern — INLINE CONDITIONAL RECOMMENDED
**Verdict:** Validated. Spec-reviewer's dedicated section is overkill. Scaffolder's inline conditional is the right fit.
**Pattern:** Add 2-4 sentence conditional block at Step 1 of each agent:
```
If context contains `Mode: bug-fix` (or no Mode prefix for backward compatibility):
  [existing bug-fix behavior]
If context contains `Mode: feature` or `Mode: scaffold`:
  [feature/scaffold-specific behavior]
```
**Scope per agent:**
- fixer: Steps 1, 5, output section names (3 changes)
- reviewer: Steps 1, 2 (2 changes)
- test-engineer: Steps 1, 3 (2 changes)
- e2e-test-engineer: Step 1 only (1 change)

## RQ-4: NEEDS_DECOMPOSITION — BLOCKING GAP CONFIRMED
**Verdict:** Validated. implement-feature Step 6b has NO handler. Signal falls through silently.
- fix-ticket has handler at line 447
- fix-bugs has handler at line 434
- implement-feature has NOTHING at Step 6b
**Decision:** Add NEEDS_DECOMPOSITION handler to implement-feature Step 6b. Model after fix-ticket but adapted: in decomposition mode (subtask loop), block immediately; in single-pass mode, escalate to re-decomposition.

## RQ-5: State Schema — SAFE AND ADDITIVE
**Verdict:** Validated. No existing `ac_source` references. 4 write consumers, 2 read consumers.
**Write sites needing ac_source companion:**
- fix-ticket → `"triage-analyst"`
- fix-bugs → `"triage-analyst"`
- implement-feature → `"spec-analyst"`
- scaffold → `"spec-writer"`
**Decision:** Add ac_source field to state/schema.md + update the 4 write sites.

## RQ-6: Smoke-Check Rollback — PHASE 1 CORRECTED, GAP IS REAL
**Verdict:** Phase 1 was wrong. Exclusion is NOT intentional — it's a genuine gap.
**Evidence:**
- block-handler:21 only excludes read-only agents (triage-analyst, code-analyst) with explicit "no git changes to revert" rationale
- smoke-check runs AFTER fixer commits exist — git changes DO exist to revert
- rollback-agent Step 1: smoke-check matches no branch → silent no-op (block comment posts but git not reverted)
- Prior audit (docs/plans/review-report-response.md) classifies as CRQ-4 P0 BLOCKING
**Decision:** ADD smoke-check to both block-handler trigger list and rollback-agent allowlist.

## Consolidated Edit Plan Adjustments

| # | Item | Phase 1 View | Phase 2 Correction | Final Action |
|---|------|------|------|------|
| 1 | Mode branching | Two-way (bug/feature) | Three-way (bug/feature/scaffold) | Expand to three-way |
| 2 | Mode pattern | TBD | Inline conditional at Step 1 | Use scaffolder pattern |
| 3 | smoke-check rollback | Drop (intentional) | Gap is real (P0 BLOCKING) | ADD to rollback triggers |
| 4 | NEEDS_DECOMPOSITION | implement-feature only | Confirmed only implement-feature missing | Add handler modeled on fix-ticket |
| 5 | ac_source | Schema only | 4 write sites + schema | Update all 5 locations |
| 6 | Test safety | Avoid write phrases | reviewer Process is the only risk | Confirmed safe |
