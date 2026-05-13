# Redmine Tracker Support + Centralized Tracker Reference — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add Redmine as a 6th supported issue tracker and centralize all tracker-specific data into a single reference document (`docs/reference/trackers.md`), eliminating scattered inline per-tracker logic from commands.

**Architecture:** Create `docs/reference/trackers.md` as the single source of truth for tracker-specific values (query syntax, state transitions, validation rules, MCP detection, defaults). Refactor `check-setup.md` and `onboard.md` to reference that file instead of containing inline per-tracker blocks. Add Redmine to all documentation, examples, and diagrams.

**Tech Stack:** Pure markdown — no code, no build, no dependencies.

**Design doc:** `docs/plans/2026-03-03-redmine-tracker-support-design.md`

---

### Task 1: Create `docs/reference/trackers.md`

**Files:**
- Create: `docs/reference/trackers.md`

**Step 1: Create the centralized tracker reference file**

Create `docs/reference/trackers.md` with the following exact content:

```markdown
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
| redmine | `status:{name}` | `status:In Progress` | `status:Closed` |

> **Redmine note:** The `status:{name}` format is an LLM convention. The LLM translates this to the appropriate Redmine API call (e.g., `status_id=2` for "In Progress"). Status name-to-ID mapping depends on the Redmine instance configuration.

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
| redmine | `status:In Progress` |

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
| redmine | Must contain `project_id=` | `status:{name}` | Any URL |

## MCP Server Detection

| Tracker | Keywords in .mcp.json | Package |
|---------|----------------------|---------|
| youtrack | `youtrack` | `@vitalyostanin/youtrack-mcp` |
| github | `github` | `@modelcontextprotocol/server-github` |
| jira | `jira` or `atlassian` | `@modelcontextprotocol/server-atlassian` |
| linear | `linear` | `@modelcontextprotocol/server-linear` |
| gitea | `gitea` or `forgejo` | `forgejo-mcp` |
| redmine | `redmine` | `mcp-server-redmine` |
```

**Step 2: Commit**

```bash
git add docs/reference/trackers.md
git commit -m "feat: add centralized tracker reference (docs/reference/trackers.md)"
```

---

### Task 2: Refactor `commands/check-setup.md`

**Files:**
- Modify: `commands/check-setup.md:28-59` (Step 3a per-tracker blocks)
- Modify: `commands/check-setup.md:75-80` (Step 7 MCP detection)

**Step 1: Replace Step 3a inline per-tracker blocks**

In `commands/check-setup.md`, replace lines 28-59 (from `### 3a. Per-tracker validation` through the unknown Type fallback) with:

```markdown
### 3a. Per-tracker validation

Read `docs/reference/trackers.md`. Find the row matching the configured Type in the Validation Rules table.

- Apply the query validation rule for that tracker to the Bug query value
- Apply the state transition format check to the State transitions value
- Apply the instance validation rule (if any) to the Instance value
- For unknown Type → [WARN] "Unknown tracker type '{Type}'. Validation skipped."
```

**Step 2: Replace Step 7 MCP server detection inline lines**

In `commands/check-setup.md`, replace lines 76-80 (the 5 tracker-specific bullets under "Issue tracker MCP") with:

```markdown
   - Issue tracker MCP: read the MCP Server Detection table from `docs/reference/trackers.md`.
     Find the row matching Type. Search .mcp.json server names/URLs for the listed keywords.
```

Keep the surrounding lines 75, 81-83 unchanged.

**Step 3: Commit**

```bash
git add commands/check-setup.md
git commit -m "refactor: check-setup references trackers.md instead of inline blocks"
```

---

### Task 3: Refactor `commands/onboard.md`

**Files:**
- Modify: `commands/onboard.md:51-90` (Step 2 per-tracker defaults)
- Modify: `commands/onboard.md:123-127` (Step 4b PR footers)

**Step 1: Replace Step 2 inline per-tracker defaults**

In `commands/onboard.md`, replace lines 51-90 (from `1. Which issue tracker` through `gitea: add label:in-progress`) with:

```markdown
1. Which issue tracker do you use? (youtrack / github / jira / linear / gitea / redmine)
2. Instance URL — read defaults from `docs/reference/trackers.md` Instance & Project Defaults table
3. Project name / key — read format from the same table
4. Bug query — read defaults from `docs/reference/trackers.md` Query Syntax table, substitute the project name
5. **Feature query** — "Do you also want to configure a feature query for `/implement-feature`?"
   If yes, read defaults from `docs/reference/trackers.md` Query Syntax table (Feature query format column).
   If user provides a Feature query → auto-include `### Feature Workflow` section in output. The Feature query key is always emitted in the `### Feature Workflow` section (where `/implement-feature` reads it from).
   If user declines → no Feature query in output.
