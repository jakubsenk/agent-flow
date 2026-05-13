# Phase 6 Plan: Scaffold MCP Chicken-and-Egg Fix (v6.1.0)

Generated: 2026-04-01
Brainstorm source: `.forge/phase-3-brainstorm/final.md` (Approach D)
Version impact: MINOR (new optional CLI feature, no contract breaking changes)

---

## Dependency Graph

```
task-001 (init CLI flags) ──────────────────────┐
                                                 ├──→ task-004 (docs + changelog)
task-002 (scaffold Step 0-MCP guidance) ────────┤
                                                 │
task-003 (scaffold resume auto-recheck) ────────┘
                                                 │
                                                 └──→ task-005 (tests)
```

- Tasks 1, 2, 3: **parallel** -- no dependencies between them. Each modifies a different section of a different file (or a non-overlapping section of the same file).
- Task 4: depends on tasks 1 + 2 + 3 (docs must reflect the final state of all changed skill files).
- Task 5: depends on tasks 1 + 2 + 3 (tests validate the changes made by those tasks). Can run in parallel with task 4.

---

## task-001: Add CLI flags to `/ceos-agents:init`

### Dependencies
None

### File
`skills/init/SKILL.md`

### Changes

#### 1a. Update frontmatter `argument-hint`

Current:
```yaml
argument-hint: "[--update]"
```

Change to:
```yaml
argument-hint: "[--update] [--tracker-type <type>] [--tracker-instance <url>] [--sc-remote <owner/repo>]"
```

#### 1b. Update Input line

Current (line 17):
```
Input: `$ARGUMENTS` = (none) | `--update`
```

Change to:
```
Input: `$ARGUMENTS` = (none) | `--update` | `--tracker-type <type>` | `--tracker-instance <url>` | `--sc-remote <owner/repo>` (flags composable)
```

#### 1c. Insert new "Step 0: Parameter Override" before current Step 1

Insert a new section immediately before `## Step 1: Read Automation Config` (before line 26). Content:

```markdown
## Step 0: Parameter Override

Parse `$ARGUMENTS` for optional CLI flags:
- `--tracker-type <type>` → `cli_tracker_type`
- `--tracker-instance <url>` → `cli_tracker_instance`
- `--sc-remote <owner/repo>` → `cli_sc_remote`

**If ANY of these flags is provided:**
1. Validate `--tracker-type` (if provided) against the lookup table in `core/mcp-detection.md` Process step 1. Valid values: `youtrack`, `github`, `jira`, `linear`, `gitea`, `redmine`. If invalid → error: `"Invalid tracker type '{value}'. Valid types: youtrack, github, jira, linear, gitea, redmine."`
2. Skip Step 1 (Automation Config read). Use flag values instead:
   - **Type** = `cli_tracker_type` (if not provided, infer from `cli_sc_remote` hostname: `github.com` → `github`; otherwise → error: `"--tracker-type is required when CLAUDE.md is not available."`)
   - **Instance** = `cli_tracker_instance` (if not provided, use default from `docs/reference/trackers.md` Instance & Project Defaults table for the given type)
   - **Remote** = `cli_sc_remote` (if not provided, skip SC server — tracker-only setup)
3. Proceed to Step 1b (detect .mcp.json.example) with the overridden values.

**If NO flags provided:** proceed to Step 1 as normal.

**Composability with `--update`:** The 3 new flags compose with `--update`. Example: `--update --tracker-type gitea` updates an existing .mcp.json with a new/changed tracker type. The `--update` flag controls Step 2 behavior (preserve existing servers); the new flags control Step 1 behavior (value source).
```

#### 1d. Update Step 1 to handle the skip

Add a guard at the top of Step 1:

```markdown
If Step 0 provided CLI overrides → skip this step entirely (values already set).
```

### Acceptance Criteria

