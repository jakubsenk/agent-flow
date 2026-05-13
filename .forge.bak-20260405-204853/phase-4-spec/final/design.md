# Technical Design: Decomposition Subtask Tracker Creation (v6.4.0)

## 1. Step-by-Step Process

The new step is identical in all three skills (inlined, not extracted to a core contract). The canonical template below is inserted at each location with only the step number differing.

### Step Names

| Skill | Step Number | Inserted Between |
|-------|-------------|------------------|
| implement-feature | Step 5a | Step 5 (Decomposition decision) and Step 6 (Subtask execution) |
| fix-ticket | Step 4b-tracker | Step 4b (Decomposition decision) and Step 4c (Subtask execution) |
| fix-bugs | Step 3b-tracker | Step 3b (Decomposition decision) and Step 3c (Subtask execution) |

### Canonical Step Template

Below is the full text to be inlined in each skill. Replace `{STEP-NUM}` with the skill-specific step number.

---

#### {STEP-NUM}. Create tracker subtasks

**Triple gate** -- skip this step entirely (no WARN, expected behavior) if ANY of:
1. `decomposition.decision != "DECOMPOSE"` (task was not decomposed)
2. `Create tracker subtasks` config value == `disabled`
3. `tracker_effective_status != "ready"` (MCP tracker not available)

**Required in-memory values:**
- `ISSUE_ID` (parent issue ID)
- `tracker_type` (from Automation Config -> Issue Tracker -> Type)
- Decomposition YAML path: `.claude/decomposition/{ISSUE-ID}.yaml`
- State.json path: `.ceos-agents/{ISSUE-ID}/state.json`
- Subtask list from decomposition (in-memory from previous step)

**Process:**

