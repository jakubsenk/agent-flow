# Phase 2: Research Answers — Sprint Planning for ceos-agents

## Executive Summary

All six research questions from Phase 1 are answered with actionable, implementation-ready detail. Key findings:

- **Per-tracker dispatch table is complete** — all 6 trackers covered with Tier 1 (MCP), Tier 2 (Bash+REST), and Tier 3 (skip+warn) for create, assign, and query. Sprint assignment is always NON-BLOCKING.
- **Semi-autonomous workflow is fully specified** — 9 steps, 5 human gates, exact gate text, `--yolo` / `--dry-run` behavior defined with source pattern citations.
- **Priority-engine integration is precise** — 6 specific output fields consumed, 50-issue ceiling inherited, `Suggested batch` as initial seed.
- **Cold-start velocity algorithm is complete** — three-tier fallback with exact formulas, effort mappings, and overflow buffer rules.
- **Sprint state schema is fully specified** — complete JSON, new RUN-ID format, child run linking, 8 state update points.
- **Config contract and file inventory are implementation-ready** — 12-key optional section, exact CLAUDE.md text changes (6 substitutions), complete file list with 5 new files and 10 modified files.
- **Execution decision: DECIDED** — sprint-plan dispatches execution after Gate 4. `Mode: suggest` (default) writes sprint assignments only; `Mode: apply` or `--apply` launches fix-ticket/implement-feature per issue.
- **Version: v6.5.0 (MINOR)** — one optional config section, one new agent, one new skill. Zero impact on projects that omit Sprint Planning.

---

## 1. Per-Tracker Sprint Dispatch Table

### MCP Tool Prefix Registry

| Tracker | Package | Tool prefix |
|---------|---------|-------------|
| youtrack | `@vitalyostanin/youtrack-mcp` | `mcp__youtrack__*` |
| github | `@modelcontextprotocol/server-github` | `mcp__github__*` |
| jira | `@modelcontextprotocol/server-atlassian` | `mcp__jira__*` or `mcp__atlassian__*` |
| linear | `@modelcontextprotocol/server-linear` | `mcp__linear__*` |
| gitea | `forgejo-mcp` | `mcp__gitea__*` or `mcp__forgejo__*` |
| redmine | `mcp-server-redmine` | `mcp__redmine__*` |

Source: `core/mcp-detection.md` inline table (single source of truth).

### Cross-Tracker Summary Table

| Tracker | sprint_create | sprint_assign | sprint_query | Sprint field config default |
|---------|--------------|---------------|--------------|----------------------------|
| youtrack | Bash+REST (MCP unverified) | MCP: `update_issue(Sprint: name)` | MCP query lang: `Sprint: {name}` | `Sprint` |
| jira | Bash+REST (MCP not confirmed) | MCP: `add_issues_to_sprint(sprintId, issues)` — requires ID resolution | JQL: `sprint = "{name}"` | `Sprint` |
| linear | Bash+GraphQL (MCP unverified) | MCP: `update_issue(cycleId: uuid)` — requires UUID resolution | MCP: `list_issues(cycleId: uuid)` | `Cycle` |
| github | MCP: `create_milestone(title, due_on)` | MCP: `update_issue(milestone: number)` — requires number resolution | MCP: `list_issues(milestone: number)` | `Milestone` |
| gitea | MCP: `create_milestone(title, due_on)` | Bash+REST (MCP unverified) | MCP: `list_issues(milestone: id)` | `Milestone` |
| redmine | MCP: `create_version(name, due_date)` (likely) | MCP: `update_issue(fixed_version_id: id)` (likely) | MCP: `list_issues(fixed_version_id: id)` | `Version` |

### Per-Tracker Detail

**IF tracker_type == "youtrack"**

Sprint vocabulary: Sprint (custom field, Agile Board-scoped). Literal `"current"` token addresses active sprint with no ID needed.

```
sprint_create:
  TIER 1 (MCP): UNVERIFIED
  TIER 2 (Bash + REST):
    curl -X POST "{YOUTRACK_INSTANCE}/api/agiles/{agileID}/sprints" \
      -H "Authorization: Bearer {YOUTRACK_TOKEN}" \
      -H "Content-Type: application/json" \
      -d '{"name": "{sprint_name}", "goal": "{sprint_goal}", "start": {epoch_ms}, "finish": {epoch_ms}}'
    NOTE: agileID resolved first via GET {YOUTRACK_INSTANCE}/api/agiles?fields=id,name
  TIER 3: Log warning "YouTrack sprint creation unavailable — no agileID configured"

sprint_assign:
  TIER 1 (MCP — preferred):
    mcp__youtrack__update_issue(issueId: "{ID}", fields: { "Sprint": "{sprint_name}" })
    NOTE: uses config Sprint field key (default "Sprint"); "current" token accepted
  TIER 2 (Bash + REST):
    curl -X POST "{YOUTRACK_INSTANCE}/api/agiles/{agileID}/sprints/{sprintID}/issues" \
      -H "Authorization: Bearer {YOUTRACK_TOKEN}" \
      -d '{"id": "{ISSUE_ID}"}'
  TIER 3 (skip + warn): NON-BLOCKING

sprint_query:
  mcp__youtrack__list_issues(query: "project: {PROJECT} Sprint: {sprint_name} State: Open")
```

**IF tracker_type == "jira"**

Sprint vocabulary: Sprint (Scrum boards only — Kanban boards have no sprint concept).
Pre-condition: `mcp__jira__get_boards(projectKey)` → check `type == "scrum"`; if Kanban → skip all sprint ops.

