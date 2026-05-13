# Scaffold Infrastructure Integration — Design

**Status:** PROPOSED
**Target version:** v5.5.0 (MINOR — new optional behavior, no breaking changes)
**Date:** 2026-03-27

## Problem

After `/scaffold` completes (Step 4: Git init → Step 4b: Tracker Configuration → Step 4c: MCP Guidance), the project is in a dead state:

1. **Step 4b** asks for tracker/SC values, writes them to CLAUDE.md, but does nothing else — no MCP setup, no connectivity check, no repo push
2. **Step 4c** prints informational text "run `/init`" — never actually runs it
3. **Step 9** creates tracker cards AFTER implementation — too late to be useful
4. No MCP verification during scaffold — `/check-setup` shows all FAIL after scaffold

The user ends up with a CLAUDE.md that has config values but zero working infrastructure.

## Constraints

- MCP servers **cannot** create tracker projects (YT/Jira/Linear/Redmine)
- MCP servers for GitHub and Gitea/Forgejo **can** manage repositories (create, push, PR)
- MCP servers configured in parent context (globally or project-level) **are available** during the scaffold session
- `.mcp.json` in the new project directory is needed for **future sessions** only
- Tracker and SC are **independent** — user may have one, both, or neither

## Design

### New Step 0-INFRA: Infrastructure Declaration

Replaces the current Step 4b and Step 4c. Moves to the **very beginning** of scaffold, before Mode Selection.

```
Before we scaffold, tell me about your infrastructure:

1. Issue tracker:
   (a) I have a tracker project ready
   (b) Not now — I'll set it up later via /init + /onboard

2. Source control:
   (a) I have a git repo ready
   (b) Not now — I'll set it up later
```

Four possible combinations, all valid:

| Tracker | SC | Behavior |
|---|---|---|
| (a) ready | (a) ready | Full integration — verify MCP, auto-fill config, create issues, push |
| (a) ready | (b) later | Tracker integration only — verify tracker MCP, create issues, git stays local |
| (b) later | (a) ready | SC integration only — verify SC MCP, push to remote, no tracker issues |
| (b) later | (b) later | Fully local scaffold — TODO markers in CLAUDE.md, user adds via `/init` + `/onboard --update` later |

### New Step 0-MCP: MCP Verification

Runs immediately after Step 0-INFRA. Only checks what the user declared as "ready".

For each declared "ready" service:

1. **Detect** MCP server in current session (scan available `mcp__*` tools)
2. **If missing** → offer: "MCP server for {type} not found. Run `/init` now? [Y/n]"
   - Y → run `/init` inline (just the relevant parts — tracker MCP, SC MCP, or both)
   - N → downgrade to "later" (revert to option b for this service)
3. **Verify connectivity** (hard gate):
   - Tracker: query 1 issue from declared project → OK/FAIL
   - SC: list repos or verify declared repo exists → OK/FAIL
   - FAIL → "Connectivity failed. Fix now / Continue without {service} / Abort"
4. **Collect details** (only for "ready" services):
   - Tracker: project key, optional starting epic (`--issue PROJ-1`)
   - SC: remote (owner/repo)

### Modified Step 4: Git Init + Auto-Config

After skeleton is generated and committed:

1. **CLAUDE.md auto-fill** — for "ready" services, fill values automatically from Step 0-MCP data (no TODO markers). For "later" services, keep TODO markers.
2. **Generate `.mcp.json`** for the new project directory:
   - Derive from detected MCP servers in session
   - Tokens: use `<YOUR_*>` placeholders (security — never copy real tokens)
   - Generate `.mcp.json.example` alongside
   - Add `.mcp.json` to `.gitignore`
3. **Commit config**: `git add CLAUDE.md .mcp.json.example .gitignore && git commit -m "chore: configure Automation Config"`

### New Step 4d: Push to Remote (if SC ready)

Only runs if SC was declared "ready" and connectivity verified:

