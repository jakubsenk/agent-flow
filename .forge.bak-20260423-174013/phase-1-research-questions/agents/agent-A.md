# Phase 1 Research Questions — Agent A
**Persona:** Mira Halen, Strategic Research Analyst  
**Angle:** Cluster A (Competitive Landscape) + Cluster E (Platform Risk) — the external-threat view  
**Date:** 2026-04-23

---

## Cluster A — Competitive Landscape (7 questions)

**A1.**  
Hypothesis: Anthropic has already shipped (or is within 2 releases of shipping) a native plugin/extension marketplace for Claude Code that would make a third-party plugin registry redundant before it reaches product-market fit.  
Question: What has Anthropic publicly shipped or announced as of Q1 2026 regarding a native Claude Code marketplace, skill/agent registry, or MCP-server catalog — and at what URL, pricing, and take-rate does it operate? Does the Anthropic-hosted MCP marketplace (mcp.so partnership or first-party) already list dev-workflow automation agents that overlap with ceos-agents' autopilot, scaffold, or fix-ticket skills?  
**Tag: P1**

**A2.**  
Hypothesis: Cursor ($20/$40/Enterprise) is a more immediate existential competitor than Copilot for the segment of developers who already run autonomous agents, because Cursor's "Background Agent" feature (Composer in background) targets the same issue-to-PR automation loop that ceos-agents automates.  
Question: What specific autonomous-agent features has Cursor shipped as of Q1 2026 (background agents, composer-autopilot, rule files, AI-driven issue ingestion)? What is Cursor's reported ARR as of early 2026, and at which pricing tier do its autonomous features activate — does the $20 Pro plan include background agents, or is this an Enterprise gate?  
**Tag: P1**

**A3.**  
Hypothesis: Factory.ai and Cognition/Devin are the highest-signal proxies for willingness-to-pay in the "fully autonomous issue-to-PR" segment, because both charge $500+/month and have paying enterprise customers — meaning the TAM is real but the price point is at the high end.  
Question: What is Factory.ai's current pricing (Droid seats, workflows, or per-PR pricing), and what is Cognition/Devin's pricing after the controversial post-launch revision from $500/month? How many paying enterprise customers do each have publicly disclosed, and what does their churn or expansion data suggest about retention at that price point?  
**Tag: P1**

**A4.**  
Hypothesis: Replit Agent and Bolt.new are not real competitors for the enterprise-tracker-to-PR segment (they target greenfield app generation for non-technical users), but their viral adoption curves will create a perception problem: buyers will ask "why not just use Replit Agent for $25/month?" without understanding the enterprise integration gap.  
Question: What is Replit Agent's pricing as of Q1 2026, and which issue trackers (Jira, Linear, YouTrack, Gitea, Redmine) does it natively integrate with? Does Bolt.new or Lovable have any tracker-integrated autonomous code generation, or are they pure "describe and build" tools with no CI/CD or PR pipeline?  
**Tag: P2**

