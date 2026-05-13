# Product Design — ceos-agents Marketplace + Autonomous Composer

**Author:** Lena Hofstätter (ex-Lovable Lead PD, ex-Bolt.new, ex-Figma Plugin Marketplace, ex-Raycast)
**Phase:** 3b brainstorm — UX-led companion-product framing
**Scope correction:** this is NOT a VC business-model variant. ceos-agents v6.9.1 shipped MIT. The question is: **what do we package alongside it, and what is the end-user journey through the combined product?**

---

## Framing position (read this first, everything else flows from it)

I have shipped three marketplaces — Figma Plugins, Raycast Store, Lovable Remixes. The one thing all three got wrong at launch and had to retrofit painfully was **the first 90 seconds**. A marketplace succeeds or dies in whether a user who arrived with zero intent walks away with one working artifact. Not a README. Not a signup. An artifact they can show a friend.

Therefore this document refuses to answer "what goes in the catalog?" before it has answered "what does the user see at T+15s, T+60s, T+180s?" Everything subordinate — editable vs. parameterized, pricing, tracker shape — is derived from that.

The product is three surfaces stitched into one journey:

1. **Catalog** (`ceos-agents.com`) — discovery of prompts/skills/agents with Claude-grade scores
2. **Composer** (`/compose/:slug`) — the run surface; autonomous end-to-end build
3. **Studio** (`/studio`) — post-run workspace: tracker + source-control + context-viz + usage, all wired to one run

Catalog is the billboard. Composer is the demo. Studio is the reason you come back tomorrow.

---

## 1. First-Time-User-Experience flow (30 steps)

**Persona:** Honza, 29, backend dev in Prague, has heard about Claude Code, never built a mobile app. Arrives from a HN thread titled "I built an Android app in 4 minutes by clicking one prompt." 11:40 PM, Friday.

1. **T+0s** — Lands on `ceos-agents.com`. Hero is not a logo wall. Hero is a single 12-second autoplay video (muted, subtitled): a cursor clicks a tile labelled "Android calorie tracker," then cuts to a phone screen showing a working app. One headline: **"Pick a prompt. Get an app. Keep editing it."** Below: a search bar pre-filled with `android calorie tracker` and a single `Run` button. No login wall. **Precedent: v0.dev landing, Bolt.new prompt-first hero.**

2. **T+4s** — Honza doesn't click Run. He scrolls. Below the fold is a live-updating grid of the top 12 prompts this week, each tile showing: thumbnail preview (auto-generated from last successful run), Claude-grade score badge (e.g. `A-`, 87/100), star rating (4.7 ★, 312 reviews), run count this week (1,243 runs), estimated cost range ($0.30–$1.20), estimated duration (4–7 min). **Precedent: Raycast Store tile density; Lovable's "trending remixes" grid.**

3. **T+12s** — He clicks a tile called **"Android kalorické tabulky"** (geo-localised CZ).

4. **T+13s** — Detail page loads in <400ms. Above the fold, side-by-side: left panel is a parameterized form with 4 fields auto-filled with sensible defaults (`app_name: "Calorie Tracker"`, `auth: "Google only"`, `database: "Firebase"`, `target_sdk: "Android 14"`). Right panel is a 30-second demo video of the last run. One big button: **`Run — est. $0.80, 5 min`**. Below: "Edit raw prompt" collapsed link, Claude-grade breakdown, 12 most recent reviews. **Precedent: Lovable Remix pre-fill; Replit Agent cost-preview.**

5. **T+20s** — Honza tweaks `app_name` to `"Kaloricka"`. The cost estimate does not change (parameter substitution is free). He clicks **Run**.

6. **T+21s** — Signup-wall appears **only now**, modal, and in the gentlest possible form: "We'll need a GitHub account to commit your app somewhere. Sign in with GitHub." Not "Create account. Verify email." Three fields become zero. **Precedent: Vercel deploy-first-ask-later.**

7. **T+35s** — OAuth round-trips. Returns to a Composer view. Free quota is shown in the top-right: **"You have 2 free composer runs. This run will use 1."**

