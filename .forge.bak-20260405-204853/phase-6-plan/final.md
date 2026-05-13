# Implementation Plan: Decomposition Subtask Tracker Creation (v6.4.0)

## Overview

This plan implements the Decomposition Subtask Tracker Creation feature across 15 tasks in 4 groups. The feature adds a new pipeline step that creates tracker sub-issues for each decomposition subtask, with per-tracker parent linking, dual-store idempotency, partial failure handling, and GitHub/Gitea checklist support.

**Total estimated change:** ~280 lines across 12 files + 9 test files copied.

---

## Canonical Step Template

This is the **single source of truth** for the new step content. Each skill adapts only the heading (step number). The template below uses `{STEP-NUM}` as a placeholder.

````markdown
### {STEP-NUM}. Create tracker subtasks

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

**Per-Tracker Issue Creation Parameters:**

| Tracker | MCP Tool Pattern | Title Parameter | Description Parameter | Parent Parameter(s) | Notes |
|---------|-----------------|-----------------|----------------------|---------------------|-------|
| YouTrack | `mcp__youtrack__*` | `summary` | `description` | `parent: {ISSUE_ID}` | Standard sub-issue |
| Jira | `mcp__jira__*` or `mcp__atlassian__*` | `summary` | `description` | `parent: {ISSUE_ID}`, `issuetype: "Sub-task"` | Guard: if parent is Sub-task, omit parent param and create flat issue without parent link |
| Linear | `mcp__linear__*` | `title` | `description` | `parentId: {ISSUE_ID}` | UUID handled by MCP server |
| Redmine | `mcp__redmine__*` | `subject` | `description` | `parent_issue_id: {ISSUE_ID}` | Numeric ID |
| GitHub | `mcp__github__*` | `title` | `body` | N/A (standalone) | Title: `[{ISSUE_ID}] {title}` |
| Gitea | `mcp__gitea__*` or `mcp__forgejo__*` | `title` | `body` | N/A (standalone) | Title: `[{ISSUE_ID}] {title}` |

**Issue Description Template:**

```markdown
{subtask.scope}

Addresses: {subtask.maps_to[0]}, {subtask.maps_to[1]}, ...

Files: {subtask.files[0]}, {subtask.files[1]}, ...

Parent issue: {ISSUE_ID}
```

- If `maps_to` is empty, omit the "Addresses:" line.
- If `files` is empty, omit the "Files:" line.
- The "Parent issue:" line is always present.
````

---

## Group 1: Foundation (sequential)

Foundation tasks establish the state schema field and config contract before any skill can reference them.

### task-001: State schema — add `tracker_issue_id` field

| Attribute | Value |
|-----------|-------|
| **File** | `state/schema.md` |
| **Insertion point** | Line 207 — after the `maps_to` row in the Subtask Object Fields table |
| **What to change** | Add a new row to the Subtask Object Fields table |
| **Content to insert** | `\| \`tracker_issue_id\` \| string or null \| No \| \`null\` \| Tracker issue ID created for this subtask (e.g., \`"PROJ-45"\` for YouTrack/Jira, \`"#123"\` for GitHub/Gitea). Populated by "Create tracker subtasks" step. Used as idempotency guard on resume. \|` |
| **Estimated lines** | 1 |
| **Dependencies** | None |
| **Parallelizable** | No (must complete before Group 2) |

### task-002: Config contract in CLAUDE.md — add `Create tracker subtasks` key

| Attribute | Value |
|-----------|-------|
| **File** | `CLAUDE.md` |
| **Insertion point** | Line 151 — the Decomposition row in the optional sections table |
| **What to change** | Update the Decomposition row to include the new key. Change `| Decomposition | Max subtasks, Fail strategy, Commit strategy | 7, fail-fast, squash |` to `| Decomposition | Max subtasks, Fail strategy, Commit strategy, Create tracker subtasks | 7, fail-fast, squash, enabled |` |
| **Estimated lines** | 1 (modified in-place) |
| **Dependencies** | None |
| **Parallelizable** | Yes (independent of task-001) |

### task-003: Config contract in CLAUDE.md — update pipeline diagrams

