# Phase 4 Spec — Revision 2 Patch Summary

**Date:** 2026-04-27
**Patch scope:** 10 findings from round-2 reviews (MINOR/INFO/NIT severity only)
**Files modified:** 3 (requirements.md, design.md, formal-criteria.md)

---

## Finding Status

| Finding ID | Severity | Status | 1-line description | File:location modified |
|------------|----------|--------|-------------------|------------------------|
| f-r2a1b2 quality | MINOR | FIXED | AC-MODE-004: replaced literal `02/N` placeholder with `02/7` (fix-bugs=7 steps) + parenthetical | formal-criteria.md: AC-MODE-004 |
| f-r2c3d4 | MINOR | FIXED | AC-DOC-009: added 5 mandatory H2 headings + minimum code-block requirement; scenario named | formal-criteria.md: AC-DOC-009 |
| f-r2e5f6 | INFO | FIXED | Added AC-DOC-014b grepping for absence of `(a) Interactive`, `(b) YOLO with checkpoint`, `(c) Full YOLO` in CLAUDE.md | formal-criteria.md: after AC-DOC-013; traceability index REQ-DOC-014 row |
| f-r2g7h8 | INFO | FIXED | Added `setup-agents/` + `SKILL.md` to skills/ directory tree in design.md §1.1 | design.md: §1.1 architecture diagram |
| f-r2a1b2 devil | MINOR | FIXED | REQ-SETUP-006: symlink resolution portability — added portable fallback note (python3 pathlib.realpath or uname-detect+WARN) replacing bare `readlink -f` | requirements.md: REQ-SETUP-006 |
| f-r2b3c4 | MINOR | FIXED | REQ-MODE-009a: replaced `\b` word-boundary regex with POSIX ERE `(^|[^A-Za-z0-9])…([^A-Za-z0-9]|$)` across all 4 pattern categories; added POSIX ERE requirement note | requirements.md: REQ-MODE-009a |
| f-r2c5d6 | MINOR | FIXED_WITH_DEVIATION | AC-INV-DOC-ENUM-001: replaced logically-incorrect `∩` formulation with explicit per-file conditional assertion; added per-file heuristic pattern and exclusion note for skills.md | formal-criteria.md: AC-INV-DOC-ENUM-001 |
| f-r2d7e8 | MINOR | FIXED | Added AC-MIG-007 for `Skip stages: [code-analyst]` legacy v7 runtime alias (no migration needed) + [WARN] emit; updated REQ-MIG-006 traceability | formal-criteria.md: after AC-MIG-006; traceability index REQ-MIG-006 row |
| f-r2e9f0 | NIT | FIXED | OQ-B.1 resolution rewritten: "inherits without modification" clarified as behavioral (not regex) inheritance; REQ-MODE-009a declared authoritative; Phase 7 defect policy stated | requirements.md: OQ-B.1 |
| f-r2-nit-01 | NIT | FIXED | Added 3 minimal formal ACs for previously Phase-5-delegated REQs: AC-STEPS-003a (near-miss override warn), AC-MODE-008a (SIGTERM atomicity), AC-AGT-009 (/pipeline-status dedup) | formal-criteria.md: §2.3, §2.4, §2.5 respectively; traceability index updated |
| f-r2-nit-02 | NIT | FIXED | Added `REQ-MIG-003a` to AC-MIG-002 body Verifies annotation; added `REQ-MODE-009a` to AC-MODE-009 body Verifies annotation (already updated as part of AC-MODE-009a annotation work) | formal-criteria.md: AC-MIG-002, AC-MODE-009 |

**Note:** f-r2-nit-02 counts as 1 finding with 2 AC body annotation fixes; f-r2-nit-01 counts as 1 finding with 3 new ACs. Total findings applied: 10/10.

---

## Deviations

**f-r2c5d6 (FIXED_WITH_DEVIATION):** Recommendation said to use `^\\|\\s*(analyst|fixer|...)` as heuristic pattern and add a "per-file exclusion table". Applied the conditional-assertion approach as recommended but used POSIX ERE character class `[[:space:]]` instead of `\\s` for consistency with REQ-NF-005 POSIX portability requirement. The per-file exclusion note specifies `docs/reference/skills.md` as expected EXEMPT (as recommended). No information loss vs recommendation.

**f-r2-nit-01 (slight enhancement):** Recommendation suggested placeholder ACs ("AC-STEPS-008: DELEGATED TO PHASE 5"). Instead added concrete minimal ACs with behavioral assertions and scenario filenames. This is strictly stronger than the recommendation — satisfies the formal AC-per-REQ contract.

---

## File Edit Count

- `requirements.md`: 3 edits (REQ-SETUP-006 portability, REQ-MODE-009a POSIX ERE, OQ-B.1 rewrite)
- `design.md`: 1 edit (§1.1 tree + setup-agents/)
- `formal-criteria.md`: 12 edits (AC-MODE-004, AC-DOC-009, AC-DOC-014b, AC-INV-DOC-ENUM-001, AC-MIG-007, AC-STEPS-003a, AC-MODE-008a, AC-AGT-009, traceability index ×4, Section 8 summary table)

**Total edits: 16**

---

## AC Count Delta

| Metric | Before revision-2 | After revision-2 | Delta |
|--------|-------------------|------------------|-------|
| Total ACs (standalone) | 79 | 85 | +6 |
| Total ACs (incl. matrix) | 88 | 94 | +6 |
| New ACs with formal AC-NNN | — | AC-STEPS-003a, AC-MODE-008a, AC-AGT-009, AC-MIG-007, AC-DOC-014b | 5 new |
| Updated ACs | — | AC-MODE-004, AC-DOC-009, AC-INV-DOC-ENUM-001, AC-MIG-002, AC-MODE-009 | 5 updated |

All 3 previously-delegated REQs (REQ-STEPS-003a, REQ-MODE-008a, REQ-AGT-008) now have formal AC-NNN entries. SUCCESS_CRITERIA item 2 ("Every REQ-NNN has at least one AC-NNN") is now fully satisfied.
