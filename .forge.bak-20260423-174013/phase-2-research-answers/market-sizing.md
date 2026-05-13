# Market Sizing Worksheet — ceos-agents Revenue Streams

**Author:** Phase 2 Research Agent B (Mira Halen)
**Date:** 2026-04-23
**Scope:** TAM / SAM / SOM for 6 candidate revenue streams + 3-year and 5-year projections

All figures in USD. Confidence bands: **Base / Upside / Downside**.
Every input is either sourced (citation number) or flagged `[ASSUMPTION]`.

---

## Methodology

**TAM formula used throughout:**
`TAM = (Total addressable buyers) × (% willing to pay for this category) × (ARPU/year)`

**SAM** = TAM filtered to ceos-agents' realistic geographic + technical + size reach  
**SOM** = SAM × capture rate in Year N

**Data anchor dates:** All market data from Q1–Q2 2026 unless flagged as older.

---

## Stream 1 — Hosted Autopilot SaaS

*Customers run ceos-agents bug-fix/feature pipelines on a managed hosted service. They pay per seat, per team, or per pipeline run.*

### Inputs

| Input | Value | Source / Assumption |
|---|---|---|
| Global professional software developers | 28–35 million [A] | Stack Overflow / GitHub 180M total, est. 15–20% professional/paid-role |
| Developers using Claude Code (weekly active) | ~1.6 million [1] | Anthropic-reported (see answers-partB Q-B1) |
| Paying Claude Code seats (estimate) | 500K–1.5M [ASSUMPTION] | Derived: $2.5B ARR run-rate / blended $600–$1,200 ARPU |
| Orgs with tracker + Claude Code (SAM filter) | 15,000–60,000 [ASSUMPTION] | See answers-partB Q-B3 |
| Avg developer seats per qualifying org | 25–75 [ASSUMPTION] | Mid-market assumption: 40 devs/org at midpoint |
| Autopilot willingness-to-pay | 30–60% of qualifying orgs [ASSUMPTION] | Teams already running automated pipelines would pay for managed version |
| ARPU (hosted autopilot tier) | $360–$1,200/seat/year [ASSUMPTION] | Devin $20–$80/mo reference, Copilot Enterprise $468/yr reference |

### TAM

`TAM = 1.6M Claude Code WAU × 20% (paying, Claude Code-sufficient) × 40% addressable for autopilot × $600/seat/year`  
`TAM = 1.6M × 0.20 × 0.40 × $600 = ~$77M`

**Note:** This is a conservative "Claude Code ecosystem only" TAM. Expanding to any Claude Code IDE/terminal user:  
`TAM (expanded) = 28M professional devs × 5% using Claude Code class tool × 30% autopilot WTP × $600/yr = $252M`

**TAM range:** $77M – $252M (ecosystem-locked vs. category-wide)

### SAM

`SAM = 30,000 qualifying orgs × 40 seats avg × 50% WTP × $600/seat/year`  
`SAM = 30,000 × 40 × 0.50 × $600 = $360M`

**SAM range: $135M – $720M** (see Q-B3 calculation in answers-partB)

### SOM (Year 1 / Year 3 / Year 5)

| Scenario | Y1 SOM | Y3 SOM | Y5 SOM |
|---|---|---|---|
| Downside (0.1% org capture, $360 ARPU, 25 seats) | $135K | $540K | $1.4M |
| Base (0.5% org capture, $600 ARPU, 40 seats) | $3.6M | $18M | $54M |
| Upside (2% org capture, $1,200 ARPU, 75 seats) | $54M | $216M | $432M |

**Base assumptions for projection:**
- Y1: 150 orgs × 40 seats × $600/yr = $3.6M ARR
- Y2–Y3: 3× org growth per year (PLG expansion)
- Y4–Y5: 2× growth (market maturation)

**Key uncertainty:** ARPU is the highest-leverage variable. Moving from $600 to $1,200/seat/year doubles every SOM figure. Devin's ACU model suggests that per-pipeline-run pricing could yield $1,200–$2,400/seat/year for active users — but adoption drops at higher price points.

