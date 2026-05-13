# Phase 4 Specification: Formal Verification Criteria

**Date:** 2026-04-02

---

## 1. Grep-Based Test Assertions

All assertions target the file indicated. Each must return a match (exit code 0) for the implementation to be considered correct.

### 1.1 SKILL.md — Step 4e Story Parsing

| # | Pattern | File | Purpose |
|---|---------|------|---------|
| G-01 | `Story N.M:` | `skills/scaffold/SKILL.md` | Story heading pattern documented |
| G-02 | `STORY-ISSUE-ID` | `skills/scaffold/SKILL.md` | Story back-reference format specified |
| G-03 | `Idempotency guard` | `skills/scaffold/SKILL.md` | Idempotency check present |
| G-04 | `supports native sub-issues` | `skills/scaffold/SKILL.md` | Tracker branching logic present |
| G-05 | `Sub-Issue Capabilities` | `skills/scaffold/SKILL.md` | Reference to trackers.md table |
| G-06 | `\[{epic_title}\]` | `skills/scaffold/SKILL.md` | GitHub/Gitea fallback title format |
| G-07 | `story failures` | `skills/scaffold/SKILL.md` | Updated display message with story counts |
| G-08 | `Split content on` | `skills/scaffold/SKILL.md` | Parsing instruction (delimiter-based) |
| G-09 | `zero stories` | `skills/scaffold/SKILL.md` | Zero-story edge case handled |
| G-10 | `cross-reference to epic issue` | `skills/scaffold/SKILL.md` | Fallback cross-reference documented |

### 1.2 SKILL.md — Step 8b Close Tracker Issues

| # | Pattern | File | Purpose |
|---|---------|------|---------|
| G-11 | `Step 8b: Close Tracker Issues` | `skills/scaffold/SKILL.md` | Step 8b section heading exists |
| G-12 | `does not include a 'Done' mapping` | `skills/scaffold/SKILL.md` | WARN message for missing Done |
| G-13 | `blocked features list` | `skills/scaffold/SKILL.md` | Per-epic completion check |
| G-14 | `Transitioned.*tracker issues to Done` | `skills/scaffold/SKILL.md` | Display message format |
| G-15 | `skipped (blocked subtasks)` | `skills/scaffold/SKILL.md` | Skipped epics reported |
| G-16 | `Could not transition` | `skills/scaffold/SKILL.md` | Per-issue failure WARN message |
| G-17 | `Do NOT explicitly close story sub-issues` | `skills/scaffold/SKILL.md` | Cascade-aware behavior |

### 1.3 SKILL.md — Step 9 Final Report Update

| # | Pattern | File | Purpose |
|---|---------|------|---------|
| G-18 | `issues closed` | `skills/scaffold/SKILL.md` | Closed-issues count in report |

### 1.4 SKILL.md — Ordering (Line-Number Checks)

| # | Assertion | Purpose |
|---|-----------|---------|
| G-19 | Line number of `Step 8b: Close Tracker Issues` > line number of `Step 8: E2E Tests` | Step 8b after Step 8 |
| G-20 | Line number of `Step 8b: Close Tracker Issues` < line number of `Step 9: Final Report` | Step 8b before Step 9 |

### 1.5 trackers.md — Sub-Issue Capabilities

| # | Pattern | File | Purpose |
|---|---------|------|---------|
| G-21 | `Sub-Issue Capabilities` | `docs/reference/trackers.md` | Section heading exists |
| G-22 | `Native sub-issues` | `docs/reference/trackers.md` | Column header present |
| G-23 | `parent_issue_id` | `docs/reference/trackers.md` | Redmine parameter documented |
| G-24 | `parentId` | `docs/reference/trackers.md` | Linear parameter documented |
| G-25 | `Standalone issue` | `docs/reference/trackers.md` | Fallback strategy documented |

### 1.6 Example Configs — Done Mapping

| # | Pattern | File | Purpose |
|---|---------|------|---------|
| G-26 | `Done:.*close` | `examples/configs/github-dotnet.md` | GitHub Done = close |
| G-27 | `Done:.*close` | `examples/configs/github-python-fastapi.md` | GitHub Done = close |
| G-28 | `Done:.*close` | `examples/configs/github-nextjs.md` | GitHub Done = close |
| G-29 | `Done:.*close` | `examples/configs/gitea-spring-boot.md` | Gitea Done = close |
| G-30 | `Done:.*transition:Done` | `examples/configs/jira-react.md` | Jira Done = transition:Done |
| G-31 | `Done:.*State: Done` | `examples/configs/youtrack-python.md` | YouTrack Done = State: Done |
| G-32 | `Done:.*status:Closed` | `examples/configs/redmine-rails.md` | Redmine Done = status:Closed (pre-existing) |

---

## 2. Edge Case Checklist

### 2.1 Zero Stories in Epic

| Case | Expected Behavior | Verification |
|------|-------------------|--------------|
| Epic file has `# Epic 01: Title` but no `### Story` headings | Epic-level issue created; story iteration skipped; no story back-references written | G-09 confirms "zero stories" text exists in SKILL.md |
| Epic file has `# Epic 01: Title` and one `---` but no story heading | Same as above — no `### Story` match found | Parsing logic splits on delimiter and matches heading pattern |

### 2.2 Tracker Unavailable at Step 4e

