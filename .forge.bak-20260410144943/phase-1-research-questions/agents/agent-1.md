# Agent 1 — Výzkumné otázky: Redmine integrace + Oracle PL/SQL stack

**Scope:** Oblast 1A (Redmine out-of-the-box) + Oblast 1B (Oracle PL/SQL kompatibilita)
**Verze pluginu:** v6.4.1
**Datum:** 2026-04-10

---

## Kontext

Zákazník (Filip Šabacký) potřebuje napojit ceos-agents na projekt v Redmine (`redmine.test.ceosdata.com/projects/ai-dev`) s Oracle PL/SQL jako vývojovým stackem. Stack je verifikovaný a zdokumentovaný v `docs/plans/readmine-project/orasetup/`. Klíčové nástroje: SQLcl 26.1, Flyway 9.22.3, Oracle XE 21c v Dockeru, utPLSQL 3.1.14. Nasazení probíhá přes shell skripty (`deploy.sh`, `test.sh`).

Zákazník explicitně zmínil, že: (a) nelze použít celou „mašinku ceos-agents" najednou, (b) workflow v Redmine nebylo jednoduchné namapovat v předchozím pokusu, (c) Oracle PL/SQL vývoj agenty „úplně podporovaný není".

---

## Oblast 1A: Redmine integrace

### OTK-1A-01: Je formát Redmine query dotazu dostatečně flexibilní pro vlastní instance?

**Otázka:** Dokumentovaný Bug query formát `project_id={P}&status_id=open&tracker_id={bug_tracker_id}` používá `status_id=open` jako zkratku. Jak plugin zachází s případem, kdy Redmine instance má nestandardní statusy nebo `tracker_id` s jiným číslováním než 1=Bug/2=Feature? Ověří si plugin toto mapování při spuštění, nebo předpokládá konvenci?

**Kde hledat odpověď:**
- `docs/reference/trackers.md` — Query Syntax + Validation Rules tabulky (ověřit, zda validace kontroluje jen přítomnost `project_id=`, ne obsah)
- `skills/check-setup/SKILL.md` — jestli check-setup ověřuje dostupnost/mapování tracker_id
- `agents/triage-analyst.md` (Process krok 1) — agent čte `Type` a použije MCP server; nikde neověřuje numerické ID trackerů

**Riziko:** Zákazníkova Redmine instance má vlastní číslování trackerů. Pokud pipeline slepě předá nakonfigurovaný query řetězec, může vrátit prázdný výsledek nebo výsledky z nesprávného trackeru, aniž by to detekovalo.

---

### OTK-1A-02: Jak konkrétně funguje překlad `status:{name}` → `status_id` v Redmine MCP serveru?

**Otázka:** Dokumentace uvádí: "The LLM translates this to the appropriate Redmine API call (e.g., `status_id=2` for 'In Progress'). Status name-to-ID mapping depends on the Redmine instance configuration." Kdo toto mapování provádí — LLM hádá, nebo MCP server `mcp-server-redmine` má API endpoint pro načtení statusů?

**Kde hledat odpověď:**
- `docs/reference/trackers.md` — State Transition Syntax poznámka pod tabulkou
- `examples/mcp-configs/redmine.json` — config MCP serveru (pouze `REDMINE_HOST` + `REDMINE_API_KEY`; neobsahuje žádné mapovací tabulky)
- Dokumentace balíčku `mcp-server-redmine` (npm) — zda nabízí tool pro čtení workflow/statusů

**Riziko:** Zákazníkova Redmine instance má vlastní stavové workflow (dokument `zadani - projektu.md` zmiňuje 2-stupňovou hierarchii a jednoduché workflow). LLM si mapování `status:In Progress → status_id=2` musí buď pamatovat z tréninku, nebo odhadnout — což je nespolehlivé pro nestandardní stavy jako "For Review" nebo "Blocked".

---

### OTK-1A-03: Podporuje `mcp-server-redmine` čtení a zápis custom fields (vlastní pole)?

**Otázka:** Zákazník v zadání zmiňuje potřebu přídavných polí v Redmine (např. `assignee_type` pro rozlišení člověk vs. agent, `context_file` pro předávání kontextu, `agent_session_id` pro tracking). Má MCP server Redmine schopnost číst a zapisovat custom fields přes Redmine REST API (`/issues/{id}.json` pole `custom_fields`)?

