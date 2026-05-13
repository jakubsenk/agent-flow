# Agent 3: Core Contracts, Decomposition & Missing Guardrails
## Research Focus: RQ-5, RQ-6, RQ-7

**Files read:**
- `core/fixer-reviewer-loop.md`
- `core/decomposition-heuristics.md`
- `core/fix-verification.md`
- `core/block-handler.md`
- `core/state-manager.md`
- `core/config-reader.md`
- `core/agent-override-injector.md`
- `core/mcp-detection.md`
- `core/mcp-preflight.md`
- `core/post-publish-hook.md`
- `core/profile-parser.md`
- `agents/fixer.md`
- `agents/architect.md`
- `agents/publisher.md`
- `agents/rollback-agent.md`
- `agents/reviewer.md`
- `agents/acceptance-gate.md`
- `agents/spec-analyst.md`
- `agents/test-engineer.md`
- `skills/implement-feature/SKILL.md`

---

## RQ-5: Fixer NEEDS_DECOMPOSITION Conflict in Feature Pipeline

### Finding 5.1 — NEEDS_DECOMPOSITION is bug-fix-era logic injected into a feature pipeline that already decomposed

**Source of conflict:**
`agents/fixer.md` Step 5 ESCAPE HATCH defines NEEDS_DECOMPOSITION as a signal triggered when the fixer realizes the scope exceeds limits (≥4 files, approaching 100-line diff). This signal is described as being consumed by the "orchestrating command."

`core/fixer-reviewer-loop.md` Step 3 states: "If fixer output contains `## NEEDS_DECOMPOSITION` → return `NEEDS_DECOMPOSITION` immediately. Only allowed once per ticket; caller enforces the limit."

`skills/implement-feature/SKILL.md` Step 5 (Decomposition decision) runs the architect first and builds a full task tree. The fixer-reviewer loop is then invoked per subtask.

**The conflict:** In the feature pipeline, by the time the fixer runs (Step 6b), the architect has already designed the decomposition, the task tree has been saved to `.claude/decomposition/{ISSUE-ID}.yaml`, and the fixer is executing a subtask with a scope that the architect already bounded to ≤100 lines. If the fixer still signals NEEDS_DECOMPOSITION from within a subtask, the feature pipeline (`skills/implement-feature/SKILL.md`) has NO documented handler for this signal in Step 6b. The skill says "If build fails → fixer fixes it (max Build retries attempts)" but does not mention what happens if NEEDS_DECOMPOSITION emerges from a subtask.

**Research Question RQ-5a:** What does `implement-feature` do when the fixer emits `NEEDS_DECOMPOSITION` within a subtask iteration (Step 6b)? There is no explicit handler in the skill for this case. Does it fall through to the generic Block handler (Step X)? Does it trigger another architect pass? Is it silently swallowed by the fixer-reviewer-loop contract returning the signal to the caller with no caller-side handler?

**Research Question RQ-5b:** `core/fixer-reviewer-loop.md` enforces a "Only allowed once per ticket" limit for NEEDS_DECOMPOSITION. In decomposition mode, the fixer runs N times (once per subtask). Does "once per ticket" mean once across all subtasks or once per subtask invocation? The contract is ambiguous — "per ticket" could be interpreted either way. If a second subtask fixer invocation triggers NEEDS_DECOMPOSITION, does the loop block, ignore it, or propagate it?

**Research Question RQ-5c:** The fixer's description in its frontmatter reads: "Implements minimal, correct bug fixes targeting root cause. Surgical changes with backwards compatibility." The NEEDS_DECOMPOSITION signal was designed for bug scoping failures. When given a feature subtask context, the fixer's own criteria ("fix is larger than expected") don't map cleanly. A feature subtask IS expected to be new code. Does the fixer calibrate its NEEDS_DECOMPOSITION threshold differently when given feature vs. bug context? Its process instructions make no distinction.

**Risk: HIGH.** A NEEDS_DECOMPOSITION signal from within a feature subtask creates an undefined state: the task tree is saved, some subtasks may be committed, and the pipeline has no defined recovery path. This could leave the repository in a partially-implemented state with no automated cleanup.

---

### Finding 5.2 — Decomposition-heuristics.md is invoked differently between pipelines

