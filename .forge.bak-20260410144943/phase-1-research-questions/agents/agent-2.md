# Agent 2 — Výzkumné otázky
## Fokus: mezery v podpoře a proveditelnost postupné adopce

**Datum:** 2026-04-10
**Agent:** Research Agent 2
**Verze pluginu:** v6.4.1

---

## Oblast 2A: Workflow gaps — Redmine workflow vs. ceos-agents state transitions

### RQ-2A-1: Chybí podpora pro stav „Ready" jako vstupní checkpoint agenta

**Soubor:** `skills/fix-ticket/SKILL.md` (krok 1), `skills/implement-feature/SKILL.md` (krok 1)

Automation Config obsahuje klíč `On start set`, který při spuštění pipeline přechodí ticket do stavu „In Progress". Zákazník požaduje, aby agent odebíral tasky **pouze ze stavu „Ready"** (viz `docs/plans/readmine-project/1  ACT-A-1.md` — `In Review` vždy projde člověkem, agent si vybírá pouze ze stavů Ready). Otázka: Umožňuje `Bug query` v Automation Config filtrovat výhradně na stav `Ready`? A pokud ano — validuje ceos-agents, že přechod `Ready → In Progress` je konzistentní s Redmine permission modelem pro daný projekt?

**Dílčí otázka:** `State transitions` podporuje pouze čtyři předdefinované klíče: `In Progress`, `Blocked`, `For Review`, `Done` (viz `skills/onboard/SKILL.md` krok 6). Pro Redmine workflow `New → Ready → In Progress → In Review → Closed` chybí klíč `Ready`. Jak plugin nakládá s přechodem `New → Ready`? Tuto transformaci (lidský checkpoint před předáním agentovi) plugin vůbec nemodeluje — jde o slepou skvrnu v kontraktu?

---

### RQ-2A-2: Přechod „In Review" — human gate nebo automatický?

**Soubory:** `skills/publish/SKILL.md` (krok 6), `skills/fix-ticket/SKILL.md` (krok po publisher), `skills/implement-feature/SKILL.md` (krok 6 publish)

Publisher nastaví stav dle `State transitions → For Review`. Zákazník specifikuje, že `In Review` vždy projde **člověkem** (viz `docs/plans/readmine-project/1  ACT-A-1.md`). Otázka: Je možné konfigurovat pipeline tak, aby po přechodu do `In Review` (For Review) pipeline **zastavila a čekala na lidský vstup** — bez manuálního zásahu do kódu pluginu? Nebo musí lidský reviewer ručně spustit další krok? Aktuálně pipeline po publisheru pokračuje automaticky bez mechanismu čekání na schválení.

---

### RQ-2A-3: Mapování `agent_session_id` custom fieldu zpět do Redmine

**Soubor:** `core/state-manager.md`, `agents/triage-analyst.md`, `agents/publisher.md`

Zákazník definuje custom field `agent_session_id` (UUID Claude Code session) pro dohledatelnost (viz `docs/plans/readmine-project/1  ACT-A-1.md`). Stav běhu je uložen v `.ceos-agents/{RUN-ID}/state.json` a zahrnuje `run_id`. Otázka: Existuje v pipeline mechanismus pro zpětný zápis `run_id` / session ID do Redmine custom fieldu `agent_session_id`? Pokud ne — jde o ruční koordinaci, nebo je to gap, který vyžaduje nový hook / publisher krok?

---

### RQ-2A-4: Zpětný zápis `context_file` custom fieldu

**Soubor:** `agents/triage-analyst.md` (Process krok 1), `docs/plans/readmine-project/1  ACT-A-1.md`

Zákazník definuje custom field `context_file` — cesta k `CONTEXT.md` v repozitáři, který agent přečte před zahájením práce. Triage-analyst čte issue z trackeru (krok 1), ale interface nezmiňuje čtení custom fieldů nad rámec standardních polí (summary, description, comments, attachments). Otázka: Čte triage-analyst automaticky custom fieldy z Redmine? Nebo musí být `context_file` explicitně přítomen v popisu ticketu, aby ho agent zpracoval? A pokud custom field existuje — umí jej publisher zpětně zapsat (např. `agent_session_id`)?

