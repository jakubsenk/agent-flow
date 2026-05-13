# v5.6.1 UX Polish — Requirements

## UXP-1: --infra Flag Format Change

Positional `ready,later` format forces users to remember order (tracker first, SC second). Change to self-documenting named format: `--infra tracker:ready,sc:later`.

### UXP-1.1: Flag Parsing Update

**Description:** Change `--infra` flag parsing from positional `{tracker},{sc}` to named `tracker:{value},sc:{value}` format. Order-independent. Clean break, no backward compatibility shim.

**Acceptance criteria:**
- AC1: `--infra tracker:ready,sc:later` is accepted and parsed correctly
- AC2: `--infra sc:later,tracker:ready` is accepted (order-independent)
- AC3: `--infra ready` is accepted as shorthand for `--infra tracker:ready,sc:ready`
- AC4: `--infra later` is accepted as shorthand for `--infra tracker:later,sc:later`
- AC5: Old positional format `--infra ready,later` is rejected with error message showing new format
- AC6: Invalid key names (e.g., `--infra foo:ready`) are rejected

**Files affected:** `commands/scaffold.md`

**Exact current text (line 22):**
```
- `--infra <value>` → infra_preset (format: `{tracker},{sc}` where each is `ready` or `later`)
```

**Exact replacement text:**
```
- `--infra <value>` → infra_preset (format: `tracker:{ready|later},sc:{ready|later}` — order-independent; shorthands: `--infra ready` = both ready, `--infra later` = both later)
```

### UXP-1.2: Flag Validation Update

**Description:** Update validation rules to match new format. Reject old positional format with helpful migration message.

**Acceptance criteria:**
- AC1: Validation regex matches `tracker:{ready|later},sc:{ready|later}` in any order
- AC2: Validation accepts single-word shorthands `ready` and `later`
- AC3: Old format `ready,later` produces error with new format example
- AC4: `--issue` + tracker:later guard still works with new format

**Files affected:** `commands/scaffold.md`

**Exact current text (lines 36-37):**
```
If `--infra` provided and format does not match `{ready|later},{ready|later}` (case-sensitive, no whitespace around comma):
→ Error: "Invalid --infra format. Expected: --infra ready,later or --infra later,later"
```

**Exact replacement text:**
```
If `--infra` provided:
- If value matches `{ready|later}` (single word) → expand to `tracker:{value},sc:{value}` (shorthand for both same)
- If value matches `tracker:{ready|later},sc:{ready|later}` or `sc:{ready|later},tracker:{ready|later}` (case-sensitive, no whitespace) → parse named pairs
- If value matches `{ready|later},{ready|later}` (old positional format) → Error: "--infra format changed in v5.6.1. Use named format: --infra tracker:ready,sc:later (or shorthand: --infra ready)"
- Otherwise → Error: "Invalid --infra format. Expected: --infra tracker:ready,sc:later (order-independent). Shorthands: --infra ready (both ready), --infra later (both later)."
```

### UXP-1.3: --issue Guard Update

**Description:** Update the `--issue` + `--infra` guard clause to reference the new format.

**Acceptance criteria:**
- AC1: Error message shows new named format
- AC2: Guard triggers when tracker value is `later` regardless of key position

**Files affected:** `commands/scaffold.md`

**Exact current text (lines 39-40):**
```
If `--infra` provided AND first value (tracker) is `later` AND `--issue` is provided:
→ Error: "--issue requires tracker access. Use --infra ready,{sc} with --issue, or remove --issue."
```

**Exact replacement text:**
```
If `--infra` provided AND tracker value is `later` AND `--issue` is provided:
→ Error: "--issue requires tracker access. Use --infra tracker:ready,sc:{value} with --issue, or remove --issue."
```

### UXP-1.4: --infra Preset Display Update

**Description:** Update the display message and parsing logic in Step 0-INFRA to match new format.

**Acceptance criteria:**
- AC1: Display message references new format
- AC2: Parsing correctly extracts tracker and sc values from named pairs

**Files affected:** `commands/scaffold.md`

