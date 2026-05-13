# v5.6.1 UX Polish — Execution Plan

**Version:** v5.6.1
**Items:** UXP-1 (--infra format), UXP-2 (canary announcement), UXP-3 (MCP jargon), UXP-4 (resume override)
**Total files modified:** ~20 (16 content + 5 test scripts)
**Estimated tasks:** 6

---

## Dependency Graph

```
task-001 (scaffold.md)  ─────────────────────────────────────────┐
task-002 (12 standard command files) ── parallel with task-001 ──┤
task-003 (implement-feature.md) ──────── parallel with task-001 ──┼──► task-005 (test scripts)
task-004 (core/mcp-preflight.md) ──────  parallel with task-001 ──┤        │
                                                                  │        ▼
                                                                  └──► task-006 (metadata)
```

---

## task-001: All scaffold.md edits (UXP-1 + UXP-2 + UXP-3.5 + UXP-3.6 + UXP-4)

**Title:** Apply all scaffold.md changes — infra format, canary announcement, MCP jargon, resume override

**Description:**
Apply 9 edits to `commands/scaffold.md` in sequence. These cover 4 different UXP items but must be done as one task because they all touch the same file and parallel edits would conflict.

Edit order (top-to-bottom by line number to avoid offset drift):

1. **Line 22 (UXP-1.1):** Replace `--infra` flag description from positional `{tracker},{sc}` to named `tracker:{ready|later},sc:{ready|later}` format with shorthands.
   - Old: `- \`--infra <value>\` → infra_preset (format: \`{tracker},{sc}\` where each is \`ready\` or \`later\`)`
   - New: `- \`--infra <value>\` → infra_preset (format: \`tracker:{ready|later},sc:{ready|later}\` — order-independent; shorthands: \`--infra ready\` = both ready, \`--infra later\` = both later)`

2. **Lines 36-37 (UXP-1.2):** Replace validation block from single-regex to multi-branch (shorthand, named pairs, old format migration error, catch-all).
   - Old: 2-line block starting with `If \`--infra\` provided and format does not match`
   - New: 4-bullet validation block with shorthand expansion, named pair parsing, old format error, catch-all error

3. **Lines 39-40 (UXP-1.3):** Update `--issue` guard to reference new format.
   - Old: `If \`--infra\` provided AND first value (tracker) is \`later\` AND \`--issue\` is provided:`
   - New: `If \`--infra\` provided AND tracker value is \`later\` AND \`--issue\` is provided:` with new error message

4. **Lines 60-62 (UXP-1.4):** Update Step 0-INFRA preset parsing from positional to named-pair extraction.
   - Old: `Parse: first value = tracker preset, second value = SC preset (e.g., \`--infra ready,later\` → tracker=ready, sc=later)`
   - New: `Parse named pairs: extract \`tracker\` and \`sc\` values from \`tracker:{value},sc:{value}\` (or shorthand — already expanded at validation). E.g., \`--infra tracker:ready,sc:later\` → tracker=ready, sc=later`

5. **Line 126 (UXP-4.1):** Replace single-line "On resume" with full override logic block (9 lines).
   - Old: single line about restoring from state.json
   - New: multi-line block with `--infra` override detection, upgrade/downgrade handling, change summary display, state.json update, Step 0-MCP re-verification for upgraded services

6. **Lines 138-143 (UXP-2.1):** Add canary-write announcement line after existing `check_write = true` bullet.
   - Old: 6-line block ending with `check_write = \`true\` (for tracker only — SC does not need write check)`
   - New: same 6 lines + new bullet: `**Before calling \`core/mcp-detection.md\` with \`check_write = true\`:** Display: \`Checking write access — creating a temporary test item in {tracker_project}. It will be deleted immediately.\``

7. **Line 146 (UXP-3.5a):** Replace MCP detection failure display message.
   - Old: `MCP server for {type} not detected in current session.`
   - New: `Cannot connect to your {type} issue tracker. Is the {type} integration configured?`

8. **Lines 158-160 (UXP-3.5b):** Replace YOLO block Reason, Detail, Recommendation.
   - Old: 3 lines with "MCP server" phrasing
   - New: 3 lines with user-friendly "cannot connect to your {tracker_type} issue tracker" phrasing

9. **Line 163 (UXP-3.5c):** Replace auto-downgrade display message.
   - Old: `MCP for {type} not available — downgrading to "later".`
   - New: `Cannot connect to {type} — downgrading to "later". Configure later via /ceos-agents:init.`

10. **Lines 750-751 (UXP-3.6):** Replace standard error in MCP Pre-flight Check section.
    - Old: `MCP server for {Type} is not available. Run \`/ceos-agents:check-setup\` for diagnostics or \`/ceos-agents:init\` to configure.`
    - New: `Cannot connect to your {Type} issue tracker. Is the {Type} integration configured? Run \`/ceos-agents:check-setup\` for diagnostics.`

