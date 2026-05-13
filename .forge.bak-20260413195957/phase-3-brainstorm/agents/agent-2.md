# Phase 3 — Agent 2: Brainstorm Areas 4-6

**Date:** 2026-04-13
**Scope:** Area 4 (State Schema Improvements), Area 5 (Missing Best Practices), Area 6 (Structural Improvements)

---

## Area 4: State Schema Improvements

### 4.1: Semantic Field Overloading — triage.* reused for spec-analyst

**Finding:** In feature mode, `implement-feature/SKILL.md` line 182 writes spec-analyst output to `triage.status` and `triage.acceptance_criteria` with the comment "(field reused for spec-analyst AC)". In scaffold mode, `scaffold/SKILL.md` line 434 does the same: "(field reused for spec-writer phase)". The `triage.*` field group was designed for bug triage (severity, area, complexity, reproduction_steps) but is now the canonical store for three conceptually different things: bug triage output, feature specification output, and scaffold specification output. A consumer reading `triage.severity = null` cannot distinguish "triage not run yet" from "this is a feature pipeline where severity is not applicable".

**Impact:** MEDIUM — does not break current execution (skills hardcode knowledge of which fields they use), but degrades observability, makes state.json misleading for external tools (dashboards, /status, /metrics), and creates a trap for future Agent Overrides or custom agents that read state.

**Approach A: Parallel field groups (new `spec_analysis.*` section alongside `triage.*`)**
- Add `spec_analysis` top-level section: `spec_analysis.status`, `spec_analysis.acceptance_criteria`, `spec_analysis.area`, `spec_analysis.summary`, `spec_analysis.type` (single_feature/epic). Leave `triage.*` exclusively for bug mode.
- Scaffold gets a further `scaffold_spec.*` or reuses `spec_analysis.*` (since spec-writer produces the same structure).
- Skills write to the section matching their mode. Downstream agents read from the correct section based on `mode` discriminator.
- Pros: Cleanest semantic model. Each field group maps to exactly one agent. External tools can distinguish modes trivially. No ambiguity about null fields.
- Cons: Increases schema surface area. Requires schema_version bump (non-breaking: new optional sections). Downstream consumers (acceptance-gate, reviewer, fixer) need to know which section to read — but they already need mode context from the skill dispatch.
- Effort: MEDIUM — new schema section, update 3 skill files (implement-feature, scaffold, fix-bugs) to write to new section, update state-manager docs, update /status and /dashboard if they read triage fields.
- Backward compatibility: MINOR version bump. Old state.json files still work (new sections are optional). New state.json files are readable by old consumers (triage.* remains for bug mode).

**Approach B: Discriminator fields (add `ac_source`, `analysis_source` to existing groups)**
- Add `triage.ac_source` field: enum `"triage-analyst" | "spec-analyst" | "spec-writer"`. This tells consumers what produced the data in this section.
- Add `code_analysis.analysis_source` field: enum `"code-analyst" | "architect"`.
- Keep field groups as-is. Null fields are expected when the source is different (e.g., `triage.severity = null` is normal when `triage.ac_source = "spec-analyst"`).
- Pros: Minimal schema change (2 new optional fields). No refactoring of downstream consumers. Backward compatible (missing discriminator = legacy or bug mode).
- Cons: Still semantically confusing — `triage.acceptance_criteria` holding feature AC is a misnomer regardless of discriminator. Dashboard/metrics tools still need conditional logic. Does not solve the "scaffold has no state section" problem.
- Effort: LOW — add 2 fields to schema.md, update 3 skill files to write discriminator.

**Approach C: Full schema v2 with mode-aware sections**
- schema_version = "2.0". Top-level sections are mode-dependent:
  ```json
  {
    "schema_version": "2.0",
    "mode": "code-feature",
    "phases": {
      "specification": { "status": "completed", "agent": "spec-analyst", ... },
      "design": { "status": "completed", "agent": "architect", ... },
      "implementation": { "status": "in_progress", ... },
      ...
    }
  }
  ```
