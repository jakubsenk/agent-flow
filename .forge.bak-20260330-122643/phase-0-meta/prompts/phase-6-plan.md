# Phase 6 — Implementation Plan

## Overview

Implement v5.6.0 — Scaffold Infrastructure Polish. Six items, all additive markdown changes to a pure markdown plugin (no code, no build system). The items have inter-dependencies due to shared target files (especially `commands/scaffold.md`).

## Task Decomposition

### Task 1: Create `core/mcp-detection.md` (NEW FILE)
**Priority:** 1 (prerequisite for Tasks 2 and 3)
**Files:** `core/mcp-detection.md` (create)
**Depends on:** nothing

Create a new core contract file following the exact format of `core/config-reader.md`:

```
# MCP Detection

## Purpose
Determine the expected MCP package and tool prefix for a given tracker type, then verify accessibility and connectivity. Single source of truth for MCP detection logic — referenced by commands/scaffold.md (Step 0-MCP) and commands/init.md (Steps 3+7).

## Input Contract
- **tracker_type** (string, required): Issue tracker type (youtrack/github/jira/linear/gitea/redmine)
- **tracker_instance** (string, optional): Instance URL for connectivity check
- **service_type** (string, required): "tracker" or "sc" — which service is being checked
- **check_write** (boolean, optional, default: false): If true, perform canary-write check after read check

## Process
1. Look up MCP package and tool prefix from the MCP Server Detection table in docs/reference/trackers.md:
   - youtrack → package: @vitalyostanin/youtrack-mcp, prefix: mcp__youtrack__*
   - github → package: @modelcontextprotocol/server-github, prefix: mcp__github__*
   - jira → package: @modelcontextprotocol/server-atlassian, prefix: mcp__jira__* or mcp__atlassian__*
   - linear → package: @modelcontextprotocol/server-linear, prefix: mcp__linear__*
   - gitea → package: forgejo-mcp, prefix: mcp__gitea__* or mcp__forgejo__*
   - redmine → package: mcp-server-redmine, prefix: mcp__redmine__*
   - Unknown → prefix: mcp__{tracker_type}__* (best-effort)

2. Check that at least one tool matching the prefix is accessible in the current session.

3. If tool found — verify connectivity:
   - Tracker: attempt a lightweight read operation (list 1 issue from project, or list projects)
   - SC: attempt to verify the declared remote exists
   - If connectivity fails: return mcp_available: false with error details

4. If check_write is true AND read check passed:
   - Create a canary item (test issue/card with title "[ceos-agents] canary — safe to delete")
   - If create succeeds: delete the canary item immediately
   - If create fails: return write_available: false (read still true)
   - If delete fails after successful create: log warning, return write_available: false

## Output Contract
- **mcp_available** (boolean): true if MCP tool is accessible and read connectivity succeeds
- **write_available** (boolean or null): true if canary-write succeeded, false if it failed, null if not tested
- **package_name** (string): Expected MCP package name
- **tool_prefix** (string): Expected tool prefix pattern
- **error** (string or null): Error message if mcp_available is false

## Failure Handling
- **No matching MCP tool found:** Return mcp_available: false. Caller decides whether to block or downgrade.
- **Read connectivity fails:** Return mcp_available: false with error details.
- **Write canary fails:** Return mcp_available: true, write_available: false. Caller decides action (warn, downgrade, block).
- **Unknown tracker type:** Attempt detection with derived prefix. Return mcp_available: false only if tool is actually missing.
```

Note: Unlike `core/mcp-preflight.md` which BLOCKs on failure, this contract returns results and lets the caller decide. This is intentional — scaffold downgrades while implement-feature blocks.

### Task 2: Refactor `commands/scaffold.md` Step 0-MCP to reference `core/mcp-detection.md`
**Priority:** 2
**Files:** `commands/scaffold.md`
**Depends on:** Task 1

In `commands/scaffold.md`, update the Step 0-MCP section:
- Replace the inline MCP detection logic (steps 1-4 of current Step 0-MCP) with a reference: "Follow `core/mcp-detection.md` to determine MCP availability."
- Keep the scaffold-specific behavior (downgrade prompts, YOLO auto-downgrade, --issue fallback) in scaffold.md
- Remove the inline "Determine expected MCP package" and "Check MCP tool accessibility" logic — that now lives in core/mcp-detection.md
- Keep the sync comment: `<!-- MCP detection logic: see core/mcp-detection.md -->`

### Task 3: Refactor `commands/init.md` Steps 3+7 to reference `core/mcp-detection.md` + Add `.mcp.json.example` detection
**Priority:** 2
**Files:** `commands/init.md`
**Depends on:** Task 1

Two changes to init.md:

**3a. MCP detection refactor (Item 1):**
- In Step 3 ("Determine MCP servers needed"): Replace the inline MCP package lookup table with a reference: "For each required MCP server, follow `core/mcp-detection.md` (with `check_write: false`) to determine the expected package name and tool prefix."
- Keep the init-specific logic (shared server detection, platform handling) in init.md
- In Step 7 ("Validate connectivity"): Replace inline connectivity check with: "For each configured MCP server with non-placeholder tokens, follow `core/mcp-detection.md` connectivity check."