---

## Stream 2 — Marketplace Take-Rate (Skills / Prompts / Agents)

*ceos-agents operates a skills/agents/prompt marketplace where third-party creators sell to Claude Code users. ceos-agents earns a % take-rate on transactions.*

### Inputs

| Input | Value | Source / Assumption |
|---|---|---|
| Claude Code paying seats (marketplace-eligible) | 500K–1.5M [ASSUMPTION] | See Stream 1 |
| % buyers willing to purchase marketplace items | 5–15% [ASSUMPTION] | Chrome Web Store benchmark: ~10% of installed-base purchases |
| Average marketplace spend per buyer/year | $50–$200 [ASSUMPTION] | JetBrains Marketplace plugins: $19–$99/plugin typical; 1–3 purchases/yr |
| Take-rate (ceos-agents) | 15–25% [2] | JetBrains 15% flat; Shopify 20% (0% on first $1M); AppExchange 15–25% |
| Risk: Anthropic offers zero take-rate marketplace | HIGH [3] | VS Code Marketplace precedent; Anthropic official skills registry already live at 0% |

### TAM

`TAM = 1.5M paying Claude Code seats × 10% (buyers) × $100/year × 20% take-rate`  
`TAM = 1.5M × 0.10 × $100 × 0.20 = $3M`

**TAM range: $1.5M – $9M/year** (narrow due to zero-take-rate competitive risk)

**Critical constraint:** Anthropic's official skills registry is already live with zero take-rate and 55+ official + 72+ community plugins [3]. If Anthropic maintains zero take-rate (HIGH probability per Q-C5 analysis), a ceos-agents marketplace can only survive by differentiating on: (a) billing infrastructure, (b) eval ratings data, (c) enterprise procurement contracts. Raw take-rate revenue is structurally capped.

### SAM

`SAM = above TAM × 50% addressable (fraction reachable before Anthropic crowds out) = $750K – $4.5M`

### SOM

| Scenario | Y1 | Y3 | Y5 |
|---|---|---|---|
| Downside (Anthropic kills marketplace economics) | $0 | $0 | $0 |
| Base (ceos-agents captures niche enterprise billing layer) | $150K | $500K | $1.2M |
| Upside (ceos-agents becomes dominant curated marketplace with billing) | $500K | $3M | $8M |

**Verdict:** Marketplace take-rate is NOT a viable primary revenue stream. It is EARLIEST to build, but SMALLEST and HIGHEST RISK due to Anthropic platform risk. Best role: distribution / discovery engine that drives Streams 1 and 6.

---

## Stream 3 — Agent-Native Tracker SaaS

*ceos-agents builds and hosts a proprietary issue tracker purpose-built for autonomous agent workflows. Revenue: per-seat subscription.*

### Inputs

| Input | Value | Source / Assumption |
|---|---|---|
| Global project tracker market | ~$2.5B ARR [ASSUMPTION] | Atlassian $5.2B FY2025 revenue [4]; Jira ~50% of revenue; Linear $100M ARR [5] |
| Jira paying organizations | 300,000+ [4] | Atlassian customer count |
| Linear paying organizations | 18,000 [5] | Latka/press |
| "Agent-native" tracker premium over Jira | $5–$15/seat/month incremental [ASSUMPTION] | AI features premium over base tracker; below Copilot Enterprise add-on |
| Market share capturable (Years 1–3) | 0.05–0.5% of tracker seats [ASSUMPTION] | Category creation; no direct analog |

### TAM

`TAM = 300,000 Jira orgs × 40 seats avg × $120/seat/year (agent-native tracker ARPU) = $1.44B`

Narrowed: "agent-native tracker" is a new category. Realistic TAM = fraction of Jira/Linear orgs willing to migrate:  
`TAM (realistic) = 50,000 AI-forward orgs × 30 seats × $120/yr = $180M`

