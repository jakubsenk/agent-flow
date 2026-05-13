# Agent–Process Separation: Interface Design

> **Status:** Proposal — pre-decision
> **Datum:** 2026-04-07
> **Kontext:** ceos-agents je Claude Code plugin; veškerá orchestrace probíhá jako přirozený jazyk interpretovaný LLM, nikoliv jako typovaný runtime. Navrhované kontrakty jsou tedy primárně **dokumentovatelné smlouvy** a **pre-flight validační schémata**, ne strojově vynucené typy v kompilačním čase.

---

## TL;DR — Shrnutí návrhu

### Je oddělení vhodné? Ano — s podmínkou postupnosti

Stávající architektura mísí ve stejném souboru dvě ortogonální věci: *co agent umí* a *jak je orchestrován*. Konkrétní problémy:

- `reviewer.md` obsahuje "Reviewer Loop" sekci — to je procesní logika, ne agentní schopnost
- `skills/fix-bugs/SKILL.md` builduje context string ad-hoc: `"Acceptance criteria: {AC from triage}"` — žádná validace, jestli AC vůbec existuje před spuštěním agenta
- `allowed-tools: mcp__*, Bash, Read, Write, Edit...` — reviewer (readonly) dostane stejné nástroje jako fixer (executor), bez jakékoli ochrany

### Navrhovaná architektura — 4 vrstvy

```
SKILL → PIPELINE DEFINITION → STEP DEFINITION → AGENT DEFINITION → TOOL NAMESPACES
```

**1. Agent interface** — přidá `interface:` blok do frontmatter s deklarací `inputs`, `outputs`, `tools` (abstraktní namespace), `role: readonly|executor`.

**2. Step definition** — samostatný soubor mapující pipeline state → agent inputs → pipeline state; definuje preconditions a flow control (`on: APPROVE → next: smoke-check`).

**3. Pipeline definition** — deklarativní YAML se state schemou, DAG závislostmi kroků a `tool_bindings`.

**4. Tool namespaces** — abstrakce nad konkrétními MCP servery. Agent volá `issue_tracker.read_issue()` a neví, zda je pod tím YouTrack, Jira nebo GitHub. Při přidání nového trackeru se mění jen binding v namespace souboru, ne 19 agentů.

### MCP a issue tracker jako konkrétní příklad

`allowed-tools: mcp__*` → nahrazeno průnikem `agent.interface.tools` × `step.tool_grants` → reviewer dostane pouze `mcp__github__get_issue`, nikdy `mcp__github__create_comment`. Agent deklaruje `issue_tracker.read_issue` (abstraktní), process resolver přeloží na konkrétní `mcp__jira__get_issue` podle konfigurace.

### Enforcement

- **Pre-flight validace** preconditions + tool availability před spuštěním každého agenta
- **Post-step validace** výstupu agenta proti output contract — místo křehkého `if output contains "## NEEDS_DECOMPOSITION"`
- **Tool set restriction** per krok — průnik deklarace agenta a povolení kroku

### Migrace

4 fáze, zpětně kompatibilní. Fáze 1 (přidat `interface:` anotace do frontmatter agentů) je bezriziková a přináší okamžitou hodnotu jako živá dokumentace API. Stávající `## Automation Config` formát v projektech zůstává beze změny ve všech fázích.

---

## 1. Proč oddělovat agenta od procesu

### 1.1 Co je špatně na současném modelu

Současná architektura mísí ve stejném souboru (a často ve stejné větě) dvě ortogonální odpovědnosti.

**Příklad — `agents/reviewer.md`:**

```markdown
### Reviewer Loop
This agent runs in an iterative loop with the fixer
(max iterations from Automation Config → Retry Limits → Fixer iterations, default 5).
```

Toto není schopnost agenta. Je to orchestrační logika procesu. Pokud se rozhodnu použít reviewer v jiném pipeline (scaffold review, PR review bez fixer loopu), musím tuto pasáž ignorovat nebo mazat.

**Příklad — `skills/fix-bugs/SKILL.md`:**

```markdown
Run `ceos-agents:fixer` (Task tool, model: opus).
Context: `Max build retries = {Build retries from config}. Block Comment Template: {template from plugin CLAUDE.md}. Acceptance criteria: {AC from triage}.`
```

Kontext je ad-hoc string. Není nikde deklarováno, že fixer **vyžaduje** `acceptance_criteria` jako vstup. Pokud triage nevyprodukuje AC (nebo pipeline triage přeskočí), fixer to nezjistí při startu — zjistí to až za běhu, nebo vůbec ne.

**Příklad — tool access:**

```yaml
allowed-tools: mcp__*, Bash, Read, Write, Edit, Glob, Grep, Task
```

Toto je monolitická sada nástrojů sdílená všemi agenty v skill. Reviewer (readonly agent) dostane stejný přístup jako fixer (executor). Neexistuje žádná ochrana proti tomu, aby reviewer omylem zapsal soubor — spoléháme jen na instrukci v přirozeném jazyce.

---

### 1.2 Konkrétní problémy a jejich dopad

| Problém | Dopad |
|---|---|
| Výstupní formát agenta je definován v přirozeném jazyce uvnitř Process sekce | Pipeline parsuje výstup křehkým string matchingem (`if output contains "## NEEDS_DECOMPOSITION"`) |
| Vstupní závislosti agenta nejsou deklarovány | Pipeline nemůže validovat, že agent dostane co potřebuje, před spuštěním |
| Tool access je monolitický per-skill | Readonly agent má stejné nástroje jako executor; nelze vynucovat read-only kontrakty |
| Každý agent zná typ issue trackeru | Při přidání nového trackeru je nutné upravit každého agenta, ne jen konfiguraci |
| Orchestrační logika (iterace, retry, skip) je v agent definici | Agent nelze reuse v jiném procesu bez ruční editace |
| Neexistuje typovaný pipeline state | Předávání dat mezi kroky je implicitní; nelze zjistit, zda krok X potřebuje výstup kroku Y |

---

### 1.3 Závěr — proč oddělovat

**Oddělení přináší:** kompozici bez editace, tool access control, testovatelnost v izolaci, snadnější reuse agentů napříč pipelines, jasnou hranici zodpovědnosti.

**Náklady:** refaktoring 19 agentů, přidání step souborů, nová vrstva abstrakce pro tools.

**Doporučení:** Oddělení je vhodné provést, ale postupně — nejprve přidat interface blok do frontmatter agentů (zpětně kompatibilní), poté extrahovat step definice, poté refaktoring tool access.

---

## 2. Navrhované rozhraní agenta

### 2.1 Rozšíření frontmatter

