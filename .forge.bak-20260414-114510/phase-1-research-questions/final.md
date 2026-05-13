# Phase 1: Research Findings — Sprint Planning for ceos-agents

## Executive Summary

- **Sprint planning as backlog selection is feasible and thin to build.** The entire feature reduces to one new skill (~50-line orchestration), one new sonnet agent (capacity fitting, ~60 lines), two workflow-router intent rows, and one optional config section. All heavy lifting is delegated to the already-built priority-engine.
- **MCP sprint creation is the weakest link across all trackers.** Only GitHub and Gitea (via `create_milestone`) have confirmed MCP creation support. YouTrack, Jira, and Linear all require Bash + REST fallbacks for sprint creation. Issue-to-sprint assignment is better-covered but still has gaps for YouTrack and Gitea.
- **A 3-tier fallback strategy is required:** (a) MCP tool where confirmed, (b) Bash + REST where MCP unverified, (c) skip with warning if both unavailable. Sprint assignment must be non-blocking — pipeline continues even on failure.
- **Vocabulary is inconsistent across trackers.** "Sprint" maps to: Sprint (YouTrack/Jira), Cycle (Linear), Milestone (GitHub/Gitea), Version or Agile Sprint (Redmine). The config contract needs a tracker-agnostic `Sprint field` key; the skill must apply tracker-specific write logic based on `Issue Tracker → Type`.
- **Semi-autonomous with `--yolo` escape hatch is the right interaction model.** Four human gates (capacity confirmation, decomposition approval per issue, scope adjustment, final sprint start) modeled on existing `[Y/n]` prompts from implement-feature and fix-bugs. All gates auto-approve under `--yolo` for CI.
- **Cold-start velocity is solvable via a three-tier heuristic fallback** (historical metrics → effort-score heuristics → manual prompt). Sprint plan must prominently annotate when heuristics are used, matching the estimate skill's warning pattern.
- **Version bump is MINOR** — purely additive: one optional config section with no required keys, one new skill, one new agent. Identical precedent to Browser Verification (v5.1.0) and Local Deployment (v5.3.0).

---

## 1. Tracker Sprint API Capabilities

### Cross-Tracker Comparison Matrix

| Feature | YouTrack | Jira | Linear | GitHub | Gitea | Redmine |
|---------|----------|------|--------|--------|-------|---------|
| Native sprint object | Yes (Sprint) | Yes (Sprint, Scrum boards only) | Yes (Cycle) | No | No | Partial (Version core; Sprint via plugin) |
| Sprint proxy used by ceos-agents | — | — | — | Milestone | Milestone | Version (always), Agile Sprint (plugin) |
| Create sprint via MCP | Unverified (`@vitalyostanin`) | Not confirmed (`sooperset`) | Unverified (official) | `create_milestone` confirmed | `create_milestone` confirmed | `create_version` likely |
| Assign issue to sprint via MCP | Unverified | `jira_add_issues_to_sprint` confirmed | `update_issue(cycleId)` confirmed | `update_issue(milestone)` confirmed | Unverified | `update_issue(fixed_version_id)` likely |
| Query sprint issues via MCP | Query language (reliable) | JQL `sprint = "X"` (reliable) | `list_issues(cycleId)` confirmed | `list_issues(milestone)` confirmed | Unverified | `list_issues(fixed_version_id)` likely |
| Sprint start date supported | Yes | Yes | Yes (Cycle) | No (due_on only) | No (due_on only) | No (due_date only) |
| Sprint state machine | Yes (active/archived) | Yes (future/active/closed) | Yes (active/completed) | Open/Closed only | Open/Closed only | Open/Locked/Closed |
| Velocity tracking | Yes (board) | Yes (board) | Yes (built-in) | No | No | No (Agile plugin only) |
| MCP package (ceos-agents default) | `@vitalyostanin/youtrack-mcp` | `@modelcontextprotocol/server-atlassian` | `@modelcontextprotocol/server-linear` | `@modelcontextprotocol/server-github` | `forgejo-mcp` | `mcp-server-redmine` |
| Sprint tooling confidence | Low | Medium | High (assign), Low (create) | High (milestone) | Medium (create confirmed, assign unverified) | Medium (version), Low (agile sprint) |

### Per-Tracker Details

**YouTrack** — First-class sprint support via Agile Boards (`/api/agiles/{agileID}/sprints`). Sprint fields: `name`, `goal`, `start`/`finish` (epoch ms), `isDefault`, `archived`. Issues assigned via `/api/agiles/{agileID}/sprints/{sprintID}/issues` or by setting the `Sprint` custom field via issue update. The literal `"current"` token addresses the active sprint without needing the sprint ID. The default `@vitalyostanin/youtrack-mcp` package has unverified sprint tool coverage; the competing `abdullahtas0/youtrack-mcp-server` (44 tools) and `randomnerd/youtrack-mcp` explicitly expose sprint CRUD but are not the registered package. Safest assignment path: set `Sprint` custom field via `mcp__youtrack__update_issue`; safest creation path: Bash + `curl` with `YOUTRACK_TOKEN`.

