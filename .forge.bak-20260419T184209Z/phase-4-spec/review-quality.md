# Phase 4 Quality Review — v6.8.1 PATCH Spec

**Reviewer:** Phase 4 Reviewer #2 — QUALITY
**Date:** 2026-04-18
**Verdict:** CONDITIONAL PASS — 3 required fixes, 2 advisory notes

---

## Criterion 1 — Atomicity of Requirements

**Result: PASS**

All 19 requirements are atomic. No compound "A and B" in a single SHALL. Multi-part verifications are separated into distinct sub-requirements (e.g., R-ITEM-2.3 / R-ITEM-2.4 / R-ITEM-2.5 for valid-input vs. invalid-input vs. character-set constraint). Release requirements follow the same pattern (R-RELEASE-1 / 2 / 3). No violations found.

---

## Criterion 2 — Testability (requirement → AC coverage)

**Result: PASS with one gap**

Requirements → AC mapping:

| REQ | AC(s) | Testable? |
|-----|-------|-----------|
| R-ITEM-1.1 | AC-ITEM-1.1 | Yes — grep all 8 files |
| R-ITEM-1.2 | AC-ITEM-1.2 | Yes — grep per-row |
| R-ITEM-1.3 | AC-ITEM-1.3 | Yes — awk alignment row check |
| R-ITEM-1.4 | AC-ITEM-1.4 | Yes — comment/active grep |
| R-ITEM-2.1 | AC-ITEM-2.1 | Yes |
| R-ITEM-2.2 | AC-ITEM-2.2 | Yes — line-order awk |
| R-ITEM-2.3 | AC-ITEM-2.3 | Yes |
| R-ITEM-2.4 | AC-ITEM-2.4 | Yes |
| R-ITEM-2.5 | AC-ITEM-2.5 | Yes |
| R-ITEM-3.1 | AC-ITEM-3.1 | Yes |
| R-ITEM-3.2 | AC-ITEM-3.2 | Yes |
| R-ITEM-3.3 | AC-ITEM-3.3 | Yes |
| R-ITEM-3.4 | AC-ITEM-3.4 | Yes (negative grep) |
| R-ITEM-4.1 | AC-ITEM-4.1a + 4.1b | Yes |
| R-ITEM-5.1 | AC-ITEM-5.1a + 5.1b | Yes |
| R-ITEM-5.2 | AC-ITEM-5.2 | Yes |
| R-ITEM-5.3 | AC-ITEM-5.3 | Yes |
| R-ITEM-5.4 | AC-ITEM-5.4 | Yes |
| R-ITEM-6.1 | AC-ITEM-6.1a + 6.1b | Yes |
| R-ITEM-6.2 | AC-ITEM-6.2 | Yes |
| R-ITEM-6.3 | AC-ITEM-6.3 | Yes |
| R-ITEM-6.4 | AC-ITEM-6.4a + 6.4b | Yes |
| R-RELEASE-1 | AC-RELEASE-1a + 1b + 1c | Yes |
| R-RELEASE-2 | AC-RELEASE-2a through 2d | Yes |
| R-RELEASE-3 | AC-RELEASE-3 | Yes |

**Gap (advisory):** R-ITEM-1 has no scenario file (no `v681-config-template-autopilot.sh`). The research final.md flagged this as optional and Phase 4 explicitly did not add it. The 8 ACs are mechanical grep commands run by Phase 8 directly — no scenario is strictly required. Not a blocking defect.

---

## Criterion 3 — Design Decisions Have Rationale

**Result: PASS**

Every design section has explicit "Design decisions" and "Trade-offs considered" sub-sections. Examples spot-checked:

- Item 1: Why `Dry run | false` vs. guide's `true` (design.md lines 98–100) — rationale is canonical default, not guide example. Clear.
- Item 2: Why inline gate vs. shared helper (design.md lines 135–143) — rationale is "no shared skill-entry contract" and "PATCH scope". Clear.
- Item 3: Why `jq -Rs .` with `:1:-1` stripping (design.md lines 201–207) — rationale explains alternative considered and rejected. Clear.
- Item 6: Why Assertion 4 writes temp file to live scenarios dir (design.md lines 418–421) — rationale and risk mitigation (`$$` suffix) present. Clear.

---

## Criterion 4 — Verbatim Inserts Syntactically Valid

