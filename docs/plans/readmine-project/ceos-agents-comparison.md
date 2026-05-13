# ceos-agents — Srovnání s konkurenčními nástroji

> **Datum:** 2026-04-07
> **Verze ceos-agents:** dle aktuální main větve
> **Metodika:** Každá funkce je hodnocena procentuálně (0–100 %), kde 100 % = plná podpora podle definice ceos-agents. Divergence je popsána v poznámce.

---

## Srovnávané nástroje

| Nástroj | Typ | Cena | Popis |
|---------|-----|------|-------|
| **Devin 2.0** (Cognition AI) | Komerční, cloud | od $20/měsíc | Autonomní AI softwarový inženýr, plný prohlížeč + shell sandbox |
| **GitHub Copilot Coding Agent** | Komerční, cloud | součást Copilot Pro+/Enterprise | Agent přiřaditelnný přímo k GitHub Issues, spouští se přes GitHub Actions |
| **OpenHands** (All Hands AI) | Open-source | zdarma (self-host) / placený cloud | Model-agnostická platforma pro AI agenty, Docker sandbox, SDK pro customizaci |
| **BMAD-METHOD** (bmad-code-org) | Open-source | zdarma (MIT) | AI-driven agile development framework; 12+ domain-expert agentů (PM, Architect, Dev, UX…), 34+ workflows, model-agnostický, 43.9K GitHub stars |

---

## Srovnávací tabulka

### 1. Architektura pipeline

| Funkce | ceos-agents | Devin 2.0 | GH Copilot Agent | OpenHands | BMAD-METHOD | Poznámka k divergenci |
|--------|:-----------:|:---------:|:----------------:|:---------:|:-----------:|----------------------|
| **Multi-agentní pipeline s pojmenovanými fázemi** | 100 % | 25 % | 20 % | 55 % | 40 % | Devin a Copilot jedou v jedné session bez explicitních fází; OpenHands kompozici podporuje, ale bez pevného pipeline kontraktu; BMAD má 4 pojmenované fáze (analysis→plan→solutioning→implementation), ale workflow triggeruje uživatel ručně — žádná end-to-end automatizace |
| **Přeskočení / přidání fází (pipeline profiles)** | 100 % | 0 % | 0 % | 15 % | 20 % | Žádný z konkurentů nenabízí deklarativní skip/extra stages config; OpenHands umožňuje SDK-level kompozici, ale bez YAML/config kontraktu; BMAD umožňuje volbu konkrétních skills, ale nemá formální skip/add config |
| **Specializované modely per fáze** (opus/sonnet/haiku dle role) | 100 % | 50 % | 30 % | 80 % | 70 % | Devin podporuje více LLM, ale nealokuje různé modely pro různé role (reviewer vs. publisher); Copilot model per fázi nepodporuje; OpenHands je model-agnostický, alokaci per agent je možná, ale není standardizována v pipeline; BMAD je také model-agnostický (Claude, GPT, Gemini), per-role alokace možná, ale nestandardizovaná |
| **Orchestrace přes config soubor** | 100 % | 0 % | 0 % | 0 % | 30 % | Ostatní nástroje nemají ekvivalent deklarativní konfigurace pipeline v CLAUDE.md; Devin/Copilot konfiguraci dělají přes UI nebo API; BMAD používá YAML project config — koncept přítomen, ale není pipeline-automation config |
| **Retry limity konfigurovatelné per typ operace** | 100 % | 10 % | 5 % | 35 % | 15 % | Devin nemá uživateli konfigurovatelné retry per fázi; Copilot retry deleguje na GitHub Actions; OpenHands má retry na LLM vrstvě (3x), ne na úrovni pipeline fází; BMAD má HALT podmínky a max-attempt logiku v workflows, ale bez konfigurovatelných retry limitů |

### 2. Integrace issue trackeru

