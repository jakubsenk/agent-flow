# Agent 1 — Academic Literature Lens — Report

**Lens:** Academic / arxiv / standardized benchmarks / research labs.
**Date:** 2026-04-26.
**Authoring agent:** Agent 1 of 5 (parallel forge-research run, sub-project A v8.0.0 of ceos-agents).

---

## Summary (5 bullets)

1. **Academia in 2025–2026 has decisively turned against "more agents = better."** The most cited recent empirical work (Kim et al., "Towards a Science of Scaling Agent Systems," arxiv 2512.08296, Dec 2025) shows that across general benchmarks, **single-agent systems outperform every multi-agent topology except decentralized at small scales**, with multi-agent systems incurring **58–515% coordination overhead** and **error-amplification factors of 4.4×–17.2×** versus a single-agent baseline. ceos-agents' current 21-agent shape is far above the "3–4 agent" capability ceiling identified.
2. **Reasoning-model era (post-o1, Sept 2024+) shifts the prompt-design optimum further toward terse role definitions plus runtime context discovery.** Anthropic's official Sept 29, 2025 guidance ("Effective context engineering") explicitly recommends "the minimal set of information that fully outlines your expected behavior" plus just-in-time loading of context via tools. The 2025 "Less Is More" mathematical-reasoning paper (arxiv 2604.18897) shows hard-accuracy plateaus at 60–79% despite 40+ prompt variants tested — additional prompt engineering yields diminishing returns past a saturation point.
3. **Empirical evidence on declarative vs. code-driven pipelines is now positive but narrow.** Daunis (PayPal, arxiv 2512.19769) reports 67% dev-time reduction, 74% LOC reduction, and accuracy improvement (78%→89%) using a declarative DSL for orchestration. But **the same paper documents a fundamental "expressiveness vs. safety" trade-off** and an increase in 10–20ms interpretation latency. The Open Agent Specification effort (arxiv 2510.04173, Oracle et al., Oct 2025) confirms cross-framework portability is now a viable design target with adapters for LangGraph, AutoGen, CrewAI, and WayFlow.
4. **The "GitHub stars ≠ adoption" finding is the most important Q12 caveat.** Wang et al. (arxiv 2512.01939, Dec 2025) shows MetaGPT (59.2k stars) had only 2 real-world adopting projects vs LangChain (119k stars / 105 projects) and CrewAI (40k / 19 projects). **Academic relevance and ecosystem maturity matter more than star momentum** for framework selection.
5. **Migration ROI evidence is weak** (Q5b). I found one direct case study (TF→JAX migration agent, arxiv 2603.27296) but **no academic case studies of declarative-pipeline-migration ROI in agent frameworks** (e.g., AutoGen→Magentic-One). Practitioner reports exist but not peer-reviewed migration ROI numbers. **Q5d ("public release expectations") is essentially out-of-academic-scope** — academia studies architectures, not user expectations of plugin customization mechanisms.

---

## Q1 — Agent system prompt depth (academic findings)

**The 2024-era best practice of long, role-heavy prompts is being challenged by 2025 evidence.**

### Key empirical findings

1. **Anthropic, "Effective context engineering for AI agents," Sept 29, 2025** (https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents)
   Direct quote: *"the minimal set of information that fully outlines your expected behavior. (Note that minimal does not necessarily mean short; you still need to give the agent sufficient information up front to ensure it adheres to the desired behavior.)"* Anthropic recommends starting "with a minimal prompt with the best model available" and adding only after testing. They favor *"just in time"* context loading via tools (file paths, queries) over front-loading all context.

2. **Liu, Wang, Willard, "Effects of Prompt Length on Domain-specific Tasks," arxiv 2502.14255 (Feb 2025)**
   Reported in search abstract: *"Short instructions negatively affect performances in all tasks compared to baseline performance, with significant decreases (e.g. precision dropping by 0.06 and 0.08 in certain areas). Long instructions generally improve performance metrics across all tasks on all experimented domains, with the biggest improvement in detail-sensitive tasks."* This **partially defends the "maximalist prompt" position** in domain-specific tasks. **Caveat:** the paper studies financial sentiment and monetary policy understanding — domain-narrow tasks where instructions disambiguate.

3. **"Less Is More: Cognitive Load and the Single-Prompt Ceiling in LLM Mathematical Reasoning," arxiv 2604.18897 (2025)**
   Searched 40+ prompt variants and found *"balanced hard accuracy plateaus in an empirical saturation region of approximately 60-79% despite substantial engineering effort."* — **a hard ceiling on prompt-engineering returns**.

4. **"Effects of Reasoning Length vs Accuracy" (multiple papers)**
   "Coding Agents are Effective Long-Context Processors" (arxiv 2603.20432) and the "How Well do LLMs Compress Their Own Chain-of-Thought" (arxiv 2503.01141) both find a **universal Pareto curve** between reasoning length and accuracy — reasoning length, rather than specific compression strategies, determines accuracy.

5. **"AgentArch: A Comprehensive Benchmark to Evaluate Agent Architectures in Enterprise," arxiv 2509.10769 (Sept 2025)**
   On enterprise tasks (3-agent and 9-agent workflows): *"Pass@K scores across all models and agentic configurations peak at 0.0634 indicating only a 6.34% chance of executing the workflow correctly in all 8 trials."* — **prompt depth alone cannot rescue agent reliability**.

### Reasoning-model era inflection point

The arrival of o1 (Sept 2024), o3, and Claude Sonnet/Opus extended thinking changes the calculus:

- **"A Comparative Study on Reasoning Patterns of OpenAI's o1 Model," arxiv 2410.13639** finds that o1's internal reasoning supersedes much of what previously had to be encoded in prompt as Chain-of-Thought scaffolding.
- "Efficient Reasoning Models: A Survey" (arxiv 2504.10903, April 2025) categorizes the field around three vectors: shorter (compressed CoT), smaller (compact specialized models), faster (efficient decoding). All three vectors **reduce the need for verbose prompt scaffolding**.
- The 2024 best practice was elaborate Chain-of-Thought instructions; 2025 evidence increasingly finds these are redundant or harmful for reasoning models.

### Synthesis for ceos-agents

ceos-agents' current 100–500 line prompts (e.g., reviewer.md ~133 lines, fixer.md ~117 lines) sit **above the median size implied by 2025 academic guidance**. The constraint blocks (NEVER rules, security boilerplate) and Process steps (numbered Read→Analyze→Implement→Build) are **not what the literature is criticizing** — they're load-bearing safety scaffolding. What 2025 academia *would* criticize is duplicated examples, multi-page output templates, and instructions duplicated from a CLAUDE.md the agent will read anyway.

**Academia ≠ practice divergence:** Practitioners often defend long prompts as "context insurance." Academic evidence (saturation curves, Pareto trade-offs) suggests this insurance has diminishing returns past a relatively low threshold.

---

## Q2 — Agent granularity (academic findings)

**The strongest 2025 academic finding: granularity should be predicted by task structure, not chosen by aesthetic preference.**

### Empirical foundation

1. **Strachan & Ying et al., "Predicting Multi-Agent Specialization via Task Parallelizability," arxiv 2503.15703 (March 2025)**
   *"Task parallelizability directly governs the effectiveness of generalist teams — when spatial or resource bottlenecks force agents to wait, specialist policies become more efficient."* The paper provides predictions for emergent behavior given team sizes and constraints.

