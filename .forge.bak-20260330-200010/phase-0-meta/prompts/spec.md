# Phase 4 — Specification

## Context

You are writing a precise specification for v5.6.1 (UX Polish) of the ceos-agents plugin. This spec will be the single source of truth for the execution phase. All changes are markdown text edits in existing files.

## Specification Format

For each item, produce:
1. **Requirement ID** (e.g., UXP-1)
2. **File** — exact path
3. **Current text** — exact lines to replace (with line numbers from current file)
4. **New text** — exact replacement text
5. **Acceptance criteria** — how to verify the change is correct

## Items

### UXP-1: --infra Flag Format

**File:** `commands/scaffold.md`

**Changes:**

1a. **Line 22** — Flag parsing entry:
- Current: `--infra <value>` -> `infra_preset (format: `{tracker},{sc}` where each is `ready` or `later`)`
- New: `--infra <value>` -> `infra_preset (format: `tracker:{ready|later},sc:{ready|later}` — order-independent, omitted key defaults to `later`)`

1b. **Lines 36-37** — Flag validation:
- Current: validation checks `{ready|later},{ready|later}` format
- New: validate `tracker:{ready|later},sc:{ready|later}` format (order-independent, partial allowed)
- New error: `"Invalid --infra format. Expected: --infra tracker:ready,sc:later (order-independent, both keys optional — omitted defaults to 'later')"`

1c. **Lines 39-40** — Validation cross-check with --issue:
- Current: "first value (tracker)" references positional format
- New: reference parsed `tracker` key value instead

1d. **Lines 60-66** — Step 0-INFRA flag preset:
- Current: "Parse: first value = tracker preset, second value = SC preset (e.g., `--infra ready,later` -> tracker=ready, sc=later)"
- New: "Parse key:value pairs from `infra_preset`. Keys: `tracker`, `sc`. Values: `ready` or `later`. Omitted key defaults to `later`. (e.g., `--infra tracker:ready,sc:later` -> tracker=ready, sc=later; `--infra tracker:ready` -> tracker=ready, sc=later)"

1e. **Line 63** — Display message:
- Current: `Infrastructure preset from --infra flag: tracker={tracker}, SC={sc}`
- No change needed (display is already correct format)

**AC:**
- Old format `--infra ready,later` is no longer accepted (validation rejects it)
- New format `--infra tracker:ready,sc:later` is accepted
- Order-independent: `--infra sc:later,tracker:ready` works identically
- Partial: `--infra tracker:ready` sets tracker=ready, sc=later (default)
- Error message is self-documenting

### UXP-2: Canary-Write Announcement

**File:** `core/mcp-detection.md`

**Changes:**

2a. **Input Contract** — Add new parameter:
- Add: `- **interactive** (boolean, optional, default: false): If true, prompt for confirmation before canary-write. Caller sets this based on user interaction mode.`

2b. **Step 4 (lines 38-43)** — Add announcement before canary creation:
- Before the "Create a canary item" substep, insert:
  ```
  - Display: `Testing write access — creating a temporary test item in {tracker_project}...`
  - If `interactive` is true: display `Proceed? [Y/n]`. If user declines, skip canary-write: set `write_available = null` (not tested), return.
  ```

**File:** `commands/scaffold.md`

2c. **Step 0-MCP, line 144** — Pass interactive flag:
- When calling `core/mcp-detection.md`, set `interactive = true` if mode is Interactive, `false` otherwise (YOLO modes).

**AC:**
- Before canary-write, user sees "Testing write access — creating a temporary test item in {project}..."
- In Interactive mode, user is asked for confirmation before canary-write
- In YOLO modes, announcement displays but no confirmation is asked
- If user declines in interactive mode, write check is skipped (write_available = null)

### UXP-3: Error Message Rewrite

**File:** `core/mcp-detection.md`

**Changes:**

3a. **Line 57** — Failure handling, no MCP tool found:
- Current: `"No MCP tool matching prefix {tool_prefix} found in current session"`
- New: `"Cannot connect to your {tracker_type} integration. Is the {tracker_type} server configured in your MCP settings?"`

