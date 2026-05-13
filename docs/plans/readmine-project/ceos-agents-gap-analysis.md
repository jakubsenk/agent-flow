# Gap Analýza: ceos-agents v6.4.1 pro projekt SK kompenzace

> **Datum:** 2026-04-10
> **Autor:** Filip Sabacky (ceos-agents), syntéza z analýzy 8 vstupních dokumentů
> **Verze pluginu:** 6.4.1
> **Cílový projekt:** SK kompenzace (Oracle PL/SQL, Redmine)
> **Klasifikace:** Interní -- pro CEO prezentaci

---

## 1. Manažerské shrnutí

Plugin **ceos-agents** je deklarativní automatizační systém pro Claude Code, který orchestruje 19 specializovaných AI agentů přes 26 skills (příkazů) v definovaných pipeline. Pokrývá celý životní cyklus od triáže přes implementaci, review, testování až po publikaci PR.

Pro projekt **SK kompenzace** (Oracle PL/SQL engine v Redmine) je plugin **podmíněně vhodný**. Redmine integrace, build/test agnosticita a Agent Override mechanismus umožňují nasazení bez změn v definicích agentů. Hlavní omezení jsou v oblasti observability nákladů (token tracking je heuristický s přesností +-50 %) a chybějícího tvrdého cost ceilingu. Pipeline je optimalizovaná pro XS/S bugy a jednoduché features -- u komplexních Oracle modulů s křížovými závislostmi bude nutná lidská kontrola.

Konzervativní odhad: **70--90 % úspěšnost na XS/S ticketech**, **$7--26 za ticket**, **15 min od ticketu k PR** v optimálním případě. Doporučujeme CEO prezentaci zakládat na předem ověřených výsledcích, nikoliv na živé ukázce.

---

## 2. Matice kompatibility

| Oblast | Status | Komentář |
|--------|--------|----------|
| Redmine integrace | ✅ | MCP server `mcp-server-redmine` nativně podporován (`core/mcp-detection.md`, řádek 28). Query, state transitions, sub-issues, resume-ticket. |
| Build & Test | ✅ | Plně agnostické shell stringy v Automation Config. Exit kód je primární signál (`agents/fixer.md`, řádek 46--48). `bash db/scripts/deploy.sh` a `bash db/scripts/test.sh` přímo použitelné. |
| Oracle PL/SQL | ⚠️ | Fixer (opus) zvládne PL/SQL syntaxi i konvence definované v CLAUDE.md. Vyžaduje Agent Override pro Oracle-specifické konvence (`.pks`/`.pkb` pořadí, utPLSQL anotace, Flyway migrace). |
| Pipeline profily | ✅ | Přeskočení nepotřebných fází (browser-verifier, e2e, reproducer) přes `--profile` flag (`core/profile-parser.md`). Pro Oracle backend projekt ideální. |
| Decomposition | ⚠️ | Jednourovňový DAG max 7 subtasků (`agents/architect.md`, řádek 96) vyhovuje 2-úrovňové hierarchii Epic->Task. NEEDS_DECOMPOSITION v subtask loop nemá handling -- doporučeno nepoužívat na začátku. |
| Observabilita | ⚠️ | `/ceos-agents:estimate` poskytuje heuristický odhad +-50 % (`skills/estimate/SKILL.md`, řádek 101). `/ceos-agents:metrics` a `/ceos-agents:dashboard` dostupné. Chybí real-time token metering. |
| Cost management | ❌ | Žádný hard cost ceiling. Proxy: retry limity (5 fixer iterací, 3 test pokusů, 3 build retries). Opus model v fixer+reviewer loop je hlavní nákladová položka (~$15/MTok input, ~$75/MTok output). |
| Postupná adopce | ✅ | `/ceos-agents:analyze-bug` jako standalone entry point. Pipeline profily umožňují přeskočit fáze. Agent Overrides per projekt bez forku pluginu (`core/agent-override-injector.md`). |

---

## 3. Detail: Co funguje

### 3.1 Redmine integrace

Plugin nativně podporuje Redmine jako issue tracker typ. MCP pre-flight check (`core/mcp-preflight.md`) automaticky ověří dostupnost `mcp__redmine__*` nástrojů před spuštěním pipeline. Triage-analyst čte typ trackeru z Automation Config a používá odpovídající MCP server (`agents/triage-analyst.md`, řádek 20). Publisher aktualizuje stav ticketu v Redmine po vytvoření PR (`agents/publisher.md`, řádek 67).

