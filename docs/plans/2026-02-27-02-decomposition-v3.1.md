# Task Decomposition v3.1 — Design Document

**Datum:** 2026-02-27
**Status:** SUPERSEDED — implemented in v3.0.0
**Faze:** 2
**Verze pluginu:** v3.1.0 (MINOR)
**Zavisi na:** Faze 1 (Feature Pipeline v3.0) — castecne (viz sekce 7: ~60% implementovatelne nezavisle)

> **[ROZHODNUTO]** Verze ponechana jako v3.1.0 (Varianta A). Design doc verze = planovaci verze dle roadmapy, ne release verze. Skutecny release dostane SemVer podle poradi shippovani. Dokument v sekci 7 jasne definuje, co je nezavisle a co zavisi na Fazi 1 — to staci.

---

## 1. Vize & cil

### Proc dekompozice

Soucasna pipeline CLAUDE-agents zpracovava kazdy ticket jako **jednu atomickou jednotku**: triage -> code-analyst -> fixer -> reviewer -> test-engineer -> publisher. Fixer ma hard limit 100 radku diffu (viz `agents/fixer.md`, sekce Constraints: "Diff > 100 lines -> reconsider approach, likely over-engineering"). Code-analyst hlasi max 5 affected files.

Tohle funguje skvele pro izolovane bugy — off-by-one error, chybejici null check, spatny SQL dotaz. Ale existuji scenare, kde je to nedostatecne:

1. **Slozite bugy** presahujici 100 radku: race condition vyrazejici se ve 3 sluzbach, data corruption vyzadujici migracni skript + opravny kod + testy. Fixer narazi na limit a blokne issue.

2. **Feature implementace** (Faze 1): nova feature se rozpadne na N dilcich ukolu — API endpoint, databazovy model, UI komponenta, integracni testy. Implementer (reuse fixer agenta) nemuze vsechno zvladnout v jednom pruchodu.

3. **Refaktoringy spojene s bugfixem**: oprava vyzaduje nejdrive restrukturalizaci kodu (rozdeleni monolitickeho souboru), pak teprve vlastni fix. Dve logicky oddelene operace.

### Co dekompozice prinasi

| Benefit | Dnesni stav | S dekompozici |
|---------|-------------|---------------|
| Spolehlivost | Slozite issues se blokuji | Mensi subtasky = mensi blast radius |
| Kvalita review | Reviewer dostane 200-radkovy diff | Reviewer dostane 3x 50-radkovy diff |
| Testovatelnost | Jeden velky commit | Kazdy subtask testovan samostatne |
| Paralelismus | Sekvencni zpracovani | Nezavisle subtasky mohou bezet paralelne (worktrees) |
| Resumabilita | Block = zacni znovu | Block na subtask 3/5 = pokracuj od 3 |
| Transparentnost | Cerna skrinka fixeru | Jasny plan s viditelnymi kroky |

### Soucasne omezeni v praxi

Kdyz dnes code-analyst (viz `agents/code-analyst.md`) reportuje 5 affected files s HIGH risk a fixer se pokusi o opravu, typicky nastane:

1. Fixer vygeneruje diff >100 radku -> sam se zablokuje (Constraints)
2. Reviewer vrati REQUEST_CHANGES -> fixer se pokusi o mensi zmenu -> ztrati kontext -> blokuje
3. Po 5 iteracich fixer<->reviewer (konfigurabilne pres Retry Limits) se issue blokne

S dekompozici: Architect agent (z Faze 1) rozlozi problem na 3 subtasky po ~40 radcich, kazdy projde celou pipeline samostatne, vysledek se slouci do jednoho PR.

### Jak dekompozice meni hru

Dekompozice transformuje pipeline z **linearniho procesu** na **orchestraci task grafu**:

```
DNES (v2.0):
  Issue -> [triage -> analysis -> fix -> review -> test -> publish]
           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
                     Jeden monoliticky pruchod

S DEKOMPOZICI (v3.1):
  Issue -> [triage -> analysis -> DECOMPOSE]
                                     |
                          +----------+----------+
                          |          |          |
                      subtask-1  subtask-2  subtask-3
                          |          |          |
                      [fix->rev->test] [fix->rev->test] [fix->rev->test]
                          |          |          |
                          +----------+----------+
                                     |
                              [integration test]
                                     |
                                 [publish]
```

Klicova zmena: pipeline uz neni flat sekvence, ale **strom s orchestracnim enginem** na vrchu.

---

## 2. Decomposition Engine — Algoritmus

### Rozhodovaci algoritmus: kdy dekomponovat vs. single-pass

Ne kazdy ticket potrebuje dekompozici. Engine musi rozhodnout automaticky (nebo na zaklade flagu `--decompose`).

**Vstup:** Vystup code-analyst agenta (pro bug-fix) nebo Architect agenta (pro feature).

**Rozhodovaci kriteria:**

| Kriterium | Prah pro dekompozici | Zdroj dat |
|-----------|---------------------|-----------|
| Pocet affected files | >= 4 | code-analyst / architect output |
| Odhadovana velikost diffu | > 60 radku | code-analyst recommended approach |
| Risk level | HIGH | code-analyst risk assessment |
| Logicka nezavislost | >= 2 nezavisle zmeny | architect / code-analyst analysis |
| Explicitni flag | `--decompose` | uzivatel |

**Rozhodovaci logika:**

```
VSTUP: analysis_output, user_flags

if "--no-decompose" in user_flags:
    return SINGLE_PASS

if "--decompose" in user_flags:
    return DECOMPOSE

if analysis_output.risk == HIGH:
    return DECOMPOSE

if analysis_output.affected_files >= 4:
    return DECOMPOSE

if analysis_output.estimated_diff_lines > 60 and analysis_output.affected_files >= 3:
    return DECOMPOSE

if analysis_output.independent_changes >= 2:
    return DECOMPOSE

return SINGLE_PASS
```

**Poznamka:** Prah 60 radku pouziva kombinovany signal: `> 60 lines AND >= 3 affected files`. Samotnych >60 radku nestaci — bug v 1-2 souborech projde fixerem primo, i kdyz ma 60-80 radku. Kombinace s poctem souboru odfiltruje false positives a zaroven zachova buffer pred 100-line limitem fixeru.

> **[ROZHODNUTO]** Threshold pouziva kombinovany signal (Varianta B): `> 60 lines AND >= 3 affected files`. Samotny pocet radku je slaby signal — vetsina normalnich bugu je 1-2 soubory. Podminka `>= 3 files` odfiltruje jednoduche bugy, ktere jsou jen trochu vetsi, ale stale atomicke.

### Sekvencni vs. paralelni mod

Po rozhodnuti "DECOMPOSE" nasleduje volba execution modu:

| Kriterium | Sekvencni | Paralelni |
|-----------|-----------|-----------|
| Subtasky maji zavislosti | ANO | NE |
| Worktrees konfigurovany | Jedno | ANO |
| Pocet subtasku | <= 2 | >= 3 |
| Subtasky sdili soubory | ANO | NE |
| Default | ANO | NE |

**Rozhodovaci logika:**

```
VSTUP: task_tree, automation_config

# Paralelni mod vyzaduje Worktrees config
if "Worktrees" not in automation_config:
    return SEQUENTIAL

# Pokud subtasky maji zavislosti, sekvencni
if task_tree.has_dependencies():
    # I s worktrees — zavislosti vynucuji sekvenci
    # VYJIMKA: nezavisle podstromy mohou bezet paralelne
    independent_groups = task_tree.get_independent_groups()
    if len(independent_groups) > 1:
        return PARALLEL_GROUPS  # Skupiny paralelne, uvnitr skupiny sekvencne
    return SEQUENTIAL

# Pokud subtasky sdili soubory, sekvencni (vyhnuti se merge konfliktum)
if task_tree.has_shared_files():
    return SEQUENTIAL

# Vsechno ostatni: paralelne (pokud je batch_size >= 2)
if automation_config.worktrees.batch_size >= 2:
    return PARALLEL

return SEQUENTIAL
```

### ASCII Flowchart rozhodoveho procesu

```
                    +------------------+
                    | Vstup: analysis  |
                    | output + flags   |
                    +--------+---------+
                             |
                    +--------v---------+
                    | --no-decompose?  |--ANO--> SINGLE_PASS
                    +--------+---------+
                             | NE
                    +--------v---------+
                    | --decompose?     |--ANO--> DECOMPOSE (*)
                    +--------+---------+
                             | NE
                    +--------v---------+
                    | risk == HIGH?    |--ANO--> DECOMPOSE (*)
                    +--------+---------+
                             | NE
                    +--------v---------+
                    | files >= 4?      |--ANO--> DECOMPOSE (*)
                    +--------+---------+
                             | NE
                    +--------v---------+
                    | diff > 60 lines? |--ANO--> DECOMPOSE (*)
                    +--------+---------+
                             | NE
                    +--------v---------+
                    | independent >= 2?|--ANO--> DECOMPOSE (*)
                    +--------+---------+
                             | NE
                             v
                        SINGLE_PASS


  (*) DECOMPOSE vetev:

                    +------------------+
                    |    DECOMPOSE     |
                    +--------+---------+
                             |
                    +--------v---------+
                    | Architect/       |
                    | code-analyst     |
                    | generuje task    |
                    | tree             |
                    +--------+---------+
                             |
                    +--------v---------+
                    | Worktrees v      |--NE--> SEQUENTIAL
                    | config?          |
                    +--------+---------+
                             | ANO
                    +--------v---------+
                    | Zavislosti mezi  |--ANO--> SEQUENTIAL
                    | subtasky?        |         (nebo PARALLEL_GROUPS
                    +--------+---------+          pokud jsou nez. skupiny)
                             | NE
                    +--------v---------+
                    | Sdilene soubory? |--ANO--> SEQUENTIAL
                    +--------+---------+
                             | NE
                             v
                         PARALLEL
```

### Role Architect agenta (Faze 1) v dekompozici

Architect agent (definovany v Fazi 1, model: opus, read-only) je zodpovedny za:

1. **Analyzu rozsahu** — kolik logickych celku ma issue
2. **Rozklad na subtasky** — kazdy subtask s jasnym scope, affected files, acceptance criteria
3. **Identifikaci zavislosti** — ktery subtask musi byt pred kterym
4. **Odhadem velikosti** — priblizny pocet radku na subtask

**Vystupni format Architect agenta** (predavany decomposition enginu):

```yaml
decomposition:
  strategy: sequential | parallel | mixed
  reason: "3 nezavisle zmeny ve 3 ruznych modulech"
  subtasks:
    - id: "subtask-1"
      title: "Oprava validace vstupu v UserService"
      scope: "Zmena validacni logiky v UserService.validate()"
      files:
        - src/services/UserService.ts
        - src/validators/inputValidator.ts
      estimated_lines: 25
      depends_on: []
      acceptance_criteria:
        - "UserService.validate() odmitne prazdny email"
        - "Existujici testy prochazi"

    - id: "subtask-2"
      title: "Pridani error handleru do API controlleru"
      scope: "Novy error handler pro validacni chyby"
      files:
        - src/controllers/UserController.ts
        - src/middleware/errorHandler.ts
      estimated_lines: 35
      depends_on: ["subtask-1"]
      acceptance_criteria:
        - "API vraci 400 s popisem chyby pri nevalidnim vstupu"

    - id: "subtask-3"
      title: "Integracni test pro validacni flow"
      scope: "E2E test validacniho flow"
      files:
        - tests/integration/userValidation.test.ts
      estimated_lines: 40
      depends_on: ["subtask-1", "subtask-2"]
      acceptance_criteria:
        - "Test pokryva happy path + chybove scenare"
```

### Fallback: co kdyz Architect nemuze dekomponovat

Scenare, kdy dekompozice selze:

1. **Issue je prilis vague** — Architect nema dost informaci pro rozklad
2. **Issue je skutecne atomicka** — nelze smysluplne rozdelit
3. **Architect vygeneruje >max_subtasks** — explodujici dekompozice

**Fallback strategie (instrukce pro command engine):**

1. **Architect nemuze dekomponovat:** Pokud Architect (nebo heuristika) nevraci platny task tree:
   - Pokud odhadovany diff <= 100 radku: fallback na SINGLE_PASS (fixer to zvladne v jednom pruchodu).
   - Pokud odhadovany diff > 100 radku: BLOCK — issue je prilis velke pro single-pass i pro dekompozici. Doporuceni: "Rucne rozlozte issue na vice mensich issues v trackeru."

2. **Architect vygeneroval prilis mnoho subtasku (> max_subtasks):**
   - Pozadej Architecta o re-dekompozici s hintem: "Max {max_subtasks} subtasku. Sluc mensi kroky do vetsich celku."
   - Pokud druhy pokus stale prekracuje limit: BLOCK s doporucenim "Dekompozice prilis granularni, rozlozte issue rucne na vice issues v trackeru."

---

## 3. Dependency Graph

