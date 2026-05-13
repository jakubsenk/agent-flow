# Research Agent 1: Tracker API Sprint Semantics

## YouTrack

### Native sprint concept
YouTrack has first-class sprint support as part of its Agile Boards feature. Each Agile board (`/api/agiles/{agileID}`) has a `sprints` collection. A sprint is a named, time-boxed iteration with `name`, `goal`, `start` (epoch ms), `finish` (epoch ms), `isDefault`, and `archived` fields. Issues are linked to sprints via `/api/agiles/{agileID}/sprints/{sprintID}/issues`. The "current" sprint can be addressed via the literal `"current"` token instead of a sprintID.

REST API endpoints (native YouTrack, not MCP-specific):
- `GET /api/agiles` — list all boards
- `POST /api/agiles/{agileID}/sprints` — create sprint
- `GET /api/agiles/{agileID}/sprints/{sprintID}` — get sprint
- `PUT /api/agiles/{agileID}/sprints/{sprintID}` — update sprint
- `POST /api/agiles/{agileID}/sprints/{sprintID}/issues` — add issue to sprint
- `GET /api/issues/{issueID}/sprints` — get sprints an issue belongs to

### MCP tool availability
ceos-agents uses `@vitalyostanin/youtrack-mcp` (prefix: `mcp__youtrack__*`). This package is a lightweight wrapper; its sprint tool coverage is **unverified** but likely limited to read operations (list issues, get sprint state via query). The competing `abdullahtas0/youtrack-mcp-server` (44 tools) explicitly lists sprint management tools but is a different package not referenced in ceos-agents.

A third implementation (`randomnerd/youtrack-mcp`) is documented as "mcp capable of managing youtrack agile boards and issues" and explicitly exposes sprint CRUD.

### Create sprint
- Via native REST: `POST /api/agiles/{agileID}/sprints` with body `{name, start, finish, goal}`
- Via MCP (`abdullahtas0` or `randomnerd` variants): tool name unverified for `@vitalyostanin/youtrack-mcp`; likely **not available** in that specific package
- **Fallback:** Use `mcp__youtrack__*` tool to execute a raw REST call if the server exposes a generic HTTP tool; otherwise call Bash with `curl`

### Assign issue to sprint
- Via native REST: `POST /api/agiles/{agileID}/sprints/{sprintID}/issues` with `{id: issueID, $type: "Issue"}`
- Via MCP: unverified for `@vitalyostanin/youtrack-mcp`
- **Fallback:** Issue custom field "Sprint" can be set via the YouTrack issue update API using `PUT /api/issues/{issueID}` with `customFields` — this is the safest approach since most YouTrack MCP servers support updating custom fields

### Query sprint issues
- Via native REST: `GET /api/agiles/{agileID}/sprints/{sprintID}/issues`
- Via YouTrack query language (works in most MCP servers): `project: {P} sprint: {sprintName}` passed to `mcp__youtrack__list_issues` or equivalent
- **Query language approach is the most reliable fallback** — any YouTrack MCP server that supports issue search supports sprint-based queries

### Limitations
- `@vitalyostanin/youtrack-mcp` sprint tool inventory is not publicly documented in detail; sprint management likely requires raw REST calls or switching to a richer package
- Agile board ID must be known before sprint operations; no auto-discovery in current ceos-agents pipeline
- YouTrack Cloud and Server APIs are identical for sprint management

### Fallback strategy
1. Query: use YouTrack query language `sprint: {name}` in `mcp__youtrack__list_issues`
2. Assign: set `Sprint` custom field via `mcp__youtrack__update_issue` (if the MCP server supports custom field updates)
3. Create sprint: Bash + `curl` against YouTrack REST API using `YOUTRACK_TOKEN` env var

---

## Jira

### Native sprint concept
Jira Software has first-class sprint support via its Agile (Software) API (`/rest/agile/1.0/`). A sprint belongs to a **board** (Scrum board type only — Kanban boards have no sprints). Key relationships: `board → sprints → issues`. Sprint states: `future`, `active`, `closed`.

