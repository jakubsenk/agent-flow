# Phase 2 Research Answers — Agent 1
## Doména: Redmine integrace a Build/Test agnostismus

---

## Q-1A-02 (CRITICAL): Jak funguje překlad status:{name} → status_id v Redmine MCP?

**Soubory:** `docs/reference/trackers.md` (řádky 27–29), `examples/mcp-configs/redmine.json`

**Zjištění:**

Soubor `docs/reference/trackers.md` na řádcích 27–29 explicitně uvádí:

> `status:{name}` je **LLM konvence**. LLM překládá tento formát na příslušné volání Redmine API (např. `status_id=2` pro "In Progress"). Mapování status name-to-ID závisí na konfiguraci konkrétní Redmine instance.

Překlad tedy NENÍ technický — je plně delegován na LLM. LLM musí za běhu odhadnout nebo zjistit správné `status_id` pro danou Redmine instanci. Soubor `examples/mcp-configs/redmine.json` (řádky 1–12) obsahuje pouze základní MCP konfiguraci (`REDMINE_HOST`, `REDMINE_API_KEY`) — žádné mapování stavů není přítomno.

**Hodnocení: ČÁSTEČNĚ**

Plugin dokumentuje konvenci (`status:{name}`), ale překlad na `status_id` je delegován na LLM bez záruky správnosti. Na instancích s nestandardními ID stavů (např. `status_id=5` pro "In Progress" místo `2`) může LLM selhat nebo použít špatné ID — zejména při prvním onboardingu bez explicitního mapování v konfiguraci.

**Implikace pro onboarding:**
- Onboarding config MUSÍ zahrnovat explicitní mapování stavů (name → ID) pro konkrétní Redmine instanci, nebo bude nutné LLM poskytnout seznam stavů jinak (např. přes Agent Override).
- Doporučeno přidat do `### Issue Tracker` sekce volitelný klíč `Status IDs` s mapováním.

---

## Q-1A-03 (HIGH): Podporuje mcp-server-redmine custom fields (assignee_type, context_file, agent_session_id)?

**Soubory:** `docs/reference/trackers.md`, `examples/mcp-configs/redmine.json`, `agents/triage-analyst.md`

**Zjištění:**

- `docs/reference/trackers.md` — žádná zmínka o custom fields pro žádný tracker. Tabulky pokrývají: Query Syntax, State Transitions, Instance & Project Defaults, On Start Set, PR Description Footer, Validation Rules, MCP Server Detection, Sub-Issue Capabilities. Custom fields nejsou v žádné sekci zmíněny.
- `examples/mcp-configs/redmine.json` — obsahuje pouze `REDMINE_HOST` a `REDMINE_API_KEY`. Žádná konfigurace custom fields.
- `agents/triage-analyst.md` (řádky 1–114) — agent čte pouze standardní pole issue trackeru (summary, description, comments, attachments). Krok 1: "Read bug details from issue tracker (summary, description, comments, custom fields)." — zmínka "custom fields" je generická, bez Redmine-specifické implementace.

**Hodnocení: CHYBÍ**

Plugin neřeší Redmine custom fields na žádné úrovni. Pokud Redmine instance používá custom fields jako `assignee_type`, `context_file` nebo `agent_session_id`, záleží výhradně na schopnosti `mcp-server-redmine` tato pole exponovat přes MCP a na schopnosti LLM je číst z obecného výpisu issue. Není žádná záruka ani dokumentovaný postup.

**Implikace pro onboarding:**
- Nutno ověřit, zda `mcp-server-redmine` exponuje custom fields v tool response.
- Pokud ano, lze je číst přes triage-analyst (krok 1 čte "custom fields" genericky).
- Pokud ne, bude potřeba Agent Override pro triage-analyst nebo rozšíření MCP konfigurace.

---

## Q-1A-01 (MEDIUM): Je Redmine query formát flexibilní pro nestandardní instance?

**Soubory:** `docs/reference/trackers.md` (řádky 14–16), `core/config-reader.md` (řádky 14–18)

**Zjištění:**

Redmine query formát dle `docs/reference/trackers.md` řádek 14:
```
project_id={P}&status_id=open&tracker_id={bug_tracker_id}
```

Řádek 16 uvádí: "tracker_id expects the numeric ID from your Redmine instance (typically 1=Bug, 2=Feature, 3=Support)."

`core/config-reader.md` řádek 16: `issue_tracker.bug_query` je přímý string — plugin ho parsuje jako hodnotu a předává beze změny. Validační pravidlo (trackers.md řádek 73): query "Must contain `project_id=`".