```
READ config: Create tracker subtasks from Decomposition section (default: "enabled")
IF value == "disabled" -> skip step
IF tracker_effective_status != "ready" -> skip step

SET success_count = 0
SET failure_count = 0
SET created_issues = []  // list of {subtask_id, tracker_issue_id, title}

FOR EACH subtask IN decomposition.subtasks (topological order):

    // --- Idempotency check (YAML-first, state.json fallback) ---
    SET yaml_value = read subtask.tracker_issue_id from .claude/decomposition/{ISSUE-ID}.yaml
    IF yaml_value != null:
        LOG "[SKIP] Subtask '{subtask.title}' already has tracker issue: {yaml_value}"
        ADD {subtask.id, yaml_value, subtask.title} to created_issues
        success_count += 1
        CONTINUE

    SET state_value = read decomposition.subtasks[subtask.id].tracker_issue_id from state.json
    IF state_value != null:
        LOG "[RECOVER] Subtask '{subtask.title}' found in state.json: {state_value}"
        WRITE state_value to subtask.tracker_issue_id in YAML (in-memory)
        ADD {subtask.id, state_value, subtask.title} to created_issues
        success_count += 1
        CONTINUE

    // --- Build issue content ---
    SET issue_title = subtask.title
    SET issue_description = build_description(subtask)
        // Description includes:
        // - Subtask scope text
        // - "Addresses: {maps_to entries joined by ', '}" (if maps_to is non-empty)
        // - "Files: {subtask.files joined by ', '}" (if files is non-empty)
        // - "Parent issue: {ISSUE_ID}"

    // --- Create issue via MCP (tracker-specific) ---
    TRY:
        IF tracker_type == "youtrack":
            result = MCP create_issue(
                project: {tracker_project},
                summary: issue_title,
                description: issue_description,
                parent: {ISSUE_ID}
            )

        ELSE IF tracker_type == "jira":
            // Jira nested sub-task guard
            parent_issue = MCP get_issue({ISSUE_ID})
            IF parent_issue.issuetype == "Sub-task":
                LOG WARN "Parent issue {ISSUE_ID} is a Sub-task -- creating flat issue without parent link."
                result = MCP create_issue(
                    project: {tracker_project},
                    summary: issue_title,
                    description: issue_description
                )
            ELSE:
                result = MCP create_issue(
                    project: {tracker_project},
                    summary: issue_title,
                    description: issue_description,
                    parent: {ISSUE_ID},
                    issuetype: "Sub-task"
                )

        ELSE IF tracker_type == "linear":
            result = MCP create_issue(
                teamId: {tracker_project},
                title: issue_title,
                description: issue_description,
                parentId: {ISSUE_ID}
            )

        ELSE IF tracker_type == "redmine":
            result = MCP create_issue(
                project_id: {tracker_project},
                subject: issue_title,
                description: issue_description,
                parent_issue_id: {ISSUE_ID}
            )

        ELSE IF tracker_type == "github" OR tracker_type == "gitea":
            result = MCP create_issue(
                owner: {owner from tracker_project},
                repo: {repo from tracker_project},
                title: "[{ISSUE_ID}] {issue_title}",
                body: issue_description
            )

        // --- Write to dual store ---
        SET new_tracker_issue_id = result.issue_id  // or result.key, result.number depending on tracker
        WRITE new_tracker_issue_id to subtask.tracker_issue_id in YAML (in-memory)
        WRITE new_tracker_issue_id to decomposition.subtasks[subtask.id].tracker_issue_id in state.json
            // Follow atomic write protocol from core/state-manager.md
        ADD {subtask.id, new_tracker_issue_id, subtask.title} to created_issues
        success_count += 1

    CATCH error:
        LOG WARN "Could not create tracker sub-issue for subtask '{subtask.title}': {error}"
        SET subtask.tracker_issue_id = null in YAML (in-memory, already null)
        failure_count += 1
        CONTINUE

END FOR

// --- GitHub/Gitea checklist (post-loop) ---
IF (tracker_type == "github" OR tracker_type == "gitea") AND success_count > 0:
    TRY:
        SET parent_body = MCP get_issue({ISSUE_ID}).body
        SET sentinel = "<!-- ceos-agents:decomposition-checklist:{ISSUE_ID} -->"
        IF parent_body CONTAINS sentinel:
            LOG "[SKIP] Decomposition checklist already exists in parent issue body."
        ELSE:
            SET checklist = "\n\n---\n## Decomposition Subtasks\n{sentinel}\n"
            FOR EACH item IN created_issues WHERE item.tracker_issue_id != null:
                checklist += "- [ ] {item.title} (#{item.tracker_issue_id})\n"
            END FOR
            SET new_body = parent_body + checklist
            MCP update_issue({ISSUE_ID}, body: new_body)
    CATCH error:
        LOG WARN "Could not update parent issue body with checklist: {error}. Standalone sub-issues may still exist."

// --- Commit YAML ---
IF success_count > 0:
    git add .claude/decomposition/
    git commit -m "chore: link decomposition subtasks to tracker issues"

// --- Result display ---
IF failure_count == 0:
    DISPLAY "Created {success_count}/{success_count + failure_count} tracker sub-issues."
ELSE IF success_count > 0:
    DISPLAY "Created {success_count}/{success_count + failure_count} tracker sub-issues ({failure_count} failures)."
ELSE:
    DISPLAY WARN "All tracker sub-issue creation failed. Check MCP tracker connectivity. Pipeline continues without tracker integration for this decomposition."

// Pipeline continues to subtask execution -- NEVER block here.
```

---

## 2. Per-Tracker Issue Creation Parameters

The following table documents the exact MCP parameters for each tracker type. These are the same parameters used in scaffold Step 4e but adapted for decomposition subtasks (no epic/story hierarchy -- flat subtask list under a parent issue).