---

## Oblast 2B: Hierarchy constraints — 2-úrovňová hierarchie a NEEDS_DECOMPOSITION

### RQ-2B-1: Lze omezit hloubku dekompozice architect agenta na 1 úroveň (pouze subtasky)?

**Soubory:** `agents/architect.md` (Process krok 7–8), `core/decomposition-heuristics.md`

Architect agent generuje task tree se subtasky (`sub-1`, `sub-2`, …), ale tyto subtasky nemají sub-subtasky — jsou plochá struktura s `depends_on` vazbami. Maximum je konfigurováno jako `Max subtasks` v Automation Config (default: 7, viz `agents/architect.md` Constraints). Zákazník požaduje Epic → Task bez Stories jako mezistupně. Otázka: Je struktura task tree v architektu **vždy jednourovňová** (parent issue → seznam subtasků bez vnořování)? Nebo může `depends_on` graf implicitně vytvářet víceúrovňovou hierarchii v issue trackeru při vytváření subtasků přes `Create tracker subtasks: enabled`?

---

### RQ-2B-2: Co se stane při NEEDS_DECOMPOSITION v kontextu 2-úrovňové hierarchie?

**Soubory:** `core/fixer-reviewer-loop.md` (krok 3), `core/decomposition-heuristics.md`, `skills/fix-ticket/SKILL.md` (krok 4b), `docs/plans/readmine-project/1  ACT-A-1.md`

Fixer může signalizovat `NEEDS_DECOMPOSITION` (max 1× per ticket). Pokud k tomu dojde, pipeline spustí architect agenta, který vytvoří subtasky v trackeru. V zákazníkově modelu je Epic kontejner pro atomické Tasky — zákazník explicitně odmítá víceúrovňové stromy. Otázka: Pokud `NEEDS_DECOMPOSITION` nastane pro ticket, který je sám subtaskem (Task pod Epicem), vytvoří plugin sub-subtasky v Redmine — čímž by porušil zákazníkovu 2-úrovňovou hierarchii? Jak to pipeline řeší?

---

### RQ-2B-3: Lze konfigurací zakázat NEEDS_DECOMPOSITION nebo omezit max. úroveň vnořování?

**Soubory:** `core/decomposition-heuristics.md`, `skills/implement-feature/SKILL.md` (flag `--no-decompose`), `CLAUDE.md` (Config Contract — Decomposition sekce)

Flag `--no-decompose` / `DISABLED` zabrání dekompozici pro daný běh. Otázka: Existuje globální konfigurace pro **trvalé** zakázání NEEDS_DECOMPOSITION signálu na úrovni projektu — tak, aby nebylo nutné přidávat `--no-decompose` ke každému volání? Stávající `Decomposition` sekce v Automation Config obsahuje `Max subtasks`, `Fail strategy`, `Commit strategy`, `Create tracker subtasks` — ale ne přepínač pro úplné zakázání vnořování.

---

## Oblast 2C: Gradual adoption — postupné nasazování agentů

### RQ-2C-1: Lze spustit jednotlivého agenta samostatně, mimo pipeline?

**Soubory:** `CLAUDE.md` (Agent Definition Format), `agents/triage-analyst.md`, `agents/code-analyst.md`

Každý agent má definici v `agents/*.md` s frontmatter `name`, `description`, `model`, `style`. Agenti jsou spouštěni přes Claude Code's Task tool. Zákazník (viz `docs/plans/readmine-project/zadani.md`) požaduje „orchestrace bude muset vzniknout samostatně od agentů" a schopnost „nasazovat agenty postupně". Otázka: Lze volat agenta (např. `triage-analyst`) přímo jako `/ceos-agents:triage-analyst <ISSUE-ID>` — bez spuštění celé fix-ticket pipeline? Nebo jsou agenti vždy orchestrováni přes skill a nemají vlastní invocable entry point?

