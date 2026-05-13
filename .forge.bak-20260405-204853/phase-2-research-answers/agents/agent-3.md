# Agent 3 — Edge Cases & Verification Research Answers

## RQ-8: Jira Sub-task Constraint

### Evidence

**File:** `docs/reference/trackers.md`, lines 88–97 (Sub-Issue Capabilities table)

```
| jira | Yes | `parent: {key}`, `issuetype: "Sub-task"` | N/A |
```

> **Note:** The parent parameter names are MCP tool conventions. The LLM uses these when invoking the tracker's MCP create-issue tool.

**File:** `skills/scaffold/SKILL.md`, lines 543–550 (Step 4e story creation table)

```
| Jira | `parent: {epic-issue-key}`, `issuetype: "Sub-task"` |
```

**File:** `docs/reference/automation-config.md` — No Jira-specific sub-task constraint or nested sub-task guard is mentioned. No Jira config example appears in the file (only GitHub, YouTrack, Gitea, Redmine examples are shown).

### Analysis

The codebase does **not** document what should happen when a Jira parent issue is itself already a Sub-task (i.e., attempting to create a Sub-task of a Sub-task). Jira's API natively rejects this — Sub-tasks cannot have Sub-task children. The current implementation in Step 4e unconditionally passes `issuetype: "Sub-task"` and `parent: {epic-issue-key}` without any guard for the case where the epic issue is already a Sub-task.

**Gap identified:** No guard clause exists. The Jira MCP tool would return an error on creation, which would be caught by the partial failure handler (Step 4e, lines 560–571): logged as `WARN: Could not create story sub-issue for {story title} in {epic filename}: {error}`, and the pipeline continues. The error would not be informative — it would appear as a generic MCP creation failure rather than a "cannot nest sub-tasks" explanation.

**What should happen (derived from existing error handling pattern):** The scaffold skill should detect before calling MCP create-issue whether the parent epic issue is already of type Sub-task (by reading its `issuetype` field). If it is, the skill should either:
1. Fall back to a standalone issue with cross-reference (same as GitHub/Gitea fallback), or
2. Log a specific WARN: "Jira parent {key} is already a Sub-task — nested Sub-tasks are not supported. Creating standalone issue instead."

This is a gap not currently covered by any documented constraint.

---

## RQ-9: Linear UUID Resolution

### Evidence

**File:** `docs/reference/trackers.md`, lines 88–97 (Sub-Issue Capabilities table)

```
| linear | Yes | `parentId: {id}` | N/A |
```

**File:** `docs/reference/trackers.md`, lines 38 (Instance & Project Defaults)

```
| linear | `linear.app` | Team identifier |
```

**File:** `docs/reference/trackers.md`, lines 60 (PR Description Footer)

```
| linear | `{issue_id}` |
```

**File:** `docs/reference/trackers.md`, line 82 (MCP Server Detection)

```
| linear | `linear` | `@modelcontextprotocol/server-linear` |
```

**File:** `skills/scaffold/SKILL.md`, line 549

```
| Linear | `parentId: {epic-issue-id}` |
```

### Analysis

The `docs/reference/trackers.md` uses `{id}` (not `{display-id}`) in the `parentId` parameter. Linear uses internal UUIDs (e.g., `abc123ef-...`) for API operations, while users see display IDs (e.g., `ENG-123`). The spec uses `{id}` generically throughout.

**No explicit documentation exists** in any file about UUID vs display ID distinction for Linear, nor is there any statement about whether the MCP server (`@modelcontextprotocol/server-linear`) performs display ID → UUID resolution transparently.

**Gap identified:** The codebase assumes the MCP server handles any required ID translation. The `parentId: {id}` convention simply uses whatever ID was returned by the MCP `create-issue` tool call that created the epic (the back-reference stored in the spec file as `<!-- Linear: {EPIC-ISSUE-ID} -->`). If the MCP server returns a UUID when creating an issue, that UUID is stored and reused as `parentId`. If the server returns a display ID, that display ID is passed. The spec does not document or enforce which format the MCP server uses, and does not add any explicit UUID resolution step.