| Attribute | Value |
|-----------|-------|
| **File** | `CLAUDE.md` |
| **Insertion points** | Lines 53-59 (Feature Pipeline diagram) and lines 38-44 (Bug-Fix Pipeline diagram) |
| **What to change** | In the Feature Pipeline diagram (lines 53-59), add `[Create tracker subtasks]` after `[Decomposition decision]`. In the Bug-Fix Pipeline diagram, no change is needed because the bug-fix pipeline shows the high-level flow and the decomposition sub-step is already implicit inside `[Decomposition decision]`. The feature pipeline should read: `→ [AC coverage check] → [Decomposition decision] → [Create tracker subtasks]` before `→ FIXER` |
| **Estimated lines** | ~2 (modify existing lines) |
| **Dependencies** | task-002 |
| **Parallelizable** | No (sequential with task-002, same file) |

**Verification Gate after Group 1:**
```bash
# Verify task-001: tracker_issue_id in state schema
grep "tracker_issue_id" state/schema.md | grep "string or null"
# Must return 1 match

# Verify task-002: Create tracker subtasks in CLAUDE.md Decomposition row
grep "Create tracker subtasks" CLAUDE.md
# Must return at least 1 match

# Verify task-003: Pipeline diagram updated
grep "Create tracker subtasks" CLAUDE.md | grep -c "tracker"
# Must return >= 2 matches (config row + pipeline diagram)

# Verify naming guard: no bare tracker_id as field name
grep "tracker_id[^_]" state/schema.md
# Must return 0 matches
```

---

## Group 2: Skills (3 parallel tasks)

These tasks insert the canonical step template into each skill file and update the YAML save instructions. All three are independent and can execute in parallel.

### task-004: implement-feature — add Step 5a

| Attribute | Value |
|-----------|-------|
| **File** | `skills/implement-feature/SKILL.md` |
| **Insertion point** | Between line 244 (end of Step 5 — Decomposition decision, last `state.json` update) and line 246 (heading `### 6. Subtask execution (or single-pass)`) |
| **What to change** | (a) Insert the canonical step template from this plan with `{STEP-NUM}` replaced by `5a`. (b) On line 239, update the "Save task tree" instruction from `runtime fields \`status: "pending"\`, \`commit_hash: null\`, \`restore_point: null\`` to `runtime fields \`status: "pending"\`, \`commit_hash: null\`, \`restore_point: null\`, \`tracker_issue_id: null\``. (c) Add `Create tracker subtasks` to the Decomposition config reading on line 33 (add to the existing Decomposition bullet: `Create tracker subtasks (default: enabled)`). |
| **Estimated lines** | ~80 (step insertion) + 2 (YAML field + config read) |
| **Dependencies** | task-001, task-002 |
| **Parallelizable** | Yes (with task-005, task-006) |

### task-005: fix-ticket — add Step 4b-tracker

| Attribute | Value |
|-----------|-------|
| **File** | `skills/fix-ticket/SKILL.md` |
| **Insertion point** | Between line 200 (end of Step 4b — last `state.json` update for AUTO→SINGLE_PASS fallthrough) and line 202 (heading `### 4c. Subtask execution (decomposition)`) |
| **What to change** | (a) Insert the canonical step template with `{STEP-NUM}` replaced by `4b-tracker`. (b) On line 184, update "Save task tree" from `runtime fields \`status: "pending"\`, \`commit_hash: null\`, \`restore_point: null\`` to include `\`tracker_issue_id: null\``. (c) Add `Create tracker subtasks (default: enabled)` to the Decomposition config reading on line 43. |
| **Estimated lines** | ~80 (step insertion) + 2 (YAML field + config read) |
| **Dependencies** | task-001, task-002 |
| **Parallelizable** | Yes (with task-004, task-006) |

### task-006: fix-bugs — add Step 3b-tracker

| Attribute | Value |
|-----------|-------|
| **File** | `skills/fix-bugs/SKILL.md` |
| **Insertion point** | Between line 187 (end of Step 3b — last AC coverage check block) and line 189 (heading `### 3c. Subtask execution (decomposition, per-bug)`) |
| **What to change** | (a) Insert the canonical step template with `{STEP-NUM}` replaced by `3b-tracker`. (b) On line 174, update "Save task tree" from `runtime fields \`status: "pending"\`, \`commit_hash: null\`, \`restore_point: null\`` to include `\`tracker_issue_id: null\``. (c) Add `Create tracker subtasks (default: enabled)` to the Decomposition config reading on line 37. |
| **Estimated lines** | ~80 (step insertion) + 2 (YAML field + config read) |
| **Dependencies** | task-001, task-002 |
| **Parallelizable** | Yes (with task-004, task-005) |

### task-007: resume-ticket — add tracker_issue_id awareness

