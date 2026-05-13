# Phase 7 — Execute

## Context

You are implementing v5.6.1 (UX Polish) for the ceos-agents plugin. Execute the plan from Phase 6 precisely. All changes are markdown text edits in existing files. Do NOT create new files.

## Pre-Flight

1. Run `tests/harness/run-tests.sh` to establish baseline (all tests must pass before edits)
2. Read the current content of all 3 target files to confirm line numbers match expectations

## Execution Steps

### Step 1: Edit `core/mcp-detection.md`

**1a. Add `interactive` parameter to Input Contract (after line 15):**

Add a new bullet after `check_write`:
```
- **interactive** (boolean, optional, default: false): If true, prompt for user confirmation before canary-write. Caller sets based on user interaction mode (e.g., Interactive scaffold mode = true, YOLO = false).
```

**1b. Add canary-write announcement to Process step 4 (insert before line 40, "Create a canary item"):**

Insert before the canary creation substep:
```
   - Display: `Testing write access — creating a temporary test item in {tracker_project}...`
   - If `interactive` is true: display `Proceed with write test? [Y/n]`. If user declines (`n`), skip canary-write: set `write_available = null`, `write_cleanup_failed = false`, return.
```

**1c. Rewrite Failure Handling messages (lines 57-61):**

Replace:
- `"No MCP tool matching prefix {tool_prefix} found in current session"` with `"Cannot connect to your {tracker_type} integration. No matching tool found — is the MCP server configured?"`
- `"{error message from failed test call}"` — keep as-is (this is the raw error, not user-facing)
- `"{error from canary create}"` — keep as-is (raw error)
- `"Canary item created but not deleted — manual cleanup needed"` — keep as-is (already clear)

### Step 2: Edit `commands/scaffold.md`

**2a. Line 22 — Flag Parsing entry:**

Replace the --infra line with:
```
- `--infra <value>` -> infra_preset (format: `tracker:{ready|later},sc:{ready|later}` — order-independent, omitted key defaults to `later`)
```

**2b. Lines 36-37 — Flag Validation:**

Replace the --infra validation block with:
```
If `--infra` provided: parse as comma-separated `key:value` pairs. Valid keys: `tracker`, `sc`. Valid values: `ready`, `later`. Order-independent. Omitted key defaults to `later`. If format is invalid (unknown key, missing colon, invalid value):
-> Error: "Invalid --infra format. Expected: --infra tracker:ready,sc:later (order-independent, both keys optional — omitted defaults to 'later')"
```

**2c. Lines 39-40 — Cross-check with --issue:**

Replace reference from "first value (tracker)" to "parsed tracker value":
```
If `--infra` provided and parsed tracker value is `later` AND `--issue` is provided:
-> Error: "--issue requires tracker access. Use --infra tracker:ready with --issue, or remove --issue."
```

**2d. Lines 60-62 — Step 0-INFRA flag preset parsing:**

Replace:
```
- Parse: first value = tracker preset, second value = SC preset (e.g., `--infra ready,later` -> tracker=ready, sc=later)
```
with:
```
- Parse key:value pairs from `infra_preset`. Keys: `tracker`, `sc`. Values: `ready` or `later`. Omitted key defaults to `later`. (e.g., `--infra tracker:ready,sc:later` -> tracker=ready, sc=later; `--infra tracker:ready` -> tracker=ready, sc=later)
```

**2e. Step 0-MCP — Pass interactive parameter (around line 138-144):**

In the Step 0-MCP section where it says "Follow `core/mcp-detection.md` with:", add:
```
   - `interactive` = `true` if mode is Interactive, `false` otherwise
```

**2f. Line 146 — MCP not detected:**

Replace: `MCP server for {type} not detected in current session.`
With: `Cannot connect to your {type} tracker. Is the {type} integration configured?`

**2g. Line 147-148 — Guidance:**

After the new error message, replace guidance with:
```
   - Display actionable steps: `To fix: (1) Check that the {type} MCP server is running, (2) Verify your API token is set, (3) Run /ceos-agents:init to reconfigure.`
```
Keep the existing guidance about expected package name for reference.