**Referenční soubory:**
- `core/mcp-detection.md` -- tabulka mapování Redmine -> `mcp-server-redmine` -> `mcp__redmine__*`
- `core/mcp-preflight.md` -- validace connectivity před pipeline
- `skills/resume-ticket/SKILL.md` -- detekce `[ceos-agents]` komentářů pro checkpoint recovery

### 3.2 Build & Test agnosticita

Automation Config definuje `Build command` a `Test command` jako libovolné shell stringy. Fixer agent spouští build command a vyhodnocuje pouze exit kód (`agents/fixer.md`, řádky 46--48). Test-engineer spouští test command a parsuje výstup (`agents/test-engineer.md`, řádky 22--23).

Pro Oracle projekt: `bash db/scripts/deploy.sh` (Flyway migrace + kompilace + validace) jako build command a `bash db/scripts/test.sh` (utPLSQL) jako test command.

### 3.3 Agent Override mechanismus

Soubor `core/agent-override-injector.md` definuje mechanismus injektáže project-specific instrukcí. Pro každého agenta (fixer, reviewer, test-engineer) lze vytvořit `{path}/{agent-name}.md`, jehož obsah se připojí jako `## Project-Specific Instructions`. Toto umožňuje naučit agenty Oracle PL/SQL konvencím bez modifikace plugin kódu.

### 3.4 Pipeline profily

`core/profile-parser.md` umožňuje deklarativně přeskočit fáze: `triage`, `code-analyst`, `spec-analyst`, `test-engineer`, `e2e-test-engineer`, `reproducer`, `browser-verifier`. Mandatorní fáze (fixer, reviewer, publisher) přeskočit nelze. Pro Oracle backend projekt profil `oracle-backend` s přeskočením `reproducer`, `browser-verifier`, `e2e-test-engineer` eliminuje irelevantní UI fáze.

### 3.5 Acceptance Criteria driven pipeline

Triage-analyst extrahuje 2--5 testovatelných AC z bug reportu (`agents/triage-analyst.md`, řádky 56--60). Reviewer ověřuje AC fulfillment per criterion (`agents/reviewer.md`, řádky 37--41). Acceptance-gate agent provádí finální verifikaci s kódovým důkazem (`agents/acceptance-gate.md`). Toto je klíčové pro formální verifikovatelnost výstupů směrem k APP týmu.

---

## 4. Detail: Identifikované mezery

### 4.1 Token tracking a cost management

| Atribut | Hodnota |
|---------|---------|
| **Popis** | `/ceos-agents:estimate` poskytuje heuristický odhad na základě per-stage tabulky (`skills/estimate/SKILL.md`, řádky 47--56). Přesnost +-50 %. Neexistuje runtime metering ani hard cost ceiling. |
| **Závažnost** | VYSOKÁ |
| **Workaround** | Retry limity jako proxy ceiling (Automation Config -> Retry Limits). Fixer iterations = 3 (místo default 5), Test attempts = 2, Build retries = 2. Před spuštěním vždy `/ceos-agents:estimate`. |
| **Dopad na projekt** | Riziko nekontrolovaných nákladů při opus fixer-reviewer loop na komplexních Oracle modulech. Při 5 iteracích fixer-reviewer s opus: odhad $15--26 za ticket. |

### 4.2 Status name-to-ID mapování v Redmine

| Atribut | Hodnota |
|---------|---------|
| **Popis** | Publisher agent nastavuje stav ticketu stringem (např. "In Review"). Redmine API vyžaduje status_id. Mapování závisí na LLM interpretaci -- MCP server `mcp-server-redmine` toto typicky řeší, ale závisí na jeho implementaci. |
| **Závažnost** | STŘEDNÍ |
| **Workaround** | Agent Override pro publisher s explicitním mapováním: `New = 1, In Progress = 2, Resolved = 3, Feedback = 4`. Ověřit na instanci `redmine.test.ceosdata.com`. |
| **Dopad na projekt** | Pokud MCP server nepodporuje name-based lookup, publisher bude blokovat. Ověřitelné v pilot fázi. |

### 4.3 NEEDS_DECOMPOSITION v subtask loop

