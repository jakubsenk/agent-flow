# Phase 8 — Correctness Review (Adversary 2) — Cycle 0

**Dimension:** Correctness  
**Reviewer:** Adversary 2 (Correctness Specialist)  
**Date:** 2026-04-27  
**Release:** v8.0.0

---

## Verdict JSON

```json
{
  "dimension": "correctness",
  "score": 0.38,
  "cycle": 0,
  "revision_required": true,
  "summary": "Critical correctness failures across 7 major check areas. Hidden tests: 5/12 PASS, 7/12 FAIL. Visible tests: 217/301 total (Pass), 69 FAIL, 15 SKIP. Primary defect: monolithic SKILL.md files not decomposed (1006/672/1147 lines vs ≤120 required). Secondary defects: --step-mode not implemented in fix-bugs/implement-feature, migrate-config --to-v8 flag missing, deprecation alias not documented in pipeline skills.",
  "checks": {
    "hidden_tests": { "pass": 5, "fail": 7, "score": 0.42 },
    "visible_tests": { "pass": 217, "fail": 69, "skip": 15, "v8_fail": 46 },
    "agent_count_18": "PASS",
    "skill_count_29": "PASS",
    "core_count_16": "PASS",
    "skill_decomposition_line_count": "FAIL",
    "skill_decomposition_steps_exist": "PASS",
    "deprecated_agent_names": "FAIL",
    "changelog_v8": "PASS (content exists, test FAIL due to grep-F Windows crash)",
    "new_artifacts": "PARTIAL",
    "doc_enumeration_parity": "FAIL"
  }
}
```

---

## Detailní výsledky

### 1. Spuštění hidden testů (gold standard)

**Celkem: 5 PASS / 7 FAIL**

| Test | Výsledek | Selhání |
|------|----------|---------|
| v8-hidden-agent-rename-collision | FAIL | migrate-config SKILL.md nedokumentuje merge triage-analyst + code-analyst; design.md chybí mapping obou |
| v8-hidden-customization-md-and-toml-coexist | FAIL | setup-agents SKILL.md nedokumentuje, že .md se NEaplikuje, pokud existuje .toml |
| v8-hidden-doc-enumeration-extra-agent | PASS | — |
| v8-hidden-mode-flag-double-yolo | FAIL | design.md chybí GOT_YOLO=false inicializace (explicitní boolean pattern) |
| v8-hidden-mode-vague-heuristic-edge | FAIL | Test fixture má chybný word count (15/17 slov místo 19/20) — bug v testu, ale test vrací FAIL |
| v8-hidden-pipeline-profiles-mixed-old-new | PASS | — |
| v8-hidden-setup-agents-malicious-symlink | PASS | — |
| v8-hidden-step-mode-abort-resume | FAIL | resume-ticket SKILL.md nedokumentuje step_mode_abort resume logiku ani guard proti re-execuci |
| v8-hidden-step-override-zero-pad-mismatch | PASS | — |
| v8-hidden-template-parity-line-ending | PASS | — |
| v8-hidden-toml-malformed-recovery | FAIL | migrate-config SKILL.md chybí per-file error isolation dokumentace |
| v8-hidden-toml-quote-escape-edge | FAIL | migrate-config SKILL.md chybí triple-quote escape dokumentace; design.md chybí verbatim text escaping |

### 2. Cross-file count enumeration

| Kontrola | Expected | Actual | Výsledek |
|----------|----------|--------|----------|
| `find agents -maxdepth 1 -name "*.md"` | 18 | 18 | **PASS** |
| `find skills -maxdepth 2 -name "SKILL.md" -not -path "*/steps/*"` | 29 | 29 | **PASS** |
| `find core -maxdepth 1 -name "*.md"` | 16 | 16 | **PASS** |

### 3. Dokumentace enumeration parity

- **CLAUDE.md:** Uvádí 18 agentů (agents/: 18 souborů) — PASS. Uvádí 29 skills — PASS. Agentní tabulka v `### Key Conventions` correctly enumertuje 18 canonical agents.
- **README.md:** Odkazuje na 29 skills, 18 agents — PASS.
- **docs/reference/agents.md:** Uvádí 18 agentů — PASS v textu, ale test `v8-doc-agents-enumeration` FAIL kvůli jednořádkové extrakci z tabulky (diff tool issue).
- **CLAUDE.md `### Model Selection` tabulka:** Řádek `test-engineer (incl. \`--e2e\` flag)` způsobuje FAIL v `xref-agent-registry` — název nesedí na filesystem (`agents/test-engineer.md`). Tabulka musí uvádět `test-engineer`, ne `test-engineer (incl. \`--e2e\` flag)`.
- **CLAUDE.md `Pipeline Profiles` skip list:** Stále uvádí staré jméno `code-analyst`, `e2e-test-engineer`, `reproducer`, `browser-verifier` místo v8.0.0 jmen `analyst-impact`, `test-engineer-e2e`, `browser-agent-reproduce`, `browser-agent-verify`. Způsobuje FAIL `xref-skip-stage-names`.

### 4. Deprecated agent names — KRITICKÝ FAIL

