# Perspektiva 2 — Inovativni strateg

**Role:** Inovativni technicky strateg
**Pristup:** Vizionarsky, zamereny na business value a "wow" efekt pro CEO prezentaci
**Datum:** 2026-04-10

---

## 1. Prilezitosti — Co CEO nejvice zaujme

### 1.1 "Od ticketu k pull requestu za 15 minut"

Toto je hlavni story. CEO nerozumi pipeline architekture, ale rozumi jednomu cislu: **cas**. Kdyz se standardni bug-fix cyklus v Oracle PL/SQL prostredi (analyza → implementace → review → test → PR) meri na dny a zapojuje 2-3 lidi, ceos-agents to zvladne za jednu session bez lidske interakce.

Demonstrace: Zalozit realisticky Redmine ticket ("SUM_KOMPENZACE vraci NULL pri prazdnem inputu"), spustit `/ceos-agents:fix-ticket`, a nechat CEO sledovat v realnem case:
1. Agent si precte ticket, extrahuje acceptance criteria
2. Analyzuje PL/SQL kod, najde root cause
3. Opravi, napise utPLSQL test, zkompiluje
4. Reviewer zkontroluje — mozna pozada o zmenu, fixer opravi
5. PR je otevreny v Gitea

**Wow faktor:** Cela demonstrace je transparentni — kazdy krok je videt v terminalu. Neni to "black box AI" ale auditable pipeline.

### 1.2 "AI neprogramuje — AI ridi vyvojovy proces"

Klic k prezentaci neni "AI napise kod" (to kazdy ocekava). Klic je: **AI ridi kvalitu**. Kazdy ticket ma:
- Acceptance criteria (2-5 polozek) — extrahuje agent z popisu
- Kazde AC je sledovane pres celou pipeline (maps_to traceability)
- Reviewer explicitne overuje plneni AC — FULFILLED / PARTIALLY / NOT ADDRESSED
- Acceptance gate (pokud je AC >= 3 nebo slozitost >= M) provede finalni verifikaci s dukazy v kodu

To je neco, co ani lidske tymy nedodrzuji konzistentne. Agent nikdy nepreskoci review. Agent nikdy "nemergnuje bez testu protoze horime."

### 1.3 "Nulove riziko nevratne skody"

Kazdy agent, ktery sezuje (fixer, test-engineer, reviewer loop) ma rollback-agent, ktery vrati git stav. Pipeline nikdy nepushne na main. Vzdy vytvori PR a pocka na lidske schvaleni.

Pro CEO to znamena: **Muzeme experimentovat bez strachu.** Nejhorsi co se stane je zablokovany ticket s detailnim komentarem proc agent neuspal. Zadna data se neztrati, zadny deploy se nerozbije.

---

## 2. Quick Wins — Ukazka za 1-2 dny

### Quick Win #1: Jednorazovy analyze-bug demo (2 hodiny)

**Co:** Zalozit 3 tickety v Redmine (realne bugy z SK kompenzace), spustit `/ceos-agents:analyze-bug` na kazdy.
**Vysled:** Strukturovany vysledek analyzy — root cause, affected files, navrzena oprava, odhadovana slozitost — bez jedine zmeny v kodu.
**Proc:** Toto je "free trial" agentickeho vyvoje. Zadne riziko, zadne zmeny, jen demonstrace analytickych schopnosti. CEO vidi, ze agent rozumi Oracle PL/SQL a Redmine.
**Pripravu:** 30 minut (Automation Config + MCP config).

### Quick Win #2: Full pipeline na demo bugu (4 hodiny)

**Co:** Pripravit jednoduchy kontrolovany bug (napr. spatny NVL v package body), spustit `/ceos-agents:fix-ticket`.
**Vysled:** PR v Gitea s opravou, utPLSQL testem, strukturovanym popisem.
**Proc:** End-to-end demo, ktery dokazuje cely workflow.
**Priprava:** 2 hodiny (customization/fixer.md + customization/test-engineer.md + overeni Docker stacku).

### Quick Win #3: Dashboard (30 minut po prvnim runu)

**Co:** Po prvnim uspesnem runu spustit `/ceos-agents:dashboard`.
**Vysled:** Interaktivni HTML stranka s pipeline statistikami, timeline aktivit, blocked issues panelem.
**Proc:** Management miluje dashboardy. Toto ukazuje, ze agenticky vyvoj neni "black box" ale plne pozorovatelny proces.

### Quick Win #4: Cost estimate pred CEO (10 minut)

