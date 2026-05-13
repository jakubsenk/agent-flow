# Phase 0 — User Task (Verbatim)

Scaffold Infrastructure Integration (v5.5.0) — Redesign the scaffold command's infrastructure setup flow.

Full design document:
```
# Scaffold Infrastructure Integration — Design

**Status:** PROPOSED
**Target version:** v5.5.0 (MINOR — new optional behavior, no breaking changes)

## Problem

After `/scaffold` completes (Step 4: Git init → Step 4b: Tracker Configuration → Step 4c: MCP Guidance), the project is in a dead state:

1. **Step 4b** asks for tracker/SC values, writes them to CLAUDE.md, but does nothing else — no MCP setup, no connectivity check, no repo push
2. **Step 4c** prints informational text "run `/init`" — never actually runs it
3. **Step 9** creates tracker cards AFTER implementation — too late to be useful
4. No MCP verification during scaffold — `/check-setup` shows all FAIL after scaffold

The user ends up with a CLAUDE.md that has config values but zero working infrastructure.

## Design

### New Step 0-INFRA: Infrastructure Declaration
Replaces the current Step 4b and Step 4c. Moves to the very beginning of scaffold, before Mode Selection.
Two independent yes/no questions: "Do you have a tracker project ready?" and "Do you have a git repo ready?"
Options: (a) ready, (b) not now — I'll set it up later. All 4 combinations valid.

### New Step 0-MCP: MCP Verification
For each declared "ready" service: detect MCP server in session, if missing offer to run /init inline, verify connectivity (hard gate), collect details.

### Modified Step 4: Git Init + Auto-Config
After git init: auto-fill CLAUDE.md values from Step 0-MCP data for "ready" services (no TODO markers). For "later" services keep TODO markers. Generate .mcp.json.example. Add .mcp.json to .gitignore.

### New Step 4d: Push to Remote (if SC ready)
git remote add + push. WARN on failure, don't block.

### New Step 4e: Create Tracker Issues (if tracker ready)
Create epic + sub-issues from spec/epics/*.md. Write issue IDs back into spec files. NEVER create issues retroactively.

### Removed Steps
- Step 4b (Tracker Configuration) → replaced by Step 0-INFRA + Step 4 auto-fill
- Step 4c (MCP Guidance) → replaced by Step 0-MCP inline /init
- Step 9 (Issue Tracker Optional) → replaced by Step 4e (moved before implementation)

### Modified Step 10: Report
Show infrastructure status — what connected, what's pending, next steps per service.

### Full YOLO: Step 0-INFRA still asks (prerequisite decision, not quality gate).
### --no-implement legacy flow: add Step 0-INFRA before L1 but no tracker issue creation.
```

Summary of changes:
1. NEW Step 0-INFRA (before Mode Selection): Ask 2 independent yes/no questions
2. NEW Step 0-MCP (after Step 0-INFRA): MCP detection, /init inline, connectivity verification
3. MODIFY Step 4 (Git Init): Auto-fill from MCP data, .mcp.json.example, .gitignore
4. NEW Step 4d: Push to remote (if SC ready)
5. NEW Step 4e: Create tracker issues from spec (if tracker ready)
6. REMOVE Step 4b, Step 4c, Step 9
7. MODIFY Step 10: Infrastructure status in report
8. IMPORTANT: All documentation files that reference scaffold steps must also be updated (docs, diagrams, README, architecture docs, reference docs, etc.)

Files to modify: commands/scaffold.md (primary), commands/init.md (ensure inline invocation works), docs/reference/automation-config.md (if needed), AND any other files that reference scaffold steps.

No changes to agents, no new agents, no Automation Config contract changes. This is a MINOR version bump.
