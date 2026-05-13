# Phase 7: Execute -- Sprint Planning for ceos-agents

## Persona

You are a **Senior Developer** implementing the sprint planning feature for the ceos-agents plugin. You write clean, minimal markdown definitions that follow established patterns exactly. You understand that this is a pure markdown plugin -- no runtime code, no build system. Every file you create must match the conventions documented in CLAUDE.md.

## Task Instructions

Execute the implementation plan from Phase 6. For each task, follow the fixer agent's red-green-refactor approach:

1. **RED:** Understand what the test expects (from Phase 5 TDD tests)
2. **GREEN:** Implement the minimum change to satisfy the acceptance criteria
3. **REFACTOR:** Clean up only within the changed scope

### Implementation Priorities

1. **Agent definition first** -- `agents/sprint-planner.md` is the foundation. Follow the exact pattern from `agents/priority-engine.md`:
   - YAML frontmatter: name, description, model, style
   - Sections: Goal, Expertise, Process (numbered steps), Constraints (NEVER rules)
   - The agent consumes priority-engine output and produces a sprint plan
   - Semi-autonomous mode: display plan, prompt for user adjustments
   - Autonomous mode: select issues by priority score, respect capacity limit

2. **Skill definition** -- `skills/sprint-plan/SKILL.md` follows the pattern from `skills/prioritize/SKILL.md`:
   - YAML frontmatter: name, description, allowed-tools, argument-hint
   - Configuration section: reads Sprint Planning config
   - MCP pre-flight check (follow `core/mcp-preflight.md`)
   - Orchestration: fetch backlog -> prioritize -> plan sprint -> create in tracker -> assign issues
   - Per-tracker dispatch table for sprint/milestone/cycle/version creation
   - Rules section

3. **Config extension** -- add `### Sprint Planning` to `core/config-reader.md` optional sections list:
   - Follow the exact `| Key | Value |` pattern
   - All keys must have defaults (optional section)

4. **State schema** -- add sprint planning fields to `state/schema.md`:
   - New `sprint_planning` object in state.json
   - Follow existing field definition pattern

5. **Integration updates** -- update existing files:
   - `skills/workflow-router/SKILL.md`: add sprint planning intent rows
   - `CLAUDE.md`: update counts, lists, tables

### Per-Tracker Sprint Operations

Follow the dispatch pattern from `skills/implement-feature/SKILL.md` Step 5a:

| Tracker | Sprint Concept | Create Operation | Assign Operation |
|---------|---------------|-----------------|-----------------|
| YouTrack | Agile board sprint | Create sprint on board | Move issue to sprint |
| Jira | Scrum board sprint | Create sprint | Move issue to sprint |
| Linear | Cycle | Create cycle | Assign issue to cycle |
| GitHub | Milestone | Create milestone | Set milestone on issue |
| Gitea | Milestone | Create milestone | Set milestone on issue |
| Redmine | Version | Create version | Set target version on issue |

For trackers where MCP does not support sprint operations, use comment-based tracking as fallback:
```
[ceos-agents] Sprint: {sprint-name} ({start} - {end})
Issues: {issue-list}
```

### Key Implementation Constraints

- Each file change must be <= 100 lines diff
- New files can be larger (they are entirely new, not diffs)
- Follow existing code conventions EXACTLY (no creative formatting)
- No emoji in file content (existing convention)
- English only in all generated content
- Block Comment Template format for all error handling

## Success Criteria

- `agents/sprint-planner.md` exists with valid YAML frontmatter and all required sections
- `skills/sprint-plan/SKILL.md` exists with full orchestration including all 6 tracker types
- `core/config-reader.md` includes Sprint Planning as an optional section with all keys and defaults
- `state/schema.md` includes sprint_planning object definition
- `skills/workflow-router/SKILL.md` has sprint planning intent rows
- `CLAUDE.md` counts and lists are updated (20 agents, 27 skills)
- All TDD tests from Phase 5 pass
- No existing tests break (run full test suite)

## Anti-Patterns

1. **Inventing new patterns** -- do NOT create new file formats, new config patterns, or new state management approaches. Use what exists.
2. **Incomplete tracker coverage** -- every dispatch table must cover all 6 tracker types. Do not skip Redmine or Linear because they are less common.
3. **Breaking existing tests** -- run `tests/harness/run-tests.sh` after each major change. If an existing test breaks, fix the implementation, not the test.
4. **Over-engineering the agent** -- the sprint-planner agent should be comparable in complexity to priority-engine (78 lines). Not a 500-line behemoth.
5. **Forgetting the semi-autonomous UX** -- the skill must include exact prompt text for user interactions in semi-autonomous mode.
6. **Ignoring graceful degradation** -- if a tracker's MCP server doesn't support sprint operations, the skill must degrade gracefully (comment-based fallback or skip with warning).
7. **Modifying existing agent behavior** -- sprint planning adds new components. It does NOT modify how existing agents (priority-engine, fixer, etc.) work.

## Codebase Context

- **Agent pattern exemplar:** `agents/priority-engine.md` (78 lines, opus, read-only analysis)
- **Skill pattern exemplar:** `skills/prioritize/SKILL.md` (52 lines, MCP-based, read-only)
- **Tracker dispatch exemplar:** `skills/implement-feature/SKILL.md` Step 5a (lines 246-398)
- **Config reader:** `core/config-reader.md` (lines 33-37 for optional sections list)
- **State schema:** `state/schema.md` (full JSON schema example at lines 30-133)
- **Workflow router:** `skills/workflow-router/SKILL.md` (intent table at lines 10-42)
- **CLAUDE.md sections to update:** Architecture (agent/skill counts), Model Selection table, Config Contract table, skills list
- **Test harness:** `tests/harness/run-tests.sh` -- run after implementation
- **Plugin version:** v6.4.6 (do NOT change -- version bump is separate)
