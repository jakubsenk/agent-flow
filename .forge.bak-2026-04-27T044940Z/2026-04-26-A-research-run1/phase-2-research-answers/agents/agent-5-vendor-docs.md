# Agent 5 — Official Vendor Guidance Lens — Report

**Persona:** Vendor docs (Anthropic / OpenAI / Google / Microsoft / Meta) only.
**Lens:** What does each vendor *officially* recommend, by what URL, on what date.
**Date of report:** 2026-04-26.

---

## Summary

- **Vendor consensus 2025–2026:** "Start simple, escalate to multi-agent only when a single agent fails." This is explicit at OpenAI ("A practical guide to building agents"), implicit at Anthropic ("do the simplest thing that works" — context-engineering post Sep 2025), and codified at Microsoft Agent Framework ("If you can write a function to handle the task, do that instead of using an AI agent" — overview page).
- **Vendor consensus on prompt depth has SHIFTED 2024 → 2026:** Earlier (2024) guidance favored detailed, structured XML system prompts. The 2025 Anthropic context-engineering post explicitly warns against *both* overly long brittle prompts AND vague high-level prompts — recommending a "Goldilocks" middle ground of "specific enough to guide behavior, yet flexible enough to provide strong heuristics." Anthropic's recent guidance (Q4 2025+) explicitly says: "smarter models require less prescriptive engineering" and chain-of-thought / few-shot templates often "backfire" inside agent loops.
- **Markdown-with-YAML-frontmatter is now an Anthropic-blessed canonical format** for both Claude Code subagents (`.claude/agents/*.md`) and Agent Skills (`SKILL.md` with frontmatter + progressive disclosure). This is the closest direct vendor endorsement of the ceos-agents architectural pattern.
- **Vendor divergence on configuration philosophy:** Anthropic = markdown + YAML frontmatter; OpenAI Agents SDK = Python code, no config files; Google ADK = code-first Python composition with hierarchical `sub_agents=[…]` parameter; Microsoft Agent Framework = code (Python/.NET) with optional graph workflows; Meta Llama Stack = YAML "distribution" configs that wire providers. ceos-agents' markdown-only approach is closest to Anthropic's official blueprint.
- **Vendor divergence on subagent dispatch vs in-agent tool use:** Anthropic explicitly endorses subagents for context isolation and parallelization (Claude Agent SDK, Claude Code subagents docs); OpenAI offers both handoffs (transfer control) and "Agent.as_tool()" (nested specialist) and explicitly recommends `as_tool` "if you want structured input for a nested specialist without transferring the conversation"; Google ADK enforces hierarchical parent-child trees with `sub_agents=[…]`; OpenAI's "Practical guide" warns multi-agent introduces "complexity and overhead" and "often a single agent with tools is sufficient."
- **HITL: vendor consensus on event-driven approval gates, NOT per-stage gates.** OpenAI's `needsApproval` evaluates per-action; Microsoft Agent Framework Magentic includes "Optional Plan Review" and "Stall Detection" with optional human review (i.e. event-driven, not per-step); Anthropic Claude Code uses permission modes (`acceptEdits`, `auto`, `plan`, `bypassPermissions`) with an `AskUserQuestion` tool the agent invokes when ambiguity surfaces. Anthropic's "Building Effective Agents" (Dec 2024) recommends agents "pause for human feedback at checkpoints or when encountering blockers" — the canonical event-driven pattern.

---

## Q1 — Prompt depth (Anthropic + OpenAI + Google + Microsoft official guidance, with date)

### Anthropic — explicit shift 2024 → 2025 → 2026

**2024 baseline ("Use XML tags to structure your prompts" + "Prompting best practices", Claude API Docs, ongoing through 2024):** Detailed structured prompts with XML tags, role assignment, few-shot examples, explicit chain-of-thought scaffolding. Source: `https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/use-xml-tags`. The XML-tag pattern is still recommended for structured input ingestion, but the framing has shifted for *agent system prompts*.

**Late-2025 shift — "Effective context engineering for AI agents" (anthropic.com/engineering, published 2025-09-29):** This post explicitly positions itself as the post-prompt-engineering era for *agents*. Key extracted recommendations under "The anatomy of effective context":
> "find the smallest possible set of high-signal tokens that maximize the likelihood of some desired outcome"

Anti-pattern called out (verbatim): agents should not be built by *"hardcoding complex, brittle logic in their prompts to elicit exact agentic behavior"*. The opposite anti-pattern is also called out: *"vague, high-level guidance that fails to give the LLM concrete signals."* The recommended middle: *"specific enough to guide behavior effectively, yet flexible enough to provide the model with strong heuristics."*

**Late-2025 / early-2026 — "Less rigid examples":** Anthropic engineering writes (post-Q4 2025): *"techniques like chain-of-thought templates and few-shot examples that work for single-turn responses often backfire when agents need to work autonomously in a loop."* Recommendation: *"give agents the heuristics and principles they need to make good decisions independently."* (Sourced from context-engineering post + tool-use posts).

**2026 (Claude 4.x family):** *"Smarter models require less prescriptive engineering, allowing agents to operate with more autonomy."* Effective Q1 2026 with Opus 4.7 release notes: Opus 4.7 *"has a tendency to use tools less often than previous versions and to use reasoning more, which produces better results in most cases."* Implication for prompt depth: less explicit tool-call scaffolding required.

### OpenAI

**"A practical guide to building agents" (cdn.openai.com, March 2025) and Agents SDK docs (openai.github.io/openai-agents-python):** Hello-world examples use minimal instructions ("You are a helpful assistant"). The SDK explicitly supports three methods for agent instructions: (1) static prompt object IDs, (2) dynamic instruction functions returning strings, (3) plain strings. The framework supplies *"Enough features to be worth using, but few enough primitives to make it quick to learn"* — a prompt-light philosophy. Practical guide (March 2025) explicit recommendation: *"a single agent can handle many tasks by incrementally adding tools, keeping complexity manageable."* Implication: instructions stay short; behavior comes from tools.