**Kde hledat odpověď:**
- `examples/mcp-configs/redmine.json` — pouze connection config, žádná zmínka o custom fields
- `docs/reference/trackers.md` — žádná sekce Custom Fields pro žádný tracker
- `agents/triage-analyst.md` krok 1 — "Read bug details from issue tracker (summary, description, comments, **custom fields**)" — toto je jediná zmínka custom fields v celém pluginu

**Riziko:** Pokud MCP server custom fields nepodporuje, zákazníkovy plánované workflow prvky (označení ticketu jako "zpracovává agent") nejsou implementovatelné přes standardní pipeline. Triage-analyst sice zmiňuje čtení custom fields, ale není jasné, zda to Redmine MCP skutečně umí.

---

### OTK-1A-04: Jak pipeline zpracovává absenci nativní sub-issue hierarchie, resp. jak funguje Redmine `parent_issue_id`?

**Otázka:** Tabulka Sub-Issue Capabilities v `trackers.md` uvádí Redmine jako "Yes" s parametrem `parent_issue_id: {id}`. Zákazník chce 2-stupňovou hierarchii (epic → task). Zákazníkovo zadání říká, že "agentický vývoj obecně znamená rozbití a zjednodušení komplikované hierarchie epic–feature–us–task". Jak Decomposition pipeline v ceos-agents konkrétně vytvoří sub-tasky v Redmine — přes jaký MCP tool?

**Kde hledat odpověď:**
- `docs/reference/trackers.md` — Sub-Issue Capabilities tabulka
- `skills/fix-bugs/SKILL.md` řádky 140–200 — Decomposition decision sekce
- `core/decomposition-heuristics.md` — logika pro vytváření subtasků
- Dokumentace `mcp-server-redmine` — zda existuje tool `create_issue` s podporou `parent_issue_id`

**Riziko:** I kdyby Redmine API `parent_issue_id` podporuje, MCP server to musí explicitně expozovat jako tool parameter. Pokud ne, decomposition sice proběhne interně, ale sub-tasky se v Redmine nevytvoří.

---

### OTK-1A-05: Pokrývá existující `redmine-rails.md` config template dostatečně non-Rails projekty?

**Otázka:** Existuje jediný Redmine config příklad: `examples/configs/redmine-rails.md` s `bundle exec rails assets:precompile` jako Build command a `bundle exec rspec` jako Test command. Zákazník používá Oracle PL/SQL, nikoliv Rails. Je Automation Config design dostatečně obecný (Build command = libovolný shell příkaz), nebo jsou někde v pipeline předpoklady o Ruby/Rails?

**Kde hledat odpověď:**
- `examples/configs/redmine-rails.md` — celý soubor
- `agents/fixer.md` krok 6 — "Run: build command from Automation Config" — přímo volá nakonfigurovaný příkaz bez interpretace
- `agents/test-engineer.md` krok 2 — "Run test command from Automation Config (Build & Test section)" — totéž
- `core/config-reader.md` — `build.build_command`, `build.test_command` jsou prosté stringy

**Předpoklad (ověřit):** Config je agnostický — Build & Test příkazy jsou shell stringy bez předpokladů o jazyce. Oracle PL/SQL stack by šlo konfigurovat jako:
- Build command: `bash test-app/db/scripts/deploy.sh`
- Test command: `bash test-app/db/scripts/test.sh`

---

### OTK-1A-06: Jak pipeline detekuje dostupnost `mcp-server-redmine` a co se stane, pokud MCP server poběží s neplatným API klíčem?

**Otázka:** MCP pre-flight check (krok 0 v fix-bugs/fix-ticket) ověřuje přítomnost MCP nástrojů s prefixem odpovídajícím `Type`. Jak konkrétně probíhá detekce pro Redmine? Kontroluje plugin jen přítomnost nástroje v tool listu, nebo provádí testovací volání (např. načíst profil uživatele)?

**Kde hledat odpověď:**
- `skills/fix-bugs/SKILL.md` řádky 80–89 — MCP pre-flight check
- `skills/fix-ticket/SKILL.md` řádky 80–85 — identická logika
- `core/mcp-preflight.md` — detailní postup preflight kontroly
- `docs/reference/trackers.md` — MCP Server Detection tabulka (klíčové slovo: `redmine` v `.mcp.json`)

**Riziko:** Pokud preflight jen zkontroluje přítomnost nástroje (ne funkčnost), pipeline se spustí a selže až při prvním reálném volání Redmine API — po případných git operacích a změně stavu ticketu. To může zanechat pipeline v nekonzistentním stavu.

