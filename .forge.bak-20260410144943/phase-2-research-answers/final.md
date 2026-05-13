# Fáze 2 — Konsolidované odpovědi na výzkumné otázky

**Pipeline:** forge-2026-04-10-001
**Datum:** 2026-04-10
**Agenti:** 3 (Out-of-box, Gaps, Config+změny)

---

## Souhrnná matice kompatibility

| Oblast | Status | Komentář |
|--------|--------|----------|
| Redmine jako tracker | PODPOROVÁNO | Query, state transitions, sub-issues, MCP config — vše existuje |
| Redmine custom fields | CHYBÍ | Plugin je neřeší; závisí na mcp-server-redmine capabilities |
| Status name→ID mapování | ČÁSTEČNĚ | LLM konvence, ne technický mechanismus — riziko na nestandardních instancích |
| Build/Test agnostičnost | PODPOROVÁNO | Shell stringy, exit kód primární signál, žádné parser předpoklady |
| Oracle PL/SQL fixer | ČÁSTEČNĚ | Opus model to zvládne + CLAUDE.md konvence; Agent Override silně doporučen |
| utPLSQL test-engineer | ČÁSTEČNĚ | Nutné vzorové testy + Agent Override pro konvence |
| Oracle Docker health check | ČÁSTEČNĚ | Vynechat Health check URL → port scan + container status |
| Stav „Ready" v workflow | CHYBÍ | 4 pevné klíče (In Progress, Blocked, For Review, Done); Ready nelze přidat |
| Lidský gate po In Review | ČÁSTEČNĚ | Pipeline zastaví před publishem, ale „In Review" se nastaví až při PR |
| Zpětný zápis session_id | CHYBÍ | Žádný mechanismus pro custom field writeback do Redmine |
| 2-úrovňová hierarchie | PODPOROVÁNO | Architect generuje jednourovňový DAG (záměrně) |
| NEEDS_DECOMPOSITION ochrana | CHYBÍ | Subtask execution loop (krok 4c) nemá handling pro tento signál |
| Standalone agent invocability | ČÁSTEČNĚ | Technicky možné přes Task tool, ale chybí granulární skills |
| Publisher skip | ČÁSTEČNĚ | Mandatory v Profile, ale interaktivně lze odmítnout |
| Skutečné token tracking | CHYBÍ | Vše jsou heuristiky (±50%), žádná reálná data z API |
| Hard cost ceiling | CHYBÍ | Neexistuje, jen nepřímé retry limity |
| Agent-process separation | NEPOTŘEBNÉ | Status „pre-decision proposal", není blocker |

---

## Detail: Co funguje out-of-the-box

### Redmine integrace (trackers.md)
- Query syntax: `project_id={P}&status_id=open&tracker_id={N}` — plně flexibilní, validátor ověřuje jen přítomnost `project_id=`
- State transitions: `status:{name}` formát — LLM konvence, funguje pro standardní stavy
- Sub-issues: `parent_issue_id` nativně podporován
- MCP config: `examples/mcp-configs/redmine.json` s `REDMINE_HOST` + `REDMINE_API_KEY`
- PR footer: `Refs #{issue_id}` pro propojení
- Resume-ticket: tracker-agnostický, funguje přes komentáře + git stav

### Build/Test
- Build command = shell string, fixer spouští přes Bash tool, hodnotí exit kód
- Test command = shell string, test-engineer čte stdout/stderr pro diagnostiku
- Oracle `deploy.sh` (Flyway + kompilace + validace) a `test.sh` (utPLSQL) fungují bez úprav
- Agenti čtou ORA-XXXXX chybové zprávy z stdout — Claude opus/sonnet to interpretuje správně

---

## Detail: Identifikované mezery

### P1: Kritické (blokující full-auto provoz)

**G1: Custom fields v Redmine (CHYBÍ)**
- `assignee_type`, `context_file`, `agent_session_id` — plugin je neřeší
- Závisí na mcp-server-redmine; triage-analyst zmiňuje „custom fields" genericky
- **Dopad:** Nelze realizovat agent-only frontu bez custom field filtru
- **Workaround:** Filtovat přes přiřazeného uživatele místo custom fieldu

**G2: Status name→ID mapování nespolehlivé (ČÁSTEČNĚ)**
- LLM hádá správné `status_id` — na nestandardních instancích může selhat
- **Dopad:** Nesprávné state transitions, tickets v nesprávném stavu
- **Workaround:** Agent Override pro triage-analyst s explicitním mapováním

**G3: NEEDS_DECOMPOSITION v subtask loop (CHYBÍ ochrana)**
- Krok 4c v fix-ticket nemá handling pro tento signál
- **Dopad:** Nekonzistentní chování, potenciální porušení 2-úrovňové hierarchie
- **Workaround:** Nastavit `Create tracker subtasks: disabled` a ručně dekomponovat

