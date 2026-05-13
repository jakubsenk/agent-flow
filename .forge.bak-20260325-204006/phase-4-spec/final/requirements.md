# Forge + ceos-agents Merger Migration: Requirements Specification

**Author:** Dr. Sarah Chen, Principal Software Architect
**Date:** 2026-03-22
**Version:** 1.0.0
**Status:** PROPOSED
**Scope:** ceos-agents v5.1.x through v5.5.0

---

## Table of Contents

1. [Plugin Identity and Versioning](#1-plugin-identity-and-versioning)
2. [Directory Structure](#2-directory-structure)
3. [/build Entry Point](#3-build-entry-point)
4. [Core Pattern Files](#4-core-pattern-files)
5. [Mode Adapter Specifications](#5-mode-adapter-specifications)
6. [Agent Roster](#6-agent-roster)
7. [State Management](#7-state-management)
8. [Backward Compatibility](#8-backward-compatibility)
9. [Documentation Plan](#9-documentation-plan)
10. [Migration Sequence](#10-migration-sequence)

---

## 1. Plugin Identity and Versioning

### 1.1 Plugin Name

The plugin name remains `ceos-agents`. The `ceos-agents:` namespace prefix is immutable. The `plugin.json` `"name"` field is unchanged.

### 1.2 Version Plan

| Version | Type | Content | Estimated PRs |
|---------|------|---------|---------------|
| v5.1.x | PATCH | Race condition fix, test fixes, pre-existing gap fixes, fragile test updates, 4 new structural tests | PR 0 |
| v5.2.0 | MINOR | State infrastructure (`.ceos-agents/{RUN-ID}/state.json`, `core/state-manager.md`, `state/schema.md`) | PR 1 |
| v5.2.x | PATCH | Core pattern extraction (create `core/` directory, refactor pipeline commands to reference core files) | PR 2, PR 3 |
| v5.3.0 | MINOR | `/build` skill with code modes (code-bugfix, code-feature, code-project) + 3 new agents | PR 4, PR 5 |
| v5.4.0 | MINOR | Analysis mode (`mode-analysis.md`, domain context blocks for reviewer/spec-writer/spec-reviewer) | PR 6 |
| v5.5.0 | MINOR | Strategy + content modes (`mode-strategy.md`, `mode-content.md`) | PR 7 |

### 1.3 Changelog Structure

Each version entry in `CHANGELOG.md` follows the existing format:

```
## [vX.Y.Z] - YYYY-MM-DD

### Added
- New capabilities (commands, agents, skills, config sections)

### Changed
- Modified behavior (internal refactors, command improvements)

### Fixed
- Bug fixes (race conditions, test failures, gaps)
```

### 1.4 Description Update

The plugin description in `.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json` is updated at v5.3.0 to reflect the unified pipeline capability:

**Current:** "Automates bug-fix workflows, feature implementation, and project scaffolding."
**Updated:** "Automates bug-fix workflows, feature implementation, project scaffolding, and multi-mode pipelines (code, analysis, strategy, content)."

This is a documentation change (Class B), not a contract change.

---

## 2. Directory Structure

### 2.1 Complete Target Layout (v5.5.0)

New files and directories are annotated with their introducing version. Existing files are unmarked.

```
ceos-agents/
  .claude-plugin/
    plugin.json                          # EXISTING — updated description at v5.3.0
    marketplace.json                     # EXISTING — updated description at v5.3.0
  agents/
    acceptance-gate.md                   # EXISTING (unchanged)
    architect.md                         # EXISTING (unchanged)
    browser-verifier.md                  # EXISTING (unchanged)
    code-analyst.md                      # EXISTING (unchanged)
    domain-analyst.md                    # NEW v5.3.0 — analytical/strategic reasoning
    e2e-test-engineer.md                 # EXISTING (unchanged)
    fixer.md                             # EXISTING (unchanged)
    intake-agent.md                      # NEW v5.3.0 — flexible input ingestion
    priority-engine.md                   # EXISTING (unchanged)
    publisher.md                         # EXISTING (unchanged)
    reproducer.md                        # EXISTING (unchanged)
    reviewer.md                          # EXISTING (unchanged)
    rollback-agent.md                    # EXISTING (unchanged)
    scaffolder.md                        # EXISTING (unchanged)
    spec-analyst.md                      # EXISTING (unchanged)
    spec-reviewer.md                     # EXISTING (unchanged)
    spec-writer.md                       # EXISTING (unchanged)
    stack-selector.md                    # EXISTING (unchanged)
    synthesizer.md                       # NEW v5.3.0 — output assembly for non-code
    test-engineer.md                     # EXISTING (unchanged)
    triage-analyst.md                    # EXISTING (unchanged)
  checklists/
    review-checklist.md                  # EXISTING (unchanged)
    test-checklist.md                    # EXISTING (unchanged)
    publish-checklist.md                 # EXISTING (unchanged)
  commands/
    analyze-bug.md                       # EXISTING (unchanged)
    changelog.md                         # EXISTING (unchanged)
    check-setup.md                       # EXISTING (unchanged)
    create-pr.md                         # EXISTING (unchanged)
    dashboard.md                         # EXISTING (unchanged)
    discuss.md                           # EXISTING (unchanged)
    estimate.md                          # EXISTING (unchanged)
    fix-bugs.md                          # EXISTING (refactored to reference core/ at v5.2.x)
    fix-ticket.md                        # EXISTING (refactored to reference core/ at v5.2.x)
    implement-feature.md                 # EXISTING (refactored to reference core/ at v5.2.x)
    init.md                              # EXISTING (unchanged)
    metrics.md                           # EXISTING (unchanged)
    migrate-config.md                    # EXISTING (unchanged)
    onboard.md                           # EXISTING (unchanged)
    prioritize.md                        # EXISTING (unchanged)
    publish.md                           # EXISTING (unchanged)
    resume-ticket.md                     # EXISTING (updated for state.json at v5.2.0)
    scaffold-add.md                      # EXISTING (unchanged)
    scaffold-validate.md                 # EXISTING (unchanged)
    scaffold.md                          # EXISTING (refactored to reference core/ at v5.2.x)
    status.md                            # EXISTING (unchanged)
    template.md                          # EXISTING (unchanged)
    version-bump.md                      # EXISTING (unchanged)
    version-check.md                     # EXISTING (unchanged)
  core/                                  # NEW v5.2.x — shared pipeline patterns
    config-reader.md                     # Automation Config parsing
    mcp-preflight.md                     # MCP server connectivity check
    fixer-reviewer-loop.md               # Fixer/reviewer iteration loop
    block-handler.md                     # Issue blocking with rollback
    agent-override-injector.md           # Agent override file loading
    decomposition-heuristics.md          # Decompose vs single-pass decision
    profile-parser.md                    # Pipeline profile stage map
    post-publish-hook.md                 # Post-publish hook + webhook execution
    fix-verification.md                  # Post-merge verify command execution
    state-manager.md                     # State file read/write/resume contract
  docs/
    architecture.md                      # EXISTING (updated at v5.3.0 with Mermaid diagrams)
    getting-started.md                   # EXISTING (updated at v5.5.0)
    guides/                              # EXISTING (unchanged)
    plans/                               # EXISTING (unchanged)
    reference/
      agents.md                          # EXISTING (updated with 3 new agents at v5.3.0)
      automation-config.md               # EXISTING (updated with new optional sections)
      build-command.md                   # NEW v5.3.0 — /build skill reference
      commands.md                        # EXISTING (unchanged)
      execution-loop.md                  # EXISTING (unchanged)
      pipelines.md                       # EXISTING (updated with non-code pipelines at v5.4.0)
      state-management.md               # NEW v5.2.0 — state.json reference
      trackers.md                        # EXISTING (unchanged)
  examples/
    configs/                             # EXISTING (expanded with new examples)
    custom-agents/                       # EXISTING (unchanged)
    mcp-configs/                         # EXISTING (unchanged)
    workflows/                           # NEW v5.3.0 — concrete workflow examples
      code-bugfix-workflow.md            # Step-by-step bugfix via /build
      code-feature-workflow.md           # Step-by-step feature via /build
      analysis-workflow.md               # Step-by-step analysis via /build
      strategy-workflow.md               # Step-by-step strategy via /build
      content-workflow.md                # Step-by-step content via /build
  skills/
    bug-workflow/
      SKILL.md                           # EXISTING (updated: add discuss + build routing)
    build/                               # NEW v5.3.0
      SKILL.md                           # Unified entry point skill
      mode-code-bugfix.md               # Code bugfix mode adapter
      mode-code-feature.md              # Code feature mode adapter
      mode-code-project.md              # Code project (scaffold) mode adapter
      mode-analysis.md                   # NEW v5.4.0 — analysis mode adapter
      mode-strategy.md                   # NEW v5.5.0 — strategy mode adapter
      mode-content.md                    # NEW v5.5.0 — content mode adapter
  state/
    schema.md                            # NEW v5.2.0 — state.json schema documentation
  tests/
    harness/                             # EXISTING (unchanged)
    mock-project/                        # EXISTING (unchanged)
    scenarios/
      # EXISTING scenarios (some updated in v5.1.x):
      browser-verification-skip.sh
      fixer-retry.sh
      happy-path.sh                      # UPDATED v5.1.x — dynamic inventory
      pipeline-consistency.sh            # UPDATED v5.1.x — discoverable pipeline files
      profile-skip.sh
      publish-success.sh
      reviewer-reject.sh
      scaffold-v2-happy-path.sh
      scaffold-v2-input-conflicts.sh
      scaffold-v2-no-implement.sh
      scaffold-v2-spec-loop.sh
      test-fail.sh
      triage-block.sh
      verify-fail.sh                     # UPDATED v5.1.x — remove step-number coupling
      # NEW scenarios:
      frontmatter-completeness.sh        # NEW v5.1.x — all agents have required fields
      model-assignment.sh                # NEW v5.1.x — model matches CLAUDE.md table
      read-only-agents.sh               # NEW v5.1.x — read-only agents contain no write
      section-order.sh                   # NEW v5.1.x — Goal/Expertise/Process/Constraints
      state-schema.sh                    # NEW v5.2.0 — state.json schema validation
      core-include-refs.sh              # NEW v5.2.x — core files referenced correctly
      build-skill-structure.sh          # NEW v5.3.0 — /build skill file structure
      build-mode-detection.sh           # NEW v5.3.0 — mode adapter presence
      new-agent-structure.sh            # NEW v5.3.0 — 3 new agents structural check
```

### 2.2 Per-Issue Runtime Directory

Created at pipeline runtime by commands and the `/build` skill. Not checked into the repository.

```
.ceos-agents/                            # In consuming project's working directory
  {RUN-ID}/                              # ISSUE-ID for tracker runs, timestamp for non-tracker
    state.json                           # Pipeline state (see Section 7)
    pipeline.log                         # Append-only event log (see Section 7.5)
    reproduction-result.json             # Moved from .claude/ (fixes race condition)
    reproducer-script.js                 # Moved from .claude/ (fixes race condition)
    verification-result.json             # Moved from .claude/ (fixes race condition)
    screenshots/                         # Moved from .claude/screenshots/
      {issue-id}-before.png
      {issue-id}-after.png
```

### 2.3 Directory Invariants

- The `agents/` directory remains flat. No subdirectories.
- The `commands/` directory remains flat. No subdirectories.
- The `core/` directory is flat. No subdirectories.
- The `skills/build/` directory contains only `SKILL.md` and `mode-*.md` files.
- The `state/` directory contains only `schema.md`.

---

## 3. /build Entry Point

### 3.1 Skill Identity

| Field | Value |
|-------|-------|
| Location | `skills/build/SKILL.md` |
| Name | `build` |
| Description | `Unified pipeline entry point for code, analysis, strategy, and content workflows` |
| Namespace invocation | `/ceos-agents:build` or natural language via bug-workflow skill router |

### 3.2 Command Signature

```
/ceos-agents:build <input> [flags]
```

**Positional argument:**
- `<input>` -- Required. One of:
  - Issue ID (e.g., `PROJ-123`) -- triggers code-bugfix or code-feature mode based on issue type
  - Natural language description (e.g., `"Analyze the impact of switching to PostgreSQL"`) -- triggers non-code mode
  - `--issue <ID>` -- explicit issue reference

**Flags:**

| Flag | Values | Default | Description |
|------|--------|---------|-------------|
| `--mode` | `code-bugfix`, `code-feature`, `code-project`, `analysis`, `strategy`, `content` | auto-detect | Explicit mode selection (bypasses auto-detection) |
| `--yolo` | (boolean) | false | Skip all confirmations, auto-approve, auto-publish |
| `--dry-run` | (boolean) | false | Analysis only, no side effects |
| `--profile` | `<name>` | (none) | Pipeline profile from Automation Config |
| `--decompose` | (boolean) | false | Force decomposition into subtasks |
| `--no-decompose` | (boolean) | false | Disable decomposition |
| `--resume` | `<RUN-ID>` | (none) | Resume a previously interrupted pipeline run |
| `--template` | `<path-or-name>` | (none) | Document template for output formatting (SDLC or custom) |
| `--output` | `<path>` | (auto) | Output directory for non-code mode deliverables |
| `--no-implement` | (boolean) | false | For code-project: scaffold only, no implementation |
| `--lang` | `<language>` | (none) | For code-project: programming language |
| `--framework` | `<framework>` | (none) | For code-project: framework selection |
| `--brainstorm` | (boolean) | false | For code-project: enable brainstorm mode |

### 3.3 Mode Detection Algorithm

When `--mode` is not specified, the `/build` skill detects the mode using the following ordered rules:

```
1. If --resume is provided:
   → Read state.json from .ceos-agents/{RUN-ID}/
   → Resume in the mode recorded in state.json

2. If input is an issue ID (matches issue tracker ID pattern from Automation Config):
   a. Query issue tracker for issue type/labels
   b. If issue type matches Feature Workflow query → mode = code-feature
   c. If issue type matches Bug query → mode = code-bugfix
   d. If neither matches → ask user to select mode

3. If input is a natural language description:
   a. Parse intent keywords:
      - "analyze", "assess", "evaluate", "research", "investigate" → candidate: analysis
      - "strategy", "plan", "roadmap", "proposal", "business case" → candidate: strategy
      - "write", "document", "content", "article", "guide", "blog" → candidate: content
      - "build", "create", "scaffold", "implement", "develop" → candidate: code-project
   b. If --template is SDLC or doc template → candidate: analysis or content (based on template type)
   c. If no clear candidate or multiple candidates → ask user

4. If auto-detection produces a candidate AND --yolo is NOT set:
   → Present detected mode to user with one-line explanation
   → Ask for confirmation: "Detected mode: {mode}. Proceed? [Y/n/change]"
   → If user says "change" → present all 6 modes for selection

5. If --yolo is set:
   → Use auto-detected mode without confirmation
   → If ambiguous → default to code-bugfix for issue IDs, analysis for text
```

### 3.4 Confirmation UX

For non-YOLO mode, the `/build` skill presents a pipeline summary before execution:

```
Pipeline: {mode-name}
Input: {input summary}
Phases: {phase list from mode adapter}
Profile: {profile-name or "default"}
Template: {template-name or "none"}
Estimated complexity: {if available from prior triage}

Proceed? [Y/n]
```

### 3.5 Skill File Organization

The `SKILL.md` file contains:
1. Frontmatter (`name`, `description`)
2. Mode detection algorithm (Section 3.3)
3. Flag parsing and validation
4. Dispatch logic: reads `${CLAUDE_SKILL_DIR}/mode-{detected-mode}.md` and follows its instructions
5. Resume logic: reads state.json and dispatches to the appropriate mode adapter at the recorded phase
6. Error handling: if mode adapter file is missing, reports available modes

Each `mode-*.md` file within `skills/build/` is a self-contained mode adapter (see Section 5).

### 3.6 Integration with bug-workflow Skill Router

The `skills/bug-workflow/SKILL.md` intent mapping table is updated with a new row:

| User Intent | Command | Arguments | Destructive? |
|-------------|---------|-----------|-------------|
| Run unified pipeline / build / analyze / strategize / write content | `ceos-agents:build` | Input + flags | Yes |

Natural language requests that match `/build` intents (e.g., "analyze the codebase for security issues", "write a strategy document") are routed to the build skill.

---

## 4. Core Pattern Files

### 4.1 Overview

The `core/` directory contains 10 markdown files, each encapsulating a shared pipeline pattern that is referenced by multiple commands and by `/build` mode adapters. Each file has a consistent structure:

```markdown
# {Pattern Name}

## Purpose
One-line description.

## Input Contract
What the caller must provide (variables, context, config sections).

## Process
Numbered steps the caller follows.

## Output Contract
What the pattern produces (variables set, state written, comments posted).

## Failure Handling
What happens when the pattern fails (block, skip, retry).
```

Core files are NOT agents. They are not dispatched via the Task tool. They are prose instructions that commands and mode adapters reference by path. Commands reference them as "Follow the process defined in `core/X.md`." The `/build` skill reads them via `${CLAUDE_SKILL_DIR}/../core/X.md` or by absolute path resolution from the plugin root.

### 4.2 config-reader.md

**Purpose:** Parse `## Automation Config` from the consuming project's CLAUDE.md and extract all configuration sections into named variables.

**Input Contract:**
- Access to the consuming project's CLAUDE.md file

**Output Contract:**
- Variables set for all config sections: `issue_tracker_type`, `issue_tracker_instance`, `issue_tracker_project`, `bug_query`, `state_transitions`, `on_start_set`, `remote`, `base_branch`, `branch_naming`, `pr_labels`, `pr_description_template`, `build_command`, `test_command`, `verify_command`
- Optional section variables: `retry_fixer_iterations` (default 5), `retry_test_attempts` (default 3), `retry_build_retries` (default 3), `retry_spec_iterations` (default 5), hooks, custom agents, notifications, worktrees, e2e test, browser verification, error handling, extra labels, feature workflow, decomposition, pipeline profiles, metrics, agent overrides

**Failure Handling:**
- If CLAUDE.md is missing or has no `## Automation Config`: Block with reason "Missing Automation Config in CLAUDE.md"
- If required sections (Issue Tracker, Source Control, PR Rules, Build & Test) are missing: Block with specific missing section name

### 4.3 mcp-preflight.md

**Purpose:** Verify MCP server connectivity before pipeline execution.

**Input Contract:**
- `issue_tracker_type` from config-reader

**Output Contract:**
- Boolean `mcp_available` — true if the issue tracker MCP server responds
- If false: the specific error message

**Failure Handling:**
- If MCP is unavailable: Block with reason "MCP server {type} not available"

### 4.4 fixer-reviewer-loop.md

**Purpose:** Execute the fixer-reviewer iteration loop with configurable retry limits and context.

**Input Contract:**
- `context` — the assembled context for the fixer (varies by command/mode)
- `max_iterations` — fixer iteration limit (from config, default 5)
- `acceptance_criteria` — list of AC items (may be empty)
- `agent_overrides_path` — path to agent override directory
- `state_run_id` — for state file updates

**Output Contract:**
- `loop_result` — one of: `APPROVED`, `BLOCKED`, `NEEDS_DECOMPOSITION`
- `iteration_count` — number of iterations executed
- `reviewer_verdicts` — list of per-iteration verdicts
- State file updated with iteration count and verdict history

**Failure Handling:**
- If `max_iterations` reached without approval: Block with reason "Fixer-reviewer loop exhausted after {N} iterations"
- If fixer signals `NEEDS_DECOMPOSITION`: return `NEEDS_DECOMPOSITION` (max 1 per ticket)
- On block: invoke rollback-agent, then block-handler

### 4.5 block-handler.md

**Purpose:** Handle pipeline blocks consistently: post comment, set issue state, invoke rollback if applicable, trigger notifications.

**Input Contract:**
- `agent_name` — the agent that triggered the block
- `step_name` — the pipeline step where failure occurred
- `reason` — max 2 sentences
- `detail` — technical output
- `recommendation` — what the human should do
- `issue_id` — the issue being processed
- `error_handling_on_block` — from config (default: `comment`)

**Output Contract:**
- Block comment posted to issue tracker using the `[ceos-agents]` Block Comment Template
- Issue state set per `error_handling_on_block` configuration
- Notification webhook fired if configured
- State file updated with block status

**Failure Handling:**
- If comment posting fails: log to pipeline.log but do not re-block (avoid infinite loop)

### 4.6 agent-override-injector.md

**Purpose:** Load project-specific agent override files and append them to agent context.

**Input Contract:**
- `agent_name` — the agent being dispatched
- `agent_overrides_path` — path from config (default: `customization/`)

**Output Contract:**
- `override_content` — the content of `{path}/{agent-name}.md` if it exists, empty string otherwise
- Content is appended to the agent prompt as `## Project-Specific Instructions`

**Failure Handling:**
- If override file does not exist: no-op (silent skip)
- If override file is unreadable: log warning, continue without override

### 4.7 decomposition-heuristics.md

**Purpose:** Determine whether a ticket should be decomposed into subtasks or executed as a single pass.

**Input Contract:**
- `decompose_flag` — tri-state: FORCE, DISABLED, AUTO
- `risk_level` — from code-analyst (HIGH/MEDIUM/LOW)
- `affected_files_count` — from code-analyst
- `estimated_diff_lines` — from code-analyst
- `change_area_count` — from code-analyst
- `complexity` — from triage (XS/S/M/L)

**Output Contract:**
- `decision` — one of: `DECOMPOSE`, `SINGLE_PASS`
- `reason` — explanation for the decision

**Failure Handling:**
- If input data is missing (no code-analyst report): default to `SINGLE_PASS` unless `decompose_flag == FORCE`

**Thresholds (code-bugfix/code-feature):**
- `risk == HIGH` → DECOMPOSE
- `affected_files_count >= 4` → DECOMPOSE
- `estimated_diff_lines > 60 AND affected_files_count >= 3` → DECOMPOSE
- `change_area_count >= 2` → DECOMPOSE

### 4.8 profile-parser.md

**Purpose:** Parse pipeline profile configuration and determine which stages to skip or add.

**Input Contract:**
- `profile_name` — from `--profile` flag
- Pipeline Profiles section from Automation Config

**Output Contract:**
- `skip_stages` — list of stage names to skip
- `extra_stages` — list of extra stage names to add
- Validated that fixer, reviewer, publisher are NOT in skip list

**Failure Handling:**
- If profile name not found in config: Block with reason "Unknown pipeline profile: {name}"
- If skip list contains fixer/reviewer/publisher: Block with reason "Cannot skip mandatory stage: {stage}"

### 4.9 post-publish-hook.md

**Purpose:** Execute post-publish hooks and webhook notifications.

**Input Contract:**
- `hooks_post_publish` — from config (may be empty)
- `notifications_webhook_url` — from config (may be empty)
- `notifications_on_events` — from config (may be empty)
- `pr_url` — the created PR URL
- `issue_id` — the issue being processed

**Output Contract:**
- Hook execution result (success/failure)
- Webhook fired if `publish` is in `on_events`

**Failure Handling:**
- Hook failure: log warning, do NOT block (post-publish hooks are advisory)
- Webhook failure: log warning, do NOT block

### 4.10 fix-verification.md

**Purpose:** Execute the verify command after PR merge to confirm the fix works in the target branch.

**Input Contract:**
- `verify_command` — from config (may be empty)
- `issue_id` — the issue being processed
- `pr_merged` — boolean

**Output Contract:**
- `verification_result` — PASSED, FAILED, or SKIPPED (if no verify command)
- If FAILED: issue is re-opened

**Failure Handling:**
- If verify command exits non-zero: post `[ceos-agents] Fix verification failed.` comment, re-open issue
- If verify command is not configured: skip (SKIPPED)

### 4.11 state-manager.md

**Purpose:** Provide the read/write/resume contract for `.ceos-agents/{RUN-ID}/state.json`.

**Input Contract (write):**
- `run_id` — the issue ID or timestamp
- `field_path` — dot-notation path to the field being updated
- `value` — the new value

**Input Contract (read):**
- `run_id` — the issue ID or timestamp

**Input Contract (resume):**
- `run_id` — the issue ID or timestamp

**Output Contract (write):**
- State file atomically updated (write to `.tmp`, rename to `.json`)
- Event appended to `pipeline.log`

**Output Contract (read):**
- Full state object, or null if file does not exist

**Output Contract (resume):**
- `resume_point` — the phase/step to resume from
- `resume_context` — preserved AC list, complexity, profile, iteration counts
- If state file does not exist: fall back to heuristic detection (resume-ticket's 7-level priority)

**Failure Handling:**
- Atomic write failure: retry once, then log error and continue (state loss is non-fatal)
- Corrupted state file: log warning, fall back to heuristic

---

## 5. Mode Adapter Specifications

### 5.1 Mode Adapter Contract

Each mode adapter file (`skills/build/mode-*.md`) follows this structure:

```markdown
# Mode: {mode-name}

## Description
One-line description of what this mode does.

## Applicable When
Conditions under which this mode is selected.

## Phase Sequence
Ordered list of phases with:
- Phase name
- Agent(s) dispatched
- Input requirements
- Output produced
- Skip conditions
- Failure handling

## Domain Context Blocks
For each existing agent that receives domain adaptation:
- Agent name
- Domain-specific checklist or criteria to inject
- Injection mechanism (appended as ## Domain Context)

## Output Format
What the pipeline produces as its final deliverable.

## SDLC Template Integration
How document templates affect output formatting.
```

### 5.2 Mode: code-bugfix

**Description:** Fix a bug from an issue tracker ticket. Equivalent to the existing `/fix-ticket` command pipeline.

**Phase Sequence:**

| # | Phase | Agent(s) | Skip Condition | Output |
|---|-------|----------|----------------|--------|
| 1 | Config | (core/config-reader.md) | Never | Config variables |
| 2 | MCP Preflight | (core/mcp-preflight.md) | Never | MCP availability |
| 3 | Triage | triage-analyst | Profile skip | AC list, complexity, severity, reproduction_steps |
| 4 | Code Analysis | code-analyst | Profile skip | Impact report, affected files, risk |
| 5 | Reproduction | reproducer | Browser config absent OR profile skip | reproduction-result.json |
| 6 | Pre-fix Hook | (config hook) | Hook not configured | Hook result |
| 7 | Fix/Review Loop | fixer + reviewer (core/fixer-reviewer-loop.md) | Never | Approved code changes |
| 8 | Post-fix Hook | (config hook + custom agent) | Hook not configured | Hook result |
| 9 | Test | test-engineer | Profile skip | Tests passing |
| 10 | E2E Test | e2e-test-engineer | E2E config absent OR profile skip | E2E tests passing |
| 11 | Browser Verify | browser-verifier | Browser config absent OR verify not in events | verification-result.json |
| 12 | Acceptance Gate | acceptance-gate | AC < 3 AND complexity < M | AC fulfillment verdict |
| 13 | Pre-publish Hook | (config hook + custom agent) | Hook not configured | Hook result |
| 14 | Publish | publisher | Never | PR URL |
| 15 | Post-publish | (core/post-publish-hook.md) | Hook not configured | Webhook fired |

**Domain Context Blocks:** None (code mode uses agents' default behavior).

**SDLC Template Integration:** Not applicable for code-bugfix mode.

### 5.3 Mode: code-feature

**Description:** Implement a feature from an issue tracker ticket. Equivalent to the existing `/implement-feature` command pipeline.

**Phase Sequence:**

| # | Phase | Agent(s) | Skip Condition | Output |
|---|-------|----------|----------------|--------|
| 1 | Config | (core/config-reader.md) | Never | Config variables |
| 2 | MCP Preflight | (core/mcp-preflight.md) | Never | MCP availability |
| 3 | Spec Analysis | spec-analyst | Profile skip | AC list (written back to issue) |
| 4 | Architecture | architect | Never | Task tree with maps_to |
| 5 | AC Coverage Check | (inline) | Never | Coverage verification |
| 6 | Decomposition Decision | (core/decomposition-heuristics.md) | Never | DECOMPOSE or SINGLE_PASS |
| 7 | Fix/Review Loop | fixer + reviewer (core/fixer-reviewer-loop.md) | Never | Approved code changes |
| 8 | Test | test-engineer | Profile skip | Tests passing |
| 9 | Acceptance Gate | acceptance-gate | Never (always runs for features) | AC fulfillment verdict |
| 10 | Publish | publisher | Never | PR URL |

**Domain Context Blocks:** None (code mode uses agents' default behavior).

**SDLC Template Integration:** Not applicable for code-feature mode.

### 5.4 Mode: code-project

**Description:** Scaffold and implement a new project from a description. Equivalent to the existing `/scaffold` command pipeline.

**Phase Sequence:**

| # | Phase | Agent(s) | Skip Condition | Output |
|---|-------|----------|----------------|--------|
| 1 | Config | (core/config-reader.md, optional) | CLAUDE.md absent | Config variables or defaults |
| 2 | Spec Writing | spec-writer + spec-reviewer | --no-implement with --template | spec/ folder |
| 3 | Spec Checkpoint | (user confirmation) | --yolo | User approval |
| 4 | Scaffolding | scaffolder | Never | Project skeleton + scorecard |
| 5 | Validate | (inline) | Never | Build + test pass |
| 6 | Git Init | (inline) | Never | Git repository |
| 7 | Architecture | architect | --no-implement | Task tree with maps_to |
| 8 | Feature Plan Checkpoint | (user confirmation) | --yolo | User approval |
| 9 | Fix/Review Loop | fixer + reviewer | --no-implement | Implemented features |
| 10 | Test | test-engineer | --no-implement | Tests passing |
| 11 | Spec Compliance | spec-reviewer --verify | --no-implement | Compliance verdict |
| 12 | E2E Test | e2e-test-engineer | --no-implement | E2E tests passing |
| 13 | Final Report | (inline) | Never | Summary |

When `--no-implement` is set, the pipeline executes: stack-selector, scaffolder, validate, git init (v3.x behavior).

**SDLC Template Integration:** If `--template sdlc` is specified, the scaffolder generates a `docs/` folder using SDLC template structure from the detected or specified tier (min/mid/max). See Section 5.8.

### 5.5 Mode: analysis

**Description:** Analyze a topic, dataset, codebase, or document set and produce a structured analytical report. This is the first non-code mode.

**Phase Sequence:**

| # | Phase | Agent(s) | Skip Condition | Output |
|---|-------|----------|----------------|--------|
| 1 | Config | (core/config-reader.md, optional) | CLAUDE.md absent | Config variables or defaults |
| 2 | Intake | intake-agent | Never | Structured input summary |
| 3 | Scope Definition | spec-writer (with analysis domain context) | Never | Analysis scope document |
| 4 | Scope Review | spec-reviewer (with analysis domain context) | Never | Scope approval |
| 5 | Domain Analysis | domain-analyst | Never | Analytical findings |
| 6 | Synthesis | synthesizer | Never | Draft report |
| 7 | Review | reviewer (with analysis domain context) | Never | Review feedback |
| 8 | Revision Loop | synthesizer + reviewer | Max 3 iterations | Approved report |
| 9 | Verification | (inline) | Never | REVIEWED verdict with confidence |
| 10 | Output | synthesizer (final format) | Never | Deliverable document(s) |

**Domain Context Blocks:**

**spec-writer (analysis mode):**
```
## Domain Context
You are scoping an analytical investigation, not a software specification.
- Replace "Tech Stack" with "Data Sources and Methods"
- Replace "Data Model" with "Analytical Framework"
- Replace "API" with "Key Questions / Hypotheses"
- Replace "NFR" with "Limitations and Assumptions"
- REQUIRED sections: Purpose, Scope, Key Questions, Data Sources, Methods
- IF APPLICABLE sections: Hypotheses, Constraints, Stakeholders
```

**spec-reviewer (analysis mode):**
```
## Domain Context
You are reviewing an analysis scope, not a software specification.
- REQUIRED sections: Purpose, Scope, Key Questions, Data Sources, Methods
- Replace tech feasibility checks with methodological soundness checks
- Check: Are key questions answerable with stated data sources?
- Check: Are methods appropriate for the questions asked?
- Check: Are limitations honestly stated?
```

**reviewer (analysis mode):**
```
## Domain Context
You are reviewing an analytical report, not source code.
- Replace code security checklist with: source credibility, data quality, statistical validity
- Replace edge case analysis with: alternative explanations, confounding factors, selection bias
- Replace convention compliance with: logical consistency, evidence sufficiency, conclusion support
- Minimum 3 issues requirement still applies
- Severity levels: HIGH (conclusion unsupported), MEDIUM (weak evidence), LOW (presentation issue)
```

**Verification:** The analysis mode verification step produces a structured verdict:

```
[ceos-agents] Analysis REVIEWED.
Confidence: {HIGH|MEDIUM|LOW}
Methodology: {sound|concerns noted}
Evidence quality: {strong|adequate|weak}
Note: This is a qualitative review, not a deterministic verification.
```

**SDLC Template Integration:** If the project has SDLC templates in `docs/`, or if `--template sdlc` is specified, the synthesizer formats output sections according to the SDLC template structure. See Section 5.8.

### 5.6 Mode: strategy

**Description:** Develop a strategic plan, proposal, or business case.

**Phase Sequence:**

| # | Phase | Agent(s) | Skip Condition | Output |
|---|-------|----------|----------------|--------|
| 1 | Config | (core/config-reader.md, optional) | CLAUDE.md absent | Config variables or defaults |
| 2 | Intake | intake-agent | Never | Structured input summary |
| 3 | Scope Definition | spec-writer (with strategy domain context) | Never | Strategy scope document |
| 4 | Scope Review | spec-reviewer (with strategy domain context) | Never | Scope approval |
| 5 | Domain Analysis | domain-analyst (with strategy context) | Never | Strategic analysis |
| 6 | Priority Assessment | priority-engine (with strategy domain context) | Optional | Prioritized options/initiatives |
| 7 | Synthesis | synthesizer | Never | Draft strategy document |
| 8 | Review | reviewer (with strategy domain context) | Never | Review feedback |
| 9 | Revision Loop | synthesizer + reviewer | Max 3 iterations | Approved document |
| 10 | Verification | (inline) | Never | REVIEWED verdict with confidence |
| 11 | Output | synthesizer (final format) | Never | Deliverable document(s) |

**Domain Context Blocks:**

**spec-writer (strategy mode):**
```
## Domain Context
You are scoping a strategic planning exercise, not a software specification.
- Replace "Tech Stack" with "Strategic Context"
- Replace "Data Model" with "Options / Scenarios"
- Replace "API" with "Decision Criteria"
- Replace "NFR" with "Constraints and Risks"
- REQUIRED sections: Purpose, Strategic Context, Options, Decision Criteria, Stakeholders
- IF APPLICABLE sections: Timeline, Budget, Dependencies, Success Metrics
```

**reviewer (strategy mode):**
```
## Domain Context
You are reviewing a strategic document, not source code.
- Replace code security checklist with: strategic coherence, stakeholder alignment, feasibility
- Replace edge case analysis with: scenario robustness, risk mitigation completeness, assumption sensitivity
- Replace convention compliance with: actionability, measurability of success criteria, timeline realism
- Minimum 3 issues requirement still applies
- Severity levels: HIGH (strategic incoherence), MEDIUM (weak feasibility), LOW (presentation issue)
```

**priority-engine (strategy mode):**
```
## Domain Context
You are prioritizing strategic initiatives, not software issues.
- Redefine dimensions: Impact → Strategic Value, Risk → Execution Risk, Effort → Resource Requirements, Urgency → Time Sensitivity
- P0/P1/P2 tiering remains (P0: must-do, P1: should-do, P2: could-do)
- Dependency graph applies to initiative dependencies, not code dependencies
```

**SDLC Template Integration:** See Section 5.8.

### 5.7 Mode: content

**Description:** Produce written content (documentation, articles, guides, specifications).

**Phase Sequence:**

| # | Phase | Agent(s) | Skip Condition | Output |
|---|-------|----------|----------------|--------|
| 1 | Config | (core/config-reader.md, optional) | CLAUDE.md absent | Config variables or defaults |
| 2 | Intake | intake-agent | Never | Structured input summary |
| 3 | Scope Definition | spec-writer (with content domain context) | Never | Content brief / outline |
| 4 | Scope Review | spec-reviewer (with content domain context) | Never | Brief approval |
| 5 | Research / Domain Analysis | domain-analyst (with content context) | Optional | Research notes |
| 6 | Drafting | synthesizer | Never | Draft content |
| 7 | Review | reviewer (with content domain context) | Never | Editorial feedback |
| 8 | Revision Loop | synthesizer + reviewer | Max 3 iterations | Approved content |
| 9 | Verification | (inline) | Never | REVIEWED verdict with confidence |
| 10 | Output | synthesizer (final format) | Never | Deliverable document(s) |

**Domain Context Blocks:**

**spec-writer (content mode):**
```
## Domain Context
You are defining a content brief, not a software specification.
- Replace "Tech Stack" with "Target Audience and Channel"
- Replace "Data Model" with "Content Structure / Outline"
- Replace "API" with "Key Messages"
- Replace "NFR" with "Tone, Style, and Format Requirements"
- REQUIRED sections: Purpose, Audience, Key Messages, Structure, Format
- IF APPLICABLE sections: SEO Requirements, Call to Action, Visual Assets, Publication Timeline
```

**reviewer (content mode):**
```
## Domain Context
You are reviewing written content, not source code.
- Replace code security checklist with: factual accuracy, source attribution, audience appropriateness
- Replace edge case analysis with: readability, information hierarchy, completeness of coverage
- Replace convention compliance with: tone consistency, style guide adherence, formatting correctness
- Minimum 3 issues requirement still applies
- Severity levels: HIGH (factual error), MEDIUM (structural/clarity issue), LOW (style/formatting)
```

**SDLC Template Integration:** See Section 5.8.

### 5.8 SDLC Template Integration

#### 5.8.1 Detection

The pipeline detects SDLC templates when:
1. The user specifies `--template sdlc` or `--template sdlc:{tier}` (where tier is `min`, `mid`, or `max`)
2. The project contains a `docs/` directory with markdown files that have YAML frontmatter containing a `type` field and a `sections` array

Detection algorithm:
```
1. If --template is specified:
   a. If value starts with "sdlc": use SDLC templates
   b. If value is a file path: load custom template (see 5.8.4)
   c. Otherwise: treat as template name, search known template registries

2. If --template is NOT specified:
   a. Scan project docs/ directory for .md files with YAML frontmatter
   b. If any file has frontmatter with "type" and "sections" fields → SDLC detected
   c. Determine tier: count template files
      - 1-3 files → min tier
      - 4-10 files → mid tier
      - 11+ files → max tier
   d. If no templates detected → use default output format (plain markdown)
```

#### 5.8.2 Template Application

When SDLC templates are detected, the synthesizer uses them as output format scaffolding:

1. Read the relevant template file(s) matching the deliverable type
2. Extract the `sections` array from YAML frontmatter
3. For each section with `required: true`: ensure the output includes this section
4. For each section with `prompt`: use the prompt as guidance for content generation
5. Preserve the section order from the template
6. Add `[DEVIATION]` tags for any section that departs from template conventions

The pipeline does NOT modify template files. It reads them as format specifications and produces output documents that conform to the template structure.

#### 5.8.3 Tier Selection

| Mode | Default Tier | Override |
|------|-------------|----------|
| analysis | mid | `--template sdlc:max` |
| strategy | mid | `--template sdlc:max` |
| content | min | `--template sdlc:mid` |
| code-project | max (for docs/ scaffolding) | `--template sdlc:min` |

#### 5.8.4 Custom Template Support

The `--template` flag also accepts:
- A file path to a custom template with YAML frontmatter containing `type`, `purpose`, and `sections`
- A directory path containing multiple template files
- The string `none` to explicitly disable template detection

Custom templates must have the same YAML frontmatter structure as SDLC templates:

```yaml
---
type: {document-type}
purpose: {one-line description}
sections:
  - name: {section-name}
    required: true|false
    prompt: {guidance text}
---
```

This makes the system extensible to any documentation standard, not just SDLC.

#### 5.8.5 Automation Config Integration

A new optional config section is added at v5.4.0:

| Section | Keys | Default |
|---------|------|---------|
| Document Templates | Template path, Default tier, Custom templates path | (none), mid, (none) |

This allows projects to set a default template without requiring the `--template` flag on every invocation.

---

## 6. Agent Roster

### 6.1 Existing Agents (18 -- unchanged)

All 18 existing agents retain their current file paths, frontmatter, Goal, Expertise, Process, and Constraints sections without modification. The complete list:

| Agent | Model | Type | File |
|-------|-------|------|------|
| triage-analyst | sonnet | read-only | `agents/triage-analyst.md` |
| code-analyst | sonnet | read-only | `agents/code-analyst.md` |
| fixer | opus | execution | `agents/fixer.md` |
| reviewer | opus | read-only | `agents/reviewer.md` |
| acceptance-gate | sonnet | read-only | `agents/acceptance-gate.md` |
| test-engineer | sonnet | execution | `agents/test-engineer.md` |
| e2e-test-engineer | sonnet | execution | `agents/e2e-test-engineer.md` |
| publisher | haiku | execution | `agents/publisher.md` |
| rollback-agent | haiku | execution | `agents/rollback-agent.md` |
| spec-analyst | sonnet | read-only | `agents/spec-analyst.md` |
| architect | opus | read-only | `agents/architect.md` |
| stack-selector | sonnet | read-only | `agents/stack-selector.md` |
| scaffolder | sonnet | execution | `agents/scaffolder.md` |
| priority-engine | opus | read-only | `agents/priority-engine.md` |
| spec-writer | opus | execution | `agents/spec-writer.md` |
| spec-reviewer | opus | read-only | `agents/spec-reviewer.md` |
| reproducer | sonnet | execution | `agents/reproducer.md` |
| browser-verifier | sonnet | execution | `agents/browser-verifier.md` |

### 6.2 New Agent: intake-agent

**File:** `agents/intake-agent.md`
**Introduced:** v5.3.0 (PR 5)

```yaml
---
name: intake-agent
description: Ingests and structures input from diverse sources (URLs, documents, pasted text, files) for pipeline processing
model: sonnet
style: Methodical, thorough, format-agnostic
---
```

**Goal:** Transform heterogeneous input (URLs, PDFs, pasted text, file sets, conversation transcripts, issue tracker tickets) into a structured input summary that downstream agents can consume uniformly.

**Expertise:** Multi-format parsing, information extraction, source cataloging, input quality assessment, deduplication of overlapping sources.

**Process:**
1. Identify the input type(s) provided:
   - Issue tracker reference → query via MCP (same as triage-analyst)
   - URL → fetch and extract content (use WebFetch if available, else note as inaccessible)
   - File path(s) → read file contents
   - Pasted text → accept as-is
   - Directory path → inventory files, read key files (README, index, config)
2. For each input source, extract:
   - Source type and location
   - Key content summary (max 500 words per source)
   - Relevant metadata (dates, authors, versions, format)
   - Quality assessment (complete, partial, unclear, contradictory)
3. Produce a structured input summary:
   - `sources`: list of {type, location, summary, quality}
   - `combined_context`: unified narrative of all inputs (max 2000 words)
   - `key_entities`: extracted names, terms, concepts
   - `ambiguities`: list of unclear or contradictory elements across sources
   - `suggested_scope`: preliminary scope based on input analysis
4. If no usable input can be extracted: Block with reason "No actionable input could be extracted from provided sources"

**Constraints:**
- NEVER modify any input source
- NEVER hallucinate content not present in sources
- NEVER exceed 2000 words in combined_context
- If a source is inaccessible, note it as `quality: inaccessible` and continue with remaining sources
- Maximum 20 sources per invocation

### 6.3 New Agent: domain-analyst

**File:** `agents/domain-analyst.md`
**Introduced:** v5.3.0 (PR 5)

```yaml
---
name: domain-analyst
description: Performs analytical and strategic reasoning on structured input to produce domain-specific findings
model: opus
style: Rigorous, evidence-based, balanced
---
```

**Goal:** Analyze structured input to produce domain-specific findings, insights, and recommendations. Handle both analytical reasoning (data/evidence-driven) and strategic reasoning (option/scenario-driven) based on the domain context provided by the mode adapter.

**Expertise:** Statistical claim assessment, methodological evaluation, causal reasoning, scenario analysis, competitive landscape analysis, stakeholder mapping, SWOT/PESTLE frameworks, hypothesis testing structure, evidence quality evaluation.

**Process:**
1. Read the intake summary and scope document from previous phases
2. Identify the analytical framework appropriate to the domain context:
   - If analysis mode: hypothesis-evidence-conclusion structure
   - If strategy mode: options-criteria-assessment structure
   - If content mode: research-organize-outline structure
3. For each key question or objective from the scope:
   a. Gather relevant evidence from the intake summary
   b. Assess evidence quality (primary/secondary, sample size, recency, source credibility)
   c. Apply appropriate analytical method
   d. Document findings with explicit evidence links
   e. Rate confidence: HIGH (strong evidence, clear reasoning), MEDIUM (adequate evidence, some assumptions), LOW (limited evidence, significant uncertainty)
4. Identify cross-cutting themes, contradictions, and gaps
5. Produce findings document:
   - `findings`: list of {question, evidence, method, conclusion, confidence}
   - `themes`: cross-cutting patterns
   - `gaps`: identified information gaps
   - `risks`: identified risks or uncertainties
   - `recommendations`: actionable next steps (max 10)
6. If evidence is insufficient to address any key question: note as a gap, do NOT fabricate findings

**Constraints:**
- NEVER present correlation as causation without explicit qualification
- NEVER suppress contradictory evidence
- NEVER produce findings without citing specific evidence from the intake summary
- NEVER exceed 10 recommendations
- If no evidence is available for a key question, mark it as `confidence: INSUFFICIENT` rather than speculating
- Maximum 5000 words in findings output

### 6.4 New Agent: synthesizer

**File:** `agents/synthesizer.md`
**Introduced:** v5.3.0 (PR 5)

```yaml
---
name: synthesizer
description: Assembles analytical findings into formatted deliverable documents with template compliance
model: sonnet
style: Clear, structured, audience-aware
---
```

**Goal:** Transform domain-analyst findings and reviewer feedback into polished deliverable documents. Handle template compliance (SDLC or custom), output formatting, and iterative revision based on review feedback.

**Expertise:** Document structuring, audience adaptation, template compliance, information hierarchy, executive summary writing, visualization description, cross-reference management.

**Process:**
1. Read the domain-analyst findings and the scope document
2. If a document template is specified (SDLC or custom):
   a. Read template file(s) and extract section structure from YAML frontmatter
   b. Map findings to template sections (required sections must be populated)
   c. For sections with `prompt` guidance: follow the prompt instructions
   d. Add `[DEVIATION]` tag to any section that departs from template conventions
3. If no template: use a default structure:
   - Executive Summary (max 300 words)
   - Background / Context
   - Methodology (for analysis) or Framework (for strategy)
   - Findings / Analysis
   - Recommendations
   - Limitations and Next Steps
   - Appendices (supporting data, sources)
4. Write the document:
   - Executive summary first (standalone, can be read without the rest)
   - Each section with clear headings and progressive detail
   - Evidence citations inline (reference intake summary sources)
   - Confidence qualifiers on all conclusions
   - Tables and bullet lists for scannable data
5. If reviewer feedback is provided (revision loop):
   a. Address each feedback item
   b. Track changes in revision notes
   c. Re-submit for review
6. Produce final output file(s) in the specified output directory

**Constraints:**
- NEVER omit a required template section
- NEVER produce output longer than 10,000 words without user approval
- NEVER remove confidence qualifiers from conclusions
- If template has sections irrelevant to the analysis, include them with a note: "Not applicable to this analysis"
- Maximum 3 revision iterations with reviewer

### 6.5 Model Selection for New Agents

| Agent | Model | Rationale |
|-------|-------|-----------|
| intake-agent | sonnet | Input processing and structuring -- analysis task, not critical decision |
| domain-analyst | opus | Core analytical reasoning requiring depth, rigor, and nuance |
| synthesizer | sonnet | Document assembly and formatting -- structured output, not deep reasoning |

### 6.6 Agent Roster Summary (v5.5.0)

| Category | Count | Agents |
|----------|-------|--------|
| Read-only | 10 | triage-analyst, code-analyst, reviewer, spec-analyst, architect, stack-selector, priority-engine, spec-reviewer, acceptance-gate, domain-analyst |
| Execution | 11 | fixer, test-engineer, e2e-test-engineer, publisher, scaffolder, spec-writer, reproducer, browser-verifier, rollback-agent, intake-agent, synthesizer |
| **Total** | **21** | |

Note: domain-analyst is read-only (produces findings, never modifies files). intake-agent is execution (may fetch URLs, read files). synthesizer is execution (writes output documents).

---

## 7. State Management

### 7.1 Directory Structure

```
.ceos-agents/
  {RUN-ID}/
    state.json
    pipeline.log
    reproduction-result.json     # (if browser reproduction ran)
    reproducer-script.js         # (if browser reproduction ran)
    verification-result.json     # (if browser verification ran)
    screenshots/                 # (if screenshots taken)
```

**RUN-ID determination:**
- For issue tracker pipelines: `RUN-ID = ISSUE-ID` (e.g., `PROJ-123`)
- For non-tracker pipelines (analysis, strategy, content without issue): `RUN-ID = {timestamp}` (format: `YYYYMMDD-HHmmss`)
- For scaffold pipelines without issue: `RUN-ID = scaffold-{timestamp}`

### 7.2 state.json Schema

```json
{
  "schema_version": 1,
  "run_id": "PROJ-123",
  "mode": "code-bugfix",
  "pipeline": "fix-ticket",
  "created_at": "2026-03-22T14:30:00Z",
  "updated_at": "2026-03-22T14:45:00Z",
  "status": "running",

  "config": {
    "profile": null,
    "retry_limits": {
      "fixer_iterations": 5,
      "test_attempts": 3,
      "build_retries": 3,
      "spec_iterations": 5
    },
    "browser_verification_enabled": false,
    "template": null
  },

  "triage": {
    "status": "completed",
    "severity": "HIGH",
    "area": "authentication",
    "complexity": "M",
    "acceptance_criteria": [
      "AC-1: Login fails with valid credentials when session cookie is expired",
      "AC-2: Error message displayed to user is misleading",
      "AC-3: Session renewal should happen automatically"
    ],
    "reproduction_steps": "1. Login with valid credentials\n2. Wait for session expiry\n3. Attempt any authenticated action"
  },

  "code_analysis": {
    "status": "completed",
    "risk": "MEDIUM",
    "affected_files": ["src/auth/session.py", "src/auth/middleware.py"],
    "affected_files_count": 2,
    "estimated_diff_lines": 35,
    "change_area_count": 1
  },

  "reproduction": {
    "status": "skipped",
    "result_path": null
  },

  "fixer_reviewer": {
    "status": "running",
    "iteration": 2,
    "max_iterations": 5,
    "verdicts": [
      {
        "iteration": 1,
        "verdict": "REQUEST_CHANGES",
        "issues_count": 3,
        "ac_fulfillment": {
          "AC-1": "PARTIALLY",
          "AC-2": "FULFILLED",
          "AC-3": "NOT ADDRESSED"
        }
      }
    ],
    "needs_decomposition": false
  },

  "decomposition": {
    "status": "not_applicable",
    "decision": "SINGLE_PASS",
    "subtasks": [],
    "completed_subtasks": []
  },

  "test": {
    "status": "pending",
    "attempt": 0,
    "max_attempts": 3
  },

  "e2e_test": {
    "status": "pending",
    "attempt": 0
  },

  "browser_verification": {
    "status": "skipped",
    "result_path": null
  },

  "acceptance_gate": {
    "status": "pending",
    "should_run": true,
    "verdict": null
  },

  "publisher": {
    "status": "pending",
    "pr_url": null,
    "branch": null
  },

  "hooks": {
    "pre_fix": null,
    "post_fix": null,
    "pre_publish": null,
    "post_publish": null
  },

  "block": null
}
```

### 7.3 Schema Field Definitions

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `schema_version` | integer | Yes | Always `1` for this specification. Enables future schema evolution. |
| `run_id` | string | Yes | Unique identifier for this pipeline run. |
| `mode` | string | Yes | One of: `code-bugfix`, `code-feature`, `code-project`, `analysis`, `strategy`, `content`. |
| `pipeline` | string | Yes | The command or skill that initiated this run (e.g., `fix-ticket`, `build`). |
| `created_at` | ISO 8601 | Yes | When the pipeline run started. |
| `updated_at` | ISO 8601 | Yes | Last state file update timestamp. |
| `status` | string | Yes | One of: `running`, `completed`, `blocked`, `failed`. |
| `config.profile` | string or null | Yes | Active pipeline profile name, or null. |
| `config.retry_limits.*` | integer | Yes | Active retry limits for this run. |
| `config.browser_verification_enabled` | boolean | Yes | Whether browser verification is configured. |
| `config.template` | string or null | Yes | Active document template, or null. |
| `triage.status` | string | Yes | One of: `pending`, `running`, `completed`, `skipped`, `failed`. |
| `triage.acceptance_criteria` | string[] | No | Full AC text, preserved for resume. |
| `triage.complexity` | string | No | XS, S, M, or L. |
| `code_analysis.status` | string | Yes | Same status enum. |
| `code_analysis.risk` | string | No | LOW, MEDIUM, or HIGH. |
| `fixer_reviewer.iteration` | integer | Yes | Current iteration count (1-based). |
| `fixer_reviewer.verdicts` | object[] | No | Per-iteration verdict history. |
| `decomposition.decision` | string | No | DECOMPOSE or SINGLE_PASS. |
| `decomposition.subtasks` | object[] | No | List of subtask objects (mirrors decomposition YAML). |
| `decomposition.completed_subtasks` | string[] | No | List of completed subtask IDs. |
| `block` | object or null | Yes | If blocked: `{agent, step, reason, detail, recommendation}`. |

### 7.4 Atomic Write Protocol

State file writes follow this protocol to prevent corruption:

1. Serialize state to JSON
2. Write to `{RUN-ID}/state.json.tmp`
3. Rename `state.json.tmp` to `state.json` (atomic on all supported platforms)
4. If rename fails: retry once after 100ms
5. If retry fails: log error to pipeline.log, continue execution (state loss is non-fatal)

### 7.5 Event Log Format

The `pipeline.log` file is an append-only file with one JSON object per line (JSONL format):

```json
{"ts":"2026-03-22T14:30:00Z","event":"pipeline_start","run_id":"PROJ-123","mode":"code-bugfix","pipeline":"fix-ticket"}
{"ts":"2026-03-22T14:30:05Z","event":"phase_start","phase":"triage","agent":"triage-analyst"}
{"ts":"2026-03-22T14:31:20Z","event":"phase_complete","phase":"triage","agent":"triage-analyst","duration_s":75}
{"ts":"2026-03-22T14:31:21Z","event":"phase_start","phase":"code_analysis","agent":"code-analyst"}
{"ts":"2026-03-22T14:32:00Z","event":"phase_complete","phase":"code_analysis","agent":"code-analyst","duration_s":39}
{"ts":"2026-03-22T14:32:01Z","event":"fixer_iteration","iteration":1,"verdict":"REQUEST_CHANGES"}
{"ts":"2026-03-22T14:35:00Z","event":"fixer_iteration","iteration":2,"verdict":"APPROVED"}
{"ts":"2026-03-22T14:40:00Z","event":"pipeline_complete","run_id":"PROJ-123","status":"completed","pr_url":"..."}
```

**Event types:**

| Event | Fields | When |
|-------|--------|------|
| `pipeline_start` | `run_id`, `mode`, `pipeline` | Pipeline begins |
| `pipeline_complete` | `run_id`, `status`, `pr_url` (if applicable) | Pipeline ends |
| `phase_start` | `phase`, `agent` | Phase begins |
| `phase_complete` | `phase`, `agent`, `duration_s` | Phase ends successfully |
| `phase_skip` | `phase`, `reason` | Phase skipped (profile/config) |
| `phase_fail` | `phase`, `agent`, `error` | Phase fails |
| `fixer_iteration` | `iteration`, `verdict` | Each fixer-reviewer loop iteration |
| `block` | `agent`, `step`, `reason` | Pipeline blocked |
| `state_write` | `field`, `value` | State file updated |
| `hook_execute` | `hook_name`, `result` | Hook executed |
| `resume` | `resume_point`, `source` | Pipeline resumed (source: `state` or `heuristic`) |

### 7.6 Resume Logic

When `resume-ticket` or `/build --resume` is invoked:

```
1. Check for .ceos-agents/{RUN-ID}/state.json
   a. If exists and parseable:
      - Read status, mode, pipeline
      - Determine resume point from phase statuses:
        - Find the first phase with status != "completed" and status != "skipped"
        - Resume from that phase
      - Restore context: AC list, complexity, profile, iteration counts
      - Log event: {"event": "resume", "resume_point": "...", "source": "state"}
   b. If exists but corrupted:
      - Log warning
      - Fall through to heuristic

2. If state.json does not exist (pre-migration ticket):
   - Use resume-ticket's existing 7-level heuristic:
     1. DECOMPOSE_PARTIAL
     2. PUBLISHED
     3. POST_REVIEW
     4. POST_FIX
     5. POST_ANALYSIS
     6. POST_TRIAGE
     7. FRESH
   - Log event: {"event": "resume", "resume_point": "...", "source": "heuristic"}
   - Note: iteration counts are NOT restored (reset to 0)

3. The heuristic fallback is preserved indefinitely.
   It is NOT removed in any version specified by this specification.
```

### 7.7 Backward Compatibility with .claude/decomposition/

The existing `.claude/decomposition/{ISSUE-ID}.yaml` path continues to be READ (not written) for backward compatibility:

- If `state.json` has `decomposition.subtasks` populated: use state.json
- If `state.json` has empty `decomposition.subtasks` AND `.claude/decomposition/{ISSUE-ID}.yaml` exists: read YAML, populate state.json, continue
- New runs ONLY write to `state.json` (no new `.claude/decomposition/*.yaml` files created)
- The YAML reading code path is preserved indefinitely

### 7.8 Browser Artifact Migration

Browser-related artifacts move from shared paths to per-issue paths:

| Old Path | New Path | Migration |
|----------|----------|-----------|
| `.claude/reproduction-result.json` | `.ceos-agents/{RUN-ID}/reproduction-result.json` | New writes go to new path; old path checked as fallback |
| `.claude/reproducer-script.js` | `.ceos-agents/{RUN-ID}/reproducer-script.js` | Same |
| `.claude/verification-result.json` | `.ceos-agents/{RUN-ID}/verification-result.json` | Same |
| `.claude/screenshots/{issue-id}-*.png` | `.ceos-agents/{RUN-ID}/screenshots/{issue-id}-*.png` | Same |

This resolves the race condition in fix-bugs parallel worktree mode where concurrent browser runs clobbered each other's results.

---

## 8. Backward Compatibility

### 8.1 Iron Rules

These rules are absolute and apply to all PRs in the migration:

1. **No command removed.** All 24 commands remain at their current paths with their current invocation names.
2. **No command renamed.** The `ceos-agents:` prefix and command names are immutable.
3. **No agent removed.** All 18 existing agents remain at their current paths.
4. **No agent renamed.** Agent file names and frontmatter `name` fields are immutable.
5. **No config section removed.** All existing Automation Config sections remain valid.
6. **No config section renamed.** Section headers and key names are immutable.
7. **No comment format modified.** The `[ceos-agents]` prefix and all 23 Class C comment templates are immutable.
8. **No pipeline profile stage name modified.** Stage names (triage, code-analyst, spec-analyst, test-engineer, e2e-test-engineer, reproducer, browser-verifier) are immutable.
9. **No required config key added.** All new config sections are optional with defaults.
10. **No MAJOR version bump.** The entire migration is additive MINOR/PATCH.

### 8.2 Preserved Contracts

| Contract | Location | Preserved |
|----------|----------|-----------|
| `maps_to: AC-{N}: {text}` output format | architect.md | Yes -- no modification |
| `[ceos-agents] 🔴 Pipeline Block` comment | 15 locations | Yes -- no modification |
| `[ceos-agents] Triage completed.` comment | triage-analyst, analyze-bug | Yes -- no modification |
| `ceos-agents:` namespace in plugin.json | .claude-plugin/plugin.json | Yes -- no modification |
| `sub-{N}` subtask ID format | architect.md | Yes -- no modification |
| Decomposition YAML read path | `.claude/decomposition/` | Yes -- read preserved indefinitely |
| Resume-ticket 7-level heuristic | resume-ticket.md | Yes -- preserved as fallback |
| Agent Overrides `{path}/{agent-name}.md` | All commands | Yes -- works for all 21 agents (18 existing + 3 new) |
| Rollback-agent read-only skip list | rollback-agent.md | Yes -- updated to include domain-analyst |
| Discuss default panel agents | discuss.md | Yes -- `architect` remains in defaults |

### 8.3 Versioning Policy Continuation

The existing versioning policy from CLAUDE.md applies without modification:

| Level | Trigger |
|-------|---------|
| MAJOR | New required config key, renamed section, breaking agent output format |
| MINOR | New optional config key, new command/agent/skill |
| PATCH | Behavior fix without contract change |

### 8.4 New Additive Elements

| Element | Version | Type |
|---------|---------|------|
| `.ceos-agents/` state directory | v5.2.0 | MINOR -- new runtime artifact |
| `core/` pattern files | v5.2.x | PATCH -- internal refactor |
| `/build` skill | v5.3.0 | MINOR -- new skill |
| intake-agent, domain-analyst, synthesizer | v5.3.0 | MINOR -- new agents |
| Document Templates config section | v5.4.0 | MINOR -- new optional section |
| Analysis mode | v5.4.0 | MINOR -- new mode |
| Strategy mode, content mode | v5.5.0 | MINOR -- new modes |
| `[ceos-agents] Analysis REVIEWED.` comment | v5.4.0 | MINOR -- new comment type |

---

## 9. Documentation Plan

### 9.1 README.md Rewrite (v5.3.0)

The README.md is updated to reflect the unified pipeline capability. Key changes:

**Quick Start section:**
- Add `/build` as the primary entry point alongside existing commands
- Show a 3-step quick start: install, configure, run
- Example: `ceos-agents:build PROJ-123` for bugfix, `ceos-agents:build "Analyze security posture"` for analysis

**Architecture section:**
- Add a simplified system diagram showing: User -> /build or /commands -> core patterns -> agents -> output
- Mention the 3-layer system: skills + commands (orchestration), core (shared patterns), agents (specialists)

**Mode overview:**
- Table of 6 modes with one-line descriptions
- Link to `docs/reference/build-command.md` for details

**Agent count update:**
- Update from "18 agent definitions" to "21 agent definitions"
- Update model selection table with new agents

### 9.2 docs/reference/build-command.md (NEW, v5.3.0)

Complete reference for the `/build` skill:
- Command signature with all flags
- Mode detection algorithm (human-readable)
- Per-mode phase sequence tables
- SDLC template integration guide
- Examples for each mode
- Relationship to existing commands (not a replacement, parallel path)

### 9.3 docs/reference/state-management.md (NEW, v5.2.0)

Complete reference for state management:
- state.json schema with field descriptions
- Event log format
- Resume logic (state-based and heuristic fallback)
- Per-issue directory structure
- Atomic write protocol
- Troubleshooting (corrupted state, missing state, migration from pre-state tickets)

### 9.4 docs/architecture.md Update (v5.3.0)

Updated architecture document:
- Mermaid diagram: system overview (skills + commands + core + agents)
- Mermaid diagram: pipeline flow for code-bugfix mode
- Mermaid diagram: pipeline flow for analysis mode
- Mermaid diagram: state lifecycle (created -> running -> completed/blocked/failed)
- Mermaid diagram: mode detection flowchart
- Data flow section: what data moves between pipeline phases
- Extension points: how to add new modes, new agents, new document templates

### 9.5 examples/workflows/ (NEW, v5.3.0+)

Concrete workflow examples showing real usage:

| File | Version | Content |
|------|---------|---------|
| `code-bugfix-workflow.md` | v5.3.0 | Step-by-step bugfix with `/build`, showing state transitions |
| `code-feature-workflow.md` | v5.3.0 | Feature implementation with `/build`, showing decomposition |
| `analysis-workflow.md` | v5.4.0 | Analysis pipeline with SDLC template integration |
| `strategy-workflow.md` | v5.5.0 | Strategy document creation |
| `content-workflow.md` | v5.5.0 | Content creation pipeline |

Each workflow example includes:
- User's starting input
- Mode detection output
- Each phase with sample agent output (abbreviated)
- Final deliverable
- state.json at key pipeline points

### 9.6 examples/configs/ Expansion (v5.4.0)

New config examples:

| File | Content |
|------|---------|
| `config-with-templates.md` | Automation Config with Document Templates section |
| `config-analysis-mode.md` | Config for a project that primarily uses analysis mode |
| `config-multi-mode.md` | Config for a project using code + analysis modes |

### 9.7 docs/getting-started.md Update (v5.5.0)

Updated to address discoverability (user concern about complexity):

**"Choose Your Path" section:**
- Flowchart: "What do you want to do?" -> mode selection -> relevant command/skill
- Explicit guidance: "If you want to fix bugs, start with `/fix-ticket`. If you want to try the unified pipeline, use `/build`."
- Link to workflow examples for each path

**Progressive Disclosure:**
- Level 1 (5 minutes): Install, run `/check-setup`, fix first bug with `/fix-ticket`
- Level 2 (15 minutes): Understand pipeline phases, configure profiles, use `/build`
- Level 3 (30 minutes): Non-code modes, SDLC templates, custom agent overrides
- Level 4 (advanced): State management, custom templates, multi-mode workflows

### 9.8 Discoverability Strategy

To address the user concern about the plugin becoming complex for new users:

1. **Single entry point prominence:** `/build` is presented as the "if in doubt, start here" command. It auto-detects mode and confirms with the user.
2. **Existing commands preserved:** Users who know `/fix-ticket` can continue using it. No forced migration.
3. **Progressive disclosure in docs:** Getting-started guide uses a 4-level learning path.
4. **`/check-setup` enhanced:** At v5.3.0, `/check-setup` reports available modes and suggests the most relevant one based on project configuration.
5. **`/status` enhanced:** Shows available pipelines and recently used modes.
6. **Workflow examples:** Concrete, copy-pasteable examples for each mode.

---

## 10. Migration Sequence

### 10.1 PR 0: Pre-existing Bug and Gap Fixes (v5.1.x PATCH)

**Gate:** None (independent)
**Version bump:** v5.1.x PATCH

**File changes:**

| Action | File | Change |
|--------|------|--------|
| Fix | `agents/reproducer.md` | Write reproduction-result.json to `.ceos-agents/{ISSUE-ID}/` instead of `.claude/` |
| Fix | `agents/browser-verifier.md` | Write verification-result.json to `.ceos-agents/{ISSUE-ID}/` instead of `.claude/` |
| Fix | `commands/fix-bugs.md` | Update artifact paths for parallel mode; create `.ceos-agents/{ISSUE-ID}/` directory |
| Fix | `commands/fix-ticket.md` | Update artifact paths to `.ceos-agents/{ISSUE-ID}/` |
| Fix | `commands/implement-feature.md` | Update artifact paths to `.ceos-agents/{ISSUE-ID}/` |
| Fix | `agents/spec-writer.md` | Add missing emoji: `[ceos-agents] Pipeline Block` -> `[ceos-agents] 🔴 Pipeline Block` |
| Fix | `skills/bug-workflow/SKILL.md` | Add `discuss` entry to intent mapping table |
| Update | `tests/scenarios/happy-path.sh` | Replace static filename lists with dynamic inventory checks |
| Update | `tests/scenarios/verify-fail.sh` | Remove step-number coupling (9d, 8c, 10b) |
| Update | `tests/scenarios/pipeline-consistency.sh` | Make PIPELINE_FILES discoverable via grep instead of hardcoded list |
| Add | `tests/scenarios/frontmatter-completeness.sh` | Verify all agents have name, description, model, style in frontmatter |
| Add | `tests/scenarios/model-assignment.sh` | Validate model assignments match CLAUDE.md table |
| Add | `tests/scenarios/read-only-agents.sh` | Verify read-only agents contain no file-write phrases |
| Add | `tests/scenarios/section-order.sh` | Verify Goal/Expertise/Process/Constraints order in all agents |

**Rollback:** `git revert`. No structural changes. All changes are independent fixes.

**Estimated size:** ~200 lines changed.

### 10.2 PR 1: State Infrastructure (v5.2.0 MINOR)

**Gate:** GATE 1 -- Validate state infrastructure works with all 3 pipeline commands.
**Version bump:** v5.2.0 MINOR

**File changes:**

| Action | File | Change |
|--------|------|--------|
| Add | `core/state-manager.md` | State file read/write/resume contract (Section 4.11) |
| Add | `state/schema.md` | State.json schema documentation (Section 7.2) |
| Update | `commands/fix-ticket.md` | Add state.json writes at each phase transition |
| Update | `commands/fix-bugs.md` | Add state.json writes at each phase transition |
| Update | `commands/implement-feature.md` | Add state.json writes at each phase transition |
| Update | `commands/scaffold.md` | Add state.json writes at each phase transition |
| Update | `commands/resume-ticket.md` | Prefer state.json, fall back to heuristic |
| Add | `tests/scenarios/state-schema.sh` | Verify state.json schema documentation has all required fields |
| Add | `docs/reference/state-management.md` | State management reference document |
| Update | `CLAUDE.md` | Document `.ceos-agents/` directory in Repository Structure |

**Rollback:** `git revert`. State.json is additive; heuristic fallback remains functional. Resume-ticket continues working via heuristic for any ticket that lacks a state file.

**Estimated size:** ~400 lines changed.

### 10.3 PR 2: Core Pattern Extraction -- Proof of Concept (v5.2.x PATCH)

**Gate:** Part of GATE 2
**Version bump:** v5.2.x PATCH

**File changes:**

| Action | File | Change |
|--------|------|--------|
| Add | `core/config-reader.md` | Config parsing pattern (Section 4.2) |
| Add | `core/mcp-preflight.md` | MCP preflight check (Section 4.3) |
| Add | `core/fixer-reviewer-loop.md` | Fixer-reviewer iteration loop (Section 4.4) |
| Add | `core/block-handler.md` | Block handling pattern (Section 4.5) |
| Add | `core/agent-override-injector.md` | Agent override loading (Section 4.6) |
| Add | `core/decomposition-heuristics.md` | Decomposition decision (Section 4.7) |
| Add | `core/profile-parser.md` | Pipeline profile parsing (Section 4.8) |
| Add | `core/post-publish-hook.md` | Post-publish execution (Section 4.9) |
| Add | `core/fix-verification.md` | Fix verification (Section 4.10) |
| Update | `commands/fix-ticket.md` | Refactor to reference core/ files instead of inline logic |
| Add | `tests/scenarios/core-include-refs.sh` | Verify core files exist and are referenced by commands |

**Rollback:** `git revert`. fix-ticket returns to inline logic; core/ directory deleted.

**Estimated size:** ~450 lines added (core files), ~100 lines net change in fix-ticket.

### 10.4 PR 3: Extend Core Extraction to Remaining Commands (v5.2.x PATCH)

**Gate:** Completes GATE 2
**Version bump:** v5.2.x PATCH

**File changes:**

| Action | File | Change |
|--------|------|--------|
| Update | `commands/fix-bugs.md` | Refactor to reference core/ files |
| Update | `commands/implement-feature.md` | Refactor to reference core/ files |
| Update | `commands/scaffold.md` | Refactor to reference core/ files (where applicable) |

**Rollback:** Per-command revert possible. Each command can be independently rolled back.

**Estimated size:** ~300 lines net change.

### 10.5 PR 4: /build Skill with Code Modes (v5.3.0 MINOR)

**Gate:** Part of GATE 3
**Version bump:** v5.3.0 MINOR

**File changes:**

| Action | File | Change |
|--------|------|--------|
| Add | `skills/build/SKILL.md` | Unified entry point skill (Section 3) |
| Add | `skills/build/mode-code-bugfix.md` | Code bugfix mode adapter (Section 5.2) |
| Add | `skills/build/mode-code-feature.md` | Code feature mode adapter (Section 5.3) |
| Add | `skills/build/mode-code-project.md` | Code project mode adapter (Section 5.4) |
| Update | `skills/bug-workflow/SKILL.md` | Add build routing row |
| Update | `.claude-plugin/plugin.json` | Update description |
| Update | `.claude-plugin/marketplace.json` | Update description |
| Update | `README.md` | Quick start, architecture, mode overview (Section 9.1) |
| Add | `docs/reference/build-command.md` | Build skill reference (Section 9.2) |
| Update | `docs/architecture.md` | Mermaid diagrams, data flow (Section 9.4) |
| Add | `examples/workflows/code-bugfix-workflow.md` | Bugfix workflow example |
| Add | `examples/workflows/code-feature-workflow.md` | Feature workflow example |
| Add | `tests/scenarios/build-skill-structure.sh` | /build skill file structure check |
| Add | `tests/scenarios/build-mode-detection.sh` | Mode adapter presence check |
| Update | `CLAUDE.md` | Update repository structure, agent count, architecture description |

**Rollback:** Delete skill files and new docs. Existing commands unaffected. Revert CLAUDE.md and README.md changes.

**Estimated size:** ~500 lines added.

### 10.6 PR 5: New Agents for Non-Code Modes (v5.3.x PATCH)

**Gate:** Part of GATE 3
**Version bump:** v5.3.x PATCH

**File changes:**

| Action | File | Change |
|--------|------|--------|
| Add | `agents/intake-agent.md` | Intake agent (Section 6.2) |
| Add | `agents/domain-analyst.md` | Domain analyst agent (Section 6.3) |
| Add | `agents/synthesizer.md` | Synthesizer agent (Section 6.4) |
| Update | `agents/rollback-agent.md` | Add domain-analyst to read-only skip list |
| Add | `tests/scenarios/new-agent-structure.sh` | Structural checks for 3 new agents |
| Update | `docs/reference/agents.md` | Add 3 new agents to reference |
| Update | `CLAUDE.md` | Update agent count to 21, add to model selection table |

**Rollback:** Delete new agent files. Revert rollback-agent.md, reference docs, and CLAUDE.md changes.

**Estimated size:** ~350 lines added.

### 10.7 PR 6: Analysis Mode (v5.4.0 MINOR)

**Gate:** Part of GATE 3
**Version bump:** v5.4.0 MINOR

**File changes:**

| Action | File | Change |
|--------|------|--------|
| Add | `skills/build/mode-analysis.md` | Analysis mode adapter (Section 5.5) |
| Update | `docs/reference/build-command.md` | Add analysis mode documentation |
| Update | `docs/reference/pipelines.md` | Add analysis pipeline |
| Update | `docs/reference/automation-config.md` | Add Document Templates optional section |
| Add | `examples/workflows/analysis-workflow.md` | Analysis workflow example |
| Add | `examples/configs/config-with-templates.md` | Config with Document Templates |
| Add | `examples/configs/config-analysis-mode.md` | Analysis mode config |

**Rollback:** Delete mode file and new docs. Code modes unaffected.

**Estimated size:** ~350 lines added.

### 10.8 PR 7: Strategy + Content Modes (v5.5.0 MINOR)

**Gate:** Completes GATE 3
**Version bump:** v5.5.0 MINOR

**File changes:**

| Action | File | Change |
|--------|------|--------|
| Add | `skills/build/mode-strategy.md` | Strategy mode adapter (Section 5.6) |
| Add | `skills/build/mode-content.md` | Content mode adapter (Section 5.7) |
| Update | `docs/reference/build-command.md` | Add strategy and content mode documentation |
| Update | `docs/reference/pipelines.md` | Add strategy and content pipelines |
| Add | `examples/workflows/strategy-workflow.md` | Strategy workflow example |
| Add | `examples/workflows/content-workflow.md` | Content workflow example |
| Add | `examples/configs/config-multi-mode.md` | Multi-mode config |
| Update | `docs/getting-started.md` | "Choose Your Path" section, progressive disclosure (Section 9.7) |
| Update | `README.md` | Final mode overview with all 6 modes |

**Rollback:** Delete mode files and new docs. Analysis and code modes unaffected.

**Estimated size:** ~450 lines added.

### 10.9 Gate Definitions

**GATE 1 (after PR 1):**
- All pipeline commands (fix-ticket, fix-bugs, implement-feature, scaffold) write state.json
- resume-ticket reads state.json and falls back to heuristic
- State schema test passes
- Full test suite green

**GATE 2 (after PR 3):**
- All 4 pipeline commands reference core/ files
- core-include-refs test passes
- Full test suite green
- Manual validation: run `fix-ticket --dry-run` and verify core file references are followed

**GATE 3 (after PR 7):**
- All 6 modes functional in `/build` skill
- All new agent structural tests pass
- Full test suite green
- User acceptance testing: run at least one pipeline per mode (code-bugfix, code-feature, analysis)

### 10.10 Timeline Estimate

| PR | Dependencies | Estimated Days |
|----|-------------|----------------|
| PR 0 | None | 1-2 |
| PR 1 | PR 0 | 2-3 |
| PR 2 | PR 1 (GATE 1) | 2-3 |
| PR 3 | PR 2 | 1-2 |
| PR 4 | PR 3 (GATE 2) | 2-3 |
| PR 5 | PR 4 | 1-2 |
| PR 6 | PR 5 | 1-2 |
| PR 7 | PR 6 | 1-2 |
| **Total** | | **11-19 working days** |

### 10.11 Explicitly Excluded from This Migration

The following items are NOT in scope for v5.1.x through v5.5.0:

1. **Command deprecation timelines.** No command is deprecated.
2. **Architect-to-planner rename.** The architect agent is not renamed.
3. **Runtime engine abstraction.** No "pipeline engine" -- core files are textual patterns.
4. **Per-phase output JSON files.** No triage.json, analysis.json, etc. State.json captures essential data.
5. **Mock-MCP-server wiring.** Integration test infrastructure is a separate initiative.
6. **Heuristic fallback removal.** The 7-level heuristic in resume-ticket is preserved indefinitely.
7. **Command-to-skill migration** (beyond `/build`). Utility commands stay as commands.

---

*End of Requirements Specification*
