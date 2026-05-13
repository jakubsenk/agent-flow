# Design: Redmine Tracker Support + Centralized Tracker Reference

**Date:** 2026-03-03
**Version impact:** MINOR bump (new optional tracker type, new reference document)
**Status:** Implemented

## Problem

Adding a new issue tracker currently requires editing 7+ files with tracker-specific inline logic scattered across commands (`check-setup.md`, `onboard.md`), documentation, and examples. This violates the single-source-of-truth principle. The immediate goal is to add Redmine support, but the design should also make future tracker additions trivial.

## Research

Analyzed how Renovate, Terraform, Backstage.io, Danger.js, semantic-release, and AI coding agents handle multi-provider support. All mature tools converge on one principle: **provider-specific data must be co-located with the provider, not scattered across core files**. For a markdown-only plugin where the LLM is the runtime, this translates to a centralized lookup table.

## Design

### Component 1: Centralized Tracker Reference (`docs/reference/trackers.md`)

A single source of truth for all tracker-specific values. Commands and agents reference this file instead of containing inline per-tracker logic.

Structure — lookup tables keyed by tracker type:

#### Query Syntax

| Tracker | Bug query format | Feature query format |
|---------|-----------------|---------------------|
| youtrack | `project: {P} State: Open Type: Bug` | `project: {P} Type: Feature State: Open` |
| github | `is:issue is:open label:bug` | `is:issue is:open label:enhancement` |
| jira | `project = {P} AND status = Open AND type = Bug` | `project = {P} AND type = Story AND status = Open` |
| linear | `team:{T} state:started type:bug` | `team:{T} type:feature` |
| gitea | `type:issues state:open label:bug` | `type:issues state:open label:enhancement` |
| redmine | `project_id={P}&status_id=open&tracker_id={bug_tracker_id}` | `project_id={P}&status_id=open&tracker_id={feature_tracker_id}` |

#### State Transition Syntax

| Tracker | Format | Example: In Progress | Example: Done |
|---------|--------|---------------------|---------------|
| youtrack | `State: {name}` | `State: In Progress` | `State: Done` |
| github | `add label:{name}`, `set state:{name}`, or `close` | `add label:in-progress` | `close` |
| jira | `transition:{name}` | `transition:In Progress` | `transition:Done` |
| linear | `state:{name}` | `state:In Progress` | `state:Done` |
| gitea | `add label:{name}` or `close` | `add label:in-progress` | `close` |
| redmine | `status:{name}` (see note below) | `status:In Progress` | `status:Closed` |

**Note on Redmine state transitions:** The `status:{name}` format is an LLM convention used by the pipeline to communicate intent. The LLM translates this to the appropriate Redmine API call (e.g., `status_id=2` for "In Progress"). Status name → ID mapping depends on the Redmine instance configuration. The MCP server handles the translation when updating issues.

#### Instance & Project Defaults

| Tracker | Default instance | Project format |
|---------|-----------------|----------------|
| youtrack | `{project}.youtrack.cloud` | Project short name (e.g. `PROJ`) |
| github | `github.com` | `owner/repo` |
| jira | `{org}.atlassian.net` | PROJECT key (uppercase) |
| linear | `linear.app` | Team identifier |
| gitea | `<your-gitea-instance>` | `owner/repo` |
| redmine | `<your-redmine-instance>` | Project identifier (slug or numeric ID) |

#### On Start Set Defaults

| Tracker | Default On start set |
|---------|---------------------|
| youtrack | `State: In Progress` |
| github | `add label:in-progress` |
| jira | `transition:In Progress` |
| linear | `state:In Progress` |
| gitea | `add label:in-progress` |
| redmine | `status:In Progress` |

#### PR Description Footer

| Tracker | Footer syntax |
|---------|--------------|
| youtrack | `{issue_link}` |
| github | `Closes #{issue_id}` |
| jira | `{issue_key}` |
| linear | `{issue_id}` |
| gitea | `Fixes #{issue_number}` |
| redmine | `Refs #{issue_id}` |

#### Validation Rules

| Tracker | Query validation | State transition format | Instance validation |
|---------|-----------------|------------------------|---------------------|
| youtrack | Must contain `project:` | `State: {name}` | Any URL |
| github | Must contain `is:issue` | `add label:`, `set state:`, or `close` | `github.com` or GHE URL |
| jira | Must contain `project =` | `transition:{name}` | `*.atlassian.net` or self-hosted |
| linear | Must contain `team:` | `state:{name}` | `linear.app` |
| gitea | Must contain `type:issues` | `add label:` or `close` | Any URL |
| redmine | Must contain `project_id=` | `status:{name}` (LLM convention — translated to `status_id` in Redmine API) | Any URL |

#### MCP Server Detection