Stávající frontmatter: `name`, `description`, `model`, `style` — 4 pole, pouze metadata.

Navrhované rozšíření přidá sekci `interface:` s deklarací vstupů, výstupů, nástrojů a role:

```yaml
---
name: reviewer
version: "2.0.0"
description: Senior code reviewer and quality gate. Ensures root cause fix, convention compliance, no regressions. Read-only.
model: opus
style: Adversarial, evidence-driven, thorough

interface:
  role: readonly          # readonly | executor
                          # readonly: agent nesmí obdržet write tools
                          # executor: agent může modifikovat filesystem a state

  # Co agent POTŘEBUJE na vstupu
  inputs:
    code_diff:
      type: git.diff
      required: true
      description: "Diff všech změn vytvořených fixerem"
    acceptance_criteria:
      type: ac.list
      required: false
      description: "Seznam AC; pokud chybí, sekce AC Fulfillment se vynechá"
    issue_context:
      type: issue.ref
      required: false
      description: "Odkaz na původní issue pro kontext"
    iteration_number:
      type: integer
      required: false
      default: 1
    previous_review:
      type: review.report
      required: false
      description: "Výstup předchozí iterace review; povinné od iterace 2"

  # Co agent GARANTUJE na výstupu
  outputs:
    verdict:
      type: enum[APPROVE, REQUEST_CHANGES, BLOCK]
      required: true
    issues:
      type: review.issue[]
      required: true
      description: "Seznam nálezů se závažností a doporučením"
    ac_fulfillment:
      type: ac.fulfillment_report
      required: false
      condition: "when inputs.acceptance_criteria present"
    block_comment:
      type: pipeline.block_comment
      required: false
      condition: "when outputs.verdict == BLOCK"

  # Nástroje, které agent smí použít
  # Deklarovány jako abstraktní namespace — process resolves na konkrétní binding
  tools:
    source_control.read_file:    { required: true }
    source_control.read_diff:    { required: true }
    issue_tracker.read_issue:    { required: false }
    # Readonly agent: žádné write tools
---
```

### 2.2 Typový systém

Typy jsou logické kategorie, ne programovací typy — slouží jako dokumentace kontraktu a pre-flight hint.

| Typ | Popis | Příklad hodnoty |
|---|---|---|
| `git.diff` | Unified diff výstup | `"--- a/foo.ts\n+++ b/foo.ts\n@@ ..."` |
| `git.ref` | Commit hash nebo branch name | `"abc123"`, `"fix/PROJ-1"` |
| `issue.ref` | Odkaz na issue (ID + tracker type) | `{id: "PROJ-123", type: "github"}` |
| `ac.list` | Číslovaný seznam acceptance criteria | `["1. Login must succeed", "2. Token refreshed"]` |
| `ac.fulfillment_report` | Výsledek AC verifikace per-AC | `[{ac: "1. ...", verdict: "FULFILLED", evidence: "..."}]` |
| `review.report` | Plný výstup review agenta | Markdown blok `## Code Review` |
| `review.issue[]` | Pole review nálezů | `[{severity: "HIGH", description: "...", recommendation: "..."}]` |
| `pipeline.block_comment` | Strukturovaný block komentář | Markdown blok `[ceos-agents] 🔴 ...` |
| `triage.report` | Plný výstup triage agenta | Markdown blok `## Triage Analysis` |
| `fix.report` | Plný výstup fixer agenta | Markdown blok `## Fix Report` |
| `enum[...]` | Výčet povolených hodnot | `enum[APPROVE, REQUEST_CHANGES, BLOCK]` |
| `integer` | Celé číslo | `3` |
| `boolean` | Pravda/nepravda | `true` |
| `string` | Řetězec | `"PROJ-123"` |
| `T[]` | Pole hodnot typu T | `review.issue[]` |
| `T?` | Volitelná hodnota | `ac.list?` |

---

## 3. Navrhované rozhraní procesního kroku (Step)

Procesní krok odděluje *použití agenta v kontextu pipeline* od *definice agenta samotného*. Každý krok je samostatný soubor.

### 3.1 Adresářová struktura

```
steps/
  fix-bugs/
    01-triage.md
    02-code-analyst.md
    03-pre-fix-hook.md
    04-fixer.md
    05-build.md
    06-reviewer.md
    07-test-engineer.md
    08-acceptance-gate.md
    09-publisher.md
    XX-block-handler.md
  implement-feature/
    01-spec-analyst.md
    02-architect.md
    ...
  scaffold/
    ...
```

### 3.2 Step definice — příklad (reviewer krok v fix-bugs pipeline)

```yaml
---
step: review
pipeline: fix-bugs
phase: 6
agent: reviewer            # reference na agents/reviewer.md
description: "Adversarial code review s AC fulfillment verifikací"

# Preconditions — výrazy nad pipeline state
# Pipeline nespustí krok, pokud není splněna podmínka
preconditions:
  - "state.fixer.status == 'completed'"
  - "state.build.passed == true"

# Input mapping: pipeline state field → agent input name
# Každý klíč musí odpovídat deklarovanému inputu agenta
inputs:
  code_diff:           state.fixer.last_diff
  acceptance_criteria: state.triage.acceptance_criteria     # optional — agent si poradí bez
  issue_context:       state.issue
  iteration_number:    state.fixer_reviewer.iterations
  previous_review:     state.fixer_reviewer.last_review     # null v první iteraci

# Output mapping: agent output name → pipeline state field
outputs:
  state.review.verdict:        verdict
  state.review.issues:         issues
  state.review.ac_fulfillment: ac_fulfillment
  state.fixer_reviewer.last_review: $self   # celý výstup kroku

# Flow control — co se stane po dokončení kroku
on:
  APPROVE:
    next: smoke-check
  REQUEST_CHANGES:
    next: fixer
    guard:
      # Smyčka fixer↔reviewer má konfigurovatelný limit
      condition: "state.fixer_reviewer.iterations < config.retry.fixer_iterations"
      on_exceeded: block
  BLOCK:
    actions: [rollback, block-handler]

# Retry — reviewer se sám neopakuje (iterace jsou na úrovni fixer↔reviewer smyčky)
retry:
  max: 0

# Povinný krok — nelze přeskočit
skippable: false

# Nástroje povolené pro tento krok
# Resolver vezme deklaraci agenta + tuto sadu a vytvoří průnik
# (proces může dát agentu MÉNĚ nástrojů než deklaruje, nikdy VÍCE)
tool_grants:
  source_control.read_file: true
  source_control.read_diff:  true
  issue_tracker.read_issue:  true
  # issue_tracker.add_comment: false  — reviewer nesmí zapisovat do trackeru
---
```

