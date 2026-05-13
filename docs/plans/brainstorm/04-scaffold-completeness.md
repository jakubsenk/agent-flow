# Brainstorm: Scaffold Pipeline Completeness Redesign

> **Datum:** 2026-03-05
> **Status:** BRAINSTORM — ceka na rozhodnuti vlastnika projektu
> **Kontext:** Scaffold pipeline (`/scaffold`) generuje pouze kostrovy projekt, ale neprodukuje funkcni aplikaci. Tento dokument analyzuje proc a navrhuje redesign.

---

## 1. Analyza soucasneho scaffold pipeline

### Krok po kroku — co se deje dnes

```
Uzivatel zada popis projektu (prirozeny jazyk + volitelne flagy)
    |
    v
[State detection] — kontrola ciloveho adresare (prazdny/existujici/git)
    |
    v
[Stack-selector] (sonnet) — vybere tech stack (jazyk, framework, DB, CI, testy)
    |
    v
[Scaffolder] (sonnet) — generuje soubory do temp adresare v 5 davkach:
    Batch 1: Build config + entry point + struktura
    Batch 2: .gitignore, .env.example, DB config
    Batch 3: 1 smoke test + linter config
    Batch 4: Dockerfile, .dockerignore, CI config
    Batch 5: README.md + CLAUDE.md s Automation Config
    |
    v
[Validace] — build, test (1 smoke test), lint, CLAUDE.md check
    |          (max 3 retries pri selhani)
    v
[Presun] — cp z temp do ciloveho adresare
    |
    v
[Git init] — git init + commit
    |
    v
[Report] — "Next steps: vyplnte TODO v CLAUDE.md, zalozne issues, spustte /implement-feature"
```

### Co scaffold produkuje

- **10-20 souboru** kostroveho projektu
- **1 smoke test** ("app starts and responds")
- **CLAUDE.md** s Automation Config (s TODO markery pro Issue Tracker instance a Source Control remote)
- **CI/CD config** (lint -> test -> build)
- **Dockerfile** (multi-stage)

### Co scaffold NEPRODUKUJE

- Zadnou business logiku
- Zadne API endpointy (krome zakladniho health checku)
- Zadne datove modely / schema
- Zadne integrace
- Zadne realnu feature — pouze prazdnou kostru

---

## 2. Gap analyza: proc jsou aplikace nekompletni

### Gap 1: Scaffold konci u kostry — nepokracuje k implementaci

Scaffold pipeline explicitne rika: *"The skeleton is a starting point — business logic is implemented later via the Feature Pipeline."* Pipeline konci po git init a zobrazi "Next steps", ale sam nic neimplementuje.

**Problemove misto:** Mezi `/scaffold` a `/implement-feature` je manualni mezera — uzivatel musi:
1. Rucne vyplnit TODO v CLAUDE.md (Issue Tracker instance, remote)
2. Rucne zalozit issues v issue trackeru
3. Rucne spustit `/implement-feature` pro kazdy issue

### Gap 2: Chybi fixer/reviewer cyklus a robustni testovani

Scaffold pouziva pouze 2 agenty:
- **stack-selector** (read-only analyza)
- **scaffolder** (generuje soubory)

Scaffolder sam verifikuje build/test/lint (krok 4, max 3 retries), takze zakladni kvalita je kontrolovana. Ale:
- **Chybi code review** — scaffolder verifikuje ze kod builduje a prochazi testy, ale nikdo nehodnosti kvalitu, citelnost a architektonickou spravnost generovaneho kodu (zadny reviewer agent)
- **Neni fixer v iterativnim rezimu** — scaffolder nema fixer<->reviewer smycku
- **Test-engineer nepise testy** — je pouze 1 pevny smoke test, zadna systematicka test coverage

### Gap 3: Issue tracker dependency blokuje autonomni pouziti

`/implement-feature` **VYZADUJE Issue ID** jako povinny vstup. Neni mozne ho spustit bez issue trackeru. Cela feature pipeline zacina ctenim issue z trackeru a nastavenim stavu.

To znamena, ze po scaffoldu:
- Bez nastaveneho issue trackeru nelze pokracovat
- Uzivatel musi rucne vytvorit issues
- Automaticky prechod scaffold -> implementace je NEMOZNY

### Gap 4: Scaffolder nema kontext o pozadovanych features