---

### RQ-2C-2: Jsou Pipeline Profiles dostatečné pro provoz s minimální sadou agentů?

**Soubory:** `core/profile-parser.md`, `skills/fix-ticket/SKILL.md` (Pipeline profile parsing sekce), `skills/implement-feature/SKILL.md` (Pipeline profile parsing sekce)

Profile-parser umožňuje přeskočit: `triage`, `code-analyst`, `spec-analyst`, `test-engineer`, `e2e-test-engineer`, `reproducer`, `browser-verifier`. Nelze přeskočit: `fixer`, `reviewer`, `publisher` (viz `core/profile-parser.md` krok 5). Otázka: Pro zákazníkovu minimální konfiguraci „planning + dev + test" bez celého CI/CD pipeline — lze vytvořit profil, který spustí **pouze** triage + fixer + reviewer a zastaví před publisherem? Publisher je jako mandatory stage neumožňuje skip — blokuje to scénář, kdy zákazník chce jen generovat kód bez PR?

---

### RQ-2C-3: Funguje Redmine integrace v současné verzi bez konfigurace?

**Soubory:** `docs/reference/trackers.md` (pokud existuje), `skills/onboard/SKILL.md` (krok 6–7), `agents/triage-analyst.md` (Process krok 1)

Triage-analyst čte `Type` z Automation Config a volí příslušný MCP server (default: youtrack). Zákazník používá Redmine na `redmine.test.ceosdata.com` (viz `docs/plans/readmine-project/zadani - projektu.md`). Otázka: Jaký MCP server je potřebný pro Redmine integraci? Existuje pro Redmine odpovídající MCP konfigurace v `/ceos-agents:init` nebo v `docs/reference/trackers.md`? Je Redmine podpora rovnocenná YouTracku, nebo má omezení (např. chybí podpora pro custom fieldy `assignee_type`, `context_file`, `agent_session_id`)?

---

### RQ-2C-4: Lze přidat custom logiku pro Redmine-specifický query bez forku pluginu?

**Soubory:** `CLAUDE.md` (Config Contract — Issue Tracker sekce), `skills/fix-bugs/SKILL.md` (Bug query sekce), `docs/plans/readmine-project/1  ACT-A-1.md`

Zákazník definuje 3 předpřipravené dotazy pro agenty: (1) `Ready + assignee_type=agent`, (2) `In Progress + agent_session_id={current}`, (3) `In Review s mými commity`. Automation Config obsahuje `Bug query` jako textové pole — zápis query je předán MCP serveru. Otázka: Lze `Bug query` napsat tak, aby filtroval na custom field `assignee_type=agent` v Redmine — nebo je query syntax omezena na standardní Redmine filtry? Pokud MCP server Redmine nepodporuje custom field filtry, jak zákazník dosáhne agent-only fronty?

---

## Oblast 2D: Observability a FinOps — sledování nákladů a telemetrie

### RQ-2D-1: Je dostupná skutečná spotřeba tokenů per agent/pipeline, nebo jen odhad?

**Soubory:** `skills/metrics/SKILL.md` (krok 6), `skills/estimate/SKILL.md`

Skill `/metrics` počítá token cost jako **odhad**: `stages × model tokens (sonnet ~30k, opus ~50k, haiku ~5k per invocation)`. Nejde o skutečnou spotřebu načtenou z Claude API — jde o hrubou heuristiku. Zákazník požaduje FinOps na úrovni per-agent/per-workflow. Otázka: Ukládá pipeline skutečnou spotřebu tokenů do `state.json` nebo `pipeline.log`? Nebo je jediný dostupný zdroj odhad v `/metrics`? Co by bylo potřeba přidat pro skutečné cost attribution per ticket a per agent?

---

### RQ-2D-2: Existuje real-time observabilita pipeline (ne pouze post-hoc report)?

**Soubory:** `skills/metrics/SKILL.md`, `skills/dashboard/SKILL.md`, `core/state-manager.md`