**TAM range: $50M – $500M** (depending on category creation success)

### SAM / SOM

| Scenario | Y1 | Y3 | Y5 |
|---|---|---|---|
| Downside (fails to differentiate from Jira + AI plugins) | $0 | $0 | $0 |
| Base (1,000 orgs × 30 seats × $100/yr) | $3M | $15M | $50M |
| Upside (5,000 orgs × 50 seats × $150/yr) | $37.5M | $150M | $400M |

**Build time estimate:** 18–36 months to viable tracker SaaS (ASSUMPTION). Too slow for solo-founder without funding. Best path: lightweight adapter layer (ceos-agents acts as the "agent layer" on top of existing trackers) rather than building a full tracker from scratch.

**Verdict:** HIGH CEILING, HIGH BUILD COST, LONG TIMELINE. Not earliest-to-monetize. Deferrable to Year 3+.

---

## Stream 4 — Agent-Native Source-Control SaaS

*ceos-agents builds a proprietary source-control system with agent-native primitives (pipeline-state-aware branching, autonomous PR creation, conflict resolution). Revenue: per-seat subscription.*

### Inputs

| Input | Value | Source / Assumption |
|---|---|---|
| GitHub paid seats (2026) | 4.7M Copilot paid [6] + GitHub Enterprise est. 10M+ seats [ASSUMPTION] | GitHub does not disclose enterprise seat count separately |
| GitLab ARR | ~$700M+ [ASSUMPTION] | GitLab public company; FY2025 revenue ~$756M per last filing |
| Premium for agent-native source control | $5–$30/seat/month [ASSUMPTION] | Above GitHub Enterprise $21/seat/mo or GitLab Premium $29/seat/mo |

### TAM

`TAM = 50M professional developers × 20% paying for source control SaaS × $120/seat/year = $1.2B`

But agent-native source control is a new category; realistic TAM in 2026–2028:  
`TAM (realistic) = 5M dev seats in AI-forward orgs × 15% willing to switch × $120/yr = $90M`

### SOM

| Scenario | Y1 | Y3 | Y5 |
|---|---|---|---|
| Downside (GitHub ecosystem lock-in too strong) | $0 | $0 | $0 |
| Base | $1M | $8M | $30M |
| Upside | $5M | $40M | $150M |

**Critical constraint:** GitHub + GitLab network effects are among the strongest in software. Building a competing source-control SaaS requires: (a) Git protocol compatibility, (b) Actions/CI equivalent, (c) existing customer migration. This is a $10M+ investment to get to MVP. Extremely high platform competition risk from GitHub's Copilot Coding Agent (which already runs at the source-control layer).

**Verdict:** STRATEGICALLY INTERESTING, OPERATIONALLY PROHIBITIVE for solo-founder. Not recommended as primary revenue stream without significant funding.

---

## Stream 5 — Agent Evaluation SaaS (Claude-grade Hosted)

*Claude-grade is operated as a hosted AGENTS.md evaluation API. Developers and teams submit agent definitions; Claude-grade returns scores, improvement suggestions, and benchmark comparisons. Revenue: per-evaluation, subscription API, or data licensing.*

### Inputs

| Input | Value | Source / Assumption |
|---|---|---|
| Publicly available AGENTS.md files (GitHub search) | Estimated 5,000–20,000 [ASSUMPTION] | Proxy: 1,000+ Claude Code plugin repos × avg 2–5 agent files; exact count requires GitHub API search |
| Target buyers: teams with custom agents | 30,000–100,000 [ASSUMPTION] | Orgs building Claude Code workflows × fraction with custom agents |
| Pricing: eval API | $0.05–$0.20 per evaluation call [ASSUMPTION] | Braintrust, Langfuse comparables: $0.02–$0.10/eval; Claude-grade non-LLM evals cheaper |
| Pricing: improvement tier (LLM-enhanced) | $0.50–$2.00 per improvement call [ASSUMPTION] | LLM inference cost ($0.10–$0.50) + margin |
| Benchmark subscription (enterprise) | $500–$5,000/org/month [ASSUMPTION] | Access to benchmark corpus, trend reports, cross-company percentiles |

