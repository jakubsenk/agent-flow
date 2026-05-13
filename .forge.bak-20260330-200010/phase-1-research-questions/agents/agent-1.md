# Agent 1 Research: v5.6.1 UX Polish — 13 Research Questions

**Date:** 2026-03-30
**Scope:** Q1 (--infra flag), Q2 (canary-write announcement), Q3 (error message rewrite), Q4 (resume --infra override)

---

## Q1: --infra Flag Format

### Question 1: Current `--infra` flag format and all parsing/validation/reference locations in `commands/scaffold.md`

**Answer:**

The `--infra` flag is defined, parsed, and validated in `commands/scaffold.md` at the following locations:

**Flag Parsing (lines 22–23):**
```
- `--infra <value>` → infra_preset (format: `{tracker},{sc}` where each is `ready` or `later`)
```
The raw value is stored as `infra_preset`.

**Flag Validation (lines 36–40):**
```
If `--infra` provided and format does not match `{ready|later},{ready|later}` (case-sensitive, no whitespace around comma):
→ Error: "Invalid --infra format. Expected: --infra ready,later or --infra later,later"

If `--infra` provided AND first value (tracker) is `later` AND `--issue` is provided:
→ Error: "--issue requires tracker access. Use --infra ready,{sc} with --issue, or remove --issue."
```

**Step 0-INFRA: `--infra` flag preset block (lines 60–66):**
```
**--infra flag preset:** If `infra_preset` is set (from `--infra` flag):
- Parse: first value = tracker preset, second value = SC preset (e.g., `--infra ready,later` → tracker=ready, sc=later)
- Set `tracker_effective_status` and `sc_effective_status` from preset values
- Display: `Infrastructure preset from --infra flag: tracker={tracker}, SC={sc}`
- If tracker preset is `"ready"`: still ask for tracker type, instance URL, project key
- If SC preset is `"ready"`: still ask for remote and base branch
- Skip the yes/no infrastructure questions — go directly to detail collection (if ready) or to Step 0-MCP (if later)
```

**Summary of valid `--infra` values:**
The regex is `{ready|later},{ready|later}` — exactly four valid combinations: `ready,ready`, `ready,later`, `later,ready`, `later,later`. Case-sensitive, no whitespace around comma.

**All locations in `scaffold.md`:**
- Line 22: Flag parsing definition
- Line 36–37: Format validation
- Line 39–40: `--issue` conflict validation
- Lines 60–66: Step 0-INFRA preset handling logic
- Line 83: `--issue` flag auto-set note (contextually references infra flag exclusion)

---

### Question 2: Tests in `tests/` that validate the `--infra` flag format string

**Answer: None found.**

Searched all 19 scenario files in `tests/scenarios/`. The only `infra`-related hits in the tests directory are:
- `tests/scenarios/state-schema.sh` lines 2 and 65 — only use "infrastructure" as the English word in comments, not testing the `--infra` flag.

The `tests/scenarios/scaffold-v2-input-conflicts.sh` validates `--spec`/`--template`/`--issue` mutual exclusion and `--no-implement` conflict, but does **not** test `--infra` flag format (`{ready|later},{ready|later}`) or the `--issue` + `tracker=later` conflict.

**Gap confirmed:** No test currently covers:
- The `{ready|later},{ready|later}` format regex
- The `--infra later,* + --issue` conflict error
- The "Invalid --infra format" error message text

---

### Question 3: Does `commands/resume-ticket.md` currently reference `--infra` in any way?

**Answer: No.**

`commands/resume-ticket.md` has no mention of `--infra`, `infra_preset`, `infrastructure`, or `tracker_effective_status`. The word "infrastructure" does not appear in that file at all. The file only references `state.json` for restoring pipeline state (line 14: `.ceos-agents/{ISSUE-ID}/state.json`), but never reads or overrides `infrastructure.*` fields.

---

### Question 4: Exact format of `--infra tracker:ready,sc:later` syntax; shorthand support?

**Answer — Clarification of the question:**

The question asks about a *proposed* new syntax `--infra tracker:ready,sc:later`. The **current** format is positional: `ready,later` (tracker first, SC second). The proposed format adds explicit key prefixes.

**Current format (from scaffold.md line 36):** `{ready|later},{ready|later}` — positional, comma-separated, no keys.

**Recommendation for the proposed format:**

If v5.6.1 introduces `--infra tracker:ready,sc:later`:
- It changes the format from positional to named-key pairs.
- The validation regex in line 36 would need updating: from `{ready|later},{ready|later}` to `tracker:{ready|later},sc:{ready|later}` (or support both).
- The error message in line 37 would also need updating: `"Invalid --infra format. Expected: --infra tracker:ready,sc:later"`

