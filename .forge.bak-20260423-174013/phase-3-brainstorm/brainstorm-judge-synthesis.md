# Brainstorm Judge Synthesis — Ilana Grischkowsky

**Author:** Ilana Grischkowsky, independent strategy advisor (ex-McKinsey Partner, TMT)
**Date:** 2026-04-23 (forge-2026-04-23-001 Phase 3)
**Inputs:** Doug's Enterprise Open-Core, Rafa's Claude-grade Cloud + viral badge, Sofía's Services-First counter + invest/pass memos, Phase 2 consolidated research
**Audience:** The user, 90 minutes before the CEO meeting.

---

## 1. Executive Headline

**Recommend a Hybrid path staged as Services-Led → Productized SaaS**, in that order — Sofía's counter-proposal for Y1 (regulated-industry productized engagements at $75K–$200K), then layer Doug's hosted-autopilot + Claude-grade private-eval SaaS on top starting month 12–15 once we have 8–10 regulated references and real private eval data. We pick this because it is the **only variant of the four that simultaneously survives all four Anthropic platform scenarios from Phase 2, has 60-day time-to-first-revenue, funds itself from month 3, and builds the one moat nobody else can replicate in under 24 months: an eval corpus of real regulated codebases under audit**. If the primary path is invalidated in the first 90 days (no regulated pipeline, CEOS corp access does not materialize), we fall back to Rafa's Claude-grade Cloud PLG path as solo-viable ramen-profitable plan B with realistic $1–2M ARR horizon, not $10M. **The single biggest open question: does the user have CEO-backed access to CEOS's existing regulated-industry client relationships, or is this a cold-start? Answer rewrites the entire recommendation.**

---

## 2. 12-Dimension Comparison Table

