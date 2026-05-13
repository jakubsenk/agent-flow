# Requirements: Decomposition Subtask Tracker Creation (v6.4.0)

## Document Conventions

Requirements use EARS (Event-Action-Response-State) format:
- **WHEN** {event/condition} **THE SYSTEM SHALL** {action} **SO THAT** {response/state change}
- **IF** {condition} **THEN** {behavior}

All requirements are uniquely identified as REQ-N.M where N is the category and M is the sequence.

---

## REQ-1: New Pipeline Step Placement

### REQ-1.1: implement-feature Step 5a

WHEN the implement-feature pipeline reaches the decomposition decision step (Step 5) AND `decomposition.decision == "DECOMPOSE"`, THE SYSTEM SHALL execute a new Step 5a "Create tracker subtasks" between Step 5 (Decomposition decision) and Step 6 (Subtask execution) SO THAT all decomposition subtasks have corresponding tracker issues before code execution begins.

### REQ-1.2: fix-ticket Step 4b-tracker

WHEN the fix-ticket pipeline reaches the decomposition decision step (Step 4b) AND `decomposition.decision == "DECOMPOSE"`, THE SYSTEM SHALL execute a new Step 4b-tracker "Create tracker subtasks" between Step 4b (Decomposition decision) and Step 4c (Subtask execution) SO THAT all decomposition subtasks have corresponding tracker issues before code execution begins.

### REQ-1.3: fix-bugs Step 3b-tracker

WHEN the fix-bugs pipeline reaches the decomposition decision step (Step 3b) AND `decomposition.decision == "DECOMPOSE"`, THE SYSTEM SHALL execute a new Step 3b-tracker "Create tracker subtasks" between Step 3b (Decomposition decision) and Step 3c (Subtask execution) SO THAT all decomposition subtasks have corresponding tracker issues before code execution begins.

### REQ-1.4: Step Position Consistency

THE SYSTEM SHALL place the tracker subtask creation step at the same logical position in all three skills: after the decomposition decision writes the YAML task tree and before the subtask execution loop begins.

### REQ-1.5: Upfront Creation

THE SYSTEM SHALL create all tracker sub-issues in a single upfront loop (iterating all subtasks) before any subtask execution begins, not incrementally during subtask execution.

---

## REQ-2: Tracker-Specific Parent-Link

### REQ-2.1: YouTrack Sub-Issue Creation

WHEN `tracker_type == "youtrack"`, THE SYSTEM SHALL create each subtask issue via MCP with parameter `parent: {PARENT-ISSUE-ID}` SO THAT the subtask is a native sub-issue of the parent.

### REQ-2.2: Jira Sub-Task Creation

WHEN `tracker_type == "jira"`, THE SYSTEM SHALL create each subtask issue via MCP with parameters `parent: {PARENT-ISSUE-KEY}` and `issuetype: "Sub-task"` SO THAT the subtask is a native Jira sub-task of the parent.

### REQ-2.3: Jira Nested Sub-Task Guard

WHEN `tracker_type == "jira"` AND the parent issue is already of type "Sub-task", THE SYSTEM SHALL create the subtask as a flat issue WITHOUT the `parent` parameter and log WARN: `"Parent issue {PARENT-ISSUE-KEY} is a Sub-task — creating flat issue without parent link."` SO THAT Jira's nested sub-task prohibition is respected.

### REQ-2.4: Linear Sub-Issue Creation

WHEN `tracker_type == "linear"`, THE SYSTEM SHALL create each subtask issue via MCP with parameter `parentId: {PARENT-ISSUE-ID}` SO THAT the subtask is a native Linear sub-issue.

### REQ-2.5: Redmine Sub-Issue Creation

WHEN `tracker_type == "redmine"`, THE SYSTEM SHALL create each subtask issue via MCP with parameter `parent_issue_id: {PARENT-ISSUE-ID}` SO THAT the subtask is a native Redmine child issue.

### REQ-2.6: GitHub Standalone + Checklist

WHEN `tracker_type == "github"`, THE SYSTEM SHALL create each subtask as a standalone issue titled `[{PARENT-ISSUE-ID}] {subtask-title}` and then append a decomposition checklist to the parent issue body (see REQ-7).

### REQ-2.7: Gitea Standalone + Checklist

WHEN `tracker_type == "gitea"`, THE SYSTEM SHALL create each subtask as a standalone issue titled `[{PARENT-ISSUE-ID}] {subtask-title}` and then append a decomposition checklist to the parent issue body (see REQ-7).

### REQ-2.8: Sub-Issue Description Content

THE SYSTEM SHALL include in every created sub-issue description:
1. The subtask scope text from the architect task tree
2. An "Addresses:" line listing all `maps_to` references (format: `Addresses: AC-1: {text}, AC-3: {text}`)
3. The list of files from the subtask's `files` field

