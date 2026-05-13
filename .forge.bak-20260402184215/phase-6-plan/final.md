# Implementation Plan

**Date:** 2026-04-02
**Scope:** Scaffold tracker integration bugfix (Step 4e story sub-issues + Step 8b Done transition)
**Primary file:** `skills/scaffold/SKILL.md`
**Total tasks:** 5

---

## Task Graph

| ID | Title | Files | Dependencies | Parallelizable | Est. Lines |
|----|-------|-------|-------------|----------------|------------|
| task-001 | Add Sub-Issue Capabilities section to trackers.md | `docs/reference/trackers.md` | none | yes | 12 |
| task-002 | Add Done mapping to 6 example configs | `examples/configs/{6 files}.md` | none | yes |  6 |
| task-003 | Replace Step 4e with expanded story sub-issue creation | `skills/scaffold/SKILL.md` | task-001 | no | 46 |
| task-004 | Insert Step 8b and update Step 9 Final Report | `skills/scaffold/SKILL.md` | task-003 | no | 28 |
| task-005 | Copy test file to test suite | `tests/scenarios/scaffold-tracker-integration.sh` | task-001, task-002, task-003, task-004 | no | 0 (copy) |

### Dependency Diagram

```
task-001 (trackers.md) ──┐
                         ├──→ task-003 (Step 4e) ──→ task-004 (Step 8b + Step 9) ──→ task-005 (tests)
task-002 (configs)  ─────┘
```

task-001 and task-002 are independent and can run in parallel. task-003 depends on task-001 (because Step 4e references `docs/reference/trackers.md` Sub-Issue Capabilities). task-004 depends on task-003 (both modify SKILL.md, and line numbers shift after task-003). task-005 runs last and copies the pre-written test file into the test suite.

---

## Task Details

### task-001: Add Sub-Issue Capabilities section to trackers.md

**Files:** `docs/reference/trackers.md`
**Dependencies:** none
**Maps to:** REQ-5, AC-5.1, AC-5.2, AC-5.3, AC-5.4, AC-5.5

**Instructions:**

Append the following text at the end of `docs/reference/trackers.md` (after line 85, which is the last line of the MCP Server Detection table). The file currently ends at line 85 with `| redmine | ...`. Add one blank line after the current content, then the new section:

**Exact text to append after the last line of the file:**

```markdown

## Sub-Issue Capabilities

| Tracker | Native sub-issues | Parent parameter | Fallback strategy |
|---------|-------------------|-----------------|-------------------|
| youtrack | Yes | `parent: {issue-id}` | N/A |
| jira | Yes | `parent: {key}`, `issuetype: "Sub-task"` | N/A |
| linear | Yes | `parentId: {id}` | N/A |
| redmine | Yes | `parent_issue_id: {id}` | N/A |
| github | No | N/A | Standalone issue: `[{epic_title}] {story_title}`, cross-reference in description |
| gitea | No | N/A | Standalone issue: `[{epic_title}] {story_title}`, cross-reference in description |

> **Note:** The parent parameter names are MCP tool conventions. The LLM uses these when invoking the tracker's MCP create-issue tool. For trackers without native sub-issues, the fallback creates a standalone issue with the epic title as a prefix and adds a link to the parent epic issue in the description body.
```

**Verification (assertions that must PASS after this task):**

- G-21: `grep -q 'Sub-Issue Capabilities' docs/reference/trackers.md` → PASS
- G-22: `grep -q 'Native sub-issues' docs/reference/trackers.md` → PASS
- G-23: `grep -q 'parent_issue_id' docs/reference/trackers.md` → PASS
- G-24: `grep -q 'parentId' docs/reference/trackers.md` → PASS
- G-25: `grep -q 'Standalone issue' docs/reference/trackers.md` → PASS

---

### task-002: Add Done mapping to 6 example configs

**Files:** `examples/configs/github-dotnet.md`, `examples/configs/github-python-fastapi.md`, `examples/configs/github-nextjs.md`, `examples/configs/gitea-spring-boot.md`, `examples/configs/jira-react.md`, `examples/configs/youtrack-python.md`
**Dependencies:** none
**Maps to:** REQ-6, AC-6.1, AC-6.2, AC-6.3

**Instructions:**

