# Proposal 1: The Conservative Approach (Dr. Heinrich Bauer)

## Philosophy

I have watched three decades of migrations fail for the same reason: the team rewrites working code to make the architecture "clean," introduces a hundred subtle regressions, and spends the next year apologizing. My guiding principles for this migration:

1. **Never break a running pipeline.** If a user has `/ceos-agents:fix-ticket PROJ-42` in their CI scripts, shell history, or muscle memory, it must keep working for at least two minor releases after a replacement exists.
2. **One structural change per PR.** Each PR must be independently revertible. If PR #7 causes a regression, reverting it must not undo the gains of PRs #1-6.
3. **Prove the new path before deprecating the old.** No command is deprecated until its replacement has been shipping for at least one release cycle with zero reported regressions.
4. **The comment prefix `[ceos-agents]` is permanent.** The research confirms 23 Class C immutable templates in users' issue trackers. We already lived through the `[CLAUDE-agents]` rename. Never again. The prefix stays forever.
5. **State infrastructure before structural migration.** The research is unambiguous: stage-number coupling in `resume-ticket`, state loss on session boundaries, and `.claude/` race conditions must be fixed before touching the pipeline structure.
6. **Tests are the canary, not the obstacle.** Fix fragile tests first so they become real regression detectors, not noise generators.

Success metric: an existing ceos-agents v5.1.0 user upgrades to the unified plugin, runs their usual commands, and notices *nothing* changed. The new capabilities are purely additive.

---

## 1. Directory Structure

### Target State (end of migration)

```
ceos-agents/                          # Plugin name unchanged
├── .claude-plugin/
│   ├── plugin.json                   # name: "ceos-agents" (unchanged)
│   └── marketplace.json
├── agents/                           # 18 existing agents (unchanged paths)
│   ├── acceptance-gate.md
│   ├── architect.md                  # Gains mode-aware section (ceos vs forge)
│   ├── browser-verifier.md
│   ├── code-analyst.md
│   ├── e2e-test-engineer.md
│   ├── fixer.md
│   ├── priority-engine.md
│   ├── publisher.md
│   ├── reproducer.md
│   ├── reviewer.md
│   ├── rollback-agent.md
│   ├── scaffolder.md
│   ├── spec-analyst.md               # Unchanged — NOT merged with spec-writer
│   ├── spec-reviewer.md
│   ├── spec-writer.md
│   ├── stack-selector.md
│   ├── test-engineer.md
│   └── triage-analyst.md
├── agents/modes/                     # NEW: mode-specific agent variants
│   ├── analysis-reviewer.md          # Reviewer with analytical domain checklists
│   ├── strategy-reviewer.md          # Reviewer with strategy domain checklists
│   ├── content-reviewer.md           # Reviewer with content domain checklists
│   ├── analysis-spec-writer.md       # Spec-writer with analytical output template
│   ├── strategy-spec-writer.md       # Spec-writer with strategy output template
│   └── content-spec-writer.md        # Spec-writer with content output template
├── commands/                         # 24 existing commands (unchanged paths)
│   ├── fix-ticket.md                 # Refactored to use core/ includes
│   ├── fix-bugs.md
│   ├── implement-feature.md
│   ├── scaffold.md
│   └── ... (20 utility commands, unchanged)
├── core/                             # NEW: extracted shared infrastructure
│   ├── config-reader.md              # Shared config reading logic
│   ├── mcp-preflight.md              # MCP pre-flight check
│   ├── fixer-reviewer-loop.md        # Fixer<->reviewer loop contract
│   ├── block-handler.md              # Block + rollback dispatch
│   ├── agent-override-injector.md    # Agent Override loading
│   ├── decomposition-heuristics.md   # Shared decomposition thresholds
│   ├── profile-parser.md             # Pipeline profile parsing (shared header)
│   ├── post-publish-hook.md          # Post-publish hook + webhook
│   ├── fix-verification.md           # Post-merge verification
│   └── state-manager.md              # State file read/write contract
├── skills/
│   ├── bug-workflow/                 # Existing skill (unchanged, gains /build routing)
│   │   └── skill.md
│   └── build/                        # NEW: unified /build entry point
│       ├── SKILL.md                  # Mode detection + dispatch
│       ├── mode-code-feature.md      # Code-feature adapter (wraps implement-feature)
│       ├── mode-code-bugfix.md       # Code-bugfix adapter (wraps fix-ticket)
│       ├── mode-code-project.md      # Code-project adapter (wraps scaffold)
│       ├── mode-analysis.md          # Analysis adapter
│       ├── mode-strategy.md          # Strategy adapter
│       └── mode-content.md           # Content adapter
├── state/                            # NEW: state schema definitions
│   └── schema.md                     # State file schema documentation
├── tests/
│   ├── harness/
│   │   ├── run-tests.sh
│   │   ├── mock-mcp-server.sh
│   │   └── fixtures/
│   ├── scenarios/                    # Updated + new scenarios
│   │   ├── happy-path.sh            # Updated: dynamic inventory
│   │   ├── verify-fail.sh           # Updated: remove step-number coupling
│   │   ├── pipeline-consistency.sh  # Updated: discoverable pipeline files
│   │   ├── frontmatter-completeness.sh  # NEW
│   │   ├── model-assignment.sh          # NEW
│   │   ├── read-only-agents.sh          # NEW
│   │   ├── section-order.sh             # NEW
│   │   ├── state-schema.sh              # NEW: validate state file schema
│   │   ├── core-include-refs.sh         # NEW: validate core/ references
│   │   └── ... (existing scenarios)
│   └── mock-project/
├── docs/
├── checklists/
└── examples/
```

