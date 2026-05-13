# Research Agent 3 — Automation Config (Oracle PL/SQL + Redmine) a potřebné změny pluginu

**Datum:** 2026-04-10
**Zdroje:** `examples/configs/redmine-rails.md`, `CLAUDE.md`, `docs/plans/readmine-project/orasetup/CLAUDE.md`, `docs/plans/readmine-project/orasetup/.env`, `docs/plans/readmine-project/zadani - projektu.md`, `docs/reference/trackers.md`, `agents/fixer.md`, `agents/test-engineer.md`, `skills/template/SKILL.md`, `docs/plans/readmine-project/agent-process-separation.md`

---

## Část 1: Návrh Automation Config pro projekt SK kompenzace

### Použité zdroje pro sestavení konfigurace

- **Redmine URL:** `https://redmine.test.ceosdata.com/projects/ai-dev/issues` (ze zadání projektu)
- **DB připojení:** Oracle XE 21c Docker, host `localhost:1521`, PDB `DEVPDB`, user `portal` (z `.env`)
- **Build příkaz:** `cd test-app && bash db/scripts/deploy.sh` (Flyway migrace + kompilace + validace) — z `orasetup/CLAUDE.md`
- **Test příkaz:** `bash test-app/db/scripts/test.sh` (spustí všechny utPLSQL testy) — z `orasetup/CLAUDE.md`
- **Tracker format:** `project_id={P}&status_id=open&tracker_id={id}` — z `docs/reference/trackers.md`
- **State transitions:** `status:{name}` formát pro Redmine — z `docs/reference/trackers.md`

### Poznámky k Redmine konfiguraci

Podle `docs/reference/trackers.md`:
- `tracker_id` je numerické ID — typicky 1=Bug, 2=Feature, 3=Support (nutno ověřit na konkrétní Redmine instanci)
- `status_id=open` je zkratka pro všechny otevřené stavy
- State transitions: `status:{name}` — LLM překládá na Redmine API volání s `status_id`
- Sub-issues: Redmine nativně podporuje `parent_issue_id: {id}` — důležité pro decomposition

---

### Výsledná `## Automation Config` sekce

```markdown
## Automation Config

### Issue Tracker
| Key | Value |
|------|---------|
| Type | redmine |
| Instance | `https://redmine.test.ceosdata.com` |
| Project | `ai-dev` |
| Bug query | `project_id=ai-dev&status_id=open&tracker_id=1` |
| Feature query | `project_id=ai-dev&status_id=open&tracker_id=2` |
| State transitions | In Progress: `status:In Progress`, Blocked: `status:Rejected`, For Review: `status:For Review`, Done: `status:Closed` |
| On start set | `status:In Progress` |

### Source Control
| Key | Value |
|------|---------|
| Remote | `<owner/repo>` |
| Base branch | `main` |
| Branch naming | `fix/{issue}-{short-description}` |

### PR Rules
| Key | Value |
|------|---------|
| Labels | `ForReview` |

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
| Build command | `cd test-app && bash db/scripts/deploy.sh` |
| Test command | `bash test-app/db/scripts/test.sh` |

### Local Deployment
| Key | Value |
|------|---------|
| Type | docker |
| Start command | `sudo docker start oracle-xe` |
| Stop command | `sudo docker stop oracle-xe` |
| Health check URL | `jdbc:oracle:thin:@//localhost:1521/DEVPDB` |
| Health check timeout | `60` |
| Ports | `1521` |

### Retry Limits
| Key | Value |
|------|---------|
| Fixer iterations | `5` |
| Test attempts | `3` |
| Build retries | `5` |
| Spec iterations | `5` |
| Root cause iterations | `3` |

### Agent Overrides
| Key | Value |
|------|---------|
| Path | `customization/` |

### Decomposition
| Key | Value |
|------|---------|
| Max subtasks | `7` |
| Fail strategy | `fail-fast` |
| Commit strategy | `squash` |
| Create tracker subtasks | `enabled` |
```

---

### Poznámky k jednotlivým sekcím

**Issue Tracker:**
- `tracker_id=1` pro bugy je výchozí Redmine konvence — před nasazením ověřit na `https://redmine.test.ceosdata.com` (Redmine → Settings → Trackers)
- `tracker_id=2` pro features (feature workflow)
- State names odpovídají defaultnímu Redmine workflow; je nutné přizpůsobit skutečným názvům stavů v projektu `ai-dev`
- Stav "Rejected" použit pro Blocked — mapuje na Redmine konvenci zamítnutí; alternativně "On Hold" pokud je konfigurováno

