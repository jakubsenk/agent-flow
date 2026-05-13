# Phase 0 Analysis

## 1. Task Type Classification

**Type:** refactor
**Rationale:** This is a systematic update of existing agent definitions and core contracts to support a second pipeline mode (feature) alongside the original (bug-fix). No new functionality is being added; existing agents are being made mode-aware. The changes are additive mode-branches, not replacements.

## 2. Complexity Assessment

| Dimension | Score | Rationale |
|-----------|-------|-----------|
| Scope | 4 | 10 files across agents/, skills/, core/, state/ — wide surface area but well-bounded by prior audit |
| Ambiguity | 2 | Exact changes are specified in the audit report (12 CRQs, each with explicit recommendation) |
| Risk | 4 | Must not break existing bug-fix pipeline; changes to 5 agents + 3 core contracts shared across 3 pipelines |
| **Composite** | **3.4** | Weighted: (4*0.35 + 2*0.25 + 4*0.40) = 1.4 + 0.5 + 1.6 = 3.5 |

**Complexity tier:** HIGH (composite >= 3.0)

## 3. Fast-Track Eligibility

**Eligible:** No
**Reason:** Composite score 3.4 exceeds fast-track threshold. 10 files, cross-cutting changes with regression risk. Full pipeline required.

## 4. Domain Identification

| Aspect | Value |
|--------|-------|
| Language | Markdown (pure plugin, no runtime code) |
| Framework | Claude Code plugin system (YAML frontmatter + markdown) |
| Domain | AI agent orchestration, pipeline engineering |
| Specialty | Mode-aware agent definitions, contract evolution |

## 5. Codebase Context Assessment

**Patterns identified:**
- Agent files follow strict format: YAML frontmatter (name, description, model, style) + Goal + Expertise + Process + Constraints
- Core contracts follow: Purpose + Input Contract + Process + Output Contract + Failure Handling
- Skills follow: frontmatter + Configuration + Flag parsing + Orchestration steps
- Mode-branching precedent: acceptance-gate.md line 21 already handles "triage-analyst for bugs, spec-analyst for features"
- State schema uses field reuse pattern (triage.* reused for spec-analyst output in feature mode)

**Existing conventions:**
- Bug-fix language is the default vocabulary (root cause, bug report, triage analysis, impact report)
- Feature pipeline adds: specification, architectural design, subtask scope, acceptance criteria from spec-analyst
- Block comment template uses [ceos-agents] prefix
- NEEDS_DECOMPOSITION is a structured signal with specific markdown format

**Key constraint:** All changes must be additive mode-branches. Bug-fix pipeline paths must remain untouched.

## 6. Confidence Scoring

| Question | Score | Rationale |
|----------|-------|-----------|
| Do I understand the task well enough to route it? | 0.95 | Prior audit provides exact file:line references and explicit recommendations for all 12 CRQs |
| Can I identify the right template/approach? | 0.90 | Standard refactor pattern: read-understand-edit-test. No novel techniques needed. |
| Are there significant unknowns that need research? | 0.85 | Research already completed (Phase 2 audit). Remaining unknowns: test harness behavior, potential interactions with scaffold pipeline |

**Average confidence:** 0.90

## 7. Routing Decision

**Route:** Full pipeline (no fast-track)
**Template:** None (custom)
**Phases to execute:** 1 (research-questions), 2 (research-answers), 3 (brainstorm), 4 (spec), 5 (TDD), 6 (plan), 7 (execute), 8 (verify), 9 (completion)
**Phases to skip:** None

**Phase customizations:**
- Phase 1-2 (Research): Lightweight — prior audit covers most ground. Focus on scaffold pipeline interactions and test harness validation.
- Phase 3 (Brainstorm): Minimal — approach is well-defined by audit recommendations. Quick validation of mode-branch pattern.
- Phase 4 (Spec): Convert audit CRQ recommendations into precise edit specifications per file.
- Phase 5 (TDD): Define test criteria — what the test harness should validate after changes.
- Phase 6 (Plan): Dependency-ordered edit sequence (BLOCKING fixes first, then HIGH, then MEDIUM).
- Phase 7 (Execute): Apply all edits across 10 files.
- Phase 8 (Verify): Run test harness + manual review of each file for bug-fix pipeline preservation.
- Phase 9 (Completion): Summary report + version considerations.

## 8. Risk Mitigations

| Risk | Mitigation |
|------|-----------|
| Bug-fix pipeline regression | Every edit is an additive mode-branch, not a replacement |
| Scaffold pipeline regression | Scaffold does not dispatch fixer/reviewer/test-engineer directly in the same way — verify no overlap |
| Inconsistent mode signal | All implement-feature dispatch points (6b, 6d, 6e) get Mode prefix simultaneously |
| Missing test coverage | Run tests/harness/run-tests.sh before and after changes |
| Partial application | Apply P0 (BLOCKING) fixes as a group, verify, then P1, verify, then P2 |
