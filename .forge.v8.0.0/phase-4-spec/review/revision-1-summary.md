# Phase 4 Spec — Revision 1 Summary

**Date:** 2026-04-27
**Revision agent role:** Address all BLOCKER + MAJOR + MINOR + selected NIT findings from Round 1 reviews
**Files modified:**
- `.forge/phase-4-spec/final/requirements.md`
- `.forge/phase-4-spec/final/design.md`
- `.forge/phase-4-spec/final/formal-criteria.md`

---

## File-existence check (devil's advocate f-a2b3c4)

Verified via `ls docs/reference/`: `pipeline.md` (singular) does **NOT** exist; `pipelines.md` (plural) is a separate pre-existing file. REQ-DOC-009 fixed to **CREATE** new file (option a from devil's advocate recommendation).

---

## Findings table

### BLOCKERs (3/3 fixed)

| ID | Status | Fix description | File:line(s) |
|----|--------|-----------------|--------------|
| f-a1b2c3 | FIXED | REQ-OVR-003 enumerates `[meta]` as **free-form table** (all sub-keys accepted, exempt from REQ-OVR-004 unknown-key rejection); REQ-OVR-004 + AC-DOC-002 cross-reference [meta] semantics | requirements.md REQ-OVR-003, REQ-OVR-004; formal-criteria.md AC-DOC-002 |
| f-b3c4d5 | FIXED | REQ-MODE-007 defines `{total}` as **physical file count** (static literal in entry SKILL.md); conditional un-triggered steps counted in {total} but NN advances non-monotonically; `s` semantics clarified | requirements.md REQ-MODE-007 |
| f-c5d6e7 | FIXED | New REQ-STEPS-003a: `[WARN] Possible misnamed step override` for case-fold / zero-pad / underscore-hyphen near-misses; falls through to default | requirements.md REQ-STEPS-003a |

### MAJORs (9/9 fixed)

| ID | Status | Fix description | File:line(s) |
|----|--------|-----------------|--------------|
| f-d7e8f9 | FIXED | REQ-SETUP-004 + REQ-SETUP-005: idempotent regen IS subject to preview prompt (only --yolo bypasses); first-time / regen / --force all behave uniformly | requirements.md REQ-SETUP-004, REQ-SETUP-005 |
| f-e9f0a1 | FIXED | New REQ-MIG-003a: explicit handling for test-engineer non-rename case + e2e-test-engineer.md merging into test-engineer.toml with `[applies-when --e2e=true]` sentinel | requirements.md REQ-MIG-003a |
| f-f1a2b3 | FIXED | New REQ-AGT-008: /pipeline-status reader dedup logic — prefer v8 keys, use v7 alias as fallback, WARN on inconsistent values; v7.0.0 rename precondition documented | requirements.md REQ-AGT-008 |
| f-c4d5e6 | FIXED | REQ-MIG-002 step 4: HTML comment `<!-- migrated v7→v8 -->` placed ABOVE Pipeline Profiles heading (NOT inside table); design.md Section 6.1 step 5 aligned | requirements.md REQ-MIG-002, design.md Section 6.1 |
| f-d6e7f8 | FIXED | New REQ-MODE-008a: SIGTERM/SIGINT atomicity — `last_completed_step` only advances via atomic write-then-rename AFTER agent + post-step-gate complete; trap handlers MUST NOT write state.json | requirements.md REQ-MODE-008a |
| f-e8f9a0 | FIXED | New REQ-DOC-014: explicit CLAUDE.md content-update REQ separate from REQ-INV-004 verification — covers Bug-Fix/Feature/Scaffold pipeline sections, Architecture section, Model Selection table | requirements.md REQ-DOC-014 |
| f-f0a1b2 | FIXED | New REQ-MODE-009a: deterministic `is_vague` function spec — word_count >= 20 AND >=1 token from concrete framework/version/command/extension regex; 4 mandatory Phase 5 boundary scenarios | requirements.md REQ-MODE-009a |
| f-a2b3c4 | FIXED | REQ-DOC-009: confirmed pipeline.md does NOT exist — changed to NEW file CREATE; pipelines.md (plural, pre-existing) explicitly out of scope | requirements.md REQ-DOC-009 |
| f-b4c5d6 | FIXED | AC-INV-EMAIL-001: replaced domain-allowlist negative grep with whitelist approach — extract all email-like tokens via wide regex, assert each is filip.sabacky@ceosdata.com or in non-maintainer context (example.*, noreply, fenced placeholder block) | formal-criteria.md AC-INV-EMAIL-001 |
| f-c6d7e8 | FIXED | REQ-DOC-006 amended: `/scaffold` row description SHALL describe --yolo/default/--step-mode flags (NOT 3-mode interactive prompt); other rows replace deprecated v7 agent names | requirements.md REQ-DOC-006 |

### MINORs (6/6 fixed)

| ID | Status | Fix description | File:line(s) |
|----|--------|-----------------|--------------|
| f-d8e9f0 | FIXED | AC-INV-PERM-001: explicit frontmatter-only extraction via awk/sed (lines 2..N between two `---`); grep applied ONLY to extracted block, not full file | formal-criteria.md AC-INV-PERM-001 |
| f-e0f1a2 | FIXED | AC-STEPS-001 line threshold: 150 → 120 (matches design "~100 lines" intent + 20 headroom); AC-STEPS-002 phrased as "5 to 8 inclusive" (5 ≤ count ≤ 8); REQ-STEPS-001 also updated | formal-criteria.md AC-STEPS-001, AC-STEPS-002; requirements.md REQ-STEPS-001 |
| f-f2a3b4 | FIXED | New AC-OVR-008: dedicated provenance-log AC for REQ-OVR-007; tests 3 cases (toml/md/none) with literal regex | formal-criteria.md AC-OVR-008 |
| f-a4b5c6 | FIXED | REQ-AGT-006: explicit re-dispatch mapping table (deprecated name → v8 agent + arg) for /resume-ticket; functional, not just logged | requirements.md REQ-AGT-006 |
| f-b6c7d8 | FIXED | REQ-DOC-011: chose option (a) — step-override-example.md contains placeholder content INLINE as fenced markdown block (no sibling file required); 4 files total | requirements.md REQ-DOC-011 |
| f-c8d9e0 | FIXED | AC-CT-002: find command amended to `-not -path '*/steps/*'` for robustness | formal-criteria.md AC-CT-002 |
| f-d1e2f3 | FIXED | design.md Section 5.1: explicit GOT_YOLO/GOT_STEP_MODE flags + post-loop check; Phase 8 lint asserts both substrings appear in entry SKILL.md files | design.md Section 5.1 |

### NITs (2/2 fixed)

| ID | Status | Fix description | File:line(s) |
|----|--------|-----------------|--------------|
| f-e3f4a5 | FIXED | REQ-OVR-004 line-number qualifier kept but cross-referenced to AC-OVR-004 (option b — line number is conditional on parser support; AC remains optional check) | requirements.md REQ-OVR-004 |
| f-a6b7c8 | FIXED | REQ-AGT-001: parenthetical formula added — "each merge eliminates 1 net agent: −1 × 3 merges = −3; 21 − 3 = 18" | requirements.md REQ-AGT-001 |

### Compliance review findings

| ID | Status | Fix description | File:line(s) |
|----|--------|-----------------|--------------|
| f-ct-phan | FIXED | Section 5 counts table phantom AC-CT-006/007 references replaced with AC-DOC-001..004 (for new guides row) and AC-DOC-011 (for examples customization dir row) | requirements.md Section 5 |
| f-trc-003 | FIXED | AC-DOC-002 body Verifies tag now lists "REQ-DOC-002, REQ-OVR-003"; traceability index for REQ-OVR-003 now points to AC-DOC-002 explicitly | formal-criteria.md AC-DOC-002, traceability index REQ-OVR-003 |
| f-trc-007 | FIXED | Addressed via new AC-OVR-008 (dedicated AC); traceability index updated to map REQ-OVR-007 → AC-OVR-008 | formal-criteria.md AC-OVR-008, traceability index REQ-OVR-007 |

### Quality review findings

| ID | Status | Fix description | File:line(s) |
|----|--------|-----------------|--------------|
| f-a1b2c3 (quality, REQ-OVR-007) | FIXED | Same fix as f-f2a3b4 / f-trc-007 — AC-OVR-008 added | formal-criteria.md AC-OVR-008 |
| f-d4e5f6 | FIXED | REQ-STEPS-001 amended — explicit list of 26 non-pipeline skills NOT decomposed; out-of-scope clause prevents Phase 7 scope creep | requirements.md REQ-STEPS-001 |
| f-g7h8i9 | FIXED | Same fix as f-b3c4d5 — REQ-MODE-007 defines {total} as static physical file count, not runtime FS scan | requirements.md REQ-MODE-007 |
| f-j1k2l3 | FIXED | AC-DOC-008 extended with step-count literal checks per pipeline (regex `fix-bugs[\s:(]+7\s*steps`, etc.) | formal-criteria.md AC-DOC-008 |
| f-m4n5o6 | FIXED | REQ-SETUP-006 extended — path restriction relative to resolved project root; symlinks NOT followed for writes; symlink-escape detection error | requirements.md REQ-SETUP-006 |
| f-p7q8r9 | FIXED | REQ-MIG-003 triple-quote escape clause added — escape `"""` as `""\"` OR fall back to `'''` literal multi-line OR single-line basic string with `\n` and `\"` | requirements.md REQ-MIG-003 |

---

## Counts

- **Total findings addressed:** 29 / 29
- **By severity:** 3 BLOCKERs FIXED, 9 MAJORs FIXED, 6 MINORs FIXED (devil) + 6 MINOR/INFO FIXED (quality), 2 NITs FIXED (devil) + 1 MINOR + 2 NITs FIXED (compliance)
- **DEFERRED:** 0
- **FIXED_WITH_DEVIATION:** 0 (all fixes follow recommendations verbatim where given)

## New REQs / ACs introduced

- **REQ-STEPS-003a** (near-miss override WARN)
- **REQ-MODE-008a** (SIGTERM atomicity)
- **REQ-MODE-009a** (formal vague-description heuristic)
- **REQ-AGT-008** (/pipeline-status reader dedup)
- **REQ-MIG-003a** (test-engineer non-rename + e2e merge)
- **REQ-DOC-014** (CLAUDE.md content update — separate from REQ-INV-004)
- **AC-OVR-008** (dedicated provenance-log AC for REQ-OVR-007)

All new identifiers extend the existing namespaces with `a`-suffix or sequential numbering; no existing REQ/AC identifier was renamed or removed (traceability preserved per revision constraints).

## Counts contract impact

- AC count: 87 → 88 (+AC-OVR-008)
- REQ count: 69 → 76 (+REQ-STEPS-003a, REQ-MODE-008a, REQ-MODE-009a, REQ-AGT-008, REQ-MIG-003a, REQ-DOC-014; functional REQ count 58→64; non-functional unchanged)
- Phantom AC-CT-006/007 references replaced with concrete AC-DOC-* references in Section 5 counts table

## EARS formality preserved

All new REQs use uppercase EARS keywords (`THE`, `SHALL`, `WHEN`, `THEN`, `IF`, `WHILE`). Czech prose surrounds REQs/ACs as before; Czech/English split unchanged.
