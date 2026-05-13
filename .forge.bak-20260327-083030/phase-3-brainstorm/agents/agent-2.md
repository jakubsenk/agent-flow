# Persona B: The Systems Thinker

The scaffold-to-deployment problem is a state machine composition problem. Today, ceos-agents has three independent pipelines (bug-fix, feature, scaffold) that share agents but do not compose into a higher-order workflow. The five stages — scaffold, feature loop, forge integration, local deployment, standalone machine — form a DAG where each stage's postcondition is the next stage's precondition. The design question is: what is the minimal kernel that makes these stages compose without coupling them?

---

## Idea 1: Pipeline Phases with Gateway Contracts

**Description:** Instead of creating new commands or agents for deployment, define a **phase contract** — a formal interface between pipeline stages. Each phase produces a `phase-result.json` that satisfies a schema, and the next phase consumes it. Scaffold already produces `state.json` with `status: "completed"`. Extend this pattern: scaffold's completion state becomes the feature loop's init state. The feature loop's completion state becomes deployment's init state. No new commands needed — the existing `state.json` gets a `phases` array that tracks the full lifecycle. A new `check-deploy` command simply reads the phase chain and validates that all preconditions for deployment are met.

**State Machine:**
```
SCAFFOLD_PENDING → SCAFFOLD_RUNNING → SCAFFOLD_COMPLETE
    ↓ (postcondition: spec/ exists, CLAUDE.md exists, git init done)
FEATURES_PENDING → FEATURES_RUNNING → FEATURES_COMPLETE
    ↓ (postcondition: all epics implemented, E2E passing)
DEPLOY_PENDING → DEPLOY_RUNNING → DEPLOY_VERIFIED
    ↓ (postcondition: health check passes, no critical console errors)
STANDALONE
```

Each transition has a **gateway predicate** — a pure read-only check. `SCAFFOLD_COMPLETE → FEATURES_PENDING` requires: `spec/` exists, `CLAUDE.md` has no TODO markers in Build & Test, git repo initialized. `FEATURES_COMPLETE → DEPLOY_PENDING` requires: all decomposition subtasks completed, test suite passing, no blocked features. These predicates are the invariants.

**Pros:**
- Zero new agents needed. Uses existing state infrastructure (state.json, pipeline.log).
- Each phase is independently resumable via existing `resume-ticket` logic extended to read phases.
- Gateway contracts are testable — you can validate them without running the pipeline.

**Cons:**
- `state.json` schema change (add `phases` array) needs careful backward compatibility.
- Does not solve the actual deployment problem — only organizes the state transitions around it.
- Feature loop stage requires translating scaffold's `spec/epics/*.md` into implement-feature-compatible format, which is the hardest unsolved problem.

**Effort:** M (schema extension + gateway predicates + check-deploy command)

**Files affected:** `state/schema.md`, `core/state-manager.md`, new `core/phase-gateway.md`, new `commands/check-deploy.md`, `commands/scaffold.md` (emit phase markers), `commands/resume-ticket.md` (phase-aware resume)

**Invariants:**
- Phase N+1 NEVER starts unless Phase N gateway predicate returns true.
- Gateway predicates are pure functions of filesystem state (spec/, CLAUDE.md, state.json, git) — no side effects.
- A phase can be re-run without corrupting the next phase's state (idempotent transitions).

---

## Idea 2: Deployment-Verifier Agent + Local Deployment Config Section

**Description:** Create a single new `deployment-verifier` agent (sonnet) that uses the reproducer's proven `run_in_background` + health poll pattern. Add a new optional `Local Deployment` config section (MINOR version bump — optional keys only). The agent starts the application using a configured command, polls a health endpoint, and then runs a lightweight verification pass: HTTP 200 on key routes, no critical console errors, basic accessibility snapshot. This is the smallest possible "deployment" addition — it answers "does the thing I just built actually run?" without trying to manage Docker, cloud providers, or CI/CD.

The key insight is that `reproducer.md` already solves the hard problem — starting an app, waiting for it, running Playwright against it, and cleaning up. The deployment-verifier is a simplified reproducer that checks routes from the scaffold's spec rather than reproduction steps from a bug report.

**State Machine:**
```
DEPLOY_IDLE → APP_STARTING → HEALTH_POLLING → HEALTH_OK → ROUTE_CHECKING → VERIFIED
                  ↓                ↓                              ↓
              START_FAILED    POLL_TIMEOUT                   CHECK_FAILED
                  ↓                ↓                              ↓
               SKIPPED          SKIPPED                    PARTIAL_VERIFIED
```

All failure modes produce `SKIPPED` or `PARTIAL` — never block. This matches the reproducer's non-blocking philosophy.