| Attribute | Value |
|-----------|-------|
| **File** | `skills/resume-ticket/SKILL.md` |
| **Insertion point** | Lines 59-68 — the `### Checkpoint: DECOMPOSE_PARTIAL` section |
| **What to change** | After existing step 2 ("Find the last completed subtask"), add a new sub-step: "2a. For each subtask, check `tracker_issue_id` — if non-null, the tracker sub-issue already exists and will not be re-created during the Create tracker subtasks step. If null, the step will attempt creation for that subtask." This documents that `tracker_issue_id` values in the YAML are preserved across resume and used as idempotency guards. |
| **Estimated lines** | ~3 |
| **Dependencies** | task-001 |
| **Parallelizable** | Yes (with task-004, task-005, task-006) |

**Verification Gate after Group 2:**
```bash
# FC-1: Step 5a heading in implement-feature
grep -n "### 5a\." skills/implement-feature/SKILL.md
# Must return exactly 1 match with line > 244 and < line of "### 6."

# FC-2: Step 4b-tracker heading in fix-ticket
grep -n "4b-tracker" skills/fix-ticket/SKILL.md
# Must return at least 1 match with line > 200 and < line of "### 4c."

# FC-3: Step 3b-tracker heading in fix-bugs
grep -n "3b-tracker" skills/fix-bugs/SKILL.md
# Must return at least 1 match with line > 187 and < line of "### 3c."

# FC-4: Triple gate in all 3 skills
grep -c "decomposition.decision" skills/implement-feature/SKILL.md  # >= 2
grep -c "Create tracker subtasks" skills/implement-feature/SKILL.md  # >= 1
grep -c "tracker_effective_status" skills/implement-feature/SKILL.md  # >= 1
# Repeat for fix-ticket and fix-bugs

# FC-5: Per-tracker parent parameters in all 3 skills
for f in skills/{implement-feature,fix-ticket,fix-bugs}/SKILL.md; do
  grep -q "parent:" "$f" && grep -q "issuetype.*Sub-task" "$f" && \
  grep -q "parentId:" "$f" && grep -q "parent_issue_id:" "$f" && echo "PASS: $f"
done
# Must print PASS for all 3

# FC-6: Jira nested sub-task guard
grep -l "Sub-task.*flat issue\|flat issue.*Sub-task\|parent.*Sub-task.*WARN\|Sub-task.*without parent" skills/{implement-feature,fix-ticket,fix-bugs}/SKILL.md
# Must return all 3 files

# FC-7: tracker_issue_id in state schema (already verified in Gate 1)

# FC-8: tracker_issue_id: null in YAML init
grep "tracker_issue_id.*null" skills/{implement-feature,fix-ticket,fix-bugs}/SKILL.md
# Must return at least 1 match per file

# FC-11: Idempotency algorithm (YAML + state.json)
grep -l "state.json.*fallback\|state.json.*recover\|YAML.*state.json" skills/{implement-feature,fix-ticket,fix-bugs}/SKILL.md
# Must return all 3 files

# FC-12: Partial failure accumulator
grep -l "NEVER block\|never block\|Pipeline continues" skills/{implement-feature,fix-ticket,fix-bugs}/SKILL.md
# Must return all 3 files
grep -l "Created.*tracker sub-issues" skills/{implement-feature,fix-ticket,fix-bugs}/SKILL.md
# Must return all 3 files

# FC-13: GitHub/Gitea checklist sentinel
grep -l "ceos-agents:decomposition-checklist" skills/{implement-feature,fix-ticket,fix-bugs}/SKILL.md
# Must return all 3 files

# FC-14: Single git commit
grep -l "git commit.*link decomposition\|git commit.*tracker" skills/{implement-feature,fix-ticket,fix-bugs}/SKILL.md
# Must return all 3 files

# FC-15: maps_to / Addresses in sub-issue description
grep -l "Addresses:" skills/{implement-feature,fix-ticket,fix-bugs}/SKILL.md
# Must return all 3 files

# FC-16: Resume ticket awareness
grep "tracker_issue_id" skills/resume-ticket/SKILL.md
# Must return at least 1 match

# FC-17: No bare tracker_id field
grep -r "tracker_id[^_]" state/schema.md skills/implement-feature/SKILL.md skills/fix-ticket/SKILL.md skills/fix-bugs/SKILL.md
# Must return 0 matches (only tracker_issue_id allowed)

# FC-18: Dual-store write order (state.json immediately/atomic)
grep -l "state.json.*immediately\|state.json.*atomic\|atomic write protocol" skills/{implement-feature,fix-ticket,fix-bugs}/SKILL.md
# Must return all 3 files
```