**A5.**  
Hypothesis: The MCP-native plugin marketplaces (mcp.so, Cursor's MCP tab, Zed extensions, JetBrains MCP plugins) will commoditize the plugin-distribution layer within 12 months, making a proprietary ceos-agents marketplace untenable unless it offers something mcp.so cannot — namely, billing, eval data, or enterprise contracts.  
Question: What is mcp.so's current catalog size (number of listed MCP servers as of April 2026), what is its take-rate (if any), and what features does it offer that a standalone marketplace would need to differentiate on? Is there a meaningful first-mover advantage in plugin curation/rating data that a ceos-agents marketplace could accumulate before mcp.so scales?  
**Tag: P1**

**A6.**  
Hypothesis: GitHub Copilot Workspace (the task-to-PR autonomous feature in GitHub.com, not the IDE extension) is the single most dangerous competitor because it operates at the source-control layer where ceos-agents has no lock-in, and GitHub can bundle it into Copilot Enterprise at $39/user/month with zero incremental friction for existing GitHub customers.  
Question: What features does GitHub Copilot Workspace have as of Q1 2026 — specifically: does it integrate with Jira, Linear, or YouTrack for issue ingestion? Does it run test suites, handle multi-file diffs, or create PRs autonomously without human-in-the-loop? At what Copilot tier is Workspace included, and what is the active-beta vs. GA timeline?  
**Tag: P1**

**A7.**  
Hypothesis: Agent-orchestration platforms (CrewAI, LangGraph, AutoGen) are not direct competitors today because they lack the pre-built tracker integrations and Claude Code ecosystem embedding that ceos-agents provides — but a well-funded pivot by any of these (e.g., CrewAI raising a Series B with enterprise-CI focus) could replicate the feature set within 6 months using the same open-source building blocks.  
Question: What is CrewAI's current funding stage and ARR (as of Q1 2026), and does their enterprise offering include pre-built GitHub/Jira/Linear integrations with autonomous PR creation? Has AutoGen (Microsoft-backed) shipped any production-grade CI integration, and at what price point?  
**Tag: P2**

---

## Cluster B — Market Sizing (4 questions)

**B1.**  
Hypothesis: The addressable market for issue-tracker-to-PR automation is bounded by the number of software developers at companies using one of the 6 supported trackers (YouTrack, GitHub Issues, Jira, Linear, Gitea, Redmine), which is a SAM in the 5-15M developer range — not the full 30M developer TAM commonly cited.  
Question: What are the publicly disclosed user counts for each of the 6 supported trackers as of 2025/2026 (Jira: ~65,000+ enterprise orgs; Linear: ~25,000 companies; YouTrack: ~20,000+ organizations; GitHub Issues: bundled with GitHub's 100M+ users; Gitea: self-hosted, ~1M+ installs estimated; Redmine: ~1M+ installs estimated)? What fraction of these users are at companies likely to pay for autonomous code-generation tooling (enterprise, >50 engineers)?  
**Tag: P1**

**B2.**  
Hypothesis: Enterprise DevTools spend per developer is $500-$2,000/year/developer based on Copilot Enterprise ($39×12=$468), JetBrains All Products ($779/year), and GitHub Advanced Security (~$49/user/month) benchmarks — meaning a ceos-agents hosted service priced at $100-$300/user/month would be at 3-8× the market reference price and requires a strong ROI narrative.  
Question: What is the observed enterprise DevTools-category spend per developer per year across Copilot Enterprise, JetBrains, GitHub Advanced Security, and Snyk — and what ROI metric (PRs/week, MTTR, bug escape rate) do these vendors use to justify premium pricing above $100/user/month?  
**Tag: P1**

**B3.**  
Hypothesis: The Claude Code active user base (the direct distribution channel for ceos-agents) is significantly smaller than GitHub Copilot's 1.3M+ paying seats (as of mid-2024 disclosures), which means top-of-funnel conversion math for any plugin-marketplace monetization depends on Anthropic's growth rate, not ceos-agents' own growth.  
Question: What is the publicly available estimate of Claude Code monthly active users or paying subscribers as of Q1 2026? What growth rate has Anthropic publicly signaled for Claude Code (new model releases, enterprise seats, API revenue disclosed in fundraising context)?  
**Tag: P1**

**B4.**  
Hypothesis: The "hosted autopilot" SaaS model for developer-tools has a demonstrated ceiling at $500/month for teams (Devin's original pricing) and $20-40/user/month for individual tools (Cursor, Copilot) — suggesting the right pricing architecture for ceos-agents is per-pipeline-run or per-issue-resolved, not per-seat.  
Question: What usage-based pricing models have Factory.ai, Devin/Cognition, or GitHub Copilot Workspace piloted or disclosed? Is there public data on conversion rates from free-tier to paid-tier in any of these products, and what was the observed average deal size for mid-market (50-500 engineer) teams?  
**Tag: P2**

---

## Cluster C — Pricing Precedents (4 questions)

**C1.**  
Hypothesis: The VS Code Marketplace take-rate of 0% is a cautionary tale that destroyed the economics for a potential Microsoft Marketplace SaaS layer, and any ceos-agents marketplace must avoid replicating this by either (a) owning the runtime (hosted), (b) owning the data (eval), or (c) charging for discovery/certification rather than revenue-share.  
Question: What is the exact take-rate structure of JetBrains Marketplace (reported 15-30%), Shopify App Store (15-20%), and Salesforce AppExchange (15-25%) — specifically: is the take-rate on first-year revenue only, recurring revenue, or all transactions? Which of these models has the highest net-revenue-retention for ISVs, and which has the highest seller churn?  
**Tag: P2**

**C2.**  
Hypothesis: Cursor's ARR ramp (reported ~$100M ARR in early 2025 based on press coverage) at $20-40/user/month implies a paying-user count of ~200,000-400,000 — meaning Cursor converted a substantial fraction of its reported 1M+ MAU to paid, at a conversion rate of 20-40%, which is 10-20× better than typical OSS PLG.  
Question: What is Cursor's most recently reported ARR, paying-seat count, and effective ARPU as of Q1 2026? What was the conversion rate from free VS Code extension downloads to paid Cursor Pro subscriptions, and what feature gate (tab completion vs. composer vs. background agents) drove the conversion event?  
**Tag: P1**

**C3.**  
Hypothesis: Devin's price drop from $500/month to a lower tier (speculated $150-250/month based on community reports) was driven by poor retention at the $500 price point because the autonomous output quality did not justify the cost for the median engineering team — not by competitive pressure from lower-priced alternatives.  
Question: What is Cognition/Devin's current (Q1 2026) pricing structure, and what public statements did Cognition make about the rationale for the revision? What is the net retention rate at the revised price point, if disclosed, and does the pricing model include a per-PR or per-task usage component?  
**Tag: P1**

**C4.**  
Hypothesis: Open-core DevTools companies that successfully monetize (GitLab Ultimate at $99/user/year, Grafana Cloud, MongoDB Atlas) all have a common pattern: the paid tier locks in an operational capability (SSO, audit logs, hosted runtime, proprietary eval) that makes switching costs real — and this is precisely the model ceos-agents must copy rather than selling "more features."  
Question: What is the free-to-paid conversion rate publicly disclosed or estimated for GitLab (CE → Premium/Ultimate), Grafana (OSS → Cloud), and HashiCorp (Terraform OSS → TFE/TFC) — and which specific features drove upgrade events? What was the observed time-from-first-install to paid-upgrade for each?  
**Tag: P2**

---

## Cluster D — Moat + Defensibility (4 questions)

**D1.**  
Hypothesis: The Claude-grade AGENTS.md evaluator (deterministic scoring + LLM improvement) creates a proprietary-data moat only if it accumulates a benchmark dataset of evaluated agent files large enough to train or fine-tune a specialized eval model — and this requires at least 10,000+ evaluations before the data itself becomes a defensible asset.  
Question: How many AGENTS.md / agent-definition files exist publicly on GitHub (search: `filename:AGENTS.md`, `filename:agent.md`, `filename:agents/*.md`) and on HuggingFace model cards as of April 2026? What is the realistic growth rate — is this a dataset that can reach 10K+ samples within 18 months, or is it a niche corpus with a ceiling of 2,000-5,000?  
**Tag: P1**

**D2.**  
Hypothesis: Tracker + source-control integration breadth (6 trackers: YouTrack, GitHub, Jira, Linear, Gitea, Redmine) is a meaningful switching-cost moat because no other autonomous coding agent supports all 6 in a single plugin — but this advantage erodes to zero within 6-12 months as Copilot Workspace, Cursor, and Factory.ai add the missing integrations.  
Question: As of Q1 2026, which of the following products support autonomous issue-to-PR pipelines for (a) Jira + GitHub, (b) Linear + GitHub, (c) YouTrack + any git host, (d) Redmine + any git host: Copilot Workspace, Cursor Background Agent, Factory.ai, Devin/Cognition, Replit Agent? For each gap, what is the publicly stated or engineering-estimated timeline to closure?  
**Tag: P1**

**D3.**  
Hypothesis: The open-source contributor base (GitHub stars, forks, external PRs) is a real but fragile moat — it provides distribution and trust signals, but does not prevent a funded competitor from forking the MIT-licensed codebase and adding a proprietary SaaS layer on top, exactly as Elastic did before AWS OpenSearch forked Elasticsearch.  
Question: What is the GitHub stars/forks trajectory for the closest OSS analogs to ceos-agents (e.g., OpenDevin/OpenHands, SWE-agent, Aider, AutoCodeRover) — and has any of them successfully converted OSS traction into a paid SaaS without being undercut by a larger vendor forking their OSS and bundling it for free?  
**Tag: P2**

**D4.**  
Hypothesis: On-prem / air-gap deployment capability (Gitea + self-hosted Redmine integration) is a genuine enterprise moat for regulated-industry customers (finance, healthcare, defense) that cloud-first competitors cannot easily serve — but the revenue per customer is high ($50K-$500K ACV) while the sales cycle is 6-18 months, making it a poor fit for a bootstrapped solo-founder go-to-market.  
Question: What is the estimated market size of "regulated-industry enterprise software teams that use self-hosted Gitea or Redmine AND would pay for autonomous coding tooling"? What ACV and sales cycle length have comparable on-prem DevTools vendors (GitLab Self-Managed, JetBrains TeamCity, SonarQube Enterprise) reported for this segment?  
**Tag: P2**

---

## Cluster E — Platform Risk (6 questions)

**E1.**  
Hypothesis: Anthropic is following the same "ship the standard, then ship the premium layer" playbook that GitHub used with Actions (2018: launch Actions free; 2019: GitHub Marketplace take-rate; 2021: kill CircleCI/Travis OSS market share) — meaning MCP was shipped as the open standard in 2024, and a curated/monetized MCP marketplace is 6-18 months away from Anthropic's roadmap.  
Question: What public signals has Anthropic emitted about a first-party Claude Code plugin marketplace or MCP-server catalog as of April 2026 — specifically: job postings for "marketplace product manager," blog posts about developer ecosystem monetization, or API documentation referencing a "plugin registry" endpoint? Is there a Claude.ai extensions tab, or any UI surface that accepts plugin submissions?  
**Tag: P1**

**E2.**  
Hypothesis: The Skill tool `disable-model-invocation: true` bug (Claude Code issue #26251, which blocks ceos-agents' autopilot skill) demonstrates that Anthropic can unilaterally break a plugin's core functionality with a platform update — and this API instability risk is an existential threat to any business model built on the Claude Code plugin API without a migration path to a different host (VS Code extension, GitHub App, CI runner).  
Question: What is Anthropic's published SLA or stability commitment for the Claude Code Skill tool API? Is there a changelog, deprecation policy, or SDK versioning contract that would give a plugin author 90+ days notice of breaking changes — or is the API effectively in permanent beta with no stability guarantee? What precedent exists from the MCP SDK or Anthropic API for deprecation timelines?  
**Tag: P1**

**E3.**  
Hypothesis: Anthropic will ship a native "Agentic Workflow" or "Autonomous Coding" feature inside Claude.ai or Claude Code within 12 months that performs the equivalent of ceos-agents' fix-ticket pipeline (issue-to-PR, with test + review loop) — because this is exactly the kind of task Claude 3.7 Sonnet was already benchmarked on (SWE-bench), and productizing it is an obvious Anthropic revenue move.  
Question: What is Anthropic's current SWE-bench score for Claude 3.7 Sonnet (reported ~70.3% on verified), and what autonomous-coding features are already available in Claude.ai Projects or Claude Code as of Q1 2026 (e.g., multi-file editing, terminal access, GitHub integration)? Does Claude Code already have a "run tests and fix until green" loop, or is that still a plugin-layer capability?  
**Tag: P1**

**E4.**  
Hypothesis: The GitHub Actions killing of Travis CI and CircleCI's OSS business is the closest historical analogy to ceos-agents' platform risk — GitHub shipped a native CI/CD layer (Actions, 2018) that was free for public repos, and within 3 years Travis CI's valuation collapsed and CircleCI's OSS segment was effectively dead. The key question is whether ceos-agents is "Travis" (commoditized) or "the GitHub Marketplace partner" (survives in the ecosystem).  
Question: What was Travis CI's ARR at peak (estimated $20-30M) and what happened to it post-Actions launch — specifically, which enterprise customer segments retained Travis and which churned? For CircleCI, how did the 2019-2022 revenue split between OSS/free-tier and enterprise shift after Actions launched, and what differentiation kept CircleCI's enterprise segment alive past $100M ARR?  
**Tag: P1**

**E5.**  
Hypothesis: Anthropic's decision to publish MCP as an open standard (rather than a proprietary protocol) was motivated by a desire to grow the ecosystem while avoiding antitrust exposure — and this same logic means Anthropic will NOT ship a proprietary tracker integration or proprietary agent marketplace, because doing so would risk killing the developer ecosystem they need to compete with OpenAI.  
Question: What public statements has Anthropic made about ecosystem partner strategy, plugin economics, or marketplace revenue-sharing as of April 2026? Has Anthropic published a developer program, a revenue-share model for plugin authors, or any financial commitment to third-party Claude Code plugin developers? What does the MCP specification governance structure (who controls the spec: Anthropic alone? an independent foundation?) say about Anthropic's intent?  
**Tag: P2**

**E6.**  
Hypothesis: The AWS partner-tool extinction pattern (AWS ships ElastiCache → Redis Labs loses cloud revenue; AWS ships SageMaker → many MLOps startups die; AWS ships Bedrock → LLM-wrapper startups compress) is a risk specifically for ceos-agents' "hosted runtime" business model — but does NOT apply to the "eval data" or "on-prem enterprise" models, because Anthropic cannot replicate proprietary customer eval datasets or on-prem deployment relationships.  
Question: Which specific ceos-agents business-model variants would be rendered zero-revenue by each of the following Anthropic moves: (a) Anthropic ships native autopilot in Claude Code, (b) Anthropic ships a first-party MCP marketplace with take-rate, (c) Anthropic ships native Jira/Linear/GitHub Issues integration, (d) Anthropic ships a native AGENTS.md evaluation score in Claude Code's agent picker? For each scenario, which business-model variant survives and what revenue impact is estimated?  
**Tag: P1**

---

## Cluster F — OSS Tension + Paid Layer (4 questions)

**F1.**  
Hypothesis: The paid layer for a MIT-licensed plugin cannot be "more features" (easily forked) — it must be either (a) hosted runtime with SLA guarantees, (b) proprietary eval/benchmark data that requires network effects to replicate, or (c) adjacent closed-source components (Claude-grade's LLM-improvement API, Asysta CEOS context visualization). The plugin itself becoming the loss-leader is a deliberate choice, not an accident.  
Question: Which of these three paid-layer models has the highest observed free-to-paid conversion rate in OSS dev-tools: (a) hosted runtime convenience (Grafana Cloud vs. OSS Grafana), (b) proprietary data/benchmark (no clean analog — closest is MongoDB Atlas vs. self-hosted Mongo), or (c) adjacent closed-source tool (GitLab vs. self-hosted GitLab CE)? What is the conversion rate for each?  
**Tag: P1**

**F2.**  
Hypothesis: OSS dev-tools projects that monetize successfully (GitLab, HashiCorp pre-BSL, Grafana, Temporal) all share a common trait: the paid tier requires non-trivial operational work to replicate (HA setup, SCIM/SSO wiring, audit log pipelines) — and for ceos-agents, the equivalent "hard to DIY" paid capability would be the pipeline-history eval network (Claude-grade + aggregated benchmark data), NOT the plugin code itself.  
Question: What specific feature drove the first $1M ARR for GitLab (Premium vs CE), HashiCorp Vault Enterprise vs OSS, and Grafana Cloud vs OSS — was it SSO/SCIM, audit logs, hosted runtime, SLA support, or a proprietary data feature? What was the time-from-OSS-launch to $1M ARR for each?  
**Tag: P2**

**F3.**  
Hypothesis: The 1-3% free-to-paid conversion rate typical for bottom-up PLG OSS tools is not the right benchmark for ceos-agents, because the plugin's users are already inside an IDE (Claude Code) that requires a paid Anthropic subscription — meaning the base population is already self-selected paying developers, and conversion to a ceos-agents paid tier should be 5-15% if the paid feature is clearly differentiated.  
Question: What is the observed conversion rate from free-tier to paid-tier for dev-tools plugins that live inside a paid host platform — specifically, JetBrains Marketplace plugins (users already pay $779/year for JetBrains) vs. VS Code Marketplace plugins (users pay $0 for VS Code)? Is there empirical data showing that "embedded in a paid host" shifts OSS plugin conversion rates above the 1-3% PLG baseline?  
**Tag: P2**

**F4.**  
Hypothesis: The Claude-grade AGENTS.md evaluator's "no-LLM eval + paid LLM improvement" split is the highest-defensibility paid layer because: (a) the deterministic eval is the free OSS loss-leader, (b) the LLM improvement API requires ongoing Anthropic API cost that users prefer to offload, and (c) aggregated eval data across all users creates a benchmark corpus that is proprietary by construction — but only if the eval data is NOT MIT-licensed (currently unclear).  
Question: Does Claude-grade's current v0.8.0 MIT license cover the evaluation output data (scores, improvement suggestions, benchmark corpus) or only the evaluator code? What is the legal precedent for "data generated by an MIT-licensed tool is proprietary to the service operator" — is this analogous to the Vercel/Next.js split where the framework is MIT but Vercel's deployment data is proprietary?  
**Tag: P1**

---

## Research Plan

### Sources Phase 2 Should Consult

1. **Anthropic official channels**: claude.ai changelog, docs.anthropic.com, Anthropic blog, job postings on anthropic.com/careers (keyword: marketplace, ecosystem, plugin, developer platform)
2. **Competitor pricing pages** (direct scrape): cursor.sh/pricing, cognition.ai/devin, factory.ai/pricing, copilot.github.com (Enterprise), replit.com/pricing, bolt.new, lovable.dev
3. **Crunchbase / PitchBook**: Cognition/Devin funding rounds and valuation, Factory.ai Series A/B, Cursor Series B ($9.9B valuation reported Jan 2025 — verify), CrewAI funding
4. **GitHub Stars as proxy for OSS traction**: OpenDevin/OpenHands, SWE-agent, Aider, AutoCodeRover — stars/forks trajectory via github.com API or star-history.com
5. **Public ARR disclosures**: Cursor ARR from Forbes/TechCrunch ($100M ARR reported Dec 2024 — verify recency), GitLab annual reports (SEC filings), HashiCorp 10-K (pre-IBM acquisition)
6. **Reddit / Hacker News sentiment**: r/ClaudeAI, r/LocalLLaMA, r/programming — threads on autonomous coding tools, ceos-agents pain points, Devin price controversy
7. **mcp.so catalog audit**: Live count of MCP servers listed, categories, take-rate documentation (or absence thereof)
8. **SWE-bench leaderboard**: paperswithcode.com/sota/software-engineering-on-swe-bench — Claude 3.7 Sonnet score, GPT-4o score, Devin score, for platform-capability comparison
9. **Anthropic MCP specification repository**: github.com/modelcontextprotocol/specification — governance, contributors, Anthropic control signals
10. **JetBrains Marketplace partner documentation**: plugins.jetbrains.com/developer — take-rate, payment terms, approval process

### P1 Questions (must-answer for any spec)

| Question | Why P1 |
|----------|--------|
| A1 — Native Claude Code marketplace status | Determines whether the marketplace business model is viable at all |
| A6 — GitHub Copilot Workspace feature set | Highest-distribution competitor with bundling advantage |
| B3 — Claude Code MAU/paying-user count | Bounds the entire top-of-funnel for plugin monetization |
| C2 — Cursor ARR and conversion rate | Best benchmark for "AI IDE plugin → paid" conversion math |
| C3 — Devin pricing revision rationale | Signals willingness-to-pay ceiling for autonomous coding |
| D1 — AGENTS.md corpus size on GitHub | Determines if Claude-grade eval data moat is achievable |
| D2 — Competitor tracker integration gap | Determines how long the 6-tracker moat holds |
| E1 — Anthropic marketplace roadmap signals | Single most important platform-risk question |
| E2 — Skill tool API stability contract | Determines whether Claude Code is a safe host platform |
| E3 — Claude Code native autonomous-coding features | Determines "how soon does the platform eat us" |
| E4 — GitHub Actions vs Travis CI case study | Historical base rate for "platform kills partner tool" |
| E6 — Revenue impact per Anthropic move | Forces explicit scenario planning per business model variant |
| F1 — Paid-layer conversion rate by model type | Directly determines which paid-layer architecture to spec |
| F4 — Claude-grade eval data license status | Determines if the data-moat thesis is legally sound |

### P2 Questions (nice-to-have)

A4, A5, A7, B4, C1, C4, D3, D4, E5, F2, F3

### Deterministic vs. Judgment-call Questions

**Answerable from public data:**
- A1 (Claude marketplace: check docs.anthropic.com, changelog)
- A6 (Copilot Workspace features: check GitHub docs)
- C2 (Cursor ARR: reported in press)
- C3 (Devin pricing: pricing page)
- E3 (SWE-bench score: paperswithcode leaderboard)
- mcp.so catalog count (live page)

**Require judgment call with explicit assumption:**
- B1 (tracker user counts require combining multiple sources + enterprise-fraction estimate)
- B3 (Claude Code MAU: not publicly disclosed — requires triangulation from API revenue disclosures)
- D1 (AGENTS.md corpus growth rate: requires a GitHub search + projection)
- E1 (Anthropic marketplace intent: requires reading job postings + inferring roadmap)
- E4 (Travis CI ARR at peak: not public — requires press triangulation)
- F4 (Claude-grade data licensing: requires legal interpretation, not just reading the license)

---

## Assumptions Inventory

The following assumptions are NOT specified by the user and materially affect business-model design. Phase 2 answers MUST surface these as sensitivity bands.

| # | Assumption | Why It Matters | Sensitivity Range |
|---|-----------|----------------|-------------------|
| 1 | **CEO budget appetite for this initiative** — Is the CEO willing to fund a 12-18 month product build, or is the budget ceiling "6 months of one developer's time"? | Determines whether a marketplace SaaS (18+ months to $1M ARR) or a consulting/support model (revenue in 3-6 months) is the right first move | Low: 6-month horizon → consulting-first; High: 3-year horizon → platform-first |
| 2 | **Solo-founder runway if CEO declines** — Does Filip have 12+ months of personal runway to pursue this independently, or is the timeline 3-6 months to first revenue? | Changes the viable go-to-market: enterprise sales (6-18 month cycles) is impossible under 6-month runway; PLG-hosted-SaaS requires 12+ months | <6 months: must be consulting or support-SLA; >12 months: hosted SaaS viable |
| 3 | **Target geography and jurisdiction** — Czech Republic/EU vs. US-first vs. global? | EU GDPR compliance adds 3-6 months to any hosted SaaS; US-first allows faster go-to-market; enterprise sales motion differs significantly | EU-first: higher compliance cost, GDPR moat vs. US competitors; US-first: larger TAM but more competition |
| 4 | **Target customer size** — SMB (10-50 engineers, $500-$2,000/month budget) vs. mid-market (50-500 engineers, $5K-$50K/month) vs. enterprise (500+ engineers, $50K+ ACV)? | Sales motion, pricing architecture, required feature set (SSO/SCIM/audit), and sales cycle length all differ by 10× across these segments | SMB → product-led, no-touch; Enterprise → field sales, 12-18 month cycle |
| 5 | **Willingness to create closed-source components** — Is Filip willing to close-source Claude-grade's LLM improvement API or the Asysta CEOS context visualization to create a proprietary paid layer, or is the philosophical commitment to full OSS an absolute constraint? | Determines whether a data/eval moat is legally defensible or whether everything gets forked | Full OSS → only hosted-runtime or support/SLA monetization; Closed-source OK → eval-data and proprietary-UX models viable |
| 6 | **Appetite for raising VC** — Is this a VC-track company (targeting $10M+ ARR, 3-5 year exit) or a bootstrapped/lifestyle business (targeting $1-3M ARR, sustainable solo or small team)? | VC-track requires a defensible moat and 100× TAM narrative; bootstrapped allows niche positioning that VCs would reject | VC: must target >$50M ARR ceiling; Bootstrap: $1-5M ARR ceiling is fine |
| 7 | **Anthropic partnership appetite** — Has Filip or the CEO explored an official Anthropic partner/ISV relationship, or is this assumed to be arms-length? | An official Anthropic partnership (revenue-share, co-marketing, listed on official extensions page) would change the distribution math fundamentally | Arms-length: dependent on organic discovery; Anthropic partner: 10-100× distribution multiplier |
| 8 | **Willingness to pivot off Claude Code** — If Anthropic ships native equivalents, is the strategic option to rebuild ceos-agents as a VS Code extension, GitHub App, or CI runner (platform-independent) — or is the Claude Code embedding a non-negotiable product decision? | Platform-independent architecture requires a 12-18 month rewrite but eliminates the E-cluster risks entirely | Claude-only: existential risk from E1/E3; Platform-agnostic: 12-18 month runway cost |
| 9 | **First-mover timeline urgency** — Is there a specific event (CEO board presentation, conference demo, customer pilot) that defines a "go/no-go" date, or is this an open-ended research phase? | Determines how much time is available for the paid-layer to accumulate network effects (eval data, stars, customers) before competitors close the integration gap | Hard deadline in 90 days → must pick the fastest-to-revenue model; Open-ended → can optimize for highest-ceiling model |
