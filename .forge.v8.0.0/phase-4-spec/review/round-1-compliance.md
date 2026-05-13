# Phase 4 Spec — Compliance Review (Round 1)

**Reviewer role:** Spec Compliance Reviewer — fresh, independent verification
**Date:** 2026-04-27
**Artifacts reviewed:**
- `.forge/phase-4-spec/final/requirements.md`
- `.forge/phase-4-spec/final/design.md`
- `.forge/phase-4-spec/final/formal-criteria.md`

**Criteria evaluated against:**
- `.forge/phase-0-meta/prompts/spec.md` — 10 SUCCESS_CRITERIA + 7 ANTI_PATTERNS
- `.forge/phase-3-brainstorm/final.md` — Phase 3 scope checklist + 12 OQ list
- `CLAUDE.md` — Cross-File Invariants section

---

## Evidence Log (compliance checks executed)

### Check 1: REQ identifiers count + per-section minimums

Counts (grep `^\*\*REQ-{group}-`):

| Section | Group | REQ count | Min (spec: ≥3) | Status |
|---------|-------|-----------|----------------|--------|
| 3.1 TOML Overlay | REQ-OVR | 7 | 3 | PASS |
| 3.2 `/setup-agents` Skill | REQ-SETUP | 6 | 3 | PASS |
| 3.3 Steps Decomposition | REQ-STEPS | 6 | 3 | PASS |
| 3.4 Mode Flag Framework | REQ-MODE | 9 | 3 | PASS |
| 3.5 Agent Consolidation | REQ-AGT | 7 | 3 | PASS |
| 3.6 Migration Tooling | REQ-MIG | 6 | 3 | PASS |
| 3.7 Documentation Deliverables | REQ-DOC | 13 | 3 | PASS |
| 3.8 Cross-File Invariants | REQ-INV | 4 | 3 | PASS |
| NF | REQ-NF | 11 | — | — |
| **TOTAL functional** | | **58** | — | — |
| **TOTAL all (incl. NF)** | | **69** | — | — |

All 8 scope sections have ≥3 REQs. **PASS.**

### Check 2: AC identifiers count + per-section minimums

Counts (grep `^\*\*AC-{group}-`):

| Group | AC count | Min (spec: ≥5) | Status |
|-------|----------|----------------|--------|
| AC-OVR | 7 | 5 | PASS |
| AC-SETUP | 8 | 5 | PASS |
| AC-STEPS | 7 | 5 | PASS |
| AC-MODE (foundational) | 9 | 5 | PASS |
| AC-AGT | 8 | 5 | PASS |
| AC-MIG | 6 | 5 | PASS |
| AC-DOC | 13 | 5 | PASS |
| AC-INV (+PERM) | 5 | 5 | PASS (exactly at minimum) |
| AC-NF | 10 | — | — |
| AC-CT | 5 | — | — |
| AC-MODE-MATRIX | 9 (in table form) | — | — |
| **TOTAL** | **87** | — | — |

All section minimums ≥5 ACs met. Note: AC-CT-006 and AC-CT-007 are **referenced** in the Section 5 counts contract table (`requirements.md`) but have **no definition entries** in `formal-criteria.md`. These are covered functionally by AC-DOC-001..004 (for the 4 new guides) and AC-DOC-011 (for the examples directory) respectively — the coverage is real but the named ACs are phantom references. See finding `f-ct-phan`.

### Check 3: 12 OQ resolution coverage

All 12 OQs verified present in `requirements.md` Section 7 with explicit status:

| OQ | Status | REQ ref |
|----|--------|---------|
| OQ-A.1 | RESOLVED | REQ-OVR-001..007 + REQ-DOC-002 |
| OQ-A.2 | RESOLVED | REQ-SETUP-002 |
| OQ-A.3 | RESOLVED | REQ-STEPS-004 |
| OQ-A.4 | RESOLVED | REQ-STEPS-005 + REQ-MIG-006 |
| OQ-A.5 | RESOLVED | REQ-MIG-001..005 + REQ-NF-009 |
| OQ-A.6 | RESOLVED | REQ-OVR-005, REQ-OVR-006, REQ-AGT-006, REQ-MIG-006, REQ-NF-001 |
| OQ-A.7 | RESOLVED | REQ-MODE-007 + REQ-MODE-008 |
| OQ-B.1 | RESOLVED | REQ-MODE-009 |
| OQ-B.2 | DEFERRED | post-v8.0.0, re-opening criterion stated |
| OQ-B.3 | RESOLVED | REQ-MODE-001..009 |
| OQ-INT.1 | RESOLVED (recommendation) | design.md Section 7 + REQ-MIG-002 |
| OQ-INT.2 | RESOLVED (matrix template) | formal-criteria.md Section 3 |

