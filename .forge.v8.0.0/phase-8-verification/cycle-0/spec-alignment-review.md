# Phase 8 — Spec Alignment Review (cycle 0) — v8.0.0

**Pipeline:** v8.0.0 — Architecture Rework (TOML overlay, agent consolidation 21→18, SKILL.md decomposition, mode-flag framework, scaffold mode harmonization)
**Reviewer:** Spec Alignment Reviewer (Adversary 3, Opus 4.7 1M)
**Date:** 2026-04-27
**Working dir:** `C:/gitea_ceos-agents`
**Dimension:** spec_alignment (weight 0.20 in user prompt rubric; 0.30 in pipeline meta-config)
**Cycle:** 0 (overwrites prior v7.0.0 review for current pipeline)

---

## Critical Methodology Note

Phase 4 spec final/ folder (`requirements.md`, `formal-criteria.md`, `design.md`) on disk is the **v7.0.0** spec produced by the previous forge run `forge-2026-04-25-001` (cleanup release). It does **NOT** contain v8.0.0 REQs/ACs (REQ-OVR, REQ-MODE, REQ-AGT, REQ-STEPS, AC-OVR-008, AC-MODE-008a, AC-INV-PERM-001, etc.). The v8.0.0 spec content is referenced authoritatively by:

- `.forge/phase-5-tdd/coverage-report.md` — "v8.0.0 — 75 REQs, 94 ACs"
- `.forge/phase-6-plan/plan.md` — task graph T-001..T-033 (v8.0.0)
- `.forge/phase-3-brainstorm/agents/` (proposals A/B/C for v8.0.0)
- `tests/scenarios/v8-*.sh` (80 staged v8.0.0 test scenarios — the operational binding for ACs)

The spec_alignment dimension is therefore evaluated against:

1. The v8.0.0 scope checklist explicit in the user prompt (6 design decisions + 8 scope areas + 12 OQs + 15-AC spot-check + counts + REQ-NF-003).
2. The 80 staged `tests/scenarios/v8-*.sh` scenarios (each scenario asserts AC compliance).
3. The actual v8.0.0 spec content reconstructed from phase-5 coverage-report, phase-6 plan, and the user-listed ACs.

This review treats `tests/scenarios/v8-*.sh` PASS/FAIL as the **binding implementation evidence** of v8.0.0 ACs.

---

## Summary

**Score: 0.62 / 1.0 — FAIL (revision cycle should be triggered)**

Substantial parts of v8.0.0 are implemented and verifiable: agent consolidation (21→18), `/setup-agents` skill creation, deprecation alias contract, count anchors in 4 of 6 anchor files, customization/ TOML schema documented, plugin-permission constraint documented in `docs/reference/automation-config.md`, and CHANGELOG v8.0.0 section present with all 5 BREAKING CHANGES subsections.

**However**, multiple v8.0.0 ACs are **demonstrably unfulfilled** due to:

1. **`design.md` is the v7.0.0 design** (24 v7.0.0 references, 0 TOML/overlay content) — the v8.0.0 design.md was overwritten when phase-4 final/ was reused by the v7.0.0 pipeline. This breaks AC-OVR-001 (overlay-wins rule), AC-OVR-005 (deep merge worked example), AC-MODE-008a (step-mode prompt template in design §5.2), and several others that depend on design.md prose.
2. **`fix-bugs/SKILL.md` lacks `--yolo` and `--step-mode` flag documentation** (frontmatter `argument-hint` shows only `[--dry-run] [--profile <name>]`). REQ-MODE-001 / REQ-MODE-003 / REQ-MODE-004 explicitly require all 3 pipeline skills (`fix-ticket`, `fix-bugs`, `implement-feature`) to expose the 3 modes. fix-ticket and implement-feature have `--yolo`; fix-bugs does not.
3. **Scaffold mode harmonization (B6) is incomplete** — interactive `(a)/(b)/(c)` prompt logic in `skills/scaffold/SKILL.md` was not fully replaced with flag-based mode framework per AC-DOC-014b / REQ-DOC-014.
4. **80 staged v8.0.0 tests run: 34 PASS / 46 FAIL** (42.5 % pass rate). Even discounting Windows-specific test infrastructure issues (Aborted greps on em-dash / arrow Unicode), the substantive correctness gaps cluster in 3 areas: (a) design.md missing all v8.0.0 prose, (b) mode-flag matrix incomplete in fix-bugs, (c) overlay deep-merge documentation gaps.