| Dimension | Doug (Ent. open-core) | Rafa (Claude-grade Cloud + badge) | Sofía (Services-first) | Hybrid (Services Y1 → SaaS Y2 — RECOMMENDED) |
|-----------|----------------------|------------------------------|------------------------|---------------------------------------------|
| **Product wedge** | Hosted autopilot + SSO/SCIM/audit for YouTrack/Redmine/Gitea | Free AGENTS.md badge + $19 Pro LLM-improvement tier | $75–200K productized regulated-industry deployments | Sofía's $75–200K engagements Y1; Doug's hosted SaaS layered on month 15–18; Rafa's free Claude-grade as lead-gen throughout |
| **MVP scope** | Hosted runtime wrapper + SSO + Stripe + audit log (~3 mo eng) | Claude-grade Cloud free + Pro + badge (~2 wk eng, already Vercel-ready) | 2 pilot engagements (design-partner) + Claude-grade public tier | 2 pilot engagements + Claude-grade public tier + Pro ($49/mo) in parallel |
| **Time-to-market** | 3–4 months to first paying customer | **4–6 weeks to first paying user** | 60–90 days to first pilot engagement close | 60–90 days to first engagement; Claude-grade Pro revenue by week 6 (incidental) |
| **Initial pricing** | $39 / $99 / $60K+ custom | $0 / $19 / $49 / +$29 Autopilot | $75K / $150–200K engagements, $10–40K/mo retainer | Engagements primary, Claude-grade $49/$199 as funnel; hosted SaaS $100–300K ACV from month 15 |
| **Target first-customer** | Mid-market YouTrack shop, design-partner discount | Indie dev / OSS maintainer / small Claude Code team | Regulated mid-market (banking/defense/healthcare) — founder's network | Regulated mid-market — same as Sofía |
| **Year-1 revenue target** | $750K ARR (100 customers) — Sofía calls this 5–9× inflated | $18K MRR = ~$216K run-rate at month 6; $300–500K ARR end-of-Y1 | **$1.44M services revenue** (11 engagements + 3 retainers) | **$1.2–1.5M** (10 engagements + Claude-grade Pro ~$80K ARR + retainers) |
| **Year-3 revenue target** | $3M ARR (Sofía: realistic $1.8–2.2M) | $2.5–3M ARR ramen king — Sofía: realistic $800K–$1.5M | $14–20M blended ($8–14M honest range per Sofía's own footnote) | **$8–12M blended** (services + SaaS crossover in Y3) |
| **Moat type** | Hypothetical enterprise switching costs + Claude-grade private-eval (requires customers we don't have) | Data moat + badge brand (both challenged by Anthropic shipping native) + speed | **Regulated-industry eval corpus** (un-copyable — Anthropic cannot build without paying customers in banking/defense) | Same as Sofía; amplified because SaaS tier from month 15 captures the eval data at scale |
| **CAC payback** | ~10 months (Doug); realistically 14–18 per Sofía's math | ~1 month if K=1.2 holds (Rafa); ~3–5 months at honest K=0.5 per Sofía | ~6 months per engagement (services LTV/CAC 18×) | ~6 months engagement; ~10 months SaaS from month 15 |
| **Platform risk exposure** | HIGH if expands to Jira/Linear (own admission); MODERATE niche-only | MODERATE on free tier (Anthropic native eval = 30% revenue hit); bounded on paid | **LOW** — services revenue structurally insulated; Anthropic cannot commoditize human consulting | **LOW Y1** (services dominant), MODERATE Y2+ (SaaS tier exposed but cushioned by cash-flow) |
| **Solo-viability (1–5)** | 2 — SOC2 + AE hiring + 12mo-to-$1M kills solo | **5** — designed for solo, Rafa's whole ethos | 1 — services require delivery capacity solo cannot provide | 2 — same services constraint as Sofía |
| **Corp-viability (1–5)** | 4 — classic playbook, proven but slow | 2 — corp governance kills viral pricing & free marketplace | **5** — perfect fit for CEOS consulting DNA | **5** — same corp fit + SaaS optionality |

**Critical numbers to remember as we present:**
- Doug needs **134× OSS community growth in 12 months** to hit his conversion math at Phase 2's honest 1.5% rate — "magical thinking" per Sofía.
- Rafa's K=1.2 viral coefficient is **2× over-modeled** vs. Plausible/Fathom actual historical data (0.6–0.9 at peak).
- Phase 2 dev-tools OSS-to-paid conversion: **0.5–3%**, not the 8% Rafa uses or the implicit 5%+ Doug requires.
- Sofía's Y3 $14–20M has an honest footnote: "$8–14M ARR" — still 2–4× Doug's Y3 $3M.

---

## 3. Recommended Path — Hybrid: Services-Led Y1 → Productized SaaS Y2

**Why this one.** Three Phase 2 findings make this the dominant choice.

First, Phase 2 is unambiguous that **basic autonomous coding is commoditized** (Claude Code 87.6% SWE-bench, Managed Agents ships autonomy) and that the market has **repriced to $20/mo for individual devs**. Any business model that sells "agent capability" to individuals is fighting Anthropic on Anthropic's home turf at Anthropic's price. The Hybrid doesn't — it sells **regulated deployment + compliance + audit work** that Anthropic cannot commoditize because Anthropic will not run banking IT engagements. That is the structural insulation Doug and Rafa both lack.

Second, Phase 2's revenue-stream ranking places **Stream 3 (Enterprise niche-tracker support / custom ACVs)** at "high-margin, defensible" with 6–12 month time-to-first-revenue. Productized consulting engagements are *Stream 3 with a product-izing wrapper* — and they compress the time-to-revenue to 60–90 days because the scope is fixed and the customer pays for delivery, not subscription-ramp. This is the fastest path to material revenue (> $1M) in the Phase 2 evidence base, beating both Doug's 12–18 month $1M-ARR trajectory and Rafa's $1M ARR at month 15–18 base case.

Third, the one moat that survives every Anthropic scenario in Phase 2's platform-risk table is **proprietary eval data from regulated codebases under audit**. Not MIT plugins (commoditized), not badge brand (Anthropic can out-brand), not enterprise switching costs (don't exist on day 1), not speed-of-iteration (decays on first hire). Services engagements *produce* this data as a byproduct of delivery — every $150K engagement is one more row in the only corpus Anthropic cannot scrape from public GitHub. This is the single strongest element across all three proposals: Sofía's identification that **services don't just generate revenue, they generate the moat ingredient**. Doug's Claude-grade private-eval thesis is correct; Sofía's insight that services are the cheapest way to fill that eval corpus is the missing piece.

**What weaknesses Sofía's own critique leaves unaddressed for this path.** Two.

(a) **Services businesses plateau without product transition.** Sofía flags this in her invest memo ("services-first businesses are classically hard to scale past $10M ARR"). The mitigation the user must personally commit to: **hosted SaaS tier ships month 15, not month 24**. This means product engineering starts at month 6 (~$300K eng budget) and SaaS alpha is running against engagement customers by month 12. Do not let services inertia delay the SaaS launch — Sofía will condition Series A on this.

(b) **Solo infeasibility.** If CEOS corp does not commit 5–8 senior FTEs and regulated-industry BD access, this plan does NOT work. Sofía is explicit: "If the CEO says no and user is solo, this proposal does not work." The user must personally pre-commit: **if Gate 3 does not approve the hiring + BD access, default to fallback (Rafa's Claude-grade-only) same day, not after 90 days of trying to force services solo.**

**First 90 days if the user commits today.**

| Days | Activity | Revenue / milestone |
|------|----------|---------------------|
| 1–14 | CEO Gate 3 sign-off; secure Claude-grade + Asysta licensing IN WRITING; hire 2 senior delivery engineers; ship Claude-grade Cloud free public tier + Pro ($49/mo) on Vercel (parallel track, 2 eng-weeks) | Licensing resolved; Claude-grade live |
| 15–45 | Founder-led BD into CEOS regulated-industry network — target 8 qualified conversations, 3 pilot-engagement LOIs at $52.5K design-partner pricing; Claude-grade Pro ~50 paying users ($2.5K MRR incidental) | 3 LOIs signed |
| 46–90 | Close 2 pilot engagements @ $52.5K each, start delivery; hire 3rd delivery engineer; first case-study draft in customer legal review | **$105K booked** + ~$3K MRR Claude-grade = **Day 90: $105K services booked, $36K ARR Claude-grade** |

**Revenue milestones:**

| Milestone | Timeline | Target |
|-----------|----------|--------|
| Day 30 | Licensing resolved, Claude-grade live, 3 LOIs | $0 realized, $157K pipeline |
| Day 90 | 2 pilot engagements delivering | **$105K booked services + $36K Claude-grade ARR** |
| Month 6 | 5 engagements delivered, 1 retainer lit | **$400K booked services + $84K Claude-grade ARR** |
| Month 12 (Y1 exit) | 11 engagements, 3 retainers, SaaS alpha, SOC2 T1 in progress | **$1.4M services revenue + ~$150K Claude-grade ARR** |
| Month 36 (Y3 exit) | 35+ engagements cumulative, 18+ SaaS logos, SOC2 T2, SI channel live | **$8–12M ARR blended** (services + retainers + SaaS + Claude-grade), Series A optional at $40–60M pre |

---

## 4. Fallback Path — Rafa's Claude-grade Cloud PLG (Solo-viable)

**Invalidation triggers for Primary (any one triggers fallback):**

1. **Day 30**: CEO has not approved headcount + BD access to regulated accounts, OR Claude-grade/Asysta licensing not resolved in writing.
2. **Day 60**: Zero pilot-engagement LOIs signed despite 15+ qualified BD conversations.
3. **Day 90**: First pilot engagement ARR booked < $50K, OR retainer attach rate on conversations = 0%.
4. **Month 6**: If services revenue booked < $300K cumulative OR delivery NPS < 40 (signaling we can't actually deliver the productized motion).

**Fallback plan (Rafa's path, but calibrated honestly):**

- **Month 0–2**: Ship Claude-grade Cloud free + Pro ($19) + Team ($49) on Vercel. Launch HN + newsletter + Twitter. Target: **100 paying users at Day 30 ($1,900 MRR)** — using Sofía's honest 2% conversion, not Rafa's 8%. If we miss this, fall back further to "keep ceos-agents as MIT + Claude-grade as free brand asset + advisory income bridge" — honestly, a lifestyle business at $500K–$1M ARR ceiling.
- **Month 3–6**: Ship $29/mo Autopilot add-on (YouTrack + Gitea + Redmine) on top of v6.9.1. Skip the marketplace UI (Rafa's week 4 deliverable) — it's distraction. Target: **$10K MRR Month 6**.
- **Month 7–18**: Pursue inbound enterprise ($499–2K/mo SLA tier). NO outbound. NO SDR. NO SOC2 until $50K MRR (too expensive relative to services-backed path).
- **Realistic Y1 ARR**: $200–400K (Sofía's honest calibration), not Rafa's $600K.
- **Realistic Y3 ceiling**: $1–2M ramen-king plateau.

The fallback is explicitly NOT $10M-optimized. It is survival-optimized. If we end up on the fallback, we tell the CEO honestly: we're running a lifestyle open-source business, not a venture-scale company.

---

## 5. Gate-3 Decision Framework — 5 Questions the CEO MUST Answer

### Q1. "Is this a CEOS corporate initiative with 12–24 month horizon, 5–8 FTE headcount commitment, and regulated-industry BD access — OR is it a solo venture where the user burns personal runway?"

**Why it matters.** The entire recommendation swaps on this single fork. Services-first requires delivery capacity and enterprise sales relationships no solo founder can produce. If it's corporate, the Hybrid wins. If solo, Claude-grade-only fallback.

**How the answer changes the recommendation.** Corporate → Hybrid (services Y1 → SaaS Y2). Solo → Rafa's Claude-grade-only path, with honest $1–2M ARR horizon and no pretense of venture-scale.

**What the user should steer toward.** Corporate. The user's asset base (v6.9.1 plugin, Claude-grade, Asysta, CEOS relationships) is 3–4× more valuable inside a corporate vehicle than solo because services delivery requires team capacity.

---

### Q2. "Does CEOS legally own Claude-grade and the Asysta CEOS NDJSON dataset, and will CEOS grant the new venture exclusive commercial license in writing by day 14?"

**Why it matters.** Phase 2 flags this as `ASM-4 — user must clarify` and Sofía calls it a Gate-3 blocker (Part C.2). Without resolution, Rafa's Week 1 MVP cannot legally ship and Sofía's eval-corpus moat cannot legally be commercialized. Doug's moat collapses without Claude-grade private-eval.

**How the answer changes the recommendation.** Licensed (exclusive commercial, written) → Hybrid or Rafa fallback, both viable. Licensed (non-exclusive or royalty-bearing) → Hybrid still viable but Claude-grade tier becomes less attractive; lean more on services moat. Not licensed → fallback to "ceos-agents plugin only" business, which reduces revenue horizon by 40–60%; we present this to CEO as unacceptable and push for resolution.

**What the user should steer toward.** Exclusive commercial license, written, before day 14. If CEO hesitates, the user should negotiate a 3-year exclusive commercial license with renewal option, rev-share 5–10% to CEOS on Claude-grade-attributable revenue.

---

### Q3. "Is the CEO willing to defer hosted SaaS product launch to month 15 and accept services-dominant P&L in Y1 (lower gross margin, higher human capital intensity), OR does the CEO insist on a product-led P&L shape from day 1?"

**Why it matters.** Doug's model is product-P&L from month 3. Sofía's model is services-P&L until month 15, then hybrid. Corporate boards often resist services mix because services don't trade at SaaS multiples. If the CEO's implicit comp frame is "we want SaaS multiples," the Hybrid is harder to sell internally and we lose the Y1 revenue runway.

**How the answer changes the recommendation.** CEO accepts services-P&L Y1 → Hybrid full-go. CEO demands product-P&L → we'd have to degrade to Doug's model but with Sofía's correction on conversion math, which means Y1 ARR $150–300K instead of $750K, delayed profitability, higher capital burn. I would push back hard: services-P&L Y1 is strictly better because it funds the product build from gross margin.

**What the user should steer toward.** Acceptance of services-P&L Y1 with explicit product-P&L transition commitment by Y3. Pitch: "We buy the moat with services revenue, then transition the margin profile."

---

### Q4. "What is the CEO's risk tolerance for the 'Anthropic ships native X' scenarios (Phase 2 H-probability for Jira/Linear integration and full-pipeline composer, both within 12 months)? Is the CEO willing to bet on first-mover upside, or does the CEO want maximum platform-risk insulation?"

**Why it matters.** Doug's enterprise-open-core has MODERATE–HIGH exposure depending on Jira/Linear expansion decision. Rafa has MODERATE exposure on the free tier. Sofía's services model has structural LOW exposure because Anthropic cannot commoditize human consulting. This is a stomach question as much as a strategy question.

**How the answer changes the recommendation.** High risk tolerance (willing to ride platform-risk for upside) → Doug's model becomes more defensible if the CEO is wrong about niche-only TAM but right about Anthropic not shipping composer within 12 months. Low risk tolerance → Hybrid (services-insulated) is the clear winner. Medium → Hybrid is still best because it gives you Y1 services insulation AND Y2+ product upside.

**What the user should steer toward.** Low-to-medium risk tolerance framing. The CEO should prefer the path that survives all four Phase 2 scenarios, not the path that wins if none of them materialize. Phase 2 gives H probability to two of them within 12 months — ignoring this is gambling, not strategy.

---

### Q5. "Target customer size for Y1 — are we selling to F500 regulated enterprises ($200K+ engagements, 6–9 month sales cycles), mid-market regulated orgs (100–1,000 devs, $75–150K engagements, 60–90 day sales cycles), or solo/SMB Claude Code users ($19–49/mo self-serve)? Pick ONE for Y1."

**Why it matters.** Trying to serve all three simultaneously is the #1 killer of early-stage B2B companies. Each segment needs a different GTM, pricing, legal motion, and team skillset. Rafa solves this by picking solo/SMB (correct for his model). Doug straddles mid-market and enterprise (his model's biggest execution risk per his own §10 Risk 3). Sofía picks mid-market regulated (correct for services model).

**How the answer changes the recommendation.** F500 only → decline; sales cycles too long for a first 90-day plan. Mid-market regulated → **Hybrid is perfectly calibrated**. Solo/SMB → Rafa fallback. Mixed "let's try all three" → reject, this is where startups die.

**What the user should steer toward.** Mid-market regulated (100–1,000 devs, banking/defense/healthcare/EU-strict) for Y1. F500 deferred to Y3 after regulated references accumulated. Solo/SMB monetized via free Claude-grade tier only, no paid self-serve focus until Y2.

---

## 6. The Single Sentence to Say to the CEO

**EN (29 words):**
*"We sell productized regulated-industry AI-agent deployments at $150K today, build the only eval corpus that's seen banking code under audit, and layer hosted SaaS on top by month 15."*

**CZ (povinná, 29 slov):**
*"Prodáváme produktizované nasazení AI agentů do regulovaných odvětví za $150K dnes, stavíme jediný eval korpus, který viděl bankovní kód pod auditem, a v měsíci 15 na to navrstvíme hostovaný SaaS."*

---

## 7. What to Do if CEO Says No (Solo Path)

**Most solo-viable variant: Rafa's Claude-grade Cloud PLG (not Sofía, not Doug).**

Sofía herself concedes: "If the CEO says no and user is solo, recommend Rafa's Claude-grade-only subset as the fallback." Doug's enterprise model is not solo-survivable (SOC2 + AE hiring + 12mo to $1M). Sofía's services model is delivery-capacity-bound (impossible solo). Rafa's model is explicitly designed for solo: ships in 4–6 weeks, ramen-profitable at $15K MRR, self-funded from personal runway.

**Absolute minimum to ship in 30 days:**

1. **Week 1–2**: Claude-grade Cloud free tier live at `claude-grade.sh` (already Vercel-ready, 2 eng-weeks). Public scoreboard + shareable badge + GitHub embed. Launch on HN, Twitter, newsletter.
2. **Week 2–3**: Pro tier ($19/mo) live via Stripe. GitHub Action shipped. "Show HN: We scored every public AGENTS.md repo" thread.
3. **Week 3–4**: Team tier ($49/mo). "State of AGENTS.md" monthly report #1. DM top 50 Claude Code plugin authors offering free Pro for badge embed.

**Day-30 revenue floor (honest, Sofía-calibrated, not Rafa's stretch):**

- **50 paying users × $19 blended = ~$950 MRR** at Day 30 (using Phase 2's 2% conversion rate, not Rafa's 8%)
- **Stretch target: $1,900 MRR** (Rafa's conservative cut = 100 users)
- **Minimum viable = $500 MRR**. Below this, iterate the product (better Pro feature gates, better badge prominence, narrower ICP on indie Claude Code devs) — do NOT pivot to enterprise services without corp backing.

If Day 30 MRR < $500, invalidation triggers: reassess whether the plugin ecosystem has any paid pull. Options: (a) keep ceos-agents MIT as portfolio asset, take a FTE role at another dev-tools company while doing Claude-grade nights-and-weekends, (b) re-approach CEOS with a smaller ask (2 FTEs, not 5), (c) consulting-bridge income while retooling the product.

---

## 8. Risks Ilana Has NOT Resolved

**1. Is the regulated-industry mid-market engineering org *actually* a buyer for AI-agent deployment today, or is this a 2027–2028 category?**
Sofía assumes banking/defense/healthcare have "budget lines for $100–500K AI agent deployment" today. I have no Phase 2 evidence on this — it's a strong assumption based on the general "every enterprise is spending on AI" narrative, which is not the same as "every enterprise is spending on AI-agent deployment with audit logs right now." **The user should validate with 3 qualified BD conversations in week 1–2 BEFORE committing headcount.** If the category is too early, Hybrid fails and we're on Rafa's fallback regardless of CEO willingness.

**2. Can CEOS actually deliver 5–8 senior engineers who can both code Claude Code pipelines AND speak banking/defense compliance?**
Sofía assumes this capability exists or is hireable in month 1–6. Senior dev-tools engineers with regulated-industry delivery experience are a narrow talent pool — maybe 2,000 people globally, heavily concentrated in big-consulting (Accenture, Deloitte) at $250–400K comp. CEOS may have this internally via consulting DNA; may not. **This is a capability audit question the CEO must answer, not assume.**

**3. Is SOC2 Type I by month 12 enough, or will regulated customers demand Type II + FedRAMP + HITRUST + PCI by month 6?**
Sofía glosses "SOC2 Type I kickoff month 12" but regulated-mid-market procurement sometimes demands more. The actual requirement is buyer-specific — defense may require FedRAMP Moderate (18–24 month audit, $500K–$2M cost), fintech may require SOC2 + PCI + SOX controls, healthcare may require HIPAA + HITRUST. **If we stumble into a procurement process that demands FedRAMP, the 15-month SaaS launch timeline slips to 24+ months** and the Hybrid's moat-building argument weakens. Need to scope regulatory floor per target vertical in week 2–3.

**4. Does Claude-grade's $19–49 individual PLG tier cannibalize enterprise deals, or does it feed them?**
Both Sofía and Rafa assume Claude-grade public + Pro tier is lead-gen for higher tiers. But enterprise procurement sometimes *disqualifies* vendors with "consumer-feeling" price points ("if it's $19/mo, it can't be serious enterprise tooling"). I've seen this reverse-signal kill deals. Mitigation: Claude-grade Enterprise tier branded separately ($499–2K/mo) with no visible association to the $19 tier on the enterprise-facing website. Need to validate by week 4 with a regulated-industry buyer conversation.

**5. Is the author's (user's) personal bandwidth actually sufficient to both run services Y1 AND ship SaaS alpha by month 12?**
Sofía assumes founder is CEO-level strategist + services-delivery-leader + product-engineering-director simultaneously. That's a lot. The real failure mode: founder gets absorbed in services delivery (because engagements ship fast and pay immediately), SaaS product engineering starves, SaaS never ships, company plateaus at $8–10M services revenue with no product multiple. **Mitigation the user must personally commit to: hire a VP Product or senior product engineer by month 6, firewalled from services delivery.** If CEO won't fund this role, Hybrid degrades to Sofía's pure-services plan which plateaus earlier.

---

**End of Ilana Grischkowsky synthesis. ~3,500 words.**
