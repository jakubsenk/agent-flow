# Brainstorm Proposal — CONSERVATIVE

**Author:** Douglas "Doug" Berrington, CFO-in-residence
**Persona:** Enterprise-SaaS CFO, 20 years, ex-VP Finance ($400M ARR dev-tools IPO), 2x mid-cap SaaS CFO, Wharton MBA, CFA
**Date:** 2026-04-23 (forge-2026-04-23-001 Phase 3)
**Input:** Phase 2 consolidated research (`final.md`, `market-sizing.md`, `competitor-table.md`, `platform-risk.md`)

---

## 1. Executive Summary + CEO Pitch

**Executive summary (EN).** ceos-agents becomes an **open-core enterprise orchestration platform** for AI coding agents, anchored on the GitLab / HashiCorp / MongoDB playbook. The MIT plugin (v6.9.1, already shipped) is the distribution layer: it seeds bottom-up adoption inside engineering teams, particularly those on **YouTrack, Redmine, and Gitea** — the three niche trackers where Anthropic has near-zero incentive to ship a native first-party integration (Phase 2 platform-risk table: ZERO exposure for niche trackers vs. H probability for Jira/Linear native). The paid layer sells **hosted autopilot with SSO/SCIM/audit logs, Claude-grade private-eval as a compliance artifact, and an enterprise support SLA**. Pricing is anchored at $39/seat/mo Starter, $99/seat/mo Business, and custom ACV starting at $60k/yr for Enterprise — deliberately below the $200+/mo Devin ceiling the market has already rejected. This is a capital-efficient, unit-economics-first path: ramen-profitable at ~200 paid seats, $1M ARR achievable in 12-18 months with one founding AE, $10M ARR on a 4-5 year horizon with disciplined mid-market sales motion.

**Executive summary (CZ).** ceos-agents se stává **open-core enterprise orchestrační platformou** pro AI kódovací agenty, postavenou na prověřeném modelu GitLab / HashiCorp / MongoDB. MIT plugin (v6.9.1, již vydán) slouží jako distribuční vrstva: zajišťuje bottom-up adopci v engineering týmech, zejména těch používajících **YouTrack, Redmine a Gitea** — tři niche trackery, kde Anthropic nemá prakticky žádný důvod stavět nativní integraci (Phase 2 platform-risk: nulová expozice pro niche trackery vs. H pravděpodobnost pro Jira/Linear). Placená vrstva prodává **hostovaný autopilot se SSO/SCIM/audit logy, Claude-grade private-eval jako compliance artefakt, a enterprise support SLA**. Ceny: $39/seat/měs Starter, $99/seat/měs Business, Enterprise vlastní ACV od $60k/rok — záměrně pod stropem $200+/měs, který trh již odmítl (Devin). Kapitálově efektivní cesta: ramen-profitable při ~200 placených seatech, $1M ARR za 12-18 měsíců s jedním zakládajícím AE, $10M ARR na horizontu 4-5 let.

**CEO pitch (EN, one line).** *"We sell the compliance, control, and eval layer that turns MIT-licensed agent plugins into a purchase-order-ready enterprise platform — starting with the three trackers Anthropic will never natively integrate."*

**CEO pitch (CZ, one line).** *"Prodáváme compliance, kontrolní a eval vrstvu, která z MIT-licencovaných agent pluginů dělá enterprise platformu s PO podpisem — začínáme u tří trackerů, které Anthropic nikdy nativně neintegruje."*

---

## 2. Business Model Canvas