**Hodnocení: PODPOROVÁNO**

Redmine query je plain string — lze konfigurovat libovolně. Uživatel může zadat jakékoliv parametry URL query (přidat `assigned_to_id=`, `priority_id=`, vlastní filtry). Validátor pouze ověřuje přítomnost `project_id=`. `tracker_id` je číselný parametr závislý na instanci — dokumentace to explicitně uvádí a nechává na uživateli.

**Implikace pro onboarding:**
- Uživatel musí zjistit správná numerická ID pro tracker a status ze své Redmine instance (API `/trackers.json`, `/issue_statuses.json`).
- Onboardovací průvodce by měl tato ID vyžádat.

---

## Q-1A-05 (HIGH): Je Build/Test config agnostický (shell string bez předpokladů)?

**Soubory:** `agents/fixer.md` (kroky 5–7, řádky 46–51), `agents/test-engineer.md` (kroky 2, 5, řádky 22–35), `core/config-reader.md` (řádky 17–18)

**Zjištění:**

- `core/config-reader.md` řádek 18: `build.build_command`, `build.test_command`, `build.verify_command` — uloženo jako čisté stringy, žádné předpoklady o formátu.
- `agents/fixer.md` krok 6 (řádek 47): "Run: build command from Automation Config (Build & Test section)" — přímé spuštění příkazu.
- `agents/fixer.md` krok 7 (řádek 49): "Run: test command from Automation Config" — přímé spuštění.
- `agents/test-engineer.md` krok 2 (řádek 22): "Run test command from Automation Config" — přímé spuštění.
- `agents/test-engineer.md` krok 5 (řádek 33): "Must pass on first try" — pouze exit kód určuje výsledek.

Agenti spouštějí příkazy přes Bash tool a hodnotí výsledek. Neexistuje žádný parser specifický pro konkrétní build systém nebo test framework.

**Hodnocení: PODPOROVÁNO**

Build a test příkazy jsou plně agnostické shell stringy. Lze použít `ant`, `mvn`, `gradle`, `make`, vlastní skripty, `utPLSQL-cli` nebo jakýkoliv spustitelný příkaz.

**Implikace pro onboarding:**
- Plná flexibilita — příkazy jako `sqlplus /nolog @run_tests.sql` nebo `docker exec oracle utplsql run` fungují stejně dobře jako `npm test`.

---

## Q-1B-01 (HIGH): Zpracovávají agenti build/test výstup na exit kódu, nebo parsují formát?

**Soubory:** `agents/fixer.md` (kroky 6–7, řádky 46–51), `agents/test-engineer.md` (kroky 2, 5, řádky 22–35)

**Zjištění:**

- `agents/fixer.md` krok 6 (řádek 47–48): "If build fails → fix build errors" — "build fails" se hodnotí z výstupu příkazu (exit kód + stderr). Žádný parser formátu.
- `agents/fixer.md` krok 7 (řádky 49–51): "If tests fail → assess whether the failure is caused by your change." — hodnocení je sémantické (LLM čte výstup), ne formátové.
- `agents/test-engineer.md` krok 2 (řádek 22–23): "If existing tests fail → check the fixer's output for noted pre-existing failures." — LLM srovnává výstup s předchozím kontextem.
- `agents/test-engineer.md` krok 5 (řádky 33–35): "Must pass on first try" — exit kód 0 = pass, nenulový = fail.

**Hodnocení: PODPOROVÁNO**

Primárně se hodnotí exit kód procesu. LLM dále čte stdout/stderr pro diagnostiku, ale neexistuje parser specifický pro JUnit XML, TAP, pytest JSON atd. To znamená, že formát výstupu není omezující — utPLSQL výstup, Oracle SQL*Plus návratové kódy atd. fungují stejně.

**Implikace pro onboarding:**
- Pokud `utPLSQL-cli` nebo SQL*Plus vrátí nenulový exit kód při selhání testů, pipeline to správně zachytí.
- Pokud příkaz vždy vrací 0 (některé starší skripty), je nutné wrapper skript s explicitním `exit 1`.

---

## Q-1B-02 (HIGH): Dokáže fixer generovat Oracle PL/SQL bez Agent Override?

**Soubory:** `agents/fixer.md` (krok 2, řádky 22–24), `CLAUDE.md` (Agent Overrides section)

**Zjištění:**