**Exact current text (lines 60-62):**
```
**--infra flag preset:** If `infra_preset` is set (from `--infra` flag):
- Parse: first value = tracker preset, second value = SC preset (e.g., `--infra ready,later` → tracker=ready, sc=later)
- Set `tracker_effective_status` and `sc_effective_status` from preset values
```

**Exact replacement text:**
```
**--infra flag preset:** If `infra_preset` is set (from `--infra` flag):
- Parse named pairs: extract `tracker` and `sc` values from `tracker:{value},sc:{value}` (or shorthand — already expanded at validation). E.g., `--infra tracker:ready,sc:later` → tracker=ready, sc=later
- Set `tracker_effective_status` and `sc_effective_status` from parsed values
```

### UXP-1.5: CHANGELOG and Roadmap Consistency

**Description:** Ensure CHANGELOG.md entry and roadmap.md item for `--infra` reference the new format consistently.

**Acceptance criteria:**
- AC1: CHANGELOG.md entry for v5.6.1 documents the format change
- AC2: Roadmap PLANNED item moved to DONE section

**Files affected:** `CHANGELOG.md`, `docs/plans/roadmap.md`

---

## UXP-2: Canary-Write Announcement

Step 0-MCP canary-write creates an issue in the user's tracker without warning. Add a visible announcement before the write check.

### UXP-2.1: Add Canary Announcement Before Write Check

**Description:** In scaffold.md Step 0-MCP, add an announcement line before the `core/mcp-detection.md` call with `check_write = true`. The announcement is always displayed (no user prompt — architecturally impossible since `core/mcp-detection.md` handles the actual write internally).

**Acceptance criteria:**
- AC1: User sees "Checking write access -- creating a temporary test item in {tracker_project}. It will be deleted immediately." before the canary write happens
- AC2: The announcement appears only when `check_write = true` (tracker service only)
- AC3: No announcement for SC services (which have `check_write = false`)
- AC4: The announcement text uses `tracker_project` variable from Step 0-INFRA in-memory state

**Files affected:** `commands/scaffold.md`

**Exact current text (lines 138-143):**
```
1. **Detect and verify MCP.** Follow `core/mcp-detection.md` with:
   - `tracker_type` = declared tracker type (or SC type)
   - `tracker_instance` = declared instance URL
   - `tracker_project` = declared project key
   - `service_type` = `"tracker"` or `"sc"`
   - `check_write` = `true` (for tracker only — SC does not need write check)
```

**Exact replacement text:**
```
1. **Detect and verify MCP.** Follow `core/mcp-detection.md` with:
   - `tracker_type` = declared tracker type (or SC type)
   - `tracker_instance` = declared instance URL
   - `tracker_project` = declared project key
   - `service_type` = `"tracker"` or `"sc"`
   - `check_write` = `true` (for tracker only — SC does not need write check)
   - **Before calling `core/mcp-detection.md` with `check_write = true`:** Display: `Checking write access — creating a temporary test item in {tracker_project}. It will be deleted immediately.`
```

---

## UXP-3: MCP Jargon to User-Friendly Error Messages

Error messages say "MCP server for {Type} is not available" -- users think "GitHub" or "Jira", not "MCP server". Rewrite all user-facing MCP error strings to use service-specific language.

### UXP-3.1: Standard Pre-Flight Error Message (11 command files)

**Description:** Replace the standard MCP pre-flight error string across all command files that use the identical pattern. Distinguish tracker vs SC service type.

**Acceptance criteria:**
- AC1: No command file contains "MCP server for {Type} is not available" after the change
- AC2: Replacement message says "Cannot connect to your {Type} issue tracker. Is the {Type} integration configured? Run /ceos-agents:check-setup for diagnostics."
- AC3: All 11 command files are updated consistently

**Files affected (all use identical error string on indicated lines):**
1. `commands/analyze-bug.md` (line 15)
2. `commands/changelog.md` (line 15)
3. `commands/create-pr.md` (line 17)
4. `commands/dashboard.md` (line 29)
5. `commands/estimate.md` (line 23)
6. `commands/fix-bugs.md` (line 80)
7. `commands/metrics.md` (line 29)
8. `commands/prioritize.md` (line 22)
9. `commands/publish.md` (line 15)
10. `commands/resume-ticket.md` (line 72)
11. `commands/scaffold-add.md` (line 24)
12. `commands/status.md` (line 15)

