# Ecosystem Spec Synthesis — ceos-agents Public Release

**Author:** Ilana Grischkowsky (independent strategy advisor, ex-McKinsey TMT partner)
**Date:** 2026-04-23 (forge-2026-04-23-001 Phase 3b synthesis)
**Scope:** Reconcile the three Phase 3b drafters (Lena Hofstätter / Product Design, Colin Asagiri-Ellesmere / Pricing, Dr. Aravinda Reyes-Chowdhary / Architecture) into ONE committed input for Phase 4 spec writing.
**Status:** This supersedes my earlier off-target `brainstorm-judge-synthesis.md`. Scope is **ecosystem product-packaging + pricing + architecture for the ceos-agents plugin public release**, NOT "full VC business-model variants."

---

## 1. Executive headline

We are publishing the ceos-agents plugin (MIT, already shipped v6.9.1) alongside a four-component hosted ecosystem — **Marketplace, Composer, Claude-grade, Context Viz, Tracker+SC** — wired together by the plugin's existing webhook + MCP contracts. The plugin stays free and client-side; the hosted layer monetizes via a **$0 Free / $19 Pro BYO / $29 Pro Hosted / $49-seat Team / $25k+ Enterprise** ladder, with marketplace distribution (no take-rate) and niche-tracker integration as the moat. Execution always runs inside the user's Claude Code session — we never resell Anthropic tokens — so our hosted margins are ~89% on Pro BYO and ~65% on Pro Hosted, not the 20-25% a reseller model would yield. Y2 realistic ARR target: ~$400k (5 Enterprise Starter + 2 Enterprise + 20 Team + 100 Pro).

**EN one-liner for CEO:** *"We publish the plugin free, sell the workspace around it, and let Anthropic's API pay for execution."*

**CZ one-liner pro CEO:** *"Plugin zveřejníme zdarma pod MIT, prodáváme workspace okolo něj — marketplace, kompozer, tracker a skórování — a za LLM běhy platí Anthropic přes uživatelův vlastní Claude Code účet, nikoli my."*

---

## 2. Product anatomy — the 5 components

| # | Component | Purpose (one sentence) | Primary user interaction | Tier availability | Integration points to the other 4 |
|---|---|---|---|---|---|
| 1 | **Plugin (ceos-agents)** | Orchestrates 21 agents inside the user's Claude Code session on their own machine, dispatching skills → agents → git/tracker | Installed locally; invoked via `/ceos-agents:*` slash commands | Free (MIT) | Emits webhooks to Context Viz; pulls signed workflow plans from Composer; reads/writes Tracker via MCP; uses Claude-grade scores to pick agents |
| 2 | **Marketplace (`ceos-agents.com`)** | Catalog + discovery for prompts, skills, agents, and composed workflows; entry point for first-time users | Browse → click tile → parameterized Run button | Free (browse + publish public) · Pro (publish private) · Team (private org namespace) · Enterprise (federation) | Launches Composer via deep-link; pulls Claude-grade scores for every listing; shows Context Viz snapshots on run-detail pages; cross-links to Tracker issues |
| 3 | **Composer** (`/compose/:slug`) | Autonomous run surface — plans a workflow from a prompt and dispatches it to the user's plugin for execution | Click "Run" on a prompt tile; watch live dashboard | Free (2 runs/mo via BYO) · Pro ($19 BYO unlimited / $29 Hosted with token pool) | Hosted planner (~10k tokens/run, WE pay); execution deep-links to plugin; streams progress to Context Viz; commits via SC; files Tracker issue |
| 4 | **Claude-grade** | Deterministic scoring (no LLM) for every marketplace item + post-run pipeline scoring; optional LLM-improve paid flow | Automatic on upload + post-run; badges embeddable anywhere | Free (public eval 20/mo cap) · Pro (private eval + LLM-improve) · Team (shared org rubric) | Every Marketplace listing carries a letter grade + numeric score; Composer uses scores to rank candidate agents during planning; post-run score updates Tracker issue lineage |
| 5 | **Tracker + Source Control** | Agent-native issue store (structured AC + agent lineage + token-budget clock) + extended-git SC layer (agent-signed commits, `refs/notes/ceos-agents`) | Studio tab in the web app; MCP server from the plugin | Free (single tracker, read-only write-back) · Pro (unlimited write) · Team (multi-tracker federation × 2) · Enterprise (federation unlimited + SSO/SCIM) | Issues triggered by Composer auto-filing; agent runs stream lineage here; Claude-grade deltas post on PR merge; Context Viz deep-links into run_id timeline |