Uzivatel pise popis projektu jako: *"REST API pro spravu uzivatelu s autentizaci a CRUD operacemi"*. Stack-selector z toho vybere tech stack, ale **tato informace o pozadovanych features se ZAHODI**. Scaffolder generuje generickou kostru bez ohledu na to, co uzivatel popsal.

### Gap 5: Spec-analyst a architect nejsou zapojeni

Feature pipeline pouziva **spec-analyst** (strukturovana specifikace) a **architect** (architektura + task tree). Scaffold pipeline tyto agenty vubec nevola — prestoze by mohli z popisu projektu vygenerovat specifikace a architekturu jeste pred scaffoldingem.

---

## 3. Analyza zavislosti na issue trackeru

### Kde je issue tracker VYZADOVAN

| Komponenta | Pouziti issue trackeru | Kriticnost |
|-----------|----------------------|------------|
| `spec-analyst` krok 1 | Cte issue details z trackeru (vstupni bod) | VYSOKA — vstupni bod |
| `spec-analyst` krok 6 | Postuje checkpoint komentar `[CLAUDE-agents] Spec analysis completed...` | NIZKA — reporting/observability |
| `implement-feature` krok 1 | Nastavuje stav issue | STREDNI — side effect |
| `implement-feature` krok X | Block handler — komentar v trackeru | STREDNI — reporting |
| `implement-feature` krok 10b | Verify — komentar v trackeru | NIZKA — post-merge |
| `publisher` krok 6 | PR popis referencuje issue | NIZKA — informacni |
| `publisher` krok 7 | Nastavuje stav issue ("For Review") + pridava komentar s PR odkazem | STREDNI — aktivni side effect |
| `rollback-agent` krok 5-6 | Postuje block komentar + nastavuje stav na Blocked | STREDNI — reporting + side effect |
| `fixer` | Cte triage/impact report (z pipeline kontextu, ne primo z trackeru) | ZADNA — cte z kontextu |
| `reviewer` | Cte bug report (z pipeline kontextu) | ZADNA — cte z kontextu |
| `test-engineer` | Cte bug report + fixer output (z pipeline kontextu) | ZADNA — cte z kontextu |

### Klicovy poznatek

**Fixer, reviewer a test-engineer issue tracker NEPOTREBUJI.** Pracuji s kontextem, ktery jim preda orchestrujici command. Jedine co potrebuji je:
- Specifikace / acceptance criteria (muze prijit z spec-analystu NEBO primo z uzivatelova popisu)
- Architektura / task tree (muze prijit z architecta)
- Diff / zmenene soubory (z fixer outputu)

**Issue tracker je potreba pouze pro:**
1. Cteni vstupnich pozadavku (nahraditelne primym vstupem)
2. Stavove prechody (volitelny side effect)
3. Block/checkpoint komenty (nahraditelne stdout reportem)
4. PR popis s issue referencí + stav update (publisher, rollback-agent — nahraditelne vynechanim)

---

## 4. Navrhovany redesign

### Koncept: Scaffold v2 — "From Description to Working App"

Novy scaffold pipeline by spojil soucasny scaffold s feature pipeline, preskocil issue tracker a provedl kompletni implementaci:

```
Uzivatel: popis projektu
    |
    v
[Stack-selector] (sonnet) — vybere tech stack
    |
    v
[Scaffolder] (sonnet) — generuje kostru (jako dnes)
    |
    v
[Validace kostry] — build + test + lint
    |
    v
[Git init] — prvni commit
    |
    v
=== NOVA FAZE: Feature Extraction & Implementation ===
    |
    v
[Spec-analyst*] (sonnet) — extrahuje features z PUVODNIHO popisu projektu
    |                        (ne z issue trackeru, ale z kontextu)
    |
    v
[Architect] (opus) — navrhne architekturu + task tree pro kazdou feature
    |
    v
[Decomposition display] — uzivatel schvali plan
    |
    v
Pro kazdou feature (sekvencne):
    |
    +---> [Fixer] (opus) — implementuje
    |         |
    |         v
    |     [Reviewer] (opus) — kontroluje (fixer<->reviewer smycka)
    |         |
    |         v
    |     [Test-engineer] (sonnet) — pise testy
    |         |
    |         v
    |     [Commit] — feat: {feature-title}
    |
    v
[Integracni testy] — cela test suite
    |
    v
[Final report] — souhrn, seznam features, test results
    |
    v
(volitelne) [Publisher] — vytvori PR pokud je remote nastaven
```

