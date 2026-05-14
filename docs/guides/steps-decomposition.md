# Steps Decomposition Guide

> This guide describes how the three pipeline skills (`fix-bugs`, `implement-feature`, `scaffold`)
> are decomposed from a monolithic `SKILL.md` (~600 lines) into an entry `SKILL.md` (~100 lines)
> and a set of step files (`steps/*.md`, 5–8 per skill). The architecture is inspired by the BMAD
> framework, where this decomposition demonstrated ~80% token reduction per step and improved LLM
> reliability due to a smaller context window. The remaining non-pipeline skills stay monolithic —
> decomposition is explicitly limited to these three pipeline skills.

---

## 1. Overview

### Why decomposition?

Originally, each of the three pipeline skills (`fix-bugs`, `implement-feature`, `scaffold`) consisted
of a single monolithic `SKILL.md` file of approximately 600 lines. This design caused two problems:

1. **Token cost**: Every pipeline step dispatched the same ~600-line context window to the LLM, even
   though most of that content was irrelevant to the current step.
2. **LLM reliability**: Larger context windows increase the likelihood of the LLM losing focus on
   the current task, mixing instructions from different steps, or misinterpreting conditional logic.

The BMAD framework (industry reference for modular agent orchestration) documented a ~80% token
reduction per step when moving from monolithic to decomposed step files, with measurably improved
per-step instruction compliance. The agent-flow plugin adopts this pattern for the three pipeline skills.

### Decomposition scope

- **3 pipeline skills decomposed**: `fix-bugs`, `implement-feature`, `scaffold`
- **Non-pipeline skills** (`analyze-bug`, `autopilot`, `changelog`, `check-setup`, `create-backlog`,
  `discuss`, `metrics`, `onboard`, `prioritize`, `publish`, `setup-agents`, `setup-mcp`, `sprint-plan`,
  `version-bump`, `version-check`) retain their monolithic `SKILL.md` structure —
  decomposition is explicitly limited to the three pipeline skills above.
- **Step override mechanism**: consuming projects may replace any individual step file
  via `customization/steps/{skill}/{step-name}.md` (see Section 4).
- **Pipeline Profiles named-phase syntax**: `Skip stages` accepts named-phase identifiers
  matching step file base names (see Section 6).

---

## 2. Architecture

### Entry SKILL.md (≤ 120 lines)

Each decomposed pipeline skill's `SKILL.md` is the **entry point** responsible for:

- YAML frontmatter (`name`, `description`, `allowed-tools`, `disable-model-invocation`, `argument-hint`)
- Mode flag parsing (`--yolo` / default / `--step-mode`, mutual-exclusion check)
- Configuration reading (`core/config-reader.md`, `core/mcp-preflight.md`, `core/profile-parser.md`)
- Issue-ID validation (path-traversal defense)
- **Step dispatch loop**: iterate over step files in `steps/`, resolve override vs default,
  emit `[INFO]` log when override active, and dispatch each step's agent via the `Task` tool
- Per-step gate logic (`--step-mode` prompt after each step, `--yolo` no-prompt flow)
- Block handler, worktree processing, and summary table

The entry `SKILL.md` does **not** contain per-step agent instructions. Those live in `steps/`.

### Step files (`steps/{NN}-{name}.md`, 5–8 per skill)

Each step file contains the **instructions for a single pipeline step**, including:

- Which agent to dispatch (e.g., `Task(subagent_type='agent-flow:analyst', model='sonnet')`)
- Skip condition (Pipeline Profile stage skip check)
- Pre-dispatch and post-dispatch `state.json` writes
- NEEDS_CLARIFICATION handling (where applicable)
- Outcome handling and block conditions

Step files are loaded at dispatch time; only the relevant step's ~150-line file enters the
LLM context window for that step — not the full pipeline definition.

### The 3 pipeline skills

| Skill | Entry SKILL.md | Step files | Total steps |
|-------|---------------|------------|-------------|
| `fix-bugs` | `skills/fix-bugs/SKILL.md` | `skills/fix-bugs/steps/` | 7 |
| `implement-feature` | `skills/implement-feature/SKILL.md` | `skills/implement-feature/steps/` | 7 |
| `scaffold` | `skills/scaffold/SKILL.md` | `skills/scaffold/steps/` | 8 |

---

## 3. Step File Conventions

### Naming

Step files follow the pattern `{NN}-{descriptive-name}.md`:

- `NN` is a **two-digit zero-padded** sequence number: `01`, `02`, ..., `08`
- `{descriptive-name}` is **kebab-case**: lowercase letters, digits, hyphens only
- Extension: `.md`

Examples: `01-triage.md`, `04-fixer-reviewer-loop.md`, `07-publish.md`

### Ordering

The numeric prefix (`NN`) indicates canonical execution order. However, the **actual dispatch
order is controlled by the entry `SKILL.md`** — the `NN` prefix is informational and aids
human readability and filesystem listing. Override files must use the same `{NN}-{name}.md`
filename to match the default step.

### Conditional steps

Some steps dispatch only when conditions are met (e.g., `03-reproduce.md` in `fix-bugs` dispatches
only when reproduction is required; `06-acceptance-gate.md` dispatches only when AC count ≥ 3 OR
complexity ≥ M). Conditional steps are **still counted** in the step total displayed in `--step-mode`
prompts — the step counter advances non-monotonically when a conditional step is not triggered
(e.g., from step `02/7` directly to `04/7`). The step file header documents its skip condition.

---

## 4. Step Override Mechanism

### Overview

Consuming projects can replace any individual pipeline step by placing a file at:

```
customization/steps/{skill}/{NN}-{name}.md
```

where `{skill}` is one of `fix-bugs`, `implement-feature`, `scaffold`, and `{NN}-{name}.md`
exactly matches the plugin-default step filename.

### Resolution at dispatch time

The entry `SKILL.md` uses the following precedence when resolving each step file:

```bash
STEP_NAME="04-fixer-reviewer-loop"  # example
SKILL_DIR="skills/fix-bugs/steps"
PROJECT_OVERRIDE="customization/steps/fix-bugs"

STEP_FILE="${SKILL_DIR}/${STEP_NAME}.md"

if [ -f "${PROJECT_OVERRIDE}/${STEP_NAME}.md" ]; then
  STEP_FILE="${PROJECT_OVERRIDE}/${STEP_NAME}.md"
  echo "[INFO] Step override active: fix-bugs/${STEP_NAME} from project customization"
fi

# Load instructions from $STEP_FILE and dispatch the agent
```

Resolution rules:

1. **Override path checked first**: `customization/steps/{skill}/{step-name}.md` in the project root.
2. **Plugin default as fallback**: `skills/{skill}/steps/{step-name}.md` in the plugin.
3. **Exact filename match required**: `{NN}-{name}.md` must match exactly. A file with a wrong name
   is not silently applied — it triggers a near-miss warning and falls through to the plugin default
   (see Section 5).

### Override semantics: replace-only

An override file **fully replaces** the corresponding plugin-default step. There is no merge,
no partial patching, no instruction insertion before or after the default body. The override
file takes the place of the entire default step.

The override file must follow the same step-file conventions (markdown format, no YAML frontmatter
required). It should dispatch the same agent role to preserve pipeline integrity, though consuming
projects may change the model, agent, or instructions as needed for their use case.

### Logging

When an override file is active, the skill emits:

```
[INFO] Step override active: {skill}/{step-name} from project customization
```

This log line appears in `.agent-flow/pipeline.log` and can be grepped for debugging
(see Section 7).

---

## 5. Near-Miss Filename Detection

If a file exists under `customization/steps/{skill}/` whose name does **not** exactly match
any plugin-default step filename, but **would** match after one of these normalizations:

- (a) **ASCII case folding**: e.g., `04-Fixer-Reviewer-Loop.md` → should be `04-fixer-reviewer-loop.md`
- (b) **Zero-padding correction**: e.g., `4-fixer-reviewer-loop.md` → should be `04-fixer-reviewer-loop.md`
- (c) **Underscore-to-hyphen**: e.g., `04_fixer_reviewer_loop.md` → should be `04-fixer-reviewer-loop.md`

...the skill emits a warning and **falls through to the plugin default** (no override applied):

```
[WARN] Possible misnamed step override: 4-fixer-reviewer-loop.md — did you mean 04-fixer-reviewer-loop.md?
```

The near-miss warning fires once per dispatch per near-miss file. It does NOT abort the pipeline.
To resolve the warning: rename the file to the canonical `{NN}-{name}.md` form, or delete it if
it was created by mistake.

Example of a near-miss that would trigger the warning:

```
# This file will NOT be applied as an override — it triggers [WARN] instead:
customization/steps/fix-bugs/4-fixer-reviewer-loop.md

# Correct form (exact match to plugin default):
customization/steps/fix-bugs/04-fixer-reviewer-loop.md
```

---

## 6. Pipeline Profiles Named-Phase Syntax

### v8 named-phase identifiers

The `Skip stages` value in the `### Pipeline Profiles` Automation Config section
accepts named-phase identifiers that correspond to step file base names or agent-phase forms.

```markdown
### Pipeline Profiles

| Key | Value |
|-----|-------|
| Profile | fast |
| Skip stages | [analyst-impact, browser-agent-reproduce] |
```

The `analyst-impact` and `browser-agent-reproduce` identifiers correspond to the consolidated agents'
internal phase flags.

The `/agent-flow:check-setup` tool validates your config format and will surface any unrecognized stage names.

---

## 7. Debugging Tips

### Trace step override activity

```bash
grep "Step override active" .agent-flow/pipeline.log
```

This shows which steps were sourced from `customization/steps/` rather than the plugin default.

### Check near-miss warnings

```bash
grep "Possible misnamed step override" .agent-flow/pipeline.log
```

### Verify step file resolution

List the plugin-default step files and your project overrides side by side:

```bash
# Plugin-default step files for fix-bugs:
ls skills/fix-bugs/steps/

# Your project overrides (if any):
ls customization/steps/fix-bugs/ 2>/dev/null || echo "(no overrides)"
```

Compare filenames exactly — `{NN}-{name}.md` must match precisely (case, zero-padding, hyphens).

### Check which steps were skipped by Profile

```bash
grep '\[SKIP\]' .agent-flow/pipeline.log
```

### Check v7 stage-name deprecation warnings

```bash
grep '\[WARN\]' .agent-flow/pipeline.log | grep -i "skip stages"
```

---

## 8. Pipeline-by-Pipeline Step Reference

### fix-bugs (7 steps)

| Step file | Description | Conditional? |
|-----------|-------------|--------------|
| `01-triage.md` | Dispatch `analyst --phase triage`: AC extraction, complexity, duplication check | No |
| `02-impact.md` | Dispatch `analyst --phase impact`: affected files, root cause analysis | No |
| `03-reproduce.md` | Dispatch `browser-agent --phase reproduce`: reproduce bug in browser | Yes (optional) |
| `04-fixer-reviewer-loop.md` | Fixer ↔ reviewer loop (max 5 iterations): code fix + AC fulfillment check | No |
| `05-test.md` | Dispatch `test-engineer`: write/run tests, build smoke check | No |
| `06-acceptance-gate.md` | Dispatch `acceptance-gate`: verify AC fulfillment with code+test evidence | Yes (AC ≥ 3 OR complexity ≥ M) |
| `07-publish.md` | Dispatch `publisher`: create PR, update tracker, fire webhooks | No |

### implement-feature (7 steps)

| Step file | Description | Conditional? |
|-----------|-------------|--------------|
| `01-spec.md` | Dispatch `spec-analyst`: specification, AC writeback to tracker | No |
| `02-architect.md` | Dispatch `architect`: task tree with `maps_to` AC traceability | No |
| `03-decomposition.md` | Decomposition decision, create tracker subtasks if needed | Yes (decomposition path only) |
| `04-fixer-reviewer-loop.md` | Fixer ↔ reviewer loop (max 5 iterations): implementation + AC fulfillment | No |
| `05-test.md` | Dispatch `test-engineer`: write/run tests, build smoke check | No |
| `06-acceptance-gate.md` | Dispatch `acceptance-gate`: verify AC fulfillment | Yes (always in decomposition; skipped in single-pass) |
| `07-publish.md` | Dispatch `publisher`: create PR, update tracker, fire webhooks | No |

### scaffold (8 steps)

| Step file | Description | Conditional? |
|-----------|-------------|--------------|
| `01-mode-resolve.md` | State detection, infra declaration, MCP check, brainstorm-if-vague | Brainstorm conditional |
| `02-spec-write-review.md` | `spec-writer` ↔ `spec-reviewer` loop: project specification | No (skipped in `--no-implement`) |
| `03-scaffold.md` | Dispatch `scaffolder`: skeleton generation, test infrastructure, scorecard | No |
| `04-architect.md` | Dispatch `architect`: feature plan with `maps_to` traceability | No |
| `05-fixer-reviewer-loop.md` | Fixer ↔ reviewer loop: implement features per spec | No (skipped in `--no-implement`) |
| `06-test.md` | Dispatch `test-engineer`: write/run tests | No (skipped in `--no-implement`) |
| `07-spec-verify.md` | Dispatch `spec-reviewer --verify`: check implementation against spec | No (skipped in `--no-implement`) |
| `08-final-report.md` | Final scaffold report: scorecard, git init, push, tracker issues | No |