`core/decomposition-heuristics.md` expects input from `code_analyst_output` (risk, affected_files, estimated_diff_lines, independent_changes). These fields come from the code-analyst agent which runs in the bug-fix pipeline.

In `implement-feature`, Step 5 calls `core/decomposition-heuristics.md` for task tree validation (cycle detection, max_subtasks check, required fields). However, the heuristic decision logic (FORCE/DISABLED/AUTO based on code_analyst_output) is replaced by the architect's own decomposition judgment (Step 7 of architect.md). The implement-feature pipeline doesn't run code-analyst at all — the architect decides.

**Research Question RQ-5d:** `core/decomposition-heuristics.md` defines the AUTO threshold evaluation against `code_analyst_output`. The `implement-feature` skill's Step 5 says "Follow `core/decomposition-heuristics.md`" but only uses it for validation (cycle detection, max_subtasks). Is it using the full contract or just a subset? Is there a discrepancy where the implement-feature skill could pass incomplete input to decomposition-heuristics (missing code_analyst_output fields since no code-analyst ran)?

**Risk: MEDIUM.** Incomplete input to decomposition-heuristics triggers its fallback (treat missing numeric fields as 0, missing risk as LOW → SINGLE_PASS). This means the heuristic validation could silently accept a malformed task tree if the architect's input is passed instead of code-analyst output.

---

## RQ-6: Missing Feature-Specific Guardrails

### Finding 6.1 — Fixer has no awareness it is implementing a feature vs. fixing a bug

`agents/fixer.md` is described as "Implements minimal, correct bug fixes targeting root cause. Surgical changes with backwards compatibility." The constraints include:

- "NEVER modify public APIs without explicit approval"
- "NEVER change more than necessary — no drive-by refactoring"
- "Diff MUST NOT exceed 100 lines."
- Red-green-refactor TDD approach (write a failing test first)

All of these constraints are written from a bug-fix perspective. When implementing a feature:

**Research Question RQ-6a:** The fixer's TDD approach (RED step: "Write a test that reproduces the bug. Run it — confirm it FAILS") is semantically wrong for feature implementation. For a feature, there is no pre-existing bug to reproduce. The fixer should write a test that verifies the new behavior. The instruction "confirm it FAILS" assumes the feature doesn't exist yet (which may be true), but the framing "reproduces the bug" is bug-specific. Is this purely cosmetic or does it affect fixer behavior on feature subtasks?

**Research Question RQ-6b:** "NEVER modify public APIs without explicit approval" — for feature implementation, API additions or modifications are often required and are explicitly approved via the spec-analyst + architect design. Does the fixer treat the architect's design plan as "explicit approval"? There is no mechanism that flags API-affecting subtasks to suppress this constraint. The architect outputs a design but the fixer's constraints make no exception for architect-approved API changes.

**Research Question RQ-6c:** The fixer's 100-line diff limit is appropriate for bug fixes (surgical changes). For features, the architect decomposes into subtasks of ≤100 lines. But what happens if a subtask legitimately requires more (e.g., a new module with boilerplate)? The architect estimates "1 new file with imports/boilerplate ≈ 30-60 lines" — so 100 lines is achievable. But the fixer's constraint says BLOCK if approaching the limit. Is the fixer's blocking trigger well-calibrated for feature subtasks, or does it risk triggering NEEDS_DECOMPOSITION prematurely on normal feature code?

**Finding:** There is no feature-specific fixer behavior. The fixer receives context (architectural design + subtask scope + AC) but its own instructions are 100% bug-fix-oriented. The feature context in the prompt is expected to override the fixer's default behavior, but this is implicit, not explicit. No fixer instruction says "when implementing a feature subtask, apply these rules instead."

**Risk: MEDIUM.** The mismatch between fixer's self-description and feature context is likely handled by the opus model's contextual reasoning, but there is no explicit guardrail ensuring feature-appropriate behavior.

---

### Finding 6.2 — No scope creep prevention in feature pipeline

In the bug-fix pipeline, the code-analyst provides an impact report with explicit scope boundaries (affected_files ≤5, diff ≤100 lines). In the feature pipeline:

- spec-analyst defines IN/OUT scope
- architect creates the task tree with files per subtask
- There is no mechanism that prevents the fixer from expanding beyond the architect's designated files per subtask

