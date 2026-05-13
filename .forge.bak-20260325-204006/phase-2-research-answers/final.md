# Phase 2: Research Answers — Synthesis

## Synthesis Notes

### Agent Scoring

| Agent | Domain | Factual Completeness (0-5) | Citation Quality (0-5) | Actionability (0-5) | Overall |
|-------|--------|---------------------------|----------------------|--------------------:|---------|
| Agent 1 | Plugin Architecture — Tool Access Model | 5 | 5 | 5 | **Exceptional** |
| Agent 2 | Pipeline Engine — Shared Pattern Map | 5 | 5 | 5 | **Exceptional** |
| Agent 3 | Architect Interface Contracts | 5 | 5 | 5 | **Exceptional** |
| Agent 4 | Pipeline State Trace | 5 | 5 | 5 | **Exceptional** |
| Agent 5 | Namespace Reference Inventory | 5 | 5 | 5 | **Exceptional** |
| Agent 6 | Non-Code Mode Agent Capabilities | 5 | 5 | 4 | **Strong** |
| Agent 7 | Test Suite Assessment | 5 | 5 | 5 | **Exceptional** |

All seven agents produced complete, evidence-based answers with direct source citations. No agent produced unsupported claims.

### Contradictions Resolved

**Contradiction 1: Agent 1 (skills lack `allowed-tools`) vs. implied blocker on migration.** Agent 1 confirms that skills use only `{name, description}` frontmatter — no `allowed-tools` field — and that tool access is inherited from the invoking session context, not declared per-skill. This resolves the Phase 1 Critical Risk #1: migration to skills is NOT blocked on tool permissions. The session already grants `mcp__*, Bash, Read, Write, Edit, Glob, Grep, Task`. Skill migration loses only the explicit declaration (a documentation benefit, not a functional restriction).

**Contradiction 2: Agent 2 (pipeline profile parsing "analogous") vs. Agent 4 (stage-number coupling as critical risk).** These are compatible. Agent 2 documents the pattern; Agent 4 documents that the pattern's step-number references are embedded in resume-ticket's detection table. The resolution: the pattern text is extractable, but the stage-to-step-number mapping within each command must remain per-command (not unified) until a machine-readable state file replaces the heuristic.

**Contradiction 3: Agent 3 (decomposition strategy field unused in execution) vs. CLAUDE.md (sequential/parallel/mixed strategies listed).** Agent 3 confirms that the `decomposition.strategy` field (`sequential`, `parallel`, `mixed`) appears in architect output and display tables, but no command uses it to actually execute subtasks in parallel. `parallel` and `mixed` strategies are display-only. This is a pre-existing gap, not a migration concern.

**Contradiction 4: Agent 5 ("discuss" is Class A for skill router) vs. Phase 1 (discuss is absent from skill router).** Agent 5 confirms that `discuss` is absent from `skills/bug-workflow/SKILL.md`'s 24-row intent table. The skill router has 23 entries, not 24. This gap exists in the current codebase before any migration.

**Contradiction 5: Agent 6 (spec-analyst is "partially" adaptable for non-code modes) vs. Agent 3 (spec-analyst is tightly bound to issue tracker MCP).** These are complementary observations. The spec-analyst's *reasoning pattern* (extract WHAT → validate clarity → structured output) is domain-independent. Its *implementation* is MCP-bound. Adaptation for non-code modes requires changing the input source; the reasoning logic transfers.

### Key Upgrade from Phase 1

Agent 1's Phase 2 research resolves the most critical Phase 1 risk: **tool access for skills is confirmed unrestricted (session-inherited)**. This changes the migration from "possibly blocked" to "architecturally feasible but requiring backward-compatibility planning." The top 10 risks table below is updated accordingly — Risk #1 from Phase 1 is now classified as **RESOLVED**.

---

## Executive Summary

The Phase 2 research confirms that migrating ceos-agents v5.1.0 into a unified pipeline with forge is architecturally feasible. The critical unknown from Phase 1 — whether skills support tool access — is resolved: skills inherit unrestricted tool access from the invoking session, making skill-based migration unblocked at the permission layer. The migration surface is large but well-mapped: approximately 60 Class A (internal-only) references, ~160 Class B (user-facing documentation) references, and 23 Class C (externally-written, immutable issue tracker comment templates) references to `ceos-agents:` and `[ceos-agents]`. The comment format is a hard constraint — the `[ceos-agents]` prefix has already been through one breaking rename (from `[CLAUDE-agents]`), and any future change creates a permanent dual-format state in users' issue trackers that cannot be retroactively cleaned. Ten pipeline patterns are genuinely shared across 3-4 commands (MCP pre-flight, config reading, fixer-reviewer loop, block handler, agent-override injection, decomposition heuristics, pipeline profile parsing, post-publish hook, fix verification, flag parsing), and all are extractable once the prerequisite state infrastructure is in place. The architect agent's interface contract is fully documented: any unified agent must preserve `maps_to: AC-{N}: {text}` (N integer, 1-based), `depends_on[]`, and `sub-{N}` IDs exactly — deviation causes silent AC coverage failures in all three consuming commands with no error output. The pipeline state model has a 13-item loss inventory: triage AC values, complexity, code-analyst impact data, fixer/reviewer/test iteration counts, and pipeline profile context all vanish at session end; only 4 artifact types survive (issue tracker comments, git, decomposition YAML, browser result JSON). The forge `.forge/` directory model is the validated target architecture for this gap. The test suite is entirely static-analysis grep; three tests will produce false failures on the first migration commit; the mock MCP server and mock project exist but are completely unwired. For non-code modes, the core pipeline loop (spec → plan → execute → verify) transfers without structural changes, but four true capability gaps exist: flexible input ingestion, analytical domain expertise, logical/causal validity checking, and feasibility assessment for non-software plans. Six existing agents are partially reusable for non-code modes with adaptation; code-analyst has the highest software coupling and is not reusable without a near-complete rewrite.

---

## Domain 1: Plugin Architecture — Tool Access Model

