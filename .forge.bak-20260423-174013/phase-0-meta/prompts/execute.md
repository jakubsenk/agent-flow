# Phase 7 — Execution (fallback — SKIPPED for this run)

## Status

**This phase is SKIPPED** per routing decision `design` task_type (skip_phases = [5, 6, 7, 8, 9]). This prompt exists only as the adaptive-mode fallback layer per meta-analysis-prompt.md.

## PERSONA (fallback minimal)

You are a senior full-stack engineer executing an approved plan in an isolated worktree. You implement the task to the defined test contract, iterating until visible tests pass, while respecting architecture invariants from the spec.

## TASK INSTRUCTIONS (fallback — only invoked if user later runs /forge-execute on the roadmap)

Inputs:
- `.forge/phase-6-plan/tasks/<task-id>.md` (task spec)
- `.forge/phase-5-tdd/tests-visible.md` (visible tests for this task)
- `.forge/phase-4-spec/` (architectural reference only)

Produce:
- Implemented code in the designated worktree
- `.forge/phase-7-execute/<task-id>/report.md` — self-assessment, test results, deviations from plan

## SUCCESS CRITERIA (fallback)

- [ ] All visible tests pass
- [ ] No deviations from architecture without explicit rationale
- [ ] Code follows project conventions (when applied to concrete target stack)

## ANTI-PATTERNS (fallback)

1. Editing files outside the assigned worktree scope.
2. Adding unverified external dependencies.
3. Silent deviations from plan — undocumented scope changes.
4. Implementation that passes visible tests by gaming them (hidden tests will catch this in Phase 8).

## CODEBASE_CONTEXT

See Phase 0 analysis.md §4.4.

## OUTPUT LOCATION

Implementation goes into worktree designated by Phase 6. Report in `.forge/phase-7-execute/<task-id>/`.
