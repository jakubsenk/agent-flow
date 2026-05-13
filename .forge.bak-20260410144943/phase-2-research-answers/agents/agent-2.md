# Phase 1 Research Answers — Agent 2

Datum: 2026-04-10
Agent: Research Agent 2
Oblast: Gaps analýza (State transitions, Pipeline flow, Standalone agents, Token cost)

---

## Q-2A-01 (HIGH): Chybí stav „Ready" v State transitions?

**Hodnocení: CHYBÍ**

### Nalezené reference

**`docs/reference/trackers.md`, řádky 20–29** — tabulka State Transition Syntax:

| Tracker | Format | Example: In Progress | Example: Done |
|---------|--------|---------------------|---------------|
| redmine | `status:{name}` | `status:In Progress` | `status:Closed` |

Definované příklady state transitions zahrnují pouze: `In Progress`, `Blocked`, `For Review`, `Done`.

**`skills/onboard/SKILL.md`, řádky 75–76** (krok 6, State transitions):
> State transitions — read defaults from `docs/reference/trackers.md` State Transition Syntax table. Compose the full value using comma separator: `In Progress: {format}, Blocked: {format}, For Review: {format}, Done: {format}`

**`core/config-reader.md`, řádky 16–17**:
> `issue_tracker.state_transitions` (key→value map)

**`docs/reference/trackers.md`, řádky 20–29** (State Transition Syntax table) a řádky 41–50 (On Start Set Defaults table):
- Pro Redmine defaultní On start set: `status:In Progress`
- Žádná zmínka o stavu `Ready` v žádné tabulce

### Analýza

Systém definuje 4 pevné stav-přechody: `In Progress`, `Blocked`, `For Review`, `Done`. Stav `Ready` (jako "čeká na zpracování", "připraveno k zahájení") v žádném místě explicitně nefiguruje.

V Redmine je `Ready` (nebo ekvivalentní stav `New`/`Open`) běžný vstupní stav. Pipeline sice čte `On start set` (nastaví `In Progress` při zahájení), ale nemá koncept "vrácení ticketu do Ready/Open stavu" — např. po zamítnutí revieweru nebo po pipeline bloku.

**Dopady:**
- Pokud zákazník používá Redmine s více stavy (New → Ready → In Progress → For Review → Done), pipeline neumí tickety resetovat do `Ready`
- Block handler nevolá žádný specifický state transition pro Redmine stav `Ready`
- `/onboard` průvodce nenabídne `Ready` jako volbu pro State transitions
- Workaround: uživatel může ručně přidat `Ready: status:Ready` do config tabulky, ale to není zdokumentováno ani testováno

---

## Q-2A-02 (HIGH): Lze po „In Review" zastavit pipeline a čekat na lidský vstup?

**Hodnocení: ČÁSTEČNĚ**

### Nalezené reference

**`skills/fix-ticket/SKILL.md`, řádky 573–578** (krok 9 — Result):
> Display the result. If `--yolo` → auto-publish. Otherwise the user decides about publishing.
> If the user chooses to publish (or `--yolo`) → run `ceos-agents:publisher`

**`skills/fix-ticket/SKILL.md`, řádky 628–630** (Rules):
> - Publisher is NOT called automatically — the user decides

**`agents/publisher.md`, řádky 66–68** (krok 7 — Update Issue Tracker):
> Set issue state: "For Review" (or equivalent from Automation Config → State transitions)

**`skills/publish/SKILL.md`, řádky 26–27**:
> Issue tracker: set state per Automation Config (Issue Tracker → State transitions → For Review)

### Analýza

**De facto pauza před publishem EXISTS:** Po dokončení fixer↔reviewer smyčky, test-engineer a acceptance-gate pipeline v `fix-ticket` ZASTAVÍ a čeká na rozhodnutí uživatele (krok 9). Uživatel musí říct "publish" nebo zavolat `/ceos-agents:publish` samostatně.

**Avšak stav „In Review" tracker pipeline NENASTAVÍ před tímto čekáním.** Tracker dostane `For Review` stav až v okamžiku, kdy publisher vytvoří PR (krok 7 v `publisher.md`). Není tedy možné nastavit tracker do stavu "In Review" (čeká na code review od lidského recenzenta) PŘEDTÍM, než se spustí publisher.

**Chybějící mechanismus:**
- Neexistuje `pause` hook nebo `awaiting-review` state transition
- Neexistuje způsob, jak nakonfigurovat: "po schválení reviewer agenta nastav tracker na `In Review` a čekej, dokud lidský reviewer neschválí"
- `/resume-ticket` umí pokračovat od pipeline bloku, ale ne od záměrné pauzy na human review
- Stav se nastaví na `For Review` až PŘI vytvoření PR, ne před ním

