# Phase 2 Research Answers — Agent 1
# Exact Quotes and Line Numbers for v5.6.1 UX Polish

## FILE 1: commands/scaffold.md

### Line 22: --infra flag description

```
Line 22: `--infra <value>` → infra_preset (format: `{tracker},{sc}` where each is `ready` or `later`)
```

**Context (lines 20-23):**
```
20: - `--ci <value>` → preset CI provider
21: - `--brainstorm` → brainstorm = true
22: - `--infra <value>` → infra_preset (format: `{tracker},{sc}` where each is `ready` or `later`)
23: - Remainder after removing flags = project description (natural language)
```

---

### Lines 36-40: --infra validation + error messages

**Lines 36-37 (format validation):**
```
36: If `--infra` provided and format does not match `{ready|later},{ready|later}` (case-sensitive, no whitespace around comma):
37: → Error: "Invalid --infra format. Expected: --infra ready,later or --infra later,later"
```

**Lines 39-40 (--issue conflict validation):**
```
39: If `--infra` provided AND first value (tracker) is `later` AND `--issue` is provided:
40: → Error: "--issue requires tracker access. Use --infra ready,{sc} with --issue, or remove --issue."
```

---

### Lines 56-67: Step 0-INFRA --infra preset handling

Full block (lines 56-66):
```
56: ### Step 0-INFRA: Infrastructure Declaration
57:
58: Before mode selection, collect infrastructure intent. This step always runs — including Full YOLO mode.
59:
60: **--infra flag preset:** If `infra_preset` is set (from `--infra` flag):
61: - Parse: first value = tracker preset, second value = SC preset (e.g., `--infra ready,later` → tracker=ready, sc=later)
62: - Set `tracker_effective_status` and `sc_effective_status` from preset values
63: - Display: `Infrastructure preset from --infra flag: tracker={tracker}, SC={sc}`
64: - If tracker preset is `"ready"`: still ask for tracker type, instance URL, project key (these details cannot be preset via --infra alone)
65: - If SC preset is `"ready"`: still ask for remote and base branch
66: - Skip the yes/no infrastructure questions — go directly to detail collection (if ready) or to Step 0-MCP (if later)
```

---

### Line 126: "On resume" block for scaffold self-resume

**Line 126 (exact):**
```
126: **On resume:** If `state.json` exists with `infrastructure` populated, restore in-memory variables from state instead of re-asking. Display: `Resumed infrastructure state from previous run.`
```

**Context (lines 124-127):**
```
124: Follow atomic write protocol from `core/state-manager.md`.
125:
126: **On resume:** If `state.json` exists with `infrastructure` populated, restore in-memory variables from state instead of re-asking. Display: `Resumed infrastructure state from previous run.`
127:
```

---

### Lines 145-163: MCP jargon occurrences

**Line 146 (mcp_available: false handler — heading comment):**
```
145: 2. **If `mcp_available: false` (MCP tool not found or connectivity failed):**
146:    - Display: `MCP server for {type} not detected in current session.`
147:    - Display guidance: the expected package name (from `core/mcp-detection.md` output), required environment variables (from `docs/reference/trackers.md`), and a note to run `/ceos-agents:init` after scaffold completes.
```

