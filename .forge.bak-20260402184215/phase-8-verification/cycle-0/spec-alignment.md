# Spec Alignment Review

**Spec:** `.forge/phase-4-spec/final/requirements.md` (8 requirements, 36 ACs)
**Test suite:** `tests/scenarios/scaffold-tracker-integration.sh` -- ALL PASS (32 assertions + regression guards)
**Date:** 2026-04-02

## Per-AC Verification

| AC | Status | Evidence |
|----|--------|----------|
| AC-1.1 | PASS | Step 4e line 526-531: Parses `### Story N.M:` headings, splits on `\n---\n` delimiter, extracts title after `### Story N.M: ` and description from content to next `---`. |
| AC-1.2 | PASS | Step 4e line 533: Native sub-issue branch for YouTrack, Jira, Linear, Redmine with parent parameter; references `Sub-Issue Capabilities in docs/reference/trackers.md`. |
| AC-1.3 | PASS | Step 4e line 535: `<!-- {TrackerType}: {STORY-ISSUE-ID} -->` written immediately after `### Story N.M:` heading. |
| AC-1.4 | PASS | Step 4e line 541: WARN logged per-story failure (`Could not create story sub-issue for {story title} in {epic filename}: {error}`), continues to next story. Epic considered succeeded if epic-level issue created. |
| AC-1.5 | PASS | Step 4e line 536: "If epic has zero stories (no `### Story` headings found): skip story iteration -- epic-only issue is sufficient." |
| AC-1.6 | PASS | Step 4e line 548: `Created {N}/{M} tracker issues ({S} stories, {F} story failures).` and line 552 for zero-failure variant `Created {M}/{M} tracker issues ({S} stories).` |
| AC-2.1 | PASS | Step 4e lines 533-534: Single IF/ELSE branch -- "If tracker supports native sub-issues" (YouTrack, Jira, Linear, Redmine) vs. "If tracker does NOT support native sub-issues" (GitHub, Gitea). |
| AC-2.2 | PASS | Step 4e line 534: GitHub/Gitea fallback title `[{epic_title}] {story_title}`. |
| AC-2.3 | PASS | Step 4e line 534: "add cross-reference to epic issue in description". |
| AC-2.4 | PASS | Step 4e line 533: Explicit reference "see Sub-Issue Capabilities in `docs/reference/trackers.md`". |
| AC-3.1 | PASS | Step 4e line 522: Epic idempotency guard checks for `<!-- {TrackerType}: ... -->` after `# Epic NN:` heading; extracts existing ID for parent linking; skips to step 1.c. |
| AC-3.2 | PASS | Step 4e line 532: Story idempotency guard checks for back-reference on next line after heading; skips creation if present. |
| AC-3.3 | PASS | AC-3.1 extracts existing IDs for parent use + AC-3.2 skips existing stories = partial resume continues only un-linked items. |
| AC-4.1 | PASS | Step 8b at line 726, between Step 8 (line 709) and Step 9 (line 748). Test G-19/G-20 confirm ordering. |
| AC-4.2 | PASS | Step 8b lines 728-731: Four guard clauses match spec exactly (tracker_effective_status, tracker_write_available, no back-references, no Done mapping). |
| AC-4.3 | PASS | Step 8b line 734: `WARN: State transitions does not include a 'Done' mapping. Skipping issue closure.` -- exact match. |
| AC-4.4 | PASS | Step 8b line 739: "an epic is complete if NONE of its subtasks (from architect decomposition) appear in the blocked features list". |
| AC-4.5 | PASS | Step 8b line 742: GitHub/Gitea close each story issue individually. Line 743: Native sub-issue trackers "Do NOT explicitly close story sub-issues" (cascade assumed). |
| AC-4.6 | PASS | Step 8b line 744: `WARN (Could not transition {issue_id} to Done: {error}), continue to next.` |
| AC-4.7 | PASS | Step 8b line 746: `Transitioned {N}/{M} tracker issues to Done. {skipped} skipped (blocked subtasks).` |
| AC-4.8 | PASS | Step 8b line 738: "Extract epic issue IDs from back-reference comments" in `spec/epics/*.md`. No state.json lookup. |
| AC-5.1 | PASS | `trackers.md` line 88: Table has 4 columns: Tracker, Native sub-issues, Parent parameter, Fallback strategy. |
| AC-5.2 | PASS | `trackers.md` lines 90-95: Six rows -- YouTrack, Jira, Linear, Redmine (Yes), GitHub, Gitea (No). |
| AC-5.3 | PASS | Parent parameters match exactly: YouTrack `parent: {issue-id}`, Jira `parent: {key}` + `issuetype: "Sub-task"`, Linear `parentId: {id}`, Redmine `parent_issue_id: {id}`, GitHub/Gitea N/A. |
| AC-5.4 | PASS | `trackers.md` lines 94-95: Fallback for GitHub/Gitea: `Standalone issue: [{epic_title}] {story_title}, cross-reference in description`. Others: N/A. |
| AC-5.5 | PASS | Section at line 87, after "MCP Server Detection" section (line 77). End of file placement confirmed. |
| AC-6.1 | PASS | All 6 configs verified: `github-dotnet.md` has `Done: \`close\`` (line 14), `github-python-fastapi.md` has `Done: \`close\`` (line 14), `github-nextjs.md` has `Done: \`close\`` (line 14), `gitea-spring-boot.md` has `Done: \`close\`` (line 14), `jira-react.md` has `Done: \`transition:Done\`` (line 14), `youtrack-python.md` has `Done: \`State: Done\`` (line 14). |
| AC-6.2 | PASS | `redmine-rails.md` line 14 retains `Done: \`status:Closed\`` unchanged. Test G-32 confirms. |
| AC-6.3 | PASS | Done mappings appended as comma-separated entries within existing State transitions value (same row, same format). |
| AC-7.1 | PASS | Step 4e guard clause (line 513): `tracker_effective_status` is NOT "ready" -> skip. Step 8b guard clause (line 729): same check. Both skip for "later"/"downgraded". |
| AC-7.2 | PASS | `--no-implement` legacy flow (lines 257-361) contains only L1-L6 steps. Does not reference Step 4e story sub-issues or Step 8b. |
| AC-7.3 | PASS | Step 4e.1.a (idempotency guard), 4e.1.b (epic creation), 4e.1.d (track result) all preserved. Story creation (4e.1.c) is additive. Regression tests confirm epic-level creation, accumulator pattern, and "Do NOT apply On start set". |
| AC-7.4 | PASS | Commit message `chore: link spec epics to tracker issues` preserved at line 546. Regression test confirms. |
| AC-7.5 | PASS | No new required or optional key added to Automation Config. "Done" is read from existing `State transitions` key. |
| AC-8.1 | PASS | Step 9 Final Report line 765: `{if step_8b_ran}, {C} issues closed{/if}` appended to tracker line within the Infrastructure section. |
| AC-8.2 | PASS | The `{if step_8b_ran}` conditional ensures closed count only appears when Step 8b executed. Otherwise tracker line uses existing format. |

## Score: 1.0 / 1.0

## Summary

All 36 acceptance criteria across 8 requirements are fully satisfied. The implementation in `skills/scaffold/SKILL.md` (Step 4e story sub-issues, Step 8b Done transition, Step 9 Final Report update) matches the specification exactly. Supporting artifacts -- `docs/reference/trackers.md` Sub-Issue Capabilities table and all 7 example configs -- are correctly updated. The test suite (`scaffold-tracker-integration.sh`) passes all 32+ assertions including regression guards. Backward compatibility is preserved: `--no-implement` flow is untouched, existing epic creation behavior is intact, commit messages are unchanged, and no Automation Config contract changes were introduced.