### Jak se modeluji zavislosti mezi subtasky

Zavislosti mezi subtasky tvori **Directed Acyclic Graph (DAG)**. Kazdy subtask je uzel, hrana A -> B znamena "B nemuze zacit, dokud A neni hotovy (completed)".

### Datova struktura

**Volba: DAG (Directed Acyclic Graph)** — konkretne adjacency list s topologickym razenim.

Alternativy a proc ne:
- **Ordered list** (jednoduchy array): Nemodeluje paralelismus. Subtask 2 a 3 muzou byt nezavisle, ale ordered list je vynucuje sekvencne.
- **Strom (tree)**: Prilis restriktivni — nezvladne diamond pattern (A -> [B, C] -> D). DAG ano.
- **DAG**: Zvlada vsechny vzory, umoznuje paralelismus i sekvenci, dobre detekovatelne cykly.

**Interni reprezentace:**

```yaml
# Task tree = DAG
dag:
  nodes:
    subtask-1:
      title: "..."
      status: pending | in_progress | completed | failed | blocked | skipped
      depends_on: []          # root node — zadne zavislosti
    subtask-2:
      title: "..."
      status: pending
      depends_on: ["subtask-1"]
    subtask-3:
      title: "..."
      status: pending
      depends_on: ["subtask-1"]
    subtask-4:
      title: "..."
      status: pending
      depends_on: ["subtask-2", "subtask-3"]  # diamond — ceka na oba

  # Odvozeno z depends_on:
  execution_order:  # topologicky sort
    - level-0: ["subtask-1"]           # zadne zavislosti
    - level-1: ["subtask-2", "subtask-3"]  # oba zavisi jen na subtask-1
    - level-2: ["subtask-4"]           # zavisi na subtask-2 i subtask-3
```

### Priklady dependency vzoru

#### Linear chain (A -> B -> C)

Typicky pripad: refaktoring -> oprava -> test. Kazdy krok stavi na predchozim.

```
    +---+     +---+     +---+
    | A | --> | B | --> | C |
    +---+     +---+     +---+

  A: Rozdeleni monolitickeho souboru na 2 moduly
  B: Oprava bugu v novem modulu
  C: Update importu ve vsech callerech
```

**DAG reprezentace:**
```yaml
nodes:
  A: { depends_on: [] }
  B: { depends_on: ["A"] }
  C: { depends_on: ["B"] }
execution_order:
  - ["A"]
  - ["B"]
  - ["C"]
```

**Moznost paralelismu:** Zadna — plne sekvencni.

#### Fan-out (A -> [B, C, D])

Typicky pripad: spolecny zaklad (migrace, nove typy), pak nezavisle zmeny v ruznych modulech.

```
                +---+
           +--> | B |
           |    +---+
    +---+  |    +---+
    | A | -+--> | C |
    +---+  |    +---+
           |    +---+
           +--> | D |
                +---+

  A: Pridani noveho DB schematu / typu
  B: Implementace v service vrstve
  C: Implementace v API controlleru
  D: Implementace v UI komponente
```

**DAG reprezentace:**
```yaml
nodes:
  A: { depends_on: [] }
  B: { depends_on: ["A"] }
  C: { depends_on: ["A"] }
  D: { depends_on: ["A"] }
execution_order:
  - ["A"]
  - ["B", "C", "D"]  # vsechny 3 paralelne
```

**Moznost paralelismu:** B, C, D mohou bezet paralelne (pokud nesdili soubory).

#### Diamond (A -> [B, C] -> D)

Typicky pripad: spolecny zaklad, 2 nezavisle zmeny, pak integrace.

```
           +---+
    +----> | B | ----+
    |      +---+     |
    |                v
  +---+            +---+
  | A |            | D |
  +---+            +---+
    |                ^
    |      +---+     |
    +----> | C | ----+
           +---+

  A: Definice noveho interface/kontraktu
  B: Implementace server-side
  C: Implementace client-side
  D: Integracni test spojujici oboje
```

**DAG reprezentace:**
```yaml
nodes:
  A: { depends_on: [] }
  B: { depends_on: ["A"] }
  C: { depends_on: ["A"] }
  D: { depends_on: ["B", "C"] }
execution_order:
  - ["A"]
  - ["B", "C"]  # paralelne
  - ["D"]        # az kdyz oba hotove
```

**Moznost paralelismu:** B a C paralelne; D ceka na oba.

#### Complex (vice urovni, vicenasobne zavislosti)

```
  +---+     +---+
  | A | --> | C | --+
  +---+     +---+   |     +---+
                     +---> | E |
  +---+     +---+   |     +---+
  | B | --> | D | --+
  +---+     +---+

  A a B: nezavisle zakladni zmeny
  C zavisi na A, D zavisi na B
  E zavisi na C i D
```

**DAG reprezentace:**
```yaml
nodes:
  A: { depends_on: [] }
  B: { depends_on: [] }
  C: { depends_on: ["A"] }
  D: { depends_on: ["B"] }
  E: { depends_on: ["C", "D"] }
execution_order:
  - ["A", "B"]     # paralelne
  - ["C", "D"]     # paralelne (C ceka na A, D ceka na B)
  - ["E"]           # ceka na oba
```

### Detekce a prevence cyklu

Cyklicke zavislosti (A -> B -> C -> A) zpusobi deadlock — zadny subtask nemuze zacit. Engine MUSI detekovat cykly pred spustenim exekuce.

**Detekce cyklu (instrukce pro command engine):**

Command engine provede nasledujici kontrolu PRED spustenim exekuce:

1. Projdi vsechny subtasky. Najdi ty, ktere nemaji zadne zavislosti (depends_on je prazdny) — to jsou "root" subtasky. Pokud zadny root subtask neexistuje, vsechny maji zavislosti = existuje cyklus -> BLOCK.
2. Oznac root subtasky jako "zpracovane".
3. Opakuj: najdi subtasky, jejichz VSECHNY zavislosti jsou uz "zpracovane". Oznac je taky jako "zpracovane".
4. Pokud po uplnem pruchodu zbydou nezpracovane subtasky, tvori cyklickou zavislost (napr. A->B->C->A). BLOCK s chybovou zpravou: "Cyklicka zavislost nalezena u subtasku: {seznam nezpracovanych}. Opravte zavislosti v task tree."

**Prevence:** Architect agent dostane v kontextu explicitni instrukci: "Zavislosti MUSI tvorit DAG (acyklicky graf). Cykly jsou zakazane. Pokud subtask A zavisi na B, B NESMI primo ani neprimo zaviset na A."

Navic: decomposition engine provede validaci PRED spustenim exekuce. Pokud cyklus nalezne -> BLOCK s detailni chybovou zpravou pro cloveka.

### Vizualizace dependency grafu

Pro budouci integraci s dashboardem (Faze 3, viz `docs/plans/2026-02-25-future-roadmap.md`):

**Textovy format (pro terminal):**

```
Task Tree — PROJ-42 (3/5 completed)

  [x] subtask-1: Rozdeleni UserService    [completed]
   |
   +--[x] subtask-2: Validacni logika     [completed]
   |
   +--[>] subtask-3: API error handler    [in_progress]
   |
   +--[ ] subtask-4: Integracni test      [pending] (ceka na subtask-2, subtask-3)
   |
  [ ] subtask-5: Cleanup deprecated code  [pending] (ceka na subtask-4)
```

**Strojove citelny format (pro dashboard):**

```json
{
  "issue_id": "PROJ-42",
  "total": 5,
  "completed": 2,
  "in_progress": 1,
  "pending": 2,
  "failed": 0,
  "nodes": [
    {"id": "subtask-1", "status": "completed", "depends_on": []},
    {"id": "subtask-2", "status": "completed", "depends_on": ["subtask-1"]},
    {"id": "subtask-3", "status": "in_progress", "depends_on": ["subtask-1"]},
    {"id": "subtask-4", "status": "pending", "depends_on": ["subtask-2", "subtask-3"]},
    {"id": "subtask-5", "status": "pending", "depends_on": ["subtask-4"]}
  ]
}
```

Tento format umoznuje dashboardu vykreslit dependency graf jako interaktivni vizualizaci (SVG, Mermaid, nebo D3.js).

---

## 4. `--decompose` Flag — UX Design

### Syntax pro vsechny ovlivnene commandy

```
/CLAUDE-agents:fix-ticket PROJ-42 --decompose
/CLAUDE-agents:fix-ticket PROJ-42 --no-decompose
/CLAUDE-agents:fix-ticket PROJ-42                  # auto-detect (default)

/CLAUDE-agents:implement-feature PROJ-100 --decompose
/CLAUDE-agents:implement-feature PROJ-100 --no-decompose
/CLAUDE-agents:implement-feature PROJ-100           # auto-detect (default)

/CLAUDE-agents:fix-bugs 5 --decompose
/CLAUDE-agents:fix-bugs 5 --no-decompose
/CLAUDE-agents:fix-bugs 5                           # auto-detect per ticket

/CLAUDE-agents:fix-ticket PROJ-42 --decompose --dry-run   # kombinace s dry-run
```

**Tri mody:**
- `--decompose` — vynuti dekompozici i pro jednoduche tickety
- `--no-decompose` — zakazat dekompozici i pro slozite tickety (puvodni single-pass chovani)
- (bez flagu) — auto-detect na zaklade analysis vystupu (viz sekce 2)

**Parsovani flagu z $ARGUMENTS:**

Nove flagy se parsuji stejnym mechanismem jako existujici `--dry-run` v `commands/fix-bugs.md` — textovym matchem v `$ARGUMENTS` stringu:
- Pokud `$ARGUMENTS` obsahuje `--decompose` (a NE `--no-decompose`): `decompose_mode = FORCE`
- Pokud `$ARGUMENTS` obsahuje `--no-decompose`: `decompose_mode = DISABLED`
- Pokud ani jedno: `decompose_mode = AUTO`
- `--dry-run` a `--decompose` lze kombinovat: `/fix-ticket PROJ-42 --decompose --dry-run`

Poradi flagu neni dulezite. Flagy se odstrani z `$ARGUMENTS` pred predanim issue ID parseru.

### Co se deje pri `/fix-ticket PROJ-42 --decompose`

Detailni flow:

```
1. Nacti Automation Config (beze zmeny)
2. Nastav issue tracker state (beze zmeny)
3. Vytvor branch (beze zmeny)
4. Triage — triage-analyst (beze zmeny)
5. Code-analyst — impact report (beze zmeny)

--- NOVA LOGIKA OD TOHOTO BODU ---

6. DECOMPOSITION DECISION
   - --decompose flag -> vzdy DECOMPOSE
   - Spusti Architect agenta (nebo code-analyst v rozsirenem modu pro bugy)
     s kontextem: "Rozloz tento bug na subtasky. Max {max_subtasks} subtasku."
   - Architect vrati task tree (YAML)

7. VALIDACE TASK TREE
   - Kontrola cyklu (topologicky sort)
   - Kontrola max_subtasks limitu
   - Kontrola: kazdy subtask ma title, scope, files, estimated_lines
   - Pokud validace selze -> BLOCK

8. ZOBRAZ PLAN UZIVATELI
   "Dekompozice PROJ-42 na 3 subtasky:
    1. [~25 lines] Oprava validace v UserService
    2. [~35 lines] Error handler v API controlleru (zavisi na 1)
    3. [~40 lines] Integracni test (zavisi na 1, 2)
    Celkem: ~100 lines, sekvencni mod
    Pokracovat? [A/n]"

9. PRO KAZDY SUBTASK (sekvencne nebo paralelne):
   a. Fixer — s kontextem subtasku (scope, files, acceptance criteria)
   b. Build verification
   c. Reviewer — s kontextem subtasku
   d. Test-engineer — s kontextem subtasku
   e. Commit subtasku
   f. Update task tree stavu

10. INTEGRACNI KROK (po vsech subtascich):
    - Spusti plny test suite
    - Pokud testy selhavaji -> debug a oprava (max 3 pokusy)
    - Pokud nelze opravit -> BLOCK

11. Zobraz vysledek — uzivatel rozhodne o publish
```

### Co se deje pri `/implement-feature PROJ-100 --decompose`

```
1. Nacti Automation Config + Feature Workflow config
2. Nastav issue tracker state
3. Vytvor branch
4. Spec-analyst — extrakce requirements (NOVY agent z Faze 1)
5. Architect — design + task tree (NOVY agent z Faze 1)

--- SPOLECNA LOGIKA S fix-ticket OD TOHOTO BODU ---

6. DECOMPOSITION (automaticke — feature pipeline vzdy dekomponuje)
   - Architect uz vygeneroval task tree v kroku 5
   - Pokud --no-decompose: single-pass implementace (jen pro male features)

7-11. Stejne jako fix-ticket (validace, zobrazeni planu, exekuce, integrace)
```

### Opt-in vs. opt-out diskuse

