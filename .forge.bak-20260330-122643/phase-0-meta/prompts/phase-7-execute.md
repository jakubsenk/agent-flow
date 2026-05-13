# Phase 7 — Execute

## Context

You are implementing v5.6.0 — Scaffold Infrastructure Polish for the ceos-agents plugin. This is a **pure markdown plugin** — there is NO code to compile, no dependencies to install. All "implementation" is writing/editing markdown files that define agent behavior and command orchestration for Claude Code.

## Critical Rules

1. **Pure markdown** — every file you create or edit is `.md`. No code, no scripts, no JSON (except state schema examples inside markdown).
2. **Follow existing patterns exactly** — core contracts use Purpose/Input/Output/Failure format. Commands use step numbering. State fields use the table format.
3. **No breaking changes** — this is v5.6.0 MINOR. No new required Automation Config keys. No changed agent output formats.
4. **Preserve existing content** — when editing files, only modify the specific sections described. Do not rewrite unrelated sections.
5. **Cross-references must be accurate** — when one file references another (e.g., "Follow `core/mcp-detection.md`"), the referenced file must exist and the reference must point to actual content.

## Execution Order

Due to `commands/scaffold.md` contention (4 items modify it), execute in this order:

### Step 1: Create `core/mcp-detection.md` (NEW FILE)

Create the file at `core/mcp-detection.md`. Follow the format from `core/config-reader.md` exactly:

```markdown
# MCP Detection

## Purpose

Determine the expected MCP package and tool prefix for a given tracker or SC type, then verify accessibility and connectivity. Single source of truth for MCP detection logic — prevents duplication between commands that need MCP verification.

Referenced by: `commands/scaffold.md` (Step 0-MCP), `commands/init.md` (Steps 3, 7).

## Input Contract

- **tracker_type** (string, required): Issue tracker type from config: `youtrack`, `github`, `jira`, `linear`, `gitea`, `redmine`
- **tracker_instance** (string, optional): Instance URL — used for connectivity check context
- **tracker_project** (string, optional): Project key — used for read connectivity test
- **service_type** (string, required): `"tracker"` or `"sc"` — determines which connectivity test to run
- **check_write** (boolean, optional, default: false): If true, perform canary-write check after successful read check

## Process

1. **Look up MCP package and tool prefix** from the MCP Server Detection table in `docs/reference/trackers.md`:

   | Tracker type | Package | Tool prefix |
   |-------------|---------|-------------|
   | youtrack | `@vitalyostanin/youtrack-mcp` | `mcp__youtrack__*` |
   | github | `@modelcontextprotocol/server-github` | `mcp__github__*` |
   | jira | `@modelcontextprotocol/server-atlassian` | `mcp__jira__*` or `mcp__atlassian__*` |
   | linear | `@modelcontextprotocol/server-linear` | `mcp__linear__*` |
   | gitea | `forgejo-mcp` | `mcp__gitea__*` or `mcp__forgejo__*` |
   | redmine | `mcp-server-redmine` | `mcp__redmine__*` |
   | (unknown) | — | `mcp__{tracker_type}__*` (best-effort) |

2. **Check tool accessibility.** Scan available tools for at least one tool matching the prefix.

3. **If tool found — verify read connectivity:**
   - If `service_type` is `"tracker"`: attempt to list 1 issue from the declared project (or list projects if no project specified)
   - If `service_type` is `"sc"`: attempt to verify the declared remote exists
   - If connectivity fails: set `mcp_available = false`, capture error

4. **If `check_write` is true AND read check passed (tracker only):**
   - Create a canary item: issue/card with title `[ceos-agents] canary — safe to delete`
   - If create succeeds: delete the canary item immediately. Set `write_available = true`.
   - If create fails: set `write_available = false`. Do NOT block — write failure is advisory.
   - If delete fails after successful create: log warning (`canary item created but not deleted — manual cleanup needed`), set `write_available = false`.

## Output Contract

- **mcp_available** (boolean): `true` if MCP tool is accessible and read connectivity succeeds
- **write_available** (boolean or null): `true` if canary-write succeeded, `false` if failed, `null` if not tested (`check_write` was false)
- **package_name** (string): Expected MCP package name from lookup table
- **tool_prefix** (string): Expected tool prefix pattern
- **error** (string or null): Error message if `mcp_available` is false, null otherwise

## Failure Handling

- **No matching MCP tool found:** Return `mcp_available: false`, `error: "No MCP tool matching prefix {tool_prefix} found in current session"`. Caller decides whether to block or downgrade.
- **Read connectivity fails:** Return `mcp_available: false`, `error: "{error message from failed test call}"`. Caller decides action.
- **Write canary fails:** Return `mcp_available: true`, `write_available: false`, `error: "{error from canary create}"`. Caller decides action (warn, downgrade, or ignore).
- **Unknown tracker type:** Attempt detection with derived prefix `mcp__{tracker_type}__*`. Return `mcp_available: false` only if tool is actually missing — never block on unknown type alone.
```