1. Frontmatter `argument-hint` includes all 3 new flags.
2. Step 0 exists before Step 1 with flag parsing, validation, and skip logic.
3. `--tracker-type` validates against the 6 known types from `core/mcp-detection.md` lookup table. Invalid type produces a clear error.
4. Missing `--tracker-instance` falls back to defaults from `docs/reference/trackers.md` Instance & Project Defaults table.
5. Missing `--sc-remote` results in tracker-only setup (no SC server configured).
6. Missing `--tracker-type` without CLAUDE.md produces a clear error (unless inferrable from `--sc-remote` hostname).
7. `--update` composes with the new flags without conflict.
8. Existing behavior (no flags, reads CLAUDE.md) is completely unchanged.

---

## task-002: Update scaffold Step 0-MCP downgrade guidance

### Dependencies
None

### File
`skills/scaffold/SKILL.md`

### Changes

#### 2a. Replace Step 0-MCP point 2 guidance text (lines 160-178)

Replace the current `mcp_available: false` handling block. The current text at line 160-178 shows a generic guidance message and a Y/n/Abort prompt. Replace with the new interactive menu:

**Current text (lines 160-178):**
```markdown
2. **If `mcp_available: false` (MCP tool not found or connectivity failed):**
   - Display: `Cannot connect to your {type} issue tracker. Is the {type} integration configured?`
   - Display guidance: the expected package name (from `core/mcp-detection.md` output), required environment variables (from `docs/reference/trackers.md`), and a note to run `/ceos-agents:init` after scaffold completes.
   - Offer: `Continue without {service}? [Y/n/Abort]`
     - Y (or Enter) → downgrade: set `{service}_effective_status = "downgraded"`, continue
     - n → re-check (user may have configured it)
     - Abort → STOP scaffold entirely
   - **In Full YOLO mode:**
     - If `--issue` flag was provided: **BLOCK** — do not downgrade.
       [... existing block comment ...]
       STOP scaffold entirely.
     - If `--issue` NOT provided: auto-downgrade without prompt. Display: `Cannot connect to {type} — downgrading to "later". Configure later via /ceos-agents:init.`
```

**New text:**
```markdown
2. **If `mcp_available: false` (MCP tool not found or connectivity failed):**
   - Display: `Cannot connect to your {type} {service}. Is the {type} integration configured?`
   - Display guidance: the expected package name (from `core/mcp-detection.md` output) and required environment variables (from `docs/reference/trackers.md`).
   - Build the init command from Step 0-INFRA values: `/ceos-agents:init --tracker-type {tracker_type} --tracker-instance {tracker_instance} --sc-remote {sc_remote}` (omit flags whose value is null).
   - Offer three options:
     ```
     (a) Configure now — run /ceos-agents:init to set up MCP (recommended)
     (b) Skip — continue without {service} (downgraded mode)
     (c) Abort — stop scaffold entirely
     ```
     - **(a) Configure now:**
       1. Display the exact init command: `Run: /ceos-agents:init --tracker-type {tracker_type} --tracker-instance {tracker_instance} --sc-remote {sc_remote}`
       2. User runs init in the same session. Init creates .mcp.json, collects tokens.
       3. After init completes: set `{service}_effective_status = "downgraded"` (MCP tools need session restart to activate — cannot verify connectivity in current session).
       4. Save checkpoint: update state.json with current pipeline state. Follow atomic write protocol from `core/state-manager.md`.
       5. Display:
          ```
          MCP configured successfully. However, MCP tools require a session restart to activate.

          Next steps:
          1. Restart your Claude Code session
          2. Resume scaffold: /ceos-agents:scaffold
             (pipeline will auto-detect the new MCP configuration)
          ```
       6. STOP scaffold.
     - **(b) Skip:** set `{service}_effective_status = "downgraded"`, continue scaffold. (Existing downgrade behavior.)
     - **(c) Abort:** STOP scaffold entirely.

   - **In Full YOLO mode:**
     - If `--issue` flag was provided: **BLOCK** — do not downgrade.
       ```
       [ceos-agents] 🔴 Pipeline Block
       Agent: scaffold
       Step: Step 0-MCP
       Reason: Cannot use --issue in Full YOLO mode — cannot connect to your {tracker_type} issue tracker.
       Detail: --issue requires issue tracker access to fetch issue description. Cannot connect to your {tracker_type} issue tracker. In YOLO mode, there is no interactive fallback to ask for a project description.
       Recommendation: Either remove --issue and provide a project description, or configure the {tracker_type} integration first (run /ceos-agents:init --tracker-type {tracker_type} --tracker-instance {tracker_instance} --sc-remote {sc_remote}).
       ```
       STOP scaffold entirely.
     - If `--issue` NOT provided AND `tracker_type` is known (from Step 0-INFRA):
       1. Auto-invoke init with flags: execute `/ceos-agents:init --tracker-type {tracker_type} --tracker-instance {tracker_instance} --sc-remote {sc_remote}` (tokens are secrets — init still prompts for those even in YOLO).
       2. After init completes: set `{service}_effective_status = "downgraded"`.
       3. Save checkpoint. Display restart+resume guidance (same as option (a) step 5).
       4. STOP scaffold.
     - If `--issue` NOT provided AND `tracker_type` is null: auto-downgrade without prompt. Display: `Cannot connect to {type} — downgrading to "later". Configure later via /ceos-agents:init.`
```