| Tracker | MCP Tool Pattern | Title Parameter | Description Parameter | Parent Parameter(s) | Notes |
|---------|-----------------|-----------------|----------------------|---------------------|-------|
| YouTrack | `mcp__youtrack__*` | `summary` | `description` | `parent: {ISSUE_ID}` | Standard sub-issue |
| Jira | `mcp__jira__*` or `mcp__atlassian__*` | `summary` | `description` | `parent: {ISSUE_ID}`, `issuetype: "Sub-task"` | Guard: if parent is Sub-task, omit parent param |
| Linear | `mcp__linear__*` | `title` | `description` | `parentId: {ISSUE_ID}` | UUID handled by MCP server |
| Redmine | `mcp__redmine__*` | `subject` | `description` | `parent_issue_id: {ISSUE_ID}` | Numeric ID |
| GitHub | `mcp__github__*` | `title` | `body` | N/A (standalone) | Title: `[{ISSUE_ID}] {title}` |
| Gitea | `mcp__gitea__*` or `mcp__forgejo__*` | `title` | `body` | N/A (standalone) | Title: `[{ISSUE_ID}] {title}` |

### Issue Description Template

For all tracker types, the sub-issue description/body follows this template:

```markdown
{subtask.scope}

Addresses: {subtask.maps_to[0]}, {subtask.maps_to[1]}, ...

Files: {subtask.files[0]}, {subtask.files[1]}, ...

Parent issue: {ISSUE_ID}
```

- If `maps_to` is empty, omit the "Addresses:" line.
- If `files` is empty, omit the "Files:" line.
- The "Parent issue:" line is always present for cross-reference (even for trackers with native parent-link, as a human-readable backup).

---

## 3. GitHub/Gitea Checklist Format

### Sentinel Comment

The sentinel comment uniquely identifies the checklist for a specific parent issue:

```
<!-- ceos-agents:decomposition-checklist:{ISSUE_ID} -->
```

Example for issue `#42`:
```
<!-- ceos-agents:decomposition-checklist:#42 -->
```

### Full Checklist Section

Appended to the end of the parent issue body:

```markdown

---
## Decomposition Subtasks
<!-- ceos-agents:decomposition-checklist:{ISSUE_ID} -->
- [ ] Validate input schema (#45)
- [ ] Add error handling (#46)
- [ ] Update API endpoint (#47)
```

### Idempotency

On subsequent runs (resume), the step checks for the sentinel before appending. If the sentinel is found via substring match in the parent issue body, the checklist append is skipped entirely. Individual subtask issues may still be created (their idempotency is handled by the YAML/state.json dual-store, not by the checklist).

### Race Condition Acceptance

The read-modify-write on the parent issue body has a theoretical race condition (concurrent modification). This is accepted as low-risk because:
1. Decomposition is rare (typically 0-1 per pipeline run)
2. The sentinel provides idempotency on retry
3. No other ceos-agents process writes to the same issue body concurrently

---

## 4. Idempotency Algorithm

### Decision Tree (per subtask)

```
READ .claude/decomposition/{ISSUE-ID}.yaml
  -> subtask.tracker_issue_id

IF tracker_issue_id != null:
  -> USE existing value, SKIP creation
  -> DONE

READ .ceos-agents/{ISSUE-ID}/state.json
  -> decomposition.subtasks[id].tracker_issue_id

IF state_value != null:
  -> RECOVER: write state_value back to YAML (in-memory)
  -> USE state_value, SKIP creation
  -> DONE

-> CREATE via MCP
  -> On success: WRITE to both YAML (in-memory) + state.json (atomic)
  -> On failure: SET null in both, LOG WARN, CONTINUE
```

### Why Dual-Store

| Scenario | YAML | State.json | Resolution |
|----------|------|------------|------------|
| Normal completion | has value | has value | Use YAML (primary) |
| Crash after state.json write, before YAML commit | null | has value | Recover from state.json |
| User runs `git checkout .` (destroys YAML) | destroyed | has value | Recover from state.json |
| User deletes `.ceos-agents/` (destroys state.json) | has value | destroyed | Use YAML (primary) |
| Both destroyed | null | null | Re-create (acceptable duplication) |

The "both destroyed" case results in duplicate tracker issues. This is a known limitation accepted as extremely unlikely and non-critical (duplicates can be manually closed).

---

## 5. Partial Failure Accumulator

### Pseudocode

