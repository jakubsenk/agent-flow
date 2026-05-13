# Phase 1 — Research Questions (Run 2, finalized)

**Run:** 2026-04-26-A-research-run2 (forge-research, sub-projekt A v8.0.0)
**Status:** USER-PROVIDED FINALIZED (Phase 1 divergent generation skipped — otázky byly explicitně předány uživatelem na základě Run 1 Top 10 shortlistu)
**Datum:** 2026-04-26

---

## Origin

Otázky Q13–Q23 byly nominovány uživatelem s explicitní vazbou na Run 1 final.md (`.forge/2026-04-26-A-research-run1/phase-2-research-answers/final.md`, 871 řádků), který:

- Identifikoval Top 10 ranked shortlist 18 frameworků z Q12 (auto-scored 5 kritérií, weighted)
- Surfacel 10 cross-cutting anomalies (Run 1 final.md sekce "Anomalies and surprising findings")
- Konvergentní 5/5 lens findings na klíčových paradigmatech (markdown+YAML frontmatter, generic+overlay production-validated, single-vs-multi task-type bifurcation, Goldilocks prompt zone, event-driven HITL)

Run 2 = 10 framework deep-dives (Q13–Q22, jeden framework per Q) + Q23 = cross-run paradigm synthesis (čte Run 1 final.md + Q13–Q22 reporty Run 2 → produkuje recommendation pro v8.0.0 A.1 brainstorm).

---

## Šablona Q13–Q22

Pro každý framework {F}:

> Hluboká analýza {F} z hlediska:
> - Granularita agentů (role definition, prompt strategy, jak velký je jeden agent)
> - Pipeline configuration mechanism (markdown / YAML / JSON / code / meta-gen)
> - Per-project customization (overlay / inheritance / generation / append-to-prompt)
> - HITL pattern (kde a jak — explicit examples)
> - Stateful vs stateless agent design
> - Specifické "lessons learned" pro {F} (známé pain points, scaling issues, community feedback)
> - Co lze přenést do markdown-only Claude Code plugin (ceos-agents kontext)
> - Co je framework-specific (runtime, language lock-in, vendor dependency)
> - Citace: docs URL + konkrétní GitHub source files (path:line)

---

## Q13 — opencode (sst)

Run 1 score 4.75. TUI agent platform, declarative `.opencode.json` agents, 149.7k★ in 12mo (Founded 2025-04-30), 1282 commits/30d (top velocity Run 1). Multi-provider abstraction, "Claude Max routing trick" went viral.

Run 2 deep-dive should explore: `.opencode.json` schema, declarative agent definition pattern, multi-provider abstraction layer, terminal-first UX implications for ceos-agents distribution. **Verify Anomaly 1** (paradigm shift in distribution model — TUI agents won 2026 thesis).

## Q14 — superpowers (Jesse Vincent / obra)

Run 1 score 4.60. Opposite philosophy to BMAD; small composable skills; sub-agent dispatch; "VERY token light" core; Anthropic marketplace adopted Jan 2026; Simon Willison endorsement.

Run 2 deep-dive should explore: skill granularity decisions, sub-agent dispatch patterns, marketplace integration model, comparison vs BMAD viral packaging vs superpowers composable. **Verify Anomaly 3:** agent-4 cited 165k★ per quemsah index (94k March → 121k April → 165k now); independent source pasqualepillitteri.it April 2026 confirms 121k single-repo. Hypothesis: 165k = marketplace aggregate. Run 2 ověř empiricky.

## Q15 — Claude Code (subagents + skills + plugins)

Run 1 score 4.45. Host platform, Anthropic-blessed customization standard. 5-tier subagent priority (Managed > CLI > Local > Project > User > Plugin). Append-to-prompt teammate pattern. Skills format: SKILL.md frontmatter + reference/ + scripts/. Progressive disclosure 3-tier (metadata ~100 tokens, SKILL.md <5k, bundled resources).

