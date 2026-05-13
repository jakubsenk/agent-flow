# Design — v6.7.2 Pipeline Consistency & Dedup

This document specifies the exact before/after text for every change in v6.7.2. Each change includes file path, line references, and verbatim replacement text.

---

## WI-4: Documentation Fixes

### Fix 1 — `core/fix-verification.md` L5: Mode-Neutral Purpose

**Before (L5):**
```
Run the verify command after PR merge to confirm the fix works on the target branch.
```

**After (L5):**
```
Run the verify command after PR merge to confirm the changes work on the target branch.
```

### Fix 2 — `core/fix-verification.md` L21: Mode-Neutral Success Comment

**Before (L19-22):**
```
5. If command succeeds → post success comment to the issue:
   ```
   [ceos-agents] ✅ Fix verified. Verify command: `{command}`. Output: {first 500 chars}.
   ```
```

**After (L19-22):**
```
5. If command succeeds → post success comment to the issue:
   ```
   [ceos-agents] ✅ Verified. Verify command: `{command}`. Output: {first 500 chars}.
   ```
```

### Fix 3 — `core/fix-verification.md` L26: Mode-Neutral Failure Comment

**Before (L24-26):**
```
6. If command fails → post failure comment to the issue:
   ```
   [ceos-agents] ❌ Fix verification failed.
```

**After (L24-26):**
```
6. If command fails → post failure comment to the issue:
   ```
   [ceos-agents] ❌ Verification failed.
```

### Fix 4 — `core/state-manager.md` L38-43: Inline Heuristic Detection Table

**Before (L38-43):**
```markdown
### Resume Process
1. Read state.json. If exists:
   - Find the first step with status "in_progress" or "pending" after all "completed" steps
   - Return resume_point (step name) and resume_context (triage AC, complexity, iteration counts)
2. If state.json does not exist:
   - Fall back to heuristic detection (see resume-ticket.md existing logic)
   - Return resume_point from heuristic with reduced context
```

**After (L38-52):**
```markdown
### Resume Process
1. Read state.json. If exists:
   - Find the first step with status "in_progress" or "pending" after all "completed" steps
   - Return resume_point (step name) and resume_context (triage AC, complexity, iteration counts)
2. If state.json does not exist:
   - Fall back to heuristic detection using these checkpoints (priority order):

     | Checkpoint | Signal | Skips |
     |-----------|--------|---------|
     | `PUBLISHED` | Open PR exists for branch | Entire pipeline |
     | `DECOMPOSE_PARTIAL` | `.claude/decomposition/{ISSUE-ID}.yaml` exists | Triage + analysis + completed subtasks |
     | `POST_REVIEW` | Branch + reviewer approval comment | Triage + code-analyst + fixer + reviewer |
     | `POST_FIX` | Branch with commits above base | Triage + code-analyst + fixer |
     | `POST_ANALYSIS` | Branch exists + triage comment | Triage + code-analyst |
     | `POST_TRIAGE` | Triage comment exists | Triage |

   - Return resume_point from heuristic with reduced context (no AC list, no iteration counts)
```

### Fix 5 — `state/schema.md`: e2e_test Section Parity

#### JSON Example

**Before (L104-106):**
```json
  "e2e_test": {
    "status": "pending"
  },
```

**After (L104-109):**
```json
  "e2e_test": {
    "status": "pending",
    "verdict": null,
    "result_path": null,
    "attempts": 0
  },
```

#### Field Definition Table

**Before (L225-226):**
```markdown
| `e2e_test` | object | Yes | — | E2E-test-engineer phase state. |
| `e2e_test.status` | string | Yes | `"pending"` | Phase status. See Step Status Enum. |
```

**After (L225-229):**
```markdown
| `e2e_test` | object | Yes | — | E2E-test-engineer phase state. |
| `e2e_test.status` | string | Yes | `"pending"` | Phase status. See Step Status Enum. |
| `e2e_test.verdict` | string or null | No | `null` | E2E test outcome: `PASSED` or `FAILED`. |
| `e2e_test.result_path` | string or null | No | `null` | Path to the E2E test result file (if stored). |
| `e2e_test.attempts` | integer | No | `0` | Number of E2E test attempts executed. |
```

### Fix 6 — `core/fixer-reviewer-loop.md` L44: Complete Caller Reference

**Before (L43-44):**
```markdown
- `NEEDS_DECOMPOSITION` → returned to caller; caller handles decomposition logic (see `core/decomposition-heuristics.md` and `skills/fix-ticket/SKILL.md` step 5).
```

**After (L43-44):**
```markdown
- `NEEDS_DECOMPOSITION` → returned to caller; caller handles decomposition logic (see `core/decomposition-heuristics.md`). Callers: `skills/fix-ticket/SKILL.md` step 5 (revert + re-decompose, max 1), `skills/fix-bugs/SKILL.md` step 4 (revert + re-decompose per-bug, max 1), `skills/implement-feature/SKILL.md` step 6b (block current subtask or block issue in single-pass).
```