```
SET results = { success: 0, failure: 0, items: [] }

FOR EACH subtask:
    TRY:
        issue_id = create_tracker_issue(subtask)
        write_dual_store(subtask.id, issue_id)
        results.success += 1
        results.items.push({ id: subtask.id, issue_id: issue_id })
    CATCH:
        LOG WARN "Could not create tracker sub-issue for '{subtask.title}': {error}"
        results.failure += 1
        results.items.push({ id: subtask.id, issue_id: null })

// Post-loop assessment
IF results.success == 0 AND results.failure > 0:
    LOG WARN "All tracker sub-issue creation failed. Check MCP tracker connectivity. Pipeline continues without tracker integration for this decomposition."
ELSE IF results.failure > 0:
    DISPLAY "Created {results.success}/{results.success + results.failure} tracker sub-issues ({results.failure} failures)."
ELSE:
    DISPLAY "Created {results.success}/{results.success} tracker sub-issues."

// GitHub/Gitea: checklist append (single operation, separate try/catch)
IF (tracker_type in ["github", "gitea"]) AND results.success > 0:
    TRY:
        append_checklist_to_parent(ISSUE_ID, results.items)
    CATCH:
        LOG WARN "Could not update parent issue body with checklist: {error}"

// Commit YAML if any succeeded
IF results.success > 0:
    git_commit_yaml()

// NEVER block -- always continue to subtask execution
```

### Failure Classification

| Failure Type | Action | Pipeline Impact |
|--------------|--------|-----------------|
| Single subtask MCP creation fails | WARN, continue | None |
| All subtask MCP creations fail | Elevated WARN | None |
| GitHub/Gitea checklist append fails | WARN | None |
| YAML git commit fails | WARN | Idempotency degraded (state.json still has values) |

---

## 6. YAML and State.json Write-Back Sequence

### Per-Subtask Write Order

After each successful MCP creation:

1. **State.json first (atomic):** Write `tracker_issue_id` to the matching subtask in `.ceos-agents/{ISSUE-ID}/state.json`. Follow atomic write protocol from `core/state-manager.md` (write to `.tmp`, rename).

2. **YAML in-memory:** Update the in-memory representation of `.claude/decomposition/{ISSUE-ID}.yaml` with the `tracker_issue_id` value. Do NOT write to disk yet.

The reason for state.json-first: if the process crashes, state.json (outside git) has the value for recovery. YAML is only committed once at the end.

### Post-Loop Write

After the entire creation loop:

3. **YAML disk write:** Write the complete YAML to `.claude/decomposition/{ISSUE-ID}.yaml` on disk.

4. **Git commit:** Stage and commit the YAML:
   ```bash
   git add .claude/decomposition/
   git commit -m "chore: link decomposition subtasks to tracker issues"
   ```

5. **State.json final update (optional):** If any additional metadata needs recording, update state.json. The per-subtask writes already happened in step 1, so this is only for aggregate data if needed.

### YAML Structure After Write

```yaml
issue_id: "PROJ-42"
decision: "DECOMPOSE"
strategy: "sequential"
subtasks:
  - id: "subtask-1"
    title: "Validate input schema"
    status: "pending"
    commit_hash: null
    restore_point: null
    tracker_issue_id: "PROJ-45"    # <-- NEW FIELD
    scope: "Add JSON schema validation..."
    files: ["src/validation.ts"]
    estimated_lines: 20
    acceptance_criteria: ["Schema validates all input"]
    maps_to: ["AC-1: Input is validated"]
    depends_on: []
  - id: "subtask-2"
    title: "Add error handling"
    status: "pending"
    commit_hash: null
    restore_point: null
    tracker_issue_id: "PROJ-46"    # <-- NEW FIELD
    scope: "Add try/catch blocks..."
    files: ["src/handler.ts"]
    estimated_lines: 15
    acceptance_criteria: ["Errors are caught"]
    maps_to: ["AC-2: Errors are handled"]
    depends_on: ["subtask-1"]
  - id: "subtask-3"
    title: "Update API endpoint"
    status: "pending"
    commit_hash: null
    restore_point: null
    tracker_issue_id: null          # <-- FAILED (MCP error)
    scope: "Update the REST endpoint..."
    files: ["src/api.ts"]
    estimated_lines: 30
    acceptance_criteria: ["API returns 200"]
    maps_to: ["AC-3: API works"]
    depends_on: ["subtask-1"]
```