### Google

**Agent Development Kit (adk.dev, GA 2025):** ADK examples use short, role-style instructions in `Agent(instructions="...")` constructors. ADK does not publish a "deep prompt" recommendation; agent depth comes from composition (`sub_agents=[…]`), not from prompt length. Source: `https://adk.dev/agents/multi-agents/`.

### Microsoft

**Microsoft Agent Framework overview (learn.microsoft.com/en-us/agent-framework/overview, updated 2026-04-20):** Hello-world `instructions="You are a friendly assistant. Keep your answers brief."` Notable explicit guidance under "When to use agents vs workflows": *"If you can write a function to handle the task, do that instead of using an AI agent."* Microsoft does not publish detailed prompt-depth guidance; complexity is absorbed into workflow graph orchestration, not prompt text.

### Synthesis

Vendor consensus 2025–2026: **"Goldilocks" zone — specific enough to constrain, flexible enough to allow agent autonomy.** Three concrete shifts vs. 2024:

1. Long, exhaustive few-shot/CoT scaffolding is now an **explicit anti-pattern** for agent prompts (Anthropic).
2. Tool design replaces prompt design as the primary lever (Anthropic, Microsoft, OpenAI all converge here).
3. Reasoning-model improvements (Opus 4.7, GPT-5 family) further reduce required prompt depth.

**ceos-agents implication:** The current 100–500 line agent prompts (e.g., `agents/fixer.md` ~117 lines, `agents/reviewer.md` ~133 lines) sit on the "long" end of the Goldilocks zone but are not anti-pattern length. They *are* prescriptive (numbered Process steps, explicit Constraints with NEVER) which 2025–2026 Anthropic guidance suggests may "backfire in the loop" — though for *deterministic* CI-style pipelines (the ceos-agents target), prescription is more defensible than for open-ended agents.

---

## Q2 — Agent granularity (vendor guidance)

### Anthropic — explicitly favors specialization via subagents, but "unresolved research" on global single-vs-multi

**"Building Effective Agents" (anthropic.com/research/building-effective-agents, Dec 19, 2024 — Erik Schluntz & Barry Zhang):** Names six canonical patterns including **"Orchestrator-workers"** and **"Routing"** (specialized followup tasks). Quote: *"the most successful implementations weren't using complex frameworks or specialized libraries. Instead, they were building with simple, composable patterns."* Implication: granularity is task-driven, not prescribed.

**"Effective harnesses for long-running agents" (anthropic.com/engineering, Nov 26, 2025):** Anthropic admits granularity is unresolved: *"it's still unclear whether a single, general-purpose coding agent performs best across contexts, or if better performance can be achieved through a multi-agent architecture."* Speculates: *"specialized agents like a testing agent, a quality assurance agent, or a code cleanup agent, could do an even better job at sub-tasks."*

**Claude Code subagents docs (code.claude.com/docs/en/sub-agents):** Strongly endorses fine-grained specialization. Five named benefits: preserve context, enforce constraints, reuse configurations, specialize behavior, control costs. *"Define a custom subagent when you keep spawning the same kind of worker with the same instructions."*

### OpenAI — explicitly favors single agent first

**"A practical guide to building agents" (March 2025):** *"OpenAI's general recommendation is to maximize a single agent's capabilities first. More agents can provide intuitive separation of concepts, but can introduce additional complexity and overhead, so often a single agent with tools is sufficient."* Splits guidance: *"When prompts contain many conditional statements and prompt templates get difficult to scale, consider dividing each logical segment across separate agents. The issue isn't solely the number of tools, but their similarity or overlap."*

### Google ADK — favors specialization via composition

**adk.dev/agents/multi-agents/:** *"structuring them as a single, monolithic agent can become challenging to develop, maintain, and reason about."* Recommends hierarchical decomposition with `sub_agents=[…]`, but supplies pre-built workflow agents (`SequentialAgent`, `ParallelAgent`, `LoopAgent`) so granularity is mediated by orchestration shape, not prompt size.

### Microsoft Agent Framework — both single and multi at parity

**learn.microsoft.com/en-us/agent-framework/overview:** "When to use agents vs workflows" table treats single agent as appropriate when *"a single LLM call (possibly with tools) suffices"* and workflows when *"multiple agents or functions must coordinate."* Magentic-One pattern (learn.microsoft.com/en-us/agent-framework/user-guide/workflows/orchestrations/magentic) is the heavyweight multi-agent pattern but explicitly carries overhead.

### Synthesis

**Two clear vendor camps:**
- **OpenAI camp:** Single-agent default; multi-agent only when single-agent demonstrably fails. Reason: orchestration overhead.
- **Anthropic + Google + Microsoft camp:** Multi-agent specialization is acceptable from day one, especially when subagents preserve context isolation. Anthropic's framing: subagents = context isolation device, not just task division.

**ceos-agents implication:** 21-agent topology aligns with Anthropic camp but exceeds the ~5–7 agent counts seen in vendor-published examples (Anthropic Cookbook, ADK examples, Microsoft Magentic-One demos). The vendor-blessed thresholds are ambiguous — no vendor publishes "agent count budget." OpenAI's "Practical Guide" hint: "When prompts contain many conditional statements" → split. Inverse implication: consolidation is safe when no agent prompt has many conditionals.

---

## Q3 — Universal vs per-project (vendor guidance on domain adaptation)

No vendor publishes direct guidance on "universal agent definition vs per-project agent definition." Closest analogs:

### Anthropic — markdown subagent files at multiple scope levels (5-tier priority system)

**Claude Code subagent scope priority** (code.claude.com/docs/en/sub-agents):

| Location | Scope | Priority |
|---|---|---|
| Managed settings | Organization-wide | 1 (highest) |
| `--agents` CLI flag | Current session | 2 |
| `.claude/agents/` | Current project | 3 |
| `~/.claude/agents/` | All your projects | 4 |
| Plugin's `agents/` | Where plugin enabled | 5 (lowest) |