### Architektonicky diagram

```
                    /scaffold "REST API pro spravu uzivatelu"
                                    |
                    +---------------+---------------+
                    |                               |
              [Stack-selector]                 [Puvodni popis]
              (tech stack)                     (features kontext)
                    |                               |
                    v                               |
              [Scaffolder]                          |
              (kostra 10-20 souboru)                |
                    |                               |
              [Validace + Git init]                 |
                    |                               |
                    +-------------------------------+
                                    |
                              [Spec-analyst*]
                         (extrakce features z popisu)
                                    |
                              [Architect]
                         (architektura + task tree)
                                    |
                         +----[Plan display]----+
                         |     (user approval)  |
                         |                      |
                    [Feature 1]           [Feature 2]  ...
                         |                      |
                   [Fixer<->Reviewer]    [Fixer<->Reviewer]
                         |                      |
                   [Test-engineer]        [Test-engineer]
                         |                      |
                   [Commit]              [Commit]
                         |                      |
                         +----------+-----------+
                                    |
                            [Integracni testy]
                                    |
                            [Final report]
```

### Klicove designove rozhodnuti

#### A) Spec-analyst bez issue trackeru

Spec-analyst dnes v kroku 1 cte z issue trackeru. Pro scaffold pipeline je nutne vytvorit **alternativni vstupni cestu** — misto issue ID dostane primo text popisu projektu.

**Moznosti:**
1. **Modifikovat spec-analyst** — pridat podminkovy krok: "Pokud kontext obsahuje issue ID, cti z trackeru. Pokud obsahuje primy text, pouzij ten."
2. **Novy agent `feature-extractor`** — specializovany agent, ktery z popisu projektu extrahuje seznam features a pro kazdy vygeneruje spec-analyst-kompatibilni vystup.
3. **Orchestrace v commandu** — command `/scaffold` sam pripravi kontext ve formatu, ktery spec-analyst ocekava, bez nutnosti menit agenta.

**Doporuceni:** Varianta 3 (orchestrace v commandu). Agenty nemenit — command pripravi kontext tak, aby spec-analyst dostal vstup ve stejnem formatu jako od issue trackeru. Zero zmenu v agentech.

#### B) Issue tracker jako optional

Pipeline musi fungovat ve 2 rezimech:
1. **S issue trackerem** — jako dnes, plny feature pipeline
2. **Bez issue trackeru** — scaffold mod, block komenty jdou do stdout, zadne stavove prechody

#### C) Rozsah implementace — kolik features

Otazka: Ma scaffold implementovat VSECHNY features z popisu, nebo jen zakladni sadu?

**Moznosti:**
1. **Vsechny features** — plne funkcni app (risk: prilis velky scope, selhani uprostred)
2. **Core features only** — spec-analyst oznaci priority, implementuji se jen "must have"
3. **Uzivatel vybere** — plan se zobrazi, uzivatel vybere ktere features implementovat

**Doporuceni:** Varianta 3. Zobrazit plan, nechat uzivatele vybrat. Moznost `--all` flagu pro automatickou implementaci vsech.

#### D) Rollback-agent role v scaffold v2

V soucasnem feature pipeline (`implement-feature.md`, krok X) rollback-agent revertuje git zmeny pri blocku od fixeru/reviewera/test-engineera. Ve scaffold v2 pipeline je situace specificka:

**Rollback-agent v kontextu scaffoldu:**
- Rollback-agent explicitne IGNORUJE scaffolder block (krok 1: "scaffolder → STOP. Do nothing.") — cleanup kostry resi `/scaffold` command sam (smaze temp adresar).
- Pro fixer/reviewer/test-engineer blocky v nove implementacni fazi rollback-agent FUNGUJE normalne — revertuje na posledni uspesny commit.
- **Kriticke rozhodnuti pro Q6:** Pokud feature 3 z 5 selze, rollback-agent revertuje pouze posledni feature (reset na posledni commit). Features 1 a 2 zustanou zachovany — kazda byla commitnuta samostatne.
- Rollback-agent ocekava issue tracker pro block komentar (krok 5-6). Ve scaffold-only modu (bez trackeru) musi orchestrujici command zajistit, ze rollback-agent preskoci kroky 5-6 a reportuje pouze do stdout.

