# Phase 4 Specification: Architecture Design

**Date:** 2026-04-02
**Source:** Phase 3 brainstorm synthesis + codebase analysis

---

## 1. Insertion Points in SKILL.md

| Change | Location | Reference |
|--------|----------|-----------|
| Expand Step 4e sub-step 1 (story parsing, idempotency, tracker branching, back-reference) | Lines 519-535 (replace current numbered list items 1.a-1.e and partial failure handling) | REQ-1, REQ-2, REQ-3 |
| Add new Step 8b: Close Tracker Issues | After line 710 (after Step 8: E2E Tests, before Step 9: Final Report) | REQ-4 |
| Update Step 9 Final Report tracker line | Line 729 (Infrastructure section, tracker connected line) | REQ-8 |

---

## 2. Expanded Step 4e Text (Full Replacement)

Replace the entire content of `### Step 4e: Create Tracker Issues` (from line 508 through line 538) with the following:

```markdown
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

---

## 3. New Step 8b Text (Full Insertion)

Insert the following as a new section between Step 8 (E2E Tests) and Step 9 (Final Report). In the current file, this means inserting after line 710 (the line `If no E2E Test section → skip.`) and before line 712 (`### Step 9: Final Report`).

```markdown
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
```

---

## 4. Step 9 Final Report Update

In the Final Report template (Step 9), modify the tracker-connected line in the Infrastructure section.

**Current text (line ~729):**
```
  Tracker: Connected ({tracker_type} @ {tracker_instance} — {tracker_project}, {N} epics created)
```

**New text:**
```
  Tracker: Connected ({tracker_type} @ {tracker_instance} — {tracker_project}, {N} epics created{if step_8b_ran}, {C} issues closed{/if})
```

The `{C}` value is the count from Step 8b's display message (number of issues transitioned to Done). If Step 8b was skipped (any guard triggered), the `, {C} issues closed` suffix is omitted.

---

## 5. trackers.md Sub-Issue Capabilities Table

Append the following section at the end of `docs/reference/trackers.md` (after the existing "MCP Server Detection" section, which ends at line 85):

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

---

## 6. Example Config Updates

Each update adds `, Done: \`{value}\`` to the end of the existing `State transitions` value.

### 6.1 `examples/configs/github-dotnet.md`

**Current line 15:**
```
| State transitions | In Progress: `add label:in-progress`, Blocked: `add label:blocked`, For Review: `add label:for-review` |
```

**New line 15:**
```
| State transitions | In Progress: `add label:in-progress`, Blocked: `add label:blocked`, For Review: `add label:for-review`, Done: `close` |
```

### 6.2 `examples/configs/github-python-fastapi.md`

**Current line 15:**
```
| State transitions | In Progress: `add label:in-progress`, Blocked: `add label:blocked`, For Review: `add label:for-review` |
```

**New line 15:**
```
| State transitions | In Progress: `add label:in-progress`, Blocked: `add label:blocked`, For Review: `add label:for-review`, Done: `close` |
```

### 6.3 `examples/configs/github-nextjs.md`

**Current line 15:**
```
| State transitions | In Progress: `add label:in-progress`, Blocked: `add label:blocked`, For Review: `add label:for-review` |
```

**New line 15:**
```
| State transitions | In Progress: `add label:in-progress`, Blocked: `add label:blocked`, For Review: `add label:for-review`, Done: `close` |
```

### 6.4 `examples/configs/gitea-spring-boot.md`

**Current line 15:**
```
| State transitions | In Progress: `add label:in-progress`, Blocked: `add label:blocked`, For Review: `add label:for-review` |
```

**New line 15:**
```
| State transitions | In Progress: `add label:in-progress`, Blocked: `add label:blocked`, For Review: `add label:for-review`, Done: `close` |
```

### 6.5 `examples/configs/jira-react.md`

**Current line 15:**
```
| State transitions | In Progress: `transition:In Progress`, Blocked: `transition:Blocked`, For Review: `transition:In Review` |
```