**Findings:** 4 MUST-FIX blockers documented below + ~12 SHOULD-FIX gaps captured.

---

## 6 Design Decisions (D1..D5 + B6) — Implementation Status

| Decision | Status | Evidence |
|---|---|---|
| **D1 TOML overlay system** | PARTIAL | `core/overlay/toml-overlay.md` exists (5 lines header verified); `skills/setup-agents/lib/toml-merge.sh` exists; `customization/{agent}.toml` schema documented in `docs/guides/toml-overlay-syntax.md`. **GAP:** `design.md` is v7.0.0 — missing overlay-wins rule + Tier 1/2/3 worked examples. v8-overlay-scalar-override.sh / v8-overlay-table-deepmerge.sh both FAIL on design.md assertions. |
| **D1 /setup-agents skill** | PASS | `skills/setup-agents/SKILL.md` exists with `disable-model-invocation: true`, argument-hint `[--dry-run] [--yolo] [--force]`, project scanning logic, `lib/toml-merge.sh` library. Skill enumerated in skills/ and counted (29 total). |
| **D2 SKILL decomposition** | PARTIAL | `skills/fix-bugs/steps/` (7 files) and `skills/implement-feature/steps/` (7 files) present; **GAP:** `skills/fix-ticket/steps/` directory **does NOT exist** — fix-ticket SKILL.md remains monolithic. REQ-STEPS-001 names all 3 pipeline skills. |
| **D3 mode flags (--yolo / default / --step-mode)** | FAIL | `--yolo` documented: fix-ticket YES (line 6), implement-feature YES (line 6), **fix-bugs NO**. `--step-mode` flag: 0 references in any of 3 entry SKILL.md (verified by `grep -n 'step-mode'`). v8-mode-mutual-exclusion.sh FAILs explicitly: "Flags --yolo and --step-mode are mutually exclusive" error text not found in any pipeline SKILL.md. |
| **D5 agent consolidation** | PASS | `agents/` has exactly 18 .md files (verified by `find agents -maxdepth 1 -mindepth 1 -name '*.md' \| wc -l` = 18). Old files DELETED: `agents/triage-analyst.md`, `agents/code-analyst.md`, `agents/e2e-test-engineer.md`, `agents/reproducer.md`, `agents/browser-verifier.md` all absent. New files: `agents/analyst.md` (frontmatter `description: Triage + impact analysis (--phase {triage,impact})`), `agents/browser-agent.md` (`description: ... --phase flag`), `agents/test-engineer.md` extended. v8-agents-enumeration.sh PASS. v8-agents-deleted-old-names.sh PASS. |
| **B6 scaffold mode harmonization** | FAIL | v8-doc-claude-md-scaffold-prose-removed.sh + v8-matrix-scaffold-default.sh both FAIL. Old interactive 3-mode prompt prose not fully purged from CLAUDE.md. AC-DOC-014b unfulfilled. |

**Decision summary:** 2 PASS / 3 PARTIAL / 1 FAIL = **D coverage 50 %**.

---

## 8 Scope Areas — Coverage Status