8. **T+36s** — Composer view has three regions: (a) top band — progress stepper with 6 stages [`Parse prompt`, `Select agents`, `Assemble workflow`, `Generate code`, `Test`, `Deploy preview`], (b) main area — live-streamed log *and* a tabbed switcher (`Log / Context / Diff / Preview`), default tab is **Context**, (c) right rail — real-time usage graph (tokens, $ spent, elapsed time). **Precedent: Replit Agent split-view; Cursor background-agent run page.**

9. **T+40s** — Stage 2 begins: "Selecting agents." The Context tab renders a live graph — a node for the user prompt on the left; child nodes light up as agents are chosen: `spec-analyst (sonnet)`, `architect (opus)`, `fixer (opus)`, `test-engineer (sonnet)`, `publisher (haiku)`. Each node is clickable → shows the agent's system prompt, its Claude-grade score, and where it came from (marketplace). This is the Asysta-derived viz, re-skinned. **Precedent: LangGraph Studio; Temporal UI.**

10. **T+90s** — Honza switches to the Log tab and watches `fixer` write React Native code. Tokens counter in right rail ticks smoothly every 2s. He switches back to Context — a new agent (`browser-verifier`) just appeared, triggered mid-run because the workflow detected a web-dashboard sub-task. He understands: the composer is actually composing.

11. **T+180s** — A yellow banner appears: **"The composer is about to pick Firebase over Supabase. Change?"** Two buttons: `Let it continue` / `Intervene`. This is the mid-run intervention point — only prompted at load-bearing decisions, never for minor choices. **Precedent: Devin's "approve plan" prompt; Cursor's "resume/modify" mid-run.**

12. **T+182s** — Honza lets it continue.

13. **T+4m30s** — Stage 6 completes. Log ends with: `✅ Deployed to preview.vercel.app/kaloricka-a7f2 · Committed to github.com/honza/kaloricka · Tracker issue #1 created.` Three links. The Preview tab auto-opens to the running app in an iframe.

14. **T+4m45s** — He taps through the preview on a simulated Android viewport. Logs a meal. It works.

15. **T+5m** — A right-rail card slides in: **"Run summary. 1.2M tokens. $0.94. 4m 52s. Claude-grade post-run score: A- (89/100)."** Below, a `Share this run` button — creates a public URL `/r/honza/kaloricka-a7f2` with read-only viz, usage graph, and a "Remix this" CTA. **Precedent: Lovable remix-share; Claude-grade badge loop from Rafa's Phase 3 proposal.**

16. **T+5m10s** — Honza clicks `Open Studio`. Studio opens to a three-pane workspace: left = file tree (from the repo), center = tracker (issues + agent runs), right = agent activity history. Tab across the top: `Files / Tracker / Runs / Usage / Context`.

17. **T+5m30s** — He clicks the `Tracker` tab. One open issue: `#1 "App generated — add iOS support?"` auto-filed by the composer as a suggested next step. Status column header is not `Todo / In Progress / Done` but `Unclaimed / Agent-running / Needs-human-review / Done`. He sees the issue is `Assigned to: @fixer-agent` with a green dot. **This is the key delta vs Linear.**

18. **T+5m50s** — He clicks the issue. Description template is pre-filled with fields the agent needs: `acceptance_criteria` (3 bullets), `affected_files` (list), `complexity` (M), `estimated_tokens` (~400k). There's a **`Dispatch agent`** button. He clicks it. Another run starts.

19. **T+6m** — Free-quota counter ticks to 1/2.

20. **T+6m30s** — He clicks the `Runs` tab. Two runs are listed with the usage graph below — stacked bars for tokens per stage, line for $ cumulative across both runs ($1.56 total, free-quota value shown as "$5 equivalent free quota used"). **Precedent: Vercel observability tab; Anthropic Console dashboards.**

21. **T+7m** — Honza heads back to Catalog, searches `seo optimization`. 40 results. Filter pills at top: `By type: [Prompt · Agent · Skill · Workflow]`, `By score: [A / B / any]`, `By cost: [<$1 / $1-5 / $5+]`, `Verified only`, `Free only`. **Precedent: Figma Plugins search chips. Anti-pattern: JetBrains marketplace where filters are buried in a dropdown — avoided.**