**Build & Test:**
- `deploy.sh` provede kompletní sekvenci: Flyway migrace → kompilace packages → kompilace testovacích packages → kontrola INVALID objektů
- Build retries zvýšeny na 5 (místo defaultních 3) — Oracle kompilace PL/SQL je pomalejší a náchylnější k přechodnému selhání, zejména při první kompilaci po DDL změnách
- `sudo` je vyžadováno pro Docker příkazy dle `orasetup/CLAUDE.md` — toto může být problém v CI prostředí bez sudo; nutno ověřit

**Local Deployment:**
- Oracle XE běží v Dockeru (`oracle-xe` kontejner) — `deployment-verifier` agent ho může startovat/stopovat
- Health check: Oracle neposkytuje HTTP endpoint; health check URL je JDBC connection string — `deployment-verifier` musí ověřit konektivitu přes `sqlcl`, ne HTTP
- **Upozornění:** Stávající `deployment-verifier` agent předpokládá HTTP health check (GET request). Pro Oracle je nutný override v `customization/deployment-verifier.md`

**Remote (Source Control):**
- Placeholder `<owner/repo>` — nutno vyplnit dle skutečného git repozitáře projektu
- Ze zadání vyplývá, že projekt používá lokální git; pokud je na Gitea instanci, použít `owner/repo` formát

---

## Část 2: Posouzení potřebných změn pluginu

### H1: Postačí Agent Overrides pro Oracle specifika?

**Odpověď: Částečně ano, ale se dvěma výhradami.**

**Co Agent Overrides pokrývají dobře:**

Mechanismus z `CLAUDE.md`:
> Optional directory with per-agent customization files. For each agent (e.g., `reviewer`, `fixer`, `test-engineer`), create a file `{path}/{agent-name}.md` with additional instructions. Contents are appended to the agent's prompt as `## Project-Specific Instructions`.

Pro Oracle PL/SQL jsou potřebná tato přizpůsobení:

**`customization/fixer.md`** — přidat instrukce:
- Vždy kompilovat spec (`.pks`) před body (`.pkb`)
- Po každé změně spustit `bash db/scripts/check_errors.sh` k ověření
- Migrace pouze přes Flyway (soubory `db/migrations/V{číslo}__{popis}.sql`) — nikdy přímý DDL
- Výjimky jako konstanty: `e_<nazev> EXCEPTION; PRAGMA EXCEPTION_INIT(e_<nazev>, -200XX);`

**`customization/test-engineer.md`** — přidat instrukce:
- Test packages pojmenovávat `ut_<jmeno>.pks/.pkb` ve složce `db/tests/`
- Povinné anotace: `-- %suite(Název)`, `-- %suitepath(test_app)`, `-- %rollback(manual)`
- Setup procedura (beforeeach): `DELETE audit_log; DELETE tasks; DELETE contacts; COMMIT;`
- Test spouštět přes: `bash test-app/db/scripts/test.sh` (ne přímo utPLSQL API)

**`customization/deployment-verifier.md`** — přidat instrukce:
- Health check přes `sqlcl`, ne HTTP: `echo "SELECT 1 FROM DUAL;" | sqlcl -S portal/portal123@localhost:1521/DEVPDB`
- Ověřit nepřítomnost INVALID objektů: `bash db/scripts/check_errors.sh`

**Výhrada 1 — Chybějící Oracle-specifický template:**
Skill `/ceos-agents:template` nenabízí Oracle PL/SQL šablonu (pouze Ruby on Rails pro Redmine). Uživatel musí Automation Config sestavit ručně — bez průvodce `onboard` nebo `template`. Toto je UX problém, ne blocker.

**Výhrada 2 — deployment-verifier HTTP předpoklad:**
`deployment-verifier` agent pravděpodobně předpokládá HTTP health check. Agent Override to může přepsat, ale nutno ověřit, zda agent override přepíše process-level instrukce nebo jen přidá kontext.