**Research Question RQ-6d:** If the fixer modifies files outside the subtask's `files` list (as defined in the architect's task tree), is there any automated check? The reviewer receives "diff from fixer + acceptance criteria from spec-analyst" but is not explicitly given the architect's subtask file list to verify scope containment. The reviewer's checklist (adversarial review, completeness, conventions, regressions, security, performance, over-engineering) does not include "did the fixer stay within the subtask's designated files?"

**Risk: MEDIUM.** A fixer implementing subtask 2 could touch files designated for subtask 3, causing conflicts or partial implementation in subsequent subtasks. The commit-per-subtask model (Step 6i) would commit these out-of-scope changes, and the decomposition's dependency graph would become invalid.

---

### Finding 6.3 — No API design review mechanism

`agents/architect.md` lists "API design" in its Expertise section and notes risk assessment includes "HIGH = public API change." However:

- There is no dedicated API design review step
- The reviewer's checklist does not include an API design review item
- spec-analyst's scope section captures what's IN/OUT but does not produce an explicit API contract document

**Research Question RQ-6e:** For features that involve new or modified public APIs (REST endpoints, library interfaces, SDK changes), is there a guardrail that ensures API design quality (backward compatibility, versioning, naming conventions, error responses, documentation)? The reviewer checks "NEVER modify public APIs without explicit approval" but for features, API creation is the goal. The reviewer has no feature-specific API review criteria.

**Risk: MEDIUM.** New APIs implemented without explicit design review criteria could introduce breaking changes in future updates, lack consistent naming/versioning, or miss error handling standards.

---

### Finding 6.4 — Backward compatibility is a bug-fix constraint, not a feature constraint

`agents/fixer.md` description: "Surgical changes with backwards compatibility." This is appropriate for bugs. For features, backward compatibility is a concern only for API-changing features, not for net-new functionality.

**Research Question RQ-6f:** Does the fixer's "backwards compatibility" constraint actively interfere with feature implementation? For example, if a feature requires adding a new required parameter to an existing function, the fixer may refuse to make the change without "explicit approval." But the architect already approved it. Is there a precedence mechanism where the architect's design overrides the fixer's default constraints?

**Risk: LOW-MEDIUM.** Likely handled by opus's contextual reasoning, but not explicitly defined.

---

### Finding 6.5 — Documentation requirements are absent in feature pipeline

Feature implementations often require documentation updates (README, API docs, changelogs, migration guides). Neither spec-analyst, architect, fixer, reviewer, nor test-engineer have documentation requirements in their feature-workflow instructions.

**Research Question RQ-6g:** Is there any mechanism in the feature pipeline that ensures documentation is updated alongside code? The spec-analyst's scope section can say "OUT: documentation updates" — but who decides? If the feature changes a public API and no documentation update is required by the spec, the pipeline will complete without flagging this gap.

**Risk: LOW.** Documentation is often a human concern, but for developer-facing APIs this could be a significant gap.

---

### Finding 6.6 — Test-engineer has bug-fix-oriented process but runs in feature pipeline

`agents/test-engineer.md` Step 1 says "Read the bug report, fixer output (changed files, root cause), and impact report (test coverage section)." In the feature pipeline, there is no bug report and no impact report. The test-engineer receives:

- Changed files from fixer
- Acceptance criteria from spec-analyst

But the test-engineer's process begins by looking for a "bug report" and "impact report" that don't exist in feature context.

**Research Question RQ-6h:** Does the test-engineer's Step 1 instruction to read "bug report" and "impact report" cause the agent to fail or behave unexpectedly when those inputs don't exist (feature pipeline)? The agent would receive architectural design + subtask context instead. Does the agent gracefully degrade to reading the available context, or does it get confused by the mismatch?

**Research Question RQ-6i:** The test-engineer's scope is "1-3 focused tests" with "Required: One test verifying the specific behavior that was fixed (regression test)." For features, there is no "behavior that was fixed" — there is "behavior that was added." The test scope is too narrow for feature validation, which may require integration tests, workflow tests, or end-to-end scenario tests beyond 1-3 focused unit tests.

**Risk: MEDIUM.** Test-engineer likely adapts based on context, but its 3-test maximum and regression-test framing could under-test feature implementations.

---

## RQ-7: Core Contract Fitness — Is fixer-reviewer-loop.md Properly Dual-Purpose?