**All 12 OQs accounted for. PASS.**

### Check 4: Weak EARS language scan

grep `should\b|might\b|could\b` in `requirements.md` and `formal-criteria.md`: **zero matches.**

grep `MAY\b` in `requirements.md`: 2 hits, both in non-normative REQ positions:
- REQ-NF-006: "Phase 6 implementation plan **MAY** choose Python `tomllib`..." — MAY here is RFC 2119 permissive (not a REQ verb), used in an advisory sub-clause about what the plan is permitted to do. This is in the WHAT-not-HOW context and does not weaken the REQ itself.
- REQ-NF-008: "New optional fields ... **MAY** be added" — standard backwards-compat permissive. Correct usage.

**No weak EARS language in REQ statements. PASS.**

### Check 5: 4 Cross-File Invariant REQs

| Invariant | REQ-ID | AC-ID |
|-----------|--------|-------|
| License SPDX consistency | REQ-INV-001 | AC-INV-LICENSE-001 |
| Maintainer email consistency | REQ-INV-002 | AC-INV-EMAIL-001 |
| Issue/PR template parity | REQ-INV-003 | AC-INV-TEMPLATE-001 |
| Doc count enumeration parity | REQ-INV-004 | AC-INV-DOC-ENUM-001 |

All 4 invariants formalized. **PASS.**

### Check 6: Plugin permission constraint AC

REQ-NF-003 present: "THE 18 agent files ... SHALL NOT contain any of the keys `hooks`, `mcpServers`, `permissionMode` in their YAML frontmatter."

AC-INV-PERM-001: grep command specified — `grep -E '^(hooks|mcpServers|permissionMode):' agents/*.md` — grep-able, zero-matches-required.

AC-DOC-007: "docs/reference/automation-config.md SHALL contain ... `hooks are skill-orchestrated, not agent-frontmatter`" — grep-able documentation anchor.

**Plugin permission constraint formalized with grep-able AC. PASS.**

### Check 7: 9 mode flag matrix ACs

All 9 cells verified present in `formal-criteria.md` Section 6 as table rows:

| Cell | AC-ID | Pipeline | Mode | Status |
|------|-------|----------|------|--------|
| 1 | AC-MODE-MATRIX-001 | fix-bugs | --yolo | PRESENT |
| 2 | AC-MODE-MATRIX-002 | fix-bugs | default | PRESENT |
| 3 | AC-MODE-MATRIX-003 | fix-bugs | --step-mode | PRESENT |
| 4 | AC-MODE-MATRIX-004 | implement-feature | --yolo | PRESENT |
| 5 | AC-MODE-MATRIX-005 | implement-feature | default | PRESENT |
| 6 | AC-MODE-MATRIX-006 | implement-feature | --step-mode | PRESENT |
| 7 | AC-MODE-MATRIX-007 | scaffold | --yolo | PRESENT |
| 8 | AC-MODE-MATRIX-008 | scaffold | default | PRESENT |
| 9 | AC-MODE-MATRIX-009 | scaffold | --step-mode | PRESENT |

**All 9 combinations covered. PASS.** (Note: AC-MODE-MATRIX entries are in table row format `| **AC-MODE-MATRIX-NNN** | ...`, not `**AC-MODE-MATRIX-NNN:**` format — this is why `grep '^\*\*AC-MODE-MATRIX-'` returned zero. The coverage is real.)

### Check 8: Counts contract in Section 5

Section 5 table verified:

| Metric | v7 | v8 | REQ ref | AC ref |
|--------|----|----|---------|--------|
| Agents | 21 | 18 | REQ-AGT-001 | AC-CT-001 |
| Skills | 28 | 29 | REQ-SETUP-001 | AC-CT-002 |
| Optional config sections | 18 | 18 | REQ-DOC-007 | AC-CT-003 |
| Core contracts | 16 | 16 | (no change) | AC-CT-004 |
| Config templates | 8 | 8 | REQ-DOC-010 | AC-CT-005 |
| New doc guides | 0 | 4 | REQ-DOC-001..004 | AC-CT-006* |
| Customization examples dir | absent | 1 dir | REQ-DOC-011 | AC-CT-007* |

*AC-CT-006 and AC-CT-007 are referenced but not formally defined (see finding `f-ct-phan`).

The numerically significant counts (21→18, 28→29) have defined ACs. **PASS for substantive counts.**

### Check 9: Implementation creep scan

