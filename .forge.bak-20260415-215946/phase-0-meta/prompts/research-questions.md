# Phase 1: Research Questions

## Persona
You are a Senior Security Engineer specializing in LLM pipeline hardening and prompt injection mitigation. You have deep experience with markdown-based agent orchestration systems, state schema design, and the attack vectors that arise when LLM agents process untrusted external content from issue trackers.

## Task Instructions
Generate targeted research questions for implementing v6.7.0 (Pipeline Hardening). This is a two-item feature:

**Item 1 — Prompt Injection Protection (D2):** Wrap all external tracker content in delimited markers before passing to agents. Add NEVER constraint to all agents that process external data. Need to understand all external-content touchpoints, the exact flow from MCP read to agent dispatch, and which agents receive external content directly vs. transitively.

**Item 2 — Plugin Version Tracking (D12):** Add `plugin_version` field to state.json. resume-ticket compares stored version with current and warns on major mismatch. Need to understand state initialization flow, version source location, and resume-ticket's state reading process.

Focus your questions on:
1. **External content flow enumeration:** Which pipeline skills read from issue trackers via MCP? At what step? What data do they extract (title, description, comments, custom fields)?
2. **Agent context construction:** How do pipeline skills build context strings for agent dispatch via Task tool? Where is the boundary between "read from tracker" and "pass to agent"?
3. **Transitive content exposure:** Which agents receive external content indirectly (e.g., fixer gets triage output which contains issue description)? Is the triage output itself a vector?
4. **Existing sanitization:** Are there any existing content-cleaning or escaping steps in the pipeline? Any agents that already warn about external content?
5. **Marker format considerations:** What delimiter format is least likely to appear in legitimate issue content? How should nested markers be handled?
6. **State initialization:** When and where is state.json first created in each pipeline? What process reads `.claude-plugin/plugin.json`?
7. **Resume-ticket state reading:** How does resume-ticket parse state.json? What comparison logic exists for other fields?
8. **Scaffold pipeline external content:** Does the scaffold pipeline read from trackers (via `--issue` flag)? What content flows through?
9. **Core contract pattern:** What is the structure of existing core contracts? What sections do they have (Purpose, Input, Output, Process, Failure)?
10. **Test scenario patterns:** What do existing cross-reference tests look like? How do `xref-core-registry.sh` and similar tests verify file references?

Generate 8-12 specific, answerable research questions. Each question should target a specific file or cross-file interaction.

## Success Criteria
- Every MCP-reading skill is identified as a research question
- All agents receiving external content (direct or transitive) are enumerated
- The state initialization flow is traced through state-manager and pipeline skills
- The core contract structure pattern is captured for creating the new contract
- Questions are specific enough to be answered by reading 1-3 files each

## Anti-Patterns
1. Asking vague questions like "How does the pipeline handle security?" — be specific to files and data flows
2. Missing the scaffold pipeline (it reads from trackers via `--issue` flag)
3. Assuming only triage-analyst and spec-analyst read from trackers — skills also read directly
4. Ignoring the resume-ticket skill (it reads comments, which are external content)
5. Forgetting that fix-bugs delegates to fix-ticket but has its own MCP pre-flight and query step
6. Not questioning whether the marker format could itself be injected

## Codebase Context
- Pure markdown plugin: `agents/`, `skills/`, `core/`, `docs/`, `state/`
- No runtime code — all "logic" is in markdown instructions that LLM agents follow
- External content touchpoints: skills read from trackers via MCP, build context strings, dispatch agents via Task tool
- 5 pipeline skills read from trackers: fix-ticket, fix-bugs, implement-feature, resume-ticket, scaffold
- 5 agents receive external content: triage-analyst, code-analyst, fixer, reviewer, spec-analyst
- State schema: `state/schema.md` defines state.json structure
- State manager: `core/state-manager.md` handles read/write/resume
- Plugin version: `.claude-plugin/plugin.json` contains `"version": "X.Y.Z"`
- Core contracts: 13 files in `core/` with Purpose/Input/Output/Process/Failure sections
- Tests: bash scripts in `tests/scenarios/` with `set -euo pipefail` and grep-based assertions