---

## 7. Commit Strategy

### Single Commit After Upfront Creation Loop

The step produces exactly ONE git commit (or zero if all creations failed):

```bash
git add .claude/decomposition/
git commit -m "chore: link decomposition subtasks to tracker issues"
```

This commit:
- Contains only changes to `.claude/decomposition/{ISSUE-ID}.yaml` (the `tracker_issue_id` values)
- Is created AFTER the entire creation loop (not per-subtask)
- Serves as the idempotency checkpoint: on resume, committed `tracker_issue_id` values indicate already-created issues
- Is separate from subtask execution commits (which come later in the pipeline)

If `success_count == 0` (all failed), no commit is made (no changes to commit).

---

## 8. Triple Gate Conditions

The step is skipped entirely (silently, no WARN) when any of these three conditions is false:

| # | Condition | Source | Evaluation |
|---|-----------|--------|------------|
| 1 | `decomposition.decision == "DECOMPOSE"` | In-memory from previous step (or state.json on resume) | If SINGLE_PASS, no subtasks exist, nothing to create |
| 2 | `Create tracker subtasks == "enabled"` | Automation Config -> Decomposition section (default: `"enabled"`) | If disabled by user, respect the setting |
| 3 | `tracker_effective_status == "ready"` | MCP pre-flight check result (Step 0 of each pipeline) | If tracker MCP is not available, cannot create issues |

All three must be true for the step to execute. The evaluation order is: 1 -> 2 -> 3 (short-circuit on first false).

### Why No WARN on Skip

Skipping is expected behavior in common scenarios:
- Most bugs are SINGLE_PASS (no decomposition) -- gate 1 rejects
- Users who disable the feature expect silence -- gate 2 rejects
- Projects without tracker integration (scaffold with `--infra later`) -- gate 3 rejects

A WARN would create noise in the majority case.

---

## 9. Files to Modify

### Skill Files (3 files, inline step)

| File | Change |
|------|--------|
| `skills/implement-feature/SKILL.md` | Insert Step 5a between Step 5 and Step 6 |
| `skills/fix-ticket/SKILL.md` | Insert Step 4b-tracker between Step 4b and Step 4c |
| `skills/fix-bugs/SKILL.md` | Insert Step 3b-tracker between Step 3b and Step 3c |

### Schema and Config Files

| File | Change |
|------|--------|
| `state/schema.md` | Add `tracker_issue_id` row to Subtask Object Fields table |
| `CLAUDE.md` | Add `Create tracker subtasks` to Decomposition optional keys table |
| `docs/reference/automation-config.md` | Add `Create tracker subtasks` to Decomposition section documentation |

### Resume Skill

| File | Change |
|------|--------|
| `skills/resume-ticket/SKILL.md` | Document that `DECOMPOSE_PARTIAL` checkpoint reads `tracker_issue_id` and skips already-created subtask issues in the tracker creation step |

### Documentation

| File | Change |
|------|--------|
| `CHANGELOG.md` | v6.4.0 entry documenting the feature |
| `docs/reference/trackers.md` | No change needed (Sub-Issue Capabilities table already has required information) |
| `docs/plans/roadmap.md` | Update `tracker_id` references to `tracker_issue_id` |

---

## 10. Non-Goals (Explicit Exclusions)

1. **No core contract extraction.** The step is inlined in each skill. If a fourth consumer appears, extraction to `core/subtask-tracker.md` can happen then.
2. **No tracker-side query for idempotency.** Too slow, unreliable, and unnecessary given dual-store.
3. **No per-subtask commit.** Single commit after the entire loop.
4. **No parent link verification.** The MCP return value confirms creation. Read-back verification (as in scaffold Step 4e) is not required for decomposition subtasks.
5. **No issue state transition.** Created sub-issues are NOT transitioned to "In Progress" -- they represent planned work. The `On start set` transition applies when the subtask execution loop processes each subtask.
