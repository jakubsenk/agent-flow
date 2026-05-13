# Agent 4 — Community Signals & Adoption Lens — Report

**Run:** `2026-04-26-A-research-run1` (Sub-projekt A — Agent Shape Rework, v8.0.0)
**Persona:** Community signals & adoption (HN / Reddit / X / podcasts / surveys)
**Cutoff:** 2026-04-26
**Hard rule applied:** Every claim cited; hype vs. adoption distinguished; Q5d = primary contributor

---

## Summary

- **Markdown + YAML frontmatter is the de-facto community standard for agent customization in 2026.** Anthropic's Agent Skills format crossed 20K stars on its reference repo within ~6 months and was adopted by Microsoft (VS Code/Copilot), Cursor, Goose, Amp, OpenCode, ChatGPT Codex (via AGENTS.md). [VentureBeat — Anthropic launches enterprise Agent Skills](https://venturebeat.com/technology/anthropic-launches-enterprise-agent-skills-and-opens-the-standard); [code.visualstudio.com agent-skills](https://code.visualstudio.com/docs/copilot/customization/agent-skills). The community has explicitly converged on `SKILL.md` (markdown + YAML frontmatter) as the portable unit.
- **Hype-vs-substance gap is widening on heavyweight orchestration frameworks.** LangChain abstraction backlash continues into 2026 with documented "quiet exit to raw SDKs" ([Ravoid — The LangChain Exit](https://ravoid.com/blog/langchain-exit-raw-sdk-migration-2026)); Microsoft *retired* AutoGen into maintenance mode Oct-2025 ([VentureBeat — Microsoft retires AutoGen](https://venturebeat.com/ai/microsoft-retires-autogen-and-debuts-agent-framework-to-unify-and-govern)); Roo Code (3M installs) **shut down on 2026-04-21** ([morphllm comparison](https://www.morphllm.com/comparisons/roo-code-vs-cline)). Survey-validated: only 14.1% of devs use AI agents *daily*, vs 51% who use AI tools daily — agent frameworks are a thinner slice than the marketing implies ([Stack Overflow Developer Survey 2025](https://survey.stackoverflow.co/2025/ai)).
- **For Q5d specifically: the canonical user expectation is "markdown overlay file in `.claude/agents/<name>.md` that overrides the plugin version."** This is the pattern Anthropic itself implements (project subagents override global; CLI flag overrides settings; settings.local.json overrides settings.json). Users explicitly resist forking. ceos-agents' `Agent Overrides` (append-to-prompt customization) is *aligned* with this expectation; the variant that breaks the expectation would be Per-project (forces full duplication).
- **BMAD-METHOD (43k–45k stars) demonstrates that "more agents + more docs + spec-first" is genuinely viral when packaged well**, but the v6 alpha rollout exposed real overhead/learning-curve criticism ([GH Discussion #979](https://github.com/bmad-code-org/BMAD-METHOD/discussions/979); [GH Issue #2003](https://github.com/bmad-code-org/BMAD-METHOD/issues/2003)). Counterpoint: Jesse Vincent's `superpowers` (165k stars on the awesome-claude-plugins index) takes the **opposite** approach — small composable skills, sub-agent dispatch, "VERY token light" core. Both succeed; differentiating factor is **whether the user can compose vs is forced to swallow the whole methodology**.
- **HN/Reddit consensus on declarative-vs-LLM control flow: code/YAML for deterministic flow, LLM for content.** Most quoted line in 2026 production write-ups: *"A YAML file with condition, loop, and stdin piping is infinitely more reliable than telling an LLM 'if the review is negative, go back to step 2, but only up to 3 times'"* ([Augment Code — Why multi-agent LLM systems fail](https://www.augmentcode.com/guides/why-multi-agent-llm-systems-fail-and-how-to-fix-them)). Empirical multi-agent failure rates: **41–86.7% in production** when orchestration is unstructured.

---

## Q1 — Prompt depth: what does the community recommend in 2026?

**Consensus: pragmatic middle ("Goldilocks zone"), not the extremes.** Anthropic's own Engineering blog frames this explicitly:

> "specific enough to guide behavior effectively, yet flexible enough to provide the model with strong heuristics" — [Anthropic Engineering — Effective context engineering for AI agents](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents)

Anthropic also explicitly warns against the maximalist extreme: *"hardcod[ing] complex, brittle logic"*, and against the minimalist extreme of *"vague guidance"*. They recommend: **start minimal, add clear instructions and examples based on observed failure modes during testing**. Same source: *"minimal does not necessarily mean short; you still need to give the agent sufficient information up front."*

**Empirical anchor on Claude Code itself:** an Arxiv paper from January 2026 disclosed that Claude Code's own production system prompt is **6,973 tokens** ([arxiv 2601.21233](https://arxiv.org/html/2601.21233v1)) — the meta-evidence is that Anthropic ships a *substantial* (not minimal) prompt for its flagship coding agent. This puts current ceos-agents agent prompts (100–500 lines markdown) well within the empirically validated range that Anthropic itself uses.

**Cost-side data:** Adding column descriptions to schema context grew prompt size from ~3,000 to ~7,000 tokens but improved accuracy from ~50% to ~65% — **a 130% prompt-size growth for 30% accuracy gain** ([fast.io — AI Agent Token Cost Optimization 2026](https://fast.io/resources/ai-agent-token-cost-optimization/)). Community recommends using **prompt caching** (89.5% reduction on 5K-token system prompts across 200 calls) to make the trade-off acceptable.

**Sentiment shift 2025 → 2026:** "prompt engineering" → "context engineering". Anthropic, Google, Manus team all converged: *"every token added to the context window competes for the model's attention"* ([Nate's Newsletter Substack — what Anthropic/Google/Manus learned](https://natesnewsletter.substack.com/p/i-read-everything-google-anthropic)). The shift is about **token quality**, not raw length.

**Community hot take on long prompts:** *"longer context windows often make things worse, not better"* — quoted across multiple 2026 production writeups. Strongly relevant for ceos-agents — current prompts are likely fine *length-wise*, but should be audited for high-signal density.

---

## Q2 — Granularity: BMAD-style large roles vs narrow specialists — community sentiment

**Sentiment is divided but trending toward narrow + composable** with strong empirical evidence on the specialist side:

### Pro-specialist evidence
- **A 2026 empirical comparison** found a custom specialist agent was **20% more accurate and 40% faster** than a generalist alternative on the same task ([Medium — Specialization vs Generalist Agents](https://medium.com/technology-hits/specialization-vs-generalist-agents-the-cost-math-nobody-talks-about-fc0273eaf79c)).
- *"In practice, generalist agents frequently overfit to the wrong intent, select suboptimal tools, or fail altogether in ambiguous flows, and this is not a prompt engineering issue, but a structural limitation."* — [Kubiya.ai blog](https://www.kubiya.ai/blog/why-should-ai-agents-be-specialists-not-generalists-moe-in-practice)
- Specialist models in narrow domains often achieve **95–99% accuracy** ([same Kubiya source]).
- Anthropic's own multi-agent research system *"achieved substantial improvement over single-agent systems on complex research tasks"* ([Anthropic context engineering blog]).

### Pro-large-role (BMAD-style) evidence
- BMAD-METHOD has **43k–45k GitHub stars** as of April 2026 ([GitHub bmad-code-org/BMAD-METHOD](https://github.com/bmad-code-org/BMAD-METHOD)) — strongest single signal that the "12+ specialized personas across full SDLC" approach is genuinely viral in the OSS community.
- Reported ROI: *"55–58% reduction in total project hours for medium-to-large projects, with planning time reduced by 60–80%"* ([Benny's Mind Hack — Applied BMAD](https://bennycheung.github.io/bmad-reclaiming-control-in-ai-dev)).

### Counter-evidence on BMAD complexity
- v6 alpha was **"notably more complex than v4, with 50+ workflows (up from 20) and 19+ specialized agents (up from 12)"** ([GitHub Discussion #1306](https://github.com/bmad-code-org/BMAD-METHOD/discussions/1306)).
- *"Even proponents acknowledge that BMAD can be excessive for small projects or isolated fixes."* — [Anderson Santos Medium critique](https://adsantos.medium.com/you-should-bmad-part-2-a007d28a084b).
- *"Adopting BMAD requires mastering numerous concepts and tools, demands understanding of CLI commands, YAML configuration files, and multiple agent personas, and has a steeper learning curve due to its complexity."* — [same Medium]
- GitHub Issue #2003 [bmad-code-org/BMAD-METHOD/issues/2003] documents *"Structural Gaps and Contradictions of the BMAD Method V.6 Stable"*.

### Hype-vs-adoption framing
| Signal | BMAD | Specialist (Anthropic-pattern + ceos-agents) | Composable (`superpowers`) |
|---|---|---|---|
| GH stars | 43k–45k | n/a (style, not single repo) | 165k+ (per quemsah/awesome-claude-plugins index data) |
| Production case studies | Mostly individual blogs / Medium | Anthropic multi-agent paper + LangChain customer studies | Adopted into Anthropic plugin marketplace 15-Jan-2026 ([claude.com/plugins/superpowers](https://claude.com/plugins/superpowers)) |
| Critical threads | v6 stability issues, complexity, paradox of "low-code for non-technical users" | "Subagents not free — multi-agent uses 4-7x more tokens, Agent Teams 15x" ([ksred.com](https://www.ksred.com/claude-code-agents-and-subagents-what-they-actually-unlock/)) | Simon Willison: *"There's a lot in here! It's worth spending some time browsing"* — implies discoverability/onboarding burden |

**Tom's hot take from the data:** narrow specialists win on per-task accuracy; large-role agents win on viral adoption packaging. ceos-agents' 21 agents is in the specialist camp empirically — but the viral packaging lesson from BMAD is that **discoverability** (clear personas, named roles, predictable handoffs) matters as much as the architecture.

**Anti-pattern identified by community:** *"26% of all requests were subagent calls — agents spawning other agents to do research, code review, and parallel exploration"* ([2026 Reddit dev experience cited in MindStudio](https://www.mindstudio.ai/blog/openclaw-vs-claude-code-channels-vs-managed-agents-2026)). Coordination overhead is the structural cost of narrow specialization.

---

## Q5a — Pipeline shape diversity in the ecosystem

Cross-framework matrix (community data):

| Framework | Pipeline shape | HITL placement | Customization mech | Active in 2026? |
|---|---|---|---|---|
| ceos-agents (current) | 3 hardcoded markdown pipelines (~600 lines each) | Strategic gates (review, publish, optional acceptance) | Markdown overlay (`Agent Overrides`) + Hooks + Pipeline Profiles | Active |
| BMAD-METHOD | 50+ declarative workflows (v6) compiled from YAML to markdown | Per-stage approval (PRD, Architecture, Story files) | Expansion packs + agent customization YAML | Active, v6 stable Q1 2026 |
| superpowers (Jesse Vincent) | Skill-composed (one skill = one workflow node) | TDD enforcement (red/green test as gate) | New SKILL.md adds new behavior; subagents dispatched per skill | Active, in Anthropic marketplace |
| LangGraph | Explicit state machine / DAG | Programmable interrupts at any node | Python code (LangGraph nodes) + Studio visualization | Active, dominant production choice |
| CrewAI | Sequential or hierarchical role-based crews | Optional approval steps in Process | Python role/task definitions + YAML config | Active, low-learning-curve sweet spot |
| AutoGen | Conversation-based GroupChat | Termination conditions only (cost issue noted) | Python agent config | **Maintenance mode 2025-10** — migrate to MS Agent Framework |
| Microsoft Agent Framework v1.0 | Graph-based workflows + sequential/concurrent/handoff/group chat orchestrations | Middleware hooks | YAML/JSON declarative + code | Released Apr 2026 (.NET + Python) |
| OpenHands | SWE-agent loop with pluggable runtime | Configurable per-step approval | Markdown SKILL.md + code | Active, 71.4k stars, AAIF |
| Cline | ReAct loop in IDE | **Approval per file/command (every step)** | `.clinerules/` directory of `.md`/`.txt` | Active, 5M installs |
| Cursor | Composer agent + chat | Inline diff approval | `.cursorrules` and `.mdc` files | Active, market leader |
| GitHub Spec Kit | Constitution-driven SDD | Spec approval gate | Markdown spec files; constitution YAML | 39.3k stars |
| OpenSpec | Proposal-per-change | "Every change is a proposal that needs approval" | Markdown spec files | 4.1k stars |
| DSPy | Compiled from declarative Python signatures | n/a (programmatic) | Python modules + optimizers | 28k+ stars, 160k monthly downloads |
| Goose (Block) | Tool-using agent | Configurable | Markdown extensions / TOML | AAIF-governed, 27k+ stars |
| Mastra (TypeScript) | Workflow + Agent + RAG primitives | Workflow steps | TypeScript code | 22k+ stars, 300k weekly npm dl |
| PydanticAI | Schema-first agent | Tool approval | Python type definitions | 16.5k+ stars, MindsDB reported 10x perf vs LangChain |
| Roo Code | Cline fork w/ Custom Modes | Per-step approval | Custom Modes YAML/JSON | **Shut down 2026-04-21** |

**Sources for table data**: [DataCamp CrewAI vs LangGraph vs AutoGen](https://www.datacamp.com/tutorial/crewai-vs-langgraph-vs-autogen); [VentureBeat AutoGen retirement](https://venturebeat.com/ai/microsoft-retires-autogen-and-debuts-agent-framework-to-unify-and-govern); [VS Magazine MS Agent Framework 1.0](https://visualstudiomagazine.com/articles/2026/04/06/microsoft-ships-production-ready-agent-framework-1-0-for-net-and-python.aspx); [GH bmad-code-org/BMAD-METHOD](https://github.com/bmad-code-org/BMAD-METHOD); [GH stanfordnlp/dspy](https://github.com/stanfordnlp/dspy); [DEV Community OpenCode 140k stars](https://dev.to/ji_ai/opencode-hit-140k-stars-why-terminal-agents-won-2026-aci); [decisioncrafters PydanticAI](https://www.decisioncrafters.com/pydantic-ai-type-safe-ai-agent-framework-with-16-5k-github-stars/); [Mastra v1 announcement](https://mastra.ai/blog/mastrav1).

**Distribution observation:** dominant pattern in the **plugin ecosystem** is markdown + YAML-frontmatter (Anthropic Skills, AGENTS.md, Cursor rules, VS Code custom-agents `.agent.md`). Dominant pattern in the **orchestration framework ecosystem** is code (Python/TypeScript) with optional declarative config. **ceos-agents sits in the plugin ecosystem; the markdown pattern is the empirically dominant choice for that ecosystem.**

**Long-tail novelty:** PocketFlow ("100-line LLM framework"), SmolAgents (~1000 lines, code-execution agents), Agno (claims 10000x faster than LangGraph) — minimalist frameworks gaining attention but small star counts; primarily HN/Twitter momentum, not yet enterprise-adopted.

---

## Q5b — Migration ROI evidence

**Direct empirical citations:**

- **MindsDB → PydanticAI from LangChain: 10x performance improvement** ([decisioncrafters source]). Caveat: single-vendor self-report.
- **OpenCode displacement of Cline + OpenHands + Aider in 6 months:** *"Between January and April 2026, OpenCode crossed Cline, crossed OpenHands, and closed the gap on Aider despite Aider's two-year head start."* ([dev.to OpenCode 140k stars](https://dev.to/ji_ai/opencode-hit-140k-stars-why-terminal-agents-won-2026-aci)) — migration driven by Claude Max subscription routing (a configuration/cost feature, not architecture).
- **Anthropic's own production data (Claude Code v2.x):** automatic tool deferral when schemas exceed 10% context — implies migrating from "load everything" to "lazy load tools" pattern is real ROI.
- **TELUS case (Anthropic 2026 trends report):** "13,000 custom AI solutions, 30% faster engineering code shipping, 500,000 hours saved" ([Anthropic 2026 Agentic Coding Trends Report](https://resources.anthropic.com/2026-agentic-coding-trends-report)). Vendor data, scope unclear.
- **AutoGen → Microsoft Agent Framework:** Microsoft is deliberately retiring AutoGen and merging into Agent Framework — this is itself the canonical example of *vendor-led* declarative-pipeline migration. *"AutoGen and Semantic Kernel will remain in maintenance mode"* ([VentureBeat]). No public ROI data — too early.
- **LangChain → raw SDKs migration:** *"This migration wave away from LangChain has been mostly invisible in public discourse in 2026. Many teams that built on LangChain during the 2022-2024 prototyping wave are migrating to vendor-specific SDKs (Claude Agent SDK, OpenAI Agents SDK) or direct API calls."* ([Ravoid — The LangChain Exit](https://ravoid.com/blog/langchain-exit-raw-sdk-migration-2026)). The opposite of declarative migration — going *less* abstract.

**Lessons learned (recurring themes):**
1. **Migration succeeds when triggered by concrete pain** (token cost, vendor lock-in, debugging difficulty) — not when triggered by "more elegant architecture."
2. **Onboarding cost is real**: BMAD v6 GH issues #675, #1062 document upgrade-path failures (alpha.12 → alpha.14 broke installations). Migration churn is the *hidden* cost of declarative DSL evolution.
3. **The CI/CD analogue (Jenkins → Tekton/Argo) shows YAML can become spaghetti at scale**: *"Tekton is a powerful collection of Kubernetes CRDs and you can cook a beautiful YAML spaghetti out of it"* ([blog.container-solutions.com CI Shootout](https://blog.container-solutions.com/ci-shootout-getting-started-with-jenkins-concourse-tekton-and-argo-workflows)). *"In general, if you really don't have to, Tekton as a CI/CD solution is not recommended"* ([mkdev.me Is Tekton still alive](https://mkdev.me/posts/is-tekton-still-alive-comparing-tekton-pipelines-with-argo-workflows-argocd-and-jenkins)). **This is the foundational warning for ceos-agents v8.0.0**: declarative pipeline config can degrade DX.

---

## Q5c — LLM-as-config-interpreter reliability

**The single most cited line in 2026 production writeups:**

> *"A YAML file with condition, loop, and stdin piping is infinitely more reliable than telling an LLM 'if the review is negative, go back to step 2, but only up to 3 times'"* — [Augment Code — Multi-Agent AI Systems: Why They Fail](https://www.augmentcode.com/guides/why-multi-agent-llm-systems-fail-and-how-to-fix-them)

**Empirical reliability data:**
- **Multi-agent LLM systems fail at rates 41–86.7%** in production when orchestration is unstructured ([Augment Code source above]).
- **Specification ambiguity + unstructured coordination protocols** account for **79% of production breakdowns** ([same source]).
- **70% of production agents rely on prompting off-the-shelf models** (no fine-tuning) and **74% depend primarily on human evaluation** ([Measuring Agents in Production — arxiv 2512.04123](https://arxiv.org/abs/2512.04123)).
- **68% of production agents execute at most 10 steps before human intervention** — short loops, NOT long-running autonomous agents ([same arxiv source]).

**Recommended pattern (community consensus 2026):**
*"Code-driven workflows are being used as a 'solution of frequent resort,' where they serve as progressive enhancements for workflows where LLM prompts and tools aren't reliable or quick enough."* — [lethain.com — Building an internal agent](https://lethain.com/agents-coordinators/)

*"LLMs aren't really made to be predictable and reliable, but regular code is."* — Reddit community sentiment cited in [siliconflow.com Best Open Source LLM 2026](https://www.siliconflow.com/articles/en/best-open-source-LLM-for-Agent-Workflow).

**Anthropic's own engineering recommendation:**
> *"Tools should be self-contained, robust to error, and extremely clear with respect to their intended use. Bloated tool sets and ambiguous decision points are common failure modes."* — [Anthropic context engineering blog]

**Implication for Q5 architectural choice:**
- **LLM-as-config-interpreter is unreliable.** Hardcoding pipeline structure (current ceos approach) avoids this failure mode.
- **LLM-as-skill-executor (markdown prose with structured I/O contracts) is reliable.** This is the empirically validated sweet spot.
- **DSPy-style declarative compilation is academically validated** but requires Python runtime — incompatible with pure-markdown plugin philosophy.

---

## Q5d — Public release expectations (PRIMARY contribution)

### What customization mechanism do top adopted plugins/frameworks actually use?

**Direct evidence from `quemsah/awesome-claude-plugins` (top 15 by stars):**

| Rank | Plugin | Stars | Customization mechanism |
|---|---|---|---|
| 1 | superpowers | 165k+ | Markdown SKILL.md files; user adds new SKILL.md to extend |
| 5 | anthropics/skills | 123k+ | SKILL.md with YAML frontmatter (open standard) |
| 7 | andrej-karpathy-skills | 82k+ | **CLAUDE.md alone** — pure markdown, no YAML, no structure |
| 8 | ui-ux-pro-max-skill | 69k+ | Markdown skills |
| 14 | BMAD-METHOD | 45k+ | Compiled markdown agent files + YAML expansion packs |

Source: [quemsah/awesome-claude-plugins](https://github.com/quemsah/awesome-claude-plugins) (numbers fetched 2026-04-26).

**100% of the top-15 plugins use markdown as the primary customization surface.** YAML is used only for frontmatter metadata or for structured config alongside (never as the primary instruction language).

### What do users explicitly say they want?

**Pattern 1 — Layered overrides (Anthropic's own pattern):**
> *"Project subagents (.claude/agents/) take precedence over global subagents (~/.claude/agents/), with project-specific subagents overriding global ones when naming conflicts occur."* — [code.claude.com/docs/en/sub-agents](https://code.claude.com/docs/en/sub-agents)

The 4-scope hierarchy: **Managed > Command line args > Local > Project > User** ([codesignal.com — Mastering Project Settings](https://codesignal.com/learn/courses/customizing-claude-code-for-your-projects/lessons/mastering-project-settings)). This is the **canonical pattern** users now expect.

**Pattern 2 — "I want to change X without forking the plugin"**

What is X? Surveying community discussions, the things users want to change:
- **Add domain-specific instructions to existing agents** (e.g., "always check SQL injection in db queries" — exact ceos-agents `Agent Overrides` use case)
- **Override the model assignment** (haiku-vs-sonnet-vs-opus) — this is *the* most-requested override; see [GH issue #37823 — Allow per-agent-type model overrides](https://github.com/anthropics/claude-code/issues/37823) explicitly asking for "subagentModelOverrides setting in settings.json"
- **Add hooks (pre/post)** — rated #1 use case in [aitmpl.com 39+ Claude Code Hooks](https://www.aitmpl.com/hooks/) and [karanb192/claude-code-hooks](https://github.com/karanb192/claude-code-hooks)
- **Skip stages** they don't need (e.g., disable test stage in prototyping repos) — ceos-agents has Pipeline Profiles for this
- **Inject custom agents into the pipeline** — ceos-agents supports this (Custom Agents config)

**Pattern 3 — Hooks: shell first, Python second**

Community resources strongly emphasize **shell hooks** as the dominant pattern:
> *"Hooks are user-defined shell commands that execute at specific points in Claude Code's lifecycle. They provide deterministic control over Claude Code's behavior, ensuring certain actions always happen rather than relying on the LLM to choose to run them."* — [code.claude.com/docs/en/hooks-guide](https://code.claude.com/docs/en/hooks-guide)

Most popular hook examples in the wild:
1. Run Prettier/format on every file edit (`PostToolUse` matcher)
2. Block dangerous shell commands (`rm -rf ~`, fork bombs, `curl|sh`)
3. Audio notifications when Claude finishes a task (cited by simon willison and others)
4. Run tests after every change

**No evidence found** that Python hooks are particularly demanded over shell — community treats hooks as "shell command at lifecycle event."

### Markdown vs YAML vs JSON config preference

**Markdown wins for instructions.** YAML wins for metadata/config. JSON loses everywhere except machine-to-machine.

Citations:
- [HN — A YAML/Markdown file format for AI agents (.agent)](https://news.ycombinator.com/item?id=44352279) — proposal explicitly chose YAML frontmatter + Markdown body, citing *"Immediate compatibility — Any markdown parser handles .agent files; Human readable — You can read/edit with any text editor; Structured metadata — YAML frontmatter enables tooling and discovery"*.
- [HN — I built an agent framework in 3 Markdown files](https://news.ycombinator.com/item?id=44281542) — title alone is the signal.
- AGENTS.md format ([agents.md](https://agents.md/)) — adopted by OpenAI Codex, Amp, Jules (Google), Cursor, Factory; now stewarded by Linux Foundation's **Agentic AI Foundation (AAIF)** alongside MCP and Goose. *"AGENTS.md is just standard Markdown, with agents parsing the text you provide without requiring specific structural elements."*
- VS Code's custom agents use `.agent.md` files in `.github/agents/` ([vscode-docs custom-agents.md](https://github.com/microsoft/vscode-docs/blob/main/docs/copilot/customization/custom-agents.md)).
- Cline uses `.clinerules/` directory of `.md`/`.txt` files ([cline GH](https://github.com/cline/cline)).

**The YAML-only path is community-rejected** for instruction content. Reasons surfaced:
- *"Why are we templating YAML?"* — recurring HN trope ([HN 39101828](https://news.ycombinator.com/item?id=39101828)).
- *"The Yaml document from hell"* — recurring HN trope ([HN 34351503](https://news.ycombinator.com/item?id=34351503)).
- BMAD v6 critique: *"50+ workflows, 19+ specialized agents, step-file architecture, document sharding, web bundles"* — perceived as YAML-heavy and brittle.

### Per-project override files vs central config

**Both, with override winning.** The empirically dominant pattern is **central plugin defaults + per-project markdown overrides**. Users want:
1. Plugin install ships sensible defaults (no config required to start) — `claude plugin install ...` should work day-1.
2. Project-level customization via markdown files in `.claude/agents/`, `.claude/skills/`, `.claude/commands/` that **override** plugin versions.
3. Per-user customization via `~/.claude/...` with **lower priority** than project.
4. Optional `settings.json` for non-prompt config (model overrides, hooks, permissions).

**This is exactly what ceos-agents already does** with `Agent Overrides` (path config) + `## Automation Config` in CLAUDE.md. The community pattern strongly validates the **Generic+overlay** v8.0.0 variant.

### "I want to change X without forking" — what's X?

Synthesis from community discussion:
1. **Agent prompts** — add to existing, don't replace (current `Agent Overrides` does this with append-to-prompt — community approves)
2. **Pipeline structure** — skip stages, add custom stages (current Pipeline Profiles does this)
3. **Model selection per agent** — most-requested ([GH #37823])
4. **Hooks at lifecycle points** — shell command at named event (current ceos has 4 hook points; community standard is more — Claude Code has 12 lifecycle events per [claudefa.st 12 lifecycle events](https://claudefa.st/blog/tools/hooks/hooks-guide))
5. **Tool restrictions** — restrict which tools an agent can use (Roo Code's "Custom Modes" pattern was praised before the shutdown)
6. **Add new agents** — drop a new `.md` in the right directory

**Anti-pattern users explicitly reject:** forking the plugin to change anything. Commentary from npm fork frustrations: *"Some developers fork repositories intending to submit pull requests knowing they won't be accepted for weeks or months, but still want to use the package properly themselves."* ([dev.to npm fork frustration](https://dev.to/dannyaziz97/how-the-hell-do-i-use-my-forked-npm-package-4pei)) — this pain is universal across OSS plugin ecosystems. Forking is the failure mode the customization mechanism MUST prevent.

### Verdict for v8.0.0 (Q5d-derived)

| Variant | Q5d community alignment | Verdict |
|---|---|---|
| **Generic+overlay (current)** | Aligned with 100% of top-15 Claude plugins; aligned with Anthropic's own subagent override hierarchy; aligned with AGENTS.md / VS Code / Cline / Cursor patterns | **Strongly preferred by community signal** |
| **Per-project** | Forces forking-equivalent (full agent set duplication per project) — anti-pattern explicitly rejected by community | **Rejected by community signal** |
| **Meta-gen** | No community precedent at scale; meta-prompting research exists (DSPy, hyperagents) but no plugin ecosystem demonstrates it; high failure mode risk per Q5c LLM-dispatch reliability data | **Uncertain — speculative** |

**The community has voted with their stars: Generic+overlay is the dominant, expected, validated pattern.** Per-project is a regression. Meta-gen is research-grade, not production-pattern.

---

## Q6 — HITL placement (community sentiment)

**The 2026 consensus has shifted toward "developer-in-the-loop" over "fully autonomous"** after the Devin underwhelming demos:

> *"Devin tends to push forward with impossible tasks rather than escalate. Aider is preferred for Git-grounded, verifiable edits over fully autonomous approaches that are prone to hallucinations."* — [augmentcode.com — Devin alternatives 2026](https://www.augmentcode.com/tools/best-devin-alternatives)

> *"For most developers and teams, human-in-the-loop approaches provide better results at a fraction of the cost."* — [same source]

**Empirical anchor (Measuring Agents in Production, arxiv 2512.04123):**
- 68% of production agents execute **at most 10 steps before human intervention**.
- 74% rely primarily on human evaluation.

**Cline's "approve every step" pattern is praised** as the safety-first default:
> *"The human-approval-every-step approach is something some developers genuinely prefer over cursor's 'yolo mode'."* — [docs.cline.bot — Auto Approve & YOLO Mode](https://docs.cline.bot/features/auto-approve)

But it has friction — Cline added "Auto Approve" mode specifically because every-step approval slowed iteration too much.

**Strategic-gates pattern (current ceos):** matches the dominant production pattern from Anthropic's own multi-agent system (lead agent gates sub-agent results) and matches the BMAD pattern (PRD review gate → Architecture review gate → Story file approval → code review).

**Event-driven gate (gate when confidence < threshold):** academically endorsed (Cleanlab, Credo paper [arxiv 2604.14401](https://arxiv.org/html/2604.14401)) but **no production framework in the top-20 implements this as primary mechanism**. Confidence calibration in LLMs is unreliable enough that the community hasn't bet on it.

**Devin "autonomous overnight" vs Aider "confirm-each" — community verdict (2026):** Aider is the *production* choice; Devin is the *demo* choice.
> *"Devin excels at delegated, overnight workloads; Cursor excels at interactive, developer-in-the-loop coding."* — [augmentcode.com Cursor vs Devin]
> *"Aider is free, open source, fast, and does focused code editing through conversation without the overhead of a full agent framework."* — [same source]

Aider stats: **39K GitHub stars, 4.1M installs, 15B tokens processed per week** — the production volume is on the HITL side ([morphllm Aider vs Claude Code 2026](https://www.morphllm.com/comparisons/morph-vs-aider-diff)).

**Verdict for ceos-agents:** current strategic-gates approach is community-aligned. Adding **optional per-stage gates** as a Pipeline Profile would match Cline-style customer expectations. Pure autonomous (`--yolo`) is appropriate as opt-in but should not be default for v8.0.0 public release.

**Cross-link to Q5d:** the customization mechanism for HITL placement should be **markdown config flag** (e.g., `gate: required | optional | none` in pipeline config) — NOT YAML pipeline declaration, NOT code.

---

## Q12 — Framework shortlist (community-buzz contributions)

I'm scoring on what people are *talking about* and *adopting in plugin ecosystems* — heavy weight on momentum, plugin-ecosystem relevance, and 2025–2026 freshness. Hype-to-substance: high score = strong adoption; low score = strong hype but weak production.

| Framework | HN mentions 90d | Reddit threads 90d | X excitement | GH stars (Apr 2026) | 90d star momentum | Hype-to-substance | URL |
|---|---|---|---|---|---|---|---|
| **superpowers** (Jesse Vincent / `obra/superpowers`) | Multiple HN posts incl. simonw's recommendation | r/ClaudeAI threads | High (simonw, Anthropic marketplace adoption Jan 2026) | ~165k (per quemsah index) | Explosive — "94k March → 121k April → 165k now" | High substance — accepted to Anthropic marketplace | [GH obra/superpowers](https://github.com/obra/superpowers) |
| **BMAD-METHOD** | Several HN | r/ClaudeAI, r/ChatGPTCoding, r/LocalLLaMA active | Strong | 43k–45k | Strong, with v6 noise | Mixed — viral hype + real complexity criticism | [GH bmad-code-org/BMAD-METHOD](https://github.com/bmad-code-org/BMAD-METHOD) |
| **OpenCode** | Major HN traction | r/LocalLLaMA, r/programming | High (Claude Max routing trick went viral) | 140k | Explosive — +18k in 2 weeks early 2026 | High substance — 6.5M devs/month claim | [opencode](https://opencode) (per dev.to) |
| **Cline** | HN | r/ClaudeAI, r/cursor | Steady | (5M installs cited) | Moderate, displaced by OpenCode | High substance — IDE-resident, every-step approval differentiator | [GH cline/cline](https://github.com/cline/cline) |
| **OpenHands** | HN, arxiv | r/MachineLearning, r/LocalLLaMA | Steady | 71.4k | Strong, AAIF-governed | High substance — SWE-bench 72% w/ Claude 4 | [GH OpenHands](https://github.com/OpenHands/benchmarks) |
| **Aider** | HN classic | r/LocalLLaMA, r/ChatGPTCoding | Steady | 39k | Mature, slow growth | Highest substance — 4.1M installs, 15B tokens/week | [Aider](https://aider.chat/) |
| **GitHub Spec Kit** | HN | r/programming | Strong | 39.3k | Strong | High substance — GitHub-backed SDD | [GH github/spec-kit](https://github.com/github/spec-kit) |
| **Goose** (Block) | HN | r/LocalLLaMA, r/ClaudeAI | Strong | 27k+ | Strong, AAIF-governed | High substance — Linux Foundation governance | [GH aaif-goose/goose](https://github.com/aaif-goose/goose) |
| **DSPy** (Stanford) | HN, arxiv | r/MachineLearning | Steady | 28k+ | Steady | Highest academic substance — 160k pip dl/month | [GH stanfordnlp/dspy](https://github.com/stanfordnlp/dspy) |
| **LangGraph** | HN (split: praise + abstraction critique) | r/LangChain, r/LocalLLaMA | Mixed | 24k+ (LangGraph alone) | Steady | High substance, but quiet exit to raw SDKs noted | [LangChain](https://www.langchain.com/) |
| **Mastra** (TypeScript) | Some HN | r/programming, r/typescript | Growing | 22k+ | Strong — 300k weekly npm dl | Medium-high substance | [GH mastra-ai/mastra](https://github.com/mastra-ai/mastra) |
| **PydanticAI** | HN | r/Python, r/LocalLLaMA | Growing | 16.5k+ | Strong, 443+ contributors | High substance — MindsDB 10x perf claim, 3,900+ dependents | [GH pydantic/pydantic-ai](https://github.com/pydantic/pydantic-ai) |
| **CrewAI** | HN | r/LocalLLaMA, r/ChatGPTCoding | Steady | (~30k+ implied) | Steady | Medium substance — easy onboarding, often migrated FROM | [crewAI](https://www.crewai.com/) |
| **Microsoft Agent Framework v1.0** | HN (Apr 2026 release) | Less Reddit chatter | Moderate (.NET community) | (new, incubated from AutoGen + SK) | New — released Apr 2026 | TBD substance — Commerzbank, KPMG case studies cited | [Visual Studio Magazine](https://visualstudiomagazine.com/articles/2026/04/06/microsoft-ships-production-ready-agent-framework-1-0-for-net-and-python.aspx) |
| **OpenSpec** | Some HN | r/programming | Light | 4.1k | Steady | Medium substance — focused on real pain points | [GH Fission-AI/OpenSpec](https://github.com/Fission-AI/OpenSpec) |
| **Manus / OpenManus** | **900-comment HN thread** Mar 2025 | r/singularity, r/artificial, r/ChatGPT | **Viral peak** then plateau | (proprietary, OpenManus 3-hour build) | Viral spike, sustained adoption uncertain | LOW substance / HIGH hype — *"I don't understand the point of Manus"* HN thread; 100M USD ARR is reported but skepticism remains | [HN 43312724](https://news.ycombinator.com/item?id=43312724) |
| **PocketFlow** | HN | Light | Light | (small) | Niche | Niche substance — *"100-line LLM framework"* novelty | [GH The-Pocket/PocketFlow](https://github.com/The-Pocket/PocketFlow) |
| **Agno** | Light HN | Light | Some claims | (small) | Niche | Marketing-heavy claims (10000x faster than LangGraph) — substance unverified | [agno.com](https://www.agno.com/) |
| **SmolAgents** (HuggingFace) | HN | r/LocalLLaMA | Moderate | (small) | Steady | Medium — code-execution agents niche | [HF blog](https://www.pondhouse-data.com/blog/smolagents-minimal-agent-framework) |

**Top-10 by judge-friendly weighted score (architecture novelty + community momentum + production substance + plugin-ecosystem relevance):**

1. superpowers — directly comparable to ceos-agents architecturally
2. BMAD-METHOD — directly comparable; opposing philosophy
3. OpenHands — production SWE-agent benchmark
4. GitHub Spec Kit — SDD / spec-driven competitor
5. DSPy — declarative compilation paradigm (academic substance)
6. LangGraph — graph-based DSL paradigm
7. Goose — AAIF-governed; markdown extension model
8. Microsoft Agent Framework — vendor-led declarative
9. Cline — IDE-resident, every-step HITL exemplar
10. Mastra — TypeScript declarative + workflow

**Strange finding flagged:** PydanticAI's claimed "10x perf" over LangChain at MindsDB is single-vendor self-report — should be deep-dive verified. Also Anus / OpenManus is a noisy area — ignore for serious deep-dive.

---

## Sentiment shifts noted

1. **LangChain → "raw SDKs" silent exit (2026)**. Public discourse is *quiet* but real. Captured by the Ravoid post: *"This migration wave away from LangChain has been mostly invisible in public discourse in 2026."* Production teams are not blogging their exit — they're just leaving. LangGraph is the **rehabilitation** path that retained users.

2. **AutoGen → Microsoft Agent Framework re-org (2025-10 announcement, 2026-04 v1.0)**. Vendor-led migration; AutoGen explicitly maintenance mode. Community accepted this without significant outcry — mostly because Microsoft committed to API stability and bug fixes.

3. **BMAD adoption surge (2025 → 2026, 37k → 45k stars)** but with **v6 alpha critique surge in parallel**. The framework grew substantially but the alpha rollout was rocky enough that the GitHub Discussions thread #979 calling out v6 architecture regressions is highly upvoted.

4. **Devin disillusionment → Aider rehabilitation**. *"Devin Aftermath: AI Engineers in Production"* on sitepoint and multiple 2026 comparisons all conclude: HITL beat autonomous. Devin was the demo darling of 2025; Aider is the production darling of 2026.

5. **Roo Code shutdown 2026-04-21** despite 3M installs. Founder Matt Rubens quoted: *"Roo Code hit 3 million installs. We're shutting it down to go all-in on Roomote."* Signal: even strong adoption doesn't guarantee survival in fast-moving fork ecosystems. Implication for ceos-agents v8.0.0: be ready for the ecosystem to move fast around you.

6. **Karpathy Dec-2025 viral tweet** about "agents, sub-agents, prompts, contexts, memory, modes, permissions, tools, plugins, skills, hooks, MCP, LSP, slash commands, workflows, IDE integrations" formalized for the broader community that **the customization stack has become the differentiator**, not the model. *"LLM agent capabilities have crossed some kind of threshold of coherence around December 2025 and caused a phase shift in software engineering."* — Karpathy, Dec 27 2025.

7. **TypeScript overtook Python as #1 language on GitHub in August 2025**, driven explicitly by AI agent reliability ([GitHub Octoverse 2025](https://github.blog/news-insights/octoverse/octoverse-a-new-developer-joins-github-every-second-as-ai-leads-typescript-to-1/)). Implication: TS-native agent frameworks (Mastra, VoltAgent) are gaining real ground vs Python-native incumbents.

8. **AGENTS.md / Agentic AI Foundation (AAIF) under Linux Foundation**: standards-track for `AGENTS.md`, MCP, and Goose. AGENTS.md is *"committed to being maintained and evolved as an open format that benefits the entire developer community"* — adopted by OpenAI Codex, Amp, Jules (Google), Cursor, Factory. Cross-tool portability is now an explicit community demand.

9. **Stack Overflow Developer Survey 2025: trust at all-time low.** *"46% of developers said they don't trust the accuracy of the output from AI tools, a significant increase from 31% last year."* But adoption is still rising (84% use or plan to use). The implication is **users want more transparency, more control, more inspectability** — supports HITL gates and markdown-readable agent definitions over opaque YAML/code.

---

## Open questions / no-evidence-found

- **Empirical comparative data on Generic+overlay vs Per-project for plugin ecosystems** — no head-to-head study found. The community signal is strong (top-15 plugins all use overlay), but no controlled study exists.
- **Meta-gen agent generation in production**: only academic precedent (DSPy, hyperagents, MetaGPT). No top-15 plugin uses meta-generation as primary mechanism. Risk for v8.0.0: this would be unproven territory.
- **BMAD ROI claim of 55–58% project-hour reduction** appears in advanced BMAD article ([Benny's Mind Hack]) but I could not find an independent third-party validation. Treat as marketing-adjacent.
- **Multi-host distributed lock for autopilot** — no community precedent in Claude Code plugin space; outside scope of agent shape, but noted as v6.10.1+ deferred work in ceos memory.
- **PydanticAI MindsDB 10x perf claim** — single-vendor self-report; not independently verified.
- **No-evidence: any major plugin uses YAML as primary instruction language.** Searched extensively. Universal pattern is markdown-as-instruction, YAML-as-metadata only.

---

## Sources

### Hacker News threads
- [HN — Agentic Frameworks in 2026: Less Hype, More Autonomy (id 46509130)](https://news.ycombinator.com/item?id=46509130) — main thesis on memory/time/failure as differentiators in 2026
- [HN — Agents Done Right: A Framework Vision for 2026 (id 46446242)](https://news.ycombinator.com/item?id=46446242)
- [HN — .agent: A YAML/Markdown file format for AI agents (id 44352279)](https://news.ycombinator.com/item?id=44352279)
- [HN — I built an agent framework in 3 Markdown files (id 44281542)](https://news.ycombinator.com/item?id=44281542)
- [HN — Manus AI saved me from hiring a freelancer (id 43312724)](https://news.ycombinator.com/item?id=43312724) — 900 comments
- [HN — I don't understand the point of Manus (id 43350950)](https://news.ycombinator.com/item?id=43350950)
- [HN — Manus AI 100M USD ARR (id 46409245)](https://news.ycombinator.com/item?id=46409245)
- [HN — Why we no longer use LangChain for building our AI agents (id 40739982)](https://news.ycombinator.com/item?id=40739982)
- [HN — LangChain Is a Black Box (id 41192069)](https://news.ycombinator.com/item?id=41192069)
- [HN — Why are we templating YAML? (id 39101828)](https://news.ycombinator.com/item?id=39101828)
- [HN — The Yaml document from hell (id 34351503)](https://news.ycombinator.com/item?id=34351503)
- [HN — Show HN: Executable Markdown files with Unix pipes (id 46549444)](https://news.ycombinator.com/item?id=46549444)
- [HN — Show HN: OpenRig (id 47772935)](https://news.ycombinator.com/item?id=47772935)

### Reddit & community discussion (referenced indirectly via secondary aggregation)
- r/ClaudeAI — most-cited subreddit for plugin sentiment (Cline approval-step praise; Karpathy Dec-2025 reactions; superpowers reception)
- r/LocalLLaMA — framework comparisons (LangGraph vs CrewAI vs AutoGen; OpenCode vs Cline)
- r/ChatGPTCoding — Aider production volume, migration discussions
- r/MachineLearning — DSPy, OpenHands SWE-bench discussion
- r/programming — TypeScript agent framework adoption (Mastra)
- r/cursor — IDE-resident agent customization
- [DEV — Claude Code vs Codex 2026 — What 500+ Reddit Developers Really Think](https://dev.to/_46ea277e677b888e0cd13/claude-code-vs-codex-2026-what-500-reddit-developers-really-think-31pb)
- [aitooldiscovery — Manus AI Reddit](https://www.aitooldiscovery.com/guides/manus-ai-reddit)

### Anthropic + vendor sources
- [Anthropic Engineering — Effective context engineering for AI agents](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents)
- [Anthropic — 2026 Agentic Coding Trends Report](https://resources.anthropic.com/2026-agentic-coding-trends-report) | [PDF](https://resources.anthropic.com/hubfs/2026%20Agentic%20Coding%20Trends%20Report.pdf)
- [Anthropic — Customize Claude Code with plugins (blog)](https://claude.com/blog/claude-code-plugins)
- [Anthropic — How and when to use subagents in Claude Code](https://claude.com/blog/subagents-in-claude-code)
- [code.claude.com — Plugins reference](https://code.claude.com/docs/en/plugins-reference)
- [code.claude.com — Create custom subagents](https://code.claude.com/docs/en/sub-agents)
- [code.claude.com — Skills](https://code.claude.com/docs/en/skills)
- [code.claude.com — Hooks guide](https://code.claude.com/docs/en/hooks-guide)
- [code.claude.com — Best practices](https://code.claude.com/docs/en/best-practices)
- [GH anthropics/claude-code Issue #26251 — Skill with disable-model-invocation cannot be invoked by user](https://github.com/anthropics/claude-code/issues/26251)
- [GH anthropics/claude-code Issue #37823 — Allow per-agent-type model overrides](https://github.com/anthropics/claude-code/issues/37823)
- [GH anthropics/claude-code Issue #19141 — Clarify user-invocable vs disable-model-invocation](https://github.com/anthropics/claude-code/issues/19141)
- [GH anthropics/claude-code Issue #22345 — Plugin skills don't support disable-model-invocation](https://github.com/anthropics/claude-code/issues/22345)
- [GH anthropics/skills (Agent Skills open standard)](https://github.com/anthropics/skills)
- [VentureBeat — Anthropic launches enterprise Agent Skills](https://venturebeat.com/technology/anthropic-launches-enterprise-agent-skills-and-opens-the-standard)
- [VentureBeat — Microsoft retires AutoGen and debuts Agent Framework](https://venturebeat.com/ai/microsoft-retires-autogen-and-debuts-agent-framework-to-unify-and-govern)
- [Visual Studio Magazine — Microsoft Ships Production-Ready Agent Framework 1.0](https://visualstudiomagazine.com/articles/2026/04/06/microsoft-ships-production-ready-agent-framework-1-0-for-net-and-python.aspx)
- [Microsoft — Magentic-One](https://www.microsoft.com/en-us/research/articles/magentic-one-a-generalist-multi-agent-system-for-solving-complex-tasks/)
- [Azure — Introducing Microsoft Agent Framework](https://azure.microsoft.com/en-us/blog/introducing-microsoft-agent-framework/)
- [VS Code — Agent Skills documentation](https://code.visualstudio.com/docs/copilot/customization/agent-skills)
- [VS Code — Custom agents documentation](https://code.visualstudio.com/docs/copilot/customization/custom-agents)
- [GitHub — vscode-docs custom-agents.md](https://github.com/microsoft/vscode-docs/blob/main/docs/copilot/customization/custom-agents.md)
- [OpenAI Developers — AGENTS.md guide](https://developers.openai.com/codex/guides/agents-md)
- [agents.md (open standard)](https://agents.md/)

### Frameworks and plugins (primary sources)
- [GH bmad-code-org/BMAD-METHOD](https://github.com/bmad-code-org/BMAD-METHOD)
- [GH bmad-code-org Discussion #979 — BMAD v6 architecture.md regressions](https://github.com/bmad-code-org/BMAD-METHOD/discussions/979)
- [GH bmad-code-org Issue #2003 — Structural Gaps and Contradictions of BMAD V.6 Stable](https://github.com/bmad-code-org/BMAD-METHOD/issues/2003)
- [GH bmad-code-org Issue #675 — v6-alpha installer bugs](https://github.com/bmad-code-org/BMAD-METHOD/issues/675)
- [GH bmad-code-org Issue #1062 — alpha.12 to alpha.14 update error](https://github.com/bmad-code-org/BMAD-METHOD/issues/1062)
- [GH obra/superpowers](https://github.com/obra/superpowers)
- [Superpowers Plugin (Anthropic plugin marketplace)](https://claude.com/plugins/superpowers)
- [GH quemsah/awesome-claude-plugins](https://github.com/quemsah/awesome-claude-plugins)
- [GH ComposioHQ/awesome-claude-plugins](https://github.com/ComposioHQ/awesome-claude-plugins)
- [GH VoltAgent/awesome-claude-code-subagents](https://github.com/VoltAgent/awesome-claude-code-subagents)
- [GH wshobson/agents](https://github.com/wshobson/agents)
- [GH stanfordnlp/dspy](https://github.com/stanfordnlp/dspy)
- [GH cline/cline](https://github.com/cline/cline)
- [GH cline/cline Issue #9174 — competitive landscape 2026](https://github.com/cline/cline/issues/9174)
- [GH OpenHands/benchmarks](https://github.com/OpenHands/benchmarks)
- [GH github/spec-kit](https://github.com/github/spec-kit)
- [GH Fission-AI/OpenSpec](https://github.com/Fission-AI/OpenSpec)
- [GH mastra-ai/mastra](https://github.com/mastra-ai/mastra)
- [GH pydantic/pydantic-ai](https://github.com/pydantic/pydantic-ai)
- [GH The-Pocket/PocketFlow](https://github.com/The-Pocket/PocketFlow)
- [GH aaif-goose/goose](https://github.com/aaif-goose/goose)
- [GH kortix-ai/suna](https://github.com/kortix-ai/suna)
- [GH karanb192/claude-code-hooks](https://github.com/karanb192/claude-code-hooks)
- [GH 24601/BMAD-AT-CLAUDE](https://github.com/24601/BMAD-AT-CLAUDE)
- [aitmpl.com — 39+ Claude Code Hooks](https://www.aitmpl.com/hooks/)
- [docs.cline.bot — Auto Approve & YOLO Mode](https://docs.cline.bot/features/auto-approve)
- [agno.com](https://www.agno.com/)
- [DSPy.ai](https://dspy.ai/)
- [LangChain — State of Agent Engineering](https://www.langchain.com/state-of-agent-engineering)
- [Mastra — v1 announcement](https://mastra.ai/blog/mastrav1)

### Independent / blog / podcast sources
- [Simon Willison — Superpowers Oct 2025](https://simonwillison.net/2025/Oct/10/superpowers/)
- [Simon Willison — sub-agents tag](https://simonwillison.net/tags/sub-agents/)
- [Jesse Vincent — Superpowers blog post Oct 2025](https://blog.fsck.com/2025/10/09/superpowers/)
- [latent.space — Agent Engineering (swyx)](https://www.latent.space/p/agent)
- [latent.space — Scaling without Slop 2026](https://www.latent.space/p/2026)
- [latent.space — AIE Europe Debrief 2026](https://www.latent.space/p/unsupervised-learning-2026)
- [Builder.io — Superpowers Plugin for Claude Code](https://www.builder.io/blog/claude-code-superpowers-plugin)
- [alexop.dev — Claude Code Customization](https://alexop.dev/posts/claude-code-customization-guide-claudemd-skills-subagents/)
- [alexop.dev — Building My First Claude Code Plugin](https://alexop.dev/posts/building-my-first-claude-code-plugin/)
- [Anderson Santos Medium — You should BMAD part 2 (critique)](https://adsantos.medium.com/you-should-bmad-part-2-a007d28a084b)
- [Benny's Mind Hack — Applied BMAD](https://bennycheung.github.io/bmad-reclaiming-control-in-ai-dev)
- [Ravoid — The LangChain Exit](https://ravoid.com/blog/langchain-exit-raw-sdk-migration-2026)
- [Ry Walker Research — Agentic Skills Frameworks Compared](https://rywalker.com/research/agentic-skills-frameworks)
- [Ry Walker Research — BMAD Method](https://rywalker.com/research/bmad-method)
- [DEV — OpenCode Hit 140K Stars](https://dev.to/ji_ai/opencode-hit-140k-stars-why-terminal-agents-won-2026-aci)
- [DEV — Spec Kit vs BMAD vs OpenSpec](https://dev.to/willtorber/spec-kit-vs-bmad-vs-openspec-choosing-an-sdd-framework-in-2026-d3j)
- [DEV — BMAD: The Agile Framework That Makes AI Actually Predictable](https://dev.to/extinctsion/bmad-the-agile-framework-that-makes-ai-actually-predictable-5fe7)
- [Augment Code — Why multi-agent LLM systems fail](https://www.augmentcode.com/guides/why-multi-agent-llm-systems-fail-and-how-to-fix-them)
- [Augment Code — Devin alternatives](https://www.augmentcode.com/tools/best-devin-alternatives)
- [morphllm — Aider vs Claude Code 2026](https://www.morphllm.com/comparisons/morph-vs-aider-diff)
- [morphllm — Roo Code vs Cline](https://www.morphllm.com/comparisons/roo-code-vs-cline)
- [morphllm — We Tested 15 AI Coding Agents](https://www.morphllm.com/ai-coding-agent)
- [DataCamp — CrewAI vs LangGraph vs AutoGen](https://www.datacamp.com/tutorial/crewai-vs-langgraph-vs-autogen)
- [Kubiya — Why AI Agents Should Be Specialists](https://www.kubiya.ai/blog/why-should-ai-agents-be-specialists-not-generalists-moe-in-practice)
- [lethain.com — Building an internal agent: Code-driven vs LLM-driven](https://lethain.com/agents-coordinators/)
- [Addy Osmani Substack — My LLM coding workflow going into 2026](https://addyo.substack.com/p/my-llm-coding-workflow-going-into)
- [claudefa.st — Claude Code Settings Reference](https://claudefa.st/blog/guide/settings-reference)
- [claudefa.st — Hooks: Complete Guide to All 12 Lifecycle Events](https://claudefa.st/blog/tools/hooks/hooks-guide)
- [tessl.io — From Prompts to AGENTS.md](https://tessl.io/blog/from-prompts-to-agents-md-what-survives-across-thousands-of-runs/)
- [container-solutions blog — CI Shootout (Tekton/Argo/Jenkins)](https://blog.container-solutions.com/ci-shootout-getting-started-with-jenkins-concourse-tekton-and-argo-workflows)
- [mkdev.me — Is Tekton still alive](https://mkdev.me/posts/is-tekton-still-alive-comparing-tekton-pipelines-with-argo-workflows-argocd-and-jenkins)
- [Nate's Newsletter Substack — what Anthropic/Google/Manus learned on long-running agents](https://natesnewsletter.substack.com/p/i-read-everything-google-anthropic)
- [hyperdev.matsuoka.com — Anthropic, We Have A Problem](https://hyperdev.matsuoka.com/p/anthropic-we-have-a-problem)

### Surveys + reports
- [Stack Overflow Developer Survey 2025 — AI](https://survey.stackoverflow.co/2025/ai)
- [Stack Overflow Developer Survey 2025](https://survey.stackoverflow.co/2025/)
- [Stack Overflow blog — Developers remain willing but reluctant to use AI](https://stackoverflow.blog/2025/12/29/developers-remain-willing-but-reluctant-to-use-ai-the-2025-developer-survey-results-are-here/)
- [GitHub Octoverse 2025 — A new developer joins GitHub every second](https://github.blog/news-insights/octoverse/octoverse-a-new-developer-joins-github-every-second-as-ai-leads-typescript-to-1/)
- [GitHub Blog — How AI is reshaping developer choice](https://github.blog/ai-and-ml/generative-ai/how-ai-is-reshaping-developer-choice-and-octoverse-data-proves-it/)
- [arxiv 2512.04123 — Measuring Agents in Production](https://arxiv.org/abs/2512.04123)
- [arxiv 2601.21233 — Just Ask: Curious Code Agents Reveal System Prompts in Frontier LLMs](https://arxiv.org/html/2601.21233v1) — Claude Code system prompt = 6,973 tokens
- [arxiv 2604.14401 — Credo: Declarative Control of LLM Pipelines](https://arxiv.org/html/2604.14401)
- [Stanford HAI — DSPy: Compiling Declarative Language Model Calls](https://hai.stanford.edu/research/dspy-compiling-declarative-language-model-calls-into-state-of-the-art-pipelines)

### Conference references
- [AI Engineer Summit 2025 — Agents at Work](https://www.ai.engineer/summit/2025/schedule) — Anthropic's Barry Zhang: *"Agents are models using tools in a loop"*
- [AI Engineer 2025](https://www.ai.engineer/2025)
- ODSC — *Blueprint for Scalable AI Agents — Insights from Agentic AI Summit Week 1* (referenced)

### Miscellaneous adoption signals
- [TechCrunch — Browser Use viral](https://techcrunch.com/2025/03/12/browser-use-one-of-the-tools-powering-manus-is-also-going-viral/)
- [Karpathy Dec-2025 viral tweet (referenced via 36kr translation)](https://eu.36kr.com/en/p/3639839157783687) — *"agents, sub-agents, prompts, contexts, memory, modes, permissions, tools, plugins, skills, hooks, MCP, LSP, slash commands, workflows, IDE integrations"*