---

### OTK-1A-07: Jaká je podpora pro Redmine webhook notifikace nebo polling pro detekci odpovědí na block komentáře?

**Otázka:** Když agent zablokuje ticket s komentářem (`[ceos-agents] 🔴 Pipeline Block`), jak operátor zjistí, že má odpovědět? A jak `/resume-ticket` detekuje, že byl komentář přidán a pipeline je připravena k obnově? Funguje to přes Redmine MCP polling?

**Kde hledat odpověď:**
- `skills/resume-ticket/SKILL.md` — mechanismus detekce komentářů
- `docs/reference/trackers.md` — PR Description Footer (Redmine: `Refs #{issue_id}`)
- `agents/triage-analyst.md` — Block Comment Template formát

**Relevance:** Zákazník explicitně zmiňuje potřebu "schopnosti lidského zásahu". Pokud resume-ticket spoléhá na manuální spuštění (nikoliv na webhook), je to use-case lidského vstupu, nikoli automatické detekce.

---

## Oblast 1B: Oracle PL/SQL stack

### OTK-1B-01: Je `Build & Test` konfigurace skutečně agnostická pro Oracle PL/SQL shell skripty?

**Otázka:** Zákazníkův stack používá `bash deploy.sh` (Flyway + SQLcl kompilace + INVALID check) a `bash test.sh` (utPLSQL). Tyto příkazy vrací exit kódy standardním způsobem (0 = úspěch). Zpracovávají agenti (fixer, test-engineer) výstup build/test příkazů pouze na základě exit kódu, nebo parsují formát výstupu (očekávají specifický formát jako "X tests passed")?

**Kde hledat odpověď:**
- `agents/fixer.md` kroky 6–7 — "Run build command... If build fails → fix build errors"
- `agents/test-engineer.md` kroky 2 a 5 — "Run test command... Must pass on first try"
- `docs/plans/readmine-project/orasetup/CLAUDE.md` — popis výstupů skriptů (deploy.sh vrací chyby ve formátu ORA-XXXXX)

**Klíčová otázka:** Pokud `deploy.sh` selže s ORA-00942, agent dostane non-zero exit kód a stdout s Oracle error textem. Dokáže fixer parsovat Oracle chybové zprávy stejně jako by parsoval Python traceback nebo TypeScript chyby kompilátoru?

---

### OTK-1B-02: Dokáže `fixer` agent generovat správný Oracle PL/SQL kód bez speciálních instrukcí?

**Otázka:** Fixer je obecný "Senior Developer" bez jazykové specializace. Oracle PL/SQL má specifickou syntaxi: package spec (`.pks`) musí být zkompilován před body (`.pkb`), výjimky se deklarují jako `EXCEPTION; PRAGMA EXCEPTION_INIT(...)`, testy vyžadují utPLSQL anotace (`-- %suite(...)`, `-- %suitepath(...)`). Zachytí fixer tyto konvence z `CLAUDE.md` zákazníkova projektu, nebo potřebuje Agent Override s Oracle-specifickými instrukcemi?

**Kde hledat odpověď:**
- `agents/fixer.md` krok 2 — "Read project conventions from CLAUDE.md (coding style, patterns, naming conventions)"
- `docs/plans/readmine-project/orasetup/CLAUDE.md` — obsahuje explicitní PL/SQL konvence (`.pks` před `.pkb`, výjimky, audit log, utPLSQL anotace)
- `CLAUDE.md` sekce Agent Overrides — mechanismus pro přidání project-specific instrukcí

**Klíčová otázka:** Zákazníkovo `orasetup/CLAUDE.md` je detailní dokumentace stacku. Pokud ho zákazník zkopíruje/odkazuje v projektu CLAUDE.md, má fixer dostatečný kontext? Nebo jsou Oracle specifika natolik vzdálená od typického webového vývoje, že potřebujeme `customization/fixer.md` s explicitními Oracle instrukcemi?

---

### OTK-1B-03: Jak `test-engineer` zpracuje utPLSQL test výstup a rozliší PASS/FAIL?

**Otázka:** utPLSQL vrací výsledky jako:
```
test_app
  Contacts Package Tests (10 tests)
    ✓ Add contact - OK
    X Duplicate email should raise exception (FAILED)
```
s exit kódem 0 nebo 1. Test-engineer je navržen pro "write tests that verify the fix". Jak napíše utPLSQL test package (`.pks` + `.pkb`) se správnými anotacemi, pokud zákazník nemá hotové test template? Spoléhá na existující test soubory jako vzor (krok 4 v agent definici)?