| Block | Content |
|-------|---------|
| **Customer Segments** | (1) Mid-market engineering teams (50-500 devs) on YouTrack, Redmine, or Gitea — our primary beachhead, least Anthropic risk. (2) Regulated-vertical enterprises (finance, healthcare, defense contractors) needing SOC2/SSO/audit for any agent tooling. (3) Dev-tool OSS power-users as a free-tier funnel. |
| **Value Propositions** | (1) "Your agents, audited." — every agent action logged, SSO-gated, SCIM-provisioned, and exportable for SOC2/ISO27001. (2) Only credible autopilot for YouTrack/Redmine/Gitea shops — where Jira-native tools don't ship. (3) Claude-grade private-eval: prove your agents are improving, not regressing, with a proprietary evaluation score. (4) Enterprise SLA: 99.9% uptime, named TAM, 4-hour P1 response. |
| **Channels** | (1) OSS distribution via the v6.9.1 plugin and Anthropic's free plugin registry (land). (2) Content + technical SEO targeting "YouTrack AI agent", "Redmine autopilot", "Gitea CI bot" (inbound). (3) Outbound to named regulated accounts using community-revealed usage signals (expand). (4) Two-speaker partnership with YouTrack/JetBrains and Gitea maintainers for co-marketing. |
| **Customer Relationships** | Self-serve for Starter (credit card, no sales touch). Sales-assist for Business (discovery call + pilot). Dedicated Customer Success + named TAM for Enterprise. Public Discord/Slack community for OSS users — low-cost support leverage and product-signal channel. |
| **Revenue Streams** | (1) Hosted Autopilot SaaS seat subscriptions (primary, ~80% of ARR by Y3). (2) Enterprise ACV with custom terms including Claude-grade private-eval + SLA (secondary, ~15%). (3) Claude-grade standalone evaluation SaaS for agent teams not yet on ceos-agents (fastest-to-revenue, ~5% but serves as land vector). We explicitly **exclude** marketplace take-rate, proprietary tracker SaaS, and proprietary source-control SaaS. |
| **Key Resources** | (1) The MIT codebase itself (21 agents / 29 skills / 184 tests — a credibility and distribution asset). (2) Claude-grade TypeScript eval engine (shippable today — the paid eval wedge). (3) Asysta CEOS dataset (NDJSON link graphs — internal proprietary data for benchmarking). (4) Founder + 2-3 senior engineers. (5) SOC2 Type I certification by month 12 (required to close Enterprise). |
| **Key Activities** | (1) Enterprise-grade runtime engineering (hosted autopilot, SSO/SCIM, audit log). (2) Niche-tracker integration depth (the moat: keeping YouTrack/Redmine/Gitea integrations ahead of anything generic). (3) Sales — founder-led until ~$1M ARR, then one AE hire. (4) SOC2/ISO27001 compliance work. (5) Community stewardship of the OSS plugin. |
| **Key Partners** | (1) Anthropic (platform provider; we are a good citizen in their registry, not a competitor). (2) JetBrains/YouTrack, Gitea, Redmine maintainers (distribution partnerships). (3) Cloud infra provider (AWS or GCP for hosted runtime; single provider for cost discipline until $3M ARR). (4) Compliance auditor (SOC2 firm). (5) Regulated-vertical SIs (downstream for F500 deployment services — optional Y3). |
| **Cost Structure** | (1) People: ~70% of OPEX, 6-8 FTEs by Y2 (4 eng, 1 AE, 1 CS, founder + 1 ops). (2) Anthropic API pass-through: variable COGS, budgeted at ~20% of hosted-autopilot revenue (gross-margin target 70%+). (3) Cloud infra: ~5-8% of revenue. (4) Compliance + legal: ~$120k/year fixed. (5) Marketing: deliberately low (~5-8% of revenue) — open-core relies on community + content, not paid acquisition. |

---

## 3. Pricing Table

| Tier | Price | Target customer | What it unlocks vs. prior tier |
|------|-------|-----------------|--------------------------------|
| **Community (OSS)** | $0 — MIT plugin, self-host | Individual devs, OSS projects, evaluators | Full plugin (21 agents, 29 skills, all 6 trackers), self-hosted autopilot, community support only — **the distribution and trust-building tier.** |
| **Starter** | **$39/seat/mo** (annual) / $49 month-to-month. Minimum 3 seats. | Small teams (3-20 devs), bootstrapped startups, agencies | Hosted autopilot runtime (no self-host ops burden), basic webhook observability, email support, 1 concurrent pipeline run per seat. **Unlocks: zero-ops hosting + we manage Anthropic API keys + usage dashboard.** |
| **Business** | **$99/seat/mo** (annual). Minimum 10 seats. Typical: $10k-50k ARR per customer. | Mid-market engineering orgs (20-200 devs), compliance-light regulated shops | Everything in Starter + **SSO (SAML/OIDC), SCIM provisioning, audit log export (CSV/JSON), Claude-grade private-eval lite (public benchmarks), 4-hour P2 SLA, priority Slack support, 3 concurrent pipelines per seat.** Unlocks: procurement-ready, InfoSec-approvable. |
| **Enterprise** | **Custom ACV, floor $60k/year, typical $80-300k, ~$125/seat effective for 500-seat deal** | F500, regulated (fintech/health/defense), 200+ devs, CISO-approved tooling lists | Everything in Business + **Claude-grade private-eval full mode (proprietary benchmark sets, regression alerts, custom eval criteria), dedicated TAM, 99.9% uptime SLA, 4-hour P1 response, VPC / single-tenant deployment option, SOC2 Type II report + DPA + MSA, named security contact, quarterly business reviews, custom legal terms (indemnity caps, audit rights), unlimited concurrent pipelines.** Unlocks: signature from CISO + CFO, not just VP Eng. |