### Acceptance Criteria

1. Step 0-MCP point 2 presents three options: (a) Configure now, (b) Skip, (c) Abort.
2. Option (a) displays the exact `/ceos-agents:init` command with `--tracker-type`, `--tracker-instance`, `--sc-remote` flags populated from Step 0-INFRA values.
3. Option (a) sets status to "downgraded" (not "ready") after init completes — MCP needs restart.
4. Option (a) saves a checkpoint and STOPs scaffold with restart+resume guidance.
5. Option (b) preserves existing downgrade behavior.
6. Option (c) preserves existing abort behavior.
7. YOLO + `--issue` BLOCK behavior is preserved (existing behavior).
8. YOLO without `--issue` (with known tracker_type): auto-invokes init with flags, then downgrades + checkpoint + STOP.
9. YOLO without `--issue` (with null tracker_type): auto-downgrades without prompt (existing behavior for `later` services).
10. The BLOCK recommendation message includes the init command with flags.

---

## task-003: Add resume auto-recheck for downgraded services

### Dependencies
None

### File
`skills/scaffold/SKILL.md`

### Changes

#### 3a. Modify the "On resume" section in Step 0-INFRA (line 140)

Current text (line 140):
```markdown
- **If no `--infra` flag:** Restore in-memory variables from state as before. Display: `Resumed infrastructure state from previous run.`
```

Replace with:
```markdown
- **If no `--infra` flag:** Restore in-memory variables from state.
  - **Auto-recheck for downgraded services:** For each service (tracker, SC) where `{service}_effective_status == "downgraded"`:
    - Display: `Previously downgraded {service} — re-checking MCP availability...`
    - Re-run Step 0-MCP for that service only (same logic as initial Step 0-MCP verification for a "ready" service).
    - If MCP is now available (`mcp_available: true`): set `{service}_effective_status = "ready"`, update state.json. Follow atomic write protocol from `core/state-manager.md`. Display: `{service} MCP now available. Status upgraded: downgraded → ready.`
    - If MCP still unavailable (`mcp_available: false`): keep `{service}_effective_status = "downgraded"`. Display: `{service} MCP still unavailable. Continuing with downgraded status.`
  - For services with `effective_status == "later"`: no action (user explicitly chose to defer — respect their choice. Use `--infra` to upgrade).
  - Display: `Resumed infrastructure state from previous run.`
```

### Acceptance Criteria

1. The "On resume" section has an auto-recheck clause for `"downgraded"` services.
2. Auto-recheck re-runs Step 0-MCP verification for each downgraded service.
3. Successful recheck upgrades status from "downgraded" to "ready" and updates state.json.
4. Failed recheck keeps "downgraded" status and continues (no blocking).
5. Services with "later" status are NOT rechecked (explicit user choice).
6. The semantic distinction is documented: "downgraded" = wanted but failed (auto-retry), "later" = user chose to skip (no auto-retry).
7. Existing `--infra` flag override behavior on resume is preserved (unchanged).

