# Phase 4 Re-Review — Round 2
Date: 2026-04-18
Reviewer: Re-Review Agent (round 2 after revisions)
Input: `revision-round-2.md` (9 fixes claimed) + 3 spec files verified against 7 required fix criteria

---

## Per-Fix Verdicts

### Q-FIX-1 — `${var:1:-1}` replaced with `jq -n --arg` (POSIX-safe)
**PASS**

Verification:
- `design.md` verbatim Fix 2 snippet (lines 183–210): uses `payload=$(jq -n --arg event ... --arg reason ...)` exclusively. No `${var:1:-1}` or `${encoded:1:-1}` appears in the verbatim insert.
- `${var:1:-1}` appears ONLY in rationale/rejected-alternatives text at lines 201 and 503 (correct: "no Bash-specific `${var:1:-1}` or equivalent POSIX construct needed"; "POSIX-safe; no Bash 4.2+ `${var:1:-1}` required"). These are anti-pattern callouts, not live snippets.
- `formal-criteria.md` AC-ITEM-3.2 (lines 100–103): positive greps for `--data-binary @-`, `--proto "=http,https"`, `<<EOF`, `jq -n`, `--arg`; negative check `! grep -qE '\$\{[A-Za-z_][A-Za-z0-9_]*:[0-9]+:-[0-9]+\}'` is present.
- AC-ITEM-3.3 (lines 105–108): greps for `jq -n --arg` in `docs/guides/autopilot.md`. Present and correct.
- No `jq -Rs .` encoding pattern retained in any verbatim insert.

---

### Q-FIX-2 — `### Added` → `### Internal` for test scenarios
**PASS**

Verification:
- `requirements.md` R-RELEASE-1 (line 128): mandates `### Internal` subsection; cites v6.8.0 precedent; `### Added` not present in the normative text.
- `design.md` Release table (line 489): "`### Fixed` + `### Internal` subsections". CHANGELOG verbatim (line 507): `### Internal` header followed by the two scenario entries. Design decisions (line 514): explicit rationale that `### Internal` matches v6.8.0 precedent and `### Added` is reserved for user-visible additions.
- `formal-criteria.md` AC-RELEASE-1b (lines 212–226): positive grep for `^### Internal$`; NEGATIVE grep that `^### Added$` is absent inside v6.8.1 block; both scenario filenames checked.
- No stray `### Added` appears inside any normative CHANGELOG block in any of the three spec files.

---

### Q-FIX-3 — Stale line citation `docs/reference/config.md:26-41` replaced in R-ITEM-1.2
**PASS**

Verification:
- `requirements.md` R-ITEM-1.2 (line 22): reads "…matching the 7-key Autopilot table under the `### Example` block of `docs/reference/config.md` verbatim…" — content-based reference, no `26-41` line numbers.
- `grep -r '26-41' requirements.md` → no matches.
- Advisory note: `design.md` line 98 (Design decisions for Item 1) still contains the stale `docs/reference/config.md:26-41` reference as a normative-anchor internal annotation. The required fix was scoped to `requirements.md` R-ITEM-1.2 only; the design.md occurrence is non-normative (private rationale for why `Dry run | false` is correct). Does not block Phase 5.

---

### DA-F-1 — `fix-bugs` gate placement clarified (loop body, not outer Step 0)
**PASS**

Verification:
- `requirements.md` R-ITEM-2.2 (lines 40–46): explicit per-skill placement table; fix-bugs entry reads "ISSUE_ID is only bound INSIDE the per-issue loop body… gate is therefore placed at the TOP of the per-issue loop body… The gate is NOT placed in outer Step 0." Closing note: "the operative AC check is `gate_line < path_line`."
- `design.md` Item 2 verbatim gate section (lines 119–122): "Placement note:" paragraph added before the gate block; distinguishes single-issue entry points (Step 0) vs. fix-bugs (top of loop body).
- `formal-criteria.md` AC-ITEM-2.2 (lines 54–56): explicitly notes "This AC is the operative mechanical check… it is satisfied whether the gate sits at outer Step 0 (single-issue skills) or inside the per-issue loop body (fix-bugs), as long as it textually precedes the first path reference."
- Both placements documented; no remaining contradiction.

---

### DA-F-2 — `echo | grep -qE` replaced with `[[ =~ ]]` bash built-in
**PASS**

