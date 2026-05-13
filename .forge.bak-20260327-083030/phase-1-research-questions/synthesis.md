# Phase 1: Research Questions — Synthesized

## Synthesis Notes

**Agent scores (specificity / coverage / actionability / total):**
- Agent 1 — Scaffold Gaps & Issue Tracker: 4 / 4 / 4 = 12
- Agent 2 — Feature Loop Orchestration: 5 / 4 / 4 = **13 (base)**
- Agent 3 — Local Deployment: 4 / 4 / 4 = 12
- Agent 4 — Cross-Plugin Bridge: 4 / 5 / 3 = 12
- Agent 5 — Plugin Constraints: 3 / 4 / 4 = 11

**Base:** Agent 2 (highest specificity — cites exact line numbers, schema field names, YAML paths).

**Unique contributions extracted:**
- Agent 1: MCP capability matrix question (Q5) — not asked by any other agent
- Agent 1: bootstrap sequence / `--tracker` flag design (Q1, Q2) — merged into bridge layer
- Agent 3: `docker-compose.yml` origin gap (Q1), reproducer pattern for docker (Q2), browser-verifier extension vs new agent (Q3), check-setup vs check-deploy (Q5)
- Agent 4: Skill() cross-namespace calling (Q1), forge-plan vs architect schema comparison (Q2), creation sequence inversion (Q3), AC maps_to coverage gap (Q4)
- Agent 5: Command-chaining capability (Q1), allowed-tools hard ceiling (Q2), mid-session crash resume consistency (Q3)

**Duplicates resolved:**
- "MCP capabilities / pre-flight check" appeared in A1-Q5, A2-Q5, A4-Q5 — merged into RQ-05 (MCP CRUD scope) and RQ-16 (MCP pre-flight gate placement)
- "TODO placeholders block implement-feature" appeared in A1-Q2, A2-Q1, A2-Q5 — merged into RQ-08 (bridge gap) and RQ-09 (setup-validation gate)
- "Scaffold build/test against missing infrastructure" appeared in A1-Q3, A2-Q5 context — single question RQ-07
- "Versioning impact of new config keys" appeared in A3-Q4, A5-Q5 — merged into RQ-18
- "Long-running process via Bash" appeared in A3-Q2, A5-Q4 — merged into RQ-14 (deploy orchestration pattern)

---

## Foundation Layer (answer first — blocks everything else)

**RQ-01: Command chaining capability**
Can a markdown command invoke another markdown command directly (true command chaining), or is all cross-command delegation limited to the Task tool dispatching a named agent — meaning `/scaffold` cannot call `/implement-feature` as a sub-command but only compose via agents?
*(Source: A5-Q1. Blocks: RQ-08, RQ-09, RQ-11, RQ-15)*

**RQ-02: Skill() cross-plugin namespace scope**
Does Claude Code support calling `Skill()` across plugin namespaces — e.g., invoking `filip-superpowers:forge-plan` from inside a `ceos-agents` command or skill? The bug-workflow skill calls `ceos-agents:<command>` intra-plugin; is this mechanism available inter-plugin, or is it scoped to the calling plugin only?
*(Source: A4-Q1. Blocks: RQ-15, RQ-16, RQ-17)*

**RQ-03: allowed-tools hard capability ceiling**
Does the `allowed-tools` frontmatter in commands (e.g., `Bash, Read, Write, Edit, Glob, Grep, Task, mcp__*`) represent a hard ceiling on what Claude Code exposes at runtime? Specifically: can a pure-markdown command start a background process (`docker compose up`), poll a health endpoint, or read environment variables beyond what the Bash tool already permits within that list — or does `allowed-tools` define the absolute boundary?
*(Source: A5-Q2. Blocks: RQ-12, RQ-13, RQ-14)*

**RQ-04: Mid-session crash resume consistency**
When a Claude Code session terminates mid-pipeline (power loss, token limit, process kill) and a new session invokes `/resume-ticket`, does `core/state-manager.md` guarantee a consistent resume point — specifically, can it detect whether the last written step was fully executed or only partially written — or can the pipeline silently replay a step that already completed?
*(Source: A5-Q3. Blocks: RQ-10 — cross-run parent tracking requires reliable per-run state)*

**RQ-05: MCP server capability scope — project-level vs issue-level**
Do any of the six supported MCP servers (forgejo-mcp, youtrack-mcp, server-github, jira, linear, redmine) expose tools for project-level operations — create repository, create project/board, create label set, create milestone — or are all servers scoped to issue-level CRUD only? No capability matrix currently exists in `docs/reference/trackers.md`. This determines whether pre-implementation card creation can be automated via existing MCP calls or requires a new integration layer.
*(Source: A1-Q5, A4-Q5. Blocks: RQ-09, RQ-15, RQ-16)*

---

## Scaffold→Feature Bridge

