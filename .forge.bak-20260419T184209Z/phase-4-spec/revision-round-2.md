# Phase 4 Revision Round 2 — Log

Date: 2026-04-18
Input: `review-quality.md` (CONDITIONAL PASS, 3 required fixes) + `review-devils-advocate.md` (CONDITIONAL PASS, 4 required fixes) + 2 advisory fixes
Output: `requirements.md`, `design.md`, `formal-criteria.md` edited in place

---

## Quality-Review Fixes

### FIX #1 — Bash 4.2+ `${var:1:-1}` substring expansion

**Root cause:** `design.md` Item 3 Fix 2 used `reason_json_value="${reason_encoded:1:-1}"` to strip `jq -Rs .` outer quotes. Requires Bash 4.2+; not portable to BusyBox `ash`, `dash`, or macOS Bash 3.2.

**Resolution applied:** Option (b) — replaced `${var:1:-1}` with `jq -n --arg <name> "${value}" '{<field>:$<name>, ...}'` structural payload construction. `jq` itself performs all string escaping; no Bash substring trim is needed. POSIX-safe.

**Changes:**
- `design.md:172-198` — Fix 2 rewritten to use `jq -n --arg` pattern; added prose on why heredoc + `${payload}` is safe after `jq -n` encoding.
- `design.md:200-211` — Design decisions updated: added `jq -n --arg` rationale, listed `jq -Rs . + ${var:1:-1}` as rejected alternative with the Bash 4.2+ caveat explicit.
- `design.md:190-198` — Fix 3 (`docs/guides/autopilot.md`) updated to recommend `jq -n --arg` for custom hooks.
- `design.md:160-171` — Fix 1 (`core/post-publish-hook.md` Section 4) cross-references `jq -n --arg` canonical pattern.
- `design.md:449` — CHANGELOG narrative for Item 3 updated from "`jq -Rs .` encoding example" to "`jq -n --arg` structural payload construction (POSIX-safe)".
- `formal-criteria.md:82-85` — AC-ITEM-3.2 updated: grep for `jq -n` and `--arg` (not `jq -Rs .`); added negative check that `${var:N:-N}` substring construct is absent.
- `formal-criteria.md:88-90` — AC-ITEM-3.3 updated: grep for `jq -n --arg` (not `jq -Rs`).

### FIX #2 — CHANGELOG subsection name (`### Added` → `### Internal`)

**Root cause:** v6.8.0 precedent at `CHANGELOG.md:44-46` uses `### Internal` for test-infrastructure artifacts. Round-1 spec used `### Added`.

**Resolution applied:** Renamed `### Added` → `### Internal` for the two test scenarios throughout.

**Changes:**
- `requirements.md:122-123` — R-RELEASE-1 revised: `### Internal` is mandated (not `### Added`); v6.8.0 precedent cited explicitly.
- `design.md:435` — Release table row updated: CHANGELOG content has `### Fixed` + `### Internal`.
- `design.md:453` — CHANGELOG verbatim: `### Added` → `### Internal`.
- `design.md:458-461` — Design decisions updated: explicit rationale that `### Internal` matches v6.8.0 precedent; `### Added` reserved for user-visible additions.
- `formal-criteria.md:192-207` — AC-RELEASE-1b rewritten: positive grep for `^### Internal$` + both scenario filenames; NEGATIVE grep that `^### Added$` is absent inside the v6.8.1 block.

### FIX #3 — Stale line citation `docs/reference/config.md:26-41`

**Root cause:** R-ITEM-1.2 cited `docs/reference/config.md:26-41` as the verbatim defaults source, but the 7-key table actually lives in the `### Example` block around lines 34-41.

**Resolution applied:** Replaced the stale line number with a content-based reference ("the 7-key Autopilot table under the `### Example` block of `docs/reference/config.md`"). Also added cross-reference to the `### Keys` normative table and `CLAUDE.md` Autopilot row.

**Changes:**
- `requirements.md:21-22` — R-ITEM-1.2 citation updated.

---

## Devil's-Advocate Fixes

### F-1 — Gate placement clarity for fix-bugs.md

**Root cause:** R-ITEM-2.2 said "Step 0 BEFORE any path reference", but `fix-bugs` processes issues in a loop; `ISSUE_ID` only exists inside the loop body.

