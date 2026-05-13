# Agent 3 Research — Areas 5 & 6

## Area 5: Tracker-Specific Mechanisms

### Source: `docs/reference/trackers.md`

#### Sub-Issue Capabilities Table (verbatim excerpt)

```
| Tracker | Native sub-issues | Parent parameter | Fallback strategy |
|---------|-------------------|-----------------|-------------------|
| youtrack | Yes | `parent: {issue-id}` | N/A |
| jira | Yes | `parent: {key}`, `issuetype: "Sub-task"` | N/A |
| linear | Yes | `parentId: {id}` | N/A |
| redmine | Yes | `parent_issue_id: {id}` | N/A |
| github | No | N/A | Standalone issue: `[{epic_title}] {story_title}`, cross-reference in description |
| gitea | No | N/A | Standalone issue: `[{epic_title}] {story_title}`, cross-reference in description |
```

The note confirms: "The parent parameter names are MCP tool conventions. The LLM uses these when invoking the tracker's MCP create-issue tool. For trackers without native sub-issues, the fallback creates a standalone issue with the epic title as a prefix and adds a link to the parent epic issue in the description body."

#### MCP Tool Names Per Tracker (from `core/mcp-detection.md`)

| Tracker | Tool Prefix |
|---------|-------------|
| youtrack | `mcp__youtrack__*` |
| github | `mcp__github__*` |
| jira | `mcp__jira__*` or `mcp__atlassian__*` |
| linear | `mcp__linear__*` |
| gitea | `mcp__gitea__*` or `mcp__forgejo__*` |
| redmine | `mcp__redmine__*` |

#### How Scaffold Step 4e Implements Tracker Issue Creation

From `skills/scaffold/SKILL.md` Step 4e (the only existing place in the codebase where sub-issue creation is implemented):

- **Native sub-issue trackers** (YouTrack, Jira, Linear, Redmine): create sub-issue passing tracker-specific parent parameter
- **Fallback trackers** (GitHub, Gitea): create standalone issue with `[{epic_title}] {story_title}` naming, cross-reference in description
- **Verification step** (native only): after creating each sub-issue, read it back and confirm the parent field is set; log WARN if not, continue
- **Idempotency guard**: before creating, check for `<!-- {TrackerType}: ... -->` back-reference comment already present in spec file

#### Key Observation: No Decomposition-Context Tracker Creation Exists

The Sub-Issue Capabilities table and parent-linking mechanism currently only appear in `skills/scaffold/SKILL.md` Step 4e (spec-based workflow). Neither `skills/fix-ticket/SKILL.md` nor `skills/implement-feature/SKILL.md` contain any step to create tracker issues for decomposition subtasks. The decomposition task tree lives entirely in `.claude/decomposition/{ISSUE-ID}.yaml` — it is a local artifact with no tracker representation.

---

### Questions Generated — Area 5

**Q5.1** The Sub-Issue Capabilities table shows that GitHub and Gitea lack native sub-issues and must fall back to standalone issues with `[{epic_title}] {story_title}` prefix naming. For decomposition subtasks in the bug/feature pipelines, the "epic" is the parent issue (e.g., `PROJ-42`). Should the fallback title format be `[PROJ-42] {subtask_title}` (using the issue ID as prefix) rather than an epic title, since there is no spec-level epic concept in the bug/feature pipelines?

**Q5.2** The Jira `issuetype: "Sub-task"` constraint requires that the parent issue itself be a Story or Epic (Jira rejects sub-tasks parented to other sub-tasks). If a user runs `/fix-ticket` on a Jira sub-task, what should happen — should the implementation skip parent linking and fall back to a standalone issue, or block with an informative error?

**Q5.3** Scaffold Step 4e includes a post-creation verification step (native trackers only): read the created issue back and confirm the parent field is set, logging WARN if not. Should decomposition subtask creation apply the same verification pattern, or is a lighter approach (no read-back) acceptable for the decomposition case?

**Q5.4** The trackers.md Sub-Issue Capabilities note says "The LLM uses these [parent parameter names] when invoking the tracker's MCP create-issue tool." The exact tool name varies (e.g., `mcp__youtrack__create_issue` vs `mcp__gitea__create_issue`). Is the LLM expected to discover the precise tool name at runtime by scanning available tools for the prefix, or should a canonical tool name per tracker be documented (e.g., in trackers.md)?