Dashboard skill generuje HTML dashboard, metrics skill generuje post-hoc report. `pipeline.log` ukládá eventy ve JSONL formátu (viz `core/state-manager.md` krok 5). Zákazník potřebuje přehled o stavu pipeline — zejména při postupném nasazování, kdy chce vidět „co mám teď otevřeného" (viz `docs/plans/readmine-project/1  ACT-A-1.md`). Otázka: Je `pipeline.log` exportovatelný / streamovatelný do externího nástroje (Grafana, ELK, vlastní dashboard) v reálném čase? Nebo je aktuálně dostupná pouze synchronní analýza přes `/dashboard` a `/metrics`?

---

### RQ-2D-3: Chybí hard cost ceiling — blokační riziko pro zákazníka

**Soubory:** `skills/estimate/SKILL.md`, `CLAUDE.md` (Retry Limits sekce), `docs/plans/readmine-project/ceos-agents-review-report.md` (sekce 4.2)

Review report (sekce 4.2) identifikuje jako kritický problém: „Plugin má `estimate` skill pro pre-run odhad, ale neexistuje hard cost ceiling, který by zastavil runaway pipeline." Zákazník předvádí ceos-agents app týmu (viz `zadani - projektu.md`) — nekontrolovatelné náklady by mohly narušit důvěru. Otázka: Existuje v konfiguraci (Retry Limits nebo Error Handling sekce) mechanismus pro zastavení pipeline po překročení odhadu tokenů? Nebo je maximální ochranou pouze konfigurace `Fixer iterations`, `Test attempts`, `Build retries` — která omezuje počet pokusů, ale ne absolutní náklady?

---

### RQ-2D-4: Jak je sledováno přiřazení práce (`assignee_type`) pro FinOps reporting?

**Soubory:** `core/state-manager.md` (state schema), `skills/metrics/SKILL.md` (krok 5 per-agent), `docs/plans/readmine-project/1  ACT-A-1.md`

Zákazník definuje `assignee_type` jako hlavní filtr pro agent queue (`agent | human | both`). Metriky v `/metrics` počítají per-agent efektivitu (triage-analyst, code-analyst, fixer, …). Otázka: Zahrnuje `state.json` nebo `pipeline.log` informaci o tom, který konkrétní ticket měl `assignee_type=agent` vs. `human` — tak aby bylo možné v reporting vrstvě rozlišit lidský vs. agentní čas a náklady? Nebo tato dimenze v aktuálním datovém modelu neexistuje?

---

## Souhrnná mapa mezer (pro Phase 2)

| Oblast | Závažnost | Typ mezery |
|--------|-----------|------------|
| 2A-1: Stav „Ready" jako entry point | Vysoká | Chybějící konfigurační klíč |
| 2A-2: Lidský gate po „In Review" | Vysoká | Chybějící wait/pause mechanismus |
| 2A-3: agent_session_id writeback | Střední | Chybějící publisher krok |
| 2A-4: Čtení custom fieldů | Střední | Nejasná MCP podpora |
| 2B-1: 1-úrovňová task tree | Nízká | Pravděpodobně OK, nutno ověřit |
| 2B-2: NEEDS_DECOMPOSITION v subtasku | Vysoká | Potenciální porušení hierarchie |
| 2B-3: Globální zákaz dekompozice | Střední | Chybějící config klíč |
| 2C-1: Standalone agent invocability | Vysoká | Architektonická otázka |
| 2C-2: Pipeline bez publisheru | Střední | Publisher je mandatory — nelze skip |
| 2C-3: Redmine MCP dostupnost | Vysoká | Operační prerekvizita |
| 2C-4: Custom field filtry v query | Střední | MCP capability gap |
| 2D-1: Skutečná spotřeba tokenů | Vysoká | Pouze odhad, ne real data |
| 2D-2: Real-time observabilita | Střední | Pouze post-hoc |
| 2D-3: Hard cost ceiling | Vysoká | Chybí zcela |
| 2D-4: assignee_type v metrikách | Nízká | Datový model gap |
