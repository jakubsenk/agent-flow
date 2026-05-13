# Phase 2 Research Answers — Tracker API (Agent 1)

**Scope:** Concrete, verified per-tracker dispatch table for sprint/milestone/version/cycle operations.
**Sources verified:** `core/mcp-detection.md`, `core/mcp-preflight.md`, `docs/reference/trackers.md`, `skills/implement-feature/SKILL.md` (Step 5a), Phase 1 `final.md`.

---

## 1. MCP Tool Prefix Registry (from `core/mcp-detection.md`)

| Tracker | Package | Tool prefix |
|---------|---------|-------------|
| youtrack | `@vitalyostanin/youtrack-mcp` | `mcp__youtrack__*` |
| github | `@modelcontextprotocol/server-github` | `mcp__github__*` |
| jira | `@modelcontextprotocol/server-atlassian` | `mcp__jira__*` or `mcp__atlassian__*` |
| linear | `@modelcontextprotocol/server-linear` | `mcp__linear__*` |
| gitea | `forgejo-mcp` | `mcp__gitea__*` or `mcp__forgejo__*` |
| redmine | `mcp-server-redmine` | `mcp__redmine__*` |

---

## 2. Per-Tracker Sprint Dispatch Table

### IF tracker_type == "youtrack"

**Sprint vocabulary:** Sprint (custom field, Agile Board-scoped)
**Config key:** `Sprint field` = `Sprint` (default)
**Sprint proxy in ceos-agents:** None — native Sprint custom field

```
sprint_create:
  TIER 1 (MCP): UNVERIFIED — @vitalyostanin/youtrack-mcp does not expose confirmed sprint CRUD tools
  TIER 2 (Bash + REST):
    curl -X POST "{YOUTRACK_INSTANCE}/api/agiles/{agileID}/sprints" \
      -H "Authorization: Bearer {YOUTRACK_TOKEN}" \
      -H "Content-Type: application/json" \
      -d '{
        "name": "{sprint_name}",
        "goal": "{sprint_goal}",
        "start": {epoch_ms_start},
        "finish": {epoch_ms_end}
      }'
    NOTE: agileID must be resolved first via:
      curl "{YOUTRACK_INSTANCE}/api/agiles?fields=id,name" \
        -H "Authorization: Bearer {YOUTRACK_TOKEN}"
  TIER 3 (skip): Log warning "YouTrack sprint creation unavailable — no agileID configured"

sprint_assign:
  TIER 1 (MCP — preferred):
    mcp__youtrack__update_issue(
      issueId: "{ISSUE_ID}",
      fields: { "Sprint": "{sprint_name}" }
    )
    NOTE: Use custom field name from config Sprint field key (default: "Sprint")
    NOTE: Token "current" addresses the active sprint — no ID resolution needed
  TIER 2 (Bash + REST):
    curl -X POST \
      "{YOUTRACK_INSTANCE}/api/agiles/{agileID}/sprints/{sprintID}/issues" \
      -H "Authorization: Bearer {YOUTRACK_TOKEN}" \
      -H "Content-Type: application/json" \
      -d '{"id": "{ISSUE_ID}"}'
  TIER 3 (skip + warn): Non-blocking. Log warning and continue.

sprint_query:
  MCP: mcp__youtrack__list_issues(query: "project: {PROJECT} Sprint: {sprint_name} State: Open")
  Query syntax: "Sprint: {sprint_name}" appended to existing Bug/Feature query
  Confidence: RELIABLE (YouTrack query language)
```

---

### IF tracker_type == "jira"

**Sprint vocabulary:** Sprint (Scrum board only — Kanban boards have no sprint concept)
**Config key:** `Sprint field` = `Sprint` (default)
**Sprint proxy in ceos-agents:** None — native Sprint (requires Jira Software license, Scrum board)
**Pre-condition check:** Detect board type before any sprint operation:
  `mcp__jira__get_boards(projectKey: "{PROJECT}")` → check `type == "scrum"`
  If `type == "kanban"` → skip sprint operations, log: "Jira board is Kanban — no sprint concept"