**Dopady:**
- Organizace s manuálním code review procesem (PR review → schválení → merge) musí toto řešit mimo pipeline
- Redmine workflow, kde `In Review` je separate stav od `For Review`, není mapovatelný

---

## Q-2A-03 (MEDIUM): Existuje mechanismus pro zpětný zápis agent_session_id/run_id do Redmine?

**Hodnocení: CHYBÍ**

### Nalezené reference

**`core/state-manager.md`, celý soubor** — popisuje čtení/zápis do `.ceos-agents/{RUN-ID}/state.json` lokálně. Žádná zmínka o zpětném zápisu do issue trackeru.

**`agents/publisher.md`, řádky 66–68** (krok 7):
> Set issue state: "For Review" (or equivalent from Automation Config → State transitions)
> Add comment to issue with PR link

Publisher zapisuje do trackeru pouze: nový stav a komentář s PR linkem.

**`skills/fix-ticket/SKILL.md`, řádky 83–86** (krok 0 — inicializace state.json):
> Initialize `state.json` with `status: "running"`, `mode: "code-bugfix"`, `pipeline: "fix-ticket"`, `run_id: "{ISSUE-ID}"`

`run_id` je uložen pouze lokálně v `state.json`, NIKDY není zapsán zpět do trackeru.

### Analýza

**`agent_session_id` jako koncept neexistuje vůbec** — v žádném souboru se tento termín nevyskytuje.

**`run_id`** je interní identifikátor pipeline běhu (typicky = `{ISSUE-ID}`), uložen pouze v `.ceos-agents/{ISSUE-ID}/state.json`.

Jedinou informací zápisovanou zpět do trackeru jsou:
1. Triage checkpoint komentář: `[ceos-agents] Triage completed. Severity: ... Area: ... Complexity: ... AC: ...`
2. Block komentář: `[ceos-agents] 🔴 Pipeline Block ...`
3. PR link komentář (publisher)
4. Změna stavu (publisher)

Žádný z těchto komentářů neobsahuje `run_id`, `session_id`, ani odkaz na lokální log soubory.

**Dopady:**
- Nelze z Redmine ticketu dohledat lokální pipeline logy
- Nelze propojit více pipeline běhů na stejném ticketu (resume, retry)
- Auditing a traceabilita jsou omezeny — musíte vědět, kde jsou lokální `.ceos-agents/` soubory

---

## Q-2B-01 (MEDIUM): Je task tree architekta vždy jednourovňový?

**Hodnocení: PODPOROVÁNO (s výhradou)**

### Nalezené reference

**`agents/architect.md`, řádky 46–66** (krok 8 — Generate task tree):

```yaml
decomposition:
  strategy: sequential | parallel | mixed
  reason: "Brief explanation why decomposition is needed"
  subtasks:
    - id: "sub-1"
      title: "Short description"
      scope: "What exactly to do"
      files: [...]
      estimated_lines: 25
      depends_on: []
      maps_to: [...]
      acceptance_criteria: [...]
```

**`agents/architect.md`, řádek 93**:
> Maximum 7 subtasks per decomposition (configurable via Automation Config → Decomposition → Max subtasks)

**`core/decomposition-heuristics.md`, výstup**:
> `DECOMPOSE` — Run architect agent, build task tree, execute per-subtask

**`skills/fix-ticket/SKILL.md`, řádky 178–201** (krok 4b — Decomposition decision):
Zpracovává seznam subtasků jako flat list v topologickém pořadí.

### Analýza

YAML schéma architekta definuje POUZE jednourovňovou strukturu: `decomposition.subtasks[]` je přímý seznam. Neexistuje `subtasks[].subtasks[]` ani žádná hierarchická vnořenost.

Závislosti jsou modelovány přes `depends_on: []` (topologické řazení), ne přes vnoření. To je záměrná architektonická volba — jednoúrovňový DAG s pořadím.

**Výhrada:** Formát je jednourovňový, ale `mixed` strategie umožňuje modelovat komplexní závislostní grafy. Skutečná hloubka hierarchie je JEDNA, ale šířka a komplikovanost grafu mohou být velké.

**Dopady:**
- Architekturálně čisté — fixer agent vždy dostane jeden izolovaný subtask
- Nelze přirozeně modelovat "epics s features s subtasky" — vše je na jedné úrovni
- Max 7 subtasků omezuje škálovatelnost pro velmi velké features

---

## Q-2B-02 (HIGH): NEEDS_DECOMPOSITION na subtasku — poruší 2-úrovňovou hierarchii?