**Files:** `commands/scaffold.md`

**Dependencies:** None

**Parallelizable:** Yes — can run in parallel with task-002, task-003, task-004

**Spec references:** UXP-1.1, UXP-1.2, UXP-1.3, UXP-1.4, UXP-2.1, UXP-3.5, UXP-3.6, UXP-4.1

---

## task-002: Standard command files MCP jargon fix (12 files)

**Title:** Replace MCP jargon error string in 12 standard command files

**Description:**
Apply the identical text replacement in 12 command files. Each file contains exactly one occurrence of the standard MCP error string.

Replacement (identical in all 12 files):
- Old: `- If not accessible → STOP with: "MCP server for {Type} is not available. Run \`/ceos-agents:check-setup\` for diagnostics or \`/ceos-agents:init\` to configure."`
- New: `- If not accessible → STOP with: "Cannot connect to your {Type} issue tracker. Is the {Type} integration configured? Run \`/ceos-agents:check-setup\` for diagnostics."`

**Files:**
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

**Dependencies:** None

**Parallelizable:** Yes — can run in parallel with task-001, task-003, task-004. All 12 files are independent of each other and can be edited in any order.

**Spec references:** UXP-3.1

---

## task-003: implement-feature.md MCP jargon fix (3 locations)

**Title:** Replace MCP jargon in implement-feature.md — standard error, YOLO block, card creation block

**Description:**
Apply 3 separate text replacements in `commands/implement-feature.md`:

1. **Line 76 (UXP-3.2):** Standard pre-flight error.
   - Old: `Otherwise: STOP with: "MCP server for {Type} is not available. Run \`/ceos-agents:check-setup\` for diagnostics or \`/ceos-agents:init\` to configure."`
   - New: `Otherwise: STOP with: "Cannot connect to your {Type} issue tracker. Is the {Type} integration configured? Run \`/ceos-agents:check-setup\` for diagnostics."`

2. **Lines 72-74 (UXP-3.3):** YOLO block Reason + Detail + Recommendation.
   - Old: 3 lines with "MCP server" phrasing in block comment
   - New: 3 lines with "cannot connect to your {Type} issue tracker" phrasing

3. **Line 146 (UXP-3.4):** Card creation block Recommendation.
   - Old: `Recommendation: Check MCP server availability and tracker permissions. Run \`/ceos-agents:check-setup\` for diagnostics.`
   - New: `Recommendation: Check that your {Type} integration is configured and has write permissions. Run \`/ceos-agents:check-setup\` for diagnostics.`

**Files:** `commands/implement-feature.md`

**Dependencies:** None

**Parallelizable:** Yes — can run in parallel with task-001, task-002, task-004

**Spec references:** UXP-3.2, UXP-3.3, UXP-3.4

---

## task-004: core/mcp-preflight.md block message fix

**Title:** Replace MCP jargon in core/mcp-preflight.md block messages

**Description:**
Apply 2 text replacements in `core/mcp-preflight.md`:

1. **Lines 29-36 (UXP-3.8a):** "No matching MCP tool found" block — update Reason and Recommendation.
   - Reason old: `No MCP server found for tracker type "{tracker_type}". The pipeline cannot access the issue tracker.`
   - Reason new: `Cannot connect to your {tracker_type} issue tracker. No integration found.`
   - Recommendation old: `Run /ceos-agents:check-setup for diagnostics, or /ceos-agents:init to configure the MCP server. Verify that the MCP server is listed in your Claude Code MCP config and that the server process is running.`
   - Recommendation new: `Run /ceos-agents:check-setup for diagnostics, or /ceos-agents:init to configure the {tracker_type} integration. Verify that the integration is listed in your Claude Code MCP config and that the server process is running.`

2. **Lines 38-46 (UXP-3.8b):** "MCP tool found but connectivity test fails" block — update Reason.
   - Reason old: `MCP server for "{tracker_type}" is registered but not responding to test queries.`
   - Reason new: `Your {tracker_type} issue tracker integration is registered but not responding.`

**Files:** `core/mcp-preflight.md`

**Dependencies:** None

**Parallelizable:** Yes — can run in parallel with task-001, task-002, task-003

**Spec references:** UXP-3.8

---

## task-005: Create test scripts (5 files)

**Title:** Create 5 test scenario scripts for v5.6.1 UX Polish changes

**Description:**
Create 5 new test scripts in `tests/scenarios/` as defined in the TDD phase (`.forge/phase-5-tdd/tests/v561-ux-polish-tests.md`). Each script is a structural grep test that verifies the content changes from tasks 1-4 are correctly applied.

