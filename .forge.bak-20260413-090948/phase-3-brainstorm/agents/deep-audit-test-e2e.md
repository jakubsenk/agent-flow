# Deep Audit: test-engineer & e2e-test-engineer

## agents/test-engineer.md

### Agent Definition Summary

The test-engineer has 6 process steps. It is described as a "Senior Test Engineer specializing in automated unit tests" whose goal is to "Write tests that verify the fix AND prevent future regressions."

### Context Passed by Each Skill

| Skill | Step | Exact context string |
|-------|------|---------------------|
| fix-ticket (step 8) | Single-pass | `Max test attempts = {Test attempts from config}.` |
| fix-ticket (step 4c.7) | Decomposition subtask | No explicit context string documented — just "Run test-engineer (Task tool, model: sonnet). Failure → retry (max Test attempts)." |
| implement-feature (step 6e) | Single-pass or per-subtask | `changed files, acceptance criteria` (no explicit context string template) |
| scaffold (step 7c) | Per-subtask in feature loop | `changed files, acceptance criteria + Max test attempts = {Test attempts from CLAUDE.md, default 3}.` |

### Step-by-Step Comparison

| Step # | Step description | Bug-fix context (fix-ticket) | Feature context (implement-feature) | Scaffold context (scaffold) | Feature ≠ Scaffold? |
|--------|-----------------|------------------------------|--------------------------------------|----------------------------|---------------------|
| 1 | Read the bug report, fixer output (changed files, root cause), and impact report (test coverage section) | Agent reads "bug report" + fixer output + code-analyst impact report. Context provides `Max test attempts`. Bug report and impact report exist because triage + code-analyst ran. | Agent reads "changed files, acceptance criteria." No bug report — reads spec-analyst AC and fixer output. No code-analyst impact report. | Agent reads "changed files, acceptance criteria + Max test attempts." No bug report — reads spec/architecture + fixer output. No code-analyst impact report. | **NO** — Both feature and scaffold provide changed files + acceptance criteria. Neither has a "bug report" or "impact report." The agent must adapt to whatever input it gets. The context shape is identical. |
| 2 | Run existing tests first; check for pre-existing failures vs new failures | Runs test command from Automation Config. Pre-existing failures documented by fixer are expected. | Runs Test command. Same logic — pre-existing failures from fixer noted. | Runs Test command from *generated* CLAUDE.md. Same logic. Project is brand-new so "pre-existing failures" are unlikely but possible if scaffolder created partial tests. | **NO** — The test command source differs (original CLAUDE.md vs generated CLAUDE.md) but that is a skill-level concern, not an agent behavior difference. The agent's behavior is identical: run tests, check for new failures. |
| 3 | Plan test scope — write 1-3 focused tests: regression test (required), edge case (recommended), boundary (optional) | "One test verifying the specific behavior that was fixed (regression test)" — the word "fixed" implies a bug. | "One test verifying the specific behavior that was fixed" — in feature context, "fixed" = "implemented." The agent should write a test for the new behavior. | Same as feature — "fixed" = "implemented." The agent writes tests for newly implemented subtask behavior. | **NO** — The agent's step 3 uses "fixed" generically. In both feature and scaffold, the agent interprets this as "the change that was made." There is no scaffold-specific test planning logic needed. |
| 4 | Write new tests following Arrange-Act-Assert, project conventions, correct directory | Follows existing test conventions. | Follows existing test conventions. | Follows whatever test conventions exist in the scaffolded project. The scaffolder should have set up test infrastructure (per scaffold step 3 scorecard). If no tests exist, the agent creates the first test file per language conventions. | **NO** — The agent already handles the "no existing tests" case: "If no existing tests exist: create the test file following language conventions." This covers scaffold's greenfield scenario without any scaffold-specific logic. |
| 5 | Run new tests — must pass on first try; fix if fail (max 3 attempts, then Block) | Standard retry logic. | Standard retry logic. | Standard retry logic. | **NO** — Identical behavior. |
| 6 | Output: Test Report (existing tests count, new tests list) | Standard output format. | Standard output format. | Standard output format. | **NO** — Identical output format. |

### Failure Handling Comparison

| Aspect | Bug-fix (fix-ticket) | Feature (implement-feature) | Scaffold (scaffold) | Feature ≠ Scaffold? |
|--------|---------------------|------------------------------|---------------------|---------------------|
| On Block | Block handler (step X): rollback-agent + issue tracker comment + webhook | Block handler (step X): rollback-agent + issue tracker comment + webhook | Block handler (step 7 block handler): rollback-agent + stdout report (NO issue tracker). Follows Fail strategy: fail-fast stops, continue skips subtask. | **YES** — Scaffold uses stdout block reporting, no issue tracker. Also follows Fail strategy (fail-fast vs continue). But this is a SKILL-LEVEL difference, not an agent-level difference. The test-engineer itself just outputs a Block Comment Template — it is the *skill* that routes the block differently. |