**Hodnocení: CHYBÍ (ochrana)**

### Nalezené reference

**`core/fixer-reviewer-loop.md`, řádky 21–23**:
> 3. If fixer output contains `## NEEDS_DECOMPOSITION` → return `NEEDS_DECOMPOSITION` immediately. Only allowed once per ticket; caller enforces the limit.

**`skills/fix-ticket/SKILL.md`, řádky 447–453** (krok 5 — Fixer, NEEDS_DECOMPOSITION handling):
```
If fixer output contains `## NEEDS_DECOMPOSITION`:
  1. Authoritative revert: git checkout . && git clean -fd
  2. If decompose_mode = DISABLED → Block ("Fixer needs decomposition but --no-decompose was set")
  3. If this ticket has already been decomposed once → Block ("Decomposition limit (1) reached")
  4. Run architect agent for decomposition (same as step 4b with FORCE)
  5. Continue with subtask execution (step 4c)
```

**`skills/fix-ticket/SKILL.md`, řádky 385–418** (krok 4c — Subtask execution):
Krok 4c volá `fixer` pro každý subtask iterativně. Po dokončení všech subtasků jde pipeline přímo na krok 8d (Pre-publish hook).

### Analýza

**KRITICKÁ MEZERA:** Ochrana "Decomposition limit (1) reached" v **kroku 5 (SINGLE_PASS fixer)** funguje správně. Ale co se stane, když NEEDS_DECOMPOSITION přijde z **kroku 4c (subtask execution)**?

V kroku 4c je fixer volán pro každý subtask v `for each subtask` smyčce (řádky 385–418). Tato smyčka volá `fixer` přes Task tool, ale logika zpracování NEEDS_DECOMPOSITION z kroku 5 se v kroku 4c **explicitně neopakuje**.

Krok 4c definuje pouze:
- build failure → Block handler
- reviewer REQUEST_CHANGES → zpět na fixer (max Fixer iterations)
- subtask failure → per-subtask rollback + fail-fast

**Chybí:** explicitní handling `## NEEDS_DECOMPOSITION` signálu uvnitř subtask execution loopu (krok 4c).

**Důsledek:** Pokud fixer v subtasku vypíše `## NEEDS_DECOMPOSITION`, krok 4c to nezachytí jako speciální signál. Pipeline buď:
1. Bude interpretovat output jako běžný fixer output (pravděpodobně reviewer pak odmítne)
2. Nebo se chování bude lišit podle implementace LLM

Tím by mohlo dojít k vytvoření 2-úrovňové hierarchie (decompose of a decomposed subtask), nebo naopak k nesprávnému blokování.

**Dopady:**
- Potenciální nekonzistence stavu pipeline při komplexních subtascích
- Spec říká "Only allowed once per ticket; caller enforces the limit" — ale krok 4c není "caller" pro NEEDS_DECOMPOSITION, krok 5 ano

---

## Q-2C-01 (HIGH): Lze spustit jednotlivého agenta standalone mimo pipeline?

**Hodnocení: ČÁSTEČNĚ**

### Nalezené reference

**`CLAUDE.md`, řádky 45–67** (Agent Definition Format):
> Every agent file in `agents/` follows this exact structure: frontmatter with `name`, `description`, `model`, `style`

**`CLAUDE.md`, řádky 12–13** (2-Layer System):
> Skills (orchestration — WHAT to do) ... Agents (specialists — HOW to do it)
> Skills read `## Automation Config` from the project's CLAUDE.md and dispatch agents. Skills contain zero project-specific logic.

Agenti jsou dispatchováni přes `Task tool` ze skills — viz `skills/fix-ticket/SKILL.md`, řádky 128–130:
> Run `ceos-agents:triage-analyst` (Task tool, model: sonnet).

**`skills/analyze-bug/SKILL.md`** — tato skill volá agenty `triage-analyst` a `code-analyst` jako standalone analýzu mimo full pipeline.

### Analýza

**Technicky ano, prakticky jen přes skill wrapper:**

Agenti jsou definováni jako Claude Code agent files (frontmatter + markdown). Claude Code umožňuje volat pojmenované agenty přes Task tool: `ceos-agents:triage-analyst`. Uživatel může tohoto agenta zavolat přímo v konverzaci jako `@ceos-agents:triage-analyst`.