- `agents/fixer.md` krok 2 (řádky 22–24): "Read project conventions from CLAUDE.md (coding style, patterns, naming conventions)" — fixer čte konvence projektu z CLAUDE.md.
- `agents/fixer.md` krok 4 (řádek 27): "Read affected files thoroughly before changing anything. Read surrounding code to understand conventions." — fixer se učí z existujícího kódu.
- `CLAUDE.md` sekce Agent Overrides: "For each agent, create a file `{path}/{agent-name}.md` with additional instructions. Contents are appended to the agent's prompt as `## Project-Specific Instructions`."

Fixer používá opus model (obecně velmi schopný v PL/SQL). Konvence se učí z CLAUDE.md a ze čtení existujícího kódu. Agent Override pro fixer není povinný, ale výrazně pomáhá pro:
- Oracle-specifické balíky (`DBMS_*`, UTL_*)
- Naming conventions pro PL/SQL (procedury, funkce, trigger naming)
- Testovací struktury utPLSQL

**Hodnocení: ČÁSTEČNĚ**

Fixer dokáže generovat PL/SQL díky obecným schopnostem Claude opus a čtení existujícího kódu. Bez Agent Override ale nemá specifické instrukce pro Oracle best practices (exception handling patterns, `PRAGMA AUTONOMOUS_TRANSACTION`, bulk collect konvence). Agent Override pro fixer je silně doporučen pro PL/SQL projekty.

**Implikace pro onboarding:**
- Vytvořit `customization/fixer.md` s Oracle PL/SQL konvencemi projektu.
- Alternativně zahrnou konvence do CLAUDE.md sekce `## Coding Conventions`.

---

## Q-1B-04 (HIGH): Koliduje "no external service calls" v test-engineer s utPLSQL (volání DB)?

**Soubory:** `agents/test-engineer.md` (Constraints section, řádek 49)

**Zjištění:**

`agents/test-engineer.md` řádek 49 (Constraints):
> "NEVER write flaky tests — no random data, no timing dependencies, **no external service calls**"

Constraint "no external service calls" je zaměřen na prevenci flaky testů (HTTP callbacky, třetí strany, nedeterministické zdroje). Databázové volání v kontextu utPLSQL NENÍ "external service call" v tomto smyslu — je to přímá součást testovacího frameworku a testovaného systému.

Constraint je navíc instrukce pro LLM při psaní testů (co nemá psát), nikoliv technické omezení exekuce. Příkaz `test_command` z Automation Config se spouští přes Bash bez filtrace.

**Hodnocení: PODPOROVÁNO**

Žádná kolize. "No external service calls" v kontextu test-engineer znamená: nepiš testy závislé na externích HTTP API, random seedech, časování. Volání databáze přes utPLSQL je integrální součástí DB unit testů — constraint se na ně nevztahuje sémanticky. Spuštění `test_command` (byť jde o `utplsql run`) probíhá bez omezení.

**Implikace pro onboarding:**
- Žádné překážky. utPLSQL testy lze konfigurovat standardně přes `Test command`.

---

## Q-1B-05 (CRITICAL): Jak pipeline řeší Oracle Docker health check (TCP vs HTTP)?

**Soubory:** `agents/deployment-verifier.md` (krok 5, řádky 45–50), `CLAUDE.md` (Local Deployment section), `skills/check-deploy/SKILL.md`

**Zjištění:**

`agents/deployment-verifier.md` krok 5 (řádky 45–50):
- "If no `Health check URL` is configured → set `health: skipped`, determine verdict from port scan and container status only"
- Pokud je URL nakonfigurována: poll každé 2 sekundy, HTTP 2xx = HEALTHY, timeout = UNHEALTHY, connection refused = UNREACHABLE

`CLAUDE.md` Local Deployment sekce: `Health check URL` je volitelný klíč (default: `http://localhost:3000/health`).

`skills/check-deploy/SKILL.md`: Krok 1 provádí port scan (TCP), krok 3 deleguje na deployment-verifier.

Oracle DB (port 1521) NEPOSKYTUJE HTTP endpoint — je to TCP/SQL*Net protokol. Standardní HTTP health check by vždy vrátil `UNREACHABLE` nebo `UNHEALTHY`.

**Hodnocení: ČÁSTEČNĚ**

Pipeline podporuje dvě alternativy:
1. **Vynechat Health check URL** — deployment-verifier přeskočí HTTP polling a spoléhá na port scan + Docker container status. Pro Oracle DB port 1521 je TCP port scan dostačující verifikací.
2. **Použít HTTP health check endpoint** — vyžaduje samostatný sidecar/healthcheck kontejner nebo vlastní HTTP wrapper okolo Oracle listeneru.

