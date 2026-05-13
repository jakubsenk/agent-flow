# Research Question 5: Backward Compatibility Surface

## Refined Question

What is the complete public API surface of ceos-agents v5.1.0 that external users depend on, and what are the exact breaking-change boundaries that must be preserved (or explicitly versioned) during any migration, refactoring, or platform change?

---

## Complete Public API Inventory

### Commands (24)

| Name | Full Namespaced Invocation | Category | Description | Flags / Args |
|------|--------------------------|----------|-------------|--------------|
| analyze-bug | `/ceos-agents:analyze-bug` | Bug-Fix | Read-only bug analysis (no code changes) | `<ISSUE-ID>` |
| fix-ticket | `/ceos-agents:fix-ticket` | Bug-Fix | Full bug-fix pipeline, single ticket, CWD | `<ISSUE-ID> [--dry-run] [--decompose\|--no-decompose] [--profile <name>] [--yolo]` |
| fix-bugs | `/ceos-agents:fix-bugs` | Bug-Fix | Batch bug-fix, N tickets, optional worktrees | `<N> [--dry-run] [--decompose\|--no-decompose] [--profile <name>]` |
| resume-ticket | `/ceos-agents:resume-ticket` | Bug-Fix | Resume pipeline from last `[ceos-agents]` checkpoint | `<ISSUE-ID>` |
| implement-feature | `/ceos-agents:implement-feature` | Feature | Full feature pipeline | `<ISSUE-ID> [--dry-run] [--decompose\|--no-decompose] [--profile <name>] [--yolo]` |
| scaffold | `/ceos-agents:scaffold` | Scaffold | New project from scratch (v2 default) or skeleton-only (--no-implement) | `<description> [--template <path>] [--spec <path>] [--issue <ID>] [--no-implement] [--lang] [--framework] [--db] [--ci] [--brainstorm]` |
| scaffold-add | `/ceos-agents:scaffold-add` | Scaffold | Add component to existing project | `<claude-md\|ci\|docker\|tests>` |
| scaffold-validate | `/ceos-agents:scaffold-validate` | Scaffold | Validate project build/test/lint | `[path]` |
| create-pr | `/ceos-agents:create-pr` | Publishing | Lightweight PR creation, no publisher agent | (none) |
| publish | `/ceos-agents:publish` | Publishing | Full PR + issue tracker update via publisher agent | (none) |
| onboard | `/ceos-agents:onboard` | Config | Interactive Automation Config wizard | `[--fresh\|--update]` |
| init | `/ceos-agents:init` | Config | Developer environment setup (MCP, tokens, permissions) | `[--update]` |
| check-setup | `/ceos-agents:check-setup` | Config | Validate config, MCP, connectivity | `[--skip-build]` |
| migrate-config | `/ceos-agents:migrate-config` | Config | Detect and upgrade config version | (none) |
| template | `/ceos-agents:template` | Config | Generate Automation Config template for a stack | `<list\|name>` |
| status | `/ceos-agents:status` | Monitoring | Overview of in-progress issues with recommended next steps | (none) |
| dashboard | `/ceos-agents:dashboard` | Monitoring | HTML pipeline dashboard | `[--days <N>] [--output <path>] [--state <filter>] [--stage <filter>]` |
| metrics | `/ceos-agents:metrics` | Monitoring | Pipeline analytics report | `[--period <N>] [--output <path>] [--format <md\|json>]` |
| estimate | `/ceos-agents:estimate` | Planning | Token/cost estimate before pipeline run | `<ISSUE-ID> [--profile <name>]` |
| prioritize | `/ceos-agents:prioritize` | Planning | AI backlog prioritization | `[--limit <N>] [--output <path>]` |
| version-bump | `/ceos-agents:version-bump` | Versioning | Bump plugin version in plugin.json + marketplace.json | `[patch\|minor\|major]` |
| version-check | `/ceos-agents:version-check` | Versioning | Compare installed vs latest version | (none) |
| changelog | `/ceos-agents:changelog` | Versioning | Generate CHANGELOG.md from merged PRs | (none) |
| discuss | `/ceos-agents:discuss` | Planning | Multi-agent discussion on a topic (read-only) | `<topic>` |

**Namespace:** All commands use the `ceos-agents:` prefix. This prefix is machine-parsed by the skill router and is itself part of the public API. Changing it is a breaking change with no migration path.

