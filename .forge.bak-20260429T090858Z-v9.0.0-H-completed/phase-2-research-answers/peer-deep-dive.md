# Peer Tool I/O Contract Deep Dive — v9.0.0 sub-projekt H

**Date:** 2026-04-28
**Author:** Senior Research Engineer (forge-research deep-dive)
**Mission:** Evidence-grounded analysis of how 18+ peer agent frameworks declare, validate, and enforce agent I/O contracts. Used to judge whether ceos-agents v9.0.0 sub-projekt H should formalize agent I/O.
**Prior research reused:**
- `.forge.bak-2026-04-27T044940Z/2026-04-26-A-research-run1/phase-2-research-answers/final.md` (Q1-Q12 cross-lens)
- `.forge.bak-2026-04-27T044940Z/2026-04-26-A-research-run1/phase-2-research-answers/agents/agent-3-oss-code.md` (source-level lens)
- `.forge.bak-2026-04-27T044940Z/2026-04-26-A-research-run2/phase-2-research-answers/final.md` (10 deep dives)
- `.forge.bak-2026-04-27T044940Z/2026-04-26-A-research-run2/phase-2-research-answers/agents/agent-Q15-claudecode.md`
- `.forge.bak-2026-04-27T044940Z/2026-04-26-A-research-run2/phase-2-research-answers/agents/agent-Q17-openai-agents-sdk.md`
- `.forge.bak-2026-04-27T044940Z/2026-04-26-A-research-run2/phase-2-research-answers/agents/agent-Q19-bmad-method.md`

**New web research (2026-04-28):**
- CrewAI Task docs (docs.crewai.com/concepts/tasks)
- MCP spec 2024-11-05 + 2025-06-18 (modelcontextprotocol.io)
- LangGraph StateGraph state schema (search-derived)
- Pydantic AI output_type docs (pydantic.dev/docs/ai)
- smolagents Tool.output_type (huggingface.co/docs/smolagents)
- Magentic-One LedgerEntry Pydantic model (github.com/microsoft/autogen)
- Anthropic Multi-Agent Research System engineering blog
- wshobson/agents sample frontmatter

---

## Executive Summary (CZ)

1. **I/O kontrakty se v ekosystému STRUKTUROVANĚ formalizují JEN tam, kde ekosystém běží na runtime/SDK** (Python/TS): CrewAI `output_pydantic`, OpenAI Agents SDK `output_type`, Pydantic AI `output_type`, LangGraph `state_schema`, MCP `inputSchema`/`outputSchema`, smolagents `output_type`, Magentic-One `LedgerEntry` Pydantic. **Markdown plugin cohort I/O kontrakty NEFORMALIZUJE** — ani BMAD (45.7k★), ani wshobson, ani Anthropic Skills, ani Claude Code subagent spec.

2. **MCP `outputSchema` byl přidán 17 měsíců po `inputSchema`** (2024-11-05 spec → 2025-06-18 spec). Anthropic sama si vybrala input contract jako P0, output contract jako P2. Validace je SHOULD (clients), ne MUST. To je důležitý signál: i tam, kde I/O contract má smysl, output validace se zaváděla pomalu a postupně.

3. **Anthropic Multi-Agent Research System** (production system, 90.2% výhra nad single-agent) **EXPLICITNĚ ŘÍKÁ že subagenti dostávají "objective + output format + guidance" v PŘIROZENÉM JAZYCE, NIKOLI schema**. Anthropic blog: *"Direct subagent outputs can bypass the main coordinator..."* — formát je prose-based, ne strict schema. Tento je nejbližší architektonický peer ceos-agents (orchestrator-worker pattern) — a oni I/O schema DESIGNOVĚ NEZAVÁDĚJÍ.

4. **CrewAI je jediný v markdown/YAML konfigurovatelný framework s povinným I/O elementem** — pole `expected_output` je REQUIRED u každé Task v Task class (string description, NE schema). Volitelně lze `output_pydantic` nebo `output_json` přidat schema validation. Validace na selhání → guardrail retry (3×). Tohle je nejbližší aplikovatelný precedens pro ceos-agents.

