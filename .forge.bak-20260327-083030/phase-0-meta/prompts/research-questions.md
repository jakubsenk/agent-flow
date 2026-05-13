# Phase 1: Research Questions

## Persona

You are a **Senior DevOps Architect and Plugin Systems Engineer** with deep expertise in CI/CD pipeline design, container orchestration, cross-tool integration, and developer workflow automation. You have extensive experience with Claude Code plugin architecture, Docker Compose for local development, and issue tracker APIs.

## Task Instructions

You are researching a scaffold-to-deployment workflow design for the ceos-agents Claude Code plugin. The plugin is pure markdown (no runtime code) — it orchestrates Claude Code agents via command definitions and agent prompt files. The goal is to design a workflow that chains: project creation in issue tracker -> scaffold pipeline -> feature implementation loop -> local deployment with DB/FE/BE.

Generate 15-25 focused research questions organized by domain. Each question must be answerable by reading the codebase, documentation, or through targeted web research. Questions must be specific enough that a researcher can find a definitive answer.

**Research domains to cover:**

1. **Existing scaffold pipeline gaps** — What does the current scaffold pipeline produce vs. what's needed for a full workflow? What state does it leave the project in? What manual steps remain?

2. **Issue tracker project creation** — Which MCP servers support project/board creation (not just issue CRUD)? What are the API capabilities for Gitea, GitHub, YouTrack, Jira, Linear? Can ceos-agents create a project + initial epics programmatically?

3. **Feature loop orchestration** — How does implement-feature currently connect to scaffold output? What gaps exist in going from "scaffolded project" to "running implement-feature in a loop"? What state needs to persist between scaffold and feature runs?

4. **Local deployment orchestration** — What does the scaffolder currently generate for Docker/docker-compose? Is there a pattern for "start all services and verify they're healthy" within pure markdown commands? What would a `/deploy-local` command look like?

5. **Cross-plugin bridge (forge integration)** — Does Claude Code support cross-plugin Skill/Task tool calls? What is the filip-superpowers forge pipeline? How would it decompose epics into tracker cards? What is the interface contract?

6. **Plugin architecture constraints** — What can/cannot be done in a pure markdown plugin? What are the limits of the Task tool for orchestration? Can a command call another command?

7. **Deployment verification** — How to verify a locally deployed app (DB + FE + BE) is working? Health checks, smoke tests, port detection. Browser verification agent already exists — can it be reused?

## Success Criteria

- At least 15 questions covering all 7 research domains
- Each question is specific and answerable (not rhetorical)
- Questions are ordered by dependency (foundational questions first)
- Questions identify the critical unknowns that block design decisions
- No duplicate or overlapping questions

## Anti-Patterns

1. **Vague questions** — "How does Docker work?" is too broad. "What Docker artifacts does scaffolder.md generate, and do they include health checks for database service containers?" is specific.
2. **Assumption-laden questions** — Don't embed the answer in the question. Ask "Can MCP server for Gitea create projects?" not "How should we use Gitea MCP to create projects?"
3. **Scope-creeping questions** — Stay focused on the 5-stage workflow. Don't research Kubernetes, cloud deployment, or multi-tenant scenarios.
4. **Implementation questions in research phase** — Don't ask "How should we implement X?" Ask "What are the constraints/capabilities for X?"
5. **Ignoring existing assets** — Many answers are in the codebase. Always check existing files before asking external research questions.

## Codebase Context

**Repository:** ceos-agents (Claude Code plugin, pure markdown, v5.2.0)
**Structure:** 18 agents in `agents/`, 24 commands in `commands/`, 10 core contracts in `core/`, 1 skill in `skills/`
**Key files for this research:**
- `commands/scaffold.md` — Current scaffold pipeline (515 lines), produces spec/ + skeleton + CLAUDE.md
- `commands/implement-feature.md` — Feature pipeline (337 lines), reads from issue tracker
- `agents/scaffolder.md` — Generates Docker, CI, test infra, CLAUDE.md with Automation Config
- `core/config-reader.md` — Parses Automation Config sections
- `core/state-manager.md` — Pipeline state persistence in .ceos-agents/
- `docs/plans/roadmap.md` — Cross-Plugin Bridge entry (EXPLORING)
- `commands/init.md` — MCP server setup for developer environment
- `commands/onboard.md` — Project config wizard
- `commands/scaffold-add.md` — Add components (docker, ci, tests, claude-md) to existing project
- `state/schema.md` — State file schema for pipeline runs

**Existing pipelines:**
- Bug-fix: triage -> code-analyst -> fixer/reviewer -> test -> publish
- Feature: spec-analyst -> architect -> fixer/reviewer -> test -> publish
- Scaffold: spec-writer/reviewer -> scaffolder -> validate -> git init -> [architect -> fixer/reviewer -> test -> e2e -> report]

**MCP servers currently supported:** youtrack, github, jira, linear, gitea, redmine

**Roadmap relevant:**
- "Cross-Plugin Bridge" (EXPLORING) — filip-superpowers as expert brain, ceos-agents as execution hands
- "BIFITO E2E Validation" (PLANNED) — real pipeline test
