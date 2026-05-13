# Phase 4 Spec-Compliance Review — forge-2026-05-13-001

**Reviewer role:** Spec-compliance (Gate 1 HYBRID fidelity + roadmap L1489-L1513 scope)
**Artifact:** `.forge/phase-4-spec/final/` (requirements.md + design.md + formal-criteria.md)
**Reference:** `.forge/phase-3-brainstorming/final.md` (Gate 1 HYBRID), `.forge/phase-2-research-answers/final.md`, `docs/plans/roadmap.md` L1489-L1513
**Date:** 2026-05-13

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
    "correctness": 4,
    "completeness": 4,
    "security": 5,
    "maintainability": 4,
    "robustness": 4,
    "weighted_aggregate": 4.15,
    "pass": true
  },
  "overall_verdict": "PASS",
  "confidence": 0.87,
  "findings": [
    {
      "id": "f-a1c2e3",
      "severity": "MINOR",
      "criterion": "correctness",
      "location": "requirements.md REQ-A-3 / phase-3-brainstorming/final.md L155",
      "description": "Canonical error message deviated from Phase 3 synthesis and roadmap L1497 wording. Phase 3/roadmap use em-dash ('--' encoded as UTF-8 em dash in roadmap Czech text), and NO 'ABORT:' prefix. REQ-A-3 adopts double-hyphen '--' + 'ABORT:' prefix. Design.md is internally consistent with REQ-A-3. The review criteria permits 'substantively identical phrasing per roadmap L1497', which this satisfies. However, a future Phase 8 grep for the exact roadmap L1497 string will fail. Recommend: Phase 7 implementer confirm the exact string in FC-A-3 grep pattern matches what is emitted in the guard-block.md Bash probe.",
      "recommendation": "Add a note to FC-A-3 or REQ-A-3 explicitly acknowledging the em-dash vs double-hyphen deviation from roadmap L1497, with rationale (ASCII-safety). No blocking change needed — the spec criteria clause 7 permits 'substantively identical phrasing'."
    },
    {
      "id": "f-b2d4f5",
      "severity": "MINOR",
      "criterion": "completeness",
      "location": "requirements.md REQ-C / phase-3-brainstorming/final.md falsifiable metric item 5",
      "description": "Phase 3 falsifiable success metric item 5 stated 'v10.2.0 adds 3 new scenarios → 356/348/0/5 or better'. The spec implements only 2 new scenario files (v10-skill-from-external-cwd.sh + v10-core-path-depth-consistency.sh), merging Phase 3's C2 fail-loud scenario into C1 as ASSERT-2. REQ-E-3 correctly reflects the 2-file reality (pass count ≥353). REQ-D-1 correctly says 13→15. The design decision (merge C2 into C1) is sound and traceable. However, no explicit rationale for the Phase 3 metric deviation is stated in the spec.",
      "recommendation": "Add one sentence to REQ-C-1 or Open Questions noting that Phase 3's C1+C2+C3 three-scenario plan was consolidated to C1+C2 (two files) by merging the fail-loud ASSERT into C1 as ASSERT-2. This closes the traceability gap without changing any FC."
    },
    {
      "id": "f-c3e5a7",
      "severity": "LOW",
      "criterion": "robustness",
      "location": "formal-criteria.md FC-B-6 note",
      "description": "FC-B-6 leaves the expected occurrence count as a TO-BE-CONFIRMED value: 'Phase 7 confirms the exact post-rewrite count and updates this expected value to match if PROBE prose is included.' The test literally says `test \"$total\" -eq 185` but the note acknowledges this may need to be 188. This leaves a soft open in a Tier-1-equivalent FC. Not a blocker (Phase 7 is explicitly tasked to confirm), but creates a window where the FC could be incorrect as written.",
      "recommendation": "Phase 7 implementer MUST update FC-B-6 expected count before tagging. Track as a Phase 7 pre-commit checklist item."
    }
  ]
}
```

---

## Elaboration

### Tier 1 — Hard Gates

**schema_valid:** All three files present, follow EARS-form requirements (WHEN/SHALL), FC IDs present throughout, status lines present (`STATUS: REQUIREMENTS-COMPLETE`, `STATUS: DESIGN-COMPLETE`, `STATUS: FORMAL-CRITERIA-COMPLETE`). Markdown is well-formed; no broken headers or unclosed code fences observed. PASS.

**requirements_traced:** Every REQ has at least one FC mapping:
- REQ-A-1 → FC-A-1 | REQ-A-2 → FC-A-1, FC-A-2 | REQ-A-3 → FC-A-1, FC-A-3 | REQ-A-4 → FC-A-1, FC-A-2 | REQ-A-5 → FC-A-4 | REQ-A-6 → FC-A-5
- REQ-B-1 → FC-B-1..5 | REQ-B-2 → FC-B-2..5 | REQ-B-3 → FC-B-6 | REQ-B-4 → FC-B-7 | REQ-B-5 → FC-B-8
- REQ-C-1 → FC-C-1 | REQ-C-2 → FC-C-2 | REQ-C-3 → FC-C-3 | REQ-C-4 → FC-C-1, FC-C-2
- REQ-D-1 → FC-D-1 | REQ-D-2 → FC-D-2 | REQ-D-3 → FC-D-3, FC-D-4 | REQ-D-4 → FC-D-4
- REQ-E-1 → FC-E-1 | REQ-E-2 → FC-E-2 | REQ-E-3 → FC-E-3 | REQ-E-4 → FC-E-4 | REQ-E-5 → FC-E-5
- Total: 18 REQs, 26 FCs. 100% traced. PASS.

**no_regressions:** REQ-E covers all regression vectors: Step Completion Invariants (E-1, E-2), harness 0-fail baseline (E-3), stage-invariant.sh byte-identical (E-4), 13 existing v10-*.sh continuity (E-5). FC-E implements machine-runnable commands for each. PASS.

**lint_clean:** Markdown structurally clean. Table formatting consistent. Code fences closed. PASS.

### Tier 3 — Quality Rubrics

**Correctness (4/5):** HYBRID lock is explicitly and correctly stated in REQ-B-1: B2 as PRIMARY, B1 REJECTED with dual rationale (Phase 2 I1 + Read-tool-token-expansion gap + CLAUDE.md L17 markdown-only invariant), B3 additive-only in 3 guard-block.md `<PREFLIGHT>` blocks. The four depth classes are precisely enumerated (REQ-B-2 table) with correct up-level counts. Design.md sed pattern correctly implements the `(^|[^./])` alternation to handle line-start edge cases AND provide idempotency. Verification log in design.md is concrete (bash 5.2 + GNU sed 4.x). One point deducted: error message form deviation from roadmap L1497 (em-dash vs `--`, `ABORT:` prefix not in roadmap) with insufficient rationale in the spec text.

**Completeness (4/5):** All 4 depth classes specified (agents/*.md / skills/*/SKILL.md / skills/*/steps/*.md / skills/*/data/*.md). REQ-A covers all 3 guard-block.md files including the new scaffold file. REQ-E covers all 5 reliability vectors. REQ-D covers doc-quartet (5 files named), CHANGELOG, version bump, roadmap update. REQ-C covers 2 new scenarios with cross-platform constraints. One point deducted: Phase 3's C1+C2+C3 three-scenario enumeration was consolidated to 2 files without explicit spec rationale; the traceability gap is present though the design decision is sound.

**Security (5/5):** No new attack surface introduced. No `core/lib/` files added (preserves CLAUDE.md L17). No `${PLUGIN_ROOT}` or env-var injection surfaces. Phase A probe is a simple `[ -r FILE ]` test — no shell expansion, no user-controlled input. FC-C-4 explicitly bans `grep -P` and `mktemp --suffix` (GNU-only) and `realpath` (portability hazard). Full marks.

**Maintainability (4/5):** FC commands are bash-runnable from repo root. Design.md provides exact script structure (B.3) with per-depth-class loop bodies. Idempotency proof (B.5) is concrete. Open Questions section flags non-blocking uncertainties for Phase 7 rather than leaving them implicit. One point deducted: FC-B-6 expected count is soft (188 vs 185 unresolved) — requires Phase 7 update before the FC is correct as written.

**Robustness (4/5):** Idempotency is specified (REQ-B-4) and FC-tested (FC-B-7). Counterfactual self-test (REQ-C-3 / FC-C-3) proves the depth-lint actually catches the failure mode. Cross-platform portability constraints (REQ-C-4 / FC-C-4) cover Win Git-Bash + macOS BSD + Linux GNU. Trap-based tmpdir cleanup specified (REQ-C-1 item 6). Phase A exit code = 2 (not 1 or 0) distinguishes guard-abort from generic failure. One point deducted: symlink-resilience risk (identified in Phase 3 B2 flaw 2 — `~/.claude/plugins/cache/ceos-agents` symlink resolution) is deferred to v10.2.1 with no FC coverage; the spec does not explicitly acknowledge this known-unknown.

### Scope Adherence Check

**In-scope (roadmap L1489-L1513):**
- Phase A guard: roadmap L1497 ✓
- Phase B path rewrite: roadmap L1499-L1503 (B2 selected per Gate 1) ✓
- Phase C scenario: roadmap L1505 ✓
- CHANGELOG, version bump, roadmap update: standard release discipline ✓

**Gate 1 HYBRID extensions (approved):**
- B3 documentary clarifier in guard-block.md only: explicitly approved in Phase 3 synthesis ✓
- Depth-lint (C3) as second new scenario: Phase 3 §Recommendation item 3 ✓
- Two scenarios not three: design consolidation, traceable ✓

**Out-of-scope items (v10.3.0+):** None present. ✓

**No v10.3.0 cleanup REQs:** Confirmed. ✓

### Criterion 7 — Phase A Canonical Error String Verbatim

**roadmap L1497 text (Czech):** `"plugin-root not resolved — core/ sibling of skills/ not found at <attempted-path>. Check plugin install integrity."`
**Phase 3 synthesis L155:** `"plugin-root not resolved — core/ sibling of skills/ not found at <attempted-path>. Check plugin install integrity."` (em dash)
**REQ-A-3 text:** `"ABORT: plugin-root not resolved -- core/ sibling of skills/ not found at <attempted-path>. Check plugin install integrity."` (double hyphen, ABORT: prefix)
**design.md A.1 Bash probe:** same as REQ-A-3 form ✓ (internally consistent)

**Verdict on criterion 7:** Substantively identical — both identify the plugin-root resolution failure and check install integrity. The `ABORT:` prefix and `--` vs em-dash are ASCII-safety improvements, not semantic changes. The review criteria explicitly permits "substantively identical phrasing per roadmap L1497". SATISFIED — but the discrepancy is flagged as finding f-a1c2e3 (MINOR) for Phase 7 awareness.

---

## Summary

| Group | REQs | FCs | Status |
|-------|------|-----|--------|
| REQ-A (Phase A guard) | 6 | 5 | PASS |
| REQ-B (Phase B rewrite) | 5 | 8 | PASS (FC-B-6 soft count flagged) |
| REQ-C (Phase C scenarios) | 4 | 4 | PASS (2 vs 3 scenario count flagged) |
| REQ-D (Cross-cutting) | 4 | 4 | PASS |
| REQ-E (Reliability invariants) | 5 | 5 | PASS |
| **Total** | **24** | **26** | **PASS** |

**Findings:** 3 total (0 HIGH, 0 MEDIUM, 2 MINOR, 1 LOW). No HARD-FAIL flags. No scope creep. No regression risk in spec as written.

**Overall:** The spec faithfully implements the Gate 1 HYBRID decision. Phase 7 can proceed.

---

**REVIEW_END phase=4 round=1 verdict=APPROVED**
