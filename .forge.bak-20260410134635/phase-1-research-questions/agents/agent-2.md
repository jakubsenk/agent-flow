# Agent 2 Research Findings — D5, D6, D7, D8

### D5: Graduated Escalation
- **Claim accuracy:** PARTIALLY_CONFIRMED
- **Evidence:**
  - `agents/fixer.md` lines 33–44: NEEDS_DECOMPOSITION is explicitly defined as a third output state beyond BLOCK/SUCCESS. It triggers when "fix requires changes across ≥4 files or the diff is approaching the 100-line limit." The signal includes Reason, Estimated scope, Suggested split, Work done so far.
  - `core/fixer-reviewer-loop.md` line 22: "If fixer output contains `## NEEDS_DECOMPOSITION` → return `NEEDS_DECOMPOSITION` immediately." The loop contract returns 3 values: APPROVED, BLOCKED, or NEEDS_DECOMPOSITION.
  - `core/block-handler.md`: Only handles the BLOCK state. No NEEDS_CLARIFICATION, no pause/wait mechanism.
  - `agents/stack-selector.md` lines 29, 60: Stack-selector can ask "up to 3 clarifying questions" — but this is a pre-pipeline scaffold agent, not a mid-pipeline agent in the bug/feature fix flow.
  - `agents/spec-writer.md` line 30: "In interactive mode: ask clarifying questions one at a time" — again scaffold context only.
  - `skills/fix-ticket/SKILL.md` and `skills/implement-feature/SKILL.md`: Confirm user interaction exists at: decomposition plan approval (Step 4b/5), AC coverage unmapped check, and PR creation decision (Step 9). These are skill-level confirmation points, not agent-level clarification states.
  - No `NEEDS_CLARIFICATION` signal exists anywhere in the codebase (Grep confirmed).
- **Nuance:** The report is right that there is no NEEDS_CLARIFICATION state — agents in the bug/feature pipeline cannot pause and ask clarifying questions mid-run. However, the "binary block/success" characterization is partially wrong: NEEDS_DECOMPOSITION is a genuine third signal from fixer that causes a scope-expansion path rather than failure. The skills also include multiple user confirmation checkpoints (decomposition plan approval, AC coverage, PR decision). The absence of clarification is by design — fixer's incomplete knowledge leads to BLOCK or NEEDS_DECOMPOSITION, never a wait-for-user-input signal.

---

### D6: Cost Guardrails
- **Claim accuracy:** CONFIRMED
- **Evidence:**
  - `skills/estimate/SKILL.md`: The skill is described as pre-run only — its process fetches issue details, scans code, and produces a cost range report. No mechanism to call it mid-pipeline, no automatic invocation from fix-ticket or fix-bugs. It is explicitly listed as a standalone pre-run planning tool.
  - `core/state-manager.md`: No cost or token tracking fields anywhere in the state manager process.
  - `state/schema.md` full schema: No cost, token, budget, or spending fields exist in state.json. Schema tracks phases, retries, verdicts, git hashes — not token consumption.
  - `CLAUDE.md` Automation Config contract: No cost-related config keys in any section. The Retry Limits section controls pipeline iteration counts only (Fixer iterations, Test attempts, Build retries, Spec iterations, Root cause iterations).
  - `skills/fix-ticket/SKILL.md` line 589–591: A static hardcoded estimate ("Estimated usage: ~119,000 tokens / ~$0.50–$1.60 USD") appears as an informational note at Step 9c, not as a runtime guardrail that can stop execution.
  - `docs/plans/2026-02-27-02-decomposition-v3.1.md` line 1723: Historical design note mentions "Celkovy token budget (konfigurovatelny) — po dosazeni limitu STOP" (Total token budget, configurable — stop when limit reached) but this was a brainstorm note, never implemented.
- **Nuance:** The report is fully accurate. There are no hard cost ceilings, no mid-pipeline cost tracking, no automatic stop on budget overrun. The estimate skill is strictly pre-run. The only runtime cost awareness is the static informational note at the end of fix-ticket. The design discussion (decomposition brainstorm doc) acknowledged this gap but it was never implemented.