| Atribut | Hodnota |
|---------|---------|
| **Popis** | Fixer agent může signalizovat NEEDS_DECOMPOSITION max 1x za ticket (`agents/fixer.md`, řádek 78). V subtask loop (po architect decomposition) chybí handling tohoto signálu -- subtask by zůstal zablokovaný. |
| **Závažnost** | NÍZKÁ (pro počáteční nasazení) |
| **Workaround** | Nepoužívat `--decompose` flag na začátku. Pracovat s XS/S tickety, kde decomposition není potřeba. Flag `--no-decompose` explicitně vypne decomposition. |
| **Dopad na projekt** | Omezení na jednoduché tickety v první fázi. Pro L/XL features bude nutná manuální dekompozice do Redmine sub-issues. |

### 4.4 Standalone agent invocability

| Atribut | Hodnota |
|---------|---------|
| **Popis** | Agenti nejsou přímo volatelní mimo pipeline. Jediný standalone entry point je `/ceos-agents:analyze-bug`. Pro postupnou adopci (agent vedle člověka) chybí možnost volat jednotlivé agenty izolovaně. |
| **Závažnost** | STŘEDNÍ |
| **Workaround** | `/ceos-agents:analyze-bug` pro analýzu. Pro fix: `/ceos-agents:fix-ticket` s `--dry-run` pro analýzu, poté plný běh. `/ceos-agents:discuss` pro multi-agent diskuzi. |
| **Dopad na projekt** | Počáteční adopce vyžaduje spuštění minimálně analyze-bug nebo fix-ticket. Nelze volat samostatně jen fixer nebo jen reviewer. |

### 4.5 Oracle-specifická znalost agentů

| Atribut | Hodnota |
|---------|---------|
| **Popis** | Žádný agent nemá nativní Oracle PL/SQL znalost. Fixer (opus) zvládne PL/SQL syntaxi z obecného tréninku, ale nezná specifika projektu (`.pks`/`.pkb` pořadí, utPLSQL anotace, Flyway konvence, `PRAGMA EXCEPTION_INIT`). |
| **Závažnost** | STŘEDNÍ |
| **Workaround** | Agent Override soubory `customization/fixer.md` a `customization/test-engineer.md` s Oracle-specifickými instrukcemi (viz Přílohy A, B). CLAUDE.md projektu s kompletními konvencemi (existující `orasetup/CLAUDE.md` jako základ). |
| **Dopad na projekt** | Bez Agent Overrides: fixer může generovat syntakticky správný ale konvenčně nesprávný kód. S Agent Overrides: kvalita srovnatelná s informovaným vývojářem. |

---

## 5. Navržený Automation Config

Následující konfigurace je připravena ke zkopírování do `CLAUDE.md` projektu SK kompenzace. Hodnoty označené `<!-- TODO: ověřit -->` vyžadují validaci na Redmine instanci.

```markdown
## Automation Config

### Issue Tracker

| Key | Value |
|-----|-------|
| Type | redmine |
| Instance | https://redmine.test.ceosdata.com |
| Project | ai-dev |
| Bug query | status_id=open&assigned_to_id=me&tracker_id=1 |
| State transitions | New->In Progress, In Progress->Resolved, Resolved->Closed |
| On start set | In Progress |

### Source Control

| Key | Value |
|-----|-------|
| Remote | fsabacky/drmax-readmine-test |
| Base branch | main |
| Branch naming | fix/{issue-id}-{short-description} |

### PR Rules

| Key | Value |
|-----|-------|
| Labels | ai-generated |

### PR Description Template

```
## Summary
{summary}

## Root Cause
{root_cause}

## Changes
{changes}

## Testing
- Build: {build_result}
- Unit tests (utPLSQL): {test_result}

## Redmine Issue
{issue_link}
```

### Build & Test

| Key | Value |
|-----|-------|
| Build command | bash db/scripts/deploy.sh |
| Test command | bash db/scripts/test.sh |

### Retry Limits

| Key | Value |
|-----|-------|
| Fixer iterations | 3 |
| Test attempts | 2 |
| Build retries | 2 |
| Spec iterations | 3 |
| Root cause iterations | 2 |

### Pipeline Profiles

| Profile | Skip stages | Extra stages |
|---------|-------------|--------------|
| oracle-backend | reproducer, browser-verifier, e2e-test-engineer | |

### Agent Overrides

| Key | Value |
|-----|-------|
| Path | customization/ |

### Error Handling

| Key | Value |
|-----|-------|
| On block | comment |
| Max blocked per run | 3 |

### Decomposition

| Key | Value |
|-----|-------|
| Max subtasks | 5 |
| Fail strategy | fail-fast |
| Commit strategy | squash |
| Create tracker subtasks | disabled |
```