REST API endpoints (Jira Software Cloud/Server):
- `GET /rest/agile/1.0/board` — list boards
- `POST /rest/agile/1.0/sprint` — create sprint (requires `originBoardId`, `name`; optional: `startDate`, `endDate`, `goal`)
- `GET /rest/agile/1.0/sprint/{sprintId}` — get sprint
- `PUT /rest/agile/1.0/sprint/{sprintId}` — update sprint (name, dates, state, goal)
- `POST /rest/agile/1.0/sprint/{sprintId}/issue` — move issues to sprint (body: `{issues: [issueKey]}`)
- `GET /rest/agile/1.0/board/{boardId}/sprint` — list sprints for a board
- `GET /rest/agile/1.0/sprint/{sprintId}/issue` — get sprint issues

Important: Sprint operations require **Jira Software** license. Jira Work Management (business projects) has no sprint concept.

### Jira Cloud vs Server differences
| Aspect | Cloud | Server/Data Center (8.14+) |
|--------|-------|---------------------------|
| Auth | Basic Auth (email + API token) | Personal Access Token (PAT) |
| Sprint API endpoint | `/rest/agile/1.0/` | `/rest/agile/1.0/` (same) |
| Board types | Scrum, Kanban | Scrum, Kanban |
| Official MCP | Atlassian Remote MCP (cloud-only, managed) | Not supported by official MCP |
| Community MCP | `sooperset/mcp-atlassian` (Cloud + DC 8.14+) | `sooperset/mcp-atlassian` |

### MCP tool availability
ceos-agents uses `@modelcontextprotocol/server-atlassian` (prefix: `mcp__jira__*` or `mcp__atlassian__*`). Sprint tool coverage in this package is **unverified**.

`sooperset/mcp-atlassian` (the most widely used community server) has documented sprint support:
- `jira_add_issues_to_sprint` — move issues to a sprint (confirmed in release notes)
- `jira_get_boards` — list boards (confirmed)
- `jira_get_sprints` — list sprints for a board (confirmed, supports `state` filter: active/future/closed)

Sprint creation and update via MCP: **not confirmed** in `sooperset/mcp-atlassian`; may require raw REST.

`xuanxt/atlassian-mcp` (51 tools) explicitly lists sprint management — but this is a different package.

### Create sprint
- Via Jira REST: `POST /rest/agile/1.0/sprint` — requires board ID (Scrum board only)
- Via MCP (`sooperset`): not confirmed; assume **not available** — use Bash fallback
- **Risk:** Only Scrum boards support sprint creation; Kanban boards do not

### Assign issue to sprint
- Via MCP (`sooperset`): `jira_add_issues_to_sprint(sprintId, issues: [issueKey])` — **confirmed available**
- Via Jira REST: `POST /rest/agile/1.0/sprint/{sprintId}/issue`

### Query sprint issues
- Via MCP: `jira_get_issues` or equivalent with JQL `sprint = "Sprint Name"` or `sprint in openSprints()`
- Via REST: `GET /rest/agile/1.0/sprint/{sprintId}/issue`

### Limitations
- Sprint API is in `@modelcontextprotocol/server-atlassian` (the package ceos-agents actually uses) — tool names may differ from `sooperset/mcp-atlassian`
- Sprint operations only apply to Scrum-type boards; board type must be detected first
- Jira Server/Data Center sprint API is identical to Cloud but authentication differs
- Parent issues that are Sub-tasks cannot have child Sub-tasks (already guarded in ceos-agents decomposition logic)

### Fallback strategy
1. Query: JQL `sprint = "Sprint Name"` or `sprint in openSprints()` in `mcp__jira__search_issues`
2. Assign to sprint: `jira_add_issues_to_sprint` (sooperset) or Bash + Jira REST API
3. Create sprint: Bash + `curl` to `/rest/agile/1.0/sprint` — requires `originBoardId` known in advance

---

## Linear

### Native sprint concept
Linear uses **Cycles** as its sprint equivalent. A Cycle is a time-boxed work period attached to a **Team** (not a project). Key fields: `id` (UUID), `name`, `number`, `startsAt`, `endsAt`, `completedAt`, `teamId`, `isActive`. Issues are linked to cycles via `cycleId` on the issue object. Linear also has **Projects** (roadmap-level grouping) which are distinct from Cycles.

As of February 2026, Linear's official MCP also supports **Initiatives** and **Milestones** (cross-team program-level grouping, distinct from Cycles).

### MCP tool availability
ceos-agents uses `@modelcontextprotocol/server-linear` (prefix: `mcp__linear__*`). Linear released an **official** MCP server on 2025-05-01. This is the recommended integration.

