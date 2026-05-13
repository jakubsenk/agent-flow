# Phase 9 — Finish

## Context

v5.6.0 — Scaffold Infrastructure Polish implementation is complete and verified. This phase handles documentation updates and version housekeeping.

## Tasks

### 1. Verify CHANGELOG.md entry

Confirm `CHANGELOG.md` has the `[5.6.0]` entry at the top (created during Phase 7). If missing, create it with:
- Section: `## [5.6.0] — {today's date}`
- Level: **MINOR**
- Summary: Scaffold Infrastructure Polish
- Added: 6 items (core/mcp-detection.md, .mcp.json.example detection, infrastructure state field, --infra flag, canary-write check, YOLO+no-MCP block)
- Changed: scaffold.md and init.md refactored to reference core contract
- Details: 11 core contracts (was 10)

### 2. Verify roadmap.md update

Confirm `docs/plans/roadmap.md` has:
- A new `## DONE — v5.6.0 (Scaffold Infrastructure Polish)` section with the 6 implemented items
- The "Commands-to-Skills Architecture Evaluation" item remains in a PLANNED section (not part of this release)
- Version in the header updated to v5.6.0

### 3. Verify CLAUDE.md core count

Confirm `CLAUDE.md` Repository Structure section says "11 shared contracts" (was 10).

### 4. Version bump considerations

Do NOT bump version in `plugin.json` or `marketplace.json` — that is done separately via `/ceos-agents:version-bump` after review.

### 5. Final commit order (for human)

Recommend to user:
1. Content changes (all markdown edits) — single commit
2. Changelog entry — same commit as content changes
3. Version bump — separate commit via `/ceos-agents:version-bump minor`
4. Git tag — created by version-bump command

### 6. Summary report

Display a summary of all changes made:

```
## v5.6.0 — Scaffold Infrastructure Polish — Complete

### New files:
- core/mcp-detection.md — shared MCP detection contract (11th core contract)

### Modified files:
- commands/scaffold.md — Step 0-MCP refactored, --infra flag, canary-write, YOLO+--issue block
- commands/init.md — Step 1b (.mcp.json.example detection), Steps 3+7 refactored
- commands/implement-feature.md — YOLO+--description MCP block
- state/schema.md — infrastructure field
- core/state-manager.md — infrastructure field note
- docs/plans/roadmap.md — DONE v5.6.0 section
- CHANGELOG.md — v5.6.0 entry
- CLAUDE.md — core count 10 → 11

### Counts:
- 1 file created, 8 files modified
- 19 agents (unchanged), 25 commands (unchanged), 11 core contracts (+1)
- 14 optional Automation Config sections (unchanged)
- No breaking changes

### Next steps:
1. Review all changes
2. Run ./tests/harness/run-tests.sh
3. Commit: git add ... && git commit -m "feat: v5.6.0 scaffold infrastructure polish"
4. Version bump: /ceos-agents:version-bump minor
```
