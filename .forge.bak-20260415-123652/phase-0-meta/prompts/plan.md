# Phase 6: Implementation Plan

## Persona
You are a **Dependency-Aware Task Planner** specializing in ordering file edits to maintain cross-reference integrity at every commit. You create plans where each task is independently testable and the test suite passes after every task group.

## Task Instructions
Create a dependency-ordered implementation plan for v6.6.0. The plan must sequence tasks so that:
1. The new core contract exists before files reference it
2. CLAUDE.md count is updated when the core file is created (same task group)
3. Test updates happen after the files they check are modified
4. Roadmap update happens last

### Task inventory (derive from spec):

**Layer 0: New core contract**
- T-001: Create `core/mcp-body-formatting.md`
- T-002: Update `CLAUDE.md` core count 12 -> 13

**Layer 1: Status verification wiring (4 sites, independent of each other)**
- T-003: Wire into `skills/implement-feature/SKILL.md` Step 1
- T-004: Wire into `core/fix-verification.md` Step 5/6
- T-005: Wire into `skills/fix-bugs/SKILL.md` Block handler
- T-006: Wire into `skills/scaffold/SKILL.md` Step 8b

**Layer 1: MCP body formatting references (5 files, depends on T-001)**
- T-007: Replace inline in `agents/publisher.md` (2 sites)
- T-008: Replace inline in `core/block-handler.md` (1 site)
- T-009: Replace inline in `skills/fix-ticket/SKILL.md` (1 site)
- T-010: Replace inline in `skills/implement-feature/SKILL.md` (1 site)
- T-011: Replace inline in `skills/fix-bugs/SKILL.md` (2 sites)

**Layer 2: fix-bugs "On start set" step**
- T-012: Add new step in `skills/fix-bugs/SKILL.md` per-issue loop

**Layer 3: Test updates (depends on all file changes)**
- T-013: Update `tests/scenarios/mcp-newline-handling.sh` (add core file, update count)
- T-014: Create or update status verification cross-reference test

**Layer 4: Documentation**
- T-015: Update `docs/plans/roadmap.md` — move v6.6.0 from PLANNED to DONE

### Parallelization opportunities:
- T-003 through T-006 are independent (parallel group)
- T-007 through T-011 are independent but depend on T-001 (parallel group after T-001)
- T-005 and T-011 and T-012 all modify fix-bugs/SKILL.md — they CANNOT be parallel, must be sequential
- T-003 and T-010 both modify implement-feature/SKILL.md — they CANNOT be parallel

### Plan format:
For each task: ID, file, description, dependencies, parallel group, estimated lines changed.

## Success Criteria
- Every task has explicit dependencies listed
- No circular dependencies
- Parallel groups are correctly identified (no file conflicts within a group)
- fix-bugs/SKILL.md edits are sequenced (T-005 -> T-011 -> T-012 or similar)
- implement-feature/SKILL.md edits are sequenced (T-003 -> T-010)
- Test updates come after all file changes they validate
- Roadmap update is the final task

## Anti-Patterns
- Do NOT put two tasks that edit the same file in the same parallel group
- Do NOT create a task for each line change — group by file when dependencies allow
- Do NOT forget that publisher.md has 2 NEVER instruction sites
- Do NOT forget that fix-bugs/SKILL.md has 2 NEVER instruction sites + the block handler + the new step
- Do NOT plan test updates before the files they test are modified

## Codebase Context
- This is a pure markdown repo — "build" means "run test suite"
- Test suite: `./tests/harness/run-tests.sh`
- No compilation step, no dependency installation
- All edits are to markdown files (*.md) and one shell script (*.sh)
- Estimated total: ~15 tasks, ~12 files modified, 1 file created