**Note:** The commands reference in `docs/reference/commands.md` lists 23 commands (the `discuss` command is not listed there but is present in the `commands/` directory and in `CLAUDE.md`). The actual count is 24.

---

### Skills (1)

| Name | Trigger | Description | Routing Target |
|------|---------|-------------|----------------|
| bug-workflow | Natural language intent matching | Routes natural language to appropriate command | All 23 commands (excludes `discuss` from intent table) |

**Full invocation:** `ceos-agents:bug-workflow` (skill namespace mirrors command namespace)

**Intent triggers mapped in skill:**
- "Analyze/describe a bug" → `analyze-bug`
- "Fix a specific bug/ticket" → `fix-ticket`
- "Fix multiple bugs" → `fix-bugs`
- "Create a pull request" → `create-pr`
- "Publish (PR + issue state)" → `publish`
- "Resume/continue a pipeline" → `resume-ticket`
- "Show status/overview" → `status`
- "Setup/onboard a project" → `onboard`
- "Configure MCP/tokens/permissions" → `init`
- "Generate changelog" → `changelog`
- "Check plugin version" → `version-check`
- "Validate config/setup" → `check-setup`
- "Bump plugin version" → `version-bump`
- "Dry run / simulate" → `fix-bugs --dry-run`
- "Scaffold new project" → `scaffold`
- "Add component to project" → `scaffold-add`
- "Validate project" → `scaffold-validate`
- "Implement a feature" → `implement-feature`
- "Show dashboard" → `dashboard`
- "View pipeline metrics/analytics" → `metrics`
- "Estimate cost/tokens for an issue" → `estimate`
- "Prioritize backlog / suggest fix order" → `prioritize`
- "Upgrade/migrate config" → `migrate-config`
- "Generate config template" → `template`

---

### Agents (18)

| Name | Model | Type | Pipeline(s) | Referenced by Commands |
|------|-------|------|-------------|----------------------|
| triage-analyst | sonnet | Read-only | Bug-fix | fix-ticket, fix-bugs, analyze-bug, resume-ticket |
| code-analyst | sonnet | Read-only | Bug-fix | fix-ticket, fix-bugs, analyze-bug, resume-ticket |
| reviewer | opus | Read-only | Bug-fix, Feature | fix-ticket, fix-bugs, implement-feature, scaffold |
| spec-analyst | sonnet | Read-only | Feature | implement-feature, resume-ticket |
| architect | opus | Read-only | Feature, Bug-fix (decomposition) | fix-ticket, fix-bugs, implement-feature, scaffold |
| stack-selector | sonnet | Read-only | Scaffold | scaffold (--no-implement mode) |
| priority-engine | opus | Read-only | Standalone | prioritize |
| spec-reviewer | opus | Read-only | Scaffold v2 | scaffold |
| acceptance-gate | sonnet | Read-only | Bug-fix (conditional), Feature (always) | fix-ticket, fix-bugs, implement-feature |
| fixer | opus | Execution | Bug-fix, Feature, Scaffold | fix-ticket, fix-bugs, implement-feature, scaffold |
| spec-writer | opus | Execution | Scaffold v2 | scaffold |
| test-engineer | sonnet | Execution | Bug-fix, Feature, Scaffold | fix-ticket, fix-bugs, implement-feature, scaffold |
| e2e-test-engineer | sonnet | Execution | Bug-fix (optional), Feature (optional), Scaffold | fix-ticket, fix-bugs, implement-feature, scaffold |
| reproducer | sonnet | Execution | Bug-fix (optional, browser verification) | fix-ticket, fix-bugs |
| browser-verifier | sonnet | Execution | Bug-fix (optional, browser verification) | fix-ticket, fix-bugs |
| publisher | haiku | Execution | Bug-fix, Feature | fix-ticket, fix-bugs, implement-feature, publish |
| scaffolder | sonnet | Execution | Scaffold | scaffold, scaffold-add |
| rollback-agent | haiku | Execution | Bug-fix, Feature (triggered on block) | fix-ticket, fix-bugs, implement-feature, scaffold |

**Agent Override path contract:** Agent names are referenced as file basenames in `{Agent Overrides path}/{agent-name}.md`. Renaming an agent is a breaking change for any project using Agent Overrides customization.

---

### Config Keys

#### Required Sections (5)

**Issue Tracker**