---

## Group 3: Documentation (5 parallel tasks)

All documentation tasks are independent and can run in parallel.

### task-008: docs/reference/skills.md — mention new steps

| Attribute | Value |
|-----------|-------|
| **File** | `docs/reference/skills.md` |
| **Insertion points** | (a) `/fix-ticket` section (lines 91-98): add to "What it does" paragraph a mention that decomposition now creates tracker sub-issues. (b) `/fix-bugs` section (lines 122-128): same mention. (c) `/implement-feature` section (lines 180-187): same mention. |
| **What to change** | For each of the three skills, add a sentence: "When decomposition is active, the pipeline creates corresponding tracker sub-issues under the parent issue before executing subtasks (configurable via `Create tracker subtasks` in Decomposition config)." |
| **Estimated lines** | ~6 (2 lines per section) |
| **Dependencies** | task-004, task-005, task-006 |
| **Parallelizable** | Yes (with task-009 through task-012) |

### task-009: docs/reference/pipelines.md — update stage tables

| Attribute | Value |
|-----------|-------|
| **File** | `docs/reference/pipelines.md` |
| **Insertion points** | (a) Bug-Fix Pipeline Stages table (line 72-88): add a row for "Create Tracker Subtasks" after the Decomposition row. (b) Feature Pipeline Stages table (lines 180-189): add a row for "Create Tracker Subtasks" after the Decomposition row. (c) Decomposition Details section (lines 191-201): add a bullet for tracker sub-issue creation. |
| **What to change** | Add stage row: `\| Create Tracker Subtasks \| (skill) \| N/A \| N/A \| None \| Creates tracker sub-issues for each decomposition subtask. Skippable via config. \|`. Add bullet to Decomposition Details: `- **Tracker sub-issues:** After decomposition plan approval, sub-issues are created in the tracker (configurable via \`Create tracker subtasks\`). Idempotent on resume via dual-store check.` |
| **Estimated lines** | ~6 |
| **Dependencies** | task-004, task-005, task-006 |
| **Parallelizable** | Yes (with task-008, task-010 through task-012) |

### task-010: docs/reference/automation-config.md — add new key to Decomposition

| Attribute | Value |
|-----------|-------|
| **File** | `docs/reference/automation-config.md` |
| **Insertion point** | Line 353 — after the `Commit strategy` row in the Decomposition section table |
| **What to change** | Add a new row to the Decomposition table: `\| Create tracker subtasks \| \`enabled\` \| Create sub-issues in the tracker for each decomposition subtask. Values: \`enabled\`, \`disabled\`. When enabled, a new step creates tracker issues after decomposition plan approval. \|` |
| **Estimated lines** | 1 |
| **Dependencies** | task-002 |
| **Parallelizable** | Yes (with task-008, task-009, task-011, task-012) |

### task-011: CHANGELOG.md — add v6.4.0 entry

| Attribute | Value |
|-----------|-------|
| **File** | `CHANGELOG.md` |
| **Insertion point** | Line 10 — before the `## [6.3.3]` entry (new version goes at top) |
| **What to change** | Insert a complete v6.4.0 changelog entry |
| **Content to insert** | See below |
| **Estimated lines** | ~25 |
| **Dependencies** | All Group 2 tasks (must know final content) |
| **Parallelizable** | Yes (with other Group 3 tasks) |

**Changelog entry content:**

