# Agent 2 — Production Engineering Lens — Report

**Run:** 2026-04-26-A-research-run1 (Phase 2)
**Lens:** What shipping AI coding products actually do under load — architectural compromises observable from product behavior, eng blogs, pricing pages, customer case studies.
**Scope:** Q1, Q2, Q3, Q4, Q5a/b/c/d, Q6, Q7, Q8, Q9, Q10, Q11, Q12. Q13–Q22 out of scope.
**Persona discipline:** Cite specific shipping products with URLs. Vendor marketing flagged separately from third-party validation. Czech context spec read; output English.

---

## Summary (5 production-grounded findings)

1. **Production has bifurcated into two paradigms with sharp empirical evidence.** Cognition's *"Don't Build Multi-Agents"* essay (June 2025) — derived from operating Devin in production for ~18 months and serving Goldman Sachs (12,000-developer pilot, 13 July 2025) — argues single-threaded agents with full context outperform parallel sub-agents on **write tasks**. Anthropic's multi-agent research system (June 2025) takes the opposite position for **read tasks**: their orchestrator + parallel sub-agents beat single-agent Opus 4 by 90.2% on internal evals — but cost 15× tokens vs chat. The split is not ideological; it tracks task type. ([Cognition](https://cognition.ai/blog/dont-build-multi-agents), [Anthropic](https://www.anthropic.com/engineering/multi-agent-research-system))

2. **AGENTS.md is now the de-facto markdown-overlay standard for per-project agent customization.** Adopted by Cursor, OpenAI Codex, Amp, Devin, Factory, Gemini CLI, GitHub Copilot, Jules, VS Code; >60,000 repos including OpenAI, Apache Airflow, Temporal; stewarded by Linux Foundation's Agentic AI Foundation since August 2025. The dominant production answer to Q5d / Q8 is **markdown overlay at repo root**, not YAML pipelines or Python hooks. ([agents.md](https://agents.md/), [OpenAI announcement](https://openai.com/index/agentic-ai-foundation/))