| Key | Required/Optional | Type | Notes |
|-----|------------------|------|-------|
| Type | Required | Enum: `youtrack`, `github`, `jira`, `linear`, `gitea`, `redmine` | Default: `youtrack` |
| Instance | Required | URL string | Tracker instance URL |
| Project | Required | String | Project identifier |
| Bug query | Required | String | Tracker-specific query syntax |
| State transitions | Required | String | Tracker-specific state mapping |
| On start set | Required | String | State to set when pipeline starts |

**Source Control**

| Key | Required/Optional | Type | Notes |
|-----|------------------|------|-------|
| Remote | Required | String `owner/repo` | Git remote |
| Base branch | Required | String | e.g., `main` |
| Branch naming | Required | String with `{issue-id}` and `{description}` placeholders | e.g., `fix/{issue-id}-{description}` |

**PR Rules**

| Key | Required/Optional | Type | Notes |
|-----|------------------|------|-------|
| Labels | Required | Comma-separated string | PR labels |

**PR Description Template**

| Key | Required/Optional | Type | Notes |
|-----|------------------|------|-------|
| (subsection content) | Required | Multi-line markdown template | Uses `{summary}`, `{root_cause}`, `{changes}`, `{testing}`, `{issue_link}` placeholders |

**Build & Test**

| Key | Required/Optional | Type | Notes |
|-----|------------------|------|-------|
| Build command | Required | Shell command string | |
| Test command | Required | Shell command string | |
| Verify command | Optional | Shell command string | Runs post-merge; re-opens issue on failure |

#### Optional Sections (13)

**Retry Limits**

| Key | Required/Optional | Default | Type |
|-----|------------------|---------|------|
| Fixer iterations | Optional | `5` | Integer |
| Test attempts | Optional | `3` | Integer |
| Build retries | Optional | `3` | Integer |
| Spec iterations | Optional | `5` | Integer |

**Hooks**

| Key | Required/Optional | Default | Type |
|-----|------------------|---------|------|
| Pre-fix | Optional | (none) | Shell command |
| Post-fix | Optional | (none) | Shell command |
| Pre-publish | Optional | (none) | Shell command |
| Post-publish | Optional | (none) | Shell command |

**Custom Agents**

| Key | Required/Optional | Default | Type |
|-----|------------------|---------|------|
| Post-fix agent | Optional | (none) | File path to agent `.md` |
| Pre-publish agent | Optional | (none) | File path to agent `.md` |

**Notifications**

| Key | Required/Optional | Default | Type |
|-----|------------------|---------|------|
| Webhook URL | Optional | (none) | URL |
| On events | Optional | (none) | Comma-separated: `pr-created`, `issue-blocked`, `pipeline-complete` |

**Worktrees**

| Key | Required/Optional | Default | Type |
|-----|------------------|---------|------|
| Batch size | Optional | `3` | Integer |
| Base path | Optional | `.worktrees/` | Directory path |
| Cleanup | Optional | `auto` | Enum: `auto`, `manual` |

**E2E Test**

| Key | Required/Optional | Default | Type |
|-----|------------------|---------|------|
| Framework | Optional | (none) | String (e.g., `playwright`, `cypress`) |
| Command | Optional | (none) | Shell command |

**Browser Verification** (added v5.1.0)

| Key | Required/Optional | Default | Type |
|-----|------------------|---------|------|
| Base URL | Required if section present | (none) | URL |
| Start command | Optional | (none) | Shell command |
| On events | Optional | `reproduce, verify` | Comma-separated: `reproduce`, `verify` |
| Timeout | Optional | `60` | Integer (seconds) |
| Max pages | Optional | `5` | Integer |
| Screenshot storage | Optional | `.claude/screenshots` | Directory path |
| Exploration | Optional | `disabled` | Enum: `enabled`, `disabled` |
| Exploration max clicks | Optional | `20` | Integer |

**Error Handling**

| Key | Required/Optional | Default | Type |
|-----|------------------|---------|------|
| On block | Optional | `comment` | Enum: `comment`, `close` |
| Max blocked per run | Optional | `unlimited` | Integer or `unlimited` |

**Extra labels**

| Key | Required/Optional | Default | Type |
|-----|------------------|---------|------|
| Labels | Optional | (none) | Comma-separated string |

**Feature Workflow**

| Key | Required/Optional | Default | Type |
|-----|------------------|---------|------|
| Feature query | Optional | (none) | String (tracker query) |
| On start set | Optional | (none) | String (state to set) |

**Decomposition**

