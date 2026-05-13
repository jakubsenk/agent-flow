# Phase 1 Research Questions — Agent B (Internal Economics View)
_Analyst persona: Mira Halen, Strategic Research Analyst_
_Angle: Market sizing + Pricing precedents + OSS-tension/paid-layer (Clusters B, C, F deep) + minimum coverage A, D, E_
_Date: 2026-04-23_

---

## Cluster A — Competitive Landscape (4 questions)

**A1.** [P1]
Hypothesis: Claude Code's plugin ecosystem is still pre-marketplace (no hosted registry, no take-rate), which means the primary distribution advantage ceos-agents has today is zero-friction install from a git URL — but that moat evaporates the moment Anthropic ships a curated marketplace.
Question: As of Q2 2026, does Anthropic operate a monetized Claude Code plugin/skill marketplace (take-rate, IAP, billing integration), or is plugin distribution still ad-hoc git install? What is the equivalent distribution surface for Cursor (mcp.so), Copilot Workspace (VS Code Marketplace), and Devin (Cognition's closed ecosystem) — and which of these charges developers or plugin authors anything?

**A2.** [P1]
Hypothesis: Agent-orchestration frameworks (CrewAI, AutoGen, LangGraph) compete on the "build your own pipeline" axis, while ceos-agents competes on the "install once, get an opinionated pipeline" axis — these are adjacent, not identical markets, so enterprise buyers must choose between DIY platform and opinionated vertical plugin.
Question: What is the observed customer-acquisition pattern for CrewAI Enterprise vs. LangGraph Platform vs. Griptape Cloud — do they sell to the same persona (platform engineering, AI infra leads) or a different persona than ceos-agents (dev-team leads, engineering managers)? Name specific pricing tiers if public (LangGraph Platform launched ~2024; CrewAI Enterprise pricing).

**A3.** [P2]
Hypothesis: Braintrust and Langfuse occupy the agent-eval layer that ceos-agents Claude-grade component partially overlaps (AGENTS.md health scoring), but neither charges meaningfully for the deterministic/rule-based evaluation path — only for LLM-as-judge and hosted tracing.
Question: What does Braintrust charge for hosted eval runs at 1M spans/month vs. Langfuse Cloud vs. Arize Phoenix? At what usage level does the pricing become a budget line item for a 50-engineer team, and does Claude-grade's deterministic (no-LLM) evaluation positioning let ceos-agents undercut that tier?

**A4.** [P2]
Hypothesis: Copilot Workspace (GitHub's agent task runner, GA 2025) is the most direct platform-level competitor to the ceos-agents bug-fix pipeline — because it runs inside GitHub, owns the issue-to-PR loop natively, and is bundled with existing Copilot Enterprise seats at no additional charge.
Question: As of Q2 2026, what are Copilot Workspace's published capabilities (multi-file fixer, test runner, PR creation), which tracker integrations does it support beyond GitHub Issues, and what fraction of Copilot Enterprise customers actively use Workspace vs. just using code-completion? Is it available on GitHub Team ($4 seat) or only Enterprise ($39 seat)?

---

## Cluster B — Market Sizing (6 questions — deepest cluster per Agent B angle)

**B1.** [P1]
Hypothesis: The addressable market for Claude Code plugin monetization is structurally bounded by the number of active Claude Code paying seats, which is a fraction of total Anthropic API revenue — and if that number is below 500K seats in 2026, the TAM for a single plugin targeting Claude Code users only is too small for a VC-scale business without expanding to multi-IDE.
Question: What is Anthropic's publicly disclosed or credibly estimated count of Claude Code (formerly known as "Claude for coding") active monthly users and paying developer seats as of Q1-Q2 2026? Cross-reference: Claude Code launched in beta ~early 2025; what growth rate (GitHub stars, waitlist, third-party analyst estimates from Redpoint/a16z/Bessemer dev-tools surveys) would put paying seats above 1M by end of 2026?

**B2.** [P1]
Hypothesis: The enterprise-DevTools software budget is a distinct and measurable line item — typically $200-800 per developer per year for tooling licenses — and AI-coding assistant tools have begun cannibalizing traditional IDE/linter/CI budgets rather than creating net-new budget.
Question: What does the 2024-2026 Forrester, Gartner, or IDC enterprise DevTools spending benchmark show for per-developer tooling budget (ex-cloud infra)? Specifically: what fraction of a 100-developer team's annual software budget is allocated to code-quality/workflow automation tools (category: code review tools, CI/CD, static analysis), and has that budget grown or been cannibalized by AI-coding assistant spend (Copilot, Cursor, Codeium)?

**B3.** [P1]
Hypothesis: The realistic SAM for a ceos-agents hosted autopilot tier is teams already paying for both an LLM API (Anthropic/OpenAI) and a project tracker (Jira/Linear/YouTrack) — the Venn intersection of "AI-forward" + "tracker-using" + "Claude Code" teams — which likely sits at 50K-200K seats globally in 2026, generating a SAM of $30M-$120M at $600/seat/year.
Question: How many companies globally have both an active Atlassian Jira seat count above 10 users AND an Anthropic API billing account (any tier)? Use indirect proxies: Jira Cloud has ~250K paying organizations; what fraction are AI-forward (defined as having API spend with any LLM vendor)? Triangulate with Linear's published ~25K organization count (2024) and GitHub's 100M developer claim. What is the credible SOM for year-1 if ceos-agents captures 0.5% of that intersection?

**B4.** [P2]
Hypothesis: The marketplace take-rate revenue stream (charging plugin authors 15-20% of plugin revenue) is only viable if the underlying marketplace generates >$50M annual GMV — below that, take-rate produces sub-$10M revenue that doesn't justify marketplace infrastructure investment.
Question: What is the annual GMV of the JetBrains Marketplace (est. ~2019-present), the Shopify App Store, and the VS Code Marketplace (zero take-rate — what was the policy rationale)? At what GMV level did Shopify's App Store become a meaningful ($50M+) revenue line for Shopify Inc.? What does that imply about the minimum plugin-ecosystem scale before take-rate monetization is economically rational for ceos-agents?

**B5.** [P2]
Hypothesis: The enterprise support/SLA tier for a dev-tools plugin is realistically priced at $2K-$10K/year per company (not per seat), which caps the revenue per customer unless bundled with hosted runtime — meaning support-only cannot be the primary revenue model at sub-500-customer scale.
Question: What do the top 10 open-core dev-tools companies (GitLab, HashiCorp/IBM, Grafana Labs, Sentry, PostHog, Metabase, Airbyte, dbt Labs, Temporal, Backstage/Roadie) charge for enterprise support SLA tiers, and at what customer scale does support revenue exceed 20% of total ARR? Is support a primary revenue driver or a secondary retention tool in these comps?

**B6.** [P2]
Hypothesis: The Asysta CEOS context-visualization dataset (link graphs of plugin structure) represents a proprietary-data asset that could be licensed as an API to LLM fine-tuning or RAG vendors — a revenue stream independent of end-user developer count — but the dataset's current size (one plugin's NDJSON graph) is too small to command a meaningful data-licensing price without expanding to a multi-plugin, multi-repo corpus.
Question: What do comparable code-knowledge graph / developer-context dataset vendors (Sourcegraph Cody's code graph, Tabnine's codebase index, Bloop's semantic search index) charge for API access or data licensing? At what corpus size (number of repositories, LOC, update frequency) does a code-knowledge dataset become licensable at $50K+/year to an enterprise buyer?

---

## Cluster C — Pricing Precedents (7 questions — deepest cluster per Agent B angle)

**C1.** [P1]
Hypothesis: The Copilot Business→Enterprise upsell ($19 → $39/user/month, a 2x price increase) achieved meaningful conversion because Enterprise added SSO/SCIM, policy controls, and Copilot Workspace — not because of raw code-completion quality. This implies enterprise controls (SSO/SCIM/audit) are the primary unlock for enterprise pricing tiers in AI-coding tools.
Question: What fraction of GitHub Copilot's paying seat base is on Business ($19) vs. Enterprise ($39) as of Q1 2026? What was the conversion rate from Business to Enterprise in the 12 months after Enterprise GA (Feb 2024)? Which specific Enterprise features drove upgrade — was it Copilot Workspace (agent mode), IP indemnity, or SAML/SCIM?

**C2.** [P1]
Hypothesis: Cursor's price compression from community pricing ($20 Pro, $40 Business) to the effective per-seat cost in enterprise negotiations is significant — and Cursor's rapid ARR ramp ($100M ARR reported in 2024) came primarily from individual developers paying $20/month (PLG), not enterprise deals, which means the enterprise price anchor is still unproven.
Question: What is Cursor's reported or estimated ARR as of Q1 2026, what is the split between individual Pro ($20) and Business/Enterprise seats, and what is the average deal size for an enterprise Cursor contract? Specifically: did Cursor's $100M ARR milestone (if confirmed) come from >5M paying individual seats at $20, or from enterprise deals at $100+/seat/year?

**C3.** [P1]
Hypothesis: Devin's price drop (from $500/month at launch in 2024 to a restructured pricing by late 2024) reveals that the market will not sustain "per-agent" pricing at SWE-salary-equivalent rates — buyers only pay autonomous-agent premiums for demonstrably autonomous outcomes (not for "agent that needs supervision").
Question: What is Devin's current pricing as of Q2 2026 (per seat, per task, per ACU, or hybrid)? What drove the price revision — low conversion at $500, competitive pressure from Cursor Agent / Copilot Workspace / Bolt.new, or repositioning to enterprise? What does this imply about the price ceiling for an "autonomous bug-fixer" tier in ceos-agents?

**C4.** [P1]
Hypothesis: OSS dev-tools with hosted SaaS companions (GitLab, Grafana Cloud, Sentry SaaS, PostHog Cloud) achieve 5-15% free-to-paid conversion on the hosted tier — primarily by making self-hosted genuinely painful at scale (ops burden, upgrade friction) rather than by feature-gating.
Question: What are the published or estimated free-to-paid conversion rates for GitLab.com Free→Premium ($29/seat/month), Grafana Cloud Free→Pro ($0→$8+/seat/month), Sentry Developer→Team ($0→$26/month), and PostHog Free→Paid (usage-based)? What specific friction point drives conversion in each case — ops burden, data volume limits, SSO/SCIM, or support SLA?

**C5.** [P2]
Hypothesis: The VS Code Marketplace's zero-take-rate policy (Microsoft charges nothing, earns nothing from extension transactions) was a deliberate strategic choice to maximize ecosystem lock-in, not an oversight — and any marketplace built on top of Claude Code must accept that Anthropic could replicate this zero-take-rate decision, destroying the ceos-agents marketplace revenue stream overnight.
Question: What is the documented rationale for Microsoft's zero-take-rate policy on VS Code Marketplace extensions? Has Microsoft ever tested or announced a paid-extension monetization program? Compare to JetBrains Marketplace (15-30% take-rate, paid plugins), Chrome Web Store (5% take-rate, $5 one-time dev fee), and Salesforce AppExchange (15-25% take-rate) — what determines whether a platform marketplace charges take-rate?

**C6.** [P2]
Hypothesis: MongoDB Atlas's free-to-paid conversion (~3-5% of free-tier users convert to paid within 12 months) is driven by storage/compute limits hitting production use cases — not by feature gates — and this model requires massive free-tier user volume (MongoDB has 1M+ registered Atlas users) to generate meaningful paid revenue.
Question: What is MongoDB Atlas's free-to-paid conversion rate and average time-to-convert (months from signup to first charge)? Compare to HashiCorp Cloud Platform (HCP) free→paid and Confluent Cloud free→paid. At what free-tier user volume does a 3% conversion rate generate $1M+ ARR, and how does that minimum volume compare to the realistic ceos-agents install base in year 1-2?

**C7.** [P2]
Hypothesis: The "credits bundle" model (pre-purchased LLM-API credits sold through the ceos-agents platform at a markup) is viable only if the platform can negotiate volume discounts from Anthropic that exceed the reseller margin — and Anthropic's current API pricing structure does not support reseller programs, making this model speculative.
Question: Does Anthropic offer reseller/volume-discount API pricing agreements to ISVs or platform builders (compare to Azure OpenAI Service partner programs, AWS Bedrock Marketplace ISV tiers, or Google Cloud's generative AI partner discounts)? What margin does a typical AI-API reseller/bundler capture (5%? 15%? 30%), and what minimum committed spend qualifies for that margin?

---

## Cluster D — Moat + Defensibility (3 questions)

**D1.** [P1]
Hypothesis: The primary defensible moat for ceos-agents is tracker integration breadth (6 trackers: YouTrack/GitHub/Jira/Linear/Gitea/Redmine) — not agent quality — because agent quality is replicated in weeks by a well-funded team, while deep integration with 6 tracker APIs + state-machine management represents 12-18 months of integration work.
Question: How long did it take GitLab to achieve comparable issue-tracker + CI/CD integration depth with the same 6+ third-party systems (Jira, Linear, GitHub Issues, Redmine, etc.), and what was their team size when they built those integrations? Does Copilot Workspace currently support any tracker beyond GitHub Issues — and if not, is that a 6-month build or a 24-month build for a team with 20 engineers?

**D2.** [P1]
Hypothesis: The Asysta CEOS dataset represents a proprietary-data network effect only if new repositories' link graphs are continuously ingested and the dataset grows with usage — a static snapshot of one plugin is not a network effect, it is just a dataset, and datasets without a flywheel have zero defensibility.
Question: What is the data flywheel mechanism in comparable code-intelligence products — Sourcegraph's code graph (does indexing more repos improve retrieval for all users?), Tabnine's model (does opt-in telemetry improve completions for the whole fleet?), GitHub Copilot's training data (does usage telemetry feed model improvement?) — and can ceos-agents replicate any of these flywheel patterns given its MIT-licensed, self-hosted-by-default architecture?

**D3.** [P2]
Hypothesis: Switching cost from ceos-agents to a competitor (e.g., Copilot Workspace + native Jira integration) is low because all pipeline state lives in flat files (.ceos-agents/state.json) that are not tied to proprietary data formats — meaning switching cost is near-zero, and retention depends entirely on quality/UX differentiation, not lock-in.
Question: What switching costs do comparable open-core CI/CD and workflow tools impose — CircleCI (YAML config portability to GitHub Actions), Temporal (workflow history locked in Temporal's data store), dbt Core (project portability to competing orchestrators)? How do these compare to ceos-agents' switching cost profile, and is there a design change (e.g., proprietary state store, hosted run history) that could raise switching cost without alienating OSS users?

---

## Cluster E — Platform Risk (3 questions)

**E1.** [P1]
Hypothesis: Anthropic shipping a native "Claude Code Marketplace" with curated plugins would be net-positive for ceos-agents (distribution) only if ceos-agents is featured/whitelisted — but if Anthropic simultaneously ships a first-party bug-fix pipeline agent (equivalent to fix-ticket), the marketplace distribution gain is offset by direct competition from the platform owner.
Question: What is Anthropic's documented product roadmap stance on: (a) a curated Claude Code plugin marketplace with billing, (b) first-party agentic pipelines for issue-to-PR workflows, and (c) native issue-tracker integrations? Cross-reference GitHub's pattern: GitHub shipped Copilot Workspace AFTER GitHub Actions had already validated the CI/CD market. Does Anthropic's MCP standard (released late 2024) signal "we will build the pipes, partners build the plumbing" or "we will own end-to-end"?

**E2.** [P1]
Hypothesis: The AWS/partner history (AWS Elastic Search → OpenSearch fork killing Elastic's cloud business; AWS SES killing early email-infrastructure startups; AWS Amplify competing with Netlify/Vercel) shows that platform risk materializes fastest when the partner's product is (a) infrastructure-adjacent, (b) high-margin, and (c) solves a problem the platform owner needs to solve for its own products — ceos-agents bug-fix automation fits all three criteria for Anthropic.
Question: In the AWS partner-getting-Amazon'd case studies, what was the median time from "AWS launches competing service" to "partner loses >30% of revenue"? Specifically for CircleCI (vs. GitHub Actions), Netlify (vs. Amplify/CloudFront Functions), and PagerDuty (vs. AWS EventBridge + SNS) — what protected the survivors and what killed or marginalized the losers? Which survival pattern is most replicable for ceos-agents?

**E3.** [P2]
Hypothesis: Anthropic's MCP (Model Context Protocol) release in late 2024 is structurally analogous to Stripe's webhook standard — it standardizes the integration layer without Anthropic owning the integration, which REDUCES platform risk for ceos-agents because Anthropic is signaling "we want ecosystem, not vertical integration."
Question: What was Anthropic's stated rationale for MCP's open-standard design (not proprietary to Claude)? Has Anthropic contributed to or blessed any third-party Claude Code plugin/skill that competes with potential first-party features? Compare to Stripe's pattern: Stripe standardized webhooks and APIs but acquired Radar (fraud), Atlas (company formation), and Terminal (in-person payments) when those adjacencies were strategically critical — which Claude Code adjacencies fit that "Stripe will eventually own this" profile?

---

## Cluster F — OSS-tension + Paid-Layer (5 questions — deepest cluster per Agent B angle)

**F1.** [P1]
Hypothesis: Among OSS dev-tools projects that reached production adoption, the ones that successfully monetize (GitLab, HashiCorp, Grafana, Sentry, PostHog) share a common pattern: the paid tier adds an operational primitive (hosted runtime, multi-tenancy, compliance controls) that is genuinely hard to self-host — not just features that could be upstreamed to the OSS version.
Question: For GitLab (Ultimate tier at $99/seat), HashiCorp Vault Enterprise, Grafana Enterprise, Sentry Business, and PostHog Teams — what specific paid-tier primitives have never been upstreamed to the OSS version, and what is the stated/inferred reason each was kept proprietary? Map each to one of: (a) hosting-complexity, (b) compliance/audit, (c) proprietary data, (d) support SLA, (e) UX/dashboard.

**F2.** [P1]
Hypothesis: The "hosted autopilot runtime" is the most defensible paid layer for ceos-agents — because self-hosting the autopilot requires a machine with Claude Code installed, Anthropic API credentials configured, and a cron scheduler, which is low-friction for 1 developer but becomes an ops burden at 10+ developers running concurrent pipelines — creating a natural usage-based upsell trigger.
Question: At what team size does self-hosted Claude Code autopilot become operationally painful enough that a managed hosting tier becomes worth $200-$500/month? Benchmark against: self-hosted n8n vs. n8n Cloud (at what workflow count does self-hosting break?), self-hosted Temporal vs. Temporal Cloud (at what workflow-execution volume?), self-hosted GitLab Runner vs. GitLab.com SaaS (at what CI minute count?). What is the "self-hosting pain threshold" in each case?

**F3.** [P1]
Hypothesis: OSS → paid conversion rates in dev-tools are bi-modal: PLG-heavy tools (Sentry, PostHog, Grafana) achieve 3-8% free-to-paid conversion via usage limits, while enterprise-sales-heavy tools (GitLab, HashiCorp) achieve higher ARPU but lower conversion rate because they target company-level buyers, not individual developers.
Question: What are the actual published or estimated free-to-paid conversion rates for: Sentry (developer → team plan), PostHog (hobby → scale plan), Grafana OSS → Grafana Cloud Pro, Metabase OSS → Metabase Cloud, and dbt Core → dbt Cloud? Break down by: individual-dev conversion vs. company-level conversion. Which conversion model (PLG individual vs. enterprise top-down) fits ceos-agents' current OSS install profile (individual devs installing from git)?

**F4.** [P2]
Hypothesis: Enterprise controls (SSO/SCIM, audit logs, role-based access, compliance exports) are the single most reliably monetizable feature gate in OSS dev-tools because they are genuinely required by enterprise IT/security policy and cannot be self-built by the consuming team — making them the lowest-friction paid-tier justification even for sophisticated engineering teams.
Question: What percentage of OSS dev-tools companies (from a sample of 20 with >1K GitHub stars and >$5M ARR) use SSO/SCIM as the primary paid-tier gate vs. usage limits vs. support SLA vs. proprietary features? Name at least 5 specific examples and their pricing (e.g., Metabase SSO is Business tier at $500/month, PostHog SSO is Teams at $450/month, Grafana Cloud SSO is Pro at $8/seat).

**F5.** [P2]
Hypothesis: The failure mode for OSS monetization is not "nobody pays" but "the paying customers are too small to matter" — small teams pay $29-$99/month, but the economics only work at $500+/month per customer, which requires either large teams (50+ seats) or enterprise deals (annual contract, procurement cycle), and small-team PLG alone rarely generates $1M ARR.
Question: What is the minimum viable customer unit economics for a dev-tools OSS-to-SaaS business to reach $1M ARR in year 2? Specifically: if average monthly contract value is $150 (10-seat team at $15/seat), how many customers are needed vs. if ACV is $800 (50-seat team at $16/seat)? Compare to the actual customer count at $1M ARR for PostHog, Metabase, and Sentry in their early years — were they hundreds of small customers or dozens of mid-market ones?

---

## Research Plan

### Sources Phase 2 must consult

1. **Anthropic public communications** — Claude Code product announcements, pricing page, MCP standard documentation, blog posts on ecosystem intent (primary source for E1, E3)
2. **GitHub/LinkedIn job postings** — Anthropic Claude Code team headcount growth as proxy for investment level (B1 triangulation)
3. **Crunchbase / PitchBook** — funding rounds for Cursor, Cognition/Devin, Braintrust, LangGraph/LangChain, CrewAI (A2, C2)
4. **Product pricing pages (live as of Q2 2026)** — Cursor pricing, Copilot Business/Enterprise pricing, Devin current pricing, Braintrust/Langfuse pricing, JetBrains Marketplace developer guide (A3, C1, C2, C3, C5)
5. **Public ARR disclosures / press coverage** — Cursor $100M ARR (The Information, 2024), Copilot seat count (Microsoft earnings calls), Sentry/PostHog/Grafana public blog ARR milestones (C2, F3, F5)
6. **Open-core monetization research** — a16z "Open Source: From Community to Commercialization" (2023), OSS Capital portfolio analysis, Joseph Jacks / OSSC data on OSS conversion rates (F1, F3, F4)
7. **Developer surveys** — Stack Overflow Developer Survey 2024/2025 (tool adoption rates, willingness to pay), JetBrains State of Developer Ecosystem 2024 (B2, B3)
8. **Platform marketplace economics** — JetBrains Marketplace developer documentation (take-rate), Shopify Partner Program terms (take-rate history), VS Code Marketplace FAQ, Chrome Web Store policies (B4, C5)
9. **AWS platform-risk case studies** — CircleCI vs. GitHub Actions market share data (DevOps Research and Assessment reports), Elastic vs. OpenSearch market response (SEC filings, earnings calls) (E2)
10. **GitHub stars + download proxies** — ceos-agents repo star trajectory, comparable plugin repos (Cursor rules repos, Claude-Code community plugins) as install-base proxy (B1, D3)

### P1 vs. P2 classification

**P1 (must-answer for any spec):** A1, A2, A4, B1, B2, B3, C1, C2, C3, C4, D1, D2, E1, E2, F1, F2, F3

**P2 (nice-to-have, answer if time permits):** A3, B4, B5, B6, C5, C6, C7, D3, E3, F4, F5

### Deterministic (public data) vs. judgment-call questions

**Deterministic from public sources:** A1, A4, B4, C1, C3, C5, C6 (pricing pages, press coverage, product docs)
**Requires judgment + explicit assumptions:** B1, B2, B3, C2, C4, C7, D1, D2, D3, E1, E2, E3, F1, F2, F3, F4, F5

---

## Assumptions Inventory

The following 8 assumptions are NOT explicitly specified by Filip Sabacky and materially affect business-model design. Phase 2 answers must present these as sensitivity bands, not silent assumptions.

**ASM-1: Solo-founder vs. corporate initiative runway**
If Filip goes solo (CEO declines), the business must be cashflow-positive within 12-18 months on solo-founder economics (~$5K-$15K monthly burn). If it proceeds as a corporate initiative, a 24-36 month pre-revenue runway is acceptable. These are fundamentally different business models — the solo path requires a PLG product that converts without a sales team; the corporate path can afford 6+ months of enterprise sales cycles. *Why it matters: determines whether pricing is $49/month self-serve or $20K/year enterprise contract.*

**ASM-2: Geographic target market (EU vs. US vs. global)**
EU-primary means GDPR compliance for hosted runtime (data residency, DPA agreements), which adds 3-6 months to a hosted offering launch. US-primary means no GDPR overhead but requires US legal entity for enterprise sales. The OSS plugin is global by default; a SaaS wrapper is not. *Why it matters: affects hosted runtime cost structure and time-to-market by 6+ months.*

**ASM-3: Target company size (SMB vs. mid-market vs. enterprise)**
SMB (10-50 devs) means PLG, self-serve, $29-$199/month, 500+ customers needed for $1M ARR. Mid-market (50-500 devs) means inside sales, $500-$5K/month, 30-50 customers. Enterprise (500+ devs) means field sales, $20K-$200K/year ACV, 10-15 customers for $1M ARR. The tracker integrations (Jira, Linear, YouTrack) suggest mid-market+, but the OSS install profile skews individual/SMB. *Why it matters: the entire go-to-market motion and hiring plan changes by segment.*

**ASM-4: Willingness to close-source adjacent components**
The core plugin is MIT-licensed and cannot be un-published. But Claude-grade (the eval CLI) and the Asysta CEOS dataset are NOT MIT-licensed as far as the codebase context states. Filip's appetite for shipping a proprietary hosted runtime, proprietary agent registry, or proprietary data API is unspecified. *Why it matters: determines whether the paid layer is "services on top of OSS" (low defensibility) or "proprietary product with OSS front-end" (higher defensibility, potential OSS community backlash).*

**ASM-5: VC appetite vs. bootstrapped path**
A marketplace + hosted runtime + enterprise sales motion requires $2M-$5M seed to staff. A bootstrapped PLG path (hosted autopilot only, no sales team) is possible at $200K-$500K personal capital or customer-funded. Filip's presentation to CEO implies a corporate path is preferred, but solo fallback implies bootstrapped tolerance. *Why it matters: the VC path optimizes for growth/defensibility; the bootstrapped path optimizes for margin and speed to cashflow-positive.*

**ASM-6: LLM API cost absorption model**
A hosted autopilot tier must pay Anthropic API costs on behalf of customers (or pass them through). At claude-sonnet-4-6 rates, a single full bug-fix pipeline run (triage → fixer → reviewer → test → publish) costs approximately $0.50-$3.00 in API tokens depending on codebase size. A team running 100 automated fixes/month incurs $50-$300 in API costs. Whether this is absorbed into the subscription price or charged as usage-based overage is unspecified. *Why it matters: determines margin profile and pricing model of the hosted tier.*

**ASM-7: Anthropic partner / preferred-vendor status**
If Anthropic designates ceos-agents as a featured partner or marketplace anchor tenant, distribution cost drops to near-zero. If ceos-agents gets no special treatment, customer acquisition costs apply (dev-tools CAC: $500-$2K per paying customer via content/SEO; $5K-$15K via enterprise sales). Filip's relationship with Anthropic and likelihood of partnership status is unspecified. *Why it matters: CAC assumptions drive the unit economics by 3-5x.*

**ASM-8: Competitive moat timeline — 6-month cliff**
Any revenue model that requires >6 months to launch its first paid product must assume that Copilot Workspace and/or a native Claude Code pipeline will ship during that window, potentially eliminating the window. If the business model requires 12+ months to first revenue (e.g., building a marketplace), the competitive landscape at launch may be materially different from today. *Why it matters: determines whether the correct strategy is "launch fastest viable paid product in 60 days" vs. "build defensible platform over 18 months."*