### Finding 7.1 — fixer-reviewer-loop.md Input Contract uses "Bug report or spec + AC + code-analyst output"

`core/fixer-reviewer-loop.md` Input Contract:
```
context | string | required | Bug report or spec + AC + code-analyst output
```

The contract explicitly acknowledges dual-purpose use ("Bug report OR spec + AC"). This is correct — the feature pipeline passes spec + AC as context.

**Verdict on dual-purpose:** Partially intentional. The "or" in the context field was added to support features. However, the contract still lists "code-analyst output" as part of the feature context option, but code-analyst does not run in the feature pipeline. The feature pipeline passes architect output instead.

**Research Question RQ-7a:** Should the fixer-reviewer-loop.md Input Contract explicitly separate the bug-fix and feature context shapes? Currently it says "Bug report or spec + AC + code-analyst output" — but in the feature pipeline, the context is "spec + AC + architect design." Code-analyst output is NOT passed. Is this an implicit assumption that the caller handles context assembly correctly, or a documentation gap?

**Risk: LOW.** Functional risk is minimal since the context field is a free-form string. Documentation risk is that maintainers may be confused about what to pass in feature mode.

---

### Finding 7.2 — Build step in fixer-reviewer-loop.md is pipeline-agnostic (good)

`core/fixer-reviewer-loop.md` Step 4: "Run Build command (max Build retries attempts). Failure → return `BLOCKED` with build error as detail."

This references "Build command" from Automation Config, which is shared by both pipelines. No bug-fix-specific assumptions.

**Verdict: Correctly dual-purpose.**

---

### Finding 7.3 — AC Fulfillment check in reviewer assumes AC come from "triage-analyst output"

`core/fixer-reviewer-loop.md` Step 6: "Dispatch `ceos-agents:reviewer` with fixer's changes + AC list."
`core/fixer-reviewer-loop.md` Step 7: "If reviewer outputs `APPROVE` (with AC Fulfillment section)..."

The AC list is passed from the caller. In the bug pipeline, this comes from triage-analyst. In the feature pipeline, this comes from spec-analyst. The core contract itself is neutral — it just passes the AC list.

However, `agents/reviewer.md` Step 1 says "Read the original bug report, triage analysis, impact report, and the fixer's output." These are all bug-fix artifacts. The reviewer has no instruction to read the spec-analyst output instead.

**Research Question RQ-7b:** Does the reviewer agent know it should read the spec-analyst output (specification) instead of the bug report + triage analysis when operating in a feature pipeline? The reviewer's process instructions are entirely bug-fix-oriented. The AC list is passed in, but the reviewer's contextual reading instructions (Step 1-2) point to bug artifacts. Does this affect review quality for features?

**Risk: MEDIUM.** The reviewer may try to find a "bug report" and "triage analysis" that don't exist, potentially causing the agent to fail at Step 1 or produce a review with incomplete context understanding.

---

### Finding 7.4 — NEEDS_DECOMPOSITION handling in fixer-reviewer-loop.md has no feature pipeline path

`core/fixer-reviewer-loop.md` Step 3: "If fixer output contains `## NEEDS_DECOMPOSITION` → return `NEEDS_DECOMPOSITION` immediately. Only allowed once per ticket; caller enforces the limit."

The Failure Handling section: "`NEEDS_DECOMPOSITION` → returned to caller; caller handles decomposition logic (see `core/decomposition-heuristics.md` and `skills/fix-ticket/SKILL.md` step 5)."

The reference is to `skills/fix-ticket/SKILL.md` step 5 only. There is NO reference to `skills/implement-feature/SKILL.md`. This suggests the NEEDS_DECOMPOSITION handling was designed exclusively for the bug-fix pipeline and was never extended to the feature pipeline.

**Research Question RQ-7c (same as RQ-5a, but from the contract perspective):** The fixer-reviewer-loop.md contract documents NEEDS_DECOMPOSITION handling as "see `skills/fix-ticket/SKILL.md` step 5." There is no equivalent documentation for the feature pipeline. This is a contract documentation gap. Was NEEDS_DECOMPOSITION handling intentionally omitted from the feature pipeline because "if it's already decomposed by the architect, this shouldn't happen"? Or was it accidentally omitted?

