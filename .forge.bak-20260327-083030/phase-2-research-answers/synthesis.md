# Phase 2 Research Answers — Synthesis Report

**Synthesized:** 2026-03-26
**Source agents:** 5 (RQ-01 through RQ-20)
**Research domains:** Foundation, MCP/Bridge, Feature Loop, Deployment, Bridge/Versioning

---

## 1. Synthesis Notes

### Agent Scoring

| Agent | RQs | Evidence Quality (0-5) | Answer Completeness (0-5) | Cross-Ref Awareness (0-5) | Total |
|-------|-----|----------------------|--------------------------|--------------------------|-------|
| Agent 1 — Foundation | RQ-01 to RQ-04 | 5 | 5 | 4 | 14 |
| Agent 2 — MCP + Bridge | RQ-05 to RQ-08 | 4 | 5 | 4 | 13 |
| Agent 3 — Feature Loop | RQ-09 to RQ-12 | 5 | 5 | 5 | 15 |
| Agent 4 — Deployment | RQ-13 to RQ-16 | 5 | 5 | 4 | 14 |
| Agent 5 — Bridge + Versioning | RQ-17 to RQ-20 | 5 | 5 | 4 | 14 |

**Base agent:** Agent 3 (highest score — strongest cross-file traceability with specific line numbers throughout).

### Unique Contributions by Agent

- **Agent 1:** Critical finding that `resume-ticket` Step 10 embeds both pipeline tables rather than calling commands — confirms cross-pipeline reuse requires inline duplication or shared agents, not command invocation. Also surfaced the tool enforcement gap (read-only agents rely on prose, not structural constraints).
- **Agent 2:** Only agent to map the exact TODO placeholder format (`<!-- TODO: -->`) used by scaffolder vs. the `<...>` pattern used by check-setup — identifying a concrete detection gap. Bootstrap sequence (scaffold → onboard --update → init → check-setup) is the clearest procedural synthesis.
- **Agent 3:** Definitive stage-by-stage comparison table for scaffold vs implement-feature (RQ-11) with explicit mandatory-skip count (9 stages). Clear finding that profile-parser stage names are insufficient for scaffold delegation. `parent_run_id` schema recommendation with correct versioning classification.
- **Agent 4:** Structural coupling analysis for browser-verifier (5 specific coupling points listed). `run_in_background` + health poll as the proven pattern for docker orchestration. `Browser Verification` precedent cited directly for new section naming.
- **Agent 5:** Definitive schema comparison (architect YAML vs forge-plan prose) with field-by-field table. AC coverage check failure mode analysis is precise: absence of `maps_to` triggers set-difference calculation, not the malformed-entry fallback. `Verify command` workaround for deploy without version bump.

### Contradictions Resolved

- **RQ-08 (manual vs. onboard --update):** Agent 2 finding that scaffold Final Report does not mention `/onboard --update` as a next step corrects the summary statement that "manual editing is the only path." Both are valid; the gap is a missing cross-reference, not a missing capability.
- **RQ-20 (Verify command for deploy):** Agent 5 introduces a workaround (repurpose `Verify command` as deploy trigger) that Agent 4 does not mention. These are complementary, not contradictory — Agent 4 focuses on the new `check-deploy` command, Agent 5 on minimizing the version bump. Both remain valid options depending on desired depth.
- **RQ-06 vs RQ-08 (TODO detection):** Agent 2 notes check-setup detects `<...>` not `<!-- TODO: -->`. This is internally consistent — both answers come from the same agent and reinforce each other. Confirmed as a real (minor) gap.

---

## 2. Key Findings

Ranked by design impact — a new feature or integration attempt will fail if it misunderstands these.

### KF-1: Command chaining does not exist — all delegation is agent dispatch (Impact: CRITICAL)

There is no mechanism for one command to programmatically invoke another command. The 2-layer model is strict: commands dispatch agents via the Task tool; skills route to commands via `Skill()`. The `resume-ticket` workaround (embedding both pipeline step tables in a single file) is the proven pattern for multi-pipeline commands. Any design requiring command-to-command handoff must replicate the target pipeline inline or factor shared behavior into shared agents.

