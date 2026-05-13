# Phase 7 — Execute

You are implementing the two bug fixes in `skills/scaffold/SKILL.md`. Follow the plan from Phase 6 exactly.

## Pre-implementation Checklist

1. Read `skills/scaffold/SKILL.md` fully (it's large — read in chunks)
2. Read `docs/reference/trackers.md` for state transition syntax
3. Read existing test files in `tests/scenarios/` to understand the test format
4. Verify you understand the current Step 4e (lines ~508-538) and Step 7 (lines ~615-680)

## Implementation Instructions

### Change 1: Expand Step 4e — Story Sub-Issue Creation

**File:** `C:/gitea_ceos-agents/skills/scaffold/SKILL.md`

**Find** the current Step 4e content (specifically the inner loop item 1c):

```markdown
     c. For each user story within the epic: create a sub-issue under the epic issue.
     d. Write the created issue ID back into the spec file as a reference comment.
     e. Track the result: success or failure for this epic.
```

**Replace with** expanded sub-steps:

```markdown
     c. Parse user stories from the epic file:
        - Stories are identified by `### Story` headings (e.g., `### Story 1.1: Initialize Vite Project`)
        - Each story's content spans from its heading to the next `### Story` heading, the next top-level `---` separator, or end of file
     d. For each parsed user story:
        i.   Extract story title: text after `### Story N.M: ` prefix (e.g., `Initialize Vite + React + TypeScript Project`)
        ii.  Extract story description: full markdown content from the story heading through its acceptance criteria section
        iii. Create a sub-issue (subtask) under the epic issue via MCP:
             - Title: `Story N.M: {story title}`
             - Description: story markdown content (including acceptance criteria)
             - Parent: the epic issue ID created in step (a)
             - If the tracker does not support native sub-issues/subtasks: create a regular issue and reference the parent epic in the description (e.g., `Parent epic: {epic issue ID}`)
        iv.  On sub-issue creation success: write the tracker issue ID into the spec file as a comment on the line immediately after the `### Story` heading: `<!-- {TrackerType}: {ISSUE-ID} -->`
        v.   On sub-issue creation failure: log `WARN: Could not create sub-issue for {story title} in {epic filename}: {error}`. Continue to next story.
     e. Write the epic-level issue ID back into the spec file as a reference comment after the epic title heading.
     f. Track the result: success or failure counts for this epic (both epic-level and story-level).
```

**Also update** the partial failure summary text (item 2) to include story counts:

Change:
```
   - Display result: `Created {N}/{M} tracker issues. {remaining text if N < M}`
```
To:
```
   - Display result: `Created {N}/{M} epic issues with {S}/{T} story sub-issues. {remaining text if N < M or S < T}`
   - If S < T: `Some story sub-issues could not be created. They can be created manually in the tracker.`
```

### Change 2: Add Step 7e — Transition Tracker Issues to Done

**File:** `C:/gitea_ceos-agents/skills/scaffold/SKILL.md`

**Find** the section header `### Step 7b: Spec Compliance Check` and insert a new step BEFORE it:

```markdown
### Step 7e: Transition Tracker Issues

**Required in-memory values from Step 0-INFRA:** `tracker_type`, `tracker_effective_status`.

**Guard clause — skip this step if ANY of:**
- `tracker_effective_status` is NOT `"ready"`
- No tracker issues were created in Step 4e (no issue ID back-references in `spec/epics/` files)

If none of the guard conditions apply, proceed:

1. **Read tracker issue IDs from spec files:**
   - Parse all `<!-- {TrackerType}: {ISSUE-ID} -->` comments from `spec/epics/*.md`
   - Categorize each ID as epic-level (appears after `# Epic` heading) or story-level (appears after `### Story` heading)

2. **Determine implementation status per story:**
   - Cross-reference story issues with the implementation results from Step 7
   - Stories whose corresponding subtasks completed successfully → mark as "implemented"
   - Stories whose subtasks were blocked, skipped, or not attempted → mark as "not implemented"

3. **Transition implemented stories to Done:**
   - For each "implemented" story issue: apply the Done state transition via MCP
   - Use the State Transition Syntax from `docs/reference/trackers.md` (e.g., YouTrack: `State: Done`, GitHub: `close`, Gitea: `close`)
   - If Automation Config `State transitions` defines a Done/Closed transition, use it. Otherwise use the tracker default from `docs/reference/trackers.md`.
   - On failure: log `WARN: Could not transition story {ISSUE-ID} to Done: {error}`. Continue to next issue.

4. **Transition completed epics to Done:**
   - For each epic: check whether ALL its story sub-issues were transitioned to Done in step 3
   - If all stories are Done → transition the epic issue to Done via MCP
   - If some stories remain open (blocked/skipped/failed) → do NOT transition the epic. Log: `Epic {ISSUE-ID} not closed — {N}/{M} stories still open.`
   - On transition failure: log `WARN: Could not transition epic {ISSUE-ID} to Done: {error}`. Continue.

5. **Display summary:**
   ```
   Tracker issues updated: {stories_closed}/{stories_total} stories closed, {epics_closed}/{epics_total} epics closed.
   {if any not closed} Remaining issues can be closed manually or via /ceos-agents:implement-feature.
   ```
```

### Change 3: Update tests (if applicable)

Check `tests/scenarios/` for existing scaffold tests. Add scenarios from Phase 5 TDD output following the established format.

## Post-implementation Checklist

1. Run `./tests/harness/run-tests.sh` to verify all tests pass
2. Read the modified `skills/scaffold/SKILL.md` to verify:
   - Step 4e now has explicit story sub-issue creation
   - Step 7e exists and has proper guard clause
   - Step numbering is consistent (7e comes after 7, before 7b)
   - No orphaned references to old step numbers
3. Verify that the `--no-implement` legacy flow is NOT affected (it should not reference Step 7e)
4. Verify that Step 9 (Final Report) still works logically with the new step

## Constraints

- Do NOT modify any agent definitions (`agents/*.md`)
- Do NOT modify any core contracts (`core/*.md`)
- Do NOT modify `docs/reference/trackers.md`
- Keep changes within `skills/scaffold/SKILL.md` and optionally `tests/`
- Preserve the existing Step 4e guard clause exactly as-is
- Preserve the existing Step 4e accumulator pattern for epic failures
