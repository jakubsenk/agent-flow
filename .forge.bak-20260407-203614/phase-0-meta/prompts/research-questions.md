# Phase 1: Research Questions — Autopilot Skill for ceos-agents

## Persona
You are a senior DevOps automation architect with 12+ years of experience designing CI/CD pipelines, unattended automation systems, and CLI tool orchestration. You are methodical and security-conscious, with deep knowledge of process management, file locking, and cross-platform scripting.

## Task Instructions
Generate research questions for implementing a new `/ceos-agents:autopilot` skill — an unattended pipeline runner that polls issue trackers and dispatches fix-bugs or implement-feature pipelines automatically.

The ceos-agents plugin is a pure-markdown Claude Code plugin (no runtime code). Skills are markdown orchestration documents in `skills/{name}/SKILL.md`. The autopilot skill must integrate with:
- Existing config contract (`## Automation Config` in CLAUDE.md)
- MCP tool system for issue tracker queries
- Existing pipeline skills (fix-bugs, implement-feature)
- State management (`.ceos-agents/` directory)

Key areas requiring research:
1. **Lock file mechanisms** — How should the autopilot prevent concurrent runs? What lock file format and location? How to handle stale locks (crashed previous run)?
2. **Issue classification** — How to reliably determine if a fetched issue is a bug vs feature? What tracker metadata to use?
3. **Existing skill dispatch patterns** — How do existing skills invoke sub-pipelines? What is the correct dispatch mechanism from one skill to another?
4. **State tracking for autopilot runs** — What state should be persisted across autopilot invocations? How to track which issues have been processed?
5. **Config contract extension** — What new optional config section is needed? What keys? What are the defaults?
6. **Logging format** — What log format should autopilot use? Where should logs be stored? How to integrate with existing pipeline.log?
7. **Error recovery** — What happens when a dispatched pipeline fails mid-run? How to clean up?
8. **Cross-platform scheduling** — What are the differences between Windows Task Scheduler and Unix cron for invoking Claude CLI?

## Success Criteria
- Minimum 8 research questions covering all key areas above
- Each question must be specific enough to yield actionable research in Phase 2
- Questions should address both the happy path and failure modes
- Questions should cover the config contract extension design

## Anti-Patterns
- Do not ask vague questions like "How should we design the system?" — be specific
- Do not duplicate questions across areas — each question should address a distinct concern
- Do not ask questions about out-of-scope items (server deployment, systemd, auth persistence)
- Do not assume runtime code — this is a pure markdown plugin

## Codebase Context
- Pure markdown plugin: 19 agents in `agents/`, 26 skills in `skills/*/SKILL.md`, 11 core contracts in `core/`
- Skills use YAML frontmatter: name, description, allowed-tools, disable-model-invocation, argument-hint
- Pipeline skills (fix-bugs, implement-feature) use `disable-model-invocation: true`
- Config parsed via `core/config-reader.md` from `## Automation Config` in project CLAUDE.md
- MCP tools: `mcp__youtrack__*`, `mcp__github__*`, `mcp__jira__*`, etc.
- State: `.ceos-agents/{RUN-ID}/state.json` per `state/schema.md`
- Existing query patterns: `Bug query` in Issue Tracker config, `Feature query` in Feature Workflow config
- fix-bugs accepts count argument, fetches N issues from Bug query
- implement-feature accepts ISSUE-ID or --description flag
- Version: 6.4.0, tests in `tests/` with shell harness
