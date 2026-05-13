# Phase 4 — Specification

You are a specification writer. Using the consensus from Phase 3 and the research from Phase 2, produce a precise specification for the version-check fix.

## Context

- Repository: `C:\gitea_ceos-agents`
- File to modify: `commands/version-check.md`
- Current version: 5.5.1
- This is a PATCH-level fix (no contract changes)

## Specification Format

### S1: Problem Statement

Describe the exact defect in 2-3 sentences. Reference the specific line and content.

### S2: Design Decisions

For each decision from the Phase 3 consensus, state the chosen approach and why:

1. **Plugin identifier resolution:** How does the command determine its own plugin key for `installed_plugins.json` lookup?
   - Option A: Hardcode `ceos-agents@ceos-agents` (this command ships with this plugin)
   - Option B: Read plugin name from `{commandDir}/../.claude-plugin/plugin.json` and marketplace from context
   - Option C: Derive from install path pattern in `installed_plugins.json`
   - Decision: [choose one, justify]

2. **Remote URL resolution:** What happens when `repository` field is missing from `plugin.json`?
   - Option A: Skip remote comparison, report "Cannot determine remote version — repository field missing from plugin.json"
   - Option B: Fall back to hardcoded URL
   - Decision: [must be A — hardcoded URLs are non-generic]

3. **Legacy marketplace check:** How to handle the `CLAUDE-agents` directory check?
   - Option A: Keep as-is with a comment explaining it's ceos-agents-specific history
   - Option B: Remove entirely
   - Option C: Generalize to check any `marketplaces/` subdirectory
   - Decision: [choose one, justify]

4. **Edge case handling level:** Minimal (handle fatal cases) or comprehensive (handle all 10 scenarios from QA persona)?
   - Decision: [choose, justify based on command simplicity vs reliability]

### S3: Exact Changes

For `commands/version-check.md`, specify:

1. **Line-by-line diff** of what changes. Use the actual current content as the baseline (the file is 63 lines).

2. For each changed line:
   - Old content (exact)
   - New content (exact)
   - Reason for change

### S4: Documentation Changes

For each file that needs updating:
- File path
- Section to change
- Old content
- New content

### S5: Version Decision

- Is this a new version (5.5.2) or an amendment to 5.5.1?
- If new version: what changes in CHANGELOG.md, plugin.json, marketplace.json?
- If amendment: what changes in CHANGELOG.md only?

### S6: Acceptance Criteria

1. AC-1: Running `/ceos-agents:version-check` from any directory (not in ceos-agents repo) shows installed version from `installed_plugins.json` and skips Part B
2. AC-2: Running `/ceos-agents:version-check` from inside the ceos-agents repo shows both installed version AND repo version comparison
3. AC-3: No hardcoded URLs appear anywhere in `commands/version-check.md`
4. AC-4: If `repository` field is missing from plugin.json, the command reports it cannot check remote version (does not error out)
5. AC-5: Legacy marketplace check runs and provides actionable advice if remnant found
6. AC-6: `docs/reference/commands.md` description for version-check is accurate

## Rules

- The spec must be complete enough that Phase 7 (execute) can implement it without ambiguity
- Every changed line must be specified exactly — no "update as appropriate"
- The spec must respect the ceos-agents plugin conventions (see CLAUDE.md: command format, versioning policy)