```bash
git remote add origin {remote_url}
git push -u origin {base_branch}
```

If push fails → WARN (do not block scaffold).

### New Step 4e: Create Tracker Issues (if tracker ready)

Only runs if tracker was declared "ready" and connectivity verified:

1. For each `spec/epics/*.md` → create issue in tracker project
2. For each user story within epic → create sub-issue
3. Write issue IDs back into spec files as reference comments
4. Commit: `git commit -m "chore: link spec epics to tracker issues"`

**Important:** This step ONLY runs during scaffold if user chose "ready" at Step 0-INFRA. If user chose "later", no tracker issues are ever created retroactively for scaffold epics. Tracker integration starts with future `/implement-feature` or `/fix-bugs` calls.

### Removed Steps

- **Step 4b** (Tracker Configuration) → replaced by Step 0-INFRA + Step 4 auto-fill
- **Step 4c** (MCP Guidance) → replaced by Step 0-MCP inline `/init`
- **Step 9** (Issue Tracker Optional) → replaced by Step 4e (moved before implementation)

### Spec Phase Questions

When using `--issue` flag (starting from a tracker epic), spec-reviewer questions are handled **in the chat** (Interactive mode), not posted to the tracker. Tracker comments add complexity and latency without clear benefit.

## Impact on Existing Steps

| Step | Change |
|------|--------|
| Step 0 (Mode Selection) | Moves after Step 0-INFRA and Step 0-MCP |
| Step 0b (Brainstorming) | No change |
| Step 1 (Specification) | No change — `--issue` input source works as before |
| Step 2 (Spec Checkpoint) | No change |
| Step 3 (Scaffold Skeleton) | No change |
| Step 4 (Git Init) | Extended with auto-fill + `.mcp.json` generation |
| Step 4b | **REMOVED** — replaced by Step 0-INFRA |
| Step 4c | **REMOVED** — replaced by Step 0-MCP |
| Step 4d | **NEW** — Push to remote |
| Step 4e | **NEW** — Create tracker issues (moved from Step 9) |
| Step 5-8 | No change |
| Step 9 | **REMOVED** — replaced by Step 4e |
| Step 10 (Report) | Updated to show infrastructure status |

## Modified Step 10: Report

```
## Scaffold Complete

**Project:** {name}
**Mode:** {mode}
**Stack:** {stack}

### Infrastructure
  Tracker: ✅ Connected (YouTrack @ instance — PROJ, 5 epics created)
  SC:      ✅ Pushed (gitea.internal/org/repo — main)
  MCP:     ✅ .mcp.json.example generated (fill tokens for future sessions)

### Implementation
  Features: {implemented} / {total} ({blocked} blocked)
  Tests: {unit} unit, {e2e} e2e
  Commits: {count}

### Next steps:
1. Fill tokens in .mcp.json (copy from .mcp.json.example)
2. Run /ceos-agents:check-setup to verify
3. Use /ceos-agents:implement-feature for new features
```

For "later" services:
```
  Tracker: ⏳ Not configured — run /ceos-agents:init + /ceos-agents:onboard --update
  SC:      ⏳ Not configured — run /ceos-agents:init
```

## Full YOLO Mode Behavior

In Full YOLO mode, Step 0-INFRA question is still asked (it cannot be skipped — infrastructure is a prerequisite decision, not a quality gate). However:

- If user declared "ready" → proceed without confirmations in all subsequent steps
- If user declared "later" → scaffold runs fully locally with no stops

## --no-implement Legacy Flow

The `--no-implement` flow (L1-L6) remains unchanged. Step 0-INFRA is added before L1 but the legacy flow does not create tracker issues (no spec/epics to create from).

## Versioning

MINOR (v5.5.0):
- New optional behavior at scaffold start
- No changes to Automation Config contract
- No new required keys
- Existing scaffold invocations without flags work identically (user just gets the new question at start)
