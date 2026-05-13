# Phase 1 — Research Questions: Synthesis

## RQ-1: Scaffold pipeline dispatch overlap
**Answer:** YES — scaffold dispatches fixer (line 674), reviewer (line 681), test-engineer (line 691) in Step 7. A **three-mode branch** (bug/feature/scaffold) is required, not just two.
**Key difference:** Scaffold passes subtask scope + spec/ folder reference + no issue ID. Block output goes to stdout, not tracker.
**Impact:** Every mode-branch added to fixer/reviewer/test-engineer must handle scaffold as a third mode, or use a safe default path that works for any non-bug context.

## RQ-2: Test harness structural validation
**Answer:** 4 tests validate agent structure. Mode-branch additions are SAFE with one constraint: reviewer.md Process must not contain `Write tool`, `Edit tool`, `write to file`, `create file`, `save file` phrases (read-only agent check).
**Tests:** frontmatter-completeness, section-order (Goal→Expertise→Process→Constraints), model-assignment, read-only-agents.
**Impact:** No change to plan. Just avoid write-tool phrases in reviewer Process additions.

## RQ-3: Existing mode-branch patterns
**Answer:** 4 established patterns found:
1. **Dedicated section** (spec-reviewer:75-127) — `## Verify Mode (--verify)` with alternate process. Best for major divergence.
2. **Inline conditional** (scaffolder:23-24) — `If spec/README.md provided (scaffold v2 mode)...`. Best for 1-2 step variations.
3. **Named execution paths** (rollback-agent:37-55) — Bold `In Worktree mode:` / `In CWD mode:` prefixes in single step.
4. **Implicit source hint** (acceptance-gate:21) — `from triage-analyst for bugs, spec-analyst for features`.
**Impact:** Use inline conditional pattern (Pattern 2) for most agent edits — only 1-2 steps vary per agent. Consistent with existing codebase style.

## RQ-4: fix-bugs NEEDS_DECOMPOSITION
**Answer:** fix-bugs has its OWN handler at line 434. Does NOT delegate to fix-ticket. Both have parallel, independently maintained 5-step handlers.
**Impact:** NEEDS_DECOMPOSITION changes must be applied to BOTH fix-bugs AND fix-ticket. Adds scope — plan must include fix-bugs as a potential 11th file to edit.

## RQ-5: State schema consumers
**Answer:** 6 consumers of `triage.acceptance_criteria`. No consumer references `ac_source` — field is new.
- Writers: fix-ticket:145, fix-bugs:124, implement-feature:182, scaffold:434
- Reader: resume-ticket:24-25
- Core: fixer-reviewer-loop:13
**Impact:** Adding `ac_source` is safe and additive. Four write sites need companion `ac_source` write for full provenance tracking.

## RQ-6: smoke-check rollback — CONTRADICTS USER ASSUMPTION
**Answer:** smoke-check is INTENTIONALLY excluded from rollback trigger lists. Rolling back after an approved fixer-reviewer loop would discard approved code — the exclusion is correct design.
- block-handler:21 trigger list: fixer, reviewer, test-engineer (no smoke-check)
- rollback-agent:26 allowlist: fixer, test-engineer, e2e-test-engineer, reviewer (no smoke-check)
- implement-feature:471 calls smoke-check with `agent = smoke-check, Step = 6d-smoke`
**Impact:** DO NOT add smoke-check to rollback allowlist. This CRQ should be reclassified or dropped. Document the intentional exclusion instead.

## Summary of Plan Adjustments

| Original Plan Item | Adjustment |
|---|---|
| Two-mode branch (bug/feature) | Expand to three-mode or use "non-bug" umbrella that covers feature + scaffold |
| Add smoke-check to rollback triggers | DROP — exclusion is intentional design, not a gap |
| NEEDS_DECOMPOSITION in implement-feature only | Also check fix-bugs:434 for consistency |
| reviewer.md Process edits | Avoid write-tool phrases (read-only check) |
| ac_source in state/schema.md only | Four write sites need companion ac_source updates |