Confirmed tools in the official Linear MCP (as of 2025–2026):
- `list_issues` — with `cycleId` filter support
- `get_issue` — includes `cycleId` field
- `create_issue` — with `cycleId` parameter (assigns issue to cycle at creation)
- `update_issue` — with `cycleId` parameter (moves issue between cycles)
- `list_teams` / `get_team`
- `list_projects` / `get_project`
- `create_project` / `update_project`

Cycle-specific tools (availability varies by MCP implementation):
- `get_current_cycle` — get active cycle for a team (confirmed in community servers, likely in official)
- `list_cycle_issues` — issues in a cycle (confirmed in community servers)
- Dedicated `create_cycle` tool: **unverified** in the official Linear MCP; creating cycles may require GraphQL API directly

### Create sprint (cycle)
- Via Linear GraphQL API: `mutation { cycleCreate(input: {teamId, name, startsAt, endsAt}) }`
- Via official MCP: **unverified** — no confirmed `create_cycle` tool in the official MCP (as of research date)
- **Fallback:** Bash + `curl` with Linear GraphQL API endpoint `https://api.linear.app/graphql` using `LINEAR_API_KEY` — Linear exposes its full API via GraphQL; cycle creation is well-documented

### Assign issue to sprint (cycle)
- Via official MCP: `update_issue(id: issueId, cycleId: cycleUUID)` — **confirmed available**
- Via Linear GraphQL: `mutation { cycleIssueCreate(cycleId, issueId) }` or `issueUpdate(id, input: {cycleId})`
- Assignment at creation: `create_issue(teamId, title, cycleId: cycleUUID)` — **confirmed available**

### Query sprint issues
- Via MCP: `list_issues` with `filter: {cycle: {id: {eq: cycleUUID}}}` or `cycleId` filter — **confirmed available**
- Via GraphQL: `query { cycle(id: cycleUUID) { issues { nodes { id title } } } }`

### Limitations
- Cycles are team-scoped (not project-scoped); a single project can span multiple teams and thus multiple cycles
- Cycle UUID must be resolved before assignment; no string-name lookup in most MCP tools
- `create_cycle` may not be exposed in the official Linear MCP; community servers vary
- Linear's official MCP uses OAuth (remote MCP) — authentication flow differs from API key-based servers

### Fallback strategy
1. Assign to cycle: `mcp__linear__update_issue` with `cycleId` — reliable, confirmed
2. Query cycle issues: `mcp__linear__list_issues` with cycle filter — reliable
3. Create cycle: Bash + Linear GraphQL API (most reliable approach since MCP tool unverified)
4. Resolve cycle by name: `mcp__linear__list_teams` → team UUID → GraphQL `cycles(filter: {name: {eq: "Sprint N"}})` or `get_current_cycle`

---

## GitHub

### Native sprint concept
GitHub has **no native sprint concept**. The proxies are:
1. **Milestones** — time-boxed containers for issues/PRs with a due date, title, description, and open/closed state. This is the closest sprint equivalent.
2. **GitHub Projects V2** — board-style project management with custom fields including an **Iteration field** (true sprint-like container with start date, duration, cadence). This is the more powerful agile tool but requires Projects V2 setup.

Current ceos-agents decomposition logic treats GitHub as "no native sub-issues" and uses standalone issues with title prefixing — the same pattern applies to sprint assignment (milestones).

### MCP tool availability
ceos-agents uses `@modelcontextprotocol/server-github` (prefix: `mcp__github__*`). GitHub released an official MCP server, updated in October 2025 to include **GitHub Projects** support (not enabled by default; requires `--toolsets projects` flag).

Milestone tools in `@modelcontextprotocol/server-github`:
- `create_milestone(owner, repo, title, due_on?, description?, state?)` — **confirmed available**
- `list_milestones(owner, repo, state?, sort?, direction?)` — **confirmed available**
- `get_milestone(owner, repo, milestone_number)` — **confirmed available**
- `update_milestone(owner, repo, milestone_number, ...)` — **confirmed available**
- Issues can be assigned to milestones via `create_issue` or `update_issue` with `milestone: milestone_number`

GitHub Projects V2 Iteration tools (via `--toolsets projects`):
- Project management tools added in October 2025; iteration field support via `mcp__github__*` project tools
- Specific iteration CRUD tool names: **unverified** — GitHub issue #1854 requests `Support for GitHub Projects v2 Iteration Fields` and is open as of research date, suggesting iteration field management via MCP may still be limited

