# Zadání: Setup drmax-readmine-test pro ceos-agents

> **Repo:** `C:\gitea_drmax-readmine-test`
> **Zdroj:** Gap analýza `docs/plans/readmine-project/ceos-agents-gap-analysis.md` (sekce 5-8, Přílohy A+B)
> **Prerekvizita v ceos-agents:** Šablona `redmine-oracle-plsql` existuje (v6.4.2+)

---

## Kontext

Projekt SK kompenzace (Oracle PL/SQL engine) v Redmine. Cíl: nakonfigurovat repo pro použití s ceos-agents pluginem — bug-fix pipeline, postupná adopce.

**Stack:** Oracle XE 21c Docker, SQLcl 26.1, Flyway 9.22.3, utPLSQL 3.1.14
**Redmine:** `redmine.test.ceosdata.com`, projekt `ai-dev`
**SC:** Gitea, `fsabacky/drmax-readmine-test`

---

## Úkoly

### 1. Vytvořit CLAUDE.md s Automation Config

Vytvořit `CLAUDE.md` v rootu repozitáře. Obsahuje:

**a) Automation Config** — vychází z šablony `redmine-oracle-plsql` (plugin ceos-agents), ale s vyplněnými hodnotami:

```markdown
## Automation Config

### Issue Tracker
| Key | Value |
|------|---------|
| Type | redmine |
| Instance | `https://redmine.test.ceosdata.com` |
| Project | `ai-dev` |
| Bug query | `status_id=open&assigned_to_id=me&tracker_id=1` |
| State transitions | In Progress: `status:In Progress`, Blocked: `status:Blocked`, For Review: `status:For Review`, Done: `status:Closed` |
| On start set | `status:In Progress` |

### Source Control
| Key | Value |
|------|---------|
| Remote | `fsabacky/drmax-readmine-test` |
| Base branch | `main` |
| Branch naming | `fix/{issue}-{short-description}` |

### PR Rules
| Key | Value |
|------|---------|
| Labels | `ai-generated` |

### PR Description Template

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

### Build & Test
| Key | Value |
|------|---------|
| Build command | `bash db/scripts/deploy.sh` |
| Test command | `bash db/scripts/test.sh` |

### Retry Limits
| Key | Value |
|------|---------|
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
|------|---------|
| Path | `customization/` |

### Local Deployment
| Key | Value |
|------|---------|
| Type | docker |
| Start command | `docker start oracle-xe` |
| Stop command | `docker stop oracle-xe` |
| Health check URL | `bash -c 'echo "SELECT 1 FROM DUAL;" | sqlplus -S system/oracle@localhost:1521/XEPDB1'` |
| Health check timeout | 60 |
| Ports | 1521 |

### Error Handling
| Key | Value |
|------|---------|
| On block | comment |
| Max blocked per run | 3 |

### Decomposition
| Key | Value |
|------|---------|
| Max subtasks | 5 |
| Fail strategy | fail-fast |
| Commit strategy | squash |
| Create tracker subtasks | disabled |
```

**b) Oracle PL/SQL konvence** — pod Automation Config přidat sekci s Oracle-specifickými konvencemi projektu. Pokud existuje `orasetup/CLAUDE.md` nebo jiný zdroj konvencí v repo, použít ho. Jinak:

- Struktura souborů: `db/packages/*.pks`, `db/packages/*.pkb`, `db/tests/ut_*.pks`, `db/tests/ut_*.pkb`, `db/migrations/V{N}__{popis}.sql`
- Kompilace: vždy spec PŘED body
- Naming: `l_` lokální, `p_` parametry, `g_` globální, `c_` konstanty, `cur_` kurzory
- Packages: `{modul}_pkg`, testy: `ut_{modul}_pkg`
- Výjimky: `PRAGMA EXCEPTION_INIT`, rozsah -20001 až -20999
- Audit log: povinný pro INSERT/UPDATE triggery
- Zakázáno: `DBMS_OUTPUT.PUT_LINE` v produkci, `WHEN OTHERS THEN NULL`, implicitní kurzory bez WHERE

<!-- TODO: Ověřit na instanci -->
<!-- - tracker_id=1 odpovídá "Bug" trackeru: GET /projects/ai-dev/trackers.json -->
<!-- - Status names: GET /issue_statuses.json -->
<!-- - assigned_to_id=me: ověřit podporu v mcp-server-redmine -->
<!-- - Container name "oracle-xe": doplnit skutečný název -->
<!-- - XEPDB1 service name: ověřit dle Oracle XE konfigurace -->

### 2. Vytvořit customization/fixer.md

Agent Override pro fixer agenta. Kompletní obsah z gap analýzy Příloha A:

- Oracle PL/SQL konvence (stack verze, struktura souborů)
- Kódovací konvence (výjimky, audit log, naming, package structure)
- Build a test příkazy s troubleshooting (ORA-00942, Teams upgrade)
- Flyway migrace pravidla
- Omezení diff (rozdělit .pks a .pkb do separátních iterací)

Soubor musí začínat `## Project-Specific Instructions` — agent override injector to připojí na konec fixer promptu.

### 3. Vytvořit customization/test-engineer.md

Agent Override pro test-engineer agenta. Kompletní obsah z gap analýzy Příloha B:

- utPLSQL 3.1.14 konvence (anotace, suitepath, rollback manual)
- Setup procedura (povinná, beforeeach, DELETE z audit_log)
- Assertion konvence (ut.expect API, exception testy)
- Naming konvence (ut_{modul}_pkg, test_{co_testujes})
- Soubory: vždy OBA (.pks + .pkb), kompilace spec PŘED body
- Časté chyby tabulka (ORA-00942, ORA-00904, ORA-44001)

Soubor musí začínat `## Project-Specific Instructions`.

### 4. Spustit validaci

Po vytvoření souborů:
1. `/ceos-agents:check-setup` — ověří kompletnost Automation Config
2. `/ceos-agents:init` — ověří MCP connectivity (vyžaduje nakonfigurovaný mcp-server-redmine)

---

## Prerekvizity (mimo scope tohoto zadání)

| Co | Stav | Kdo |
|----|------|-----|
| Oracle XE 21c Docker běží | Ověřit | Milan Marťák |
| `db/scripts/deploy.sh` existuje a vrací exit 0 | Ověřit | Milan Marťák |
| `db/scripts/test.sh` existuje a vrací exit 0 | Ověřit | Milan Marťák |
| `mcp-server-redmine` nakonfigurovaný v Claude Code | Nakonfigurovat | Filip Sabacky |
| `.env` s DB credentials | Vytvořit | Milan Marťák |
| Redmine API přístup (API key) | Ověřit | Filip Sabacky |

---

## Doporučený postup

1. Spustit `/forge` s tímto zadáním — vytvoří všechny 3 soubory
2. Ověřit TODO komentáře v CLAUDE.md proti Redmine API
3. Spustit `/ceos-agents:check-setup` pro validaci
4. Až bude infra ready (Docker, scripty, MCP) — spustit `/ceos-agents:init`
5. Vytvořit 3-5 XS/S bug ticketů v Redmine a otestovat `/ceos-agents:fix-ticket`

---

## Poznámky

- `/ceos-agents:template redmine-oracle-plsql` lze pustit pro referenci, ale je read-only (jen zobrazí šablonu)
- Forge zvládne celý setup jako jeden task — vytvoří soubory, doplní hodnoty z kontextu
- Hodnoty označené `<!-- TODO -->` vyžadují manuální validaci na Redmine instanci
- Agent Override obsah je 1:1 z gap analýzy Přílohy A a B — ověřený format
