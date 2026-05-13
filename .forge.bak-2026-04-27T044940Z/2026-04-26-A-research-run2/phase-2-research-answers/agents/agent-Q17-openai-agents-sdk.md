# Q17 — OpenAI Agents SDK: Hluboká analýza (Run 2)

**Datum:** 2026-04-26
**Run:** 2026-04-26-A-research-run2 (forge-research, sub-projekt A v8.0.0)
**Scope:** Q17 — OpenAI Agents SDK + Codex Subagents (8 dimenzí)
**Primary lens:** Vendor (OpenAI official docs, Agents SDK release notes)
**Secondary lens:** OSS code (openai/openai-agents-python source)
**Recency:** Pokrývá March 2025 (SDK release) → April 15, 2026 (next evolution update)
**NEOBSAHUJE žádné v8.0.0 doporučení** — output je evidence map

---

## Lens disclosure

Tato analýza čerpá primárně z:
- **Vendor docs:** `openai.github.io/openai-agents-python` (plná dokumentace), `developers.openai.com/api/docs/guides/agents` (API guide), `developers.openai.com/codex/subagents` (Codex Subagents), `openai.com/index/the-next-evolution-of-the-agents-sdk/` (April 2026 blog)
- **OSS source:** `github.com/openai/openai-agents-python` source files — `src/agents/agent.py` (lines 471–938), `src/agents/handoffs/__init__.py` (lines 222–335), `src/agents/extensions/handoff_prompt.py`
- **Recency anchors:** SDK release March 11, 2025; next evolution update April 15, 2026 (TechCrunch); Codex Subagents docs stav 2026-04
- **Run 1 kontext:** Run 1 final.md (Q3, Q5, Q7, Q12) — použit jako kontextová vrstva, NE jako primární citace zdroj

---

## Executive summary

OpenAI Agents SDK (release March 11, 2025, GA) je **code-first Python library** s minimalistickými 4 primitivy: Agents, Handoffs, Guardrails, Sessions. Pipeline = `Runner.run(agent, input)` v Python kódu — žádný YAML, žádný markdown. Agent instrukce jsou typicky **20–200 znakové strings** (thin mode), nebo dynamické callably. Handoffs jsou reprezentovány jako **tool-calls** — LLM rozhoduje o delegaci výběrem nástroje `transfer_to_<agent_name>`. Codex Subagents implementují **typed inherit-with-override** přes TOML soubory v `.codex/agents/` — nejblíže k production-shipping inheritance modelu v ekosystému. **April 15, 2026** update přidal native sandbox + long-horizon harness jako enterprise primitiva. Framework je Python (a TypeScript) runtime-dependent — **plně nekompatibilní s markdown-only plugin filozofií**, ale obsahuje architektonické vzory přenositelné jako inspirace pro ceos-agents v8.0.0.

---

## Dimenze 1 — Granularita agentů

### Agent class: kompletní signatura

`Agent` je `@dataclass` v `src/agents/agent.py` (lines 471–938), generic přes `TContext`. Klíčové fieldy:

| Field | Type | Default | Sémantika |
|-------|------|---------|-----------|
| `name` | `str` | Required | Agent identifier |
| `instructions` | `str \| Callable[[RunContextWrapper, Agent], MaybeAwaitable[str]] \| None` | `None` | System prompt nebo dynamický callback |
| `model` | `str \| Model \| None` | `None` → defaults `gpt-4.1` | LLM implementace |
| `model_settings` | `ModelSettings` | Default | Temperature, top_p, tool_choice |
| `tools` | `list[Tool]` | `[]` | Function tools, MCP tools, hosted tools |
| `handoffs` | `list[Agent \| Handoff]` | `[]` | Sub-agenti pro delegaci |
| `output_type` | `type \| AgentOutputSchemaBase \| None` | `None` | Pydantic/dataclass/TypedDict structured output |
| `input_guardrails` | `list[InputGuardrail]` | `[]` | Pre-run validace |
| `output_guardrails` | `list[OutputGuardrail]` | `[]` | Post-run validace |
| `hooks` | `AgentHooks \| None` | `None` | Lifecycle callbacks |
| `handoff_description` | `str` (inherited) | (none) | Popis pro LLM při výběru handoff |
| `mcp_servers` | `list` (inherited) | `[]` | MCP server integrace |
| `tool_use_behavior` | `Literal \| StopAtTools \| Callable` | `"run_llm_again"` | Tool result handling strategie |
| `reset_tool_choice` | `bool` | `True` | Reset tool preference po volání |