2. **Kim et al., "Towards a Science of Scaling Agent Systems," arxiv 2512.08296 (Dec 2025)** — **most quantitatively important paper for Q2**
   Found:
   - *"Under fixed computational budgets, per-agent reasoning capacity becomes prohibitively thin beyond 3–4 agents."*
   - Reasoning turns follow **power-law scaling with exponent 1.724** (p<0.001).
   - On high-parallelizability tasks (Finance Agent): centralized MAS gives +80.9%, decentralized +74.5%.
   - On sequential-constraint tasks (PlanCraft): all MAS variants degrade -39% to -70%.
   - On tool-heavy tasks (Workbench, 16 tools): independent MAS -35%, decentralized +5.7%.
   - **Aggregate success rates**: SAS 46.6%, Independent MAS 37.0%, Decentralized 47.7%, Centralized 46.3%, Hybrid 45.2%.
   - **Error amplification factors** vs SAS baseline: Centralized 4.4×, Decentralized 7.8×, Hybrid 5.1×, Independent 17.2×.
   - **"Tasks where single-agent performance already exceeds 45% accuracy experience negative returns from additional agents."**

3. **Yin et al., "A Comprehensive Empirical Evaluation of Agent Frameworks on Code-centric Software Engineering Tasks," arxiv 2511.00872 (Nov 2025)**
   Across 7 frameworks (AgentOrchestra, OWL, SE-Agent, Trae, GPTswarm, OpenHands, SWE-Agent): *"single-agent systems outperformed multi-agent systems across all three tasks, contrary to intuitive expectations. The overhead of inter-agent coordination exceeded benefits from specialization."* Multi-agent token spending dominated by planning agents (65–67% of tokens).

4. **Xu et al., "Rethinking the Value of Multi-Agent Workflow: A Strong Single Agent Baseline," arxiv 2601.12307 (2025)**
   On HumanEval: single-agent OneFlow 92.1% vs AFlow multi-agent 90.1%. On GSM8K: 93.3% vs 93.6%. **Single-agent matched or exceeded multi-agent** at lower cost ($0.020 vs $0.026 on HumanEval).

5. **Bogavelli et al., "AgentArch," arxiv 2509.10769 (Sept 2025)**
   Found multi-agent advantage was **specifically in final-decision quality** (Sonnet 4: 84-87% with multi-agent function calling vs 72-76% single-agent) but single-agent dominated on overall scores.
   Critical: *"Variation in memory management styles and orchestration strategies (within multi-agent architectures) both had minimal impact on scores"* — **architectural choice within MAS matters less than the SAS/MAS choice itself**.

6. **Belcak et al. (NVIDIA), "Small Language Models are the Future of Agentic AI," arxiv 2506.02153 (June 2025, revised Sept 2025)**
   Argues *"language models perform a small number of specialized tasks repetitively and with little variation"* in agentic systems — **defends specialization at the model level**, not necessarily the agent level.

### Synthesis for ceos-agents

ceos-agents currently has 21 specialized agents (triage, code-analyst, fixer, reviewer, test-engineer, etc.). The Kim et al. capability ceiling is **3–4 agents** before per-agent context starves. ceos-agents survives this because:
- Most pipelines dispatch ≤6 agents sequentially per ticket (not in parallel)
- Each agent runs in a **fresh context window** (clean slate, no accumulated noise)

This sequential, fresh-context dispatch pattern is **closer to a "single large agent run as multiple stages"** than to a true multi-agent system. **Academia would call this a single-agent pipeline with role-switching, not a multi-agent system.** This is closer to Magentic-One's orchestrator-led design (ArXiv 2411.04468, GAIA 38% completion) than to AutoGen group-chat anti-patterns.

**Practical recommendation grounded in evidence:** The current 21-agent shape is defensible *because* dispatch is sequential and stateless. Granularity per stage (e.g., should triage and code-analyst be merged?) is a separate question — Yin et al. (arxiv 2511.00872) finds **planning agents consume 65-67% of tokens in multi-agent SE systems**, suggesting consolidation candidates: triage+code-analyst, test-engineer+e2e-test-engineer, reproducer+browser-verifier.

**Where academia and practice diverge:** Practitioner forums (BMAD, CrewAI tutorials) advocate elaborate role hierarchies (PM + Architect + Dev + QA + …). Academic evidence (Kim et al., Yin et al., Xu et al.) finds these consistently underperform single-agent baselines on actual benchmarks.

---

## Q3 — Universal vs per-project vs hybrid agent (academic findings)

**Limited direct academic evidence; existing data favors generic core + lightweight project-specific tail (the hybrid).**

### Findings

1. **"Agent Fine-tuning through Distillation for Domain-specific LLMs in Microdomains," arxiv 2510.00482 (Oct 2025)**
   Found that **lightweight fine-tuning + RAG with small domain-example sets** achieves results comparable to fully domain-fine-tuned systems. Suggests **per-project specialization at the prompt-overlay level can substitute for full per-project agents.**

2. **"Agent Data Protocol: Unifying Datasets for Diverse, Effective Fine-tuning of LLM Agents," arxiv 2510.24702 (Oct 2025)**
   *"ADP consistently outperforms task-specific tuning on the target task and avoids negative transfer that single-domain tuning often induces on other tasks. On SWE-Bench, ADP trained Qwen-2.5-7B-Instruct achieves 10.4%, versus 1.0% with SWE-smith Only."* — **negative transfer is a real risk** of fully per-project agents.

3. **"AgentScope 1.0: A Developer-Centric Framework," arxiv 2508.16279 (Aug 2025)**
   Inheritance-based agent composition via `StateModule` base class; supports inheritance plus per-attribute overlay. Validates a hybrid architecture pattern at the framework level.

4. **"Authenticated Workflows: A Systems Approach," arxiv 2602.10465**
   Documents an `extends` field semantics for inheriting and refining policies — *"each child policy refines its parent by adding restrictions"* — a pattern directly analogous to ceos-agents' `Agent Overrides` append-to-prompt.

5. **NVIDIA SLM paper (arxiv 2506.02153)** advocates *"heterogeneous agentic systems (i.e., agents invoking multiple different models)"* — implies a hybrid where generic agents call out to specialized SLMs/LLMs as needed, **not** wholly per-project agents.

### Synthesis for ceos-agents

There is **no academic study directly comparing fully-generic vs fully-per-project vs hybrid agent architectures**. The closest analog is fine-tuning literature, which says:
- Single-domain specialization risks negative transfer (ADP paper).
- Lightweight overlay of generic with project-specific delta is competitive (Distillation paper).
- Hybrid (heterogeneous) is what production-grade frameworks (AgentScope, Authenticated Workflows) implement.

ceos-agents' current `Agent Overrides` (generic + append) **matches the academic consensus** for hybrid composition. Pure per-project would invite negative transfer; pure generic limits expressiveness for niche stacks (Oracle PL/SQL, etc.).

**No-evidence-found note:** No academic paper specifically tested fully-per-project agent definitions vs generic+overlay in a side-by-side benchmark. This is a gap.

---

## Q4 — Stateful vs stateless agents (academic findings)

**2025 academic evidence is split, but a strong recent paper argues stateless wins for enterprise scale.**

### Findings

1. **"Stateless Decision Memory for Enterprise AI Agents," arxiv 2604.20158 (2026)** — **the most direct paper for Q4**
   Abstract findings:
   - *"Stateful memory architectures violate enterprise deployment properties by construction, which explains enterprise's practical preference for retrieval pipelines despite retrieval's inferior decision-alignment performance."*
   - Their stateless DPM (Deterministic Projection Memory) is *"7-15× faster at binding budgets, making one LLM call at decision time instead of N. DPM logs two LLM calls per decision while summarization logs 83-97 on LongHorizon-Bench."*
   - **"Statelessness is attainable in an agent-memory substrate without paying the decision-quality penalty retrieval pays."**