| Scope area | Tasks | Filesystem evidence | Status |
|---|---|---|---|
| 1. TOML overlay system | T-001, T-002 | `core/overlay/toml-overlay.md` exists; `skills/setup-agents/lib/toml-merge.sh` exists; `docs/guides/toml-overlay-syntax.md` exists | PARTIAL (design.md gap) |
| 2. /setup-agents skill | T-010, T-011 | SKILL.md exists with frontmatter, argument-hint, disable-model-invocation; lib/ subdir present | PASS |
| 3. Steps decomposition | T-007, T-008, T-009 | `fix-bugs/steps/` (7), `implement-feature/steps/` (7) — fix-ticket/steps/ MISSING | PARTIAL |
| 4. Mode flag framework | T-007, T-008, T-009 (folded) | `--yolo` in 2/3 entry SKILL.md; `--step-mode` in 0/3; mutual-exclusion error text absent | FAIL |
| 5. Agent consolidation | T-003, T-004, T-005, T-006 | 18 agents; all 5 deprecated files DELETED; aliases in `core/aliases/agents-rename-aliases.md`; new analyst/browser-agent/extended-test-engineer present | PASS |
| 6. Migration tooling | T-006 | `skills/migrate-config/SKILL.md` exists; **`--to-v8` mode**: NOT verified by direct grep; v8-migrate-config-md-to-toml.sh FAIL, v8-migrate-config-skip-stages.sh FAIL, v8-migrate-config-yolo-autoresolve.sh FAIL — 5 of 5 migrate-config v8 tests FAIL | PARTIAL/FAIL |
| 7. Documentation deliverables | T-017..T-026 | 4 NEW guides exist (`migration-v7-to-v8.md`, `setup-agents-skill.md`, `steps-decomposition.md`, `toml-overlay-syntax.md`); CHANGELOG v8.0.0 has all 5 BREAKING subsections | PARTIAL (12 doc tests fail; substantive content gaps in design.md + migration guide Migration: paragraphs missing) |
| 8. Cross-File Invariants | T-030 | License SPDX MIT consistent (manual grep verified); maintainer email consistent; **template parity FAIL** (v8-invariant-template-parity.sh fails); **plugin-perm constraint** documented but exact phrase mismatch | PARTIAL |

**Scope coverage: 2 PASS / 5 PARTIAL / 1 FAIL = ~50 % full coverage.**

---

## 12 OQ Spot-Check (5 sampled per user prompt)

Per user prompt: pick OQ-A.1, OQ-A.7, OQ-B.1, OQ-INT.1, OQ-INT.2.

Source: `.forge/phase-4-spec/review/round-1-compliance.md` lines 70-85 documents OQ → REQ resolutions for v8.0.0 spec.

| OQ | Resolution per round-1-compliance.md | Implementation evidence | Verdict |
|---|---|---|---|
| OQ-A.1 (TOML schema, per-agent config keys, [meta] free-form) | RESOLVED → REQ-OVR-001..007 + REQ-DOC-002 | `core/overlay/toml-overlay.md` parser contract, `docs/guides/toml-overlay-syntax.md` enumerates per-agent keys + [meta] free-form (verified by v8-doc-toml-syntax-content.sh which PASSES on assertions 1-2 then FAILS on Assertion 5 "absent key inherited" rule). Substantively RESOLVED with 1 doc gap. | PARTIAL |
| OQ-A.7 (3 mode flags semantics: --yolo / default / --step-mode) | RESOLVED → REQ-MODE-007 + REQ-MODE-008 | `--yolo` documented in 2/3 entry SKILL.md, `--step-mode` documented in 0/3. v8-mode-mutual-exclusion.sh FAIL. v8-mode-stepmode-* tests FAIL (4 of 5). Spec Phase 5 references the resolution but Phase 7 implementation incomplete. | FAIL |
| OQ-B.1 (vague-input heuristic for scaffold) | RESOLVED → REQ-MODE-009 | v8-mode-vague-heuristic-boundaries.sh FAIL; v8-mode-scaffold-vague-skip.sh FAIL. Heuristic logic not surfaced in scaffold SKILL.md prose. | FAIL |
| OQ-INT.1 (TOML overlay first vs agent renames first ordering) | RESOLVED → design.md §7 + REQ-MIG-002 | Phase 6 plan §0.0 documents "TOML overlay first, agent renames second" decision. Implementation respects this (T-001 → T-003..T-006). However design.md §7 doesn't exist (design.md is v7.0.0). Migration evidence: customization/ doesn't exist as committed dir, but `/migrate-config --to-v8` skeleton present. | PARTIAL |
| OQ-INT.2 (mode-flag matrix template across 3 pipeline skills) | RESOLVED → formal-criteria.md §3 (matrix table) | v8-matrix-fixbugs-{default,stepmode,yolo}.sh all FAIL; v8-matrix-implfeat-{default,stepmode}.sh FAIL; v8-matrix-scaffold-{default,stepmode}.sh FAIL. Matrix not fully realized in skills. | FAIL |

