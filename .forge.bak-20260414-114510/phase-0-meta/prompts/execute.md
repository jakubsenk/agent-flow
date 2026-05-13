# Phase 7: Execute -- Sprint Planning & Backlog Management for ceos-agents

## Persona

You are a **Senior Developer** implementing the sprint planning & backlog management feature for the ceos-agents plugin. You write clean, minimal markdown definitions that follow established patterns exactly. You understand that this is a pure markdown plugin -- no runtime code, no build system. Every file you create must match the conventions documented in CLAUDE.md.

## Task Instructions

Execute the implementation plan from Phase 6. For each task, follow the approach:

1. **Understand** what the test expects (from Phase 5 TDD tests)
2. **Implement** the minimum change to satisfy the acceptance criteria
3. **Verify** consistency with existing patterns

### Implementation Priorities

1. **Agent definitions first** -- `agents/backlog-creator.md` and `agents/sprint-planner.md` are the foundation.

   **backlog-creator.md** -- follow agents/spec-analyst.md pattern:
   - YAML frontmatter: name: backlog-creator, description (concise), model: sonnet, style (e.g., "Specification-focused, structured, detail-oriented")
   - Goal: Extract epics from specification files and produce structured backlog items
   - Expertise: Spec parsing, feature extraction, acceptance criteria derivation, epic sizing
   - Process: numbered steps for reading spec, extracting features, producing epic cards in the template format (spec section 4)
   - Constraints: NEVER modify code/files, NEVER create tracker issues, max epic count, Block Comment Template

   **sprint-planner.md** -- follow agents/priority-engine.md pattern:
   - YAML frontmatter: name: sprint-planner, description (concise), model: sonnet, style (e.g., "Capacity-focused, data-driven, constraint-aware")
   - Goal: Produce capacity-constrained sprint plans from prioritized issue lists
   - Expertise: Capacity planning, sprint selection, dependency awareness, effort estimation
   - Process: receive priority-engine output, resolve effort sizes, walk ranked list top-to-bottom, fit to capacity, flag decompose_recommended, produce sprint plan table
   - Constraints: NEVER re-rank (priority-engine ranking is authoritative), NEVER modify code/issues, NEVER persist state, Block Comment Template
   - Output format: structured sprint plan with issue table + overflow section

2. **Skill definitions** -- `skills/create-backlog/SKILL.md` and `skills/sprint-plan/SKILL.md`.

   **create-backlog/SKILL.md** -- follow skills/implement-feature/SKILL.md pattern for tracker dispatch:
   - YAML frontmatter: name, description, allowed-tools, argument-hint, disable-model-invocation: true
   - Flag parsing: spec path, --decompose, --update
   - Configuration: reads Issue Tracker, Sprint Planning (optional), Agent Overrides
   - MCP pre-flight check (core/mcp-preflight.md)
   - Orchestration:
     - Step 0: MCP pre-flight
     - Step 1: Read spec files (folder or single file)
     - Step 2: Dispatch backlog-creator agent (Task tool, sonnet)
     - Step 3: Display epic preview table (name, AC count, size, dependencies)
     - Step 4: Human confirmation gate (Y/n)
     - Step 5: Create tracker issues per epic (per-tracker dispatch, reuse implement-feature Step 5a pattern)
     - Step 6 (optional --decompose): dispatch architect per epic, create sub-issues
     - Step 7 (optional --update): match existing issues by title, update instead of create
   - State: .ceos-agents/backlog-{timestamp}/state.json
   - Per-tracker issue creation: same dispatch table as implement-feature Step 5a
   - Epic card template: spec section 4 format

   **sprint-plan/SKILL.md** -- follow skills/prioritize/SKILL.md for priority-engine dispatch, then extend:
   - YAML frontmatter: name, description, allowed-tools, argument-hint, disable-model-invocation: true
   - Flag parsing: --all, --apply, --dry-run, --yolo
   - Configuration: reads Issue Tracker, Sprint Planning section, Retry Limits, Agent Overrides
   - MCP pre-flight check
   - Orchestration:
     - Step 0: MCP pre-flight + config validation (Sprint Planning section required)
     - Step 1: Fetch open issues from tracker (Bug query + Feature query, limit = Max issues)
     - Step 2: Dispatch priority-engine (Task tool, opus) -- reuse exact pattern from skills/prioritize/SKILL.md
     - Step 3: Dispatch sprint-planner (Task tool, sonnet) with priority-engine output + Sprint Planning config
     - Step 4: Gate 1 -- capacity confirmation (display sprint plan, Y/n, --yolo auto-approves)
     - Step 5: Gate 2 -- unmapped AC warning (if epic has no AC, BLOCK even in --yolo)
     - Step 6: Gate 3 -- final "Start sprint?" (Y/n, --yolo auto-approves)
     - Step 7: Sprint assignment per tracker (3-tier fallback from spec section 6)
     - Step 8 (optional --apply): dispatch implement-feature per selected issue
     - --dry-run: execute steps 0-6, display plan, exit (no tracker writes)
     - --all: sprint-planner produces multi-sprint plan, steps 4-7 repeat per sprint
   - Sprint assignment dispatch table: 6 trackers x 3 tiers (spec section 6)
   - State: .ceos-agents/sprint-{timestamp}/state.json