SO THAT tracker sub-issues are self-documenting and traceable to parent acceptance criteria.

---

## REQ-3: Idempotence

### REQ-3.1: YAML-Primary Idempotency Check

WHEN the step begins processing a subtask, THE SYSTEM SHALL first read `.claude/decomposition/{ISSUE-ID}.yaml` and check the subtask's `tracker_issue_id` field. IF `tracker_issue_id` is non-null, THEN the system SHALL skip creation for that subtask and use the existing value.

### REQ-3.2: State.json Fallback Check

IF the YAML check (REQ-3.1) returns null for `tracker_issue_id` BUT `state.json` at path `decomposition.subtasks[matching-id].tracker_issue_id` is non-null, THEN the system SHALL use the state.json value (crash recovery: YAML write failed after state.json write was successful), write it back into the YAML, and skip creation for that subtask.

### REQ-3.3: Dual-Store Write After Creation

WHEN a sub-issue is successfully created via MCP, THE SYSTEM SHALL write the returned issue ID to BOTH:
1. The subtask's `tracker_issue_id` field in `.claude/decomposition/{ISSUE-ID}.yaml` (in-memory, committed later)
2. The matching subtask entry in `.ceos-agents/{ISSUE-ID}/state.json` immediately (follow atomic write protocol from `core/state-manager.md`)

SO THAT crash recovery is possible from either store.

### REQ-3.4: No Tracker-Side Query

THE SYSTEM SHALL NOT query the tracker for existing issues as part of the idempotency check. Idempotency is determined solely from the dual-store (YAML + state.json).

---

## REQ-4: State Schema Update

### REQ-4.1: tracker_issue_id Field in Subtask Object

THE SYSTEM SHALL add a new field `tracker_issue_id` to the Subtask Object Fields table in `state/schema.md`:

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `tracker_issue_id` | string or null | No | `null` | Tracker issue ID for this subtask (e.g., `PROJ-45`). Set after creation via MCP. Used as idempotency guard on resume. |

### REQ-4.2: YAML Subtask Field

THE SYSTEM SHALL add `tracker_issue_id: null` as a runtime field in the `.claude/decomposition/{ISSUE-ID}.yaml` subtask objects, alongside existing runtime fields (`status`, `commit_hash`, `restore_point`).

### REQ-4.3: Field Naming

THE SYSTEM SHALL use the field name `tracker_issue_id` (NOT `tracker_id`) to avoid collision with Redmine's `tracker_id` parameter which refers to issue TYPE, not issue identity.

---

## REQ-5: Config Contract Update

### REQ-5.1: New Decomposition Key

THE SYSTEM SHALL add a new optional key to the Decomposition section of Automation Config:

| Key | Default | Description |
|-----|---------|-------------|
| Create tracker subtasks | `enabled` | Create sub-issues in the tracker for each decomposition subtask. Values: `enabled`, `disabled`. |

### REQ-5.2: String Enum Values

THE SYSTEM SHALL accept only two values for the `Create tracker subtasks` key: `enabled` or `disabled`. Any other value SHALL produce an error: `"Invalid value for 'Create tracker subtasks': {value}. Expected: enabled or disabled."`

### REQ-5.3: Default Enabled

WHEN the `Create tracker subtasks` key is absent from the Decomposition section OR the entire Decomposition section is absent, THE SYSTEM SHALL default to `enabled`.

### REQ-5.4: Versioning Classification

This change SHALL be classified as MINOR (v6.4.0) because it adds an optional key to an existing optional section, requiring no changes from existing consumers.

---

## REQ-6: Partial Failure Handling

### REQ-6.1: Per-Subtask Accumulator

WHEN an individual subtask MCP creation call fails, THE SYSTEM SHALL:
1. Log WARN: `"Could not create tracker sub-issue for subtask '{subtask-title}': {error}"`
2. Set `tracker_issue_id` to `null` for that subtask in both YAML and state.json
3. Continue to the next subtask

SO THAT a single tracker failure does not block the entire creation loop.

### REQ-6.2: Result Display

AFTER the creation loop completes, THE SYSTEM SHALL display: `"Created {N}/{M} tracker sub-issues ({F} failures)."` where N = successful, M = total, F = failed.

### REQ-6.3: 100% Failure Escalation

IF N == 0 (all subtask creations failed), THE SYSTEM SHALL display an elevated WARN: `"All tracker sub-issue creation failed. Check MCP tracker connectivity. Pipeline continues without tracker integration for this decomposition."` The pipeline SHALL NOT block.

### REQ-6.4: Pipeline Never Blocks on Tracker Failure

THE SYSTEM SHALL NEVER block the pipeline due to tracker sub-issue creation failure. The step is informational — the execution loop proceeds regardless of creation results.