**Opt-in (soucasny navrh):**
- Default: auto-detect (engine rozhodne na zaklade analyzy)
- `--decompose` vynuti dekompozici
- `--no-decompose` vynuti single-pass
- **Vyhoda:** Existujici workflow se NEMENI. Zadny breaking change.
- **Nevyhoda:** Uzivatele, kteri nevedi o flagu, ho nepouziji a slozite issues se budou blokovat jako dosud.

**Opt-out (alternativa):**
- Default: vzdy dekomponovat (pokud analyza rika DECOMPOSE)
- `--no-decompose` vynuti single-pass
- **Vyhoda:** Uzivatele automaticky profituji z dekompozice.
- **Nevyhoda:** Zmena chovani existujicich commandu. Potencialne prekvapeni.

**Rozhodnuti:** Opt-in s auto-detect defaultem. Duvody:
1. Auto-detect je konzervativni (dekompozice jen pri jasnych signalech)
2. Nedochazi ke zmene chovani pro existujici uzivatele
3. Feature pipeline (Faze 1) bude mit dekompozici jako vychozi chovani — tam se ocekava
4. Bug pipeline zachova single-pass jako default pro jednoduche bugy

### Interaktivni mod: schvaleni task tree pred exekuci

**Navrh:** Vzdy zobrazit plan a cekat na potvrzeni. Duvody:
- Dekompozice je nova a nepredvidatelna — uzivatel chce videt co se stane
- Architect agent muze vygenerovat nesmyslny plan — clovek to chyti
- Konzistentni s filozofii CLAUDE-agents: "orchestrovana linka s lidskym dohledem"

**Format zobrazeni:**

```
## Decomposition Plan — PROJ-42

| # | Subtask | Files | ~Lines | Zavisi na |
|---|---------|-------|--------|-----------|
| 1 | Oprava validace v UserService | UserService.ts, inputValidator.ts | ~25 | — |
| 2 | Error handler v API controlleru | UserController.ts, errorHandler.ts | ~35 | 1 |
| 3 | Integracni test | userValidation.test.ts | ~40 | 1, 2 |

**Strategie:** sekvencni (zavislosti mezi subtasky)
**Celkem:** 3 subtasky, ~100 radku, odhad ~3 fixer pruchody

Pokracovat? [A/n]
```

**Moznosti odpovedi:**
- `A` / `ano` / `y` / Enter — pokracovat s planem
- `n` / `ne` — zrusit (uzivatel muze upravit issue a zkusit znovu)
- `e` / `edit` — budouci moznost: interaktivne upravit plan (mimo scope v3.1)

### Priklady pouziti (8 scenaru)

**Scenar 1: Jednoduchy bug, auto-detect**
```
> /CLAUDE-agents:fix-ticket PROJ-42

Triage: OK (Severity: MEDIUM, Area: auth)
Code-analyst: 1 affected file, ~15 lines, LOW risk
-> Auto-detect: SINGLE_PASS (pod prahy dekompozice)
-> Pokracuje standardni pipeline...
```

**Scenar 2: Slozity bug, auto-detect**
```
> /CLAUDE-agents:fix-ticket PROJ-99

Triage: OK (Severity: HIGH, Area: data-sync)
Code-analyst: 5 affected files, ~120 lines, HIGH risk
-> Auto-detect: DECOMPOSE (HIGH risk + >60 lines + >=4 files)
-> Spoustim Architect pro dekompozici...

## Decomposition Plan — PROJ-99
| # | Subtask | ~Lines | Zavisi na |
|---|---------|--------|-----------|
| 1 | Fix race condition v SyncService | ~30 | — |
| 2 | Pridani lock mechanismu do DataStore | ~40 | 1 |
| 3 | Update retry logiky v SyncWorker | ~25 | 1 |
| 4 | Integracni test | ~35 | 1, 2, 3 |
Pokracovat? [A/n]
```

**Scenar 3: Jednoduchy bug, vynucena dekompozice**
```
> /CLAUDE-agents:fix-ticket PROJ-42 --decompose

Triage: OK (Severity: LOW, Area: ui)
Code-analyst: 1 affected file, ~10 lines, LOW risk
-> --decompose flag: DECOMPOSE (vynuceno uzivatelem)
-> Spoustim Architect...

## Decomposition Plan — PROJ-42
| # | Subtask | ~Lines | Zavisi na |
|---|---------|--------|-----------|
| 1 | Oprava CSS z-index v modalu | ~10 | — |
**Poznamka:** Architect vygeneroval 1 subtask — dekompozice neni nutna.
Pokracovat jako single-pass? [A/n]
```

**Scenar 4: Feature implementace**
```
> /CLAUDE-agents:implement-feature PROJ-200 --decompose

Spec-analyst: Feature "Export do CSV" — 3 acceptance criteria
Architect: Dekompozice na 4 subtasky

## Decomposition Plan — PROJ-200
| # | Subtask | ~Lines | Zavisi na |
|---|---------|--------|-----------|
| 1 | CSV serializer utility | ~45 | — |
| 2 | Export endpoint v ReportController | ~30 | 1 |
| 3 | UI tlacitko + download handler | ~35 | 2 |
| 4 | E2E test exportu | ~25 | 1, 2, 3 |
**Strategie:** sekvencni (kazdy krok stavi na predchozim)
Pokracovat? [A/n]
```

**Scenar 5: Batch fix s dekompozici**
```
> /CLAUDE-agents:fix-bugs 3 --decompose

Zpracovavam 3 bugy...
- PROJ-42: SINGLE_PASS (auto-detect: LOW risk, 1 soubor)
- PROJ-99: DECOMPOSE (auto-detect: HIGH risk, 5 souboru)
  -> 4 subtasky, sekvencni mod
- PROJ-101: DECOMPOSE (auto-detect: MEDIUM risk, 4 soubory)
  -> 2 subtasky, paralelni mod (worktrees)

Pokracovat? [A/n]
```

**Scenar 6: Dry-run s dekompozici**
```
> /CLAUDE-agents:fix-ticket PROJ-99 --decompose --dry-run

Triage: OK (Severity: HIGH)
Code-analyst: 5 files, HIGH risk
Architect: 4 subtasky

## Dry-Run Decomposition Report — PROJ-99
| # | Subtask | Files | ~Lines | Zavisi na |
|---|---------|-------|--------|-----------|
| 1 | Fix race condition | SyncService.ts | ~30 | — |
| 2 | Lock mechanismus | DataStore.ts | ~40 | 1 |
| 3 | Retry logika | SyncWorker.ts | ~25 | 1 |
| 4 | Integracni test | sync.test.ts | ~35 | 1, 2, 3 |

**Strategie:** sekvencni
**Celkovy odhad:** ~130 lines, ~4 fixer pruchody
**Odhadovane tokeny:** ~350k (~$1.50-$4.00)

Zadne zmeny provedeny. Pro spusteni: /CLAUDE-agents:fix-ticket PROJ-99 --decompose
```

**Scenar 7: Dekompozice s paralelnim modem**
```
> /CLAUDE-agents:fix-ticket PROJ-150 --decompose

Architect: 3 nezavisle subtasky (ruzne moduly, zadne sdilene soubory)
Worktrees config nalezena.

## Decomposition Plan — PROJ-150
| # | Subtask | ~Lines | Zavisi na | Worktree |
|---|---------|--------|-----------|----------|
| 1 | Fix auth modulu | ~30 | — | worktree-1 |
| 2 | Fix payment modulu | ~25 | — | worktree-2 |
| 3 | Fix notification modulu | ~20 | — | worktree-3 |
**Strategie:** PARALELNI (3 worktrees, zadne zavislosti)
Pokracovat? [A/n]
```

**Scenar 8: Resume po selhani subtasku**
```
> /CLAUDE-agents:resume-ticket PROJ-99

Checkpoint detekce:
- Nalezen task tree: 4 subtasky
- subtask-1: completed
- subtask-2: completed
- subtask-3: FAILED (fixer block po 5 iteracich)
- subtask-4: pending

Checkpoint: DECOMPOSE_PARTIAL (2/4 completed, 1 failed)
Pokracuji od subtask-3...
```

---

## 5. Execution Model

### Sekvencni mod

**Flow:**

```
subtask-1 --[commit]--> subtask-2 --[commit]--> ... --[commit]--> squash/merge --> PR
    |                       |                           |
    v                       v                           v
  [fixer]               [fixer]                     [fixer]
  [build]               [build]                     [build]
  [reviewer]            [reviewer]                  [reviewer]
  [test-eng]            [test-eng]                  [test-eng]
```

**Detailni ASCII diagram:**

```
+------------------------------------------------------------------+
| SEKVENCNI MOD                                                     |
+------------------------------------------------------------------+
|                                                                    |
|  +-----------+    +-----------+    +-----------+    +-----------+ |
|  | subtask-1 |    | subtask-2 |    | subtask-3 |    | INTEGRACE | |
|  +-----------+    +-----------+    +-----------+    +-----------+ |
|  | 1. fixer  |    | 1. fixer  |    | 1. fixer  |    | 1. full   | |
|  | 2. build  | -> | 2. build  | -> | 2. build  | -> |    test   | |
|  | 3. review |    | 3. review |    | 3. review |    |    suite  | |
|  | 4. test   |    | 4. test   |    | 4. test   |    | 2. squash | |
|  | 5. COMMIT |    | 5. COMMIT |    | 5. COMMIT |    | 3. PR     | |
|  +-----------+    +-----------+    +-----------+    +-----------+ |
|       |                |                |                |        |
|    commit-1         commit-2         commit-3      squash commit  |
|       |                |                |                |        |
|  "subtask-1:       "subtask-2:      "subtask-3:    "PROJ-42:     |
|   fix validace"     error handler"   integ. test"   fix xyz"     |
|                                                                    |
+------------------------------------------------------------------+
```

**Commit strategie:**

Navrhovane **dve varianty**, konfigurovatelne:

1. **Squash (default):** Kazdy subtask vytvori samostatny commit BEHEM exekuce. Squash se provede AZ po uspesne integraci (vsechny subtasky completed + integracni test OK). PR obsahuje jeden commit.
   - **Vyhoda:** Cisty git log, jeden commit = jeden ticket
   - **Nevyhoda:** Ztrata granularity v git historii
   - **Dulezite:** Squash NESMI probehnout prubezne — per-subtask commity musi zustat dostupne po celou dobu exekuce, protoze per-subtask rollback pouziva `git reset --hard {restore_point_N}`. Squash az jako posledni krok pred PR.

2. **Individual commits:** Kazdy subtask zustane jako samostatny commit. PR obsahuje N commitu.
   - **Vyhoda:** Granularni historie, snazsi bisect, kompatibilni s per-subtask rollbackem
   - **Nevyhoda:** Potencialne "noisy" git log

**Navrhovane reseni:** Default = squash. Duvodem je konzistence se soucasnym chovanim (fix-ticket dnes vytvari jeden commit). Volba bude konfigurovatelna pres Automation Config (nova volitelna sekce Decomposition). Squash se provadi az po uspesne integraci, ne prubezne — tim se zachova moznost per-subtask rollbacku behem exekuce.

**Jak se predava kontext mezi subtasky:**

Kriticky problem: subtask-2 musi vedet, co subtask-1 zmenil. Fixer agent cte soubory z disku, takze zmeny z commit-1 jsou automaticky viditelne. Ale kontext (proc se to zmenilo, jaky je celkovy plan) se musi predat explicitne.

**Mechanismus predavani kontextu:**

```
Pro kazdy subtask N engine pripravi kontext:
{
  "issue": { ... },                    # puvodni issue
  "decomposition_plan": { ... },       # cely task tree
  "current_subtask": subtask_N,        # aktualni subtask s detaily
  "completed_subtasks": [              # co uz bylo hotove
    {
      "id": "subtask-1",
      "summary": "Opravena validace — pridana kontrola prazdneho emailu",
      "files_changed": ["UserService.ts", "inputValidator.ts"],
      "diff_summary": "+15 -3 radky"
    }
  ],
  "remaining_subtasks": [subtask_3, ...],  # co jeste zbyva
  "accumulated_context": "..."             # volny text s poznamkami z predchozich kroku
}
```

Fixer agent pro subtask N dostane tento kontext jako soucast Task instrukce — vi, co se zmenilo, proc, a co bude nasledovat.

### Paralelni mod (worktrees)

**Flow:**

```
                    +-- worktree-1: subtask-1 [fix->review->test->commit] --+
                    |                                                        |
BASE BRANCH --------+-- worktree-2: subtask-2 [fix->review->test->commit] --+-- MERGE --> PR
                    |                                                        |
                    +-- worktree-3: subtask-3 [fix->review->test->commit] --+
```

**Detailni ASCII diagram:**

