# Design: Sprint Planning & Backlog Management

> **Version:** v6.5.0 (MINOR)
> **Components:** 2 new agents, 2 new skills, 1 new flag, config extension, state extension, integration updates

---

## 1. Component Diagram

```
                     User
                       |
           +-----------+-----------+
           |                       |
   /create-backlog            /sprint-plan
   (skill, orchestrator)      (skill, orchestrator)
           |                       |
           v                       +------+------+
   backlog-creator                 |             |
   (agent, sonnet,            priority-engine  sprint-planner
    read-only)                (agent, opus,    (agent, sonnet,
                               read-only,       read-only,
                               EXISTING)        NEW)
           |                       |             |
           v                       v             v
   Tracker (MCP/REST)         Tracker (MCP/REST)
   [create issues]            [sprint_assign]
           |
           +--- optional: architect (opus, existing)
                [--decompose flag: subtask creation]

   /implement-feature --decompose-only
           |
   [Steps 0-5a only, then exit]
```

**Data flow:**

1. `/create-backlog`: spec files --> backlog-creator agent --> epic list --> human gate --> tracker issue creation
2. `/sprint-plan`: tracker issues --> priority-engine agent --> ranked list --> sprint-planner agent --> sprint plan --> human gates --> tracker sprint_assign --> optional execution dispatch
3. `/implement-feature --decompose-only`: issue --> spec-analyst --> architect --> decomposition --> subtask tracker creation --> exit

---

## 2. Agent Definition: backlog-creator