2. **"AMA-Bench: Evaluating Long-Horizon Memory for Agentic Applications," arxiv 2602.22769**
   Establishes that long-horizon memory is needed for some agent classes — but the paper focuses on conversational agents, not pipeline-style code agents.

3. **"Hindsight is 20/20: Building Agent Memory that Retains, Recalls, and Reflects," arxiv 2512.12818 (Dec 2025)**
   Reports state-of-the-art results on memory-bench tasks. Memory mattered for personal-assistant style agents.

4. **Anthropic Claude Code subagents documentation** (https://anthropic.skilljar.com/introduction-to-subagents)
   Direct quote (June 2025): *"Subagents prevent context bloat by isolating exploration in clean context windows, returning only summaries."* — Anthropic's design favors **per-dispatch fresh context** (stateless from the parent's perspective).

5. **"AgentScope 1.0," arxiv 2508.16279**
   Implements `state_dict` and `load_state_dict` for explicit state serialization — but this is opt-in per-StateModule, not default.

### Reasoning-model era impact

The post-o1 era complicates the picture. Reasoning models accumulate large "thinking" traces *within* a single dispatch. There is academic interest in whether stateful agents with persistent thinking traces outperform stateless ones — but as of 2026-04, no paper isolates this variable cleanly.

### Synthesis for ceos-agents

ceos-agents' design (stateless agents, explicit state passed via files like `.ceos-agents/state.json` and `pipeline-history.md`) **aligns with the 2026 stateless-memory enterprise paper**. The pipeline-history mechanism (last 5 entries for fixer, last 10 for reviewer) is a **bounded retrieval pattern**, not stateful memory.

**Practical evidence:** Anthropic's official subagents pattern (clean context per dispatch) and the Stateless Decision Memory paper both support keeping ceos-agents stateless. The cost (re-loading context per dispatch) is academically defensible.

**Where academia and practice diverge:** Many practitioner frameworks (CrewAI threads, AutoGen GroupChat memory, LangGraph state) provide stateful agent threads. Academic evidence increasingly says these are **not necessary for the per-stage role-switching pipeline pattern** that ceos-agents uses.

---

## Q5a — Pipeline shape diversity (academic studies)

**Academia confirms there is genuine architectural diversity in production frameworks, with no dominant winner.**

### Direct evidence

1. **Martinez & Franch, "Dissecting the SWE-Bench Leaderboards," arxiv 2506.17208 (2025)**
   Identifies **7 architectural groups (G1–G7)** among SWE-Bench submitters. Three execution patterns: *fixed execution* (deterministic pipelines), *scaffolded execution* (structured stages with local autonomy), *emergent autonomy* (fully dynamic). Key finding: *"high-performing submissions follow a variety of architectural strategies"* — **no single architecture dominates**.
   - Distribution: 67% of Lite entries open-source, 52% of Verified entries open-source.
   - Industry vs academic: median 51.8% (industry small companies, Verified) vs 31.5% (academic, Verified).

2. **"AgentArch," arxiv 2509.10769 (Sept 2025)**
   Tested 3 orchestration strategies (orchestrator-isolated, orchestrator-open, single-agent) and found:
   - *"Variation in memory management styles and orchestration strategies (within multi-agent architectures) both had minimal impact on scores."*
   - **Models peaked on different configurations between use cases — no universal optimum.**

3. **Yin et al., arxiv 2511.00872 (Nov 2025)**
   7 frameworks evaluated, 3 architectural layers identified (Orchestration & Reasoning, Collaborative Role, Tool Augmentation). Wide diversity in pipeline shape; no dominant pattern.

4. **"Towards a Science of Scaling Agent Systems," arxiv 2512.08296**
   Mixed-effects model **explains 51.3% of performance variance through coordination metrics** — *"empirical coordination metrics" predict optimal architecture better than "categorical architecture labels alone (43% variance explained)"*. **Architecture choice is task-conditional, not universal.**

5. **"Open Agent Specification (Agent Spec)," arxiv 2510.04173 (Oct 2025)**
   Demonstrates that the *same agent specification* can be executed across LangGraph, CrewAI, AutoGen, and WayFlow — implying frameworks are converging on *expressible* common abstractions despite surface-level diversity.

### Pipeline-shape matrix (academic synthesis)

| Framework | Pipeline shape | Stateful? | Academic positioning |
|---|---|---|---|
| AutoGen | Conversation/group-chat | Yes (per-agent) | Conversational; underperforms on code (Yin et al.) |
| CrewAI | Hierarchical role tree | Yes | Process-driven; lacks param validation per Wang et al. arxiv 2512.01939 |
| LangGraph | DAG/state-machine | Yes (shared state) | Most explicit graph; Agent Spec adapter target |
| MetaGPT | Code-generation chain | Yes | Decomposition susceptible to RAG deviation per arxiv 2512.01939 |
| Magentic-One | Orchestrator-led | Yes | 38% on GAIA (arxiv 2411.04468) |
| OpenHands | ReAct-loop | No (per-step) | 70.8% Verified per arxiv 2506.17208 |
| SWE-Agent | Single-agent scaffold | No | 66% Verified per arxiv 2506.17208 |
| AgentScope | Inheritance-composed | Configurable | Explicit StateModule base (arxiv 2508.16279) |
| Strands Agents | Model-driven loop | Optional | AWS reference; minimal scaffolding |
| OpenAI Agents SDK | Sequential agent loop | Session memory | Production-ready evolution of Swarm (March 2025) |

**Conclusion for Q5a:** The diversity is real. Academic evidence supports **multiple defensible shapes** rather than one winner. ceos-agents' "scaffolded execution" (sequential markdown stages) is a recognized pattern in Martinez & Franch's taxonomy.

---

## Q5b — Migration ROI evidence (academic case studies)

**This is the weakest evidence area. Academic literature has minimal direct migration-ROI data.**

### What evidence exists

1. **"A Multi-agent AI System for Deep Learning Model Migration from TensorFlow to JAX," arxiv 2603.27296**
   This is *agents performing a migration* — not framework migration ROI. Reported: *"allows landing reworked models in a fraction of the time compared to manual migration."* Quantitative number: "fraction of the time" — vague.

2. **Daunis (PayPal), arxiv 2512.19769 (Nov 2025)** — **closest direct evidence**
   Reported migration from imperative to declarative DSL:
   - 67% reduction in development time (48 → 16 hours)
   - 76% faster modifications (8.5 → 2.0 hours)
   - 74% fewer lines of code (220 vs 850 lines)
   - Task success: 78% → 89%
   - Steps to completion: -30%
   - P95 latency: 185ms vs 240ms baseline
   - **Caveat:** This is a single industry case study from PayPal, not a peer-reviewed migration cost study.

3. **"Open Agent Specification" (arxiv 2510.04173)** — *intends* to enable migration but provides no migration ROI numbers; only adapter coverage for LangGraph, AutoGen, CrewAI, WayFlow.

4. **Wang et al., arxiv 2512.01939 (Dec 2025)** — adoption study
   Found: *"96% of top-starred projects adopt multiple frameworks, highlighting that a single framework can no longer meet the complex needs of agent systems."* — implies **migration costs are real but absorbed by multi-framework composition**, not single-framework switches.
   Documented per-framework migration pain: *"LangChain/AutoGen: highest maintenance complexity despite maturity; breaking API changes during upgrades. CrewAI: strict version pinning causes multi-framework collaboration conflicts."*

### Practitioner-side claims (clearly noted as non-academic)

