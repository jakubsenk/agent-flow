# Forge Run Report — Format Evaluation (forge-2026-04-14-002)

## Zadání

Vyhodnotit, zda by dokumenty ceos-agents pluginu (agenti, skills, core kontrakty, config šablony — vše markdown) měly přejít na YAML nebo JSON. Posoudit dopad na spotřebu tokenů, kvalitu výstupů, zpracovatelnost a udržovatelnost.

## Klíčový závěr

**Markdown je správný a optimální formát pro tento plugin.** Žádná velká migrace formátu není opodstatněná.

### Proč

1. **Ekosystémový hard constraint:** Claude Code vyžaduje `.md` soubory pro skills (SKILL.md) a agenty. Přejmenování na `.yaml`/`.json` by rozbilo plugin — skills by zmizely z tab-complete, agenti by nebyli nalezeni.

2. **87-96% obsahu je přirozený jazyk:** Procesní kroky, constrainty, expertise popisy. Formátová změna nemůže komprimovat prózu — token cost je dán instrukcemi, ne serializačním formátem.

3. **LLM comprehension:** Markdown numbered lists jsou optimální pro sekvenční instrukce. YAML by degradoval instrukce na datové struktury, se kterými LLM pracuje jinak (extrakce dat vs. následování kroků).

4. **Token úspory jsou marginální:** Jediná oblast s reálnou úsporou jsou `| Key | Value |` tabulky v config šablonách (~35% úspora), ale ty tvoří jen ~3% celkového token budgetu (~1,250 tokenů z ~119,100).

5. **Core kontrakty jsou efektivnější v próze:** Inline typing konvence (`**field** (type, required): description`) je 40-60% kompaktnější než YAML schema.

## Implementované změny (v6.5.1 PATCH)

| Změna | Soubor | Popis |
|-------|--------|-------|
| C1 | `agents/scaffolder.md` | Fix duplikátního kroku 4b → sekvenční číslování 1-6 |
| C2 | `skills/fix-bugs/SKILL.md` | HTML contributor note o záměrném opakování atomic-write |
| C3 | `agents/triage-analyst.md` | MUST constrainty: Quality gate (PASS/UNCLEAR), Reproduction steps (JSON array) |
| C4 | `agents/code-analyst.md` | MUST constrainty: root cause confirmed (YES/NO), Risk level (LOW/MEDIUM/HIGH) |
| C5 | `agents/fixer.md` | MUST constraint: NEEDS_DECOMPOSITION exact string |
| C5 | `agents/reviewer.md` | MUST constrainty: Verdict (APPROVE/REQUEST_CHANGES/BLOCK), AC fulfillment (FULFILLED/PARTIALLY/NOT ADDRESSED) |

**5 nových testů:** `tests/scenarios/ac1-*.sh` až `ac5-*.sh`

## Test výsledky

- Před: 72 testů, 70 pass, 2 fail (pre-existující: xref-agent-registry, xref-command-count)
- Po: 77 testů, 75 pass, 2 fail (stejné pre-existující selhání)
- **Žádná regrese.**

## Verifikace

FULL_PASS (aggregate 1.00). Všech 7 acceptance kritérií splněno.

## Odložené položky

| Položka | Verze | Důvod odložení |
|---------|-------|----------------|
| `## Machine Output` sekce v agentech | v7.0.0 (MAJOR) | Nová strukturovaná output sekce mění agent output contract. Potřeba design rozhodnutí: aktivní parsing vs. suplementární. |
| Dual-format config podpora (colon notation) | v6.6.0 (MINOR) | Blast radius 12+ souborů, nutná aktualizace CLAUDE.md kontraktu. Token úspora ~260/run nestojí za MAJOR verzi. |
| Dekompozice velkých skill souborů | TBD | Blokováno na runtime výzkumu — Claude Code nepodporuje multi-file skill loading. |

## Metriky

- Celkové tokeny: ~555K estimated
- Celková doba: ~40 minut
- Fáze: 10 (0-9), žádné přeskočeny
- Review rounds: 0
- Eskalace: 0
- Revision cycles: 0
