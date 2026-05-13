# Phase 0 Analysis: Scaffold MCP Setup Chicken-and-Egg Bug

## Problem Statement

When `/scaffold` runs in a project that needs both a tracker (e.g., YouTrack) and source control (e.g., Gitea), Step 0-MCP detects that MCP servers are not configured. It correctly identifies the gap, but has no mechanism to fix it. The natural fix path (`/init`) requires reading `## Automation Config` from CLAUDE.md -- but CLAUDE.md does not exist yet because scaffold has not created it.

**Result:** The LLM goes off-script, creates `.mcp.json` with placeholder tokens, marks infrastructure as "ready" in state.json, but the MCP servers cannot actually connect. The pipeline stalls. No CLAUDE.md is ever generated.

**Real-world evidence (licence-ceos-agents-yt):**
- `.mcp.json` exists with `<YOUR_YOUTRACK_TOKEN>` and `<YOUR_GITEA_TOKEN>` -- placeholder tokens
- No `state.json` found (pipeline stalled before state persistence)
- No `CLAUDE.md` generated

## Root Cause

The init skill (`skills/init/SKILL.md`) Step 1 reads Automation Config from CLAUDE.md. If no Automation Config is found, it errors: "No Automation Config found. Run `/ceos-agents:onboard` first." This is the correct behavior for existing projects, but creates a circular dependency during scaffold:

```
scaffold needs MCP --> calls init --> init needs CLAUDE.md --> scaffold creates CLAUDE.md --> but MCP needed first
```

## Codebase Context Assessment

### Dependency Graph of Affected Files

```
skills/scaffold/SKILL.md (Step 0-MCP, Step 4b-replaced)
  |-- core/mcp-detection.md (MCP verification contract -- unchanged)
  |-- core/mcp-preflight.md (MCP preflight -- unchanged)
  |-- skills/init/SKILL.md (Step 1 reads CLAUDE.md -- NEEDS CHANGE)
  |   |-- core/mcp-detection.md
  |   |-- examples/mcp-configs/*.json (templates -- unchanged)
  |   +-- docs/reference/trackers.md (lookup tables -- unchanged)
  +-- state/schema.md (infrastructure object -- unchanged)
```

### Files That Change

| File | Change Type | Description |
|------|-------------|-------------|
| `skills/init/SKILL.md` | MODIFY | Add CLI parameters (`--tracker-type`, `--tracker-instance`, `--sc-remote`) as alternative to reading from CLAUDE.md. When these params are provided, skip CLAUDE.md reading entirely. |
| `skills/scaffold/SKILL.md` | MODIFY | Step 0-MCP: when MCP is unavailable, offer to call `/init` with CLI parameters from Step 0-INFRA in-memory variables instead of telling user "run /init later". |
| `docs/reference/skills.md` | MODIFY | Update init skill entry to document new CLI parameters. |

### Files That Do NOT Change

- `core/mcp-detection.md` -- detection/verification contract is correct as-is
- `core/mcp-preflight.md` -- preflight is correct as-is
- `core/config-reader.md` -- config parsing is correct, init bypass does not affect it
- `state/schema.md` -- infrastructure schema is correct
- `examples/mcp-configs/*.json` -- templates are correct
- `docs/reference/trackers.md` -- lookup tables are correct
- All agent definitions -- no agent changes needed
- `skills/check-setup/SKILL.md` -- reads from CLAUDE.md which exists in its context
- `skills/onboard/SKILL.md` -- generates CLAUDE.md, does not read MCP
- `skills/resume-ticket/SKILL.md` -- MCP preflight reads from existing CLAUDE.md

## Complexity Assessment

| Axis | Score (1-5) | Rationale |
|------|-------------|-----------|
| Scope | 2 | 2 skill files change (init, scaffold), 1 docs file gets minor update. No agents, no core contracts, no state schema. |
| Ambiguity | 2 | Solution direction is clear: add CLI params to init, call init from scaffold's Step 0-MCP. The only design question is the exact parameter names and how token collection works interactively during scaffold. |
| Risk | 2 | Init changes are additive (new optional params). Scaffold changes are in the MCP failure path only. Existing init behavior with no params is unchanged. Existing scaffold with "later" or "downgraded" paths are unchanged. |

**Overall: Low complexity (6/15)**

## Solution Direction Evaluation

### Approach A: Add CLI parameters to `/init` (RECOMMENDED)

