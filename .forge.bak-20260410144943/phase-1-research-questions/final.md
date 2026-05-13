# Fáze 1 — Konsolidované výzkumné otázky

**Pipeline:** forge-2026-04-10-001
**Datum:** 2026-04-10
**Agenti:** 3 (Redmine+Oracle, Gaps+adopce, Config+změny)
**Celkem otázek:** 30 → konsolidováno na 22 unikátních

---

## Oblast 1: Co ceos-agents zvládne out-of-the-box

### 1.1 Redmine integrace

| ID | Otázka | Priorita | Kde hledat |
|----|--------|----------|------------|
| Q-1A-01 | Je formát Redmine query (`tracker_id`, `status_id`) dostatečně flexibilní pro nestandardní instance? | Střední | `docs/reference/trackers.md`, `core/config-reader.md` |
| Q-1A-02 | Jak funguje překlad `status:{name}` → `status_id` — LLM hádá, nebo MCP server má API? | Kritická | `docs/reference/trackers.md`, `examples/mcp-configs/redmine.json` |
| Q-1A-03 | Podporuje `mcp-server-redmine` čtení/zápis custom fields (`assignee_type`, `context_file`, `agent_session_id`)? | Vysoká | `examples/mcp-configs/redmine.json`, `agents/triage-analyst.md` |
| Q-1A-04 | Jak pipeline vytváří sub-tasky v Redmine přes `parent_issue_id`? | Střední | `docs/reference/trackers.md`, `core/decomposition-heuristics.md` |
| Q-1A-05 | Je Automation Config agnostický vůči jazyku (Build/Test = shell string bez předpokladů)? | Vysoká | `agents/fixer.md` krok 6, `core/config-reader.md` |
| Q-1A-06 | Jak hluboce MCP preflight kontroluje Redmine (přítomnost vs. funkčnost)? | Nízká | `core/mcp-preflight.md`, `skills/fix-bugs/SKILL.md` |
| Q-1A-07 | Jak `/resume-ticket` detekuje nové komentáře v Redmine? | Nízká | `skills/resume-ticket/SKILL.md` |

### 1.2 Oracle PL/SQL kompatibilita

| ID | Otázka | Priorita | Kde hledat |
|----|--------|----------|------------|
| Q-1B-01 | Zpracovávají agenti build/test výstup pouze na exit kódu, nebo parsují formát (ORA-XXXXX)? | Vysoká | `agents/fixer.md` kroky 6-7, `agents/test-engineer.md` kroky 2, 5 |
| Q-1B-02 | Dokáže fixer generovat Oracle PL/SQL kód z CLAUDE.md konvencí bez Agent Override? | Vysoká | `agents/fixer.md` krok 2, `orasetup/CLAUDE.md` |
| Q-1B-03 | Jak test-engineer zpracuje utPLSQL dvousouborovou strukturu (.pks/.pkb) a anotace? | Střední | `agents/test-engineer.md` krok 4, `orasetup/CLAUDE.md` |
| Q-1B-04 | Koliduje constraint „no external service calls" v test-engineer s utPLSQL (volání DB)? | Vysoká | `agents/test-engineer.md` Constraints |
| Q-1B-05 | Jak pipeline řeší Oracle Docker health check (TCP 1521, ne HTTP)? | Kritická | `CLAUDE.md` Local Deployment, `agents/deployment-verifier.md` |
| Q-1B-06 | Podporuje pipeline `sudo docker` bez interaktivního hesla? | Střední | `orasetup/CLAUDE.md`, infrastrukturní prerekvizita |

---

## Oblast 2: Identifikace mezer (gaps)

### 2.1 Workflow gaps