```
+------------------------------------------------------------------+
| PARALELNI MOD (Worktrees)                                         |
+------------------------------------------------------------------+
|                                                                    |
|  BASE BRANCH (main/development)                                    |
|       |                                                            |
|       +-- git worktree add .worktrees/PROJ-42-sub1                |
|       |     |                                                      |
|       |     +-- subtask-1: fixer -> build -> reviewer -> test     |
|       |     +-- commit na sub-branch                               |
|       |     +-- HOTOVO                                             |
|       |                                                            |
|       +-- git worktree add .worktrees/PROJ-42-sub2   (paralelne) |
|       |     |                                                      |
|       |     +-- subtask-2: fixer -> build -> reviewer -> test     |
|       |     +-- commit na sub-branch                               |
|       |     +-- HOTOVO                                             |
|       |                                                            |
|       +-- git worktree add .worktrees/PROJ-42-sub3   (paralelne) |
|             |                                                      |
|             +-- subtask-3: fixer -> build -> reviewer -> test     |
|             +-- commit na sub-branch                               |
|             +-- HOTOVO                                             |
|                                                                    |
|  MERGE FAZE:                                                       |
|       |                                                            |
|       +-- Vytvor feature branch: PROJ-42-fix                      |
|       +-- git merge sub1-branch                                    |
|       +-- git merge sub2-branch                                    |
|       +-- git merge sub3-branch                                    |
|       |     |                                                      |
|       |     +-- KONFLIKT? -> conflict resolution (viz nize)       |
|       |                                                            |
|       +-- Full test suite                                          |
|       +-- Cleanup worktrees                                        |
|       +-- PR                                                       |
|                                                                    |
+------------------------------------------------------------------+
```

**Worktree creation a cleanup:**

```bash
# Vytvoreni — pro kazdy subtask
git worktree add {base_path}/{issue_id}-sub{N} -b {issue_id}-sub{N} {base_branch}
# base_path z Automation Config -> Worktrees -> Base path (default: .worktrees)

# Kazdy worktree = izolovany pracovni adresar
# Fixer/reviewer/test bezi v kontextu worktree

# Cleanup — po merge nebo pri selhani
git worktree remove {base_path}/{issue_id}-sub{N}
git branch -d {issue_id}-sub{N}  # smazani pomocne branch
```

**Batch limity:** Max paralelne worktrees = `batch_size` z Automation Config -> Worktrees. Pokud subtasku > batch_size, engine zpracovava po davkach:

```
5 subtasku, batch_size = 3:
  Batch 1: subtask-1, subtask-2, subtask-3 (paralelne)
  Batch 2: subtask-4, subtask-5 (paralelne)
  Merge vsech 5
```

**Merge strategie:**

Navrhovana strategie: **rebase + squash** na feature branch.

```
1. Vytvor feature branch z base_branch
2. Pro kazdy completed subtask (v topologickem poradi):
   a. git cherry-pick {subtask_commit} (ne merge — cisteji)
   b. Pokud conflict -> conflict resolution (viz nize)
3. Squash vsechny cherry-picks do jednoho commitu (nebo zachovej — dle config)
4. PR z feature branch do base_branch
```

**Alternativa: merge commits** — kazdy subtask se mergne jako merge commit. Vice trackovatelne, ale "noisy" historie.

**Rozhodnuti:** Cherry-pick + optional squash. Duvody: konzistence s single-pass chovanim, cisty git log.

**Detekce a reseni konfliktu:**

```
Pri cherry-pick subtask-N:
  if conflict:
    1. Analyzuj conflict — ktere soubory, ktere radky
    2. Pokud conflict je trivialni (ruzne sekce stejneho souboru):
       -> Automaticky resolvni (git mergetool s jednoduchym algoritmem)
    3. Pokud conflict je netrivialni (stejne radky):
       -> Spusti fixer agenta s kontextem:
          "Resolvni merge conflict v {file}. Subtask-A zmenil {radky}
           kvuli {duvod}. Subtask-B zmenil {radky} kvuli {duvod}.
           Obe zmeny musi zachovat oba zamery."
       -> Max 2 pokusy na conflict resolution
    4. Pokud nelze resolvnit:
       -> BLOCK s detaily konfliktu
       -> Doporuceni: "Rucne resolvnete merge conflict v {file}"
```

### Error handling

**Co se stane pri selhani subtasku N:**

Dve strategie (konfigurovatelne):

**Fail-fast (default):**
```
subtask-1: OK
subtask-2: OK
subtask-3: FAIL (fixer block)
subtask-4: SKIPPED (nezacal — predchozi selhal)
subtask-5: SKIPPED

-> Rollback subtask-3
-> Subtask-1 a subtask-2 zustanou commitnute
-> Report: "3/5 subtasku zpracovano, subtask-3 selhal: {duvod}"
-> Issue se NEBLOKUJE (castecny progres zachovan)
-> Uzivatel muze pouzit /resume-ticket pro pokracovani od subtask-3
```

**Continue-on-failure:**
```
subtask-1: OK
subtask-2: OK
subtask-3: FAIL (fixer block)
subtask-4: OK (pokracuje — nema zavislost na subtask-3)
subtask-5: FAIL (zavisi na subtask-3, ktery selhal -> automaticky skip)

-> Rollback subtask-3
-> Report: "3/5 subtasku OK, 1 FAIL, 1 SKIPPED"
-> Uzivatel muze pouzit /resume-ticket
```

**Rozhodnuti:** Default fail-fast, protoze:
1. Konzervativnejsi — mensi riziko nekonzistentnich zmen
2. Subtasky casto maji implicitni zavislosti (i kdyz nejsou deklarovane)
3. Continue-on-failure je uzitecny jen pro plne nezavisle subtasky (vzacne)
4. Konfigurovatelne pres Automation Config pro ty, co chteji continue

**Rollback strategie per subtask vs. full rollback:**

| Scenar | Rollback scope |
|--------|---------------|
| subtask-1 selze (jediny hotovy) | Full rollback — zadny progres |
| subtask-3 selze (1+2 hotove) | Rollback jen subtask-3 — zachovat 1+2 |
| Merge konflikty po vsech subtascich | Full rollback — vsechny subtasky |
| Integracni test selze | Rollback integracniho kroku, zachovat subtasky |

**Implementace per-subtask rollbacku:**

```
Pro kazdy subtask engine uklada:
  - commit hash PRED subtaskem (restore point)
  - commit hash PO subtasku (subtask commit)

Pri rollbacku subtask-N:
  git reset --hard {restore_point_N}
  # Commit-1 az commit-(N-1) zustanou zachovane
```

**Resume capability:**

Integrace s existujicim `/resume-ticket` commandem (viz `commands/resume-ticket.md`). Novy checkpoint:

| Checkpoint | Signal | Preskoci |
|-----------|--------|---------|
| `DECOMPOSE_PARTIAL` | Task tree existuje + nektery subtask completed | Triage + analysis + hotove subtasky |

Detekce: resume-ticket precte task tree soubor (viz sekce 6 — datovy model) a urci, ktery subtask je posledni completed. Pokracuje od nasledujiciho.

### Orchestrace: jak command engine ridi multi-subtask exekuci

Command engine (uvnitr `/fix-ticket` a `/implement-feature`) ridi exekuci takto:

**Sekvencni mod — instrukce pro command engine:**

1. Urcit poradi subtasku: nejdrive ty bez zavislosti, pak ty jejichz zavislosti jsou vsechny completed.
2. Pro kazdy subtask v tomto poradi:
   a. Overit, ze vsechny zavislosti maji stav "completed". Pokud ne, preskocit (ceka).
   b. Sestavit kontext: cely decomposition plan + summary predchozich subtasku + diff summary.
   c. Spustit subtask pipeline: fixer -> build -> reviewer -> test -> commit.
   d. Pokud subtask SELZE:
      - Provest rollback tohoto subtasku (viz per-subtask rollback).
      - Pokud fail_strategy = "fail-fast": zastavit, zapsat report "X/N subtasku zpracovano", skoncit.
      - Pokud fail_strategy = "continue": oznacit zavisle subtasky jako "skipped", pokracovat dalsim nezavislym subtaskem.
   e. Pokud subtask USPEJE: oznacit jako "completed", ulozit task tree stav na disk (pro resume).
3. Po vsech subtascich: integracni krok (viz nize).

**Paralelni mod — instrukce pro command engine:**

1. Rozdelit subtasky do urovni podle topologickeho poradi (uroven 0 = bez zavislosti, uroven 1 = zavisi jen na urovni 0, atd.).
2. Pro kazdou uroven:
   a. Vytvorit worktrees pro vsechny subtasky na teto urovni.
   b. Spustit subtask pipeline pro vsechny paralelne (vice Task volani v jednom message bloku).
   c. Po dokonceni: zpracovat vysledky — oznacit completed/failed, rollback selhavsich.
   d. Cleanup worktrees, ulozit task tree stav.
3. Po vsech urovnich: integracni krok (merge + full test suite).

**Poznamka k Claude Code Task tool:**
Soucasne agenty se spousteji pres `Task` tool s parametrem `model` a `prompt`. Pro paralelni exekuci: command vytvori vice Task volani v jednom message bloku — Claude Code je zpracuje paralelne. Toto je existujici mechanismus (pouzivany v `commands/fix-bugs.md` pro paralelni triage).

**Upozorneni k paralelnimu modu:** Paralelni exekuce subtasku jednoho ticketu pres worktrees je v CLAUDE-agents NOVA a NEPROKÁZANA capability. Existujici `fix-bugs.md` pouziva worktrees pro paralelni zpracovani RUZNYCH bugu (kazdy bug = jeden worktree), ale ne pro paralelni subtasky JEDNOHO ticketu. Pred implementaci paralelniho modu je nutne provest proof-of-concept: overit, ze Claude Code Task tool zvlada vice paralelne bezicich fixer+reviewer+test pipeline v ruznych worktrees bez interference. Paralelni mod je proto zaraden do Faze 2b (po zakladnim sekvencnim modu).

---

## 6. Datovy model

### Task tree format

**Volba: YAML.** Duvody:
- Konzistence s Architect agent vystupem (viz sekce 2)
- Citelne pro cloveka (debug, manual inspekce)
- Jednoduche parsovani (Claude Code zvlada YAML nativne)
- Alternativy: JSON (mene citelne), Markdown (tezko parsovatelne strojove)

### Priklad task tree s 5 subtasky

```yaml
# .claude/decomposition/PROJ-42.yaml
version: "1.0"
issue_id: "PROJ-42"
issue_title: "Race condition v data sync procesu"
created_at: "2026-02-27T10:30:00Z"
updated_at: "2026-02-27T11:45:00Z"
strategy: sequential
fail_strategy: fail-fast
commit_strategy: squash

status: in_progress  # pending | in_progress | completed | failed | partial

subtasks:
  - id: "sub-1"
    title: "Pridani mutex do SyncService"
    scope: "Zabraneni concurrent pristupu k sync operacim"
    files:
      - src/services/SyncService.ts
      - src/utils/mutex.ts
    estimated_lines: 20
    depends_on: []
    acceptance_criteria:
      - "SyncService.sync() pouziva mutex"
      - "Concurrent volani cekaji na uvolneni locku"
    status: completed
    started_at: "2026-02-27T10:35:00Z"
    completed_at: "2026-02-27T10:42:00Z"
    commit_hash: "a1b2c3d"
    restore_point: "f0e1d2c"
    fixer_iterations: 1
    reviewer_verdict: "APPROVE"

  - id: "sub-2"
    title: "Oprava retry logiky v DataStore"
    scope: "Retry po lock timeout misto okamziteho selhani"
    files:
      - src/stores/DataStore.ts
    estimated_lines: 30
    depends_on: ["sub-1"]
    acceptance_criteria:
      - "DataStore retry-uje 3x pri lock timeout"
      - "Exponential backoff mezi pokusy"
    status: completed
    started_at: "2026-02-27T10:43:00Z"
    completed_at: "2026-02-27T10:55:00Z"
    commit_hash: "d4e5f6a"
    restore_point: "a1b2c3d"
    fixer_iterations: 2
    reviewer_verdict: "APPROVE"

  - id: "sub-3"
    title: "Update SyncWorker pro graceful shutdown"
    scope: "Pridani shutdown handleru ktery ceka na dokonceni sync"
    files:
      - src/workers/SyncWorker.ts
      - src/workers/WorkerManager.ts
    estimated_lines: 35
    depends_on: ["sub-1"]
    acceptance_criteria:
      - "SyncWorker reaguje na SIGTERM"
      - "Shutdown pocka na dokonceni aktivni sync operace"
    status: in_progress
    started_at: "2026-02-27T10:56:00Z"
    completed_at: null
    commit_hash: null
    restore_point: "d4e5f6a"
    fixer_iterations: 3
    reviewer_verdict: "REQUEST_CHANGES"

  - id: "sub-4"
    title: "Integracni test race condition scenaru"
    scope: "Test simulujici concurrent sync volani"
    files:
      - tests/integration/sync-race.test.ts
    estimated_lines: 45
    depends_on: ["sub-1", "sub-2", "sub-3"]
    acceptance_criteria:
      - "Test spusti 10 concurrent sync operaci"
      - "Zadny data corruption po vsech operacich"
    status: pending
    started_at: null
    completed_at: null
    commit_hash: null
    restore_point: null
    fixer_iterations: 0
    reviewer_verdict: null

  - id: "sub-5"
    title: "Cleanup deprecated sync API"
    scope: "Odstraneni starych sync metod nahrazenych novymi"
    files:
      - src/services/SyncService.ts
      - src/api/syncRoutes.ts
    estimated_lines: 15
    depends_on: ["sub-4"]
    acceptance_criteria:
      - "Deprecated metody odstraneny"
      - "API routes aktualizovany"
    status: pending
    started_at: null
    completed_at: null
    commit_hash: null
    restore_point: null
    fixer_iterations: 0
    reviewer_verdict: null

execution_log:
  - timestamp: "2026-02-27T10:35:00Z"
    event: "subtask_started"
    subtask: "sub-1"
  - timestamp: "2026-02-27T10:42:00Z"
    event: "subtask_completed"
    subtask: "sub-1"
    details: "1 fixer iteration, reviewer APPROVE"
  - timestamp: "2026-02-27T10:43:00Z"
    event: "subtask_started"
    subtask: "sub-2"
  - timestamp: "2026-02-27T10:55:00Z"
    event: "subtask_completed"
    subtask: "sub-2"
    details: "2 fixer iterations, reviewer APPROVE"
  - timestamp: "2026-02-27T10:56:00Z"
    event: "subtask_started"
    subtask: "sub-3"
```