22. **T+7m30s** — He clicks a Skill called `/seo-audit-and-fix`. Detail page has a **`Add to my project`** button instead of `Run`. Because Skills are reusable units, not one-shot runs.

23. **T+7m40s** — He adds `/seo-audit-and-fix` to his Kaloricka project. Studio side-panel confirms: "Skill added. Available in Composer as `/seo-audit-and-fix`."

24. **T+8m** — He triggers `/seo-audit-and-fix` against his repo. Second composer run begins. Free quota → 2/2. Banner appears: **"This is your last free run. After this, runs are metered."**

25. **T+11m** — Skill run completes. 0.3M tokens, $0.22. The run worked. He's now used all 2 free runs.

26. **T+11m10s** — Next navigation action — he clicks a third prompt in Catalog — triggers the **paywall moment**. Modal, single view: "You've used your 2 free composer runs this month. Three ways forward: (a) **Pro — $29/mo**, 50 runs + priority queue + private runs + private Claude-grade evals. (b) **BYOK — free**, bring your own Anthropic API key and we charge $0 infra. (c) **Wait 30 days** for your free quota to reset." Three buttons. **Precedent: Cursor's trial-exhausted modal; Lovable credit-exhausted modal. Anti-pattern: Figma's "contact sales" — avoided.**

27. **T+11m30s** — Honza picks BYOK because he has $10 in Anthropic credits lying around. Two fields: paste key, verify. Now he runs unlimited — but he sees a small badge "BYOK mode — no Claude-grade private evals, no priority queue."

28. **T+13m** — He runs a fourth prompt. Works.

29. **T+20m** — He shares `/r/honza/kaloricka-a7f2` on Twitter. Tweet embed shows the Claude-grade `A-` badge and the 4m52s runtime. Two friends click through. **Viral loop closes.**

30. **T+24h** — Email the next morning: "Your Kaloricka app had 3 remixes overnight. Top remix added Apple Health sync. Want to pull their changes?" CTA: **`Open Studio`**. He re-enters. Retention hook closed.

---

## 2. The "prompts editable vs. parameterized" decision

**Decision: BOTH, layered. Default to parameterized. Raw-edit is one click away.**

Every marketplace prompt is a file with two parts:

```yaml
---
name: android-kaloricke-tabulky
parameters:
  - name: app_name
    type: string
    default: "Calorie Tracker"
  - name: auth
    type: enum[google, email, apple, none]
    default: google
  - name: database
    type: enum[firebase, supabase, sqlite]
    default: firebase
  - name: target_sdk
    type: int
    default: 34
---

# Prompt body (freely editable in power mode)
Build an Android app named {{app_name}} that tracks daily calorie intake...
```

The Composer detail page renders:
- **Quick Run form** (default view): just the parameters as form fields. Novice runs in <30 seconds.
- **`Edit raw` button** (one click): collapses the form, shows the full prompt body with parameter tokens inline. Edits fork the prompt automatically to the user's library as `my-android-kaloricke-tabulky` (never overwrite upstream).

