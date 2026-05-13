# Phase 6 — Implementation Plan

You are creating the implementation plan for fixing two bugs in `skills/scaffold/SKILL.md`. Use the spec from Phase 4 and test definitions from Phase 5.

## Task Graph

### Task 1: Expand Step 4e — Story Sub-Issue Creation
- **File:** `skills/scaffold/SKILL.md`
- **Location:** Step 4e (currently lines ~508-538)
- **Action:** Expand the step's inner loop (item 1c) from a single line to detailed sub-steps
- **Dependencies:** None
- **Estimated lines changed:** ~50-60 lines added

**Detailed changes:**

1. Replace the terse line `c. For each user story within the epic: create a sub-issue under the epic issue.` with expanded sub-steps:

   ```
   c. Parse user stories from the epic file:
      - Stories are identified by `### Story` headings (e.g., `### Story 1.1: Initialize Vite Project`)
      - Each story's content spans from its `### Story` heading to the next `### Story` heading, the next `---` at heading level, or end of file
   d. For each parsed user story:
      i.   Extract story title: text after `### Story N.M: ` prefix
      ii.  Extract story description: full markdown content from the story heading through its acceptance criteria
      iii. Create a sub-issue (subtask) under the epic issue via MCP:
           - Title: `Story N.M: {story title}`
           - Description: story markdown content (including acceptance criteria)
           - Parent: the epic issue created in step (a)
           - If the tracker does not support native sub-issues: create a regular issue with title prefix `[{epic title}] Story N.M: {story title}` and add a reference to the parent epic issue in the description
      iv.  Write tracker issue ID back into the spec file as a reference comment on the line after the story heading:
           `<!-- {TrackerType}: {ISSUE-ID} -->`
      v.   On failure: log `WARN: Could not create sub-issue for Story N.M in {epic filename}: {error}`, continue to next story
   ```

2. Update the back-reference in step (d) to clarify it covers both epics AND stories:
   - Epic back-reference: written after the epic title (existing behavior, preserved)
   - Story back-reference: written after each story heading (new behavior)

3. Update the partial failure summary to include story counts:
   - Change display from `Created {N}/{M} tracker issues` to `Created {N}/{M} epic issues with {S}/{T} story sub-issues`

### Task 2: Add Step 7e — Transition Tracker Issues to Done
- **File:** `skills/scaffold/SKILL.md`
- **Location:** After Step 7 (Feature Implementation Loop), before Step 7b (Spec Compliance Check)
- **Action:** Add a new step
- **Dependencies:** Task 1 (needs story issue IDs from Step 4e back-references)
- **Estimated lines changed:** ~40-50 lines added

**Detailed changes:**

Insert new `### Step 7e: Transition Tracker Issues` section with:

1. **Guard clause** (same pattern as Step 4e):
   - Skip if `tracker_effective_status` is NOT `"ready"`
   - Skip if no tracker issues were created in Step 4e (no back-references in spec/epics/)

2. **Read issue IDs from spec/epics/ back-references:**
   - Parse all `<!-- {TrackerType}: {ISSUE-ID} -->` comments from spec/epics/*.md
   - Categorize: epic-level IDs (after `# Epic` heading) vs story-level IDs (after `### Story` headings)

3. **Determine implementation status per story:**
   - Cross-reference with the decomposition task tree (from Step 5)
   - Stories whose corresponding subtasks completed successfully = "implemented"
   - Stories whose subtasks were blocked/skipped = "not implemented"

4. **Transition stories to Done:**
   - For each "implemented" story: apply Done state transition via MCP
   - Use State Transition Syntax from `docs/reference/trackers.md` (e.g., YouTrack: `State: Done`, GitHub: `close`, Gitea: `close`)
   - Read the Done transition from Automation Config `State transitions` if defined; otherwise use tracker default from trackers.md
   - On failure: `WARN: Could not transition {ISSUE-ID} to Done: {error}`, continue

5. **Transition epics to Done (conditional):**
   - For each epic: check if ALL its stories are "implemented"
   - If yes: transition epic to Done
   - If no (some stories blocked): do NOT transition epic, log: `Epic {ISSUE-ID} not closed — {N} stories still open`

6. **Display summary:**
   ```
   Tracker issues updated: {N}/{M} stories closed, {E_closed}/{E_total} epics closed.
   ```

### Task 3: Update test scenarios
- **File:** `tests/scenarios/` (new or existing file)
- **Action:** Add test scenarios from Phase 5
- **Dependencies:** Tasks 1, 2
- **Estimated lines changed:** ~30-40 lines

## Execution Order

```
Task 1 (Step 4e expansion)  ─┐
                              ├──> Task 3 (tests)
Task 2 (Step 7e addition)   ─┘
```

Tasks 1 and 2 are independent (different sections of the same file) but both modify `skills/scaffold/SKILL.md`, so they should be executed sequentially to avoid merge conflicts. Task 3 depends on both.

## Parallelization

**Sequential execution recommended.** All three tasks modify the same file or depend on its final state. No parallelization opportunity.

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Step 4e expansion makes the step too verbose | Medium | Low | Keep instructions concise, use numbered sub-steps |
| Tracker API incompatibility for sub-issues | Low | Medium | Include fallback for trackers without native sub-issues |
| Step 7e Done transition syntax wrong | Low | Medium | Reference trackers.md explicitly in the instruction |
| Existing tests break | Low | Low | Run test suite before commit |
