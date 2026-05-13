# Onboard Wizard Redesign — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Rewrite the `/onboard` wizard to support update mode, bundle UX, feature workflow, and strict English output.

**Architecture:** Single command (`commands/onboard.md`) with two modes (fresh + update), smart routing to `/migrate-config`, and bundle-based optional section selection. No config contract changes.

**Tech Stack:** Pure markdown (no code, no build system). All changes are `.md` files.

**Design doc:** `docs/plans/2026-03-02-onboard-redesign-design.md`

---

### Task 1: Fix pre-existing key name inconsistencies in CLAUDE.md

**Files:**
- Modify: `CLAUDE.md` — line 105 (Config Contract table, Source Control row)

**Step 1: Fix `Branch naming pattern` → `Branch naming`**

In `CLAUDE.md`, the Config Contract table (line 105) says:

```
| Source Control | Remote (owner/repo), Base branch, Branch naming pattern |
```

Change to:

```
| Source Control | Remote (owner/repo), Base branch, Branch naming |
```

This aligns with the normative spec in `docs/reference/automation-config.md` (line 91) and all 6 templates.

**Step 2: Commit**

```bash
git add CLAUDE.md
git commit -m "fix: align 'Branch naming' key name in config contract"
```

---

### Task 2: Fix pre-existing issues in check-setup.md

**Files:**
- Modify: `commands/check-setup.md` — lines 22-26 (required keys table) and line 65 (optional sections list)

**Step 1: Fix Build & Test key names in required keys table**

In `commands/check-setup.md`, the required keys table (line 25) says:

```
| Build & Test | Build, Test |
```

Change to:

```
| Build & Test | Build command, Test command |
```

**Step 2: Move PR Description Template from optional to required**

In the required sections table (after line 24, PR Rules row), add a new row:

```
| PR Description Template | (subsection present) |
```

In the optional sections list (line 65), remove `PR Description Template` from the comma-separated list:

Before: `PR Description Template, Retry Limits, Hooks, Custom Agents, Notifications, Worktrees, E2E Test, Error Handling, Extra labels, Decomposition, Pipeline Profiles, Metrics, Feature Workflow`

After: `Retry Limits, Hooks, Custom Agents, Notifications, Worktrees, E2E Test, Error Handling, Extra labels, Decomposition, Pipeline Profiles, Metrics, Feature Workflow`

**Step 3: Commit**

```bash
git add commands/check-setup.md
git commit -m "fix: align check-setup with config contract (key names, PR template required)"
```

---

### Task 3: Update all 6 example templates — key names and profiles

**Files:**
- Modify: `examples/configs/github-nextjs.md`
- Modify: `examples/configs/github-dotnet.md`
- Modify: `examples/configs/github-python-fastapi.md`
- Modify: `examples/configs/gitea-spring-boot.md`
- Modify: `examples/configs/jira-react.md`
- Modify: `examples/configs/youtrack-python.md`

**Step 1: Fix key names in all 6 templates**

In every template, change:
- `| Build |` → `| Build command |`
- `| Test |` → `| Test command |`
- `| Verify |` → `| Verify command |` (only in github-nextjs.md where it appears in commented section)

**All 6 files** have the Build & Test section with the short key names. Example change (github-nextjs.md):

Before:
```
| Build | `npm run build` |
| Test | `npm test` |
```

After:
```
| Build command | `npm run build` |
| Test command | `npm test` |
```

Do the same for all 6 templates.

**Step 2: Fix profile definitions in github-nextjs.md**

In `examples/configs/github-nextjs.md` (commented section, lines 122-127), change:

Before:
```
| fast | triage, code-analyst | — |
| strict | — | e2e-test-engineer |
| minimal | triage, code-analyst, test-engineer | — |
```

After:
```
| fast | triage, code-analyst, test-engineer | — |
| strict | — | e2e-test-engineer |
| minimal | triage, code-analyst, test-engineer, e2e-test-engineer | — |
```