| Case | Expected Behavior | Verification |
|------|-------------------|--------------|
| `tracker_effective_status = "later"` | Step 4e skipped entirely (guard clause) | AC-7.1 |
| `tracker_effective_status = "downgraded"` | Step 4e skipped entirely (guard clause — NOT "ready") | AC-7.1 |
| `tracker_write_available = false` | Step 4e skipped entirely (guard clause) | Existing guard preserved |
| MCP tool fails mid-iteration (3rd of 5 epics) | WARN logged, continue to 4th epic; commit partial links | AC-1.4 |

### 2.3 Tracker Unavailable at Step 8b

| Case | Expected Behavior | Verification |
|------|-------------------|--------------|
| `tracker_effective_status = "later"` | Step 8b skipped entirely | AC-4.2 |
| `tracker_write_available = false` | Step 8b skipped entirely | AC-4.2 |
| No back-reference comments in spec/epics/ | Step 8b skipped (no issues to close) | AC-4.2 |
| `State transitions` has no `Done` mapping | WARN displayed, Step 8b skipped | AC-4.3, G-12 |
| MCP fails for 1 of 4 epic transitions | WARN logged, continue to next; final count is 3/4 | AC-4.6, G-16 |

### 2.4 Partial Failure / Resume

| Case | Expected Behavior | Verification |
|------|-------------------|--------------|
| Run 1: 3/5 epics created, then crash | 3 epic files have back-references, 2 do not | Back-references committed to git at step 4e.2 |
| Run 2: resume scaffold | Idempotency guard detects 3 existing back-references, skips them, creates remaining 2 | AC-3.1, AC-3.3 |
| Run 1: epic created, 2/4 stories created, then crash | Epic has back-ref, 2 stories have back-refs, 2 do not | Back-references committed together |
| Run 2: resume | Epic skipped (idempotent), 2 stories skipped (idempotent), 2 stories created | AC-3.2 |
| Step 8b resumes after partial Done transition | No idempotency guard needed — transitioning an already-Done issue is a no-op in all trackers | By tracker semantics |

### 2.5 GitHub/Gitea Specific

| Case | Expected Behavior | Verification |
|------|-------------------|--------------|
| GitHub tracker, epic with 3 stories | 1 epic issue + 3 standalone issues with `[{epic_title}]` prefix | AC-2.2, G-06 |
| GitHub tracker, Step 8b | Close epic issue AND close all 3 story issues individually | AC-4.5 |
| Gitea tracker, same scenario | Same behavior as GitHub | AC-2.1 |

### 2.6 Native Sub-Issue Trackers

| Case | Expected Behavior | Verification |
|------|-------------------|--------------|
| YouTrack, epic with 3 stories | 1 epic issue + 3 sub-issues with `parent: {epic-id}` | AC-2.1, AC-2.2 via branching |
| YouTrack, Step 8b | Close only epic issue; sub-issues cascade | AC-4.5, G-17 |
| Jira, Redmine, Linear | Same parent-link behavior with respective parameter names | AC-5.3 |

---

## 3. Backward Compatibility Verification

These assertions verify that existing behavior is NOT broken by the changes.

### 3.1 Must NOT Change

| # | Assertion | Verification Method |
|---|-----------|-------------------|
| BC-1 | `--no-implement` legacy flow (L1-L6) is unmodified | Grep: no `Step 4e` or `Step 8b` reference appears between `--no-implement Legacy Flow` and `---` separator ending that section |
| BC-2 | Step 4e guard clauses are preserved | Grep: `tracker_effective_status is NOT "ready"`, `tracker_write_available is false`, `spec/epics/ directory does not exist` all present |
| BC-3 | `On start set` NOT applied in Step 4e | Grep: `Do NOT apply the .On start set.` present in Step 4e |
| BC-4 | Commit message format unchanged | Grep: `chore: link spec epics to tracker issues` present |
| BC-5 | Step 9 report structure unchanged (only tracker line modified) | Grep: `## Scaffold Complete`, `### Infrastructure`, `### Implementation`, `### Next steps:` all present |
| BC-6 | `redmine-rails.md` State transitions row unchanged | Grep: `Done: .status:Closed.` still present (was pre-existing) |
| BC-7 | No new required key in Automation Config | No mention of new required config key in SKILL.md changes |

### 3.2 Must NOT Appear

| # | Negative Assertion | Purpose |
|---|-------------------|---------|
| BC-8 | `Step 7e` must NOT appear in SKILL.md | Phase 0 proposed Step 7e; brainstorm moved it to Step 8b |
| BC-9 | `On complete` must NOT appear in SKILL.md as a config key | No new config key — "Done" is read from existing State transitions |
| BC-10 | `tracker_issues` must NOT appear as a state.json field | No state.json persistence of issue IDs (out of scope) |
| BC-11 | `core/sub-issue-creator.md` must NOT be created | No new core contract (single consumer) |

---

## 4. Test Execution Checklist

Before merge, the implementation must pass:

1. **Existing test suite:** `./tests/harness/run-tests.sh` — all 39+ existing tests pass
2. **New assertions in `scaffold-v2-happy-path.sh`:** All 17 new grep assertions pass (G-01 through G-18 content + G-19/G-20 ordering)
3. **trackers.md assertions:** G-21 through G-25 pass
4. **Example config assertions:** G-26 through G-32 pass
5. **Negative assertions:** BC-8 through BC-11 verified manually (no automated test needed — these are implementation guardrails)
6. **Manual review:** Step 4e expanded text reads naturally and is actionable by an LLM executing the skill
7. **Manual review:** Step 8b guard clauses cover all four skip conditions from AC-4.2
