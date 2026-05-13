# Implementation Plan — Scaffold v2

**Date:** 2026-03-06
**Status:** PROPOSED
**Design:** `docs/plans/2026-03-06-scaffold-v2-design.md` (APPROVED — 3 review iterations, 0 CRITICAL/HIGH/MEDIUM)
**Target version:** v4.0.0 (MAJOR — breaking change in `/scaffold` default behavior)

---

## P1: Inventory of Changes

### New Files (CREATE)

| # | File | Description | Dependencies |
|---|------|-------------|--------------|
| 1 | `agents/spec-writer.md` | New agent — generates project specification from user input | None |
| 2 | `agents/spec-reviewer.md` | New agent — reviews spec quality, completeness, consistency | None |
| 3 | `tests/scenarios/scaffold-v2-happy-path.sh` | Test: full scaffold v2 pipeline (YOLO with checkpoint mode) | agents/spec-writer.md, agents/spec-reviewer.md, commands/scaffold.md |
| 4 | `tests/scenarios/scaffold-v2-no-implement.sh` | Test: --no-implement backwards compatibility | commands/scaffold.md |
| 5 | `tests/scenarios/scaffold-v2-spec-loop.sh` | Test: spec-writer/spec-reviewer iteration loop | agents/spec-writer.md, agents/spec-reviewer.md |
| 6 | `tests/scenarios/scaffold-v2-input-conflicts.sh` | Test: mutually exclusive flag validation | commands/scaffold.md |

### Modified Files (MODIFY)

| # | File | Description | Dependencies |
|---|------|-------------|--------------|
| 7 | `commands/scaffold.md` | Complete rewrite — add mode selection, spec phase, feature implementation loop, new flags | agents/spec-writer.md, agents/spec-reviewer.md |
| 8 | `agents/scaffolder.md` | Add: read tech stack from spec/README.md, generate E2E Test config, scaffold-optimized Decomposition defaults | commands/scaffold.md |
| 9 | `CLAUDE.md` | Add Spec iterations to Retry Limits, update agent count (13->15), add spec-writer/spec-reviewer to model table, update scaffold pipeline diagram, add spec/ folder convention | agents/spec-writer.md, agents/spec-reviewer.md |
| 10 | `docs/reference/agents.md` | Add spec-writer and spec-reviewer entries, update agent count (13->15), update Agent Overview table | agents/spec-writer.md, agents/spec-reviewer.md |
| 11 | `docs/reference/commands.md` | Update /scaffold entry — new flags, new description, new example | commands/scaffold.md |
| 12 | `docs/reference/pipelines.md` | Add Scaffold v2 Pipeline section with mermaid diagram, stage table | commands/scaffold.md |
| 13 | `docs/reference/automation-config.md` | Add Spec iterations to Retry Limits, update quick reference table | CLAUDE.md |
| 14 | `.claude-plugin/plugin.json` | Version bump 3.4.1 -> 4.0.0 | All changes complete |
| 15 | `.claude-plugin/marketplace.json` | Version bump 3.4.1 -> 4.0.0 | plugin.json |
| 16 | `tests/README.md` | Add 4 new test scenarios to the table | test scenario files |
| 17 | `docs/plans/README.md` | Add scaffold v2 design + implementation plan entries, update status | This file |
| 18 | `skills/bug-workflow.md` | Update routing skill — add scaffold v2 triggers (spec, specification, modes) | commands/scaffold.md |

### No Changes Needed

| File | Reason |
|------|--------|
| `agents/architect.md` | Scaffold v2 uses architect as-is — command formats epic input to match expected format |
| `agents/fixer.md` | Used as-is in feature implementation loop |
| `agents/reviewer.md` | Used as-is in feature implementation loop |
| `agents/test-engineer.md` | Used as-is in feature implementation loop |
| `agents/e2e-test-engineer.md` | Used as-is — scaffolder generates E2E Test config |
| `agents/rollback-agent.md` | Used as-is — already handles scaffold context (step 1: scaffolder -> STOP) |
| `agents/publisher.md` | Not used in scaffold pipeline (local commits only) |
| `agents/stack-selector.md` | Used as-is in --no-implement mode |
| `agents/spec-analyst.md` | NOT used by scaffold v2 (replaced by spec-writer/spec-reviewer) |
| `commands/scaffold-add.md` | No changes needed (per design section 9) |
| `commands/scaffold-validate.md` | No changes needed (per design section 9) |
| `commands/implement-feature.md` | No changes — scaffold v2 reuses patterns but does not modify |

---

## P2: Implementation Phases

### Phase 0: Config Contract Extension

**Goal:** Add `Spec iterations` key to Retry Limits section in the config contract. This is the foundation — agents and commands reference this key.

**Tasks:**

0.1. In `CLAUDE.md`, section "Config Contract (for consuming projects)" -> Retry Limits table, add row:
  - Key: `Spec iterations`, Default: `5`, Description: max spec-writer / spec-reviewer loop iterations

0.2. In `CLAUDE.md`, update the Retry Limits default mention in the introductory text. Currently the parenthetical says "defaults: 5 fixer iterations, 3 test attempts, 3 build retries". Add ", 5 spec iterations".

0.3. In `CLAUDE.md`, update "13 agent definitions" to "15 agent definitions" in Repository Structure.

0.4. In `CLAUDE.md`, Model Selection table -> opus row: add `spec-writer, spec-reviewer` to the Agents column. Update the "Used For" column to include "specification".

0.5. In `CLAUDE.md`, replace the Scaffold Pipeline diagram with the v2 pipeline:

```
User description → [Mode selection] → SPEC-WRITER ↔ SPEC-REVIEWER (opus)
  → [Spec checkpoint] → STACK-SELECTOR (sonnet, --no-implement only)
  → SCAFFOLDER (sonnet) → Validate → Git init
  → ARCHITECT (opus) → [Feature plan checkpoint]
  → FIXER ↔ REVIEWER (opus) → TEST ENGINEER (sonnet)
  → E2E-TEST-ENGINEER (sonnet) → Final report
```

