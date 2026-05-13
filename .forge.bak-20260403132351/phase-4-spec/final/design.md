# Design Document — Scaffold Pipeline Bugfixes

**Version:** 6.1.6 (PATCH)
**Date:** 2026-04-02
**Files affected:** 2 (`skills/scaffold/SKILL.md`, `agents/spec-writer.md`)
**Estimated change:** ~50-70 lines across 2 files

---

## Change 1: Story Sub-Issue Linking (REQ-1)

**File:** `skills/scaffold/SKILL.md`
**Location:** Step 4e, line 533 (the bullet starting with "If tracker supports native sub-issues")

### Current text (line 533-534)

```markdown
        - **If tracker supports native sub-issues** (YouTrack, Jira, Linear, Redmine — see Sub-Issue Capabilities in `docs/reference/trackers.md`): create sub-issue with parent set to epic issue ID using the tracker's native parent parameter
```

### Replacement text

```markdown
        - **If tracker supports native sub-issues** (YouTrack, Jira, Linear, Redmine): create sub-issue with parent set to epic issue ID using the tracker-specific parameter:

          | Tracker | Parent parameter(s) to pass |
          |---------|----------------------------|
          | YouTrack | `parent: {epic-issue-id}` |
          | Jira | `parent: {epic-issue-key}`, `issuetype: "Sub-task"` |
          | Linear | `parentId: {epic-issue-id}` |
          | Redmine | `parent_issue_id: {epic-issue-id}` |

        - **Verification (native sub-issue trackers only):** After creating each story sub-issue, read the created issue back from the tracker. Confirm that the parent field (parent/parentId/parent_issue_id) is set to the epic issue ID. If the parent is NOT set, log `WARN: Story {story-issue-id} parent not set to {epic-issue-id}. Manual linking may be required.` and continue to the next story.
```

### Rationale

The current instruction defers to `docs/reference/trackers.md` via cross-file reference. The LLM executing Step 4e may skip reading the reference doc, resulting in incorrect or missing parent parameter names. Inlining the table eliminates the cross-file dependency. The verification sub-step catches silent failures where the tracker accepted the create call but ignored the parent parameter.

The reference table in `docs/reference/trackers.md` remains unchanged -- it is the canonical reference used by other skills and documentation. The inline table in Step 4e is a duplicate for reliability purposes.

---

## Change 2: Explicit Story Closing (REQ-2)

**File:** `skills/scaffold/SKILL.md`
**Location:** Step 8b, lines 740-746 (the transition logic items 3a-3d and item 5)

### Current text (lines 740-746)

```markdown
3. For each fully-completed epic:
   a. Transition the epic issue to Done using `State transitions -> Done` syntax from Automation Config.
   b. For GitHub/Gitea (standalone story issues): also close each story issue individually. Read story IDs from back-reference comments within the epic file.
   c. For trackers with native sub-issues (YouTrack, Jira, Linear, Redmine): closing the parent epic typically cascades to children. Do NOT explicitly close story sub-issues.
   d. On failure: WARN (`Could not transition {issue_id} to Done: {error}`), continue to next.
4. For epics with blocked subtasks: skip. These remain open for manual triage.
5. Display: `Transitioned {N}/{M} tracker issues to Done. {skipped} skipped (blocked subtasks).`
```

### Replacement text

```markdown
3. For each fully-completed epic:
   a. Transition the epic issue to Done using `State transitions -> Done` syntax from Automation Config.
   b. Close each story sub-issue individually for ALL tracker types. Read story IDs from back-reference comments (`<!-- {TrackerType}: {STORY-ID} -->`) within the epic file. Transition each story issue to Done using the same `State transitions -> Done` syntax.
   c. If a story issue is already in the target Done state, treat it as success — do not emit a warning or error.
   d. On failure (epic or story transition): WARN (`Could not transition {issue_id} to Done: {error}`), continue to next.
4. For epics with blocked subtasks: skip. These remain open for manual triage.
5. Display: `Transitioned {N}/{M} epic issues and {S} story issues to Done. {skipped} epics skipped (blocked subtasks).`
```

### Rationale

The current code assumes that closing a parent epic in YouTrack/Jira/Linear/Redmine cascades to children. This is factually incorrect -- cascade-close requires explicit workflow rules configured by project admins and is not a default in any of these trackers. The fix removes the tracker-type branching and always closes stories explicitly. The idempotency guard (item 3c) handles cases where a tracker DOES have cascade rules configured -- the story will already be Done, which is treated as success.

---

## Change 3: Implementation Comments (REQ-3)

**File:** `skills/scaffold/SKILL.md`
**Location:** Between Step 8 (E2E Tests, ending at line 724) and Step 8b (Close Tracker Issues, starting at line 726)

### Insertion: New Step 8a

Insert the following section after line 724 (`If no E2E Test section -> skip.`) and before line 726 (`### Step 8b: Close Tracker Issues`):

