# Phase 9 — Completion

## Persona
{{PERSONA}}: Release Manager for the ceos-agents plugin. Responsible for final commit, version bump, changelog validation, and handoff summary.

## Task Instructions
{{TASK_INSTRUCTIONS}}:

Finalize ceos-agents v6.3.1 release. This phase handles commit, version bump, and summary.

### Step 1: Pre-commit verification
1. Run `./tests/harness/run-tests.sh` one final time
2. Verify all tests pass
3. Run `git diff` to review all changes
4. Confirm no unintended files are modified

### Step 2: Commit content changes
Stage and commit the content files + changelog:
```bash
git add skills/analyze-bug/SKILL.md skills/fix-bugs/SKILL.md agents/scaffolder.md tests/scenarios/scaffolder-e2e-batch.sh CHANGELOG.md
git commit -m "fix: UNCLEAR handler, cross-stack Playwright detection, test grep fragility (v6.3.1)"
```

### Step 3: Version bump
Use the `/ceos-agents:version-bump` skill OR manually:
1. Update `.claude-plugin/plugin.json`: version "6.3.0" → "6.3.1"
2. Update `.claude-plugin/marketplace.json`: version "6.3.0" → "6.3.1"
3. Update `docs/plans/roadmap.md`: Current version line
4. Commit: `chore: bump version 6.3.0 → 6.3.1`
5. Tag: `git tag v6.3.1`

### Step 4: Update roadmap
Move the "Triage UNCLEAR Handler + Scaffold Patch Fixes — v6.3.1" item from "PLANNED — Next" to "DONE" section in `docs/plans/roadmap.md`.

### Step 5: Handoff summary

Produce a structured summary:

```
## v6.3.1 Release Summary

### Changes
1. **analyze-bug UNCLEAR handler** — Step 3a added. On UNCLEAR triage, posts Block Comment to tracker and stops.
2. **fix-bugs UNCLEAR path** — Step 2 UNCLEAR bullet now explicitly posts Block Comment (dry-run: record only).
3. **Scaffolder Batch 7 cross-stack detection** — Detects Playwright via package.json, pyproject.toml, and Gemfile. Generates language-appropriate test files.
4. **Test grep fragility** — Section-aware sed|grep patterns. Specific "up to 27" assertion. 6 new cross-stack test assertions.

### Files modified
- `skills/analyze-bug/SKILL.md` (UNCLEAR handler)
- `skills/fix-bugs/SKILL.md` (UNCLEAR path explicit)
- `agents/scaffolder.md` (cross-stack Playwright)
- `tests/scenarios/scaffolder-e2e-batch.sh` (grep fixes + new assertions)
- `CHANGELOG.md` (v6.3.1 entry)
- `.claude-plugin/plugin.json` (version bump)
- `.claude-plugin/marketplace.json` (version bump)
- `docs/plans/roadmap.md` (version + status update)

### Test results
- All {N} scenarios passed
- No regressions

### Version
- 6.3.0 → 6.3.1 (PATCH)
- Tag: v6.3.1
```

## Success Criteria
{{SUCCESS_CRITERIA}}:
- Content commit created with correct message
- Version bump commit created separately
- Git tag v6.3.1 created
- All tests pass in final verification
- Roadmap updated (item moved to DONE)
- Handoff summary produced

## Anti-Patterns
{{ANTI_PATTERNS}}:
- Do NOT amend previous commits
- Do NOT push to remote (user will push when ready)
- Do NOT skip the final test run
- Do NOT combine content and version bump into one commit
- Do NOT forget to update roadmap.md
- Do NOT create the tag before the version bump commit

## Codebase Context
{{CODEBASE_CONTEXT}}:
- Commit convention: (1) content + changelog, (2) version-bump, (3) tag
- Never commit `.claude/settings.local.json`
- Always run tests before committing
- Version files: `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`
- Roadmap: `docs/plans/roadmap.md`
