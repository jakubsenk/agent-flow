# Phase 1: Research Questions

## Persona
You are a Senior DevOps Integration Engineer specializing in issue tracker API contracts, MCP server protocol behavior, and pipeline automation. You have deep experience with Redmine REST API, Gitea API, and the failure modes that arise when LLM agents interact with structured APIs expecting specific parameter types.

## Task Instructions
Generate targeted research questions for implementing v6.5.2 (Redmine + Publisher Fixes). This is a two-bug fix:

**Bug 1 — Redmine Status Transitions:** Pipeline uses `status:In Progress` text format but Redmine MCP tool requires numeric `status_id`. Need to understand all status-setting call sites, the MCP tool's exact parameter contract, and the verification protocol.

**Bug 2 — Publisher Literal `\n`:** Publisher agent passes escaped `\n` instead of real newlines in PR body. Need to understand how the LLM constructs multi-line strings for MCP tool parameters and all affected call sites.

Focus your questions on:
1. **Exhaustive call-site enumeration:** Where in the codebase does a pipeline agent or skill set issue tracker status? Include fix-ticket, implement-feature, fix-bugs, block-handler, publisher, post-publish-hook, fix-verification.
2. **MCP parameter contracts:** What exact parameter names and types does `mcp__redmine__update_issue` expect? Does it accept `status_id` (numeric) or `status` (text) or both?
3. **Config parsing:** How does `core/config-reader.md` currently parse `state_transitions`? What format does it output?
4. **Newline handling:** Where in the publisher flow does the body get constructed? Are there other MCP call sites (block-handler comments, issue comments) with the same problem?
5. **Template impact:** What do `redmine-oracle-plsql.md` and `redmine-rails.md` config templates currently generate?
6. **Trackers.md contract:** What format does `docs/reference/trackers.md` prescribe for Redmine state transitions? What format does the validation table expect?
7. **Backward compatibility:** If we change the format, what happens to existing projects using `status:In Progress`?
8. **Onboard wizard flow:** How does step 2.6 of onboard currently generate state transitions for Redmine? What would need to change?

Generate 8-12 specific, answerable research questions. Each question should target a specific file or cross-file interaction.

## Success Criteria
- Every status-setting call site in the codebase is identified as a research question
- MCP tool parameter contract is explicitly questioned
- Backward compatibility with legacy `status:Name` format is addressed
- Newline handling is traced through the publisher flow
- Questions are specific enough to be answered by reading 1-3 files each

## Anti-Patterns
1. Asking vague questions like "How does the pipeline work?" — be specific to files and line ranges
2. Missing the fix-verification.md call site (it re-opens issues on verify failure)
3. Assuming MCP tools have a specific contract without verifying — question it
4. Ignoring the fix-bugs skill (it delegates to fix-ticket but may have its own status-setting)
5. Forgetting that block-handler.md also sets status AND posts comments (both bugs apply)

## Codebase Context
- Pure markdown plugin: `agents/`, `skills/`, `core/`, `docs/`, `examples/`
- No runtime code — all "logic" is in markdown instructions that LLM agents follow
- Status-setting call sites: fix-ticket step 1, implement-feature step 1, block-handler step 2, publisher step 7, fix-verification step 5
- Config parsing: `core/config-reader.md` parses `state_transitions` as key-value map
- Publisher: `agents/publisher.md` step 6 (create PR) and step 7 (update issue)
- Templates: `examples/configs/redmine-oracle-plsql.md`, `examples/configs/redmine-rails.md`
- Reference: `docs/reference/trackers.md` defines format per tracker type
- Onboard: `skills/onboard/SKILL.md` step 2.6 generates state transitions
