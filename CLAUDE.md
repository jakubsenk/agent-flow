# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

A Claude Code plugin (`ceos-agents`) that automates bug-fix workflows, feature implementation, and project scaffolding. It provides specialized agents that are orchestrated by commands to take an issue from triage through fix, review, test, and publish — or to scaffold a new project from scratch. The plugin is generic — all project-specific configuration lives in the consuming project's CLAUDE.md under `## Automation Config`.

**Author:** Filip Sabacky
**Installation:** `claude plugin marketplace add <path-to-repo>`, then `claude plugin install ceos-agents@ceos-agents`

## Repository Structure

No build system, no dependencies. Manual test suite in `tests/`. This is a pure plugin of markdown definitions.

- `.claude-plugin/` — Plugin metadata (`plugin.json`, `marketplace.json`)
- `agents/` — 17 agent definitions (markdown with YAML frontmatter)
- `skills/` — 18 skills (slash commands)
- `docs/plans/` — Architecture decision records
- `docs/guides/` — Installation and configuration guides
- `docs/reference/` — Command, agent, pipeline, and config reference
- `examples/` — Config templates, custom agent examples, MCP config examples
- `checklists/` — Pipeline phase checklists (review, test, publish)
- `tests/` — Test harness with scenarios and CI workflow
- `.ceos-agents/` — Per-run pipeline state files (state.json, pipeline.log, browser artifacts)
- `state/` — State schema documentation
- `core/` — 17 shared pipeline pattern contracts

## Architecture: 2-Layer System

**Skills** (orchestration — WHAT to do): `/analyze-bug`, `/autopilot`, `/changelog`, `/check-setup`, `/create-backlog`, `/discuss`, `/fix-bugs`, `/implement-feature`, `/metrics`, `/onboard`, `/prioritize`, `/publish`, `/scaffold`, `/setup-agents`, `/setup-mcp`, `/sprint-plan`, `/version-bump`, `/version-check`
**Agents** (specialists — HOW to do it): acceptance-gate, analyst, architect, backlog-creator, browser-agent, deployment-verifier, fixer, priority-engine, publisher, reviewer, rollback-agent, scaffolder, spec-analyst, spec-reviewer, spec-writer, sprint-planner, test-engineer

Skills read `## Automation Config` from the project's CLAUDE.md and dispatch agents. Skills contain zero project-specific logic.

## Bug-Fix Pipeline

```
Issue tracker query → ANALYST --phase triage (sonnet, +AC extraction, +complexity, +reproduction_steps)
  → ANALYST --phase impact (sonnet) → [BROWSER-AGENT --phase reproduce (sonnet, optional)] → [Pre-fix hook]
  → FIXER ↔ REVIEWER (opus, +AC fulfillment check)
  → [Post-fix hook + custom agent] → [Smoke check (build + test)] → TEST-ENGINEER (sonnet)
  → [TEST-ENGINEER --e2e (sonnet, optional)] → [BROWSER-AGENT --phase verify (sonnet, optional)] → [Acceptance gate (conditional: AC ≥ 3 or complexity ≥ M)]
  → [Pre-publish hook + custom agent] → PUBLISHER (haiku)
```

Retry limits are configurable via `Retry Limits` section in Automation Config (defaults: 5 fixer iterations, 3 test attempts, 3 build retries, 5 spec iterations, 3 root cause iterations).

Each agent can **Block** the issue (set state, add comment using Block Comment Template, move on). On block from fixer/reviewer/test-engineer: **rollback-agent** reverts git state. Hooks and custom agents can be inserted at 4 points (see `skills/fix-bugs/SKILL.md` for full pipeline).

## Feature Pipeline

```
Issue tracker query → SPEC-ANALYST (sonnet, +AC writeback)
  → ARCHITECT (opus, +maps_to traceability)
  → [AC coverage check] → [Decomposition decision] → [Create tracker subtasks]
  → FIXER ↔ REVIEWER (opus, +AC fulfillment check)
  → [Smoke check (build + test)] → TEST-ENGINEER (sonnet) → [Acceptance gate (always in decomposition, skipped in single-pass)]
  → PUBLISHER (haiku)
```

## Scaffold Pipeline

