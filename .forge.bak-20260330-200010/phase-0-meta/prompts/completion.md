# Phase 9 — Completion

## Context

You are completing the v5.6.1 (UX Polish) release for the ceos-agents plugin. All changes have been implemented and verified. Finalize the release.

## Completion Steps

### Step 1: Update Roadmap

Move the 4 items from `PLANNED -- v5.6.1 (UX Polish)` to `DONE -- v5.6.1 (UX Polish)` in `docs/plans/roadmap.md`.

Format the DONE section following the existing pattern:

```markdown
## DONE -- v5.6.1 (UX Polish)

### --infra Flag Format
**Source:** v5.6.0 UX review
Changed positional `--infra ready,later` to self-documenting `--infra tracker:ready,sc:later` format. Order-independent, omitted key defaults to "later".
**Files:** `commands/scaffold.md`, `commands/resume-ticket.md`

### Canary-Write Announcement
**Source:** v5.6.0 UX review
Added announcement before canary-write: "Testing write access -- creating a temporary test item in {project}...". Interactive mode asks for confirmation. New `interactive` parameter in `core/mcp-detection.md` contract.
**Files:** `core/mcp-detection.md`, `commands/scaffold.md`

### Error Messages Use User Language
**Source:** v5.6.0 UX review
Replaced MCP jargon ("MCP server for {type} is not available") with user-friendly messages ("Cannot connect to your {type} tracker"). Added actionable next steps.
**Files:** `core/mcp-detection.md`, `commands/scaffold.md`

### Resume Infrastructure Override
**Source:** v5.6.0 UX review
`/resume-ticket` accepts `--infra` flag for scaffold pipeline resume. Overrides stale state.json infrastructure values. Prompts for details when upgrading from "later" to "ready".
**Files:** `commands/resume-ticket.md`
```

### Step 2: Create Changelog Entry

Add v5.6.1 entry to `CHANGELOG.md` following the existing format. Include all 4 items with file references.

### Step 3: Version Bump

Update version from 5.6.0 to 5.6.1 in:
- `.claude-plugin/plugin.json`
- `.claude-plugin/marketplace.json`

### Step 4: Update CLAUDE.md Memory

The current version in the project CLAUDE.md does not include a version field that needs updating. The memory file (`MEMORY.md`) tracks version — note v5.6.1 but do NOT modify the memory file (it is auto-managed).

### Step 5: Run Final Tests

Run `tests/harness/run-tests.sh` one final time to confirm everything is clean.

### Step 6: Summary Report

Produce a summary for the user:

```
## v5.6.1 Release Summary

**Type:** PATCH (UX Polish)
**Files modified:** 3 (commands/scaffold.md, core/mcp-detection.md, commands/resume-ticket.md)
**Files created:** 0

### Changes:
1. --infra flag: positional -> self-documenting key:value format (tracker:ready,sc:later)
2. Canary-write: announces before creating test item, asks in interactive mode
3. Error messages: MCP jargon replaced with user-friendly language + actionable steps
4. Resume: --infra flag support for scaffold pipeline resume with state override

### Commit ready. Version bumped to 5.6.1.
```

## Notes

- Do NOT push to remote — user decides when to push
- Do NOT create a git tag — user may want to review first
- Commit order per project conventions: (1) content changes + changelog in one commit, (2) version bump as separate commit
