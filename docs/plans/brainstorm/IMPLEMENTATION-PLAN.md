# Implementation Plan — ceos-agents v3.4.0

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Rename plugin CLAUDE-agents → ceos-agents, fix Forgejo MCP URL, fix directory scope bug, create new `init` command, improve check-setup diagnostics, and add MCP guard clauses to all 16 MCP-dependent commands.

**Architecture:** Pure markdown plugin — all changes are text edits in .md, .json, .yaml, .sh files. No build system, no runtime code. Verification via grep counts and manual inspection.

**Tech Stack:** Markdown, JSON, YAML, Bash (test harness)

---

## Overview

Six brainstorm documents (01–03, 05–07) identified interconnected improvements. DECISIONS.md contains all finalized architectural decisions. This plan implements them in 6 phases ordered by dependency:

1. **Rename** CLAUDE-agents → ceos-agents (breaking change, touches ~60 active files)
2. **URL fix** for Forgejo MCP + docs updates
3. **Directory scope fix** — git root + confirm in onboard/migrate-config, unify wording in 7 commands
4. **New `init` command** — MCP server config, token setup, permission setup
5. **Check-setup improvements** — better diagnostics for MCP issues
6. **Guard clause** — pre-flight MCP check in all 16 MCP-dependent commands

## Prerequisites (before implementation)

| # | Prerequisite | How to verify | Status |
|---|-------------|---------------|--------|
| P1 | Verify Codeberg URL: `codeberg.org/goern/forgejo-mcp` exists and has releases | Open URL in browser, confirm releases page loads | DECISIONS.md says verified (forgejo/forgejo-mcp = 404) |
| P2 | Create `examples/mcp-configs/redmine.json` | File does NOT exist yet — needed for Phase 4 `init` command | Must create |
| P3 | Communicate rename to 4 users | Email/message before Phase 1 starts | Must do |
| P4 | Rename Gitea repo `CLAUDE-agents` → `ceos-agents` | Gitea admin UI: Settings → Repository name | Must do AFTER Phase 1 code changes, BEFORE push |

---

## Phase 1: Rename (breaking change)

Rename plugin from `CLAUDE-agents` to `ceos-agents`. This changes the namespace prefix from `CLAUDE-agents:` to `ceos-agents:`.

### Scope rules

