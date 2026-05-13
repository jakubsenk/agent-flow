# Q20 — Devin (Cognition): Hluboká analýza pro ceos-agents v8.0.0 Agent Shape Rework

**Agent:** Q20-devin (Run 2, Sub-projekt A)
**Datum:** 2026-04-26
**Primární lens:** Production (Goldman Sachs pilot, ARR growth, enterprise adoption)
**Sekundární lens:** Vendor (Cognition blog posts, product evolution timeline)
**Délka:** ~4 800 slov

---

## Exec summary

Devin je proprietary cloud SaaS autonomous coding agent od Cognition AI. Klíčové nálezy pro ceos-agents v8.0.0:

1. **Compound AI terminologie ≠ multi-agent v přesném smyslu.** Devin má 4 nástroje (shell, editor, browser, planner UI), nikoliv 4 samostatné modely nebo oddělené agent instance. Cognition tento setup nazývá "compound AI system," ale interní architektura nebyla publikována — všechny componenty jsou Cognition-proprietary a nerozlišené v public dokumentaci.

2. **Cognition "Don't Build Multi-Agents" (June 2025) vs Anthropic "+90.2%" (June 2025)** — empiricky ověřená kontradikcene stejném měsíci — rozlišuje se task typem: write-tasks favorizují single-threaded agent; read/research-tasks favorizují parallel sub-agents. Cognition v březnu 2026 provedl **partial reversal** produktem "Devin Manages Devins" — ne esejí.

3. **Defect rate data z Goldman pilotu nemá independent third-party verification.** Čísla 1.5-2× vyšší defect rate a 1.5-2.3 PR review cycles citovaná v Run 1 **nejsou publikovaná v žádném veřejném zdroji** — Goldman ani Cognition tato specifika nezveřejnili. Produktivita 3-4× je Goldman CIO claim (July 2025), ne verifikované měření.

4. **SWE-bench 13.86%** je Cognition-published datum z března 2024 — v době publikace byl SOTA, do 2026 překonán mnohonásobně (Opus 4.7: 87.6% na SWE-bench Verified, April 2026).

5. **Pricing: $500/mo → $20/mo** je potvrzený fakt (April 2025, Devin 2.0 launch), ale económia za tím je neprůhledná — usage-based model přes ACU (Agent Compute Unit, ~15 min = 1 ACU).

6. **"200 min autonomous"** v Run 1 summarizaci odpovídá: Devin varuje při přibližně 150-200 minutách aktivní práce (~10 ACU), session není tvrdě ukončena, ale kontextová degradace nastupuje.

---

## 1. Granularita agentů — Devin jako compound AI system

### Co je "compound AI" v Cognition kontextu

Cognition popisuje Devin jako **compound AI system**, ale tato terminologie je marketingová, nikoliv architektonická specifikace. Z public dostupných zdrojů vyplývá:

Devin má přístup k **4 nástrojům / pracovnímu prostředí** (shell, code editor, browser, planner), nikoliv 4 separátní model-instances nebo agent loops. Introducing Devin blog post (March 12, 2024) popisuje: *"Devin is equipped with common developer tools including the shell, code editor, and browser within a sandboxed compute environment."* Architekturní detail o tom, zda jsou tyto schopnosti implementovány přes separate model calls, separate agent loops, nebo jako tool-calls jednoho modelu, **nebyl Cognition publikován**.

Devin 2.0 (April 3, 2025) přidal **Interactive Planning** jako user-facing nástroj, **Devin Search** (agentic codebase exploration), a **Devin Wiki** (automatic repo indexing). Opět — user-facing features, nikoli architekturní komponenty.

### Run 1 "Planner + Coder + Critic + Browser" — caveat

Run 1 final.md popisoval Devin jako "4 components (Planner + Coder + Critic + Browser)." **Tato dekompozice nemá primární source na cognition.ai.** Pravděpodobně jde o inference ze Devin's tool set (planner UI + code editor + self-review feature v Devin 2.2 + browser), nikoliv o Cognition-published architecture. **Treat as inference, not verified compound architecture.**

