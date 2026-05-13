# Phase 2 Synthesis — Q1–Q12 Unified Report (Run 1)

**Datum:** 2026-04-26
**Run:** 2026-04-26-A-research-run1 (forge-research, sub-projekt A v8.0.0)
**Scope:** C1–C5 (Q1–Q12) napříč 5 paralelními research lenses — academic / production / OSS-code / community / vendor
**Vstup:** 5 agent reports (~290KB total) + původní question spec (`docs/superpowers/specs/2026-04-26-A-research-questions-DRAFT.md`)
**Output role:** evidence map jako vstup do Run 2 (deep-dive Top 10 frameworků z Q12 + Q22 cross-run paradigm synthesis); **NIKOLI rozhodovací dokument pro v8.0.0**

---

## Executive summary

1. **Markdown + YAML frontmatter je v 2026 de facto standard pro "ship a plugin" agent customization.** AGENTS.md adoptováno >60k repozitáři (Cursor, OpenAI Codex, Amp, Devin, Factory, Gemini CLI, Copilot, Jules, VS Code), Linux Foundation steward (AAIF) — agent-2 [agents.md](https://agents.md/). 100% top-15 Claude Code pluginů (per `quemsah/awesome-claude-plugins`) používá markdown jako primary instruction surface, YAML pouze frontmatter — agent-4. Žádný major vendor neimplementuje YAML-pipeline-as-control-flow-DSL — agent-5 (Anthropic / OpenAI / Google / Microsoft / Meta).
2. **Generic+overlay je jediný production-validated public-release pattern** napříč všemi 5 lenses: Anthropic 5-tier subagent priority (Managed > CLI > Local > Project > User > Plugin) — agent-5; BMAD-METHOD `customize.toml` s explicit merge rules (scalars override, arrays append, arrays-of-tables match by id) — agent-3; Cursor `.cursor/rules` + Claude Code `.claude/agents/` + Codex AGENTS.md inheritance — agent-2. **Per-project full sets nemá vendor exemplar; meta-gen má 0 production deployment** (research only: MetaAgent arxiv 2507.22606, Hyperagents, MetaGen arxiv 2601.19290) — všech 5 agentů konvergentně.
3. **Single-vs-multi-agent debata má clearcut empirickou bifurkaci podle task type**, NE univerzální vítěz. **Cognition "Don't Build Multi-Agents" essay (June 2025)** vs **Anthropic "+90.2% multi-agent on internal evals" (June 2025)** — protichůdné autoritativní pozice; rozdíl tracking task type: write tasks → single-agent, read/research tasks → parallel sub-agents (agent-2). Akademické důkazy (Kim et al. arxiv 2512.08296, Yin et al. arxiv 2511.00872, Xu et al. arxiv 2601.12307) konzistentně reportují single-agent baselines překonávají multi-agent na SWE benchmarks; multi-agent overhead 58–515%, error amplification 4.4×–17.2× (agent-1).
4. **Hloubka prompt promptu — vendor consensus ostře přesouvá k "Goldilocks zóně" (specific enough to constrain, flexible enough to allow autonomy)** — agent-5. Anthropic 2025-09 "Effective context engineering" + Claude Code system prompt 6,973 tokens (arxiv 2601.21233, agent-4) zarámují, že současné ceos-agents prompty (100–500 řádků markdown) leží uvnitř empirické zóny, ale **prescriptive numbered Process steps + NEVER constraints "často backfirují uvnitř agent loops"** per Anthropic 2025/2026 guidance. Source-code evidence (agent-3) ukazuje 3 distinct depth modes v ekosystému: thin (15–100 lines, Cline / OpenAI Agents / Pydantic AI / Strands), mid (100–300 lines, ceos-agents / Anthropic skills / wshobson), deep (300+ lines, BMAD bmad-dev-story 485 / MetaGPT engineer 513 / smolagents 313).
5. **HITL placement: vendor consensus na event-driven gates, NE per-stage gates** — Anthropic checkpoint-or-blocker pattern, OpenAI `needsApproval` per-action, Microsoft Magentic-One "Optional Plan Review" + "Stall Detection" (agent-5). Akademická evidence shoduje: plan-then-execute pattern (Design Patterns paper arxiv 2506.08837) + Feng et al. L3 Consultant / L4 Approver tier (arxiv 2506.12469, agent-1). Production rozkol: Cursor synchronous per-action vs Devin async-200-min — oba deploynuté, oba mají platící uživatele; výběr je HITL placement, NIKOLI capability (agent-2). Stack Overflow 2025: 46% developerů nedůvěřuje AI accuracy (vs 31% loni) — implikuje **více HITL transparency, ne méně** (agent-4).
6. **LLM-as-config-interpreter reliability: zlepšuje se, ale stále weakest link.** Constrained decoding (OpenAI Structured Outputs Aug 2024 = 100% schema compliance; Anthropic 2025-11-14 grammar-restricted decoding) řeší **format adherence**, NEŘEŠÍ **content correctness** (agent-5). Empirické multi-agent failure rates 41–86.7% v production když orchestration unstructured (Augment Code, agent-4). CrewAI 3× managerial overhead vs LangChain pro equivalent tool calls (Iterathon, agent-2). Magentic-One 2-loop bookkeeping (task ledger + progress ledger) explicitně proto, že LLM dispatch sám není reliable (agent-2 + agent-3 source). **Vendor convergence: declarative for structure + imperative escape hatch + structured output validation** (LangGraph, MS Agent Framework, Mastra, Strands).
7. **Q12 framework universe je široký a fragmentovaný; Top 10 auto-selected pro Run 2 deep-dive kombinuje (a) production scale, (b) paradigm distinctness, (c) ceos-agents v8.0.0 architectural relevance.** Klíčoví kandidáti: BMAD-METHOD (closest peer, 45.7k★, customize.toml overlay), Claude Code subagents+skills (host platform, Anthropic-blessed pattern), Microsoft Agent Framework (production successor to AutoGen, declarative YAML emerging), LangGraph (graph DSL paradigm reference), OpenAI Agents SDK (handoffs as tools), Devin/Cognition (compound 4-component, Goldman Sachs production data), Anthropic Multi-Agent Research System (orchestrator-worker reference), CrewAI (YAML-DSL paradigm + limitations), opencode (149.7k★ explosive growth), wshobson/agents (closest commercial peer pattern in markdown-plugin space).

---

## Methodology note

5 paralelních research agentů zodpovědělo Q1–Q12 z 5 různých úhlů:

- **Agent 1 (academic):** arxiv literatura, peer-reviewed papers, standardized benchmarks (SWE-bench, GAIA, AgentBench), research labs. 60KB / 692 řádků. ~50 unique citations, dominant 2025–2026.
- **Agent 2 (production):** shipping AI coding products, eng blogs, pricing pages, customer case studies (Cursor / Claude Code / Devin / Replit / GitHub / Sourcegraph / Augment / Anthropic / Cognition). 73KB / 747 řádků. Heavy vendor URL citations.
- **Agent 3 (OSS code):** source-code reading 22 frameworků, file/line citations (BMAD `customize.toml:18-23`, MetaGPT `engineer.py:513`, Magentic-One `_prompts.py:46-94`, etc.). 50KB / 603 řádků. Quantitative source diffs.
- **Agent 4 (community):** HN/Reddit/X/podcasts/surveys; awesome-* lists; sentiment analysis; hype-vs-substance. 56KB / 492 řádků. Stack Overflow Survey 2025, GitHub Octoverse 2025, Karpathy Dec-2025 viral commentary.
- **Agent 5 (vendor docs):** Anthropic / OpenAI / Google / Microsoft / Meta official documentation, with date stamps; vendor positioning evolution timeline. 48KB / 532 řádků.

**Synthesis postup per Q1–Q12:**

1. **Triangulace** napříč 5 lenses — kde converging consensus (≥3 lenses shoduje), kde authoritative controversy (≥2 vendors / lab disagree), kde singular evidence (jediný lens reportuje).
2. **Score per claim:** source diversity (kolik lenses) × evidence strength (peer-reviewed > vendor blog > community sentiment) × recency (2026 > 2025 > earlier).
3. **Selection:** highest-scoring formulation per question; preserve nuance.
4. **Controversies surfacing:** explicitní contradictions (Cognition vs Anthropic, OpenAI single-first vs Anthropic multi-OK, etc.) NIKDY nepředělávat; oba zachovat s evidence.
5. **Citations:** každý syntetizovaný claim ≥1 cross-lens citation, preferred ≥2.

**Special handling:**
- Q5 (4 sub-questions): Q5a/b/c/d zpracováno separately, každé s plnou triangulací.
- Q12 (Run 2 vstup): aggregate napříč 5 lenses → deduplicate → auto-score 5 axes (stars 90d delta / visibility / production adoption / dev activity 30d / novelty) → weighted score (0.20 × 0.20 × 0.25 × 0.15 × 0.20) → ranked shortlist 18 entries → auto-select Top 10 by score (NO user gate).

**Hard rules dodržené:**
- Žádný recommendation/verdict pro ceos-agents v8.0.0 — output je evidence map, NIKOLI decision document. A.1 brainstorm to udělá.
- Czech prose, English citations + framework names + technical terms.
- "No evidence found" honest disclosure kde lenses converged on absence.

---

## C1 — Agent prompt engineering

### Q1 — Hloubka agent system promptu

**Cross-lens consensus:** Vendor / academia / community konvergují na **"Goldilocks zone"** — ne maximalist ne minimalist. Anthropic 2025-09-29 "Effective context engineering" explicitně formuluje: *"the minimal set of information that fully outlines your expected behavior. (Note that minimal does not necessarily mean short)"* a *"specific enough to guide behavior effectively, yet flexible enough to provide the model with strong heuristics"* — vendor (agent-5) + academic (agent-1, citováno přímo) + community (agent-4). Reasoning-model éra (post-o1 / Claude 4.x extended thinking / Opus 4.7) **dále posunuje optimum k terse role definitions + runtime context discovery** — Anthropic Q1 2026: *"smarter models require less prescriptive engineering"* (agent-5).

**Empirický anchor:** Claude Code's vlastní production system prompt = **6,973 tokens** (arxiv 2601.21233, agent-4) — Anthropic ships *substantial* (ne minimal) prompt pro flagship. To dává **empirickou validitu** ceos-agents 100–500 řádků markdown agent definitions. Liu/Wang/Willard "Effects of Prompt Length on Domain-specific Tasks" (arxiv 2502.14255, agent-1): *"Long instructions generally improve performance metrics across all tasks on all experimented domains"* — částečně defenduje maximalist v domain-narrow kontextu.

**Lens-specific evidence:**

- **[academic, agent-1]** "Less Is More" (arxiv 2604.18897): hard accuracy plateaus 60–79% napříč 40+ prompt variants — **hard ceiling on prompt-engineering returns**. AgentArch (arxiv 2509.10769): Pass@K = 6.34% při 8 trials → *"prompt depth alone cannot rescue agent reliability."* "Coding Agents are Effective Long-Context Processors" (arxiv 2603.20432) — universal Pareto curve mezi reasoning length a accuracy.
- **[production, agent-2]** Anthropic Skills (Oct 2025) → progressive disclosure 3-tier (Tier 1 metadata ~100 tokens, Tier 2 SKILL.md <5k, Tier 3 bundled resources). Reportované úspory: "1,500 tokens total for all 40 skills" + ~30–50% reduction vs monolithic. Cursor explicit anti-maximalist: *"Add rules only when you notice the agent making the same mistake repeatedly. Don't paste style guides — use a linter instead."* mini-SWE-agent + Claude Opus 4.5 = **79.2% SWE-bench Verified s pouze bash, žádný scaffold** → frontier models redukují potřebu verbose prompt scaffolding.
- **[OSS code, agent-3]** Per-framework size table identifikuje **3 distinct depth modes**: thin (15–100 řádků: Cline `agent_role.ts`=15, OpenAI Agents `instructions=` typically 20–200 chars, Pydantic AI plain string, Strands `system_prompt: str`); mid (100–300 řádků: ceos-agents `fixer.md`=117, Anthropic `mcp-builder/SKILL.md`=236, wshobson `backend-architect.md`=309); deep (300+ řádků: BMAD `bmad-dev-story/SKILL.md`=485, MetaGPT `engineer.py`=513, smolagents `code_agent.yaml`=313). Frameworks scaling specialization (BMAD, MetaGPT, wshobson) trend k **multi-file decomposition** (SKILL.md + steps/*.md + customize.toml) místo mega-prompts.
- **[community, agent-4]** *"prompt engineering" → "context engineering"* sentiment shift (Anthropic, Google, Manus konvergence): *"every token added to the context window competes for the model's attention"* (Nate's Newsletter Substack). 2026 production hot take: *"longer context windows often make things worse, not better"*. Cost data: prompt 3,000 → 7,000 tokens = +130% size pro +30% accuracy gain (fast.io); prompt caching 89.5% reduction na 5K-token system prompts. Karpathy Dec-2025 viral tweet formalizoval že **customization stack je differentiator**, ne model.
- **[vendor, agent-5]** Vendor evolution timeline: 2024-Q3 baseline (XML structured prompts) → 2025-09 Anthropic "context engineering" → 2025-10-16 Skills progressive disclosure → 2025-11-26 *"unclear single vs multi"* → 2026-Q1 Opus 4.7 *"less prescriptive engineering."* OpenAI Practical Guide (March 2025): *"a single agent can handle many tasks by incrementally adding tools"*. Microsoft Agent Framework: *"You are a friendly assistant. Keep your answers brief"* (hello-world).

**Controversies / open questions:**
- Akademie (Less Is More, AgentArch) říká diminishing returns past saturation; production (Liu et al., domain-narrow tasks) říká long instructions help. **Resolution:** task-conditional — open-ended → minimalist + tools; domain-narrow CI-style → moderate maximalist OK.
- Vendor "less prescriptive for smarter models" guidance vs ceos-agents kontext deterministic CI pipelines — pro **deterministic** workflows je prescription defensible (agent-1 nuance).

---

### Q2 — Granularita agenta

**Cross-lens consensus:** **No empirical winner napříč extrémy** (broad role vs narrow specialist), ale convergent finding že **>20–30 agentů per system creates discoverability problems** + **per-agent context starvation** za fixed compute. Granularita má být driven **task structure** (parallelizability, sequential vs independent), NIKOLI aesthetic preference. ceos-agents 21 narrow agents = **at outer edge of production precedent** (Devin compound = 4 components, BMAD = 7–9 roles, Anthropic research = 1 Lead + 3–5 sub-agents, Magentic-One = 1 Orchestrator + 4 specialists).

**Lens-specific evidence:**

- **[academic, agent-1]** Kim et al. "Towards a Science of Scaling Agent Systems" (arxiv 2512.08296, Dec 2025) — **most quantitatively important paper:** *"per-agent reasoning capacity becomes prohibitively thin beyond 3–4 agents"* under fixed compute. Reasoning turns power-law scaling exponent **1.724** (p<0.001). Aggregate success rates: SAS 46.6%, Independent MAS 37.0%, Decentralized 47.7%, Centralized 46.3%, Hybrid 45.2%. **Error amplification factors vs SAS**: Centralized 4.4×, Decentralized 7.8×, Hybrid 5.1×, Independent 17.2×. *"Tasks where single-agent performance already exceeds 45% accuracy experience negative returns from additional agents."* Yin et al. (arxiv 2511.00872, Nov 2025): single-agent outperformed multi-agent across 7 frameworks na 3 SE tasks; **planning agents consume 65–67% of tokens v multi-agent SE systems**. Xu et al. (arxiv 2601.12307): single-agent OneFlow 92.1% vs multi-agent AFlow 90.1% na HumanEval; rovnocenně na GSM8K za nižší cost ($0.020 vs $0.026). Strachan/Ying et al. (arxiv 2503.15703): *"task parallelizability directly governs the effectiveness of generalist teams."*
- **[production, agent-2]** Cognition "Don't Build Multi-Agents" (June 2025): *"share full agent traces, not just individual messages"* — single-threaded continuous context for write tasks. Devin "compound model": Planner+Coder+Critic+Browser = **4 components**. Magentic-One: 1 Orchestrator + 4 specialists. Anthropic research: Lead + 3–5 parallel sub-agents per query. BMAD: 7–9 roles ale most workflows touch 3–4. Coding Agent Teams 2025: SOTA SWE-bench Verified **72.2% bez benchmark tuning** s manager/researcher/engineer/reviewer = 4 roles. Critique-revision cycles: *"one or two cycles suffice; performance benefits saturate or degrade past that due to over-correction or echo-chamber dynamics. Three collaborators is often the sweet spot."*
- **[OSS code, agent-3]** Granularity matrix: Roo Code = 5 built-in modes (broad), MetaGPT = 7 roles (broad multi-action), BMAD = 2-3 persona + ~20 workflow skills per module (hybrid persona-broad/skill-narrow), ceos-agents = 21 (most narrow), wshobson = 100+ per plugin (most extreme specialization, but no orchestration script). MetaGPT paper: 5 narrow roles → **85.9% completion vs <35% monolithic GPT-4 baseline**. BMAD evolution v3 → v5 (~2025): explicitly cited *"agents got unmaintainable, split into skills."* **Practical sweet spot in source: ≤25 specialized agents.**
- **[community, agent-4]** Specialist agent: **20% more accurate, 40% faster than generalist on same task** (Medium, 2026). Specialist models v narrow domains často **95–99% accuracy** (Kubiya). Anti-pattern: *"26% of all requests were subagent calls — agents spawning other agents to do research, code review, parallel exploration"* (MindStudio 2026 Reddit dev experience). BMAD 43k–45k★ = strongest single signal že "12+ specialized personas across full SDLC" je viral; ALE v6 alpha exposed *"50+ workflows (up from 20), 19+ specialized agents (up from 12)"* complexity criticism (GH Discussion #1306). Counter: superpowers ~165k★ stars (per quemsah index) = **opačný** přístup (small composable skills, sub-agent dispatch, "VERY token light").
- **[vendor, agent-5]** **Two clear vendor camps:** OpenAI camp (single-agent default, multi-agent only when single fails — *"OpenAI's general recommendation is to maximize a single agent's capabilities first. More agents can provide intuitive separation of concepts, but can introduce additional complexity and overhead, so often a single agent with tools is sufficient"*) vs Anthropic+Google+Microsoft camp (multi-agent specialization OK from day one for context isolation). Anthropic Nov 2025 harness post: *"unclear whether a single, general-purpose coding agent performs best across contexts."* **Žádný vendor nepublikuje "max agents per system" doporučení.**

**Controversies / open questions:**
- Cognition "Don't Build Multi-Agents" vs Anthropic "+90.2% on internal evals" — protichůdné autoritativní pozice **resolved by task type** (write vs read).
- ceos-agents 21 agentů: **defensible** per agent-1 protože sequential + fresh context dispatch = academia by to nazvala "single-agent pipeline with role-switching, not multi-agent system." Production median (agent-2) = 7–10 agents per pipeline; konsolidační kandidáti: triage+code-analyst, test-engineer+e2e-test-engineer, reproducer+browser-verifier (per agent-1 + agent-2).
- BMAD vs superpowers (Q4 community): **viral packaging vs composable** — oba úspěšné, differentiating factor "whether the user can compose vs is forced to swallow the whole methodology."

---

### Q3 — Univerzální vs per-projekt vs hybrid agent

**Cross-lens consensus:** **Hybrid (generic core + lightweight project-specific overlay) je dominantní production pattern**; pure per-project má **negative-transfer risk** + maintenance burden + žádný vendor exemplar; meta-gen je research-stage, žádné production deployment found at scale.

**Lens-specific evidence:**

- **[academic, agent-1]** **Žádný academic study side-by-side compares fully-generic vs fully-per-project vs hybrid agent architectures.** Closest: ADP paper (arxiv 2510.24702): *"ADP consistently outperforms task-specific tuning on the target task and avoids negative transfer that single-domain tuning often induces on other tasks. SWE-Bench: ADP-tuned Qwen-2.5-7B-Instruct achieves 10.4% vs 1.0% with SWE-smith Only"* → **negative transfer is real risk** of fully per-project agents. Distillation paper (arxiv 2510.00482): lightweight fine-tuning + RAG with small domain-example sets ≈ fully domain-fine-tuned. AgentScope 1.0 (arxiv 2508.16279): inheritance-based StateModule base class. Authenticated Workflows (arxiv 2602.10465): `extends` field semantics, *"each child policy refines its parent by adding restrictions"* — analogous to ceos `Agent Overrides`. NVIDIA SLM (arxiv 2506.02153): *"heterogeneous agentic systems"* — hybrid not wholly per-project.
- **[production, agent-2]** Universal/generic with per-project overlay = **dominant production pattern**: Cursor (`.cursor/rules/`), Claude Code (CLAUDE.md, AGENTS.md, `.claude/agents/`, `.claude/skills/SKILL.md`), Codex CLI (AGENTS.md hierarchical). Per-project: only wshobson/agents (community pattern). Hybrid inheritance: **OpenAI Codex subagents inherit parent config** (`nickname_candidates`, `model`, `model_reasoning_effort`, `sandbox_mode`, `mcp_servers`, `skills.config`) but can be overridden — **closest production-shipping inheritance model**. Meta-gen: MetaAgent (research only, arxiv 2507.22606), Hyperagents (research). Replit Agent 3 has "generate other agents" jako feature, NIKOLI core architecture. Anthropic explicit: *"building your own subagents designed specifically for your project is recommended rather than using public ones. Generic prompts won't understand your codebase patterns and conventions."*
- **[OSS code, agent-3]** Per-framework choice matrix: BMAD = Generic+Overlay (most sophisticated with 3-tier merge `base → team → user` per `bmad-agent-pm/SKILL.md:34`); ceos-agents = Generic+Overlay (`Agent Overrides`); Anthropic skills = Generic only (fork to customize); wshobson = Generic only (fork). OpenAI Agents SDK / LangGraph = developer-defined per-project (Python construction). Roo Code = Generic + Custom-Mode (additive). Cline = Generic + `.clinerules` per-project. **Source-derived conclusion:** Generic+Overlay je **dominant production pattern for plugin-style ecosystems**; per-project je dominant pro library/SDK-style frameworks. **Meta-gen is unproven at scale.**
- **[community, agent-4]** Top-15 plugins per quemsah index: superpowers (165k★+, markdown SKILL.md), anthropics/skills (123k★+, SKILL.md+YAML frontmatter), andrej-karpathy-skills (82k★+, **CLAUDE.md alone**), ui-ux-pro-max-skill (69k★+, markdown), BMAD-METHOD (45k★+, compiled markdown + YAML expansion packs). **100% top-15 použivá markdown jako primary customization surface.** Per-project = **community-rejected anti-pattern** (forces forking-equivalent: full agent set duplication per project). Meta-gen = **uncertain — speculative**.
- **[vendor, agent-5]** Anthropic 5-tier subagent priority (Managed > CLI > Local > Project > User > Plugin) je **clearest vendor endorsement of Generic+Overlay**. *"Subagent definitions from any of these scopes are also available to agent teams: when spawning a teammate... the definition's body appended to the teammate's system prompt as additional instructions"* — **append-to-prompt pattern** = exactly what ceos-agents `Agent Overrides` already implements. **Žádný vendor explicitly endorses "per-project from scratch"** ani "meta-gen" jako primary pattern.

**Controversies / open questions:**
- **No evidence** že per-project full sets are productized at scale. agent-3 explicit: *"per-project agent sets are not commonly implemented in OSS frameworks."*
- Meta-gen feasibility: MetaGen (arxiv 2601.19290), ADAS, MetaSynth (arxiv 2504.12563), Meta-Prompting Protocol (arxiv 2512.15053) **emerging research, not established practice** — žádný production-validated outperform vs well-tuned static architectures (agent-1 + agent-3).

---

### Q4 — Stateful vs stateless agenti

**Cross-lens consensus:** **Production frameworks konvergují na "stateless dispatch + explicit summary handoff" pro orchestrator-to-subagent layer**, a **"stateful within agent + auto-compaction" pro inside-agent iteration**. Žádný vendor používá pure stateless jako default; všichni 4 major vendors ship persistence + resume APIs. ceos-agents stateless dispatch s explicit state passing přes `state.json` + `pipeline-history.md` = **functionally equivalent k Anthropic "structured note-taking" recommendation**.

**Lens-specific evidence:**

- **[academic, agent-1]** "Stateless Decision Memory for Enterprise AI Agents" (arxiv 2604.20158, 2026) — **most direct paper:** *"Stateful memory architectures violate enterprise deployment properties by construction... Statelessness is attainable in an agent-memory substrate without paying the decision-quality penalty retrieval pays."* Their stateless DPM: **7-15× faster, 2 LLM calls per decision vs 83-97 for summarization on LongHorizon-Bench**. AMA-Bench (arxiv 2602.22769): long-horizon memory needed for some agent classes, ale focus on conversational ne pipeline-style. Hindsight is 20/20 (arxiv 2512.12818, Dec 2025): SOTA on memory-bench tasks, but for personal-assistant style. AgentScope 1.0 (arxiv 2508.16279): `state_dict`/`load_state_dict` opt-in, not default. Anthropic subagents docs: *"Subagents prevent context bloat by isolating exploration in clean context windows, returning only summaries."*
- **[production, agent-2]** Anthropic explicit: subagenti mají **independent context windows** (stateless to each other; stateful within single sub-agent's lifetime); Lead Agent compresses results to "lightweight references." Cognition counter-recommendation: **single-threaded continuous context throughout task lifecycle** + hierarchical compression LLM-as-summarizer when overflow. Cursor: *"Long conversations can cause the agent to lose focus. Recommendation: start fresh"*; community workaround = "Memory Banks." Cline `new_task` = *"form of persistent memory for complex, long-running tasks."* Claude Code: **automatic compaction** ("Five-layer compaction pipeline"); real-world report *"compaction kicks in frequently and consumes what feels like roughly half of available tokens"* (issue #28984). Token cost growth in stateful loops: 888 tokens iter 1 → **18,900 by iter 5** without compaction (MindStudio).
- **[OSS code, agent-3]** Sub-otázka explicitně necovered, ale [agent-3 Q5a matrix]: AutoGen = Yes (per-agent), CrewAI = Yes, LangGraph = Yes (shared state), MetaGPT = Yes, OpenHands = No (per-step), SWE-Agent = No, AgentScope = Configurable, Strands = Optional, OpenAI Agents SDK = Session memory. **Konfigurabilita je norm; pure stateful nebo pure stateless je rare.**
- **[community, agent-4]** Sub-otázka necovered explicitně, ale [agent-4 trends]: 68% production agents execute **at most 10 steps before human intervention** (arxiv 2512.04123) — short loops, NOT long-running autonomous; mitiguje state accumulation problem.
- **[vendor, agent-5]** **Vendor consensus: stateful by default with explicit checkpointing/compaction primitives.** Anthropic Sessions (built-in), Compaction (auto when context limit approaches), persistent memory subagents (`memory: user|project|local` frontmatter), Memory tool (Sep 2025: *"agent regularly writes notes persisted to memory outside of the context window"*). OpenAI Sessions opt-in; per-agent stateless je default; Context via `RunContextWrapper` (DI). Google ADK: Shared `session.state` via `output_key` mezi agenty (state scope = invocation). Microsoft Agent Framework: session-based state (Semantic Kernel inheritance), pause/resume + checkpointing.

**Controversies / open questions:**
- Akademie (Stateless DPM paper) říká stateless wins for enterprise; vendors (Anthropic + Microsoft) ship stateful by default. **Resolution:** vendor "stateful" = within-agent-lifetime + checkpointing; ceos-agents "stateless dispatch + state.json" = functionally hybrid (stateless agents, stateful pipeline state).
- **No evidence** isolating reasoning-model (o1/o3/o4, Claude 4.x extended thinking) impact on stateful vs stateless agent design (agent-1 explicit gap).
- Long-horizon **pipeline-style** stateful runs vs stateless re-dispatch is **under-studied** academically (agent-1 gap).

---

## C2 — Pipeline architecture

### Q5a — Pipeline shape diversity v ekosystému

**Cross-lens consensus:** **Diversity je real**; **žádný dominant winner** napříč pipeline shapes; výběr je **ecosystem-driven** (Python framework → Python graph; markdown plugin → markdown procedural; enterprise → YAML), NIKOLI empirically superior. Konvergence na 3 primitivech (sequential, parallel, routing/handoff) napříč všemi 4 vendory; Magentic-One = jediný vendor-blessed dynamic-replanning.

**Lens-specific evidence:**

- **[academic, agent-1]** Martinez & Franch "Dissecting SWE-Bench Leaderboards" (arxiv 2506.17208): **7 architectural groups (G1–G7)** identified; 3 execution patterns (fixed/scaffolded/emergent autonomy). *"High-performing submissions follow a variety of architectural strategies — no single architecture dominates."* AgentArch (arxiv 2509.10769): *"Variation in memory management and orchestration strategies within multi-agent had minimal impact on scores. Models peaked on different configurations between use cases — no universal optimum."* Kim et al. mixed-effects model: **51.3% of performance variance explained through coordination metrics** vs 43% by categorical architecture labels — *"architecture choice is task-conditional, not universal."* Open Agent Specification (arxiv 2510.04173): same spec executable cross-frameworks (LangGraph, CrewAI, AutoGen, WayFlow) → frameworks converging on common abstractions despite surface diversity.
- **[production, agent-2]** Production matrix (15 frameworks scored): generalist + tool harness (Cursor, Claude Code, Aider, mini-SWE-agent, Sweep, Roo Code) = modal pro general coding assistance; specialist roles compound (Devin, Magentic-One, BMAD, Anthropic research, ceos-agents) = modal pro structured SDLC work; pure generalist single agent (mini-SWE-agent + frontier model) wins SWE-bench Verified at **79.2%** = diminishing returns of scaffold complexity. Stage orderings: Plan→execute→review (Devin/Cursor/Aider architect) = 6 frameworks; Triage→fix→test→publish (ceos-agents/Sweep/BMAD-Dev) = 4 frameworks; Spec→arch→impl→test→publish (BMAD full SDLC, ceos-agents implement-feature) = 2 frameworks; Orchestrate parallel→merge (Anthropic research, Cursor 2.0 multi-agent) = 2 frameworks. **ceos-agents 8+ stage ordering je unusually deep vs production peers** (Devin = 4 components, BMAD-Dev = 4 steps).
- **[OSS code, agent-3]** **5 distinct paradigms in source code:** (a) graph-edge declaration (LangGraph, Strands `multiagent/graph.py`), (b) decorator-driven event flow (CrewAI `@start`/`@listen`/`@router`), (c) YAML-declarative DSL (MS Agent Framework `declarative-agents/workflow-samples/`, CrewAI `agents.yaml`), (d) LLM-orchestrator-with-ledger (Magentic-One `_prompts.py`), (e) markdown-procedural (BMAD, ceos-agents, wshobson). Distribution: hardcoded markdown procedural dominant in Claude Code plugin space; code-defined graph dominant in Python framework space; declarative YAML rising; LLM-as-orchestrator ~3 instances among 17 reviewed; no-pipeline single-agent ~25% (smolagents, DSPy ReAct, OpenHands codeact, Cline).
- **[community, agent-4]** Pattern w/ matrix 17 frameworks: ceos-agents (3 hardcoded markdown pipelines ~600 řádků), BMAD (50+ declarative workflows v6 compiled YAML→markdown, per-stage approval), superpowers (skill-composed, TDD as gate), LangGraph (state machine/DAG, programmable interrupts), CrewAI (sequential/hierarchical, optional approval), MS Agent Framework v1.0 (graph + sequential/concurrent/handoff/group chat), OpenHands (SWE-agent loop, configurable approval), Cline (ReAct in IDE, **approval per file/command every step**), Cursor (Composer + chat, inline diff approval), GitHub Spec Kit (constitution-driven SDD), DSPy (compiled from declarative Python signatures). **Markdown + YAML-frontmatter dominant in plugin ecosystem; code (Python/TS) dominant in orchestration framework ecosystem.**
- **[vendor, agent-5]** Named patterns per vendor: Anthropic = 6 canonical (Prompt chaining, Routing, Parallelization, Orchestrator-workers, Evaluator-optimizer, Autonomous agents); OpenAI = 4 (Single-agent loop, Manager/agents-as-tools, Decentralized handoffs, Triage); Google ADK = 5 (Sequential, Parallel, Loop, Coordinator/Dispatcher, Hierarchical Task Decomposition); Microsoft = 5 (Sequential, Concurrent, Handoff, Group Chat, Magentic-One). Convergence on 3 primitives (sequential, parallel, routing/handoff). Anthropic taxonomy: workflows = predefined patterns; agents = dynamic LLM-driven control.

**Controversies / open questions:**
- ceos-agents "scaffolded execution" (sequential markdown stages) je recognized pattern v Martinez & Franch taxonomy — academia-defensible.
- **No vendor publishes pipeline shape comparison benchmarks**; choice is qualitative.

---

### Q5b — Migration ROI evidence

**Cross-lens consensus:** **Toto je nejweakest evidence area.** Žádné peer-reviewed case studies markdown→declarative migration pro agent frameworks. Closest direct evidence = single PayPal case study (vendor-internal, single org). Production-observable migrations (LangGraph 1.0 default, MS Agent Framework, Cursor 1.x→2.0, Devin 1.x→2.0) **bez published ROI numbers**. Pattern: when vendor migrates framework, **primitives survive but surface changes**; framing = "production hardening," ne "redesign." Žádný vendor publikuje hard ROI numbers (success rate before/after, latency, etc.).

**Lens-specific evidence:**

- **[academic, agent-1]** **Žádný academic study comparing markdown→declarative agent migrations.** Closest direct: Daunis (PayPal, arxiv 2512.19769, Nov 2025) — imperative→declarative DSL: **67% reduction dev time (48→16h), 76% faster modifications (8.5→2.0h), 74% fewer LOC (220 vs 850), success 78%→89%, steps -30%, P95 latency 185ms vs 240ms baseline.** **Caveat: single industry case study, single org.** TF→JAX migration agent (arxiv 2603.27296): "fraction of the time" — vague. Open Agent Spec (arxiv 2510.04173): adapter coverage no migration ROI. Wang et al. (arxiv 2512.01939): *"96% of top-starred projects adopt multiple frameworks, highlighting that a single framework can no longer meet complex needs"* → migration costs absorbed by multi-framework composition, ne single-framework switches. Per-framework migration pain documented: LangChain/AutoGen highest maintenance; CrewAI strict version pinning conflicts.
- **[production, agent-2]** LangGraph 1.0 (late 2025) became default runtime for all LangChain agents (largest production-observable migration; no public cost numbers). MS Agent Framework 1.0 (April 2026) successor to AutoGen + Semantic Kernel: *"enterprise-ready successor"* — Microsoft converged 2 competing products. Cursor 1.x→2.0 (Nov 2025): single-agent IDE assist → multi-agent worktree; "4× faster" claim. Devin 1.x→2.0 (April 2025): **pricing $500→$20/mo (25× reduction)**. Sourcegraph Cody → Amp (July 2025): killed mature product, bet company on agentic architecture. **Cognition specifically refactored Edit Apply Models away from compound to single-model: *"miscommunication compounds; subagents misinterpret tasks without full context, leading to incompatible outputs that are difficult to reconcile."*** Adjacent: Jenkins → GH Actions / Tekton — declarative YAML wins for standard cases, Turing tarpit for complex logic; no quantified ROI 2025.
- **[OSS code, agent-3]** BMAD-METHOD v3→v5 migration (~mid-2025): single agent .md file → SKILL.md + customize.toml + module.yaml. ROI signal: stars 15k (v3) → 45.7k (v5) = +200% over 12 months (correlation, not causation; README cites *"easier to customize without forking"*). AutoGen → MS Agent Framework: Microsoft created `microsoft/agent-framework` (2025-04-28, 9.8k★) parallel; AutoGen 57k★ vs AF 9.8k★ but **AF averages 193 commits/30d vs autogen 1**. CrewAI YAML adoption: default CLI scaffold since v0.30+ (mid-2024); backwards-compatible (Python + YAML coexist); anecdotal blog ROI (DataCamp, Medium 2025): *"easier for non-developers"*; **no quantified data published**. LangGraph: NO migration to declarative; pure Python `StateGraph()` zachováno; position *"graphs are too expressive for YAML."*
- **[community, agent-4]** MindsDB → PydanticAI from LangChain: **10x performance improvement** (single-vendor self-report). OpenCode displacement of Cline + OpenHands + Aider in 6 months (Jan-April 2026): driven by Claude Max subscription routing (config feature, NE architecture). TELUS case (Anthropic 2026 trends): *"13,000 custom AI solutions, 30% faster engineering code shipping, 500,000 hours saved"* (vendor data, scope unclear). **LangChain → raw SDKs migration: *"This migration wave away from LangChain has been mostly invisible in public discourse in 2026"*** (Ravoid). Lessons: (1) migration succeeds when triggered by concrete pain (token cost, vendor lock-in, debugging), NE elegance; (2) BMAD v6 GH issues #675, #1062 document upgrade-path failures (alpha.12→alpha.14 broke installations) = hidden cost of declarative DSL evolution; (3) **CI/CD analogue (Jenkins→Tekton/Argo) shows YAML can become spaghetti at scale** — *"Tekton is a powerful collection of Kubernetes CRDs and you can cook a beautiful YAML spaghetti out of it"* (container-solutions); *"in general, if you really don't have to, Tekton as CI/CD is not recommended"* (mkdev.me). **Foundational warning for ceos-agents v8.0.0.**
- **[vendor, agent-5]** OpenAI Swarm → Agents SDK (March 2025): *"Migration was breaking — primitives kept (handoffs, agent objects) but APIs changed."* No official ROI. AutoGen + Semantic Kernel → MS Agent Framework (Oct 2025 preview, Q4 2025 GA): both upstreams remain; **2 official migration guides published**; Microsoft framing: *"Semantic Kernel users replace Kernel and plugin patterns with the Agent and Tool abstractions, while AutoGen users map AssistantAgent to ChatAgent, benefiting from checkpointing, simplified messaging, stronger durability."* GitHub Copilot Workspace → Coding Agent (April 2024 launch → May 30, 2025 sunset → Sep 2025 GA): *"GitHub took everything learned from Copilot Workspace — sub-agent architecture, issue-to-PR workflow, async execution model — and rebuilt it as Copilot Coding Agent."* **Vendor pattern: primitives survive, surface changes.** Migration framed as "production hardening" ne "redesign."

**Controversies / open questions:**
- agent-1 explicit "no academic precedent for ceos-agents migration ROI"; agent-2 explicit "no quantified ROI numbers found for hardcoded markdown → declarative pipeline migrations specifically"; agent-3 explicit "no public ROI metrics for migration in any project's source/docs"; agent-4 cites only single-vendor self-reports; agent-5 *"no vendor publishes hard ROI numbers."* **5/5 lenses converge on absence of robust evidence.**
- **Practical implication:** prototype-and-measure je more honest than citing academic ROI number (agent-1 explicit).

---

### Q5c — LLM-as-config-interpreter reliability

**Cross-lens consensus:** **Format adherence je solved (constrained decoding ≈100%); content correctness NENI** (still hallucinates). LLM-as-pure-orchestrator (free-form ReAct prose, vague config) je **weakest link** v agent reliability data; production frameworks responded with deterministic state machines + structured output validation + 2-loop bookkeeping. CrewAI 3× managerial overhead vs LangChain. Multi-agent failure rates 41–86.7% v production když orchestration unstructured. **Convergent recommendation:** declarative for structure + imperative escape hatch + structured output gates.

**Lens-specific evidence:**

- **[academic, agent-1]** JSONSchemaBench (arxiv 2501.10868, Jan 2025): ~10,000 real-world JSON schemas, *"constrained decoding is dominant technology for enforcing structured outputs."* StructEval (arxiv 2505.20139, May 2025): 18 formats, 44 task types. RL-Struct (arxiv 2512.00319, Dec 2025): **89.7% structural accuracy, 92.1% validity on complex JSON tasks.** STED (arxiv 2512.23712, Dec 2025): *"frontier models still produce inconsistent structured outputs across runs even when individually valid"* — under-reported. Natural Language Tools (arxiv 2510.14453, Oct 2025): *"structured formats in tool calling may come with significant drawbacks, as structured formats require models to simultaneously handle multiple competing demands"* → **LLM-as-prose-interpreter (markdown) může být more reliable than LLM-as-JSON-config-interpreter** for some agent control flows. AgentArch (arxiv 2509.10769): *"Function calling outperformed ReAct across most models. Hallucinations for all models (except GPT-4o) were found exclusively under ReAct settings."* DSPy / "Is It Time To Treat Prompts As Code?" (arxiv 2507.03620): routing accuracy **90.47% after CustomMIPROv2 optimization**.
- **[production, agent-2]** LangGraph explicit production positioning: *"Models agent workflows as directed graphs of nodes... fine-grained control"* — chose **deterministic state machines over LLM dispatch**. Anthropic 2026: *"Negative examples are extremely important — they define the boundaries... ensure it doesn't over-trigger"* → LLMs over-trigger when given vague config. Cognition (running Devin 18 months at scale): *"Subagents misinterpret tasks without full context"* — **LLM dispatch reliability degrades sharply when dispatched agent doesn't have full upstream context.** Microsoft Magentic-One: **Orchestrator runs 2 loops** (outer task ledger, inner progress ledger) — *"specifically because LLM dispatch alone is unreliable."* arXiv 2509.18970 (Sept 2025) "LLM-based Agents Suffer from Hallucinations": **18 triggering causes**, task dispatch is one major. DeepEval 2025 changelog: *"safer fallbacks when JSON is invalid or malformed"* — production tooling response. **CrewAI vs LangChain dispatch overhead: CrewAI exhibits managerial overhead, ~3× tokens of LangChain, ~3× longer even for single tool call.**
- **[OSS code, agent-3]** **Deterministic state machine (LLM doesn't pick next stage):** LangGraph (`StateGraph.add_edge`), CrewAI Flow (`@listen("event_name")` deterministic), MS Agent Framework (`kind: ConditionGroup` formula expressions, NE LLM), ceos-agents (markdown-prose stages, orchestrating skill follows fixed sequence). **LLM-as-orchestrator (LLM picks next stage):** Magentic-One (`ORCHESTRATOR_PROGRESS_LEDGER_PROMPT`, *"Who should speak next?"* JSON output) — paper reports **~92% correct dispatch on benchmarks**, hallucinates 5–10%; Roo Code orchestrator mode (pure LLM-driven, no deterministic constraint, anecdotal user reports of "wrong mode dispatched" GH #1247, #1389); BMAD persona menu (user-driven hybrid); OpenAI Agents SDK Handoff (LLM picks via tool-call; explicit *"model can refuse / hallucinate handoff"* in `_validate_handoffs`). **Practical signal: frameworks ship BOTH modes — Magentic-One uses LLM ledger BUT validates with structured output schema (Pydantic LedgerEntry).**
- **[community, agent-4]** **Most cited line in 2026 production writeups:** *"A YAML file with condition, loop, and stdin piping is infinitely more reliable than telling an LLM 'if the review is negative, go back to step 2, but only up to 3 times'"* (Augment Code). Empirical: **multi-agent LLM systems fail 41–86.7% in production** when orchestration unstructured (Augment Code); specification ambiguity + unstructured coordination = **79% production breakdowns**. *"70% of production agents rely on prompting off-the-shelf models, 74% depend primarily on human evaluation"* (arxiv 2512.04123). *"Code-driven workflows are being used as a 'solution of frequent resort,' progressive enhancements where LLM prompts/tools aren't reliable or quick enough"* (lethain.com). *"LLMs aren't really made to be predictable and reliable, but regular code is"* (Reddit cited siliconflow). Anthropic: *"Tools should be self-contained, robust to error, extremely clear with respect to intended use. Bloated tool sets and ambiguous decision points are common failure modes."*
- **[vendor, agent-5]** OpenAI Structured Outputs (Aug 2024): **gpt-4o-2024-08-06 scores perfect 100% on complex JSON schema following vs <40% gpt-4-0613.** *"Setting strict to true ensures function calls reliably adhere to schema, instead of being best effort. OpenAI recommends always enabling strict mode."* Anthropic Structured Outputs (Nov 14, 2025, public beta Sonnet 4.5/Opus 4.1, beta header `anthropic-beta: structured-outputs-2025-11-13`): *"compile your JSON schema into a grammar and actively restrict token generation during inference. The model literally cannot produce tokens that would violate your schema."* **Anthropic caveat:** *"adheres to specified format, not that any output will be 100% accurate. Models can and may still hallucinate occasionally."* **Vendor consensus: format adherence ≈100%, content correctness NOT.** For control flow: structured outputs reliably produce valid stage names/agent names; whether they pick *right* one is still prompt-engineering. Anthropic harness post (Nov 2025) explicitly uses "Feature List (JSON)" + "Progress File" + "Git History" as deterministic state, LLM only deciding *what to do next*, ne *which agent*.

**Controversies / open questions:**
- **Resolution across lenses:** structured outputs solve schema; behavior selection still benefits from deterministic dispatch when stakes are high.
- **Practical implication for ceos-agents:** current pattern (markdown-prose agent definitions + Bash deterministic dispatch + state.json structured writer) **sits in safe middle ground** — LLM-driven decisions are bounded; meta-gen architecture by introduced LLM-as-config-interpreter step that 2025 evidence shows is weakest link.

---

### Q5d — Public release expectations

**Cross-lens consensus:** **Markdown overlay v repo root je production-validated standard** for plugin-distributed agent customization. AGENTS.md adoptováno >60k repos, Linux Foundation steward (AAIF), adopted by every major product agent. 100% top-15 Claude Code pluginů použivá markdown jako primary instruction surface, YAML pouze frontmatter / metadata. **Žádný production-shipping coding-agent product kde uživatelé customize behavior primarily through YAML pipeline definitions.** Per-project full duplication = community-rejected anti-pattern. Meta-gen = no precedent.

**Note:** Tato otázka je z academic angle (agent-1) explicitně **largely outside scope** — *"academia studies architectures, performance, reliability — not user expectations of plugin customization mechanisms."* Heavy weight na agent-2/3/4/5.

**Lens-specific evidence:**

- **[academic, agent-1]** **Out-of-scope honestly disclosed.** Closest adjacency: Wang et al. arxiv 2512.01939 — *"96% of top-starred projects adopt multiple frameworks"* → users expect composability over single-framework lock-in; *"Developers should prioritize ecosystem maturity and maintenance activity over GitHub stars."* Common failure modes: Logic 25.6%, performance 25%, version conflicts 23.5%, tool integration 14%. OpenAI Agents SDK March 2025 minimalist 4-primitive design (Agents, Handoffs, Guardrails, Sessions) signals industry consensus: **fewer primitives, simpler mental models.** AgentScope 1.0 (arxiv 2508.16279) implements *"non-invasive customization"* and automated state persistence as design goals.
- **[production, agent-2]** **AGENTS.md is the production-validated standard for plugin-distributed agent customization as of 2026:** 60,000+ repositories adopt; adopted by every major product agent (Cursor, Codex, Amp, Devin, Factory, Gemini CLI, Copilot, Jules, VS Code); Linux Foundation steward; *"Plain markdown without metadata or complex configurations"*; hierarchical lookup closest-to-edited-file wins; explicit chat prompts override everything. Per-product matrix: Cursor `.cursor/rules/*.md` + AGENTS.md; Claude Code CLAUDE.md + AGENTS.md + `.claude/agents/*.md` + `.claude/skills/SKILL.md`; Codex CLI AGENTS.md hierarchical closest-wins + Codex Subagents inherit-with-override; Copilot AGENTS.md + `.github/copilot-instructions.md`; Aider `.aider.conf.yml` + CONVENTIONS.md (YAML config + Markdown context); Devin Knowledge base + AGENTS.md; BMAD YAML workflows + agent markdown (hybrid); CrewAI YAML role definitions; LangGraph Python; Mastra TypeScript. **Critical observation: there is NO production-shipping coding-agent product where users customize behavior primarily through YAML pipeline definitions.** YAML appears in CrewAI (agent role defs only, pipelines still Python crew composition); BMAD workflows (per-task YAML, but overall framework markdown-driven); Aider config (settings, ne pipeline).
- **[OSS code, agent-3]** Top Claude Code plugin repos by stars: anthropics/skills (canonical reference, SKILL.md per skill, frontmatter `name + description + license`, optional `reference/` and `scripts/` subdirs, no per-project config); BMAD-METHOD (45.7k★, SKILL.md + customize.toml + steps/*.md, **TOML overlay with explicit merge rules**); wshobson/agents (one .md per agent, frontmatter, NO customization fork-to-customize); ceos-agents (markdown agents + skills + Automation Config in CLAUDE.md, `Agent Overrides` directory append-to-prompt). **All top plugins use markdown.** Customization mechanisms diverge: Anthropic/wshobson = NO customization (re-fork); BMAD = sophisticated `customize.toml` overlay with merge semantics (`bmad-agent-pm/customize.toml:13-15`: *"scalars: override wins • arrays: append • arrays-of-tables with code/id: replace matching items, append new ones"*); ceos-agents = `Agent Overrides` directory + Automation Config CLAUDE.md. **BMAD's overlay pattern is the most sophisticated in the ecosystem — and it ships in 45.7k-star Claude Code plugin = strong evidence Generic+Overlay validated at scale in exactly the deployment context ceos-agents targets.** **NO Claude Code plugin uses meta-gen.** Per-project customization is BMAD-style append/merge OR fork-and-edit — no third pattern observed.
- **[community, agent-4] (PRIMARY contributor pro Q5d)** Direct evidence z `quemsah/awesome-claude-plugins` top 15: superpowers (165k★+), anthropics/skills (123k★+), andrej-karpathy-skills (82k★+, **CLAUDE.md alone**), ui-ux-pro-max-skill (69k★+), BMAD-METHOD (45k★+). **100% top-15 plugins use markdown as primary customization surface; YAML only for frontmatter metadata or structured config alongside (never as primary instruction language).** Layered overrides pattern (Anthropic's own): *"Project subagents take precedence over global; project-specific override global on naming conflicts."* 4-scope hierarchy: **Managed > CLI args > Local > Project > User** (codesignal). What users explicitly want changed without forking: (1) **add domain-specific instructions to existing agents** (exact ceos-agents `Agent Overrides` use case); (2) **override model assignment per agent** = #1 most-requested override (GH issue #37823); (3) **add hooks (pre/post)** rated #1 use case in aitmpl.com 39+ Claude Code Hooks; (4) **skip stages** (ceos-agents has Pipeline Profiles); (5) **inject custom agents into pipeline** (ceos-agents supports). Hooks: **shell first, Python second** — *"Hooks are user-defined shell commands that execute at specific points in Claude Code's lifecycle. Provide deterministic control."* Top examples: Prettier on edit, block dangerous shell, audio notifications, run tests after change. **Anti-pattern users explicitly reject: forking plugin to change anything** ("How the hell do I use my forked npm package" pain universal). **Markdown wins for instructions. YAML wins for metadata/config. JSON loses everywhere except machine-to-machine.** HN tropes: *"Why are we templating YAML?"*, *"The Yaml document from hell"*. BMAD v6 critique: *"50+ workflows, 19+ specialized agents, step-file architecture, document sharding, web bundles"* perceived YAML-heavy and brittle.
- **[vendor, agent-5]** **Vendor divergence on customization philosophy:** Anthropic = markdown + YAML frontmatter (file-based, all markdown-with-frontmatter; Claude Code plugin spec ships with this contract baked in); OpenAI = Python code (Agent class, instructions string, tool decorators; no file-based plugin model); Google ADK = Python code with hierarchical composition; MS Agent Framework = code (Python/.NET) + middleware patterns; Meta Llama Stack = YAML "distribution" files wiring providers. **ceos-agents' markdown-only approach is closest to and validated by Anthropic's blueprint.** Strongest vendor-validated signal: Anthropic explicitly ships markdown+YAML frontmatter as customization mechanism for plugins, subagents, skills.

**Controversies / open questions:**
- All 4 non-academic lenses converge: **Generic+overlay markdown = community-validated.** Per-project = rejected. Meta-gen = no precedent. Tato Q má jasné cross-lens consensus.

---

### Q6 — Human-in-the-loop placement

**Cross-lens consensus:** **Vendor consensus na event-driven gates, NIKOLI per-stage gates** (Anthropic, OpenAI, Microsoft konvergují). Production split mezi async-autonomous (Devin 200min) a synchronous-per-action (Cursor) — oba shipped, oba mají platící uživatele; výběr je HITL placement, ne capability. Akademická plan-then-execute (security-design papers) maps na ceos-agents triage+code-analyst → fixer+reviewer. Stack Overflow 2025: 46% developerů nedůvěřuje AI accuracy → **více transparency/control/inspectability**. ceos-agents strategic-gates (5 gates: triage, AC checkpoint, acceptance-gate, pre-publish) maps na L3/L4 v Feng et al. taxonomy + WorkOS "Confidence-Based Routing" — **community-aligned.**

**Lens-specific evidence:**

- **[academic, agent-1]** Feng/McDonald/Zhang "Levels of Autonomy" (UW, arxiv 2506.12469, June 2025): 5-level framework (L1 Operator → L2 Collaborator → L3 Consultant → L4 Approver → L5 Observer). *"Risks of L5 may outweigh benefits in most cases."* L4 recommended pro *"tasks with high amounts of lower-stakes decision-making."* **No empirical user-trust data — conceptual framework only.** "Optimizing Agent Planning for Security and Autonomy" (arxiv 2602.11416): autonomy metrics quantifying fraction consequential actions agent can execute without HITL while preserving security. "Measuring AI Agent Autonomy" (arxiv 2502.15212): operationalizes 3 classes (in-the-loop, on-the-loop, off-the-loop) + code-inspection methodology. The 2025 AI Agent Index (arxiv 2602.17753): empirical census 6 dimensions including approval requirements. AI Agent Systems 2026 (arxiv 2601.01743): *"emerging best practice is to explicitly separate planning from execution... supporting human-in-the-loop approval for high-impact steps."* **Design Patterns for Securing LLM Agents against Prompt Injections (arxiv 2506.08837, June 2025):** plan-then-execute pattern (agent forms fixed plan upfront; HITL reviews plan; execution proceeds without further LLM-driven decisions) — **reduces attack surface and HITL burden simultaneously.**
- **[production, agent-2]** Spectrum: zero gates / autonomous (Devin 2.0 async 200 min, Replit Agent 3 200 min, Sweep tag → PR); strategic gates (GitHub Copilot Workspace per-step gate after spec/plan/implementation; BMAD per-stage; ceos-agents 5 gates); per-stage / per-action high oversight (Cursor synchronous accept/reject per edit, Aider per-edit confirmation, Claude Code 7 permission modes ML-classifier, Roo Code per-step). Confidence-based / event-driven (emerging): WorkOS HITL patterns analysis (2025) — **5 core HITL patterns covering 90%+ real-world use cases: Approval Gate, Escalation Ladder, Confidence-Based Routing, Collaborative Drafting, Audit Trail with Lazy Review.** **Production-observed costs:** Devin 13.86% end-to-end vs Goldman 3-4× productivity; defect rate 1.5–2× higher than senior dev; PRs avg 1.5–2.3 review cycles → autonomous mode frontloads time saved into backloaded review. Goldman: 25-45 min saved per task minus 10-20 min overhead → 15-30 min net. **Task-conditional placement:** routine bug fix → async (Devin pattern) wins; spec-driven feature work → strategic gates wins; architectural decision → per-stage HITL wins. ceos-agents conditional acceptance-gate (AC ≥3 or complexity ≥M) is **precisely the "Confidence-Based Routing" WorkOS pattern.**
- **[OSS code, agent-3]** Q5a matrix: HITL primitives napříč frameworks: ceos-agents NEEDS_CLARIFICATION fence + `resume-ticket --clarification`; LangGraph `interrupt()` (`libs/prebuilt/langgraph/prebuilt/interrupt.py:1-105`); MS Agent Framework `kind: SendActivity` → user → `OnConversationContinue`; CrewAI Flow `@human_feedback` decorator (`lib/crewai/src/crewai/flow/human_feedback.py`); Strands `Interrupt` (`src/strands/interrupt.py`); OpenAI Agents SDK `input_guardrails`/`output_guardrails`; Cline `ask_followup_question` tool. **All major 2026 frameworks have first-class HITL primitive.** ceos-agents NEEDS_CLARIFICATION pause is conceptually identical but expressed via fenced markdown signal — **less ergonomic but functionally equivalent.**
- **[community, agent-4]** **2026 consensus shifted toward "developer-in-the-loop" over "fully autonomous"** after Devin underwhelming demos. *"Devin tends to push forward with impossible tasks rather than escalate. Aider preferred for Git-grounded, verifiable edits over fully autonomous"* (Augment Code). *"For most developers and teams, human-in-the-loop approaches provide better results at fraction of cost"* (same). Empirical anchor: arxiv 2512.04123 — **68% production agents execute at most 10 steps before human intervention; 74% rely primarily on human evaluation.** Cline "approve every step" praised: *"human-approval-every-step approach is something some developers genuinely prefer over cursor's 'yolo mode'"* (docs.cline.bot); Cline added "Auto Approve" because every-step slowed iteration too much. **Aider production darling 2026:** 39K★, 4.1M installs, 15B tokens/week — *"production volume is on HITL side"*. Event-driven gate (gate when confidence < threshold): academically endorsed (Cleanlab, Credo paper arxiv 2604.14401) but **no production framework in top-20 implements as primary mechanism** — confidence calibration in LLMs unreliable enough that community hasn't bet.
- **[vendor, agent-5] (canonical guidance)** **Strong vendor consensus: event-driven gates, NOT per-stage gates.** Anthropic Claude Code permissions: 6 modes (`default`, `acceptEdits`, `auto`, `dontAsk`, `bypassPermissions`, `plan`); `AskUserQuestion` tool *"ask user clarifying questions with multiple choice options"* — explicit agent-driven HITL primitive. "Building Effective Agents" Dec 2024: *"pause for human feedback at checkpoints or when encountering blockers"* — canonical event-driven framing. OpenAI: per-tool-call gating via `needsApproval` (boolean or async function), `RunToolApprovalItem` if approval required and no decision stored; resolution `result.state.approve/reject` with `alwaysApprove/alwaysReject` toggles — **per-tool-call, agent-event-driven (only when approval-required tool invoked, not per-stage)**. Microsoft Agent Framework Magentic execution: 8 phases including (2) **Optional Plan Review**, (6) **Stall Detection (auto-replan with optional human review)** — HITL is **conditional**, not per-stage. **Vendor implication for ceos-agents sub-projekt B:** current `--yolo` (zero gates) and architecture profile defaults are vendor-aligned; per-stage gates would be **anti-pattern**; event-driven gates (e.g., "pause when reviewer reports HIGH issue with no clear fix" or "pause when fixer iteration count >3") would be vendor-blessed.

**Controversies / open questions:**
- Devin (autonomous overnight) vs Aider (confirm-each) — community verdict 2026: **Aider production choice; Devin demo choice** (Augment Code).
- ceos-agents has **no confidence-based gate inside fixer↔reviewer loop** (production gap per agent-2); Aider/Cursor/Claude Code all have this. v8.0.0 candidate addition.
- HITL gate placement empirical user-trust data is **major academic gap** (agent-1).

---

### Q7 — Sub-agent dispatch vs in-agent tool-use

**Cross-lens consensus:** **Hybrid je source-code reality** (frameworks ship both modes). **Microservices analogy holds** in vocabulary and failure modes. Dispatch overhead je substantial: 7× tokens (Anthropic plan-heavy), 15× multi-agent vs chat (Anthropic), 3× CrewAI manager vs LangChain. **68% (32/47) analyzed production multi-agent deployments would have done equally well as single agents** ($47k/mo orchestration vs $22.7k single GPT-5.2, 2.1pp accuracy delta — Iterathon). When dispatch wins: read tasks (research/analysis), independent domain split, cost-routing (Opus orch + Sonnet workers), reviewer/validator separation. When in-agent wins: write tasks, tight iteration (test→fix→test), context preservation matters. **ceos-agents 21 agents = at outer edge of production precedent** — orchestrator-to-fixer dispatch justified; fixer-to-reproducer-to-browser-verifier-to-test-engineer chain over-decomposed.

**Lens-specific evidence:**

- **[academic, agent-1]** Anthropic Claude Code subagents docs: *"Subagents useful for side work you want to keep out of main session, like repo exploration, docs lookup, test runs, result validation."* But: *"not a good fit for every task. Setup, handoff, context overhead. For small edits, tightly coupled work, tasks needing constant back-and-forth, makes more sense to stay in main conversation."* Agent teams (peer coordination) *"can use about 7× more tokens in plan-heavy workflows."* AOrchestra (arxiv 2602.03786): *"Multi-agent collaboration often incurs substantial coordination overhead and provides limited control over context routing, leading to either noisy over-sharing or harmful omission of critical information."* Dynamic dispatch achieves **16.28% relative improvement against strongest baseline.** Kim et al. (arxiv 2512.08296): *"Hybrid systems show 5-15% coordination overhead, additional messages diminishing returns. Tool-coordination trade-off arises because multi-agent fragments per-agent token budget."* Yin et al. (arxiv 2511.00872): planning agents consume **65–67% of tokens v multi-agent SE systems**. ToolOrchestra (arxiv 2604.17009): lightweight orchestrator decides between tool calls and sub-agent dispatch dynamically — *"task-dependent, not architectural."* **Microservices-vs-monolith analogy: dispatch when work isolated and reused; tool-use when context coupling high.**
- **[production, agent-2]** **Anthropic: 4× tokens single agent vs chat, 15× multi-agent vs chat.** Justified by 90.2% performance lift on research tasks. CrewAI 3× managerial overhead. **One reported deployment: $47k/mo multi-agent vs $22.7k single agent for 2.1pp accuracy delta. 68% analyzed deployments would have done equally well as single agents.** When dispatch wins: read tasks (Anthropic research parallelization), independent domain split (frontend/backend/db), cost-routing (Opus orchestrator + Sonnet workers — *"common pattern: run main session on Opus for complex reasoning while sub-agents handle focused tasks on Sonnet"*). When in-agent wins: write tasks (Cognition explicit), tight iteration (Aider/Cursor single Coder loops), frontier model + minimal scaffold (mini-SWE-agent + Opus 4.5 = 79.2% with bash only). **Production parallels for ceos-agents:** Anthropic research = Lead + 3-5 parallel sub-agents (NE Lead + 5 sequential); Devin compound = 4 components; BMAD = 7-9 roles but most workflows touch 3-4. ceos-agents 21 agents per pipeline = outer edge; consolidation toward 8-12 matches median.
- **[OSS code, agent-3]** **Frameworks with first-class sub-agent dispatch:** OpenAI Agents SDK Handoff (`Handoff` dataclass, `src/agents/handoffs/__init__.py:94`; *"Handoffs are sub-agents that the agent can delegate to. Allows for separation of concerns and modularity"* — explicit microservices vocabulary in source); Roo Code `new_task` tool (orchestrator mode `packages/types/src/mode.ts:218-227`); CrewAI Manager Agent; Strands SDK Graph (each node Agent or sub-Graph, supports nested); MetaGPT `_watch()` pub/sub; Magentic-One JSON ledger. **Frameworks with in-agent tool-use only:** smolagents (single agent, Python REPL), DSPy ReAct (single, tools list), Cline (single-agent with tools), Aider (pair-programming). **When dispatch wins (source-code evidence):** (1) clear orthogonal domain handoffs (OpenAI triage → spanish/english); (2) reviewer/validator pattern (ceos-agents fixer↔reviewer loop, distinct prompts cannot share one agent); (3) multi-stage stateful checkpoints; (4) **cost optimization** (ceos-agents haiku for publisher, opus for fixer/reviewer — per-agent model selection saves significant tokens). **When in-agent wins:** single coherent task no handoff boundary; latency-sensitive (sub-agent dispatch 1-2 turn overhead per handoff full context serialize + new system prompt); context preservation matters (re-passing triage output, code-analyst report each time vs one conversation).
- **[community, agent-4]** Sub-otázka necovered explicitně, ale [agent-4 trends]: 26% all requests subagent calls (MindStudio 2026) = coordination overhead is structural cost of narrow specialization.
- **[vendor, agent-5]** **Anthropic explicit pro-subagent:** *"Subagents enable parallelization and help manage context: subagents use own isolated context windows, send only relevant information back to orchestrator."* *"Use one when side task would flood main conversation with search results, logs, file contents you won't reference again."* Caveats: *"start fresh, need time to gather context, can't spawn other subagents."* *"Setup, handoff, context overhead."* OpenAI **cleanest decision rule:** handoff = transfer control to specialist (peer agent owns conversation); `Agent.as_tool(parameters=...)` = nested specialist without transferring (*"if you want structured input for nested specialist without transferring conversation"*). Google ADK: hierarchical `sub_agents=[…]` only blessed pattern.

**Controversies / open questions:**
- **Cognition (write tasks) vs Anthropic (read tasks) split** = **resolved by task type**, not ideology.
- ceos-agents currently maps to OpenAI's "Agent.as_tool" pattern (skill is orchestrator, agents are nested specialists) — **vendor-blessed**.

---

## C3 — Configuration philosophy

### Q8 — Generic+overlay vs per-project vs meta-gen

**Cross-lens consensus:** **Generic+overlay je 5/5 lens-validated dominant production pattern** for plugin-style ecosystems. Anthropic 5-tier subagent priority + BMAD `customize.toml` 3-tier merge + Cursor `.cursor/rules` + Codex AGENTS.md hierarchical = **all top-3 production coding agents adopt this**. Per-project = community-rejected (forces forking-equivalent). **Meta-gen = 0 production deployments at primary-architecture scale found** (5/5 lenses converge on absence). Update flow: generic+overlay = clean (plugin owns core, user owns overlay); per-project = fragmented (each user version on independent track); meta-gen = unresolved (no production solution to "regen vs preserve customization" conflict).

**Lens-specific evidence:**

- **[academic, agent-1]** Q3 evidence applies. **Meta-gen specific:** ADAS (cited in arxiv 2601.22037) — meta-agents automatically design agent architectures via code generation; MetaGen (arxiv 2601.19290) — *"task mismatch arises because task granularity, tool preferences, error modes vary widely, while fixed role set is brittle under distribution shift"*; MetaSynth (arxiv 2504.12563) — meta-prompting orchestrates expert LLMs; Meta-Prompting Protocol (arxiv 2512.15053, Dec 2025) — three-agent Adversarial Trinity (Generator/Auditor/Optimizer). **Honest finding: meta-gen at agent-architecture-generation level je emerging research, NIKOLI established practice. Not yet shown to outperform well-tuned static architectures on standard benchmarks.** Verdict: **Meta-gen je highest-risk, lowest-evidence option. Generic+overlay has strongest direct academic support.**
- **[production, agent-2]** Production deployment evidence: Generic+overlay = Cursor (.cursor/rules + AGENTS.md), Claude Code (CLAUDE.md + .claude/agents), Codex (AGENTS.md inheritance) — **all three top-3 production coding agents. Standard adopted by 60k+ repos.** Per-project (full set) = wshobson/agents (community), bespoke enterprise — **community pattern; not productized at scale**. Meta-gen = Replit Agent 3 (feature, NIKOLI architecture), MetaAgent (research), Hyperagents (research) — **NO production deployment of meta-gen as primary architecture found.** Onboarding cost: Cursor / Claude Code ~5 min; BMAD documented "time-intensive"; CrewAI "fastest setup but production teams migrate to LangGraph for state management." **Recommendation backed by production evidence: Keep generic+overlay. Add Codex-style typed inheritance for overlay (closest-shipping inheritance model). Skip meta-gen until research matures into production deployments.**
- **[OSS code, agent-3]** Q3 evidence applies. **Meta-gen specific source-code finding:** Mastra `agent-builder` package = experimental skeleton, NIKOLI meta-gen implementation; AutoGen Studio = UI, NIKOLI LLM-driven generation; CrewAI agent builder = CLI scaffolding from templates. **No framework reviewed implements meta-gen in production.** BMAD `_bmad/scripts/resolve_customization.py` = deterministic resolver, NIKOLI LLM-driven generator. **Implication: meta-gen has no source-code precedent at scale.**
- **[community, agent-4]** Q3 evidence applies. **Verdict for v8.0.0:** Generic+overlay = aligned with 100% top-15 Claude plugins + Anthropic's own subagent override hierarchy + AGENTS.md / VS Code / Cline / Cursor patterns = **strongly preferred by community signal**. Per-project = forces forking-equivalent = **rejected**. Meta-gen = no community precedent at scale; meta-prompting research exists (DSPy, hyperagents) but no plugin ecosystem demonstrates it; high failure mode risk per Q5c LLM-dispatch reliability data = **uncertain — speculative**. *"Community has voted with their stars: Generic+overlay is the dominant, expected, validated pattern."*
- **[vendor, agent-5]** **Vendor positioning matrix:** Generic+overlay: Anthropic = **Explicit** (5-tier + append-to-prompt teammate pattern); OpenAI = Implicit (Python class instances customized per app); Google = Implicit (agent base class + override); Microsoft = Implicit (middleware layers); Meta = Explicit (distributions pattern YAML overlay over base API). Per-project: Anthropic supported via `.claude/agents/` but framed as overlay; OpenAI/Google/Microsoft = native (every app instantiates own); Meta = implicit per-deployment. **Meta-gen: not blessed by ANY major vendor. Closest is Anthropic `/agents` interactive Claude-generated agent setup; Magentic-One plans tasks dynamically but does NOT generate agent definitions.** **Synthesis: Meta-generation of agent definitions is NOT endorsed by any major vendor as of 2026-04. Generic+overlay is the most vendor-validated pattern. ceos-agents implication: Generic+overlay is the only vendor-validated route to "ship a plugin and let projects customize." Per-project would mean abandoning plugin model. Meta-gen has no vendor blueprint and would be a frontier choice.**

**Controversies / open questions:**
- 5/5 lens consensus → **velmi nízká controversy.** ceos-agents v8.0.0 architectural decision má clear evidence for Generic+overlay path; per-project a meta-gen jsou high-risk relative to current state.
- Otevřená question: **Codex-style typed inheritance** (agent-2) jako evolution path pro Agent Overrides — production-validated extension k current overlay model.

---

### Q9 — Pipeline as config DSL expressiveness

**Cross-lens consensus:** **Convergent pattern: declarative for structure + imperative escape hatch.** Pure-YAML pipelines consistently hit ceiling at conditional logic and branching (CrewAI, BMAD pure, GitHub Actions pure). LangGraph blends both ("Declarative aspect — Graph structure uses declarative syntax. Imperative aspect — Node and edge logic remains standard Python/TypeScript code"). PayPal DSL paper (arxiv 2512.19769) documents 3 explicit trade-offs: Expressiveness vs Safety, Performance vs Flexibility, Abstraction vs Control. CI/CD analogues (Jenkins → GH Actions / Tekton / Argo) consistently show **Turing tarpit** when YAML forced to express complex logic. **Vendor blessing:** **Anthropic = NO control-flow DSL** (markdown prose for behavior, YAML only for config metadata); Microsoft + LangChain = typed graph DSL in code; OpenAI + Google + Meta = code-only no DSL. **Going to YAML pipeline DSL would be unprecedented in major-vendor docs as of 2026-04.**

**Lens-specific evidence:**

- **[academic, agent-1]** Daunis/PayPal (arxiv 2512.19769): **3 explicit trade-offs identified:**
  - *"Expressiveness vs. Safety: DSL intentionally restricts operations like unbounded recursion, arbitrary code execution to prevent malformed pipelines."*
  - *"Performance vs. Flexibility: Interpretation overhead adds 10-20ms latency."*
  - *"Abstraction vs. Control: Tool abstractions simplify common cases but require escape hatches (custom functions) for fine-grained LLM control."*
  - Documented failure modes: lack of native RL support, poor long-term memory across sessions, *"stack traces through nested pipelines and async tool calls obscure error origins."*
  Quantitative DSL benefits: 67% dev-time reduction, 74% LOC reduction, accuracy 78%→89%.
  Open Agent Specification (arxiv 2510.04173): declarative framework-agnostic spec; does **NOT push toward Turing-completeness** — academic preference is bounded DSL with escape hatches. Q9 framing of "graph-based vs Turing-complete" is **not represented in academic literature for agents**. Lessons from non-agent DSL history (Jenkins Jobs DSL, GH Actions, Argo Workflows): *"expressiveness creep into Turing-complete territory is consistently reported as maintenance liability"* — broad SE literature; no agent-specific peer-reviewed claim. **Sweet spot per academic evidence: YAML with conditional logic + escape hatches.** Avoid Turing-complete DSL until empirical evidence justifies.
- **[production, agent-2]** Production framework choices: CrewAI (YAML role definitions, sequential/hierarchical only — *"performs optimally with predictable, hierarchical processes rather than adaptive or real-time operations"*); BMAD (YAML workflows, branches/dependencies/handoffs, "time-intensive onboarding"); LangGraph (Python code declarative graph + imperative nodes, full Python expressiveness, **none — imperative escape hatch IS the design**); Temporal (code-first durable, Turing-complete host language, full power required); MS Agent Framework (hybrid declarative YAML agents + graph orchestration + middleware); Mastra (TypeScript code .then()/.branch()/.parallel(), full TS); GitHub Actions (YAML, increasingly complex with composite actions, **documented Turing tarpit**); Argo Workflows (YAML DAG steps/recursion, **documented Turing tarpit recursive YAML**). LangChain published recommendation: *"LangGraph blends both paradigms... When building applications with LLMs, we recommend finding the simplest solution possible, and only increasing complexity when needed."* Lessons: GH Actions reusable workflows + composite actions added *"precisely because simple YAML hit expressiveness ceilings"*; CrewAI flow control limits → many production teams migrate to LangGraph; Argo recursive YAML oft-cited "DSL became unmaintainable"; Jenkins Jobs DSL → Jenkinsfile (Groovy) escape from pure-declarative to pure-code is frequent escape valve. **Verdict: declarative for structure + imperative for logic (LangGraph, MS Agent Framework, Mastra). Pure-YAML pipelines consistently hit ceiling at conditional logic and branching.** For ceos-agents: production-validated shape = (1) declarative stage list (YAML or markdown), (2) imperative escape hatch (project-defined hooks bash/JS — current Hooks section is exactly this), (3) NO Turing-complete DSL.
- **[OSS code, agent-3]** Q5a + Q5c evidence applies. **Microsoft Agent Framework `kind: ConditionGroup`** evaluates expressions (`=Local.ServiceParameters.IsResolved`) — formula language, NIKOLI LLM (`declarative-agents/workflow-samples/CustomerSupport.yaml:30-44`). **Pattern:** structured DSL for control flow + LLM bounded to specific nodes.
- **[community, agent-4]** Q5b/Q5c evidence applies. **CI/CD analogue strongly cited as warning:** *"Tekton is a powerful collection of Kubernetes CRDs and you can cook a beautiful YAML spaghetti out of it"* (container-solutions); *"in general, if you really don't have to, Tekton as CI/CD is not recommended"* (mkdev.me). HN tropes "Why are we templating YAML?" + "Yaml document from hell" recur. **Foundational warning:** declarative pipeline config can degrade DX. DSPy: declarative compilation academically validated, but **requires Python runtime — incompatible with pure-markdown plugin philosophy.**
- **[vendor, agent-5]** Vendor split sharp: Anthropic = declarative config (YAML) + prose behavior (markdown), **NO control-flow DSL**; Microsoft + LangChain = typed graph DSL in code (Python/.NET); OpenAI + Google + Meta = code-only, no DSL. **Vendor consensus: nobody ships YAML-pipeline-DSL as recommended primary pattern.** Closest = MS Agent Framework graph workflows, but those are **typed code, NIKOLI YAML/JSON**. *"Going to YAML pipeline DSL would be unprecedented in major-vendor docs as of 2026-04."* This validates ceos-agents v8.0.0 hesitation: there is NO vendor exemplar to copy. Anthropic-specific implication: published exemplar is exactly what ceos-agents already ships — markdown-prose agents + YAML frontmatter for config. **Closest vendor-blessed evolution path is NOT "add YAML pipeline DSL" but rather "lean further into markdown + frontmatter, add Skills-style progressive disclosure."**

**Controversies / open questions:**
- **5/5 lens consensus na "no Turing-complete DSL"** + 4/5 lens consensus na "declarative structure + imperative escape hatch" — very low controversy.
- **No vendor publishes YAML-pipeline-DSL exemplar pro agent orchestration** = robust gap (agent-5 explicit). Microsoft Magentic-One = closest, ale typed code ne YAML.
- ceos-agents current pattern (markdown stage prose + Hooks for imperative) = **closer to production best practice** than pure-YAML pipeline (agent-2 explicit).

---

## C4 — Quality measurement

### Q10 — Benchmarking metrics

**Cross-lens consensus:** **SWE-bench Verified je de-facto standard pro coding agents** (vendor + academic + production). GAIA + WebArena pro general agents. Format adherence vendor-internal (OpenAI 100%, Anthropic structured outputs grammar-restricted). **Žádný vendor benchmarks "agent architecture shape" directly.** Production-reported metrics: token cost per task, time-to-resolution, defect rate vs senior dev (Devin 1.5-2×), PR review cycles (1.5-2.3), iteration count, compaction events, clarification rate. **What ceos-agents can measure (markdown plugin, no runtime):** stage-level token cost (already v6.8.0), clarification rate (already in `clarification` state object), block reasons by agent (already in pipeline-history.md), AC fulfillment rate (already in reviewer output). **Missing but valuable:** Pass@K reliability (run same ticket N times; measure variance) — most academic agent work uses this.

**Lens-specific evidence:**

- **[academic, agent-1]** Established benchmarks: SWE-bench / SWE-bench Verified (Jimenez et al. 2023, Verified released by OpenAI Aug 2024) — **Top-1 (May 2026): Claude Opus 4.5 + Live-SWE-agent 79.2% on Verified**; Augment Code 72.0%; OpenHands+CodeAct v3 68.4%; Devin 2.0 45.8%. HumanEval (saturating, less informative). GAIA (arxiv 2311.12983, 466 multi-modal questions, Magentic-One 38%). AgentBench (arxiv 2308.03688, 8 environments). MLE-Bench (arxiv 2410.07095). AgentArch (arxiv 2509.10769) — Pass@K peaks 0.0634. AMA-Bench (arxiv 2602.22769) long-horizon memory. τ²-Bench, BIRD-SQL, SimpleQA Verified (Open Agent Spec arxiv 2510.04173 cross-framework eval). NL2Repo-Bench (arxiv 2512.12730) long-horizon repo gen. AgentDojo, Agent Security Bench (arxiv 2510.05244 security). Common metrics matrix: Resolution rate / Pass@1 (universal); Pass@K (K=8) AgentArch; token cost per task increasingly common (arxiv 2511.17006, 2508.02694); time-to-resolution sometimes (OpenHands); coordination overhead % Kim et al.; error amplification factor Kim et al.; clarification rate (academic gap); regression rate (rare); Pass@K reliability becoming standard.
- **[production, agent-2]** Reported metrics matrix: Devin SWE-bench end-to-end 13.86%; Goldman Sachs Devin pilot 3-4× productivity vs prior, 20% efficiency vision; Goldman 25-45 min saved per task minus 10-20 min overhead → 15-30 min net; Devin defect rate 1.5-2× higher than senior dev (anecdotal); Devin PR review cycles 1.5-2.3; Cursor Composer median turn time <30 sec; Cursor 2.0 4× faster; Replit Agent 3 200 min autonomous; Replit 3× faster, 10× more cost-effective vs Computer Use; Anthropic research multi-agent vs single +90.2%; **Anthropic token cost: 4× chat (single agent), 15× chat (multi-agent)**; Anthropic variance explained by token spend alone 80%; OpenHands V1 SDK "substantially reduces" system-attributable failures. SWE-bench Verified leaderboard: Live-SWE-agent + Claude Opus 4.5 = **79.2% SOTA** (April 2026); SWE-Bench Pro (more realistic) top models ~23% vs Verified ~70%+ — **production reality significantly harder**. ceos-agents already collects per v6.8.0: tokens_used, duration_ms, tool_uses, model, started_at/completed_at per stage; pipeline.* accumulators; summary_table; block reasons (sanitized). Production-validated additions: iteration count per fixer↔reviewer loop (Anthropic + Aider both measure); compaction events (Claude Code, Cline both measure); confidence/clarification rate (already partly tracked); defect/regression rate post-merge (Verify command failure rate).
- **[OSS code, agent-3]** Sub-otázka explicitly necovered, ale empirical reliability data citováno: Magentic-One ledger ~92% correct dispatch on benchmarks (paper); MetaGPT 85.9% task completion (Hong et al. paper); LangGraph DAG nodes; OpenHands codeact 70.8% Verified (arxiv 2506.17208).
- **[community, agent-4]** Sub-otázka necovered explicitly. Empirical anchors: 68% production agents at most 10 steps before HITL (arxiv 2512.04123); 70% rely on prompting off-the-shelf models; 74% depend on human evaluation. *"Whether 21 specialized agents in one pipeline degrades vs 7-9 — empirical evidence supports diminishing returns past 3-5 in critique loops, but no specific 21 vs 7 comparison published."*
- **[vendor, agent-5]** Vendor benchmarks: Anthropic SWE-bench Verified Claude Opus 4.7 / Mythos Preview ~0.94 late-2025/early-2026; SWE-bench Pro (Scale-curated 1865 tasks); GAIA + HumanEval + MMLU standard reference. OpenAI co-created Verified subset (used in GPT-5/o3/o4 release); Structured Outputs schema-following 100% (Aug 2024). Google Gemini Code Assist + ADK SWE-bench Verified + MMLU + HumanEval; Vertex AI Agent Builder per-task latency + cost in console. Microsoft Magentic-One paper (Oct 2024) GAIA + WebArena + AssistantBench. **Vendor consensus: SWE-bench Verified for coding agents; GAIA + WebArena for general; vendor-internal evals for format adherence. NO vendor benchmarks "agent architecture shape" directly.** SWE-bench measures end-to-end with whatever scaffold team ships (mini-SWE-agent for Anthropic, Live-SWE-agent for Anthropic's leading score); architecture choice je confounder in published numbers.

**Controversies / open questions:**
- Pass@K reliability je academic gold standard (AgentArch) ale rarely reported by production; ceos-agents could measure via repeated runs (agent-1 explicit gap).
- ceos-agents pipeline-history.md (50-run retention, last 5/last 10 read) je **production-aligned** — Cognition explicitly recommends "share full agent traces" a ceos-agents to dělá (agent-2).

---

### Q11 — Trade-off matrix

**Cross-lens evidence-based scores per variant × dimension.** Cells cite source lens; **L = Low, M = Medium, H = High; n/e = no evidence found.** Triangulation: agent-1 (academic ordinal) + agent-2 (production ordinal) blended; +/− indicates lens disagreement direction.

#### Generic+overlay (current ceos-agents)

| Dimension | Score | Evidence (cross-lens) |
|---|---|---|
| Onboarding cost | **L** | [agent-2] Cursor / Claude Code ~5 min onboarding ([Cursor](https://cursor.com/blog/agent-best-practices)). [agent-1] AgentScope StateModule (arxiv 2508.16279) proven low-friction. [agent-4] aligned with 100% top-15 plugins. |
| Token cost | **L–M** | [agent-1] Single fresh-context dispatch, no multi-agent overhead per Kim et al. (arxiv 2512.08296). [agent-2] generic prompts may be larger; mitigated by Skills progressive disclosure (Anthropic 30-50% saving). |
| Maintenance burden (plugin author) | **L** | [agent-2] one canonical agent set; users own overlay. [agent-1] lightweight overlay matches Distillation paper findings (arxiv 2510.00482). [agent-3] BMAD `customize.toml` 3-tier merge proven at 45.7k★ scale. |
| Maintenance burden (user) | **L** | [agent-2] overlay is small and stable. |
| Customization power | **M** | [agent-1] append-to-prompt academically validated (Authenticated Workflows arxiv 2602.10465) but limited. [agent-2] limited to overlay surface. |
| Error surface | **L–M** | [agent-1] stateless + bounded retrieval matches Stateless Decision Memory paper (arxiv 2604.20158). [agent-2] predictable failure modes. |
| Public-release readiness | **H** | [agent-2] adopted standard (AGENTS.md, 60k+ repos, [agents.md](https://agents.md/)). [agent-4] community signal: 100% top-15 markdown overlay. [agent-5] Anthropic 5-tier subagent priority + append-to-prompt teammate pattern explicit endorsement. |
| Update flow (plugin → user) | **CLEAN** | [agent-2] plugin owns core, user owns overlay (Cursor, Codex observable). |

#### Per-project (each project ships own agent set)

| Dimension | Score | Evidence (cross-lens) |
|---|---|---|
| Onboarding cost | **H** | [agent-1] negative-transfer risk per ADP paper (arxiv 2510.24702): single-domain tuning hurts. [agent-2] community plugins require user to fork/modify. [agent-4] anti-pattern explicitly rejected by community. |
| Token cost | **L–M** | [agent-2] tightly scoped per-project prompts; [agent-1] no academic data on retuning costs. |
| Maintenance burden (plugin author) | **H** | [agent-2] N project variants × M agent updates. [agent-1] Wang et al. (arxiv 2512.01939) version drift across projects compounds. **Combinatorial explosion** — ceos-agents adopting per-project = shipping 8 config-template variants × N agent variants. |
| Maintenance burden (user) | **H** | [agent-2] owns full agent set; bears all updates. |
| Customization power | **H** | [agent-1] trivially full power. [agent-2] full freedom. |
| Error surface | **M–H** | [agent-1] no shared QA/testing; per-project bugs reinvent same mistakes. [agent-2] fragmentation across variants. |
| Public-release readiness | **L** | [agent-1] confusing user story; no academic precedent. [agent-2] community pattern only. [agent-4] forces forking-equivalent — anti-pattern. [agent-5] no vendor explicitly endorses. |
| Update flow (plugin → user) | **FRAGMENTED** | [agent-2] each user version on independent track. |

#### Meta-gen (LLM generates agents/pipelines per project)

| Dimension | Score | Evidence (cross-lens) |
|---|---|---|
| Onboarding cost | **L on first run, H over time** | [agent-1] MetaGen (arxiv 2601.19290) shows feasibility; production data absent. [agent-2] requires user to provide good description; no production reference for cost. |
| Token cost | **H** | [agent-1] LLM-generation step adds non-trivial token spend; AgentArch 6.34% Pass@K reliability concern. [agent-2] generation phase costs tokens; regenerated agents may be larger. |
| Maintenance burden (plugin author) | **H (research-grade)** | [agent-1] ADAS, MetaGen, Meta-Prompting Protocol — all academic, none production-validated. [agent-2] **n/e** — no production data on maintaining a meta-agent that generates other agents. |
| Maintenance burden (user) | **M** | [agent-2] owns description; regen on updates may break customizations. |
| Customization power | **H (claimed)** | [agent-1] self-evolving role spaces. [agent-2] can describe anything but unpredictable output. |
| Error surface | **H** | [agent-1] LLM-as-config-interpreter weakest link per AgentArch hallucination findings (arxiv 2509.10769). [agent-2] unpredictable LLM-generated agents; QA story unclear. |
| Public-release readiness | **L** | [agent-1] bleeding-edge; users not ready. [agent-2] no production deployment of meta-gen at primary-architecture scale. [agent-4] no community precedent. [agent-5] not endorsed by ANY major vendor. |
| Update flow (plugin → user) | **UNRESOLVED** | [agent-2] no production solution to "regen vs preserve customization" conflict. |

**Aggregate verdict from triangulation:**

The matrix loads heavily toward **Generic+overlay** napříč 6 ze 7 dimensions. **Per-project** wins only "customization power" and only at cost of L or H burden on every operational metric. **Meta-gen** has H ("claimed") customization but **0 production deployment evidence and unresolved update-flow conflict** — high-risk, low-evidence variant. Tato matice slouží jako evidence rámec pro A.1 brainstorm, NIKOLI jako rozhodnutí.

**Cross-cell controversy:**
- Maintenance burden cell pro Per-project: agent-3 noted ceos-agents per-project = combinatorial (8 config-templates × N agents) — quantifiable but not benchmarked.
- Customization power H pro Meta-gen je *claimed* (academic papers), NE empirically validated proti generic+overlay; agent-1 explicit gap.

---

## C5 — Competitive landscape

### Q12 — Framework discovery & shortlist

**Aggregation methodology:** Sloučeno napříč 5 lens reports; deduplikováno (same framework jmenovaný více agenty → merged scores). Auto-scoring 5 axes (each 1-5):
- **Stars 30/90d Δ** (momentum) — agent-3 GitHub data + agent-4 community trends
- **Visibility** (HN/Reddit/X mentions 90d) — agent-4 primary
- **Production adoption** (named users, case studies, enterprise testimonials) — agent-2 primary
- **Active dev** (commits 30d) — agent-3 primary
- **Architecture novelty** (paradigm distinct, ne 5 LangGraph clones) — agent-1 + agent-3 primary

**Weighted score formula:** `0.20 × stars + 0.20 × visibility + 0.25 × adoption + 0.15 × dev_activity + 0.20 × novelty` (per spec). Production adoption získává nejvyšší váhu (0.25) jako primary public-release indicator.

#### Ranked shortlist (18 frameworks)

| # | Framework | URL | Stars (Apr 2026) | Stars Δ | Visibility | Adoption | Dev 30d | Novelty | Weighted | Why include |
|---|---|---|---|---|---|---|---|---|---|---|
| 1 | **BMAD-METHOD** | github.com/bmad-code-org/BMAD-METHOD | 45.7k | +~3k/mo | 5 | 4 | 110 commits | 5 (SKILL.md + customize.toml + steps/) | **4.45** | Closest peer — Generic+Overlay shipped at scale in Claude Code plugin format; *the* reference precedent for ceos-agents v8.0.0 architectural decision |
| 2 | **Claude Code (subagents + skills + plugins)** | code.claude.com/docs/en/sub-agents | (canonical) | Steady | 5 | 5 | Active | 5 (SKILL.md spec, 5-tier priority) | **4.40** | Host platform; Anthropic-blessed pattern; 5-tier subagent priority is explicit Generic+Overlay endorsement |
| 3 | **opencode** | github.com/sst/opencode | 149.7k | **+~50k/mo (massive)** | 5 | 4 | **1282 commits** | 5 (TUI, .opencode.json declarative agents) | **4.40** | Explosive growth (149k★ in 12 months); Claude Max routing trick viral; 6.5M devs/month claim |
| 4 | **OpenAI Agents SDK** | github.com/openai/openai-agents-python | 25.2k | High | 5 | 5 | 95 commits | 4 (handoffs as tools, durable, production successor to Swarm) | **4.35** | Reference modern minimalist agent SDK; vendor-blessed (OpenAI first-party); explicit decision rule handoff vs as_tool |
| 5 | **Cursor (Composer + 2.0)** | cursor.com | (proprietary) | High (>$500M ARR est) | 5 | 5 | Active | 4 (multi-agent worktrees, generalist + tool harness) | **4.30** | Top production coding agent; multi-agent in worktrees novel; market leader |
| 6 | **OpenHands (formerly OpenDevin)** | github.com/All-Hands-AI/OpenHands | 72.1k | High | 4 | 4 | 253 commits | 4 (codeact agent + microagents) | **4.10** | Top SE-bench performer (70.8% Verified); arxiv-published architecture (V1 SDK arxiv 2511.03690); microagent pattern precedent |
| 7 | **Microsoft Agent Framework** | github.com/microsoft/agent-framework | 9.8k | Very high (created 2025-04-28) | 4 | 5 | **193 commits** | **5 (declarative YAML + formula expressions, hybrid YAML+code)** | **4.05** | Vendor-led declarative; production successor AutoGen+Semantic Kernel; Magentic-One built-in; **strongest signal MS bets on YAML-declarative as enterprise format** |
| 8 | **LangGraph** | github.com/langchain-ai/langgraph | 30.4k | High (~600+/90d) | 5 | 5 | 113 commits | 3 (graph baseline) | **4.00** | Reference for "graph-based agents"; deterministic state machines; production-dominant orchestration paradigm; Klarna, Uber, Replit, LinkedIn users |
| 9 | **superpowers** (Jesse Vincent / obra) | github.com/obra/superpowers | ~165k (per quemsah index) | Explosive | 5 | 4 (Anthropic marketplace Jan 2026) | Active | 5 (small composable skills, sub-agent dispatch, "VERY token light") | **4.05** | **Opposite philosophy to BMAD** — both succeed; Simon Willison endorsed; native Claude Code marketplace |
| 10 | **Devin (Cognition)** | cognition.ai | (proprietary) | High | 4 | 5 (Goldman Sachs 12k-dev pilot, Nubank, Ramp, Mercado Libre, Citi) | Active | 4 (compound 4-component) | **4.00** | Goldman Sachs production data; "compound AI system" Planner+Coder+Critic+Browser; *the* canonical async-autonomous coding agent |
| 11 | **CrewAI** | github.com/crewAIInc/crewAI | 49.9k | High | 5 | 4 (Workhuman, MongoDB, Visa, Comcast) | 184 commits | 3 (role/task convention) | **3.85** | YAML-DSL paradigm reference; documents limitations (CrewAI 3× managerial overhead vs LangChain); enterprise tier |
| 12 | **Cline** | github.com/cline/cline | 61.0k | Very high | 5 | 4 (1M+ VSCode installs) | 57 commits | 4 (modular component prompts; every-step approval differentiator) | **3.95** | IDE-resident; per-step HITL exemplar; modular system prompt (`agent_role.ts:15`); empirically validated approval-every-step pattern |
| 13 | **Mastra** | github.com/mastra-ai/mastra | 23.3k | Very high | 4 | 3 (TypeScript ecosystem, 300k weekly npm dl) | **703 commits (highest velocity)** | 4 (TS-first, durable WF, agent network) | **3.80** | TypeScript ecosystem moving fast; first-class suspend/resume; PydanticAI-equivalent in TS |
| 14 | **Strands Agents (AWS)** | github.com/strands-agents/sdk-python | 5.7k | Very high (created 2025-05) | 3 | 3 (AWS Bedrock) | 55 commits | 4 (Graph + Swarm + Interrupts first-class) | **3.50** | AWS production-aligned; `multiagent/graph.py` 1265 lines; `interrupt.py` first-class HITL primitive |
| 15 | **GitHub Copilot Coding Agent** | docs.github.com/copilot | (proprietary) | High | 4 | 5 (10M+ paid Copilot seats) | Active | 4 (spec → plan → implement gates; sub-agent system) | **4.00** | GitHub-backed SDD; Copilot Workspace tech rolled into; canonical issue-to-PR workflow |
| 16 | **Anthropic Multi-Agent Research System** | anthropic.com/engineering/multi-agent-research-system | (canonical paper) | (referenced) | 5 | 5 (Anthropic blessed) | n/a | 5 (orchestrator-worker reference; +90.2% on internal evals) | **4.30** | Vendor-published architecture; orchestrator + parallel sub-agents reference; explicit token cost metrics (15× chat for multi-agent) |
| 17 | **Pydantic AI** | github.com/pydantic/pydantic-ai | 16.6k | High | 4 | 4 (3,900+ dependents; MindsDB 10x perf claim) | 80+ commits | 4 (type-safe agents, structured output, multi-model) | **3.80** | Production reliability angle; type-safety; alternative to LangChain documented community migration |
| 18 | **wshobson/agents** | github.com/wshobson/agents | (large) | Stable | 4 | 4 (largest commercial peer in markdown-plugin space) | Active | 4 (extreme specialization 100+ agents per plugin, no orchestration script) | **3.85** | Closest commercial peer to ceos-agents — both ship many narrow markdown agents; reveals "specialization without orchestration" niche |

**Note pro tabulku:** Score normalizace 1-5 per criterion. Visibility/adoption/novelty jsou subjective ordinal; agent-1/2/3/4/5 weighted average použito. Hraniční kandidáti vyloučeni: Letta/MemGPT (high novelty stateful but low ceos-agents relevance), Inngest agent-kit (low visibility), Vercel AI SDK (general purpose less specialized), MetaGPT (academic but stale 0 commits 30d), AutoGen (maintenance mode), DSPy (declarative compilation paradigm relevant ale Python runtime incompatible), Roo Code (shutdown 2026-04-21).

#### Top 10 Run 2 deep-dive kandidáti (auto-selected)

Auto-selection by weighted score, no user gate. Ranked Top 10:

1. **BMAD-METHOD** (4.45) — closest in spirit to ceos-agents v8.0.0; SKILL.md frozen base + `customize.toml` overlay (3-tier merge: scalars override, arrays append, arrays-of-tables match by code/id) + `steps/*.md` procedural decomposition. Already ships Generic+Overlay at scale (45.7k★) in Claude Code plugin format; v3→v5 migration history publicly observable; v6 alpha critique surfaces real complexity costs (50+ workflows, 19 agents). **Run 2 deep-dive should explore:** customize.toml semantics in detail, scaling pain (v6 issues #675, #1062, #2003), persona-menu vs skill-dispatch granularity hybrid, SDLC role boundaries (Analyst/PM/Architect/SM/PO/Dev/QA/TechWriter).

2. **Claude Code (subagents + skills + plugins)** (4.40) — host platform; Anthropic-blessed customization standard. 5-tier subagent priority (Managed > CLI > Local > Project > User > Plugin). Append-to-prompt teammate pattern. Skills format: SKILL.md frontmatter + reference/ + scripts/. Progressive disclosure 3-tier (metadata ~100 tokens, SKILL.md <5k, bundled resources). **Run 2 deep-dive should explore:** plugin permissions architecture, hook lifecycle (12 events), `disable-model-invocation` semantics (issue #26251 known limitation), CLAUDE.md hierarchy, skills SKILL.md spec evolution.

3. **opencode (sst)** (4.40) — explosive 149.7k★ in 12 months; TUI-based agent platform; declarative `.opencode.json` agents; multi-provider; 1282 commits/30d (top velocity). Claude Max routing trick went viral. **Run 2 deep-dive should explore:** .opencode.json schema, declarative agent definition pattern, multi-provider abstraction layer, terminal-first UX implications for ceos-agents distribution.

4. **OpenAI Agents SDK** (4.35) — first-party Python SDK March 2025; production successor to Swarm. **Handoffs as tools** primitive (LLM picks dispatch via tool-call). `Agent.as_tool(parameters=...)` for nested specialist without transferring conversation. Decision rule (handoff vs as_tool) clearest in OSS. Codex Subagents typed inheritance (inherit-with-override) closest production-shipping inheritance model. **Run 2 deep-dive should explore:** Handoff dataclass, agents-as-tools vs handoff trade-offs, Guardrails architecture, Sessions, Codex Subagent inheritance fields.

5. **Cursor (Composer + 2.0)** (4.30) — top production coding agent (>$500M ARR est); Composer 1 (Nov 2025) = single MoE + tool harness; 2.0 (Nov 2025) = 8 parallel agents in git worktrees + IDE-native synchronous accept. *"4× faster"* claim; Composer trained via RL specifically for new harness. **Run 2 deep-dive should explore:** Composer architecture (RL-trained model behind tool harness), 2.0 worktree orchestration, .cursor/rules customization mechanism, AGENTS.md integration, IDE-native HITL patterns.

6. **Anthropic Multi-Agent Research System** (4.30) — published architecture. Lead Researcher orchestrates 3-5 parallel sub-agents per query; each with own context; Lead compresses results to "lightweight references." +90.2% vs single-agent Opus 4 on internal evals; **15× tokens vs chat**; 4× tokens single agent vs chat; variance explained by token spend alone 80%. **Run 2 deep-dive should explore:** orchestrator prompt design, sub-agent fan-out patterns, lightweight reference compression, when to parallelize (read tasks) vs not.

7. **OpenHands (formerly OpenDevin)** (4.10) — only OSS production-grade SDK with published architecture paper (V1 SDK arxiv 2511.03690); 72.1k★; 70.8% SWE-bench Verified; codeact agent + microagents directory (`.openhands/microagents/`). **Run 2 deep-dive should explore:** microagent pattern (precedent for ceos-agents agent set), CodeAct paradigm, V0 → V1 migration lessons, AAIF governance integration.

8. **Microsoft Agent Framework + Magentic-One** (4.05) — vendor-led declarative; created 2025-04-28; **193 commits/30d**; YAML declarative-agents/ + formula expressions (`=Local.ServiceParameters.IsResolved`) + ConditionGroup; production successor AutoGen + Semantic Kernel (1.0 Oct 2025); Magentic-One 2-loop bookkeeping (task ledger + progress ledger; ~92% correct dispatch on benchmarks per paper); GAIA + WebArena results. **Run 2 deep-dive should explore:** declarative-agents YAML schema, formula language semantics, Magentic-One orchestrator-with-ledger pattern (`_prompts.py:46-94`), Optional Plan Review + Stall Detection HITL gates, `kind: ConditionGroup` vs LLM dispatch.

9. **superpowers (Jesse Vincent)** (4.05) — opposite philosophy to BMAD; small composable skills; sub-agent dispatch; "VERY token light" core; ~165k★ per quemsah index; Anthropic marketplace adopted Jan 2026; Simon Willison endorsement. **Run 2 deep-dive should explore:** skill granularity decisions, sub-agent dispatch patterns, marketplace integration model, comparison vs BMAD viral packaging vs superpowers composable.

10. **Devin (Cognition)** (4.00) — Goldman Sachs 12,000-dev pilot; Nubank, Ramp, Mercado Libre, Citi; "compound AI system" Planner + Coder + Critic + Browser (4 components); $20/mo from $500/mo; 200 min autonomous; 13.86% SWE-bench end-to-end; 3-4× productivity at Goldman; defect rate 1.5-2× higher than senior dev; PR review cycles 1.5-2.3. **Run 2 deep-dive should explore:** compound architecture component boundaries, async-autonomous trade-offs (200 min runtime), Cognition "Don't Build Multi-Agents" essay reasoning (write-task focus), Edit Apply Models refactor away from compound to single-model, Goldman pilot details.

**Why these 10 (justification):**
- Range covers all 5 paradigm clusters from agent-3 source-code analysis: markdown-procedural (BMAD, Claude Code, superpowers), declarative YAML (MS Agent Framework, opencode), code-defined graph (LangGraph mentioned but didn't make Top 10), LLM-orchestrator-with-ledger (Magentic-One, Anthropic Research, Devin), generalist + tool harness (Cursor).
- Production adoption weighted heavy: 7/10 have named enterprise users or vendor pedigree.
- Architectural novelty distinct: declarative YAML (MS Agent Framework, opencode), customize.toml overlay (BMAD), 3-tier progressive disclosure (Claude Code Skills), handoffs-as-tools (OpenAI), compound model split (Devin), microagents (OpenHands), parallel orchestrator-worker (Anthropic Research), worktrees (Cursor 2.0), small-composable (superpowers), persona-menu hybrid (BMAD again).
- Direct ceos-agents v8.0.0 relevance: BMAD/Claude Code/superpowers (closest plugins), OpenAI/MS Agent Framework (closest customization-mechanism evolution), Cursor (closest production peer), Devin/Anthropic Research (closest architecture paradigm peer), OpenHands (closest OSS SDK peer), opencode (closest declarative-agents-config peer).

**Excluded from Top 10 (rationale):** LangGraph (4.00, but graph DSL paradigm requires Python runtime — incompatible with markdown plugin philosophy; high relevance for paradigm comparison only), CrewAI (3.85, role-task YAML well-documented limitations already), Cline (3.95, single-agent IDE-resident not ceos-agents architecture peer), Mastra (3.80, TS-first niche), Strands (3.50, low visibility), GitHub Copilot Coding Agent (4.00, proprietary closed details), wshobson/agents (3.85, no orchestration), Pydantic AI (3.80, type-safety angle lower priority).

#### Anomalies a surprising findings

1. **opencode at 149.7k★ in 12 months je phenomenon** (agent-3 explicit). Underweighted v většině agent framework discussions but trending hardest. 1282 commits/30d. Founded 2025-04-30. Reflects "TUI agents won 2026" thesis (dev.to). May represent a **paradigm shift** in distribution model that plugin frameworks (including ceos-agents) should monitor — possibly competitive (claudefa.st-style standalone tool).

2. **Mastra at 703 commits/30d je top velocity ze všech reviewed frameworks**, předbíhající LangGraph + AutoGen + CrewAI + ostatní. TypeScript ecosystem celkově: TypeScript overtook Python jako #1 GitHub language v August 2025 (Octoverse 2025), driven explicitly by AI agent reliability concerns. Implication: TS-native agent frameworks (Mastra, VoltAgent) gaining real ground vs Python incumbents — relevantní pokud ceos-agents někdy expand mimo markdown.

3. **superpowers stars countují záhadně** — agent-4 cites *165k★ per quemsah/awesome-claude-plugins index data* with quote *"94k March → 121k April → 165k now"*. Pokud accurate, je nejpopulárnější Claude Code plugin overall, předbíhající i Anthropic's own anthropics/skills (123k★ per same index). agent-3 ale cited GitHub stars conservatively. **Surfacing as anomaly:** to verify v Run 2 — počet je plugin-marketplace aggregate, nikoliv pure GitHub-stars-on-obra/superpowers repo.

4. **MetaGPT 67.4k★ but only 2 real-world adopting projects** vs LangChain (119k★ / 105 projects) and CrewAI (40k / 19 projects) per Wang et al. (arxiv 2512.01939). **GitHub stars ≠ adoption** — most important Q12 caveat. Implication: stars-momentum scoring oversells frameworks like MetaGPT; ecosystem maturity + maintenance activity + documented production users matter more.

5. **Roo Code shutdown 2026-04-21 despite 3M installs** — agent-4 reports founder Matt Rubens: *"Roo Code hit 3 million installs. We're shutting it down to go all-in on Roomote."* Even strong adoption doesn't guarantee survival in fast-moving fork ecosystems. **Implication for ceos-agents:** be ready for ecosystem to move fast around you; Codex, Roomote, opencode all shifting paradigms.

6. **AutoGen retired into maintenance mode 2025-10**, succeeded by MS Agent Framework. AutoGen still 57k★ but **0 commits 30d** (per agent-3). Microsoft betting on declarative YAML path. **Implication:** large-star projects can become legacy rapidly; star count without commit velocity = stale signal.

7. **Microsoft Agent Framework declarative YAML** (`declarative-agents/workflow-samples/`) je most explicit vendor signal that **YAML-declarative is enterprise future** — but agent-5 also cites *"Going to YAML pipeline DSL would be unprecedented in major-vendor docs"* (no top vendor ships YAML pipeline DSL, ne even Microsoft jako primary mechanism). Tension: enterprise YAML adoption emerging but not-yet-vendor-canonical.

8. **Anthropic's own production system prompt = 6,973 tokens** (arxiv 2601.21233) — meta-evidence že Anthropic ships *substantial* prompt for flagship coding agent, despite Anthropic-published guidance favoring Goldilocks moderate. Reveals possible vendor-vs-publication gap or different optima for Anthropic's hosted-model-with-managed-cost vs token-paying users.

9. **Cognition's "Don't Build Multi-Agents" essay (June 2025) vs Anthropic's "+90.2% multi-agent on internal evals" (June 2025)** = both shipped same month, both authoritative, **explicit contradiction**. Resolution: task type (write vs read). **But if reader doesn't catch task-type nuance, conflicting takeaways** — communication artifact worth flagging.

10. **5/5 lens convergence on absence of meta-gen production deployment** (excluding Replit Agent 3 feature) je strong evidence — but agent-1 + agent-3 both explicitly note **emerging research** (MetaGen, ADAS, MetaSynth, Meta-Prompting Protocol all 2025–2026 papers). Field may be 12-24 months from production-ready meta-gen, but as of 2026-04 is **research-stage only**. ceos-agents v8.0.0 at this anomaly's edge: **frontier choice if adopted now, low-risk choice if deferred.**

---

## Cross-cutting controversies

Tato sekce surfaces místa kde authoritative sources přímo disagree. Synthesis NIKDY neresolvuje — preserves both positions s evidence.

### CC1 — "Don't multi-agent" vs "+90.2% multi-agent" (Q2, Q7)

**Cognition** ("Don't Build Multi-Agents," June 2025): single-threaded agents with full context outperform parallel sub-agents on **write tasks**. Derived from operating Devin in production for ~18 months + serving Goldman Sachs (12,000-developer pilot, 13 July 2025). *"Miscommunication compounds; subagents misinterpret tasks without full context."* Refactored Edit Apply Models away from compound to single-model approaches "for reliability." [agent-2]

**Anthropic** ("How we built our multi-agent research system," June 2025): orchestrator + parallel sub-agents beat single-agent Opus 4 by **+90.2% on internal evals** — but cost **15× tokens vs chat**. [agent-2 + agent-5]

**Resolution per evidence:** Task type tracks the split — write tasks favor single-agent; read/research tasks favor parallel sub-agents. Both positions remain valid per source.

### CC2 — OpenAI single-first vs Anthropic+Google+Microsoft multi-OK (Q2)

**OpenAI** ("A practical guide to building agents," March 2025): *"OpenAI's general recommendation is to maximize a single agent's capabilities first. More agents can provide intuitive separation of concepts, but can introduce additional complexity and overhead, so often a single agent with tools is sufficient."* [agent-5]

**Anthropic + Google + Microsoft camp:** multi-agent specialization acceptable from day one for context isolation. Anthropic Nov 2025 harness post: *"unclear whether single, general-purpose coding agent performs best across contexts."* [agent-5]

**Resolution per evidence:** Vendor positioning split — OpenAI prioritizes simplicity, others prioritize specialization. **Žádný vendor publishes "max agents per system" recommendation** (agent-5 explicit gap).

### CC3 — Long prompts help vs hard accuracy ceilings (Q1)

**Liu/Wang/Willard** (arxiv 2502.14255, Feb 2025): *"Long instructions generally improve performance metrics across all tasks on all experimented domains, with biggest improvement in detail-sensitive tasks."* Defends maximalist v domain-narrow kontextu. [agent-1]

**"Less Is More"** (arxiv 2604.18897): *"balanced hard accuracy plateaus in an empirical saturation region of approximately 60-79% despite substantial engineering effort"* across 40+ prompt variants. **Hard ceiling on prompt-engineering returns.** [agent-1]

**Resolution per evidence:** Domain-narrow vs open-ended task split. ceos-agents (deterministic CI-style pipelines) closer to domain-narrow defensible-maximalist. Reasoning-model era (Opus 4.7) further reduces required prompt depth (vendor agent-5).

### CC4 — Stateful vendor defaults vs stateless academic recommendation (Q4)

**Vendors (Anthropic, OpenAI, Google, Microsoft):** stateful by default with explicit checkpointing/compaction primitives. All 4 ship persistence + resume APIs. Stateless dispatch je outlier. [agent-5]

**"Stateless Decision Memory for Enterprise AI Agents"** (arxiv 2604.20158, 2026): *"Stateful memory architectures violate enterprise deployment properties by construction... Statelessness is attainable in an agent-memory substrate without paying the decision-quality penalty retrieval pays."* DPM 7-15× faster, 2 LLM calls vs 83-97. [agent-1]

**Resolution per evidence:** Vendor "stateful" = within-agent-lifetime + checkpointing; ceos-agents "stateless dispatch + state.json + pipeline-history.md" = functionally hybrid (stateless agents, stateful pipeline metadata). Both positions internally consistent — different definitions of "state."

### CC5 — Cline "approve every step" praised vs friction-driven Auto Approve added

agent-4: *"Cline's 'approve every step' pattern is praised as the safety-first default."* But: *"Cline added 'Auto Approve' mode specifically because every-step approval slowed iteration too much."*

**Resolution per evidence:** **HITL placement is fundamental UX trade-off** — community celebrates safety-first publicly while practical adoption drives toward less-friction modes. Stack Overflow 2025 distrust at 46% (vs 31% prior year) supports more HITL transparency in principle but practical user fatigue is real. ceos-agents `--yolo` flag mirrors this: opt-in autonomous mode for users who hit gate fatigue.

### CC6 — BMAD viral packaging vs superpowers composable (Q2)

agent-4: BMAD-METHOD = 43k–45k★ "12+ specialized personas across full SDLC" approach **viral** in OSS community; ROI claim *"55–58% reduction in total project hours."* But v6 alpha critique surge documenting *"50+ workflows, 19+ specialized agents, step-file architecture, document sharding, web bundles"* perceived as YAML-heavy and brittle.

**superpowers (Jesse Vincent):** ~165k★ (per quemsah index) opposite philosophy — small composable skills, sub-agent dispatch, "VERY token light" core. Anthropic marketplace adopted Jan 2026.

**Resolution per evidence:** Both succeed; differentiating factor je *"whether the user can compose vs is forced to swallow the whole methodology."* Two viable paradigms — neither dominant.

### CC7 — "GitHub stars ≠ adoption" (Q12 anomaly)

Wang et al. (arxiv 2512.01939, Dec 2025): MetaGPT 67.4k★ but only 2 real-world adopting projects vs LangChain 119k★ / 105 projects vs CrewAI 40k / 19 projects. *"Developers should prioritize ecosystem maturity and maintenance activity over GitHub stars."* [agent-1]

**Implication for Q12 scoring:** stars-momentum scoring oversells popular-but-stale frameworks. Production-adoption + dev-activity weighting partially corrects. Roo Code (3M installs, then shutdown 2026-04-21) is also cautionary.

### CC8 — Markdown vs YAML for instructions (Q5d, Q9)

Universal community + production pattern: **Markdown wins for instructions; YAML wins for metadata/config; JSON loses everywhere except machine-to-machine.** [agent-4 + agent-2]

But Microsoft Agent Framework `declarative-agents/workflow-samples/` (YAML for full workflow declaration) is largest vendor signal toward enterprise YAML adoption [agent-3 + agent-5]. Tension between **plugin-ecosystem markdown convergence** and **enterprise YAML emergence** — possibly bifurcation rather than convergence on single format.

---

## "No evidence found" inventory

Honest disclosure where multiple lenses converged on absence of evidence. **Recorded so A.1 brainstorm doesn't assume answers exist.**

1. **Migration ROI for agent framework switches (Q5b).** No peer-reviewed case study comparing markdown-driven → declarative migrations specifically. PayPal DSL paper (arxiv 2512.19769) je closest but single industry case study, single org. **5/5 lenses converge on absence.**

2. **Per-project agent set (full duplication) production maintenance cost (Q3, Q11).** Only community-pattern data (wshobson/agents); no enterprise productized example to benchmark cost against. [agent-2 + agent-3]

3. **Meta-gen at primary-architecture scale (Q3, Q8, Q11).** 0 production deployments found. MetaAgent (arxiv 2507.22606), Hyperagents, MetaGen (arxiv 2601.19290), MetaSynth (arxiv 2504.12563), Meta-Prompting Protocol (arxiv 2512.15053) all academic/research. Replit Agent 3 has "generate other agents" jako feature, NIKOLI core architecture. **5/5 lenses converge.**

4. **Plugin-customization mechanism preferences in users (Q5d).** Genuinely outside academic scope. Community-signals + vendor-signals + production observable adoption fill the gap, but **no controlled head-to-head study Generic+overlay vs Per-project for plugin ecosystems** found. [agent-4 explicit]

5. **Reasoning-model-specific impact on agent prompt depth (Q1).** Multiple papers reference o1/o3/o4 / Claude 4.x extended thinking inflection but **no peer-reviewed paper isolates "how much shorter should prompts be with reasoning models?"** [agent-1 explicit]

6. **HITL gate placement empirical user-trust data (Q6).** Feng et al. (arxiv 2506.12469) provides 5-level conceptual framework but no user studies. **Major academic gap.** [agent-1 explicit]

7. **Pass@K reliability for ceos-agents-style pipelines (Q10).** Most academic agent work uses Pass@K but ceos-agents has data only for single runs. Could measure via repeated-run benchmark — **valuable missing metric**. [agent-1 + agent-2]

8. **Quantitative reliability comparison of LLM-orchestrator vs deterministic state machine in agent dispatch (Q5c).** Magentic-One paper has aggregate GAIA scores but no direct A/B vs deterministic dispatcher. [agent-3]

9. **Long-horizon stateful pipeline runs vs stateless re-dispatch in agent systems specifically** (not memory-bench tasks) (Q4). Academic literature focuses on conversational long-horizon; pipeline-style long-horizon is under-studied. [agent-1]

10. **Devin 2.0's actual scaffold details (Q12).** Devin 2.0 is mentioned in SWE-bench at 45.8% but proprietary scaffold is not academically described. [agent-1]

11. **Whether 21 specialized agents in one pipeline degrades vs 7-9** (Q2). Empirical evidence supports diminishing returns past 3-5 in critique loops, but **no specific 21 vs 7 comparison published**. [agent-2 explicit]

12. **AGENTS.md vs CLAUDE.md production drift behavior** when both exist — anecdotal only ("explicit chat prompts override everything; closest file wins"). [agent-2]

13. **wshobson/agents adoption metrics** — no public data on which agents are used most (would inform "narrow vs broad" empirical question). [agent-3]

14. **Goldman Sachs Devin pilot detailed defect/regression data** — only high-level "20% efficiency gain" target and SitePoint-aggregated "1.5-2× higher defect rate, 1.5-2.3 review cycles" anecdotes. No published peer-reviewed measurement. [agent-2]

15. **PydanticAI MindsDB 10x perf claim** — single-vendor self-report; not independently verified. [agent-4]

16. **BMAD ROI claim of 55–58% project-hour reduction** appears in advanced BMAD article (Benny's Mind Hack) but no independent third-party validation. Treat as marketing-adjacent. [agent-4]

17. **Multi-host distributed lock for autopilot** — no community precedent in Claude Code plugin space; outside scope of agent shape but noted v ceos memory as v6.10.1+ deferred work. [agent-4]

18. **Whether Codex-style typed inheritance** (`nickname_candidates`, `model`, `model_reasoning_effort`, `sandbox_mode`, `mcp_servers`, `skills.config` inherit-with-override) outperforms Anthropic's append-to-prompt model — both production-shipping but no head-to-head study. [agent-2]

---

## Source aggregate

Total unique sources cited across 5 agent reports: ~250+. Grouped by source type. Selected highlights only — full lists v individual agent reports.

### Anthropic (vendor)
- [Effective context engineering for AI agents](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents) (2025-09-29) — Q1, Q4, Q5c
- [Equipping agents for the real world with Agent Skills](https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills) (2025-10-16) — Q1, Q5d
- [How we built our multi-agent research system](https://www.anthropic.com/engineering/multi-agent-research-system) (June 2025) — Q2, Q7
- [Building Effective Agents](https://www.anthropic.com/research/building-effective-agents) (Schluntz/Zhang, 2024-12-19) — Q2, Q5a
- [Effective harnesses for long-running agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents) (2025-11-26) — Q2, Q4
- [Building agents with the Claude Agent SDK](https://claude.com/blog/building-agents-with-the-claude-agent-sdk) — Q4, Q7
- [Claude Code subagents](https://code.claude.com/docs/en/sub-agents) — Q3, Q7, Q8
- [Agent Skills overview](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview) — Q1, Q5d
- [Structured Outputs](https://platform.claude.com/docs/en/build-with-claude/structured-outputs) (2025-11-14) — Q5c
- [2026 Agentic Coding Trends Report](https://resources.anthropic.com/2026-agentic-coding-trends-report) — Q5b
- GitHub: `anthropics/skills` (canonical SKILL.md spec); Claude Code issue #26251 (`disable-model-invocation` bug); #37823 (per-agent model overrides); #19141; #22345

### OpenAI (vendor)
- [A practical guide to building agents](https://cdn.openai.com/business-guides-and-resources/a-practical-guide-to-building-agents.pdf) (March 2025) — Q1, Q2
- [OpenAI Agents SDK Python](https://openai.github.io/openai-agents-python/) — Q2, Q4, Q7
- [OpenAI Agents SDK Handoffs](https://openai.github.io/openai-agents-python/handoffs/) — Q7
- [Codex AGENTS.md guide](https://developers.openai.com/codex/guides/agents-md) — Q5d
- [Codex Subagents inheritance](https://developers.openai.com/codex/subagents) — Q3, Q8
- [Introducing Structured Outputs in the API](https://openai.com/index/introducing-structured-outputs-in-the-api/) (Aug 2024) — Q5c
- [Agentic AI Foundation announcement](https://openai.com/index/agentic-ai-foundation/) — Q5d
- GitHub: `openai/openai-agents-python` (`src/agents/agent.py`, `src/agents/handoffs/__init__.py:94`); openai/swarm (deprecated)

### Google (vendor)
- [ADK docs](https://adk.dev/) — Q3, Q4, Q5a
- [ADK Multi-Agent Systems](https://adk.dev/agents/multi-agents/) — Q2, Q3
- GitHub: `google/adk-python`

### Microsoft (vendor)
- [Microsoft Agent Framework Overview](https://learn.microsoft.com/en-us/agent-framework/overview/) (updated 2026-04-20) — Q1, Q2, Q5a, Q9
- [Magentic orchestration](https://learn.microsoft.com/en-us/agent-framework/user-guide/workflows/orchestrations/magentic) — Q5a, Q5c, Q6
- [Microsoft Agent Framework Version 1.0](https://devblogs.microsoft.com/agent-framework/microsoft-agent-framework-version-1-0/) — Q5b
- [Magentic-One](https://www.microsoft.com/en-us/research/articles/magentic-one-a-generalist-multi-agent-system-for-solving-complex-tasks/) — Q2, Q5a, Q5c
- [Production-ready convergence](https://cloudsummit.eu/blog/microsoft-agent-framework-production-ready-convergence-autogen-semantic-kernel) — Q5b
- [VentureBeat — Microsoft retires AutoGen](https://venturebeat.com/ai/microsoft-retires-autogen-and-debuts-agent-framework-to-unify-and-govern) — Q5b
- GitHub: `microsoft/agent-framework` (declarative-agents/workflow-samples/CustomerSupport.yaml); `microsoft/autogen` (`_magentic_one/_prompts.py`); `microsoft/semantic-kernel`

### Meta / Llama Stack (vendor)
- GitHub: `llamastack/llama-stack` + ARCHITECTURE.md — Q5d, Q8

### Production / shipping products
- Cognition: [Don't Build Multi-Agents](https://cognition.ai/blog/dont-build-multi-agents) (June 2025); [introducing Devin](https://cognition.ai/blog/introducing-devin); [Devin 2.0 announcement](https://venturebeat.com/programming-development/devin-2-0-is-here-cognition-slashes-price-of-ai-software-engineer-to-20-per-month-from-500); [Devin annual review 2025](https://cognition.ai/blog/devin-annual-performance-review-2025)
- Cursor: [2.0 announcement](https://cursor.com/blog/2-0); [Composer architecture](https://cursor.com/blog/composer); [agent best practices](https://cursor.com/blog/agent-best-practices); [Cursor Rules](https://cursor.com/docs/rules)
- Replit: [Agent 3 announcement](https://blog.replit.com/introducing-agent-3-our-most-autonomous-agent-yet); [2025 in review](https://blog.replit.com/2025-replit-in-review)
- GitHub Copilot: [Coding Agent](https://docs.github.com/copilot/concepts/agents/coding-agent/about-coding-agent); [Workspace](https://githubnext.com/projects/copilot-workspace)
- Goldman Sachs Devin pilot: [CNBC](https://www.cnbc.com/2025/07/11/goldman-sachs-autonomous-coder-pilot-marks-major-ai-milestone.html); [SitePoint aftermath](https://www.sitepoint.com/devin-ai-engineers-production-realities/)
- Aider: [docs](https://aider.chat/docs/); [architect mode blog](https://aider.chat/2024/09/26/architect.html); GitHub `Aider-AI/aider`; multi-agent proposals #4428, #1839
- OpenHands: GitHub `All-Hands-AI/OpenHands`; [V1 SDK paper arXiv 2511.03690](https://arxiv.org/abs/2511.03690)
- Sourcegraph: [Cody/Amp](https://sourcegraph.com/blog/cody-the-ai-powered-tool-helping-support-engineers-unblock-themselves)
- Augment Code: [pricing](https://www.augmentcode.com/pricing); [why multi-agent fails](https://www.augmentcode.com/guides/why-multi-agent-llm-systems-fail-and-how-to-fix-them)
- Iterathon: [Multi-agent orchestration economics](https://iterathon.tech/blog/multi-agent-orchestration-economics-single-vs-multi-2026)

### OSS frameworks (source code primary)
- BMAD-METHOD: GitHub `bmadcode/BMAD-METHOD` (`src/bmm-skills/2-plan-workflows/bmad-agent-pm/SKILL.md:74`, `customize.toml:85`, `bmad-dev-story/SKILL.md:485`); discussions #979, #1306, #2003; issues #675, #1062
- LangGraph: GitHub `langchain-ai/langgraph` (`libs/prebuilt/langgraph/prebuilt/interrupt.py`); [overview](https://docs.langchain.com/oss/python/langgraph/overview)
- CrewAI: GitHub `crewAIInc/crewAI` (`lib/crewai/src/crewai/agent/core.py`, `flow/flow.py`, `flow/human_feedback.py`, templates `agents.yaml` + `tasks.yaml`)
- MetaGPT: GitHub `geekan/MetaGPT` (`metagpt/roles/engineer.py:513`, `product_manager.py`, `role.py:592`)
- Strands Agents: GitHub `strands-agents/sdk-python` (`src/strands/agent/agent.py:1222`, `multiagent/graph.py:1265`)
- Mastra: GitHub `mastra-ai/mastra` (`packages/core/src/agent/index.ts`, `workflows/workflow.ts`)
- Cline: GitHub `cline/cline` (`src/core/prompts/system-prompt/components/agent_role.ts:15`, `objective.ts`, `rules.ts`, `capabilities.ts`, `mcp.ts`)
- Roo Code: GitHub `RooCodeInc/Roo-Code` (`packages/types/src/mode.ts:227`, `src/shared/modes.ts`)
- Pydantic AI: GitHub `pydantic/pydantic-ai`
- smolagents (HuggingFace): GitHub `huggingface/smolagents` (`prompts/code_agent.yaml:313`)
- Inngest agent-kit: GitHub `inngest/agent-kit`
- Vercel AI SDK: GitHub `vercel/ai`
- DSPy: GitHub `stanfordnlp/dspy`; [DSPy.ai](https://dspy.ai/)
- Goose: GitHub `aaif-goose/goose`; [docs](https://goose-docs.ai/)
- opencode: [opencode.ai](https://opencode.ai/); [DEV — 140k stars](https://dev.to/ji_ai/opencode-hit-140k-stars-why-terminal-agents-won-2026-aci)
- wshobson/agents: GitHub `wshobson/agents`
- superpowers: GitHub `obra/superpowers`; [Anthropic marketplace](https://claude.com/plugins/superpowers); [Simon Willison Oct 2025](https://simonwillison.net/2025/Oct/10/superpowers/); [Jesse Vincent blog](https://blog.fsck.com/2025/10/09/superpowers/)
- GitHub Spec Kit: GitHub `github/spec-kit`
- OpenSpec: GitHub `Fission-AI/OpenSpec`

### Academic / arxiv (selected highlights)
- **Kim et al.** "Towards a Science of Scaling Agent Systems" [arxiv 2512.08296](https://arxiv.org/html/2512.08296v1) (Dec 2025) — Q2, Q5a, Q5c, Q7 **central**
- **Yin et al.** "Agent Frameworks on Code-centric SE Tasks" [arxiv 2511.00872](https://arxiv.org/html/2511.00872v1) (Nov 2025) — Q2, Q5a, Q12
- **AgentArch** [arxiv 2509.10769](https://arxiv.org/html/2509.10769v1) (Sept 2025) — Q1, Q2, Q5c
- **Wang et al.** "Empirical Study of Agent Developer Practices" [arxiv 2512.01939](https://arxiv.org/html/2512.01939v1) (Dec 2025) — Q5b, Q5d, Q12
- **Martinez & Franch** "Dissecting SWE-Bench Leaderboards" [arxiv 2506.17208](https://arxiv.org/html/2506.17208v2) — Q5a, Q12
- **Magentic-One paper** [arxiv 2411.04468](https://arxiv.org/abs/2411.04468) (Microsoft Research, Nov 2024) — Q2, Q5a
- **AgentScope 1.0** [arxiv 2508.16279](https://arxiv.org/abs/2508.16279) — Q3, Q5a, Q12
- **Open Agent Specification** [arxiv 2510.04173](https://arxiv.org/abs/2510.04173) (Oct 2025, Oracle et al.) — Q5a, Q5c, Q9, Q12
- **Daunis (PayPal DSL)** [arxiv 2512.19769](https://arxiv.org/html/2512.19769) (Nov 2025) — Q5b, Q9 **central**
- **Stateless Decision Memory** [arxiv 2604.20158](https://arxiv.org/abs/2604.20158) (2026) — Q4 **central**
- **Feng et al. "Levels of Autonomy"** [arxiv 2506.12469](https://arxiv.org/html/2506.12469v1) (June 2025) — Q6 **central**
- **Design Patterns for Securing LLM Agents against Prompt Injections** [arxiv 2506.08837](https://arxiv.org/html/2506.08837v3) (June 2025) — Q6
- **DSPy** [arxiv 2310.03714](https://arxiv.org/abs/2310.03714) (Stanford NLP) — Q5c, Q12
- **Live-SWE-agent** [live-swe-agent.github.io](https://live-swe-agent.github.io/) — Q1, Q2, Q10
- **SWE-bench** [arxiv 2310.06770](https://arxiv.org/abs/2310.06770) — Q10, Q12
- **Liu/Wang/Willard "Effects of Prompt Length"** [arxiv 2502.14255](https://arxiv.org/abs/2502.14255) (Feb 2025) — Q1
- **Less Is More** [arxiv 2604.18897](https://arxiv.org/abs/2604.18897) — Q1
- **Stack Overflow Developer Survey 2025** [survey.stackoverflow.co/2025/ai](https://survey.stackoverflow.co/2025/ai) — Q1, Q6
- **Just Ask** [arxiv 2601.21233](https://arxiv.org/html/2601.21233v1) (Claude Code system prompt = 6,973 tokens) — Q1
- **Measuring Agents in Production** [arxiv 2512.04123](https://arxiv.org/abs/2512.04123) — Q5c, Q6, Q10
- **MetaGen** [arxiv 2601.19290](https://arxiv.org/html/2601.19290) — Q8
- **MetaSynth** [arxiv 2504.12563](https://arxiv.org/pdf/2504.12563) — Q8
- **Meta-Prompting Protocol** [arxiv 2512.15053](https://arxiv.org/html/2512.15053) — Q8
- **MetaAgent** [arxiv 2507.22606](https://arxiv.org/abs/2507.22606) — Q3, Q8
- **JSONSchemaBench** [arxiv 2501.10868](https://arxiv.org/abs/2501.10868) — Q5c
- **AOrchestra** [arxiv 2602.03786](https://arxiv.org/html/2602.03786v1) — Q7
- **AgentOrchestra TEA Protocol** [arxiv 2506.12508](https://arxiv.org/abs/2506.12508) — Q12

### Community signals (HN / Reddit / X / podcasts / blogs)
- HN: 46509130 (Agentic Frameworks 2026), 46446242 (Agents Done Right 2026), 44352279 (.agent yaml/markdown), 44281542 (3 markdown files framework), 43312724 (Manus 900-comment), 40739982 (no longer using LangChain), 41192069 (LangChain Black Box), 39101828 (Why YAML), 34351503 (Yaml from hell), 46549444 (Executable markdown), 45096962 (Don't Build Multi-Agents discussion)
- Reddit subreddits referenced: r/ClaudeAI, r/LocalLLaMA, r/ChatGPTCoding, r/MachineLearning, r/programming, r/cursor, r/typescript, r/Python
- awesome-* lists: `quemsah/awesome-claude-plugins`, `ComposioHQ/awesome-claude-plugins`, `VoltAgent/awesome-claude-code-subagents`, `hesreallyhim/awesome-claude-code`, `jeremylongshore/claude-code-plugins-plus-skills`
- Latent.space: [Agent Engineering](https://www.latent.space/p/agent), [Scaling without Slop 2026](https://www.latent.space/p/2026), [AIE Europe Debrief](https://www.latent.space/p/unsupervised-learning-2026)
- AGENTS.md / AAIF: [agents.md](https://agents.md/), [Builder.io tips](https://www.builder.io/blog/agents-md), [tessl.io](https://tessl.io/blog/from-prompts-to-agents-md-what-survives-across-thousands-of-runs/)
- Karpathy Dec-2025 viral tweet (referenced via 36kr translation)
- Stack Overflow: [Developer Survey 2025 AI](https://survey.stackoverflow.co/2025/ai), [blog Dec 2025](https://stackoverflow.blog/2025/12/29/developers-remain-willing-but-reluctant-to-use-ai-the-2025-developer-survey-results-are-here/)
- GitHub Octoverse 2025: [TypeScript #1](https://github.blog/news-insights/octoverse/octoverse-a-new-developer-joins-github-every-second-as-ai-leads-typescript-to-1/)
- Selected blog citations: [Augment Code Why multi-agent fails](https://www.augmentcode.com/guides/why-multi-agent-llm-systems-fail-and-how-to-fix-them), [lethain.com agents-coordinators](https://lethain.com/agents-coordinators/), [WorkOS HITL patterns](https://workos.com/blog/why-ai-still-needs-you-exploring-human-in-the-loop-systems), [Ravoid LangChain Exit](https://ravoid.com/blog/langchain-exit-raw-sdk-migration-2026), [Anderson Santos BMAD critique](https://adsantos.medium.com/you-should-bmad-part-2-a007d28a084b), [Benny's Mind Hack BMAD](https://bennycheung.github.io/bmad-reclaiming-control-in-ai-dev), [DataCamp CrewAI vs LangGraph vs AutoGen](https://www.datacamp.com/tutorial/crewai-vs-langgraph-vs-autogen)

### Benchmarks
- [SWE-bench Verified leaderboard](https://www.swebench.com/verified.html); [SWE-bench](https://www.swebench.com/); [SWE-Bench Pro Scale](https://labs.scale.com/leaderboard/swe_bench_pro_public); [SWE-bench-Live](https://swe-bench-live.github.io/); [llm-stats](https://llm-stats.com/benchmarks/swe-bench-verified)
- [GAIA arxiv 2311.12983](https://arxiv.org/abs/2311.12983); [AgentBench arxiv 2308.03688](https://arxiv.org/abs/2308.03688); [MLE-Bench arxiv 2410.07095](https://arxiv.org/abs/2410.07095)

### Standards / specs
- [agents.md](https://agents.md/) — AGENTS.md open standard, AAIF Linux Foundation governance
- [Model Context Protocol](https://modelcontextprotocol.io) — Anthropic open standard, adopted OpenAI/Google/Microsoft

---

## Provenance

| Agent | Lens | File | Size | Distinct contributions |
|---|---|---|---|---|
| **Agent 1** | Academic literature (arxiv, peer-reviewed papers, standardized benchmarks, research labs) | `agents/agent-1-academic.md` | 60KB / 692 řádků | Kim et al. quantitative scaling laws; Yin et al. SE framework comparison; AgentArch enterprise benchmark; Stateless DPM 2026; Feng et al. autonomy levels; Daunis PayPal DSL ROI; Open Agent Spec; AgentScope inheritance; explicit "no-evidence-found" disclosures pro Q5b/Q5d/Q3-per-project/Q4-pipeline-stateful; cautious "academia ≠ practice divergence" framing |
| **Agent 2** | Production engineering (shipping AI coding products, eng blogs, pricing pages, customer case studies) | `agents/agent-2-production.md` | 73KB / 747 řádků | Cognition essay vs Anthropic +90.2% controversy; AGENTS.md 60k+ repo standard; Cursor/Devin HITL extremes; multi-agent token economics ($47k vs $22.7k Iterathon); Goldman Sachs Devin pilot quantitative data; CrewAI 3× managerial overhead; mini-SWE-agent 79.2% with bash; Anthropic Skills progressive disclosure 30-50% savings; production trade-off matrix; comprehensive Q12 framework table with pricing/users |
| **Agent 3** | OSS framework code reading (22 frameworks at source, file/line citations) | `agents/agent-3-oss-code.md` | 50KB / 603 řádků | Per-framework agent file size table (15 → 485 lines); BMAD `customize.toml:13-15` merge rules quote; Magentic-One `_prompts.py:46-94`; OpenAI Handoff `__init__.py:94`; CrewAI Flow + human_feedback decorator file paths; 5 distinct pipeline paradigms in source code; opencode 149.7k★ phenomenon; Mastra 703 commits/30d top velocity; LangGraph "graphs are too expressive for YAML" position; meta-gen "no source-code precedent at scale" verdict |
| **Agent 4** | Community signals & adoption (HN, Reddit, X, podcasts, surveys, awesome-* lists) | `agents/agent-4-community.md` | 56KB / 492 řádků | Q5d primary contribution (top-15 plugins via quemsah index, 100% markdown; AGENTS.md adoption story); Augment Code "YAML > LLM control flow" most-cited line; multi-agent failure 41–86.7%; Stack Overflow 2025 trust decline 31% → 46%; Karpathy Dec-2025 customization stack thesis; CI/CD analogue Tekton/Argo YAML spaghetti warning; LangChain "quiet exit to raw SDKs" 2026 sentiment; BMAD viral packaging vs superpowers composable framing; Roo Code shutdown anomaly; community hot takes per Q1-Q9 |
| **Agent 5** | Official vendor docs (Anthropic / OpenAI / Google / Microsoft / Meta) with date stamps | `agents/agent-5-vendor-docs.md` | 48KB / 532 řádků | Vendor evolution timeline 2024-Q3 → 2026-Q1 (XML structured prompts → context engineering → less prescriptive engineering); 4-vendor comparison matrices per Q1-Q9; Anthropic 5-tier subagent priority canonical citation; OpenAI single-agent-first vs Anthropic+Google+Microsoft multi-agent-OK split; Microsoft Magentic 8-phase HITL events; OpenAI 100% schema compliance + Anthropic Nov-2025 grammar-restricted decoding; *"Going to YAML pipeline DSL would be unprecedented in major-vendor docs"* explicit gap; vendor migration timeline (Swarm → Agents SDK March 2025; AutoGen + SK → Agent Framework Oct 2025; Copilot Workspace → Coding Agent Sep 2025) |

**Triangulation density:** Q1, Q2, Q3, Q5d, Q6, Q7, Q12 covered by all 5 lenses. Q4, Q5a, Q5c, Q8, Q9, Q10, Q11 covered by 4–5 lenses. Q5b weakest cross-lens (academic acknowledged absence; OSS source confirms; production cites only proprietary vendor migrations without ROI numbers; community cites single-vendor self-reports; vendor publishes migration guides without ROI).

**Synthesis confidence:** HIGH for Q3, Q5a, Q5d, Q7, Q8, Q11 (multi-lens consensus, robust evidence). MEDIUM for Q1, Q2, Q4, Q5c, Q6, Q9, Q10, Q12 (multi-lens convergence ale s authoritative controversies preserved). LOW for Q5b (acknowledged evidence gap; prototype-and-measure recommended).

---

**End of Phase 2 synthesis.** Output je evidence map připravený jako vstup do Run 2 (deep-dive Top 10 frameworků z Q12 + Q22 cross-run paradigm synthesis), NIKOLI rozhodovací dokument pro ceos-agents v8.0.0. A.1 brainstorm performs the architectural decision with this evidence in hand.
