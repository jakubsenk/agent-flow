# Persona C: The User Advocate

I have conducted 100+ usability studies. I care about what happens when things go wrong, how many concepts a user must hold in their head at once, and whether the "obvious" path leads to success or to a cryptic error 20 minutes later.

Before evaluating designs, let me map the five user journeys against the current plugin to identify exactly where the friction lives:

**Journey 1 ("I have an idea"):** `/scaffold` works end-to-end today. The cliff comes at the end: the Final Report says "fill in TODO sections" and lists `/check-setup`, but never mentions `/onboard --update` — the user must know that command exists. That is the first pit-of-failure.

**Journey 2 ("scaffolded yesterday, add a feature"):** The user must: (a) manually edit CLAUDE.md TODOs or discover `/onboard --update`, (b) run `/init` to set up MCP, (c) run `/check-setup`, (d) create an issue in the tracker, (e) run `/implement-feature ISSUE-ID`. That is 5 steps across 4 commands, with no single command that checks "are you ready?" Five concepts: TODO placeholders, MCP servers, config validation, issue tracker cards, feature pipeline. If they skip step (c) and go straight to (e), it fails at MCP pre-flight with a message pointing them to check-setup. Recoverable, but irritating.

**Journey 3 ("10 features planned"):** No batch feature command exists. The user must run `/implement-feature` ten times manually. There is no `/implement-features` (plural) analogous to `/fix-bugs`. Each invocation is independent with no shared state.

**Journey 4 ("deploy locally with DB"):** Nothing exists. The user is on their own with `docker compose up`. Zero plugin support.

**Journey 5 ("something broke during scaffold"):** `/resume-ticket` handles bugs and features but does NOT handle scaffold runs. Scaffold state lives in `.ceos-agents/scaffold-{timestamp}/` but no command reads it for resume. If scaffold crashes at Step 7 (feature loop), the user must restart from scratch or manually figure out what was committed.

---

## Idea 1: The Golden Path — Fix the Handoff, Not the Architecture

**Description:** Instead of adding new commands, fix the existing gaps that make the scaffold-to-feature transition painful. Three surgical changes: (1) Add `/onboard --update` to scaffold's Final Report next-steps, (2) Add a "readiness gate" to `/implement-feature` that runs config validation (check-setup Block 1) before mutating any state, (3) Add `/scaffold-resume` as an alias for `/resume-ticket` that understands scaffold state files. No new agents, no new config sections, no new concepts for the user to learn.

**User Journey:**
```
User: /scaffold "task management app with Postgres"
  → (scaffold runs, generates project, CLAUDE.md has TODOs)
  → Final Report now says:
    1. Run /ceos-agents:onboard --update to fill in TODO sections (interactive wizard)
       — OR edit CLAUDE.md manually
    2. Run /ceos-agents:init to configure MCP servers
    3. Run /ceos-agents:check-setup to validate everything
    4. Create issues in your tracker, then /ceos-agents:implement-feature <ID>

User: /implement-feature PROJ-1
  → Step 0b: Config validity check (new)
  → "Automation Config has 2 incomplete sections: Issue Tracker Instance (TODO),
     Source Control Remote (TODO). Run /ceos-agents:onboard --update to fix."
  → User fixes config
User: /implement-feature PROJ-1
  → Runs successfully
```

**Error Recovery:**
- Config errors caught BEFORE side effects (no orphan branches, no state mutations)
- Scaffold crash at Step 7: `/scaffold-resume` reads `.ceos-agents/scaffold-*/state.json`, finds last completed subtask, resumes from next
- Missing MCP: existing pre-flight check already covers this; the readiness gate catches config issues earlier

**Cognitive Load:** Zero new concepts. The user learns the same commands they already need to learn. The change is that the system tells them what to do next instead of making them guess.

**Pros:**
- Smallest possible change set — 3 edits to existing files, 0 new files
- No version bump needed for the onboard mention fix; MINOR for Step 0b and scaffold-resume
- Directly addresses the #1 pain point (the handoff gap) identified in research (KF: RQ-08)

