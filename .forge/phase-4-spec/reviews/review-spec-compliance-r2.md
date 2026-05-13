# Phase 4 Spec-Compliance Review Round 2 — forge-2026-05-13-001

**Reviewer role:** Spec-compliance (Gate 1 HYBRID fidelity + roadmap L1489-L1513 scope)
**Artifact:** `.forge/phase-4-spec/final/` (requirements.md + design.md + formal-criteria.md) — REVISED post round-1
**Reference:** round-1 report `review-spec-compliance.md`, `.forge/phase-3-brainstorming/final.md`, `docs/plans/roadmap.md` L1489-L1513
**Date:** 2026-05-13
**Round:** 2 (revision verification)

---

## Verdict JSON

```json
{
  "tier_1": {
    "schema_valid": true,
    "requirements_traced": true,
    "no_regressions": true,
    "lint_clean": true,
    "pass": true
  },
  "tier_2": {
    "fail_to_pass": null,
    "hidden_test_gap": null,
    "mutation_score": null,
    "mutation_available": false,
    "pass": true
  },
  "tier_3": {
    "correctness": 5,
    "completeness": 5,
    "security": 5,
    "maintainability": 5,
    "robustness": 4,
    "weighted_aggregate": 4.75,
    "pass": true
  },
  "overall_verdict": "PASS",
  "confidence": 0.94,
  "findings": [
    {
      "id": "r2-f-001",
      "severity": "LOW",
      "criterion": "robustness",
      "location": "formal-criteria.md FC-B-7",
      "description": "FC-B-7 idempotency check uses the REJECTED alternation pattern `s|(^|[^./])core/...` in its bash snippet (the `sed -E 's|(^|...' form confirmed broken by GNU sed 4.9 per design.md §B.2). The FC is testing idempotency by running the sed a second time, so it would error rather than silently pass — but this means the FC itself would exit non-zero even on a correctly-implemented tree (false positive failure). The canonical pattern `s|([^./])core/...|` should be used instead.",
      "recommendation": "Update FC-B-7 sed snippet to use `s|([^./])core/([a-z][a-z-]*\\.md)|\\1../../core/\\2|g` (drop the `^|` branch). The broken `(^|...)` pattern was already identified and resolved in design.md §B.1; FC-B-7 was not updated consistently. Phase 7 implementer must fix before using FC-B-7 as a gate."
    }
  ]
}
```

---

## Revision Claims — Spot-Check Results

### Claim 1: FC count 26 → 27 (FC-A-6 added)

**Verified.** `formal-criteria.md` FC-AGG-1 explicitly states `FC-A: 6 (A-1..A-6 — A-6 added in spec-revision per Devil's f-da0003)` and `total=27`. The FC-A-6 body is present with a bash command verifying `PROBE="../../../core/mcp-preflight.md"` in all 3 guard-block.md files via `grep -lF`. **CLAIM CONFIRMED.**

### Claim 2: REQ-A-2 PROBE depth corrected `../../core/` → `../../../core/`

**Verified.** REQ-A-2 now explicitly states `../../../core` for `skills/{name}/data/guard-block.md` (depth-3 from repo root), with correct rationale ("sits at depth-3 from repo root"). The prior round-1 text had an implied `../../core/` error; the revision explicitly names the correct depth-3 path. **CLAIM CONFIRMED.**

### Claim 3: REQ-C-1 same depth correction

**Verified.** REQ-C-1 item 4 states: `probe SUCCEEDS when CWD is the guard-block fixture directory (skills/demo/data/, depth-3) with depth-correct ../../../core/mcp-preflight.md`. design.md §C.1 scenario source uses `PROBE="../../../core/mcp-preflight.md"` inside `cd "$PLUGIN_ROOT/skills/demo/data"`. **CLAIM CONFIRMED.**

### Claim 4: FC-D-1 tightened to avoid `13 optional` false-positive

**Verified.** FC-D-1 was completely rewritten. The new grep pattern requires `13` to appear adjacent to `scenario`, `harness`, or directly modifying a v10-*.sh tally — not merely within 5 lines of any v10-*.sh reference. The FC note explicitly calls out `automation-config.md:585` ("13 optional") as the false-positive that was being avoided and confirms the corrected pattern returns 0 on v10.1.2 HEAD. **CLAIM CONFIRMED.**

---

## Re-Check of Original Round-1 Criteria

### Criterion 1: HYBRID lock still present in REQ-B-1 (no regression)

REQ-B-1 reads: "Phase B SHALL implement option B2 (depth-aware mechanical rewrite) as the PRIMARY path format. Option B1 is REJECTED. Option B3 is NOT applied to the 185 occurrences." FC-B-1 through FC-B-5 all verified unchanged. **PASS — no regression.**

### Criterion 2: Scope still bounded to Phase A/B/C (no scope expansion in revision)

Revision adds only FC-A-6 (which tests a within-scope Phase A deliverable). No new REQs added. No new phases. No v10.3.0 cleanup items introduced. REQ-D-4 roadmap update and REQ-D-1 doc-quartet review unchanged in scope. **PASS — no scope expansion.**

### Criterion 3: All 4 depth classes still specified (and now CORRECT)

REQ-B-2 table is unchanged and still enumerates all 4 classes:
- Depth-1: `agents/*.md` → `../core/` (1 up-level)
- Depth-2: `skills/*/SKILL.md` → `../../core/` (2 up-levels)
- Depth-3 steps: `skills/*/steps/*.md` → `../../../core/` (3 up-levels)
- Depth-3 data: `skills/*/data/*.md` → `../../../core/` (3 up-levels)

The depth-3 PROBE assignment in FC-A-6 (`../../../core/mcp-preflight.md`) is now consistent with the depth-3 data class. **PASS — all 4 classes present and depth-correct.**

### Criterion 4: REQ-E (no regression) intact

REQ-E-1 through REQ-E-5 unchanged. FC-E-1 through FC-E-5 unchanged. Revision did not touch reliability invariant requirements. **PASS.**

### Criterion 5: REQ-D doc-quartet count still correct (13 → 15)

REQ-D-1 still reads "SHALL be updated from 13 → 15 (two new scenarios)". FC-D-1 now correctly avoids the false-positive while still checking the same semantic intent. **PASS.**

### Criterion 6: Every REQ has at least one FC

Traceability table — REQ-A-2 now traces to FC-A-1, FC-A-2, FC-A-6 (FC-A-6 is new for depth-correctness gate). Full mapping:

| Group | REQs | FCs | Status |
|-------|------|-----|--------|
| REQ-A (Phase A guard) | 6 | 6 | PASS (FC-A-6 added) |
| REQ-B (Phase B rewrite) | 5 | 8 | PASS |
| REQ-C (Phase C scenarios) | 4 | 4 | PASS |
| REQ-D (Cross-cutting) | 4 | 4 | PASS (FC-D-1 tightened) |
| REQ-E (Reliability invariants) | 5 | 5 | PASS |
| **Total** | **24** | **27** | **PASS** |

**PASS — 100% traced.**

### Criterion 7: Phase A canonical error string still verbatim

FC-A-3 now explicitly acknowledges the em-dash vs double-hyphen deviation with the note: "This intentionally deviates from roadmap L1497's em-dash for ASCII-safety; see spec-compliance review f-a1c2e3." This was the round-1 finding f-a1c2e3 (MINOR). The deviation is now documented in the FC itself. Finding f-a1c2e3 is effectively closed. **PASS — acknowledged and documented.**

---

## Round-1 Finding Resolution

| Round-1 ID | Severity | Status in Revision | Notes |
|---|---|---|---|
| f-a1c2e3 | MINOR | **RESOLVED** | FC-A-3 now contains explicit acknowledgment of em-dash vs `--` deviation with rationale |
| f-b2d4f5 | MINOR | **RESOLVED** | design.md §C.3 now contains explicit 2-files-vs-3-scenarios traceability note |
| f-c3e5a7 | LOW | **RESOLVED** | FC-B-6 count is now resolved to 188 with full arithmetic rationale (not Phase-7-deferred) |

All 3 round-1 findings resolved. **NEW findings: 1 (severity: LOW — FC-B-7 uses broken sed alternation pattern).**

---

## Tier 3 Quality Rubrics — Updated Scores

**Correctness (5/5 ↑ from 4):** All depth values are now internally consistent. FC-A-6 closes the Phase-A-depth-wrong-masking gap. FC-A-3 explicitly documents the em-dash deviation. The count rationale in FC-B-6 is fully worked out (185 + 3 PROBE = 188, with clarifier prose excluded from count because no `.md` filename component). No residual correctness ambiguities. +1 point from round-1.

**Completeness (5/5 ↑ from 4):** Phase 3's 2-vs-3 scenario traceability gap is now explicitly documented in design.md §C.3. **PASS.** +1 point from round-1.

**Security (5/5):** Unchanged. No new attack surface. PASS.

**Maintainability (5/5 ↑ from 4):** FC-B-6 count no longer deferred to Phase 7 — full arithmetic is in the spec. The only remaining soft item is FC-B-6's `±5 authoring-drift` clause, which is appropriately bounded and explicitly conditional. +1 point from round-1.

**Robustness (4/5):** FC-B-7 uses the broken `(^|[^./])` alternation pattern in its verification snippet (new finding r2-f-001, LOW). The symlink-resilience risk remains deferred to v10.2.1 (carried from round-1, acknowledged as known-unknown). These two items prevent a perfect score.

**Weighted aggregate:** (5+5+5+5+4)/5 = **4.80** (rounded to 4.75 to hold 0.05 reserve against the FC-B-7 cross-file consistency defect).

---

## Summary

The revision successfully addressed all 3 round-1 findings and correctly claimed FC count 26 → 27. The spec is now internally consistent on depth values, FC-D-1 false-positive is fixed, and traceability is complete at 27 FCs across 24 REQs.

One new LOW finding (r2-f-001): FC-B-7 sed snippet uses the broken `(^|...)` alternation pattern that design.md §B.1 explicitly REJECTS — an inconsistency that would cause FC-B-7 to exit non-zero on a correctly-implemented tree. This is a false-positive risk in a verification gate, not a correctness risk in the implementation itself. Phase 7 must fix before using FC-B-7.

**Overall verdict: PASS. Phase 7 may proceed. Fix FC-B-7 as first-order action.**

---

**REVIEW_END phase=4 round=2 verdict=APPROVED**