**Conclusion:** UUID resolution is implicitly delegated to the MCP server. The plugin passes through whatever ID format the MCP server returns from issue creation. This is consistent with the note in `docs/reference/trackers.md` line 97: "The parent parameter names are MCP tool conventions. The LLM uses these when invoking the tracker's MCP create-issue tool." Whether transparent resolution is needed depends on the specific MCP server implementation — the plugin itself adds no conversion layer.

---

## RQ-13: Post-Creation Verification (Step 4e)

### Evidence

**File:** `skills/scaffold/SKILL.md`, lines 552 (Step 4e, verification step)

```
- **Verification (native sub-issue trackers only):** After creating each story sub-issue, read the 
  created issue back from the tracker. Confirm that the parent field (parent/parentId/parent_issue_id) 
  is set to the epic issue ID. If the parent is NOT set, log `WARN: Story {story-issue-id} parent not 
  set to {epic-issue-id}. Manual linking may be required.` and continue to the next story.
```

This verification step applies to: YouTrack, Jira, Linear, Redmine (all native sub-issue trackers).

### Analysis

The verification step in Step 4e is a **post-creation read-back check** that confirms the parent relationship was actually persisted by the tracker. The stated purpose is to catch cases where:
- The MCP create-issue call succeeded (returned an ID), but
- The parent field was silently dropped (tracker API accepted the call but ignored the parent parameter, or the MCP server did not pass it through correctly).

**Is this needed for decomposition (implement-feature)?** The decomposition flow in `implement-feature` does NOT create sub-issues in the tracker — it creates sub-tasks as an internal architect task tree (YAML in state.json). Tracker issues are created at the start of `implement-feature` (one issue per feature, Step 0c), not as decomposed sub-issues. The architect's sub-tasks are implementation units, not tracker tickets.

**Is MCP return value sufficient?** No — the MCP return value confirms the API accepted the request, but not that the parent relationship was persisted. The verification step explicitly exists because some tracker integrations may silently drop the parent parameter. For scaffold Step 4e, the read-back is necessary to catch silent failures.

**Conclusion:** The post-creation verification (read-back) in Step 4e is specific to scaffold's issue creation flow. Decomposition does not create tracker sub-issues, so the verification pattern is not needed there. The MCP return value alone (issue ID) is not sufficient to confirm parent linkage — an explicit read-back is the correct pattern.

---

## RQ-14: Write Capability Check for Decomposition

### Evidence

**File:** `core/mcp-detection.md`, lines 1–62 (full file)

Key: `check_write` (boolean, optional, default: false). When true, performs canary-write check:
- Create issue titled `[ceos-agents] canary — safe to delete`
- Delete it immediately
- Returns `write_available` (boolean), `write_cleanup_failed` (boolean)

**File:** `core/mcp-preflight.md`, lines 13–14

```
Follow `core/mcp-detection.md` with `service_type: "tracker"`, `check_write: false`:
```

MCP preflight (`core/mcp-preflight.md`) explicitly uses `check_write: false` — it only verifies read connectivity.

**File:** `skills/scaffold/SKILL.md`, lines 159–165 (Step 0-MCP)

```
- `check_write` = `true` (for tracker only — SC does not need write check)
- **Before calling `core/mcp-detection.md` with `check_write = true`:** Display: 
  `Checking write access — creating a temporary test item in {tracker_project}.`
```

Scaffold Step 0-MCP is the only step that calls `mcp-detection.md` with `check_write: true`. It sets `tracker_write_available` in memory, and Step 4e uses this as a guard clause (line 523): `tracker_write_available is false` → skip issue creation.

**File:** `skills/implement-feature/SKILL.md`, lines 66–82 (Step 0: MCP pre-flight check)