**Step 3: Commit**

```bash
git add examples/configs/
git commit -m "fix: align template key names and profile definitions with normative spec"
```

---

### Task 4: Update test fixtures — key names and profiles

**Files:**
- Modify: `tests/harness/fixtures/automation-config.md`
- Modify: `tests/mock-project/CLAUDE.md`

**Step 1: Fix key names in test fixture**

In `tests/harness/fixtures/automation-config.md` (lines 41-43), change:

Before:
```
| Build | `echo "build ok"` |
| Test | `echo "test ok"` |
| Verify | `echo "verify ok"` |
```

After:
```
| Build command | `echo "build ok"` |
| Test command | `echo "test ok"` |
| Verify command | `echo "verify ok"` |
```

**Step 2: Fix profile definitions in test fixture**

In the same file (lines 48-50), change:

Before:
```
| fast | triage, code-analyst | |
| strict | | e2e-test-engineer |
| minimal | triage, code-analyst, test-engineer | |
```

After:
```
| fast | triage, code-analyst, test-engineer | |
| strict | | e2e-test-engineer |
| minimal | triage, code-analyst, test-engineer, e2e-test-engineer | |
```

**Step 3: Fix key names in mock project**

In `tests/mock-project/CLAUDE.md` (lines 50-51), change:

Before:
```
| Build | `python -c "import app"` |
| Test | `python -m pytest tests/ -v` |
```

After:
```
| Build command | `python -c "import app"` |
| Test command | `python -m pytest tests/ -v` |
```

**Step 4: Verify test scenarios reference correct key names**

Read all 8 test scenario files in `tests/scenarios/` and check if any parse the key names `Build` or `Test` directly. If they do, update them. If they don't reference key names (most scenarios test pipeline behavior, not config parsing), no changes needed.

**Step 5: Commit**

```bash
git add tests/
git commit -m "fix: align test fixtures with normative key names and profiles"
```

---

### Task 5: Rewrite commands/onboard.md — frontmatter and detection

**Files:**
- Modify: `commands/onboard.md` — full rewrite

This is the main task. Due to the size of the rewrite, it's split into multiple sub-steps. All sub-steps operate on the same file.

**Step 1: Write the new frontmatter and Input section**

Replace the entire `commands/onboard.md` with the new version. Start with:

```markdown
---
description: Interactive wizard for generating Automation Config
allowed-tools: Read, Glob, Write, Edit
---

# Onboard

Interactive wizard that collects parameters and generates the `## Automation Config` block.

Input: `$ARGUMENTS` = (none) | `--fresh` | `--update`

- No arguments (default): auto-detect existing config and route accordingly
- `--fresh`: force fresh mode, skip config detection
- `--update`: force update mode, error if no config exists
```

**Step 2: Write Step 0 — Detection and Routing**

```markdown
## Step 0: Detection and Routing

1. Read the target project's CLAUDE.md
2. Look for `## Automation Config` section
3. If `--fresh` in $ARGUMENTS → skip detection, go to Fresh mode (step 1)
4. If `--update` in $ARGUMENTS and no config exists → error: "No Automation Config found. Run without --update to create one."
5. Route based on detection:

| State | Action |
|-------|--------|
| No config exists | Fresh mode (step 1) |
| Config exists, current version (has Pipeline Profiles or Metrics) | Offer: "[1] Update existing config [2] Start fresh (overwrites)" |
| Config exists, old version (no Pipeline Profiles and no Metrics) | "Detected older config format. Recommend running `/CLAUDE-agents:migrate-config` first for structural upgrade, then return here for value adjustments. Continue anyway? [y/N]" |

In update mode: parse entire existing config into key→value structure per section. This provides default values throughout the wizard.

Then proceed to:
- Fresh mode → step 1
- Update mode → step U0
```

**Step 3: Write Steps 1–2 — Template and Issue Tracker**

```markdown
## Fresh Mode

### Step 1: Template Offer

