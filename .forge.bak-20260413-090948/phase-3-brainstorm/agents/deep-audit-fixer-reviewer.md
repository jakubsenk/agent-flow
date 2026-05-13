# Deep Audit: Fixer & Reviewer — Agent Definitions vs Pipeline Contexts

## Methodology

For each agent (fixer, reviewer), for each numbered Process step, we compare:
1. What the agent definition says the agent should do
2. What context each of the 3 skills actually provides
3. Whether the agent needs to behave differently between feature and scaffold

---

## agents/fixer.md

### Process Step Analysis

| Step # | Step Description (from agent definition) | Bug-fix context (fix-ticket) | Feature context (implement-feature) | Scaffold context (scaffold) | Feature ≠ Scaffold? |
|--------|------------------------------------------|------------------------------|--------------------------------------|----------------------------|---------------------|
| 1 | "Read the triage analysis and impact report thoroughly. If triage analysis or impact report is missing, Block with reason 'Missing input from previous pipeline stage'." | Triage output (from triage-analyst) + code-analyst impact report are both available. Context: `Max build retries = {Build retries from config}. Block Comment Template: {template}. Acceptance criteria: {AC from triage}.` In decomposition mode (step 4c): `decomposition plan + summary of previous subtasks + current subtask (scope, files, acceptance criteria).` | Spec-analyst output (specification with AC) + architect design + task tree. Context: `architectural design + subtask scope + acceptance criteria`. No "triage analysis" or "impact report" per se — the analogous inputs are spec + architecture. | Spec-writer output (spec/ folder) + architect design + task tree. Context: `subtask scope + acceptance criteria + architecture design + Max build retries = {Build retries from CLAUDE.md, default 3}.` Also: `spec/ folder available for reference`. | **NO** — Both feature and scaffold provide architecture design + subtask scope + AC. Scaffold additionally notes "spec/ folder available for reference" but this is additive, not behavioral. The agent definition says "triage analysis and impact report" but both non-bug pipelines substitute spec + architecture. The substitution is identical in feature and scaffold. |
| 2 | "Read project conventions from CLAUDE.md (coding style, patterns, naming conventions)" | CLAUDE.md exists in project (pre-existing project). | CLAUDE.md exists in project (pre-existing project). | CLAUDE.md is **generated** by scaffolder in Step 3. Fixer reads the generated CLAUDE.md. | **NO** — The fixer reads CLAUDE.md either way. The only difference is who created it (user vs scaffolder), but the fixer's behavior is identical: read it. |
| 3 | "Analyze before coding: reason through root cause — what is wrong, 2-3 approaches, simplest and lowest-risk, document reasoning" | Direct bug-fix context: root cause is a bug to fix. | Feature context: "what is wrong" does not apply — the task is implementing new code, not fixing a bug. The agent must reason about the best implementation approach for the subtask scope. | Same as feature — implementing new code per subtask scope. | **NO** — Both feature and scaffold require the same reinterpretation of "root cause" → "implementation approach". The agent definition is bug-flavored here ("What exactly is wrong and why?") but both non-bug pipelines need the same mental model shift. |
| 4 | "Read affected files (from impact report) thoroughly before changing anything. Read surrounding code to understand conventions." | Affected files come from code-analyst impact report (explicit list, max 5 files). | Affected files come from architect's subtask `files` field. | Affected files come from architect's subtask `files` field. | **NO** — Identical source (subtask.files) in both feature and scaffold. |
| 5 | "Implement the fix using red-green-refactor: RED (write failing test), GREEN (minimal fix), REFACTOR (cleanup). Skip RED if no test infrastructure. ESCAPE HATCH: NEEDS_DECOMPOSITION if >=4 files or approaching 100-line limit." | Full red-green-refactor. Test infrastructure typically exists. NEEDS_DECOMPOSITION can be signaled. | Full red-green-refactor. Test infrastructure typically exists (pre-existing project). NEEDS_DECOMPOSITION is handled by implement-feature (step 5 has its own decomposition logic — but the fixer's escape hatch is still valid if single-pass). | **Test infrastructure may not exist yet** — scaffolder creates skeleton including test setup in Step 3, so by Step 7 (fixer), test infrastructure should exist. However, if scaffolder's test setup is minimal, the fixer may encounter the "no test infrastructure" escape. NEEDS_DECOMPOSITION: scaffold always runs in decomposition mode (architect always decomposes), so fixer would never need NEEDS_DECOMPOSITION signal. | **MARGINAL NO** — The "no test infrastructure" escape clause already exists in the agent definition. NEEDS_DECOMPOSITION is irrelevant in scaffold (always decomposed) but the agent simply won't trigger it. No behavioral change needed. |
| 5-RED | "Write a test that reproduces the bug. Run it — confirm it FAILS." | Bug test: write a test that reproduces the specific bug, expect failure. | Feature test: write a test for the new behavior, expect failure (TDD). | Same as feature: write a test for new behavior. | **NO** — Both require TDD for new code. The agent definition says "reproduces the bug" but both non-bug pipelines reinterpret this as "tests the expected new behavior that doesn't exist yet." Identical reinterpretation. |
| 5-GREEN | "Implement the minimal fix to make the failing test pass. Target root cause, not symptoms. Smallest possible change." | Bug fix: smallest change to fix the root cause. | Feature implementation: implement the subtask scope minimally. | Same as feature: implement subtask scope. | **NO** — Both require minimal implementation of scope. |
| 5-ESCAPE | "NEEDS_DECOMPOSITION signal if scope exceeds limits (>=4 files, approaching 100 lines)" | Used when single-pass fix is too large. Triggers architect decomposition. | Used when single-pass feature implementation is too large. Implement-feature handles it (step 6b → step X → architect). | **Never triggered** — scaffold always decomposes via architect before reaching fixer. All subtasks are pre-scoped. The escape hatch is dead code in scaffold context. | **MARGINAL NO** — Dead code is harmless. No behavioral difference needed. |
| 6 | "Build the project to verify compilation. Run build command from Automation Config." | Build command from existing project's Automation Config. | Build command from existing project's Automation Config. | Build command from **generated** CLAUDE.md's Automation Config. Scaffold step 7a says: "After completion: run Build command from generated CLAUDE.md." | **NO** — The fixer runs the build command. Source of the command differs (existing vs generated CLAUDE.md) but fixer's behavior is identical. |
| 7 | "Run tests as sanity check. If test failures caused by your change → fix. If pre-existing → note and continue." | Pre-existing test failures are a real possibility (old codebase). | Pre-existing test failures possible but less likely (working codebase + new feature). | **No pre-existing failures** — everything was just scaffolded. Any test failure is caused by the fixer's change. | **NO** — The agent definition already handles both cases ("assess whether the failure is caused by your change"). In scaffold, the answer is always "yes, it's your change" but the agent logic is the same. |
| 8 | "Output Fix Report: root cause, approach, files changed, build status, test status." | Fix Report with bug root cause. | Fix Report with implementation approach (not "root cause" per se). | Same as feature. | **NO** — Output format is identical. "Root cause" is reinterpreted as "implementation rationale" in both non-bug pipelines. |
| Reviewer Loop | "If iteration 2+: read reviewer feedback, address every issue, try different strategy if rejected." | Standard iteration behavior. | Standard iteration behavior. | Standard iteration behavior. | **NO** — Identical across all three pipelines. |

### Fixer Context Strings — Exact Comparison

| Pipeline | Single-pass fixer context | Decomposed subtask fixer context |
|----------|--------------------------|----------------------------------|
| **fix-ticket** | `Max build retries = {N}. Block Comment Template: {template}. Acceptance criteria: {AC from triage}.` | `decomposition plan + summary of previous subtasks + current subtask (scope, files, acceptance criteria).` |
| **implement-feature** | `architectural design + subtask scope + acceptance criteria` | Same as single-pass + `Full decomposition plan + summary of previously completed subtasks + current subtask (scope, files, acceptance criteria).` |
| **scaffold** | N/A (scaffold always decomposes) | `subtask scope + acceptance criteria + architecture design + Max build retries = {N}.` + `Full decomposition plan + summary of previously completed subtasks + current subtask scope, files, acceptance_criteria + spec/ folder available for reference` |

### Fixer Structural Differences (Skill-Level, NOT Agent-Level)

| Aspect | Bug-fix | Feature | Scaffold |
|--------|---------|---------|----------|
| Hooks (Pre-fix, Post-fix) | Executed if configured | Executed if configured | **NOT executed** — "Hooks are not executed during scaffold because the project is being created from scratch" |
| NEEDS_DECOMPOSITION handling | Caller handles (revert + architect) | Caller handles | **Never triggered** (always pre-decomposed) |
| Block handler | Rollback + issue tracker comment + webhook | Rollback + issue tracker comment + webhook | Rollback + **stdout only** (no issue tracker comment — `"No issue tracker context — skip issue tracker updates."`) |
| Build command source | Existing CLAUDE.md | Existing CLAUDE.md | Generated CLAUDE.md |
| Acceptance gate after fixer loop | Conditional (>=3 AC or complexity >=M) | Always in decomposition, skipped in single-pass | Not present in scaffold (spec-reviewer --verify runs later at Step 7b instead) |

**Key finding:** ALL of these differences are handled at the **skill (orchestration) level**, not inside the fixer agent definition. The fixer agent itself behaves identically regardless of which pipeline dispatches it.

### Fixer Verdict: `2_MODES_SUFFICIENT`

The fixer agent definition does not need to distinguish between feature and scaffold. Both provide:
- Architecture design + subtask scope + acceptance criteria
- Build and test commands
- Reviewer feedback loop

The only "bug-flavored" language in the agent ("triage analysis," "root cause," "reproduces the bug") is naturally reinterpreted by the LLM when given feature/scaffold context. Feature and scaffold contexts are structurally identical from the fixer's perspective. The differences (hooks, block handling, NEEDS_DECOMPOSITION, acceptance gate) are all skill-level orchestration concerns.

---

## agents/reviewer.md

### Process Step Analysis

| Step # | Step Description (from agent definition) | Bug-fix context (fix-ticket) | Feature context (implement-feature) | Scaffold context (scaffold) | Feature ≠ Scaffold? |
|--------|------------------------------------------|------------------------------|--------------------------------------|----------------------------|---------------------|
| 1 | "Read the original bug report, triage analysis, impact report, and the fixer's output (changed files, approach, reasoning)" | Bug report + triage output + code-analyst impact report + fixer Fix Report. Context: `Max fixer iterations = {N}. Acceptance criteria: {AC from triage}.` | Spec-analyst specification + architect design + fixer Fix Report. Context: `diff from fixer + acceptance criteria from spec-analyst`. | Architecture design + fixer Fix Report. Context: `diff from fixer + acceptance criteria + Max fixer iterations = {N}.` + spec/ folder is available on disk. | **NO** — Both feature and scaffold provide AC + fixer diff + architectural context. The reviewer reads "bug report, triage analysis, impact report" but in non-bug pipelines these are substituted with spec + architecture. Identical substitution in both. |
| 2 | "Review the actual code changes using Read tool — read every changed file" | Read changed files. | Read changed files. | Read changed files. | **NO** — Identical behavior. |
| 3 | "Think before judging: Does the approach make sense? Simpler approach missed? Highest-risk aspects?" | Evaluate bug-fix approach. | Evaluate feature implementation approach. | Evaluate feature implementation approach (in a scaffolded project). | **NO** — Same reasoning process. The context (bug vs new feature) differs but the mental model is the same. |
| 4 | "Adversarial review — apply checklist: Root cause, Completeness, Conventions, Regressions, Security, Performance, Over-engineering, AC fulfillment" | Full checklist applies. "Root cause" = does the fix address the actual bug? | Full checklist applies. "Root cause" reinterpreted as "does the implementation address the actual requirement?" "Regressions" = could this break existing code? | Full checklist applies. Same reinterpretation as feature. **"Regressions"** is less relevant — there's minimal existing code to regress against in a scaffolded project. But the checklist item is still valid (could this break other scaffold-generated code?). | **MARGINAL NO** — "Regressions" has a different weight (less existing code in scaffold), but the checklist item still applies. The reviewer naturally adjusts severity based on context. No behavioral change needed in the agent definition. |
| 4-AC | "AC fulfillment: For each AC → FULFILLED / PARTIALLY / NOT ADDRESSED. NOT ADDRESSED = HIGH issue." | AC from triage-analyst. | AC from spec-analyst. | AC from spec-analyst (stored in spec/ folder). | **NO** — Same AC fulfillment check regardless of AC source. |
| 5 | "Edge case analysis: null/undefined, empty collections, zero/negative/overflow, type coercion, race conditions, early returns, error handlers" | Full edge case analysis on bug-fix diff. | Full edge case analysis on feature diff. | Full edge case analysis on scaffold feature diff. | **NO** — Identical analysis process. |
| 6 | "Issue count gate: MUST identify at least 3 specific issues. If fewer, re-examine for architectural violations, missing docs, integration risks, dependency concerns." | Standard 3-issue minimum. | Standard 3-issue minimum. | Standard 3-issue minimum. **Note:** In scaffold, "integration risks with untested callers" and "dependency version concerns" may have different characteristics (all callers are new, dependencies are freshly selected) but the checklist still applies. | **NO** — The issue count gate is context-independent. The reviewer may find different *types* of issues in scaffold (e.g., more architectural/convention issues, fewer regression issues) but the process is the same. |
| 7 | "Output: Verdict (APPROVE/REQUEST_CHANGES/BLOCK), Issues found, AC Fulfillment section" | Standard output format. | Standard output format. | Standard output format. | **NO** — Identical output contract. |
| Reviewer Loop | "If iteration 2+: verify fixer addressed ALL previous issues, re-raise unresolved Criticals, consider fixer's reasoning, don't raise new issues on already-approved code." | Standard loop behavior. | Standard loop behavior. | Standard loop behavior. | **NO** — Identical loop protocol. |

### Reviewer Context Strings — Exact Comparison

| Pipeline | Reviewer context |
|----------|-----------------|
| **fix-ticket** | `Max fixer iterations = {Fixer iterations from config}. Acceptance criteria: {AC from triage}.` |
| **implement-feature** | `diff from fixer + acceptance criteria from spec-analyst` |
| **scaffold** | `diff from fixer + acceptance criteria + Max fixer iterations = {Fixer iterations from CLAUDE.md, default 5}.` |

### Reviewer Structural Differences (Skill-Level, NOT Agent-Level)

| Aspect | Bug-fix | Feature | Scaffold |
|--------|---------|---------|----------|
| AC source | triage-analyst | spec-analyst | spec-analyst (via spec/) |
| Upstream analysis | triage + code-analyst | spec-analyst + architect | spec-writer + spec-reviewer + architect |
| Block handler behavior | Issue tracker comment + webhook | Issue tracker comment + webhook | **stdout only** (no tracker comment) |
| Post-review smoke check | Yes (step 7a) | Yes (step 6d-smoke) | **No** — scaffold has batch-level test suite run instead |
| Spec compliance check after | No | No | **Yes** — spec-reviewer --verify runs at Step 7b after all fixer-reviewer loops complete |

**Key finding:** ALL of these differences are skill-level orchestration. The reviewer agent itself behaves identically. It reviews code, checks AC, outputs a verdict.

### Reviewer Verdict: `2_MODES_SUFFICIENT`

The reviewer agent definition does not need to distinguish between feature and scaffold. Both provide:
- Fixer diff to review
- Acceptance criteria for AC fulfillment check
- Max iteration count

The reviewer's adversarial checklist (root cause, completeness, conventions, regressions, security, performance, over-engineering, AC fulfillment) applies equally to both. The "regression" checklist item naturally has less weight in scaffold (less existing code) but this is contextual weighting by the LLM, not a behavioral mode switch.

---

## Cross-Agent Summary

### What the Agent Definitions Say (Bug-Flavored Language)

| Agent | Bug-specific language in definition | Impact on non-bug pipelines |
|-------|------------------------------------|-----------------------------|
| Fixer | "bug fixes", "root cause", "reproduces the bug", "triage analysis and impact report" | LLM reinterprets naturally when given feature/scaffold context. No behavioral mismatch. |
| Reviewer | "original bug report, triage analysis, impact report", "root cause" | Same — LLM reinterprets. AC fulfillment check is pipeline-agnostic. |

### What the Skills Actually Pass

| Context element | fix-ticket | implement-feature | scaffold | Feature ≠ Scaffold? |
|----------------|------------|-------------------|----------|---------------------|
| Upstream analysis | triage + code-analyst | spec-analyst + architect | spec-writer/reviewer + architect | NO — both provide spec + architecture |
| Acceptance criteria | From triage | From spec-analyst | From spec-analyst (via spec/) | NO — same format |
| Subtask scope | From architect (if decomposed) | From architect | From architect | NO — same source |
| Architecture design | Not always present | Always present | Always present | NO |
| Max build retries | Explicit in context | Implicit (in CLAUDE.md) | Explicit in context | NO — cosmetic |
| Max fixer iterations | Explicit in context | Implicit (in CLAUDE.md) | Explicit in context | NO — cosmetic |
| Block Comment Template | Explicit in context | Not in context (in CLAUDE.md) | Not in context | NO — agent reads CLAUDE.md anyway |
| spec/ folder reference | N/A | N/A | "spec/ folder available for reference" | **YES — but additive, not behavioral** |
| Hooks execution | Yes | Yes | **No** (skip all hooks) | Skill-level, not agent-level |

### The Only Scaffold-Unique Element

The `spec/ folder available for reference` note in scaffold's fixer context is the ONLY element unique to scaffold that is not present in implement-feature. However:

1. This is **additive context** — it tells the fixer "you can also look at spec/ for reference"
2. It does not change the fixer's behavior, only enriches its context
3. It could be added to implement-feature's context too (if spec/ existed in that pipeline)
4. The fixer agent definition does not reference spec/ at all — it's purely a skill-level hint

---

## FINAL VERDICT

### Fixer: `2_MODES_SUFFICIENT`

Feature and scaffold are identical from the fixer's perspective. Both provide architecture + subtask scope + AC. The differences (hooks, block handling, NEEDS_DECOMPOSITION, build command source) are all skill-level orchestration concerns that the fixer agent never sees.

### Reviewer: `2_MODES_SUFFICIENT`

Feature and scaffold are identical from the reviewer's perspective. Both provide fixer diff + AC. The differences (block handling, smoke checks, spec compliance) are all skill-level orchestration that runs outside the reviewer agent.

### Overall: `2_MODES_SUFFICIENT`

At the agent definition level, 2 modes (bug-fix | guided-implementation) are sufficient. The feature and scaffold pipelines provide structurally identical contexts to both fixer and reviewer. All scaffold-specific behaviors (no hooks, stdout-only blocks, spec compliance check, batch testing) are handled by the skill orchestration layer, not by the agents themselves.

**Recommendation:** If the agent definitions are refactored to support modes, use:
- **Mode 1: bug-fix** — triage analysis + impact report as input, "root cause" framing, NEEDS_DECOMPOSITION escape hatch active
- **Mode 2: guided-implementation** — spec/architecture as input, "implementation" framing, NEEDS_DECOMPOSITION may be inactive (pre-decomposed), covers both feature and scaffold

No third mode is needed. The skill layer handles all scaffold-specific orchestration differences.
