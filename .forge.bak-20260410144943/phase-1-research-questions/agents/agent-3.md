# Research Agent 3 — Výzkumné otázky
## Oblast 3: Automation Config + Oblast 4: Plugin changes

**Datum:** 2026-04-10
**Kontext:** Onboarding projektu SK kompenzace (Oracle PL/SQL) na ceos-agents v6.4.1
**Tracker:** Redmine (redmine.test.ceosdata.com/projects/ai-dev)
**Stack:** Oracle XE 21c Docker, SQLcl kompilace, Flyway 9.22.3, utPLSQL testy, deploy.sh

---

## Oblast 3: Automation Config — Konkrétní otázky

### 3.1 Issue Tracker sekce — jaké hodnoty?

**Soubor:** `examples/configs/redmine-rails.md`

Existující Redmine šablona obsahuje:
```
| Type | redmine |
| Instance | <your-redmine-instance> |
| Project | <project-identifier> |
| Bug query | project_id=<project-identifier>&status_id=open&tracker_id=<bug-tracker-id> |
```

**Otázky:**
- Jaký je přesný `Project` identifikátor pro `redmine.test.ceosdata.com/projects/ai-dev`? Je to `ai-dev`?
- Jaký je `tracker_id` pro bug tracker v Redmine instanci `ai-dev`? (Nutné ověřit přes Redmine API nebo UI — `tracker_id` pro "Bug" není standardní, liší se per-instance)
- Jaké `State transitions` jsou nakonfigurované v této Redmine instanci? Šablona (`redmine-rails.md`) předpokládá stavy `In Progress`, `Blocked`, `For Review`, `Closed` — jsou tyto stavy dostupné v `ai-dev` projektu?
- Existuje separátní `tracker_id` pro feature requesty vs. bugy v `ai-dev`? Pokud ano, jaký query použít pro `Feature query` (potřebné pro feature pipeline)?

### 3.2 Source Control sekce — Branch naming pro Redmine IDs

**Soubor:** `examples/configs/redmine-rails.md`, `CLAUDE.md` (Config Contract sekce)

Šablona (`redmine-rails.md`) navrhuje `fix/{issue}-{short-description}`.

**Otázky:**
- Používá Redmine v projektu `ai-dev` numerické ID (např. `#42`) nebo textové ID? Formát větve by měl odpovídat — např. `fix/42-fix-description` vs. `fix/ai-dev-42-fix-description`.
- Má projekt SK kompenzace konvenci pro branch naming, která se liší od šablony? (např. `feature/`, `hotfix/` prefixy pro různé typy ticketů)
- Jaký je `Remote` (owner/repo) — předpokládá se Gitea repo na stejné instanci nebo jiný SC provider? (kritické pro `Source Control` sekci)

### 3.3 Build & Test sekce — Oracle stack příkazy

**Soubory:** `agents/fixer.md` (krok 6–7), `agents/test-engineer.md` (krok 2, 5), `docs/plans/readmine-project/orasetup/CLAUDE.md`

Z `orasetup/CLAUDE.md` jsou k dispozici tyto příkazy:
- Kompilace: `bash db/scripts/compile_all.sh`
- Deploy (Flyway + kompilace + validace): `cd test-app && bash db/scripts/deploy.sh`
- Testy: `bash test-app/db/scripts/test.sh`

Fixer (`agents/fixer.md`, krok 6) spouští `Build command`, test-engineer (`agents/test-engineer.md`, krok 2) spouští `Test command`.

**Otázky:**
- Co by měl být `Build command` pro Oracle stack? Možnosti:
  - `bash db/scripts/compile_all.sh` (pouze kompilace) — rychlé, ale nespouští Flyway migrace
  - `cd test-app && bash db/scripts/deploy.sh` (plný deploy) — pomalejší, ale zaručuje konzistentní stav DB
  - Který přístup je vhodný pro iterativní fixer↔reviewer smyčku (max 5 iterací)?
- Co by měl být `Test command`? `bash test-app/db/scripts/test.sh` — ale vyžaduje funkční DB připojení. Jak test-engineer (`agents/test-engineer.md`) pozná, že Oracle Docker kontejner běží? Měl by `Test command` obsahovat pre-check na Docker?
- Je `Verify command` (volitelný, spouští se po merge PR dle `CLAUDE.md`) vhodný pro Oracle deploy? Např. spustit `deploy.sh` po merge jako smoke test produkčního prostředí?
- Cesta `test-app/db/scripts/test.sh` vs. `db/scripts/test.sh` — liší se pro různé prostředí? `orasetup/CLAUDE.md` uvádí obě variace.