- BMAD evolution from BMAD-METHOD v1 → v2 (community-driven, no academic case study).
- AutoGen → AutoGen v0.4 actor-model rebuild (Jan 2025) — Microsoft blog claim; no academic ROI study.
- Magentic-One built on top of AutoGen — no migration cost reported.

### Synthesis for ceos-agents

**No academic case study exists for migrations like markdown→declarative or generic→meta-gen agents.** The closest is the PayPal DSL paper (single sample, single org) and the Wang et al. adoption survey (which says framework switches are rare; composition is the norm).

**Honest finding:** ceos-agents has **no academic precedent to draw migration-ROI from**. Any v8 architecture decision will be evidence-light on this dimension. Practical implication: prototype-and-measure is more honest than citing an academic ROI number.

---

## Q5c — LLM-as-config-interpreter reliability (papers)

**2025 evidence is concrete and improving rapidly. Constrained decoding + structured outputs achieve high reliability; unstructured "LLM-as-config-interpreter" lags.**

### Direct evidence

1. **"JSONSchemaBench: A Rigorous Benchmark of Structured Outputs for Language Models," arxiv 2501.10868 (Jan 2025)**
   ~10,000 real-world JSON schemas. Establishes constrained decoding as *"the dominant technology for enforcing structured outputs during generation."* Reports baseline reliability across frontier models.

2. **"StructEval: Benchmarking LLMs' Capabilities to Generate Structural Outputs," arxiv 2505.20139 (May 2025)**
   18 formats (JSON, YAML, CSV, HTML, React, SVG), 44 task types. Reports format-adherence and structural-correctness metrics across models.

3. **"RL-Struct: A Lightweight Reinforcement Learning Framework for Reliable Structured Output," arxiv 2512.00319 (Dec 2025)**
   *"89.7% structural accuracy and 92.1% validity on complex JSON tasks, significantly outperforming SFT and zero-shot baselines."*

4. **"STED and Consistency Scoring," arxiv 2512.23712 (Dec 2025)**
   Documents that **frontier models still produce inconsistent structured outputs across runs** even when individually valid — an under-reported reliability issue for "LLM as config interpreter" patterns.

5. **"Natural Language Tools: A Natural Language Approach to Tool Calling," arxiv 2510.14453 (Oct 2025)**
   Found: *"structured formats in tool calling may come with significant drawbacks, as structured formats require models to simultaneously handle multiple competing demands: understanding the query, selecting appropriate tools, adhering to format constraints, and generating a response."* — suggests **LLM-as-prose-interpreter (markdown) may be more reliable than LLM-as-JSON-config-interpreter** for some agent control flows.

6. **"AgentArch," arxiv 2509.10769** (already cited)
   *"Function calling outperformed ReAct across most models. Hallucination patterns: hallucinations for all models (except GPT-4o) were found exclusively under ReAct settings."* — **structured function calling is more reliable than free-form ReAct prose for agent control**.

7. **"DSPy: Compiling Declarative Language Model Calls" (foundation paper) and follow-ups**
   "Is It Time To Treat Prompts As Code?" arxiv 2507.03620 reports **routing accuracy 90.47% after CustomMIPROv2 optimization** in DSPy.

### Reasoning-model era impact

o3/o4 reasoning models reportedly produce more reliable structured outputs (less format drift), though I found no peer-reviewed benchmark isolating this. Anthropic Claude 4.x extended thinking similarly.

### Synthesis for ceos-agents

The ceos-agents pattern of **markdown-prose agent definitions + Bash dispatch + state.json** sits in an interesting middle ground:
- Agent definitions (markdown) are LLM-as-skill-executor — high reliability per Natural Language Tools paper.
- State files (.ceos-agents/state.json) are LLM-as-structured-writer — modern tools achieve 89-92% reliability per RL-Struct.
- Pipeline dispatch (Bash if/then in skills) is **deterministic, not LLM-driven** — 100% reliability.

**The current architecture has high inherent reliability because LLM-driven decisions are bounded.** A meta-gen architecture (LLM generates pipeline) introduces an LLM-as-config-interpreter step that 2025 evidence suggests is **the weakest link**.

**Recommendation grounded in evidence:** If declarative DSL is adopted (per Daunis/PayPal), keep dispatch logic *interpreted by a deterministic runtime*, not an LLM. The Open Agent Specification (arxiv 2510.04173) approach — declarative spec + deterministic adapter to runtime — is academically defensible.

**Where academia and practice diverge:** Practitioners often say "let the LLM figure out the workflow." Academic evidence (AgentArch ReAct hallucinations, Pass@K = 6.34% at 8 trials) says this is unreliable at scale.

---

## Q5d — Public release expectations (out of academic scope)

**This question is largely outside academic literature.** Academia studies architectures, performance, reliability — not user expectations of plugin customization mechanisms.

### What academic adjacency exists

1. **Wang et al., arxiv 2512.01939 (Dec 2025)** — adoption practices
   Surveyed agent developer practices. Findings most relevant to Q5d:
   - *"96% of top-starred projects adopt multiple frameworks"* — users expect composability over single-framework lock-in.
   - **Common failure modes:** Logic failures 25.6%, performance 25%, version conflicts 23.5%, tool integration 14%. — Users expect reliability around these failure axes.
   - *"Developers should prioritize factors like ecosystem maturity and maintenance activity over GitHub stars."*

2. **OpenAI Agents SDK release (March 2025)** — minimalist 4-primitive design (Agents, Handoffs, Guardrails, Sessions) signals where the industry consensus is heading: **fewer primitives, simpler mental models**.

3. **AgentScope 1.0 paper (arxiv 2508.16279)** — implements *"non-invasive customization"* and automated state persistence as design goals, signaling academic recognition that customization is a usability requirement.

### Honest scope finding

The literature does **not** answer:
- What plugin customization mechanism do top adopted plugins use?
- Do users prefer YAML, JSON, markdown, or Python hooks?
- What's the HN/Reddit/X sentiment on agent customization?

**These are properly answered by Agent 4 (community signals) and Agent 5 (vendor guidance).** I defer.

---

## Q6 — Human-in-the-loop placement (academic findings)

### Direct evidence

1. **Feng, McDonald, Zhang (UW), "Levels of Autonomy for AI Agents," arxiv 2506.12469 (June 2025)**
   Five-level framework:
   - L1 Operator — user always in charge
   - L2 Collaborator — frequent communication
   - L3 Consultant — agent leads, user advises strategically
   - L4 Approver — agent autonomous, user approves consequential actions
   - L5 Observer — fully autonomous

   *"The risks of L5 agents may outweigh benefits in most cases."* L4 is recommended for *"tasks with high amounts of lower-stakes decision-making."* **No empirical user-trust data** in this paper — it is a conceptual framework only.

2. **"Optimizing Agent Planning for Security and Autonomy," arxiv 2602.11416**
   Introduces **autonomy metrics quantifying the fraction of consequential actions an agent can execute without HITL approval while preserving security.** First formal quantification of HITL placement vs security.

3. **"Measuring AI Agent Autonomy: Towards a Scalable Approach with Code Inspection," arxiv 2502.15212 (Feb 2025)**
   Operationalizes three classes: in-the-loop, on-the-loop, off-the-loop. Provides code-inspection methodology for classifying existing agents.

4. **"The 2025 AI Agent Index," arxiv 2602.17753 (Feb 2026)**
   Categorizes deployed agents on six dimensions including approval requirements. **Empirical census** of what HITL patterns are actually used in production agents.

