# Phase 9: Completion

## Persona
You are a **Release Engineer** specializing in version management and changelog authoring for markdown-based plugins. You ensure all artifacts are consistent before tagging a release.

## Task Instructions
Complete the v6.7.1 release:

1. **Verify all implementation is done:**
   - Item 1: config-reader has `create_tracker_subtasks` in Decomposition section
   - Item 2: fix-bugs has Config Validity Gate (Step 0b)
   - Item 3: state schema has `spec_iterations` and `root_cause_iterations`
   - Item 4: implement-feature has conditional code-analyst step (Step 3a)
   - Item 5: external-input-sanitizer has marker escaping step
   - Item 6: state-manager has graceful degradation clause
   - Item 7: acceptance-gate, architect, reproducer have NEVER constraint
   - Roadmap updated (PLANNED -> DONE)
   - Test suite passes

2. **Create changelog entry** in `CHANGELOG.md`:
   - Version: v6.7.1
   - Date: 2026-04-15
   - Theme: Contract & Schema Fixes + Hardening Follow-ups
   - 7 items organized by category (contract fixes, schema fixes, security hardening, behavioral enhancements, documentation)
   - File count and impact summary
   - Follow existing changelog format exactly

3. **Version bump preparation:**
   - Do NOT bump the version yourself — the user will use `/ceos-agents:version-bump` skill
   - Report: current version (v6.7.0), target version (v6.7.1), bump type (PATCH)
   - List files that need version bump: `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`

4. **Final summary:**
   - Files modified: ~10 (list them all)
   - Files created: 0
   - Tests created/updated: list them
   - Total changes: summarize per-item

## Success Criteria
- Changelog follows existing format exactly
- Version classification is correct (PATCH — no new contract keys, no new agents, no breaking changes)
- All 7 items are covered in the changelog
- File count in changelog matches actual changes
- No version bump is performed (left for version-bump skill)

## Anti-Patterns
- Do NOT bump the version (the user uses /ceos-agents:version-bump for that)
- Do NOT create a git tag
- Do NOT push to remote
- Do NOT modify plugin.json or marketplace.json
- Do NOT forget any of the 7 items in the changelog

## Codebase Context
- Current version: v6.7.0
- Target version: v6.7.1
- Bump type: PATCH (corrective fixes, no new contract keys)
- Changelog file: `CHANGELOG.md` at repo root
- Version files: `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`
- Version bump skill: `/ceos-agents:version-bump` (handles plugin.json, marketplace.json, git tag)
- Commit convention: content changes first, then version bump as separate commit
