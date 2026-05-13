# Onboard Wizard Redesign — Design Document

**Date:** 2026-03-02
**Status:** Approved
**Scope:** Rewrite `commands/onboard.md` to support update mode, bundles, feature workflow, and strict English output

## Problem Statement

The current `/onboard` wizard has 7 identified issues from real-world usage:

1. No detection of existing config — blindly generates new config, may overwrite customizations
2. No re-runnability — cannot pre-fill answers from existing config
3. Language mixing — Czech prose ended up in machine-readable config (BIFITO project)
4. Missing feature workflow — no Feature query or feature-specific pipeline config
5. Tedious optional sections UX — 12 individual yes/no questions
6. Pipeline Profiles not prominent enough
7. PR Description Template has no preview or inline editing

Additionally discovered: 3 optional sections missing from the wizard entirely (Feature Workflow, Decomposition, Metrics).

## Design Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Architecture | Single command, two modes (fresh + update) | Fresh and update share 80% of logic |
| migrate-config interaction | Smart routing (detect → suggest migrate-config → continue) | Keeps single responsibility, both commands useful independently |
| Optional sections UX | Bundles + multi-select fallback | Reduces questions from 12 to 1, with full control available |
| PR Description Template | Auto-generate per tracker + preview + inline edit | Minimal questions, best defaults |
| Feature query placement | Asked in Issue Tracker step, emitted in Feature Workflow section | UX improvement — asked where natural, stored where consumers expect |
| Language | All wizard text and output in English | Plugin is fully English since v3.2.0 |
| Update mode UX | Section-by-section with diff at the end | Balance of thorough and efficient |

## Input

`$ARGUMENTS` = (none) | `--fresh` | `--update`

- No arguments (default): auto-detect existing config and route accordingly
- `--fresh`: force fresh mode, skip config detection (useful for starting over)
- `--update`: force update mode, error if no config exists

## Cancellation Behavior

- **Fresh mode:** No side effects until Step 8 (output). Cancelling at any point before Step 8 is safe — nothing is written.
- **Update mode:** Changes are collected in memory and only written at Step U3 after explicit confirmation. Cancelling before U3 discards all changes.
- No partial state is saved between sessions. If the user stops mid-wizard, they restart from the beginning.

## Detailed Design

### Step 0: Detection and Routing

At the very beginning, before greeting:

1. Read the target project's CLAUDE.md
2. Look for `## Automation Config` section
3. Three possible states:

| State | Action |
|-------|--------|
| No config exists | Fresh mode (step 1+) |
| Config exists, current version (v3.1) | Offer: "Update existing config?" / "Start fresh (overwrites)" |
| Config exists, old version | "Detected v{X} config. Run `/migrate-config` first for structural upgrade, then return here for value adjustments." |

In update mode: parse entire existing config into key→value structure. This structure provides default values throughout the wizard.

### Step 1: Template Offer (fresh mode only)

Unchanged from current. Offer template → `/CLAUDE-agents:template list` → user selects → proceed through steps 2–5 for adjustments.

If no template → classic wizard (step 2).

### Step 2: Issue Tracker

Same step-by-step approach, same tracker-specific defaults, with two additions:

**New: Feature query** — asked right after Bug query:
- "Do you also want to configure a feature query for `/implement-feature`?"
- Default per tracker:
  - youtrack: `project: {PROJECT} Type: Feature State: Open`
  - github: `is:issue is:open label:enhancement`
  - jira: `project = {PROJECT} AND type = Story AND status = Open`
  - linear: `team:{TEAM} type:feature` (no state filter — features can be in various states)
  - gitea: `type:issues state:open label:enhancement`
- If user provides a Feature query → auto-include `### Feature Workflow` section in output (even if not explicitly selected in optional bundles). The Feature query key is always emitted in the `### Feature Workflow` section, never in Issue Tracker — this is where `implement-feature.md` reads it from.
- If user declines → no Feature query in output (implement-feature still works with manual issue ID)