**Shorthand support question** (`--infra ready` meaning both ready, `--infra later` meaning both later):

Currently **not supported** — the format requires exactly two comma-separated values. If shorthand is added:
- `--infra ready` → `tracker=ready, sc=ready`
- `--infra later` → `tracker=later, sc=later`
- This would require format validation to accept: `{ready|later}` (shorthand) OR `{ready|later},{ready|later}` (explicit) OR `tracker:{ready|later},sc:{ready|later}` (named-key)

**Evidence from scaffold.md line 37:**
> `"Invalid --infra format. Expected: --infra ready,later or --infra later,later"`

The current error only shows two-value examples, no shorthand. Adding shorthand requires the error message to also be updated.

---

## Q2: Canary-Write Announcement

### Question 5: Exact sequence of operations in `core/mcp-detection.md` step 4 (canary-write); where should the announcement be inserted?

**Answer:**

`core/mcp-detection.md` step 4 (lines 39–44):

```
4. **If `check_write` is true AND read check passed (tracker only):**
   - First, check if a stale canary exists: search for open issues with title starting with
     `[ceos-agents] canary`. If found, delete it before creating a new one.
   - Create a canary item: issue/card with title `[ceos-agents] canary — safe to delete`
   - If create succeeds: delete the canary item immediately.
     Set `write_available = true`, `write_cleanup_failed = false`.
   - If create fails: set `write_available = false`, `write_cleanup_failed = false`.
   - If delete fails after successful create: set `write_available = true` (write works),
     `write_cleanup_failed = true`. Log warning.
```

**Exact operation sequence:**
1. Search for stale canary (title starts with `[ceos-agents] canary`) — delete if found
2. Create canary item: `[ceos-agents] canary — safe to delete`
3a. If create succeeds → delete immediately → set `write_available=true`, `write_cleanup_failed=false`
3b. If create fails → set `write_available=false`, `write_cleanup_failed=false`
3c. If delete fails after create → set `write_available=true`, `write_cleanup_failed=true`, log warning

**Where to insert the announcement:**

The `core/mcp-detection.md` file is a **shared contract** with no user-facing output defined — it only defines output variables (`write_available`, `write_cleanup_failed`, etc.). The announcement belongs in **`commands/scaffold.md`** (the caller), not in `core/mcp-detection.md`.

Specifically, the announcement should appear **after** the `core/mcp-detection.md` call returns and **before** acting on the result, in Step 0-MCP (line 138–176 of `scaffold.md`). The logical insertion point is:

```
Before calling core/mcp-detection.md with check_write=true:
→ Announce: "Testing write access to {tracker_type} tracker..."
```

Or equivalently, `core/mcp-detection.md` step 4 could document an **expected announcement prefix** that callers should emit before invoking the canary check, but the actual output statement should remain in `scaffold.md`.

---

### Question 6: Is there a concept of "interactive mode" vs "YOLO mode" in `commands/scaffold.md` that should gate whether to ask vs. announce for canary-write?

**Answer: Yes, explicitly.**

`scaffold.md` defines three modes (lines 206–210):
```
(a) Interactive — we'll build the spec together
(b) YOLO with checkpoint — I'll design everything, you approve before implementation
(c) Fully automated — I'll design and implement everything, no stops (YOLO mode)
```

Mode is stored at Step 0 (line 204: "Store selected mode").

Canary-write already has YOLO-specific behavior at line 171:
```
**In Full YOLO mode:** auto-set `tracker_write_available = false`.
Display: `Tracker write access unavailable — Step 4e will be skipped.`
```

The canary-write announcement gating logic would be:
- **Interactive / YOLO-with-checkpoint:** Ask user before initiating canary-write (e.g., "Testing write access — this will create and delete a test item in your tracker. OK? [Y/n]")
- **Full YOLO mode:** Announce without asking (e.g., "Testing write access to {tracker_type} tracker — creating and deleting a canary item...")

**Caveat:** Step 0-INFRA and Step 0-MCP run **before** mode selection (Step 0). Specifically:
- Step 0-INFRA: line 58 — "This step always runs — including Full YOLO mode."
- Step 0-MCP: runs immediately after Step 0-INFRA (line 129)
- Step 0 Mode Selection: line 197

This means **mode is not yet known** when canary-write runs. The question is whether the announcement UX needs to account for this ordering. If mode selection is moved before Step 0-MCP, the gating would be clean. If not, either:
1. Always announce without gating (simplest)
2. Move the mode question before Step 0-MCP