| Funkce | ceos-agents | Devin 2.0 | GH Copilot Agent | OpenHands | BMAD-METHOD | Poznámka k divergenci |
|--------|:-----------:|:---------:|:----------------:|:---------:|:-----------:|----------------------|
| **Šíře podpory trackerů** (YouTrack, GitHub, Jira, Linear, Gitea, Redmine) | 100 % | 35 % | 45 % | 30 % | 0 % | Devin: Jira + Linear; Copilot: GitHub Issues, Jira, Azure Boards, Linear, Raycast; OpenHands: GitHub + GitLab (Jira ve vývoji); BMAD žádný issue tracker neintegruje — stories jsou markdown soubory v repozitáři |
| **Automatické přechody stavů issue** (In Progress → In Review → Done) | 100 % | 20 % | 35 % | 15 % | 0 % | Copilot mění GitHub status, ale nezná multi-tracker state machine; Devin aktualizuje Jira/Linear částečně; OpenHands stav nespravuje; BMAD ukládá status do frontmatter story souboru — bez propojení na externí tracker |
| **Zápis AC zpět do issue trackeru** (spec-analyst writeback) | 100 % | 0 % | 0 % | 0 % | 0 % | Unikátní funkce ceos-agents; žádný z konkurentů automaticky nepíše extrahovaná AC zpět do ticketu; BMAD ukládá AC do story souborů lokálně v repozitáři |
| **Čtení kontextu z issue při startu** | 100 % | 85 % | 90 % | 70 % | 10 % | Devin/Copilot mají přímé propojení s issue UI; OpenHands vyžaduje ruční předání URL; BMAD čte story soubory z repozitáře, nikoli z externího trackeru |

### 3. Automatizace opravy bugů

| Funkce | ceos-agents | Devin 2.0 | GH Copilot Agent | OpenHands | BMAD-METHOD | Poznámka k divergenci |
|--------|:-----------:|:---------:|:----------------:|:---------:|:-----------:|----------------------|
| **Plný bug-fix pipeline** (triage→analyst→fix→review→test→publish) | 100 % | 65 % | 55 % | 70 % | 30 % | Devin pokrývá kroky, ale bez explicitního triage/review agenta; Copilot postrádá dedikovaný review a triage krok; OpenHands má dobré SWE-bench výsledky, ale bez strukturovaných fází; BMAD má `bmad-dev-story` a `bmad-quick-dev`, ale bez triage, code-analyst nebo publisher — pipeline není automatizovaný end-to-end |
| **Triage s odhadem komplexity a AC extrakcí** | 100 % | 15 % | 10 % | 10 % | 15 % | Devin vytváří plán, ale neextrahuje AC strukturovaně; Copilot žádný triage krok nemá; BMAD nemá dedikovaný triage agent — AC jsou definovány člověkem v story souboru předem, ne extrahovány automaticky z bug reportu |
| **Dedikovaný code-analyst** (impact zone, call hierarchy) | 100 % | 20 % | 0 % | 30 % | 15 % | Devin interně analyzuje kód, ale ne jako separátní read-only agent; OpenHands používá obecné browsing/grep schopnosti; BMAD `bmad-agent-analyst` existuje, ale zaměřuje se na byznys analýzu, ne na technický impact code change |
| **Reproducer agent** (Playwright reprodukce před fixem) | 100 % | 35 % | 0 % | 40 % | 0 % | Devin má prohlížeč a může reprodukovat, ale bez dedikovaného pipeline kroku; Copilot nemá browser krok; OpenHands má browser access; BMAD toto nepodporuje |
| **Fixer ↔ Reviewer iterace** s limitem počtu kol | 100 % | 30 % | 15 % | 25 % | 40 % | Devin a Copilot nemají explicitní fixer↔reviewer smyčku s konfigurovatelným limitem; OpenHands nemá dedikovaný reviewer agent; BMAD má `bmad-code-review` s detekcí resumption a dev-story prioritizuje review feedback, ale bez konfigurovatelného limitu kol |

### 4. Implementace features