### KF-2: Scaffold delegation to implement-feature via profiles is structurally impossible (Impact: CRITICAL)

Scaffold Step 7 must skip 9 stages of implement-feature (MCP preflight, set-issue-state, create-branch, spec-analyst, architect, decomposition, all hook stages, publisher, feature-verification) and keep only 4 (fixer, reviewer, test-engineer, commit-subtask). The profile-parser covers only 7 skippable stage names and explicitly forbids skipping fixer/reviewer/publisher. Stage names like `set-issue-state` and `create-branch` are not in the profile-parser's vocabulary. The current scaffold Step 7 inline loop is the correct architecture — it is already the required stripped-down reimplementation.

### KF-3: Forge-plan output is structurally incompatible with implement-feature's AC coverage check (Impact: CRITICAL)

The architect agent produces YAML with a required `maps_to: ["AC-N: text"]` field per subtask. Forge-plan produces prose markdown with no `maps_to` field. The AC coverage check algorithm collects `maps_to` entries and computes set difference against parent AC indices — absence of `maps_to` means zero entries, triggering an "all AC unmapped" result. In YOLO mode this is a hard block. Any forge integration that feeds forge-plan output into implement-feature must translate it to architect YAML format first, adding `maps_to` entries.

### KF-4: browser-verifier cannot be extended for deploy smoke — 5 structural coupling points (Impact: HIGH)

browser-verifier reads `reproduction-result.json` (issue ID + fixer diff + AC), replays a `reproducer-script.js` generated for a specific bug, examines modified routes from the diff, checks AC from bug reports, and namespaces output to `.ceos-agents/{ISSUE-ID}/`. All five coupling points are structural. A new `deployment-verifier` agent is required for deploy smoke checks.

### KF-5: Docker orchestration via Bash is viable using the reproducer pattern (Impact: HIGH)

`agents/reproducer.md` already uses `run_in_background` + health poll + timeout for dev server startup. This pattern maps directly to `docker compose up -d` + container health check loop + `docker compose down` teardown. No architectural blocker exists. The deployment-verifier agent can implement this pattern with confidence.

### KF-6: All new deploy config must be a new optional section — MINOR version bump (Impact: HIGH)

Adding a new optional `Local Deployment` section follows the exact precedent of Browser Verification (v5.0.0 → v5.1.0, MINOR). Making any deploy key required would be MAJOR. The `Verify command` in Build & Test can be repurposed as a deploy trigger without any version bump if full orchestration depth is not needed. A new `Deploy` hook category would be MINOR.

### KF-7: check-setup cannot be extended for deploy — contract violation (Impact: HIGH)

check-setup is contractually "read-only" and "safe for repeated execution." Starting a docker stack is side-effectful and long-running. A new `check-deploy` command is required. check-setup already provides structural validation of any new `Local Deployment` section for free (Block 1 parses all optional sections by convention).

### KF-8: Read-only agent enforcement is prose-only, not structural (Impact: MEDIUM)

Agents like triage-analyst, code-analyst, and reviewer are constrained to read-only behavior by prose instructions only. No tool-level restriction prevents them from calling Write or Edit. The `allowed-tools` declaration in commands is the ceiling for the command context, but whether subagents dispatched via Task inherit that ceiling is unconfirmed. This is a design-level trust assumption, not a runtime guarantee.

### KF-9: Crash resume is best-effort — in_progress steps re-execute (Impact: MEDIUM)

The state manager prevents corrupt state (atomic writes via tmp rename) but not stale state. A crash mid-step leaves the step as `in_progress` and the step re-executes in full on resume. Fixer-reviewer iteration counts survive crashes only if the completion write succeeded before the crash. The most fragile scenario is a crash inside a git operation (state shows preceding step completed, git state may not match). This is a known, documented design tradeoff — not a bug.

### KF-10: Cross-plugin Skill() calls are unvalidated — the bridge is EXPLORING, not implemented (Impact: MEDIUM)

