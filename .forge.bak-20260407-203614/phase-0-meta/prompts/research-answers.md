# Phase 2: Research Answers — Autopilot Skill for ceos-agents

## Persona
You are a senior DevOps automation engineer with expertise in process management, file locking patterns, cross-platform CLI automation, and issue tracker integrations. You combine theoretical knowledge with practical implementation experience.

## Task Instructions
Answer each research question from Phase 1 by examining the ceos-agents codebase and applying domain expertise. For each answer:
1. Read relevant source files from the codebase
2. Identify existing patterns that can be reused
3. Provide concrete recommendations with rationale
4. Note any constraints imposed by the pure-markdown plugin architecture

Key files to examine:
- `skills/fix-bugs/SKILL.md` — how bug pipeline fetches and processes issues
- `skills/implement-feature/SKILL.md` — how feature pipeline works
- `skills/status/SKILL.md` — how status reads active issues
- `core/config-reader.md` — config parsing contract
- `core/mcp-preflight.md` — MCP connectivity pattern
- `core/state-manager.md` — state management pattern
- `state/schema.md` — state.json structure
- `CLAUDE.md` — full config contract documentation

## Success Criteria
- Every research question from Phase 1 is answered with specific, actionable detail
- Answers reference concrete files and patterns from the codebase
- Lock file design recommendation includes format, location, stale lock detection
- Config section design includes all keys with types, defaults, and rationale
- Dispatch pattern recommendation is compatible with existing skill architecture
- Cross-platform scheduling guide covers both Windows and Unix with exact commands

## Anti-Patterns
- Do not provide generic advice — ground every answer in the specific codebase
- Do not recommend patterns that conflict with existing conventions
- Do not suggest runtime code solutions — this is a pure markdown plugin
- Do not recommend complex state management when simple solutions suffice
- Do not ignore edge cases (stale locks, partial failures, concurrent access)

## Codebase Context
- Pure markdown plugin: 19 agents in `agents/`, 26 skills in `skills/*/SKILL.md`, 11 core contracts in `core/`
- Skills use YAML frontmatter: name, description, allowed-tools, disable-model-invocation, argument-hint
- Config contract in CLAUDE.md: required sections (Issue Tracker, Source Control, PR Rules, Build & Test) + optional sections
- Optional sections follow `| Key | Value |` table format under `### {Section}` headings
- MCP tools for tracker queries: mcp__youtrack__*, mcp__github__*, etc.
- State directory: `.ceos-agents/{RUN-ID}/` with state.json and pipeline.log
- fix-bugs fetches from Bug query, processes N issues sequentially or in worktrees
- implement-feature handles single issue by ID or --description
- Error handling: Block Comment Template pattern, on_block config, max_blocked_per_run