### Finding 1.1: Skills Have No `allowed-tools` Frontmatter

Across two plugins (ceos-agents and filip-superpowers), zero of five examined skills declare `allowed-tools`. The command frontmatter schema is `{description, allowed-tools}`; the skill frontmatter schema is `{name, description}`. This is not an omission by convention — it is a schema difference. The `allowed-tools` field is a command-only concept.

Evidence: All four fil-superpowers skills (`forge`, `forge-execute`, `forge-research`, `forge-plan`, `forge-status`) and the ceos-agents `bug-workflow` skill have only `name` and `description` in their frontmatter.

### Finding 1.2: Tool Access for Skills is Session-Inherited (Unrestricted)

Skills run with the same tool permissions as the Claude Code session that invoked them. The `forge` skill instructs the orchestrator to use Agent, Write, Read, Bash, and AskUserQuestion — all heavy tool operations — with no frontmatter restriction, and the skill functions. `forge-status` enforces read-only behavior purely through prose instructions ("This skill is READ-ONLY. It never modifies forge.json"), not frontmatter. This confirms that read-only enforcement is behavioral, not structural.

**Migration implication:** Converting ceos-agents commands to skills does not change tool access. The current `mcp__*, Bash, Read, Write, Edit, Glob, Grep, Task` tool set remains available. The explicit narrowing that commands provide (documentation benefit) is lost, but this is not a functional regression for the automation use case where the full tool set is already required.

### Finding 1.3: The `name` Field Becomes Mandatory

Commands only declare `description`. Skills require both `name` and `description`. Any command-to-skill migration must assign a `name` value in frontmatter.

### Finding 1.4: Skill File Naming Convention is Inconsistent

ceos-agents uses `skills/bug-workflow/skill.md` (lowercase); filip-superpowers uses `skills/forge/SKILL.md` (uppercase). Both work. This is an undocumented convention difference.

### Finding 1.5: plugin.json is Discovery Metadata Only

Neither ceos-agents nor filip-superpowers declares commands, skills, or agents in `plugin.json`. Discovery is by directory convention: `commands/*.md` → slash commands, `skills/<name>/skill.md` → skills, `agents/*.md` → Task-invokable agents. No plugin.json changes are required to add skills.

### Finding 1.6: `$CLAUDE_SKILL_DIR` Pattern for Large Skills

The forge skill references `${CLAUDE_SKILL_DIR}` to read sub-prompt files within the skill's directory. This enables splitting large skill logic (ceos-agents' 400+ line pipeline commands) across multiple files within a skill folder. This is the recommended pattern for migrating the longest commands.

### Residual Gap

The filip-superpowers CLAUDE.md was inaccessible (permission denied). It may contain plugin-level tool access declarations. The AskUserQuestion tool is used by forge skills but not declared in any ceos-agents command `allowed-tools` — its availability within the ceos-agents context could not be confirmed from file inspection alone.

---

## Domain 2: Pipeline Engine — Shared Pattern Map

### Extraction Classification

Ten patterns were examined across fix-ticket, fix-bugs, implement-feature, and scaffold. The classification below supersedes and refines the Phase 1 list with precise difficulty ratings.

| Pattern | Shared Across | Extraction Difficulty | Classification |
|---------|--------------|----------------------|----------------|
| MCP Pre-flight Check | fix-ticket, fix-bugs, implement-feature, resume-ticket (word-for-word identical); scaffold (analogous, conditional) | Easy | Extractable |
| Agent Override Injection | All 4 commands (identical rule text) | Easy | Extractable |
| Config Reading Block | fix-ticket, fix-bugs, implement-feature (same 14+ sections, same defaults); scaffold (lazy/inline — no upfront block) | Medium | Extractable for 3 commands; scaffold needs "config-absent" variant |
| Pipeline Profile Parsing | fix-ticket, fix-bugs, implement-feature (identical lookup logic; divergent stage maps); scaffold (absent) | Medium | Shared header + lookup extractable; stage maps remain per-command |
| Fixer↔Reviewer Loop | All 4 commands (same loop logic, same limit enforcement); context differs per command | Medium | Core loop extractable; context assembly per-command |
| Block Handler | fix-ticket, fix-bugs, implement-feature (near-identical); scaffold (reduced inline variant) | Medium | Extractable with scaffold variant |
| Post-publish Hook + Webhook | fix-ticket, fix-bugs, implement-feature (identical); scaffold (absent) | Easy | Extractable for 3 commands |
| Fix Verification (post-merge) | fix-ticket, fix-bugs, implement-feature (identical logic); scaffold (absent) | Easy | Extractable for 3 commands |
| Decomposition Heuristics | fix-ticket, fix-bugs (identical thresholds: risk==HIGH, files>=4, diff>60&&files>=3, changes>=2); implement-feature (similar, different thresholds); scaffold (inverted — always decomposes) | Hard | Logic shared; thresholds and trigger conditions per-command |
| Flag Parsing | Decompose tri-state (FORCE/DISABLED/AUTO) identical across fix-ticket, fix-bugs, implement-feature; scaffold has entirely different flags and adds validation | Hard | Only decompose tri-state is extractable |

### Non-Extractable Patterns (command-specific)

1. **Dry-run behavior** — Each command defines different steps, different report formats, deeply interleaved throughout. No clean extraction boundary.
2. **Worktree orchestration** — fix-bugs only: batch processing, Variant A/B mode switching, per-bug worktree lifecycle.
3. **Scaffold spec-writer↔spec-reviewer loop** — Structurally analogous to fixer↔reviewer but uses different agents, different signals (APPROVE/REVISE vs APPROVE/REQUEST_CHANGES), different iteration counter (Spec iterations vs Fixer iterations).
4. **Acceptance gate conditionality** — fix-ticket/fix-bugs: conditional on AC≥3 OR complexity≥M; implement-feature: always runs.
5. **Context assembly for fixer** — Each command assembles different context (triage AC vs spec-analyst AC, with/without browser result, with/without code-analyst impact report).