---

## 9. Step Override Examples

### Example 1: fix-bugs — custom fixer-reviewer loop (project-specific review rules)

Suppose your project requires all reviewer comments to be in Czech. Place a replacement step file:

```
customization/steps/fix-bugs/04-fixer-reviewer-loop.md
```

Contents (minimal replacement):

```markdown
# Step 04 — Fixer-Reviewer Loop (project override)

Dispatch fixer then reviewer per the plugin default logic, with this addition:

## Project-specific reviewer constraint

The reviewer MUST write all comments in Czech. This is non-negotiable for this project.
```

When the pipeline runs, the skill emits:

```
[INFO] Step override active: fix-bugs/04-fixer-reviewer-loop from project customization
```

The override replaces the entire default `04-fixer-reviewer-loop.md` body. Any plugin default
content not repeated in the override file is not applied.

### Example 2: implement-feature — custom acceptance gate (stricter AC coverage threshold)

To lower the AC gate threshold to fire for all issues (not just AC ≥ 3), override:

```
customization/steps/implement-feature/06-acceptance-gate.md
```

```markdown
# Step 06 — Acceptance Gate (project override: always active)

## Skip condition

NEVER skip — this gate runs for ALL issues regardless of AC count or complexity.

## Dispatch

You MUST invoke Task(subagent_type='agent-flow:acceptance-gate', model='sonnet').
Context: all acceptance criteria from step 01-spec, plus current codebase state.
```

### Example 3: scaffold — custom final report (add deployment checklist)

To append a deployment checklist to every scaffold final report:

```
customization/steps/scaffold/08-final-report.md
```

```markdown
# Step 08 — Final Report (project override: with deployment checklist)

Follow the plugin default final report format, then append:

## Deployment Checklist (project-specific)

- [ ] Verify `docker-compose.yml` environment variables are set in CI
- [ ] Confirm staging environment URL in `docs/deployment.md`
- [ ] Tag first release as `v0.1.0-alpha`
```

---

## 10. v7 Monolithic vs v8 Decomposed — Comparison

| Dimension | v7 (monolithic) | v8 (decomposed) |
|-----------|-----------------|-----------------|
| `fix-bugs/SKILL.md` lines | ~600 | ~110 |
| Context window per step dispatch | ~600 lines (full pipeline) | ~150 lines (step only) |
| Token usage per step (estimated) | 100% | ~20–25% (BMAD evidence) |
| Step override granularity | None (all-or-nothing fork) | Per step, replace-only |
| Pipeline Profiles skip syntax | v7 agent names (legacy) | Named-phase identifiers (`analyst-impact`, etc.) |
| Step file structure | N/A | `skills/{skill}/steps/{NN}-{name}.md` |
| Override path | `customization/{agent}.md` (agent-level) | `customization/steps/{skill}/{NN}-{name}.md` (step-level) |

### File structure comparison

**v7 (monolithic):**

```
skills/fix-bugs/
  SKILL.md    (~600 lines — full pipeline logic)
```

**v8 (decomposed):**

```
skills/fix-bugs/
  SKILL.md                    (~110 lines — dispatch logic only)
  steps/
    01-triage.md              (~150 lines)
    02-impact.md              (~150 lines)
    03-reproduce.md           (~120 lines, conditional)
    04-fixer-reviewer-loop.md (~200 lines)
    05-test.md                (~150 lines)
    06-acceptance-gate.md     (~120 lines, conditional)
    07-publish.md             (~100 lines)
```

---

## Related Documentation

- `docs/guides/toml-overlay-syntax.md` — TOML overlay system for per-agent customization, including Pipeline Profiles syntax
- `docs/guides/toml-overlay-syntax.md` — TOML overlay system for per-agent customization
- `docs/reference/pipeline.md` — reference: entry SKILL.md responsibilities, step file contract
- `docs/reference/automation-config.md` — Pipeline Profiles configuration reference (named-phase syntax)
