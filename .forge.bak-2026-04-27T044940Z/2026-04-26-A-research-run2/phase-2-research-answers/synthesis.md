# Cross-Run Paradigm Synthesis — ceos-agents v8.0.0 Agent Shape Rework

**Dokument:** Q23 Cross-Run Paradigm Synthesis
**Datum:** 2026-04-26
**Autor:** Senior Synthesis Architect (forge-research Run 2 synthesis agent)
**Vstup:** Run 1 final.md (Q1–Q12, 5 lenses) + Run 2 agents Q13–Q22 (10 framework deep-dives)
**Účel:** Section-ready vstup do A.1 brainstormu a `2026-04-MM-A-agent-shape-design.md` spec
**NIKOLI rozhodovací dokument** — A.1 brainstorm provede architektonické rozhodnutí

---

## 1. Executive Summary

1. **Generic+overlay je jediný production-validated public-release pattern napříč všemi zdrojovými daty.** 5/5 Run 1 lenses + 10/10 Run 2 deep-dive frameworks konvergují: append-to-prompt overlay (CLAUDE.md/AGENTS.md/customize.toml/Agent Overrides) je standardní způsob customizace plugin-style agentů. Per-project full-duplication nemá vendor exemplar. Meta-gen má 0 production deployments k 2026-04 [Q8, Q11, Q13, Q14, Q15, Q19].

2. **Vendor consensus 2026-Q2: markdown pro instrukce, YAML pouze pro config/frontmatter.** 100% top-15 Claude Code pluginů, Anthropic Skills 32-page playbook (2026-01-29), AGENTS.md AAIF Linux Foundation steward, Karpathy LLM Wiki pattern (2026-04) — všechny potvrzují markdown+YAML-frontmatter jako canonical. BMAD v6.1.0 (2026-03) explicitně zrušil YAML workflow engine a přešel zpět na čistý markdown. Jediná výjimka: MS Agent Framework 1.0 GA (enterprise tier, .NET/Python runtime required) [Q12, Q15, Q18, Q19].

3. **Klíčová bifurkace: plugin-ecosystem markdown vs enterprise YAML se v 2026-Q2 prohlubuje, nikoli konverguje.** Plugin ecosystem (Anthropic, BMAD, superpowers, Claude Code) tvrdne kolem markdown+frontmatter. Enterprise IT (MS Agent Framework) tvrdne kolem YAML declarative DSL. ceos-agents musí explicitně vybrat stranu [CC8 z Run 1, Q18].

4. **Single-vs-multi-agent debata je vyřešena task-type bifurkací, NE universálním vítězem.** Write tasks → single-threaded context wins (Cognition, Cline). Read/research tasks → parallel sub-agents win (Anthropic Multi-Agent Research +90.2%). Cognition částečně revertoval v 2026-03 ("Devin Manages Devins") — orchestrator deleguje decomposable write subtasks na managed Devins s clean-slate kontextem. Tato architektura je přesnou analogií k ceos-agents orchestrating skill + stateless sub-agent dispatch [CC1 z Run 1, Q20].

5. **Run 2 opravuje 9 Run 1 nepřesností.** Klíčové: (a) Claude Code plugin subagenti nemohou použít `hooks`, `mcpServers`, `permissionMode` frontmatter — **blocking constraint pro v8.0.0 design** [Q15, Oprava 2]; (b) Magentic-One GAIA = 38% overall, ne 92% dispatch rate (92% byla human baseline, dvě odlišné metriky) [Q18, Oprava 3]; (c) Goldman Sachs Devin defect/PR-cycle data jsou **unverified** — žádný third-party publikovaný zdroj [Q20, Oprava 5]; (d) Anthropic 6,973-token Claude Code prompt = sémantická self-description z arxiv 2601.21233, ne přesné měření; reálný baseline 27–31k tokenů včetně tool definitions [Q15, Oprava 8]. Plus opravy hook event count (12→31), Devin "compound architecture" (community inference), Copilot 4.7M paid (ne 10M+), Cline 3.7M VSCode installs (ne 1M+), 5-tier vs 6-tier subagent priority, superpowers 168k★ single-repo. **Plný seznam viz sekce 7** (10 numbered oprav).

6. **HITL evoluce je jednoznačně friction-driven: granular auto-approve categories, ne odstraňování gates.** Cline za 5 měsíců produkce přidala Auto Approve ("most requested feature"), pak YOLO mode. Cursor přidalo YOLO mode. ceos-agents `--yolo` flag je ecosystem-aligned. Per-step gates jsou production anti-pattern pro iterativní coding workflows [Q22, Q16, Q6].

7. **ceos-agents 21 agentů je na outer edge production precedentu, ale architektonicky defensible.** Devin = 4 komponenty, BMAD po konsolidaci = 6, Anthropic research = 1+3-5, Magentic-One = 5. Ale: Kim et al. (arxiv 2512.08296) "per-agent reasoning capacity thins past 3-4 under fixed compute" + BMAD v4→v6 konsolidoval 19+ agentů → 6 pro zjednodušení. Konsolidační kandidáti pro v8.0.0: (triage-analyst + code-analyst), (test-engineer + e2e-test-engineer) [Q2 z Run 1, Q19, Q20].

8. **Stateless dispatch + externalized state (state.json + git) je production-validated hybrid.** Copilot: stateful uvnitř session, stateless mezi sessions, stav externalizován do git/draft-PR. Devin "Manages Devins": parent stateful, managed Devins clean-slate. ceos-agents current pattern (stateless agent dispatch + state.json) je functionally identical k tomuto production paradigmatu [Q20, Q21, Q4 z Run 1].

9. **Meta-gen jako architektonická varianta pro v8.0.0 je frontier choice s 0 production precedents.** Akademická literatura (MetaGen arxiv 2601.19290, ADAS, MetaSynth) ukazuje feasibility. Žádný z 10 deep-dive frameworků neimplementuje meta-gen jako primární architekturu. LLM-as-config-interpreter je "weakest link" per 5/5 Run 1 lenses [Q8, Q5c z Run 1].

10. **Run 2 vyvrátila Anomaly 3 (superpowers stars) a potvrdila Anomaly 10 (meta-gen no production).** BMAD star count verifikován na 45.7k (ne 29.6k — dočasná anomálie). Cline VSCode installs verifikovány na 3.7M (ne 1M+ jak bylo odhadováno). Goldman Sachs Devin defect-rate data (1.5-2×) nemá third-party verification [Q14, Q22, Q20].

---

## 2. Komparativní Matrice

10 frameworků × 10 dimenzí. Formát: **hodnota** (evidence Q-reference).