### State tracking per subtask

| Stav | Vyznam | Prechody |
|------|--------|----------|
| `pending` | Subtask jeste nezacal | -> `in_progress` |
| `in_progress` | Fixer/reviewer/test probiha | -> `completed`, `failed`, `blocked` |
| `completed` | Subtask uspesne dokoncen (commit existuje) | Konecny stav |
| `failed` | Subtask selhal (fixer block, test fail, atd.) | -> `in_progress` (pri resume) |
| `blocked` | Subtask nelze spustit (zavislost selhala) | -> `pending` (pri resume po oprave zavislosti) |
| `skipped` | Preskochen (continue-on-failure, zavislost failed) | -> `pending` (pri resume) |

**Stavovy diagram:**

```
                    +--- resume ---+
                    |              |
                    v              |
  +--------+   +-------------+   +---------+
  | pending |-->| in_progress |-->| failed  |
  +--------+   +-------------+   +---------+
       |              |
       |              v
       |        +-----------+
       |        | completed |
       |        +-----------+
       |
       +------> +---------+
       |        | blocked |  (zavislost selhala)
       |        +---------+
       |              |
       |              +--- resume ---> pending
       |
       +------> +---------+
                | skipped |  (continue-on-failure)
                +---------+
                      |
                      +--- resume ---> pending
```

### Ulozeni (storage location)

**Navrh:** `.claude/decomposition/{issue_id}.yaml`

Duvody:
- `.claude/` je standardni adresar pro Claude Code metadata
- Adresar `decomposition/` separuje task trees od jine metadata
- Pojmenovani dle issue ID = snadne nalezeni
- YAML soubor = commitovatelny (ale nedoporucujeme commitovat — docasny artefakt)

**Zivotni cyklus souboru:**
1. Vytvoren pri spusteni dekompozice
2. Aktualizovan po kazdem subtasku (stav, timestamp, commit hash)
3. Smazan po uspesnem publishu (nebo ponechan pro audit — konfigurovatelne)
4. Precten pri `/resume-ticket` pro detekci checkpointu

**Gitignore:** Doporucujeme pridat `.claude/decomposition/` do `.gitignore` — task trees jsou docasne runtime artefakty, ne soucast codebase.

### Resumabilita

**Jak `/resume-ticket` detekuje dekompozicni stav:**

Rozsireni detekce v `commands/resume-ticket.md`:

```
# Existujici checkpointy (nemeni se):
if PR exists for branch -> PUBLISHED
else if branch has commits above base -> POST_FIX
else if branch exists + triage comment -> POST_ANALYSIS
else if triage comment exists -> POST_TRIAGE
else -> FRESH

# NOVY checkpoint pro dekompozici:
if .claude/decomposition/{issue_id}.yaml exists:
    task_tree = parse(yaml)
    completed = [s for s in task_tree.subtasks if s.status == "completed"]
    failed = [s for s in task_tree.subtasks if s.status == "failed"]

    if all completed:
        -> DECOMPOSE_COMPLETE (vsechny subtasky hotove, chybi integrace/publish)
    elif any completed and any failed:
        -> DECOMPOSE_PARTIAL (castecny progres)
        "Nalezeno {len(completed)}/{total} hotovych subtasku.
         Selhal: {failed[0].id} — {failed[0].title}
         Pokracuji od: {next_pending_subtask.id}"
    elif any completed:
        -> DECOMPOSE_IN_PROGRESS
        "Nalezeno {len(completed)}/{total} hotovych subtasku.
         Pokracuji od: {next_pending_subtask.id}"
```

**Integrace s `/resume-ticket`:**

Novy krok v resume-ticket flow:

```
# Po detekci checkpointu:
if checkpoint in [DECOMPOSE_PARTIAL, DECOMPOSE_IN_PROGRESS]:
    task_tree = load_task_tree(issue_id)

    # Overit stav base branch — pokud base branch odejel od posledniho subtasku,
    # proved rebase nebo merge pred pokracovanim. Toto je dulezite pri resume
    # po dnech/tydnech, kdy main/development mohly dostat nove commity.
    check_base_branch_divergence(task_tree, config)

    # Resetovat failed subtasky na pending (novy pokus)
    for subtask in task_tree.subtasks:
        if subtask.status == "failed":
            subtask.status = "pending"

    # Pokracovat od prvniho pending subtasku
    execute_decomposed(task_tree, config, resume=True)

elif checkpoint == DECOMPOSE_COMPLETE:
    # Vsechny subtasky hotove — spustit integracni test + publish
    run_integration_and_publish(task_tree, config)
```

---

## 7. Zavislost na Fazi 1

### Co PRESNE je potreba z Feature Pipeline (Faze 1)

| Komponenta z Faze 1 | Potreba pro Fazi 2 | Kriticky? |
|---------------------|---------------------|-----------|
| Architect agent | Generuje task tree (dekompozici) | ANO — jadro dekompozice |
| Architect output format | YAML task tree (viz sekce 2) | ANO — datova struktura |
| Spec analyst agent | Ne — dekompozice bug-fixu pouziva code-analyst | NE |
| `/implement-feature` command | Integrace dekompozice do feature pipeline | CASTECNE |
| Feature Workflow config | Konfigurace pro feature dekompozici | NE (optional) |

**Klicova zavislost: Architect agent.** Bez Architecta neni kdo by vygeneroval task tree. Code-analyst (viz `agents/code-analyst.md`) produkuje impact report, ale nerozklada na subtasky — to neni jeho role.

### Co muze fungovat nezavisle

**Dekompozice pro bug-fix (`--decompose`)** muze fungovat BEZ plne Feature Pipeline:
- Code-analyst vygeneruje impact report (uz dnes)
- Misto Architect agenta muze rozhodovaci engine pouzit **zjednodusenou heuristiku**:

**Heuristicka dekompozice (bez Architecta) — detailni instrukce:**

Command engine pouzije vystup code-analysta a aplikuje nasledujici pravidla:

1. **Vicero root cause candidates (2+):** Vytvor 1 subtask per root cause candidate. Kazdy subtask opravuje jednu pricinu. Zavislosti: linearni (subtask N+1 zavisi na N) — bezpecna volba, protoze root causes mohou sdilet soubory.

2. **Seskupeni dle modulu (4+ affected files):** Identifikuj moduly podle adresarove struktury — soubory ve stejnem adresari (nebo podstromu) patri do jednoho modulu. Priklad: `src/services/*.ts` = modul "services", `src/controllers/*.ts` = modul "controllers". Vytvor 1 subtask per modul. Pokud adresarova struktura neni jasna (vsechny soubory v jednom adresari), seskup podle logicke souvislosti — soubory sdilene v importech patri k sobe.

3. **Test coverage gaps:** Pokud code-analyst identifikuje chybejici testy, pridej 1 extra subtask na konec (zavisi na vsech predchozich) s title "Doplneni testu pro {oblast}".

4. **Generovani acceptance criteria:** Kazdy subtask musi mit alespon 1 acceptance criterium. Heuristika ho odvodi z code-analyst reportu: "Opravit {root cause popis} v {affected files}" + "Existujici testy prochazi". Pokud code-analyst specifikuje expected behavior, pouzij ho jako acceptance criterium.

5. **Defaultni zavislosti:** Pokud neni jasne, zda subtasky jsou nezavisle, pouzij linearni zavislosti (bezpecnejsi). Paralelni heuristicke subtasky jen pokud maji disjunktni mnoziny souboru.

Tato heuristika je horsi nez Architect (nerozumi designu, API kontraktum, architektonickym zavislostem), ale pokryje priblizne 60% pripadu (jednoduche bugy s vicero affected areas).

### Muze se Faze 2 castecne implementovat pred Fazi 1?

**ANO — a doporucujeme to.** Navrhovany phasing:

| Krok | Zavislost na Fazi 1 | Implementace |
|------|---------------------|-------------|
| Datovy model (YAML task tree) | NE | Pred Fazi 1 |
| Execution engine (sekvencni mod) | NE | Pred Fazi 1 |
| Heuristicka dekompozice (bez Architecta) | NE | Pred Fazi 1 |
| `/fix-ticket --decompose` s heuristikou | NE | Pred Fazi 1 |
| Integrace s Architect agentem | ANO | Po Fazi 1 |
| Paralelni mod (worktrees) | NE (ale vhodne testovat s Architectem) | Po Fazi 1 |
| `/implement-feature` integrace | ANO | Po Fazi 1 |
| Resume pro dekompozici | NE | Pred Fazi 1 |

**Zaver:** ~60% Faze 2 je implementovatelne nezavisle na Fazi 1. Architect agent je "nice-to-have" pro kvalitni dekompozici, ale heuristika pokryje zakladni use case.

### Sdilene vs. nezavisle komponenty

| Komponenta | Sdilena / Nezavisla |
|------------|---------------------|
| Task tree YAML format | SDILENA — Architect (Faze 1) a decomposition engine (Faze 2) musi pouzivat stejny format. **DULEZITE:** Feature Pipeline v3.0 design doc aktualne NEspecifikuje YAML task tree format — je treba ho synchronizovat. Doporuceni: definovat kanonicky format zde (sekce 6) a referencovat z Feature Pipeline dokumentu. |
| Execution engine | NEZAVISLA — Faze 2 specificky |
| Dependency graph | NEZAVISLA — Faze 2 specificky |
| Per-subtask rollback | NEZAVISLA — rozsireni existujiciho rollback-agenta |
| Resume checkpointy | SDILENA — rozsireni /resume-ticket (existujici command) |
| Worktree management | SDILENA — existujici Worktrees config z Automation Config |
| `--decompose` flag parsing | NEZAVISLA — v command logice |

---

## 8. Guardrails & Limits

### Max subtasks limit

**Default: 5.** Konfigurovatelne pres Automation Config:

```markdown
### Decomposition (optional)
| Klic | Hodnota |
|------|---------|
| Max subtasks | 5 |
| Strategy | sequential / parallel / auto |
| Fail strategy | fail-fast / continue |
| Commit strategy | squash / individual |
```

**Poznamka:** 5 je **default hodnota**, ne hard limit. Konfigurovatelne pres Automation Config v rozsahu 1-10 (viz Dodatek D). Uzivatel muze nastavit jiny limit dle potreby projektu.

**Proc je default 5:**
- Architect generuje typicky 2-5 subtasku pro realnou feature/bug
- >5 subtasku = pravdepodobne prilis granularni dekompozice
- 5 subtasku * ~60 radku = ~300 radku celkove — rozumny rozsah pro jeden PR
- Kazdy subtask prochazi fixer + reviewer + test = ~3-5 minut -> 5 subtasku = ~15-25 minut
- Pri batch zpracovani (/fix-bugs) s dekompozici: 5 bugu * 5 subtasku = 25 fixer pruchodu — jeste zvladnutelne

### Max celkovy diff across all subtasks

**Default: 500 radku.** Duvody:
- 5 subtasku * 100 radku (fixer limit) = 500 radku max
- PR s >500 radky je tezko revidovatelny clovekem
- Pokud Architect odhaduje >500 radku celkem -> BLOCK s doporucenim "Issue je prilis velky, rozdelete rucne na vice issues"

**Implementace:** Engine scita `estimated_lines` ze vsech subtasku. Pokud suma > 500 -> varovani pred spustenim. Pokud actual diff > 500 po dokonceni -> varovani v PR description.