Zero cross-plugin Skill() calls exist anywhere in the ceos-agents codebase. The roadmap lists the cross-plugin bridge as EXPLORING. Whether `Skill(skill='filip-superpowers:forge-plan', ...)` works at runtime is unknown from static analysis. Any integration design that depends on this must validate it empirically before committing.

---

## 3. Full Answers

### RQ-01: Command chaining capability

**Answer:** No command chaining exists. Every cross-unit delegation uses `Task tool` dispatching a named agent. The only `Skill()` calls in the codebase are in `skills/bug-workflow/SKILL.md` (skill routing to commands), never from commands to other commands. `resume-ticket` Step 10 appears to call other commands but does so by embedding both pipeline step tables inline as prose reference, not programmatic invocation.

**Evidence summary:** All 24 commands examined — none contain slash-command invocations of other commands. `fix-bugs.md`, `fix-ticket.md`, `implement-feature.md`, `scaffold.md` all delegate exclusively via `Task tool → agent name`.

**Confidence:** HIGH

**Implications:** Cross-pipeline reuse requires inline duplication or shared agent definitions. The resume-ticket embedding pattern is the established workaround. No command composition layer exists or can be easily added within the current architecture.

---

### RQ-02: Skill() cross-plugin namespace scope

**Answer:** Unconfirmed. Zero cross-plugin Skill() calls exist in ceos-agents. The roadmap classifies the cross-plugin bridge as EXPLORING. Runtime support for `Skill(skill='other-plugin:name')` is not documented or validated anywhere in the inspectable codebase.

**Evidence summary:** All `Skill()` calls in `skills/bug-workflow/SKILL.md` use `ceos-agents:` namespace only. `.forge.bak` research artifacts list cross-plugin Skill() as an open question from prior research cycles.

**Confidence:** MEDIUM (absence confirmed; runtime support NEEDS_VALIDATION)

**Implications:** Any integration design depending on ceos-agents calling `filip-superpowers:forge-plan` must empirically validate runtime support before committing to it. If unsupported, the only integration paths are prose documentation or logic duplication.

---

### RQ-03: allowed-tools hard capability ceiling

**Answer:** The `allowed-tools` frontmatter in commands is the designed security boundary for that command's execution context. All 24 commands declare the identical set: `mcp__*, Bash, Read, Write, Edit, Glob, Grep, Task`. Plugin.json contains zero tool declarations. Skills have no `allowed-tools` field and inherit unrestricted session access. Whether Task-dispatched agents are constrained by the parent command's `allowed-tools` is unconfirmed by codebase inspection.

**Evidence summary:** Frontmatter confirmed across fix-ticket, fix-bugs, implement-feature, scaffold. `plugin.json` verified to contain only metadata fields. Agent definitions (`agents/*.md`) contain no `allowed-tools` frontmatter.

**Confidence:** HIGH for command-level ceiling. MEDIUM for agent tool inheritance (NEEDS_VALIDATION).

**Implications:** Read-only enforcement for triage-analyst, code-analyst, reviewer is prose-only. No structural runtime guarantee. A malfunctioning agent could technically call Write even though instructed not to.

---

### RQ-04: Mid-session crash resume consistency

**Answer:** Best-effort, not guaranteed-consistent. Atomic writes via `.tmp` rename prevent corrupted state files but not stale state. A crash mid-step leaves the step as `in_progress` and it re-executes fully on resume. Heuristic fallback activates when no state file exists. State loss is explicitly non-fatal by design.

**Evidence summary:** `core/state-manager.md` specifies atomic write, retry-once-then-log-warning failure handling, and heuristic fallback for corrupted state. `state/schema.md` Step Status Enum confirms `in_progress` is written at phase start and `completed` at phase end — a crash between these causes re-execution.

**Confidence:** HIGH

**Implications:** Re-execution of already-completed steps is a known cost. The most fragile crash point is inside git operations. Fixer iteration counts survive crashes only when the completion write preceded the crash. Acceptable tradeoff for the use case.

---

### RQ-05: MCP server capability scope — project-level vs issue-level