### Create sprint (milestone)
- `mcp__github__create_milestone(owner, repo, title, due_on)` — **confirmed available**
- Milestone `title` = sprint name; `due_on` = sprint end date (ISO 8601)

### Assign issue to sprint (milestone)
- `mcp__github__update_issue(owner, repo, issue_number, milestone: milestone_number)` — **confirmed available**
- `mcp__github__create_issue(owner, repo, title, body, milestone: milestone_number)` — **confirmed at creation**

### Query sprint issues
- `mcp__github__list_issues(owner, repo, milestone: milestone_number)` — **confirmed available**
- Milestone number must be resolved first via `list_milestones`

### Limitations
- Milestones have no "start date" — only `due_on` (end date); true sprint velocity tracking is not possible via milestones alone
- No sprint state machine (active/future/closed) — only open/closed milestone states
- GitHub Projects V2 Iteration fields provide proper sprint semantics but: (a) require Projects setup, (b) MCP iteration field support is incomplete as of research date, (c) projects toolset must be explicitly enabled
- No sub-issue nesting — decomposition checklist pattern (already in ceos-agents) is the correct approach

### Fallback strategy
1. Sprint proxy = Milestone; use `mcp__github__create_milestone` + `mcp__github__update_issue(milestone: N)`
2. For richer sprint tracking: Projects V2 with iteration field — requires manual Projects setup by user; MCP toolset must be enabled in server config
3. Query sprint issues: `mcp__github__list_issues(milestone: N)` — reliable

---

## Gitea

### Native sprint concept
Gitea/Forgejo has **no native sprint concept**. The proxy is **Milestones** — identical semantics to GitHub milestones: title, description, due date, open/closed state. No Projects V2 equivalent with iteration fields.

### MCP tool availability
ceos-agents uses `forgejo-mcp` (prefix: `mcp__gitea__*` or `mcp__forgejo__*`). The primary implementation is `raohwork/forgejo-mcp`.

