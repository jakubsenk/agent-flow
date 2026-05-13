# Roadmap

Current priorities and future direction for the ceos-agents plugin.

> **Current version:** v9.6.1
> **Last updated:** 2026-05-11

---

## How to Read This

| Section | Meaning |
|---------|---------|
| **DONE** | Completed work — serves as reference material and zadání template for future versions |
| **PLANNED — vX.Y.Z** | Committed to a specific version, designed, ready to implement |
| **PLANNED — Next** | Will happen soon, no version assigned yet |
| **BACKLOG** | Designed (has plan/design doc), waiting for a slot |
| **EXPLORING** | Interesting direction, needs design work before committing |
| **VISION** | Big ideas, separate projects, no concrete plan |
| **NOT PLANNED** | Evaluated and rejected (with reason) |

---

## DONE — v4.1.0 (Quality, DX & Customization)

### Adversarial Review + Edge Case Hunter
**Source:** BMAD adoption, Bod 1+2
Reviewer gets adversarial stance, must find minimum 3 issues per review, systematically traces edge cases.
Severity tiers: HIGH / MEDIUM / LOW. **Files:** `agents/reviewer.md`

### TDD-First in Fixer
**Source:** BMAD adoption, Bod 3
Fixer follows red-green-refactor. Fallback for projects without test infrastructure.
**Files:** `agents/fixer.md`

### Agent Style Metadata
**Source:** BMAD adoption, Bod 10
`style` field in every agent's frontmatter. **Files:** all 15 `agents/*.md`

### Intelligent Guidance in /status
**Source:** BMAD adoption, Bod 6
"Recommended Next Steps" section with context-aware suggestions. **Files:** `commands/status.md`

### Brainstorming Phase for Scaffold
**Source:** BMAD adoption, Bod 4+11
`--brainstorm` flag + auto-trigger for vague descriptions + anti-bias rules. **Files:** `commands/scaffold.md`

### Agent Overrides (Per-Project Customization)
**Source:** BMAD adoption, Bod 5
`customization/` directory with per-agent markdown files. New optional config key: `Agent Overrides`.
**Files:** `CLAUDE.md`, `commands/fix-ticket.md`, `commands/fix-bugs.md`, `commands/implement-feature.md`, `commands/scaffold.md`

### YOLO Mode for All Pipeline Commands
**Source:** BMAD adoption, Bod 9
`--yolo` flag for `fix-ticket` and `implement-feature`. **Files:** `commands/fix-ticket.md`, `commands/implement-feature.md`

### Pipeline Checklists
**Source:** BMAD adoption, Bod 8
Dedicated checklist files per pipeline phase. Agents reference them as validation gates.
**Files:** new `checklists/` directory

### Multi-Agent Discussion (`/discuss`)
**Source:** BMAD adoption, Bod 12
New command: multi-agent discussion with synthesis. **Files:** new `commands/discuss.md`

---

## DONE — v5.0.0 (AC-Driven Pipelines)

### AC-Driven Pipelines (Acceptance Criteria as Red Thread)
**Source:** Multi-agent discussions (`2026-03-08-{bugfix,feature,scaffold}-pipeline-discuss.md`)
**Evaluation:** `2026-03-08-ac-pipeline-evaluation.md` (28 sources, 22 proposals → 12 unified + 3 deferred to v5.1+ + 3 dropped)
**Implementation plan:** `2026-03-08-ac-pipeline-v5-plan.md`

**MAJOR version** — breaking change in agent output format contract (triage-analyst checkpoint comment, reviewer AC Fulfillment section, architect `maps_to` field).

All 12 unified changes implemented across 5 phases. 3 deferred to v5.1+.

**Files:** `agents/triage-analyst.md`, `agents/reviewer.md`, `agents/spec-analyst.md`, `agents/architect.md`, `agents/fixer.md`, `agents/scaffolder.md`, `agents/spec-reviewer.md`, `agents/spec-writer.md`, new `agents/acceptance-gate.md`, `commands/fix-bugs.md`, `commands/fix-ticket.md`, `commands/implement-feature.md`, `commands/scaffold.md`, `CLAUDE.md`

---

## DONE — v5.1.0 (Browser Verification)

### Browser-Based Bug Reproduction & Verification

Two-phase browser automation bookending the fix pipeline.

**Phase 1 — Reproduction (before fixer):** `reproducer` agent generates a Playwright script from triage `reproduction_steps`, executes it via Bash, collects structured evidence (accessibility snapshot, console errors, network failures) → passes to fixer as JSON. Never blocks pipeline.

**Phase 2 — Verification (after test-engineer):** `browser-verifier` agent runs in two sub-phases: (A) scoped verification — replays reproduction steps, checks adjacent pages, visual AC sanity check — binding PASS/FAIL verdict; (B) guided exploration (optional, `Exploration: enabled`) — read-only adjacent UI check — soft evidence only, never blocks.