**Answer:** The plugin uses MCP exclusively at issue-level (query, state update, comment) and PR-level (create PR, add label). No project-level operations (create repository, create project/board, create milestone) are called or documented. Whether the underlying MCP packages expose such tools is unknown from this codebase.

**Evidence summary:** `examples/mcp-configs/` contains only connection wrappers — no tool capability enumeration. `commands/check-setup.md` Block 3 and `commands/init.md` Step 7 validate only issue query and repo listing. `scaffold.md` Step 9 creates issue cards (issue-level) under an already-configured project, not the project itself.

**Confidence:** HIGH for plugin scope. LOW for package capability scope (NEEDS_VALIDATION).

**Implications:** The `mcp__*` wildcard in `allowed-tools` is a potential latent risk if underlying packages expose project-creation tools — a misconfigured agent could inadvertently call them. Worth inspecting `@modelcontextprotocol/server-github` and `forgejo-mcp` package capability lists.

---

### RQ-06: Scaffold bootstrap sequence and TODO placeholder design

**Answer:** The intended bootstrap sequence is: (1) `/scaffold` generates project + CLAUDE.md with `<!-- TODO: -->` markers, (2) manual edit or `/onboard --update` replaces TODO values, (3) `/init` configures MCP and tokens, (4) `/check-setup` validates. The scaffold Final Report explicitly documents this but omits `/onboard --update` as an alternative to manual editing.

**Evidence summary:** `scaffolder.md` Process step 3 specifies `<!-- TODO: Replace with your actual ... -->` for Instance, Project, Remote. `scaffold.md` Step 9 explicitly skips card creation when TODO markers present. `onboard.md` Step U1 walks all sections interactively. `check-setup.md` uses `<...>` pattern for placeholder detection.

**Confidence:** HIGH

**Implications:** Minor gap: check-setup detects `<YOUR_*>` angle-bracket placeholders but not `<!-- TODO: -->` HTML comment markers. A user who replaces `<YOUR_INSTANCE>` with a literal TODO comment would pass check-setup's placeholder check. Low risk in practice; worth noting in documentation.

---

### RQ-07: Scaffold build/test against missing infrastructure

**Answer:** The scaffolder is required to generate `.env.test` with test-specific values and dynamic port allocation, plus create/teardown test fixtures for DB projects. This prevents port conflicts and cleans up state. However, no constraint mandates service-free test execution — DB-dependent projects may require a running database for local tests to pass. CI coverage is assured via service containers in the generated CI config.

**Evidence summary:** `agents/scaffolder.md` Batch 3 mandates `.env.test`, dynamic port allocation, and DB test fixtures. Constraints section: "Generated skeleton MUST build, MUST pass tests, MUST pass linter." But no explicit "tests must pass without any running service" constraint exists. Scaffolder generates CI service containers (Batch 4) for DB dependencies.

**Confidence:** MEDIUM (structural requirements clear; functional sufficiency for local service-free execution is LLM-dependent)

**Implications:** For PostgreSQL/MySQL projects scaffolded in a clean environment, local `pytest` or `npm test` may fail without a running DB. CI passes because of generated service containers. Recommend adding an explicit constraint to `scaffolder.md` requiring SQLite fallback or mocking for unit tests in DB-dependent projects.

---

### RQ-08: Scaffold-to-implement-feature handoff — missing finalize step

**Answer:** No `/scaffold-finalize` command exists. The functional alternative is `/onboard --update`, which walks all Automation Config sections interactively and will replace TODO placeholders when the user provides real values. The scaffold Final Report does not mention this command — that is the gap. Manual editing remains the only *documented* path; `/onboard --update` is an undocumented but functional alternative.

**Evidence summary:** `/scaffold-finalize` is not among the 24 commands. `commands/onboard.md` Step U0 detects existing config; Step U1 iterates sections. `scaffold.md` Step 10 next-steps list manual editing, check-setup, scaffold-validate — no mention of onboard.

**Confidence:** HIGH

**Implications:** Quick fix: add `/ceos-agents:onboard --update` as an option in the scaffold Final Report's next-steps list. No new command needed — the capability already exists.

---

### RQ-09: Setup-validation gate placement before the feature loop

