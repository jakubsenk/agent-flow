# Code Review — Scaffold Plugin v1.0

**Soubor:** `docs/plans/2026-02-27-04-scaffold-plugin-v1.0.md`
**Reviewer:** Claude Opus 4.6 (superpowers:code-reviewer)
**Datum:** 2026-02-27
**Verdikt:** Připraven po template cleanup + model fix

---

## Co je dobře

- Separační rationale je důkladný — 5 nezávislých důvodů pro oddělený plugin
- Agent definice přesně kopírují CLAUDE-agents konvence
- Q&A sekce (13 otázek) je neobvykle silná — pre-mortem thinking
- MVP cut (steps 1-12) dává kompletní vertical slice
- Generovaný CLAUDE.md příklad (Appendix B) validuje config-writer design end-to-end
- Srovnání s existujícími nástroji (Appendix C) jasně ukazuje differentiator

---

## Critical (3)

### C1: Template parametrizace je v rozporu s "pure markdown / no dependencies"

Section 4 definuje `.tmpl` soubory s `{{#if database}}...{{/if}}` a `{{#each dependencies}}...{{/each}}` syntaxí. Pak říká "agent je dostatečně inteligentní na to, aby rozuměl `{{#if}}` blokům bez formálního parseru."

Q1 správně odpovídá "hybridní přístup: templates definují STRUKTURU, agent generuje OBSAH." Ale Section 4 to nereflektuje — `.tmpl` soubory implikují template-engine approach.

**Doporučení:** Dropnout `.tmpl` extension a `{{#if}}`/`{{#each}}` syntaxi. Templates = referenční příklady + `template.md` metadata. Agent čte template adresář jako inspiraci a generuje soubory od nuly.

### C2: Stack-selector (opus) neodpovídá model selection konvencím

CLAUDE-agents konvence: opus = critical code changes, quality review. Stack selection je analytická úloha (jako triage) → sonnet. Triage-analyst (triage rozhodnutí o severity) používá sonnet. Stack-selector (tech stack rozhodnutí) je srovnatelná decision-quality úloha.

**Doporučení:** Změnit na sonnet. Konzistence across oba pluginy + nižší cost.

### C3: Žádná rollback strategie pro selhání scaffoldu

Po 2 failed retries validace zůstane uživatel s half-generated, non-building projektem. Na rozdíl od CLAUDE-agents pipeline (rollback-agent), scaffold nemá recovery mechanism.

**Doporučení:** Option A (jednodušší): scaffold běží v prázdném adresáři → rollback = smazat vše a reportovat chyby. Option B (bezpečnější): scaffoldovat do temp dir, přesunout až po úspěšné validaci.

---

## Important (6)

### I1: Config-writer (haiku) je příliš slabý pro komplexitu úlohy

Haiku je v CLAUDE-agents pro mechanické úlohy (publisher: commit+push+PR, rollback: git revert). Config-writer musí cross-referencovat 3 upstream agenty + Config Contract + generovat validní tabulkový formát. To je reasoning-heavy úloha.

**Doporučení:** Povýšit na sonnet, nebo přidat explicitní Config Contract checklist do agent Process.

### I2: Scaffold Config chicken-and-egg problém

`/scaffold init` běží v prázdném adresáři → žádný CLAUDE.md se Scaffold Config. Fallback na `~/.claude/CLAUDE.md` vyžaduje pre-konfiguraci. První run je vždy interaktivní.

**Doporučení:** Explicitně zdokumentovat. Zvážit: nabídnout uložení preferencí do global config po prvním úspěšném scaffoldu.

### I3: Scaffolder nemá file-writing strategii

Generování 20-30 souborů přes jednotlivé Write tool calls je token-expensive a context-window sensitive. Žádná batching strategie.

**Doporučení:** Přidat batched file writing do Process: "package manifest + entry point → verify → config + database → verify → tests → verify → Docker + CI."

### I4: Tech stack detekce předpokládá single-stack projekty

Detekční tabulky hledají jeden manifest. Nespecifikuje kde hledat (root? rekurzivně?) ani jak handleovat multiple matches.

**Doporučení:** Root-first, pak jeden level subdirectories. Multiple matches → zobrazit seznam, uživatel vybere.

### I5: Cross-plugin version kompatibilita není vynucená

Config-writer je vázaný na CLAUDE-agents Config Contract major verzi, ale žádný mechanismus to nekontroluje.

**Doporučení:** Přidat `compatible_config_contract: "2.x"` do plugin metadata nebo agent definition.

### I6: PR Description Template v CLAUDE.md — header collision

Generovaný CLAUDE.md obsahuje `## Summary`, `## Root Cause` uvnitř PR Description Template — koliduje s `## Automation Config` section boundary.

**Doporučení:** Zabalit template do fenced code bloku (triple backticks) nebo použít `###`/`####` level headers.

---

## Suggestions (5)

- **S1:** Přidat `--template <name>` flag pro přímý výběr šablony
- **S2:** Effort pro template creation (step 8, "L") může být podhodnocený — zvážit split na structure + content
- **S3:** `--output-dir` parametr pro scaffolding mimo CWD
- **S4:** "What can you do?" intent v routing skillu pro discoverability
- **S5:** Zdokumentovat interakční model stack-selector otázky ↔ command (Task tool běží do completion, nemůže pausnout pro user input)