| Tracker | Keywords in .mcp.json | Package |
|---------|----------------------|---------|
| youtrack | `youtrack` | `@vitalyostanin/youtrack-mcp` |
| github | `github` | `@modelcontextprotocol/server-github` |
| jira | `jira` or `atlassian` | `@modelcontextprotocol/server-atlassian` |
| linear | `linear` | `@modelcontextprotocol/server-linear` |
| gitea | `gitea` or `forgejo` | `forgejo-mcp` |
| redmine | `redmine` | `mcp-server-redmine` |

### Component 2: Refactored Commands

#### `commands/check-setup.md` — Step 3a

Replace the current 5 inline per-tracker blocks (lines 32-59) with:

```markdown
### 3a. Per-tracker validation

Read `docs/reference/trackers.md`. Find the row matching the configured Type in the Validation Rules table.
- Apply the query validation rule for that tracker to the Bug query value
- Apply the state transition format check to the State transitions value
- Apply the instance validation rule (if any) to the Instance value
- For unknown Type → [WARN] "Unknown tracker type '{Type}'. Validation skipped."
```

#### `commands/check-setup.md` — Step 7 (MCP server detection)

Replace the current 5 inline lines (lines 76-80) with:

```markdown
- Issue tracker MCP: read the MCP Server Detection table from `docs/reference/trackers.md`.
  Find the row matching Type. Search .mcp.json server names/URLs for the listed keywords.
```

#### `commands/onboard.md` — Step 2

Replace inline per-tracker defaults (lines 51-90) with references to `docs/reference/trackers.md`:

```markdown
1. Which issue tracker do you use? (youtrack / github / jira / linear / gitea / redmine)
2. Instance URL — read defaults from `docs/reference/trackers.md` Instance & Project Defaults table
3. Project name / key — read format from the same table
4. Bug query — read defaults from Query Syntax table, substitute the project name
5. Feature query — read defaults from Query Syntax table
6. State transitions — read defaults from State Transition Syntax table. Compose the full value using comma separator: `In Progress: {format}, Blocked: {format}, For Review: {format}, Done: {format}`
7. On start set — read defaults from On Start Set Defaults table
```

#### `commands/onboard.md` — Step 4b (PR Description Template footer)

Replace inline per-tracker footers (lines 123-127) with:

```markdown
Tracker-specific footers — read from `docs/reference/trackers.md` PR Description Footer table.
```

### Component 3: Documentation Updates

#### `CLAUDE.md` — Config Contract

Change the Issue Tracker Type allowed values from:
```
youtrack/github/jira/linear/gitea
```
to:
```
youtrack/github/jira/linear/gitea/redmine
```

#### `docs/reference/automation-config.md`

- Add `redmine` to the Type key description (line 43)
- Add a Redmine example block after the Gitea example

**Redmine example:**

```markdown
**Redmine example:**

| Key | Value |
|-----|-------|
| Type | `redmine` |
| Instance | `https://redmine.example.com` |
| Project | `my-project` |
| Bug query | `project_id=my-project&status_id=open&tracker_id=1` |
| State transitions | `In Progress: status:In Progress, Blocked: status:Blocked, For Review: status:For Review, Done: status:Closed` |
| On start set | `status:In Progress` |
```

#### `docs/guides/mcp-configuration.md`

Add new section:

```markdown
## Redmine MCP server