**Pros:**
- Reuses a proven pattern (reproducer's run_in_background + health poll + Playwright check).
- New optional config section = MINOR version bump (no breaking change).
- Directly answers the user's question: "does my scaffolded project actually work end-to-end?"

**Cons:**
- Only covers local deployment (localhost). No cloud, no containers, no CI/CD.
- Requires Playwright in the consuming project (same dependency as browser verification).
- The "routes to check" derivation from spec is heuristic — spec/epics may not map cleanly to HTTP routes.

**Effort:** S (one new agent, one new config section, scaffold step 8.5 insertion)

**Files affected:** new `agents/deployment-verifier.md`, `commands/scaffold.md` (add step between E2E and final report), `CLAUDE.md` (document new config section and agent), `state/schema.md` (add `deployment` phase object), `docs/reference/automation-config.md`

**Invariants:**
- Deployment-verifier NEVER blocks the pipeline (all failures → SKIPPED/PARTIAL, matching reproducer contract).
- App process started by deployment-verifier is ALWAYS killed before returning (same cleanup contract as reproducer).
- Config section is entirely optional — scaffold works identically without it.

---

## Idea 3: Scaffold Continuum — Epic-to-Feature Bridge with Translation Layer

**Description:** The hardest problem in the 5-stage workflow is stage 2 → stage 3: translating scaffold's `spec/epics/*.md` into implement-feature-compatible issue tracker cards, then running implement-feature against them. Today this is impossible because (a) commands cannot invoke other commands, and (b) forge-plan schemas are incompatible with implement-feature's spec-analyst input. The solution is a **translation layer** in `core/` that converts between schema formats, plus extending scaffold's Step 9 (issue tracker card creation) to produce cards that implement-feature can consume directly.

The key architectural insight: scaffold Step 7 already runs the full fixer-reviewer-test loop inline. The feature loop for a scaffolded project is not "run implement-feature N times" — it is "scaffold Step 7 repeated for post-scaffold changes." The bridge is not between scaffold and implement-feature. It is between the scaffold's completed state and a new iteration of scaffold Step 7 for additional epics/features added after initial scaffold.

This means: add an `--extend` flag to scaffold that reads existing `spec/` and `state.json`, accepts new epic descriptions, runs them through the spec-writer/reviewer loop, and feeds them into the Step 7 feature implementation loop. No cross-command invocation needed.

**State Machine:**
```
SCAFFOLD_COMPLETE → EXTEND_INIT → SPEC_EXTEND → SPEC_REVIEW
                                      ↓               ↓
                                  ARCHITECT → FEATURE_LOOP → EXTEND_COMPLETE
                                                  ↑     ↓
                                              RETRY   BLOCK
```

**Pros:**
- Solves the actual hard problem (scaffold → feature loop continuity) without cross-command calls.
- Single command entry point (`/scaffold --extend`) — no new commands to learn.
- Reuses all existing scaffold infrastructure (Step 5 architect, Step 7 fixer loop).

**Cons:**
- Scaffold command grows even longer (already 515 lines). May trigger the "lost in middle" context degradation that Step-File Architecture (roadmap item) was designed to prevent.
- `--extend` semantics are subtly different from initial scaffold (existing codebase, existing tests, existing CLAUDE.md). Fixer context must be richer.
- Does not address forge integration (stage 3) — that remains a cross-plugin problem.

**Effort:** L (flag parsing, spec extension logic, state continuity, architect re-run with existing codebase context)

**Files affected:** `commands/scaffold.md` (major extension), `core/state-manager.md` (phase chain reading), `state/schema.md` (extend run tracking), `agents/spec-writer.md` (extend mode instructions), `agents/architect.md` (incremental decomposition with existing subtask awareness)

**Invariants:**
- `--extend` NEVER modifies files from the original scaffold unless architect explicitly declares a dependency.
- Existing tests MUST still pass after extend (integration gate from Step 7 applies).
- `spec/` folder is append-only during extend — existing epic files are never overwritten (new epics get higher NN prefix).

---

## Idea 4: Standalone Machine Pattern — Onboard --from-scaffold

**Description:** Stage 5 (standalone machine) means: a project scaffolded by ceos-agents should be fully autonomous — it can run fix-bugs, implement-feature, and publish without any scaffold context. Today, scaffold Step 10 prints "fill in TODO sections in CLAUDE.md" and hopes the user does it. The gap is that CLAUDE.md is generated with TODO markers for Issue Tracker instance and Source Control remote, and nobody verifies those are filled before the first pipeline run fails.

The solution: extend `/onboard --update` to detect scaffold-generated TODO markers and guide the user through filling them. Add a `--from-scaffold` flag (or auto-detect via `state.json` with `pipeline: "scaffold"`) that runs a focused wizard: just the 4-5 values that scaffold could not know (tracker instance URL, project key, remote owner/repo, tokens). Then auto-run `check-setup` to validate. The "standalone machine" is not a new pipeline stage — it is the completion of the existing onboard flow, triggered at the right moment.

**State Machine:**
```
SCAFFOLD_COMPLETE → ONBOARD_DETECT → ONBOARD_WIZARD → CONFIG_COMPLETE → CHECK_SETUP → STANDALONE
                         ↓                                                    ↓
                    ALREADY_COMPLETE                                     SETUP_FAILED
                         ↓                                                    ↓
                      STANDALONE                                         FIX_AND_RETRY
```

**Pros:**
- Tiny scope — extends existing onboard command, no new agents or core files.
- Directly addresses the "last mile" problem: scaffold produces 95% of what's needed, this fills the 5%.
- `check-setup` already validates everything — just need to wire it into the post-scaffold flow.

**Cons:**
- Does not address stages 2-4 (feature loop, forge, deployment). Only solves the final stage.
- User still has to manually provide secrets/tokens — no way around this in a pure-markdown plugin.
- Trivial in isolation — the value comes from composing this with Ideas 1-3, not standalone.

**Effort:** XS (onboard flag + scaffold TODO detection + check-setup auto-invocation guidance)

**Files affected:** `commands/onboard.md` (add --from-scaffold detection), `commands/scaffold.md` (update Step 10 next steps to recommend onboard --update)

**Invariants:**
- `--from-scaffold` NEVER writes values the user did not explicitly provide.
- If CLAUDE.md has no TODO markers, `--from-scaffold` reports "already complete" and exits.
- check-setup is recommended, never auto-run (user might not have MCP servers configured yet).

---

## Idea 5: Lifecycle State Machine Kernel — `parent_run_id` + Phase Registry

**Description:** The minimal kernel that makes all four ideas above composable: add `parent_run_id` to the state schema (backward-compatible, nullable) and create a `core/phase-registry.md` that defines the lifecycle phases and their gateway contracts. When scaffold completes, its state.json records `run_id: "scaffold-20260326-100000"`. When the user later runs `--extend` or creates issue tracker cards (Step 9), the new run's state.json records `parent_run_id: "scaffold-20260326-100000"`. This creates a **run chain** — a linked list of pipeline executions that form a project's lifecycle history.

The phase registry defines 5 lifecycle phases (scaffold, feature-loop, deployment-check, integration, standalone) with entry/exit conditions. Any command can register its run against a phase. `/status` can then show the full project lifecycle state, not just active issues.

This is the **kernel** — the minimal abstraction that enables Ideas 1-4 without requiring them. It is backward compatible (parent_run_id defaults to null), costs almost nothing to implement, and provides the connective tissue for future composition.

**State Machine:** (meta — this is the machine that manages other machines)
```
                    ┌─────────────────────────────────────┐
                    │         Phase Registry               │
                    │                                       │
  scaffold run ────→│  phase: scaffold    ← gateway: none  │
                    │  phase: features    ← gateway: spec/ + CLAUDE.md complete │
  feature runs ───→│  phase: deployment  ← gateway: tests passing │
                    │  phase: standalone  ← gateway: check-setup passes │
  deploy check ───→│                                       │
                    └─────────────────────────────────────┘
                              ↓
                    Linked via parent_run_id chain
```

**Pros:**
- Absolute minimal change — one nullable field in state schema, one core file.
- Backward compatible — existing state.json files work unchanged (parent_run_id = null).
- Enables `/status` to show project lifecycle, `/metrics` to compute cross-phase analytics.
- Foundation for all other ideas — none of them conflict with this kernel.

**Cons:**
- By itself, does nothing visible to the user. Pure infrastructure investment.
- Phase registry is a new contract that all future commands must respect — governance overhead.
- Run chain can grow unbounded — needs a cleanup/archival story eventually.

**Effort:** S (state schema field + core/phase-registry.md + status command lifecycle view)

**Files affected:** `state/schema.md` (add `parent_run_id` field), new `core/phase-registry.md`, `commands/status.md` (optional lifecycle view), `commands/scaffold.md` (record phase marker)

**Invariants:**
- `parent_run_id` is either null or a valid run_id that exists in `.ceos-agents/`.
- Phase transitions are monotonic — a project lifecycle never moves backward (scaffold → features, never features → scaffold).
- The phase registry is advisory — no command is REQUIRED to register. Unregistered runs simply do not appear in the lifecycle view.

---

## Top Recommendation

**Implement Ideas 5 + 2, in that order.**

Idea 5 (Lifecycle Kernel) is the right starting point because it establishes the compositional foundation without committing to any specific workflow. It costs almost nothing (one schema field, one core file) and makes every future extension cleaner. This is the **minimal kernel** question answered: `parent_run_id` + phase registry is the connective tissue.

Idea 2 (Deployment-Verifier) is the highest-value standalone deliverable because it answers the immediate user question ("does my scaffolded app run?") with a proven pattern (reproducer's run_in_background + Playwright). It is a MINOR version bump, requires no breaking changes, and leverages existing infrastructure.

Together, they compose naturally: scaffold completes → deployment-verifier runs within scaffold → state.json records the phase → future feature runs link back via parent_run_id → `/status` shows the full lifecycle.

Ideas 1 and 3 are valuable but larger and should wait until the kernel proves itself. Idea 4 is trivially composable with anything — implement it opportunistically when touching onboard.

**The systems principle at work:** Build the smallest possible abstraction layer (Idea 5) that makes the concrete features (Idea 2) composable with future features (Ideas 1, 3, 4) without requiring those future features to exist yet. This is the difference between designing a system and designing a feature.