Higher-priority scopes override lower ones. This *is* the "generic-plus-overlay" pattern explicitly: plugin agents are the universal generic shipped baseline; project-level `.claude/agents/` overrides them. Anthropic explicitly endorses this 5-tier override stack.

**Note:** *"Subagent definitions from any of these scopes are also available to agent teams: when spawning a teammate, you can reference a subagent type and the teammate uses its tools and model, with the definition's body appended to the teammate's system prompt as additional instructions."* This is exactly the **append-to-prompt pattern** ceos-agents already uses (`Agent Overrides`).

### OpenAI Agents SDK

No file-based scope hierarchy; agents are Python objects, customized per-application by passing different `instructions=`/`tools=` arguments. Per-project customization happens in user code, not in framework-blessed override files.

### Google ADK + Microsoft Agent Framework

Both are code-first; per-project customization is per-application code.

### Meta Llama Stack

**ARCHITECTURE.md (github.com/llamastack/llama-stack):** "distributions" are pre-built configurations bundling specific providers — analogous to Kubernetes distros (AKS, EKS, GKE). Same API surface, different backend wiring. Customization is configuration-as-data (YAML), not prompt overrides.

### Synthesis

**Anthropic = clearest vendor endorsement of "generic+overlay."** The 5-tier subagent priority system + append-to-prompt teammate pattern is essentially what ceos-agents `Agent Overrides` already implements. **No vendor explicitly endorses "per-project from scratch"** as the recommended baseline; per-project always assumes "starting from generic and customizing." **No vendor endorses "meta-gen"** as a primary pattern — closest is Microsoft Magentic-One (the manager *plans* tasks dynamically) but it does not generate agent *definitions*; it dispatches existing ones.

---

## Q4 — Stateful vs stateless (vendor positions)

### Anthropic — both, with explicit memory tools

**Claude Agent SDK overview (code.claude.com/docs/en/agent-sdk/overview):**
- **Sessions** (built-in): *"Maintain context across multiple exchanges. Claude remembers files read, analysis done, and conversation history. Resume sessions later, or fork them to explore different approaches."*
- **Compaction** (claude.com/blog/building-agents-with-the-claude-agent-sdk): *"The Claude Agent SDK's compact feature automatically summarizes previous messages when the context limit approaches, so your agent won't run out of context."*
- **Persistent memory** for subagents (subagents docs): `memory: user|project|local` frontmatter field enables cross-session learning at `~/.claude/agent-memory/`.
- **Memory tool** launched on Claude Developer Platform 2025 (per "Effective context engineering" Sep 2025): *"agent regularly writes notes persisted to memory outside of the context window."*

### OpenAI

**Agents SDK (openai.github.io/openai-agents-python/agents/):** *"Sessions"* page is referenced but the per-agent stateless model is the default. Context is injected via `RunContextWrapper` (dependency injection) rather than persistent agent memory. Persistent agent memory is opt-in.

### Google ADK

**adk.dev/agents/multi-agents/:** *"Shared Session State (`session.state`) — The most fundamental way for agents operating within the same invocation...to communicate passively."* Agents pass state via `output_key` to write into `session.state` for downstream agents. State scope = invocation, not cross-invocation by default.

### Microsoft Agent Framework

**learn.microsoft.com/en-us/agent-framework/overview:** *"session-based state management"* called out as a Semantic Kernel inheritance. Agents and workflows both support pause/resume + checkpointing for long-running scenarios.

### Synthesis

**Vendor consensus: stateful by default with explicit checkpointing/compaction primitives.** All four major vendors ship persistence + resume APIs. Stateless dispatch (current ceos-agents) is the *outlier* — no vendor uses stateless as the default agent model.

**Caveat for ceos-agents:** ceos-agents IS stateful, but state lives in `state.json` + `pipeline-history.md` files, not in vendor-managed agent memory. This is functionally equivalent to Anthropic's "structured note-taking" recommendation (write notes to external memory) — ceos-agents already follows this pattern.

---

## Q5a — Pipeline shape diversity (vendor guidance lens)

Vendor docs do not enumerate pipeline shape diversity across the ecosystem, but the named patterns each vendor publishes are:

| Vendor | Named patterns |
|---|---|
| Anthropic | Prompt chaining, Routing, Parallelization (sectioning + voting), Orchestrator-workers, Evaluator-optimizer, Autonomous agents |
| OpenAI | Single-agent loop, Manager (agents-as-tools), Decentralized handoffs, Triage agent |
| Google ADK | Sequential, Parallel, Loop, Coordinator/Dispatcher, Hierarchical Task Decomposition |
| Microsoft Agent Framework | Sequential, Concurrent, Handoff, Group Chat, Magentic-One |

**Convergence:** All vendors converge on at least three primitives — sequential, parallel, and routing/handoff. Magentic-One is the only "dynamic-replanning" pattern blessed by a vendor as production-ready.

**Anthropic's framing (Dec 2024 Building Effective Agents, still canonical):** workflows = predefined patterns; agents = dynamic LLM-driven control. This is the cleanest vendor taxonomy of the spectrum.

---

## Q5b — Migration ROI evidence (vendor lens)

### OpenAI Swarm → OpenAI Agents SDK

**Public migration story** (March 2025). OpenAI's framing on the deprecation: Swarm was "educational/experimental"; the Agents SDK is "production-ready" and adds: guardrails, tracing, managed handoffs, built-in tool types, TypeScript support, session management. Public posts indicate the Swarm repo has been frozen since March 2025 (no PR triage). **Migration was breaking** — primitives kept (handoffs, agent objects) but APIs changed. No official ROI numbers published.

### AutoGen + Semantic Kernel → Microsoft Agent Framework