**Exact current text (identical in all 12 files above):**
```
- If not accessible → STOP with: "MCP server for {Type} is not available. Run `/ceos-agents:check-setup` for diagnostics or `/ceos-agents:init` to configure."
```

**Exact replacement text:**
```
- If not accessible → STOP with: "Cannot connect to your {Type} issue tracker. Is the {Type} integration configured? Run `/ceos-agents:check-setup` for diagnostics."
```

### UXP-3.2: implement-feature.md Standard Error

**Description:** Update the non-YOLO fallback error message in implement-feature.md.

**Acceptance criteria:**
- AC1: Standard error string updated to user-friendly version
- AC2: YOLO block message Detail field also updated

**Files affected:** `commands/implement-feature.md`

**Exact current text (line 76):**
```
  - Otherwise: STOP with: "MCP server for {Type} is not available. Run `/ceos-agents:check-setup` for diagnostics or `/ceos-agents:init` to configure."
```

**Exact replacement text:**
```
  - Otherwise: STOP with: "Cannot connect to your {Type} issue tracker. Is the {Type} integration configured? Run `/ceos-agents:check-setup` for diagnostics."
```

### UXP-3.3: implement-feature.md YOLO Block Detail

**Description:** Update the block message Detail field in the YOLO+--description error.

**Acceptance criteria:**
- AC1: Block message Detail uses user-friendly language
- AC2: Block Reason also updated

**Files affected:** `commands/implement-feature.md`

**Exact current text (lines 72-74):**
```
    Reason: Cannot create tracker card without MCP server in YOLO mode.
    Detail: --description requires tracker MCP to create the issue card. MCP server for "{Type}" is not available. In YOLO mode, there is no interactive fallback.
    Recommendation: Either configure the MCP server first (run /ceos-agents:init), or create the issue manually and pass the Issue ID instead of --description.
```

**Exact replacement text:**
```
    Reason: Cannot create tracker card — cannot connect to your {Type} issue tracker in YOLO mode.
    Detail: --description requires issue tracker access to create the issue card. Cannot connect to your {Type} issue tracker. In YOLO mode, there is no interactive fallback.
    Recommendation: Either configure the {Type} integration first (run /ceos-agents:init), or create the issue manually and pass the Issue ID instead of --description.
```

### UXP-3.4: implement-feature.md Card Creation Block

**Description:** Update the MCP card creation failure block message.

**Acceptance criteria:**
- AC1: Recommendation uses user-friendly language

**Files affected:** `commands/implement-feature.md`

**Exact current text (line 146):**
```
     Recommendation: Check MCP server availability and tracker permissions. Run `/ceos-agents:check-setup` for diagnostics.
```

**Exact replacement text:**
```
     Recommendation: Check that your {Type} integration is configured and has write permissions. Run `/ceos-agents:check-setup` for diagnostics.
```

### UXP-3.5: scaffold.md Step 0-MCP Error Messages

**Description:** Update MCP error messages in scaffold.md Step 0-MCP section.

**Acceptance criteria:**
- AC1: "MCP server for {type} not detected" message updated
- AC2: YOLO block Reason and Detail updated
- AC3: Auto-downgrade message updated

**Files affected:** `commands/scaffold.md`

**Exact current text (line 146):**
```
   - Display: `MCP server for {type} not detected in current session.`
```

**Exact replacement text:**
```
   - Display: `Cannot connect to your {type} issue tracker. Is the {type} integration configured?`
```

**Exact current text (lines 158-160):**
```
       Reason: Cannot use --issue in Full YOLO mode without MCP server.
       Detail: --issue requires tracker MCP to fetch issue description. MCP server for "{tracker_type}" is not available. In YOLO mode, there is no interactive fallback to ask for a project description.
       Recommendation: Either remove --issue and provide a project description, or configure the MCP server first (run /ceos-agents:init).
```