- Each phase is named semantically, not by the bug-mode agent name. The `agent` field records which agent executed the phase.
- Pros: Cleanest long-term design. Extensible for new modes. Self-documenting.
- Cons: Breaking change — schema_version bump to 2.0 = MAJOR version. All consumers (skills, /status, /dashboard, /metrics, /resume-ticket, external tools) need migration. High effort.
- Effort: HIGH — complete rewrite of state schema, migration of all state-reading code (12+ skill files, 4+ core contracts, 3 utility skills).

**Recommendation:** Approach A (parallel field groups). It strikes the right balance: clean semantics, moderate effort, non-breaking (MINOR). Approach B is a band-aid that does not resolve the conceptual mismatch. Approach C is the "right" long-term answer but the effort/risk ratio is too high for the current benefit. Approach A can be a stepping stone toward C if ever needed.

Specific proposal for Approach A:
```json
"spec_analysis": {
  "status": "pending",
  "agent": "spec-analyst",
  "acceptance_criteria": [],
  "area": null,
  "summary": null,
  "type": null,
  "dependencies": null,
  "constraints": null
}
```
- `implement-feature` writes to `spec_analysis.*` instead of `triage.*`.
- `scaffold` writes to `spec_analysis.*` with `agent: "spec-writer"`.
- `fix-ticket` and `fix-bugs` continue to write to `triage.*`.
- For the v1→v1.1 migration: `triage.*` remains in schema for all modes (backward compat), `spec_analysis.*` is optional (absent = bug mode or legacy).

---

### 4.2: code_analysis.* reused for architect output

**Finding:** `implement-feature/SKILL.md` line 192 writes architect output to `code_analysis.status` with "(field reused for architect output)". The `code_analysis.*` section has fields `risk`, `affected_files`, `estimated_diff_lines` — these semantically describe bug impact analysis, not feature architecture design. Architect output is structurally different: it produces architecture design, task trees, risk assessment, and approach rationale.

**Impact:** MEDIUM — same category as 4.1 but narrower scope (only 1 skill reuses these fields vs 2 for triage).

**Recommendation:** Follow the same Approach A pattern. Add a `design` top-level section:
```json
"design": {
  "status": "pending",
  "agent": "architect",
  "risk": null,
  "decomposition_indicated": false,
  "subtask_count": null,
  "strategy": null
}
```
- `implement-feature` writes to `design.*` instead of `code_analysis.*`.
- `fix-ticket` writes to `code_analysis.*` (architect output goes to `design.*` when decomposition is triggered there too).
- Migration path: same as 4.1 — optional new section, backward compatible.

---

### 4.3: Scaffold has no dedicated state sections

**Finding:** Scaffold pipeline uses the generic state schema but shoehorns data into fields designed for bug-fix. Scaffold-specific data (infrastructure declarations, spec writer iterations, scaffolder scorecard, spec compliance check) has no home in the schema. The `infrastructure` section exists but only covers infra declaration — not the scaffolder execution, validation, or compliance steps.

**Impact:** LOW-MEDIUM — scaffold works today because the skill manages its own flow, but /status, /resume-ticket, and /dashboard cannot provide meaningful scaffold-specific status (they would show misleading triage/code_analysis data from the reused fields).

**Recommendation:** Add scaffold-specific optional sections as part of the Approach A effort:
```json
"scaffold": {
  "spec_iterations": 0,
  "spec_max_iterations": 5,
  "scorecard": null,
  "git_init": false,
  "pushed": false,
  "compliance_verdict": null
}
```
This is LOW effort (new optional section, update scaffold skill only) and dramatically improves observability for scaffold runs.

---

### 4.4: Missing `ac_source` field

**Finding:** Phase 2 identified that acceptance criteria flow through the pipeline with no provenance tracking. A downstream agent (reviewer, acceptance-gate) cannot determine whether AC came from triage-analyst (bug), spec-analyst (feature), or spec-writer (scaffold). This matters because:
- Triage-analyst AC are inferred from a bug report (may be incomplete)
- Spec-analyst AC are extracted/inferred from a feature request (higher confidence)
- Spec-writer AC are written from scratch (highest confidence, validated by spec-reviewer)