---

## task-004: Update docs and changelog

### Dependencies
task-001, task-002, task-003

### Files
- `docs/reference/skills.md` (init entry)
- `CHANGELOG.md`

### Changes

#### 4a. Update `/init` entry in skills reference

File: `docs/reference/skills.md`, the `/init` section (lines 353-383).

**Update syntax block:**
```
\ceos-agents:init
\ceos-agents:init --update
\ceos-agents:init --tracker-type gitea --tracker-instance https://git.example.com --sc-remote owner/repo
\ceos-agents:init --update --tracker-type github
```

**Update flags list:**
```markdown
**Flags:**
- `--update` — Update existing configuration, preserving non-ceos-agents servers
- `--tracker-type <type>` — Override tracker type (youtrack/github/jira/linear/gitea/redmine). Bypasses CLAUDE.md read.
- `--tracker-instance <url>` — Override tracker instance URL. Defaults to type-specific default if omitted.
- `--sc-remote <owner/repo>` — Override source control remote. Omit for tracker-only setup.
```

**Update table:**
```markdown
| Aspect | Detail |
|--------|--------|
| Input | (none), `--update`, `--tracker-type`, `--tracker-instance`, `--sc-remote` (composable) |
| Output | `.mcp.json`, `.mcp.json.example`, `.claude/settings.json` |
| Destructive | Yes (writes files) |
| MCP required | Yes (for connectivity validation) |
```

**Update "What it does" paragraph** to mention that CLI flags can bypass the CLAUDE.md requirement, enabling init to run before Automation Config exists (e.g., during scaffold).

**Add second example:**
```
\ceos-agents:init --tracker-type gitea --tracker-instance https://git.example.com --sc-remote myorg/myproject
```

#### 4b. Add CHANGELOG entry

Prepend to CHANGELOG.md (above the `## [6.0.1]` entry):

```markdown
## [6.1.0] — 2026-04-01

**MINOR** — Scaffold MCP chicken-and-egg fix: init accepts CLI flags to bypass CLAUDE.md requirement; scaffold offers interactive MCP setup and auto-rechecks downgraded services on resume.

### Added
- **`/init` CLI flags:** `--tracker-type`, `--tracker-instance`, `--sc-remote` — bypass Automation Config read, enabling init to run before CLAUDE.md exists (e.g., during scaffold)
- **Scaffold Step 0-MCP interactive menu:** When MCP is unavailable, offers (a) Configure now via init, (b) Skip, (c) Abort — replacing the previous Y/n/Abort prompt
- **Scaffold resume auto-recheck:** Services with "downgraded" status are automatically re-verified on resume without requiring `--infra` flag

### Changed
- **Scaffold Step 0-MCP YOLO behavior:** YOLO mode without --issue now auto-invokes init with flags when tracker type is known, then checkpoints and stops for restart
- **Scaffold BLOCK recommendation:** Includes the exact `/ceos-agents:init` command with pre-filled flags

### Details
- 19 agents (unchanged), 26 skills (unchanged), 11 core contracts (unchanged)
- Test suite: 39 → 40 scenarios
- Semantic distinction formalized: "downgraded" = auto-retry on resume; "later" = user's explicit choice, never auto-retry
```

### Acceptance Criteria

1. `docs/reference/skills.md` init entry shows all 3 new flags in syntax, flags list, table, and examples.
2. CHANGELOG.md has a `[6.1.0]` entry with correct MINOR classification.
3. CHANGELOG entry lists all 3 Added items and 2 Changed items matching the actual implementation.
4. Test count in CHANGELOG matches actual test count after task-005.
5. Date in CHANGELOG matches the implementation date.

---

## task-005: Add test scenario

### Dependencies
task-001, task-002, task-003

### File
`tests/scenarios/scaffold-mcp-checkpoint.sh` (new file)

### Changes