**Exact replacement text:**
```
       Reason: Cannot use --issue in Full YOLO mode — cannot connect to your {tracker_type} issue tracker.
       Detail: --issue requires issue tracker access to fetch issue description. Cannot connect to your {tracker_type} issue tracker. In YOLO mode, there is no interactive fallback to ask for a project description.
       Recommendation: Either remove --issue and provide a project description, or configure the {tracker_type} integration first (run /ceos-agents:init).
```

**Exact current text (line 163):**
```
     - If `--issue` NOT provided: auto-downgrade without prompt. Display: `MCP for {type} not available — downgrading to "later".`
```

**Exact replacement text:**
```
     - If `--issue` NOT provided: auto-downgrade without prompt. Display: `Cannot connect to {type} — downgrading to "later". Configure later via /ceos-agents:init.`
```

### UXP-3.6: scaffold.md Standard Error Message (MCP Pre-flight section)

**Description:** Update the standard error message at the bottom of scaffold.md (MCP Pre-flight Check section).

**Acceptance criteria:**
- AC1: Standard error string updated to user-friendly version

**Files affected:** `commands/scaffold.md`

**Exact current text (lines 750-751):**
```
If MCP inaccessible at any check point:
→ STOP: "MCP server for {Type} is not available. Run `/ceos-agents:check-setup` for diagnostics or `/ceos-agents:init` to configure."
```

**Exact replacement text:**
```
If MCP inaccessible at any check point:
→ STOP: "Cannot connect to your {Type} issue tracker. Is the {Type} integration configured? Run `/ceos-agents:check-setup` for diagnostics."
```

### UXP-3.7: fix-bugs.md Standard Error

**Description:** Update the standard MCP pre-flight error in fix-bugs.md.

**Acceptance criteria:**
- AC1: Error string updated to user-friendly version

**Files affected:** `commands/fix-bugs.md`

**Exact current text (line 80):**
```
- If not accessible → STOP with: "MCP server for {Type} is not available. Run `/ceos-agents:check-setup` for diagnostics or `/ceos-agents:init` to configure."
```

**Note:** This file is already listed in UXP-3.1 but called out separately because it has a slightly different location (inside the MCP pre-flight section under "### 0. MCP pre-flight check"). The text is identical to UXP-3.1.

### UXP-3.8: core/mcp-preflight.md Block Messages

**Description:** Update user-facing error strings in the shared MCP pre-flight contract. These appear in block comments shown to the user.

**Acceptance criteria:**
- AC1: "No MCP server found for tracker type" block message updated
- AC2: "MCP server for ... is registered but not responding" block message updated
- AC3: Recommendation text updated

**Files affected:** `core/mcp-preflight.md`

**Exact current text (lines 29-36):**
```
- **No matching MCP tool found:** BLOCK pipeline with:
  ```
  [ceos-agents] 🔴 Pipeline Block
  Agent: mcp-preflight
  Step: MCP pre-flight check
  Reason: No MCP server found for tracker type "{tracker_type}". The pipeline cannot access the issue tracker.
  Detail: Expected tool prefix: mcp__{tracker_type}__*. No matching tool is registered in this session.
  Recommendation: Run /ceos-agents:check-setup for diagnostics, or /ceos-agents:init to configure the MCP server. Verify that the MCP server is listed in your Claude Code MCP config and that the server process is running.
  ```
```

**Exact replacement text:**
```
- **No matching MCP tool found:** BLOCK pipeline with:
  ```
  [ceos-agents] 🔴 Pipeline Block
  Agent: mcp-preflight
  Step: MCP pre-flight check
  Reason: Cannot connect to your {tracker_type} issue tracker. No integration found.
  Detail: Expected tool prefix: mcp__{tracker_type}__*. No matching tool is registered in this session.
  Recommendation: Run /ceos-agents:check-setup for diagnostics, or /ceos-agents:init to configure the {tracker_type} integration. Verify that the integration is listed in your Claude Code MCP config and that the server process is running.
  ```
```