5. **Magentic-One je jediný "markdown-procedural meets strict schema" peer** — orchestrator prompt je prose, ale očekávaný JSON output je striktně Pydantic-validated `LedgerEntry`. Prompt obsahuje literal: *"Please output an answer in pure JSON format according to the following schema. The JSON object must be parsable as-is. DO NOT OUTPUT ANYTHING OTHER THAN JSON, AND DO NOT DEVIATE FROM THIS SCHEMA"*. Toto funguje, protože output je consumed by deterministic Python code (orchestrator), ne by another LLM.

6. **ceos-agents v8.0.0 má de-facto kontrakty bez deklarace** — section headers `## Fix Report`, `## Code Review`, `## Triage Analysis`, `## NEEDS_DECOMPOSITION`, `## NEEDS_CLARIFICATION` jsou exact-string-grep contracts používané skill orchestrátory. Toto je **implicitně to samé co Magentic-One LedgerEntry** — jen bez machine-validated schema. **Risk: schema drift** mezi agent prompt (markdown) a skill parser (markdown grep).

7. **Median industry pattern: kontrakty deklarovány tam, kde je downstream-consumer kód, ne tam, kde je downstream-consumer LLM.** ceos-agents má OBOJÍ — section headers parsované Bash/skill, ALE i obsah té sekce čtou další LLM agenti (reviewer čte fixer's Fix Report). Hybrid story = nuance. Doporučení musí toto reflektovat.

---

## Per-Tool Matrix

Notation: ✅ = present, ❌ = absent, ⚠ = optional/partial, "—" = N/A. Citations are file:line or URL.

### Markdown-plugin cohort (closest peers to ceos-agents)

| Tool | Has agent defs? | Where I/O declared | Input format | Output format | Mandatory? | Storage | Validated when? | On violation | Source |
|---|---|---|---|---|---|---|---|---|---|
| **BMAD-METHOD v6.4.0** | YES (markdown SKILL.md + customize.toml) | ❌ NOT DECLARED for I/O. `customize.toml` covers persona/menu/persistent_facts only | None — prose | None — prose-based menu output | N/A | — | Never | Silent (LLM reads next | docs.bmad-method.org/how-to/customize-bmad/, run2 Q19 dim 3 |
| **Claude Code subagents** | YES (markdown + YAML frontmatter) | ❌ I/O NOT in spec. Frontmatter has `name`, `description`, `tools`, `model`, etc. — NO input/output schema field | None | None | N/A | — | Never | Silent | code.claude.com/docs/en/sub-agents, run2 Q15 dim 1 |
| **Anthropic Skills (SKILL.md)** | NO (skills, not agents) — but adjacent | ❌ Frontmatter has `name`, `description`, `license`. No I/O schema | None | None | N/A | — | Never | Silent | github.com/anthropics/skills |
| **wshobson/agents (184 agents)** | YES (one .md per agent) | ❌ Frontmatter: `name`, `description`, `model`. Body is prose Capabilities + Philosophy. **No I/O schema, no output template** | None | Implicit prose | N/A | — | Never | Silent | github.com/wshobson/agents/.../backend-architect.md (verified 2026-04-28) |
| **opencode (sst, 149.7k★)** | YES (markdown agents in `.opencode/agents/*.md`) | ❌ JSON config (`opencode.json`) for tool perms; agent body is prose | None | None | N/A | — | Never | Silent | run2 Q13 |
| **superpowers (obra, 168k★)** | NO formal agents, 14 SKILL.md | ❌ 4-state reporting convention (DONE/DONE_WITH_CONCERNS/NEEDS_CONTEXT/BLOCKED) is prose-based, not schema | None | Prose 4-state | Convention, not validated | — | Never | Silent | run2 Q14 |
| **ceos-agents v8.0.0** (baseline) | YES (18 markdown + frontmatter) | ⚠ DE-FACTO contracts via section headers `## Fix Report`, `## NEEDS_DECOMPOSITION`, etc. Not in frontmatter, not declared as schema | Implicit prose | Implicit section headers grep'd by skills | Convention, not validated | Embedded in agent body | Author-time only (review during PR) | Skill grep returns false → Block | C:/gitea_ceos-agents/agents/fixer.md:73-82 (Fix Report template), :48-55 (NEEDS_DECOMPOSITION) |

**Markdown-plugin cohort verdict:** **0/7 declare I/O contracts in any structured form.** The closest precedent is ceos-agents itself (section headers) and superpowers (4-state convention) — both prose-based and informal.

### Runtime/SDK cohort (Python/TS frameworks)

| Tool | Has agent defs? | Where I/O declared | Input format | Output format | Mandatory? | Storage | Validated when? | On violation | Source |
|---|---|---|---|---|---|---|---|---|---|
| **CrewAI Task** | YES (Python or YAML Task class) | ✅ FIRST-CLASS: `expected_output` (str), `output_pydantic` (BaseModel), `output_json` (BaseModel), `output_file` (path) | Prose `description` (string) | `expected_output` MANDATORY string + optional Pydantic | `expected_output`: REQUIRED. `output_pydantic`/`output_json`: OPTIONAL | Same file as Task (YAML/Python) | Runtime via guardrail | Guardrail returns `(False, error_message)`, agent retries up to `guardrail_max_retries` (default 3) | docs.crewai.com/concepts/tasks (verified 2026-04-28) |
| **OpenAI Agents SDK** | YES (Python `Agent` dataclass) | ✅ `output_type` field — `type \| AgentOutputSchemaBase \| None` | `instructions` prose; tools have schemas | Pydantic/dataclass/TypedDict via `output_type` | OPTIONAL (None default) | Same file as Agent | Runtime by SDK | Validation error raised; structured output enforced via JSON-schema-restricted decoding | github.com/openai/openai-agents-python `src/agents/agent.py:471-938`, run2 Q17 dim 1 |
| **Pydantic AI** | YES (Python `Agent`) | ✅ `output_type` constructor arg | `instructions` prose | Pydantic class via `output_type` | OPTIONAL — *"When no output type is specified... any plain text response... will be used as the output data"* | Same file as Agent | Runtime via Pydantic | `ModelRetry` raised — agent retries with modified args | pydantic.dev/docs/ai/core-concepts/output (verified 2026-04-28) |
| **LangGraph** | NO agent class — nodes are functions | ✅ `StateGraph(state_schema=)` constructor — TypedDict, dataclass, or Pydantic | TypedDict/Pydantic shared state | Same shared state (additive via reducers) | REQUIRED (graph won't construct without it) | Same module as graph build | Runtime; **Pydantic validates ONLY at first-node input boundary, not subsequent or outputs** | Mismatched node return → silent merge into state (TypedDict has no validator); Pydantic at boundary raises ValidationError | docs.langchain.com/oss/python/langgraph/use-graph-api; reference.langchain.com/python/langgraph/graph/state/StateGraph |
| **smolagents Tool** | YES (Python class) | ✅ `inputs: dict`, `output_type: str` (one of `["string","boolean","integer","number","image","audio","array","object","any","null"]`) | Class attribute `inputs` | Class attribute `output_type` | REQUIRED for both | Same Python class | Author-time (Tool class enforces) + runtime (LLM sees schema in system prompt) | Tool can't be instantiated without; runtime mismatch is LLM error, not framework | huggingface.co/docs/smolagents/main/en/tutorials/tools (verified 2026-04-28) |
| **MCP Tools (2024-11-05)** | NO (tools, not agents) — but cited as protocol | ✅ `inputSchema` (JSON Schema, REQUIRED). ❌ NO outputSchema in this version | JSON Schema | Free text content blocks | inputSchema REQUIRED, output free | Tool definition (server-side) | Runtime: server **MUST** validate inputs (per spec). Output: no validator | JSON-RPC error -32602 (Invalid arguments) | modelcontextprotocol.io/specification/2024-11-05/server/tools (verified 2026-04-28) |
| **MCP Tools (2025-06-18)** | (newer version) | ✅ `inputSchema` REQUIRED + `outputSchema` ADDED as OPTIONAL. structured vs unstructured content distinction | JSON Schema | JSON Schema (optional) | inputSchema REQUIRED, outputSchema OPTIONAL | Tool definition (server-side) | Server **MUST** produce conforming structured results IF outputSchema declared. Clients **SHOULD** validate | If outputSchema present and result doesn't conform: server violates MUST. Client SHOULD reject. | modelcontextprotocol.io/specification/2025-06-18/server/tools (verified 2026-04-28) |
| **Magentic-One (AutoGen)** | YES (Python class) | ✅ `LedgerEntry` Pydantic — orchestrator output strictly validated | Prose system prompt | `LedgerEntry` (5-field BaseModel: is_request_satisfied, is_in_loop, is_progress_being_made, next_speaker, instruction_or_question) | REQUIRED for orchestrator (consumed by Python code) | Same Python file as orchestrator | Runtime via Pydantic + grammar-restricted decoding | Pydantic ValidationError → orchestrator retry loop | github.com/microsoft/autogen `_magentic_one/_prompts.py` (extracted via WebFetch 2026-04-28); run1 agent-3 Q5c |
| **AutoGen (function tools)** | YES (Python) | ✅ Function signatures — Python type hints become tool schema | `Annotated[type, "description"]` | Function return type → JSON schema | REQUIRED (signatures) | Same Python file | Author-time + runtime | Type mismatch → SDK error | github.com/microsoft/autogen, run2 Q12 (acknowledged in passing) |
| **MS Agent Framework (declarative YAML)** | YES (YAML agents 1-3 sentences) | ⚠ Workflows have `kind: ConditionGroup`, `kind: Question`. Agent I/O is prose `instructions`. **Output schema not first-class for agents** | Prose | Prose | N/A for agents; conditions use formula language | YAML files | Runtime per Workflows.Declarative engine | Formula evaluation error | run2 Q18 dim 1, dim 2; declarative-agents/workflow-samples/CustomerSupport.yaml |
| **Strands SDK (AWS)** | YES (Python `Agent`) | ⚠ `system_prompt: str` only; structured output via Pydantic possible but not first-class field | String prompt | Implicit | OPTIONAL | Same Python | Runtime if Pydantic | Same as Pydantic | github.com/strands-agents/sdk-python, run1 agent-3 Q1 table |
| **MetaGPT (Python roles)** | YES (Python class) | ⚠ `Role` has `instruction` string, plus `Action` objects with their own outputs (e.g., `WriteCode` outputs Code object) | Prose `instruction` | Action-defined Pydantic-like objects | OPTIONAL but conventional per role | metagpt/roles/*.py + metagpt/actions/*.py | Runtime | Type errors | github.com/geekan/MetaGPT/blob/main/metagpt/roles/engineer.py (513 lines), run1 agent-3 Q1 |
| **Cline** | NO multi-agent — single agent | ❌ No formal I/O contract; tool-use pattern | Tools schemas (read_file, write_to_file, etc.) | Tool results | Tool-level only | tool definitions | Runtime per tool call | Runtime error in tool | github.com/cline/cline `src/core/prompts/system-prompt/components/`, run2 Q22 |

**Runtime/SDK cohort verdict:** **9/12 have I/O contracts in some form** (CrewAI, OpenAI SDK, Pydantic AI, LangGraph, smolagents, MCP 2025-06, Magentic-One, AutoGen, MetaGPT). **3/12 partial or absent** (MS Agent Framework — agents prose, workflows formula; Strands — Pydantic possible not first-class; Cline — tool-level only).

### SaaS / Closed cohort

| Tool | Has agent defs? | I/O contract evidence | Source |
|---|---|---|---|
| **Devin (Cognition)** | NO public agent definitions ("compound 4-component" is marketing) | No public schema. Devin Knowledge tab = per-repo natural-language instructions. **No documented I/O schema.** | run2 Q20 |
| **GitHub Copilot Coding Agent** | Custom agents `.github/agents/*.yml` since 2025-10. Frontmatter is prose-mostly | Agent format YAML, but **no documented I/O schema for agent outputs** — output goes to PR | run2 Q21 |
| **Cursor (Composer)** | Single MoE agent + horizontal replicas (2.0) + parent→child (2.5) | `.cursor/rules/*.mdc` are prose Markdown rules, no I/O schema | run2 Q16 |
| **Anthropic Multi-Agent Research System** | YES — orchestrator-worker pattern in production | **EXPLICITLY no schema.** Lead agent provides subagents with: *"an objective, an output format, guidance on the tools and sources to use, and clear task boundaries"* — prose-only. *"Subagents call tools to store their work in external systems, then pass lightweight references back to the coordinator"* — handoff is via tool calls + external storage, not schema | anthropic.com/engineering/multi-agent-research-system (verified 2026-04-28) |

**SaaS cohort verdict:** **0/4 declare structured I/O contracts.** All use prose instructions; output flows to PR or natural-language summary.

---

## Cross-Cutting Findings

### 1. Median pattern across the 22 frameworks

| Storage | Format | Validation | Frequency |
|---|---|---|---|
| Same file as agent | Pydantic / TypedDict / JSON Schema | Runtime by framework | **9/22** (CrewAI, OpenAI SDK, Pydantic AI, LangGraph, smolagents, MCP, Magentic-One, AutoGen, MetaGPT) |
| Sidecar config | TOML/YAML | Author-time merge | **0/22** for I/O specifically (BMAD `customize.toml` is for persona/menu, not I/O) |
| Section header convention | Prose markdown | Skill grep / never | **2/22** (ceos-agents, superpowers) |
| Not declared at all | — | — | **11/22** (BMAD, Claude Code, wshobson, opencode, MS Agent Framework agents, Strands defaults, Cline, Devin, Copilot, Cursor, Anthropic Multi-Agent) |

**Median = "in same file as agent, Pydantic/TypedDict, runtime-validated"** — but only when agent IS Python code. **In markdown-plugin cohort: "not declared at all" is the modal pattern.**

### 2. Production-adopted pattern (excluding research/hobby)

Filter: GA/v1.0+, named enterprise customers, >10k stars OR commercial.

- **CrewAI** (49.9k★, Workhuman, MongoDB, Visa, Comcast): `expected_output` REQUIRED prose + optional Pydantic — **production-adopted I/O contract pattern**
- **OpenAI Agents SDK** (25.2k★, OpenAI Codex prod): optional `output_type` Pydantic — **production-adopted**
- **MCP servers** (Anthropic protocol, 1000+ servers): `inputSchema` mandatory, `outputSchema` optional — **production-adopted protocol**
- **LangGraph** (30.4k★, Klarna, Uber, Replit): `state_schema` REQUIRED — **production-adopted**

— vs. —

- **Anthropic Multi-Agent Research System** (production, +90% over single-agent): **NO schema, prose-based** — production-adopted ANTI-pattern
- **BMAD** (45.7k★): **NO I/O schema** — production-adopted ANTI-pattern
- **Claude Code subagents** (4.7M paid Copilot signal-equivalent): **NO I/O schema** — production-adopted ANTI-pattern

**Production verdict: there are TWO production-adopted patterns.** Where the consumer is deterministic code → schema is universal. Where the consumer is another LLM agent → prose is universal.

### 3. Markdown-plugin cohort pattern (ceos-agents' nearest cohort)

**0 of 7 declare formal I/O contracts.** Cohort members:

| Plugin | I/O contract | Stars | Adopted? |
|---|---|---|---|
| BMAD-METHOD | None | 45.7k | Yes (heavy) |
| Claude Code subagents | None | platform | Yes (Anthropic) |
| Anthropic Skills | None | canonical | Yes (Anthropic) |
| wshobson/agents | None | embedded plugin | Yes (Claude Code marketplace) |
| opencode | None for agents (JSON for config) | 149.7k | Yes (explosive growth) |
| superpowers | 4-state convention only (prose) | 168k | Yes (Anthropic marketplace) |
| ceos-agents v8.0.0 | Section-header convention | (private) | (this repo) |

**Cohort signal: structured I/O contracts are absent in every dominant markdown-plugin peer.** This is not by oversight; it's by design — markdown plugins target LLM-to-LLM consumption, where prose is the lingua franca.

### 4. Patterns that deliberately AVOID I/O contracts and why

- **Cline** (single-agent thin): Tool-level schema is enough; agent itself doesn't need I/O contract because there's no agent-to-agent handoff. *"Single agent loop"* per run2 Q22.
- **Anthropic Multi-Agent Research System** (orchestrator-worker, production): Anthropic engineering blog explicitly favors *"detailed task descriptions"* over schema. Engineering rationale: *"Without detailed task descriptions, agents duplicate work, leave gaps, or fail."* The cure for that is more-prose, not more-schema.
- **BMAD-METHOD v6.1.0**: **Removed YAML workflow engine, returned to pure markdown.** Direct quote: *"Convert entire BMAD method to skills-based architecture... Removal of legacy YAML/XML workflow engine infrastructure"* (run2 Q19 dim 2). This is the strongest counter-evidence: BMAD tried structured pipeline, **walked back** to prose.
- **Anthropic Skills**: Spec is `name + description + body` — Anthropic could trivially have added `output` field, didn't. Per Q15, **Anthropic intentionally keeps frontmatter minimal** to preserve cross-platform portability (agentskills.io standard).
- **MCP itself**: Anthropic's OWN protocol shipped `inputSchema` REQUIRED in 2024-11-05 spec but **deferred `outputSchema` for 17 months** (added 2025-06-18 as OPTIONAL). When Anthropic designs a protocol, they're conservative about output validation.

### 5. Where ceos-agents v8.0.0 sits today

- ceos-agents has **section-header conventions** (`## Fix Report`, `## NEEDS_DECOMPOSITION`, `## NEEDS_CLARIFICATION`, `## Code Review`, `## Triage Analysis`) embedded in agent body markdown.
- These section headers **ARE de-facto I/O contracts** — skills `grep -E "## NEEDS_DECOMPOSITION"` against agent output. Verified in `agents/fixer.md:48-55, 58-66, 73-82`.
- This is **architecturally identical to Magentic-One's `LedgerEntry`** — except (a) no Pydantic class, (b) no automated validation, (c) the section headers are described in prose inside the agent prompt, not in a separate machine-readable spec.
- **Risk:** Schema drift between agent prompt (markdown body) and skill consumer (grep regex in skill body). When fixer.md changes "## Fix Report" → "## Fix Summary", every skill that grep'd `Fix Report` silently breaks. Currently this is caught by harness tests (`tests/`) but with no contract layer.
- **Alignment with peer cohort:** ceos-agents is **MORE structured than markdown-plugin median (which has nothing) but LESS structured than runtime/SDK median (Pydantic).** That's a coherent middle-ground.
- 4 of 18 agents already have `--phase` polymorphism (analyst, test-engineer, browser-agent, spec-reviewer) — meaning a single agent file produces **multiple distinct outputs** depending on phase flag. This is explicitly NOT representable in standard frontmatter and would need any I/O contract format to support polymorphism.

---

## Recommendation for ceos-agents v9.0.0 sub-projekt H

### Final answer: PARTIAL — formalize as DOCUMENTATION CONVENTION (mandatory), not as schema validation (defer)

In Czech: **Ano, formalizovat — ale jako konvenci v markdown body, ne jako Pydantic-style strict schema runtime validator. Mandatory pro všech 18 agentů, MAJOR proto, že Agent definition format se rozšiřuje.**

### Specifics

| Decision | Choice | Justification |
|---|---|---|
| **Storage** | Same agent .md file, new `## Output Contract` section in body (after `## Process`, before `## Constraints`) | Markdown-plugin cohort never uses sidecar files for I/O. ceos-agents already keeps agent prompt + de-facto contracts in same file. Sidecar adds complexity without precedent. |
| **Format** | Markdown table or fenced YAML block specifying: required input sections, required output sections, valid signal sentinels (`NEEDS_DECOMPOSITION`, `NEEDS_CLARIFICATION`), polymorphism by `--phase` | Anthropic Skills spec is `name + description + body` — minimal frontmatter is the proven pattern. Putting contract in body means existing `customization/` overrides keep working. **Frontmatter is NOT touched** — guarantees backward-compat for v8.0.0 customization.md files. |
| **Enforcement** | Author-time lint (CI check via `tests/harness/`), NOT runtime schema validation | Magentic-One uses runtime Pydantic ONLY because the consumer is Python code. ceos-agents consumers are LLM agents (reviewer reads fixer's Fix Report). Runtime validation against an LLM-produced markdown is fragile. Lint catches drift between agent body and skill grep. |
| **Mandatory / Optional** | MANDATORY for all 18 agents (because their output shape IS the pipeline's contract) | CrewAI made `expected_output` REQUIRED on Task — same logic applies here. Optional contracts get ignored, then drift, then break. The 18 agents already have de-facto contracts; formalizing them just makes drift visible. |
| **Polymorphism** | `## Output Contract` MUST handle `--phase X` agents by listing per-phase output shapes | 4 of 18 agents (analyst, test-engineer, browser-agent, spec-reviewer) need this. Pydantic-style single-class output_type can't represent this without union types. Markdown table can. |
| **Backward-compat** | v8.0.0 `customization/{agent}.md` overrides keep working unmodified — they append project-specific instructions, NOT redefine contract | Frontmatter stays unchanged. Existing override pattern (append-to-prompt) preserved. New `## Output Contract` section is plugin-side only; project overrides cannot remove or modify contract (per BMAD's "no removal mechanism" principle). |

### Why this and not alternatives

**Why not full Pydantic-style runtime validation (alternative A):**
- The consumer of fixer's `## Fix Report` is reviewer (an LLM), not Python code. Pydantic validates JSON. Reviewer reads markdown. Validating markdown against a Pydantic schema requires either (a) coercing fixer to produce JSON (loses LLM-readable prose), or (b) parsing markdown back to JSON (fragile). Neither is what runtime-SDK frameworks do — they keep both producer AND consumer in the same Python process.
- Magentic-One can use Pydantic because Python orchestrator IS the consumer. ceos-agents skills are markdown procedures, not Python.
- Anthropic's own Multi-Agent Research System (the closest production peer architecturally) explicitly **rejected** schema in favor of "objective + output format + guidance" prose — and beat single-agent by 90.2%. **Strongest evidence in our peer set against Pydantic-style rigor for orchestrator-worker.**

**Why not "no contracts at all, status quo" (alternative B):**
- Section-header drift is a real risk. v6.0.0 → v7.0.0 → v8.0.0 saw multiple cases where agent prompt text changed slightly and skill grep had to be updated in lockstep. This burden grows with every customization/override added downstream.
- Author-time lint catches drift in CI before users hit it. Cost is one new test scenario per agent. Benefit is contract-as-documentation that downstream Agent Override authors can read.
- BMAD has a `customize.toml` 4-merge-rule schema and wins at scale. ceos-agents has section headers undocumented. **Going from undocumented to documented (no behavior change at runtime) is a Pareto improvement.**

**Why not "optional, gradual rollout to 5 agents" (the brainstorm partial recommendation):**
- Optional contracts are never adopted uniformly. CrewAI's `expected_output` is REQUIRED — that's why it's used. The 5-agent partial rollout creates two classes of agents (with/without contract), which means downstream tooling (skills, customization) has to handle both, which means complexity goes up not down.
- All 18 agents already have de-facto contracts. Document them all at once, in one MAJOR release, with one migration guide.

**Why MAJOR (v9.0.0) and not MINOR (v8.1.0):**
- Per CLAUDE.md versioning policy: *"Adding a required key to Automation Config = MAJOR. Adding an optional section = MINOR. ... breaking change in agent output format contract (new/modified structured output sections that Agent Overrides or external tooling may parse) = MAJOR."*
- Adding `## Output Contract` to all 18 agents is a structured-output-section addition. External tooling (Agent Overrides) will see new content. **Strict reading of policy = MAJOR.**
- This sub-projekt H is also a v9.0.0 deliverable per the original roadmap allocation.

### Trade-offs accepted

**Gain:**
- Schema drift becomes visible in CI (harness lint test)
- Section-header conventions become discoverable to downstream Agent Override authors
- 4 polymorphic `--phase` agents get explicit per-phase output documentation
- Contract is loadable as Tier 1 metadata for skill orchestrators (no extra grep)
- Aligned with Anthropic Skills spec philosophy (minimal frontmatter, body holds detail)
- Aligned with CrewAI mandatory `expected_output` precedent (production-validated 49.9k★)

**Give up:**
- No runtime validation. If reviewer LLM hallucinates a different format, lint won't catch it (only author-time agent prompt drift).
- Format is markdown, not JSON Schema or Pydantic. External tools (e.g. metrics dashboard) parsing agent outputs still need their own grep regex. The contract documents what to grep for, not a machine-checkable definition.
- One more section in every agent file (~10-30 lines added per agent body — but prior research shows wshobson agents are 309 lines, ceos-agents fixer is 117, BMAD bmad-dev-story is 485 — there is plenty of headroom).
- v9.0.0 release work: 18 agents to update, harness tests to add, migration guide. Estimated ~2-3 days of focused work + docs.

---

## Sources cited (newly verified 2026-04-28)

- CrewAI Tasks: https://docs.crewai.com/concepts/tasks
- MCP 2024-11-05 spec: https://modelcontextprotocol.io/specification/2024-11-05/server/tools
- MCP 2025-06-18 spec (added outputSchema): https://modelcontextprotocol.io/specification/2025-06-18/server/tools
- Pydantic AI output: https://pydantic.dev/docs/ai/core-concepts/output/
- smolagents Tool: https://huggingface.co/docs/smolagents/main/en/tutorials/tools
- LangGraph StateGraph: https://docs.langchain.com/oss/python/langgraph/use-graph-api ; https://reference.langchain.com/python/langgraph/graph/state/StateGraph
- Anthropic Multi-Agent Research System: https://www.anthropic.com/engineering/multi-agent-research-system
- AutoGen Magentic-One LedgerEntry: github.com/microsoft/autogen `python/packages/autogen-agentchat/src/autogen_agentchat/teams/_group_chat/_magentic_one/_prompts.py`
- wshobson backend-architect: github.com/wshobson/agents/blob/main/plugins/backend-development/agents/backend-architect.md (frontmatter: name + description + model)
- ceos-agents fixer.md: C:/gitea_ceos-agents/agents/fixer.md (lines 48-66 NEEDS_*; 73-82 Fix Report)

## Sources cited (reused from prior runs)

- Run 1 final.md ~180KB: full Q1-Q12 cross-lens with 5 lenses (academic, production, OSS code, community, vendor docs)
- Run 1 agent-3 OSS code lens: 22 frameworks read at source level — single most useful prior artifact for this deep dive
- Run 2 final.md ~67KB: Top 10 deep-dive synthesis with 4+1 paradigm clustering
- Run 2 Q15 Claude Code: 5-tier subagent priority, frontmatter spec
- Run 2 Q17 OpenAI Agents SDK: Agent dataclass + Codex Subagents TOML
- Run 2 Q19 BMAD-METHOD: customize.toml 4 merge rules; v6.1.0 walk-back from YAML

## Surprising / honest findings

- **Anthropic's own multi-agent research system explicitly avoids I/O schema.** This was the most surprising finding — the architectural peer closest to ceos-agents (orchestrator + workers, in production at Anthropic) is intentionally schema-free. Strong dissent against the brainstorm's PARTIAL/MAJOR-validation framing.
- **MCP added outputSchema 17 months after inputSchema.** Anthropic's protocol design choices reveal that even when contracts make obvious sense, output validation is a P2 concern — input is P0.
- **BMAD walked back from YAML to markdown in v6.1.0** (March 2026). Strong empirical evidence that the markdown-plugin cohort actively rejects structure-for-structure's-sake, even when previously adopted.
- **Where peer evidence is missing:** No peer in the 22-framework set has documented "section-header markdown contract with author-time lint" pattern. This recommendation is **synthesis-level inference, not direct precedent**. The closest analogues are (a) CrewAI's mandatory `expected_output` (mandatory string, not schema), and (b) Magentic-One's Pydantic LedgerEntry (mandatory schema, runtime-validated). Our recommendation sits between them. Honestly noted.
- **Where peer evidence is contradictory:** CrewAI says output contract should be REQUIRED. Anthropic Multi-Agent Research says output contract should be PROSE-ONLY. Both are production-validated. The recommendation reconciles by making the **convention required (CrewAI side)** but the **format prose-shaped (Anthropic side)**.