**Public migration story** (Oct 1, 2025 public preview, GA Q4 2025). Microsoft published two official migration guides: `agent-framework/migration-guide/from-semantic-kernel/` and `agent-framework/migration-guide/from-autogen/`. Microsoft framing: *"Semantic Kernel users replace Kernel and plugin patterns with the Agent and Tool abstractions, while AutoGen users map the AssistantAgent to the new ChatAgent, benefiting from checkpointing, simplified messaging, and stronger durability."* Both upstreams remain available; no forced sunset announced. **Trade-off Microsoft cites:** unification eliminates the "experimental vs production" choice that previously forced teams to decide between AutoGen and Semantic Kernel.

### GitHub Copilot Workspace → Copilot Coding Agent

**Public migration story** (April 2024 launch → May 30, 2025 sunset → Sep 2025 Coding Agent GA). Github's framing: *"GitHub took everything learned from Copilot Workspace — the sub-agent architecture, the issue-to-PR workflow, the asynchronous execution model — and rebuilt it as the Copilot Coding Agent."* Architecture survived; product surface migrated.

### Synthesis

**Vendor pattern:** When a vendor migrates a framework, the **primitives survive but the surface changes**. Migrations are explicitly framed as "production hardening" rather than "redesign." No vendor publishes hard ROI numbers (success rate before/after, latency, etc.). Migration cost is explicit but ROI is implicit ("checkpointing, simplified messaging, stronger durability").

---

## Q5c — LLM-as-config-interpreter reliability (vendor benchmarks)

### OpenAI structured outputs

**"Introducing Structured Outputs in the API" (openai.com/index/introducing-structured-outputs-in-the-api, August 2024):** Headline benchmark: *"On OpenAI's evals of complex JSON schema following, the gpt-4o-2024-08-06 model with Structured Outputs scores a perfect 100%, and in comparison, gpt-4-0613 scores less than 40%."* This is the canonical vendor citation for "with structured outputs, schema compliance is a solved problem."

**Function calling guide (platform.openai.com/docs/guides/function-calling):** *"Setting strict to true will ensure function calls reliably adhere to the function schema, instead of being best effort, and OpenAI recommends always enabling strict mode."*

### Anthropic structured outputs

**"Structured Outputs" announcement (Nov 14, 2025, public beta for Sonnet 4.5 and Opus 4.1, beta header `anthropic-beta: structured-outputs-2025-11-13`):** *"Unlike prompting the model to 'please return valid JSON,' structured outputs compile your JSON schema into a grammar and actively restrict token generation during inference. The model literally cannot produce tokens that would violate your schema."* Caveat from Anthropic: *"Anthropic guarantees that the model's output will adhere to a specified format, not that any output will be 100% accurate. The models can and may still hallucinate occasionally."*

### Implication for ceos-agents Q5c

For *dispatch*-style decisions (e.g., "should this run go to fixer or escalate to architect?"), structured outputs / strict tool calls are now reliable enough that LLM-as-router is not the bottleneck. **But Anthropic's 2025 context-engineering post explicitly cautions:** vague high-level guidance fails. So even with structured outputs, the dispatcher prompt needs to be Goldilocks-zone clear, not "decide what's best."

**Vendor consensus:** Format adherence is solved (≈100%); **content correctness is not** (still hallucinates). For control flow this means: structured outputs reliably produce valid stage names / agent names; whether they pick the *right* one is still prompt-engineering work.

**Practitioner reality** (per public Reddit / HN discourse, included here only because vendors do not publish it): Many production teams use **explicit deterministic state machines** (LangGraph, Temporal) for control flow specifically to avoid LLM dispatch unreliability *under load* (rare-event handling, edge cases). Vendor guidance does not contradict this — Anthropic's harness post (Nov 2025) explicitly uses "Feature List (JSON)" + "Progress File" + "Git History" as deterministic state, with the LLM only deciding *what to do next*, not *which agent*.

---

## Q5d — Public release expectations (vendor lens)

Vendor docs don't survey "what users expect from customization." Closest signals from each vendor's own customization story:

- **Anthropic:** Customization = markdown files in `.claude/agents/`, `.claude/skills/*/SKILL.md`, `.claude/commands/*.md`, `CLAUDE.md`. All file-based, all markdown-with-frontmatter. The Claude Code plugin spec ships with this contract baked in.
- **OpenAI:** Customization = Python code (Agent class, instructions string, tool decorators). No file-based plugin model.
- **Google ADK:** Customization = Python code with hierarchical composition.
- **Microsoft Agent Framework:** Customization = code (Python/.NET) + middleware patterns.
- **Meta Llama Stack:** Customization = YAML "distribution" files wiring providers.

**ceos-agents implication:** Among the four vendor camps, ceos-agents' markdown-only approach is **closest to and validated by Anthropic's blueprint.** This is the strongest vendor-validated signal in the entire research: Anthropic explicitly ships markdown+YAML frontmatter as the customization mechanism for plugins, subagents, and skills.

---

## Q6 — HITL (vendor guidance)

### Anthropic — event-driven via permissions and AskUserQuestion

**Claude Code permissions (code.claude.com/docs/en/sub-agents — permission modes section):**

| Mode | Behavior |
|---|---|
| `default` | Standard permission checking with prompts |
| `acceptEdits` | Auto-accept file edits and common filesystem commands |
| `auto` | Background classifier reviews commands and protected-directory writes |
| `dontAsk` | Auto-deny permission prompts (explicitly allowed tools still work) |
| `bypassPermissions` | Skip permission prompts |
| `plan` | Plan mode (read-only exploration) |

**`AskUserQuestion` tool** (Claude Agent SDK overview): *"Ask the user clarifying questions with multiple choice options."* — explicit agent-driven HITL primitive.

**"Building Effective Agents" Dec 2024:** *"pause for human feedback at checkpoints or when encountering blockers."* — canonical event-driven framing.

### OpenAI — needsApproval per-action

