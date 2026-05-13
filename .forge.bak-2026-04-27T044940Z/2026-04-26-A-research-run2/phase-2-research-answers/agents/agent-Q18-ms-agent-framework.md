# Q18 — Microsoft Agent Framework + Magentic-One: Hluboká analýza

**Datum:** 2026-04-26
**Run:** 2 (deep-dive)
**Framework:** Microsoft Agent Framework 1.0 GA + Magentic-One
**Primary lens:** vendor (Microsoft devblogs, MS Learn, docs.microsoft.com)
**Secondary lens:** OSS code (`microsoft/agent-framework` GitHub)
**Cílový výstup:** vstup do Q22 cross-run synthesis + A.1 brainstorm

---

## Executive Summary

Microsoft Agent Framework (dále "MAF") dosáhlo 1.0 GA 2026-04-03. Je to produkční sjednocení AutoGen (odchod do maintenance módu) a Semantic Kernel (1.0 Oct 2025). Framework nabízí **dva ortogonální přístupy**: (a) programatický graph-based workflow engine (primární surface, stabilní v 1.0) a (b) declarative YAML agents + workflows (alternativní surface, **stále ve `--prerelease` NuGet stavu** ke dni 1.0 GA). Toto je klíčové rozlišení pro řešení Anomaly 7 z Run 1.

Magentic-One je **1 Orchestrator + 4 specialists** (WebSurfer, FileSurfer, Coder, ComputerTerminal), implementován jako orchestration pattern uvnitř MAF — nikoliv standalone framework. Dual-ledger architektura (task ledger + progress ledger) je patrně nejrelevantnější vzor pro ceos-agents stateful pipelines. Optional Plan Review (HITL gate po plánování, před exekucí) je dokumentovaná a funkční feature od 2026-03.

---

## Lens Disclosure

- **Vendor primary:** devblogs.microsoft.com/agent-framework, learn.microsoft.com/en-us/agent-framework, devblogs.microsoft.com/foundry
- **OSS code secondary:** `github.com/microsoft/agent-framework` (directory listing, declarative-agents/workflow-samples/CustomerSupport.yaml, python samples)
- **Academic tertiary:** arxiv.org/abs/2411.04468 (Magentic-One paper, Fourney et al., Nov 2024)
- **No inference** — každý claim níže má citaci na konkrétní zdroj

---

## Dimenze 1: Granularita agentů

### Magentic-One: 1 Orchestrator + 4 Specialists

Magentic-One obsahuje přesně **5 agentů** — ověřeno z arxiv 2411.04468v1 (Fourney et al. 2024):

- **Orchestrator** — plánuje, přiřazuje úkoly, detekuje stall, syntezizuje výsledky
- **WebSurfer** — browser navigace a webová interakce
- **FileSurfer** — čtení filesystému a dokumentů
- **Coder** — generování a analýza kódu
- **ComputerTerminal** — exekuce kódu a shell příkazy

(Run 1 uvádí "1 Orchestrator + 4 specialists" — verifikováno jako správné. Kompozice: WebSurfer, FileSurfer, Coder, ComputerTerminal.)

### MAF "Hello World" minimalistický přístup

Run 1 citoval pozorování agentů jako `"You are a friendly assistant. Keep your answers brief"` (hello-world). MS Learn declarative agents doc (learn.microsoft.com, updated 2026-04-02) potvrzuje: declarative agent YAML `kind: Prompt` definice obsahuje pouze `name`, `description`, `instructions`, `model` — velmi plochá struktura, žádné Process/Constraints sekce analogické ceos-agents stylu.

```yaml
# Z MS Learn docs, learn.microsoft.com/en-us/agent-framework/agents/declarative
kind: Prompt
name: DiagnosticAgent
displayName: Diagnostic Assistant
instructions: Specialized diagnostic and issue detection agent for systems with critical error protocol
description: An agent that performs diagnostics on systems and can escalate issues when critical errors are detected.
model:
  id: =Env.AZURE_OPENAI_MODEL
  connection:
    kind: remote
    endpoint: =Env.FOUNDRY_PROJECT_ENDPOINT
```

**Porovnání s ceos-agents:** MAF deklarativní agenti jsou minimalistické entity (instructions = 1-3 věty). Komplexní behaviour (routing, looping, escalation) je v **workflow** YAML, ne v agent definici. To je fundamentálně odlišné od ceos-agents přístupu, kde agent definice obsahuje celé Process (numbered steps) + Constraints.