3. **Cursor and Devin represent the two production HITL extremes.** Cursor 2.0 (Nov 2025) ships "Multi-Agent" with 8 parallel agents in git worktrees but keeps the developer in the IDE-native synchronous-approval loop. Devin 2.0 ($20/mo from $500/mo, April 2025) is asynchronously delegated — user posts task, agent runs autonomously up to 200 minutes (Replit Agent 3 comparable), returns PR. Both ship; both have paying users; the architectural choice is HITL placement, not capability. ([Cursor 2.0](https://cursor.com/blog/2-0), [Devin 2.0 pricing cut](https://venturebeat.com/programming-development/devin-2-0-is-here-cognition-slashes-price-of-ai-software-engineer-to-20-per-month-from-500))

4. **Multi-agent dispatch is real-money expensive in production.** Anthropic measures 4× tokens for single agents vs chat, **15× tokens for multi-agent vs chat**. CrewAI has 3× managerial overhead vs LangChain on equivalent tool calls. One published deployment cost analysis: $47k/mo orchestration vs $22.7k for single GPT-5.2 agent on customer service (2.1pp accuracy delta). 68% (32/47) of analyzed production multi-agent deployments would have done equally well or better as single agents. ([Anthropic](https://www.anthropic.com/engineering/multi-agent-research-system), [Iterathon analysis](https://iterathon.tech/blog/multi-agent-orchestration-economics-single-vs-multi-2026))

5. **Generic-prompt-with-overlay beats meta-generated agents in production deployments observable today.** Claude Code's official subagents docs and Anthropic's own guidance recommend project-specific subagents over public collections ("Generic prompts won't understand your codebase patterns"). BMAD ships a fixed agent set with YAML workflows, validated on a NestJS monorepo with 743 tests. No shipping product I found uses meta-generated agents at scale; closest is research-stage MetaAgent (arXiv July 2025) and Meta's Hyperagents (research only). Production evidence for variant 3 (meta-gen) is **weak-to-absent**. ([Claude Code subagents](https://code.claude.com/docs/en/sub-agents), [BMAD](https://docs.bmad-method.org/), [MetaAgent paper](https://arxiv.org/abs/2507.22606))

---

## Q1 — Agent system prompt depth (production patterns)

### What shipping products actually do

**Claude Code (Anthropic, v2.1.120 April 2026):** The system prompt is **not one string** — it contains 110+ strings (24 builtin tool descriptions, sub-agent prompts for Plan/Explore/Task, utility prompts for CLAUDE.md/compact/statusline/magic docs/WebFetch/Bash/security review/agent creation), all in a large minified JS file. Token counts per component: Managed Agents overview ~2316 tokens, Python reference ~2841 tokens, TypeScript reference ~2855 tokens. ([Piebald-AI mirror of Claude Code prompts](https://github.com/Piebald-AI/claude-code-system-prompts))

**Cursor (2025–2026):** Cursor's official agent-best-practices guide explicitly recommends the **opposite of maximalism**: "Add rules only when you notice the agent making the same mistake repeatedly." Don't paste style guides — "use a linter instead." Reference files rather than copying content. Rules should be "focused on the essentials: the commands to run, the patterns to follow, and pointers to canonical examples." ([Cursor Agent best practices](https://cursor.com/blog/agent-best-practices))

**Anthropic engineering guidance (2026):** "Good context engineering means finding the smallest possible set of high-signal tokens that maximize the likelihood of some desired outcome." Anthropic has explicitly reframed prompt engineering as **context engineering** — "every token added to the context window competes for the model's attention, and when many tokens accumulate, the model's ability to reason about what actually matters degrades because signal gets drowned by accumulation." ([Anthropic Effective Context Engineering](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents))

**Anthropic Skills (released October 2025, open standard December 2025):** Solves the prompt-depth problem through **progressive disclosure** — three tiers:
- Tier 1: Metadata (~100 tokens / skill) loaded at session start
- Tier 2: SKILL.md (<5k tokens) loaded only when matched
- Tier 3: Bundled resources/scripts loaded only when invoked

Reported context savings: "1,500 tokens total for all 40 skills" with progressive disclosure vs ~30–50% reduction vs monolithic prompts. ([Anthropic Skills](https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills), [Lee Hanchung deep dive](https://leehanchung.github.io/blogs/2025/10/26/claude-skills-deep-dive/))

### Trade-off revealed by production behavior

| Pattern | Adopting product | Cost signal | Drift signal |
|---|---|---|---|
| Maximalist hardcoded prompt | Claude Code itself (24 tool descriptions in main loop) | Anthropic absorbs cost; user pays per token in agent pricing | Anthropic ships weekly updates; community mirrors track changes |
| Minimalist + read at runtime | Cursor `.cursor/rules` + AGENTS.md | Lower per-turn token cost | Drift is user's problem (rules out of date) |
| Progressive disclosure (3-tier) | Anthropic Skills (Oct 2025), Cognition Devin internal | Optimal — only loads what matched | Requires good metadata authoring |

**Production verdict for ceos-agents:** The maximalist 100–500 line markdown agent definitions place ceos-agents in the **Claude Code internal pattern** (which Anthropic absorbs cost for). For a plugin distributed to users who pay per token, the **progressive disclosure pattern (Skills standard)** is the demonstrably-shipping architecture as of 2026. AGENTS.md (project root, 60k+ repos) handles the per-project tail.

### What changed 2025 → 2026

- **Pre-Sonnet-4 (mid-2024):** Maximalist prompts dominant because models needed hand-holding.
- **Post-Opus-4.5 / o3 / o4 (late 2025):** SOTA shifts to minimalist + tool-use. Live-SWE-agent + Claude Opus 4.5 = 79.2% SWE-bench Verified using just bash; "models are evaluated using mini-SWE-agent in a minimal bash environment with no tools and no special scaffold." ([SWE-bench Verified](https://www.swebench.com/verified.html), [Live-SWE-agent](https://live-swe-agent.github.io/))
- **2026 trend signal:** The mini-SWE-agent result reveals that **scaffold complexity has diminishing returns** with frontier models. Best-performing public scaffolds in 2026 are increasingly thin.

---

## Q2 — Agent granularity (production patterns)

### Spectrum observed in shipping products

**Narrow specialization (ceos-agents current pattern):**
- **BMAD** ships 7–9 specialized roles: Analyst, PM, UX, Architect, SM, PO, Dev, QA, Tech Writer. ([BMAD docs](https://docs.bmad-method.org/))
- **Magentic-One (Microsoft, Nov 2024 → Microsoft Agent Framework 1.0 April 2026):** 1 Orchestrator + 4 specialists (WebSurfer, FileSurfer, Coder, ComputerTerminal). ([Magentic-One](https://www.microsoft.com/en-us/research/articles/magentic-one-a-generalist-multi-agent-system-for-solving-complex-tasks/))
- **Devin (Cognition, internal architecture):** "compound AI system" — Planner + Coder + Critic + Browser as named specialist models. ([Devin guide 2026](https://aitoolsdevpro.com/ai-tools/devin-guide/))
- **Anthropic research system:** Lead Researcher orchestrates 3–5 parallel sub-agents per query, each with own context. ([Anthropic research](https://www.anthropic.com/engineering/multi-agent-research-system))

**Generalist:**
- **Cursor Composer 1 (Nov 2025):** Single MoE model, "tool harness with more than ten tools." Most turns under 30 seconds. ([Cursor Composer](https://cursor.com/blog/composer))
- **Aider:** Single Coder coordinates LLM ↔ filesystem ↔ git. Multi-agent has been **proposed since 2025** (issues #4428, #1839) but not shipped. ([Aider issue #4428](https://github.com/aider-ai/aider/issues/4428))
- **mini-SWE-agent (used in SWE-bench Verified evals):** "single tool — bash — and a system prompt describing the task." This is the canonical minimalist generalist; Claude Opus 4.5 hits 79.2% with it. ([Live-SWE-agent](https://live-swe-agent.github.io/))

**Hybrid (architect + editor split):**
- **Aider's architect mode:** Two-model split — heavy reasoning model (e.g., DeepSeek R1, o1) acts as "architect," lighter editor model (Sonnet, 4o) translates plan to file edits. SOTA on Aider's own code-editing benchmark; DeepSeek R1 + Sonnet hit 64% at $13.29 for benchmark suite. ([Aider Architect mode blog](https://aider.chat/2024/09/26/architect.html))

### Empirical numbers

- **Coding Agent Teams (2025):** Multi-agent system with manager/researcher/engineer/reviewer roles hit SOTA on SWE-bench Verified at **72.2%** without benchmark tuning. ([dev.to writeup](https://dev.to/nikita_benkovich_eb86e54d/coding-agent-teams-outperform-solo-agents-722-on-swe-bench-verified-4of5))
- **Generalist agents:** 90% faster deployment, 50% lower cost — but "decision quality drops in high-stakes situations." ([Katonic AI](https://www.katonic.ai/blog/generalist-agents))
- **Critique–revision cycles:** "One or two critique–revision cycles suffice to realize most gains, with performance benefits saturating or even degrading at higher depths due to over-correction or echo-chamber dynamics." Three collaborators is "often … the sweet spot." ([emergentmind.com](https://www.emergentmind.com/topics/multi-agent-critique-and-revision))

### Trade-off revealed

The pattern is clear: **production products that solve open-ended tasks (Cursor, Aider, mini-SWE-agent, Composer) trend toward generalist + tool-use**; **production products that solve structured workflow tasks (BMAD for SDLC, Magentic-One for browse/file/code, Devin's compound model split) trend toward specialist roles**. ceos-agents' bug-fix and feature pipelines are **structured workflow tasks** — the specialist pattern matches production precedent.

The 21-agent count is at the high end. Magentic-One ships 5; Devin ships 4 specialist models; BMAD ships 7–9; Anthropic's research system spawns 3–5 sub-agents per query. **Production evidence does not justify 21+ agents for a SDLC pipeline**; consolidation toward 7–10 is the modal pattern.

---

## Q3 — Universal vs per-project vs hybrid agent (production patterns)

### What shipping products actually do

**Universal/generic with per-project overlay (dominant):**
- **Cursor** — single agent system, customized via `.cursor/rules/` markdown files in repo. ([Cursor Rules](https://cursor.com/docs/rules))
- **Claude Code** — single agent system, customized via `CLAUDE.md`, AGENTS.md, project-scoped Skills, project-scoped subagents in `.claude/agents/`. ([Claude Code subagents](https://code.claude.com/docs/en/sub-agents))
- **Codex CLI (OpenAI)** — universal model, customized via AGENTS.md hierarchical files (closest-wins). ([OpenAI AGENTS.md guide](https://developers.openai.com/codex/guides/agents-md))

**Per-project (rare in product form, common as community pattern):**
- **wshobson/agents (community, 184 specialized agents distributed via 78 plugins):** Closest production-flavored example to per-project agents. ([wshobson/agents](https://github.com/wshobson/agents))
- **Anthropic's official Claude Code guidance explicitly recommends this pattern:** "There are many public collections of Claude Code subagents, however, building your own subagents designed specifically for your project is recommended rather than using public ones. Generic prompts won't understand your codebase patterns and conventions." ([Claude Code subagents docs](https://code.claude.com/docs/en/sub-agents))

**Hybrid inheritance (Codex):**
- **Codex subagents inherit configuration from parent sessions** — `nickname_candidates`, `model`, `model_reasoning_effort`, `sandbox_mode`, `mcp_servers`, `skills.config` all inherit by default but can be overridden. ([OpenAI Codex Subagents](https://developers.openai.com/codex/subagents))
- This is the **closest production-shipping example of hybrid inheritance**: base agent definition with project-specific delta overrides.

**Meta-generated (research only, no production deployment found):**
- MetaAgent (arXiv July 2025) automatically constructs multi-agent systems via finite state machines. ([MetaAgent](https://arxiv.org/abs/2507.22606))
- Meta's Hyperagents — research framework for self-modifying agents. ([Hyperagents](https://venturebeat.com/orchestration/meta-researchers-introduce-hyperagents-to-unlock-self-improving-ai-for-non-coding-tasks))
- **No shipping product I found uses meta-generated agents as the primary architecture.** Replit Agent 3 has a "generate other agents" capability but as a feature, not the core architecture. ([Replit Agent 3](https://blog.replit.com/introducing-agent-3-our-most-autonomous-agent-yet))

### Trade-off revealed

The production pattern is **universal/generic agent + per-project markdown overlay**, with the closest product-shipping inheritance model in **OpenAI Codex's subagent inheritance** (hybrid, opt-in overrides). Generic+overlay is the safest bet for a public-release plugin because:

1. Update flow is clean: plugin updates the generic agent; user owns the overlay.
2. Onboarding is fast: scaffolder generates a starter overlay; user extends.
3. Maintenance burden falls on plugin author for core, user for overlay — clear contract.

**For ceos-agents v8.0.0, the production-validated path is generic+overlay (current architecture is correct), with possible enrichment toward Codex-style typed inheritance for the overlay.** Per-project full sets are too maintenance-heavy for distribution; meta-gen is research-stage.

---

## Q4 — Stateful vs stateless agents (production patterns)

### Production evidence

**Anthropic's explicit position (2026):** Subagents in their multi-agent research system have **independent context windows** (stateless to each other; stateful within a single sub-agent's lifetime). The Lead Agent compresses results into "lightweight references" passed back. ([Anthropic research](https://www.anthropic.com/engineering/multi-agent-research-system))

**Cognition's explicit position:** "Share context, and share full agent traces, not just individual messages." Their counter-recommendation to multi-agent: **single-threaded continuous context throughout task lifecycle**. When context overflows, use **hierarchical compression (LLM that summarizes to key decisions/events)**. ([Cognition Don't Build Multi-Agents](https://cognition.ai/blog/dont-build-multi-agents))

**Cursor production behavior:**
- "Long conversations can cause the agent to lose focus." Recommendation: start fresh.
- Cursor's own community has built **"Memory Banks"** as a stateful workaround — structured project context maintained across chat sessions.
- ([Cursor agent best practices](https://cursor.com/blog/agent-best-practices))

**Cline production behavior:**
- Implements `new_task` tool — "form of persistent memory for complex, long-running tasks."
- ([Cline GitHub](https://github.com/cline/cline))

**Claude Code production behavior:**
- **Compaction is automatic** when context budget approaches limit. "Five-layer compaction pipeline."
- Real-world report: "compaction kicks in frequently and consumes what feels like roughly half of the available tokens." ([Claude Compaction docs](https://platform.claude.com/docs/en/build-with-claude/compaction), [issue #28984](https://github.com/anthropics/claude-code/issues/28984))

**Token cost growth in stateful loops (measured):**
- Multi-step research without compaction: 888 tokens iter 1 → **18,900 tokens by iter 5**. ([MindStudio token budget post](https://www.mindstudio.ai/blog/ai-agent-token-budget-management-claude-code))

### Trade-off revealed

Production shipping products converge on **"stateless dispatch + explicit summary handoff"** for orchestrator-to-subagent flow, and **"stateful within agent + auto-compaction"** for inside-agent iteration. The pure stateless model that ceos-agents currently uses (each dispatch starts clean, context passed explicitly) **matches the orchestrator-to-subagent layer of every shipping product I examined** — Anthropic, Cognition, Magentic-One.

What ceos-agents may want to add in v8.0.0: a **bounded stateful layer for the fixer↔reviewer loop** specifically, since that loop is precisely the iteration pattern Cline's `new_task` and Aider's architect/editor exemplify. But the cross-agent layer should stay stateless — that's the production consensus.

---

## Q5a — Pipeline shape diversity in ecosystem (production view)

Below is the production-deployed framework matrix. Score = "shape characteristic" presence: ✓ = native, △ = via plugin/community, ✗ = absent. URLs in Sources.

| Framework | Pipeline definition | HITL placement | Agent set | Production paradigm |
|---|---|---|---|---|
| **Cursor 2.0** | Hardcoded orchestrator + 8 parallel agents in worktrees | IDE-native synchronous accept | Single Composer model + tools | Generalist + tool harness |
| **Devin 2.0** | Hardcoded planning loop, async execution up to 200 min | Async — review PR at end | Compound: Planner+Coder+Critic+Browser | Specialist compound model |
| **Claude Code** | Conversational + agent loop (5-mode permissions, 5-layer compaction) | 7 permission modes | Generalist main + plugin subagents | Generalist + plugin extensibility |
| **Replit Agent 3** | Hardcoded autonomous loop with browser-test reflection | Async; runs 200 min | Specialist agents (web, code, deploy) | Sandboxed compound system |
| **OpenHands V1 SDK** | Stateless event-sourced; composable | Configurable | Plugin agents | Library-style framework |
| **BMAD** | YAML workflows with declarative steps | Stage-gate per role | 7–9 fixed specialist roles | Declarative SDLC roles |
| **Magentic-One / MS Agent Framework** | Outer loop (task ledger) + inner loop (progress ledger) | Configurable | 1 Orchestrator + 4 specialists | Two-tier orchestrator+workers |
| **Anthropic research system** | Orchestrator-worker; lead agent spawns 3–5 sub-agents | None during run; review final report | 1 Lead + N parallel sub-agents | Parallel research orchestration |
| **CrewAI** | YAML role definitions; sequential or hierarchical crews | Configurable per task | Generic crew with role prompts | Declarative role-based |
| **LangGraph** | Code-defined directed graph (declarative graph + imperative nodes) | Per-node interruption | User-defined; checkpoint-based | Graph-state machine |
| **AutoGen** | Async actor messaging | Configurable | User-defined async actors | Conversation-based actors |
| **Aider** | Single Coder loop; architect/editor optional split | Per-edit confirmation | Single (or 2 in architect mode) | Pair-programming loop |
| **Sweep AI** | Hardcoded GitHub-issue → PR pipeline | Tag issue 'sweep'; review PR | Single agent with tools | GitHub-event-driven |
| **Aider community proposal** | Multi-agent (proposed, not shipped) | n/a | 3–5 specialist roles | n/a |
| **Roo Code** | Mode-based (Code/Architect/Ask/Debug/Custom) | Per-action confirmation | Multiple modes, single model | Mode-switched generalist |

### Distribution

- **Generalist + tool harness:** Cursor, Claude Code, Aider, mini-SWE-agent, Sweep, Roo Code. **Modal production pattern for general coding assistance.**
- **Specialist roles (compound):** Devin, Magentic-One, BMAD, Anthropic research, ceos-agents. **Modal pattern for structured SDLC work.**
- **Pure generalist single agent:** mini-SWE-agent + frontier model wins on SWE-bench Verified at 79.2% — diminishing returns of scaffold complexity at frontier model scale.
- **Meta-gen / self-generating:** No shipping production product. Research only.

### Stage orderings observed

Long tail: ~6 distinct orderings across these frameworks. Dominant orderings:
1. **Plan → execute → review** (Devin, Cursor, Aider architect mode) — 6 frameworks
2. **Triage → fix → test → publish** (ceos-agents, Sweep, BMAD-Dev workflow) — 4 frameworks
3. **Spec → arch → impl → test → publish** (BMAD full SDLC, ceos-agents implement-feature) — 2 frameworks
4. **Orchestrate parallel → merge** (Anthropic research, Cursor 2.0 multi-agent) — 2 frameworks

**Key finding:** ceos-agents' "triage → analyst → fixer ↔ reviewer → test → publish" ordering is in the second-most-common bucket but is unusually deep (8+ stages) compared to production peers. Devin's compound is 4-component; BMAD's dev workflow is 4-step.

---

## Q5b — Migration ROI evidence (production case studies)

### Direct evidence: agent framework migrations

**LangGraph 1.0 (late 2025) — became default runtime for all LangChain agents.** This is the largest production-observable migration in the agent space: every LangChain user effectively migrated from prompt-chaining to graph-based state-machine execution. No public migration cost numbers, but adoption is massive (LangChain has tens of thousands of production users). ([LangChain blog](https://www.langchain.com/blog/how-to-think-about-agent-frameworks))

**Microsoft Agent Framework 1.0 (April 2026) — successor to AutoGen + Semantic Kernel.** Microsoft converged two competing products into one. Direct quote: "The enterprise‑ready successor to AutoGen … production-ready release: stable APIs, and a commitment to long-term support." ([MS Agent Framework](https://cloudsummit.eu/blog/microsoft-agent-framework-production-ready-convergence-autogen-semantic-kernel))

**Cursor 1.x → 2.0 (Nov 2025) — migrated from single-agent IDE assist to multi-agent worktree orchestration.** Internal architecture rewrite; "Composer" model trained via RL specifically for the new harness. No published migration cost; result is "4× faster" claim. ([Cursor 2.0](https://cursor.com/blog/2-0))

**Devin 1.x → 2.0 (April 2025) — pricing dropped from $500 to $20/mo.** Major architectural shift signaled by 25× pricing reduction. Cognition characterized this as making agents "accessible." ([Devin 2.0 announcement](https://venturebeat.com/programming-development/devin-2-0-is-here-cognition-slashes-price-of-ai-software-engineer-to-20-per-month-from-500))

**Sourcegraph Cody → Amp (July 2025) — discontinued Cody Free/Pro, pivoted to Amp.** This is a *deletion* migration: Sourcegraph killed its mature product and bet the company on the new agentic architecture. Production users were forced to migrate or move off. ([Sourcegraph blog](https://sourcegraph.com/blog/cody-the-ai-powered-tool-helping-support-engineers-unblock-themselves))

### Adjacent evidence: CI pipeline migrations

The Jenkins → GitHub Actions / Tekton migration story is well-documented and provides analog. Common reported patterns: declarative YAML wins for standard cases, but teams hit the "Turing tarpit" when YAML is forced to express complex logic (Jenkinsfile groovy escape hatch; GitHub Actions composite actions; Argo Workflows DAG complexity). No specific quantified ROI case study found in 2025 sources.

### Lessons learned from production migrations (Cognition's specific lessons)

- **Multi-agent → single-agent (write-task) refactor:** Cognition refactored their Edit Apply Models away from "separate large-model (explanation) + small-model (execution) systems to single-model approaches for reliability." ([Cognition essay](https://cognition.ai/blog/dont-build-multi-agents))
- **Reason for refactor:** "Miscommunication compounds; subagents misinterpret tasks without full context, leading to incompatible outputs that are difficult to reconcile."

### Verdict for ceos-agents

Production-observable migration ROI is hardest to quantify in this space — vendors don't publish before/after deployment cost numbers. The strongest **negative evidence** is Cognition explicitly migrating *away* from compound architecture for write-tasks. The strongest **positive evidence** is LangGraph's near-universal adoption of graph-state-machine model, suggesting declarative graph orchestration with imperative node logic is a genuinely productive abstraction at scale.

**no quantified ROI numbers found** for hardcoded markdown → declarative pipeline migrations specifically.

---

## Q5c — LLM-as-config-interpreter reliability (production evidence)

### Production data points

**LangGraph's explicit production positioning:** "Models agent workflows as directed graphs of nodes of agents, tools, and memory, providing fine-grained control." LangGraph chose **deterministic state machines over LLM dispatch** for production reliability. ([LangGraph](https://www.langchain.com/blog/how-to-think-about-agent-frameworks))

**Anthropic's recommendation (2026):** "Building with language models is becoming less about finding the right words and phrases for your prompts, and more about optimizing the broader configuration of context." Critically: "Negative examples are extremely important — they define the boundaries of the feature and ensure it doesn't over-trigger." This indicates **LLMs over-trigger when given vague config instructions**. ([Anthropic context engineering](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents))

**Cognition's direct production observation:** "Subagents misinterpret tasks without full context." They observed this empirically running Devin in production for 18 months at scale. The fundamental claim: **LLM dispatch reliability degrades sharply when the dispatched agent doesn't have full upstream context** — which is precisely the failure mode of LLM-as-config-interpreter. ([Cognition essay](https://cognition.ai/blog/dont-build-multi-agents))

**MicroSoft's two-loop fix in Magentic-One:** The Orchestrator runs **two loops**: outer loop (task ledger: facts, guesses, plan) and inner loop (progress ledger: current progress, task assignment). This double-bookkeeping pattern exists *specifically because LLM dispatch alone is unreliable*. ([Magentic-One](https://www.microsoft.com/en-us/research/articles/magentic-one-a-generalist-multi-agent-system-for-solving-complex-tasks/))

**arXiv 2509.18970 (Sept 2025) "LLM-based Agents Suffer from Hallucinations: A Survey":** Explicitly identifies **18 triggering causes** for agent hallucinations, with task dispatch being one major category. ([arXiv 2509.18970](https://arxiv.org/abs/2509.18970))

**DeepEval 2025 changelog:** Added "structured prompt metadata and improved Prompt.load() parsing, including safer fallbacks when JSON is invalid or malformed." This is the production tooling response to LLM-generated config being unreliable. ([DeepEval changelog](https://deepeval.com/changelog/changelog-2025))

### Quantitative dispatch reliability (production observation)

**CrewAI vs LangChain dispatch overhead:** CrewAI exhibits "managerial overhead, consuming nearly 3× the tokens of LangChain and taking almost 3× longer even when asked to make a single tool call." This is a **direct production-comparable measurement** of LLM-as-orchestrator overhead. ([Iterathon](https://iterathon.tech/blog/multi-agent-orchestration-economics-single-vs-multi-2026))

### Verdict

Production evidence consistently shows: **LLMs are unreliable as deterministic dispatchers when given declarative config without sufficient guardrails**. Production frameworks have responded with:
1. **Deterministic state machines** with LLM nodes (LangGraph, Temporal+LLM)
2. **Two-loop bookkeeping** (Magentic-One: separate task ledger and progress ledger)
3. **Hierarchical compression** (Cognition: LLM-as-summarizer is OK; LLM-as-orchestrator with no shared trace is not)
4. **Structured output gates** (Anthropic's structured outputs, OpenAI tool calling JSON schema enforcement)

**For ceos-agents Q5 decision:** A pure declarative YAML pipeline that depends on the LLM to interpret stage transitions reliably is the **least-supported** option in production evidence. A markdown prose pipeline (current) where the LLM is the executor of well-specified prose steps is closer to **mini-SWE-agent's pattern**, which is production-validated. A declarative graph (LangGraph-style) where the LLM is bounded to specific nodes and transitions are deterministic is the most-validated production pattern. **Pure markdown ≈ pure-LLM-orchestrator** — same failure mode as YAML, just less structured.

---

## Q5d — Public release expectations (production evidence)

### What top-shipping products use for customization

| Product | User-facing customization | Format |
|---|---|---|
| **Cursor** | `.cursor/rules/*.md` + AGENTS.md | Markdown |
| **Claude Code** | CLAUDE.md, AGENTS.md, `.claude/agents/*.md` (subagents), `.claude/skills/SKILL.md` | Markdown + YAML frontmatter |
| **OpenAI Codex CLI** | AGENTS.md (hierarchical, closest-wins) + Codex Subagents (inherit-with-override) | Markdown |
| **GitHub Copilot** | AGENTS.md, `.github/copilot-instructions.md` | Markdown |
| **Aider** | `.aider.conf.yml` + CONVENTIONS.md | YAML config + Markdown context |
| **Devin** | Knowledge base (web UI) + AGENTS.md | Markdown |
| **BMAD** | YAML workflows + agent markdown | Hybrid (YAML pipeline + Markdown agents) |
| **CrewAI** | YAML role definitions | YAML |
| **LangGraph** | Python code (declarative + imperative hybrid) | Python |
| **Mastra** | TypeScript code | TypeScript |

### The dominant answer

**AGENTS.md is the production-validated standard for plugin-distributed agent customization** as of 2026:
- 60,000+ repositories adopt
- Adopted by every major product agent (Cursor, Codex, Amp, Devin, Factory, Gemini CLI, Copilot, Jules, VS Code)
- Linux Foundation steward
- "Plain markdown without metadata or complex configurations"
- Hierarchical lookup: closest-to-edited-file wins; explicit chat prompts override everything

([agents.md](https://agents.md/), [OpenAI announcement of Agentic AI Foundation](https://openai.com/index/agentic-ai-foundation/), [Builder.io tips](https://www.builder.io/blog/agents-md))

### Community signals

- **awesome-claude-code, awesome-claude-plugins, claude-code-plugins-plus-skills (jeremylongshore):** "423 plugins, 2,849 skills, 177 agents." The community ecosystem is overwhelmingly markdown-format. ([jeremylongshore](https://github.com/jeremylongshore/claude-code-plugins-plus-skills))
- **VoltAgent/awesome-claude-code-subagents:** "100+ specialized Claude Code subagents." All markdown. ([VoltAgent](https://github.com/VoltAgent/awesome-claude-code-subagents))
- **Composio HQ awesome-claude-plugins, hesreallyhim/awesome-claude-code:** Both index 4,200+ skills, 2,500+ marketplace repositories. Markdown is the lingua franca.

### Critical observation

**There is no production-shipping coding-agent product where users customize behavior primarily through YAML pipeline definitions.** YAML appears in:
- CrewAI (agent role definitions, but pipelines are still Python crew composition)
- BMAD workflows (per-task YAML, but the overall framework is markdown-driven)
- Aider config (settings, not pipeline)

The strongest YAML-pipeline production system in the agent space is BMAD's own workflow engine — and even it puts the agent definitions in markdown.

### Verdict for ceos-agents v8.0.0

The production-validated public-release pattern is:
1. **Plugin agents in markdown** (current: ✓)
2. **Per-project overlay in markdown** (current: Agent Overrides ✓)
3. **AGENTS.md compatibility** (NEW: ceos-agents should read project AGENTS.md if present, since users will already have one)
4. **Pipeline definition in markdown prose** (current ceos-agents pattern matches mini-SWE-agent / Claude Code internal patterns) — declarative YAML pipelines are NOT the production-dominant pattern despite vendor marketing for CrewAI/BMAD; the **read-AGENTS.md-and-execute-prose** pattern is what users now expect

---

## Q6 — Human-in-the-loop placement (production patterns)

### Spectrum observed in shipping products

**Zero gates / autonomous (high autonomy):**
- **Devin 2.0** — async delegation, runs up to ~200 min, returns PR for review. Goldman Sachs deploys Devin at 12,000-developer pilot under "continuous human supervision" — but the supervision is at the *PR-review stage*, not in-loop. Devin's autonomous resolution rate: 13.86% end-to-end on SWE-bench. ([CNBC Goldman Sachs](https://www.cnbc.com/2025/07/11/goldman-sachs-autonomous-coder-pilot-marks-major-ai-milestone.html), [Devin SWE-bench](https://cognition.ai/blog/introducing-devin))
- **Replit Agent 3** — runs 200 minutes autonomously with browser-based self-testing reflection loop. ([Replit Agent 3](https://blog.replit.com/introducing-agent-3-our-most-autonomous-agent-yet))
- **Sweep** — fully autonomous: tag GitHub issue, get PR. ([Sweep AI](https://aiagentstore.ai/ai-agent/sweep-ai))

**Strategic gates (every key transition):**
- **GitHub Copilot Workspace** — explicit gate after spec, after plan, after implementation: "Whether generating a plan, implementing code, or automatically finding and fixing errors, Copilot Workspace leverages a system of sub-agents to iterate with developers at every step." ([GitHub Copilot Workspace](https://githubnext.com/projects/copilot-workspace))
- **BMAD method** — workflow gates between Analyst → PM → Architect → Dev. ([BMAD docs](https://docs.bmad-method.org/))
- **ceos-agents current** — gates at triage, AC checkpoint, acceptance-gate, pre-publish (5 gates).

**Per-stage / per-action (high oversight):**
- **Cursor** — synchronous accept/reject per edit by default; "keeps humans in the loop by design"; "developers stay in the driver's seat and approve actions as they go." ([Cursor agent best practices](https://cursor.com/blog/agent-best-practices))
- **Aider** — per-edit confirmation; user reviews each diff. ([Aider docs](https://aider.chat/docs/))
- **Claude Code** — 7 permission modes, ML-based classifier deciding what needs approval. ([Claude Code docs](https://code.claude.com/docs/en/overview))
- **Roo Code** — "Control each action and make Roo as autonomous as you want as you build confidence." ([Roo Code](https://roocode.com/))

**Confidence-based / event-driven (emerging):**
- **WorkOS HITL patterns analysis (2025):** "5 core HITL patterns that cover 90%+ of real-world use cases: Approval Gate, Escalation Ladder, Confidence-Based Routing, Collaborative Drafting, and Audit Trail with Lazy Review." ([WorkOS](https://workos.com/blog/why-ai-still-needs-you-exploring-human-in-the-loop-systems))
- **Claude Code's permission modes** are essentially confidence-routed: low-risk read-only operations auto-approved; high-risk write/delete gated.

### Production-observed costs of mis-placed gates

**Devin's 13.86% end-to-end** vs **Goldman's reported 3-4× productivity** suggests that for most autonomous tasks, end-of-task review is sufficient *if* the agent has high confidence on what it's doing. But Devin's defect rate is "1.5–2× higher than senior-developer-authored code," and PRs average "1.5–2.3 review cycles" — meaning autonomous mode frontloads time saved into backloaded review. ([SitePoint Devin aftermath](https://www.sitepoint.com/devin-ai-engineers-production-realities/))

**Goldman Sachs reports 25-45 min saved per task and 10-20 min review overhead** — net 15-30 min/task gain for *suitable* work. For *unsuitable* work (architectural judgment), autonomous mode is a loss.

### Trade-off revealed

The production data points to **task-type-conditional HITL placement**:
- **Routine bug fix / mechanical refactor:** Async delegation (Devin pattern) wins
- **Spec-driven feature work:** Strategic gates (Copilot Workspace, BMAD pattern) wins
- **Architectural decision / novel design:** Per-stage HITL (Cursor pattern) wins

ceos-agents currently mixes patterns: bug-fix pipeline has 5 gates (strategic); `--yolo` removes them (zero-gate); acceptance-gate is conditional (event-driven on AC count ≥ 3 or complexity ≥ M). **This is consistent with production patterns; the conditional acceptance-gate is precisely the "Confidence-Based Routing" pattern from WorkOS analysis.**

The biggest production gap: ceos-agents has no **confidence-based gate inside the fixer↔reviewer loop**. Aider, Cursor, Claude Code all have this. v8.0.0 should consider adding.

---

## Q7 — Sub-agent dispatch vs in-agent tool-use (production patterns)

### Production evidence — dispatch overhead is substantial

- **Anthropic measures multi-agent at 15× chat tokens; agents at 4× chat.** Net: dispatch + sub-agent overhead is ~3-4× the in-agent equivalent. Justification: 90.2% performance lift on research tasks. ([Anthropic research](https://www.anthropic.com/engineering/multi-agent-research-system))
- **CrewAI 3× managerial overhead** vs LangChain for equivalent tool calls. ([Iterathon](https://iterathon.tech/blog/multi-agent-orchestration-economics-single-vs-multi-2026))
- **One reported production deployment:** $47k/mo multi-agent vs $22.7k single agent for 2.1pp accuracy delta. **68% of analyzed deployments would have done equally well as single agents.** ([Iterathon](https://iterathon.tech/blog/multi-agent-orchestration-economics-single-vs-multi-2026))

### When dispatch wins (production-observed)

1. **Read tasks (research, analysis, gathering):** Anthropic's research system. Parallelization wins.
2. **Independent domain split (frontend/backend/db):** Documented Claude Code pattern. ([codewithseb](https://www.codewithseb.com/blog/claude-code-sub-agents-multi-agent-systems-guide))
3. **Cost-routing (Opus orchestrator + Sonnet workers):** "A common pattern: run your main session on Opus for complex reasoning while sub-agents handle focused tasks on Sonnet."

### When in-agent tool-use wins (production-observed)

1. **Write tasks (code editing, file creation):** Cognition's explicit position. Single agent owns trace.
2. **Tight iteration (test → fix → test):** Aider, Cursor — single Coder loops.
3. **Frontier model + minimal scaffold:** mini-SWE-agent + Opus 4.5 = 79.2% with **bash only**.

### Verdict for ceos-agents

ceos-agents currently dispatches subagents heavily (21 agent definitions, dispatched as Task subagents). Production evidence suggests **the orchestrator-to-fixer dispatch is justified** (separation of read-only analysis from write execution), but **fixer-to-reproducer-to-browser-verifier-to-test-engineer chain is over-decomposed**. Production parallels:

- **Anthropic research:** Lead + 3-5 parallel sub-agents — not Lead + 5 sequential sub-agents.
- **Devin compound:** Planner + Coder + Critic + Browser — 4 components.
- **BMAD:** 7-9 roles but most workflows touch 3-4.

ceos-agents' 21 agents per pipeline run is at the **outer edge of production precedent**. v8.0.0 consolidation toward fewer agents (8-12) per pipeline matches the production median.

---

## Q8 — Generic+overlay vs per-project vs meta-gen (production verdict)

### Production deployment evidence by variant

| Variant | Production-deployed example | Maturity signal |
|---|---|---|
| **Generic+overlay** | Cursor (.cursor/rules + AGENTS.md), Claude Code (CLAUDE.md + .claude/agents), Codex (AGENTS.md inheritance) | All three are top-3 production coding agents. Standard adopted by 60k+ repos. |
| **Per-project (full set)** | wshobson/agents (community), bespoke enterprise deployments | Community pattern; not productized at scale |
| **Meta-gen** | Replit Agent 3 (feature, not architecture), MetaAgent (research), Hyperagents (research) | **No production deployment of meta-gen as primary architecture found** |

### Update flow analysis (from production behavior)

**Generic+overlay update flow (Cursor, Claude Code observable):**
- Plugin updates push immediately; user overlay stays put.
- Conflict surface: minimal; overlay is in user's repo, plugin in plugin dir.
- Users who customize core agents have to rebase manually (rare).

**Per-project update flow (community plugins observable):**
- Each project shipped independently; updates require user pull.
- Higher fragmentation; community fork-and-modify is the norm.
- ceos-agents adopting per-project would mean **shipping 8 config-template variants × N agent variants** — combinatorial explosion.

**Meta-gen update flow (theoretical, no production):**
- Plugin update changes meta-agent prompt; regeneration produces new agent set.
- Risk: regeneration drifts from user's customizations (which were also generated, hard to track).
- **No production user has solved this regeneration-vs-customization conflict at scale.**

### Onboarding cost (production-observed)

- **Cursor onboarding:** ~5 min — install, open project, AGENTS.md auto-detected. Empty AGENTS.md still works (uses defaults).
- **Claude Code onboarding:** ~5 min — install, project auto-scans CLAUDE.md.
- **BMAD onboarding:** Documented as "time-intensive," requires user to study the workflow YAML structure. ([Reenbit](https://reenbit.com/the-bmad-method-how-structured-ai-agents-turn-vibe-coding-into-production-ready-software/))
- **CrewAI onboarding:** "Fastest setup" — but for production, "teams that start with CrewAI for prototyping often migrate to LangGraph when they need production-grade state management." ([gurusup](https://gurusup.com/blog/best-multi-agent-frameworks-2026))

### Verdict

**Generic+overlay is the production-validated public-release pattern.** Specifically:
1. Top-3 coding agents (Cursor, Claude Code, Codex) all use it.
2. Per-project full sets exist only as bespoke or community patterns; no productized example.
3. Meta-gen has **zero production deployment** as primary architecture; only as a feature within otherwise generic agents (Replit's "agent-generates-agent" is feature, not architecture).

ceos-agents' current generic+overlay is the production-validated choice. Migration to per-project would be against production precedent. Migration to meta-gen would be ahead of production validation (research-stage).

**Recommendation backed by production evidence:** Keep generic+overlay. Add Codex-style typed inheritance for the overlay (since it's the closest-shipping inheritance model). Skip meta-gen until research matures into production deployments.

---

## Q9 — Pipeline-as-config DSL expressiveness (production patterns)

### What production frameworks chose

| Framework | DSL choice | Expressiveness ceiling | Turing tarpit signal |
|---|---|---|---|
| **CrewAI** | YAML role definitions | Sequential / hierarchical only | Constrained — "performs optimally with predictable, hierarchical processes rather than adaptive or real-time operations" |
| **BMAD** | YAML workflows | Branches, dependencies, handoff points | Documented complexity ("time-intensive onboarding") |
| **LangGraph** | Code (Python TS) — declarative graph + imperative nodes | Full Python expressiveness | None — the imperative escape hatch IS the design |
| **Temporal (general)** | Code-first workflows; durable | Turing-complete (host language) | Used for "rigid, mission-critical business logic" — full power required |
| **Microsoft Agent Framework** | Hybrid: declarative YAML agents + graph orchestration + middleware pipelines | Configurable (declarative for agent definition, code for orchestration) | None at present |
| **Mastra** | TypeScript code (.then(), .branch(), .parallel()) | Full TS expressiveness | None |
| **GitHub Actions** | YAML | Increasingly complex with composite actions | **Documented Turing tarpit** — well-known criticism |
| **Argo Workflows** | YAML DAG | Steps, DAG, recursion | **Documented Turing tarpit** — recursive YAML composition is hard to debug |

### LangChain's published recommendation

> "LangGraph blends both paradigms: Declarative aspect — Graph structure (nodes and edges) uses declarative syntax. Imperative aspect — Node and edge logic remains standard Python/TypeScript code. This hybrid avoids forcing developers into purely declarative constraints."

> "When building applications with LLMs, we recommend finding the simplest solution possible, and only increasing complexity when needed."

([LangChain blog](https://www.langchain.com/blog/how-to-think-about-agent-frameworks))

### Production lessons learned

- **GitHub Actions' YAML reusable workflows + composite actions** were added precisely *because* simple YAML hit expressiveness ceilings.
- **CrewAI's flow control limitations** (branching, parallel) led many production teams to migrate to LangGraph.
- **Argo Workflows recursive YAML** is an oft-cited example of "DSL became unmaintainable."
- **Jenkins Jobs DSL → Jenkinsfile (Groovy)** — escape from pure-declarative to pure-code is the frequent escape valve.

### Verdict

The production-converged answer is **declarative for structure + imperative for logic** (LangGraph, MS Agent Framework, Mastra). Pure-YAML pipelines (CrewAI, BMAD pure, GitHub Actions pure) consistently hit ceiling at conditional logic and branching.

**For ceos-agents:** if v8.0.0 introduces a pipeline DSL, the production-validated shape is:
1. **Declarative stage list** (YAML or markdown)
2. **Imperative escape hatch** (project-defined hooks in bash/JS — current Hooks section is exactly this)
3. **No Turing-complete DSL** (production evidence shows this fails)

The current ceos-agents pattern (markdown stage prose + Hooks for imperative) is closer to production best practice than a pure-YAML pipeline would be.

---

## Q10 — Benchmarking metrics (production vs research)

### Production-reported metrics (what shipping products report)

| Product | Reported metric | Number | Source |
|---|---|---|---|
| Devin | SWE-bench end-to-end | 13.86% | [Cognition](https://cognition.ai/blog/introducing-devin) |
| Goldman Sachs Devin pilot | Productivity gain | 3-4× vs prior tools, 20% efficiency vision | [CNBC](https://www.cnbc.com/2025/07/11/goldman-sachs-autonomous-coder-pilot-marks-major-ai-milestone.html) |
| Goldman Sachs Devin pilot | Time saved per task | 25-45 min, minus 10-20 min overhead → 15-30 min net | [SitePoint](https://www.sitepoint.com/devin-ai-engineers-production-realities/) |
| Devin (anecdotal production) | Defect rate vs senior dev | 1.5-2× higher | [SitePoint](https://www.sitepoint.com/devin-ai-engineers-production-realities/) |
| Devin (anecdotal production) | PR review cycles | 1.5-2.3 | [SitePoint](https://www.sitepoint.com/devin-ai-engineers-production-realities/) |
| Cursor Composer | Median turn time | <30 sec | [Cursor](https://cursor.com/blog/composer) |
| Cursor 2.0 | Speed improvement | 4× faster than similar models | [Cursor 2.0](https://cursor.com/blog/2-0) |
| Replit Agent 3 | Autonomous runtime | up to 200 min | [Replit](https://blog.replit.com/introducing-agent-3-our-most-autonomous-agent-yet) |
| Replit Agent 3 | Test efficiency | 3× faster, 10× more cost-effective than Computer Use | [Replit](https://blog.replit.com/introducing-agent-3-our-most-autonomous-agent-yet) |
| Anthropic research multi-agent | vs single-agent | +90.2% on internal evals | [Anthropic](https://www.anthropic.com/engineering/multi-agent-research-system) |
| Anthropic research multi-agent | Token cost | 4× chat (single agent), 15× chat (multi-agent) | [Anthropic](https://www.anthropic.com/engineering/multi-agent-research-system) |
| Anthropic research multi-agent | Variance explained by token spend alone | 80% | [Anthropic](https://www.anthropic.com/engineering/multi-agent-research-system) |
| OpenHands V1 SDK | System-attributable failure reduction | "Substantially reduces" vs V0 | [arXiv 2511.03690](https://arxiv.org/abs/2511.03690) |

### SWE-bench Verified leaderboard signal

- Live-SWE-agent + Claude Opus 4.5: **79.2%** (SOTA open-scaffold, April 2026)
- mini-SWE-agent (bash only) + frontier model performs near top
- SWE-Bench Pro (more realistic): top models ~23% (vs SWE-bench Verified ~70%+) — **production reality is significantly harder than the verified subset suggests**

([SWE-bench](https://www.swebench.com/), [Live-SWE-agent](https://live-swe-agent.github.io/), [SWE-Bench Pro](https://labs.scale.com/leaderboard/swe_bench_pro_public))

### What ceos-agents could measure (markdown plugin, no runtime)

ceos-agents already collects this in its state.json schema (per v6.8.0):
- `tokens_used`, `duration_ms`, `tool_uses`, `model`, `started_at`, `completed_at` per stage
- `pipeline.*` accumulators
- `summary_table` (≤20 rows / 4000 chars)
- Block reasons (sanitized)

Production-validated additions worth considering:
1. **Iteration count per fixer↔reviewer loop** (Anthropic measures this; Aider measures this)
2. **Compaction events** (Claude Code, Cline both measure)
3. **Confidence/clarification rate** (already partly tracked via NEEDS_CLARIFICATION counters)
4. **Defect/regression rate post-merge** (Verify command failure rate)

The plugin's `pipeline-history.md` (50-run retention, last 5/last 10 read by fixer/reviewer) is **production-aligned** — Cognition explicitly recommends "share full agent traces" and ceos-agents does this.

---

## Q11 — Trade-off matrix (evidence-based, production-grounded)

For the three architectural variants. Cells are evidence-grounded ordinal scores: **HIGH / MEDIUM / LOW** with citation. "n/e" = no evidence found.

| Dimension | Generic+overlay (current) | Per-project | Meta-gen |
|---|---|---|---|
| **Onboarding cost** | LOW — Cursor / Claude Code take ~5 min ([Cursor](https://cursor.com/blog/agent-best-practices)) | MEDIUM — community plugins require user to fork/modify | HIGH — requires user to provide good description; no production reference for cost |
| **Token cost** | MEDIUM — generic prompts may be larger; mitigated by Skills progressive disclosure (Anthropic 30-50% saving) ([Anthropic Skills](https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills)) | LOW — tightly scoped per-project prompts | HIGH — generation phase costs tokens; regenerated agents may be larger |
| **Maintenance burden (plugin author)** | LOW — one canonical agent set; users own overlay | HIGH — N project variants × M agent updates | n/e — no production data on maintaining a meta-agent that generates other agents |
| **Maintenance burden (user)** | LOW — overlay is small and stable | HIGH — owns full agent set; bears all updates | MEDIUM — owns description; regen on updates may break customizations |
| **Customization power** | MEDIUM — limited to overlay surface | HIGH — full freedom | HIGH — can describe anything, but unpredictable output |
| **Error surface** | LOW-MEDIUM — predictable failure modes | MEDIUM — fragmentation across variants | HIGH — unpredictable LLM-generated agents; QA story unclear |
| **Public-release readiness** | HIGH — adopted standard (AGENTS.md, 60k+ repos) ([agents.md](https://agents.md/)) | LOW — community pattern only | LOW — no production deployment of meta-gen at primary-architecture scale |
| **Update flow (plugin → user)** | CLEAN — plugin owns core, user owns overlay (Cursor, Codex) | FRAGMENTED — each user version on independent track | UNRESOLVED — no production solution to "regen vs preserve customization" conflict |

### Production verdict

The matrix loads heavily toward **generic+overlay**. The only column where per-project or meta-gen wins is "customization power" — and only at the cost of LOW or n/e on every other operational metric.

---

## Q12 — Framework shortlist (production-deployed candidates)

Selection criteria: production deployment evidence (named users, case studies, named pricing tier customers, public eng blog mentions). Heterogeneity weighted: avoid 5 LangGraph clones.

| # | Framework | Production users / signals | Pricing model | Architecture signal | URL |
|---|---|---|---|---|---|
| 1 | **Cursor (with Composer)** | >$500M ARR (estimated late 2025); Microsoft, Replit, Stripe, Shopify dev teams reported users | Per-seat $20-40/mo + usage tiers | Generalist + tool harness; multi-agent worktrees in 2.0 | [cursor.com](https://cursor.com/blog/composer) |
| 2 | **Claude Code** | Enterprise customers via Anthropic; 60k+ repos with CLAUDE.md; ecosystem of 4,200+ skills, 9,000+ plugins | Bundled with Claude API ($20+/mo Pro); per-token API | Generalist + plugins/skills/subagents; markdown-first | [code.claude.com](https://code.claude.com/docs/en/overview) |
| 3 | **Devin (Cognition)** | Goldman Sachs (12,000-dev pilot); Nubank, Ramp, MercadoLibre, Citi reported pilots | $20/mo Core, $500/mo Team, ACU-based ($2-2.25/15min) | Compound model: Planner+Coder+Critic+Browser; async delegation | [devin.ai/pricing](https://devin.ai/pricing/) |
| 4 | **OpenAI Codex CLI** | OpenAI-internal + ChatGPT Plus/Pro/Team/Enterprise users (millions) | Bundled with ChatGPT plans; or $1.50/M-in + $6/M-out via API | Open-source Rust CLI; AGENTS.md hierarchical inheritance; subagents inherit-with-override | [developers.openai.com/codex](https://developers.openai.com/codex/cli) |
| 5 | **Replit Agent 3** | Replit's 30M+ user base; Agent 3 specifically targets non-coders + production apps | Replit Core $25/mo, Teams $50, Enterprise custom | Sandboxed compound + browser-verification reflection loop; can generate other agents | [replit.com/products/agent](https://replit.com/products/agent) |
| 6 | **Cline (formerly Claude Dev)** | 1M+ VSCode marketplace installs; community dominant in autonomy-first niche | BYO API key; free OSS | Single-agent autonomy model; user-permission-gated each tool call | [github.com/cline/cline](https://github.com/cline/cline) |
| 7 | **Aider** | ~25k+ GitHub stars; mature OSS; adopted in research/CLI workflows | BYO API key; free OSS | Coder loop with optional architect/editor split (2-model pattern) | [aider.chat](https://aider.chat/docs/) |
| 8 | **OpenHands (formerly OpenDevin)** | 64k+ GitHub stars; AMD partnership for local deployment | OSS; cloud option | Stateless event-sourced SDK; production V1 with measured failure reduction | [openhands.dev](https://openhands.dev/) |
| 9 | **Sourcegraph Amp** | Sourcegraph Enterprise customers (large enterprises, named in marketing) | Enterprise pricing; replaced Cody Free/Pro mid-2025 | Multi-repo agentic; codebase-context-first | [sourcegraph.com](https://sourcegraph.com/blog/cody-the-ai-powered-tool-helping-support-engineers-unblock-themselves) |
| 10 | **Windsurf (Cognition-owned)** | Gartner Magic Quadrant Leader 2025; acquired by Cognition Dec 2025 for $250M | Per-seat enterprise | Cascade agent with planning sub-agent; deep codebase reasoning | [windsurf.com/cascade](https://windsurf.com/cascade) |
| 11 | **GitHub Copilot (Workspace + Agent Mode)** | GitHub's customer base (10M+ paid Copilot seats); Workspace TP sunset May 2025 → Agent Mode mainstreamed | $10-39/mo per seat tiers | Spec → plan → implement gates; sub-agent system | [github.com/features/copilot](https://docs.github.com/en/copilot/get-started/features) |
| 12 | **LangGraph (LangChain)** | Tens of thousands of LangChain production users; v1.0 stable late 2025 | Open source; LangSmith paid observability | Declarative graph + imperative nodes; durable state | [langchain.com](https://www.langchain.com/blog/how-to-think-about-agent-frameworks) |
| 13 | **Microsoft Agent Framework (post-AutoGen + Magentic-One)** | Azure / enterprise customers via Microsoft | Bundled with Azure | Hybrid: YAML agents + graph orchestration + middleware; production-ready convergence of AutoGen + Semantic Kernel | [microsoft.com/AutoGen](https://www.microsoft.com/en-us/research/articles/magentic-one-a-generalist-multi-agent-system-for-solving-complex-tasks/) |
| 14 | **CrewAI** | Production users; commercial enterprise tier; MIT license | Open source + commercial enterprise | Declarative YAML role definitions; sequential or hierarchical crews | [crewai.com](https://gurusup.com/blog/best-multi-agent-frameworks-2026) |
| 15 | **BMAD-METHOD** | Validated on NestJS monorepo (743 tests, 9 bounded contexts); 120K views on V4 Masterclass; v6 Alpha | Open source | YAML workflows + 7-9 specialized markdown agents; SDLC role-based | [docs.bmad-method.org](https://docs.bmad-method.org/) |
| 16 | **Sweep AI** | GitHub-app deployment; bundled into many indie/SMB devs' GitHub workflows | Free + paid tiers | Pure GitHub-event-driven; tag issue → PR; single agent | [github.com/sweepai](https://github.com/sweepai) |
| 17 | **Augment Code** | Enterprise customers; pricing model overhauled Oct 2025 to credits | $20/mo Indie, $60-200 Std/Max, $60-240k Enterprise | Large-codebase context-first agent | [augmentcode.com/pricing](https://www.augmentcode.com/pricing) |
| 18 | **Goose (Block / AAIF)** | Block (parent of Square / Cash App) production user; Linux Foundation hosted | OSS; BYO LLM | On-machine MCP-extensible agent; multi-LLM | [goose-docs.ai](https://goose-docs.ai/) |
| 19 | **Roo Code (shutting down May 2026; succeeded by roomote.dev)** | VSCode marketplace adoption; orchestrator mode + multi-mode design | Roo Cloud + Router (sunset); free extension | Mode-based generalist (Code/Architect/Ask/Debug/Custom) | [roocode.com](https://roocode.com/) |
| 20 | **Pydantic AI** | 16k+ GitHub stars by April 2026; Amazon Bedrock AgentCore users | OSS | Type-safe Python framework; production-grade structured output | [ai.pydantic.dev](https://ai.pydantic.dev/) |
| 21 | **OpenAI Agents SDK + AgentKit** | OpenAI customers via Responses API + Agents SDK (Mar 2025); AgentKit announced DevDay Oct 2025 | Per-token API | Successor to Swarm; orchestration with web search, file search, computer use | [openai.com](https://developers.openai.com/codex/cli) |

### "Why include" justifications

- **Cursor / Claude Code / Devin / Codex CLI / Replit / Cline / Aider:** Top-tier production coding agents with clear architectural distinctions; non-overlapping paradigms.
- **OpenHands:** Open-source production SDK with arXiv-published architecture lessons; serves "DIY production" niche.
- **Sourcegraph Amp / Windsurf / Copilot:** Enterprise-incumbent perspective.
- **LangGraph / MS Agent Framework / CrewAI / Pydantic AI / OpenAI Agents SDK:** General-purpose orchestration frameworks where coding agents are one use case; reveal infrastructure-layer trade-offs.
- **BMAD:** The closest-in-spirit framework to ceos-agents (SDLC role-based, declarative-leaning, markdown-first).
- **Sweep:** GitHub-event-driven autonomous PR creator; closest analog to ceos-agents bug-fix pipeline.
- **Augment Code:** Codebase-scale context perspective with documented enterprise pricing changes.
- **Goose:** Local-first / on-machine perspective backed by Block in production.
- **Roo Code:** Mode-based UX experiment; cautionary tale (shutting down May 2026 despite adoption).

### Notable observations / oddities

- **No meta-gen framework qualifies** — MetaAgent and Hyperagents are research-stage. This is a real signal: the architectural variant has no production validation.
- **AGENTS.md is technically not a framework** but a customization standard adopted by virtually every framework above. Its 60k-repo adoption is the strongest signal in this entire shortlist.
- **Roo Code's shutdown** (despite ~140k stars on the larger OpenCode they aren't related — different products) is a cautionary data point: novel UX patterns don't always survive in production.

### Suggested top 10 for Run 2 deep-dives (production-evidence-weighted)

Recommended priority for Run 2 framework deep-dives based on production evidence + paradigm distinctness + relevance to ceos-agents v8.0.0 architecture decision:

1. **BMAD-METHOD** (closest in spirit; YAML-pipeline-with-markdown-agents experiment)
2. **Cursor 2.0 (Composer)** (multi-agent worktrees; closest production "Claude Code with custom orchestration" parallel)
3. **Claude Code (subagents + skills + plugins)** (the platform ceos-agents lives on)
4. **Devin** (compound architecture; Goldman Sachs production data)
5. **LangGraph** (declarative graph + imperative nodes — the production-dominant orchestration paradigm)
6. **Anthropic Multi-Agent Research System** (orchestrator-worker reference; published architecture)
7. **OpenHands SDK** (only OSS production-grade SDK with published architecture paper)
8. **OpenAI Codex CLI + AGENTS.md + Subagents** (closest production example of typed-inheritance overlay model)
9. **Microsoft Agent Framework (Magentic-One)** (production successor to AutoGen; two-loop bookkeeping)
10. **CrewAI** (the YAML-role-DSL paradigm reference; highlights its limitations)

---

## Open questions / no-evidence-found

- **Quantified ROI numbers for hardcoded markdown → declarative pipeline migrations** specifically in the agent space — not found. Best analogs are CI pipeline migrations (Jenkins → Tekton/GHA) but these are not directly comparable.
- **Production cost-to-maintain meta-gen architecture** — no production deployments at scale, so no data.
- **Per-project full-set agent maintenance cost in production** — only community-pattern data; no enterprise productized example.
- **Goldman Sachs Devin pilot detailed defect/regression data** — only the high-level "20% efficiency gain" target and the SitePoint-aggregated "1.5-2× higher defect rate, 1.5-2.3 review cycles" anecdotes. No published peer-reviewed measurement.
- **AGENTS.md vs CLAUDE.md production drift behavior** when both exist — anecdotal only ("explicit chat prompts override everything; closest file wins").
- **Whether 21 specialized agents in one pipeline degrades vs 7-9** — empirical evidence supports diminishing returns past 3-5 in critique loops, but no specific 21 vs 7 comparison published.

---

## Sources

### Direct production evidence (eng blogs, vendor announcements, customer pilots)

- [Cursor 2.0 announcement (Cursor blog, Nov 2025)](https://cursor.com/blog/2-0)
- [Cursor Composer architecture (Cursor blog)](https://cursor.com/blog/composer)
- [Cursor agent best practices (Cursor blog)](https://cursor.com/blog/agent-best-practices)
- [Cursor Rules documentation](https://cursor.com/docs/rules)
- [Cognition introducing Devin](https://cognition.ai/blog/introducing-devin)
- [Cognition Devin 2.0 announcement](https://cognition.ai/blog/devin-2)
- [Cognition Devin annual performance review 2025](https://cognition.ai/blog/devin-annual-performance-review-2025)
- [Cognition "Don't Build Multi-Agents" essay](https://cognition.ai/blog/dont-build-multi-agents)
- [Anthropic — How we built our multi-agent research system](https://www.anthropic.com/engineering/multi-agent-research-system)
- [Anthropic — Effective context engineering for AI agents](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents)
- [Anthropic — Equipping agents for the real world with Agent Skills](https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills)
- [Anthropic — 2026 Agentic Coding Trends Report (PDF)](https://resources.anthropic.com/hubfs/2026%20Agentic%20Coding%20Trends%20Report.pdf)
- [Claude Code subagents docs](https://code.claude.com/docs/en/sub-agents)
- [Claude Code overview](https://code.claude.com/docs/en/overview)
- [Claude Code costs management](https://code.claude.com/docs/en/costs)
- [Claude API compaction docs](https://platform.claude.com/docs/en/build-with-claude/compaction)
- [OpenAI Codex CLI docs](https://developers.openai.com/codex/cli)
- [OpenAI Codex pricing](https://developers.openai.com/codex/pricing)
- [OpenAI Codex AGENTS.md guide](https://developers.openai.com/codex/guides/agents-md)
- [OpenAI Codex Subagents inheritance docs](https://developers.openai.com/codex/subagents)
- [OpenAI Agentic AI Foundation announcement](https://openai.com/index/agentic-ai-foundation/)
- [OpenAI Codex announcement](https://openai.com/index/introducing-codex/)
- [Devin pricing page](https://devin.ai/pricing/)
- [Devin 2.0 pricing cut announcement (VentureBeat)](https://venturebeat.com/programming-development/devin-2-0-is-here-cognition-slashes-price-of-ai-software-engineer-to-20-per-month-from-500)
- [Devin guide 2026 (AI Tools DevPro)](https://aitoolsdevpro.com/ai-tools/devin-guide/)
- [Goldman Sachs Devin pilot (CNBC)](https://www.cnbc.com/2025/07/11/goldman-sachs-autonomous-coder-pilot-marks-major-ai-milestone.html)
- [Goldman Sachs Devin pilot (IBM Think)](https://www.ibm.com/think/news/goldman-sachs-first-ai-employee-devin)
- [Devin production aftermath analysis (SitePoint)](https://www.sitepoint.com/devin-ai-engineers-production-realities/)
- [Replit Agent 3 announcement](https://blog.replit.com/introducing-agent-3-our-most-autonomous-agent-yet)
- [Replit 2025 in review](https://blog.replit.com/2025-replit-in-review)
- [Replit Agent product page](https://replit.com/products/agent)
- [Sourcegraph Cody blog](https://sourcegraph.com/blog/cody-the-ai-powered-tool-helping-support-engineers-unblock-themselves)
- [Windsurf Cascade product](https://windsurf.com/cascade)
- [GitHub Copilot Workspace](https://githubnext.com/projects/copilot-workspace)
- [GitHub Copilot features](https://docs.github.com/en/copilot/get-started/features)
- [Anthropic Plugins for Claude Code](https://claude.com/plugins)
- [Claude Code plugins docs](https://code.claude.com/docs/en/plugins)
- [Augment Code pricing](https://www.augmentcode.com/pricing)
- [Augment Code pricing change Oct 2025](https://www.augmentcode.com/blog/augment-codes-pricing-is-changing)

### Standards & ecosystem

- [AGENTS.md home](https://agents.md/)
- [AGENTS.md OpenAI Codex AGENTS.md sample](https://github.com/openai/codex/blob/main/AGENTS.md)
- [Builder.io AGENTS.md tips](https://www.builder.io/blog/agents-md)
- [awesome-claude-plugins (Composio)](https://github.com/ComposioHQ/awesome-claude-plugins)
- [awesome-claude-code (hesreallyhim)](https://github.com/hesreallyhim/awesome-claude-code)
- [VoltAgent awesome-claude-code-subagents](https://github.com/VoltAgent/awesome-claude-code-subagents)
- [wshobson agents](https://github.com/wshobson/agents)
- [jeremylongshore claude-code-plugins-plus-skills](https://github.com/jeremylongshore/claude-code-plugins-plus-skills)

### Frameworks (other than agents covered above)

- [BMAD Method docs](https://docs.bmad-method.org/)
- [BMAD GitHub](https://github.com/bmad-code-org/BMAD-METHOD)
- [BMAD plugin Claude Code](https://github.com/PabloLION/bmad-plugin)
- [BMAD reenbit explainer](https://reenbit.com/the-bmad-method-how-structured-ai-agents-turn-vibe-coding-into-production-ready-software/)
- [Magentic-One (Microsoft Research)](https://www.microsoft.com/en-us/research/articles/magentic-one-a-generalist-multi-agent-system-for-solving-complex-tasks/)
- [Microsoft Agent Framework production-ready convergence](https://cloudsummit.eu/blog/microsoft-agent-framework-production-ready-convergence-autogen-semantic-kernel)
- [Microsoft Agent Framework overview](https://learn.microsoft.com/en-us/agent-framework/overview/)
- [LangGraph blog "How to think about agent frameworks"](https://www.langchain.com/blog/how-to-think-about-agent-frameworks)
- [Aider docs](https://aider.chat/docs/)
- [Aider architect mode blog](https://aider.chat/2024/09/26/architect.html)
- [Aider GitHub](https://github.com/Aider-AI/aider)
- [Aider multi-agent proposal #4428](https://github.com/aider-ai/aider/issues/4428)
- [Aider multi-agent #1839](https://github.com/Aider-AI/aider/issues/1839)
- [Cline GitHub](https://github.com/cline/cline)
- [OpenHands SDK arXiv 2511.03690](https://arxiv.org/abs/2511.03690)
- [OpenHands V1 SDK GitHub](https://github.com/OpenHands/software-agent-sdk/)
- [Devstral release blog](https://openhands.dev/blog/devstral-a-new-state-of-the-art-open-model-for-coding-agents)
- [Tabby](https://www.tabbyml.com/)
- [Sweep AI overview](https://aiagentstore.ai/ai-agent/sweep-ai)
- [SWE-Agent GitHub](https://github.com/SWE-agent/SWE-agent)
- [Goose docs](https://goose-docs.ai/)
- [Goose GitHub](https://github.com/aaif-goose/goose)
- [OpenCode](https://opencode.ai/)
- [Pydantic AI docs](https://ai.pydantic.dev/)
- [Roo Code](https://roocode.com/)
- [Roo Code GitHub](https://github.com/RooCodeInc/Roo-Code)
- [Kilo Code](https://kilo.ai)
- [Mastra framework](https://mastra.ai/framework)

### Benchmarks

- [SWE-bench leaderboards](https://www.swebench.com/)
- [SWE-bench Verified](https://www.swebench.com/verified.html)
- [Live-SWE-agent leaderboard](https://live-swe-agent.github.io/)
- [SWE-Bench Pro leaderboard (Scale)](https://labs.scale.com/leaderboard/swe_bench_pro_public)
- [Vals.ai SWE-bench](https://www.vals.ai/benchmarks/swebench)

### Architecture analyses & third-party validation

- [LangGraph vs Temporal for AI Agents (Medium)](https://medium.com/data-science-collective/langgraph-vs-temporal-for-ai-agents-durable-execution-architecture-beyond-for-loops-a1f640d35f02)
- [LangGraph vs AutoGen vs CrewAI comparison (DataCamp)](https://www.datacamp.com/tutorial/crewai-vs-langgraph-vs-autogen)
- [Multi-agent dispatch overhead economics (Iterathon)](https://iterathon.tech/blog/multi-agent-orchestration-economics-single-vs-multi-2026)
- [Best Multi-Agent Frameworks 2026 (gurusup)](https://gurusup.com/blog/best-multi-agent-frameworks-2026)
- [Coding Agent Teams 72.2% SWE-bench (dev.to)](https://dev.to/nikita_benkovich_eb86e54d/coding-agent-teams-outperform-solo-agents-722-on-swe-bench-verified-4of5)
- [Multi-Agent Critique & Revision (Emergent Mind)](https://www.emergentmind.com/topics/multi-agent-critique-and-revision)
- [Single vs Multi-Agent System (Phil Schmid)](https://www.philschmid.de/single-vs-multi-agents)
- [Cursor 2.0 multi-agent (InfoQ)](https://www.infoq.com/news/2025/11/cursor-composer-multiagent/)
- [Replit Agent 3 (InfoQ)](https://www.infoq.com/news/2025/09/replit-agent-3/)
- [How Cursor Shipped its Coding Agent to Production (ByteByteGo)](https://blog.bytebytego.com/p/how-cursor-shipped-its-coding-agent)
- [Anthropic Multi-Agent Research System summary (ByteByteGo)](https://blog.bytebytego.com/p/how-anthropic-built-a-multi-agent)
- [Why AI Agents Should Be Specialists (Kubiya)](https://www.kubiya.ai/blog/why-should-ai-agents-be-specialists-not-generalists-moe-in-practice)
- [Generalist vs Specialized AI Agents (Katonic AI)](https://www.katonic.ai/blog/generalist-agents)
- [HITL patterns (WorkOS)](https://workos.com/blog/why-ai-still-needs-you-exploring-human-in-the-loop-systems)
- [HITL patterns (DEV.to Taimoor)](https://dev.to/taimoor__z/-human-in-the-loop-hitl-for-ai-agents-patterns-and-best-practices-5ep5)
- [Stateful vs Stateless AI Agents (Tacnode)](https://tacnode.io/post/stateful-vs-stateless-ai-agents-practical-architecture-guide-for-developers)
- [Token budget management Claude Code (MindStudio)](https://www.mindstudio.ai/blog/ai-agent-token-budget-management-claude-code)
- [Claude Code Compaction (Medium)](https://medium.com/@reliabledataengineering/claude-compaction-the-secret-to-infinite-length-conversations-03b6ee607f2d)
- [Claude Skills deep dive (Lee Hanchung)](https://leehanchung.github.io/blogs/2025/10/26/claude-skills-deep-dive/)
- [Piebald-AI claude-code-system-prompts](https://github.com/Piebald-AI/claude-code-system-prompts)

### Research / academic

- [LLM-based Agents Suffer from Hallucinations (arXiv 2509.18970)](https://arxiv.org/abs/2509.18970)
- [MetaAgent (arXiv 2507.22606)](https://arxiv.org/abs/2507.22606)
- [Meta Hyperagents (VentureBeat)](https://venturebeat.com/orchestration/meta-researchers-introduce-hyperagents-to-unlock-self-improving-ai-for-non-coding-tasks)
- [OpenHands paper (arXiv 2511.03690)](https://arxiv.org/abs/2511.03690)

### Hacker News / community discussion

- [Don't Build Multi-Agents HN discussion](https://news.ycombinator.com/item?id=45096962)
- [Jason Zhou X thread on Cognition's essay](https://x.com/jasonzhou1993/status/1933484175140794639)