**Co:** Spustit `/ceos-agents:estimate <ISSUE-ID>` na libovolnem ticketu.
**Vysled:** Tabulka best/typical/worst case s odhadem tokenu a USD ceny.
**Proc:** Adresuje okamzitou otazku CEO: "Kolik to stoji?" Odpoved: "$2-8 za typicky bug fix, $5-26 pro slozite."

---

## 3. Rozsirene scenare — Kam to muze vest

### 3.1 Feature Pipeline: Od pozadavku k implementaci

SK kompenzace neni jen o bugfixech. Jak se vyvojovy proces rozjede, prijdou nove pozadavky. ceos-agents ma plnohodnotny **feature pipeline**:

```
Redmine ticket → Spec-analyst (extrahuje AC, post zpet do ticketu)
  → Architect (navrhne task tree s maps_to vazbami)
  → Dekompozice (pokud slozite — az 7 subtasku)
  → Fixer ↔ Reviewer (pro kazdy subtask)
  → Test-engineer → Publisher
```

**Business value:** Analytik napise pozadavek do Redmine, agent ho rozlozi na technicky plan, implementuje, otestuje a predlozi k review. Analytik (nebo vyvojar) jen schvaluje vysledek.

**Timeline:** Nasazeni feature pipeline = +1 den konfigurace nad bug-fix pipeline (sdili Automation Config).

### 3.2 Scaffold Pipeline: Novy projekt za hodinu

Pokud CEOS data chce budoucne vytvoret novy produkt/mikrosluzbu, `/ceos-agents:scaffold` dokaze:
1. Z popisu v prirozene reci vygenerovat specifikaci (EARS format)
2. Vybrat tech stack (stack-selector agent)
3. Vytvorit kostru projektu (adresarova struktura, build skripty, CI/CD)
4. Inicializovat git, vytvorit epics v Redmine
5. Implementovat prvni features (fixer ↔ reviewer loop)
6. Validovat celou spec (spec-reviewer --verify)

**Pro Oracle PL/SQL:** Tohle je obzvlast mocne. Scaffolding PL/SQL projektu (migrace schema, utPLSQL setup, deploy.sh, Flyway konfigurace) je nudna a repetitivni prace. Agent to udela za minuty.

### 3.3 Batch Processing: Fronta bugu pres noc

`/ceos-agents:fix-bugs 10` — zpracuj 10 bugu z fronty. Spustit vecer, rano zkontrolovat vysledky.

**Scenar pro SK kompenzace:** Po pocatecni analyze se casto objevi 20-30 "low hanging fruit" bugu. Namisto alokace vyvojare na tyden monotonni prace:
1. Oznacit tickety v Redmine jako "Ready" (filtr v Bug query)
2. Spustit batch
3. Rano zkontrolovat: X oprav ceka na review, Y zablokovanych s jasnym duvodem proc

**Business value:** Developer se muze venovat architektonickym rozhodnutim a code review, zatimco agent resi rutinu.

### 3.4 Prioritize + Estimate: Inteligentni backlog management

`/ceos-agents:prioritize` analyzuje cely backlog a navrhne poradce oprav pomoci AI prioritizace. `/ceos-agents:estimate` pred kazdym ticketem odhadne naklady.

**Scenar:** Pred planovacim meetingem spustit prioritize → management dostane serazeny backlog s odhady casu a nakladu. Data-driven rozhodovani misto "citoveho" odhadu seniorniho vyvojare.

### 3.5 Multi-Agent Discussion: Architektonicke rozhodovani

`/ceos-agents:discuss "Mame pouzit materialized views nebo in-memory cache pro kompenzacni sumarizace?"` — spusti diskuzi mezi 2-3 agenty (architekt, security reviewer, performance expert) a syntetizuje doporuceni.

**Business value:** Ziskani vice perspektiv na technicke rozhodnuti bez nutnosti svolat meeting 3 seniornich lidi.

---

## 4. Kompetitivni vyhoda — Co ceos-agents umi a nikdo jiny ne

### 4.1 Tabulka unikatnich vlastnosti

Trzni analyza (docs/plans/readmine-project/ceos-agents-market-analysis.md) zmapovala 8 nejblizsich alternativ. Zadna nema vsechny 4 klicove vlastnosti soucasne:

| Vlastnost | ceos-agents | GAAI Framework | Amazon Kiro | Deepsense.ai |
|-----------|:-----------:|:--------------:|:-----------:|:------------:|
| Named pipeline stages (skip/add) | ANO | NE | NE | NE |
| AC tracking end-to-end | ANO | castecne | castecne | NE |
| Automaticky git rollback pri selhani | ANO | NE | NE | NE |
| Spec-driven development (bug + feature + scaffold) | ANO | NE | castecne | NE |
| Multi-tracker podpora (6 systemu) | ANO | NE | Jira only | Jira only |
| Agent overrides (per-project customizace) | ANO | NE | NE | NE |
| Pipeline profiles | ANO | NE | NE | NE |
| Resume-ticket (pokracovani po selhani) | ANO | NE | NE | NE |

### 4.2 Specificke vyhody pro Oracle PL/SQL prostredi

1. **Agnosticky build/test system** — zadny predpoklad o technologii. `deploy.sh` a `test.sh` jako shell stringy funguje primo.
2. **Opus model rozumi PL/SQL** — interpretuje ORA-XXXXX chyby, rozumi package spec/body separaci, Flyway migracim.
3. **Agent Overrides** — PL/SQL konvence (check_errors.sh, naming conventions, utPLSQL anotace) se vlozi jednou a plati pro vsechny future runy.
4. **Zadna zavislost na NPM/Python/Docker** — plugin je pure markdown. Jedina zavislost je Claude Code CLI.

### 4.3 Storytelling pro CEO

> "Konkurencni nastroje (Cursor, Copilot, Devin) pomahaji programatorovi programovat. ceos-agents automatizuje celou cestu od pozadavku k hotovemu pull requestu — vcetne kvalitativnich kontrol, ktere lidske tymy casto preskakuji."

---

## 5. Roadmap pro postupnou adopci

### Faze 1: "Pozorovatel" (Tyden 1)

| Co | Jak | Riziko |
|----|-----|--------|
| Pouze analyza — zadne zmeny kodu | `/analyze-bug` na 5-10 existujicich ticketech | Nulove |
| Demonstrate AI pochopeni codebase | Agent overrides pro PL/SQL konvence | Minimalni |
| Dashboard s vysledky analyzy | `/dashboard` po runech | Nulove |

**Cil:** Ziskat duveru tymu. Ukazat ze agent rozumi domene.

### Faze 2: "Asistent" (Tyden 2-3)

| Co | Jak | Riziko |
|----|-----|--------|
| Full pipeline na kontrolovanych bugech | `/fix-ticket` na 3-5 "easy" ticketech | Nizke — rollback chrani |
| Lidske review kazdeho PR | Standard code review proces | Nulove |
| Metriky a cost tracking | `/metrics`, `/estimate` | Nulove |

**Cil:** Prvni uspesne PR mergnute do main. Measurable data o case a kvalite.

### Faze 3: "Spolupracovnik" (Tyden 4-6)

| Co | Jak | Riziko |
|----|-----|--------|
| Batch processing | `/fix-bugs 5` na front bugech | Stredni — retry limity nastavit konzervativne |
| Feature pipeline | `/implement-feature` na jednom pozadavku | Stredni — slozitejsi nez bugfix |
| Decomposition pro slozite ukoly | `--decompose` flag | Stredni — subtask loop |

**Cil:** Rutinni pouzivani pro jednoduche az stredni ukoly. Developer se soustedi na review a architektonicke rozhodnuti.

### Faze 4: "Autonomni clen tymu" (Mesic 2-3)

| Co | Jak | Riziko |
|----|-----|--------|
| Nocni batch run | Cron job + `/fix-bugs 10` | Stredni — nutny monitoring |
| Scaffold pro nove moduly | `/scaffold` pro nove PL/SQL balicky | Nizke |
| Prioritize pro backlog management | `/prioritize` pred planovanim | Nulove |
| Plna integrace do vyvojoveho procesu | Kazdy ticket prochazi pipeline | Vyzaduje process change |

**Cil:** Agent je bezna soucast vyvojoveho workflow, ne experiment.

---

## 6. Metriky uspechu — Jak merit hodnotu agentickeho vyvoje

### 6.1 Primarne metriky (pro management)

| Metrika | Zdroj | Baseline (bez agenta) | Cil (s agentem) |
|---------|-------|----------------------|-----------------|
| **Cas od ticketu do PR** | Redmine + Git timestamps | 2-5 dnu | 1-4 hodiny |
| **Pocet oprav/tyden** | `/metrics` report | 3-5 (manualne) | 15-25 (agent + review) |
| **Naklady na opravu** | `/estimate` + API billing | ~800 CZK (2h vyvojare) | ~50-200 CZK ($2-8 API) |
| **Pomer uspesnych oprav** | `/metrics` success_rate | N/A | >70% (bez lidske intervence) |
| **Pokryti testy** | utPLSQL report | castecne | 100% novych oprav |

