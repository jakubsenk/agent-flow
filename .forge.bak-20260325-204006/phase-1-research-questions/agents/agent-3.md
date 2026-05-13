# Research Question 3: Agent Merge Feasibility

## Refined Question

For the two confirmed agent merges (ceos spec-analyst + forge spec-writer → unified spec-writer; ceos architect + forge planner → unified planner), what are the exact prompt sections, model assignments, input/output contracts, and constraint sets of each source agent? Where do they have incompatible behaviors, and what is the actual feasibility and recommended strategy for each merge?

---

## Agent Comparison: ceos spec-analyst vs forge spec-writer

### Side-by-Side Comparison

| Dimension | ceos spec-analyst | forge spec-writer (Phase 4) |
|-----------|-------------------|------------------------------|
| **Name** | `spec-analyst` | Phase 4 Specification agent (inline prompt, no standalone agent file) |
| **Model** | sonnet | opus (non-negotiable) |
| **Role persona** | Senior Product Analyst | Domain-matched expert (set by meta-agent via `{{PERSONA}}` slot) |
| **Style** | Requirements-focused, clarity-driven, structured | Visionary (ceos spec-writer); template-driven (forge) |
| **Primary goal** | Extract what needs to be built from an existing issue tracker request — produce a structured specification with 2-7 ACs | Produce a three-layer formal specification (EARS requirements + architecture design + GWT formal criteria) from brainstorm output |
| **Input source** | Issue tracker (reads issue summary, description, comments, custom fields, attachments) | Brainstorm output (`{{BRAINSTORM_OUTPUT}}` from Phase 3 `final.md`) — no issue tracker |
| **Input format** | Unstructured issue text | Prior-phase file on disk (`phase-3-brainstorm/final.md`) |
| **Epic handling** | Explicitly detects single feature vs epic; analyzes up to 5 sub-features; blocks if >5 independent outcomes | No explicit epic detection; outputs a single monolithic spec document |
| **Output format** | Single `## Feature Specification` markdown block (inline, returned to command) | Three separate files: `requirements.md` (EARS), `design.md` (architecture), `formal-criteria.md` (GWT) |
| **Output destination** | Returned in-context to the orchestrating command | Written to `.forge/phase-4-spec/final/` on disk |
| **AC format** | Bullet list (testable outcomes) | Gherkin-style GWT: `Given/When/Then` with REQ-{NNN} traceability IDs |
| **Spec format standard** | Informal markdown bullet spec | EARS notation for requirements (`REQ-{NNN}` IDs, MUST/SHOULD/MAY priority, rationale per requirement) |
| **Architecture content** | Explicitly EXCLUDED: "Extract what needs to be built, not how — that's the architect's job" | INCLUDED: Layer 2 is dedicated architecture design (component diagram, data flow, interface definitions, tech choices) |
| **Issue tracker integration** | Posts two comments: checkpoint comment + separate AC comment | None — no issue tracker in forge pipeline |
| **Block behavior** | Posts Block Comment Template to issue tracker using exact `[ceos-agents] 🔴` format | No issue tracker — blocks go to stdout |
| **Scope detection** | Explicit: detects bugs masquerading as features; guards against too-large requests | None — forge meta-agent handles task classification before Phase 4 |
| **Constraints** | NEVER design architecture; NEVER guess; NEVER modify code; must post AC to tracker | NEVER skip REQUIRED sections; NEVER write vague AC; max 7 epics (ceos spec-writer); traceability to REQ-IDs required |
| **Review/iteration** | Single-pass, no internal review loop | THREE parallel reviewers (spec compliance + quality + devil's advocate); all must PASS; max 3 iterations |
| **Who calls it** | `implement-feature.md` step 3 | `forge-spec` skill (standalone) / forge orchestrator Phase 4 |

### Key Distinctions

1. **Model tier**: ceos uses sonnet (analysis); forge uses opus (creation). This reflects fundamentally different tasks — analysis/extraction vs. formal synthesis.
2. **Architecture scope**: ceos spec-analyst is deliberately architecture-free; forge spec-writer includes architecture in Layer 2. The ceos architect agent handles what forge embeds in the spec.
3. **Formality level**: forge uses EARS notation with REQ-{NNN} IDs; ceos uses informal bullet criteria with AC-1/AC-2 numbering.
4. **Input pipeline position**: ceos spec-analyst reads raw issue tracker data; forge spec-writer reads processed brainstorm output — fundamentally different pipeline positions.
5. **Review infrastructure**: forge has a 3-reviewer loop; ceos spec-analyst has none (the command does not loop on spec-analyst output).

---

## Agent Comparison: ceos architect vs forge planner (Phase 6)

### Side-by-Side Comparison

| Dimension | ceos architect | forge planner (Phase 6) |
|-----------|----------------|--------------------------|
| **Name** | `architect` | Phase 6 Planning agent (inline prompt in `plan-decomposition-prompt.md`) |
| **Model** | opus | opus |
| **Role persona** | Senior Software Architect | Domain-matched expert (set by meta-agent via `{{PERSONA}}` slot) |
| **Style** | Strategic, systems-thinking, trade-off aware | Decomposition-focused (plan decomposition prompt is task-centric) |
| **Primary goal** | Design minimal pragmatic architecture AND generate task tree. Dual role: design + decompose | Decompose a pre-existing specification (from Phase 4) into a parallelizable task graph. Decomposition only — no new architectural design. |
| **Input source** | Specification from spec-analyst (features) OR impact report from code-analyst (bugs) | `requirements.md` + `design.md` (from Phase 4 spec) + `tests/` (from Phase 5 TDD) |
| **Prior phase dependency** | Receives spec-analyst output in-context | Reads three separate files from disk: `phase-4-spec/final/requirements.md`, `phase-4-spec/final/design.md`, `phase-5-tdd/tests/` |
| **Architecture design** | YES — produces high-level design (where to add code, what interfaces change, what to modify) | NO — architecture already exists in `design.md` from Phase 4; planner only decomposes it |
| **Task size limit** | Each subtask ≤ 100 lines diff (hard limit for fixer agent) | Each task ≤ 200 LOC estimated |
| **Max subtasks** | 7 (configurable via Automation Config, default: 7; scaffold: 5) | No explicit cap — implicit by complexity |
| **Traceability format** | `maps_to: ["AC-{N}: {text}"]` linking subtasks to parent AC numbers | `Requirements: REQ-001, REQ-002` — bidirectional: every task maps to REQ-*, every REQ-* maps to at least one task |
| **Dependency strategies** | Three explicit strategies: `sequential`, `parallel`, `mixed` with `depends_on` field | Dependency levels (Level 1, Level 2, ...) with `blocks`/`blockedBy` fields; parallel groups by level |
| **Decomposition decision** | Conditional: decompose ONLY when thresholds exceeded (≥4 files, >60 lines AND ≥3 files, HIGH risk, ≥2 independent changes) | Always decomposes — it is the planner's sole purpose |
| **Output format** | YAML task tree embedded in markdown `## Architecture Design` block | Markdown `# Implementation Plan` with table summary, dependency levels section, detailed tasks per task ID |
| **Task ID format** | `sub-{N}` (e.g., `sub-1`, `sub-2`) | `task-{NNN}` (e.g., `task-001`, `task-002`) |
| **Output destination** | Returned in-context to command + saved to `.claude/decomposition/{ISSUE-ID}.yaml` | Written to `.forge/phase-6-plan/final.md` on disk |
| **Architecture fields** | `title`, `scope`, `files[]`, `estimated_lines`, `depends_on[]`, `maps_to[]`, `acceptance_criteria[]` | `title`, `description`, `blockedBy`, `blocks`, `files[]`, `done criteria`, `tests`, `estimated_lines`, `parallel` |
| **Block behavior** | Posts Block Comment Template to issue tracker; rollback-agent reverts git | No issue tracker — reports to stdout |
| **Cycle detection** | Handled by the orchestrating command (implement-feature step 5) | Validated in forge plan's own review loop (review loop validates DAG) |
| **When decomposition not needed** | Outputs a single implementation plan for fixer (no YAML task tree) | N/A — always produces a task graph |
| **Think step** | Yes: explicit "Think before designing" step with 2-3 approaches, blast radius, rejected alternatives | No explicit think step — persona is set by meta-agent; instructions are direct |
| **Review loop** | None — single-pass, no internal review | Review loop: spec compliance, max 3 rounds; validates DAG + done criteria + requirement traceability |
| **Dual-use** | Used in bug-fix pipeline (with code-analyst input) AND feature pipeline (with spec-analyst input) | Only used in forge pipeline; no bug-fix usage |
| **Who calls it** | `implement-feature.md`, `fix-ticket.md`, `fix-bugs.md`, `scaffold.md` | `forge-plan` skill (standalone) / forge orchestrator Phase 6 |

### Key Distinctions

1. **Architecture vs. decomposition**: ceos architect designs architecture AND decomposes; forge planner only decomposes (architecture already written by Phase 4 spec-writer).
2. **Task size limits**: ceos uses 100-line diff (fixer constraint); forge uses 200 LOC (implementer constraint). Not aligned.
3. **Traceability format**: `maps_to: AC-{N}` (AC index-based) vs `Requirements: REQ-{NNN}` (requirement ID-based). Different schemas.
4. **Dependency fields**: ceos uses `depends_on[]` (subtask IDs); forge uses `blocks`/`blockedBy` (bidirectional). Different graph representations.
5. **Task ID format**: `sub-{N}` vs `task-{NNN}`. Incompatible with any shared downstream processing.
6. **Decomposition trigger**: ceos architect is conditional (decompose only when thresholds exceeded); forge planner always decomposes.
7. **Bug-fix usage**: ceos architect serves the bug-fix pipeline; forge planner has no equivalent.

---

## Cross-References (who calls whom)

### spec-analyst references

| File | Reference | Context |
|------|-----------|---------|
| `commands/implement-feature.md:88` | dispatches spec-analyst (Task tool, sonnet) | Step 3 — spec phase |
| `commands/implement-feature.md:94` | stores `acceptance_criteria` from spec-analyst output | Passes to all downstream agents |
| `commands/implement-feature.md:118` | collects AC from spec-analyst output for coverage check | AC mapping in decomposition step 5 |
| `commands/implement-feature.md:213` | passes full feature AC from spec-analyst to acceptance-gate | Step 6g |
| `commands/implement-feature.md:70` | names spec-analyst in dry-run description | Dry-run check |
| `commands/resume-ticket.md:85` | defines checkpoint `POST_TRIAGE` → start from architect (spec-analyst done) | Resume logic |
| `commands/scaffold.md:261` | formats architect input to match spec-analyst output format | Epic specs for scaffold |
| `commands/dashboard.md:59` | maps block from spec-analyst to triage state | Block category detection |
| `agents/architect.md:22` | reads spec from spec-analyst or code-analyst | Input declaration |
| `agents/architect.md:67` | references spec-analyst/triage-analyst as source of parent AC | maps_to traceability |
| `agents/acceptance-gate.md:21` | reads AC from spec-analyst (features) or triage-analyst (bugs) | Input declaration |
| `agents/rollback-agent.md:25` | names spec-analyst in skip-rollback list | Safety guard |
| `agents/rollback-agent.md:90` | names spec-analyst in NEVER-rollback constraint | Safety constraint |

### spec-writer references

| File | Reference | Context |
|------|-----------|---------|
| `commands/scaffold.md:191` | dispatches spec-writer (Task tool, opus) | Step 1 — spec phase |
| `commands/scaffold.md:194–200` | runs spec-writer ↔ spec-reviewer loop | Iteration loop |
| `commands/scaffold.md:161,181,185,187,189` | routes different input sources to spec-writer | Input source routing |
| `commands/scaffold.md:285` | notes scaffold uses fewer max subtasks because spec-writer pre-decomposes | Downstream note |
| `agents/spec-reviewer.md:124` | references spec-writer/spec-reviewer loop | Constraint (no blocking) |

### architect references

| File | Reference | Context |
|------|-----------|---------|
| `commands/implement-feature.md:98` | dispatches architect (Task tool, opus) | Step 4 |
| `commands/implement-feature.md:102` | handles architect block | Error path |
| `commands/implement-feature.md:107` | reads decompose_mode to trigger architect | Decomposition decision |
| `commands/fix-ticket.md:140` | dispatches architect for bug decomposition | Step 4b |
| `commands/fix-bugs.md:130` | dispatches architect for batch bug decomposition | Step 3c |
| `commands/scaffold.md:277` | dispatches architect for all scaffold epics | Step 5 |
| `commands/scaffold.md:289–296` | validates architect output, per-epic AC coverage check | Validation |
| `commands/resume-ticket.md:85–86` | defines resume checkpoints relative to architect | POST_TRIAGE, POST_ANALYSIS |
| `commands/discuss.md:13–14` | includes architect in default agent_list for /discuss | Default discussion panel |
| `commands/dashboard.md:60` | maps block from architect to analysis state | Block category |
| `agents/spec-analyst.md:13` | distinguishes spec-analyst scope from architect's scope | Domain boundary |
| `agents/spec-analyst.md:71` | NEVER design architecture — that's architect's job | Constraint |
| `agents/rollback-agent.md:25,90` | names architect in skip-rollback list and constraint | Safety guard |

---

## Conflict Points

### Merge 1: spec-analyst + forge spec-writer → unified spec-writer

1. **Model conflict**: spec-analyst uses sonnet; forge spec-writer uses opus. A unified agent must pick one. Sonnet is cheaper but loses the opus-level synthesis quality that forge's three-reviewer loop validates against.

2. **Architecture scope conflict**: spec-analyst explicitly NEVER designs architecture ("that's the architect's job"). Forge spec-writer includes a full architecture design layer (Layer 2: design.md). A merged agent cannot simultaneously exclude and include architecture. This is a fundamental scope boundary conflict.

3. **Output format incompatibility**: ceos produces one inline markdown block consumed in-context. Forge produces three separate disk files. The consuming commands (implement-feature, scaffold) parse spec-analyst output differently than forge reads Phase 4 files.

4. **AC format incompatibility**: ceos uses informal bullet list ACs (AC-1, AC-2 by position). Forge uses EARS REQ-{NNN} IDs with traceability. The architect agent references `AC-{N}` by index from spec-analyst — a forge-style `REQ-{NNN}` ID system would break the `maps_to` format expected by architect and all AC coverage check logic.

5. **Issue tracker integration conflict**: spec-analyst posts checkpoint and AC comments to the issue tracker. Forge spec-writer has no issue tracker context and explicitly routes block output to stdout. A merged agent must handle both contexts (tracked vs. untracked environments).

6. **Pipeline position conflict**: spec-analyst is post-issue-read, pre-architecture. Forge spec-writer is post-brainstorm, and itself includes architecture. A merged agent would need conditional behavior based on what upstream phase provided input.

7. **Epic detection conflict**: spec-analyst has explicit epic detection and sub-feature analysis (up to 5). Forge spec-writer has no epic detection — it produces whatever the brainstorm output described. These are incompatible decomposition strategies at the spec level.

8. **Review loop conflict**: forge spec-writer has a 3-reviewer validation loop as part of Phase 4. spec-analyst has no review loop — the command immediately consumes its output. A merged agent using forge's review loop would require changes to implement-feature.md to handle revision cycles.

### Merge 2: architect + forge planner → unified planner

1. **Scope conflict (architecture vs. decomposition)**: The most fundamental conflict. ceos architect designs architecture AND decomposes. Forge planner ONLY decomposes (architecture is already in Phase 4 spec). A merged agent serving ceos pipelines must produce architecture; serving forge pipeline it must not (architecture already exists). These are mutually exclusive behaviors in terms of output content.

2. **Task size limit conflict**: ceos uses 100-line diff limit (fixer's constraint). Forge uses 200 LOC per task (implementer's constraint). A merged agent cannot enforce both simultaneously — it must parameterize or split by target executor.

3. **Traceability format conflict**: ceos uses `maps_to: ["AC-{N}: {text}"]` (index-based, tied to spec-analyst AC numbering). Forge uses `Requirements: REQ-{NNN}` (ID-based, tied to EARS requirement IDs). The AC coverage check logic in implement-feature.md parses `AC-{N}:` prefix specifically. A different format would break all three commands (implement-feature, fix-ticket, fix-bugs).

4. **Dependency representation conflict**: ceos uses `depends_on: [sub-id]` (unidirectional, subtask IDs). Forge uses `blockedBy`/`blocks` (bidirectional, task-NNN IDs). The implement-feature.md cycle detection algorithm explicitly parses `depends_on` fields. A merged output format would require changes to all three consuming commands.

5. **Decomposition trigger conflict**: ceos architect conditionally decomposes (only when thresholds exceeded — returns a single plan when decomposition not needed). Forge planner always decomposes. A merged agent needs a conditional mode, but forge's pipeline never exercises the "no decomposition" path.

6. **Bug-fix pipeline conflict**: ceos architect serves the bug-fix pipeline with code-analyst impact report input. Forge planner has no bug-fix equivalent — it only receives spec + tests. A unified planner must handle both input types.

7. **Review loop conflict**: ceos architect has no internal review loop. Forge planner has a spec-compliance review loop (max 3 rounds, validates DAG + traceability). A unified agent must conditionally use or skip the review loop based on context.

8. **Task ID format conflict**: `sub-{N}` (ceos) vs `task-{NNN}` (forge). Downstream commands, decomposition YAML saved to `.claude/decomposition/`, and the rollback-agent all reference subtask IDs.

---

## Merge Strategy Assessment

### Merge 1: spec-analyst + forge spec-writer → unified spec-writer

**Feasibility Rating: LOW-MEDIUM (technically possible, architecturally awkward)**

These agents do not overlap — they operate at different pipeline positions with different inputs, outputs, formats, and scopes. The "merge" would actually be a MODE-BASED split:

- **Mode A (ceos pipeline)**: Extract spec from issue tracker. Scope: WHAT only (no architecture). Output: inline markdown block. Issue tracker integration active. AC format: bullet list. No review loop.
- **Mode B (forge pipeline)**: Generate spec from brainstorm output. Scope: WHAT + HOW + FORMAL. Output: three disk files. No issue tracker. EARS + GWT format. Three-reviewer loop.

**Recommended approach**: Do NOT merge into a single agent definition. Instead, create a unified agent with a `mode` parameter that dispatches different internal processes. However, the model difference (sonnet vs opus) and the architecture scope difference are so fundamental that in practice this would be two distinct code paths sharing nothing except the agent name.

A cleaner approach: define the unified agent at the orchestration level (command dispatches the right variant by name) rather than within the agent's own prompt. The ceos pipeline keeps calling the lightweight sonnet version; the forge pipeline calls the opus version with full three-layer output.

**Architecture scope is the hard blocker**: spec-analyst's explicit "NEVER design architecture" constraint is incompatible with forge spec-writer including architecture as Layer 2. Any merge must resolve this by either always including architecture (breaking ceos's architect role boundary) or always excluding it (breaking forge's integrated spec+design output).

### Merge 2: architect + forge planner → unified planner

**Feasibility Rating: MEDIUM (feasible with clear mode separation)**

These agents share more conceptual overlap than spec-analyst vs forge spec-writer — both decompose work into tasks with dependency ordering. However, the scope, format, and input contracts differ significantly.

**Recommended approach**: MODE-BASED agent with explicit modes:

- **Mode A (ceos pipeline)**: Design architecture + conditionally decompose. Input: spec-analyst output OR code-analyst impact report. Output: YAML task tree with `maps_to: AC-{N}` traceability, `depends_on[]`, `sub-{N}` IDs, 100-line limit. No review loop. Single pass.
- **Mode B (forge pipeline)**: Decompose only (architecture already in spec). Input: Phase 4 requirements.md + design.md + Phase 5 tests/. Output: markdown plan with `REQ-{NNN}` traceability, `blocks`/`blockedBy`, `task-{NNN}` IDs, 200-LOC limit. Review loop (max 3 rounds).

The critical requirement: the ceos commands parse specific field names (`depends_on`, `maps_to`, `sub-{N}`) from the task tree YAML. Any unified agent MUST preserve these exact field names in ceos mode, or all three consuming commands (implement-feature, fix-ticket, fix-bugs) need updates to parse a new format.

**If a true unified agent is desired**: The agent definition must use conditional sections clearly labeled by mode, and the consuming orchestrators (ceos commands and forge orchestrator) must pass an explicit mode parameter. The agent's model should be opus in both modes (ceos architect is already opus; forge planner is opus — this is the one non-conflicting dimension).

---

## Files Examined

1. `C:/gitea_ceos-agents/agents/spec-analyst.md` — ceos spec-analyst agent definition
2. `C:/gitea_ceos-agents/agents/spec-writer.md` — ceos spec-writer agent definition (scaffold pipeline)
3. `C:/gitea_ceos-agents/agents/architect.md` — ceos architect agent definition
4. `C:/gitea_ceos-agents/agents/spec-reviewer.md` — ceos spec-reviewer agent definition
5. `C:/gitea_ceos-agents/commands/implement-feature.md` — feature pipeline orchestration
6. `C:/gitea_ceos-agents/commands/scaffold.md` — scaffold pipeline orchestration
7. `C:/gitea_ceos-agents/commands/fix-ticket.md` (partial) — bug-fix pipeline architect usage
8. `C:/gitea_ceos-agents/commands/fix-bugs.md` (partial) — batch bug-fix pipeline architect usage
9. `C:/gitea_ceos-agents/commands/resume-ticket.md` (partial) — resume checkpoint spec-analyst/architect references
10. `C:/gitea_ceos-agents/commands/dashboard.md` (partial) — block state mapping
11. `C:/gitea_ceos-agents/agents/rollback-agent.md` (partial) — skip-rollback lists
12. `C:/gitea_ceos-agents/agents/acceptance-gate.md` (partial) — AC input source
13. `C:/Users/FSABACKY/.claude/plugins/cache/filip-superpowers-marketplace/filip-superpowers/0.1.0/skills/forge/SKILL.md` — forge orchestrator, Phase 4 and Phase 6 dispatch details
14. `C:/Users/FSABACKY/.claude/plugins/cache/filip-superpowers-marketplace/filip-superpowers/0.1.0/skills/forge-spec/SKILL.md` — forge-spec standalone skill
15. `C:/Users/FSABACKY/.claude/plugins/cache/filip-superpowers-marketplace/filip-superpowers/0.1.0/skills/forge-spec/spec-writer-prompt.md` — forge spec-writer agent prompt template
16. `C:/Users/FSABACKY/.claude/plugins/cache/filip-superpowers-marketplace/filip-superpowers/0.1.0/skills/forge-plan/SKILL.md` — forge-plan standalone skill
17. `C:/Users/FSABACKY/.claude/plugins/cache/filip-superpowers-marketplace/filip-superpowers/0.1.0/skills/forge-plan/plan-decomposition-prompt.md` — forge planner agent prompt template
18. `C:/Users/FSABACKY/.claude/plugins/cache/filip-superpowers-marketplace/filip-superpowers/0.1.0/skills/forge/meta-analysis-prompt.md` — Phase 0 meta-agent (Phase 4/6 configuration)

---

## Migration Risks

### High-Severity Risks

1. **AC coverage check breakage (architect merge)**: The commands `implement-feature.md`, `fix-ticket.md`, and `fix-bugs.md` all parse `maps_to: AC-{N}:` prefix explicitly. The AC matching algorithm in implement-feature step 5 is index-based. If the unified planner emits `REQ-{NNN}` instead of `AC-{N}` in ceos mode, all three commands silently fail to detect unmapped AC — a correctness regression with no error output.

2. **ceos architect serves bug pipeline (architect merge)**: The ceos architect is called from `fix-ticket.md` and `fix-bugs.md` with code-analyst impact report input (not spec input). Forge planner has no equivalent input path. A unified planner must handle this third input type, or the bug-fix pipeline loses its decomposition capability. This is a hard regression risk — the forge planner's prompt has no concept of bug impact reports.

3. **Architecture design loss (spec-analyst merge)**: If the unified spec-writer always includes architecture (as forge does), the ceos architect's role boundary is destroyed. Every feature in the implement-feature pipeline would receive architectural prescriptions from the spec stage, then receive potentially conflicting architectural advice from the architect stage — the architect's "Think before designing / reject alternatives" step would be meaningless.

4. **Issue tracker AC posting (spec-analyst merge)**: spec-analyst MUST post AC to the issue tracker as a checkpoint comment. This is a pipeline observability requirement used by resume-ticket to detect `POST_TRIAGE` state. If the unified agent omits this in forge contexts (where no tracker exists), that is expected. But if a consuming command misconfigures the mode, the checkpoint comment is silently lost, breaking `/resume-ticket` detection.

### Medium-Severity Risks

5. **Task ID format cascades (architect merge)**: `sub-{N}` IDs appear in `.claude/decomposition/{ISSUE-ID}.yaml` files which are read by `resume-ticket.md` to restore pipeline state. A task ID format change (`task-{NNN}`) would break resume-ticket for any in-flight tickets mid-decomposition.

6. **Model downgrade risk (spec-analyst merge)**: ceos spec-analyst uses sonnet. If the unified agent upgrades to opus for all invocations (to match forge), token cost per feature ticket increases significantly. ceos runs this agent on every `implement-feature` invocation.

7. **Decomposition trigger loss (architect merge)**: ceos architect's conditional decomposition (single plan when no decomposition needed) is used frequently for small features. If forge's always-decompose behavior is adopted, every small feature in implement-feature gets unnecessarily decomposed into subtasks, adding overhead and git complexity (per-subtask commits, squash logic).

8. **Review loop adoption in ceos pipeline (spec-analyst merge)**: forge's 3-reviewer loop for spec quality is valuable but architecturally incompatible with the current ceos implement-feature flow. implement-feature dispatches spec-analyst and immediately consumes its output — it has no loop handling. Adopting forge's review loop would require a non-trivial refactor of implement-feature orchestration.

9. **Rollback-agent safety list (both merges)**: `rollback-agent.md` has a hardcoded list of read-only agents to skip (`spec-analyst`, `architect`). If agent names change, the safety guard silently breaks — rollback-agent would attempt to revert git state for a read-only agent, find no changes, and fail or succeed vacuously.

10. **discuss command default agents (architect merge)**: `commands/discuss.md` includes `architect` in the default `--agents` list. If the agent is renamed or merged into `planner`, the default discussion panel breaks silently (Task tool would receive an unknown agent name).