```markdown
## [6.4.0] — 2026-04-05

**MINOR** — Decomposition subtask tracker creation. When a pipeline decomposes a task into subtasks, corresponding sub-issues are now created in the issue tracker for traceability and visibility.

### Added
- **implement-feature Step 5a "Create tracker subtasks":** After decomposition plan approval, creates tracker sub-issues under the parent issue for each subtask. Supports all 6 tracker types: YouTrack (`parent:`), Jira (`parent:` + `issuetype: Sub-task`), Linear (`parentId:`), Redmine (`parent_issue_id:`), GitHub/Gitea (standalone issues with `[PARENT-ID]` title prefix + checklist in parent body).
- **fix-ticket Step 4b-tracker "Create tracker subtasks":** Same functionality for the single-bug pipeline.
- **fix-bugs Step 3b-tracker "Create tracker subtasks":** Same functionality for the batch bug pipeline.
- **Decomposition config key `Create tracker subtasks`:** New optional key (default: `enabled`). Set to `disabled` to suppress tracker sub-issue creation.
- **State schema `tracker_issue_id` field:** New field in Subtask Object Fields (`string or null`, default: `null`). Populated after successful MCP creation. Used as idempotency guard on resume via dual-store (YAML-primary, state.json fallback).
- **GitHub/Gitea decomposition checklist:** For trackers without native parent-link, a checklist section with sentinel comment (`<!-- ceos-agents:decomposition-checklist:{ID} -->`) is appended to the parent issue body.
- **Jira nested sub-task guard:** When the parent issue is already a Sub-task type, creates a flat issue without parent link (Jira prohibition on nested sub-tasks).
- **Partial failure accumulator:** Individual MCP creation failures are logged as WARN and do not block the pipeline. Result display: `Created {N}/{M} tracker sub-issues ({F} failures)`.
- **resume-ticket DECOMPOSE_PARTIAL awareness:** Resume reads `tracker_issue_id` from YAML and skips already-created sub-issues.
```

### task-012: docs/plans/roadmap.md — move to DONE

| Attribute | Value |
|-----------|-------|
| **File** | `docs/plans/roadmap.md` |
| **Insertion point** | (a) Line 433 — the current `### Decomposition Subtask Tracker Creation` entry under `## PLANNED -- Next`. (b) After the last `## DONE` section (before `## PLANNED`). |
| **What to change** | (a) Remove the entry from `## PLANNED -- Next` (lines 433-451). (b) Add a new `## DONE -- v6.4.0 (Decomposition Subtask Tracker Creation)` section after the last DONE section (currently `## DONE -- v6.3.x`). Content: summary of the feature, list of files modified, reference to design docs in `.forge/`. (c) Update version header on line 5 from `v6.3.3` to `v6.4.0` and `Last updated` on line 6 to the implementation date. |
| **Estimated lines** | ~20 (move + new section) |
| **Dependencies** | All Group 2 tasks |
| **Parallelizable** | Yes (with other Group 3 tasks) |

**Verification Gate after Group 3:**
```bash
# Verify task-008: skills.md mentions new step
grep "Create tracker subtasks\|tracker sub-issues" docs/reference/skills.md
# Must return at least 1 match

# Verify task-009: pipelines.md mentions new stage
grep "Create Tracker Subtasks\|tracker sub-issues" docs/reference/pipelines.md
# Must return at least 1 match

# Verify task-010: automation-config.md has new key
grep "Create tracker subtasks" docs/reference/automation-config.md
# Must return at least 1 match
grep -A1 "Create tracker subtasks" docs/reference/automation-config.md | grep "enabled"
# Must return at least 1 match

# Verify task-011: CHANGELOG has v6.4.0
grep "\[6.4.0\]" CHANGELOG.md
# Must return exactly 1 match

# Verify task-012: roadmap DONE section
grep "DONE.*v6.4.0\|DONE.*Decomposition Subtask Tracker" docs/plans/roadmap.md
# Must return at least 1 match
```

---

## Group 4: Tests + Version Bump (sequential)

### task-013: Copy test files to tests/scenarios/

| Attribute | Value |
|-----------|-------|
| **Source** | `.forge/phase-5-tdd/tests/*.sh` (7 files) and `.forge/phase-5-tdd/tests-hidden/*.sh` (2 files) |
| **Destination** | `tests/scenarios/` (all 9 files) |
| **What to change** | Copy all 9 test scripts from the TDD phase into the test harness directory. Files: `test-step-placement.sh`, `test-tracker-types.sh`, `test-idempotence.sh`, `test-state-schema.sh`, `test-config-contract.sh`, `test-cross-skill-consistency.sh`, `test-docs-update.sh`, `test-github-gitea-checklist.sh`, `test-partial-failure.sh` |
| **Estimated lines** | 0 (file copy, no content changes) |
| **Dependencies** | All Group 2 and Group 3 tasks (tests should pass after implementation) |
| **Parallelizable** | No (must precede test run) |

### task-014: Run test suite

| Attribute | Value |
|-----------|-------|
| **Command** | `./tests/harness/run-tests.sh` |
| **What to verify** | All existing tests still pass AND all 9 new tests pass (GREEN) |
| **Dependencies** | task-013 |
| **Parallelizable** | No |

### task-015: Version bump 6.3.3 -> 6.4.0