### TAM

`TAM (eval API) = 50,000 orgs × 100 evals/month × $0.10/eval × 12 months = $6M`

`TAM (benchmark subscription) = 5,000 enterprise orgs × $1,000/month = $60M`

**Combined TAM: $10M – $80M** (eval API is commodity; benchmark data is where defensibility lives)

### SAM

`SAM = 10,000 orgs × 50 evals/month × $0.10 × 12 + 1,000 enterprise subscriptions × $1,000/mo × 12`  
`SAM = $600K + $12M = $12.6M`

### SOM

| Scenario | Y1 | Y3 | Y5 |
|---|---|---|---|
| Downside (low adoption; Anthropic ships native eval) | $50K | $150K | $300K |
| Base (500 orgs × avg $200/month) | $1.2M | $4M | $10M |
| Upside (5,000 orgs × avg $500/month) | $30M | $60M | $90M |

**Earliest-to-launch:** Claude-grade is described as "shippable today" (TypeScript, Vercel-ready). Time to first revenue: **30–60 days** if hosted API is stood up. This is the fastest path to any revenue.

**Key dependency:** The eval data moat requires continuous accumulation. 1,000 evals = no moat. 100,000 evals = lightweight moat. 10,000,000 evals across diverse agent types = strong moat. The moat builds slowly unless ceos-agents distributes a free eval tier aggressively.

**Verdict:** EARLIEST-TO-MONETIZE, SMALLEST SOM IN YEAR 1, but has a path to $10M+ if benchmark data accumulates. Strategic value: also validates and improves the core plugin product.

---

## Stream 6 — Enterprise Support / White-Glove Contracts

*Enterprise teams pay for: SLA-backed support, custom agent development, onboarding/integration services, dedicated instance hosting with compliance (SOC2, HIPAA). Revenue: ACV-based contracts.*

### Inputs

| Input | Value | Source / Assumption |
|---|---|---|
| Enterprise buyer profile | 200–2,000 developer orgs, regulated industries (fintech, healthtech, defense) [ASSUMPTION] | |
| ACV range | $20,000–$200,000/year [ASSUMPTION] | GitLab Self-Managed enterprise $99/seat/yr × 200–2,000 seats; SonarQube Enterprise comparable |
| Number of enterprises willing to pay in Year 2 | 5–25 [ASSUMPTION] | Solo-founder limit; enterprise sales cycle 3–9 months |
| Support/professional services mix | 50% recurring support + 50% PS [ASSUMPTION] | |

### TAM

`TAM = 5,000 enterprise dev orgs globally (>200 devs, AI-forward, regulated) × $50,000 ACV = $250M`

Narrowed to self-hosted/Gitea/Redmine segment (where ceos-agents has unique value):  
`TAM (regulated/self-hosted) = 1,000 orgs × $50,000 = $50M`

### SAM / SOM

| Scenario | Y1 | Y3 | Y5 |
|---|---|---|---|
| Downside (no enterprise sales without team) | $0 | $0 | $200K |
| Base (5 contracts × $30K ACV) | $150K | $1M | $4M |
| Upside (25 contracts × $80K ACV + PS revenue) | $2M | $10M | $30M |

**Key constraint:** Enterprise sales require dedicated sales capacity. Solo-founder can close 2–5 enterprise deals/year through network (enough for $100K–$500K Y1 ARR). Scaling requires a sales hire at ~$120K/year + commission.

**Verdict:** HIGHEST ARPU PER CUSTOMER, LONGEST SALES CYCLE. Best as Year 2–3 complement to PLG-driven streams, not Year 1 primary.

---

## Cross-Stream Summary