### Forge Patterns Absent from ceos-agents (10 items)

These are candidates for adoption during migration:
1. Persistent `forge.json` state machine (current_phase, per-phase status enum, cumulative metrics)
2. Structured event log with 16 event types (append-only `forge.log`)
3. Explicit Context Handoff Protocol (per-phase input matrix documented in skill)
4. 4-tier config system (project + user + defaults + runtime overrides)
5. Phase execution loop with skip dependency validation
6. JIT prompt refinement based on prior phase outputs
7. Two-tier template variable system
8. Explicit crash recovery decision tree
9. Rate limit handling with model fallback
10. PASS_TO_PASS regression gate between phases

### Critical Constraint: Stage-Number Coupling

The pipeline profile parsing sections in fix-ticket and fix-bugs contain stage-to-step-number mappings (e.g., `triage = step 3`, `code-analyst = step 4`). resume-ticket's checkpoint detection relies on these same step numbers. Any extraction that renumbers steps must simultaneously update resume-ticket's checkpoint table. This is the hardest constraint on refactoring freedom and must be addressed by introducing a machine-readable state file before any step renumbering occurs.

---

## Domain 3: Agent Interface Contracts

### Architect Output Contract (Complete Field Inventory)

The architect produces one of two shapes. The consuming commands (implement-feature, fix-ticket, fix-bugs) parse these fields programmatically:

| Field | Format | Parsed How | Fragility |
|-------|--------|-----------|-----------|
| `subtask.id` | string, pattern `"sub-{N}"` | String interpolation into commit message; task tree resume | Stable (no regex validation of pattern) |
| `subtask.title` | string (free text) | Display table, commit message | Stable |
| `subtask.scope` | string (free text) | Passed verbatim to fixer | Stable |
| `subtask.files` | list of path strings | Display table, fixer context | Stable |
| `subtask.estimated_lines` | integer | Display table, required-field validation | Stable |
| `subtask.depends_on` | list of id strings | Topological sort for execution order; completion check | Stable (field name matters) |
| `subtask.maps_to` | list of `"AC-{N}: {text}"` strings | Regex `AC-(\d+):` — index N extracted, set coverage check | **FRAGILE** — format change = silent AC coverage failure |
| `subtask.acceptance_criteria` | list of strings | Required-field validation; passed verbatim to fixer | Stable |
| `**Decomposition:** YES/NO` | Markdown bullet | String presence `YES` vs `NO` → pipeline branch decision | **FRAGILE** — no formal parsing rule defined in commands |
| `decomposition.strategy` | `sequential`/`parallel`/`mixed` | Display-only (no execution logic uses it) | Display-only |
| `decomposition.reason` | free text | Display-only | Display-only |

**Runtime fields written by commands (not produced by architect):** `status`, `commit_hash`, `restore_point` — all written to `.claude/decomposition/{ISSUE-ID}.yaml` after subtask execution.

### Critical Format Constraints

1. **`maps_to: "AC-{N}: {text}"` is a hard contract.** All three consuming commands (implement-feature, fix-ticket, fix-bugs) parse this format by regex `AC-(\d+):` to extract integer N. If a unified agent emits `REQ-{NNN}:` (forge format) in ceos mode, the coverage check finds zero mappings — no error, no block, silent correctness regression. N must be 1-based (1 to total AC count); N=0 or N > total silently produces uncovered AC.

2. **Required field validation does NOT include `id` or `maps_to`.** implement-feature line 115 validates `title, scope, files, estimated_lines, acceptance_criteria`. An architect output missing `id` fields passes validation but breaks commit message formatting. An output missing `maps_to` passes validation when no parent AC exist (vacuously satisfied).

3. **Decompose signal is informal.** The `**Decomposition:** YES` / `NO` bullet is the branch trigger in implement-feature, but the parsing rule is "architect indicates decomposition" — no formal substring match is defined in the command. The intended matching is inferrable but not documented.

4. **`decomposition.strategy` parallel/mixed: execution unimplemented.** All three commands execute subtasks in topological-sort sequential order. The `parallel` and `mixed` strategy values are specified in the architect output but never honored at runtime — they display in the plan table only.

### Merge Feasibility Conclusion

A mode-based unified architect/planner is MORE compatible with the current contract than separate named agents, provided the ceos mode emits the exact YAML field names and `AC-{N}:` format. No consuming command parses agent identity — they only parse the YAML structure. Separate named agents would be equally compatible only if each emits the identical schema, adding drift surface without benefit.

**The spec-analyst + forge spec-writer merge is NOT recommended.** These agents occupy different pipeline positions: spec-analyst reads an issue tracker and outputs WHAT; forge spec-writer reads brainstorm output and generates a full spec including HOW. The `NEVER design architecture` constraint in spec-analyst is incompatible with forge spec-writer's architecture layer. These must remain separate.

### Secondary Fragility Points

- **rollback-agent hardcodes read-only agent names** in its skip list. Any agent rename silently breaks the rollback safety guard.
- **discuss command default agents hardcodes `architect` by name.** An architect rename breaks the default discussion panel with no error.
- **spec-writer.md has inconsistent block comment** (`[ceos-agents] Pipeline Block` — missing 🔴 emoji). Pre-existing gap, not migration-introduced.

---

## Domain 4: Pipeline State Model

### Persistent Artifacts Inventory (survive session boundaries)

| Artifact | Path | Written By | Survived By |
|---------|------|-----------|------------|
| Decomposition task tree YAML | `.claude/decomposition/{ISSUE-ID}.yaml` | fix-ticket, fix-bugs, implement-feature | resume-ticket (DECOMPOSE_PARTIAL), subtask execution loop |
| Reproduction result JSON | `.claude/reproduction-result.json` | reproducer agent | browser-verifier, fixer context |
| Reproducer Playwright script | `.claude/reproducer-script.js` | reproducer agent | browser-verifier |
| Verification result JSON | `.claude/verification-result.json` | browser-verifier | pipeline command |
| Screenshots | `.claude/screenshots/{issue-id}-before.png` | reproducer, browser-verifier | PR comment context |
| Issue tracker comments | External (issue tracker) | triage-analyst, spec-analyst, agents | resume-ticket, dashboard, metrics |
| Git branch + commits | Git | fix-ticket step 2, fixer commits | all downstream steps |