| Funkce | ceos-agents | Devin 2.0 | GH Copilot Agent | OpenHands | BMAD-METHOD | Poznámka k divergenci |
|--------|:-----------:|:---------:|:----------------:|:---------:|:-----------:|----------------------|
| **Spec-driven feature pipeline** (spec-analyst→architect→fixer→test→publish) | 100 % | 20 % | 10 % | 20 % | 75 % | Ostatní tři nástroje nemají spec-driven pipeline jako first-class citizen; Devin pracuje s user stories v ticketu, ale bez spec lifecycle; BMAD je zde nejsilnější alternativou: PRD → epics/stories s AC → architect → TDD implementace — chybí automatizovaný publish a vazba na issue tracker |
| **Architekt agent** (task tree s maps_to AC) | 100 % | 15 % | 0 % | 20 % | 80 % | Devin vytváří plán interně, ale bez traceability AC↔subtask; Copilot nearchitekturuje; OpenHands nemá dedicated architect agent; BMAD `bmad-agent-architect` + `bmad-create-architecture` jsou plnohodnotné, ale chybí strojově zpracovatelné maps_to pole |
| **Dekompozice komplexních issues** (NEEDS_DECOMPOSITION) | 100 % | 35 % | 5 % | 30 % | 65 % | Devin breakuje úlohy interně bez explicitního signálu; Copilot dekompozici nepodporuje; OpenHands má základní task breakdown; BMAD `bmad-create-epics-and-stories` řeší dekompozici jako first-class citizen (epic → stories dle user value), ale bez NEEDS_DECOMPOSITION signálu v automatizovaném pipeline |
| **AC fulfillment check per fáze** (reviewer + acceptance-gate) | 100 % | 10 % | 5 % | 5 % | 40 % | Unikátní funkce ceos-agents u prvních třech alternativ — nekontrolují plnění AC na každé fázi; BMAD dev-story nekompletuje story bez splnění AC a `bmad-code-review` zahrnuje AC review, ale chybí dedikovaný acceptance-gate agent s kódovým důkazem |

### 5. Scaffolding projektů

| Funkce | ceos-agents | Devin 2.0 | GH Copilot Agent | OpenHands | BMAD-METHOD | Poznámka k divergenci |
|--------|:-----------:|:---------:|:----------------:|:---------:|:-----------:|----------------------|
| **Plný scaffold pipeline** (spec-writer↔reviewer→scaffolder→validate→git→features) | 100 % | 30 % | 10 % | 25 % | 15 % | Devin může vygenerovat projekt, ale bez spec lifecycle a validation pipeline; Copilot scaffold nepodporuje; OpenHands může scaffoldovat, ale bez pipeline fází; BMAD nemá dedikovaný scaffold pipeline — `bmad-generate-project-context` generuje kontext, ale ne spustitelný skeleton |
| **Spec složka** (spec/README, architecture, epics) jako single source of truth | 100 % | 0 % | 0 % | 0 % | 50 % | Unikátní pro ceos-agents u Devina, Copilotu a OpenHands; BMAD ukládá PRD, architecture docs a stories do repozitáře — filosofie je podobná, ale není to formalizovaná `spec/` složka jako single source of truth |
| **Spec-writer ↔ spec-reviewer iterace** | 100 % | 0 % | 0 % | 0 % | 30 % | Unikátní automatická smyčka u ceos-agents; Devin/Copilot/OpenHands nemají ekvivalent; BMAD má `bmad-create-prd` + `bmad-validate-prd` + `bmad-edit-prd` — iterativní workflow existuje, ale je manuálně triggerovaný, ne automatická smyčka |
| **Scorecard a validace výsledku scaffold** | 100 % | 10 % | 0 % | 15 % | 0 % | Ostatní bez strukturovaného scorecards; BMAD nemá ekvivalent quality scorecard pro výsledek scaffoldu |

### 6. Kvalita kódu a testování