### Max hloubka dependency grafu

**Default: 4 urovne.** Duvody:
- 4 urovne = dostatecne pro diamond pattern i complex DAG
- >4 urovne = dekompozice je prilis hluboce vnorena, ztrata prehledu
- Hlubsi graf = delsi sekvencni cesta = delsi celkovy cas

**Implementace:** Po topologickem sortu spocitat pocet urovni. Pokud > 4 -> Architect retry s hintem "Zmensete hloubku na max 4 urovne."

### Monitoring doby behu subtasku

Claude Code Task tool nema nativni timeout — command nemuze prerusit bezici Task. Proto jsou casove limity implementovany jako **soft warningy**, ne hard stopy.

**Mechanismus:** Command engine zaznamenava cas zahajeni kazdeho subtasku. Po dokonceni subtasku zapise dobu behu do execution logu. Pokud subtask trva neocekavane dlouho (orientacne >10 minut), engine zapise warning do logu: "Subtask {id} trval {cas} — zvazit zjednoduseni scope pri dalsim pokusu."

**Celkovy limit:** Jediny hard limit, ktery lze vynutit, je celkovy pocet fixer iteraci per subtask (existujici Retry Limits z Automation Config). Casove limity jsou informativni — slouzi pro reporting a uzivatelsky prehled, ne pro preruseni exekuce.

### Odhad nakladu pred exekuci (token usage prediction)

**Motivace:** Dekompozice nasobi spotrebu tokenu — kazdy subtask projde fixer (opus) + reviewer (opus) + test (sonnet). Uzivatel by mel vedet pribliznou cenu pred spustenim.

**Odhad per subtask (ilustrativni, ceny dle sazeb z February 2026 — mohou se zmenit):**

| Agent | Model | ~Input tokens | ~Output tokens | ~Cena |
|-------|-------|---------------|----------------|-------|
| Fixer | opus | 15 000 | 5 000 | ~$0.30 |
| Build (Bash) | — | 500 | 500 | ~$0.00 |
| Reviewer | opus | 20 000 | 3 000 | ~$0.35 |
| Test-engineer | sonnet | 10 000 | 5 000 | ~$0.05 |
| **Subtask celkem** | | **~45 500** | **~13 500** | **~$0.70** |

**Odhad celkove dekompozice:**

```
Celkem = N_subtasku * $0.70 + overhead (analyza, integrace, orchestrace)
       = N_subtasku * $0.70 + $0.50

Priklad:
  3 subtasky: ~$2.60
  5 subtasku: ~$4.00
  5 subtasku s retry: ~$6.00-$8.00
```

**Zobrazeni pred spustenim:**

```
## Odhad nakladu dekompozice — PROJ-42

| Polozka | Tokeny | ~Cena |
|---------|--------|-------|
| Analyza (triage + code-analyst) | ~50k | $0.50 |
| Subtask 1 (fixer + reviewer + test) | ~60k | $0.70 |
| Subtask 2 | ~60k | $0.70 |
| Subtask 3 | ~60k | $0.70 |
| Integrace + orchestrace | ~30k | $0.30 |
| **Celkem** | **~260k** | **~$2.90** |

Skutecne naklady mohou byt 2-3x vyssi pri retry iteracich.
Pokracovat? [A/n]
```

---

## 9. Implementacni plan

### Sekvence implementacnich kroku

| # | Krok | Zavislost | Vyzaduje Fazi 1? | Effort | Popis |
|---|------|-----------|------------------|--------|-------|
| 1 | Definice YAML task tree formatu | — | NE | S | Specifikace formatu + validacni schema |
| 2 | Heuristicky decomposer (bez Architecta) | 1 | NE | M | Jednoducha heuristika pro bug-fix dekompozici na zaklade code-analyst vystupu |
| 3 | Execution engine — sekvencni mod | 1 | NE | L | Jadro: iterace pres subtasky, kontext management, commit strategie |
| 4 | Per-subtask rollback rozsireni | 3 | NE | M | Rozsireni rollback-agenta o per-subtask rollback (zachovani predchozich subtasku). Nova capability — existujici rollback-agent dela jen full rollback, per-subtask rollback vyzaduje novou logiku pro selective reset s ochranou predchozich commitu. |
| 5 | Task tree persistence (.claude/decomposition/) | 1, 3 | NE | S | Ukladani a nacitani task tree YAML souboru |
| 6 | `--decompose` flag v `/fix-ticket` | 2, 3, 5 | NE | M | Integrace decomposition enginu do existujiciho fix-ticket commandu |
| 7 | Rozhodovaci algoritmus (auto-detect) | 2, 6 | NE | M | Automaticka detekce, zda dekomponovat na zaklade analyzy |
| 8 | Resume checkpointy pro dekompozici | 5 | NE | M | Rozsireni /resume-ticket o DECOMPOSE_PARTIAL checkpoint |
| 9 | Integrace s Architect agentem | 1, 3 | ANO | M | Napojeni na Architect output misto heuristiky |
| 10 | Dependency graph engine (DAG) | 1 | NE | M | Topologicky sort, detekce cyklu, execution levels |
| 11 | Paralelni mod (worktrees) | 3, 10 | NE | L | Worktree management, paralelni exekuce, merge/cherry-pick |
| 12 | Conflict resolution | 11 | NE | M | Detekce a reseni merge konfliktu pri paralelni exekuci |
| 13 | `--decompose` flag v `/fix-bugs` | 6, 7 | NE | S | Rozsireni batch commandu o dekompozici per ticket |
| 14 | `--decompose` v `/implement-feature` | 9 | ANO | M | Integrace do feature pipeline |
| 15 | Automation Config — Decomposition sekce | — | NE | S | Nova volitelna config sekce |
| 16 | Rozsireni skill routing | 6, 14 | CASTECNE | S | Nove intenty: "rozloz", "dekomponuj", "subtasky" |
| 17 | Rozsireni `/check-setup` | 15 | NE | S | Validace Decomposition config sekce |
| 18 | Odhad nakladu (token estimation) | 3 | NE | S | Zobrazeni odhadu tokenu/ceny pred spustenim |
| 19 | Dokumentace + CHANGELOG | vsechny | NE | M | README update, CHANGELOG, CLAUDE.md update |
| 20 | Smoke test | vsechny | NE | M | Test s realnym multi-file bugem/feature |

### Dependency diagram implementacnich kroku

```
  [1] YAML format
   |
   +-----+-----+-----+
   |     |     |     |
  [2]  [5]  [10]  [15]
   |     |     |     |
   +--+--+     |    [17]
      |        |
     [3] Engine (seq)
      |        |
   +--+--+     |
   |     |     |
  [4]  [6]    [10] DAG
   |     |     |
   |   [7]  [11] Parallel
   |     |     |
   |   [8]  [12] Conflicts
   |     |     |
   |   [13]    |
   |     |     |
   +--+--+-----+
      |
     [9] Architect integrace (FAZE 1)
      |
    [14] implement-feature
      |
    [16] Skill routing
      |
    [18] Token estimation
      |
    [19] Dokumentace
      |
    [20] Smoke test
```

### Faze implementace

**Faze 2a (nezavisla na Fazi 1):** Kroky 1-8, 10, 13, 15, 17, 18
- Heuristicka dekompozice pro bug-fix
- Sekvencni mod
- Resume
- Zakladni DAG engine

**Faze 2b (po Fazi 1):** Kroky 9, 11, 12, 14, 16
- Architect integrace
- Paralelni mod
- Feature pipeline integrace
- Skill routing

**Faze 2c (finalizace):** Kroky 19, 20
- Dokumentace, testing

### Odhadovany effort

| Effort | Pocet kroku | Popis |
|--------|-------------|-------|
| S (1-2 hodiny) | 7 | Format, persistence, config, skill, check-setup, token est., flag v fix-bugs |
| M (3-5 hodin) | 10 | Heuristika, per-subtask rollback, flag v fix-ticket, auto-detect, resume, DAG, conflicts, Architect, feature, docs |
| L (6-10 hodin) | 3 | Sekvencni engine, paralelni engine, smoke test |

**Celkovy odhad:** ~65-95 hodin prace (Faze 2a: ~40h, Faze 2b: ~25h, Faze 2c: ~10h)

---

## 10. Rizika & edge cases

### Riziko 1: Architect generuje nekvalitni dekompozici

**Popis:** Architect agent (opus model) muze vygenerovat subtasky, ktere jsou prilis granularni, prilis hrube, nebo s nesmyslnymi zavislostmi. Spatna dekompozice je horsi nez single-pass.

**Pravdepodobnost:** STREDNI — Architect je read-only analyticky agent, ale dekompozice je kreativni ukol s mnozstvim "spravnych" odpovedi.

**Mitigace:**
1. Interaktivni schvaleni — uzivatel vidi plan a muze odmitnout
2. Guardrails — max 5 subtasku, max 4 urovne, max 500 radku celkem
3. Fallback — pokud Architect nemuze dekomponovat, single-pass fallback
4. Heuristicky sanity check — kazdy subtask musi mit alespon 1 soubor a >0 odhadovanych radku

### Riziko 2: Merge konflikty v paralelnim modu

**Popis:** Dva paralelne subtasky mohou modifikovat stejny soubor v ruznych radcich (nebo i stejnych radcich). Cherry-pick/merge selze.

**Pravdepodobnost:** STREDNI — nastava kdyz Architect spatne identifikuje sdilene soubory.

**Mitigace:**
1. Pre-exekucni kontrola: pokud 2+ subtasky sdili soubor -> prepni na sekvencni mod
2. Fixer agent pro conflict resolution s kontextem obou zmen
3. Fallback na manualni reseni — BLOCK s detaily konfliktu
4. Architect instrukce: "Subtasky pro paralelni zpracovani NESMI sdilet soubory"

### Riziko 3: Subtask ordering errors

**Popis:** Subtask-2 zavisi na zmene z subtask-1, ale zavislost neni deklarovana. Sekvencni mod nahodou funguje (subtask-1 bezi pred 2), ale paralelni mod selze.

**Pravdepodobnost:** VYSOKA — implicitni zavislosti jsou tezko detekovatelne automaticky.

**Mitigace:**
1. Default sekvencni mod — bezpecnejsi, eliminuje vetsi cast ordering chyb
2. Architect instrukce: "Deklaruj VSECHNY zavislosti explicitne, vcetne implicitnich"
3. File-based detekce: pokud subtask-2 meni soubor modifikovany subtask-1, pridat implicitni zavislost
4. Build verifikace po kazdem subtasku — selhani odhali chybejici zavislost

### Riziko 4: State corruption behem multi-subtask exekuce

**Popis:** Task tree YAML soubor se poskodi (crash uprostred zapisu, concurrent pristup, disk full). Engine nemuze obnovit stav.

**Pravdepodobnost:** NIZKA — ale katastrofalni pri vyskytu.

**Mitigace:**
1. Zapis pres Write tool: Claude Code Write tool nepodporuje atomicke operace (temp soubor + rename). Task tree se zapisuje primo pres Write tool — jednoduchy a konzistentni s ostatnimi command instrukcemi.
2. Validace pri nacteni: pokud YAML je invalid nebo prazdny -> pokusit se o rekonstrukci stavu z git historie (commit hashe + branch structure). Toto je hlavni ochrana proti corrupted writes.
3. Backup predchozi verze: pred kazdym zapisem zkopirovat `{issue_id}.yaml` -> `{issue_id}.yaml.bak` (pres Bash cp prikaz).
4. Git commity jako source of truth: i bez YAML souboru lze rekonstruovat stav z git historie — commit messages obsahuji subtask ID, branch structure ukazuje progress.

### Riziko 5: Resource exhaustion (prilis mnoho worktrees)

**Popis:** Pri batch zpracovani `/fix-bugs 10 --decompose` s paralelnim modem: 10 bugu * 5 subtasku = 50 worktrees. Diskovy prostor, file descriptory, git performance.

**Pravdepodobnost:** STREDNI — nastava pri agresivnim batch zpracovani.

**Mitigace:**
1. `batch_size` z Worktrees config — limituje max soucasne worktrees
2. Cleanup po KAZDEM hotovem subtasku (ne az na konci)
3. Worktree limit per issue: max `max_subtasks` worktrees na jeden ticket
4. Celkovy worktree limit: max `batch_size * max_subtasks` (z config, default 5*5=25)
5. Disk space check pred vytvorenim worktree — pokud <1GB volneho mista -> WARN

### Riziko 6: Token exhaustion (vysoke naklady)

**Popis:** Dekompozice nasobi pocet agent volani. 5 subtasku s retry iteracemi muze spotrebovat 10x vice tokenu nez single-pass. Uzivatel neocekava $20 ucet za jeden ticket.

**Pravdepodobnost:** STREDNI — zvlaste pri slozitych issues s mnohymi retry iteracemi.