```
sprint_create:
  TIER 1 (MCP): NOT CONFIRMED for @modelcontextprotocol/server-atlassian
  TIER 2 (Bash + REST):
    # Step 1: Resolve board ID
    curl -u "{EMAIL}:{TOKEN}" "{JIRA_INSTANCE}/rest/agile/1.0/board?projectKeyOrId={PROJECT}" \
      | jq '.values[] | select(.type=="scrum") | .id'
    # Step 2: Create sprint
    curl -X POST -u "{EMAIL}:{TOKEN}" -H "Content-Type: application/json" \
      "{JIRA_INSTANCE}/rest/agile/1.0/sprint" \
      -d '{"name": "{sprint_name}", "startDate": "{ISO-8601}", "endDate": "{ISO-8601}",
           "originBoardId": {board_id}, "goal": "{sprint_goal}"}'
  TIER 3: Log warning "Jira sprint creation requires Bash fallback — JIRA_TOKEN must be set"

sprint_assign:
  TIER 1 (MCP — CONFIRMED via sooperset; verify tool name in installed package):
    mcp__jira__add_issues_to_sprint(sprintId: {sprint_id}, issues: ["{ISSUE_KEY}"])
    NOTE: sprint_id is numeric — resolve via mcp__jira__get_sprints(boardId, state: "future,active")
  TIER 2 (Bash + REST):
    curl -X POST -u "{EMAIL}:{TOKEN}" -H "Content-Type: application/json" \
      "{JIRA_INSTANCE}/rest/agile/1.0/sprint/{sprint_id}/issue" \
      -d '{"issues": ["{ISSUE_KEY}"]}'
  TIER 3 (skip + warn): NON-BLOCKING

sprint_query:
  mcp__jira__search_issues(jql: "project = {PROJECT} AND sprint = \"{sprint_name}\" AND status = Open")
```

**IF tracker_type == "linear"**

Sprint vocabulary: Cycle (team-scoped, not project-scoped). UUIDs required for both issueId and cycleId.

```
sprint_create:
  TIER 1 (MCP): UNVERIFIED — create_cycle not confirmed in official Linear MCP
  TIER 2 (Bash + GraphQL):
    curl -X POST https://api.linear.app/graphql \
      -H "Authorization: {LINEAR_API_KEY}" -H "Content-Type: application/json" \
      -d '{"query": "mutation { cycleCreate(input: { teamId: \"{TEAM_UUID}\", name: \"{sprint_name}\",
           startsAt: \"{ISO-8601}\", endsAt: \"{ISO-8601}\" }) { cycle { id name } } }"}'
    NOTE: TEAM_UUID resolved via GET teams { nodes { id name identifier } }
  TIER 3: Log warning "Linear cycle creation unavailable — LINEAR_API_KEY must be set"

sprint_assign:
  TIER 1 (MCP — CONFIRMED):
    mcp__linear__update_issue(issueId: "{UUID}", cycleId: "{CYCLE_UUID}")
    NOTE: cycle UUID resolved via mcp__linear__list_cycles(teamId) → find by name
  TIER 2 (Bash + GraphQL):
    mutation { issueUpdate(id: "{UUID}", input: { cycleId: "{CYCLE_UUID}" }) { success } }
  TIER 3 (skip + warn): NON-BLOCKING

sprint_query:
  mcp__linear__list_issues(cycleId: "{CYCLE_UUID}")
  NOTE: resolve UUID from cycle name first
```

**IF tracker_type == "github"**