| Stream | SAM | Y1 SOM Base | Y3 SOM Base | Y5 SOM Base | Time to First Revenue | Build Cost | Risk Level |
|---|---|---|---|---|---|---|---|
| 1. Hosted Autopilot SaaS | $360M | $3.6M | $18M | $54M | 3–6 months | MEDIUM | MEDIUM |
| 2. Marketplace Take-Rate | $4.5M | $150K | $500K | $1.2M | 1–2 months | LOW | HIGH (Anthropic risk) |
| 3. Tracker SaaS | $180M | $3M | $15M | $50M | 18–36 months | HIGH | HIGH |
| 4. Source-Control SaaS | $90M | $1M | $8M | $30M | 24–48 months | VERY HIGH | VERY HIGH |
| 5. Eval SaaS (Claude-grade) | $12.6M | $1.2M | $4M | $10M | 1–2 months | LOW | LOW |
| 6. Enterprise Support | $50M | $150K | $1M | $4M | 1–3 months (inbound) | LOW | LOW |

**Largest SOM (Y5 Base):** Stream 1 — Hosted Autopilot SaaS at $54M  
**Earliest to monetize:** Stream 5 — Eval SaaS (Claude-grade), 30–60 days to first revenue

---

## 3-Year and 5-Year Projections (Base Scenario, Combined Streams)

*Assumes starting with Streams 2, 5, 6 in Year 1; adding Stream 1 in Year 2; deferring Streams 3 and 4.*

| Year | Stream 1 | Stream 2 | Stream 5 | Stream 6 | **Total ARR** |
|---|---|---|---|---|---|
| Y1 | $0 | $150K | $1.2M | $150K | **$1.5M** |
| Y2 | $3.6M | $300K | $2M | $500K | **$6.4M** |
| Y3 | $18M | $500K | $4M | $1M | **$23.5M** |
| Y4 | $36M | $600K | $6M | $2M | **$44.6M** |
| Y5 | $54M | $800K | $10M | $4M | **$68.8M** |

**Downside scenario (Y5):** $12M ARR (Stream 1 fails, Streams 5+6 only)  
**Upside scenario (Y5):** $170M ARR (Stream 1 captures 2% of SAM)

---

## Key Inputs Sensitivity Table

| Input | Base Value | If changes to | Y5 ARR impact |
|---|---|---|---|
| Hosted Autopilot ARPU | $600/seat/yr | $1,200/seat/yr | +$54M (doubles Stream 1) |
| Qualifying org count | 30,000 | 15,000 | -$27M Stream 1 Y5 |
| OSS→paid conversion | 0.5% | 2% | +$81M Stream 1 Y5 |
| Marketplace take-rate | 20% | 0% (Anthropic zero) | Stream 2 = $0 |
| Claude-grade benchmark data | Accumulates | Anthropic ships native eval | Stream 5 drops 70% |

---

## Citations (Market Sizing Specific)

| # | Source | Used For |
|---|---|---|
| [1] | https://www.getpanto.ai/blog/claude-ai-statistics (2026-04-23) | Claude Code WAU |
| [2] | https://plugins.jetbrains.com/docs/marketplace/revenue-sharing-and-fees.html (2026-04-23) | Marketplace take-rate |
| [3] | https://groundy.com/articles/claude-code-plugins-anthropic-s-official-plugin-ecosystem-explained/ (2026-04-23) | Anthropic marketplace status |
| [4] | https://www.businesswire.com/news/home/20250130093810/en/Atlassian-Announces-Second-Quarter-Fiscal-Year-2025-Results (2026-04-23) | Atlassian customer count |
| [5] | https://aakashgupta.medium.com/linear-hit-1-25b-with-100-employees-heres-how-they-did-it-54e168a5145f (2026-04-23) | Linear customer count |
| [6] | https://www.getpanto.ai/blog/github-copilot-statistics (2026-04-23) | GitHub Copilot paid seats |
| [A] | Stack Overflow Developer Survey 2025 https://survey.stackoverflow.co/2025 (2026-04-23) | Professional developer count |