Milestone tools in `raohwork/forgejo-mcp` (confirmed via PR #83 and documentation):
- `list_repo_milestones(owner, repo)` — **confirmed available** (added in PR #83)
- `create_milestone(owner, repo, title, due_on?, description?)` — **confirmed available**
- Edit/delete milestone: **confirmed available** (documentation states "Manage milestones: create, edit, delete")
- `get_milestone`: **likely available** (listed in search results); exact parameter signature unverified

Issue assignment to milestone: Gitea REST API supports `milestone` field on issue create/update. Whether `forgejo-mcp` exposes this via `create_issue` / `update_issue` with a `milestone` parameter is **unverified** — the documentation focuses on issue management tools without milestone-assignment specifics.

### Create sprint (milestone)
- `mcp__gitea__create_milestone(owner, repo, title, due_on?)` — **confirmed available**
- Fallback: Bash + Gitea REST API `POST /api/v1/repos/{owner}/{repo}/milestones`

### Assign issue to sprint (milestone)
- Via Gitea REST: `PATCH /api/v1/repos/{owner}/{repo}/issues/{index}` with `{"milestone": milestone_id}`
- Via MCP: `mcp__gitea__update_issue(owner, repo, index, milestone: milestone_id)` — **unverified** whether the `milestone` parameter is exposed
- **Fallback:** Bash + Gitea REST API using `GITEA_TOKEN` env var

### Query sprint issues
- Via Gitea REST: `GET /api/v1/repos/{owner}/{repo}/issues?milestone=N`
- Via MCP: `mcp__gitea__list_issues(owner, repo, milestone: N)` — **unverified**
- Fallback: filter all issues client-side after `list_repo_milestones` + `list_issues`

### Limitations
- No sprint start date in milestones — only `due_on`
- No sprint velocity or capacity tracking
- Issue-to-milestone assignment via MCP is unverified; may require direct REST calls
- Gitea and Forgejo share the same REST API surface; `raohwork/forgejo-mcp` works for both

### Fallback strategy
1. Sprint proxy = Milestone; `mcp__gitea__create_milestone` for creation
2. Assign to sprint: Bash + `curl` to Gitea REST API if MCP doesn't expose `milestone` param on issue update
3. Query: Bash + Gitea REST `GET /issues?milestone=N` or `list_issues` with milestone filter if available

---

## Redmine

### Native sprint concept
Redmine has a **two-tier sprint model**:

**Tier 1 — Core Versions (always available):**
Redmine's built-in "Version" (`/projects/{id}/versions`) serves as a lightweight sprint proxy. Key fields: `name`, `description`, `due_date`, `status` (open/locked/closed), `sharing`. Issues are assigned via `fixed_version` field (also displayed as "Target version" in UI). REST API is fully supported in core Redmine.

**Tier 2 — Agile Plugin Sprints (plugin-dependent):**
The RedmineUP Agile plugin (`redmine_agile`) adds true sprint objects. From Agile plugin v1.5.0+, sprints are separate entities from versions: `GET/POST/PUT/DELETE /projects/{id}/agile_sprints/{sprint_id}.json`. To assign an issue to an Agile sprint: `PUT /issues/{issue_id}.json` with `{issue: {agile_data_attributes: {agile_sprint_id: N}}}`.

### MCP tool availability
ceos-agents uses `mcp-server-redmine` (prefix: `mcp__redmine__*`). The primary implementations are:
- `runekaagaard/mcp-redmine` — "covering close to 100% of Redmine's API"; uses httpx + Redmine OpenAPI spec
- `@icoach/redmine-mcp-server` — comprehensive integration

For `runekaagaard/mcp-redmine`:
- Version (sprint proxy) tools: **likely available** — the server claims ~100% API coverage and Redmine's Versions API is a core endpoint
- Agile plugin sprint tools: **likely not available** — plugin-specific endpoints require plugin to be installed and are not part of core Redmine OpenAPI spec
- Issue `fixed_version` assignment: **likely available** via `mcp__redmine__update_issue` since it's a standard issue field

### Create sprint (version)
- Via MCP: `mcp__redmine__create_version(project_id, name, due_date?, status?)` — **likely available** (core API)
- Via REST: `POST /projects/{id}/versions.json` with `{version: {name, due_date, status}}`

### Assign issue to sprint (version)
- Via MCP: `mcp__redmine__update_issue(issue_id, fixed_version_id: N)` — **likely available** (standard issue field)
- Via REST: `PUT /issues/{id}.json` with `{issue: {fixed_version_id: N}}`
- Note: `fixed_version` is the API name; "Target version" is the UI display name

### Assign issue to Agile sprint (plugin)
- Via REST only: `PUT /issues/{id}.json` with `{issue: {agile_data_attributes: {agile_sprint_id: N}}}`
- Via MCP: **not available** — Agile plugin endpoints are outside core Redmine API

### Query sprint issues
- Via MCP: `mcp__redmine__list_issues(fixed_version_id: N)` — **likely available**
- Via REST: `GET /issues.json?fixed_version_id=N`
- Agile sprint query: `GET /issues.json?agile_sprint_id=N` (Agile plugin only)

### Limitations
- Version (core) vs. Agile sprint (plugin) are **two distinct objects** — most Redmine instances use versions; Agile sprints require the paid RedmineUP plugin
- MCP servers target core Redmine API; Agile plugin sprint operations require direct REST calls
- `fixed_version_id` is a numeric ID; must resolve version name to ID before assignment
- Redmine's REST API historically had issues with `fixed_version` visibility in list responses (bug #6843, #23763) — resolved in modern Redmine versions

### Fallback strategy
1. Use core **Version** as sprint proxy — universally available, no plugin required
2. Assign via `mcp__redmine__update_issue(fixed_version_id: N)` — reliable core API
3. Create version: `mcp__redmine__create_version(project_id, name, due_date)` — reliable
4. Agile sprint assignment: Bash + `curl` with Agile plugin REST endpoint (only if plugin confirmed installed)
5. Resolve version name to ID: `mcp__redmine__list_versions(project_id)` then filter by name

---

## Cross-Tracker Comparison Matrix

| Feature | YouTrack | Jira | Linear | GitHub | Gitea | Redmine |
|---------|----------|------|--------|--------|-------|---------|
| Native sprint object | Yes (Sprint) | Yes (Sprint, Scrum boards only) | Yes (Cycle) | No | No | Partial (Version core; Sprint via plugin) |
| Sprint proxy | — | — | — | Milestone | Milestone | Version (always), Agile Sprint (plugin) |
| Create sprint via MCP | Unverified (`@vitalyostanin`) | Not confirmed (`sooperset`) | Unverified (official) | `create_milestone` (confirmed) | `create_milestone` (confirmed) | `create_version` (likely) |
| Assign issue to sprint via MCP | Unverified | `jira_add_issues_to_sprint` (confirmed) | `update_issue(cycleId)` (confirmed) | `update_issue(milestone)` (confirmed) | Unverified | `update_issue(fixed_version_id)` (likely) |
| Query sprint issues via MCP | Query language (reliable) | JQL `sprint = "X"` (reliable) | `list_issues(cycleId)` (confirmed) | `list_issues(milestone)` (confirmed) | Unverified | `list_issues(fixed_version_id)` (likely) |
| Sprint start date | Yes | Yes | Yes (Cycle) | No (milestone: due_on only) | No (milestone: due_on only) | No (version: due_date only) |
| Sprint state machine | Yes (active/archived) | Yes (future/active/closed) | Yes (active/completed) | Open/Closed only | Open/Closed only | Open/Locked/Closed |
| Velocity tracking | Yes (board) | Yes (board) | Yes (built-in) | No | No | No (Agile plugin only) |
| MCP package used by ceos-agents | `@vitalyostanin/youtrack-mcp` | `@modelcontextprotocol/server-atlassian` | `@modelcontextprotocol/server-linear` | `@modelcontextprotocol/server-github` | `forgejo-mcp` | `mcp-server-redmine` |
| Sprint tooling confidence | Low | Medium | High (assign), Low (create) | High (milestone) | Medium (create confirmed, assign unverified) | Medium (version), Low (agile sprint) |

---

## Key Findings & Risks

### Finding 1: Vocabulary mismatch across trackers
Sprint → Cycle (Linear), Milestone (GitHub/Gitea), Version or Agile Sprint (Redmine). Any sprint feature in ceos-agents must abstract over these terms. A `sprint_proxy_type` field in the pipeline config would be needed: `sprint | cycle | milestone | version`.

### Finding 2: MCP sprint creation is the weakest link
- YouTrack: `@vitalyostanin/youtrack-mcp` sprint creation tools **unverified** — this is the default package
- Jira: `@modelcontextprotocol/server-atlassian` sprint creation **not confirmed** — the default package
- Linear: official MCP `create_cycle` **unverified**
- GitHub/Gitea: `create_milestone` **confirmed** — the most reliable for sprint creation via MCP
- Redmine: `create_version` **likely available** in `mcp-server-redmine`

**Risk:** For YouTrack and Jira (the two primary enterprise trackers), sprint creation via the currently-registered MCP packages may require falling back to direct REST API calls via Bash.

### Finding 3: Issue-to-sprint assignment is better covered
- Linear `update_issue(cycleId)` — confirmed
- Jira `jira_add_issues_to_sprint` — confirmed (sooperset package, not necessarily the ceos-agents default)
- GitHub `update_issue(milestone)` — confirmed
- YouTrack, Gitea, Redmine — unverified but REST fallback is straightforward

### Finding 4: Query is universally reliable via native query languages
All trackers support filtering issues by sprint/cycle/milestone in their native query language, which is the input to the existing MCP `list_issues` / `search_issues` tools. This path requires zero new MCP tool additions.

### Finding 5: Redmine dual-model complexity
Redmine has two sprint concepts (Version vs. Agile Sprint) that behave differently and have different API surfaces. The Agile plugin is not universally installed. ceos-agents should default to Version for maximum compatibility; Agile Sprint support should be optional and gated on plugin detection.

### Finding 6: GitHub Projects V2 Iteration fields are not MCP-ready
The official GitHub MCP server added Projects support in October 2025 but the iteration field (true sprint with start+end dates) is not yet fully manageable via MCP (GitHub issue #1854 is open). Milestone is the safe sprint proxy for GitHub/Gitea.

### Recommended Implementation Approach
Given the gaps above, a sprint assignment feature in ceos-agents should:
1. Use a **3-tier strategy per tracker**: (a) try MCP tool, (b) fallback to Bash + REST, (c) skip with warning if both unavailable
2. Treat sprint assignment as **optional and non-blocking** — the pipeline continues even if sprint assignment fails
3. Resolve sprint/cycle by name before assignment (list + filter); never hardcode IDs in config
4. Add a `Sprint` optional config section: `Name pattern` (e.g., `Sprint {YYYY-WW}`) and `Auto-assign` (enabled/disabled)
5. For Redmine: detect whether Agile plugin is available before attempting sprint-specific operations