### Step 2: Update `state/schema.md` — add infrastructure field

In `state/schema.md`, make these additions:

**2a.** In the Full Schema Example JSON (after `"config": { ... }`), add:
```json
  "infrastructure": {
    "tracker_status": "ready",
    "tracker_type": "gitea",
    "tracker_instance": "https://gitea.example.com",
    "tracker_project": "owner/repo",
    "sc_status": "later",
    "sc_remote": null,
    "sc_base_branch": "main"
  },
```

**2b.** In the Top-Level Field Definitions table (after the `config.retry_limits.build_retries` row), add a new section for infrastructure:

```
| `infrastructure` | object or null | No | `null` | Infrastructure declarations from scaffold Step 0-INFRA. Persists tracker and SC readiness for resume. Only populated by scaffold pipeline. |
| `infrastructure.tracker_status` | string or null | No | `null` | Tracker readiness: `"ready"`, `"later"`, or `"downgraded"`. |
| `infrastructure.tracker_type` | string or null | No | `null` | Declared tracker type (youtrack/github/jira/linear/gitea/redmine). |
| `infrastructure.tracker_instance` | string or null | No | `null` | Declared tracker instance URL. |
| `infrastructure.tracker_project` | string or null | No | `null` | Declared tracker project key. |
| `infrastructure.sc_status` | string or null | No | `null` | SC readiness: `"ready"`, `"later"`, or `"downgraded"`. |
| `infrastructure.sc_remote` | string or null | No | `null` | Declared SC remote (owner/repo format). |
| `infrastructure.sc_base_branch` | string | No | `"main"` | Declared base branch. |
```

### Step 3: Update `core/state-manager.md` — infrastructure field

In the Write Operation section, no structural changes needed. The dot-notation path system already supports arbitrary nested fields. But add a note after the Write Process step 3:

> Infrastructure fields (e.g., `infrastructure.tracker_status`) follow the same write protocol. The `infrastructure` object is optional and typically only written by the scaffold pipeline at Step 0-INFRA.

### Step 4: Update `commands/init.md` — reference core/mcp-detection.md + .mcp.json.example detection

**4a. Add Step 1b** (new section between Step 1 and Step 2):

```markdown
## Step 1b: Detect .mcp.json.example

If `.mcp.json.example` exists in CWD (typically generated by `/ceos-agents:scaffold`):

1. Parse the file to extract pre-fill values:
   - **Tracker type:** Identify from MCP server package name (e.g., `@vitalyostanin/youtrack-mcp` → `youtrack`, `forgejo-mcp` → `gitea`). Use the reverse mapping from `core/mcp-detection.md` lookup table.
   - **Instance URL:** Extract from environment variable values (e.g., `YOUTRACK_URL`, `FORGEJO_URL`, `REDMINE_HOST`)
   - **Remote:** Extract from SC MCP server config if present (e.g., GitHub server implies GitHub remote)

2. If parsing succeeds:
   - Display: `Detected .mcp.json.example from previous /scaffold run. Pre-filling: Tracker={type}, Instance={url}`
   - Use extracted values as defaults for Steps 3-4 (user can still override at token collection)
   - Skip redundant questions where values are already known

3. If `.mcp.json.example` does not exist or parsing fails:
   - No action — proceed normally to Step 2 (no warning needed)
```

**4b. Update Step 3** — replace inline MCP package lookup table with reference:

Replace the table content with:
```markdown
Follow `core/mcp-detection.md` Process step 1 to determine the expected MCP package and tool prefix for the declared tracker type.

If Step 1b pre-filled tracker type: use the pre-filled value as default (user can override).
```

Keep the shared server detection logic and platform-specific handling in init.md (those are init-specific, not shared).

**4c. Update Step 7** — replace inline connectivity check with reference:

Replace the connectivity check logic with:
```markdown
For each configured MCP server with non-placeholder tokens, follow `core/mcp-detection.md` (with `check_write: false`) to verify connectivity.
```

Keep the success/failure/skip display messages in init.md.

### Step 5: Update `commands/scaffold.md` — all scaffold changes (items 1, 4, 5, 6)

This is the most complex step. Make ALL scaffold.md changes in one coordinated edit:

**5a. Flag Parsing section — add --infra flag:**

Add to the flag parsing list:
```markdown
- `--infra <value>` → infra_preset (format: `{tracker},{sc}` where each is `ready` or `later`)
```

**5b. Flag Validation section — add --infra validation:**

Add after existing validation rules:
```markdown
If `--infra` provided and format does not match `{ready|later},{ready|later}`:
→ Error: "Invalid --infra format. Expected: --infra ready,later or --infra later,later"
```

**5c. Step 0-INFRA — add --infra preset handling + state persistence:**

At the beginning of Step 0-INFRA, add:
```markdown
If `infra_preset` is set (from --infra flag):
  - Parse: first value = tracker preset, second value = SC preset
  - Set `tracker_effective_status` and `sc_effective_status` from preset values
  - Display: `Infrastructure preset from --infra flag: tracker={tracker}, SC={sc}`
  - If tracker preset is "ready": still ask for tracker type, instance URL, project key (these details cannot be preset via --infra alone)
  - If SC preset is "ready": still ask for remote and base branch
  - Skip the yes/no infrastructure questions — go directly to detail collection (if ready) or to Step 0-MCP (if later)
```

At the end of Step 0-INFRA (after the in-memory variables table), add:
```markdown
**State persistence:** After collecting all infrastructure values, write to state.json:
- `infrastructure.tracker_status` = `tracker_effective_status`
- `infrastructure.tracker_type` = `tracker_type`
- `infrastructure.tracker_instance` = `tracker_instance`
- `infrastructure.tracker_project` = `tracker_project`
- `infrastructure.sc_status` = `sc_effective_status`
- `infrastructure.sc_remote` = `sc_remote`
- `infrastructure.sc_base_branch` = `sc_base_branch`

Follow atomic write protocol from `core/state-manager.md`.

**On resume:** If `state.json` exists with `infrastructure` populated, restore in-memory variables from state instead of re-asking. Display: `Resumed infrastructure state from previous run.`
```

**5d. Step 0-MCP — refactor to reference core/mcp-detection.md + add canary-write:**

Replace the current inline detection logic with:
```markdown
<!-- MCP detection logic: see core/mcp-detection.md -->

For each service declared "ready":

1. Follow `core/mcp-detection.md` with:
   - `tracker_type` = declared tracker type (or SC type)
   - `tracker_instance` = declared instance URL
   - `tracker_project` = declared project key
   - `service_type` = "tracker" or "sc"
   - `check_write` = true (for tracker only — SC does not need write check)

2. **If `mcp_available: false`:**
   {keep existing downgrade/block logic — see 5e below for YOLO+--issue change}

3. **If `mcp_available: true` AND service is tracker:**
   - If `write_available: false`:
     - Display: `⚠️ Tracker MCP has read access but write access failed. Issue creation at Step 4e may fail.`
     - Offer: `Continue with read-only tracker? Step 4e will be skipped. [Y/n]`
       - Y → set `tracker_write_available = false`
       - n → re-check
     - **In Full YOLO mode:** auto-set `tracker_write_available = false`. Display: `Tracker write access unavailable — Step 4e will be skipped.`
   - If `write_available: true`: set `tracker_write_available = true`
   - If `write_available: null`: set `tracker_write_available = true` (write not tested — assume OK)

4. **If `mcp_available: true` AND service is SC:** proceed normally.
```

**5e. Step 0-MCP — YOLO + --issue block:**

In step 2 (MCP tool not found), modify the Full YOLO mode behavior:

```markdown
- **In Full YOLO mode:**
  - If `--issue` flag was provided: **BLOCK** — do not downgrade.
    ```
    [ceos-agents] 🔴 Pipeline Block
    Agent: scaffold
    Step: Step 0-MCP
    Reason: Cannot use --issue in Full YOLO mode without MCP server.
    Detail: --issue requires tracker MCP to fetch issue description. MCP server for "{tracker_type}" is not available. In YOLO mode, there is no interactive fallback to ask for a project description.
    Recommendation: Either remove --issue and provide a project description, or configure the MCP server first (run /ceos-agents:init).
    ```
    STOP scaffold entirely.
  - If `--issue` NOT provided: auto-downgrade without prompt (existing behavior). Display: `MCP for {type} not available — downgrading to "later".`
```

**5f. Step 4e — add canary-write guard:**

In the Step 4e guard clause list, add:
```markdown
- `tracker_write_available` is `false`
```

### Step 6: Update `commands/implement-feature.md` — YOLO+no-MCP block

In the Step 0 MCP pre-flight check section, add context-specific error for --yolo + --description:

After the existing MCP check, add:
```markdown
If `--yolo` AND `description_mode = true` AND MCP is not accessible:
- **BLOCK** with:
  ```
  [ceos-agents] 🔴 Pipeline Block
  Agent: implement-feature
  Step: MCP pre-flight check
  Reason: Cannot create tracker card without MCP server in YOLO mode.
  Detail: --description requires tracker MCP to create the issue card. MCP server for "{Type}" is not available. In YOLO mode, there is no interactive fallback.
  Recommendation: Either configure the MCP server first (run /ceos-agents:init), or create the issue manually and pass the Issue ID instead of --description.
  ```
```

### Step 7: Update `docs/plans/roadmap.md`

Move the 6 implemented items from "PLANNED — v5.5.1+ (Scaffold Infrastructure Follow-ups)" to a new "DONE — v5.6.0 (Scaffold Infrastructure Polish)" section. Keep "Commands-to-Skills Architecture Evaluation" in PLANNED (moved to a renamed section).

### Step 8: Update `CHANGELOG.md`

Add entry at the top, after the header:

```markdown
## [5.6.0] — {date}

**MINOR** — Scaffold Infrastructure Polish: shared MCP detection contract, init pre-fill from .mcp.json.example, infrastructure state persistence, --infra flag, canary-write check, YOLO+no-MCP blocking. No breaking changes.

### Added
- **`core/mcp-detection.md` — shared MCP detection contract:** Extracts MCP package lookup, tool prefix detection, read connectivity check, and canary-write check into a single core contract. Referenced by `commands/scaffold.md` (Step 0-MCP) and `commands/init.md` (Steps 3, 7). Prevents logic drift between commands.
- **init.md `.mcp.json.example` detection (Step 1b):** When `/init` runs after `/scaffold`, detects existing `.mcp.json.example` in CWD and pre-fills tracker type, instance URL, and remote. Eliminates redundant questions for scaffold-then-init workflow.
- **`infrastructure` field in state schema:** Optional object in `state.json` persisting Step 0-INFRA declarations (tracker/SC readiness, type, instance, project, remote). Enables `/resume-ticket` to recover infrastructure state after mid-scaffold interruption.
- **`--infra` CLI flag for scaffold:** Pre-answers Step 0-INFRA questions (format: `--infra ready,later`). Enables fully unattended scaffold in CI/automation contexts.
- **Step 0-MCP canary-write check:** After successful read verification, optionally tests write access via create+delete canary item. Warns early if write permissions are missing (instead of failing at Step 4e, 10-30 min later). Non-blocking — downgrades to read-only.
- **YOLO + no-MCP blocking:** When `--issue` is provided in Full YOLO mode but MCP is missing, blocks with explicit error instead of silently downgrading. Also applies to `--yolo --description` in implement-feature.

### Changed
- **scaffold.md Step 0-MCP:** Refactored to reference `core/mcp-detection.md` instead of inline detection logic.
- **init.md Steps 3 and 7:** Refactored to reference `core/mcp-detection.md` for package lookup and connectivity verification.
- **Step 4e guard clause:** Now also checks `tracker_write_available` (set by canary-write check).

### Details
- 19 agents (unchanged), 25 commands (unchanged), 11 core contracts (was 10)
- 14 optional config sections (unchanged)
```

### Step 9: Update `CLAUDE.md`

In the Repository Structure section, update the core/ description:
- Change "10 shared contracts" to "11 shared contracts"
- Add `mcp-detection.md` to the list if contracts are enumerated

## Verification Checklist

After all edits:
1. `core/mcp-detection.md` exists with Purpose/Input/Output/Failure sections
2. `commands/scaffold.md` references `core/mcp-detection.md` (not inline logic)
3. `commands/init.md` references `core/mcp-detection.md` and has Step 1b
4. `state/schema.md` has `infrastructure` field in example JSON and field definitions table
5. `core/state-manager.md` mentions infrastructure fields
6. `commands/scaffold.md` has `--infra` in Flag Parsing and Flag Validation
7. `commands/scaffold.md` Step 0-INFRA has --infra preset handling and state persistence
8. `commands/scaffold.md` Step 0-MCP has canary-write check
9. `commands/scaffold.md` Step 0-MCP has YOLO+--issue block
10. `commands/scaffold.md` Step 4e has `tracker_write_available` guard
11. `commands/implement-feature.md` has YOLO+--description MCP block
12. `docs/plans/roadmap.md` has DONE v5.6.0 section
13. `CHANGELOG.md` has v5.6.0 entry
14. Run `./tests/harness/run-tests.sh` — all tests pass