implement-feature uses `core/mcp-preflight.md` (read-only, `check_write: false`). No write canary check is performed. It only verifies that the tracker MCP is accessible and responsive.

### Analysis

**Does decomposition flow need its own write check?**

Decomposition within `implement-feature` (the architect generating a task tree) does NOT create tracker sub-issues. The task tree lives entirely in `state.json`. Therefore, the decomposition flow has no direct need for a write capability check.

However, `implement-feature` does write to the tracker at several points:
- Step 0c: Create issue (if `--description` flag)
- During pipeline: state transitions via `On start set`
- Publisher: creates PR and updates issue state

These writes are not preflight-checked. Write failures are handled inline (e.g., Step 0c MCP card creation failure → BLOCK). There is no pre-emptive canary write in `implement-feature`.

**Conclusion:** The decomposition flow does not need its own write capability check because it writes only to `state.json`, not to the tracker. The write canary pattern is specific to scaffold Step 0-MCP because Step 4e creates tracker issues in bulk and benefits from early write-access validation. For `implement-feature`, write failures are caught inline at the point of use. Adding a write canary to `implement-feature` would be a potential improvement but is not currently documented or required by any existing contract.

---

## RQ-15: maps_to in Sub-Issue Descriptions

### Evidence

**File:** `agents/architect.md`, lines 46–72 (Task tree YAML format)

```yaml
maps_to:
  - "AC-1: {text of the parent feature/bug AC this subtask addresses}"
  - "AC-3: {text of another parent AC}"
```

**File:** `agents/architect.md`, lines 89–91 (Constraints)

```
- Every parent acceptance criterion MUST be mapped to at least one subtask via `maps_to`. 
  Unmapped AC indicates incomplete decomposition.
- `maps_to` entries MUST use format `AC-{N}: {verbatim text from parent AC}` where N matches 
  the parent AC numbering exactly.
```

**File:** `skills/scaffold/SKILL.md`, lines 543–554 (Step 4e story sub-issue creation)

Step 4e creates tracker issues from `spec/epics/*.md` — the epic/story content from the spec. There is no reference to architect's `maps_to` field in Step 4e. The issue title comes from the story heading, the description from the story body.

**File:** `skills/scaffold/SKILL.md`, lines 575–614 (Step 5: Architecture & Decomposition)

The architect receives the formatted epic specifications. The `maps_to` field in the task tree links subtasks back to parent AC. This is internal to the pipeline's task tree (state.json), not surfaced to tracker tickets.

**File:** `skills/implement-feature/SKILL.md` — No mention of injecting `maps_to` into tracker issue descriptions.

### Analysis

**Does AC traceability (maps_to) appear in tracker sub-issue descriptions?**

No. The `maps_to` field is an **internal architect output field** used within the ceos-agents pipeline for:
1. AC coverage validation (scaffold Step 5 AC coverage check, lines 616–623)
2. Reviewer AC fulfillment verification
3. Acceptance gate verification

The tracker sub-issue descriptions created in Step 4e (scaffold) are populated from the spec story content — not from the architect's task tree. The architect runs in Step 5, which is *after* Step 4e creates tracker issues.

**Sequencing constraint:** In the scaffold pipeline, tracker issues are created at Step 4e (before architect runs at Step 5). The architect's `maps_to` field does not exist yet when tracker issues are created. Even if `maps_to` were desired in descriptions, writing it back to tracker issues would require a separate post-Step 5 update pass — which is not currently specified.

**Conclusion:** AC traceability via `maps_to` should NOT appear in tracker sub-issue descriptions under the current design. The `maps_to` field is an internal pipeline contract between architect → pipeline orchestration → reviewer/acceptance-gate. If traceability in the tracker is desired (e.g., adding "Addresses AC-2: User can log in" to the issue description), that would be a new feature requiring a spec change. The current design keeps the tracker representation clean (spec content only) and uses `maps_to` purely as internal pipeline metadata.