Different AC sources warrant different strictness levels in downstream verification.

**Impact:** LOW — does not cause failures today, but limits the acceptance-gate's ability to calibrate its strictness.

**Recommendation:** If Approach A from 4.1 is adopted, `ac_source` becomes implicit: AC in `triage.*` = from triage-analyst, AC in `spec_analysis.*` = from spec-analyst or spec-writer (the `spec_analysis.agent` field disambiguates). No separate `ac_source` field needed — the structural separation IS the provenance. This is another argument for Approach A over Approach B.

---

## Area 5: Missing Best Practices

### 5.1: Mode awareness pattern from acceptance-gate

**Finding:** The acceptance-gate agent (line 21 in the Process section) explicitly handles different AC sources: "Read the acceptance criteria from context (from triage-analyst for bugs, spec-analyst for features)." This is the ONLY shared agent that explicitly acknowledges it receives input from different upstream agents depending on mode. Other shared agents (fixer, reviewer, test-engineer, publisher) have no such awareness — they implicitly assume bug-mode context.

**Impact:** HIGH — acceptance-gate's explicit mode awareness is the gold standard pattern. It should be replicated in all 4 shared execution/review agents. Without it, agents may apply bug-specific heuristics to feature work (e.g., fixer saying "Read the triage analysis" when there is no triage analysis in feature mode).

**Best practice to replicate:**

For each shared agent, add an explicit "Input Source Mapping" in the Process section, step 1:

**Fixer** (currently says "Read the triage analysis and impact report"):
```
1. Read the upstream analysis:
   - Bug mode: triage analysis (from triage-analyst) + impact report (from code-analyst)
   - Feature mode: specification (from spec-analyst) + architecture design (from architect)
   - Scaffold mode: specification (from spec-writer) + architecture design (from architect)
   If upstream analysis or design is missing, Block with reason 'Missing input from previous pipeline stage'.
```

**Reviewer** (currently says "Read the original bug report, triage analysis, impact report"):
```
1. Read the upstream context:
   - Bug mode: original bug report + triage analysis + impact report + fixer output
   - Feature mode: feature specification + architecture design + fixer output
   - Scaffold mode: project specification + architecture design + fixer output
```

**Test-engineer** (currently says "Read the bug report, fixer output, and impact report"):
```
1. Read the upstream context:
   - Bug mode: bug report + fixer output (changed files, root cause) + impact report
   - Feature mode: feature specification + fixer output (changed files, approach) + architecture design
   - Scaffold mode: project specification + fixer output + architecture design
```

**Publisher** (needs mode-specific behavior, not just input mapping — see 5.2).

This pattern has zero risk (it adds clarity without changing behavior) and LOW effort (text additions to 4 agent files).

---

### 5.2: Publisher mode-aware PR titles and commit prefixes

**Finding:** Publisher currently uses a single format: `[PROJ-123] Fix: {description}`. This is correct for bugs but misleading for features and scaffolds. Conventional Commits (widely adopted, understood by changelogs and semantic-release tooling) dictate different prefixes per change type.

**Impact:** MEDIUM — incorrect prefix does not break anything but degrades developer experience, confuses changelog generators, and misrepresents the nature of the change in git history.

**Approach A: Mode-aware prefix table in publisher agent**
Add to publisher Process step 4 (Stage and Commit):
```
Commit prefix selection based on pipeline mode (from skill dispatch context):
| Mode | Commit prefix | PR title prefix | Example |
|------|--------------|-----------------|---------|
| code-bugfix | fix({scope}): | Fix: | fix(auth): prevent token expiration [PROJ-123] |
| code-feature | feat({scope}): | Feature: | feat(auth): add OAuth2 support [PROJ-456] |
| code-project | init({scope}): | Init: | init(project): scaffold FastAPI application |
```
- Pros: Single point of truth. Publisher already reads the issue, so it knows the context. Aligns with Conventional Commits spec.
- Cons: Publisher is haiku-model — adding conditional logic increases complexity for a mechanical agent.
- Effort: LOW — text addition to publisher.md, no structural changes.