**RQ-06: Scaffold bootstrap sequence and TODO placeholder design**
The scaffold pipeline generates `Instance` (tracker URL) and `Remote` (owner/repo) as TODO placeholders, making the MCP pre-flight check in `implement-feature` Step 0 always fail on a freshly scaffolded project. What is the intended bootstrap sequence — should the user configure the tracker *before* running `/scaffold` (passing values via `--tracker` / `--remote` flags), or should `/scaffold` accept and pre-fill these values so that Step 9 (issue tracker card creation) and the subsequent feature loop can run without manual file editing?
*(Source: A1-Q1, A1-Q2, A2-Q1)*

**RQ-07: Scaffold build/test against missing infrastructure**
Scaffold Step 7 runs the `Build command` and `Test command` from the generated CLAUDE.md — but those commands may require external services (running database, `.env` with secrets) that don't exist during scaffold. Does the scaffolder generate a `.env.example` / `.env.test` with stub values sufficient for build and test to pass in isolation, or is there an unhandled gap where commands silently fail because infrastructure prerequisites are absent?
*(Source: A1-Q3, A2-Q5 context)*

**RQ-08: Scaffold-to-implement-feature handoff — missing finalize step**
After scaffold completes, the working tree is on the default branch with no remote configured and CLAUDE.md still contains TODO markers. The `implement-feature` pipeline requires a non-TODO `Remote`, a non-TODO `Instance`, and a configured branch naming convention. Is there a missing `scaffold-finalize` step — or a new `/project-init` command — that should push the scaffold result to a remote repo, configure `Remote` and `Instance` in CLAUDE.md, and produce a state that `implement-feature` can consume without manual file editing? Or is manual editing the only supported path?
*(Source: A1-Q2, A1-Q4, A2-Q1)*

**RQ-09: Setup-validation gate before the feature loop**
When a feature loop begins after scaffold — potentially before CLAUDE.md TODO markers are resolved — at what pipeline step should a configuration validity gate run? Should `/ceos-agents:check-setup` (or a new `setup-validation` core pattern) be invoked before the first `implement-feature` call to detect incomplete configuration, rather than letting the MCP pre-flight check in Step 0 fail inside an agent invocation?
*(Source: A2-Q5, A1-Q2)*

**RQ-10: Cross-run parent/child relationship tracking in state schema**
Each `implement-feature` run writes its own `.ceos-agents/{ISSUE-ID}/state.json` with no link to the scaffold run that preceded it. For a scaffold → N feature runs workflow, should a `parent_run_id` field be added to the state schema (`state/schema.md`) so that `/status`, `/metrics`, and `/resume-ticket` can reconstruct the full workflow lineage — or is a naming convention (e.g., feature branches derived from the scaffold run ID) sufficient?
*(Source: A2-Q2)*

**RQ-11: Scaffold-to-implement-feature delegation — pipeline stage delta**
Scaffold Step 7 (feature implementation loop) already runs fixer + reviewer + test-engineer inline per subtask — with no spec-analyst, no publisher, no acceptance-gate, and no PRs. If scaffold is redesigned to delegate each epic to a separate `implement-feature` invocation, which pipeline stages would need to be conditionally skipped via `--profile` or a new flag — and would the decomposition step in `implement-feature` (Step 5) need to be skipped to avoid re-decomposing work already decomposed by scaffold's architect?
*(Source: A2-Q3, A2-Q4)*

---

## Deployment Layer

**RQ-12: docker-compose.yml ownership — scaffolder vs scaffold-add**
The scaffolder generates a `Dockerfile` and `.dockerignore` (Batch 4), and `scaffold-add docker` explicitly generates `docker-compose.yml` — but the scaffolder agent definition never mentions `docker-compose.yml`. For full-stack projects (DB + FE + BE), should the scaffolder generate the compose file directly, or should compose-file generation remain the exclusive responsibility of `scaffold-add docker`? If the scaffolder should generate it, what service definitions and health check stubs should it include by default?
*(Source: A3-Q1)*

**RQ-13: Browser-verifier extension vs new deployment-verifier agent**
The `browser-verifier` agent is scoped to a single bug fix — it replays a `reproducer-script.js`, checks adjacent pages, and returns a `VERIFIED/PARTIAL/FAILED/SKIPPED` verdict tied to a specific issue ID and fixer diff. Could `browser-verifier` be extended with a "Deployment Smoke" sub-phase (triggered by `On events: deploy`, navigating configurable smoke URLs and asserting HTTP 200 + no critical console errors) — or does the coupling to bug-fix context (issue ID, fixer diff, reproducer script) make a separate `deployment-verifier` agent a cleaner design that avoids contaminating the bug-fix pipeline contract?
*(Source: A3-Q3)*

**RQ-14: Long-running docker orchestration via Bash tool — viability**
The browser-verifier pattern (agent generates script → Bash executes `node script.js` → agent reads JSON result) is the only existing precedent for agent-driven external process execution. Can this pattern be applied to `docker compose up --detach` — generating a startup script, executing it via Bash, then polling service health endpoints (via `docker inspect` or HTTP GET) until all containers report healthy — given Bash tool constraints: no interactive TTY, no persistent shell state between calls, and per-call timeout limits? What is the maximum startup wait that can be implemented reliably under these constraints?
*(Source: A3-Q2, A5-Q4)*