For each of the 6 files below, find the `State transitions` row (line 14 in each file) and append the Done mapping to the existing value. Use the Edit tool with exact string replacement. Do NOT modify `examples/configs/redmine-rails.md` (it already has `Done: \`status:Closed\``).

**File 1: `examples/configs/github-dotnet.md` (line 14)**
- Old: `| State transitions | In Progress: \`add label:in-progress\`, Blocked: \`add label:blocked\`, For Review: \`add label:for-review\` |`
- New: `| State transitions | In Progress: \`add label:in-progress\`, Blocked: \`add label:blocked\`, For Review: \`add label:for-review\`, Done: \`close\` |`

**File 2: `examples/configs/github-python-fastapi.md` (line 14)**
- Old: `| State transitions | In Progress: \`add label:in-progress\`, Blocked: \`add label:blocked\`, For Review: \`add label:for-review\` |`
- New: `| State transitions | In Progress: \`add label:in-progress\`, Blocked: \`add label:blocked\`, For Review: \`add label:for-review\`, Done: \`close\` |`

**File 3: `examples/configs/github-nextjs.md` (line 14)**
- Old: `| State transitions | In Progress: \`add label:in-progress\`, Blocked: \`add label:blocked\`, For Review: \`add label:for-review\` |`
- New: `| State transitions | In Progress: \`add label:in-progress\`, Blocked: \`add label:blocked\`, For Review: \`add label:for-review\`, Done: \`close\` |`

**File 4: `examples/configs/gitea-spring-boot.md` (line 14)**
- Old: `| State transitions | In Progress: \`add label:in-progress\`, Blocked: \`add label:blocked\`, For Review: \`add label:for-review\` |`
- New: `| State transitions | In Progress: \`add label:in-progress\`, Blocked: \`add label:blocked\`, For Review: \`add label:for-review\`, Done: \`close\` |`

**File 5: `examples/configs/jira-react.md` (line 14)**
- Old: `| State transitions | In Progress: \`transition:In Progress\`, Blocked: \`transition:Blocked\`, For Review: \`transition:In Review\` |`
- New: `| State transitions | In Progress: \`transition:In Progress\`, Blocked: \`transition:Blocked\`, For Review: \`transition:In Review\`, Done: \`transition:Done\` |`

**File 6: `examples/configs/youtrack-python.md` (line 14)**
- Old: `| State transitions | In Progress: \`State: In Progress\`, Blocked: \`State: Blocked\`, For Review: \`State: For Review\` |`
- New: `| State transitions | In Progress: \`State: In Progress\`, Blocked: \`State: Blocked\`, For Review: \`State: For Review\`, Done: \`State: Done\` |`

**Verification (assertions that must PASS after this task):**

- G-26: `grep -qE 'Done:.*close' examples/configs/github-dotnet.md` → PASS
- G-27: `grep -qE 'Done:.*close' examples/configs/github-python-fastapi.md` → PASS
- G-28: `grep -qE 'Done:.*close' examples/configs/github-nextjs.md` → PASS
- G-29: `grep -qE 'Done:.*close' examples/configs/gitea-spring-boot.md` → PASS
- G-30: `grep -qE 'Done:.*transition:Done' examples/configs/jira-react.md` → PASS
- G-31: `grep -qE 'Done:.*State: Done' examples/configs/youtrack-python.md` → PASS
- G-32: `grep -qE 'Done:.*status:Closed' examples/configs/redmine-rails.md` → PASS (pre-existing, must not break)

---

### task-003: Replace Step 4e with expanded story sub-issue creation

**Files:** `skills/scaffold/SKILL.md`
**Dependencies:** task-001 (trackers.md must have Sub-Issue Capabilities section for the reference to be valid)
**Maps to:** REQ-1 (AC-1.1 through AC-1.6), REQ-2 (AC-2.1 through AC-2.4), REQ-3 (AC-3.1 through AC-3.3), REQ-7 (AC-7.1 through AC-7.5)

**Instructions:**

Replace the ENTIRE content of Step 4e — from line 508 (`### Step 4e: Create Tracker Issues`) through line 538 (`3. If ALL epics succeeded: commit and display: \`Created {M}/{M} tracker issues.\``) — with the expanded text below.

**Use the Edit tool.** The old_string to match is (lines 508-538):