```
sprint_create:
  TIER 1 (MCP): NOT CONFIRMED for @modelcontextprotocol/server-atlassian
    sooperset/mcp-atlassian has: jira_get_boards, jira_get_sprints — but NOT jira_create_sprint
  TIER 2 (Bash + REST):
    # Step 1: Resolve board ID
    curl -u "{JIRA_EMAIL}:{JIRA_TOKEN}" \
      "{JIRA_INSTANCE}/rest/agile/1.0/board?projectKeyOrId={PROJECT}" \
      | jq '.values[] | select(.type=="scrum") | .id'
    # Step 2: Create sprint
    curl -X POST \
      -u "{JIRA_EMAIL}:{JIRA_TOKEN}" \
      -H "Content-Type: application/json" \
      "{JIRA_INSTANCE}/rest/agile/1.0/sprint" \
      -d '{
        "name": "{sprint_name}",
        "startDate": "{ISO-8601}",
        "endDate": "{ISO-8601}",
        "originBoardId": {board_id},
        "goal": "{sprint_goal}"
      }'
  TIER 3 (skip): Log warning "Jira sprint creation requires Bash fallback — JIRA_TOKEN must be set"

sprint_assign:
  TIER 1 (MCP — CONFIRMED via sooperset, verify tool name in installed package):
    mcp__jira__add_issues_to_sprint(
      sprintId: {sprint_id},
      issues: ["{ISSUE_KEY}"]
    )
    NOTE: sprint_id is numeric — must resolve from sprint name first:
      mcp__jira__get_sprints(boardId: {board_id}, state: "future,active")
      → find sprint where name == config Sprint field value
  TIER 2 (Bash + REST):
    curl -X POST \
      -u "{JIRA_EMAIL}:{JIRA_TOKEN}" \
      -H "Content-Type: application/json" \
      "{JIRA_INSTANCE}/rest/agile/1.0/sprint/{sprint_id}/issue" \
      -d '{"issues": ["{ISSUE_KEY}"]}'
  TIER 3 (skip + warn): Non-blocking.

sprint_query:
  MCP: mcp__jira__search_issues(jql: "project = {PROJECT} AND sprint = \"{sprint_name}\" AND status = Open")
  Query syntax: JQL `sprint = "{sprint_name}"` (literal sprint name in quotes)
  Confidence: RELIABLE
```

---

### IF tracker_type == "linear"

**Sprint vocabulary:** Cycle (team-scoped, not project-scoped)
**Config key:** `Sprint field` = `Cycle` (recommended default for Linear — document this in config reference)
**Sprint proxy in ceos-agents:** Cycle

```
sprint_create:
  TIER 1 (MCP): UNVERIFIED — official Linear MCP (released 2025-05-01) has no confirmed create_cycle tool
  TIER 2 (Bash + GraphQL):
    curl -X POST https://api.linear.app/graphql \
      -H "Authorization: {LINEAR_API_KEY}" \
      -H "Content-Type: application/json" \
      -d '{
        "query": "mutation { cycleCreate(input: { teamId: \"{TEAM_UUID}\", name: \"{sprint_name}\", startsAt: \"{ISO-8601}\", endsAt: \"{ISO-8601}\" }) { cycle { id name } } }"
      }'
    NOTE: TEAM_UUID must be resolved:
      curl -X POST https://api.linear.app/graphql \
        -H "Authorization: {LINEAR_API_KEY}" \
        -H "Content-Type: application/json" \
        -d '{"query": "{ teams { nodes { id name identifier } } }"}'
  TIER 3 (skip): Log warning "Linear cycle creation unavailable — LINEAR_API_KEY must be set"

sprint_assign:
  TIER 1 (MCP — CONFIRMED):
    mcp__linear__update_issue(
      issueId: "{ISSUE_UUID}",
      cycleId: "{CYCLE_UUID}"
    )
    NOTE: Both issueId and cycleId are UUIDs — must resolve cycle UUID from name first:
      mcp__linear__list_cycles(teamId: "{TEAM_UUID}") → find where name == sprint_name
    ALTERNATE (at create time):
      mcp__linear__create_issue(
        teamId: "{TEAM_UUID}",
        title: "...",
        cycleId: "{CYCLE_UUID}"
      )
  TIER 2 (Bash + GraphQL):
    curl -X POST https://api.linear.app/graphql \
      -H "Authorization: {LINEAR_API_KEY}" \
      -H "Content-Type: application/json" \
      -d '{
        "query": "mutation { issueUpdate(id: \"{ISSUE_UUID}\", input: { cycleId: \"{CYCLE_UUID}\" }) { success } }"
      }'
  TIER 3 (skip + warn): Non-blocking.

sprint_query:
  MCP: mcp__linear__list_issues(cycleId: "{CYCLE_UUID}")
  NOTE: cycleId UUID must be resolved from cycle name before querying
  Confidence: RELIABLE (confirmed)
```