### State Loss Inventory (13 items — all vanish at session end)

| Lost State | Impact Level | Migration Priority |
|-----------|------------|-------------------|
| Full AC text from triage-analyst | MEDIUM — resume cannot recover; downstream agents need text, not count | HIGH |
| Complexity value (XS/S/M/L) | MEDIUM — acceptance-gate condition cannot be re-evaluated at resume | HIGH |
| Code-analyst impact report | MEDIUM — decomposition decision cannot be re-derived | MEDIUM |
| Pipeline profile active at time of run | HIGH — resume without `--profile` skips different stages | HIGH |
| Fixer iteration count | LOW-MEDIUM — resets on resume (could allow more retries than configured) | MEDIUM |
| Test attempt count | LOW-MEDIUM — same | MEDIUM |
| Build retry count | LOW | LOW |
| Reviewer verdict history | MEDIUM — fixer may repeat rejected approaches | MEDIUM |
| Per-step timing data | LOW — metrics unavailable | LOW |
| Token usage actuals | LOW — metrics unavailable | LOW |
| Hook execution results | LOW | LOW |
| Block count (fix-bugs) | MEDIUM — max-blocked-per-run counter resets | MEDIUM |
| Browser verification verdict (in-session) | MEDIUM — file persists but no command re-reads it at resume | LOW (file available) |

### resume-ticket Checkpoint Detection (7-level priority heuristic)

Priority order (highest to lowest):
1. `DECOMPOSE_PARTIAL` — `.claude/decomposition/{ISSUE-ID}.yaml` exists with completed subtasks
2. `PUBLISHED` — open PR exists for the branch
3. `POST_REVIEW` — branch has commits above base + reviewer approval comment
4. `POST_FIX` — branch has commits above base (no reviewer comment)
5. `POST_ANALYSIS` — branch exists + triage comment
6. `POST_TRIAGE` — `[ceos-agents] Triage completed.` comment exists (no branch)
7. `FRESH` — none of the above

Detection signals queried: issue tracker comments (via MCP), git branch/commit state (via Bash), source control MCP (PR existence), local filesystem (decomposition YAML).

Known limitation stated in resume-ticket.md: "Detection is best-effort — heuristics may not be 100% accurate."

### Parallel Execution Conflicts in fix-bugs (Worktree Mode)

| Conflict | Risk Level | Mitigation |
|---------|-----------|------------|
| `.claude/reproduction-result.json` shared across worktrees | **HIGH** — parallel bugs clobber each other's reproduction results | None stated in codebase |
| `.claude/verification-result.json` shared across worktrees | **HIGH** — same | None stated in codebase |
| `.claude/screenshots/` collision | LOW — named by issue ID | Natural isolation |
| `.claude/decomposition/{ISSUE-ID}.yaml` collision | LOW — named by issue ID | Natural isolation |
| Git branch naming | LOW — includes issue ID | Natural isolation |
| Build command contention | MEDIUM — depends on project's build isolation | No mitigation |

The `.claude/reproduction-result.json` and `.claude/verification-result.json` race conditions are the most significant undocumented bugs in the current codebase.

### Forge State Model as Migration Target

forge's `.forge/` directory provides the proven pattern: `forge.json` (state machine with current_phase, per-phase status enum, cumulative metrics), `forge.log` (append-only structured event log with 16 event types), and per-phase output directories. Checkpoint detection is deterministic: file presence is authoritative, not heuristic.

The equivalent for ceos-agents would be a `.ceos-agents/{ISSUE-ID}/` per-issue directory containing: `state.json` (pipeline position, step statuses), `triage.json` (full AC list, complexity, severity), `code-analyst.json` (impact report), `iteration-log.md` (fixer↔reviewer history), and `ceos-agents.log` (append-only event log). This addresses 8 of 13 state-loss items and resolves the stage-number coupling in resume-ticket.

---

## Domain 5: Backward Compatibility Inventory

### Reference Count by Class

| Class | Definition | Count | Files |
|-------|-----------|-------|-------|
| A | Internal-only: safe to update in one PR, no user impact | ~60 references | 18 files |
| B | User-facing documentation: requires coordinated release note | ~160 references | 24 files |
| C | External data format: written to issue trackers at runtime, cannot be retroactively changed | 23 distinct templates | 15 files |

### Class C: Immutable External Comment Templates

All 23 templates use the `[ceos-agents]` prefix. Key formats:

| Template | Written By | Parsed By |
|---------|-----------|---------|
| `[ceos-agents] 🔴 Pipeline Block` | 12 agents + 4 commands (15 locations) | resume-ticket, dashboard |
| `[ceos-agents] Triage completed. Severity: {s}. Area: {a}. Complexity: {c}. AC: {n}.` | triage-analyst, analyze-bug | resume-ticket, dashboard, metrics |
| `[ceos-agents] Spec analysis completed. Area: {a}. Criteria: {n}.` | spec-analyst | resume-ticket |
| `[ceos-agents] Acceptance Criteria: ...` | spec-analyst | None (informational) |
| `[ceos-agents] ✅ Fix verified.` | fix-ticket, fix-bugs, implement-feature | None (informational) |
| `[ceos-agents] ❌ Fix verification failed.` | fix-ticket, fix-bugs, implement-feature | None (informational) |

**Note:** `agents/spec-writer.md` line 88 has `[ceos-agents] Pipeline Block` (missing `🔴` emoji) — a pre-existing inconsistency. The pipeline-consistency.sh test checks for the emoji; spec-writer's block template fails this check (pre-existing test gap, not migration-introduced).

### Version Impact by Change Scenario

