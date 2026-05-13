# Phase 9 — Completion

You are finalizing the bug fix for the scaffold skill's tracker integration.

## Completion Checklist

### Code Quality
- [ ] `skills/scaffold/SKILL.md` changes are clean and well-formatted
- [ ] No TODO markers left in the changes (unless intentional)
- [ ] Step numbering is consistent throughout the file
- [ ] All cross-references to other steps are correct

### Test Results
- [ ] `./tests/harness/run-tests.sh` passes with 0 failures
- [ ] No new warnings introduced

### Documentation
- [ ] No documentation changes needed (this is a bugfix, not a new feature)
- [ ] CHANGELOG.md entry is NOT needed yet (will be added at version bump time)

### Version Impact Assessment
- **Level:** PATCH (behavioral fix without contract change)
- **Reason:** This fixes existing behavior that was already documented in Step 4e ("create a sub-issue") and adds a missing pipeline step. No new required config keys, no new agent output formats, no breaking changes.
- **Current version:** Check `plugin.json` for current version
- **Next version:** Current patch + 1

### Summary for User

Write a concise summary of what was fixed:

```
## Scaffold Skill Bug Fix

### Problem 1: Stories not created as sub-issues
Step 4e (Create Tracker Issues) instructed "create a sub-issue under the epic issue" 
but lacked specific parsing and creation guidance. The LLM would include story text 
in the epic description instead of creating separate tracker issues.

**Fix:** Expanded Step 4e with detailed sub-steps for parsing `### Story` headings, 
extracting story content, creating tracker sub-issues with proper titles and descriptions, 
and writing per-story back-references into spec files.

### Problem 2: Epics not closed after implementation
The scaffold pipeline had no step to transition tracker issues to "Done" after 
implementation. Unlike fix-ticket and implement-feature (which use the publisher agent), 
scaffold commits directly without a publisher step.

**Fix:** Added Step 7e (Transition Tracker Issues) between the implementation loop 
and spec compliance check. It reads issue IDs from spec file back-references, 
transitions implemented stories to Done, and closes epics only when all their stories 
are complete.

### Files Changed
- `skills/scaffold/SKILL.md` — Step 4e expanded, Step 7e added
```

### Commit Message Draft

```
fix: scaffold step 4e creates story sub-issues and step 7e closes tracker issues after implementation

Step 4e now explicitly parses ### Story headings from epic files and creates
sub-issues in the tracker for each story, with per-story back-references.

New Step 7e transitions implemented story and epic issues to Done state
after the feature implementation loop completes.

Fixes: stories were only written into epic descriptions (not created as
separate tracker issues), and issues were never closed after implementation.
```