- "Would you like to start from a template? I have pre-built configurations for popular stacks."
- If yes → run `/CLAUDE-agents:template list` and let the user choose
- If user selects a template → load it, then go through steps 2–5 for adjustments
- If no → continue with classic wizard (step 2)

Greet the user: "I'll set up Automation Config for your project. I'll ask about all the parameters step by step."

### Step 2: Issue Tracker

Ask step by step:

1. Which issue tracker do you use? (youtrack / github / jira / linear / gitea)
2. Instance URL — defaults per tracker:
   - youtrack: `{project}.youtrack.cloud`
   - github: `github.com`
   - jira: `{org}.atlassian.net`
   - linear: `linear.app`
   - gitea: `<your-gitea-instance>`
3. Project name / project key:
   - github: `owner/repo` format
   - jira: PROJECT key (uppercase)
   - linear: team identifier
   - youtrack: project short name
   - gitea: `owner/repo` format
4. Bug query — offer defaults per tracker:
   - youtrack: `project: {PROJECT} State: Open Type: Bug`
   - github: `is:issue is:open label:bug`
   - jira: `project = {PROJECT} AND status = Open AND type = Bug`
   - linear: `team:{TEAM} state:started type:bug`
   - gitea: `type:issues state:open label:bug`
5. **Feature query** — "Do you also want to configure a feature query for `/implement-feature`?"
   If yes, offer defaults per tracker:
   - youtrack: `project: {PROJECT} Type: Feature State: Open`
   - github: `is:issue is:open label:enhancement`
   - jira: `project = {PROJECT} AND type = Story AND status = Open`
   - linear: `team:{TEAM} type:feature`
   - gitea: `type:issues state:open label:enhancement`
   If user provides a Feature query → auto-include `### Feature Workflow` section in output. The Feature query key is always emitted in the `### Feature Workflow` section (where `/implement-feature` reads it from).
   If user declines → no Feature query in output.
6. State transitions — offer defaults per tracker:
   - youtrack: `In Progress: State: In Progress | Blocked: State: Blocked | For Review: State: For Review`
   - github: `In Progress: add label:in-progress | Blocked: add label:blocked | For Review: add label:for-review`
   - jira: `In Progress: transition:In Progress | Blocked: transition:Blocked | For Review: transition:In Review`
   - linear: `In Progress: state:In Progress | Blocked: state:Blocked | For Review: state:In Review`
   - gitea: `In Progress: add label:in-progress | Blocked: add label:blocked | For Review: add label:for-review`
7. On start set — default per tracker:
   - youtrack: `State: In Progress`
   - github: `add label:in-progress`
   - jira: `transition:In Progress`
   - linear: `state:In Progress`
   - gitea: `add label:in-progress`
```

**Step 4: Write Steps 3–5 — Source Control, PR, Build**

```markdown
### Step 3: Source Control

Ask:
- Remote hostname + owner/repo (e.g. `gitea.internal.ceosdata.com/org/repo`)
- Base branch (default: `main`)
- Branch naming (default: `fix/{issue}-{short-description}`)

### Step 4: PR Rules + PR Description Template

**4a.** Labels for PR (default: `ForReview`)

**4b.** PR Description Template:
1. Auto-generate a tracker-appropriate template with this structure:

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

   Tracker-specific footers:
   - GitHub: `Closes #{issue_id}`
   - Gitea: `Fixes #{issue_number}`
   - YouTrack: `{issue_link}`
   - Jira: `{issue_key}`
   - Linear: `{issue_id}`

2. Display the full template as preview
3. "Looks good? Or do you want to customize? (add/remove/rename sections)"
4. If customize → apply changes interactively

### Step 5: Build & Test

Ask:
- Build command (e.g. `npm run build`, `dotnet build`)
- Test command (e.g. `npm test`, `pytest`)
- Verify command (optional): "Do you have a post-merge verification command? (e.g., integration tests)"

Generated key names: `Build command`, `Test command`, `Verify command`.
```

**Step 5: Write Step 6 — Optional Sections with Bundles**

```markdown
### Step 6: Optional Sections

