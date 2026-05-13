# Phase 1 Research Questions — Agent 3 (Security/Docs Specialist)

## Context

v6.8.1 PATCH — 6 roadmap items (per `docs/plans/roadmap.md` §"PLANNED — v6.8.1"):
1. `examples/configs/*.md` — add `### Autopilot` optional section row per template (8 files)
2. `issue_id` regex gate at state.json path derivation (path-traversal defense-in-depth)
3. JSON-encoding documentation for payload field interpolation
4. Lock-timeout phrasing alignment — 120 vs 121 vs 125 vs +5min buffer
5. Fixer-reviewer crash-recovery regression test (tokens_used integrity)
6. Test harness exit-code propagation (exits 0 even when failures exist)

---

## Research Questions

### Q1 (Item 2 — Security: path traversal scope)

**What is the exact file path and line range in `core/state-manager.md` where `.ceos-agents/{RUN-ID}/state.json` directory creation occurs, and is there currently ANY character-set restriction or sanitization applied to `RUN-ID` / `issue_id` before it is used to construct the filesystem path?**

Target files: `core/state-manager.md` (lines 1-170), `state/schema.md` (RUN-ID Determination section).  
Expected answer: identify the exact "Missing directory: Create `.ceos-agents/{RUN-ID}/` on first write" failure handling line (line 167) and confirm no regex gate exists there or in `skills/fix-ticket/SKILL.md` at the point where `issue_id` is first used to build the path.

---

### Q2 (Item 2 — Security: issue_id character set across trackers)

**What characters can appear in issue IDs produced by each supported tracker type (youtrack, github, jira, linear, gitea, redmine), and is there a canonical regex or allowlist already defined anywhere in the plugin for issue_id validation?**

Target files: `docs/reference/trackers.md`, `state/schema.md` (example values like `PROJ-42`, `#123`), `core/external-input-sanitizer.md`, `core/config-reader.md`.  
Expected answer: a per-tracker character-set table and a YES/NO on whether any existing regex allowlist is defined; note the absence of one in `core/state-manager.md` and `skills/autopilot/SKILL.md`.

---

### Q3 (Item 2 — Security: path traversal attack surface)

**In `skills/autopilot/SKILL.md`, `core/state-manager.md`, and `skills/fix-ticket/SKILL.md`, what are ALL the code paths where `issue_id` (or `run_id`) is concatenated into a filesystem path string (directory creation, state.json write, log file write), and is the `run_id` = `{issue_id}_{timestamp}` format the only place where a malicious value could produce a path like `.ceos-agents/../../../etc/passwd`?**

Target files: `core/state-manager.md` lines 22-35 (Write Process), `skills/autopilot/SKILL.md` lines 317-322 (log file append), `state/schema.md` (RUN-ID format table).  
Expected answer: enumerate every filesystem path construction site; confirm whether `{issue_id}` is used raw or only as a component of `{RUN-ID}` which then goes into `.ceos-agents/{RUN-ID}/`.

---

### Q4 (Item 3 — Docs: JSON-encoding gap identification)