**Mitigace:**
1. Odhad nakladu PRED spustenim (viz sekce 8) — uzivatel musi potvrdit
2. Celkovy token budget (konfigurovatelny) — po dosazeni limitu STOP
3. Progresivni reporting: "Subtask 3/5, dosud spotrebovano ~180k tokenu (~$3.50)"
4. Retry limity zustavaji — max 5 fixer iteraci per subtask, ne per celou dekompozici

### Riziko 7: Ztrata kontextu mezi subtasky

**Popis:** Fixer agent pro subtask-3 nerozumi, proc subtask-1 zmenil urcity soubor. Generuje nekonzistentni kod. Reviewer to chyti, ale fixer nemuze opravit bez kontextu.

**Pravdepodobnost:** STREDNI — kontext se predava jako text, ale muze byt nedostatecny.

**Mitigace:**
1. Kontext pro kazdy subtask zahrnuje: cely decomposition plan + summary predchozich subtasku + diff summary
2. Fixer dostane instrukci: "Precti zmeny z predchozich subtasku pred zahajenim prace"
3. Reviewer kontroluje konzistenci s predchozimi subtasky (nova polozka v review checklistu)
4. Accumulated context: kazdy subtask muze pridat poznamky pro nasledujici subtasky

### Riziko 8: Nekonzistence mezi subtasky

**Popis:** Subtask-1 prida interface `IValidator`. Subtask-2 prida jiny interface `Validator` (bez I prefixu). Oba projdou review samostatne, ale dohromady jsou nekonzistentni.

**Pravdepodobnost:** STREDNI — kazdy subtask ma svuj reviewer pruchod, ale reviewer nevidi celkovy obraz.

**Mitigace:**
1. Integracni review krok: po vsech subtascich spustit reviewer na CELKOVY diff (ne per subtask)
2. Reviewer instrukce zahrnuji konvence z CLAUDE.md projektu
3. Architect definuje konvence v task tree (naming, patterns) — fixer je nasleduje
4. Integracni test suite chyti runtime nekonzistence (ale ne naming konvence)

### Riziko 9: Deadlock pri paralelnim modu s chybnym DAG

**Popis:** Navzdory detekci cyklu muze nastat deadlock pri runtime — subtask-A ceka na commit od subtask-B, ktery ceka na merge vysledek od subtask-A.

**Pravdepodobnost:** NIZKA — detekce cyklu pred spustenim by mela eliminovat.

**Mitigace:**
1. Pre-exekucni detekce cyklu (Kahnuv algoritmus)
2. Runtime timeout per execution level — pokud level nebezi za 15 minut -> BLOCK
3. Monitoring: engine sleduje stav vsech subtasku a detekuje "stuck" stavy

### Riziko 10: Incompatibilita s existujicim /fix-bugs worktree modem

**Popis:** `/fix-bugs` uz ma worktree podporu (viz `commands/fix-bugs.md`, sekce Worktree zpracovani). Dekompozice pridava druhou uroven worktrees (worktree per subtask uvnitr worktree per bug). Vnorene worktrees nejsou git feature.

**Pravdepodobnost:** VYSOKA — toto je realna architektonicka komplikace.

**Mitigace:**
1. **Pravidlo: nikdy vnorene worktrees.** Bug-level worktree NEBO subtask-level worktree, nikdy oba.
2. Pri `/fix-bugs --decompose` s worktrees:
   - Bug-level worktree se vytvori pro kazdy bug (existujici chovani)
   - Subtasky uvnitr bug-level worktree bezi SEKVENCNE (ne v dalsich worktrees)
   - Paralelismus je na urovni bugu, ne subtasku
3. Alternativa: subtask-level worktrees jen pri `/fix-ticket --decompose` (jeden bug, vice subtasku paralelne)

---

## 11. Otevrene otazky

```
Q: Jaky format pro task tree — YAML, JSON, nebo Markdown?
-> Navrhovana odpoved: YAML. Duvody: (1) Konzistence s Architect agent vystupem,
   ktery je prirozene strukturovany a YAML se dobre generuje z LLM vystupu.
   (2) Citelne pro cloveka — uzivatel muze otevrit .claude/decomposition/PROJ-42.yaml
   a videt stav. (3) Claude Code nativne zvlada YAML parsovani. JSON by fungoval taky,
   ale je mene citelny. Markdown je tezko parsovatelny strojove a nasobil by chybovost.
```

```
Q: Ma byt sekvencni nebo paralelni mod default?
-> Navrhovana odpoved: Sekvencni. Duvody: (1) Bezpecnejsi — zadne merge konflikty,
   zadne sdilene soubory, zadne race conditions. (2) Jednodussi implementace —
   muze byt hotovy v Fazi 2a bez zavislosti na Fazi 1. (3) Paralelni mod je
   optimalizace, ne zakladni funkcionalita. (4) Existujici /fix-bugs uz pouziva
   worktrees pro paralelismus na urovni bugu — pridavani dalsi urovne paralelismu
   zvysuje komplexitu. Paralelni mod bude dostupny pres config (Decomposition ->
   Strategy -> parallel), ale default zustava sequential.
```

```
Q: Jak resit "exploding decomposition" — Architect generuje 15 subtasku?
-> Navrhovana odpoved: Default limit 5 subtasku (konfigurovatelny v rozsahu 1-10). Pokud Architect
   vygeneruje vice, engine pozada o re-dekompozici s hintem "Sluc mensi kroky,
   max 5 subtasku." Pokud druhy pokus stale prekracuje limit, fallback:
   (A) vzit prvnich 5 a ignorovat zbytek, nebo (B) BLOCK s doporucenim pro
   cloveka. Navrhujeme variantu (B) — exploding decomposition signalizuje,
   ze issue je prilis velky pro automatizaci a melo by byt rucne rozlozeno
   na vice issues v trackeru. Varianta (A) riskuje, ze 5 subtasku nebude
   kompletni reseni.
```

```
Q: Jak resit fail-fast vs. continue-on-failure v kontextu zavislosti?
-> Navrhovana odpoved: Fail-fast jako default s inteligentnim skipovanim.
   Kdyz subtask-2 selze:
   - Subtasky zavisle na subtask-2 (primo i neprimo) se automaticky skipnou.
   - Subtasky NEzavisle na subtask-2 mohou pokracovat (pokud strategie = continue).
   Toto je hybrid: fail-fast pro zavislou vetev, continue pro nezavisle vetve.
   Implementace: pri selhani projdi DAG a oznac vsechny descendanty jako "skipped",
   pak pokracuj s dalsim subtaskem, ktery nema skipped zavislost.
   Konfigurovatelne pres Automation Config -> Decomposition -> Fail strategy.
```

```
Q: Jak se integrace s /resume-ticket zmeni pro dekompozicni stav?
-> Navrhovana odpoved: Novy checkpoint typ DECOMPOSE_PARTIAL s task tree
   souborem jako zdrojem pravdy. Resume-ticket precte .claude/decomposition/{issue}.yaml,
   urci posledni completed subtask, a pokracuje od dalsiho pending. Existujici
   checkpointy (POST_TRIAGE, POST_FIX, atd.) zustavaji beze zmeny — pouzivaji
   se pro non-decomposed tickets. Detekce: pokud existuje task tree YAML soubor
   pro dany issue, pouzij decomposition resume logiku; jinak puvodni logiku.
   Toto je zpetne kompatibilni — stare tickets bez task tree funguji jako dosud.
```

```
Q: Maji se subtask commity commitovat na hlavni branch ticketu nebo na
   sub-branches?
-> Navrhovana odpoved: Na hlavni branch ticketu (sekvencni mod) nebo na
   sub-branches (paralelni mod). V sekvencnim modu: vsechny subtasky commituji
   na jednu branch (napr. PROJ-42-fix), kazdy subtask = jeden commit. Na konci
   se bud squashnou, nebo zustanou jako individual commits. V paralelnim modu:
   kazdy worktree ma svou sub-branch (napr. PROJ-42-sub1, PROJ-42-sub2). Na konci
   se cherry-picknou na hlavni feature branch a sub-branches se smazou.
   Duvod pro rozliseni: sekvencni mod nemusi resit merge (commity jsou linearni),
   paralelni mod potrebuje sub-branches pro izolaci.
```

```
Q: Jak zabranit tomu, aby worktree management v /fix-bugs kolidoval
   s worktree management v dekompozici?
-> Navrhovana odpoved: Striktni pravidlo — NIKDY vnorene worktrees. Pri
   /fix-bugs s worktrees (existujici funkcionalita) se kazdy bug zpracovava
   v bug-level worktree. Pokud bug pouziva dekompozici, subtasky bezi SEKVENCNE
   uvnitr bug-level worktree. Paralelni subtask-level worktrees jsou povoleny
   JEN pri /fix-ticket --decompose (kde neexistuje nadrazeny bug-level worktree).
   Implementace: engine kontroluje, zda uz bezi v worktree (git rev-parse --show-toplevel
   vs git worktree list). Pokud ano, vynucuje sekvencni subtask zpracovani.
   Toto eliminuje vnorene worktrees uplne.
```

```
Q: Jak velka by mela byt Decomposition config sekce v Automation Config?
-> Navrhovana odpoved: Minimalni — 4 klice. CLAUDE-agents filozofie je
   "rozumne defaulty, konfigurace jen kdyz je potreba." Navrh:
   | Klic | Default | Popis |
   | Max subtasks | 5 | Limit dekompozice |
   | Strategy | auto | auto / sequential / parallel |
   | Fail strategy | fail-fast | fail-fast / continue |
   | Commit strategy | squash | squash / individual |
   Vsechno ostatni (timeouty, token limity, max diff) ma hard-coded default
   a neni konfigurovatelne v prvni verzi. Pokud se ukaze potreba, pridame
   v patch verzi. Duvod: prilis mnoho config klicu = prilis mnoho rozhodnuti
   pro uzivatele pri onboardingu (/onboard command). 4 klice = 1 minuta
   rozhodovani. 15 klicu = "nechci to nastavovat."
```

```
Q: Ma se task tree ukladat do git (commitovat) nebo jen na disk?
-> Navrhovana odpoved: Jen na disk, NE do gitu. Duvody: (1) Task tree je
   runtime artefakt, ne soucast codebase. (2) Commitovani by znecistilo
   git historii docasnymi soubory. (3) Pri cleanup (po publish) se soubor
   smaze — nepotrebujeme jeho historii. (4) Resumabilita je zaristena:
   soubor existuje na disku, dokud neni smazan. (5) Doporucujeme pridat
   .claude/decomposition/ do .gitignore. VYJIMKA: pokud uzivatel chce
   auditovatelnost, muze rucne commitovat task tree pred smazanim — ale
   to je jeho rozhodnuti, ne default chovani pluginu.
```

```
Q: Jak by mel vypadat integracni test po dokonceni vsech subtasku?
-> Navrhovana odpoved: Integracni krok je POVINNY po dokonceni vsech subtasku,
   bez ohledu na to, ze kazdy subtask prosel testy individualne. Duvod: subtask
   testy overibuji izolovanou zmenu, integracni test overuje interakci VSECH zmen.
   Flow: (1) Spustit plny test suite (Build & Test -> Test command z config).
   (2) Pokud E2E Test config existuje, spustit i E2E testy. (3) Pokud testy
   selhavaji, spustit fixer agenta s kontextem "Oprav integracni problem
   zpusobeny kombinaci subtasku" (max 3 pokusy). (4) Pokud nelze opravit,
   BLOCK. Tento krok je analogie krok 8 (test-engineer) v soucasnem fix-ticket,
   ale bezi na CELKOVEM diffu, ne na jednom subtask diffu.
```

```
Q: Ma byt dekompozice dostupna i pro /analyze-bug (read-only analyza)?
-> Navrhovana odpoved: ANO — jako soucast dry-run. /analyze-bug dnes spousti
   triage-analyst + code-analyst a zobrazuje vysledky bez zmen. S dekompozici
   by mohl navic zobrazit: "Tento bug by byl dekomponovan na N subtasku:
   [tabulka]". Toto je cenne pro planovani — clovek vidi, jak pipeline
   bug zpracuje, bez spusteni. Implementace: pridat --decompose flag do
   /analyze-bug, ktery spusti Architect/heuristiku a zobrazi plan. Zadne
   zmeny, zadne side effects. Ekvivalent: /fix-ticket --decompose --dry-run,
   ale strucnejsi syntax.
```

```
Q: Jak ochranit proti "subtask drift" — subtask zacne resit neco jineho nez
   jeho scope definuje?
-> Navrhovana odpoved: Trislozkova obrana: (1) Fixer agent dostane explicitni
   scope a acceptance criteria z task tree — instrukce "Zmen JEN soubory
   uvedene v scope. NIKDY nemen soubory mimo scope." (2) Reviewer kontroluje
   scope compliance — nova polozka v review checklistu: "Jsou zmeny v ramci
   definovaneho scope subtasku?" Pokud ne, REQUEST_CHANGES. (3) Post-subtask
   validace: engine porovna zmenene soubory s deklarovanymi v task tree.
   Pokud fixer zmenil soubor mimo scope, varuj uzivatele (ne automaticky
   block — fixer muze mit legitimni duvod, napr. transitivni zavislost).
```

