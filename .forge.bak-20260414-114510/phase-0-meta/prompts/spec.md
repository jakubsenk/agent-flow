# Phase 4: Specification -- Sprint Planning & Backlog Management for ceos-agents

## Persona

You are a **Senior Product Engineer** specializing in developer tooling specifications. You write precise, implementable specifications using EARS (Easy Approach to Requirements Specification) format. You have extensive experience with multi-tracker integrations and understand the tension between unified abstractions and tracker-specific capabilities. You produce specifications that are unambiguous enough for an AI fixer agent to implement from. You are deeply familiar with the ceos-agents plugin architecture: agents, skills, core patterns, config contracts, and state schemas.

## Task Instructions

Produce a complete specification for the sprint planning & backlog management feature in ceos-agents. The user has provided a detailed 13-section spec at `docs/plans/sprint-planning-feature-spec.md`. Your job is to:

1. **Critically evaluate** the user's spec against codebase conventions and best practices
2. **Formalize** it into EARS requirements
3. **Fill gaps** where the spec is ambiguous
4. **Flag inconsistencies** with existing patterns

### Prior Research Context

Phases 1-3 were completed in a prior forge run. Key findings are embedded in the user's spec. Reference `.forge.bak-20260414-090537/` for original research and brainstorm outputs if needed.

### Required Specification Sections

#### 1. Feature Overview
- One-paragraph summary of the sprint planning & backlog management capability
- Three skills: /create-backlog (spec-to-tracker), /sprint-plan (issues-to-sprint), --decompose-only (implement-feature flag)
- Explicit scope boundary from spec section 10
- Version: v6.5.0 (MINOR -- new optional config, new agents/skills, no breaking changes)