| Framework | 1. Agent granularity | 2. Pipeline config | 3. Per-project customization | 4. HITL pattern | 5. Stateful vs stateless | 6. Runtime dependency | 7. Public-release readiness | 8. Migration cost (do ceos) | 9. Community size | 10. Production adoption |
|---|---|---|---|---|---|---|---|---|---|---|
| **opencode** | thin/mid — 4 built-in (build, plan, general, explore) + custom `.opencode/agents/*.md` [Q13] | JSON (opencode.json) + AGENTS.md; žádný YAML pipeline DSL; emergentní pipeline z LLM [Q13] | 3-tier overlay: global → project → per-agent; `instructions: []` additive; 8-vrstvá precedence [Q13] | Plan mode (read-only) → Build mode (manual switch); permission-per-tool-per-agent [Q13] | Stateless dispatch mezi session; stateful uvnitř session; git snapshot [Q13] | Bun + TypeScript runtime, HTTP server, Drizzle ORM — nekompatibilní s markdown-only [Q13] | GA (v1.14.25, daily releases); 150k★ [Q13] | HIGH (runtime; overlay pattern konceptuálně přenositelný) [Q13] | 150k★, 6.5M monthly devs, 14.5M npm downloads/month [Q13] | Claude Max OAuth routing (2026-01 viral); po Anthropic enforcement ztráta části base; 10 named enterprise integrations [Q13] |
| **superpowers** | mid — 14 SKILL.md soubory (100–371 řádků); 1 dedikovaný agent (code-reviewer.md); "small composable" filozofie [Q14] | Žádný pipeline DSL; skill dispatch přes using-superpowers meta-skill; sub-agent dispatch přes Task tool; 4-stavový reporting (DONE/DONE_WITH_CONCERNS/NEEDS_CONTEXT/BLOCKED) [Q14] | Žádná nativní per-project customization; deleguje na CLAUDE.md/AGENTS.md hierarchii; žádná customize.toml analogie [Q14] | 4 strategické explicitní gates: brainstorm approval, plan execution method, TDD Iron Law, verification-before-completion [Q14] | Stateless fresh-context sub-agenti; self-contained prompty; nikoli session history pass-through [Q14] | None — pure markdown plugin; Claude Code platform dependency [Q14] | GA (v5.0.7); 168k★ na obra/superpowers; Anthropic marketplace Jan 2026 [Q14] | LOW-MEDIUM (kompatibilní filozofie; customization slabší) [Q14] | 168k★ (obra/superpowers); 121k★ ověřeno April 2026 (pasqualepillitteri.it) [Q14] | Simon Willison endorsement; Anthropic marketplace; ~700k+ users estimate z marketplace install data [Q14] |
| **Claude Code** | mid — 4+ built-in subagents (Explore, Plan, General, statusline-setup); plugin tier 5 (nejnižší); custom via .claude/agents/ (tier 3) [Q15] | Skills (SKILL.md) + Subagents + Hooks (31 events) + Plugins; žádný pipeline DSL; 3-tier progressive disclosure (Tier 1 ~100 tokens, Tier 2 <5k, Tier 3 bundled) [Q15] | 5-tier priority: Managed > CLI > Project > User > Plugin; append-to-prompt teammate pattern; project/.claude/agents/ override plugin tier [Q15] | 6 permission modes (default/acceptEdits/auto/dontAsk/bypassPermissions/plan); AskUserQuestion tool; event-driven per-tool-call gates [Q15] | Stateful uvnitř session (auto-compaction 5-layer pipeline); stateless mezi sessions; persistent memory subagent option [Q15] | Claude Code platform (proprietary); žádný extra runtime pro plugin [Q15] | GA; flagship Anthropic product; Opus 4.7 87.6% SWE-bench Verified (2026-04-16) [Q15] | LOW (host platforma; plugin frontmatter constraints — viz Oprava 2) [Q15] | Platform-level adoption; 87.6% SWE-bench SOTA; agentskills.io open standard Dec 2025 [Q15] | Anthropic flagship product; named enterprise users (TELUS 13k solutions, 30% faster); cross-platform Skills standard [Q15] |
| **Cursor** | mid — Composer 1 = single MoE agent; 2.0 = 8× horizontal replication v worktrees; 2.5 = parent→child subagents; custom subagents viz Cursor 3 [Q16] | Žádný pipeline DSL; `.cursor/rules/*.mdc` + AGENTS.md overlay; emergentní pipeline z Composer model [Q16] | 3-tier: User → Team → Project rules; `.cursor/rules/` verzovatelné v git; Team Rules v Cursor Teams ($40/user/month) [Q16] | 2-tier: sync diff review (default) + YOLO mode; Cursor 3: /best-of-n jako structured confidence gate; empiricky průměr 4.68 rule souborů per projekt [Q16] | Stateful per worktree (filesystem-level); stateless mezi session; kontext nesdílen přes worktrees [Q16] | Electron/Node.js IDE (closed-source); nekompatibilní s markdown-only [Q16] | GA; $2B ARR, $50B valuation (April 2026); Cursor 3 jako "biggest architectural change since launch" [Q16] | HIGH (IDE runtime, proprietary model; overlay přenositelný) [Q16] | $2B ARR; "fastest B2B SaaS to $1B"; 100k+ paying teams estimate [Q16] | Anecdotal enterprise deployment (Cursor Teams); named: Stripe, Figma, Linear (plugin partners); >$2B ARR implied large installed base [Q16] |
| **OpenAI Agents SDK** | thin-mid — instrukce typicky 20–200 chars; canonical customer service demo = 1 triage + 4 specialists; "start with one agent" guidance [Q17] | Python code only; Runner.run(agent, input); handoffs jako tool-calls (LLM-driven dispatch); 4 primitiva (Agents, Handoffs, Guardrails, Sessions) + 2026-04-15: sandbox + long-horizon harness [Q17] | Library, ne plugin framework; per-project = Python class instantiation; Codex Subagents: TOML inherit-with-override v .codex/agents/ (closest production inheritance model) [Q17] | Per-tool-call gating přes needsApproval; RunToolApprovalItem; alwaysApprove/alwaysReject toggles; Input/Output Guardrails [Q17] | Sessions opt-in stateful (pluggable backends); per-agent stateless je default; RunContextWrapper DI [Q17] | Python (nebo TypeScript) runtime required; nekompatibilní s markdown-only [Q17] | GA (March 2025); 25.2k★; 2026-04-15 next evolution update [Q17] | HIGH (Python runtime; Codex TOML inherit pattern přenositelný) [Q17] | 25.2k★; OpenAI-first-party; enterprise tier via Codex [Q17] | OpenAI Codex production; enterprise customers přes Codex API; named: žádní veřejní k 2026-04 [Q17] |
| **MS Agent Framework** | thin — declarative YAML agent = 1-3 věty instructions; behaviour v workflow YAML, ne v agent def; Magentic-One = 1 Orchestrator + 4 specialists [Q18] | YAML declarative workflows + graph-based runtime; ConditionGroup formula expressions (ne LLM); stale surfaces: Workflows.Declarative still --prerelease NuGet k 1.0 GA [Q18] | Deklarativní agenti jako per-project YAML konfigs; middleware layers; 3 deployment scopes [Q18] | Magentic-One: 8 fází vč. Optional Plan Review (gate 2) + Stall Detection (gate 6); Question/RequestExternalInput/Confirmation actions v YAML [Q18] | Session-based state (Semantic Kernel inheritance); pause/resume + checkpointing; stateful orchestration [Q18] | .NET nebo Python runtime required; Azure cloud native; nekompatibilní s markdown-only [Q18] | 1.0 GA 2026-04-03; Workflows.Declarative = --prerelease; 9.8k★ [Q18] | HIGH (.NET/Python runtime; dual-ledger konceptuálně přenositelný) [Q18] | 9.8k★; 193 commits/30d; Microsoft-backed [Q18] | Hyperscaler backing; AutoGen + Semantic Kernel user base (57k★ + 23k★); 1.0 GA enterprise-ready [Q18] |
| **BMAD-METHOD** | mid-deep — 6 SDLC role agents (v6 stable po konsolidaci z 19+); broad persona + menu; SKILL.md 142–485 řádků; steps/*.md decomposition 2-3k tokens/step [Q19] | Markdown procedural (unified workflow.md od v6.1.0); steps/*.md decomposition; customize.toml TOML overlay; v6.1.0 ZRUŠIL YAML workflow engine (vrátil se k čistému markdown) [Q19] | 3-tier TOML overlay: base → team → user; 4 merge rules (scalar override, table deep-merge, array-of-tables match by code, array append); NO removal mechanism; sparse override pattern [Q19] | Persona-menu pattern (HITL-driven by design); uživatel vybírá z menu; BMAD je opak ceos-agents autonomous pipeline-first přístupu [Q19] | Stateless session (nový agent per invocation); stav předáván přes dokument artefakty (PRD, Architecture); žádný state.json [Q19] | None — pure markdown plugin; Claude Code platform [Q19] | GA (v6.4.0, 2026-04-25); 45.7k★ (ověřeno Q19 Run 2) [Q19] | LOW-MEDIUM (closest peer; customize.toml merge přenositelné) [Q19] | 45.7k★; BMAD v6 stable GA 2026-03-02; aktivní GH community [Q19] | 100+ named adopters v GH discussions; 55-58% project hour reduction claim (unverified); komunitní case studies [Q19] |
| **Devin** | thin-SaaS — 4 tools/prostředí (shell, editor, browser, planner UI); "compound AI" = marketing frame, NE multi-agent architektura; Devin 2.2 = self-review loop; "Devin Manages Devins" (2026-03) = parent orchestrator + managed Devins [Q20] | Hardcoded SaaS pipeline; žádný user-facing pipeline DSL; žádný config file; žádné hooks/profiles/custom agents v core flow [Q20] | Knowledge tab (per-repo instructions analogické CLAUDE.md); žádné file-based overlay; GitHub/Slack/Linear integrations [Q20] | Zero mandatory gates + async PR-boundary gate; optional interrupt; ~10 ACU soft limit (~150 min) [Q20] | Stateful per session; parent Devin stateful + managed Devins clean-slate (2026-03 architektura) [Q20] | Cloud SaaS only; nekompatibilní s on-premise/markdown-only [Q20] | GA; $20/mo (z $500/mo); enterprise tier [Q20] | HIGH (SaaS, nekompat. plugin; clean-slate dispatch přenositelný) [Q20] | Proprietary; Ramp 80 PRs/week; Goldman Sachs pilot; Nubank, Mercado Libre, Citi [Q20] | Goldman Sachs 12k-dev pilot (67% PRs merged vs 34% prior year); Ramp 10k hours/month saved; named Fortune 500 customers [Q20] |
| **GH Copilot Coding Agent** | thin-SaaS — 3 public komponenty (Plan Agent, Research Agent, Repair/Implementation Agent); custom agents .github/agents/*.yml od 2025-10; celkem odhad 3-5 interních [Q21] | Hardcoded GitHub backend; žádný user-configurable pipeline DSL; custom agents přes intent matching; co je konfigurovatelné: plan gate on/off, MCP servery, firewall rules [Q21] | 4-tier hierarchie: org → repo-global → path-specific → custom agents; AGENTS.md + .github/copilot-instructions.md + .github/instructions/*.instructions.md [Q21] | Strategic gates exemplar: Plan Gate (volitelný) + PR Gate (povinný) + CI/CD Gate (semi-automatický); žádné per-step gates [Q21] | Stateful uvnitř session (průběžné git commity); stateless mezi sessions; externalizace do git/draft PR [Q21] | GitHub Cloud backend; GitHub Actions compute; nekompatibilní s on-premise/markdown-only [Q21] | GA (Sep 2025); 4.7M paid subscribers (Microsoft FY26 Q2 — ne "10M+" jak bylo v Run 1) [Q21] | HIGH (SaaS, GitHub-specific; gate pattern přenositelný) [Q21] | 4.7M paid Copilot subscribers; GitHub platform embedding [Q21] | GitHub-native; enterprise GitHub tier; DOGE US government reported use; verifikovaná Fortune 500 adoption přes GitHub Enterprise [Q21] |
| **Cline** | thin — single-agent IDE-resident architecture; jeden LLM loop zpracovává vše; volitelné subagents jako subprocess (v3.58.0) [Q22] | Žádný pipeline DSL; emergentní pipeline z LLM tool-use decisions; Plan mode vs Act mode (manuální přepnutí) [Q22] | .clinerules/ (md/txt s YAML frontmatter paths: glob); cross-IDE compatibility (Cursor rules, Windsurf, AGENTS.md); Memory Bank = 6-file markdown systém [Q22] | Per-step approval jako founding principle; friction → Auto Approve ("most requested feature") v3.0.0 → YOLO mode v3.30.1 → 8 granular categories 2026; ~5 měsíců produkce → první ústupek [Q22] | Stateless mezi konverzacemi; stateful uvnitř jedné conversation thread; Memory Bank pro cross-session persistence [Q22] | VS Code extension (Node.js); nekompatibilní s markdown-only plugin distribucí [Q22] | GA; v3.81.0 (2026-04-24); 61k★; 3.7M VSCode installs [Q22] | HIGH (IDE extension, single-agent; .clinerules + YOLO timeline přenositelné) [Q22] | 61k★; 3.7M VSCode installs (ne "1M+" z Run 1); 57 commits/30d [Q22] | Žádní named enterprise customers k 2026-04; developer-individual adoption; VSCode marketplace popularity [Q22] |

---

## 3. Identifikace Paradigmat (revidovaný clustering)

### 3.1 Verifikace Run 1 5-cluster framework

Run 1 agent-3 (OSS-code lens) identifikoval **5 clusters** z analýzy 17 frameworků:
1. **Markdown-procedural** (BMAD, ceos-agents, wshobson)
2. **Declarative YAML** (MS Agent Framework, CrewAI)
3. **Generalist + tool harness** (Cursor, Devin, GitHub Copilot, Cline)
4. **Code-defined graph** (LangGraph, Strands, CrewAI Flow)
5. **LLM-orchestrator-with-ledger** (Magentic-One)

**Run 2 verifikace:** 5-cluster framework je **z velké části potvrzen**, ale vyžaduje **2 zpřesnění** a **1 nový sub-cluster**:

- **Cluster 1 (Markdown-procedural)** je potvrzen a rozšířen. BMAD v6.1.0 explicitně zrušil YAML workflow engine a vrátil se k markdown — silný kontra-signál vůči YAML-deklarativní migrace [Q19]. superpowers přidává sub-pattern "small composable skills" jako anti-thezi k BMAD monolithic workflow — oba jsou markdown-procedural ale s odlišnou granularitou [Q14].
- **Cluster 2 (Declarative YAML)** je potvrzen jako legitimní enterprise pattern ale s kritickým zjištěním: MS Agent Framework Workflows.Declarative stále ve `--prerelease` NuGet stavu i po 1.0 GA [Q18]. YAML v opencode.json je config (nikoli pipeline DSL) — opencode patří lépe do Cluster 3.
- **Cluster 3 (Generalist + tool harness)** je rozšířen o nový sub-cluster: **Autonomous SaaS loop** (Devin, GitHub Copilot Coding Agent) = cloud-hosted, zero user-configurable pipeline, PR-boundary gate jako jediný mandatory HITL. Odlišuje se od IDE-resident (Cursor, Cline) runtime modelem.
- **Cluster 4 (Code-defined graph)** je potvrzeno — LangGraph, Strands. LangGraph není v Top 10 (Python runtime incompatible), ale paradigm zůstává referenčně relevantní.
- **Cluster 5 (LLM-orchestrator-with-ledger)** je potvrzen (Magentic-One) ale přesněji zařazen jako **sub-pattern Cluster 4**, nikoli samostatný cluster — dual-ledger je implementační pattern uvnitř graph-based orchestrace [Q18].

**Revidovaný 4+1 clustering:**

### Paradigma P1: Markdown-Procedural Plugin

**Core mechanism:** Agenti a pipelines jsou definovány jako markdown soubory. Pipeline = hardcoded sekvence markdown instrukcí čtených LLM. Customization = overlay souborů (append-to-prompt nebo TOML merge). Žádný build system, žádný runtime, žádné binaries. Distribuce jako git repozitář nebo Claude Code plugin.

**Kdo ho používá:** BMAD-METHOD (45.7k★, v6.4.0), ceos-agents (v7.0.0), superpowers (168k★), wshobson/agents, Anthropic Skills (agentskills.io cross-platform standard) [Q14, Q15, Q19].

**Kdy vyhrává:**
- Distribuce jako Claude Code plugin — žádná infrastruktura na straně uživatele
- SDLC orchestration s definovanými fázemi (triage → fix → review → test → publish)
- Comunity / OSS adoption — markdown je universálně čitelný, commitovatelný, PRovatelný
- Teams kde ne-developers konfigurují agenty — markdown vs Python threshold
- Public release readiness — 100% top-15 Claude Code pluginů tímto paradigmatem [Q5d z Run 1, Q15]

**Kdy prohrává:**
- Long-running autonomous loops vyžadující runtime state (LangGraph state machine je spolehlivější)
- Complex conditional branching — "YAML document from hell" risk i v markdown procedural [CC8 z Run 1]
- Škálování past 20+ agentů — BMAD konsolidoval z 19+ → 6, komunita dokumentovala "complexity creep" [Q19]
- B2B enterprise s compliance requirements — runtime auditability chybí

**Public-release readiness paradigmu:** HIGHEST — všechny velké Claude Code pluginy. Anthropic-blessed standard. agentskills.io open standard.

### Paradigma P2: Declarative YAML Enterprise

**Core mechanism:** Agenti definováni krátkými YAML soubory (instructions = 1-3 věty). Chování definováno ve workflow YAML přes action types (If, ConditionGroup, Foreach, InvokeAgent, Question). Runtime = .NET nebo Python SDK. Formula language pro conditions (ne LLM dispatch). Stateful orchestrace s pause/resume.

**Kdo ho používá:** MS Agent Framework (1.0 GA 2026-04-03, Microsoft) [Q18]. Okrajově: CrewAI YAML role definitions (ale pipeline stále Python code).

**Kdy vyhrává:**
- Enterprise IT deployment s compliance, audit trail, version-control of behavior
- Integrace s Azure/Microsoft 365 ekosystémem
- Non-developer administrators konfigurující agentní chování bez psaní kódu
- Komplexní multi-tenant agent orchestrace s RBAC
- Organizace s existujícím Semantic Kernel / AutoGen investment (migration path) [Q18]

**Kdy prohrává:**
- Plugin-style distribuce — runtime dependency eliminuje Claude Code plugin deployment model
- Community/OSS adoption — YAML pipeline DSL má learning curve + Turing tarpit risk [CC8 z Run 1]
- Rychlá iterace — Workflows.Declarative stále prerelease i po 1.0 GA [Q18]
- Projekty bez Azure/Microsoft infrastructure
- Reasoning-model era — "less prescriptive engineering" trend jde opačným směrem [Q1 z Run 1]

**Public-release readiness paradigmu:** MEDIUM — 1.0 GA pro graph-based orchestration; Workflows.Declarative prerelease. Enterprise-only adoption signal.

### Paradigma P3: Generalist Tool Harness

**Core mechanism:** Jeden (nebo horizontálně replikovaný) generalistický agent s bohatou sadou tools. Pipeline = emergentní z LLM tool-use decisions, nikoli deklarativní sekvence. Customization = overlay souborů (AGENTS.md, .clinerules, .cursor/rules). HITL = per-action approval nebo YOLO mode.

**Sub-pattern P3a (IDE-resident):** Cursor, Cline — synchronní diff review v IDE, kontextová awareness o editovaném kódu.

**Sub-pattern P3b (Autonomous SaaS loop):** Devin, GitHub Copilot Coding Agent — cloud-hosted, async issue-to-PR, PR-boundary gate jako mandatory HITL.

**Kdo ho používá:** Cursor ($2B ARR), Cline (61k★, 3.7M installs), Devin (Goldman Sachs, Ramp, Nubank), GitHub Copilot Coding Agent (4.7M paid subscribers), opencode (150k★) [Q13, Q16, Q20, Q21, Q22].

**Kdy vyhrává:**
- General-purpose coding assistance (NE pipeline automation)
- Interactive development — uživatel vede konverzaci, ne pipeline
- Single developer/team workflows bez enterprise orchestration requirements
- Tasks kde task structure není předem definovatelná (open-ended bug fixing)
- High-frequency low-ceremony tasks (quick fixes, refactoring)

**Kdy prohrává:**
- Strukturované SDLC pipelines s AC verification, acceptance gates, rollback
- Multi-ticket batch automation (autopilot pattern)
- Tasks vyžadující explicitní role separation (fixer vs reviewer jako separate contexts)
- Enterprise compliance — emergentní pipeline není auditovatelná
- Token cost at scale — single-agent full-context accumulation vs stateless fresh-dispatch [Q4 z Run 1]

**Public-release readiness paradigmu:** HIGHEST (P3b SaaS) / HIGH (P3a IDE) — největší production adoption v ekosystému. Mainstream developer choice 2026.

### Paradigma P4: Code-Defined Graph

**Core mechanism:** Pipeline = directed graph definovaný v Python/TypeScript kódu. Nodes = Python funkce nebo agent invocations. Edges = deterministic nebo conditional transitions. Stav = sdílený graph state object. Runtime = LangGraph, Strands, Mastra. Optional: LLM-orchestrator-with-ledger sub-pattern (Magentic-One dual task+progress ledger).

**Kdo ho používá:** LangGraph (30k★, Klarna, Uber, Replit, LinkedIn), Strands (AWS), Mastra (23k★, 703 commits/30d), Magentic-One (MS Agent Framework) [Q18, Q12 z Run 1].

**Kdy vyhrává:**
- Complex conditional agent flows s deterministic control flow requirements
- Long-running stateful workflows s pause/resume/checkpoint
- Python/TypeScript ecosystem — full programmatic control
- Performance-critical paths — deterministic state machine spolehlivější než LLM dispatch
- Large engineering teams kde pipeline je "code to review and maintain"

**Kdy prohrává:**
- Non-developer customization — Python code vs markdown threshold
- Claude Code plugin distribution — runtime dependency incompatible
- Rapid iteration — graph topology changes require code changes, not markdown edits
- Community/OSS plugin ecosystem — Python SDK != plugin distributable

**Public-release readiness paradigmu:** HIGH (produkčně deployed) — ale relevantní pouze pro Python/TS projects, ne plugin ecosystem.

### 3.2 Cross-Paradigm Tensions

**Tension T1: opencode autonomous loop vs ceos-agents hardcoded pipeline**

Opencode: LLM autonomně rozhoduje o tool calls bez deklarativní stage sequence. ceos-agents: 8+ stage sequential markdown pipeline, deterministický order. Oba handleují bug-fixing. Opencode = P3 (emergentní pipeline), ceos-agents = P1 (procedural pipeline). ceos-agents pipeline je "scaffolded execution" pattern (citace Martinez & Franch taxonomy arxiv 2506.17208 zmiňuje synthesis agent — **citace NEOVĚŘENA v Run 2 source reportech, treat jako synthesis-agent inference**); Opencode je "emergent autonomy" cluster. Pro komplex SDLC (triage → AC extraction → review → acceptance gate) je P1 deterministic ordering kritický [Q13, Q5a z Run 1].

**Tension T2: BMAD persona-menu vs ceos-agents autonomous dispatch**

BMAD: uživatel vybírá agenta z menu (HITL-driven orchestration). ceos-agents: skill automaticky dispatche agenty bez user interaction (pipeline-first). Oba jsou P1 (markdown-procedural). Diferenciator: BMAD cílí kreativní SDLC (spec, PRD, UX design) kde user guidance per step přidává hodnotu. ceos-agents cílí CI/CD automation (bug fix, feature implementation) kde uživatelský input je gate, ne orchestrator [Q19, Q6 z Run 1].

**Tension T3: superpowers small composable vs BMAD monolithic SDLC**

Superpowers: 14 malých skills, žádná nativní per-project customization, zero pipeline definition. BMAD: 6 broad agents + 50+ workflows + customize.toml. Oba P1, oba >40k stars. Diferenciator: superpowers = TDD-driven code quality process; BMAD = full project lifecycle methodology. ceos-agents je blíže BMAD (pipeline-first, multiple stages), ale bere od superpowers sub-agent dispatch s fresh-context a strategické gates [Q14, Q19].

---

## 4. Doporučení Paradigmatu pro ceos-agents v8.0.0 (Structured Decision Space)

Tato sekce NEPOSKYTUJE rozhodnutí. Strukturuje decision space pro A.1 brainstorm s evidence-based trade-offs per option.

### 4.1 Customization Paradigm

**Option A: Generic+overlay extended (status quo →)**

- Zachovat 21 (nebo konsolidovaných ~12-16) agentů jako markdown soubory v `agents/*.md`
- Agent Overrides = append-to-prompt `customization/{agent-name}.md` soubory
- Rozšíření: přidat TOML overlay analogii BMAD `customize.toml` pro structured override vs append

✅ **Pros:** 5/5 Run 1 lenses + 8/10 Run 2 deep-dives potvrzují jako dominant production pattern [Q8, Q11]; nejnižší migration cost z v7; Anthropic 5-tier subagent priority explicitně endorsuje append-to-prompt [Q15]; update flow clean (plugin owns core, user owns overlay); BMAD `customize.toml` 3-tier merge semantics je produktionově validovaný pattern přenositelný přímo [Q19].

❌ **Cons:** Customization power limitovaná (append-only, no removal per BMAD explicit caveat [Q19]); 21 agentů na outer edge production precedentu (BMAD konsolidoval na 6 [Q19]); Agent Overrides directory append-to-prompt je méně structured než TOML merge — LLM může ignorovat append instructions [Q5c z Run 1].

Evidence Q-refs: [Q3 z Run 1, Q8, Q11, Q14, Q15, Q19].
Migration cost from v7: LOW.

**Option B: Per-project agents (full set per project)**

- Každý projekt dostane vlastní kopii agent set (`project-agents/`) s plnou free-dom modifikací
- Plugin dodává "template set" jako starting point

✅ **Pros:** Maximální customization power; project-specific agent tuning možný bez append constraints; plný přístup ke každému agent fieldu.

❌ **Cons:** 5/5 Run 1 lenses community-rejected anti-pattern [Q8]; maintenance burden HIGH (N projects × M agents × update cycle); update flow FRAGMENTED (každý user na independent track); žádný vendor exemplar [Q3 z Run 1, Q11]; Wang et al. (arxiv 2512.01939) "96% of top projects adopt multiple frameworks" = maintenance drift risk; negative transfer risk per ADP paper (arxiv 2510.24702) [Q3 z Run 1].

Evidence Q-refs: [Q3 z Run 1, Q8, Q11].
Migration cost from v7: MEDIUM (tooling needed pro template generation).

**Option C: Meta-gen (per-project agents generated from spec)**

- Meta-agent generuje agent set z CLAUDE.md description nebo `spec/` složky
- Automatický re-gen při plugin update nebo project spec change

✅ **Pros:** Ideální per-project tuning bez maintenance burden; self-evolving agent architectures (akademická evidence: MetaGen arxiv 2601.19290, ADAS) [Q8 z Run 1]; onboarding frictionless na "first run."

❌ **Cons:** 5/5 Run 1 lenses + 10/10 Run 2 deep-dives: 0 production deployments [Q8, Q11]; LLM-as-config-interpreter je "weakest link" per Q5c z Run 1 — meta-gen přidává celý extra LLM-decision-step; žádný vendor exemplar; QA story pro generated agents neřešena; "regen vs preserve customization" conflict unresolved [Q8 z Run 1, Q5c z Run 1].

Evidence Q-refs: [Q3 z Run 1, Q8, Q11, Q5c z Run 1].
Migration cost from v7: HIGH (design + implementation of meta-agent).

**Option D: Hybrid generic-base + project-tail (BMAD-style overlay)**

- Generic core agent set (základní instrukce) zůstává plugin-managed
- TOML/YAML overlay (`customization/{agent-name}.toml`) s typed merge semantics (ne jen append)
- Project-level `.claude/agents/{agent-name}.md` pro full override konkrétního agenta (tier 3 Claude Code)

✅ **Pros:** BMAD `customize.toml` 3-tier merge je production-validated u 45.7k-star Claude Code plugin [Q19]; Codex Subagents TOML inherit-with-override je nejbližší production-shipping inheritance model [Q17]; umožňuje selective override bez full fork; BMAD merge rules (scalars override, arrays append, array-of-tables match by code) jsou implementovatelné [Q19]; Claude Code tier 3 project agents override plugin agents nativně [Q15].

❌ **Cons:** TOML overlay = nový complexity layer oproti v7 append-only; BMAD "no removal mechanism" (additive-only) je inherentní constraint overlay paradigmatu [Q19]; customization discovery pro nové uživatele je non-trivial (BMAD GH issue #2003: "10-15× více času s BMAD") [Q19]; migration cost z v7 Agent Overrides = medium.

Evidence Q-refs: [Q17, Q19, Q15].
Migration cost from v7: MEDIUM.

### 4.2 Pipeline Config Paradigm

**Option A: Hardcoded markdown skills (current ceos)**

- `skills/fix-bugs/SKILL.md`, `skills/implement-feature/SKILL.md`, `skills/scaffold/SKILL.md` jako ~600-řádkové markdown procedury
- Hooks pro imperative escape hatch (Bash)

✅ **Pros:** BMAD v6.1.0 explicitně **revertoval z YAML zpět k markdown** (March 2026) — strongest evidence that markdown-procedural is superior to YAML pipeline for Claude Code plugin ecosystem [Q19]; MS Workflows.Declarative stále prerelease [Q18]; vendor evidence: "No vendor publishes YAML-pipeline-DSL exemplar for agent orchestration" [Q9 z Run 1]; provoz Hooks sekce = imperativní escape hatch bez Turing tarpit [Q9 z Run 1]; community consensus "YAML document from hell" [CC8 z Run 1].

❌ **Cons:** 600-řádkové markdown pipelines jsou monolithic — BMAD steps/*.md decomposition (2-3k tokens/step vs 15k monolithic) ukazuje alternativu [Q19]; čitelnost klesá s délkou; debugging pipeline failure je nestrukturovaný.

Evidence Q-refs: [Q9 z Run 1, Q18, Q19, CC8 z Run 1].
Migration cost from v7: ZERO.

**Option B: Declarative pipeline DSL (YAML/TOML)**

- `pipeline.yaml` definující stage sequence, conditions, agent assignments, HITL gates
- LLM interpretuje nebo runtime exekutuje

✅ **Pros:** MS Agent Framework 1.0 GA ukazuje enterprise adoption [Q18]; PayPal DSL paper (arxiv 2512.19769): 67% dev-time reduction, 74% LOC reduction, 78%→89% accuracy [Q5b z Run 1]; structured config čitelnější než 600-řádkový markdown.

❌ **Cons:** BMAD explicitně YAML zrušil (v6.1.0, March 2026) po zkušenosti s YAML v agent pipeline [Q19]; MS Workflows.Declarative prerelease [Q18]; CI/CD analogie (Jenkins/Tekton/Argo) konzistentně ukazuje Turing tarpit při komplexní logice [Q5b z Run 1]; žádný major vendor (Anthropic) neships YAML pipeline DSL jako recommended primary pattern [Q9 z Run 1]; LLM-as-YAML-interpreter není spolehlivý pro control flow [Q5c z Run 1].

Evidence Q-refs: [Q5b z Run 1, Q9 z Run 1, Q18, Q19].
Migration cost from v7: HIGH.

**Option C: Hybrid (markdown procedure + TOML overlay pro stage customization)**

- Markdown procedura zůstává primárním pipeline def
- TOML overlay umožňuje skip/extra stages bez edit SKILL.md
- Analogie: BMAD steps/*.md + customize.toml [Q19]; ceos Pipeline Profiles jako v7 precedent

✅ **Pros:** BMAD model kombinuje markdown procedure s TOML config overlay — production-validated [Q19]; ceos Pipeline Profiles (skip/extra stages) jsou již v7 feature — rozšíření k TOML je inkrementální; steps/*.md decomposition (2-3k tokens/step) je přenositelný pattern pro token reduction [Q19].

❌ **Cons:** Přidání TOML config layer zvyšuje komplexitu onboardingu; "sparse override" guidance (BMAD explicit: "copying full customize.toml is harmful") vyžaduje user education [Q19]; documentation burden roste.

Evidence Q-refs: [Q17, Q19, Q5b z Run 1].
Migration cost from v7: LOW-MEDIUM.

### 4.3 HITL Strategy

**Option A: Zero gates (current ceos --yolo)**

- Agent pipeline běží bez mandatory user confirmation
- Výsledek: PR jako první mandatory artifact

✅ **Pros:** Devin "Manages Devins" (2026-03) architektura = orchestrator bez per-step gates [Q20]; Ramp 80 PRs/week s Devin = production-validated zero-gate throughput [Q20]; ceos autopilot skill používá toto; YOLO mode formalizován v Cline, Cursor, Claude Code [Q22, Q16, Q15].

❌ **Cons:** Stack Overflow 2025: 46% developerů nedůvěřuje AI accuracy [Q6 z Run 1]; Stack Overflow 2026-02-18 "Mind the gap" follow-up potvrzuje trust deficit [Q6 z Run 1]; public release bez jakéhokoli defaultního HITL gate může odradit enterprise uživatele.

Evidence Q-refs: [Q20, Q22, Q6 z Run 1].

**Option B: Per-step gates (Cline original)**

- Každý tool call vyžaduje user approval

✅ **Pros:** Nejjasnější per-step HITL exemplar [Q22]; komunita ho chválí jako "safety-first" [CC5 z Run 1].

❌ **Cons:** Cline community pressure → Auto Approve přidán jako "most requested feature" po 5 měsících [Q22]; per-step gates jsou production anti-pattern pro batch automation; ceos-agents pipeline má ~50+ tool calls per fix-ticket → nepoužitelné [Q22].

Evidence Q-refs: [Q22, CC5 z Run 1].

**Option C: Strategic gates (current ceos default + decomposition)**

- Gates na klíčových bodech: triage (AC extraction), decomposition approval, acceptance-gate, pre-publish
- Odpovídá GitHub Copilot Plan Gate + PR Gate [Q21]

✅ **Pros:** GitHub Copilot Coding Agent = nejjasnější "strategic gates" exemplar v production (Plan Gate volitelný + PR Gate povinný + CI/CD Gate semi-automatický) [Q21]; Feng et al. L3 Consultant / L4 Approver taxonomy [Q6 z Run 1]; WorkOS "Confidence-Based Routing" pattern alignment [Q6 z Run 1]; ceos conditional acceptance-gate je "Confidence-Based Routing" [Q6 z Run 1].

❌ **Cons:** Počet gates je architektonické rozhodnutí bez empirické optimalizace pro ceos-agents konkrétně; academic gap: "no empirical user-trust data for HITL gate placement" [Q6 z Run 1, "No evidence found" #6].

Evidence Q-refs: [Q21, Q6 z Run 1].

**Option D: Event-driven gates**

- Gates jsou triggered events, ne fixed stage checkpoints: "pause when fixer iteration >3," "pause when reviewer says HIGH issue without clear fix"

✅ **Pros:** Magentic-One Optional Plan Review + Stall Detection (gate 6) = production-deployed event-driven gates [Q18]; Anthropic "Building Effective Agents" Dec 2024: "pause for human feedback at checkpoints or when encountering blockers" = explicitně event-driven framing [Q6 z Run 1]; vendor consensus = event-driven preferred over per-stage [Q6 z Run 1].

❌ **Cons:** No production framework in top-20 implements confidence-based event-driven gate as PRIMARY mechanism [Q6 z Run 1]; confidence calibration v LLMs stále unreliable [Q6 z Run 1]; implementace uvnitř markdown procedury je komplexní bez runtime support.

Evidence Q-refs: [Q18, Q6 z Run 1].

**Sub-projekt B compatibility note:** Options C a D jsou nejkompatibilnější s sub-projektem B (HITL) výsledky — oba jsou event-driven / strategic, nikoliv per-step. Option A (--yolo) by měl zůstat jako opt-in mode, nikoli default pro public-release.

### 4.4 Stateful vs Stateless Agent Design

**Option A: Stateless dispatch (current ceos)**

- Každý agent dostane fresh context s explicitními data z předchozích kroků
- state.json externalizuje pipeline state

✅ **Pros:** superpowers fresh-context sub-agenti s self-contained prompty [Q14]; Stateless DPM paper (arxiv 2604.20158): stateless 7-15× faster, 2 LLM calls vs 83-97 [Q4 z Run 1]; Anthropic: "Subagents prevent context bloat by isolating exploration in clean context windows" [Q4 z Run 1]; "Devin Manages Devins" = clean-slate dispatch per managed Devin [Q20]; token cost growth v stateful loops: 888 tokens iter 1 → 18,900 by iter 5 bez compaction [Q4 z Run 1].

❌ **Cons:** Každý dispatch re-requires context injection (triage output, code-analyst report) — overhead per handoff; information loss risk při neúplném context forwarding [Q7 z Run 1, Q5c z Run 1].

Evidence Q-refs: [Q14, Q20, Q4 z Run 1].

**Option B: Stateful sessions**

- Agenti sdílejí session state nebo conversation history
- OpenAI Sessions (opt-in, pluggable backends) [Q17]; Magentic-One 2-loop bookkeeping [Q18]

✅ **Pros:** Reduced context injection overhead; richer agent memory across turns; LangGraph shared state object je production standard [Q4 z Run 1].

❌ **Cons:** Token cost growth (stateful loops problematic bez compaction) [Q4 z Run 1]; "Stateless Decision Memory for Enterprise AI Agents" paper (arxiv 2604.20158) říká stateful architectures "violate enterprise deployment properties by construction" [Q4 z Run 1]; vendor "stateful" = within-agent-lifetime, ne across-agents [Q4 z Run 1]; Claude Code plugin subagents nemohou sdílet session state — platformové omezení [Q15].

Evidence Q-refs: [Q17, Q18, Q4 z Run 1, Q15].

**Option C: Externalized state (state.json + git) — current ceos extended**

- Agent state externalizován do state.json (pipeline metadata) + git (code changes)
- Analogie: GitHub Copilot průběžné git commity + draft PR jako stav [Q21]; ceos state.json + pipeline-history.md [Q4 z Run 1]

✅ **Pros:** Copilot model (stateful uvnitř session, stateless mezi sessions, stav externalizován do git) = production-validated hybrid [Q21]; ceos-agents state.json + pipeline-history.md je functionally identical k "structured note-taking" doporučení Anthropic [Q4 z Run 1]; auditovatelný, verzovatelný, restartovatelný.

❌ **Cons:** I/O overhead na state.json při každém kroku; při velkém počtu agentů state schema complexity roste (v6.9.0 schema s 16 additive fieldy je hranici čitelnosti).

Evidence Q-refs: [Q21, Q4 z Run 1].

### 4.5 Single-Agent vs Multi-Agent

**Option A: Single agent + tools**

- Jeden fixer agent zvládne triage, analýzu, fix, review, test internally přes tool calls

✅ **Pros:** Cline = single-agent s 61k★ a 3.7M installs [Q22]; Devin pre-2026-03 = single compound agent; mini-SWE-agent + Claude Opus 4.5 = 79.2% SWE-bench Verified s pouze bash [Q2 z Run 1]; Kim et al. (arxiv 2512.08296) "single-agent baselines outperform multi-agent on SWE benchmarks" [Q2 z Run 1]; token cost: 4× chat (single agent) vs 15× chat (multi-agent) [Q7 z Run 1].

❌ **Cons:** Role confusion — fixer nevidí kód jako reviewer; context accumulation bez role isolation degraduje kvalitu po iteracích; "context accumulates, focus degrades" — Cognition vlastní zdůvodnění pro přechod od single k multi (2026-03) [Q20]; Anthropic multi-agent research +90.2% pro read tasks [CC1 z Run 1].

Evidence Q-refs: [Q22, Q20, Q2 z Run 1, Q7 z Run 1].

**Option B: Multi-agent specialist set (current ceos)**

- 21 narrow specialists; každý dostane fresh dispatch

✅ **Pros:** Anthropic Multi-Agent Research +90.2% [CC1 z Run 1]; Magentic-One 5 specialists = production reference [Q18]; BMAD 6 SDLC roles (po konsolidaci) = validated at scale [Q19]; role separation = reviewer nikdy není biased od fixer context; acceptance-gate jako independent verifier je architektonicky čistý [Q2 z Run 1].

❌ **Cons:** ceos-agents 21 agentů = outer edge production precedentu; BMAD konsolidoval 19+ → 6 [Q19]; Yin et al. (arxiv 2511.00872): planning agents consume 65-67% tokens; Kim et al.: "per-agent reasoning capacity thins past 3-4 under fixed compute" [Q2 z Run 1]; 5× token cost overhead vs single-agent chat [Q7 z Run 1].

Evidence Q-refs: [Q18, Q19, Q2 z Run 1, CC1 z Run 1].

**Option C: Hybrid (single agent + parallel sub-agent dispatch when decomposable)**

- Core pipeline single-agent (pro write tasks)
- Sub-agent dispatch pro read tasks a independent domains (code-analyst, test-engineer, e2e-test)

✅ **Pros:** "Devin Manages Devins" (2026-03) = production exemplar tohoto patternu — orchestrator deleguje decomposable subtasks na managed Devins [Q20]; Cursor 2.0 8 worktrees = horizontal sub-agent dispatch pro independent tasks [Q16]; superpowers "dispatching-parallel-agents" = independent-domain simultaneous dispatch [Q14]; OpenAI "Agent.as_tool" pattern = nested specialist bez transfer conversation [Q17].

❌ **Cons:** Architektonická komplexita — kdy dispatch a kdy in-agent tool-use je non-trivial design decision; "microservices vs monolith" problema reprodukuje se v agent layer [Q7 z Run 1].

**Per-option: task type bifurcation (Anomaly 9 z Run 1, reframovaná v Q20)**

Cognition původní "Don't Build Multi-Agents" (June 2025) bylo o write tasks. Cognition "Devin Manages Devins" (2026-03) ukázal, že multi-agent je OK pro write tasks pokud jsou **decomposable** (narrow focus, clean-slate context per subtask). Bifurkace je teď:
- Write tasks, monolithic (single output, tight coupling) → single-agent wins
- Write tasks, decomposable (independent subtasks) → parent orchestrator + managed workers
- Read/research tasks (parallel exploration) → parallel sub-agents
- ceos-agents bug-fix pipeline = mix: triage/code-analyst = read → parallel OK; fixer↔reviewer = write, monolithic → sequential tight coupling; test-engineer = semi-independent → sub-agent OK [Q20, CC1 z Run 1].

Evidence Q-refs: [Q20, Q14, Q16, Q17, Q7 z Run 1, CC1 z Run 1].

---

## 5. Evidence Trail Audit

Každý klíčový claim sekcí 1-4 s Q-referencí a primárním zdrojem.

| Claim # | Claim | Q-references | Primární citace |
|---|---|---|---|
| C1 | Generic+overlay dominant production pattern, 5/5 lenses | Q3 z Run 1, Q8, Q11 | BMAD `customize.toml:13-15`; Anthropic 5-tier subagent docs [code.claude.com/docs/en/sub-agents]; AGENTS.md AAIF Linux Foundation 2025-12 |
| C2 | 100% top-15 Claude Code pluginů používá markdown | Q5d z Run 1, Q15 | quemsah/awesome-claude-plugins index; Anthropic Skills 32-page playbook 2026-01-29 |
| C3 | BMAD v6.1.0 zrušil YAML workflow engine, přešel na markdown | Q19 | github.com/bmad-code-org/BMAD-METHOD/releases — v6.1.0 (13 Mar 2026) |
| C4 | MS Workflows.Declarative stále prerelease i po 1.0 GA | Q18 | devblogs.microsoft.com/agent-framework/microsoft-agent-framework-version-1-0/ |
| C5 | superpowers nemá nativní per-project customization mechanismus | Q14 | github.com/obra/superpowers source; using-superpowers/SKILL.md priority hierarchy |
| C6 | Claude Code plugin subagenti nemohou použít `hooks`, `mcpServers`, `permissionMode` | Q15 | code.claude.com/docs/en/sub-agents (verifikováno 2026-04-26) |
| C7 | opencode: 4 built-in agents (build, plan, general, explore); agent.ts:117-250 | Q13 | packages/opencode/src/agent/agent.ts (deepwiki.com/sst/opencode/3.2-agent-system) |
| C8 | Devin "compound AI" = marketing; 4 tools, ne 4 agent instances | Q20 | cognition.ai/blog/introducing-devin (March 2024); "Planner+Coder+Critic+Browser" je community inference, ne Cognition-published |
| C9 | GH Copilot 4.7M paid subscribers, ne 10M+ | Q21 | Microsoft FY26 Q2 earnings (January 2026) |
| C10 | Cline 3.7M VSCode installs, ne 1M+ | Q22 | github.com/cline/cline marketplace page (verifikováno 2026-04-26) |
| C11 | Magentic-One: 38% GAIA overall (vs human baseline 92%±3.1%, dvě odlišné metriky) | Q18 | arxiv 2411.04468 (Fourney et al. 2024) |
| C12 | Claude Code system prompt baseline: 27k-31k tokenů (ne 6,973) | Q15 | GH issue #52979; buildtolaunch.substack.com; Simon Willison Apr 2026 |
| C13 | Goldman Sachs defect rate data nemá third-party verification | Q20 | Run 2 Q20 agent explicit: "no published public source for 1.5-2× defect rate" |
| C14 | Cognition "Devin Manages Devins" (2026-03) = partial reversal | Q20, CC1 z Run 1 | cognition.ai/blog/devin-can-now-manage-devins (March 19, 2026) |
| C15 | Anthropic Multi-Agent Research +90.2% = read/research tasks | Q20, CC1 z Run 1 | anthropic.com/engineering/multi-agent-research-system (June 2025) |
| C16 | Cursor: $2B ARR, $50B valuation (April 2026 Series E) | Q16 | datacamp.com/blog/cursor-3; VentureBeat April 2026 |
| C17 | BMAD star count 45.7k ověřeno (29.6k byl dočasný) | Q19 | GH Issue #1559 (dated Feb 2026); quemsah index konzistentní |
| C18 | BMAD: 3-tier TOML merge; 4 merge rules; NO removal mechanism | Q19 | docs.bmad-method.org/how-to/customize-bmad/ (verifikováno Run 2) |
| C19 | obra/superpowers = 168k★ (live WebFetch 2026-04-26); 121k★ = March 2026 peak reportované v April 2026 článku | Q14 | WebFetch 2026-04-26; pasqualepillitteri.it/en/news/215 (April 2026, reporting March 2026 number) |
| C20 | Kim et al. "per-agent reasoning thins past 3-4 under fixed compute" | Q2 z Run 1 | arxiv 2512.08296 (Kim et al., Dec 2025) |
| C21 | Cline Auto Approve = "most requested feature" po 5 měsících | Q22 | github.com/cline/cline release v3.0.0 (2024-12-18) notes |
| C22 | BMAD konsolidace: 19+ agentů v6 alpha → 6 agents v6.3.0 (April 2026) | Q19 | github.com/bmad-code-org/BMAD-METHOD/releases (v6.3.0, 2026-04-10) |
| C23 | OpenAI Codex Subagents: TOML inherit-with-override pattern | Q17 | developers.openai.com/codex/subagents |
| C24 | 5/5 Run 1 lenses: 0 production meta-gen deployments | Q3 z Run 1, Q8 | "No evidence found" inventory #3 v Run 1 final.md |
| C25 | Anthropic 2026 Agentic Coding Trends: "2026 = year multi-agent wins" | CC1 z Run 1 | resources.anthropic.com/2026-agentic-coding-trends-report |

---

## 6. Anomálie Status Update (z Run 1)

### Anomaly 1: opencode 149.7k★ paradigm shift — "TUI won 2026" over-claimed

**Run 2 status: VERIFIED AS REAL GROWTH, "TUI won" claim PARTIALLY WITHDRAWN.**

Q13 ověřuje: opencode ~150k★ k 2026-04-26, 6.5M monthly active developers, 14.5M npm downloads/March 2026. Velocity reálná (1,282 commits/30d). ALE: "TUI won 2026" thesis je overstated — primárním katalyzátorem 18k stars za 2 týdny v lednu 2026 byl Claude Max OAuth routing trick, nikoli TUI paradigm shift. Po Anthropic enforcement (2026-02-19 ToS update + 2026-04-04 plný ban) opencode odstranil OAuth kód. Dlouhodobý growth je reálný, ale virální peak byl driven kontroverzí, ne TUI adoption [Q13].

### Anomaly 2: Mastra 703 commits/30d, TypeScript overtook Python

**Run 2 status: NEDEEP-DIVEL, POTVRZENO Z RUN 1 DAT.**

Mastra skončila na #12 v Q12 shortlistu (weighted score 3.90), mimo Top 10 pro Run 2. TypeScript overtaking Python jako #1 GitHub language v August 2025 (Octoverse 2025) je potvrzeno Run 1 agent-4. Mastra 703 commits/30d = top velocity ze všech frameworků — run 1 finding zachován. Relevantní pro ceos-agents pokud expanduje mimo markdown-only, ale pro v8.0.0 agent shape decision je marginálně relevantní.

### Anomaly 3: superpowers stars discrepancy (165k vs 121k vs 168k)

**Run 2 status: VYŘEŠENO.**

Q14 empiricky verifikoval: obra/superpowers = 168k★ k 2026-04-26 (live WebFetch). 121k★ = peak measure March 2026 (pasqualepillitteri.it April 2026 report). 165k★ = quemsah index aggregace — hypotéza "marketplace aggregate" nepotvrzena (obra/superpowers-marketplace má 885★). Všechna čísla se vztahují na jeden repo, liší se datem měření. Konzistentní exponenciální růst. **Run 1 dezavuování "165k = marketplace aggregate" se ukazuje jako nesprávné — 168k je single-repo číslo** [Q14].

### Anomaly 4: MetaGPT 67.4k★ vs 2 adopting projects

**Run 2 status: NEDEEP-DIVEL, RUN 1 FINDING ZACHOVÁN.**

MetaGPT skončila mimo Top 10 (academic focus, stale commits). Wang et al. (arxiv 2512.01939) finding "67.4k★ vs 2 real-world adopters" zůstává jako nejdůležitější warning: GitHub stars ≠ adoption. Pro ceos-agents: komunita-ověřené adopters (named organizations) jsou důležitější metriku než star count [Q12 z Run 1].

### Anomaly 5: Roo Code shutdown (2026-04-21, 3M installs)

**Run 2 status: NEDEEP-DIVEL, POTVRZENO.**

Roo Code shutdown potvrzen v Run 1 data (2026-04-21, vyloučen z Q12 shortlistu explicitně). Pro ceos-agents: cautionary tale — silná adoption nezaručuje survival v rychle se měnícím ekosystému. Relevantní pro v8.0.0 sustainability rozhodnutí.

### Anomaly 6: AutoGen retired → MS Agent Framework

**Run 2 status: POTVRZENO v Q18.**

Q18 detailně popisuje: AutoGen vstoupil do maintenance mode 2025-10. MS Agent Framework 1.0 GA 2026-04-03 = enterprise successor. Dva official migration guides publikovány. AutoGen 57k★ vs MAF 9.8k★ ale MAF 193 commits/30d vs AutoGen ~1 commit/30d — commit velocity jako správný signal. **Potvrzeno [Q18].**

### Anomaly 7: MS Agent Framework declarative YAML tension

**Run 2 status: PARTIALLY RESOLVED.**

Q18 přesně identifikuje bifurkaci: (a) graph-based programmatic workflow engine = STABLE v 1.0 GA; (b) Workflows.Declarative YAML surface = stále `--prerelease` NuGet package i po 1.0 GA. Microsoft tedy current deployed a committed alternative surface, ale Workflows.Declarative není production-stable. Pro ceos-agents: YAML declarative pipeline by kopírovalo prerelease Microsoft feature, nikoli GA feature. Tension z Run 1 je PARTIALLY RESOLVED: enterprise YAML emerging, ale production-stable referenční implementace chybí [Q18].

### Anomaly 8: Anthropic 6,973 token prompt vs Goldilocks

**Run 2 status: VYŘEŠENO v Q15.**

Q15 empiricky verifikoval: 6,973 tokens z arxiv 2601.21233 je sémantická extrakce ze session interakce, nikoli přesné měření interního systémového promptu. Skutečný baseline Claude Code session = **27,000–31,000 tokenů** (systémový prompt ~2,500 + tool definitions 14–17k + konfigurace). Goldilocks "minimal-not-short" guidance popisuje záměr, ne tokenový limit — 6,973 i 27k+ jsou uvnitř definice "Goldilocks" protože zahrnují různé komponenty. **VYŘEŠENO [Q15].**

### Anomaly 9: Cognition vs Anthropic multi-agent

**Run 2 status: REFRAMOVÁNO v Q20.**

Q20 potvrzuje a zpřesňuje: Cognition "Don't Build Multi-Agents" (June 2025) bylo specificky o write tasks kde single-threaded context outperforms. "Devin Manages Devins" (2026-03) = Cognition sám zavedl orchestrator + managed workers pattern pro decomposable write subtasks. Toto je **komunikační artefakt, ne věcná kontradikce** — Cognition měnil framování (reject multi-agent → embrace orchestrated multi-agent pro decomposable tasks). Bifurkace (write-monolithic vs write-decomposable vs read) je produkčně potvrzena [Q20, CC1 z Run 1].

### Anomaly 10: Meta-gen no production

**Run 2 status: CONFIRMED, žádný z Q13-Q22 frameworks ships meta-gen v stable.**

Všech 10 Run 2 deep-dives: žádný framework neimplementuje meta-gen jako primární architekturu. Replit Agent 3 "generate other agents" = feature, nikoli architektura. MS Agent Framework = deterministic resolver, nikoli LLM-generated agents. Opencode generate() = beta/experimental feature pro generování agent definic z popisu, nikoli meta-gen pipeline. **5/5 Run 1 + 10/10 Run 2 = 0 production deployments meta-gen [Q13-Q22].**

---

## 7. Klíčové Opravy / Corrections of Run 1

### Oprava 1: Hook lifecycle — 31 events, ne 12 (Q15)

**Run 1 claim:** Hook lifecycle má 12 event typů (starší zdroje).
**Korekce:** Q15 verifikoval: Claude Code má nyní **31 distinktních event typů** — Async Hooks (Jan 2026) a HTTP Hooks (Feb 2026) přidaly novou vrstvu. Kritické pro v8.0.0 design: plugin hooks mohou využít celé event spektrum (ale plugin agenti stále nemohou `hooks` frontmatter pole — viz Oprava 2).

### Oprava 2: Plugin permission restriction — kritické constraint (Q15)

**Run 1 claim:** Agent Overrides mohou přidat hooks a permissions k plugin agentům.
**Korekce:** Q15 explicitně: **Plugin agenti NEPODPORUJÍ `hooks`, `mcpServers`, ani `permissionMode` frontmatter pole** — ignorovány z bezpečnostních důvodů. ceos-agents jako plugin tedy NEMŮŽE svým agentům přidávat hooks nebo přepínat permission mode přes agent frontmatter. Toto je zásadní constraint pro v8.0.0 design — všechny hooks musí být na plugin level, nikoli per-agent level.

### Oprava 3: Magentic-One 38% GAIA vs "92% dispatch rate" (Q15, Q18)

**Run 1 claim (v Q5c evidence):** "Magentic-One ~92% correct dispatch on benchmarks."
**Korekce:** Q18 objasňuje: Magentic-One **38% GAIA overall** (human baseline = vyšší). 92% se vztahuje na ledger-based dispatch accuracy v laboratorním experimentu pro paper reporting, ne na real-world GAIA task completion. Jsou to dvě odlišné metriky. Run 1 mohl chybně implikovat, že 92% je production dispatch success rate — to není správné [Q18].

### Oprava 4: Devin "compound architecture" (Q20)

**Run 1 claim:** Devin = "compound AI system: Planner+Coder+Critic+Browser (4 components)."
**Korekce:** Q20 verifikoval: tato dekompozice nemá primární source na cognition.ai. Je to **community inference** z Devin's tool set (planner UI + code editor + self-review feature v Devin 2.2 + browser), nikoliv Cognition-published architecture. Devin 2.2 "Review Autofix" = single-agent self-review, ne separate Critic agent. Treat original claim jako inference, ne verified compound architecture [Q20].

### Oprava 5: Goldman Sachs defect rate data (Q20)

**Run 1 claim:** "Devin defect rate 1.5-2× higher than senior dev; PR review cycles 1.5-2.3."
**Korekce:** Q20 verifikoval: tato specifická čísla **nejsou publikovaná v žádném veřejném zdroji** — Goldman ani Cognition tato specifika nezveřejnili. Produktivita 3-4× je Goldman CIO claim (July 2025), nikoli verifikované měření. Data pravděpodobně pochází z SitePoint-aggregated anecdotal reports. **Treat jako unverified [Q20].**

### Oprava 6: GH Copilot 10M+ paid seats → 4.7M (Q21)

**Run 1 claim:** "GitHub Copilot 10M+ paid seats."
**Korekce:** Q21 verifikoval: **4.7 milionů paid subscribers** k lednu 2026 (Microsoft FY26 Q2 earnings) — verifikovatelný zdroj. "10M+" číslo se nepodařilo verifikovat. Run 1 pravděpodobně kombinoval total GitHub Copilot users (free tier + paid) nebo citoval starší estimate. Správné číslo: 4.7M paid [Q21].

### Oprava 7: Cline 1M+ VSCode installs → 3.7M (Q22)

**Run 1 claim:** "Cline 1M+ VSCode installs" (z Q12 shortlist, Run 1).
**Korekce:** Q22 verifikoval: **3.7M VSCode installs** (GitHub marketplace page, verifikováno 2026-04-26). 1M+ bylo underestimate z dřívějšího data. Aktuální install base je 3.7× větší [Q22].

### Oprava 8: Anthropic 6,973-token Claude Code prompt = sémantická self-description, ne přesné měření (Q15)

**Run 1 claim:** "Claude Code production system prompt = 6,973 tokens" (citace arxiv 2601.21233) — toto číslo bylo využito jako empirický anchor pro Goldilocks zone debate (Q1, Anomaly 8).
**Korekce:** Q15 verifikoval: arxiv 2601.21233 metodologie je explicitně **"semantic descriptions, not verbatim text"** — Claude popsalo svůj prompt vlastními slovy v JustAsk-style interakci, nikoli token-precise extrakce. Reálný 2026-04 baseline Claude Code session = **27,000–31,000 tokenů** (core system prompt ~2,500 + tool definitions 14–17k + konfigurace), potvrzeno GH issue #52979 + Piebald-AI/claude-code-system-prompts (v2.1.120, 2026-04-24). Důsledek pro Anomaly 8: **rozpor s Goldilocks guidance neexistuje** — Anthropic guidance se vztahuje na system-prompt body (autorovaná instrukce), ne na tool definitions injection. ceos-agents 100–500-řádkové agent definitions jsou uvnitř Goldilocks zóny. **Vyřešeno [Q15].**

### Oprava 9: 5-tier vs 6-tier Claude Code subagent priority (Q15)

**Run 1 terminologie:** "Managed > CLI > Local > Project > User > Plugin" (6 úrovní).
**Korekce:** Q15 objasnil: správně je "Managed > CLI > Project > User > Plugin" — **5 úrovní**, ne 6. "Local" neexistuje jako separátní tier; `.claude/agents/` = project (tier 3). Zdroj: code.claude.com/docs/en/sub-agents [Q15].

### Oprava 10: superpowers Anomaly 3 dezavuování (Q14)

**Run 1 claim:** "165k★ = quemsah index aggregate; 121k★ je single-repo anchor."
**Korekce:** Q14 verifikoval: obra/superpowers = **168k★ k 2026-04-26** (live WebFetch). 168k > 165k, tedy 165k byl nižší estimate. obra/superpowers-marketplace = 885★ (ne relevantní k 165k). Hypotéza "marketplace aggregate" byla nesprávná — všechna čísla se vztahují na jeden repo, liší se datem [Q14].

---

## 8. Open Questions for A.1 Brainstorm

**OQ1: Konsolidace agentů — kolik je "správně" pro ceos-agents v8.0.0?**

Run 2 evidence: BMAD konsolidoval 19+ → 6 [Q19]; Kim et al. "thinning past 3-4" [Q2 z Run 1]; ale ceos-agents sequential pipeline (ne parallel critique) může defensibly mít více agentů. Konkrétní kandidáti konsolidace: (triage-analyst + code-analyst), (test-engineer + e2e-test-engineer), (reproducer + browser-verifier). Q-ref: [Q2 z Run 1, Q19]. Proč důležité: přímý dopad na token cost a maintenance burden.

**OQ2: TOML overlay pro Agent Overrides — adoption nebo risk?**

BMAD customize.toml je production-validated [Q19]. Codex Subagents TOML inherit-with-override je production-shipping [Q17]. Ale BMAD "no removal mechanism" je inherentní limit [Q19] a TOML přidává onboarding complexity. Je TOML-based overlay pro ceos-agents Agent Overrides v2 vhodný cíl pro v8.0.0, nebo je append-to-prompt-only dostatečné a méně risky? Q-ref: [Q17, Q19]. Proč důležité: architektonické rozhodnutí s dopady na customization power vs simplicity.

**OQ3: Plugin permission restriction — jak designovat hooks v v8.0.0? `(BLOCKING CONSTRAINT)`**

Plugin subagenti nemohou mít `hooks` frontmatter [Q15]. ceos-agents chce lifecycle automation (pre-fix, post-fix hooks). Jak implementovat per-agent hooks v rámci plugin constraints? Options: (a) skill-level hooks (ne agent-level), (b) orchestrating skill explicitně volá hooks bash commands, (c) plugin-level hooks definované v `.claude-plugin/` ale ne per-agent. Q-ref: [Q15]. Proč důležité: blocking constraint pro v8.0.0 design.

**OQ4: Strategické vs event-driven HITL gates pro ceos sub-projekt B?**

Q6 z Run 1 + Q18 (Magentic-One Stall Detection) + Q21 (Copilot strategic gates) ukazují vendor consensus na event-driven / strategic. ceos-agents má current "5 fixed gates" model. Pro sub-projekt B: přejít na event-driven gates ("pause when iteration >N," "pause when reviewer flag HIGH") nebo zachovat fixed stages? Q-ref: [Q6 z Run 1, Q18, Q21]. Proč důležité: přímé rozhodnutí sub-projektu B, sdílená evidence s Q6.

**OQ5: Jak měřit quality ceos-agents v8.0.0 architektonické změny?**

"No vendor benchmarks agent architecture shape directly" — SWE-bench měří scaffold + model dohromady [Q10 z Run 1]. Pro ceos-agents: Pass@K (run same ticket N times, measure variance), per-stage token cost, AC fulfillment rate, block rate jsou měřitelné. Jak nadesignovat v8.0.0 A/B test (v7.0.0 baseline vs v8.0.0 architecture)? Q-ref: [Q10 z Run 1, Q20]. Proč důležité: bez measurement je architektonické rozhodnutí bez feedback loop.

**OQ6: ceos-agents steps/*.md decomposition — token reduction vs complexity?**

BMAD steps/*.md pattern: 2,000–3,000 tokens/step vs 15,000 tokens monolithic = 80% reduction [Q19]. ceos-agents fix-bugs SKILL.md = ~600 řádků monolithic. Je steps/*.md decomposition v ceos skills vhodná pro v8.0.0, nebo je monolithic SKILL.md pro skills dostatečné a decomposition by přidala navigační overhead? Q-ref: [Q19]. Proč důležité: token cost je přímý uživatelský náklad.

**OQ7: Customization discovery jako onboarding blocker?**

BMAD GH issue #2003: "10-15× více času s BMAD než bez" — customization discovery failure. ceos-agents `Agent Overrides` je méně structured než BMAD customize.toml — ještě větší discovery risk. Jak designovat ceos-agents v8.0.0 onboarding tak, aby customization byla discoverable bez "design hole"? Q-ref: [Q19, Q5d z Run 1]. Proč důležité: public-release critical — první impression u nových uživatelů.

**OQ8: AGENTS.md interoperability — explicitně podpořit?**

AGENTS.md adoptováno >60k repos; Copilot, Cursor, Devin, Claude Code, Codex, opencode — vše čte AGENTS.md [Q21, Q13, Q15]. ceos-agents aktuálně čte CLAUDE.md `## Automation Config`. Má ceos-agents v8.0.0 explicitně podporovat AGENTS.md jako alternativu ke CLAUDE.md config, nebo zachovat CLAUDE.md-only? Q-ref: [Q5d z Run 1, Q21, Q13]. Proč důležité: interoperability s celým ekosystémem.

---

## 9. Lens Disclosure

### Primární závislosti

**Nejtěžší oporu** měla tato synthesis na:
- **Q19 (BMAD):** Nejrelevantnější peer framework pro ceos-agents v8.0.0. Historická evoluce v3→v6, `customize.toml` schema, steps/*.md decomposition pattern, scaling pain data jsou přímo přenositelné. BMAD je "closest peer" s production-validated evidence.
- **Q15 (Claude Code):** Hostitelská platforma pro ceos-agents. Plugin permission constraints (hooks/mcpServers/permissionMode restriction), 5-tier subagent priority, hook lifecycle (31 events) jsou architektonicky kritické pro v8.0.0.
- **Q20 (Devin):** Nejvíce korigoval Run 1 claims. Goldman defect data unverified, "compound AI" as inference, HITL zero-gate exemplar, "clean-slate dispatch" analogie k ceos-agents dispatch pattern.
- **Q22 (Cline):** Nejbohatší HITL evolution timeline. Per-step → granular auto-approve → YOLO. Přímý precedent pro sub-projekt B rozhodnutí.

### Evidence gaps

- **opencode (Q13):** Proprietary/closed parts runtime nedostupné. Architektonické detaily pouze z dokumentace a DeepWiki inference.
- **Cursor (Q16):** Closed-source IDE. "4× faster" claim metodologicky neverifikovatelný. Interní model routing neznámý.
- **GH Copilot (Q21):** Closed-source SaaS. Sub-agent architektura je UX-level popis, ne technical diagram. Model routing neznámý.
- **MS Agent Framework Workflows.Declarative (Q18):** Prerelease stav limituje evidence o production behavior. Málo community case studies k 2026-04.

### Řešení kontradikce mezi reporty

**BMAD star count (Q19 vs Run 1):** Q19 Run 2 verifikoval 45.7k★ přes GH Issue #1559 (Feb 2026). Run 1 citoval 29.6k jako "current GitHub" — zřejmě dočasná anomálie (repo refresh/cache issue). Run 2 evidence je preferred jako aktuálnější a s explicit source.

**superpowers star count (Q14 vs Run 1):** Q14 live WebFetch = 168k★ (2026-04-26). Adoption jako interpretace "jednoduchého" čísla: 121k★ (March 2026 peak), 168k★ (April 2026 live). Run 1 dezavuování "165k = aggregate" se ukazuje jako nesprávné. Q14 evidence je preferred.

**Cognition multi-agent (Q20 vs CC1 z Run 1):** Synthesis zachovává obě pozice — "Don't Build Multi-Agents" (June 2025) je valid pro write-monolithic tasks; "Devin Manages Devins" (March 2026) = partial reversal pro write-decomposable tasks. Kontradikce je task-type conditional, ne věcná.