---

## WI-1: Tracker Subtask Extraction

### New File: `core/tracker-subtask-creator.md`

**Full content of the new file:**

```markdown
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
| Gitea | `mcp__gitea__*` or `mcp__forgejo__*` | `title` | `body` | N/A (standalone) | Title: `[{issue_id}] {title}` |

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
```

### Caller Replacement: `skills/fix-ticket/SKILL.md` step 4b-tracker

**Before (L207-388, the entire step 4b-tracker including Triple gate, Required in-memory values, Process pseudocode block, Per-Tracker table, and Issue Description Template):**

The block starting at line 207 with `### 4b-tracker. Create tracker subtasks` through line 388 ending with `- Follow \`core/mcp-body-formatting.md\` when constructing multi-line MCP tool parameters.`

**After (replacement for the entire block):**

```markdown
### 4b-tracker. Create tracker subtasks

Follow `core/tracker-subtask-creator.md`.

Required in-memory values: `ISSUE_ID`, `tracker_type`, `tracker_project`, `tracker_effective_status`, `decomposition_decision`, `create_tracker_subtasks_config`, subtask list, YAML path (`.claude/decomposition/{ISSUE-ID}.yaml`), state.json path (`.ceos-agents/{ISSUE-ID}/state.json`).
```

### Caller Replacement: `skills/implement-feature/SKILL.md` step 5a

**Before (L266-448, the entire step 5a including Triple gate, Required in-memory values, Process pseudocode block, Per-Tracker table, Issue Description Template, and mcp-body-formatting reference):**

The block starting at line 266 with `### 5a. Create tracker subtasks` through line 448 ending with `Follow \`core/mcp-body-formatting.md\` when constructing multi-line MCP tool parameters.`

**After (replacement for the entire block):**

```markdown
### 5a. Create tracker subtasks

Follow `core/tracker-subtask-creator.md`.

Required in-memory values: `ISSUE_ID`, `tracker_type`, `tracker_project`, `tracker_effective_status`, `decomposition_decision`, `create_tracker_subtasks_config`, subtask list, YAML path (`.claude/decomposition/{ISSUE-ID}.yaml`), state.json path (`.ceos-agents/{ISSUE-ID}/state.json`).
```

### Caller Replacement: `skills/fix-bugs/SKILL.md` step 3b-tracker

**Before (L224-406, the entire step 3b-tracker including Triple gate, Required in-memory values, Process pseudocode block, Per-Tracker table, Issue Description Template, and mcp-body-formatting reference):**

The block starting at line 224 with `### 3b-tracker. Create tracker subtasks` through line 406 ending with `Follow \`core/mcp-body-formatting.md\` when constructing multi-line MCP tool parameters.`

**After (replacement for the entire block):**

```markdown
### 3b-tracker. Create tracker subtasks

Follow `core/tracker-subtask-creator.md`.

Required in-memory values: `ISSUE_ID`, `tracker_type`, `tracker_project`, `tracker_effective_status`, `decomposition_decision`, `create_tracker_subtasks_config`, subtask list, YAML path (`.claude/decomposition/{ISSUE-ID}.yaml`), state.json path (`.ceos-agents/{ISSUE-ID}/state.json`).
```

---

## WI-3: Block Handler Inline Removal (implement-feature)

### `skills/implement-feature/SKILL.md` step X

**Before (L642-666):**
```markdown
### X. Block handler

Follow `core/block-handler.md`:

1. Run `ceos-agents:rollback-agent` (Task tool, model: haiku) — revert git changes
2. Set issue state to Blocked (State transitions → Blocked)
3. **On block action** (per Error Handling → On block):
   - `comment` (default): Add a Block comment to the issue tracker (see below)
   - `close`: Add a Block comment + close the issue
   - Other value: interpret as a custom action (always add a comment)
4. Add Block comment to the issue tracker:
   ```
   [ceos-agents] 🔴 Pipeline Block
   Agent: {agent name}
   Step: {pipeline step}
   Reason: {max 2 sentences}
   Detail: {error output}
   Recommendation: {what human should do}
   ```
5. If Notifications → Webhook URL exists and On events contains `issue-blocked`:
   ```bash
   curl -X POST {webhook_url} -H "Content-Type: application/json" -d '{"event":"issue-blocked","issue":"{issue_id}","agent":"{agent}","reason":"{reason}"}'
   ```

6. Update `state.json`: set top-level `status` to `"blocked"`, write `block` object with `{agent, step, reason, detail, recommendation}`. Follow atomic write protocol from `core/state-manager.md`.
```

**After (4 lines, matching fix-ticket L605-609):**
```markdown
### X. Block handler

Follow `core/block-handler.md` for the block protocol.

Update `state.json`: set top-level `status` to `"blocked"`, write `block` object with `{agent, step, reason, detail, recommendation}`. Follow atomic write protocol from `core/state-manager.md`.
```

---

