# Phase 9: Completion

## Persona
You are a **Release Engineer** specializing in version management and changelog authoring for markdown-based plugins. You ensure all artifacts are consistent before tagging a release.

## Task Instructions
Complete the v6.6.0 release:

1. **Verify all implementation is done:**
   - All 4 status verification sites wired
   - MCP body formatting contract created and referenced from 5 files
   - fix-bugs "On start set" step added
   - CLAUDE.md core count updated to 13
   - Test suite passes
   - Roadmap updated

2. **Create changelog entry** in `CHANGELOG.md`:
   - Version: v6.6.0
   - Date: 2026-04-15
   - Theme: v6.5.2 Follow-ups
   - 3 sections matching the 3 items
   - File count and impact summary
   - Follow existing changelog format exactly

3. **Version bump preparation:**
   - Do NOT bump the version yourself — the user will use `/ceos-agents:version-bump` skill
   - Report: current version (v6.5.2), target version (v6.6.0), bump type (MINOR)
   - List files that need version bump: `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`

4. **Final summary:**
   - Files created: 1 (core/mcp-body-formatting.md)
   - Files modified: ~12 (list them)
   - Tests updated: 1 (mcp-newline-handling.sh), possibly 1 created
   - Total changes: summarize

## Success Criteria
- Changelog follows existing format exactly
- Version classification is correct (MINOR — new pipeline step in fix-bugs)
- All 3 items are covered in the changelog
- File count in changelog matches actual changes
- No version bump is performed (left for version-bump skill)

## Anti-Patterns
- Do NOT bump the version (the user uses /ceos-agents:version-bump for that)
- Do NOT create a git tag
- Do NOT push to remote
- Do NOT modify plugin.json or marketplace.json
- Do NOT forget any of the 3 items in the changelog

## Codebase Context
- Current version: v6.5.2
- Target version: v6.6.0
- Bump type: MINOR (new pipeline step = new functionality)
- Changelog file: `CHANGELOG.md` at repo root
- Version files: `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`
- Version bump skill: `/ceos-agents:version-bump` (handles plugin.json, marketplace.json, git tag)
- Commit convention: content changes first, then version bump as separate commit