**Approach B: Skill passes explicit prefix to publisher**
The orchestrating skill (fix-ticket, implement-feature, scaffold) passes the desired prefix as part of the publisher context: `Commit prefix: feat`. Publisher uses it mechanically without needing to understand modes.
- Pros: Publisher stays purely mechanical. Mode logic stays in skills where it belongs.
- Cons: Requires updating 3 skill files to pass the prefix. Minor additional context parameter.
- Effort: LOW — 3 skill file updates + 1 agent text update.

**Recommendation:** Approach B. It follows the existing architecture principle: skills know WHAT, agents know HOW. Publisher should not need to understand pipeline modes — the skill should tell it what prefix to use. This keeps the haiku agent simple and moves intelligence to the skill layer.

Implementation detail for Approach B:
- `fix-ticket` dispatches publisher with: `Commit prefix: fix, PR title prefix: Fix:`
- `implement-feature` dispatches publisher with: `Commit prefix: feat, PR title prefix: Feature:`
- `scaffold` dispatches publisher with: `Commit prefix: init, PR title prefix: Init:`
- Publisher step 4 becomes: "Use commit prefix from skill context. If not provided, default to `fix` (backward compatibility)."
- Publisher step 6 (PR title) becomes: "Use PR title prefix from skill context. If not provided, default to `Fix:` (backward compatibility)."

---

### 5.3: Test-engineer in scaffold mode — missing test infrastructure handling

**Finding:** Test-engineer assumes test infrastructure exists: "Run test command from Automation Config", "Run existing tests first", "Place tests in the correct test directory". In scaffold mode, the test-engineer runs AFTER the scaffolder, which generates test infrastructure (Batch 3). But: (1) the CLAUDE.md might have `<!-- TODO: -->` placeholders in the test command, (2) the test framework might not be installed yet (scaffolder may have generated config but not run `npm install` / `pip install`), (3) the generated test directory structure is brand new and may differ from what test-engineer expects from existing projects.

**Impact:** MEDIUM — can cause test-engineer to block on "No test command configured" or fail silently by writing tests that do not integrate with the scaffold's test infrastructure.

**Best practice — add scaffold mode awareness to test-engineer:**

```
1b. Scaffold mode detection:
    If this is a scaffold pipeline (context indicates spec-writer/scaffolder upstream):
    - Read the generated CLAUDE.md Build & Test section. If test command contains
      <!-- TODO --> placeholders → Block with "Test command not yet configured in CLAUDE.md."
    - Check that test framework dependencies are installed (run the package manager's
      install command if needed: npm install / pip install / go mod download)
    - Read the scaffolder's test infrastructure files (conftest.py, setup files) to
      understand the generated test patterns BEFORE writing new tests
    - Reference the scaffolder's scorecard: if Tests = PASS, the infrastructure is valid.
      If Tests = FAIL, the infrastructure needs fixing before adding more tests.
```

**Approach A: Add scaffold-aware steps to test-engineer agent**
- Pros: Self-contained — test-engineer handles its own edge cases.
- Cons: Increases agent complexity. Scaffold-specific knowledge in a shared agent.
- Effort: LOW — text additions to test-engineer.md.

**Approach B: Skill pre-validates test infrastructure before dispatching test-engineer**
- The scaffold skill checks scaffolder scorecard (Tests = PASS?) before dispatching test-engineer. If FAIL, it runs scaffolder fix-up first.
- Pros: Keeps test-engineer mode-agnostic. Validation logic in the skill where it belongs.
- Cons: Does not help with the "read scaffolder's patterns" aspect — test-engineer still needs to understand the generated structure.
- Effort: LOW — skill-level check only.

**Recommendation:** Both, layered. Approach B (skill pre-validates infrastructure) + Approach A (test-engineer step 1 includes scaffold mode detection for reading generated patterns). The skill handles the "is infrastructure ready?" gate, while the agent handles "how do I adapt to this project's testing setup?" This mirrors how fixer gets architecture context in feature mode — the agent should be told what mode it is in and adapt its reading strategy.

---

