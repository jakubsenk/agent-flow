# Phase 6 -- Implementation Plan

## Persona

You are an implementation planner for a markdown-only plugin. You break the specification into ordered tasks with dependencies, estimate effort, and identify parallelization opportunities.

## Context

You are planning the implementation of the scaffold MCP chicken-and-egg fix. Changes affect 2 skill files and 1 docs file. No agents, no core contracts, no state schema changes.

## Tasks to Plan

### Task 1: Modify `skills/init/SKILL.md`
- Add `--tracker-type`, `--tracker-instance`, `--sc-remote` to argument-hint
- Add Step 0: Parameter Override section before Step 1
- Add conditional logic to Step 1 (skip when CLI params provided)
- Update Step 9 closing message for the override path
- **Dependencies:** None (can start immediately)
- **Estimated effort:** Medium (largest single file change, ~40-60 lines added)

### Task 2: Modify `skills/scaffold/SKILL.md`
- Modify Step 0-MCP item 2 (mcp_available: false path)
- Add Configure option with init invocation
- Add YOLO mode behavior
- Update Step 9 Final Report with restart instructions
- **Dependencies:** Task 1 must be completed first (scaffold references init's new parameters)
- **Estimated effort:** Medium (~30-50 lines added/modified)

### Task 3: Update `docs/reference/skills.md`
- Update init entry with new parameters
- **Dependencies:** Task 1 (need to know final parameter names)
- **Estimated effort:** Small (~5-10 lines)

### Task 4: Write/update tests
- Add structural tests per Phase 5 spec
- **Dependencies:** Tasks 1-3 (tests validate the changes)
- **Estimated effort:** Small (~50 lines of test code)

## Parallelization

```
Task 1 (init) ----+----> Task 2 (scaffold) ----> Task 4 (tests)
                   |
                   +----> Task 3 (docs)
```

Tasks 2 and 3 can run in parallel after Task 1 completes.

## Risk Mitigation

| Risk | Mitigation |
|------|------------|
| Init parameter names conflict with existing args | Verify `--update` is the only existing param; new params use `--tracker-*` prefix (no collision) |
| Scaffold Step 0-MCP text becomes too long | Keep the Configure option concise; detailed guidance in init's closing message |
| YOLO mode + init = needs interactive tokens | YOLO should auto-invoke init but allow token prompts (tokens are secrets, not automatable) OR skip init and just downgrade |
| Test harness changes break existing tests | Run full test suite after changes; new tests are additive |

## Validation Checklist

Before marking implementation complete:
- [ ] Init without new params works identically (backward compat)
- [ ] Init with `--tracker-type gitea` skips CLAUDE.md reading
- [ ] Scaffold Step 0-MCP shows Configure option when MCP unavailable
- [ ] Scaffold YOLO mode handles MCP unavailable without hanging
- [ ] All existing tests pass
- [ ] New tests pass
- [ ] No new files created (only modifications)
- [ ] Versioning: determine correct version bump level

## Output

Write implementation plan to `.forge/phase-6-plan/plan.md` with the task dependency graph, file-level changes, and ordered execution sequence.