**Architecture:** Hybrid Script approach (agent generates Playwright script → Bash executes → reads results from disk). Does NOT use `@playwright/mcp` directly — avoids Claude Code sub-agent MCP access blocker (bug #13605).

**Dependencies:** Playwright installed in consuming project (`npm install playwright`). Application must be running or `Start command` set. New optional config section: `Browser Verification` (8 keys).

**Files:** `agents/reproducer.md`, `agents/browser-verifier.md` (new), `agents/triage-analyst.md`, `commands/fix-ticket.md`, `commands/fix-bugs.md`, `CLAUDE.md`, `docs/reference/automation-config.md`, `docs/reference/agents.md`

---

## DONE — v5.2.0 (State Management + Core Extraction)

### State Management Infrastructure
**Source:** forge pipeline analysis (`.forge/phase-2-research-answers/`)

Persistent pipeline state via `.ceos-agents/{ISSUE-ID}/state.json`. Captures pipeline position,
step statuses, triage AC text, complexity, profile, iteration counts. Atomic writes (temp+rename).
Resume-ticket prefers state.json with heuristic fallback for pre-v5.2 tickets.

**Files:** new `state/schema.md`, new `core/state-manager.md`, `commands/fix-ticket.md`,
`commands/fix-bugs.md`, `commands/implement-feature.md`, `commands/scaffold.md`,
`commands/resume-ticket.md`, `CLAUDE.md`

### Core Pattern Extraction
**Source:** forge pipeline analysis — 10 shared patterns identified across 4 pipeline commands

Extracted duplicated pipeline logic into `core/` directory with explicit contracts
(Purpose, Input, Output, Failure). All 4 pipeline commands refactored to reference core files.

**Files:** 10 new `core/*.md` (config-reader, mcp-preflight, fixer-reviewer-loop, block-handler,
agent-override-injector, decomposition-heuristics, profile-parser, post-publish-hook,
fix-verification, state-manager)

### Bug Fixes
- Fix `.claude/` race condition: browser artifacts use per-issue `.ceos-agents/{ID}/` paths
- Fix spec-writer missing 🔴 emoji in block comment
- Fix discuss command gap in skill router (23→24 entries)
- Update 3 fragile tests, add 6 new structural tests (20 total)

---

## DONE — v5.3.0 (Scaffold-to-Deployment Workflow)

Merged planned v5.3.0 (Guided Handoff) and v5.4.0 (Feature from Chat + Deploy) into a single release.
Implemented via forge pipeline (10 phases).

### Scaffold Auto-Finalize (Steps 4b/4c)
**Source:** forge pipeline analysis (2026-03-26)
Scaffold interactively configures tracker values (Instance, Project, Remote) after skeleton generation.
Full YOLO skips. **Files:** `commands/scaffold.md`

### Config Validity Gate (Step 0b)
**Source:** forge pipeline analysis (2026-03-26)
`implement-feature` and `fix-ticket` validate Automation Config for TODO markers before starting.
Blocks with actionable error pointing to `/onboard --update`.
**Files:** `commands/implement-feature.md`, `commands/fix-ticket.md`

### Status Readiness Mode (Step 6b)
**Source:** forge pipeline analysis (2026-03-26)
`/status` shows Configuration Readiness table (Check/Status/Detail). Soft MCP check + build tooling check.
**Files:** `commands/status.md`

### Feature from Description (`--description` flag)
`/implement-feature --description "dark mode toggle"` creates tracker card and implements in one command.
Duplicate detection before card creation. **Files:** `commands/implement-feature.md`

### Workflow Router Feature Routing
Natural language feature descriptions routed to `implement-feature --description`.
**Files:** `skills/workflow-router/SKILL.md` (31 intent rows, was 27)

### Local Deployment Verification
`deployment-verifier` agent (19th) + `/check-deploy` command (25th) + `Local Deployment` config section (6 keys).
Docker support with port conflict detection. Native (non-Docker) also supported.
**Files:** `agents/deployment-verifier.md`, `commands/check-deploy.md`, `CLAUDE.md`, `core/config-reader.md`

### Skill Rename: bug-workflow → workflow-router
Renamed to reflect broader scope (bugs, features, scaffolding, deployment).
**Files:** `skills/workflow-router/SKILL.md`

### State Schema: parent_run_id
Optional field linking child pipeline runs to parent (scaffold → feature runs).
**Files:** `state/schema.md`

---

## DONE — v5.4.0 (Analysis Improvements)

### Issue Quality Gate
**Source:** Contributor PR #1 (Vít Ludwig)
`triage-analyst` and `spec-analyst` validate ticket quality using functional questions instead of checking section names. Blocks incomplete tickets with concrete feedback.
**Files:** `agents/triage-analyst.md`, `agents/spec-analyst.md`

### Reproduction Walkthrough + Root Cause Sanity Check
`code-analyst` step 7: mandatory step-by-step trace of reproduction steps against code. Step 8: gate question "If I fix this, will repro steps produce expected behavior?" Iteration limit via `Root cause iterations` config key (default: 3).
**Files:** `agents/code-analyst.md`

### Partial Report Mode
When root cause cannot be confirmed, `code-analyst` produces non-blocking partial report with boundary explanation and next steps. Pipeline blocks at orchestrator level.
**Files:** `agents/code-analyst.md`, `commands/fix-ticket.md`, `commands/fix-bugs.md`

### Module Docs Config Section
Optional section with `Path` key for per-module documentation. Consumed by code-analyst and architect.
**Files:** `CLAUDE.md`, `agents/code-analyst.md`, `agents/architect.md`, `commands/onboard.md`

---

## DONE — v5.5.x (Scaffold Infrastructure + Version-Check)

### v5.5.0 — Scaffold Infrastructure Integration
**Source:** v5.5.0 brainstorm (3 personas, Phase 3 synthesis)

Step 0-INFRA (infrastructure declaration) + Step 0-MCP (MCP verification) at scaffold start. Step 4 auto-fills CLAUDE.md from MCP data, generates `.mcp.json.example`. Step 4d pushes to remote. Step 4e creates tracker issues from spec epics (accumulator pattern for partial failure).

Replaced Steps 4b/4c (auto-finalize) and Step 9 (issue tracker) with upfront infrastructure workflow.

**Files:** `commands/scaffold.md`, `README.md`, `docs/architecture.md`, `docs/reference/pipelines.md`

### v5.5.1–v5.5.3 — Version-Check Rewrite
Complete rewrite of `/version-check`: Part A (installed plugin status from any directory), Part B (repo comparison in plugin repo), Part C (auto-update cache with rsync/robocopy). Resilient registry lookup, semver comparison via `sort -V`, 10 explicit error paths.
**Files:** `commands/version-check.md`

---

## DONE — v5.6.0 (Scaffold Infrastructure Polish)

### core/mcp-detection.md — Shared MCP Detection Contract
**Source:** v5.5.0 brainstorm (all 3 personas), Phase 3 synthesis
Extracted MCP detection logic (tracker type → MCP package lookup + connectivity check + canary-write) into `core/mcp-detection.md` contract. `commands/scaffold.md` (Step 0-MCP) and `commands/init.md` (Steps 3, 7) now reference the shared contract instead of inline logic.
**Files:** `core/mcp-detection.md` (new), `commands/scaffold.md`, `commands/init.md`

### init.md .mcp.json.example Detection
**Source:** v5.5.0 brainstorm (Persona 2 — UX Designer)
New Step 1b in init.md: detects existing `.mcp.json.example` and pre-fills tracker type, instance URL, and remote. Reduces redundant prompts for scaffold-then-init workflow.
**Files:** `commands/init.md`

### state.json Infrastructure Field
**Source:** v5.5.0 brainstorm (Persona 3 — Systems Thinker)
Added optional `infrastructure` object to `state.json` schema persisting Step 0-INFRA declarations (tracker/SC readiness, type, instance, project, remote). Enables resume after mid-scaffold crash.
**Files:** `state/schema.md`, `core/state-manager.md`, `commands/scaffold.md`

### --infra CLI Flag for Scaffold
**Source:** v5.5.0 brainstorm (Persona 2 — UX Designer)
`--infra ready,later` or `--infra later,later` pre-answers Step 0-INFRA questions. Enables fully unattended scaffold in CI/automation. Consistent with --lang, --framework, --db patterns.
Format changed to named pairs (`tracker:ready,sc:later`) in v5.6.1.
**Files:** `commands/scaffold.md`

### Step 0-MCP Canary-Write Check
**Source:** v5.5.0 verification (Devil's Advocate — P2)
After successful read check, Step 0-MCP optionally tests write access via create+delete canary item. Warns early if write permissions are missing. Non-blocking — downgrades to read-only. Step 4e guard clause updated.
**Files:** `commands/scaffold.md`, `core/mcp-detection.md`

### --issue + YOLO + no-MCP UX Consolidation
**Source:** v5.5.0 verification (Devil's Advocate — P1)
When --issue is provided in Full YOLO mode without MCP, blocks with explicit error instead of silently downgrading. Also applies to --yolo + --description in implement-feature.
**Files:** `commands/scaffold.md`, `commands/implement-feature.md`

---

## DONE — v5.6.1 (UX Polish)

### --infra flag format
**Source:** v5.6.0 UX review
Positional `--infra ready,later` forces user to remember order (tracker, SC). Changed to self-documenting format: `--infra tracker:ready,sc:later`. Order-independent. Shorthands: `--infra ready` (both ready), `--infra later` (both later). Old format rejected with migration error.
**Files:** `commands/scaffold.md`, `commands/resume-ticket.md`, `core/mcp-detection.md`

### Canary-write should ask or announce
**Source:** v5.6.0 UX review
Step 0-MCP canary-write creates an issue in the user's tracker without warning. Step 0-MCP now displays "Checking write access — creating a temporary test item in {project}" before canary-write check runs.
**Files:** `commands/scaffold.md`, `core/mcp-detection.md`

### Error messages should use user language, not MCP jargon
**Source:** v5.6.0 UX review
Block messages said "MCP server for {type} is not available" — users think "GitHub" or "Jira", not "MCP server". Replaced with "Cannot connect to your {type} issue tracker" across 16 files. Technical jargon removed from all user-facing error strings.
**Files:** `commands/scaffold.md`, `commands/init.md`, `commands/fix-ticket.md`, `commands/fix-bugs.md`, `commands/implement-feature.md`, `commands/check-deploy.md`, `commands/resume-ticket.md`, `core/mcp-detection.md`, `core/mcp-preflight.md`, `agents/triage-analyst.md`, `agents/spec-analyst.md`, `agents/deployment-verifier.md`, `agents/browser-verifier.md`, `agents/reproducer.md`, `CLAUDE.md`, `skills/workflow-router/SKILL.md`

### Resume should allow infrastructure override
**Source:** v5.6.0 UX review
If user crashes mid-scaffold, sets up tracker, and resumes — pipeline ignores the new setup because state.json has `"later"`. Resume now detects `--infra` flag on re-invocation and prefers it over stale state. Supports upgrade (later→ready) with re-verification and downgrade (ready→later) with field cleanup.
**Files:** `commands/resume-ticket.md`, `commands/scaffold.md`, `core/state-manager.md`

---

## DONE — v5.7.0 (E2E Pipeline Validation)

### E2E Pipeline Validation
12 new test scenarios covering cross-reference integrity, pipeline contracts, and config contracts. 6 bugs fixed during research. Test suite grows from 25 to 37 scenarios.

**Cross-reference integrity (4):** Dynamic agent/core/command count validation against CLAUDE.md claims.
**Pipeline contracts (6):** Feature pipeline step ordering, deployment verifier completeness, agent dispatch models, feature agent chain, state write coverage, hook execution order.
**Config contracts (2):** Required key consumption, optional section parity between CLAUDE.md and config-reader.md.

**Files:** `tests/scenarios/` (12 new), `tests/harness/run-tests.sh`, `agents/deployment-verifier.md`, `commands/implement-feature.md`, `core/config-reader.md`, `CLAUDE.md`

---

## DONE — v6.2.0 (E2E Deployment Guard)

### E2E Test Engineer: Deployment Guard
**Source:** User feedback (2026-04-04) — e2e-test-engineer has "NEVER run without a live application" rule but no automatic check

Two-level guard preventing E2E tests from running against a dead application:
1. **Agent-level** — pre-flight check inside `e2e-test-engineer.md` step 3 (safety net)
2. **Pipeline-level** — deployment-verifier dispatch before e2e-test-engineer in 4 skill files (proactive start)

**Files:** `agents/e2e-test-engineer.md`, `skills/fix-ticket/SKILL.md`, `skills/fix-bugs/SKILL.md`, `skills/implement-feature/SKILL.md`, `skills/scaffold/SKILL.md`

---

## DONE — v6.3.0 (Scaffold Quality: E2E + Docs)

### Scaffold: E2E Test Generation (Batch 7)
**Source:** User feedback (2026-04-04)

Scaffolder agent generates a basic Playwright e2e test suite when the tech stack includes a web framework and Playwright is in dependencies. Conditional — skipped for non-web projects or projects without Playwright. Follows Batch 6 conditional pattern.

Generated files: `playwright.config.ts`, `e2e/smoke.spec.ts`, `test:e2e` script in `package.json`. Scorecard: "E2E Test Setup" item (conditional). File count ceiling raised to 27.

**Files:** `agents/scaffolder.md`

### Scaffold: Application Documentation for Agents (Batch 8)
**Source:** User feedback (2026-04-04)

Scaffolder agent generates `docs/ARCHITECTURE.md` summarizing stack choices, directory structure, key patterns, and configuration approach. NOT conditional — every project gets documentation. Module Docs config section auto-populated with `Path: docs/`.

Scorecard: "App documentation" item (always checked). Downstream agents (code-analyst, architect) automatically consume via Module Docs config.

**Files:** `agents/scaffolder.md`, `skills/scaffold/SKILL.md`

---

## DONE — v6.1.9 (Decomposition Persistence Parity)

### Decomposition Persistence Parity
**Source:** forge pipeline analysis (2026-04-03), implement-feature bugfix (v6.1.8)

Ported 4 persistence fixes from `implement-feature/SKILL.md` to `fix-ticket/SKILL.md` and `fix-bugs/SKILL.md`:
1. SINGLE_PASS state.json write for `--no-decompose` (DISABLED) path
2. AUTO→SINGLE_PASS fallthrough state.json write
3. `mkdir -p .claude/decomposition/` before YAML write + runtime field initialization
4. Explicit per-subtask `status`, `commit_hash`, `restore_point` in both YAML and state.json

Also documented all 11 subtask object fields in `state/schema.md`.

**Files:** `skills/fix-ticket/SKILL.md`, `skills/fix-bugs/SKILL.md`, `state/schema.md`

---

## DONE — v6.0.0 (Commands-to-Skills Migration)

### Commands-to-Skills Migration
**Source:** Architecture review (2026-03-31), Anthropic best-practice guidance

Migrated all 25 commands from `commands/*.md` to `skills/*/SKILL.md`. MAJOR version — internal architecture change from legacy commands to recommended skills system.

**Key changes:**
- 25 command files → 25 skill directories with SKILL.md
- Added `disable-model-invocation: true` for 14 pipeline/destructive skills
- Updated 22 test files, 3 core files, CLAUDE.md, 1 docs file
- Removed `commands/` directory
- workflow-router unchanged (already a skill)

**Files:** All `skills/*/SKILL.md` (25 new), `CLAUDE.md`, `tests/scenarios/*.sh` (22 updated + 2 new), `core/fixer-reviewer-loop.md`, `core/decomposition-heuristics.md`, `core/mcp-detection.md`, `docs/guides/mcp-configuration.md`

---

## DONE — v6.3.1 (UNCLEAR Handler + Scaffold Patch Fixes)

### fix: analyze-bug missing UNCLEAR handler
**Source:** Bug report (2026-04-05) — analyze-bug skill asked clarifying questions in chat instead of posting a block comment to YouTrack

Added UNCLEAR handler (step 3a) to `skills/analyze-bug/SKILL.md` — posts block comment to tracker when triage returns UNCLEAR. Made UNCLEAR path explicit in `skills/fix-bugs/SKILL.md` — posts block comment matching fix-ticket pattern.

**Files:** `skills/analyze-bug/SKILL.md`, `skills/fix-bugs/SKILL.md`

### fix: Scaffold Batch 7 cross-stack Playwright detection
**Source:** v6.3.0 Devil's Advocate review (2026-04-05)

Expanded Batch 7 Playwright detection to check `package.json` (`@playwright/test`), `pyproject.toml`/`requirements.txt` (`pytest-playwright`), and `Gemfile` (`capybara-playwright-driver`). Generates language-appropriate test files: `.spec.ts` for JS/TS, `test_smoke.py` for Python, `smoke_spec.rb` for Ruby.

**Files:** `agents/scaffolder.md`

### fix: Scaffold test grep semantic fragility
**Source:** v6.3.0 Devil's Advocate review (2026-04-05)

Replaced fragile grep patterns in `scaffolder-e2e-batch.sh` with context-aware assertions. Batch 7 conditional check uses `grep -A5 "Batch 7" | grep`. File count ceiling matches `up to 27`. Added cross-stack Playwright test assertions.

**Files:** `tests/scenarios/scaffolder-e2e-batch.sh`

---

## DONE — v6.3.2 (Verification Follow-ups)

### fix: UNCLEAR signal contract formalization
**Source:** v6.3.1 Devil's Advocate review (2026-04-05) — triage-analyst outputs "Quality gate: incomplete" but consuming skills branch on "UNCLEAR"

Formalized `Quality gate: UNCLEAR` as the machine-readable signal token in `agents/triage-analyst.md`. Aligned all three consuming skills (analyze-bug, fix-bugs, fix-ticket) to use identical Block Comment Template format on UNCLEAR. Token is explicitly documented as the contract consumed by downstream skills.

**Files:** `agents/triage-analyst.md`, `skills/analyze-bug/SKILL.md`, `skills/fix-bugs/SKILL.md`, `skills/fix-ticket/SKILL.md`

### fix: Batch 7 missing Playwright bindings (Java, .NET, Go)
**Source:** v6.3.1 Devil's Advocate review (2026-04-05) — cross-stack Playwright detection covers JS/Python/Ruby but misses Java, .NET, Go

Added detection for `com.microsoft.playwright` in pom.xml/build.gradle, `Microsoft.Playwright` in *.csproj, and `playwright-go` in go.mod. Generates language-appropriate e2e test files (`SmokeTest.java`, `SmokeTest.cs`, `smoke_test.go`).

**Files:** `agents/scaffolder.md`, `tests/scenarios/scaffolder-e2e-batch.sh`

### fix: Test grep -A5 reformatting tolerance
**Source:** v6.3.1 Devil's Advocate review (2026-04-05) — `grep -A5` has only 3-line margin before failure

Replaced `grep -A5 "Batch 7"` with `sed -n '/Batch 7/,/Batch 8/p'` range extraction. Made smoke test assertion Batch-7-scoped. Added Java/Go/.NET Playwright test assertions.

**Files:** `tests/scenarios/scaffolder-e2e-batch.sh`

---

## DONE — v6.3.3 (Pipeline Output Verification)

### fix: Scaffold Step 3 validation depth
**Source:** User feedback (2026-04-04) — scaffold reports success but generated project may have build errors

Expanded Step 3 from one-line scaffolder self-report delegation to explicit skill-level verification: reads Build command and Test command from generated CLAUDE.md Automation Config, runs them independently, loops back to scaffolder on failure (max 3 retries). Both v2 (Step 3) and legacy (L3) flows updated.

**Files:** `skills/scaffold/SKILL.md`

### fix: Scaffolder scorecard hard requirements
**Source:** User feedback (2026-04-04) — scaffolder scorecard "Builds" and "Tests" are advisory only

Promoted "Build" and "Tests" from informational scorecard items to hard requirements. Scaffolder must fix failures before outputting the report. Constraints section reinforced with explicit blocking language.

**Files:** `agents/scaffolder.md`

### fix: Post-review smoke check (fix-ticket + fix-bugs)
**Source:** User feedback (2026-04-04) — no build/test verification between reviewer approval and test-engineer

Added step 7a (fix-ticket) and step 6a (fix-bugs) — post-review smoke check runs Build command + Test command from Automation Config between fixer-reviewer loop and test-engineer. Catches regressions from reviewer iterations.

**Files:** `skills/fix-ticket/SKILL.md`, `skills/fix-bugs/SKILL.md`

---

## DONE — v6.4.0 (Decomposition Subtask Tracker Creation)

- **What:** When implement-feature/fix-ticket/fix-bugs decompose a task into subtasks (via architect), create sub-issues in the tracker under the parent issue.
- **Steps:** 5a (implement-feature), 4b-tracker (fix-ticket), 3b-tracker (fix-bugs)
- **Trackers:** All 6 types supported (YouTrack, Jira, Linear, Redmine native parent-link; GitHub/Gitea standalone + checklist)
- **Config:** `Create tracker subtasks` key in Decomposition section (default: `enabled`)
- **State:** `tracker_issue_id` field added to Subtask Object Fields
- **Idempotence:** Dual-store (YAML-primary, state.json fallback)
- **Files modified:** 12 files + 9 test files

---

## DONE — v6.4.2 (Oracle PL/SQL Template)

New Automation Config template for Oracle PL/SQL + Redmine projects. Driven by SK kompenzace onboarding gap analysis.

- **New template:** `examples/configs/redmine-oracle-plsql.md` — Redmine tracker, Flyway migrations, utPLSQL tests, Oracle Docker deployment, oracle-backend pipeline profile, conservative retry limits, Agent Override path
- **Template catalog:** Added `redmine-oracle-plsql` to `skills/template/SKILL.md`
- **No agent/skill/core changes** — pure template addition

**Source:** `docs/plans/readmine-project/ceos-agents-gap-analysis.md` (section 7)
**Files:** `examples/configs/redmine-oracle-plsql.md` (new), `skills/template/SKILL.md`

---

## DONE — v6.5.0 (Sprint Planning & Backlog Management)

**Status:** IMPLEMENTED
**Source:** Feature specification (`docs/plans/sprint-planning-feature-spec.md`)

New capability: convert specifications to tracker epics and plan capacity-constrained sprints.

**Components:**
- 2 new agents: `backlog-creator` (sonnet), `sprint-planner` (sonnet)
- 2 new skills: `/create-backlog`, `/sprint-plan`
- 1 new flag: `--decompose-only` on `/implement-feature`
- Config: `### Sprint Planning` optional section (8 keys)
- State: `sprint-{timestamp}` and `backlog-{timestamp}` RUN-ID formats

**Files:** `agents/backlog-creator.md`, `agents/sprint-planner.md`, `skills/create-backlog/SKILL.md`, `skills/sprint-plan/SKILL.md`, `skills/implement-feature/SKILL.md`, `core/config-reader.md`, `state/schema.md`, `CLAUDE.md`, `skills/workflow-router/SKILL.md`, `skills/scaffold/SKILL.md`, `docs/reference/skills.md`

---

## DONE — v6.4.4 (Connectivity Diagnostics Hardening)

Theme: Systemic follow-up from v6.4.3 check-setup TLS diagnostics. Extend the path resolution and error classification patterns to all affected files.
**Source:** forge-2026-04-11-001 out-of-scope findings

### Bare Path Migration (trackers.md)
Migrate all bare `docs/reference/trackers.md` references across the plugin to use Glob-first resolution (the pattern introduced in check-setup v6.4.3). Affects 13+ files: `skills/onboard/SKILL.md` (6 refs), `skills/scaffold/SKILL.md` (4 refs), `skills/init/SKILL.md` (1 ref), `core/mcp-detection.md` (1 ref), and others.
**Pattern:** Three-layer Glob (`.claude/plugins/**/`, `**/`, CWD fallback) with `[WARN]` on missing file.
**Files:** ~7 skill/core files. **Impact:** PATCH (behavioral fix, no config contract change).

### Structured Error Classification in core/mcp-detection.md
Extend `core/mcp-detection.md` with a structured `error_type` output field (enum: `tls`, `auth`, `not_found`, `timeout`, `unknown`). Currently, raw error strings are passed through and each caller (check-setup, init, fix-bugs, fix-ticket) independently parses them. With structured error_type, callers become 3-line delegation calls instead of inline pattern matchers.
**Files:** `core/mcp-detection.md`, `skills/check-setup/SKILL.md`, `skills/init/SKILL.md`. **Impact:** PATCH (internal contract, no config change).

### Step 10 TLS Treatment
Apply the same TLS diagnostic pattern (curl probe + NODE_OPTIONS hint) to the SC connectivity check (Step 10) in check-setup. Currently only Step 9 (Issue tracker) has TLS diagnostics; Step 10 still falls back to generic "unreachable" on TLS failure.
**Files:** `skills/check-setup/SKILL.md`. **Impact:** PATCH.

---

## DONE — v6.5.2 (Redmine + Publisher Fixes)

Theme: Two confirmed pipeline bugs from real-world Redmine usage.
**Source:** drmax-readmine-test project (2026-04-13). Implemented via forge pipeline (forge-2026-04-15-001).

### Redmine Status Transitions — Numeric ID Parsing
Changed Redmine canonical format from `status:{name}` (LLM convention, unreliable) to `status_id:{id}` (numeric, deterministic). Legacy `status:{name}` remains accepted with WARN.

**Changes:**
- `docs/reference/trackers.md`: Updated 4 locations (State Transition Syntax, Redmine note, On Start Set Defaults, Validation Rules) to use `status_id:{id}` as canonical format
- New `core/status-verification.md`: Advisory post-set verification contract — read-back after status-set, WARN on mismatch, NEVER block. Wired into publisher Step 7, block-handler Step 2, fix-ticket Step 1
- `skills/onboard/SKILL.md`: Redmine-specific sub-step 6a for interactive numeric status ID collection (curl guidance, no MCP needed)
- `skills/migrate-config/SKILL.md`: New deprecated-pattern rule for `status:{name}` → `status_id:{id}` conversion (interactive, skippable)
- `skills/check-setup/SKILL.md`: WARN emission for legacy Redmine format
- Both Redmine templates (`redmine-oracle-plsql.md`, `redmine-rails.md`) updated to `status_id:{id}` format

### Publisher Literal `\n` in PR Body
Added NEVER constraint for literal `\n` escape sequences in all 5 MCP body call sites: publisher (PR description + block comment), block-handler (block comment), fix-ticket (subtask description), implement-feature (subtask description), fix-bugs (block comment + subtask description). New regression test `mcp-newline-handling.sh`.

**Files:** 15 total (13 edits + 2 new: `core/status-verification.md`, `tests/scenarios/mcp-newline-handling.sh`). **Impact:** PATCH.

### Not planned
- config-reader Redmine normalization (architectural change, not needed — trackers.md format fix is sufficient)
- Onboard wizard MCP access (allowed-tools expansion, design decision beyond PATCH scope)

---

## DONE — v6.6.0 (v6.5.2 Follow-ups)

Theme: Complete the patterns started in v6.5.2 — extend status verification to all call sites, centralize MCP body formatting, add missing fix-bugs pipeline step.
**Source:** v6.5.2 deferred items (forge-2026-04-15-001).

### Status Verification — Remaining Call Sites
Wire `core/status-verification.md` into the 4 remaining call sites not covered in v6.5.2: `skills/implement-feature/SKILL.md` Step 1, `core/fix-verification.md` Step 6, `skills/fix-bugs/SKILL.md` block handler, `skills/scaffold/SKILL.md` Step 8b. v6.5.2 covered the 3 highest-value sites (publisher, block-handler, fix-ticket).
**Files:** 4 skill/core files. **Impact:** PATCH.

### MCP Body Formatting Contract
Create `core/mcp-body-formatting.md` centralized contract for multi-line MCP tool parameters. Replace per-site NEVER instructions (added in v6.5.2) with single contract references. Prevents the entire class of `\n` literal bugs from recurring.
**Files:** new `core/mcp-body-formatting.md`, 5 files with reference updates. **Impact:** PATCH.

### fix-bugs "On start set" Step
Add "Set issue state to In Progress" step at the beginning of the per-issue loop in `skills/fix-bugs/SKILL.md`. Currently fix-bugs is the only pipeline skill that doesn't set issue state on start — it delegates to publisher for "For Review" but never sets "In Progress". Pre-existing functional gap, not a regression.
**Files:** `skills/fix-bugs/SKILL.md`. **Impact:** MINOR (new step in existing pipeline — drives version number).

---

## DONE — v6.7.0 (Pipeline Hardening)

Theme: Robustness and security of the existing pipeline.
**Source:** External review report analysis (2026-04-08) — 2 of 12 recommendations accepted.

### Prompt Injection Protection (D2)
Wrap all external tracker content (issue title, description, comments) in `--- EXTERNAL INPUT START ---` / `--- EXTERNAL INPUT END ---` markers before passing to agents. Added NEVER constraint to 5 agents (triage-analyst, code-analyst, fixer, reviewer, spec-analyst). Added sanitizer reference to 6 skills (fix-ticket, fix-bugs, implement-feature, resume-ticket, scaffold, analyze-bug). New `core/external-input-sanitizer.md` contract.
**Files:** 13 (1 new core contract, 6 skills, 5 agents, CLAUDE.md). **Impact:** PATCH (behavioral fix).

### Plugin Version Tracking (D12)
Added `plugin_version` field to state.json (read from `.claude-plugin/plugin.json` at pipeline start via state-manager initialization). resume-ticket compares stored plugin_version with current version and warns on major version mismatch. Silent skip when field is absent (pre-v6.7.0 state).
**Files:** 4 (state/schema.md, core/state-manager.md, skills/resume-ticket/SKILL.md, CLAUDE.md). **Impact:** PATCH (internal field).

---

## DONE — v6.7.1 (Contract & Schema Fixes + Hardening Follow-ups)

Theme: Quick fixes to core contracts and state schema gaps, plus security/robustness follow-ups from v6.7.0 verification.
**Source:** forge-2026-04-13-003 audit (Batch 3) + forge-2026-04-15-003 verification (P2-P3 findings).

### config-reader Missing Key
Add `decomposition.create_tracker_subtasks` (default: `enabled`) to `core/config-reader.md` Decomposition section parsing. Currently used by 3 pipeline skills but not documented in the config-reader contract.
**Files:** `core/config-reader.md`. **Impact:** PATCH.

### Config Validity Gate in fix-bugs
Add Config Validity Gate (Step 0b) to fix-bugs for parity with fix-ticket and implement-feature. Currently fix-bugs is the only pipeline skill missing this gate — incomplete configs slip through.
**Files:** `skills/fix-bugs/SKILL.md`. **Impact:** PATCH.

### State Schema Retry Limit Fields
Add `config.retry_limits.spec_iterations` and `config.retry_limits.root_cause_iterations` to `state/schema.md`. Currently these limits exist in the Automation Config contract but not in the state schema — resume-ticket cannot restore them from state.
**Files:** `state/schema.md`. **Impact:** PATCH.

### Code-analyst Before Architect in implement-feature
Add conditional code-analyst dispatch before architect in implement-feature for modification-heavy features. Simple heuristic: if existing files match the spec-analyst scope, run code-analyst first to provide codebase impact context. Currently architect works from spec only, with no codebase pre-screen.
**Files:** `skills/implement-feature/SKILL.md`. **Impact:** PATCH (behavioral enhancement).

### Marker Nesting Attack Mitigation
External input markers (`--- EXTERNAL INPUT START ---` / `--- EXTERNAL INPUT END ---`) can be defeated if attacker-controlled tracker content contains the same marker strings, causing premature boundary termination. Add content escaping to `core/external-input-sanitizer.md`: escape any occurrence of marker strings within the wrapped content before wrapping.
**Files:** `core/external-input-sanitizer.md`, potentially agent constraints. **Impact:** PATCH (security hardening).

### State-Manager Graceful Degradation Documentation
`core/state-manager.md` reads `plugin_version` from `.claude-plugin/plugin.json` but does not explicitly document behavior when the file is unreadable (missing, malformed JSON, no `version` field). Add explicit graceful degradation clause: default to `null` with no error on any read failure.
**Files:** `core/state-manager.md`. **Impact:** PATCH (documentation).

### Extended NEVER Constraint Coverage
NEVER constraint for external input markers currently covers 5 agents (triage-analyst, code-analyst, fixer, reviewer, spec-analyst). Extend to 5 additional agents that may process external tracker content: acceptance-gate, architect, reproducer, priority-engine, browser-verifier. These agents receive issue data indirectly through pipeline context.
**Files:** `agents/acceptance-gate.md`, `agents/architect.md`, `agents/reproducer.md`, `agents/priority-engine.md`, `agents/browser-verifier.md`. **Impact:** PATCH (defense-in-depth).

---

## DONE — v6.7.2 (Pipeline Consistency & Dedup)

Theme: Reduce duplication and align cross-skill consistency. Found during 3-pipeline audit (2026-04-13).
**Source:** forge-2026-04-13-003 audit, Batch 3-4 items. Implemented via forge pipeline (forge-2026-04-16-004).

### Tracker Subtask Extraction to Core Contract
Extracted Create Tracker Subtasks logic (~460 lines duplicated across 3 skills) into `core/tracker-subtask-creator.md` (15th core contract). Standard contract structure: Purpose, Input Contract (9 fields), Process (triple gate + pseudocode), Per-Tracker table, Issue Description Template, Output Contract, Failure Handling. Three skills reduced to 5-line delegation stubs.
**Files:** new `core/tracker-subtask-creator.md`, `skills/fix-ticket/SKILL.md`, `skills/fix-bugs/SKILL.md`, `skills/implement-feature/SKILL.md`, `CLAUDE.md` (14→15). **Impact:** PATCH (internal refactor).

### Webhook Format Alignment
Aligned implement-feature webhook keys to canonical format (`issue_id`, `pr_url`, `timestamp`, `--max-time 5 --retry 0`). Removed duplicate inline webhooks: implement-feature step 10a delegates to `core/post-publish-hook.md`, fix-bugs step 8b converted to pointer.
**Files:** `skills/implement-feature/SKILL.md`, `skills/fix-bugs/SKILL.md`. **Impact:** PATCH.

### Block Handler Inline Removal
Removed 25-line inline block procedure from implement-feature Step X. Replaced with 4-line fix-ticket-style delegation to `core/block-handler.md`. Auto-fixed 4 latent bugs (unconditional rollback, missing status-verification, deviant webhook keys, missing failure handling). fix-bugs Step X also cleaned to delegation + skill-specific addenda.
**Files:** `skills/implement-feature/SKILL.md`, `skills/fix-bugs/SKILL.md`. **Impact:** PATCH.

### LOW Documentation Fixes (6 edits)
- `core/fix-verification.md`: Mode-neutral language ("Verified" / "Verification failed" / "confirm the changes work")
- `core/state-manager.md`: Replaced forward reference to resume-ticket.md with inline 6-checkpoint heuristic table
- `state/schema.md`: Added `verdict`, `result_path`, `attempts` fields to e2e_test section
- `state/schema.md`: Added mode-reuse documentation for triage.*/code_analysis.* fields
- `core/fixer-reviewer-loop.md`: NEEDS_DECOMPOSITION now lists all 3 callers (fix-ticket, fix-bugs, implement-feature)

**Files:** 5 files. **Impact:** PATCH.

### Not implemented (deferred)
- fix-bugs YOLO latent bug (references `--yolo` mode but has no `--yolo` flag) — moved to BACKLOG

---

## IMPLEMENTED — v6.8.0 (Autopilot + Observability) — 2026-04-18

Shipped via forge pipeline `forge-2026-04-17-001` (10 phases, 1 Phase 8 revision cycle, aggregate 0.857 FULL_PASS). All three items delivered. Follow-ups moved to PLANNED v6.8.1 and v6.9.0.

### Delivered

1. **Autopilot skill** (`/ceos-agents:autopilot`) — 29th skill, headless dispatcher with mkdir-based portable lock (120min stale detection), 7 roadmap-canonical config keys, `[WARN]` + bug-only mode on absent `Feature Workflow`, full short-circuit dry-run, Security Considerations documented.
2. **Observability Hooks D10** — `pipeline-started`, `step-completed`, `pipeline-completed` events in `core/post-publish-hook.md` Section 4; `run_id` as `{issue_id}_{YYYYMMDDTHHMMSSZ}`; curl hardened with `--proto "=http,https"`.
3. **Real-Time Cost Visibility** — per-stage `tokens_used`/`duration_ms`/`tool_uses`/`model`/`started_at`/`completed_at` + `pipeline.*` accumulator + `summary_table` (≤20 rows/4000 chars); `schema_version` stays `"1.0"`; `/metrics` dual-mode measured-vs-estimated with provenance footer.

### Completion artifacts

Full report: `.forge/phase-9-completion/report.md`. Commander verdict: `.forge/phase-8-verification/commander-verdict.md`.

### Original design direction (for historical reference)

### Autopilot Skill
**Source:** forge brainstorm (2026-04-05, approved)

New skill `/ceos-agents:autopilot` — thin dispatcher that reads Bug query + Feature query, classifies issues, dispatches `fix-ticket` or `implement-feature` per issue, logs results. Lock file for concurrency, 7-key optional config section (`### Autopilot`), append-only log.

**Design direction:**
- Thin dispatcher, no new agents, no sub-skills
- Dispatch via Skill tool: `fix-ticket` for bugs, `implement-feature` for features, sequential
- Lock file at `.ceos-agents/autopilot.lock` (timestamp + hostname, stale at 120min)
- Config: Max issues per run (1), Lock timeout (120), Log file, Bug limit (0), Feature limit (0), On error (skip), Dry run (false)
- Two-query classification: Bug query first, then Feature query, bug takes priority on overlap
- Error boundaries: MCP/lock failure = stop, per-issue errors = skip (configurable)
- CLI invocation: `claude -p "Run /ceos-agents:autopilot" --dangerously-skip-permissions`

**Open questions (deployment, not PoC):**
- Auth persistence: does `claude login` session token survive long-term on headless server?
- Credential transfer: copy `~/.claude/.credentials.json` from dev machine to server — does it work cross-machine?

**Impact:** MINOR (new optional config section + new skill).

### Observability Hooks (D10)
**Source:** External review report analysis (2026-04-08), recommendation D10

Expand webhook system beyond current 2 events (block, PR) to include `pipeline-started`, `step-completed`, `pipeline-completed` with richer payload (step_name, duration, iteration_count). Autopilot is the primary consumer of real-time pipeline events. Dashboard/metrics skills remain post-hoc; external monitoring gets real-time data via webhooks.

**Files:** core/post-publish-hook.md, core/block-handler.md, CLAUDE.md (Notifications config), pipeline skills.
**Impact:** MINOR (new optional events in Notifications config).

### Real-Time Cost Visibility
**Source:** BMAD comparison — blind spot for both tools. Mechanism copied from filip-superpowers/forge (forge.json per-phase `tokens_estimated` + `duration_ms` + `tool_uses`, metrics accumulator).

Per-agent usage tracking — same pattern as forge. Agent/Task tool returns 3 usage fields on every dispatch: `total_tokens`, `duration_ms`, `tool_uses`. Skills capture all three and write to state.json per-stage. `/metrics` aggregates.

**Forge reference (what we copy):**
```json
// forge.json per-phase pattern:
"phases": {
  "0": {"tokens_estimated": 91023, "duration_ms": 370000, "tool_uses": 28, ...}
}
// forge.json metrics accumulator:
"metrics": {"total_tokens_estimated": 729023, "total_duration_ms": 2526000}
```

**Mechanism (mirroring forge 1:1):**
1. Each pipeline skill captures `total_tokens`, `duration_ms`, `tool_uses` from Task tool result after every agent dispatch
2. Write per-stage usage object to state.json:
   ```json
   "triage": {"tokens_used": 12500, "duration_ms": 45000, "tool_uses": 8, "model": "sonnet"},
   "code_analysis": {"tokens_used": 18200, "duration_ms": 62000, "tool_uses": 12, "model": "sonnet"},
   "fix": {"tokens_used": 45000, "duration_ms": 120000, "tool_uses": 34, "model": "opus"},
   "review": {"tokens_used": 22000, "duration_ms": 55000, "tool_uses": 15, "model": "opus"}
   ```
3. For fixer↔reviewer loop: accumulate across iterations (`fix.iterations: 3, fix.tokens_used: 135000`)
4. Write cumulative `pipeline.total_tokens`, `pipeline.total_duration_ms`, `pipeline.total_tool_uses` at pipeline end
5. Pipeline summary report includes usage table:
   ```
   | Stage         | Model  | Tokens  | Duration | Tools |
   |---------------|--------|---------|----------|-------|
   | triage        | sonnet | 12,500  | 45s      | 8     |
   | code-analyst  | sonnet | 18,200  | 62s      | 12    |
   | fixer (×3)    | opus   | 135,000 | 360s     | 102   |
   | reviewer (×3) | opus   | 66,000  | 165s     | 45    |
   | test-engineer | sonnet | 15,800  | 48s      | 11    |
   | publisher     | haiku  | 3,200   | 12s      | 5     |
   | **Total**     |        | 250,700 | 692s     | 183   |
   ```
6. `/metrics` reads per-stage usage from state.json across completed issues, reports averages and outliers

**forge.json vs state.json — structural mapping:**

| | forge.json | state.json |
|---|---|---|
| **Stage keys** | Numbered phases: `"0"`, `"1"`, ... | Named stages: `"triage"`, `"code_analysis"`, `"fixer_reviewer"`, `"test"`, ... |
| **Usage fields (current)** | `tokens_estimated`, `duration_ms` per phase | NONE — only `status` per stage |
| **Accumulator** | `metrics.total_tokens_estimated`, `metrics.total_duration_ms` | NONE — needs `pipeline.*` section |
| **Timing** | `started_at` + `completed_at` per phase | `started_at` + `updated_at` top-level only, NO per-stage timing |
| **Write mechanism** | Atomic tmp+rename (6-step protocol) | Atomic tmp+rename via `core/state-manager.md` |
| **Iterations** | N/A (single pass per phase) | `fixer_reviewer.iterations`, `test.attempts` already tracked |

**What needs to change in state.json:**
1. Add `tokens_used`, `duration_ms`, `tool_uses`, `model` fields to EACH existing stage section (triage, code_analysis, fixer_reviewer, test, e2e_test, browser_verification, publisher)
2. For `fixer_reviewer`: usage is cumulative across iterations (already has `iterations` counter)
3. Add new top-level `pipeline` section: `{"total_tokens": N, "total_duration_ms": N, "total_tool_uses": N}`
4. Add per-stage `started_at`, `completed_at` (currently only top-level — need per-stage timing for the summary table)
5. `core/state-manager.md` Write Process unchanged — same atomic protocol, just new field paths

**Verification before implementation:** Read `state/schema.md` Full Schema Example — confirm field names are consistent with existing sections. Read forge.json from a recent forge run — confirm Agent tool usage metadata format (`total_tokens`, `duration_ms`, `tool_uses`).

**Files:** 4 pipeline skills (capture + summary), `state/schema.md` (per-stage usage fields + pipeline section), `core/state-manager.md` (usage write pattern), `skills/metrics/SKILL.md` (aggregation), `skills/dashboard/SKILL.md` (optional visualization).
**Impact:** PATCH (informational output, no contract change).

---

## IMPLEMENTED — v6.8.1 (Post-v6.8.0 follow-ups) — 2026-04-19

All 6 items shipped via forge pipeline `forge-2026-04-18-001` (9 phases, 0 revision cycles, aggregate 0.907 FULL_PASS, ~2.48M tokens). Tag: `v6.8.1`.

- `examples/configs/*` — `### Autopilot` block added to all 8 templates (path corrected: `examples/configs/`, not `examples/config-templates/`)
- `issue_id` regex gate `^[A-Za-z0-9#_-]+$` via bash `[[ =~ ]]` in 4 skills (fix-ticket, fix-bugs, implement-feature, resume-ticket) — path-traversal + newline-injection defense
- JSON-encode payload field interpolation — `core/post-publish-hook.md` Field value safety note; `core/block-handler.md` Step 5 rewritten to heredoc + `jq -n --arg` + `curl --proto "=http,https"`; `docs/guides/autopilot.md` Payload field safety paragraph
- Lock-timeout text alignment — `skills/autopilot/SKILL.md:368` now explicitly names 120 min contract / 125 min primary path / 121 min BusyBox fallback as the effective stale threshold
- Fixer-reviewer crash-recovery regression test — `core/fixer-reviewer-loop.md` Step 10 documents cumulative `tokens_used`/`duration_ms`/`tool_uses` across iterations + crash-recovery preservation; new scenario `tests/scenarios/v681-fixer-reviewer-crash-recovery.sh`
- Test harness exit-code propagation — `tests/harness/run-tests.sh` counters switched from `((N++))` to `N=$((N+1))` (bash `-e` compatible); new meta-test `tests/scenarios/v681-harness-exit-propagation.sh`
- Harness: 141/141 passing (140 baseline − 1 retired v6.8.0-pinned test + 2 new v681- scenarios).

---

## SHIPPED — v6.9.0 (Pipeline Intelligence + OSS Readiness) — 2026-04-20

Theme: Pipeline learns and communicates better **+ plugin becomes open-source ready**.

Combines original v6.9.0 scope with v6.8.1 polish follow-ups (originally planned as v6.8.2) and open-source go-live prerequisites. Single release = cleaner public launch.

Shipped via forge pipeline `forge-2026-04-19-001` (10 phases, 3 revision cycles in Phase 4, 90 EARS REQs, 118 ACs, 49 test scenarios, ~5M tokens estimated). Tag: `v6.9.0`.

### OSS Readiness (shipped)

- **LICENSE** — MIT License committed to repo root (`Copyright (c) 2024-2026 Filip Sabacky`). `plugin.json.license` + `marketplace.json` updated to `"MIT"`.
- **SECURITY.md** — vulnerability reporting policy; primary contact `filip.sabacky@ceosdata.com`; secondary contact deferred to v6.9.1.
- **Repository URL** — `plugin.json.repository` updated to RFC 2606 unsquattable placeholder `https://example.invalid/ceos-agents.git`; canonical public URL deferred to v6.9.1.
- **CODE_OF_CONDUCT.md** — Contributor Covenant 2.1 by reference + light enforcement note.
- **Issue / PR templates** — `.gitea/issue_template/` + `.github/ISSUE_TEMPLATE/` (byte-identical pairs); PR templates. PII warning + no-secrets checkbox.

### Pipeline Intelligence (shipped)

- **NEEDS_CLARIFICATION pause state** — fixer + triage-analyst can pause pipeline; `resume-ticket --clarification "<text>"` resumes. DoS caps: max 3/run, max 1/iteration. `core/agent-states.md` (16th core contract).
- **`.ceos-agents/pipeline-history.md` feedback loop** — per-run metadata appended; fixer reads last 5, reviewer reads last 10; 50-run retention; `sanitize_block_reason()` credential redaction (17 patterns).
- **`pipeline-paused` webhook event** — additive event on pause; `--proto "=http,https"` discipline.
- **Webhook circuit breaker** — 3-consecutive-failure threshold; in-memory per-run; advisory only.
- **`outcome: "failed"` Step Z** — fall-through fire path (logical only; process-death not covered).
- **`/ceos-agents:metrics --format json`** — machine-readable output; `block.detail` HARD-EXCLUDED.
- **Architecture freshness check** — soft `[WARN]` when `docs/architecture.md` >25 commits stale; non-blocking.
- **`### Pause Limits` optional config section** — `Pause timeout` key (default 30 days). Total optional sections: 18 → 19.

### v6.8.1-sourced polish (shipped)

- `--proto "=http,https"` added at all 18 webhook curl sites in 3 pipeline skills.
- `trap 'rm -f "$TMPSCEN"' EXIT INT TERM` added to `v681-harness-exit-propagation.sh`.
- `jq -n` → `jq -nc` (compact) in `core/block-handler.md`.
- Jira dotted-project keys accepted: regex → `^[A-Za-z0-9#._-]+$` + dot-only-reject guard.
- Hidden-test `REPO_ROOT` path corrected: `../../` → `../../../`.
- `core/block-handler.md` counter-example wrapped in `<!-- COUNTER-EXAMPLE: ... -->` HTML comment.

### `core/snippets/` sub-namespace (shipped)

5 canonical snippets: `webhook-curl.md`, `issue-id-validation.md`, `metrics-json-schema.md`, `pipeline-completion.md`, `architecture-freshness.md`. Does NOT count toward top-level core contracts total (stays at 16).

### Deferred to v6.9.1

- Canonical repository URL replacement (gate: public mirror provisioned)
- SECURITY.md secondary contact channel
- Cross-run circuit breaker persistence + Webhook URL allowlist
- Multi-host distributed lock for Autopilot

---

## SHIPPED — v6.9.2 (Autopilot Bash Subprocess Dispatch) — 2026-04-23

**PATCH** — resolves the live-pilot BIFITO blocker from 2026-04-22. Implemented as direct execution (no forge pipeline) because the decision record in `project_v692_plan.md` was already complete and empirically validated.

### Fixed
- **Autopilot Step 6 dispatch** (`skills/autopilot/SKILL.md:367-369`) — `Skill(ceos-agents:fix-ticket, ...)` / `Skill(ceos-agents:implement-feature, ...)` replaced with Bash subprocess `claude -p "Run /ceos-agents:{skill} ${ISSUE_ID}" --dangerously-skip-permissions`. Upstream Claude Code bug [#26251](https://github.com/anthropics/claude-code/issues/26251) blocks Skill-tool invocation of targets with `disable-model-invocation: true`; plain-text headless invocation is the only reliable path.
- **Outcome classification** now reads `child_exit` + `.ceos-agents/${ISSUE_ID}/state.json`. New `paused` outcome for NEEDS_CLARIFICATION returns (symmetry with REQ-050b pause-state detection in Step 1a).

### Design decisions retained
- **`disable-model-invocation: true` kept on all 15 pipeline skills** — safety flag preserved; workaround is at the dispatcher layer only.
- **Only autopilot adopts subprocess dispatch.** `workflow-router` stays blocked for `disable-model-invocation: true` targets (project policy: interactive routing stays user-mediated; only autopilot does programmatic dispatch to pipeline skills).
- **Plan rejected: Option A (remove `disable-model-invocation` flag)** — would break safety posture for the upstream bug's duration. Subprocess dispatch is architecturally cleaner (process isolation, crash containment).

### Known Issues (v6.10.0 watchlist)
- Upstream #26251 — if Anthropic ships a selective-invocation whitelist primitive (`allow-invocation-from`, `invocable-by`, or similar), evaluate restoring Skill-tool dispatch to reclaim ~2-5k per-issue overhead.

---

## Post-v6.9.2 focus — community-release blockers

**Decision (2026-04-23):** after v6.9.2 tag+push, feature work is paused until the ceos-agents plugin is ready for public community announcement. Scope restricted to release blockers only.

### v6.10.0 — Quality Sprint + Security Consistency (next forge pipeline)

**Ready to execute now — no external gates.**

1. **Test Discipline Overhaul** — all 41 v6.9.0 visible scenarios are `grep -F` doc-string assertions, not functional behavioral tests. Pattern allowed 8 functional bugs to slip Phase 7 gate in v6.9.0. Scope: audit 41 + add 20-40 functional tests exercising actual bash/jq state-machine logic.
2. **Agent Dispatch Enforcement** (bundled with Test Discipline) — same class of bug as test-discipline issue. Layers 1+2+4 (~12h): imperative SKILL.md prose + PostToolUse hook validator + functional dispatch enforcement test.
3. **Prompt-injection constraint for 11 agents (Phase 2 research confirmed test-engineer, e2e-test-engineer, backlog-creator were not patched in v6.9.0 as previously stated)** — mechanical batch (~2-3h). Canonical source of EXTERNAL INPUT Constraint block: `agents/code-analyst.md:120`. v6.9.0 shipped the EXTERNAL INPUT Constraint only on the 3 HIGH-risk agents identified at the time; Phase 2 forge-2026-04-23-002 research confirmed test-engineer, e2e-test-engineer, and backlog-creator were NOT patched (prior claim was incorrect). All 11 (test-engineer, e2e-test-engineer, backlog-creator, spec-reviewer, spec-writer, rollback-agent, sprint-planner, scaffolder, stack-selector, deployment-verifier, publisher) need the same per Phase 2 §G-3. Without this the plugin has uneven prompt-injection defense — unacceptable for public release where external PRs can inject malicious tracker content.
   - **Prerequisite:** `tests/scenarios/v6.9.0-webhook-proto-coverage.sh` RETIRE (exit 77) BEFORE Layer 1 prose rewrite (avoids false FAIL from grep on rewritten lines).
   - **Prerequisite:** `tests/scenarios/pipeline-agent-dispatch-models.sh` grep pattern update (match old AND new prose defensively) BEFORE Layer 1 prose rewrite.
   - **External research item (Phase 4):** PostToolUse hook API — research artifact at `.forge/phase-4-spec/research/dispatch-hook-api.md`, confidence HIGH per Phase 5 gate. Evaluate for Layer 2 hook validator implementation.

### v6.10.1 — Public-release blockers (waiting on external gate)

**Deferred from v6.10.0 because the public mirror does not yet exist.** Ships once the external gate resolves — can land as a fast patch after v6.10.0.

1. **Canonical repository URL** (HARD BLOCKER for marketplace ingestion) — `plugin.json.repository` is currently `https://example.invalid/ceos-agents.git` (RFC 2606 unsquattable placeholder). Replace with real public mirror URL. Gate: public mirror provisioned + DNS + HTTP 200 + org name confirmed. Must be green-gated before Claude Code marketplace ingestion is attempted.
2. **SECURITY.md secondary contact channel** — blocked on secondary email channel availability (personal or `security@<public-org>` forwarder once mirror exists).
3. **Autopilot dispatch audit parity** (T2-ADV-3 follow-up) — after v6.10.0 Layer 1+2+4 enforcement lands, verify that `skills/autopilot/SKILL.md` subprocess dispatch path aligns with any new dispatch-enforcement prose contracts. Ensures autopilot's out-of-band `claude -p` path is not accidentally excluded from Layer 4 functional test coverage.

### v6.11.0 — Autopilot Hardening + DSL Maturation (post-announcement feature release)

**After public announcement.** Substantial design + schema work, not release-blocking. Lands once real usage data is available to guide design decisions.

1. **Cross-run circuit breaker persistence + Webhook URL allowlist** — covert-channel DoS via malicious `Webhook URL` in a PR is partially mitigated by per-run breaker in v6.9.0; full mitigation requires cross-run state persistence (breaker survives process restart) + operator-configured URL allowlist. Phase 3 Agent C adversarial Scenario 3. New state schema + new config key.
2. **Multi-host distributed lock for Autopilot** — disjoint-query pattern (v6.9.0) is operator-discipline-only; not enforced. Evaluate: (a) flock advisory lock (NFS-fragile); (b) external coordinator (etcd/redis/consul — breaks no-deps invariant); (c) formalized disjoint-query with config validation. Gate: portability test matrix passing across local FS + NFS + SMB + S3FUSE.
3. **JSON-event hook graduation** — current `pipeline-started`, `step-completed`, `pipeline-completed`, `pipeline-paused` webhook events are plain-text-adjacent prose; graduate to structured JSON-event contract with versioned schema, backward-compatibility guarantees, and integration test coverage.
4. **Prompt-injection defense-in-depth** (T3-ADV-1/ADV-2/ADV-3 deferred) — post-v6.10.0 hardening once base EXTERNAL INPUT Constraint is in all 11 agents: (a) T3-ADV-1 nested markers (detect `<!-- EXTERNAL INPUT -->` injected inside tracker content), (b) T3-ADV-2 homoglyph normalization on tracker-sourced strings, (c) T3-ADV-3 producer-side stripping (sanitize tracker content before injecting into agent context).
5. **DSL Maturation** — helpers #4-8 from the full 8-helper DSL vision (v6.10.0 ships only 3 helpers: `assert_file_contains`, `assert_state_field`, `assert_exit`). Remaining 5 helpers: `assert_json_field`, `assert_grep_count`, `assert_not_contains`, `mock_tracker_response`, `assert_webhook_payload`.

**Execution plan:** v6.10.0 scope handled via forge pipeline in a fresh window (not this session). v6.10.1 landed direct-execution style once the external mirror gate goes green. v6.11.0 scoped after public announcement when usage telemetry is available. See `BACKLOG` items for related design notes.

---

## SHIPPED — v6.9.1 (Docs Completion + Polish Patch) — 2026-04-20

PATCH release scoped to close doc gaps that shipped with v6.9.0 and the small polish/correctness items surfaced during Phase 8 cycle-1 + Phase 9. Heavier items (multi-host lock, cross-run breaker, 8-agent prompt-injection batch) deferred to v6.10.0. Full Phase 8 verification required before tag.

### Scope (IN v6.9.1)

#### A. Doc completion (34 gaps per `.forge/v6.9.1-doc-audit.md`)
- **BLOCKING (5)**: `docs/reference/automation-config.md` missing `### Autopilot` + `### Pause Limits` sections entirely; `### Notifications` `On events` enum wrong (`pipeline-complete` → `pipeline-completed`, missing `pipeline-started`/`step-completed`/`pipeline-paused`); `docs/guides/troubleshooting.md` missing NEEDS_CLARIFICATION + circuit-breaker guidance
- **HIGH (14)**: 8 config templates missing `### Pause Limits`; `docs/reference/skills.md` missing `--clarification` flag; `docs/reference/agents.md` missing NEEDS_CLARIFICATION output + EXTERNAL INPUT constraint on fixer/triage-analyst; `docs/reference/config.md` missing `pipeline-paused` event token; `README.md` Skills table missing `autopilot` + `workflow-router`; other HIGH items
- **MEDIUM (10)**: CHANGELOG v6.9.0 entry says "14 credential patterns" (truth: 17); pipeline reference gaps for paused state; stale SSRF deferral note in config.md
- **LOW (5)**: cosmetic

#### B. Small code fixes
- `parse_pause_timeout()` case-insensitive unit tokens (downcase before comparison)
- BSD/macOS `date -d` portability in `skills/autopilot/SKILL.md` (use `python -c "..."` or platform detect)
- `Webhook_URL` vs `WEBHOOK_URL` casing consistency
- `sanitize_block_reason()` bare-lowercase coverage gap (anchor LOWER-VAR with `^|[[:space:]]`)
- AWS_VAR vs LOWER-VAR redaction overlap documented or patterns merged
- `h-snippet-citation-marker-format.sh` scope to `skills/ + core/` only (exclude `.forge/`)

#### C. Additive webhook event
- `pipeline-resumed` webhook (additive, closes pause/resume symmetry — matches per-stage discipline)

#### D. Phase 4 spec amendments
- REQ-042 — enumerate `clarification.asked_at` field
- REQ-045 — explicitly forbid `resume-ticket` from incrementing `clarifications_consumed`
- REQ-052 — document `sanitize_block_reason()` 14→17 pattern expansion

**Target commit structure** (per doc-audit plan):
- Commit A (docs-BLOCKING+HIGH): `automation-config.md`, `config.md`, `examples/configs/*.md` (×8), `README.md`
- Commit B (docs-skills+agents-HIGH): `skills.md`, `agents.md`
- Commit C (docs-troubleshooting+pipeline+arch-HIGH/MEDIUM): `troubleshooting.md`, `pipelines.md`, `architecture.md`
- Commit D (CHANGELOG accuracy): `CHANGELOG.md`
- Commit E (code fixes): autopilot SKILL.md, post-publish-hook.md, hidden test
- Commit F (pipeline-resumed event): post-publish-hook.md, skills/*/SKILL.md firing sites
- Commit G (spec amendments): `.forge/phase-4-spec/final/requirements.md`
- Commit H (CHANGELOG v6.9.1 entry + version bump to 6.9.1)

### v6.9.0 PATCH context
v6.9.0 shipped 2026-04-20 with Phase 8 cycle-1 FULL_PASS (aggregate 0.953). The doc gaps were missed because Phase 9 doc-audit checked count strings (e.g., "19 optional sections") but not enumeration completeness. v6.10.0 will fix this via a Test Discipline Overhaul (see below).

---

## DEFERRED from v6.9.1 → later (heavier items, out of patch scope)

> **Note (2026-04-23):** the scoping below was written during v6.9.1 planning. It has been superseded by the **Post-v6.9.2 focus** section above, which splits these items across v6.10.0 (quality + prompt-injection), v6.10.1 (public-release blockers waiting on external mirror gate), and v6.11.0 (autopilot hardening — cross-run breaker + multi-host lock). Technical context below remains authoritative; version assignments above are canonical.

### OSS Readiness Follow-ups (wait for external trigger)
- **SECURITY.md secondary contact channel** — blocked on secondary email channel availability. Options: personal email or `security@<future-public-org>` forwarder once mirror exists. Will land when external dependency resolves, not on v6.9.1 timeline.
- **Replace placeholder repository URL** — `plugin.json.repository` currently `https://example.invalid/ceos-agents.git` (RFC 2606 unsquattable placeholder). Replace with canonical public mirror URL once provisioned. Gate: mirror exists + DNS resolves + HTTP 200 + org name confirmed.

### Autopilot Hardening (features, not patch-appropriate)
- **Cross-run circuit breaker persistence + Webhook URL allowlist** — covert-channel DoS via malicious `Webhook URL` in a PR is partially mitigated by per-run breaker in v6.9.0; full mitigation requires cross-run state persistence (breaker survives process restart) + operator-configured URL allowlist. Phase 3 Agent C adversarial Scenario 3. **Deferred: this is a FEATURE (new state schema + config key), not a patch item.**
- **Multi-host distributed lock for Autopilot** — disjoint-query pattern (v6.9.0) is operator-discipline-only; not enforced. Will evaluate three options: (1) flock advisory lock (NFS-fragile); (2) external coordinator (etcd/redis/consul — breaks no-deps invariant); (3) formalized disjoint-query with config validation. Gate: portability test matrix passing across local FS + NFS + SMB + S3FUSE. **Deferred: substantial design work + portability test matrix.**
- **Prompt-injection constraint for 8 remaining agents** — v6.9.0 shipped HIGH-risk 3 (test-engineer, e2e-test-engineer, backlog-creator). Remaining 8 (spec-reviewer, spec-writer, rollback-agent, sprint-planner, scaffolder, stack-selector, deployment-verifier, publisher) need the EXTERNAL INPUT Constraint per Phase 2 §G-3. **Deferred: 8-file mechanical batch best-handled as its own focused commit.**

### Test Discipline Overhaul → v6.10.0

**Source:** Phase 8 cycle-0 robustness reviewer (2026-04-20) — root finding

All 41 v6.9.0 visible test scenarios are documentation-presence assertions (`grep -F 'string'` against markdown), NOT functional behavioral tests. This pattern allowed 8 critical functional bugs in NEEDS_CLARIFICATION (asked_at field never written, Question/question case mismatch, .iteration field path wrong, double-increment, webhook never fired) to slip through Phase 7 + cycle-0 quality gates. Cycle-1 caught them only because devil's advocate read the impl directly.

v6.10.0 should overhaul test discipline: every functional REQ should have at least one scenario that exercises actual bash/jq state-machine logic, not just doc-string presence. Cycle-1 added `tests/scenarios/v6.9.0-needs-clarification-e2e.sh` as a stub demonstrating the pattern.

**Assessment:** Substantial scope (41 tests to audit + likely ~20-40 new functional tests to write). Worth doing in v6.10.0 as a dedicated quality sprint.

### Agent Dispatch Enforcement → v6.10.0

**Source:** Operator question (2026-04-21) — colleague concern that pipeline skills may not actually invoke Task tool to dispatch named subagents (`ceos-agents:fixer` etc.) and instead inline-execute the agent role in the same Claude context.

**Problem:** Pipeline skills (`fix-ticket`, `fix-bugs`, `implement-feature`, `scaffold`) instruct Claude in markdown prose like `"Run the fixer agent (Task tool, model: opus)"`. There is NO hard enforcement that Claude actually invokes the Task tool — Claude could read `agents/fixer.md`, "embody" the persona, and execute the work in the same context. This would silently negate:
- Agent context isolation (sycophantic agreement risk if reviewer sees fixer's reasoning)
- Per-agent token cost tracking (state.json `tokens_used` would be parent-context-aggregated)
- Model-per-role optimization (everything would run at parent's model, not per-agent opus/sonnet/haiku)
- The architectural diagram in `docs/architecture.md#data-flow` would be misleading

**Proposed 5-layer defense (combine layers 1+2+4 as v6.10.0 minimum):**

1. **Imperative SKILL.md prose** (~30 min) — replace `"Run the fixer agent (Task tool, ...)"` with `"You MUST invoke Task(subagent_type='ceos-agents:fixer', model='opus'). DO NOT inline-execute. Inline execution is a CONTRACT VIOLATION detected by post-skill validator."`. ~70% adherence improvement on its own.

2. **PostToolUse hook + validate-dispatch.sh script** (~3h) — `~/.claude/settings.json` hook fires after every `Skill` invocation. Script reads `.ceos-agents/state.json`, asserts each expected stage has `tokens_used > 100` (real agent dispatched). On violation: emit `[FATAL] Skill orchestration violation: $stage did not dispatch agent` and halt. ~95% catches inline-execution post-hoc with deterministic certainty.

3. **Pre-flight subagent_type assertion** (~4-6h, depends on plugin introspection API availability) — Step 0a in pipeline skills verifies all required `ceos-agents:*` subagent_types are registered in the runtime. Catches plugin-uninstall / registration failures.

4. **Functional dispatch enforcement test** (~6-10h, fits in Test Discipline Overhaul scope) — new `tests/scenarios/v6.10.0-skill-dispatch-enforcement.sh` runs synthetic skill against mock issue, asserts: each stage has nonzero distinct `tokens_used`, sequential timestamps (not parallel-parent-context), distinct models per stage. Catches violations at CI time before they reach production.

5. **Runtime dispatch logger** (~2-3h) — each agent dispatch appends to `.ceos-agents/dispatch-log.jsonl` with timestamp/stage/subagent_type/model/tokens. Audit tool `/ceos-agents:audit-dispatch ISSUE-ID` reads log and reports dispatch chain. Forensic-only (does NOT prevent violations, helps debug them).

**Recommended v6.10.0 scope:** Layers 1 + 2 + 4 (~12h total).

**Tests this is the SAME class of bug as the doc-only TDD pattern that Test Discipline Overhaul addresses** — both rely on assertion against doc strings instead of actual runtime behavior. Bundle these into one v6.10.0 quality sprint.

Theme: Breaking changes bundled together. Only release when enough MAJOR items accumulate.

### Cross-file Key Name Alignment
`Branch naming pattern` still appears inconsistently across agents, skills, and docs.
Requires coordinated rename — breaking change in Automation Config.

### Unified Plugin Design System
**Source:** User observation (2026-03-31) — filip-superpowers and ceos-agents have divergent structures

Establish a shared template/standard for Claude Code plugins so that new plugins follow a consistent architecture and existing plugins (filip-superpowers, ceos-agents) converge on the same patterns.

**Possible deliverables:**
- Plugin scaffold template (cookiecutter/copier style) — directory structure, CLAUDE.md skeleton, marketplace.json, plugin.json, example skill with all frontmatter fields
- Shared conventions doc — naming, frontmatter standards, agent definition format, versioning policy
- ceos-agents alignment with filip-superpowers patterns where it makes sense

**Depends on:** Commands-to-Skills migration completing first (now complete).
Only included here IF it produces breaking changes in ceos-agents. Otherwise MINOR.

---

## BACKLOG — Designed, Waiting for Slot

### ~~v9.0.1 polish queue~~ (SHIPPED 2026-04-29, see version table line 1071)
**Status:** ALL 9 items + extended Cat A/B/E/F scope shipped via forge run `forge-2026-04-29-001`. See CHANGELOG [9.0.1] for full detail. Original entry preserved below for historical context.

### v9.0.2 critical hotfix — overlay TOML dispatch wiring (PRIORITY)
**Source:** empirical regression detection 2026-04-29 during codegraph MCP integration testing in `asysta-ai/ceos-cmd` (session `9ac6979e`). Full analysis: `docs/plans/2026-04-29-overlay-dispatch-regression-evidence.md` (handover artifact from kolega's debugging session, in-repo copy). Forge brief: `docs/plans/2026-04-29-overlay-toml-dispatch-hotfix-brief.md`.

**Problem (one-line):** v8.0.0 TOML overlay migrace skončila pouze v dokumentaci a helper kódu — runtime path se nikdy nezapojil. `customization/*.toml` soubory (které examples a `/setup-agents` propagují) jsou silently ignored.

**Two confirmed defects** (verified in main `fa44838`):
- **A:** `core/agent-override-injector.md` Process step 1 hardcodes `.md`. `skills/setup-agents/lib/toml-merge.sh::resolve_overlay()` exists but has zero callers (orphaned).
- **B:** 8 z 13 dispatch step files vůbec injector nezavolá. fix-bugs: 6 ze 7 broken (only `04-fixer-reviewer-loop` injects). implement-feature: 2 ze 6 broken (01-spec, 07-publish).

**Empirical evidence:** session 9ac6979e, 8 agent dispatches, **0 prompts with `## Project-Specific Instructions`**, **0 `mcp__codegraph__*` tool calls** despite 5 correctly-written `customization/*.toml` files on disk.

**Classification:** PATCH (no contract change — runtime aligns with already-shipped doc contract). No renumbering of v9.1.0/v9.2.0/v10.0.0 needed.

**Scope (delegated to forge phase 1 research):** dispatch wiring policy (BEFORE-Task() injection for all 13 sites), legacy `.md` handling (migration guide says `[ERROR]`, no enforcement code exists — needs decision), integration test that would have caught this in v8.0.0.

**Out of scope:** bigger overlay redesign, new override formats, contract changes.

**Files (estimate):** `core/agent-override-injector.md` (rewrite), 13 step files (`skills/{fix-bugs,implement-feature}/steps/*.md`, `skills/check-deploy/SKILL.md`), 3 parent `SKILL.md` files, 1 new test scenario.

### ~~v9.0.3 polish queue~~ (MERGED 2026-04-30 → v9.1.0 Plugin Cleanup)
**Status:** All planned v9.0.3 items (jq cleanup) merged into v9.1.0 along with workflow-router deletion. Single MINOR release covers both. See v9.1.0 entry below.

### v9.1.0 — Plugin Cleanup (MINOR — workflow-router deletion + jq dep removal)
**Source:** 2026-04-30 user decision after diagnosing UX regression where `using-superpowers` rule + workflow-router's description-matching auto-interception broke ALL 15 destructive skills (fix-bugs, fix-ticket, publish, autopilot, scaffold, etc.). Combined with pre-existing jq cleanup (was v9.0.3 polish queue).

**Architectural rationale (router deletion):** workflow-router is structurally redundant. Each skill is self-describing via its `description` frontmatter — Claude Code's Skill tool natively auto-invokes non-destructive skills from natural language without a central dispatcher. For destructive skills, the `disable-model-invocation: true` flag means user-typed slash commands are the ONLY valid invocation path; a router intermediary cannot help (its `Skill()` calls are blocked by design). Router's destructive branch was always-broken-since-v6.x (when destructive skills got the flag). Deletion = removing dead code, not removing functionality.

**Scope:**

1. **Delete `skills/workflow-router/`** directory entirely.
2. **Test cleanup:**
   - Delete `tests/scenarios/sprint-workflow-router.sh`
   - Remove `workflow-router` line from `tests/scenarios/skills-directory-structure.sh:58`
3. **Doc reference cleanup** in 8 files (CLAUDE.md, README.md, CHANGELOG.md, docs/reference/skills.md, docs/plans/roadmap.md, docs/plans/cross-plugin-bridge-alternatives-REVIEW.md, docs/plans/sprint-planning-feature-spec.md, docs/guides/steps-decomposition.md, docs/superpowers/specs/2026-04-24-public-release-readiness-WIP.md, docs/superpowers/specs/2026-04-25-config-skills-agents-audit.md, docs/superpowers/specs/2026-04-27-ceo-presentation-narrative.md). Verify with `grep -rn "workflow-router" --include="*.md"` after edits.
4. **Skill count update** (feedback_doc_completeness invariant): 29 → 28 skills across CLAUDE.md, README.md, docs/reference/skills.md, docs/architecture.md.
5. **CHANGELOG `[Removed]` section** documenting deletion with rationale.
6. **Migration note** in CHANGELOG for users who relied on natural-language routing — point to direct slash commands and note that non-destructive skills auto-invoke from NL via their own `description` fields.
7. **`hooks/validate-dispatch.sh` jq removal** — refactor 6 `jq` invocations (state.json parsing for Layer 4 dispatch enforcement) to bash-only equivalents (grep/sed/awk patterns). Pre-existing from v6.10.0.
8. **Companion test re-enabling** — once #7 lands, `tests/scenarios/v6.10.0-skill-dispatch-enforcement.sh` will RUN unconditionally (currently SKIPs when `jq` is absent). Final harness target: 28X/28X/0/0.
9. **Optional:** `core/agent-states.md` 2 jq refs — same refactor pattern.

**Classification:** MINOR. Deleting a skill = removing public surface; even though router was always-broken-for-destructive, it had visible non-destructive auto-invoke value. Conservative semver = MINOR not PATCH. jq removal alone would be PATCH but bundling = MINOR.

**Test scenarios to add:**
- `v9.1.0-workflow-router-removed.sh` — assert `skills/workflow-router/` does not exist + skill count is 28.
- `v9.1.0-no-router-references.sh` — grep across docs for `workflow-router`, fail if any production reference remains (docs/plans historical entries can be excepted via path filter).
- `v9.1.0-skills-self-describing.sh` — assert every skill has a non-empty `description` frontmatter field (since natural-language routing now relies on this).

**Out of scope:** redesigning skill discovery, adding new help/discovery tooling, replacing router with an alternative dispatcher. If users miss "deprecated name suggestions" (`/status` → `/pipeline-status`), document in CHANGELOG `[Removed]` migration block + README; do NOT re-add a runtime intermediary.

**Outcome target:** zero `jq` dependency across production code + tests; workflow-router deleted; destructive skills work from direct `/ceos-agents:X` invocation without model interception; non-destructive skills auto-invoke from natural language via their own descriptions. Aligns with CLAUDE.md "pure markdown plugin, no build, no deps" invariant.

### v9.2.0 — Plugin cleanup + check-deploy deletion (MINOR)

**Source:** v9.1.0 Plugin Cleanup release deferred follow-up. The v9.1.0 release deleted 4 v9-overlay tests (`v9-overlay-dispatch-wiring.sh`, `v9-overlay-legacy-md-policy.sh`, `v9-overlay-provenance-log-emission.sh`, `v9-overlay-toml-render-layout.sh`) that were authored against transient `.forge/phase-5-tdd/` workspace paths and could not run on a fresh checkout. v9.2.0 must author **replacement v9-overlay coverage** against stable `tests/lib/` + `tests/fixtures/v9-overlay/` conventions to restore behavioral coverage of `core/agent-override-injector.md` + `skills/setup-agents/lib/toml-merge.sh` (the production code paths exercised by the deleted tests, which themselves remain fully shipped and correct).

**Scope:**
1. Author 4-5 replacement test scenarios under stable `tests/scenarios/v9.2.0-overlay-*.sh` naming, with fixtures committed to `tests/fixtures/v9-overlay/`.
2. Coverage target: full v9.0.2 hotfix scope — TOML primary path, `.md` legacy short-circuit, dispatch wiring per-step, provenance log emission, layout shape.
3. Plus: bash-only `make_state_json_bash` helper in `tests/lib/fixtures.sh` to fully decouple harness from jq runtime dependency (referenced by v9.1.0 spec design.md §6.3).
4. Delete `skills/check-deploy/` (27 skills after deletion). Rationale: unreachable in practice — no pipeline calls it (deployment-verifier is dispatched directly by fix-bugs, fix-ticket, implement-feature, scaffold); it wraps lifecycle ops users do directly; requires optional Local Deployment config section that most projects don't configure. Docs: CLAUDE.md skill count + list, docs/reference/skills.md, README.
5. Delete `skills/template/` (26 skills after deletion). Rationale: sub-step of `/onboard` accidentally exposed as a standalone command — `/onboard` Step 1 already calls it internally. No standalone use case that `/onboard` doesn't cover. Collateral: inline template listing + load logic directly into `/onboard` Step 1 (replace `run /ceos-agents:template list` call).
6. Merge `skills/dashboard/` into `skills/metrics/` (25 skills after deletion). Both skills read identical data (MCP comments, state.json, git log) and differ only in output format. New design: (a) default — run report, display in terminal (box-drawing output, current behavior), then ask "Výstup uložit? [1] Ne [2] JSON → stdout [3] HTML → ./metrics.html"; (b) positional arg (`/ceos-agents:metrics json` or `html`) skips the question. Remove `--format` and `--output` flags. Keep `--period`. Docs: CLAUDE.md skill count + list, docs/reference/skills.md, README.

### ~~v9.3.0~~ — Skills refactoring (SHIPPED 2026-05-04)
**Status:** SHIPPED via forge run `forge-2026-05-03-001` FULL_PASS 0.93. See release tabulka níže + CHANGELOG [9.3.0]. Originally drafted scope items (fix-ticket+fix-bugs merge, scaffold-add subcommand, resume-ticket drop, advisory triple) all delivered. v9.2.0 advisory backlog (3 items: `make_state_json_bash` duplicate-key, `v9.2.0-overlay-md-rejected.sh` orphan, `/metrics --format html` HTML-escape) shipped together. Final harness 306/301/1/4. Counts: 17 core / 17 agents / 22 skills / 18 config sections.

---

### ~~v9.4.0~~ — Switch from `goern/forgejo-mcp` to oficialni `gitea/gitea-mcp` (SHIPPED 2026-05-05)
**Status:** SHIPPED via forge run `forge-2026-05-05-001` FULL_PASS 0.895 (security 0.95, correctness 0.88, spec_alignment 0.95, robustness 0.78). Path B locked (env-var double divergence + archive format change). 12+ souboru zmeneno (7 planned + 5 ripple + 4 Phase 8.5 micro-revision). Final harness 304/309/1/4. Deferred: v9.4.1 polish (m1 stale-binary cleanup, m2 T2 allow-list narrowing, a1 prose-form pattern, a2 CI git-fetch-tags docs, a3 double-server advisory, a5 provenance sentence, a7 T2 allow-list spec), v9.5.x (a4 SHA256 checksum, a6 tar defense-in-depth).

### ~~v9.4.0~~ — Switch from `goern/forgejo-mcp` to oficiální `gitea/gitea-mcp` (MINOR)

**Source:** discussion 2026-05-05 — review otázka před public release: proč používáme komunitní Forgejo fork místo oficiálního Gitea MCP serveru? Historický artefakt z 2026-02-25 (`docs/plans/brainstorm/DECISIONS.md` #1) — tehdy se rozhodovalo jen mezi `forgejo/forgejo-mcp` (404) a `goern/forgejo-mcp` (community fork). Oficiální `gitea/gitea-mcp` (gitea.com/gitea/gitea-mcp) tehdy nebyl v rozhodovací matici, žádný technical comparison neproběhl.

**Rationale:** Pro public release je defensible volba **oficiální maintainerský MCP server**. Reviewers a early adopters očekávají oficiální tooling, ne community fork ze 4. ruky. Gitea MCP je designed specificky pro Gitea API (nikoliv Forgejo fork mapping), maintainerský upstream je samotný Gitea projekt.

**Backward-compat policy (rozhodnuto 2026-05-05):** **Bez explicitní backward-compat vrstvy.** Lokální-only plugin nemá důvod nést code-cost dvou-MCP-dispatch logiky. Pokud Phase 1 research ukáže že tool-naming se mezi `goern/forgejo-mcp` a `gitea/gitea-mcp` liší (= conditional dispatch v ~10 skills) → **hard switch, žádný fallback**. Pokud tool names match (Gitea API parita) → forgejo-mcp dál "náhodou" funguje bez explicitní podpory. V žádném případě plugin nepřidává kód jen kvůli zachování forgejo-mcp uživatelské zkušenosti.

**Path C handling (rozhodnuto 2026-05-05):** Pokud Phase 1 najde blocker tool chybějící v `gitea/gitea-mcp` → **ship v9.4.0 jako doc-only release** (CHANGELOG entry "v9.4.0 — Phase 1 research result, switch deferred until upstream gap resolved" + raise issue na gitea/gitea-mcp + roadmap update). **Žádné renumberování** následujících verzí. v9.5.0 pokračuje normálně. Důvod: zachovat stable version cadence pro audit trail; doc-only release je legitimní outcome research-driven decision gate.

**Scope:**
1. **Phase 1 — Research (forge phase-1):** parita check `gitea/gitea-mcp` vs `goern/forgejo-mcp`:
   - **Tool naming convention** (kritické pro decision gate): zda oba MCP exposují tool names ve stejném formátu (`mcp__gitea__create_issue` vs `mcp__forgejo__create_issue` apod.) nebo ne
   - Tool coverage matrix: issues (list, get, create, update, comment), pull requests (create, list, comments, merge, labels), state transitions, branches, milestones, repository introspection
   - Authentication model: token scopes, env var naming
   - Install story: pre-built binaries (Windows/Linux/macOS) vs `go install`, version cadence
   - Maintenance signal: commits / releases v posledních 6M, open issues, response time
   - Identifikovat blocker tools (pokud existuje): co `goern/forgejo-mcp` umí a `gitea/gitea-mcp` ne
2. **Phase 2 — Decision gate (na základě Phase 1):**
   - **Path A — tool names match + coverage OK** → switch je low-cost. Skills v pipeline volají stejné tool names; forgejo-mcp funguje dál náhodou (binary swap = jiná implementace stejného kontraktu). Žádný conditional dispatch kód v skills.
   - **Path B — tool names liší se nebo coverage gap** → **hard switch, drop forgejo-mcp support úplně**. Žádný runtime detection / fallback / dual-dispatch. `/setup-mcp` instaluje jen `gitea-mcp`; uživatelé s `forgejo-mcp` musí re-spustit `/setup-mcp`. Cost-cap: nesouhlasím přidat víc než ~5 řádků compat kódu.
   - **Path C — blocker tool chybí v `gitea-mcp`** → defer celé v9.4.0; raise issue na gitea/gitea-mcp + dokumentovat decision; pokračovat dál na v9.5.0.
3. **Phase 3 — Implementation:**
   - `examples/mcp-configs/gitea.json` — přepsat na `gitea-mcp` binary, nové env var názvy podle Phase 1 zjištění
   - `docs/guides/mcp-configuration.md` (sekce "Gitea/Forgejo MCP server" L45-55) — kompletní rewrite na oficiální Gitea MCP. **Forgejo zmíněn jen jako historická poznámka v CHANGELOG, ne v primary docs.**
   - `docs/guides/installation.md` — refs update
   - `skills/setup-mcp/SKILL.md` — install logika **přepsat** na `gitea/gitea-mcp` (žádná detekce starého binary, žádný prompt). Pokud uživatel má `forgejo-mcp` → `/setup-mcp` ho jen přepíše/dorovná instalací `gitea-mcp` do `.mcp.json`.
   - `README.md`, `CLAUDE.md` — pokud explicitně zmiňují `forgejo-mcp` → update
4. **Phase 4 — Minimal advisory (pouze Path B):**
   - **Pokud Path B:** `/check-setup` přidá jeden řádek warning pokud `forgejo-mcp` v `.mcp.json` ale Type=`gitea`: `[WARN] forgejo-mcp detected but Type=gitea — run /setup-mcp to switch to oficiální gitea-mcp (v9.4.0)`. To je vše. Žádný interactive prompt, žádný auto-detect-and-rewrite, žádný dual dispatch v skills.
   - **Pokud Path A:** žádný runtime warning, ale **explicit deprecation note** v `examples/mcp-configs/forgejo.json` header (`# DEPRECATED: prefer examples/mcp-configs/gitea.json with oficiální gitea/gitea-mcp binary; tento file kept jen pro backward-compat (API parita).`) + CHANGELOG zápis "v9.4.0 doporučuje gitea-mcp; forgejo-mcp dál funguje díky API paritě, ale je deprecated jako doporučená cesta." Reviewers a public adopters vidí explicit signal.
5. **Phase 5 — Test:** harness scénář ověřující `gitea-mcp` discovery + tool dispatch (mock MCP server adaptér). **Žádné backward-compat scénáře pro forgejo-mcp.**

**Classification:** MINOR — Automation Config kontrakt nezasažen (`### Issue Tracker → Type: gitea` zůstává; změna je jen v doporučeném `.mcp.json` binary).

**Risk / blockers:**
- **Tool naming divergence (Path B):** pokud Phase 1 najde tool-naming rozdíl, hard switch znamená že stávající forgejo-mcp users musí re-spustit `/setup-mcp`. Akceptovatelná friction pro lokální-only plugin.
- **Coverage gap (Path C):** ship doc-only v9.4.0 (CHANGELOG + upstream issue raise), žádné renumberování následujících verzí.
- **Windows install:** ověřit že `gitea/gitea-mcp` má Windows pre-built binary (jinak `go install` jako u `forgejo-mcp`).

**Depends on:** nic. **Blokuje:** v10.4.0 (announcement messaging by mělo používat oficiální MCP).

**Estimated size:**
- Path A: ~5 souborů upraveno (docs + examples + setup-mcp install command), 1 nový test scénář, žádná skill-code změna.
- Path B: ~6 souborů (jako Path A + 1 řádek ve `/check-setup`), 1 nový test scénář, žádná skill-code změna.
- Path C: 0 souborů; jen documented decision + roadmap update.

---

### v9.5.0 — Backward-Compat Cleanup + Skills Pruning (MINOR)

**Source:** discussion 2026-05-04 — překotný vývoj (v6 → v9.3 za ~2 měsíce) udělal z compat kódu mrtvý balast. Některé položky mají v komentářích `"removed in v9.0.0"` ale jsme na v9.3.0 a stále existují. Plugin je lokální-only (žádní externí uživatelé) → external break-risk = 0.

**Rationale:** Lokální-only plugin nepotřebuje udržovat schopnost resume v6.x/v7.x runů ani alias mappingy starých agent/stage jmen. Cleanup ~300 řádků mrtvého kódu redukuje maintenance surface a vyjasňuje kontrakt.

> **HARD GATE: MUST ship before v10.4.0 (public release announcement).** Lokální-only argument (external break-risk = 0) platí jen do okamžiku public announcement. Po v10.4.0 už backward-compat začíná počítat — odložení této verze za announcement by změnilo classification z MINOR na MAJOR a vyžadovalo by deprecation cycle. Pokud z jakéhokoliv důvodu nelze ship v9.5.0 před v10.4.0, scope musí být přehodnocen (drop některé položky, nebo odložit announcement).

**Scope (audit 2026-05-04, ordering 2026-05-05):**

Pořadí provedení v rámci forge run (kód napřed → testy → docs cleanup, aby každý commit byl atomický a testable):

**Wave 1 — runtime kód (state + resume + aliases):**
1. `core/state-manager.md:150-217` — odstranit v6.7.x fallback čtení (chybějící cost pole `tokens_used`/`duration_ms`/`tool_uses` → 0; chybějící `model`/`started_at`/`completed_at` → null) + v8 alias keys (`triage_completed_at` → `analyst_triage_completed_at`, `code_analyst_*`, `e2e_test_*`, `reproducer_*`).
2. `core/resume-detection.md:83-90` — odstranit `#ISSUE_ID` prefix normalizaci (legacy v6 tracker format).
3. `core/aliases/agents-rename-aliases.md` — smazat celý soubor (v7 agent jména `triage-analyst`, `code-analyst`, `e2e-test-engineer`, `reproducer`, `browser-verifier`).
4. `skills/setup-agents/lib/toml-merge.sh:443` + `skills/fix-bugs/SKILL.md:236-247` — smazat legacy `.md` overlay fallback. v7→v8 overlay format migration považována za dokončenou.

**Wave 2 — skills + version-check + pipeline profiles:**
5. `skills/version-check/SKILL.md:86-96` — odstranit v7 state.json detection advisory.
6. Pipeline Profiles stage name aliases v `skills/fix-bugs/steps/02-impact.md:12` (`code-analyst` → `analyst-impact`).
7. Redmine `status:{name}` → `status_id:{id}` legacy format detection v `skills/check-setup/SKILL.md:45-47`.

**Wave 3 — skill deletion (`/migrate-config`, `/estimate`, `/pipeline-status`, `/scaffold-validate`):**
8. `skills/migrate-config/` — smazat celý skill (a jeho Redmine legacy detection v `skills/migrate-config/SKILL.md:268-283`). **CHANGELOG migration message:** add explicit `[Removed]` block s `Migration: pokud máte pre-v9 plugin a chcete upgrade, skočte rovnou na v9.x/v10.x — žádný step-by-step migrate skript není provided. v6/v7/v8 → v9/v10 migration je manuální; konzultujte CHANGELOG entries jednotlivých verzí.` Důvod: po v10.4.0 announcement budou external users; bez tool a bez explicit message by upgrade path byl nečitelný.
9. `skills/estimate/` — smazat celý skill (110 řádků). **Rationale:** stale 2025-03 pricing tabulka (Sonnet/Opus/Haiku ceny jsou outdated po >1 roce), ±50% heuristic (low accuracy), zero usage signal (žádný forge run / release v memory ho nepoužil), v6.9.0 real-time cost visibility v `pipeline.json` poskytuje měřená data post-run (autoritativní > ex-ante odhad). **CHANGELOG message:** add `[Removed]` block s `Pre-flight cost estimate skill removed. Use post-run measured data in .ceos-agents/pipeline.json (added in v6.9.0) for actual token usage and cost tracking.` Pokud by se v budoucnu ukázalo že public adopters chtějí ex-ante odhad, dá se napsat čistě nanovo s aktuálními cenami a kalibrováno měřenými daty z `/metrics`.
10. `skills/pipeline-status/` — smazat celý skill (152 řádků). **Rationale:** primární use case (cross-issue runtime overview) předpokládá multi-pipeline parallel attended workflow, který user nemá — single-session usage vidí pipeline output přímo v Claude okně; "walked away" edge case je hypotetický (zero usage signal). Configuration Readiness subsection (~50 řádků) duplikuje `/check-setup`. Cross-references update needed: `core/state-manager.md:206` (informativní zmínka v dedup logice — buď reword nebo remove; dedup samotný stays for autopilot), `docs/guides/troubleshooting.md:312` (replace ref s `cat .ceos-agents/{ID}/state.json` + tracker UI), `docs/guides/installation.md`, `docs/guides/migration-v7-to-v8.md`, `docs/guides/steps-decomposition.md`, `docs/architecture.md`, `docs/reference/automation-config.md`, `docs/reference/skills.md`, `README.md`, `CLAUDE.md`, plus 5 test scénářů (skills enumeration + count assertions). **CHANGELOG message:** add `[Removed]` block s `Pipeline overview skill removed. For runtime visibility: 'cat .ceos-agents/*/state.json' for active pipeline state; tracker UI for issue-level status; 'git status' for branches.` Pokud by se v budoucnu ukázalo že multi-pipeline batch users to chtějí, dá se napsat čistě nanovo bez Configuration Readiness duplicate.
11. `skills/scaffold-validate/` — smazat celý skill (88 řádků) **+ relocate Docker dry-build check do `/check-setup`** (~10 řádků added). **Rationale:** load-bearing duplicate funkce — CLAUDE.md `## Automation Config` sections check je v `/check-setup` Block 1 (důkladněji: per-tracker validation, placeholder detection, optional sections format); build+test execution je v `/check-setup` Block 3 (s `--skip-build` flag); fresh-scaffold validate je v `/scaffold` internal phase (`skills/scaffold/SKILL.md:287` "L5: Validate (build + lint)" + `:360` "Validate output (build + lint)"). Unique Docker dry-build check **přesouvá** do `/check-setup` (decision 2026-05-07: konzistentní s existující Local Deployment validation, ~10 řádků nový check). Lint auto-detect (ruff/eslint/golangci-lint) **se nepřesouvá** — není v Automation Config kontraktu, většina projektů má lint v CI; relocate by byl feature creep za marginální payoff. **Docker check spec do `/check-setup`:** new step v Block 3 nebo nový "Block 4: Docker (optional)": `if [ -f Dockerfile ]; then docker build --no-cache -t check-setup-test . ; fi` → output `[OK] Docker — build passed` / `[FAIL] Docker — {error}` / `[SKIP] Docker — no Dockerfile`. Respektuje `--skip-build` flag (jako test/build kroky). Cross-references update: ~20 souborů (CHANGELOG, docs/guides/migration-v7-to-v8.md, docs/guides/steps-decomposition.md, docs/reference/automation-config.md, docs/reference/skills.md, docs/architecture.md, README.md, CLAUDE.md, skills/scaffold/SKILL.md:141 "See also" reference, plus 5 test scénářů (skills enumeration + count + frontmatter + directory structure)). **CHANGELOG message:** add `[Removed]` block s `Scaffold validation skill removed; Docker dry-build check moved to /ceos-agents:check-setup. Use /ceos-agents:check-setup for CLAUDE.md sections + build/test/docker validation; /ceos-agents:scaffold has built-in validate phase that runs after generation.`

**Wave 4 — test scénáře (po runtime změnách):**
12. Smazat zastaralé scénáře:
   - `tests/scenarios/v8-nf-state-additive-readable.sh`
   - `tests/scenarios/v8-agents-state-additive.sh`
   - `tests/scenarios/cost-resume-v6.7-state.sh`
   - další `v7-*` / `v8-back-compat-*` scénáře (audit jednotlivě před forge phase 4).
13. **Edit `tests/scenarios/verify-fail.sh`** (carried forward from v9.4.0 backlog) — smazat řádky 7-13 (kontrola `skills/fix-ticket/SKILL.md` "Fix Verification" — `fix-ticket` skill smazán v9.3.0 při merge do `/fix-bugs`). Zachovat řádky 15-29 (fix-bugs + implement-feature checks jsou stále valid). Net edit: -7 řádků v jednom test souboru. Důvod: bez edit by test failnul při prvním spuštění harness (set -e + `grep -q` na non-existent file).

**Předpoklad před commitem:** grep `.ceos-agents/` napříč všemi známými projekty (gitea_ceos-agents, drmax-readmine-test, bifito) zda neexistuje žádný pre-v9 state.json. Pokud ano → buď migrate, nebo accept loss of resume schopnosti pro ty starší runy.

**KEEP rozhodnutí (2026-05-07):** `/publish` skill **zachován** navzdory zvážení k delete. Důvody: (a) manual workflow support (developer kóduje ručně, pak `/publish` udělá PR + tracker update); (b) PR-only mode pro non-tracker branches (`chore/refactor-foo` → publish jako PR bez tracker update); (c) recovery use case (pipeline blokne na publisher fázi, fix manuálně, re-run `/publish`). Není duplicitní jako ostatní 4 delete kandidáti — publisher dispatch v fix-bugs/implement-feature/scaffold pipelines je interní paralelní cesta přes `Task()` agent dispatch, ne volání `/publish` skillu. **Defer revisit do v10.3.0+** — pokud po public release announcement community feedback ukáže že nikdo standalone nepoužívá, smazat ve v10.4.0/v11.0.0.

**KEEP rozhodnutí (2026-05-07):** `/pipeline-status` Configuration Readiness logika již **NENÍ** relocated do `/check-setup` — `/check-setup` Block 1 už pokrývá Automation Config sections check důkladněji. Žádný relocate.

**Classification:** MINOR — lokální plugin, žádný external break **(za předpokladu hard gate dodržen)**. Nicméně forge phase-1 ověří zda by formálně neměl být MAJOR (state.json schema změna může count jako breaking pro Cross-File Invariants kontrakt). Pokud by ship slipnul za v10.4.0 → mandatory MAJOR (v11.0.0) s deprecation cycle.

**Counts po cleanupu:** 22 → **18 skills** (smaže `/migrate-config` + `/estimate` + `/pipeline-status` + `/scaffold-validate`); 17 core (unchanged — resolved by Phase 2 forge research: `core/aliases/agents-rename-aliases.md` je depth-2, nepočítá se v `find core/ -maxdepth 1` kontraktu; deletion is no-op pro count assertion); 17 agentů beze změny; 18 config sections beze změny.

**Estimated size:** ~670 řádků net odstraněno (live measured 2026-05-07: 673 deleted = migrate-config 323 + estimate 110 + pipeline-status 152 + scaffold-validate 88; minus ~10 added pro Docker check v `/check-setup`; plus 7 řádků edit v `verify-fail.sh` carried-forward), 6+ test scénářů smazáno + 1 test scénář editován (`verify-fail.sh`) + 1 nový test scénář pro Docker check v `/check-setup` (plus případné `/estimate` + `/pipeline-status` + `/scaffold-validate` test scénáře — audit před forge phase 4). Single forge run.

**Depends on:** nic. **Blokuje:** v10.4.0 (hard gate, viz výše).

> **Forge run completed 2026-05-08** — `forge-2026-05-07-001`, FULL_PASS aggregate 0.839 (Sec 0.96 / Corr 0.78 / Spec 0.82 / Robust 0.82). 7 commitů na main: 021936d (W1+2), eb5948d (W3), 33a545a (W4), 3cbcbf8 (post-W4 fixes), e3e0273 (Phase 8 cycle-0 revision), 49e0b0f (forge artifacts), 42f1b9e (v9.3.0-doc-count-sync.sh stale-22 fix — pre-ship). Counts dosaženy (skills 22→18; core 17 unchanged; agents 17 unchanged; config 18 unchanged). Operator next step: `/ceos-agents:version-bump 9.5.0` + tag push.
>
> **Phase 8 advisory findings — disposition (2026-05-08, pre-ship):**
> - **Resolved (in-ship):** v9.3.0-doc-count-sync.sh stale `\b22\b` literals — refactored to post-v9.5.0 baseline (commit 42f1b9e); 26/26 assertions PASS post-fix.
> - **Resolved as design-choice:** scenario filename convention `v9-5-*.sh` (hyphen) vs spec literal `v9.5.0-*.sh` (dot) — umbrella tests provide 100% functional coverage; naming is operator-acceptable. NOT a backlog item.
> - **Resolved as design-choice:** 3 deleted overlay tests (v8-overlay-md-toml-coexist + provenance-log + syntax-error) — assertions were specific to legacy `.md` overlay path which Wave-1 removed; restoring would not assert anything meaningful. NOT a backlog item.
> - **Resolved as no-issue:** hidden-test `../..` path resolution — hidden tests are oracle-only (Phase 8 dispatcher reads them programmatically), never invoked from CLI directly. NOT a backlog item.
> - **Resolved as design-choice:** CHANGELOG single `### Removed` block vs spec's 4 separate blocks — Keep-a-Changelog format is guideline not enforcement; semantically equivalent. NOT a backlog item.
> - **Deferred to v10.4.0 public-release polish:** present-tense "consolidates the former triage-analyst" prose in `docs/reference/agents.md` L104/548/591 + `docs/reference/pipeline.md` L324-329. Cosmetic only; natural fit for v10.4.0 launch sprint (already a polish-heavy release).

---

### v9.6.0 — MCP Server Audit + Vendor-Official Migration (MINOR)

**Status:** SHIPPING 2026-05-09 (forge run forge-2026-05-08-001 with replanning cycle 1).

**Source:** User-prompted audit of all 7 MCP server templates (`examples/mcp-configs/*.json`). Original Phase 2 (2026-05-08) missed 3 vendor-official remote MCP endpoints (Atlassian Rovo, Linear, JetBrains YouTrack) by limiting search to npm namespace prefixes. Replanning cycle 1 (2026-05-09) corrected the evidence.

**Critical correction vs. memory of "v9.6.0 = cleanup":** Memory note from 2026-05-08 claimed v9.6.0 = GitHub pre-release cleanup. **This release supersedes that plan.** Cleanup is renumbered to v9.7.0 (later → v10.1.0 per 2026-05-11 cascade); public release polish to v9.8.0 (later → v10.2.0).

#### Scope (15 file edits)

**Vendor-official endpoint REPLACEs (5):**
1. `examples/mcp-configs/github.json` → `https://api.githubcopilot.com/mcp/` (HTTP, Bearer PAT)
2. `examples/mcp-configs/jira.json` → Atlassian Rovo `https://mcp.atlassian.com/v1/mcp` (HTTP, OAuth) — **Cloud only** per Gate 3 user decision (on-prem fallback dropped, may add v10.x+ if user demand)
3. `examples/mcp-configs/linear.json` → `https://mcp.linear.app/mcp` (HTTP, OAuth) — Linear je cloud-only SaaS
4. `examples/mcp-configs/youtrack.json` → `https://<INSTANCE>.youtrack.cloud/mcp` (HTTP, Bearer) — Cloud + on-prem 2026.1+; vitalyostanin fallback documented v `setup-mcp` Step 3 prose pro pre-2026.1 on-prem
5. `examples/mcp-configs/redmine.json` → `runekaagaard/mcp-redmine==2026.01.13.152335` via uvx — REDMINE_HOST → REDMINE_URL env rename

**Config fixes (2):**
6. `examples/mcp-configs/codegraph.json` → `"type": "https"` → `"type": "http"` (Claude Code schema fix)
7. `skills/setup-mcp/SKILL.md` Step 5 → 8 gitea asset names with new naming convention `gitea-mcp_v1.1.0_{OS}_{ARCH}.{EXT}` (PascalCase OS, x86_64), pinned na v1.1.0

**Skill body updates (1 file, 3 sections):**
8. `skills/setup-mcp/SKILL.md` Step 2b — npx prereq list updated (jen pro YouTrack vitalyostanin fallback path); NO upfront uvx check
9. `skills/setup-mcp/SKILL.md` Step 3 — detection table reflects new HTTP transport pro github/jira/linear/youtrack; uvx pro redmine; vitalyostanin fallback prose
10. `skills/setup-mcp/SKILL.md` Step 5 — gitea (8 platforms) + redmine sub-section rewritten pro uvx

**Cross-file consistency (3):**
11. `core/mcp-detection.md` — lookup table updated s nové transporty/endpointy
12. `docs/guides/mcp-configuration.md` — všechny tracker sekce aktualizovány
13. `docs/guides/tokens.md` — Jira/Linear/YouTrack token sekce update (no ATLASSIAN_EMAIL pro OAuth)

**New documentation (1):**
14. `docs/reference/mcp-server-versions.md` — NEW page s per-server status table (OFFICIAL/COMMUNITY), endpoint, auth, Cloud/On-Prem, MCP protocol version, last-verified 2026-05-09, next-audit date + audit cadence section + Atlassian SSE deprecation 2026-06-30 hard deadline

**CHANGELOG + tests:**
15. `CHANGELOG.md` v9.6.0 entry s per-file enumeration + BREAKING-FOR-USERS-OF-OLD-TEMPLATES callout + Atlassian SSE deadline
16. `tests/scenarios/v9-6-0-mcp-*.sh` (5 NEW scenarios per REQ-050..054)

#### Audit cadence commitment (per Naomi's chaos-engineering hard constraint)

- **90-day quarterly audit** of all 5 vendor-official endpoints + Redmine community pin (per `docs/reference/mcp-server-versions.md` cadence)
- **Hard deadline 2026-06-30** — Atlassian deprecates `/sse` endpoint that day; tracking required
- Next audit: **2026-08-09** (90 days from this release); MUST be done by v10.3.0+ ship
- Cadence enforcement: forge run quarterly, smoke test 5 critical curls (`https://api.githubcopilot.com/mcp/`, `https://mcp.atlassian.com/v1/mcp`, `https://mcp.linear.app/mcp`, `https://gitea.com/api/v1/repos/gitea/gitea-mcp/releases/latest`, `npm view runekaagaard/mcp-redmine`)

#### Net change

- **5 vendor-official replacements** (github, jira-Cloud, linear, youtrack-Cloud, gitea — last uz byl official)
- **1 community upgrade** (redmine: jesusr00 1* → runekaagaard 182*)
- **2 config fixes** (codegraph type, gitea asset names)
- **0 broken templates remaining** (predtim 4 hard 404)
- **1 new doc page** (`mcp-server-versions.md`)

#### Counts after release

- Skills: **18** (unchanged)
- Core contracts: **17** (unchanged)
- Agents: **17** (unchanged)
- Automation Config sections: **18** (unchanged)
- docs/reference/ pages: **11** (was 10; added mcp-server-versions.md)

**Depends on:** nic. **Blokuje:** v10.3.0 (cleanup — should ship right after; cleanup muze bezet bez zavislosti na MCP audit, ale logicky pre-launch oba musi byt done).

**Replanning audit trail:** Phase 2 (research-answers) re-executed s rozsirzenym scope; Phase 3 (brainstorm) re-executed s 3 personas + judge synthesis. Original Phase 2/3 artifacts zachovany jako `.invalidated` v `.forge/`.

---

### v9.6.1 — Implicit self-assign on On-start-set (PATCH)

**Status:** SHIPPING 2026-05-11 (mini-forge cycle: skipped Phase 0-3, ran Phase 5+7+8+9 inline).

**Source:** User-reported behavior gap (meeteo / Jira project MEE) — pipeline correctly transitions issue state per `On start set` config but does not set assignee. Plugin currently has no assignee handling at all (`grep` confirms zero references in production code; only mentioned historically in deleted forge artifacts). Adding implicit self-assign closes the gap with **zero new config keys** (true backward-compat PATCH per CLAUDE.md versioning policy).

**Behavior change:** When `fix-bugs` Step 1 fires `On start set` transition, the plugin shall ALSO call the tracker's assignee-set MCP tool to assign the issue to the MCP-authenticated user (self). **Scope: `fix-bugs` only** — `implement-feature` does not have an explicit `On start set` step (different orchestration model — feature decomposition creates sub-issues without applying On start set per Step 4e); deferred to future MINOR if feature-level self-assign is desired. Failure mode = advisory WARN (mirror `core/status-verification.md` pattern), pipeline never blocks. Existing `On start set` semantic stays (transition state) — self-assign is a new implicit default.

**Per-tracker MCP tool reference (inline in skills, no new core contract):**

| Tracker | Endpoint (post-v9.6.0) | Tool | Parameter shape |
|---------|------------------------|------|-----------------|
| jira | `mcp.atlassian.com/v1/mcp` | `editIssue` | `fields.assignee.accountId = "<self>"` (resolve via `getCurrentUser` MCP call) |
| youtrack | `<INSTANCE>.youtrack.cloud/mcp` | `update_issue` | Assignee custom field set to current user |
| linear | `mcp.linear.app/mcp` | `issueUpdate` mutation | `assigneeId: "me"` (Linear self shortcut) |
| gitea | `gitea-mcp` v1.1.0 binary | `editIssue` | `assignees: ["<self>"]` |
| github | `api.githubcopilot.com/mcp/` | `addAssignees` | `assignees: ["@me"]` (GitHub self shortcut) |
| redmine | `runekaagaard/mcp-redmine==2026.01.13.152335` (uvx) | `update_issue` | `assigned_to_id: "me"` (or numeric via `getCurrentUser`) |
| codegraph | (user-internal) | n/a | (skipped — codegraph is read-only context provider, not issue tracker) |

**Scope (final — 4 file edits):**
- `skills/fix-bugs/SKILL.md` Step 1 — instruct self-assign after status-set with per-tracker tool inline reference table
- `docs/reference/automation-config.md` — note implicit self-assign behavior under `On start set` row
- `CHANGELOG.md` v9.6.1 entry
- `tests/scenarios/v9-6-1-self-assign-fix-bugs.sh` (NEW) — verify Step 1 prose instructs self-assign + per-tracker tools mentioned
- `tests/scenarios/v9-6-1-self-assign-failure-advisory.sh` (NEW) — verify advisory failure mode (WARN, not block) + CHANGELOG + no new config key
- (no new core contract — per-tracker mapping inline in skills to keep PATCH classification strict)
- (`implement-feature` self-assign DROPPED from v9.6.1 scope — out of scope per orchestration model difference; tracked above)

**Classification:** PATCH per CLAUDE.md versioning policy — "Behavior fix without contract change". No new config keys, no new core contracts (count stays at 17), no new agents/skills/config sections (counts stay at 17/18/18 respectively). Existing user CLAUDE.md configs remain valid; new behavior fires automatically.

**Counts after release:** 18 skills, 17 core, 17 agents, 18 config sections, docs/reference/ pages 11 (all unchanged from v9.6.0).

**Depends on:** v9.6.0 (uses post-migration vendor-official MCP servers' assignee tools).

**Blokuje:** nic (orthogonal to v10.3.0 cleanup; v10.0.0 reliability fix je nezávislý — assignee handling neovlivňuje dispatch invariants).

**Open design questions (pending decision before implementation):**
- (Q1) Implementation style — streamlined patch (no forge, ~30-45 min) vs. mini-forge (Phases 4-9 only, ~1-1.5h) vs. full forge (~3-4h)
- (Q2) Failure mode — advisory WARN only (current proposal), OR future MINOR adds opt-out via `On start assign | none` config key

**Edge cases identified:**
- Self-resolution when MCP server uses Bearer PAT (whose user does it represent?) — most trackers expose `/myself` endpoint; resolve once, cache in pipeline state
- User has no permission to self-assign — advisory WARN, pipeline continues per `core/status-verification.md` pattern
- Tracker doesn't support assignee (theoretical — all 6 supported trackers do)
- User-explicit `--no-assign` CLI flag — out of scope for PATCH; MINOR if needed later

---

### v10.0.0 — Orchestration Reliability ENRICHED HYBRID (MAJOR)

**Status:** SHIPPED 2026-05-12 — forge run `forge-2026-05-12-001` completed Phases 0,4,5,6,7,8,9 (Phases 1-3 skipped, research/brainstorm directional verdict ENRICHED HYBRID confidence 0.80 from prior runs `forge-2026-05-11-001` paused + `forge-2026-05-11-002` second-opinion). User upgraded MINOR → MAJOR 2026-05-11 to preserve mandatory `## Step Completion Invariants` section as forward-compat insurance (L3 of 4-layer defense in depth). Phase 8 verdict: **FULL_PASS aggregate 0.922** (security 0.91, correctness 0.97, spec_alignment 0.97, robustness 0.82 — meets elevated 0.80 threshold per REQ-X-VERIFY). Full harness: 343 PASS / 0 FAIL / 6 SKIP. Ship commit: `{TBD-phase-9}`; test harness: 349 total (+9 v10 scenarios).

#### Carry-Forward to v10.1.0 (focused polish release)

7 items deferred from Phase 8 reviewer findings — all LOW or 1 MED severity, below the FULL_PASS revision threshold. Spec-scope-locked per REQ-X-SHIP-ORDER atomic ship invariant (mid-Phase-7 scope extension would invalidate Gate 4 approval). **Allocated to new dedicated v10.1.0** (small focused polish release) per 2026-05-12 user decision — plugin is pre-public, no real-world consumer urgency. Original GitHub cleanup release shifted to v10.2.0 (cascade renumber: cleanup v10.1.0 → v10.2.0, polish v10.2.0 → v10.3.0, Direct Mode v10.3.0 → v10.4.0). Smaller v10.1.0 scope = easier forge cycle + targeted verification of carry-forward fixes without bundling orthogonal mass-deletion work. CLAUDE.md `## Versioning Policy` MINOR clause covers all 7 (new backward-compat features + behavior fixes without contract change).

**v10.1.0 scope (focused polish release — all 7 items):**
1. **LOW — Log-injection sanitization** in `core/lib/stage-invariant.sh emit_witness_audit` — stage parameter via newline-bearing string could forge audit log entries. Practical risk = 0 (callers feed stage from hardcoded STAGES whitelist), but defense-in-depth: add `stage=${stage//[$'\n\r']/_}` normalization. Phase 8 security 0.91 LOW finding.
2. **LOW — Regex-injection in `check_dispatch_witness`** — stage parameter embedded in grep regex without escaping. Same callers-trusted mitigation. Add `printf '%s' "$stage" | sed 's/[][\.*^$/]/\\&/g'` escape.
3. **LOW — CLAUDE.md L317-L323 stale section ordering text** — Phase 9 doc-audit fixed Agent Definition Format additions (added Output Contract + Step Completion Invariants entries) but left adjacent ordering paragraph slightly stale. Cosmetic.
4. **MED — Stage-list consistency meta-harness** — new `tests/scenarios/v10-stage-list-consistency.sh` asserting parity between: `hooks/validate-dispatch.sh` STAGES, per-skill `<stage_allowlist>` blocks, `state/schema.md` enumerated stages, and agent per-stage bindings. Prevents future drift when a new stage is added (Phase 8 robustness 0.82 MEDIUM finding — the one explicit gap acknowledged in commander verdict).
5. **LOW — REQ-C-5 — examples/custom-agents/ harness validation** — current `v10-step-completion-invariants-completeness.sh` hardcodes `AGENTS_DIR="agents"`. Extension to also validate `examples/custom-agents/*.md` would close the consumer-onboarding gap (currently those files have the section as guidance but aren't gated).
6. **LOW — REQ-B-5 — strict-mode env var test** — `tests/scenarios/v10-strict-mode-opt-in.sh` exercising `CEOS_STRICT_DISPATCH=1` path through `hooks/validate-dispatch.sh`. Phase 6 plan TASK-B-006 reserved this; Phase 5 explicitly did not author it.
7. **LOW — Allow-list parser malformed-XML fixture** — `tests/fixtures/v10-stage-allowlist/malformed-{empty,truncated,extra-tags}.md` + harness assertion that `step-12-result.md` / `step-08-publish.md` parser fails gracefully (no false ANOMALY block) on malformed `<stage_allowlist>`. Phase 4 round 3 DA concern #3.

**Rationale for deferral + consolidation:**
- All items LOW severity except #4 (MED). #4 acknowledged in Phase 8 commander verdict as the one explicit gap, but the FULL_PASS aggregate (0.922) and elevated robustness (0.82 ≥ 0.80) meant no revision cycle was triggered.
- Spec REQ-X-SHIP-ORDER mandates atomic single-commit ship of 4 areas A/B/C/D. Adding scope mid-Phase-7 would have invalidated Gate 4 approval (28-REQ contract).
- Phase 6 plan TASK-B-006 explicitly noted REQ-B-5 strict-mode test as "advisory carry-over for Phase 7/8 dispatch, not in initial scope".
- Items #1-#2 (security) are theoretical injection vectors with current callers-are-trusted mitigation; converting to active defense is polish-grade.
- **Scope decision 2026-05-12 (user, two-step):**
  1. First proposed v10.0.1 PATCH (#1-#3) + v10.1.0 MINOR (#4-#7) cleanup release additions. Rejected as over-engineered version churn.
  2. Then proposed consolidation into v10.1.0 cleanup. User questioned bundling orthogonal scopes; decision was to **allocate v10.1.0 EXCLUSIVELY to carry-forward** and renumber GitHub cleanup to v10.2.0 (cascade renumber). v10.1.0 stays small/focused/easy-to-verify; GitHub cleanup keeps its own forge cycle without bundling.
- Estimated v10.1.0 scope size: ~150 lines (3 line-changes in stage-invariant.sh + 1 test for #4 + 1 test for #5 + 1 test for #6 + 3 fixtures + 1 test for #7). 3-4h forge cycle (small spec, no architectural decisions, all items are well-defined polish).

Reference: `.forge/phase-9-completion/carry-forward.md` (full Phase 8 finding text + severity matrix).


**Source:** User-reported behavior gap v consuming projektech (meeteo, BIFITO) — `/fix-bugs` a `/implement-feature` pipeline tiše skipuje agenty (`test-engineer`, `deployment-verifier`, `browser-agent`, `acceptance-gate`, E2E). Symptom: high token consumption, PR otevřen s nehotovými testy bez warning. Dva forge runy (paused + fresh second-opinion) forensicky potvrdily root cause — viz `.forge.bak-2026-05-11T180037Z/phase-2-research-answers/final.md` a `.forge.bak-{TBD}/phase-2-research-answers/final.md` (post-merge forge run audit trail).

**Forensic findings (Phase 2 dual-run convergent):**
1. `skills/fix-bugs/SKILL.md` = 929 řádků, **zero** `Read steps/` instrukcí → `steps/*.md` (833 řádků) jsou dead context. První Task dispatch na L375 (~40% hloubka souboru).
2. `skills/implement-feature/SKILL.md` = 371 řádků, stejný gap; první Task L137.
3. `skills/scaffold/SKILL.md` = 662 řádků s explicitní dispatch table na L120 (`Read 'steps/' sub-files. Execute in order:`); **zero documented silent skips**. Working reference pattern.
4. `skills/forge/SKILL.md` (filip-superpowers) = thin-controller; MANDATORY-EXECUTION-GUARD na L12 (2.3% hloubka), externí `data/guard-block.md`, XML-tagged, anti-rationalization table. Working reference.
5. `hooks/validate-dispatch.sh` triple-null pro failing stages: (a) vždy exit 0 (L107), (b) STAGES whitelist (L22) = jen 5 stages (omits `e2e_test`, `browser_verification`, `acceptance_gate`), (c) `dispatched_at` nikdy nepsán v fix-bugs prose.
6. `core/agent-override-injector.md:215` + `tests/scenarios/v8-count-core-contracts.sh:18` zakazují nový `core/*.md` (EXPECTED_CORE_COUNT=17). Escape hatch: `core/lib/*.sh` (subdirectory + .sh = exempt; precedent `core/snippets/`, `core/overlay/` ověřeno).

#### Scope (4 oblasti)

##### A) Thin-controller rewrite (load-bearing reliability mechanism)
- `skills/fix-bugs/SKILL.md` 929 → ~240 řádků; přesunout step prose do `skills/fix-bugs/steps/*.md` (nové soubory: 08-test.md, 08b-e2e.md, 08b-browser.md, 08c-acceptance.md, 08d-pre-publish.md, 09-result.md doplnit nebo přepsat). Nahoře nového SKILL.md: MANDATORY-EXECUTION-GUARD reference na file-position <6%, externí `skills/fix-bugs/data/guard-block.md`, XML-tagged. Explicit dispatch table mirroring `scaffold/SKILL.md:120` shape.
- `skills/implement-feature/SKILL.md` 371 → ~180 řádků; stejný pattern. `steps/08-publish.md` doplnit nebo přepsat.
- Nové `skills/fix-bugs/data/guard-block.md` + `skills/implement-feature/data/guard-block.md` (mirror `filip-superpowers/skills/forge/data/guard-block.md` shape).

##### B) Runtime-observable dispatch invariant
- Nový `core/lib/stage-invariant.sh` (Bash, ~85 řádků): `compute_dispatch_witness(stage, prompt_head_128, subagent_type, model)` + `check_dispatch_witness(stage, expected_witness)`.
- Nové optional pole `dispatch_witness` v state.json (sha256 hash) — orchestrator zapíše atomicky s `dispatched_at` před každým Task dispatch.
- `hooks/validate-dispatch.sh`: STAGES whitelist rozšířit z 5 na 8 (přidat `e2e_test`, `browser_verification`, `acceptance_gate`), sourcovat `core/lib/stage-invariant.sh`, emit `WITNESS_OK | WITNESS_MISSING | WITNESS_MISMATCH` audit lines pro každou stage.
- `state/schema.md`: dokumentovat `dispatch_witness` field pro všech 8 stages.

##### C) Per-agent completion contract (forward-compat insurance — MAJOR trigger)
- Nová **MANDATORY** sekce `## Step Completion Invariants` ve všech 17 `agents/*.md` (template-driven, ~5-10 řádků each). Pattern (per-agent customized):
  ```
  ## Step Completion Invariants
  Before returning DONE, the orchestrator MUST verify that state.json[<stage>] contains:
  - dispatched_at: nenull, ISO 8601 timestamp
  - dispatch_witness: nenull, sha256 hex string
  - tool_uses: nenull, integer >= 1
  - status: "completed"
  Failure to verify = return BLOCKED with reason "completion_invariant_violated:<missing-field>".
  ```
- Nový `tests/scenarios/v10-step-completion-invariants-completeness.sh` (harness completeness check — fail pokud kterýkoli `agents/*.md` postrádá sekci).
- Update `examples/custom-agents/*.md` (4 soubory: security-analyst, dependency-analyst, migration-reviewer, compliance-checker) — přidat template sekci jako consumer guidance.

##### D) Default-on terminal surfacing
- Nový (nebo rewritten v thin-controller) `skills/fix-bugs/steps/09-result.md` + `skills/implement-feature/steps/08-publish.md`: na konci pipeline číst `.ceos-agents/{ISSUE-ID}/dispatch-audit.log`, počítat `WITNESS_MISSING` výskyty, surfacovat v user-facing terminal report block. **Defaultně zapnuté, žádný env var.**
- Opt-in strict mode zachován: `CEOS_STRICT_DISPATCH=1` → hook exit 2 na `WITNESS_MISMATCH` (pro CI / strict consumers).

#### Falsification tests (6 nových harness scenarios)

| Test ID | Co testuje | Pre-fix | Post-fix |
|---|---|---|---|
| `v10-thin-controller-line-count.sh` | fix-bugs ≤250L, implement-feature ≤200L, dispatch table na <60% file position | FAILS (929L / 371L, 0 `Read steps/`) | PASSES |
| `v10-dispatch-witness-audit.sh` | Fixture state.json bez witness pro `acceptance_gate` produkuje `WITNESS_MISSING` audit line | FAILS (hook STAGES=5, žádná witness logika) | PASSES |
| `v10-schema-witness-coverage.sh` | `state/schema.md` enumeruje `dispatch_witness` pro všech 8 stages | FAILS (STAGES=5, witness=0) | PASSES |
| `v10-hooks-stages-extended.sh` | `hooks/validate-dispatch.sh:22` STAGES obsahuje všech 8 jmen | FAILS (jen 5) | PASSES |
| `v10-terminal-report-witness-surface.sh` | Step 9 step files grep-able pro `WITNESS_MISSING` + `dispatch-audit.log` | FAILS (step files neexistují) | PASSES |
| `v10-step-completion-invariants-completeness.sh` | Všech 17 `agents/*.md` obsahuje `## Step Completion Invariants` sekci s mandatory fields | FAILS (0/17) | PASSES |

#### Contract impact analysis (per CLAUDE.md L239-L249)

| Clause | Triggered? | Reasoning |
|---|---|---|
| MAJOR — "Breaking change in Automation Config contract — new required key, renamed section" (L243) | NO | Žádný nový required Automation Config key. `CEOS_STRICT_DISPATCH` je env var, ne config key. |
| MAJOR — "breaking change in agent output format contract" (L243) | NO | `## Output Contract` sekce v agent files nezasažena. |
| MAJOR — **"introduction of a mandatory new structured contract section in agent definition files that v8.0.0 agents would fail validation against"** (L243) | **YES** | `## Step Completion Invariants` je mandatory sekce ve všech 17 agent files; co-shipped harness scenario `v10-step-completion-invariants-completeness.sh` failuje pro agent file bez ní. **Toto je trigger pro MAJOR.** Precedent: v9.0.0 shipnul `## Output Contract` stejným pattern (FULL_PASS 0.91, žádný consumer pain). |
| MAJOR — "Adding new static declaration sections ... MAJOR when MANDATORY" (L249) | YES | Same as above. |

**Migration cost:** `examples/custom-agents/*.md` (4 soubory) dostanou template sekci v rámci tohoto release. Consumer-side custom agents (downstream uživatelé) via `core/agent-override-injector.md` structure-blind injector nepostradájí — injector je append-only a nevaliduje sekce. Real-world migration overhead = ~30 min update examples + dokumentace v CHANGELOG migration note.

#### Counts po release

| Metric | Před | Po | Změna |
|---|---|---|---|
| Skills | 18 | 18 | beze změny |
| Core contracts (top-level *.md) | 17 | 17 | beze změny (escape hatch: `core/lib/stage-invariant.sh`) |
| Agents | 17 | 17 | beze změny |
| Config sections | 18 | 18 | beze změny |
| Doc-count quartet drift | 0 | 0 | bez změny (jen `core/` count update v `core/lib/` shape note) |

#### Estimated size

~+1500 řádků netto, ~30 souborů (8 navíc oproti původnímu HYBRID MINOR návrhu):
- 2 thin-controller SKILL rewrites
- ~12 nových/rewritten step files
- 2 nová `data/guard-block.md`
- 1 nové `core/lib/stage-invariant.sh`
- 17 agent files (přidat sekci)
- 4 examples/custom-agents update
- 6 nových harness scenarios
- 1 `hooks/validate-dispatch.sh` update
- 1 `state/schema.md` update
- 1 CHANGELOG entry + migration note
- 4-5 doc-quartet sync edits

**Forge cycle estimate:** 9-12h (Phase 4 spec → 5 TDD → 6 plan → 7 execute → 8 verify → 9 completion). Phases 0-3 už hotové v paused run `forge-2026-05-11-001` + fresh second-opinion `forge-2026-05-11-002`.

#### Risks + mitigations

| Risk | Mitigation |
|---|---|
| Thin-controller rewrite breaks existing test fixtures | Phase 5 TDD writes regression tests against current behavior; Phase 8 verification cross-checks |
| `dispatch_witness` shape (sha256 input canonicalization) drifts under prompt template edits | Document canonical form v `state/schema.md`; harness scenario locks in expected witness shape |
| `## Step Completion Invariants` shape suboptimální (vybrána špatná fields) | Phase 4 forge spec writing designuje shape s explicit requirements; v11.0.0 fix bez backward-compat constraint pokud potřeba |
| Consumer Custom Agents (real-world) bez sekce by failovaly | Injector je structure-blind (verified `core/agent-override-injector.md`); real consumer agents nepostiženi |
| Forge 9-12h cycle déle než MINOR alternative (6-8h) | Acceptable trade-off za defense-in-depth — quality dividend > čas |

#### Sentinel-skip residual gap (zachován z původního HYBRID)

Pojmenován v `.forge.bak-2026-05-11T180037Z/phase-3-brainstorm/final.md` sekce 7. Závěr: defense in depth 3-layer enforcement (orchestrator guard + subagent completion contract + hook witness check) — všechny tři musí selhat současně pro recurrence. **Escalation trigger k v11.0.0:** 3+ consumer reports `WITNESS_MISSING` audit lines + green-state PR + `## Step Completion Invariants` verifikace skipnuta.

#### Classification

**MAJOR** per CLAUDE.md L243 ("introduction of a mandatory new structured contract section in agent definition files that v8.0.0 agents would fail validation against"). Co-shipped harness scenario (`v10-step-completion-invariants-completeness.sh`) činí classification non-circular.

**Why MAJOR is justified now (pre-public timing):**
- Plugin teprve jde public — žádní real-world Custom Agent consumers; migration cost = examples/ update only
- v9.0.0 `## Output Contract` precedent funguje (FULL_PASS 0.91, zero consumer pain)
- Forward-compat insurance je explicit user-value gain (long-term plugin quality)
- Reliability priority (user-stated) — 3-layer defense in depth > 2-layer
- Po public release každý MAJOR stojí 6-18 měsíců migration support; tohle je jednorázové cheap-MAJOR okno

#### Depends on / Blokuje

**Depends on:** v9.6.0 (post-MCP-audit vendor-official trackers; witness computation potřebuje stable per-tracker MCP endpoints), v9.6.1 (implicit self-assign baseline). **Blokuje:** v10.1.0 (carry-forward polish — fixes v10.0.0 reviewer findings) + v10.2.0 (`core/` path disambiguation) + v10.3.0 (cleanup nesmí ship před reliability fix — public launch by ukazoval rozbitou pipeline).

#### Open design decisions (pre-Phase 4 spec)

- (Q1) `## Step Completion Invariants` shape — generic per-stage (univerzální field list) nebo per-agent (každý agent-customized invariants)? Phase 4 spec rozhodne — recommendation: per-agent customized pro maximální information density.
- (Q2) `dispatch_witness` canonicalization — sha256 over `subagent_type|model|prompt_head_128` exact byte form, nebo include rendered template variables? Phase 4 spec rozhodne — recommendation: prompt_head_128 BEFORE Tier-1 variable injection (per Phase 0 meta-agent template), aby witness byl stable přes template variable substitution.
- (Q3) Strict mode default — advisory (current proposal) nebo strict (exit 2) by default? Recommendation: advisory by default, strict opt-in přes `CEOS_STRICT_DISPATCH=1` (zachováno z původního HYBRID).

> **Added 2026-05-11** from user-driven forge run pair (paused + fresh second-opinion). Fresh judge verdict HYBRID(thin-controller + dispatch-witness + hooks-extension) confidence 0.80 jako MINOR v9.7.0; user revize 2026-05-11 upgradovala na MAJOR v10.0.0 kvůli zachování `## Step Completion Invariants` mandatory sekce (forward-compat insurance + defense-in-depth 3rd layer). Cascade renumber: cleanup v9.7.0 → v10.1.0, polish v9.8.0 → v10.2.0, Direct Mode v9.9.0 → v10.3.0.

---

### v10.1.0 — v10.0.0 Carry-Forward Polish (MINOR)

**Status: RELEASED + IMPLEMENTED 2026-05-12** (forge-2026-05-12-002 single-cycle ship). Pipeline ran with skip [1,2,3] (Phases 1-3 already complete from v10.0.0 run). Full verification (TASK-HARNESS-FULL) ahead of version-bump commit.

**Source:** Phase 8 reviewer findings from v10.0.0 forge run `forge-2026-05-12-001`. Small focused polish release allocated 2026-05-12 (user decision) — separated from v10.3.0 GitHub cleanup to keep scopes orthogonal.

**Scope:** 7 items (3 LOW security/cosmetic polish + 1 MED stage-list meta-harness + 3 LOW test gaps). Full detail listed under v10.0.0 entry `#### Carry-Forward to v10.1.0 (focused polish release)` subsection — NOT duplicated here to maintain single source of truth.

**Estimated size:** ~150 lines, 3-4h forge cycle. No architectural decisions; all items are well-defined polish from Phase 8 commander verdict.

**Depends on:** v10.0.0 (this release fixes its known polish gaps). **Blokuje:** v10.3.0 (cleanup release should ship after v10.1.0 + v10.2.0 path disambiguation to absorb any follow-up findings).

---

### v10.1.1 — check_dispatch_witness grep -A window hotfix (PATCH)

**Status: RELEASED + IMPLEMENTED 2026-05-13** (single-pass v9.6.1-pattern: skipped forge cycle, ran fix + test + CHANGELOG + commit + tag inline). Surfaced by Phase 8 robustness review during v10.1.0 forge run `forge-2026-05-12-002`; deferred as out-of-scope of v10.1.0 carry-forward polish (scope-lock), shipped as standalone PATCH the next day.

**Source:** Phase 8 robustness reviewer (dimension score 0.74) empirically reproduced a pre-existing v10.0.0 BLOCKER bug while systematically probing the v10.0.0 lib for the first time. Full reproducer + fix candidates in `.forge.bak-{v10.1.1-archive-timestamp}/phase-8-verification/carry-forward.md` (committed in `ede7434` as part of v10.1.0 forge artifacts).

**Bug:** `core/lib/stage-invariant.sh::check_dispatch_witness` uses `grep -A 8 '"<stage>"[[:space:]]*:'` to find the `dispatch_witness` field within a stage block. When a `triage` stage block contains an `acceptance_criteria` array with ≥4 items (each on its own line in pretty-printed JSON), the `dispatch_witness` field falls beyond line 8 from the stage key match → false `WITNESS_MISSING rc=1`. Empirically reproduced 2026-05-13: 5-AC fixture → dispatch_witness at line 16, grep window stops at line 12 → MISS. Real-world impact: every fix-bugs run with ≥4 AC items (CLAUDE.md mandates 2-5) produces incorrect audit verdicts, undermining the L2 audit defense from v10.0.0.

**Root cause:** Hardcoded `-A 8` window introduced in v10.0.0 (file's birth commit). Not a v10.1.0 regression.

**Scope (PATCH — minimal fix):**
- **Fix option (chosen recommendation):** `grep -A 30` (raise window to cover up to ~20-item AC arrays + buffer). Single-line edit in `core/lib/stage-invariant.sh`. Alternative: awk-based stage-block extraction (robust against arbitrary array sizes) — ~10 lines, recommended for permanence.
- **New test:** `tests/scenarios/v10-witness-large-triage-block.sh` — fixture with 5-AC triage block, assert `check_dispatch_witness` returns `WITNESS_OK rc=0` (regression-protection).
- **CHANGELOG entry** + roadmap status update.

**Estimated size:** ~30-50 lines (1 line fix + 1 new test scenario + new fixture + CHANGELOG entry). 30-45 min single-pass, OR 2-3h mini-forge cycle (skip Phases 0-3, run 4-9 inline; pattern: v9.6.1).

**Optional bundled cleanup (LOW, post-v10.1.0 carry-forward):**
- Phase 4 spec docs drift: `.forge.bak-.../phase-4-spec/final/{requirements.md L51, design.md L130/L138-140/L361}` reference 4-backslash sed form. The actual correct form is 2-backslash. Cosmetic.
- ~12 LOW polish items across Phase 8 reviewer dimensions (FC tightening opportunities, line-count imprecisions in coverage-map.md, REQ-B-1 vs REQ-REL-LIB-BUDGET diagnostic string in v10-dispatch-witness-audit.sh L69).

These LOWs do NOT block v10.1.1 ship; they fold in opportunistically.

**Depends on:** v10.1.0 (this release fixes v10.0.0 bug surfaced during v10.1.0 forge). **Blokuje:** v10.1.2 (followed immediately by polish sweep) → v10.2.0 (`core/` path disambiguation) → v10.3.0 (cleanup).

---

### v10.1.2 — Polish sweep (PATCH)

**Status: RELEASED + IMPLEMENTED 2026-05-13** (immediately after v10.1.1; same-session sweep of remaining actionable LOWs from v10.1.0 Phase 8 reviewer findings).

**Scope (4 cosmetic/robustness items):**
- CLAUDE.md L106 typo `emit_witness_event` → `emit_witness_audit` (canonical function name)
- `tests/scenarios/v10-dispatch-witness-audit.sh` L13 header comment + L70 diagnostic string: REQ-B-1 attribution → REQ-REL-LIB-BUDGET attribution + ceiling 120 → 140
- `core/lib/stage-invariant.sh` self-test trap for temp file cleanup on SIGINT

**Estimated size:** ~10 lines. ~15 min single-pass.

**Out-of-scope (genuine reasons, NOT deferred):**
- CHANGELOG.md L20 historical `emit_witness_event` typo — Keep-a-Changelog convention: historical entries are immutable.
- `.forge/` doc drift (4-backslash sed text in spec artifacts) — forge artifacts are post-commit audit trail; rewriting falsifies history.
- Awk-based stage-block extraction (alternative to `-A 30`) — premature future enhancement; no observed regression with current implementation.
- Phase 5 staged-test FC tightening — staged tests preserve RED→GREEN signal property; post-ship tightening would break this audit guarantee.

**Depends on:** v10.1.1 (clean baseline). **Blokuje:** v10.2.0 (`core/` path disambiguation ships next).

> **Added 2026-05-13** as a roadmap entry per `feedback_roadmap_items.md` discipline. v10.1.0 forge Phase 8 robustness reviewer identified this BLOCKER; v10.1.0 scope was already locked (carry-forward from v10.0.0 commander verdict, NOT from v10.1.0-time review), so the fix was deferred to v10.1.1.

---

### v10.2.0 — `core/` path disambiguation in skill SKILL.md files (MINOR)

**Released:** 2026-05-13. Forge run `forge-2026-05-13-001`. Phase A (fail-loud guard + scaffold/data/guard-block.md NEW), Phase B (185 occurrences across 40 files rewritten to depth-correct relative paths, idempotent), Phase C (5 new harness scenarios, 13->18 total v10-*.sh). Harness: 0 failed.

**Source:** 2026-05-13 diagnostika `/fix-bugs` runu pro BIFITO-4293 (filip.sabacky). Orchestrator interpretoval relativní cesty `core/<file>.md` v `skills/fix-bugs/SKILL.md` jako pod-adresáře `skills/fix-bugs/core/` (který neexistuje) místo top-level `core/` (sourozenec `skills/`, `agents/`). Po `No such file or directory` z `ls` Claude **tiše pokračoval bez core logiky** ("Core files don't exist in this install — I'll work from SKILL.md + step files directly.") → vážná tichá degradace pipeline: chybí `resume-detection`, `mcp-preflight`, `config-reader`, `block-handler`, `decomposition-heuristics`, `agent-override-injector`, plus `dispatch_witness` audit z v10.0.0 reliability contractu.

**Sekundární finding:** Read tool tvrdil že načetl `core/resume-detection.md`, `core/mcp-preflight.md`, `core/config-reader.md` z `skills/fix-bugs/core/` — pak `ls` ty soubory vyvrátil. Halucinace v hlavičce orchestrátoru; Claude se vyvrátil sám sebe `ls`em. Nelze obecně zabránit (model behavior), ale Phase A guard vynucuje hlasité selhání místo tichého fallback.

**Scope (3 work items):**

1. **Phase A — Fail-loud guard (~30 řádků):** Do `skills/{fix-bugs,implement-feature,scaffold}/data/guard-block.md` přidat preflight check který testuje čitelnost kanonického probe-souboru `core/mcp-preflight.md`. Pokud nelze najít → abort se zprávou `"plugin-root not resolved — core/ sibling of skills/ not found at <attempted-path>. Check plugin install integrity."`. Žádný silent fallback. Tím se zarazí tichá degradace pozorovaná u BIFITO-4293.

2. **Phase B — Unambiguous path rewrite (~201 výskytů, mechanická):** Globální nahrazení `core/<file>.md` patternů v 37 souborech. Cílový formát TBD při forge brief (možnosti):
   - (B1) Prefix `${PLUGIN_ROOT}/core/...md` + resolver helper v guard-block.md (env var resolve z SKILL.md absolute path; `dirname` 2× nahoru).
   - (B2) Relative-to-SKILL `../../core/...md` (mechanická, ale Claude má problém s relative paths když CWD ≠ skill dir).
   - (B3) Inline upřesnění `core/<file>.md (sibling of skills/, at plugin root)` při prvním výskytu v každém SKILL.md + guard-block.md instrukce.
   - **Postiženo:** 9 SKILL.md (fix-bugs:12, implement-feature:14, scaffold:11, create-backlog:11, sprint-plan:10, publish:5, autopilot:4, setup-mcp:6, analyze-bug:1) + 28 step files + 2 guard-block.md. Celkem 201 výskytů `core/<file>.md` bez explicitního plugin-root prefixu.

3. **Phase C — Regression scenario (~30-50 řádků):** Nový `tests/scenarios/v10-skill-from-external-cwd.sh` který simuluje běh `/fix-bugs` z out-of-repo CWD (např. `/tmp/external-project/`) a ověří, že boot sequence buď najde `core/` přes resolved plugin root, nebo failne hlasitě (Phase A guard). Bez tohoto se bug znovu zaplíží — žádný stávající scénář netestuje "external CWD" path resolution.

**Classification:** MINOR — žádný Automation Config kontrakt change, žádný Output Contract change agentů; mění interní orchestrator chování + textovou formu cest v 37 skill files; přidává harness scenario. PATCH-eligible by také šlo (bez API kontrakt změny), ale rozsah (37 souborů, ~201 výskytů, nový harness scenario) + tichá degradace na public users ospravedlňuje MINOR bump.

**Estimated size:** ~250-350 řádků total (Phase A ~30 + Phase B ~50-100 net řádky after sed/regex pass + Phase C ~30-50 + CHANGELOG + roadmap status update). Forge cycle: 2-3 h (jeden coherent run; mechanická B + design-light A + test-driven C). Sole-source forge brief kandidát.

**Depends on:** v10.1.2 (clean baseline) -- **SHIPPED** 2026-05-13. **Blokuje:** v10.3.0 (GitHub cleanup nesmí ship dokud orchestrator může silentně degradovat — public users by spadli do stejné pasti při fresh `claude plugin install`).

> **Added 2026-05-13** from user-driven `/fix-bugs` diagnostic session pro BIFITO-4293: orchestrator silently bypassed core/ logic when path resolution failed; user rozhodl izolovat opravu jako samostatnou verzi (ne bundle do v10.3.0 cleanup). Cascade renumber 2026-05-13: cleanup v10.2.0 → v10.3.0, polish v10.3.0 → v10.4.0, Direct Mode v10.4.0 → v10.5.0.

---

### v10.3.0 / v1.0.0 — GitHub pre-release cleanup + public launch (MINOR → reset na v1.0.0)

> **ROZHODNUTÍ 2026-05-13:**
> - Plugin přejmenován: `ceos-agents` → `agent-flow`, skill prefix `ceos-agents:` → `agent-flow:`
> - Canonical repo: `https://github.com/asysta-act/agent-flow`
> - Verze resetována na **v1.0.0** pro public release (interní v6–v10 historie zůstane v Gitea archivu)
> - CHANGELOG začíná čistě od v1.0.0
> - Git historie: `git checkout --orphan` → jeden initial commit na GitHub (Gitea = archiv s plnou historií)
> - Roadmapa: rewrite pro komunitu — jen budoucí plány, bez interních renumbering poznámek
> - **Příprava proběhne v `C:\gitea_agent-flow`** (čistá pracovní kopie), pak push na GitHub

**Source:** discussion 2026-05-04 + community research (4 surveyed Claude Code plugin repa: `anthropics/claude-plugins-official`, `wshobson/agents`, `ivan-magda/claude-code-plugin-template`, `shinpr/claude-code-workflows`).

> **Renumbered 2026-05-13:** was v10.2.0, renumbered to v10.3.0 after v10.2.0 newly allocated to `core/` path disambiguation (user decision 2026-05-13 — keep scopes orthogonal, avoid bundling tichá-degradace fix s 33MB mass deletion). Cascade renumber: polish v10.3.0 → v10.4.0, Direct Mode v10.4.0 → v10.5.0.
> **Renumbered 2026-05-12:** was v10.1.0, renumbered to v10.2.0 after v10.1.0 allocated to v10.0.0 carry-forward polish (user decision — keep scopes orthogonal, avoid bundling 33MB mass deletion with 150L test additions). Cascade renumber: polish v10.2.0 → v10.3.0, Direct Mode v10.3.0 → v10.4.0.

> **Scope split 2026-05-05:** demo project byl původně Část A tohoto release. Přesunut do **separátního ceos-agents-demo repa jako v0.1.0** (po vzoru ceos-agents-web). Důvody: (a) standalone demo repo má vlastní release cycle; (b) bundling orthogonálních věcí (cleanup vs. demo) zatemňuje plugin scope; (c) plugin v10.1.0 = jen distribuční cleanup (bylo v9.6.0 → v9.7.0 → v10.1.0 přes 3 renumbery). Demo repo entry tracked v sekci níže "Demo project (separate repo)".

**Rationale — repo-as-distribution model:** Claude Code pluginy se instalují přes `claude plugin marketplace add <git-repo>` — celý repo se klonuje každému uživateli do `~/.claude/plugins/cache/`. Žádné `dist/`, žádný `.npmignore` ekvivalent. Každý soubor v repu = shipnut každému uživateli. Komunitní norma: ship jen canonical structure (`.claude-plugin/`, `agents/`, `skills/`, `commands/`, README, LICENSE) + consumer-facing docs. **Žádný ze 4 surveyed pluginů neshippuje `tests/`, `docs/plans/`, ani internal ADRs.** `shinpr/claude-code-workflows` má `docs/plans/` explicitně v `.gitignore`.

#### Scope — Repo cleanup (audit 2026-05-04 + decisions 2026-05-05)

**Pre-cleanup repo size (live count 2026-05-07):** ~70 MB, ~3000+ souborů.

**Critical step 1 — relocate `roadmap.md` PŘED deletion:** roadmap.md sám je v `docs/plans/` deletion path. Forge phase-7 musí provést `git mv docs/plans/roadmap.md docs/roadmap.md` jako první commit (atomic), separátně od `docs/plans/` hard-delete. Bez tohoto kroku tag commit smaže active-tracking dokument. Update všech ref na `docs/plans/roadmap.md` v repu (CHANGELOG, README, MEMORY snippets externí) na novou cestu.

##### MUST REMOVE (ship-blockers — install bloat, internal-only artefacts)

| Položka | Velikost | Souborů | Důvod |
|---|---|---|---|
| `.forge.bak-*/` (53 dirs, live 2026-05-07) | ~32 MB | 2415 | Historical pipeline run logs. Ekvivalent shippingu CI logs v npm. Žádný consumer use case. |
| `docs/plans/` (kromě roadmap.md, viz Step 1) | 2.9 MB | 99 (live: 100, minus roadmap.md = 99) | Internal design docs, ADRs, brainstorm outputs, REVIEW files, české zadání. Komunitní norma: `.gitignore`. |
| `docs/superpowers/specs/` | 340 KB | 9 | Internal forge briefs / specs. Stejný důvod jako `docs/plans/`. |
| `REVIEW-REPORT-v3.1.0.md` (root) | — | 1 | Stale review artifact z v3.1.0 era, root-level smetí. |
| `grep.exe.stackdump` (root) | — | 1 | Debug crash dump. |
| `nul` (root) | — | 1 | Windows stdout-redirect artifact. |
| `skills/version-bump/` | — | — | Plugin-maintainer internal tool. Community users nebumpují plugin verzi. |
| `.forge/` (current run) | ~755 KB | — | Současný forge run audit trail. Buď zachovat, nebo cleanout per release; ne v hot-path repu. |

**Akce:** Po Step 1 (roadmap.md move) hard delete + rozšíření `.gitignore` patterns:
```
.forge/
.forge.bak-*/
.forge.v*/
docs/plans/
docs/superpowers/
*.stackdump
nul
REVIEW-REPORT-*.md
```

##### KEEP DECISIONS (rozhodnuto 2026-05-05 přes runtime grep)

| Položka | Decision | Důvod |
|---|---|---|
| `tests/` | **KEEP** | Grep ukázal 10+ refs z `core/`, `docs/`, `core/snippets/`. Multi-agent pipeline trust signal. |
| `checklists/` | **KEEP** | Grep nalezl 2 ref (`agents/test-engineer.md`, `agents/reviewer.md`) — runtime referenced. |
| `state/` | **KEEP** | Grep nalezl 7 ref (3 core kontrakty + 4 skills/snippets). Runtime referenced; schema autoritativní. |

##### MUST KEEP (consumer-facing, plugin runtime)

- `.claude-plugin/` — plugin metadata
- `agents/`, `skills/`, `core/` — plugin runtime
- `tests/`, `checklists/`, `state/` — runtime referenced (viz výše)
- `examples/` (28 souborů) — config templates jsou consumer-facing copy-paste šablony
- `hooks/` — Claude Code event hooks
- `docs/guides/`, `docs/reference/` — consumer dokumentace
- `docs/roadmap.md` — relokovaný v Step 1
- `README.md`, `LICENSE`, `CHANGELOG.md`, `SECURITY.md`, `CODE_OF_CONDUCT.md`, `CONTRIBUTING.md`
- `.gitea/`, `.github/` (issue + PR templates) — required for Cross-File Invariant #3 (template parity)

##### Hygiene

- Po Step 1 (roadmap.md relocation) ověřit že žádný agent / skill / docs neref `docs/plans/` ani `docs/superpowers/specs/` paths (`grep -rn "docs/plans/" --include="*.md"`). Pokud existují → buď update ref na novou cestu, nebo (pokud pointují na smazaný soubor) odstranit.

#### Counts po cleanupu

**Skills:** 18 → **17 skills** (smazání `skills/version-bump/`; baseline 18 = post-v9.5.0 po smazání `/migrate-config` + `/estimate` + `/pipeline-status` + `/scaffold-validate`). Doc-count drift audit invariant (per `feedback_doc_completeness.md`): update pro CLAUDE.md, README.md, docs/reference/skills.md, docs/architecture.md.

**Core / agents / config sections:** beze změny.

#### Classification
MINOR — žádný runtime contract change (jen file-system / distribution surface cleanup) **+ jeden skill removal** (`/version-bump`). Plugin runtime nezasažen.

#### Estimated savings
~35 MB / ~2530+ souborů odstraněno (live count 2026-05-07: 2415 z `.forge.bak-*` + 99 z `docs/plans/` + 9 z `docs/superpowers/` + version-bump + root smetí). Repo z 70 MB → ~35 MB. Install footprint pro každého downstream uživatele odpovídajícím způsobem snížen.

#### Demo project (separate repo, NOT plugin scope)

Standalone `ceos-agents-demo` v0.1.0 — sandbox repo s pre-configured ceos-agents + záměrné bugy/features pro walkthrough. Tracked v separátním repo roadmapě po vzoru ceos-agents-web. Bonus: demo run produkuje state.json snapshoty pro hero replay scenarios v ceos-agents-web v0.1.0. **Created on a different schedule, not blocking plugin v10.1.0 ship.**

#### Depends on / Blokuje
**Depends on:** v10.0.0 (reliability fix musí být shipnut před public launch) + v10.1.0 (carry-forward polish shipnut) + v10.2.0 (`core/` path disambiguation shipnut — orchestrator musí být robust před public install). **Blokuje:** v10.4.0 (announcement musí ukazovat čistý repo, ne 67 MB s `.forge.bak-*` bloat).

> **Renumbered 2026-05-04** from v9.4.0 → v9.5.0 (v9.4.0 reallocated to Backward-Compat Cleanup).
> **Scope expanded 2026-05-04** s konkrétním must-remove inventory + community research evidence.
> **Renumbered 2026-05-05** from v9.5.0 → v9.6.0 (v9.4.0 reallocated to gitea-mcp switch; backward-compat cleanup posunut na v9.5.0; tato sekce posunuta na v9.6.0).
> **Scope split 2026-05-05** — demo project moved to separate ceos-agents-demo repo v0.1.0; plugin v9.6.0 = cleanup-only.
> **Decisions resolved 2026-05-05** — `tests/`, `checklists/`, `state/` keep (runtime grep evidence). `skills/version-bump/` count update explicit (18→17, post-v9.5.0 baseline).
> **Renumbered 2026-05-09** from v9.6.0 → v9.7.0 (v9.6.0 reallocated to MCP Server Audit + Vendor-Official Migration; cleanup posunuto na v9.7.0; public release polish posunuto na v9.8.0; Direct Mode posunuto na v9.9.0).
> **Renumbered 2026-05-11** from v9.7.0 → v10.1.0 (v10.0.0 newly allocated to Orchestration Reliability ENRICHED HYBRID MAJOR; cascade renumber cleanup→v10.1.0, polish→v10.2.0, Direct Mode→v10.3.0).

---

### v10.4.0 — Public release polish (MINOR)

**Source:** discussion 2026-05-05 — pure G polish bundle. Communication / documentation / hosting; žádný runtime refactor (ten je v v10.5.0).

#### Pre-release decisions (TBD — vyřešit PŘED otevřením polish-window)

**Tyto rozhodnutí nejsou polish-time, jsou strategické. Musí být decided before v10.3.0 forge/edit-window otevře, jinak polish blokne. HARD DEADLINE: 2026-05-14** (1 týden od 2026-05-07; pokud neresolved → blokuje v9.5.0+v10.1.0 ship).

- [x] **Canonical URL: GitHub mirror vs. gitea-only.** **RESOLVED 2026-05-13.** GitHub = primár, Gitea = archiv. Canonical repo: `https://github.com/asysta-act/agent-flow`. Plugin přejmenován: `ceos-agents` → `agent-flow`, skill prefix `ceos-agents:` → `agent-flow:`. Veškerý budoucí development jde na GitHub. **Owner:** Filip. **Hard deadline:** 2026-05-14. ✓
- [x] **SECURITY secondary contact channel.** **RESOLVED 2026-05-13.** GitHub Security Advisories (native GitHub vulnerability reporting, zero maintenance). Primary kontakt zůstává `filip.sabacky@ceosdata.com`. ✓
- [x] **Announcement target date.** **RESOLVED 2026-05-13.** Datum: **2026-05-14**. ✓

#### Scope (Public Release polish — once decisions resolved)
- **Canonical URL update:** `.claude-plugin/plugin.json:repository` z `gitea.internal.ceosdata.com` (per v9.0.1 polish queue) na finální hodnotu. README + docs/guides/installation.md ref update.
- **SECURITY.md rewrite:** contact (primary + secondary status), disclosure policy, supported versions matrix.
- **README.md rewrite:** marketing-grade, ne internal-zadání. Hero use cases (3 audience tiers per v10.5.0 Direct Mode messaging), install path, 60-second walkthrough.
- Hosting deploy ceos-agents-web řeší samotný web repo; plugin scope = jen polish + URL fix napříč repos.

#### Public announcement checklist
- [ ] Blog post draft (medium / personal blog / company blog) — TBD where
- [ ] Social media drafts: Twitter/X, LinkedIn, Mastodon (Czech tech community)
- [ ] Claude Code community channel post (Discord / GitHub Discussions)
- [ ] Reddit posts: r/ClaudeAI, r/programming (TBD subreddit fit)
- [ ] Email outreach: Anthropic plugin contact (if marketplace ingestion path exists)
- [ ] Demo repo (ceos-agents-demo v0.1.0) ship coordinated → link from announcement
- [ ] ceos-agents-web v0.1.0 deployed → link from announcement (if shippable in time)
- [ ] Launch date locked + announcement coordinated across channels
- [ ] First-week monitoring plan: who watches issues / Discord / social mentions for first 7 days

#### Messaging constraints
- v10.4.0 shipuje **konzervativně** (tracker mode only). Direct Mode (text prompt / file / no-PR) je v10.5.0 → announcement messaging musí buď:
  - (a) říct "tracker pipeline tool, Direct Mode coming v10.5.0" (honest, dva announce momenty), nebo
  - (b) odložit announcement až po v10.5.0 ship (jeden announce s plnou audience claim).
- **Decision deferred to v10.5.0 strategic defense (viz tam).** Default: (a).

#### Classification
MINOR — žádný runtime contract change. Polish-heavy = forge overkill, direct edits.

#### Depends on / Blokuje
**Depends on:** v9.5.0 (clean code, hard gate), v9.6.0 (MCP audit), v10.0.0 (orchestration reliability), v10.1.0 (carry-forward polish), v10.2.0 (`core/` path disambiguation), v10.3.0 (clean repo). ✓ v9.4.0 (oficiální MCP) satisfied 2026-05-05; ✓ v9.4.1 (gitea-mcp download fallbacks) satisfied 2026-05-07. **Blokuje:** v10.5.0 (post-announcement default per current decision).

> **Renumbered 2026-05-05** from v9.5.0 → v9.6.0 → v9.7.0 (per gitea-mcp + backward-compat insertions). Per-skill validation scope **moved 2026-05-05 to v9.8.0** (natural integrace s Direct Mode input-layer refactorem; jeden coherent refactor místo dvou partially-overlapping).
> **Pre-release decisions extracted 2026-05-05** — Canonical URL + SECURITY secondary + announcement date jsou TBD-decisions, ne polish work. Announcement checklist explicit.
> **Renumbered 2026-05-09** from v9.7.0 → v9.8.0 (v9.6.0 reallocated to MCP Server Audit; cleanup posunuto na v9.7.0; polish na v9.8.0; Direct Mode na v9.9.0).
> **Renumbered 2026-05-11** from v9.8.0 → v10.2.0 (v10.0.0 newly allocated to Orchestration Reliability ENRICHED HYBRID MAJOR; cascade renumber).

---

### v10.5.0 — Direct Mode + per-skill prerequisites (MINOR)

**Source:** discussion 2026-05-05 — strategic product decision (text input + no-PR + virtual issue) + per-skill prerequisites (gh CLI lazy-validation pattern). Sloučeno do jednoho release 2026-05-05 — oba refactory sahají do stejných míst (Step 1 každého pipeline skill, `/check-setup` rewrite, per-skill prerequisites docs, `automation-config.md` matrix), takže jeden coherent refactor je čistější než dva partially-overlapping.

Tracker-only design je historický artefakt z BIFITO/drmax kontextu (oba korporáti). Pro public release tracker-only = self-imposed adoption ceiling.

**Audience reality:**

| Profil | Použije ceos-agents dnes? | Po Direct Mode? |
|---|---|---|
| Korporát s YouTrack / Jira / Linear | Ano (target dnes) | Ano (unchanged) |
| OSS maintainer s GitHub Issues | Ano | Ano (unchanged) |
| Solo dev / hobbysta bez trackeru | **Ne** | Ano |
| Experimenter ("zkouším plugin na local repu") | **Ne** | Ano |
| Notebook / script developer | **Ne** | Ano |

Realistický odhad: **5-10× širší audience.** Solo devs jsou většina Claude Code community.

**Community precedent (research 2026-05-05):**

| Tool | Tracker required? | Text prompt input? | PR required? |
|---|---|---|---|
| Aider | Ne | Ano (positional) | Ne (commit only) |
| Cursor Composer | Ne | Ano (chat) | Ne |
| Continue.dev | Ne | Ano (chat) | Ne |
| Cody (Sourcegraph) | Ne | Ano | Optional |
| GitHub Copilot Workspace | Optional | Ano | Ano (default), no-PR mode |
| Replit Agent | Ne | Ano | N/A |
| Devin (Cognition) | Optional Slack/Linear | Ano | Optional |
| OpenHands (ex-OpenDevin) | Ne | Ano | Optional |
| filip-superpowers forge | Ne | Ano (forge takes any task) | Ne |
| **ceos-agents (dnes)** | **Ano** | **Ne** | **Ano** | ← outlier |

**Tracker-first integrace je výjimka, ne pravidlo.** Nejbližší analogie: **GitHub Copilot Workspace** — začal jako "issue → PR" (= dnešní ceos-agents), přidal prompt input později kvůli mizerné tracker-only adoption. Po přidání prompt vstupu adoption explodovala. Real precedent pro evolution arc.

**Quality contract:** "Garbage in = garbage out" je explicitní user contract (Aider precedent). Plugin nepředstírá že jednovětý prompt = stejná kvalita jako rich tracker issue. Doc s good-prompt examples + optional `--strict` flag který failne pokud prompt < 50 znaků.

#### Strategic decision: PŘED nebo PO v10.4.0 announcement?

**Roadmap default rozhodnutí 2026-05-05: PO announcement (announce konzervativně tracker-mode v v10.4.0, Direct Mode jako post-G milestone v10.5.0).** Rozhodnutí je explicitně defendováno z obou stran:

| Argument | PRO "po" (current) | PRO "před" |
|---|---|---|
| Marketing impact | Dva announce momenty = dva buzz peaky; "v10.5.0 — Direct Mode arrives" je samostatná news cyklus. | Jeden coherent announce s plnou audience claim (5-10×) = silnější PR moment, žádné "wait for v10.5.0" friction. |
| Risk profile | Initial release low-risk (jen polish + URL fix); pokud regression, malá blast radius. | Direct Mode validates feature před public eyes; pokud regression v10.5.0 hned po announce → reputation hit. |
| Audience expectation | Aider/Copilot Workspace evolution arc je věrohodný precedent (issue→PR start, prompt input later). | Solo devs uvidí "tracker required" v initial release → bounce před v10.5.0. |
| Forge investment risk | Phase 1 research validuje 5-10× claim PŘED forge commit; pokud claim selže, sunk cost je jen research. | Sunk cost na celý refactor pokud audience claim nesplní očekávání. |
| Schedule | v10.4.0 ship rychleji (polish-only); v10.5.0 nezdržuje announcement. | Announcement čeká na v10.5.0 ship — delší time-to-public. |

**Re-eval trigger:** pokud po v10.4.0 announcement community signal opakuje "wish ceos-agents took prompt" víc než 3× v prvních 7 dnech, **expedovat v10.5.0** na top priority. Pokud signal je tichý (community spokojená s tracker mode), v10.5.0 normální cadence.

**Monitoring plan (added 2026-05-07):**
- **Owner:** Filip.
- **Window:** prvních 7 dní po v10.4.0 announcement (T+0 až T+7).
- **Channels:** (a) Claude Code Discord (#plugins channel + DMs); (b) Reddit r/ClaudeAI + r/programming; (c) GitHub Discussions + Issues na public ceos-agents repo; (d) Mastodon/X mentions (search `@ceos-agents` + `ceos-agents`); (e) email inbox (filip.sabacky@ceosdata.com).
- **Threshold:** ≥3 distinct mentions požadavku na prompt input / no-tracker / direct mode v 7-day window. Mentions od stejného uživatele se počítají jako 1.
- **Action on threshold hit:** expedite v10.5.0 forge run (Phase 0 → 1 → 4 → 6 → 7 → 8) v T+8 až T+21 window. Skip Phase 0 audience claim re-validation (signal už validuje claim).
- **Action on no-signal:** v10.5.0 normální cadence (Phase 0 light pre-commit discovery dle plánu, no rush).
- **Daily check:** 5-min pass přes všechny channels denně po T+1; report Filip jen pokud threshold hit nebo close-to-hit (2+ mentions).

#### Scope

1. **Phase 0 — Pre-commit discovery (light, BEFORE forge phase-1 commit):**
   - Quick community signal scan: Aider GitHub issues / Discord / Reddit r/ClaudeAI pro "prompt input" / "no tracker" mentions u podobných tools.
   - Audit Copilot Workspace adoption metrics (public blog posts about evolution).
   - Filip osobní validation: 30-min thought experiment, jaké jsou last 5 plugin/tool feature reqs uživateli udělali a kolik z toho vyžadovalo tracker.
   - **Decision gate:** pokud Phase 0 ukáže audience claim < 3×, refactor scope na "tracker-only s vylepšeným messaging"; pokud ≥ 3×, commit na full forge run. Tato gate šetří proti committed-on-hopes scenariu.

2. **Phase 1 — Research (forge phase-1, jen pokud Phase 0 gate passes):**
   - Validation 5-10× audience claim přes community signal (Discord/Reddit/GH discussions o "wish ceos-agents took prompt").
   - Virtual issue contract design: jaké minimum metadata potřebuje pipeline (analyst čte AC, fixer čte description, reviewer cituje, publisher generates PR title) — co lze odvodit z prompt vs. co user musí dodat explicitně.
   - Auto-detect rules robustness: tracker ID pattern (`[A-Z]+-[0-9]+`, `#[0-9]+`), file path detection, prompt fallback. Co když user zadá `5` (batch count vs. issue ID #5)?

3. **Phase 2 — Design (`core/virtual-issue.md`):**
   - Single adapter před skill exekucí: load_input(arg) → virtual_issue.md (`.ceos-agents/inbox/{slug}/issue.md`).
   - Slug derivation: prompt prvních 50 znaků slugified, file basename, nebo tracker ID (passthrough).
   - State.json key = slug (místo issue ID). Tracker mode používá real ID jako slug = backward-compat.
   - Agents čtou virtual_issue.md identicky; netuší zda je real issue nebo prompt-generated.
   - Comments → soubor (`{slug}/comments.md` append-only) místo tracker API. Tracker mode dál posílá komentáře zpět do trackeru pro audit trail.

4. **Phase 3 — Implementation:**
   - **Core:** `core/virtual-issue.md` (nový kontrakt), shared step v `core/load-input.md`, state-manager.md key derivation extension.
   - **Skills:** `/fix-bugs`, `/implement-feature` Step 1 přepnout na `load_input(arg)` adapter. `/publish` Step 1 + Step N přidat `--no-pr` flow (commit-only path).
   - **Agents:** žádná změna. Agenti vidí jen virtual issue.
   - **CLI surface:**
     - `/fix-bugs <arg>` — auto-detect: tracker ID pattern → tracker; integer standalone (ambiguous) → batch z queue (current behavior); file path/`.md`/`.txt` → file; else → prompt
     - `/fix-bugs --todo` — niche scan TODO/FIXME komenty (jediný explicitní flag)
     - PR vs no-PR = config-driven (zero flags v běžném použití); `--pr`/`--no-pr` jako last-resort override
   - **Optional Automation Config sekce `### Direct Mode`** (default-on):
     ```
     ### Direct Mode
     | Key            | Value                       | Default |
     |----------------|-----------------------------|---------|
     | Enabled        | true / false                | true    |
     | Allowed inputs | tracker, prompt, file, todo | all     |
     | Require PR     | true / false                | false   |
     ```
   - **Per-skill prerequisites (gh CLI pattern, integrované do stejného input-layer refactoru):**
     - Smaž blanket `Required: Yes` v `docs/reference/automation-config.md:15-39` quick-reference tabulce; nahraď per-skill required mapping (tabulka už dnes částečně existuje v "Used By" sloupci, jen rozšířit na actual prereq matrix).
     - Každý skill `SKILL.md` deklaruje `## Prerequisites` sekci (nula nebo více Automation Config sekcí). Žádný runtime validator parsing — jen prose contract.
     - V Step 1 každého pipeline skill přidat `require_section "Issue Tracker"` shared step call (lokálně, ne globálně). Po Direct Mode integraci se requirement aplikuje jen na **tracker-mode dispatch path** — direct-mode (prompt/file) cesta requirement neaktivuje. Chyba vypadá konkrétně: `"/fix-bugs ID-mode requires Issue Tracker config in CLAUDE.md ## Automation Config. Use direct mode (/fix-bugs \"prompt\") or run /onboard."`
     - `/check-setup` přepsat na **per-skill matrix report**:
       ```
       ✓ Ready (11): /scaffold, /onboard, /discuss, /metrics, /version-check, ...
       ✓ Direct mode ready (4): /fix-bugs, /implement-feature, /autopilot, /publish (Direct Mode enabled)
       ⚠ /fix-bugs tracker-mode needs: Issue Tracker, Source Control, PR Rules, Build & Test
       ⚠ /publish PR mode needs: Source Control, PR Rules (Issue Tracker optional)
       ```
     - Po v10.5.0 už per-skill validation pokrývá jen residual prereqs (Source Control pro commit, PR Rules pro publisher). Tracker prereq se uplatňuje jen když user explicitně volá tracker-mode dispatch (issue ID).

5. **Phase 4 — Strict mode for corporates:**
   - `### Direct Mode → Enabled: false` v CLAUDE.md → pipeline skills failnou s jasnou chybou pokud user spustí `/fix-bugs "popis"`: `"Direct mode disabled by project config. Use tracker issue ID instead."`
   - `### Direct Mode → Require PR: true` → publisher nemá `--no-pr` cestu dostupnou, vždy PR.
   - **3 řádky shared step config check, žádný runtime overhead, zero regression risk pro existing corp users** (defaults match dnešní behavior když config sekci nepřidají).
   - Audit story pro security review: "Project může vypnout direct mode jedním řádkem v CLAUDE.md. Default-on jen pro adoption frictionless; default-off lze enforcovat globálně přes Agent Overrides nebo company template CLAUDE.md."

6. **Phase 5 — Test:**
   - Harness scénáře: tracker-mode (existing), direct-mode-prompt, direct-mode-file, direct-mode-todo-scan, direct-mode-corp-strict-blocked, --no-pr commit-only, virtual-issue slug derivation, state-key-collision (tracker ID vs slug).

#### Flag policy

**Konečný flag count:** 1 niche flag (`--todo`) + positional arg + 2 last-resort overrides (`--pr`/`--no-pr`). Čistší než většina dev CLI.

| Invocation | Behavior |
|---|---|
| `/fix-bugs BIFITO-123` | Tracker mode (current) |
| `/fix-bugs 5` | Batch 5 z queue (current; integer = batch count) |
| `/fix-bugs ./bugs.md` | File mode |
| `/fix-bugs "login is broken"` | Prompt mode |
| `/fix-bugs --todo` | Scan TODO/FIXME komenty (niche) |
| `/publish` (auto-detect issue ID v branch) | PR mode (current) |
| `/publish --no-pr` | Local commit only |

#### Risk + mitigation

| Risk | Mitigation |
|---|---|
| Quality regression na slabém promptu | Explicit `--strict` flag (fail < 50 chars); doc s good-prompt examples; "garbage in = garbage out" contract |
| Komplexita testů (2 input paths) | Virtual issue adapter = single source of truth; agenti nezasaženi; testy se větví jen v Step 1 load_input |
| State key collision (slug vs issue ID) | Slug prefix `direct-{slug}` vs tracker ID `{ID}` — namespace separation |
| Corporate audit panic | Strict mode 3-line config; default-off lze enforcovat company-wide |
| Pipeline ceremony heavy pro "fix typo" | User volí kdy spustit pipeline; `--prompt "fix typo"` může běžet, ale `claude` chat-based fix je rychlejší pro one-liner — to je OK |

#### Marketing positioning po v10.5.0

"ceos-agents — works like Aider for solo devs, like Copilot Workspace for teams, like enterprise pipeline for corp." 3 audience tiers v jednom plugin. **10× silnější marketing** než tracker-only positioning.

#### Classification
MINOR — Automation Config kontrakt není breaking (`### Direct Mode` je optional s default-on, plně backward-compat). Existing pipeline users dostanou identické runtime chování.

#### Estimated size
~20-25 souborů upraveno: nový `core/virtual-issue.md` + `core/load-input.md` shared step + state-manager.md key derivation extension + 4 pipeline skills Step 1 update (load_input + require_section) + publisher Step N split (PR vs no-PR) + `/check-setup` per-skill matrix rewrite + `automation-config.md` Required/Optional matrix rewrite + 17 SKILL.md soubory dostanou `## Prerequisites` sekci (template-driven, ~5 řádků each; post-v10.1.0 baseline = 17 skills). **Estimated total: ~600-800 řádků code change** (17 skills × 5 řádků Prereq + ~500 řádků nový/refaktored core/load-input + virtual-issue + 4 pipeline updates + check-setup rewrite). Reference: v9.4.0 gitea-mcp switch byl ~200 řádků (commit `4e6dc51`); v10.5.0 je ~3-4× větší. **Forge-driven** (Phase 1 research → Phase 4 spec → Phase 6 plan → Phase 7 execute → Phase 8 verify).

#### Cross-File Invariant impact
- **NEW invariant:** počet skills s `## Prerequisites` sekcí musí matchovat skill count (po v10.3.0 cleanupu: 17 skills = 17 souborů s `## Prerequisites`). Tracked ve `feedback_doc_completeness.md`.
- Update `automation-config.md` Required/Optional matrix musí být v sync s aktuálním skill catalogem.

#### Dependencies
- Po **v10.4.0 G** — public release musí proběhnout dřív než velká feature expansion **per current strategic decision** (viz "Strategic decision: PŘED nebo PO" tabulka výše). Pokud Phase 0 pre-commit discovery nebo post-v10.4.0 community signal změní rovnováhu, decision lze re-evaluate.
- **Nevylučuje** v10.x discussion. Pokud Direct Mode adoption silná → roadmap items jako multi-prompt batch / TODO scanner / IDE plugin integration.

#### Depends on / Blokuje
**Depends on:** v10.4.0 (per current strategic decision; lze re-eval). **Blokuje:** nic v10.x. **Triggers:** post-v10.5.0 v11.x feature expansion options.

> **Added 2026-05-05** from discussion: "ano akceptujeme text input + no-PR pro 5-10× audience expansion; strict mode pro korporáty triviálně enforceable; flagy redukovány na 1 niche + positional arg + auto-detect."
> **Scope expanded 2026-05-05**: per-skill prerequisites (gh CLI pattern) sloučeno z původního v9.7.0 part B — oba refactory sahají do stejného input-layer kódu (Step 1 dispatch + `/check-setup` rewrite), takže jeden coherent refactor je čistší.
> **Strategic defense + Phase 0 added 2026-05-05**: explicit oboustranná tabulka pro "PŘED vs PO" rozhodnutí + light pre-commit discovery gate před forge commit. Direct Mode tabulka header opravena (3 sloupce match).
> **Renumbered 2026-05-09** from v9.8.0 → v9.9.0 (v9.6.0 reallocated to MCP Server Audit; cascade renumber cleanup→v9.7.0, polish→v9.8.0, Direct Mode→v9.9.0).
> **Renumbered 2026-05-11** from v9.9.0 → v10.3.0 (v10.0.0 newly allocated to Orchestration Reliability ENRICHED HYBRID MAJOR; cascade renumber).

---

### v9.0.1 polish queue (HISTORICAL — shipped 2026-04-29)
**Source:** v8.0.0 forge cycle 3 deferrals + 2026-04-28 surfaced bugs (carried forward — v9.0.0 shipped 2026-04-29 without polishing these LOW items; renumbered from `v8.0.1` because v9.0.0 is now the active trunk).

1. `design.md` + `pipeline.md` `code-analyst → analyst-impact` mapping refresh.
2. `xref-skip-stage-names` test v7→v8 update (now: v7→v9 update — stale name list grew during v8.0.0 forge cycle).
3. 6 Windows harness portability bugy (paths, line endings, exec flags).
4. `docs/guides/migration-v7-to-v8.md` `Migration:` prefix coverage.
5. `formal-criteria.md` AC-MODE-009 entry.
6. `CLAUDE.md` residual "21 agents" mention cleanup (was 18 in v8, now 17 in v9 after stack-selector deletion).
7. `skills/version-check/SKILL.md` — fast-fail when remote URL is `example.invalid` placeholder. Currently the skill correctly handles timeout (line 46) but UI shows scary "Terminated EXIT: 143" before recovery. Add an explicit check: if `remote_url` host matches `example.invalid` (or any RFC 2606 reserved TLD), skip the `git ls-remote` call and report "Remote version check skipped — plugin.json `repository` field is a placeholder. Set it to a real URL via plugin v10.4.0 G."
8. `.claude-plugin/plugin.json` `repository` field is currently `https://example.invalid/ceos-agents.git`. Two paths: (a) set to current actual remote `https://gitea.internal.ceosdata.com/fsabacky/ceos-agents.git` now (works for internal users); (b) defer to v10.4.0 G alongside canonical URL decision. **Recommendation: (a)** — plugin is currently usable only via gitea anyway, locking in a working URL helps version-check + plugin install resolution for real users now. v10.4.0 G can update again to public URL if/when GitHub mirror is decided.
9. **(NEW 2026-04-29)** 4 v8 harness scenarios that bind to transient `.forge/phase-4-spec/final/design.md` content (`v8-overlay-scalar-override`, `v8-overlay-table-deepmerge`, `v8-setup-agents-header`, `v8-setup-agents-preview`) — should be re-pointed at stable production docs instead of per-run mutable forge artifacts. Phase 8 commander verdict 2026-04-29 flagged.

### ~~v9.0.1 polish ticket~~ (MOVED 2026-04-28 to ceos-agents-web)
Full content + 16 polish items (P-001..P-016) are now tracked in `ceos-agents-web` `docs/roadmap.md` (canonical URL TBD via v10.4.0 G). Source forge artifacts also moved with the sub-projekt: see ceos-agents-web `.forge/`.

**Source forge run** (kept in web repo as audit trail) — see `ceos-agents-web/.forge/` Phases 0–9.

### PRD / Product Discovery Workflow
**Source:** BMAD comparison — BMAD has a 12-step PRD creation process

Our spec-writer generates specifications in one pass (with review loop). BMAD has a multi-step
facilitated discovery: init, discovery, vision, executive summary, success metrics, user journeys,
domain model, innovation, project type, scoping, functional requirements, non-functional requirements.

**Assessment:** Our spec-writer + spec-reviewer loop covers the basic need for scaffold.
A full PRD workflow would be a significant addition (~12 new step files, possibly a new agent).
Worth exploring if scaffold users report that specifications lack depth. Could be implemented
as a `--deep-spec` flag on scaffold or as a standalone `/create-prd` command.

### Document Sharding with Selective Loading
**Source:** BMAD comparison — BMAD has INDEX_GUIDED loading strategy

When specifications get large, agents should load only relevant parts instead of everything.
We already shard scaffold specs (spec/README.md, architecture.md, verification.md, epics/*.md).
Missing piece: intelligent selective loading where architect reads only the epics relevant
to the current subtask.

**Assessment:** Not urgent — typical epics are 20-50 lines, even 7 epics is ~250 lines.
Becomes relevant for projects with 15+ epics or very detailed specifications.

### fix-bugs YOLO References (Latent Bug)
**Source:** v6.7.2 audit
- fix-bugs: YOLO references inherited from fix-ticket but --yolo flag not supported (latent, no user impact until --yolo is added to fix-bugs)

### Parallel State Schema Sections
**Source:** forge-2026-04-13-003 audit. Dedicated `spec_analysis.*`, `design.*`, `scaffold.*` sections instead of overloading `triage.*`/`code_analysis.*`. Mitigated by v6.7.2 inline mode-reuse documentation. Pull from backlog if downstream tools need structured access.
**Files:** `state/schema.md`, all pipeline skills. **Impact:** MINOR.

### spec-reviewer Split
**Source:** forge-2026-04-13-003 audit. Split into `spec-reviewer` (quality, opus) + `spec-compliance-checker` (--verify, sonnet). The --verify mode has different I/O contracts. Works fine as-is; split when scaffold refactor or `--extend` creates pressure.
**Files:** `agents/spec-reviewer.md`, new agent, `skills/scaffold/SKILL.md`. **Impact:** MINOR.

### Event-driven Gate Detection in Default Mode (B2 — "smoke alarm")
**Source:** v8.0.0 sub-projekt B brainstorm 2026-04-26 — B2 originally scoped, deferred from v8.0.0.

**Problem:** Default mode runs silently between strategic gates (e.g., between triage gate and acceptance gate). When fixer-reviewer loop hits a stuck pattern (reviewer flags same HIGH issue 3+ iterations in a row), pipeline currently waits to hard retry limit (5) before blocking — wastes ~250k tokens + 15-20 min wall-clock per stuck ticket.

**Proposed:** Add event-driven detection inside default mode:
- Trigger 1: fixer iter > N AND reviewer same-issue-flag count >= 3 → pause (interactive) or auto-block (autopilot)
- Trigger 2: AC fulfillment trending down across iterations → pause/block
- Trigger 3: build/test fail X consecutive times after fixer change → pause/block
- Configurable thresholds via Automation Config `### Retry Limits` extension (per-trigger thresholds, sensible defaults)

**Value calculus:**
- Manual debug (`--step-mode`) → user already sees iterations, B2 redundant
- Pure autonomous (`--yolo`) → B2 = early auto-block, saves tokens
- **Default mode + autopilot batches → B2 sweet spot:** detection in iter 3 instead of iter 5 = ~150k tokens saved per stuck ticket; on 50-ticket overnight autopilot batch with ~10% stuck rate = ~750k tokens saved + ~1-2 hours wall-clock recovery
- BIFITO autopilot pilot specifically benefits

**Why deferred:** A.1 mode framework (`--yolo` + default + `--step-mode`) covers public-release safety story. B2 is **production cost optimization**, not a release blocker. Add when real autopilot usage data shows stuck-pattern frequency justifies implementation cost.

**Trigger:** Real BIFITO/drmax autopilot deployment data showing stuck-rate > 5% per batch, OR community feedback requesting smarter default-mode detection.

**Files:** `core/agent-states.md` (event detection contract), `skills/fix-bugs/SKILL.md` + `implement-feature/SKILL.md` (default mode trigger logic), `core/config-reader.md` (threshold parsing), `docs/reference/automation-config.md` (`### Retry Limits` extension docs).

**Impact:** MEDIUM — adds new event-driven decision points; requires careful threshold tuning to avoid false-positive pauses; integrates with B6 scaffold mode harmonization if both ship together.

---

## EXPLORING — Needs Design

### Public Release Readiness (v7.0.0 epic candidate)
**Source:** brainstorming 2026-04-24 (per-sub-project specs pending under `docs/superpowers/specs/`)

**Core problem:** dnešní ceos-agents je CLI-first, plně autonomní, overlay-konfigurovaný, a nese historickou zátěž 29 skills + 21 agentů + 19 optional configů. Pro public release potřebujeme rozhodnout finální tvar agentů, přidat human-in-the-loop approval gates, vyčistit scope před zmrazením API, přidat web-based onboarding + interaktivní dashboard, a naskenovat projekt a navrhnout agenty (sedí na meta-agent z filip-superpowers).

**Sub-project decomposition:**

| # | Sub-projekt | Co řeší | Depends on |
|---|---|---|---|
| A | Agent shape rework | generic+overlay vs per-project vs meta-gen | — |
| B | Human-in-the-loop pipelines | konfigurovatelné approval gates + per-step diskuze | — |
| C | Scope cleanup / YAGNI sweep | revize 29/21/19, remove-before-freeze | — |
| D | Project scanner → agent suggester | naskenuj projekt, navrhni agenty (možná via meta-agent) | A |
| E | Web-based onboarding wizard | HTML náhrada za `/onboard` | A, D |
| F | Interactive dashboard | statický dashboard → ovládání pipeline | B |
| G | Public release polish | canonical URL, SECURITY kontakt, README, announcement | vše výše |

**Implementation order:** C → A → B → D → E → F → G (cleanup dřív než redesign; A blokuje D+E; B blokuje F; G nyní alokované do v9.8.0 — viz tabulka níže). E + F **přesunuty 2026-04-28 do separátního ceos-agents-web repa** jako v0.1.0 + v0.2.0; v plugin scope už nejsou.

**Release allocation (rozhodnuto 2026-04-25, přečíslováno):**

| Release | Theme | Sub-projekty |
|---|---|---|
| **v7.0.0** | Cleanup + naming + auto-detect publish (breaking) | C |
| **v8.0.0** | Architecture rework (breaking) | A + B |
| **v9.0.0** | Formal Agent I/O Contracts | **SHIPPED 2026-04-29** — sub-projekt **H** (Agent I/O Contracts). `## Output Contract` sekce s Inputs + Outputs tabulkami u 17 agentů (stack-selector deleted), polymorphic split u 4 agentů, doc-only contracts (no runtime validator), backward-compat (override injector untouched). Forge run `forge-2026-04-28-001` FULL_PASS 0.91. Pre-announced breaking changes shipnuty ve stejném release: stack-selector orphan delete, dispatch idiom harmonization, `[WARN]→[ERROR]` flip pro deprecated agent names + .md overlay. |
| **v9.0.1** | Polish + 0-FAIL test cleanup | **SHIPPED 2026-04-29** — 9-item polish queue + Cat A+B+E+F 0-FAIL extension + Wave 9 obsolete SKIP cleanup + Wave 10 jq refactor (Cat B additions back to bash-only). Forge run `forge-2026-04-29-001` FULL_PASS 0.9225 (Cycle 0 FAIL 0.827 → Cycle 1 FULL_PASS 0.9225). Final harness: 284/283/0/1 (1 SKIP = pre-existing v6.10.0 hook jq dep, deferred to v9.0.2). See CHANGELOG [9.0.1]. |
| **v9.0.2** | Critical hotfix — overlay TOML dispatch wiring | **SHIPPED 2026-04-30** — wire `customization/*.toml` overlays into agent dispatch (regression from v8.0.0 TOML migration: doc + helper landed, runtime path didn't). Two defects: injector hardcodes `.md`; 8 z 13 dispatch step files vůbec injector nevolají. Forge run `forge-2026-04-29-002` FULL_PASS 0.926. See CHANGELOG [9.0.2]. |
| ~~**v9.0.3**~~ | ~~Polish patch — pre-existing jq dep cleanup~~ | **MERGED 2026-04-30 → v9.1.0** — jq cleanup bundled with workflow-router deletion into single MINOR release. |
| **v9.1.0** | Plugin Cleanup — workflow-router deletion + jq dep removal | **SHIPPED 2026-05-01** — deleted `skills/workflow-router/` (architecturally redundant). Plus jq cleanup (validate-dispatch.sh L97 refactor). 8 test deletions + 5 new oracle tests. Forge run `forge-2026-04-30-001` FULL_PASS 0.947. Final harness: 286/285/0/1 (1 SKIP jq-free dev). 28 skills (was 29). See CHANGELOG [9.1.0]. |
| **v9.2.0** | Plugin Cleanup 2 — skill catalog consolidation | **SHIPPED 2026-05-02** — deleted `check-deploy`, `template`, `dashboard` (25 skills). Merged dashboard into `/metrics --format html`. Inlined template into `/onboard` Step 1. 11 new v9.2.0 test scenarios + `tests/fixtures/v9-overlay/`. bash-only `make_state_json_bash` in fixtures.sh. Forge run `forge-2026-05-02-001` FULL_PASS 0.897. Final harness: 296/296/0/0 (jq-equipped CI) / 296/294/0/2 (jq-free dev). See CHANGELOG [9.2.0]. |
| **v9.3.0** | Skills refactoring | **SHIPPED 2026-05-04** — merged `fix-ticket` + `fix-bugs` → `/fix-bugs` (tracker-type-aware dispatch, `--batch` flag, jq-free); merged `scaffold-add` into `/scaffold add` subcommand; dropped `resume-ticket` (resume detection inlined into 3 pipeline entry-points via new `core/resume-detection.md`, 17. core kontrakt). Plus 3 advisory fixes from v9.2.0 backlog. Forge run `forge-2026-05-03-001` FULL_PASS 0.93. Final harness: 306/301/1/4 (jq-free dev) / 296/296/0/0 (jq-equipped CI). 22 skills (was 25). See CHANGELOG [9.3.0]. |
| **v9.4.0** | Switch to oficiální `gitea/gitea-mcp` | Přepnutí z `goern/forgejo-mcp` (community Forgejo fork) na oficiální `gitea/gitea-mcp`. Phase 1 research → decision gate (Path A: tool names match → forgejo dál funguje náhodou; Path B: tool names liší se → hard switch, žádný dual-dispatch kód; Path C: blocker → defer). **Bez explicitní backward-compat vrstvy** — lokální-only plugin nemá důvod nést code-cost dvou-MCP-dispatch logiky. MINOR. (Added 2026-05-05; backward-compat policy explicit 2026-05-05.) |
| **v9.5.0** | Backward-Compat Cleanup + skills pruning | Smaže pre-v9 state.json fallbacky, v7→v8 alias mappingy, /migrate-config skill, /estimate skill (stale 2025-03 pricing, zero usage signal, ±50% heuristic — measured tokens via v6.9.0 real-time cost visibility nahrazuje), /pipeline-status skill (single-session usage pattern duplikuje Claude Code session view; tracker UI + git status pokrývají edge case "walked away"), /scaffold-validate skill (CLAUDE.md sections check duplikuje /check-setup Block 1; build+test execution duplikuje /check-setup Block 3; scaffold pipeline má vlastní internal validate phase L287/L360; **Docker dry-build check relocates do /check-setup** jako nový Block, ~10 řádků; lint detection nepřesouváme — není v Automation Config kontraktu), ~6 test scénářů. **~660 řádků net odstraněno** (~670 deleted minus ~10 added pro Docker relocate). 22→**18 skills**. MINOR. (Added 2026-05-04, renumbered from v9.4.0 → v9.5.0 2026-05-05; /estimate added 2026-05-07; /pipeline-status + /scaffold-validate added 2026-05-07.) |
| **v9.6.0** | MCP Server Audit + Vendor-Official Migration | Audit všech 7 MCP server šablon (`examples/mcp-configs/*.json`). 5 vendor-official endpoint replacements (github, jira-Cloud, linear, youtrack-Cloud, redmine uvx), 2 config fixes, 1 nová doc stránka (`mcp-server-versions.md`). 90-day quarterly audit cadence + Atlassian hard deadline 2026-06-30. MINOR. (forge-2026-05-08-001; replanning cycle 1 — rozšíření Phase 2 scope o non-npm vendor MCP endpointy.) |
| **v10.0.0** | Orchestration Reliability ENRICHED HYBRID | MAJOR contract bump. Thin-controller rewrite of `fix-bugs` (929→~240L) + `implement-feature` (371→~180L) per scaffold/forge precedent; new `core/lib/stage-invariant.sh` + `dispatch_witness` state.json field + extended `hooks/validate-dispatch.sh` STAGES (5→8); **MANDATORY `## Step Completion Invariants` sekce v 17 agent files** (forward-compat insurance, MAJOR trigger per CLAUDE.md L243); default-on terminal-report surfacing of `WITNESS_MISSING` audit lines; co-shipped harness completeness test. 3-layer defense-in-depth enforcement (structural guard + runtime witness + subagent completion contract). ~+1500 řádků netto, ~30 souborů, 9-12h forge cycle. (Added 2026-05-11 via paired forge runs `forge-2026-05-11-001` + `forge-2026-05-11-002`; user-upgrade MINOR→MAJOR 2026-05-11 pro zachování forward-compat insurance.) |
| **v10.1.0** | v10.0.0 Carry-Forward Polish | Focused polish release: 7 items from v10.0.0 Phase 8 reviewer findings (3 LOW security/cosmetic + 1 MED stage-list meta-harness + 3 LOW test gaps). ~150 řádků, 3-4h forge cycle. MINOR per CLAUDE.md (new tests + behavior fixes without contract change). (Added 2026-05-12; original split #1-#3 v10.0.1 PATCH + #4-#7 v10.1.0 MINOR rejected, then v10.1.0 = cleanup + carry-forward rejected; final allocation = v10.1.0 EXCLUSIVELY carry-forward, GitHub cleanup renumbered to v10.2.0.) |
| **v10.2.0** | `core/` path disambiguation in skill SKILL.md files | Fail-loud guard + unambiguous path rewrite + regression scenario. Fixes tichá-degradace pozorovaná u BIFITO-4293 (orchestrator interpretoval `core/<file>.md` jako pod-adresář `skills/fix-bugs/`, tiše pokračoval bez core logiky včetně dispatch_witness auditu). 37 souborů / ~201 výskytů. MINOR. (Added 2026-05-13.) |
| **v10.3.0** | GitHub pre-release cleanup | Repo hygiene cleanup: relocate `docs/plans/roadmap.md` → `docs/roadmap.md` jako Step 1, pak hard delete `.forge.bak-*/` (~30 MB), `docs/plans/` (95 souborů), `docs/superpowers/specs/`, `skills/version-bump/`, root smetí (`REVIEW-REPORT-*.md`, `*.stackdump`, `nul`); rozšířit `.gitignore` patterns. `tests/`, `checklists/`, `state/` KEEP (runtime grep evidence 2026-05-05). 18→**17 skills** (`/version-bump` removed; baseline 18 = post-v9.5.0 po smazání `/migrate-config` + `/estimate` + `/pipeline-status` + `/scaffold-validate`). Předpokládá ~33 MB / ~2470+ souborů odstraněno (67 MB → ~34 MB repo). MINOR. (Demo project split off to separate `ceos-agents-demo` repo v0.1.0 2026-05-05. Renumbered: v9.6.0 → v9.7.0 2026-05-09 → v10.1.0 2026-05-11 → v10.2.0 2026-05-12 → v10.3.0 2026-05-13.) |
| **v10.4.0** | Public release polish | G pure: canonical URL, SECURITY, README rewrite, announce. Hosting deploy of web (E/F) moved to ceos-agents-web repo. Polish-heavy = forge overkill, direct edits. MINOR. (Renumbered from v9.5.0 → v9.6.0 → v9.7.0 → v9.8.0 → v10.2.0 → v10.3.0 → v10.4.0 přes 6 cascade renumberings.) |
| **v10.5.0** | Direct Mode + per-skill prerequisites | Strategic product expansion: text prompt / file / TODO scan jako alternativa k trackeru; `--no-pr` mode pro local-only commit; virtual issue abstrakce (`core/virtual-issue.md`) jako single source of truth pro agenty; per-skill prerequisites (gh CLI lazy-validation pattern, sloučeno z původního v9.7.0 part B); strict mode pro korporáty přes optional `### Direct Mode` Automation Config sekci. Audience 5-10× expansion. Aider/Copilot Workspace precedent. MINOR (backward-compat: defaults match dnešní behavior). Forge-driven. (Added 2026-05-05; per-skill scope merged 2026-05-05; renumbered v9.8.0 → v9.9.0 → v10.3.0 → v10.4.0 → v10.5.0.) |
| ~~Node.js Runtime + interaktivní F~~ | (Originally proposed as next MAJOR) | **DROPPED 2026-05-02** — plugin zůstává markdown-only, žádný Node.js runtime. Dashboard / interaktivní F řeší ceos-agents-web (separate repo). The next MAJOR slot was instead used for v10.0.0 = Orchestration Reliability ENRICHED HYBRID (2026-05-11). |

> **Historical note:** ~~v9.0.0 = E showcase web~~ MOVED 2026-04-28 → ceos-agents-web v0.1.0. ~~v9.1.0 = F read-only dashboard~~ MOVED 2026-04-28 → ceos-agents-web v0.2.0. The freed v9.0.0/v9.1.0 numbers were reallocated to plugin-core work (H + Demo) per the same-day Agent I/O Contracts brainstorm.

**Důvod přečíslování (2026-04-25):** sub-projekt C obsahuje breaking changes (smazání `Extra labels`, rename `/status`→`/pipeline-status`, rename `/init`→`/setup-mcp`, smazání `/create-pr` skillu). Per CLAUDE.md versioning policy = MAJOR. User rozhodnutí: dnes málo userů, později mnohem víc — tlačit rychle, ne držet semver-conservative scope split. Public release polish posunut z v7.0.0 do v9.0.0 (žádný funkční dopad — interní renumbering).

**v9.x cross-release blockers + final scope (rozhodnuto 2026-04-27 přes Volba C):** v9.0.0 je **blocked by v8.0.0** (HOTOVO, forge dokončen 2026-04-27 FULL_PASS 0.863). E závisí na sub-projektu A (TOML overlay schema z `/setup-agents`); F závisí na sub-projektu B (HITL gates v state.json). Per CLAUDE.md versioning policy oba E a F = backward-compat features = MINOR releases (ne MAJOR), proto rozsekáno na samostatné minor verze místo původního "v9.0.0 = E + F dohromady". Důsledky:
- **D ABSORBED** do v8.0.0 jako `/setup-agents` skill (sub-projekt A.1 ř. 50 design specu) — D bývalý "Project scanner → agent suggester" je identická funkce. v9.x nemá samostatný D track.
- ~~**v9.0.0 = E only** (showcase web)~~ — **MOVED 2026-04-28** do `ceos-agents-web` repa jako v0.1.0. Plný brainstorm zůstává v plugin specs (`docs/superpowers/specs/2026-04-27-E-showcase-brainstorm.md`) jako historical record.
- ~~**v9.1.0 = F read-only only** (dashboard)~~ — **MOVED 2026-04-28** do `ceos-agents-web` repa jako v0.2.0. Sdílená `file-import.ts` infrastruktura zůstává shared přes workspace package `@ceos-agents/file-import` (v ceos-agents-web `packages/shared/`). Brainstorm: `docs/superpowers/specs/2026-04-27-F-dashboard-brainstorm.md`.
- **v9.0.0 = H Agent I/O Contracts** (NEW, allocated 2026-04-28) — formalize agent input/output contracts as `## Inputs` + `## Outputs` markdown sections. Forge brief at `docs/superpowers/specs/2026-04-28-H-agent-io-contracts-brief.md`. Backward-compat doc work, but per CLAUDE.md versioning policy: extracting implicit prose into explicit kontrakts may count as MAJOR if it changes agent output format kontrakt — TBD via forge phase 1 research.
- **v9.1.0 = Plugin Cleanup** (NEW 2026-04-30) — workflow-router deletion + jq dep removal. Combines previously-planned v9.0.3 jq cleanup with newly-discovered workflow-router structural redundancy (each skill self-describes via `description`; router's destructive branch always-broken since `disable-model-invocation` flags). MINOR. See BACKLOG entry for full scope.
- **v9.2.0 = Plugin Cleanup 2** — check-deploy deletion (27 skills) + replacement v9-overlay coverage + bash-only `make_state_json_bash`. MINOR. (Renumbered 2026-05-02.)
- **v9.3.0 = Skills refactoring** — **SHIPPED 2026-05-04** — merge fix-ticket+fix-bugs do `/fix-bugs` (tracker-type-aware dispatch + `--batch` flag); scaffold-add do `/scaffold add` subcommand; drop resume-ticket (resume detection inlined do 3 entry-points přes nové `core/resume-detection.md`, 17. core kontrakt); analyze-bug zachován jako read-only triage tool. Plus 3 advisory fixy z v9.2.0 backlogu. Forge run `forge-2026-05-03-001` FULL_PASS 0.93. 22 skills.
- **v9.4.0 = Switch to oficiální `gitea/gitea-mcp`** — přepnutí z `goern/forgejo-mcp` (community Forgejo fork z 2026-02-25 brainstorm rozhodnutí) na oficiální `gitea/gitea-mcp`. Phase 1 parity research → decision gate (Path A/B/C). **Bez explicitní backward-compat** — pokud tool names match, forgejo dál funguje náhodou; pokud se liší, hard switch bez dual-dispatch kódu (cost-cap ~5 řádků compat). Automation Config kontrakt nezasažen. MINOR. (Added 2026-05-05.)
- **v9.5.0 = Backward-Compat Cleanup + skills pruning** — smaže pre-v9 state.json fallbacky (`core/state-manager.md:150-217`), v7→v8 alias mappingy (`core/aliases/agents-rename-aliases.md`, `.md` overlay fallback), `/migrate-config` skill, `/estimate` skill (stale 2025-03 pricing tabulka, ±50% heuristic, zero usage signal — v6.9.0 měřené tokens v pipeline.json post-run jsou autoritativní, ex-ante odhad nepřinesl hodnotu), `/pipeline-status` skill (single-session attended workflow vidí pipeline output přímo v Claude okně; cross-issue overview je hypotetický use case bez usage signalu — tracker UI + `cat .ceos-agents/*/state.json` + `git status` pokrývají "walked away" edge case bez separátního skillu), `/scaffold-validate` skill (CLAUDE.md sections check duplikuje `/check-setup` Block 1; build+test execution duplikuje `/check-setup` Block 3 s `--skip-build`; scaffold pipeline má vlastní internal validate phase v `skills/scaffold/SKILL.md:287` + `:360`; **Docker dry-build check relocates do `/check-setup`** jako nový check ~10 řádků — konzistentní s existující Local Deployment validation; lint detection se nepřesouvá — není v Automation Config kontraktu), Redmine legacy `status:{name}` detekci, ~6 test scénářů. ~663 řádků net (live measured 2026-05-07). 22→**18 skills**. **KEEP `/publish`** (manual workflow + PR-only mode = legit standalone use, decision 2026-05-07, defer revisit do v10.2.0+). MINOR (lokální-only plugin = žádný external break). (Added 2026-05-04, renumbered from v9.4.0 → v9.5.0 2026-05-05; `/estimate` added 2026-05-07; `/pipeline-status` + `/scaffold-validate` added 2026-05-07 — všechny čtyři delete kandidáti sdílí stejný rationale: nízký/nulový usage signal + duplicitní funkce dostupná jinde, až přijde public release a někdo si řekne, dá se napsat čistě nanovo.)
- **v9.6.0 = MCP Server Audit + Vendor-Official Migration** — audit 7 MCP server šablon; 5 vendor-official endpoint replacements (github, jira-Cloud, linear, youtrack-Cloud, redmine uvx); 2 config fixes (codegraph type, gitea asset names); 1 nová doc stránka (`mcp-server-versions.md`); 90-day quarterly audit cadence commitment; Atlassian hard deadline 2026-06-30. 0 broken templates remaining (bylo 4 hard 404). MINOR. Forge-driven. (forge-2026-05-08-001 replanning cycle 1 — 2026-05-09.)
- **v9.7.0 = GitHub pre-release cleanup** (cleanup-only po split 2026-05-05; renumbered z v9.6.0 2026-05-09) — repo hygiene: relocate roadmap.md jako Step 1 → hard delete `.forge.bak-*/` (53 dirs / 32 MB / 2415 souborů — live count 2026-05-07), `docs/plans/` (100 souborů live, 99 po roadmap relocate), `docs/superpowers/specs/` (9 souborů / 340 KB), `skills/version-bump/`, root smetí. `tests/`, `checklists/`, `state/` KEEP (runtime grep evidence). Community research 2026-05-04: 4 surveyed plugin repa neshipou tests/, docs/plans/, ani internal ADRs. ~35 MB / ~2530+ souborů odstraněno (70 MB → ~35 MB repo). 18→**17 skills** (post-v9.5.0 baseline 18 = 22 minus /migrate-config + /estimate + /pipeline-status + /scaffold-validate). Demo projekt přesunut do separátního `ceos-agents-demo` repa jako v0.1.0 (separate release cycle, ne plugin scope).
- **v9.8.0 = G** (canonical URL, SECURITY contact, README rewrite, public announcement; renumbered z v9.7.0 2026-05-09). Hosting deploy ceos-agents-web řeší samotný web repo; plugin scope = jen polish + URL fix napříč repos. **Pure polish, žádný runtime refactor** — input-layer changes jsou v v9.9.0. MINOR. (Renumbered from v9.5.0 → v9.6.0 → v9.7.0 2026-05-05 → v9.8.0 2026-05-09; per-skill validation moved to v9.9.0 2026-05-05.)
- **v9.9.0 = Direct Mode + per-skill prerequisites** (renumbered z v9.8.0 2026-05-09) — text input + no-PR + virtual issue abstrakce + per-skill lazy validation (gh CLI pattern). Strategic product expansion sloučená s validation refactorem (oba sahají do stejného input-layer kódu — Step 1 dispatch + `/check-setup` rewrite, takže jeden coherent refactor). Tracker-only design je historický artefakt z BIFITO/drmax kontextu (oba korporáti). Aider/Copilot Workspace precedent (Copilot Workspace měl identickou evolution arc: issue → PR start, prompt input added later). Audience 5-10× expansion. Strict mode pro korporáty triviálně enforceable přes 3-řádkovou config sekci. MINOR (backward-compat: defaults match existing behavior). Forge-driven. (Added 2026-05-05; per-skill scope merged 2026-05-05.)
- ~~**v10.0.0 (proposed) = Node.js Runtime + interaktivní F**~~ — **DROPPED 2026-05-02.** Plugin zůstává čistě markdown (zero deps invariant). Interaktivní dashboard / "klik=spusť pipeline" funkčnost je v scope ceos-agents-web (samostatný repo); plugin samotný neporodí Node.js runtime. **2026-05-11 update:** v10.0.0 slot reallocated to Orchestration Reliability ENRICHED HYBRID MAJOR (markdown + 1 Bash script, žádný Node.js — invariant zachován). Žádné post-v10.4.0 plánované MAJOR releases na plugin track.

**Pořadí implementace plugin scope:** v9.0.0 (H Agent I/O Contracts forge) → v9.0.2 (overlay TOML hotfix, SHIPPED 2026-04-30) → v9.1.0 (Plugin Cleanup: router deletion + jq dep removal, MINOR, SHIPPED 2026-05-01) → v9.2.0 (Plugin Cleanup 2: check-deploy deletion + v9-overlay coverage + bash helper) → v9.3.0 (Skills refactoring: fix+scaffold merge) → v9.4.0 (Switch to oficiální gitea/gitea-mcp) → v9.5.0 (Backward-Compat Cleanup + skills pruning: pre-v9 fallbacky + alias mappingy + /migrate-config + /estimate + /pipeline-status + /scaffold-validate delete) → v9.6.0 (MCP Server Audit + Vendor-Official Migration: 5 endpoint replacements + quarterly audit cadence) → v9.6.1 (Implicit self-assign PATCH, SHIPPED 2026-05-11) → **v10.0.0 (Orchestration Reliability ENRICHED HYBRID forge: thin-controller rewrite + dispatch_witness runtime invariant + mandatory `## Step Completion Invariants` agent contract section, MAJOR per CLAUDE.md L243)** → v10.1.0 (v10.0.0 Carry-Forward Polish: 7 Phase 8 reviewer findings, ~150 lines focused polish forge) → v10.1.1 (check_dispatch_witness grep -A window hotfix, PATCH) → v10.1.2 (polish sweep, PATCH) → v10.2.0 (`core/` path disambiguation in skill SKILL.md files, fixes tichá-degradace pozorovaná u BIFITO-4293) → v10.3.0 (GitHub pre-release cleanup) → v10.4.0 (G pure polish, polish-heavy = forge overkill) → v10.5.0 (Direct Mode forge: text input + no-PR + virtual issue + per-skill prerequisites, strategic audience expansion). Po v10.5.0 plugin zůstává markdown-only — žádný Node.js runtime plán. Sub-projekt E + F (původní v9.0.0 + v9.1.0 plánu) jsou nyní externí na ceos-agents-web roadmapě jako v0.1.0 + v0.2.0; dashboard/interaktivita pokračují tam.

**Stack volby v brainstormech (Astro+Tailwind+Vite pro E, Preact+plain CSS+uPlot pro F) jsou NON-BINDING** — direction signal pro forge phase 1 research, ne hard contract. Forge ověří na evidence + sdílená infrastruktura E/F (file-import.ts).

**Per-sub-project flow:** každý A-H dostane vlastní `docs/superpowers/specs/YYYY-MM-DD-<sub>-design.md` (nebo brief pro forge) přes brainstorming s uživatelem (rozhodnutí strategická, ne delegovaná na forge). Exekuce pak:
- **build-heavy (H Agent I/O Contracts v9.0.0, demo v9.2.0)** → forge se specem jako vstupem (research → spec → TDD → plan → execute → verify). E + F build-heavy items proběhly mimo plugin scope — viz ceos-agents-web `.forge/` (E v0.1.0 hotovo). v9.1.0 Plugin Cleanup je deletion-heavy = direct edits, ne forge.
- **decision/cleanup-heavy (C, G)** → přímo writing-plans → executing-plans (forge by byl overkill)
- **A, B** → exekuce přes forge (HOTOVO 2026-04-27 v8.0.0 forge run)
- **D** → ABSORBED do A.1 jako `/setup-agents` skill (žádný samostatný flow)
- **H Agent I/O Contracts** (NEW 2026-04-28) → research-heavy + cross-doc; forge je vhodný (market scan + best-practice review + decision + implementation per agent + tests). Brief: `docs/superpowers/specs/2026-04-28-H-agent-io-contracts-brief.md`.

**Final v7.0.0 scope (rozhodnuto 2026-04-25, ready to plan):**

| # | Akce | Breaking? |
|---|---|---|
| 1 | Smazat `Extra labels` config sekci (duplikuje `PR Rules → Labels`) | Ano |
| 2 | Opravit doc `Pause Limits` mapping (applies to 6 skills, not just `/autopilot`) | Ne (doc fix) |
| 3 | Rename `/ceos-agents:status` → `/ceos-agents:pipeline-status` (kolize s Claude Code builtin `/status`) | Ano |
| 4 | Rename `/ceos-agents:init` → `/ceos-agents:setup-mcp` (kolize s Claude Code builtin `/init`) | Ano |
| 5 | Auto-detect tracker v `/publish` + smazat `/create-pr` skill (issue ID nalezen → tracker update + PR; nenalezen → jen PR; tracker down → fail) | Ano |
| 6 | README + docs varování o kolizích krátkých slash forem s Claude Code builtins | Ne |

**Counts po v7.0.0:** 29 → **28 skills** (−`/create-pr`), 19 → **18 config sekcí** (−`Extra labels`), 21 → **21 agentů** (no change). Renamy nesnižují count.

**Zahozeno z původního auditu (2026-04-25):** 4-reviewer audit (`docs/superpowers/specs/2026-04-25-config-skills-agents-audit.md`) byl jako rozhodovací nástroj špatná volba — reviewers neměli kontext "nedávno dodané feature čekající na adoption" a označili strategické features (dashboard, discuss, sprint-plan, prioritize, create-backlog) jako DELETE. Po per-feature ověření v repu reálný actionable cleanup vyšel jen 4 položky výše. Audit dokument zůstává jako reference.

**Related VISION items:** "Node.js Runtime" — DROPPED z plugin scope 2026-05-02; dashboard/runtime pokračuje na ceos-agents-web tracku (separate repo). ASYSTA (G vyžaduje stabilní API, pokud ASYSTA bude orchestrovat ceos jako graph node).

### Cross-Plugin Bridge (filip-superpowers ↔ ceos-agents)
**Source:** forge pipeline Phase A discussion (2026-03-23), deep exploration session (2026-03-31)

**Core problem:** scaffold produces shallow output (basic skeleton). forge produces expert-quality output but lacks infrastructure (tracker, SC, git, CI, tracker cards). User wants forge-quality thinking + scaffold infrastructure in one workflow without duplication.

**Validated (2026-03-31):**
- Cross-plugin `Skill()` calls work — confirmed empirically
- Cross-plugin `Agent()` dispatch works — Claude sees agents from both plugins
- forge Phase 7 code review is stronger than initially assessed (Code Constitution + code-quality-reviewer + Phase 8 panel)
- Scaffold `--spec` flag already exists — partial bridge capability in place

**Leading options (no winner — each has a real trade-off):**

| Option | Entry point | Approach | Trade-off |
|--------|------------|----------|-----------|
| scaffold `--deep` flag | scaffold | Calls forge skills for thinking phases (0b, 1, 5) | Couples plugins via Skill() calls; spec format mismatch |
| forge `--scaffold` mode | forge | Dispatches ceos agents (scaffolder, fixer, reviewer) at Phase 7 | ceos agents need Automation Config; no tracker entry point |
| Sequential workflow | user | `/forge` then `/scaffold --spec --no-implement` | Loses forge Phase 8 verify; friction (2-3 commands) |
| ASYSTA orchestration | ASYSTA | Both plugins stay independent; ASYSTA chains them as graph | Not built yet; defers the problem |

**Unresolved blockers:**
- Spec format mismatch: forge EARS (REQ-NNN, formal-criteria.md) vs scaffold epics/*.md
- Entry point question: scaffold has tracker; forge has deep thinking — both valid
- ASYSTA may make plugin-level integration unnecessary if it becomes the orchestration layer

**Analysis artifacts:** `docs/plans/cross-plugin-bridge-summary.md` (full exploration),
`docs/plans/cross-plugin-bridge-value-analysis.md`, `docs/plans/cross-plugin-bridge-alternatives-REVIEW.md`,
`.forge/phase-3-brainstorm/` (3-agent brainstorm + judge synthesis + devil's advocate review)

### ~~Config Wizard — Local-Server Backend~~ (MOVED 2026-04-28 to ceos-agents-web)
The web-runtime variant of this idea — local HTTP server inside the wizard, file-system write-back, meta-agent scan — is now tracked in `ceos-agents-web` `docs/roadmap.md` (canonical URL TBD via v10.4.0 G). The plugin-side hook (a new `/ceos-agents:setup-config` skill that spawns the local server) remains a plugin concern and stays on this roadmap as a follow-up once the web side ships.

---

### Cross-Plugin Dogfooding
**Source:** v5.6.0 development session (2026-03-29)

Use ceos-agents to develop filip-superpowers (fix-bugs, implement-feature) and forge to develop ceos-agents. Mutual validation loop — both plugins tested against real usage.

**Prerequisites:** filip-superpowers needs `## Automation Config` in CLAUDE.md, Gitea issues, MCP server configured.

**Assessment:** Not overkill — best E2E test for both plugins. Validates full pipeline against real codebase.

### Tracker for Roadmap Items
**Source:** v5.6.0 roadmap review (2026-03-29)

Move roadmap items to Gitea issues with labels. Roadmap.md becomes lightweight overview linking to issues. Enables lifecycle management, comments, assignment.

**Assessment:** Simple to set up. Could partially leverage ceos-agents itself (reads from tracker, creates PRs). Start with PLANNED items only.

### Scaffold Design Quality — Phase B (Stack-selector + flags)
**Source:** scaffold pipeline feedback (2026-04-02), forge research (2026-04-03)

**Phase A (v6.1.7) DONE:** Scaffolder Batch 6 "Design" + spec-writer "Design & UX" subsection. Tailwind CSS for JS stacks, classless CSS for server-rendered. Conditional on web project detection.

**Phase B (future MINOR):**
- Add `project_type: web | api | cli | library` to stack-selector output
- Add `--web` / `--api` / `--cli` flags to scaffold command
- Add DaisyUI as optional theme enhancement (Agent Override example)
- Consider: dedicated design config section in Automation Config

**Assessment:** Phase A covers 80% of the value. Phase B adds formal project type signal and explicit user control.

### scaffold --extend
**Source:** forge pipeline analysis (2026-03-26)
Add new features to an existing scaffolded project (`/scaffold --extend "add auth module"`).
Needs design: how to diff existing scaffold spec vs extension request, which agents re-run.

### Batch Feature Implementation
**Source:** forge pipeline analysis (2026-03-26)
Implement a list of features in sequence from a single command invocation.
Builds on worktrees support. Needs design for inter-feature dependency ordering.

### PR Review Feedback Loop
**Source:** design review 2026-05-07

**Problem:** Pipeline aktuálně zpracovává zpětnou vazbu ze dvou zdrojů:
- **Tracker issue** (komentáře, popis, zadání) — funguje. Při re-runu pipeline tyto informace přečte a zahrne do kontextu.
- **PR review komentáře** (developer okomentuje PR na Gitea/GitHub) — **nefunguje.** Jakmile PUBLISHER vytvoří PR, pipeline je z pohledu ceos-agents "hotová". Pokud developer přidá review komentáře na PR ("toto je špatně, oprav X"), pipeline o tom neví. Uživatel nemá způsob jak tyto komentáře dostat do opravné iterace bez manuálního kopírování.

**Aktuální workaround:** Uživatel musí manuálně zkopírovat obsah PR review komentářů do tracker issue a pak pustit pipeline znovu.

**UX flow (Option A — re-run same command):**
```
1. Developer přidá review komentáře na PR (Gitea/GitHub)
2. Uživatel spustí: /ceos-agents:fix-bugs ISSUE-123  (stejný příkaz jako poprvé)
3. resume-detection vidí: state.json má pr_url, PR je stále open
   → dotáže se MCP na review komentáře PR
   → pokud existují unresolved komentáře → vstoupí do "PR review mode"
   → pokud žádné komentáře nejsou → standardní resume (dosavadní chování)
4. Fixer dostane jako kontext: původní triage + review komentáře z PR
5. Fixer pushne nové commity na existující branch (ne nový PR)
6. Reviewer zkontroluje že každý review komentář byl adresován
7. Pipeline postne na tracker issue: "[ceos-agents] PR review addressed. {N} comments resolved."
```

**Co by řešení znamenalo:**
- Rozšíření `core/resume-detection.md` o stav `pr_open_with_reviews` (PR open + unresolved review komentáře)
- Nová větev v `skills/fix-bugs/SKILL.md` pro PR review mode (čtení komentářů přes MCP, fixer s review kontextem, push na existující branch)
- Reviewer krok: per-comment adresování místo standardního AC check

**Závislosti:** MCP server musí podporovat čtení PR review komentářů (Gitea MCP: `list_issue_comments` na PR čísle; GitHub MCP: `get_pull_request_reviews` + `get_pull_request_review_comments`).

**Assessment:** Reálný use case — developer review je standardní součást workflow. Gap způsobuje friction: buď uživatel manuálně kopíruje feedback, nebo nechá PR viset bez opravy. Středně složitá implementace — primárně rozšíření resume-detection o stav `pr_open_with_reviews` a nová větev v fix-bugs.

### Output Contract Runtime Enforcement
**Source:** forge-research 2026-05-07 (LLM output validation research)

Aktuálně jsou Output Contract sekce (v9.0.0) jen dokumentace v promptu agenta — žádné runtime vynucení. Porušení kontraktu způsobuje tiché selhání downstream (špatná data v state.json).

**Research findings (forge-research 2026-05-07):**
- Správný hook pro inspekci agent outputu je `SubagentStop` (má `last_assistant_message`), ne PostToolUse — ale ani ten neumí injektovat opravný kontext zpět (GH #3983, closed-as-not-planned)
- Komunita konvergovala na Pydantic+retry pro JSON output; pro markdown-sekce neexistuje žádný etablovaný nástroj
- Baseline compliance Sonnet/Opus s explicitním promptem: ~85-98% per-invocation; s 1 retry: ~99.6%
- `pipeline.log` ukládá jen lifecycle eventy — plný text agenta na disk se neukládá nikde

**Doporučené přístupy (seřazeny):**
1. **D — Inline sentinel expansion** (nejlepší fit): přidat section-presence check do `core/fixer-reviewer-loop.md` + dalších core kontraktů ihned po Task callu. Zero infra, pure-markdown, deterministické. Pokryje chybějící sekce (`## Fix Report` absent). Nezachytí field-level porušení.
2. **A — SubagentStop hook** (opt-in per project): shell skript provisioned by `/setup-agents`, čte `last_assistant_message`, hard-abort na chybějící sekce. Vyžaduje setup krok v consuming projektu.
3. **E — state.json post-validation**: validace extrahovaných polí (severity enum, complexity enum) po zápisu do state.json. Nezachytí chybějící sekce.

**Trigger pro implementaci:** reálné pipeline failure způsobené špatně strukturovaným outputem agenta — zatím teoretický problém.

**Assessment:** Nízká priorita dokud se problém neprojeví v praxi. Approach D je triviální (3 řádky per core contract) a může být přidán jako součást příštího MINOR releasu pokud se objeví motivující bug.

---

## VISION

These are directions where the project could evolve. None have concrete plans yet —
they represent the ceiling of what's possible, not commitments.

| Item | What it enables | Assessment |
|------|----------------|------------|
| **Node.js Runtime** | CI/CD integration, scheduled runs, API server, batch processing, web dashboard, "klik=spusť pipeline" varianta F | **DROPPED 2026-05-02 z plugin scope.** Plugin zůstává čistě markdown. Dashboard + runtime pokračuje na `ceos-agents-web` tracku (separate repo). |
| **Standalone CLI Tool** | `npx ceos-agents fix-ticket ISSUE-123` without Claude Code | Stepping stone to runtime. md→API translator. |
| **Multi-IDE Support** | Cursor, Windsurf, Kiro via converter tool | Conflicts with pure-markdown philosophy. Start with Cursor. |
| **Module / Plugin Ecosystem** | Third-party agent+command bundles, registry | Premature without external users. Agent Overrides is step 1. |
| **Performance Regression Testing** | Benchmarks before/after fix, detect regressions | Start as custom agent example. |
| **Dependency Vulnerability Scanning** | npm audit / pip-audit / trivy as pipeline stage | Start as custom agent example. |
| **Natural Language Config** | Describe config in plain text, agent generates tables | /onboard already does basic version. |
| **Monorepo Support** | Per-package configs, selective test running | Needs `Monorepo` config section + cross-package analysis. |
| **Automated Changelog** | Rich changelogs from pipeline execution data | Beyond current `/changelog` (merged PRs only). |

---

## NOT PLANNED

| Item | Reason |
|------|--------|
| **Context Management / Context Budget** (review D1) | Architecture already provides isolation via Task tool dispatch — agents get curated context, not accumulated history. Report misunderstood the architecture. (2026-04-08) |
| **Structured JSON Agent Output** (review D3) | Anti-pattern for LLM consumers. Current markdown-with-signal-tokens approach works. JSON schema would be MAJOR breaking change without added value. (2026-04-08) |
| **Reviewer Instruction Differentiation** (review D4) | Factually incorrect claim. Reviewer is explicitly adversarial with security checklist; fixer is pragmatic/surgical. Structural asymmetry exists by design. (2026-04-08) |
| **Hard Cost Ceiling** (review D6) | Requires runtime the plugin doesn't have. Cannot count tokens in a markdown plugin. Existing retry limits cover practical cases. See Real-Time Cost Visibility in v6.8.0 for informational alternative. (2026-04-08) |
| **Context Summarization Agent** (review D9) | Architecturally unnecessary — Task tool dispatch already isolates context. Summarizer would add latency/cost with no benefit. (2026-04-08) |
| **Multi-Reviewer Pattern** (review D11) | Existing mechanisms suffice: adversarial reviewer + Agent Overrides + custom Post-fix agent. Dual opus would double costs without proportional value. (2026-04-08) |
| **Flaky Test Detection** (review D7) | Pipeline should not compensate for bad test suites. Flaky tests are a project quality problem — projects should fix them, not mask them with retries. Most test frameworks have native retry mechanisms. (2026-04-15) |
| **Named agent personas** (Mary, Winston) | Conflicts with functional architecture. `style` field is sufficient for differentiation without theatrics. |
| **GUI / web dashboard** | Plugin is CLI-first. `/dashboard` generates static HTML which is sufficient. |
| **Marketplace listing** | Deferred — no external users yet. |
| **Runtime in this repo** | Separate project with own lifecycle. |
| **Real-time multi-user collaboration** | Both ceos-agents and BMAD are single-session tools. Real-time collaboration would require a fundamentally different architecture. |
| **Onboard Wizard Polish** | No concrete feedback driving it. `--dry-run` for a one-time-per-project wizard is pointless. Placeholder without scope. |
| **version-bump Enhancements** | Auto-detect bump type and `--push` flag save one decision and one command. Micro-optimizations with no real value. |
| **Documentation Overhaul** | All 4 phases completed incrementally across v3.x–v5.x: CZ→EN translation, Diataxis restructure, new docs, README with Mermaid. Nothing left to do. |
| **Step-File Architecture** | Subsumed by Commands-to-Skills Migration (DONE v6.0.0). Skill directories natively support splitting long files into SKILL.md + reference files. |
| **Fixer Agent Rename** | High cost (MAJOR bump, 15+ test scenarios, 4 skills, 3 core contracts), questionable benefit. Name is well-established, description update in v6.7.0 clarifies broader role. Nobody asked "why is it called fixer?" (2026-04-16) |

---

## Historical Roadmaps

Previous roadmap documents (now superseded):
- `2026-02-25-future-roadmap.md` — v2.0-era roadmap
- `2026-02-28-v3.1-v5.0-roadmap-design.md` — v3.1-v5.0 roadmap
- `bmad-comparison-analysis.md` — full competitive analysis vs BMAD-METHOD
- `bmad-adoption-plan.md` — detailed implementation plan for adopted items