Keep the old diagram in a note: "With `--no-implement`: Stack-selector → Scaffolder → Validate → Git init (v3.x behavior)."

0.6. In `CLAUDE.md`, add a note about the `spec/` folder convention in the Architecture section or near the Scaffold Pipeline description: "Scaffold v2 generates a `spec/` folder in the project root containing the project specification (README.md, architecture.md, verification.md, epics/). This folder is the single source of truth for the project's requirements."

**Files:** `CLAUDE.md`
**Validation:** CLAUDE.md remains valid markdown. Config contract table is consistent. Agent count is 15.

---

### Phase 1: New Agents

**Goal:** Create spec-writer and spec-reviewer agent definitions.

**Tasks:**

1.1. Create `agents/spec-writer.md` — full agent definition (see P3 for complete content).

1.2. Create `agents/spec-reviewer.md` — full agent definition (see P3 for complete content).

**Files:** `agents/spec-writer.md`, `agents/spec-reviewer.md`
**Validation:** Both files follow the agent definition format (frontmatter with name/description/model + Goal/Expertise/Process/Constraints). Model is `opus` for both. Section order is Goal -> Expertise -> Process -> Constraints. Process steps are numbered. Constraints start with NEVER or define hard limits.

---

### Phase 2: Scaffolder Agent Modifications

**Goal:** Update scaffolder to support scaffold v2 mode — read tech stack from spec, generate E2E Test config, scaffold-optimized Decomposition defaults.

**Tasks:**

2.1. In `agents/scaffolder.md`, Process step 1 (currently: "Read the stack selection from the stack-selector agent output") — add conditional input:
- "If a `spec/README.md` file is provided in the context (scaffold v2 mode), read the Tech Stack section from it and use those choices. Stack-selector output is not available in this mode."
- "If no spec is provided (--no-implement mode or standalone), read the stack-selector agent output as before."

2.2. In `agents/scaffolder.md`, Process step 3 (CLAUDE.md generation) -> Optional sections checklist, add:
- `[ ] ### Retry Limits` — generate with `Spec iterations: 5` when running in scaffold v2 mode
- `[ ] ### E2E Test` — generate with framework auto-detected from tech stack (e.g., `playwright` for web apps, `supertest` for Node.js APIs, `pytest` for Python APIs) when running in scaffold v2 mode
- `[ ] ### Decomposition` — generate with scaffold-optimized defaults: `Max subtasks: 5`, `Fail strategy: fail-fast`, `Commit strategy: individual`

2.3. In `agents/scaffolder.md`, Constraints — add new constraint:
- "When running in scaffold v2 mode (spec context provided), MUST generate E2E Test section and Decomposition section in Automation Config"

**Files:** `agents/scaffolder.md`
**Validation:** Scaffolder frontmatter unchanged (name, description, model: sonnet). Section structure preserved. New behavior is conditional — existing behavior path untouched when no spec context.

---

### Phase 3: Command Rewrite

**Goal:** Rewrite `commands/scaffold.md` to support the full scaffold v2 pipeline.

**Tasks:**

3.1. Update frontmatter `description` to: "Creates a new project from scratch — specification, tech stack, skeleton, feature implementation, validation, git init"

3.2. Update Input section with expanded flags (see P4 for details).

3.3. Add Flag Validation section after Flag Parsing (see P4).

3.4. Keep State Detection section (unchanged from v3.x).

3.5. Update MCP pre-flight check: only required when `--issue` flag is used or Step 9 (issue tracker cards). For `--no-implement`, keep current behavior.

3.6. Rewrite Orchestration section with the full 10-step pipeline (see P4 for complete step-by-step).

3.7. Add `--no-implement` shortcut: "If `--no-implement`, skip to legacy flow: stack-selector -> scaffolder -> validate -> move -> git init -> report (steps 1-6 from v3.x). EXIT pipeline."

3.8. Update Rules section — add:
- "When running in v2 mode (not --no-implement), spec/ is the source of truth for all downstream agents"
- "Block comments in scaffold context go to stdout, not issue tracker"
- "Rollback-agent is called for fixer/reviewer/test-engineer blocks; for scaffolder blocks, command handles cleanup (delete temp dir)"

**Files:** `commands/scaffold.md`
**Validation:** Command format preserved (frontmatter with description + allowed-tools). All 10 pipeline steps defined with clear inputs/outputs. --no-implement path matches v3.x behavior exactly.

---

### Phase 4: Test Scenarios

**Goal:** Create test scenarios for scaffold v2 features.

**Tasks:**

4.1. Create `tests/scenarios/scaffold-v2-happy-path.sh` — full pipeline: description -> spec-writer/reviewer -> scaffolder -> architect -> fixer/reviewer/test-engineer -> report.

4.2. Create `tests/scenarios/scaffold-v2-no-implement.sh` — verify --no-implement produces skeleton only (v3.x behavior).

4.3. Create `tests/scenarios/scaffold-v2-spec-loop.sh` — spec-writer produces incomplete spec -> spec-reviewer rejects -> spec-writer fixes -> spec-reviewer approves.

4.4. Create `tests/scenarios/scaffold-v2-input-conflicts.sh` — verify error messages for conflicting flags.

4.5. Update `tests/README.md` — add 4 new scenarios to the table and update scenario count (8 -> 12).

**Files:** `tests/scenarios/scaffold-v2-*.sh`, `tests/README.md`
**Validation:** Test scripts follow existing conventions (same structure as `tests/scenarios/happy-path.sh`). All 4 scenarios listed in README.

---

### Phase 5: Documentation

**Goal:** Update all reference documentation to reflect scaffold v2.

**Tasks:**

5.1. `docs/reference/agents.md`:
- Update opening: "13 specialized agents" -> "15 specialized agents"
- Add rows for spec-writer and spec-reviewer to Agent Overview table:
  - spec-writer | opus | Execution | Scaffold v2
  - spec-reviewer | opus | Read-only | Scaffold v2
