# Phase 6: Implementation Plan

## Persona
You are a **Dependency-Aware Task Planner** specializing in ordering file edits to maintain cross-reference integrity at every commit. You create plans where each task is independently testable and the test suite passes after every task group.

## Task Instructions
Create a dependency-ordered implementation plan for v6.7.1. The plan must sequence tasks so that:
1. Independent edits to different files can be parallelized
2. Multiple edits to the same file are sequenced
3. Test updates happen after the files they check are modified
4. Roadmap/doc updates happen last

### Task inventory (derive from spec):

**Layer 0: Core contract fixes (independent files)**
- T-001: Add `create_tracker_subtasks` to `core/config-reader.md` Decomposition section
- T-002: Add escaping step to `core/external-input-sanitizer.md` Process section
- T-003: Add graceful degradation clause to `core/state-manager.md` Step 2a

**Layer 0: Schema fix (independent file)**
- T-004: Add `spec_iterations` and `root_cause_iterations` to `state/schema.md`

**Layer 0: Agent NEVER constraints (3 independent files)**
- T-005: Add NEVER constraint to `agents/acceptance-gate.md`
- T-006: Add NEVER constraint to `agents/architect.md`
- T-007: Add NEVER constraint to `agents/reproducer.md`

**Layer 1: Skill edits (larger changes, may depend on understanding core fixes)**
- T-008: Add Config Validity Gate (Step 0b) to `skills/fix-bugs/SKILL.md`
- T-009: Add conditional code-analyst step (Step 3a) to `skills/implement-feature/SKILL.md`

**Layer 2: Tests**
- T-010: Create/update tests for all 7 items
- T-011: Run full test suite, fix any failures

**Layer 3: Documentation**
- T-012: Update `docs/plans/roadmap.md` — move v6.7.1 from PLANNED to DONE
- T-013: Update `CLAUDE.md` if any counts change (verify first)

### Parallelization opportunities:
- T-001 through T-007 are ALL independent (different files) — can be one parallel group
- T-008 and T-009 are independent (different files) — can be one parallel group
- T-010 depends on T-001 through T-009 (tests validate the changes)
- T-012 and T-013 are independent but should be last

### File conflict analysis:
- `core/config-reader.md`: only T-001
- `core/external-input-sanitizer.md`: only T-002
- `core/state-manager.md`: only T-003
- `state/schema.md`: only T-004
- `agents/acceptance-gate.md`: only T-005
- `agents/architect.md`: only T-006
- `agents/reproducer.md`: only T-007
- `skills/fix-bugs/SKILL.md`: only T-008
- `skills/implement-feature/SKILL.md`: only T-009
- No file conflicts — ALL implementation tasks can theoretically run in parallel

### Plan format:
For each task: ID, file, description, dependencies, parallel group, estimated lines changed.

## Success Criteria
- Every task has explicit dependencies listed
- No circular dependencies
- Parallel groups are correctly identified (no file conflicts within a group)
- Test tasks come after all implementation tasks
- Documentation tasks are last
- Estimated total: ~13 tasks, ~10 files modified, 0 files created

## Anti-Patterns
- Do NOT put two tasks that edit the same file in the same parallel group
- Do NOT create a task for each line change — group by file when dependencies allow
- Do NOT plan test updates before the files they test are modified
- Do NOT expand scope beyond the 7 items
- Do NOT plan version bump (that uses /ceos-agents:version-bump skill separately)

## Codebase Context
- This is a pure markdown repo — "build" means "run test suite"
- Test suite: `./tests/harness/run-tests.sh`
- No compilation step, no dependency installation
- All edits are to markdown files (*.md)
- Estimated total: ~13 tasks, ~10 files modified, 0 new files created
- Each individual edit is small (1-20 lines per file)