This is a design decision for v5.6.1. The current code structure does not support gating at the canary-write point.

---

### Question 7: Should the announcement happen inside `core/mcp-detection.md` or in `commands/scaffold.md`?

**Answer: In `commands/scaffold.md` (the caller).**

**Rationale:**

`core/mcp-detection.md` is explicitly designed as a shared contract:
> "Single source of truth for MCP detection logic — prevents duplication between commands that need MCP verification."
> "Referenced by: `commands/scaffold.md` (Step 0-MCP), `commands/init.md` (Steps 3, 7)."

`core/mcp-detection.md` defines only output variables — it has no user-facing display strings. Adding a user-facing announcement inside the core file would:
1. Break the separation of concerns (core = logic contract, commands = orchestration + UX)
2. Cause the announcement to appear in `/init` contexts too (where it may be inappropriate)
3. Couple the shared contract to scaffold-specific UX

**Correct approach:** `commands/scaffold.md` Step 0-MCP (lines 138–176) should announce *before* invoking `core/mcp-detection.md` with `check_write=true`. This keeps the core file as a pure logic contract and the command as the UX layer.

---

## Q3: Error Message Rewrite

### Question 8: ALL occurrences of "MCP server for {type}" or similar MCP jargon in `commands/scaffold.md` and `core/mcp-detection.md`

**Answer:**

**`commands/scaffold.md`:**

| Line | Text |
|------|------|
| 146 | `Display: \`MCP server for {type} not detected in current session.\`` |
| 159 | `MCP server for "{tracker_type}" is not available. In YOLO mode, there is no interactive fallback to ask for a project description.` (inside block comment Detail field) |
| 163 | `MCP for {type} not available — downgrading to "later".` |
| 751 | `"MCP server for {Type} is not available. Run \`/ceos-agents:check-setup\` for diagnostics or \`/ceos-agents:init\` to configure."` |

**`core/mcp-detection.md`:**

No user-facing "MCP server for {type}" strings. The file only defines output variables and internal logic notes. The error strings in the Failure Handling section (lines 57–61) are descriptions of what to return, not display strings:
- Line 57: `error: "No MCP tool matching prefix {tool_prefix} found in current session"` — this is the `error` output field value, not a display string
- Line 58: `error: "{error message from failed test call}"` — same

---

### Question 9: Other files that use similar MCP jargon phrasing

**Answer — Comprehensive list from search across all `commands/*.md`:**

The pattern `"MCP server for {Type} is not available. Run..."` appears as the standard MCP pre-flight error in **15 command files**:

- `commands/analyze-bug.md` line 15
- `commands/changelog.md` line 15
- `commands/create-pr.md` line 17
- `commands/dashboard.md` line 29
- `commands/estimate.md` line 23
- `commands/fix-bugs.md` line 80
- `commands/fix-ticket.md` — uses "Use the MCP server for {Type}." (lines 123, 333) as agent context, not user-facing error
- `commands/implement-feature.md` lines 73, 76
- `commands/metrics.md` line 29
- `commands/prioritize.md` line 22
- `commands/publish.md` lines 15, 24
- `commands/resume-ticket.md` line 72
- `commands/scaffold-add.md` line 24
- `commands/scaffold.md` lines 146, 159, 163, 751
- `commands/status.md` line 15

**Pattern variants:**
1. **Pre-flight stop error (most common):** `"MCP server for {Type} is not available. Run \`/ceos-agents:check-setup\` for diagnostics or \`/ceos-agents:init\` to configure."`
2. **Step 0-MCP display (scaffold only):** `"MCP server for {type} not detected in current session."`
3. **YOLO downgrade display (scaffold only):** `"MCP for {type} not available — downgrading to \"later\"."`
4. **Agent context string (fix-ticket, fix-bugs, publish):** `"Use the MCP server for {Type}."` — this is an instruction to the agent, not a user-facing error; different category.

**`commands/init.md`:** Does not use "MCP server for {Type}" as a user-facing error. Uses `mcp_available` as a variable name (line 155–156) but error text is: `"[FAIL] {server_name}: {error}. Check your token and URL."` — already user-friendly.

---

### Question 10: Appropriate user-facing name for each tracker type

**Answer — Based on evidence from existing files:**

`commands/scaffold.md` line 75 already uses capitalized display names:
> `(a) I have a tracker project ready (YouTrack / GitHub / Jira / Linear / Gitea / Redmine)`

`docs/reference/trackers.md` MCP Server Detection table (lines 77–84) uses lowercase internal IDs.

**Recommended user-facing name mapping:**