**Ale:**
- Neexistuje žádná standalone skill pro každého agenta individuálně (kromě `/analyze-bug` která wrap triage+code-analyst)
- Agenti předpokládají kontext z předchozích pipeline kroků (např. triage-analyst předpokládá, že dostane issue ID; fixer předpokládá, že dostane AC a code-analyst output)
- Publisher agent předpokládá existenci větve a commitů — standalone volání bez pipeline kontextu selže
- Reproducer, browser-verifier, deployment-verifier potřebují specifické soubory z `.ceos-agents/{ISSUE-ID}/`

**Existující standalone entry points:**
- `/analyze-bug` — volá triage-analyst + code-analyst
- `/ceos-agents:discuss` — multi-agent diskuse (volá agenty v debatním módu)

**Chybí:** Granulární standalone skills pro jednotlivé agenty (reviewer, fixer, test-engineer, publisher samostatně).

**Dopady:**
- Nelze snadno "spustit jen reviewer na existující PR"
- Nelze snadno "spustit jen publisher bez předchozí pipeline"
- Workaround: přímé `@ceos-agents:reviewer` volání v chatu s manuálním kontextem

---

## Q-2C-02 (MEDIUM): Publisher je mandatory — blokuje "generuj kód bez PR"?

**Hodnocení: ČÁSTEČNĚ**

### Nalezené reference

**`core/profile-parser.md`, řádky 17–18**:
> 5. Validate skip list: stages `fixer`, `reviewer`, `publisher` CANNOT be skipped. If any appear → BLOCK with error: "Profile '{name}' attempts to skip mandatory stage '{stage}'. Fixer, reviewer, and publisher cannot be skipped."

**`skills/fix-ticket/SKILL.md`, řádky 573–575** (krok 9 — Result):
> Display the result. If `--yolo` → auto-publish. Otherwise the user decides about publishing.
> If the user chooses to publish (or `--yolo`) → run `ceos-agents:publisher`

**`skills/fix-ticket/SKILL.md`, řádky 628–630** (Rules):
> - Publisher is NOT called automatically — the user decides

### Analýza

**Duality:** Publisher je "mandatory" ve smyslu, že **nelze ho přeskočit přes Pipeline Profile** (`profile-parser.md` to explicitně blokuje). ALE publisher NENÍ automaticky spuštěn — uživatel musí explicitně říct "publish" nebo použít `--yolo`.

**Tedy:** "generuj kód bez PR" je možné jako workflow:
1. Spustit `/fix-ticket {id}` bez `--yolo`
2. Pipeline provede vše až do kroku 9
3. Uživatel odmítne publish
4. Kód existuje v local branch, bez PR

**Ale nešlo by to nakonfigurovat přes Pipeline Profile** — nelze vytvořit profil `no-publish`, který by publisher přeskočil. Pokud uživatel chce "vždy neskipovat publisher", je chráněn.

**Dopady:**
- Pro use-case "jen vygeneruj kód, nepublikuj" funguje manuální odmítnutí v interaktivním módu
- Ale `--yolo` mode vždy publishuje — pro CI/CD automation bez PR není `--yolo` použitelný
- Chybí `--no-publish` flag jako explicitní varianta k `--yolo`

---

## Q-2D-01 (HIGH): Je spotřeba tokenů skutečná nebo odhad?

**Hodnocení: CHYBÍ (skutečné trackování)**

### Nalezené reference

**`skills/estimate/SKILL.md`, řádky 49–77** (Per-stage token costs):
> Per-stage token costs (heuristic)
> ⚠️ Estimates are heuristic — actual costs may vary ±50%.

**`skills/estimate/SKILL.md`, řádek 104**:
> If metrics data unavailable → mention "Based on heuristics only".

**`skills/metrics/SKILL.md`, řádky 77–80** (krok 6 — Token cost estimate):
> Per-issue estimate: count stages × model tokens (sonnet ~30k, opus ~50k, haiku ~5k per invocation).
> Total estimate for the period.

**`core/state-manager.md`**, celý soubor — `state.json` obsahuje pole:
- `triage.status`, `code_analysis.status`, `fixer_reviewer.iterations`, `test.attempts`, atd.
- **Žádné pole pro skutečné tokeny** — `token_usage`, `actual_tokens`, `cost` se v schema ani v state-manager.md nevyskytují

**`skills/fix-ticket/SKILL.md`, řádky 586–591** (krok 9c — Token usage estimate):
```
Estimated usage: ~119,000 tokens
Estimated cost: ~$0.50–$1.60 USD
(Estimate is approximate — actual costs may be 2–5× higher/lower)
```
Toto je **statický text** vložený přímo do skill definice jako "display text", ne dynamicky vypočítaná hodnota.

### Analýza

**Skutečná spotřeba tokenů NENÍ sledována nikde v pipeline.** Vše jsou heuristiky:

1. `/estimate` — heuristický pre-run odhad (stage × fixní token cena z tabulky)
2. `/metrics` — retrospektivní heuristický odhad (stages × fixní token cena za invokaci)
3. `fix-ticket` krok 9c — statický "hard-coded" odhad vložený do textu skill

Claude Code API neposkytuje usage metadata zpět do agentního kontextu způsobem, který by se dal automaticky uložit. Tokeny by musely být sledovány přes Anthropic API usage endpoint mimo pipeline.

**Dopady:**
- Skutečné náklady na provoz pipeline jsou neznámé — jen ±50% odhad
- `/metrics` report pro "Est. token cost" je heuristika, ne skutečná data
- Nelze detekovat "tenhle ticket stál 10× více než obvykle" bez externího monitoringu

---

## Q-2D-02 (HIGH): Chybí hard cost ceiling?

**Hodnocení: CHYBÍ**

### Nalezené reference

**`CLAUDE.md`, řádky 192–201** (Config Contract — Retry Limits):
> Fixer iterations (default: 5), Test attempts (default: 3), Build retries (default: 3), Spec iterations (default: 5), Root cause iterations (default: 3)

**`CLAUDE.md`, řádky 214–215** (Config Contract — Error Handling):
> On block (default: `comment`), Max blocked per run (default: `unlimited`)

**`skills/estimate/SKILL.md`, řádky 60–67** (Worst case calculation):
```
| Scenario | Tokens (input) | Tokens (output) | Est. Cost |
| Worst case | ~{N}k | ~{N}k | ~${max} |
```
Jen zobrazí worst case odhad, nenastaví žádný strop.

**`core/profile-parser.md`** — Pipeline Profiles umožňují přeskočit stages (triage, code-analyst, test-engineer, reproducer, browser-verifier), čímž se nepřímo snižují tokeny. Ale to není cost ceiling, jen stage skip.

### Analýza

**Hard cost ceiling jako konfigurační možnost NEEXISTUJE.** Neexistuje žádný z těchto mechanismů:

1. `Max cost per run: $X` — pipeline se zastaví, pokud překročí odhadovaný/skutečný náklad
2. `Max tokens per run: N` — tvrdý strop na tokeny
3. Token budget awareness — agenti nevědí, "kolik tokenů zbývá"
4. Auto-cancel při překročení limitu

**Existující aproximace (ale ne cost ceiling):**
- `Retry Limits` omezují maximální počet iterací → nepřímo omezují tokeny per run
- `Max blocked per run` (Error Handling) omezuje počet zablokovaných issues, ne celkový cost
- Pipeline Profiles mohou přeskočit drahé stages (opus agenti)

**Worst-case scenario bez stropu:**
- 5 fixer iterations × 7 subtasks × opus = 5 × 7 × (~$0.75) ≈ $26 za jeden ticket
- Plus test-engineer retries, e2e, browser-verifier, acceptance-gate
- Estimate skill varuje "may be 2–5× higher/lower" — takže reálný worst case neznámý

**Dopady:**
- Bez cost ceiling je pipeline potenciálně velmi drahá při komplikovaných ticketech
- Organizace nemůže nastavit "max $5 na ticket" jako safety guard
- Jedinou ochranou jsou retry limity, ale ty jsou nastaveny na funcionalitu (kvalita), ne na cenu

---

## Souhrn mezer

| ID | Závažnost | Status | Popis |
|----|-----------|--------|-------|
| Q-2A-01 | HIGH | CHYBÍ | Stav „Ready" v State transitions není podporován |
| Q-2A-02 | HIGH | ČÁSTEČNĚ | Pauza před publishem existuje, ale stav „In Review" se nenastavuje předem |
| Q-2A-03 | MEDIUM | CHYBÍ | Žádný zpětný zápis run_id/session_id do Redmine |
| Q-2B-01 | MEDIUM | PODPOROVÁNO | Task tree je vždy jednourovňový DAG (záměrně) |
| Q-2B-02 | HIGH | CHYBÍ | NEEDS_DECOMPOSITION uvnitř subtask execution loop není ošetřen |
| Q-2C-01 | HIGH | ČÁSTEČNĚ | Agenti volatelní přes Task, ale chybí granulární standalone skills |
| Q-2C-02 | MEDIUM | ČÁSTEČNĚ | Publisher mandatory přes profily, ale interaktivně lze odmítnout |
| Q-2D-01 | HIGH | CHYBÍ | Skutečná spotřeba tokenů není sledována, vše jsou heuristiky |
| Q-2D-02 | HIGH | CHYBÍ | Hard cost ceiling neexistuje, jen nepřímé retry limity |