#### E) Interakce flagu `--lang`, `--framework`, `--db`, `--ci` s `--implement`

Existujici flagy ovlivnuji stack-selector (preskoci otazky pro pokryte kategorie). Ve scaffold v2 s `--implement`:
- Flagy primarne ovlivnuji fazi stack selection + scaffolding (jako dnes)
- Spec-analyst a architect pracuji s POPISEM projektu, ne s tech stackem — flagy je primo neovlivnuji
- Architect ale CTE existujici codebase (krok 2) — takze neprime vliv existuje: scaffold vygenerovany s `--framework fastapi` urci architekturu, kterou architect pouzije jako zaklad
- Neni nutna specialni interakce — existujici flow je dostatecny

#### F) CLAUDE.md TODO markery po implementaci

Scaffold generuje CLAUDE.md s TODO placeholdery pro Issue Tracker instance a Source Control remote. Po scaffold v2 s `--implement`:
- **TODO markery zustavaji** — scaffold v2 nevyplni Issue Tracker instance ani Source Control remote automaticky (nema odkud vzit tyto hodnoty)
- **Publisher je volitelny** — pokud remote neni nastaven, publisher se preskoci (viz navrhovany pipeline: "volitelne")
- **Dulezite:** Final report musi explicitne pripomnout uzivateli, ze CLAUDE.md stale obsahuje TODO sekce, ktere je treba vyplnit pred pouzitim dalsich pipeline commands (`/fix-bugs`, `/implement-feature`)
- Alternativa: pridat `--remote owner/repo` a `--tracker-instance url` flagy do scaffold v2, ktere by TODO markery vyplnily automaticky (rozsireni scope — zvazit v budoucnu)

#### G) Architect na minimalni codebase

Architect v kroku 2 cte existujici codebase ("Read affected codebase areas thoroughly"). U cerstve scaffoldovaneho projektu je codebase minimalni (10-20 souboru kostry bez business logiky).

**Riziko:** Architect muze produkovat suboptimalni navrhy, protoze nema kontext "realneho" kodu — navrhovane struktury nemuseji odpovidat tomu, co scaffolder vygeneroval.

**Mitigace:**
1. Architect DOSTANE scaffold output jako kontext — vi jakou strukturu scaffolder zvolil
2. Sekvencni implementace features znamena, ze architect pro feature 2+ uz vidi kod z feature 1
3. Pro prvni feature je minimalni codebase vlastne VYHODA — architect navrhovne od nuly bez legacy omezeni
4. Rizikem zustava nesoulad mezi scaffolder konvencemi a architect navrhem — command musi zajistit, ze architect dostane explicitni instrukci respektovat existujici strukturu projektu

---

## 5. Detailni navrh noveho commandu

### `/scaffold` v2 — rozsirene flagy

```
/scaffold "popis projektu" [--lang X] [--framework X] [--db X] [--ci X]
    [--implement]        # po scaffoldu pokracuj implementaci features
    [--implement --all]  # implementuj vsechny features bez ptani
    [--no-implement]     # pouze kostra (soucasne chovani)
```

Vychozi chovani: `--implement` (novy default) nebo `--no-implement` (zachovat zpetnou kompatibilitu)?

### Novy interni flow pro `--implement`

Po soucasnem scaffold flow (kroky 1-6) pokracuj:

```
7. Feature extraction
   - Vezmi puvodni popis projektu
   - Priprav kontext pro spec-analyst:
     {
       summary: "Feature: {extracted feature name}",
       description: "{detail z popisu}",
       source: "scaffold-extraction"  // marker ze to neni z trackeru
     }
   - Spust spec-analyst pro kazdy feature

8. Architecture
   - Spust architect s celkovou specifikaci
   - Explicitne instrukce: respektuj existujici scaffold strukturu
   - Architect vygeneruje task tree (dekompozice)

9. Plan display + user approval

10. Feature implementation loop
    Pro kazdy subtask z task tree:
    a) Fixer (opus) — implementace
    b) Reviewer (opus) — review (fixer<->reviewer smycka, max iteraci dle konfigurace)
    c) Test-engineer (sonnet) — testy
    d) Commit
    e) Pri blocku: rollback-agent revertuje posledni feature, pokracuj dle fail strategy

11. Integration
    - Spust celou test suite
    - Pokud selhava — debug (max pokusu dle konfigurace)

12. Final report
    - Souhrn implementovanych features
    - Test results
    - Upozorneni na TODO markery v CLAUDE.md (Issue Tracker, Source Control)
```