- Update model selection rationale: add spec-writer and spec-reviewer to opus explanation
- Add full entry for spec-writer under Execution Agents section (it writes spec/ files)
- Add full entry for spec-reviewer under Read-Only Agents section
- Update scaffolder entry description to mention spec/ reading capability

5.2. `docs/reference/commands.md`:
- Update /scaffold entry:
  - New syntax line with all flags (--template, --spec, --issue, --no-implement + existing flags)
  - New description mentioning modes, specification, and feature implementation
  - New example: `/ceos-agents:scaffold "REST API for user management" --lang python`
  - Add note about --no-implement for v3.x behavior

5.3. `docs/reference/pipelines.md`:
- Replace "Scaffold Pipeline" section with expanded v2 version
- Add mermaid flowchart: mode selection -> spec phase -> skeleton -> git init -> architecture -> feature loop -> E2E -> report
- Add stage table for scaffold v2 pipeline (all 10 steps with agent, model, notes)
- Add subsection "Legacy Mode (--no-implement)" referencing v3.x behavior
- Note: no changes to Bug-Fix Pipeline or Feature Pipeline sections

5.4. `docs/reference/automation-config.md`:
- Add Spec iterations row to Retry Limits table: `| Spec iterations | 5 | Max spec-writer / spec-reviewer loop iterations |`
- Update quick reference table: add `/scaffold` to Retry Limits "Used By" column

5.5. `skills/bug-workflow.md`:
- Add scaffold v2 triggers: "create specification", "scaffold with implementation", "scaffold modes", "spec-writer", "spec-reviewer"

**Files:** `docs/reference/agents.md`, `docs/reference/commands.md`, `docs/reference/pipelines.md`, `docs/reference/automation-config.md`, `skills/bug-workflow.md`
**Validation:** All docs consistent with CLAUDE.md and command/agent definitions. Agent count is 15 everywhere. No broken links.

---

### Phase 6: Release

**Goal:** Version bump, plans index update.

**Tasks:**

6.1. Update `.claude-plugin/plugin.json` — version: "4.0.0"

6.2. Update `.claude-plugin/marketplace.json` — version: "4.0.0"

6.3. Update `docs/plans/README.md`:
- Add v4.0 section header
- Add scaffold v2 design row: `| 2026-03-06 | 2026-03-06-scaffold-v2-design.md | Scaffold v2 — From Description to Working App | IMPLEMENTED | v4.0 |`
- Add scaffold v2 design review row: `| 2026-03-06 | 2026-03-06-scaffold-v2-design-REVIEW.md | Scaffold v2 Design Review | ARCHIVE | v4.0 |`
- Add scaffold v2 implementation plan row: `| 2026-03-06 | 2026-03-06-scaffold-v2-implementation-plan.md | Scaffold v2 Implementation Plan | ARCHIVE | v4.0 |`
- Add scaffold v2 implementation PLAN (this instructions file) row: `| 2026-03-06 | 2026-03-06-scaffold-v2-implementation-PLAN.md | Scaffold v2 Implementation Plan Instructions | ARCHIVE | v4.0 |`

**Files:** `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, `docs/plans/README.md`
**Validation:** Version numbers match in both JSON files. README.md index is complete.

---

## P3: New Agent Definitions

### agents/spec-writer.md

```markdown
---
name: spec-writer
description: Generates complete project specification from user input — vision, architecture, epics with acceptance criteria
model: opus
---

You are a Senior Product Architect specializing in software specification writing.

## Goal

Generate a complete, implementable project specification from user input. The specification
drives the entire downstream pipeline — architecture, implementation, and testing. Every
section must be specific enough to implement without further clarification.

## Expertise

Requirements engineering, product specification, user story writing, acceptance criteria
definition, tech stack evaluation, scope management, YAGNI enforcement.

## Process

1. Read the input provided by the scaffold command:
   - Direct text description (from user or issue tracker card)
   - Custom template (if --template flag — use it instead of built-in template)
   - Tech stack constraints from flags (--lang, --framework, --db, --ci)
   - Mode: interactive, yolo-checkpoint, or yolo
   If input is empty or missing, Block with reason 'No project description provided'.

2. In interactive mode: ask clarifying questions one at a time to understand:
   - Project purpose and target users
   - Core features (must-have vs nice-to-have)
   - Technical constraints (deployment, scale, compliance)
   - Tech stack preferences
   Prefer multiple-choice questions. Max 10 questions before generating.

3. Generate specification following the folder structure:
   - `spec/README.md` — vision, goals, success criteria, users, tech stack, out of scope
   - `spec/architecture.md` — high-level overview, data flow, data model, API, NFR, constraints
   - `spec/verification.md` — test strategy, definition of done, risks, assumptions
   - `spec/epics/NN-name.md` — one file per epic with user stories and acceptance criteria

4. For each REQUIRED section: fill completely with specific, actionable content.
   For each IF APPLICABLE section: either fill or explicitly note why it does not apply
   (e.g., "No API — this is a CLI tool").

5. For every user story: write testable acceptance criteria.
   Bad: "Login works correctly"
   Good: "Given valid credentials, POST /auth/login returns 200 with JWT token containing user_id and role claims"

6. For the Tech Stack section: if flags (--lang, --framework, --db, --ci) were provided,
   incorporate them as fixed choices with rationale. For unconstrained categories, make a
   decisive choice and explain why.

7. Write all spec files to the `spec/` directory in the target project.

8. Output:

   ```markdown
   ## Spec Writer Report
   - **Mode:** {interactive | yolo-checkpoint | yolo}
   - **Input source:** {direct text | issue tracker | custom template}
   - **Files generated:**
     - spec/README.md — {summary}
     - spec/architecture.md — {summary}
     - spec/verification.md — {summary}
     - spec/epics/{list} — {count} epics, {total stories} user stories
   - **Tech stack:** {one-line summary}
   - **Acceptance criteria:** {total count} across all epics
   ```