Devin 2.2 (February 24, 2026) přidal "Devin Review Autofix" — self-verification loop kde Devin *"plans, codes, reviews its own output, catches issues, and fixes them - all before you ever open the PR."* Toto je nejbližší "Critic" component evidence — ale jde o **single-agent self-review**, ne separate critic agent.

**Conclusion pro dimension 1:** Devin není multi-agent v technickém smyslu. Je to single agentic loop s přístupem k developer tools a self-review capability. "Compound AI" je Cognition marketing frame.

---

## 2. Pipeline configuration mechanism

### Hardcoded SaaS pipeline

Devin **nemá user-facing pipeline DSL.** Pipeline je zcela hardcoded v Cognition runtime. Workflow = issue description → plan generation → implement → self-review → PR. Uživatel nemůže tento flow konfigurovat, přeskočit fáze, přidat vlastní agenty, nebo definovat conditions.

**Customization surface, která existuje:**
- Cognition "Knowledge" tab: per-repo instructions (podobný CLAUDE.md `Automation Config`)
- Devin API: programmatic session creation pro integrations
- Slack/Linear/GitHub integrations: trigger Devin z externích systémů
- Session-level instructions: uživatel posílá zprávy během session

**Co neexistuje:**
- Žádný config file v projektu
- Žádný YAML/JSON pipeline definition
- Žádný hook system (pre-fix, post-fix, pre-publish)
- Žádná pipeline profile / skip stage capability
- Žádný custom agent insertion