### 3.3 Klíčové principy step definice

**Input mapping jako explicitní smlouva:** místo `Context: "Acceptance criteria: {AC from triage}"` (string interpolace) deklarujeme `code_diff: state.fixer.last_diff`. Pre-flight check může ověřit, zda `state.fixer.last_diff` existuje, *před* spuštěním agenta.

**`tool_grants` = intersection s deklarací agenta:** agent deklaruje co MŮŽE použít; krok deklaruje co SMÍ použít v tomto kontextu. Výsledek je průnik. Reviewer v bug-fix pipeline dostane `source_control.read_*` + `issue_tracker.read_issue`, ale nikdy `issue_tracker.add_comment` — i kdyby ho omylem zavolal.

**`on:` blok nahrazuje orchestrační věty v agent definici:** Věta "Iterations exhausted → proceed to Block handler" patří sem, ne do `agents/reviewer.md`.

---

## 4. Navrhované rozhraní pipeline (Process)

Pipeline definice popisuje sekvenci kroků, sdílený state schema, a konfiguraci. Nahrazuje monolitický skills soubor — skill zůstane jako entry point, ale deleguje na pipeline definici.

### 4.1 Pipeline definice

```yaml
---
name: fix-bugs
version: "2.0.0"
description: "Bug-fix pipeline: triage → analyst → fix → review → test → publish"
entry_skill: skills/fix-bugs/SKILL.md   # stávající skill je entry point

# Pipeline State Schema
# Typovaný sdílený kontext předávaný mezi kroky
# Persistence: .ceos-agents/{ISSUE-ID}/state.json (přes core/state-manager.md)
state:
  issue:          issue.ref               # required — nastaveno při spuštění
  triage:
    status:       enum[pending, completed, blocked, skipped]
    acceptance_criteria:  ac.list?
    complexity:   enum[XS, S, M, L]?
    severity:     enum[CRITICAL, HIGH, MEDIUM, LOW]?
    area:         string?
  code_analysis:
    status:       enum[pending, completed, blocked, skipped]
    affected_files: string[]?
    risk:         enum[LOW, MEDIUM, HIGH]?
    estimated_diff_lines: integer?
  fixer:
    status:       enum[pending, in_progress, completed, blocked]
    last_diff:    git.diff?
    needs_decomposition: boolean?
  fixer_reviewer:
    iterations:   integer                 # default: 0
    last_verdict: enum[APPROVE, REQUEST_CHANGES, BLOCK]?
    last_review:  review.report?
    ac_fulfillment: ac.fulfillment_report?
  build:
    passed:       boolean?
    attempts:     integer                 # default: 0
  review:
    verdict:      enum[APPROVE, REQUEST_CHANGES, BLOCK]?
    issues:       review.issue[]?
  test:
    status:       enum[pending, completed, blocked, skipped]
    attempts:     integer
  publisher:
    status:       enum[pending, completed]
    pr_url:       string?
    branch:       string?

# Stages — sekvence kroků s DAG závislostmi
stages:
  - id: triage
    step: steps/fix-bugs/01-triage.md
    parallel: true          # může běžet paralelně přes více issues
    skippable: true

  - id: code-analyst
    step: steps/fix-bugs/02-code-analyst.md
    parallel: true
    skippable: true
    depends_on: [triage]

  - id: pre-fix-hook
    step: steps/fix-bugs/03-pre-fix-hook.md
    skippable: true
    depends_on: [code-analyst]

  - id: fixer
    step: steps/fix-bugs/04-fixer.md
    skippable: false
    depends_on: [code-analyst]

  - id: build
    step: steps/fix-bugs/05-build.md
    skippable: false
    depends_on: [fixer]

  - id: reviewer
    step: steps/fix-bugs/06-reviewer.md
    skippable: false
    depends_on: [build]
    loop:
      with: fixer
      max: "config.retry.fixer_iterations"   # reference na Automation Config

  - id: test-engineer
    step: steps/fix-bugs/07-test-engineer.md
    skippable: true
    depends_on: [reviewer]

  - id: acceptance-gate
    step: steps/fix-bugs/08-acceptance-gate.md
    skippable: true
    depends_on: [reviewer]
    condition: "len(state.triage.acceptance_criteria) >= 3 OR state.triage.complexity IN ['M','L']"

  - id: publisher
    step: steps/fix-bugs/09-publisher.md
    skippable: false
    depends_on: [test-engineer, acceptance-gate]

# Tool namespace bindings
# Abstraktní namespace → konkrétní implementace
# Resolved z Automation Config při startu pipeline
tool_bindings:
  issue_tracker:    "mcp.{config.issue_tracker.type}"
                    # příklady: mcp.youtrack, mcp.github, mcp.jira, mcp.linear
  source_control:   "builtin.git"
  build_system:     "builtin.bash"
  browser:          "mcp.playwright"
  notification:     "builtin.curl"

# Pipeline Profiles
profiles:
  fast:
    skip: [code-analyst, test-engineer, e2e-test-engineer, reproducer, browser-verifier]
    description: "Rychlý fix bez analýzy a E2E; vhodné pro triviální bugy (XS)"
  paranoid:
    add: [e2e-test-engineer, browser-verifier]
    description: "Kompletní pipeline včetně E2E a browser verifikace"
  ci:
    skip: [triage]
    description: "Přeskočí triage — issue je již otriagovaný (CI triggered)"
---
```

---

## 5. Rozhraní externích nástrojů — Tool Namespace

Klíčová abstrakce, která odstraňuje coupling agentů na konkrétní MCP servery.

### 5.1 Problém stávajícího přístupu

Každý agent aktuálně provádí tuto logiku:

```markdown
Read the `Type` key to determine which MCP server to use (default: youtrack).
```

Toto znamená, že každý agent:
1. Musí vědět o Automation Config
2. Musí implementovat "překlad" type → MCP prefix
3. Musí být upraven při přidání nového trackeru

### 5.2 Navrhovaná abstrakce

**Tool namespace soubory** definují abstraktní API a jeho implementační bindingy:

```yaml
---
# tools/namespaces/issue_tracker.md
namespace: issue_tracker
version: "1.0.0"
description: "CRUD operace nad issue trackerem — tracker-agnostic abstrakce"

# Abstraktní metody namespace
methods:
  read_issue:
    description: "Načte issue detail včetně komentářů a příloh"
    inputs:
      issue_id: { type: string, required: true }
    outputs:
      title:       string
      description: string
      state:       string
      comments:    comment[]
      attachments: attachment[]
      custom_fields: map[string, any]

  add_comment:
    description: "Přidá komentář k issue"
    inputs:
      issue_id: { type: string, required: true }
      content:  { type: string, required: true }
    outputs:
      comment_id: string
      success:    boolean

  transition_state:
    description: "Přepne issue do nového stavu"
    inputs:
      issue_id:  { type: string, required: true }
      new_state: { type: string, required: true }
    outputs:
      success: boolean

  write_ac:
    description: "Zapíše strukturovaná AC zpět do issue (writeback)"
    inputs:
      issue_id:            { type: string, required: true }
      acceptance_criteria: { type: ac.list, required: true }
    outputs:
      success: boolean

  search_issues:
    description: "Vyhledá issues dle query"
    inputs:
      query:  { type: string, required: true }
      limit:  { type: integer, required: false, default: 10 }
    outputs:
      issues: issue.ref[]

  close_as_duplicate:
    description: "Zavře issue jako duplikát a přidá odkaz na originál"
    inputs:
      issue_id:    { type: string, required: true }
      original_id: { type: string, required: true }
    outputs:
      success: boolean

# Implementační bindingy per tracker type
# Každý binding mapuje abstraktní metodu na konkrétní MCP tool call
implementations:
  youtrack:
    tool_prefix: "mcp__youtrack__"
    method_map:
      read_issue:         "get_issue"
      add_comment:        "create_comment"
      transition_state:   "update_issue_state"
      write_ac:           "update_issue_custom_field"   # AC jako custom field
      search_issues:      "search_issues"
      close_as_duplicate: "update_issue"

  github:
    tool_prefix: "mcp__github__"
    method_map:
      read_issue:         "get_issue"
      add_comment:        "create_issue_comment"
      transition_state:   "update_issue"    # state přes labels nebo close
      write_ac:           "create_issue_comment"   # AC jako komentář (GitHub nemá custom fields)
      search_issues:      "search_issues"
      close_as_duplicate: "update_issue"

  jira:
    tool_prefix: "mcp__jira__"
    method_map:
      read_issue:         "get_issue"
      add_comment:        "add_comment"
      transition_state:   "transition_issue"
      write_ac:           "update_issue"
      search_issues:      "search_issues"
      close_as_duplicate: "transition_issue"

  linear:
    tool_prefix: "mcp__linear__"
    method_map:
      read_issue:         "getIssue"
      add_comment:        "createComment"
      transition_state:   "updateIssue"
      write_ac:           "createComment"
      search_issues:      "searchIssues"
      close_as_duplicate: "updateIssue"
---
```

Analogicky pro `source_control`, `browser`, `build_system`, `notification`:

```yaml
---
# tools/namespaces/source_control.md
namespace: source_control

methods:
  read_file:     { inputs: {path: string}, outputs: {content: string} }
  read_diff:     { inputs: {from: git.ref, to: git.ref?}, outputs: {diff: git.diff} }
  create_branch: { inputs: {name: string, base: git.ref}, outputs: {success: boolean} }
  commit:        { inputs: {message: string, files: string[]}, outputs: {hash: git.ref} }
  push:          { inputs: {branch: string, remote: string}, outputs: {success: boolean} }
  create_pr:     { inputs: {title: string, body: string, base: string, labels: string[]}, outputs: {pr_url: string} }
  revert:        { inputs: {to_ref: git.ref}, outputs: {success: boolean} }

implementations:
  git:
    tool_prefix: "builtin.bash"
    method_map:
      read_file:     "cat {path}"
      read_diff:     "git diff {from} {to}"
      create_branch: "git checkout -b {name} {base}"
      commit:        "git commit -m {message}"
      push:          "git push -u origin {branch}"
      revert:        "git reset --hard {to_ref}"
      create_pr:     "mcp.github/create_pull_request | mcp.gitea/create_pull_request | gh pr create"
---
```

### 5.3 Výhody tool namespace abstrakce

| Před abstrakcí | Po abstrakci |
|---|---|
| Agent: "Read Type from Automation Config, use mcp__youtrack__* or mcp__github__*..." | Agent: `tools: [issue_tracker.read_issue]` |
| Přidání nového trackeru = editace každého agenta | Přidání = nový binding v issue_tracker namespace |
| Reviewer může zavolat issue_tracker.add_comment (není blokováno) | `tool_grants` v step definici odřízne add_comment pro readonly krok |
| MCP preflight ověřuje dostupnost pro celý pipeline | Preflight ověřuje dostupnost per-agent (jen tools deklarované v interface) |
| Nelze testovat agenta bez živého MCP serveru | Mock binding v tool namespace → testovatelnost bez MCP |

---

## 6. Enforcement mechanismy

V kontextu Claude Code pluginu (LLM interpretuje markdown) existují čtyři praktické vrstvy enforcement.

### 6.1 Pre-flight validace (před spuštěním kroku)

Skill (process orchestrátor) provede před voláním Task:

```markdown
Pre-flight check for step `review`:
1. Verify preconditions:
   - state.fixer.status == 'completed' → OK / FAIL
   - state.build.passed == true → OK / FAIL
2. Verify required inputs exist in pipeline state:
   - state.fixer.last_diff (required for code_diff) → present / MISSING
3. Verify tool availability:
   - issue_tracker.read_issue → resolve binding → check mcp__github__get_issue accessible
4. If any check fails → Block with descriptive error before dispatching agent
```

Toto nahrazuje implicitní předpoklady v skill próze. Místo "dostane kontext pokud existuje" dostaneme explicitní selhání s popisem co chybí.

### 6.2 Tool set restriction (při dispatchování agenta)

Skill předá `allowed-tools` derivovaný z průniku agent interface + step tool_grants (místo monolitického `mcp__*, Bash, Read, Write, Edit, Glob, Grep`):

```markdown
# Stávající (příliš permisivní)
allowed-tools: mcp__*, Bash, Read, Write, Edit, Glob, Grep, Task

# Navrhované (per agent, derived from interface + tool_grants)
# Pro reviewer krok:
allowed-tools: Read, Glob, Grep, mcp__github__get_issue, mcp__github__get_pull_request
# Bez: Bash, Write, Edit, mcp__github__create_comment, mcp__github__update_issue
```

V praxi: skill vygeneruje allowed-tools string z tool_grants a tool_bindings resolutionu.

### 6.3 Output schema validace (po dokončení agenta)

Skill validuje výstup agenta proti deklarovanému output contract před zápisem do pipeline state:

```markdown
Post-step validation for `review`:
1. Parse agent output for required fields:
   - verdict: found "APPROVE" → valid enum value ✓
   - issues: found "## Code Review ... 1. [HIGH]..." → present ✓
2. If verdict == BLOCK:
   - block_comment: required → check present ✓
3. Write to pipeline state:
   - state.review.verdict = "APPROVE"
   - state.review.issues = [parsed issues]
```

