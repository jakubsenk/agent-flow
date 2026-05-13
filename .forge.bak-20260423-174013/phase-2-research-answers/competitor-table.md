# Competitive Landscape Table

**Produced by:** Phase 2 Research Agent A (Mira Halen)
**Date:** 2026-04-23
**Scope:** All competitors named in Phase 1 Cluster A questions plus additional relevant entrants

All prices in USD. Est. ARR/users flagged with confidence band. Sources in last column.

---

| Product | Parent company | Category | Entry price ($/user/mo) | Mid tier | Enterprise | Est. ARR or users | Funding/stage | Key differentiator | Key weakness | Source |
|---------|---------------|----------|------------------------|----------|------------|-------------------|---------------|--------------------|--------------|--------|
| **Cursor** | Anysphere | AI IDE (autonomous agent) | $0 (Hobby) / $20 (Pro) | $60 (Pro+) | Custom (Enterprise) | $2B ARR (2026, single-source aggregate — LOW confidence for exact figure); 2M+ users | $900M raised; $9.9B valuation (late 2025) | Background agents at $20/month; $2B ARR ramp velocity; IDE-native with agent autonomy | No native tracker integration (manual copy-paste issues); credit-based metering penalizes heavy agent use | cursor.com/pricing; neuriflux.com/blog/claude-code-review-2026 |
| **GitHub Copilot (Individual/Pro)** | Microsoft/GitHub | AI IDE assistant | $0 (Free) / $10 (Pro) | $39 (Pro+) | N/A (see Business/Enterprise rows) | 4.7M paid subscribers (Jan 2026); 20M total users | Subsidiary of Microsoft | Largest installed base; native GitHub Issues integration; bundled in VS Code | Limited tracker integration (Jira/Linear via MCP only; no YouTrack/Redmine); Workspace still maturing | docs.github.com/en/copilot/get-started/plans; getpanto.ai/blog/github-copilot-statistics |
| **GitHub Copilot Business** | Microsoft/GitHub | Autonomous coding agent (team) | $19/user/mo | N/A | N/A (see Enterprise row) | 50,000+ org deployments | Subsidiary | Centralized policy, agent mode GA March 2026 | No YouTrack/Redmine native integration; Jira requires MCP setup | docs.github.com/en/copilot/get-started/plans |
| **GitHub Copilot Enterprise** | Microsoft/GitHub | Autonomous coding agent (enterprise) | $39/user/mo | N/A | $39/user/mo (Enterprise tier) | 90% of Fortune 100 deployed | Subsidiary | Copilot Workspace autonomous PR from GitHub Issues; agentic code review GA March 2026; GitHub source-control lock-in | Requires GitHub as source control; no cross-tracker (YouTrack/Redmine) pipeline | docs.github.com/en/copilot/get-started/plans |
| **Cognition Devin** | Cognition AI | Autonomous software engineer | $20/mo (Pro) | $80/mo (Teams flat rate) | Custom (SAML/SSO/SLAs) | UNKNOWN (private) | $175M raised; ~$2B valuation (est. 2024, may be stale) | Native Jira + Linear + GitHub/GitLab integrations; ACU-based pay-as-you-go overage; true autonomous operation (not IDE-assisted) | Repriced from $500 → $20 reveals $500 WTP ceiling failed; ACU cost ($8–9/hr) adds up for long tasks | devin.ai/pricing; venturebeat.com/programming-development/devin-2-0 |
| **Replit Agent** | Replit | Greenfield app generation + hosting | $25/mo (Core) | $100/mo (Pro, Turbo mode) | Custom | UNKNOWN (private); millions of users on platform | ~$1.16B raised | Integrated IDE + hosting + agent; effort-based pricing; 200min autonomous session | Greenfield-only; no issue-tracker-driven PR creation for existing codebases; no YouTrack/Redmine/Gitea | replit.com/pricing; blog.replit.com/introducing-agent-3 |
| **Bolt.new** | StackBlitz | Greenfield vibe-coding | Free tier / ~$20/mo | n/a | n/a | UNKNOWN | StackBlitz (Series A, ~$7.9M — stale, likely subsequent rounds) | Instant browser-based full-stack generation; no setup required | No tracker integration; greenfield only; no test-run loop for existing repos | bolt.new; stackblitz.com |
| **v0.dev** | Vercel | UI component generation | Free / usage-based | Usage-based | n/a | UNKNOWN (Vercel product line) | Vercel Series E, ~$250M raised | One-click Vercel deployment; React/Tailwind specialist; viral adoption | UI/frontend only; no backend, no issue tracking, no test loops | v0.dev |
| **Lovable** | Lovable (formerly GPT Engineer) | Greenfield app generation | $20/mo (Starter) | $50/mo (Pro) | Custom | UNKNOWN (private) | Seed/Series A (est., not confirmed) | Natural language to full-stack app; GitHub sync | Greenfield only; listed in Anthropic enterprise marketplace — may become direct Anthropic distribution channel | lovable.dev; claude.com/platform/marketplace |
| **Factory.ai** | Factory AI | Autonomous dev lifecycle (Droids) | $20/mo (Pro) | $200/mo (Max) | Custom | UNKNOWN (private); enterprise customers: Nvidia, Adobe, EY, Palo Alto Networks | $150M Series C @ $1.5B valuation (April 2026, Khosla) | Full SDLC automation; model-agnostic (Claude + DeepSeek); native Jira + Linear integrations; cloud + local agent | No YouTrack/Redmine/Gitea; token-based billing complexity; $1.5B valuation requires enterprise ACV to justify | factory.ai/pricing; tech-insider.org/factory-ai-150-million-series-c |
| **Tempo Labs** | Tempo Labs | React component generation (Figma-to-code) | UNKNOWN (freemium reported) | UNKNOWN | UNKNOWN | UNKNOWN (early stage) | Seed (est.) | Figma design-to-React code; frontend specialist | Very narrow scope; no issue tracking, no backend, no test automation | tempolabs.ai (accessed 2026-04-23 — pricing page not publicly detailed) |
| **Claude Code (as platform)** | Anthropic | AI coding agent / platform host | $20/mo (Claude Pro includes Claude Code) | $100/mo (Team Premium with SSO/SCIM) | $39+/seat (Enterprise with API consumption commitment) | 18.9M Claude MAU (web); $2.5B Claude run-rate (Feb 2026); Claude Code users not separately disclosed | $7.3B+ raised; $61.5B valuation (est. 2025–2026) | Native "run tests + fix" loop (87.6% SWE-bench); managed agents; open MCP standard; 97M MCP installs | No native YouTrack/Redmine/Gitea; plugin API stability not guaranteed; issue tracker integrations require MCP setup | anthropic.com; getpanto.ai/blog/claude-ai-statistics |
| **CrewAI** | CrewAI Inc. | Multi-agent orchestration framework | $0 (50 executions/mo) | $99/mo (100 executions) | $120K/year (Ultra) | UNKNOWN (private) | Seed funded | Framework-level flexibility; Jira integration documented; enterprise execution quotas | NOT a plug-and-play pipeline (requires engineering to configure); different buyer persona (platform engineers vs. dev-team leads); no autonomous PR creation pre-built | crewai.com/pricing; lindy.ai/blog/crew-ai-pricing |
| **Braintrust** | Brainrust Data, Inc. | LLM evaluation + tracing platform | $0 (OSS SDK) | Usage-based (projects/logs) | Custom | UNKNOWN (private) | Series A (est.) | Eval + tracing + prompt management; integrates with any LLM | Not a coding agent; different buyer (ML engineers, not dev-team leads); does not evaluate agent definitions (AGENTS.md), only LLM outputs | braintrust.dev |
| **Langfuse** | Langfuse GmbH | LLM observability + tracing (open-source) | $0 (OSS self-hosted) | $59/mo (cloud, Hobby) | Custom | UNKNOWN; OSS with MIT license | Seed-stage (est.) | Open-source, self-hostable; integrates with all major frameworks; EU-hosted option for GDPR | Observability only (no agent orchestration, no tracker integration, no PR generation); different buyer persona than ceos-agents | langfuse.com; github.com/langfuse/langfuse |
| **OpenHands (formerly OpenDevin)** | All Hands AI | Open-source autonomous coding agent | $0 (self-hosted) | Cloud service (pricing UNKNOWN) | UNKNOWN | Open-source; VC-backed (Series A, $100M est. 2025 — unconfirmed) | Most starred autonomous agent repo; broad community; SWE-bench competitive scores | No native multi-tracker pipeline; requires self-hosting expertise; no structured acceptance criteria workflow | github.com/All-Hands-AI/OpenHands |
| **Linear Cyrus** | Linear | Issue-driven autonomous coding (native to Linear) | Bundled with Linear (pricing UNKNOWN as add-on) | n/a | n/a | UNKNOWN (pilot, not GA) | Linear is well-funded ($35M+ raised) | Native Linear integration; runs on Claude Code; closes issues autonomously; no config required for Linear users | Linear-only; no support for Jira, YouTrack, Redmine, Gitea, GitHub Issues; narrow scope | builder.io/blog/claude-code-with-jira; linear.app/integrations |
| **ceos-agents** | Filip Sabacky (indie) | Autonomous bug-fix + feature pipeline plugin | $0 (MIT open-source, self-hosted) | N/A (no paid tier yet) | N/A | 0 (pre-revenue) | Pre-seed / bootstrapped | 6-tracker support (YouTrack, GitHub, Jira, Linear, Gitea, Redmine); 21-agent orchestration; acceptance criteria loop; MIT-licensed; pure markdown (no runtime dependencies) | No hosted runtime; no paid tier; API stability risk (Anthropic Skill tool); solo founder capacity constraint; zero distribution today | github.com/ceos-agents (v6.9.1) |

