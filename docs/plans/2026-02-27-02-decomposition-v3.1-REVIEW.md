# Code Review — Task Decomposition v3.1

**Soubor:** `docs/plans/2026-02-27-02-decomposition-v3.1.md`
**Reviewer:** Claude Opus 4.6 (superpowers:code-reviewer)
**Datum:** 2026-02-27
**Verdikt:** Potřebuje reframing na LLM-executable instrukce

---

## Co je dobře

- Fundamentální koncept (dekomponovat složité tickety na subtask DAG) řeší reálný problém
- ASCII diagramy dependency vzorů (linear, fan-out, diamond, complex) jsou výborné
- Důkladná analýza sequential vs. parallel mode s rozhodovací logikou
- Error handling strategie (fail-fast vs. continue-on-failure) je dobře promyšlená
- Resumabilita s `/resume-ticket` integrací je konzistentní s existující architekturou
- 8 detailních UX scénářů pokrývají reálné use cases

---

## Critical (3)

### C1: Pseudokód je nerealistický pro LLM exekuci

Dokument specifikuje algoritmy (Kahnův topologický sort, DAG traversal, execution engine) jako software. Ale implementační médium jsou markdown instrukce pro LLM:

```python
# Tohle LLM sledující markdown instrukce neudělá deterministicky:
FUNKCE detect_cycles(dag):
    in_degree = {node: len(node.depends_on) for node in dag}
    queue = [node for node in dag if in_degree[node] == 0]
    ...
```

**Doporučení:** Přeformulovat z "jak to algoritmicky spočítat" na "co má LLM udělat":
- "Ověř, že žádný subtask nemá cyklickou závislost (A→B→C→A). Pokud najdeš cyklus, BLOCK."
- "Spusť subtasky v pořadí: nejdřív ty bez závislostí, pak ty jejichž závislosti jsou completed."

### C2: Atomické YAML zápisy nejsou dosažitelné

Dokument navrhuje "atomic write: zápis do temp souboru, pak rename". Ale command instruuje Claude Code přes Write tool, který atomické operace nepodporuje. Task tree persistence potřebuje realističtější mechanismus.

**Doporučení:** Přijmout Write tool "as is" a přidat validaci při načtení (pokud YAML je invalid, rekonstruovat z git stavu).

### C3: Timeout per subtask je neimplementovatelný

Claude Code Task tool nemá nativní timeout. Dokument to sám přiznává (line 1538-1540), ale stále specifikuje konkrétní minutové limity jako hard spec. Command nemůže přerušit běžící Task.

**Doporučení:** Nahradit timeout soft warningem v command instrukcích: "Pokud subtask trvá neočekávaně dlouho, zapiš warning do execution logu."

---

## Important (6)

### I1: Heuristický decomposer je nedospecifikovaný

Dokument říká, že 60% Fáze 2 je implementovatelné bez Architecta díky "heuristické dekompozici". Ale heuristika je popsaná jen 5 řádky pseudokódu:
```
Pokud code-analyst hlasi:
  - 2+ root cause candidates -> 1 subtask per candidate
  - 5 affected files -> seskupit dle modulu
  - Test coverage gaps -> 1 extra subtask pro testy
```

Chybí: jak "seskupit dle modulu"? Jak identifikovat hranice modulů? Jak generovat acceptance criteria?

### I2: Squash commit strategie koliduje s per-subtask rollbackem

Default commit strategie je "squash" (všechny subtask commity na konci squashnou). Ale per-subtask rollback používá `git reset --hard {restore_point_N}` — po squash tyto restore points neexistují.

**Doporučení:** Squash provést až po úspěšné integraci (ne průběžně), nebo rollback přepnout na soft reset.

### I3: Threshold 60 řádků pro auto-decompose je příliš agresivní

Fixer má 100-line limit. Auto-decompose se aktivuje při >60 řádcích. Mnoho normálních bugů má 60-80 řádků a projdou fixerem bez problémů. Threshold 60 způsobí zbytečnou dekompozici.

**Doporučení:** Zvýšit na 80 (buffer 20 řádků místo 40), nebo kombinovat s dalšími signály (60 lines AND >=3 files).

### I4: Flag parsing není specifikované

`--decompose`, `--no-decompose`, `--dry-run` — jak přesně je command parsuje z `$ARGUMENTS`? Existující commands (fix-bugs.md) parsují `--dry-run` z volného textu. Nové flagy by měly být specifikovány stejným mechanismem.

### I5: Rollback-agent potřebuje rozšíření

Per-subtask rollback je nová capability — existující rollback-agent dělá full rollback. Rozsah změn v rollback-agent.md je podhodnocený (dokument říká effort "S").

### I6: Paralelní exekuce přes worktrees je neprokázaná

Claude Code Task tool s paralelními worktrees — nikde v existující codebase není precedent. Fix-bugs.md používá worktrees pro batch processing, ale ne pro paralelní subtasky jednoho ticketu.

---

## Minor (6)

- **M1:** Verze v3.1.0 závisí na v3.0.0, ale YAML format a DAG engine jsou nezávislé — verze by měla reflektovat co reálně shippne
- **M2:** Config example headers — český vs. anglický formát
- **M3:** `skipped` stav chybí v Architect output schema (Section 2), přestože je v state tracking (Section 6)
- **M4:** Max subtasks: "Default: 5" vs. "Hard limit 5" — nekonzistentní charakterizace (config range 1-10 říká, že 5 je default, ne limit)
- **M5:** Token pricing je hardcoded (February 2026) — prezentovat jako ilustrativní, ne absolutní
- **M6:** Resume po dnech: base branch mohl mezitím odjet. Přidat poznámku o rebase/merge ověření při resume.

---

## Cross-document gap

Feature Pipeline v3.0 definuje Architect output jako "implementační plán", ale **nespecifikuje YAML task tree formát**, na kterém Decomposition v3.1 závisí. Formát je třeba synchronizovat mezi oběma dokumenty.