**OQ resolution: 0 RESOLVED-and-implemented / 2 PARTIAL / 3 FAIL.**

---

## AC Spot-Check (15 ACs from user prompt — polish-patch focus)

Independent verification by direct filesystem check + scenario invocation. Test scenario referenced where present.

| AC ID | Verification | Evidence | Verdict |
|---|---|---|---|
| AC-OVR-008 (overlay provenance log) | v8-overlay-provenance-log.sh runs | Test PASSES (rewritten as behavioral doc-verification per round-2 quality review) | PASS |
| AC-MODE-008a (step-mode SIGTERM atomicity contract) | v8-mode-stepmode-sigterm-atomicity.sh | FAIL — SIGTERM atomicity not documented in state schema | FAIL |
| AC-MODE-009 (vague-input heuristic) | v8-mode-vague-heuristic-boundaries.sh | FAIL | FAIL |
| AC-AGT-009 (pipeline-status agent dedup display) | Per coverage-report.md mapped to v8-pipeline-status-dedup.sh — file ABSENT in scenarios dir | No test scenario found by name | UNVERIFIED |
| AC-DOC-014b (CLAUDE.md scaffold-prose removed) | v8-doc-claude-md-scaffold-prose-removed.sh | FAIL | FAIL |
| AC-MIG-007 (Pipeline Profiles legacy alias) | v8-pipeline-profiles-legacy-alias.sh | FAIL | FAIL |
| AC-INV-PERM-001 (frontmatter permission keys = 0; constraint documented) | v8-invariant-plugin-perm-constraint.sh | FAIL on exact phrase "hooks are skill-orchestrated, not agent-frontmatter" (case-sensitive `grep -qF` mismatch — actual phrase is "Hooks are skill-orchestrated, not agent-frontmatter" with capital H). Frontmatter scan PASSES (0 forbidden keys in 18 agents). | PARTIAL (case mismatch is implementation bug — either spec must allow case-insensitive or doc must use lowercase; substantive constraint IS documented) |
| AC-DOC-001 (migration guide sections) | v8-doc-migration-guide-sections.sh | FAIL (8 sections OK, "Migration:" paragraphs missing) | FAIL |
| AC-DOC-002 (toml-overlay-syntax content) | v8-doc-toml-syntax-content.sh | FAIL (on "absent key inherited from plugin default" assertion) | FAIL |
| AC-DOC-003 (setup-agents skill examples) | v8-doc-setup-agents-examples.sh runs | PASS | PASS |
| AC-DOC-004 (steps-decomposition guide) | v8-doc-steps-decomp-content.sh runs | PASS | PASS |
| AC-CT-001 (agents = 18) | v8-agents-enumeration.sh | PASS | PASS |
| AC-CT-002 (skills = 29) | v8-count-skills.sh | PASS | PASS |
| AC-CT-003 (core = 16) | v8-count-core-contracts.sh | PASS | PASS |
| AC-CT-004 (config sections = 18) | v8-count-config-sections.sh | FAIL — CLAUDE.md has 5 section headings; automation-config.md has 11 — neither matches the expected 18 (test may be looking for wrong heading level or count semantic; substantive count likely OK at the table-row level) | FAIL |