grep for `tomllib|taplo|tomlq` in `requirements.md` and `formal-criteria.md`:
- `requirements.md` line 281 (REQ-NF-006): parser names appear inside "Phase 6 implementation plan MAY choose Python `tomllib`, external `taplo`, bash-only `tomlq`..." — this is in a TOOLING NEUTRALITY REQ, explicitly listing tools as examples of permitted choices, not as mandates. The REQ begins "THE specification SHALL NOT mandate a specific TOML parser implementation." These names are anti-example enumeration inside a negative mandate, not a specification of the implementation. **Not a violation of AP3.**
- AC-NF-006 in `formal-criteria.md`: "no `tomllib`, `taplo`, or other parser name appears as a hard requirement" — this is the verifiable AC for REQ-NF-006. Correct.

grep for bash snippets in `requirements.md`: REQ-MODE-007 contains the exact prompt wording block — this is a content specification (WHAT the user sees), not an implementation directive (HOW to display it). Appropriate for a spec.

**No AP3 implementation creep. PASS.**

### Check 10: Doc enumeration ACs

AC-INV-DOC-ENUM-001 verified: specifies per-file enumeration extraction + set-equality assertions across 5 files. The AC explicitly lists the 18 agent names via cross-reference to AC-AGT-001, the 29 skill names via cross-reference to AC-DOC-006, and requires count-string sanity as a secondary check only. Primary verification is set-equality, not count strings.

AC-DOC-005 specifies all 18 agent names in exact order — enumeration-complete, not just count.
AC-DOC-006 specifies all 29 skill names with `/ceos-agents:` prefix — enumeration-complete.

**Full enumeration ACs present; AP4 doc audit shortcuts avoided. PASS.**

### Check 11: Bidirectional traceability scan

Forward (REQ → AC): Section 9 of `formal-criteria.md` lists all 69 REQs with their primary ACs. Verified sample:
- REQ-OVR-001 → AC-OVR-001..003 ✓
- REQ-MODE-006 → AC-MODE-001 ✓
- REQ-AGT-005 → AC-AGT-001 ✓
- REQ-INV-003 → AC-INV-TEMPLATE-001 ✓

Two coverage gaps found:
1. **REQ-OVR-003** → traceability table maps to AC-DOC-002, but AC-DOC-002 body says `*Verifies REQ-DOC-002.*` (not REQ-OVR-003). Coverage is logically sound (the guide that enumerates overrideable keys does implicitly verify REQ-OVR-003), but the AC body tag is missing. See finding `f-trc-003`.
2. **REQ-OVR-007** → traceability table maps to AC-STEPS-003 ("logging style example") and AC-OVR-001 ("provenance log inferred"). Neither AC body explicitly cites REQ-OVR-007. See finding `f-trc-007`.
3. **REQ-MODE-005** → traceability table maps to AC-MODE-002 with note "AC supplied by v6.9.0 baseline". The AC body says `*Verifies REQ-MODE-003.*`, not REQ-MODE-005. The explanatory note in the traceability table accepts this as "baseline-supplied" — the v6.9.0 NEEDS_CLARIFICATION contract is pre-existing; this is an acknowledged limitation with explanation.

Reverse (AC → REQ): Every AC entry has at least one `*Verifies REQ-...*` body annotation. **No orphaned ACs found.**

**Bidirectional traceability is substantially complete. The 2 REQ-OVR missing body tags are MINOR gaps (real coverage exists via traceability table, just not reflected in AC body annotations).**

### Check 12: Lint/format compliance

- Heading hierarchy: sequential (H1 → H2 → H3, no skips)
- Code blocks: all closed (even count per file: requirements.md=2, design.md=42, formal-criteria.md=0 fenced-code-blocks — 0 is correct since all ACs use inline code not fenced blocks)
- REQ/AC identifier format: consistent `**REQ-{group}-{NNN}:**` across all 69 REQs and `**AC-{group}-{NNN}:**` for standalone ACs; matrix ACs use table format (different but consistent within Section 6)
- Tables: aligned

