# Phase 4: Specification — Autopilot Skill for ceos-agents

## Persona
You are a principal software architect with 15+ years of experience writing precise technical specifications for automation systems. You excel at defining contracts, interfaces, and behavior with zero ambiguity. You are meticulous about edge cases and error handling.

## Task Instructions
Write a complete specification for the `/ceos-agents:autopilot` skill based on the brainstorm synthesis from Phase 3. The specification must be precise enough for a developer to implement without asking clarifying questions.

The specification must cover:

### A. Skill Definition
- YAML frontmatter (name, description, allowed-tools, disable-model-invocation, argument-hint)
- Skill behavior: what the skill does step-by-step when invoked
- Arguments: flags, defaults, validation

### B. Config Contract Extension
- New `### Autopilot` optional config section in Automation Config
- All keys with types, defaults, descriptions
- How the section interacts with existing Bug query and Feature query
- Validation rules for the config section

### C. Lock File Protocol
- Lock file location, format, content
- Acquisition: how to acquire, what to check
- Release: when to release, cleanup on error
- Stale lock detection: timeout, PID checking (if applicable)

### D. Issue Processing Logic
- How issues are fetched (Bug query + Feature query)
- How issue type is determined (bug vs feature)
- How "already in progress" issues are detected and skipped
- Dispatch logic: how fix-bugs/implement-feature are invoked per issue
- Max issues per run enforcement
- Sequential vs parallel processing

### E. Logging and State
- Log file location, format, entries
- What state persists across invocations
- Run history tracking

### F. Error Handling
- Error categories and responses
- When to skip an issue vs stop the run
- How to report errors in the log

### G. Documentation Deliverables
- Setup guide for Windows Task Scheduler
- Setup guide for Unix cron
- Integration with existing docs structure

### H. Config Contract Documentation
- Updates to CLAUDE.md config contract table
- Updates to docs/reference/ if applicable

## Success Criteria
- Every behavior is specified with no ambiguity
- All config keys have types, defaults, and validation rules
- Lock file protocol handles all edge cases (stale, crash, concurrent)
- Error handling covers all failure modes
- Spec is implementable from markdown alone (no runtime code assumptions)
- All documentation deliverables are enumerated with content outlines

## Anti-Patterns
- Do not leave design decisions open — make every choice explicit
- Do not specify behavior that requires runtime code
- Do not break the existing config contract
- Do not specify features outside PoC scope (server deployment, auth, systemd)
- Do not assume any specific issue tracker — the spec must work for all supported types (youtrack, github, jira, linear, gitea, redmine)
- Do not forget to specify the version bump implications (new optional section = MINOR bump)

## Codebase Context
- Pure markdown plugin: 19 agents, 26 skills, 11 core contracts
- CLAUDE.md config contract: required sections + 15 optional sections
- Versioning policy: new optional section = MINOR bump (6.4.0 -> 6.5.0)
- Skills use `disable-model-invocation: true` for pipeline skills
- Config reader: `core/config-reader.md` — parses `| Key | Value |` tables
- State: `.ceos-agents/{RUN-ID}/state.json` with atomic writes
- Tests: `tests/` with shell harness, scenarios validate markdown structure
- Docs: `docs/guides/` for setup guides, `docs/reference/` for command/skill reference
