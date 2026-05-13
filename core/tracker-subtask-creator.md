# Tracker Subtask Creator

## Purpose

Create tracker sub-issues from a decomposition plan, with idempotency, per-tracker MCP dispatch, and dual-store (YAML + state.json) persistence.

## Input Contract

| Field | Type | Notes |
|-------|------|-------|
| issue_id | string | Parent issue tracker ID |
| tracker_type | string | From Automation Config → Issue Tracker → Type |
| tracker_project | string | From Automation Config → Issue Tracker → Project |
| tracker_effective_status | string | `"ready"` or `"unavailable"` — set by caller from MCP pre-flight output (`core/mcp-preflight.md`) |
| decomposition_decision | string | `"DECOMPOSE"` or `"SINGLE_PASS"` |
| create_tracker_subtasks_config | string | Value of Decomposition → Create tracker subtasks (default: `"enabled"`) |
| subtask_list | object[] | Subtask objects from decomposition (in topological order) |
| yaml_path | string | Path to `.claude/decomposition/{ISSUE-ID}.yaml` |
| state_json_path | string | Path to `.ceos-agents/{ISSUE-ID}/state.json` |

## Process

### Triple Gate

Skip this procedure entirely (no WARN, expected behavior) if ANY of:
1. decomposition_decision != "DECOMPOSE"
2. create_tracker_subtasks_config == "disabled"
3. tracker_effective_status != "ready"

### Subtask Creation Loop

```
SET success_count = 0
SET failure_count = 0
SET created_issues = []  // list of {subtask_id, tracker_issue_id, title}

FOR EACH subtask IN subtask_list (topological order):

    // --- Idempotency check (YAML-first, state.json fallback) ---
    SET yaml_value = read subtask.tracker_issue_id from {yaml_path}
    IF yaml_value != null:
        LOG "[SKIP] Subtask '{subtask.title}' already has tracker issue: {yaml_value}"
        ADD {subtask.id, yaml_value, subtask.title} to created_issues
        success_count += 1
        CONTINUE

    SET state_value = read decomposition.subtasks[subtask.id].tracker_issue_id from {state_json_path}
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
        // - "Parent issue: {issue_id}"

    // --- Create issue via MCP (tracker-specific) ---
    TRY:
        IF tracker_type == "youtrack":
            result = MCP create_issue(
                project: {tracker_project},
                summary: issue_title,
                description: issue_description,
                parent: {issue_id}
            )

        ELSE IF tracker_type == "jira":
            // Jira nested sub-task guard
            parent_issue = MCP get_issue({issue_id})
            IF parent_issue.issuetype == "Sub-task":
                LOG WARN "Parent issue {issue_id} is a Sub-task -- creating flat issue without parent link."
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
                    parent: {issue_id},
                    issuetype: "Sub-task"
                )

        ELSE IF tracker_type == "linear":
            result = MCP create_issue(
                teamId: {tracker_project},
                title: issue_title,
                description: issue_description,
                parentId: {issue_id}
            )

        ELSE IF tracker_type == "redmine":
            result = MCP create_issue(
                project_id: {tracker_project},
                subject: issue_title,
                description: issue_description,
                parent_issue_id: {issue_id}
            )

        ELSE IF tracker_type == "github" OR tracker_type == "gitea":
            result = MCP create_issue(
                owner: {owner from tracker_project},
                repo: {repo from tracker_project},
                title: "[{issue_id}] {issue_title}",
                body: issue_description
            )

        // --- Write to dual store ---
        SET new_tracker_issue_id = result.issue_id  // or result.key, result.number depending on tracker
        WRITE new_tracker_issue_id to subtask.tracker_issue_id in YAML (in-memory)
        WRITE new_tracker_issue_id to decomposition.subtasks[subtask.id].tracker_issue_id in {state_json_path}
            // Follow atomic write protocol from core/state-manager.md
            // State.json written IMMEDIATELY after each successful creation (per-subtask, atomic)
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
        SET parent_body = MCP get_issue({issue_id}).body
        SET sentinel = "<!-- ceos-agents:decomposition-checklist:{issue_id} -->"
        IF parent_body CONTAINS sentinel:
            LOG "[SKIP] Decomposition checklist already exists in parent issue body."
        ELSE:
            SET checklist = "\n\n---\n## Decomposition Subtasks\n{sentinel}\n"
            FOR EACH item IN created_issues WHERE item.tracker_issue_id != null:
                checklist += "- [ ] {item.title} (#{item.tracker_issue_id})\n"
            END FOR
            SET new_body = parent_body + checklist
            MCP update_issue({issue_id}, body: new_body)
    CATCH error:
        LOG WARN "Could not update parent issue body with checklist: {error}. Standalone sub-issues may still exist."

// --- Commit YAML ---
IF success_count > 0:
    git add -A
    git commit -m "chore: link decomposition subtasks to tracker issues"

// --- Result display ---
IF failure_count == 0:
    DISPLAY "Created {success_count}/{success_count + failure_count} tracker sub-issues."
ELSE IF success_count > 0:
    DISPLAY "Created {success_count}/{success_count + failure_count} tracker sub-issues ({failure_count} failures)."
ELSE:
    DISPLAY WARN "All tracker sub-issue creation failed. Check MCP tracker connectivity. Pipeline continues without tracker integration for this decomposition."

// Pipeline continues -- NEVER block here.
```

## Per-Tracker Issue Creation Parameters

| Tracker | MCP Tool Pattern | Title Parameter | Description Parameter | Parent Parameter(s) | Notes |
|---------|-----------------|-----------------|----------------------|---------------------|-------|
| YouTrack | `mcp__youtrack__*` | `summary` | `description` | `parent: {issue_id}` | Standard sub-issue |
| Jira | `mcp__jira__*` or `mcp__atlassian__*` | `summary` | `description` | `parent: {issue_id}`, `issuetype: "Sub-task"` | Guard: if parent is Sub-task, omit parent param and create flat issue without parent link |
| Linear | `mcp__linear__*` | `title` | `description` | `parentId: {issue_id}` | UUID handled by MCP server |
| Redmine | `mcp__redmine__*` | `subject` | `description` | `parent_issue_id: {issue_id}` | Numeric ID |
| GitHub | `mcp__github__*` | `title` | `body` | N/A (standalone) | Title: `[{issue_id}] {title}` |
| Gitea | `mcp__gitea__*` | `title` | `body` | N/A (standalone) | Title: `[{issue_id}] {title}` |

## Issue Description Template

```markdown
{subtask.scope}

Addresses: {subtask.maps_to[0]}, {subtask.maps_to[1]}, ...

Files: {subtask.files[0]}, {subtask.files[1]}, ...

Parent issue: {issue_id}
```

- If `maps_to` is empty, omit the "Addresses:" line.
- If `files` is empty, omit the "Files:" line.
- The "Parent issue:" line is always present.

Follow `core/mcp-body-formatting.md` when constructing multi-line MCP tool parameters.

## Output Contract

- `success_count` (integer): number of tracker issues created or recovered
- `failure_count` (integer): number of creation failures
- `created_issues` (list): `{subtask_id, tracker_issue_id, title}` tuples
- YAML committed if success_count > 0
- Pipeline continues regardless of outcome. NEVER block here.

## Failure Handling

- Individual subtask creation failure → log warning, increment failure_count, continue loop
- GitHub/Gitea checklist update failure → log warning, continue (standalone sub-issues still exist)
- All creations failed → display warning message, pipeline continues
- YAML commit failure → log warning, continue (tracker issues exist, YAML linkage lost — recoverable on resume via state.json fallback)
