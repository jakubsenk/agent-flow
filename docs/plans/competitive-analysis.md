# Hloubková konkurenční analýza: ceos-agents vs BMAD-METHOD

**Datum:** 2026-03-06
**Autor:** Claude Opus 4.6 (agent pro konkurenční analýzu)
**Analyzované repozitáře:**
- ceos-agents v4.0.1 — `C:\gitea_ceos-agents` (15 agentů, 23 příkazů, 1 skill)
- BMAD-METHOD v6.0.1 — `github.com/bmad-code-org/BMAD-METHOD` (9 agent person, 34+ workflow, 12 skills, CLI instalátor)

---

## Shrnutí

BMAD-METHOD a ceos-agents zaujímají zásadně odlišné niky v prostoru AI-asistovaného vývoje. **BMAD je kolaborativní plánovací facilitátor** — vyniká v provádění lidí strukturovanou specifikací, architekturou a plánovacími fázemi pomocí bohatých interaktivních workflow s 60+ brainstormingovými technikami, adversariálním review a party mode multi-agentní diskuzí. **ceos-agents je autonomní exekuční engine** — vyniká v převzetí existujícího bugu nebo feature ticketu a provedení kompletního pipeline (triage → fix → review → test → publish) s minimálním lidským zásahem. BMAD má hlubší specifikační a plánovací rigoróznost; ceos-agents má hlubší automatizaci, integraci s issue trackery a CI/CD publishing. Ani jedno řešení není striktně lepší — řeší různé problémy. Největší mezery v ceos-agents jsou absence strukturovaných plánovacích workflow, adversariální review metodologie a podpora více IDE. Největší mezery v BMAD jsou absence automatizovaných pipeline, integrace s issue trackery a CI/CD publishingu.

---

## Srovnávací matice