**No change:** Tracker selection, Instance URL, Project, Bug query, State transitions, On start set — all same as current.

### Step 3: Source Control

Unchanged: Remote, Base branch, Branch naming.

> **Key name:** The normative reference (`automation-config.md`) and all templates use `Branch naming`. The CLAUDE.md contract says `Branch naming pattern` — this is a pre-existing inconsistency to fix separately.

### Step 4: PR Rules + PR Description Template (merged)

**4a.** Labels (same as current)

**4b.** PR Description Template — new approach:
1. Auto-generate tracker-appropriate template:
   - GitHub: `Closes #{issue_id}` footer
   - Gitea: `Fixes #{issue_number}` footer
   - YouTrack: `{issue_link}` footer
   - Jira: `{issue_key}` footer
   - Linear: `{issue_id}` footer
2. Display full template as preview
3. "Looks good? Or do you want to customize?"
4. If customize → offer to add/remove/rename sections

Default template structure (all trackers):

```
## Summary
{summary}

## Root Cause
{root_cause}

## Changes
{changes}

## Testing
{testing}

{tracker-specific footer}
```

> **Note:** The default template includes `## Root Cause`, matching the normative reference in `automation-config.md`. Some existing templates in `examples/configs/` omit Root Cause — both forms are valid. The wizard's "customize" option lets users remove it.

### Step 5: Build & Test

Key names used in generated output: `Build command`, `Test command`, `Verify command` — matching the normative spec in `automation-config.md`. Note: existing templates in `examples/configs/` use short forms (`Build`, `Test`). Templates should be updated for consistency (see Files to Change).

Same as current, plus:
- **Verify command** (optional): "Do you have a post-merge verification command? (e.g., integration tests, smoke tests)"
  Generated key: `| Verify command | {value} |`

### Step 6: Optional Sections (bundle UX)

**6a. Bundle selection:**

```
Which optional sections do you want to configure?

  [1] standard (recommended) — Retry Limits, Error Handling, Pipeline Profiles, Feature Workflow
  [2] full — all 12 optional sections
  [3] minimal — Retry Limits only
  [4] custom — choose from the list
```

**6b. Custom multi-select** (if option 4):

```
Select sections to configure (comma-separated numbers):

  [ 1] Retry Limits — max fixer/test/build retries
  [ 2] Error Handling — behavior on pipeline block
  [ 3] Pipeline Profiles — skip/add pipeline stages per task type
  [ 4] Feature Workflow — feature-specific On start set
  [ 5] Hooks — shell commands at pipeline integration points
  [ 6] Custom Agents — custom agent files at pipeline points
  [ 7] Notifications — webhook for pipeline events
  [ 8] Worktrees — parallel bug processing via git worktrees
  [ 9] E2E Test — end-to-end testing framework
  [10] Decomposition — task decomposition for complex features
  [11] Metrics — pipeline analytics configuration
  [12] Extra labels — additional PR labels
```

Note: Feature Workflow in optional sections only covers "On start set" for features (if different from bug pipeline). Feature query is already in step 2. When asking about Feature Workflow's "On start set", show the fallback: "Feature 'On start set' (default: same as Issue Tracker '{value}' — press Enter to keep)." This matches the fallback documented in `implement-feature.md`.

**6c. Processing order:** Pipeline Profiles first (affects entire pipeline), then remaining in list order.

**6d. Pipeline Profiles — prominent handling:**
- Offer pre-built profiles with explanation:
  - `fast`: skip triage, code-analyst, test-engineer — "Quick fixes, skip analysis"
  - `strict`: extra e2e-test-engineer — "Full quality gate"
  - `minimal`: skip triage, code-analyst, test-engineer, e2e-test-engineer — "Emergency hotfixes"
- User can add custom profiles
- Display profile table as preview before confirming

**Bundle contents:**

| Bundle | Sections |
|--------|----------|
| standard | Retry Limits, Error Handling, Pipeline Profiles, Feature Workflow |
| full | All 12 optional sections |
| minimal | Retry Limits |