**Hard invariant (per Aravinda):** The plugin NEVER calls Marketplace/Composer/Tracker backends directly from agent code. Only via webhooks (outbound) + MCP servers (bidirectional). Offline-against-bare-git contract preserved.

---

## 3. Final pricing table — COMMITTED

Resolving the $19 vs $29 tension: **accept Colin's dual-SKU Pro** — $19 BYO and $29 Hosted are NOT redundant given Aravinda's client-side-execution insight. Here is why, and here is the full table.

**Tension-resolution defense (3-5 sentences):**
Per Aravinda's client-side execution decision, execution runs inside the user's own Claude Code session — we are NOT reselling Anthropic tokens at $29/mo. What $29 Hosted sells is (a) a bounded hosted-planner token pool for the ~10k tokens/run WE do pay, (b) Context Viz persistent WebSocket storage, (c) private Claude-grade eval throughput, (d) priority queue on the planner service, and (e) multi-device Studio session sync. Pro BYO at $19 gives users who bring their own Claude Code Max subscription OR Anthropic enterprise key the same private namespace + eval features without the hosted-planner pool. This segments WTP correctly — prosumers with infinite tokens take $19, convenience-first users take $29 — and preserves a clean 89% margin on BYO and 55-70% margin on Hosted per Colin's math, while avoiding Option A's "what justifies the upgrade?" ambiguity.

| Tier | Price | What unlocks vs. tier below | Gross margin |
|---|---|---|---|
| **Free** | $0 | Plugin (MIT) · marketplace browse + public publish · Claude-grade public eval (20/mo cap) · Context Viz read-only · Tracker+SC single-integration read + auto-fill · **BYO composer: 2 runs/mo from marketplace tiles** | N/A (CAC spend) |
| **Pro BYO** | **$19/mo** | Unlimited composer runs (user provides Anthropic key) · private namespace on marketplace · private Claude-grade eval · pipeline history export · webhooks · private skill/prompt publish · priority queue | **~89%** |
| **Pro Hosted** | **$29/mo** | Everything in Pro BYO + hosted planner pool (effectively unlimited — we pay ~10k tokens/run, cap at 200 runs/mo soft) · Context Viz multi-device sync · PNG/SVG usage-graph export · LLM-improve flow on Claude-grade (private) | **~65% cached / 40% retail worst case** |
| **Team** | **$49/seat/mo** (min 3 seats) | Shared org namespace · Google SSO · team-shared token pool · multi-tracker federation (2 trackers) · pipeline history aggregation · shared Studio + agent-usage policies | **70-83%** |
| **Enterprise Starter** | **$25k/yr floor** | SAML/SCIM SSO · 99.5% SLA · 90d+ audit export · ≤25 seats · unlimited multi-tracker federation · standard support · single-tenant option | ~80% (labor-heavy) |
| **Enterprise** | **$50-150k/yr** | On-prem or Bedrock deployment · 40 hrs/yr custom agent dev · 99.9% SLA · dedicated CSM · priority roadmap · regional data residency | 65-75% |

**BYO API key position (explicit):** BYO is available at every paid tier. Pro BYO is the default for prosumers (Aider/Cline-native mental model). Pro Hosted is the default for convenience-first buyers. Team/Enterprise default to BYO via workspace-level enterprise Anthropic key (ONE credential for all seats, not per-seat).

**Upgrade triggers:**
- Free → Pro BYO/Hosted: quota exhaustion (2 free runs exhausted) OR wants private publish OR private eval
- Pro → Team: 3+ collaborators OR shared Studio need
- Team → Enterprise Starter: SSO/SAML/SCIM OR audit >90d OR 50+ seats OR procurement review
- Enterprise Starter → Enterprise: on-prem/Bedrock OR regulated industry OR custom SLA

---

## 4. User journey — condensed FTUE (12 steps for pitch deck)

Lena's 30-step full flow is correct; here is the 12-step pitch-deck version.

