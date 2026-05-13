# Brainstorm Proposal — INNOVATIVE (Rafa Pontes)

**Author:** Rafael "Rafa" Pontes, 3x solo founder — drafted for forge-2026-04-23-001, Phase 3.
**Date:** 2026-04-23
**Lens:** Solo-founder, PLG, ramen-profitable in 6 months, ship in 4-6 weeks. Distribution > features. Moats from community + speed + data flywheel, NOT from enterprise switching cost.

---

## 1. Executive Summary

Stop trying to out-Devin Devin. Stop trying to out-Factory Factory. The market just repriced autonomous coding from $500 to $20 — which means the only winners will be the brand that **owns the free quality layer above everyone's agents**. That is Claude-grade.

Ship **Claude-grade Cloud** as a free "AGENTS.md Report Card" — one URL, paste your repo, get a public shareable score and badge. Bolt a $19/mo **Pro** tier on top (private evals, LLM improvement suggestions, benchmark percentiles, GitHub Action) and a $49/mo **Team** tier (multi-repo, Slack alerts, custom rubrics). Day 1 viral loop: every public report card is a shareable URL with a badge that embeds in READMEs — every embedded badge is free marketing. Month 2: layer a hosted autopilot add-on ($29/mo) for the 6-tracker niche using v6.9.1. Month 4: open the free marketplace where every skill has a Claude-grade score — badges become the flywheel that forces every serious plugin author to care about our score. Month 6: ramen profitable at ~$15k MRR, 300 paying users, zero VC, one founder.

**CEO pitch (EN):** "We ship a free AI-coding badge that every serious Claude Code repo will embed in its README inside 90 days — and we charge the 2% who want to see their private scores."

**CEO pitch (CZ):** "Vypustíme zadarmo 'AGENTS.md známku kvality', kterou si během 90 dnů nalepí do README každé vážnější Claude Code repo — a bereme peníze od 2 %, co chtějí vidět svoje soukromé skóre."

---

## 2. Business Model Canvas

