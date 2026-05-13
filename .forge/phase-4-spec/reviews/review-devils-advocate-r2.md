# Phase 4 — Devil's Advocate Review — Round 2

**Forge run:** `forge-2026-05-13-001`
**Reviewer role:** Devil's Advocate (adversarial review)
**Round:** 2 (spec-revision verification)
**Date:** 2026-05-13

---

## Round-1 Defect Status

### f-da0001 — sed delimiter bug `(^|[^./])` with `|` delimiter

**Status: VERIFIED FIXED in Phase B canonical patterns.**

Independent re-run on GNU sed 4.x (Git-Bash):

- REJECTED pattern `s|(^|[^./])core/...|...|g` → `sed: -e expression #1, char 36: unknown option to 's'` (exit 1). Confirmed broken.
- CANONICAL pattern `s|([^./])core/([a-z][a-z-]*\.md)|\1../../core/\2|g` → exit 0. Rewrites mid-line occurrences correctly.
- Dual-pattern line: BOTH occurrences rewritten in single pass. Confirmed.
- Idempotency: second pass produces zero additional changes. Confirmed.
- `./core/` and `../core/` forms: NOT double-rewritten. Confirmed.

Design §B.1 and §B.2 contain the corrected canonical patterns. The fix is genuine and fully documented with live test evidence.

**HOWEVER: f-da0001 survives in FC-B-7 (HIGH — see NEW FINDINGS below).**

### f-da0002 — FC-D-1 false-positive on automation-config.md:585

**Status: VERIFIED FIXED.**

New FC-D-1 grep pattern requires `13` to be adjacent to `scenario`, `harness`, or `v10-*.sh` token — not merely within 5 lines of a v10-*.sh reference. Live verification:

- `grep -nE 'v10-[a-z-]+\.sh' docs/reference/automation-config.md` → line 585 (`v10-counts-invariants.sh`).
- Context window (lines 580-590) contains "13 optional" — but the refined inner `grep -qE` pattern does NOT match "13 optional" against the adjacency rule.
- `fail=0` result confirmed. No false-positive.

FC-D-1 also correctly TRIGGERS on a genuine stale-13 line ("13 v10-scenarios exist in harness") and correctly PASSES on a post-update "15 v10-scenarios" line.

### f-da0003 — No pre-Phase-B PROBE depth assertion (FC-A-6 missing)

**Status: VERIFIED FIXED.**

FC-A-6 is present in `formal-criteria.md` §FC-A-6 (pp. 86-107). It:
- Uses `grep -lF 'PROBE="../../../core/mcp-preflight.md"'` against all 3 guard-block.md files.
- Explicitly states "This FC runs AFTER Phase A is complete but BEFORE Phase B sed."
- Correctly catches a wrong-depth PROBE that `[^./]` idempotency guard would silently miss.

The ordering constraint is documented in both formal-criteria.md (FC-A-6 header) and design.md Implementation Order (steps 1-4 sequence: A.4 → A.3 → A.1/A.2 → B.3).

### f-da0004 — REQ-A-2 CWD contradiction

**Status: VERIFIED FIXED.**

REQ-A-2 now reads: "…computed as the depth-correct relative path from the **guard-block.md file's own directory** (i.e. `../../../core` for `skills/{name}/data/guard-block.md`, which sits at depth-3 from repo root). The probe path resolves relative to the guard-block.md file's directory because guard-block.md is included by SKILL.md via a Read directive whose relative paths are evaluated relative to the including file's location, not to Claude's CWD."

This is unambiguous. No CWD-of-Claude confusion remains.

### f-da0005 — FC-B-6 count ambiguity (188 vs 185)

**Status: VERIFIED FIXED.**

FC-B-6 rationale block explicitly decomposes: 185 (Phase B rewrites) + 3 (Phase A PROBE assignments in guard-block.md files) = 188. The B3 clarifier prose example tokens (`../core/`, `../../core/`, `../../../core/`) are shown NOT to match because they lack a filename component. The ±5 authoring-drift escape hatch is present. The logic is clear and defensible.

---

## New Adversarial Probes (Round 2)

### Probe A — Does line-start assumption create a future regression risk?