3. **Existing skill modification** -- add --decompose-only to implement-feature:
   - Add to argument-hint in YAML frontmatter
   - Add to flag parsing section
   - Add early exit after Step 5a: if --decompose-only, display decomposition result and STOP

4. **Config extension** -- add Sprint Planning to core/config-reader.md:
   - Add to the optional sections list following the exact pattern of existing entries
   - Sprint Planning -> sprint_planning.sprint_duration (default: 2 weeks), sprint_planning.capacity_unit (default: story-points), sprint_planning.team_capacity (default: none), sprint_planning.velocity_target (default: none), sprint_planning.sprint_field (default: tracker-dependent), sprint_planning.mode (default: suggest), sprint_planning.max_issues (default: 20)
   - Also add Epic template key

5. **State schema** -- add to state/schema.md:
   - New RUN-ID formats: backlog-{timestamp}, sprint-{timestamp}
   - Sprint state object (from brainstorm simplified schema)
   - Backlog state object

6. **Integration updates**:
   - workflow-router: add rows for create-backlog and sprint-plan intents
   - CLAUDE.md: update ALL relevant sections:
     - Repository Structure: "21 agent definitions", "28 skills"
     - Architecture 2-Layer System: add /create-backlog and /sprint-plan to Skills list, add backlog-creator and sprint-planner to Agents list
     - Model Selection table: add backlog-creator and sprint-planner under sonnet
     - Config Contract optional sections table: add Sprint Planning row
     - "Key Conventions Across All Agents" read-only agents list: add backlog-creator and sprint-planner
   - docs/reference/skills.md: add entries
   - docs/plans/roadmap.md: remove from NOT PLANNED, add to implemented

### Per-Tracker Sprint Assignment Operations

Follow the dispatch pattern from implement-feature Step 5a:

| Tracker | Sprint Concept | MCP (Tier 1) | Bash+REST (Tier 2) | Skip (Tier 3) |
|---------|---------------|-------------|-------------------|---------------|
| YouTrack | Sprint | update_issue(Sprint: name) | curl REST | skip+warn |
| Jira | Sprint (Scrum only) | add_issues_to_sprint(sprintId, issues) | curl REST | skip+warn |
| Linear | Cycle | update_issue(cycleId: uuid) | GraphQL mutation | skip+warn |
| GitHub | Milestone | update_issue(milestone: number) | curl REST | skip+warn |
| Gitea | Milestone | unverified -> Tier 2 | curl REST | skip+warn |
| Redmine | Version | update_issue(fixed_version_id: id) | curl REST | skip+warn |