**Resolution applied:** Clarified that for `fix-bugs`, the gate is at the TOP of the per-issue loop body (not outer Step 0); for `fix-ticket`, `implement-feature`, `resume-ticket`, gate is in Step 0 immediately after ISSUE_ID is read.

**Changes:**
- `requirements.md:39-49` — R-ITEM-2.2 expanded with per-skill placement clarification and a closing note that `gate_line < path_line` (AC-ITEM-2.2) is the operative mechanical check.
- `design.md:118-119` — Item 2 section added explicit "Placement note" before the verbatim gate block.
- `formal-criteria.md:53-56` — AC-ITEM-2.2 expanded to note that either outer-Step-0 or inside-loop placement satisfies the AC as long as gate_line < path_line.

### F-2 — Newline injection via `echo | grep`

**Root cause:** `echo "$ISSUE_ID" | grep -qE '^...$'` evaluates per line of multi-line input and is bypassable by `$'../../etc/passwd\nPROJ-42'` (valid `PROJ-42` on line 2 matches).

**Resolution applied:** Replaced the gate with `[[ ! "${ISSUE_ID}" =~ ^[A-Za-z0-9#_-]+$ ]]` (bash built-in anchors against entire string). Added explicit R-ITEM-2.6 requirement and AC-ITEM-2.6 acceptance criterion for multi-line rejection. Updated error message from `[ERROR]` to `[BLOCK]` per user-supplied snippet.

**Changes:**
- `requirements.md:49-51` — R-ITEM-2.4 updated: `[BLOCK]` message; mandates bash `[[ =~ ]]` form; explicitly forbids `echo | grep -qE` form.
- `requirements.md:53-54` — R-ITEM-2.5 updated: added CR (`\r`) to forbidden characters list.
- `requirements.md:56-57` — NEW R-ITEM-2.6 added: explicit newline-injection rejection requirement with example attack payload.
- `requirements.md:8-9` — Meta updated: total requirements 19→20; negative requirements list includes R-ITEM-2.6.
- `design.md:121-139` — Verbatim gate block rewritten to use `[[ =~ ]]`; added security rationale paragraph on bash anchoring semantics; valid/reject examples include multi-line payload.
- `formal-criteria.md:63-72` — AC-ITEM-2.4 expanded: grep for `[BLOCK] Invalid issue_id`, for bash `[[ =~ ]]` form (positive), and NEGATIVE against `echo "${ISSUE_ID}" | grep -qE` (bypassable form).
- `formal-criteria.md:74-89` — NEW AC-ITEM-2.6 added: behavioral shell-invocation test with `ISSUE_ID=$'good\nbad'` asserting non-zero exit.
- `formal-criteria.md:8` — Meta count 29→31 (AC-ITEM-2.6 + new positive Item 6 counter-form check).

### F-3 — Meta-test Assertion 4 effectiveness

**Root cause:** The original Assertion 4 (single-scenario smoke) does NOT validate the `((N++))` → `N=$((N+1))` fix in full-run mode, because single-scenario mode (harness lines 25-31) was already correct pre-fix. The static grep assertions and AC-ITEM-6.2 are the operative checks.

**Resolution applied:** Added positive-form counter grep to each of Assertions 1-3 (require `PASS=$((PASS + 1))` form PRESENT, not just unsafe form absent). Documented the full validation chain in design.md and the assumptions it relies on. Clarified that Assertion 4 is a belt-and-suspenders regression guard, not a primary correctness check.

**Changes:**
- `design.md:409-437` — Added "Validation chain" subsection in Item 6: explicit 4-step chain with Steps 1-3 as OPERATIVE and Step 4 as complementary.
- `design.md:439-444` — Added "Assumptions and known scope limits": baseline cleanliness requirement for AC-ITEM-6.2; single-scenario mode was already correct pre-fix.
- `design.md:409-438` — Meta-test bash body updated: each Assertion 1-3 now has two sub-checks (unsafe form absent + safe form present); added explanatory comment under Assertion 4.
- `design.md:446-447` — Trade-offs note updated to reflect retained-Assertion-4 rationale.

### F-4 — Meta-test naming consistency