- **Package:** `mcp-server-redmine` (npm)
- **Source:** [github.com/yonaka15/mcp-server-redmine](https://github.com/yonaka15/mcp-server-redmine)
- **Launch:** `npx -y --prefix /path/to/mcp-server-redmine mcp-server-redmine`
- **Env variables:** `REDMINE_HOST`, `REDMINE_API_KEY`
- **Config:**

{
  "mcpServers": {
    "redmine": {
      "command": "npx",
      "args": ["-y", "--prefix", "/path/to/mcp-server-redmine", "mcp-server-redmine"],
      "env": {
        "REDMINE_HOST": "https://<redmine-instance>",
        "REDMINE_API_KEY": "<redmine-api-key>"
      }
    }
  }
}

Replace `/path/to/mcp-server-redmine` with the actual installation directory (e.g., `~/.mcp/mcp-server-redmine`).

- **Verification:** In Claude Code, ask about an existing Redmine issue. If you see issue data, the MCP server is working.
```

#### `docs/guides/tokens.md`

Add new section:

```markdown
## Redmine API Key

1. Open Redmine → **My account** (top right)
2. In the right sidebar: **API access key → Show**
3. If no key exists, click **Reset** to generate one
4. Copy the key
5. Alternative: Admin can generate keys via Administration → Users → {user} → API access key

Note: Redmine API key provides full access to whatever the user can access in the UI. There are no scoped tokens in Redmine.
```

#### `docs/guides/tokens.md` — Overview table

Add row:

```
| Redmine API key | Issue tracker | `mcp-server-redmine` |
```

### Component 4: Example Config

New file `examples/configs/redmine-rails.md`:

```markdown
# Ruby on Rails + Redmine — Automation Config Template

> Copy the section below into your project's CLAUDE.md

## Automation Config

### Issue Tracker
| Key | Value |
|------|---------|
| Type | redmine |
| Instance | `<your-redmine-instance>` |
| Project | `<project-identifier>` |
| Bug query | `project_id=<project-identifier>&status_id=open&tracker_id=<bug-tracker-id>` |
| State transitions | In Progress: `status:In Progress`, Blocked: `status:Blocked`, For Review: `status:For Review`, Done: `status:Closed` |
| On start set | `status:In Progress` |

### Source Control
| Key | Value |
|------|---------|
| Remote | `<owner/repo>` |
| Base branch | `main` |
| Branch naming | `fix/{issue}-{short-description}` |

### PR Rules
| Key | Value |
|------|---------|
| Labels | `ForReview` |

### PR Description Template

## Summary
{summary}

## Changes
{changes}

## Testing
{testing}

Refs #{issue_id}

### Build & Test
| Key | Value |
|------|---------|
| Build command | `bundle exec rails assets:precompile` |
| Test command | `bundle exec rspec` |
```

### Component 5: Template Command Update

Update `commands/template.md` — add Redmine row to the Available Templates table:

```
| redmine-rails | Ruby on Rails | Redmine |
```

## Files Changed Summary

| File | Change type | Description |
|------|------------|-------------|
| `docs/reference/trackers.md` | NEW | Centralized tracker reference with 7 lookup tables |
| `commands/check-setup.md` | REFACTOR | Replace inline blocks with reference to trackers.md |
| `commands/onboard.md` | REFACTOR | Replace inline defaults with reference to trackers.md |
| `commands/template.md` | ADD | Add redmine-rails to template table |
| `CLAUDE.md` | EDIT | Add `redmine` to allowed types |
| `docs/reference/automation-config.md` | ADD | Add redmine to Type + Redmine example |
| `docs/guides/mcp-configuration.md` | ADD | Add Redmine MCP server section |
| `docs/guides/tokens.md` | ADD | Add Redmine API key section + overview row |
| `examples/configs/redmine-rails.md` | NEW | Example Automation Config for Redmine + Rails |
| `README.md` | EDIT | Add Redmine to mermaid diagram (line 21) + update "5 supported" → "6 supported" (line 228) |
| `docs/getting-started.md` | EDIT | Add `redmine` to tracker list (line 44) |
| `docs/architecture.md` | EDIT | Add Redmine to mermaid diagram (line 36) |
| `docs/reference/commands.md` | EDIT | Update "5 tracker types" → "6 tracker types" + add Redmine to list (line 330) |

## Tests

Test fixtures (`tests/mock-project/CLAUDE.md`, `tests/harness/fixtures/automation-config.md`) use specific tracker types (youtrack, github) and do not enumerate all types. No changes needed — adding a new tracker type does not break existing test scenarios. A Redmine-specific test fixture is out of scope for this change (can be added later if Redmine E2E testing is needed).

## What Does NOT Change

- Agent files — agents are tracker-agnostic by design
- Pipeline commands (`fix-bugs`, `fix-ticket`, `publish`, etc.) — they pass Type through without inspection
- Other commands (`changelog`, `status`, `resume-ticket`) — they just read Type
- Config contract structure — no new required keys
- Versioning — this is a MINOR bump (new optional capability)
- Historical plan documents in `docs/plans/` — these reference the state at the time they were written and are not updated retroactively

## Risks

1. **Redmine query syntax uses REST API parameters** — the `mcp-server-redmine` package passes parameters directly to the Redmine REST API. `tracker_id` and `status_id` expect numeric IDs that vary per Redmine instance. Default examples use `status_id=open` (a Redmine shortcut) and `tracker_id=<bug-tracker-id>` as a placeholder. The onboard wizard and trackers.md note this. Users must look up their instance's tracker IDs (typically: 1=Bug, 2=Feature, 3=Support).
2. **Redmine has no scoped tokens** — unlike GitHub/Jira, Redmine API keys grant full user access. Documented in tokens.md.
3. **Refactoring check-setup/onboard to reference trackers.md** — the LLM must reliably read a separate file mid-execution. This is a standard pattern (agents already read CLAUDE.md mid-execution), so risk is low.
4. **MCP server requires `--prefix` flag** — unlike other MCP servers in the plugin that use simple `npx -y <package>`, `mcp-server-redmine` requires `--prefix /path/to/...` for installation. This is documented in the MCP configuration section with a clear note about replacing the path.