**Result: PASS with one defect (REQUIRED FIX #1)**

**Valid:**
- Item 1 verbatim blocks: well-formed Markdown table with `| Key | Value |` header and `|-----|-------|` alignment. Correct.
- Item 2 bash gate: `if ! echo "${ISSUE_ID}" | grep -qE '^[A-Za-z0-9#_-]+$'; then` — syntactically valid bash, correct `-qE` flag with proper quoting.
- Item 4 replacement line: plain prose substitution — syntactically trivial.
- Item 5 scenario: `set -euo pipefail`, guard block, assertions, `exit "$FAIL"` — valid bash.
- Item 6 scenario: structurally identical to Item 5 — valid bash.

**Defect — design.md Item 3, Fix 2 (`core/block-handler.md` Step 5):**

The verbatim `jq` encoding snippet in design.md reads:
```
reason_encoded=$(printf '%s' "${reason}" | jq -Rs .)   # JSON-encode free-form reason text
reason_json_value="${reason_encoded:1:-1}"              # strip outer quotes for interpolation
```
The `${var:1:-1}` Bash substring expansion **requires Bash 4.2+**. BusyBox `sh` and `/bin/sh` on many distributions do not support negative-index substring. Since the autopilot SKILL.md already has a BusyBox-fallback code path for `find -mmin` (confirmed at lines 191/202), this inconsistency may cause confusion. The design does not note this limitation.

**REQUIRED FIX #1:** Add a prose note in design.md Item 3 Fix 2 stating that `${var:1:-1}` requires Bash 4.2+ and is safe for this use case because `core/block-handler.md` executes in the Claude Code harness (bash, not sh), OR substitute a `sed` equivalent (`sed 's/^"\|"$//g'`) that works in POSIX sh. Either resolution is acceptable; the omission must be flagged.

---

## Criterion 5 — Regex `^[A-Za-z0-9#_-]+$` Correctly Rejects Path-Traversal

**Result: PASS**

Explicit enumeration of what the regex accepts and rejects:

**Accepted characters (whitelist):**
`A-Z`, `a-z`, `0-9`, `#`, `_`, `-` (hyphen, correctly placed at end of character class to avoid range interpretation).

**Rejected characters (verified against POSIX ERE `^[A-Za-z0-9#_-]+$`):**

| Character | Category | Rejected? |
|-----------|----------|-----------|
| `/` | Path separator (Unix) | YES — not in class |
| `\` | Path separator (Windows) | YES — not in class |
| `.` | Component of `..` | YES — not in class |
| `..` | Directory traversal | YES — both chars rejected |
| ` ` (space) | Shell word split | YES — not in class |
| null byte `\0` | Shell injection | YES — not in class; `grep -qE` treats null as non-match |
| `` ` `` | Command substitution | YES — not in class |
| `$` | Variable expansion | YES — not in class |
| `"` | Shell quoting | YES — not in class |
| `'` | Shell quoting | YES — not in class |
| `(`, `)` | Subshell / regex | YES — not in class |
| `<`, `>` | Redirection | YES — not in class |
| `|` | Pipe | YES — not in class |
| `~` | Home dir expansion | YES — not in class |
| `;` | Command separator | YES — not in class |
| `&` | Background / AND | YES — not in class |
| `*`, `?` | Glob | YES — not in class |
| `[`, `]` | Glob / class | YES — not in class |
| `{`, `}` | Brace expansion | YES — not in class |
| newline | Multi-line injection | YES — `grep -qE` processes one line; `echo` with newline would result in second line not matching |

**No widening observed:** R-ITEM-2.5 and AC-ITEM-2.5 both enforce that no additional branch widens the allowlist. Design confirms this (design.md line 141: "Widening the regex... rejected").

**Minor concern (advisory, not blocking):** The `+` quantifier requires at least one character — an empty string `""` is correctly rejected (no match). The spec does not explicitly state this, but it is correct behavior.

---

## Criterion 6 — CHANGELOG Structure Matches v6.8.0 Precedent

**Result: PASS with one inconsistency (REQUIRED FIX #2)**

**v6.8.0 CHANGELOG structure (verified from `CHANGELOG.md` lines 10–46):**
```
## [6.8.0] — 2026-04-17
**MINOR** — [summary]
### Added
### Changed
### Migration notes
### Known Issues (deferred to v6.8.1)
### Internal
```

**Proposed v6.8.1 structure (from design.md):**
```
## [6.8.1] — 2026-04-18
**PATCH** — [summary]
### Fixed
### Added
```

**However:** The design.md CHANGELOG verbatim (lines 438–456 of design.md) uses `### Added` as the second subsection for the two new test scenarios. The research final.md (line 726) says `### Internal` for test scenarios ("New test scenarios: ... (+2 scenarios; total: 142)").

The v6.8.0 precedent uses `### Internal` for test scenario additions (see CHANGELOG.md line 44–46). The design.md uses `### Added`, which is a structural deviation from the v6.8.0 pattern.

**REQUIRED FIX #2:** Rename `### Added` to `### Internal` in the verbatim CHANGELOG entry in design.md (and correspondingly in requirements.md R-RELEASE-1 and formal-criteria.md AC-RELEASE-1b). The research final.md already uses `### Internal` — the design.md deviated. This keeps the CHANGELOG consistent with v6.8.0.

---

## Criterion 7 — Commit-Sequence Guidance Is Unambiguous

**Result: PASS**

The commit sequence is stated three times and is consistent across all three documents:

1. **design.md Cross-Item Dependencies table** — 5 ordering constraints, clear rationale for each.
2. **design.md Release section** — "All Item 1-6 changes land in a single `content + CHANGELOG` commit. Version-bump produces a second commit plus tag."
3. **requirements.md R-RELEASE-2** — "The content commit (R-RELEASE-1) MUST be created and pushed to the working tree before the version-bump skill is invoked."
4. **formal-criteria.md AC-RELEASE-2d** — git-log verification of commit order.

The intra-content-commit constraint (Items 5 and 6 scenarios committed in same commit as their respective contract patches) is documented in design.md at design time (lines 318 and precise sentence in Item 6 design decisions).

No ambiguity found.

---

## Criterion 8 — No Scope Creep Beyond 6 Roadmap Items

**Result: PASS**

File inventory: 19 modified + 2 created = 21 file operations. Each file maps to one of the 6 items or the release process. No new skills, no new agents, no new Automation Config keys, no new core contracts beyond what the roadmap items require.

**Research-justified expansions (not scope creep):**
- Item 2 expanded from 1 skill to 4 skills — justified by Phase 2 research showing autopilot does NOT construct `{ISSUE-ID}` paths.
- Item 3 expanded from 1 file to 3 files — justified by Phase 2 research revealing `block-handler.md` uses a worse pattern.
- Item 5 requires a prose patch before the scenario can be written — justified by gap discovery.

All expansions are explicitly flagged in research final.md and accepted into the spec. No un-flagged additions.

---

## Criterion 9 — Cross-Item Dependencies Explicit and Consistent

**Result: PASS**

**Item 5 prose-before-test dependency:**
- requirements.md R-ITEM-5.1 is listed before R-ITEM-5.2 (prose contract before scenario).
- design.md Item 5 design decisions explicitly states "Loop-contract patch must land in the SAME commit as the scenario".
- formal-criteria.md AC-ITEM-5.1a/5.1b verify the prose; AC-ITEM-5.2 verifies the scenario file. Correct ordering.

**Item 6 analogous dependency:**
- design.md Item 6 "MUST land before or in the same commit as" the scenario.
- No contradiction with Item 5. Symmetric treatment.

**Item 2 → Item 3 cross-reference:**
- R-ITEM-3.1 cross-references "the issue_id regex gate from Item 2 as the primary defense" — this is a narrative reference, not a dependency. Item 3 can be implemented independently. Design confirms this (design.md line 22: "Item 2 regex gate MAY land independently of Item 3").

**No contradictions found between any pair of items.**

---

## Criterion 10 — File-Line Citations Accurate (Spot-Check)

**Result: PASS with two inaccuracies (REQUIRED FIX #3)**

**Verified accurate:**

1. `tests/harness/run-tests.sh` lines 42, 48, 52 — CONFIRMED. Actual file shows `((PASS++))` at line 42, `((SKIP++))` at line 48, `((FAIL++))` at line 52. Exact match.

2. `skills/autopilot/SKILL.md:368` troubleshooting bullet — CONFIRMED. Actual line 368 reads `<120min old`. Exact match with the "current text" verbatim in design.md.

3. `core/fixer-reviewer-loop.md` Step 10 at line 28 — CONFIRMED. Actual line 28 matches the "Current Step 10" verbatim in design.md/research. Step 10 lacks `tokens_used` accumulation language.

4. `CHANGELOG.md:42` path discrepancy — CONFIRMED. Line 42 reads `examples/config-templates/*`. Correct identification.

5. `docs/guides/autopilot.md` line 286 — CONFIRMED. Actual content at line 286 is the "Webhook payloads are forward-compatible..." sentence, ending at exactly line 286. The insertion point "after line 286" is correct.

6. `core/block-handler.md` Step 5 lines 40–44 — CONFIRMED. Lines 40–44 show the `curl ... -d '...'` pattern without `--proto`. Exact match with "Current-state evidence" in research.

**Inaccuracies found:**

**Inaccuracy A (minor):** requirements.md R-ITEM-2.2 states gate placement "before the reference near line 87" for `skills/fix-ticket/SKILL.md`. Research final.md Item 2 says "insertion after line ~87". These are equivalent but the `~` approximation makes them ambiguous. The actual file-line should be confirmed at implementation time (not a blocking defect, but implementers must re-verify).

**Inaccuracy B (REQUIRED FIX #3):** design.md Item 5, under "Current Step 10 (verbatim, line 28 of `core/fixer-reviewer-loop.md`)", the comment says "line 28". The actual `core/fixer-reviewer-loop.md` Step 10 text is on line 28 of the file — this is CONFIRMED. However, the research final.md calls out `state/schema.md:344` for the cumulative-semantics prose. The scenario Assertion 4 in the verbatim bash greps for `'tokens_used.*running total|cumulatively across iterations'` in `core/state-manager.md`. The research final.md lines 480–487 show that `core/state-manager.md:138-148` contains exactly `fixer_reviewer.tokens_used  += iteration_tokens_used   (running total)` and `The \`fixer_reviewer\` stage accumulates token counts cumulatively across iterations`. This is consistent with the scenario assertion.

**Re-evaluation: no actual line citation error exists for Inaccuracy B.** After cross-checking, Assertions 3 and 4 in the crash-recovery scenario target the correct files with correct grep patterns for content that is already present. No fix required on this point.

**Inaccuracy C (REQUIRED FIX #3):** The `docs/reference/config.md` citations differ between spec and actual file. R-ITEM-1.2 says "matching `docs/reference/config.md:26-41` verbatim". The actual `docs/reference/config.md` has the Autopilot keys table starting at line 15 (the `| Key | Type | Default | Description |` header), with the bare-value example at lines 35–41. The lines 26–41 cited in the requirement do not correspond to the table structure in the authoritative config reference file. The `docs/reference/config.md` file (verified above) has the `### Keys` table at lines 15–23 and the `### Example` block starting at line 25, with the bare `### Autopilot` table block at approximately lines 34–41. The "verbatim: `docs/reference/config.md:26-41`" citation is off by ~8 lines. The underlying content (7 keys, correct defaults) is correct; only the line numbers are stale. This is a spec accuracy defect that could confuse Phase 8's mechanical verification.

**REQUIRED FIX #3:** Update R-ITEM-1.2 in requirements.md to remove the specific line numbers from the `docs/reference/config.md` citation, or update them to the actual verified line range. The authoritative defaults are in the `### Example` block of `docs/reference/config.md` (not lines 26-41). Use content-based reference ("the 7-key default table in `docs/reference/config.md`") rather than stale line numbers.

---

## Summary of Required Fixes

| # | Location | Issue | Severity |
|---|----------|-------|----------|
| FIX #1 | `design.md` Item 3 Fix 2 | `${var:1:-1}` Bash 4.2+ note absent — may confuse implementers on BusyBox-aware paths | REQUIRED |
| FIX #2 | `design.md` + `requirements.md` + `formal-criteria.md` CHANGELOG sections | `### Added` subsection name for test scenarios should be `### Internal` per v6.8.0 precedent | REQUIRED |
| FIX #3 | `requirements.md` R-ITEM-1.2 | `docs/reference/config.md:26-41` line citation is inaccurate (~8 lines off); replace with content-based reference | REQUIRED |

## Advisory Notes (non-blocking)

| # | Note |
|---|------|
| A | No test scenario for Item 1 (config-template coverage) — acknowledged as optional scope in research.md, acceptable for PATCH |
| B | Empty string `""` is correctly rejected by `^[A-Za-z0-9#_-]+$` (`+` requires ≥1 char) — not documented explicitly; spec could mention this as a valid invariant |

---

## Final Assessment

The spec is internally consistent, well-structured, and covers all 6 roadmap items with no scope creep. Requirements are atomic and testable. Design decisions have clear rationale. The regex analysis is thorough and correct. Commit sequencing is unambiguous. Three required fixes are mechanical corrections (Bash version note, subsection name alignment, stale line number). None affects the functional design. After these fixes, the spec is ready for Phase 5 (TDD).