| Funkce | ceos-agents | Devin 2.0 | GH Copilot Agent | OpenHands | BMAD-METHOD | Poznámka k divergenci |
|--------|:-----------:|:---------:|:----------------:|:---------:|:-----------:|----------------------|
| **Build & test smoke check** po každém fixu | 100 % | 75 % | 80 % | 70 % | 60 % | Devin spouští testy autonomně; Copilot přes Actions; OpenHands spouští testy, ale bez retry per fázi; BMAD dev-story zahrnuje red-green-refactor cyklus a testy musí projít před dokončením tasku, ale bez automatického smoke check per pipeline krok |
| **Dedikovaný test-engineer agent** (píše unit testy) | 100 % | 40 % | 25 % | 40 % | 50 % | Devin a OpenHands testy píší jako součást obecné session, ne jako separátní agent; BMAD dev-story explicitně vyžaduje TDD, ale unit test writing není oddělený agent — je součástí dev-story procesu |
| **E2E test engineer** (Playwright/Cypress) | 100 % | 45 % | 35 % | 50 % | 55 % | Devin může E2E testy psát; Copilot via Actions; OpenHands má browser; žádný z prvních tří nemá dedikovaný pipeline krok s agentem; BMAD `bmad-qa-generate-e2e-tests` je dedikovaný workflow s detekcí frameworku (Playwright, Vitest, Cypress…) a ověřením průchodu — není součástí automatického pipeline, ale silnější než zbylé alternativy |
| **Browser verifier** (replay + screenshot + exploration) | 100 % | 55 % | 0 % | 50 % | 15 % | Devin má plný browser sandbox; OpenHands má browser; Copilot prohlížeč nemá; žádný nemá strukturovaný verification protocol s max_pages/exploration config; BMAD nemá browser verification krok |
| **Acceptance gate agent** (read-only AC verification s code evidence) | 100 % | 0 % | 0 % | 0 % | 35 % | Unikátní pro ceos-agents u Devina, Copilotu a OpenHands; BMAD dev-story nekompletuje story bez splnění AC, ale chybí dedikovaný read-only gate agent s explicitním kódovým důkazem jako separátní pipeline krok |

### 7. Správa selhání a rollback

| Funkce | ceos-agents | Devin 2.0 | GH Copilot Agent | OpenHands | BMAD-METHOD | Poznámka k divergenci |
|--------|:-----------:|:---------:|:----------------:|:---------:|:-----------:|----------------------|
| **Rollback agent** (revert git + komentář do trackeru) | 100 % | 10 % | 5 % | 10 % | 0 % | Devin vyžaduje manuální zásah při selhání; Copilot nemá rollback; OpenHands nemá dedikovaný rollback krok; BMAD nemá žádný rollback mechanismus |
| **Block comment s machine-parseable prefixem** | 100 % | 20 % | 30 % | 15 % | 0 % | Ostatní zanechávají komentáře, ale bez strukturovaného formátu pro /resume-ticket; BMAD nemá block comment protokol — workflow HALT je interní stav, ne komentář v issue trackeru |
| **Konfigurovatelné chování na selhání** (on_block: comment/skip/fail) | 100 % | 0 % | 10 % | 15 % | 10 % | Devin nemá konfigurovatelné on_block chování; Copilot deleguje na Actions; OpenHands nemá tuto config úroveň; BMAD má HALT podmínky (explicit stop points) v workflows, ale bez konfigurovatelného on_block chování |
| **Max blocked per run limit** | 100 % | 0 % | 0 % | 0 % | 0 % | Unikátní pro ceos-agents |

### 8. Customizace a rozšiřitelnost

| Funkce | ceos-agents | Devin 2.0 | GH Copilot Agent | OpenHands | BMAD-METHOD | Poznámka k divergenci |
|--------|:-----------:|:---------:|:----------------:|:---------:|:-----------:|----------------------|
| **Hooks** (pre/post fix, pre/post publish) | 100 % | 20 % | 65 % | 45 % | 20 % | Copilot má GitHub Actions jako hooky; Devin API umožňuje integraci, ale ne deklarativní hooky; OpenHands SDK umožňuje hooky programaticky; BMAD nemá explicitní pipeline hooky — `bmad-correct-course` umožňuje korekci za běhu, ale není totéž |
| **Custom agents** (post-fix agent, pre-publish agent) | 100 % | 10 % | 30 % | 60 % | 70 % | OpenHands má SDK pro vlastní agenty; Copilot rozšiřitelný přes Actions; Devin toto nepodporuje nativně; BMAD má `bmad-module-template` + `bmad-plugins-marketplace` — jeden z nejsilnějších ekosystémů rozšíření (game dev, creative, web components) |
| **Agent overrides** (per-project instrukce per agent) | 100 % | 0 % | 0 % | 25 % | 40 % | OpenHands SDK umožňuje systémový prompt override; Devin a Copilot nemají per-agent override z konfiguračního souboru; BMAD umožňuje project config YAML s parametry pro agenty, ale bez souborů per-agent ve složce `customization/` |
| **Konfigurace bez externích závislostí** | 100 % | 0 % | 0 % | 0 % | 50 % | ceos-agents je pure markdown plugin; ostatní vyžadují cloud účty, SDK nebo GitHub repo settings; BMAD je MIT open-source a markdown-based, ale vyžaduje `npx bmad-method install` + Node.js v20+ + Python 3.10+ + uv |
| **Šablony konfigurace per tech stack** | 100 % | 0 % | 0 % | 10 % | 20 % | Ostatní nemají ekvivalent /template příkazu; BMAD modulární ekosystém umožňuje stack-specifické moduly, ale nemá /template command |