**6a.** Bundle selection:

```
Which optional sections do you want to configure?

  [1] standard (recommended) — Retry Limits, Error Handling, Pipeline Profiles, Feature Workflow
  [2] full — all 12 optional sections
  [3] minimal — Retry Limits only
  [4] custom — choose from the list
```

If user selected a Feature query in step 2, Feature Workflow is auto-included regardless of bundle choice.

**6b.** If custom → show multi-select checklist:

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

**6c.** Processing order: Pipeline Profiles first (affects entire pipeline), then remaining in list order.

**6d.** Pipeline Profiles — prominent handling:
- Offer pre-built profiles with explanation:
  - `fast`: skip triage, code-analyst, test-engineer — "Quick fixes, skip analysis"
  - `strict`: extra e2e-test-engineer — "Full quality gate"
  - `minimal`: skip triage, code-analyst, test-engineer, e2e-test-engineer — "Emergency hotfixes"
- User can add custom profiles
- Display profile table as preview before confirming

**6e.** Feature Workflow — when asking about "On start set":
- Show fallback: "Feature 'On start set' (default: same as Issue Tracker '{value}' — press Enter to keep)"
- This matches the fallback in `/implement-feature`

**6f.** For each remaining selected section, ask for its key values using defaults from `docs/reference/automation-config.md`:
- Retry Limits: Fixer iterations (default: 5), Test attempts (default: 3), Build retries (default: 3)
- Error Handling: On block (default: `comment`), Max blocked per run (default: `unlimited`)
- Hooks: Pre-fix, Post-fix, Pre-publish, Post-publish (all default: none)
- Custom Agents: Post-fix agent, Pre-publish agent (all default: none)
- Notifications: Webhook URL, On events (all default: none)
- Worktrees: Batch size (default: 3), Base path (default: `.worktrees/`), Cleanup (default: `auto`)
- E2E Test: Framework, Command (all default: none)
- Decomposition: Max subtasks (default: 7), Fail strategy (default: `fail-fast`), Commit strategy (default: `squash`)
- Metrics: Output (default: `stdout`), Period (default: `30 days`)
- Extra labels: Labels (default: none)
```

**Step 6: Write Steps 7–9 — Generate, Output, Closing**

```markdown
### Step 7: Generate Automation Config

Generate the Automation Config block from collected answers.

Language rules:
1. All keys in English — exactly per `docs/reference/automation-config.md`
2. All identifier values in English (State transitions, Branch naming, Labels, Profile names)
3. User-provided values preserved as-is (URLs, project names, commands)
4. Table format always (`| Key | Value |`) — never bullet-point lists
5. PR Description Template section headings always in English

### Step 8: Output Options

**Fresh mode:**
- Option 1 (default): Print the block to chat — the user copies it manually
- Option 2: Write directly into CLAUDE.md
  - If `## Automation Config` already exists → warn and offer overwrite or cancel
  - If it does not exist → append to the end of CLAUDE.md

**Update mode:**
- Display diff (before → after, only changed sections)
- Option 1 (default): Write changes to CLAUDE.md
- Option 2: Print to chat only

Safety: Never delete existing sections/keys that the wizard does not recognize. Preserve custom additions.

### Step 9: Closing Message

```
Automation Config generated successfully.

Next steps:
1. Run /CLAUDE-agents:check-setup to validate your configuration
2. Configure MCP servers for your issue tracker (see docs/guides/mcp-configuration.md)
3. Try /CLAUDE-agents:analyze-bug <issue-id> to test the bug pipeline
```

If Feature query was configured, add:
```
4. Try /CLAUDE-agents:implement-feature <issue-id> to test the feature pipeline
```

Always end with:
```
Note: CLAUDE-agents uses semantic versioning. See Versioning Policy in the plugin's CLAUDE.md.
```
```

**Step 7: Write Update Mode section**

```markdown
## Update Mode