## WI-2: Webhook Format Alignment

### `skills/implement-feature/SKILL.md` step 10a

**Before (L617-623):**
```markdown
#### 10a. Post-publish hook + webhook

Follow `core/post-publish-hook.md`. If Hooks → Post-publish exists: run the command via Bash.
If Notifications → Webhook URL exists and On events contains `pr-created`:
```bash
curl -X POST {webhook_url} -H "Content-Type: application/json" -d '{"event":"pr-created","issue":"{issue_id}","pr":"{pr_url}"}'
```
```

**After (2 lines):**
```markdown
#### 10a. Post-publish hook + webhook

Follow `core/post-publish-hook.md` for hook execution and webhook firing.
```

### `skills/fix-bugs/SKILL.md` step 8b

**Before (L610-618):**
```markdown
### 8b. Webhook — PR created

If Notifications → Webhook URL exists and `pr-created` is in On events:
```bash
curl --max-time 5 --retry 0 -X POST -H "Content-Type: application/json" \
  -d '{"event":"pr-created","issue_id":"{issue}","pr_url":"{url}","timestamp":"{ISO8601}"}' \
  "{Webhook URL}"
```
Failure → warning, must not stop the pipeline.
```

**After (3 lines):**
```markdown
### 8b. Webhook — PR created

Handled by `core/post-publish-hook.md` (invoked in step 8a above). No additional action needed.
```

### `skills/fix-bugs/SKILL.md` step X

**Before (L667-710):**
```markdown
### X. Block handler

Follow `core/block-handler.md` for the block protocol.

On block from fixer/reviewer/test-engineer/build/hook/custom agent:

1. **Rollback:** Run `ceos-agents:rollback-agent` (Task tool, model: haiku).
   Context: `Agent: {name}. Step: {step}. Reason: {reason}. Detail: {output}. Recommendation: {recommendation}. Execution context: {worktree_path if worktree mode} | CWD (if sequential).`
   - DO NOT rollback on block from triage/code-analyst — no git changes to revert

2. **Set issue state to Blocked** (State transitions → Blocked)
   After the status-set MCP call, follow `core/status-verification.md` to verify the transition succeeded.

3. **On block action** (per Error Handling → On block):
   - `comment` (default): Add a Block comment to the issue tracker (see below)
   - `close`: Add a Block comment + close the issue
   - Other value: interpret as a custom action (always add a comment)

4. **Add Block comment** to the issue tracker:
   ```
   [ceos-agents] 🔴 Pipeline Block
   Agent: {agent name}
   Step: {pipeline step}
   Reason: {max 2 sentences}
   Detail: {error output}
   Recommendation: {what human should do}
   ```

Follow `core/mcp-body-formatting.md` when constructing the comment string.

5. **Webhook — issue-blocked:** If Notifications → Webhook URL exists and `issue-blocked` is in On events:
   ```bash
   curl --max-time 5 --retry 0 -X POST -H "Content-Type: application/json" \
     -d '{"event":"issue-blocked","issue_id":"{issue}","agent":"{agent}","reason":"{reason}","timestamp":"{ISO8601}"}' \
     "{Webhook URL}"
   ```

6. Update `.ceos-agents/{ISSUE-ID}/state.json`: set top-level `status` to `"blocked"`, write `block` object with `{agent, step, reason, detail, recommendation}`. Follow atomic write protocol from `core/state-manager.md`.

7. **Block counter:** Increment `block_count`. If `Max blocked per run` is not `unlimited` and `block_count >= Max blocked per run`:
   - Display: "Max blocked per run ({N}) reached. Remaining {M} bugs skipped."
   - Skip to step 9 (Summary) — DO NOT process remaining bugs.

8. Continue with next bug.
```

**After:**
```markdown
### X. Block handler

Follow `core/block-handler.md` for the block protocol.

**Skill-specific context:**
- Rollback execution context: `{worktree_path}` (parallel mode) or `CWD` (sequential mode). Pass this in the rollback-agent Task context string.
- State path: `.ceos-agents/{ISSUE-ID}/state.json` (per-issue, not per-run).
- Block counter: After core block protocol completes, increment `block_count`. If `Max blocked per run` is not `unlimited` and `block_count >= Max blocked per run`:
  - Display: "Max blocked per run ({N}) reached. Remaining {M} bugs skipped."
  - Skip to step 9 (Summary) — DO NOT process remaining bugs.
- Continue with next bug.
```

---

## WI-Cross: CLAUDE.md

### Core Contract Count

**Before (L27):**
```
- `core/` — 14 shared pipeline pattern contracts
```

**After (L27):**
```
- `core/` — 15 shared pipeline pattern contracts
```

---

## WI-Cross: Roadmap Entry

### `docs/plans/roadmap.md`

Add one line to the appropriate section (PATCH backlog or known issues):

```
- fix-bugs: YOLO references inherited from fix-ticket but --yolo flag not supported (latent, no user impact until --yolo is added to fix-bugs)
```