**Poznámky k ověření na Redmine instanci:**

1. `Bug query` -- ověřit `tracker_id=1` odpovídá trackeru "Bug" v projektu ai-dev. Zkontrolovat přes `GET /projects/ai-dev/trackers.json`.
2. `State transitions` -- ověřit názvy stavů odpovídají konfiguraci workflow v Redmine. Zkontrolovat přes `GET /issue_statuses.json`.
3. `assigned_to_id=me` -- ověřit, že MCP server `mcp-server-redmine` podporuje `me` alias. Alternativa: explicitní user ID.
4. `Labels` -- Redmine nativně nepodporuje PR labels jako GitHub/Gitea. Ověřit, zda publisher agent korektně handluje absenci label API. Případně odstranit Labels řádek.
5. `Remote` -- ověřit formát owner/repo odpovídá Gitea instanci (pokud SC je Gitea) nebo jiné SC platformě.

---

## 6. Potřebné soubory pro projekt

| Soubor | Účel | Kde vytvořit | Kdo odpovídá |
|--------|------|--------------|--------------|
| `CLAUDE.md` | Hlavní konfigurace projektu + Automation Config (sekce 5 výše) + Oracle PL/SQL konvence (z `orasetup/CLAUDE.md`) | `C:\gitea_drmax-readmine-test\CLAUDE.md` | Filip Sabacky |
| `customization/fixer.md` | Agent Override: Oracle PL/SQL instrukce pro fixer agenta | `C:\gitea_drmax-readmine-test\customization\fixer.md` | Filip Sabacky |
| `customization/test-engineer.md` | Agent Override: utPLSQL instrukce pro test-engineer agenta | `C:\gitea_drmax-readmine-test\customization\test-engineer.md` | Filip Sabacky |
| `.env` | DB connection variables (DB_DSN, DB_USER, DB_PASS, DB_URL) | `C:\gitea_drmax-readmine-test\.env` | Milan Marťák (infra) |
| `flyway.conf` | Flyway migrace konfigurace | `C:\gitea_drmax-readmine-test\flyway.conf` | Milan Marťák (existuje) |

---

## 7. Potřebné změny v pluginu

| Soubor | Typ změny | Priorita | Verze |
|--------|-----------|----------|-------|
| `examples/automation-config-oracle.md` | Nový soubor: šablona Automation Config pro Oracle PL/SQL stack | Nice-to-have | v6.5.0 |
| `skills/template/SKILL.md` | Rozšíření: přidat `oracle-plsql` jako rozpoznávaný stack pro `/ceos-agents:template` | Nice-to-have | v6.5.0 |
| Žádná změna v `agents/*.md` | Agent definice zůstávají beze změn | -- | -- |
| Žádná změna v `core/*.md` | Core moduly zůstávají beze změny | -- | -- |
| Žádná změna v `skills/*.md` | Skills zůstávají beze změny | -- | -- |

**Klíčový závěr:** 0 změn v agent definicích, 0 změn v core, 0 změn v skills. Veškerá Oracle-specifická konfigurace je na straně projektu (CLAUDE.md + Agent Overrides).

---

## 8. Roadmapa nasazení

### Fáze 1: Příprava prostředí (odhad: 8--12 hodin)

**Kroky:**
1. Ověřit Oracle XE 21c Docker funkčnost na cílovém stroji
2. Nainstalovat a ověřit SQLcl 26.1, Flyway 9.22.3, utPLSQL 3.1.14
3. Nakonfigurovat MCP server `mcp-server-redmine` pro Claude Code
4. Vytvořit `CLAUDE.md` s Automation Config (sekce 5)
5. Vytvořit `customization/fixer.md` a `customization/test-engineer.md` (Přílohy A, B)
6. Spustit `/ceos-agents:check-setup` pro validaci konfigurace
7. Spustit `/ceos-agents:init` pro ověření MCP connectivity

**Gate kritéria:**
- `/ceos-agents:check-setup` projde bez chyb
- `bash db/scripts/deploy.sh` vrací exit 0
- `bash db/scripts/test.sh` vrací exit 0
- MCP server `mcp-server-redmine` je dostupný a vrací issues z projektu ai-dev

### Fáze 2: Pilot na XS/S ticketech (odhad: 4--8 hodin)