### MAF vs ceos-agents granularita

| Aspekt | MAF deklarativní agent | ceos-agents agent |
|---|---|---|
| Instructions délka | 1-3 věty | 100-500 řádků |
| Behaviour definice | Ve workflow YAML | V agent promptu |
| Reusability | Agent volán z různých workflows | Agent vázán na konkrétní pipeline role |
| Customization | Instrukce + tools | Append-to-prompt overlay |

---

## Dimenze 2: Pipeline Configuration Mechanism

### YAML Schema — kompletní dump

Ověřeno z `learn.microsoft.com/en-us/agent-framework/workflows/declarative` (updated 2026-04-02, word count 7748, tutoriál).

**C# struktura (trigger-based):**

```yaml
kind: Workflow
trigger:
  kind: OnConversationStart
  id: <workflow_id>
  actions:
    - kind: <ActionType>
      id: <unique_id>           # optional
      displayName: <string>    # optional
      # action-specific properties
```

**Python struktura (name-based):**

```yaml
name: <workflow_name>
description: <string>           # optional
inputs:
  <parameterName>:
    type: string
    description: <string>
actions:
  - kind: <ActionType>
    id: <unique_id>
    # action-specific properties
```

**Action types (kompletní tabulka z docs, oba jazyky):**

| Kategorie | Actions | C# | Python |
|---|---|---|---|
| Variable Management | `SetVariable`, `SetMultipleVariables`, `ResetVariable` | ✅ | ✅ |
| Variable Management | `AppendValue` | ❌ | ✅ |
| Variable Management | `SetTextVariable`, `ClearAllVariables`, `ParseValue`, `EditTableV2` | ✅ | ❌ |
| Control Flow | `If`, `ConditionGroup`, `Foreach`, `BreakLoop`, `ContinueLoop`, `GotoAction` | ✅ | ✅ |
| Control Flow | `RepeatUntil` | ❌ | ✅ |
| Output | `SendActivity` | ✅ | ✅ |
| Output | `EmitEvent` | ❌ | ✅ |
| Agent Invocation | `InvokeAzureAgent` | ✅ | ✅ |
| Tool Invocation | `InvokeFunctionTool` | ✅ | ✅ |
| Tool Invocation | `InvokeMcpTool` | ✅ | ❌ |
| Human-in-the-Loop | `Question`, `RequestExternalInput` | ✅ | ✅ |
| Human-in-the-Loop | `Confirmation`, `WaitForInput` | ❌ | ✅ |
| Workflow Control | `EndWorkflow`, `EndConversation`, `CreateConversation` | ✅ | ✅ |
| Conversation | `AddConversationMessage`, `CopyConversationMessages`, `RetrieveConversationMessage`, `RetrieveConversationMessages` | ✅ | ❌ |

Source: learn.microsoft.com/en-us/agent-framework/workflows/declarative, sekce "Action Types"