### Step 7: Generate Automation Config

Language rules for generated output:
1. All keys in English — exactly per `docs/reference/automation-config.md`
2. All identifier values in English (State transitions, Branch naming, Labels, Profile names)
3. User-provided values preserved as-is (URLs, project names, commands)
4. Table format always (`| Key | Value |`) — never bullet-point lists
5. PR Description Template section headings always in English

### Step 8: Output Options

**Fresh mode:**
- Option 1 (default): Print to chat
- Option 2: Write directly into CLAUDE.md (append at end)

**Update mode:**
- Display diff (before → after, only changed sections)
- Option 1 (default): Write changes to CLAUDE.md
- Option 2: Print to chat only

Safety: Never delete existing sections/keys that the wizard doesn't recognize. Preserve custom additions.

### Step 9: Closing Message

```
Automation Config generated successfully.

Next steps:
1. Run /CLAUDE-agents:check-setup to validate your configuration
2. Configure MCP servers for your issue tracker (see docs/guides/mcp-configuration.md)
3. Try /CLAUDE-agents:analyze-bug <issue-id> to test the bug pipeline
{4. Try /CLAUDE-agents:implement-feature <issue-id> to test the feature pipeline}

Note: CLAUDE-agents uses semantic versioning. See Versioning Policy in the plugin's CLAUDE.md.
```

Step 4 is only shown when Feature query was configured. The `{...}` notation indicates conditional output.

## Update Mode — Detailed Flow

**U0. Overview display:**

```
Detected existing Automation Config (v3.1):

  Issue Tracker: gitea @ gitea.internal.ceosdata.com — BIFITO
  Source Control: fsabacky/BIFITO — main
  PR Rules: Labels = ForReview
  Build & Test: dotnet build / dotnet test
  Optional: Retry Limits, Error Handling, Pipeline Profiles
  Missing optional: Feature Workflow, Hooks, Worktrees, ...

  [1] Update existing config (go through sections, change what you need)
  [2] Add missing optional sections
  [3] Start fresh (overwrites everything)
```

**U1. Section-by-section update:**
- Display current values as table
- "Any changes? (enter to keep, or type new values)"
- Skip unchanged sections quickly

**U2. Add missing sections:**
- Show only sections not yet in config
- Multi-select from the missing ones

**U3. Diff and confirm:**
- Show before/after diff for changed sections only
- Write to CLAUDE.md after confirmation

## Config Contract Impact

This redesign does NOT change the Automation Config contract:
- No new required keys
- No renamed sections
- No structural changes to the config format
- Feature query remains in the `### Feature Workflow` section (where `implement-feature.md` reads it from)
- The wizard asks about Feature query earlier (in Step 2 during Issue Tracker setup) for better UX, but the generated output always places it in Feature Workflow

**No version bump required.** This is purely a wizard UX improvement — the generated config format is identical. No downstream command behavior changes.

## Files to Change

| File | Change |
|------|--------|
| `commands/onboard.md` | Full rewrite — two modes, bundles, all 12 optional sections, template preview |
| `examples/configs/*.md` | Update key names (`Build command` instead of `Build`, etc.) and align profile definitions (`fast`, `minimal`) with normative spec |

## Pre-existing Issues Discovered (fix in same release)

| File | Issue |
|------|-------|
| `commands/check-setup.md` | PR Description Template listed as optional (step 5, line 65) but it is required per CLAUDE.md contract |
| `CLAUDE.md` | `Branch naming pattern` key name — rest of codebase uses `Branch naming` |
| `examples/configs/*.md` | Short key names (`Build`, `Test`) and profile definitions (`fast`, `minimal`) don't match normative spec |
| `commands/check-setup.md` | Build & Test required keys use short form (`Build`, `Test`) vs normative spec (`Build command`, `Test command`) |

## Out of Scope

- Changes to `/migrate-config` — stays independent
- Changes to `/check-setup` — beyond the PR Description Template fix noted above
- Runtime behavior changes — this is purely a wizard UX redesign