```
### Step 4e: Create Tracker Issues

**Required in-memory values from Step 0-INFRA:** `tracker_type`, `tracker_instance`, `tracker_project`, `tracker_effective_status`.

**Guard clause — skip this step if ANY of:**
- `tracker_effective_status` is NOT `"ready"`
- `tracker_write_available` is `false`
- `spec/epics/` directory does not exist or is empty

If none of the guard conditions apply, proceed:

1. Iterate over `spec/epics/*.md` files (sorted by filename prefix):
   - For each epic file:
     a. Create an epic-level issue in the tracker project (title from epic heading, description from epic content).
     b. Do NOT apply the `On start set` state transition from Automation Config. Issues represent planned work, not started work. The `On start set` transition applies when `/implement-feature` begins working on each issue.
     c. For each user story within the epic: create a sub-issue under the epic issue.
     d. Write the created issue ID back into the spec file as a reference comment.
     e. Track the result: success or failure for this epic.

2. **Partial failure handling (accumulator pattern):**
   - On individual epic failure: log the failure (`WARN: Could not create tracker issue for {epic filename}: {error}`), continue to next epic.
   - After iteration completes: if any epics succeeded, commit the partial links:
     ```bash
     git add spec/
     git commit -m "chore: link spec epics to tracker issues"
     ```
   - Display result: `Created {N}/{M} tracker issues. {remaining text if N < M}`
   - If N < M: `Remaining epics can be linked later via /implement-feature.`
   - Pipeline continues — this is a WARN, not a BLOCK.

3. If ALL epics succeeded: commit and display: `Created {M}/{M} tracker issues.`
```

**The new_string replacement is:**

```
### Step 4e: Create Tracker Issues

**Required in-memory values from Step 0-INFRA:** `tracker_type`, `tracker_instance`, `tracker_project`, `tracker_effective_status`.

**Guard clause — skip this step if ANY of:**
- `tracker_effective_status` is NOT `"ready"`
- `tracker_write_available` is `false`
- `spec/epics/` directory does not exist or is empty

If none of the guard conditions apply, proceed:

1. Iterate over `spec/epics/*.md` files (sorted by filename prefix):
   For each epic file:

   a. **Idempotency guard (epic):** Check if the epic file already contains a `<!-- {TrackerType}: ... -->` back-reference comment after the `# Epic NN:` heading. If present: skip epic creation, extract the existing issue ID for use as parent ID in story creation. Jump to step 1.c.

   b. Create an epic-level issue in the tracker project (title from epic heading, description from epic content). Do NOT apply the `On start set` state transition from Automation Config. Issues represent planned work, not started work. The `On start set` transition applies when `/implement-feature` begins working on each issue. Write the created issue ID back into the spec file as `<!-- {TrackerType}: {EPIC-ISSUE-ID} -->` after the `# Epic NN:` heading.

   c. **Parse stories from the epic markdown file:**
      - Split content on `\n---\n` delimiter to get blocks
      - Identify story blocks by matching `### Story N.M:` headings
      - For each story block:
        - Extract title: text after `### Story N.M: `
        - Extract description: content from user-story sentence to next `---` (exclusive)
        - **Idempotency guard (story):** If story heading already has a `<!-- {TrackerType}: ... -->` back-reference comment on the next line, skip creation for this story
        - **If tracker supports native sub-issues** (YouTrack, Jira, Linear, Redmine — see Sub-Issue Capabilities in `docs/reference/trackers.md`): create sub-issue with parent set to epic issue ID using the tracker's native parent parameter
        - **If tracker does NOT support native sub-issues** (GitHub, Gitea): create standalone issue with title `[{epic_title}] {story_title}`, add cross-reference to epic issue in description
        - Write story issue ID back as `<!-- {TrackerType}: {STORY-ISSUE-ID} -->` immediately after the `### Story N.M:` heading
      - If epic has zero stories (no `### Story` headings found): skip story iteration — epic-only issue is sufficient

   d. Track the result: success or failure for this epic.

2. **Partial failure handling (accumulator pattern):**
   - On individual **story** failure: log `WARN: Could not create story sub-issue for {story title} in {epic filename}: {error}`, continue to next story. The epic is considered succeeded if the epic-level issue was created.
   - On individual **epic** failure: log `WARN: Could not create tracker issue for {epic filename}: {error}`, continue to next epic.
   - After iteration completes: if any epics succeeded, commit the partial links:
     ```bash
     git add spec/
     git commit -m "chore: link spec epics to tracker issues"
     ```
   - Display result: `Created {N}/{M} tracker issues ({S} stories, {F} story failures).`
   - If N < M: `Remaining epics can be linked later via /implement-feature.`
   - Pipeline continues — this is a WARN, not a BLOCK.

3. If ALL epics succeeded and zero story failures: commit and display: `Created {M}/{M} tracker issues ({S} stories).`
```

**Critical preservation checks after edit:**

- The guard clause text (`tracker_effective_status is NOT "ready"`, `tracker_write_available is false`, `spec/epics/ directory does not exist`) MUST be present (BC-2)
- The text `Do NOT apply the \`On start set\`` MUST be present (BC-3)
- The commit message `chore: link spec epics to tracker issues` MUST be present (BC-4)
- The next section (`### Step 5: Architecture & Decomposition` on what was line 540) MUST remain intact and unmodified

**Verification (assertions that must PASS after this task):**

- G-01: `grep -q 'Story N\.M:' skills/scaffold/SKILL.md` → PASS
- G-02: `grep -q 'STORY-ISSUE-ID' skills/scaffold/SKILL.md` → PASS
- G-03: `grep -q 'Idempotency guard' skills/scaffold/SKILL.md` → PASS
- G-04: `grep -q 'supports native sub-issues' skills/scaffold/SKILL.md` → PASS
- G-05: `grep -q 'Sub-Issue Capabilities' skills/scaffold/SKILL.md` → PASS
- G-06: `grep -q '\[{epic_title}\]' skills/scaffold/SKILL.md` → PASS
- G-07: `grep -q 'story failures' skills/scaffold/SKILL.md` → PASS
- G-08: `grep -q 'Split content on' skills/scaffold/SKILL.md` → PASS
- G-09: `grep -q 'zero stories' skills/scaffold/SKILL.md` → PASS
- G-10: `grep -q 'cross-reference to epic issue' skills/scaffold/SKILL.md` → PASS
- Regression: `grep -q 'chore: link spec epics to tracker issues' skills/scaffold/SKILL.md` → PASS
- Regression: `grep -q 'Do NOT apply the .On start set.' skills/scaffold/SKILL.md` → PASS

---

### task-004: Insert Step 8b and update Step 9 Final Report

**Files:** `skills/scaffold/SKILL.md`
**Dependencies:** task-003 (must complete first because task-003 changes line numbers in SKILL.md; also, both tasks modify the same file so they cannot run in parallel)
**Maps to:** REQ-4 (AC-4.1 through AC-4.8), REQ-8 (AC-8.1, AC-8.2)

**Instructions — Part A: Insert Step 8b**

Insert the new Step 8b section between Step 8 (E2E Tests) and Step 9 (Final Report). After task-003 completes, the line numbers will have shifted. Use the Edit tool to find the exact boundary. The anchor text is:

**old_string** (the end of Step 8 flowing into Step 9):

```
If no E2E Test section → skip.

### Step 9: Final Report
```

**new_string:**

```
If no E2E Test section → skip.

### Step 8b: Close Tracker Issues

**Guard clause — skip this step if ANY of:**
- `tracker_effective_status` is NOT `"ready"`
- `tracker_write_available` is `false`
- No tracker issues were created at Step 4e (no back-reference comments `<!-- {TrackerType}: ... -->` found in `spec/epics/*.md`)
- `State transitions` value from Automation Config does not contain a `Done` mapping

If guard triggers for missing Done mapping: display `WARN: State transitions does not include a 'Done' mapping. Skipping issue closure.`

**Transition logic:**

1. Read all `spec/epics/*.md` files. Extract epic issue IDs from back-reference comments (`<!-- {TrackerType}: {ID} -->`).
2. Determine which epics are fully completed: an epic is complete if NONE of its subtasks (from architect decomposition) appear in the blocked features list (computed by Step 7 block handler).
3. For each fully-completed epic:
   a. Transition the epic issue to Done using `State transitions -> Done` syntax from Automation Config.
   b. For GitHub/Gitea (standalone story issues): also close each story issue individually. Read story IDs from back-reference comments within the epic file.
   c. For trackers with native sub-issues (YouTrack, Jira, Linear, Redmine): closing the parent epic typically cascades to children. Do NOT explicitly close story sub-issues.
   d. On failure: WARN (`Could not transition {issue_id} to Done: {error}`), continue to next.
4. For epics with blocked subtasks: skip. These remain open for manual triage.
5. Display: `Transitioned {N}/{M} tracker issues to Done. {skipped} skipped (blocked subtasks).`

### Step 9: Final Report
```

**Instructions — Part B: Update Step 9 Final Report tracker line**

In the Final Report template, find the tracker-connected line and add the closed-issues count.

**old_string:**

```
  Tracker: Connected ({tracker_type} @ {tracker_instance} — {tracker_project}, {N} epics created)
```

**new_string:**

```
  Tracker: Connected ({tracker_type} @ {tracker_instance} — {tracker_project}, {N} epics created{if step_8b_ran}, {C} issues closed{/if})
```

**Verification (assertions that must PASS after this task):**

- G-11: `grep -q 'Step 8b: Close Tracker Issues' skills/scaffold/SKILL.md` → PASS
- G-12: `grep -q "does not include a 'Done' mapping" skills/scaffold/SKILL.md` → PASS
- G-13: `grep -q 'blocked features list' skills/scaffold/SKILL.md` → PASS
- G-14: `grep -qE 'Transitioned.*tracker issues to Done' skills/scaffold/SKILL.md` → PASS
- G-15: `grep -q 'skipped (blocked subtasks)' skills/scaffold/SKILL.md` → PASS
- G-16: `grep -q 'Could not transition' skills/scaffold/SKILL.md` → PASS
- G-17: `grep -q 'Do NOT explicitly close story sub-issues' skills/scaffold/SKILL.md` → PASS
- G-18: `grep -q 'issues closed' skills/scaffold/SKILL.md` → PASS
- G-19: Line number of `Step 8b: Close Tracker Issues` > line number of `Step 8: E2E Tests` → PASS
- G-20: Line number of `Step 8b: Close Tracker Issues` < line number of `Step 9: Final Report` → PASS
- BC-5: `grep -q '## Scaffold Complete' skills/scaffold/SKILL.md` → PASS (report structure intact)
- BC-5: `grep -q '### Next steps:' skills/scaffold/SKILL.md` → PASS (report structure intact)

---

### task-005: Copy test file to test suite

**Files:** `tests/scenarios/scaffold-tracker-integration.sh` (new file, copied from `.forge/phase-5-tdd/tests/`)
**Dependencies:** task-001, task-002, task-003, task-004 (all implementation must be done before tests can pass)
**Maps to:** All REQs (test coverage)

**Instructions:**

Copy the pre-written test file from the TDD phase into the test scenarios directory:

```bash
cp .forge/phase-5-tdd/tests/scaffold-tracker-integration.sh tests/scenarios/scaffold-tracker-integration.sh
```

The file already exists at `.forge/phase-5-tdd/tests/scaffold-tracker-integration.sh` and contains all 34 visible test assertions. No modifications are needed -- the file is ready to use as-is.

After copying, run the full test to verify all assertions pass:

```bash
bash tests/scenarios/scaffold-tracker-integration.sh
```

**Verification:**

- All 34 assertions in `scaffold-tracker-integration.sh` pass (exit code 0)
- Existing test suite (`./tests/harness/run-tests.sh`) still passes (all 39+ existing tests + 1 new test)

---

## Execution Order Summary

```
Phase 1 (parallel):  task-001 + task-002
Phase 2 (sequential): task-003 (depends on task-001)
Phase 3 (sequential): task-004 (depends on task-003)
Phase 4 (sequential): task-005 (depends on all)
```

Total estimated: ~92 lines of new/modified content across 9 files.

---

## Negative Assertions (Must NOT Happen)

These are implementation guardrails -- no task should introduce any of these:

| ID | Assertion | Reason |
|----|-----------|--------|
| BC-8 | `Step 7e` must NOT appear in SKILL.md | Phase 0 proposed Step 7e; brainstorm moved it to Step 8b |
| BC-9 | `On complete` must NOT appear as a config key in SKILL.md | No new config key -- "Done" is read from existing State transitions |
| BC-10 | `tracker_issues` must NOT appear as a state.json field | No state.json persistence of issue IDs |
| BC-11 | `core/sub-issue-creator.md` must NOT be created | No new core contract (single consumer) |