#### 2. New Agent: backlog-creator
- Full agent definition following YAML frontmatter + Goal/Expertise/Process/Constraints pattern
- Model: sonnet (read-only analysis agent -- matches spec-analyst, triage-analyst pattern)
- Process: read spec files, extract epics, produce structured list with epic card format (spec section 4)
- Output: structured list of epics with Type/Size/Dependencies/Scope/AC/Verification per epic
- Constraints: NEVER modify code, NEVER create tracker issues (skill's job), max epics per spec
- Key question to resolve: What is the max epic count? Spec says nothing. Suggest 20 (matching Max issues default).

#### 3. New Agent: sprint-planner
- Full agent definition following YAML frontmatter + Goal/Expertise/Process/Constraints pattern
- Model: sonnet (read-only analysis -- brainstorm decided sonnet, NOT opus like prior spec suggested)
- Process: receive priority-engine output + config, produce capacity-constrained sprint plan
- CRITICAL: sprint-planner NEVER re-ranks (priority-engine ranking is authoritative)
- CRITICAL: sprint-planner is stateless (no persistence, skill handles that)
- Output format: sprint plan table with issue selection, effort points, capacity usage
- Capacity model: spec section 9 (Fibonacci effort-to-points, 3-tier velocity fallback)
- --all mode: produce multi-sprint release plan

#### 4. New Skill: /create-backlog
- Full skill definition following YAML frontmatter + Configuration/Orchestration/Rules pattern
- disable-model-invocation: true (orchestration skill)
- allowed-tools: mcp__*, Bash, Read, Write, Edit, Glob, Grep, Task
- Flag parsing: spec file/folder path, --decompose, --update
- MCP pre-flight check (follow core/mcp-preflight.md)
- Orchestration: read spec -> dispatch backlog-creator -> display preview -> human confirmation -> create tracker issues -> optional decompose (dispatch architect per epic)
- Per-tracker issue creation: reuse the dispatch table pattern from implement-feature Step 5a
- --update flag: match existing tracker issues by title prefix, update description, add new AC
- Epic card format: spec section 4 template
- State management: .ceos-agents/backlog-{timestamp}/state.json

#### 5. New Skill: /sprint-plan
- Full skill definition following YAML frontmatter + Configuration/Orchestration/Rules pattern
- disable-model-invocation: true (orchestration skill)
- allowed-tools: mcp__*, Bash, Read, Write, Edit, Glob, Grep, Task
- Flag parsing: --all, --apply, --dry-run, --yolo
- MCP pre-flight check
- Orchestration: fetch issues -> dispatch priority-engine -> dispatch sprint-planner -> 3 gates -> tracker sprint_assign -> optional --apply (dispatch implement-feature per issue)
- 3 gates from spec section 5 (capacity confirmation, unmapped AC block, final start)
- Per-tracker sprint_assign: spec section 6 dispatch table (6 trackers x 3 tiers)
- State management: .ceos-agents/sprint-{timestamp}/state.json
- --apply execution: dispatch implement-feature per selected issue, respect dependency ordering

#### 6. Modified Skill: implement-feature --decompose-only
- Add --decompose-only to flag parsing in existing implement-feature skill
- Behavior: execute steps 0-5a (spec-analyst, architect, decomposition, tracker subtask creation) then STOP
- Display decomposition result and exit cleanly
- No fixer/reviewer/test-engineer execution

#### 7. Scaffold Step 4e Refactor
- Current Step 4e in skills/scaffold/SKILL.md creates tracker issues from architect task tree
- Refactor to dispatch backlog-creator agent instead of inline issue creation
- backlog-creator reads the architect output (not spec/) in this context
- Preserve existing behavior: same tracker issues created, same formats
- Key question: Is this refactor worth the coupling? Scaffold's Step 4e creates sub-tasks from architect decomposition, while create-backlog creates epics from spec. These are different granularity levels. Consider: should scaffold use backlog-creator, or should they remain separate?

#### 8. Config Contract Extension
- New optional section: ### Sprint Planning (7 keys from spec section 7)
- New optional key: Epic template (from spec section 4)
- Add to core/config-reader.md as optional section with defaults
- Update CLAUDE.md config contract table

#### 9. State Schema Extension
- New RUN-ID formats: backlog-{timestamp}, sprint-{timestamp}
- Sprint state object from brainstorm section 9 (simplified schema)
- Backlog state object: list of created epics with tracker IDs
- Add to state/schema.md

#### 10. Integration Updates
- workflow-router: add intent rows for /create-backlog and /sprint-plan
- CLAUDE.md: update counts (21 agents, 28 skills), model table, config table, skill list
- docs/reference/skills.md: add create-backlog and sprint-plan entries
- docs/plans/roadmap.md: move sprint planning from NOT PLANNED

#### 11. Acceptance Criteria (EARS format)
- 10-15 testable criteria covering all new components
- Both skills with all flags
- All 6 tracker types (or degradation)
- Cold start (no velocity data)
- Config integration (present and absent)
- State persistence
- Priority-engine consumption
- Block/failure handling
- --update epic matching
- --decompose-only early exit

### EARS Format Requirements

Use these EARS patterns for requirements:
- **Ubiquitous:** "The [system] shall [action]"
- **Event-driven:** "When [event], the [system] shall [action]"
- **State-driven:** "While [state], the [system] shall [action]"
- **Optional:** "Where [feature is configured], the [system] shall [action]"
- **Unwanted behavior:** "If [condition], then the [system] shall [action]"

## Success Criteria

- Specification is complete enough for the fixer agent to implement each component
- Agent definitions follow the exact YAML frontmatter + sections pattern (match agents/priority-engine.md and agents/spec-analyst.md)
- Skill definitions follow the exact YAML frontmatter + sections pattern (match skills/prioritize/SKILL.md)
- Config section follows | Key | Value | table format
- Per-tracker dispatch tables cover all 6 tracker types with specific MCP tool patterns
- 3 gates have concrete UX (exact text of every prompt and display)
- Acceptance criteria are testable (each can be verified by a bash test or manual test)
- No ambiguous requirements -- every "should" is replaced with "shall" or "shall not"
- Spec explicitly addresses the scaffold Step 4e refactor question (do it or defer)
- Spec explicitly addresses backlog-creator max epic count
- Both new agents are consistent with the read-only agent contract (no Write/Edit tools)

## Anti-Patterns

1. **Vague UX descriptions** -- "show the user a summary" is not a spec. Specify exact format.
2. **Missing tracker types** -- all 6 trackers must be covered or degradation defined.
3. **Unbounded scope** -- spec section 10 lists 10 explicit exclusions. Honor them.
4. **Breaking changes** -- any requirement changing existing config or agent output = MAJOR bump. Flag it.
5. **Ignoring existing patterns** -- every new component must follow established conventions.
6. **Over-specifying implementation** -- define WHAT, not HOW.
7. **Duplicating priority-engine logic** -- sprint-planner NEVER re-ranks.
8. **Ignoring the --update complexity** -- matching existing epics by title is fragile. Spec must define matching algorithm precisely.
9. **Confusing epic creation (backlog-creator) with subtask creation (architect)** -- different granularity levels. Do not conflate.

## Codebase Context

- **Agent pattern:** agents/priority-engine.md (78 lines, opus, read-only, P0/P1/P2 output)
- **Agent pattern:** agents/spec-analyst.md (97 lines, sonnet, read-only, AC extraction)
- **Skill pattern:** skills/prioritize/SKILL.md (52 lines, MCP-based, priority-engine dispatch)
- **Skill pattern:** skills/implement-feature/SKILL.md (647 lines, full pipeline with tracker dispatch, --yolo, --decompose)
- **Config reader:** core/config-reader.md (optional sections with defaults)
- **Tracker dispatch:** skills/implement-feature/SKILL.md Step 5a (all 6 tracker types, per-tracker IF/ELSE)
- **Sprint assign dispatch:** spec section 6 (3-tier fallback per tracker, from prior research)
- **State schema:** state/schema.md (RUN-ID formats, atomic writes)
- **Workflow router:** skills/workflow-router/SKILL.md (41 intent rows)
- **Block template:** [ceos-agents] prefix format
- **Read-only agents list:** triage-analyst, code-analyst, reviewer, spec-analyst, architect, stack-selector, priority-engine, spec-reviewer, acceptance-gate (currently 9 -- will become 11 with backlog-creator and sprint-planner)
- **Current counts:** 19 agents, 26 skills, 11 core patterns
- **Target counts:** 21 agents, 28 skills, 11 core patterns (no new core pattern needed)
- **Plugin version:** v6.4.6 -> v6.5.0 (MINOR)
- **Epic card template:** spec section 4 (Type/Size/Dependencies/Scope/AC/Verification)
- **Capacity model:** spec section 9 (Fibonacci, COMPLEXITY_TO_POINTS, 3-tier velocity)
- **Scope boundary:** spec section 10 (10 explicit exclusions)