**Verdict: CONCERN (LOW)**

The spec documents the zero-line-start-occurrences assumption clearly in design.md §B.1 (the "Line-start edge case — REJECTED ALTERNATIVE" block, line 148). It explicitly states:

> "if a future contributor adds a line-start occurrence, the static depth-lint (FC-C-2) will catch the resulting unrewritten path during CI."

This is the correct mitigation. FC-C-2 (`v10-core-path-depth-consistency.sh`) uses `grep -nE '(\.\./){1,}core/[a-z][a-z-]*\.md|[^./]core/[a-z][a-z-]*\.md|^core/[a-z][a-z-]*\.md'` — the `^core/` branch explicitly covers the line-start case for CI detection.

The concern is MINOR: the §B.2 verification fixture labels the "At start: core/early.md" line as a "line-start (synthetic edge case)" but then explains it is actually preceded by a space (`At start: ` prefix). This creates a subtle fixture labelling confusion: the fixture does NOT actually test a true line-start case (column 0). A genuinely column-0 `core/early.md` would fail `[^./]` (no preceding character to match) and go unrewritten. The CI lint would catch it, but the spec's verification log does not confirm the lint's `^core/` branch fires.

**Assessment:** FC-C-2's `^core/` grep clause is present and correct. The CI backstop holds. Constraint is documented. Not HIGH.

### Probe B — Can a wrong-depth Phase A authoring error still slip past FC-A-6?

**Verdict: PASS**

FC-A-6 checks for the verbatim string `PROBE="../../../core/mcp-preflight.md"` before Phase B runs. This directly catches wrong-depth authoring in Phase A (e.g., `../core/` instead of `../../../core/`). The `[^./]` idempotency guard cannot mask an already-wrong relative path that contains `../` (since `../core/` DOES contain `./`, the sed would not rewrite it — but it starts with `..` not `.` so the class `[^./]` would not match the `./` at position 2 anyway). More precisely: `../../../core/mcp-preflight.md` with `..` at the start — the character before `core/` is `/`, which is in `[^./]` (not `.` or `/`... wait, `/` IS excluded by `[^./]`). Actually `[^./]` excludes both `.` and `/`. So `../core/` — the character before `core/` is `/`, which IS excluded. So `../core/` already has `./`-class char before `core/`. A wrong `../../core/` would also have `/` before `core/`. FC-A-6 catches this BEFORE Phase B, so the authoring error is caught at the gate regardless.

Implementation Order step 2 creates the file with depth-3 PROBE, FC-A-6 validates it at step "after Phase A before Phase B." The ordering is enforced in the spec. No gap.

### Probe C — Does the FC-D-1 grep handle both pre-v10.2.0 (13) and post-v10.2.0 (15) correctly?

**Verdict: PASS**

Verified live:

1. A genuine "13 scenarios" context → TRIGGERS (correctly flags stale count). Exit 0 from outer `test "$fail" -eq 0` → FAIL (correct, pre-update).
2. "13 optional" near v10-counts-invariants.sh → does NOT trigger (no false-positive). Confirmed.
3. After update to "15 scenarios" → does NOT trigger "13" (correct, post-update the FC passes trivially).

The v10.1.2 HEAD verification claim in FC-D-1 ("Verified against v10.1.2 HEAD: returns 0") is consistent with live test result.

### Probe D — Does "188 vs 185" rationale create implementer confusion?

**Verdict: PASS**

The FC-B-6 rationale is step-by-step: 185 (Phase B sed scope) + 3 (Phase A PROBE assignments) = 188. It also pre-empts the clarifier-prose double-count concern by showing those tokens don't match (no filename component). The ±5 escape hatch with "update both test value AND this rationale block in a single design-doc-correction commit" gives Phase 7 an actionable procedure.

One minor clarity note: the rationale says "40 files × pre-Phase-A baseline" — this phrasing is slightly ambiguous because Phase A adds a new file (scaffold/data/guard-block.md) that is NOT in the pre-Phase-A 40-file scope. But the rationale correctly states "+3 occurrences added by Phase A" separately, so the arithmetic is sound even if the phrasing is slightly compressed.