| Dimenze | ceos-agents | BMAD-METHOD | Vítěz | Poznámky |
|---------|-------------|-------------|-------|----------|
| **Architektura a filozofie návrhu** | 2-vrstvý (příkazy orchestrují agenty). Příkazy = CO, agenti = JAK. Čistý markdown, nulové závislosti. Plugin pro Claude Code. | Modulový ekosystém (core + BMM + rozšíření). Agenti + workflow + úkoly + šablony + checklisty. CLI instalátor (Node.js). Multi-IDE. | **Remíza** | Různé filozofie: ceos = automatizace-first, BMAD = kolaborace-first. Obě jsou validní. |
| **Model agentů/person** | 15 agentů. Striktní formát: frontmatter (name, description, model) + Goal/Expertise/Process/Constraints. Funkční role (fixer, reviewer, triage-analyst). Žádná osobnost. | 9 agentů s bohatými personami: jména (Mary, Winston, Amelia), identita, communication_style, principy. Menu-řízená interakce. Customizace agentů přes `.customize.yaml`. | **BMAD** | BMAD model person je bohatší — pojmenované postavy s osobností vytvářejí lepší oddělení rolí a poutavější interakci. ceos-agents agenti jsou funkční, ale neosobní. |
| **Orchestrace pipeline** | Plně automatizovaný pipeline: fetch → triage → analyze → fix ↔ review → test → publish. Worktree paralelismus, dávkování, dekompozice, hooky, vlastní agenti, pipeline profily, dry-run, resume. Block handler s rollbackem. | Step-file sekvenční provádění v rámci každého workflow. YOLO režim pro autonomní postup. Žádný automatizovaný vícekrokový pipeline. Člověk-in-the-loop v každém kroku. | **ceos-agents** | Automatizace pipeline ceos-agents je daleko sofistikovanější. BMAD vyžaduje lidskou přítomnost v každém kroku workflow. ceos dokáže zpracovat N bugů autonomně s paralelními worktrees. |
| **Specifikace a plánování** | Scaffold v2: spec-writer ↔ spec-reviewer smyčka generuje spec/ složku. Žádný PRD workflow. Žádný UX design workflow. Žádné research workflow. | 4-fázový systém: Analýza (brainstorming, research, brief) → Plánování (PRD, UX design) → Řešení (architektura, epiky a stories, readiness check) → Implementace. Bohaté šablony, krok-za-krokem facilitace. | **BMAD** | Hloubka plánování BMAD je výrazně nadřazená. 4 fáze s více workflow na fázi. spec-writer ceos-agents je jednorázový generátor vs. vícekrokové facilitované discovery BMAD. |
| **Generování a oprava kódu** | fixer agent (opus): chirurgické minimální opravy, limit 100 řádků diffu, cílení na root cause, ověření buildu. Dekompozice pro složité bugy. | dev agent (Amelia): implementace založená na stories, red-green-refactor TDD cyklus, provádění task/subtask, sledování stavu sprintu. | **ceos-agents** | fixer ceos-agents je více omezený a bezpečný pro produkci (limit 100 řádků, povinný úspěšný build, rollback). Dev agent BMAD je více orientovaný na features, ale méně bezpečnostně omezený. |
| **Review a kvalitativní brány** | reviewer agent (opus): strukturovaný checklist (root cause, úplnost, konvence, regrese, bezpečnost, výkon, over-engineering). Iterativní fixer ↔ reviewer smyčka (max 5). | Adversariální code review: MUSÍ najít problémy, nula nálezů = zastavení. Validace git diffu. Fix-or-action-items workflow. Integrace se stavem sprintu. Edge case hunter task (JSON výstup). | **BMAD** | Adversariální review metodologie BMAD je opravdu lepší — nutit reviewera najít problémy eliminuje rubber-stamping. Edge case hunter je unikátní koncept, který ceos-agents zcela postrádá. |
| **Testovací strategie** | test-engineer (sonnet): píše unit testy po opravě, max 3 pokusy. e2e-test-engineer pro end-to-end. Oddělení agenti. | dev agent zahrnuje TDD (red-green-refactor). QA agent (Quinn) pro generování testů po epiku. Test Architect modul (TEA) dostupný jako rozšíření pro enterprise testování. | **BMAD** | TDD-first přístup BMAD (red před green) je metodologicky silnější. TEA modul přidává enterprise-grade testovací strategii, kterou ceos-agents nepokrývá. Nicméně automatizovaná testovací smyčka ceos-agents je více hands-off. |
| **Scaffolding / Bootstrap projektu** | Plný scaffold v2 pipeline: popis → spec → skeleton → implementace → test → e2e → git init. --no-implement pro skeleton-only. 3 režimy (interaktivní, YOLO-checkpoint, plný YOLO). | Žádná schopnost scaffoldingu projektu. Předpokládá existující codebase nebo manuální setup. | **ceos-agents** | Toto je jasná výhoda ceos-agents. BMAD nemá ekvivalent — začíná od požadavků, ale negeneruje projektové skeletony. |
| **Flexibilita konfigurace** | Automation Config v CLAUDE.md: 15+ konfiguračních sekcí (Issue Tracker, Source Control, Build & Test, Retry Limits, Hooks, Custom Agents, Notifications, Worktrees, E2E Test, Error Handling, Pipeline Profiles, Decomposition, Metrics, Feature Workflow, Extra Labels). Vše ve formátu tabulek. | module.yaml konfigurace per modul + core config. Proměnné: user_name, communication_language, skill_level, output_folder, project_name. Customizace agentů přes .customize.yaml. | **ceos-agents** | Konfigurační kontrakt ceos-agents je daleko komplexnější pro CI/CD automatizaci. Konfigurace BMAD je jednodušší, protože neautomatizuje publishing ani operace s issue trackery. |
| **Rozšiřitelnost (vlastní agenti, hooky)** | 4 hook pointy (pre-fix, post-fix, pre-publish, post-publish). Injekce vlastních agentů ve 2 bodech. Pipeline profily pro přeskočení/přidání fází. Namespace kompozabilita. | Modulový systém (BMB builder, TEA, CIS, BMGD). Vlastní moduly přes npm. Customizace agentů přes .customize.yaml (memories, menus, critical_actions, prompts). BMad Builder pro vytváření nových agentů/workflow. | **BMAD** | Modulový ekosystém BMAD je rozšiřitelnější — plný npm-based modulový systém s builder nástrojem. ceos-agents má hooky a vlastní agenty, ale žádný ekvivalent module marketplace nebo builderu. |
| **Integrace s issue trackery** | 6 trackerů: YouTrack, GitHub, Jira, Linear, Gitea, Redmine. Založeno na MCP. Přechody stavů, dotazy, komentáře, blokování. | Žádná. Sledování založené na souborovém systému (sprint-status.yaml, story soubory). Žádná integrace s externím trackerem. | **ceos-agents** | Kompletní výhoda ceos-agents. BMAD má nulovou integraci s issue trackery. |
| **CI/CD a publishing** | publisher agent vytváří větve, commituje, pushuje, vytváří PR. Webhook notifikace. Verify příkaz po merge. Plná automatizace git workflow. | Žádný CI/CD publishing. Manuální git operace. Žádné vytváření PR. Žádné automatizované pushování. | **ceos-agents** | Kompletní výhoda ceos-agents. BMAD se nedotýká git operací mimo implementaci dev agenta. |
| **Zpracování chyb a obnova** | Block handler: rollback-agent vrací git stav, komentuje issue, nastavuje stav. Resume-ticket pokračuje z bodu selhání. Max blokovaných za běh. Fail-fast/continue strategie. | Halt podmínky ve workflow. Zpracování chyb na úrovni kroků. Žádný rollback mechanismus. Žádná resume schopnost. | **ceos-agents** | Zpracování chyb ceos-agents je production-grade s rollbackem, resume a konfigurovatelnými strategiemi. BMAD se prostě zastaví. |
| **Kvalita dokumentace** | docs/guides/, docs/reference/, docs/plans/. Primárně interní. Žádný web. Žádné tutoriály. Některé průvodce jsou v češtině. Adresář plánů je komplexní. | Diataxis framework: tutorials/, how-to/, explanation/, reference/. Dedikovaný web (docs.bmad-method.org). Style guide. Čínský překlad. Getting started tutoriál. | **BMAD** | Dokumentace BMAD sleduje profesionální standardy (Diataxis). Má web, strukturované docs, style guide, komunitní docs. Dokumentace ceos-agents je funkční, ale méně uhlazená. |
| **Onboarding / DX** | /init příkaz, /onboard wizard, /check-setup validace. /template pro generování konfigurace. Instalace z plugin marketplace. | npx bmad-method install (interaktivní CLI). /bmad-help inteligentní průvodce. Vícekrokový instalátor s výběrem modulů, detekcí IDE, konfiguračními prompty. Getting started tutoriál. | **BMAD** | Onboarding BMAD je uhlazenější: interaktivní CLI instalátor, inteligentní /bmad-help detekující stav projektu, krok-za-krokem tutoriál. /onboard ceos-agents funguje, ale je méně propracovaný. |
| **Systém šablon a checklistů** | Block Comment Template, PR Description Template. Žádné samostatné soubory šablon/checklistů. | Bohatý systém šablon: PRD šablona, architektura šablona, tech spec šablona, story šablona, epics šablona, sprint status šablona, UX design šablona, brainstorming šablona, readiness report šablona. Checklisty per workflow (code-review, dev-story, sprint-planning, create-story). | **BMAD** | Systém šablon a checklistů BMAD je výrazně bohatší. Každý workflow má strukturované šablony. ceos-agents má minimální šablony. |
| **Multi-model strategie** | Explicitní per-agent: opus (fixer, reviewer, architect, priority-engine, spec-writer, spec-reviewer), sonnet (triage-analyst, code-analyst, test-engineer, e2e-test-engineer, spec-analyst, stack-selector, scaffolder), haiku (publisher, rollback-agent). | Žádná specifikace modelu v definicích agentů. Výběr modelu ponechán na uživateli/konfiguraci IDE. | **ceos-agents** | Explicitní přiřazení modelu per agent v ceos-agents je významná výhoda — optimalizuje náklady a kvalitu. BMAD ponechává výběr modelu zcela na uživateli. |
| **Kvalita prompt engineeringu** | Funkční, přímé prompty. Jasné procesní kroky. Silné definice omezení (NEVER pravidla). Konzistentní formát napříč všemi agenty. Dobrý, ale ne kreativní. | Bohaté persona prompty s osobností. XML workflow instrukce s kritickými tagy. Micro-file architektura bojuje proti "lost in the middle". Anti-bias protokoly v brainstormingu. Adversariální postoj v review. | **BMAD** | Prompt engineering BMAD je sofistikovanější — XML instrukce s kritickými sekcemi, micro-file architektura pro správu kontextu, anti-bias protokoly. ceos-agents je konzistentní, ale jednodušší. |
| **Kompozabilita a modularita** | Namespace prefix (ceos-agents:). Příkazy a agenti jsou oddělené záležitosti. Plugin architektura. Může se skládat s jinými Claude Code pluginy. | Modulový ekosystém s řešením závislostí. npm balíčkování. Manifest systém modulů. Možnost instalace více modulů. Plánovaná podpora komunitních modulů. | **BMAD** | Modulový systém BMAD je více kompozabilní — npm-based balíčky, závislosti modulů, builder nástroj. ceos-agents je jediný plugin s namespace izolací. |
| **Reálná robustnost** | Testováno manuální test sadou (13 scénářů). Worktree paralelismus pro dávkové zpracování. MCP pre-flight kontroly. Retry limity všude. Resume schopnost. Dry-run režim pro bezpečné testování. | Test sada s fixtures (validace schématu agentů, CLI integrace, validace referencí souborů). Kvalitativní CI workflow (markdownlint, eslint, prettier). CodeRabbit integrace. | **ceos-agents** | ceos-agents je robustnější pro automatizované provádění pipeline (retry, rollback, resume, dry-run). Testování BMAD je více o frameworku samotném. Pro produkční pipeline použití je ceos-agents otužilejší. |

