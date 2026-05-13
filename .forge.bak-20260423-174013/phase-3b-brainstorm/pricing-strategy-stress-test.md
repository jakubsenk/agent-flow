# Pricing Strategy Stress Test — ceos-agents Ecosystem Bundle

**Author:** Colin Asagiri-Ellesmere (pricing consultant, ex-Datadog Head of Pricing, ex-Retool VP Monetization)
**Date:** 2026-04-23
**Input files read:** `final.md`, `answers-partB.md`, `market-sizing.md`
**Scope:** Replace the "5 runs/month" placeholder table with a unit-economics-grounded pricing model.

---

## Preamble: what I refuse to do

I will not endorse any price that lacks a cost-per-unit model. The previous "5 composer runs/month" proposal is unshippable because a single composer "run" can vary 40× in API cost depending on whether it's a typo fix or a 6-agent pipeline that does triage → code-analyst → fixer↔reviewer (5 iters) → test-engineer → publisher on a multi-file feature. You cannot price a unit you cannot meter. Everything below starts from **tokens**, not runs, and converts to user-visible quotas only at the last step.

---

## 1. Unit cost estimation — what does 1 composer run cost us?

### Assumptions (explicit)

I use public Anthropic API prices as of 2026-04 (stated for Claude Sonnet 4.5 and Opus 4.x tiers; these move, so the model must be re-run quarterly):

| Model | Input $/M tokens | Output $/M tokens | Cached input $/M |
|---|---|---|---|
| Claude Opus 4.x | $15 | $75 | $1.50 |
| Claude Sonnet 4.5 | $3 | $15 | $0.30 |
| Claude Haiku | $0.80 | $4 | $0.08 |

**Caveat:** these are retail API prices. Actual ceos-agents COGS will be 30–60% lower with aggressive prompt caching on the CLAUDE.md + agent-definition tail (which is ~25k stable tokens across all agents), but I will model retail first and show the cached variant separately.

**Token profile per ceos-agents pipeline stage** (derived from the 21 agents × model assignments in CLAUDE.md — opus for fixer/reviewer/architect, sonnet for analysts, haiku for publisher/rollback):

| Scenario | Stages executed | Sonnet tokens (in+out) | Opus tokens (in+out) | Haiku tokens |
|---|---|---|---|---|
| **Small** (one-file bug, AC=2, complexity XS) | triage → code-analyst → fixer(1 iter) → reviewer(1) → test-engineer → publisher | 60k in / 10k out | 40k in / 8k out | 5k in / 1k out |
| **Medium** (multi-file feature, AC=4, complexity M, 3 fixer-reviewer iters) | spec-analyst → architect → fixer↔reviewer (3 iters) → test-engineer → e2e → acceptance-gate → publisher | 250k in / 40k out | 350k in / 70k out | 10k in / 2k out |
| **Large** (scaffold + new app build, spec + architect + 5 fixer iters + e2e + browser-verifier) | spec-writer↔spec-reviewer → scaffolder → architect → fixer↔reviewer (5 iters) → test-engineer → e2e → browser-verifier | 900k in / 150k out | 1.2M in / 250k out | 20k in / 4k out |

**Cost math (retail, no caching):**

| Scenario | Sonnet cost | Opus cost | Haiku cost | **Total $/run (retail)** | **With 50% cache savings** |
|---|---|---|---|---|---|
| Small | 60k×$3/M + 10k×$15/M = **$0.33** | 40k×$15/M + 8k×$75/M = **$1.20** | 5k×$0.80/M + 1k×$4/M = **$0.008** | **$1.54** | **$0.77** |
| Medium | 250k×$3/M + 40k×$15/M = **$1.35** | 350k×$15/M + 70k×$75/M = **$10.50** | 10k×$0.80/M + 2k×$4/M = **$0.016** | **$11.87** | **$5.94** |
| Large | 900k×$3/M + 150k×$15/M = **$4.95** | 1.2M×$15/M + 250k×$75/M = **$36.75** | 20k×$0.80/M + 4k×$4/M = **$0.032** | **$41.73** | **$20.87** |

**The anchor:** a **medium run costs us ~$6–$12 at retail**, a **large run costs us ~$20–$42**. A "5 runs/month" free tier — if the user does medium or large work — costs us **$30–$210/user/month in API alone**. That is catastrophic for any free tier above ~100 users without a BYO key option.

> **ASSUMPTION flag:** these token profiles are my best estimates from the CLAUDE.md architecture. They MUST be measured in pilot before committing to any hosted tier. See §10 risks.