**Answer:** A new Step 0b (Config validity check) should be inserted after the MCP pre-flight check (Step 0) and before Step 1 (Set issue state) in `implement-feature.md`. It should validate Automation Config structure only (equivalent to Block 1 of check-setup.md) — not run build/test commands. This prevents partial side effects (issue state mutation, branch creation) caused by config errors discovered mid-pipeline.

**Evidence summary:** `commands/implement-feature.md` Step 0 is MCP pre-flight only. Steps 1 onward mutate tracker state and create git branches. `commands/check-setup.md` Block 1 performs full structural config validation. `commands/status.md` references a `.claude/setup-validated` marker but nothing writes it or enforces it.

**Confidence:** HIGH

**Implications:** A config error (missing required key, placeholder not replaced) currently surfaces after irreversible side effects have occurred. Step 0b is a low-cost addition — read CLAUDE.md, verify all required keys exist and are non-placeholder, stop with guidance if not.

---

### RQ-10: Cross-run parent/child relationship in state schema

**Answer:** No `parent_run_id` field exists in the current state schema (schema_version 1.0). Adding it as an optional field (`string | null`, default `null`) is a backward-compatible MINOR change. It would enable `/metrics` lineage attribution, `/resume-ticket` scaffold context surfacing, and future dashboard views of scaffold→feature trees.

**Evidence summary:** `state/schema.md` lines 29-183 reviewed in full — no cross-run reference field exists. `run_id` for scaffold uses format `scaffold-{timestamp}`; feature runs use Issue ID. `commands/metrics.md` reconstructs cross-run history from issue tracker comments, not state files.

**Confidence:** HIGH

**Implications:** Without `parent_run_id`, a feature run processed by implement-feature has no programmatic link back to the scaffold run that created the project. The metrics command works around this via comment parsing, which is fragile. Adding the field is low-cost and schema-version-safe.

---

### RQ-11: Scaffold-to-implement-feature delegation — pipeline stage delta

**Answer:** Delegation via the profile-parser is structurally impossible. Scaffold would need to skip 9 stages of implement-feature (including `set-issue-state`, `create-branch`, all hooks, `publisher`, `feature-verification`) that are not in the profile-parser's stage vocabulary. The profile-parser covers only 7 stage names and explicitly disallows skipping fixer/reviewer/publisher. The current scaffold Step 7 inline loop is the correct architecture — it is already the required stripped-down reimplementation of the fixer→reviewer→test-engineer→commit cycle.

**Evidence summary:** `core/profile-parser.md` valid skip stages: triage, code-analyst, spec-analyst, test-engineer, e2e-test-engineer, reproducer, browser-verifier. `commands/implement-feature.md` steps 0-10 enumerated. Stage-by-stage comparison table produced: 9 mandatory skips, 4 must-keep stages.

**Confidence:** HIGH

**Implications:** Do not attempt to refactor scaffold Step 7 to delegate to implement-feature via profiles. The current inline loop is the right abstraction. If the fixer→reviewer→test-engineer loop needs enhancement, update both scaffold Step 7 and implement-feature's core loop in parallel.

---

### RQ-12: docker-compose.yml ownership — scaffolder vs scaffold-add

**Answer:** Current ownership is correct. `docker-compose.yml` belongs to `scaffold-add docker`, not to the scaffolder's baseline pass. Scaffolder produces a minimal buildable skeleton (Dockerfile + .dockerignore + CI with service containers). Compose is orchestration-layer and should remain opt-in via scaffold-add.

**Evidence summary:** `agents/scaffolder.md` Batch 4 enumerates: Dockerfile, .dockerignore, CI config — no `docker-compose.yml`. `commands/scaffold-add.md` docker component explicitly includes `docker-compose.yml`.

**Confidence:** HIGH

**Implications:** No change needed. If a scaffold run detects a multi-service spec, the quality scorecard could add a WARN informing the user to run `/scaffold-add docker` — informational only, not a structural change.

---

### RQ-13: browser-verifier extension vs new deployment-verifier agent