6. State transitions — read defaults from `docs/reference/trackers.md` State Transition Syntax table. Compose the full value using comma separator: `In Progress: {format}, Blocked: {format}, For Review: {format}, Done: {format}`
7. On start set — read defaults from `docs/reference/trackers.md` On Start Set Defaults table
```

**Step 2: Replace Step 4b inline per-tracker footers**

In `commands/onboard.md`, replace lines 123-127 (from `- GitHub: Closes` through `- Linear: {issue_id}`) with:

```markdown
   Tracker-specific footers — read from `docs/reference/trackers.md` PR Description Footer table.
```

Keep the surrounding context (lines 118-122 and 128+) unchanged.

**Step 3: Commit**

```bash
git add commands/onboard.md
git commit -m "refactor: onboard references trackers.md instead of inline defaults"
```

---

### Task 4: Update `CLAUDE.md` Config Contract

**Files:**
- Modify: `CLAUDE.md:104`

**Step 1: Add `redmine` to allowed types**

In `CLAUDE.md` line 104, change:

```
youtrack/github/jira/linear/gitea, default: youtrack
```

to:

```
youtrack/github/jira/linear/gitea/redmine, default: youtrack
```

**Step 2: Commit**

```bash
git add CLAUDE.md
git commit -m "feat: add redmine to Config Contract allowed tracker types"
```

---

### Task 5: Update `docs/reference/automation-config.md`

**Files:**
- Modify: `docs/reference/automation-config.md:43` (Type description)
- Modify: `docs/reference/automation-config.md:82` (after Gitea example, add Redmine example)

**Step 1: Add `redmine` to Type key description**

On line 43, change:

```
| Type | Tracker type: `youtrack`, `github`, `jira`, `linear`, `gitea` (default: `youtrack`) |
```

to:

```
| Type | Tracker type: `youtrack`, `github`, `jira`, `linear`, `gitea`, `redmine` (default: `youtrack`) |
```

**Step 2: Add Redmine example after Gitea example**

After line 82 (end of Gitea example), insert:

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

**Step 3: Commit**

```bash
git add docs/reference/automation-config.md
git commit -m "feat: add Redmine example to automation-config reference"
```

---

### Task 6: Update `docs/guides/mcp-configuration.md`

**Files:**
- Modify: `docs/guides/mcp-configuration.md` (add section before "Verifying the Entire Setup")

**Step 1: Add Redmine MCP server section**

Before the `## Verifying the Entire Setup` section (line 111), insert:

```markdown
## Redmine MCP server

- **Package:** `mcp-server-redmine` (npm)
- **Source:** [github.com/yonaka15/mcp-server-redmine](https://github.com/yonaka15/mcp-server-redmine)
- **Launch:** `npx -y --prefix /path/to/mcp-server-redmine mcp-server-redmine`
- **Env variables:** `REDMINE_HOST`, `REDMINE_API_KEY`
- **Config:**
```json
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
```

Replace `/path/to/mcp-server-redmine` with the actual installation directory (e.g., `~/.mcp/mcp-server-redmine`).

- **Verification:** In Claude Code, ask about an existing Redmine issue. If you see issue data, the MCP server is working.

```

**Step 2: Commit**

```bash
git add docs/guides/mcp-configuration.md
git commit -m "feat: add Redmine MCP server section to mcp-configuration guide"
```

---

### Task 7: Update `docs/guides/tokens.md`

**Files:**
- Modify: `docs/guides/tokens.md:7-13` (overview table)
- Modify: `docs/guides/tokens.md` (add section after Linear API Key, before Token Security)

**Step 1: Add Redmine row to overview table**

After the Linear row (line 13), add:

```
| Redmine API key | Issue tracker | `mcp-server-redmine` |
```

**Step 2: Add Redmine API Key section**

After the `## Linear API Key` section (after line 55) and before `## Token Security` (line 57), insert:

```markdown
## Redmine API Key

1. Open Redmine → **My account** (top right)
2. In the right sidebar: **API access key → Show**
3. If no key exists, click **Reset** to generate one
4. Copy the key
5. Alternative: Admin can generate keys via Administration → Users → {user} → API access key

Note: Redmine API key provides full access to whatever the user can access in the UI. There are no scoped tokens in Redmine.

```

**Step 3: Commit**

```bash
git add docs/guides/tokens.md
git commit -m "feat: add Redmine API key section to tokens guide"
```

---

### Task 8: Create `examples/configs/redmine-rails.md`

**Files:**
- Create: `examples/configs/redmine-rails.md`

**Step 1: Create example config file**