Create a new test file that validates the structural changes made by tasks 1-3. Follow the pattern established by `tests/scenarios/scaffold-resume-infra-override.sh` and `tests/scenarios/scaffold-canary-announcement.sh`.

```bash
#!/bin/bash
# Test: Scaffold MCP chicken-and-egg fix (v6.1.0)
# Validates: init CLI flags, scaffold Step 0-MCP interactive menu, resume auto-recheck
set -e

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
INIT_SKILL="$REPO_ROOT/skills/init/SKILL.md"
SCAFFOLD_SKILL="$REPO_ROOT/skills/scaffold/SKILL.md"

FAIL=0
fail() { echo "FAIL: $1"; FAIL=1; }

# === INIT CLI FLAGS (task-001) ===

# 1. Init argument-hint includes --tracker-type
if ! grep -q '\-\-tracker-type' "$INIT_SKILL"; then
  fail "init SKILL.md missing --tracker-type flag"
fi

# 2. Init argument-hint includes --tracker-instance
if ! grep -q '\-\-tracker-instance' "$INIT_SKILL"; then
  fail "init SKILL.md missing --tracker-instance flag"
fi

# 3. Init argument-hint includes --sc-remote
if ! grep -q '\-\-sc-remote' "$INIT_SKILL"; then
  fail "init SKILL.md missing --sc-remote flag"
fi

# 4. Init has Step 0 (Parameter Override) before Step 1
step0_line=$(grep -n "Step 0.*Parameter Override\|Parameter Override" "$INIT_SKILL" | head -1 | cut -d: -f1)
step1_line=$(grep -n "Step 1.*Read Automation Config\|Read Automation Config" "$INIT_SKILL" | head -1 | cut -d: -f1)
if [ -z "$step0_line" ]; then
  fail "init SKILL.md missing Step 0: Parameter Override"
elif [ -z "$step1_line" ]; then
  fail "init SKILL.md missing Step 1 anchor"
elif [ "$step0_line" -ge "$step1_line" ]; then
  fail "init SKILL.md Step 0 must appear before Step 1 (Step 0 at line $step0_line, Step 1 at $step1_line)"
fi

# 5. Init validates --tracker-type against known types
if ! grep -q 'youtrack.*github.*jira.*linear.*gitea.*redmine\|Valid.*types\|Invalid.*tracker.*type' "$INIT_SKILL"; then
  fail "init SKILL.md missing tracker-type validation against known types"
fi

# 6. Init mentions composability with --update
if ! grep -q '\-\-update.*\-\-tracker-type\|\-\-tracker-type.*\-\-update\|compos.*update' "$INIT_SKILL"; then
  fail "init SKILL.md missing --update composability documentation"
fi

# === SCAFFOLD STEP 0-MCP GUIDANCE (task-002) ===

# 7. Scaffold Step 0-MCP offers "Configure now" option
if ! grep -q 'Configure now\|configure now' "$SCAFFOLD_SKILL"; then
  fail "scaffold SKILL.md Step 0-MCP missing 'Configure now' option"
fi

# 8. Scaffold Step 0-MCP displays init command with flags
if ! grep -q 'init.*\-\-tracker-type' "$SCAFFOLD_SKILL"; then
  fail "scaffold SKILL.md Step 0-MCP missing init command with --tracker-type flag"
fi

# 9. Scaffold Step 0-MCP mentions checkpoint/STOP after init
if ! grep -q 'checkpoint\|STOP scaffold\|restart.*resume\|session restart' "$SCAFFOLD_SKILL"; then
  fail "scaffold SKILL.md Step 0-MCP missing checkpoint + STOP guidance after init"
fi

# 10. Scaffold Step 0-MCP has Skip option (existing downgrade behavior)
mcp_section_start=$(grep -n "mcp_available: false" "$SCAFFOLD_SKILL" | head -1 | cut -d: -f1)
if [ -n "$mcp_section_start" ]; then
  mcp_context=$(sed -n "$mcp_section_start,$((mcp_section_start + 50))p" "$SCAFFOLD_SKILL")
  if ! echo "$mcp_context" | grep -qi 'skip\|downgrad'; then
    fail "scaffold SKILL.md Step 0-MCP missing Skip/downgrade option"
  fi
fi

# === SCAFFOLD RESUME AUTO-RECHECK (task-003) ===

# 11. Resume section mentions auto-recheck for downgraded services
resume_line=$(grep -n "On resume" "$SCAFFOLD_SKILL" | head -1 | cut -d: -f1)
if [ -n "$resume_line" ]; then
  context=$(sed -n "$resume_line,$((resume_line + 25))p" "$SCAFFOLD_SKILL")
  if ! echo "$context" | grep -qi 'downgraded.*re-check\|re-check.*downgraded\|auto-recheck\|re-run.*0-MCP\|re-checking.*MCP'; then
    fail "scaffold SKILL.md resume section missing auto-recheck for downgraded services"
  fi
fi

# 12. Resume section distinguishes "downgraded" from "later"
if [ -n "$resume_line" ]; then
  context=$(sed -n "$resume_line,$((resume_line + 30))p" "$SCAFFOLD_SKILL")
  if ! echo "$context" | grep -qi 'later.*no action\|later.*skip\|later.*defer\|respect.*choice'; then
    fail "scaffold SKILL.md resume section missing 'later' = no-recheck semantics"
  fi
fi

# 13. Resume auto-recheck upgrades status on success
if [ -n "$resume_line" ]; then
  context=$(sed -n "$resume_line,$((resume_line + 30))p" "$SCAFFOLD_SKILL")
  if ! echo "$context" | grep -qi 'ready\|upgrade.*status\|status.*ready'; then
    fail "scaffold SKILL.md resume auto-recheck missing upgrade to ready on success"
  fi
fi

[ "$FAIL" -eq 0 ] && echo "PASS: Scaffold MCP chicken-and-egg fix verified (v6.1.0)"
exit "$FAIL"
```