| Key | Required/Optional | Default | Type |
|-----|------------------|---------|------|
| Max subtasks | Optional | `7` | Integer |
| Fail strategy | Optional | `fail-fast` | Enum: `fail-fast`, `continue` |
| Commit strategy | Optional | `squash` | Enum: `squash`, `individual` |

**Pipeline Profiles**

| Key | Required/Optional | Type | Notes |
|-----|------------------|------|-------|
| Profile | Optional | String (profile name) | |
| Skip stages | Optional | Comma-separated stage names | Skippable: `triage`, `code-analyst`, `spec-analyst`, `test-engineer`, `e2e-test-engineer`, `reproducer`, `browser-verifier` |
| Extra stages | Optional | Comma-separated stage names | |

**Metrics**

| Key | Required/Optional | Default | Type |
|-----|------------------|---------|------|
| Output | Optional | `stdout` | String (path or `stdout`) |
| Period | Optional | `30 days` | String |

**Agent Overrides**

| Key | Required/Optional | Default | Type |
|-----|------------------|---------|------|
| Path | Optional | `customization/` | Directory path |

---

### Structured Output Formats

These formats are machine-parsed by commands (`/resume-ticket`, `/dashboard`, `/metrics`) by scanning issue tracker comments. They constitute a stable output contract.

#### Block Comment Template

Posted by any blocking agent to the issue tracker. The `[ceos-agents]` prefix is the machine-readable anchor.

```
[ceos-agents] 🔴 Pipeline Block
Agent: {agent name}
Step: {pipeline step where failure occurred}
Reason: {max 2 sentences}
Detail: {technical output — error message, diff, test output}
Recommendation: {what the human should do}
```

**Fields used by `/resume-ticket`:** prefix `[ceos-agents]`, keyword `Pipeline Block`
**Fields used by `/dashboard` and `/metrics`:** prefix `[ceos-agents]`, `Agent:`, `Step:`, `Reason:`

**Legacy prefix:** `[CLAUDE-agents]` (from pre-v3.4.0, accepted by `resume-ticket` for backward compatibility)

#### Triage Checkpoint Comment

Posted by `triage-analyst` after successful triage.

```
[ceos-agents] Triage completed. Severity: {severity}. Area: {area}. Complexity: {complexity}. AC: {count}.
```

**Breaking change in v5.0.0:** Added `Complexity: {c}. AC: {n}.` fields. Prior format: `[ceos-agents] Triage completed. Severity: {s}. Area: {a}.`

**Fields used by `/resume-ticket`:** prefix `[ceos-agents]`, keyword `Triage completed` → indicates triage stage is done, resume from code-analyst

#### Spec Analysis Checkpoint Comment

Posted by `spec-analyst` after successful spec analysis.

```
[ceos-agents] Spec analysis completed. Area: {area}. Criteria: {count}.
```

**Fields used by `/resume-ticket`:** prefix `[ceos-agents]`, keyword `Spec analysis completed` → indicates spec-analyst is done, resume from architect

#### Reviewer AC Fulfillment Section

Posted by `reviewer` in its review output when AC are provided (added v5.0.0).

```
## AC Fulfillment
- AC-1: {text} — FULFILLED / PARTIALLY / NOT ADDRESSED
- AC-2: {text} — FULFILLED / PARTIALLY / NOT ADDRESSED
...
```

#### Acceptance Gate Report

Posted by `acceptance-gate` agent.

```
## Acceptance Gate Report
- **Verdict:** APPROVE / REQUEST_CHANGES
- **AC:** {n}/{total} fulfilled, {p} partial, {m} not addressed
- **Details:**
  1. {AC text} → {verdict} — {file:line}, {test}
- **Summary:** {text}
```

#### Architect Task Tree YAML

Saved to `.claude/decomposition/{ISSUE-ID}.yaml` for resume support.

```yaml
decomposition:
  strategy: sequential | parallel
  reason: "{text}"
  subtasks:
    - id: "sub-{N}"
      title: "{text}"
      scope: "{text}"
      files: [...]
      estimated_lines: {N}
      depends_on: [...]
      acceptance_criteria: [...]
      maps_to: "AC-{N}: {text}"   # added v5.0.0
```

**`maps_to` field:** Added in v5.0.0. Format `AC-{N}: {text}` is parsed by commands for AC coverage check.

#### Browser Verification Evidence Files

Written to filesystem by `reproducer` and `browser-verifier` agents.