Create `examples/configs/redmine-rails.md` with:

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

**Step 2: Commit**

```bash
git add examples/configs/redmine-rails.md
git commit -m "feat: add Redmine + Rails example config template"
```

---

### Task 9: Update `commands/template.md`

**Files:**
- Modify: `commands/template.md:30` (template table)

**Step 1: Add Redmine row to template table**

After line 30 (`| youtrack-python | Python | YouTrack |`), add:

```
| redmine-rails | Ruby on Rails | Redmine |
```

**Step 2: Commit**

```bash
git add commands/template.md
git commit -m "feat: add redmine-rails to template catalog"
```

---

### Task 10: Update documentation — tracker lists and counts

**Files:**
- Modify: `README.md:21` (mermaid diagram)
- Modify: `README.md:228` ("5 supported" → "6 supported")
- Modify: `docs/getting-started.md:14-19` (tracker bullet list)
- Modify: `docs/getting-started.md:44` (inline tracker list)
- Modify: `docs/architecture.md:36` (mermaid diagram)
- Modify: `docs/reference/commands.md:330` ("5 tracker types" → "6 tracker types")

**Step 1: Update `README.md` mermaid diagram**

On line 21, change:

```
        Tracker["Issue Tracker<br/>GitHub · Gitea · YouTrack · Jira · Linear"]
```

to:

```
        Tracker["Issue Tracker<br/>GitHub · Gitea · YouTrack · Jira · Linear · Redmine"]
```

**Step 2: Update `README.md` supported count**

On line 228, change:

```
| [Tokens](docs/guides/tokens.md) | API token generation for all 5 supported trackers |
```

to:

```
| [Tokens](docs/guides/tokens.md) | API token generation for all 6 supported trackers |
```

**Step 3: Update `docs/getting-started.md` bullet list**

After line 19 (`  - Gitea`), add:

```
  - Redmine
```

**Step 4: Update `docs/getting-started.md` inline list**

On line 44, change:

```
1. **Issue tracker type** — Select your tracker (youtrack, github, jira, linear, or gitea)
```

to:

```
1. **Issue tracker type** — Select your tracker (youtrack, github, jira, linear, gitea, or redmine)
```

**Step 5: Update `docs/architecture.md` mermaid diagram**

On line 36, change:

```
    ISSUE_TRACKER["Issue Tracker<br/>(YouTrack / GitHub / Jira /<br/>Linear / Gitea)"]
```

to:

```
    ISSUE_TRACKER["Issue Tracker<br/>(YouTrack / GitHub / Jira /<br/>Linear / Gitea / Redmine)"]
```

**Step 6: Update `docs/reference/commands.md` tracker count**

On line 330, change:

```
Supports all 5 tracker types (YouTrack, GitHub, Jira, Linear, Gitea).
```

to:

```
Supports all 6 tracker types (YouTrack, GitHub, Jira, Linear, Gitea, Redmine).
```

**Step 7: Commit**

```bash
git add README.md docs/getting-started.md docs/architecture.md docs/reference/commands.md
git commit -m "docs: update tracker lists and counts to include Redmine"
```

---

### Task 11: Update design doc status

**Files:**
- Modify: `docs/plans/2026-03-03-redmine-tracker-support-design.md:5`

**Step 1: Mark design as implemented**

On line 5, change:

```
**Status:** Draft
```

to:

```
**Status:** Implemented
```

**Step 2: Commit**

```bash
git add docs/plans/2026-03-03-redmine-tracker-support-design.md
git commit -m "docs: mark Redmine design as implemented"
```

---

### Task 12: Final verification

**Files:** (read-only — no modifications)

**Step 1: Verify all tracker-type references include `redmine`**

Run:

```bash
grep -rn "youtrack/github/jira/linear/gitea" --include="*.md" | grep -v "docs/plans/"
```

Expected: Zero results (all non-plan files should now list `redmine` too).

**Step 2: Verify no "5 supported" / "5 tracker" references remain**

Run:

```bash
grep -rn "5 supported\|5 tracker" --include="*.md" | grep -v "docs/plans/" | grep -v "CHANGELOG"
```

Expected: Zero results.

**Step 3: Verify file existence**

Run:

```bash
ls docs/reference/trackers.md examples/configs/redmine-rails.md
```

Expected: Both files exist.

**Step 4: Verify check-setup.md no longer has inline per-tracker blocks**

Run:

```bash
grep -c "YouTrack (Type = youtrack)" commands/check-setup.md
```

Expected: `0`

**Step 5: Verify onboard.md no longer has inline per-tracker defaults**

Run:

```bash
grep -c "youtrack:.*youtrack.cloud" commands/onboard.md
```

Expected: `0`