Sprint vocabulary: Milestone (no start date, open/closed only). Projects V2 Iterations exist but MCP support incomplete (issue #1854).

```
sprint_create:
  TIER 1 (MCP — CONFIRMED):
    mcp__github__create_milestone(owner, repo, title: "{sprint_name}", due_on: "{ISO-8601}",
                                  description: "{sprint_goal}")
  TIER 2 (Bash + REST — fallback only):
    curl -X POST -H "Authorization: token {GITHUB_TOKEN}" \
      "https://api.github.com/repos/{owner}/{repo}/milestones" \
      -d '{"title": "{sprint_name}", "due_on": "{ISO-8601}", "description": "{sprint_goal}"}'

sprint_assign:
  TIER 1 (MCP — CONFIRMED):
    mcp__github__update_issue(owner, repo, issue_number, milestone: {milestone_number})
    NOTE: number resolved via mcp__github__list_milestones → find by title
  TIER 2 (Bash + REST):
    curl -X PATCH -H "Authorization: token {GITHUB_TOKEN}" \
      "https://api.github.com/repos/{owner}/{repo}/issues/{number}" \
      -d '{"milestone": {milestone_number}}'
  TIER 3 (skip + warn): NON-BLOCKING

sprint_query:
  mcp__github__list_issues(owner, repo, milestone: "{milestone_number}", state: "open")
```

**IF tracker_type == "gitea"**

Sprint vocabulary: Milestone (identical semantics to GitHub). No start date.

```
sprint_create:
  TIER 1 (MCP — CONFIRMED via raohwork/forgejo-mcp):
    mcp__gitea__create_milestone(owner, repo, title: "{sprint_name}", due_on: "{ISO-8601}",
                                 description: "{sprint_goal}")
    OR: mcp__forgejo__create_milestone(...)

sprint_assign:
  TIER 1 (MCP): UNVERIFIED — mcp__gitea__update_issue with milestone param not confirmed
  TIER 2 (Bash + REST — primary path):
    # Step 1: resolve ID
    curl -H "Authorization: token {GITEA_TOKEN}" \
      "{GITEA_INSTANCE}/api/v1/repos/{owner}/{repo}/milestones" \
      | jq '.[] | select(.title=="{sprint_name}") | .id'
    # Step 2: assign
    curl -X PATCH -H "Authorization: token {GITEA_TOKEN}" -H "Content-Type: application/json" \
      "{GITEA_INSTANCE}/api/v1/repos/{owner}/{repo}/issues/{index}" \
      -d '{"milestone": {milestone_id}}'
  TIER 3 (skip + warn): NON-BLOCKING

sprint_query:
  mcp__gitea__list_issues(owner, repo, milestone: {milestone_id}, state: "open")
  NOTE: resolve milestone_id from name first
```

**IF tracker_type == "redmine"**

Sprint vocabulary: Two-tier — Version (core, always available) vs. Agile Sprint (plugin-dependent).
Pre-condition: `GET {REDMINE_INSTANCE}/projects/{PROJECT}/agile_sprints.json` → if 404 → use Version only.
Default: always Version for maximum compatibility.

```
sprint_create (Version — default):
  TIER 1 (MCP — LIKELY via runekaagaard/mcp-redmine):
    mcp__redmine__create_version(project_id: "{PROJECT}", name: "{sprint_name}",
                                  description: "{sprint_goal}", due_date: "{YYYY-MM-DD}", status: "open")
  TIER 2 (Bash + REST):
    curl -X POST -H "X-Redmine-API-Key: {REDMINE_TOKEN}" -H "Content-Type: application/json" \
      "{REDMINE_INSTANCE}/projects/{PROJECT}/versions.json" \
      -d '{"version": {"name": "{sprint_name}", "due_date": "{YYYY-MM-DD}", "status": "open"}}'

sprint_assign (Version):
  TIER 1 (MCP — LIKELY):
    mcp__redmine__update_issue(issue_id: {ID}, fixed_version_id: {version_id})
    NOTE: version_id resolved via mcp__redmine__list_versions(project_id) → find by name
  TIER 2 (Bash + REST):
    curl -X PUT -H "X-Redmine-API-Key: {REDMINE_TOKEN}" -H "Content-Type: application/json" \
      "{REDMINE_INSTANCE}/issues/{ID}.json" \
      -d '{"issue": {"fixed_version_id": {version_id}}}'
  TIER 3 (skip + warn): NON-BLOCKING

sprint_query (Version):
  mcp__redmine__list_issues(project_id: "{PROJECT}", fixed_version_id: {version_id}, status_id: "open")

sprint_create (Agile Plugin — only if detected):
  TIER 2 (Bash only — no MCP covers plugin API):
    curl -X POST -H "X-Redmine-API-Key: {REDMINE_TOKEN}" -H "Content-Type: application/json" \
      "{REDMINE_INSTANCE}/projects/{PROJECT}/agile_sprints.json" \
      -d '{"agile_sprint": {"name": "{sprint_name}", "sprint_start_date": "{YYYY-MM-DD}",
                            "sprint_end_date": "{YYYY-MM-DD}"}}'
```

### Name → ID Resolution Requirements

All trackers except YouTrack require resolving a name to a numeric/UUID ID before assignment:

| Tracker | Name → ID resolution call |
|---------|--------------------------|
| youtrack | Not needed — `Sprint` field accepts name directly |
| jira | `mcp__jira__get_sprints(boardId)` → filter by name → get `id` (numeric) |
| linear | `mcp__linear__list_cycles(teamId)` → filter by name → get `id` (UUID) |
| github | `mcp__github__list_milestones(owner, repo)` → filter by title → get `number` |
| gitea | `mcp__gitea__list_milestones(owner, repo)` → filter by title → get `id` |
| redmine | `mcp__redmine__list_versions(project_id)` → filter by name → get `id` |

### Fallback Decision Logic (sprint_assign per issue)

```
FOR EACH issue IN approved_sprint_issues:
  SET assigned = false
  TRY MCP (Tier 1):
    IF tracker_type IN ["youtrack", "jira", "linear", "github", "redmine"]:
      execute confirmed/likely MCP call
      SET assigned = true
    ELSE IF tracker_type == "gitea":
      SKIP to Tier 2 (MCP assign unverified)
  CATCH mcp_error:
    LOG WARN "MCP sprint assign failed — trying Bash fallback"

  IF NOT assigned:
    TRY Bash + REST (Tier 2):
      execute curl command per tracker (see above)
      SET assigned = true
    CATCH bash_error:
      LOG WARN "Bash sprint assign failed for {issue_id}"

  IF NOT assigned (Tier 3):
    LOG WARN "[sprint-plan] Could not assign {issue_id} to sprint — both MCP and REST fallback failed.
             Issue remains in backlog. Sprint assignment is metadata-only; does not block pipeline."

  // NEVER block pipeline on sprint assignment failure
```

### Environment Variables for Bash Fallbacks

| Tracker | Variables |
|---------|-----------|
| youtrack | `YOUTRACK_TOKEN`, `YOUTRACK_INSTANCE` |
| jira | `JIRA_TOKEN`, `JIRA_EMAIL`, `JIRA_INSTANCE` |
| linear | `LINEAR_API_KEY` |
| github | `GITHUB_TOKEN` |
| gitea | `GITEA_TOKEN`, `GITEA_INSTANCE` |
| redmine | `REDMINE_TOKEN`, `REDMINE_INSTANCE` |

If missing when Bash fallback is needed: log warning and proceed to Tier 3 skip.

---

## 2. Semi-Autonomous Workflow

### Complete 9-Step Flow

The workflow has two phases: **Planning Phase** (steps 1–8) and **Execution Phase** (step 9).

```
1. MCP pre-flight check (core/mcp-preflight.md pattern)
2. Sprint Planning config gate (hard stop if section absent)
3. Fetch open issues via MCP (Bug query + Feature query if configured)
4. Run priority-engine via Task tool (model: opus)
5. Run sprint-planner via Task tool (model: sonnet)
   [GATE 1: Capacity confirmation]
6. Scope adjustment (interactive issue toggle, repeating prompt)
   [GATE 5: "Add or remove issues?" — optional, skip under --yolo]
7. Per-issue decomposition gates
   [GATE 2: Decomposition approval per issue — "Continue? [Y/n]"]
   [GATE 3: Unmapped AC warning — "Continue anyway? [Y/n]"]
   (Post-decomposition: re-run sprint-planner for updated effort totals)
8. Display final sprint plan table
   [GATE 4: "Start sprint? [Y/n]"]
   [--dry-run exits here — no tracker writes, no execution]
9a. Sprint assignment (Mode: apply or --apply only)
9b. Execution dispatch (fix-ticket/implement-feature per issue)
   OR: suggestion display only (Mode: suggest default)
```

### Step-by-Step Detail

**Step 1 — MCP pre-flight check**
Pattern: `core/mcp-preflight.md`. Read `Issue Tracker → Type`; verify at least one `mcp__*` tool matching tracker type is accessible. On failure: STOP. No `--yolo` exception here — without tracker access there is nothing to plan.

**Step 2 — Config validation**
Read `### Sprint Planning` from Automation Config. If absent: STOP with "Sprint Planning config not found. Add `### Sprint Planning` section to Automation Config or run `/ceos-agents:check-setup`." Also apply Config Validity Gate (implement-feature step 0b pattern): scan all required sections for `<!-- TODO:` or `<...>` placeholders.

**Step 3 — Fetch open issues**
Apply `Bug query` + `Feature query` (if `Feature Workflow` section configured). Filter by `Include types` (default: `bug, feature`). Filter out `Exclude labels`. Cap at `Max issues` (default: 20). Hard ceiling from priority-engine is 50.

**Step 4 — Run priority-engine**
Pattern: `skills/prioritize/SKILL.md` step 3 — `run ceos-agents:priority-engine (Task tool, model: opus)`. Pass issue list with historical data if `./reports/metrics.md` exists. Output: ranked P0/P1/P2 tables with `Impact`, `Risk`, `Effort`, `Score`, `Rationale`; `Suggested batch` recommendation; `Estimated cost for batch`.

**Step 5 — Run sprint-planner**
`run ceos-agents:sprint-planner (Task tool, model: sonnet)`. Pass: priority-engine output + all Sprint Planning config keys + `velocity_source`. Sprint-planner applies capacity constraints via structured arithmetic (walk ranked list, accumulate effort sizes, stop at ceiling). NOT freeform reasoning.

**Gate 1 — Capacity confirmation**
```
Suggested sprint: {N} issues — {total_estimated_effort} effort points
Team capacity: {configured_value or "unknown"}
Velocity source: {historical | heuristic | manual | unconstrained}
Proceed with this selection? [Y/n]
```
Pattern: implement-feature step 0c (card preview prompt, lines 134–140). `--yolo` auto-approves. If N: offer scope adjustment (Gate 5) or STOP.

**Step 6 — Scope adjustment (Gate 5)**
```
Add or remove issues? Enter issue ID to toggle, or press Enter to continue.
```
Repeats until Enter with no input. On each toggle: re-run sprint-planner capacity fit (NOT full priority-engine re-run — use cached scores). `--yolo` skips entirely.

**Step 7 — Per-issue decomposition gates**
For each issue where sprint-planner flags `decompose_recommended: true` (effort_score >= 4 OR priority-engine Risk = 5):

Gate 2: display decomposition plan table → `Continue? [Y/n]`. Pattern: `fix-bugs/SKILL.md` step 3b (line 174). `--yolo` auto-approves.

Gate 3: if unmapped AC detected → "Continue anyway? The unmapped criteria will not be explicitly addressed. [Y/n]". Pattern: `fix-bugs/SKILL.md` line 188. `--yolo` BLOCKS (does not auto-approve) — consistent with implement-feature line 215 "If mode is YOLO → Block".

After Gate 2 approval: re-run sprint-planner; post-decomposition effort = `effort_points × subtask_count`. If post-decomp total exceeds capacity: warn user, offer to remove decomposed issue from sprint.

**Gate 4 — Final sprint start gate**
```
## Sprint Plan — {sprint_name}

| # | Issue | Tier | Effort | Decompose? | Subtasks |
|---|-------|------|--------|------------|---------|
| 1 | PROJ-42: Fix login | P0 | 3 | No | — |
| 2 | PROJ-38: Add API auth | P1 | 5 | Yes (3 subtasks) | spec, impl, test |

Total effort: ~{N} | Issues: {N} | Est. cost: ~${min}-${max}
Velocity source: {historical | heuristic | manual | unconstrained}

Start sprint? [Y/n]
```
Pattern: implement-feature step 5 decomposition plan display (lines 224–237). `--yolo` auto-approves. If N: STOP, no tracker writes, no execution.

### 5 Human Gates Summary

| Gate | Trigger | --yolo behavior |
|------|---------|-----------------|
| Gate 1 | After sprint-planner output | Auto-approve |
| Gate 2 | Per decomposable issue | Auto-approve |
| Gate 3 | Unmapped AC in decomposed issue | BLOCK (does not approve) |
| Gate 4 | Final "Start sprint?" | Auto-approve |
| Gate 5 | Scope adjustment toggle | Skip entirely |

### --yolo and --dry-run Behavior

**`--yolo`:**
- Auto-approves Gates 1, 2, 4, 5
- BLOCKS on Gate 3 (unmapped AC — high-stakes, consistent with implement-feature behavior)
- Enables fully automated CI sprint execution

**`--dry-run`:**
- Exits after Gate 4 display (step 6 in skill steps)
- No tracker writes
- No state file written
- No pipeline launched
- Pattern: `fix-bugs/SKILL.md` step 0 (line 93), `implement-feature/SKILL.md` step 0 (lines 90–95)

**`--apply`:**
- Overrides `Mode: suggest` to write sprint assignments and launch execution
- Without `--apply` AND without `Mode: apply` → suggestion display only after Gate 4

---

## 3. Priority-Engine Integration

### Output Fields Consumed

Sprint-planner consumes these specific fields from priority-engine's structured markdown output:

**From P0/P1/P2 tables (per-issue):**
| Field | Usage |
|-------|-------|
| `Issue` (`{ID}: {title}`) | Sprint plan table population |
| `Impact` (`/5`) | Capacity-fit rationale |
| `Risk` (`/5`) | If Risk = 5, flag `decompose_recommended: true` |
| `Effort` (`/5`) | PRIMARY field for capacity fitting; maps to hours/points |
| `Score` (computed) | Preserve sort order — sprint-planner does NOT re-rank |
| `Rationale` (1-sentence) | Pass through verbatim to sprint plan table |

**From `### Dependencies` section:**
- `{issue_A} → blocks → {issue_B}` graph — if B is in plan and A is not: add A (if fits) or flag B as at-risk

**From `### Recommendations` section:**
- `Suggested batch: {top N issues}` — initial sprint selection input to sprint-planner (may be trimmed by capacity)
- `Estimated cost for batch: ~${min}-${max}` — passed through to Gate 4 `Est. cost` display

### 50-Issue Limit

Hard ceiling of 50 issues per analysis from `priority-engine.md` line 65 ("Max 50 issues per analysis"). Sprint-planner inherits this: if backlog > 50, process only top 50 by creation date and document the truncation. Config `Max issues` defaults to 20 (intentionally below ceiling).

### Suggested Batch Seed

Priority-engine's `Suggested batch` field (priority-engine.md line 58) is the initial sprint selection. Sprint-planner may trim it further based on capacity. Priority-engine is NEVER re-run after Gate 1 — scores are cached in memory. Only sprint-planner is re-invoked on scope adjustment toggles.

---

## 4. Cold-Start Velocity Algorithm

### Three-Tier Fallback with Formulas

**Tier determination:**
```
IF ./reports/metrics.md exists (or Metrics → Output path from config):
    velocity_source = "historical" → GOTO Tier 1
ELSE IF Team capacity OR Velocity target is configured:
    velocity_source = "heuristic" → GOTO Tier 2
ELSE:
    velocity_source = "manual" (if user answers) OR "unconstrained" (if skipped)
    → GOTO Tier 3
```

**Tier 1 — Historical data:**
```
avg_time_to_fix_hours = extracted from metrics report "Avg time to fix"
success_rate = extracted from "Issues fixed" percentage (decimal, e.g. 0.75)

sprint_duration_hours = parse_duration(Sprint duration):
  "1 week" → 40h | "2 weeks" → 80h | "3 weeks" → 120h | "4 weeks" → 160h

effective_capacity_hours = min(team_capacity_hours, sprint_duration_hours)

max_issues = floor(effective_capacity_hours / avg_time_to_fix_hours × success_rate)
// Example: floor(80 / 6.5 × 0.75) = floor(9.2) = 9 issues
```

Story-points mode:
```
team_capacity_points = Team capacity config (e.g., 40)
velocity_target_points = Velocity target config (e.g., 35)
effective_capacity = min(team_capacity_points, velocity_target_points)
// Use EFFORT_TO_POINTS mapping below for accumulation
```

**Tier 2 — Heuristic (cold start, no metrics):**

Effort score (1–5) from priority-engine maps to:
```
EFFORT_TO_HOURS  = {1: 0.5, 2: 1.0, 3: 2.0, 4: 4.0, 5: 8.0}
EFFORT_TO_POINTS = {1: 1,   2: 2,   3: 3,   4: 5,   5: 8}
// Points: Fibonacci-adjacent (1,2,3,5,8) — consistent with triage complexity map
```

Complexity → effort mapping (preferred when `[ceos-agents] Triage completed.` comments exist):
```
COMPLEXITY_TO_HOURS  = {"XS": 2.0, "S": 4.0, "M": 8.0, "L": 16.0}
COMPLEXITY_TO_POINTS = {"XS": 1, "S": 2, "M": 3, "L": 5}
// Takes precedence over priority-engine effort scores when available
// (triage-analyst complexity validated against actual code — more signal)
```

Capacity ceiling with overflow buffer:
```
IF Capacity unit == "story-points":
  capacity = min(Team capacity, Velocity target) if both set; else whichever present
  for each issue in ranked list:
    issue_cost = EFFORT_TO_POINTS[effort_score]
    overflow_threshold = issue_cost × 0.2   // 20% of own size
    IF accumulated_cost + issue_cost <= capacity + overflow_threshold:
      include issue; accumulated_cost += issue_cost
    ELSE: overflow_issues.append(issue)

IF Capacity unit == "hours":
  capacity = Team capacity (hours)
  for each issue in ranked list:
    issue_cost = EFFORT_TO_HOURS[effort_score]
    IF accumulated_cost + issue_cost <= capacity × 1.1:  // 10% rounding buffer
      include issue; accumulated_cost += issue_cost
    ELSE: overflow_issues.append(issue)
```

**Tier 3 — Manual prompt (no capacity, no metrics):**
```
DISPLAY:
  "No team capacity configured and no historical velocity data found."
  "Estimated hours available this sprint: [enter number or press Enter to skip]"

IF user enters N:
  team_capacity_hours = N; velocity_source = "manual"
  APPLY Tier 2 formula with EFFORT_TO_HOURS and N as capacity

IF user presses Enter:
  velocity_source = "unconstrained"; effective_capacity = null
  SELECT top min(Max issues, 20) from ranked list (no accumulation)
```

**Cold-start annotation (Tiers 2 and 3, shown at every gate):**
```
Warning: Velocity estimate based on {heuristic estimates | manual input} — no historical data found.
  Run /ceos-agents:metrics after this sprint to calibrate future planning.
```

---

## 5. Sprint State Schema

### Complete JSON Schema

Written to `.ceos-agents/sprint-{timestamp}/state.json` using atomic write protocol (write to `.json.tmp`, rename — per `state/schema.md` lines 270–276).

```json
{
  "schema_version": "1.0",
  "run_id": "sprint-20260413-143000",
  "parent_run_id": null,
  "mode": "sprint-planning",
  "pipeline": "sprint-plan",
  "status": "running",
  "started_at": "2026-04-13T14:30:00Z",
  "updated_at": "2026-04-13T14:35:00Z",
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
    "goal": null,
    "duration": "2 weeks",
    "capacity_unit": "story-points",
    "capacity_configured": 40,
    "velocity_target": 35,
    "effective_capacity": 35,
    "velocity_source": "historical",
    "approved_at": null,
    "started_at": null,
    "issues": [
      {
        "issue_id": "PROJ-42",
        "title": "Fix login redirect loop",
        "priority_score": 9.5,
        "tier": "P0",
        "effort_score": 2,
        "effort_hours": 1.0,
        "effort_points": 2,
        "type": "bug",
        "decompose_recommended": false,
        "subtask_count": null,
        "post_decomp_effort": null,
        "sprint_assigned": false,
        "child_run_id": null,
        "status": "pending"
      }
    ],
    "total_effort_pre_decomp": 7,
    "total_effort_post_decomp": 14,
    "completed_issues": 0,
    "blocked_issues": 0,
    "skipped_issues": 0
  },
  "gates": {
    "capacity_confirmed": false,
    "scope_adjusted": false,
    "sprint_started": false
  },
  "sprint_assignment": {
    "status": "pending",
    "mode": "apply",
    "tracker_sprint_id": null,
    "tracker_sprint_name": null,
    "assigned_count": 0,
    "failed_count": 0
  },
  "block": null
}
```

### Key Field Definitions

| Field | Type | Description |
|-------|------|-------------|
| `sprint.name` | string or null | Sprint/milestone/cycle name. From `Sprint naming pattern` config if set; otherwise `Sprint {YYYY-WW}`. |
| `sprint.effective_capacity` | int or null | `min(capacity_configured, velocity_target)`. Null when both absent (unconstrained). |
| `sprint.velocity_source` | string | `"historical"`, `"heuristic"`, `"manual"`, or `"unconstrained"`. |
| `sprint.issues[].effort_score` | int | Raw 1–5 score from priority-engine. |
| `sprint.issues[].effort_hours` | float | Derived: 1→0.5h, 2→1h, 3→2h, 4→4h, 5→8h. |
| `sprint.issues[].effort_points` | int | Derived: XS=1, S=2, M=3, L=5 (from triage) or 1→1, 2→2, 3→3, 4→5, 5→8 (from effort_score). |
| `sprint.issues[].decompose_recommended` | bool | `true` if effort_score >= 4 OR priority-engine Risk = 5. |
| `sprint.issues[].subtask_count` | int or null | Number of subtasks after Gate 2 approval. Null until then. |
| `sprint.issues[].post_decomp_effort` | int or null | `effort_points × subtask_count`. Null until Gate 2 approved. |
| `sprint.issues[].sprint_assigned` | bool | Whether tracker sprint field was successfully written. |
| `sprint.issues[].child_run_id` | string or null | Set to issue ID once fix/feature pipeline launches. Links to `.ceos-agents/{ISSUE-ID}/state.json`. Mirrors `parent_run_id` pattern from `state/schema.md` line 36. |
| `sprint.issues[].status` | string | `pending`, `running`, `completed`, `blocked`, `skipped`. |
| `sprint_assignment.mode` | string | `"suggest"` or `"apply"`. |

### RUN-ID Format

New row to add to `state/schema.md` RUN-ID Determination table:

| Pipeline type | RUN-ID format | Example |
|---|---|---|
| Sprint planning run | `sprint-{timestamp}` | `sprint-20260413-143000` |

### Child Run Linking

`sprint.issues[].child_run_id` is set to the issue ID (e.g., `"PROJ-42"`) once the fix/feature pipeline is launched. Links to `.ceos-agents/{ISSUE-ID}/state.json`. Uses same `parent_run_id` pattern from `state/schema.md` line 36.

### State Update Points (8 points)

1. After step 2 (config validation) → write initial state with `status: "running"`, all issues `pending`
2. After Gate 1 confirmed → set `gates.capacity_confirmed: true`, write issue list with effort scores
3. After each Gate 2 (decomposition) → update `subtask_count`, `post_decomp_effort`, `total_effort_post_decomp`
4. After Gate 4 confirmed → set `gates.sprint_started: true`, `sprint.approved_at`
5. After each sprint assignment write → update `sprint_assigned`, `sprint_assignment.assigned_count/failed_count`
6. As each child pipeline starts → set `child_run_id`, `status: "running"`
7. As each child pipeline completes/blocks → update `status`, increment `completed_issues/blocked_issues`
8. On pipeline completion → set top-level `status: "completed"`

---

## 6. Config Contract

### Exact Sprint Planning Section

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

All 12 keys are optional. Section absence = sprint planning disabled; skill exits immediately with a clear message. Projects need only include keys being overridden from defaults.

### Optional Sections Table Row (add to CLAUDE.md after Decomposition row)

```
| Sprint Planning | Sprint duration, Capacity unit, Team capacity, Velocity target, Sprint field, Priority field, Mode, Max issues, Include types, Exclude labels, Estimation field, Report path | 2 weeks, story-points, (none), (none), Sprint, Priority, suggest, 20, bug/feature, (none), (none), (none) |
```

### CLAUDE.md Changes (6 substitutions)

**1. Agent count** (`agents/` line):
- Before: `- \`agents/\` — 19 agent definitions (markdown with YAML frontmatter)`
- After: `- \`agents/\` — 20 agent definitions (markdown with YAML frontmatter)`

**2. Skill count** (`skills/` line):
- Before: `- \`skills/\` — 26 skills (slash commands, including workflow-router)`
- After: `- \`skills/\` — 27 skills (slash commands, including workflow-router)`

**3. Skills list** (2-Layer System section):
- Before: `\`/dashboard\`, \`/metrics\`, \`/estimate\`, \`/prioritize\`, \`/migrate-config\`, \`/template\`, \`/discuss\``
- After: `\`/dashboard\`, \`/metrics\`, \`/estimate\`, \`/prioritize\`, \`/migrate-config\`, \`/template\`, \`/discuss\`, \`/sprint-plan\``

**4. Agents list** (2-Layer System section):
- Before: `..., deployment-verifier`
- After: `..., deployment-verifier, sprint-planner`

**5. Model Selection table** (sonnet row agents cell):
- Before: `triage-analyst, code-analyst, test-engineer, e2e-test-engineer, spec-analyst, stack-selector, scaffolder, acceptance-gate, reproducer, browser-verifier, deployment-verifier`
- After: `triage-analyst, code-analyst, test-engineer, e2e-test-engineer, spec-analyst, stack-selector, scaffolder, acceptance-gate, reproducer, browser-verifier, deployment-verifier, sprint-planner`

**6. Read-only agents list** (Key Conventions section):
- Before: `Read-only agents (triage-analyst, code-analyst, reviewer, spec-analyst, architect, stack-selector, priority-engine, spec-reviewer, acceptance-gate) NEVER modify code`
- After: `Read-only agents (triage-analyst, code-analyst, reviewer, spec-analyst, architect, stack-selector, priority-engine, spec-reviewer, acceptance-gate, sprint-planner) NEVER modify code`

### Version: v6.5.0 (MINOR)

Rationale: one new optional config section (no required keys), one new agent, one new skill. Zero impact on projects omitting Sprint Planning. Identical precedent: Browser Verification (v5.1.0), Local Deployment (v5.3.0). Per CLAUDE.md versioning policy: "Adding an **optional** section = MINOR."

---

## 7. Component Inventory

### sprint-planner Agent (exact frontmatter + sections)

File: `agents/sprint-planner.md`

```markdown
---
name: sprint-planner
description: Applies capacity constraints to a prioritized backlog to produce a sprint plan with fit analysis
model: sonnet
style: Pragmatic, capacity-aware, time-boxed
---

You are a Sprint Planning Analyst specializing in backlog capacity fitting.

## Goal

Receive a priority-ranked issue list and sprint capacity parameters; produce a sprint plan that fits within the sprint window, accounting for team velocity, issue sizes, and dependencies.

## Expertise

Capacity planning, sprint sizing, effort-to-hours mapping, dependency ordering, overflow detection, velocity heuristic derivation.

## Process

1. Receive inputs: priority-ranked issue list (from priority-engine), Sprint Planning config keys, and velocity source.
2. Filter: remove issues matching `Exclude labels`.
3. Resolve issue sizes:
   a. `Estimation field` configured → read from tracker data.
   b. Not configured → scan tracker comments for `[ceos-agents] Triage completed. ... Complexity: {X}.` → map XS=1/S=2/M=3/L=5 (points) or XS=2h/S=4h/M=8h/L=16h (hours).
   c. Neither → assign size 3 (medium) and annotate as estimated.
4. Determine effective capacity: min(Team capacity, Velocity target) if both set; either alone if one set; unlimited if neither (return top Max issues with annotation).
5. Walk ranked list accumulating sizes. Include issue if overflow ≤20% of its own size (rounding buffer).
6. Flag dependency-blocked issues: if A is in plan and depends on B not in plan → add B (if fits) or annotate A as "at-risk: depends on {B}".
7. Annotate velocity source. Emit cold-start warning for Tier 2/3.
8. Output sprint plan table with overflow candidates section.

## Constraints

- NEVER modify code or write to the issue tracker — read-only; tracker writes handled by sprint-plan skill
- NEVER invent issue data — only use provided input
- Max 50 issues as input (consistent with priority-engine.md limit); if more, process first 50 and note truncation
- If `Team capacity` is 0 → treat as unconfigured; log warning
- On failure: Block using Block Comment Template with Agent: sprint-planner, Step: Sprint Capacity Fitting
```

### sprint-plan Skill (exact frontmatter + steps)

File: `skills/sprint-plan/SKILL.md`

```markdown
---
name: sprint-plan
description: Produces a sprint plan by ranking backlog issues against team capacity and optionally assigning them to the next sprint
allowed-tools: mcp__*, Read, Glob, Grep, Task
argument-hint: "[--apply] [--dry-run] [--capacity <N>] [--duration <1w|2w|3w|4w>] [--output <path>] [--yolo]"
---
```

Steps (abbreviated):
```
0. MCP pre-flight check
0b. Sprint Planning config gate (parse 12 keys with defaults; apply flag overrides)
1. Fetch issues (Bug query + Feature query; cap at Max issues)
2. Determine velocity source (Tier 1/2/3 fallback; Tier 3 prompt unless --yolo)
3. Run priority-engine (Task tool, model: opus)
4. Run sprint-planner (Task tool, model: sonnet)
5. Gate 1 — Capacity confirmation [--yolo auto-approves]
5b. Gate 5 — Scope adjustment [--yolo skips]
6. --dry-run gate (if set → display and STOP)
7. Per-issue decomposition gates (Gate 2 + Gate 3)
8. Gate 4 — "Start sprint? [Y/n]" [--yolo auto-approves]
9. Sprint assignment (Mode: apply or --apply only; per-tracker dispatch table)
10. Write sprint state (.ceos-agents/sprint-{timestamp}/state.json, atomic write)
11. Output report (if Report path configured)
```

Rules:
- Read-only by default (Mode: suggest)
- Sprint assignment NON-BLOCKING
- NEVER skip Gate 4 in non-`--yolo` mode even if `--apply` is set
- priority-engine failure BLOCKING; sprint-planner failure BLOCKING; assignment failure NON-BLOCKING

### Workflow-Router Rows

Insert after existing "Prioritize backlog" row in `skills/workflow-router/SKILL.md`:

```
| Plan next sprint / sprint planning / what should go in this sprint | `ceos-agents:sprint-plan` | Optional: `--capacity N`, `--duration 1w|2w|3w|4w`, `--output path` | No (suggest mode) |
| Apply sprint plan / assign issues to sprint / commit sprint plan | `ceos-agents:sprint-plan` | `--apply` | Confirm before assigning |
```

The `--apply` row must appear in the destructive confirmation gate (step 4) alongside `fix-ticket`, `fix-bugs`, `create-pr`, `publish`, `check-deploy --start/--stop`.

Pattern source: `check-deploy / check-deploy --start / check-deploy --stop` rows (workflow-router lines 40–42) — same skill, different flags.

### File Inventory

**New files (5):**

| File | Description |
|------|-------------|
| `agents/sprint-planner.md` | 20th agent — read-only capacity fitting |
| `skills/sprint-plan/SKILL.md` | 27th skill — orchestration with 11 steps |
| `tests/scenarios/sprint-plan-config-contract.sh` | Verify Sprint Planning section in CLAUDE.md optional sections table |
| `tests/scenarios/sprint-plan-skill-structure.sh` | Verify sprint-plan SKILL.md exists, frontmatter, agent dispatch |
| `tests/scenarios/sprint-planner-agent-format.sh` | Verify sprint-planner.md frontmatter, sections, read-only |
| `tests/scenarios/workflow-router-sprint-intent.sh` | Verify workflow-router contains sprint-plan intent rows |
| `tests/scenarios/sprint-plan-dry-run.sh` | Verify --dry-run exits before tracker writes |

Note: 7 new test scenario files listed above (agent-3.md listed 5 in header but detailed 7 — all 7 are confirmed and distinct).

**Modified files (10):**

| File | Change |
|------|--------|
| `CLAUDE.md` | 6 substitutions (agent/skill counts, lists, model table, read-only list) + optional sections table row |
| `skills/workflow-router/SKILL.md` | +2 intent rows |
| `tests/scenarios/frontmatter-completeness.sh` | Add `sprint-planner` to AGENTS array; count 19→20 |
| `tests/scenarios/read-only-agents.sh` | Add `sprint-planner` to READ_ONLY_AGENTS array; count 9→10 |
| `tests/scenarios/xref-command-count.sh` | No direct changes — reads filesystem counts; CLAUDE.md changes ensure match |
| `docs/reference/automation-config.md` | Add Sprint Planning section documentation |
| `docs/plans/roadmap.md` | Update "Sprint planning / tracking" entry: sprint planning as backlog selection IMPLEMENTED v6.5.0; sprint tracking still NOT PLANNED |
| `.claude-plugin/plugin.json` | Version bump: `"6.4.6"` → `"6.5.0"` |
| `state/schema.md` | Add RUN-ID row: `sprint-{timestamp}` |
| `CHANGELOG.md` | New v6.5.0 entry |

**Test file exact changes:**

`tests/scenarios/frontmatter-completeness.sh` — AGENTS array:
```bash
AGENTS=(
  triage-analyst code-analyst fixer reviewer acceptance-gate
  test-engineer e2e-test-engineer publisher rollback-agent spec-analyst
  architect stack-selector scaffolder priority-engine spec-writer
  spec-reviewer reproducer browser-verifier deployment-verifier
  sprint-planner
)
```
PASS message: `"PASS: All 20 agents have all 4 required frontmatter fields (name, description, model, style)"`

`tests/scenarios/read-only-agents.sh` — READ_ONLY_AGENTS array:
```bash
READ_ONLY_AGENTS=(
  triage-analyst code-analyst reviewer spec-analyst architect
  stack-selector priority-engine spec-reviewer acceptance-gate
  sprint-planner
)
```
PASS message: `"PASS: All 10 read-only agents have no write-tool phrases in Process sections"`

---

## 8. Test Scenarios

| Scenario | File | What It Tests |
|----------|------|---------------|
| Config contract | `sprint-plan-config-contract.sh` | Sprint Planning section in CLAUDE.md optional sections table; all 12 keys; defaults for Mode, Capacity unit, Sprint field |
| Skill structure | `sprint-plan-skill-structure.sh` | SKILL.md exists; correct frontmatter; dispatches priority-engine + sprint-planner via Task; contains --dry-run and --yolo handling |
| Agent format | `sprint-planner-agent-format.sh` | Frontmatter 4 fields; `model: sonnet`; Goal/Expertise/Process/Constraints sections; no write-tool phrases; NEVER modify code in Constraints |
| Router intent | `workflow-router-sprint-intent.sh` | workflow-router contains `ceos-agents:sprint-plan`; --apply row present; --apply row marked as requiring confirmation |
| Dry-run gate | `sprint-plan-dry-run.sh` | --dry-run handling present; dry-run gate appears BEFORE sprint assignment section; NON-BLOCKING language for assignment failures |
| Frontmatter completeness (existing, updated) | `frontmatter-completeness.sh` | All 20 agents have all 4 frontmatter fields |
| Read-only agents (existing, updated) | `read-only-agents.sh` | All 10 read-only agents have no write-tool phrases in Process sections |

---

## 9. Execution Decision

**DECIDED: sprint-plan dispatches execution after Gate 4.**

Three modes of operation:

**Mode: suggest (default — no `--apply`)**
- After Gate 4: write sprint assignments to tracker (metadata only)
- Display: "Sprint plan created. Run `/ceos-agents:fix-bugs {N}` or `/ceos-agents:implement-feature {ISSUE-ID}` to begin implementation."
- State: `gates.sprint_started: true`, all `sprint.issues[].status` remain `"pending"`

**Mode: apply (config or `--apply` flag)**
- After Gate 4: write sprint assignments + launch execution
- Routing: `fix-ticket {issue_id}` for bugs; `implement-feature {issue_id}` for features (one at a time, not `fix-bugs N` batch)
- Order: tier order (P0 first, then P1, P2)
- Parallelism: issues in the same tier with no dependency relationship may be dispatched in parallel via simultaneous Task calls; dependent issues serialized
- State: `child_run_id` set to issue ID; links to `.ceos-agents/{ISSUE-ID}/state.json`

**`--dry-run`**
- Exit after Gate 4 display, no tracker writes, no execution

Rationale for launching execution (not just plan):
1. Gate 4 is an explicit "Start sprint?" commitment — unambiguous.
2. `--dry-run` provides plan-only path for users who want recommendation only.
3. Without execution launch, user must manually construct commands after planning — defeats the purpose.
4. `--yolo` enables fully automated CI sprint execution (consistent with implement-feature line 13).

`fix-ticket` per issue (not `fix-bugs N` batch) because: sprint state needs `child_run_id` linkage; per-issue status tracking requires knowing when each completes/blocks; `fix-bugs` batch parallelism can be replicated via parallel Task calls for same-tier, dependency-free P0 issues.

---

## 10. Open Questions for Brainstorming

These items are NOT blocking the MVP implementation but should be tracked for follow-up:

1. **Sprint naming pattern config key** — Not specified in research. Should `Sprint field` double as a naming template (e.g., `Sprint {YYYY-WW}`) or should there be a separate `Sprint naming pattern` key? The state schema uses `Sprint {YYYY-WW}` as the fallback but the config contract does not expose this as a configurable key yet.

2. **Sprint goal authoring** — The Phase 1 workflow matrix noted "AI drafts, human approves before pipeline starts." This gate is not included in the 5 defined gates. Decision needed: include as Gate 0.5 (optional, before Gate 1), or omit from MVP and treat `sprint.goal` as always null?

3. **Sprint-level dashboard and metrics** — Sprint state files exist (`.ceos-agents/sprint-*/state.json`); dashboard and metrics work unchanged for individual issues. Sprint-level aggregation (sprint completion rate, sprint velocity actual) requires reading sprint state. Deferred to follow-up MINOR release — architecture supports it without schema changes.

4. **Parallel execution scope** — Research confirmed same-tier, dependency-free issues may be dispatched in parallel via Task. Should there be a config key (`Parallel execution: true/false`) to control this, or is parallelism always on? Default: always on (consistent with `fix-bugs` parallel triage pattern).

5. **`--yolo` with `Mode: suggest`** — If `--yolo` is passed but `Mode: suggest` is configured, does execution launch anyway? Research implies yes (Gate 4 auto-approved + `--yolo` means execute), but the `Mode: suggest` config implies the project owner wants suggest-only by default. Resolution needed: `--yolo --apply` required for execution, or `--yolo` alone implies `--apply`?

6. **Redmine Agile Plugin auto-detection** — The detection heuristic (`GET .../agile_sprints.json` → 404 = no plugin) should be verified against real Redmine instances. The fallback to Version is safe; the detection is a best-effort optimization.

7. **Jira MCP tool name mismatch** — `@modelcontextprotocol/server-atlassian` (ceos-agents default) has unverified tool names; `sooperset/mcp-atlassian` confirms `jira_add_issues_to_sprint`. The skill should attempt both `mcp__jira__add_issues_to_sprint` and `mcp__atlassian__add_issues_to_sprint` before Bash fallback.

8. **Scope adjustment (Gate 5) in MVP** — Agent 2 noted this is a new interaction pattern not present elsewhere. Its complexity (repeating prompt loop, cache management) adds scope. Decision: include in MVP or defer to follow-up? Current research includes it as MVP.