---

### D7: Flaky Test Detection
- **Claim accuracy:** CONFIRMED
- **Evidence:**
  - `agents/test-engineer.md` lines 22–23: When existing tests fail, the agent checks if "ALL failures are pre-existing (documented by fixer)" — if so, it continues; if any NEW failures exist, it Blocks. This is a pre-existing failure awareness, not flakiness detection.
  - `agents/test-engineer.md` line 49 (Constraints): "NEVER write flaky tests — no random data, no timing dependencies, no external service calls." This is a prohibition on writing flaky tests, not detection/handling of flaky tests in the existing suite.
  - `agents/test-engineer.md` lines 34–35: "Must pass on first try... If test fails → fix the test (max 3 attempts, then Block)." No retry/rerun mechanism for distinguishing a flaky failure from a real failure.
  - `core/fixer-reviewer-loop.md`: No flakiness logic. Build failures → BLOCKED. No re-run on intermittent failure.
  - `skills/fix-ticket/SKILL.md` Step 8: "Loop: max {Test attempts} attempts." The attempts here are for test-engineer fixing failing tests it wrote, not for rerunning the same test to detect flakiness.
  - `checklists/test-checklist.md` line 13: "No flaky tests (no timing dependencies, no external service calls)" — prevention checklist only, no detection guidance.
  - Grep for "flaky", "retry", "unstable", "rerun" across all agent and skill files confirms: flakiness handling is limited to "don't write flaky tests" guidance; no detection, quarantine, or rerun logic exists.
- **Nuance:** The report is accurate. The pipeline has no mechanism to distinguish a flaky pre-existing test failure from a genuine regression introduced by the fix. Any test failure that is not pre-documented by the fixer will cause a Block. The "max 3 attempts" retry for test-engineer is for the agent fixing its own newly-written tests, not for rerunning existing tests multiple times to detect intermittent failures.

---

### D8: Plugin Self-Tests in CI
- **Claim accuracy:** PARTIALLY_CONFIRMED
- **Evidence:**
  - `.gitea/workflows/test.yaml` lines 1–4: The file itself contains a note: "NOTE: No Gitea Actions runner is configured for this repo. All jobs will be cancelled at 0s. Tests run locally via ./tests/harness/run-tests.sh. This workflow is kept for future use if a runner is registered."
  - `.gitea/workflows/test.yaml` lines 5–19: The CI workflow is fully defined (triggers on push to main and pull_request, runs `bash tests/harness/run-tests.sh`) but cannot execute because no runner is registered.
  - `tests/harness/run-tests.sh`: A complete bash test harness that loops through all scenario scripts in `tests/scenarios/`, reports PASS/FAIL/SKIP, exits with code 1 on any failure.
  - `tests/scenarios/`: 50 scenario files (actual count from directory listing), covering happy path, block scenarios, retry limits, pipeline consistency, scaffold, state schema, cross-skill consistency, agent registry, and more. The README states 13 but the actual directory contains 50 scripts.
  - `tests/README.md` line 72: "CI: Gitea Actions workflow runs tests on push" — this claim in the docs is contradicted by the workflow file's own header note.
  - Test scenarios include structural validation (frontmatter-completeness.sh, read-only-agents.sh, xref-agent-registry.sh, xref-core-registry.sh, xref-command-count.sh, core-include-refs.sh, skills-directory-structure.sh, skills-frontmatter-check.sh, section-order.sh) — these catch regressions in agent definitions without running a live pipeline.
- **Nuance:** The report's claim that "tests don't run in CI" is confirmed — no runner is registered and all CI jobs cancel at 0s. However, the claim that "there is no way to automatically detect regression in agent definitions" is too strong. A comprehensive 50-scenario test suite exists and runs correctly via `./tests/harness/run-tests.sh` locally. The test suite includes structural validation scenarios that would catch regressions in agent definitions. The gap is purely the missing CI runner, not the absence of tests. The README documentation also overstates CI capability ("runs tests on push") when the runner is absent.