**2h. Lines 158-160 — YOLO block message Detail:**

Replace: `MCP server for "{tracker_type}" is not available. In YOLO mode, there is no interactive fallback to ask for a project description.`
With: `Cannot connect to your {tracker_type} tracker. The {tracker_type} integration must be configured to use --issue. In YOLO mode, there is no interactive fallback.`

**2i. Line 163 — YOLO auto-downgrade:**

Replace: `MCP for {type} not available — downgrading to "later".`
With: `Cannot reach {type} integration — infrastructure downgraded to "later".`

**2j. Lines 748-751 — Standard error message:**

Replace: `MCP server for {Type} is not available. Run /ceos-agents:check-setup for diagnostics or /ceos-agents:init to configure.`
With: `Cannot connect to your {Type} tracker. Run /ceos-agents:check-setup for diagnostics or /ceos-agents:init to configure.`

### Step 3: Edit `commands/resume-ticket.md`

**3a. After line 8 — Add --infra flag parsing:**

After "Resume the pipeline for ticket $ARGUMENTS from the point where it was interrupted. Read Automation Config from CLAUDE.md." add:

```
## Flag Parsing

Parse `$ARGUMENTS`:
- Issue ID (required) — first positional argument
- `--infra <value>` -> infra_override (format: `tracker:{ready|later},sc:{ready|later}` — order-independent, omitted key defaults to `later`). Only applicable to scaffold pipeline resume.
```

**3b. After State File Detection, before "### Heuristic Detection" — Add infrastructure override logic:**

After the state file detection section (after line 29), insert:

```
### Infrastructure Override (scaffold only)

If `--infra` flag was provided in $ARGUMENTS:

1. If state.json `pipeline` is NOT `"scaffold"`:
   - Display warning: `--infra flag is only applicable to scaffold pipeline resume. Ignoring.`
   - Skip this section.

2. If state.json `pipeline` is `"scaffold"` AND `infrastructure` is populated:
   - Parse `--infra` flag: comma-separated `key:value` pairs. Valid keys: `tracker`, `sc`. Valid values: `ready`, `later`. Order-independent. Omitted key defaults to `later`.
   - Compare parsed values with `infrastructure.tracker_status` and `infrastructure.sc_status` from state.json.
   - If any value differs:
     a. Update `infrastructure.tracker_status` and/or `infrastructure.sc_status` in state.json.
     b. Display: `Infrastructure changed since last run. Using new values.`
     c. If tracker changed from `"later"` or `"downgraded"` to `"ready"`: prompt for tracker details (type, instance URL, project key) — same questions as scaffold Step 0-INFRA.
     d. If SC changed from `"later"` or `"downgraded"` to `"ready"`: prompt for SC details (remote, base branch).
     e. Update state.json with new infrastructure values. Follow atomic write protocol from `core/state-manager.md`.
     f. Re-run Step 0-MCP for any service that changed to `"ready"` (verify the new infrastructure is accessible).
   - If no values differ:
     - Display: `Infrastructure matches previous run. No changes needed.`

3. If state.json `pipeline` is `"scaffold"` AND `infrastructure` is NOT populated:
   - Treat as fresh infrastructure collection. Run scaffold Step 0-INFRA with the `--infra` flag values as preset.
```

## Post-Flight

1. Run `tests/harness/run-tests.sh` — all tests must pass
2. Search entire codebase for remaining "MCP server for" to verify completeness
3. Verify `--infra` format description matches between `scaffold.md` and `resume-ticket.md`
4. Review each modified file to ensure markdown formatting is intact

## Rules

- Do NOT create new files
- Do NOT modify files outside the 3 targets (scaffold.md, mcp-detection.md, resume-ticket.md)
- Do NOT change the CLAUDE.md contract (no new required keys)
- Do NOT modify agent definitions
- Preserve existing markdown structure (headings, code blocks, tables)
- Use the Edit tool for all changes (not Write) to minimize diff size