---

## Brutální analýza

### Silné stránky — Věci, které BMAD nemá nebo dělá hůře

1. **Automatizovaný end-to-end pipeline** — ceos-agents dokáže vzít ID bugu a vytvořit zmergovaný PR s nulovým lidským zásahem. BMAD vyžaduje lidskou přítomnost v každém kroku workflow. Toto je naše klíčová vlastnost.

2. **Integrace s issue trackery** — 6 typů trackerů přes MCP. BMAD má nulovou externí integraci. Pro týmy používající YouTrack/Jira/Linear/GitHub Issues je to masivní výhoda.

3. **CI/CD publishing** — Publisher agent, vytváření PR, správa větví, webhook notifikace, post-merge verifikace. BMAD se nedotýká git operací.

4. **Multi-model optimalizace nákladů** — Explicitní přiřazení modelu per agent (opus pro kritické myšlení, sonnet pro analýzu, haiku pro mechanické úkoly). BMAD používá jakýkoli model, který má uživatel nakonfigurovaný.

5. **Rollback a resume** — Production-grade obnova po chybách. Rollback agent vrací git stav při selhání. Resume-ticket pokračuje z bodu selhání. BMAD se prostě zastaví.

6. **Scaffolding projektu** — Plný scaffold v2 pipeline (popis → fungující aplikace). BMAD předpokládá, že projekt již existuje.

7. **Paralelní zpracování** — Worktree-based dávkové zpracování více bugů současně. BMAD je striktně sekvenční.

8. **Pipeline profily** — Přeskočení/přidání fází per profil. Umožňuje různé konfigurace pipeline pro různé typy práce. BMAD nemá ekvivalent.

9. **Dry-run režim** — Analýza N bugů bez jakýchkoli vedlejších efektů. BMAD nemá koncept náhledu/dry-run.

10. **Dekompozice** — Architect agent dokáže rozložit složité bugy na podúkoly s provádění s vědomím závislostí. Dekompozice BMAD je na úrovni epik/stories, ne na úrovni oprav.

### Slabé stránky — Věci, které BMAD dělá lépe nebo nám zcela chybí

1. **Žádné strukturované plánovací workflow** — ceos-agents nemá vytváření PRD, žádný UX design workflow, žádné research workflow, žádné vytváření product briefu. BMAD má celou Fázi 1 (Analýza) a Fázi 2 (Plánování), které kompletně přeskakujeme. Náš spec-writer je jednorázový generátor; vytváření PRD v BMAD je vícekroková facilitovaná konverzace s 12 kroky.

2. **Žádná adversariální review metodologie** — Adversariální review BMAD nutí reviewera najít problémy (nula nálezů = zastavení). Náš reviewer agent dělá strukturovaný review, ale může snadno orazítkovat "APPROVE", pokud oprava vypadá rozumně. Chybí nám mandát "najdi alespoň N problémů".

