# Phase 7 — Execute

You are implementing the design awareness feature for the ceos-agents scaffold pipeline. Follow the plan exactly.

## Context

Read:
- `.forge/phase-6-plan/plan.md` — implementation plan with task graph
- `.forge/phase-4-spec/spec.md` — specification
- `.forge/phase-4-spec/formal-criteria.md` — acceptance criteria
- `.forge/phase-5-tdd/test-plan.md` — test scenarios (tests are already written)

## Execution Rules

1. **Follow the plan** — implement tasks in the order specified by `execution_order`. Do not skip tasks or reorder.
2. **100-line diff limit** — each task must produce a diff of at most 100 lines. If you're approaching the limit, split the remaining work into a continuation task.
3. **Test after each task** — run the associated test(s) after completing each task. If a test fails, fix before proceeding.
4. **Preserve existing structure** — agent files must maintain their exact format (frontmatter + Goal + Expertise + Process + Constraints). Do not rewrite entire files; make surgical edits.
5. **Conditional design awareness** — all design-related additions must be conditional on web project detection. Backend/CLI projects must be completely unaffected.
6. **No aesthetic choices** — never hardcode colors, fonts, spacing values, or visual design decisions. Reference framework defaults and presets only.
7. **Backward compatibility** — run ALL existing tests after each batch of tasks. If any existing test fails, fix immediately.

## Per-Task Execution

For each task in the plan:

1. Read the target file(s) completely
2. Identify the exact insertion/modification points
3. Make the changes using the Edit tool (prefer Edit over Write for existing files)
4. Run the associated test(s): `bash tests/scenarios/{test-name}.sh`
5. If test fails: diagnose, fix, re-run
6. Run the full test suite: `bash tests/harness/run-tests.sh`
7. If any existing test fails: diagnose, fix, re-run
8. Report task completion

## Commit Strategy

After each batch of tasks:
```bash
git add {specific files changed}
git commit -m "feat(scaffold): {batch description}

Part of: scaffold design awareness feature"
```

Do NOT commit failing code. Every commit must pass the full test suite.

## Quality Checks

After all tasks are complete:
1. Run the full test suite: `bash tests/harness/run-tests.sh`
2. Verify no agent file has broken frontmatter (all must have name, description, model, style)
3. Verify no design-related content appears in non-conditional contexts
4. Count total lines changed across all files — compare to plan estimates
5. List any deviations from the plan with justification

## Output

Save execution log to `.forge/phase-7-execute/execution-log.md` with:
- Per-task: files changed, lines changed, tests passed/failed, deviations from plan
- Summary: total files changed, total lines changed, all tests passing (yes/no)
