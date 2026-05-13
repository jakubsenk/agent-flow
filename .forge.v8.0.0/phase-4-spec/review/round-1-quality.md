# Phase 4 Spec — Quality Review (Round 1)

**Reviewer role:** Senior Architect — Phase 5–8 downstream usability
**Date:** 2026-04-27
**Artifacts reviewed:**
- `.forge/phase-4-spec/final/requirements.md`
- `.forge/phase-4-spec/final/design.md`
- `.forge/phase-4-spec/final/formal-criteria.md`

---

## Verdict

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
    "security": 4,
    "maintainability": 5,
    "robustness": 4,
    "weighted_aggregate": 4.15,
    "pass": true
  },
  "overall_verdict": "PASS",
  "confidence": 0.87,
  "findings": [
    {
      "id": "f-a1b2c3",
      "severity": "MINOR",
      "criterion": "correctness",
      "location": "requirements.md REQ-OVR-007 / formal-criteria.md traceability index",
      "description": "REQ-OVR-007 (provenance log to pipeline.log) has a weak AC binding. The traceability index maps it to AC-STEPS-003 (step override logging) as example and AC-OVR-001 (provenance log inferred). Neither AC directly verifies that the overlay_source={toml|md|none} and overlay_path={path} log structure is emitted with those exact fields. A Phase 5 TDD agent may generate a test that is too loose or too strict depending on interpretation.",
      "recommendation": "Add AC-OVR-008 dedicated to REQ-OVR-007: 'WHEN reviewer agent is dispatched with customization/reviewer.toml present, THEN pipeline.log SHALL contain a line matching regex agent=reviewer overlay_source=toml overlay_path=customization/reviewer.toml. VERIFIED BY bash scenario tests/scenarios/v8-overlay-provenance-log.sh.' Update traceability index."
    },
    {
      "id": "f-d4e5f6",
      "severity": "MINOR",
      "criterion": "completeness",
      "location": "requirements.md REQ-STEPS-001 / design.md Section 4.1",
      "description": "REQ-STEPS-001 specifies 3 pipeline skills for decomposition (fix-bugs, implement-feature, scaffold) but the spec does not address whether the other 26 skills (e.g., fix-ticket, resume-ticket) remain as monolithic SKILL.md files or adopt steps/ decomposition too. fix-ticket is the most frequently invoked skill and shares significant logic with fix-bugs. If Phase 7 executor misunderstands scope and decomposes fix-ticket as well, it would be out-of-spec. If they correctly leave it monolithic, the original ~600-line pain point remains for 26 skills.",
      "recommendation": "Add a single sentence to REQ-STEPS-001: 'The 26 non-pipeline skills (all skills other than fix-bugs, implement-feature, scaffold) SHALL NOT be decomposed into steps/ in v8.0.0; their monolithic SKILL.md structure is preserved.' This is implicit from design.md Section 4.1 but not stated as a REQ, leaving a Phase 7 out-of-scope creep risk."
    },
    {
      "id": "f-g7h8i9",
      "severity": "MINOR",
      "criterion": "robustness",
      "location": "requirements.md REQ-MODE-007 / design.md Section 5.2",
      "description": "The --step-mode prompt in REQ-MODE-007 references '{total}' as a field in 'Step {NN}/{total} completed'. However, the total step count is not a fixed number — scaffold has 8 steps, fix-bugs has 7, implement-feature has 7. REQ-MODE-007 does not specify HOW the skill knows the total (static value from entry SKILL.md? dynamic from counting steps/ directory files?). Two implementations are possible: (a) hard-coded constant in entry SKILL.md, (b) dynamic count via file-system scan at runtime. Both satisfy the REQ but produce different behavior when a step override adds or removes steps (override is replace-only, so count stays the same — but this subtlety is nowhere stated). Phase 7 executor may choose (b), which adds a POSIX file-system call that could behave differently on Windows Git Bash.",
      "recommendation": "Add a clarification clause to REQ-MODE-007: 'The {total} value SHALL be the count of step files in the plugin-default skills/{skill}/steps/ directory at the time of SKILL.md authoring (static, not runtime file-system scan). Override files do not change the step count denominator.' This eliminates the portability concern and the implementation ambiguity."
    },
    {
      "id": "f-j1k2l3",
      "severity": "MINOR",
      "criterion": "completeness",
      "location": "requirements.md Section 3.7 / REQ-DOC-008",
      "description": "REQ-DOC-008 requires docs/architecture.md to be updated with 18 agents, 29 skills, TOML overlay layer, steps decomposition node, mode flag framework arrows, and all 3 pipelines with step counts. AC-DOC-008 checks for literal strings '18 agents' AND '29 skills' AND a diagram with named-phase identifiers. However, REQ-DOC-008 says 'diagram SHALL show all 3 pipelines with their step counts' — but AC-DOC-008 does not verify the pipeline-with-step-counts requirement. A diagram that shows 18 agents and 29 skills but omits the step counts would pass the AC but fail the REQ.",
      "recommendation": "Extend AC-DOC-008 to also verify step counts are present in the diagram, e.g.: 'AND the architecture diagram SHALL contain the literals 01-triage.md OR steps/fix-bugs OR step count annotations for at least the fix-bugs pipeline.' Alternatively, add 'fix-bugs: 7 steps' as a literal string assertion."
    },
    {
      "id": "f-m4n5o6",
      "severity": "INFO",
      "criterion": "security",
      "location": "requirements.md REQ-SETUP-006",
      "description": "REQ-SETUP-006 restricts /setup-agents to writing only within customization/ directory. This is the primary path-traversal defense. However, the REQ does not specify behavior when the project root is not the CWD (e.g., user invokes /setup-agents from a subdirectory). The current SKILL.md entry always operates from project root per REQ-SETUP-001 detection logic — but the path-traversal guard relies on 'no writes outside customization/' without specifying the reference point for that constraint.",
      "recommendation": "Add to REQ-SETUP-006: 'The path restriction SHALL be enforced relative to the resolved project root (the directory containing CLAUDE.md or git root), regardless of the working directory at invocation time. Symlinks in customization/ MUST NOT be followed for write operations.' This is a known POSIX symlink escape vector and worth a single sentence REQ rather than leaving it to Phase 6 discretion."
    },
    {
      "id": "f-p7q8r9",
      "severity": "INFO",
      "criterion": "robustness",
      "location": "requirements.md REQ-MIG-003",
      "description": "REQ-MIG-003 converts v7 .md overlay content into [[process_additions]] with step='after_default'. This is a reasonable default. However, the spec does not address the case where the v7 .md file contains multi-line content with triple-quote-sensitive characters (e.g., three consecutive double-quotes in the raw text). The design.md Section 6.1 uses triple-quoted TOML strings (instruction = \"\"\"...\"\"\"). A v7 overlay that happens to contain \"\"\" in its text will produce invalid TOML. This is an edge case but a real one for projects that used code snippets in their overlays.",
      "recommendation": "Add to REQ-MIG-003: 'WHEN the verbatim .md content contains the substring \"\"\" (three double-quotes), THE migration skill SHALL escape it as \\\"\\\"\\\" within the triple-quoted TOML string, OR SHALL use a single-quoted TOML string literal instead.' A Phase 5 scenario should cover this edge case."
    }
  ]
}
```

---

## Elaboration (Czech, ≤ 300 slov)

Spec je v celku výjimečně kvalitní — jeden z nejlépe strukturovaných Phase 4 výstupů co jsem u tohoto projektu viděl. Plný PASS na všech Tier 3 dimenzích nad minimem.

**Correctness (4/5):** Náhodný vzorek 5 REQů: REQ-OVR-002 (3-tier merge), REQ-MODE-007 (step-mode prompt), REQ-AGT-001 (18 agentů), REQ-MIG-002 (backup semantics), REQ-DOC-001 (migration guide sections) — všechny věrně odrážejí source spec rozhodnutí D1–D5 + B6. Odečet: REQ-OVR-007 provenance log nemá silný dedikovaný AC (viz finding f-a1b2c3), a REQ-MODE-007 {total} ambiguita (f-g7h8i9) mohla být zachycena v design fázi.

**Completeness (4/5):** Všech 6 design rozhodnutí (D1–D5 + B6) má REQ pokrytí. Všech 12 OQs je vyřešeno — žádné unmentioned. 4 Cross-File Invariants formalizovány jako dedikované REQs. Doc deliverables jsou per-file (ne agregované). Odečet: scope exclusion pro 26 non-pipeline skills není explicitně stazena do REQ (f-d4e5f6), a REQ-DOC-008 AC gap pro step counts (f-j1k2l3).

**Security (4/5):** Plugin permission constraint REQ-NF-003 je přítomný s grep-able AC (AC-INV-PERM-001). Path-traversal defense v REQ-SETUP-006 je tam, ale chybí symlink escape specifikace (f-m4n5o6). TOML parser security (untrusted input) je pokryta REQ-OVR-004 (syntax error halt + unknown key halt) + REQ-NF-006 tooling neutrality. Migration safety pokryta REQ-NF-009 + AC-MIG-006. Odečet za symlink gap.

**Maintainability (5/5):** REQ/AC ID konvence je konzistentní a přehledná. Glossary (requirements.md Section 2) je vynikající — 16 termínů s přesnými definicemi. Bidirectional traceability index v formal-criteria.md Section 9 je kompletní a snadno prohledatelný. Design.md architecture diagram je čitelný. Cross-references fungují.

**Robustness (4/5):** Backwards compatibility matrix (REQ-MIG-006) je kompletní 5-row deprecation table. Failure modes pro TOML parse error, backup failure, step override mismatch jsou dokumentovány. Odečet: {total} static-vs-dynamic ambiguita (f-g7h8i9) a triple-quote edge case v migration (f-p7q8r9).

**Klíčový závěr pro pipeline:** Phase 5 TDD může psát 50+ scénářů přímo z formal-criteria.md bez nutnosti zpětně číst source A/B specy. Phase 6 planner vidí dependency order (TOML conversion → agent renames). Phase 7 executor ví konkrétně co psát. Phase 8 verifikace má grep-commandy. Všechny 4 downstream fáze jsou unblocked.

6 findings jsou drobné — spec nevyžaduje revision loop. Doporučení jsou enhancements do Phase 5 TDD task listu nebo minor spec patches.
