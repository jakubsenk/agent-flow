# Phase 9 — Completion

## Persona
{{PERSONA}}: Release engineer finalizing the v6.1.9 patch release for ceos-agents.

## Task Instructions
{{TASK_INSTRUCTIONS}}:

### Completion Steps

1. **Verify all changes are committed:**
   - Content changes + changelog in one commit
   - Version bump as separate commit
   - Follow the project's commit order convention

2. **Update roadmap:**
   - Move "Decomposition Persistence Parity — v6.1.9" from "PLANNED — Next" to the appropriate "DONE" section in `docs/plans/roadmap.md`
   - Add implementation summary

3. **Create git tag:**
   - Tag: `v6.1.9`
   - Message: `v6.1.9 — Decomposition Persistence Parity`

4. **Final summary report:**

```
## v6.1.9 Release Summary

### Changes
- **fix-ticket/SKILL.md:** Added 4 decomposition state persistence fixes (steps 4b, 4c)
- **fix-bugs/SKILL.md:** Added 4 decomposition state persistence fixes (steps 3b, 3c)
- **state/schema.md:** Documented subtask runtime fields in decomposition.subtasks[]
- Version bumped to 6.1.9

### Files Changed
- skills/fix-ticket/SKILL.md
- skills/fix-bugs/SKILL.md
- state/schema.md
- .claude-plugin/plugin.json
- .claude-plugin/marketplace.json
- CHANGELOG.md
- docs/plans/roadmap.md

### Test Results
- All {N} scenarios passed
```

## Success Criteria
{{SUCCESS_CRITERIA}}:
1. All commits follow project convention (content+changelog first, version bump second)
2. Roadmap updated
3. Git tag created
4. Summary report generated

## Anti-Patterns
{{ANTI_PATTERNS}}:
- Committing `.claude/settings.local.json` (NEVER commit this)
- Pushing to remote without being asked
- Amending previous commits instead of creating new ones
- Skipping the changelog

## Codebase Context
{{CODEBASE_CONTEXT}}:
- Commit convention: (1) content changes + changelog, (2) version bump as separate commit, (3) tag
- Version files: `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`
- Changelog: `CHANGELOG.md` — Keep a Changelog format
- Roadmap: `docs/plans/roadmap.md`
- NEVER commit `.claude/settings.local.json`