### 9. Paralelní zpracování

| Funkce | ceos-agents | Devin 2.0 | GH Copilot Agent | OpenHands | BMAD-METHOD | Poznámka k divergenci |
|--------|:-----------:|:---------:|:----------------:|:---------:|:-----------:|----------------------|
| **Git worktrees pro batch zpracování** | 100 % | 0 % | 0 % | 15 % | 0 % | Devin má paralelní sessions (ne worktrees); Copilot může zpracovávat více issues v oddělených Actions jobs; OpenHands scale-out přes SDK; BMAD zpracovává sekvenčně per story, bez worktrees |
| **Konfigurovatelný batch size a base path** | 100 % | 0 % | 0 % | 0 % | 0 % | Unikátní pro ceos-agents |

### 10. Observabilita a metriky

| Funkce | ceos-agents | Devin 2.0 | GH Copilot Agent | OpenHands | BMAD-METHOD | Poznámka k divergenci |
|--------|:-----------:|:---------:|:----------------:|:---------:|:-----------:|----------------------|
| **Pipeline analytics** (success rate, per-agent effectiveness, failure patterns) | 100 % | 25 % | 40 % | 20 % | 20 % | Devin má session historii; Copilot GitHub Insights; OpenHands základní logy; žádný nemá per-agent effectiveness metriky; BMAD má `bmad-sprint-status` a `bmad-retrospective` pro sprint tracking, ale bez per-agent metrik |
| **HTML dashboard** (pipeline state, blocked issues, statistiky) | 100 % | 30 % | 50 % | 10 % | 10 % | Copilot má GitHub UI; Devin má session přehled; OpenHands nemá ekvivalent dashboardu; BMAD sprint status je markdown výstup bez HTML dashboardu |
| **Konfigurovatelné metrické období a output** | 100 % | 0 % | 20 % | 0 % | 0 % | Ostatní nemají konfigurovatelný reporting period |
| **State soubory per run** (.ceos-agents/state.json, pipeline.log) | 100 % | 0 % | 30 % | 25 % | 30 % | Copilot má Actions logy; OpenHands logy session; Devin má historii v UI; žádný nemá lokální state soubory v repo; BMAD ukládá stav do frontmatter story souboru (Status, Tasks checkboxy, Dev Agent Record) — bez state.json a pipeline.log |

### 11. PR a source control

| Funkce | ceos-agents | Devin 2.0 | GH Copilot Agent | OpenHands | BMAD-METHOD | Poznámka k divergenci |
|--------|:-----------:|:---------:|:----------------:|:---------:|:-----------:|----------------------|
| **PR s šablonou a labely** | 100 % | 65 % | 90 % | 70 % | 20 % | Copilot je nativně GitHub — nejlepší PR integrace; Devin PR vytváří dobře; OpenHands podporuje GitHub/GitLab PR; BMAD nemá dedikovaný publisher krok — `bmad-dev-story` nastaví story status na "review" jako signál pro člověka, který PR vytvoří ručně |
| **Branch naming konvence z konfigurace** | 100 % | 20 % | 40 % | 30 % | 10 % | Copilot naming částečně; ostatní branch pojmenování nekonfigurují; BMAD branch naming nekonfiguruje |
| **Verify command po merge** (re-open issue při selhání) | 100 % | 0 % | 20 % | 0 % | 0 % | Copilot může spouštět post-merge Actions, ale ne re-open issue; ostatní verify po merge nepodporují; BMAD toto nepodporuje |
| **Notifikace přes webhook** (na pipeline events) | 100 % | 60 % | 70 % | 20 % | 0 % | Devin má Slack integraci; Copilot GitHub notifikace; OpenHands omezené notifikace; BMAD nemá webhook notifikace |

### 12. Nasazení a deployment