**Root cause:** Phase 2 research used `ac-v681-harness-exit-propagation.sh`; spec uses `v681-harness-exit-propagation.sh` (correct, per PATCH precedent `v644-diagnostics-hardening.sh`). Naming could drift at implementation time.

**Resolution applied:** Confirmed `tests/scenarios/` precedent (bash `ls`) — `v644-diagnostics-hardening.sh` exists with no `ac-` prefix (PATCH convention); `ac-v68-*` exists with `ac-` prefix (minor-version AC convention). Spec standardizes on `v681-harness-exit-propagation.sh` across all files and adds an explicit CAUTION to the AC.

**Changes:**
- `design.md:419-420` — Item 6 Design decisions: added explicit cross-reference that all 4 spec documents (`requirements.md`, `design.md`, `formal-criteria.md`, scenario file itself) MUST use `v681-harness-exit-propagation.sh`; Phase-2 research `ac-v681-` name explicitly rejected.
- `formal-criteria.md:175-178` — AC-ITEM-6.4a expanded with CAUTION block listing the canonical filename, the rejected Phase-2 name, and a companion negative check that `ac-v681-harness-exit-propagation.sh` does NOT exist.

---

## Advisory Fixes (Optional, Applied)

### AC-RELEASE-1c grep ambiguity

**Root cause:** Original `awk … | grep … && awk … | grep … && exit 1 || exit 0` composite command is hard to audit.

**Resolution applied:** Tightened into a three-step scripted check: extract v6.8.1 block to a temp file, positive grep for `examples/configs/`, negative grep for `examples/config-templates/`, explicit temp cleanup and exit codes.

**Changes:**
- `formal-criteria.md:215-226` — AC-RELEASE-1c rewritten with structured multi-line bash.

### R-ITEM-1.4 parenthetical about github-nextjs being "bare"

**Root cause:** Original R-ITEM-1.4 text said "7 bare templates (`github-nextjs.md` plus the 6 templates without an existing optional-section comment block)". `github-nextjs.md` is NOT bare — it already has a `<!--...-->` block (per design.md Item 1 table).

**Resolution applied:** Revised to "7 commented-style templates (i.e., the 8 templates MINUS `redmine-oracle-plsql.md`)" with explicit parenthetical noting that `github-nextjs.md` already has a comment block (Autopilot inserted inside) vs. the other 6 getting a new divider + comment block appended.

**Changes:**
- `requirements.md:28-30` — R-ITEM-1.4 rewritten.

---

## Summary Table of Changes

| Fix | File(s) | Lines edited (approx) |
|-----|---------|----------------------|
| Q-FIX-1 (${var:1:-1}) | design.md, formal-criteria.md | design.md:160-211, 449; formal-criteria.md:82-90 |
| Q-FIX-2 (### Internal) | requirements.md, design.md, formal-criteria.md | requirements.md:122-123; design.md:435,453,458-461; formal-criteria.md:192-207 |
| Q-FIX-3 (config.md stale line) | requirements.md | requirements.md:21-22 |
| DA-F-1 (fix-bugs gate placement) | requirements.md, design.md, formal-criteria.md | requirements.md:39-49; design.md:118-119; formal-criteria.md:55-56 |
| DA-F-2 (newline injection) | requirements.md (+R-ITEM-2.6), design.md, formal-criteria.md (+AC-ITEM-2.6) | requirements.md:8-9,49-57; design.md:121-139; formal-criteria.md:8,63-89 |
| DA-F-3 (Assertion 4 effectiveness) | design.md (validation chain + positive grep) | design.md:409-447 |
| DA-F-4 (naming consistency) | design.md, formal-criteria.md | design.md:419-420; formal-criteria.md:175-178 |
| ADV-1 (AC-RELEASE-1c ambiguity) | formal-criteria.md | formal-criteria.md:215-226 |
| ADV-2 (R-ITEM-1.4 "bare") | requirements.md | requirements.md:28-30 |

**Requirement count:** 19 → 20 (added R-ITEM-2.6).
**AC count:** 29 → 31 (added AC-ITEM-2.6 + positive counter-form check in Item 6 meta-test).
**Document structure unchanged** — all edits are in-place within the existing R-ITEM/AC-ITEM/R-RELEASE/AC-RELEASE sections.

No fixes unresolved. All 3 quality reviewer fixes + all 4 devil's-advocate fixes + 2 advisories applied.