**RQ-15: New Local Deployment config section vs extending Build & Test**
A local deployment workflow needs at minimum: a compose file path, per-service health check URLs, and a startup timeout. Should these live in a new optional `Local Deployment` config section (parallel to `Browser Verification`), or as new optional keys added to the existing `Build & Test` section? What is the versioning impact: new optional keys in an existing section vs a new optional section — both are MINOR per current policy, but do they differ in their contract footprint and potential for future MAJOR conflicts?
*(Source: A3-Q4, A5-Q5)*

**RQ-16: check-setup extension vs new check-deploy command**
If a deployment pipeline stage is introduced, should `check-setup` be extended to verify deployment prerequisites (Docker daemon reachable via `docker info`, `docker compose` binary present, compose file exists) — or should a dedicated `/ceos-agents:check-deploy` command own deployment readiness verification, following the same read-only, safe-for-repeated-execution contract that `check-setup` currently enforces? What is the coupling risk of embedding Docker awareness into a command that currently has no infrastructure dependencies?
*(Source: A3-Q5)*

---

## Cross-Plugin Bridge

**RQ-17: forge-plan vs architect task tree schema — compatibility**
What is the exact output format written to `.forge/` by `filip-superpowers:forge-plan` at the end of its pipeline — specifically: field names, nesting depth, dependency representation, and acceptance criteria references? Does it match or conflict with the YAML schema that the ceos-agents `architect` agent produces (`id`, `title`, `scope`, `files`, `estimated_lines`, `depends_on`, `acceptance_criteria`, `maps_to: AC-{N}: {text}`)? A field-by-field comparison determines whether a format translation layer is needed before ceos-agents can consume forge-plan output.
*(Source: A4-Q2. Requires: RQ-02)*

**RQ-18: forge-plan AC maps_to gap — coverage check failure**
The `implement-feature` pipeline performs an AC coverage check (Step 5) that fails if any architect subtask lacks a `maps_to` entry in `AC-{N}: {text}` format. If forge-plan produces its own decomposition tree without equivalent traceability fields, the AC coverage check would always fail on forge-plan output. Must the AC coverage check be conditionally skipped, adapted to accept forge-plan's native format, or must forge-plan output be post-processed to inject `maps_to` annotations before entering the fixer loop?
*(Source: A4-Q4. Requires: RQ-17)*

---

## Verification & Versioning

**RQ-19: Epic-to-card creation sequence — pre-implementation vs post-implementation**
Two valid creation sequences exist: (a) user describes epic → forge-plan decomposes → ceos-agents creates tracker cards → `implement-feature` runs on each card; or (b) user creates tracker card first → `implement-feature --expert` calls forge-plan with the issue description → forge-plan returns a task tree used instead of architect output. Which sequence (a) avoids the MCP pre-flight check becoming a blocking dependency before cards exist, and (b) is compatible with the MCP CRUD capabilities established in RQ-05?
*(Source: A4-Q3. Requires: RQ-02, RQ-05)*

**RQ-20: Versioning impact of new optional config keys**
The "Deploy workflow" will add new Automation Config keys (e.g., `Compose file`, `Health check URLs`, `Startup timeout`, `Deploy command`). Per the versioning policy: new optional keys or sections = MINOR. However, if a new hook category (`Deploy` hook) is introduced in the `Hooks` section — an existing required-structure section — does adding a new hook point constitute a contract-level change requiring a MAJOR bump, or is it additive-only and therefore MINOR? Does the existing `Hooks` section (Pre-fix, Post-fix, Pre-publish, Post-publish) already provide a sufficient injection point for a deployment step without requiring a new hook category?
*(Source: A3-Q4, A5-Q5)*

---

## Dependency Map

```
RQ-01 (command chaining)
  └─ RQ-08, RQ-09, RQ-11, RQ-19

RQ-02 (Skill() cross-namespace)
  └─ RQ-17, RQ-18, RQ-19

RQ-03 (allowed-tools ceiling)
  └─ RQ-12, RQ-13, RQ-14

RQ-04 (crash resume)
  └─ RQ-10

RQ-05 (MCP capability scope)
  └─ RQ-09, RQ-16, RQ-19

RQ-06 (bootstrap sequence) ── standalone
RQ-07 (build/test missing infra) ── standalone
RQ-08 (finalize step) ── requires RQ-01, RQ-06
RQ-09 (setup-validation gate) ── requires RQ-05, RQ-08
RQ-10 (cross-run state) ── requires RQ-04
RQ-11 (delegation delta) ── requires RQ-01, RQ-08
RQ-12 (compose ownership) ── requires RQ-03
RQ-13 (verifier extension) ── requires RQ-03
RQ-14 (long-running docker) ── requires RQ-03
RQ-15 (config section design) ── requires RQ-14
RQ-16 (check-deploy) ── requires RQ-05, RQ-14
RQ-17 (schema compatibility) ── requires RQ-02
RQ-18 (maps_to gap) ── requires RQ-17
RQ-19 (creation sequence) ── requires RQ-02, RQ-05
RQ-20 (versioning impact) ── requires RQ-15
```

**Total: 20 questions, 0 duplicates.**