**Answer:** A new `deployment-verifier` agent is required. browser-verifier has 5 structural coupling points to the bug-fix pipeline that cannot be repurposed for deploy smoke without gutting the agent: (1) reads `reproduction-result.json` for issue ID/diff/AC, (2) replays `reproducer-script.js` per issue ID, (3) reads fixer diff to identify modified routes, (4) performs AC check based on bug-fix criteria, (5) namespaces output to `.ceos-agents/{ISSUE-ID}/`. Deploy smoke has different inputs (target URL, health endpoints, expected page states) and different success criteria.

**Evidence summary:** `agents/browser-verifier.md` Steps 1, 3a, 3b, 3c, 5 and the `FAILED → return to fixer` verdict reviewed directly.

**Confidence:** HIGH

**Implications:** The new deployment-verifier agent needs its own config keys (separate from `On events: reproduce, verify`), its own output namespace (e.g., `.ceos-agents/deploy/{timestamp}/`), and its own verdict-to-pipeline feedback logic (fail → block deploy, not return to fixer).

---

### RQ-14: Long-running docker orchestration via Bash tool — viability

**Answer:** Viable. The `run_in_background` + health poll pattern in `agents/reproducer.md` maps directly to `docker compose up -d` + container health check loop + `docker compose down` cleanup. No architectural blocker exists. The reproducer pattern is purpose-built for "start a background process, wait for it to be ready, then proceed."

**Evidence summary:** `agents/reproducer.md` Step 2 uses `run_in_background` for dev server startup, retries health check up to 15 seconds, then proceeds. Step 5 tears down via `pkill -f "{Start command pattern}"`. Direct structural mapping to docker compose lifecycle.

**Confidence:** HIGH

**Implications:** deployment-verifier agent can confidently implement this pattern. Key implementation details: prerequisite check (`docker`, `docker compose version`), `compose up -d` in background, poll `/health` or `docker compose ps` for readiness, write result JSON, agent reads JSON, cleanup `compose down`.

---

### RQ-15: New Local Deployment config section vs extending Build & Test

**Answer:** A new optional `Local Deployment` section is the correct approach. It follows the Browser Verification precedent (added as own section rather than extending E2E Test). This keeps Build & Test semantically clean (build artifacts + test runs) and gives deployment config its own keys without ambiguity. The `Verify command` in Build & Test remains as a post-merge URL smoke check, distinct from full stack orchestration.

**Evidence summary:** `core/config-reader.md` and `CLAUDE.md` Build & Test section contains 3 keys (build_command, test_command, verify_command). Browser Verification added 8 keys as a standalone section. Versioning policy: optional section = MINOR.

**Confidence:** HIGH

**Implications:** MINOR version bump. Recommended keys: `Compose file` (default: `docker-compose.yml`), `Health check URL`, `Services` (list of expected containers), `Startup timeout`, `Teardown strategy` (always/on-success/never).

---

### RQ-16: check-setup extension vs new check-deploy command

**Answer:** A new `check-deploy` command is required. check-setup's contract is "read-only, safe for repeated execution." Starting a docker stack is side-effectful and long-running — adding it would violate the contract and compound flag proliferation (`--skip-build`, `--skip-deploy`). check-setup already provides structural validation of a `Local Deployment` section for free via Block 1. check-deploy handles: parse Local Deployment section, `docker compose up`, poll health endpoints, report container status, `docker compose down`.

**Evidence summary:** `commands/check-setup.md` Block 4 is the only side-effectful block (`Build command`, `Test command`) with a `--skip-build` escape hatch. The read-only/safe-for-repeated-execution contract is explicit in the file.

**Confidence:** HIGH

**Implications:** check-deploy follows the same `[OK]/[FAIL]/[SKIP]` output format as check-setup for consistency. It can be invoked standalone or referenced in the scaffold Final Report's next-steps list. Total command count: 24 + 1 = 25 if added.

---

### RQ-17: Forge-Plan vs Architect Task Tree Schema — Compatibility

