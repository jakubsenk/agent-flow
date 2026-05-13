# Phase 2 Research Answers — Agent 1 (CRQ-1 through CRQ-4)

Agent: agent-1
Questions: CRQ-1, CRQ-2, CRQ-3, CRQ-4
Date: 2026-04-13

---

## CRQ-1: Fixer hard Block on missing triage/impact artifacts

### Finding Summary

The fixer's Step 1 checks for "triage analysis" and "impact report" by name. The `implement-feature` Step 6b provides "architectural design + subtask scope + acceptance criteria" — none of which are labeled "triage analysis" or "impact report". The fixer will likely Block unless it interprets the architectural design as a substitute, which is ambiguous prose-level matching with no formal contract.

### Evidence Table

| File | Line | Exact Text | Severity |
|------|------|-----------|----------|
| `agents/fixer.md` | 20 | `"Read the triage analysis and impact report thoroughly. If triage analysis or impact report is missing, Block with reason 'Missing input from previous pipeline stage'."` | CRITICAL |
| `skills/implement-feature/SKILL.md` | 447–448 | `"Run the fixer agent (Task tool, model: opus): - Context: architectural design + subtask scope + acceptance criteria"` | CRITICAL |
| `core/fixer-reviewer-loop.md` | 13 | `"context | string | required | Bug report or spec + AC + code-analyst output"` | HIGH |

### Analysis

The fixer's Step 1 is a hard check: it specifically names "triage analysis" and "impact report". The `implement-feature` pipeline provides three substitutes — architectural design (from architect), subtask scope, and AC from spec-analyst — but none are explicitly named "triage analysis" or "impact report". The `fixer-reviewer-loop.md` input contract acknowledges "Bug report or spec + AC + code-analyst output" as valid alternatives, but the fixer agent itself does not reflect this flexibility. The fixer reads its own Step 1 literally and will Block if those specific labeled artifacts are absent.

### Recommendation

Update `agents/fixer.md` Step 1 to accept the feature pipeline's artifact vocabulary. Change the guard condition to: "If triage analysis (bug context) or architectural design (feature context) and acceptance criteria are missing, Block." This makes the condition pipeline-mode-aware without coupling the fixer to a specific pipeline.

---

## CRQ-2: No pipeline mode signal to shared agents

### Finding Summary

No explicit "mode: feature-implementation" signal is passed when `implement-feature` dispatches fixer, reviewer, or test-engineer. These agents receive different context payloads per pipeline, but have no formal mode flag — they must infer context from what artifacts are present.

### Evidence Table

| File | Line | Exact Text | Severity |
|------|------|-----------|----------|
| `skills/implement-feature/SKILL.md` | 447–448 | `"Context: architectural design + subtask scope + acceptance criteria"` | HIGH |
| `skills/implement-feature/SKILL.md` | 460–461 | `"Context: diff from fixer + acceptance criteria from spec-analyst"` | MEDIUM |
| `skills/implement-feature/SKILL.md` | 484–485 | `"Context: changed files, acceptance criteria"` | MEDIUM |
| `agents/fixer.md` | 20 | `"Read the triage analysis and impact report thoroughly."` — no mode branch | HIGH |
| `agents/reviewer.md` | 20 | `"Read the original bug report, triage analysis, impact report, and the fixer's output"` — no mode branch | HIGH |
| `agents/test-engineer.md` | 20 | `"Read the bug report, fixer output (changed files, root cause), and impact report"` — no mode branch | HIGH |

### Analysis

All three shared agents (fixer, reviewer, test-engineer) are written with bug-fix pipeline vocabulary in their Process sections. They reference "bug report", "triage analysis", "impact report" as expected inputs. When invoked from `implement-feature`, the context payload replaces those with "architectural design + subtask scope + AC", but there is no explicit mode signal telling the agent "you are in feature-implementation mode, not bug-fix mode". The agents must infer this from context structure alone, which is fragile. The reviewer's Step 1 and test-engineer's Step 1 will attempt to "read bug report and impact report" from context that does not contain these, potentially producing confused or degraded behavior.

### Recommendation

Add a `mode` field to the context passed when dispatching shared agents from `implement-feature`. For example, prepend the context with `Mode: feature-implementation` and update the agent Process sections to branch on mode — handling "bug-fix" vs "feature-implementation" vocabulary explicitly. Alternatively, refactor the agents to accept a generic "problem statement + AC" contract so they are pipeline-agnostic.

---

## CRQ-3: NEEDS_DECOMPOSITION from feature subtask — no handler

### Finding Summary

When fixer emits `NEEDS_DECOMPOSITION` during `implement-feature`, the `fixer-reviewer-loop.md` returns it to the caller (`implement-feature`), but `implement-feature` Step 6b has no handler for this signal — it only handles build failure and reviewer approval/rejection. The signal falls through silently.

### Evidence Table