### Why not pick one?
- Pure parameterized (Lovable's original Remix flow) = novices love it, but power users feel caged and leave.
- Pure free-edit (raw prompt library, like PromptBase) = no trust signal, high-variance outcomes, cold-start killer.
- Layered = novice speed **and** expert depth, at the cost of one more concept (parameters block). The concept is discoverable because the Quick Run form *is* the parameter block rendered.

### Acceptance criteria
- Novice with zero context completes Quick Run in <30 seconds (measured by time-to-first-composer-start from prompt-page load).
- Expert can fork + customize in <2 minutes (measured by time to first commit to their forked prompt).
- **Forked prompts appear in `/my/prompts` with a `parent:` link** — discoverability is preserved, attribution is automatic.

### Inspiration precedent
- Lovable Remix + parameter pre-fill.
- Claude Code Skill frontmatter pattern (this is literally already our own convention).
- Figma Plugin Manifest — mandatory schema that enables tooling above it.

---

## 3. Marketplace item types — detail-page UX

| Type | Detail page above the fold | Key metadata | `Run` button action | `Fork` button action | Claude-grade display | Human reviews |
|---|---|---|---|---|---|---|
| **Prompt** | Parameterized form + 30s demo video of last run | parameters schema, est. cost, est. duration, target stack | Starts Composer → autonomous build | Copies prompt to `/my/prompts`, opens raw editor | Top-right badge (letter grade + 2-digit score); click → breakdown per rubric | Star rating + last 12 reviews, "Was this useful? Y/N" per review |
| **Skill** | Skill invocation example + screenshot of Studio integration | triggers (regex/intent), required config keys, dependencies (agents it dispatches) | `Add to my project` — installs to user's Studio | `Fork skill` — copies the SKILL.md into user's plugin namespace | Badge + an extra bar: "Compatible with X agents in your project" | Star rating. Reviews filterable by agent compatibility |
| **Agent** | Agent system prompt (first 200 chars, expand) + example runs | model (opus/sonnet/haiku), role tags (fixer/reviewer/etc), token-avg-per-invocation | `Dispatch` — opens a one-off task input field | `Fork agent` — copies the agent MD to user's agent library | Badge + "Benchmark: beats default fixer by 12% on AC-fulfillment" (if available) | Star rating + "dispatches this month" counter |
| **Workflow** (composed) | Graph visualization (composer's auto-assembled agent chain) + runtime stats from last 10 runs | parent prompt, agent list, est. cost, est. duration | `Run composed workflow` — same as prompt Run, but skips the compose step | `Fork workflow` — locks current composition as user's private skill | Aggregate score (weighted by step contribution) | Per-step reviews possible (power feature) |

**Design consistency note:** all four types share the same page chrome (hero, metadata band, reviews footer). They differ in the primary CTA and the metadata density. **Precedent: VS Code Marketplace — uses same shell for extensions/themes/snippets; different only in install target.**

### Claude-grade score UI convention
- **Letter grade primary** (A+/A/A-/B+/B/B-/C/D/F). Large. Colored.
- **Numeric detail on hover** (e.g. "89/100 · rubric: correctness 95, security 85, perf 78").
- **Public always** if the item is public. Private evals (paid tier) show a padlock badge and are visible only to the author.
- **Badge is embeddable everywhere** (README, personal site, marketplace detail page) — Rafa's Phase 3 viral insight is salvageable and correct.

---

## 4. Autonomous composer flow — concrete

**Trigger:** user clicks `Run` on the "Android kalorické tabulky" prompt detail page.

**Sequence:**

1. **Frontend commits Run** (client-side): collects parameter values, shows a single spinner for <800ms.
2. **Backend creates a `run_id`** (format `{user}_{slug}_{timestamp}`) and opens a Server-Sent Events stream to the browser.
3. **Composer starts Stage 1 — Parse:** `spec-analyst` is dispatched with the prompt + parameters. Emits EARS-style requirements. Browser renders them in the Context tab as a bulleted list, ticking in as they stream.
4. **Stage 2 — Select agents:** a meta-selector scans the user's available agents (marketplace + installed) and matches them to requirements. Dispatches `architect` to produce the task tree. Context tab grows — nodes light up left-to-right.
5. **Stage 3 — Assemble workflow:** the composer writes an ephemeral SKILL.md to `.ceos-agents/runs/{run_id}/workflow.md`. This skill is visible in Studio → Files tab (read-only). **Design decision: the composed workflow IS a skill file, exactly as user envisioned.** Savable to user's library post-run.
6. **Stage 4 — Generate code:** `fixer` + `test-engineer` iterate. Log tab streams the diff live. Right rail usage graph updates every 2 seconds. Context tab shows which agent is active (pulsing node).
7. **Load-bearing-decision guard:** if the workflow hits a branch point with >1 viable path (e.g. Firebase vs Supabase), composer pauses and raises an intervention banner. Timeout 60s → defaults to the spec-analyst's initial pick. User can `Intervene` → side-chat opens, user types preference, composer resumes.
8. **Stage 5 — Test:** smoke build + unit tests run. If they fail, composer retries up to `Fixer iterations` limit from config (default 5). Failures appear as red checkmarks in the stepper.
9. **Stage 6 — Deploy preview:** three artifacts in parallel: (a) Vercel preview URL for web dashboards, (b) GitHub commit on a new branch, (c) tracker issue. All three links appear in the Log as the last 3 lines, also in a right-rail "Artifacts" card.
10. **End state:** Preview tab auto-opens to the deployed URL. Run summary card renders at right. Claude-grade post-run evaluation runs async (30-60s after completion) and updates the summary card when ready. User can now either: click `Open Studio` for the workspace, click `Share run` for the public URL, or click `Run again with different params`.

### UI specifics

- **No chat interface by default.** Composer run is a dashboard, not a conversation. Mid-run intervention uses a sidebar chat only when triggered. **Precedent: Replit Agent stepper > Devin's chat. Lovable switched from chat to preview-first in 2024 — retention improved.**
- **Context-viz inline during run** (Context tab is default view on composer page, not a separate tab). Side panel in Studio post-run. **NOT a separate app.**
- **Usage graph real-time** (right rail, updates every 2s). End-of-run summary consolidates. **Both, not either-or.**
- **Diff view available via tab, not dominant.** Most users don't read the diff during run. Power users can. **Precedent: GitHub Actions UI — logs primary, diff secondary.**

### Deploy targets
- **Default: all three.** Vercel preview (for UI), GitHub commit (for code), tracker issue (for follow-up).
- User can toggle each in Quick-Run form advanced settings (collapsed by default).
- Self-host escape: BYO deploy target via MCP (e.g. point to user's own Vercel team, own GitHub org, own tracker).

---

## 5. Paywall mechanics — the critical UX moment

**Primary mechanic: composer runs per month, hard cap, soft-landing ramp.**

- **Free tier:** 2 composer runs per calendar month. Full Studio access. Full catalog browse + read-only eval scores. Unlimited Skill/Agent install (no run). BYOK always free.
- **Pro tier ($29/mo):** 50 composer runs/month. Private runs (not indexed in public feed). Private Claude-grade evals. Priority queue. Usage graph + cost breakdown exports.
- **Team tier ($99/seat/mo, min 3 seats):** shared Studio, SSO, team tracker, agent-usage policies, audit log.
- **Enterprise (custom):** on-prem Studio, custom trackers, SLA.

**Why runs, not tokens:** tokens are opaque to end users. A run has a clear beginning and end. A run is a "thing I did today." Counting tokens is an accountant's metric, not a UX metric. **Precedent: Cursor switched from token-based to request-based pricing specifically for this reason.**

**What counts as "a run":**
- One composer invocation = 1 run, regardless of retries inside the run. Fixer-reviewer iterations are bundled.
- Skill dispatch from Studio ("Add + Run `/seo-audit`") = 1 run.
- Agent direct-dispatch from the Agent detail page = 1 run.
- Forking a prompt = 0 runs.
- Reading a run's public URL = 0 runs.
- Claude-grade eval on your own code = 0 runs (evals are on Claude-grade free tier, separately).

**Trigger point design (Honza's paywall moment at step 26):**
- Modal appears on the *next* run attempt after quota is exhausted, never mid-run. **Never interrupt a run-in-progress with a paywall. Cardinal rule.**
- Modal offers three paths, not one (Pro, BYOK, Wait). BYOK is the escape valve that prevents "this feels like a trap." **Precedent: Claude Code's own API-key escape hatch.**
- Modal shows the value the free tier already gave ("2 runs completed, $1.50 infra value consumed").

**Why this survives the platform-risk scenarios from Phase 2:**
- If Anthropic ships native autonomous composer → our paywall is on the *workflow composition* + the *Studio context*, not the raw LLM call. BYOK even accepts that scenario gracefully.
- Free tier must deliver the viral loop (2 runs = 1 app shipped + 1 shared URL). Paid tier gates "I'm building a second serious thing."

**Anti-patterns I am deliberately avoiding:**
- "Enter credit card to start trial" (Bolt.new 2024 mistake, backed out).
- "Unlimited for 14 days then $0 afterward" (no commitment signal, conversion craters).
- "Token usage meter visible always" (anxiety-inducing, suppresses usage, hurts viral).

---

## 6. Tracker + source-control integration UX

**Decision: Tracker is a first-class product. Source-control is a Git frontend + agent-metadata layer, NOT a custom VCS.**

### Why not custom VCS
Git has won. Every tool in the pipeline already speaks Git. Building a custom VCS forces every integration to re-plumb. Cold-start catastrophic. **Precedent: Pijul, Fossil, Sapling — all technically superior, all commercially dead.**

What we *can* build is a Git-aware metadata layer: commits tagged with `run_id`, agent-signed commits (GPG with agent-specific key derivation), branch conventions optimized for agent runs (e.g. `agent/fixer/run-123`).

### Agent-native tracker — concrete differences vs Linear/Jira

| Dimension | Linear/Jira | ceos-agents tracker |
|---|---|---|
| Statuses | Todo / In Progress / In Review / Done | **Unclaimed / Agent-running / Needs-human-review / Blocked / Done** |
| Assignee dropdown | List of humans | **List of humans + list of agents + `Auto-select`** |
| Issue description | Free-text | **Template enforced**: `acceptance_criteria`, `affected_files`, `complexity`, `estimated_tokens`, `blocking_dependencies` — agent-consumable |
| Columns on board | Custom | **Agent activity feed column** is first-class — shows the stream of dispatches + outcomes for any issue |
| "Comments" | Humans only | **Humans + agent system messages** (clearly distinguished styling); agent messages include token-spend footer |
| Labels | Manual | **Auto-labelled** from Claude-grade post-run (`needs-decomposition`, `ac-not-fulfilled`, `security-review`, `flaky`) |
| SLA clock | Days | **Token-budget clock**: "Issue has consumed 1.2M of 2M token budget; 60% remaining." |
| Webhooks | Generic | **Pre-baked ceos-agents events** (`agent-blocked`, `ac-fulfilled`, `pipeline-completed`) |
| Linked PR status | Badge | **Inline diff preview + Claude-grade delta** ("This PR raised the repo score from B+ to A-") |

### The issue lifecycle in the new tracker

1. Issue created (by human, by composer auto-file, or by webhook from external tracker).
2. Agent auto-dispatched if `assignee == agent` (pipeline triggers ceos-agents skill).
3. Agent streams progress to activity feed; Studio Tracker tab updates live.
4. Agent files PR → PR appears as linked artifact with Claude-grade delta.
5. Either (a) human reviews and merges, or (b) acceptance-gate agent auto-approves if AC fulfilled.
6. Issue closes. Token budget + Claude-grade delta saved to history.

### Source-control UX
- A Git frontend that displays commits with `agent/run_id` metadata enriched.
- Branch visualizer that shows which branches are agent-work vs human-work.
- Commit-level "explain this commit" button → replays the run that produced it from `.ceos-agents/` state.
- **The repo itself is standard Git, hosted on GitHub or Gitea.** We don't host; we *visualize and enrich.*
- Rationale: lets us integrate with user's existing Git setup (huge) and hedges against any "source-control lock-in" fear.

### Bundled or separate apps?
**Single bundled Studio app.** Tracker tab + Source tab + Runs tab + Usage tab + Context tab. One cohesive workspace, one login, one theme. **Precedent: Linear's single-app ethos beats Jira's fragmented app sprawl.**

---

## 7. Context-viz and usage-graph packaging

**Decision: Embedded in Studio AND a standalone free tool. NOT a separate paid product.**

### Why both
- **Embedded in Studio** because the viral loop requires it (users see it mid-run, share it post-run).
- **Standalone free tool at `viz.ceos-agents.com`** because the existing Asysta NDJSON graphs are shippable today per Phase 2 and serve as a second viral-loop surface for users who haven't bought into the full ecosystem.
- **NOT paid** because the data is not proprietary — it's the user's own run metadata. Monetizing user-owned observability is a betrayal pattern, and the backlash is not worth the marginal revenue.

### Reuse Asysta NDJSON or build fresh?
**Reuse the NDJSON schema.** Re-skin the renderer. Here is the argument:
- Asysta's NDJSON graph schema is already proven (CEOS dataset exists).
- Schema stability = easier to plug into Studio post-run snapshot dumps.
- A complete rewrite burns 4-6 weeks for zero-visible-difference outcome.
- Re-skin: new CSS/layout tuned to Composer's single-run view (not org-wide CEOS dataset view) — 1 week.

### Usage-graph specifics
- Real-time line chart: $ cumulative, stacked by agent.
- Token-per-stage bar chart: finalized on run completion.
- **Exportable as PNG/SVG** (Pro feature, because "I want a pretty chart for my CTO" = real enterprise signal).
- **Shareable URL** (free: public runs auto-share; paid: private runs stay private).

---

## 8. FTUE anti-patterns to avoid (5)

1. **Empty-catalog cold start.** Figma Plugins launched with 12 plugins, looked barren; Raycast launched with 40+. *Our rule:* **seed the catalog with 50 high-quality prompts, 20 agents, 10 composed workflows BEFORE public launch.** All authored or curated by us. Each with Claude-grade A- or better. Don't ship a barren catalog to HN.

2. **Search without filters.** PromptBase's search is one input with no facets; users bounce at 60%. *Our rule:* filter chips visible above-the-fold on catalog listing (type, score band, cost band, verified-only). Never bury filters in a dropdown.

3. **Pricing hidden until signup.** Factory.ai, pre-2025, had "Contact us for pricing." *Our rule:* **pricing page public, all tiers with numbers, linked from every run-page footer.** Honest $29/mo > mysterious "Enterprise." Even enterprise tier says "custom, starting $X."

4. **First-run demands signup before value.** Bolt.new 2024 required email+password before showing the prompt UI — conversion dropped 20%. *Our rule:* **landing-page hero is interactive without auth.** Signup only triggers at "I want to save my artifact / need GitHub." Value first, account second.

5. **Run history buried.** Cursor's background-agent history was 3 clicks deep pre-2026. Users lost runs. *Our rule:* **Studio > Runs tab is one click from any composer screen; URL-shareable; retained forever (even on free tier).** Observability is not a paid feature; it's a usability requirement.

---

## 9. MVP — what ships in week 1 of public marketing

**Hard strip-down. Everything non-essential is v2.**

### Ships in Week 1 (the demoable MVP)
- **Catalog** (`ceos-agents.com`) with **25 seeded prompts, 10 agents, 5 composed workflows** (all with Claude-grade A- scores, all authored by us). Search + 4 filter chips. Prompt detail page with parameterized form + raw-edit.
- **Composer** for prompts only (skills/agents/workflows dispatch is v2). Stages 1–6. Context tab + Log tab + Preview tab. Right-rail usage graph (real-time). Intervention banner at load-bearing decisions (1 hardcoded heuristic: database choice).
- **Studio** with Files tab + Runs tab + Usage tab (basic). Tracker tab in read-only form (issues auto-filed by composer visible, manual create disabled in week 1).
- **Claude-grade scoring** — pre-run score on detail page + post-run score in run summary. Public badges embeddable. (Private evals = v2.)
- **GitHub auth** only (Gitea/GitLab OAuth v2).
- **Paywall** — 2 free runs/month + BYOK mode + Pro ($29/mo) tier with Stripe. Team + Enterprise not live week 1.
- **Share URLs** for public runs (critical for viral loop).
- **Landing-page hero video** (12 seconds, showing one prompt→app flow end to end).
- **Docs** — one "Getting started" page, one API/BYOK page, one "Claude-grade scoring rubric" page.

### Explicitly NOT in week 1
- Skill dispatch from catalog ("Add to my project").
- Agent direct-dispatch page.
- Workflow remixing.
- Mid-run intervention side-chat (only the banner, no interactive chat).
- Tracker full write path (create/assign/status-change UI).
- Source-control enrichment views beyond commit-list-with-run_id-badge.
- Standalone viz tool (`viz.ceos-agents.com`) — week 3.
- Team tier / SSO / audit log.
- Mobile app.
- MCP integration for BYO deploy targets (MCP is a dev-focused audience; wait for inbound).

### Why this strips to the bone
Week-1 marketing demo is this: a single prompt → a working Android app → shared URL → Claude-grade badge → embedded README. That's it. Everything else is there to not-embarrass-us, not to dazzle. Dazzle is weeks 2–6.

---

(end — ~3850 words)