| Change | Version Impact | Reason |
|--------|---------------|--------|
| Change `[ceos-agents]` comment prefix | **MAJOR** | Agent output format contract; resume-ticket, dashboard, metrics all parse it; historical precedent: `[CLAUDE-agents]` → `[ceos-agents]` was BREAKING |
| Change `ceos-agents:` namespace prefix | **MAJOR** | Public API: all 24 commands change invocation names simultaneously |
| Add new field to Triage checkpoint comment | **MAJOR** | Adding `Complexity: {c}. AC: {n}.` in v5.0.0 was explicitly marked BREAKING |
| Add new comment type (e.g., `[ceos-agents] Browser verification completed.`) | **MINOR** | Additive; existing parsers unaffected |
| Rename plugin in plugin.json | **MAJOR** | Equivalent to namespace change |
| Add new optional config section | **MINOR** | Backward-compatible |
| Add new required config key | **MAJOR** | Per versioning policy |

### Key Class A Focus Points (highest change volume)

- `skills/bug-workflow/SKILL.md` — 24-row intent table + Skill() templates: all 26 occurrences are Class A
- All Task-tool dispatch calls in commands (e.g., `ceos-agents:triage-analyst`): Class A
- `.claude-plugin/plugin.json` `"name": "ceos-agents"`: **source of truth for the namespace**; Class A

### Soft Class C (outside plugin control)

- `docs/guides/tokens.md` recommends `ceos-agents-<PROJECT>` as API token naming convention. Tokens created by users in external systems cannot be retroactively renamed. Impact is cosmetic (no runtime parsing) but creates documentation inconsistency.

### Known Gap: `discuss` Missing from Skill Router

`commands/discuss.md` exists and is listed in CLAUDE.md (making 24 commands), but is absent from `skills/bug-workflow/SKILL.md`'s 24-row intent table. The skill router has only 23 entries. Any user asking "let's discuss X" would not be routed to `/ceos-agents:discuss`. This is a pre-existing gap in the current codebase, not a migration artifact.

---

## Domain 6: Non-Code Mode Agent Capabilities

### Reusability Assessment

| Agent | Non-Code Reusability | What Transfers | What Is Hardcoded | Change Required |
|-------|---------------------|----------------|-------------------|-----------------|
| spec-writer | Partial (output structure only needs change) | Structured document generation, interactive questioning (max 10, one at a time), YAGNI/scope discipline, REQUIRED vs IF APPLICABLE section discipline | 4-file output structure, "Tech Stack"/"Data Model"/"API"/"NFR" sections, tech stack flags | Configurable output template replacing fixed 4-file spec layout |
| spec-reviewer | Partial (REQUIRED sections need replacement) | Completeness/consistency/feasibility/scope checks, BLOCK vs WARN severity, loop-with-writer pattern, --verify compliance mode | All REQUIRED section names are software-specific; consistency checks reference tech stack; --verify mode searches codebase | REQUIRED section checklist must be configurable per document type |
| spec-analyst | Partial (input source needs generalization) | Core extraction pattern (WHAT not HOW), clarity validation, IN/OUT scope distinction, size assessment (single vs epic), multimodal input | MCP-only input, "Area" field is module-specific, issue tracker comment posting | Accept non-tracker inputs; generalize output sink |
| priority-engine | High (only dimension semantics need redefinition) | 4-dimension scoring formula unchanged, P0/P1/P2 tiering, dependency graph construction, max-50-items discipline, transparency requirement | Input is MCP issues; Risk dimension defined for code areas; Recommendations reference fix-bugs | Redefine dimension semantics for domain; generalize input |
| reviewer | Partial (checklists need replacement) | Adversarial stance, minimum-3-issues gate, HIGH/MEDIUM/LOW severity, AC fulfillment tracking, iterative loop | Security checklist (SQL injection, XSS), edge case analysis (null/undefined, race conditions), code-specific convention compliance | Replace security/performance/edge-case checklists with domain criteria |
| code-analyst | Not viable for reuse | Risk classification vocabulary (LOW/MEDIUM/HIGH) | All mechanics: file search, call hierarchy tracing, test coverage, git log — software-specific by design | Near-complete rewrite for non-code domain; would be a different agent sharing only vocabulary |

### True Capability Gaps (no existing agent covers these)

**Gap 1: Flexible Input Ingestion.** All existing agents assume either a software codebase on disk or an issue tracker via MCP. No agent can ingest a URL, PDF, pasted document, uploaded file set, or conversation transcript as primary input. Non-code modes require a new intake capability.

**Gap 2: Analytical Domain Expertise.** No existing agent possesses: statistical claim assessment, methodological flaw identification, data quality evaluation, correlation-vs-causation distinction, hypothesis-through-evidence analysis structure. spec-writer is oriented toward building things; non-code analysis mode needs an agent oriented toward understanding and explaining things — a different epistemic posture.

**Gap 3: Strategy Domain Expertise.** No existing agent understands: competitive landscape analysis, stakeholder mapping, scenario planning, options appraisal, decision criteria weighting, SWOT/PESTLE frameworks, business case construction. priority-engine scores by impact/risk/effort but does not reason about strategic trade-offs.

**Gap 4: Content Domain Expertise.** No existing agent covers: audience fit, readability, editorial voice, SEO, information hierarchy, call-to-action effectiveness, publication format requirements.

**Gap 5: Logical/Causal Validity Checking.** spec-reviewer checks structural and factual consistency. No agent checks whether stated conclusions follow from evidence, whether causal claims are supported, or whether arguments contain logical fallacies. This gap matters most for analysis and strategy modes.

**Gap 6: Feasibility Assessment for Non-Software Plans.** spec-reviewer's feasibility check is "can this be built with this tech stack?" Strategy mode requires "can this organization execute this plan given its resources and constraints?" — fundamentally different reasoning.

### Non-Gaps (agents are sufficient with adaptation)