**3b. `.mcp.json.example` detection (Item 2):**
- Add a new Step 1b between Steps 1 and 2: "Detect `.mcp.json.example`"
- Logic:
  1. Check if `.mcp.json.example` exists in CWD
  2. If found: parse it to extract tracker type (from MCP server package name), instance URL (from env vars), and remote (from SC server config)
  3. Pre-fill Step 3 values from parsed data. Display: "Detected .mcp.json.example from previous /scaffold run. Pre-filling configuration: Tracker: {type}, Instance: {url}, Remote: {remote}"
  4. User can still override any pre-filled value at the token collection step
  5. If `.mcp.json.example` not found: no action (graceful fallback, no warning needed)

### Task 4: Add `infrastructure` field to `state/schema.md` and `core/state-manager.md`
**Priority:** 1 (independent, can run parallel with Task 1)
**Files:** `state/schema.md`, `core/state-manager.md`
**Depends on:** nothing

**4a. state/schema.md:**
- Add `infrastructure` field to the Full Schema Example JSON, after `config`:
  ```json
  "infrastructure": {
    "tracker_status": "ready",
    "tracker_type": "gitea",
    "tracker_instance": "https://gitea.example.com",
    "tracker_project": "owner/repo",
    "sc_status": "later",
    "sc_remote": null,
    "sc_base_branch": "main"
  }
  ```
- Add field definitions to the Top-Level Field Definitions table:
  | Field | Type | Required | Default | Description |
  |-------|------|----------|---------|-------------|
  | `infrastructure` | object or null | No | `null` | Infrastructure declarations from Step 0-INFRA. Persists tracker and SC readiness status for resume. Only populated by scaffold pipeline. |
  | `infrastructure.tracker_status` | string | No | `null` | Tracker readiness: `"ready"`, `"later"`, or `"downgraded"` |
  | `infrastructure.tracker_type` | string or null | No | `null` | Declared tracker type |
  | `infrastructure.tracker_instance` | string or null | No | `null` | Declared tracker instance URL |
  | `infrastructure.tracker_project` | string or null | No | `null` | Declared tracker project |
  | `infrastructure.sc_status` | string | No | `null` | SC readiness: `"ready"`, `"later"`, or `"downgraded"` |
  | `infrastructure.sc_remote` | string or null | No | `null` | Declared SC remote (owner/repo) |
  | `infrastructure.sc_base_branch` | string | No | `"main"` | Declared base branch |

**4b. core/state-manager.md:**
- In the Write Operation input contract, add: "Fields include all top-level sections from `state/schema.md` including the optional `infrastructure` object."
- No structural changes needed — the dot-notation path system already supports arbitrary fields (e.g., `infrastructure.tracker_status`)

### Task 5: Add `--infra` flag to `commands/scaffold.md`
**Priority:** 3
**Files:** `commands/scaffold.md`
**Depends on:** Task 2 (scaffold.md already modified), Task 4 (infrastructure state field exists)

In `commands/scaffold.md`:

**5a. Flag Parsing section:**
- Add: `--infra <value>` → `infra_preset` (format: `{tracker},{sc}` where each is `ready` or `later`)
- Example: `--infra ready,later` → tracker preset = ready, SC preset = later

**5b. Flag Validation section:**
- Add: If `--infra` provided but format is not `{ready|later},{ready|later}` → Error: "Invalid --infra format. Use: --infra ready,later or --infra later,later"

**5c. Step 0-INFRA:**
- If `infra_preset` is set: skip the interactive questions, use preset values
- Display: `Infrastructure preset: tracker={tracker}, SC={sc} (from --infra flag)`
- If `--infra ready,*` but no `--issue`: still ask for tracker type, instance, project (unless also provided via other flags in a future version)
- Proceed directly to Step 0-MCP

**5d. State persistence:**
- After Step 0-INFRA completes (whether interactive or from --infra flag), write infrastructure state:
  ```
  state.json → infrastructure.tracker_status = tracker_effective_status
  state.json → infrastructure.tracker_type = tracker_type
  state.json → infrastructure.tracker_instance = tracker_instance
  state.json → infrastructure.tracker_project = tracker_project
  state.json → infrastructure.sc_status = sc_effective_status
  state.json → infrastructure.sc_remote = sc_remote
  state.json → infrastructure.sc_base_branch = sc_base_branch
  ```
- Follow atomic write protocol from `core/state-manager.md`

### Task 6: Add canary-write check to `commands/scaffold.md` Step 0-MCP
**Priority:** 3
**Files:** `commands/scaffold.md`
**Depends on:** Task 2 (scaffold.md already has core/mcp-detection.md reference)

In `commands/scaffold.md` Step 0-MCP, after the current step 4 (connectivity verification):

Add step 4b: **Canary-write check (tracker only)**