Add optional parameters to init: `--tracker-type <type>`, `--tracker-instance <url>`, `--sc-remote <owner/repo>`.

When these params are provided:
1. Skip Step 1 (CLAUDE.md reading) entirely
2. Use the provided values directly for Steps 3-6 (MCP server determination, token collection, generation)
3. Steps 7-9 (validation, permissions, closing) work unchanged

Scaffold Step 0-MCP then calls init with these parameters when MCP is unavailable and user wants to set it up now.

**Pros:**
- No code duplication -- init remains the single source of truth for MCP setup
- Init stays backward-compatible (no params = existing behavior)
- Clear separation of concerns: scaffold collects infra intent, init handles MCP setup mechanics
- Parameters are useful beyond scaffold (any automation that knows its config can call init directly)

**Cons:**
- Session restart requirement: `.mcp.json` changes require Claude Code session restart for MCP tools to become available. Init can create the file, but scaffold cannot use MCP tools in the same session.

### Approach B: Scaffold creates .mcp.json directly (REJECTED)

Have scaffold Step 0-MCP create `.mcp.json` inline using the same template logic as init.

**Pros:**
- Simpler call path (no cross-skill invocation)

**Cons:**
- Duplicates init's template rendering, token collection, platform detection, and gitea binary handling logic
- Two places to maintain MCP setup logic -- violates DRY
- Still has the session restart problem

### Approach C: Scaffold creates temporary CLAUDE.md for init (REJECTED)

Have scaffold write a minimal CLAUDE.md with just the Issue Tracker and Source Control sections before calling init, then delete/replace it.

**Cons:**
- Fragile -- partial CLAUDE.md could confuse other detection logic
- Unnecessary complexity -- if we can pass params directly, why create a temp file?

### Session Restart Problem (applies to all approaches)

MCP servers in `.mcp.json` are loaded by Claude Code at session start. Creating/modifying `.mcp.json` mid-session does NOT make the MCP tools available immediately. This means:

1. Init creates `.mcp.json` with real tokens during scaffold
2. Step 0-MCP re-checks MCP availability
3. MCP tools are still not available (session was not restarted)
4. Scaffold must downgrade anyway

**Resolution:** This is acceptable. The fix ensures:
- `.mcp.json` is created with REAL tokens (not placeholders) during scaffold
- User is told to restart session and resume with `/scaffold` (state is preserved)
- On resume, Step 0-MCP re-runs, finds MCP tools available, continues
- This is strictly better than the current state where `.mcp.json` gets placeholders and the pipeline stalls

## Routing Decision

This is a **behavior fix** (PATCH level per versioning policy): no contract changes, no new required config keys, no new agents. The init skill gets new optional CLI parameters -- this is additive and backward-compatible.

**Pipeline:** Full pipeline (all phases). No phases need skipping.

## Implementation Summary

### init changes (skills/init/SKILL.md)

1. Add to frontmatter `argument-hint`: `"[--update] [--tracker-type <type>] [--tracker-instance <url>] [--sc-remote <owner/repo>]"`
2. Add new "Step 0: Parameter Override" before Step 1:
   - Parse `--tracker-type`, `--tracker-instance`, `--sc-remote` from $ARGUMENTS
   - If ANY of these params are provided: skip Step 1 (CLAUDE.md reading), use the param values directly
   - Missing params that can be inferred (e.g., instance URL from type defaults) use defaults from `docs/reference/trackers.md`
3. Step 3 (Determine MCP servers needed): accept override values alongside CLAUDE.md-derived values
4. All other steps unchanged -- token collection, platform handling, validation, permissions all work the same

### scaffold changes (skills/scaffold/SKILL.md)

1. Step 0-MCP, item 2 (mcp_available: false path): Add a new interactive option before the existing "Continue without {service}?" prompt:
   - "Would you like to configure {service} MCP now? I'll collect your API tokens and set up .mcp.json. [Configure / Skip / Abort]"
   - If Configure: invoke init with `--tracker-type {tracker_type} --tracker-instance {tracker_instance} --sc-remote {sc_remote}` (values from Step 0-INFRA)
   - After init completes: Display session restart guidance, downgrade to "later", continue
   - If Skip: existing downgrade behavior
   - If Abort: existing abort behavior
2. In Full YOLO mode: auto-invoke init with params (no interactive prompt), then auto-downgrade. Display restart guidance.
3. Step 9 (Final Report): if init was invoked during Step 0-MCP, add explicit restart+resume instructions to next steps