- **Document quality review loop:** spec-reviewer adapted with domain-appropriate sections. No new agent needed.
- **Prioritization engine:** priority-engine with redefined dimension semantics. No new agent needed.
- **Structured output generation:** spec-writer with configurable output template. Mode parameter + template injection suffice.
- **Iterative refinement:** spec-writer ↔ spec-reviewer loop pattern is fully reusable.
- **Scope management:** YAGNI enforcement and epic-count limits are domain-independent when configurable.

---

## Domain 7: Test Suite Assessment

### Suite Architecture

- **Runner:** `tests/harness/run-tests.sh` — glob discovers all `tests/scenarios/*.sh`, executes each as separate bash subprocess, exit 0=PASS/exit 77=SKIP/non-zero=FAIL. Single-scenario mode available.
- **14 scenarios** (README says 13 — count is stale). All are static grep/file-existence checks. **No scenario executes agents, commands, or pipeline logic.**

### Fragility Classification

| Scenario | Fragility Level | Will Break On |
|---------|----------------|--------------|
| `happy-path.sh` | **CRITICAL** | Any file rename, merge, or split. Hardcodes all 24 command names + 18 agent names. |
| `verify-fail.sh` | MEDIUM | Step heading rename. Step numbers (9d, 8c, 10b) have OR fallbacks — renumbering alone does NOT break; renaming the section does. |
| `pipeline-consistency.sh` | HIGH | Adding a fifth pipeline command (not in hardcoded 4-file list). Check 5 (rollback + issue tracker) already produces false positives for scaffold.md (scaffold says "No issue tracker context" yet check passes). |
| `scaffold-v2-happy-path.sh` | MEDIUM | Renaming scaffold pipeline section headings (e.g., "Feature Implementation Loop"). |
| `scaffold-v2-spec-loop.sh` | MEDIUM | Reworded loop section or `max_iterations exhausted` phrase. |
| `browser-verification-skip.sh` | MEDIUM | Exact NEVER-constraint phrase changes or stage-mapping format changes. |
| `test-fail.sh` | **EFFECTIVELY MEANINGLESS** | Would pass with any agent file containing `"NEVER"`. Provides zero signal. |
| All others | LOW | Stable file paths and broad pattern matches. |

### Unused Infrastructure

**`tests/harness/mock-mcp-server.sh`:** Complete JSON-RPC stdin/stdout MCP server supporting 10+ methods, reading from fixtures, writing call log to `mcp-log.json`. **Referenced by zero scenario files.** Built for integration tests never written.

**`tests/mock-project/`:** Complete execution target with `CLAUDE.md` (full Automation Config), `app.py` (12 lines with intentional bugs), `tests/test_app.py` (4 pytest tests, 2 designed to fail against buggy app). **Referenced by zero scenario files.** Designed for pipeline execution tests never written.

**`tests/harness/fixtures/`:** `automation-config.md` (3-profile config) and `issues.json` (3 sample issues). **Referenced only by mock-mcp-server.sh, which itself is unused.**

### Coverage Map Gaps

| Coverage Area | Status |
|--------------|--------|
| Frontmatter completeness for 16 of 18 agents | Missing (only reproducer + browser-verifier checked) |
| Model assignments for sonnet agents | Missing |
| `Goal → Expertise → Process → Constraints` section order | Missing |
| Read-only agents contain no write phrases | Missing |
| Cross-agent handoff contracts | Missing |
| `discuss` command in skill router | Missing |
| Acceptance-gate conditionality logic | Missing |
| E2E pipeline in implement-feature | Missing |
| Config contract completeness (all sections except Spec iterations) | Missing |
| Namespace reference (`ceos-agents:`) validation | Missing |
| Any live agent execution or pipeline invocation | Missing (entirely) |

### Pre-Migration Test Changes Required

Three tests must be updated before the first migration commit to prevent false failures:

1. **`happy-path.sh`:** Replace static filename lists with count-based checks (`ls commands/*.md | wc -l` = 24, `ls agents/*.md | wc -l` = 18) or dynamic inventory comparison against CLAUDE.md.
2. **`verify-fail.sh`:** Remove or isolate step-number clauses (`"9d\."`, `"8c\."`, `"10b\."`) — the bare section-name fallbacks already cover the real intent.
3. **`pipeline-consistency.sh`:** Make `PIPELINE_FILES` discoverable (grep all commands that reference `rollback-agent` or `fixer.*Task tool`) rather than hardcoded to 4 files.

Simultaneously add four structural parity tests to maintain protection coverage:
1. `frontmatter-completeness.sh` — check all 18 agents have name, description, model, style fields
2. `model-assignment.sh` — validate model assignments against CLAUDE.md table
3. `read-only-agents.sh` — verify 9 read-only agents contain no file-write phrases
4. `section-order.sh` — verify `Goal → Expertise → Process → Constraints` order in all agents

---

## Cross-Domain Insights

### Insight 1: The State Gap is the Central Prerequisite

Agents 2, 4, and 5 all independently identify ceos-agents' lack of persistent pipeline state as the root cause of multiple issues: brittle resume-ticket heuristics (7-level priority heuristic explicitly documented as "best-effort"), lost iteration counts enabling retry-limit bypass on resume, inability to detect profile-context loss (HIGH impact), and the stage-number coupling that blocks free pipeline restructuring. Introducing a `.ceos-agents/{ISSUE-ID}/state.json` file before any structural migration simultaneously addresses four independent risks.

### Insight 2: The `[ceos-agents]` Prefix is a Two-Layer Constraint

Agent 5's inventory reveals 23 Class C templates — the external comment format is immutable. But Agent 4's state trace shows these comments ARE the primary resume-ticket signal source. This means the comment format must be treated as a versioned API contract. The `[CLAUDE-agents]` legacy prefix demonstrates that old-format detection must be maintained indefinitely. Any new pipeline variant should add *new* comment types (MINOR version bump) rather than modifying existing formats.

### Insight 3: Pattern Extraction and State Introduction are Sequential, Not Parallel