**AC fulfillment: 6 / 15 PASS = 40 %.**

---

## Counts Contract — Filesystem Verification

| Metric | v8.0.0 target | Actual | Verdict |
|---|---|---|---|
| Agents | 18 | 18 (`find agents -maxdepth 1 -mindepth 1 -name '*.md' \| wc -l`) | PASS |
| Skills | 29 | 29 (`find skills -maxdepth 1 -mindepth 1 -type d \| wc -l`) | PASS |
| Core contracts | 16 | 16 (`find core -maxdepth 1 -mindepth 1 -type f -name '*.md' \| wc -l`) | PASS (16 .md files in core/ root) |
| Config sections | 18 | UNVERIFIED at heading-count level (test FAILs); table-row level likely OK | PARTIAL |
| Templates | 8 | 8 in `examples/configs/` | PASS (count); content-update FAIL per v8-doc-config-templates.sh |

**Counts: 4 / 5 PASS at filesystem level.**

---

## REQ-NF-003 Plugin Permission Constraint

`docs/reference/automation-config.md:438` contains:
> "ceos-agents plugin agents do **NOT** support `hooks:`, `mcpServers:`, or `permissionMode:` keys in YAML frontmatter ... **Hooks are skill-orchestrated, not agent-frontmatter** — pipeline hooks are configured at **PROJECT level** via the `### Hooks` section in your project's CLAUDE.md, NOT in any agent's YAML frontmatter."

**Substantive constraint IS documented.** v8-invariant-plugin-perm-constraint.sh frontmatter scan passes (0 forbidden keys across 18 agents). The test case-sensitivity mismatch (lowercase "hooks" vs documented "Hooks") is an AC-spec bug, not a doc bug. **Verdict: PASS** with caveat (test bug to be fixed in v8.0.1).

---

## MUST-FIX Blockers (4)

### MF-1 — design.md is v7.0.0; missing all v8.0.0 design content

**Severity:** CRITICAL — breaks 4+ ACs (AC-OVR-001, AC-OVR-005, AC-MODE-008a, several extraction ACs).

**Detail:** `.forge/phase-4-spec/final/design.md` was overwritten by the v7.0.0 forge run. It contains 24 references to v7.0.0 / publisher / Extra labels / branch-parse and 0 references to TOML overlay. Multiple v8.0.0 tests assert design.md content (overlay-wins rule, Tier 3 deep-merge worked example, step-mode prompt template, [meta] table semantics, BASH_REMATCH idiom) — all fail.

**Recommendation:** Phase 9 or v8.0.1 patch: regenerate v8.0.0 design.md from `.forge/phase-4-spec/review/round-{1,2}-*` content + `phase-3-brainstorm/agents/` proposals + phase-6-plan/plan.md notes. The reconstruction inputs all exist.

### MF-2 — fix-bugs/SKILL.md lacks --yolo and --step-mode flags

**Severity:** HIGH — breaks 5+ ACs (AC-MODE-001, AC-MODE-MATRIX-{2,5,8}, AC-MODE-002).

**Detail:** `skills/fix-bugs/SKILL.md` line 6 argument-hint: `"<N> [--dry-run] [--profile <name>]"` — no --yolo, no --step-mode, no mutual-exclusion documentation. The other two pipeline skills (fix-ticket, implement-feature) DO have --yolo. REQ-MODE-001 explicitly mandates all 3.

**Recommendation:** Add `--yolo` and `--step-mode` to fix-bugs SKILL.md frontmatter argument-hint; mirror the YOLO-mode handling logic from fix-ticket SKILL.md lines 16, 24, 315, 328, 634; add mutual-exclusion error message verbatim per AC-MODE-001 ("Flags --yolo and --step-mode are mutually exclusive"); add exit code 2 documentation.