### Key Implementation Constraints

- Each file modification must be <= 100 lines diff
- New files can be larger (entirely new, not diffs)
- Follow existing code conventions EXACTLY (no creative formatting)
- English only in all generated content
- Block Comment Template format for all error handling
- Both new agents MUST be read-only (no Write/Edit tool references in Process)
- sprint-planner MUST NOT re-rank (Constraint section must say NEVER)
- --yolo does NOT imply --apply (spec section 5)
- Sprint assignment is ALWAYS NON-BLOCKING (spec section 6)

## Success Criteria

- agents/backlog-creator.md exists with valid YAML frontmatter and all required sections
- agents/sprint-planner.md exists with valid YAML frontmatter and all required sections
- skills/create-backlog/SKILL.md exists with full orchestration including tracker dispatch
- skills/sprint-plan/SKILL.md exists with full orchestration including all 6 tracker types, 3 gates, and sprint_assign
- skills/implement-feature/SKILL.md has --decompose-only in flag parsing and argument-hint
- core/config-reader.md includes Sprint Planning as an optional section with all 7 keys and defaults
- state/schema.md includes sprint and backlog state objects with RUN-ID formats
- skills/workflow-router/SKILL.md has create-backlog and sprint-plan intent rows
- CLAUDE.md counts and lists are updated (21 agents, 28 skills)
- All TDD tests from Phase 5 pass
- No existing tests break (run full test suite: tests/harness/run-tests.sh)

## Anti-Patterns

1. **Inventing new patterns** -- do NOT create new file formats, config patterns, or state approaches. Use existing ones.
2. **Incomplete tracker coverage** -- every dispatch table must cover all 6 tracker types.
3. **Breaking existing tests** -- run tests/harness/run-tests.sh after each major change.
4. **Over-engineering agents** -- backlog-creator and sprint-planner should be comparable to spec-analyst and priority-engine in length (80-100 lines each).
5. **Forgetting gates UX** -- sprint-plan skill must include exact prompt text for all 3 gates.
6. **Ignoring graceful degradation** -- sprint assignment failures are NON-BLOCKING always.
7. **Modifying priority-engine** -- sprint planning adds new components. Priority-engine is NOT modified.
8. **Forgetting --update matching** -- create-backlog --update must define how existing epics are matched (title prefix).
9. **Missing the --decompose-only early exit** -- implement-feature must cleanly exit after Step 5a with a summary display.

## Codebase Context

- **Agent pattern exemplar:** agents/priority-engine.md (78 lines, opus, read-only analysis with P0/P1/P2 output)
- **Agent pattern exemplar:** agents/spec-analyst.md (97 lines, sonnet, read-only with AC extraction)
- **Skill pattern exemplar:** skills/prioritize/SKILL.md (52 lines, MCP-based, priority-engine dispatch)
- **Skill pattern exemplar:** skills/implement-feature/SKILL.md (647 lines, full pipeline with tracker dispatch tables)
- **Tracker dispatch exemplar:** skills/implement-feature/SKILL.md Step 5a (lines 246-398, all 6 tracker types)
- **Config reader:** core/config-reader.md (lines 24-37 for optional sections list)
- **State schema:** state/schema.md (full JSON schema, RUN-ID table)
- **Workflow router:** skills/workflow-router/SKILL.md (intent table lines 10-42)
- **CLAUDE.md sections to update:** Repository Structure, Architecture 2-Layer System (both lists), Model Selection table, Key Conventions, Config Contract tables
- **Test harness:** tests/harness/run-tests.sh -- run after implementation
- **Plugin version:** v6.4.6 (do NOT change -- version bump is separate post-implementation step)
- **Prior research:** .forge.bak-20260414-090537/phase-1-research-questions/final.md (tracker API details)
- **Brainstorm output:** .forge.bak-20260414-090537/phase-3-brainstorm/final.md (Conservative Pragmatist design)