**Q5.5** Linear uses `parentId` (not `parent` or `parent_issue_id`), and the ID format is a UUID-style internal ID — not a human-readable issue number like `PROJ-42`. When the pipeline has the parent issue ID as a display string (e.g., `MAR-7`), how does the skill resolve it to Linear's internal UUID needed for `parentId`? Does the implementation need an explicit look-up step via MCP?

**Q5.6** For trackers with native sub-issues, should the decomposition subtask tracker issues be created all upfront (before any subtask execution begins), or one at a time just before each subtask's fixer step? The scaffold Step 4e creates all issues in one pass; the decomposition loop executes subtasks sequentially. Each approach has trade-offs for partial failure recovery and resume idempotency.

**Q5.7** The Sub-Issue Capabilities table only covers the six tracker types already in the reference. Is the design expected to be extensible to new tracker types added in the future, and if so, what is the extension contract — a new row in the Sub-Issue Capabilities table plus a new entry in the MCP Server Detection table, or something more?

---

## Area 6: Resume / Idempotence

### Source: `skills/resume-ticket/SKILL.md`, `core/state-manager.md`, `core/decomposition-heuristics.md`

#### How `/resume-ticket` Detects Pipeline State

**Priority 0 — State File Detection** (`state.json` exists):
1. Read `.ceos-agents/{ISSUE-ID}/state.json`
2. Find first step with `status: "in_progress"` → resume from that step
3. If none in_progress: find first `"pending"` step after all `"completed"` → resume there
4. Restore context (AC, complexity, iteration counts, profile, flags) from state file

**Heuristic Fallback** (`state.json` absent):

```
if PR exists for branch → PUBLISHED
else if .claude/decomposition/{ISSUE-ID}.yaml exists → DECOMPOSE_PARTIAL
else if branch has commits above base → POST_FIX (or POST_REVIEW if reviewer approval comment)
else if branch exists + triage comment → POST_ANALYSIS
else if triage comment exists → POST_TRIAGE
else → FRESH
```

**DECOMPOSE_PARTIAL checkpoint** (highest priority in heuristic — checked before POST_FIX):
- Detection: `.claude/decomposition/{ISSUE-ID}.yaml` file exists
- Action: read task tree, find last completed subtask, continue from next (in_progress or pending)
- Failed subtasks: reset to pending and retry

#### State.json Idempotency Pattern

From `core/state-manager.md`:
- Each issue has its own directory `.ceos-agents/{ISSUE-ID}/`
- No file-level locking — parallel tickets never share state files
- Atomic write: write to `.json.tmp`, rename to `.json`
- If write fails: retry once, then log warning and continue (state is advisory)
- Corrupted file: renamed to `state.json.corrupt.{timestamp}`, triggers heuristic fallback

The `decomposition.subtasks` list in `state.json` tracks per-subtask `status` and `commit_hash`. The `.claude/decomposition/{ISSUE-ID}.yaml` file is the primary source of truth for decomposition resume; `state.json` mirrors subset of that data.

#### What Happens on Partial Failure Today

From `skills/fix-ticket/SKILL.md` Step 4c (subtask execution):
- On subtask failure: `git reset --hard {restore_point_N}`
- `fail-fast` strategy: stop and report "X/N completed"
- Task tree state is saved (status fields updated in YAML + state.json)
- Resume via `DECOMPOSE_PARTIAL` checkpoint: reads `.claude/decomposition/{ISSUE-ID}.yaml`, picks up from next subtask

#### Critical Gap: No tracker_id in Decomposition YAML

The `.claude/decomposition/{ISSUE-ID}.yaml` schema (as described in fix-ticket Step 4b and implement-feature Step 5) includes per-subtask fields: `id`, `title`, `scope`, `files`, `acceptance_criteria`, `depends_on`, `estimated_lines`, `maps_to`, `status`, `commit_hash`, `restore_point`. There is **no `tracker_issue_id` field** in the current schema for storing the created tracker issue ID per subtask.

This means:
1. There is no existing idempotency mechanism for tracker issue creation in decomposition
2. On resume, there is no way to detect whether a subtask's tracker issue was already created
3. The `DECOMPOSE_PARTIAL` checkpoint in resume-ticket only checks task execution state (code changes, commits) — not tracker issue creation state

---

### Questions Generated — Area 6

**Q6.1** The `.claude/decomposition/{ISSUE-ID}.yaml` schema currently has no `tracker_issue_id` field per subtask. Should a new optional field (e.g., `tracker_issue_id: null | "PROJ-43"`) be added to the YAML schema to enable idempotency on resume — skip creation if already populated? Or should the idempotency guard use the tracker itself (search for issues with matching title or a `[ceos-agents-subtask: {subtask-id}]` marker in the description)?