5. **"AI Agent Systems: Architectures, Applications, and Evaluation," arxiv 2601.01743 (2026)**
   *"An emerging best practice is to explicitly separate planning from execution, where a planner proposes a plan with explicit constraints while an executor carries out the plan under stricter tool permissions, supporting human-in-the-loop approval for high-impact steps."*

6. **"Design Patterns for Securing LLM Agents against Prompt Injections," arxiv 2506.08837 (June 2025)**
   The "plan-then-execute" pattern: agent forms a fixed plan upfront; HITL reviews plan; execution proceeds without further LLM-driven decisions. **Reduces attack surface and HITL burden simultaneously.**

### Synthesis for ceos-agents

ceos-agents' current **strategic-gate pattern** (NEEDS_DECOMPOSITION at fixer, acceptance gate after AC≥3, NEEDS_CLARIFICATION in fixer/triage) maps to **L3 Consultant / L4 Approver** in Feng et al.'s taxonomy. This is academically defensible.

**Empirical recommendation:** Plan-then-execute (Design Patterns paper) maps onto ceos-agents pipeline naturally — triage+code-analyst form the plan, fixer+reviewer execute. The HITL gate **between planning and execution** (after architect, before fixer) would be the strongest academic-literature-aligned placement.

**Where academia and practice diverge:** Many practitioners advocate "gate every stage." Feng et al. (and security-design papers) suggest **minimal gates at high-leverage decision points** is more robust.

---

## Q7 — Sub-agent dispatch vs in-agent tool-use (academic findings)

### Direct evidence

