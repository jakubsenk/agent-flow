# Phase 2 Research Answers — Consolidated Index

**Generated:** forge-2026-04-23-001 Phase 2 synthesis
**Method:** Disjoint parallel scope (no merge needed — Agent A owned Clusters A/D/E + competitor-table + platform-risk; Agent B owned Clusters B/C/F + market-sizing + assumptions)

## Artifacts

| File | Scope | Owner |
|------|-------|-------|
| `answers-partA.md` | Clusters A (competitive), D (moat), E (platform risk) | Agent A |
| `answers-partB.md` | Clusters B (market), C (pricing), F (OSS-tension) | Agent B |
| `competitor-table.md` | 14+ row competitive landscape | Agent A |
| `market-sizing.md` | TAM/SAM/SOM for 6 revenue streams | Agent B |
| `assumptions.md` | 5-10 material assumptions with sensitivity | Agent B |
| `platform-risk.md` | 4 Anthropic scenarios with probability + horizon | Agent A |

## Phase 2 Key Findings (orient Phase 3 brainstorm)

### Thesis-altering facts

1. **Basic "autonomous bug-fix" is commoditized.** Claude Code natively runs test-fix loops at 87.6% SWE-bench Verified; Claude Managed Agents is a fully autonomous cloud environment. A business model of "we sell autonomous coding" is DEAD. ceos-agents must sell **orchestration depth + niche tracker support** (YouTrack/Redmine/Gitea) + **enterprise controls**, not raw autonomy.

2. **Market repriced from $500 → $20/mo.** Devin crashed from $500 to $20/mo; Cursor background agents at $20/mo; Factory.ai at $20/mo. **WTP ceiling for individual devs is $20-80/mo.** Enterprise ACV can remain high but must be negotiated custom. Per-outcome pricing (per issue resolved, e.g., Devin ACU $2.25/15min) is more defensible than per-seat for autonomous agents.

3. **Marketplace take-rate is near-zero economically.** Anthropic already runs free plugin/skills registry. VS Code pattern (0%) is more likely than JetBrains pattern (15-30%). Stream-2 (marketplace) SOM base = $150k Y1 and collapses to $0 if Anthropic maintains zero-take-rate. **Marketplace alone is not a business.** It is a distribution mechanism for other paid layers.

4. **OSS → paid conversion is 0.5-3%, not 5-15%.** Elastic ~1%, Confluent <1%, PostHog ~2%, dbt Core ~10% (outlier with commercial Cloud gate). Without hard gate (SSO/SCIM mandate, usage quota, ops-burden trigger at ≥10 devs), ceos-agents will convert near 0%.

5. **Plugin API has no stability SLA.** GitHub issue #487 (March 2026) asking about deprecation timelines OPEN AND UNANSWERED. Any plugin-only business model is existentially fragile. **A VS Code extension + GitHub App distribution layer is required as a hedge.**

### Revenue-stream ranking (Agent B market sizing)

| Rank | Stream | Y5 SOM (base) | Time-to-first-revenue | Viability |
|------|--------|---------------|----------------------|-----------|
| 1 | Hosted Autopilot SaaS | ~$54M | 3-6 months | ✅ strongest |
| 2 | Claude-grade Eval SaaS | smaller | **30-60 days** | ✅ fastest, already shippable |
| 3 | Enterprise niche-tracker support | custom ACVs | 6-12 months | ✅ high-margin, defensible |
| 4 | Agent-native tracker SaaS | mid | 12-18 months | ⚠ requires MVP build |
| 5 | Marketplace take-rate | ~$0-150k | — | ❌ not standalone viable |
| 6 | Agent-native source-control | small | 18-24 months | ❌ cold start, Git dominance |

### Anthropic platform-risk summary

| Scenario | Probability | Horizon | Revenue impact |
|----------|-------------|---------|---------------|
| Monetized marketplace take-rate | M (30-45%) | 12-24mo | FATAL for Stream 5 only |
| Native Jira + Linear integration | **H (60-70%)** | 12mo | SEVERE for plugin-only; **ZERO for YouTrack/Redmine/Gitea niche** |
| Native AGENTS.md eval score | M (30-45%) | 12-24mo | FATAL for basic Claude-grade; LOW for LLM improvement layer |
| Full-pipeline autonomous composer | **H (65-75%)** | 12mo | FATAL for plugin-only composer; MODERATE for enterprise-niche-tracker hosted runtime |

### Decision-blocking data gaps (Phase 3 must make explicit assumptions)

1. Claude Code paying developer seat count (18.9M MAU includes all Claude; CC subset unknown — assume range 500K-2M)
2. Anthropic enterprise marketplace take-rate (private — model both 0% and 20% scenarios)
3. Factory.ai / Devin enterprise ACV + churn (private — stated assumption required)
4. ceos-agents addressable AGENTS.md corpus size (LOW confidence — low thousands)
5. CEO outcome — known by end of today (binary assumption ASM-1)
6. Claude-grade + Asysta licensing intent (ASM-4 — user must clarify)
7. Anthropic API cost per pipeline run (ASM-6 — must measure, not estimate)

## Phase 3 Brainstorm Mandate

Given the above, the brainstorm phase MUST produce business-model variants that:

- **Survive "Anthropic ships native X"** for X ∈ {marketplace, Jira/Linear integration, eval, composer} — explicit mitigation per variant
- **Anchor pricing at $20-80/mo individual / custom enterprise ACV** — not $200+/mo
- **Leverage the 3 niche trackers** (YouTrack, Redmine, Gitea) as moat, NOT the commoditized big-3 (Jira, Linear, GitHub)
- **Have a hard OSS→paid conversion gate** in every variant (SSO/SCIM, usage cap, team size trigger, hosted runtime, proprietary data)
- **Use the marketplace as distribution mechanism, NOT as primary revenue stream**
- **Address the plugin API fragility** via VS Code / GitHub App / Slack / MCP-broader distribution hedge
- **Distinguish corporate-initiative vs. solo-founder paths** explicitly (different cost structures, different pricing tolerance, different governance)
- **Identify Claude-grade as 30-60 day quick-revenue MVP** regardless of long-term variant chosen

Each variant will be scored on: revenue scalability, moat durability, platform-risk resilience, MVP time-to-market, capital requirement, corp-vs-solo fit.