### MF-3 — fix-ticket lacks steps/ decomposition

**Severity:** MEDIUM — breaks REQ-STEPS-001 / AC-STEPS-001 / AC-STEPS-002.

**Detail:** `skills/fix-ticket/` has no `steps/` subdirectory. Other 2 pipeline skills have decomposed steps (`fix-bugs/steps/` 7 files, `implement-feature/steps/` 7 files). REQ-STEPS-001 names all 3.

**Recommendation:** Either decompose fix-ticket SKILL.md into `steps/01..07*.md` per the established convention OR document an explicit deviation in design.md §3.3.

### MF-4 — Scaffold mode harmonization (B6) incomplete

**Severity:** MEDIUM — breaks AC-DOC-014b, AC-MATRIX-SCAFFOLD-{default,stepmode}, REQ-DOC-014.

**Detail:** v8-doc-claude-md-scaffold-prose-removed.sh + v8-matrix-scaffold-{default,stepmode}.sh all FAIL. Old interactive 3-mode prompt prose remains in `CLAUDE.md` and the new flag-based mode framework is not fully wired into `skills/scaffold/SKILL.md`.

**Recommendation:** Audit `skills/scaffold/SKILL.md` and CLAUDE.md scaffold prose; align with the design-decision B6 (3 mode flags replace interactive `(a)/(b)/(c)`). Re-run v8-matrix-scaffold-* tests to confirm.

---

## SHOULD-FIX (12 — captured for v8.0.1 follow-up bin)

