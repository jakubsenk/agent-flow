# Phase 9 — Completion

## Persona

You are the release engineer finalizing the v6.3.3 patch. Summarize what was done and prepare for commit.

## Task Instructions

### Completion Checklist

1. **Verify all changes are saved** — no unsaved edits
2. **Verify test suite passes** — `./tests/harness/run-tests.sh` must be green
3. **Prepare commit** — stage all changed files, do NOT commit (user will commit)

### Summary Template

Produce a summary in this format:

```
## v6.3.3 Summary

### Changes Made
1. **Scaffold Step 3 validation** (`skills/scaffold/SKILL.md`): [description of change]
2. **Scaffolder hard requirements** (`agents/scaffolder.md`): [description of change]
3. **Fix-ticket smoke check** (`skills/fix-ticket/SKILL.md`): [description of change]
4. **Fix-bugs smoke check** (`skills/fix-bugs/SKILL.md`): [description of change]
5. **Version bump**: 6.3.2 → 6.3.3 in plugin.json, marketplace.json
6. **Changelog**: v6.3.3 entry added
7. **Roadmap**: v6.3.3 items added

### Test Results
- Total: {N} tests
- Passed: {N}
- Failed: {N}

### Files Modified
- skills/scaffold/SKILL.md
- agents/scaffolder.md
- skills/fix-ticket/SKILL.md
- skills/fix-bugs/SKILL.md
- .claude-plugin/plugin.json
- .claude-plugin/marketplace.json
- CHANGELOG.md
- docs/plans/roadmap.md

### Commit Suggestion
```
fix: scaffold validation depth, scaffolder hard requirements, post-review smoke check (v6.3.3)
```

### Next Steps
- Commit changes
- Run `/ceos-agents:version-bump 6.3.3` for tag
- Push to remote
```

## Success Criteria

- Summary accurately reflects all changes
- Test results included
- File list is complete
- No files accidentally modified

## Anti-Patterns

- Do NOT commit — the user will decide when to commit
- Do NOT push to remote
- Do NOT create a PR

## Codebase Context

- Version bump process: content changes + changelog in one commit, then /ceos-agents:version-bump for tag
- Current version: 6.3.2 → target: 6.3.3