Toto nahrazuje ad-hoc string matching (`if output contains "## NEEDS_DECOMPOSITION"`). Output contract definuje přesně jaká struktura se hledá.

### 6.4 State schema validace (průběžná)

Core `state-manager.md` validuje při každém zápisu do state.json, že field_path odpovídá deklarovanému pipeline state schema. Neznámé pole → varování, zápis povolen (forward compatibility).

---

## 7. Kompozice pipeline ze stavebnic

Cílem oddělení je, aby bylo možné sestavit nový pipeline ze stávajících agent+step definic bez psaní nového kódu.

### 7.1 Příklad — "lightweight PR review" pipeline

Nová pipeline sestavená ze stávajících komponent:

```yaml
---
name: pr-review
version: "1.0.0"
description: "Lightweight pipeline pro review existujícího PR (bez fixu)"

stages:
  - id: reviewer
    step: steps/fix-bugs/06-reviewer.md    # reuse stávajícího step
    # reviewer krok dostane jiný input mapping:
    input_override:
      code_diff: state.pr.diff             # z PR, ne z fixer output
      issue_context: state.pr.linked_issue # z PR description
    skippable: false

  - id: test-engineer
    step: steps/fix-bugs/07-test-engineer.md   # reuse bez modifikace
    skippable: true

tool_bindings:
  source_control: "mcp.github"
  issue_tracker:  "mcp.{config.issue_tracker.type}"
---
```

Oba agenti (`reviewer`, `test-engineer`) jsou reusovány bez editace jejich definic. Jen vstupní mapping se liší.

### 7.2 Příklad — přidání custom agenta do pipeline

Stávající mechanismus custom agents (Post-fix agent, Pre-publish agent) je ad-hoc. S formálním step interface lze custom agenty přidat deklarativně:

```yaml
# V Automation Config (CLAUDE.md), místo stávajícího textu:
# | Post-fix agent | customization/security-scanner.md |

# Navrhovaná forma v pipeline steps:
stages:
  - id: security-scanner
    step: customization/steps/security-scanner.md   # projekt-specifický step
    after: build                                     # vložení za konkrétní krok
    skippable: true
```

### 7.3 Příklad — agent reuse napříč pipelines

| Agent | fix-bugs pipeline | implement-feature pipeline | pr-review pipeline |
|---|---|---|---|
| `triage-analyst` | step 1 | ✗ (spec-analyst místo) | ✗ |
| `code-analyst` | step 2 | step 2 | ✗ |
| `fixer` | step 4 | step 3 | ✗ |
| `reviewer` | step 6 | step 4 | step 1 ✓ reuse |
| `test-engineer` | step 7 | step 5 | step 2 ✓ reuse |
| `acceptance-gate` | step 8 | step 6 | ✗ |
| `publisher` | step 9 | step 7 | ✓ reuse |

Reuse je bezproblémový, protože krok definuje input mapping specifický pro pipeline, agent definice zůstává nezměněna.

---

## 8. Praktické příklady tool namespace v akci

### 8.1 MCP issue tracker — triage-analyst před a po

**Před (stávající `agents/triage-analyst.md`):**
```markdown
Read bug details from issue tracker (summary, description, comments, custom fields).
Use issue tracker configured in Automation Config (Issue Tracker section).
Read the `Type` key to determine which MCP server to use (default: youtrack).
```

**Po (navrhovaný):**
```yaml
# V agent interface:
tools:
  issue_tracker.read_issue:    { required: true }
  issue_tracker.add_comment:   { required: true }   # pro checkpoint komentář
  issue_tracker.write_ac:      { required: true }   # pro AC writeback
  issue_tracker.search_issues: { required: true }   # pro duplicate detection
  issue_tracker.close_as_duplicate: { required: false }
```

```markdown
# V agent Process sekci (zjednodušeno):
1. Call `issue_tracker.read_issue(issue_id)` to get full issue detail.
2. Call `issue_tracker.search_issues(query)` to detect duplicates.
3. ...
10. Call `issue_tracker.add_comment(issue_id, checkpoint_comment)`.
```

Agent nezná tracker type. Process resolver zajistil, že `issue_tracker.*` je namapováno na `mcp__github__*` (nebo `mcp__jira__*` atd.) na základě konfigurace.

### 8.2 MCP playwright — browser-verifier

```yaml
# tools/namespaces/browser.md
namespace: browser
methods:
  navigate:    { inputs: {url: string}, outputs: {success: boolean} }
  click:       { inputs: {selector: string}, outputs: {success: boolean} }
  fill:        { inputs: {selector: string, value: string}, outputs: {success: boolean} }
  screenshot:  { inputs: {path: string}, outputs: {path: string} }
  get_console: { outputs: {entries: console_entry[]} }
  get_errors:  { outputs: {errors: network_error[]} }

implementations:
  playwright:
    tool_prefix: "mcp__playwright__"
    method_map:
      navigate:    "navigate"
      click:       "click"
      fill:        "fill"
      screenshot:  "screenshot"
      get_console: "console"
      get_errors:  "network"
```

`browser-verifier` agent deklaruje:
```yaml
tools:
  browser.navigate:    { required: true }
  browser.click:       { required: true }
  browser.screenshot:  { required: true }
  browser.get_console: { required: true }
  browser.get_errors:  { required: true }
```

Pokud se změní MCP playwright na jiný browser automation tool (např. `mcp__puppeteer__*`), stačí změnit binding v `browser` namespace. Agent definice zůstane nedotčena.

### 8.3 Build system — fixer a test-engineer

```yaml
# tools/namespaces/build_system.md
namespace: build_system
methods:
  build:     { inputs: {command: string}, outputs: {success: boolean, output: string} }
  test:      { inputs: {command: string}, outputs: {success: boolean, output: string, failures: test_failure[]} }
  run:       { inputs: {command: string}, outputs: {exit_code: integer, stdout: string, stderr: string} }

implementations:
  bash:
    tool_prefix: "builtin.bash"
    # Všechny metody mapují na Bash tool s daným příkazem
```

`fixer` deklaruje:
```yaml
tools:
  source_control.read_file:  { required: true }
  build_system.build:        { required: true }
  build_system.test:         { required: true }
  build_system.run:          { required: false }   # pro custom verifikaci
```

`reviewer` NEdeklaruje `build_system.*` — readonly agent nemůže spouštět buildy.

### 8.4 Notification webhook