3. **Žádný brainstorming ani elicitace** — BMAD má 62 brainstormingových technik v 10 kategoriích (kolaborativní, kreativní, hluboké, strukturované, teatrální, divoké, biomimetické, kvantové, kulturní, introspektivní). Plus pokročilá elicitace s metodami jako Pre-mortem analýza, First Principles Thinking, Red Team vs Blue Team. Máme nulovou schopnost kreativní ideace.

4. **Žádný party mode** — BMAD dokáže přivést více agent person do jedné konverzace pro kolaborativní diskuzi. Naši agenti jsou striktně sekvenční a izolovaní. Žádný způsob, jak dosáhnout dynamiky "architekt a fixer diskutují přístup".

5. **Žádná osobnost agentů** — BMAD agenti mají jména, komunikační styly, identity ("Mluví s nadšením lovce pokladů"), principy navázané na reálné metodologické frameworky. Naši agenti jsou funkční ("Jsi Senior Developer specializující se na chirurgické opravy bugů"), ale neosobní. To ovlivňuje zapojení uživatelů.

6. **Žádné sprint plánování ani sledování** — BMAD má sprint-status.yaml, story soubory se sledováním stavu, sprint planning workflow, retrospektivy. ceos-agents vytváří PR, ale nemá koncept sprint kadence, stavu stories ani sledování vývoje.

7. **Žádný systém customizace agentů** — BMAD má `.customize.yaml` soubory, kde uživatelé mohou přepsat personu, přidat memories, injektovat položky menu, přidat critical_actions — vše zachováno přes aktualizace. ceos-agents nemá žádný mechanismus customizace per agent.

8. **Žádná podpora více IDE** — ceos-agents je pouze pro Claude Code. BMAD podporuje Claude Code, Cursor, Windsurf, Kiro, Gemini Code Assist, OpenCode, Trae a další přes svůj CLI instalátor generující IDE-specifickou konfiguraci. Toto je významné omezení dosahu na trh.

9. **Žádný modulový ekosystém** — BMAD má BMad Builder (vytváření vlastních agentů/workflow), Test Architect (enterprise testování), Creative Intelligence Suite, Game Dev Studio. Vše instalovatelné přes npm. ceos-agents je jeden monolitický plugin.

10. **Dokumentace je méně strukturovaná** — BMAD používá Diataxis framework (tutorials, how-to, explanation, reference) s dedikovaným webem. Naše docs jsou funkční, ale chybí getting-started tutoriál, žádný web, smíchané jazyky a žádný style guide pro dokumentaci.

11. **Žádná step-file architektura** — Micro-file architektura BMAD načítá jeden krok najednou, aby bojovala proti "lost in the middle" problémům s velkými kontexty. Každý step soubor je samostatný. ceos-agents načítá celou definici příkazu najednou, což může být problematické pro složité orchestrace.

12. **Žádný edge case hunter** — BMAD má specializovaný task (`review-edge-case-hunter.xml`), který mechanicky prochází každou větvící cestu a hraniční podmínku a vypisuje strukturovaný JSON. Náš reviewer kontroluje edge cases, ale nemá dedikovaný, systematický přístup.

### Slepá místa — Věci, které ani jedno řešení nedělá dobře

1. **Real-time kolaborace** — Ani jeden systém nepodporuje více lidí nebo více AI sessions pracujících na stejné codebase současně s detekcí konfliktů. Oba jsou single-session nástroje.

2. **Učení se z výsledků** — Ani jeden systém nevrací zpětnou vazbu z výsledků (které opravy fungovaly, které byly blokovány, které review našly reálné problémy) pro zlepšení budoucího výkonu. Žádná reinforcement smyčka.

3. **Viditelnost nákladů během provádění** — Ani jeden neposkytuje real-time spotřebu tokenů během provádění pipeline. ceos-agents má `/estimate`, ale to je pouze pre-execution.

4. **Skenování zranitelností závislostí** — Ani jeden neintegruje nástroje pro audit závislostí (npm audit, pip-audit atd.) jako součást review nebo testovacího pipeline.

5. **Testování výkonnostní regrese** — Ani jeden nemá dedikované výkonnostní benchmarkování jako fázi pipeline. Oba kontrolují správnost, ale ne výkon.

### Přeinženýrování — Věci, kde překomplikováváme vs. jednodušší přístup BMAD

1. **Automation Config kontrakt** — 15+ konfiguračních sekcí s požadavky na specifický formát tabulek. BMAD používá jednoduchou YAML konfiguraci automaticky generovanou instalátorem. Naše konfigurace je mocná, ale zastrašující pro nové uživatele. Fakt, že potřebujeme `/onboard`, `/template`, `/migrate-config` A `/check-setup` jen pro konfiguraci, naznačuje, že je příliš složitá.

2. **Block Comment Template** — Rigidní formát šablony se specifickými poli (Agent, Step, Reason, Detail, Recommendation). BMAD se prostě zastaví s jasnou zprávou. Naše formálnost přidává trasovatelnost, ale také ceremoniálnost.

3. **Pipeline Profiles** — Přeskočení fází, extra fáze, konfigurace per profil. To přidává komplexitu pro use case (různé konfigurace pipeline per typ bugu), který nemusí být dostatečně častý, aby ospravedlnil mentální zátěž.

### Podinženýrování — Věci, které řešíme příliš volně vs. rigoróznost BMAD

1. **Kvalita specifikace** — Náš spec-writer generuje spec v jednom průchodu (s review smyčkou), ale neexistuje strukturovaný discovery proces. Vytváření PRD v BMAD má 12 kroků: init, discovery, vize, executive summary, metriky úspěchu, user journeys, doménový model, inovace, typ projektu, scoping, funkční požadavky, nefunkční požadavky a polish. Každý krok má vlastní soubor s vloženými pravidly.