**Not HIGH. Not CONCERN-worthy beyond advisory.**

---

## New Findings (Round 2 Fresh)

### f-da-r2-001 — FC-B-7 retains the broken `(^|[^./])` sed pattern (CRITICAL)

**FC:** FC-B-7 (`formal-criteria.md` lines 213-224)

**Evidence:**

```bash
after=$(printf '%s\n' "$before" | sed -E 's|(^|[^./])core/([a-z][a-z-]*\.md)|\1../../core/\2|g')
```

This is the exact broken pattern from f-da0001, now present inside the FC-B-7 idempotency check. Live confirmation on GNU sed 4.x:

```
$ printf '%s\n' "test core/foo.md" | sed -E 's|(^|[^./])core/([a-z][a-z-]*\.md)|\1../../core/\2|g'
sed: -e expression #1, char 36: unknown option to `s'
EXIT=1
```

**Impact:** FC-B-7, as written, will ALWAYS FAIL on GNU sed with exit 1 from the sed command itself — not from the idempotency check. Phase 7 implementer running FC-B-7 verbatim will see a spurious failure on every post-rewrite file. The idempotency property IS guaranteed by the correct canonical pattern (independently verified), but the FC-B-7 verification script is broken.

**Required fix:** Replace `s|(^|[^./])core/...|...|g` in FC-B-7 with `s|([^./])core/([a-z][a-z-]*\.md)|\1../../core/\2|g` (drop the `^` branch, use plain character class). This is the exact same fix applied to the Phase B canonical pattern.

**Severity: CRITICAL** — An FC that always errors on the target platform provides zero verification value and will block Phase 8 commander sign-off if run literally.

---

```json
[
  {
    "id": "f-da-r2-001",
    "severity": "CRITICAL",
    "fc": "FC-B-7",
    "artifact": "formal-criteria.md",
    "location": "line ~216",
    "title": "FC-B-7 retains broken (^|[^./]) sed pattern — always errors on GNU sed 4.x",
    "description": "FC-B-7's idempotency check sed invocation uses s|(^|[^./])...|...|g with | as delimiter. This causes 'unknown option to s' on GNU sed 4.9, identical to f-da0001. The FC will always exit non-zero from the sed error, not from any actual idempotency violation.",
    "fix": "Replace the s|...| pattern in FC-B-7 with the canonical form s|([^./])core/([a-z][a-z-]*\\.md)|\\1../../core/\\2|g (drop ^ branch, use plain character class, retain | delimiter).",
    "confidence": 0.99
  }
]
```

---

## Summary Table

| Item | Round-1 verdict | Round-2 verdict |
|------|----------------|----------------|
| f-da0001 (sed delimiter bug) | FAIL | VERIFIED FIXED in Phase B patterns |
| f-da0002 (FC-D-1 false-positive) | FAIL | VERIFIED FIXED |
| f-da0003 (no FC-A-6) | FAIL | VERIFIED FIXED |
| f-da0004 (REQ-A-2 CWD wording) | FAIL | VERIFIED FIXED |
| f-da0005 (FC-B-6 count ambiguity) | FAIL | VERIFIED FIXED |
| Probe A (line-start assumption) | — | CONCERN (LOW) |
| Probe B (FC-A-6 dispatch correctness) | — | PASS |
| Probe C (FC-D-1 pre/post both work) | — | PASS |
| Probe D (188 vs 185 implementer clarity) | — | PASS |
| f-da-r2-001 (FC-B-7 broken sed) | — | **CRITICAL NEW FINDING** |

---

## Verdict

**FAIL** (confidence 0.97)

1 CRITICAL finding: `f-da-r2-001` — FC-B-7 in `formal-criteria.md` uses the broken `(^|[^./])` alternation with `|` delimiter, identical to the f-da0001 defect that was fixed in the Phase B canonical patterns but missed in the verification FC. The fix is a one-line change: replace the sed pattern in FC-B-7 with the canonical `([^./])` form. All 5 round-1 defects are genuinely fixed. No other HIGH or CRITICAL issues found.

**Required action before PASS:** Fix FC-B-7 sed pattern. Re-submit for Round 3 (single-issue verification only).