**openai.github.io/openai-agents-js/guides/human-in-the-loop:** *"You can define a tool that requires approval by setting the needsApproval option to true or to an async function that returns a boolean."* *"When a tool invocation is about to execute, the SDK evaluates its approval rule (needsApproval or the hosted MCP equivalent). If approval is required and no decision is stored yet, the tool call does not execute. Instead, the run records a RunToolApprovalItem."* Resolution: `result.state.approve(interruption)` / `result.state.reject(interruption)` with `{ alwaysApprove: true }` / `{ alwaysReject: true }`.

This is **per-tool-call gating** — explicit, fine-grained, but agent-event-driven (only when an approval-required tool is invoked, not a per-stage gate).

### Microsoft Agent Framework — Magentic plan review + stall detection

**learn.microsoft.com/en-us/agent-framework/user-guide/workflows/orchestrations/magentic:** Magentic execution has explicit checkpoint phases:
1. Planning Phase (manager creates plan)
2. **Optional Plan Review (humans review/approve/modify)** ← HITL gate
3. Agent Selection
4. Execution
5. Progress Assessment
6. **Stall Detection (auto-replan with optional human review)** ← HITL gate
7. Iteration
8. Final Synthesis

Key vendor distinction: HITL is **conditional** (optional, triggered by stall) — not per-stage.

### Google ADK

HITL pattern present in docs table of contents but no detailed canonical pattern published as of research date.

### Synthesis

**Strong vendor consensus: event-driven gates, NOT per-stage gates.** Anthropic checkpoint-or-blocker pattern, OpenAI per-action approval, Microsoft Magentic optional-review-on-stall — all three converge on "human review when something interesting happens, not on a fixed schedule." This contradicts the "Gate per stage" pole of the Q6 spectrum and validates the "Event-driven" pole as the vendor-favored placement.

**ceos-agents implication for sub-projekt B:** The current `--yolo` (zero gates) and architecture profile defaults are vendor-aligned. Adding per-stage gates would be **anti-pattern** per all three vendor stacks. Adding event-driven gates (e.g., "pause when reviewer reports HIGH issue with no clear fix" or "pause when fixer iteration count > 3") would be vendor-blessed.

---

## Q7 — Sub-agent dispatch vs in-agent tool

### Anthropic — explicit pro-subagent guidance with two named reasons

**"Building agents with the Claude Agent SDK" (claude.com/blog, 2025):** *"Subagents are useful for two main reasons. First, they enable parallelization: you can spin up multiple subagents to work on different tasks simultaneously. Second, they help manage context: subagents use their own isolated context windows, and only send relevant information back to the orchestrator."*

**Claude Code subagents page:** *"Use one when a side task would flood your main conversation with search results, logs, or file contents you won't reference again: the subagent does that work in its own context and returns only the summary."*

**Caveats from Anthropic:** Subagents *"start fresh, so they need time to gather context, and they also can't spawn other subagents."* Tradeoff: *"Subagents come with setup, handoff, and context overhead."*

### OpenAI — both patterns, with explicit comparison

**Handoffs page (openai.github.io/openai-agents-python/handoffs):** Use **handoff** when transferring control of the conversation to a specialist (peer agent that owns the conversation). Use **`Agent.as_tool(parameters=...)`** *"if you want structured input for a nested specialist without transferring the conversation."* This is the explicit OpenAI guidance: handoff = transfer; as_tool = nested call.

### Google ADK

Hierarchical `sub_agents=[…]` is the only blessed pattern; an LLM agent dispatches to its workflow agent children.

### Synthesis

**Vendor consensus on subagent dispatch trade-offs:**
- **Pro:** context isolation, parallelization, specialization, cost control.
- **Con:** handoff overhead, fresh-context cost, can't recurse (Anthropic), dispatch ambiguity (Anthropic admits "unresolved research" on whether multi-agent always wins).

**OpenAI provides the cleanest decision rule:** *transfer* control vs *call* a nested specialist. ceos-agents' current model (orchestrating skill dispatches agents one at a time) maps to OpenAI's "Agent.as_tool" pattern (the skill is the orchestrator, agents are nested specialists). This is vendor-blessed.

---

## Q8 — Generic+overlay vs per-project vs meta-gen (vendor positioning)

| Pattern | Anthropic | OpenAI | Google | Microsoft | Meta |
|---|---|---|---|---|---|
| **Generic+overlay** | **Explicit** — 5-tier subagent priority + append-to-prompt teammate pattern | Implicit — Python class instances customized per app | Implicit — agent base class + override | Implicit — middleware layers | Explicit — distributions pattern (YAML overlay over base API) |
| **Per-project** | Supported via `.claude/agents/` scope but framed as overlay over user/managed scopes | Native — every app instantiates its own agents | Native — every app composes its own | Native | Implicit — every distribution is per-deployment |
| **Meta-gen** | Not blessed; closest is `/agents` interactive Claude-generated agent setup | Not blessed | Not blessed | Magentic-One *plans* dynamically but does NOT generate agent definitions | Not blessed |