| Internal type | User-facing name |
|---------------|-----------------|
| `youtrack` | `YouTrack` |
| `github` | `GitHub` (not "GitHub Issues" — the tracker is GitHub, issues are a feature) |
| `jira` | `Jira` |
| `linear` | `Linear` |
| `gitea` | `Gitea` |
| `redmine` | `Redmine` |

**Evidence:** The scaffold.md interactive prompt already establishes this capitalization convention. The error message rewrite should use `{tracker_type_display}` (capitalized) instead of raw `{type}` or `{Type}` in user-facing strings.

**Rewritten error messages:**

Instead of: `"MCP server for {type} not detected in current session."`
Use: `"Could not connect to your {tracker_type_display} issue tracker. The MCP integration may not be active in this session."`

Instead of: `"MCP server for {Type} is not available. Run \`/ceos-agents:check-setup\`..."`
Use: `"{tracker_type_display} is not connected. Run \`/ceos-agents:check-setup\` for diagnostics or \`/ceos-agents:init\` to configure."`

Instead of: `"MCP for {type} not available — downgrading to \"later\"."`
Use: `"{tracker_type_display} not connected — treating as 'set up later'."`

---

## Q4: Resume --infra Override

### Question 11: How does `commands/resume-ticket.md` currently detect and resume scaffold pipelines? Does it support scaffold resume?

**Answer: No scaffold pipeline support.**

`commands/resume-ticket.md` only supports **BUG** and **FEATURE** pipelines. Evidence:

**Pipeline type detection (lines 85–88):**
```
8. **Pipeline type detection:**
   - If comment `[ceos-agents] Spec analysis completed.` ... → FEATURE pipeline (use steps from `/implement-feature`)
   - If comment `[ceos-agents] Triage completed.` ... → BUG pipeline (use steps from `/fix-ticket`)
   - If neither → BUG pipeline (default)
```

There is no detection branch for scaffold pipelines. The checkpoints defined (lines 35–44) map to:
- `DECOMPOSE_PARTIAL`, `FRESH`, `POST_TRIAGE`, `POST_ANALYSIS`, `POST_FIX`, `POST_REVIEW`, `PUBLISHED`

None of these correspond to scaffold steps (0-INFRA, 0-MCP, 1-Spec, 2-Checkpoint, 3-Skeleton, 4-Git Init, 5-Architecture, 6-Feature Plan, 7-Implementation, 8-E2E, 9-Final Report).

**State file detection (lines 14–29):** The state file path is `.ceos-agents/{ISSUE-ID}/state.json`. For scaffold runs, the RUN-ID is `scaffold-{timestamp}` (from `state/schema.md` lines 24–26), not an issue ID. The resume command takes `$ARGUMENTS` as an issue ID, so scaffold runs would require passing `scaffold-20260322-143000` as the argument — which is not documented or supported.

**Step 0 MCP pre-flight (lines 68–72):**
```
- Read Type from Automation Config (Issue Tracker section)
- If not accessible → STOP with: "MCP server for {Type} is not available..."
```
This is tracker-only and assumes an Automation Config exists. For scaffold pipelines (which may not have a completed CLAUDE.md yet), this pre-flight would fail.

**Conclusion:** `commands/resume-ticket.md` **does not support scaffold pipelines** at all. Adding `--infra` override for resume would require either:
1. A new scaffold-specific resume path in `resume-ticket.md`
2. A new `--infra` flag handled by `scaffold.md` itself for self-resume (the "On resume" note at line 126 already exists in `scaffold.md`)

---

### Question 12: Where in the resume flow should `--infra` flag parsing and state override logic be inserted?

**Answer:**

Since scaffold has its own resume mechanism (scaffold.md line 126: "On resume: If `state.json` exists with `infrastructure` populated, restore in-memory variables from state instead of re-asking"), there are two viable insertion points:

**Option A: In `commands/scaffold.md` — at the top (Flag Parsing section)**

Insert `--infra` into the existing flag-parsing block (lines 12–23). When `state.json` exists AND `--infra` is provided on re-invocation:
1. Parse `infra_preset` from `--infra` flag
2. Override `state.json` `infrastructure.*` fields with new values
3. Continue with resume flow

The "On resume" block (line 126) would then check: if `--infra` flag was provided AND `infra_preset` parsed, override the restored state before proceeding.

Pseudocode insertion after line 126:
```
**On resume with --infra override:** If `state.json` exists AND `infra_preset` is set:
- Parse `infra_preset` into new tracker/SC values
- Override: `tracker_effective_status`, `sc_effective_status` from `infra_preset`
- Display: `--infra override applied: tracker={tracker}, SC={sc}. Previous state overridden.`
- Re-ask detail questions for any "ready" service that lacks details in state
- Update state.json with new infrastructure values before proceeding
- Continue resume from detected step
```