---

## 2. The BYO API key mechanic — PRO or CON

### Arguments FOR BYO key

- **Eliminates our COGS risk.** User pays Anthropic directly; we charge only for orchestration, storage, audit, SSO, collaboration.
- **Matches market norms for dev-tools.** Cursor allows BYO fallback. Aider is default BYO. Cline is BYO. Roo Code is BYO. The prosumer expectation for an OSS-adjacent plugin is that BYO is available.
- **Enables prosumers and power users.** A user with a Claude Code Max plan ($200/mo, unlimited) already has infinite tokens. Forcing them onto our API reseller model is user-hostile.
- **Regulatory fit.** Enterprise customers with existing Anthropic enterprise agreements (volume discounts, zero-retention clauses, on-prem region control) will refuse to proxy through us.

### Arguments AGAINST BYO key

- **Fragments user base economics.** A user on BYO gives us zero marginal revenue per run; we rely on subscription only for the orchestration layer.
- **Harder to optimize.** If we can't see tokens flow, we can't route Haiku for trivial stages. Our caching optimizations only benefit hosted users.
- **Support asymmetry.** "Why did my run fail?" — with BYO we can't diagnose without their key. Creates two-class support experience.
- **Rate-limit blame.** When BYO user hits Anthropic rate limits, they blame us.

### Precedents (from research)

- **Cursor:** hosted default, BYO fallback in Settings. Most users stay on hosted.
- **Aider:** pure BYO. OSS-native.
- **Cline / Roo Code:** BYO-only, OSS extensions.
- **Replit Agent:** NOT BYO — bundled.
- **Lovable:** NOT BYO — bundled.
- **Devin:** NOT BYO — uses ACU pricing against their own infra.

**Observation:** BYO-only products stay small-revenue OSS tools (Aider, Cline). Hosted-default products capture enterprise (Cursor, Replit, Devin). **BYO as a fallback is the dominant winning pattern.**

### Recommendation: **YES — BYO key supported, but NOT the default path.**

Structure:
- **Hosted runtime (default):** we pay Anthropic, user pays us a subscription + usage. This is where gross margin lives.
- **BYO key (opt-in):** user provides Anthropic API key; we charge a flat orchestration fee (not metered). Unlimited user-side tokens.
- **Enterprise Anthropic account:** enterprise customers point ceos-agents at their own Bedrock / Anthropic enterprise endpoint. Table-stakes for any enterprise deal > $25k ACV.