1. **T+0s** — Lands on `ceos-agents.com` from HN/Twitter. Hero: 12s autoplay video + single "Run" button on a prompt tile (`Android calorie tracker`). No signup wall.
2. **T+12s** — Clicks a prompt tile. Detail page shows parameterized form (4 fields, sensible defaults), Claude-grade score (A-, 87/100), est. cost ($0.80), est. runtime (5 min), "Edit raw prompt" option, last 12 reviews.
3. **T+20s** — Tweaks `app_name`. Clicks **Run**.
4. **T+21s** — GitHub OAuth modal ("we'll need GitHub to commit your app"). No email, no password. One click.
5. **T+35s** — Composer view opens. Quota badge top-right: **"2 free composer runs this month. This will use 1."**
6. **T+40s-4m30s** — Live run: progress stepper + Context tab (agent graph lights up) + Log tab + right-rail usage graph (tokens, $, elapsed). At T+180s, one load-bearing-decision banner (`Firebase vs Supabase?`) with 60s timeout.
7. **T+4m30s** — Success: preview URL, GitHub commit link, tracker issue auto-filed. Preview tab auto-opens to running app.
8. **T+5m** — Summary card: "$0.94 consumed from free quota · 1.2M tokens · A- post-run score · Share this run" with a public URL + embeddable badge.
9. **T+7m** — User heads back to catalog, installs second prompt, runs it. Quota hits 2/2 with friendly banner.
10. **T+11m (PAYWALL TRIGGER)** — On the THIRD run attempt, modal appears with THREE paths, never mid-run: **(a) Pro Hosted $29/mo**, **(b) Pro BYO $19/mo** (paste your Anthropic key), **(c) Wait 30 days**. Modal shows "You've used 2 runs, $1.50 infra value consumed — here's what's next."
11. **T+11m30s** — User picks BYO (has Claude Code Max). Two fields: key + verify. Unlimited runs unlocked.
12. **T+24h** — Retention email: "Your Kaloricka app got 3 remixes overnight. Top remix added Apple Health sync. Want to pull their changes?" → viral + retention loop closed.

**Paywall-trigger rule (cardinal):** Never interrupt a run-in-progress with a paywall. Always trigger on the *next* run attempt after quota exhaustion, with BYO as the grace-escape.

---

## 5. Architecture — one paragraph + one diagram

Per Aravinda's load-bearing decision: **federated content plane (marketplace = GitHub-backed registry) + thin hosted control plane (composer planner, Claude-grade, Context Viz ingestion, Tracker metadata) + strictly client-side execution plane (plugin runs inside the user's own Claude Code session)**. The single most important business-model fact in this entire bundle: **we never pay the Anthropic API bill for the user's workflow — their Claude Code subscription does. We only pay ~10k planner tokens per composer run.** This kills 90% of the hosting cost, sidesteps Anthropic's Managed Agents price war, and structurally repositions the economics from "25% margin API reseller" to "65-89% margin SaaS."

```
 Browser ──(1) browse tiles──→ Marketplace (Vercel/Next.js + Neon Postgres)
    │                               │
    │                               └──(2) compose planner (~10k tok, OUR cost)
    │                                      │
    │                               returns workflow plan + Claude-grade scores
    │                                      │
    │<─────────────────────────────────────┘
    │
    │ (3) deep-link claude-code://run?workflow=<signed-jwt-url>
    ▼
 Claude Code session (USER'S MACHINE — execution plane)
    └── ceos-agents plugin dispatches 21 agents
         │
         ├─ webhook (existing v6.8.0 contract) → Context Viz (Vercel + Pusher WS)
         ├─ git push → GitHub / SC wrapper (extended-git, signed commits)
         └─ MCP server call → Tracker (Bun on Fly.io + Neon Postgres)
              │
              └─ webhook back → Marketplace (update ranking, award XP)

 Identity: Clerk (SSO/SCIM ready for Enterprise)
```

---

## 6. MVP week-1 scope (ships-or-doesn't-ship)

Merging Lena's "25 seeded prompts" + Aravinda's MVP dependency graph + Colin's free-tier economics:

**SHIPS week 1:**
- Plugin v6.9.1 (already live, MIT, MCP servers for Tracker + Marketplace published as npm packages)
- Marketplace at `ceos-agents.com`: **25 seeded prompts + 10 agents + 5 composed workflows**, all authored/curated by us, all Claude-grade A- or better. Search + 4 filter chips (type/score/cost/verified). Prompt detail page with parameterized form + "Edit raw" button + auto-fork-to-`/my/prompts`
- Composer for prompts ONLY (skills/agents/workflows dispatch ships v2): stages 1-6, Context tab + Log tab + Preview tab, right-rail real-time usage graph, ONE hardcoded load-bearing intervention heuristic (database choice)
- Claude-grade: pre-run score on detail page + post-run score in summary card + embeddable badges; public eval only (private is Pro)
- GitHub OAuth (Gitea/GitLab deferred to week 3)
- Paywall: 2 free runs/month + Pro BYO ($19) + Pro Hosted ($29) with Stripe. Team + Enterprise NOT live week 1.
- Share URLs for public runs (`/r/{user}/{slug}`) — critical for viral loop
- Landing-page 12s hero video
- Docs: one Getting-started page, one API/BYOK page, one Claude-grade rubric page
- Tracker: READ-ONLY write-back (composer-filed issues visible in Studio; manual create disabled)

