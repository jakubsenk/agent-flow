# Analyza ukolu — Phase 0 Meta-Agent

## Typ ukolu

**Klasifikace:** research / design
**Popis:** Gap analyza pluginu ceos-agents vuci pozadavkum realneho onboardingu projektu SK kompenzace (Oracle PL/SQL + Redmine + postupna adopce). Zadny kod se nemeni — vystupem je strukturovany analyticko-navrharsky dokument.

## Slozitost

| Dimenze | Hodnoceni | Zduvodneni |
|---------|-----------|------------|
| Rozsah | Stredni | 8 dokumentu k analyze, kazdy 50-300 radku; krizove referencovani vuci 19 agentum, 26 skills, 11 core modulum |
| Ambiguita | Stredni | Pozadavky jsou jasne formulovane (Milan Martak), ale nektere implikace vyzaduji interpretaci (co presne znamena "postupne nasazovani" v kontextu ceos-agents) |
| Riziko | Nizke | Zadne zmeny kodu — analyza je read-only |
| Domenovka znalost | Vysoka | Vyzaduje hlubokou znalost architektury ceos-agents (2-vrstvy system, pipeline kontrakty, Automation Config schema) + porozumeni Redmine workflow + Oracle PL/SQL dev stacku |

**Celkova slozitost:** STREDNI (M)

## Domena

- **Primarni:** Architektura Claude Code pluginu (ceos-agents)
- **Sekundarni:** Issue tracker integrace (Redmine), Oracle PL/SQL vyvoj, agenticky workflow design
- **Kontext:** Enterprise onboarding scenario — App tym CEOS Data, postupna adopce

## Spolehlivost odhadu

**Confidence:** 0.90

Vysoka spolehlivost, protoze:
1. Dokumenty jsou kompletni a detailni (8 souboru, ~1200 radku celkem)
2. Codebase ceos-agents je dobre znamy (sam se analyzuje)
3. Redmine podpora je jiz implementovana v v6.x (trackers.md, MCP config, example config)
4. Zadne externi zavislosti — vsechny informace jsou v repu

## Kontext codebase

### Relevantni soubory
- `docs/plans/readmine-project/` — 8 analyzovanych dokumentu + orasetup/
- `docs/reference/trackers.md` — Redmine podpora (query syntax, state transitions, MCP detection)
- `examples/configs/redmine-rails.md` — Sablona Automation Config pro Redmine
- `examples/mcp-configs/redmine.json` — MCP server konfigurace
- `agents/` — 19 agentnich definic (triage-analyst, fixer, reviewer, atd.)
- `skills/` — 26 skills (fix-bugs, implement-feature, scaffold, atd.)
- `core/` — 11 sdilenych kontraktnich modulu
- `CLAUDE.md` — Hlavni dokumentace pluginu vcetne Automation Config kontraktu

### Klicove aspekty pro analyzu
1. **Redmine podpora:** Jiz existuje — query syntax, state transitions, MCP detection, example config
2. **Oracle PL/SQL:** Neni primo podporovan jako tech-stack sablona; existuje obecny `/template` skill
3. **Postupna adopce:** Pipeline Profiles umoznuji skip stages, ale cela orchestrace je still all-or-nothing (skill -> pipeline)
4. **2-urovnova hierarchie:** Decomposition v ceos-agents podporuje subtasky, ale defaultne mohou byt hlubsi nez 2 urovne
5. **Oddeleni agent/process:** Navrh z agent-process-separation.md neni implementovan — soucasny stav je monoliticky
6. **Custom fields Redmine:** assignee_type, context_file, agent_session_id — ceos-agents je nema v Automation Config

## Bezpecnostni vyhodnoceni (fast-track eligibilita)

**Fast-track:** NE — neuplatnuje se

Duvod: Typ ukolu je "research/design", ne implementace. Fast-track je urcen pro trivialni code changes. Analyticke ukoly prochazi fazi 0-3 (research pipeline), ne faze 6-9 (implementacni pipeline).

## Doporuceny routing

- **Faze 0:** Meta-analyza (tento dokument)
- **Faze 1:** Vyzkumne otazky — systematicka dekompozice problemu na konkretni otazky
- **Faze 2:** Odpovedi na vyzkumne otazky — grepping/cteni relevantniho kodu
- **Faze 3:** Brainstorm synteza — consolidace nalezu do gap-analyzy a doporuceni
- **Faze 4:** (volitelne) Specifikace — formalni strukturovany vystup gap-analyzy
- **Faze 5-9:** Preskocit — zadna implementace

## Zavislosti a rizika

| Riziko | Pravdepodobnost | Mitigace |
|--------|-----------------|----------|
| Neuplna znalost Redmine MCP serveru | Nizka | Existuji examples/ a docs/reference/trackers.md |
| Neporozumeni pozadavkum Milana Martaka | Stredni | 3 dokumenty s pozadavky se navzajem doplnuji; pouzit vsechny |
| Overscoping analyzy | Stredni | Drzet se 4 otazek ze zadani, nekombinovat s architektonickym navrhem |