### 5.4: Reviewer AC Fulfillment — conditional section not mode-aware enough

**Finding:** Reviewer line 108 says: "If acceptance criteria were provided in context, MUST include AC Fulfillment section in output. If no AC provided, skip the section." This is a passive approach — it waits for AC to show up in context. But the reviewer does not actively seek AC from the correct source based on mode. In bug mode, AC come from triage-analyst. In feature mode, AC come from spec-analyst. The skill dispatch passes AC, but if the skill forgets or passes incomplete AC, the reviewer silently skips AC verification.

**Impact:** LOW — skills currently pass AC correctly, but the reviewer has no self-check mechanism.

**Recommendation:** Add an explicit AC source expectation to reviewer:
```
   - **AC source verification:** In bug mode, expect AC from triage-analyst output.
     In feature mode, expect AC from spec-analyst output. If AC are expected but
     not provided in context, note in output: "WARNING: No acceptance criteria
     provided. AC fulfillment check skipped." This is NOT a blocking issue —
     the reviewer completes its code quality review regardless.
```
Effort: LOW — text addition to reviewer.md.

---

## Area 6: Structural Improvements

### 6.1: spec-reviewer used in 3 incompatible roles in scaffold

**Finding:** The spec-reviewer agent is dispatched in scaffold with three distinct responsibilities:
1. **Validation role** (line 405): Validate a user-supplied `--spec` path. Read-only, checks completeness/quality.
2. **Iteration role** (line 421-428): Review spec-writer output in a spec-writer/spec-reviewer loop. Read-only, provides APPROVE/REVISE feedback.
3. **Compliance role** (line 729): `--verify` mode — compare implemented code against spec. Read-only, produces IMPLEMENTED/PARTIALLY/MISSING verdicts per AC.

Roles 1 and 2 are similar (both review specification quality) but role 3 is fundamentally different — it reviews CODE against SPEC, not SPEC against quality criteria. The --verify mode is already a separate Process section in the agent definition (lines 77-128), showing that the agent author recognized the distinction.

**Impact:** MEDIUM — the current agent handles all 3 roles via the `--verify` flag, but it increases cognitive load (one agent, two very different evaluation frameworks). More importantly, it limits specialization: the compliance role could benefit from deeper code analysis capabilities (understanding test assertion patterns, tracing AC to function signatures) that would bloat the specification review role.

**Approach A: Split spec-reviewer into 2 agents (spec-reviewer + spec-compliance-checker)**
- `spec-reviewer` keeps roles 1 and 2 (specification quality review). Unchanged from current except removing the `--verify` section.
- New `spec-compliance-checker` agent (sonnet model — it reads code, similar to acceptance-gate) takes role 3. It gets the full `--verify` Process section.
- Pros: Clean separation of concerns. Each agent has one clear job. compliance-checker can evolve independently (e.g., adding deeper code tracing). Model selection can differ (opus for spec review quality, sonnet for code scanning).
- Cons: 20th agent. Need to update scaffold skill to dispatch different agent at step 7b. Adds to the "19 agents" inventory.
- Effort: MEDIUM — extract --verify section into new agent file, update scaffold skill reference, update CLAUDE.md agent count, update tests.

**Approach B: Keep unified but add explicit role parameter**
- spec-reviewer receives a `role` parameter from the skill: `role: review` (roles 1+2) or `role: verify` (role 3).
- Agent switches behavior based on role parameter instead of --verify flag.
- Pros: No new agent. Minimal change.
- Cons: Still one agent with two identities. Role parameter is functionally equivalent to --verify flag — cosmetic improvement.
- Effort: LOW — rename flag to role parameter, no structural change.

**Approach C: Keep as-is, improve documentation**
- Add a clear "Roles" section at the top of spec-reviewer explaining the 3 usage contexts.
- Pros: Zero structural change.
- Cons: Does not address the fundamental issue of one agent doing two very different things.
- Effort: LOW.