### 3.4 Local Deployment sekce — potřebná pro Oracle Docker?

**Soubor:** `CLAUDE.md` (Optional sections tabulka — Local Deployment: Type, Start command, Stop command, Health check URL, Health check timeout, Ports)

**Otázky:**
- Je `Local Deployment` sekce nutná, pokud Oracle Docker kontejner (`oracle-xe`) musí běžet před spuštěním build/test příkazů?
  - `Start command`: `sudo docker start oracle-xe` ?
  - `Stop command`: nepovinné (nechceme zastavovat DB)
  - `Health check URL`: Oracle nemá HTTP endpoint — lze použít TCP check na port 1521? Současná implementace deployment-verifier předpokládá HTTP health check — funguje TCP?
  - `Ports`: `1521` (Oracle listener)
- Alternativa: Přidat Docker pre-check přímo do `Build command` skriptu a `Local Deployment` sekci vynechat. Která varianta je preferovaná?
- `sudo` je vyžadováno pro `docker` příkazy (dle `orasetup/CLAUDE.md`) — jak to ovlivňuje agenty? Fixer a test-engineer spouštějí příkazy přímo — mají oprávnění na `sudo docker`?

### 3.5 PR Rules sekce

**Soubor:** `examples/configs/redmine-rails.md`

**Otázky:**
- Jaké labely jsou dostupné v cílovém Gitea/SC repozitáři? Šablona navrhuje `ForReview` — existuje tato konvence v projektu?
- Má Redmine integrace s PR labely (obousměrná synchronizace stavu), nebo jsou labely pouze pro SC vrstvu?

---

## Oblast 4: Plugin changes — Konkrétní otázky

### 4.1 `/template` skill — chybí Oracle PL/SQL profil?

**Soubor:** `skills/template/SKILL.md` (řádky 22–36)

Aktuální seznam šablon v `/ceos-agents:template list`:
```
| redmine-rails | Ruby on Rails | Redmine |
```
Chybí: Oracle PL/SQL + Redmine kombinace.

**Otázky:**
- Je nutné přidat nový template `examples/configs/redmine-oracle-plsql.md` před onboardingem, nebo lze projekt nakonfigurovat manuálně bez šablony?
- Pokud ano, co musí šablona obsahovat navíc oproti `redmine-rails.md`?
  - `Build command` pro SQLcl kompilaci
  - `Test command` pro utPLSQL
  - `Local Deployment` sekce pro Oracle Docker
  - Komentáře o `sudo` požadavcích a Flyway verzi
- Priorita: Je vytvoření šablony blocker pro onboarding, nebo nice-to-have?

### 4.2 Agenti — potřebují Oracle-specifické znalosti?

**Soubory:** `agents/fixer.md` (celý), `agents/test-engineer.md` (celý)

**Otázka — fixer.md:**
- Fixer (`agents/fixer.md`, krok 5 RED fáze) předpokládá standardní test framework. Pro utPLSQL platí jiné konvence:
  - Soubory: `ut_<package>.pks` a `ut_<package>.pkb` (ne `test_*.py` nebo `*.test.ts`)
  - Spuštění: `echo "EXEC ut.run('ut_contacts_pkg');" | sqlcl -S ...`
  - Anotace: `-- %suite`, `-- %suitepath`, `-- %rollback(manual)`
  - Výstup chyb je Oracle specifický: `ORA-XXXXX`, `PLS-XXXXX`, `Package INVALID`
  - Potřebuje fixer tato pravidla explicitně znát, nebo je dostatečné mít je v `orasetup/CLAUDE.md` (Agent Overrides mechanismus)?