**Cons:**
- Does not address Journey 3 (batch features) or Journey 4 (local deployment) at all
- "Fixing the handoff" is less impressive than a new feature — harder to justify as a release
- scaffold-resume is a new command name pointing to existing logic — could confuse users who already know resume-ticket

**Effort:** S

**Files affected:**
- `commands/scaffold.md` (Step 10 — add onboard --update to next steps)
- `commands/implement-feature.md` (new Step 0b — config validity gate)
- `commands/resume-ticket.md` (add scaffold pipeline type detection + scaffold state file reading)

---

## Idea 2: The Guided Runway — `/scaffold --continue` and Smart Next Steps

**Description:** After scaffold completes, the user's #1 question is "what now?" Today the answer is a static list. This idea makes the scaffold report interactive: the system detects what is incomplete and offers to fix it inline. A new `--continue` flag on `/scaffold` re-enters the project in a post-scaffold mode that walks the user through config completion, MCP setup, and first feature creation — all in one session. Internally it chains: onboard --update logic + init logic + first implement-feature. No new commands to discover; the user just stays in `/scaffold`.

**User Journey:**
```
User: /scaffold "task management app with Postgres"
  → scaffold completes, Final Report shows:

  ## Scaffold Complete
  ...
  ### What's next?
  Your project builds and tests pass, but 3 things need setup before
  you can use the full pipeline:

  (a) Fill in CLAUDE.md config — Issue Tracker instance, Source Control remote
      → I can walk you through this now (same as /onboard --update)
  (b) Configure MCP servers — tokens for your tracker and git host
      → I can set this up now (same as /init)
  (c) Ready to go — skip setup, I'll remind you later

  [a/b/c]

User: a
  → Onboard --update wizard runs inline (Issue Tracker, Source Control)
  → "Config updated. Now configure MCP? [Y/n]"
User: y
  → Init wizard runs inline
  → "Setup complete. Want to implement your first feature? [Y/n]"
User: y
  → "Create an issue in your tracker first, or describe the feature here
     and I'll create the tracker card for you."
User: "Add user authentication with email/password"
  → Creates tracker card via MCP, gets PROJ-1
  → Runs implement-feature PROJ-1

--- Next day ---
User: /scaffold --continue
  → Detects existing project with scaffold state
  → Shows: "Project: task-mgmt. 3/8 features implemented. 0 blocked."
  → "Pick a feature to implement, or type 'status' for details."
```

**Error Recovery:**
- Each sub-step (onboard, init, implement) has its own error handling — failures are localized
- If MCP setup fails: "MCP configuration failed: {error}. You can try again with /ceos-agents:init or continue without tracker integration."
- If the user closes the session mid-wizard: `/scaffold --continue` picks up from where they left off (reads state.json)
- Scaffold crash during feature loop: `--continue` detects partial state and resumes

**Cognitive Load:** ONE concept: `/scaffold`. The user never needs to discover `/onboard`, `/init`, or `/check-setup` independently. They learn those commands exist only if they want to re-run them individually later.

**Pros:**
- Lowest cognitive load of any option — one command does everything
- "Pit of success" — doing the obvious thing (/scaffold, then /scaffold --continue) leads to a working pipeline
- Addresses Journeys 1, 2, and 5 in a single design

**Cons:**
- Significant complexity added to scaffold.md — the command becomes a mini-orchestrator
- `/scaffold --continue` semantics overlap with `/resume-ticket` — where does one end and the other begin?
- Does not address Journey 3 (batch features) or Journey 4 (deployment)

**Effort:** M

**Files affected:**
- `commands/scaffold.md` (post-scaffold wizard, --continue flag, state detection)
- `state/schema.md` (new `post_scaffold_phase` field in scaffold pipeline state)

---

## Idea 3: The Full Stack — Deploy Pipeline with `check-deploy` and `deployment-verifier`