- Only runs if `tracker_effective_status` is `"ready"` AND tracker MCP connectivity passed
- Follow `core/mcp-detection.md` with `check_write: true`
- If `write_available: false`:
  - Display warning: `Tracker MCP has read access but write access failed. Issue creation at Step 4e may fail.`
  - Display: `Continue with read-only tracker? Step 4e (create tracker issues) will be skipped. [Y/n]`
  - Y → set `tracker_write_available = false` (Step 4e will check this and skip)
  - n → re-check
  - **In Full YOLO mode:** auto-downgrade write capability. Display: `Tracker write access unavailable — Step 4e will be skipped.`
- If `write_available: true`: proceed normally, set `tracker_write_available = true`

Update Step 4e guard clause to include: `tracker_write_available` is false → skip

### Task 7: Add YOLO+no-MCP block to `commands/scaffold.md` and `commands/implement-feature.md`
**Priority:** 3
**Files:** `commands/scaffold.md`, `commands/implement-feature.md`
**Depends on:** Task 2 (scaffold.md already modified)

**7a. scaffold.md — Step 0-MCP, modify step 3 (MCP tool not found):**
- Current behavior in Full YOLO mode: auto-downgrade without prompt
- New behavior: If `--issue` flag was provided AND mode is Full YOLO AND MCP tool not found:
  - **BLOCK** instead of downgrading:
    ```
    [ceos-agents] 🔴 Pipeline Block
    Agent: scaffold
    Step: Step 0-MCP
    Reason: Cannot use --issue in Full YOLO mode without MCP server.
    Detail: --issue requires tracker MCP to fetch issue description. MCP server for "{tracker_type}" is not available. In YOLO mode, there is no interactive fallback to ask for a project description.
    Recommendation: Either remove --issue and provide a project description, or configure the MCP server first (run /ceos-agents:init).
    ```
  - STOP scaffold entirely.
- If `--issue` is NOT provided: keep existing auto-downgrade behavior in YOLO mode.

**7b. implement-feature.md — Step 0 MCP pre-flight check:**
- Current behavior: always blocks on MCP failure (STOP)
- New behavior: If `--yolo` flag AND `--description` flag AND MCP failure:
  - **BLOCK** with explicit message:
    ```
    [ceos-agents] 🔴 Pipeline Block
    Agent: implement-feature
    Step: MCP pre-flight check
    Reason: Cannot create tracker card without MCP server in YOLO mode.
    Detail: --description requires tracker MCP to create the issue card. MCP server for "{Type}" is not available. In YOLO mode, there is no interactive fallback.
    Recommendation: Either configure the MCP server first (run /ceos-agents:init), or create the issue manually and pass the Issue ID instead of --description.
    ```
- This replaces the generic MCP failure message with a context-specific one when --yolo + --description are combined.

### Task 8: Update documentation and metadata
**Priority:** 4 (last)
**Files:** `docs/plans/roadmap.md`, `CHANGELOG.md`, `CLAUDE.md` (core/ count update)
**Depends on:** Tasks 1-7

**8a. roadmap.md:**
- Move the "PLANNED — v5.5.1+ (Scaffold Infrastructure Follow-ups)" section items that are implemented (items 1-6) to a new "DONE — v5.6.0 (Scaffold Infrastructure Polish)" section
- Keep "Commands-to-Skills Architecture Evaluation" in PLANNED (not part of this release)

**8b. CHANGELOG.md:**
- Add `## [5.6.0] — {date}` entry at the top
- **MINOR** — Scaffold Infrastructure Polish
- Added: core/mcp-detection.md, init.md .mcp.json.example detection, state.json infrastructure field, --infra CLI flag, Step 0-MCP canary-write check, YOLO+no-MCP blocking
- Changed: scaffold.md Step 0-MCP refactored to reference core contract, init.md Steps 3+7 refactored
- Details: 19 agents (unchanged), 25 commands (unchanged), 11 core contracts (was 10)

**8c. CLAUDE.md:**
- Update core/ count from 10 to 11 in the Repository Structure section

## Dependency Graph

```
Task 1 (core/mcp-detection.md) ──┬──→ Task 2 (scaffold refactor) ──→ Task 5 (--infra flag) ──→ Task 6 (canary-write) ──→ Task 7a (YOLO block scaffold)
                                 │
                                 └──→ Task 3 (init refactor + .mcp.json.example)
                                       └──→ Task 3b (merged into Task 3)

Task 4 (state schema) ──────────────→ Task 5 (--infra flag writes state)

Task 7b (YOLO block implement-feature) — independent of scaffold.md tasks

Task 8 (docs) ──→ depends on all above
```

## Parallelization Plan

**Batch 1 (parallel):**
- Task 1: Create core/mcp-detection.md
- Task 4: Update state/schema.md + core/state-manager.md

**Batch 2 (parallel, after Batch 1):**
- Task 3: Refactor init.md + add .mcp.json.example detection
- Task 7b: Add YOLO+no-MCP block to implement-feature.md

**Batch 3 (sequential, after Batch 1 — scaffold.md is single-writer):**
- Tasks 2, 5, 6, 7a: All scaffold.md changes in one coordinated edit

**Batch 4 (after all):**
- Task 8: Documentation updates