**Exact current text (lines 38-46):**
```
- **MCP tool found but connectivity test fails** (auth error, network error, timeout): BLOCK pipeline with:
  ```
  [ceos-agents] 🔴 Pipeline Block
  Agent: mcp-preflight
  Step: MCP pre-flight check
  Reason: MCP server for "{tracker_type}" is registered but not responding to test queries.
  Detail: {error message from the failed test call}
  Recommendation: Check that your API token is valid and has the required permissions. Check that the {tracker_type} instance is reachable. Run /ceos-agents:check-setup for diagnostics.
  ```
```

**Exact replacement text:**
```
- **MCP tool found but connectivity test fails** (auth error, network error, timeout): BLOCK pipeline with:
  ```
  [ceos-agents] 🔴 Pipeline Block
  Agent: mcp-preflight
  Step: MCP pre-flight check
  Reason: Your {tracker_type} issue tracker integration is registered but not responding.
  Detail: {error message from the failed test call}
  Recommendation: Check that your API token is valid and has the required permissions. Check that the {tracker_type} instance is reachable. Run /ceos-agents:check-setup for diagnostics.
  ```
```

### UXP-3.9: CLAUDE.md Standard Error Message

**Description:** Update the standard error message reference in the project's CLAUDE.md (Block Comment Template context).

**Acceptance criteria:**
- AC1: No "MCP server for" phrasing remains in CLAUDE.md

**Files affected:** `CLAUDE.md` — not applicable. The CLAUDE.md file does not contain the "MCP server for {Type} is not available" error string. No change needed.

---

## UXP-4: Resume --infra Override

When a user crashes mid-scaffold, sets up their tracker, and resumes with `--infra tracker:ready`, the pipeline should use the new values instead of stale state.json data.

### UXP-4.1: Resume Infrastructure Override Logic

**Description:** In scaffold.md Step 0-INFRA "On resume" section, add logic to detect `--infra` flag on re-invocation and prefer it over state.json values. Support both upgrade (later->ready) and downgrade (ready->later).

**Acceptance criteria:**
- AC1: `--infra tracker:ready,sc:later` on resume overrides state.json `infrastructure.tracker_status` and `infrastructure.sc_status`
- AC2: Upgrade (later->ready) triggers re-run of Step 0-MCP for the upgraded service
- AC3: Downgrade (ready->later) nulls out detail fields (tracker_type, tracker_instance, tracker_project for tracker; sc_remote, sc_base_branch for SC)
- AC4: Display change summary: `Infrastructure override: tracker {old} → {new}, SC {old} → {new}.`
- AC5: State.json is updated with new values after override
- AC6: If no `--infra` flag on resume, existing behavior unchanged (restore from state)

**Files affected:** `commands/scaffold.md`

**Exact current text (line 126):**
```
**On resume:** If `state.json` exists with `infrastructure` populated, restore in-memory variables from state instead of re-asking. Display: `Resumed infrastructure state from previous run.`
```

**Exact replacement text:**
```
**On resume:** If `state.json` exists with `infrastructure` populated:
- **If `--infra` flag is provided on re-invocation:** Override state.json values with the new `--infra` values. For each service (tracker, SC):
  - If status changed: display change line (e.g., `tracker: later → ready`)
  - **Upgrade (later/downgraded → ready):** Set `{service}_effective_status = "ready"`. Ask for missing detail fields (tracker type/instance/project for tracker; remote/base branch for SC). Mark service for Step 0-MCP re-verification.
  - **Downgrade (ready → later):** Set `{service}_effective_status = "later"`. Null out detail fields (`tracker_type`, `tracker_instance`, `tracker_project` for tracker; `sc_remote`, `sc_base_branch` for SC).
  - Display summary: `Infrastructure override: tracker {old_status} → {new_status}, SC {old_status} → {new_status}.`
  - Update state.json with new infrastructure values. Follow atomic write protocol from `core/state-manager.md`.
  - For any service upgraded to "ready": proceed to Step 0-MCP to verify the newly declared service. Services that remain unchanged skip re-verification.
- **If no `--infra` flag:** Restore in-memory variables from state as before. Display: `Resumed infrastructure state from previous run.`
```