**Option B: In `commands/resume-ticket.md` — add scaffold pipeline detection**

Would require:
1. Detecting scaffold run IDs (`scaffold-*` pattern)
2. Reading `state.json` from `.ceos-agents/scaffold-{timestamp}/state.json`
3. Applying `--infra` override to infrastructure fields
4. Jumping back into `scaffold.md` pipeline at the correct step

This is more complex and may be out of scope for a UX Polish release. Option A (scaffold.md self-resume with `--infra` override) is simpler and more consistent with the existing architecture.

---

### Question 13: What state.json fields need to be overwritten when `--infra` is provided on resume?

**Answer — Based on `state/schema.md` (lines 155–161):**

The `infrastructure` object in state.json:

```json
"infrastructure": {
  "tracker_status": "ready",      ← overwrite from infra_preset first value
  "tracker_type": "gitea",        ← ask if new tracker_status is "ready" and was null
  "tracker_instance": "...",      ← ask if new tracker_status is "ready" and was null
  "tracker_project": "...",       ← ask if new tracker_status is "ready" and was null
  "sc_status": "later",           ← overwrite from infra_preset second value
  "sc_remote": null,              ← ask if new sc_status is "ready" and was null
  "sc_base_branch": "main"        ← ask if new sc_status is "ready" and was null
}
```

**Overwrite rules:**

| Field | When to overwrite |
|-------|-------------------|
| `infrastructure.tracker_status` | Always — from `infra_preset` first value |
| `infrastructure.sc_status` | Always — from `infra_preset` second value |
| `infrastructure.tracker_type` | Only if new `tracker_status = "ready"` AND field is currently null in state |
| `infrastructure.tracker_instance` | Only if new `tracker_status = "ready"` AND field is currently null in state |
| `infrastructure.tracker_project` | Only if new `tracker_status = "ready"` AND field is currently null in state |
| `infrastructure.sc_remote` | Only if new `sc_status = "ready"` AND field is currently null in state |
| `infrastructure.sc_base_branch` | Only if new `sc_status = "ready"` AND field is currently null in state |

**Important: Top-level `status` field is NOT overwritten** — the pipeline status (`running`/`blocked`/etc.) is managed by the pipeline execution, not by the `--infra` override.

**In-memory variable sync:** After overwriting state.json, the in-memory variables (`tracker_effective_status`, `sc_effective_status`, `tracker_type`, etc.) must also be updated to match — they are used by all downstream steps without re-reading state.json.

**Step 0-MCP must re-run** after an `--infra` override on resume, because the effective statuses may have changed (e.g., from `later` to `ready`). This means MCP verification needs to happen fresh even for a resumed pipeline.

---

## Summary of Key Findings

### --infra flag (Q1)
- Current format: `{ready|later},{ready|later}` — positional, comma-separated, case-sensitive, no whitespace
- Parsed at: scaffold.md lines 22, 36–40, 60–66
- **No tests** validate `--infra` format, the `--issue` conflict, or the error message text
- `resume-ticket.md` has **zero** references to `--infra` or infrastructure state

### Canary-write announcement (Q2)
- Step 4 sequence: stale canary check → create → delete → set output vars
- Announcement belongs in **`commands/scaffold.md`** (caller), not `core/mcp-detection.md` (shared contract)
- Mode gating is **architecturally impossible** as-is: 0-INFRA/0-MCP run before mode selection (Step 0)
- Recommendation: Always announce without gating (simplest), or restructure to move mode selection before Step 0-MCP

### Error message rewrite (Q3)
- "MCP server for {type}" pattern appears at: scaffold.md lines 146, 159, 163, 751
- Same pattern in 13 other command files (standard pre-flight error)
- `core/mcp-detection.md` has **no user-facing display strings** — only output variable definitions
- Recommended display names: YouTrack, GitHub, Jira, Linear, Gitea, Redmine (matching scaffold.md line 75)

### Resume --infra override (Q4)
- `resume-ticket.md` **does not support scaffold pipelines** — only bug and feature pipelines
- No scaffold pipeline detection, no scaffold-specific checkpoints, no `infrastructure.*` field handling
- Best insertion point: `commands/scaffold.md` self-resume path (existing "On resume" block at line 126)
- Fields to overwrite: `infrastructure.tracker_status`, `infrastructure.sc_status` (always); detail fields (conditionally if null and new status is "ready")
- Step 0-MCP must re-run after any `--infra` override
