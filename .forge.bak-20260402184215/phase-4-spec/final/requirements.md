# Phase 4 Specification: Requirements

**Scope:** Fix two bugs in `skills/scaffold/SKILL.md` — story sub-issue creation (Bug 1) and tracker issue Done transition (Bug 2).
**Version impact:** PATCH (no config contract change, no new required key, no new agent).
**Date:** 2026-04-02
**Source:** Phase 3 brainstorm synthesis (final.md)

---

## REQ-1: Story Sub-Issue Creation (Step 4e Expansion)

**EARS format:** When Step 4e iterates over `spec/epics/*.md` files and a file contains one or more user stories (identified by `### Story N.M:` headings), the system shall parse each story from the epic markdown, create a tracker sub-issue for each story linked to the parent epic issue, and write back the story issue ID as a back-reference comment.

### Acceptance Criteria

1. **AC-1.1: Story parsing.** Given an epic file with stories delimited by `---` separators, when Step 4e processes it, then each `### Story N.M:` block is identified — title extracted from the heading text (after `### Story N.M: `), description extracted from content between the heading and the next `---` delimiter.

2. **AC-1.2: Sub-issue creation with parent link.** Given a tracker that supports native sub-issues (YouTrack, Jira, Linear, Redmine — per Sub-Issue Capabilities table in `docs/reference/trackers.md`), when a story sub-issue is created, then it is linked to the parent epic issue via the tracker's native parent parameter.

3. **AC-1.3: Story back-reference writeback.** Given a story sub-issue is created successfully, when the spec file is updated, then a back-reference comment `<!-- {TrackerType}: {STORY-ISSUE-ID} -->` is written on the line immediately following the `### Story N.M:` heading.

4. **AC-1.4: Per-story failure handling.** Given a sub-issue creation fails for a single story, when the error is caught, then a WARN is logged and the pipeline continues to the next story. The epic is considered succeeded if the epic-level issue was created.

5. **AC-1.5: Zero stories edge case.** Given an epic file contains zero `### Story` headings, when Step 4e processes it, then story iteration is skipped — the epic-only issue is sufficient.

6. **AC-1.6: Updated display message.** After Step 4e completes, the display message includes story counts: `Created {N}/{M} tracker issues ({S} stories, {F} story failures).`

---

## REQ-2: Tracker-Specific Branching (Native Sub-Issues vs. Fallback)

**EARS format:** When Step 4e creates story sub-issues and the configured tracker does NOT support native sub-issues (GitHub, Gitea), the system shall create standalone issues with a title format of `[{epic_title}] {story_title}` and add a cross-reference to the epic issue in the story issue description.

### Acceptance Criteria

1. **AC-2.1: Tracker branching logic.** Step 4e contains a single IF/ELSE branch: trackers that support native sub-issues (YouTrack, Jira, Linear, Redmine) vs. trackers that do not (GitHub, Gitea).

2. **AC-2.2: Fallback title format.** Given GitHub or Gitea tracker, when a story issue is created, then its title follows the format `[{epic_title}] {story_title}`.

3. **AC-2.3: Fallback cross-reference.** Given GitHub or Gitea tracker, when a story issue is created, then the story issue description includes a cross-reference to the parent epic issue.

4. **AC-2.4: Reference to trackers.md.** Step 4e references `docs/reference/trackers.md` Sub-Issue Capabilities table for tracker-specific details rather than enumerating per-tracker API parameters inline.

---

## REQ-3: Idempotency Guards for Resume Safety

**EARS format:** When Step 4e runs during a resumed scaffold pipeline, the system shall check for existing back-reference comments before creating tracker issues, skipping creation for any epic or story that already has a back-reference.

### Acceptance Criteria

1. **AC-3.1: Epic-level idempotency.** Before creating an epic issue, Step 4e checks if the epic file already contains a `<!-- {TrackerType}: ... -->` back-reference comment after the `# Epic NN:` heading. If present, skip epic creation and extract the existing issue ID for use as parent ID.

2. **AC-3.2: Story-level idempotency.** Before creating a story sub-issue, Step 4e checks if the story heading already has a `<!-- {TrackerType}: ... -->` back-reference comment. If present, skip creation for that story.

3. **AC-3.3: Partial resume continuity.** Given a previous run created 3 out of 5 epic issues before interruption, when scaffold resumes, then only the 2 remaining epics have issues created. The 3 existing epics are skipped (their IDs are extracted for parent linking).

---

## REQ-4: Tracker Issue Done Transition (New Step 8b)

**EARS format:** When all quality gates pass (Step 7b Spec Compliance + Step 8 E2E Tests), the system shall transition fully-completed tracker issues to Done using the `State transitions -> Done` mapping from Automation Config.

### Acceptance Criteria

1. **AC-4.1: Insertion point.** Step 8b is positioned after Step 8 (E2E Tests) and before Step 9 (Final Report).

2. **AC-4.2: Guard clauses.** Step 8b is skipped entirely if ANY of: (a) `tracker_effective_status` is NOT `"ready"`, (b) `tracker_write_available` is `false`, (c) no tracker issues were created at Step 4e (no back-reference comments in `spec/epics/*.md`), (d) `State transitions` does not contain a `Done` mapping.

