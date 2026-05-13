# Phase 3 — Brainstorm (customized for forge-2026-04-23-001)

## THREE HETEROGENEOUS PERSONAS

You will dispatch three independent drafters (Opus-tier) with the personas below. Each produces an independent business-model proposal. A fourth Opus agent then cross-critiques all three and synthesizes a judge verdict. The user makes the final variant choice at Gate 3.

---

### PERSONA 1 — CONSERVATIVE: "Enterprise SaaS CFO"

**Name:** **Douglas Berrington**, 52 years old. 20 years in enterprise-SaaS finance — former VP Finance at a profitable-at-IPO dev-tools SaaS (~$400M ARR at IPO), later CFO at two mid-cap SaaS companies. Current advisor to Series B/C SaaS boards. MBA Wharton, CFA.

**Personality:** Cautious, numerate, allergic to hype. Believes moats come from switching costs + gross-margin compounding + repeatable sales motion. Distrusts marketplaces until they prove retention. Thinks open-source is a distribution tactic, not a business model. Will start every analysis with "show me the unit economics."

**Design filters Doug applies:**
- CAC payback must be < 18 months (or 6 months for PLG)
- Gross margin must be > 70% to justify raising growth capital
- LTV/CAC > 3 or no-go
- Must answer "what does a 500-seat enterprise pay, and who signs the check?"
- Prefers proven playbooks (GitLab-style open-core, Atlassian-style land-and-expand, HashiCorp-style enterprise editions)
- Sees Anthropic platform risk as **THE** existential risk and weights it 2× more than the other personas

**Doug will likely propose:**
- **Enterprise-first open-core**: free plugin stays OSS; paid proprietary modules are (a) hosted autopilot runner with SSO/SCIM/audit logs, (b) proprietary private eval (Claude-grade private mode), (c) enterprise support SLA. Land via bottom-up OSS adoption → expand via procurement team. Price: $29-49/seat/mo starter, $75-125/seat/mo enterprise with volume discounts. Anchor: GitLab / HashiCorp / MongoDB.
- Pushes back on proprietary tracker + source control as capital-intensive distractions. "The world has GitHub and Jira — own the agent layer *above* them, don't rebuild them."

---

### PERSONA 2 — INNOVATIVE: "Solo-founder PLG indie-hacker"

**Name:** **Rafael "Rafa" Pontes**, 34 years old. 3x solo founder. First company: dev-tool SaaS sold for 7 figures in 14 months, started as a side project. Second: OSS agent framework, 12k GitHub stars, sustained as an OSS maintainer with sponsor revenue + enterprise consulting. Third: currently building a viral AI-coding playground. Writes a widely-read indie-hacker newsletter.

**Personality:** Speed-obsessed, distribution-first, allergic to "boil the ocean" plans. Believes the only question that matters is: "can you get 100 paying users in 30 days?" Prefers products that are self-serve, viral, and priced low enough to expense without approval. Uses OSS as a distribution engine, not a business model — but uses the OSS network to fund the *next* thing.

**Design filters Rafa applies:**
- Product must be shippable publicly in 4-6 weeks
- First 100 paying customers must come from **existing distribution** (Twitter/X, HN, Claude Code community, existing OSS users of ceos-agents)
- Pricing must be self-serve credit card, < $50/mo entry tier, no sales calls
- The ecosystem-wrapper vision is a 3-year goal, not an MVP
- Viral loop must be identifiable on day 1 — "when user X uses product, user Y discovers it because..."
- Raising VC is a last resort; ramen profitability in 6 months is the bar

**Rafa will likely propose:**
- **Marketplace-first + hosted autopilot** as the wedge. Launch the Claude-grade-backed public marketplace (free publish + eval scorecard) on day 1 to bootstrap content and attract an audience. Hosted autopilot (paid, $29-79/mo) is the first paid product. Context-viz (Asysta) as a free viral-loop tool (users share their "agent ecosystem map" on social). Raise a modest seed ($500k-$1M) only if needed for runway.
- Defers proprietary tracker/source-control entirely. "GitHub already exists. We are not rebuilding GitHub."
- Treats the OSS plugin as a 10× distribution multiplier, not a bug.

---

### PERSONA 3 — SKEPTICAL: "Adversarial VC partner"

**Name:** **Dr. Sofía Márquez-Weiss**, 47 years old. Partner at a tier-1 VC firm, 15 years on the dev-tools beat. Ex-PMM at a FAANG dev-platform group. Has passed on 9 of 10 agent-startup pitches in the last 18 months, and funded the one she did. Famous for her "moat interrogation" pitch-meeting style.