| ID | Otázka | Priorita | Kde hledat |
|----|--------|----------|------------|
| Q-2A-01 | Chybí stav „Ready" v State transitions? (`New→Ready` je lidský checkpoint před agentem) | Vysoká | `skills/fix-ticket/SKILL.md`, `skills/onboard/SKILL.md` krok 6 |
| Q-2A-02 | Lze po „In Review" zastavit pipeline a čekat na lidský vstup? | Vysoká | `skills/publish/SKILL.md`, `agents/publisher.md` |
| Q-2A-03 | Existuje mechanismus pro zpětný zápis `agent_session_id`/`run_id` do Redmine? | Střední | `core/state-manager.md`, `agents/publisher.md` |

### 2.2 Hierarchy a decomposition

| ID | Otázka | Priorita | Kde hledat |
|----|--------|----------|------------|
| Q-2B-01 | Je task tree architekta vždy jednourovňový, nebo může vytvořit vnořování? | Střední | `agents/architect.md`, `core/decomposition-heuristics.md` |
| Q-2B-02 | Co se stane při NEEDS_DECOMPOSITION na subtasku — poruší 2-úrovňovou hierarchii? | Vysoká | `core/fixer-reviewer-loop.md`, `core/decomposition-heuristics.md` |

### 2.3 Postupná adopce

| ID | Otázka | Priorita | Kde hledat |
|----|--------|----------|------------|
| Q-2C-01 | Lze spustit jednotlivého agenta standalone mimo pipeline? | Vysoká | `CLAUDE.md` Agent Definition Format |
| Q-2C-02 | Publisher je mandatory — blokuje scénář „generuj kód bez PR"? | Střední | `core/profile-parser.md` krok 5 |

### 2.4 Observability a FinOps

| ID | Otázka | Priorita | Kde hledat |
|----|--------|----------|------------|
| Q-2D-01 | Je spotřeba tokenů skutečná (z API) nebo jen heuristický odhad? | Vysoká | `skills/metrics/SKILL.md`, `core/state-manager.md` |
| Q-2D-02 | Chybí hard cost ceiling — co chrání před runaway pipeline? | Vysoká | `skills/estimate/SKILL.md`, `CLAUDE.md` Retry Limits |

---

## Oblast 3: Automation Config pro SK kompenzace

Otázky konsolidovány do Phase 2, kde budou přímo zodpovězeny čtením kódu.

Klíčové body k ověření:
- Přesný `Project` identifikátor (`ai-dev`)
- `Build command`: `compile_all.sh` vs. `deploy.sh`
- `Test command`: `test.sh` s pre-checkem na Docker
- `Local Deployment`: nutnost vs. wrapper skript
- `Branch naming`: formát s Redmine numeric ID

---

## Oblast 4: Potřebné změny pluginu

Otázky konsolidovány do Phase 2, kde budou zodpovězeny a prioritizovány.

Klíčové hypotézy k validaci:
- **H1:** Agent Overrides (`customization/fixer.md`, `customization/test-engineer.md`) stačí pro Oracle specifika — není nutná změna `agents/`
- **H2:** Nová šablona `redmine-oracle-plsql.md` je nice-to-have, ne blocker
- **H3:** Agent-process separation NENÍ blocker pro onboarding (future enhancement)
- **H4:** Minimální změny = 1 nová šablona + Agent Overrides v projektu + wrapper skripty pro sudo

---

## Prioritizace pro Phase 2

### Kritické (zodpovědět první)
1. Q-1A-02 — Status mapping v Redmine MCP
2. Q-1B-05 — Oracle Docker health check (TCP vs HTTP)

### Vysoké (zodpovědět druhé)
3. Q-1A-03 — Custom fields podpora v MCP
4. Q-1A-05 — Build/Test agnostičnost
5. Q-1B-01 — Exit kód vs. output parsing
6. Q-1B-02 — Fixer + Oracle PL/SQL
7. Q-1B-04 — „No external service calls" kolize
8. Q-2A-01 — Stav „Ready" gap
9. Q-2A-02 — Lidský gate po In Review
10. Q-2C-01 — Standalone agent invocability
11. Q-2D-01 — Token spotřeba real vs. odhad
12. Q-2D-02 — Hard cost ceiling

### Střední/Nízké (zodpovědět pokud čas dovolí)
13-22: Zbývající otázky