- `.claude/reproduction-result.json` — structured evidence bundle from reproducer
- `.claude/verification-result.json` — structured verification result from browser-verifier

Format: JSON with `verdict` field (`VERIFIED`/`PARTIAL`/`FAILED`/`SKIPPED`).

---

### Versioning Contract

Defined in `CLAUDE.md` and `CHANGELOG.md`:

| Bump Level | Triggers | Examples |
|-----------|----------|---------|
| MAJOR (X.0.0) | Breaking change in Automation Config contract (new required key, renamed section) OR breaking change in agent output format contract (new/modified structured output sections that Agent Overrides or external tooling may parse) | New required key in Issue Tracker; triage checkpoint format change (v5.0.0); plugin rename CLAUDE-agents→ceos-agents (v3.4.0) |
| MINOR (X.Y.0) | New backward-compatible feature — new optional key, new command/agent | `/version-check` command (v3.x); Browser Verification section (v5.1.0); new `discuss` command (v4.1.0) |
| PATCH (X.Y.Z) | Behavior fix without contract change | Agent text fix, command logic fix, doc corrections |

**Key rule:** Adding a **required** key to Automation Config = MAJOR. Adding an **optional** section = MINOR.

**Extended rule (since v5.0.0):** Breaking changes to structured output formats (Block Comment Template fields, checkpoint comment format, reviewer AC Fulfillment section, architect `maps_to` format) also trigger MAJOR.

---

## Deprecation Risks

### If Command Names Change

- **Direct impact:** Users who invoke commands by name in scripts, CI pipelines, or documentation references will break immediately.
- **Skill router impact:** `skills/bug-workflow/skill.md` hardcodes all 23+ command names with the `ceos-agents:` prefix. Any rename requires updating the skill's intent table.
- **Resume-ticket impact:** `resume-ticket` routes based on checkpoint comment type. If commands change behavior or checkpoint format, detection logic breaks.

### If Agent Names Change