Explicitní podpora pro TCP-only health check (jako `pg_isready` pro PostgreSQL nebo přímý TCP connect test) chybí. Workaround je buď vynechat URL (spolehnutí na port scan), nebo přidat health check skript do Docker Compose.

**Implikace pro onboarding:**
- Oracle Docker setup: NEUVÁDĚT `Health check URL` v Automation Config (nebo ho vynechat).
- Deployment-verifier pak použije port scan (1521) + Docker container status jako verifikaci.
- Doporučeno přidat do `docker-compose.yml` Oracle healthcheck (`healthcheck: test: ["CMD", "bash", "-c", "echo exit | sqlplus -L sys/... as sysdba"]`).

---

## Q-1B-03 (MEDIUM): Jak test-engineer zpracuje utPLSQL dvousouborovou strukturu?

**Soubory:** `agents/test-engineer.md` (kroky 3–5, řádky 24–35)

**Zjištění:**

`agents/test-engineer.md`:
- Krok 3 (řádky 24–28): "Plan test scope — write 1-3 focused tests"
- Krok 4 (řádky 29–32): "Follow project test conventions (framework, naming, structure — read existing tests first)" + "Place tests in the correct test directory (use Glob to find existing test files, follow the same pattern)"
- Krok 5 (řádky 33–35): "Run new tests" přes test command

utPLSQL dvousouborová struktura (spec file `ut_<package>_spec.pkb` + body `ut_<package>_body.pkb`) nebo single-file struktura v SQL balíku je konvence projektu. Test-engineer:
1. Čte existující testy přes Glob
2. Odvozuje konvence (file naming, package structure)
3. Vytváří nové testy podle stejného vzoru

**Hodnocení: PODPOROVÁNO (s podmínkou)**

Test-engineer je schopen zpracovat utPLSQL strukturu za předpokladu, že v projektu EXISTUJÍ alespoň nějaké vzorové testy. Bez vzorových testů krok 4 říká: "If no existing tests exist: create the test file following language conventions (e.g., `tests/test_{module}.py` for Python...)" — pro PL/SQL neexistuje výchozí konvence, LLM bude muset hádat nebo selže.

**Implikace pro onboarding:**
- Zajistit alespoň 1-2 vzorové utPLSQL test soubory v repozitáři před spuštěním pipeline.
- Zvážit Agent Override pro test-engineer s popisem utPLSQL konvencí (`customization/test-engineer.md`).

---

## Q-1A-04 (MEDIUM): Jak pipeline vytváří sub-tasky v Redmine přes parent_issue_id?

**Soubory:** `docs/reference/trackers.md` (řádky 88–97), `agents/architect.md` (krok 8, řádky 45–72)

**Zjištění:**

`docs/reference/trackers.md` řádky 88–97 — Sub-Issue Capabilities tabulka:
- Redmine: **Yes** | `parent_issue_id: {id}` | N/A (fallback není potřeba)
- Poznámka: "The parent parameter names are MCP tool conventions. The LLM uses these when invoking the tracker's MCP create-issue tool."

`agents/architect.md` krok 8 (řádky 45–72): Generuje task tree v YAML formátu se subtasky (id, title, scope, files, estimated_lines, depends_on, maps_to, acceptance_criteria). Runtime pole jako `tracker_issue_id` jsou přidávána orchestrujícím příkazem během exekuce.

Orchestrující příkaz (implement-feature/fix-ticket) volá MCP `create-issue` tool s parametrem `parent_issue_id: {parent_id}` pro každý subtask v task tree.

**Hodnocení: PODPOROVÁNO**

Pipeline má nativní podporu pro Redmine sub-issues přes `parent_issue_id`. Architect definuje task tree, orchestrující příkaz vytváří tracker sub-issues. Není potřeba fallback (standalone issues s prefixem jako u GitHub/Gitea).

**Implikace pro onboarding:**
- `mcp-server-redmine` musí podporovat `parent_issue_id` parametr v create-issue tool — nutno ověřit verzi balíčku.
- Standardní Redmine API `POST /issues.json` s `{"issue": {"parent_issue_id": X}}` je nativní feature.

---

## Q-1B-06 (MEDIUM): sudo docker bez interaktivního hesla

**Zdroj:** Execution model Claude Code (inference), `agents/deployment-verifier.md` (krok 4)