**Závěr H1:** Agent Overrides postačí pro fixer a test-engineer. Pro deployment-verifier je nutný override s explicitní instrukcí nahradit HTTP health check sqlcl příkazem.

---

### H2: Je nový template `redmine-oracle-plsql.md` blokerem?

**Odpověď: Není blokerem, ale je žádoucí zlepšení.**

Ze `skills/template/SKILL.md`:
```
### Variant 2: `<stack-name>`
1. Read `examples/configs/{stack-name}.md`
2. Display contents
```

Skill `/ceos-agents:template` je read-only — pouze zobrazuje existující šablony. Přidání nové šablony `examples/configs/redmine-oracle-plsql.md` je trivialní:
- Jeden nový soubor
- Žádná změna skillů ani agentů
- Žádná verzovací implikace (MINOR bump v6.x.y)
- Výčet šablon v `Variant 1: list` je hard-coded v SKILL.md — nutno přidat jeden řádek

**Dopad bez šablony:** Uživatel sestaví Automation Config ručně podle CLAUDE.md Config Contract sekce. Tato zpráva (Část 1) slouží jako funkční náhrada šablony pro okamžité použití.

**Dopad s šablonou:** `/ceos-agents:template redmine-oracle-plsql` okamžitě vrátí hotovou konfiguraci, `/ceos-agents:onboard` ji nabídne jako výchozí.

**Závěr H2:** Není blokerem pro spuštění projektu. Je to low-effort zlepšení (1 nový soubor, 1 řádek v SKILL.md) doporučené pro finální release.

---

### H3: Je agent-process separation blokerem?

**Odpověď: Není blokerem. Je to dlouhodobá architekturní vize, ne prerekvizita.**

Ze `docs/plans/readmine-project/agent-process-separation.md`:

Dokument má status **"Proposal — pre-decision"** (řádek 3). Jde o návrh čtyřvrstvé architektury:
```
SKILL → PIPELINE DEFINITION → STEP DEFINITION → AGENT DEFINITION → TOOL NAMESPACES
```

Navrhovaná migrace má 4 fáze, přičemž fáze 1 (interface anotace) je `zpětně kompatibilní, ~2 týdny` a fáze 3 je `BREAKING: skills musí být aktualizovány`.

**Klíčové zjištění:** Dokument explicitně říká:
> "Stávající `## Automation Config` formát v projektech zůstává beze změny ve všech fázích."

Projekt SK kompenzace může být spuštěn na stávající architektuře (v6.x). Agent Overrides, Automation Config a stávající pipeline fungují bez jakékoliv implementace navrhovaného oddělení.

**Co separation řeší pro Oracle PL/SQL (relevance):**
- **Technology Profiles** (sekce 11) by umožnily deklarovat Oracle PL/SQL konvence jako profil místo Agent Override — ale toto je budoucí optimalizace
- **Tool namespaces** by přeložily `build_system.build` na `bash db/scripts/deploy.sh` transparentně — ale stávající Automation Config Build command to řeší identicky
- **Pre-flight validace** by ověřila, že Docker Oracle kontejner běží před spuštěním pipeline — ale toto lze řešit přes deployment-verifier

**Závěr H3:** Žádný bloker. Separation je EXPLORING/pre-decision architekturní návrh. Projekt SK kompenzace může být spuštěn okamžitě na stávající v6.x architektuře.

---

### H4: Minimální sada změn

Níže jsou konkrétní soubory nutné k spuštění projektu SK kompenzace s ceos-agents:

#### Nutné (bez těchto projekt nefunguje)

| Soubor | Akce | Obsah |
|--------|------|-------|
| `CLAUDE.md` projektu SK kompenzace | Vytvořit | `## Automation Config` sekce z Části 1 tohoto dokumentu (vyplnit Remote) |
| `customization/fixer.md` (v projektu SK kompenzace) | Vytvořit | Oracle PL/SQL konvence pro fixer agenta |
| `customization/test-engineer.md` (v projektu SK kompenzace) | Vytvořit | utPLSQL test konvence a naming |

#### Žádoucí (zlepšení UX, ne bloker)