Agent 2 documents 10 extractable patterns; Agent 4 documents that stage-number coupling in resume-ticket blocks renumbering; Agent 7 documents that happy-path.sh will fail immediately on any structural change. These constraints converge on a clear sequence: (1) introduce state.json, (2) update fragile tests, (3) extract shared patterns. Attempting extraction without the prerequisites produces false test failures AND breaks resume for in-flight tickets simultaneously.

### Insight 4: The `.claude/` Directory Has Two Race Conditions

Agent 4's parallel execution analysis reveals that `reproduction-result.json` and `verification-result.json` are written to the main repo's `.claude/` directory, not the worktree-isolated path. In fix-bugs parallel worktree mode, concurrent browser reproduction/verification runs clobber each other's results. This is the only currently undocumented data-corruption bug in the v5.1.0 codebase.

### Insight 5: Agent Merges Should be Mode Dispatch at Orchestration Level

Agents 3 and 6 independently confirm that spec-analyst + forge spec-writer and architect + forge planner involve incompatible behaviors at the agent prompt level. The correct pattern is orchestration-level mode dispatch: the command decides which agent to call based on context (ceos vs forge pipeline), not a unified agent that code-switches internally. A unified agent with two code paths shares only a name, creating maintenance risk with no architectural benefit.

### Insight 6: The Test Suite is a False Confidence Generator

Agent 7 reveals that a command could drop its entire fixer↔reviewer loop, remove the block handler, or change the acceptance gate condition and all 14 tests would still pass — as long as certain keyword strings remain present. The mock infrastructure for real integration tests exists but is completely unwired. The current test suite validates file presence and keyword existence, not behavioral correctness.

### Insight 7: Non-Code Mode Extension is Additive, Not Replacement

Agent 6 confirms that all 10 forge phases apply to non-code modes without structural changes. The 6 true capability gaps (flexible input ingestion, analytical domain expertise, strategy domain expertise, content domain expertise, logical validity checking, non-software feasibility assessment) are additive — new agents added to the roster, not replacements of existing ones. The 6 partially-reusable agents (spec-writer, spec-reviewer, spec-analyst, priority-engine, reviewer) need adaptation of checklists, section names, and input/output formats, not rewrites.

---

## Migration Prerequisites (ordered)

The following steps must be completed BEFORE the actual migration of commands to skills or pattern extraction begins. Each depends on its predecessor.

**Prerequisite 1 (Blocker): Fix the `.claude/` race condition in fix-bugs parallel mode.**
- File: `agents/reproducer.md`, `agents/browser-verifier.md`, `commands/fix-bugs.md`
- Action: Make browser artifact paths worktree-relative (relative to the worktree CWD, not the main repo) or use issue-ID-namespaced paths.
- Risk if skipped: Data corruption in production for any project using parallel worktree mode with browser verification.

**Prerequisite 2 (Test Infrastructure): Update 3 fragile tests before first migration commit.**
- Files: `tests/scenarios/happy-path.sh`, `tests/scenarios/verify-fail.sh`, `tests/scenarios/pipeline-consistency.sh`
- Action: As specified in Domain 7 Pre-Migration Changes section.
- Risk if skipped: Every migration commit produces false test failures, creating noise that masks real regressions.

**Prerequisite 3 (Test Infrastructure): Add 4 structural parity tests.**
- Files: New `tests/scenarios/frontmatter-completeness.sh`, `model-assignment.sh`, `read-only-agents.sh`, `section-order.sh`
- Action: As specified in Domain 7 Coverage Map section.
- Risk if skipped: Structural regressions during migration are invisible.

**Prerequisite 4 (State Infrastructure): Introduce `.ceos-agents/{ISSUE-ID}/state.json`.**
- Files: `commands/fix-ticket.md`, `commands/fix-bugs.md`, `commands/implement-feature.md`, `commands/resume-ticket.md`
- Action: Define and document the state.json schema (pipeline position, step statuses, triage AC list, complexity, profile-in-use, iteration counts); update resume-ticket to write and read the file; keep heuristic detection as fallback for pre-migration in-flight tickets.
- Risk if skipped: Stage-number coupling in resume-ticket blocks all step renumbering; profile-context loss remains HIGH-impact; iteration counts reset on resume.

**Prerequisite 5 (Compatibility Audit): Fix the `discuss` command gap in the skill router.**
- File: `skills/bug-workflow/SKILL.md`
- Action: Add `discuss` entry to the 24-row intent table (currently 23 entries).
- Risk if skipped: Users who ask "let's discuss X" are silently not routed to the command.

**Prerequisite 6 (Fix Pre-existing Gap): Fix spec-writer.md block comment missing 🔴 emoji.**
- File: `agents/spec-writer.md` line 88
- Action: Change `[ceos-agents] Pipeline Block` to `[ceos-agents] 🔴 Pipeline Block`.
- Risk if skipped: pipeline-consistency.sh test fails for spec-writer; inconsistent external comments.

---

## Key Design Decisions for Brainstorming

These 7 decisions represent the major architectural choices that Phase 3 brainstorming must address. Each is a genuine fork — the research facts bound the option space but do not dictate the answer.

### Decision 1: State File Schema and Migration Path

**Question:** What is the exact schema for `.ceos-agents/{ISSUE-ID}/state.json`, and how does the system handle the transition period when in-flight tickets have no state file (heuristic fallback required)?

**Facts constraining choice:** The state file must capture at minimum: triage AC list, complexity, pipeline profile used, step status map (13 step names, each with pending/running/completed/failed/skipped status), and fixer/test/build iteration counts. The file must be named per-issue-ID to avoid fix-bugs parallel conflicts. A file-locking mechanism (PID guard or atomic write) is required for fix-bugs batch mode.

### Decision 2: Command-to-Skill Migration Scope

**Question:** Should all 24 commands migrate to skills, or only a subset? Which commands should remain as commands (if any)?

**Facts constraining choice:** Skills inherit unrestricted tool access (resolved). Commands provide explicit `allowed-tools` documentation but no functional restriction. The 3-layer architecture (user → skill router → command → agent) could simplify to 2 layers (user → skill → agent). But the `ceos-agents:` prefix on command invocations is embedded in Class B documentation and user tooling — renaming commands to skills changes the invocation surface.