```yaml
# tools/namespaces/notification.md
namespace: notification
methods:
  send_webhook:
    inputs:
      url:     { type: string, required: true }
      payload: { type: object, required: true }
    outputs:
      success: boolean
      http_status: integer

implementations:
  curl:
    tool_prefix: "builtin.bash"
    template: |
      curl --max-time 5 --retry 0 -X POST -H "Content-Type: application/json" \
        -d '{payload_json}' '{url}'
```

Pipeline (nikoliv agent!) volá `notification.send_webhook` v post-publish hook. Agenti notifikace neposílají přímo.

---

## 9. Migrační strategie

Oddělení agent definic od process definic je rozsáhlá změna. Navrhovaný přístup je postupný a zpětně kompatibilní.

### 9.1 Fáze 1 — Interface anotace (zpětně kompatibilní, ~2 týdny)

Přidat `interface:` sekci do frontmatter všech 19 agentů. Stávající markdown body zůstane beze změny.

Dopady:
- Skills se nemění
- Pre-flight check v skill může volitelně číst interface sekci pro validaci
- Žádný breaking change

Deliverable: 19 agentů s `interface:` anotací

### 9.2 Fáze 2 — Tool namespace definice (~1 týden)

Vytvořit `tools/namespaces/` adresář s namespace soubory pro:
- `issue_tracker` (6 trackerů)
- `source_control` (git + MCP github/gitea)
- `build_system` (bash)
- `browser` (playwright)
- `notification` (curl webhook)

Dopady:
- Agenti se nemusí měnit (namespace existuje, ale není enforcement)
- Dokumentace nyní přesně popisuje co který agent potřebuje

Deliverable: 5 namespace souborů

### 9.3 Fáze 3 — Step extrakce pro fix-bugs (~2 týdny)

Extraovat 9 step souborů pro fix-bugs pipeline z `skills/fix-bugs/SKILL.md`.
Skill se stane thin orchestrátorem, který:
1. Čte pipeline definici
2. Pro každý krok: validuje preconditions, resolves tools, dispatches agent, validates outputs

Dopady:
- SKILL.md se zkrátí na ~50 řádků orchestrace + import pipeline definice
- Step soubory jsou reusovatelné pro jiné pipelines
- BREAKING: skills musí být aktualizovány

Deliverable: 9 step souborů + refaktorovaný SKILL.md

### 9.4 Fáze 4 — Tool enforcement (~1 týden)

Skill generuje `allowed-tools` dynamicky z průniku agent interface + step tool_grants + tool_bindings resolution.

Dopady:
- Reviewer fyzicky nedostane write tools
- Testovatelnost bez živého MCP serveru (mock bindings)

Deliverable: tool resolver v `core/tool-resolver.md`

### 9.5 Přehled vrstev po dokončení migrace

```
┌─────────────────────────────────────────────────────────────┐
│ SKILL (entry point)                                         │
│ - parsuje argumenty, čte Automation Config                  │
│ - importuje pipeline definici                               │
│ - volá process orchestrátor                                 │
└─────────────────┬───────────────────────────────────────────┘
                  │
┌─────────────────▼───────────────────────────────────────────┐
│ PIPELINE DEFINITION (process/*.md)                          │
│ - state schema, stages, tool_bindings, profiles             │
│ - deklarativní — žádná imperative logika                    │
└─────────────────┬───────────────────────────────────────────┘
                  │  pro každý stage
┌─────────────────▼───────────────────────────────────────────┐
│ STEP DEFINITION (steps/{pipeline}/{N}-{name}.md)            │
│ - agent reference, input/output mapping                     │
│ - preconditions, flow control, tool_grants                  │
└─────────────────┬───────────────────────────────────────────┘
                  │  resolves agent interface
┌─────────────────▼───────────────────────────────────────────┐
│ AGENT DEFINITION (agents/{name}.md)                         │
│ - interface: inputs, outputs, tools (abstraktní)            │
│ - role: readonly | executor                                 │
│ - Goal, Expertise, Process, Constraints (beze změny)        │
└─────────────────┬───────────────────────────────────────────┘
                  │  resolves tool namespaces
┌─────────────────▼───────────────────────────────────────────┐
│ TOOL NAMESPACES (tools/namespaces/{namespace}.md)           │
│ - abstraktní metody namespace                               │
│ - implementační bindingy per konfigurace                    │
│ - příklady: issue_tracker, source_control, browser          │
└─────────────────────────────────────────────────────────────┘
```

---

## 10. Co tato architektura umožňuje navíc

Po dokončení migrace vznikne infrastruktura pro funkce, které jsou v stávajícím modelu obtížné nebo nemožné:

| Funkce | Mechanismus |
|---|---|
| **Testování agenta v izolaci** | Mock tool_bindings + mock pipeline state → agent dostane fake inputs, výstup se validuje proti output contract |
| **Dry-run s validací** | Pre-flight ověří všechny preconditions + tool availability bez spuštění agenta |
| **Automatická dokumentace API** | Z interface sekcí lze generovat reference dokumentaci |
| **Versioning agentů** | `agent: reviewer@^2.0.0` v step definici → explicitní kompatibilita |
| **Multi-tracker pipeline v jednom běhu** | Různé steps mohou mít různé tool_bindings (jedna pipeline zpracovává GitHub + Jira issues současně) |
| **Custom pipeline jako first-class citizen** | Projekt může definovat vlastní pipeline soubor odkazující na stávající steps + vlastní custom steps |
| **Pipeline jako kód (pipeline-as-code)** | Pipeline definice je YAML → verzovatelná, diffovatelná, code-reviewovatelná |
| **Metrics per tool namespace** | Sledovat kolikrát `issue_tracker.add_comment` selhalo napříč runs |

---

## 11. Technology Profiles — znalost stacku jako samostatná vrstva

### 11.1 Kde technologie v současném modelu žije — a proč je to problém

Analýza stávajících agentů odhaluje tři místa, kde je knowledge o tech stacku baked-in, všechna tří problematická:

**Místo 1 — přirozený jazyk uvnitř agent definice (`test-engineer.md`):**
```markdown
If no existing tests exist: create the test file following language conventions
(e.g., `tests/test_{module}.py` for Python, `{module}.test.ts` for TypeScript)
```
Každý agent zná pár stacků jako příklady. Při přidání nového jazyka (Rust, Kotlin, Swift) je nutné editovat každého agenta.

**Místo 2 — gigantické podmíněné bloky v jednom agentovi (`scaffolder.md`):**
```markdown
For JS/TS stacks: playwright.config.ts with baseURL...
For Python stacks: pytest-playwright configuration in conftest.py...
For Ruby stacks: capybara-playwright-driver in spec/support/capybara.rb...
For Java stacks: com.microsoft.playwright in pom.xml...
For .NET stacks: Microsoft.Playwright.NUnit in *.csproj...
For Go stacks: playwright-go in go.mod...
```
Scaffolder.md je ~210 řádků. Polovina jsou `if language == X` větve. Přidání nového stacku = editace agenta. Agentní definice a stack-specifická logika jsou nerozeznatelné.