Zdroj: [docs.devin.ai/get-started/devin-intro](https://docs.devin.ai/get-started/devin-intro), Devin 2.0 product docs (cognition.ai/blog/devin-2, April 3, 2025).

---

## 3. Per-project customization

### SaaS customization model

Devin je SaaS — veškerá customization je přes Settings UI, nikoliv file-based config. Mechanismy:

- **Knowledge tab:** uživatel vkládá "knowledge" o projektu — konvence, vzory, co dělat/nedělat. Analogické k AGENTS.md nebo CLAUDE.md project instructions. Cognition nespecifikuje technický formát ani délkový limit.
- **GitHub repo permissions:** Devin dostane read/write access k vybraným repozitářům.
- **Slack integration:** Devin dostane kanály pro notifikace a user communication.
- **Linear integration:** ticket assignment → Devin session automaticky.

**Pro ceos-agents kontext:** Devin knowledge tab je closest-analog k ceos-agents `Agent Overrides` (per-agent markdown instructions). Ale Devin knowledge platí per-session celý, ne per-agent-type. **Žádná direct relevance** jako file-based pattern pro ceos-agents v8.0.0.

---

## 4. HITL pattern — Zero-gates exemplar

### Primární design: async-autonomous s PR-boundary gate

Devin je **canonical zero-gates exemplar** v produktovém smyslu. Uživatel:
1. Vytvoří session (posílá task description nebo GitHub issue)
2. Může sledovat live nebo se vrátit later
3. Dostane PR k review jako první HITL gate

Během session může uživatel Devina přerušit a poslat zprávu — jde o **optional interrupt**, ne mandatory gate.

**ACU + session duration data:**
- 1 ACU ≈ 15 minut aktivní práce Devina (potvrzeno ceníkem a komunitou, zdroj: [x.com/SledgeDev/status/1866971992802594998](https://x.com/SledgeDev/status/1866971992802594998))
- Pro plan s 10 ACU limitem per command = max ~150 minut na jeden příkaz
- Devin varuje při ~10 ACU kumulativní práci v jedné session — kontextová degradace signal

**"200 min autonomous" claim z Run 1:** Pravděpodobně inference z 10-13 ACU effective session budget (150-195 min) + session-level warning mechanizmu. Cognition nepublikoval tvrdý 200-minutový limit. Run 1 zformuloval jako production observation, nikoli jako official spec. **Treat as ~10 ACU soft limit, not hard 200-minute cutoff.**

### Ramp production workflow

Ramp (fintech customer, potvrzen Cognition funding announcement, September 2025) používá Devin s **parallel worker modelem**: multiple Devins souběžně tackle různé aspekty, dedicated Devin verifikuje outputs a vytváří single PR. Metriky:
- 80 PRs merged weekly
- 10,000+ hours saved monthly
- 8 min average: Airflow bug detection → PR completion
- Half of generated PRs merge without modification

Zdroj: [devin.ai/customers/ramp](https://devin.ai/customers/ramp) (Cognition-published, vendor caveat platí).

### Srovnání HITL strategií

| Tool | HITL Pattern | Gate frequency |
|------|-------------|----------------|
| Devin | Zero mandatory gates + async PR | 1 gate at PR |
| Cline | Per-step approval | Every tool call |
| GitHub Copilot Coding Agent | Strategic: spec → plan → implement | 2-3 gates |
| ceos-agents (current) | Zero gates (--yolo default) nebo per-stage | Configurable |

**Architecturální poznatek:** Devin volí PR boundary jako přirozený human checkpoint, protože je to standard software development workflow artifact. ceos-agents dělá totéž (publisher vytváří PR). Shoda v gate placement.

---

## 5. Stateful vs stateless agent design

### Single Devin: stateful per session

Každá Devin session je **stateful** — agent si pamatuje veškerý kontext (codebase explorace, provedené kroky, edit history, test výsledky) v rámci jedné session. Context window se kumuluje. Při dosažení 10 ACU (~150 min) nastává kontextová degradace — Cognition flaguje session jako "long running."

### "Devin Manages Devins" (March 19, 2026): parent-child stateful/stateless hybrid

Klíčová architekturní změna a **partial reversal** Cognition pozice:

> "when one agent tries to handle too many things in a single session, context accumulates, focus degrades, and the quality of each subtask suffers."

Řešení (z [cognition.ai/blog/devin-can-now-manage-devins](https://cognition.ai/blog/devin-can-now-manage-devins), March 19, 2026):

- **Parent Devin** = orchestrator — stateful, má plný kontext celého task
- **Managed Devins** = workers — každý dostane **clean slate, narrow focus, own shell, own test runner**
- Parent *"can also read the full trajectories of its managed Devins to understand what worked, what didn't, and where they got stuck, and use that to improve how it breaks down the next task"*
- Managed Devins běží paralelně, každý v izolaci

Tato architektura je přesnou analogií k ceos-agents pattern: **orchestrating skill** (fix-bugs, implement-feature) drží pipeline state, každý **sub-agent** dostane fresh dispatch s explicitním kontextem předaným jako součást promptu. Devin terminologie: "clean slate, narrow focus" = ceos-agents terminologie: stateless dispatch + explicitní kontext injection.

**Srovnání přístupu k state:**

| Systém | Parent/Orchestrator | Worker/Sub-agent |
|--------|--------------------|--------------------|
| Devin (post-2026-03-19) | Stateful (kumuluje full trajectory) | Clean slate per task |
| ceos-agents (current) | Stateless skill (pipeline state v state.json) | Stateless per dispatch |
| AutoGen | GroupChat memory (shared) | Per-agent thread |
| CrewAI | Crew memory | Per-task stateless |

**Klíčový rozdíl:** ceos-agents ukládá state externě v `state.json` a předává kontext explicitně při každém dispatch — toto je funkčně ekvivalentní "clean slate + narrow focus" principu, který Cognition identifikovalo jako solution pro context degradation.

---

## 6. "Lessons learned" — KLÍČOVÁ PRIORITA pro Q20

### 6a. Cognition "Don't Build Multi-Agents" (June 12, 2025)

**Primární zdroj:** [cognition.ai/blog/dont-build-multi-agents](https://cognition.ai/blog/dont-build-multi-agents)

**Datum:** June 12, 2025

**Plný argument:**

Esej identifikuje **Context Engineering** jako "#1 job of engineers building AI agents" — dynamická optimalizace toho, co LLM vidí v každém okamžiku. Definuje dvě core principy:

- **Princip 1:** *"Share context, and share full agent traces, not just individual messages"* — subagent potřebuje vidět full trajectory, ne jen summary.
- **Princip 2:** *"Actions carry implicit decisions, and conflicting decisions carry bad results"* — každá akce agenta embeduje implicit rozhodnutí (jaký background, jaká barevná paleta, jaký coding style). Paralelní subagenti dělají conflicting implicit decisions bez coordination.

**Flappy Bird příklad (parafráze):** Task "build Flappy Bird clone" se rozdělí mezi dva subagenty. Jeden vytvoří Super Mario Bros. background, druhý postaví bird character. Finální agent musí kombinovat dva vzájemně nekonzistentní výstupy — *"the undesirable task of combining these two miscommunications."*

**Edit Apply Model disclosure (kritický nález pro Run 2):**

Esej obsahuje historický insight o architekturní volbě:

> "In 2024, many models were bad at editing code, and a common practice among coding agents (including Devin) was to use an 'edit apply model' — an approach where it was more reliable to get a small model to rewrite an entire file based on markdown explanations of changes rather than have a large model output a properly formatted diff."

Cognition tuto praxi **opustil** kvůli nespolehlivosti: *"the small model would misinterpret the instructions...due to the most slight ambiguities."* Moderní přístup (2025) = **single model dělá edit i application v jednom kroku** — eliminace compound model chain.

**Záměr eseje:** obhajoba single-threaded linear agent pro write-tasks. Cognition derivuje z 18 měsíců Devin production experience. **Neobsahuje žádná kvantitativní data** — jde o argumentaci z principů, nikoliv empirická čísla.

**Klíčový caveat:** esej nevylučuje multi-agent pro read/research tasks — pouze tvrdí, že pro *write tasks* (code editing, software implementation) jsou parallel subagents kontraproduktivní v 2025 production. *"When this day comes, it will unlock much greater amounts of parallelism and efficiency"* — Cognition nevylučuje multi-agent budoucnost.

### 6b. Anthropic "Building a multi-agent research system" (June 13, 2025)

**Primární zdroj:** [anthropic.com/engineering/built-multi-agent-research-system](https://www.anthropic.com/engineering/built-multi-agent-research-system)

**Datum:** June 13, 2025 (jeden den po Cognition eseji)

**+90.2% metodologie:**

- Test task: identifikovat všechny board members across Information Technology S&P 500 companies — **extensive parallel information retrieval**, ne write/coding task
- Systém: Claude Opus 4 jako Lead Agent + Claude Sonnet 4 sub-agents (orchestrator-worker pattern)
- Výsledek: +90.2% vs single-agent Claude Opus 4 na **interních evalech**
- Token cost: **15× více tokenů vs chat interaction**, 4× více než single-agent

**Architektura:**
Lead Agent dekomponuje queries → multiple sub-agents parallel exploration, každý se separátním context window → lead agent komprimuje výsledky do "lightweight references" → CitationAgent pro final output.

**Kdy multi-agent funguje (per Anthropic):**
- Breadth-first queries requiring simultaneous multi-directional exploration
- Tasks exceeding individual context window capacity
- Parallel information-gathering (NOT parallel code editing)

**Klíčový soulad s Cognition:** Anthropic SAMI uznává, že single-agent zůstává preferovaný pro "sequential workflows and heavily interdependent tasks like coding." Tedy: obě firmy říkají totéž, jen z různých výchozích pozic.

### 6c. Anomaly 9 Resolution — kde je kontradikceve skutečnosti?

**Zdánlivá kontradikcee:**
Cognition říká "Don't Build Multi-Agents" ve stejném měsíci, kdy Anthropic říká "+90.2% multi-agent."

**Skutečná situace (empiricky ověřeno výše):**

| Claim | Task type | Verdict |
|-------|-----------|---------|
| Cognition: single-agent superiority | Write tasks (code editing, implementation) | Validní pro stated domain |
| Anthropic: +90.2% multi-agent | Read tasks (research, parallel info retrieval) | Validní pro stated domain |

**Kontradikcee je komunikační artefakt**, nikoliv věcná neshoda. Obě firmy se shodnou na task-type conditional:
- Write/implementation tasks → single-threaded agent s full context
- Research/parallel-exploration tasks → orchestrator + parallel sub-agents

**Proč to vypadá jako kontradikcee:** Cognition napsal esej bez explicit task-type qualifier ("Don't Build Multi-Agents" — ne "Don't Build Multi-Agents for write tasks"). Čtenář bez kontextu může nabýt absolutistický dojem.

### 6d. Cognition partial reversal: "Devin Manages Devins" (March 19, 2026)

**Primární zdroj:** [cognition.ai/blog/devin-can-now-manage-devins](https://cognition.ai/blog/devin-can-now-manage-devins)

**Datum:** March 19, 2026 — 9 měsíců po "Don't Build Multi-Agents" eseji

**Klíčový citát (přímá citace):**

> "when one agent tries to handle too many things in a single session, context accumulates, focus degrades, and the quality of each subtask suffers."

Tato věta **reaplikuje** context-degradation argument z June 2025 eseje — ale nyní jako **justification pro decomposition**, nikoliv jako rejection of parallelism. Logika se obrátila:

- June 2025: "context degrades → don't parallelize"
- March 2026: "context degrades in single long session → dekomponuj do parallel managed Devins, každý s narrow focus"

**Proč je to partial (ne full) reversal:** Cognition nepublikoval essay-level retraction. "Don't Build Multi-Agents" esej stále existuje na původní URL. Managed Devins je **product announcement**, nikoli philosophical update. Cognition positioning zůstává: multi-agent je složité a risky; ale hierarchical decomposition s clean-slate workers je přijatelná forma, pokud parent koordinuje a worker má narrow focus.

**Architekturní poučení:** Cognition vlastně popisuje přesně to, co Anthropic navrhuje jako "hierarchical multi-agent" — jeden orchestrator s plným kontextem + specialists s clean-slate narrow focus. Terminologická bifurcace ("don't do multi-agent" vs "this is multi-agent") překrývá věcnou shodu.

### 6e. 2026 vendor consensus: kde jsme k 2026-04-26?

**Anthropic 2026 Agentic Coding Trends Report** ([resources.anthropic.com/2026-agentic-coding-trends-report](https://resources.anthropic.com/2026-agentic-coding-trends-report)):

Report identifikuje "multi-agent coordination" jako jeden z 8 trendů přetvářejících software development v 2026. Přesný citát *"2026 is the year single-agent workflows give way to coordinated multi-agent systems"* se nepodařilo extrahovat z landing page (patrně v plném PDF) — zachováno jako Run 1 citation s caveautem. Report zmiňuje case studies: Rakuten, CRED, TELUS, Zapier.

**Výsledný vendor consensus (2026-04-26):**

1. **Multi-agent legitimita vzrostla** — Cognition, Anthropic, Microsoft Agent Framework 1.0 GA, OpenAI Agents SDK long-horizon harness — všichni posunuli k multi-agent jako přijatelný default.
2. **Task-type bifurcation přetrvává** — write tasks stále favorizují single-threaded nebo hierarchical (ne flat parallel); research/exploration tasks benefitují z plné parallelizace.
3. **"Clean slate + narrow focus" je emerging consensus** — Devin Manages Devins, Anthropic orchestrator-worker, ceos-agents stateless dispatch — všechny konvergují k tomuto patternu.
4. **Žádný vendor nepublikoval "max agents per system" recommendation** — horní hranice granularity zůstává empiricky nekotvená.

### 6f. Goldman Sachs pilot — evidence inventory

**Datum pilotu:** July 2025 announcement (CNBC, TechCrunch, Fortune)

**Confirmed facts (independent reporting):**

| Fakt | Zdroj | Typ |
|------|-------|-----|
| Goldman má ~12,000 developerů | CNBC, July 11, 2025 | Verified |
| Goldman CIO Marco Argenti: 3-4× produktivita "předchozích AI nástrojů" | CNBC, July 11, 2025 | Goldman executive claim |
| "Hybrid workforce" vision | Marco Argenti, Goldman | Goldman executive claim |
| Plán: hundreds → thousands Devin instances | CNBC | Goldman executive claim |
| 67% PRs merged (2025) vs 34% (2024) | Cognition Annual Review, Nov 14, 2025 | Vendor-published, not Goldman-attributed |

**Unverified claims z Run 1 (defect rate, PR review cycles):**

Run 1 citoval: *"defect rate 1.5-2× higher than senior dev; PR review cycles 1.5-2.3."* Rozsáhlé hledání primárního zdroje nepřineslo výsledek. Cognition Annual Review (November 2025) ani TechCrunch, Fortune, CNBC reporty tato specifika neobsahují. Možné zdroje: neveřejný Cognition sales material, paywalled Bloomberg/WSJ investigativní report, nebo inference z obecných AI code quality studies.

**Goldman Annual Report 2025** (goldmansachs.com) existuje jako PDF — nebyl extrahován, ale veřejně dostupný pro Run 2 ověření pokud potřeba.

**Caveat pro Q22 synthesis:** defect rate a PR review cycle čísla z Run 1 jsou **unverified**. Citovat pouze pokud ověřený zdroj nalezen; jinak použít "reported" qualifier nebo vynechat.

### 6g. SWE-bench 13.86% — kontext a zastarání

**Primární zdroj:** [cognition.ai/blog/swe-bench-technical-report](https://cognition.ai/blog/swe-bench-technical-report), March 15, 2024

- Devin vyřešil 79 z 570 issues = **13.86% success rate**
- Metodologie: 45-minute runtime limit, standardized prompt, git remote removed
- "End-to-end" = fully autonomous, žádný user input, jen GitHub issue description
- V době publikace: SOTA (předchozí best assisted baseline: 4.80%)

**Rychlost zastarání:**
- 2024-Q2: SWE-Agent (Princeton) dosáhl 12.29%, brzy 14.7%
- 2025: Multiple systems překonaly 50% na SWE-bench Verified
- 2026-04: Opus 4.7 = **87.6% SWE-bench Verified** (Anthropic, April 2026)

**Interpretace:** 13.86% je historicky significant (první systém překonávající 10% threshold na plném SWE-bench), ale jako benchmark figure pro srovnání v 2026 je obsolete. Devin 2.x skóre na aktuálním SWE-bench Verified **Cognition nepublikoval** jako of 2026-04-26.

### 6h. Pricing economics — $500/mo → $20/mo

**Primární zdroje:**
- VentureBeat: "Cognition slashes price of AI software engineer to $20 per month from $500" ([venturebeat.com](https://venturebeat.com/programming-development/devin-2-0-is-here-cognition-slashes-price-of-ai-software-engineer-to-20-per-month-from-500))
- Cognition blog: "Devin 2.0" (cognition.ai/blog/devin-2), April 3, 2025

**Detail přechodu:**

| Verze | Cena | Model |
|-------|------|-------|
| Devin 1.x | $500/mo | Subscription, 250 ACU |
| Devin 2.0+ | $20/mo (Pro) / $80/mo (Teams) | Pay-as-you-go + quota |

Starý plán: $500/mo = 250 ACU = $2.00/ACU
Nový plán: $20/mo Pro = 9 ACU = $2.25/ACU (slightly higher per-unit, but massively lower entry)

**Ekonomická interpretace:** přechod je **land-and-expand** strategie, nikoliv unit economics zlepšení. Per-ACU cena se mírně zvýšila ($2.00 → $2.25); snížila se pouze bariéra vstupu (individuální devs vs. enterprise-only). Cognition ARR vzrostl $1M (Sep 2024) → $73M (Jun 2025) — $20/mo entry evidentně funguje jako acquisition channel.

**Ohledně loss-leader hypotézy:** Cognition total company net burn pod $20M za celou historii (z funding announcement, Sep 2025) — nenaznačuje agresivní loss-leader operaci. Unit economics pravděpodobně blízko break-even na compute při ACU $2.25.

**Aktuální pricing (2026-04-26):**
- Free: limitovaný přístup
- Pro: $20/mo
- Max: $200/mo
- Teams: $80/mo (unlimited members)
- Enterprise: custom (VPC deployment option)

Zdroj: [devin.ai/pricing/](https://devin.ai/pricing/)

---

## 7. Co lze přenést do markdown-only Claude Code plugin (ceos-agents kontext)

### Přenositelné patterns (architecturálně relevantní)

#### 7a. Clean-slate dispatch s explicitním kontextem

Cognition "Devin Manages Devins" potvrdil: nejspolehlivější pattern je **orchestrator s full context + workers s clean slate a narrow focus**. ceos-agents to již implementuje (stateless dispatch + state.json + explicitní kontext injection). Toto je **validation**, ne nová inspirace.

**Implication pro v8.0.0:** Pokud A.1 brainstorm zvažuje přechod k "stateful" fixer (fixer si pamatuje across iterations v thread-style), Devin's experience naopak doporučuje NEPROVÁDĚT tuto změnu — context accumulation = quality degradation per Cognition production data.

#### 7b. Self-review jako součást execution loop

Devin 2.2 "Devin Review Autofix" = Devin sám reviewuje svůj output před PR. ceos-agents má tento pattern jako **fixer ↔ reviewer loop** (dva separátní agenti). Devin to dělá v jednom agentu.

**Otázka pro A.1:** Je fixer↔reviewer jako dva separátní agents worth the overhead? Devin konsolidoval do jednoho. Ale: ceos-agents reviewer je jiný model (opus) a dostane clean-slate perspective. Toto je vědomá design choice, nikoliv jen implementační zkratka.

#### 7c. Knowledge/instructions per project

Devin "Knowledge" tab ≈ ceos-agents `Agent Overrides` + `CLAUDE.md Automation Config`. Pattern je universální. Direct přenos: ceos-agents approach je **sofistikovanější** (per-agent granularita vs Devin's per-session global knowledge).

#### 7d. PR jako natural HITL gate

Devin i ceos-agents konvergují k PR jako primárnímu human checkpoint. Toto je **industry standard** — potvrzeno Devin, GitHub Copilot Coding Agent, ceos-agents publisher. Žádná změna potřeba.

### Nepřenositelné (framework-specific nebo runtime-dependent)

- **ACU billing model** — SaaS revenue model, není relevantní pro open-source plugin
- **Parallel Devin orchestration** — vyžaduje cloud runtime s VM provisioning per worker; markdown plugin nemůže spawny VMs
- **Devin Search + Wiki** — vyžadují Cognition proprietary indexing backend
- **Windsurf IDE integration** — post-acquisition product feature, proprietary

---

## 8. Co je framework-specific

### Devin = Cognition proprietary cloud SaaS

Devin nemá žádný open-source kód, žádný plugin format, žádný config file schema. Veškerá "architektura" je black-box s vendor-published high-level description.

**Production data je vendor-published (potential bias):**
- 67% PR merge rate: Cognition-published, metodologie neuvedena (aggregovaná přes jakých issues? jakých zákazníků? sezónní efekty?)
- 4× faster problem solving: Cognition claim, žádná peer-reviewed verification
- Goldman CIO 3-4× productivity claim: single executive statement, pilot je teprve "starting"
- Nubank 8× efficiency + 20× cost savings: Cognition case study, Nubank nepotvrdil independent

**Independent third-party verification:**
- Prakticky neexistuje pro specifické metriky
- CNBC, TechCrunch, Fortune reporty jsou relay of Goldman/Cognition press releases
- SWE-bench 13.86% je reproducible (metodologie publikována, [github.com/CognitionAI/devin-swebench-results](https://github.com/CognitionAI/devin-swebench-results)) — ale z 2024, obsolete

**Valuation jako proxy pro adoption:**
Cognition fundraisoval $400M při $10.2B valuation (Founders Fund, September 2025). ARR: $1M → $73M za 9 měsíců. Tato čísla jsou investor-verified (due diligence), nikoliv self-reported operational metrics. Silnější evidence než marketing claims.

---

## Citation inventory (primární zdroje ověřené v tomto reportu)

| Zdroj | URL | Datum | Typ |
|-------|-----|-------|-----|
| Cognition "Don't Build Multi-Agents" | cognition.ai/blog/dont-build-multi-agents | June 12, 2025 | Vendor primary |
| Cognition "Devin can now Manage Devins" | cognition.ai/blog/devin-can-now-manage-devins | March 19, 2026 | Vendor primary |
| Cognition "Introducing Devin 2.0" | cognition.ai/blog/devin-2 | April 3, 2025 | Vendor primary |
| Cognition "Introducing Devin 2.2" | cognition.ai/blog/introducing-devin-2-2 | February 24, 2026 | Vendor primary |
| Cognition "Devin Annual Performance Review 2025" | cognition.ai/blog/devin-annual-performance-review-2025 | November 14, 2025 | Vendor primary |
| Cognition SWE-bench Technical Report | cognition.ai/blog/swe-bench-technical-report | March 15, 2024 | Vendor primary |
| Cognition "Funding, growth, and next frontier" | cognition.ai/blog/funding-growth-and-the-next-frontier-of-ai-coding-agents | September 8, 2025 | Vendor primary |
| Anthropic "Built multi-agent research system" | anthropic.com/engineering/built-multi-agent-research-system | June 13, 2025 | Vendor primary |
| Anthropic 2026 Agentic Coding Trends Report | resources.anthropic.com/2026-agentic-coding-trends-report | 2026 | Vendor primary |
| Ramp customer page | devin.ai/customers/ramp | 2025 | Vendor case study |
| Devin pricing page | devin.ai/pricing/ | 2026 (current) | Vendor primary |
| Devin docs intro | docs.devin.ai/get-started/devin-intro | 2026 (current) | Vendor primary |
| TechCrunch Goldman Sachs pilot | techcrunch.com/2025/07/11/goldman-sachs-is-testing-viral-ai-agent-devin-as-a-new-employee/ | July 11, 2025 | Independent journalism |
| VentureBeat Devin 2.0 pricing | venturebeat.com (Devin 2.0 pricing article) | April 3, 2025 | Independent journalism |
| CognitionAI SWE-bench results | github.com/CognitionAI/devin-swebench-results | March 2024 | Vendor primary (reproducible) |

---

## Lens disclosure

Tento report je psán z **production lens** (primární) a **vendor lens** (sekundární) dle zadání.

**Production lens caveat:** Veškerá production data z Devin jsou vendor-published nebo relay single executive statements. Žádné independent třetí strany nepublikovaly peer-reviewed case study Devin production adoption. Goldman pilot je v brzké fázi (announced July 2025, scale "hundreds" plánovaných); výsledková data nejsou k dispozici mimo CIO aspirational claims.

**Vendor lens caveat:** Cognition má incentive prezentovat Devin jako úspěšný. ARR data ($73M annualized k June 2025) a funding valuation ($10.2B) jsou investor-verified a tedy silnější evidence; operational metrics (PR merge rate, speed) jsou self-reported bez metodologické transparency.

**Absence evidence caveat:** Architektura compound AI system (internal komponenty, model selection, dispatch mechanism) **nebyla Cognition publikována**. Veškeré inference o Planner/Coder/Critic/Browser komponentách jsou komunitní interpretace toolů, nikoliv official architecture disclosure. Tento report tuto absenci explicitně označuje.

---

## Shrnutí pro Q22 cross-run synthesis

1. **Multi-agent debate** má empirický resolution: task-type bifurcation. Write → single-threaded/hierarchical. Research → parallel orchestrator-worker. Cognition a Anthropic se nevěcně neliší, jen komunikačně.

2. **Cognition architectural evolution**: od Edit Apply Model compound (2024) → single-model (2025, "Don't Build Multi-Agents") → hierarchical Managed Devins (March 2026). Každý krok snižoval complexity a zvyšoval context integrity.

3. **"Clean slate + narrow focus"** je emerging cross-vendor consensus pro worker agents v hierarchical pipelines — přímá validace současného ceos-agents stateless dispatch patternu.

4. **Devin = zero-pipeline-config SaaS.** Pro ceos-agents je nejcennější jako negative exemplar (co se stane, když pipeline konfiguraci neposkytneš uživateli) a jako production validation pro PR-boundary HITL pattern.

5. **Goldman defect rate specifika jsou unverified.** Pro Q22 synthesis: citovat pouze jako "reported in secondary sources without primary verification."