**Q6.2** The `DECOMPOSE_PARTIAL` checkpoint in `resume-ticket` reads the task tree YAML and resumes from the next pending subtask. If tracker issue creation is added as a pre-execution step, should it be gated on a flag in the YAML (`tracker_issue_id` present/absent), or should the resume logic treat tracker issue creation and code execution as separate resumable phases within a subtask?

**Q6.3** The state-manager documents that `state.json` write failures are advisory (pipeline must not block on state write failure). Should the same advisory policy apply to tracker issue creation failures during decomposition — i.e., a tracker creation failure is logged as WARN and the subtask proceeds without a tracker issue — or should tracker creation failure be a hard block?

**Q6.4** The heuristic fallback for `DECOMPOSE_PARTIAL` does not inspect tracker state at all — it only checks for the local YAML file. If tracker issue creation is added, what should a fresh `/resume-ticket` run (with no state.json) do if the YAML exists but has no `tracker_issue_id` fields populated? Should it re-attempt tracker creation before continuing execution, or assume issues were not created and skip (accepting duplicates as a risk)?

**Q6.5** The current DECOMPOSE_PARTIAL resume logic states: "For failed subtasks: reset to pending and retry." If a subtask failed after its tracker issue was created but before code execution completed, a naive reset-and-retry would create a duplicate tracker issue on the next attempt. What deduplication strategy should be used: (a) prefix/marker in issue title, (b) store tracker_issue_id in YAML and check before creating, (c) search tracker for existing issues with matching title before creating?

**Q6.6** `core/mcp-detection.md` defines a write canary check (`check_write: true`) that creates and immediately deletes a test issue. The existing Scaffold Step 4e reuses the `tracker_write_available` flag set at Step 0-MCP. For decomposition tracker creation in fix-ticket and implement-feature, no equivalent write check currently exists. Should a write capability check be added to the decomposition flow — and if so, at what point (config parsing, decomposition decision step, or just before the first issue creation)?

**Q6.7** The decomposition YAML is stored at `.claude/decomposition/{ISSUE-ID}.yaml` — a path inside the project's git repository. Writing tracker_issue_id values back into this file after each creation means the file will have uncommitted changes between subtask commits. Should this file be committed as part of each subtask commit (alongside the code), or committed separately after all tracker issues are created, or written and left as an untracked local file (never committed)?

---

## Gaps and Ambiguities Found

**Gap A — No existing end-to-end implementation for decomposition tracker creation:** The feature is entirely absent from fix-ticket and implement-feature. The only comparable implementation is scaffold Step 4e, which targets a different context (spec-based epic/story hierarchy, not code decomposition subtasks). The design must be specified from scratch for the decomposition case.

**Gap B — Jira issuetype constraint is not documented for the decomposition case:** The trackers.md table notes `issuetype: "Sub-task"` for Jira, but Jira's sub-task constraint (parent must be a standard issue type, not another sub-task) is only documented implicitly. Decomposition on Jira sub-tasks could silently fail or produce an error from the Jira API.

**Gap C — "tracker_id" terminology ambiguity:** In `docs/reference/trackers.md`, `tracker_id` appears in Redmine's query syntax (numeric ID for issue type, e.g., `tracker_id=1` for Bug). In the context of decomposition resume, "tracker_id" would mean the issue ID of a created sub-issue. These are two different things with the same term. Any new field added to the YAML should use a non-ambiguous name (e.g., `tracker_issue_id` or `issue_tracker_id`).

**Gap D — No policy on what to do when tracker write is unavailable mid-decomposition:** The scaffold flow has a clear policy (check write at Step 0-MCP, skip Step 4e if `tracker_write_available = false`). For decomposition in fix/feature pipelines, there is no equivalent gate and no documented policy for handling tracker write failures mid-loop.

**Gap E — Linear UUID resolution not addressed:** Linear's `parentId` requires an internal UUID, but the pipeline works with display IDs (e.g., `ENG-7`). The trackers.md table does not explain how to resolve display ID → UUID. This is either assumed to be handled transparently by the Linear MCP server, or it is an undocumented caller responsibility.

**Gap F — DECOMPOSE_PARTIAL and tracker state are fully decoupled:** The resume logic was designed before tracker issue creation was contemplated for the decomposition case. The checkpoint table has no concept of "tracker issues partially created" as a resumable state. If tracker creation is added, the resume-ticket logic may need a new sub-state or the DECOMPOSE_PARTIAL handling must be extended to cover it.