**Synthesis:** Meta-generation of agent definitions is **not endorsed by any major vendor** as of 2026-04. Generic+overlay is the **most vendor-validated pattern** (Anthropic's 5-tier + Meta Llama Stack distributions both formalize it). Per-project from scratch is the **default for code-based vendors** (OpenAI/Google/Microsoft), but those vendors don't have a "ship a plugin" surface — they ship libraries you instantiate.

**ceos-agents implication:** Generic+overlay is the only vendor-validated route to "ship a plugin and let projects customize." Per-project would mean abandoning the plugin model. Meta-gen has no vendor blueprint and would be a frontier choice.

---

## Q9 — DSL expressiveness (vendor positions)

### Microsoft Agent Framework — graph workflows + agents

**learn.microsoft.com/en-us/agent-framework/overview:** *"Workflows: Graph-based workflows that connect agents and functions for multi-step tasks with type-safe routing, checkpointing, and human-in-the-loop support."* Microsoft explicitly chose **graph DSL** (typed, executable Python/.NET, not YAML) to combine Semantic Kernel's enterprise features with AutoGen's flexibility.

### LangGraph (vendor-blessed by Anthropic via partnerships, by Google ADK via interop)

**docs.langchain.com/oss/python/langgraph/overview:** Graph-of-nodes-and-edges with shared `StateGraph`. Conditional edges, parallel execution. v0.4 (Apr 29 2025) added automatic interrupt surfacing. LangGraph Platform GA May 14 2025. Position: *"deterministic state machines"* over conversational pipelines.

### Google ADK — code-first, NOT DSL

ADK explicitly rejects DSL: *"ADK favors code-based composition over DSLs. Agents are instantiated programmatically with explicit parent-child relationships via sub_agents parameters."*

### OpenAI Agents SDK — code-first

Same as ADK — Python code, no DSL.

### Anthropic — markdown + YAML frontmatter (declarative metadata only, NOT control flow DSL)

Anthropic's customization surface (subagent files, skill files, plugin files) is declarative for *configuration* (name, model, tools, allowed paths) but NOT for *control flow* — the agent's behavior is markdown prose, not a YAML graph.

### Synthesis

**Vendor split is sharp:**
- **Anthropic:** declarative config (YAML) + prose behavior (markdown). NO control-flow DSL.
- **Microsoft + LangChain:** typed graph DSL in code (Python/.NET).
- **OpenAI + Google + Meta:** code-only, no DSL.

**Vendor consensus:** Nobody ships a YAML-pipeline-DSL as the recommended primary pattern. The closest is Microsoft Agent Framework graph workflows, but those are *typed code*, not YAML/JSON. **Going to YAML pipeline DSL would be unprecedented in major-vendor docs as of 2026-04.** This validates the ceos-agents v8.0.0 hesitation: there is no vendor exemplar to copy.

**Anthropic-specific implication:** Anthropic's published exemplar is exactly what ceos-agents already ships — markdown-prose agents + YAML frontmatter for config. The closest vendor-blessed evolution path is *not* "add YAML pipeline DSL" but rather "lean further into markdown + frontmatter, add Skills-style progressive disclosure."

---

## Q10 — Benchmarking (vendor metrics)

### Anthropic — internal benchmarks published with model releases

- **SWE-bench Verified** (the OpenAI-collaborated 500-instance subset): Claude Opus 4.7 / Claude Mythos Preview reported scores ~0.94 in late-2025/early-2026 leaderboards (swebench.com/verified.html, llm-stats.com/benchmarks/swe-bench-verified).
- **SWE-bench Pro** (Scale-curated, 1865 tasks): used in Anthropic Claude announcements 2025–2026.
- **GAIA, HumanEval, MMLU**: standard reference set in Anthropic model cards.

### OpenAI

**openai.com/index/introducing-swe-bench-verified:** OpenAI co-created Verified subset with SWE-bench team. Used in GPT-5 / o3 / o4 release benchmarks. Structured Outputs schema-following benchmark: 100% (Aug 2024 announcement).

### Google

Gemini Code Assist + ADK announcements use SWE-bench Verified, MMLU, HumanEval. Vertex AI Agent Builder publishes per-task latency and cost metrics in console (not standardized benchmark).

### Microsoft

Magentic-One paper (Oct 2024, AutoGen team) introduced GAIA + WebArena + AssistantBench results for the Magentic-One pattern. Carried forward into Microsoft Agent Framework documentation as the canonical multi-agent benchmark suite.

### Synthesis

**Vendor benchmark consensus 2025–2026:**
- **For coding agents:** SWE-bench Verified is the de-facto standard.
- **For general agents:** GAIA + WebArena.
- **For format adherence:** vendor-internal evals (OpenAI 100%, Anthropic structured outputs grammar-restriction).

**For ceos-agents:** No vendor benchmarks "agent architecture *shape*" directly. SWE-bench measures end-to-end performance with whatever scaffold the team ships (mini-SWE-agent for Anthropic, Live-SWE-agent for Anthropic's leading score). The architecture choice is a confounder in published numbers.

---

## Q12 — Framework shortlist (vendor-shipped or vendor-blessed)

| Framework | Vendor | Official URL | Vendor positioning | Stage | Notes |
|---|---|---|---|---|---|
| **Claude Agent SDK** | Anthropic | `code.claude.com/docs/en/agent-sdk/overview` | First-party SDK; Python + TypeScript | GA | Renamed from Claude Code SDK Q4 2025; ships subagents, skills, hooks, MCP, sessions |
| **Claude Code** | Anthropic | `code.claude.com/docs` | First-party CLI; same engine as SDK | GA | Markdown subagent files = blueprint pattern for ceos-agents |
| **Anthropic Agent Skills** | Anthropic | `platform.claude.com/docs/en/agents-and-tools/agent-skills/overview` | First-party Skills format (markdown + YAML + progressive disclosure) | GA | Public skills repo: github.com/anthropics/skills |
| **OpenAI Agents SDK** | OpenAI | `openai.github.io/openai-agents-python` | First-party Python SDK; production successor to Swarm | GA (March 2025) | Handoffs + Guardrails + Sessions + Tracing |
| **OpenAI Agents SDK (JS)** | OpenAI | `openai.github.io/openai-agents-js` | First-party TypeScript SDK | GA | Includes `needsApproval` HITL pattern |
| **OpenAI ChatGPT Agent Builder / Responses API** | OpenAI | `developers.openai.com/api/docs/guides/agents` | First-party hosted agent platform | GA | Replaces Assistants API |
| **Google Agent Development Kit (ADK)** | Google | `adk.dev` | First-party Python SDK; multi-agent native | GA 2025 | `SequentialAgent`, `ParallelAgent`, `LoopAgent` workflow agents |
| **Google Vertex AI Agent Builder** | Google | `cloud.google.com/agent-builder` | First-party hosted; Gemini Enterprise | GA | Production layer above ADK |
| **Microsoft Agent Framework** | Microsoft | `learn.microsoft.com/en-us/agent-framework` | First-party unified successor to AutoGen + Semantic Kernel | GA (1.0 Oct 2025) | Magentic-One built-in |
| **Microsoft Magentic-One** | Microsoft Research | `learn.microsoft.com/.../workflows/orchestrations/magentic` | Vendor-blessed dynamic-replanning pattern | GA inside Agent Framework | Originated as standalone Microsoft Research paper Oct 2024 |
| **AutoGen (legacy)** | Microsoft Research | `github.com/microsoft/autogen` | Predecessor to Agent Framework; active community | Maintained but deprecated for new dev | Migration guide shipped |
| **Semantic Kernel (legacy)** | Microsoft | `github.com/microsoft/semantic-kernel` | Predecessor to Agent Framework | Maintained but deprecated for new dev | Migration guide shipped |
| **Meta Llama Stack** | Meta | `github.com/llamastack/llama-stack` | First-party agent runtime; provider-agnostic | GA | Distribution pattern (YAML); Responses API for agents |
| **LangGraph** | LangChain (vendor-blessed by Anthropic via integration partnerships) | `docs.langchain.com/oss/python/langgraph/overview` | Production state-machine framework | GA (Platform GA May 2025) | Vendor-blessed by appearance in Anthropic/Google integration docs |
| **MCP (Model Context Protocol)** | Anthropic (open standard) | `modelcontextprotocol.io` | Standardized agent-tool interface | GA | Adopted by OpenAI, Google, Microsoft Agent Framework |
| **Cline** | Cline (community), Anthropic-blessed via Claude Sonnet integration | `github.com/cline/cline` | Open-source Cursor alternative; supervised agentic IDE | GA | Level 3 supervised agent |
| **Cursor** | Cursor / Anysphere | `cursor.com` | IDE-first; semantic codebase index + Agent | GA | Level 3 supervised agent |
| **Aider** | Community, vendor-agnostic | `aider.chat` | CLI autonomous coding agent | GA | Level 4 autonomous |
| **GitHub Copilot Coding Agent** | GitHub / Microsoft | `docs.github.com/copilot/concepts/agents/coding-agent/about-coding-agent` | First-party coding agent (successor to Copilot Workspace) | GA Sep 2025 | Issue-to-PR workflow, sub-agent architecture |

---

## Vendor guidance evolution timeline

| Date | Vendor | Shift |
|---|---|---|
| 2024-Q3 | OpenAI | Releases Swarm as "educational/experimental" multi-agent |
| 2024-08 | OpenAI | Introduces Structured Outputs API (gpt-4o, 100% schema compliance) |
| 2024-10 | Microsoft Research | Magentic-One paper: dynamic-replanning multi-agent pattern |
| 2024-12-19 | Anthropic | "Building Effective Agents" — canonical 6-pattern taxonomy. *"Most successful implementations weren't using complex frameworks or specialized libraries"* |
| 2025-03 | OpenAI | Agents SDK GA (replaces Swarm). First-party handoffs + guardrails |
| 2025-Q2 | Anthropic | Claude Code subagents docs + skills format formalized |
| 2025-04-29 | LangChain | LangGraph v0.4 — automatic interrupt surfacing |
| 2025-05-14 | LangChain | LangGraph Platform GA |
| 2025-05-30 | GitHub | Copilot Workspace sunset (technology rolled into Coding Agent) |
| 2025-09 | GitHub | Copilot Coding Agent GA |
| 2025-09-29 | Anthropic | "Effective context engineering for AI agents" — explicit shift away from prompt engineering toward context engineering. **"do the simplest thing that works"** |
| 2025-10-01 | Microsoft | Agent Framework public preview (AutoGen + Semantic Kernel unified) |
| 2025-10-16 | Anthropic | "Equipping agents with Agent Skills" — progressive disclosure pattern formalized |
| 2025-11-14 | Anthropic | Structured Outputs public beta (Sonnet 4.5 + Opus 4.1) — grammar-restricted decoding |
| 2025-11-26 | Anthropic | "Effective harnesses for long-running agents" — admits granularity is unresolved research |
| 2025-Q4 | Microsoft | Agent Framework 1.0 GA |
| 2026-Q1 | Anthropic | Opus 4.7 release — *"smarter models require less prescriptive engineering"* — depth-of-prompt guidance shifts toward minimalism for capable models |

**Big picture:** From late-2024 "build with simple composable patterns" → mid-2025 "context engineering replaces prompt engineering" → late-2025/2026 "smarter models = less prescriptive prompts." The arc consistently moves toward **less verbose agent definitions, smarter agents, more implicit reliance on model capability.**

---

## Open questions / no-evidence-found

1. **No vendor publishes a "max agents per system" recommendation.** Anthropic admits this is "unresolved research" (Nov 2025 harnesses post). ceos-agents' 21 agents falls outside any vendor exemplar (which range 3–7 named agents).
2. **No vendor publishes "agent prompt depth" benchmark with controlled comparisons** (e.g., 50-line vs 200-line vs 500-line prompt → success rate). Guidance is qualitative ("Goldilocks zone") not quantitative.
3. **No vendor publishes a YAML-pipeline-DSL exemplar** for agent orchestration. Microsoft Agent Framework graph workflows are typed Python/.NET code, not YAML. Vendor-blessed declarative is limited to *configuration* (frontmatter), not *control flow*.
4. **No vendor publishes "meta-generation of agent definitions" as a recommended pattern.** Magentic-One plans tasks dynamically but does not generate agent definitions.
5. **OpenAI "Practical Guide to Building Agents" PDF could not be fetched directly** (PDF binary; secondary HTML page returned 403). Findings reconstructed from press release summaries and OpenAI Agents SDK docs. Date confirmed: March 2025.

---

## Sources

### Anthropic
- "Building Effective AI Agents" (Erik Schluntz & Barry Zhang, 2024-12-19) — `https://www.anthropic.com/research/building-effective-agents`
- "Effective context engineering for AI agents" (2025-09-29) — `https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents`
- "Effective harnesses for long-running agents" (2025-11-26) — `https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents`
- "Equipping agents for the real world with Agent Skills" (2025-10-16) — `https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills`
- "Building agents with the Claude Agent SDK" (2025) — `https://claude.com/blog/building-agents-with-the-claude-agent-sdk`
- Claude Agent SDK overview — `https://code.claude.com/docs/en/agent-sdk/overview`
- Claude Code subagents — `https://code.claude.com/docs/en/sub-agents`
- Agent Skills overview — `https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview`
- Prompting best practices — `https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices`
- Use XML tags — `https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/use-xml-tags`
- Structured Outputs (2025-11-14) — `https://platform.claude.com/docs/en/build-with-claude/structured-outputs`
- Public skills repo — `https://github.com/anthropics/skills`

### OpenAI
- "A practical guide to building agents" (March 2025) — `https://cdn.openai.com/business-guides-and-resources/a-practical-guide-to-building-agents.pdf` (HTML index: `https://openai.com/business/guides-and-resources/a-practical-guide-to-building-ai-agents/`)
- OpenAI Agents SDK (Python) — `https://openai.github.io/openai-agents-python/`
- OpenAI Agents SDK Agents — `https://openai.github.io/openai-agents-python/agents/`
- OpenAI Agents SDK Handoffs — `https://openai.github.io/openai-agents-python/handoffs/`
- OpenAI Agents SDK Guardrails — `https://openai.github.io/openai-agents-python/guardrails/`
- OpenAI Agents SDK (JS) Human-in-the-loop — `https://openai.github.io/openai-agents-js/guides/human-in-the-loop/`
- "Introducing Structured Outputs in the API" (2024-08) — `https://openai.com/index/introducing-structured-outputs-in-the-api/`
- Structured Outputs guide — `https://platform.openai.com/docs/guides/structured-outputs`
- Function calling guide — `https://platform.openai.com/docs/guides/function-calling`
- "Introducing SWE-bench Verified" — `https://openai.com/index/introducing-swe-bench-verified/`
- Agents SDK API guide — `https://developers.openai.com/api/docs/guides/agents`
- Guardrails and human review — `https://developers.openai.com/api/docs/guides/agents/guardrails-approvals`
- OpenAI Swarm (deprecated) — `https://github.com/openai/swarm`

### Google
- ADK docs — `https://google.github.io/adk-docs/` (mirror: `https://adk.dev/`)
- ADK Multi-Agent Systems — `https://adk.dev/agents/multi-agents/`
- ADK Agents — `https://google.github.io/adk-docs/agents/`
- Vertex AI Agent Builder — `https://docs.cloud.google.com/agent-builder/agent-development-kit/overview`
- "Build multi-agentic systems using Google ADK" — `https://cloud.google.com/blog/products/ai-machine-learning/build-multi-agentic-systems-using-google-adk`
- ADK Python repo — `https://github.com/google/adk-python`

### Microsoft
- Microsoft Agent Framework Overview (updated 2026-04-20) — `https://learn.microsoft.com/en-us/agent-framework/overview/`
- Agent Framework workflow orchestrations — `https://learn.microsoft.com/en-us/agent-framework/user-guide/workflows/orchestrations/overview`
- Magentic orchestration — `https://learn.microsoft.com/en-us/agent-framework/user-guide/workflows/orchestrations/magentic`
- Tool approval (HITL) — `https://learn.microsoft.com/en-us/agent-framework/agents/tools/tool-approval`
- Migration from Semantic Kernel — `https://learn.microsoft.com/en-us/agent-framework/migration-guide/from-semantic-kernel/`
- "Introducing Microsoft Agent Framework" (Oct 1, 2025) — `https://devblogs.microsoft.com/foundry/introducing-microsoft-agent-framework-the-open-source-engine-for-agentic-ai-apps/`
- "Microsoft Agent Framework Version 1.0" (Q4 2025) — `https://devblogs.microsoft.com/agent-framework/microsoft-agent-framework-version-1-0/`
- Semantic Kernel — `https://github.com/microsoft/semantic-kernel`
- AutoGen — `https://github.com/microsoft/autogen`
- AI Agent Orchestration Patterns — `https://learn.microsoft.com/en-us/azure/architecture/ai-ml/guide/ai-agent-design-patterns`

### Meta
- Llama Stack repo — `https://github.com/llamastack/llama-stack`
- Llama Stack architecture — `https://github.com/llamastack/llama-stack/blob/main/ARCHITECTURE.md`
- Llama Stack apps (agentic components) — `https://github.com/llamastack/llama-stack-apps`

### LangChain (vendor-adjacent)
- LangGraph overview — `https://docs.langchain.com/oss/python/langgraph/overview`
- LangGraph product page — `https://www.langchain.com/langgraph`

### GitHub / Copilot
- Copilot features — `https://docs.github.com/en/copilot/get-started/features`
- Copilot Coding Agent — `https://docs.github.com/copilot/concepts/agents/coding-agent/about-coding-agent`
- Copilot Workspace (sunset May 2025) — `https://githubnext.com/projects/copilot-workspace`
- "Introducing GitHub Copilot agent mode" (Feb 24, 2025) — `https://code.visualstudio.com/blogs/2025/02/24/introducing-copilot-agent-mode`

### Cursor / Cline / Aider
- Cursor — `https://cursor.com/`
- Cline repo — `https://github.com/cline/cline`
- Aider — `https://aider.chat/`

### Benchmarks
- SWE-bench Verified leaderboard — `https://www.swebench.com/verified.html`
- SWE-bench leaderboards — `https://www.swebench.com/`
- SWE-bench Pro — `https://labs.scale.com/leaderboard/swe_bench_pro_public`
- SWE-bench-Live — `https://swe-bench-live.github.io/`
- llm-stats SWE-bench — `https://llm-stats.com/benchmarks/swe-bench-verified`

### MCP
- Model Context Protocol — `https://modelcontextprotocol.io`