**Answer:** Structurally incompatible. The architect produces YAML with 8 required fields per subtask including `maps_to` (used for programmatic AC traceability). Forge-plan produces prose markdown with `**Change:**`, `**Acceptance:**` (a shell command), and `**Dependencies:**` — no `maps_to` field, no `acceptance_criteria` list, no `id` field in YAML format, no `strategy`/`reason` top-level fields.

**Evidence summary:** `agents/architect.md` lines 46-65 YAML schema read directly. `.forge.bak-20260325-204006/phase-6-plan/final.md` forge-plan output read directly. Field-by-field comparison table produced.

**Confidence:** HIGH (both formats read from real artifacts)

**Implications:** Any forge integration that feeds forge-plan output into implement-feature's decomposition step must translate it to architect YAML first. The translation must synthesize `maps_to` entries (mapping tasks to parent AC indices) that forge-plan does not produce. This is a non-trivial transformation requiring AC context.

---

### RQ-18: Forge-Plan AC Coverage Check — Always Fails

**Answer:** Yes, the AC coverage check would always produce a warning or hard block on unmodified forge-plan output. The algorithm collects `maps_to` fields from all subtasks (finds zero), computes set difference against parent AC count (all unmapped), and reports. In YOLO mode: hard block. In non-YOLO mode: warning with `[Y/n]` override. The malformed-entry fallback (treat as warning, not error) does not apply when the field is entirely absent.

**Evidence summary:** `commands/implement-feature.md` lines 123-137 AC coverage check algorithm read directly. Algorithm: collect all N from `maps_to: ["AC-N: ..."]` entries → verify 1..{total AC count} all appear → set-difference yields unmapped. Forge-plan has zero `maps_to` fields.

**Confidence:** HIGH

**Implications:** The translation layer between forge-plan and implement-feature is mandatory, not optional. It must add `maps_to` entries. If the forge integration is designed to skip the AC coverage check (e.g., via YOLO mode + user override), the traceability guarantee is lost.

---

### RQ-19: Epic-to-Card Creation Sequence — Pre vs Post-Implementation

**Answer:** Post-implementation card creation (scaffold Step 9 model) is more compatible with MCP capabilities. It avoids MCP as a blocking pre-condition — implementation proceeds on local git state alone. MCP is optional, interactive, and gracefully degraded via TODO-marker detection. Pre-implementation creation (implement-feature model) is correct when the issue tracker is the authoritative work driver; post-implementation is correct when the tracker is a downstream notification target.

**Evidence summary:** `commands/implement-feature.md` Step 0 MCP pre-flight is first action before any branch or state mutation. `commands/scaffold.md` Step 9 MCP is only required with `--issue` flag or at optional card creation step; Full YOLO skips entirely.

**Confidence:** HIGH

**Implications:** For a forge integration that runs implement-feature pipelines as part of scaffold, tracker availability should not be a blocking prerequisite for implementation. Design should follow the post-implementation card model: implement fully, then optionally create tracker cards, degrade gracefully if tracker is unavailable.

---

### RQ-20: Versioning Impact of New Optional Config Keys

**Answer:** New optional `Local Deployment` section = MINOR bump. Making any key required = MAJOR. New `Deploy` hook category = MINOR. Repurposing `Verify command` as deploy trigger = no bump (within current contract). Existing hooks (Pre/Post-fix, Pre/Post-publish) are insufficient for post-merge deployment — there is no post-merge hook.

**Evidence summary:** `CLAUDE.md` versioning policy table: "Adding an optional section = MINOR." Browser Verification was v5.0.0 → v5.1.0 (MINOR precedent). `commands/implement-feature.md` lines 277-280 confirm `Post-publish` fires on `pr-created`, not on merge. `Verify command` runs after merge but is a verification command, not a hook.

**Confidence:** HIGH for versioning rules. MEDIUM for Verify command workaround (inferred, not validated).

**Implications:** The deployment feature set can be shipped as a single MINOR release: new `Local Deployment` config section + new `deployment-verifier` agent + new `check-deploy` command + new `Deploy` hook category (if needed for post-merge automation). No MAJOR bump required if all deploy config keys are optional.

---

## 4. NEEDS_VALIDATION Items

Items confirmed as requiring empirical testing before design commitments can be made.