### Interakce s existujicimi scaffold commandy

#### `/scaffold-validate` v kontextu scaffold v2

`/scaffold-validate` dnes validuje build, testy, lint, CLAUDE.md strukturu a Docker. Ve scaffold v2:
- **Behem scaffold faze:** `/scaffold` pouziva stejnou validacni logiku interni (krok 3 — validace kostry). Zadna zmena.
- **Po implementaci features:** `/scaffold-validate` zustava uzitecny jako samostatny nastroj pro overeni stavu projektu kdykoli. Validace se nemeni — build/test/lint/CLAUDE.md check funguje nezavisle na tom, jak byl projekt vytvoren.
- **Zadna zmena potrebna** — `/scaffold-validate` je uz dostatecne genericke.

#### `/scaffold-add` v kontextu scaffold v2

`/scaffold-add` pridava komponenty (claude-md, ci, docker, tests) do existujiciho projektu. Ve scaffold v2:
- **Behem scaffold faze:** nepouziva se — scaffolder generuje vse najednou.
- **Po scaffold v2:** zustava uzitecne pro pozdejsi pridavani komponent (napr. uzivatel chce pridat Docker az po implementaci features).
- **Potencialni rozsireni:** Pokud scaffold v2 zavede `--implement`, `/scaffold-add` by mohl podporovat pridani feature do existujiciho projektu: `/scaffold-add feature "popis feature"`. To by ale bylo nove rozsireni, ne zmena stavajiciho chovani.
- **Momentalne zadna zmena potrebna** — `/scaffold-add` funguje nezavisle.

---

## 6. Vztah k existujici Decomposition konfiguraci

Automation Config uz ma sekci `Decomposition` s nasledujicimi klici:
- **Max subtasks** (default: 7) — maximalni pocet subtasku na dekompozici
- **Fail strategy** (default: fail-fast) — co delat pri selhani subtasku
- **Commit strategy** (default: squash) — jak commitovat subtasky

### Jak se Decomposition config vztahuje k scaffold v2

Scaffold v2 by mel **cist a respektovat existujici Decomposition konfiguraci** z CLAUDE.md, kterou sam vygeneroval:

| Scaffold v2 aspekt | Decomposition config klíc | Vztah |
|---------------------|---------------------------|-------|
| Limit na pocet features (Q3) | Max subtasks | **Primo pouzitelne** — kazda feature je subtask. Max subtasks = max features v jednom behu. |
| Handling selhani (Q6) | Fail strategy | **Primo pouzitelne** — `fail-fast` = zastav pipeline, `continue` = preskoc a pokracuj dalsim subtaskem. |
| Granularita commitu | Commit strategy | **Primo pouzitelne** — `squash` = jeden commit na konci, `individual` = commit per feature. |

### Klicovy poznatek

**Scaffold v2 NEMUSI definovat vlastni limity.** Muze pouzit Decomposition sekci, kterou scaffolder vygeneroval v CLAUDE.md. To znamena:
- Q3 (limit na features) se RESI existujicim `Max subtasks` (default 7)
- Q6 (handling selhani) se RESI existujicim `Fail strategy` (default fail-fast)
- Commit granularita se RESI existujicim `Commit strategy` (default squash)

Scaffolder by mel generovat rozumne defaulty v Decomposition sekci — napr. `Max subtasks: 5` pro scaffold pouziti (konzervativnejsi nez default 7 pro feature pipeline).

---

## 7. Rizikova analyza