| Soubor | Akce | Obsah |
|--------|------|-------|
| `customization/deployment-verifier.md` (v projektu) | Vytvořit | Přepsat health check z HTTP na sqlcl |
| `examples/configs/redmine-oracle-plsql.md` (v ceos-agents) | Vytvořit | Nová šablona pro `/ceos-agents:template` |
| `skills/template/SKILL.md` (v ceos-agents) | Upravit | Přidat `redmine-oracle-plsql` do tabulky v Variant 1 |

#### Nepotřebné pro spuštění

- Žádné změny v existujících agentech (`fixer.md`, `test-engineer.md` v pluginu)
- Žádná implementace agent-process separation
- Žádné nové agenty
- Verze pluginu: žádný bump není potřeba pro projekt-level soubory; MINOR bump (6.5.0) pokud se přidá šablona do pluginu

---

### Speciální analýza: utPLSQL vs. "no external service calls" constraint

**Constraint z `agents/test-engineer.md`:**
```
NEVER write flaky tests — no random data, no timing dependencies, no external service calls
```

**Zdánlivý konflikt:** utPLSQL testy volají Oracle databázi — je to "external service call"?

**Hodnocení: Toto je interpretační problém, nikoliv skutečný technický konflikt.**

**Argument proč se constraint na utPLSQL nevztahuje:**

1. **Kontext constraintu:** "no external service calls" je historicky namířeno proti testům, které volají třetí-stranné HTTP API (Stripe, Sendgrid, AWS), nevolají zároveň databázi jako součást unit testů. V kontextu Oracle PL/SQL projekt *je* databáze — je to produkční artefakt, ne externí závislost.

2. **Analogie:** V Django projektu by test-engineer napsal testy spouštěné přes `pytest` + Django test runner, který interně volá PostgreSQL databázi. Nikdo by neřekl, že "volá external service". utPLSQL je totéž — je to test runner, který běží uvnitř databáze, která je cílovým prostředím.

3. **Flakiness risk:** Constraint míří na nedeterminismus. utPLSQL testy s `-- %rollback(manual)` a explicitním setup (DELETE + COMMIT) jsou deterministické — každý test začíná ze stejného stavu.

4. **Praktický dopad:** Constraint v praxi zabrání test-engineerovi volat `http.get('https://api.example.com')` nebo generovat `uuid4()` bez seedu. Nebrání volání `ut.run('ut_contacts_pkg')` nebo přímé EXEC PL/SQL procedury v testu.

**Potenciální skutečný problém:**

Test-engineer defaultně hledá test soubory dle jazykových konvencí (Python: `tests/test_{module}.py`, TypeScript: `{module}.test.ts`). Oracle PL/SQL konvence jsou jiné (`ut_<jmeno>.pks/.pkb` v `db/tests/`). Bez Agent Override může test-engineer:
- Nevědět, kde hledat existující testy
- Nevědět formát utPLSQL anotací
- Nevědět, jak spustit konkrétní test package

**Řešení:** `customization/test-engineer.md` override (viz H4 výše) explicitně definuje Oracle PL/SQL test konvence. Toto je standardní mechanismus pluginu — žádná úprava samotného agenta není potřeba.

**Závěr:** "no external service calls" constraint není skutečný problém pro utPLSQL. Potenciální problém jsou chybějící Oracle-specifické konvence v test-engineerovi — řešeno přes Agent Override.

---

## Shrnutí

| Otázka | Závěr |
|--------|-------|
| H1: Agent Overrides pro Oracle? | Postačí pro fixer + test-engineer. Deployment-verifier vyžaduje override pro sqlcl health check. |
| H2: Nový template bloker? | Není bloker. Jeden nový soubor v examples/configs/ + 1 řádek v SKILL.md. |
| H3: Agent-process separation bloker? | Není bloker. Status "pre-decision proposal". Projekt funguje na stávající architektuře. |
| H4: Minimální change set | 3 soubory v projektu SK kompenzace (CLAUDE.md + 2 overrides). Volitelně 2 soubory v pluginu. |
| utPLSQL vs. constraint | Interpretační, ne technický konflikt. Řešeno Agent Override, ne změnou agenta. |

**Doporučení pro okamžité spuštění:** Zkopírovat Automation Config z Části 1, vyplnit `Remote` pole, vytvořit `customization/fixer.md` a `customization/test-engineer.md` s Oracle instrukcemi. Spustit `/ceos-agents:check-setup` pro validaci.