**Místo 3 — implicitní v tréninkových datech LLM:**
Agenti prostě "vědí" Python, TypeScript, .NET — ale tato znalost není deklarována, není verzována, není testovatelná.

---

### 11.2 Tři dimenze technologie — nutno oddělit

Stávající model tyto tři věci mísí. Jsou to fundamentálně odlišné kategorie:

| Dimenze | Co to je | Kde by mělo žít |
|---|---|---|
| **Příkazy** | Jak spustit build, test, lint | `tool_namespace.build_system` + Automation Config |
| **Konvence** | Kde jsou soubory, jak se jmenují, jaká je struktura projektu | **Technology Profile** (nová vrstva) |
| **Expert patterns** | Jazykové idiomy, framework patterns, anti-patterny, časté bugy | **Technology Profile** (nová vrstva) |
| **Projektové přizpůsobení** | Specifická pravidla daného projektu | Agent Overrides v CLAUDE.md (stávající) |

`tool_namespace.build_system` řeší dimenzi 1 (`pytest` vs `dotnet test` vs `npm test`).
**Technology Profile** řeší dimenze 2 a 3.
Agent Overrides řeší dimenzi 4.

---

### 11.3 Technology Profile — navrhovaný formát

Technology Profile je strukturovaný dokument injektovaný do agenta procesem na základě tech stacku projektu. Agent sám neví, na jakém stacku pracuje — dozvídá se to až z profilu.

```yaml
---
# tech-profiles/python-fastapi.md
profile: python-fastapi
version: "3.11+"
base: python          # dědí z base profilu — Python conventions jsou sdílené
extends: [fastapi]    # framework-level nadstavba

# Projektová struktura — konvence
structure:
  source_root: "src/{package_name}/"
  test_root: "tests/"
  test_file_pattern: "test_{module}.py"
  test_naming: "def test_{behavior}_{scenario}():"
  entry_point: "src/{package_name}/main.py"
  config_file: "pyproject.toml"

# Testovací ekosystém
testing:
  framework: pytest
  runner: "pytest {test_root} -v"
  fixture_style: "conftest.py"
  mock_library: "pytest-mock (mocker fixture)"
  coverage: "pytest-cov"
  patterns:
    - "Arrange-Act-Assert v každém testu"
    - "Fixtures pro sdílený stav, ne setUp/tearDown"
    - "pytest.raises() pro exception testing"
    - "parametrize pro data-driven testy"
  anti_patterns:
    - "unittest.TestCase — nepoužívat v pytest projektech"
    - "assertRaises — preferovat pytest.raises"
    - "Globální stav v testech — izolovat pomocí fixtures"

# Jazykové konvence
conventions:
  style: "PEP 8 + Black (line-length: 88)"
  types: "Strict mypy, no implicit Any, all public functions annotated"
  imports: "isort, absolute imports, stdlib → third-party → local"
  async: "asyncio, async def pro FastAPI endpoints, await pro async calls"
  null_handling: "Optional[T] s is None check, ne == None"

# FastAPI-specifické patterns
framework_patterns:
  routing: "APIRouter s prefix a tags, ne přímé přidání na app"
  dependency_injection: "Depends() pro sdílené závislosti (DB session, auth)"
  validation: "Pydantic models pro request/response, Field() pro validaci"
  error_handling: "HTTPException pro client errors, middleware pro server errors"
  testing: "TestClient z httpx, dependency_overrides pro mock DI"

# Časté bugy v tomto stacku
common_bugs:
  - "Mutable default arguments: `def foo(x: list = [])` — použít `= None` + inicializace v těle"
  - "Late binding v lambda/closure uvnitř smyčky — použít `default=val`"
  - "asyncio.run() uvnitř existujícího event loop (FastAPI) — použít `await`"
  - "Zapomenutý `await` na async funkci — vrátí coroutine object, ne výsledek"
  - "N+1 query v ORM — použít eager loading nebo joinedload"

# Fix patterns — jak správně opravit typické problémy
fix_patterns:
  add_endpoint: |
    @router.post("/path", response_model=ResponseSchema, status_code=201)
    async def create_item(data: RequestSchema, db: Session = Depends(get_db)):
        ...
  mock_dependency: |
    app.dependency_overrides[get_db] = lambda: mock_db
    # cleanup: app.dependency_overrides.clear()
---
```

Base profil (`python.md`) obsahuje obecné Python konvence sdílené přes všechny frameworky. Framework profil (`fastapi.md`) rozšiřuje base pouze o framework-specifické věci.

---

### 11.4 Kompozice profilů

Profily jsou kompozitní — project nemusí vybírat jen jeden.

```
Base language          Framework              Project specifics
─────────────────      ─────────────────      ────────────────────────
python.md          +   fastapi.md         +   Agent Overrides (CLAUDE.md)
typescript.md      +   react.md           +   Agent Overrides
dotnet.md          +   aspnet-core.md     +   Agent Overrides
go.md              +   gin.md             +   Agent Overrides
java.md            +   spring-boot.md     +   Agent Overrides
```

Výsledný "kontext profilu" injektovaný do agenta je konkatenace relevantních sekcí — od base profilu po projektové přizpůsobení.

---

### 11.5 Jak profil dostane agent — injekce procesem

Agent **nedeklaruje** konkrétní tech stack. Deklaruje pouze potřebu kontextu:

```yaml
# V agent interface (v frontmatter):
interface:
  tech_profile:
    required: true   # agent MUSÍ dostat tech profile — nemůže pracovat bez znalosti stacku
    # příklady agentů s required: fixer, test-engineer, scaffolder, reviewer
    # příklady agentů bez: triage-analyst, publisher, rollback-agent (stack-agnostic)
```

Step definice zajistí injekci:

```yaml
# V step definici:
inputs:
  tech_profile: state.project.tech_profile    # načteno z Automation Config při startu pipeline

# Automation Config v CLAUDE.md projektu:
# | Tech stack | python-fastapi |   ← přidání nového klíče
```

Pipeline při startu:
1. Přečte `Tech stack` z Automation Config
2. Načte `tech-profiles/{stack}.md` (base + framework)
3. Uloží do `state.project.tech_profile`
4. Každý krok, jehož agent má `tech_profile: required`, dostane profil jako vstup

---

### 11.6 Agent je stack-agnostický — profil dodává kontext