Scripts to create:
1. `tests/scenarios/scaffold-infra-flag-format.sh` — T-1: verifies UXP-1 (named --infra format)
2. `tests/scenarios/scaffold-canary-announcement.sh` — T-2: verifies UXP-2 (canary-write announcement)
3. `tests/scenarios/no-mcp-jargon-errors.sh` — T-3: verifies UXP-3 (MCP jargon removed from 14+ files)
4. `tests/scenarios/scaffold-resume-infra-override.sh` — T-4: verifies UXP-4 (resume --infra override)
5. `tests/scenarios/scaffold-v561-regression.sh` — T-5: regression guard (structural elements intact)

After creating the scripts, run `./tests/harness/run-tests.sh` to verify all existing + new tests pass.

**Files:**
- `tests/scenarios/scaffold-infra-flag-format.sh` (new)
- `tests/scenarios/scaffold-canary-announcement.sh` (new)
- `tests/scenarios/no-mcp-jargon-errors.sh` (new)
- `tests/scenarios/scaffold-resume-infra-override.sh` (new)
- `tests/scenarios/scaffold-v561-regression.sh` (new)

**Dependencies:** task-001, task-002, task-003, task-004 (tests verify the content changes from all 4 tasks)

**Parallelizable:** No — must wait for all content tasks to complete first. Run test suite after creation to validate.

**Spec references:** T-1 through T-5 from phase-5-tdd

---

## task-006: Metadata — CHANGELOG.md entry + roadmap.md update

**Title:** Add v5.6.1 changelog entry and move roadmap items from PLANNED to DONE

**Description:**
Two metadata updates after all content and tests are verified:

1. **CHANGELOG.md:** Add v5.6.1 entry after the `[5.6.0]` entry. Format:

   ```
   ## [5.6.1] — 2026-03-30

   **PATCH** — UX Polish: self-documenting --infra flag format, canary-write announcement, user-friendly error messages, resume --infra override. No contract changes.

   ### Changed
   - **--infra flag format:** Changed from positional `ready,later` to named `tracker:ready,sc:later`. Order-independent. Shorthands: `--infra ready` (both ready), `--infra later` (both later). Old format rejected with migration error.
   - **MCP error messages:** Replaced "MCP server for {Type} is not available" with "Cannot connect to your {Type} issue tracker" across 16 files. Technical jargon removed from all user-facing error strings.
   - **Canary-write announcement:** Step 0-MCP now displays "Checking write access -- creating a temporary test item in {project}" before canary-write check runs.
   - **Resume --infra override:** Resuming scaffold with `--infra` flag now overrides stale state.json values. Supports upgrade (later->ready) with re-verification and downgrade (ready->later) with field cleanup.

   ### Details
   - 19 agents (unchanged), 25 commands (unchanged), 11 core contracts (unchanged)
   ```

2. **docs/plans/roadmap.md:** Move the `## PLANNED — v5.6.1 (UX Polish)` section (with all 4 items) to a new `## DONE — v5.6.1 (UX Polish)` section, placed after `## DONE — v5.6.0` and before `## PLANNED — Next`. Update the version/date header at the top of the file.

3. **roadmap.md v5.6.0 --infra entry:** Update the existing DONE v5.6.0 item "### --infra CLI Flag for Scaffold" to note the format was changed in v5.6.1 (add brief note: `Format changed to named pairs in v5.6.1.`).

**Files:**
- `CHANGELOG.md`
- `docs/plans/roadmap.md`

**Dependencies:** task-001, task-002, task-003, task-004, task-005 (must verify all changes and tests pass before writing metadata)

**Parallelizable:** No — final task, runs after everything else is verified

**Spec references:** UXP-1.5

---

## Execution Summary

| Task | Title | Files | Dependencies | Parallel? |
|------|-------|-------|-------------|-----------|
| task-001 | scaffold.md (all edits) | 1 | none | Yes (wave 1) |
| task-002 | 12 standard command files | 12 | none | Yes (wave 1) |
| task-003 | implement-feature.md | 1 | none | Yes (wave 1) |
| task-004 | core/mcp-preflight.md | 1 | none | Yes (wave 1) |
| task-005 | Test scripts | 5 (new) | 001-004 | No (wave 2) |
| task-006 | Metadata (CHANGELOG + roadmap) | 2 | 001-005 | No (wave 3) |

**Wave 1** (parallel): task-001, task-002, task-003, task-004 — all content changes
**Wave 2** (sequential): task-005 — create tests, run test suite
**Wave 3** (sequential): task-006 — changelog + roadmap

**Total edits:** ~30 replacements across ~20 files
**Critical path:** task-001 (most complex, 10 sequential edits in one file) -> task-005 -> task-006
