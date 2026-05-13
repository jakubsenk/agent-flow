# Tracker Reference

Single source of truth for all tracker-specific values. Referenced by `check-setup`, `onboard`, and other commands. To add a new tracker, add one row to each table below.

## Query Syntax

| Tracker | Bug query format | Feature query format |
|---------|-----------------|---------------------|
| youtrack | `project: {P} State: Open Type: Bug` | `project: {P} Type: Feature State: Open` |
| github | `is:issue is:open label:bug` | `is:issue is:open label:enhancement` |
| jira | `project = {P} AND status = Open AND type = Bug` | `project = {P} AND type = Story AND status = Open` |
| linear | `team:{T} state:started type:bug` | `team:{T} type:feature` |
| gitea | `type:issues state:open label:bug` | `type:issues state:open label:enhancement` |
| redmine | `project_id={P}&status_id=open&tracker_id={bug_tracker_id}` | `project_id={P}&status_id=open&tracker_id={feature_tracker_id}` |

> **Redmine note:** `tracker_id` expects the numeric ID from your Redmine instance (typically 1=Bug, 2=Feature, 3=Support). `status_id=open` is a Redmine shortcut that matches all open statuses.

## State Transition Syntax

| Tracker | Format | Example: In Progress | Example: Done |
|---------|--------|---------------------|---------------|
| youtrack | `State: {name}` | `State: In Progress` | `State: Done` |
| github | `add label:{name}`, `set state:{name}`, or `close` | `add label:in-progress` | `close` |
| jira | `transition:{name}` | `transition:In Progress` | `transition:Done` |
| linear | `state:{name}` | `state:In Progress` | `state:Done` |
| gitea | `add label:{name}` or `close` | `add label:in-progress` | `close` |
| redmine | `status_id:{id}` | `status_id:2` | `status_id:5` |

> **Redmine note:** The `status_id:{id}` format uses the numeric ID from your Redmine instance. Common defaults: 1=New, 2=In Progress, 3=Resolved, 4=Feedback, 5=Closed, 6=Rejected. Verify your instance's IDs via `GET /issue_statuses.json`. The legacy `status:{name}` format (e.g., `status:In Progress`) is accepted but unreliable — it depends on LLM translation at runtime, which may fail silently. Use `status_id:{id}` for deterministic behavior.

## Instance & Project Defaults

| Tracker | Default instance | Project format |
|---------|-----------------|----------------|
| youtrack | `{project}.youtrack.cloud` | Project short name (e.g. `PROJ`) |
| github | `github.com` | `owner/repo` |
| jira | `{org}.atlassian.net` | PROJECT key (uppercase) |
| linear | `linear.app` | Team identifier |
| gitea | `<your-gitea-instance>` | `owner/repo` |
| redmine | `<your-redmine-instance>` | Project identifier (slug or numeric ID) |

## On Start Set Defaults

| Tracker | Default On start set |
|---------|---------------------|
| youtrack | `State: In Progress` |
| github | `add label:in-progress` |
| jira | `transition:In Progress` |
| linear | `state:In Progress` |
| gitea | `add label:in-progress` |
| redmine | `status_id:2` |

## PR Description Footer

| Tracker | Footer syntax |
|---------|--------------|
| youtrack | `{issue_link}` |
| github | `Closes #{issue_id}` |
| jira | `{issue_key}` |
| linear | `{issue_id}` |
| gitea | `Fixes #{issue_number}` |
| redmine | `Refs #{issue_id}` |

## Validation Rules

| Tracker | Query validation | State transition format | Instance validation |
|---------|-----------------|------------------------|---------------------|
| youtrack | Must contain `project:` | `State: {name}` | Any URL |
| github | Must contain `is:issue` | `add label:`, `set state:`, or `close` | `github.com` or GHE URL |
| jira | Must contain `project =` | `transition:{name}` | `*.atlassian.net` or self-hosted |
| linear | Must contain `team:` | `state:{name}` | `linear.app` |
| gitea | Must contain `type:issues` | `add label:` or `close` | Any URL |
| redmine | Must contain `project_id=` | `status_id:{id}` or `status:{name}` (legacy) | Any URL |

## MCP Server Detection

| Tracker | Keywords in .mcp.json | Transport | Endpoint / Package |
|---------|----------------------|-----------|--------------------|
| youtrack | `youtrack` | HTTP | `https://<INSTANCE>.youtrack.cloud/mcp` |
| github | `github` | HTTP | `https://api.githubcopilot.com/mcp/` |
| jira | `jira` or `atlassian` | HTTP | `https://mcp.atlassian.com/v1/mcp` |
| linear | `linear` | HTTP | `https://mcp.linear.app/mcp` |
| gitea | `gitea` | stdio (binary) | `gitea-mcp` |
| redmine | `redmine` | stdio (uvx) | `uvx --from mcp-redmine==2026.01.13.152335 mcp-redmine` |

## Sub-Issue Capabilities

| Tracker | Native sub-issues | Parent parameter | Fallback strategy |
|---------|-------------------|-----------------|-------------------|
| youtrack | Yes | `parent: {issue-id}` | N/A |
| jira | Yes | `parent: {key}`, `issuetype: "Sub-task"` | N/A |
| linear | Yes | `parentId: {id}` | N/A |
| redmine | Yes | `parent_issue_id: {id}` | N/A |
| github | No | N/A | Standalone issue: `[{epic_title}] {story_title}`, cross-reference in description |
| gitea | No | N/A | Standalone issue: `[{epic_title}] {story_title}`, cross-reference in description |

> **Note:** The parent parameter names are MCP tool conventions. The LLM uses these when invoking the tracker's MCP create-issue tool. For trackers without native sub-issues, the fallback creates a standalone issue with the epic title as a prefix and adds a link to the parent epic issue in the description body.