2. **Hloubka code review** — Náš reviewer provádí checklist, ale nevynucuje nalezení problémů. Adversariální review BMAD VYŽADUJE minimálně 3-10 specifických problémů per review. Pokud je nalezeno méně než 3, vynutí opětovné prozkoumání. Náš reviewer může schválit příliš snadno.

3. **Správa kontextu** — Step-file architektura BMAD explicitně spravuje omezení kontextového okna. My načítáme celé definice příkazů (některé mají 400+ řádků jako `fix-bugs.md`) najednou. Přístup BMAD s načítáním jednoho kroku najednou s just-in-time načítáním je robustnější pro složité workflow.

4. **Implementační metodologie** — Dev agent BMAD sleduje striktní TDD (red-green-refactor): napíše SELHÁVAJÍCÍ testy NEJPRVE, pak implementuje, pak refaktoruje. Náš fixer napíše opravu jako první, pak test-engineer přidá testy poté. TDD je metodologicky silnější.

5. **Bohatost šablon** — BMAD má šablony pro každý artefakt: PRD, architektura, tech spec, stories, epiky, sprint status, UX design, brainstorming sessions, readiness reports. My máme v podstatě jen Block Comment Template a PR Description Template.

---

## Ukradeno s hrdostí — Akční vylepšení z BMAD

### P0: Kritické mezery

#### 1. Adversariální review metodologie
**Co to je:** Code review BMAD nutí reviewera najít problémy. Nula nálezů spouští zastavení. Reviewer přijímá "cynický postoj" — předpokládej, že problémy existují, a najdi je. Vyžaduje minimum 3-10 specifických problémů per review.

**Jak to BMAD implementuje:** `src/bmm/workflows/4-implementation/code-review/instructions.xml` řádky 7-11:
```xml
<critical>YOU ARE AN ADVERSARIAL CODE REVIEWER - Find what's wrong or missing!</critical>
<critical>Find 3-10 specific issues in every review minimum - no lazy "looks good" reviews</critical>
```
Pokud `total_issues_found < 3`, workflow vynutí opětovné prozkoumání s explicitními dalšími kategoriemi hledání.

**Proč je to hodnotné:** Eliminuje rubber-stamping. Náš současný reviewer může schválit s nulovými nálezy, což maří účel kvalitativní brány. Adversariální review konzistentně zachytí problémy, které normální review přehlédne.

**Jak integrovat:**
- Přidat do `agents/reviewer.md` Process krok 4: "MUSÍŠ identifikovat alespoň 3 specifické problémy per review. Pokud najdeš méně než 3 po svém počátečním review, znovu prozkoumej kód na: edge cases, null handling, porušení architektury, mezery v dokumentaci, integrační problémy, problémy se závislostmi. Nula nálezů je podezřelá — znovu analyzuj."
- Přidat nové omezení: "NIKDY neschvaluj s nulovými nálezy. Pokud opravdu nemůžeš najít problémy, vypiš detailní vysvětlení, proč je tato oprava výjimečně čistá, a stále uveď alespoň 1 nález na úrovni návrhu."
- Přidat úrovně závažnosti odpovídající BMAD: HIGH (musí se opravit před merge), MEDIUM (mělo by se opravit), LOW (bylo by hezké)

**Odhadovaný rozsah:** `agents/reviewer.md` — 15 řádků přidáno do Process, 2 řádky do Constraints.

#### 2. Edge Case Hunter Task
**Co to je:** Specializovaný review task, který mechanicky prochází každou větvící cestu a hraniční podmínku a hlásí pouze neošetřené případy. Výstup ve strukturovaném JSON.

**Jak to BMAD implementuje:** `src/core/tasks/review-edge-case-hunter.xml` — oddělený od obecného code review. Metodou řízený (vyčerpávající enumerace cest), ne postojem řízený (adversariální). Trasuje: podmínky, switche, early returns, guard clauses, smyčky, error handlery, null/empty, přetečení, type coercion, konkurence, timing.

**Proč je to hodnotné:** Nachází třídu bugů, kterou ani náš fixer, ani reviewer systematicky nekontroluje. Strukturovaný JSON výstup ho dělá strojově parsovatelným pro downstream tooling.

**Jak integrovat:** Nevytvářet nového agenta — místo toho přidat edge-case analýzu jako povinný pod-krok do Process reviewerova agenta (krok 4, po checklistu). Přidat specifickou instrukci: "Pro každý změněný soubor trasuj každou větvící cestu a hraniční podmínku. Hlásit jakékoli neošetřené: null/undefined, prázdné kolekce, nulové/záporné hodnoty, přetečení, type coercion, race conditions u konkurence."

**Odhadovaný rozsah:** `agents/reviewer.md` — 8 řádků přidáno do Process kroku 4.

#### 3. Strategie podpory více IDE
**Co to je:** BMAD podporuje Claude Code, Cursor, Windsurf, Kiro, Gemini, OpenCode, Trae a další přes platform-specifické šablony generované CLI instalátorem.

**Jak to BMAD implementuje:** `tools/cli/installers/lib/ide/` má dedikované instalátory per IDE. `templates/combined/` má IDE-specifické šablony příkazů agentů. Každé IDE má svůj vlastní způsob objevování příkazů/agentů a instalátor generuje správný formát.

**Proč je to hodnotné:** ceos-agents je pouze pro Claude Code, což omezuje trh na jedno IDE. Samotný Cursor má obrovský podíl na trhu v prostoru AI kódování.

