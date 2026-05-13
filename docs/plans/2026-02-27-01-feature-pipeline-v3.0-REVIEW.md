# Code Review — Feature Pipeline v3.0

**Soubor:** `docs/plans/2026-02-27-01-feature-pipeline-v3.0.md`
**Reviewer:** Claude Opus 4.6 (superpowers:code-reviewer)
**Datum:** 2026-02-27
**Verdikt:** Připraven po vyřešení C1+C2

---

## Co je dobře

- Výjimečná hloubka srovnání bug-fix vs. feature pipeline (side-by-side tabulky)
- Agent definice přesně kopírují CLAUDE.md konvence (frontmatter, Goal → Expertise → Process → Constraints)
- Edge case coverage je důkladný — každý agent má dedikovanou tabulku
- Command definice zrcadlí fix-ticket strukturálně (kroky, hooks, block handler, dry-run)
- Otevřené otázky jsou dobře formulované s navrženými odpověďmi
- Datový model (Section 5) je cenný přídavek — artifact lifecycle je jasný

---

## Critical (2)

### C1: Verze v3.0.0 označená jako MINOR — rozpor s versioning policy

Dokument na řádku 6 říká `Verze pluginu: v3.0.0 (MINOR — nova volitelna funkce)`. Ale v3.0.0 je MAJOR bump (z 2.0.0). Dle CLAUDE.md versioning policy: MAJOR = breaking change v Config Contract, MINOR = nová backward-compatible funkce. Dokument opakovaně říká, že žádné breaking changes nejsou → mělo by být **v2.1.0**.

**Doporučení:** Změnit verzi na v2.1.0 v celém dokumentu, nebo explicitně zdůvodnit proč je MAJOR bump opodstatněný.

### C2: Existující agenti mají bug-specific wording v Process step 1

Dokument tvrdí "zero changes to existing agents", ale:
- `fixer.md` step 1: "Read the triage analysis and impact report"
- `reviewer.md` step 1: "Read the original bug report, triage analysis, impact report, and the fix diff"
- `test-engineer.md`: "Read the bug report, fix diff, and impact report"

Ve feature pipeline žádný "impact report" ani "bug report" neexistuje — jsou nahrazeny "implementačním plánem" a "specifikací".

**Doporučení:** Buď (A) přijmout jako known limitation a zdokumentovat, nebo (B) generalizovat wording v agentech (PATCH change — "Read the analysis report and context provided").

---

## Important (5)

### I1: resume-ticket chybí step mapping pro feature pipeline

Rozšířená detekce checkpointů přidává POST_SPEC, ale chybí explicitní mapování:
- POST_SPEC → spusť od architect
- POST_ANALYSIS (feature) → spusť od fixer (s implementačním plánem)

Chybí i edge case: co když pro jeden issue existují oba komentáře (Triage dokončen + Spec dokončen)?

### I2: Feature query nemá konzumenta ve Fázi 1

Feature Workflow config definuje `Feature query`, ale žádný command ani agent ho nekonzumuje v Phase 1. Spec-analyst ho nereferencuje, implement-feature ho nevaliduje.

**Doporučení:** Definovat konzumenta, nebo přesunout do Phase 2 spolu s Max subtasks a Subtask strategy.

### I3: 100-line limit je pro features příliš restriktivní

Architect blokuje při >100 řádcích celkem. Pro features je 100 řádků často nedostatečných i pro malé features (OAuth příklad by reálně překročil). V Phase 1 bez dekompozice bude většina reálných features okamžitě blokována.

**Doporučení:** Zvýšit limit na 200-300 řádků nebo učinit konfigurovatelným přes Feature Workflow config.

### I4: Skill "bug-workflow" bude handlovat features

Po v3.0 bude skill `bug-workflow` routovat i feature intenty, ale název a description stále říkají "bugs". Minimálně updatovat description. Zvážit rename na `dev-workflow` (breaking change — opatrně).

### I5: Chybí WebFetch v implement-feature allowed-tools

Spec-analyst Process step 2 říká "Download and analyze attachments." Fix-bugs.md má WebFetch v allowed-tools, implement-feature ne.

---

## Minor (6)

- **M1:** Checkpoint komentář `Spec dokoncen` — mix češtiny a angličtiny (konzistentní s existujícím patternem, ale stojí za povšimnutí)
- **M2:** Odhad 10-14 hodin může být optimistický, zejména end-to-end smoke test vyžaduje funkční projekt s MCP
- **M3:** CLAUDE.md "Repository Structure" počty (8 agents, 12 commands) potřebují explicitní update v implementačním plánu — lesson learned z 2026-02-24
- **M4:** Config example používá `Klíč/Hodnota` headers, ale CLAUDE.md říká `| Key | Value |`
- **M5:** Forward reference na `/implement-features` (plural, batch) vytváří soft expectation
- **M6:** Open question o `/implement-features` je dobře zdůvodněný (ne v Phase 1), ale webhook events v Appendix C ho zmiňují
