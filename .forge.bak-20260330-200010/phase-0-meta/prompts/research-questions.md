# Phase 1 — Research Questions

## Context

You are researching a v5.6.1 UX Polish release for the ceos-agents plugin (pure markdown, no runtime code). Four items need implementation across 3 markdown files.

## Questions to Answer

### Q1: --infra Flag Format (Item 1)
1. What is the current `--infra` flag format and all locations where it is parsed, validated, or referenced in `commands/scaffold.md`?
2. Are there any tests in `tests/` that validate the `--infra` flag format string?
3. Does `commands/resume-ticket.md` currently reference `--infra` in any way?
4. What is the exact format of the new `--infra tracker:ready,sc:later` syntax? Should it support shorthand like `--infra ready` (both ready) or `--infra later` (both later)?

### Q2: Canary-Write Announcement (Item 2)
5. What is the exact sequence of operations in `core/mcp-detection.md` step 4 (canary-write)? Where exactly should the announcement be inserted?
6. In `commands/scaffold.md`, is there a concept of "interactive mode" vs "YOLO mode" that should gate whether to ask vs. announce for canary-write?
7. Should the announcement happen inside `core/mcp-detection.md` (shared contract) or in `commands/scaffold.md` (caller)?

### Q3: Error Message Rewrite (Item 3)
8. List ALL occurrences of "MCP server for {type}" or similar MCP jargon in `commands/scaffold.md` and `core/mcp-detection.md`.
9. Are there other files (e.g., `commands/init.md`, `commands/resume-ticket.md`) that use similar MCP jargon phrasing?
10. What is the appropriate user-facing name for each tracker type? (e.g., "GitHub Issues" vs "GitHub", "YouTrack" vs "youtrack")

### Q4: Resume --infra Override (Item 4)
11. How does `commands/resume-ticket.md` currently detect and resume scaffold pipelines? Does it even support scaffold resume, or only bug/feature pipelines?
12. Where in the resume flow should `--infra` flag parsing and state override logic be inserted?
13. What state.json fields need to be overwritten when `--infra` is provided on resume?

## Research Scope

- **Primary files:** `commands/scaffold.md`, `core/mcp-detection.md`, `commands/resume-ticket.md`
- **Secondary files:** `tests/` directory (for test impact), `commands/init.md` (for MCP jargon consistency), `state/schema.md` (for infrastructure field reference)
- **Out of scope:** Agent definitions, skills, docs/plans (already reviewed)