| File | Line | Exact Text | Severity |
|------|------|-----------|----------|
| `core/fixer-reviewer-loop.md` | 22–23 | `"If fixer output contains ## NEEDS_DECOMPOSITION → return NEEDS_DECOMPOSITION immediately. Only allowed once per ticket; caller enforces the limit."` | CRITICAL |
| `core/fixer-reviewer-loop.md` | 43–44 | `"NEEDS_DECOMPOSITION → returned to caller; caller handles decomposition logic (see core/decomposition-heuristics.md and skills/fix-ticket/SKILL.md step 5)."` | CRITICAL |
| `skills/implement-feature/SKILL.md` | 447–464 | Step 6b and 6d describe only: fixer run → build failure → reviewer loop → APPROVE or REQUEST_CHANGES. No `NEEDS_DECOMPOSITION` branch. | CRITICAL |
| `agents/fixer.md` | 33–44 | `"ESCAPE HATCH: If during implementation you realize the fix requires changes across ≥4 files or the diff is approaching the 100-line limit... Output a NEEDS_DECOMPOSITION signal"` | CRITICAL |
| `agents/fixer.md` | 78 | `"NEEDS_DECOMPOSITION may be signaled at most ONCE per ticket."` | HIGH |

### Analysis

The `fixer-reviewer-loop.md` explicitly says "caller enforces the limit" and directs to `fix-ticket/SKILL.md` step 5 as the reference implementation — not `implement-feature`. The `implement-feature` skill has no branch in Step 6b that catches `NEEDS_DECOMPOSITION`. This creates an unhandled signal: the loop exits with `NEEDS_DECOMPOSITION`, but `implement-feature` Step 6b only checks for build failure and proceeds to reviewer. The most likely runtime behavior is that the fixer's NEEDS_DECOMPOSITION output is treated as a Fix Report by the reviewer, causing confusion, or the pipeline stalls. In decomposition mode (multiple subtasks), this is especially problematic — decomposing an already-decomposed subtask is architecturally incoherent and there is no guard.

### Recommendation

Add a `NEEDS_DECOMPOSITION` handler in `implement-feature` Step 6b, after the fixer-reviewer loop returns. In single-pass mode, the handler should Block with a message like "Feature scope exceeds fixer limits in single-pass mode — re-run with `--decompose` flag or break the feature into smaller issues manually." In decomposition mode (per-subtask), Block on that subtask and proceed to the next if `fail-fast` is not set, or stop the pipeline if `fail-fast` is set. Mirror the handler from `fix-ticket/SKILL.md` step 5.

---

## CRQ-4: Smoke-check Block leaves git dirty

### Finding Summary

The smoke-check failure in `implement-feature` Step 6d-smoke routes to the Block handler (Step X), which calls `rollback-agent`. However, `rollback-agent` Step 1 only rolls back for agents: `fixer`, `test-engineer`, `e2e-test-engineer`, `reviewer`. The agent name passed is `smoke-check` — which is not in the rollback trigger list. Rollback is skipped, leaving git in a dirty post-fixer state.

### Evidence Table

| File | Line | Exact Text | Severity |
|------|------|-----------|----------|
| `skills/implement-feature/SKILL.md` | 472–477 | `"Run Build command via Bash. If it fails → Block handler (step X) with agent = smoke-check, Step = 6d-smoke..."` | CRITICAL |
| `agents/rollback-agent.md` | 25–28 | `"If the blocking agent is fixer, test-engineer, e2e-test-engineer, or reviewer → proceed with rollback."` | CRITICAL |
| `agents/rollback-agent.md` | 24–26 | `"If the blocking agent is triage-analyst, code-analyst, spec-analyst, architect, or stack-selector → STOP. Do nothing."` | HIGH |
| `core/block-handler.md` | 21 | `"If the blocking agent is fixer, reviewer, or test-engineer → dispatch ceos-agents:rollback-agent"` | CRITICAL |

### Analysis

There is a double failure here: both `core/block-handler.md` Step 1 and `rollback-agent.md` Step 1 have explicit allowlists for which agents trigger rollback. `smoke-check` is absent from both lists. The `block-handler.md` Step 1 says rollback is dispatched only for `fixer`, `reviewer`, or `test-engineer`. `rollback-agent.md` Step 1 adds `e2e-test-engineer` to its own list but also won't match `smoke-check`. The net effect: when smoke check fails after fixer+reviewer approval (code is already committed per the per-subtask loop design — Step 6i commits after 6h), the block handler fires but rollback is not performed. Git state is dirty with the fixer's changes intact on the branch. The issue is blocked in the tracker, but the branch is left in an inconsistent state.

Note: In single-pass mode, the fixer's work has not yet been committed at the time of smoke check (Step 6i commits after 6h acceptance gate), so the dirty state is uncommitted changes — still problematic but at least not committed to the branch. In decomposition mode, previous subtask commits are clean (they passed their own smoke check), but the current subtask's uncommitted changes remain.

### Recommendation

Two complementary fixes are needed:

1. Add `smoke-check` to the rollback trigger list in `core/block-handler.md` Step 1: change the condition from "If the blocking agent is `fixer`, `reviewer`, or `test-engineer`" to also include `smoke-check`.

2. Add `smoke-check` to the proceed-with-rollback list in `agents/rollback-agent.md` Step 1 (or remove the allowlist approach in favor of a denylist — only skip rollback for read-only agents and publisher/scaffolder).

The denylist approach (option 2b) is more robust: specify agents that should NOT rollback (triage-analyst, code-analyst, spec-analyst, architect, stack-selector, publisher, scaffolder) rather than an allowlist, so new agents automatically get correct rollback behavior.
