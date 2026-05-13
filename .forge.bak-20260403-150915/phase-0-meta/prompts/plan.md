# Phase 6 — Implementation Plan

You are creating a detailed implementation plan with dependency graph and task decomposition for adding design awareness to the ceos-agents scaffold pipeline.

## Context

Read:
- `.forge/phase-4-spec/spec.md` — specification
- `.forge/phase-4-spec/formal-criteria.md` — acceptance criteria
- `.forge/phase-5-tdd/test-plan.md` — test scenarios
- `CLAUDE.md` — plugin architecture, agent definition format

## Planning Constraints

1. **Pure markdown** — all changes are to .md files. No build, no compile, no runtime.
2. **100-line diff limit per task** — the fixer agent (or subagent) can change at most 100 lines per task. Plan accordingly.
3. **Agent definition format** — frontmatter (name, description, model, style) + Goal + Expertise + Process + Constraints. Must be preserved exactly.
4. **Backward compatibility** — existing tests in `tests/scenarios/` must continue to pass.
5. **Test-first** — tests from Phase 5 are written first, implementation makes them pass.

## Task Decomposition

Break the implementation into tasks that respect the 100-line diff limit. Each task must:
- Have a clear scope (specific file(s) to modify)
- Have testable completion criteria (which test(s) it makes pass)
- Specify dependencies on other tasks
- Estimate diff size (lines added/modified/removed)

### Suggested Task Structure

**Task 1: stack-selector.md — Add CSS framework selection**
- Modify Process step 4 to include CSS/design framework category
- Modify Output to include CSS framework in the stack selection
- Add constraint about web vs non-web detection
- ~30-50 lines changed
- Dependencies: none
- Tests: scaffold-design-stack-selector.sh

**Task 2: spec-writer.md — Add conditional Design & UX section**
- Add conditional "Design & UX" section to the spec generation process
- Section only generated when project type includes web frontend
- Include: CSS framework, responsive approach, accessibility requirements
- ~40-60 lines changed
- Dependencies: none (can run parallel with Task 1)
- Tests: scaffold-design-spec-writer.sh

**Task 3: scaffolder.md — Add design batch for web projects**
- Add Batch 6 (or extend existing batches) for design-related files
- Conditional on web project detection
- Include: CSS framework config, base layout, accessibility setup
- ~50-70 lines changed
- Dependencies: Task 1 (needs to know what CSS framework was selected)
- Tests: scaffold-design-scaffolder.sh

**Task 4: spec-reviewer.md — Add Design & UX section validation**
- Add the new section to completeness checks (conditional)
- Add quality checks for design requirements
- ~20-30 lines changed
- Dependencies: Task 2 (needs to know what the section looks like)
- Tests: scaffold-design-spec-reviewer.sh

**Task 5: skills/scaffold/SKILL.md — Add detection logic and context passing**
- Add web project detection in pipeline orchestration
- Pass design flag to scaffolder and fixer contexts
- ~30-50 lines changed
- Dependencies: Tasks 1-4 (needs all agent changes to exist)
- Tests: scaffold-design-detection.sh

**Task 6: Documentation and test updates**
- Update CLAUDE.md agent table if new agent added
- Update docs/reference files
- Ensure all test scenarios pass
- ~20-40 lines changed
- Dependencies: Tasks 1-5
- Tests: scaffold-design-backward-compat.sh, scaffold-design-no-aesthetic-choices.sh, scaffold-design-accessibility.sh

## Output Format

Save the plan to `.forge/phase-6-plan/plan.md` with:

```yaml
tasks:
  - id: "task-1"
    title: "..."
    scope: "..."
    files:
      - path/to/file.md
    estimated_lines: N
    depends_on: []
    tests: ["test-name.sh"]
    acceptance_criteria:
      - "..."
  - id: "task-2"
    ...

execution_order:
  - batch_1: ["task-1", "task-2"]  # parallel
  - batch_2: ["task-3", "task-4"]  # parallel, depends on batch_1
  - batch_3: ["task-5"]            # depends on batch_2
  - batch_4: ["task-6"]            # depends on batch_3

total_estimated_lines: N
risk_assessment: "..."
```

Also save a dependency graph visualization (ASCII art) showing task ordering and parallelization opportunities.