This lets us capture prosumers (BYO-fee) AND enterprise (BYO-mandate) AND PLG freemium (hosted, metered). Not locking users out of BYO is the difference between OSS goodwill (we're published MIT on `example.invalid`) and a cash-grab image.

---

## 3. Free-tier economics — what we can afford

### The math for a hosted free tier

Assume 10,000 free users. Unknown: average runs/month and scenario mix. Let's model three behavior profiles.

| Profile | Avg runs/mo | Mix (S/M/L) | Avg $/run (retail) | $/user/mo | 10k users monthly burn |
|---|---|---|---|---|---|
| Casual tinkerer | 3 | 80% / 20% / 0% | $2.14 | $6.42 | $64,200 |
| Active prosumer | 10 | 50% / 40% / 10% | $8.72 | $87.20 | $872,000 |
| Power user (abusive) | 30 | 30% / 40% / 30% | $17.80 | $534 | $5.3M |

**At retail API prices, a 10k-user free tier with even casual usage burns $64k/month = $770k/year.** To break even at 1% free→paid conversion and $19/mo ARPU:

`Revenue = 10,000 × 1% × $19 × 12 = $22,800/year`
`Cost = $770k/year`
`Profitability ratio: 0.03` — catastrophic.

To reach break-even at 1% conversion with casual usage, we need ARPU × conversion × users × 12 ≥ burn:
`Required ARPU at 1% conversion = $770k / (10,000 × 0.01 × 12) = $6,400/year` — nonsensical.

Flip it: **at $19/mo ARPU and 1% conversion, we can afford a maximum free-tier burn of $0.19/user/mo retail cost.** That's **ONE small run per user per month** at retail, or **TWO small runs** with 50% caching.

### Free-tier proposal

The free tier must be structured so the average free user costs us <$0.20/mo. Three options:

- **Option A (hosted, metered, tiny):** 1 small-equivalent run/month (capped at 80k Sonnet + 40k Opus tokens). Any overage forces BYO or upgrade. **Brutal UX, zero prosumer appeal.**
- **Option B (BYO-required for composer, hosted for non-composer):** free tier gets unlimited browse/publish/context-viz/tracker+SC integration + **Claude-grade evals (our compute, but ~$0.01/eval)**. Composer pipelines require BYO key or paid tier. **This is the winner.**
- **Option C (hosted, generous — loss leader):** 5 small-equivalent runs/month, eat the ~$4/user/mo burn, treat as marketing spend. Only viable if we raise capital. Not recommended bootstrapped.

**Recommended: Option B.** Justification:
- Free users get the plugin's full non-compute value (marketplace browse, publish, CLAUDE.md context viz, tracker+SC glue, Claude-grade eval read-only on public AGENTS.md corpus).
- Free composer runs are **BYO-only** — user pays Anthropic directly. Our burn = $0/run for composer.
- Free eval calls are capped at 20/month per user (our cost ~$0.20/eval amortized = $4/user/month — we can afford this because evals are the moat-building data).
- Conversion trigger: user wants composer without handling their own key → Pro. User wants team sharing → Team. Crystal-clear gate.

**Supported conversion-rate economics:** at 0.5% free→paid conversion (conservative from Q-C4), 10k free users → 50 paid × $19 × 12 = $11,400/year. Our free-tier burn ≈ 10k × $4/mo = $480k/year. **Still loss-making on free-tier alone**, BUT Option B removes composer COGS, so free-tier burn drops to ~$480k/year (eval-only). At 2% conversion → $45,600/year. Still not break-even on free tier alone, but **acceptable as CAC** if we model it as marketing.

**To make Option B free tier profitable alone**: cap evals at 5/month (~$1/user/mo burn = $120k/yr on 10k users) and require the PR submission feature to be gated to Pro. At 1% conversion → $22,800 from paid, ~$120k burn. Still loss-making. **Conclusion: free tier is CAC, not profit. Budget it accordingly.**

---

## 4. Pro tier mechanics ($19 is tentative — stress-test it)

### Options evaluated

**Option P1: $19/mo with token pool (500k Sonnet + 100k Opus included, then BYO or pay-per-token)**
- At retail cost: 500k Sonnet = $1.50, 100k Opus = $1.50 (input) + ~$7.50 (output assuming 20% output) ≈ $10.50
- Our COGS per Pro user: ~$10.50 retail, $5.25 with caching
- Gross margin: ($19 − $5.25) / $19 = **72%** — solid SaaS margin
- Problem: 500k tokens = maybe 2 medium runs or 1 large run. Feels stingy next to Cursor Pro ($20 "unlimited" fast completions).

**Option P2: $19/mo for N runs, then pay-per-run overage**
- If N=20 small-equivalent runs: our cost = 20 × $0.77 cached = $15.40, margin = 19%. **Too thin.**
- If N=20 mixed (mostly small, some medium): cost = 20 × $3 avg = $60. **Negative margin.**
- Problem: user mix is unknown; per-run pricing is user-hostile (they avoid running).

**Option P3: $29/mo with 1M Sonnet + 200k Opus token pool**
- Cost: ~$21 retail, ~$10.50 cached; margin ~64% cached
- Headroom for 4–5 medium runs/month or 1 large + 3 mediums. Feels generous.
- Psychological gap vs. Cursor Pro ($20) and Devin Core ($20 + ACU overage). **$29 is defensible if we ship better automation depth.**

**Option P4: $19/mo for Pro (BYO-only, unlimited) — orchestration subscription**
- User provides Anthropic key; we charge for the software layer (private namespace, private eval, unlimited composer, pipeline history, webhook, state dashboards)
- Our COGS: ~$0 API, ~$2/user/mo infra
- Gross margin: ($19 − $2) / $19 = **89%**
- This matches Aider/Cline model but with enterprise-grade orchestration + tracker integrations. **Clean PLG subscription.**

### Recommendation: **Dual-SKU Pro — $19 BYO-only, $29 Hosted**

| SKU | Price | Compute | Included |
|---|---|---|---|
| **Pro BYO** | $19/mo | User's Anthropic key | Unlimited composer · private eval · private namespace · pipeline history · webhook · priority queue |
| **Pro Hosted** | $29/mo | Our compute | Everything in Pro BYO + 1M Sonnet + 200k Opus token pool/month (enough for ~4 medium runs), $0.15/1k Sonnet overage, $0.50/1k Opus overage |

**Why two SKUs:** segmentation on WTP-for-convenience. Claude Code Max users ($200/mo) and enterprise Anthropic users already have tokens — they take Pro BYO for $19. Prosumers who don't want to handle keys take Pro Hosted for $29. **Almost everyone above the free tier converts to one or the other.**

**Margin math:**
- Pro BYO: 89% gross margin, no COGS risk
- Pro Hosted: 64% cached / 24% retail worst case. At blended 50% cached, ~55% gross margin. If a Pro Hosted user regularly exceeds pool, they either (a) pay overage (accretive) or (b) migrate to Pro BYO.

**Expected conversion from Free:** 1.0–2.5% (research anchors Elastic 1%, PostHog 2%, dbt 10%). Bet on 1.5%. Of those, 60% take Pro Hosted (convenience), 40% take Pro BYO (prosumer). **Blended Pro ARPU ≈ $25/mo = $300/year.**

---

## 5. Team tier ($49/seat tentative — stress-test it)

### Minimum seat count

Claude's "no floor" proposal undervalues the setup cost. Recommendation: **minimum 3 seats.** Rationale:
- Below 3, collaboration features (shared namespace, shared eval, pipeline history aggregation) add minimal value.
- 3-seat floor aligns with Notion Team ($10 × 3), Linear Team ($8 × 3), and removes "one founder buying Team pretending to have a team" edge case.
- Implies minimum Team billing = 3 × $49 = $147/mo.

### Volume discounts

- 3–9 seats: $49/seat/mo (list)
- 10–24 seats: $45/seat/mo (8% discount)
- 25–49 seats: $42/seat/mo (14% discount)
- 50+ seats: "talk to sales" — gateway to Enterprise negotiation

### Hosted vs. BYO for Team

Team tier must be **hosted by default** with BYO available. Why:
- Shared runs need shared credentials management; "each seat has their own Anthropic key" is operationally hell.
- Team BYO is available as "enterprise key mode" where the workspace admin configures ONE enterprise Anthropic key for all seats. Single credential, no per-seat fragmentation.

### Token pool (Team Hosted)

Shared pool, not per-seat: 3M Sonnet + 500k Opus × seat count per month. Seats pool their budget; active seats benefit from inactive seats' allocation. Overage at same rates as Pro Hosted.

### Margin math

- 3-seat Team ($147/mo) on hosted: COGS ~$30–45/mo (3 pools consumed at 50% caching × 50% utilization). Margin ~70%.
- 20-seat Team ($900/mo) on hosted: COGS ~$150/mo assuming ~60% utilization. Margin ~83%.

### Conversion Team → Enterprise

Triggers:
- **Headcount**: crossing 50 seats OR 6+ seats in a regulated industry (fintech, healthtech, defense)
- **Procurement signal**: MSA request, SOC2 requirement, legal review
- **Feature demand**: SSO/SAML/SCIM beyond Google OAuth, audit logs > 90 days, on-prem deployment, regional data residency, custom SLA

Expected conversion Free→Team: 0.2% (teams convert slower than individuals). Expected Pro→Team: 5% annually (as solo users form teams or onboard collaborators).

---

## 6. Enterprise floor — what's the minimum ACV

### Enterprise cost-to-serve (solo-founder reality)

- Sales cycle: 4–8 weeks (benchmark: dev-tools pre-IPO)
- SE time: 10–20 hours pre-sale demos + POC support
- Legal + MSA: 4–8 hours (first time; template thereafter)
- CSM: 1–2 hours/month ongoing
- Fully loaded cost for solo-founder closing 1 enterprise deal: **~40 hours or ~$8k in opportunity cost**

### Benchmarks

- GitHub Enterprise: $21/user/mo = $252/user/yr; typical floor deal ~100 seats = $25k ACV
- GitLab Ultimate: $99/user/yr; typical floor ~50 seats = $5k ACV (but Ultimate cross-sells to $50k+)
- HashiCorp Vault Enterprise: ~$15k ACV floor
- Grafana Enterprise: ~$57k ACV average at scale (per Q-B5 research — $400M ARR / 7k customers if 10% enterprise-support → $57k)
- Metabase Pro: $500/mo = $6k/yr minimum
- Devin Enterprise: custom, assumed $30k+ ACV floor

### ceos-agents Enterprise floor recommendation: **$25,000 ACV minimum**

Rationale:
- Below $25k, the deal does not cover solo-founder sales cost + ongoing CSM allocation.
- $25k aligns with "mid-market" rather than "small-team Team tier bleed."
- Enables $25k entry-level with $50–150k expansion targets on dedicated deployment / custom SLA / compliance add-ons.

**Enterprise SKU structure:**
- **Enterprise Starter**: $25k/yr — SSO/SAML/SCIM, 99.5% SLA, audit log export, shared tenant, up to 25 seats, standard support
- **Enterprise**: $50–150k/yr — everything above + on-prem/Bedrock deployment, custom agent development hours, 99.9% SLA, dedicated CSM, priority roadmap input
- **Enterprise + Regulated**: $150k+/yr — SOC2 + HIPAA + data residency + custom deployment region + dedicated instance

**Target Y2 enterprise mix:** 5 Starter deals ($125k) + 2 Enterprise ($150k) = $275k ARR. Conservative given solo-founder capacity.

---

## 7. Marketplace monetization — take-rate or not

### Take-rate viability

Research is unambiguous: **zero take-rate is the Anthropic-likely steady state** (Q-C5, CONFIRMED HIGH confidence). A ceos-agents marketplace that charges 15–20% when Anthropic charges 0% is dead.

### Weaker monetization variants

**Featured listings / sponsored placement:**
- Chrome Web Store: does NOT run paid featured listings (curated by Google). **Precedent against.**
- Shopify App Store: limited ad placements, not core revenue.
- JetBrains Marketplace: no featured ads, relies on take-rate.
- **Verdict:** featured-listing revenue is a $0–$500k/year max business at our scale. Not worth the product complexity.

**Private-skill commerce (dev sells proprietary skill, we take 10%):**
- Analogous to Unity Asset Store (~$100M/yr at peak, but Unity has 4M dev audience with game-specific purchase intent).
- For ceos-agents, estimated volume: at 50k Claude Code seats (mid-range), 10% interested in private skills, 2% purchasing, $50 avg spend = 50k × 10% × 2% × $50 = $5k/year in GMV × 10% take-rate = **$500/year.**
- Not a business. Even upside scenario (500k seats, 5% purchasing, $100 avg spend) = $250k GMV × 10% = **$25k/year.** Insignificant.

### Conclusion: **Marketplace is distribution, NOT revenue. Commit.**

The marketplace's job is:
1. **Acquisition channel** — free users land here browsing skills, convert to paid when they want to publish privately / eval their skills / run composer
2. **Moat-builder** — accumulated public-skill eval scores = Claude-grade benchmark corpus
3. **Defensive** — if Anthropic opens paid marketplace later, we already have the audience and billing infra

**No take-rate. No featured listings. No commerce fees.** Private skills hosted on Team/Enterprise plans (gated by subscription, not per-skill transactions).

---

## 8. Tracker + source-control monetization

### The options

- **Option A: Free forever** — data moat + distribution wedge
- **Option B: Free for 5-seat teams, paid for 6+** — Slack-style
- **Option C: Free self-hosted, paid hosted** — GitLab-style
- **Option D: Paid from day 1** — small fee, agent-native differentiator

### Analysis

Tracker + SC integration is the **highest-friction integration** in the plugin (21 agents × tracker-specific adapters × SC-specific commit/PR logic). It's also ceos-agents' moat per Q-A3 research: the niche trackers (YouTrack, Redmine, Gitea) are what Anthropic won't build natively.

**Option A is correct.** Reasoning:
- Making tracker integration paid cripples distribution. A plugin that asks "pay $X before you can use the thing it does" in an OSS ecosystem is DOA.
- Tracker integration is the wedge: once a team integrates ceos-agents with their YouTrack/Redmine, the switching cost is high and they convert to Team/Enterprise for scale.
- The data moat: we accumulate pipeline metadata across 100+ tracker integrations, which informs eval + agent improvements.

**But with nuance:** Enterprise-only tracker features SHOULD be paid:
- Multi-tracker federation (one workspace, issues from Jira + Linear + Gitea + Redmine)
- Custom-field sync and bidirectional workflow state mirroring
- Sprint/epic roll-up across projects
- Cross-tracker analytics dashboards

**Recommendation: Option A (free base tracker+SC integration) + paid federation/analytics layer in Team/Enterprise.** This keeps the wedge sharp and puts monetization at the collaboration layer where WTP is real.

---

## 9. Final pricing table — my commit

| Tier | Price | What's Included | Upgrade Trigger | Gross Margin | Expected Conversion from Tier Below |
|---|---|---|---|---|---|
| **Free** | $0 | Plugin install · marketplace browse/publish public · Claude-grade public eval (20/mo cap) · CLAUDE.md context viz · tracker+SC base integration (single tracker) · **BYO-key composer (unlimited, user pays Anthropic)** · 0 hosted composer runs | Wants hosted composer OR private namespace OR private eval | N/A (CAC) | — |
| **Pro BYO** | $19/mo | Everything in Free + unlimited hosted composer (user provides key) · private namespace · private eval · pipeline history · webhooks · priority queue · private skill publish | Wants shared team workspace OR 3+ collaborators | **89%** | 0.8% of Free |
| **Pro Hosted** | $29/mo | Everything in Pro BYO + hosted compute (1M Sonnet + 200k Opus token pool/mo) · overage at $0.15/1k Sonnet + $0.50/1k Opus | Pool exceeded 3+ months OR wants team features | **55–70%** (caching-dependent) | 0.7% of Free (1.5% combined with BYO) |
| **Team** | $49/seat/mo (3-seat min; tiered discounts 10+ / 25+) | Shared private marketplace · team dashboard · shared token pool (3M Sonnet + 500k Opus × seats/mo) · Google SSO · pipeline history aggregation · multi-tracker federation (2 trackers) | Needs SSO/SAML/SCIM OR audit logs >90d OR 50+ seats OR procurement | **70–83%** | 5% of Pro annually; 0.2% of Free |
| **Enterprise Starter** | $25k/yr floor | SAML/SCIM SSO · 99.5% SLA · 90d+ audit export · up to 25 seats · multi-tracker federation (unlimited) · standard support · single-tenant option | Needs on-prem/Bedrock OR custom agents OR 99.9% SLA OR regulated industry | **~80%** (labor-heavy) | 10% of mid-to-large Team (20+ seats) |
| **Enterprise** | $50–150k/yr | Everything in Starter + on-prem or Bedrock deployment · custom agent development (40 hrs/yr) · 99.9% SLA · dedicated CSM · priority roadmap · custom deployment region | Needs SOC2+HIPAA OR dedicated instance OR multi-region | **65–75%** (heavy services mix) | 15% of Enterprise Starter expansion |
| **Enterprise + Regulated** | $150k+/yr | Everything in Enterprise + SOC2 + HIPAA + data residency + dedicated instance + custom SLA negotiable | — | **60%** | — |

**Blended targets (Y2):**
- 8,000 Free users (CAC)
- 100 Pro (BYO + Hosted mix) × $25 blended × 12 = $30k
- 20 Team averaging 8 seats × $47 × 12 = $90k
- 5 Enterprise Starter + 2 Enterprise = $125k + $150k = $275k
- **Y2 ARR target: ~$400k**

This is conservative and more realistic than `market-sizing.md` Stream-1 base ($3.6M Y1), which required 150 orgs × 40 seats. My Y2 needs only 25 Team + 7 Enterprise to hit $400k.

---

## 10. Self-identified risks

### Risk 1: Token profiles are guesses, not measurements

Every price I computed starts from token estimates of "medium = 250k Sonnet + 350k Opus." This is my best inference from the 21-agent architecture, NOT measured. If actual medium runs use 2× more Opus (because reviewer loops take 5 iterations in practice, not 3), Pro Hosted gross margin drops from 55% to 20%. **This MUST be measured in the first 30 days of any pilot** via a token-telemetry hook in the pipeline. Do not ship hosted tier without this data.

### Risk 2: Anthropic prices move against us

If Anthropic drops Sonnet to $1/M input / $5/M output (aggressive competitive move vs. GPT-5), our COGS halves and our margins balloon — fine. But if Anthropic raises Opus pricing or deprecates Opus 4.x without a price-equivalent replacement, our Pro Hosted tier breaks immediately. **Mitigation:** all hosted tiers need a quarterly repricing clause in ToS, AND BYO is always available as the escape valve. This is also why dual-SKU Pro matters — Pro BYO is resilient to any Anthropic pricing move.

### Risk 3: Free-tier abuse via sockpuppet accounts

Even with Option B (composer BYO-only, eval hosted at 20/mo cap), a motivated attacker can create 100 free accounts and consume 2,000 free evals/month (= $400 in our API burn) for competitive benchmarking. At 10k free users, sockpuppet abuse realistically accounts for 5–15% of users. **Mitigations:** email-domain deduplication, rate-limit free-eval by IP, require GitHub OAuth (raises cost of sockpuppet creation), put public-corpus evals behind a cache (same skill evaluated twice = served from cache, $0 additional cost). Even so, assume 10% free-tier cost inflation from abuse.

---

**End of stress test.** Return message follows separately.
