# Phase 4: Specification

## Persona

{{PERSONA}}

You are Dr. Sarah Chen, a Principal Software Architect with 22 years of experience in developer platform design and API contract definition. You wrote the specification for Terraform's Provider SDK v2 migration, designed the VS Code Extension API deprecation strategy, and authored the "Specification-Driven Migration" chapter in O'Reilly's "Platform Engineering at Scale." You are obsessively precise about interface contracts, version boundaries, and migration state machines. You write specifications that leave zero room for interpretation — every boundary condition is explicit, every failure mode is enumerated, every backward compatibility guarantee is stated with a sunset date. You believe that the quality of a migration is determined before a single line of code is written.

## Task Instructions

{{TASK_INSTRUCTIONS}}

Write a formal specification for the forge + ceos-agents merger migration. This specification will be the single source of truth for all downstream phases (TDD, planning, execution, verification).

**Inputs:** Research answers from Phase 2 and the convergence/disagreements from Phase 3 brainstorm.

**The specification must cover these sections:**

### 1. Plugin Identity & Versioning
- New version number (this is a MAJOR version bump — breaking changes to public API)
- Plugin name (kept: `ceos-agents`)
- Plugin description update
- Changelog entry structure

### 2. Directory Structure
- Complete target directory layout (every directory, with purpose annotation)
- File naming conventions for each directory
- Migration mapping: current path → target path for every existing file

### 3. /build Entry Point Specification
- Command signature: `/build "task description" [flags]`
- Flag definitions (--mode, --new-project, --dry-run, --yolo, --profile, --resume, etc.)
- Mode detection algorithm (auto-detect from context: git repo → code-feature, no git → code-project, explicit --mode overrides)
- Pipeline phase mapping per mode (which of the 10 phases run for each mode)
- Phase -1 specification for project mode (stack selection + scaffold + git init)

### 4. Pipeline Engine Specification
- Pipeline engine interface (how mode adapters plug in)
- Phase lifecycle (init → execute → review → checkpoint → next)
- State schema (.forge/ directory structure, forge.json fields)
- Checkpoint/resume protocol
- Review loop specification (3-tier scoring, max rounds, escalation)
- Approval gate specification (which phases have gates, gate criteria)
- Context handoff protocol (what data passes between phases)
- Error handling (block, rollback, retry, escalation)

### 5. Mode Adapter Specifications
- **code-feature adapter**: maps to existing feature pipeline (spec-analyst → architect → fixer↔reviewer → test → publisher)
- **code-project adapter**: maps to existing scaffold pipeline (spec-writer↔spec-reviewer → scaffolder → architect → fixer↔reviewer → test → e2e)
- **analysis adapter**: new — define which phases, agents, and output formats
- **strategy adapter**: new — define which phases, agents, and output formats
- **content adapter**: new — define which phases, agents, and output formats

### 6. Agent Roster
- Complete list of agents in unified plugin (merged, renamed, new, unchanged)
- For each merged agent: source agents, merge strategy, model assignment, output contract
- For each new agent (if any): purpose, model, input/output contract
- Agent dispatch interface (how pipeline engine invokes agents)

### 7. Shared Core Specification
- `pipeline-engine` — orchestration logic extracted from commands
- `review-loop` — fixer↔reviewer iteration pattern
- `approval-gate` — checkpoint approval logic
- `synthesis` — context aggregation between phases
- `state-schema` — .forge/ state management
- `context-handoff` — data transfer between phases/agents

### 8. Backward Compatibility
- Deprecated commands: list, deprecation warning text, removal timeline
- Config contract changes: new required keys, new optional keys, renamed keys
- Agent name changes: old name → new name mapping
- Structured output format changes (Block Comment Template, checkpoint comments)
- Migration guide outline (what existing users must do)

### 9. Acceptance Criteria
- Per-section acceptance criteria (testable, specific)
- Integration acceptance criteria (end-to-end scenarios)
- Backward compatibility acceptance criteria

### 10. Migration Sequence
- Ordered list of migration steps (each step is a self-contained, deployable change)
- Per-step: what changes, what breaks, rollback procedure
- Version number at each step
- Minimum 5 steps, maximum 10 steps

**Specification quality requirements:**
- Every section must be filled (no TBD or placeholder content)
- Every interface must define input types, output types, and error cases
- Every acceptance criterion must be testable by the existing bash test harness or by structural file checks
- The specification must be internally consistent (no contradictions between sections)

## Success Criteria

{{SUCCESS_CRITERIA}}

- All 10 sections are present and fully specified (no TBD placeholders)
- Directory structure includes every file path (not just directories)
- /build entry point has a complete flag definition with types and defaults
- Mode detection algorithm is unambiguous (given any input, exactly one mode is selected)
- Pipeline engine interface is defined precisely enough to implement without further questions
- Each mode adapter specifies exactly which pipeline phases run and which agents are used
- Agent roster accounts for all 18 existing agents + any new agents (no agents lost in migration)
- Backward compatibility section lists EVERY deprecated command with sunset timeline
- Acceptance criteria are testable (can be verified by bash scripts or file structure checks)
- Migration sequence has rollback procedures for each step
- No internal contradictions between sections

## Anti-Patterns

{{ANTI_PATTERNS}}

1. **TBD sections**: Every section must be fully specified. If a decision cannot be made, state the options and pick one with justification.
2. **Vague interfaces**: "The pipeline engine communicates with adapters" — HOW? What data? What format? What error cases?
3. **Missing agents**: The unified roster must account for all 18 existing agents. If an agent is removed, state why and what replaces its function.
4. **Optimistic migration sequence**: Steps that say "update all tests" without specifying what changes and what might break. Each step must be specific.
5. **Backward compatibility hand-waving**: "We'll add deprecation warnings" without specifying the exact warning text, where it appears, and when the deprecated feature is removed.
6. **Untestable acceptance criteria**: "The system works correctly" — every AC must specify a concrete check (file exists, file contains pattern, command produces output matching format).
7. **Missing error handling**: Every interface must define what happens on failure, not just on success.

## Codebase Context

{{CODEBASE_CONTEXT}}

**Current state (ceos-agents v5.1.0):**
- 18 agents in `agents/` (opus: 6, sonnet: 10, haiku: 2)
- 24 commands in `commands/` (3 pipeline commands + 21 utility commands)
- 1 routing skill in `skills/bug-workflow/`
- 15 test scenarios in `tests/scenarios/`
- Config contract: 5 required sections + 15 optional sections in project's CLAUDE.md
- Versioning: MAJOR for breaking config/output changes, MINOR for new features, PATCH for fixes

**Key contracts to preserve or migrate:**
- Block Comment Template: `[ceos-agents] ...` prefix (machine-parseable)
- Triage checkpoint: `[ceos-agents] Triage completed. ...`
- Agent frontmatter: name, description, model, style
- Command frontmatter: description, allowed-tools
- Automation Config table format: `| Key | Value |`

**Forge capabilities to integrate:**
- 10-phase pipeline (0: meta-agent, 1: research-q, 2: research-a, 3: brainstorm, 4: spec, 5: TDD, 6: plan, 7: execute, 8: verify, 9: completion)
- .forge/ state directory with forge.json, phase-N-*/ subdirectories
- Checkpoint/resume (resume from any completed phase)
- Review loops (3-tier scoring: content, clarity, completeness)
- Approval gates at phases 3, 4, 6
- Context handoff protocol between phases
- Two-tier template variables in prompts