| Funkce | ceos-agents | Devin 2.0 | GH Copilot Agent | OpenHands | BMAD-METHOD | Poznámka k divergenci |
|--------|:-----------:|:---------:|:----------------:|:---------:|:-----------:|----------------------|
| **Local deployment verifier** (start/stop/health check) | 100 % | 50 % | 35 % | 55 % | 0 % | Devin může spustit aplikaci lokálně; Copilot přes Actions; OpenHands může spustit v Docker sandboxu; BMAD nemá deployment verification krok |
| **Self-hosted / bez externích závislostí** | 100 % | 0 % | 0 % | 90 % | 75 % | OpenHands je open-source a self-hostable; ceos-agents je pure markdown plugin v Claude Code; Devin a Copilot jsou cloud-only; BMAD je MIT a self-hostable, ale vyžaduje Node.js v20+ + Python 3.10+ + uv (ne zero-dependency) |
| **Security sandbox** | 70 % | 95 % | 90 % | 90 % | 30 % | ceos-agents spoléhá na Claude Code permissions model — vědomý trade-off (jednoduchost vs. izolace); ostatní mají Docker/Actions/VM sandbox; BMAD stejně jako ceos-agents spoléhá na IDE permissions model |

### 13. Cena a licencování

| Aspekt | ceos-agents | Devin 2.0 | GH Copilot Agent | OpenHands | BMAD-METHOD |
|--------|:-----------:|:---------:|:----------------:|:---------:|:-----------:|
| **Základní cena** | Zdarma (plugin) | $20/měsíc (Core) | ~$39/měsíc (Pro+) | Zdarma (self-host) | Zdarma |
| **Platba za compute** | Claude API (dle spotřeby) | $2.25/ACU | Premium requests | Dle modelu | Claude/GPT/Gemini API |
| **Licence** | Proprietární | Proprietární | Proprietární | MIT | MIT |
| **Vendor lock-in** | Anthropic Claude Code | Cognition AI cloud | GitHub ekosystém | Žádný (open source) | Žádný — model-agnostický |

---

## Agregované skóre per kategorie

| Kategorie | ceos-agents | Devin 2.0 | GH Copilot Agent | OpenHands | BMAD-METHOD |
|-----------|:-----------:|:---------:|:----------------:|:---------:|:-----------:|
| Pipeline architektura | **100 %** | 26 % | 11 % | 39 % | 35 % |
| Integrace issue trackeru | **100 %** | 39 % | 45 % | 31 % | 3 % |
| Bug-fix automatizace | **100 %** | 47 % | 36 % | 47 % | 20 % |
| Feature implementace | **100 %** | 20 % | 4 % | 19 % | **65 %** |
| Scaffolding projektů | **100 %** | 10 % | 3 % | 10 % | 24 % |
| Kvalita a testování | **100 %** | 43 % | 28 % | 45 % | 43 % |
| Failure handling & rollback | **100 %** | 8 % | 11 % | 10 % | 3 % |
| Customizace & rozšiřitelnost | **100 %** | 6 % | 19 % | 28 % | 40 % |
| Paralelní zpracování | **100 %** | 0 % | 0 % | 8 % | 0 % |
| Observabilita & metriky | **100 %** | 14 % | 25 % | 14 % | 15 % |
| PR & source control | **100 %** | 36 % | 55 % | 30 % | 8 % |
| Nasazení & deployment | **100 %** | 33 % | 33 % | 78 % | 35 % |
| **Průměr** | **100 %** | **24 %** | **23 %** | **30 %** | **24 %** |

---

## Shrnutí

### Kde ceos-agents dominuje (funkce bez ekvivalentu v konkurenci)

- **AC-driven pipeline** — extrakce, zápis zpět do trackeru, fulfillment check na každé fázi, acceptance-gate agent
- **Spec-driven scaffolding** — plný životní cyklus spec (writer↔reviewer), spec složka jako single source of truth, scorecard
- **Rollback agent** — automatický revert git stavu s machine-parseable komentářem pro /resume-ticket
- **Block comment protokol** — strukturovaný formát pro strojové zpracování, max_blocked_per_run limit
- **Agent overrides** — per-project instrukce per agent z konfiguračního souboru
- **Pipeline profiles** — deklarativní skip/extra stages bez změny kódu
- **Git worktrees** — konfigurovatelný batch processing
- **Verify command po merge** — re-open issue při selhání post-merge verifikace
- **Nulové závislosti** — pure markdown plugin, žádný cloud, žádný SDK