### Key Decisions

**Agents stay at `agents/*.md`.** No agent is moved. No agent is renamed. The `customization/{agent-name}.md` Agent Override convention continues to work without any change. The `rollback-agent.md` skip list (`triage-analyst`, `code-analyst`, `spec-analyst`, `architect`, `stack-selector`) requires zero updates.

**Mode-specific agent variants go to `agents/modes/`.** These are NOT replacements for existing agents. They are additional agents with domain-specific checklists. The `discuss` command's default `--agents reviewer,fixer,architect` continues to work because the original agents are untouched.

**`core/` is a new directory for extracted shared patterns.** These are markdown files containing the shared logic. Commands reference them via prose instruction ("Follow the process defined in `core/fixer-reviewer-loop.md`"). This is the same pattern as `$CLAUDE_SKILL_DIR` sub-files in skills. The core files are not independently invokable — they are inline includes.

**`skills/build/` is the new `/build` entry point.** It coexists with `skills/bug-workflow/`. The old skill continues to route to commands. The new skill routes to mode adapters within its own directory.

**`state/schema.md` documents the state file contract.** The actual state files live in the consuming project at `.ceos-agents/{ISSUE-ID}/state.json` (not in the plugin repo).

---

## 2. Pipeline Engine Design

### Core Principle: Extraction, Not Abstraction

I explicitly reject a "pipeline engine" as a runtime abstraction layer. This is a pure markdown plugin with no runtime code. There is no interpreter, no function dispatch, no import mechanism. What we can do is extract shared *prose patterns* into `core/*.md` files that pipeline commands reference by name.

### Shared Core Files

Each `core/*.md` file defines a self-contained process with:
- A clear **input contract** (what variables must be set before invoking this pattern)
- A clear **output contract** (what variables/state this pattern produces)
- A clear **failure contract** (what happens on error)

#### `core/config-reader.md`

```markdown
# Config Reader

## Input
- CWD must contain a CLAUDE.md with `## Automation Config`

## Process
1. Read CLAUDE.md from CWD
2. Parse the `## Automation Config` section
3. Extract all sections per the Config Contract (see plugin CLAUDE.md)
4. Apply defaults for missing optional sections
5. Store extracted values as named variables for downstream use

## Output
Variables: Type, Instance, Project, Bug_query, State_transitions, On_start_set,
Remote, Base_branch, Branch_naming, PR_labels, PR_template,
Build_command, Test_command, Verify_command,
Fixer_iterations (default:5), Test_attempts (default:3), Build_retries (default:3),
Spec_iterations (default:5), Hooks, Custom_agents, Notifications, Worktrees,
E2E_test, Browser_verification, Error_handling, Extra_labels, Agent_overrides_path,
Feature_workflow, Decomposition, Pipeline_profiles, Metrics, Agent_overrides

## Failure
If CLAUDE.md is missing → STOP: "No CLAUDE.md found. Run /ceos-agents:onboard."
If ## Automation Config is missing → STOP: "No Automation Config. Run /ceos-agents:init."
If required sections missing → STOP with list of missing required sections.
```

#### `core/mcp-preflight.md`

```markdown
# MCP Pre-flight Check

## Input
- Type (from config-reader)

## Process
1. Check that at least one `mcp__*` tool matching the tracker type is accessible
2. If not accessible → STOP with: "MCP server for {Type} is not available.
   Run `/ceos-agents:check-setup` for diagnostics or `/ceos-agents:init` to configure."

## Output
- MCP confirmed available (proceed with pipeline)
```

#### `core/fixer-reviewer-loop.md`

```markdown
# Fixer-Reviewer Loop

## Input
- context: string (assembled by the calling command — bug context, feature spec, or subtask scope)
- acceptance_criteria: list (from triage, spec-analyst, or parent task)
- max_iterations: integer (from config Fixer_iterations, default: 5)
- agent_overrides_path: string (from config, default: "customization/")
- build_command: string (from config)
- build_retries: integer (from config, default: 3)

## Process
1. Load Agent Override for fixer if `{agent_overrides_path}/fixer.md` exists
2. Run ceos-agents:fixer (Task tool, model: opus) with context + AC + override
3. If fixer output contains `## NEEDS_DECOMPOSITION`:
   - Signal NEEDS_DECOMPOSITION to the calling command (caller handles)
   - EXIT this loop
4. Run build_command. Retry up to build_retries on failure.
   If exhausted → signal BUILD_FAILED to caller
5. Load Agent Override for reviewer if `{agent_overrides_path}/reviewer.md` exists
6. Run ceos-agents:reviewer (Task tool, model: opus) with context + AC + override
7. If APPROVE → EXIT loop successfully
8. If REQUEST_CHANGES → increment iteration counter, go to step 2
9. If iteration counter > max_iterations → signal MAX_ITERATIONS_EXCEEDED to caller

## Output
- APPROVED: fixer changes passed review
- NEEDS_DECOMPOSITION: fixer requested decomposition (caller must handle)
- BUILD_FAILED: build command failed after retries
- MAX_ITERATIONS_EXCEEDED: review loop exhausted

## State Updates
- Write iteration count to state file after each iteration
- Write reviewer verdict summary to state file
```

#### `core/block-handler.md`

```markdown
# Block Handler