Verification:
- `design.md` verbatim gate block (line 127): `if [[ ! "${ISSUE_ID}" =~ ^[A-Za-z0-9#_-]+$ ]]; then` — bash built-in form.
- Security rationale paragraph (lines 133–135) explains why `[[ =~ ]]` anchors to the entire string vs. grep's per-line evaluation; newline injection example `$'../../etc/passwd\nPROJ-42'` included in reject examples.
- `requirements.md` R-ITEM-2.4 (line 52): mandates `[[ "${ISSUE_ID}" =~ ... ]]` form; explicitly forbids `echo "${ISSUE_ID}" | grep -qE`.
- `requirements.md` R-ITEM-2.5 (line 55): CR (`\r`) added to forbidden characters.
- NEW `requirements.md` R-ITEM-2.6 (lines 57–58): explicit newline-injection rejection requirement with attack payload example.
- `requirements.md` Meta (line 8): count updated to 20 (was 19); R-ITEM-2.6 listed among negative requirements.
- `formal-criteria.md` AC-ITEM-2.4 (lines 63–70): four sub-checks including positive `[[ =~ ]]` grep and NEGATIVE `echo | grep -qE` grep.
- NEW `formal-criteria.md` AC-ITEM-2.6 (lines 77–89): behavioral shell-invocation test with `ISSUE_ID=$'good\nbad'`.
- `formal-criteria.md` Meta (line 8): count updated to 31 (was 29).

---

### DA-F-3 — Meta-test validation chain documented; positive counter-form greps added
**PASS**

Verification:
- `design.md` Item 6 "Validation chain" subsection (lines 462–471): explicit 4-step chain. Steps 1–3 marked OPERATIVE; Step 4 (single-scenario smoke) marked complementary. Explains why single-scenario mode was already correct pre-fix.
- "Assumptions and known scope limits" subsection (lines 473–477): documents the baseline-cleanliness requirement for AC-ITEM-6.2 and acknowledges single-scenario mode pre-fix correctness.
- Meta-test scenario (design.md lines 409–454): each of Assertions 1, 2, 3 now has two sub-checks — unsafe form absent (negative) AND safe form present (positive). E.g., Assertion 1 checks both `((FAIL++))` absent AND `FAIL=$((FAIL + 1))` present.
- `formal-criteria.md` AC-ITEM-6.1a (lines 162–165): positive greps for all three safe counter forms present.

---

### DA-F-4 — `v681-harness-exit-propagation.sh` naming consistency (no `ac-` prefix)
**PASS**

Verification:
- `design.md` lines 457–458: explicit cross-reference that all 4 spec documents MUST use `v681-harness-exit-propagation.sh`; `ac-v681-` name explicitly rejected, Phase-2 name labelled discarded.
- `formal-criteria.md` AC-ITEM-6.4a (lines 191–196): canonical filename `v681-harness-exit-propagation.sh` used in the `test -f` command. CAUTION block (lines 196) names the rejected Phase-2 name `ac-v681-harness-exit-propagation.sh` and provides companion negative check: `test ! -f tests/scenarios/ac-v681-harness-exit-propagation.sh`.
- `requirements.md` R-ITEM-6.4 (line 121): uses `v681-harness-exit-propagation.sh` (no `ac-` prefix).
- `design.md` file inventory (line 545): `v681-harness-exit-propagation.sh` (no `ac-` prefix).
- Spot-checked: `ac-v681-harness` appears ONLY in revision-round-2.md (historical reference to Phase-2 name) and in devil's-advocate review (original defect description). None of the three normative spec files use it as a canonical name.

---

## Regression / Scope-Creep Sanity Check

- Total requirement count 19→20 (added R-ITEM-2.6): expected and justified.
- Total AC count 29→31 (added AC-ITEM-2.6 + positive Item 6 counter-form check): expected and justified.
- No new skills, agents, config keys, or core contracts introduced.
- No normative AC weakened or removed.
- Advisory fixes (AC-RELEASE-1c clarity, R-ITEM-1.4 "bare" parenthetical) are tightening, not scope creep.
- One residual non-blocking issue: `design.md:98` (Item 1 Design decisions) still has stale `docs/reference/config.md:26-41` as an internal annotation. This was not in the required fix scope and does not affect Phase 8 mechanical verification.

---

## Overall Verdict: PASS

All 7 required fixes verified as correctly applied. No blocking regressions introduced.

| Fix | Verdict |
|-----|---------|
| Q-FIX-1 (`${var:1:-1}` → `jq -n --arg`) | PASS |
| Q-FIX-2 (`### Added` → `### Internal`) | PASS |
| Q-FIX-3 (stale `config.md:26-41` line citation) | PASS |
| DA-F-1 (fix-bugs gate placement clarified) | PASS |
| DA-F-2 (`echo|grep` → `[[ =~ ]]` + R-ITEM-2.6 + AC-ITEM-2.6) | PASS |
| DA-F-3 (meta-test validation chain + positive counter-form greps) | PASS |
| DA-F-4 (`v681-harness-exit-propagation.sh` naming consistency) | PASS |

**Spec is cleared for Phase 5 (TDD).**
