# Phase 4 — Specification

You are writing the specification for fixing two bugs in `skills/scaffold/SKILL.md`. Use the brainstorm output from Phase 3 to inform your design decisions.

## Requirements (EARS Format)

### REQ-1: Story sub-issue creation

**When** Step 4e iterates over `spec/epics/*.md` files **and** a file contains one or more user stories (identified by `### Story` headings), **the system shall** create a sub-issue in the tracker for each story, linked to the parent epic issue, with the story title as the sub-issue title and the story description (including acceptance criteria) as the sub-issue description.

**Acceptance Criteria:**

1. Given an epic file with 4 stories (e.g., `01-project-setup.md` with Stories 1.1-1.4), When Step 4e processes it, Then 1 epic issue + 4 sub-issues are created in the tracker.
2. Given a sub-issue is created, When the issue appears in the tracker, Then its title follows the format `Story N.M: {story title}` and its description contains the full story content including acceptance criteria.
3. Given a sub-issue is created successfully, When the spec file is updated, Then a back-reference comment is written at the story heading level in the format `<!-- YouTrack: {ISSUE-ID} -->` (or equivalent per tracker type).
4. Given a sub-issue creation fails, When the error is caught, Then a WARN is logged and the pipeline continues to the next story (accumulator pattern, same as epic failure handling).
5. Given a tracker does NOT support native sub-issues/subtasks, When Step 4e attempts to create stories, Then it creates regular issues with a title prefix indicating the parent epic (e.g., `[Epic 01] Story 1.1: ...`) and links them via description reference.

### REQ-2: Tracker issue state transition after implementation

**When** the Feature Implementation Loop (Step 7) completes for all batches, **the system shall** transition all successfully implemented tracker issues (both stories and epics) to the "Done" state (or equivalent per tracker type per the State Transition Syntax from `docs/reference/trackers.md`).

**Acceptance Criteria:**

1. Given all stories in an epic were implemented successfully, When Step 7e runs, Then each story issue is transitioned to "Done" and the epic issue is transitioned to "Done".
2. Given some stories in an epic were blocked/skipped, When Step 7e runs, Then only the successfully implemented story issues are transitioned to "Done". The epic issue is NOT transitioned (since not all stories are complete).
3. Given `tracker_effective_status` is NOT "ready", When Step 7e would run, Then it is skipped entirely.
4. Given a state transition fails for a single issue, When the error is caught, Then a WARN is logged and the pipeline continues to the next issue (accumulator pattern).
5. Given the Automation Config has a `State transitions` section with a "Done" entry, When Step 7e runs, Then it uses that specific transition syntax. If no "Done" entry exists, it falls back to the tracker default from `docs/reference/trackers.md`.

### REQ-3: Backward compatibility

**The system shall** maintain backward compatibility with existing scaffold behavior:
1. Projects scaffolded with `tracker_effective_status = "later"` or `"downgraded"` are unaffected.
2. Projects scaffolded with `--no-implement` are unaffected (legacy flow does not create tracker issues).
3. The fix does not change the existing epic creation behavior — only adds story sub-issue creation.
4. The fix does not change the commit structure or branch strategy.

## Architecture Design

### Modified file: `skills/scaffold/SKILL.md`

**Change 1: Expand Step 4e** (after line 523, within the existing step)

Add detailed sub-steps for story parsing and sub-issue creation:
- Story identification: `### Story` heading pattern
- Story boundary: from heading to next `### Story` heading, next `---` separator at heading level, or end of file
- Sub-issue title format: `Story N.M: {title text}`
- Sub-issue description: full story markdown content (including AC)
- Back-reference: `<!-- {TrackerType}: {ISSUE-ID} -->` inserted after the story heading
- Failure handling: per-story accumulator (WARN + continue)

**Change 2: Add new Step 7e** (after Step 7, Feature Implementation Loop, before Step 7b, Spec Compliance Check)

New step: "Transition Tracker Issues to Done"
- Guard: same as Step 4e (`tracker_effective_status == "ready"`)
- Read tracker issue IDs from `spec/epics/*.md` back-references (both epic and story level)
- For each implemented story: transition to Done
- For each epic where ALL stories are Done: transition epic to Done
- Failure handling: per-issue accumulator (WARN + continue)
- State update: log transition results to stdout

### No changes needed to:
- `agents/` — no agent behavior changes
- `core/` — no shared contract changes
- `docs/reference/trackers.md` — sub-issue creation is via existing MCP tools
- `tests/` — test file update will be handled in Phase 5 (TDD)

## Traceability

| Requirement | Change | Location |
|-------------|--------|----------|
| REQ-1 | Expand Step 4e | `skills/scaffold/SKILL.md` lines ~519-536 |
| REQ-2 | Add Step 7e | `skills/scaffold/SKILL.md` after line ~680 |
| REQ-3 | No change | Verified by guard clauses |