**Pricing rationale (Doug's note).** Starter at $39 is below the $50 psychological self-serve ceiling; Business at $99 clears the "needs manager approval" threshold but stays under $100 anchor. Enterprise floor at $60k/yr is calibrated to one named AE's quota capacity (8-10 deals/yr at $80-150k ACV = $800k-$1.5M quota). We deliberately avoid the $200+/seat/mo zone — Phase 2 evidence: Devin crashed $500 → $20/mo; the market has repriced. Our Enterprise effective /seat (~$125) sits in the Cursor-Enterprise / Copilot-Enterprise range, which is the proven zone.

**Volume discounting:** 10% at 50 seats, 15% at 100, 20% at 250, custom above 500. No volume discount at Starter.

---

## 4. Revenue Math: 0 → $10M ARR Path

All figures USD. Anchored on Phase 2 base-case market-sizing (Stream 1 SAM = $360M; base SOM Y1 $3.6M / Y3 $18M / Y5 $54M). I am pacing **below** the Phase 2 base SOM trajectory — Doug's rule: always plan below the market sizing.

### Milestone 0 → First 10 paying customers (end of month 4-6)

| Metric | Value |
|---|---|
| Customers | 10 |
| Avg seats per customer | 6 (mix of 3-seat Starter + a couple 10-seat Business design-partners) |
| ARPU (per customer, annualized) | ~$5,800 |
| MRR / ARR | $4,800 / **$58K ARR** |
| CAC | **Founder-sold, ~$2,500/customer fully loaded** (founder time @ $180/hr × ~14hr avg sales cycle). Source: Phase 2 assumption ASM-5 on founder sales motion; Bessemer "founder-led" benchmark. |
| LTV (@ 2.5% monthly logo churn = 30% annual) | ARPU × gross-margin (70%) × 1 / churn = $5,800 × 0.70 × 3.33 = **$13,500** |
| LTV / CAC | 5.4× |
| Gross margin | 60% (early cloud overhead underutilized; below steady state) |
| Payback period | **~7 months** |
| What changes | Founder-led sales, concierge onboarding, hand-crafted Slack support. Design-partner discounts (20-30%). No AE hire. |

### Milestone 1 → 100 paying customers (end of month 12-15)

| Metric | Value |
|---|---|
| Customers | 100 (85 Starter, 12 Business, 3 Enterprise) |
| Avg seats / customer | 9 |
| ARPU (blended) | ~$7,500/yr |
| MRR / ARR | $62.5K / **$750K ARR** |
| CAC | Blended $3,800 (Starter: $1,200 self-serve-assisted; Business: $8,000 founder-sold; Enterprise: $25,000 founder + CS). Source: SaaStr 2025 mid-market benchmarks adjusted. |
| LTV (@ 20% annual logo churn post-design-partner cohort) | $7,500 × 0.72 × 5 = **$27,000** |
| LTV / CAC | **7.1×** ✅ |
| Gross margin | 72% |
| Payback period | **~10 months** ✅ |
| What changes | First CS hire (month 10-12). SOC2 Type I kickoff. Begin hiring founding AE. Move Anthropic API cost to a proper COGS line; negotiate annual committed-use discount. |

### Milestone 2 → $100K MRR / $1.2M ARR (end of month 15-18)

| Metric | Value |
|---|---|
| Customers | ~140 (110 Starter, 22 Business, 8 Enterprise) |
| Avg seats / customer | 11 |
| ARPU | ~$8,600/yr |
| MRR / ARR | $100K / **$1.2M ARR** |
| CAC | Blended $4,500 (founding AE ramped to 50%, inbound still 60% of pipeline) |
| LTV | $8,600 × 0.73 × 5.5 = **$34,500** |
| LTV / CAC | 7.7× |
| Gross margin | 73% |
| Payback period | **~11 months** ✅ |
| What changes | SOC2 Type I complete (unlocks bigger Business deals). First AE fully ramped. Marketing hire (content + technical SEO). Net revenue retention target: 110%+. |

### Milestone 3 → $1M → $3M ARR (end of month 24 — Y2 exit)

| Metric | Value |
|---|---|
| Customers | ~280 (200 Starter, 60 Business, 20 Enterprise) |
| Avg seats / customer | 14 |
| ARPU | ~$10,700/yr |
| ARR | **$3.0M** |
| CAC | Blended $5,200 |
| LTV (@ 15% annual logo churn, NRR 115%) | $10,700 × 0.75 × 6.67 × 1.15 ≈ **$61,000** (NRR-boosted) |
| LTV / CAC | 11.7× |
| Gross margin | 75% |
| Payback period | **~10 months** ✅ |
| What changes | Second AE. SOC2 Type II audit underway. Claude-grade private-eval launched as paid add-on. YouTrack co-marketing announcement. **Decision point: raise Series A (~$8-12M) or stay capital-efficient to $10M ARR.** |

### Milestone 4 → $10M ARR (end of year 4-5)

| Metric | Value |
|---|---|
| Customers | ~650 (400 Starter, 180 Business, 70 Enterprise) |
| Avg seats / customer | 22 (enterprise weighted) |
| ARPU | ~$15,400/yr |
| ARR | **$10.0M** |
| CAC | Blended $6,500 |
| LTV (@ 12% annual logo churn, NRR 120%) | $15,400 × 0.76 × 8.33 × 1.20 ≈ **$117,000** |
| LTV / CAC | 18× |
| Gross margin | 76% |
| Payback period | **~10 months** ✅ |
| What changes | 4-6 AEs, 2 SEs, VP Sales, VP Eng, CS team of 3. Regulated-vertical SI partnerships. International expansion (EU-first; EU data residency required for hosted autopilot). Enterprise-only eval benchmarks (the true proprietary data moat). |

**Summary discipline check.** Every milestone: CAC payback < 18mo ✅, gross margin > 70% ✅ (after milestone 1), LTV/CAC > 3 ✅. The model is unit-economics-honest from $750K ARR onward.

---

## 5. 24-Month Roadmap (customer-value, not features)

Every phase is anchored to revenue and customers — never to "we built X feature." Feature work is the means; customer value is the end.

### Months 1–3 — "First 10 paying design-partners" | MRR target: **$4.8K ($58K ARR)**
- **Customer target:** 10 paying logos (mix: 7 Starter ~3-6 seats, 3 Business 8-12 seats)
- **Primary activity:** Stand up hosted autopilot runtime (cloud-hosted v6.9.1 autopilot). SSO-SAML MVP. Billing (Stripe). Usage dashboard.
- **Sales motion:** Founder-led, direct outreach to known YouTrack/Redmine/Gitea-using engineering leaders via existing network + HN/community. 20-30% design-partner discount in exchange for case-study rights and product feedback.
- **Headcount:** Founder + 2 senior engineers (existing). No new hires yet.
- **Capital deployed:** ~$120K (infra, Stripe, legal for ToS/DPA templates, founders' time)
- **Exit criteria:** 10 paying logos, at least 2 Business-tier references, NRR > 100%, NPS > 40.

### Months 4–6 — "Product-led growth flywheel lit" | MRR target: **$12K ($150K ARR)**
- **Customer target:** 25 paying logos total (add 15 net)
- **Primary activity:** Self-serve signup live (credit card, no sales touch) for Starter tier. Content + technical SEO (3 pieces/week on YouTrack/Redmine/Gitea agent workflows). Public Claude-grade standalone (free tier) as a distribution lure — users who run Claude-grade on their agents become prospects for hosted autopilot. Audit-log export MVP.
- **Sales motion:** PLG self-serve for Starter. Founder-led Business deals (target: 5 Business logos closed in this phase).
- **Headcount:** +1 engineer (infra/runtime), +1 contractor for content marketing.
- **Capital deployed:** ~$180K cumulative additional
- **Exit criteria:** 25 logos, Starter self-serve conversion ≥ 2% of free-trial signups, Business ARPU ≥ $12K, 0 production incidents > SEV-2.

### Months 7–12 — "First enterprise deal + SOC2 Type I" | Exit ARR target: **$750K**
- **Customer target:** 100 paying logos; **at least 3 Enterprise logos** (ACV ≥ $60K each)
- **Primary activity:** SOC2 Type I audit (kickoff month 7, report month 12). SCIM provisioning. Audit log full coverage. Claude-grade private-eval lite for Business tier. First VPC / single-tenant deployment option for Enterprise.
- **Sales motion:** Hire founding AE (month 8-9). Target accounts: JetBrains/YouTrack user community, Gitea-using European fintechs, US defense-contractor R&D teams.
- **Headcount:** +1 founding AE, +1 CS, +1 engineer (compliance/security). Team = 6 FTE.
- **Capital deployed:** ~$550K cumulative additional (SOC2 audit ~$60K, AE OTE ~$180K/yr, CS $130K, eng $180K, marketing $60K, infra/tools $40K)
- **Exit criteria:** $750K ARR, 3+ Enterprise logos, SOC2 Type I report in hand, NRR ≥ 105%, CAC payback ≤ 12mo.

### Months 13–18 — "Sales motion repeatability + expansion" | Exit ARR target: **$1.5-1.8M**
- **Customer target:** 180 logos, 10+ Enterprise, NRR 110%+
- **Primary activity:** Second AE + SE hire. Prove sales motion is AE-reproducible (founder disengages from deal-level). SOC2 Type II audit begins. Claude-grade private-eval **full mode** launched (proprietary benchmark suites per vertical — the moat thickens). Co-marketing with JetBrains + Gitea.
- **Sales motion:** Two AEs + SE. 60% inbound, 40% outbound. Founder becomes CEO (strategy, fundraising-optional, exec hires).
- **Headcount:** +1 AE, +1 SE, +1 engineer, +1 CS. Team = 10 FTE.
- **Capital deployed:** ~$900K cumulative additional
- **Exit criteria:** $1.5M+ ARR, AE-led deal velocity (≥ 60% of new ACV closed by AEs, not founder), repeatable qualification playbook documented, < 10% logo churn annualized.

### Months 19–24 — "Series A readiness OR ramen-to-scale bootstrap" | Exit ARR target: **$3.0M**
- **Customer target:** 280 logos, 20+ Enterprise
- **Primary activity:** **Fork-in-the-road decision at month 18.** Path A: raise Series A ($8-12M @ $30-50M pre) to accelerate to $10M ARR in 24 more months with 20-25 FTE. Path B: stay bootstrapped, grow 70-100% YoY organically, target cash-flow positive at $3-4M ARR, aim for $10M ARR in 48-60 months. Both paths viable given unit economics; recommendation depends on CEO risk tolerance + market timing.
- **Headcount (Path A):** +3 AE, +2 SE, +2 eng, VP Sales, VP Eng = 17 FTE end of month 24
- **Headcount (Path B):** +1 AE, +1 eng, +1 CS = 13 FTE end of month 24
- **Capital deployed (non-A-round):** ~$2.1M cumulative 24-month opex (Path B footprint)
- **Exit criteria:** $3M ARR, CAC payback ≤ 12mo, NRR ≥ 115%, SOC2 Type II report issued, at least one $200K+ Enterprise logo (validates upper-end pricing), international expansion plan drafted.

---

## 6. Moat Statement

**The moat is proprietary enterprise orchestration depth in the niche-tracker corridor Anthropic will not natively serve, compounded by switching costs from deep tracker-workflow integration and a proprietary evaluation-data asset (Claude-grade private-eval) that gets better with every paying customer.** Concretely: a 300-dev enterprise running ceos-agents against YouTrack with 14 months of audit logs, 40 custom review rules, a Claude-grade regression-alert history, SCIM-provisioned team structure, and a SOC2 Type II-audited pipeline does not rip-and-replace to save $20/seat — ripping it out is an 8-12 week procurement + re-audit event for them. That is a measurable, testable switching cost (target: > 3× ARPU total cost of switching). The Claude-grade proprietary-eval layer adds network-effect economics: the more customers run Claude-grade, the richer our benchmark distribution, the better we can flag regressions vs. industry norms — a data asset that Anthropic's native eval (even if shipped) cannot match without our customer population. The OSS plugin is NOT the moat — it is the distribution and trust layer that lets us land enterprise deals other vendors can't even see.

---

## 7. Platform-Risk Mitigation

Phase 2 `platform-risk.md` identifies 4 Anthropic scenarios. As the CFO persona I weight platform risk 2× heavier than the other personas — here is concrete, specific mitigation for each. No "we'll pivot" hand-waving.

| Anthropic scenario | Probability × Horizon (Phase 2) | Revenue at risk | **Concrete mitigation lever** |
|---|---|---|---|
| **Monetized marketplace take-rate** (Anthropic launches paid marketplace with 15-30% take-rate) | M (30-45%) × 12-24mo | FATAL **only** for a marketplace-primary model. Our model explicitly excludes marketplace as a revenue stream. | **Pre-committed lever:** we never took marketplace revenue, so we have nothing to lose. The MIT plugin lives on Anthropic's free registry AND we ship parallel distribution via a VS Code extension + a GitHub App that wraps the hosted-autopilot runtime (so enterprise users never depend solely on the Claude Code plugin runtime). Already a v6.9.0 deferral in roadmap; we front-load it to month 4-6. |
| **Native Jira + Linear integration** in Claude Code | **H (60-70%)** × 12mo | SEVERE for plugin-only Jira/Linear players. **ZERO for our niche-tracker focus.** | **Pre-committed lever:** we deliberately do NOT compete for the Jira/Linear corridor — our GTM is YouTrack/Redmine/Gitea-first. If Anthropic ships native Jira/Linear, **we benefit**: it validates the category and proves that niche trackers will remain unserved. Our sales pitch becomes easier: "Anthropic won't build this for you; we did." Additional hedge: we keep YouTrack integration depth 12-18 months ahead of any generic integration (custom YouTrack workflow rules, YouTrack-specific agent behaviors, YT-state-machine awareness). |
| **Native AGENTS.md eval / scorecard** in Claude Code | M (30-45%) × 12-24mo | FATAL for basic Claude-grade public eval; LOW for Claude-grade **private** mode | **Pre-committed lever:** the paid Claude-grade tier is explicitly *private, enterprise-data-driven, regression-alerting eval* with customer-specific benchmark suites and SLA-backed alerts. Anthropic can ship a generic public score; they cannot ship an eval that knows *your* repo's last 90 days of regression trends + your 14 custom eval criteria + your compliance-audit export. Our private-eval wedge is data + integration depth, not just algorithm. Public Claude-grade becomes a free funnel (Rafa-style). |
| **Full-pipeline autonomous composer** in Claude Code Managed Agents | **H (65-75%)** × 12mo | FATAL for "we sell autonomous coding." MODERATE for enterprise orchestration + niche tracker + compliance. | **Pre-committed lever:** Our paid product does NOT sell "autonomous coding" — that's commoditized (Phase 2 finding 1). We sell **"autonomous coding, but your CISO approves it."** Mitigations: (a) hosted autopilot integrates with customer's VPC + audit requirements that Claude Managed Agents cannot match for regulated customers; (b) our runtime is tracker-first (YouTrack/Redmine/Gitea workflows), not general-purpose; (c) if Claude Managed Agents prices low, we can run on their runtime *beneath* our orchestration layer, not compete with it — becoming a "manager of managers" premium layer. |

**Cross-cutting hedge (all scenarios).** We diversify distribution early: VS Code Marketplace extension, GitHub App, Slack app, direct CLI — so that no single Anthropic API/registry change is fatal. We track `ANTHROPIC_DEPENDENCY_RATIO` = (revenue at risk if Anthropic ships native X) / (total ARR) as a board-level KPI and keep it < 40% from month 12 onward.

---

## 8. Corp-vs-Solo Viability

Honest assessment — this model has asymmetric fit. It works well as a corporate initiative; it works *survivably* as solo but is not ideal.

| Variable | Corporate initiative (CEO-funded, 12-24mo horizon) | Solo venture (ramen profitable in 6mo, no VC) |
|---|---|---|
| **Time-to-first-revenue** | 3-4 months (hosted autopilot MVP + 5-10 design-partner contracts) — compatible with corp horizon. | 3-4 months — **borderline**. Solo cannot wait 6+ months for first revenue without bridge income (consulting). |
| **Capital required Y1** | ~$550K (2-3 engineers + founding AE + SOC2 + infra). CEO/corp comfortable. | ~$120K if founder is sole engineer + uses Claude-grade as 60-day quick-revenue. **Requires consulting/advisory income bridge** or small ($250-500K) pre-seed. SOC2 deferred to Y2 — limits Enterprise deals Y1 (acceptable for ramen-profitable target, fatal for VC scaling). |
| **Sales motion fit** | ✅ Strong. Corporate can hire founding AE month 8-9. Founder-led sales to 10-20 logos then AE handoff is proven. | ⚠ Weak. Solo founder-led sales is labor-intensive; Enterprise deals require 6-9 months cycles that compete with product work. Ramen-profitable possible at $500K-$800K ARR on Starter+Business only, Enterprise deferred. |
| **Compliance (SOC2) timeline** | ✅ Month 7-12. Unlocks Enterprise ACVs by month 15. | ❌ Not viable in Y1. SOC2 costs $60K + 6mo founder-attention tax. Solo path works with Starter+Business only until $1M ARR, then SOC2 becomes affordable. |
| **Pricing power** | Full stack ($39/$99/$60K+ custom) available. | Starter + Business ($39/$99) only in Y1. Enterprise ACV closed only with explicit SOC2-deferred-by-agreement deals (rare). Effective ARPU ~$8K/yr instead of ~$12K blended. |
| **Founder risk concentration** | Distributed across corp governance, multiple eng hires. | **Concentrated.** Single bus-factor risk. If founder incapacitated, 0 revenue. No CS, no AE bench. |
| **Y2 exit ARR realistic** | **$3M** (model baseline) | **$600K-$1.2M** (ramen-profitable but not growth-stage) |
| **Y4-5 exit ARR realistic** | **$10M** (with Series A) or $5-6M (bootstrapped) | $2-4M (lifestyle business, still respectable) |
| **Works if CEO says no?** | N/A (CEO funded) | ✅ Yes, with consulting bridge + deferred SOC2 + Starter/Business focus. Doug's verdict: *survivable but suboptimal.* |

**Doug's verdict:** This model is **explicitly designed for the corporate-initiative path**. The enterprise open-core playbook assumes (a) you can afford SOC2 in Y1, (b) you can hire a founding AE in month 8-9, (c) you can carry 12-15 months to $1M ARR without revenue pressure. Solo-viable but meaningfully degraded. If the user goes solo, **Rafa's proposal (PLG-first, marketplace-lite, faster ramp) is a better fit** — the CFO honestly concedes this.

---

## 9. Dependence on Existing Shippable Components

Three assets exist today and materially accelerate this model. Here is what each contributes and what remains to be built.

| Asset | What it contributes to MVP | Gap remaining |
|---|---|---|
| **ceos-agents plugin v6.9.1** (MIT, shipped 2026-04-20) | The **distribution and trust layer**. 21 agents, 29 skills, 6-tracker support, 184 tests, Autopilot already implemented. Bottom-up adoption inside engineering teams without a sales call. Anthropic registry listing. Proof the author can ship. | Hosted runtime wrapper (cloud-hosted autopilot with per-customer isolation, usage metering, Stripe billing). SSO/SAML integration. SCIM provisioning. Audit log export pipeline. ~3 months of runtime/infra engineering. |
| **Claude-grade eval engine** (TypeScript, Vercel-ready, shippable today) | The **paid eval wedge** — both a 30-60 day quick-revenue MVP as standalone Claude-grade SaaS AND the Business/Enterprise tier differentiator. Public scorecard mode for free distribution funnel; private mode for paid. Already TypeScript + Vercel-ready = zero infrastructure cold-start. | Private-mode data model (customer benchmark storage, proprietary-benchmark-per-tenant, regression-alert logic). Enterprise eval criteria DSL. Compliance-artifact export format. ~2 months from MVP to Business-tier feature. |
| **Asysta CEOS dataset** (NDJSON link graphs) | **Internal proprietary benchmarking + the Claude-grade private-mode bootstrap corpus.** Real-world ceos-agents pipeline execution data that seeds the Claude-grade private-eval benchmarks before we have paying customers generating their own. Also a potential free-tier viral feature (agent ecosystem visualization), though Doug treats this as Rafa-territory and deprioritizes. | Licensing clarification (ASM-4 in Phase 2 — must confirm CEO/legal sign-off to use the dataset commercially). If commercially licensable, it is a material seed asset worth 6-12 months of benchmark-bootstrap time. If not licensable, we lose the cold-start advantage but can rebuild from hosted-autopilot customer data within 6-9 months. |

**Summary.** ~60% of the MVP is already shippable in some form. The remaining 40% (hosted runtime, SSO/SCIM, Stripe billing, Claude-grade private mode) is ~$300-400K of engineering over 3-4 months — well within the corporate-path capital envelope.

---

## 10. Summary + the 3 Biggest Risks I See in My Own Model

### The thesis in one sentence
Sell the compliance and control layer on top of a MIT-licensed plugin for the three trackers Anthropic won't natively serve, priced below the Devin-crash ceiling, with Claude-grade private-eval as the data-moat compounder — capital-efficient to $3M ARR, Series-A-optional to $10M.

### 3 biggest risks in MY OWN model (CFO self-critique — honest)

**Risk 1 — Niche-tracker TAM is possibly too small to reach $10M ARR on that corridor alone.**
Phase 2 market sizing assumed 30,000 qualifying orgs at the Claude-Code-plus-tracker intersection. Of those, the YouTrack/Redmine/Gitea share is likely 15-25% of the qualifying universe — call it 5,000-8,000 orgs globally. At my Y5 base case of 650 customers, I need ~10% market share of that specific corridor, which is aggressive for a niche. **Mitigation consideration:** the model probably has to expand to Jira/Linear at the Business and Enterprise tiers by month 18-24, accepting the platform-risk trade. I pretend this is purely a niche play but realistically the $10M path requires some Jira/Linear exposure, which re-introduces the very Anthropic risk I claimed to avoid. Sofía will correctly hammer this.

**Risk 2 — Hosted-autopilot gross margin is at mercy of Anthropic API pricing.**
I assume 70-76% gross margin. That assumes Anthropic API costs stay at or below ~20% of customer revenue (ASM-6 in Phase 2 — must measure, not estimate). If Anthropic raises prices, or if our average pipeline run consumes more tokens than estimated, gross margin can collapse to 50-55% — which kills Series A valuation multiples and squeezes the bootstrap path. **Mitigation consideration:** we need to instrument actual token cost per pipeline run within the first 30 days of hosted autopilot launch, negotiate committed-use discounts at month 6, and have a fallback pricing model (per-pipeline-run usage cap or overage fee on Starter) ready if per-seat economics degrade. I am underweighting this risk in the base case.

**Risk 3 — Founder-led-sales to AE-led-sales handoff is where most enterprise SaaS dies.**
The model assumes by month 12 we hire a founding AE and by month 18 the AE is closing 60% of new ACV. In my own CFO career I've watched this exact transition fail twice: founder doesn't document the sales playbook, AE can't replicate founder's technical authority, win rate drops from 35% to 12% for 6 months, CAC doubles, capital efficiency craters. The "ramp a founding AE" step is a real operational risk that I have glossed over with one bullet point in the roadmap. **Mitigation consideration:** start documenting sales qualification + objection handling + demo choreography from customer #1. Record every sales call (with consent). Hire the AE at month 8 not 9 so there are 2 months of founder-pair-selling before solo handoff. Budget for AE-ramp-failure (a 3-month productivity tax) in the capital plan — I have not done that in the numbers above.

### Bottom-line CFO verdict on my own proposal
**Investable but not heroic.** Unit economics are clean. Platform-risk hedged. Playbook proven (GitLab/HashiCorp/MongoDB). Boring in the best way. The risk is that "boring open-core enterprise" in 2026 may be too slow against a PLG competitor who wins the individual-developer mindshare race in the first 12 months — which is exactly what Rafa will argue. That tension is the right Gate-3 decision for the CEO to make.

---

**End of Doug Berrington proposal. ~4,800 words.**