**New line 15:**
```
| State transitions | In Progress: `transition:In Progress`, Blocked: `transition:Blocked`, For Review: `transition:In Review`, Done: `transition:Done` |
```

### 6.6 `examples/configs/youtrack-python.md`

**Current line 15:**
```
| State transitions | In Progress: `State: In Progress`, Blocked: `State: Blocked`, For Review: `State: For Review` |
```

**New line 15:**
```
| State transitions | In Progress: `State: In Progress`, Blocked: `State: Blocked`, For Review: `State: For Review`, Done: `State: Done` |
```

### 6.7 `examples/configs/redmine-rails.md`

**No change required.** Already contains `Done: \`status:Closed\`` in the State transitions value.

---

## 7. Test File Updates

File: `tests/scenarios/scaffold-v2-happy-path.sh`

Add the following test assertions after the existing Step 4e assertion (line 108) and before the v5.5.0 regression guards section (line 110):

```bash
# --- Story sub-issue creation (Step 4e expansion) ---

# Step 4e specifies story parsing with delimiter
if ! grep -q "Story N.M:" "$SCAFFOLD_CMD"; then
  echo "FAIL: Step 4e missing story heading pattern (Story N.M:)"
  exit 1
fi

# Step 4e specifies story back-reference writeback
if ! grep -q "STORY-ISSUE-ID" "$SCAFFOLD_CMD"; then
  echo "FAIL: Step 4e missing story back-reference writeback format"
  exit 1
fi

# Step 4e includes idempotency guard
if ! grep -q "Idempotency guard" "$SCAFFOLD_CMD"; then
  echo "FAIL: Step 4e missing idempotency guard for resume safety"
  exit 1
fi

# Step 4e includes tracker branching (native vs fallback)
if ! grep -q "supports native sub-issues" "$SCAFFOLD_CMD"; then
  echo "FAIL: Step 4e missing tracker-specific branching for sub-issues"
  exit 1
fi

# Step 4e references trackers.md Sub-Issue Capabilities
if ! grep -q "Sub-Issue Capabilities" "$SCAFFOLD_CMD"; then
  echo "FAIL: Step 4e missing reference to Sub-Issue Capabilities table"
  exit 1
fi

# Step 4e includes GitHub/Gitea fallback strategy
if ! grep -q '\[{epic_title}\]' "$SCAFFOLD_CMD"; then
  echo "FAIL: Step 4e missing GitHub/Gitea fallback title format"
  exit 1
fi

# Step 4e display message includes story counts
if ! grep -q "story failures" "$SCAFFOLD_CMD"; then
  echo "FAIL: Step 4e missing updated display message with story counts"
  exit 1
fi

# --- Done transition (Step 8b) ---

# Step 8b exists
if ! grep -q "Step 8b: Close Tracker Issues" "$SCAFFOLD_CMD"; then
  echo "FAIL: scaffold.md missing Step 8b: Close Tracker Issues"
  exit 1
fi

# Step 8b has guard clause for missing Done mapping
if ! grep -q "does not include a 'Done' mapping" "$SCAFFOLD_CMD"; then
  echo "FAIL: Step 8b missing WARN for absent Done mapping"
  exit 1
fi

# Step 8b appears after Step 8 and before Step 9
STEP_8B_LINE=$(grep -n "Step 8b: Close Tracker Issues" "$SCAFFOLD_CMD" | head -1 | cut -d: -f1)
STEP_9_LINE=$(grep -n "Step 9: Final Report" "$SCAFFOLD_CMD" | head -1 | cut -d: -f1)
E2E_LINE=$(grep -n "Step 8: E2E Tests" "$SCAFFOLD_CMD" | head -1 | cut -d: -f1)
if [ -z "$STEP_8B_LINE" ] || [ -z "$STEP_9_LINE" ] || [ -z "$E2E_LINE" ]; then
  echo "FAIL: Cannot find Step 8, 8b, or 9 for ordering check"
  exit 1
fi
if [ "$STEP_8B_LINE" -le "$E2E_LINE" ] || [ "$STEP_8B_LINE" -ge "$STEP_9_LINE" ]; then
  echo "FAIL: Step 8b must appear after Step 8 (E2E Tests) and before Step 9 (Final Report)"
  exit 1
fi

# Step 8b includes per-epic granularity check
if ! grep -q "blocked features list" "$SCAFFOLD_CMD"; then
  echo "FAIL: Step 8b missing per-epic blocked subtask check"
  exit 1
fi

# Step 9 Final Report includes closed-issues count
if ! grep -q "issues closed" "$SCAFFOLD_CMD"; then
  echo "FAIL: Step 9 Final Report missing closed-issues count"
  exit 1
fi

# --- trackers.md Sub-Issue Capabilities ---

TRACKERS_REF="$REPO_ROOT/docs/reference/trackers.md"

if ! grep -q "Sub-Issue Capabilities" "$TRACKERS_REF"; then
  echo "FAIL: trackers.md missing Sub-Issue Capabilities section"
  exit 1
fi

if ! grep -q "parent_issue_id" "$TRACKERS_REF"; then
  echo "FAIL: trackers.md Sub-Issue Capabilities missing Redmine parent parameter"
  exit 1
fi

# --- Example configs: Done mapping ---

for cfg in github-dotnet github-python-fastapi github-nextjs gitea-spring-boot jira-react youtrack-python redmine-rails; do
  if ! grep -q "Done" "$REPO_ROOT/examples/configs/$cfg.md"; then
    echo "FAIL: Example config $cfg.md missing Done mapping in State transitions"
    exit 1
  fi
done
```

