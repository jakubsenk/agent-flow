# Changelog

All notable changes to agent-flow will be documented in this file.

## [1.0.0] — 2026-05-14

### Initial Public Release

agent-flow is a Claude Code plugin that automates software development workflows —
bug fixes, feature implementation, and project scaffolding — from issue tracker
to merged PR, using a pipeline of specialized AI agents.

### What's included

**17 skills (slash commands):**
`/analyze-bug`, `/autopilot`, `/changelog`, `/check-setup`, `/create-backlog`,
`/discuss`, `/fix-bugs`, `/implement-feature`, `/metrics`, `/onboard`,
`/prioritize`, `/publish`, `/scaffold`, `/setup-agents`, `/setup-mcp`,
`/sprint-plan`, `/version-check`

**17 agents:**
`acceptance-gate`, `analyst`, `architect`, `backlog-creator`, `browser-agent`,
`deployment-verifier`, `fixer`, `priority-engine`, `publisher`, `reviewer`,
`rollback-agent`, `scaffolder`, `spec-analyst`, `spec-reviewer`, `spec-writer`,
`sprint-planner`, `test-engineer`

**3 pipeline types:**
- Bug-fix: issue tracker → triage → fix → review → test → PR
- Feature: spec → architecture → implementation → review → test → PR
- Scaffold: description → spec → code → test → git init

**Key capabilities:**
- Configurable via `## Automation Config` in your project's CLAUDE.md
- Supports YouTrack, GitHub Issues, Jira, Linear, Gitea, Redmine
- Agent Overrides for per-project customization
- Pipeline profiles, hooks, browser verification, decomposition
- Autopilot mode for batch processing
