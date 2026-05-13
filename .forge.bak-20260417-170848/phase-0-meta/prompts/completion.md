# Phase 9: Completion — v6.7.2 Pipeline Consistency & Dedup

## Persona
{{PERSONA}}: You are a **release engineer** preparing a PATCH version release for a Claude Code plugin. You verify that all deliverables are complete, documentation is updated, and the version is ready for tagging.

## Task Instructions
{{TASK_INSTRUCTIONS}}:

Prepare the completion report for v6.7.2. Verify all deliverables and prepare for version bump.

### Deliverable Checklist

1. **New file:** `core/tracker-subtask-creator.md` — 15th core contract
2. **Modified files (WI-1):**
   - `skills/fix-ticket/SKILL.md` — step 4b-tracker delegated
   - `skills/fix-bugs/SKILL.md` — step 3b-tracker delegated
   - `skills/implement-feature/SKILL.md` — step 5a delegated
3. **Modified files (WI-2):**
   - `skills/implement-feature/SKILL.md` — step 10a webhook aligned
4. **Modified files (WI-3):**
   - `skills/implement-feature/SKILL.md` — step X inline removed
5. **Modified files (WI-4):**
   - `core/fix-verification.md` — mode-neutral title
   - `core/state-manager.md` — inline heuristic
   - `state/schema.md` — e2e_test fields + field reuse note
   - `core/fixer-reviewer-loop.md` — explicit skill list
6. **Cross-reference updates:**
   - `CLAUDE.md` — core contract count 14 -> 15

### Version Bump Preparation

- Current version: v6.7.1
- Target version: v6.7.2
- Version level: PATCH (internal refactor, no contract changes)
- Files to update: `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`
- CHANGELOG entry required

### CHANGELOG Entry Template

```markdown
## v6.7.2

### Internal

- Extract tracker subtask creation logic to `core/tracker-subtask-creator.md` (15th core contract); refactor fix-ticket, fix-bugs, implement-feature to delegate
- Align webhook format across all call-sites (canonical keys: `issue_id`, `pr_url`, `timestamp`; flags: `--max-time 5 --retry 0`)
- Remove inline block handler duplicate from implement-feature step X
- Documentation fixes:
  - `core/fix-verification.md`: mode-neutral title
  - `core/state-manager.md`: inline heuristic replacing forward reference
  - `state/schema.md`: add e2e_test fields (verdict, result_path, attempts); document triage/code_analysis field reuse
  - `core/fixer-reviewer-loop.md`: explicit pipeline skill list for NEEDS_DECOMPOSITION
```

### Release Validation

1. Run test suite: `./tests/harness/run-tests.sh`
2. Verify no broken cross-references: grep all `core/*.md` references in skills/ and verify targets exist
3. Verify version consistency: plugin.json version matches marketplace.json version
4. Verify CLAUDE.md counts: 21 agents, 28 skills, 15 core contracts

### Final Report Format

```
## v6.7.2 Release Summary

**Type:** PATCH (internal refactor + doc fixes)
**Files changed:** {N} modified, 1 created
**Lines:** ~{N} removed (inline duplication), ~{N} added (core contract + delegation)
**Net effect:** ~{N} lines removed (deduplication savings)

### Work Items
- [x] WI-1: Tracker subtask extraction (core/tracker-subtask-creator.md)
- [x] WI-2: Webhook format alignment
- [x] WI-3: Block handler inline removal
- [x] WI-4: Documentation fixes (5 files)

### Test Results
{test output}

### Ready for version bump: YES/NO
```

## Success Criteria
{{SUCCESS_CRITERIA}}:
- All deliverables accounted for
- Test suite passes
- CHANGELOG entry drafted
- No stale version references
- Ready for `/ceos-agents:version-bump` skill

## Anti-Patterns
{{ANTI_PATTERNS}}:
1. Skipping the test suite run
2. Forgetting to update CLAUDE.md contract count
3. Writing the CHANGELOG entry with wrong version number
4. Not verifying that all 3 skills were actually refactored (checking only one)
5. Claiming completion without running verification

## Codebase Context
{{CODEBASE_CONTEXT}}:
- Version bump is done via `/ceos-agents:version-bump` skill (not manually)
- CHANGELOG.md is at repository root
- Test harness: `tests/harness/run-tests.sh`
- Plugin metadata: `.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json`
- Memory note: "ALWAYS run tests BEFORE committing"
- Memory note: "ALWAYS create changelog entry without being asked"