### Acceptance Criteria

1. Test file exists at `tests/scenarios/scaffold-mcp-checkpoint.sh`.
2. Test is executable (`chmod +x`).
3. Test has 13 checks covering all 3 tasks (6 for init, 4 for scaffold guidance, 3 for resume auto-recheck).
4. Test passes against the implemented changes from tasks 1-3.
5. Test follows existing conventions: `set -e`, `REPO_ROOT` derivation, `fail()` function, final PASS/FAIL with exit code.

---

## Execution Summary

| Task | File(s) | Estimated Lines Changed | Parallelizable With |
|------|---------|------------------------|---------------------|
| task-001 | `skills/init/SKILL.md` | +35 lines (new Step 0 + frontmatter + input line update) | task-002, task-003 |
| task-002 | `skills/scaffold/SKILL.md` | ~40 lines replaced (Step 0-MCP point 2 rewrite) | task-001, task-003 |
| task-003 | `skills/scaffold/SKILL.md` | ~12 lines replaced (On resume section expansion) | task-001, task-002 |
| task-004 | `docs/reference/skills.md`, `CHANGELOG.md` | +30 lines docs, +20 lines changelog | task-005 |
| task-005 | `tests/scenarios/scaffold-mcp-checkpoint.sh` | +90 lines (new file) | task-004 |

**Total estimated change:** ~230 lines across 4 files (1 new file, 3 modified files).

### Parallel Execution Windows

1. **Window 1:** task-001 + task-002 + task-003 (all independent)
2. **Window 2:** task-004 + task-005 (both depend on window 1, independent of each other)

### Risk Notes

- task-002 and task-003 both modify `skills/scaffold/SKILL.md` but in non-overlapping sections (task-002: lines 160-178, task-003: line 140). If executed by parallel agents, each must target its specific line range to avoid merge conflicts.
- The init Step 0 insertion (task-001) shifts all subsequent step numbers in init by 1. The existing Steps 1-9 remain Steps 1-9 (Step 0 is prepended, not inserted between existing steps). No renumbering needed.
- CHANGELOG test count (39 -> 40) assumes exactly 1 new test file. Verify against actual `tests/scenarios/` count after task-005.