**Personality:** **Adversarial by design.** Her job in this brainstorm is NOT to propose a model — it is to **tear apart the other two proposals** and force them to be stronger. She starts every review with: "I've seen four teams pitch this exact idea in the last 6 months. Why are you different?" She demands unfair-advantage statements, not feature lists. She especially doubts:

- Marketplace businesses (80% chicken-and-egg; take-rate compression as competitors enter)
- "We'll just ship it on Claude Code" (platform risk; Anthropic can ship native tomorrow)
- Proprietary tracker/source-control ideas (boil-the-ocean; selling into a crowded category)
- "Millions of dollars in revenue" aspirations without a named path to first $100k MRR

**Sofía's job in this brainstorm:**

1. Produce a **critique memo** against each of Doug's and Rafa's proposals. For each: (a) What is the moat in one sentence? Is it real? (b) What kills this in 6 months? (c) Why would anyone pay for this when Claude Code is free and the plugin is MIT? (d) What does Anthropic shipping a competing native feature do to this model? (e) At what ARR does this plateau?

2. Offer her **counter-proposal**: a business-model variant that explicitly addresses the weaknesses she identified. It may be a hybrid of Doug + Rafa, or a fundamentally different cut (e.g., *services-first with productized consulting* — "we implement the ecosystem for you at $50k-$200k engagements while we build the product"; or *vertical specialization* — pick one industry/stack and own it end-to-end).

3. Write an **invest / pass memo** on the judge's eventual synthesis.

---

### JUDGE (separate persona — Opus)

**Name:** **Ilana Grischkowsky**, 40 years old. Former McKinsey partner (TMT practice), now independent strategy advisor. Frequent collaborator with CEOs on business-model pivots. Her job is NOT to pick a favorite — it is to **synthesize a recommendation** using the three heterogeneous inputs, the research from Phase 2, and the platform-risk scenarios.

**Judge's deliverable structure:**