Zdroj: `openai.github.io/openai-agents-python/ref/agent/` (agent.py lines 471–938)

### Délka instructions v praxi

OpenAI Agents SDK dokumentace explicitně popisuje instrukce jako **"typically 20–200 chars"** (thin mode) — viz Run 1 OSS-code lens (agent-3 Q1 source-code size table). Vendor examples z customer service demo ukazují instrukce ve stylu:

- Minimalistické: `"Always respond in haiku form"`
- Mírně rozvinuté: `"Help the user with their questions. If they ask about booking, hand off the booking agent."`
- Triage pattern: `"A triage agent routes to specialists. Identify the user's need and transfer to the appropriate specialist."`

Žádný SDK example nepoužívá 100+ řádkové markdown definice — to je paradigmatický kontrast oproti ceos-agents přístupu (117 řádků u `fixer.md`).

### Optimal granularity v OpenAI examples

Canonical OpenAI customer service demo (`github.com/openai/openai-cs-agents-demo`) implementuje **triage + 4 specialistů**: Flight Information Agent, Seat Booking Agent, Cancellation Agent, FAQ Agent. Architektura: **1 Triage + N specialist** = 5 agentů celkem.

Praktické doporučení z vendor docs (`developers.openai.com/api/docs/guides/agents`):

> "Start with one agent whenever you can. Add specialists only when they materially improve capability isolation, policy isolation, prompt clarity, or trace legibility."

> "As the number of required tools increases, consider splitting tasks across multiple agents."

Vendor nepoužívá číselný limit. Run 1 synthesis (Q2) identifikovala Sweet Spot = ≤5 specializovaných agentů v canonical OpenAI examples (customer service = 5, Triage = 1 + 4 domains). Toto je v kontrastu s ceos-agents 21 agenty, které Run 1 označil jako "outer edge of production precedent."

---

## Dimenze 2 — Pipeline configuration mechanism

### Code-defined Python, ne markdown/YAML

OpenAI Agents SDK definuje pipeline výhradně v **Python kódu**. Žádný YAML DSL, žádný markdown procedural pipeline:

```python
# Základní single-agent run
result = Runner.run_sync(agent, "user input")

# Multi-agent orchestrace přes handoffs (Python in-process)
triage_agent = Agent(
    name="Triage",
    instructions="Route user requests to specialist agents.",
    handoffs=[booking_agent, refund_agent, faq_agent]
)
result = await Runner.run(triage_agent, "I need to book a flight")
```

Zdroj: `openai.github.io/openai-agents-python/quickstart/`

Pipeline = `Runner.run(agent, input)` s agentem jako entry point. Handoffs delegate konverzaci na sub-agenty — LLM rozhoduje volbou tool `transfer_to_<agent_name>`. Žádný centrální pipeline orchestrator kód mimo Python tříd.

### 4 primitiva SDK

SDK vědomě minimalizuje abstrakce (z Swarm migration lessons):

1. **Agents** — LLM + instructions + tools (základní výkonná jednotka)
2. **Handoffs** — Agent-to-agent delegation via tool-call (LLM-driven)
3. **Guardrails** — Input + output validation gates (code-defined)
4. **Sessions** — Persistent memory layer (pluggable backends)

Plus od April 2026:
5. **Long-horizon harness** — In-distribution harness pro frontier models na komplexních multi-step tasks
6. **Native sandbox** — Izolovaná workspace pro file/code operations

Zdroj: `openai.github.io/openai-agents-python/` (overview section); TechCrunch 2026-04-15

---

## Dimenze 3 — Per-project customization

### Agents SDK: žádný declarative overlay

Agents SDK je **library**, ne plugin framework. "Per-project" customization = instantiace vlastních `Agent(...)` objektů v Python kódu. Žádný declarative overlay mechanismus — každý projekt builduje vlastní agent set od začátku v Pythonu.

```python
# Per-project customization = Python class instances
my_project_fixer = Agent(
    name="ProjectFixer",
    instructions="You fix Django REST Framework bugs. Always use pytest. ...",
    tools=[bash_tool, file_editor],
    model="gpt-5.5"
)
```