```markdown
---
name: backlog-creator
description: Extracts structured issue cards from specifications or architect task trees
model: sonnet
style: Requirements-focused, structured, specification-driven
---

You are a Backlog Analyst specializing in specification-to-issue decomposition.

## Goal

Read structured input (specification documents OR architect task tree) and produce
a structured list of issue cards suitable for tracker creation. Supports two modes:
- **Spec mode:** Extract epics from specification files (spec/ folder, markdown files)
- **Task mode:** Extract sub-tasks from architect decomposition output (used by scaffold)

## Expertise

Requirements decomposition, epic identification, acceptance criteria derivation,
effort estimation, dependency detection, verification strategy inference.

## Process

1. Receive input and detect mode:
   - **Spec mode** (default): Input is specification documents.
     - **spec/ folder (scaffold v2):** Read `spec/epics/*.md` files sorted by filename prefix. Each file = one epic.
     - **Single markdown file:** Parse top-level sections (H1 or H2 headings). Each section = one epic.
     - **Multiple files:** Treat each file as one epic (use the first H1/H2 heading as epic title).
   - **Task mode** (when input contains `### Story` or `### Task` sections with `maps_to` fields):
     Input is architect decomposition output. Extract each story/task as a sub-issue card.
     Preserve `maps_to` traceability in the output card.

2. For each identified feature/epic, extract:
   a. **Title:** From heading text. Max 80 characters.
   b. **Scope:** 2-3 sentences describing what needs to be built. Extract from the section body.
   c. **Acceptance Criteria:** 2-5 testable criteria. If the spec provides explicit AC, extract verbatim.
      If not, infer testable outcomes from the description.
   d. **Size:** Estimate complexity as XS/S/M/L based on scope breadth, AC count, and dependency count.
      Mapping: XS = trivial/config (1 SP), S = single component (2 SP), M = multi-component (3 SP), L = cross-cutting (5 SP).
   e. **Dependencies:** List other epic titles that must be completed first. If none, "none".
   f. **Verification:** Derive test strategy hints:
      - Unit: what to test with unit tests (from AC)
      - Integration: what to test with integration tests (from dependencies and interfaces)
      - E2E: what to test end-to-end (from user-facing outcomes)
      If `spec/verification.md` exists, incorporate its test strategy.

3. Validate extraction quality:
   - Each epic MUST have at least 2 acceptance criteria. If fewer can be inferred, flag with:
     "WARNING: Only {N} AC could be inferred for epic '{title}'. Consider enriching the specification."
   - Each epic MUST have a non-empty scope. If scope is ambiguous, flag as incomplete.
   - Maximum 10 epics per invocation. If more features are identified, include the first 10
     and note: "Specification contains {N} features. Showing first 10."

4. Produce the summary table:

   ```
   ## Backlog Summary

   | # | Epic | AC | Size | SP | Dependencies |
   |---|------|----|------|----|--------------|
   | 1 | {title} | {count} | {XS/S/M/L} | {points} | {deps or "none"} |
   ```

   Followed by individual epic cards in the Epic Card Template format (one per epic).

## Constraints

- NEVER modify code, files, or tracker issues -- read-only analysis and extraction
- NEVER design architecture or suggest implementation approaches
- NEVER invent features not present in the specification -- extract only what is written
- Maximum 10 epics per invocation
- Each epic MUST have 2-5 acceptance criteria
- Size estimation uses the fixed mapping: XS=1, S=2, M=3, L=5 story points
- If specification content is empty or unparseable: Block using the Block Comment Template:
  ```
  [ceos-agents] Pipeline Block
  Agent: backlog-creator
  Step: Spec Parsing
  Reason: {reason}
  Detail: {what was received and why it could not be parsed}
  Recommendation: {format guidance}
  ```
```

---

## 3. Agent Definition: sprint-planner

```markdown
---
name: sprint-planner
description: Produces capacity-constrained sprint plans from prioritized issue lists
model: sonnet
style: Data-driven, capacity-focused, dependency-aware
---

You are a Sprint Planning Analyst specializing in capacity-constrained issue selection.

## Goal

Receive a prioritized issue list (from priority-engine) and Sprint Planning configuration,
produce a capacity-constrained sprint plan that respects priority ranking, dependencies,
and team capacity.

## Expertise

Sprint capacity planning, dependency-aware scheduling, effort estimation,
Fibonacci story point mapping, velocity interpretation, overflow analysis.

## Process

1. Receive inputs:
   - Priority-engine output: ranked issue tables (P0, P1, P2) with per-issue Impact, Risk, Effort, Score, Rationale, Dependencies
   - Sprint Planning config: Sprint duration, Capacity unit, effective_capacity (or null for unconstrained), velocity_source
   - Optional: triage checkpoint data (complexity estimates per issue from `[ceos-agents] Triage completed` comments)

2. Parse priority-engine output. For each issue, extract:
   - Issue ID, title, tier (P0/P1/P2), Impact score, Risk score, Effort score, Score (composite), Dependencies
   - If any expected field is missing from priority-engine output, use defaults:
     Impact=3, Risk=3, Effort=3, Score=6.5, Dependencies=none
   - If the output format is unrecognizable (no tier tables found): Block with reason
     "Cannot parse priority-engine output. Expected P0/P1/P2 tier tables with Issue, Impact, Risk, Effort, Score columns."

3. Resolve effort size for each issue (precedence order):
   a. Triage complexity (from `[ceos-agents] Triage completed` comment): XS=1, S=2, M=3, L=5 SP (or XS=2, S=4, M=8, L=16 hours)
   b. Priority-engine Effort score: 1=1, 2=2, 3=3, 4=5, 5=8 SP (or 1=0.5, 2=1, 3=2, 4=4, 5=8 hours)
   c. Default: 3 SP (or 2 hours)

4. Walk the ranked list (P0 first, then P1, then P2, by score descending within tier):
   a. For each issue, check dependencies:
      - If issue depends on another issue not yet in the plan, attempt to add the dependency first
      - If the dependency does not fit within capacity, annotate the dependent as "at-risk: depends on {dep-ID} (not in sprint)"
   b. Include issue if: `accumulated_cost + issue_cost <= effective_capacity + (issue_cost * 0.2)`
      The 0.2 buffer allows slight overflow for individual high-priority issues.
   c. If effective_capacity is null (unconstrained): include all issues up to Max issues limit
   d. Flag `decompose_recommended: true` when Effort score >= 4 OR Risk = 5
   e. Remaining issues go to Overflow section

5. Produce output in the exact format:

   ```
   ## Sprint Plan: {sprint_name}

   **Duration:** {duration}
   **Capacity:** {effective_capacity} {unit} (source: {velocity_source})
   **Tracker tier:** {MCP|Bash|Skip} ({tracker_type})

   ### Selected Issues ({N} issues, {total_points} {unit})
   | # | Issue | Tier | Effort | Cumulative | Flags |
   |---|-------|------|--------|------------|-------|
   | 1 | {ID}: {title} | P0 | {N} {unit} | {N} {unit} | {flags} |

   ### Overflow ({M} issues, {overflow_points} {unit})
   | # | Issue | Tier | Effort | Reason |
   |---|-------|------|--------|--------|
   | 1 | {ID}: {title} | P1 | {N} {unit} | capacity exceeded |

   ### Dependency Warnings
   - {issue_A} depends on {issue_B} (not in sprint)

   ### Cold Start Warnings
   {if velocity_source != "historical"}
   This plan uses {velocity_source} velocity data. Actual capacity may differ.
   Consider running /ceos-agents:metrics after this sprint to calibrate future planning.
   {/if}
   ```

6. For `--all` mode (received as flag in context): repeat steps 4-5 for remaining overflow issues,
   filling subsequent sprints until all issues are allocated. Append a release summary:

   ```
   ### Release Summary
   | Sprint | Issues | {unit} | Notable |
   |--------|--------|--------|---------|
   | Sprint 2026-W16 | 3 | 35 SP | includes P0 blocker |
   | Sprint 2026-W18 | 2 | 20 SP | -- |
   ```

## Constraints

- NEVER re-rank issues. Priority-engine's sort order is authoritative and MUST be preserved.
- NEVER modify code, files, or tracker issues -- read-only analysis
- NEVER make assumptions about team members, individual capacity, or roles
- NEVER generate sprint goals or strategic alignment statements
- Maximum issues per sprint: respect Max issues config value (default: 20, max: 50)
- Effort mapping is fixed and transparent -- always show which mapping was used per issue
- If priority-engine output is missing or unparseable: Block using the Block Comment Template:
  ```
  [ceos-agents] Pipeline Block
  Agent: sprint-planner
  Step: Sprint Planning
  Reason: {reason}
  Detail: {what was received}
  Recommendation: Run /ceos-agents:prioritize first to generate ranked backlog.
  ```
```

---

## 4. Skill Skeleton: /create-backlog

```markdown
---
name: create-backlog
description: Creates backlog epics in issue tracker from a specification document
allowed-tools: mcp__*, Bash, Read, Write, Edit, Glob, Grep, Task
disable-model-invocation: true
argument-hint: "<spec-path> [--decompose] [--update] [--dry-run] [--yolo]"
---

# Create Backlog

Input: `$ARGUMENTS` = spec path (positional) + optional flags

## Flag Parsing

Parse `$ARGUMENTS`:
- Remove `--decompose`, `--update`, `--dry-run`, `--yolo` from arguments string
- Remainder = spec path (file or directory)
- If spec path is empty: STOP with "Usage: /ceos-agents:create-backlog <spec-path> [--decompose] [--update] [--dry-run] [--yolo]"
- `--decompose` and `--update` are mutually exclusive. If both: STOP with "Cannot use --decompose with --update."
- `--dry-run` can combine with any other flag.

## Configuration

Read Automation Config from CLAUDE.md section `## Automation Config`. Follow `core/config-reader.md`.

**Required:**
- Issue Tracker: Type, Instance, Project

**Optional:**
- Sprint Planning: Epic template (path to custom template)
- Agent Overrides: Path (default: `customization/`)
- Decomposition: Max subtasks (default: 7) -- used only with --decompose

### 0. MCP pre-flight check

Follow `core/mcp-preflight.md`. If --dry-run, skip MCP check.

### 0b. State initialization

Create `.ceos-agents/backlog-{YYYYMMDD-HHmmss}/` directory.
Initialize `state.json` with `status: "running"`, `mode: "backlog-creation"`, `pipeline: "create-backlog"`.
Follow atomic write protocol from `core/state-manager.md`.

## Orchestration

### Step 1: Read specification

Read the spec path:
- If directory: glob `{spec-path}/epics/*.md` (scaffold v2 format). If no epics/ subdir, glob `{spec-path}/*.md`.
- If file: read the single file.
- If path does not exist or is empty: STOP with "Specification path not found or empty: {spec-path}"

### Step 2: Extract epics (backlog-creator agent)

Run `ceos-agents:backlog-creator` (Task tool, model: sonnet).
Context: specification content + Epic template path (if configured).

Before dispatch, check Agent Overrides: follow `core/agent-override-injector.md`.

If agent Blocks: display block message and STOP.

### Step 3: Human gate (preview)

If `--dry-run`:
- Display Backlog Summary table + individual epic cards
- STOP ("Dry run complete. No tracker issues created.")

Display Backlog Summary table.
Prompt: "Create {N} epics in {tracker_type} tracker? [Y/n]"
If `--yolo`: auto-approve.
If rejected: STOP ("Cancelled. No issues created.")

### Step 4: Create tracker issues

For each epic from backlog-creator output, create a tracker issue.

**Update mode (--update):**
Execute the update matching algorithm (section 12) to find existing issues.
For matched epics: update issue description via MCP.
For unmatched epics: create new issues.

**Create mode (default):**
Per-tracker dispatch (section 5) to create epic-level issues.

**Accumulator pattern:**
- On individual epic failure: log WARN, continue
- Track success_count and failure_count

### Step 4a: Decompose (--decompose only)

If `--decompose` flag:
For each successfully created epic issue:
1. Run architect agent (Task tool, model: opus) with epic specification
2. Create sub-issues from architect task tree per implement-feature Step 5a dispatch table
3. Accumulator pattern for sub-issue failures

### Step 5: Result display

Display: "Created {success_count}/{total} epic issues."
If --decompose: "Created {subtask_count} sub-tasks across {epic_count} epics."
If failures: "({failure_count} failures. Check warnings above.)"

Update state.json: set status to "completed". Follow atomic write protocol.

## Rules

- Agent Overrides: follow `core/agent-override-injector.md`
- Partial failure: NEVER block the entire pipeline on a single epic creation failure
- Language fidelity: preserve all diacritics and non-ASCII characters from spec content
- Epic issues shall NOT have the On start set state transition applied (they represent planned work)
```

---

## 5. Per-Tracker Dispatch Table: Epic Creation (/create-backlog)

Epic creation follows the same MCP tool conventions as implement-feature Step 5a, but creates top-level issues (not sub-issues). No parent parameter.

| Tracker | MCP Tool Prefix | Title Param | Description Param | Type/Label | Notes |
|---------|----------------|-------------|-------------------|------------|-------|
| YouTrack | `mcp__youtrack__*` | `summary` | `description` | `Type: Feature` | Standard issue |
| Jira | `mcp__jira__*` or `mcp__atlassian__*` | `summary` | `description` | `issuetype: "Epic"` | Use Epic issue type; fallback to Story if Epic type unavailable |
| Linear | `mcp__linear__*` | `title` | `description` | label: `feature` | Linear has no native Epic type; use label |
| Redmine | `mcp__redmine__*` | `subject` | `description` | `tracker_id: Feature` | Use Feature tracker; fallback to default tracker |
| GitHub | `mcp__github__*` | `title` | `body` | label: `epic` | Add `epic` label |
| Gitea | `mcp__gitea__*` or `mcp__forgejo__*` | `title` | `body` | label: `epic` | Add `epic` label |

**Issue Description Template (Epic Card, see section 7):**

The full epic card rendered from the Epic Card Template is used as the issue description/body.

---

## 6. Skill Skeleton: /sprint-plan

```markdown
---
name: sprint-plan
description: Plans a sprint from backlog issues using capacity constraints and priority ranking
allowed-tools: mcp__*, Bash, Read, Glob, Grep, Task
disable-model-invocation: true
argument-hint: "[--all] [--apply] [--dry-run] [--limit <N>] [--yolo]"
---

# Sprint Plan

Input: `$ARGUMENTS` = optional flags

## Flag Parsing

Parse `$ARGUMENTS`:
- `--all`: plan all sprints (release plan), not just the next one
- `--apply`: after planning, dispatch implement-feature/fix-ticket per issue
- `--dry-run`: display plan only, no tracker writes, no execution
- `--limit <N>`: override Max issues config (1-50)
- `--yolo`: auto-approve Gate 1 and Gate 3 (Gate 2 still blocks)

`--yolo` does NOT imply `--apply`. Explicit `--yolo --apply` required for full automation.
`--dry-run` overrides `--apply` (if both present, dry-run wins).

## Configuration

Read Automation Config from CLAUDE.md section `## Automation Config`. Follow `core/config-reader.md`.

**Required for sprint-plan:**
- Issue Tracker: Type, Instance, Project, Bug query
- Sprint Planning: (entire section must be present)

**Optional:**
- Feature Workflow: Feature query
- Metrics: Output
- Agent Overrides: Path (default: `customization/`)
- Build & Test: Build command, Test command (required only if --apply)

If `### Sprint Planning` section is absent: BLOCK with "Sprint Planning section not found in Automation Config. Add it to enable sprint planning."

### 0. MCP pre-flight check

Follow `core/mcp-preflight.md`.
Record tracker tier for Gate 1 display.

### 0b. State initialization

Create `.ceos-agents/sprint-{YYYYMMDD-HHmmss}/` directory.
Initialize `state.json` with `status: "running"`, `mode: "sprint-planning"`, `pipeline: "sprint-plan"`.
Follow atomic write protocol from `core/state-manager.md`.

### 0c. Velocity source determination

3-tier fallback:
- **Tier 1 (historical):** Check if `./reports/metrics.md` (or Metrics -> Output path) exists.
  If yes: read avg_time_to_fix and success_rate. Set `velocity_source = "historical"`.
  If file is corrupt or unparseable: WARN "Metrics file unreadable, falling back to heuristic." Set velocity_source to Tier 2.
- **Tier 2 (heuristic):** If Team capacity or Velocity target is configured, use effort mappings.
  Set `velocity_source = "heuristic"`.
- **Tier 3 (manual/unconstrained):** If neither capacity nor velocity configured:
  Prompt: "No capacity data. Enter team capacity for this sprint (in {unit}), or press Enter for unconstrained planning:"
  If user enters a value: use it as effective_capacity. Set `velocity_source = "manual"`.
  If user presses Enter: effective_capacity = null. Set `velocity_source = "unconstrained"`.
  In --yolo mode: skip prompt, use unconstrained. Set `velocity_source = "unconstrained"`.

Compute effective_capacity:
- Both Team capacity and Velocity target set: `min(Team capacity, Velocity target)`
- Only one set: use that value
- Neither set and Tier 3 manual value provided: use that value
- Neither set and no manual value: null (unconstrained, top-N)

If Velocity target > Team capacity: WARN "Velocity target ({V}) exceeds Team capacity ({C}). Using Team capacity."

## Orchestration

### Step 1: Fetch issues

Via MCP server (per Issue Tracker -> Type), fetch open issues.
Use Bug query + Feature query (if Feature Workflow section exists).
Limit: `--limit` flag value, or Max issues config value, or default 20.

If 0 issues found: display "No open issues found matching the query. Nothing to plan." STOP.

### Step 2: Enrich with history

If metrics report exists, read per-area data. If triage checkpoint comments exist on issues,
extract complexity estimates.

### Step 3: Run priority-engine

Run `ceos-agents:priority-engine` (Task tool, model: opus).
Context: list of issues + historical data.

Before dispatch, check Agent Overrides: follow `core/agent-override-injector.md`.

If priority-engine fails: BLOCK.

### Step 4: Run sprint-planner

Run `ceos-agents:sprint-planner` (Task tool, model: sonnet).
Context: priority-engine output + Sprint Planning config values + velocity source + --all flag.

Before dispatch, check Agent Overrides: follow `core/agent-override-injector.md`.

If sprint-planner fails: BLOCK.

### Gate 1: Capacity confirmation

Display sprint-planner output (full table).
Prompt: "Accept this sprint plan? [Y/n]"
If --yolo: auto-approve.
If rejected: STOP ("Sprint planning cancelled."). Set state status to "completed" (clean exit).

Update state.json: write sprint issue list with effort scores.

### Gate 2: Unmapped AC warning

For each issue in the Selected Issues table:
1. Check if the issue has a `[ceos-agents] Triage completed` or `[ceos-agents] Spec analysis completed` comment
2. Extract AC count from that comment
3. If AC count < 2 or no triage/spec comment exists: add to unmapped_ac_list

If unmapped_ac_list is non-empty:
- Display:
  ```
  WARNING: The following issues have insufficient acceptance criteria:
  | Issue | AC Count | Status |
  |-------|----------|--------|
  | {ID} | {N} | No triage/spec analysis |
  ```
- This gate BLOCKS even in --yolo mode.
- Prompt: "Issues without sufficient AC may produce lower-quality implementations. Continue? [Y/n]"
- If rejected: STOP.

### Gate 3: Final confirmation

If --dry-run: display plan and STOP. No tracker writes.

Display:
```
Ready to start sprint:
- Sprint: {sprint_name}
- Issues: {N}
- Tracker writes: {yes/no based on sprint_assign availability}
- Execution: {yes (--apply) / no (suggest only)}

Proceed? [Y/n]
```
If --yolo: auto-approve.
If rejected: STOP.

Update state.json: mark status as "approved".

### Step 5: Sprint assignment

For each selected issue, execute sprint_assign using 3-tier fallback (section 8).
Each assignment is NON-BLOCKING: on failure, log WARN, set `sprint_assigned: false`, continue.

Generate sprint_name: `Sprint {YYYY}-W{WW}` (current year, current ISO week).

Display: "Assigned {success}/{total} issues to {sprint_name}."

### Step 6: Execution dispatch (--apply only)

If Mode != "apply" AND --apply flag not present: STOP with suggested commands:
```
Sprint planned. To implement:
/ceos-agents:implement-feature {ID-1}
/ceos-agents:implement-feature {ID-2}
...
```

If Mode == "apply" OR --apply flag present:
For each selected issue (respecting dependency order):
1. Determine type: if issue labels/type contain "bug" -> dispatch `/ceos-agents:fix-ticket {ID}`
2. Otherwise: dispatch `/ceos-agents:implement-feature {ID}`
3. Wait for completion before starting dependent issues
4. On child pipeline block: mark dependent issues as blocked too
5. Update state.json per child pipeline status

Update state.json: set top-level status to "completed".

## Rules

- `--yolo` does NOT imply `--apply` -- explicit `--yolo --apply` needed
- Sprint assignment is ALWAYS NON-BLOCKING
- Priority-engine is invoked ONCE -- never re-run within a single sprint-plan invocation
- No sprint creation -- assign to existing sprints/milestones only. If target does not exist, warn and skip.
- Agent Overrides: follow `core/agent-override-injector.md`
- Jira pre-check: detect Scrum vs Kanban board. Kanban -> skip sprint operations, plan still generated.
```

---

## 7. Epic Card Template

The default template used by backlog-creator for each epic. Can be overridden via `Epic template` config key or Agent Overrides (`customization/backlog-creator.md`).

```markdown
## {Epic Title}

**Type:** feature
**Size:** {XS|S|M|L} ({N} SP)
**Dependencies:** {comma-separated epic titles, or "none"}

### Scope
{2-3 sentences describing what needs to be built}

### Acceptance Criteria
1. {Testable criterion}
2. {Testable criterion}
3. {Testable criterion}

### Verification
- Unit: {what to test with unit tests}
- Integration: {what to test with integration tests}
- E2E: {what to test end-to-end}
```

**Template variables:**
- `{Epic Title}`: from specification heading
- `{XS|S|M|L}`: size category from backlog-creator analysis
- `{N}`: story points mapped from size (XS=1, S=2, M=3, L=5)
- `{Dependencies}`: other epic titles or "none"
- Scope, AC, Verification sections: populated by backlog-creator

**Override mechanism (two paths):**
1. **Config key:** Set `Epic template` in `### Sprint Planning` config to a file path. The file shall contain the template with the same `{placeholder}` syntax.
2. **Agent Override:** Create `customization/backlog-creator.md` with instructions like "Always add a Technical Notes section to each epic card."

---

## 8. Per-Tracker Sprint Assignment Dispatch Table

Sprint assignment uses a 3-tier fallback. The skill tries Tier 1 first, falls back to Tier 2, then Tier 3. Every tier failure is NON-BLOCKING.

### Tier 1: MCP

| Tracker | MCP Tool | Parameters | Notes |
|---------|----------|------------|-------|
| YouTrack | `mcp__youtrack__update_issue` or equivalent | `issueId: {ID}`, `field: Sprint`, `value: {sprint_name}` | Sprint field name from config (default: `Sprint`) |
| Jira | `mcp__jira__add_issues_to_sprint` or equivalent | `sprintId: {resolved_id}`, `issues: [{ID}]` | Requires name-to-ID resolution. Pre-check: board.type must be "scrum". If Kanban: skip+warn. |
| Linear | `mcp__linear__update_issue` or equivalent | `issueId: {ID}`, `cycleId: {resolved_uuid}` | Requires name-to-UUID resolution via `list_cycles` |
| GitHub | `mcp__github__update_issue` or equivalent | `owner: {owner}`, `repo: {repo}`, `issue_number: {N}`, `milestone: {resolved_number}` | Requires milestone name-to-number resolution |
| Gitea | Skip to Tier 2 | -- | Gitea MCP sprint assignment is unverified |
| Redmine | `mcp__redmine__update_issue` or equivalent | `issue_id: {ID}`, `fixed_version_id: {resolved_id}` | Requires version name-to-ID resolution. Always Version, never Agile Plugin. |

**Name-to-ID resolution:** Before the assignment loop, resolve the sprint/milestone/cycle name to its tracker-internal identifier. Resolution is done ONCE and cached. If resolution fails (no match found): skip assignment for this tracker with WARN "Sprint/milestone '{sprint_name}' not found in {tracker_type}. Create it manually and re-run." -- NON-BLOCKING.

**Multiple match handling:** If name resolution returns multiple results, use exact string match. If still ambiguous, use the most recently created entry and WARN "Multiple sprints matching '{sprint_name}' found. Using most recent: {selected_id}."

### Tier 2: Bash + REST

Only attempted if Tier 1 fails (MCP tool not available or MCP call fails).

| Tracker | Command Pattern | Auth Environment Variable |
|---------|----------------|--------------------------|
| YouTrack | `curl -X POST {instance}/api/issues/{ID} -H "Authorization: Bearer $YOUTRACK_TOKEN" -H "Content-Type: application/json" -d '{"customFields":[{"name":"Sprint","$type":"SingleEnumIssueCustomField","value":{"name":"{sprint_name}"}}]}'` | `YOUTRACK_TOKEN` |
| Jira | `curl -X POST {instance}/rest/agile/1.0/sprint/{sprint_id}/issue -u "$JIRA_USER:$JIRA_TOKEN" -H "Content-Type: application/json" -d '{"issues":["{ID}"]}'` | `JIRA_USER`, `JIRA_TOKEN` |
| Linear | `curl -X POST https://api.linear.app/graphql -H "Authorization: $LINEAR_TOKEN" -H "Content-Type: application/json" -d '{"query":"mutation { issueUpdate(id: \"{ID}\", input: {cycleId: \"{cycle_id}\"}) { success } }"}'` | `LINEAR_TOKEN` |
| GitHub | `curl -X PATCH https://api.github.com/repos/{owner}/{repo}/issues/{N} -H "Authorization: token $GITHUB_TOKEN" -H "Content-Type: application/json" -d '{"milestone": {milestone_number}}'` | `GITHUB_TOKEN` |
| Gitea | `curl -X PATCH {instance}/api/v1/repos/{owner}/{repo}/issues/{N} -H "Authorization: token $GITEA_TOKEN" -H "Content-Type: application/json" -d '{"milestone": {milestone_id}}'` | `GITEA_TOKEN` |
| Redmine | `curl -X PUT {instance}/issues/{ID}.json -H "X-Redmine-API-Key: $REDMINE_TOKEN" -H "Content-Type: application/json" -d '{"issue":{"fixed_version_id":{version_id}}}'` | `REDMINE_TOKEN` |

If the required environment variable is not set: skip to Tier 3 immediately. Never prompt for tokens mid-pipeline.

### Tier 3: Skip + Warn

Display: "Could not assign {ID} to {sprint_name} in {tracker_type}. Assign manually in your tracker."
Set `sprint_assigned: false` for this issue.
Continue to next issue.

---

## 9. Gate UX Specifications

### Gate 1: Capacity Confirmation

**When:** After sprint-planner produces output.

**Display format:**
```
{full sprint-planner output table from REQ-SPB-017}

Accept this sprint plan? [Y/n]
```

**Behavior:**
- `--yolo`: auto-approve, display "[auto-approved]"
- User enters Y or presses Enter: proceed to Gate 2
- User enters n: STOP with "Sprint planning cancelled." State: completed (clean exit)

### Gate 2: Unmapped AC Warning

**When:** After Gate 1 approval. Only triggers if any selected issue has < 2 AC.

**Display format:**
```
WARNING: The following issues have insufficient acceptance criteria for quality implementation:

| Issue | AC Count | Concern |
|-------|----------|---------|
| PROJ-3 | 0 | No triage/spec analysis found |
| PROJ-7 | 1 | Only 1 AC -- may produce incomplete implementation |

Issues without sufficient acceptance criteria may produce lower-quality implementations.
Consider running /ceos-agents:analyze-bug or /ceos-agents:implement-feature --dry-run on these issues first.

Continue with sprint? [Y/n]
```

**Behavior:**
- `--yolo`: this gate STILL BLOCKS. Display the warning table and prompt.
- User enters Y: proceed to Gate 3
- User enters n: STOP with "Sprint planning cancelled due to AC concerns."

### Gate 3: Final Confirmation

**When:** After Gate 2 (or directly after Gate 1 if Gate 2 did not trigger).

**Display format:**
```
Ready to start sprint:
- Sprint: Sprint 2026-W16
- Issues: 5
- Total effort: 32 SP
- Tracker writes: sprint assignment via MCP (youtrack)
- Execution: suggest only (use --apply to auto-execute)

Proceed? [Y/n]
```

**Behavior:**
- `--dry-run`: display plan summary and STOP before this gate with "Dry run complete. No tracker writes performed."
- `--yolo`: auto-approve, display "[auto-approved]"
- User enters Y or presses Enter: proceed to sprint assignment
- User enters n: STOP with "Sprint planning cancelled before tracker writes."

---

## 10. Config Contract Extension

### New Optional Section: `### Sprint Planning`

```markdown
### Sprint Planning

| Key | Value |
|-----|-------|
| Sprint duration | 2 weeks |
| Capacity unit | story-points |
| Team capacity | 40 |
| Velocity target | 35 |
| Sprint field | Sprint |
| Mode | suggest |
| Max issues | 20 |
| Epic template | (none) |
```

This section is parsed by `core/config-reader.md` into:
- `sprint_planning.sprint_duration` (default: `2 weeks`)
- `sprint_planning.capacity_unit` (default: `story-points`)
- `sprint_planning.team_capacity` (default: none)
- `sprint_planning.velocity_target` (default: none)
- `sprint_planning.sprint_field` (default: tracker-dependent, see Sprint Model table)
- `sprint_planning.mode` (default: `suggest`)
- `sprint_planning.max_issues` (default: 20)
- `sprint_planning.epic_template` (default: none)

**config-reader.md update:** Add `### Sprint Planning` to the optional sections list with the above keys and defaults.

**Validation rules:**
- `Sprint duration`: must be one of `1 week`, `2 weeks`, `3 weeks`, `4 weeks`. Other values: WARN and use default.
- `Capacity unit`: must be `story-points` or `hours`. Other values: WARN and use default.
- `Team capacity`: must be positive integer. 0 treated as unconfigured.
- `Velocity target`: must be positive integer. Must be <= Team capacity if both set.
- `Sprint field`: string. If empty, use tracker-dependent default.
- `Mode`: must be `suggest` or `apply`. Other values: WARN and use `suggest`.
- `Max issues`: must be integer 1-50. Out of range: clamp to [1, 50] with WARN.
- `Epic template`: file path. If set but file not found: WARN and use built-in template.

---

## 11. State Schema Extensions

### New RUN-ID Formats

| Pipeline type | RUN-ID format | Example |
|---------------|---------------|---------|
| Sprint planning | `sprint-{YYYYMMDD-HHmmss}` | `sprint-20260413-143000` |
| Backlog creation | `backlog-{YYYYMMDD-HHmmss}` | `backlog-20260413-143000` |

### New mode Values

| Mode | Pipeline |
|------|----------|
| `sprint-planning` | sprint-plan |
| `backlog-creation` | create-backlog |

### Sprint State Object (for sprint-plan)

```json
{
  "schema_version": "1.0",
  "run_id": "sprint-20260413-143000",
  "parent_run_id": null,
  "mode": "sprint-planning",
  "pipeline": "sprint-plan",
  "status": "running",
  "started_at": "ISO-8601",
  "updated_at": "ISO-8601",
  "config": {
    "profile": null,
    "flags": ["--apply"],
    "retry_limits": {
      "fixer_iterations": 5,
      "test_attempts": 3,
      "build_retries": 3
    }
  },
  "sprint": {
    "name": "Sprint 2026-W16",
    "duration": "2 weeks",
    "effective_capacity": 35,
    "velocity_source": "historical",
    "issues": [
      {
        "issue_id": "PROJ-42",
        "tier": "P0",
        "effort_points": 2,
        "type": "bug",
        "sprint_assigned": false,
        "child_run_id": null,
        "status": "pending"
      }
    ],
    "completed_issues": 0,
    "blocked_issues": 0
  }
}
```

### Backlog State Object (for create-backlog)

```json
{
  "schema_version": "1.0",
  "run_id": "backlog-20260413-143000",
  "parent_run_id": null,
  "mode": "backlog-creation",
  "pipeline": "create-backlog",
  "status": "running",
  "started_at": "ISO-8601",
  "updated_at": "ISO-8601",
  "config": {
    "profile": null,
    "flags": [],
    "retry_limits": {
      "fixer_iterations": 5,
      "test_attempts": 3,
      "build_retries": 3
    }
  },
  "backlog": {
    "spec_path": "spec/",
    "epics_total": 4,
    "epics_created": 0,
    "epics_failed": 0,
    "subtasks_created": 0,
    "created_issues": []
  }
}
```

### 5 State Update Points (sprint-plan)

1. After config validation: write initial state with `status: "running"`, empty issues array
2. After Gate 1 confirmed: write issue list with effort scores, effective_capacity, velocity_source
3. After Gate 3 confirmed: mark status as `"approved"`
4. Per child pipeline start/complete/block: update `child_run_id`, issue `status`, increment counters
5. On pipeline completion: set top-level `status: "completed"`

### 3 State Update Points (create-backlog)

1. After config validation: write initial state with `status: "running"`, spec_path, epics_total
2. Per epic created: increment `epics_created`, append to `created_issues`
3. On pipeline completion: set top-level `status: "completed"`

---

## 12. --update Matching Algorithm

The `--update` flag on /create-backlog identifies existing tracker issues that correspond to epics in the specification, then updates their descriptions instead of creating duplicates.

### Algorithm

```
INPUT: epic_list (from backlog-creator), tracker_type, tracker_project
OUTPUT: matched_pairs [{epic_index, tracker_issue_id}], unmatched_epics [epic_index]

1. Fetch all open issues from the tracker project matching:
   - Type/label: "Feature" or "Epic" (tracker-specific query)
   - State: open/in-progress (not resolved/closed)
   - Limit: 100 issues max

2. For each epic in epic_list:
   a. Normalize the epic title: lowercase, strip leading/trailing whitespace,
      collapse multiple spaces to single space.
   b. For each tracker issue:
      - Normalize the tracker issue title using the same rules
      - Compute similarity score using TWO methods:
        (i)  Prefix match: do the first 40 characters match? (boolean)
        (ii) Token overlap: split both titles into word tokens (split on whitespace and punctuation),
             compute Jaccard similarity = |intersection| / |union|
      - Match criteria: prefix match OR Jaccard similarity >= 0.7
   c. If exactly one tracker issue matches: pair them.
   d. If multiple tracker issues match: select the one with highest Jaccard similarity.
      If tied, select the most recently updated. WARN: "Multiple matches for epic '{title}'. Using {selected_id}."
   e. If no tracker issue matches: add to unmatched_epics list.

3. Display match results:
   ```
   ## Update Preview

   | # | Epic | Match | Tracker Issue | Similarity |
   |---|------|-------|---------------|------------|
   | 1 | Auth Module | MATCHED | PROJ-12 | 0.85 |
   | 2 | Notifications | NEW | -- | -- |

   Update 1 existing issue(s) and create 1 new issue(s)? [Y/n]
   ```

4. On confirmation (or --yolo auto-approve):
   - For matched pairs: update issue description via MCP (preserve title, update body)
   - For unmatched epics: create new issues (same as default create mode)
```

### Edge Cases

- **Empty tracker (0 open issues):** All epics are unmatched. Behaves like create mode.
- **Epic title changed significantly:** No match found. New issue created. User should close the old one manually.
- **Tracker issue already closed:** Not included in the fetch (filtered by open state). New issue created.

---

## 13. Capacity Model Detail

### Effort-to-Unit Mappings (Fixed)

**Story Points (Fibonacci-adjacent):**

| Priority-Engine Effort Score | Story Points |
|------------------------------|-------------|
| 1 (trivial) | 1 |
| 2 (simple) | 2 |
| 3 (medium) | 3 |
| 4 (complex) | 5 |
| 5 (very complex) | 8 |

**Hours:**

| Priority-Engine Effort Score | Hours |
|------------------------------|-------|
| 1 (trivial) | 0.5 |
| 2 (simple) | 1.0 |
| 3 (medium) | 2.0 |
| 4 (complex) | 4.0 |
| 5 (very complex) | 8.0 |

### Triage Complexity Precedence

When an issue has a `[ceos-agents] Triage completed` or `[ceos-agents] Spec analysis completed` comment with a complexity field, that complexity takes precedence over the priority-engine's Effort score.

**Complexity to Story Points:**

| Complexity | Story Points |
|------------|-------------|
| XS | 1 |
| S | 2 |
| M | 3 |
| L | 5 |

**Complexity to Hours:**

| Complexity | Hours |
|------------|-------|
| XS | 2 |
| S | 4 |
| M | 8 |
| L | 16 |

### Effective Capacity Computation

```
IF Team capacity AND Velocity target both configured:
    IF Velocity target > Team capacity:
        WARN "Velocity target exceeds Team capacity. Using Team capacity."
        effective_capacity = Team capacity
    ELSE:
        effective_capacity = min(Team capacity, Velocity target)
ELSE IF only Team capacity configured:
    effective_capacity = Team capacity
ELSE IF only Velocity target configured:
    effective_capacity = Velocity target
ELSE:
    effective_capacity = null  (unconstrained mode)
```

### Velocity 3-Tier Fallback

| Tier | Source | Condition | velocity_source value |
|------|--------|-----------|----------------------|
| 1 | `./reports/metrics.md` or Metrics -> Output path | File exists and is parseable | `"historical"` |
| 2 | Effort mappings + config capacity | Team capacity or Velocity target configured | `"heuristic"` |
| 3 | User prompt (interactive) or top-N (--yolo/unattended) | Neither configured, no metrics | `"manual"` or `"unconstrained"` |

### Cold-Start Annotation

When velocity_source is not `"historical"`, every gate display shall include:

```
NOTE: This plan uses {velocity_source} velocity data. Capacity estimates
may not reflect actual team throughput. Run /ceos-agents:metrics after
completing this sprint to calibrate future planning.
```

---

## 14. Scaffold Step 4e: Refactor to Use backlog-creator

**Decision: REFACTOR scaffold Step 4e to dispatch backlog-creator agent in task mode.**

backlog-creator supports two modes (spec mode and task mode). In task mode, it accepts architect
decomposition output and produces structured sub-task cards. This allows scaffold Step 4e to:

1. Dispatch backlog-creator in task mode with architect's decomposition output as input
2. Receive structured sub-task cards back
3. The **scaffold skill** (not the agent) handles tracker-specific operations:
   - Creating issues via per-tracker dispatch table (same as today)
   - Writing back-reference comments (`<!-- {TrackerType}: {ID} -->`) into spec files
   - Maintaining parent-child relationships

**What changes in scaffold Step 4e:**
- Replace inline story extraction logic with backlog-creator dispatch (Task tool)
- Pass architect output as context to backlog-creator
- Process backlog-creator's structured card output through existing tracker dispatch table
- Back-reference writing and idempotency checking remain in the skill

**What stays the same:**
- Back-reference protocol (`<!-- ... -->`) stays in the skill
- Parent-child issue creation logic stays in the skill
- Step 5/8a/8b dependencies on epic IDs are unaffected

**Benefit:** One agent for issue card extraction, two consumers (create-backlog skill, scaffold skill).
No code duplication in card extraction logic. Tracker dispatch can also be extracted to
`core/tracker-issue-creator.md` as a shared core pattern in a follow-up PATCH.

---

## 15. Workflow Router Updates

Add these rows to `skills/workflow-router/SKILL.md` Intent Mapping table:

| User Intent | Command | Arguments | Destructive? |
|-------------|---------|-----------|-------------|
| Create backlog / convert spec to issues / extract epics | `ceos-agents:create-backlog` | Spec path + optional: --decompose, --update, --dry-run | Yes |
| Plan a sprint / sprint planning / plan next sprint | `ceos-agents:sprint-plan` | Optional: --all, --apply, --dry-run, --limit N | Yes |
| Plan all sprints / release plan | `ceos-agents:sprint-plan` | `--all` | Yes |
| Decompose a feature into subtasks only (without implementation) | `ceos-agents:implement-feature` | Issue ID + `--decompose-only` | Yes |

---

## 16. implement-feature Changes for --decompose-only

### Flag Parsing Update

Add `--decompose-only` to the flag parsing section:
- `--decompose-only`: `decompose_only_mode = true`
- `--decompose-only` with `--no-decompose`: STOP with mutual exclusion error
- `--decompose-only` implies `--decompose` (force decomposition)

### Pipeline Flow

When `decompose_only_mode = true`:
1. Execute Steps 0 through 5a normally (config, MCP, spec-analyst, architect, decomposition, tracker subtask creation)
2. After Step 5a completes: display decomposition plan table
3. Display: "Decomposition complete. {N} subtasks created in tracker. Run `/ceos-agents:implement-feature {ISSUE-ID}` to begin implementation."
4. Set state.json `status: "completed"`, `decomposition.status: "completed"`
5. EXIT -- do not proceed to Step 6 or beyond

This is an early-exit pattern, not a new pipeline. The same state.json schema is used.
