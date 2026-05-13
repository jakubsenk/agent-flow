# Assumptions Inventory — ceos-agents Business Model

**Author:** Phase 2 Research Agent B (Mira Halen)
**Date:** 2026-04-23
**Purpose:** Surface 8 unstated but material assumptions; for each, provide sensitivity analysis showing how business-model choice changes if the assumption is violated.

All monetary figures in USD.

---

## Overview

The following assumptions are NOT explicitly stated in the brief but are material to business-model design. Each is labeled with: current assumed state, alternative state, and the business-model implication of each.

---

## ASM-1 — Solo-Founder vs. Corporate Initiative Runway

**Assumed state (default):** CEO declines; Filip proceeds solo with personal runway of 12–18 months at ~$5K–$15K/month burn.

**Alternative state:** CEO approves; ceos-agents becomes a corporate product with 2–5 FTE and $500K–$2M initial budget.

| Dimension | Solo-Founder Path | Corporate Path |
|---|---|---|
| Burn rate | $5K–$15K/month (infra + Anthropic API costs) | $100K–$200K/month (salaries + infra) |
| Time to first revenue required | 6–9 months (cashflow survival) | 12–18 months (acceptable loss period) |
| Business model | PLG self-serve only (no enterprise sales cycle) | Enterprise sales viable (6-month cycles acceptable) |
| Optimal revenue stream | Stream 5 (Claude-grade hosted, 30-60 days) + Stream 1 (autopilot SaaS, 3–6 months) | Stream 1 (autopilot) + Stream 3 (tracker SaaS) |
| Pricing ceiling | $200–$500/month per team (teams won't wait for enterprise procurement) | $20K–$200K ACV (enterprise procurement viable) |

**Decision-blocking question:** CEO presentation outcome TODAY determines which path is live. Both paths have valid business models, but the product architecture differs: solo path optimizes for 0-touch onboarding and credit-card checkout; corporate path optimizes for SSO/SCIM and contract negotiation.

**Sensitivity:** If solo path and burn drops below $3K/month (API cost crisis), the business must reach $3K MRR within 6 months or pivot/pause. At 0.5% conversion of 600K Claude Code seats = 3,000 paying users at $1/month = $3K MRR — achievable only with a free-to-paid conversion gate.

---

## ASM-2 — Target Geography and Legal Jurisdiction

**Assumed state:** Czech Republic / EU-first (Filip is EU-based; existing network is CZ/SK).

**Alternative state:** US-first go-to-market (larger TAM, more competition, requires US legal entity for enterprise contracts).

| Dimension | EU-First | US-First |
|---|---|---|
| GDPR compliance for hosted runtime | Required from Day 1 (3–6 months delay + DPA agreements) | Not required (but US enterprise buyers expect SOC2) |
| TAM reach | ~20% of global SAM (EU developers) | ~45% of global SAM (US developers) |
| Competition | Lower — Cursor/Devin have limited EU enterprise presence | Higher — all major players are US-focused |
| Enterprise sales cycles | Longer (procurement in CZ/SK is relationship-based) | Shorter for SMB; longer for enterprise |
| Pricing power | EUR pricing often 80–90% of USD equivalent | Full USD pricing |
| Data residency | EU data residency required for regulated industries (fintech, health) → GDPR moat | US hosting sufficient for most customers |

**Sensitivity:** If EU-first and GDPR compliance is delayed, hosted autopilot launch is delayed 3–6 months. This is the difference between $1.5M Y1 ARR (base) and $0.5M Y1 ARR (GDPR-delayed). **Mitigation:** Launch API-only tier without persistent data storage first (no GDPR data processing obligation for stateless evals); add hosted state storage only after GDPR compliance is in place.

---

## ASM-3 — Target Customer Size

**Assumed state:** Mid-market focus — teams of 10–100 developers at AI-forward companies already using Claude Code and an issue tracker.

**Alternative states:**
- SMB (1–10 devs): Higher count, lower ACV, faster sales, PLG-only
- Enterprise (500+ devs): Lower count, high ACV ($50K–$200K), requires compliance features and sales team

| Dimension | SMB (1–10 devs) | Mid-Market (10–100 devs) [Assumed] | Enterprise (500+ devs) |
|---|---|---|---|
| SAM customer count | ~200,000 orgs [ASSUMPTION] | ~30,000 orgs | ~3,000 orgs |
| ACV | $200–$1,200/yr | $2,400–$12,000/yr | $20,000–$200,000/yr |
| Conversion friction | Low (credit card) | Medium (manager approval) | High (procurement + legal) |
| Self-host rate | HIGH (engineers self-host freely) | MEDIUM | LOW (IT prefers hosted + SLA) |
| Features required | Core pipeline, simple setup | SSO, audit log, team billing | SCIM, SOC2, dedicated instance, on-prem option |
| $1M ARR customer count | ~4,000 customers | ~250 customers | ~20 customers |

**Sensitivity:** If ceos-agents targets SMB but SMB teams self-host (MIT license), conversion to paid is <1% of installs. SMB is attractive on paper but hostile to paid conversion without a non-removable cloud hook (e.g., shared pipeline history stored on ceos-agents servers). Mid-market has the best economics: large enough for managed-hosting value, small enough for direct sales without full enterprise procurement.

---

## ASM-4 — Willingness to Close-Source Adjacent Components

**Assumed state:** Core plugin is MIT-licensed (immutable commitment to community). Claude-grade and Asysta CEOS licensing status is unclear; Filip may be willing to operate them as closed-source hosted services.

**Alternative states:**
- Full OSS: everything MIT → hosted-runtime or support/SLA is the only paid layer
- Partial closed-source: Claude-grade eval API + Asysta CEOS dataset kept proprietary → eval data moat viable
- Dual-license (BSL/AGPL + commercial): plugin becomes non-MIT → fork risk, community backlash

| Assumption State | Business Model Enabled | Defensibility | Community Risk |
|---|---|---|---|
| Full OSS (MIT everything) | Hosted runtime + SLA only | LOW — competitors can self-host entire stack | None |
| Core MIT + Claude-grade/Asysta closed [Assumed default] | Eval SaaS (Stream 5) + hosted runtime | MEDIUM — eval data moat if accumulated | Low (core still MIT) |
| BSL/AGPL dual-license | Enterprise license + feature gating | HIGH | HIGH — community fork; OpenDevin/AutoCodeRover examples show forks succeed quickly |

**Sensitivity:** If Claude-grade is kept MIT *including its benchmark corpus*, there is no eval data moat — anyone can run Claude-grade locally and build their own corpus. The moat requires keeping the *accumulated benchmark scores* server-side and behind a paid API. This is a product architecture decision, not a licensing decision: **keep Claude-grade code MIT, keep Claude-grade's hosted service data proprietary.**

---

## ASM-5 — VC Appetite vs. Bootstrapped Path

**Assumed state:** Bootstrapped or CEO-funded. No external VC raise planned in Year 1.

**Alternative state:** VC seed raise of $2M–$5M in Year 1–2.

| Dimension | Bootstrapped | VC-Funded |
|---|---|---|
| ARR target | $1M–$5M (cashflow-positive by Y3) | $10M–$50M ARR by Y3 (growth over margin) |
| Revenue stream priority | Earliest-to-revenue (Claude-grade + enterprise support) | Highest-ceiling (autopilot SaaS + tracker SaaS) |
| Pricing strategy | Maximize margin; charge higher from Day 1 | Growth-first; low price + usage-based to maximize adoption |
| Runway | 12–18 months (must hit $3K MRR to survive solo) | 24–36 months (VC capital extends runway) |
| Business model ceiling | $5M–$10M ARR (acceptable exit via acquisition) | $50M–$200M ARR (VC return requires 10× on $3M seed = $30M ARR minimum) |

**Sensitivity:** VC path requires targeting a market with >$100M ARR ceiling visible within 5 years. Based on market sizing, only Stream 1 (Hosted Autopilot SaaS, $54M Y5 base) and Stream 3 (Tracker SaaS, $50M Y5 base) meet this threshold. Streams 5 and 6 alone are not VC-scale. **If VC-funded, must commit to building Stream 1 aggressively AND build a conversion moat (SSO, audit logs, compliance) within 18 months of launch.**

---

## ASM-6 — LLM API Cost Absorption Model

**Assumed state:** Hosted autopilot SaaS absorbs Anthropic API costs within a subscription fee (fixed-price, customer doesn't see per-run cost).

**Alternative state:** Usage-based pass-through — customer pays subscription base + per-pipeline-run overage billed at Anthropic API cost + margin.

**Cost model (base case):**
- Full bug-fix pipeline (triage → fixer → reviewer → test → publish): ~$0.50–$3.00 per run [ASSUMPTION based on ceos-agents agent model counts × token estimates]
- Team running 100 auto-fixes/month: $50–$300 API cost
- At $600/seat/year for 40-seat team = $2,000/month subscription
- API cost for 100 runs/month = $50–$300 → margin = $1,700–$1,950/month (85–98% gross margin)
- BUT: at high-usage teams (500 runs/month), API cost = $250–$1,500/month → margin compresses to 25–87%

| Pricing Model | Margin at 100 runs/mo | Margin at 500 runs/mo | Customer adoption |
|---|---|---|---|
| Fixed subscription ($2K/mo per team) | 85–97% | 25–87% | Simple; predictable for customer |
| Usage-based ($20 base + $3/run) | 85%+ consistently | 85%+ consistently | Higher friction; unpredictable bills |
| Hybrid ($500/mo + $2/run overage) | 75%+ | 75%+ | Best of both; Devin's model |

**Sensitivity:** If Anthropic raises API prices by 2×, fixed-subscription margin compresses severely at high-usage teams. Usage-based model protects margin but reduces adoption. **Recommendation:** Hybrid model (Devin's approach) — base subscription covers fixed usage quota; overages billed per run. This is the current market-clearing design.

---

## ASM-7 — Anthropic Partner / Preferred-Vendor Status

**Assumed state:** Arms-length relationship. ceos-agents is a community plugin, not an Anthropic-designated partner.

**Alternative state:** Anthropic designates ceos-agents as a featured/recommended plugin, driving distribution at near-zero CAC.

**CAC impact:**

| Distribution Status | CAC | Customer acquisition path |
|---|---|---|
| Official Anthropic-featured (partner) | $50–$200 (content/referral) | Anthropic marketplace listing drives inbound |
| Arms-length (community plugin) | $500–$2,000 (B2B SaaS median) [ASSUMPTION] | SEO, content marketing, direct outreach |
| Enterprise sales-led | $5,000–$15,000 per enterprise customer | Field sales + SDRs |

**Unit economics impact:**
- At $500 CAC and $600 ARPU/year, payback period = 10 months — acceptable
- At $2,000 CAC and $600 ARPU/year, payback period = 40 months — unacceptable for bootstrapped
- At $50 CAC (Anthropic-featured), payback period = 1 month — excellent

**Sensitivity:** Without Anthropic partnership, solo-founder must budget 30–40% of Year 1 ARR toward customer acquisition (content, developer advocacy, conferences). This makes the $1.5M Y1 ARR target harder but achievable via direct outreach to companies already using Claude Code Teams (identified through LinkedIn, GitHub, etc.).

**How to validate:** Apply to Anthropic's Development Partner Program (support.claude.com/en/articles/11174108) [ASSUMPTION: program accepts commercial plugin partners, not just data-sharing partners]. Seek listing in official claude-plugins-official registry.

---

## ASM-8 — Competitive Moat Horizon

**Assumed state:** ceos-agents has a 6–12 month window before Copilot Coding Agent (formerly Workspace) and Cursor Background Agents add YouTrack/Gitea/Redmine integration, eroding the 6-tracker moat.

**Sensitivity range:** 3 months (if GitHub prioritizes missing integrations) to 24 months (if Redmine/Gitea are too niche to prioritize).

| Horizon | Business Model Implication |
|---|---|
| 3 months | Must ship first paid product in 60 days; only Stream 5 (Claude-grade) and Stream 6 (support) are safe; Stream 1 requires faster execution |
| 6–12 months [Assumed] | Standard launch timeline; can build hosted autopilot SaaS properly with auth, billing, multi-tenant |
| 18–24 months | Can invest in deeper moats: Asysta CEOS dataset, Claude-grade benchmark corpus, SSO/compliance |

**Hardest assumption to validate:** How fast will GitHub add YouTrack and Gitea support? GitHub Copilot Coding Agent currently integrates with GitHub Issues natively and is working on Jira/Linear via MCP [7]. YouTrack (JetBrains-owned) and Gitea (open-source, niche) are lower priority for GitHub. Redmine (Rails, primarily EU regulated industries) is very unlikely to be prioritized by GitHub. **Conclusion: the 6-tracker moat is most durable in the YouTrack + Gitea + Redmine segment — exactly the EU/regulated-industry segment where ceos-agents has geographic advantage (ASM-2).**

---

## Decision-Blocking Assumptions (Must Validate Before Spec Finalization)

| # | Assumption | How to Validate | Urgency |
|---|---|---|---|
| ASM-1 | CEO presentation outcome | CEO meeting TODAY | IMMEDIATE |
| ASM-4 | Claude-grade/Asysta licensing intent | 1:1 with Filip (5 minutes) | IMMEDIATE |
| ASM-6 | Actual Anthropic API cost per full pipeline run | Run 10 test pipelines and measure tokens | THIS WEEK |
| ASM-3 | Target company size — can 250 mid-market customers be acquired in Year 2? | 10 customer discovery conversations | WEEK 2 |
| ASM-7 | Anthropic partner program availability for commercial plugins | Review support.claude.com partner docs | WEEK 1 |

---

## Citations

| # | URL | Access Date |
|---|---|---|
| [7] | https://github.blog/changelog/2025-10-28-managing-copilot-business-in-enterprise-is-now-generally-available/ | 2026-04-23 |
| [8] | https://support.claude.com/en/articles/11174108-about-the-development-partner-program | 2026-04-23 |