### Verdict: `2_MODES_SUFFICIENT`

The test-engineer agent behaves identically across all three pipelines. Every step produces the same outputs and follows the same logic regardless of whether the context comes from a bug report, feature spec, or scaffold spec.

Key observations:
- Step 1 says "Read the bug report" but the agent adapts to whatever input context it receives. It does not branch on mode.
- Step 3 says "regression test" — in feature/scaffold, this simply becomes "test verifying the implemented behavior."
- The only difference is in failure routing (stdout vs issue tracker), which is handled by the skill, not the agent.
- The "no existing tests" case in step 4 already covers scaffold's greenfield scenario.

The word "bug" appears in step 1 ("Read the bug report") and step 3 ("behavior that was fixed"), but these are descriptive rather than prescriptive — the agent works with whatever context the skill provides.

---

## agents/e2e-test-engineer.md

### Agent Definition Summary

The e2e-test-engineer has 9 process steps. It is described as a "Senior QA Automation Engineer specializing in E2E tests" whose goal is to cover "the complete user flow affected by the fix."

### Context Passed by Each Skill

| Skill | Step | Exact context string |
|-------|------|---------------------|
| fix-ticket (step 8b) | Single-pass | No explicit context string documented — just "Run `ceos-agents:e2e-test-engineer` (Task tool, model: sonnet)" |
| fix-ticket (step 4c.9) | Decomposition subtask | No explicit context string — just "If E2E Test section exists: run e2e-test-engineer." |
| implement-feature (step 6g) | Single-pass or per-subtask | No explicit context string documented — just "Run the e2e-test-engineer agent (Task tool, model: sonnet)." |
| scaffold (step 8) | Post all subtasks | `spec/verification.md test strategy + list of implemented features + acceptance criteria` |

### Step-by-Step Comparison

| Step # | Step description | Bug-fix context (fix-ticket) | Feature context (implement-feature) | Scaffold context (scaffold) | Feature ≠ Scaffold? |
|--------|-----------------|------------------------------|--------------------------------------|----------------------------|---------------------|
| 1 | Read the bug report and fix diff — understand which user flow was affected | Reads bug report + fix diff. There is a specific bug with a specific user flow. | Reads feature spec + implementation diff. Understands which user flows were added/changed. | Reads `spec/verification.md test strategy + list of implemented features + acceptance criteria`. ALL user flows are new. | **YES** — In scaffold, the agent receives `spec/verification.md` which contains a formal test strategy (written by spec-writer), a list of ALL implemented features, and acceptance criteria. In feature mode, it gets ad-hoc context from the skill. The *shape* of the input differs: scaffold gives a curated verification plan; feature gives raw changed files + AC. However, the agent's *behavior* (read input, understand flows) does not change — it reads whatever it is given. This is an INPUT difference, not a BEHAVIORAL difference. |
| 2 | Read E2E test configuration from Automation Config (E2E Test section) | Reads from project's CLAUDE.md Automation Config. | Reads from project's CLAUDE.md Automation Config. | Reads from *generated* CLAUDE.md Automation Config. | **NO** — Same behavior. The skill provides the config source; the agent reads it the same way. |
| 3 | Deployment pre-flight — verify application is running (dispatch deployment-verifier or warn) | Checks Local Deployment section from skill context. Dispatches deployment-verifier if configured. | Same as bug-fix. | Deployment guard runs BEFORE e2e-test-engineer dispatch (scaffold step 8 deployment guard). If deployment failed, e2e-test-engineer is never dispatched. If Local Deployment is absent, scaffold logs a warning and dispatches anyway. | **NO** — The agent's step 3 behavior is identical. The scaffold skill pre-filters deployment failures before dispatch, but the agent doesn't know or care about that. If dispatched, it runs the same pre-flight check. |
| 4 | Check if E2E test infrastructure is available (running app, dry-run test command) | Standard check. | Standard check. | Standard check. In a scaffold context, the app may have just been started for the first time. | **NO** — Same behavior. Greenfield vs existing doesn't matter to the agent. |
| 5 | Review existing E2E tests for the affected area (Glob for test files, read patterns) | Finds existing E2E tests and reads conventions. | Same. | In scaffold, there may be zero existing E2E tests (the scaffolder may or may not have created test stubs). The agent uses Glob to find them — if none found, it proceeds with framework defaults. | **NO** — The agent already handles "none found" in its output format ("none found"). No scaffold-specific behavior needed. |
| 6 | Plan test scope — write 1-2 focused E2E tests: happy path (required), error/edge case (recommended) | Focuses on the user flow affected by the bug fix. 1-2 tests. | Focuses on user flows added by the feature. 1-2 tests. | Focuses on user flows from the full feature set. Context provides "list of implemented features" — potentially MANY flows, but scope is still 1-2 tests. | **YES** — Scaffold context includes ALL implemented features, not just one subtask's changes. However, the agent's instruction is still "1-2 focused E2E tests" per dispatch. The skill could dispatch it multiple times or once with a broader scope, but the agent behavior per invocation is the same: pick the most critical flow, write 1-2 tests. The scope selection may be harder with more flows, but the agent's process is unchanged. This is an INPUT VOLUME difference, not a BEHAVIORAL difference. |
| 7 | Write new E2E tests (resilient selectors, explicit waits, auth handling) | Standard E2E test writing. | Same. | Same — the writing patterns (data-testid, waits, auth helpers) are framework-level, not pipeline-level. | **NO** — Identical behavior. |
| 8 | Run the tests (E2E command, max 3 attempts) | Standard execution + retry. | Same. | Same. | **NO** — Identical. |
| 9 | Output: E2E Test Report (existing tests, new tests, auth handling) | Standard output format. | Standard output format. | Standard output format. | **NO** — Identical. |