**Kde hledat odpověď:**
- `agents/test-engineer.md` kroky 4–5 — "Follow project test conventions... read existing tests first"
- `docs/plans/readmine-project/orasetup/CLAUDE.md` — konvence utPLSQL testů (anotace, setup procedura)
- `docs/plans/readmine-project/orasetup/SETUP.md` — sekce "Struktura test-app" (vzorové testy ut_contacts_pkg, ut_tasks_pkg)

**Klíčová otázka:** Test-engineer čte existující testy a napodobuje vzory. Pokud projekt má vzorové utPLSQL testy, agent by měl zvládnout psát nové. Ale dvousouborová struktura (`.pks` + `.pkb`) a nutnost kompilovat spec před body je nestandardní — je to zachyceno v konvencích CLAUDE.md?

---

### OTK-1B-04: Je `code-analyst` schopen analyzovat Oracle PL/SQL kód a identifikovat root cause?

**Otázka:** Code-analyst provádí statickou analýzu kódu, mapuje call hierarchy a odhaduje diff rozsah. Oracle PL/SQL nemá typický import/module systém — volání jsou přes package.procedure syntaxi (např. `contacts_pkg.add_contact`). Dokáže code-analyst sledovat závislosti mezi packages, včetně cross-package calls, bez speciálních nástrojů?

**Kde hledat odpověď:**
- `agents/code-analyst.md` — Process sekce, zejména kroky pro mapování call hierarchy
- `docs/plans/readmine-project/orasetup/SETUP.md` — struktura projektu (`.pks`/`.pkb` soubory, `db/packages/`)

**Klíčová otázka:** Code-analyst má přístup k Bash, Read, Glob, Grep — může procházet `.pks`/`.pkb` soubory a grep-ovat cross-package reference. Statická analýza by měla fungovat. Ale detekce "INVALID objects" (kompilační chyby v DB) vyžaduje spuštění `check_errors.sh`, ne jen čtení souborů.

---

### OTK-1B-05: Jak pipeline řeší závislost na běžícím Oracle Docker kontejneru?

**Otázka:** Celý Oracle PL/SQL stack předpokládá běžící `oracle-xe` Docker kontejner (`sudo docker` přístup, kontejner na portu 1521). Pokud kontejner neběží, všechny build/test příkazy selžou. Plugin má `Local Deployment` konfigurační sekci (Start command, Stop command, Health check URL). Je tato sekce vhodná pro Oracle Docker, nebo je primárně navržena pro webové aplikace (výchozí: `docker compose up -d`, health check URL `http://localhost:3000/health`)?

**Kde hledat odpověď:**
- `CLAUDE.md` sekce Local Deployment — dokumentace 6 klíčů konfigurace
- `skills/fix-bugs/SKILL.md` řádky 46–48 — čtení Local Deployment konfigurace
- `core/config-reader.md` — mapování Local Deployment klíčů
- `docs/plans/readmine-project/orasetup/SETUP.md` — Oracle XE spuštění (`sudo docker run`, port 1521, health check neexistuje jako HTTP endpoint)

**Klíčová otázka:** Oracle XE nemá HTTP health check endpoint (pouze TCP port 1521). Deployment-verifier agent pravděpodobně spoléhá na HTTP health check URL. Jak pipeline detekuje, že DB je ready? (`docker logs | grep "DATABASE IS READY TO USE!"` je nestandardní přístup)

---

### OTK-1B-06: Podporuje pipeline `sudo` příkazy pro Docker operace bez interaktivního hesla?

**Otázka:** Zákazníkova dokumentace uvádí: "sudo je vyžadováno pro docker příkazy" (CLAUDE.md orasetup). Příkazy jako `sudo docker exec oracle-xe sqlplus ...` jsou součástí compile.sh a test.sh. Může Claude Code (fixer, test-engineer) spouštět `sudo` příkazy v Bash nástrojích bez interaktivního promptu pro heslo?

**Kde hledat odpověď:**
- `docs/plans/readmine-project/orasetup/SETUP.md` — poznámka o sudo a docker skupině
- `docs/plans/readmine-project/orasetup/CLAUDE.md` — "sudo je vyžadováno pro docker příkazy"