**Recommendation:** Approach A (split into spec-reviewer + spec-compliance-checker). The compliance role is different enough in its input (code + spec vs spec alone), its evaluation framework (AC-to-code mapping vs quality criteria), and its optimal model (sonnet for code scanning vs opus for quality judgment) that it deserves its own agent. The acceptance-gate agent already validates AC-to-code mapping for individual subtasks — the compliance checker validates the entire spec against the full codebase. They are complementary but operate at different scopes.

However, the timing matters. If this audit is targeting a MINOR release, Approach C (documentation) for now + Approach A planned for next MINOR. If this audit is a MAJOR rework, Approach A immediately.

---

### 6.2: No code-analyst before architect in implement-feature

**Finding:** The bug-fix pipeline runs code-analyst before the fixer to map impact zones and identify risk. The feature pipeline skips code-analyst entirely and goes straight from spec-analyst to architect. This means the architect designs the implementation without a systematic analysis of the existing codebase's call hierarchy, test coverage gaps, and risk zones.

The architect's step 3 says "Read affected codebase areas thoroughly" — but this is a manual read-and-understand step, not the systematic impact analysis that code-analyst provides (call hierarchy tracing, dependency mapping, test coverage assessment, historical bug pattern analysis).

**Impact:** MEDIUM — architect compensates by reading the codebase, but misses the structured analysis that code-analyst provides. This is especially risky for features that modify existing code (not greenfield additions).

**Approach A: Add code-analyst step before architect in implement-feature**
- After spec-analyst (step 3), before architect (step 4), run code-analyst.
- Context: spec-analyst's output (area, affected modules) instead of triage output.
- Code-analyst would need a minor adaptation: skip bug-specific steps (reproduction walkthrough) in feature mode, focus on dependency mapping and test coverage of the affected area.
- Pros: Architect gets systematic codebase analysis. Risk assessment is data-driven, not intuition-based.
- Cons: Adds a pipeline step (cost + latency). For greenfield features that add new modules with no existing code to analyze, code-analyst adds nothing.
- Effort: MEDIUM — update implement-feature skill (new step between 3 and 4), update code-analyst agent (feature mode awareness — skip reproduction walkthrough, adjust output format).

**Approach B: Architect incorporates code-analyst's systematic methodology**
- Add code-analyst's systematic analysis steps (call hierarchy tracing, test coverage assessment, historical analysis) to the architect's Process, as prerequisite steps before design.
- Pros: No additional pipeline step. No added cost/latency.
- Cons: Bloats architect agent. Mixes analysis and design responsibilities. Goes against the principle of single-responsibility agents.
- Effort: LOW-MEDIUM — significant text additions to architect.md.

**Approach C: Conditional code-analyst — only for modification-heavy features**
- After spec-analyst, check: does the specification indicate modification of existing code (vs purely additive)?
- Heuristic: if spec-analyst's area maps to existing source files (Glob/Grep check by the skill), run code-analyst. If the area is new (no matching files), skip.
- Pros: Cost-efficient — only pays for analysis when it adds value.
- Cons: Adds conditional logic to the skill. The heuristic may misclassify borderline cases.
- Effort: MEDIUM — conditional logic in skill + code-analyst feature mode awareness.

**Recommendation:** Approach C (conditional code-analyst). It captures the value of systematic codebase analysis for modification-heavy features while avoiding unnecessary cost for greenfield additions. The heuristic is simple: after spec-analyst identifies the area, the skill runs `Glob` for existing files in that area. If matches exist, dispatch code-analyst. If no matches, skip directly to architect.

This also addresses the `decomposition-heuristics.md` contract issue from Phase 2 (CRQ-11): in feature mode with code-analyst, the contract's threshold-based heuristics become applicable (code-analyst provides the `risk`, `affected_files`, `estimated_diff_lines` fields). Without code-analyst, the architect's own scope estimation drives the decomposition decision (current behavior, which works for greenfield).

---

### 6.3: Tracker subtask creation duplicated across 3 skills (~540 lines)

**Finding:** The "Create tracker subtasks" step is copy-pasted with identical logic across three skills:
- `implement-feature/SKILL.md` Step 5a (lines 246-399) — ~153 lines
- `fix-ticket/SKILL.md` Step 4b-tracker (lines 203-356) — ~153 lines  
- `fix-bugs/SKILL.md` Step 3b-tracker (lines 190-343) — ~153 lines