**Description:** Add a deployment verification layer: a new optional `Local Deployment` config section, a `deployment-verifier` agent (sonnet, reuses the `run_in_background` + health poll pattern from reproducer), and a `check-deploy` command. After scaffold + feature implementation, the user runs `/check-deploy` which: reads `docker-compose.yml`, starts the stack, polls health endpoints, runs smoke checks, and reports results. This completes Journey 4. The scaffold Final Report is updated to mention `/scaffold-add docker` and `/check-deploy` as post-implementation steps.

**User Journey:**
```
User: /scaffold "task management app with Postgres"
  → scaffold completes, includes Dockerfile but no docker-compose.yml

User: /scaffold-add docker
  → Generates docker-compose.yml with app + postgres services
  → "docker-compose.yml generated. Add Local Deployment config to CLAUDE.md? [Y/n]"
User: y
  → Adds to CLAUDE.md:
    ### Local Deployment
    | Key | Value |
    | Compose file | docker-compose.yml |
    | Health check URL | http://localhost:3000/health |
    | Startup timeout | 60 |
    | Teardown strategy | always |

User: /check-deploy
  ## Deploy Check — task-mgmt

  ### Prerequisites
  [OK]   docker found (v24.0.7)
  [OK]   docker compose found (v2.23.3)
  [OK]   docker-compose.yml found
  [OK]   Local Deployment config found in CLAUDE.md

  ### Stack Startup
  [OK]   docker compose up -d (3 services)
  [OK]   postgres — healthy (2.1s)
  [OK]   app — healthy (5.3s)
  [OK]   Health check http://localhost:3000/health — 200 OK

  ### Smoke Check
  [OK]   GET / — 200
  [OK]   No critical console errors

  ### Teardown
  [OK]   docker compose down — all containers stopped

  ---
  Result: 0 FAIL — Local deployment verified.
```

**Error Recovery:**
- Docker not installed: `[FAIL] docker not found. Install Docker Desktop: https://docs.docker.com/get-docker/`
- Compose file missing: `[FAIL] docker-compose.yml not found. Run /ceos-agents:scaffold-add docker to generate one.`
- Health check timeout: `[FAIL] app — not healthy after 60s. Last log: {last 10 lines of docker compose logs app}`. The agent shows logs, not just the timeout.
- Port conflict: `[FAIL] Port 5432 already in use. Stop the conflicting service or change the port in docker-compose.yml.`
- Teardown: ALWAYS runs even on failure (controlled by `Teardown strategy` config)

**Cognitive Load:** Two new concepts: `Local Deployment` config section and `/check-deploy` command. Both follow patterns the user already knows (config sections look like all others; check-deploy output looks like check-setup).

**Pros:**
- Directly addresses Journey 4 — the only idea that handles deployment
- Follows established precedent (Browser Verification pattern for config, check-setup pattern for command)
- Research confirms this is architecturally viable (KF-5, KF-6, KF-7)

**Cons:**
- Does not address Journeys 2 or 3 (handoff gap, batch features)
- New command (25 total) + new agent (19 total) — adds to the surface area
- Docker-specific — users deploying without Docker get nothing from this

**Effort:** M

**Files affected:**
- `agents/deployment-verifier.md` (new agent)
- `commands/check-deploy.md` (new command)
- `commands/scaffold-add.md` (update docker component to offer Local Deployment config)
- `CLAUDE.md` (add Local Deployment to optional config table, update agent count)
- `docs/reference/automation-config.md` (Local Deployment section docs)

---

## Idea 4: The Conveyor Belt — Unified Post-Scaffold Dashboard with Action Buttons

**Description:** The real problem is not any single missing command — it is that the user finishes scaffold and faces an open field with no guardrails. This idea adds a persistent "project readiness" view to `/status` that tracks post-scaffold setup progress and suggests the single most important next action. When you run `/status` after a scaffold, instead of showing issue tracker state (which is empty), it shows a setup checklist with actionable guidance. As the user completes steps, the checklist updates. Once all prerequisites pass, `/status` switches to its normal issue-tracking mode.