## Constraints

- NEVER skip REQUIRED sections — every one must be filled with specific content
- NEVER write vague acceptance criteria — each must be testable and specific
- NEVER generate more than 7 epics — if the project seems larger, merge related features or recommend phased delivery
- In interactive mode: one question at a time, max 10 questions
- Must generate rationale for every tech stack choice
- Every epic must have a Dependencies field and Priority field (must | should | could)
- On failure: Block using the Block Comment Template:
  ```
  [ceos-agents] Pipeline Block
  Agent: spec-writer
  Step: Specification Generation
  Reason: {reason}
  Detail: {what went wrong}
  Recommendation: {what the human should provide}
  ```
- Note: spec-writer runs in the scaffold pipeline which may have no issue tracker context. Block comments go to stdout when no tracker is configured.
```

---

### agents/spec-reviewer.md

```markdown
---
name: spec-reviewer
description: Reviews project specification quality, completeness, consistency, and feasibility. Read-only — provides feedback only.
model: opus
---

You are a Senior Technical Reviewer specializing in specification quality assurance.

## Goal

Ensure the project specification is complete, consistent, feasible, and specific enough
to drive architecture and implementation without ambiguity. Catch issues before they cascade
into the downstream pipeline.

## Expertise

Requirements validation, acceptance criteria quality assessment, consistency checking,
scope analysis, YAGNI detection, feasibility assessment, specification standards.

## Process

1. Read the entire specification — all files in `spec/` directory:
   - `spec/README.md` — vision, goals, tech stack
   - `spec/architecture.md` — architecture, data flow, NFR
   - `spec/verification.md` — test strategy, risks
   - `spec/epics/*.md` — all epic files