### REQ-6.5: GitHub/Gitea Checklist Failure

IF the parent issue body update (checklist append) fails for GitHub/Gitea, THE SYSTEM SHALL log WARN: `"Could not update parent issue body with checklist: {error}. Standalone sub-issues may still exist."` and continue.

---

## REQ-7: GitHub/Gitea Checklist in Parent Issue Body

### REQ-7.1: Checklist Format

WHEN `tracker_type` is `"github"` or `"gitea"` AND at least one subtask issue was successfully created, THE SYSTEM SHALL append a decomposition checklist section to the parent issue body using this exact format:

```markdown

---
## Decomposition Subtasks
<!-- ceos-agents:decomposition-checklist:{PARENT-ISSUE-ID} -->
- [ ] {subtask-title} (#{subtask-issue-number})
- [ ] {subtask-title} (#{subtask-issue-number})
```

### REQ-7.2: Sentinel Comment for Idempotency

THE SYSTEM SHALL include the HTML comment `<!-- ceos-agents:decomposition-checklist:{PARENT-ISSUE-ID} -->` as a sentinel. On subsequent runs, the system SHALL check for this sentinel in the parent issue body. IF the sentinel is present, the system SHALL skip the checklist append (checklist already exists).

### REQ-7.3: Read-Modify-Write Sequence

THE SYSTEM SHALL:
1. Read the parent issue body via MCP
2. Check for sentinel comment — if present, skip
3. Append the checklist section to the body text
4. Update the parent issue body via MCP

### REQ-7.4: Failed Subtasks Excluded from Checklist

THE SYSTEM SHALL only include successfully created subtask issues (those with non-null `tracker_issue_id`) in the checklist. Failed subtask creations are omitted.

### REQ-7.5: Standalone Issue Title Format

FOR GitHub and Gitea, each standalone subtask issue SHALL be titled: `[{PARENT-ISSUE-ID}] {subtask-title}`.

---

## REQ-8: Resume Behavior

### REQ-8.1: DECOMPOSE_PARTIAL Checkpoint Awareness

WHEN the pipeline is resumed via `/ceos-agents:resume-ticket` and the checkpoint is `DECOMPOSE_PARTIAL`, THE SYSTEM SHALL:
1. Read `.claude/decomposition/{ISSUE-ID}.yaml`
2. Check each subtask's `tracker_issue_id` field
3. Skip creation for subtasks that already have a non-null `tracker_issue_id`
4. Attempt creation only for subtasks with null `tracker_issue_id`
5. After the creation pass, proceed to the subtask execution loop (continuing from the next pending subtask)

### REQ-8.2: YAML Write Survives Git Operations

THE SYSTEM SHALL commit the YAML (with populated `tracker_issue_id` values) to git after the creation loop (see REQ-6 and design.md commit strategy). This ensures that `tracker_issue_id` values survive `git checkout` and are available on resume.

### REQ-8.3: State.json as Crash Recovery Fallback

IF `.claude/decomposition/{ISSUE-ID}.yaml` has null for a subtask's `tracker_issue_id` BUT `.ceos-agents/{ISSUE-ID}/state.json` has a non-null value (indicating a crash between state.json write and YAML commit), THE SYSTEM SHALL use the state.json value and skip creation for that subtask (same as REQ-3.2).

---

## Traceability Matrix

| Requirement | Affected Files | Test Criteria |
|-------------|----------------|---------------|
| REQ-1.1 | `skills/implement-feature/SKILL.md` | Step 5a heading exists between Step 5 and Step 6 |
| REQ-1.2 | `skills/fix-ticket/SKILL.md` | Step 4b-tracker heading exists between Step 4b and Step 4c |
| REQ-1.3 | `skills/fix-bugs/SKILL.md` | Step 3b-tracker heading exists between Step 3b and Step 3c |
| REQ-2.1-2.7 | All 3 skill files | Per-tracker parameter table present in each step |
| REQ-3.1-3.4 | All 3 skill files | Idempotency algorithm described in each step |
| REQ-4.1 | `state/schema.md` | `tracker_issue_id` row in Subtask Object Fields table |
| REQ-4.2 | All 3 skill files | `tracker_issue_id: null` in YAML write instructions |
| REQ-5.1 | `CLAUDE.md`, `docs/reference/automation-config.md` | New key in Decomposition table |
| REQ-6.1-6.5 | All 3 skill files | Accumulator pattern described, pipeline-never-blocks stated |
| REQ-7.1-7.5 | All 3 skill files | Checklist format with sentinel present |
| REQ-8.1-8.3 | `skills/resume-ticket/SKILL.md`, all 3 skill files | Resume reads `tracker_issue_id` from YAML |