**User Journey:**
```
User: /scaffold "task management app with Postgres"
  → scaffold completes

User: /status
  ## Project Readiness — task-mgmt

  ### Setup Progress
  [DONE]  Project scaffolded (8 features implemented, 0 blocked)
  [TODO]  CLAUDE.md config — 2 TODOs remaining (Instance, Remote)
  [TODO]  MCP servers — not configured
  [TODO]  Config validation — not run
  [SKIP]  Local deployment — no Local Deployment config (optional)

  ### Next Action
  → Run /ceos-agents:onboard --update to fill in CLAUDE.md TODOs

  When all required steps are [DONE], /status will show your issue tracker overview.

User: /onboard --update
  → fills in Instance, Remote

User: /status
  ## Project Readiness — task-mgmt

  ### Setup Progress
  [DONE]  Project scaffolded
  [DONE]  CLAUDE.md config — all sections complete
  [TODO]  MCP servers — not configured
  [TODO]  Config validation — not run
  [SKIP]  Local deployment — optional

  ### Next Action
  → Run /ceos-agents:init to configure MCP servers

User: /init
  → configures MCP

User: /status
  ## Project Readiness — task-mgmt

  ### Setup Progress
  [DONE]  Project scaffolded
  [DONE]  CLAUDE.md config
  [DONE]  MCP servers
  [TODO]  Config validation — run /ceos-agents:check-setup

  ### Next Action
  → Run /ceos-agents:check-setup to validate everything

User: /check-setup
  → all OK

User: /status
  ## Status — task-mgmt
  (normal issue tracker view — readiness phase complete)

  | Issue | Title | Stage | Branch | PR |
  ...

  ### Recommended Next Steps
  1. No active issues. Run /ceos-agents:implement-feature <ID> to start.
```

**Error Recovery:**
- Each step in the checklist links to the exact command that fixes it
- If `/check-setup` finds failures, `/status` shows them: `[FAIL] Config validation — 2 issues (run /ceos-agents:check-setup for details)`
- If the user tries `/implement-feature` before readiness is complete, the Step 0b gate (from Idea 1) catches it — but `/status` would have already told them what to do
- Scaffold state is read from `.ceos-agents/scaffold-*/state.json` for the initial DONE entry

**Cognitive Load:** Zero new commands. The user learns ONE habit: "when in doubt, run `/status`." The system does the thinking about what to do next. This is the Netflix model — do not ask the user to browse, just recommend.

**Pros:**
- Builds on an existing command the user already needs to learn
- Progressive disclosure: setup checklist disappears once done, revealing the normal view
- Works for ALL journeys as a universal "where am I?" command
- Does not add to command count or agent count

**Cons:**
- `/status` becomes significantly more complex (two modes with state detection)
- Readiness detection requires reading scaffold state, CLAUDE.md TODOs, .mcp.json — multiple file reads
- Does not DO anything — it only TELLS the user what to do; they still run 4 separate commands

**Effort:** S

**Files affected:**
- `commands/status.md` (add readiness mode with setup checklist)

---

## Idea 5: The Composite — Idea 1 + Idea 4 + Deployment Foundation

**Description:** Combine the three highest-impact, lowest-risk changes into a single coherent release: (a) Fix the handoff gap (Idea 1 — add onboard mention to scaffold report, add config validity gate to implement-feature), (b) Smart status with readiness tracking (Idea 4 — /status knows about post-scaffold state), (c) Lay the deployment foundation (scaffold-add docker offers Local Deployment config, but defer check-deploy command and deployment-verifier agent to a follow-up release). The result: after scaffold, the user runs `/status` and gets told exactly what to do. Each command they run before `/implement-feature` is validated before it mutates state. Deployment config is prepared but not yet orchestrated.