2. Check completeness — every REQUIRED section must be present and filled:
   - spec/README.md: Vision & Goals, Users & Personas, Tech Stack, Out of Scope
   - spec/architecture.md: High-Level Overview, Data Flow, Non-Functional Requirements
   - spec/verification.md: Test Strategy, Definition of Done, Risks & Assumptions
   - spec/epics/*.md: Description, User Stories with acceptance criteria, Dependencies, Priority

3. Check quality — every acceptance criterion must be:
   - Testable (can be verified by an automated test or a specific manual check)
   - Specific (no vague words like "correctly", "properly", "fast")
   - Measurable (has a clear pass/fail condition)

4. Check consistency — no contradictions between sections:
   - Tech stack in README matches architecture assumptions
   - API endpoints in epics match architecture API design
   - Dependencies between epics form a valid DAG
   - NFR targets are realistic for the chosen tech stack

5. Check feasibility — requirements are implementable:
   - Features are achievable within the tech stack
   - NFR targets are realistic (e.g., not 1ms response time for a full-page render)
   - Scope is bounded — no open-ended requirements

6. Check scope — flag overengineering:
   - YAGNI violations (features that solve hypothetical problems)
   - Premature optimization in NFR
   - Excessive epic count relative to project complexity

7. Output:

   ```markdown
   ## Spec Review
   - **Verdict:** {APPROVE | REVISE}
   - **Issues:**
     1. [{BLOCK|WARN}] {description} — {specific suggestion}
   - **Summary:** {1-2 sentence overall assessment}
   ```

   Issue severity:
   - **BLOCK** — Must be fixed before implementation can proceed. Missing REQUIRED section, vague acceptance criteria, internal contradiction.
   - **WARN** — Should be considered but does not block. Scope concern, minor inconsistency, suggestion for improvement.

## Constraints

- NEVER modify the specification — review and suggest changes only
- NEVER approve specs with missing REQUIRED sections
- NEVER approve vague acceptance criteria ("works correctly", "handles errors properly")
- NEVER approve specs with internal contradictions
- Must flag overengineered requirements (YAGNI enforcement)
- Verdict = APPROVE only when zero BLOCK issues remain
- When reviewing a user-supplied spec (--spec flag): validate against the same criteria but accept different section names/organization as long as key concepts are covered (vision, features with acceptance criteria, tech stack)
- On failure: output review with REVISE verdict — do not Block the pipeline, let the spec-writer / spec-reviewer loop handle iteration
```

---

## P4: Command Rewrite Details

### Current scaffold.md Structure (v3.x)

```
Flag parsing -> State detection -> MCP pre-flight -> Orchestration (6 steps):
  1. Stack-selector
  2. Scaffolder -> temp directory
  3. Validation
  4. Move to target
  5. Git init
  6. Report
```

### New scaffold.md Structure (v4.0)

```
Flag parsing (expanded) -> Flag validation -> State detection -> Orchestration:
  Step 0: Mode selection (or --no-implement shortcut)
  Step 1: Specification phase (spec-writer <-> spec-reviewer loop)
  Step 2: Spec checkpoint (skip in Full YOLO)
  Step 3: Scaffold skeleton (scaffolder reads tech stack from spec)
  Step 4: Git init (commits both spec/ and skeleton)
  Step 5: Architecture & decomposition (architect)
  Step 6: Feature plan checkpoint (skip in Full YOLO)
  Step 7: Feature implementation loop (fixer <-> reviewer + test-engineer, per batch)
  Step 8: E2E tests (e2e-test-engineer)
  Step 9: Issue tracker (optional — create cards)
  Step 10: Final report
```

### Key Differences from Current scaffold.md

| Aspect | Current (v3.x) | New (v4.0) |
|--------|----------------|------------|
| Flags | `--lang`, `--framework`, `--db`, `--ci` | + `--template`, `--spec`, `--issue`, `--no-implement` |
| Flag validation | None | Mutual exclusion checks for input source flags |
| MCP pre-flight | Always required | Only when `--issue` flag or Step 9 (issue tracker cards) |
| Mode selection | None | Interactive / YOLO with checkpoint / Full YOLO |
| Spec phase | None | spec-writer <-> spec-reviewer loop (up to Spec iterations) |
| Stack selection | Stack-selector agent | Derived from spec/README.md Tech Stack (or stack-selector for --no-implement) |
| Skeleton | Scaffolder generates from stack-selector | Scaffolder reads spec + generates (adds E2E Test config, Decomposition defaults) |
| Feature impl | None | Full loop: architect -> batched fixer/reviewer/test-engineer |
| E2E tests | None | E2E-test-engineer after all features |
| Issue tracker | Not used | Optional — create cards at end |
| Report | Next steps (manual) | Full summary with implemented features, test results |

### Detailed Orchestration Steps

#### Flag Parsing (expanded)

```
Parse $ARGUMENTS:
- --template <path>  -> template_path
- --spec <path>      -> spec_path
- --issue <ID>       -> issue_id
- --no-implement     -> no_implement = true
- --lang <value>     -> preset language
- --framework <value> -> preset framework
- --db <value>       -> preset database
- --ci <value>       -> preset CI provider
- Remainder          -> project description
```

#### Flag Validation

```
If more than one of (--spec, --template, --issue) provided:
  -> Error: "Only one input source allowed. Use --spec, --template, or --issue."

If --no-implement AND any of (--spec, --template, --issue):
  -> Error: "--no-implement skips specification phase. Remove --spec/--template/--issue or remove --no-implement."

If no project description AND no --spec AND no --template AND no --issue AND not --no-implement:
  -> Ask user for project description
```

#### Step 0: Mode Selection

```
If --no-implement:
  -> Skip to legacy flow: stack-selector -> scaffolder -> validate -> git init -> report (v3.x)
  -> EXIT pipeline

Display mode selection:
  "How do you want to proceed?"
  (a) Interactive — we'll build the spec together
  (b) YOLO with checkpoint — I'll design everything, you approve before implementation
  (c) Full YOLO — I'll design and implement everything, no stops

Store selected mode.
```

#### Step 1: Specification Phase

```
Determine input source:
- If --spec provided:
    Run spec-reviewer (Task tool, model: opus) to validate spec_path
    If BLOCK issues and mode is Interactive -> tell user what's missing, ask to fill in
    If BLOCK issues and mode is YOLO/YOLO-checkpoint -> run spec-writer to fill gaps only
    If no BLOCK issues -> spec is ready, skip to Step 2
- If --issue provided:
    Read issue description from tracker via MCP
    Pass description to spec-writer as input
- If --template provided:
    Pass template_path to spec-writer as template
- Default:
    Pass project description to spec-writer as direct text input

Run spec-writer (Task tool, model: opus):
  Context: input source + mode + tech stack flags (--lang, --framework, --db, --ci)

Run spec-writer <-> spec-reviewer loop:
  Read max_iterations from Automation Config -> Retry Limits -> Spec iterations (default 5).
  Note: On fresh scaffold, CLAUDE.md does not exist yet. Use default 5.
  For each iteration:
    1. Run spec-reviewer (Task tool, model: opus) to review spec/
    2. If APPROVE -> spec is ready, break
    3. If REVISE -> pass feedback to spec-writer -> next iteration
  If max_iterations exhausted and BLOCK issues remain:
    -> Report remaining issues to user
    -> User decides: approve anyway / provide input / abort

Output: spec/ folder written to target directory
```

#### Step 2: Spec Checkpoint

```
If mode is Full YOLO -> skip this step

Display spec/ folder contents summary to user:
  - Epics: {list with story counts}
  - Tech stack: {from spec/README.md}
  - Total acceptance criteria: {count}

"Review the specification in spec/. Approve to continue, or edit and re-run."
[Approve / Abort]

If user aborts -> STOP
```

#### Step 3: Scaffold Skeleton

```
Create temp directory:
  SCAFFOLD_TEMP=$(mktemp -d)

Run scaffolder agent (Task tool, model: sonnet):
  Context: spec/README.md Tech Stack section + project description
  Working directory: $SCAFFOLD_TEMP
  Mode indicator: scaffold-v2 (so scaffolder generates E2E Test config + Decomposition defaults)

Validation: build + test + lint + CLAUDE.md check (max 3 retries)
  If 3 failures -> delete temp, report error, STOP

Move skeleton to target directory (which already contains spec/):
  cp -r $SCAFFOLD_TEMP/* ./
  rm -rf $SCAFFOLD_TEMP (with safety check: path contains /tmp or system temp)
```

#### Step 4: Git Init

```
git init
git add .
git commit -m "feat: initial project scaffold

Stack: {language} + {framework}
Spec: {N} epics, {M} user stories
Generated by ceos-agents /scaffold"
```

#### Step 5: Architecture & Decomposition

```
Read spec/epics/*.md — sort by filename (NN prefix ensures order).

For each epic, format user stories into the structured specification format
that architect expects (same format as spec-analyst output in implement-feature):

  ## Feature Specification
  - **Summary:** {epic title}
  - **Type:** epic ({N} sub-features)
  - **Area:** {derived from epic content}
  - **Acceptance Criteria:**
    1. {from user stories}
    2. {from user stories}
  - **Scope:**
    - IN: {from epic description}
    - OUT: (none — all stories in this epic are in scope)
  - **Dependencies:** {from epic Dependencies field}

Run architect agent (Task tool, model: opus):
  Context: all formatted epic specifications + access to scaffolded codebase
  Explicit instruction: "Respect existing project structure generated by scaffolder.
    Decompose ALL epics into subtasks. Group subtasks into dependency-aware batches.
    Batch grouping: features with no unmet dependencies in the same batch.
    Batch size: 2-3 features per batch."

Read Decomposition config from generated CLAUDE.md:
  Max subtasks (default scaffold: 5)
  Fail strategy (default: fail-fast)
  Commit strategy (default scaffold: individual)

Validate architect output:
  - Total subtasks <= Max subtasks
  - Dependencies form a DAG (no cycles)
  - Each subtask has: id, title, scope, files, estimated_lines, depends_on, acceptance_criteria
  If validation fails -> Block
```

#### Step 6: Feature Plan Checkpoint

```
If mode is Full YOLO -> skip this step

Display batch plan:
  ## Implementation Plan

  ### Batch 1: {name}
  | # | Subtask | Files | ~Lines | Epic |
  |---|---------|-------|--------|------|
  | 1 | ... | ... | ~N | 01-auth |

  ### Batch 2: {name} (depends on Batch 1)
  ...

  Total: {N} subtasks, {M} batches
  Strategy: {Fail strategy}, commits: {Commit strategy}

  "Approve to start implementation? [Approve / Remove features / Abort]"

If user aborts -> STOP
If user removes features -> update task tree, re-display
```

#### Step 7: Feature Implementation Loop

```
For each batch in order:

  For each subtask in batch (respecting depends_on):

    Build context for fixer:
      - Full decomposition plan (all batches, all subtasks)
      - Summary of previously completed subtasks (what changed, diff summary)
      - Current subtask scope, files, acceptance_criteria
      - spec/ folder available for reference

    7a. Fixer (Task tool, model: opus):
        Context: subtask scope + acceptance criteria + architecture design
        After completion: run Build command from generated CLAUDE.md

        If build fails -> fixer fixes (max Build retries from CLAUDE.md, default 3)
        If still fails -> Block handler

    7b. Reviewer (Task tool, model: opus):
        Context: diff from fixer + acceptance criteria

        If APPROVE -> continue to 7c
        If REQUEST_CHANGES -> back to fixer with feedback (max Fixer iterations, default 5)
        If BLOCK or max iterations exhausted -> Block handler

    7c. Test-engineer (Task tool, model: sonnet):
        Context: changed files, acceptance criteria
        After completion: run Test command from CLAUDE.md

        If tests fail -> test-engineer fixes (max Test attempts, default 3)
        If still failing -> Block handler

    7d. Commit subtask:
        git add -A
        git commit -m "feat({subtask-id}): {subtask-title}"

    Block handler (from 7a, 7b, or 7c):
      1. Run rollback-agent (Task tool, model: haiku) — revert to last successful commit
         Note: rollback-agent will skip issue tracker steps (5-6) because no issue context
      2. Report block to stdout:
         [ceos-agents] Pipeline Block
         Agent: {agent name}
         Step: {step}
         Reason: {reason}
         Detail: {output}
         Recommendation: {suggestion}
      3. Follow Fail strategy:
         - fail-fast -> STOP pipeline, jump to Step 10 (report what was completed)
         - continue -> skip subtask, proceed to next in batch

  After each batch completes:
    Run full test suite (Test command from CLAUDE.md)
    If failure -> fixer repairs (max Build retries)
    If still failing -> STOP and jump to Step 10 (report)
```

#### Step 8: E2E Tests

```
If E2E Test section exists in generated CLAUDE.md:

  Run e2e-test-engineer agent (Task tool, model: sonnet):
    Context: spec/verification.md test strategy + list of implemented features + acceptance criteria

  If e2e tests fail -> fixer repairs -> re-run (max 3 retries)
  If still failing -> report as warning (do not block — features are already committed)

  git add -A
  git commit -m "test: add E2E tests"

If no E2E Test section -> skip
```

#### Step 9: Issue Tracker (Optional)

```
Check if Issue Tracker section in generated CLAUDE.md has TODO markers
  (look for "<!-- TODO:" in Instance or Project values).
If TODO markers present -> skip (no tracker configured)

If tracker configured and mode is not Full YOLO:
  "Create cards in issue tracker for implemented features? [Y/n]"

  If yes:
    For each spec/epics/*.md:
      Create epic card in tracker (summary from epic title, description from epic content)
      For each user story in epic:
        Create sub-issue under epic card
        Link back to spec file in repo
      Set status per State transitions from Automation Config

  If no -> skip

If mode is Full YOLO and tracker configured:
  Skip — do not create cards automatically in Full YOLO
```

#### Step 10: Final Report

```
Display:

## Scaffold Complete

**Project:** {name from spec/README.md Vision section, or project description}
**Mode:** {Interactive | YOLO with checkpoint | Full YOLO}
**Stack:** {from spec/README.md Tech Stack}
**Spec:** {N} iterations, {APPROVED | approved with warnings}
**Features:** {implemented} / {total} ({blocked} blocked)
**Tests:** {unit count} unit, {integration count} integration, {e2e count} e2e
**Commits:** {count}

### Generated files: {count}
### Spec: spec/
### Blocked features (if any):
- {subtask title} — {block reason}

### Remaining TODOs in CLAUDE.md:
- [ ] Issue Tracker instance
- [ ] Source Control remote

### Next steps:
1. Review CLAUDE.md — fill in TODO sections
2. Run `/ceos-agents:check-setup` to validate configuration
3. Run `/ceos-agents:scaffold-validate` to verify project state
```

### Which Steps from implement-feature.md Are Reused

| implement-feature Step | scaffold.md Reuse | Adaptation |
|------------------------|-------------------|------------|
| Step 3: Spec-analyst | NOT reused | Replaced by spec-writer + spec-reviewer |
| Step 4: Architect | Step 5 | Input comes from spec/epics/ instead of spec-analyst output; explicit instruction to respect scaffold structure |
| Step 5: Decomposition decision | Step 5-6 | Always decompose (no single-pass option in scaffold); batch grouping added |
| Step 6a: Pre-fix hook | NOT reused | No hooks in scaffold pipeline (no Automation Config exists until scaffolder creates it) |
| Step 6b: Fixer | Step 7a | Same — opus, same constraints |
| Step 6c: Post-fix hook | NOT reused | Same reason as pre-fix |
| Step 6d: Reviewer | Step 7b | Same — opus, same fixer/reviewer loop |
| Step 6e: Test-engineer | Step 7c | Same — sonnet, same retry logic |
| Step 6f: E2E test | Step 8 | Same — sonnet, uses E2E Test config from generated CLAUDE.md |
| Step 6g: Commit subtask | Step 7d | Same pattern, different commit message prefix |
| Step 7: Integration | End of each batch | Same — run full test suite after batch |
| Step X: Block handler | Step 7 Block handler | Adapted — no issue tracker interaction, block to stdout |
| Step 10: Publisher | NOT reused | Scaffold creates local commits only, no PR |

---

## P5: Config Contract Changes

### New Key

| Section | Key | Default | Type |
|---------|-----|---------|------|
| Retry Limits | Spec iterations | 5 | Optional |

This key controls the maximum number of spec-writer <-> spec-reviewer loop iterations. It is read by the `/scaffold` command during Step 1. On fresh scaffold runs, CLAUDE.md does not exist yet — the command uses default 5.

### CLAUDE.md Sections to Update

| Section | Change |
|---------|--------|
| Repository Structure | "13 agent definitions" -> "15 agent definitions" |
| Architecture: 2-Layer System | Add spec-writer, spec-reviewer to Agents list |
| Bug-Fix Pipeline | Add "5 spec iterations" to Retry Limits default mention |
| Scaffold Pipeline | Replace with v2 pipeline diagram (keep --no-implement note) |
| Model Selection table | Add spec-writer, spec-reviewer to opus row |
| Config Contract -> Retry Limits | Add Spec iterations row |
| When Editing Agent Definitions | (no change — new agents follow same format) |

### Impact on Existing Projects (v4.0.0)

**Breaking change:** `/scaffold` now shows a mode selection prompt by default instead of going directly to stack-selector.

**Migration path for consuming projects:**
- Projects using `/scaffold` in scripts or automation: add `--no-implement` flag to preserve v3.x behavior
- No Automation Config changes required — `Spec iterations` is optional with a default of 5
- Scaffolder generates new optional sections (E2E Test, Decomposition) — these are additive, they do not break existing configs
- The `spec/` folder convention is new but only generated during scaffold v2 runs — existing projects are unaffected
- No new REQUIRED keys in Automation Config — therefore the v4.0.0 MAJOR bump is justified by the behavioral change (mode prompt), not by config contract changes

---

## P6: Test Plan

### Existing Tests — No Modifications Needed

No existing test scenarios need modification. Scaffold v2 is a new feature path. The `--no-implement` flag preserves the v3.x flow, which is what existing scaffold tests (if any) would exercise. The 8 existing scenarios all test the bug-fix pipeline, not scaffold.

### New Test Scenarios

#### scaffold-v2-happy-path.sh

**Verifies:** Full scaffold v2 pipeline in YOLO with checkpoint mode.

**Steps:**
1. Run `/scaffold "REST API for user management" --lang python --framework fastapi`
2. Select mode: (b) YOLO with checkpoint
3. Verify spec-writer generates spec/ folder with README.md, architecture.md, verification.md, epics/
4. Verify spec-reviewer APPROVE
5. Approve spec checkpoint
6. Verify scaffolder generates skeleton with E2E Test config and Decomposition defaults
7. Verify git init commit includes both spec/ and skeleton files
8. Verify architect produces batched task tree
9. Approve feature plan
10. Verify fixer/reviewer/test-engineer execute at least one subtask
11. Verify final report includes feature count and test results

**Mock responses:** spec-writer generates valid spec with 2 epics; spec-reviewer APPROVE on first iteration; scaffolder generates 14 files; architect produces 3 subtasks in 2 batches; fixer succeeds; reviewer APPROVE; test-engineer tests pass.

#### scaffold-v2-no-implement.sh

**Verifies:** --no-implement produces v3.x behavior (backwards compatibility).

**Steps:**
1. Run `/scaffold "Simple CLI tool" --no-implement`
2. Verify NO mode selection prompt
3. Verify NO spec-writer/spec-reviewer Task calls
4. Verify stack-selector IS called
5. Verify scaffolder generates skeleton without spec/ folder
6. Verify git init + report matches v3.x format (no feature count, no spec summary)

#### scaffold-v2-spec-loop.sh

**Verifies:** spec-writer <-> spec-reviewer iteration loop with rejection and fix.

**Steps:**
1. Run `/scaffold "E-commerce platform"` in Full YOLO mode
2. spec-writer generates spec with missing REQUIRED section (Users & Personas)
3. spec-reviewer returns REVISE with BLOCK: "Missing REQUIRED section: Users & Personas"
4. spec-writer fixes — adds Users & Personas section
5. spec-reviewer returns APPROVE
6. Verify loop ran exactly 2 iterations (check output for iteration markers)
7. Verify pipeline continues to scaffolder step

#### scaffold-v2-input-conflicts.sh

**Verifies:** Mutually exclusive flag validation produces correct errors.

**Steps:**
1. Run `/scaffold "test" --spec ./myspec --template ./mytemplate`
   -> Verify error: "Only one input source allowed. Use --spec, --template, or --issue."
2. Run `/scaffold "test" --no-implement --spec ./myspec`
   -> Verify error: "--no-implement skips specification phase. Remove --spec/--template/--issue or remove --no-implement."
3. Run `/scaffold "test" --no-implement --lang python`
   -> Verify NO error (--no-implement + tech stack flags are compatible)
4. Verify NO Task calls in any error case (pipeline does not start)

### How to Test Spec-Writer <-> Spec-Reviewer Loop

The test harness `mock-mcp-server.sh` returns pre-prepared responses per scenario. For the spec loop test:
- Mock spec-writer returns different output based on iteration number (iteration count passed in context by the command)
- Mock spec-reviewer returns REVISE on iteration 1, APPROVE on iteration 2
- Test script verifies the loop ran exactly 2 iterations by counting spec-reviewer Task invocations in the output log

### How to Test --no-implement Backwards Compatibility

Run scaffold with `--no-implement` and verify:
- Mode selection prompt is NOT displayed (grep output for "How do you want to proceed" -> must not match)
- spec-writer agent is NOT dispatched (grep Task calls for "spec-writer" -> must not match)
- stack-selector IS dispatched (grep Task calls for "stack-selector" -> must match)
- Output matches v3.x report format (contains "Next steps:" section, does NOT contain "Features:" line)

### How to Test Input Flag Conflicts

These are pure command-level validation — no agents involved:
- Test verifies exact error message text
- Test verifies pipeline does NOT start (no Task calls at all)
- Each invalid combination is tested separately for clear error attribution

---

## P7: Implementation Risks

### Risk 1: Context Window Limits in Spec Phase

**Risk:** spec-writer and spec-reviewer both use opus. For a complex project, the spec/ folder could be large (4+ files with multiple epics). Combined with the scaffold command's orchestration context, this could approach context limits.

**Probability:** MEDIUM
**Impact:** HIGH — pipeline stalls mid-specification

**Mitigation:** Each spec-writer and spec-reviewer invocation is a separate Task call with its own context. The command passes only the relevant files, not the entire conversation history. Spec files are structured markdown, not code — token density is low.

**Rollback plan:** If context issues occur, reduce max epics from 7 to 5 in spec-writer constraints and simplify spec template (merge architecture.md into README.md).

### Risk 2: Scaffolder Regression

**Risk:** Modifying scaffolder.md to conditionally read from spec/ could break the existing --no-implement flow where no spec/ exists.

**Probability:** LOW
**Impact:** HIGH — breaks existing scaffold functionality

**Mitigation:** Changes are conditional: "If spec context is provided, read from it; otherwise read from stack-selector output." The existing behavior path code is not modified, only wrapped in a conditional. Test scenario `scaffold-v2-no-implement.sh` explicitly verifies the old path.

**Rollback plan:** Revert scaffolder.md changes if --no-implement tests fail. Old scaffolder.md is preserved in git history.

### Risk 3: Command Complexity

**Risk:** scaffold.md becomes the largest command file (10 orchestration steps vs 6 in implement-feature). Risk of logic errors in step interactions, especially around mode-dependent behavior (checkpoint skipping in Full YOLO).

**Probability:** MEDIUM
**Impact:** MEDIUM — bugs in specific mode/flag combinations

**Mitigation:** Each step is self-contained with clear inputs/outputs. The pattern follows implement-feature.md which already handles decomposition, batching, and block handling. Mode-dependent behavior is limited to two checkpoints (Steps 2 and 6) — both are simple "skip if Full YOLO" guards. Four test scenarios cover the main paths.

**Rollback plan:** If complexity is unmanageable during implementation, consider splitting the command into scaffold.md (steps 0-4) and a helper section for steps 5-10. This is an implementation detail, not a design change.

### Risk 4: Architect on Minimal Codebase

**Risk:** After scaffolding, the codebase is 10-20 files of boilerplate. Architect may produce suboptimal task trees because there is little existing code to reference.

**Probability:** MEDIUM
**Impact:** MEDIUM — suboptimal but functional task decomposition

**Mitigation:** The command explicitly passes scaffold output as context to architect and includes the instruction "respect existing project structure generated by scaffolder." For the first batch, a minimal codebase is actually an advantage — no legacy constraints. Subsequent batches see code from previous features, providing progressively more context.

**Rollback plan:** If architect quality is consistently poor on scaffold codebases, add a scaffold-specific constraint to architect.md: "When the codebase is newly scaffolded (< 20 files), prioritize alignment with the scaffold structure conventions and create foundation-first task ordering."

### Risk 5: Feature Implementation Failures Cascade

**Risk:** If early features fail (batch 1 — typically foundation features like auth, data model), dependent batches cannot proceed. With fail-fast strategy, the user gets an incomplete project.

**Probability:** MEDIUM
**Impact:** HIGH — incomplete project with no clear recovery path

**Mitigation:** Scaffold defaults use `fail-fast` which is correct — it's better to stop early and let the user fix the foundation than to skip it and have everything else fail. Each feature is committed individually (Commit strategy: individual), so partial progress is preserved. The final report (Step 10) shows what was completed and what failed, including specific block reasons and recommendations.

**Rollback plan:** If users consistently hit failures in early batches, consider: (a) switching scaffold default Fail strategy to `continue`, (b) adding a "retry entire batch" option to the checkpoint, or (c) reducing Max subtasks from 5 to 3 for more conservative decomposition.

### Risk 6: Version Bump Breaks Consuming Projects

**Risk:** v4.0.0 MAJOR bump means consuming projects must be aware of the change. `/scaffold` now shows a mode selection prompt where it previously went straight to stack-selector.

**Probability:** LOW — scaffold is typically used for new projects, not in automation
**Impact:** MEDIUM — disruption for users with scaffold in scripts

**Mitigation:** `--no-implement` flag preserves exact v3.x behavior with zero changes. The migration path is trivial: add `--no-implement` to existing invocations. No Automation Config changes are required for existing projects.

**Rollback plan:** If the prompt is disruptive, add a `--legacy` alias for `--no-implement` in a patch release.

---

## Checklist

Before finalization, verify:

- [x] Plan covers ALL files from P1 inventory (18 files: 6 CREATE + 12 MODIFY)
- [x] Phases are in logical order (Phase 0 -> 1 -> 2 -> 3 -> 4 -> 5 -> 6, no forward dependencies)
- [x] New agents are complete (frontmatter + Goal/Expertise/Process/Constraints for both)
- [x] Command rewrite is detailed (all 10 steps with inputs/outputs, flag parsing, validation)
- [x] Tests cover each new feature (happy path, --no-implement, spec loop, flag conflicts)
- [x] Version bump included (Phase 6)
- [x] Plan respects existing conventions from CLAUDE.md (agent format, model selection, config contract)