### Failure Handling Comparison

| Aspect | Bug-fix (fix-ticket) | Feature (implement-feature) | Scaffold (scaffold) | Feature ≠ Scaffold? |
|--------|---------------------|------------------------------|---------------------|---------------------|
| On Block/Failure | Block handler (step X): rollback + issue tracker comment | Block handler (step X): rollback + issue tracker comment | "report as warning (do not block — features are already committed)" — scaffold treats E2E failure as non-blocking. | **YES** — Scaffold explicitly does NOT block on E2E failure; it reports a warning. Bug-fix and feature both block. But this is a SKILL-LEVEL routing difference. The agent itself produces the same output (Block Comment Template or pass); the skill decides whether to treat it as fatal. |

### Scaffold-Specific Input Analysis

The scaffold skill provides a **unique context** to e2e-test-engineer that differs from both bug-fix and feature:

```
Context: spec/verification.md test strategy + list of implemented features + acceptance criteria
```

This is structurally different from:
- **Bug-fix**: implicit context (bug report + fix diff available in the conversation)
- **Feature**: implicit context (changed files + acceptance criteria mentioned but no explicit context string)

However, this is an **input enrichment**, not a behavioral fork. The agent reads whatever it gets. The spec/verification.md is just additional helpful context — the agent doesn't need to branch its process based on whether this document exists.

### Language Analysis: Bug-Centric Wording

The agent definition uses bug-centric language in two places:
- Step 1: "Read the bug report and fix diff"
- Goal: "user flow affected by the fix"
- Goal: "Prevent UI-level regressions"

In feature/scaffold context:
- "bug report" → becomes "feature spec" or "spec/verification.md"
- "affected by the fix" → becomes "added by the implementation"
- "regressions" → still relevant (ensure new features don't break each other)

These are **natural language descriptions** that the agent interprets flexibly. No code branching is needed.

### Verdict: `2_MODES_SUFFICIENT`

The e2e-test-engineer agent behaves identically across all three pipelines at the process step level. The differences are:

1. **Input shape** (scaffold provides spec/verification.md; others provide ad-hoc context) — but the agent reads whatever it gets without branching
2. **Failure routing** (scaffold treats failure as warning; others block) — but this is a skill-level decision, not an agent-level behavior
3. **Scope of flows to test** (scaffold has all features; bug-fix has one fix) — but the agent always writes 1-2 focused tests per invocation regardless of input volume

No step in the agent's process requires a conditional branch based on whether the pipeline is "feature" or "scaffold."

---

## Overall Summary

| Agent | Steps with Feature ≠ Scaffold at AGENT level | Verdict |
|-------|----------------------------------------------|---------|
| test-engineer | 0 out of 6 | **2_MODES_SUFFICIENT** |
| e2e-test-engineer | 0 out of 9 | **2_MODES_SUFFICIENT** |

### Key Finding: All Differences Are Skill-Level, Not Agent-Level

Both agents exhibit differences between feature and scaffold contexts, but EVERY difference is in one of two categories:

1. **Input shape differences** — the skill provides different context strings, but the agent's process steps are the same (read input, write tests, run tests, report). The agent does not need a mode flag to handle different inputs.

2. **Failure routing differences** — scaffold treats test/E2E failures as warnings (non-blocking); bug-fix and feature treat them as blocks. But the agent always outputs the same structured result (Test Report or Block Comment Template). The skill decides what to do with that output.

### Recommendation

For `test-engineer` and `e2e-test-engineer`, the agent definitions do NOT need a mode parameter. The current single-mode definitions are sufficient for all three pipelines. The skill layer handles all pipeline-specific routing and context assembly.

The only improvement worth considering is updating bug-centric language in the agent definitions to be more generic:
- Step 1 of test-engineer: "Read the bug report" → "Read the issue context (bug report, feature spec, or implementation scope)"
- Step 1 of e2e-test-engineer: "Read the bug report and fix diff" → "Read the issue context and implementation diff"
- Goal of e2e-test-engineer: "affected by the fix" → "affected by the changes"

These are cosmetic wording changes, not behavioral changes. The agents already work correctly without them because they adapt to whatever context they receive.