3b. **Lines 58-60** — Failure handling, read connectivity fails and write canary create fails:
- Keep the `error` field populated with the actual error text (technical detail for debugging)
- No change to the `mcp_available`, `write_available` return values

**File:** `commands/scaffold.md`

3c. **Line 146** — MCP not detected message:
- Current: `MCP server for {type} not detected in current session.`
- New: `Cannot connect to your {type} tracker. Is the {type} integration configured?`

3d. **Line 148** — Guidance display:
- Current: mentions "expected package name" and "required environment variables"
- New: Add actionable steps: `To fix: (1) Check that the {type} MCP server is running, (2) Verify your API token is set, (3) Run /ceos-agents:init to reconfigure.`

3e. **Lines 158-160** — YOLO mode block message:
- Current: `MCP server for "{tracker_type}" is not available`
- New: `Cannot connect to your {tracker_type} tracker. The {tracker_type} integration must be configured to use --issue.`

3f. **Line 163** — YOLO auto-downgrade:
- Current: `MCP for {type} not available — downgrading to "later".`
- New: `Cannot reach {type} integration — infrastructure downgraded to "later".`

3g. **Lines 748-751** — Standard error message block:
- Current: `MCP server for {Type} is not available. Run /ceos-agents:check-setup for diagnostics or /ceos-agents:init to configure.`
- New: `Cannot connect to your {Type} tracker. Run /ceos-agents:check-setup for diagnostics or /ceos-agents:init to configure.`

**AC:**
- No occurrence of "MCP server for" remains in `scaffold.md` or `mcp-detection.md`
- All error messages use "{type} tracker" or "{type} integration" language
- Technical MCP details (package name, tool prefix) remain in guidance/detail sections for debugging
- Error messages include actionable next steps

### UXP-4: Resume --infra Override

**File:** `commands/resume-ticket.md`

**Changes:**

4a. **After line 8** — Add --infra flag to input parsing:
- Add to $ARGUMENTS parsing: `Parse optional --infra flag from $ARGUMENTS (same format as scaffold: tracker:{ready|later},sc:{ready|later}).`

4b. **After State File Detection (Priority 0), before step 7** — Add infrastructure override logic:
- Insert new substep between state restoration and checkpoint determination:
  ```
  If `--infra` flag was provided AND state.json `pipeline` is `"scaffold"` AND state.json has `infrastructure` populated:
    1. Parse --infra flag using same format as scaffold (tracker:ready,sc:later — order-independent, omitted defaults to later)
    2. Compare parsed values with state.json `infrastructure.tracker_status` and `infrastructure.sc_status`
    3. If any value differs:
       - Update state.json infrastructure fields with new values
       - Display: "Infrastructure changed since last run. Using new values."
       - If tracker changed from "later" to "ready": prompt for tracker details (type, instance, project) — same questions as scaffold Step 0-INFRA
       - If SC changed from "later" to "ready": prompt for SC details (remote, base branch)
       - Follow atomic write protocol from core/state-manager.md
    4. If no values differ: display "Infrastructure matches previous run." (no state update needed)

  If `--infra` flag was provided AND pipeline is NOT "scaffold":
    - Display warning: "--infra flag is only applicable to scaffold pipeline resume. Ignoring."
  ```

**AC:**
- `resume-ticket.md` accepts `--infra` flag in $ARGUMENTS
- When resuming a scaffold pipeline with `--infra`, state.json infrastructure values are updated
- Display message "Infrastructure changed since last run. Using new values." when values differ
- When tracker/SC changes from "later" to "ready", user is prompted for details
- --infra flag is ignored (with warning) for non-scaffold pipeline resumes
- Uses same `tracker:ready,sc:later` format as updated scaffold command (UXP-1)

## Cross-Cutting Concerns

- **Consistency:** UXP-1 and UXP-4 must use the same `--infra` flag format
- **No contract break:** No changes to Automation Config required keys, no changes to agent output format
- **Backward compatibility:** Old `--infra ready,later` format will no longer be accepted (intentional breaking of the flag format, but the flag itself was introduced in v5.6.0 — very recent, acceptable)
- **Test impact:** Check `tests/` for any references to `--infra` format validation