**Lines 158-163 (Full YOLO block comment + auto-downgrade):**
```
158:       Reason: Cannot use --issue in Full YOLO mode without MCP server.
159:       Detail: --issue requires tracker MCP to fetch issue description. MCP server for "{tracker_type}" is not available. In YOLO mode, there is no interactive fallback to ask for a project description.
160:       Recommendation: Either remove --issue and provide a project description, or configure the MCP server first (run /ceos-agents:init).
161:       ```
162:       STOP scaffold entirely.
163:     - If `--issue` NOT provided: auto-downgrade without prompt. Display: `MCP for {type} not available — downgrading to "later".`
```

---

### Line 751: MCP jargon in "Standard error message" section

**Lines 750-751 (exact):**
```
750: If MCP inaccessible at any check point:
751: → STOP: "MCP server for {Type} is not available. Run `/ceos-agents:check-setup` for diagnostics or `/ceos-agents:init` to configure."
```

**Full section (lines 748-751):**
```
748: **Standard error message:**
749:
750: If MCP inaccessible at any check point:
751: → STOP: "MCP server for {Type} is not available. Run `/ceos-agents:check-setup` for diagnostics or `/ceos-agents:init` to configure."
```

---

### Step 0-MCP section: Where canary-write is invoked

**Lines 128-143 (Step 0-MCP header and setup):**
```
128: ### Step 0-MCP: MCP Verification
129:
130: <!-- MCP detection logic: see core/mcp-detection.md -->
131:
132: Runs immediately after Step 0-INFRA. Only checks services the user declared as "ready".
133:
134: **Required in-memory values from Step 0-INFRA:** `tracker_type`, `tracker_instance`, `tracker_project`, `tracker_effective_status`, `sc_effective_status`.
135:
136: For each service declared "ready":
137:
138: 1. **Detect and verify MCP.** Follow `core/mcp-detection.md` with:
139:    - `tracker_type` = declared tracker type (or SC type)
140:    - `tracker_instance` = declared instance URL
141:    - `tracker_project` = declared project key
142:    - `service_type` = `"tracker"` or `"sc"`
143:    - `check_write` = `true` (for tracker only — SC does not need write check)
```

**Lines 165-176 (where write check results are processed — canary outcomes):**
```
165: 3. **If `mcp_available: true` AND service is tracker — check write access:**
166:    - If `write_available: false` (create failed — no write permission):
167:      - Display: `⚠️ Tracker MCP has read access but write access failed. Issue creation at Step 4e may fail.`
168:      - Offer: `Continue with read-only tracker? Step 4e will be skipped. [Y/n]`
169:        - Y → set `tracker_write_available = false`
170:        - n → re-check
171:      - **In Full YOLO mode:** auto-set `tracker_write_available = false`. Display: `Tracker write access unavailable — Step 4e will be skipped.`
172:    - If `write_available: true` AND `write_cleanup_failed: true` (write works, but stale canary exists):
173:      - Display: `⚠️ Tracker write access works but canary cleanup failed. A test item may remain in your tracker.`
174:      - Set `tracker_write_available = true` (write works, proceed normally)
175:    - If `write_available: true` AND `write_cleanup_failed: false`: set `tracker_write_available = true`
176:    - If `write_available: null`: set `tracker_write_available = true` (write not tested — assume OK)
```

**Note:** The canary-write is invoked via `check_write = true` at line 143. The actual canary creation logic lives in `core/mcp-detection.md` (lines 38-43). The `scaffold.md` Step 0-MCP only CALLS the detection contract — it does not contain canary logic itself.

**Canary-write announcement location finding:**
The "canary-write announcement" (displaying what is about to happen before the write check runs) does NOT currently exist in scaffold.md. The only display messages are AFTER the check results are known (lines 167-174). The pre-announcement would need to be ADDED at line 143 (after `check_write = true`, before delegating to core/mcp-detection.md).

---

### Additional MCP jargon: Lines 733-741 (MCP Pre-flight section)

**Lines 733-741:**
```
733: ## MCP Pre-flight Check
734:
735: After v5.5.0, MCP availability is verified proactively at Step 0-MCP — not lazily before individual operations. The pre-flight logic below covers cases outside Step 0-MCP coverage.
736:
737: **Cases requiring an additional MCP check:**
738:
739: - `--issue` flag: Step 1 fetches the issue description from the tracker. Before fetching, verify the tracker MCP tool is still accessible (Step 0-MCP may have run earlier in the session but the tool could become unavailable). If inaccessible → apply `--issue` downgrade fallback (see Step 0-MCP step 5: discard --issue, fall back to project description prompt).
740:
741: - `--no-implement` legacy flow: Step 0-INFRA and Step 0-MCP fire before L1 (stack-selector). If the user declared tracker or SC as "ready", the MCP was already verified at Step 0-MCP. For "later" services, no MCP check is needed.
```

---

## FILE 2: core/mcp-detection.md

### Lines 38-43: canary-write step 4 sequence

**Lines 38-43 (exact):**
```
38: 4. **If `check_write` is true AND read check passed (tracker only):**
39:    - First, check if a stale canary exists: search for open issues with title starting with `[ceos-agents] canary`. If found, delete it before creating a new one (prevents canary spam from prior failed cleanups).
40:    - Create a canary item: issue/card with title `[ceos-agents] canary — safe to delete`
41:    - If create succeeds: delete the canary item immediately. Set `write_available = true`, `write_cleanup_failed = false`.
42:    - If create fails: set `write_available = false`, `write_cleanup_failed = false`. Do NOT block — write failure is advisory.
43:    - If delete fails after successful create: set `write_available = true` (write demonstrably works), `write_cleanup_failed = true`. Log warning.
```

---

### Lines 56-61: failure handling messages

**Lines 55-61 (exact):**
```
55: ## Failure Handling
56:
57: - **No matching MCP tool found:** Return `mcp_available: false`, `error: "No MCP tool matching prefix {tool_prefix} found in current session"`. Caller decides whether to block or downgrade.
58: - **Read connectivity fails:** Return `mcp_available: false`, `error: "{error message from failed test call}"`. Caller decides action.
59: - **Write canary create fails:** Return `mcp_available: true`, `write_available: false`, `write_error: "{error from canary create}"`. Caller decides action (warn, downgrade, or ignore).
60: - **Write canary delete fails (create succeeded):** Return `mcp_available: true`, `write_available: true`, `write_cleanup_failed: true`, `write_error: "Canary item created but not deleted — manual cleanup needed"`. Write access demonstrably works; the cleanup failure is advisory.
61: - **Unknown tracker type:** Attempt detection with derived prefix `mcp__{tracker_type}__*`. Return `mcp_available: false` only if tool is actually missing — never block on unknown type alone.
```

---

### check_write parameter handling

**Lines 14-15 (input contract):**
```
14: - **check_write** (boolean, optional, default: false): If true, perform canary-write check after successful read check
```

**Lines 38-43** (full canary sequence, duplicated above for completeness — this IS the `check_write` handler).

**Output contract fields produced by check_write (lines 47-53):**
```
47: - **mcp_available** (boolean): `true` if MCP tool is accessible and read connectivity succeeds
48: - **write_available** (boolean or null): `true` if canary-write succeeded (create + delete both OK), `false` if create failed, `null` if not tested (`check_write` was false)
49: - **write_cleanup_failed** (boolean): `true` if canary was created but deletion failed (write works, but a stale canary item exists). `false` otherwise.
50: - **package_name** (string): Expected MCP package name from lookup table
51: - **tool_prefix** (string): Expected tool prefix pattern
52: - **error** (string or null): Error message if `mcp_available` is false, null otherwise
53: - **write_error** (string or null): Error message if `write_available` is false or `write_cleanup_failed` is true, null otherwise
```

**No user-facing strings exist in core/mcp-detection.md.** All strings in lines 57-61 are values assigned to output fields (error/write_error) — they are returned to callers, not displayed directly to users. The caller (scaffold.md Step 0-MCP) decides what to display.

---

## FILE 3: commands/resume-ticket.md

### Full structure and flags

**Lines 1-8 (frontmatter + header):**
```
1: ---
2: description: Resumes pipeline from failure point without re-analysis
3: allowed-tools: mcp__*, Bash, Read, Write, Edit, Grep, Glob, Task
4: ---
5:
6: # Resume Ticket
7:
8: Resume the pipeline for ticket $ARGUMENTS from the point where it was interrupted. Read Automation Config from CLAUDE.md.
```

**Flags accepted:** `$ARGUMENTS` = ISSUE-ID only. No named flags (no --infra, no --mode, no --skip). The command accepts a single positional argument (the issue ID). There is NO --infra override support anywhere in this file.

---

### MCP pre-flight check section

**Lines 67-72 (exact — Step 0 MCP pre-flight):**
```
67: ### 0. MCP pre-flight check
68:
69: Before any pipeline operation, verify MCP tool availability:
70: - Read Type from Automation Config (Issue Tracker section)
71: - Check that at least one `mcp__*` tool matching the tracker type is accessible
72: - If not accessible → STOP with: "MCP server for {Type} is not available. Run `/ceos-agents:check-setup` for diagnostics or `/ceos-agents:init` to configure."
```

**Note:** This is the ONLY MCP jargon in resume-ticket.md. Line 72 uses the SAME standard error message pattern as scaffold.md line 751.

---

### State restoration section

**Lines 14-28 (Priority 0 state file detection):**
```
14: If `.ceos-agents/{ISSUE-ID}/state.json` exists:
15: 1. Read and parse the state file
16: 2. Determine resume point from step statuses:
17:    - Find the first step with `status: "in_progress"` → resume from that step
18:    - If no "in_progress" step: find the first `"pending"` step after all `"completed"` steps → resume from that step
19:    - If all steps completed → pipeline is done, inform user
20: 3. Restore context from state file:
21:    - Triage acceptance criteria from `triage.acceptance_criteria`
22:    - Complexity from `triage.complexity`
23:    - Fixer iteration count from `fixer_reviewer.iterations`
24:    - Pipeline profile from `config.profile`
25:    - Active flags from `config.flags`
26: 4. Pass resume_point and restored context to the appropriate pipeline command
27: 5. Detection method: "state_file" (logged for metrics)
28:
```

**Key finding:** The state restoration at lines 20-25 does NOT restore `infrastructure.*` fields. There is no scaffold-specific state restoration in resume-ticket.md. This is correct — resume-ticket only handles BUG and FEATURE pipelines (lines 94-110), not the SCAFFOLD pipeline. The scaffold self-resume (line 126 of scaffold.md) is handled entirely within scaffold.md itself.

---

## FILE 4: commands/init.md

### MCP jargon occurrences

**Line 60 (Step 3 comment):**
```
60: <!-- MCP detection logic: see core/mcp-detection.md -->
```

**Line 151 (Step 7 comment):**
```
151: <!-- MCP connectivity: see core/mcp-detection.md -->
```

**Lines 153-158 (Step 7 connectivity display — user-facing):**
```
153: For each configured MCP server with non-placeholder tokens, follow `core/mcp-detection.md` (with `check_write: false`) to verify connectivity:
154:
155: - If `mcp_available: true` → "[OK] {server_name} connected successfully"
156: - If `mcp_available: false` → "[FAIL] {server_name}: {error}. Check your token and URL."
157:
158: If any placeholder tokens remain:
159: - "[SKIP] {server_name}: token not configured. Add it to .mcp.json later."
```

**Assessment:** init.md uses `mcp_available` as an internal variable reference, not as user-facing text. The user-facing strings "[OK]", "[FAIL]", "[SKIP]" at lines 155-159 are the display format — these use `{server_name}` and `{error}` substitutions. These are already in good UX style and likely do NOT need changes for v5.6.1 unless the target is to unify terminology with scaffold.md's "MCP server for {type} not detected in current session."

**No "MCP server for {Type} is not available" pattern in init.md.** The standard error message from resume-ticket.md line 72 / scaffold.md line 751 does not appear here — init.md uses its own display format at lines 155-156.

---

## SUMMARY TABLE: All pieces requiring modification for v5.6.1

| File | Lines | Current Text (key phrase) | Change Type |
|------|-------|--------------------------|-------------|
| scaffold.md | 22 | `{tracker},{sc}` format note | Clarify/expand flag description |
| scaffold.md | 36-37 | `Invalid --infra format. Expected: --infra ready,later...` | Error message UX polish |
| scaffold.md | 39-40 | `--issue requires tracker access. Use --infra ready,{sc}...` | Error message UX polish |
| scaffold.md | 60-66 | `Infrastructure preset from --infra flag: tracker={tracker}, SC={sc}` | Display message polish |
| scaffold.md | 126 | `Resumed infrastructure state from previous run.` | Resume display polish |
| scaffold.md | 143 | `check_write = true` (no pre-announcement) | ADD canary-write announcement before delegating |
| scaffold.md | 146 | `MCP server for {type} not detected in current session.` | Jargon → user-friendly |
| scaffold.md | 159 | `MCP server for "{tracker_type}" is not available.` (inside block comment Detail) | Jargon → user-friendly |
| scaffold.md | 163 | `MCP for {type} not available — downgrading to "later".` | Jargon → user-friendly |
| scaffold.md | 751 | `MCP server for {Type} is not available. Run...` | Jargon → user-friendly |
| resume-ticket.md | 72 | `MCP server for {Type} is not available. Run...` | Jargon → user-friendly (consistency with scaffold.md) |
| core/mcp-detection.md | 39-43 | Canary logic (internal contract) | No user-facing strings; no changes needed |
| init.md | 155-156 | `[OK]`/`[FAIL]` display format | LOW PRIORITY — different pattern, already clean |

## KEY FINDING: Canary-Write Announcement Placement

The canary-write announcement (telling user what is about to happen) MUST go in `scaffold.md` at the Step 0-MCP section, specifically between line 143 (`check_write = true`) and the point where `core/mcp-detection.md` is called. Specifically, after the `check_write = true` line, before step 3's result handling at line 165, add:

```
- Before calling `core/mcp-detection.md` with `check_write: true`: Display: `Checking write access to {tracker_type} tracker — creating a temporary canary item to verify permissions.`
```

`core/mcp-detection.md` does NOT display anything to users — it only returns output fields. The caller (scaffold.md) is responsible for all user-visible messages about the canary write test.

## KEY FINDING: --infra Resume Override

The `--infra` flag override on resume belongs in `scaffold.md` Step 0-INFRA's "On resume" block (line 126), NOT in `resume-ticket.md`. The current line 126 text only restores from state — it needs an additional clause:

Current: `**On resume:** If state.json exists with infrastructure populated, restore in-memory variables from state instead of re-asking. Display: Resumed infrastructure state from previous run.`

Needed addition: A clause for `--infra` override during resume — if `infra_preset` is set (user passed `--infra` when calling `/scaffold` again on an existing `.ceos-agents/` state), the `--infra` values should OVERRIDE the restored state values, with a display message indicating the override.

## KEY FINDING: resume-ticket.md Does NOT Support Scaffold

`resume-ticket.md` handles only BUG pipeline (fix-ticket) and FEATURE pipeline (implement-feature). It has no scaffold pipeline support, no state.json reading for `infrastructure.*` fields, and no `--infra` flag. Any scaffold resume is self-contained within `scaffold.md` line 126. No changes to `resume-ticket.md` are needed for --infra resume support.