**Variable namespaces (C# runtime):**

| Namespace | Popis | Příklad |
|---|---|---|
| `Local.*` | Variables lokální k workflow | `Local.message` |
| `System.*` | System-provided values | `System.LastMessage.Text`, `System.ConversationId` |

Note: C# declarative workflows nepoužívají `Workflow.Inputs` nebo `Workflow.Outputs` namespaces — input přichází přes `System.LastMessage`, output přes `SendActivity`. Python verze má `Workflow.Inputs.*` namespace (jiná architektura).

Source: learn.microsoft.com/en-us/agent-framework/workflows/declarative, sekce "Variable Namespaces"

---

## Dimenze 3: Per-Project Customization

### Deklarativní agenti jako per-project YAML configs

Z `declarative-agents/` adresáře v `github.com/microsoft/agent-framework` (ověřeno 2026-04-26):

```
microsoft/agent-framework/
├── declarative-agents/
│   ├── agent-samples/      # per-agent YAML definitions
│   └── workflow-samples/   # per-workflow YAML definitions
│       ├── CustomerSupport.yaml
│       ├── DeepResearch.yaml
│       ├── Marketing.yaml
│       ├── MathChat.yaml
│       └── README.md
├── dotnet/
├── python/
└── schemas/
```

Source: github.com/microsoft/agent-framework, directory listing, retrieved 2026-04-26

### Inheritance / Overlay rules

**NEEXISTUJÍ** — žádná inheritance ani overlay mechanika pro declarative agents v dokumentaci nalezena. Každý YAML agent nebo workflow je self-contained definice. "Per-project customization" probíhá tak, že projekt vytvoří vlastní YAML soubory (nikoliv dědění ze shared base).

Porovnání s ceos-agents `Agent Overrides` (append-to-prompt): MAF nemá ekvivalentní mechanismus pro declarative path. Programatická cesta (Python/C# kód) allows full inheritance via subclassing `MagenticManagerBase`.

### Copilot Studio integrace

MAF deklarativní workflows jsou primárně navrženy pro **Azure Foundry** + **Copilot Studio** ekosystém. Foundry-hosted workflows a Copilot Studio Declarative Agents jsou separátní produkty sdílející YAML schéma. Pro self-hosted / open-source použití je primární cesta programatická (Python SDK / .NET NuGet).

---

## Dimenze 4: HITL Pattern

### Optional Plan Review — ověřena implementace

Dokumentována v `learn.microsoft.com/en-us/agent-framework/workflows/orchestrations/magentic` (updated 2026-04-02):

```python
# Z MS Learn docs (Python)
workflow = MagenticBuilder(
    participants=[researcher_agent, analyst_agent],
    intermediate_outputs=True,
    enable_plan_review=True,  # HITL gate
    manager_agent=manager_agent,
    max_round_count=10,
    max_stall_count=1,
    max_reset_count=2,
).build()
```

Workflow flow s HITL (dokumentovaný):

1. **Planning Phase** — manager analyzuje task, vytvoří initial plan
2. **Optional Plan Review** — pokud `enable_plan_review=True`, emituje `WorkflowEvent` s `type="request_info"` a `MagenticPlanReviewRequest` data
3. Uživatel může: **Revise** (feedback → replanning) nebo **Approve** (pokračovat)
4. Agent Selection, Execution, Progress Assessment
5. **Stall Detection** — pokud `stall_count > max_stall_count`, auto-replan + optional human review
6. Iteration until completion or limits
7. Final Synthesis

Source: learn.microsoft.com/en-us/agent-framework/workflows/orchestrations/magentic, sekce "Advanced: Human-in-the-Loop Plan Review"

### Stall Detection přesný threshold

Z `MagenticBuilder` API dokumentace (totéž MS Learn):

- `max_stall_count` — konfigurovatelný (příklady: 1, 3)
- `max_reset_count` — konfigurovatelný (příklady: 2)

Z arxiv 2411.04468v1 (původní paper): "If the counter exceeds the threshold of ≤2, the system resets its planning loop." (Paper má fixed threshold ≤2; MAF implementace to zpřístupňuje jako konfigurovatelný parametr.)

### HITL akce v declarative workflow YAML

Pro declarative workflows (ne Magentic orchestration) existují dedikované HITL actions:

```yaml
# Question action — ptá se uživatele
- kind: Question
  id: ask_name
  question:
    text: "What is your name?"
  variable: Local.userName
  default: "Guest"

# RequestExternalInput — čeká na external system/process
- kind: RequestExternalInput
  id: request_approval
  prompt:
    text: "Please provide approval for this request."
  variable: Local.approvalResult
```

Source: learn.microsoft.com/en-us/agent-framework/workflows/declarative, sekce "Human-in-the-Loop Actions"

`WaitForInput` a `Confirmation` existují pouze v Python verzi. C# verze má `RequestExternalInput` s suspend/resume přes `CheckpointManager`.

---

## Dimenze 5: Stateful vs Stateless Agent Design

### Magentic-One: 2-loop bookkeeping

Ověřeno z arxiv 2411.04468v1 (Fourney et al., Nov 2024):

**Task Ledger (outer loop):**
- Obsahuje: "given or verified facts, facts to look up (e.g., via web search), facts to derive (e.g., programmatically, or via reasoning), and educated guesses"
- Manažer ho vytváří na začátku a aktualizuje po každém stall
- Persistuje po celou dobu úkolu

**Progress Ledger (inner loop):**
- Vytvářen v každé iteraci inner loop
- Obsahuje: "current progress, task assignment to agents"
- Orchestrator dělá self-reflection přes progress ledger

Tato dual-ledger architektura je **explicitly stateful** — na rozdíl od ceos-agents stateless dispatch (kde kontext je předán explicitně jako argument, ale agent nemá vlastní paměť).

### Benchmark výsledky — empirická data

Z arxiv 2411.04468v1 (tabulky z paperu):

| Benchmark | Score (GPT-4o + o1) | Poznámka |
|---|---|---|
| GAIA Level 1 | 54.84% | |
| GAIA Level 2 | 32.70% | |
| GAIA Level 3 | 22.92% | |
| GAIA Overall | 38.00% | vs human performance 92.00±3.1% |
| WebArena | 32.80% | GPT-4o only |
| AssistantBench | 27.70% accuracy | 13.3% exact match |

**Klíčové zjištění o 92% čísle:** Run 1 citoval "Magentic-One ledger ~92% correct dispatch on benchmarks (paper)" — toto číslo **není correct dispatch rate**. Z arxiv 2411.04468v1 je 92.00% **human performance baseline** na GAIA benchmark (Table 1: "92.00±3.1"). Magentic-One samotné dosahuje **38% na GAIA overall**. Číslo 92% bylo patrně chybně interpretováno run-1 agentem. Tato anomálie je verifikována.

### State management v MAF declarative workflows

MAF declarative workflows implementují state přes:
1. **Local variables** — per-workflow session state (`Local.*` namespace)
2. **CheckpointManager** — perzistentní state pro fault-tolerance a resume

```csharp
// In-memory checkpoint (dev)
CheckpointManager checkpointManager = CheckpointManager.CreateInMemory();
// File-based checkpoint (production)
var checkpointManager = CheckpointManager.CreateJson(
    new FileSystemJsonCheckpointStore(checkpointFolder));
```

Source: learn.microsoft.com/en-us/agent-framework/workflows/declarative, sekce "Resuming from Checkpoints"

MAF tedy nabízí **explicitní workflow-level state** s checkpoint/resume capability — to je substantiálně silnější než ceos-agents stateless dispatch (stav je v `.ceos-agents/state.json` ale agent sám ho nečte automaticky).

---

## Dimenze 6: "Lessons Learned" — Evoluční trajektorie

### AutoGen → Magentic-One → MS Agent Framework

**Timeline (ověřeno):**

- **AutoGen** — původní MS multi-agent framework, research-grade; peak 57k★; dnes 0 commits/30d (maintenance only per Run 1 agent-3)
- **Magentic-One** (Nov 2024, arxiv 2411.04468) — první vendor-blessed production-quality multi-agent pattern; původně jako AutoGen extension
- **Semantic Kernel 1.0** (Oct 2025) — konsolidace .NET AI SDK
- **MS Agent Framework** (Oct 1, 2025 — initial announcement, devblogs.microsoft.com/foundry) — sjednocení AutoGen + Semantic Kernel
- **MS Agent Framework 1.0 GA** (April 3, 2026, devblogs.microsoft.com/agent-framework/microsoft-agent-framework-version-1-0/) — produkční release

**AutoGen maintenance mode status:** "Semantic Kernel and AutoGen are now in maintenance mode — security patches and bug fixes will continue, but new feature development is moving to Agent Framework going forward." Source: techstrong.ai, 2026-04-06.

**Migration path:**
- AutoGen: `AssistantAgent → ChatAgent`; `FunctionTool → @ai_function decorator`; orchestration přechod z event-driven na typed graph-based Workflow API
- Semantic Kernel: Kernel/plugin patterns → Agent/Tool abstractions; existující vector store integrations zachovány

Source: devblogs.microsoft.com/foundry/introducing-microsoft-agent-framework-the-open-source-engine-for-agentic-ai-apps/ (Oct 2025)

### Co přineslo 1.0 GA (2026-04-03)

Z devblogs GA announcement:

- **Stable API surface** (breaking changes od preview)
- **Long-term support commitment**
- Stable: Single agents, service connectors, middleware, memory architecture, graph-based workflow engine, multi-agent orchestration patterns (sequential, concurrent, handoff, group chat, Magentic-One), A2A + MCP protocol support
- **Declarative YAML agents** — listed jako GA feature v oznámení, ALE v NuGet stavu `--prerelease`

Source: devblogs.microsoft.com/agent-framework/microsoft-agent-framework-version-1-0/

### Enterprise customer signals

Z devblogs.microsoft.com/foundry (Oct 2025 initial announcement, 12 pojmenovaných zákazníků):
- **KPMG** — audit automation
- **Commerzbank** — customer support
- **BMW** — vehicle telemetry analysis
- Fujitsu, Citrix, TCS, Sitecore, NTT DATA, a další

GA blog (2026-04-03) uvádí "real-world validation with customers and partners" ale bez jmen nebo kvantitativních dat. Žádné case studies s ROI metrikami.

---

## Dimenze 7: Co lze přenést do markdown-only Claude Code plugin

### 7a — Task Ledger + Progress Ledger jako ceos-agents pattern

**Magentic-One dual-ledger** je nejbezprostředněji aplikovatelný vzor. Ceos-agents má analogii:
- `.ceos-agents/state.json` = partial task ledger (issue metadata, AC, pipeline phase)
- `pipeline-history.md` (50-run retention) = partial progress ledger

Co ceos-agents **nemá** a Magentic-One **má**: outer-loop task ledger s explicitním "facts to look up" + "educated guesses" strukturou, která je průběžně aktualizována při každém stall. Toto by byl silnější state pattern pro fixer↔reviewer loop (fixer by explicitně zapisoval "verified facts" o codebase struktuře místo opakovaného re-discovery).

**Přenositelnost do markdown-only:** Realizovatelné jako strukturovaná sekce v state.json — žádný runtime nutný. Fixer prompt by mohl obsahovat "update task ledger facts section" instrukci.

### 7b — Optional Plan Review jako HITL gate

MAF `enable_plan_review=True` u Magentic orchestration je přímá analogie k ceos-agents sub-projektu B (Human-in-the-Loop). Vzor:

1. Agent vytvoří plán (triage output → AC)
2. HITL gate: uživatel approves nebo provides feedback
3. Agent replanuje podle feedbacku

V markdown-only kontextu ceos-agents: realizovatelné jako `NEEDS_CLARIFICATION` po triage fázi s explicitním checkpoint (uživatel schválí AC před spuštěním fixer fáze). Toto je přímé rozšíření existujícího NEEDS_CLARIFICATION mechanismu.

**Rozdíl:** MAF Optional Plan Review je event-driven (WorkflowEvent stream), ceos-agents NEEDS_CLARIFICATION je file-based pause (`paused` state + manual resume). Výsledek stejný, implementace odlišná.

### 7c — Kind: ConditionGroup vs LLM Dispatch

**ConditionGroup** je deterministické větvení v YAML (formula expression, NIKOLI LLM):

```yaml
- kind: ConditionGroup
  id: route_by_category
  conditions:
    - condition: =Local.category = "electronics"
      actions:
        - kind: SetVariable
          variable: Local.department
          value: Electronics Team
  elseActions:
    - kind: SetVariable
      variable: Local.department
      value: General Support
```

Source: learn.microsoft.com/en-us/agent-framework/workflows/declarative, sekce "ConditionGroup"

**CustomerSupport.yaml** (github.com/microsoft/agent-framework/declarative-agents/workflow-samples/CustomerSupport.yaml) ukazuje reálný use case:
- `=Not(Local.ServiceParameters.IsResolved)` — loop condition pro SelfServiceAgent
- `=Local.RoutingParameters.TeamName = "Windows Support"` — routing branch
- `=Local.SupportParameters.ResolutionSummary` — data extraction

Source: CustomerSupport.yaml, retrieved via github.com/microsoft/agent-framework 2026-04-26

**Relevance pro ceos-agents:** Ceos-agents aktuálně používá LLM dispatch (markdown prose popis → agent rozhodne). MAF ConditionGroup pattern ukazuje, že deterministic branching v pipeline je realizovatelné bez LLM. V markdown-only kontextu by analogie byl `if: [condition]` v pipeline stage definition — podobně jako GitHub Actions `if:` conditional. Run 1 (agent-3) toto správně identifikoval; potvrzeno.

### 7d — InvokeAzureAgent s `externalLoop.when`

```yaml
- kind: InvokeAzureAgent
  id: support_agent
  agent:
    name: SupportAgent
  input:
    externalLoop:
      when: =Not(Local.IsResolved)
```

Toto je YAML ekvivalent fixer↔reviewer retry loop v ceos-agents. Ceos-agents implementuje loop jako numbered steps v markdown prose — MAF ho deklaruje jako YAML `externalLoop.when` condition. Pattern je stejný (opakuj dokud podmínka), surface odlišná.

---

## Dimenze 8: Co je Framework-Specific (Lock-in Analysis)

### Runtime dependency

| Aspekt | Specifikum |
|---|---|
| Primární runtime | .NET 8 (C#) + Python 3.10+ |
| NuGet pakety | `Microsoft.Agents.AI` (stable), `Microsoft.Agents.AI.Workflows.Declarative` (**--prerelease**) |
| Azure dependency | Azure Foundry project endpoint (pro `AzureAgentProvider` + `FoundryChatClient`) |
| Model default | Azure OpenAI (ale multi-provider: Anthropic Claude, Amazon Bedrock, Google Gemini, Ollama) |
| Checkpoint storage | In-memory nebo file-based JSON (no external DB required pro self-hosted) |

### Copilot Studio / Foundry lock-in

Declarative agents a workflows jsou primárně navrženy pro **Azure AI Foundry** ekosystém. `AzureAgentProvider` vyžaduje Foundry project endpoint. Self-hosted použití je možné přes programatický path s jiným model providerem, ale declarative YAML path je tightly coupled na Foundry hosting.

`InvokeMcpTool` connection pro hosted scenarios má `connection.name` pro Foundry `ProjectConnectionId` — ale docs explicitně uvádí "Note: This feature is not fully supported yet." Source: MS Learn declarative docs.

### C# vs Python feature parity

Feature parity **není** plná (ověřeno z action type tabulky):

- C# nemá: `AppendValue`, `EmitEvent`, `RepeatUntil`, `Confirmation`, `WaitForInput`, `InvokeMcpTool` (pro hosted)
- Python nemá: `SetTextVariable`, `ClearAllVariables`, `ParseValue`, `EditTableV2`, `InvokeMcpTool` (plný)
- Magentic orchestration: **Python only** ("Magentic Orchestration is not yet supported in C#" — MS Learn)

Source: learn.microsoft.com/en-us/agent-framework/workflows/orchestrations/magentic, sekce "C# zone pivot"

### Open-source status

Repo `github.com/microsoft/agent-framework` je open-source (MIT license). 9.8k★ ke dni Q12 scoring. Vznikl 2025-04-28 (0 → 9.8k v 12 měsících).

---

## Speciální Sekce: Řešení Anomaly 7

### Anomaly 7 z Run 1: "declarative-agents/workflow-samples/ vs No vendor ships YAML DSL as primary"

Run 1 identifikoval tuto tenzí:
> "Microsoft Agent Framework `declarative-agents/workflow-samples/` je most explicit vendor signal that YAML-declarative is enterprise future — but agent-5 also cites 'Going to YAML pipeline DSL would be unprecedented in major-vendor docs' (no top vendor ships YAML pipeline DSL as primary mechanism)."

**Empirická verifikace Run 2:**

**1) Existence `declarative-agents/workflow-samples/` — VERIFIKOVÁNO.**
Adresář existuje v `github.com/microsoft/agent-framework` s 4 YAML soubory: CustomerSupport.yaml, DeepResearch.yaml, Marketing.yaml, MathChat.yaml. Source: GitHub directory listing, retrieved 2026-04-26.

**2) Je to "primary mechanism" nebo "alternative surface"?**

Empirická evidence naznačuje **alternative surface, nikoliv primary**:

- GA blog (2026-04-03): Code examples jsou programatické (C#/Python), YAML zmíněn jako feature bullet point
- Techstrong.ai review (2026-04-06): "Declarative YAML support is presented as secondary. The article mentions it briefly near the conclusion rather than in core capability descriptions."
- NuGet status: `Microsoft.Agents.AI.Workflows.Declarative 1.0.0-rc4` — stále jako **release candidate / prerelease**, nikoliv stable 1.0 package; MS Learn docs instruují `dotnet add package Microsoft.Agents.AI.Workflows.Declarative --prerelease`
- MS Learn "When to Use Declarative vs. Programmatic" tabulka: Declarative doporučeno pro "standard orchestration patterns, workflows that change frequently, non-developers"; Programmatic pro "complex custom logic, maximum flexibility, integration with existing code"

**3) Co MS officiálně doporučuje (devblogs + docs hierarchy)?**

Intro tutorial (`learn.microsoft.com/en-us/agent-framework/overview/`) začíná programatickými příklady. Declarative je dokumentována v dedikované sekci `/workflows/declarative` jako alternativní approach. Docs hierarchie: Overview → Agents → Workflows → Orchestrations → (optionally) Declarative.

**4) Adoption signals — enterprise?**