---

## Summary: Integration Coverage Matrix

| Tracker | Copilot Workspace | Cursor BG Agent | Factory.ai | Devin | ceos-agents |
|---------|------------------|-----------------|------------|-------|-------------|
| GitHub Issues | Native | No | Yes | Yes | Yes |
| Jira | Via MCP (setup req.) | No | Yes (native) | Yes | Yes |
| Linear | Via MCP (setup req.) | No | Yes (native) | Yes | Yes |
| YouTrack | No | No | No | No | **Yes** |
| Redmine | No | No | No | No | **Yes** |
| Gitea | No | No | No | No | **Yes** |

ceos-agents' unique moat: YouTrack + Redmine + Gitea — niche trackers with no competitor coverage as of April 2026.

---

## Pricing Tier Comparison: Autonomous Issue-to-PR

| Product | Entry price for autonomous issue→PR | What's included |
|---------|-------------------------------------|-----------------|
| GitHub Copilot (Pro) | $10/mo | Basic agent mode; GitHub Issues only |
| GitHub Copilot (Business) | $19/user/mo | Cloud agent + org policy controls |
| Cursor (Pro) | $20/mo + MAX surcharge | Background agents; no tracker native |
| Devin (Pro) | $20/mo + ACU overage | Jira + Linear native; pay-as-you-go |
| Factory.ai (Pro) | $20/mo | Jira + Linear + GitHub; token-based billing |
| Replit Agent (Core) | $25/mo | Greenfield only; no existing-codebase tracker |
| Devin (Teams) | $80/mo flat | Unlimited team members; Jira + Linear |
| ceos-agents | $0 (self-hosted) | All 6 trackers; multi-agent orchestration |

*Note: Market has converged at $20/month entry price for individual autonomous agents. Per-seat enterprise deals range from $39/user/mo (Copilot Enterprise) to custom six-figure ACV.*