**Jak integrovat:** Toto je velká iniciativa. Začít s podporou Cursoru:
1. Prozkoumat formát `.cursor/rules` a vlastních příkazů Cursoru
2. Vytvořit adresář `tools/` s konverzním skriptem, který transformuje naše `.md` příkazy do Cursor-kompatibilního formátu
3. Přidat příkaz `/ceos-agents:export --target cursor`

**Odhadovaný rozsah:** Nový `tools/cursor-export.js` (nebo shell skript), nový příkaz `commands/export.md`. Střední náročnost.

### P1: Významná vylepšení

#### 4. Step-File architektura pro složité příkazy
**Co to je:** BMAD načítá workflow instrukce jeden krok najednou ("micro-file architektura"), aby zabránil "lost in the middle" degradaci kontextu.

**Jak to BMAD implementuje:** Každý workflow má adresář `steps/` s `step-01-init.md`, `step-02-discovery.md` atd. workflow.md načte pouze step-01. Každý step soubor explicitně pojmenovává další krok. Proměnné přetrvávají mezi kroky. Pravidla: "NIKDY nenačítej více step souborů současně", "VŽDY přečti celý step soubor před provedením."

**Proč je to hodnotné:** Náš `commands/fix-bugs.md` má 414 řádků. `commands/scaffold.md` má 443 řádků. Načtení všeho najednou riskuje degradaci kontextu. Step-file architektura by udržela každou instrukci čerstvou.

**Jak integrovat:** Pro naše dva nejsložitější příkazy (fix-bugs, scaffold) rozdělit příkaz na step soubory. Hlavní soubor příkazu se stane loaderem, který zpracovává krok 1, který řetězí na krok 2 atd. To zachovává zpětnou kompatibilitu (soubor příkazu stále existuje) a zároveň zlepšuje kvalitu provádění pro dlouhé pipeline.

**Odhadovaný rozsah:** `commands/fix-bugs.md` → adresář `commands/fix-bugs/` s 5-6 step soubory. `commands/scaffold.md` → adresář `commands/scaffold/` s 4-5 step soubory. Velký refaktor, ale vysoká hodnota.

**Poznámka k prioritě:** Odložit, dokud nebudou důkazy, že degradace kontextu způsobuje reálná selhání.

#### 5. Systém customizace agentů
**Co to je:** Per-agent `.customize.yaml` soubory, které umožňují uživatelům přepsat personu, přidat memories, injektovat položky menu a definovat startup akce — zachovány přes aktualizace pluginu.

**Jak to BMAD implementuje:** `_bmad/_config/agents/{module}-{agent}.customize.yaml`. Sekce: metadata (nahrazuje), persona (nahrazuje), memories (přidává), menu (přidává), critical_actions (přidává), prompts (přidává). Šablona na `src/utility/agent-components/agent.customize.template.yaml`.

**Proč je to hodnotné:** Uživatelé často chtějí doladit chování agenta pro svůj projekt (např. "reviewer by měl vždy kontrolovat SQL injection", "fixer by nikdy neměl používat var"). Momentálně by museli forkovat plugin.

**Jak integrovat:** Přidat podporu pro adresář `customization/` v konzumujícím projektu. Pro každého agenta zkontrolovat, zda existuje `customization/{agent-name}.md`. Pokud ano, připojit jeho obsah k promptu agenta jako "## Projektově-specifické instrukce". To je jednodušší než YAML přístup BMAD, ale dosahuje 80% hodnoty.

**Odhadovaný rozsah:** Dokumentace konvence + 3-4 řádky přidané do každého příkazu, který dispatchuje agenty pro načtení customizačních souborů. Nebo: jedna instrukce v `CLAUDE.md` pod novou sekcí "## Agent Customization" vysvětlující konvenci.

#### 6. TDD-First implementace
**Co to je:** Dev agent BMAD sleduje striktní red-green-refactor: napíše SELHÁVAJÍCÍ testy nejprve, potvrdí jejich selhání, implementuje minimální kód, potvrdí úspěch testů, pak refaktoruje.

**Jak to BMAD implementuje:** `src/bmm/workflows/4-implementation/dev-story/instructions.xml` krok 5:
```xml
<!-- RED PHASE -->
<action>Write FAILING tests first for the task/subtask functionality</action>
<action>Confirm tests fail before implementation - this validates test correctness</action>
<!-- GREEN PHASE -->
<action>Implement MINIMAL code to make tests pass</action>
```

**Proč je to hodnotné:** Testy napsané po implementaci často testují implementaci místo požadavku. TDD zajišťuje, že testy validují chování, ne kód. Také zachytí nejednoznačnost požadavků dříve.

**Jak integrovat:** Upravit `agents/fixer.md` Process krok 5 tak, aby zahrnoval: "Před implementací opravy napiš test, který reprodukuje bug (red fáze). Potvrď, že test selhává. Pak implementuj opravu, aby test prošel (green fáze). Pak ověř, že všechny existující testy stále procházejí." To se shoduje s TDD bez nutnosti samostatného kroku test-engineer pro počáteční reprodukční test.

**Odhadovaný rozsah:** `agents/fixer.md` — 5 řádků upravených v Process kroku 5.

#### 7. Brainstormingová schopnost pro Scaffold
**Co to je:** BMAD má 62 brainstormingových technik organizovaných podle kategorie se strukturovaným facilitačním workflow.

**Jak to BMAD implementuje:** `src/core/workflows/brainstorming/brain-methods.csv` obsahuje 62 technik. `src/core/workflows/brainstorming/workflow.md` je facilitační workflow s anti-bias protokoly a cílem "100+ nápadů před organizováním".