**Otázka — test-engineer.md:**
- Test-engineer (`agents/test-engineer.md`, krok 4) hledá existující test soubory via Glob a "follows the same pattern". Pro Oracle:
  - Pattern: `db/tests/ut_*.pks` a `db/tests/ut_*.pkb` — zvládne test-engineer tento pattern bez explicitních instrukcí?
  - Arrange-Act-Assert vzor se v PL/SQL píše jinak než v OOP jazycích — přenese agent správně tento pattern na PL/SQL `PROCEDURE` strukturu s `ut_expect`?
  - Constraint "NEVER write flaky tests — no external service calls" koliduje s tím, že utPLSQL testy JSOU volání databáze. Jak tuto kolizi řešit?

**Otázka — Agent Overrides:**
- Mechanismus `Agent Overrides` (`CLAUDE.md`, sekce Agent Overrides) umožňuje přidat `customization/fixer.md` a `customization/test-engineer.md` s Oracle-specifickými instrukcemi.
- Je toto dostatečné pro první iteraci, nebo je nutná úprava samotných agent definic v `agents/`?
- Konkrétně: Stačí do `customization/fixer.md` přidat instrukce o SQLcl kompilaci, `check_errors.sh`, ORA chybových výstupech a pořadí kompilace (spec před body)?

### 4.3 Oddělenost agentů (agent-process separation) — nutné před onboardingem?

**Soubory:** `CLAUDE.md` (Architecture sekce), `docs/plans/roadmap.md` (pokud obsahuje zmínku)

**Otázky:**
- Je "agent-process separation" blocker pro onboarding Oracle projektu, nebo lze pipeline provozovat bez ní?
- Konkrétně: Fixer a test-engineer spouštějí shell příkazy (`build command`, `test command`) přímo v procesu agenta. Pro Oracle Docker to znamená, že agent musí mít `sudo` oprávnění. Je toto bezpečnostní riziko, které blokuje onboarding?
- Alternativa: Přidat wrapper skript `db/scripts/build.sh` a `db/scripts/run-tests.sh`, které interně řeší `sudo` — agenti tak nemusí vědět o `sudo` požadavku. Je toto dostatečné?

### 4.4 Minimální sada změn pro odblokování onboardingu

**Soubory:** `examples/configs/redmine-rails.md`, `skills/template/SKILL.md`, `agents/fixer.md`, `agents/test-engineer.md`, `CLAUDE.md`

Na základě analýzy výše — navrhovaný minimální set změn:

**Otázky k validaci prioritizace:**
1. **Nová šablona** `examples/configs/redmine-oracle-plsql.md` — nutná pro `/ceos-agents:template` + onboard wizard. Blocker nebo nice-to-have?
2. **Agent Overrides soubory** v projektu SK kompenzace (`customization/fixer.md`, `customization/test-engineer.md`) — bez změny plugin kódu. Dostatečné pro Oracle specifika?
3. **Local Deployment sekce** v Automation Config — nutná pro Oracle Docker pre-check, nebo lze řešit v build skriptu?
4. **Žádná změna v `agents/`** — Oracle specifika pokryjí Agent Overrides. Je tato hypotéza správná, nebo existuje případ, kdy Agent Overrides nestačí (např. constraint v `agents/test-engineer.md` o "no external service calls")?
5. **`/onboard` skill** (`skills/onboard/SKILL.md`) — zvládne průvodce vygenerovat správný config pro Oracle stack, nebo předpokládá webový/aplikační server s HTTP health endpointem?

---

## Shrnutí priorit výzkumných otázek

| Priorita | Otázka | Soubor |
|----------|--------|--------|
| KRITICKÁ | Jaký je přesný Bug query pro Redmine `ai-dev` (tracker_id)? | `examples/configs/redmine-rails.md` |
| KRITICKÁ | Build command: `compile_all.sh` nebo `deploy.sh`? | `agents/fixer.md`, `orasetup/CLAUDE.md` |
| KRITICKÁ | Stačí Agent Overrides pro Oracle specifika, nebo nutná změna agentů? | `agents/fixer.md`, `agents/test-engineer.md` |
| VYSOKÁ | Je Local Deployment sekce nutná pro Oracle Docker? | `CLAUDE.md` Config Contract |
| VYSOKÁ | Je nutná nová šablona `redmine-oracle-plsql.md`? | `skills/template/SKILL.md` |
| STŘEDNÍ | Jak řešit `sudo docker` oprávnění pro agenty? | `orasetup/CLAUDE.md` |
| NÍZKÁ | Agent-process separation — blocker nebo future enhancement? | `CLAUDE.md` Architecture |