- **Agent Overrides:** Projects with `customization/{agent-name}.md` files will silently stop receiving their customizations (files are ignored if name doesn't match). No error, silent failure.
- **Pipeline profiles:** Stage names in `Skip stages` and `Extra stages` keys reference agent identifiers (`triage`, `code-analyst`, etc.). A rename invalidates existing profile configurations.
- **`/discuss` command:** Dispatches agents by name — a rename breaks multi-agent discussion sessions.

### If Config Keys Change (Required Section Keys)

- **Immediate breakage:** `check-setup` validation will fail, and all pipeline commands will read wrong values or halt on missing keys.
- **`migrate-config` dependency:** The migration command detects config version by presence/absence of specific key names. If keys are renamed without updating `migrate-config`, version detection fails.

### If Config Section Names Change

- Same as key changes, plus `check-setup` section-presence validation breaks.
- The `/onboard` wizard and `/template` command generate config with specific section names — old generated configs won't be recognized by commands after rename.

### If Structured Output Formats Change (Block Comment, Checkpoint Comments)

- **`/resume-ticket`:** Detects pipeline stage by scanning for `[ceos-agents] Triage completed` and `[ceos-agents] Spec analysis completed` text patterns. Any format change means existing blocked tickets cannot be resumed automatically.
- **`/dashboard` and `/metrics`:** Parse `[ceos-agents]` prefixed comments from issue tracker history. Format changes cause incorrect parsing, wrong statistics, and missing blocked issues in dashboard.
- **External tooling:** Any organization that has built automation on top of these comment formats (e.g., custom dashboards, Slack bots, CI hooks) breaks silently.

### If the `ceos-agents:` Namespace Prefix Changes

- All 24 command invocations across user scripts, documentation, and the skill router break.
- The `[ceos-agents]` comment prefix in issue trackers would create a namespace collision or require dual-prefix support.
- Historical comments in issue trackers (already posted with `[ceos-agents]` prefix) become orphaned — `resume-ticket` and `dashboard` cannot parse them correctly.

### If the `spec/` Folder Convention Changes

- Scaffold v2 pipeline: `scaffolder` reads tech stack from `spec/README.md`. Renaming this path breaks scaffold.
- `spec-reviewer --verify` mode reads the entire `spec/` tree. Path changes break spec compliance checks.
- Users who have already scaffolded projects have `spec/` in their repository — a convention change would require manual migration.

### If `.claude/decomposition/{ISSUE-ID}.yaml` Path or Format Changes

- `resume-ticket` uses this file to reconstruct decomposition state. Path or format change means mid-decomposition issues cannot be resumed.

---

## Files Examined

- `C:/gitea_ceos-agents/CLAUDE.md` — canonical config contract, versioning policy, block comment template, architecture overview
- `C:/gitea_ceos-agents/.claude-plugin/plugin.json` — plugin identity (name: `ceos-agents`, version: `5.1.0`)
- `C:/gitea_ceos-agents/.claude-plugin/marketplace.json` — marketplace registration
- `C:/gitea_ceos-agents/skills/bug-workflow/skill.md` — skill definition, full intent-to-command routing table
- `C:/gitea_ceos-agents/docs/reference/commands.md` — full command reference (23 entries; 24th is `discuss`)
- `C:/gitea_ceos-agents/docs/reference/agents.md` — full agent reference with example outputs
- `C:/gitea_ceos-agents/docs/reference/automation-config.md` — complete config section reference
- `C:/gitea_ceos-agents/docs/reference/pipelines.md` — pipeline diagrams, stage tables, error handling, block comment format variant
- `C:/gitea_ceos-agents/docs/reference/execution-loop.md` — canonical fixer/reviewer/test-engineer loop, block handler format
- `C:/gitea_ceos-agents/docs/reference/trackers.md` — tracker-specific values (query syntax, state transitions, MCP detection)
- `C:/gitea_ceos-agents/docs/guides/installation.md` — installation procedure, plugin update mechanism
- `C:/gitea_ceos-agents/CHANGELOG.md` — complete version history, breaking changes, MAJOR/MINOR/PATCH examples

---

## Migration Risks

### High Risk: Command Namespace

The `ceos-agents:` prefix appears in:
1. All 24 command file invocations
2. The skill router (hardcoded in every row of the intent table)
3. User scripts, CI pipelines, documentation
4. The `[ceos-agents]` issue tracker comment prefix (separate concern but shares the name)

Any migration that changes the plugin name or namespace prefix requires a coordinated update across all four surfaces simultaneously, with no graceful fallback for already-posted comments.

### High Risk: Issue Tracker Comment Formats

The `[ceos-agents]` prefix and checkpoint comment formats are the only machine-readable state tracking mechanism. They are written to external systems (issue trackers) that ceos-agents does not control. Once comments are posted, they cannot be retroactively updated. A format change creates a split-brain state: old tickets have old-format comments, new tickets have new-format comments, and `resume-ticket`/`dashboard`/`metrics` must handle both.

The legacy prefix `[CLAUDE-agents]` (pre-v3.4.0) demonstrates this problem is already known — `resume-ticket` explicitly accepts both prefixes.

### High Risk: Agent Override File Naming

The Agent Override mechanism relies on filename matching by agent name. Projects using customization files have no runtime error if a name changes — customizations silently stop applying. There is no validation in `check-setup` for this (it only checks Automation Config sections, not the customization directory contents).

### Medium Risk: Pipeline Profile Stage Names

Stage names used in `Skip stages` are agent identifiers (`triage`, `code-analyst`, `spec-analyst`, etc.), not display names. These are stored in the consuming project's CLAUDE.md config. Adding new skippable stages (e.g., `reproducer`, `browser-verifier` added in v5.1.0) is backward compatible. Renaming existing stage identifiers breaks existing profile configurations in all consuming projects simultaneously.

### Medium Risk: `--no-implement` Flag Backward Compatibility

The `--no-implement` flag preserves the pre-v4.0.0 scaffold behavior. Its existence as a named flag is a public API commitment. Removing it forces all users who relied on the simple skeleton workflow to change their usage. The flag was explicitly added as a compatibility shim in v4.0.0 and should be treated as a long-term commitment.

### Low Risk: Spec Folder Structure

The `spec/` folder structure (README.md, architecture.md, verification.md, epics/*.md) is written to the consuming project's repository. Changing the expected structure in downstream agents (scaffolder, spec-reviewer, architect) creates an incompatibility for projects already scaffolded with v4.x or v5.x where a `spec/` folder exists.

### Low Risk: `.claude/` Directory Artifacts

Files written to `.claude/` (decomposition YAML, reproduction-result.json, verification-result.json, screenshots) accumulate across pipeline runs. The recommended `.gitignore` entries in the config reference document show these are expected to be excluded. However, the paths are referenced by name in agent definitions — path changes require updating both agents and documentation simultaneously.