**Kroky:**
1. Vytvořit 3--5 XS/S bug ticketů v Redmine s jasným popisem a AC
2. Spustit `/ceos-agents:estimate <ISSUE-ID>` pro každý ticket (ověření odhadů)
3. Spustit `/ceos-agents:fix-ticket <ISSUE-ID> --profile oracle-backend` na prvním ticketu
4. Vyhodnotit výsledek: kvalita fixu, správnost PL/SQL konvencí, utPLSQL testů
5. Iterovat Agent Overrides podle zjištění
6. Zpracovat zbývající tickety

**Gate kritéria:**
- Minimálně 2 z 5 ticketů úspěšně projdou celou pipeline (fix -> review -> test -> PR)
- Generovaný PL/SQL kód kompiluje bez INVALID objektů
- utPLSQL testy prochází
- Agent Overrides pokrývají identifikované nedostatky

### Fáze 3: Rozšířený pilot s APP týmem (odhad: 16--24 hodin)

**Kroky:**
1. Prezentace výsledků Fáze 2 zástupcům APP týmu
2. Společné vytvoření 5--10 reálných ticketů z backlogu SK kompenzace
3. Spuštění pipeline s human-in-the-loop dohledem (APP tým reviewuje PR)
4. Měření: čas od ticketu k PR, kvalita kódu, počet review iterací
5. Sběr zpětné vazby od APP týmu
6. Refinement Agent Overrides a Automation Config

**Gate kritéria:**
- Minimálně 60 % ticketů projde pipeline bez manuálního zásahu
- APP tým akceptuje kvalitu generovaného kódu jako "review-ready"
- Průměrný čas od ticketu k PR < 30 minut
- Žádný pipeline block z důvodu chybné Oracle konvence (po refinement)

### Fáze 4: Produkční adopce (odhad: průběžně)

**Kroky:**
1. Definovat SOP (Standard Operating Procedure) pro agentický vývoj v APP týmu
2. Nastavit `/ceos-agents:fix-bugs N --profile oracle-backend` jako standardní workflow
3. Monitoring přes `/ceos-agents:metrics` a `/ceos-agents:dashboard`
4. Postupné zvyšování autonomie (snížení human-in-the-loop)
5. Rozšíření na feature pipeline (`/ceos-agents:implement-feature`)

**Gate kritéria:**
- 80 %+ úspěšnost na XS/S ticketech za měsíc
- ROI > 3x (úspora času vs. náklady na API)
- APP tým aktivně používá workflow bez asistence

---

## 9. Rizika a mitigace

| Riziko | Pravděpodobnost | Dopad | Mitigace |
|--------|-----------------|-------|----------|
| Oracle Docker nestabilní / nedostatečné prostředky | STŘEDNÍ | VYSOKÝ | Předem otestovat na cílovém stroji. Oracle XE 21c vyžaduje min. 4 GB RAM. Fallback: remote DB. |
| MCP server `mcp-server-redmine` nepodporuje potřebné API operace | NÍZKÁ | VYSOKÝ | Ověřit v Fázi 1. Fallback: přímé REST API volání přes Bash v Agent Override. |
| Fixer generuje syntakticky nesprávný PL/SQL | STŘEDNÍ | STŘEDNÍ | Agent Override s explicitními konvencemi (Příloha A). Build command zachytí kompilační chyby. Retry mechanismus (max 3 pokusy). |
| Náklady na opus model překročí rozpočet | STŘEDNÍ | VYSOKÝ | Snížit retry limity (fixer iterations: 3, test attempts: 2). Před každým spuštěním `/ceos-agents:estimate`. Monitoring přes API billing dashboard. |
| CEO ukázka selže živě | VYSOKÁ (40--60 %) | VYSOKÝ | Prezentaci zakládat na hotových výsledcích z Fáze 2. Připravit 2--3 předem úspěšně zpracované tickety. Živou ukázku provádět pouze na triviálním XS ticketu. |
| APP tým odmítne adoptovat workflow | STŘEDNÍ | STŘEDNÍ | Zapojit APP tým již v Fázi 3. Zdůraznit, že agent generuje PR k review, nenahrazuje vývojáře. Postupná adopce -- začít s analyze-bug, pak fix-ticket. |
| Flyway migrace kolidují s existujícím schématem | NÍZKÁ | STŘEDNÍ | Separátní dev schéma/PDB pro agentický vývoj. Agent nikdy nemigruje produkci. |
| Token context window overflow na rozsáhlém PL/SQL | NÍZKÁ | STŘEDNÍ | Code-analyst omezuje na max 5 affected files. Pipeline profil přeskakuje zbytečné fáze. Pro L tickety manuální dekompozice. |