### Step U0: Overview Display

Show a summary of the existing config:

```
Detected existing Automation Config:

  Issue Tracker: {type} @ {instance} — {project}
  Source Control: {remote} — {base branch}
  PR Rules: Labels = {labels}
  Build & Test: {build command} / {test command}
  Optional: {list of present optional sections}
  Missing optional: {list of absent optional sections}

  [1] Update existing config (go through sections, change what you need)
  [2] Add missing optional sections
  [3] Start fresh (overwrites everything)
```

### Step U1: Section-by-section update

For each existing section:
1. Display current values as table
2. "Any changes? (press Enter to keep, or type new values)"
3. If no changes → skip to next section
4. If changes → record new values

Include all sections: Issue Tracker, Source Control, PR Rules, PR Description Template, Build & Test, and all present optional sections.

### Step U2: Add missing sections

After going through existing sections:
- Show only sections not yet in config as a multi-select list
- For each selected section → ask for values (same questions as fresh mode step 6)

### Step U3: Diff and confirm

- Show before/after diff for changed sections only
- "Apply changes to CLAUDE.md? [Y/n]"
- Write to CLAUDE.md after confirmation
- Then show the closing message (step 9)
```

**Step 8: Write Rules section**

```markdown
## Rules

- All wizard text (questions, prompts, explanations) in English
- All generated output (Automation Config block) in English
- Do not validate answers — validation belongs in `/check-setup`
- Offer defaults, but the user can change them
- Skip optional sections if the user says no
- Output always in table format (`| Key | Value |`)
- Feature query is always emitted in `### Feature Workflow` section, never in Issue Tracker
- In update mode: never delete sections/keys the wizard does not recognize
- Cancellation is safe: no changes are written until step 8 (fresh) or U3 (update)
```

**Step 9: Review the complete file**

Read the entire new `commands/onboard.md` and verify:
- All 12 optional sections are listed in the multi-select
- Profile definitions match normative spec (`fast`, `strict`, `minimal`)
- Key names match normative spec (`Build command`, `Test command`, `Verify command`, `Branch naming`)
- Feature query placement is correct (asked in step 2, emitted in Feature Workflow)
- Update mode flow is complete (U0 → U1 → U2 → U3)
- No leftover Czech text

**Step 10: Commit**

```bash
git add commands/onboard.md
git commit -m "feat: redesign onboard wizard with update mode, bundles, and feature workflow

- Add config detection and routing (fresh vs update mode)
- Add $ARGUMENTS support (--fresh, --update)
- Add bundle UX for optional sections (standard/full/minimal/custom)
- Add Feature query to Issue Tracker step
- Add PR Description Template preview with tracker-specific defaults
- Add Verify command to Build & Test step
- Add all 12 optional sections (was missing: Feature Workflow, Decomposition, Metrics)
- Align profile definitions with normative spec
- All wizard text and output in English"
```

---

### Task 6: Final verification

**Step 1: Cross-reference check**

Verify these cross-references are consistent:
- `commands/onboard.md` step 2 Feature query defaults match `commands/implement-feature.md` Feature Workflow section
- `commands/onboard.md` key names match `docs/reference/automation-config.md`
- `commands/onboard.md` profile definitions match `docs/reference/automation-config.md` Pipeline Profiles section
- `examples/configs/*.md` key names and profiles match normative spec
- `tests/harness/fixtures/automation-config.md` key names match
- `tests/mock-project/CLAUDE.md` key names match
- `commands/check-setup.md` required keys match normative spec

**Step 2: Verify no regressions in test scenarios**

Read `tests/scenarios/*.sh` to check if any scenario references old key names (`Build`, `Test`) directly. If any do, update them.

Run: `grep -r "| Build |" tests/scenarios/` and `grep -r "| Test |" tests/scenarios/`

**Step 3: Run test suite (if possible)**

Run: `./tests/harness/run-tests.sh`

If tests pass → done. If tests fail due to key name changes → fix the test scenarios.