**Zjištění:**

Claude Code spouští příkazy přes Bash tool v non-interaktivním shellu. `sudo` vyžadující heslo způsobí timeout nebo zablokování bez odpovědi — interaktivní prompt nelze poskytnout.

`agents/deployment-verifier.md` krok 4 předpokládá `docker compose up -d` bez `sudo`.

**Hodnocení: CHYBÍ (infrastrukturní požadavek)**

Plugin neposkytuje žádný mechanismus pro předání sudo hesla. Jediné funkční řešení je infrastrukturní:

1. **Přidat uživatele do skupiny `docker`:** `usermod -aG docker $USER` — docker příkazy bez sudo.
2. **Sudoers bez hesla pro docker:** `NOPASSWD: /usr/bin/docker` v `/etc/sudoers.d/`.
3. **Rootless Docker:** `dockerd-rootless-setuptool.sh install`.

**Implikace pro onboarding:**
- Prerekvizita pro Oracle Docker workflow: uživatel musí mít přístup k `docker` bez `sudo`.
- Dokumentovat jako infrastrukturní požadavek onboardingu.

---

## Q-1A-06, Q-1A-07 (LOW): MCP preflight depth, resume-ticket detection

**Soubory:** `core/mcp-preflight.md` (řádky 1–47), `skills/resume-ticket/SKILL.md` (řádky 11–69)

### Q-1A-06: MCP preflight hloubka

`core/mcp-preflight.md`:
- Deleguje na `core/mcp-detection.md` s `service_type: "tracker"`, `check_write: false`
- Kontroluje pouze **přítomnost MCP tool** (tool prefix `mcp__{tracker_type}__*`) a **read connectivity**
- Neověřuje write permissions, nevaliduje Redmine projekty ani stavy
- Dva failure modes: tool nenalezen → BLOCK, tool nalezen ale nereaguje → BLOCK

**Hodnocení: ČÁSTEČNĚ**

Preflight je lehký check — ověří připojitelnost, ale ne oprávnění pro zápis (vytváření issues, přechody stavů). Selhání write operací se projeví až za běhu pipeline.

**Implikace pro onboarding:**
- Pre-flight projde i když API klíč nemá write oprávnění — pipeline selže až při prvním zápisu.
- Doporučeno zahrnout write test do onboardingu (`/ceos-agents:check-setup`).

### Q-1A-07: Resume-ticket detekce

`skills/resume-ticket/SKILL.md`:
- **Priority 0:** State file `.ceos-agents/{ISSUE-ID}/state.json` — deterministic resume
- **Fallback heuristika:** Detekuje checkpoint ze komentářů v trackeru, git větví, PR stavu
- Detekce pipeline typu (BUG vs FEATURE) dle komentářů `[ceos-agents] Triage completed.` vs `[ceos-agents] Spec analysis completed.`
- Triage comment (řádek 42): akceptuje `[ceos-agents]` i legacy `[CLAUDE-agents]` prefix

Pro Redmine: resume-ticket čte komentáře přes MCP — stejný mechanismus jako ostatní agenti. Funguje pokud `mcp-server-redmine` exponuje comments v issue detail.

**Hodnocení: PODPOROVÁNO**

Resume-ticket je tracker-agnostický — detekce je založena na komentářích a git stavu. Redmine nevyžaduje žádnou speciální konfiguraci pro resume funkčnost.

---

## Shrnutí pro onboarding (prioritizováno)

| Priorita | Oblast | Stav | Akce |
|----------|--------|------|------|
| CRITICAL | status:{name} → status_id překlad | ČÁSTEČNĚ | Přidat mapování stavů do onboarding guide nebo Agent Override |
| HIGH | Custom fields (assignee_type atd.) | CHYBÍ | Ověřit mcp-server-redmine capabilities; zvážit Agent Override |
| HIGH | Oracle Docker TCP health check | ČÁSTEČNĚ | Vynechat Health check URL, spoléhat na port scan + container status |
| HIGH | utPLSQL vzorové testy | PODMÍNĚNO | Zajistit vzorové testy v repozitáři před spuštěním pipeline |
| MEDIUM | sudo docker | CHYBÍ (infrastruktura) | Přidat uživatele do skupiny docker jako prerekvizitu |
| MEDIUM | parent_issue_id v mcp-server-redmine | PODPOROVÁNO | Ověřit verzi balíčku |
| LOW | MCP preflight write test | ČÁSTEČNĚ | Zahrnout write test do check-setup |