| Block | Content |
|---|---|
| **1. Customer Segments** | (a) Indie devs + OSS maintainers building Claude Code plugins/agents (free badge users — distribution engine); (b) solo + SMB teams (1-20 devs) shipping agentic code, Claude Code power users — **primary paid segment**; (c) mid-market teams (20-100 devs) on niche trackers (YouTrack/Redmine/Gitea) — secondary paid; (d) plugin authors wanting reach (free marketplace supply side). Explicitly NOT F500 enterprises in Year 1. |
| **2. Value Propositions** | Free: "Public report card for your AGENTS.md in 30 seconds; shareable badge shows the world your agent definitions are good." Paid Pro ($19): "Private evals, LLM-powered 'Fix this' suggestions, GitHub Action, benchmark percentile, no rate limit." Paid Team ($49): "Every repo in your org scored; Slack alerts on regression; custom rubrics; pre-merge CI gate." Autopilot add-on ($29): "Drop-in hosted pipeline for YouTrack/Redmine/Gitea — the trackers Anthropic will never build for." |
| **3. Channels** | (1) Twitter/X + HN: "We scored every public AGENTS.md repo, here are the top 20" launch-thread; (2) Claude-grade badge virality (every README embed is a billboard); (3) ceos-agents GitHub (184 stars projection + 50 existing plugin users as beachhead); (4) indie newsletter (Rafa's own 8k-reader list); (5) Claude Code Discord + community; (6) ProductHunt + Indie Hackers; (7) conference sponsorship (zero budget — do lightning talks instead). |
| **4. Customer Relationships** | 100% self-serve for first 500 paying users. Founder-run Discord for paid tier. Monthly "State of AGENTS.md" public report co-marketing. Zero sales calls until >$100k MRR. |
| **5. Revenue Streams** | (a) Pro subscription $19/mo (primary); (b) Team subscription $49/mo (margin expander); (c) Autopilot add-on $29/mo (niche-tracker wedge); (d) Enterprise SLA at $499-$2,000/mo (inbound only, Month 9+); (e) Featured slot on marketplace homepage $99/mo (Month 6+); (f) API pay-as-you-go ($0.10/eval) for CI/CD tooling integrators (Month 4+). **Explicitly NO marketplace take-rate.** |
| **6. Key Resources** | Claude-grade TypeScript eval engine (shippable today, Vercel-ready); ceos-agents v6.9.1 plugin (MIT, 21 agents, 184 tests, autopilot + 6 trackers); Asysta CEOS NDJSON link-graph dataset (free viz tool); accumulated eval corpus (the moat, day 1 empty, grows exponentially); Rafa's distribution network (Twitter 12k, newsletter 8k, HN karma); MIT brand trust. |
| **7. Key Activities** | Week 1-2: Ship Claude-grade Cloud free tier + Pro. Week 3-4: Badge virality + 3 HN launches + State-of-AGENTS.md public report. Week 5-8: Autopilot hosted add-on on Vercel Functions. Month 3-4: Free marketplace UI (read-only, scores surfaced). Month 5-6: API monetization + Team tier polish. |
| **8. Key Partnerships** | Anthropic (pursue official partner program; apply Day 1); Vercel (hosting credits + AI SDK); niche-tracker vendors JetBrains/Redmine/Gitea (distribution co-marketing — free badges for their plugin users); 5-10 popular Claude Code plugin maintainers (seed the marketplace; give them "Verified Author" badges free forever). |
| **9. Cost Structure** | Infra (Vercel + Supabase): ~$200/mo ramping to $2k/mo at 1k users. Anthropic API (LLM improvement tier): pay-per-use, passed through on Pro ($1 cost at $19 revenue = 95% GM). Domain + tools: $100/mo. Founder salary: $0 — founder burns personal runway $5k-8k/mo until $15k MRR. **Total burn to ramen profit: ~$30-50k over 6 months.** |

---

## 3. Pricing Table

| Tier | Price | Target | What's included | Self-serve? |
|---|---|---|---|---|
| **Public Report Card** | $0 forever | Anyone with a public repo | One-click AGENTS.md eval; public URL; shareable badge; rate-limited to 5/day | Yes |
| **Pro** | **$19/mo** | Solo devs, OSS maintainers, moonlighters | Private evals; unlimited rate; LLM-powered "Fix my AGENTS.md" suggestions; GitHub Action; benchmark percentile; 5 private repos | Credit card, Stripe |
| **Team** | **$49/mo** | Teams 2-20 | Everything in Pro + unlimited private repos; Slack alerts; custom rubrics; pre-merge CI gate; basic SSO (Google workspace); 5 seats incl. | Credit card, Stripe |
| **Autopilot Add-on** | **+$29/mo** | Any paid tier + niche tracker | Hosted ceos-agents pipeline for YouTrack/Redmine/Gitea; 100 runs/mo; overage $0.30/run; your Anthropic API key passthrough OR our billing +20% | Credit card, Stripe |
| **Marketplace Feature** | **$99/mo** | Plugin authors seeking distribution | Homepage slot; "Staff Pick" badge; author page with email capture; metrics dashboard | Credit card, Stripe |
| **Enterprise SLA** | **$499-$2,000/mo** | Inbound only, Month 9+ | SSO/SCIM, on-prem option, DPA, audit log, custom rubrics, support SLA | Inbound → 30-min founder call → MSA; NO SDR, NO sales ops |

**Pricing rationale:**
- **< $50 entry** hits Rafa's design filter; $19 is below "expense-without-approval" threshold for every paying dev in the world.
- **LLM improvement tier is the defensible paid capability** (per Phase 2 Scenario 3 analysis — basic scoring commoditizes, improvement API does not).
- **Autopilot at $29/mo** undercuts Devin ($20 with overages that hit $80) and Factory ($20 with token complexity) — we win on simplicity + niche tracker support.
- **No freemium autopilot.** The autopilot costs money per run; giving it away = burn hell. Claude-grade eval costs near zero per call (deterministic checks + cached LLM calls), so freemium works there.
- **Enterprise gated behind inbound** — solo founder cannot do outbound enterprise; let them find us via badge saturation.

---

## 4. Revenue Math — 0 → 100 paying users in 30 days → $10k MRR → $100k MRR → $1M ARR

### Day 0-30 funnel assumptions (concrete)

**Existing distribution (free + paying attention):**
- ceos-agents GitHub users: ~50 active installers (current small base; assume 3x growth to 150 in Week 1 from launch traffic)
- Rafa's Twitter: 12,000 followers, ~3% engagement ≈ 360 eyeballs per launch thread
- Newsletter: 8,000 subscribers, ~30% open rate ≈ 2,400 reads per launch email
- HN: 3 posts across launch week (Show HN Claude-grade, Show HN Badge, Show HN Autopilot) — assume 1 front-pages = 40,000 uniques, 2 don't = 10,000 combined
- Claude Code Discord: ~15,000 members, lightweight posts = ~500 clicks
- Anthropic Discord + official plugin registry: ~30,000 Claude Code devs reachable

**Total Day 0-30 top-of-funnel reachable:** ~60,000 unique devs see Claude-grade free tool.

**Funnel math:**
- 60,000 uniques × 15% tool-try rate (Rafa benchmark from prior products) = 9,000 free evals performed
- 9,000 free evals × 40% "WOW this found real issues" rate = 3,600 "aha" users
- 3,600 × 8% paid conversion (aggressive but typical for tools priced <$20 with clear Pro gates — see Linear $19, PostHog $20, Vercel Pro $20 benchmarks) = **288 paying Pro signups**
- Minus 30-day free-trial-then-cancel churn ~30% = **~200 paying users net at Day 30**

**Conservative cut:** halve every stage → still 100 paying users at Day 30.

**30-day MRR target: ~100 Pro users × $19 = ~$1,900 MRR minimum; stretch $3,800 MRR.**

### Path to $10k MRR (Month 4-6)

At $19 ARPU blended (some upsell to $49 Team by Month 3):
- $10k MRR = ~500 paying users
- From 100 at Day 30 → 500 at Day 180 requires ~3.2× compounding quarterly, or ~27% MoM growth
- Drivers: (a) embedded badges compounding (each paid customer embeds in ≥1 README = 1 free impression per README view × ~100 views/mo = 100 exposures/customer/mo); (b) State-of-AGENTS.md monthly PR hit; (c) Autopilot add-on attach rate ~15% of Pro = +$29 incremental on ~75 users = +$2,175 MRR

### Path to $100k MRR (Month 12-18)

At blended $30 ARPU (Team + Autopilot mix):
- $100k MRR = ~3,300 paying customers
- From 500 → 3,300 in 12 months requires ~23% MoM compounding (aggressive but plausible if badge-virality holds)
- Driver: enterprise inbound (~20 enterprise deals at $1,500 ACV/mo blended = $30k MRR by Month 18)
- Driver: marketplace featured slots ~50 × $99/mo = $5k MRR
- Driver: API integration revenue ~$10k MRR from ~3 CI/CD vendor partnerships

### Path to $1M ARR (Month 18-24)

$1M ARR = ~$83k MRR — we cross this around Month 15-18 in base case.

### Path to $10M ARR (Month 30-48)

- $10M ARR = ~$833k MRR
- Requires ~25,000 paying users at $30 blended ARPU
- Phase 2 Stream-1 SAM ($360M) supports this if we capture ~0.3% of mid-market SAM
- **Honest assessment:** $10M ARR is a VC-scale outcome and NOT this proposal's commitment. Rafa's commitment is **$1-2M ARR ramen-profitable by Month 24**. Anyone who promises $10M ARR from a solo bootstrap is lying.

### Unit economics (Month 6 target state)

| Metric | Value | Notes |
|---|---|---|
| CAC | ~$20 blended (mostly organic) | Badge virality + HN + Twitter = near-zero paid CAC; ~10% of acquisitions from paid ads @ $100 CPA |
| ARPU | $22/mo blended (Pro heavy) | Grows to $30/mo by Month 18 as Team + Autopilot attach |
| Gross margin | 88% | LLM improvement API cost ~$1 per customer/mo; infra ~$1.50 |
| Payback period | ~1 month | CAC $20 / ARPU $22 × 0.88 GM ≈ 1 month |
| LTV (at 3% monthly churn) | $22 × 33-month expected life × 0.88 = $640 | LTV/CAC ~32× |
| Monthly churn | 3-5% target | Freemium viral products typically see higher churn than enterprise; accepted |

**Ramen-profitability bar: $15k MRR = ~500 users at $30 ARPU.** Hit Month 6.

---

## 5. 24-Month Roadmap

Every milestone ties to paying users, not features.

### Weekly (Weeks 1-8)

| Week | Milestone | Success metric |
|---|---|---|
| **1** | Ship Claude-grade Cloud free tier on Vercel: `claude-grade.sh/score?repo=X`. Embed badge API `/badge.svg`. Public launch on Twitter + newsletter + Claude Code Discord. | **500 free evals run** |
| **2** | Ship Pro tier ($19/mo, Stripe). Ship GitHub Action. Show HN: "We scored every public AGENTS.md repo, here are the top 20." | **30 paying users** |
| **3** | Ship Team tier ($49/mo, basic SSO). Publish first "State of AGENTS.md" monthly report (massive SEO + backlink magnet). | **60 paying users** |
| **4** | Badge virality push: DM top 50 Claude Code plugin authors offering free Pro in exchange for README badge embed. Show HN: Claude-grade Team. | **100 paying users** — **DAY 30 CHECKPOINT HIT** |
| **5** | Ship Autopilot hosted add-on MVP for **YouTrack + Gitea** (niche wedge from Phase 2 moat analysis). Built on ceos-agents v6.9.1 autopilot skill. | **130 paying, 10 Autopilot** |
| **6** | Ship Asysta context-viz as free tool at `asysta.sh` — users upload ecosystem; shareable viz URL. Second viral loop live. | **160 paying, 15 Autopilot** |
| **7** | Add Redmine to Autopilot. Launch indie-hacker newsletter sponsor week. ProductHunt launch (#1 product of the day target). | **200 paying** |
| **8** | Ship pre-merge CI gate (Team feature). Second "State of AGENTS.md" report. Close Week 8 with audit: what's working / cut what isn't. | **250 paying, $6k MRR** |

### Monthly (Months 3-6)

| Month | Milestone | Target |
|---|---|---|
| **3** | Free public marketplace UI at `ceos-agents.com/marketplace` — read-only directory of Claude Code plugins, each with Claude-grade score. NO take-rate, NO billing. Drives Claude-grade distribution. | **400 paying users; $9k MRR** |
| **4** | API monetization ($0.10/eval) — chase 2-3 CI/CD vendor partnerships (GitHub Actions integrators, CircleCI Orbs authors). First enterprise inbound call. | **550 paying; $12k MRR; 1 enterprise** |
| **5** | Marketplace featured-slot monetization ($99/mo). Enterprise SLA tier opens (inbound only). VS Code extension of Claude-grade evaluator (platform-risk hedge #1 per Phase 2). | **650 paying; $14k MRR; 3 enterprise** |
| **6** | **RAMEN-PROFITABILITY CHECKPOINT.** Kill anything not contributing to revenue. Launch annual plans (2 months free). Fall conference lightning talks. | **800 paying; $18k MRR; 5 enterprise** |

### Quarterly (Months 7-24)

| Quarter | Focus | Target ARR |
|---|---|---|
| **Q3** (Mo 7-9) | Team-tier conversion push; Slack + Microsoft Teams apps; deeper Claude Code Discord engagement; OSS contribution flywheel for Claude-grade rules. | $300k ARR |
| **Q4** (Mo 10-12) | Autopilot vertical expansion — add Slack-based triage, expand to mid-market teams. Apply to Anthropic partner program. | **$600k ARR** |
| **Q5** (Mo 13-15) | Enterprise inbound scale — hire first PT customer-success contractor. Launch self-host option for Autopilot (ceos-agents Enterprise edition) for regulated industries. | $1M ARR |
| **Q6** (Mo 16-18) | Asysta CEOS dataset monetization — org-dependency maps as paid feature for mid-market; second viral loop matures. | $1.5M ARR |
| **Q7** (Mo 19-21) | International — EU GDPR-compliant tier (Phase 2 ASM-2 mitigation); Japan + Czech language docs. | $2M ARR |
| **Q8** (Mo 22-24) | Evaluate: raise seed ($1-2M to accelerate to $10M ARR) OR stay profitable ($2-3M ARR ramen king). **Binary fork decision at Month 24.** | **$2.5-3M ARR** |

**What is explicitly NOT in the roadmap:**
- Proprietary issue tracker (boil-the-ocean; Jira + YouTrack exist)
- Proprietary source control (Git dominance; GitHub won)
- Full-pipeline autonomous composer (Anthropic will ship this — per Phase 2 Scenario 4 H-probability)
- Marketplace take-rate (Phase 2 market-sizing = $0-150k Y1; not worth cycles)
- Enterprise sales team before $500k ARR
- VC raise before $1M ARR (staying optional)

---

## 6. Moat Statement

**My moat is NOT "we have agents." My moat is a compounding data + community asset:**

1. **Claude-grade benchmark corpus (the data moat).** Every free eval and every paid eval feeds a growing corpus of `{agent definition, score, observed outcome}` triples. At 10k evals we have a trivially replicable dataset. At 500k we have something no competitor can match — cross-team benchmark percentiles that only exist if you've been aggregating for 12+ months. This is Phase 2 ASM-4's "keep code MIT, keep hosted service data proprietary" lever.
2. **README badge saturation (brand moat).** If by Month 6 the top 500 Claude Code plugin repos embed a Claude-grade badge, "Claude-grade score" becomes a de-facto standard — like `npm audit`, `codecov`, or `CI-passing` badges. Anthropic can ship a competing score, but they'd be the challenger to our incumbent badge. **Even if Anthropic ships, the badge shows OUR brand, not theirs.**
3. **Speed-of-iteration moat (founder moat).** Solo founder with one product, one domain, one user community ships 10× faster than a 50-person dev-tool company. Every Rafa-class solo product that won (Lenny's, Plausible, Tailwind UI, Ghost) won on iteration speed + community trust. This is un-copyable by design.
4. **Niche-tracker entrenchment (segment moat).** YouTrack + Redmine + Gitea is Phase 2's most durable finding — Anthropic and GitHub will not build these (probability L per Scenario 2). Autopilot add-on owns this niche.

**What is NOT my moat:** 6-tracker support generically (commoditizes via MCP within 12 months); autonomous coding (commoditized NOW); multi-agent orchestration (Claude Managed Agents is 70% of the way there).

---

## 7. Platform-Risk Mitigation — "Anthropic ships X" as OPPORTUNITY

My lens differs from every enterprise playbook: I treat Anthropic shipping features as **distribution accelerators**, not existential threats. Here's how each Phase 2 scenario maps:

### Scenario 1 — Anthropic monetized marketplace (M, 12-24mo)
- **We don't run a paid marketplace.** Our marketplace is free-publish with Claude-grade scores as the discovery signal. Anthropic shipping monetization = our free directory becomes MORE valuable as the neutral ground.
- **Mitigation: ALREADY BAKED IN.** No revenue exposure.

### Scenario 2 — Native Jira + Linear integration (H, 12mo)
- Jira + Linear go commodity. **We were never selling to Jira/Linear shops as the primary segment.** Our paid Autopilot is YouTrack + Redmine + Gitea — explicitly the Anthropic won't-build segment.
- **Mitigation: if we misread this, pivot Autopilot to "orchestration-on-top-of-native-Jira" (CircleCI Orbs pattern) in 2 weeks — not 6 months.**

### Scenario 3 — Native AGENTS.md eval score (M, 12-24mo)
- **This one matters most.** If Anthropic ships a native basic score, the free Claude-grade tier commoditizes.
- **Mitigation (staged):**
  - (a) **Partner, don't compete:** Apply to Anthropic partner program Week 1. Offer to BE the native score — license Claude-grade engine to Anthropic on rev-share.
  - (b) **LLM-improvement layer is the real product** — per Phase 2 §Scenario 3, basic scoring commoditizes; improvement suggestions don't.
  - (c) **Badge brand is the real moat**, not the algorithm. Shipping first buys 9-12 months of brand lead. Anthropic's score would show up as "Anthropic score" — a different brand, not a replacement.
  - (d) **If Anthropic kills us on eval: pivot in 2 weeks.** The infrastructure is Vercel functions + Stripe — not a 200-person engineering org. We flip to being the "pipeline observability + benchmark percentile" layer on top of Anthropic's native score.

### Scenario 4 — Full-pipeline autonomous composer (H, 12mo)
- **We don't compete on raw autonomy.** Claude Managed Agents already exists; we are NOT trying to be Devin.
- Autopilot add-on is **only for niche trackers Anthropic won't support.** If Anthropic ships native composer for Jira, our users cheer (cheaper tools), and they still pay us for YouTrack/Redmine/Gitea where it's unavailable.
- **Mitigation: positioning-first, not feature-first.** Every landing page headline says "the trackers Anthropic doesn't build for," not "autonomous coding."

**Summary: the platform-risk math on my model.** In the worst-case where ALL four scenarios materialize simultaneously within 12 months:
- Scenario 1: $0 revenue loss
- Scenario 2: $0 revenue loss (we didn't target that segment)
- Scenario 3: **~30% revenue loss** from free-tier churn; Pro tier (LLM improvement) holds
- Scenario 4: $0 revenue loss (Autopilot is niche-tracker-only)
- **Net: 30% worst-case hit, survivable, pivot-able in 2 weeks.** Compare to Doug's enterprise-open-core model which would lose 60-80% in the same scenario.

---

## 8. Corp-vs-Solo Viability

### Solo-founder viability: **HIGH ✅**

- Ship in 4-6 weeks: **YES** (Claude-grade is shippable today, Vercel-ready)
- Ramen profitable in 6 months: **YES** at $15k MRR = 500 paying users
- Burn to break-even: ~$30-50k total over 6 months, fundable from personal runway
- Decisions per day: ~20; latency: ~1 hour. This is where solo wins.
- **Filip-specific fit:** v6.9.1 autopilot, Claude-grade, Asysta are all his work — zero acquisition cost on the foundational components.

### Corporate initiative viability: **MEDIUM ⚠️**

Corporate lens slows this down in 4 specific ways:
1. **Brand/legal review of public badges** adds 4-8 weeks before Week 1 can happen. Solo ships in 3 days; corporate ships in 2 months.
2. **Pricing below $50/mo is "too cheap"** for most CEOs — the model works, but faces resistance from boards. Expect pressure to add $299/mo tiers that will tank top-of-funnel.
3. **Free marketplace with no take-rate** is anathema to CFO thinking. Expect pressure to monetize early = kill viral loop.
4. **Enterprise-first instincts** from corporate salespeople will push toward SDR hires and outbound in Month 3 — wrong for this model. The right move is to stay founder-led on sales until Month 9.

**If corporate path is chosen:** Hire Rafa-archetype as GM with autonomy over pricing, hiring, and product scope. Board must commit to "PLG for 12 months, no enterprise sales pressure."

**If solo path:** Filip runs this exactly as designed. Primary risk: he's the only point of failure. Mitigation: incorporate in Month 3 (single-member LLC), hire PT contractor in Month 6 (~$3k/mo from first $15k MRR).

---

## 9. Dependence on Existing Shippable Components

This is the entire reason a 4-6 week MVP is possible. Without these, this proposal becomes a 6-month plan and dies.

| Component | Role | Built? | Dependency level |
|---|---|---|---|
| **Claude-grade (TypeScript, Vercel-ready)** | Core eval engine powering Claude-grade Cloud | ✅ Ready today per Phase 2 | **CRITICAL — Week 1 blocker without it** |
| **Claude-grade LLM improvement tier (`fix-ai.ts`)** | Pro-tier paid feature | ✅ Already scaffolded | **HIGH — Week 2 blocker** |
| **ceos-agents v6.9.1 autopilot skill** | Powers the $29/mo Autopilot add-on | ✅ Shipped 2026-04-20 | **HIGH — Week 5 blocker** |
| **v6.9.2 Bash subprocess dispatch fix** | Needed for Autopilot to run headless; currently blocked by Claude Code #26251 | ⚠️ Planned, not implemented | **MEDIUM — workaround: run Autopilot as single-issue dispatch initially (pre-v6.9.2); full batch in Week 6** |
| **Asysta CEOS NDJSON link-graph dataset** | Free viral-loop viz tool (Week 6) | ✅ Ready today per Phase 2 | **MEDIUM — Week 6 launch; non-blocking for Week 1-4 revenue** |
| **6-tracker support (YouTrack, Redmine, Gitea, Jira, Linear, GitHub)** | Niche-wedge differentiator | ✅ Shipped in v6.x | **HIGH — Autopilot add-on value prop** |
| **MIT license baseline** | Brand trust + community growth engine | ✅ Shipped v6.9.0 | **HIGH — OSS→paid conversion gate depends on hosted-data moat, not code moat** |
| **Rafa/Filip's distribution (newsletter, Twitter, GitHub)** | Day-1 launch channel | ✅ Exists | **HIGH — 60k Day-1 top-of-funnel depends on it** |
| **Claude Code Discord + Anthropic community reach** | Secondary channel | ✅ Exists | **MEDIUM — can substitute with HN + Twitter** |

**What is NOT required:** No new agents, no new skills, no new core contracts, no enterprise features, no SSO, no SOC2, no tracker SaaS, no source-control SaaS, no composer. Everything needed to hit Day-30 target already exists in the repo.

**One integration risk:** v6.9.2 Autopilot subprocess fix is on planned-but-not-started. Week 5 Autopilot launch can either (a) ship single-issue dispatch mode (acceptable, matches v6.9.1 behavior), or (b) require v6.9.2 to land first. Week 5 is the drop-dead; if v6.9.2 slips past Week 4, Autopilot launches in single-issue mode and batch mode ships in Week 7.

---

## Appendix: Day 1 Viral Loop (Named Mechanism)

> **User X runs `curl claude-grade.sh/score?repo=myproject` → receives a shareable URL `claude-grade.sh/r/myproject` with a public score + embeddable badge `![AGENTS.md score](claude-grade.sh/badge/myproject)` → embeds badge in README on GitHub → when user Y visits myproject's README they see the badge → Y clicks badge → Y lands on claude-grade.sh and scores their own repo → Y embeds badge → ... (compounding)**

Viral coefficient target: K = 1.2 (every user produces 1.2 new free users). At K=1.2 from 100 Day-30 paying users = 500 paying users by Month 6 without any paid marketing. This is aggressive but matches the Plausible, Vercel deploy-badge, and codecov precedent patterns.

---

**END — Rafa Pontes, signed 2026-04-23.**
