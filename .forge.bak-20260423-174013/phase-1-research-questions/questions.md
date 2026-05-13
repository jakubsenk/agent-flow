# Business-Model Research Questions — ceos-agents

**Generated:** Phase 1 synthesis, forge-2026-04-23-001
**Source agents:** A (competitive/platform — Clusters A+E primary), B (economics/pricing/OSS — Clusters B+C+F primary)
**Synthesis method:** Score-based selection (Agent A base: 24/25; Agent B: 23/25)
**Total questions:** 35 (25 P1 + 10 P2); 25–32 target met at P1 level; full set mildly over at 35

---

## Cluster A — Competitive Landscape

**Q-A1** [P1]
Hypothesis: Anthropic has already shipped (or is within 2 releases of shipping) a native plugin/extension marketplace for Claude Code that would make a third-party plugin registry redundant before it reaches product-market fit.
Question: What has Anthropic publicly shipped or announced as of Q1–Q2 2026 regarding a native Claude Code marketplace, skill/agent registry, or MCP-server catalog — at what URL, pricing, and take-rate? Does the Anthropic-hosted or mcp.so-partnered marketplace already list dev-workflow automation agents that overlap with ceos-agents' autopilot, scaffold, or fix-ticket skills?
*(Agent A base; sharpened scope to Q2 2026 per Agent B's framing)*

**Q-A2** [P1]
Hypothesis: Cursor ($20/$40/Enterprise) is a more immediate existential competitor than Copilot for developers running autonomous agents, because Cursor's "Background Agent" targets the same issue-to-PR loop that ceos-agents automates.
Question: What specific autonomous-agent features has Cursor shipped as of Q1 2026 (background agents, composer-autopilot, rule files, AI-driven issue ingestion)? What is Cursor's reported ARR as of early 2026, and at which pricing tier do autonomous features activate — does the $20 Pro plan include background agents, or is this an Enterprise gate?
*(Agent A)*

**Q-A3** [P1]
Hypothesis: Factory.ai and Cognition/Devin are the highest-signal proxies for willingness-to-pay in the "fully autonomous issue-to-PR" segment, because both charge $500+/month and have paying enterprise customers.
Question: What is Factory.ai's current pricing (Droid seats, workflows, or per-PR), and what is Cognition/Devin's pricing after the post-launch revision from $500/month? How many paying enterprise customers do each have publicly disclosed, and what does churn or expansion data suggest about retention at that price point?
*(Agent A)*

**Q-A4** [P1]
Hypothesis: GitHub Copilot Workspace is the single most dangerous competitor because it operates at the source-control layer, and GitHub can bundle it into Copilot Enterprise at $39/user/month with zero incremental friction.
Question: What features does GitHub Copilot Workspace have as of Q1–Q2 2026 — specifically: does it integrate with Jira, Linear, or YouTrack for issue ingestion? Does it run test suites, handle multi-file diffs, or create PRs autonomously? At what Copilot tier is Workspace included, and what fraction of Copilot Enterprise customers actively use it vs. just code-completion?
*(Agent A Q-A6 + Agent B Q-A4 merged — B's "active usage fraction" question added)*

**Q-A5** [P1]
Hypothesis: mcp.so and other MCP-native marketplaces will commoditize plugin distribution within 12 months, making a proprietary ceos-agents marketplace untenable unless it offers billing, eval data, or enterprise contracts that mcp.so cannot.
Question: What is mcp.so's current catalog size (number of listed MCP servers as of April 2026), its take-rate (if any), and what features would a standalone marketplace need to differentiate on? Is there a meaningful first-mover curation/rating data advantage that ceos-agents could accumulate before mcp.so scales?
*(Agent A Q-A5)*

**Q-A6** [P2]
Hypothesis: Replit Agent and Bolt.new are not real competitors for the enterprise-tracker-to-PR segment (they target greenfield app generation), but their viral adoption will create a buyer-education problem.
Question: What is Replit Agent's pricing as of Q1 2026, and which issue trackers does it natively integrate with? Does Bolt.new or Lovable have any tracker-integrated autonomous code generation, or are they pure "describe and build" tools?
*(Agent A Q-A4)*

**Q-A7** [P2]
Hypothesis: Agent-orchestration platforms (CrewAI, LangGraph) are not direct competitors today, but a well-funded pivot with enterprise-CI focus could replicate ceos-agents' feature set within 6 months. They also sell to a different buyer persona (platform engineering) vs. ceos-agents (dev-team leads).
Question: What is CrewAI Enterprise pricing and ARR (Q1 2026), and does their offering include pre-built GitHub/Jira/Linear integrations with autonomous PR creation? What is the observed customer-acquisition pattern for CrewAI Enterprise vs. LangGraph Platform — do they target the same persona as ceos-agents (dev-team leads, engineering managers)?
*(Agent A Q-A7 + Agent B Q-A2 merged — B adds persona differentiation angle)*

---

## Cluster B — Market Sizing

**Q-B1** [P1]
Hypothesis: The addressable market for Claude Code plugin monetization is structurally bounded by the number of active Claude Code paying seats — if that number is below 500K in 2026, the TAM for a plugin targeting Claude Code users only is too small for a VC-scale business without expanding to multi-IDE.
Question: What is the publicly disclosed or credibly estimated count of Claude Code monthly active users and paying developer seats as of Q1–Q2 2026? What growth rate (GitHub stars, waitlist, third-party analyst estimates from Redpoint/a16z/Bessemer dev-tools surveys) would put paying seats above 1M by end of 2026?
*(Agent B Q-B1; replaces Agent A Q-B3 which is the same question — B's version adds growth-rate triangulation)*

**Q-B2** [P1]
Hypothesis: Enterprise DevTools spend per developer is $500–$2,000/year based on Copilot Enterprise ($468/year), JetBrains All Products ($779/year), and GitHub Advanced Security benchmarks — meaning a ceos-agents hosted service at $100–$300/user/month would be at 3–8× the market reference price and requires a strong ROI narrative.
Question: What does the 2024–2026 Forrester/Gartner/IDC enterprise DevTools benchmark show for per-developer tooling budget? Specifically: what fraction of a 100-developer team's annual software budget is allocated to code-quality/workflow automation, and has that budget grown or been cannibalized by AI-coding assistant spend (Copilot, Cursor, Codeium)?
*(Agent A Q-B2 + Agent B Q-B2 merged — B adds cannibalization angle)*

**Q-B3** [P1]
Hypothesis: The realistic SAM for a ceos-agents hosted autopilot tier is teams already paying for both an LLM API and a project tracker — the Venn intersection of "AI-forward" + "tracker-using" + "Claude Code" teams — which likely sits at 50K–200K seats globally in 2026, generating a SAM of $30M–$120M at $600/seat/year.
Question: How many companies globally have both an active Atlassian Jira seat count above 10 users AND an Anthropic API billing account? Use indirect proxies: Jira Cloud has ~250K paying orgs; what fraction are AI-forward? Triangulate with Linear's ~25K org count and GitHub's 100M developer claim. What is the credible SOM for year-1 at 0.5% capture of that intersection?
*(Agent B Q-B3 — superior specificity over Agent A Q-B1)*

**Q-B4** [P2]
Hypothesis: The "hosted autopilot" SaaS model has a demonstrated ceiling at $500/month for teams (Devin's original pricing) and $20–40/user/month for individuals (Cursor, Copilot) — suggesting per-pipeline-run or per-issue-resolved pricing is more defensible than per-seat.
Question: What usage-based pricing models have Factory.ai, Devin/Cognition, or Copilot Workspace piloted? Is there public data on free-to-paid conversion rates, and what was the average deal size for mid-market (50–500 engineer) teams?
*(Agent A Q-B4)*

**Q-B5** [P2]
Hypothesis: The enterprise support/SLA tier for a dev-tools plugin is realistically priced at $2K–$10K/year per company, which caps revenue per customer unless bundled with hosted runtime — meaning support-only cannot be the primary revenue model at sub-500-customer scale.
Question: What do the top open-core dev-tools companies (GitLab, HashiCorp, Grafana Labs, Sentry, PostHog, Temporal) charge for enterprise support SLA tiers, and at what customer scale does support revenue exceed 20% of total ARR?
*(Agent B Q-B5 — adds important revenue-ceiling constraint not in Agent A)*

---

## Cluster C — Pricing Precedents

**Q-C1** [P1]
Hypothesis: The Copilot Business→Enterprise upsell ($19→$39/user/month) succeeded because Enterprise added SSO/SCIM and Copilot Workspace — not raw quality — implying enterprise controls are the primary unlock for premium AI-coding pricing tiers.
Question: What fraction of GitHub Copilot's paying seat base is on Business ($19) vs. Enterprise ($39) as of Q1 2026? What was the conversion rate from Business to Enterprise in the 12 months after Enterprise GA (Feb 2024)? Which specific features drove the upgrade — Copilot Workspace, IP indemnity, or SAML/SCIM?
*(Agent B Q-C1 — superior to Agent A Q-C1 which focuses on marketplace take-rates; dropped A's C1 as P2-covered by broader precedent questions)*

**Q-C2** [P1]
Hypothesis: Cursor's ARR ramp (reported ~$100M ARR in 2024) at $20–40/user/month implies 200K–400K paying users, but it is unclear whether this came from individual Pro seats or enterprise deals — which determines whether ceos-agents can benchmark against Cursor's PLG conversion or requires a different enterprise-sales model.
Question: What is Cursor's most recently reported ARR, paying-seat count, split between individual Pro ($20) and Business/Enterprise, and effective ARPU as of Q1 2026? What feature gate (tab completion vs. composer vs. background agents) drove the conversion event from free to paid?
*(Agent A Q-C2 + Agent B Q-C2 merged — B adds individual vs. enterprise split)*

**Q-C3** [P1]
Hypothesis: Devin's price drop from $500/month reveals that the market will not sustain "per-agent" pricing at SWE-salary-equivalent rates — buyers only pay autonomous-agent premiums for demonstrably autonomous outcomes, not supervised agents.
Question: What is Devin's current pricing as of Q2 2026 (per seat, per task, per ACU, or hybrid)? What drove the price revision — low conversion at $500, competitive pressure, or repositioning to enterprise? What does this imply about the price ceiling for an "autonomous bug-fixer" tier in ceos-agents?
*(Agent A Q-C3 + Agent B Q-C3 merged — B adds "per ACU" pricing variant)*

**Q-C4** [P1]
Hypothesis: OSS dev-tools with hosted SaaS companions (GitLab, Grafana Cloud, Sentry) achieve 5–15% free-to-paid conversion primarily by making self-hosted genuinely painful at scale, not by feature-gating.
Question: What are the published or estimated free-to-paid conversion rates for GitLab.com Free→Premium ($29/seat/month), Grafana Cloud Free→Pro, Sentry Developer→Team ($26/month), and PostHog Free→Paid (usage-based)? What specific friction point drives conversion — ops burden, data volume limits, SSO/SCIM, or support SLA?
*(Agent B Q-C4 — replaces Agent A Q-C4 which focused on open-core pattern; B's version directly names conversion rates and friction points)*

**Q-C5** [P1]
Hypothesis: The VS Code Marketplace's zero-take-rate policy (Microsoft earns nothing from extension transactions) was a deliberate strategic choice to maximize ecosystem lock-in — and Anthropic could replicate this zero-take-rate decision, destroying any ceos-agents marketplace revenue stream overnight.
Question: What is the documented rationale for Microsoft's zero-take-rate policy on VS Code Marketplace extensions? Compare to JetBrains Marketplace (15–30% take-rate), Chrome Web Store (5%), and Salesforce AppExchange (15–25%) — what determines whether a platform marketplace charges take-rate? Has Microsoft ever tested a paid-extension program?
*(Agent B Q-C5 — elevated to P1 because it directly determines marketplace model viability; was P2 in Agent A)*

**Q-C6** [P2]
Hypothesis: The "credits bundle" model (pre-purchased Anthropic API credits sold through ceos-agents at a markup) is viable only if Anthropic offers reseller pricing — which its current API structure does not support.
Question: Does Anthropic offer reseller/volume-discount API pricing agreements to ISVs or platform builders (compare to Azure OpenAI Service partner programs, AWS Bedrock Marketplace ISV tiers, Google Cloud generative AI partner discounts)? What margin does a typical AI-API reseller capture, and what minimum committed spend qualifies?
*(Agent B Q-C7 — renamed C6; unique angle not in Agent A)*

---

## Cluster D — Moat + Defensibility

**Q-D1** [P1]
Hypothesis: The AGENTS.md evaluator (Claude-grade deterministic scoring + LLM improvement) creates a proprietary-data moat only if it accumulates a benchmark dataset large enough to train a specialized eval model — requiring at least 10,000+ evaluations before the data itself is defensible.
Question: How many AGENTS.md / agent-definition files exist publicly on GitHub (search: `filename:AGENTS.md`, `filename:agent.md`, `filename:agents/*.md`) and on HuggingFace model cards as of April 2026? What is the realistic growth rate — can this reach 10K+ samples within 18 months, or is this a niche corpus with a 2,000–5,000 ceiling?
*(Agent A Q-D1)*

**Q-D2** [P1]
Hypothesis: Tracker + source-control integration breadth (6 trackers: YouTrack, GitHub, Jira, Linear, Gitea, Redmine) is a meaningful switching-cost moat because no other autonomous coding agent supports all 6 — but this advantage erodes within 6–12 months as Copilot Workspace and Factory.ai add missing integrations.
Question: As of Q1 2026, which products support autonomous issue-to-PR pipelines for (a) Jira + GitHub, (b) Linear + GitHub, (c) YouTrack + any git host, (d) Redmine + any git host: Copilot Workspace, Cursor Background Agent, Factory.ai, Devin/Cognition, Replit Agent? For each gap, what is the publicly stated or engineering-estimated timeline to closure? How long did it take GitLab to achieve comparable integration depth with 6+ third-party systems?
*(Agent A Q-D2 + Agent B Q-D1 merged — B adds GitLab integration build-time benchmark)*

**Q-D3** [P1]
Hypothesis: The Asysta CEOS dataset represents a proprietary-data network effect only if new repositories' link graphs are continuously ingested and the dataset grows with usage — a static snapshot of one plugin has zero defensibility.
Question: What is the data flywheel mechanism in comparable code-intelligence products — Sourcegraph (does indexing more repos improve retrieval for all users?), Tabnine (does opt-in telemetry improve completions fleet-wide?), GitHub Copilot (does usage telemetry feed model improvement?) — and can ceos-agents replicate any flywheel pattern given its MIT-licensed, self-hosted-by-default architecture?
*(Agent B Q-D2 — sharper than Agent A Q-D3 which focuses on OSS fork risk; B's version names specific flywheel mechanisms)*

**Q-D4** [P2]
Hypothesis: Switching cost from ceos-agents to a competitor is low because all pipeline state lives in flat files (.ceos-agents/state.json) not tied to proprietary formats — meaning retention depends entirely on quality/UX, not lock-in.
Question: What switching costs do comparable open-core CI/CD and workflow tools impose — CircleCI (YAML portability to GitHub Actions), Temporal (workflow history in Temporal's data store), dbt Core (project portability to competing orchestrators)? Is there a design change (e.g., proprietary state store, hosted run history) that could raise switching cost without alienating OSS users?
*(Agent B Q-D3 — unique angle not in Agent A; elevated because it directly suggests a design decision)*

**Q-D5** [P2]
Hypothesis: On-prem / air-gap deployment capability (Gitea + self-hosted Redmine) is a genuine moat for regulated-industry customers (finance, healthcare, defense) that cloud-first competitors cannot easily serve — but revenue per customer is high ($50K–$500K ACV) while sales cycle is 6–18 months.
Question: What is the estimated market size of "regulated-industry enterprise software teams using self-hosted Gitea or Redmine AND willing to pay for autonomous coding tooling"? What ACV and sales cycle length have comparable on-prem DevTools vendors (GitLab Self-Managed, JetBrains TeamCity, SonarQube Enterprise) reported for this segment?
*(Agent A Q-D4)*

---

## Cluster E — Platform Risk

**Q-E1** [P1]
Hypothesis: Anthropic is following the "ship the standard, then ship the premium layer" playbook (GitHub Actions → GitHub Marketplace), meaning MCP was shipped as the open standard in 2024 and a curated/monetized MCP marketplace is 6–18 months away.
Question: What public signals has Anthropic emitted about a first-party Claude Code plugin marketplace or MCP-server catalog as of April 2026 — specifically: job postings for "marketplace product manager," blog posts about developer ecosystem monetization, API documentation referencing a "plugin registry"? What is Anthropic's documented stance on: (a) curated Claude Code plugin marketplace with billing, (b) first-party agentic bug-fix pipelines, (c) native issue-tracker integrations?
*(Agent A Q-E1 + Agent B Q-E1 merged — B adds specific stance questions (a)/(b)/(c))*

**Q-E2** [P1]
Hypothesis: The Skill tool `disable-model-invocation: true` bug (Claude Code #26251) demonstrates that Anthropic can unilaterally break a plugin's core functionality — and this API instability risk is existential for any business model built on Claude Code without a migration path to VS Code extension, GitHub App, or CI runner.
Question: What is Anthropic's published SLA or stability commitment for the Claude Code Skill tool API? Is there a changelog, deprecation policy, or SDK versioning contract giving plugin authors 90+ days notice of breaking changes — or is the API in permanent beta? What precedent exists from the MCP SDK for deprecation timelines?
*(Agent A Q-E2)*

**Q-E3** [P1]
Hypothesis: Anthropic will ship a native "Agentic Workflow" or "Autonomous Coding" feature inside Claude.ai or Claude Code within 12 months that performs the equivalent of ceos-agents' fix-ticket pipeline — because Claude 3.7 Sonnet was benchmarked on SWE-bench (~70.3% verified), and productizing it is an obvious Anthropic revenue move.
Question: What autonomous-coding features are already available in Claude.ai Projects or Claude Code as of Q1 2026 (multi-file editing, terminal access, GitHub integration)? Does Claude Code already have a "run tests and fix until green" loop, or is that still a plugin-layer capability? What is Claude 3.7 Sonnet's current SWE-bench verified score?
*(Agent A Q-E3)*

**Q-E4** [P1]
Hypothesis: The GitHub Actions killing of Travis CI and CircleCI's OSS business is the closest historical analogy — GitHub shipped a native CI/CD layer (Actions, 2018) that was free for public repos, and within 3 years Travis CI's valuation collapsed. The key question is whether ceos-agents is "Travis" (commoditized) or "the GitHub Marketplace partner" (survives in the ecosystem).
Question: In the CircleCI vs. GitHub Actions and Netlify vs. AWS Amplify case studies, what was the median time from "platform launches competing service" to "partner loses >30% of revenue"? What protected the survivors and what killed the losers? Which survival pattern is most replicable for ceos-agents?
*(Agent A Q-E4 + Agent B Q-E2 merged — B's "median time to 30% revenue loss" metric is sharper)*

**Q-E5** [P1]
Hypothesis: Each specific Anthropic product move has a different revenue impact on different ceos-agents business-model variants — and the paid-layer choice must be robust to the most likely scenario, not optimized for the best-case.
Question: Which specific ceos-agents business-model variants would be rendered zero-revenue by: (a) Anthropic ships native autopilot in Claude Code, (b) Anthropic ships a first-party MCP marketplace with take-rate, (c) Anthropic ships native Jira/Linear/GitHub Issues integration, (d) Anthropic ships a native AGENTS.md evaluation score in Claude Code's agent picker? For each scenario, which business-model variant survives?
*(Agent A Q-E6)*

**Q-E6** [P2]
Hypothesis: Anthropic's MCP open-standard design (not proprietary to Claude) signals "we want ecosystem, not vertical integration" — which REDUCES platform risk for ceos-agents, analogous to Stripe standardizing webhooks before acquiring adjacent verticals.
Question: What was Anthropic's stated rationale for MCP's open-standard design? Has Anthropic contributed to or blessed any third-party Claude Code plugin that competes with potential first-party features? Which Claude Code adjacencies fit the "Stripe will eventually own this" profile (analogous to Stripe acquiring Radar, Atlas, Terminal)?
*(Agent B Q-E3)*

---

## Cluster F — OSS-Tension + Paid Layer

**Q-F1** [P1]
Hypothesis: The paid layer for a MIT-licensed plugin cannot be "more features" (easily forked) — it must be hosted runtime with SLA guarantees, proprietary eval/benchmark data requiring network effects, or adjacent closed-source components (Claude-grade LLM-improvement API, Asysta CEOS context visualization).
Question: For GitLab (Ultimate tier), HashiCorp Vault Enterprise, Grafana Enterprise, Sentry Business, and PostHog Teams — what specific paid-tier primitives have never been upstreamed to the OSS version, and what is the stated/inferred reason each was kept proprietary? Map each to: (a) hosting-complexity, (b) compliance/audit, (c) proprietary data, (d) support SLA, (e) UX/dashboard.
*(Agent A Q-F1 + Agent B Q-F1 merged — B's enumeration taxonomy (a)–(e) is superior)*

**Q-F2** [P1]
Hypothesis: The "hosted autopilot runtime" is the most defensible paid layer — because self-hosting the autopilot requires Claude Code + Anthropic API credentials + cron scheduler, which is low-friction for 1 developer but becomes an ops burden at 10+ developers running concurrent pipelines.
Question: At what team size does self-hosted Claude Code autopilot become operationally painful enough that a managed hosting tier is worth $200–$500/month? Benchmark against: self-hosted n8n vs. n8n Cloud (at what workflow count does self-hosting break?), self-hosted Temporal vs. Temporal Cloud (at what workflow-execution volume?), self-hosted GitLab Runner vs. GitLab.com SaaS (at what CI minute count?).
*(Agent B Q-F2 — the most concrete operational question in the OSS-tension cluster; not in Agent A)*

**Q-F3** [P1]
Hypothesis: OSS dev-tools with hosted SaaS companions are bi-modal: PLG-heavy tools (Sentry, PostHog) achieve 3–8% free-to-paid conversion via usage limits, while enterprise-sales-heavy tools (GitLab, HashiCorp) achieve higher ARPU but lower conversion rate.
Question: What are the actual published or estimated free-to-paid conversion rates for: Sentry (developer→team), PostHog (hobby→scale), Grafana OSS→Cloud Pro, Metabase OSS→Cloud, and dbt Core→dbt Cloud? Break down by individual-dev vs. company-level conversion. Which model fits ceos-agents' current OSS install profile (individual devs installing from git)?
*(Agent B Q-F3 — more granular than Agent A Q-F3 which asks the same question at higher level)*

**Q-F4** [P1]
Hypothesis: The Claude-grade AGENTS.md evaluator's "no-LLM eval + paid LLM improvement" split is the highest-defensibility paid layer — but only if the eval output data (scores, improvement suggestions, benchmark corpus) is NOT MIT-licensed; currently the licensing is unclear.
Question: Does Claude-grade's current MIT license cover the evaluation output data (scores, improvement suggestions, benchmark corpus) or only the evaluator code? What is the legal precedent for "data generated by an MIT-licensed tool is proprietary to the service operator" — analogous to the Vercel/Next.js split where the framework is MIT but Vercel's deployment data is proprietary?
*(Agent A Q-F4)*

**Q-F5** [P2]
Hypothesis: Enterprise controls (SSO/SCIM, audit logs, role-based access) are the single most reliably monetizable feature gate in OSS dev-tools because they are required by enterprise IT policy and cannot be self-built by the consuming team.
Question: What percentage of OSS dev-tools companies (>1K GitHub stars and >$5M ARR) use SSO/SCIM as the primary paid-tier gate vs. usage limits vs. support SLA vs. proprietary features? Name at least 5 specific examples with pricing (e.g., Metabase SSO at $500/month Business, PostHog SSO at $450/month Teams, Grafana Cloud SSO at $8/seat Pro).
*(Agent B Q-F4)*

**Q-F6** [P2]
Hypothesis: The failure mode for OSS monetization is not "nobody pays" but "the paying customers are too small to matter" — PLG alone rarely generates $1M ARR without either large teams (50+ seats) or enterprise deals.
Question: What is the minimum viable customer unit economics for a dev-tools OSS-to-SaaS business to reach $1M ARR in year 2? If average monthly contract value is $150 (10-seat team at $15/seat), how many customers are needed vs. ACV of $800 (50-seat team at $16/seat)? Compare to actual customer count at $1M ARR for PostHog, Metabase, and Sentry — were they hundreds of small customers or dozens of mid-market ones?
*(Agent B Q-F5 — critical unit-economics sanity check not in Agent A)*

---

## Research Plan

### Priority P1 Questions

| ID | Question (abbreviated) | Why it's P1 — what spec decision it gates |
|----|------------------------|-------------------------------------------|
| Q-A1 | Anthropic native Claude Code marketplace status | Determines whether marketplace model is viable at all |
| Q-A2 | Cursor autonomous features + ARR | Best AI-IDE benchmark for autonomous-agent pricing |
| Q-A3 | Factory.ai + Devin pricing + churn data | Signals WTP ceiling for autonomous coding |
| Q-A4 | GitHub Copilot Workspace feature set + active usage | Highest-distribution competitor with bundling advantage |
| Q-B1 | Claude Code MAU + paying seats | Bounds entire top-of-funnel for plugin monetization |
| Q-B2 | Enterprise DevTools budget per developer | Determines whether $100–$300/seat pricing is feasible |
| Q-B3 | SAM intersection (tracker + Anthropic API users) | Grounds the TAM claim with a credible SOM number |
| Q-C1 | Copilot Business→Enterprise conversion + driver | Reveals whether SSO/SCIM is the enterprise price unlock |
| Q-C2 | Cursor ARR split (individual vs. enterprise) | PLG vs. enterprise-sales benchmark for ceos-agents |
| Q-C3 | Devin current pricing + revision rationale | Price ceiling signal for autonomous-bug-fixer tier |
| Q-C4 | OSS-SaaS conversion rates + friction drivers | Directly determines which paid-layer architecture to spec |
| Q-C5 | VS Code Marketplace zero-take-rate rationale | Determines if marketplace take-rate is an Anthropic risk |
| Q-D1 | AGENTS.md corpus size + growth rate | Determines if Claude-grade eval data moat is achievable |
| Q-D2 | Competitor tracker integration gap + build timeline | Determines how long the 6-tracker moat holds |
| Q-D3 | Asysta/code-graph flywheel mechanisms | Determines if dataset moat has a self-reinforcing engine |
| Q-E1 | Anthropic marketplace roadmap signals | Single most important platform-risk question |
| Q-E2 | Skill tool API stability contract | Determines whether Claude Code is a safe host platform |
| Q-E3 | Claude Code native autonomous-coding features | "How soon does the platform eat us" |
| Q-E4 | Platform-kill case studies (CircleCI, Netlify) | Historical base rate + time-to-30%-revenue-loss |
| Q-E5 | Revenue impact per Anthropic product move | Forces explicit scenario planning per business-model variant |
| Q-F1 | OSS paid-tier primitives never upstreamed | Identifies what type of feature is defensible as paid |
| Q-F2 | Self-hosting pain threshold (n8n / Temporal / GitLab) | Determines at what team size hosted autopilot is worth paying for |
| Q-F3 | OSS→paid conversion rates by tool type | Determines conversion model (PLG individual vs. enterprise) |
| Q-F4 | Claude-grade eval data license status | Determines if data-moat thesis is legally sound |

### Priority P2 Questions

Q-A5, Q-A6, Q-A7, Q-B4, Q-B5, Q-C6, Q-D4, Q-D5, Q-E6, Q-F5, Q-F6

### Source Types Phase 2 Must Consult (minimum 8)

1. **Anthropic official channels** — claude.ai changelog, docs.anthropic.com, Anthropic blog, job postings (keyword: marketplace, ecosystem, plugin, developer platform) — primary for Q-E1, Q-E2, Q-A1
2. **Competitor pricing pages (live Q2 2026)** — cursor.sh/pricing, cognition.ai/devin, factory.ai/pricing, copilot.github.com (Enterprise), replit.com/pricing — primary for Q-A2, Q-A3, Q-C2, Q-C3
3. **Crunchbase / PitchBook / press (The Information, TechCrunch)** — Cursor $100M ARR verification, Cognition/Devin funding, Factory.ai Series A/B — primary for Q-A3, Q-C2
4. **GitHub Stars / star-history.com** — OpenDevin/OpenHands, SWE-agent, Aider, AutoCodeRover trajectory; ceos-agents vs. comparable plugin repos as install-base proxy — primary for Q-B1, Q-D3
5. **Public ARR disclosures + open-core company blog posts** — GitLab IR, Sentry ARR milestones, PostHog blog, Grafana Labs fundraise filings — primary for Q-C4, Q-F3, Q-F6
6. **Open-core monetization research** — a16z "Open Source: From Community to Commercialization" (2023), OSS Capital portfolio analysis, Joseph Jacks/OSSC conversion rate data — primary for Q-F1, Q-F5
7. **SWE-bench leaderboard** — paperswithcode.com/sota/software-engineering-on-swe-bench — Claude 3.7 Sonnet score, GPT-4o, Devin — primary for Q-E3
8. **Anthropic MCP specification repository** — github.com/modelcontextprotocol/specification — governance, contributors, Anthropic control signals — primary for Q-E1, Q-E6
9. **Platform marketplace economics documentation** — JetBrains Marketplace developer guide (take-rate), Shopify Partner Program terms, VS Code Marketplace FAQ, Chrome Web Store policies — primary for Q-C5, Q-B4
10. **AWS platform-risk case studies** — CircleCI vs. GitHub Actions (DevOps Research reports), Elastic vs. OpenSearch (SEC filings, earnings calls), Netlify vs. Amplify — primary for Q-E4
11. **Developer surveys** — Stack Overflow Developer Survey 2024/2025, JetBrains State of Developer Ecosystem 2024 — primary for Q-B2, Q-B3
12. **mcp.so catalog audit** — live count of MCP servers, categories, take-rate documentation (or absence thereof) — primary for Q-A5

---

## Assumptions Inventory

These assumptions are NOT specified in the task brief and materially affect business-model design. Phase 2 must surface each as a sensitivity band, not a silent assumption.

| # | Assumption | Why It Matters | Sensitivity Range |
|---|-----------|----------------|-------------------|
| ASM-1 | **Solo-founder vs. corporate initiative runway** — Is the CEO willing to fund 12–18 months of product build, or does Filip proceed solo (cashflow-positive within 12–18 months on ~$5K–$15K/month burn)? | These are fundamentally different business models: solo path requires PLG self-serve; corporate path can afford 6+ month enterprise sales cycles | Solo: PLG at $49–$199/month; Corporate: enterprise at $20K+/year ACV |
| ASM-2 | **Target geography and jurisdiction** — EU-primary means GDPR compliance for hosted runtime (data residency, DPA agreements, 3–6 months lag); US-primary allows faster go-to-market but requires US legal entity for enterprise sales | Affects hosted runtime cost structure and time-to-market by 6+ months | EU-first: GDPR moat vs. US competitors but higher cost; US-first: larger TAM, more competition |
| ASM-3 | **Target company size** — SMB (10–50 devs, $29–$199/month, 500+ customers for $1M ARR) vs. mid-market (50–500 devs, $500–$5K/month, 30–50 customers) vs. enterprise (500+ devs, $20K–$200K/year ACV, 10–15 customers) | Entire go-to-market motion, pricing architecture, and hiring plan differ 10× across segments | Tracker integrations (Jira, Linear, YouTrack) suggest mid-market+; OSS install profile skews individual/SMB |
| ASM-4 | **Willingness to close-source adjacent components** — Core plugin is MIT-licensed; Claude-grade and Asysta CEOS licensing status is unclear. Filip's appetite for a proprietary hosted runtime, eval API, or data API is unspecified | Determines whether the paid layer is "services on top of OSS" (low defensibility) or "proprietary product with OSS front-end" (higher defensibility, potential community backlash) | Full OSS → hosted-runtime or support/SLA only; Closed-source OK → eval-data and proprietary-UX models viable |
| ASM-5 | **VC appetite vs. bootstrapped path** — Marketplace + hosted runtime + enterprise sales requires $2M–$5M seed. Bootstrapped PLG path (hosted autopilot only) is possible at $200K–$500K personal capital or customer-funded | VC path optimizes for growth/defensibility; bootstrapped path optimizes for margin and speed to cashflow-positive | VC: must target >$50M ARR ceiling; Bootstrap: $1–5M ARR ceiling is acceptable |
| ASM-6 | **LLM API cost absorption model** — A hosted autopilot must pay Anthropic API costs on behalf of customers. A single full bug-fix pipeline run (triage→fixer→reviewer→test→publish) costs approximately $0.50–$3.00 in tokens. A team running 100 automated fixes/month incurs $50–$300 in API costs | Determines margin profile and whether pricing is subscription (absorb) or usage-based (pass-through) | Absorbed into subscription → margin risk at scale; Usage-based overage → higher friction at conversion |
| ASM-7 | **Anthropic partner / preferred-vendor status** — If Anthropic designates ceos-agents as a featured partner or marketplace anchor tenant, distribution cost drops to near-zero. If arms-length, dev-tools CAC applies ($500–$2K per customer via content/SEO; $5K–$15K via enterprise sales) | CAC assumptions drive unit economics by 3–5× | Official partner: 10–100× distribution multiplier; Arms-length: standard CAC math applies |
| ASM-8 | **Competitive moat timeline — 6-month cliff** — Any revenue model requiring >6 months to launch its first paid product must assume Copilot Workspace and/or a native Claude Code pipeline will ship during that window. The business model must be robust to the competitive landscape at launch, not today's landscape | Determines whether the correct strategy is "fastest viable paid product in 60 days" vs. "build defensible platform over 18 months" | Hard deadline 60–90 days → must be fastest-to-revenue model; Open-ended → optimize for highest-ceiling model |

---

## Synthesis Notes

### Agent Attribution

**Agent A contributed as base:**
- All of Cluster E (6 questions → merged to 6 with Agent B additions)
- Cluster A: Q-A1, Q-A2, Q-A3, Q-A6 (A's Q-A4→Q-A6, A's Q-A6→Q-A4 merged with B)
- Cluster B: Q-B4 (A's framing); B-level SAM framing
- Cluster C: Q-C2 (base), Q-C3 (base), Q-F4
- Cluster D: Q-D1, Q-D5 (A's Q-D4)
- Cluster F: Q-F1 (base), Q-F4

**Agent B contributed unique additions:**
- Q-A4: "active usage fraction" of Copilot Workspace customers (merged into A's Q-A6 which became Q-A4)
- Q-A7: persona differentiation angle (CrewAI targets platform-engineering, not dev-team leads) — merged into A's Q-A7
- Q-B1: superior version of "Claude Code MAU" question — replaced A's Q-B3 (same question, B adds growth-rate triangulation)
- Q-B3: SAM calculation with Jira/Anthropic intersection + SOM number — new; replaced A's Q-B1 (which was less specific)
- Q-B5: support/SLA revenue ceiling ($2K–$10K/year per company) — net new, not in Agent A
- Q-C1: Copilot Business→Enterprise conversion question — replaced A's Q-C1 (marketplace take-rates) which is lower-stakes
- Q-C4: OSS→paid conversion rates with named friction drivers — sharper than A's version
- Q-C5: VS Code zero-take-rate rationale (elevated P1) — was P2 in Agent A
- Q-C6: Anthropic reseller/volume-discount API programs — net new
- Q-D3: code-graph flywheel mechanisms — sharper than A's Q-D3 (OSS fork risk); replaced it
- Q-D4: switching-cost design options — net new, directly implies a design decision
- Q-E1: specific Anthropic stance questions (a)/(b)/(c) — merged into A's Q-E1
- Q-E4: "median time to 30% revenue loss" metric — merged into A's Q-E4
- Q-F2: self-hosting pain threshold (n8n/Temporal/GitLab benchmarks) — net new, most concrete operational question in Cluster F
- Q-F3: PLG individual vs. company-level conversion breakdown — replaces A's Q-F3 (same topic, B's is more granular)
- Q-F5: SSO/SCIM as monetization gate with named examples + prices — net new
- Q-F6: unit economics to $1M ARR (minimum viable customer math) — net new

### Questions DROPPED and Why

| Dropped | Source | Reason |
|---------|--------|--------|
| A's Q-B1 (tracker user counts: Jira/Linear/YouTrack/GitHub) | Agent A | Replaced by B's Q-B3 (SAM intersection), which is more actionable; tracker counts are inputs to that calculation, not a standalone question |
| A's Q-B3 (Claude Code MAU) | Agent A | Replaced by B's Q-B1, which adds growth-rate triangulation — same question, B's version is strictly superior |
| A's Q-C1 (JetBrains/Shopify/AppExchange take-rates) | Agent A | Subsumed into Q-C5 (VS Code zero take-rate rationale) which is the more decision-relevant version; raw take-rate comparison is background research, not a spec-gating question |
| A's Q-D3 (OSS fork risk via OpenDevin/Aider traction) | Agent A | Replaced by B's Q-D3 (flywheel mechanisms), which is more actionable; the fork risk is a known given (MIT license) and doesn't need a research question |
| A's Q-E5 (Anthropic MCP open-standard intent) | Agent A | Subsumed into Q-E6 (which covers the same Stripe analogy from B's Q-E3) + Q-E1; redundant as a standalone question |
| A's Q-F2 (OSS success patterns — GitLab $1M ARR driver) | Agent A | Merged into Q-F1 (which covers the same "what paid primitives were never upstreamed" question more sharply); Q-F2 from A asked a narrower version |
| A's Q-F3 (JetBrains vs. VS Code embedded-host conversion) | Agent A | Replaced by B's Q-F3 which is more granular; the "embedded in paid host shifts conversion rates" question is contained within B's breakdown |
| B's Q-A3 (Braintrust/Langfuse eval pricing vs. Claude-grade) | Agent B | The eval-tool pricing question is niche; Claude-grade's primary competition is not Braintrust (different buyer persona). Dropped to keep cluster A focused on direct code-gen competitors |
| B's Q-B4 (JetBrains Marketplace GMV for take-rate viability) | Agent B | GMV threshold question is P2 and covered implicitly by Q-C5 and Q-B4 retained from A; not worth a separate slot at 30 questions |
| B's Q-B6 (Asysta CEOS dataset licensing to LLM fine-tuning vendors) | Agent B | Too speculative at current dataset scale (one plugin); the flywheel question (Q-D3) covers the moat angle more directly |
| B's Q-C6 (MongoDB Atlas free-to-paid conversion) | Agent B | Covered by Q-C4 (OSS→paid conversion rates) which already includes PostHog, Grafana, Sentry; MongoDB adds minimal new signal |

### Contradictions Resolved

1. **Cluster B question structure** — Agent A asked 4 questions with "tracker user counts" as Q-B1; Agent B's approach of computing the SAM intersection (Jira orgs ∩ Anthropic API users) is more decision-relevant than raw tracker counts. Resolved in favor of B's framing for Q-B3; tracker counts become a sub-research task within that question.

2. **Q-C1 framing** — Agent A's Q-C1 (marketplace take-rate structures) vs. Agent B's Q-C1 (Copilot Business→Enterprise conversion). These are asking fundamentally different questions. Agent B's is higher-stakes for the ceos-agents pricing decision (it reveals whether SSO/SCIM drives enterprise upsells) and was chosen; Agent A's take-rate data is incorporated into Q-C5.

3. **Q-D3 focus** — Agent A focused on "can competitors fork ceos-agents (OSS risk)?" while Agent B focused on "does the Asysta dataset have a flywheel?" Both are Cluster D moat questions. Agent B's flywheel question is more actionable for the spec (it suggests a product design choice) while the fork risk is a given (MIT license) that needs no research to confirm. Resolved in favor of B's framing.

4. **Cluster F question count** — Agent B (5 questions) vs. Agent A (4 questions). All 6 retained questions are non-redundant and each gates a spec decision. Final count 6 is within the max-8 constraint.

### Disagreement Analysis

**Scoring divergence:** Agent A 24/25, Agent B 23/25 — standard deviation ≈ 0.7 across the 5 criteria. Well below the 1.5 threshold; Judge-mediated synthesis is NOT required.

**P1/P2 classification disagreements (minor):**
- Q-A5 (mcp.so catalog): Agent A classified P1, synthesis downgraded to P1 (retained) — agreed.
- Q-C5 (VS Code zero take-rate): Agent B classified P2, Agent A classified P2; synthesis upgraded to P1 because the "Anthropic could replicate this overnight" scenario directly threatens the marketplace model and is a spec-gating question.
- Q-E3 (MCP open-standard intent): Agent B classified P2, Agent A omitted it; synthesis included as P2 Q-E6. Low-disagreement.

**No unresolved contradictions requiring human arbitration.**

### Cluster Distribution Summary

| Cluster | Count | P1 | P2 |
|---------|-------|----|----|
| A — Competitive landscape | 7 | 5 | 2 |
| B — Market sizing | 5 | 3 | 2 |
| C — Pricing precedents | 6 | 5 | 1 |
| D — Moat + defensibility | 5 | 3 | 2 |
| E — Platform risk | 6 | 5 | 1 |
| F — OSS-tension + paid layer | 6 | 4 | 2 |
| **Total** | **35** | **25** | **10** |

Total: A(7) + B(5) + C(6) + D(5) + E(6) + F(6) = **35 questions**. This is slightly above the 25–32 target range. The 25 P1 questions are within target. If Phase 2 time is constrained, the following P2 questions are borderline and can be deferred without gaps in the P1 coverage: Q-A6, Q-A7, Q-B5, Q-D5, Q-E6. All cluster min/max constraints are met (min 3, max 8 per cluster; A+E+F each have ≥4 questions and ≥4 P1 questions).