**EXPLICITLY NOT week 1** (per Aravinda's architecture phasing):
- Live WebSocket viz (Pusher; ships week 3)
- Skill/Agent direct-dispatch pages
- Mid-run intervention side-chat (only the banner, not interactive)
- Tracker full write path
- SC enrichment views beyond `run_id` badge on commit list
- Agent-signed commits (v2.0, 6-12 months)
- Team tier / SSO / audit log
- Mobile app / standalone `viz.ceos-agents.com` (week 3)
- MCP for BYO deploy targets
- LLM-improve flow on Claude-grade

**The strip-down test:** Week-1 marketing demo is ONE prompt → working Android app → shared URL → embeddable A- badge. That's it. Everything else is "don't-embarrass-us," not "dazzle."

---

## 7. Roadmap — 30 / 90 / 180 days

**30 days post-launch:**
- Claude-grade private eval (Pro tier unlock) — per Colin, this is the clearest Pro-tier value lever after hosted composer runs
- Marketplace author uploads (GitHub OAuth + static analysis gates per Aravinda §5)
- Context Viz MVP reading `pipeline-history.md` (no live WS yet)
- Standalone `viz.ceos-agents.com` as second viral-loop surface
- Skill dispatch from marketplace (install to user's project)
- *Rationale:* unblocks the upload-side viral loop. Revenue target: first 100 Pro conversions ($2.5k MRR blended).

**90 days post-launch:**
- Tracker full write UX (agent-native schema + MCP + web Studio tab)
- Context Viz live WebSocket (Pusher/Ably)
- Composer sandboxed execution option (Vercel Sandbox — Pro convenience feature)
- Human ratings + review flow on marketplace
- Clerk SSO/SCIM enabled — **Team tier launches** at $49/seat/mo, min 3 seats
- *Rationale:* opens Team conversion. Revenue target: 20 Team logos at avg 8 seats = $7.5k MRR ($90k ARR).

**180 days post-launch:**
- Agent direct-dispatch page + Workflow remixing
- Multi-tracker federation (2 trackers in Team; unlimited in Enterprise)
- Agent-signed commits in SC layer
- Enterprise Starter tier launches — SAML/SCIM, 99.5% SLA, 90d audit log
- First 2-3 Enterprise design-partner deals closed
- *Rationale:* proves Y2 $400k ARR path. 5 Enterprise Starter + 2 Enterprise + 20 Team + 100 Pro by month 12.

---

## 8. Platform-risk re-assessment under corrected scope

The four Phase 2 Anthropic-platform scenarios apply DIFFERENTLY to this packaging than to the original Phase 3 variants. Per-scenario response:

| Phase 2 scenario | Probability × horizon | How THIS packaging responds |
|---|---|---|
| Anthropic ships monetized marketplace take-rate | M (30-45%) × 12-24mo | **Structurally neutral.** We already have zero take-rate; our marketplace is distribution, not revenue. If Anthropic ships with 20% take-rate, our free-take-rate position becomes a differentiator, not a threat. |
| Anthropic ships native Jira + Linear integration | **H (60-70%) × 12mo** | **Structurally better positioned than Phase 3 variants.** We monetize on YouTrack/Redmine/Gitea niche-tracker federation + SSO/SCIM + enterprise audit — none of which Anthropic will ship natively. Our Jira/Linear integration is free-tier and lives alongside theirs. |
| Anthropic ships native AGENTS.md eval | M (30-45%) × 12-24mo | **Claude-grade free-tier becomes wallpaper; Claude-grade LLM-improve (paid) survives.** The basic score is commoditized in 12-24mo — we accept this and pivot the paid value to LLM-driven improvement suggestions + private rubrics + benchmark percentiles. |
| Anthropic ships full-pipeline autonomous composer | **H (65-75%) × 12mo** | **This is the real exposure.** If Anthropic ships a hosted planner/composer at <$10/mo bundled in Claude Code Pro, our $29 Hosted Pro tier collapses. Mitigation: (a) Pro BYO at $19 survives because it sells orchestration depth + tracker federation + private namespace, not the planner itself; (b) our composer's USP becomes "composes across 21 specialized agents + niche trackers + structured AC," not "runs an autonomous workflow." If the Anthropic composer is generic, ours stays defensible. If it ships niche-tracker federation too (LOW probability per Phase 2), we are in trouble. |

**Bottom line:** Client-side execution + niche-tracker moat + zero-take-rate marketplace = structurally better against 3 of 4 Phase 2 risks. The composer-threat is the one we must watch actively.

---

## 9. The 3 numbers that MUST be validated in first 60 days

Per Colin's self-identified pricing risk + Lena's FTUE + the Phase 2 data gaps:

1. **Actual token profile per composer run** (Colin's Risk 1, explicit ASSUMPTION flag): medium runs are estimated at 250k Sonnet + 350k Opus based on the 21-agent architecture. If actual is 2× on Opus (because reviewer iterations run 5 in practice, not 3), Pro Hosted margin drops from 65% → 20%. **Measurement:** instrument the first 100 Pro Hosted runs with per-stage token telemetry. Re-price if measurements diverge >30%.

2. **Free-to-paid conversion rate** (anchored by Phase 2 at 0.5-3%, Colin is betting 1.5%): measure at day 30, 60, 90. Below 0.8% sustained → restructure free tier (likely cut to 1 free run/mo or gate private-publish behind Pro earlier). Above 2.5% → consider raising free-tier to 3 runs/mo to accelerate top-of-funnel.

3. **FTUE paywall-trigger timing vs. aha-moment** (Lena's UX risk): when does the free user hit the cap relative to their first shared URL / first "this worked" moment? **Too early** (cap hits before the A- badge emits) → 70% dropoff at paywall. **Too late** (cap hits after user has already given up interest) → same 70% dropoff. Target: the paywall should trigger on the *third run attempt* **after** the user has shared at least one public URL. Measure: time-to-first-share, time-to-quota-exhaustion, delta between them.

---

## 10. CEO-pitch one-pager outline

What the CEO needs to hear, in order:

- **(a) What we're publishing:** ceos-agents v6.9.1 (MIT, already shipped) + a 4-component hosted ecosystem (Marketplace, Composer, Claude-grade, Tracker+SC).
- **(b) What it bundles:** one plugin + one web workspace at `ceos-agents.com`. Single login (Clerk). Composer runs client-side in the user's Claude Code session, so we never resell Anthropic tokens.
- **(c) Pricing:** $0 Free → $19 Pro BYO / $29 Pro Hosted → $49/seat Team (min 3) → $25k+/yr Enterprise. Simple ladder, BYO escape valve at every tier, zero marketplace take-rate.
- **(d) Who pays:** 100 Pro ($300/yr) + 20 Team (8 seats × $47) + 5 Enterprise Starter ($25k) + 2 Enterprise ($150k) = Y2 target ~$400k ARR (conservative; Colin's math).
- **(e) Y1 revenue target:** $100-150k (first 40-60 Pro + 5 Team + 1 Enterprise Starter) — low to let the FTUE + viral loop compound.
- **(f) Resource ask from CEO:** 6 weeks of founder focus + ~$40k infra/tooling (Vercel Pro, Fly.io, Clerk, Pusher, Stripe) + ~$20k seed content (25 prompts + 10 agents + 5 workflows all authored to A- Claude-grade) + hold on all other CEOS initiatives during week 1-4 shipping sprint.
- **(g) Fallback if CEO says no:** ship only the Marketplace (week 1) + Claude-grade free badge — 30-60 day revenue pilot per Phase 2 — and defer Composer/Tracker/Context-Viz to a formal capital raise. Minimum-viable public release preserves the OSS goodwill either way because the plugin is already MIT.

---

## 11. Phase 4 writing instructions

Phase 4 spec writer should produce exactly these 12 deliverables:

1. **Full product spec per component** (5 specs, EARS-style requirements, 30-50 REQs each):
   - Plugin (delta spec — what changes vs. v6.9.1 to support marketplace/composer integration)
   - Marketplace (full spec: catalog, search, upload, review, auth, billing)
   - Composer (full spec: planner service, deep-link handoff, webhook ingestion, intervention banner)
   - Claude-grade (full spec: deterministic rubric, LLM-improve paid flow, embed badges, public/private eval)
   - Tracker+SC (full spec: agent-native schema, MCP server, SC git-wrapper, signed-commit deferred)
2. **Public pricing page copy** (EN + CZ, ~800 words each, with FAQ covering BYO, refunds, overage, cancellation, team billing)
3. **Launch checklist for week 1** (chronological, owner-assigned, with go/no-go gates per Aravinda's MVP dependency graph)
4. **10-slide CEO deck with Czech speaker notes** (following §10 outline; include one slide on platform-risk posture per §8)
5. **Technical architecture diagram** (detailed — expand Aravinda's diagram to include Clerk auth flow, JWT ES256 signing, Vercel Blob content CDN, Neon Postgres schemas, Fly.io region topology)
6. **Security + abuse-prevention policy for marketplace** (per Aravinda §5: static analysis gates, safety-rubric scoring, featured-tier requirements, incident response playbook, 14-pattern credential scan reuse)
7. **Seed-content production brief** (25 prompts + 10 agents + 5 workflows — what each covers, target user persona, Claude-grade A- acceptance criteria, author assignments, deadline)
8. **FTUE analytics + measurement plan** (instrument the 3 validation numbers from §9: token-per-run telemetry, conversion funnel, paywall-trigger-vs-aha timing)
9. **Token-telemetry instrumentation spec** (per Colin's Risk 1 — how we measure actual run costs during first 100 Pro Hosted runs; what the re-pricing trigger threshold is)
10. **Clerk identity + auth flow spec** (GitHub OAuth primary, Anthropic key link for BYO, SSO/SCIM deferred to Team-tier 90-day mark)
11. **Webhook + MCP contract extension spec** (what v6.9.1's post-publish-hook + state.json schema need to add/not-add for Composer-planner integration — strictly ADDITIVE, no breaking changes)
12. **Rollback + exit-ramp playbook** (how a user takes their marketplace content back to plain git in 10 minutes; how an Enterprise customer takes the tracker data out; OSS-safe exit guarantee wording for enterprise MSA)

---

## 12. My (Ilana's) ambivalence — user should decide explicitly

**I am genuinely torn on one decision that the user must make before Phase 4 begins:**

**Should the MVP ship Composer at all in week 1, or should we stage it?**

- **Ship Composer week 1 (Lena's position):** the 12-step FTUE depends on it; the viral loop is "one prompt → working app → shared URL." Without Composer, the MVP is "a catalog of markdown files" — Figma-Plugins-at-launch energy. Weaker demo, weaker HN moment, slower conversion.
- **Defer Composer to week 3-4 (Aravinda-leaning):** Composer planner service + deep-link handoff + signed-URL validation + load-bearing-intervention heuristic + Vercel Workflow fn is ~3 weeks of solo-founder engineering. Shipping it week 1 compresses the surface area we can QA. Defer = safer ship, but you lose the "Android app in 4 minutes" moment.

I genuinely do not know which is right. The decision is a risk-appetite call: **ship-the-dazzle-and-pray** vs. **ship-a-polished-catalog-and-add-dazzle-in-two-weeks**. Both have winning precedents (Bolt.new shipped dazzle-first and won; Raycast shipped catalog-first and won). The user knows the Honza-equivalent real customer better than I do. Please commit one way before Phase 4 so the spec writer knows whether to write 5 full specs or 4 + 1 stub.

---

*End of synthesis — ~4,400 words. Ready for Phase 4 input.*