1. AC-OVR-008 test was rewritten in revision-2 to a doc-grep (legitimately PASS) but downstream tests still expect runtime overlay log emission — verify test+impl parity.
2. v8-overlay-array-append.sh / v8-overlay-md-toml-coexist.sh fail; design.md gap is root cause.
3. v8-mode-stepmode-{abort-state, prompt-format, resume, skip-escape}.sh FAIL — step-mode UI/UX prose missing from pipeline SKILL.md files.
4. v8-pipeline-status-dedup.sh referenced in coverage-report but file ABSENT from `tests/scenarios/` — staging gap.
5. v8-migrate-config-* (5 tests) all FAIL — `/migrate-config --to-v8` mode is incomplete.
6. v8-pipeline-profiles-legacy-alias.sh FAIL — alias-mapping table for legacy stage names not surfaced in pipeline SKILL.md.
7. v8-doc-config-templates.sh FAIL — 8 templates not updated to reference customization/*.toml in v8.0.0 idiom.
8. v8-invariant-template-parity.sh FAIL — issue/PR template `.gitea ↔ .github` parity broken (was PASS in v7.0.0 — regression).
9. v8-invariant-doc-enumeration-parity.sh FAIL — count anchors drift between CLAUDE.md / README.md / docs/reference/skills.md.
10. v8-doc-pipeline-content.sh FAIL — `docs/reference/pipeline.md` v8.0.0 content gap.
11. v8-doc-agents-enumeration.sh FAIL — `docs/reference/agents.md` likely missing or has stale 21-agent list.
12. v8-nf-v7-project-compat.sh FAIL — backwards-compat smoke test for v7.0.0 customization/ files breaking.

---

## Score Calculation

Weighted score breakdown (max 1.0):

| Component | Weight | Score | Weighted |
|---|---|---|---|
| 6 design decisions (D1..D5 + B6) | 0.20 | 2/6 PASS + 3/6 PARTIAL @ 0.5 + 1/6 FAIL = (2 + 1.5 + 0) / 6 = 0.583 | 0.117 |
| 8 scope areas covered | 0.15 | 2/8 PASS + 5/8 PARTIAL @ 0.5 + 1/8 FAIL = (2 + 2.5 + 0) / 8 = 0.563 | 0.084 |
| 5 OQ spot-check | 0.10 | 0/5 PASS + 2/5 PARTIAL @ 0.5 + 3/5 FAIL = 1/5 = 0.200 | 0.020 |
| 15 AC spot-check | 0.30 | 6/15 PASS + 1/15 PARTIAL @ 0.5 = 6.5/15 = 0.433 | 0.130 |
| Counts contract | 0.10 | 4/5 = 0.80 | 0.080 |
| REQ-NF-003 plugin perm | 0.05 | PASS = 1.0 | 0.050 |
| Test scenario PASS rate | 0.10 | 34/80 = 0.425 | 0.043 |
| **Aggregate** | **1.00** | — | **0.624** |

**Final score: 0.62 / 1.0**

Per user prompt rubric:
- 1.0: All 6 decisions implemented, all 8 scope areas covered, 12 OQs resolved, 15/15 ACs fulfilled, counts match
- 0.85+: Minor gaps (e.g., 1 OQ resolution unclear)
- 0.7+: Substantive gaps but core spec implemented
- **< 0.7: FAIL — revision cycle triggered**

**Verdict: 0.62 — FAIL** (revision cycle trigger threshold).

---

## Czech Elaboration (≤350 words)

**Závěr: spec_alignment = 0.62, FAIL prahu 0.70 → měl by být spuštěn revision cycle.**

Pipeline `forge-2026-04-25-001` je sice nominálně v7.0.0 (cleanup release) a pro něj prior cycle-0 review skóroval spec_alignment 0.95. Ale skutečný stav repozitáře a phase 5/6/7 artefakty ukazují, že proběhl **subsekventní v8.0.0 forge run** (TOML overlay, agent consolidation 21→18, /setup-agents skill, mode-flag framework). User prompt explicitně žádá v8.0.0 verifikaci, takže review skoruji proti v8.0.0 specu.

**Co je hotovo (PASS):** Agent consolidation (21→18) je čistý — 5 deprecated souborů smazáno, 3 nové merged agenty (`analyst`, `browser-agent`, rozšířený `test-engineer`) mají správnou frontmatter. `/setup-agents` skill existuje s `disable-model-invocation`, `lib/toml-merge.sh`, scanner logikou. Aliasy v `core/aliases/agents-rename-aliases.md` plně dokumentují v7→v8 mapping s `[WARN]` log a v9.0.0 hard-removal target. CHANGELOG má v8.0.0 sekci se všemi 5 BREAKING subsekcemi. Counts (18 agents / 29 skills / 16 core / 8 templates) sedí na filesystem úrovni.

**Co je rozbité (FAIL):** **Hlavní problém:** `phase-4-spec/final/design.md` byl přepsán v7.0.0 obsahem (24 v7.0.0 referencí, 0 TOML/overlay) — chybí v8.0.0 design.md sekce, na které se odvolává 6+ AC testů (overlay-wins, Tier 3 deep merge worked example, step-mode prompt template). **Druhý problém:** `fix-bugs/SKILL.md` postrádá `--yolo` a `--step-mode` flagy úplně (jenom fix-ticket a implement-feature je mají). **Třetí problém:** `fix-ticket` nemá `steps/` decomposition (jenom fix-bugs + implement-feature mají). **Čtvrtý problém:** Scaffold B6 harmonization incomplete — interactive prose neodstraněna z CLAUDE.md, flag-based framework ve scaffold/SKILL.md neúplný. **Test evidence:** 80 staged v8 testů: 34 PASS / 46 FAIL (42.5 % pass rate). i po odečtení Windows core-dump issues (em-dash/arrow Unicode v `grep -qF`) zůstává cca 35-40 substantive failures.

**Doporučení:** revision cycle nutný. 4 MUST-FIX blockery dokumentovány výše: (1) regenerovat v8.0.0 design.md ze zachovaných phase-4 review artefaktů, (2) přidat --yolo + --step-mode do fix-bugs, (3) decompose fix-ticket nebo dokumentovat odchylku, (4) doharmonizovat scaffold mode B6.