| Riziko | Pravdepodobnost | Dopad | Mitigace |
|--------|----------------|-------|----------|
| Prilis velky scope — scaffold se pokusi implementovat prilis mnoho a selze uprostred | VYSOKA | VYSOKY | Limit z Decomposition → Max subtasks, uzivatel schvaluje plan |
| Token limit — dlouhy pipeline vycepa kontext | STREDNI | VYSOKY | Kazdy feature cycle bezi v samostatnem Task (izolace kontextu) |
| Kvalita features — bez lidskeho issue popisu budou specifikace vague | STREDNI | STREDNI | Spec-analyst ma pravo blokovat vague pozadavky; uzivatel muze doplnit |
| Zpetna kompatibilita — zmena defaultniho chovani /scaffold | NIZKA | STREDNI | `--no-implement` flag zachova puvodni chovani |
| Slozitost commandu — scaffold.md se stane prilis komplexni | STREDNI | STREDNI | Rozdelit na scaffold.md (kostra) + scaffold-implement.md (nova faze) |
| Chybejici issue tracker pro block handling | NIZKA | NIZKY | Block jde do stdout; rollback-agent preskoci kroky 5-6 (issue tracker) |
| Scaffolder generuje spatnou kostru a features pak selzou | STREDNI | VYSOKY | Validace kostry PRED zahajenim feature implementace |
| Fixer presahne 100-line diff limit na feature | VYSOKA | STREDNI | Architect musi dekomponovat features na male subtasky |
| Architect na minimalni codebase produkuje suboptimalni navrh | STREDNI | STREDNI | Architect dostane scaffold output jako kontext + instrukci respektovat existujici strukturu; sekvencni features budou narustat |
| CLAUDE.md TODO markery zustanou nevyplnene a blokuji dalsi pipeline commands | NIZKA | NIZKY | Final report explicitne upozorni uzivatele na TODO sekce |

---

## 8. Alternativni pristupy

### Pristup A: Monoliticky scaffold v2 (doporuceny)

Jeden command `/scaffold --implement` udela vse — od popisu k funkcni aplikaci. Popsano vyse.

**Pro:** Jednoduche pro uzivatele, jeden command.
**Proti:** Slozita orchestrace, dlouhy behovy cas.

### Pristup B: Scaffold + automaticke issues

Scaffold vygeneruje kostru, pak automaticky vytvori issues v trackeru a spusti `/implement-feature` pro kazdy.

**Pro:** Znovupouzije existujici feature pipeline beze zmeny.
**Proti:** Vyzaduje issue tracker — neodstranuje zavislost. Pridava dalsi krok.

### Pristup C: Novy command `/scaffold-implement`

Oddeleny command, ktery se spusti nad existujicim scaffoldem a implementuje features.

**Pro:** Separace zodpovednosti, scaffold zustane jednoduchy.
**Proti:** Uzivatel musi spustit 2 commandy. Ale umoznuje i pouziti na existujicich projektech.

### Pristup D: Hybridni — scaffold + interni scaffold-implement

`/scaffold` zustava jak je (zpetna kompatibilita). Flag `--implement` aktivuje novou fazi. Interni implementace vyuziva novy command `/scaffold-implement`, ktery `/scaffold` vola automaticky pri `--implement`, ale uzivatel ho muze spustit i samostatne na existujicim projektu.

**Pro:** Zpetna kompatibilita, modularita, znovupouzitelnost `/scaffold-implement` na libovolnem projektu. Deli slozitost do 2 souboru.
**Proti:** 2 command soubory k udrzbe. Musi sdílet kontext (puvodni popis projektu).

**Rozdil od pristupu C:** Pristup C vyzaduje manualni spusteni 2 commandu. Pristup D automaticky vola `/scaffold-implement` z `/scaffold --implement`, ale zachovava moznost samostatneho pouziti.

---

## Rozhodovaci otazky

Nasledujici otazky vyzaduji rozhodnuti vlastnika projektu pred zahajenim implementace:

### Q1: Defaultni chovani scaffoldu
Ma `/scaffold` ve vychozim stavu implementovat features (`--implement` je default), nebo zustat u soucasneho chovani (`--no-implement` je default)?

- **(a)** `--implement` je default — scaffold automaticky pokracuje k implementaci (uzivatel pouzije `--no-implement` pro starou kostru)
- **(b)** `--no-implement` je default — zpetna kompatibilita, uzivatel musi explicitne zadat `--implement`
- **(c)** Interaktivni prompt: "Chcete implementovat features? [Y/n]"

### Q2: Architektura commandu
Jak implementovat novou fazi?

- **(a)** Rozsirit stavajici `scaffold.md` o kroky 7-12
- **(b)** Novy command `scaffold-implement.md`, ktery scaffold vola (pristup D — hybridni)
- **(c)** Novy command `scaffold-implement.md` jako samostatny — uzivatel ho muze spustit i bez scaffoldu (na existujicim projektu)