**Proč je to hodnotné:** Náš scaffold pipeline skočí rovnou od popisu ke specifikaci. Pro uživatele, kteří mají vágní nápad ("Chci aplikaci pro správu úkolů"), by brainstormingová fáze před spec-writing produkovala mnohem lepší specifikace.

**Jak integrovat:** Přidat volitelný `--brainstorm` flag do `/scaffold`. Když je nastaven, před spuštěním spec-writeru spustit brainstormingový facilitační krok (nový příkaz nebo inline v scaffold). Udržet to štíhlé: 3-5 otázek používajících divergentní myšlenkové techniky, pak syntetizovat do zpřesněného popisu projektu, který se předá spec-writeru.

**Odhadovaný rozsah:** Nový volitelný krok v `commands/scaffold.md` (15-20 řádků). Nebo: delegovat na skill superpowers:brainstorming, který již existuje v naší sadě skillů.

#### 8. Ekvivalent /bmad-help — Inteligentní status a průvodce
**Co to je:** `/bmad-help` BMAD prozkoumá projekt, detekuje, co bylo dokončeno, a doporučí, co dělat dál. Spouští se automaticky na konci každého workflow.

**Jak to BMAD implementuje:** Je to core task, který čte stav projektu (které artefakty existují v `_bmad-output/`) a křížově odkazuje s mapou workflow pro navržení dalších kroků.

**Proč je to hodnotné:** Náš `/status` příkaz ukazuje rozpracované issues, ale nevede uživatele k tomu, co dělat dál. Schopnost "co dál?" by výrazně zlepšila DX, zejména pro nové uživatele.

**Jak integrovat:** Vylepšit `/ceos-agents:status` o sekci "Doporučené další kroky" na základě stavu projektu: existuje CLAUDE.md? Je Automation Config kompletní? Jsou bugy k opravě? Jsou features k implementaci? Jaký je stav pipeline?

**Odhadovaný rozsah:** `commands/status.md` — 10-15 řádků přidáno pro logiku doporučení.

### P2: Příjemné bonusy

#### 9. Osobnost agentů a komunikační styl
**Co to je:** BMAD agenti mají jména, komunikační styly ("Mluví klidným, pragmatickým tónem") a osobnostní rysy, které dělají interakci poutavější.

**Proč je to hodnotné:** Dělá zážitek zapamatovatelnějším a pomáhá uživatelům rychle identifikovat, který agent odpovídá. Vytváří brand identitu.

**Jak integrovat:** Přidat volitelné náznaky osobnosti do popisů agentů. Udržet je subtilní — nepotřebujeme "Mary analytičku", ale mohli bychom přidat řádek `communication_style` do frontmatteru. Příklad: `style: "Přímý, technický, založený na důkazech"` pro reviewera.

**Odhadovaný rozsah:** Všech 15 `agents/*.md` souborů — 1 řádek každý. Nízká priorita.

#### 10. Sharding dokumentů
**Co to je:** BMAD podporuje rozdělení velkých artefaktů (PRD, architektura) do více souborů s index.md a inteligentním selektivním načítáním.

**Jak to BMAD implementuje:** `input_file_patterns` ve workflow YAML se strategiemi: FULL_LOAD, SELECTIVE_LOAD, INDEX_GUIDED. Protokol `discover_inputs` ve `workflow.xml` zajišťuje nalezení a načtení správných souborů.

**Proč je to hodnotné:** Velké specifikační dokumenty mohou překročit limity kontextu. Sharding se selektivním načítáním zajišťuje, že agenti vidí jen to, co potřebují.