## Input
- blocking_agent: string (name of the agent that triggered the block)
- reason: string (from the blocking agent's output)
- detail: string (technical output)
- recommendation: string
- issue_id: string
- Type: string (tracker type)
- On_block: string (from Error Handling config, default: "comment")

## Process
1. Format Block Comment per template:
   [ceos-agents] Red-circle Pipeline Block
   Agent: {blocking_agent}
   Step: {current pipeline step}
   Reason: {reason}
   Detail: {detail}
   Recommendation: {recommendation}

2. Post comment to issue tracker via MCP

3. If On_block = "comment" → comment only
   If On_block = "close" → also transition issue state

4. If blocking_agent is fixer, test-engineer, e2e-test-engineer, or reviewer:
   Run ceos-agents:rollback-agent (Task tool, model: haiku) to revert git state

5. Update state file: mark current step as BLOCKED

## Output
- Issue commented and optionally state-transitioned
- Git state reverted (if applicable)
- State file updated
```

#### `core/agent-override-injector.md`

```markdown
# Agent Override Injector

## Input
- agent_name: string
- agent_overrides_path: string (default: "customization/")

## Process
1. Check if file `{agent_overrides_path}/{agent_name}.md` exists
2. If yes: read its contents
3. Append to the agent's Task tool context as:
   "## Project-Specific Instructions\n{contents}"
4. If no: do nothing (silent — this is expected)

## Output
- Augmented context string (or original context unchanged)
```

The remaining `core/` files (`decomposition-heuristics.md`, `profile-parser.md`, `post-publish-hook.md`, `fix-verification.md`, `state-manager.md`) follow the same input/process/output/failure structure.

### How Commands Reference Core Files

Commands reference core files by name in their prose. Example refactoring of `fix-ticket.md`:

**Before (current):**
```markdown
### 0. MCP pre-flight check
Before any pipeline operation, verify MCP tool availability:
- Read Type from Automation Config (Issue Tracker section)
- Check that at least one `mcp__*` tool matching the tracker type is accessible
- If not accessible → STOP with: "MCP server for {Type} is not available. ..."
```

**After (refactored):**
```markdown
### 0. MCP pre-flight check
Follow the process defined in `core/mcp-preflight.md`.
```

This is not an import mechanism. It is a prose reference. The LLM reads the core file when it encounters the reference. This works because:
- Claude Code's Task tool already reads referenced files
- The plugin's `agents/` directory is already discoverable by path
- The `core/` directory follows the same convention

### Mode Adapter Contract

Each mode adapter in `skills/build/` follows this interface:

```markdown
# Mode Adapter: {mode-name}

## Applicability
When to use this mode (detection heuristics)

## Pipeline Phases
Ordered list of phases with:
- Phase name
- Agent(s) used
- Core pattern(s) referenced
- Skip conditions
- Phase-specific configuration

## Input Requirements
What the /build skill must provide to this adapter

## Output Contract
What this adapter produces when the pipeline completes

## State Management
Which state file fields this adapter reads/writes
```

The `/build` skill (`skills/build/SKILL.md`) dispatches to mode adapters based on detection:

```markdown
## Mode Detection

1. If `--mode` flag provided → use that mode
2. If `--new-project` flag → mode = code-project
3. If CWD has no git repo and no source files → mode = code-project
4. Analyze the task description:
   - Technical keywords (build, implement, fix, add, create, deploy, refactor) → mode = code-feature
   - Analytical keywords (analyze, research, investigate, compare, evaluate) → mode = analysis
   - Strategic keywords (plan, strategy, roadmap, prioritize, decide) → mode = strategy
   - Content keywords (write, draft, document, blog, report, presentation) → mode = content
5. Default: code-feature

## Dispatch
Read the appropriate mode adapter file from this skill directory:
- code-feature → mode-code-feature.md
- code-bugfix → mode-code-bugfix.md
- code-project → mode-code-project.md
- analysis → mode-analysis.md
- strategy → mode-strategy.md
- content → mode-content.md

Follow the pipeline phases defined in the adapter.
```

---

## 3. Agent Merge Strategy

### Decision: NO agent merges. Mode dispatch at orchestration level.

The Phase 2 research is clear:

- **spec-analyst + forge spec-writer merge: LOW feasibility.** Incompatible scopes ("NEVER design architecture" vs "includes architecture"). These agents remain separate. The orchestration layer decides which to call.
- **architect + forge planner merge: MEDIUM feasibility.** The research recommends mode-based dispatch. I agree, but I implement it at the *command/skill level*, not inside the agent.

### What Happens to Each Agent

| Agent | Action | Rationale |
|-------|--------|-----------|
| acceptance-gate | UNCHANGED | Read-only, no forge equivalent |
| architect | UNCHANGED + mode context | Command/skill provides mode-aware context. The agent's `maps_to: AC-{N}:` output is preserved exactly. For forge-style decomposition, the calling skill provides forge-format context and the architect adapts its output phrasing (not its core structure). |
| browser-verifier | UNCHANGED | No forge equivalent |
| code-analyst | UNCHANGED | No forge equivalent; not reusable for non-code modes |
| e2e-test-engineer | UNCHANGED | No forge equivalent |
| fixer | UNCHANGED | Core execution agent, identical role in both pipelines |
| priority-engine | UNCHANGED + mode context | For non-code modes, calling skill provides domain-specific dimension definitions in context |
| publisher | UNCHANGED | Mechanical task, identical role |
| reproducer | UNCHANGED | No forge equivalent |
| reviewer | UNCHANGED + mode context | For non-code modes, calling skill provides domain-specific checklists in context |
| rollback-agent | UNCHANGED | Mechanical task, identical role |
| scaffolder | UNCHANGED | Scaffold-specific, no forge equivalent |
| spec-analyst | UNCHANGED | Feature pipeline specific, NOT merged with spec-writer |
| spec-reviewer | UNCHANGED + mode context | For non-code modes, calling skill provides domain-specific REQUIRED sections in context |
| spec-writer | UNCHANGED + mode context | For non-code modes, calling skill provides domain-specific output template in context |
| stack-selector | UNCHANGED | Scaffold-specific |
| test-engineer | UNCHANGED | Core execution agent, identical role |
| triage-analyst | UNCHANGED | Bug pipeline specific |

### New Mode-Specific Agents

For non-code modes that require genuinely different domain expertise (not just different checklists passed to existing agents), new agents are added to `agents/modes/`:

| Agent | Model | Role |
|-------|-------|------|
| `agents/modes/analysis-reviewer.md` | opus | Reviewer variant with analytical domain checklists (statistical validity, methodology, data quality) |
| `agents/modes/strategy-reviewer.md` | opus | Reviewer variant with strategy domain checklists (feasibility, stakeholder impact, competitive analysis) |
| `agents/modes/content-reviewer.md` | opus | Reviewer variant with content domain checklists (audience fit, readability, editorial voice, SEO) |
| `agents/modes/analysis-spec-writer.md` | opus | Spec-writer variant for analytical output (hypothesis-evidence structure, methodology, data sources) |
| `agents/modes/strategy-spec-writer.md` | opus | Spec-writer variant for strategy output (options appraisal, decision criteria, business case) |
| `agents/modes/content-spec-writer.md` | opus | Spec-writer variant for content output (audience, tone, information hierarchy, publication format) |

These are separate agents because the Phase 2 research identifies "analytical domain expertise," "strategy domain expertise," and "content domain expertise" as true capability gaps that cannot be filled by passing different checklists to existing agents. The epistemic posture is fundamentally different.

### Why Not Merge Architect + Forge Planner

The architect's `maps_to: AC-{N}: {text}` format is regex-parsed by 3 consuming commands with **no error on mismatch**. A unified agent with a mode switch introduces drift risk: one mode's output format could inadvertently leak into the other. Two separate agents with clear, immutable output contracts are safer than one agent with two code paths.

However, the forge planner does not exist as a file in this repo. It is part of the forge plugin which is being absorbed. The forge planner's functionality (decompose into phases, no AC mapping) is handled by the `/build` skill's mode adapter, which calls the existing `architect` agent with forge-appropriate context. If the architect's output does not include `maps_to` fields (because the context did not provide acceptance criteria), the consuming code gracefully handles this (the `maps_to` validation is vacuously satisfied when no parent AC exist, per Phase 2 Domain 3).

---

## 4. Command -> Skill Migration

### Decision: Commands stay. Skills are added alongside.

I do NOT migrate commands to skills. I add skills that coexist with commands. Here is why:

1. **The `ceos-agents:` namespace is embedded in ~160 Class B documentation references and user tooling.** Renaming commands to skills changes invocation syntax.
2. **Commands provide explicit `allowed-tools` documentation.** Skills do not. While this is not a functional restriction, it is valuable documentation for understanding what each command can do.
3. **The 20 utility commands (status, check-setup, onboard, etc.) are fine as commands.** They are small, single-purpose, and do not need the skill treatment.
4. **Only the pipeline commands benefit from skill architecture** (the `$CLAUDE_SKILL_DIR` pattern for sub-file includes, mode adapter dispatch).

### Migration Plan

| Command | Action | Timeline |
|---------|--------|----------|
| `fix-ticket` | KEEP as command. Refactor internals to reference `core/*.md`. | Phase 3 (PR #5-7) |
| `fix-bugs` | KEEP as command. Refactor internals to reference `core/*.md`. | Phase 3 (PR #5-7) |
| `implement-feature` | KEEP as command. Refactor internals to reference `core/*.md`. | Phase 3 (PR #5-7) |
| `scaffold` | KEEP as command. Refactor internals to reference `core/*.md`. | Phase 3 (PR #5-7) |
| `resume-ticket` | KEEP as command. Updated to use state file with heuristic fallback. | Phase 2 (PR #4) |
| 19 utility commands | KEEP as commands. No changes. | N/A |
| `bug-workflow` skill | KEEP. Updated to include `/build` routing. | Phase 4 (PR #8) |
| `/build` skill | NEW. Added as `skills/build/SKILL.md`. | Phase 4 (PR #8-10) |

### The `/build` Entry Point

```markdown
---
name: build
description: >
  Use when the user wants to build, analyze, strategize, or create content.
  Unified entry point for all pipeline modes. Triggers on "build me X",
  "analyze Y", "create a strategy for Z", "write content about W",
  or explicit /build invocation.
---

# Build

You are the unified pipeline orchestrator. Your job is to detect the
appropriate mode for the user's request and dispatch to the correct
mode adapter.

## Arguments
- $ARGUMENTS = task description (natural language) + optional flags
- `--mode code|analysis|strategy|content` (override auto-detection)
- `--new-project` (force code-project mode)
- All flags from the target mode's command are passed through

## Mode Detection
[See mode detection logic from Section 2 above]

## Dispatch
[Read appropriate mode-*.md file from $CLAUDE_SKILL_DIR]

## State Initialization
Before dispatching to a mode adapter:
1. Generate a pipeline run ID: `{mode}-{timestamp}`
2. Create state directory: `.ceos-agents/{run-id}/`
3. Write initial `state.json` with status: "started", mode, and input hash
4. Pass state directory path to the mode adapter
```

### Updating `bug-workflow` Skill

The existing `bug-workflow` skill gains one new row in its intent table:

```
| Build something / unified pipeline | `ceos-agents:build` (Skill) | Task description | Depends |
```

And the `/build` skill handles all forge-originated requests. This means users can reach the new functionality via either:
- `/ceos-agents:build "analyze competitor pricing"` (direct skill invocation)
- Natural language to the `bug-workflow` skill: "build me an analysis of competitor pricing"
- The existing commands continue to work: `/ceos-agents:fix-ticket PROJ-42`

---

## 5. Backward Compatibility

### Layer 1: Zero Breaking Changes (v6.0.0 avoided)

The entire migration is designed to avoid a MAJOR version bump:

1. **No command removed.** All 24 commands stay at their current paths.
2. **No agent renamed.** All 18 agents stay at their current paths with their current `name` field values.
3. **No config key changed.** No existing required or optional section is modified.
4. **No comment format changed.** The `[ceos-agents]` prefix is permanent.
5. **No output format changed.** `maps_to: AC-{N}: {text}` is unchanged.

### Layer 2: New Capabilities (MINOR version bumps)

| Change | Version Impact | Justification |
|--------|---------------|---------------|
| Add `core/` directory | PATCH | Internal refactoring, no public API change |
| Add `skills/build/` | MINOR | New feature, no existing feature affected |
| Add `agents/modes/` | MINOR | New agents, no existing agent affected |
| Add `state/` directory | MINOR | New optional feature |
| Add `.ceos-agents/` state directory convention | MINOR | Optional; commands fall back to heuristic when absent |
| New config section: `State Management` | MINOR | Optional section with defaults |

### Layer 3: Deprecation Schedule (future, post-migration)

After the unified `/build` skill has been shipping for at least 2 minor releases with zero regressions:

1. **v7.0.0 (earliest):** Add deprecation warnings to `fix-ticket`, `fix-bugs`, `implement-feature`, `scaffold` commands. Warning text: "This command will be removed in v8.0.0. Use `/ceos-agents:build` instead."
2. **v8.0.0 (earliest):** Consider removing deprecated commands. BUT ONLY IF telemetry/feedback confirms zero active users of the old commands. If in doubt, keep them.

I emphasize: this deprecation schedule is speculative. It may never happen. The commands may coexist with the `/build` skill indefinitely. That is fine. Working code does not need to be removed to make an architecture diagram look cleaner.

### Agent Override Compatibility

The `customization/{agent-name}.md` convention is preserved exactly:
- `customization/reviewer.md` still applies to the `reviewer` agent
- `customization/fixer.md` still applies to the `fixer` agent
- Mode-specific agents in `agents/modes/` use a new convention: `customization/modes/{agent-name}.md`
- The `check-setup` command is updated to validate both paths

### Resume-Ticket Compatibility

The `resume-ticket` command is updated to:
1. First check for `.ceos-agents/{ISSUE-ID}/state.json` (authoritative)
2. If absent, fall back to the existing 7-level heuristic (unchanged)
3. Both `[ceos-agents]` and `[CLAUDE-agents]` comment detection are preserved

This means:
- New runs create state files and resume deterministically
- Old runs (pre-state-file) resume via heuristic as before
- There is never a moment where resume breaks

---

## 6. Non-Code Modes

### Delivery Scope for v1

The Phase 2 research identifies 4 true capability gaps. I recommend delivering them in two increments:

**Increment 1 (included in initial /build release):**
- Input ingestion (prerequisite for everything)
- Analysis mode (most natural extension of existing spec-writer/spec-reviewer loop)

**Increment 2 (next minor release):**
- Strategy mode
- Content mode

### Why Analysis First

Analysis mode has the highest overlap with existing agent capabilities:
- `spec-writer` (adapted) generates the analytical framework
- `spec-reviewer` (adapted) validates completeness and methodology
- `priority-engine` (adapted) ranks findings by impact
- `architect` (adapted) structures the output

Strategy and content modes require more novel domain expertise and benefit from learning from the analysis mode delivery.

### Pipeline Phases for Non-Code Modes

Using the forge 10-phase model, adapted per mode:

| Phase | Code-Feature | Analysis | Strategy | Content |
|-------|-------------|----------|----------|---------|
| 0. Meta | detect mode | detect mode | detect mode | detect mode |
| 1. Research Questions | spec-analyst | input-ingestion + question framing | input-ingestion + question framing | input-ingestion + question framing |
| 2. Research Answers | code-analyst | analysis-spec-writer (research) | strategy-spec-writer (research) | content-spec-writer (research) |
| 3. Brainstorm | architect | analysis-spec-writer (framework) | strategy-spec-writer (options) | content-spec-writer (outline) |
| 4. Spec | spec-writer + spec-reviewer loop | analysis-spec-writer + spec-reviewer loop | strategy-spec-writer + spec-reviewer loop | content-spec-writer + spec-reviewer loop |
| 5. TDD/Quality | test-engineer (tests) | quality checklist (methodology) | quality checklist (feasibility) | quality checklist (audience fit) |
| 6. Plan | architect (task tree) | architect (section plan) | architect (section plan) | architect (section plan) |
| 7. Execute | fixer (code) | fixer (document writing) | fixer (document writing) | fixer (document writing) |
| 8. Review | reviewer + acceptance-gate | analysis-reviewer | strategy-reviewer | content-reviewer |
| 9. Complete | publisher | output assembly | output assembly | output assembly |

### Input Ingestion

All existing agents assume input from either a codebase or an issue tracker via MCP. Non-code modes need flexible input. Rather than building a new agent, the `/build` skill's mode adapter handles input gathering in Phase 0/1:

```markdown
## Input Gathering (non-code modes)

1. Read $ARGUMENTS for the task description
2. Check for input sources:
   - File path(s) in CWD → read via Read tool
   - URL → fetch via WebFetch tool (if available)
   - Pasted text → use directly from $ARGUMENTS
   - --input <path> flag → read specified file(s)
3. Assemble input context for downstream agents
4. If no input provided → ask user for input or data source
```

This is handled at the skill level, not the agent level, because input ingestion is an orchestration concern (WHAT to feed the pipeline) not a specialist concern (HOW to process it).

---

## 7. State Management

### State File Schema

Location: `.ceos-agents/{RUN-ID}/state.json`

For issue-tracker-based runs: `RUN-ID = {ISSUE-ID}` (e.g., `PROJ-42`)
For build-based runs: `RUN-ID = {mode}-{YYYYMMDD-HHMMSS}` (e.g., `analysis-20260322-143000`)

```json
{
  "schema_version": "1.0.0",
  "run_id": "PROJ-42",
  "pipeline_type": "bug-fix | feature | scaffold | analysis | strategy | content",
  "mode": "code-bugfix | code-feature | code-project | analysis | strategy | content",
  "started_at": "2026-03-22T14:30:00Z",
  "updated_at": "2026-03-22T14:35:00Z",
  "status": "running | completed | blocked | failed",
  "current_step": "triage",
  "profile": "fast | null",
  "skipped_stages": ["e2e-test-engineer"],

  "triage": {
    "status": "completed | pending | skipped | failed",
    "acceptance_criteria": [
      {"id": 1, "text": "Login page returns 200", "fulfilled": null}
    ],
    "complexity": "M",
    "severity": "critical",
    "area": "auth"
  },

  "code_analyst": {
    "status": "completed",
    "risk": "HIGH",
    "affected_files": ["src/auth.py", "src/login.py", "tests/test_auth.py"],
    "estimated_diff_lines": 45
  },

  "decomposition": {
    "status": "not_needed | in_progress | completed",
    "strategy": "sequential",
    "subtask_count": 3,
    "completed_subtasks": ["sub-1"],
    "current_subtask": "sub-2",
    "task_tree_path": ".claude/decomposition/PROJ-42.yaml"
  },

  "fixer_reviewer": {
    "status": "in_progress",
    "iteration": 2,
    "max_iterations": 5,
    "last_verdict": "REQUEST_CHANGES",
    "verdict_history": [
      {"iteration": 1, "verdict": "REQUEST_CHANGES", "summary": "Missing null check"}
    ]
  },

  "test_engineer": {
    "status": "pending",
    "attempt": 0,
    "max_attempts": 3
  },

  "build": {
    "status": "pending",
    "attempt": 0,
    "max_retries": 3
  },

  "browser": {
    "reproduction_status": "reproduced | not_reproduced | skipped | pending",
    "verification_status": "pending",
    "result_path": ".ceos-agents/PROJ-42/reproduction-result.json"
  },

  "acceptance_gate": {
    "status": "pending",
    "required": true,
    "verdict": null
  },

  "publisher": {
    "status": "pending",
    "pr_url": null,
    "branch": null
  }
}
```

### Key Design Decisions

**Run-ID-scoped browser artifacts.** The `.claude/reproduction-result.json` race condition is fixed by moving browser artifacts into the run's state directory: `.ceos-agents/{RUN-ID}/reproduction-result.json` and `.ceos-agents/{RUN-ID}/verification-result.json`. This eliminates the parallel execution conflict in `fix-bugs` worktree mode.

**Heuristic fallback.** `resume-ticket` checks for the state file first. If absent (pre-migration runs), it falls back to the existing 7-level heuristic. This fallback is preserved indefinitely. It costs nothing and prevents breakage for in-flight tickets during the migration period.

**Atomic writes.** State file updates use write-to-temp-then-rename pattern (atomic on all filesystems). No file locking needed for single-pipeline runs. For `fix-bugs` parallel mode, each bug has its own state directory (scoped by ISSUE-ID), so no cross-bug contention exists.

**Schema versioning.** `schema_version: "1.0.0"` allows future schema evolution. If the state file has a schema version the current plugin version does not recognize, it falls back to heuristic detection.

### State Manager Contract (`core/state-manager.md`)

```markdown
# State Manager

## Operations

### Initialize
- Create `.ceos-agents/{RUN-ID}/` directory
- Write initial state.json with status: "running"

### Update Step
- Read current state.json
- Update the specified step's status and data
- Write back atomically

### Read State
- If `.ceos-agents/{RUN-ID}/state.json` exists → parse and return
- If not → return null (caller must use heuristic fallback)

### Mark Complete
- Update status to "completed"
- Record completed_at timestamp

### Mark Blocked
- Update status to "blocked"
- Record blocking_agent, reason, step
```

---

## 8. Migration Sequence

### Ordering Rationale

The Phase 2 research establishes a clear dependency chain:
1. Race condition fix (prerequisite: undocumented data corruption bug)
2. Test infrastructure (prerequisite: prevent false failures)
3. State infrastructure (prerequisite: unblocks pipeline restructuring)
4. Core extraction (prerequisite: reduces duplication before adding new features)
5. /build skill + mode adapters (the new feature)
6. Non-code modes (depends on /build skill)

### PR Sequence

#### PR #1: Fix `.claude/` Race Condition
**Files:** `agents/reproducer.md`, `agents/browser-verifier.md`, `commands/fix-bugs.md`
**Change:** Browser artifact paths become run-ID-scoped. `reproduction-result.json` is written to `.ceos-agents/{ISSUE-ID}/` instead of `.claude/`. Same for `verification-result.json`. `fix-bugs.md` updated to pass the scoped path to agents.
**Version:** PATCH (v5.1.1) — behavior fix, no contract change.
**Test:** Verify artifacts are written to scoped paths. Existing tests unaffected (no test covers browser artifact paths).
**Rollback:** `git revert` — the old `.claude/` paths continue to work; the race condition simply reappears.

#### PR #2: Fix Fragile Tests
**Files:** `tests/scenarios/happy-path.sh`, `tests/scenarios/verify-fail.sh`, `tests/scenarios/pipeline-consistency.sh`
**Change:** Per Phase 2 Domain 7 recommendations — dynamic inventory, remove step-number coupling, discoverable pipeline files.
**Version:** PATCH (v5.1.2) — test-only change.
**Test:** Run `./tests/harness/run-tests.sh` — all existing tests must pass.
**Rollback:** `git revert` — restores old fragile tests. Functional regression: zero (test-only change).

#### PR #3: Add Structural Parity Tests
**Files:** New `tests/scenarios/frontmatter-completeness.sh`, `tests/scenarios/model-assignment.sh`, `tests/scenarios/read-only-agents.sh`, `tests/scenarios/section-order.sh`
**Change:** Four new test scenarios per Phase 2 Domain 7 recommendations.
**Version:** PATCH (v5.1.3) — test-only change.
**Test:** Run full test suite — new tests must pass against current codebase.
**Rollback:** `git revert` — removes new tests. No functional regression.

#### PR #4: Introduce State Infrastructure
**Files:** New `state/schema.md`, new `core/state-manager.md`, updated `commands/fix-ticket.md`, `commands/fix-bugs.md`, `commands/implement-feature.md`, `commands/resume-ticket.md`
**Change:** Pipeline commands write state files during execution. resume-ticket reads state file first, falls back to heuristic. Browser artifacts moved to state directory. New test: `tests/scenarios/state-schema.sh`.
**Version:** MINOR (v5.2.0) — new optional feature (state files).
**Config change:** New optional config section `State Management` with key `Path` (default: `.ceos-agents/`). MINOR — optional section.
**Test:** All existing tests pass. New state-schema test validates the documented schema against actual state file writes in commands.
**Rollback:** `git revert` — removes state file writes. resume-ticket falls back to heuristic (which is unchanged). The `.ceos-agents/` directories created during the PR's lifetime are inert (ignored by all code paths after revert).

**APPROVAL GATE 1: Validate state infrastructure works with all 3 pipeline commands before proceeding.**

#### PR #5: Extract Core Patterns (1/3) — Config, MCP, Agent Override
**Files:** New `core/config-reader.md`, `core/mcp-preflight.md`, `core/agent-override-injector.md`. Updated `commands/fix-ticket.md`, `commands/fix-bugs.md`, `commands/implement-feature.md`.
**Change:** Three shared patterns extracted. Commands reference core files instead of duplicating logic. New test: `tests/scenarios/core-include-refs.sh` (validates all core references resolve to existing files).
**Version:** PATCH (v5.2.1) — internal refactoring.
**Test:** All tests pass. Manually verify that each command's behavior is unchanged by running a dry-run.
**Rollback:** `git revert` — commands revert to inline logic. Zero functional regression.

#### PR #6: Extract Core Patterns (2/3) — Fixer-Reviewer Loop, Block Handler
**Files:** New `core/fixer-reviewer-loop.md`, `core/block-handler.md`. Updated pipeline commands.
**Change:** The fixer-reviewer loop and block handler are extracted. Commands reference core files.
**Version:** PATCH (v5.2.2).
**Rollback:** Same as PR #5.

#### PR #7: Extract Core Patterns (3/3) — Remaining Patterns
**Files:** New `core/decomposition-heuristics.md`, `core/profile-parser.md`, `core/post-publish-hook.md`, `core/fix-verification.md`. Updated pipeline commands.
**Version:** PATCH (v5.2.3).
**Rollback:** Same as PR #5.

**APPROVAL GATE 2: All 4 pipeline commands fully refactored to use core patterns. Full test suite green. Manual dry-run validation of each pipeline.**

#### PR #8: Add `/build` Skill — Code Modes
**Files:** New `skills/build/SKILL.md`, `skills/build/mode-code-feature.md`, `skills/build/mode-code-bugfix.md`, `skills/build/mode-code-project.md`. Updated `skills/bug-workflow/skill.md` (add build routing row).
**Change:** The `/build` entry point exists and can dispatch to code-feature, code-bugfix, and code-project modes. These modes delegate to the existing commands (fix-ticket, fix-bugs, implement-feature, scaffold) via Skill() invocation.
**Version:** MINOR (v5.3.0) — new feature.
**Test:** New test validates skill file structure. Manual test: `/ceos-agents:build "fix the login bug PROJ-42"` should dispatch to fix-ticket.
**Rollback:** `git revert` — removes the `/build` skill. All existing commands unaffected.

#### PR #9: Add Analysis Mode — Agent Variants
**Files:** New `agents/modes/analysis-reviewer.md`, `agents/modes/analysis-spec-writer.md`. New `skills/build/mode-analysis.md`.
**Change:** Analysis mode is functional end-to-end.
**Version:** MINOR (v5.4.0) — new feature.
**Test:** New test validates mode-specific agent frontmatter. Manual test: `/ceos-agents:build --mode analysis "evaluate our deployment pipeline efficiency"`
**Rollback:** `git revert` — removes analysis mode. Code modes unaffected.

#### PR #10: Add Strategy + Content Modes
**Files:** New `agents/modes/strategy-reviewer.md`, `agents/modes/strategy-spec-writer.md`, `agents/modes/content-reviewer.md`, `agents/modes/content-spec-writer.md`. New `skills/build/mode-strategy.md`, `skills/build/mode-content.md`.
**Version:** MINOR (v5.5.0).
**Rollback:** Same pattern as PR #9.

**APPROVAL GATE 3: All modes functional. Full test suite green. User acceptance testing.**

#### PR #11: Fix Pre-existing Gaps
**Files:** `agents/spec-writer.md` (add missing red-circle emoji to block comment), `skills/bug-workflow/skill.md` (add `discuss` entry to intent table).
**Version:** PATCH (v5.5.1).
**Rollback:** `git revert` — restores pre-existing gaps (not a regression).

#### PR #12: Documentation Update
**Files:** `README.md`, `CLAUDE.md`, `docs/reference/*.md`, `docs/guides/*.md`, `CHANGELOG.md`.
**Version:** PATCH (v5.5.2) — docs only.
**Rollback:** `git revert`.

### Total: 12 PRs across 3 approval gates

Each PR is independently revertible. No PR depends on a future PR. Every PR leaves the system in a working state.

### Timeline Estimate

- PRs #1-3 (prerequisites): 1-2 days
- PR #4 (state infrastructure): 2-3 days
- PRs #5-7 (core extraction): 3-5 days
- PR #8 (build skill): 2-3 days
- PRs #9-10 (non-code modes): 3-5 days
- PRs #11-12 (cleanup): 1 day

**Total: approximately 12-19 working days**, with approval gates providing natural pause points for validation.

---

## Risk Assessment

### Risks Mitigated by This Approach

| Risk | Mitigation |
|------|------------|
| Stage-number coupling blocks restructuring | State file introduced before any restructuring (PR #4) |
| `.claude/` race condition in parallel mode | Fixed in PR #1, before any structural changes |
| Test false failures block velocity | Fixed in PR #2, before any structural changes |
| Agent Override silent failure on rename | No agents renamed — zero risk |
| `[ceos-agents]` comment format breakage | No comment formats changed — zero risk |
| `maps_to: AC-{N}:` format breakage | No architect output format changed — zero risk |
| `rollback-agent` skip list breakage | No agents renamed — zero risk |
| `discuss` command default agents breakage | No agents renamed — zero risk |
| Existing CI scripts using `/ceos-agents:*` | All commands preserved — zero risk |

### Residual Risks

| Risk | Severity | Mitigation |
|------|----------|------------|
| **Core file references not followed by LLM.** The "Follow the process defined in `core/X.md`" pattern relies on the LLM reading the referenced file. If Claude Code does not follow cross-file prose references, the core extraction breaks. | HIGH | Validate with a manual dry-run before merging PR #5. If the LLM does not follow references, fall back to `$CLAUDE_SKILL_DIR` includes within skills (not commands). Worst case: keep the duplicated logic in commands. |
| **Mode detection false positives.** A user saying "build me a report" might get mode=content when they want mode=code-feature. | MEDIUM | The `--mode` flag provides an explicit override. The mode detection heuristics are conservative (default to code-feature). Improve heuristics based on user feedback. |
| **State file corruption.** A crash during state file write could leave a corrupt JSON file. | MEDIUM | Atomic write pattern (temp + rename). If parsing fails, fall back to heuristic detection. |
| **Non-code mode agents are undertested.** The new `agents/modes/*.md` agents have no pipeline-level tests because the test suite is static-analysis only. | MEDIUM | Add structural tests for mode agents (frontmatter, section order). Real behavioral testing requires the mock infrastructure to be wired — recommend as a follow-up project. |
| **Core extraction increases indirection.** Commands that previously contained all logic inline now reference external files. This makes it harder to understand a command in isolation. | LOW | Each core file has explicit input/output/failure contracts. The indirection is documented. The benefit (reduced duplication across 4 pipeline commands) outweighs the cost (one extra file read per shared pattern). |
| **Scope creep in non-code modes.** Analysis, strategy, and content modes are genuinely new territory. The domain expertise requirements may be larger than estimated. | MEDIUM | Deliver analysis mode first (PR #9) as a learning exercise. Defer strategy and content to PR #10 only after analysis mode validation. If analysis mode reveals fundamental issues, reassess the approach before proceeding. |

### What This Approach Does NOT Do

1. **Does not create a runtime pipeline engine.** This is a pure markdown plugin. There is no code to run. The "pipeline engine" is shared prose patterns, not a software abstraction.
2. **Does not remove any existing command.** All 24 commands survive the migration. Deprecation is speculative and far-future.
3. **Does not merge any existing agent.** All 18 agents survive unchanged. Mode dispatch happens at the orchestration level.
4. **Does not rename the plugin.** `ceos-agents` stays `ceos-agents`.
5. **Does not change any external-facing format.** Comment templates, config contract, and agent output formats are all unchanged.

This is, by design, the approach with the smallest blast radius. Every new capability is additive. Every existing capability is preserved. The migration can be paused at any approval gate without leaving the system in a broken state. If the entire effort is abandoned after PR #4, the system is strictly better than today (race condition fixed, fragile tests fixed, state infrastructure available).