---

## 10. CEO prezentace -- doporučení

### Co ukázat

1. **Předem zpracovaný XS bug (živě hotový výsledek):** Redmine ticket -> PR s fixem, testy, traceability komentáři. Projít výstup triage-analyst (AC, complexity), code-analyst (impact report), fixer (fix report), reviewer (review s AC fulfillment), test-engineer (test report), publisher (PR).
2. **Čísla z pilotu (Fáze 2):** Konkrétní metriky -- počet zpracovaných ticketů, úspěšnost, průměrný čas, náklady na ticket.
3. **Automation Config:** Ukázat, že veškerá projekt-specifická konfigurace je v jednom souboru (CLAUDE.md). Nulové změny v pluginu.
4. **Srovnání:** Čas manuálního zpracování ticketu vs. agentické zpracování. Konzervativní odhad: 15 min (agent) vs. 2--4 hodiny (člověk) pro XS/S bug.

### Co neukázat

1. **Živou pipeline na neznámém ticketu** -- 40--60 % pravděpodobnost selhání v reálném čase. Opus fixer-reviewer loop může trvat 5--15 minut.
2. **Decomposition na L ticketech** -- NEEDS_DECOMPOSITION handling v subtask loop není kompletní.
3. **Cost management dashboard** -- real-time token tracking neexistuje, pouze heuristiky.
4. **Feature pipeline** -- pro prvotní prezentaci příliš komplexní. Zaměřit se na bug-fix pipeline.

### Klíčová čísla pro CEO

| Metrika | Konzervativní odhad | Optimistický odhad |
|---------|--------------------|--------------------|
| Úspěšnost na XS/S bugech | 70 % | 90 % |
| Čas od ticketu k PR | 15--30 min | 10--15 min |
| Náklady na ticket | $7--26 | $5--12 |
| ROI za 3 měsíce | 3x | 8x |
| Setup time (jednorázový) | 31 hodin | 16 hodin |

### Fallback plán

Pokud pilot (Fáze 2) ukáže < 50 % úspěšnost:
1. Přejít na hybridní režim: `/ceos-agents:analyze-bug` pro analýzu + manuální fix
2. Zaměřit se na hodnotu triage-analyst (AC extrakce, complexity odhad) a code-analyst (impact analýza) -- tyto fáze fungují nezávisle na technologickém stacku
3. Prezentovat jako "AI-asistovaný vývoj" místo "AI-řízený vývoj"

---

## 11. Konkrétní úkoly (task list)

| # | Úkol | Odhad | Zodpovídá | Fáze |
|---|------|-------|-----------|------|
| 1 | Ověřit Oracle XE 21c Docker na cílovém stroji (4 GB RAM, port 1521) | 2h | Milan Marťák | 1 |
| 2 | Nainstalovat a nakonfigurovat `mcp-server-redmine` pro Claude Code | 2h | Filip Sabacky | 1 |
| 3 | Ověřit Redmine API: status IDs, tracker IDs, assigned_to_id=me | 1h | Filip Sabacky | 1 |
| 4 | Vytvořit `CLAUDE.md` projektu (Automation Config + Oracle konvence) | 2h | Filip Sabacky | 1 |
| 5 | Vytvořit `customization/fixer.md` (Příloha A) | 1h | Filip Sabacky | 1 |
| 6 | Vytvořit `customization/test-engineer.md` (Příloha B) | 1h | Filip Sabacky | 1 |
| 7 | Spustit `/ceos-agents:check-setup` a `/ceos-agents:init` | 0.5h | Filip Sabacky | 1 |
| 8 | Vytvořit 3--5 XS/S bug ticketů v Redmine s AC | 2h | Milan Marťák | 2 |
| 9 | Spustit `/ceos-agents:estimate` na každém ticketu | 0.5h | Filip Sabacky | 2 |
| 10 | Spustit `/ceos-agents:fix-ticket` na pilotních ticketech | 3h | Filip Sabacky | 2 |
| 11 | Vyhodnotit výsledky a iterovat Agent Overrides | 2h | Filip Sabacky | 2 |
| 12 | Připravit prezentační materiály z výsledků Fáze 2 | 3h | Filip Sabacky | 2 |
| 13 | Prezentace APP týmu + společná tvorba reálných ticketů | 4h | Milan Marťák + APP tým | 3 |
| 14 | Rozšířený pilot s human-in-the-loop | 12h | Filip Sabacky + APP tým | 3 |
| 15 | Refinement konfigurace a SOP dokument | 4h | Filip Sabacky | 3 |
| 16 | (Volitelné) Přidat `oracle-plsql` šablonu do ceos-agents pluginu | 2h | Filip Sabacky | 4 |