---

### IF tracker_type == "github"

**Sprint vocabulary:** Milestone (no native sprint; Projects V2 Iteration fields exist but MCP support is incomplete — GitHub issue #1854 open)
**Config key:** `Sprint field` = `Milestone` (recommended default for GitHub)
**Sprint proxy in ceos-agents:** Milestone
**Limitation:** No start date (only `due_on`); state machine is open/closed only — no sprint state machine

```
sprint_create:
  TIER 1 (MCP — CONFIRMED):
    mcp__github__create_milestone(
      owner: "{owner}",
      repo: "{repo}",
      title: "{sprint_name}",
      due_on: "{ISO-8601}",
      description: "{sprint_goal}"
    )
  TIER 2 (Bash + REST — fallback only):
    curl -X POST \
      -H "Authorization: token {GITHUB_TOKEN}" \
      -H "Content-Type: application/json" \
      "https://api.github.com/repos/{owner}/{repo}/milestones" \
      -d '{
        "title": "{sprint_name}",
        "due_on": "{ISO-8601}",
        "description": "{sprint_goal}"
      }'
  TIER 3: Not expected — MCP creation is confirmed.

sprint_assign:
  TIER 1 (MCP — CONFIRMED):
    mcp__github__update_issue(
      owner: "{owner}",
      repo: "{repo}",
      issue_number: {issue_number},
      milestone: {milestone_number}
    )
    NOTE: milestone_number is numeric — must resolve from name first:
      mcp__github__list_milestones(owner: "{owner}", repo: "{repo}")
      → find milestone where title == sprint_name → get number
  TIER 2 (Bash + REST):
    curl -X PATCH \
      -H "Authorization: token {GITHUB_TOKEN}" \
      "https://api.github.com/repos/{owner}/{repo}/issues/{issue_number}" \
      -d '{"milestone": {milestone_number}}'
  TIER 3 (skip + warn): Non-blocking.

sprint_query:
  MCP: mcp__github__list_issues(
    owner: "{owner}",
    repo: "{repo}",
    milestone: "{milestone_number}",
    state: "open"
  )
  Query syntax: filter by milestone number (resolve name → number first)
  Confidence: RELIABLE
```

---

### IF tracker_type == "gitea"

**Sprint vocabulary:** Milestone (no native sprint; identical semantics to GitHub milestones)
**Config key:** `Sprint field` = `Milestone` (recommended default for Gitea)
**Sprint proxy in ceos-agents:** Milestone
**Limitation:** No start date (only `due_on`); state machine is open/closed only

```
sprint_create:
  TIER 1 (MCP — CONFIRMED via raohwork/forgejo-mcp):
    mcp__gitea__create_milestone(
      owner: "{owner}",
      repo: "{repo}",
      title: "{sprint_name}",
      due_on: "{ISO-8601}",
      description: "{sprint_goal}"
    )
    OR (alternate prefix):
    mcp__forgejo__create_milestone(...)
  TIER 2 (Bash + REST):
    curl -X POST \
      -H "Authorization: token {GITEA_TOKEN}" \
      -H "Content-Type: application/json" \
      "{GITEA_INSTANCE}/api/v1/repos/{owner}/{repo}/milestones" \
      -d '{
        "title": "{sprint_name}",
        "due_on": "{ISO-8601}",
        "description": "{sprint_goal}"
      }'
  TIER 3: Not expected — MCP creation is confirmed.

sprint_assign:
  TIER 1 (MCP): UNVERIFIED — mcp__gitea__update_issue with milestone parameter not confirmed
  TIER 2 (Bash + REST — primary path):
    # Step 1: Resolve milestone ID
    curl -H "Authorization: token {GITEA_TOKEN}" \
      "{GITEA_INSTANCE}/api/v1/repos/{owner}/{repo}/milestones" \
      | jq '.[] | select(.title=="{sprint_name}") | .id'
    # Step 2: Assign issue
    curl -X PATCH \
      -H "Authorization: token {GITEA_TOKEN}" \
      -H "Content-Type: application/json" \
      "{GITEA_INSTANCE}/api/v1/repos/{owner}/{repo}/issues/{issue_index}" \
      -d '{"milestone": {milestone_id}}'
  TIER 3 (skip + warn): Non-blocking.

sprint_query:
  MCP: mcp__gitea__list_issues(
    owner: "{owner}",
    repo: "{repo}",
    milestone: {milestone_id},
    state: "open"
  )
  NOTE: milestone_id is numeric — resolve from name first via list_milestones
  Confidence: MEDIUM (list_milestones confirmed, milestone filter on list_issues unverified but standard Gitea API)
```

---

### IF tracker_type == "redmine"

**Sprint vocabulary:** Two-tier — Version (core, always available) vs. Agile Sprint (plugin-dependent)
**Config key:** `Sprint field` = `Version` (default; use `Agile Sprint` only if plugin detected)
**Sprint proxy in ceos-agents:** Version (default; Agile Sprint as optional upgrade)
**Pre-condition check:** Detect Agile plugin before attempting agile sprint operations:
  `GET {REDMINE_INSTANCE}/projects/{PROJECT}/agile_sprints.json` → if 404 or error → use Version only

**Default path (Version):**

```
sprint_create:
  TIER 1 (MCP — LIKELY via runekaagaard/mcp-redmine):
    mcp__redmine__create_version(
      project_id: "{PROJECT}",
      name: "{sprint_name}",
      description: "{sprint_goal}",
      due_date: "{YYYY-MM-DD}",
      status: "open"
    )
  TIER 2 (Bash + REST):
    curl -X POST \
      -H "X-Redmine-API-Key: {REDMINE_TOKEN}" \
      -H "Content-Type: application/json" \
      "{REDMINE_INSTANCE}/projects/{PROJECT}/versions.json" \
      -d '{
        "version": {
          "name": "{sprint_name}",
          "description": "{sprint_goal}",
          "due_date": "{YYYY-MM-DD}",
          "status": "open"
        }
      }'
  TIER 3: Not expected if mcp-redmine is installed.

sprint_assign:
  TIER 1 (MCP — LIKELY):
    mcp__redmine__update_issue(
      issue_id: {ISSUE_ID},
      fixed_version_id: {version_id}
    )
    NOTE: version_id is numeric — resolve from name first:
      mcp__redmine__list_versions(project_id: "{PROJECT}")
      → find version where name == sprint_name → get id
  TIER 2 (Bash + REST):
    curl -X PUT \
      -H "X-Redmine-API-Key: {REDMINE_TOKEN}" \
      -H "Content-Type: application/json" \
      "{REDMINE_INSTANCE}/issues/{ISSUE_ID}.json" \
      -d '{"issue": {"fixed_version_id": {version_id}}}'
  TIER 3 (skip + warn): Non-blocking.

sprint_query:
  MCP: mcp__redmine__list_issues(
    project_id: "{PROJECT}",
    fixed_version_id: {version_id},
    status_id: "open"
  )
  Query syntax (URL param form): project_id={PROJECT}&fixed_version_id={version_id}&status_id=open
  Confidence: MEDIUM (API coverage claim ~100% for mcp-redmine)
```

**Optional path (Agile Plugin — only if plugin detected):**

```
sprint_create (agile plugin):
  TIER 2 (Bash only — no MCP server covers plugin API):
    curl -X POST \
      -H "X-Redmine-API-Key: {REDMINE_TOKEN}" \
      -H "Content-Type: application/json" \
      "{REDMINE_INSTANCE}/projects/{PROJECT}/agile_sprints.json" \
      -d '{
        "agile_sprint": {
          "name": "{sprint_name}",
          "sprint_start_date": "{YYYY-MM-DD}",
          "sprint_end_date": "{YYYY-MM-DD}"
        }
      }'

sprint_assign (agile plugin):
  TIER 2 (Bash only):
    curl -X PUT \
      -H "X-Redmine-API-Key: {REDMINE_TOKEN}" \
      -H "Content-Type: application/json" \
      "{REDMINE_INSTANCE}/issues/{ISSUE_ID}.json" \
      -d '{"issue": {"agile_data_attributes": {"agile_sprint_id": {sprint_id}}}}'
```

---

## 3. Cross-Tracker Summary Table

| Tracker | sprint_create | sprint_assign | sprint_query | Sprint field config default |
|---------|--------------|---------------|--------------|----------------------------|
| youtrack | Bash+REST (MCP unverified) | MCP: `update_issue(Sprint: name)` | MCP query lang: `Sprint: {name}` | `Sprint` |
| jira | Bash+REST (MCP not confirmed) | MCP: `add_issues_to_sprint(sprintId, issues)` — requires ID resolution | JQL: `sprint = "{name}"` | `Sprint` |
| linear | Bash+GraphQL (MCP unverified) | MCP: `update_issue(cycleId: uuid)` — requires UUID resolution | MCP: `list_issues(cycleId: uuid)` | `Cycle` |
| github | MCP: `create_milestone(title, due_on)` | MCP: `update_issue(milestone: number)` — requires number resolution | MCP: `list_issues(milestone: number)` | `Milestone` |
| gitea | MCP: `create_milestone(title, due_on)` | Bash+REST (MCP unverified) | MCP: `list_issues(milestone: id)` | `Milestone` |
| redmine | MCP: `create_version(name, due_date)` (likely) | MCP: `update_issue(fixed_version_id: id)` (likely) | MCP: `list_issues(fixed_version_id: id)` | `Version` |

---

## 4. ID Resolution Requirements

All trackers except YouTrack require resolving a name → numeric/UUID ID before assignment. The sprint-plan skill must perform this resolution step before any sprint_assign operation:

| Tracker | Name → ID resolution call |
|---------|--------------------------|
| youtrack | Not needed — `Sprint` field accepts name directly |
| jira | `mcp__jira__get_sprints(boardId)` → filter by name → get `id` (numeric) |
| linear | `mcp__linear__list_cycles(teamId)` → filter by name → get `id` (UUID) |
| github | `mcp__github__list_milestones(owner, repo)` → filter by title → get `number` |
| gitea | `mcp__gitea__list_milestones(owner, repo)` → filter by title → get `id` |
| redmine | `mcp__redmine__list_versions(project_id)` → filter by name → get `id` |

---

## 5. Fallback Decision Logic (for sprint_assign in skill Step 9)

```
FOR EACH issue IN approved_sprint_issues:
  SET assigned = false

  // Tier 1: Try MCP
  TRY:
    IF tracker_type == "youtrack":
      mcp__youtrack__update_issue(issueId, fields: { Sprint: sprint_name })
      SET assigned = true
    ELSE IF tracker_type == "jira":
      mcp__jira__add_issues_to_sprint(sprintId: resolved_id, issues: [issue_key])
      SET assigned = true
    ELSE IF tracker_type == "linear":
      mcp__linear__update_issue(issueId: uuid, cycleId: resolved_uuid)
      SET assigned = true
    ELSE IF tracker_type == "github":
      mcp__github__update_issue(owner, repo, issue_number, milestone: resolved_number)
      SET assigned = true
    ELSE IF tracker_type == "gitea":
      // MCP unverified — skip to Tier 2
      THROW "gitea MCP assign unverified"
    ELSE IF tracker_type == "redmine":
      mcp__redmine__update_issue(issue_id, fixed_version_id: resolved_id)
      SET assigned = true
  CATCH mcp_error:
    LOG WARN "MCP sprint assign failed for {issue_id}: {mcp_error} — trying Bash fallback"

  // Tier 2: Bash + REST
  IF NOT assigned:
    TRY:
      Bash curl command per tracker (see dispatch table above)
      SET assigned = true
    CATCH bash_error:
      LOG WARN "Bash sprint assign failed for {issue_id}: {bash_error}"

  // Tier 3: Skip with warning
  IF NOT assigned:
    LOG WARN "[sprint-plan] Could not assign {issue_id} to sprint '{sprint_name}' — both MCP and REST fallback failed. Issue remains in backlog. Sprint assignment is metadata-only and does not block pipeline."

  // NEVER block pipeline on sprint assignment failure
```

---

## 6. Environment Variables Required for Bash Fallbacks

| Tracker | Variable | Usage |
|---------|----------|-------|
| youtrack | `YOUTRACK_TOKEN`, `YOUTRACK_INSTANCE` | All REST calls |
| jira | `JIRA_TOKEN`, `JIRA_EMAIL`, `JIRA_INSTANCE` | Basic auth REST calls |
| linear | `LINEAR_API_KEY` | Bearer auth GraphQL |
| github | `GITHUB_TOKEN` | token auth REST |
| gitea | `GITEA_TOKEN`, `GITEA_INSTANCE` | token auth REST |
| redmine | `REDMINE_TOKEN`, `REDMINE_INSTANCE` | X-Redmine-API-Key REST |

Variables are read from the environment. If missing when Bash fallback is needed, log warning and proceed to Tier 3 skip.

---

## 7. Codebase Verification Notes

The following patterns were verified against the actual codebase:

- **MCP tool prefixes**: Confirmed in `core/mcp-detection.md` (inline table, lines 26-34) — this is the single source of truth.
- **YouTrack issue update pattern**: `mcp__youtrack__update_issue` with custom field map is the existing pattern used across `skills/implement-feature/SKILL.md` Step 5a (lines 300-307); the Sprint custom field follows the same pattern.
- **GitHub/Gitea milestone MCP**: Confirmed in Phase 1 `final.md` — `create_milestone` confirmed for both; `update_issue(milestone)` confirmed for GitHub; Gitea assign is unverified.
- **Jira sprint tools**: `jira_add_issues_to_sprint` confirmed by sooperset docs; tool name in `@modelcontextprotocol/server-atlassian` may differ — skill must attempt with standard name and fall back to REST on 404/unknown tool.
- **Linear cycle**: `update_issue(cycleId)` confirmed by official Linear MCP; `create_cycle` is unverified MCP.
- **Redmine version**: `mcp-server-redmine` claims ~100% API coverage; `create_version` and `update_issue(fixed_version_id)` are standard Redmine API endpoints — high confidence but labeled "likely" until runtime-confirmed.
- **No existing sprint-specific patterns in codebase**: Step 5a in implement-feature covers sub-issue creation only. Sprint assignment is a net-new operation with no existing dispatch table to extend.