**Jira** — Sprint belongs to a Scrum board (`/rest/agile/1.0/`). Sprint states: `future`, `active`, `closed`. Kanban boards have no sprint concept — board type must be detected before sprint operations. `sooperset/mcp-atlassian` confirms: `jira_add_issues_to_sprint`, `jira_get_boards`, `jira_get_sprints` (with state filter). Sprint creation via MCP not confirmed; requires Bash + REST. `@modelcontextprotocol/server-atlassian` (the ceos-agents default) has unverified tool names that may differ from sooperset's documentation. Sprint API requires Jira Software license — not available on Jira Work Management.

**Linear** — Uses **Cycles** (not "sprints"). Cycle is team-scoped, not project-scoped. Official Linear MCP (released 2025-05-01) confirms: `update_issue(cycleId)` and `create_issue(cycleId)` for assignment, `list_issues` with cycle filter for querying. A dedicated `create_cycle` MCP tool is unverified; Bash + Linear GraphQL (`mutation { cycleCreate(...) }` at `https://api.linear.app/graphql`) is the reliable creation path. Cycle UUID must be resolved before assignment — no string-name lookup in most MCP tools. Official MCP uses OAuth (remote); authentication flow differs from API-key-based servers.

**GitHub** — No native sprint. Two proxies: (1) **Milestones** (closest equivalent — title, due date, open/closed state, confirmed MCP tooling); (2) **Projects V2 Iteration fields** (true sprint with start+end dates and cadence, but MCP iteration field support is incomplete — GitHub issue #1854 open as of research date; requires `--toolsets projects` flag). Milestone is the safe, confirmed sprint proxy. Milestone limitation: no start date (only `due_on`), no sprint state machine beyond open/closed.

**Gitea/Forgejo** — No native sprint. Milestone proxy (identical semantics to GitHub milestones). `raohwork/forgejo-mcp` confirms: `list_repo_milestones`, `create_milestone`, edit/delete milestone. Issue-to-milestone assignment via `mcp__gitea__update_issue(milestone: N)` is **unverified** — Bash + Gitea REST (`PATCH /api/v1/repos/{owner}/{repo}/issues/{index}`) is the reliable fallback. No start date in milestones. Gitea and Forgejo share the same REST API surface.

**Redmine** — **Two-tier model:**
- *Core Versions* (always available): `fixed_version` field on issues (`PUT /issues/{id}.json`). MCP `create_version` and `update_issue(fixed_version_id)` are likely available via `runekaagaard/mcp-redmine` (~100% API coverage claim). `fixed_version_id` is numeric; name must be resolved to ID first via `list_versions`.
- *Agile Plugin Sprints* (plugin-dependent): RedmineUP Agile plugin v1.5.0+ adds separate sprint objects (`/projects/{id}/agile_sprints/`). Assigned via `agile_data_attributes.agile_sprint_id`. Not available in MCP servers targeting core Redmine API; requires Bash + REST. Plugin presence must be detected before attempting these operations. **ceos-agents should default to Version for maximum compatibility.**

### MCP Tool Availability Assessment

| Operation | Confirmed via MCP | Requires Bash Fallback |
|-----------|-------------------|----------------------|
| Query sprint issues | All trackers (via native query language) | None |
| Assign to sprint | Linear, Jira, GitHub | YouTrack, Gitea, Redmine (likely MCP, but unverified) |
| Create sprint | GitHub, Gitea | YouTrack, Jira, Linear, Redmine |

**Key insight:** Query is universally reliable via native query languages (YouTrack query language, JQL, GraphQL, milestone filters). Sprint assignment is moderately covered. Sprint creation is the most fragile operation across the two primary enterprise trackers (YouTrack, Jira).

### Recommended Architecture: 3-Tier Strategy

For every sprint operation across all trackers:

1. **Tier 1 — Try MCP tool** (where confirmed: GitHub, Gitea, Jira assign, Linear assign, Redmine version)
2. **Tier 2 — Bash + REST fallback** (where MCP unverified: YouTrack create, Jira create, Linear create, Gitea assign)
3. **Tier 3 — Skip with warning** if both unavailable; pipeline continues

Sprint assignment must be **optional and non-blocking** — failure to assign an issue to a sprint must never abort the fix or implement pipeline. This is a metadata operation, not a code-change gate.

Additional rules:
- Resolve sprint/cycle/milestone by name before operations; never hardcode IDs in config
- Detect Redmine Agile plugin before attempting agile sprint operations (core Version is the default)
- Detect Jira board type (Scrum vs. Kanban) before attempting sprint operations

---

## 2. Semi-Autonomous Workflow Design

### Decision Matrix (Autonomous vs Semi-Autonomous)

| Decision Point | Autonomous (`--yolo`) | Semi-Autonomous (default) | Rationale |
|----------------|----------------------|--------------------------|-----------|
| Issue selection from backlog | AI selects top-N by priority score | AI presents ranked list, human confirms | Business context (team goals, capacity) cannot be inferred |
| Capacity ceiling | Use static config value | AI suggests based on velocity, human confirms or adjusts | Velocity on cold start is unknown; human must set first sprint budget |
| Sprint goal statement | Auto-generate from top-3 P0 titles | AI drafts, human approves before pipeline starts | Sprint goal is a communication artifact needing human ownership |
| Scope negotiation (add/remove) | Not applicable | Interactive toggle per issue before final gate | Silent overflow of capacity is unacceptable |
| Decomposition approval per issue | Auto-approved (mirrors `--yolo` in implement-feature step 5) | Wait for confirmation per issue (matches implement-feature step 5 default) | Decomposition changes branch strategy and subtask count — high stakes |
| Unmapped AC in decomposition | Block (matches YOLO behavior in fix-bugs line 188) | Ask: "Continue anyway? [Y/n]" (matches non-YOLO behavior) | Consistent with existing AC coverage check pattern |
| Start pipeline after plan approval | Auto-start immediately | Show final plan table, require explicit "Start sprint? [Y/n]" | Prevents accidental launch of multi-issue batch |

### Human Interaction Points

All gates use the existing `[Y/n]` prompt pattern from implement-feature and fix-bugs. No new interaction primitives are needed.

**Gate 1 — Capacity confirmation** (after priority-engine output):
```
Suggested sprint: {N} issues — {total_estimated_effort} effort points
Team capacity: {configured_value or "unknown"}
Proceed with this selection? [Y/n]
```
Pattern source: implement-feature step 0c (card preview prompt).

**Gate 2 — Decomposition approval per issue** (for each issue where architect recommends decomposition):
Display plan table, wait for `Continue? [Y/n]`. Pattern source: fix-bugs step 3b (line 174).

**Gate 3 — Unmapped AC warning** (for decomposed issues with gaps):
```
Continue anyway? The unmapped criteria will not be explicitly addressed. [Y/n]
```
Pattern source: fix-bugs line 188.

**Gate 4 — Final sprint start gate** (last human gate before execution):
```
## Sprint Plan — {sprint_name}

| # | Issue | Tier | Effort | Decompose? | Subtasks |
|---|-------|------|--------|------------|---------|
...

Total effort: ~{N} | Issues: {N} | Est. cost: ~${min}-${max}

Start sprint? [Y/n]
```
Pattern source: implement-feature step 5 decomposition plan display (lines 224-237).

**Gate 5 — Scope adjustment** (before Gate 4, optional):
```
Add or remove issues? Enter issue ID to toggle, or press Enter to continue.
```
This is a new interaction style modeled on the `discuss` skill step 5 follow-up prompt pattern.

**Important:** After decomposition approval (Gate 2), sprint planning must re-estimate capacity because a decomposed issue's effort multiplies by subtask count (up to `max_subtasks = 7`). The final sprint plan table at Gate 4 must reflect post-decomposition effort totals.

### Velocity Cold Start Strategy

**Three-tier fallback:**

1. **Tier 1 — Historical data available:** Read `./reports/metrics.md` (or Metrics → Output config path). Extract `avg_time_to_fix` and `success_rate`. Derive estimated velocity = `(team_capacity_hours / avg_time_to_fix) × success_rate`.

2. **Tier 2 — Cold start (metrics unavailable):** Fall back to priority-engine effort scores. Effort 1-5 maps to: 1=0.5h, 2=1h, 3=2h, 4=4h, 5=8h (same order-of-magnitude as the estimate skill's token cost table). Suggest initial sprint = issues whose summed effort ≤ configurable capacity ceiling.

3. **Tier 3 — No capacity configured:** Prompt user once at planning start:
   ```
   No team capacity configured and no historical velocity data found.
   Estimated hours available this sprint: [enter number or press Enter to skip capacity check]
   ```
   If skipped, operate without capacity ceiling and show warning banner in sprint plan.

**Cold-start annotation** (applied when Tier 2 or Tier 3 is used):
```
Warning: Velocity estimate based on heuristics only — no historical data found.
  Run /ceos-agents:metrics after this sprint to calibrate future planning.
```
This matches the estimate skill step 7 pattern ("Based on heuristics only").

---

## 3. Integration with Existing Components

### Priority-Engine Integration

**Pattern:** `skills/prioritize/SKILL.md` runs `ceos-agents:priority-engine` via Task tool (step 3, line 38) and displays the result. Sprint planning reuses this exact invocation.

**Recommendation: inline the priority-engine call** rather than requiring `/prioritize` as a prerequisite. The orchestration in `skills/prioritize/SKILL.md` is ~50 lines (fetch → enrich → run agent); inlining avoids a prerequisite step users will forget.

**Hard limit inherited from priority-engine:** Maximum 50 issues per analysis (priority-engine.md line 65). Sprint planning cannot plan across more than 50 issues in a single pass. If the backlog exceeds 50, the sprint is chosen from the top 50 by creation date. This limit must be documented in the sprint-plan skill.

**Priority-engine output reuse:** The `Recommendations` section already contains a `Suggested batch: {top N issues for next /fix-bugs run}` field (line 58). Sprint planning reads this as the initial issue selection and presents it as the suggested sprint set.

### Fix-Bugs Relationship

Sprint planning is a **pre-flight orchestrator**, not a replacement for fix-bugs or implement-feature:

```
/sprint-plan → issue selection + capacity check → human approval
  → FOR EACH issue: route to /fix-bugs or /implement-feature (per issue type)
```

`skills/fix-bugs/SKILL.md` already supports batch processing (line 99: `Limit = count from $ARGUMENTS`) and parallel triage (line 101). Sprint planning passes the approved issue list to a single `fix-bugs N` call and inherits the parallel triage + sequential fix behavior. No new batch loop implementation is needed.

The key difference from plain `fix-bugs`: sprint planning adds a planning gate before execution — capacity check, goal statement, scope negotiation. Plain `fix-bugs` has no such gate.

**Flag compatibility:** Sprint planning supports `--dry-run` (inherited from fix-bugs step 0, line 93-95) to preview the sprint plan without executing the pipeline.

### State Persistence

**Current schema** (`state/schema.md`) is per-issue (`.ceos-agents/{ISSUE-ID}/state.json`). Sprint planning requires cross-issue state.

**Required new top-level state file:** `.ceos-agents/sprint-{timestamp}/state.json`

New RUN-ID type to add to `state/schema.md` RUN-ID table (lines 22-27):

| Pipeline type | RUN-ID format | Example |
|---------------|--------------|---------|
| Sprint planning run | `sprint-{timestamp}` | `sprint-20260413-143000` |

Proposed sprint state schema:

```json
{
  "schema_version": "1.0",
  "run_id": "sprint-20260413-143000",
  "mode": "sprint-planning",
  "pipeline": "sprint-plan",
  "status": "running",
  "started_at": "ISO-8601",
  "updated_at": "ISO-8601",
  "sprint": {
    "goal": "string or null",
    "capacity_hours": null,
    "velocity_source": "historical | heuristic | manual | unconstrained",
    "issues": [
      {
        "issue_id": "PROJ-42",
        "priority_score": 8.5,
        "tier": "P0",
        "effort": 3,
        "type": "bug | feature",
        "child_run_id": "PROJ-42",
        "status": "pending | running | completed | blocked | skipped"
      }
    ],
    "total_effort": null,
    "approved_at": null,
    "started_at": null,
    "completed_issues": 0,
    "blocked_issues": 0
  }
}
```

`child_run_id` links to individual `.ceos-agents/{ISSUE-ID}/state.json` for drill-down — analogous to `parent_run_id` in schema.md line 36 (scaffold spawning sub-runs). The atomic write protocol (`state.json.tmp` → rename, defined in schema.md lines 270-276) must be followed.

### Dashboard/Metrics

**Dashboard** (`skills/dashboard/SKILL.md`): No changes needed for individual issue tracking. Sprint-originated issues produce the same `[ceos-agents]` comment format and appear correctly in the existing stage inference logic (lines 60-68). Sprint-level aggregation (goal, issues completed/blocked/pending) would require reading `.ceos-agents/sprint-*/state.json` — this is additive and suitable for a follow-up MINOR release.

**Metrics** (`skills/metrics/SKILL.md`): Per-issue metrics work without changes (same `[ceos-agents]` comments + git log inputs). New sprint-level metrics (`sprint_completion_rate`, `sprint_velocity_actual`) would require reading sprint state files — not currently done. Recommended as an optional section guarded by checking whether any `sprint-*` state files exist. Backward-compatible, suitable for follow-up MINOR release.

---

## 4. Config Contract

### Proposed Sprint Planning Section

All keys are optional. Section absence means sprint planning is disabled; skills skip sprint-related steps silently.

```markdown
### Sprint Planning

| Key | Value |
|-----|-------|
| Sprint duration | 2 weeks |
| Capacity unit | story-points |
| Team capacity | 40 |
| Velocity target | 35 |
| Sprint field | Sprint |
| Priority field | Priority |
| Mode | suggest |
| Max issues | 20 |
| Include types | bug, feature |
| Exclude labels | blocked, wont-fix |
| Estimation field | Story points |
| Report path | reports/sprint-plan.md |
```

**Key definitions:**

| Key | Default | Description |
|-----|---------|-------------|
| Sprint duration | `2 weeks` | Length of one sprint: `1 week`, `2 weeks`, `3 weeks`, `4 weeks`. |
| Capacity unit | `story-points` | `story-points`, `hours`, or `days`. |
| Team capacity | (none) | Total capacity in Capacity unit. Absent → planner skips capacity fit check. |
| Velocity target | (none) | Historically delivered units per sprint. When both Team capacity and Velocity target are set → `min(Team capacity, Velocity target)` is used. |
| Sprint field | `Sprint` | Name of the custom field / tracker concept for sprint assignment. Tracker-specific behavior: YouTrack/Jira → custom field; GitHub/Gitea → milestone; Linear → cycle. |
| Priority field | `Priority` | Name of the priority field in the tracker, used to rank candidates. |
| Mode | `suggest` | `suggest` = read-only recommendation (default). `apply` = write sprint assignments to tracker after confirmation. |
| Max issues | `20` | Maximum issues to consider per run. Maps to `--limit` pattern from `/prioritize`. |
| Include types | `bug, feature` | Comma-separated issue types to include. |
| Exclude labels | (none) | Comma-separated labels that permanently disqualify an issue from sprint consideration. |
| Estimation field | (none) | Tracker field name for story points. Absent → derive from triage complexity (XS=1, S=2, M=3, L=5 story-points; or XS=2h, S=4h, M=8h, L=16h for hours). |
| Report path | (none) | If set, write sprint plan report to this file in addition to stdout. |

**Important:** `Sprint field` must be interpreted tracker-specifically in the skill (read `Issue Tracker → Type`). This conditional complexity should be documented in `docs/reference/automation-config.md` following the same pattern as State transitions documentation.

### Version Bump Assessment

**MINOR (X.Y.0)** — new backward-compatible optional section.

Rationale per CLAUDE.md Versioning Policy: "Adding an **optional** section = MINOR." Zero impact on projects that do not configure it. No existing Automation Config key is renamed or removed. No existing agent output format contract changes. Structurally identical to Browser Verification (v5.1.0, MINOR), Local Deployment (v5.3.0, MINOR).

Note for changelog: `Mode: apply` is the first skill to write sprint *metadata* (not just issue state transitions). This behavioral distinction should be explicitly called out in the changelog entry even though the version bump is MINOR.

### Pipeline Profile Interaction

Sprint planning is **not a pipeline stage**. It is a standalone pre-pipeline skill (like `/prioritize` or `/estimate`) that produces a plan but does not execute the fix or implement pipeline.

Consequence: Sprint Planning config does NOT interact with `### Pipeline Profiles`. Pipeline Profiles control skip/extra stages within `fix-ticket`, `fix-bugs`, and `implement-feature`. Sprint planning runs before those skills. Sprint planning has no `Skip stages` or profile-override capability. The user selects a profile independently when launching the execution skills.

---

## 5. Scope Boundaries

### In Scope

- **Sprint backlog selection:** Query open issues, apply priority + capacity constraints, produce a ranked list of issues fitting the upcoming sprint. Core value: replacing manual backlog grooming with AI-assisted selection.
- **Capacity fitting:** Given team capacity (story-points or hours) and velocity target, trim or extend the proposed issue list to fit the sprint window.
- **Size derivation:** If no `Estimation field` is configured, derive size from triage-analyst complexity labels already present in tracker comments (`[ceos-agents] Triage completed. ... Complexity: M.`). Reuses existing structured data without adding a new pipeline stage.
- **Sprint assignment (optional, `Mode: apply`):** After human confirmation, write the sprint assignment to the tracker using `Sprint field` and tracker MCP server.
- **Sprint plan report:** Markdown table with ID, title, complexity/size, priority, rationale. Saved to `Report path` if configured.
- **Dependency awareness:** Reuse priority-engine's dependency graph logic. Issues that block others are prioritized. Sprint-planner delegates ranking to priority-engine and applies capacity constraints on top.

### Out of Scope

The following were explicitly considered and rejected — they remain in the NOT PLANNED section of the roadmap:

- **Sprint review automation** — team ceremony requiring human judgment on "done," demo narratives, stakeholder feedback
- **Sprint retrospective** — human-facilitated team dynamics discussion, outside CLI plugin capability
- **Burndown tracking** — live metric; trackers' native burndown views already handle this; `/metrics` covers pipeline analytics
- **Velocity history computation** — tracker-specific (YouTrack/Jira/Linear have native velocity charts); replicating in markdown adds fragility; `Velocity target` is configured manually
- **Sprint goal writing** — product management task requiring business objective context
- **Issue estimation (story pointing)** — planning poker model requires interactive team sessions
- **Multi-team / per-person capacity breakdown** — pure PM tooling; `Team capacity` is a single aggregate number

### Minimum Viable Sprint Planning

The minimum feature delivering genuine value with no scope creep:

1. Read open issues from tracker (reuse existing MCP + Bug query / Feature query pattern)
2. Dispatch `ceos-agents:priority-engine` (Task tool, opus) — already exists, already ranks by impact/risk/effort
3. Apply capacity constraint: walk ranked list, accumulate estimated sizes, stop when capacity reached
4. Output a sprint plan table: `| # | Issue | Size | Priority | Rationale |` — human-readable, tracker-independent
5. If `Mode: apply` → confirm with user, write `Sprint field` to each planned issue via MCP

**Agents required for MVP:** priority-engine (exists) + sprint-planner (new, ~60 lines). No other agents needed. The sprint-planner is thin enough that its logic could be inlined in the skill — but a dedicated agent keeps architecture clean and model costs predictable.

---

## 6. New Components Inventory

### sprint-planner Agent

**Purpose:** Applies capacity constraints and sprint-specific scoring on top of priority-engine output to produce a sprint plan. Distinct from priority-engine: priority-engine is a general backlog ranker (opus, complex dependency reasoning across 50 issues); sprint-planner receives pre-ranked output and applies simpler arithmetic capacity constraints (sonnet is sufficient).

**Proposed frontmatter:**
```markdown
---
name: sprint-planner
description: Applies capacity constraints to a prioritized backlog to produce a sprint plan with fit analysis
model: sonnet
style: Pragmatic, capacity-aware, time-boxed
---
```

**Sections (sketch):**
- **Goal:** Receive a prioritized issue list and sprint capacity parameters; produce a sprint plan that fits within the sprint window, accounting for team velocity, issue sizes, and dependencies.
- **Expertise:** Capacity planning, sprint sizing, dependency ordering, scope negotiation.
- **Process:**
  1. Receive: prioritized issue list (from priority-engine), Sprint Planning config keys.
  2. Filter: remove issues matching `Exclude labels`.
  3. Resolve sizes: if `Estimation field` present → read from tracker data. Else map triage complexity (XS=1, S=2, M=3, L=5 story-points; or XS=2h, S=4h, M=8h, L=16h for hours).
  4. Apply capacity ceiling: `effective_capacity = min(Team capacity, Velocity target)` if both set; else whichever is present; else unlimited (return top `Max issues`).
  5. Walk priority-ordered list: accumulate size until `effective_capacity` reached. Issues that would overflow by ≤20% of their own size may be included (rounding buffer).
  6. Flag dependency-blocked issues: if issue A is in plan but depends on B which is not → add B to plan or flag A as at-risk.
  7. Output sprint plan (structured markdown table) and overflowing issues with sizes.
- **Constraints:** NEVER modify code. NEVER assign sprint field directly — skill handles tracker writes. Max 50 issues as input (consistent with priority-engine limit). If capacity is 0 or unconfigured → output full priority list capped at `Max issues` with a note.

**Classification:** Read-only agent (analysis, no code modification) — consistent with triage-analyst, code-analyst, spec-analyst, acceptance-gate.

### sprint-plan Skill

**Proposed frontmatter:**
```markdown
---
name: sprint-plan
description: Produces a sprint plan by ranking backlog issues against team capacity and optionally assigning them to the next sprint
allowed-tools: mcp__*, Read, Glob, Grep, Task
argument-hint: "[--apply] [--dry-run] [--capacity <N>] [--duration <1w|2w|3w|4w>] [--output <path>] [--yolo]"
---
```

**Arguments:**
- `--apply` — override `Mode: suggest` → write sprint assignments to tracker after confirmation
- `--dry-run` — show plan without writing anything, regardless of `Mode` config
- `--capacity <N>` — override `Team capacity` from config for this run
- `--duration <1w|2w|3w|4w>` — override `Sprint duration` for this run
- `--output <path>` — override `Report path` for this run
- `--yolo` — auto-approve all human gates (for CI/automation contexts); consistent with implement-feature behavior

**Orchestration steps:**
1. MCP pre-flight check (consistent with all pipeline skills — pattern: `core/mcp-preflight.md`).
2. Read Sprint Planning config. If section absent → stop: "Sprint Planning config not found. Add `### Sprint Planning` section to Automation Config or run `/ceos-agents:check-setup`."
3. Fetch open issues via MCP (Bug query + Feature query, filtered by `Include types`, capped at `Max issues`).
4. Run `ceos-agents:priority-engine` (Task tool, opus). Pass: issue list + `Priority field`.
5. Run `ceos-agents:sprint-planner` (Task tool, sonnet). Pass: ranked list + Sprint Planning config.
6. Display sprint plan (Gate 1: capacity confirmation, Gate 5: scope adjustment). If `--dry-run` → stop here.
7. Per-issue decomposition approval gates (Gates 2 and 3) for issues recommended for decomposition.
8. Display final sprint plan table (Gate 4: "Start sprint? [Y/n]"). All gates auto-approve under `--yolo`.
9. If `Mode: apply` or `--apply` flag → for each issue in plan: write `Sprint field` via MCP (tracker-specific logic based on `Issue Tracker → Type`). On MCP failure → try Bash + REST fallback → on both failure → skip with warning.
10. If `--output` or `Report path` → write report to file.
11. Write sprint state to `.ceos-agents/sprint-{timestamp}/state.json`.

**Rules:** Read-only by default (`Mode: suggest`). Destructive only when `Mode: apply` or `--apply` flag. Sprint assignment is non-blocking — failure never aborts the plan. Confirmation required before any tracker writes.

### Workflow-Router Updates

Add two new rows to the Intent Mapping table in `skills/workflow-router/SKILL.md`:

| User Intent | Command | Arguments | Destructive? |
|-------------|---------|-----------|-------------|
| Plan next sprint / sprint planning / what should go in this sprint | `ceos-agents:sprint-plan` | Optional: `--apply`, `--capacity N`, `--output path` | No (suggest mode) / Yes (apply mode) |
| Apply sprint plan / assign issues to sprint / commit sprint plan | `ceos-agents:sprint-plan` | `--apply` | Confirm before assigning |

The "apply" variant maps to the same skill with `--apply` flag and requires confirmation — consistent with the `check-deploy --start` pattern (same skill, destructive flag, marked as requiring confirmation).

### CLAUDE.md Updates Required

1. **Optional sections table** — add one new row for Sprint Planning (12 keys with defaults).
2. **Architecture: 2-Layer System** — update agent count from 19 to 20, skill count from 26 to 27.
3. **Model Selection table** — add `sprint-planner` to the sonnet row.
4. **Key Conventions** — sprint-planner is a read-only agent.

### Test Scenarios Needed

Following the pattern in `tests/scenarios/`:

1. **`sprint-plan-config-contract.sh`** — Verify `Sprint Planning` section in CLAUDE.md optional sections table with all 12 keys and correct defaults. Analogous to `test-config-contract.sh`.
2. **`sprint-plan-skill-structure.sh`** — Verify `skills/sprint-plan/SKILL.md` exists, has correct frontmatter, dispatches priority-engine and sprint-planner via Task tool. Analogous to `pipeline-feature-agents.sh`.
3. **`sprint-planner-agent-format.sh`** — Verify `agents/sprint-planner.md` exists, has correct frontmatter (`model: sonnet`), has Goal/Expertise/Process/Constraints sections, appears in read-only agents list. Analogous to `frontmatter-completeness.sh` and `read-only-agents.sh`.
4. **`workflow-router-sprint-intent.sh`** — Verify workflow-router SKILL.md contains `sprint-plan` in its intent table. Analogous to `xref-skip-stage-names.sh`.
5. **`xref-command-count-sprint.sh`** — Update `xref-command-count.sh` claim: skills 26 → 27, agents 19 → 20. (Must be updated in the same commit as the new files to avoid test failure — identical issue as deployment-verifier in v5.3.0.)
6. **`sprint-plan-dry-run.sh`** — Verify `--dry-run` flag prevents tracker writes (check SKILL.md contains dry-run gate before any MCP write operations). Analogous to `profile-skip.sh`.

---

## 7. Roadmap Reversal Justification

The `NOT PLANNED` entry in `docs/plans/roadmap.md` (line 837) reads:

> **Sprint planning / tracking** | ceos-agents is not a PM tool. Sprint tracking is delegated to issue trackers (YouTrack/Jira/Linear have native sprints).

**This was a correct rejection of sprint tracking. It was NOT a rejection of sprint planning as backlog selection.**

Three conditions changed since that decision was recorded:

1. **Priority-engine exists (v6.x).** When the sprint planning entry was added to NOT PLANNED, priority-engine did not exist. Sprint planning now requires only a thin wrapper around already-built capabilities (priority-engine + MCP tracker writes). The build cost dropped from "new full agent + new analysis logic" to "new skill + one thin agent for capacity fitting."

2. **Metrics + estimate infrastructure.** The `/metrics` and `/estimate` skills (v6.x) established the pattern for read-only analytical skills producing planning-relevant output. Sprint planning is the natural next step in the planning → execution sequence: `estimate → prioritize → sprint-plan → fix-ticket/implement-feature`.

3. **Scope clarification.** The original rejection conflated two distinct concepts: (a) sprint tracking (burndown, review, retro — **correctly rejected**, trackers do this natively) and (b) sprint planning as a one-shot backlog selection tool (new, **not rejected by the original rationale**). `Mode: suggest` as the default reinforces that this is an analytical tool, not a PM replacement.

**What remains correctly NOT PLANNED:** burndown tracking, sprint review automation, sprint retrospective, per-person workload assignment. These remain delegated to native tracker features and must be restated in the roadmap entry for sprint planning to preempt scope creep requests.

---

## 8. Open Questions & Risks

**Questions requiring human input:**

1. **`@vitalyostanin/youtrack-mcp` sprint tool inventory** — Must verify the actual tool list in the installed package before implementation. The agent definitions for sprint operations in YouTrack cannot be finalized until MCP tool names are confirmed. Is it acceptable to hard-require a REST fallback for YouTrack sprint creation, or should the skill prompt the user to install a different MCP package?

2. **Linear cycle creation path** — The official Linear MCP's `create_cycle` tool is unverified. If absent, Bash + GraphQL is required. Is it acceptable to require `LINEAR_API_KEY` env var (in addition to the MCP OAuth token) for cycle creation, or should sprint creation be skipped for Linear with a warning?

3. **Jira board type detection** — Sprint operations require a Scrum board. The skill must detect board type before attempting sprint creation. Should board type detection be a blocking pre-flight check (fail if Kanban) or a soft warning (skip sprint assignment, continue with plan output)?

4. **Redmine: Version vs Agile Sprint default** — Research confirms Version as the universal fallback. Should the `Sprint field` key default to `Version` for Redmine projects, or should the skill auto-detect based on tracker type and override the generic default?

5. **Sprint naming convention** — Agent 3 proposes `Sprint field` as a config key for the custom field name. Agent 1 suggests a `Sprint naming pattern` key (e.g., `Sprint {YYYY-WW}`). Which approach is canonical? Both may be needed (field name + name generation pattern).

6. **Scope adjustment gate (Gate 5)** — Agent 2 proposes an interactive issue-toggle prompt before the final gate. This is a new interaction style not present elsewhere in ceos-agents. Is this worth the complexity, or should scope adjustment be handled by re-running `/sprint-plan` with explicit `--exclude` flags?

**Risks:**

- **MCP sprint creation brittleness (High likelihood, Medium impact):** YouTrack and Jira (primary enterprise trackers) require Bash + REST fallbacks for sprint creation. The Bash fallback requires environment variables (`YOUTRACK_TOKEN`, `JIRA_TOKEN`) to be set. If not set, sprint creation silently skips. This must be documented prominently.
- **Velocity misconfiguration (Medium likelihood, Medium impact):** Users providing an inaccurate `Velocity target` will get unrealistic sprint plans. Mitigation: annotate the sprint plan with "Velocity target: N (configured manually)" and recommend running `/ceos-agents:metrics` after each sprint.
- **Decomposition capacity inflation (Medium likelihood, High impact):** When issues are decomposed during sprint execution, actual effort can multiply by up to 7x (max subtasks). Sprint planning's capacity estimate becomes unreliable after decomposition approval. The sprint plan must warn: "Capacity estimate may change after decomposition."
- **Priority-engine 50-issue cap (Certain, documented):** Teams with 200+ open issues get sprint plans from only the oldest 50 scored issues. This is a hard inherited constraint that must be documented in the sprint-plan skill.
- **Scope creep pressure (Near-certain, Low impact per request):** Once sprint planning exists, users will request burndown tracking, velocity auto-computation, retrospective summaries. The NOT PLANNED rationale must be explicitly restated in the roadmap entry and referenced from the sprint-plan skill documentation.
- **Test count assertions (Certain, Low impact):** `xref-command-count.sh` asserts agent count = 19, skills count = 26. Adding sprint-planner + sprint-plan will break this test unless CLAUDE.md claims and the test are updated atomically in the same commit (identical issue as deployment-verifier in v5.3.0).

---

## 9. Key Design Decisions for Brainstorming

The following are the most important unresolved choices that Phase 3 brainstorming must address:

1. **Sprint creation vs. sprint assignment only.** Should `/sprint-plan` be able to CREATE a new sprint/cycle/milestone in the tracker, or only ASSIGN issues to an existing sprint that the user has already created? Creation requires Bash + REST for YouTrack/Jira/Linear (unverified or confirmed absent from MCP). Assignment-only is simpler, more reliable, but requires the user to pre-create the sprint container. Decision affects scope, complexity, and the 3-tier fallback design significantly.

2. **Config gate: require Sprint Planning section, or graceful no-op?** Agent 3 proposes that absent config → skill stops with an error message pointing to `check-setup`. This is consistent with how other pipeline skills handle missing required config. The alternative (graceful no-op with a warning) is more user-friendly but may hide misconfiguration. Which behavior is correct for a `Mode: suggest` default?

3. **sprint-planner as a dedicated agent vs. inlined logic.** Agent 3 confirms the capacity-fitting logic is simple enough to inline in the skill (~50 lines). A dedicated agent adds ~60 lines of markdown but makes model costs predictable and keeps agent architecture clean. Is the dedicated agent worth it for MVP, or should it be a post-MVP extraction?

4. **`--yolo` flag scope.** Should `--yolo` auto-approve ALL gates (including the final "Start sprint?" gate that launches execution across multiple issues), or only the planning gates (capacity, decomposition) while still requiring explicit start confirmation? Auto-approving the execution start in a CI context could trigger significant API cost.

5. **Scope adjustment gate (Gate 5) inclusion in MVP.** The interactive issue-toggle prompt is a new UX pattern not present elsewhere in ceos-agents. Including it makes the sprint planning session feel like a real planning ceremony; excluding it keeps the MVP thin. This is a UX design choice with no precedent to follow in the codebase.

6. **Sprint-level dashboard/metrics aggregation.** Should the initial implementation include sprint-level views in dashboard and metrics, or defer them to a follow-up MINOR release? Including them increases the sprint planning MINOR bump scope significantly; deferring means users have no sprint-level visibility until a later version.

7. **Tracker-specific `Sprint field` defaults.** Should the skill auto-detect the correct sprint field name based on `Issue Tracker → Type` (e.g., `Sprint` for YouTrack/Jira, `Milestone` for GitHub/Gitea, `Cycle` for Linear, `Version` for Redmine), overriding the user's configured `Sprint field` when the tracker-specific concept name is known? Or should the user always configure the field name explicitly?