| Attribute | Value |
|-----------|-------|
| **Method** | Use `/ceos-agents:version-bump minor` skill |
| **What it does** | Updates `.claude-plugin/plugin.json` version from `6.3.3` to `6.4.0`, updates `.claude-plugin/marketplace.json`, creates git commit with tag `v6.4.0` |
| **Dependencies** | task-014 (all tests must pass first) |
| **Parallelizable** | No |

**Final Verification Gate:**
```bash
# Plugin version is 6.4.0
grep '"version"' .claude-plugin/plugin.json | grep "6.4.0"

# All tests pass
./tests/harness/run-tests.sh

# Git tag exists
git tag -l "v6.4.0"
```

---

## Dependency Graph

```
Group 1 (foundation, sequential)
  task-001 (state/schema.md) ──────────┐
  task-002 (CLAUDE.md config row) ─────┤
  task-003 (CLAUDE.md pipeline diagrams)┤
                                        ▼
Group 2 (skills, parallel)
  task-004 (implement-feature/SKILL.md) ─┐
  task-005 (fix-ticket/SKILL.md) ────────┤
  task-006 (fix-bugs/SKILL.md) ──────────┤
  task-007 (resume-ticket/SKILL.md) ─────┤
                                          ▼
Group 3 (docs, parallel)
  task-008 (docs/reference/skills.md) ───┐
  task-009 (docs/reference/pipelines.md) ┤
  task-010 (docs/reference/auto-config.md)┤
  task-011 (CHANGELOG.md) ───────────────┤
  task-012 (docs/plans/roadmap.md) ──────┤
                                          ▼
Group 4 (tests + version bump, sequential)
  task-013 (copy test files) ────────────┐
  task-014 (run test suite) ─────────────┤
  task-015 (version-bump minor) ─────────┘
```

---

## Summary Table

| ID | File | Change | ~Lines | Deps | Parallel |
|----|------|--------|--------|------|----------|
| task-001 | `state/schema.md` | Add `tracker_issue_id` row to Subtask Object Fields table after line 207 | 1 | None | No |
| task-002 | `CLAUDE.md` | Update Decomposition row at line 151 to include `Create tracker subtasks` key | 1 | None | Yes (with 001) |
| task-003 | `CLAUDE.md` | Update Feature Pipeline diagram at lines 53-59 to show `[Create tracker subtasks]` | 2 | task-002 | No |
| task-004 | `skills/implement-feature/SKILL.md` | Insert Step 5a between lines 244-246; update YAML save at line 239; update config read at line 33 | 82 | task-001, 002 | Yes |
| task-005 | `skills/fix-ticket/SKILL.md` | Insert Step 4b-tracker between lines 200-202; update YAML save at line 184; update config read at line 43 | 82 | task-001, 002 | Yes |
| task-006 | `skills/fix-bugs/SKILL.md` | Insert Step 3b-tracker between lines 187-189; update YAML save at line 174; update config read at line 37 | 82 | task-001, 002 | Yes |
| task-007 | `skills/resume-ticket/SKILL.md` | Add `tracker_issue_id` awareness to DECOMPOSE_PARTIAL section at lines 59-68 | 3 | task-001 | Yes |
| task-008 | `docs/reference/skills.md` | Add tracker sub-issue mention to fix-ticket, fix-bugs, implement-feature descriptions | 6 | task-004-006 | Yes |
| task-009 | `docs/reference/pipelines.md` | Add "Create Tracker Subtasks" stage rows and decomposition detail bullet | 6 | task-004-006 | Yes |
| task-010 | `docs/reference/automation-config.md` | Add `Create tracker subtasks` row to Decomposition table after line 353 | 1 | task-002 | Yes |
| task-011 | `CHANGELOG.md` | Insert v6.4.0 entry before line 10 | 25 | task-004-006 | Yes |
| task-012 | `docs/plans/roadmap.md` | Move feature from PLANNED to DONE, update version header | 20 | task-004-006 | Yes |
| task-013 | `tests/scenarios/*.sh` | Copy 9 test files from `.forge/phase-5-tdd/` | 0 | All Groups 2-3 | No |
| task-014 | (run tests) | Execute `./tests/harness/run-tests.sh` | 0 | task-013 | No |
| task-015 | `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json` | Version bump 6.3.3 -> 6.4.0 via `/ceos-agents:version-bump minor` | 2 | task-014 | No |

**Total: 15 tasks, ~311 estimated lines changed, 12 files modified + 9 test files copied.**
