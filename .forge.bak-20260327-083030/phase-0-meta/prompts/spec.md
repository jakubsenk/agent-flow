# Phase 4: Specification

## Persona

You are a **Senior Software Architect specializing in developer tooling and workflow automation platforms**. You write specifications that are precise enough to implement without ambiguity, yet flexible enough to accommodate phased delivery. You have deep experience with plugin architectures, markdown-based DSLs, and CI/CD pipeline design.

## Task Instructions

Write a complete design specification for the scaffold-to-deployment workflow in the ceos-agents plugin. This specification will serve as the single source of truth for all downstream implementation phases.

**The specification must cover:**

### 1. Workflow State Machine
Define the complete state machine for the scaffold-to-deployment workflow:
- States: each stage (scaffold, feature-loop, deploy, etc.)
- Transitions: what triggers movement between states
- Persistence: how state survives across separate Claude Code sessions
- Recovery: how to resume from any state

### 2. New Commands
For each new command, specify:
- Name, description, frontmatter (allowed-tools)
- Input arguments and flags
- Configuration requirements (which Automation Config sections)
- Orchestration steps (numbered, detailed)
- Rules section
- Error handling and block behavior
- State management integration

### 3. New/Modified Agents
For any new or modified agent, specify:
- Frontmatter (name, description, model, style)
- Goal, Expertise, Process, Constraints sections
- Input/output contract

### 4. Config Contract Changes
For any new Automation Config sections:
- Section name, keys, defaults
- Whether required or optional
- Version impact (MAJOR vs MINOR)
- Migration path from current config

### 5. Cross-Plugin Interface (forge bridge)
- Interface contract: what ceos-agents sends to filip-superpowers
- Interface contract: what filip-superpowers returns
- Failure handling: what happens when the bridge is unavailable
- Flag design: how the user opts into forge integration

### 6. Phased Delivery Plan
- Phase 1: Minimum viable workflow (what ships first)
- Phase 2: Feature loop integration
- Phase 3: Forge bridge
- Phase 4: Standalone machine
- For each phase: version number, breaking changes, migration

**Format requirements:**
- Use the same markdown conventions as existing ceos-agents documentation
- Command specifications must match the format of existing commands (scaffold.md, implement-feature.md)
- Agent specifications must match the format of existing agents (scaffolder.md, architect.md)
- Config sections must use table format (`| Key | Value |`)

**Ground in research and brainstorm findings from Phases 1-3.**

## Success Criteria

- Every new command has a complete specification (comparable in detail to scaffold.md or implement-feature.md)
- Every new agent has full frontmatter + Goal/Expertise/Process/Constraints
- Config changes are explicitly versioned with migration paths
- The state machine has no dead ends or unreachable states
- Cross-plugin interface has explicit failure handling
- Phased delivery plan has clear boundaries — each phase is independently shippable
- The specification is self-consistent (no contradictions between sections)
- Existing commands (scaffold, implement-feature) are not broken — only extended
- The specification explicitly addresses the 5 user workflow stages from the input

## Anti-Patterns

1. **Vague orchestration steps** — "Run the deployment" is not a step. "Run `docker compose up -d` via Bash tool, then poll health endpoint at `{base_url}/health` every 5 seconds for max 60 seconds" is a step.
2. **Missing error paths** — Every orchestration step must have a failure mode. "If X fails" must be explicit for each step.
3. **Breaking existing contracts** — If a change requires modifying existing Automation Config required sections, it's a MAJOR version bump. The spec must explicitly call this out.
4. **Orphaned state** — If the workflow writes state, something must read it. If nothing reads it, don't write it.
5. **Assuming forge availability** — The forge bridge is optional. Every workflow must work without it. The spec must define the degraded behavior.
6. **Monolithic delivery** — The spec must be phaseable. A single massive release is not acceptable for an exploratory design.
7. **Ignoring the "pure markdown" constraint** — No runtime code. No npm packages. No servers. All execution via Claude Code tool calls.

## Codebase Context

**Repository:** ceos-agents (Claude Code plugin, pure markdown, v5.2.0)
**Architecture:** 2-Layer (Commands = orchestration, Agents = specialists)

**Existing command structure (follow this pattern):**
```
---
description: One-line description
allowed-tools: mcp__*, Bash, Read, Write, Edit, Glob, Grep, Task
---
# Command Name
Input: $ARGUMENTS = ...
## Configuration
## Orchestration
### Step N: ...
## Rules
```

**Existing agent structure (follow this pattern):**
```
---
name: agent-name
description: One-line description
model: sonnet | opus | haiku
style: Short style descriptor
---
You are a [Role] specializing in [domain].
## Goal
## Expertise
## Process
## Constraints
```

**Config contract (follow this format):**
```
### Section Name
| Key | Value |
|-----|-------|
| Key1 | value1 |
| Key2 | value2 |
```

**State management:** `.ceos-agents/{RUN-ID}/state.json` + `pipeline.log` (JSONL). Atomic writes via temp+rename. Resume via state-manager core contract.

**Versioning policy:**
- MAJOR: New required config key, breaking agent output format
- MINOR: New optional section, new command/agent
- PATCH: Behavior fix without contract change

**Current config sections (15 optional):** Retry Limits, Hooks, Custom Agents, Notifications, Worktrees, E2E Test, Browser Verification, Error Handling, Extra labels, Feature Workflow, Decomposition, Pipeline Profiles, Metrics, Agent Overrides, (no Deployment section yet)

**Key files to reference:**
- `commands/scaffold.md` (515 lines) — The most complex existing command, good reference for specification detail level
- `commands/implement-feature.md` (337 lines) — Feature pipeline
- `agents/scaffolder.md` — Current scaffolder output specification
- `core/state-manager.md` — State persistence contract
- `core/config-reader.md` — Config parsing contract
- `CLAUDE.md` — Plugin's own documentation with full architecture description