### Q3: Limit na pocet features
Pouzije scaffold v2 existujici Decomposition → Max subtasks z CLAUDE.md, nebo vlastni limit?

- **(a)** Cist Decomposition → Max subtasks z vygenerovane CLAUDE.md (default 7)
- **(b)** Scaffold-specific default (napr. 5) — scaffolder generuje Decomposition s nizsi hodnotou
- **(c)** Hardcoded limit v scaffold commandu — nezavisly na Decomposition config
- **(d)** Bez limitu — uzivatel rozhodne pri schvaleni planu

### Q4: Spec-analyst vstup bez issue trackeru
Jak zajistit, ze spec-analyst dostane kvalitni vstup bez issue trackeru?

- **(a)** Command sam pripravi "fake issue" kontext z popisu projektu — spec-analyst se nemeni
- **(b)** Pridat spec-analystu podminkovy krok pro primy textovy vstup
- **(c)** Novy agent `feature-extractor` ktery z popisu projektu extrahuje features

### Q5: Issue tracker v scaffold pipeline
Jak nakládat s issue tracker dependency specificky ve scaffold pipeline?

- **(a)** Scaffold v2 funguje zcela bez issue trackeru — block komenty do stdout, publisher preskocen nebo vytvori PR bez issue reference
- **(b)** Scaffold v2 detekuje, zda je issue tracker nakonfigurovan (TODO markery vs. realne hodnoty v CLAUDE.md) a pouzije ho pokud je dostupny, jinak stdout fallback
- **(c)** Scaffold v2 vyzaduje `--no-tracker` flag pro explicitni opt-out z issue trackeru

*Poznamka: Otazka globalni optional issue tracker dependency pro vsechny pipeline commands (`/implement-feature`, `/fix-bugs` atd.) je mimo scope tohoto dokumentu a vyzaduje samostatny brainstorm.*

### Q6: Handling selhani uprostred implementace
Pouzije scaffold v2 existujici Decomposition → Fail strategy, nebo vlastni logiku?

- **(a)** Cist Decomposition → Fail strategy z CLAUDE.md (default: fail-fast)
- **(b)** Scaffold-specific default (continue) — scaffolder generuje odlisny default
- **(c)** Vzdy se zeptat uzivatele pri selhani: "Feature X selhala. Preskocit a pokracovat? [Y/n]"

Pri libovolne variante: rollback-agent revertuje pouze posledni neuspesnou feature (reset na posledni uspesny commit). Predchozi features zustanou zachovany.

### Q7: Publisher na konci scaffoldu
Ma scaffold na konci vytvorit PR, nebo jen lokalni commit?

- **(a)** Vzdy jen lokalni commity — scaffold bezi na novem projektu, remote nemusi existovat
- **(b)** Nabidnout PR pokud je remote nastaven (a CLAUDE.md nema TODO marker v Source Control)
- **(c)** Nechat na uzivateli — zobrazit instrukce

### Q8: Commit granularita
Jak commitovat features ve scaffold v2?

- **(a)** Cist Decomposition → Commit strategy z CLAUDE.md (default: squash — jeden commit za vsechny features)
- **(b)** Vzdy individual — kazda feature je samostatny commit (lepsi git historie pro novy projekt)
- **(c)** Scaffold-specific default (individual) nezavisly na Decomposition config

### Q9: Vztah k Decomposition konfiguraci — souhrnne
Ma scaffold v2 cist existujici Decomposition sekci z CLAUDE.md (Q3, Q6, Q8), nebo mit zcela vlastni konfiguraci?

- **(a)** Pouzit Decomposition config — konzistentni chovani napric pipeline, scaffolder generuje rozumne defaults
- **(b)** Vlastni scaffold-specific konfigurace — nezavisle na Decomposition, ale riziko duplikace
- **(c)** Cist Decomposition config, ale scaffolder generuje scaffold-optimalizovane defaulty (napr. Max subtasks: 5 misto 7, Commit strategy: individual misto squash)

### Q10: Priorita implementace
Je tohle priorita pro dalsi release, nebo budouci prace?

- **(a)** Dalsi minor release (v3.4.0)
- **(b)** Dalsi major release (v4.0.0 — protoze meni chovani commandu)
- **(c)** Odlozeno — neni aktualni priorita

---