The logic is identical: triple gate, idempotency check (YAML-first, state.json fallback), per-tracker MCP dispatch (6 tracker types), dual-store write, GitHub/Gitea checklist append, result display. Additionally, `resume-ticket` references the same logic for resumed pipelines.

This is the largest single duplication in the codebase. Any bug fix or new tracker type requires updating 3+ files identically.

**Impact:** HIGH — maintenance burden is significant. A bug in the Jira nested sub-task guard (lines 265-282 in implement-feature) must be fixed in all 3 copies. Adding a 7th tracker type requires 3 identical insertions. The existing core/ directory has 11 contracts for exactly this purpose.

**Approach A: Extract to core/tracker-subtask-creator.md**
- Create a new core contract `core/tracker-subtask-creator.md` with:
  - Input contract: ISSUE_ID, tracker_type, tracker_project, subtask_list, decomposition_yaml_path, state_json_path
  - Process: the full pseudocode (triple gate, idempotency, per-tracker dispatch, dual-store, checklist)
  - Per-tracker parameter table
  - Issue description template
  - Output contract: success_count, failure_count, created_issues list
- All 3 skills replace their inline copy with: "Follow `core/tracker-subtask-creator.md`."
- Pros: Single source of truth. Adding a tracker type = 1 file change. Bug fixes propagate automatically. Follows the established core contract pattern (config-reader, block-handler, fixer-reviewer-loop, etc.).
- Cons: Core contracts are interpreted by Claude at runtime — extracting does not literally DRY the code (it is all markdown), but it establishes the intent that the logic should be identical. If Claude deviates during execution, the core contract is the authority.
- Effort: MEDIUM — extract contract, update 3 skill files to reference it, update resume-ticket.

**Approach B: Extract only the per-tracker dispatch table**
- Keep the flow logic (triple gate, idempotency, dual-store) inline in each skill, but extract the per-tracker MCP parameters table to `core/tracker-dispatch-table.md`.
- Skills reference the table for the tracker-specific call but handle the surrounding logic themselves.
- Pros: Addresses the most error-prone part (tracker-specific parameters). Smaller extraction.
- Cons: Still duplicates the flow logic (triple gate, idempotency, dual-store). Half-measure.
- Effort: LOW — extract table only.

**Approach C: Full extraction + make it an "inline contract" with copy guard**
- Same as Approach A, but add a sentinel comment to each skill: `<!-- tracker-subtask-creator: follows core/tracker-subtask-creator.md — DO NOT diverge -->`.
- Tests verify the contract reference exists and no inline tracker creation logic is present.
- Pros: Approach A + enforcement.
- Cons: Extra test infrastructure.
- Effort: MEDIUM-HIGH.

**Recommendation:** Approach A (extract to core contract). This follows the established pattern — `core/fixer-reviewer-loop.md`, `core/block-handler.md`, `core/decomposition-heuristics.md` all exist for exactly this reason. The tracker subtask creator is the largest and most complex shared logic in the pipeline, making it the highest-value extraction candidate.

Proposed contract structure:
```
# Tracker Subtask Creator

## Purpose
Create tracker sub-issues for decomposed subtasks with idempotency and dual-store persistence.

## Input Contract
| Field | Type | Notes |
|-------|------|-------|
| issue_id | string | Parent issue ID |
| tracker_type | string | youtrack/github/jira/linear/gitea/redmine |
| tracker_project | string | Project key or owner/repo |
| subtask_list | list | Decomposition subtasks (topological order) |
| yaml_path | string | .claude/decomposition/{ISSUE-ID}.yaml |
| state_path | string | .ceos-agents/{ISSUE-ID}/state.json |

## Triple Gate (prerequisite check)
...

## Idempotency Protocol
...

## Per-Tracker Dispatch Table
...

## Dual-Store Write Protocol
...

## GitHub/Gitea Checklist Append
...

## Output Contract
| Field | Type |
|-------|------|
| success_count | integer |
| failure_count | integer |
| created_issues | list of {subtask_id, tracker_issue_id, title} |
```