Run 2 deep-dive should explore: plugin permissions architecture, hook lifecycle (12 events), `disable-model-invocation` semantics (issue #26251 known limitation), CLAUDE.md hierarchy, skills SKILL.md spec evolution. **Verify Anomaly 8:** Anthropic's own production system prompt = 6,973 tokens (arxiv 2601.21233) vs Anthropic-published guidance favoring "Goldilocks moderate" prompt length. Vendor-vs-publication gap?

## Q16 — Cursor (Composer + 2.0)

Run 1 score 4.45. Top production coding agent (>$500M ARR est); Composer 1 (Nov 2025) = single MoE + tool harness; 2.0 (Nov 2025) = 8 parallel agents in git worktrees + IDE-native synchronous accept. "4× faster" claim; Composer trained via RL specifically for new harness.

Run 2 deep-dive should explore: Composer architecture (RL-trained model behind tool harness), 2.0 worktree orchestration, `.cursor/rules` customization mechanism, AGENTS.md integration, IDE-native HITL patterns.

## Q17 — OpenAI Agents SDK

Run 1 score 4.30. First-party Python SDK March 2025; production successor to Swarm. Handoffs as tools primitive (LLM picks dispatch via tool-call). `Agent.as_tool(parameters=...)` for nested specialist without transferring conversation. Decision rule (handoff vs as_tool) clearest in OSS. Codex Subagents typed inheritance (inherit-with-override) closest production-shipping inheritance model.

Run 2 deep-dive should explore: Handoff dataclass, agents-as-tools vs handoff trade-offs, Guardrails architecture, Sessions, Codex Subagent inheritance fields.

## Q18 — Microsoft Agent Framework + Magentic-One

Run 1 score 4.30. Vendor-led declarative; created 2025-04-28; 193 commits/30d; YAML `declarative-agents/` + formula expressions (`=Local.ServiceParameters.IsResolved`) + ConditionGroup; production successor AutoGen + Semantic Kernel (1.0 Oct 2025); Magentic-One 2-loop bookkeeping (task ledger + progress ledger; ~92% correct dispatch on benchmarks per paper); GAIA + WebArena results.

Run 2 deep-dive should explore: declarative-agents YAML schema, formula language semantics, Magentic-One orchestrator-with-ledger pattern (`_prompts.py:46-94`), Optional Plan Review + Stall Detection HITL gates, `kind: ConditionGroup` vs LLM dispatch. **Verify Anomaly 7:** declarative-agents/workflow-samples/ je most explicit vendor signal že YAML-declarative is enterprise future, ale agent-5 také cituje "no top vendor ships YAML pipeline DSL as primary mechanism." Tension: enterprise YAML emerging but not-yet-vendor-canonical. Run 2 ověří aktuální stav adoption.

## Q19 — BMAD-METHOD

Run 1 score 4.25. Closest in spirit to ceos-agents v8.0.0; SKILL.md frozen base + customize.toml overlay (3-tier merge: scalars override, arrays append, arrays-of-tables match by code/id) + steps/*.md procedural decomposition. 45.7k★ Claude Code plugin format. v3→v5 migration history publicly observable; v6 alpha critique surfaces real complexity costs (50+ workflows, 19 agents).

Run 2 deep-dive should explore: customize.toml semantics in detail, scaling pain (v6 issues #675, #1062, #2003), persona-menu vs skill-dispatch granularity hybrid, SDLC role boundaries (Analyst/PM/Architect/SM/PO/Dev/QA/TechWriter), v3→v5 migration history, v6 alpha critique.

## Q20 — Devin (Cognition)

Run 1 score 4.25. Goldman Sachs 12,000-dev pilot; Nubank, Ramp, Mercado Libre, Citi; "compound AI system" Planner + Coder + Critic + Browser (4 components); $20/mo from $500/mo; 200 min autonomous; 13.86% SWE-bench end-to-end; 3-4× productivity at Goldman; defect rate 1.5-2× higher than senior dev; PR review cycles 1.5-2.3.

Run 2 deep-dive should explore: compound architecture component boundaries, async-autonomous trade-offs (200 min runtime), Cognition "Don't Build Multi-Agents" essay reasoning (write-task focus), Edit Apply Models refactor away from compound to single-model, Goldman pilot details. **Verify Anomaly 9:** Cognition's "Don't Build Multi-Agents" essay (June 2025) vs Anthropic's "+90.2% multi-agent on internal evals" (June 2025) — explicit contradiction, both shipped same month. Resolution per Run 1: task type (write vs read). Run 2 prohloubí — kdy multi-agent vyhrává, kdy single-agent.

## Q21 — GitHub Copilot Coding Agent

Run 1 score 4.25. GitHub-backed Spec-Driven Development pipeline (spec → plan → implement → review gates); 10M+ paid Copilot seats; canonical issue-to-PR async workflow; Copilot Workspace tech rolled into Coding Agent (April 2024 launch → May 30, 2025 sunset → Sep 2025 GA); proprietary closed-details but architectural pattern publicly described (sub-agent system, GitHub-native HITL gates).

Run 2 deep-dive should explore: spec-plan-implement gate pattern (closest production analogue to ceos-agents implement-feature pipeline), issue-to-PR async workflow primitives, sub-agent architecture (per public docs), HITL gate placement vs strategic-gates ceos-agents pattern, integration with `.github/workflows/`.

## Q22 — Cline

Run 1 score 4.05. IDE-resident; per-step HITL exemplar; 61.0k★, 1M+ VSCode installs; modular system prompt composed at runtime from components (`agent_role.ts:15`, `objective.ts`, `rules.ts`, `capabilities.ts`, `mcp.ts`); empirically validated approval-every-step pattern; "Auto Approve" mode added under user friction (CC5 controversy reference).

Run 2 deep-dive should explore: modular component-prompt composition (precedent for ceos-agents agent customization), per-step HITL UX trade-offs, "Auto Approve" friction-driven feature lessons, single-agent IDE-resident architecture as comparison-axis vs orchestrator-driven ceos-agents.

---

## Q23 — Cross-run paradigm synthesis (FINÁLNÍ otázka v Run 2)

Přečti Run 1 final.md (`.forge/2026-04-26-A-research-run1/phase-2-research-answers/final.md`) i Q13–Q22 reporty z tohoto Run 2 a vyrob cross-run paradigm synthesis pro ceos-agents v8.0.0:

1. **Komparativní matrice** (10 frameworků × dimensions: agent granularity / pipeline config / per-project customization / HITL / stateful / runtime dependency / public-release readiness / migration cost / community size / production adoption) s evidence-based scores napříč všemi Q1–Q22.

2. **Identifikace paradigmat v ekosystému** (Run 1 agent-3 source-code analýza našla 5 clusters: markdown-procedural, declarative YAML, generalist + tool harness, code-defined graph, LLM-orchestrator-with-ledger). Per paradigm: kdo ho používá, co je core mechanism, kdy vyhrává, kdy prohrává. Pokud Run 2 deep-dives odhalí další paradigma nebo přepíše tento clustering, zdokumentuj to.

3. **Doporučení paradigmatu pro ceos-agents v8.0.0** s explicit trade-offs:
   - Generic+overlay (status quo extended) vs per-project agents vs meta-gen (per Anomaly 10: meta-gen production = none jako of 2026-04, frontier choice if adopted now)
   - Hardcoded markdown skills vs declarative pipeline config vs hybrid (per Anomaly 7: enterprise YAML emerging but not-yet-vendor-canonical)
   - HITL strategy (zero gates / per-stage / strategic / event-driven) — Cline (Q22) per-step exemplar, GitHub Copilot (Q21) strategic gates, Devin (Q20) zero gates exemplar
   - Stateful vs stateless agent design (per Run 1 Q4 coverage)
   - Single-agent vs multi-agent (per Anomaly 9: task type matters — write vs read)

4. **Evidence trail per claim** — každý claim citovaný na konkrétní Q z Run 1 (Q1–Q12) nebo Run 2 (Q13–Q22). Žádné apriori biases.

5. **Output:** section-ready vstup pro A.1 brainstorm a následný `2026-04-MM-A-agent-shape-design.md` spec. Produkuj v češtině, technické termíny anglicky.

---

## Anomalies k surfovat napříč Run 2

Z Run 1 final.md "Anomalies and surprising findings":

1. opencode 149.7k★ in 12mo paradigm-shift signal (Q13 priorita)
2. Mastra 703 commits/30d top velocity, TypeScript overtook Python jako #1 GitHub language Aug 2025
3. superpowers stars discrepancy (Q14 priorita)
4. MetaGPT 67.4k★ ale jen 2 real-world adopting projects (Wang et al. arxiv 2512.01939) — GitHub stars ≠ adoption (most important Q12 caveat)
5. Roo Code shutdown 2026-04-21 despite 3M installs ("Roo Code hit 3 million installs. We're shutting it down to go all-in on Roomote")
6. AutoGen retired 2025-10 (succeeded by MS Agent Framework), 57k★ but 0 commits 30d — star count without commit velocity = stale signal
7. MS Agent Framework declarative YAML tension (Q18 priorita)
8. Anthropic's production prompt 6,973 tokens vs published Goldilocks guidance (Q15 priorita)
9. Cognition vs Anthropic multi-agent contradiction (Q20 priorita)
10. 5/5 lens convergence on absence of meta-gen production deployment (excluding Replit Agent 3); emerging research (MetaGen, ADAS, MetaSynth, Meta-Prompting Protocol all 2025–2026 papers); field 12-24 months from production-ready meta-gen jako of 2026-04

## Excluded references substantively important (Run 1)

Agenti smí surfovat:

- **Anthropic Multi-Agent Research System** (#11, score 4.00) — orchestrator-worker; Lead + 3–5 parallel sub-agents; +90.2% vs single-agent Opus 4 on internal evals; 15× tokens vs chat
- **Mastra** (#12, 3.90) — TypeScript ecosystem, 703 commits/30d (top velocity), first-class suspend/resume
- **OpenHands** (#13, 3.80) — only OSS production-grade SDK with published architecture paper (V1 SDK arxiv 2511.03690); 72.1k★; 70.8% SWE-bench Verified; codeact agent + microagents directory (`.openhands/microagents/`); precedent for ceos-agents agent set; AAIF governance integration
- LangGraph (3.70), CrewAI (3.65), Pydantic AI (3.65), Strands Agents (AWS, 3.40), wshobson/agents (3.25, closest commercial peer to ceos-agents in markdown-plugin space)

---

## Specifické pokyny pro Run 2

1. **Jazyk:** výstupy česky, technické termíny + framework names + citace anglicky
2. **Žádné apriori biases** — pouze evidence-based claims s citacemi na docs/source/papers
3. **Q23 (cross-run synthesis) je architektonicky nejdůležitější otázkou celého výzkumu** — věnuj jí plnou hloubku, ne shortcut summary; zatímco Q13–Q22 deep-dives mohou být per-framework focus, Q23 musí pracovat s celou evidence base napříč Q1–Q22
4. **Token budget:** unrestricted (user explicitně povolil "klidne velky")
5. **Run 1 zmínky a anomálie výše jsou kontext-hint, NIKOLI definitivní seznam** — agenti smí jít hlouběji, ověřit Run 1 anomálie empiricky, surfovat dodatečné findings
6. **Run 1 měl 5 lenses** (academic / production / OSS-code / community / vendor); **Run 2 zachová stejnou diverzitu** napříč N paralelními agenty (10 framework-specific deep-dives + 1 synthesis)

## Output paths Run 2

```
.forge/2026-04-26-A-research-run2/
├── phase-1-research-questions/
│   └── final.md                       (this file)
└── phase-2-research-answers/
    ├── agents/
    │   ├── agent-Q13-opencode.md
    │   ├── agent-Q14-superpowers.md
    │   ├── agent-Q15-claudecode.md
    │   ├── agent-Q16-cursor.md
    │   ├── agent-Q17-openai-agents-sdk.md
    │   ├── agent-Q18-ms-agent-framework.md
    │   ├── agent-Q19-bmad-method.md
    │   ├── agent-Q20-devin.md
    │   ├── agent-Q21-gh-copilot.md
    │   └── agent-Q22-cline.md
    ├── synthesis.md                   (Q23 cross-run synthesis)
    ├── review-{1..3}.md
    └── final.md
```