**Celkový odhad: 31--40 hodin** (bez Fáze 4, která je průběžná).

---

## 12. Přílohy

### Příloha A: Draft Agent Override pro fixer (`customization/fixer.md`)

```markdown
## Project-Specific Instructions

### Oracle PL/SQL konvence

Tento projekt používá Oracle PL/SQL s následujícím technologickým stackem:
- Oracle XE 21c v Docker kontejneru
- SQLcl 26.1 pro kompilaci
- Flyway 9.22.3 pro migrace (NE Flyway 10+)
- utPLSQL 3.1.14 pro unit testy

### Struktura souborů

- `.pks` = package specification (veřejné rozhraní)
- `.pkb` = package body (implementace)
- **VŽDY kompiluj spec PŘED body** -- pořadí je kritické
- Produkční kód: `db/packages/*.pks`, `db/packages/*.pkb`
- Testy: `db/tests/ut_*.pks`, `db/tests/ut_*.pkb`
- Migrace: `db/migrations/V{číslo}__{popis}.sql`

### Kódovací konvence

1. **Výjimky:** Definuj jako konstanty v package spec:
   ```sql
   e_invalid_input EXCEPTION;
   PRAGMA EXCEPTION_INIT(e_invalid_input, -20001);
   ```
   Rozsah custom error kódů: -20001 až -20999.

2. **Audit log:** Každý INSERT/UPDATE trigger MUSÍ zapisovat do tabulky `audit_log`:
   ```sql
   INSERT INTO audit_log (table_name, operation, record_id, old_values, new_values, changed_by, changed_at)
   VALUES (:table, :op, :id, :old, :new, USER, SYSTIMESTAMP);
   ```

3. **Naming konvence:**
   - Packages: `{modul}_pkg` (např. `compensation_calc_pkg`)
   - Testy: `ut_{modul}_pkg` (např. `ut_compensation_calc_pkg`)
   - Migrace: `V{N}__{stručný_popis}.sql` (dvojité podtržítko)
   - Proměnné: `l_` prefix pro lokální, `p_` prefix pro parametry, `g_` prefix pro globální
   - Konstanty: `c_` prefix (např. `c_max_retries`)
   - Kurzory: `cur_` prefix

4. **Package structure:**
   ```sql
   CREATE OR REPLACE PACKAGE {name}_pkg AS
     -- Konstanty
     -- Výjimky
     -- Typy (TYPE, RECORD, TABLE)
     -- Procedury a funkce (veřejné rozhraní)
   END {name}_pkg;
   /
   ```

5. **NIKDY nepoužívej:**
   - `DBMS_OUTPUT.PUT_LINE` v produkčním kódu (pouze v testech)
   - Implicitní kurzory pro SELECT INTO bez WHERE (riziko NO_DATA_FOUND/TOO_MANY_ROWS)
   - `WHEN OTHERS THEN NULL` -- vždy loguj nebo re-raise

### Build a test příkazy

- Build: `bash db/scripts/deploy.sh` -- provede Flyway migrace + kompilaci + validaci
- Test: `bash db/scripts/test.sh` -- spustí všechny utPLSQL testy
- Kontrola chyb: `bash db/scripts/check_errors.sh`
- Pokud build selže s ORA-00942: tabulky neexistují -- spusť nejprve Flyway migrace
- Pokud build selže s "Teams upgrade required": špatná verze Flyway (musí být 9.22.3, NE 10+)

### Flyway migrace

Pokud tvůj fix vyžaduje DDL změnu (nová tabulka, alter table, nový index):
1. Zjisti poslední číslo migrace: `ls db/migrations/ | sort -V | tail -1`
2. Vytvoř nový soubor: `db/migrations/V{N+1}__{popis}.sql`
3. Flyway baselineVersion=0 -- NIKDY neměň toto nastavení
4. Migrace MUSÍ být idempotentní kde je to možné

### Omezení diff

Oracle PL/SQL packages jsou typicky větší než kód v jiných jazycích. Pokud se blížíš 100-řádkovému limitu:
- Rozděl změnu na spec (.pks) a body (.pkb) v separátních iteracích
- Preferuj menší, atomické změny
```

### Příloha B: Draft Agent Override pro test-engineer (`customization/test-engineer.md`)

```markdown
## Project-Specific Instructions

### utPLSQL testovací konvence

Tento projekt používá utPLSQL 3.1.14 pro unit testování Oracle PL/SQL kódu.

### Struktura test package

Každý testovací package MUSÍ dodržovat:

```sql
CREATE OR REPLACE PACKAGE ut_{modul}_pkg AS
  -- %suite({Modul} Tests)
  -- %suitepath(test_app)
  -- %rollback(manual)

  -- %beforeeach
  PROCEDURE setup;

  -- %test({Popis testu})
  PROCEDURE test_{co_testujes};

  -- %test({Popis dalšího testu})
  PROCEDURE test_{dalsi_test};
END ut_{modul}_pkg;
/
```

### Setup procedura (povinná)

Každý test package MUSÍ mít `setup` proceduru anotovanou `-- %beforeeach`:

```sql
PROCEDURE setup IS
BEGIN
  DELETE FROM audit_log;
  DELETE FROM {relevantní_tabulky};
  COMMIT;
END setup;
```

Účel: zajistit čistý stav před každým testem. VŽDY includovat DELETE z audit_log.

### Assertion konvence

Používej utPLSQL assertion API:
```sql
-- Rovnost
ut.expect(l_actual).to_equal(l_expected);

-- NULL check
ut.expect(l_value).to_be_null();
ut.expect(l_value).not_to_be_null();

-- Exception test
BEGIN
  {volání_které_má_vyhodit_výjimku};
  ut.fail('Očekávaná výjimka nebyla vyhozena');
EXCEPTION
  WHEN {modul}_pkg.e_{nazev_vyjimky} THEN
    NULL; -- Očekávaná výjimka
END;

-- Počet záznamů
ut.expect(l_count).to_be_greater_than(0);
```

### Naming konvence testů

- Test package: `ut_{modul}_pkg`
- Test procedura: `test_{co_testujes}` -- stručný, popisný název
- Příklady:
  - `test_create_contact_success`
  - `test_create_contact_duplicate_raises`
  - `test_calc_compensation_zero_amount`
  - `test_audit_log_on_update`

### Soubory

- Spec: `db/tests/ut_{modul}_pkg.pks`
- Body: `db/tests/ut_{modul}_pkg.pkb`
- VŽDY vytvoř OBA soubory (spec i body)
- VŽDY kompiluj spec PŘED body

### Spuštění testů

```bash
# Všechny testy
bash db/scripts/test.sh

# Konkrétní package (pro ověření nově vytvořených testů)
source .env
echo "EXEC ut.run('ut_{modul}_pkg');" | sqlcl -S "${DB_USER}/${DB_PASS}@${DB_DSN}"
```

### Co testovat (pro Oracle PL/SQL bugy)

1. **Povinné:** Regresní test reprodukující bug (INSERT dat, volání procedury, ověření výsledku)
2. **Doporučené:** Edge case -- NULL vstup, prázdná kolekce, hraniční hodnota
3. **Volitelné:** Audit log záznam po operaci (pokud fix zahrnuje trigger/audit)

### Časté chyby

| Chyba | Příčina | Řešení |
|-------|---------|--------|
| ORA-00942 v testu | Tabulka neexistuje | Nejprve spusť `deploy.sh` (Flyway migrace) |
| ORA-00904 UT3.xxx | Chybí grant na utPLSQL typy | Viz SETUP.md -- granty na UT3 schéma |
| ORA-44001 invalid schema | Špatný suitepath formát | Použít `ut.run(':test_app')` s dvojtečkou |
| Test prochází ale neměl by | Setup procedura nesmaže data | Přidat DELETE do setup procedury |
| Package INVALID po kompilaci | Syntaktická chyba v testu | `bash db/scripts/check_errors.sh` pro detail |
```

---

> **Poznámka:** Tento dokument vychází z analýzy codebase ceos-agents v6.4.1 (19 agentů, 26 skills, 11 core modulů), 8 vstupních dokumentů v `docs/plans/readmine-project/`, a diskuzí o projektu SK kompenzace. Všechny reference na konkrétní soubory pluginu jsou ověřeny proti aktuální verzi.