**In `core/post-publish-hook.md`, do the heredoc examples for `pipeline-started`, `step-completed`, and `pipeline-completed` events in Section 4 (lines 104-113) document any requirement to JSON-encode field values (e.g., PR URLs containing `"` or `\`, issue IDs containing special chars, pipeline names) before interpolating them into the heredoc payload?**

Target files: `core/post-publish-hook.md` lines 1-137 (entire file).  
Expected answer: confirm that the Section 4 curl heredoc examples use bare `${variable}` interpolation with NO JSON-encoding note or `jq --arg` pattern, whereas Section 3 (line 23) has a "special characters" note — identify the gap between Section 3 and Section 4 documentation.

---

### Q5 (Item 3 — Docs: JSON-encoding current Section 3 precedent)

**What is the EXACT phrasing of the special-characters note on line 23 of `core/post-publish-hook.md` (Section 3, `pr-created` event), and does `docs/guides/autopilot.md` (webhook payload section, lines 228-286) reproduce this note for the Section 4 events?**

Target files: `core/post-publish-hook.md` line 23, `docs/guides/autopilot.md` lines 228-290.  
Expected answer: quote the existing note verbatim; confirm `docs/guides/autopilot.md` has no equivalent encoding note for `pipeline-started`/`step-completed`/`pipeline-completed` — establishing both the precedent and the missing docs.

---

### Q6 (Item 4 — Docs: lock-timeout phrasing discrepancies)

**In `skills/autopilot/SKILL.md`, list EVERY occurrence of the numbers 120, 121, and 125 along with their surrounding context (±2 lines), and identify which occurrences document the user-facing config value (120min) vs the internal implementation buffer (+5min = 125min) vs the BusyBox fallback hardcode (+121min mmin check).**

Target files: `skills/autopilot/SKILL.md` lines 52, 101, 127-128, 191, 202, 238, 368.  
Expected answer: tabulate the 7+ occurrences, noting that:
- Line 52: config table says `120` (Lock timeout default)
- Line 101: prose says "older than `Lock timeout` minutes (default 120)" then references `+121` fallback
- Line 127-128: code says `LOCK_TIMEOUT=120`, `LOCK_TIMEOUT_WITH_BUFFER=$((LOCK_TIMEOUT + 5))`
- Line 191: BusyBox hardcode `find -mmin +121` (120+1, NOT 120+5=125)
- Line 238: invariant 6 says "+5 minute buffer"
- Line 368: troubleshooting says "lock is <120min old"
This confirms the ambiguity: config=120, primary-path=125, BusyBox-path=121, prose=120.

---

### Q7 (Item 4 — Docs: autopilot guide lock-timeout phrasing)

**In `docs/guides/autopilot.md`, what text appears in the "Lock file stuck" troubleshooting section (lines 340-380) regarding the 120/121/125-minute thresholds, and does it explicitly explain the +5-minute NFS/CIFS skew buffer as distinct from the user-configured `Lock timeout` value?**

Target files: `docs/guides/autopilot.md` lines 340-380.  
Expected answer: quote the key sentences; note that line 350 says "120 minutes (plus a 5-minute NFS/CIFS skew buffer)" — this IS documented in the guide but NOT in the SKILL.md config table row or the BusyBox fallback explanation (line 101 / Invariant 6 / line 191 are inconsistent about which value is 121 vs 125).

---

### Q8 (Item 1 — Config templates: current optional-section format)

**In each of the 8 config templates in `examples/configs/*.md`, what is the exact markdown format used for commented-out optional sections? Specifically: do they use a summary row pattern (`### SectionName (optional)` then `| Key | Value |` table) or an HTML comment block (`<!-- ... -->`), and where does the `### Autopilot` section need to be inserted in each file to maintain sort order consistency?**

Target files: all 8 files in `examples/configs/` — verify by reading `github-nextjs.md` as canonical reference (has `<!-- ... -->` HTML comment block for all optional sections).  
Expected answer: confirm ALL 8 templates use the same HTML comment block pattern, identify which optional sections already appear (Retry Limits, Hooks, Custom Agents, Notifications, Worktrees, E2E Test, Error Handling, Extra labels, Feature Workflow, Decomposition, Pipeline Profiles, Metrics) and confirm `### Autopilot` is absent from all 8 files, establishing insertion position.

---

### Q9 (Item 1 — Config templates: Autopilot section key reference)

**What is the canonical `### Autopilot` section table format (7 keys with Type and Default columns) as documented in `docs/guides/autopilot.md` lines 40-63 and `docs/reference/config.md`, and does the key table use the same pipe-table style as the other optional sections already present in the config templates?**

Target files: `docs/guides/autopilot.md` lines 40-63, `docs/reference/config.md` (Autopilot section), `examples/configs/github-nextjs.md` (any existing optional-section table for comparison).  
Expected answer: provide the exact 7-row table that should be inserted in each template (matching the format in the guide); confirm the existing template optional-section style uses `| Key | Value |` (NOT Type/Default columns) — establishing what format should be used in the minimal config-template representation.

---

### Q10 (Item 5 — Test: existing crash-recovery scenario templates)

**What is the file structure and assertion pattern used by the closest existing regression scenarios to the planned "fixer-reviewer crash mid-iteration → cumulative tokens_used integrity" scenario? Specifically, look at `tests/scenarios/ac-v68-cost-fixer-reviewer-cumulative.sh` and `tests/scenarios/ac-v68-cost-resume-backward-compat.sh` — what files do they grep, what patterns do they assert (positive and negative), and what exit-code convention do they use for PASS/FAIL?**

Target files: `tests/scenarios/ac-v68-cost-fixer-reviewer-cumulative.sh`, `tests/scenarios/ac-v68-cost-resume-backward-compat.sh`.  
Expected answer: extract the grep patterns, target files (skills/fix-ticket/SKILL.md, state/schema.md), FAIL counter pattern, and exit `"$FAIL"` convention — this is the template for the new scenario.

---

### Q11 (Item 6 — Test harness: exit-code verification)

**In `tests/harness/run-tests.sh`, is the `if [ $FAIL -gt 0 ]; then exit 1; fi` block at line 66-68 the ONLY mechanism ensuring non-zero exit propagation, and what is the exact behavior of `((FAIL++))` at line 52 (when FAIL transitions from 0 to 1) under `set -uo pipefail` — specifically, does the arithmetic expression's exit code 1 cause any silent early script termination before the final FAIL check is reached?**

Target files: `tests/harness/run-tests.sh` (entire file, 69 lines).  
Expected answer: confirm the harness uses `set -uo pipefail` (NOT `-e`), that `((FAIL++))` when FAIL=0 exits with code 1 (arithmetic false) but does NOT abort the script (no `-e`), and that the final `if [ $FAIL -gt 0 ]` correctly exits 1. Identify whether the roadmap claim ("exits 0 even when failures exist") is accurate or refers to a subtle edge case — e.g., missing `|| true` after `((FAIL++))` or `((PASS++))` causing undefined behavior in strict CI environments that wrap the harness.

---

### Q12 (Items 1+6 — CHANGELOG and version-bump process)

**What is the exact format of the v6.8.0 CHANGELOG entry (sections: Added, Changed, Fixed, Known Issues, Internal) and the Known Issues sub-section that documents the missing `### Autopilot` config-template row — does it cite all 8 config template files by name or by directory glob?**

Target files: `CHANGELOG.md` lines 10-46 (v6.8.0 entry), `skills/version-bump/SKILL.md` lines 19-40 (pre-flight checks).  
Expected answer: quote the Known Issues line verbatim; confirm the v6.8.1 CHANGELOG entry must use the same section structure (Added, Changed, Fixed), that the version-bump skill verifies `## [6.8.1]` heading exists before bumping, and that both `plugin.json` and `marketplace.json` must be updated atomically.

---

## Summary

### Item Coverage

| Item | Questions |
|------|-----------|
| 1 — Config templates | Q8, Q9, Q12 |
| 2 — issue_id regex / path-traversal | Q1, Q2, Q3 |
| 3 — JSON-encoding docs | Q4, Q5 |
| 4 — Lock-timeout alignment | Q6, Q7 |
| 5 — Crash-recovery regression test | Q10 |
| 6 — Test harness exit-code | Q11 |

### Phase 2 Files to Read (Priority Order)

**Security focus (Items 2, 3):**
- `core/state-manager.md` — full file (path construction at lines 22-35, 167-168)
- `core/post-publish-hook.md` — full file (Section 3 line 23 vs Section 4 lines 104-113)
- `docs/guides/autopilot.md` — lines 228-290 (webhook payload section)
- `docs/reference/trackers.md` — full file (issue ID formats per tracker)
- `core/external-input-sanitizer.md` — full file (existing sanitization precedent)

**Lock-timeout docs (Item 4):**
- `skills/autopilot/SKILL.md` — lines 45-240 (config table + lock code + invariants)
- `docs/guides/autopilot.md` — lines 340-380 (troubleshooting section)

**Config templates (Item 1):**
- `examples/configs/github-nextjs.md` — full file (canonical template reference)
- All remaining 7 `examples/configs/*.md` files — confirm identical optional-section pattern

**Test patterns (Items 5, 6):**
- `tests/scenarios/ac-v68-cost-fixer-reviewer-cumulative.sh` — assertion pattern
- `tests/scenarios/ac-v68-cost-resume-backward-compat.sh` — crash-recovery pattern
- `tests/harness/run-tests.sh` — full file (exit-code logic verification)

**Release process (Item 1+6):**
- `CHANGELOG.md` — lines 10-46 (v6.8.0 entry structure)
- `skills/version-bump/SKILL.md` — lines 19-40 (pre-flight check sequence)
