# Phase 6: Implementation Plan

## Persona
{{PERSONA}}: Senior Plugin Architect specializing in cross-cutting feature implementation, markdown-based plugin systems, and systematic multi-file change coordination.

## Task Instructions
{{TASK_INSTRUCTIONS}}:

Create a detailed, dependency-ordered implementation plan for the Decomposition Subtask Tracker Creation feature (v6.4.0). The plan must decompose work into tasks that can be executed by subagents in isolated worktrees where possible.

### Planning Protocol

1. **Identify all files to modify** with specific changes per file
2. **Order tasks by dependency** — config contract before skills, state schema before skills
3. **Group parallelizable tasks** — the 3 skill files can be updated in parallel
4. **Identify verification steps** between task groups

### Task Decomposition

#### Group 1: Foundation (sequential, must complete before Group 2)

**Task 1.1: State Schema Update**
- File: `state/schema.md`
- Change: Add `tracker_id` field to Subtask Object Fields table
- Details: Add row after `maps_to` row: `| tracker_id | string or null | No | null | Tracker issue ID created for this subtask. Populated by "Create tracker subtasks" step. Format depends on tracker type (e.g., "PROJ-43" for YouTrack/Jira, "#123" for GitHub/Gitea). |`
- Estimated lines: ~3

**Task 1.2: Config Contract Update (CLAUDE.md)**
- File: `CLAUDE.md`
- Change: Update Decomposition row in optional sections table
- Details: Change `| Decomposition | Max subtasks, Fail strategy, Commit strategy | 7, fail-fast, squash |` to `| Decomposition | Max subtasks, Fail strategy, Commit strategy, Create tracker subtasks | 7, fail-fast, squash, true |`
- Also update pipeline diagrams (Bug-Fix Pipeline and Feature Pipeline) to show the new step
- Estimated lines: ~5-10

#### Group 2: Core Implementation (parallelizable — 3 independent skill files)

**Task 2.1: implement-feature/SKILL.md**
- File: `skills/implement-feature/SKILL.md`
- Change: Add new Step 5a "Create Tracker Subtasks" after Step 5 (decomposition decision) and before Step 6 (subtask execution)
- Content: guard clause, iteration over subtasks, MCP issue creation per tracker type, tracker_id writeback to state.json and YAML, idempotence, partial failure handling, GitHub/Gitea checklist
- Also: add `Create tracker subtasks` to Configuration section's Decomposition reading
- Estimated lines: ~60-80

**Task 2.2: fix-ticket/SKILL.md**
- File: `skills/fix-ticket/SKILL.md`
- Change: Add new Step 4b-tracker "Create Tracker Subtasks" after Step 4b (decomposition decision, plan approval) and before Step 4c (subtask execution)
- Content: same pattern as Task 2.1, adapted for fix-ticket step numbering
- Also: add `Create tracker subtasks` to Configuration section
- Estimated lines: ~60-80

**Task 2.3: fix-bugs/SKILL.md**
- File: `skills/fix-bugs/SKILL.md`
- Change: Add new Step 3b-tracker "Create Tracker Subtasks" after Step 3b (decomposition decision, plan approval) and before Step 3c (subtask execution)
- Content: same pattern as Task 2.1, adapted for fix-bugs step numbering
- Also: add `Create tracker subtasks` to Configuration section
- Estimated lines: ~60-80

#### Group 3: Documentation (parallelizable — independent doc files)

**Task 3.1: docs/reference/skills.md**
- File: `docs/reference/skills.md`
- Change: Update fix-ticket, fix-bugs, and implement-feature sections to mention the new step
- Estimated lines: ~10-15

**Task 3.2: docs/reference/pipelines.md**
- File: `docs/reference/pipelines.md`
- Change: Update pipeline diagrams (mermaid) and stage tables for all 3 pipelines
- Add "Create Tracker Subtasks" stage to the Feature Pipeline and Bug-Fix Pipeline stage tables
- Estimated lines: ~15-20

**Task 3.3: docs/reference/automation-config.md**
- File: `docs/reference/automation-config.md`
- Change: Update Decomposition section to include `Create tracker subtasks` key
- Add to the quick reference table: Decomposition now used by fix-ticket, fix-bugs, implement-feature, scaffold
- Estimated lines: ~5-10

**Task 3.4: CHANGELOG.md**
- File: `CHANGELOG.md`
- Change: Add v6.4.0 entry (MINOR) with Added section listing all changes
- Estimated lines: ~25-35

**Task 3.5: docs/plans/roadmap.md**
- File: `docs/plans/roadmap.md`
- Change: Move "Decomposition Subtask Tracker Creation" from BACKLOG to DONE section
- Update version header
- Estimated lines: ~5-10

#### Group 4: Version Bump (sequential, after all changes)

**Task 4.1: Version bump**
- Use `/ceos-agents:version-bump` skill
- Bump 6.3.3 -> 6.4.0 (MINOR)
- Updates: `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, roadmap.md header

### Dependency Graph

```
Group 1 (foundation)
  Task 1.1 (state schema) ──┐
  Task 1.2 (config contract) ┤
                              ▼
Group 2 (skills, parallel)
  Task 2.1 (implement-feature) ──┐
  Task 2.2 (fix-ticket) ─────────┤
  Task 2.3 (fix-bugs) ───────────┤
                                  ▼
Group 3 (docs, parallel)
  Task 3.1 (skills.md) ──────┐
  Task 3.2 (pipelines.md) ───┤
  Task 3.3 (auto-config.md) ─┤
  Task 3.4 (CHANGELOG.md) ───┤
  Task 3.5 (roadmap.md) ─────┤
                              ▼
Group 4 (version bump)
  Task 4.1 (version-bump)
```

### Verification Gates

- **After Group 1:** Verify state schema has tracker_id field, CLAUDE.md has updated Decomposition row
- **After Group 2:** Verify all 3 skills have the new step, cross-skill consistency check (grep for key patterns)
- **After Group 3:** Verify all doc files updated, CHANGELOG has v6.4.0 entry
- **After Group 4:** Verify plugin.json version is 6.4.0, run test suite

## Success Criteria
{{SUCCESS_CRITERIA}}:
- [ ] All 6 user items are covered by at least one task
- [ ] Tasks are ordered by dependency (no forward references)
- [ ] Parallelizable groups are identified
- [ ] Each task has file path, specific change description, and estimated lines
- [ ] Verification gates between groups
- [ ] Total estimated change: ~200-350 lines across ~12 files

## Anti-Patterns
{{ANTI_PATTERNS}}:
- Do NOT create tasks for files that do not need changing
- Do NOT split a single file change across multiple tasks (one task per file)
- Do NOT forget any of the 3 skill files
- Do NOT plan agent definition changes (architect output format is unchanged)
- Do NOT plan runtime code changes (pure markdown plugin)
- Do NOT skip the version bump task

## Codebase Context
{{CODEBASE_CONTEXT}}:
- All files are markdown — no compilation, no tests to update (except test suite)
- 3 skill files are long (implement-feature: ~456 lines, fix-ticket: ~451 lines, fix-bugs: ~588 lines)
- Version bump is done via `/ceos-agents:version-bump` skill (updates plugin.json, marketplace.json, tags)
- Test suite: `tests/harness/run-tests.sh` — should pass before and after changes
- CHANGELOG format: Keep a Changelog with MAJOR/MINOR/PATCH classification