**Risk: HIGH.** If NEEDS_DECOMPOSITION fires from a feature subtask, the implement-feature caller has no documented handler. The pipeline either silently blocks (Step X) or crashes with undefined behavior. Neither outcome is documented.

---

## RQ-7 Extension: Other Core Contracts with Bug-Fix Assumptions

### Finding 7.5 — core/fix-verification.md is bug-context named but content is neutral

`core/fix-verification.md` is named "fix-verification" (bug-fix framing). The `implement-feature` skill uses it in Step 10b but calls it "Feature Verification." The contract itself is pipeline-neutral (just runs a Verify command). However, the failure comment posted to the issue says:

```
[ceos-agents] ❌ Fix verification failed.
```

This says "Fix verification" even when called from the feature pipeline. A feature that fails post-merge verification would post a comment saying "Fix verification failed" — confusing framing for a new feature.

**Research Question RQ-7d:** Should `core/fix-verification.md` accept a context parameter (bug-fix vs. feature) to customize the success/failure comment wording? Currently both pipelines post identical "Fix verified" / "Fix verification failed" messages regardless of whether the work was a bug fix or feature implementation.

**Risk: LOW.** Cosmetic issue only, but could be confusing to issue tracker watchers.

---

### Finding 7.6 — core/block-handler.md rollback trigger list is feature-aware but incomplete

`core/block-handler.md` Step 1: "If the blocking agent is `fixer`, `reviewer`, or `test-engineer` → dispatch rollback-agent."