```
[0-INFRA: infra declaration] → [0-MCP: MCP check]
  → User description → SPEC-WRITER ↔ SPEC-REVIEWER (opus)
  → [Spec checkpoint] → SCAFFOLDER (sonnet, +test infrastructure, +scorecard)
  → Validate → Git init → [4d: push] → [4e: tracker issues]
  → ARCHITECT (opus, +maps_to) → [Feature plan checkpoint]
  → FIXER ↔ REVIEWER (opus) → TEST-ENGINEER (sonnet)
  → [Spec compliance check (spec-reviewer --verify)]
  → TEST-ENGINEER --e2e (sonnet) → Final report
```

Pipeline mode is selected via a flag at invocation time:
- **default** — human-in-the-loop with review checkpoints after each major phase
- **`--yolo`** — automated run, all checkpoints skipped, pipeline runs to completion without pausing
- **`--step-mode`** — pause before every individual agent step for fine-grained control

With `--no-implement`: `[0-INFRA] → [0-MCP] → STACK-SELECTOR (sonnet) → SCAFFOLDER (sonnet) → Validate → Git init → [push if SC ready]` (v3.x behavior).

In scaffold v2 mode, the specification is saved as a `spec/` folder in the project root (spec/README.md, spec/architecture.md, spec/verification.md, spec/epics/*.md). This folder is the single source of truth for all downstream agents.

## Agent Definition Format

Every agent file in `agents/` follows this exact structure:

```markdown
---
name: agent-name
description: One-line description used by Claude Code's Task tool
model: sonnet | opus | haiku
style: Short communication style descriptor
---

You are a [Role] specializing in [domain].

## Goal
## Expertise
## Process (numbered steps)
## Output Contract (v9.0.0+, mandatory — structured output schema agents return)
## Step Completion Invariants (v10.0.0+, mandatory — fields the orchestrator MUST verify in state.json before considering the stage complete: `dispatched_at` non-null ISO 8601, `dispatch_witness` non-null 64-hex sha256, `tool_uses` ≥ 1, `status="completed"`. Failure → orchestrator returns BLOCKED with reason `completion_invariant_violated:<missing-field>`. Witness verified via `core/lib/stage-invariant.sh::check_dispatch_witness`.)
## Constraints (NEVER rules, limits, failure handling)
```

> **v10.0.0 reliability contract:** `## Step Completion Invariants` is a mandatory structured section in every `agents/*.md`. Custom agents that lack it will fail the harness scenario `tests/scenarios/v10-step-completion-invariants-completeness.sh`. See `core/lib/stage-invariant.sh` for the runtime helper functions (`compute_dispatch_witness`, `check_dispatch_witness`, `emit_witness_audit`).

### Model Selection

| Model | Used For | Agents |
|-------|----------|--------|
| opus | Critical code changes, quality review, architecture, specification, prioritization | fixer, reviewer, architect, priority-engine, spec-writer, spec-reviewer |
| sonnet | Analysis, testing, triage, specification, scaffolding, AC verification, deployment, backlog creation, sprint planning | analyst, test-engineer (incl. `--e2e` flag), spec-analyst, scaffolder, acceptance-gate, browser-agent, deployment-verifier, backlog-creator, sprint-planner |
| haiku | Mechanical/template tasks | publisher, rollback-agent |

### Key Conventions Across All Agents

- Read-only agents (analyst, reviewer, spec-analyst, architect, priority-engine, spec-reviewer, acceptance-gate, backlog-creator, sprint-planner) NEVER modify code
- Execution agents (fixer, test-engineer, publisher, scaffolder, spec-writer, browser-agent, deployment-verifier) make changes
- Max retry limits: 3 for builds/test fixes, 5 for fixer↔reviewer iterations, 5 for spec iterations
- Failure strategy: Block the issue with a comment explaining why, then move on
- Fixer diffs should be ≤100 lines; analyst (--phase impact) reports ≤5 affected files
- Publisher never pushes to main/dev directly — always creates a PR
- PR descriptions always in English; use template from Automation Config
- analyst (--phase triage) output includes: acceptance criteria (2-5 items), complexity estimate (XS/S/M/L)
- Reviewer output includes: AC Fulfillment section (per-AC verdict: FULFILLED/PARTIALLY/NOT ADDRESSED) when AC are provided
- Acceptance-gate agent verifies AC fulfillment with code + test evidence (read-only, sonnet)
- Architect task tree includes: `maps_to` field linking subtasks to parent acceptance criteria (format: `AC-{N}: {text}`)
- Spec-analyst posts acceptance criteria as a separate comment to the issue tracker
- Spec-reviewer has a `--verify` mode for checking implementation against spec
- Fixer can signal NEEDS_DECOMPOSITION when scope exceeds limits (max 1 per ticket)

## Automation Config

Projects using this plugin must have `## Automation Config` in their CLAUDE.md with **18 optional config sections in total** (plus the required sections). All sections use table format (`| Key | Value |`); no bullet-point lists.

**Required sections** (must be present in every consumer CLAUDE.md):

| Section | Keys |
|---------|------|
| Issue Tracker | Type (youtrack/github/jira/linear/gitea/redmine, default: youtrack), Instance, Project, Bug query, State transitions, On start set |
| Source Control | Remote (owner/repo), Base branch, Branch naming |
| PR Rules | Labels |
| PR Description Template | Multi-line template (separate subsection) |
| Build & Test | Build command, Test command, Verify command (optional — runs after PR merge). Verify command runs after PR merge. If it fails, the issue is re-opened. |

**Optional sections table:**

| Section | Keys | Default |
|---------|------|---------|
| Retry Limits | Fixer iterations, Test attempts, Build retries, Spec iterations, Root cause iterations | 5, 3, 3, 5, 3 |
| Module Docs | Path | (none) |
| Hooks | Pre-fix, Post-fix, Pre-publish, Post-publish | (none) |
| Custom Agents | Post-fix agent, Pre-publish agent | (none) |
| Notifications | Webhook URL, On events (`pr-created`, `issue-blocked`, `pipeline-started`, `step-completed`, `pipeline-completed`) | (none) |
| Worktrees | Batch size, Base path, Cleanup | (none) |
| E2E Test | Framework, Command | (none) |
| Browser Verification | Base URL, Start command, On events, Timeout, Max pages, Screenshot storage, Exploration, Exploration max clicks | (none) |
| Error Handling | On block, Max blocked per run | comment, unlimited |
| Feature Workflow | Feature query, On start set | (none) |
| Decomposition | Max subtasks, Fail strategy, Commit strategy, Create tracker subtasks | 7, fail-fast, squash, enabled |
| Pipeline Profiles | Profile, Skip stages, Extra stages | (none) |
| Metrics | Output, Period | stdout, 30 days |
| Agent Overrides | Path | customization/ |
| Local Deployment | Type, Start command, Stop command, Health check URL, Health check timeout, Ports | (none) |
| Sprint Planning | Sprint duration, Capacity unit, Team capacity, Velocity target, Sprint field, Mode, Max issues, Epic template | 2 weeks, story-points, (none), (none), (tracker-dependent), suggest, 20, (none) |
| Autopilot | Max issues per run, Lock timeout, Log file, Bug limit, Feature limit, On error, Dry run | 1, 120, .ceos-agents/autopilot.log, 0, 0, skip, false |
| Pause Limits | Pause timeout | 30 days |

---

The 18 H3 sub-sections below are the **canonical Automation Config sections**:

### Retry Limits

Optional. Keys + defaults: Fixer iterations (5), Test attempts (3), Build retries (3), Spec iterations (5), Root cause iterations (3).

### Module Docs

Optional. Keys: Path. Default (none).

### Hooks

Optional. Keys: Pre-fix, Post-fix, Pre-publish, Post-publish. Default (none).

### Custom Agents

Optional. Keys: Post-fix agent, Pre-publish agent. Default (none).

### Notifications

Optional. Keys: Webhook URL, On events (`pr-created`, `issue-blocked`, `pipeline-started`, `step-completed`, `pipeline-completed`). Default (none).

### Worktrees

Optional. Keys: Batch size, Base path, Cleanup. Default (none).

### E2E Test

Optional. Keys: Framework, Command. Default (none).

### Browser Verification

Optional. Keys: Base URL, Start command, On events, Timeout, Max pages, Screenshot storage, Exploration, Exploration max clicks. Default (none).

### Error Handling

Optional. Keys + defaults: On block (comment), Max blocked per run (unlimited).

### Feature Workflow

Optional. Keys: Feature query, On start set. Default (none).

### Decomposition

Optional. Keys + defaults: Max subtasks (7), Fail strategy (fail-fast), Commit strategy (squash), Create tracker subtasks (enabled).

### Pipeline Profiles

Optional. Keys: Profile, Skip stages, Extra stages. Default (none). Applies to fix-bugs and implement-feature. Stage names for skip: triage, analyst-impact, spec-analyst, test-engineer, test-engineer-e2e, browser-agent-reproduce, browser-agent-verify. Stages fixer, reviewer, publisher CANNOT be skipped.

### Metrics

Optional. Keys + defaults: Output (stdout), Period (30 days).

### Agent Overrides

Optional. Keys + default: Path (customization/). For each agent (e.g., `reviewer`, `fixer`, `test-engineer`), create a file `{path}/{agent-name}.md` with additional instructions. Contents are appended to the agent's prompt as `## Project-Specific Instructions`. Example: `customization/reviewer.md` with content "Always check for SQL injection in all database queries" will add this instruction to every reviewer invocation. Files that don't match any agent name are ignored.

### Local Deployment

Optional. Keys: Type, Start command, Stop command, Health check URL, Health check timeout, Ports. Default (none).

### Sprint Planning

Optional. Keys + defaults: Sprint duration (2 weeks), Capacity unit (story-points), Team capacity (none), Velocity target (none), Sprint field (tracker-dependent), Mode (suggest), Max issues (20), Epic template (none).

### Autopilot

Optional. The `### Autopilot` section has exactly 7 keys. `Bug query` and `Feature query` are NOT Autopilot keys — they are read from `### Issue Tracker` and `### Feature Workflow` respectively.

| Key | Default | Purpose |
|-----|---------|---------|
| Max issues per run | 1 | Total cap per invocation (bugs + features combined) |
| Lock timeout | 120 | Stale lock threshold in minutes |
| Log file | .ceos-agents/autopilot.log | Append-only run log path |
| Bug limit | 0 | Per-type bug cap (0 = no per-type cap) |
| Feature limit | 0 | Per-type feature cap (0 = no per-type cap) |
| On error | skip | `skip` = continue on error; `stop` = abort run on first error |
| Dry run | false | `true` = full short-circuit (no lock, no state, no dispatch) |

### Pause Limits

Optional section controlling how long a `paused` pipeline (awaiting NEEDS_CLARIFICATION clarification) is retained before autopilot considers it abandoned.

| Key | Default |
|-----|---------|
| Pause timeout | 30 days |

Valid range: min 1 hour, max 365 days. Invalid values fall back to the default (30 days) with a `[WARN]` log — the pipeline is NOT aborted on invalid input. See `skills/autopilot/SKILL.md` `parse_pause_timeout()` for validation logic.

## Webhook Payloads

Webhook payloads are forward-compatible — additive fields may be added in future MINOR versions without a schema version bump. Consumers MUST use lenient JSON parsing (ignore unknown fields). Existing payload fields (`pr-created`, `ceos-agents-block`) are never renamed or removed. New events (`pipeline-started`, `step-completed`, `pipeline-completed`) were added in v6.8.0. Webhook delivery failure is advisory — `[WARN] Webhook delivery failed` is logged and the pipeline continues.

**Operator trust required**: The `Webhook URL` value is dispatched via `curl` without scheme or host validation. Operators are responsible for configuring trusted URLs pointing to internal observability endpoints. SSRF defenses (e.g., restricting `file://`/`gopher://` schemes) are deferred to v6.9.0. Per spec design §3.6.

**Known v6.9.0 limitation — covert-channel DoS:** the `Webhook URL` value in Automation Config is dispatched via curl without scheme/host validation beyond `--proto "=http,https"`. A malicious PR that injects a slow-responding `Webhook URL` could trigger the v6.9.0 circuit-breaker (3 consecutive failures, then suppression for the run). This is bounded but not zero-cost. **Operator guidance:** (a) treat CLAUDE.md `Webhook URL` PR changes as security-relevant, (b) defer setting `Webhook URL` in multi-contributor environments until v6.9.1 (which will add cross-run circuit persistence + URL allowlist).

## Plugin Composability

ceos-agents uses the `ceos-agents:` namespace prefix on all skills. To ensure compatibility with other plugins:

- All skills are invoked as `/ceos-agents:<skill>` (e.g., `/ceos-agents:fix-bugs`)
- Custom agents should follow a similar namespace convention (e.g., `my-plugin:agent-name`)
- Run `/ceos-agents:check-setup` to detect potential skill name conflicts with other installed plugins

## Block Comment Template

When an agent blocks an issue, skills instruct it to use this format:

```
[ceos-agents] 🔴 Pipeline Block
Agent: {agent name}
Step: {pipeline step where failure occurred}
Reason: {max 2 sentences}
Detail: {technical output — error message, diff, test output}
Recommendation: {what the human should do}
```

Triage checkpoint comment format (after successful triage):

```
[ceos-agents] Triage completed. Severity: {severity}. Area: {area}. Complexity: {complexity}. AC: {count}.
```

Both use `[ceos-agents]` prefix for machine-parseable detection by entry-point skills (`/fix-bugs`, `/implement-feature`, `/scaffold`) which auto-resume paused pipelines.

## Versioning Policy

| Level | Trigger | Examples |
|-------|---------|---------|
| MAJOR (X.0.0) | Breaking change in Automation Config contract — new required key, renamed section — OR breaking change in agent output format contract (new/modified structured output sections that Agent Overrides or external tooling may parse) — OR introduction of a mandatory new structured contract section in agent definition files that v8.0.0 agents would fail validation against | New required key in Issue Tracker; new output section in analyst; mandatory `## Output Contract` (v9.0.0) |
| MINOR (X.Y.0) | New backward-compatible feature — new optional key, new command/agent | `/version-check`, optional Hooks section |
| PATCH (X.Y.Z) | Behavior fix without contract change | Agent text fix, command logic fix |

Key rule: Adding a **required** key to Automation Config = MAJOR. Adding an **optional** section = MINOR.

Adding new static declaration sections to agent definition files (`## Output Contract`, `## Inputs`, `## Outputs`, or similar metadata blocks) that are not enforced at runtime classifies as MINOR when the section is OPTIONAL (consuming-project agent files without it remain valid against the harness) and MAJOR when the section is MANDATORY (agent files without it fail at least one harness scenario). The override injector at `core/agent-override-injector.md` is structure-blind and is not "external tooling that parses" agent body sections — its append-only behavior does not fire the MAJOR clause on its own.

## Cross-File Invariants

The following invariants MUST hold across release commits. Phase 8 verification scenarios assert each:

1. **License SPDX consistency** — `.claude-plugin/plugin.json:license`, `.claude-plugin/marketplace.json:plugins[0].license`, and the first heading of `LICENSE` MUST all reference the exact string `"MIT"` (canonical SPDX form, case-sensitive).
2. **Maintainer email consistency** — `SECURITY.md`, `CODE_OF_CONDUCT.md`, and `CONTRIBUTING.md` MUST all reference `filip.sabacky@ceosdata.com` as the maintainer contact (no other emails for this role).
3. **Issue/PR template parity** — corresponding files under `.gitea/issue_template/`, `.gitea/pull_request_template.md`, `.github/ISSUE_TEMPLATE/`, `.github/PULL_REQUEST_TEMPLATE.md` MUST be byte-identical pairs (verify via `diff -q`).

See `feedback_doc_completeness.md` for the doc-count drift audit discipline (CLAUDE.md, README.md, docs/reference/automation-config.md, docs/reference/skills.md, docs/architecture.md count fields must be kept in sync).

## When Editing Agent Definitions

- Preserve the frontmatter format exactly (name, description, model, style)
- Keep the Goal → Expertise → Process → Output Contract → Step Completion Invariants → Constraints section order
- Process steps must be numbered and actionable
- Constraints must start with NEVER or define hard limits
- The `description` field in frontmatter is what appears in Claude Code's agent picker — keep it concise and descriptive
