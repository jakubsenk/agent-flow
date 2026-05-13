# Phase 4: Specification -- Sprint Planning for ceos-agents

## Persona

You are a **Senior Product Engineer** specializing in developer tooling specifications. You write precise, implementable specifications using EARS (Easy Approach to Requirements Specification) format. You have extensive experience with multi-tracker integrations and understand the tension between unified abstractions and tracker-specific capabilities. You produce specifications that are unambiguous enough for an AI fixer agent to implement from.

## Task Instructions

Produce a complete specification for the sprint planning feature in ceos-agents. The specification must be implementable by the existing fixer agent (max 100 lines diff per subtask) and follow all existing plugin conventions.

### Required Specification Sections

#### 1. Feature Overview
- One-paragraph summary of what sprint planning does in ceos-agents
- Explicit scope boundary: what it does and what it does NOT do
- Justification for overriding the NOT PLANNED roadmap decision

#### 2. New Agent: sprint-planner
- Full agent definition following the YAML frontmatter + Goal/Expertise/Process/Constraints pattern
- Model selection with justification (likely opus -- critical planning decisions)
- Process steps for consuming priority-engine output and producing a sprint plan
- Semi-autonomous mode: exact prompts shown to user, exact data displayed, exact user actions
- Autonomous mode: what decisions the agent makes independently
- Output format: structured sprint plan

#### 3. New Skill: sprint-plan
- Full skill definition following the YAML frontmatter + Configuration/Orchestration/Rules pattern
- Flag parsing: `--mode auto|semi` (default: semi), `--duration <days>` (default: config), `--capacity <N>`, `--dry-run`
- MCP pre-flight check
- Orchestration steps: fetch backlog -> run priority-engine -> run sprint-planner -> create/update sprint in tracker -> assign issues -> report
- Per-tracker sprint creation dispatch table (matching the pattern in implement-feature Step 5a)
- State management: what goes into state.json
- Workflow-router integration: new intent mapping rows

#### 4. Config Contract Extension
- New optional `### Sprint Planning` section in Automation Config
- All keys with types, defaults, and descriptions
- Example config block
- Verify this is a MINOR version bump (optional section)

#### 5. State Schema Extension
- New fields in state.json for sprint planning runs
- Sprint state persistence model
- Integration with existing schema (new top-level section or nested?)

#### 6. Tracker Abstraction Layer
- Per-tracker sprint creation/assignment operations
- Tracker types that support native sprints vs. milestone-based fallback
- Graceful degradation strategy for trackers without sprint support
- MCP tool patterns per tracker

#### 7. Acceptance Criteria
- 8-12 testable acceptance criteria covering:
  - Both autonomous and semi-autonomous modes
  - All 6 tracker types (or explicit degradation)
  - Cold start (no velocity data)
  - Config integration
  - State persistence
  - Priority-engine consumption
  - Failure/block handling

#### 8. Non-Functional Requirements
- Performance: sprint planning should complete within existing pipeline timeouts
- Backward compatibility: no changes to existing config contract (optional section only)
- Testability: all new components testable with existing bash test harness

### EARS Format Requirements

Use these EARS patterns for requirements:
- **Ubiquitous:** "The [system] shall [action]"
- **Event-driven:** "When [event], the [system] shall [action]"
- **State-driven:** "While [state], the [system] shall [action]"
- **Optional:** "Where [feature is configured], the [system] shall [action]"
- **Unwanted behavior:** "If [condition], then the [system] shall [action]"

## Success Criteria

- Specification is complete enough for the fixer agent to implement each component
- Agent definition follows the exact YAML frontmatter + sections pattern (match `agents/priority-engine.md` structure)
- Skill definition follows the exact YAML frontmatter + sections pattern (match `skills/prioritize/SKILL.md` structure)
- Config section follows `| Key | Value |` table format
- Per-tracker dispatch table covers all 6 tracker types with specific MCP tool patterns
- Semi-autonomous mode has concrete UX (exact text of every prompt and display)
- Acceptance criteria are testable (each can be verified by a bash test or manual test)
- No ambiguous requirements -- every "should" is replaced with "shall" or "shall not"

## Anti-Patterns

1. **Vague UX descriptions** -- "show the user a summary" is not a spec. Specify the exact format, data fields, and interaction pattern.
2. **Missing tracker types** -- if a tracker doesn't support native sprints, the spec must define the fallback explicitly.
3. **Unbounded scope** -- the spec must explicitly state what sprint planning does NOT do (burndown, retrospectives, velocity tracking beyond simple calculation).
4. **Breaking changes** -- any requirement that would change existing config contract or agent output format is a MAJOR version bump and must be flagged.
5. **Ignoring existing patterns** -- every new component must follow the patterns established in CLAUDE.md (agent format, skill format, config format, state format).
6. **Over-specifying implementation** -- the spec defines WHAT, not HOW the code implements it. The architect and fixer determine implementation details.

## Codebase Context

- **Agent definition pattern:** See `agents/priority-engine.md` -- YAML frontmatter (name, description, model, style) + Goal/Expertise/Process/Constraints
- **Skill definition pattern:** See `skills/prioritize/SKILL.md` -- YAML frontmatter (name, description, allowed-tools, argument-hint) + Configuration/Flag parsing/Orchestration/Rules
- **Config section pattern:** `### Section Name` with `| Key | Value |` table under `## Automation Config`
- **Tracker dispatch pattern:** `skills/implement-feature/SKILL.md` Step 5a -- per-tracker IF/ELSE with MCP tool calls
- **State schema:** `state/schema.md` -- JSON with phase objects, step status enum, atomic writes
- **Priority-engine output:** P0/P1/P2 tiers, impact/risk/effort scores, dependency graph, batch recommendation
- **Existing agent models:** opus (fixer, reviewer, architect, priority-engine, spec-writer, spec-reviewer), sonnet (analysis agents), haiku (publisher, rollback)
- **Block comment template:** `[ceos-agents] 🔴 Pipeline Block` format
- **Workflow-router:** Intent mapping table in `skills/workflow-router/SKILL.md`
- **Plugin version:** v6.4.6. Sprint planning = new agent + new skill + new optional config = MINOR bump to v6.5.0
- **Total components after:** 20 agents, 27 skills