### 6.2 Sekundarne metriky (pro technicke vedeni)

| Metrika | Zdroj | Co sleduje |
|---------|-------|-----------|
| **Block rate per agent** | `/metrics` block_analysis | Ktere kroky pipeline nejcasteji selhavaji |
| **Fixer iterations (avg)** | `/metrics` per_agent | Kvalita prvniho pokusu — mene iteraci = lepsi |
| **Review rejection rate** | Git PR data | Kvalita agent-generovaneho kodu |
| **Time in review** | Git timestamps | Jak rychle lide schvaluji agent PRs |
| **Agent Override effectiveness** | Pred/po porovnani | Zlepsuji PL/SQL custom instrukce kvalitu? |

### 6.3 ROI kalkulace pro CEO

**Konzervativni scenar (Faze 2, 3 mesice):**

```
Agent opravi: 10 bugu/tyden × 12 tydnu = 120 bugu
Cas vyvojare usetren: 120 × 3h = 360 hodin
Naklady vyvojare: 360h × 400 CZK/h = 144,000 CZK
Naklady API: 120 × $5 avg × 25 CZK = 15,000 CZK
Cisty usetren cas: 144,000 - 15,000 = 129,000 CZK

ROI = 129,000 / 15,000 = 8.6x
```

**Agresivni scenar (Faze 4, 6 mesicu):**

```
Agent opravi + implementuje: 25 ukolu/tyden × 24 tydnu = 600 ukolu
Cas vyvojare usetren: 600 × 4h = 2,400 hodin
Naklady vyvojare: 2,400h × 400 CZK/h = 960,000 CZK
Naklady API: 600 × $8 avg × 25 CZK = 120,000 CZK
Cisty usetren cas: 960,000 - 120,000 = 840,000 CZK

ROI = 840,000 / 120,000 = 7x
```

### 6.4 Kvalitativni metriky (nemeritelne, ale dulezite)

- **Konzistence kvality:** Agent nikdy nevynecha review, nikdy nepromeskne AC, nikdy "nepreskoci test protoze je patek odpoledne"
- **Knowledge capture:** Agent Overrides a Automation Config jsou ziva dokumentace vyvojoveho procesu
- **Onboarding:** Novy clen tymu vidi fungujici pipeline a rozumi procesu behem hodin misto tydnu
- **Audit trail:** Kazdy ticket ma strukturovane komentare — kdo (ktery agent) co udelal a proc

---

## 7. Rizika a mitigace

| Riziko | Pravdepodobnost | Dopad | Mitigace |
|--------|----------------|-------|----------|
| CEO ocekava 100% uspesnost | Vysoka | Vysoky | Prezentovat realisticky: 70-80% success rate, zbytek vyzaduje lidsky zasah |
| API naklady prekvapi | Stredni | Stredni | `/estimate` pred kazdym runem, konzervativni retry limity |
| Tym odmitne "AI replacement" | Stredni | Vysoky | Framovat jako "AI asistent" ne "nahrada"; developer ridi review |
| PL/SQL specificke chyby | Vysoka | Nizky | Agent Overrides + iterativni zlepsovani |
| Status ID mapovani sezve | Stredni | Stredni | Agent Override s explicitnim mapovanim; testovat na prvnim ticketu |

---

## 8. Zaverecne doporuceni

### Hlavni message pro CEO:

> ceos-agents neni "dalsi AI kodovaci nastroj." Je to **automatizovany vyvojovy proces** s kontrolou kvality, auditable rozhodovanim a meritelnou navratnosti. Pro Oracle PL/SQL prostredi SK kompenzace je pripraveny k nasazeni behem 1-2 dnu s nulovym rizikem — kazda akce je reverzibilni, kazdy vysledek prochazi lidskym review.

### Tri klicova cisla pro prezentaci:

1. **15 minut** — od ticketu k pull requestu (demonstrace na zivu)
2. **8x ROI** — konzervativni odhad navratnosti za 3 mesice
3. **6 trackeru, 3 pipeline, 19 agentu** — enterprise-ready, ne prototyp

### Nejsilnejsi argument:

Agent nedela jen to, co programator nestihne. Agent dela to, co **programator neudela** — konzistentni AC tracking, rollback pri selhani, strukturovane block komentare, 100% pokryti novych oprav testy. To je kvalita, kterou ziskate _navic_, ne misto neceho.