---

## 8. Traceability Matrix

| Requirement | Change Description | File | Location |
|-------------|-------------------|------|----------|
| REQ-1 (AC-1.1–1.6) | Expand Step 4e with story parsing, per-story iteration, back-reference writeback, updated display | `skills/scaffold/SKILL.md` | Step 4e (lines 508-538) |
| REQ-2 (AC-2.1–2.4) | Add IF/ELSE tracker branching in Step 4e, reference trackers.md | `skills/scaffold/SKILL.md` | Step 4e, sub-step 1.c |
| REQ-3 (AC-3.1–3.3) | Add idempotency guards for epic and story in Step 4e | `skills/scaffold/SKILL.md` | Step 4e, sub-steps 1.a, 1.c |
| REQ-4 (AC-4.1–4.8) | New Step 8b: Close Tracker Issues | `skills/scaffold/SKILL.md` | Between Step 8 and Step 9 |
| REQ-5 (AC-5.1–5.5) | Add Sub-Issue Capabilities section | `docs/reference/trackers.md` | After MCP Server Detection (end of file) |
| REQ-6 (AC-6.1–6.3) | Add Done mapping to 6 example configs | `examples/configs/{6 files}.md` | State transitions row |
| REQ-7 (AC-7.1–7.5) | No code change — verified by guard clauses | `skills/scaffold/SKILL.md` | Step 4e guard, Step 8b guard |
| REQ-8 (AC-8.1–8.2) | Add closed-issues count to Final Report tracker line | `skills/scaffold/SKILL.md` | Step 9 Infrastructure section |
| Tests | Add grep assertions for all new content | `tests/scenarios/scaffold-v2-happy-path.sh` | After existing Step 4e assertions |

---

## 9. Files Modified Summary

| File | Type of Change |
|------|---------------|
| `skills/scaffold/SKILL.md` | Replace Step 4e content, insert Step 8b, modify Step 9 report |
| `docs/reference/trackers.md` | Append Sub-Issue Capabilities section |
| `examples/configs/github-dotnet.md` | Add Done to State transitions |
| `examples/configs/github-python-fastapi.md` | Add Done to State transitions |
| `examples/configs/github-nextjs.md` | Add Done to State transitions |
| `examples/configs/gitea-spring-boot.md` | Add Done to State transitions |
| `examples/configs/jira-react.md` | Add Done to State transitions |
| `examples/configs/youtrack-python.md` | Add Done to State transitions |
| `tests/scenarios/scaffold-v2-happy-path.sh` | Add 17 new grep assertions |