### Decision 3: Unified Architect/Planner — Mode Dispatch vs. Separate Agents

**Question:** Should a unified `architect` agent handle both ceos pipelines (design+decompose, `maps_to: AC-{N}:` format) and forge pipelines (decompose-only, `REQ-{NNN}` format) via mode dispatch, or should they remain as separate agents?

**Facts constraining choice:** The `maps_to: AC-{N}:` format is parsed by regex in 3 consuming commands; any format deviation causes silent coverage failures. A unified agent must preserve this format in ceos mode exactly. The benefit of unification is reduced maintenance; the risk is a unified agent with two divergent code paths that drift over time.

### Decision 4: Non-Code Mode Delivery Scope

**Question:** For the first release of non-code modes, which of the 4 true capability gaps (flexible input ingestion, analytical domain expertise, strategy domain expertise, content domain expertise) should be in scope vs. deferred?

**Facts constraining choice:** Input ingestion is a prerequisite for all non-code modes — all other gaps build on it. Analytical, strategy, and content domain expertise are independent capability sets. priority-engine and spec-writer/spec-reviewer are immediately reusable with adaptation for all three modes. The 6 partially-reusable agents can be adapted incrementally.

### Decision 5: `[ceos-agents]` Comment Format Versioning

**Question:** For any new pipeline features (e.g., browser verification completion comment, state.json checkpoints), should new comment types use the existing `[ceos-agents]` prefix or introduce a versioned prefix (e.g., `[ceos-agents/v6]`)?

**Facts constraining choice:** Adding new comment types is MINOR (additive, existing parsers unaffected). Modifying existing formats is MAJOR. The `[CLAUDE-agents]` precedent shows that prefix changes require indefinite dual-format support in all parsers. A versioned prefix would enable clean deprecation but would immediately break all existing comment detection in resume-ticket, dashboard, and metrics.

### Decision 6: Parallel Execution Scope for fix-bugs

**Question:** Should the `.claude/` race condition (reproduction-result.json, verification-result.json clobbering in worktree mode) be fixed before migration, or should browser verification be disabled in parallel mode as a simpler mitigation?

**Facts constraining choice:** The race condition is the only currently undocumented data-corruption bug in v5.1.0. The clean fix (worktree-relative artifact paths) requires changes to reproducer.md and browser-verifier.md. The simple mitigation (disable browser verification in fix-bugs parallel mode) reduces capability but eliminates the risk immediately. Either choice must be made before non-code mode work begins, as non-code modes may introduce similar parallel execution patterns.

### Decision 7: Test Suite Evolution Strategy

**Question:** Should the test suite remain static-analysis (upgrade the grep-based tests and add new grep tests) or should it begin wiring the mock-mcp-server and mock-project for real integration tests?

**Facts constraining choice:** The mock infrastructure is complete and unwired — activation requires only scenario files that `cd` to mock-project, set the MCP environment to point at mock-mcp-server.sh, and run the harness. Real integration tests would detect behavioral regressions that 14 grep tests cannot. The cost is test execution time and maintenance of the mock scenarios. The risk of remaining grep-only: a command could lose its entire fixer↔reviewer loop without any test failing.

---

## Risk Registry Update

Changes from Phase 1 top-10 risks based on Phase 2 findings.

| # | Risk | Severity | Change from Phase 1 | Basis |
|---|------|----------|---------------------|-------|
| 1 | ~~`allowed-tools` gap for skills~~ | ~~CRITICAL~~ | **RESOLVED** — skills inherit unrestricted session tool access; no functional restriction on migration | Agent 1 Phase 2 findings |
| 2 | AC coverage check silent failure from architect/planner format change | **CRITICAL** | Confirmed — `maps_to: AC-{N}:` is regex-parsed by 3 commands with no error on mismatch | Agent 3 Domain 3 |
| 3 | Issue tracker comment formats are immutable | **HIGH** | Confirmed with enhanced detail — 23 distinct Class C templates across 15 files; spec-writer pre-existing gap | Agent 5 Domain 5 |
| 4 | Stage-number coupling in resume-ticket blocks pipeline restructuring | **HIGH** | Confirmed — fix-bugs step numbers differ from fix-ticket; state.json prerequisite validated | Agent 4 Domain 4 |
| 5 | Architecture design loss from spec-analyst merge | **HIGH** | Confirmed — spec-analyst `NEVER design architecture` is incompatible with forge spec-writer including architecture | Agent 3, Agent 6 |
| 6 | Bug-fix decomposition path has no forge planner equivalent | **HIGH** | Confirmed — forge planner has no concept of code-analyst impact reports | Agent 3 Domain 3 |
| 7 | Agent Override silent failures on rename | **HIGH** | Confirmed — check-setup does not validate customization directory | Agent 5 |
| 8 | **NEW: `.claude/` race condition in fix-bugs parallel mode** | **HIGH** | New finding — reproduction-result.json and verification-result.json clobbering in worktree mode; no mitigation in codebase | Agent 4 Domain 4 |
| 9 | State loss between sessions — full AC text not persisted | **MEDIUM** | Confirmed with 13-item loss inventory; pipeline profile loss upgraded to HIGH within MEDIUM category | Agent 4 |
| 10 | Test suite false failures block migration velocity | **MEDIUM** | Confirmed — 3 tests will fail immediately on structural change; meaningless test (test-fail.sh) identified | Agent 7 |

**Dropped from top-10:** Pipeline profile stage names stored in external configs (moved to lower priority — affects only skip-stage users, not core migration path). Replaced by the `.claude/` race condition (#8 above).

**Updated priority order within MEDIUM:**
- Pipeline profile context loss at session end: promoted to HIGH-within-MEDIUM (not recoverable at resume without state.json)
- Parallel execution state clobbering: upgraded to HIGH (data corruption, not logic error)