---

## Dodatek A: Srovnani s existujicimi resenimi

### Jak to dela Devin AI

Devin pouziva "planner" agent, ktery rozlozi task na kroky a "executor" agent, ktery je provadi. Kroky jsou linearne (zadny DAG). Kazdy krok = jedna "action" (edit file, run command, browse web). Dekompozice je na urovni jednotlivych operaci, ne logickych celku.

**Rozdil:** CLAUDE-agents dekomponuje na LOGICKE CELKY (subtasky), ne na atomicke operace. Subtask = mini-pipeline (fixer + reviewer + test). Toto je vyssi uroven abstrakce — mensi pocet subtasku, ale kazdy je robustnejsi (prochazi review + test).

### Jak to dela GitHub Copilot Workspace

Copilot Workspace zobrazuje "plan" s kroky, uzivatel muze kroky upravit pred exekuci. Plan je linearni seznam zmen per soubor. Zadna dekompozice na nezavisle subtasky, zadny dependency graf.

**Rozdil:** CLAUDE-agents ma dependency graf, paralelni exekuci, a per-subtask review/test. Copilot Workspace bezi bez review a testu — uzivatel musi sam zkontrolovat.

---

## Dodatek B: Priklad end-to-end flow

### Scenar: Complex bug fix s dekompozici

**Bug:** "Data corruption pri concurrent sync operacich" (PROJ-42)

```
KROK 1: Uzivatel spusti
> /CLAUDE-agents:fix-ticket PROJ-42 --decompose

KROK 2: Pipeline zacina
  - Nacitam Automation Config...
  - Issue tracker: YouTrack, Type: youtrack
  - Nastavuji stav: In Progress
  - Vytvarim branch: PROJ-42-sync-corruption-fix

KROK 3: Triage (triage-analyst, sonnet)
  - Severity: HIGH
  - Area: data-sync
  - Reproduction: "Spusti 10 concurrent sync operaci, data se pokazi"
  - [CLAUDE-agents] Triage dokoncen. Severity: HIGH. Area: data-sync.

KROK 4: Code-analyst (sonnet)
  - Root cause: chybejici locking v SyncService.sync()
  - Affected files: SyncService.ts, DataStore.ts, SyncWorker.ts,
    mutex.ts (novy), sync.test.ts (novy)
  - Risk: HIGH (5 souboru, concurrent access)
  - Doporuceny pristup: "Pridat mutex, retry logiku, graceful shutdown"

KROK 5: Decomposition decision
  - --decompose flag: ANO
  - HIGH risk + 5 files + >60 lines: ANO (i bez flagu)
  - Spoustim Architect/heuristiku...

KROK 6: Architect vystup
  Dekompozice na 5 subtasku (viz priklad v sekci 6)

KROK 7: Zobrazeni planu
  ## Decomposition Plan — PROJ-42

  | # | Subtask | ~Lines | Zavisi na |
  |---|---------|--------|-----------|
  | 1 | Mutex pro SyncService | ~20 | — |
  | 2 | Retry logika v DataStore | ~30 | 1 |
  | 3 | Graceful shutdown SyncWorker | ~35 | 1 |
  | 4 | Integracni test | ~45 | 1, 2, 3 |
  | 5 | Cleanup deprecated API | ~15 | 4 |

  Strategie: sekvencni (zavislosti)
  Odhad: ~145 lines, ~$4.00
  Pokracovat? [A/n]

  > A

KROK 8: Exekuce subtask-1
  [fixer] Pridavam mutex do SyncService.ts, vytvarim mutex.ts
    -> Diff: +18 lines, 2 soubory
  [build] npm run build -> OK
  [reviewer] APPROVE — minimalni zmena, spravny mutex pattern
  [test] Existujici testy: PASS. Novy test: SyncService.mutex.test.ts PASS
  [commit] "subtask-1: add mutex to SyncService" (a1b2c3d)
  -> Task tree update: sub-1 = completed

KROK 9: Exekuce subtask-2
  [fixer] Pridavam retry logiku do DataStore.ts
    -> Diff: +28 lines, 1 soubor
  [build] npm run build -> OK
  [reviewer] REQUEST_CHANGES — chybi exponential backoff
  [fixer] Iterace 2 — pridavam backoff
    -> Diff: +32 lines
  [reviewer] APPROVE
  [test] PASS
  [commit] "subtask-2: add retry logic to DataStore" (d4e5f6a)
  -> Task tree update: sub-2 = completed

KROK 10: Exekuce subtask-3
  [fixer] Pridavam shutdown handler do SyncWorker.ts a WorkerManager.ts
    -> Diff: +33 lines, 2 soubory
  [build] OK
  [reviewer] APPROVE
  [test] PASS
  [commit] "subtask-3: add graceful shutdown to SyncWorker" (g7h8i9j)
  -> Task tree update: sub-3 = completed

KROK 11: Exekuce subtask-4
  [fixer] Vytvarim sync-race.test.ts
    -> Diff: +42 lines, 1 soubor
  [build] OK
  [reviewer] APPROVE
  [test] PASS (10 concurrent sync operaci, zadna korupce)
  [commit] "subtask-4: integration test for race condition" (k0l1m2n)
  -> Task tree update: sub-4 = completed

KROK 12: Exekuce subtask-5
  [fixer] Odstranuji deprecated metody
    -> Diff: -12 lines, 2 soubory
  [build] OK
  [reviewer] APPROVE
  [test] PASS
  [commit] "subtask-5: cleanup deprecated sync API" (o3p4q5r)
  -> Task tree update: sub-5 = completed

KROK 13: Integracni krok
  [test] Full test suite: 247 tests, 247 passed, 0 failed
  [squash] 5 commitu -> 1: "PROJ-42: fix data corruption in concurrent sync"
  -> Task tree update: status = completed

KROK 14: Vysledek
  ## Decomposition Complete — PROJ-42

  | # | Subtask | Status | Fixer iter. | Reviewer |
  |---|---------|--------|-------------|----------|
  | 1 | Mutex pro SyncService | OK | 1 | APPROVE |
  | 2 | Retry logika v DataStore | OK | 2 | APPROVE |
  | 3 | Graceful shutdown | OK | 1 | APPROVE |
  | 4 | Integracni test | OK | 1 | APPROVE |
  | 5 | Cleanup deprecated API | OK | 1 | APPROVE |

  **Celkem:** 5/5 subtasku OK, 6 fixer iteraci, ~135 lines changed
  **Full test suite:** 247/247 PASS
  **Spotrebovano:** ~310k tokenu (~$3.80)

  Pro publish zadej: /CLAUDE-agents:publish

KROK 15: (uzivatel rozhodne)
> /CLAUDE-agents:publish

  -> Publisher vytvari PR...
  -> PR #142: "PROJ-42: fix data corruption in concurrent sync"
  -> Issue tracker: stav = For Review
  -> Hotovo.
```

---

## Dodatek C: Zmeny v existujicich souborech

Implementace Faze 2 vyzaduje zmeny v techto existujicich souborech:

| Soubor | Typ zmeny | Popis |
|--------|-----------|-------|
| `commands/fix-ticket.md` | MODIFIKACE | Pridani --decompose flagu, integrace decomposition enginu mezi krok 4 (code-analyst) a krok 5 (fixer) |
| `commands/fix-bugs.md` | MODIFIKACE | Pridani --decompose flagu, per-ticket decomposition v batch zpracovani |
| `commands/resume-ticket.md` | MODIFIKACE | Novy checkpoint DECOMPOSE_PARTIAL, task tree detekce |
| `commands/check-setup.md` | MODIFIKACE | Validace Decomposition config sekce |
| `commands/analyze-bug.md` | MODIFIKACE | Volitelny --decompose pro zobrazeni planu |
| `agents/rollback-agent.md` | MODIFIKACE | Per-subtask rollback logika |
| `agents/fixer.md` | BEZ ZMENY | Fixer agent se nemeni — dostava jen jiny kontext (subtask vs. cely issue) |
| `agents/reviewer.md` | BEZ ZMENY | Reviewer se nemeni — dostava jen jiny kontext |
| `skills/bug-workflow/SKILL.md` | MODIFIKACE | Nove intenty pro dekompozici |
| `CLAUDE.md` | MODIFIKACE | Dokumentace Decomposition config sekce, aktualizace pipeline diagramu |

**Nove soubory:**

| Soubor | Typ | Popis |
|--------|-----|-------|
| `commands/implement-feature.md` | NOVY (Faze 1, ne 2) | Feature pipeline command |
| `agents/architect.md` | NOVY (Faze 1, ne 2) | Architect agent pro dekompozici |
| `agents/spec-analyst.md` | NOVY (Faze 1, ne 2) | Spec analyst pro feature pipeline |

**Poznamka:** Vetsina novych souboru patri do Faze 1 (Feature Pipeline). Faze 2 (Decomposition) PRIMARNE modifikuje existujici soubory a pridava logiku do command enginu. Jediny novy artefakt Faze 2 je YAML task tree format (runtime, ne commitovany soubor).

---

## Dodatek D: Automation Config rozsireni

Nova volitelna sekce `Decomposition`:

```markdown
### Decomposition (optional)
| Klic | Hodnota |
|------|---------|
| Max subtasks | 5 |
| Strategy | auto |
| Fail strategy | fail-fast |
| Commit strategy | squash |
```

**Hodnoty:**
- **Max subtasks:** 1-10 (integer). Default: 5.
- **Strategy:** `auto` (engine rozhodne), `sequential` (vzdy sekvencne), `parallel` (vzdy paralelne, vyzaduje Worktrees config). Default: `auto`.
- **Fail strategy:** `fail-fast` (zastavit pri prvnim selhani), `continue` (pokracovat nezavislymi subtasky). Default: `fail-fast`.
- **Commit strategy:** `squash` (vsechny subtask commity se squashnou do jednoho), `individual` (kazdy subtask jako samostatny commit v PR). Default: `squash`.

**Dopad na verzi pluginu:** Nova volitelna config sekce = MINOR (v3.1.0). Zadny breaking change.

**Dopad na /onboard:** Rozsireni onboard commandu o otazku "Chces nastavit Decomposition?" (v ramci volitelnych sekci).

**Dopad na /check-setup:** Validace formatu a hodnot Decomposition sekce (pokud existuje).

---

## Review Status

**Review:** 2026-02-27 | **Stav:** APPROVED
**Vsechny [REVIEW Q] rozhodnuty:** M1 (verze v3.1.0 — Varianta A), I3 (threshold 60 + 3 files — Varianta B).

### Zapracovane nalezy

| Typ | ID | Popis | Stav |
|-----|-----|-------|------|
| Critical | C1 | Pseudokod preformulovan na LLM-executable instrukce (detekce cyklu, orchestrace, fallback) | ZAPRACOVANO |
| Critical | C2 | Atomicke YAML zapisy nahrazeny Write tool + validace pri nacteni | ZAPRACOVANO |
| Critical | C3 | Timeout per subtask nahrazen soft warningem (monitoring doby behu) | ZAPRACOVANO |
| Important | I1 | Heuristicky decomposer dospecifikovan (5 detailnich pravidel) | ZAPRACOVANO |
| Important | I2 | Squash commit strategie — squash az po integraci, ne prubezne | ZAPRACOVANO |
| Important | I3 | Threshold 60 radku — kombinovany signal: >60 lines AND >=3 files (Varianta B) | ROZHODNUTO |
| Important | I4 | Flag parsing specifikovany (mechanismus z $ARGUMENTS) | ZAPRACOVANO |
| Important | I5 | Rollback-agent effort zvysen z S na M, popis rozsiren | ZAPRACOVANO |
| Important | I6 | Paralelni exekuce pres worktrees — pridano upozorneni o neprokázanosti + PoC pozadavek | ZAPRACOVANO |
| Minor | M1 | Verze v3.1.0 ponechana — planovaci verze dle roadmapy (Varianta A) | ROZHODNUTO |
| Minor | M2 | Config headers CZ/EN — preskoceno (vyzaduje audit celeho dokumentu, ne trivialni) | PRESKOCENO |
| Minor | M3 | `skipped` stav doplnen do DAG datove struktury (sekce 3) | ZAPRACOVANO |
| Minor | M4 | "Hard limit 5" opraveno na "Default 5" (konfigurovatelne 1-10) | ZAPRACOVANO |
| Minor | M5 | Token pricing oznacen jako ilustrativni (February 2026 sazby) | ZAPRACOVANO |
| Minor | M6 | Resume — pridana kontrola divergence base branch | ZAPRACOVANO |
| Cross-doc | — | YAML format synchronizace s Feature Pipeline v3.0 — pridana poznamka do sdilenych komponent | ZAPRACOVANO |