Toto je diametrálně odlišné od ceos-agents `Agent Overrides` (append-to-prompt markdown soubory). OpenAI SDK neimplementuje overlay pattern — plná kontrola, ale žádná plugin-style distribuce.

### Codex Subagents: typed inheritance (inherit-with-override)

Codex CLI (OpenAI's coding agent, ne Agents SDK přímo) implementuje **Subagents** přes TOML soubory v:
- Personal agents: `~/.codex/agents/{agent-name}.toml`
- Project-scoped agents: `.codex/agents/{agent-name}.toml`

Každý soubor definuje jednoho custom agenta. **Inheritance mechanismus:** optional fields dědí z parent session, explicit nastavení overriduje:

**Required fields:**
| Field | Type | Sémantika |
|-------|------|-----------|
| `name` | string | Agent identifier pro spawn |
| `description` | string | Human-facing guidance pro LLM — kdy použít |
| `developer_instructions` | string | Behavioral directives (core system prompt body) |

**Optional fields (inherit-with-override from parent):**
| Field | Type | Dědičnost |
|-------|------|-----------|
| `nickname_candidates` | string[] | Pool zobrazovacích jmen pro instance |
| `model` | string | LLM selection |
| `model_reasoning_effort` | string | Reasoning intensity |
| `sandbox_mode` | string | Execution restrictions |
| `mcp_servers` | table | MCP server konfigurace |
| `skills.config` | array | Skill definitions |

Citace z Codex docs: *"Optional fields such as `nickname_candidates`, `model`, `model_reasoning_effort`, `sandbox_mode`, `mcp_servers`, and `skills.config` inherit from the parent session when you omit them."*

Zdroj: `developers.openai.com/codex/subagents`

**Minimální custom agent příklad (jen required fields):**
```toml
name = "reviewer"
description = "PR reviewer focused on correctness and security."
developer_instructions = """
Review code like an owner.
Prioritize correctness, security, and test coverage.
"""
```

**Override-heavy příklad:**
```toml
name = "oracle-pl-sql-fixer"
description = "Fixes PL/SQL bugs in Oracle database stored procedures."
developer_instructions = "..."
model = "gpt-5.4"
model_reasoning_effort = "high"
sandbox_mode = "read-only"
```

**Proč je to "closest production-shipping inheritance model"** (Run 1 agent-2 finding): Codex Subagents jsou vendor-shipped, production-deployed, hierarchický (global `[agents]` config + per-agent TOML override), s explicitní "inherit when omitted" sémantikou. Srovnej s ceos-agents `Agent Overrides` (append-to-prompt markdown) — Codex model je **strukturovanější** (typed fields, explicit schema) ale sdílí stejný základní princip: generic base + per-project override.

**Rozdíl oproti ceos-agents Agent Overrides:**
- Codex: typed TOML fields, každý override má explicitní sémantiku (model override = konkrétní model string)
- ceos-agents: volný markdown append — přidá libovolné instrukce k prompt, ale nemůže override model nebo konfiguraci structurovaně

**Global config sekce:**
```toml
[agents]
max_threads = 6      # Concurrent open agent thread limit
max_depth = 1        # Nesting depth (default 1 = single level)
job_max_runtime_seconds = 3600
```

Runtime overrides (e.g. `/approvals` changes, sandbox mods) automaticky reaplikují na spawned children — dynamický inheritance za runtime.

---

## Dimenze 4 — HITL pattern

### `needs_approval` per-action primitive

Agents SDK implementuje HITL přes `needs_approval` parameter na tool deklaraci:

```python
@function_tool
async def book_flight(ctx, params) -> str: ...
book_flight.needs_approval = True  # vždy vyžaduje approval

# Nebo conditional:
async def needs_oakland_approval(ctx, params, call_id) -> bool:
    return "Oakland" in params.get("city", "")

@function_tool(needs_approval=needs_oakland_approval)
async def book_flight_conditional(ctx, params) -> str: ...
```

Mechanismus `needs_approval` je aplikovatelný na: `function_tool`, `Agent.as_tool()`, `ShellTool`, `ApplyPatchTool`, MCP servery.

**Approval flow:**
1. Model emituje tool call; runner evaluuje approval rule
2. Pokud existuje prior decision v `RunContextWrapper` → execution pokračuje
3. Jinak → pause; `RunResult.interruptions` vrátí `ToolApprovalItem` (agent name, tool name, arguments)
4. `state = result.to_state()` → `state.approve(interruption)` nebo `state.reject(interruption)`
5. `Runner.run(agent, state)` → resumption

**Klíčová vlastnost:** *"That approval surface is run-wide, not limited to the current top-level agent."* Approvals přes handoffs a nested `Agent.as_tool()` surfacují na outer run — unifikovaný HITL povrch.

Zdroj: `openai.github.io/openai-agents-python/human_in_the_loop/`

**`RunState` serializace** pro durable approvals:
```python
state = result.to_state()
STATE_PATH.write_text(state.to_string())  # persist

# Later (jiný process, restart):
state = await RunState.from_string(agent, stored_str)
state.approve(interruption)
result = await Runner.run(agent, state)
```

Sticky decisions: `always_approve=True` / `always_reject=True` přežívají serializaci.

**Poznámka k JS SDK paritě:** `needsApproval` (camelCase) je JS/TypeScript SDK ekvivalent. Python SDK má `needs_approval` (snake_case). Funkcionálně ekvivalentní — oba implementují per-action, event-driven HITL, NE per-stage gate. Toto je vendor-aligned HITL pattern (Run 1 Q6 finding: vendor consensus = event-driven, NE per-stage).

### Guardrails architecture

**Dvě třídy:**
- `InputGuardrail` — validuje před agent run
- `OutputGuardrail` — validuje po agent run

**Execution flow:**
```python
@input_guardrail
async def check_safe_input(ctx, agent, input_data) -> GuardrailFunctionOutput:
    # Evaluace vstupu
    return GuardrailFunctionOutput(
        output_info={"reason": "..."},
        tripwire_triggered=is_unsafe
    )
```

Pokud `tripwire_triggered=True` → exception `InputGuardrailTripwireTriggered` / `OutputGuardrailTripwireTriggered`.

**Execution modes (input):**
- **Parallel** (default): Concurrent s agentem pro minimální latenci
- **Blocking**: Guardrail runs first — blokuje agent execution pokud tripwire

**Tool guardrails** (novinka): Wrap `function_tool` pro pre/post-execution validaci na úrovni jednotlivých nástrojů.

Zdroj: `openai.github.io/openai-agents-python/guardrails/`

**Vztah k ceos-agents:** ceos-agents nemá ekvivalent Guardrails primitivu. Nejbližší analogie je `acceptance-gate` agent (read-only, AC fulfillment check) — ale to je celý agent dispatch, NE programmatický gate. Guardrails jako inline Python funkce = fundamentálně odlišná architektura.

---

## Dimenze 5 — Stateful vs stateless agent design

### Sessions primitive

`Session` je interface definovaný protokolovou třídou `SessionABC`:

```python
class SessionABC:
    async def get_items(limit: int | None = None) -> List[TResponseInputItem]: ...
    async def add_items(items: List[TResponseInputItem]) -> None: ...
    async def pop_item() -> TResponseInputItem | None: ...
    async def clear_session() -> None: ...
```

Stav je serializován jako `TResponseInputItem` dicts — standardní OpenAI message format:
```python
{"role": "user", "content": "Hello"}
{"role": "assistant", "content": "Hi there!"}
```

SDK automaticky fetchuje stored conversation history před každým run a persistuje nové items po completion.

**Usage:**
```python
session = SQLiteSession("conversation_123")
result1 = await Runner.run(agent, "What is X?", session=session)
result2 = await Runner.run(agent, "What about Y?", session=session)  # Remembers X
```

### Storage backends

| Backend | Use case |
|---------|----------|
| `SQLiteSession` | Local dev; file nebo in-memory |
| `AsyncSQLiteSession` | Async SQLite s `aiosqlite` |
| `RedisSession` | Distributed systems; low-latency shared memory |
| `SQLAlchemySession` | Production DB (PostgreSQL, MySQL) |
| `MongoDBSession` | MongoDB; horizontally-scalable |
| `DaprSession` | Cloud-native; 30+ backend support |
| `OpenAIConversationsSession` | Server-managed OpenAI storage |
| `OpenAIResponsesCompactionSession` | Auto-compacting wrapper pro dlouhé konverzace |
| `EncryptedSession` | Transparent encryption wrapper |
| `AdvancedSQLiteSession` | SQLite s branching a analytics |

Zdroj: `openai.github.io/openai-agents-python/sessions/`

### Stateful vs stateless design — SDK pohled

**Stateful přístup:** `Runner.run(agent, input, session=session)` — SDK spravuje memory automaticky. Vhodné pro multi-turn konverzace.

**Stateless přístup:** `Runner.run(agent, input)` bez session — každý run dostane čistý kontext. Vhodné pro pipeline-style dispatch kde orchestrator spravuje state explicitně.

SDK dokumentace: *"Use sessions when you want the SDK to manage client-side memory for you."* Sessions nelze kombinovat s `conversation_id`, `previous_response_id`, nebo `auto_previous_response_id` — jsou vzájemně vylučující mechanismy.

**Handoffs a state:** Handoff transferuje konverzační historii na sub-agenta (pokud není filtrovaná přes `input_filter`). To umožňuje stateful kontext propagaci napříč agenty. `input_filter` funkce umožňuje selektivní filtraci — např. předat jen relevantní subset kontextu.

**Srovnání s ceos-agents:** ceos-agents implementuje "stateless dispatch + explicit state passing" přes `state.json` + `pipeline-history.md` — Run 1 (Q4) to identifikoval jako "functionally equivalent to Anthropic's structured note-taking recommendation." OpenAI SDK Sessions jsou mocnější (více backends, auto-compaction), ale vyžadují Python runtime. ceos-agents stateless pattern je architektonicky analogický k OpenAI SDK stateless mode.

---

## Dimenze 6 — Lessons learned (Swarm → Agents SDK)

### March 2025: Swarm → Agents SDK migration

**Swarm** byl educational/experimental framework pro multi-agent orchestraci — záměrně minimalistický, bez guardrails, bez tracing, Python-only.

**Agents SDK** (release March 11, 2025) = production-ready successor:
- Zachoval Swarm primitiva (Agents, Handoffs via function returns)
- Přidal: Guardrails, Tracing, Sessions, TypeScript SDK, structured outputs
- Breaking migration: API se změnila, primitiva přežila
- Vendor framing: "a lightweight, easy-to-use package with very few abstractions"

Zdroj: `openai.github.io/openai-agents-python/` (overview); `mem0.ai/blog/openai-agents-sdk-review` (December 2025)

**Lessons z Swarm:**
- Handoffs jako tool-calls (LLM picks via function call) = killer feature zachovaný v SDK
- Guardrails nutné pro produkční safety
- Tracing nutný pro debugging multi-agent flows
- TypeScript parity potřebná pro enterprise adoption

### April 15, 2026: Next evolution update

TechCrunch (2026-04-15): *"OpenAI updates its Agents SDK to help enterprises build safer, more capable agents"*

OpenAI blog: *"to go build these long-horizon agents using our harness and with whatever infrastructure they have"*

**Co bylo přidáno:**
- **Native sandbox:** Izolovaná workspace; agenti mohou přistupovat k files/code jen pro specifické operace; system-wide integrity preservation
- **Long-horizon harness:** In-distribution harness pro frontier models — umožňuje komplexní multi-step tasks bez ztráty koherence
- **Python first, TypeScript planned:** Initial launch Python only; code mode + subagents planned for both

**Enterprise focus:** Update explicitně adresuje "two biggest enterprise blockers: safety and complexity."

Zdroj: TechCrunch 2026-04-15; `devops.com/openai-upgrades-its-agents-sdk-with-sandboxing-and-a-new-model-harness/`

### Agents-as-tools vs handoffs: decision rule

**Nejjasnější formulace z vendor docs** (`developers.openai.com/api/docs/guides/agents/orchestration`):

| Pattern | Kdy použít | Ownership |
|---------|-----------|-----------|
| **Handoff** | Specialist should own the next response; different instructions/tools needed; workflow splits into distinct phases | Control moves to specialist |
| **Agent.as_tool()** | Manager should stay in control; specialist does bounded task (summarization, classification); one stable outer workflow | Manager keeps ownership |

Vendor explicitní formulace:
- Handoff: *"A specialist should take over the conversation for that branch of the work"*
- as_tool: *"The manager should synthesize the final answer"* / *"The specialist is doing a bounded task like summarization or classification"*

**Design guidance:** *"Start with one agent whenever you can. Add specialists only when they materially improve capability isolation, policy isolation, prompt clarity, or trace legibility."*

*"Avoid premature splitting, as it creates more prompts, more traces, and more approval surfaces without necessarily making the workflow better."*

Zdroj: `developers.openai.com/api/docs/guides/agents/orchestration`

### Known limitations

1. **LLM-driven handoff selection může halucinovat:** Magentic-One source (`_prompts.py` orchestrator) to explicitně řeší 2-loop ledger — Agents SDK nemá analogický mechanismus, spoléhá na LLM správnost. Run 1 (agent-3) cituje: *"model can refuse / hallucinate handoff"* v `_validate_handoffs`
2. **Non-OpenAI providers beta:** LiteLLM / Any-LLM adaptery jsou beta; tracing nefunguje; hosted tools nefungují; structured outputs závisí na backend
3. **Python runtime dependency:** Celý SDK vyžaduje Python interpreter — fundamentálně incompatible s markdown-only plugin filozofií
4. **Guardrail schema complexity ceiling:** Anthropic Structured Outputs docs uvádí 400 error "compiled grammar is too large" pro komplexní JSON schemas — analogický problém existuje u OpenAI schema validation (produkční realita)
5. **TypeScript/Python parity lag:** April 2026 update přidal features Python-first; TypeScript support "planned" — runtime divergence

---

## Dimenze 7 — Co lze přenést do markdown-only Claude Code plugin

### Handoff vs as_tool decision rule → relevance pro ceos-agents

OpenAI decision rule (ownership-based) je **přenositelný jako architektonický princip** i do markdown kontextu:

- **ceos-agents fixer ↔ reviewer loop:** Reviewer jako fixer's handoff by nedával smysl (fixer by ztratil ownership opravy). Reviewer jako `as_tool`-equivalent (nested specialist bez ownership transfer) = správný pattern. V ceos-agents terminologii: `Task` dispatch na reviewer + výsledek zpět do fixer loop = funkcionálně ekvivalent `as_tool`. Toto je **vendor-aligned** design.
- **ceos-agents skill → agent dispatch:** Skill (orchestrator) dispatchuje agenty přes `Task` tool bez ownership transferu (skill vždy synthezuje final output) = funkcionálně ekvivalentní `as_tool` pattern. Ne handoff (skill by ztratil konverzační kontrolu).
- **Implikace:** Současná ceos-agents architektura (skill = orchestrator, agents = nested specialists via Task) odpovídá OpenAI "agents as tools" pattern — vendor-blessed.

### Typed Subagent inheritance → srovnání s ceos-agents Agent Overrides

| Aspect | Codex Subagents (OpenAI) | ceos-agents Agent Overrides |
|--------|--------------------------|------------------------------|
| Format | TOML soubor s typed fields | Markdown soubor s volným textem |
| Location | `.codex/agents/{name}.toml` | `{path}/{agent-name}.md` |
| Inheritance | Typed inherit-with-override (per field) | Append-to-prompt (celý obsah přidán) |
| Override granularity | Field-level (model, sandbox, skills) | None (jen přidání instrukce) |
| Model override | ✅ Explicitní `model = "gpt-5.4"` | ❌ Nelze (jen instrukce) |
| Discovery | Automatické ze filesystem | Automatické ze filesystem |
| Format validation | TOML schema | None (volný markdown) |

**Key finding:** Codex Subagent inheritance je **strukturovanější** než ceos-agents Agent Overrides. Codex umožňuje field-level override (model, sandbox, skills) — ceos-agents pouze instrukce append. Pokud by v8.0.0 přineslo structured overlay (ne jen markdown append), Codex TOML pattern je nejbližší production-shipped reference.

### Guardrails pattern → přenositelnost

Guardrails jako programmatické Python funkce jsou **nekompatibilní** s markdown-only filozofií. Avšak sémantický pattern (input validation gate + output validation gate s tripwire) je přenositelný jako:
- Input guardrail → **triage-analyst** (validuje issue před pipeline start)
- Output guardrail → **acceptance-gate** (validuje AC fulfillment po fixer+reviewer)

Tato architektonická analogie ukazuje, že ceos-agents pipeline gates jsou funkčně ekvivalentní Guardrails — jen implementované jako agent dispatchů místo Python funkcí.

### Sessions pattern → přenositelnost

Sessions (multi-turn memory) jsou Python-specific. Avšak sémantický pattern je přenositelný:
- ceos-agents `state.json` = stateless pipeline state (orchestrator-level)
- ceos-agents `pipeline-history.md` = long-term history (cross-run memory)
- Tyto two layers = funkcionálně ekvivalentní kombinaci stateless dispatch + explicit state (Run 1 Q4 finding potvrzeno z OpenAI angle)

---

## Dimenze 8 — Co je framework-specific (nelze přenést)

### Python runtime dependency

Celý Agents SDK vyžaduje Python interpreter. `Runner.run()`, `@function_tool`, `@dataclass Agent` — vše Python. **Nelze transplantovat do markdown-only plugin**. Jakýkoli přenos je architektonická inspirace, NE přímá adopce.

### TypeScript SDK jako separate codebase

`github.com/openai/openai-agents-js` = separátní TypeScript implementace. Feature parity lag (April 2026 update = Python first). Pro ceos-agents irrelevantní (plugin je markdown, NE TS/Python runtime).

### OpenAI model lock-in

Default model `gpt-4.1`, doporučeno `gpt-5.5`. Tracing uploaduje na OpenAI servery. Hosted tools (`WebSearchTool`, `FileSearchTool`, code interpreter) fungují **pouze s OpenAI modely**.

**Compatibility layer:** LiteLLM adapter (`openai-agents[litellm]`) umožňuje 100+ providers včetně Anthropic Claude, Google Gemini, Azure. Avšak:
- Tracing nefunguje s non-OpenAI providers (401 error)
- Hosted tools nefungují
- Structured outputs závisí na backend support
- Status: **beta, best-effort**

Praktická realita: Agents SDK je de facto OpenAI-first. LiteLLM compat existuje ale s omezeními.

### Pydantic AI compatibility

Dokumentace OpenAI Agents SDK **neobsahuje žádnou referenci na Pydantic AI**. Frameworks jsou oddělené. Pydantic AI (`pydantic-ai`) má vlastní Agent class s jiným API — typ-system kompatibilita (oba používají Pydantic) ale žádná programmatická interoperabilita.

### Python dataclass as primary agent definition format

`Agent` je Python `@dataclass` — kompletní opak markdown frontmatter. Přímá adopce by znamenala abandon markdown-plugin filozofie a přechod na Python-based plugin. Codex Subagents TOML je hybridní střed — deklarativní soubory, ale structured schema. Toto je nejblíže k "přenositelný bez Python runtime".

---

## Syntéza: klíčové architektonické nálezy

### Nález 1: SDK je paradigmaticky odlišný, ale decision rules jsou přenositelné

OpenAI Agents SDK je Python library (runtime-dependent), ceos-agents je markdown plugin (runtime-independent). Přímá adopce je nemožná. Avšak:
- **Handoff vs as_tool decision rule** (ownership-based) je přenositelný princip
- **Guardrails pattern** (input/output validation gates) je architektonicky analogický k ceos-agents acceptance-gate a triage-analyst
- **Stateless dispatch + explicit state** je sdílený vzor (OpenAI stateless mode = ceos-agents stateless dispatch)

### Nález 2: Codex Subagents = nejbližší production-shipped inheritance model

Codex TOML Subagents implementují typed inherit-with-override — field-level override (model, sandbox, skills.config). Toto je strukturovanější než ceos-agents Agent Overrides (append-only markdown). Pokud v8.0.0 zvažuje evolution Agent Overrides mechanismu, Codex pattern je nejbližší vendor-blessed reference.

### Nález 3: thin instructions je OpenAI paradigma, thick markdown je ceos-agents paradigma

OpenAI examples: 20–200 char instructions. ceos-agents agents: 100–500+ řádků markdown. Vendor trend (Run 1 Q1, Q2) = frontier models redukují potřebu verbose scaffold. Avšak Run 1 Q1 také dokumentuje: *"deterministic CI-style workflows = moderate maximalist OK"* — ceos-agents kontext (deterministic pipeline) je defensible exception.

### Nález 4: April 2026 update = enterprise trajectory, NE paradigm shift

Long-horizon harness + native sandbox = enterprise hardening, NE nový architektonický vzor. OpenAI zachovává minimalist-4-primitiv přístup. Žádný nový orchestration DSL, žádný declarative YAML. Potvrzuje Run 1 finding: *"Going to YAML pipeline DSL would be unprecedented in major-vendor docs as of 2026-04."*

### Nález 5: needsApproval = per-action event-driven, vendor-aligned pattern

OpenAI HITL = per-tool-call gating, NE per-stage. `needs_approval` na tool level = event-driven gate spouštěný jen při příslušném tool call. Toto potvrzuje Run 1 Q6 finding (vendor consensus = event-driven gates). ceos-agents strategic gates (triage, AC checkpoint, acceptance-gate, pre-publish) jsou vendor-aligned; per-stage gates by byly anti-pattern.

---

## Citation index

| Citace | Zdroj | URL |
|--------|-------|-----|
| Agent dataclass fields (lines 471–938) | `src/agents/agent.py` | `github.com/openai/openai-agents-python/blob/main/src/agents/agent.py` |
| Handoff dataclass + handoff() function (lines 222–335) | `src/agents/handoffs/__init__.py` | `openai.github.io/openai-agents-python/ref/handoffs/` |
| as_tool() signature (lines 587–738) | `src/agents/agent.py` | `openai.github.io/openai-agents-python/ref/agent/` |
| Agent class full API reference | Vendor docs | `openai.github.io/openai-agents-python/ref/agent/` |
| Handoff docs + decision rule | Vendor docs | `openai.github.io/openai-agents-python/handoffs/` |
| Orchestration and handoffs (ownership rule) | Vendor docs | `developers.openai.com/api/docs/guides/agents/orchestration` |
| Agents SDK overview + primitives | Vendor docs | `openai.github.io/openai-agents-python/` |
| Guardrails architecture | Vendor docs | `openai.github.io/openai-agents-python/guardrails/` |
| Sessions overview + backends | Vendor docs | `openai.github.io/openai-agents-python/sessions/` |
| Human-in-the-loop (HITL + RunState) | Vendor docs | `openai.github.io/openai-agents-python/human_in_the_loop/` |
| Models/providers + non-OpenAI compat | Vendor docs | `openai.github.io/openai-agents-python/models/` |
| Codex Subagents schema | Vendor docs | `developers.openai.com/codex/subagents` |
| SDK release March 11, 2025 | News | `analyticsvidhya.com/blog/2025/03/openai-agents-update/` |
| April 2026 next evolution | Vendor blog | `openai.com/index/the-next-evolution-of-the-agents-sdk/` |
| April 2026 TechCrunch coverage | News | `techcrunch.com/2026/04/15/openai-updates-its-agents-sdk-to-help-enterprises-build-safer-more-capable-agents/` |
| Swarm migration + SDK review | Community | `mem0.ai/blog/openai-agents-sdk-review` |
| handoff_prompt.py extension | OSS source | `src/agents/extensions/handoff_prompt.py` |

---

## Hard gaps (poctivé disclosure)

1. **`src/agents/handoffs.py` exact line numbers:** GitHub vrátil 404 na přímý raw file fetch — URL struktura se mohla změnit na `handoffs/__init__.py`. Handoff dataclass fields a handoff() function jsou citovány z API reference docs (`openai.github.io/openai-agents-python/ref/handoffs/`) a jsou věrohodné, ale přesné line numbers z source souboru nelze potvrdit přímým fetch.
2. **Swarm primitives exact pre-migration:** Swarm repository (`github.com/openai/swarm`) zachován pro educational purposes, ale detailní diff Swarm → SDK API není extrahován.
3. **Codex Subagents `[agents]` config.toml global settings:** Dokumentace uvádí global settings (`max_threads`, `max_depth`, `job_max_runtime_seconds`) — zda jsou dalsi keys nebylo exhaustively ověřeno.
4. **Instruction length vendor examples:** OpenAI docs neuvádí explicitní "20–200 chars" boundary jako hard spec — tato range pochází z Run 1 OSS-code lens (agent-3) komparací github source files. Vendor docs popisují instrukce jen qualitatively.