### P2: Vysoké (omezující použitelnost)

**G4: Stav „Ready" v State transitions (CHYBÍ)**
- Plugin má 4 pevné klíče; zákazník potřebuje 5. stav
- **Dopad:** Nelze modelovat checkpoint „New→Ready" před zpracováním agentem
- **Workaround:** Použít `Bug query` s filtrem na specifický Redmine stav

**G5: Skutečné token tracking (CHYBÍ)**
- Vše jsou heuristiky ±50%, žádná reálná data z Claude API
- **Dopad:** FinOps reporting neproveditelný
- **Workaround:** Externí monitoring (Anthropic API dashboard)

**G6: Hard cost ceiling (CHYBÍ)**
- Retry limity jsou proxy, ne cost-aware
- Worst case: ~$26+ na komplexní ticket bez stropu
- **Dopad:** Riziko runaway costs při demonstraci
- **Workaround:** Konzervativní retry limity (fixer=3, test=2)

**G7: Standalone agent invocability (ČÁSTEČNĚ)**
- Agenti volatelní přes Task tool, ale bez granulárních skills
- **Dopad:** Postupná adopce vyžaduje ruční orchestraci
- **Workaround:** `/analyze-bug` jako entry point pro triage+code-analyst

### P3: Střední (UX/convenience)

**G8:** Zpětný zápis agent_session_id — CHYBÍ
**G9:** Oracle Docker TCP health check — ČÁSTEČNĚ (vynechat URL)
**G10:** Chybí Oracle PL/SQL template — nice-to-have
**G11:** Publisher mandatory v Profile — workaround: interaktivní odmítnutí

---

## Navržený Automation Config (draft)

```markdown
## Automation Config

### Issue Tracker
| Key | Value |
|------|---------|
| Type | redmine |
| Instance | https://redmine.test.ceosdata.com |
| Project | ai-dev |
| Bug query | project_id=ai-dev&status_id=open&tracker_id=1 |
| State transitions | In Progress: status:In Progress, Blocked: status:Rejected, For Review: status:For Review, Done: status:Closed |
| On start set | status:In Progress |

### Source Control
| Key | Value |
|------|---------|
| Remote | <owner/repo> |
| Base branch | main |
| Branch naming | fix/{issue}-{short-description} |

### PR Rules
| Key | Value |
|------|---------|
| Labels | ForReview |

### PR Description Template

## Summary
{summary}

## Changes
{changes}

## Testing
{testing}

Refs #{issue_id}

### Build & Test
| Key | Value |
|------|---------|
| Build command | cd test-app && bash db/scripts/deploy.sh |
| Test command | bash test-app/db/scripts/test.sh |

### Retry Limits
| Key | Value |
|------|---------|
| Fixer iterations | 5 |
| Test attempts | 3 |
| Build retries | 5 |

### Agent Overrides
| Key | Value |
|------|---------|
| Path | customization/ |

### Decomposition
| Key | Value |
|------|---------|
| Max subtasks | 7 |
| Fail strategy | fail-fast |
| Commit strategy | squash |
| Create tracker subtasks | enabled |
```

**Poznámka:** `tracker_id=1` a state names ověřit na Redmine instanci. `Remote` vyplnit dle skutečného git repo.

---

## Minimální sada změn pro spuštění

### V projektu SK kompenzace (nutné)
1. `CLAUDE.md` — vložit Automation Config (výše) + PL/SQL konvence z orasetup/CLAUDE.md
2. `customization/fixer.md` — Oracle PL/SQL konvence (spec před body, check_errors.sh, Flyway migrace)
3. `customization/test-engineer.md` — utPLSQL konvence (anotace, naming, setup/teardown)

### V projektu SK kompenzace (žádoucí)
4. `customization/deployment-verifier.md` — sqlcl health check místo HTTP

### V pluginu ceos-agents (žádoucí, ne blocker)
5. `examples/configs/redmine-oracle-plsql.md` — nová šablona
6. `skills/template/SKILL.md` — přidat řádek do tabulky šablon

### Nepotřebné
- Žádné změny v `agents/` definicích
- Žádná implementace agent-process separation
- Žádné nové agenty
- Žádný MAJOR/MINOR version bump pluginu (pouze pokud se přidá šablona → MINOR)

---

## Infrastrukturní prerekvizity
1. Docker uživatel bez sudo: `usermod -aG docker $USER`
2. Oracle XE kontejner běžící: `docker start oracle-xe`
3. MCP server Redmine nakonfigurovaný: `.mcp.json` s redmine entry
4. Vzorové utPLSQL testy v repozitáři (min. 1-2 test packages)
5. Redmine API klíč s write oprávněními
