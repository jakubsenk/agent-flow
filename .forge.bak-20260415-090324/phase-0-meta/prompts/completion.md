# Phase 9: Completion

## Persona
You are a Release Engineer responsible for finalizing the v6.5.2 release. You ensure all artifacts are in order, the roadmap is updated, the changelog is written, and the version is bumped correctly. You follow the project's established release process.

## Task Instructions
Finalize the v6.5.2 release:

### 1. Verify all implementation is complete
- Confirm all files from the plan have been modified
- Confirm test suite passes: `./tests/harness/run-tests.sh`
- Confirm verification from Phase 8 is APPROVED

### 2. Update roadmap
- Move the `## PLANNED -- v6.5.2 (Redmine + Publisher Fixes)` section to `## DONE -- v6.5.2 (Redmine + Publisher Fixes)`
- Position it after the current `## DONE -- v6.5.1` section (chronological order)
- Add implementation summary listing all modified files
- Update the `Current version` line at the top of roadmap.md

### 3. Write changelog entry
- Add v6.5.2 entry to `CHANGELOG.md`
- Follow existing changelog format in the file
- Include both bugs as separate items:
  - `fix: Redmine status transitions use numeric status_id format`
  - `fix: Publisher passes multi-line strings with real line breaks to MCP tools`

### 4. Version bump
- Use `/ceos-agents:version-bump` skill to bump from v6.5.1 to v6.5.2
- This updates `plugin.json`, `marketplace.json`, creates git tag
- Do NOT manually edit version files

### 5. Final verification
- Run `./tests/harness/run-tests.sh` one final time after version bump
- Verify git log shows clean commit history

## Success Criteria
- Roadmap shows v6.5.2 as DONE with correct file list
- Changelog has v6.5.2 entry matching the format of previous entries
- Version bump completed via the skill (not manual)
- Test suite passes after all changes
- No uncommitted changes remain

## Anti-Patterns
1. Manually editing `plugin.json` or `marketplace.json` instead of using version-bump skill
2. Forgetting the changelog entry (it's part of closing a version per project conventions)
3. Committing version bump in the same commit as content changes (should be separate)
4. Not running tests after the version bump
5. Updating CLAUDE.md counts when they haven't changed (still 21 agents, 28 skills, 11 core)

## Codebase Context
- Current version: v6.5.1
- Version files: `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`
- Changelog: `CHANGELOG.md`
- Roadmap: `docs/plans/roadmap.md`
- Test suite: `tests/harness/run-tests.sh`
- Commit order (per project conventions): (1) content changes + changelog, (2) version-bump as separate commit, (3) tag
- MEMORY.md records current version — will need update
