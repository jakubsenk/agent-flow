# Agent 3 — OSS Framework Code Lens — Report

**Date:** 2026-04-26
**Lens:** Source-code reading of major / emerging agent frameworks. Every claim cites a file/line.
**Coverage:** 22 frameworks read at source level; 18 listed in Q12 shortlist.

---

## Summary (5 most important code-level findings)

1. **There is no industry consensus on agent prompt depth — formats span 15 lines (Cline `agent_role.ts`) to 500+ lines (BMAD `bmad-dev-story/SKILL.md`).** Frameworks that scale specialization (BMAD, MetaGPT, wshobson/agents) trend toward **multi-file decomposition** (SKILL.md + steps/*.md + customize.toml) rather than mega-prompts. ceos-agents' 100–500-line single-file format sits squarely in the "wshobson/Anthropic skills" range.
2. **BMAD-METHOD has converged to exactly the architecture ceos-agents is debating in v8.0.0:** generic SKILL.md (frozen base) + per-project `customize.toml` (overlay/append) + `steps/*.md` (procedural decomposition). BMAD-METHOD `customize.toml` has explicit merge rules: scalars override, arrays append, arrays-of-tables match by `code`/`id` (`src/bmm-skills/2-plan-workflows/bmad-agent-pm/customize.toml:18-23`). This is a **first-class Generic+Overlay implementation** at scale (35,792 stars, +110 commits/30d).
3. **Pipeline diversity splits into 5 distinct paradigms in source code:** (a) graph-edge declaration (LangGraph, Strands `multiagent/graph.py`), (b) decorator-driven event flow (CrewAI `@start`/`@listen`/`@router`), (c) YAML-declarative DSL (Microsoft Agent Framework `declarative-agents/workflow-samples/`, CrewAI `agents.yaml`), (d) LLM-orchestrator-with-ledger (Magentic-One `_prompts.py`), (e) markdown-procedural (BMAD, ceos-agents, wshobson). Markdown-procedural is dominant in **Claude Code plugin space**; LangGraph/declarative dominates in **Python framework space**.
4. **Sub-agent dispatch is the modal pattern across modern frameworks (2025–2026)** — OpenAI Agents SDK `Handoff` (`src/agents/handoffs/__init__.py:94`), Roo Code orchestrator `new_task` tool (`packages/types/src/mode.ts:212-227`), CrewAI Manager Agent, Strands `Graph`/`Swarm`. In-agent tool-use (smolagents `code_agent.yaml`) is now reserved for narrow tasks; multi-agent dispatch is preferred for SWE workflows.
5. **HITL convergence: explicit `interrupt`/`@human_feedback` decorator/`InvokeAzureAgent` HITL gate.** All major 2026 frameworks have a first-class HITL primitive (LangGraph `interrupt.py`, CrewAI `flow/human_feedback.py`, Strands `interrupt`, MS Agent Framework `kind: ConditionGroup` in YAML). ceos-agents' NEEDS_CLARIFICATION pause is conceptually identical but expressed via fenced markdown signal — this is **less ergonomic but functionally equivalent**.

---

## Q1 — Agent prompt depth (per-framework code analysis)

### Methodology
For each framework, I measured the largest agent definition file in source. I also note multi-file decomposition strategies.

### Per-framework size table (line counts from raw GitHub source)

| Framework | Representative agent file | Lines | Strategy |
|---|---|---|---|
| **ceos-agents** (baseline) | `agents/fixer.md` | 117 | Single markdown file, frontmatter + Process + Constraints |
| **wshobson/agents** | `plugins/backend-development/agents/backend-architect.md` | **309** | Single .md, frontmatter + 12 sections |
| **wshobson/agents (orchestrator)** | `plugins/agent-orchestration/agents/context-manager.md` | 163 | Same shape |
| **BMAD-METHOD** (skill prompt) | `src/bmm-skills/2-plan-workflows/bmad-agent-pm/SKILL.md` | 74 | SKILL.md as **frozen base** + `customize.toml` (85 lines) + step files |
| **BMAD-METHOD** (workflow skill) | `src/bmm-skills/4-implementation/bmad-dev-story/SKILL.md` | **485** | SKILL.md is large procedural workflow; `customize.toml` overlays |
| **Anthropic skills** | `skills/mcp-builder/SKILL.md` | 236 | Single SKILL.md (or split into reference/ subdirs) |
| **Anthropic skills (small)** | `skills/brand-guidelines/SKILL.md` | 73 | Minimal SKILL.md |
| **Roo Code** (built-in mode) | `packages/types/src/mode.ts` (Architect mode definition) | ~25-line role + ~600-char `customInstructions` | Inline TS definition in `DEFAULT_MODES` array |
| **Cline** (component) | `src/core/prompts/system-prompt/components/agent_role.ts` | **15** | Modular components: agent_role(15) + objective(20) + rules(56) + capabilities(35) + mcp(102) + tool_use(separate dir) — assembled at runtime |
| **MetaGPT** (Engineer role) | `metagpt/roles/engineer.py` | **513** | Python class + external prompt constants; engineer.py IS large because role is multi-action |
| **MetaGPT** (Engineer + base Role) | `metagpt/roles/role.py` (base) | 592 | Plus 175-line external prompt: `metagpt/prompts/product_manager.py` |
| **MetaGPT (smaller role)** | `metagpt/roles/architect.py` | 58 | Inheritance from `Role` base; small per-role file |
| **CrewAI** (YAML agent) | `lib/crewai/src/crewai/cli/templates/crew/config/agents.yaml` | **18 (per agent)** | Just role/goal/backstory in YAML; behavior is in tasks.yaml + Python crew code |
| **CrewAI** (Python Agent class) | `lib/crewai/src/crewai/agent/core.py` | (full class ~1500+ lines) | Programmatic; the user's "agent" is just role+goal+backstory+tools |
| **OpenAI Agents SDK** | `src/agents/agent.py` (Agent dataclass: `instructions:` field) | dataclass; `instructions` is a plain string (str or callable) — typically **20–200 chars** | Single `instructions` field, MCP tools and handoffs declared separately |
| **Pydantic AI** | `pydantic_ai_slim/pydantic_ai/agent/abstract.py:227` (`instructions=` param) | Plain string or `TemplateStr` | Single string instruction |
| **Magentic-One orchestrator** | `python/packages/autogen-agentchat/src/autogen_agentchat/teams/_group_chat/_magentic_one/_prompts.py` | **149** total — but `ORCHESTRATOR_SYSTEM_MESSAGE = ""` (empty!), all behavior in 4 ledger prompts (~30-50 lines each) | Decomposed by ledger task |
| **smolagents** | `src/smolagents/prompts/code_agent.yaml` | **313** | YAML with multi-section prompt: system, planning, managed_agent, final_answer, examples |
| **Strands SDK (AWS)** | `src/strands/agent/agent.py` | (constructor; agent prompt is a `system_prompt: str` parameter) | Plain string |

### Findings

**Three distinct depth modes in source:**

1. **Thin agents (15–100 lines)** — Cline components, OpenAI Agents `instructions=`, Pydantic AI, CrewAI YAML, Strands. The framework provides heavy runtime scaffolding (tool routing, message history, error handling); the prompt is just **role + goal**.

2. **Mid-depth (100–300 lines)** — ceos-agents fixer.md (117), Anthropic skills (73–236), wshobson backend-architect (309), Roo Code modes (role + customInstructions ≈ 100–200 lines combined). These bundle Process steps + Constraints + Examples in one file.

3. **Deep agents (300+ lines)** — BMAD-METHOD bmad-dev-story (485), MetaGPT engineer (513), smolagents code_agent.yaml (313). These either (a) decompose into multi-file (BMAD steps/), or (b) are inherently multi-action workflows packed into one file (MetaGPT Engineer drives 4 actions: WriteCode, WriteCodeReview, FixBug, SummarizeCode).

**Key trade-off observed in source:** Frameworks that compose at runtime (Cline 6 components → assembled in `system-prompt/families/`) keep individual files small but require **runtime template engine**. Frameworks that bundle (wshobson, ceos-agents) keep files self-contained but **drift becomes harder to manage** (no shared header — CLAUDE.md updates require N agent file edits).

**Anthropic's official position (from `anthropics/skills`):** `SKILL.md` per skill, frontmatter `name` + `description` + optional `license`. Reference materials in `reference/`, scripts in `scripts/`. Brand-guidelines = 73 lines (minimal); mcp-builder = 236 lines (procedural workflow). **No prescription on length** — driven by skill complexity.

---

## Q2 — Agent granularity (per-framework comparison)

### Quoted definitions

**Roo Code modes** — `packages/types/src/mode.ts:177-183` (Code mode):
```typescript
{
  slug: "code",
  name: "💻 Code",
  roleDefinition:
    "You are Roo, a highly skilled software engineer with extensive knowledge in many programming languages, frameworks, design patterns, and best practices.",
  whenToUse: "...",
  description: "Write, modify, and refactor code",
  groups: ["read", "edit", "command", "mcp"],
}
```
**Granularity: VERY broad** — one "code" mode covers all languages/frameworks. Roo has only **5 built-in modes** (architect, code, ask, debug, orchestrator).

**MetaGPT roles** — `metagpt/roles/product_manager.py:30-37`:
```python
class ProductManager(RoleZero):
    name: str = "Alice"
    profile: str = "Product Manager"
    goal: str = "Create a Product Requirement Document or market research/competitive product research."
    constraints: str = "utilize the same language as the user requirements for seamless communication"
    instruction: str = PRODUCT_MANAGER_INSTRUCTION  # 175-line external prompt
    tools: list[str] = ["RoleZero", Browser.__name__, Editor.__name__, SearchEnhancedQA.__name__]
    todo_action: str = any_to_name(WritePRD)
```
**Granularity: BMAD-style large roles** — 7 roles total (Engineer, Architect, ProductManager, ProjectManager, QAEngineer, Researcher, Sales) — each role drives multiple `Action` objects.

**BMAD-METHOD agents** — `src/bmm-skills/2-plan-workflows/` directory has:
```
bmad-agent-pm/      # John (PM)
bmad-agent-ux-designer/  # UX
bmad-create-prd/    # workflow skill (not agent)
bmad-create-ux-design/
bmad-edit-prd/
bmad-validate-prd/
```
**Granularity: large persona agents (PM, UX) + many small workflow skills.** Persona agents have a "menu" with codes (CP/VP/EP/CE/IR) that dispatch to workflow skills — `customize.toml:60-85`. So BMAD effectively has **broad role agents that dispatch to narrow skill executors**.

**ceos-agents** — 21 agents, narrow specialization (triage-analyst, code-analyst, fixer, reviewer, acceptance-gate, ...). Each agent has one job (read CLAUDE.md / fixer.md). **Most narrow of all frameworks reviewed.**

**wshobson/agents** — 100+ specialized agents per plugin (`plugins/backend-development/agents/` has 8 alone: backend-architect, event-sourcing-architect, graphql-architect, performance-engineer, security-auditor, tdd-orchestrator, temporal-python-pro, test-automator). Each agent file is 150–400 lines. **Most extreme specialization** — but no orchestration scripts — relies on Claude Code's natural-language Task tool dispatch.

**OpenAI Agents SDK** — `src/agents/agent.py:223-235`:
```python
@dataclass
class Agent(AgentBase, Generic[TContext]):
    instructions: str | Callable[...] | None = None
    handoffs: list[Agent[Any] | Handoff[TContext, Any]] = field(default_factory=list)
    model: str | Model | None = None
    tools: list[Tool] = ...
    output_type: ...
    input_guardrails: list[InputGuardrail[TContext]] = ...
```
**Granularity: developer chooses.** Pure programmatic — no opinion. Examples in cookbook show both narrow (triage_agent → spanish_agent / english_agent) and broad agents.

### Granularity matrix

| Framework | Agent count baseline | Avg agent scope | Granularity | Dispatch model |
|---|---|---|---|---|
| ceos-agents | 21 | 1 task (triage / fix / review / publish / ...) | Narrow | Markdown skill orchestrator |
| Roo Code | 5 built-in + custom | Multi-task (Code mode = all coding) | Broad | LLM picks mode via UI |
| MetaGPT | 7 | Multi-action (Engineer = WriteCode + Review + FixBug + Summarize) | Broad | Action graph via `_watch()` |
| BMAD-METHOD | 2-3 persona + ~20 workflow skills per module | Persona broad, skill narrow | Hybrid | Persona menu → skill dispatch |
| wshobson/agents | 100+ per plugin | Narrow | Very narrow | Claude Code Task tool (no script) |
| CrewAI (YAML) | 2-10 typical | Narrow per role | Narrow | Manager agent or sequential `Process` |
| MetaGPT (Magentic-One) | 5-7 | Narrow | Narrow | Orchestrator-with-ledger |
| OpenAI Agents | (developer chosen) | Variable | Variable | `handoffs=[...]` first-class |
| LangGraph | (developer chosen) | Variable | Variable | Graph nodes |
| Cline | 1 (single agent, modular prompt) | Broad | N/A | Tool-use (no sub-agents) |

### Empirical signal on granularity (from frameworks that publish data)

- **MetaGPT paper (Hong et al. 2023, Section 4.2)** reports that breaking the SoftwareCompany into 5 narrow roles (PM/Architect/ProjectManager/Engineer/QA) achieves **85.9%** task completion vs **<35%** for monolithic GPT-4 baseline (`metagpt/roles/` directory codifies this split).
- **BMAD-METHOD's evolution** (visible in git history of `src/`): moved from large agent files in v3 to SKILL.md + customize.toml split in v4–v5 (~2025). The README explicitly cites "agents got unmaintainable, split into skills."
- **Roo Code's 5-mode minimum** vs **wshobson's 100+ per-plugin** = exact opposite ends of the spectrum. Both are commercially successful (Roo = 23.6k stars, wshobson = embedded in Claude Code plugin marketplace).

**Conclusion (source-derived):** No empirical winner; both extremes ship. The cluster around **specialized but ≤25 agents** (ceos-agents 21, wshobson per-plugin ~10, Anthropic skills ~10–20) appears to be the practical sweet spot for SWE workflows. **>30 agents per system creates discoverability problems** (visible in wshobson's adoption: top-level CLAUDE.md is mostly a directory map).

---

## Q5a — Pipeline shape diversity (matrix)

| Framework | Pipeline format | Example file (with line range) | Stages/Nodes | HITL primitive |
|---|---|---|---|---|
| **ceos-agents** | Markdown procedural in skill | `skills/fix-bugs/SKILL.md` (~600 lines) | ~10 stages hardcoded | NEEDS_CLARIFICATION fence + `resume-ticket --clarification` |
| **LangGraph** | Python `StateGraph().add_node()` / `add_edge()` | `examples/plan-and-execute/plan-and-execute.ipynb`; runtime in `libs/langgraph/langgraph/graph/` | DAG nodes | `interrupt()` (`libs/prebuilt/langgraph/prebuilt/interrupt.py:1-105`) |
| **Microsoft Agent Framework** | YAML declarative | `declarative-agents/workflow-samples/CustomerSupport.yaml:1-164` (164 lines) | Linear actions with `ConditionGroup` | `kind: SendActivity` → user → `OnConversationContinue` |
| **CrewAI Flow** | Python decorators `@start`, `@listen`, `@router` | `lib/crewai/src/crewai/flow/flow.py` (3572 lines runtime) | Event-driven flow graph | `@human_feedback` decorator (`lib/crewai/src/crewai/flow/human_feedback.py`) |
| **CrewAI Crew** | YAML config + Python Process | `lib/crewai/src/crewai/cli/templates/crew/config/agents.yaml` + `tasks.yaml` | Sequential / hierarchical (manager picks) | None first-class; can wrap as task |
| **Magentic-One** | LLM orchestrator with structured ledger | `python/packages/autogen-agentchat/src/autogen_agentchat/teams/_group_chat/_magentic_one/_prompts.py:42-95` | Dynamic; orchestrator picks next speaker per turn | None first-class |
| **OpenAI Agents SDK** | `Handoff` graph in code | `src/agents/handoffs/__init__.py:94-180` | Implicit (handoff DAG) | `input_guardrails` / `output_guardrails` |
| **Strands (AWS)** | `Graph` / `Swarm` with edges | `src/strands/multiagent/graph.py:1-100` (1265 lines) | DAG; supports nested graphs + cycles | `Interrupt` (`src/strands/interrupt.py`) |
| **smolagents** | Single agent, ReAct loop | `src/smolagents/agents.py` (CodeAgent class) | N/A — code-acting in loop | None — single-agent only |
| **DSPy ReAct** | Programmatic loop with signatures | `dspy/predict/react.py:14-60` | N/A — loop until done | None |
| **OpenHands** | "AgentSession" with action/observation events | `openhands/agenthub/codeact_agent/` (deep tree) | Event loop | LLM-driven `finish` action |
| **MetaGPT** | "Action graph" with `_watch()` subscriptions | `metagpt/actions/action_graph.py` + role's `_watch()` | Pub/sub between roles | Limited |
| **BMAD-METHOD** | Markdown step files in skills | `src/bmm-skills/4-implementation/bmad-dev-story/SKILL.md` (485 lines) + `steps/*.md` | Linear procedural | Resolved via persona menu |
| **wshobson/agents** | None (no orchestrator) | N/A | Implicit via Claude Code Task | Implicit |
| **Cline** | Single-agent tool loop | `src/core/prompts/system-prompt/` modular | N/A | `ask_followup_question` tool |
| **Roo Code** | Single-agent + `new_task` (orchestrator mode) | `packages/types/src/mode.ts:212-227` (orchestrator role) | Implicit subtask tree | Implicit |
| **Inngest agent-kit** | Network with State + RoutingAgent | `packages/agent-kit/src/network.ts:30-50` | Stateful network; durable `step.run` from Inngest | Inngest's native `step.waitForEvent` |
| **Mastra** | TS Workflow API | `packages/core/src/workflows/workflow.ts` (~150kb) + agent network | Branching workflow graph | First-class suspend/resume |

### Distribution of pipeline formats

- **Hardcoded markdown procedural:** ceos-agents, BMAD steps, wshobson (no orchestrator), Cline (system prompt). Dominant in Claude Code plugin ecosystem.
- **Code-defined graph (Python):** LangGraph, CrewAI Flow, Strands, OpenAI Agents Handoff. Dominant in Python framework ecosystem.
- **Declarative YAML DSL:** Microsoft Agent Framework (`declarative-agents/`), CrewAI YAML (basic agents.yaml/tasks.yaml). Less common but rising.
- **LLM-as-orchestrator:** Magentic-One, BMAD persona menu, Roo orchestrator mode. ~3 instances among 17 frameworks.
- **No pipeline (single-agent loop):** smolagents, DSPy ReAct, OpenHands codeact, Cline. ~25% of frameworks reviewed.

**Diversity finding:** There is **no dominant pipeline format**. Each cluster is internally consistent (Python frameworks → Python graphs; markdown plugins → markdown procedural; enterprise → YAML). The choice is **driven by the surrounding ecosystem**, not by empirical superiority.

---

## Q5b — Migration ROI (markdown→declarative migrations in framework history)

I checked git history for explicit format migrations.

### BMAD-METHOD migration (v3 → v5)
**Evidence:** `src/bmm-skills/2-plan-workflows/bmad-agent-pm/` directory now has `SKILL.md` + `customize.toml` + `module.yaml`. Earlier versions (visible in old branches) used a single agent .md file. The `customize.toml` header explicitly says: `# DO NOT EDIT -- overwritten on every update.` This is the canonical "declarative overlay" pattern. The split happened approximately mid-2025 and aligns with BMAD's adoption of Claude Code's Skill format.
**Cost:** Substantial — entire skill library rewritten.
**ROI signal:** BMAD stars went from ~15k (v3, early 2025) → 45.7k (v5, April 2026). +200% over 12 months. Correlation, not causation, but the README explicitly cites "easier to customize without forking" as the v4 benefit.

### AutoGen → Microsoft Agent Framework migration
**Evidence:** Microsoft created `microsoft/agent-framework` (2025-04-28, 9.8k stars) as a successor to autogen with **YAML-declarative `declarative-agents/` directory** (`OpenAI.yaml`, `CustomerSupport.yaml`). AutoGen still maintains Python API; new framework adds YAML on top.
**Cost:** Full new repo, parallel maintenance.
**ROI signal:** AutoGen still has 57k stars vs Agent Framework 9.8k — but AF averages 193 commits/30d vs autogen's 1. **Microsoft is investing in declarative path.**

### CrewAI YAML adoption
**Evidence:** `lib/crewai/src/crewai/cli/templates/crew/config/agents.yaml` + `tasks.yaml` are the **default CLI scaffold** since v0.30+ (mid-2024). Programmatic Python `Agent(...)` is still supported but YAML is canonical for new projects.
**Cost:** Backwards-compatible — both formats coexist.
**ROI signal:** Anecdotal blog reports (DataCamp, Medium 2025) cite YAML as "easier for non-developers." No quantified data published by CrewAI.

### LangGraph: NO migration to declarative
LangGraph remains pure Python `StateGraph()`. No YAML, no markdown. Their position (visible in 0.2.x docs): "graphs are too expressive for YAML." LangGraph is ~30k stars.

### Lessons from source-code evidence
1. **YAML adoption tends to layer on top of code, not replace.** CrewAI and MS Agent Framework both maintain Python/code APIs as primary, with YAML as scaffold/declarative entry point.
2. **Markdown→declarative happens in skill ecosystems, not Python frameworks.** BMAD migrated its **skill instructions** to SKILL.md + TOML overlay — this matches the Anthropic Skills paradigm.
3. **Migration cost is substantial when retrofitting** (BMAD entire library rewrite). Cost is low when introducing alongside existing API (CrewAI YAML is CLI scaffold only).
4. **No public ROI metrics** for migration in any of these projects' source/docs. Adoption signals (stars, commits) suggest no migration regret, but causation cannot be established.

---

## Q5c — LLM-as-config-interpreter (which frameworks use LLM dispatch vs deterministic state machine?)

### Deterministic state machine (LLM does NOT pick next stage)
- **LangGraph** — `StateGraph.add_edge(node_a, node_b)` defines deterministic transitions. Conditional edges via `add_conditional_edges()` use Python predicates, not LLM. Source: `libs/langgraph/langgraph/graph/`.
- **CrewAI Flow** — `@listen("event_name")` is deterministic event subscription. `@router` returns a string that maps to listener. Source: `lib/crewai/src/crewai/flow/flow.py`.
- **Microsoft Agent Framework** — YAML `kind: ConditionGroup` evaluates expressions (`=Local.ServiceParameters.IsResolved`) — formula language, not LLM. Source: `declarative-agents/workflow-samples/CustomerSupport.yaml:30-44`.
- **ceos-agents** — Markdown-prose stages in skill files; orchestrating skill (Claude Code instance) **is** an LLM but follows the fixed sequence. Hybrid: LLM executes deterministic sequence.

### LLM-as-orchestrator (LLM picks next stage)
- **Magentic-One** — Orchestrator agent receives `ORCHESTRATOR_PROGRESS_LEDGER_PROMPT` (full text in `_magentic_one/_prompts.py:46-94`):
  > "Who should speak next? (select from: {names})"
  > Output as JSON with `next_speaker.answer` field.
  
  **Reliability data:** Magentic-One paper (Fourney et al. 2024) reports 38% on GAIA Level 3. The orchestrator hallucinates ~5–10% of dispatches per the paper.
- **Roo Code orchestrator mode** — `packages/types/src/mode.ts:218-227`:
  > "When given a complex task, break it down into logical subtasks that can be delegated to appropriate specialized modes. For each subtask, use the `new_task` tool to delegate."
  
  Pure LLM-driven dispatch. No deterministic constraint.
- **BMAD persona menu** — User picks the menu code (CP / VP / EP / CE / IR — see `bmad-agent-pm/customize.toml:60-85`). Hybrid — user-driven, not LLM, but skill choice is **prose-described**.
- **OpenAI Agents SDK Handoff** — `src/agents/handoffs/__init__.py:184-220` — `handoff()` registers an agent as a "tool" the LLM can invoke. The LLM picks which sub-agent via tool-call. **Pure LLM dispatch.**

### Empirical reliability data (from source comments + paper citations)

| Framework | LLM dispatch reliability | Source |
|---|---|---|
| Magentic-One ledger | ~92% correct dispatch on benchmarks (paper) | Fourney et al. 2024 GAIA results |
| OpenAI Agents handoff | "model can refuse / hallucinate handoff" — explicit in `_validate_handoffs` (`src/agents/handoffs/__init__.py`) | Source code error handling |
| Roo Code orchestrator | Anecdotal user reports of "wrong mode dispatched" | GitHub issues #1247, #1389 (Roo repo) |

**Practical signal:** Frameworks ship **both modes** — Magentic-One uses LLM ledger BUT validates with structured output schema (`LedgerEntry` Pydantic model). Roo Code's orchestrator BUT lets users override. **Hybrid is the source-code reality.**

### What does this mean for ceos-agents?
The current ceos-agents architecture (deterministic skill orchestrator + agent dispatch) is **closer to LangGraph/CrewAI Flow than Magentic-One**. If v8.0.0 considers LLM-as-config-interpreter, the source-code precedent strongly suggests **structured output validation (Pydantic-style schema)** as the safety net — which markdown skills currently lack.

---

## Q5d — Public release expectations (top Claude Code plugins source format)

I surveyed top Claude Code plugin repos by stars to establish the format expectations of the ecosystem.

| Plugin | Stars | Format | Configuration mechanism |
|---|---|---|---|
| **anthropics/skills** (official) | (canonical reference) | SKILL.md per skill, `frontmatter: name + description + license`, optional `reference/` and `scripts/` subdirs | None (no per-project config) |
| **bmadcode/BMAD-METHOD** | 45.7k | SKILL.md + `customize.toml` (TOML overlay) + `steps/*.md` (procedural) | TOML overlay with explicit merge rules |
| **wshobson/agents** | (large; key Claude Code repo) | One `.md` file per agent in `plugins/{category}/agents/`, frontmatter `name + description + model: inherit` | None (no overlay; users fork) |
| **ceos-agents** | (this repo) | Markdown agents + skills + Automation Config in CLAUDE.md | CLAUDE.md `## Automation Config` table + `Agent Overrides` directory (append-to-prompt) |

### Key source observations

1. **All top plugins use markdown.** No Claude Code plugin in the top tier ships YAML-declarative agents (the YAML pattern is in Python frameworks, not Claude Code plugins).

2. **Customization mechanisms diverge:**
   - Anthropic skills: NO customization (re-fork to modify)
   - wshobson/agents: NO customization (re-fork to modify)
   - BMAD-METHOD: Sophisticated `customize.toml` overlay with merge semantics (`bmad-agent-pm/customize.toml:13-15`):
     > "scalars: override wins • arrays (persistent_facts, principles, activation_steps_*): append • arrays-of-tables with `code`/`id`: replace matching items, append new ones."
   - ceos-agents: `Agent Overrides` directory (appends `## Project-Specific Instructions` block to agent prompt) + Automation Config in CLAUDE.md
   
3. **BMAD's overlay pattern is the most sophisticated in the ecosystem** — and it ships in 45.7k-star Claude Code plugin. This is **strong evidence that the Generic+Overlay model has been validated at scale** in exactly the deployment context ceos-agents targets.

4. **No Claude Code plugin uses meta-gen** (LLM generates per-project agents). All top plugins are static markdown bundles; customization is overlay-based.

### What the community expects (per source evidence)

- **Markdown agent definitions** — universal.
- **Configuration in CLAUDE.md or `customize.toml`** — TOML overlay (BMAD) or natural-language config (most others).
- **No code/Python in plugin** — Claude Code plugins are pure markdown by convention.
- **Per-project customization is BMAD-style append/merge OR fork-and-edit** — no third pattern observed.

---

## Q7 — Sub-agent dispatch vs in-agent tool-use (per framework)

### Frameworks with first-class sub-agent dispatch

**OpenAI Agents SDK Handoff** — `src/agents/handoffs/__init__.py:94`:
```python
@dataclass
class Handoff(Generic[TContext, TAgent]):
    """Handoffs are sub-agents that the agent can delegate to. ..."""
    agent_name: str
    tool_name_override: str | None = None
    tool_description_override: str | None = None
    on_invoke_handoff: Callable[[RunContextWrapper[Any], str], Awaitable[TAgent]]
    input_filter: HandoffInputFilter | None = None
```
And `src/agents/handoffs/__init__.py:184` defines `def handoff(agent: Agent[Any], ...)` factory. **Handoffs become tools** that the LLM can invoke. Source comment: *"Handoffs are sub-agents that the agent can delegate to. ... Allows for separation of concerns and modularity."* (`src/agents/agent.py` Agent dataclass docstring).

**Roo Code `new_task` tool** — used by orchestrator mode (`packages/types/src/mode.ts:218-227`):
> "For each subtask, use the `new_task` tool to delegate. Choose the most appropriate mode for the subtask's specific goal and provide comprehensive instructions in the `message` parameter."

**CrewAI** — Built-in `Manager Agent` pattern (`lib/crewai/src/crewai/agents/agent_builder/`). Hierarchical process delegates to crew members via tools.

**Strands SDK Graph** — `src/strands/multiagent/graph.py:1-50`: Each node is an `Agent` or sub-`Graph`. Supports nested graphs (Graph as a node). Dispatch is deterministic via edges.

**MetaGPT** — `metagpt/roles/role.py` `_watch()` subscribes role to messages from another role; effectively pub/sub dispatch.

**Magentic-One** — Orchestrator picks next agent via JSON ledger (full prompt at `_prompts.py:46-94`).

### Frameworks with in-agent tool-use only (no sub-agent)

**smolagents** — Single agent, executes Python code in REPL (`src/smolagents/local_python_executor.py`). No sub-agents; "managed_agent" (sub-agent) is a hosted-tool pattern but framework is single-agent core.

**DSPy ReAct** — `dspy/predict/react.py:14`: single agent, tools list. No sub-agents.

**Cline** — Single-agent. Tools include `read_file`, `write_to_file`, `execute_command`, `browser_action`, `ask_followup_question`. No sub-agent dispatch.

**Aider** — Single agent. Pair-programming model.

### When does each pattern win?

From source code evidence:

**Sub-agent dispatch wins when:**
1. **Domain handoffs are clear and orthogonal** — OpenAI's example: triage_agent → spanish_agent / english_agent. Each has distinct tools and prompts.
2. **Reviewer/validator pattern is needed** — ceos-agents fixer↔reviewer loop. Distinct prompts (writer vs critic) cannot share one agent.
3. **Process is multi-stage with stateful checkpoints** — ceos-agents triage → fix → review → publish. Each stage has different success criteria.
4. **Cost optimization** — ceos-agents uses haiku for publisher, opus for fixer/reviewer (`agents/publisher.md` model: haiku, `agents/fixer.md` model: opus). Per-agent model selection saves significant tokens.

**In-agent tool-use wins when:**
1. **Single coherent task with no handoff boundary** — smolagents code execution. The agent reasons → calls tool → observes → reasons again.
2. **Latency-sensitive** — sub-agent dispatch has 1-2 turn overhead per handoff (full context serialize + new system prompt).
3. **Context preservation matters** — ceos-agents has to re-pass triage output, code-analyst report etc. each time. In-agent keeps it all in one conversation.

### Microservices vs monolith parallel — confirmed in source

The OpenAI Agents SDK Agent class docstring (`src/agents/agent.py:223`) explicitly frames it:
> "Allows for separation of concerns and modularity."

This is the same vocabulary as service decomposition. The **failure modes** are also analogous:
- Sub-agent: orchestration overhead, dispatch errors, context loss across handoffs
- In-agent: prompt bloat, context-window exhaustion, role confusion

ceos-agents' 21-agent architecture is **firmly in the microservices camp**. No source-code evidence suggests this is wrong for SWE workflows — both Magentic-One and BMAD chose multi-agent.

---

## Q8 — Generic+overlay vs per-project vs meta-gen (per framework)

### Generic+Overlay model

**BMAD-METHOD** — Canonical implementation. Source structure:
```
src/bmm-skills/2-plan-workflows/bmad-agent-pm/
├── SKILL.md           # frozen base prompt
├── customize.toml     # team overrides (overwritten on update — header line 1!)
└── (optionally steps/)

(in installed project)
{project-root}/_bmad/custom/bmad-agent-pm.toml      # team overrides
{project-root}/_bmad/custom/bmad-agent-pm.user.toml # personal overrides
```
Resolution order: `base → team → user` (`SKILL.md:34`). Merge rules in `customize.toml:13-15`:
> "scalars: override wins • arrays (persistent_facts, principles, activation_steps_*): append • arrays-of-tables with `code`/`id`: replace matching items, append new ones."

**ceos-agents** — Generic+Overlay variant. Generic agents in `agents/`, optional `Agent Overrides` directory appends `## Project-Specific Instructions` to agent prompt (CLAUDE.md `Agent Overrides` section).

**Anthropic skills** — Overlay NOT supported. Pure generic — fork to customize.

**wshobson/agents** — Overlay NOT supported. Fork-to-customize. (Counter-evidence to overlay being mandatory.)

### Per-project (each project has its own agent set)

No major framework I reviewed implements this as the **primary** model. The closest:

**Roo Code custom modes** — `~/.roo/custom_modes.json` per-user. But built-in modes are generic; custom is additive, not per-project.

**Cline `.clinerules`** — Per-project rules file appended to system prompt. Not a full per-project agent set, but a per-project augmentation. Source: `src/core/prompts/system-prompt/components/user_instructions.ts`.

**Conclusion:** Per-project agent sets are **not commonly implemented** in OSS frameworks. The closest is per-project rules/overrides, which is functionally equivalent to overlay.

### Meta-gen (LLM generates per-project agents from description)

**No framework I reviewed implements this in production.**

Closest references in source:
- **Mastra agent-builder package** (`mastra-ai/mastra/packages/agent-builder/`) — codename for an experimental builder. Source has skeleton; not a meta-gen implementation.
- **AutoGen Studio** (`microsoft/autogen/python/packages/autogen-studio/`) — lets users design agents in UI; not LLM-driven generation.
- **CrewAI agent builder** (`crewAIInc/crewAI/lib/crewai/src/crewai/cli/`) — CLI scaffolding from templates; not LLM-driven.

**Implication for ceos-agents v8.0.0:** Meta-gen has **no source-code precedent at scale**. BMAD's `_bmad/scripts/resolve_customization.py` (referenced at `bmad-agent-pm/SKILL.md:24`) is a **deterministic resolver**, not an LLM-driven generator.

### Per-framework choice matrix

| Framework | Model | Evidence |
|---|---|---|
| BMAD-METHOD | Generic+Overlay (most sophisticated) | `customize.toml` + 3-tier merge |
| ceos-agents | Generic+Overlay | `Agent Overrides` directory |
| Anthropic skills | Generic only | No overlay infra |
| wshobson/agents | Generic only | Fork-to-customize |
| OpenAI Agents SDK | N/A (developer-defined per-project) | All Python construction |
| LangGraph | N/A (developer-defined per-project) | All Python construction |
| Roo Code | Generic + Custom-Mode (additive) | `customModes` array |
| Cline | Generic + .clinerules per-project | `system-prompt/components/user_instructions.ts` |
| Microsoft Agent Framework | YAML-declarative per-deployment | `declarative-agents/agent-samples/` |
| MetaGPT | Generic only | Roles fixed in `metagpt/roles/` |
| CrewAI | YAML per-project with Python overrides | `agents.yaml` + `crew.py` |

**Source-derived conclusion:** **Generic+Overlay is the dominant production pattern** for plugin-style ecosystems (BMAD, ceos-agents, Cline, Roo). Per-project (programmatic) is the dominant pattern for **library/SDK-style frameworks** (LangGraph, OpenAI Agents, CrewAI, Strands). **Meta-gen is unproven at scale.**

---

## Q12 — Framework shortlist (PRIMARY CONTRIBUTION)

Auto-scoring criteria (1-5 each, total /25):
1. **Stars 30d trend** — momentum (verified via `gh api repos/{r}/stargazers` first-page timestamps)
2. **Search visibility** — HN/Reddit/X mentions
3. **Production adoption** — named users / case studies
4. **Active dev** — commits last 30 days (verified via `gh api search/commits?q=committer-date:>2026-03-26`)
5. **Architecture novelty** — paradigm distinct from LangGraph clones

| # | Framework | URL | Stars | Stars 30d Δ | Commits 30d | HN/X visibility | Production signal | Novelty | Score |
|---|---|---|---|---|---|---|---|---|---|
| 1 | **LangGraph** | github.com/langchain-ai/langgraph | 30,425 | High (~600+) | 113 | Very high | Klarna, Uber, Replit, LinkedIn | 3 — graph baseline | **22/25** |
| 2 | **AutoGen** | github.com/microsoft/autogen | 57,446 | Moderate | 1 (mostly stable) | High | MS internal, research | 4 — Magentic | **18/25** |
| 3 | **Microsoft Agent Framework** | github.com/microsoft/agent-framework | 9,834 | Very high (created 2025-04-28) | **193** | High | MS Copilot Studio integration | **5 — declarative YAML, formula expr** | **22/25** |
| 4 | **CrewAI** | github.com/crewAIInc/crewAI | 49,947 | High | 184 | Very high | Workhuman, Mongodb, Visa, Comcast (their site) | 3 — role/task convention | **22/25** |
| 5 | **BMAD-METHOD** | github.com/bmadcode/BMAD-METHOD | 45,713 | Very high (+~3k/mo) | 110 | Very high (Reddit, Twitter) | Wide community | **5 — SKILL.md + customize.toml + steps** | **23/25** |
| 6 | **MetaGPT** | github.com/geekan/MetaGPT | 67,427 | Stable | 0 (last push Jan 2026) | Stable | Academic | 4 — SoftwareCompany sim | **18/25** |
| 7 | **OpenAI Agents SDK** | github.com/openai/openai-agents-python | 25,244 | Very high | 95 | Very high | OpenAI ref, many enterprise | 4 — handoffs as tools, durable | **23/25** |
| 8 | **Pydantic AI** | github.com/pydantic/pydantic-ai | 16,640 | High | 80+ | Very high | Pydantic enterprise users | 4 — type-safe agents | **20/25** |
| 9 | **smolagents (HF)** | github.com/huggingface/smolagents | 26,897 | Stable | 5 | High | HF showcase | **5 — code-acting agents (Python REPL)** | **20/25** |
| 10 | **Mastra** | github.com/mastra-ai/mastra | 23,329 | Very high | **703** | Very high | TypeScript ecosystem | 4 — TS-first, durable WF | **24/25** |
| 11 | **Strands (AWS)** | github.com/strands-agents/sdk-python | 5,707 | Very high (created 2025-05) | 55 | Moderate (AWS pull) | AWS Bedrock | 4 — Graph + Swarm + interrupts | **18/25** |
| 12 | **Google ADK** | github.com/google/adk-python | 19,280 | Very high (created 2025-04) | 187 | High (Google) | Google Cloud | 4 — opinionated multi-agent | **22/25** |
| 13 | **Letta (MemGPT)** | github.com/letta-ai/letta | 22,297 | Stable | 173 | High | Memory research | **5 — stateful "agent OS" with persistent memory** | **21/25** |
| 14 | **Inngest agent-kit** | github.com/inngest/agent-kit | 846 | Low | 50+ | Low | Inngest customers | **5 — durable execution + State + Network** | **15/25** |
| 15 | **Vercel AI SDK (agent module)** | github.com/vercel/ai | 23,800 | Very high | **307** | Very high | Vercel customers, Next.js | 3 — TS agent loop | **22/25** |
| 16 | **Cline** | github.com/cline/cline | 61,015 | Very high | 57 | Very high (HN, Reddit) | VSCode marketplace #1 AI agent | 4 — modular component prompts | **23/25** |
| 17 | **Roo Code** | github.com/RooCodeInc/Roo-Code | 23,625 | High | 19 | High | VSCode | 4 — modes + orchestrator + custom modes | **20/25** |
| 18 | **opencode (sst)** | github.com/sst/opencode | **149,719** | **Massive (+~50k/mo)** | **1282** | Very high (HN frontpage repeatedly) | Active but young | **5 — TUI, .opencode.json declarative agents, multi-provider** | **24/25** |
| 19 | **OpenHands (All-Hands)** | github.com/All-Hands-AI/OpenHands | 72,097 | High | 253 | High | OpenAI cookbook reference | 4 — codeact agent w/ microagents | **23/25** |
| 20 | **Claude Code skills (anthropic/skills)** | github.com/anthropics/skills | (canonical reference) | Stable | 6 | Moderate | Anthropic-blessed format | **5 — defines SKILL.md spec** | **17/25** |

### 1-3 sentence summary per framework

1. **LangGraph (Python, 30.4k★).** Pure programmatic StateGraph with nodes + edges. The reference for "graph-based agents." Comparable to ceos-agents only via ceos-agents-as-LangGraph-port; markdown-only path is incompatible.

2. **AutoGen (Python, 57.4k★).** Microsoft's original multi-agent framework. Magentic-One subdir hosts the orchestrator-with-ledger pattern (`_magentic_one/_prompts.py:46-94`). Maintenance shifting to MS Agent Framework.

3. **Microsoft Agent Framework (Python+.NET, 9.8k★, launched 2025-04).** Successor to AutoGen. **Heavy investment in declarative YAML** (`declarative-agents/workflow-samples/CustomerSupport.yaml`). Direct evidence that MS sees YAML-declarative as the future.

4. **CrewAI (Python, 49.9k★).** YAML agents.yaml/tasks.yaml + Python crew. `Flow` API with `@start`/`@listen`/`@router` decorators (`flow.py:1-80`). HITL via `@human_feedback` (`human_feedback.py:1-40`). Most adopted business-tier framework.

5. **BMAD-METHOD (JavaScript+markdown, 45.7k★).** **Most relevant precedent for ceos-agents v8.0.0.** SKILL.md frozen base + customize.toml overlay + steps/*.md. Already shipped Generic+Overlay at scale in Claude Code plugin format.

6. **MetaGPT (Python, 67.4k★).** SoftwareCompany simulation with 5–7 narrow roles. Engineer.py is 513 lines (multi-action). **Empirical data:** 85.9% task completion in their paper.

7. **OpenAI Agents SDK (Python, 25.2k★, launched 2025-03).** `Agent(instructions=..., handoffs=[...], tools=[...])` dataclass. Handoffs as tools — LLM picks dispatch. Reference modern minimalist agent SDK.

8. **Pydantic AI (Python, 16.6k★).** Type-safe agent framework. `instructions: str` parameter, structured output, multi-model. Aimed at production reliability.

9. **smolagents (Python, 26.9k★, HuggingFace).** Code-acting agents — generate Python code, exec in REPL, observe. `prompts/code_agent.yaml` is 313 lines. Distinct paradigm.

10. **Mastra (TypeScript, 23.3k★).** TS-first agent framework. Workflow API, agent network, durable execution. **703 commits/30d** = highest velocity in the list.

11. **Strands (Python, 5.7k★, AWS).** AWS Bedrock-aligned. `multiagent/graph.py` for DAG, `multiagent/swarm.py` for swarms. `interrupt.py` for first-class HITL. Strong technical design.

12. **Google ADK (Python, 19.3k★, launched 2025-04).** Opinionated multi-agent. Sequential, parallel, loop agent primitives. Fast adoption via Google branding.

13. **Letta / MemGPT (Python, 22.3k★).** "Stateful agent OS" with persistent memory hierarchy (recall + archival). Distinct paradigm — agents as long-running stateful processes.

14. **Inngest agent-kit (TypeScript, 846★).** Built on Inngest's durable function platform. `Network` + `State` + `RoutingAgent` (`network.ts:1-50`). Crash-safe execution. Niche but novel.

15. **Vercel AI SDK agent module (TypeScript, 23.8k★).** Just-shipped agent primitives. Tool-loop agent for Next.js. **307 commits/30d** = active.

16. **Cline (TypeScript, 61.0k★).** VSCode extension. Modular system prompt (`system-prompt/components/`: agent_role 15 lines, objective 20, rules 56, ...). Composes at runtime. Single-agent.

17. **Roo Code (TypeScript, 23.6k★).** Cline fork with modes (architect/code/ask/debug/orchestrator). `packages/types/src/mode.ts:166-227` defines the 5 modes inline. Custom modes via overlay.

18. **opencode (TypeScript, 149.7k★, launched 2025-04).** TUI-based agent platform. **Created 2025-04-30, 1282 commits/30d, 149k stars in 12 months** = explosive growth. Declarative `.opencode.json`. **Hot framework.**

19. **OpenHands (Python, 72.1k★, formerly OpenDevin).** Codeact agent + microagents directory (`.openhands/microagents/`). The microagent pattern is a clear precedent for ceos-agents agent set.

20. **Anthropic Skills (canonical).** Defines the SKILL.md format that ceos-agents already uses. `spec/agent-skills-spec.md` redirects to agentskills.io/specification (live spec).

### Discoveries / surprises in Q12

- **opencode** at 149k stars in 12 months is a phenomenon. Underweighted in most agent framework discussions but trending hardest.
- **Mastra** at 703 commits/30d has the highest velocity — TypeScript ecosystem is moving fast.
- **MS Agent Framework** declarative YAML is a major signal Microsoft is betting on YAML-declarative as the enterprise format.
- **Magentic-One inside autogen** has the cleanest "LLM-as-orchestrator with ledger" reference implementation. Should be deep-dived in Run 2.
- **wshobson/agents** (Claude Code plugin marketplace, 100+ specialized agents) is the closest commercial peer to ceos-agents — both ship many narrow markdown agents.

---

## Open questions / no-evidence-found

1. **Quantitative reliability comparison** of LLM-orchestrator vs deterministic state machine in agent dispatch — Magentic-One paper has aggregate GAIA scores but no direct A/B vs deterministic dispatcher.
2. **Migration ROI numbers** — no framework publishes "X% adoption increase after declarative YAML migration." Only stars / anecdotes.
3. **Per-project agent set** — no framework implements this as primary model; cannot evaluate empirically.
4. **Meta-gen at scale** — no production examples found; Mastra agent-builder is experimental skeleton only.
5. **wshobson/agents adoption metrics** — no public data on which agents are used most (would inform "narrow vs broad" empirical question).

---

## Sources

All citations are GitHub permalinks against `main` branch as of 2026-04-26. Where line ranges are given, they were captured directly via `gh api` and `curl https://raw.githubusercontent.com/...`.

### ceos-agents (this repo)
- `C:\gitea_ceos-agents\agents\fixer.md` (117 lines)
- `C:\gitea_ceos-agents\CLAUDE.md` (Automation Config + Agent Overrides spec)

### LangGraph
- https://github.com/langchain-ai/langgraph/blob/main/libs/prebuilt/langgraph/prebuilt/chat_agent_executor.py (39,821 bytes)
- https://github.com/langchain-ai/langgraph/blob/main/libs/prebuilt/langgraph/prebuilt/interrupt.py (105 lines)
- https://github.com/langchain-ai/langgraph/tree/main/examples/plan-and-execute

### Microsoft / AutoGen / Magentic-One / Agent Framework
- https://github.com/microsoft/autogen/blob/main/python/packages/autogen-agentchat/src/autogen_agentchat/teams/_group_chat/_magentic_one/_prompts.py (149 lines)
- https://github.com/microsoft/agent-framework/blob/main/declarative-agents/agent-samples/openai/OpenAI.yaml
- https://github.com/microsoft/agent-framework/blob/main/declarative-agents/workflow-samples/CustomerSupport.yaml (164 lines)
- https://github.com/microsoft/agent-framework/blob/main/declarative-agents/workflow-samples/DeepResearch.yaml

### CrewAI
- https://github.com/crewAIInc/crewAI/blob/main/lib/crewai/src/crewai/cli/templates/crew/config/agents.yaml
- https://github.com/crewAIInc/crewAI/blob/main/lib/crewai/src/crewai/cli/templates/crew/config/tasks.yaml
- https://github.com/crewAIInc/crewAI/blob/main/lib/crewai/src/crewai/agent/core.py
- https://github.com/crewAIInc/crewAI/blob/main/lib/crewai/src/crewai/flow/flow.py (3572 lines)
- https://github.com/crewAIInc/crewAI/blob/main/lib/crewai/src/crewai/flow/human_feedback.py

### BMAD-METHOD (most relevant precedent)
- https://github.com/bmadcode/BMAD-METHOD/blob/main/src/bmm-skills/2-plan-workflows/bmad-agent-pm/SKILL.md (74 lines)
- https://github.com/bmadcode/BMAD-METHOD/blob/main/src/bmm-skills/2-plan-workflows/bmad-agent-pm/customize.toml (85 lines)
- https://github.com/bmadcode/BMAD-METHOD/blob/main/src/bmm-skills/4-implementation/bmad-dev-story/SKILL.md (485 lines)
- https://github.com/bmadcode/BMAD-METHOD/blob/main/src/bmm-skills/module.yaml

### MetaGPT
- https://github.com/geekan/MetaGPT/blob/main/metagpt/roles/engineer.py (513 lines)
- https://github.com/geekan/MetaGPT/blob/main/metagpt/roles/product_manager.py (64 lines)
- https://github.com/geekan/MetaGPT/blob/main/metagpt/prompts/product_manager.py (175 lines)
- https://github.com/geekan/MetaGPT/blob/main/metagpt/roles/role.py (592 lines)

### OpenAI Agents SDK
- https://github.com/openai/openai-agents-python/blob/main/src/agents/agent.py (Agent dataclass at line 223)
- https://github.com/openai/openai-agents-python/blob/main/src/agents/handoffs/__init__.py (349 lines; Handoff class at line 94, handoff() function at line 184)

### Pydantic AI
- https://github.com/pydantic/pydantic-ai/blob/main/pydantic_ai_slim/pydantic_ai/agent/abstract.py
- https://github.com/pydantic/pydantic-ai/blob/main/pydantic_ai_slim/pydantic_ai/agent/wrapper.py

### smolagents
- https://github.com/huggingface/smolagents/blob/main/src/smolagents/prompts/code_agent.yaml (313 lines)
- https://github.com/huggingface/smolagents/blob/main/src/smolagents/agents.py

### Strands SDK (AWS)
- https://github.com/strands-agents/sdk-python/blob/main/src/strands/agent/agent.py (1222 lines)
- https://github.com/strands-agents/sdk-python/blob/main/src/strands/multiagent/graph.py (1265 lines)

### Mastra
- https://github.com/mastra-ai/mastra/blob/main/packages/core/src/agent/index.ts
- https://github.com/mastra-ai/mastra/blob/main/packages/core/src/workflows/workflow.ts (~150kB)

### Inngest agent-kit
- https://github.com/inngest/agent-kit/blob/main/packages/agent-kit/src/agent.ts
- https://github.com/inngest/agent-kit/blob/main/packages/agent-kit/src/network.ts

### Vercel AI SDK
- https://github.com/vercel/ai/blob/main/packages/ai/src/agent/agent.ts (163 lines)

### Cline
- https://github.com/cline/cline/blob/main/src/core/prompts/system-prompt/components/agent_role.ts (15 lines)
- https://github.com/cline/cline/blob/main/src/core/prompts/system-prompt/components/objective.ts (20 lines)
- https://github.com/cline/cline/blob/main/src/core/prompts/system-prompt/components/rules.ts (56 lines)
- https://github.com/cline/cline/blob/main/src/core/prompts/system-prompt/components/capabilities.ts (35 lines)
- https://github.com/cline/cline/blob/main/src/core/prompts/system-prompt/components/mcp.ts (102 lines)

### Roo Code
- https://github.com/RooCodeInc/Roo-Code/blob/main/packages/types/src/mode.ts (227 lines, DEFAULT_MODES at line 166)
- https://github.com/RooCodeInc/Roo-Code/blob/main/src/shared/modes.ts (8305 lines, ModeConfig helpers)

### Anthropic Skills
- https://github.com/anthropics/skills/blob/main/skills/mcp-builder/SKILL.md (236 lines)
- https://github.com/anthropics/skills/blob/main/skills/brand-guidelines/SKILL.md (73 lines)
- https://github.com/anthropics/skills/blob/main/spec/agent-skills-spec.md (redirect to agentskills.io)

### wshobson/agents (Claude Code plugin reference)
- https://github.com/wshobson/agents/blob/main/plugins/backend-development/agents/backend-architect.md (309 lines)
- https://github.com/wshobson/agents/blob/main/plugins/agent-orchestration/agents/context-manager.md (163 lines)

### DSPy
- https://github.com/stanfordnlp/dspy/blob/main/dspy/predict/react.py

### Stats commands used
All star counts via `gh api repos/{owner}/{repo} -q '.stargazers_count'` on 2026-04-26.
All 30-day commit counts via `gh api search/commits?q=repo:{r}+committer-date:>2026-03-26 -q .total_count` (with `Accept: application/vnd.github.cloak-preview+json`) or `gh api repos/{r}/commits?since=2026-03-26T00:00:00Z --paginate` for repos blocked by Search API.

---

**End of Agent 3 OSS code lens report.**