```markdown
### Step 8a: Post Implementation Comments

**Guard clause -- skip this step if ANY of:**
- `tracker_effective_status` is NOT `"ready"`
- `tracker_write_available` is `false`
- No tracker issues were created at Step 4e (no back-reference comments `<!-- {TrackerType}: ... -->` found in `spec/epics/*.md`)

If none of the guard conditions apply, proceed:

1. Read all `spec/epics/*.md` files. Extract epic issue IDs from back-reference comments.
2. Determine which epics are fully completed (same logic as Step 8b: an epic is complete if NONE of its subtasks appear in the blocked features list).
3. For each fully-completed epic, post a comment to the epic tracker issue:

   ```
   [ceos-agents] Scaffold implementation completed.
   Features: {comma-separated list of implemented subtask titles for this epic}
   Branch: {current branch name}
   Stories: {N} implemented, {B} blocked
   ```

4. Track the count of successfully posted comments.
5. On individual comment failure: log `WARN: Could not post implementation comment to {issue-id}: {error}`, continue to next epic. Never block.
6. Display: `Posted implementation comments to {C}/{E} epic issues.`
```

### Step 9 update

In Step 9 (Final Report), add a line to the Tracker section within the `{if tracker_effective_status == "ready"}` block. After the existing `{N} epics created{if step_8b_ran}, {C} issues closed{/if}` text, extend the conditional:

**Current (line 765):**
```
  Tracker: Connected ({tracker_type} @ {tracker_instance} — {tracker_project}, {N} epics created{if step_8b_ran}, {C} issues closed{/if})
```

**Replacement:**
```
  Tracker: Connected ({tracker_type} @ {tracker_instance} — {tracker_project}, {N} epics created{if step_8a_ran}, {P} comments posted{/if}{if step_8b_ran}, {C} issues closed{/if})
```

### Rationale

After scaffold completes, tracker issues have no activity trail -- no implementation evidence, no PR links, no summary of work done. Developers browsing YouTrack/Jira see bare issues with no context. The implementation comment provides an audit trail. Comments are per-epic (not per-story) to minimize noise, following the skeptic's recommendation from the brainstorm. The `[ceos-agents]` prefix enables machine-parseable detection by `/dashboard` and `/metrics`.

---

## Change 4: Language Fidelity (REQ-4)

### Change 4a: spec-writer constraint

**File:** `agents/spec-writer.md`
**Location:** Constraints section (after line 95, before the closing of the file)

Insert the following as a new bullet after the last constraint (line 95: `Block comments go to stdout when no tracker is configured.`):

```markdown
- NEVER transliterate, remove, or replace diacritics or non-ASCII characters from user-provided content -- preserve Czech, Slovak, German, and all other Unicode characters exactly as provided in project descriptions, epic titles, story titles, and acceptance criteria
```

### Change 4b: Step 4e language fidelity instruction

**File:** `skills/scaffold/SKILL.md`
**Location:** Step 4e, after the story creation instructions (after line 536: `If epic has zero stories...`)

Insert a new instruction item before item 1.d (`Track the result`):

```markdown
   e. **Language fidelity:** Preserve all diacritics and non-ASCII characters from spec content when creating issue titles and descriptions. Do not transliterate or ASCII-fold characters (e.g., keep "Spravce uzivatelskych uctu" exactly as written in the spec, including any diacritics present in the original).
```

This means the current item `d. Track the result` becomes item `f.`

### Rationale

The LLM may strip or transliterate diacritics when passing text through tool calls, especially for Czech/Slovak project descriptions. An explicit constraint in the spec-writer prevents mangling during spec generation, and the Step 4e instruction prevents mangling when creating tracker issues from spec content.

---

## File Change Summary

| File | Section | Action | Lines affected (approx) |
|------|---------|--------|------------------------|
| `skills/scaffold/SKILL.md` | Step 4e (line 533) | Replace 1 line with inline table + verification sub-step | +12, -1 |
| `skills/scaffold/SKILL.md` | Step 4e (after line 536) | Insert language fidelity instruction | +1 |
| `skills/scaffold/SKILL.md` | Step 8a (after line 724) | Insert entire new section | +22 |
| `skills/scaffold/SKILL.md` | Step 8b (lines 740-746) | Replace 6 lines with unified close logic | +6, -6 |
| `skills/scaffold/SKILL.md` | Step 9 (line 765) | Update tracker display line | +1, -1 |
| `agents/spec-writer.md` | Constraints (after line 95) | Insert 1 new NEVER constraint | +1 |

**Total estimated:** +43 lines, -8 lines = net +35 lines across 2 files.

---

## Dependencies Between Changes

The four changes are independent and can be implemented in any order. However, the recommended implementation order is:

1. **REQ-2** (Story Closing) -- highest impact, simplest change
2. **REQ-1** (Story Linking) -- same file area as REQ-2
3. **REQ-3** (Implementation Comments) -- new section, no conflicts
4. **REQ-4** (Language Fidelity) -- touches both files, no conflicts

REQ-3 (Step 8a) and REQ-2 (Step 8b) are adjacent sections but do not interact -- Step 8a posts comments, Step 8b closes issues. Step 8a runs first so that comments are posted before closure (some trackers may restrict comments on closed issues).