### Kde konkurence dominuje

- **Devin 2.0**: Lepší sandbox izolace (VM + browser), Slack integrace, vyšší autonomie na nestrukturovaných úlohách, multi-LLM flexibilita
- **GitHub Copilot Agent**: Nativní GitHub integrace (PR, Issues, Actions), nejlepší UX pro GitHub-centric týmy, GitHub Insights
- **OpenHands**: Open-source (MIT), model-agnostický, SDK pro pokročilou customizaci, Docker sandbox, nejlepší SWE-bench benchmark výsledky (72 % na Verified)
- **BMAD-METHOD**: Nejsilnější spec-driven feature pipeline z alternativ (PRD + UX + architekt + epics/stories s AC + TDD), pluginový ekosystém (43.9K stars, marketplace), model-agnostický (Claude/GPT/Gemini), Party Mode pro multi-agent diskuse; dominuje v kategorii Feature implementace (65 % vs. max 20 % ostatních alternativ)

### BMAD-METHOD — detailní profil

| Dimenze | Hodnocení | Komentář |
|---|---|---|
| **Silná stránka** | Feature pipeline | PRD → UX design → architektura → epics/stories → TDD implementace; nejstrukturovanější spec-driven přístup mimo ceos-agents |
| **Slabá stránka** | Issue tracker | Nulová integrace s externími trackery; stories jsou markdown soubory, ne tickety |
| **Slabá stránka** | Rollback & failure handling | Žádný rollback mechanismus, žádné block comments, žádné pipeline failure recovery |
| **Slabá stránka** | Automatizace end-to-end | Workflows jsou manuálně triggerované; žádný automatický pipeline od issue po PR |
| **Unikát** | Ekosystém modulů | Plugin marketplace (game dev, creative, web components), Party Mode, 43.9K stars — největší komunita ze srovnávaných OSS nástrojů |
| **Unikát** | Agentní role | PM, UX Designer, Tech Writer, Architect jako first-class agenti — ceos-agents tyto role nemá; BMAD pokrývá pre-dev fáze lépe |

### Kontext srovnání

Srovnání je asymetrické záměrně — ceos-agents je **Claude Code plugin** s nulovou cenou za infrastrukturu a konfigurací v jednom CLAUDE.md souboru. Konkurenční nástroje jsou **standalone platformy** s vlastním UI, sandboxem, a billing systémem. Jejich nižší skóre v tabulce tedy nereflektuje horší kvalitu, ale jiný záběr a filosofii: Devin/Copilot/OpenHands řeší obecnou autonomní práci, ceos-agents řeší **strukturované, auditovatelné a konfigurovatelné workflow** s důrazem na traceabilitu od issue po merge.

---

## Zdroje

- [OpenHands — platforma pro AI software agenty](https://openhands.dev/)
- [Devin AI — Wikipedia](https://en.wikipedia.org/wiki/Devin_AI)
- [Devin 2.0 pricing — VentureBeat](https://venturebeat.com/programming-development/devin-2-0-is-here-cognition-slashes-price-of-ai-software-engineer-to-20-per-month-from-500)
- [GitHub Copilot coding agent — GitHub Blog](https://github.blog/news-insights/product-news/github-copilot-meet-the-new-coding-agent/)
- [GitHub Copilot coding agent — GitHub Docs](https://docs.github.com/en/copilot/concepts/agents/coding-agent/about-coding-agent)
- [GitHub Copilot Workspace vs OpenHands](https://createaiagent.net/comparisons/github-copilot-workspace-vs-openhands/)
- [Devin AI Review & Limitations 2026](https://www.idlen.io/blog/devin-ai-engineer-review-limits-2026/)
- [OpenHands — SWE-bench 72 % paper](https://arxiv.org/html/2407.16741v3)
- [Devin vs GitHub Copilot vs OpenHands — SourceForge](https://sourceforge.net/software/compare/Devin-vs-GitHub-Copilot-vs-OpenHands/)
- [BMAD-METHOD — GitHub](https://github.com/bmad-code-org/BMAD-METHOD)
- [BMAD-METHOD plugins marketplace](https://github.com/bmad-code-org/bmad-plugins-marketplace)