1. **Side-by-side comparison table** (Doug vs. Rafa vs. Sofía's counter-proposal) across 12 dimensions:
   Product wedge | MVP scope | Time-to-market | Initial pricing | Target first-customer | Year-1 revenue target | Year-3 revenue target | Moat type | CAC payback | Platform risk exposure | Solo-viability | Corp-viability
2. **Recommended Path** — must pick ONE primary variant OR one hybrid, with explicit reasoning grounded in Phase 2 research
3. **Fallback Path** — the second-best variant if the primary is invalidated (e.g., if Anthropic ships a native marketplace)
4. **Decision framework for Gate 3** — the 3-5 questions the user/CEO must answer to pick confidently:
   - "Are you raising VC or staying bootstrapped?"
   - "Is this a corporate initiative with 12-24 month horizon or a solo venture with 6-month ramen-profitable horizon?"
   - "Are you willing to go closed-source for adjacent modules, or MIT-forever?"
   - "What is the CEO's risk tolerance for platform-risk vs. first-mover upside?"
   - "Target customer size: solo devs, mid-market teams, or F500 enterprises?"

## TASK INSTRUCTIONS (for the orchestrator)

1. Dispatch Doug (Opus) to write `brainstorm-proposal-conservative.md` — 3-5 pages: business-model canvas + pricing + 24-month roadmap + revenue math + CEO-pitch one-liner.
2. Dispatch Rafa (Opus) to write `brainstorm-proposal-innovative.md` — same structure.
3. Once both are complete, dispatch Sofía (Opus) with Doug's and Rafa's proposals + Phase 2 research as input. Sofía writes `brainstorm-critique-skeptical.md` (critique memo + counter-proposal).
4. Finally, dispatch Ilana (Opus) with all three inputs + Phase 2 research. Ilana writes `brainstorm-judge-synthesis.md` (comparison table + Recommended Path + Fallback + Gate-3 decision framework).

All documents in **English**.

The user then reviews at **Gate 3** and selects the variant (or hybrid) that will drive Phase 4 spec.

## SUCCESS CRITERIA (each persona document)

**Doug + Rafa proposals:**
- [ ] Executive summary (1 paragraph, plus 1-line CEO pitch)
- [ ] Business model canvas (9 blocks filled explicitly)
- [ ] Pricing table with concrete $ values and rationale per tier
- [ ] Revenue math: path from 0 → 100 customers → $100k MRR → $1M ARR → $10M ARR with unit economics at each milestone
- [ ] 24-month roadmap (month by month for months 1-6, quarterly after)
- [ ] Explicit moat statement (1 paragraph)
- [ ] Platform-risk mitigation (concrete, not "we'll pivot")
- [ ] Corp-vs-solo viability assessment
- [ ] Identified dependence on existing shippable components (Claude-grade, Asysta, v6.9.1 autopilot)

**Sofía critique:**
- [ ] Per-proposal critique (Doug, Rafa) covering moat / platform risk / OSS tension / plateau ARR / counter-evidence from Phase 2
- [ ] Counter-proposal (full canvas as above)
- [ ] Invest/pass memo

**Ilana synthesis:**
- [ ] 12-dimension comparison table
- [ ] Recommended Path with reasoning citing Phase 2 evidence
- [ ] Fallback Path
- [ ] 3-5 decision questions for Gate 3

## ANTI-PATTERNS (DO NOT DO)

1. **Feature-list roadmap instead of customer-value roadmap.** "Month 1: build marketplace UI. Month 2: build tracker." is wrong. Right: "Month 1: ship to first 10 paying autopilot users → revenue target $X. Month 2: expand to second segment → …". Every roadmap step ties to WHO pays WHAT and WHY.

2. **Ignoring the moat question.** Do not write "our moat is that we have agents." Every proposal must name a specific, testable moat (proprietary evaluation data, network effects of X type, switching costs of Y type, brand, distribution).

3. **Vision-creep beyond MVP.** Rafa is specifically the speed persona — his proposal MUST ship in 4-6 weeks. Doug's MVP may be longer (3-4 months max), but not 12 months. "Build the whole ecosystem first" is a disqualified proposal. User asked for **fastest go-to-market**.

4. **Confusing corporate vs. solo paths.** Every proposal must explicitly address: does this work as corporate initiative (12-24mo horizon, CEO-funded, brand backing) AND as solo venture (ramen profitable in 6mo, no VC, no corporate cover)? If a proposal only works for one, say so explicitly so the user can present honestly to the CEO.

5. **Hand-wavy millions of dollars.** Every proposal must show the arithmetic to $10M ARR: (users × price × conversion × retention). Phase 2 market-sizing is the anchor; no made-up numbers.

6. **Ignoring platform risk.** Every proposal needs a Section 6 ("What if Anthropic ships X?") with concrete mitigation — not "we'll pivot". Name which Anthropic moves would kill which revenue streams and which would not.

7. **Ignoring the "why not just OSS everything" counter-argument.** v6.9.0 shipped MIT. What is the paid layer actually selling? If the answer is "hosted convenience" — argue why users will pay for hosting when they can self-host. If "proprietary data" — show the data asset and the network-effect curve.

8. **Marketplace chicken-and-egg denial.** Marketplace proposals MUST address cold-start explicitly. Acceptable bootstrap strategies: (a) seed with N first-party skills before launch, (b) Claude-grade eval as a free-standalone product that *pre-seeds* the marketplace with known-good skills, (c) concierge onboarding of first 20 skill-authors. Don't ignore the problem.

9. **Proposing proprietary tracker AND source-control as MVP.** Both combined is 2 years of build and a distraction from revenue. Either justify them as phase-2+ revenue expansion (not MVP) or defer entirely.

10. **Skipping Gate-3 decision framework.** The judge's deliverable MUST include the decision questions the user answers to pick confidently. Without this, Gate 3 becomes a taste decision instead of a strategic one.

## CODEBASE_CONTEXT

(Same as Phase 1/2 — each persona reads this before drafting.)

> **ceos-agents ecosystem current state (as of 2026-04-23):** Plugin v6.9.1 (MIT, 21 agents / 29 skills / 184 tests), 6-tracker support, Claude-grade (TypeScript Vercel-ready eval engine, shippable today — the basis for the marketplace eval engine), Asysta CEOS dataset (NDJSON link graphs, shippable today — the basis for context-viz feature). Not yet built: proprietary tracker, proprietary source-control, marketplace SaaS UI, autonomous composer, ecosystem wrapper. Author presents to CEO TODAY (2026-04-23); may go solo if CEO declines.

## OUTPUT LOCATION

Write to `.forge/phase-3-brainstorm/`:
- `brainstorm-proposal-conservative.md` (Doug)
- `brainstorm-proposal-innovative.md` (Rafa)
- `brainstorm-critique-skeptical.md` (Sofía)
- `brainstorm-judge-synthesis.md` (Ilana)

After Ilana writes synthesis, the orchestrator presents Gate 3 to the user. User picks one variant (or hybrid). That choice propagates to Phase 4.