| ID | RQ | Item | Risk if Wrong |
|----|-----|------|---------------|
| NV-01 | RQ-02 | Empirically invoke `Skill(skill='filip-superpowers:forge-status')` from a ceos-agents context to confirm cross-plugin Skill() runtime support | Cross-plugin bridge design is invalid if unsupported |
| NV-02 | RQ-03 | Confirm whether Task-dispatched agents inherit the parent command's `allowed-tools` or receive unrestricted access | Read-only agent enforcement is weaker than assumed if agents get broader access |
| NV-03 | RQ-05 | Inspect `@modelcontextprotocol/server-github` and `forgejo-mcp` package capability lists for project-level tools (create_repo, create_milestone, etc.) | `mcp__*` wildcard could permit inadvertent project-creation calls |
| NV-04 | RQ-06 | Verify that `/onboard --update` correctly handles `<!-- TODO: -->` HTML comment placeholders (does pressing Enter skip the field or clear it?) | Users could inadvertently leave TODO markers unresolved after running onboard |
| NV-05 | RQ-07 | Scaffold a PostgreSQL + Python FastAPI project and run tests in a clean environment without a running Postgres — confirm whether tests pass or require a live DB | DB-dependent scaffolded projects may fail in CI or local dev without running services |
| NV-06 | RQ-16 | Determine whether `check-deploy` should be a standalone command or `check-setup --deploy` subcommand flag (discoverability vs. contract purity tradeoff) | Discoverability suffers if standalone; read-only contract violated if flag approach taken |
| NV-07 | RQ-20 | Validate that using `Verify command` as a deploy trigger is sufficient for typical deploy scenarios (does it receive enough context to start+verify a stack?) | Workaround may be too constrained for full deploy orchestration |

---

## 5. Design Constraints Map

### POSSIBLE (confirmed from codebase)

- New `deployment-verifier` agent using the `run_in_background` + health poll pattern from reproducer
- New optional `Local Deployment` config section (MINOR bump, Browser Verification precedent)
- New `check-deploy` command with `[OK]/[FAIL]/[SKIP]` output format
- Adding `parent_run_id: null` field to state schema (MINOR, backward-compatible)
- Adding Step 0b (Config validity check) to `implement-feature.md` before Step 1
- Forge-plan → architect YAML translation layer with synthesized `maps_to` entries
- Post-implementation tracker card creation following scaffold Step 9 model
- `/onboard --update` as an undocumented-but-functional alternative to manual CLAUDE.md editing post-scaffold
- `Verify command` repurposed as deploy trigger (no version bump required)
- scaffold Step 7 inline loop continuing as the correct architecture for scaffold-time feature implementation

### IMPOSSIBLE (confirmed architectural limits)

- Command chaining (one command programmatically invoking another command)
- Profile-parser stage skipping for scaffold→implement-feature delegation (9 required skips, only 7 stage names in parser vocabulary, explicit prohibition on skipping publisher)
- Extending browser-verifier for deploy smoke without structural redesign (5 hard coupling points)
- Adding docker stack orchestration to check-setup without violating its read-only/safe-for-repeated-execution contract
- Forge-plan output passing implement-feature's AC coverage check without translation (zero `maps_to` fields → all AC unmapped → warning/block)
- Making any deploy config key required without a MAJOR version bump

### UNCERTAIN (requires validation or design decision)

- Cross-plugin Skill() calls: `Skill(skill='filip-superpowers:...')` — runtime support unconfirmed (NV-01)
- Task-dispatched agent tool access scope — whether agents are bounded by parent command's `allowed-tools` (NV-02)
- Whether `/onboard --update` correctly handles `<!-- TODO: -->` vs. `<YOUR_*>` placeholder formats (NV-04)
- Service-free local test execution for DB-dependent scaffolded projects (NV-05)
- Optimal command surface for deploy verification: standalone `check-deploy` vs. `check-setup --deploy` (NV-06)
- `Verify command` workaround sufficiency for full deploy orchestration (NV-07)
- Whether project-level MCP tools are exposed by underlying packages (NV-03)