Klíčový princip: agent nezná Python. Agent umí **aplikovat proces** (opravit bug, napsat test). Profil mu dodá kontext, aby to dělal správně pro daný stack.

**`test-engineer.md` před:**
```markdown
If no existing tests exist: create the test file following language conventions
(e.g., `tests/test_{module}.py` for Python, `{module}.test.ts` for TypeScript)
```

**`test-engineer.md` po:**
```markdown
4. Write new tests:
   - Follow Arrange-Act-Assert pattern
   - Follow conventions from tech_profile:
     - test_root: {tech_profile.structure.test_root}
     - test_file_pattern: {tech_profile.structure.test_file_pattern}
     - test_naming: {tech_profile.structure.test_naming}
     - framework patterns: {tech_profile.testing.patterns}
   - Avoid anti-patterns listed in tech_profile.testing.anti_patterns
```

Agent je teď stack-agnostický. Přidání podpory pro Rust nevyžaduje editaci agent definice — stačí vytvořit `tech-profiles/rust.md`.

---

### 11.7 Scaffolder — speciální případ (šablony vs. profily)

Scaffolder je výjimka, která vyžaduje jiný přístup.

**Problém:** Scaffolder nemá jen *konvence* — má jiný *proces* per stack. Pro Python generuje `pyproject.toml + conftest.py`, pro TypeScript `package.json + jest.config.ts`, pro .NET `*.csproj + xunit`. Toto nejde vyřešit profily — profil říká *co* generovat, ne *jak* to vygenerovat strukturálně.

**Správný přístup pro scaffolder: Stack Templates**

```
tech-templates/
  python-fastapi/
    pyproject.toml.tmpl
    src/__init__.py.tmpl
    tests/conftest.py.tmpl
    Dockerfile.tmpl
    .github/workflows/ci.yml.tmpl
    CLAUDE.md.tmpl
  typescript-react/
    package.json.tmpl
    tsconfig.json.tmpl
    src/main.tsx.tmpl
    ...
  dotnet-aspnet/
    App.csproj.tmpl
    Program.cs.tmpl
    ...
```

Scaffolder agent se pak stane **template engine**:
1. Čte `tech_profile` → ví jaký stack
2. Načte `tech-templates/{stack}/` → ví jaké soubory generovat a jakou šablonu použít
3. Instantiates šablony s hodnotami z spec + Automation Config
4. Ověří výsledek (build, test, lint)

**Výhody:**
- Přidání nového stacku = nový adresář v `tech-templates/`, agent se nemění
- Šablony jsou verzovatelné, diffovatelné, code-reviewovatelné
- Scaffolder.md klesne z ~210 řádků podmíněné logiky na ~60 řádků čistého procesu

---

### 11.8 Přehled vrstev po přidání Technology Profiles

```
┌─────────────────────────────────────────────────────────────────────────┐
│ PIPELINE STATE                                                          │
│   state.project.tech_profile = python-fastapi (načteno ze stacku)      │
└────────────────────────────────────┬────────────────────────────────────┘
                                     │  injektováno do každého kroku
         ┌───────────────────────────┼─────────────────────────┐
         │                           │                         │
┌────────▼──────────┐   ┌────────────▼──────────┐   ┌─────────▼─────────┐
│ TOOL NAMESPACES   │   │ TECHNOLOGY PROFILES   │   │ AGENT OVERRIDES   │
│                   │   │                       │   │                   │
│ issue_tracker.*   │   │ tech-profiles/        │   │ customization/    │
│ source_control.*  │   │   python.md           │   │   fixer.md        │
│ build_system.*    │   │   python-fastapi.md   │   │   reviewer.md     │
│ browser.*         │   │   typescript.md       │   │                   │
│                   │   │   react.md            │   │ (projekt-spec.    │
│ (řeší: KDE a JAK │   │                       │   │ přizpůsobení)     │
│ zavolat ext. API) │   │ (řeší: JAKÝ kód      │   │                   │
│                   │   │ je správný pro stack) │   │                   │
└───────────────────┘   └───────────────────────┘   └───────────────────┘
         │                           │                         │
         └───────────────────────────┴─────────────────────────┘
                                     │  vše injektováno do
┌────────────────────────────────────▼────────────────────────────────────┐
│ AGENT (stack-agnostický)                                                │
│   interface.tools: [build_system.test, source_control.read_file]        │
│   interface.tech_profile: required                                      │
│   Goal / Expertise / Process / Constraints — beze změny při +stack     │
└─────────────────────────────────────────────────────────────────────────┘
```

---

### 11.9 Proč NE: agent jako specialista per stack

Alternativa — specializované agenty (`fixer-python.md`, `fixer-typescript.md`) — je anti-pattern z těchto důvodů:

| Kritérium | Generic agent + profile | Specialized agent per stack |
|---|---|---|
| Přidání nového stacku | Nový profil soubor | N nových agentů (fixer + test-engineer + reviewer + ...) |
| Oprava procesu (např. nové pravidlo review) | Editace 1 agenta | Editace N agentů |
| Konzistence procesu napříč stacky | Garantována (jeden zdrojový agent) | Nemůže být garantována |
| Počet souborů pro 10 stacků + 8 agentů | 8 agentů + 10 profilů = 18 souborů | 80 souborů |
| Testovatelnost | Agent testován jednou, profily samostatně | Každá kombinace testována zvlášť |

Specializace na úrovni **profilu** je správná. Specializace na úrovni **agenta** je kvadratická škálovací past.

---

## 13. Otevřené otázky

1. **Kde jsou uloženy step definice?** Navrhováno `steps/{pipeline-name}/` v pluginu. Projekty mohou mít `customization/steps/` pro override (analogicky k agent overrides).

2. **Jak je tool resolver implementován?** Jako `core/tool-resolver.md` — dokument popisující algoritmus resolutionu abstraktního namespace na konkrétní allowed-tools string. LLM ho čte a aplikuje při sestavování Task callů.

3. **Zpětná kompatibilita stávajícího CLAUDE.md formátu?** Fáze 1–2 jsou čistě additive. Fáze 3 mění interní strukturu skills, ale `## Automation Config` formát v projektech zůstává beze změny.

4. **Jak řešit agenta, jehož výstup neodpovídá deklarovanému output contractu?** Post-step validace zaznamená nesoulad do pipeline.log, pokusí se parsovat best-effort, a pokud klíčové pole chybí, zahájí Block handler. Soft failure pro nepovinná pole.

5. **Má smysl definovat tool namespace pro `builtin.bash`?** Ano — explicitní deklarace `build_system.build: {required: true}` je cennější než implicitní předpoklad, že Bash je dostupný. Pre-flight může ověřit konfiguraci Build command.