GA blog: "real-world validation with customers and partners" — bez jmen pro 1.0 GA. Foundry blog (Oct 2025): 12 pojmenovaných firem (KPMG, Commerzbank, BMW...) — ale pro celkový MAF, nikoliv specificky pro declarative YAML path. Žádný case study explicitně uvádí "we use declarative YAML workflows in production."

**5) Rozhodující evidence pro Anomaly 7 resolution:**

Anomaly 7 je **ČÁSTEČNĚ REZOLVOVÁNA** takto:

- **Část 1 (vendor commitment je real):** Microsoft investuje do declarative YAML — `declarative-agents/` adresář existuje, MS Learn docs jsou rozsáhlé (7748 words pro declarative workflows tutorial), feature je listed v GA announcement. Commitment je signifikantní.
- **Část 2 (není primary mechanism):** Declarative YAML workflows jsou ve `--prerelease` NuGet package stavu i po 1.0 GA. Magentic orchestration (Python only) = narrower scope. GA blog code examples = programatické. MS Learn "When to Use" tabulka = deklaruje declarative jako optional pro specific scenarios.
- **Část 3 (Run 1 konkluzí "no vendor ships YAML DSL as primary" stále platí):** Microsoft YAML je **valid enterprise alternative surface**, nikoliv replacement pro programmatic approach. Closest vendor to shipping YAML as primary mechanism — ale ještě tam není.