This list is feature-pipeline compatible for the standard agents. However, `implement-feature` also uses:
- `spec-analyst` (no rollback — correct, read-only, Step 3)
- `architect` (no rollback — correct, read-only, Step 4)
- `acceptance-gate` (no rollback — correct, read-only, Step 6h)
- `smoke-check` (block handler invoked with `agent = smoke-check` — but rollback-agent's Step 1 does NOT include `smoke-check` in its rollback trigger list)
- `deployment-verifier` (called in Step 6f-deploy, block goes to Step X — rollback-agent does not list `deployment-verifier` either)

**Research Question RQ-7e:** When `implement-feature` Step 6d-smoke (smoke check) fails and calls the Block handler with `agent = smoke-check`, the `block-handler.md` passes `agent_name = "smoke-check"` to the rollback-agent. The rollback-agent Step 1 lists agents that trigger rollback: `fixer`, `test-engineer`, `e2e-test-engineer`, `reviewer`. `smoke-check` is NOT in this list. Result: the smoke check block goes to block-handler but triggers NO rollback. Is this intentional? The smoke check runs after fixer approval — if the build fails at smoke check, the fixer's changes remain in git with no rollback. This is a data inconsistency.

**Risk: HIGH.** A build failure at smoke check (Step 6d-smoke) leaves uncommitted fixer changes in git, transitions the issue to Blocked, but does NOT revert git state. The repository is left dirty. On resume, the pipeline would encounter unexpected working tree state.

---

### Finding 7.7 — core/block-handler.md does not distinguish feature vs. bug for state transitions

`core/block-handler.md` Step 2: "Transition the issue to the Blocked state (from config → State transitions → Blocked) via the issue tracker MCP server."

For the feature pipeline, the issue is a feature ticket (different type, possibly different state machine) but the Blocked state transition comes from the same Automation Config key. This is correct behavior but means bug and feature tickets share the same blocked state. Some trackers (Jira, YouTrack) have separate state machines per issue type.

**Research Question RQ-7f:** For trackers that have type-specific state workflows (Jira issue types, YouTrack state machines per issue type), the Automation Config has a single `State transitions → Blocked` value. Is there a gap where the feature ticket's state machine doesn't have a "Blocked" transition (because it was configured for bugs)? This would cause the block-handler's state transition to silently fail (logged as warning, pipeline continues).

**Risk: LOW-MEDIUM.** Depends on project tracker configuration. The block-handler handles failure gracefully (log warning, continue), so pipeline won't crash, but the feature ticket may not be properly marked as Blocked.

---

### Finding 7.8 — core/decomposition-heuristics.md is bug-context in its input design

`core/decomposition-heuristics.md` Input Contract requires `code_analyst_output` with fields: `risk`, `affected_files`, `estimated_diff_lines`, `independent_changes`. These fields come exclusively from code-analyst (bug pipeline).

The `implement-feature` Step 5 references this contract for "task tree validation" but the architect (not code-analyst) provides the task tree. The validation logic in Step 5 of implement-feature lists specific checks (cycle detection, topological sort, max_subtasks, required fields per subtask) but does NOT feed the heuristic AUTO decision logic.

**Verdict:** The implement-feature pipeline uses decomposition-heuristics.md for structural validation only, not for FORCE/DISABLED/AUTO decision-making (that decision is delegated to the architect). The contract's input requirements are therefore not fully applicable in the feature context.

**Research Question RQ-7g:** Should `core/decomposition-heuristics.md` be split into two concerns: (1) decision logic (FORCE/DISABLED/AUTO based on code_analyst_output — bug-fix only) and (2) structural validation (cycle detection, field completeness — used by both pipelines)? Currently, both concerns are bundled in one contract, causing confusion about what the feature pipeline actually uses from it.

**Risk: LOW.** Current usage is correct but the contract is confusing to read and maintain.

---

## Summary: Risk Assessment by Gap

| # | Gap | Risk | Pipeline Impact |
|---|-----|------|-----------------|
| 5.1 | NEEDS_DECOMPOSITION in feature subtask has no handler | HIGH | Undefined state, partial git commits, no rollback |
| 5.2 | Decomposition-heuristics code-analyst input not available in feature pipeline | MEDIUM | Silent fallback to SINGLE_PASS on malformed input |
| 6.1 | Fixer constraints are bug-fix-oriented, no feature mode | MEDIUM | Fixer may apply wrong TDD framing, API constraint conflicts |
| 6.2 | No scope containment check per subtask | MEDIUM | Fixer can modify files outside subtask scope, breaking later subtasks |
| 6.3 | No API design review criteria for features | MEDIUM | New APIs may lack quality standards |
| 6.4 | Backward compatibility constraint conflicts with API-changing features | LOW-MEDIUM | Fixer may refuse valid API changes |
| 6.5 | No documentation update requirement for features | LOW | Documentation debt |
| 6.6 | Test-engineer reads "bug report" in feature context | MEDIUM | Agent may fail to find required inputs, under-test feature |
| 7.1 | fixer-reviewer-loop.md context field conflates code-analyst with architect output | LOW | Documentation confusion |
| 7.2 | Build step in fixer-reviewer-loop.md is neutral | NONE | No issue |
| 7.3 | Reviewer reads bug-specific artifacts in feature context | MEDIUM | Reviewer may produce lower-quality feature review |
| 7.4 | NEEDS_DECOMPOSITION handling references only fix-ticket, not implement-feature | HIGH | No caller-side handler documented for feature pipeline |
| 7.5 | fix-verification.md says "Fix verified" for features | LOW | Misleading comment wording |
| 7.6 | smoke-check agent not in rollback-agent trigger list | HIGH | Dirty git state after smoke check failure in feature pipeline |
| 7.7 | Single Blocked state transition for both bug and feature tickets | LOW-MEDIUM | May fail silently on trackers with type-specific state machines |
| 7.8 | decomposition-heuristics.md bundles decision and validation concerns | LOW | Maintainability confusion |

---

## High-Priority Research Questions (Unresolved — Require Deeper Investigation)

**RQ-5a** (HIGH): What does `implement-feature` Step 6b do when fixer emits NEEDS_DECOMPOSITION within a subtask? Examine if any handler exists beyond the documented gap.

**RQ-7c** (HIGH): Was NEEDS_DECOMPOSITION handling for feature pipeline intentionally omitted? Check git history or any design decisions referencing this.

**RQ-7e** (HIGH): Smoke-check block leaves dirty git state in feature pipeline — is this an actual gap or is there a hidden mechanism? Check if the implement-feature skill handles smoke-check blocks differently from other blocks.

**RQ-6b** (MEDIUM): Does the architect's design plan constitute "explicit approval" for API changes from the fixer's perspective? Is there a context injection mechanism that suppresses fixer's API constraint?

**RQ-6d** (MEDIUM): Is there a subtask scope containment check anywhere in the feature pipeline execution loop?

**RQ-7b** (MEDIUM): Does reviewer.md handle absence of bug report/triage analysis gracefully when given feature context? Does it fall back to reading spec-analyst output?