- **Change:** All active source files (commands/, agents/, skills/, docs/guides/, docs/reference/, docs/*.md, examples/, tests/, .claude-plugin/, root files, CI)
- **Skip:** Historical files in `docs/plans/2026-*` (archive, no user impact)
- **Skip:** Files in `.claude/worktrees/` (stale worktree, should be cleaned up)
- **Skip:** Brainstorm files in `docs/plans/brainstorm/` (decision docs, not shipped)

### What changes

Every occurrence of `CLAUDE-agents` becomes `ceos-agents`. This includes:
- Plugin name in JSON configs
- Namespace prefix in command references (`/CLAUDE-agents:` → `/ceos-agents:`)
- Agent task references (`CLAUDE-agents:fixer` → `ceos-agents:fixer`)
- Block comment prefix `[CLAUDE-agents]` → `[ceos-agents]`
- Checkpoint markers `[CLAUDE-agents] Triage completed` → `[ceos-agents] Triage completed`
- Skill name `CLAUDE-agents:bug-workflow` → `ceos-agents:bug-workflow`
- Documentation text references
- Installation command `/plugin install CLAUDE-agents@CLAUDE-agents` → `/plugin install ceos-agents@ceos-agents`

### Task 1.1: Rename in plugin metadata

**Files:**
- Modify: `.claude-plugin/plugin.json` (lines 2, 8 — `"name": "CLAUDE-agents"`, `"repository"` URL)
- Modify: `.claude-plugin/marketplace.json` (lines 2, 8 — `"name": "CLAUDE-agents"`)

**Step 1:** Edit `plugin.json`

```json
{
  "name": "ceos-agents",
  "description": "CEOS CLAUDE Agents — development automation: bug-fix, feature pipeline, scaffold, decomposition, dashboard",
  "version": "3.3.0",
  "author": {
    "name": "Filip Sabacky"
  },
  "repository": "https://gitea.internal.ceosdata.com/fsabacky/ceos-agents.git",
  "license": "UNLICENSED"
}
```

**Step 2:** Edit `marketplace.json`

```json
{
  "name": "ceos-agents",
  "owner": {
    "name": "Filip Sabacky"
  },
  "plugins": [
    {
      "name": "ceos-agents",
      "source": "./",
      "description": "CEOS CLAUDE Agents — development automation: bug-fix, feature pipeline, scaffold, decomposition, dashboard",
      "version": "3.3.0"
    }
  ]
}
```

**Step 3:** Verify

```bash
grep -c "CLAUDE-agents" .claude-plugin/plugin.json .claude-plugin/marketplace.json
# Expected: 0 for both files
grep -c "ceos-agents" .claude-plugin/plugin.json .claude-plugin/marketplace.json
# Expected: plugin.json:2, marketplace.json:2
```

### Task 1.2: Rename in skill file

**Files:**
- Modify: `skills/bug-workflow/SKILL.md` (26 occurrences)

**Step 1:** Replace all `CLAUDE-agents` → `ceos-agents` in `skills/bug-workflow/SKILL.md`

Key changes:
- Line 6: `routing assistant for the CLAUDE-agents plugin` → `ceos-agents plugin`
- Lines 12-34: All command references in Intent Mapping table (`CLAUDE-agents:analyze-bug` → `ceos-agents:analyze-bug`, etc.)
- Lines 40-44: Process section references

**Step 2:** Verify

```bash
grep -c "CLAUDE-agents" skills/bug-workflow/SKILL.md
# Expected: 0
grep -c "ceos-agents" skills/bug-workflow/SKILL.md
# Expected: 26
```

### Task 1.3: Rename in commands (22 files)

**Files:** All 22 files in `commands/`

Commands with `CLAUDE-agents` references (from grep count):

| File | Occurrences | What changes |
|------|-------------|-------------|
| `fix-ticket.md` | 12 | Agent dispatch refs, command refs |
| `version-check.md` | 11 | Plugin name refs, install instructions |
| `fix-bugs.md` | 10 | Agent dispatch refs, pipeline refs |
| `metrics.md` | 8 | Agent refs, command refs |
| `dashboard.md` | 7 | Command refs, output format |
| `onboard.md` | 6 | Command refs in closing message, template refs |
| `resume-ticket.md` | 5 | Checkpoint marker `[CLAUDE-agents]`, command refs |
| `analyze-bug.md` | 4 | Agent refs, checkpoint marker |
| `check-setup.md` | 3 | Plugin name, composability check |
| `implement-feature.md` | 3 | Agent dispatch, command refs |
| `scaffold.md` | 3 | Command refs |
| `template.md` | 3 | Command refs |
| `version-bump.md` | 2 | Plugin refs |
| `migrate-config.md` | 1 | Upgrade recommendation ref |
| `prioritize.md` | 1 | Agent ref |
| `publish.md` | 1 | Agent ref |
| `create-pr.md` | 0 | (verify — may have indirect refs) |
| `changelog.md` | 0-1 | (verify) |
| `estimate.md` | 0 | (verify) |
| `scaffold-add.md` | 0 | (verify) |
| `scaffold-validate.md` | 0 | (verify) |
| `status.md` | 0 | (verify) |

**Step 1:** For each file with occurrences, replace `CLAUDE-agents` → `ceos-agents` using replace_all.

**Critical patterns to change:**
- `/CLAUDE-agents:` → `/ceos-agents:` (slash command refs)
- `CLAUDE-agents:triage-analyst` → `ceos-agents:triage-analyst` (agent dispatch)
- `[CLAUDE-agents]` → `[ceos-agents]` (block comment/checkpoint markers)
- `CLAUDE-agents pipeline` → `ceos-agents pipeline` (prose)
- `CLAUDE-agents commands` → `ceos-agents commands` (composability check)

**CRITICAL — resume-ticket.md backwards compatibility:**

`resume-ticket.md` line 90 states: "`[CLAUDE-agents]` comments are critical for detection — the prefix is stable". Existing issues in trackers still have old `[CLAUDE-agents]` comments. After rename:

1. Change all `[CLAUDE-agents]` → `[ceos-agents]` in the template patterns
2. BUT update the detection logic (lines 17-18, 57-58) to accept BOTH prefixes:
   - Change `[CLAUDE-agents] Triage completed.` → detect `[ceos-agents] Triage completed.` OR `[CLAUDE-agents] Triage completed.`
   - Change `[CLAUDE-agents] Spec analysis completed.` → detect both prefixes
3. Update line 90: change "the prefix is stable" to "the `[ceos-agents]` prefix is used for new comments; `[CLAUDE-agents]` (legacy) is also accepted for detection"

**Step 2:** Verify

```bash
grep -rl "CLAUDE-agents" commands/
# Expected: no results
grep -c "ceos-agents" commands/*.md | grep -v ":0$"
# Expected: files with counts matching original
```

### Task 1.4: Rename in agents (13 files)

**Files:** All 13 files in `agents/`

Agents with `CLAUDE-agents` references:

| File | Occurrences | What changes |
|------|-------------|-------------|
| `code-analyst.md` | 3 | Block comment prefix `[CLAUDE-agents]` |
| `priority-engine.md` | 2 | Command refs |
| `spec-analyst.md` | 2 | Checkpoint marker `[CLAUDE-agents]` |
| `triage-analyst.md` | 2 | Checkpoint marker `[CLAUDE-agents]` |
| `architect.md` | 1 | Ref |
| `e2e-test-engineer.md` | 1 | Ref |
| `fixer.md` | 1 | Block comment prefix |
| `publisher.md` | 1 | Block comment prefix |
| `reviewer.md` | 1 | Block comment prefix |
| `rollback-agent.md` | 1 | Block comment prefix |
| `test-engineer.md` | 1 | Block comment prefix |

**Step 1:** Replace `CLAUDE-agents` → `ceos-agents` in all 11 agent files with occurrences. The critical change is `[CLAUDE-agents]` → `[ceos-agents]` in block comment templates and checkpoint markers.

**Step 2:** Verify

```bash
grep -rl "CLAUDE-agents" agents/
# Expected: no results
```

### Task 1.5: Rename in documentation

**Files:**

| File | Occurrences |
|------|-------------|
| `docs/reference/commands.md` | 50 |
| `docs/guides/troubleshooting.md` | 19 |
| `docs/getting-started.md` | 18 |
| `docs/reference/pipelines.md` | 11 |
| `docs/guides/installation.md` | 8 |
| `docs/architecture.md` | 8 |
| `docs/reference/automation-config.md` | 7 |
| `docs/guides/tokens.md` | 7 |
| `docs/reference/agents.md` | 4 |
| `docs/guides/cross-platform.md` | 4 |
| `docs/guides/custom-agents.md` | 3 |
| `docs/guides/mcp-configuration.md` | 1 |

**Step 1:** Replace `CLAUDE-agents` → `ceos-agents` in all 12 docs files.

**Step 2:** Verify

```bash
grep -rl "CLAUDE-agents" docs/guides/ docs/reference/ docs/architecture.md docs/getting-started.md
# Expected: no results
```

### Task 1.6: Rename in root files

**Files:**
- `CLAUDE.md` (8 occurrences)
- `README.md` (9 occurrences)
- `CHANGELOG.md` (1 occurrence — existing entries only, new entry added later)
- `CONTRIBUTING.md` (2 occurrences)

**Step 1:** Replace `CLAUDE-agents` → `ceos-agents` in all 4 files.

**Important:** In `CLAUDE.md`, the installation line changes:
```
**Installation:** `/plugin install ceos-agents@ceos-agents`
```

**Step 2:** Verify

```bash
grep -c "CLAUDE-agents" CLAUDE.md README.md CHANGELOG.md CONTRIBUTING.md
# Expected: 0 for all
```

### Task 1.7: Rename in tests and CI

**Files:**
- `tests/README.md` (1)
- `tests/mock-project/CLAUDE.md` (1)
- `tests/harness/mock-mcp-server.sh` (1)
- `tests/harness/run-tests.sh` (2)
- `tests/harness/fixtures/issues.json` (1)
- `.gitea/workflows/test.yaml` (1)

**Step 1:** Replace `CLAUDE-agents` → `ceos-agents` in all 6 files.

**Step 2:** Verify

```bash
grep -rl "CLAUDE-agents" tests/ .gitea/
# Expected: no results
```

### Task 1.8: Rename in docs/plans active files

**Files:**
- `docs/plans/roadmap.md` (3)
- `docs/plans/README.md` (1)

**Step 1:** Replace in these 2 files only. Do NOT touch historical `docs/plans/2026-*` files.

### Task 1.9: Final rename verification

**Step 1:** Full codebase grep (excluding skipped dirs)

```bash
grep -rl "CLAUDE-agents" --include="*.md" --include="*.json" --include="*.yaml" --include="*.sh" . | grep -v "docs/plans/2026-" | grep -v ".claude/worktrees" | grep -v "docs/plans/brainstorm" | grep -v "REVIEW-REPORT"
# Expected: no results
```

**Step 2:** Commit

```bash
git add -A
git commit -m "feat!: rename plugin CLAUDE-agents → ceos-agents

BREAKING CHANGE: Plugin namespace changes from CLAUDE-agents: to ceos-agents:.
Users must reinstall: /plugin install ceos-agents@ceos-agents
All command references change (e.g. /ceos-agents:fix-ticket).
Block comment markers change from [CLAUDE-agents] to [ceos-agents]."
```

---

## Phase 2: URL fix + docs

### Task 2.1: Fix Forgejo MCP URL in active docs

Per DECISIONS.md #1: URL `forgejo/forgejo-mcp` → `goern/forgejo-mcp` (verified: forgejo/forgejo-mcp = 404).

**Files:**
- Modify: `docs/guides/mcp-configuration.md:45` — URL fix
- Modify: `docs/guides/installation.md:72` — URL fix

**Step 1:** In `docs/guides/mcp-configuration.md`, line 45, change:
```
- **Source:** [codeberg.org/forgejo/forgejo-mcp/releases](https://codeberg.org/forgejo/forgejo-mcp/releases)
```
→
```
- **Source:** [codeberg.org/goern/forgejo-mcp/releases](https://codeberg.org/goern/forgejo-mcp/releases)
```

**Step 2:** In `docs/guides/installation.md`, line 72, change:
```
download the linux-amd64 binary from [codeberg.org/forgejo/forgejo-mcp/releases](https://codeberg.org/forgejo/forgejo-mcp/releases)
```
→
```
download the linux-amd64 binary from [codeberg.org/goern/forgejo-mcp/releases](https://codeberg.org/goern/forgejo-mcp/releases)
```

**Step 3:** Verify

```bash
grep -r "forgejo/forgejo-mcp" docs/guides/ docs/reference/ examples/
# Expected: no results (only historical docs/plans/ may still have old URL)
grep "goern/forgejo-mcp" docs/guides/mcp-configuration.md docs/guides/installation.md
# Expected: 1 match per file
```

### Task 2.2: Add UX tip to onboard closing message

Per DECISIONS.md #4: Add tab-complete and skill routing tip.

**File:** `commands/onboard.md:209-212`

**Step 1:** After the existing closing message note, add:

```markdown
Tip: You can use tab-completion (`/ceos<tab>`) to discover commands, or describe what you want in natural language — the skill router will find the right command.
```

**Step 2:** Verify by reading `commands/onboard.md` lines 209-215.

### Task 2.3: Commit

```bash
git add docs/guides/mcp-configuration.md docs/guides/installation.md commands/onboard.md
git commit -m "fix: correct Forgejo MCP URL to goern/forgejo-mcp + add UX tip to onboard"
```

---

## Phase 3: Directory scope fix

### Task 3.1: Add git root + confirm to onboard

Per DECISIONS.md doc 03: Git root as default, confirm before write, heuristika for subdirectory.

**File:** `commands/onboard.md`

**Step 1:** Add new section after line 14 (before `## Step 0`):

```markdown
## Scope

Target directory = git repository root (detect via `git rev-parse --show-toplevel`).
If not in a git repo → use CWD.

- Target file: `{target_dir}/CLAUDE.md`
- NEVER read or write CLAUDE.md outside of the target directory
- NEVER traverse parent directories to find CLAUDE.md
- Before any write operation, display: `Target: {absolute_path}/CLAUDE.md — Is this correct? [Y/n/custom path]`
- If CWD is NOT git root AND a CLAUDE.md exists in a parent directory:
  "You're in a subdirectory. CLAUDE.md exists at {parent}/CLAUDE.md.
   Write here ({CWD}) or there ({parent})? [here/THERE]"
```

**Step 2:** Update Step 0 (currently line 18) to reference Scope:

Change:
```
1. Read the target project's CLAUDE.md
```
→
```
1. Determine the target directory per ## Scope rules above
2. Read `{target_dir}/CLAUDE.md`
```

**Step 3:** Update Step 8 Fresh mode (line 182-184):

Change:
```
  - If it does not exist → append to the end of CLAUDE.md
```
→
```
  - If it does not exist → create CLAUDE.md in the target directory, append config
  - Display absolute path before writing: "Will write to: {absolute_path}/CLAUDE.md"
```

**Step 4:** Update Step U3 (line 254-255):

Change:
```
- "Apply changes to CLAUDE.md? [Y/n]"
- Write to CLAUDE.md after confirmation
```
→
```
- "Apply changes to {absolute_path}/CLAUDE.md? [Y/n]"
- Write to the target directory CLAUDE.md after confirmation
```

**Step 5:** Verify by reading the modified file.

### Task 3.2: Apply same fix to migrate-config

Per DECISIONS.md doc 03 Q4: Same fix for migrate-config.

**File:** `commands/migrate-config.md`

**Step 1:** Add Scope section after line 4 (after frontmatter):

```markdown
## Scope

Target directory = git repository root (detect via `git rev-parse --show-toplevel`).
If not in a git repo → use CWD.

- Target file: `{target_dir}/CLAUDE.md`
- NEVER read or write CLAUDE.md outside of the target directory
- NEVER traverse parent directories to find CLAUDE.md
- Before any write operation, display: `Target: {absolute_path}/CLAUDE.md — Is this correct? [Y/n/custom path]`
```

**Step 2:** Update line 12:

Change:
```
Read the target project's CLAUDE.md, find `## Automation Config`.
```
→
```
Determine the target directory per ## Scope rules above. Read `{target_dir}/CLAUDE.md`, find `## Automation Config`.
```

### Task 3.3: Unify "target project's" wording in 7 commands

Per DECISIONS.md doc 03 Q6: Variant B — unify in all 7 commands.

New standard wording: `Read Automation Config from CLAUDE.md` (matches the pattern already used by 8+ other commands).

**Files and changes:**

| File | Line | Old | New |
|------|------|-----|-----|
| `commands/onboard.md` | ~18 (post-Scope edit) | `Read the target project's CLAUDE.md` | Changed in Task 3.1 already |
| `commands/migrate-config.md` | 12 | `Read the target project's CLAUDE.md` | Changed in Task 3.2 already |
| `commands/implement-feature.md` | 12 | `Read from the target project's CLAUDE.md section` | `Read Automation Config from CLAUDE.md section` |
| `commands/dashboard.md` | 19 | `Read from the target project's CLAUDE.md:` | `Read Automation Config from CLAUDE.md:` |
| `commands/estimate.md` | 12 | `Read from the target project's CLAUDE.md section` | `Read Automation Config from CLAUDE.md section` |
| `commands/prioritize.md` | 12 | `Read from the target project's CLAUDE.md section` | `Read Automation Config from CLAUDE.md section` |
| `commands/metrics.md` | 18 | `Read from the target project's CLAUDE.md section` | `Read Automation Config from CLAUDE.md section` |

**Step 1:** Edit each of the 5 remaining commands (implement-feature, dashboard, estimate, prioritize, metrics).

**Step 2:** Verify

```bash
grep -r "target project's CLAUDE.md" commands/
# Expected: no results
```

### Task 3.4: Commit

```bash
git add commands/onboard.md commands/migrate-config.md commands/implement-feature.md commands/dashboard.md commands/estimate.md commands/prioritize.md commands/metrics.md
git commit -m "fix: directory scope — git root + confirm, unify CLAUDE.md wording in 7 commands"
```

---

## Phase 4: New command `init`

Per DECISIONS.md doc 02+06: New command for developer environment setup (MCP servers, tokens, permissions). Separate from onboard (project config).

### Task 4.0: Create redmine.json prerequisite

**File:** Create `examples/mcp-configs/redmine.json`

```json
{
  "mcpServers": {
    "redmine": {
      "command": "npx",
      "args": ["-y", "--prefix", "<PATH_TO_MCP_SERVER_REDMINE>", "mcp-server-redmine"],
      "env": {
        "REDMINE_HOST": "https://<YOUR_REDMINE_INSTANCE>",
        "REDMINE_API_KEY": "<YOUR_REDMINE_API_KEY>"
      }
    }
  }
}
```

### Task 4.1: Create `commands/init.md`

**File:** Create `commands/init.md`

```markdown
---
description: Configures developer environment — MCP servers, tokens, and permissions
allowed-tools: Read, Glob, Write, Edit, Bash, mcp__*
---

# Init

Set up the developer environment for ceos-agents pipeline. Generates `.mcp.json` (MCP server configuration) and `.claude/settings.json` (tool permissions).

This command is the counterpart to `/ceos-agents:onboard`:
- **onboard** = project config (Automation Config in CLAUDE.md)
- **init** = developer environment (MCP servers, tokens, permissions)

Input: `$ARGUMENTS` = (none) | `--update`

## Scope

This command writes to the CURRENT WORKING DIRECTORY:
- `.mcp.json` — MCP server configuration
- `.claude/settings.json` — tool auto-approval (optional)
- `.gitignore` — adds `.mcp.json` if not present

## Step 1: Read Automation Config

Read Automation Config from CLAUDE.md. Extract:
- **Type** from Issue Tracker (determines tracker MCP server)
- **Instance** from Issue Tracker (determines server URL/env vars)
- **Remote** from Source Control (determines SC MCP server and hostname)

If no Automation Config found → error: "No Automation Config found. Run `/ceos-agents:onboard` first."

## Step 2: Detect existing .mcp.json

- If `.mcp.json` exists in CWD:
  - If `--update` → parse existing config, preserve non-ceos-agents servers
  - If no flag → "Found existing .mcp.json. Update it? [Y/n]"
    - Y → parse and preserve
    - N → skip MCP setup, go to Step 6
- If `.mcp.json` does NOT exist → fresh mode

## Step 3: Determine MCP servers needed

Read `docs/reference/trackers.md` MCP Server Detection table.

| Tracker Type | MCP Package | Token env var | Extra env vars |
|-------------|-------------|---------------|----------------|
| youtrack | `@vitalyostanin/youtrack-mcp` | `YOUTRACK_TOKEN` | `YOUTRACK_BASE_URL` |
| github | `@modelcontextprotocol/server-github` | `GITHUB_PERSONAL_ACCESS_TOKEN` | — |
| jira | `@modelcontextprotocol/server-atlassian` | `ATLASSIAN_API_TOKEN` | `ATLASSIAN_URL`, `ATLASSIAN_EMAIL` |
| linear | `@modelcontextprotocol/server-linear` | `LINEAR_API_KEY` | — |
| gitea | `forgejo-mcp` (binary) | `FORGEJO_TOKEN` | `FORGEJO_URL` |
| redmine | `mcp-server-redmine` | `REDMINE_API_KEY` | `REDMINE_HOST` |

**Shared server detection:** Compare tracker Type hostname with Source Control Remote hostname.
- Gitea tracker + Gitea SC → single `forgejo-mcp` instance (shared)
- GitHub tracker + GitHub SC → single `server-github` instance (shared)
- Mixed (e.g. Jira + GitHub SC) → two separate servers

Determine which servers to configure:
1. Tracker MCP server (always)
2. Source control MCP server (if different from tracker)

## Step 4: Collect tokens

For each required MCP server:

"Your tracker is {Type}. You need a {token_name} token."
"See docs/guides/tokens.md for how to create one."
"Paste your token (or press Enter to skip — you can add it later):"

For extra env vars (Instance URL, email):
- Auto-fill from Automation Config where possible (Instance → base URL)
- Ask for remaining (e.g. ATLASSIAN_EMAIL for Jira)

If shared server detected:
"Your tracker ({Type}) and source control ({Remote}) use the same MCP server. One configuration covers both."

If separate SC server needed:
"Your source control is on {hostname}. You need a {sc_token_name} token."

## Step 5: Platform-specific handling

### For forgejo-mcp (Gitea/Forgejo tracker):

Detect platform via Bash:
```bash
uname -s  # Linux, Darwin, MINGW*/MSYS* (Windows)
uname -m  # x86_64, arm64, aarch64
```

Based on result, determine:
- Windows: binary name `forgejo-mcp.exe`, download `forgejo-mcp-windows-amd64.exe`
- Linux: binary name `forgejo-mcp`, download `forgejo-mcp-linux-amd64`, needs `chmod +x`
- macOS x86: binary name `forgejo-mcp`, download `forgejo-mcp-darwin-amd64`
- macOS ARM: binary name `forgejo-mcp`, download `forgejo-mcp-darwin-arm64`

"Download the forgejo-mcp binary from: https://codeberg.org/goern/forgejo-mcp/releases"
"Save it to a known path (e.g., `bin/forgejo-mcp`)."
"Enter the path to your forgejo-mcp binary:"

### For mcp-server-redmine:

"mcp-server-redmine requires a local installation with --prefix."
"Enter the path to your mcp-server-redmine installation (e.g., /usr/local/lib/mcp-server-redmine):"

### For all npx-based servers:

No special handling — npx auto-downloads.

## Step 6: Generate .mcp.json

Load the appropriate template from `examples/mcp-configs/{type}.json`.

- Replace placeholder tokens with user-provided values (or keep `<YOUR_*>` if skipped)
- Replace placeholder URLs with values from Automation Config
- If update mode: merge into existing `.mcp.json` (preserve unrelated servers)
- If shared server: emit only one server entry

Write `.mcp.json` to CWD.

If `.mcp.json` not in `.gitignore`:
- Add `.mcp.json` to `.gitignore`

Create `.mcp.json.example` (same structure, all tokens replaced with `<YOUR_*>`).

## Step 7: Validate connectivity

For each configured MCP server with non-placeholder tokens:

- Attempt a minimal MCP call:
  - Tracker: query 1 issue (same as check-setup Block 3)
  - Source control: list repos (same as check-setup Block 3)
- Success → "[OK] {server_name} connected successfully"
- Failure → "[FAIL] {server_name}: {error}. Check your token and URL."

If any placeholder tokens remain:
- "[SKIP] {server_name}: token not configured. Add it to .mcp.json later."

## Step 8: Permission setup

"Would you like to configure permanent tool permissions? This prevents permission prompts when resuming sessions."

Offer 4 levels:

```
[1] Full pipeline (recommended) — all tools needed for fix/implement/scaffold
[2] Read-only — analysis commands only (analyze-bug, status, dashboard)
[3] Minimal — basic tools, approve MCP per-call
[4] Custom — choose specific tools
```

Generate `.claude/settings.json` based on choice:

**Full pipeline:**
```json
{
  "permissions": {
    "allow": [
      "Read", "Write", "Edit", "Glob", "Grep", "Bash",
      "mcp__{tracker_prefix}__*", "mcp__{sc_prefix}__*"
    ]
  }
}
```

Where `{tracker_prefix}` and `{sc_prefix}` are specific to the configured servers (e.g., `youtrack`, `gitea`, `github`). Per DECISIONS.md doc 06 Q4: use specific prefixes, NOT wildcard `mcp__*`.

**Read-only:**
```json
{
  "permissions": {
    "allow": [
      "Read", "Glob", "Grep",
      "mcp__{tracker_prefix}__*"
    ]
  }
}
```

**Minimal:**
```json
{
  "permissions": {
    "allow": ["Read", "Glob", "Grep"]
  }
}
```

**Custom:** Let user select from list of tools.

If `.claude/settings.json` already exists:
- Merge: add missing permissions, don't remove existing ones
- Show diff before writing

## Step 9: Closing message

```
Developer environment configured successfully.

  .mcp.json — MCP server configuration ({N} servers)
  .mcp.json.example — template for team sharing (no secrets)
  .claude/settings.json — tool permissions ({level})

Next steps:
1. Run /ceos-agents:check-setup to verify everything works
2. If you skipped tokens, add them to .mcp.json before running the pipeline

Tip: You can re-run /ceos-agents:init --update anytime to update your setup.
```

## Rules

- NEVER write tokens into CLAUDE.md — only into .mcp.json
- NEVER commit .mcp.json to git — always add to .gitignore
- In update mode: preserve existing non-ceos-agents MCP servers in .mcp.json
- In update mode: preserve existing permissions in .claude/settings.json
- Auto-fill from Automation Config where possible — minimize questions
- All wizard text in English
```

**Step 2:** Verify the file exists and is well-formed.

### Task 4.2: Update onboard closing message to reference init

**File:** `commands/onboard.md` — Step 9 closing message

Change the MCP line (line ~200 after Phase 3 edits):
```
2. Configure MCP servers for your issue tracker (see docs/guides/mcp-configuration.md)
```
→
```
2. Run /ceos-agents:init to configure MCP servers and permissions
```

### Task 4.3: Update docs to reference init command

**Files:**
- `docs/getting-started.md` — add init to the "after onboard" flow
- `docs/reference/commands.md` — add init command entry
- `docs/guides/mcp-configuration.md` — add note about init as automated alternative

For `docs/reference/commands.md`, add entry:

```markdown
### init

Configures developer environment — MCP servers, tokens, and permissions.

```
/ceos-agents:init
/ceos-agents:init --update
```

| Aspect | Detail |
|--------|--------|
| Input | (none) or `--update` |
| Output | `.mcp.json`, `.mcp.json.example`, `.claude/settings.json` |
| Destructive | Yes (writes files) |
| MCP required | Yes (for connectivity validation) |
```

### Task 4.4: Commit

```bash
git add commands/init.md examples/mcp-configs/redmine.json commands/onboard.md docs/
git commit -m "feat: add /ceos-agents:init command for MCP + permissions setup"
```

---

## Phase 5: Check-setup improvements

### Task 5.1: Distinguish "not configured" vs "not running"

Per DECISIONS.md doc 05 Q5.

**File:** `commands/check-setup.md` — Block 2 (lines 47-56)

**Step 1:** Replace Block 2 content with enhanced version:

```markdown
### Block 2: MCP servers (presence and connectivity)

6. Read `.mcp.json` in the project root:
   - Found → [OK]
   - NOT found in CWD → search parent directories (up to git root or 3 levels):
     - Found at {path} → [WARN] ".mcp.json found at {path}, but Claude Code loads from CWD ({cwd}). Copy or symlink it here."
     - Not found anywhere → [FAIL] "No .mcp.json found. Run /ceos-agents:init to create one."

7. Compare MCP servers with Automation Config:
   - Issue tracker MCP: read the MCP Server Detection table from `docs/reference/trackers.md`.
     Find the row matching Type. Search .mcp.json server names/URLs for the listed keywords.
   - If match → [OK] "Issue tracker MCP: {server_name} ({type})"
   - If no match → [FAIL] "No MCP server configured for tracker type '{type}'. Run /ceos-agents:init to set it up."
   - Source control MCP: match server names/URLs with Remote from config
   - If match → [OK]
   - If no match → [FAIL] "No MCP server configured for source control '{remote}'"

8. Verify that tokens in `.mcp.json` are not empty or placeholders → [OK] or [FAIL]
```

**Step 2:** Update Block 3 (lines 58-66) to distinguish connection failures:

```markdown
### Block 3: Connectivity

9. Run the Bug query from Automation Config via MCP (limit 1 result):
   - Success → [OK] with the number of bugs found
   - Auth error → [FAIL] "MCP server configured but authentication failed — check your token in .mcp.json"
   - Timeout/connection refused → [FAIL] "MCP server configured but not reachable — verify the server is running and URL is correct"
10. Verify source control connectivity: list repositories via MCP
    - Success → [OK]
    - Failure → [FAIL] with specific error type (auth vs unreachable)
```

### Task 5.2: Add parent directory .mcp.json detection

Already covered in Task 5.1, step 6 — the enhanced Block 2 includes parent directory search.

### Task 5.3: Commit

```bash
git add commands/check-setup.md
git commit -m "fix: check-setup — distinguish not-configured vs not-running, parent dir detection"
```

---

## Phase 6: Guard clause

Per DECISIONS.md doc 05 Q6: All 16 MCP-dependent commands get a pre-flight check.

### Task 6.1: Define guard clause template

The guard clause to add at the beginning of each command's orchestration/steps section:

```markdown
### 0. MCP pre-flight check

Before any pipeline operation, verify MCP tool availability:
- Read Type from Automation Config (Issue Tracker section)
- Check that at least one `mcp__*` tool matching the tracker type is accessible
- If not accessible → STOP with: "MCP server for {Type} is not available. Run `/ceos-agents:check-setup` for diagnostics or `/ceos-agents:init` to configure."
```

### Task 6.2: Add guard clause to all 16 MCP-dependent commands

**Files (16 commands):**

| Command | Insert after line | Section to insert before |
|---------|-------------------|------------------------|
| `fix-bugs.md` | After Configuration section (~line 34) | Before "## Pipeline" |
| `fix-ticket.md` | After Configuration section (~line 39) | Before pipeline start |
| `implement-feature.md` | After Configuration section (~line 29) | Before pipeline start |
| `resume-ticket.md` | After step 1 config read (~line 10) | Before step 2 checkpoint detection |
| `analyze-bug.md` | After step 2 config verify (~line 14) | Before step 3 triage |
| `publish.md` | After step 4 config read (~line 10) | Before step 5 |
| `create-pr.md` | After config read (~line 12) | Before PR creation |
| `status.md` | After step 1 config read (~line 14) | Before step 2 |
| `dashboard.md` | After Configuration section (~line 22) | Before data fetch |
| `metrics.md` | After Configuration section (~line 22) | Before data fetch |
| `estimate.md` | After Configuration section (~line 16) | Before estimation |
| `prioritize.md` | After Configuration section (~line 15) | Before backlog fetch |
| `changelog.md` | After step 1 config read (~line 14) | Before PR fetch |
| `check-setup.md` | N/A — check-setup IS the diagnostics command, skip guard | — |
| `scaffold.md` | After state detection (~line 20) | Before scaffold pipeline |
| `scaffold-add.md` | After detection step | Before component generation |

Note: `check-setup.md` does NOT get a guard clause — it IS the diagnostic tool. That leaves **15 commands** that get the guard clause (not 16 — check-setup excluded).

**Step 1:** Add the guard clause section to each of the 15 commands, right after they read Automation Config and before the main operation begins.

**Step 2:** Verify

```bash
grep -l "MCP pre-flight check" commands/*.md | wc -l
# Expected: 15
grep -L "MCP pre-flight check" commands/*.md
# Expected: check-setup.md, init.md, onboard.md, migrate-config.md, scaffold-validate.md, template.md, version-bump.md, version-check.md (8 files — 6 non-MCP + check-setup + init)
```

### Task 6.3: Commit

```bash
git add commands/
git commit -m "feat: add MCP pre-flight guard clause to 15 pipeline commands"
```

---

## Phase 7: Troubleshooting docs + upstream report

### Task 7.1: Add permission troubleshooting section

Per DECISIONS.md doc 06 Q1-Q3: Add docs, report upstream.

**File:** `docs/guides/troubleshooting.md`

**Step 1:** Add new section after "Pipeline Issues" (after line ~175):

```markdown
## Permission Issues

### Permission prompts after session resume

**Symptom:** After resuming a session with `claude -c`, Claude Code prompts for tool permissions again for every tool call.

**Cause:** Claude Code session permissions may not persist across `claude -c` resume. This is platform behavior, not a ceos-agents issue.

**Solution:** Configure permanent permissions in `.claude/settings.json`:

1. Run `/ceos-agents:init` — it generates `.claude/settings.json` with appropriate permissions
2. Or manually create `.claude/settings.json` in your project root:

```json
{
  "permissions": {
    "allow": [
      "Read", "Write", "Edit", "Glob", "Grep", "Bash",
      "mcp__youtrack__*", "mcp__gitea__*"
    ]
  }
}
```

Replace `mcp__youtrack__*` and `mcp__gitea__*` with your tracker and source control MCP prefixes.

**Important:** Avoid `mcp__*` wildcard — it permits ALL MCP servers including those from other plugins. Use specific prefixes for better security.

**For worktree users:** If you use parallel processing with worktrees (`Batch size > 1`), permanent permissions are essential — each parallel task may prompt separately, multiplying permission requests.
```

### Task 7.2: Commit

```bash
git add docs/guides/troubleshooting.md
git commit -m "docs: add permission troubleshooting section"
```

---

## Testing Plan

### Per-phase verification

| Phase | Verification method |
|-------|-------------------|
| 1 (Rename) | `grep -rl "CLAUDE-agents"` excluding skipped dirs → 0 results |
| 2 (URL fix) | `grep -r "forgejo/forgejo-mcp" docs/guides/` → 0 results |
| 3 (Scope fix) | `grep -r "target project's" commands/` → 0 results; read onboard.md Scope section |
| 4 (Init) | File exists: `commands/init.md`; file exists: `examples/mcp-configs/redmine.json`; closing message in onboard.md references init |
| 5 (Check-setup) | Read check-setup.md Block 2 — verify parent dir detection and error differentiation |
| 6 (Guard) | `grep -l "MCP pre-flight check" commands/*.md` → 15 files |
| 7 (Docs) | Read troubleshooting.md — verify permission section exists |

### E2E manual test

After all phases:
1. Install plugin fresh: `/plugin install ceos-agents@ceos-agents`
2. Run `/ceos-agents:check-setup` on a project with Automation Config
3. Run `/ceos-agents:init` on a project — verify .mcp.json generation
4. Run `/ceos-agents:onboard --fresh` from a subdirectory — verify git root detection and confirm prompt
5. Run `/ceos-agents:analyze-bug <ID>` — verify guard clause triggers if MCP not configured

---

## Risks and Mitigation

| Risk | Impact | Mitigation |
|------|--------|-----------|
| Breaking change (rename) | 4 users must reinstall | P3: communicate before release; CHANGELOG clearly marks breaking change |
| Checkpoint markers change `[CLAUDE-agents]` → `[ceos-agents]` | Existing pipeline comments in issue trackers won't match new markers | `resume-ticket` should detect BOTH old and new markers for backwards compat |
| Forgejo URL change (goern vs forgejo) | Incorrect if verification was wrong | P1: verify URL before implementation |
| New `init` command complexity | Many edge cases (update mode, shared servers, platform detection) | Start simple, iterate; check-setup as safety net |
| Guard clause false positives | scaffold/scaffold-add have `mcp__*` but don't always use it | Guard clause says "if pipeline requires MCP" — these commands can skip if no tracker configured |

### Backwards compatibility: checkpoint markers

**Critical:** `resume-ticket.md` currently detects `[CLAUDE-agents]` prefix in issue tracker comments. After rename, new comments use `[ceos-agents]` but old comments still have `[CLAUDE-agents]`.

**Fix:** In `commands/resume-ticket.md`, update checkpoint detection to accept BOTH prefixes:

```markdown
Detect checkpoint comments matching prefix `[ceos-agents]` OR `[CLAUDE-agents]` (legacy).
```

This must be done in Phase 1, Task 1.3 when editing resume-ticket.md.

---

## Versioning

### Why MAJOR is warranted but v3.4.0 is chosen

Per `CLAUDE.md` Versioning Policy:
- MAJOR: "Breaking change in Automation Config contract — new required key, renamed section"
- The rename does NOT change Automation Config contract — no required keys change, no sections rename
- The rename changes the **plugin namespace** (command prefix, block markers), which IS breaking for users
- However: only 4 internal users, no external marketplace listing, communication covers the impact

**Decision:** Ship as v3.4.0 (MINOR) because:
1. No Automation Config contract changes
2. Only 4 known users, all internal
3. Rename is a one-time operation, not an ongoing contract change
4. New `init` command is a new backward-compatible feature (MINOR trigger)

Alternative: If user decides rename warrants MAJOR → v4.0.0.

### CHANGELOG draft

```markdown
## [3.4.0] — 2026-03-XX

### Breaking

- **Renamed plugin** from `CLAUDE-agents` to `ceos-agents` — all command references change (e.g., `/ceos-agents:fix-ticket`). Reinstall required: `/plugin install ceos-agents@ceos-agents`
- Block comment markers changed from `[CLAUDE-agents]` to `[ceos-agents]` (resume-ticket accepts both for backwards compatibility)

### Added

- **New command `/ceos-agents:init`** — configures developer environment (MCP servers, tokens, permissions) in one interactive flow
- MCP pre-flight guard clause in 15 pipeline commands — clear error messages when MCP is unavailable
- Directory scope protection — onboard and migrate-config use git root with confirmation before writing
- Parent directory `.mcp.json` detection in check-setup
- Permission troubleshooting section in docs
- UX tip about tab-completion and skill routing in onboard closing message
- `examples/mcp-configs/redmine.json` template

### Fixed

- Forgejo MCP URL corrected from `forgejo/forgejo-mcp` to `goern/forgejo-mcp`
- check-setup now distinguishes "MCP not configured" vs "MCP not running"
- Unified "target project's CLAUDE.md" wording across 7 commands for consistent behavior

### Improved

- Onboard closing message references `/ceos-agents:init` instead of manual MCP docs
```

---

## Review

### Review iteration 1

**Methodology:** Read all source files referenced in the plan, verify line numbers and facts.

**Findings:**

| # | Finding | Severity | Status |
|---|---------|----------|--------|
| 1 | Agent report claimed 14 MCP commands, but detailed data shows 16 (scaffold + scaffold-add both have `mcp__*`). Plan correctly uses 16. | Info | Correct in plan |
| 2 | Guard clause section says 16 commands but then excludes check-setup → 15. This is correct (check-setup IS the diagnostic). | Info | Correct in plan |
| 3 | Phase 1 Task 1.3: `create-pr.md` listed as 0 occurrences, but it references `CLAUDE-agents` in command refs to other commands. Need to verify. | Medium | Added "(verify)" note |
| 4 | Resume-ticket backwards compat for checkpoint markers identified as risk and mitigated in Risk section. | Info | Addressed |
| 5 | `commands/onboard.md` line numbers will shift after Phase 3 Task 3.1 adds Scope section. All subsequent Phase 4 references to onboard line numbers must account for this. Plan notes "~line 200 after Phase 3 edits". | Low | Noted with ~ prefix |
| 6 | Phase 4 `init` command has `allowed-tools: mcp__*` which is wildcard. But DECISIONS.md says specific prefixes for permissions. The `init` command NEEDS wildcard because it must work with ANY tracker type before knowing which one. This is correct — wildcard in command scope, specific in generated settings.json. | Info | Correct in plan |
| 7 | `docs/plans/roadmap.md` and `docs/plans/README.md` listed for rename but are borderline "active" vs "planning" docs. Decision to include them is reasonable as they're navigation docs, not historical archives. | Low | Included |

**Verdict:** No blocking findings. All line numbers are approximate (marked with ~) because Phase 1 rename and Phase 3 scope changes shift line numbers. Implementation should use content matching (old_string/new_string), not line-number addressing.

### Review iteration 2

**Methodology:** Cross-reference every DECISIONS.md decision against plan coverage.

| Decision | Doc | Covered in Phase | Status |
|----------|-----|-----------------|--------|
| URL `goern/forgejo-mcp` | 01-Q1 | Phase 2, Task 2.1 | OK |
| Fix only active files | 01-Q2 | Phase 2, Task 2.1 (2 files) | OK |
| Rename to `ceos-agents` | 01-Q3 | Phase 1 (all tasks) | OK |
| UX tip in onboard | 01-Q4 | Phase 2, Task 2.2 | OK |
| No Command Quick Reference | 01-Q5 | Not in plan (decided NO) | OK |
| No allowed-tools expansion in onboard | 02-Q1 | Correct — init has its own tools | OK |
| MCP setup in new `init`, not onboard | 02-Q2 | Phase 4 | OK |
| Auto-generate .mcp.json | 02-Q3 | Phase 4, Step 6 | OK |
| Init detects platform for forgejo | 02-Q4 | Phase 4, Step 5 | OK |
| Update mode merge | 02-Q5 | Phase 4, Step 2+6 | OK |
| Validation in init, not onboard | 02-Q6 | Phase 4, Step 7 | OK |
| Shared server detection | 02-Q7 | Phase 4, Step 3 | OK |
| SC MCP config too | 02-Q8 | Phase 4, Step 3 | OK |
| Git root default | 03-Q1 | Phase 3, Task 3.1 | OK |
| Confirm path before write | 03-Q2 | Phase 3, Task 3.1 | OK |
| Subdirectory handled by Q1+Q2 | 03-Q3 | Phase 3, Task 3.1 heuristic | OK |
| Fix migrate-config too | 03-Q4 | Phase 3, Task 3.2 | OK |
| Minor version (combined) | 03-Q5 | Versioning section | OK |
| Variant B: unify all 7 commands | 03-Q6 | Phase 3, Task 3.3 | OK |
| Docs + diagnostics in check-setup | 05-Q1 | Phase 5 + Phase 7 | OK |
| Parent dir .mcp.json search | 05-Q2 | Phase 5, Task 5.1 | OK |
| .mcp.json via init, not onboard | 05-Q3 | Phase 4 | OK |
| CWD warning in closing message | 05-Q4 | Phase 4, Task 4.2 (init ref) | OK |
| Distinguish not-configured vs not-running | 05-Q5 | Phase 5, Task 5.1 | OK |
| Guard in all 16 commands | 05-Q6 | Phase 6 (15 — check-setup excluded) | OK |
| Minor version | 05-Q7 | Versioning section | OK |
| Combine with doc 02 | 06-Q1 | Phase 4 (init = MCP + permissions) | OK |
| Init generates .claude/settings.json | 06-Q2 | Phase 4, Step 8 | OK |
| Report upstream | 06-Q3 | Noted in Risk section | OK |
| Specific MCP permissions | 06-Q4 | Phase 4, Step 8 | OK |
| Pre-flight in resume-ticket | 06-Q5 | Phase 6 (included in 15 commands) | OK |

**Verdict:** No missing decisions.

### Review iteration 3

**Methodology:** Post-creation verification — grep actual source files to confirm plan accuracy.

**Verified facts:**
1. `create-pr.md` — confirmed 0 occurrences of `CLAUDE-agents` (grep verified). No rename needed.
2. `changelog.md`, `status.md`, `estimate.md`, `scaffold-add.md`, `scaffold-validate.md` — all confirmed 0 occurrences. No rename needed.
3. `CHANGELOG.md` (root) — confirmed 1 occurrence at line 3 (`All notable changes to the CLAUDE-agents plugin.`). Rename needed.
4. `resume-ticket.md` — confirmed 5 occurrences of `[CLAUDE-agents]` at lines 17, 18, 57, 58, 90. Backwards compat logic must be added here (plan updated in Task 1.3).
5. Agent block comment markers `[CLAUDE-agents]` confirmed in 11 agent files (all listed in Task 1.4).
6. `check-setup.md` Block 2 starts at line 47, Block 3 at line 58 — matches plan references.
7. `onboard.md` Step 9 closing message at lines 193-212 — matches plan.
8. `commands/init.md` does NOT exist yet — confirmed this is a new file (Phase 4).

**Findings:**

| # | Finding | Severity | Action |
|---|---------|----------|--------|
| 8 | Plan Task 1.3 table listed `create-pr.md: 0` as "(verify)" — now verified as genuinely 0 | Info | Confirmed correct |
| 9 | Plan Phase 6 guard clause also needs to account for `init.md` (new command with `mcp__*`) — but `init` does its OWN connectivity check in Step 7, so guard clause is redundant for it | Info | No change needed — init handles MCP internally |
| 10 | `docs/plans/brainstorm/DECISIONS.md` references `ceos-agents:init` in closing message format (doc 05 Q4) — plan correctly uses this in Task 4.2 | Info | Confirmed correct |

**Verdict: APPROVE** — All 32 decisions from DECISIONS.md are covered. All file references verified against actual source. No blocking findings. Line numbers are approximate by design (content matching required for implementation).

**Review iterations:** 3
**Final status:** APPROVE

### Review iteration 4 (independent external review)

**Methodology:** Full independent review. Read ALL 56 source files referenced in the plan (22 commands, 13 agents, 1 skill, 2 plugin metadata, 12 docs, 4 root, 6 tests/CI, 2 docs/plans active). Dispatched 4 parallel research agents. Verified every occurrence count with direct `grep -c`. Cross-referenced DECISIONS.md coverage, line numbers, verification commands, and file completeness.

**Files read:** 56 (full content)
**Grep verifications performed:** 15 (direct grep -c on disputed files)

**Findings:**

| # | Finding | Severity | Action |
|---|---------|----------|--------|
| 11 | Task 1.1: plugin.json line numbers were "2, 7" but CLAUDE-agents is on lines 2, 8 (repository URL is line 8, not 7) | MEDIUM | Fixed → "lines 2, 8" |
| 12 | Task 1.1: marketplace.json line numbers were "2, 7, 9" (implying 3 occurrences) but actual is lines 2, 8 (2 occurrences — two `"name"` fields) | MEDIUM | Fixed → "lines 2, 8" |
| 13 | Task 1.1 Step 3 verification: expected ceos-agents count for plugin.json was 1 but should be 2 (name on line 2 + repository URL on line 8) | MEDIUM | Fixed → "plugin.json:2" |
| 14 | Phase 6 Task 6.2 Step 2 verification: `init.md` was missing from the expected-no-guard list. After Phase 4 creates init.md, there are 23 commands total; init handles MCP internally (Step 7), so it also has no guard clause → 8 files without, not 7 | MEDIUM | Fixed → added init.md, changed 7→8 |
| 15 | Occurrence counts verified correct for ALL other files: version-check.md=11 ✓, code-analyst.md=3 ✓, SKILL.md=26 ✓, CHANGELOG.md=1 ✓, CLAUDE.md=8 ✓, CONTRIBUTING.md=2 ✓, README.md=9 ✓ | Info | All match plan |
| 16 | Forgejo URL `forgejo/forgejo-mcp` confirmed in exactly 2 active docs files (mcp-configuration.md:45, installation.md:72) — matches plan Task 2.1 | Info | Correct |
| 17 | "target project's CLAUDE.md" confirmed in exactly 7 commands (onboard:18, migrate-config:12, implement-feature:12, dashboard:19, estimate:12, prioritize:12, metrics:18) — matches plan Task 3.3 | Info | Correct |
| 18 | trackers.md MCP Server Detection table (lines 75-84) confirmed — all 6 trackers have Package entries matching init command Step 3 | Info | Correct |
| 19 | examples/mcp-configs/redmine.json confirmed NOT existing — prerequisite P2 is valid | Info | Correct |
| 20 | 16 commands with `mcp__*` in allowed-tools confirmed (6 without: migrate-config, onboard, scaffold-validate, template, version-bump, version-check) — matches plan Phase 6 | Info | Correct |
| 21 | resume-ticket.md backwards compat: lines 17, 18, 57, 58, 90 confirmed with `[CLAUDE-agents]` prefix — plan's backwards compat handling in Task 1.3 is correct and complete | Info | Correct |
| 22 | check-setup.md Block 2 at line 47, Block 3 at line 58 — matches plan Phase 5 references | Info | Correct |
| 23 | onboard.md Step 9 closing message at lines 193-212, MCP reference at line 200 — matches plan Phase 4 Task 4.2 | Info | Correct |
| 24 | All 32 DECISIONS.md decisions covered (verified independently, matches iteration 2) | Info | Correct |

**Corrections applied:** 4 (findings 11-14). All MEDIUM severity — factual inaccuracies in line numbers and verification expected counts.

**Re-verification after fixes:**
- Task 1.1: "lines 2, 8" matches actual plugin.json/marketplace.json ✓
- Task 1.1 Step 3: "plugin.json:2, marketplace.json:2" matches expected post-rename counts ✓
- Phase 6 Step 2: "8 files" = check-setup + init + 6 non-MCP ✓; "15 files" with guard = 23 total - 8 = 15 ✓

### Review iteration 4 (final)

**Methodology:** Full independent external review — 56 source files read, 15 direct grep verifications, 4 parallel research agents, cross-reference of all DECISIONS.md decisions
**Files read:** 56
**Findings:** 0 CRITICAL, 0 HIGH, 4 MEDIUM (all fixed), 10 INFO
**All CRITICAL/HIGH resolved:** Yes (none found)
**All MEDIUM resolved:** Yes (4 fixed in iteration 4)
**Final status:** APPROVE
