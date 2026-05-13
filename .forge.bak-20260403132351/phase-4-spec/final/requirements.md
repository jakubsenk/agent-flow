# Requirements Specification — Scaffold Pipeline Bugfixes

**Version:** 6.1.6 (PATCH)
**Date:** 2026-04-02
**Scope:** 4 fixes to the scaffold pipeline in `skills/scaffold/SKILL.md` and `agents/spec-writer.md`
**Issue #1 (Design Quality):** DEFERRED — not in scope.

---

## REQ-1: Story Sub-Issue Linking (Issue #2)

**EARS format:**

WHEN Step 4e creates story sub-issues for trackers with native sub-issue support (YouTrack, Jira, Linear, Redmine), the skill SHALL inline the tracker-specific parent parameter name and value directly in the instruction text, rather than deferring to a cross-file reference in `docs/reference/trackers.md`.

WHEN Step 4e creates a story sub-issue, the skill SHALL verify the created issue by reading it back and confirming the parent field is set to the expected epic issue ID.

IF the verification read-back shows the parent is NOT set, the skill SHALL log a WARN and continue (not block).

### Acceptance Criteria

| ID | Criterion | Type |
|----|-----------|------|
| AC-1.1 | Step 4e instruction for native sub-issue trackers includes an inline table mapping each tracker type to its exact parent parameter name: YouTrack `parent`, Jira `parent` + `issuetype: "Sub-task"`, Linear `parentId`, Redmine `parent_issue_id`. | Rule |
| AC-1.2 | Step 4e includes a verification sub-step: after creating each story sub-issue, read the created issue back and confirm the parent/parentId/parent_issue_id field matches the epic issue ID. | GWT: Given a story sub-issue was just created, When the skill reads back the created issue, Then it confirms the parent field matches the epic issue ID. |
| AC-1.3 | If verification fails (parent not set), the skill logs `WARN: Story {story-id} parent not set to {epic-id}. Manual linking may be required.` and continues to the next story. | GWT: Given a verification read-back shows no parent link, When the failure is detected, Then a WARN is logged and processing continues without blocking. |
| AC-1.4 | The cross-file reference to `docs/reference/trackers.md` is removed from the inline instruction (the reference doc remains unchanged). | Rule |

---

## REQ-2: Explicit Story Closing (Issue #3)

**EARS format:**

WHEN Step 8b closes tracker issues for fully-completed epics, the skill SHALL explicitly close ALL story sub-issues for ALL tracker types, removing the assumption that closing a parent epic cascades to children.

IF a story issue is already in the target Done state, the skill SHALL treat it as success (no error, no warning).

### Acceptance Criteria

| ID | Criterion | Type |
|----|-----------|------|
| AC-2.1 | Step 8b removes the branching logic that differentiates GitHub/Gitea (explicit story close) from YouTrack/Jira/Linear/Redmine (assumed cascade). | Rule |
| AC-2.2 | Step 8b explicitly closes each story sub-issue for ALL tracker types (YouTrack, Jira, Linear, Redmine, GitHub, Gitea) by reading story IDs from back-reference comments in the epic file and transitioning each to Done. | GWT: Given an epic is fully completed, When the skill processes story closure, Then it reads all `<!-- {TrackerType}: {STORY-ID} -->` back-references from the epic file and transitions each story issue to Done. |
| AC-2.3 | If a story issue is already in the Done state, the transition is treated as success (no WARN, no error). | GWT: Given a story issue is already in Done state, When the skill attempts to transition it, Then no error or warning is emitted. |
| AC-2.4 | The phrase "closing the parent epic typically cascades to children" and the "Do NOT explicitly close story sub-issues" instruction are removed from Step 8b. | Rule |
| AC-2.5 | The summary display line is updated to include story closure count: `Transitioned {N}/{M} epic issues and {S} story issues to Done. {skipped} epics skipped (blocked subtasks).` | Rule |

---

## REQ-3: Implementation Comments (Issue #4)

**EARS format:**

WHEN the scaffold pipeline reaches the issue-closure phase (after E2E tests, before closing issues), the skill SHALL post a `[ceos-agents]` prefixed implementation summary comment to each fully-completed epic issue in the tracker.

The comment SHALL be posted per epic (NOT per story) to avoid comment noise.

IF posting a comment fails, the skill SHALL log a WARN and continue (never block).

### Acceptance Criteria

| ID | Criterion | Type |
|----|-----------|------|
| AC-3.1 | A new Step 8a is inserted between Step 8 (E2E Tests) and Step 8b (Close Tracker Issues). | Rule |
| AC-3.2 | Step 8a posts a comment to each fully-completed epic issue using the `[ceos-agents]` prefix. The comment format is: `[ceos-agents] Scaffold implementation completed.\nFeatures: {list of implemented subtask titles}\nBranch: {branch name}\nStories: {N} implemented, {B} blocked` | Rule |
| AC-3.3 | Comments are posted ONLY to epic-level issues, not to individual story issues. | Rule |
| AC-3.4 | If posting a comment fails, the skill logs `WARN: Could not post implementation comment to {issue-id}: {error}` and continues to Step 8b. | GWT: Given the tracker API rejects a comment post, When the failure is caught, Then a WARN is logged and the pipeline continues to Step 8b without blocking. |
| AC-3.5 | Step 8a has a guard clause matching Step 8b's guards: skip if `tracker_effective_status` is not `"ready"`, `tracker_write_available` is `false`, or no back-reference comments exist. | Rule |
| AC-3.6 | The Final Report (Step 9) display reflects whether implementation comments were posted (count of comments posted). | Rule |

---

## REQ-4: Language Fidelity (Issue #5)

**EARS format:**

WHEN the spec-writer agent generates specification content, it SHALL preserve all diacritics and non-ASCII characters from user input exactly as provided, without transliteration or removal.

WHEN Step 4e creates tracker issues from spec content, the skill SHALL instruct the LLM to preserve all diacritics and non-ASCII characters in issue titles and descriptions.

### Acceptance Criteria

| ID | Criterion | Type |
|----|-----------|------|
| AC-4.1 | `agents/spec-writer.md` Constraints section includes a new NEVER rule: "NEVER transliterate, remove, or replace diacritics or non-ASCII characters from user-provided content -- preserve Czech, Slovak, German, and all other Unicode characters exactly as provided in project descriptions, epic titles, story titles, and acceptance criteria." | Rule |
| AC-4.2 | Step 4e in `skills/scaffold/SKILL.md` includes an explicit language fidelity instruction: "Preserve all diacritics and non-ASCII characters from spec content when creating issue titles and descriptions. Do not transliterate or ASCII-fold characters." | Rule |
| AC-4.3 | The spec-writer constraint is placed in the existing Constraints section, maintaining the NEVER-prefix convention used by all other constraints in that section. | Rule |

---

## Traceability Matrix

| Requirement | Files Modified | Backwards Compatible | Version Impact |
|-------------|---------------|---------------------|----------------|
| REQ-1 | `skills/scaffold/SKILL.md` (Step 4e) | Yes | PATCH |
| REQ-2 | `skills/scaffold/SKILL.md` (Step 8b) | Yes | PATCH |
| REQ-3 | `skills/scaffold/SKILL.md` (new Step 8a) | Yes | PATCH |
| REQ-4 | `agents/spec-writer.md`, `skills/scaffold/SKILL.md` (Step 4e) | Yes | PATCH |

**Overall version impact:** PATCH (no new required config keys, no breaking changes to agent output contracts).