3. **AC-4.3: Missing Done mapping warning.** Given `State transitions` does not include a `Done` mapping, when Step 8b evaluates its guard, then it displays `WARN: State transitions does not include a 'Done' mapping. Skipping issue closure.`

4. **AC-4.4: Per-epic granularity.** An epic is transitioned to Done only if NONE of its subtasks appear in the blocked features list. Epics with any blocked subtask remain open.

5. **AC-4.5: GitHub/Gitea explicit story closure.** For trackers without native sub-issues (GitHub, Gitea), Step 8b explicitly closes each story issue in addition to the epic issue. For trackers with native sub-issues (YouTrack, Jira, Linear, Redmine), only the parent epic is closed (cascade assumed).

6. **AC-4.6: Per-issue failure handling.** Given a state transition fails for a single issue, when the error is caught, then a WARN is logged (`Could not transition {issue_id} to Done: {error}`) and the pipeline continues.

7. **AC-4.7: Display message.** After Step 8b completes, display: `Transitioned {N}/{M} tracker issues to Done. {skipped} skipped (blocked subtasks).`

8. **AC-4.8: Issue ID retrieval method.** Tracker issue IDs are retrieved by parsing `spec/epics/*.md` back-reference comments. No state.json lookup.

---

## REQ-5: Sub-Issue Capabilities Documentation

**EARS format:** The system shall document sub-issue capabilities for all 6 supported trackers in `docs/reference/trackers.md` as a new section titled "Sub-Issue Capabilities".

### Acceptance Criteria

1. **AC-5.1: Table structure.** The table has 4 columns: Tracker, Native sub-issues (Yes/No), Parent parameter, Fallback strategy.

2. **AC-5.2: Six rows.** Rows for: YouTrack, Jira, Linear, Redmine (all Yes), GitHub, Gitea (both No).

3. **AC-5.3: Parent parameter values.** YouTrack: `parent: {issue-id}`, Jira: `parent: {key}` + `issuetype: "Sub-task"`, Linear: `parentId: {id}`, Redmine: `parent_issue_id: {id}`, GitHub: N/A, Gitea: N/A.

4. **AC-5.4: Fallback strategy values.** GitHub and Gitea: "Standalone issue with `[{epic_title}] {story_title}` title, cross-reference in description". Others: N/A.

5. **AC-5.5: Placement.** The section is added after the existing "MCP Server Detection" section (end of file) in `docs/reference/trackers.md`.

---

## REQ-6: Example Config Updates

**EARS format:** All example configs in `examples/configs/` that lack a `Done` mapping in their `State transitions` row shall be updated to include the tracker-appropriate Done value.

### Acceptance Criteria

1. **AC-6.1: Configs requiring update.** The following 6 configs need a Done mapping added:
   - `github-dotnet.md` — add `Done: \`close\``
   - `github-python-fastapi.md` — add `Done: \`close\``
   - `github-nextjs.md` — add `Done: \`close\``
   - `gitea-spring-boot.md` — add `Done: \`close\``
   - `jira-react.md` — add `Done: \`transition:Done\``
   - `youtrack-python.md` — add `Done: \`State: Done\``

2. **AC-6.2: Config already correct.** `redmine-rails.md` already has `Done: \`status:Closed\`` and must NOT be modified.

3. **AC-6.3: Insertion format.** The Done mapping is appended to the existing `State transitions` value (comma-separated, same format as existing entries).

---

## REQ-7: Backward Compatibility

**EARS format:** The system shall maintain backward compatibility with all existing scaffold behavior.

### Acceptance Criteria

1. **AC-7.1: Later/downgraded unaffected.** Projects with `tracker_effective_status = "later"` or `"downgraded"` are unaffected — Step 4e guard clause skips, Step 8b guard clause skips.

2. **AC-7.2: --no-implement unaffected.** The `--no-implement` legacy flow (L1-L6) is not modified. It does not execute Steps 4e or 8b.

3. **AC-7.3: Existing epic creation preserved.** The existing epic-level issue creation behavior (Step 4e.1.a, 4e.1.b, 4e.1.d) is unchanged. Story sub-issue creation is additive.

4. **AC-7.4: Existing commit structure preserved.** The `chore: link spec epics to tracker issues` commit message and its trigger conditions are unchanged.

5. **AC-7.5: No Automation Config contract change.** No new required or optional key is added. "Done" is read from the existing `State transitions` key.

---

## REQ-8: Final Report Update (Closed-Issues Count)

**EARS format:** When Step 9 generates the Final Report, the system shall include the count of tracker issues transitioned to Done by Step 8b.

### Acceptance Criteria

1. **AC-8.1: Closed count in Infrastructure section.** The tracker line in the Final Report includes closed-issues count when Step 8b ran: `Tracker: Connected ({tracker_type} @ {tracker_instance} — {tracker_project}, {N} epics created, {C} issues closed)`.

2. **AC-8.2: No closed count when Step 8b skipped.** If Step 8b was skipped (guard triggered), the tracker line remains unchanged (existing format without closed count).