**User Journey:**
```
User: /scaffold "task management app with Postgres"
  → Final Report now includes /onboard --update in next steps

User: /status
  → Readiness checklist shows 4 TODOs
  → "Next: Run /ceos-agents:onboard --update"

User: /onboard --update
  → fills config

User: /status
  → 2 TODOs remaining
  → "Next: Run /ceos-agents:init"

User: /init → /check-setup → all green

User: /implement-feature PROJ-1
  → Step 0b validates config first (catches any remaining issues)
  → Runs successfully

User: /scaffold-add docker
  → Generates docker-compose.yml + Local Deployment config in CLAUDE.md
  → "Local deployment config added. Full deployment verification
     (/check-deploy) coming in a future release. For now, run
     'docker compose up' to test locally."

--- Future release ---
User: /check-deploy
  → Full deployment verification pipeline
```

**Error Recovery:**
- Config gate (Step 0b) catches ALL config issues before side effects — this is the single most impactful error prevention measure
- `/status` readiness mode means the user always knows where they stand
- Scaffold crash: add scaffold pipeline type to resume-ticket (small addition)
- Deployment: deferred to next release, so no new failure modes in this release

**Cognitive Load:** Zero new commands in this release. Zero new config sections the user must configure (Local Deployment is generated by scaffold-add, not hand-authored). The user learns `/status` as their home base — everything else flows from there.

**Pros:**
- Highest impact-to-effort ratio: fixes the 3 biggest pain points without adding commands
- Incremental: deployment foundation is laid without committing to the full check-deploy/deployment-verifier design
- Every change is independently testable and shippable
- Addresses Journeys 1, 2, and 5 fully; sets up Journey 4 for next release

**Cons:**
- Journey 3 (batch features) still unaddressed — would need a separate `/implement-features` command
- "Composite" means no single compelling narrative for the release — it is "miscellaneous improvements"
- scaffold-add docker generating Local Deployment config is speculative if check-deploy does not exist yet

**Effort:** M (sum of S + S + small additions to scaffold-add)

**Files affected:**
- `commands/scaffold.md` (Step 10 — add onboard --update to next steps)
- `commands/implement-feature.md` (new Step 0b — config validity gate)
- `commands/status.md` (readiness mode with setup checklist)
- `commands/resume-ticket.md` (scaffold pipeline type support)
- `commands/scaffold-add.md` (docker component generates Local Deployment config stub)
- `CLAUDE.md` (Local Deployment in optional config table)

---

## Top Recommendation

**Idea 5: The Composite** creates the best "pit of success."

Here is my reasoning as a user advocate:

The #1 cause of user abandonment is not missing features — it is getting stuck between steps. Today, a user who successfully scaffolds a project hits a wall of silence: the Final Report lists 4 next steps with no guidance on order, no validation that they completed them correctly, and no way to check their progress. The most likely failure mode is: user edits CLAUDE.md manually, makes a typo in a key name, runs `/implement-feature`, gets a cryptic config error after the branch was already created.

The composite fixes this with three interlocking safety nets:

1. **The scaffold report tells them about `/onboard --update`** — this is a one-line fix that eliminates the most common "how do I fill in TODOs?" question.

2. **`/status` shows readiness state** — the user has a single command that answers "am I ready?" at any point. This is the habit-forming command. Once they learn to check `/status`, they never get stuck.

3. **Step 0b in implement-feature validates config before side effects** — this is the hard safety net. Even if the user skips status and charges ahead, the system catches config problems before creating branches or mutating tracker state. The error message points them to the exact fix.

These three changes are individually small (S effort each), independently valuable, and collectively transform the post-scaffold experience from "figure it out yourself" to "the system guides you." They require zero new commands, zero new agents, and zero new config sections for the user to learn.

Deployment (Idea 3) is the right follow-up release. Laying the Local Deployment config foundation in scaffold-add now means the config format is stable before check-deploy ships. But shipping check-deploy + deployment-verifier in the same release as the handoff fixes would double the scope without addressing the primary pain point.

The batch features gap (Journey 3) is real but lower priority — a user who can successfully implement one feature can run the command ten times. It is a convenience problem, not a blocking problem. Worth tracking for a future `/implement-features` command analogous to `/fix-bugs`.