**Jak integrovat:** Pro scaffold v2 spec/ složku již shardujeme (spec/README.md, spec/architecture.md, spec/verification.md, spec/epics/*.md). Mohli bychom přidat INDEX_GUIDED strategii načítání pro architect agenta, aby selektivně načítal pouze relevantní epiky.

**Odhadovaný rozsah:** Drobné doplnění do `commands/scaffold.md` a `agents/architect.md`.

#### 11. YOLO režim pro všechny příkazy
**Co to je:** YOLO režim BMAD přeskočí všechna potvrzení a simuluje odpovědi zkušeného uživatele.

**Proč je to hodnotné:** Náš scaffold už má Interaktivní/YOLO-checkpoint/Plný YOLO. Rozšíření tohoto vzoru na další příkazy (implement-feature, fix-ticket) by umožnilo zkušeným uživatelům spouštět pipeline rychleji.

**Odhadovaný rozsah:** `commands/fix-ticket.md`, `commands/implement-feature.md` — přidat `--yolo` flag.

#### 12. Šablony checklistů per fáze pipeline
**Co to je:** BMAD má dedikované soubory checklistů per workflow, které slouží jako validační brány.

**Proč je to hodnotné:** Dělá kvalitativní brány explicitními a auditovatelnými. Momentálně naši agenti mají omezení, ale žádné samostatné checklisty, které by šlo verzovat a customizovat nezávisle.

**Odhadovaný rozsah:** Nový adresář `checklists/` s `review-checklist.md`, `test-checklist.md` atd. Odkazováno agenty.

---

## Naše výhody — Co chránit

Toto jsou věci, které by uživatelé BMAD záviděli. Zdvojnásob investici do těchto:

1. **Autonomní provádění pipeline** — "Dej mi 5 bugů, opravím je, zatímco spíš." BMAD tohle neumí. Toto je náš příkop.

2. **Integrace s issue trackery** — 6 trackerů, založeno na MCP, přechody stavů, komentování, blokování. BMAD je pouze souborový systém. Chránit a rozšiřovat (více trackerů, bohatší integrace).

3. **Publisher agent** — Automatizované vytváření PR s pojmenováním větví, labely, šablonami popisu, trasovatelností zpět k issue. BMAD nemá nic srovnatelného.

4. **Rollback a resume** — Production-grade obnova po chybách. BMAD se prostě zastaví. To dělá ceos-agents bezpečným pro bezobslužný provoz.

5. **Worktree paralelismus** — Zpracování více bugů současně v izolovaných worktrees. BMAD je striktně sekvenční.

6. **Multi-model optimalizace nákladů** — Explicitní přiřazení modelu per agent. BMAD plýtvá opus tokeny na úkoly vhodné pro haiku.

7. **Dry-run režim** — Náhled, co by pipeline udělal, bez vedlejších efektů. Esenciální pro budování důvěry.

8. **Pipeline profily** — Různé konfigurace pipeline pro různé typy práce. Unikátní pro ceos-agents.

9. **Webhook notifikace** — Event-driven integrace s externími systémy. BMAD má Discord webhooky pro releasy, ale nic pro pipeline události.

10. **Config-driven generická architektura** — ceos-agents je projektově agnostický. Veškerá projektově specifická konfigurace žije v CLAUDE.md. BMAD se instaluje do adresáře projektu (_bmad/), což je těžší.

---

## Top 10 doporučení (prioritizované)

### 1. Přidat adversariální review metodologii do reviewer agenta [P0]
**Proč:** Největší kvalitativní mezera. Náš reviewer může orazítkovat. Přístup BMAD s vynucenými nálezy zachytí více bugů.
**Náročnost:** Malá (15 řádků v `agents/reviewer.md`)
**Dopad:** Přímo zlepšuje kvalitu oprav pro každý běh pipeline.

### 2. Přidat edge case analýzu do revieweru [P0]
**Proč:** Systematická enumerace cest zachytí třídu bugů, kterou momentálně přehlížíme.
**Náročnost:** Malá (8 řádků v `agents/reviewer.md`)
**Dopad:** Méně post-merge regresí.

### 3. Přidat TDD přístup do fixer agenta [P1]
**Proč:** Napsání reprodukčního testu před opravou zajistí, že oprava skutečně řeší hlášené chování.
**Náročnost:** Malá (5 řádků v `agents/fixer.md`)
**Dopad:** Vyšší míra správnosti oprav.

### 4. Vytvořit schopnost exportu pro více IDE [P0 pro dosah na trh]
**Proč:** Omezení na Claude Code limituje náš adresovatelný trh. Cursor má masivní adopci.
**Náročnost:** Střední (nový příkaz + konvertor)
**Dopad:** Otevírá ceos-agents celému trhu AI IDE.

### 5. Přidat inteligentní průvodce do /status příkazu [P1]
**Proč:** Noví uživatelé nevědí, co dělat dál. /bmad-help BMAD je jejich nejlepší onboardingový nástroj.
**Náročnost:** Malá (15 řádků v `commands/status.md`)
**Dopad:** Vylepšený onboarding a retence uživatelů.

### 6. Zavést konvenci customizace agentů [P1]
**Proč:** Uživatelé chtějí doladit agenty pro svůj projekt bez forkování pluginu.
**Náročnost:** Malá (dokumentace + definice konvence)
**Dopad:** Uživatelé mohou specializovat agenty pro svou codebase.

### 7. Přidat --brainstorm flag do scaffold [P1]
**Proč:** Uživatelé s vágními nápady produkují lepší specifikace po strukturované ideaci.
**Náročnost:** Malá (využít existující superpowers:brainstorming skill)
**Dopad:** Vyšší kvalita scaffold výstupu.

### 8. Prozkoumat step-file architekturu pro fix-bugs a scaffold [P1]
**Proč:** Naše nejdelší příkazy (400+ řádků) mohou trpět degradací kontextu.
**Náročnost:** Velká (restrukturace adresářů + step soubory)
**Dopad:** Lepší spolehlivost pipeline pro složité orchestrace. Odložit, dokud nebudeme mít důkazy o degradaci kontextu.

### 9. Vylepšit dokumentaci s Diataxis strukturou [P2]
**Proč:** Profesionální dokumentace zlepšuje adopci a snižuje zátěž podpory.
**Náročnost:** Střední (restrukturace existujících docs + přidání tutoriálu)
**Dopad:** Lepší první dojem, méně problémů s onboardingem.

### 10. Přidat YOLO režim do fix-ticket a implement-feature [P2]
**Proč:** Zkušení uživatelé chtějí přeskočit potvrzení.
**Náročnost:** Malá (parsování flagů + skip logika)
**Dopad:** Rychlejší iterace pro power uživatele.

---

## Metodologické poznámky

Tato analýza byla provedena čtením kompletního zdrojového kódu obou repozitářů:
- **ceos-agents:** Všech 15 agentů v `agents/`, všech 23 příkazů v `commands/`, veškeré docs v `docs/`, CLAUDE.md, metadata pluginu, příklady, testy
- **BMAD-METHOD:** Všech 9 definic agentů v `src/bmm/agents/` a `src/core/agents/`, klíčové workflow (create-prd, create-architecture, create-epics-and-stories, dev-story, code-review, brainstorming, quick-dev, sprint-planning), všechny tasky v `src/core/tasks/`, veškerá dokumentace v `docs/`, CLI tooling v `tools/cli/`, konfigurace modulů, 12 skills v `.claude/skills/`, šablony, checklisty a systém customizace agentů

Počty souborů: ceos-agents ~60 významných souborů, BMAD-METHOD ~531 celkem souborů (~350 ne-git významných souborů).
