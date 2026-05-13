# Correctness Review

## Checks

| # | Check | Status | Detail |
|---|-------|--------|--------|
| 1 | Internal consistency (4e ↔ 8b cross-reference) | PASS | Step 8b line 731 explicitly references "issues created at Step 4e" and matches back-reference detection (`<!-- {TrackerType}: ... -->` in `spec/epics/*.md`) used by Step 4e line 535 |
| 2 | Guard clause consistency | PASS | Both Step 4e (lines 512–515) and Step 8b (lines 728–732) use identical guard pairs: `tracker_effective_status` NOT "ready" AND `tracker_write_available` false. Step 8b adds one extra guard (no back-references found, missing Done mapping) which is appropriate — it is additive, not contradictory |
| 3 | Back-reference format consistency | PASS | Epic format `<!-- {TrackerType}: {EPIC-ISSUE-ID} -->` (line 524) and story format `<!-- {TrackerType}: {STORY-ISSUE-ID} -->` (line 535) are consistent. Step 8b reads both using the same pattern `<!-- {TrackerType}: {ID} -->` (line 738, 742) |
| 4 | Tracker branching logic alignment | PASS | Step 4e branches on "supports native sub-issues" (YouTrack/Jira/Linear/Redmine = native; GitHub/Gitea = standalone with `[{epic_title}]` prefix). Step 8b mirrors this: GitHub/Gitea explicitly closes story issues (line 742), native trackers rely on cascade (line 743). The split is symmetric |
| 5 | Test file bash syntax | PASS | `bash -n` reports zero errors. All variables (`STEP8_LINE`, `STEP8B_LINE`, `STEP9_LINE`) are properly quoted, `set -e` is at the top, exit `$FAIL` is correct |
| 6 | No regression in existing steps | PASS | Steps 0-INFRA through Step 9 are all present. Step 4e still creates epic-level issues (line 524), still has accumulator pattern (line 540), still has commit message "chore: link spec epics to tracker issues" (line 546), still has "Do NOT apply the `On start set`" (line 524). Step numbering: 0-INFRA, 0-MCP, 0, 0b, 1, 2, 3, 4, 4d, 4e, 5, 6, 7, 7b, 8, 8b, 9 — no gaps or duplicates |

## Additional Observations

- **G-18 mismatch (minor):** The test at line 134 greps for literal `'issues closed'`. SKILL.md line 765 contains `{C} issues closed` — the substring `issues closed` is present, so the grep matches correctly. No issue.
- **`step_8b_ran` variable:** Step 9's Final Report uses `{if step_8b_ran}` (line 765) as a conditional, but Step 8b itself never sets this variable explicitly. This is a minor gap — the implementation relies on the model inferring whether Step 8b ran from context. However, this is a behavioral/LLM convention, not a structural defect, and is outside the scope of what the test verifies.
- **Story failure count in display message:** Step 4e line 548 uses `{F} story failures` which satisfies test G-07. Step 4e line 552 (all-success path) omits the failure count, which is correct since F=0.
- **Unlabeled test assertions (lines 71–77):** Two assertions without G-NN labels — "per-story failure handling (WARN + continue)" and "story back-reference writeback format". Both are satisfied by SKILL.md lines 541 and 535 respectively. The missing labels are a test documentation gap, not a correctness issue.

## Score: 0.95 / 1.0

## Summary

The implementation is correct and internally consistent. Step 4e and Step 8b are symmetric and coherent: guard conditions match, back-reference formats align, tracker branching logic is properly mirrored. The trackers.md Sub-Issue Capabilities table is well-formed with all required columns and rows. The test script has valid bash syntax and all 32+ assertions map to real content in SKILL.md. Step numbering is intact with no gaps or duplicates. The 0.05 deduction is for the `step_8b_ran` variable not being explicitly set in Step 8b, leaving its definition implicit — a minor behavioral gap that does not affect functional correctness.