1. **Anthropic, Claude Code subagents docs** (https://anthropic.skilljar.com/introduction-to-subagents)
   *"Subagents are useful for side work you want to keep out of the main session, like repo exploration, docs lookup, test runs, and result validation."* But: *"Subagents are not a good fit for every task. They come with setup, handoff, and context overhead. For small edits, tightly coupled work, or tasks that need constant back-and-forth, it usually makes more sense to stay in the main conversation."* And: agent teams (peer coordination) *"can use about 7× more tokens in plan-heavy workflows."*

2. **"AOrchestra: Automating Sub-Agent Creation for Agentic Orchestration," arxiv 2602.03786**
   *"Multi-agent collaboration often incurs substantial coordination overhead and provides limited control over context routing, leading to either noisy over-sharing or harmful omission of critical information."* Their dynamic dispatch achieves *"16.28% relative improvement against the strongest baseline."*

3. **"Towards a Science of Scaling Agent Systems," arxiv 2512.08296** — already cited
   *"Hybrid systems show 5-15% coordination overhead, with additional messages yielding diminishing returns. The tool-coordination trade-off arises because multi-agent systems fragment the per-agent token budget, leaving insufficient capacity for complex tool orchestration."*

4. **Yin et al., arxiv 2511.00872** — already cited
   Found planning agents in multi-agent systems consume 65–67% of tokens — the dispatch overhead is substantial.

5. **"Small Model as Master Orchestrator: Learning Unified Agent-Tool Orchestration," arxiv 2604.17009**
   ToolOrchestra trains a *lightweight orchestrator* that decides between tool calls and sub-agent dispatch dynamically. Suggests the right answer is **task-dependent, not architectural**.

### Microservices analogy

The user prompt asked about a microservices-vs-monolith analogy. Academia rarely makes this analogy explicitly, but the trade-offs map closely:
- **Sub-agent dispatch** = microservice call (network overhead, context loss, integration complexity)
- **In-agent tool use** = monolith function call (no overhead, full context, less modular)

The academic verdict aligns with software architecture: **dispatch when the work is sufficiently isolated and reused**; tool-use when context coupling is high.

### Synthesis for ceos-agents

ceos-agents' current pattern (skills dispatch agents via Task tool; agents use Bash/Read/Edit directly inside their context) **aligns with the academic hybrid recommendation**. Browser-verifier as a sub-agent makes sense (clean context, isolated tool budget); browser-verifier as a fixer-internal step would bloat fixer's context.

**Specific guidance from evidence:** Reproducer is borderline. If reproducer needs <5 tool calls and shares context with fixer's analysis, in-agent is cheaper. If reproducer needs Playwright + fresh browser context, sub-agent dispatch is justified by Anthropic's "isolation" argument.

---

## Q8 — Generic+overlay vs per-project vs meta-gen (cross-cutting; academic angle)

This question is partially answered by Q3. Academic evidence relevant specifically to **meta-gen**:

1. **"ADAS introduces meta-agents that automatically design agent architectures through code generation"** (cited in arxiv 2601.22037)
2. **"MetaGen: Self-Evolving Roles and Topologies for Multi-Agent LLM Reasoning," arxiv 2601.19290**
   *"Task mismatch arises because task granularity, tool preferences, and error modes vary widely, while a fixed role set is often brittle under distribution shift. MetaGen is a training-free framework that adapts both the role space and the collaboration topology at test time."*
3. **"MetaSynth: Meta-Prompting-Driven Agentic Scaffolds," arxiv 2504.12563**
   Meta-prompting orchestrates expert LLMs to generate diverse data — analogous to meta-gen for agents.
4. **"The Meta-Prompting Protocol," arxiv 2512.15053 (Dec 2025)**
   Three-agent Adversarial Trinity (Generator/Auditor/Optimizer) for self-improving meta-prompting.

**Honest finding:** Meta-gen at the *agent-architecture-generation* level (per ceos-agents Q8 framing) is **emerging research, not established practice**. Academic evidence shows it's possible (MetaGen, ADAS) but not yet shown to outperform well-tuned static architectures on standard benchmarks.

**Recommendation for ceos-agents v8:** Meta-gen is **highest-risk, lowest-evidence** of the three options. Generic+overlay (Q3) has the strongest direct academic support.

---

## Q9 — Pipeline as config DSL expressiveness (academic angle)

Already partially covered in Q5c. Direct evidence on DSL expressiveness levels:

1. **Daunis (PayPal), arxiv 2512.19769** — **most direct paper**
   Identifies three trade-offs explicitly:
   - *"Expressiveness vs. Safety: The DSL intentionally restricts operations like unbounded recursion, arbitrary code execution to prevent malformed pipelines."*
   - *"Performance vs. Flexibility: Interpretation overhead adds 10-20ms latency."*
   - *"Abstraction vs. Control: Tool abstractions simplify common cases but require escape hatches (custom functions) for fine-grained LLM control."*
   - **Documented failure modes:** lack of native RL support, poor long-term memory across sessions, "stack traces through nested pipelines and async tool calls obscure error origins."

2. **"Open Agent Specification" (arxiv 2510.04173)** — provides a *declarative, framework-agnostic* specification but does **not** push toward Turing-completeness. The Q9 framing of "graph-based vs Turing-complete" is **not represented in academic literature** for agents — the academic preference is bounded DSL with escape hatches.

3. **"A Declarative Language for LLM Agent Workflows" (Daunis paper above)**
   Quantitative DSL benefits: 67% dev-time reduction, 74% LOC reduction, accuracy 78%→89%.

### Lessons from non-agent DSL history (cited only as analogy)

Academic literature on Jenkins Jobs DSL, GitHub Actions, Argo Workflows is sparse but consistent: **expressiveness creep into Turing-complete territory is consistently reported as a maintenance liability** in software engineering literature broadly. No agent-framework-specific paper makes this claim peer-reviewed.

### Synthesis

**Sweet spot per academic evidence:** YAML with conditional logic + escape hatches to user-supplied code or markdown agents. Avoid Turing-complete DSL until empirical evidence justifies it.

---

## Q10 — Benchmarking metrics (academic findings)

### Established benchmarks academia uses

1. **SWE-bench / SWE-bench Verified** (Jimenez et al., 2023; Verified released by OpenAI, Aug 2024)
   - Top-1 (May 2026): Claude Opus 4.5 + Live-SWE-agent **79.2%** on Verified.
   - Augment Code 72.0%, OpenHands+CodeAct v3 68.4%.
   - Devin 2.0: 45.8% on Verified.
   - Origin paper: arxiv 2310.06770.

2. **HumanEval** — code generation; saturating, less informative for agents.

3. **GAIA** (arxiv 2311.12983) — 466 multi-modal questions for general AI assistants. Magentic-One: 38%.

4. **AgentBench** (arxiv 2308.03688) — 8 environments evaluating LLMs as agents.

5. **MLE-Bench** (arxiv 2410.07095) — ML engineering tasks.

6. **AgentArch** (arxiv 2509.10769) — enterprise agent architecture comparison; **Pass@K peaks at 0.0634**.

7. **Mle-bench, ML-Bench, MLAgentBench, SUPER** — domain-specific.

8. **AMA-Bench** (arxiv 2602.22769) — long-horizon memory.

9. **τ²-Bench, BIRD-SQL, SimpleQA Verified** — used by Open Agent Specification (arxiv 2510.04173) for cross-framework evaluation.

10. **NL2Repo-Bench** (arxiv 2512.12730) — long-horizon repository generation.

11. **AgentDojo, Agent Security Bench** — security-focused (arxiv 2510.05244).

### Key metrics academia reports

| Metric | Common in academic papers | Notes for ceos-agents |
|---|---|---|
| Resolution rate / Pass@1 | Yes (universal) | Direct analog: % of bug tickets that produce a merged PR |
| Pass@K (K=8) | AgentArch | Reliability under repeated trials |
| Token cost per task | Increasingly common (arxiv 2511.17006, 2508.02694) | Already tracked in v6.8.0 metrics |
| Time-to-resolution / wall-clock | Sometimes (OpenHands papers) | Already tracked |
| Coordination overhead % | Kim et al. arxiv 2512.08296 | Could be measured (token spend on dispatch vs work) |
| Error amplification factor | Kim et al. | New metric ceos could compute from history |
| Clarification rate | Almost never (academic gap) | ceos has data — could publish |
| Regression rate | Rare | Verify-after-PR-merge captures this |
| Pass@K reliability | Becoming standard | ceos-agents could measure via repeated runs |

### What ceos-agents can measure (evidence-grounded)

- Stage-level token cost (already in v6.8.0).
- Clarification rate (already in `clarification` state object).
- Block reasons by agent (already in pipeline-history.md).
- AC fulfillment rate (already in reviewer output).
- **Missing but valuable:** Pass@K reliability (run same ticket N times; measure variance) — most academic agent work uses this.

---

## Q11 — Trade-off matrix template (academic-evidence-based)

Below: each cell cites the academic source of its score. **L = Low, M = Medium, H = High.** Values are ordinal, evidence-grounded.

### Generic+overlay (current ceos-agents)

| Dimension | Score | Evidence |
|---|---|---|
| Onboarding cost | L | Empirical: ceos's `Agent Overrides` parallels AgentScope's StateModule (arxiv 2508.16279) — proven low-friction |
| Token cost | L–M | Single fresh-context dispatch; no multi-agent overhead per Kim et al. (arxiv 2512.08296) |
| Maintenance burden | L | Lightweight overlay matches Distillation paper findings (arxiv 2510.00482) |
| Customization power | M | Append-to-prompt is academically validated (Authenticated Workflows extends pattern, arxiv 2602.10465) but limited |
| Error surface | L–M | Stateless + bounded retrieval matches Stateless Decision Memory paper (arxiv 2604.20158) recommendations |
| Public-release readiness | M | OOS-academic-scope; defer to Agent 4/5 |

### Per-project (each project ships own agent set)

| Dimension | Score | Evidence |
|---|---|---|
| Onboarding cost | H | Negative-transfer risk per ADP paper (arxiv 2510.24702): single-domain tuning hurts |
| Token cost | M–H | No reuse; each project retunes — no academic data |
| Maintenance burden | H | Wang et al. (arxiv 2512.01939): version drift across projects compounds |
| Customization power | H | Trivially full power |
| Error surface | H | No shared QA/testing; per-project bugs reinvent same mistakes |
| Public-release readiness | L | Confusing user story; no academic precedent |

### Meta-gen (LLM generates agents/pipelines per project)

| Dimension | Score | Evidence |
|---|---|---|
| Onboarding cost | L on first run, H over time | MetaGen (arxiv 2601.19290) shows feasibility; production data absent |
| Token cost | H | LLM-generation step adds non-trivial token spend; AgentArch 6.34% Pass@K reliability concern |
| Maintenance burden | H (research-grade) | ADAS, MetaGen, Meta-Prompting Protocol — all academic, none production-validated |
| Customization power | H (claimed) | Self-evolving role spaces |
| Error surface | H | LLM-as-config-interpreter weakest link per AgentArch hallucination findings |
| Public-release readiness | L | Bleeding-edge; users not ready |

### Verdict from academic angle

**Generic+overlay has the strongest combination of academic backing and known failure modes.** Per-project has weak academic backing (negative-transfer risk). Meta-gen is research-stage, not production-stage.

---

## Q12 — Framework shortlist contribution (academic relevance)

The other agents will surface practitioner-popular frameworks. My contribution is **frameworks that academia is actually studying**, with notable papers cited.

| Framework | GitHub URL | Academic relevance | Notable papers / academic citations |
|---|---|---|---|
| **LangGraph** | github.com/langchain-ai/langgraph | High — most adapter-targeted in academic specs | Open Agent Spec arxiv 2510.04173; Wang et al. adoption arxiv 2512.01939 (26 real adopters); intelligent Spark Agents arxiv 2412.01490 |
| **AutoGen** | github.com/microsoft/autogen | High — Microsoft's flagship, base for Magentic-One | Magentic-One arxiv 2411.04468; Wang et al. arxiv 2512.01939 (22 adopters); v0.4 actor model rebuild Jan 2025 |
| **Magentic-One** | github.com/microsoft/autogen/tree/main/python/packages/autogen-magentic-one | High — peer-reviewed Microsoft Research paper, GAIA 38% | arxiv 2411.04468 (Fourney et al., Microsoft Research) |
| **CrewAI** | github.com/crewAIInc/crewAI | Medium — production adoption signals | Wang et al. arxiv 2512.01939 (19 adopters); criticized for *"hierarchical task templates lack parameter validation and manual callbacks, reducing robustness"* |
| **MetaGPT** | github.com/geekan/MetaGPT | High academic citation, low adoption | Wang et al. arxiv 2512.01939 (only 2 adopters despite 59.2k stars); SE comparison arxiv 2511.00872 |
| **OpenHands (formerly OpenDevin)** | github.com/All-Hands-AI/OpenHands | Highest — top SE-bench performer | SWE-bench analysis arxiv 2506.17208 (70.8% Verified); Yin et al. arxiv 2511.00872 (best on SRDD) |
| **SWE-Agent** | github.com/SWE-agent/SWE-agent | High — Princeton lab, foundational | SWE-bench original arxiv 2310.06770; arxiv 2506.17208 dissection (66% Verified) |
| **AgentScope** | github.com/agentscope-ai/agentscope | High — peer-reviewed paper, novel state management | arxiv 2508.16279 (Aug 2025); StateModule inheritance pattern |
| **DSPy** | github.com/stanfordnlp/dspy | Highest — Stanford NLP, declarative LM programming | Original arxiv 2310.03714; "Is It Time To Treat Prompts As Code?" arxiv 2507.03620; GEPA optimizer (93% MATH) |
| **Strands Agents (AWS)** | github.com/strands-agents/sdk-python | Medium — AWS production deployments (Q Developer, Glue, VPC Reachability Analyzer); no peer-reviewed paper yet | AWS open-source blog May 2025 |
| **OpenAI Agents SDK** | github.com/openai/openai-agents-python | Medium — production-ready Swarm evolution; cited in many comparisons | OpenAI release March 2025; Mem0 review Dec 2025 |
| **Pydantic AI** | github.com/pydantic/pydantic-ai | Low academic, high practitioner adoption | Langfuse comparison March 2025; type-safety angle |
| **smolagents (HuggingFace)** | github.com/huggingface/smolagents | Medium — code-execution paradigm distinct from prose-ReAct | HF research blog; code-as-action paradigm |
| **AgentOrchestra (TEA protocol)** | github.com/SkyworkAI/agent-orchestra | Medium — recent paper proposes lifecycle protocol | arxiv 2506.12508 (Jan 2026); novel TEA abstraction |
| **WayFlow** | (Oracle) | Medium — reference runtime for Open Agent Spec | arxiv 2510.04173 |
| **Agno** | github.com/agno-agi/agno | Low academic, growing practitioner adoption | Langfuse comparison; SDK + managed platform |
| **BMAD-METHOD** | github.com/bmad-code-org/BMAD-METHOD | Low academic (no peer-reviewed paper); high practitioner attention | Sabaliauskas Medium analysis Oct 2025; Ziyu blog |
| **GPTswarm** | github.com/metauto-ai/GPTSwarm | Medium — best on vulnerability detection per arxiv 2511.00872 | arxiv 2402.16823 (original); Yin et al. arxiv 2511.00872 (77% vuln-detection accuracy) |
| **AutoCodeRover** | github.com/nus-apr/auto-code-rover | High — NUS academic team | arxiv 2404.05427 |
| **Agent Spec / WayFlow (Oracle)** | github.com/oracle/wayflow | Medium — declarative cross-framework standard | arxiv 2510.04173 (Oct 2025) — direct relevance to Q5/Q9 |

### Academic-angle highlights worth flagging to synthesizer

- **OpenHands and SWE-Agent are the only frameworks with consistently top-cited SWE-bench performance** in 2025 academic literature. ceos-agents should look at their architecture closely for sub-project A inspiration.
- **DSPy is the academic-endorsement leader for declarative-prompt-as-code** — most cited framework in 2025 papers on prompt optimization. If Q5 trends toward declarative, DSPy is the academic reference point.
- **MetaGPT and CrewAI have notable popularity-vs-adoption gaps** per Wang et al. arxiv 2512.01939 — be cautious about citing them as "successful" patterns.
- **Magentic-One is the most peer-reviewed multi-agent generalist system** (arxiv 2411.04468) — its orchestrator-led pattern is academically defensible.
- **AgentScope 1.0 (arxiv 2508.16279)** is the clearest academic reference for the inheritance/composition pattern that ceos-agents' Agent Overrides resembles.

---

## Open questions / no-evidence-found

These are areas where I genuinely could not surface academic evidence:

1. **Migration ROI for agent framework switches (Q5b).** No peer-reviewed case study exists comparing markdown-driven → declarative migrations specifically. The PayPal DSL paper (arxiv 2512.19769) is the closest but is a single industry case study from one organization.
2. **Plugin-customization mechanism preferences in users (Q5d).** Genuinely outside academic scope. Defer to community-signals agent.
3. **Reasoning-model (o1/o3/o4, Claude 4.x extended thinking) specific impact on agent prompt depth.** Multiple papers reference the era inflection but **no peer-reviewed paper isolates "how much shorter should prompts be with reasoning models?"** as of 2026-04.
4. **Direct fully-per-project vs hybrid agent benchmarks.** No academic study found. Inferred from fine-tuning literature (negative transfer) and AgentScope inheritance pattern.
5. **Long-horizon stateful pipeline runs vs stateless re-dispatch in agent systems specifically (not memory-bench tasks).** Academic literature focuses on conversational long-horizon; pipeline-style long-horizon is under-studied.
6. **HITL gate placement empirical user-trust data.** Feng et al. provides framework but no user studies. Major academic gap.
7. **Devin 2.0's actual scaffold details.** Devin 2.0 is mentioned in SWE-bench at 45.8% but proprietary scaffold is not academically described.

---

## Sources

All citations gathered, deduplicated. Format: `[Title](URL) — date — relevance`.

### Anthropic / vendor official
- [Effective context engineering for AI agents](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents) — Sept 29, 2025 — Q1, Q4
- [Claude Code subagents introduction](https://anthropic.skilljar.com/introduction-to-subagents) — 2025 — Q4, Q7
- [Prompting best practices](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices) — Claude API docs — Q1

### Foundational / framework papers
- [Magentic-One: A Generalist Multi-Agent System for Solving Complex Tasks](https://arxiv.org/abs/2411.04468) — Nov 2024, Microsoft Research — Q2, Q5a
- [AgentScope 1.0: A Developer-Centric Framework](https://arxiv.org/abs/2508.16279) — Aug 2025 — Q3, Q5a, Q12
- [Open Agent Specification (Agent Spec)](https://arxiv.org/abs/2510.04173) — Oct 2025 (rev Nov 2025), Oracle et al. — Q5a, Q5c, Q9, Q12
- [DSPy: Compiling Declarative Language Model Calls into Self-Improving Pipelines](https://arxiv.org/abs/2310.03714) — Stanford NLP — Q5c, Q12
- [SWE-bench origin paper](https://arxiv.org/abs/2310.06770) — Princeton — Q10, Q12
- [AgentBench](https://arxiv.org/abs/2308.03688) — Q10
- [GAIA benchmark](https://arxiv.org/abs/2311.12983) — Q10

### 2025–2026 empirical (most-cited in this report)
- [Towards a Science of Scaling Agent Systems](https://arxiv.org/html/2512.08296v1) — Kim et al. (Google Research, MIT, DeepMind), Dec 2025 — **central to Q2, Q5a, Q5c, Q7**
- [A Comprehensive Empirical Evaluation of Agent Frameworks on Code-centric Software Engineering Tasks](https://arxiv.org/html/2511.00872v1) — Yin et al., Nov 2025 — Q2, Q5a, Q12
- [AgentArch: A Comprehensive Benchmark to Evaluate Agent Architectures in Enterprise](https://arxiv.org/html/2509.10769v1) — Bogavelli et al., Sept 2025 — Q1, Q2, Q5c
- [An Empirical Study of Agent Developer Practices in AI Agent Frameworks](https://arxiv.org/html/2512.01939v1) — Wang et al., Dec 2025 — Q5b, Q5d, Q12
- [Dissecting the SWE-Bench Leaderboards](https://arxiv.org/html/2506.17208v2) — Martinez & Franch, 2025 — Q5a, Q12
- [Rethinking the Value of Multi-Agent Workflow: A Strong Single Agent Baseline](https://arxiv.org/pdf/2601.12307) — Xu et al., 2025 — Q2

### Prompt design / reasoning era
- [Effects of Prompt Length on Domain-specific Tasks for Large Language Models](https://arxiv.org/abs/2502.14255) — Liu, Wang, Willard, Feb 2025 — Q1
- [Less Is More: Cognitive Load and the Single-Prompt Ceiling in LLM Mathematical Reasoning](https://arxiv.org/abs/2604.18897) — 2025 — Q1
- [A Comparative Study on Reasoning Patterns of OpenAI's o1 Model](https://arxiv.org/html/2410.13639) — 2024 — Q1 reasoning era
- [Efficient Reasoning Models: A Survey](https://arxiv.org/abs/2504.10903) — April 2025 — Q1
- [Multi-Agent Design: Optimizing Agents with Better Prompts and Topologies](https://arxiv.org/html/2502.02533v1) — Zhou et al., Feb 2025 — Q2
- [Predicting Multi-Agent Specialization via Task Parallelizability](https://arxiv.org/pdf/2503.15703) — March 2025 — Q2

### Stateful vs stateless / memory
- [Stateless Decision Memory for Enterprise AI Agents](https://arxiv.org/abs/2604.20158) — 2026 — **central to Q4**
- [AMA-Bench: Evaluating Long-Horizon Memory for Agentic Applications](https://arxiv.org/html/2602.22769v1) — 2026 — Q4
- [Hindsight is 20/20: Building Agent Memory that Retains, Recalls, and Reflects](https://arxiv.org/html/2512.12818v1) — Dec 2025 — Q4

### HITL / autonomy
- [Levels of Autonomy for AI Agents](https://arxiv.org/html/2506.12469v1) — Feng et al. (UW), June 2025 — **central to Q6**
- [Optimizing Agent Planning for Security and Autonomy](https://arxiv.org/abs/2602.11416) — 2026 — Q6
- [Measuring AI Agent Autonomy: Towards a Scalable Approach with Code Inspection](https://arxiv.org/html/2502.15212v1) — Feb 2025 — Q6
- [The 2025 AI Agent Index Documenting Technical and Safety Features of Deployed Agentic AI Systems](https://arxiv.org/html/2602.17753v1) — 2026 — Q6, Q12

### Structured output / config interpreters / orchestration
- [JSONSchemaBench: A Rigorous Benchmark of Structured Outputs](https://arxiv.org/abs/2501.10868) — Jan 2025 — Q5c
- [StructEval: Benchmarking LLMs' Capabilities to Generate Structural Outputs](https://arxiv.org/html/2505.20139v1) — May 2025 — Q5c
- [STED and Consistency Scoring](https://arxiv.org/abs/2512.23712) — Dec 2025 — Q5c
- [Natural Language Tools: A Natural Language Approach to Tool Calling](https://arxiv.org/html/2510.14453v1) — Oct 2025 — Q5c
- [RL-Struct: A Lightweight Reinforcement Learning Framework for Reliable Structured Output](https://arxiv.org/html/2512.00319v2) — Dec 2025 — Q5c
- [A Declarative Language for Building And Orchestrating LLM-Powered Agent Workflows](https://arxiv.org/html/2512.19769) — Daunis (PayPal), Nov 2025 — **central to Q5b, Q9**
- [AOrchestra: Automating Sub-Agent Creation for Agentic Orchestration](https://arxiv.org/html/2602.03786v1) — 2026 — Q7
- [Small Model as Master Orchestrator: Learning Unified Agent-Tool Orchestration](https://arxiv.org/html/2604.17009) — Q7
- [AgentOrchestra: Orchestrating Multi-Agent Intelligence with the TEA Protocol](https://arxiv.org/abs/2506.12508) — June 2025 (rev Jan 2026) — Q12

### SLM / specialization / fine-tuning
- [Small Language Models are the Future of Agentic AI](https://arxiv.org/abs/2506.02153) — Belcak et al. (NVIDIA), June 2025 — Q2, Q3
- [Small Language Models for Agentic Systems: A Survey](https://arxiv.org/abs/2510.03847) — Sharma & Mehta, Oct 2025 — Q2
- [Agent Fine-tuning through Distillation for Domain-specific LLMs in Microdomains](https://arxiv.org/abs/2510.00482) — Oct 2025 — Q3
- [Agent Data Protocol: Unifying Datasets for Diverse, Effective Fine-tuning of LLM Agents](https://arxiv.org/html/2510.24702) — Oct 2025 — Q3

### Token cost / efficiency
- [Budget-Aware Tool-Use Enables Effective Agent Scaling](https://arxiv.org/html/2511.17006v1) — Nov 2025 — Q10
- [Efficient Agents: Building Effective Agents While Reducing Cost](https://arxiv.org/html/2508.02694v1) — Aug 2025 — Q10
- [Token-Budget-Aware LLM Reasoning](https://arxiv.org/pdf/2412.18547) — June 2025 — Q10
- [Reducing Cost of LLM Agents with Trajectory Reduction (AgentDiet)](https://arxiv.org/html/2509.23586) — Sept 2025 — Q10
- [SkillReducer: Optimizing LLM Agent Skills for Token Efficiency](https://arxiv.org/html/2603.29919) — Q10

### Meta-gen / self-evolving
- [MetaGen: Self-Evolving Roles and Topologies for Multi-Agent LLM Reasoning](https://arxiv.org/html/2601.19290) — 2026 — Q8
- [The Meta-Prompting Protocol: Orchestrating LLMs via Adversarial Feedback Loops](https://arxiv.org/html/2512.15053) — Dec 2025 — Q8
- [Optimizing Agentic Workflows using Meta-tools (ADAS)](https://arxiv.org/html/2601.22037v2) — Q8
- [MetaSynth: Meta-Prompting-Driven Agentic Scaffolds](https://arxiv.org/pdf/2504.12563) — Q8

### Security / multi-agent isolation (relevant to per-stage HITL placement)
- [Indirect Prompt Injections: Are Firewalls All You Need, or Stronger Benchmarks?](https://arxiv.org/html/2510.05244v1) — Oct 2025 — Q6, Q5c
- [Design Patterns for Securing LLM Agents against Prompt Injections](https://arxiv.org/html/2506.08837v3) — June 2025 — Q6
- [A Multi-Agent LLM Defense Pipeline Against Prompt Injection Attacks](https://arxiv.org/abs/2509.14285) — Dec 2025 — Q5c

### Practitioner-source comparisons (for Q12 framework triangulation)
- [Best AI Agent Frameworks in 2025 (Langwatch)](https://langwatch.ai/blog/best-ai-agent-frameworks-in-2025-comparing-langgraph-dspy-crewai-agno-and-more)
- [OpenAI Agents SDK Review (Mem0)](https://mem0.ai/blog/openai-agents-sdk-review)
- [Strands Agents AWS open-source blog](https://aws.amazon.com/blogs/opensource/introducing-strands-agents-an-open-source-ai-agents-sdk/)

### Other supporting papers cited
- [Coding Agents are Effective Long-Context Processors](https://arxiv.org/html/2603.20432v1) — Q1
- [Context Length Alone Hurts LLM Performance Despite Perfect Retrieval](https://arxiv.org/html/2510.05381v1) — 2025 — Q1
- [How Well do LLMs Compress Their Own Chain-of-Thought?](https://arxiv.org/html/2503.01141v1) — March 2025 — Q1
- [The Prompt Report: A Systematic Survey of Prompt Engineering Techniques](https://arxiv.org/abs/2406.06608) — 2025 — Q1
- [A Multi-agent AI System for Deep Learning Model Migration from TensorFlow to JAX](https://arxiv.org/html/2603.27296) — Q5b
- [LLM-Enabled Multi-Agent Systems: Empirical Evaluation and Insights into Emerging Design Patterns](https://arxiv.org/html/2601.03328v1) — Q5a
- [Evaluation and Benchmarking of LLM Agents: A Survey](https://arxiv.org/html/2507.21504v1) — July 2025 — Q10

---

**End of Agent 1 academic-lens report.**