`grep` přes `agents/` + `skills/` vrátil **148 aktivních referencí** na deprecated jména (`triage-analyst`, `code-analyst`, `e2e-test-engineer`, `reproducer`, `browser-verifier`). Kromě nutných/přechodových výskytů (aliases, alias-tables v docs) se staré názvy stále používají aktivně:
- `agents/rollback-agent.md:26` — aktivní reference na `e2e-test-engineer` v runtime logice
- `agents/architect.md` — reference na `code-analyst`, `triage-analyst` (funkční logika, ne jen komentáře)
- `skills/analyze-bug/SKILL.md` — dispatch `ceos-agents:triage-analyst`, `ceos-agents:code-analyst`
- `agents/reviewer.md` — reference na `triage-analyst` v AC fulfillment sekci
- `skills/estimate/SKILL.md` — table rows pro `triage-analyst`, `code-analyst`, `e2e-test-engineer`

**Závažnost: KRITICKÁ** — agent dispatch references na neexistující agenty (starých 21 jmen) způsobí runtime error v produkci.

### 5. SKILL.md decomposition — KRITICKÝ FAIL

| Soubor | Aktuální počet řádků | Požadovaný max | Výsledek |
|--------|---------------------|----------------|----------|
| `skills/fix-bugs/SKILL.md` | **1 006** | ≤ 120 | **FAIL** |
| `skills/implement-feature/SKILL.md` | **672** | ≤ 120 | **FAIL** |
| `skills/scaffold/SKILL.md` | **1 147** | ≤ 120 | **FAIL** |

`steps/` adresáře **existují** (PASS) a obsahují správný počet souborů, ale entry SKILL.md nebyla zkrácena na ≤120 řádků (dispatch-only thinness). To je nejobjemnější selhání implementace — celý decomposition contract (AC-STEPS-001) není splněn.

Navíc `scaffold/SKILL.md` stále obsahuje staré v7 mode řetězce `(a) Interactive`, `(b) YOLO with checkpoint` (line 273-274) a 17 referencí na `mode is Interactive`/`mode is Full YOLO` — scaffold mode harmonizace není implementována v hlavním SKILL.md, přestože `steps/` soubory ji implementují.

### 6. CHANGELOG entry — CONDITIONAL PASS

CHANGELOG.md sekce `## v8.0.0` existuje a obsahuje všech 5 breaking-change sekcí. Test `v8-doc-changelog-v8` selhává kvůli Windows grep crash (`grep -qiF` s multibyte `→` UTF-8) — jde o bug v testu na Windows, nikoliv chybu implementace. Obsah CHANGELOG je věcně správný.

### 7. Nové artifacts — PARTIAL PASS

| Artifact | Existuje? | Výsledek |
|----------|-----------|----------|
| `core/overlay/toml-overlay.md` | ANO | PASS |
| `skills/setup-agents/SKILL.md` | ANO | PASS |
| `skills/setup-agents/lib/toml-merge.sh` | ANO | PASS |
| `examples/customization/reviewer-strict-security.toml` | ANO | PASS |
| `examples/customization/fixer-no-tests.toml` | ANO | PASS |
| `examples/customization/analyst-monorepo.toml` | ANO | PASS |
| `examples/customization/step-override-example.md` | ANO | PASS |
| `docs/guides/migration-v7-to-v8.md` | ANO | PASS |
| `docs/guides/toml-overlay-syntax.md` | ANO | PASS |
| `docs/guides/setup-agents-skill.md` | ANO | PASS |
| `docs/guides/steps-decomposition.md` | ANO | PASS |
| `docs/reference/pipeline.md` | ANO | PASS |
| `core/aliases/agents-rename-aliases.md` | ANO | PASS |

Nové artifacts **existují** — to je pozitivní. Problém je v **obsahu** klíčových souborů:
- `skills/migrate-config/SKILL.md` chybí `--to-v8` flag, backup dokumentace, `[[process_additions]]` wrapping, per-file error isolation, triple-quote escape
- `skills/fix-bugs/SKILL.md`, `skills/fix-ticket/SKILL.md`, `skills/implement-feature/SKILL.md` chybí `--step-mode` flag dokumentace a `mutually exclusive` error text
- `resume-ticket/SKILL.md` chybí `step_mode_abort` resume logika

---

## Souhrnné hodnocení

**Skóre: 0.38 / 1.0**

Rationale pro nízké skóre:
- **Nejkritičtější defekt:** Tři pipeline SKILL.md soubory (fix-bugs, implement-feature, scaffold) NEJSOU zkráceny na ≤120 řádků. steps/ adresáře existují, ale entry SKILL.md zůstaly monolitické. Jde o hlavní architektonický kontrakt v8.0.0 (AC-STEPS-001) — nesplněn.
- **Druhý kritický defekt:** 148 aktivních referencí na deprecated agent names v runtime kódu (dispatch calls, rollback logic, reviewer logic). V produkci by způsobily runtime error.
- **Třetí kritický defekt:** `--step-mode` flag není implementován v `fix-bugs/SKILL.md` ani `implement-feature/SKILL.md` (pouze v scaffold/steps/ souborech). Testová matice pro default/stepmode/yolo má 4 z 6 testů FAIL.
- **migrate-config --to-v8:** Kompletně chybí v migrate-config SKILL.md — uživatelé nemohou migrovat overlay soubory.
- Hidden testy: 7/12 FAIL (nad threshold 2 FAIL pro skóre ≥ 0.85).
- Visible v8 testy: 46 FAIL.

**Revision cycle: REQUIRED**