**Lint clean. PASS.**

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
    "completeness": 4,
    "security": 5,
    "maintainability": 4,
    "robustness": 4,
    "weighted_aggregate": 4.55,
    "pass": true
  },
  "overall_verdict": "PASS",
  "confidence": 0.91,
  "findings": [
    {
      "id": "f-ct-phan",
      "severity": "MINOR",
      "criterion": "maintainability",
      "location": "requirements.md Section 5 (counts table rows 6-7) / formal-criteria.md Section 5",
      "description": "AC-CT-006 and AC-CT-007 are referenced in the requirements.md Section 5 counts contract table as the primary ACs for 'New documentation guides (4)' and 'Customization examples directory' respectively, but neither is defined as a formal entry in formal-criteria.md. The underlying coverage is real — REQ-DOC-001..004 are verified by AC-DOC-001..004, and REQ-DOC-011 is verified by AC-DOC-011 — but the named AC-CT-006/AC-CT-007 identifiers are phantom references. This causes confusion if Phase 8 automation tries to look up AC-CT-006 and finds nothing.",
      "recommendation": "Either (a) define AC-CT-006 and AC-CT-007 as formal entries in formal-criteria.md Section 5 as cross-references (e.g., 'AC-CT-006: SAME AS AC-DOC-001..004 combined — see Section 2.7'), OR (b) remove the AC-CT-006/007 columns from the Section 5 table and replace with the actual AC-DOC-* identifiers. Option (b) is cleaner."
    },
    {
      "id": "f-trc-003",
      "severity": "NIT",
      "criterion": "correctness",
      "location": "formal-criteria.md: AC-DOC-002 body / traceability index line REQ-OVR-003",
      "description": "REQ-OVR-003 (overrideable keys per agent enumerated in toml-overlay-syntax.md) is mapped in the traceability index to AC-DOC-002, but AC-DOC-002's body annotation says '*Verifies REQ-DOC-002.*' only. The coverage is logically correct (a guide containing the key reference table does verify REQ-OVR-003), but the AC body does not cite REQ-OVR-003 explicitly. Phase 8 automation scanning for 'Verifies REQ-OVR-003' will find zero hits in AC bodies.",
      "recommendation": "Add 'REQ-OVR-003' to AC-DOC-002's Verifies annotation: '*Verifies REQ-DOC-002, REQ-OVR-003.*' — one-line fix."
    },
    {
      "id": "f-trc-007",
      "severity": "NIT",
      "criterion": "correctness",
      "location": "formal-criteria.md: traceability index line REQ-OVR-007",
      "description": "REQ-OVR-007 (provenance log to pipeline.log) is mapped in the traceability index to AC-STEPS-003 (logging style example) and AC-OVR-001 (provenance log inferred). Neither AC body contains 'Verifies REQ-OVR-007'. The quality review (round-1-quality.md) also flagged this and recommended a dedicated AC-OVR-008. From a compliance standpoint this is a NIT: the traceability table provides the forward link, and the Phase 8 commander can use it. No information is lost. But the bidirectional consistency of body annotations is incomplete for this REQ.",
      "recommendation": "Add 'REQ-OVR-007' to AC-OVR-001 or AC-STEPS-003 body annotation as secondary verifies reference — or accept the round-1-quality recommendation to add AC-OVR-008 dedicated to this REQ."
    }
  ]
}
```

---

## Elaboration (Czech, ≤ 300 slov)

### Celkové hodnocení: PASS s vysokou jistotou (0.91)

Spec je mechanicky kompletní a přesná. Všechny Tier 1 binary checky prošly bez výjimky.

**Tier 1 shrnutí:**
- 3 soubory existují se správnými sekcemi ✓
- 69 REQs s REQ-NNN identifikátory ✓
- 87 ACs s AC-NNN identifikátory ✓ (matrix ACs v table formátu — jiný styl, ale konzistentní)
- Všech 12 OQs v Section 7 s RESOLVED nebo DEFERRED statusem ✓
- Žádný weak EARS jazyk (should/might/could) v REQ statements ✓
- Žádný AP3 implementation creep v requirements.md nebo formal-criteria.md ✓
- 4 Cross-File Invariants jako dedikované REQs ✓
- Plugin permission constraint REQ-NF-003 + grep-able AC-INV-PERM-001 ✓
- 9 mode flag matrix kombinací v Section 6 ✓
- Counts contract v Section 5 s REQ + AC referencemi ✓
- Doc enumeration ACs (full lists, ne jen count strings) ✓
- Markdown lint čistý ✓

**Tier 3 skóre:**
- **Correctness 5/5** — žádný REQ nevychyluje z A.1 D1–D5 nebo B.1 B6 rozhodnutí; EARS keywords použity korektně ve všech 69 REQs
- **Completeness 4/5** — odečet za phantom AC-CT-006/007 a dva chybějící body annotation Verifies tagy pro REQ-OVR-003 a REQ-OVR-007 (f-trc-003, f-trc-007)
- **Security 5/5** — plugin permission constraint, path-traversal defense, TOML parse error halt, backup-before-modify, všechny formalizovány
- **Maintainability 4/5** — REQ/AC číslování konzistentní; drobný odečet za phantom AC-CT-006/007 (zmätok pro Phase 8 automation)
- **Robustness 4/5** — backwards compat matrix, failure modes, schema additive policy — vše pokryto; drobný odečet za stejné mezery identifikované v quality review (OVR-007 provenance log thin AC coverage)

**Výsledek pro pipeline:** Spec je ready pro Phase 5 TDD. Tři MINOR/NIT nálezy nevyžadují revision loop — jsou to zlepšení do Phase 5 task listu nebo jednořádkové opravy v sidecar commitech.