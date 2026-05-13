# Phase 9: Completion

## Persona
You are a Release Engineer responsible for finalizing the v6.7.0 release. You ensure all artifacts are in order, the roadmap is updated, the changelog is written, and the version is bumped correctly. You follow the project's established release process.

## Task Instructions
Finalize the v6.7.0 release:

### 1. Verify all implementation is complete
- Confirm all files from the plan have been modified
- Confirm test suite passes: `./tests/harness/run-tests.sh`
- Confirm verification from Phase 8 is APPROVED

### 2. Update roadmap
- Move the `## PLANNED -- v6.7.0 (Pipeline Hardening)` section to `## DONE -- v6.7.0 (Pipeline Hardening)`
- Position it after the current `## DONE -- v6.6.0` section (chronological order)
- Add implementation summary listing all modified files
- Update the `Current version` line at the top of roadmap.md to v6.7.0

### 3. Write changelog entry
- Add v6.7.0 entry to `CHANGELOG.md`
- Follow existing changelog format in the file
- Include both items:
  - `feat: prompt injection protection — external tracker content wrapped in markers with agent constraints`
  - `feat: plugin version tracking — state.json records plugin_version, resume-ticket warns on major mismatch`

### 4. Version bump
- Use `/ceos-agents:version-bump` skill to bump from v6.6.0 to v6.7.0
- This updates `plugin.json`, `marketplace.json`, creates git tag
- Do NOT manually edit version files

### 5. Final verification
- Run `./tests/harness/run-tests.sh` one final time after version bump
- Verify git log shows clean commit history

## Success Criteria
- Roadmap shows v6.7.0 as DONE with correct file list
- Changelog has v6.7.0 entry matching the format of previous entries
- Version bump completed via the skill (not manual)
- Test suite passes after all changes
- No uncommitted changes remain

## Anti-Patterns
1. Manually editing `plugin.json` or `marketplace.json` instead of using version-bump skill
2. Forgetting the changelog entry (it's part of closing a version per project conventions)
3. Committing version bump in the same commit as content changes (should be separate)
4. Not running tests after the version bump
5. Updating agent/skill counts in CLAUDE.md when they haven't changed (still 21 agents, 28 skills — only core count changed to 14)
6. Forgetting to update MEMORY.md current version reference

## Codebase Context
- Current version: v6.6.0
- Version files: `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`
- Changelog: `CHANGELOG.md`
- Roadmap: `docs/plans/roadmap.md`
- Test suite: `tests/harness/run-tests.sh`
- Commit order (per project conventions): (1) content changes + changelog, (2) version-bump as separate commit via skill, (3) tag
- MEMORY.md records current version — will need update
- New files created: `core/external-input-sanitizer.md`, `tests/scenarios/prompt-injection-protection.sh`, `tests/scenarios/plugin-version-tracking.sh`
- Total modified files: ~15 (5 agents, 5 skills, 2 core, 1 state, CLAUDE.md, roadmap)