---

### 6.4: Smoke check (build + test after fixer-reviewer) — informal agent identity

**Finding:** The smoke check step (implement-feature Step 6d-smoke, fix-ticket Step 7a) uses `agent = smoke-check` in its block output, but `smoke-check` is not a real agent — it is inline skill logic. Phase 2 identified that `block-handler.md` does not list `smoke-check` in its rollback trigger list, so smoke-check blocks do not trigger git rollback.

**Impact:** LOW-MEDIUM — smoke-check failures leave dirty git state. The fix is simple (add to rollback trigger list) but the deeper issue is: should smoke-check be formalized?

**Approach A: Just fix the rollback trigger list**
- Add `smoke-check` to `core/block-handler.md` rollback trigger list.
- Pros: Minimal change, fixes the bug.
- Cons: Does not address the architectural question of inline "virtual agents".
- Effort: LOW.

**Approach B: Extract smoke check to a core contract**
- `core/smoke-check.md`: Input = build command + test command. Output = PASS / FAIL with error details.
- Skills reference the contract instead of inlining the 4-step logic.
- Pros: Consistent with extraction pattern. Makes smoke-check a first-class concept.
- Cons: Overkill for 4 lines of logic.
- Effort: LOW.

**Recommendation:** Approach A (fix the rollback trigger list). The smoke check is too simple to warrant a core contract — it is literally "run build, run test, if either fails then block." But DO add `smoke-check` to the rollback trigger list and use the denylist approach suggested in Phase 2 (agents that do NOT trigger rollback: triage-analyst, code-analyst, spec-analyst, architect, stack-selector, publisher, scaffolder; all others including virtual agents like smoke-check DO trigger rollback).

---

## Cross-Cutting Summary

### Priority-ordered implementation plan

| Priority | Area | Item | Effort | Version Impact |
|----------|------|------|--------|----------------|
| P1 | 6.3 | Extract tracker-subtask-creator core contract | MEDIUM | PATCH (no behavior change, just DRY) |
| P1 | 5.1 | Add mode-aware input source mapping to fixer, reviewer, test-engineer | LOW | PATCH (documentation improvement in agent content) |
| P1 | 6.4 | Fix rollback trigger list for smoke-check | LOW | PATCH (bug fix) |
| P2 | 5.2 | Publisher mode-aware PR titles (Approach B: skill passes prefix) | LOW | MINOR (new feature: prefix parameter) |
| P2 | 4.1 | Add spec_analysis.* section to state schema | MEDIUM | MINOR (new optional schema section) |
| P2 | 4.2 | Add design.* section to state schema | MEDIUM | MINOR (bundled with 4.1) |
| P3 | 5.3 | Test-engineer scaffold mode awareness | LOW | PATCH (agent content improvement) |
| P3 | 4.3 | Add scaffold.* section to state schema | LOW | MINOR (bundled with 4.1/4.2) |
| P4 | 6.1 | Split spec-reviewer into spec-reviewer + spec-compliance-checker | MEDIUM | MINOR (new agent) |
| P4 | 6.2 | Conditional code-analyst before architect in implement-feature | MEDIUM | MINOR (new pipeline step) |
| P5 | 5.4 | Reviewer AC source verification warning | LOW | PATCH |

### Dependency graph
- 4.1 + 4.2 + 4.3 should be implemented together (one schema update)
- 5.1 is prerequisite for 5.3 (mode awareness pattern before scaffold-specific adaptation)
- 6.2 depends on 5.1 (code-analyst needs feature mode awareness before being used in feature pipeline)
- 6.3 is independent — can be done anytime
- 6.4 is independent — should be done ASAP (bug fix)

### Estimated total effort
- P1 items: ~2 hours (mostly text edits)
- P2 items: ~4 hours (schema changes + skill updates)
- P3 items: ~1 hour (agent text edits)
- P4 items: ~4 hours (new agent + new pipeline step)
- P5 items: ~30 minutes
- **Total: ~11.5 hours of implementation work**