**Klíčová odpověď (z dokumentace):** SETUP.md zmiňuje `sudo usermod -aG docker $USER` jako volitelné. Pokud agent běží v prostředí kde uživatel NENÍ ve skupině docker, `sudo docker` vyžaduje buď passwordless sudo (NOPASSWD v sudoers) nebo přidání do docker skupiny. Toto je infrastrukturní prerekvizita, ne problém pluginu.

---

### OTK-1B-07: Může `reviewer` agent smysluplně recenzovat Oracle PL/SQL kód?

**Otázka:** Reviewer je "Senior Developer" bez jazykové specializace, který recenzuje diff z fixeru. Oracle PL/SQL má specifická rizika: nesprávné COMMIT/ROLLBACK v transakcích, chybějící PRAGMA EXCEPTION_INIT, INVALID objects po kompilaci, performance anti-patterns (implicit cursor vs explicit cursor). Jak reviewer tyto problémy odhalí bez Oracle-specifického kontextu?

**Kde hledat odpověď:**
- `agents/reviewer.md` — Process sekce a Constraints
- `CLAUDE.md` sekce Agent Overrides — mechanismus pro `customization/reviewer.md`
- `docs/plans/readmine-project/ceos-agents-review-report.md` sekce 5.2 — "Self-review bias" jako identifikovaná slabina

**Klíčová otázka:** Je potřeba vytvořit `customization/reviewer.md` s Oracle-specifickými review checklist body (transakční správnost, INVALID objects, utPLSQL test coverage)?

---

### OTK-1B-08: Je Decomposition pipeline použitelná pro Oracle PL/SQL feature, nebo je příliš vázaná na webový vývoj?

**Otázka:** Zákazník chce ukázat "funkční analýza → technická analýza → plán práce → vývoj PL/SQL → testování → dokumentace". Implementační pipeline (implement-feature, decomposition) předpokládá iterace fixer↔reviewer a smoke check (build + test). Je Architect agent schopen vytvořit smysluplný task tree pro PL/SQL feature (package API design, DDL migrace, package body, testy)?

**Kde hledat odpověď:**
- `agents/architect.md` — jak vytváří task tree a `maps_to` vazby
- `skills/implement-feature/SKILL.md` — decomposition pipeline kroky
- `docs/plans/readmine-project/zadani - projektu.md` — popis cíle (funkční analýza, tech analýza, PL/SQL vývoj, testování)

---

## Shrnutí prioritizace výzkumných otázek

| Priorita | Oblast | Otázka | Riziko |
|----------|--------|--------|--------|
| KRITICKÁ | 1B | OTK-1B-05 (Oracle Docker health check) | Pipeline blokuje při start/stop |
| KRITICKÁ | 1A | OTK-1A-02 (status:name → status_id překlad) | Nesprávné stavy ticketů |
| VYSOKÁ | 1A | OTK-1A-03 (custom fields podpora) | Chybí workflow prvky zákazníka |
| VYSOKÁ | 1B | OTK-1B-01 (Build & Test agnostičnost) | Základní fungování pipeline |
| VYSOKÁ | 1B | OTK-1B-02 (Fixer + Oracle PL/SQL) | Kvalita generovaného kódu |
| STŘEDNÍ | 1A | OTK-1A-01 (tracker_id flexibilita) | Nesprávné dotazy na tickety |
| STŘEDNÍ | 1B | OTK-1B-03 (test-engineer + utPLSQL) | Testovací coverage |
| NÍZKÁ | 1A | OTK-1A-06 (MCP preflight hloubka) | Diagnostické info |
| NÍZKÁ | 1B | OTK-1B-06 (sudo Docker) | Infrastrukturní prerekvizita |

---

## Doporučené zdroje pro navazující výzkum

1. `docs/reference/trackers.md` — kompletní Redmine reference
2. `examples/configs/redmine-rails.md` — jediný Redmine config template
3. `examples/mcp-configs/redmine.json` — MCP server konfigurace
4. `docs/plans/readmine-project/orasetup/CLAUDE.md` — Oracle PL/SQL konvence
5. `docs/plans/readmine-project/orasetup/SETUP.md` — kompletní stack dokumentace
6. `agents/fixer.md`, `agents/test-engineer.md` — jak agenti zpracovávají build/test output
7. `core/mcp-preflight.md` — detaily preflight kontroly
8. `core/config-reader.md` — Automation Config parsing kontrakt
9. `CLAUDE.md` sekce Agent Overrides + Local Deployment — extensibility mechanismy