**Formula language semantics — VERIFIKOVÁNO:**

Výrazy prefixované `=` jsou vyhodnocovány jako **PowerFx expression language** (Microsoft Power Platform):

Funkce dostupné (z MS Learn docs):
- `Concat(str1, str2, ...)` — string concatenation
- `If(condition, trueValue, falseValue)` — conditional
- `IsBlank(value)` — null check
- `Upper(text)` / `Lower(text)` — case conversion
- `Find(searchText, withinText)` — text search
- `MessageText(message)` — extract text from message object
- `UserMessage(text)` — create user message
- `AgentMessage(text)` — create agent message
- `Not(expression)`, `And(e1, e2)` — boolean operators
- Arithmetic: `Local.TurnCount + 1`, comparison `= "string"`, `>= 18`

Variable scopes: `Local.*`, `System.*` (C#); `Workflow.Inputs.*`, `Workflow.Outputs.*`, `Env.*` (Python).

Source: learn.microsoft.com/en-us/agent-framework/workflows/declarative, sekce "Expression Language"

`=Local.ServiceParameters.IsResolved` je PowerFx property access na nested object (`ServiceParameters` je output z `InvokeAzureAgent` action, `IsResolved` je field v agent response schema). Výraz vrací boolean.

---

## Syntéza Findings pro Q22 Input

### Framework fingerprint

| Dimenze | Finding |
|---|---|
| Agent granularita | Minimalistické agents (1-3 věty instrukce) + heavyweight workflow YAML |
| Pipeline mechanism | Programatický graph (primary, stable) + YAML declarative (alternative, prerelease) |
| Per-project customization | Self-contained YAML files, žádný inheritance/overlay mechanism |
| HITL pattern | Optional Plan Review (enable_plan_review=True) + Stall Detection (konfigurovatelný threshold) |
| Stateful design | Explicit dual-ledger (task + progress), checkpoint/resume, workflow-level Local state |
| Evolution | AutoGen → Magentic-One → MAF; 12 enterprise customers (KPMG, BMW, Commerzbank) |
| Lock-in | .NET 8 / Python 3.10+, Azure Foundry tight coupling (declarative path), Magentic = Python only |

### Přenositelné vzory (pro ceos-agents, bez implementační rekomendace)

1. **Dual-ledger pattern** — task ledger (verified facts + guesses) + progress ledger (per-step state) jako explicit stateful primitive. V markdown-only: rozšíření state.json o `task_ledger` sekci.
2. **Optional Plan Review HITL** — explicit gate po plánování, před exekucí. Uživatel může revize nebo approve. V ceos-agents: rozšíření NEEDS_CLARIFICATION na "plan review" checkpoint po triage.
3. **ConditionGroup = deterministic branching** — kontrolní flow bez LLM. Podmínky jsou formula expressions. V ceos-agents: alternativa k LLM dispatch pro pipeline routing.
4. **externalLoop.when** — deklarativní retry loop s podmínkou. Analogie k fixer↔reviewer loop v ceos-agents.

### Framework-specific (nepřenositelné)

1. Azure Foundry hosting dependency pro plný declarative workflow stack
2. .NET 8 runtime (C# primary path)
3. Magentic orchestration = Python only, ne produkčně testováno mimo původní Magentic-One specialist set
4. PowerFx expression engine (Microsoft Power Platform závisost)

---

## Citace (chronologicky)

- Fourney, A. et al. "Magentic-One: A Generalist Multi-Agent System for Solving Complex Tasks." arxiv 2411.04468v1, Nov 2024. [https://arxiv.org/abs/2411.04468](https://arxiv.org/abs/2411.04468)
- Microsoft. "Introducing Microsoft Agent Framework: The Open-Source Engine for Agentic AI Apps." devblogs.microsoft.com/foundry, Oct 1, 2025. [https://devblogs.microsoft.com/foundry/introducing-microsoft-agent-framework-the-open-source-engine-for-agentic-ai-apps/](https://devblogs.microsoft.com/foundry/introducing-microsoft-agent-framework-the-open-source-engine-for-agentic-ai-apps/)
- Microsoft. "Declarative Agents." learn.microsoft.com/en-us/agent-framework/agents/declarative. Updated 2026-04-02. [https://learn.microsoft.com/en-us/agent-framework/agents/declarative](https://learn.microsoft.com/en-us/agent-framework/agents/declarative)
- Microsoft. "Declarative Workflows - Overview." learn.microsoft.com/en-us/agent-framework/workflows/declarative. Updated 2026-04-02. [https://learn.microsoft.com/en-us/agent-framework/workflows/declarative](https://learn.microsoft.com/en-us/agent-framework/workflows/declarative)
- Microsoft. "Magentic Orchestration." learn.microsoft.com/en-us/agent-framework/workflows/orchestrations/magentic. Updated 2026-04-02. [https://learn.microsoft.com/en-us/agent-framework/workflows/orchestrations/magentic](https://learn.microsoft.com/en-us/agent-framework/workflows/orchestrations/magentic)
- Microsoft. "Microsoft Agent Framework Version 1.0." devblogs.microsoft.com/agent-framework, Apr 3, 2026. [https://devblogs.microsoft.com/agent-framework/microsoft-agent-framework-version-1-0/](https://devblogs.microsoft.com/agent-framework/microsoft-agent-framework-version-1-0/)
- GitHub. `microsoft/agent-framework` repository. [https://github.com/microsoft/agent-framework](https://github.com/microsoft/agent-framework). Retrieved 2026-04-26.
- GitHub. `microsoft/agent-framework/declarative-agents/workflow-samples/CustomerSupport.yaml`. Retrieved 2026-04-26.
- NuGet Gallery. `Microsoft.Agents.AI.Workflows.Declarative`. [https://www.nuget.org/packages/Microsoft.Agents.AI.Workflows.Declarative/](https://www.nuget.org/packages/Microsoft.Agents.AI.Workflows.Declarative/). Retrieved 2026-04-26.
- Microsoft. "Microsoft Agent Framework Version 1.0." Visual Studio Magazine, Apr 6, 2026. [https://visualstudiomagazine.com/articles/2026/04/06/microsoft-ships-production-ready-agent-framework-1-0-for-net-and-python.aspx](https://visualstudiomagazine.com/articles/2026/04/06/microsoft-ships-production-ready-agent-framework-1-0-for-net-and-python.aspx)

---

*Agent: Q18 MS Agent Framework deep-dive | Run 2 | 2026-04-26 | Délka: ~4,200 slov*
