# Phase 8 Correctness Adversary Report

## Test Harness Run

- Exit code: 0 (harness exits 0 even with 1 failing test — test failure does not propagate to process exit code)
- Total tests: 140
- Passing: 139
- Failing: 1

**Failing test:** `ac-v68-doc-version-6.8.0`

```
FAIL: .claude-plugin/plugin.json does not contain '"version": "6.8.0"'
FAIL: .claude-plugin/marketplace.json does not contain '"version": "6.8.0"'
```

Both manifests still show `"version": "6.7.2"`. AC-27 maps to EARS requirement "all" (version bump). The version bump was deferred or not committed; the implementation is otherwise feature-complete but the version artifact is missing.

---

## Findings

### [CORRECTNESS-FINDING-1] severity=HIGH

**Location:** `skills/fix-ticket/SKILL.md:87` and `skills/implement-feature/SKILL.md:89`

**Expected:** state.json is initialized with the final `run_id` value (`"{ISSUE_ID}_{YYYYMMDDTHHMMSSZ}"`), or if initialized with a placeholder, a subsequent atomic write updates `run_id` in state.json before any webhook fires.

**Actual:** Both `fix-ticket` (line 87) and `implement-feature` (line 89) initialize state.json with `run_id: "{ISSUE-ID}"` (the pre-v6.8.0 bare form), then on the very next line compute the correct `run_id` from memory and fire `pipeline-started` using the in-memory value. There is NO step that writes the corrected `run_id` back to state.json. Result: `state.json.run_id` contains `"PROJ-42"` while all three webhook payloads use `"PROJ-42_20260417T143000Z"`. Any consumer that reads `run_id` from state.json to correlate with webhook events will get mismatched values.

Compare with `fix-bugs` (line 98–99) which explicitly writes `run_id` to state.json in a dedicated Step 0-obs — that is the correct pattern. `fix-ticket` and `implement-feature` lack the explicit `run_id` state.json update step.

**Repro:** Read `state/schema.md` example (line 38): `"run_id": "PROJ-42"`. Cross-reference with design.md canonical definition: `"{issue_id}_{YYYYMMDDTHHMMSSZ}"`. Grep `fix-ticket/SKILL.md` line 87 for `run_id: "{ISSUE-ID}"` — the init does not use the timestamped form.

---

### [CORRECTNESS-FINDING-2] severity=HIGH

**Location:** `state/schema.md` lines 22–31 ("RUN-ID Determination" table)

**Expected:** The RUN-ID Determination table reflects the v6.8.0 canonical `run_id` format `"{issue_id}_{YYYYMMDDTHHMMSSZ}"` for issue tracker pipelines (per design.md canonical definitions and requirements.md §1.3).

**Actual:** The table still shows the pre-v6.8.0 format `ISSUE-ID` (example: `PROJ-42`) with no timestamp component. The schema example at line 38 also shows `"run_id": "PROJ-42"`. This means the schema.md documentation contradicts the actual format implemented in all four pipeline skills and documented in design.md §4.3.

Consumers reading schema.md to understand the `run_id` field format will implement incorrect parsers that do not expect the `_{YYYYMMDDTHHMMSSZ}` suffix, breaking log correlation.

**Repro:** `grep -n '"run_id": "PROJ-42"' state/schema.md` returns line 38 — no timestamp. `grep "run_id" design.md` returns `"{issue_id}_{YYYYMMDDTHHMMSSZ}"`.

---

### [CORRECTNESS-FINDING-3] severity=MEDIUM

**Location:** `.claude-plugin/plugin.json:4`, `.claude-plugin/marketplace.json:11`

**Expected:** Both files show `"version": "6.8.0"` per AUTOPILOT-R1, AC-27, and design.md §3.6.

**Actual:** Both files show `"version": "6.7.2"`. This is the direct cause of the test harness failure (`ac-v68-doc-version-6.8.0` FAIL). All other implementation work is present, but the version bump was not executed. The failing test (exit 0 from harness) conceals the failure from a simple exit-code check — the harness returns 0 despite 1 failure, which is itself a secondary finding (see [CORRECTNESS-FINDING-7]).

**Repro:** `grep '"version"' .claude-plugin/plugin.json .claude-plugin/marketplace.json` → both return `6.7.2`.

---

### [CORRECTNESS-FINDING-4] severity=MEDIUM

**Location:** `skills/fix-ticket/SKILL.md:495,529`, `skills/fix-bugs/SKILL.md:665,668`, `skills/implement-feature/SKILL.md:524,556`, `skills/scaffold/SKILL.md:987`

**Expected:** `pipeline-completed` webhook fires with `outcome` one of `success`, `blocked`, `failed` (per design.md §4.5 and `core/post-publish-hook.md` Section 4).

**Actual:** None of the four pipeline skills fire `pipeline-completed` with `outcome: "failed"`. Only `success` and `blocked` are implemented. The `failed` outcome would be relevant when the pipeline exits due to an unhandled exception or non-block error path (e.g., MCP failure during mid-pipeline operation, catastrophic state write failure). Without a `failed` outcome emission, monitoring consumers cannot distinguish between a blocked pipeline (expected, recoverable) and a crashed pipeline (unexpected, requires human intervention). The `failed` state also exists in the top-level `status` enum in schema.md, but no corresponding `pipeline-completed` call is wired.

**Repro:** `grep -n "outcome.*failed" skills/fix-ticket/SKILL.md skills/fix-bugs/SKILL.md skills/implement-feature/SKILL.md skills/scaffold/SKILL.md` → zero matches.

---

### [CORRECTNESS-FINDING-5] severity=MEDIUM

**Location:** `skills/autopilot/SKILL.md:128,208` vs `requirements.md:AUTOPILOT-R3,AUTOPILOT-R4`

**Expected (AUTOPILOT-R3):** Lock with `acquired_at` ≤ 120 minutes ago → exit 2. Lock with `acquired_at` > `Lock timeout` minutes → reclaim (AUTOPILOT-R4).

**Actual:** The implementation uses `age_min -gt LOCK_TIMEOUT_WITH_BUFFER` where `LOCK_TIMEOUT_WITH_BUFFER = LOCK_TIMEOUT + 5` (line 128). With default `LOCK_TIMEOUT=120`, the actual stale threshold is 125 minutes, not 120. A lock that is 121–125 minutes old would exit 2 (as if fresh), contradicting AUTOPILOT-R3's literal "≤ 120 minutes ago" language. The +5 minute buffer is intentional per design.md §4.8 point 6 ("absorb NFS/CIFS clock skew") but the EARS requirement does not reflect this relaxation. The troubleshooting note at line 363 also says "lock is <120min old" — consistent with the spec literal but not the implementation.

**Repro:** Set `LOCK_TIMEOUT=120`. Create lock with `acquired_at` 122 minutes ago. Run autopilot. Expected per spec: reclaim (AUTOPILOT-R4, >120). Actual: exit 2 (age 122 < LOCK_TIMEOUT_WITH_BUFFER 125). The spec and implementation disagree on the window 121–125 minutes.

---

### [CORRECTNESS-FINDING-6] severity=LOW

**Location:** `skills/fix-ticket/SKILL.md:164` vs `skills/fix-ticket/SKILL.md:322`

**Expected:** All stages compute `duration_ms` consistently as `completed_at epoch ms − started_at epoch ms`.

**Actual:** The triage stage post-dispatch (line 164) explicitly specifies `duration_ms = completed_at epoch ms − started_at epoch ms`. The fixer_reviewer stage post-dispatch (line 322) uses the formula `fixer_reviewer.duration_ms += elapsed ms` — "elapsed ms" is an unspecified variable name not defined in context. For other stages (code_analysis, reproduction, test, e2e_test, etc.), the post-dispatch only says `write {stage}.duration_ms` without specifying the formula at all. An LLM executing this skill must infer the formula from context; if it uses `result.usage.duration_ms` (the Task tool response field) rather than the wall-clock delta, the stored value would differ from the spec formula. `state-manager.md` line 97 shows `{stage}.duration_ms = completed_at epoch ms − started_at epoch ms` as the canonical formula, but no in-line reminder appears in most stage post-dispatch steps of fix-ticket.

**Repro:** `grep -n "duration_ms.*epoch\|duration_ms.*started_at" skills/fix-ticket/SKILL.md` returns only line 164 (triage). All other stages lack the explicit formula.

---

### [CORRECTNESS-FINDING-7] severity=LOW

**Location:** `tests/harness/run-tests.sh` (exit code behavior)

**Expected:** A test harness that reports 1 failure returns a non-zero exit code so CI pipelines and human reviewers detect the failure.

**Actual:** The harness returns exit code 0 despite 1 failing test (`ac-v68-doc-version-6.8.0`). The final output line shows `Total: 140 | Pass: 139 | Fail: 1 | Skip: 0` but the process exits 0. This means a CI pipeline configured as `./tests/harness/run-tests.sh && echo "OK"` would incorrectly report success. Verification of the failing test requires reading stdout rather than checking the exit code.

**Repro:** `bash tests/harness/run-tests.sh; echo "Exit: $?"` → outputs `Exit: 0` despite `Fail: 1`.

---

### [CORRECTNESS-FINDING-8] severity=LOW

**Location:** `skills/fix-ticket/SKILL.md:306` — `step-completed` for `reproduction` stage

**Expected per WEBHOOK-R3:** `step-completed` fires when the stage "successfully writes `{stage}.status: completed`". On a block (reproducer is never blocked per skill) or on `skipped` status, the webhook is skipped.

**Actual:** Line 306 says "Skip if stage was skipped". However, the reproducer has three non-completed statuses per line 303–304: `completed` (fires webhook), `skipped` (skipped), and implicitly if the reproducer is dispatched and returns `not_reproduced` or `reproduced` — in these cases the stage is still set to `completed` and the webhook fires correctly. This is correct. But the status `skipped` and `not_reproduced` paths both result in `reproduction.status = "completed"` (line 304 says status is completed for ALL non-skip outcomes), meaning the webhook fires for `not_reproduced` runs — which is correct behavior per WEBHOOK-R3 (the stage completed). However, the sentence "set `reproduction.status` to `"completed"` (or `"skipped"` if skipped)" suggests the webhook would fire for `not_reproduced` outcomes, which is semantically correct but may surprise consumers expecting only `step-completed` on success verdicts.

This is a documentation clarity issue, not a logic error — the implementation is correct but the intent could be clearer.

---

## EARS Coverage Spot-Check (5 IDs)

| EARS ID | Implementation artifact found | Status |
|---|---|---|
| AUTOPILOT-R2 | `skills/autopilot/SKILL.md` Step 2 mkdir + owner.json write | PRESENT |
| AUTOPILOT-R5 | `install_trap()` function in Step 2 code block, verifies pid before rm -rf | PRESENT |
| WEBHOOK-R6 | `skills/fix-ticket/SKILL.md` line 346: "Fire ONCE per loop completion — never per iteration" | PRESENT |
| COST-R5 | `skills/fix-ticket/SKILL.md` lines 310,322: cumulative += pattern, "do not reset" | PRESENT |
| COST-R10 | `skills/fix-ticket/SKILL.md` line 491: truncation logic at 20 rows / 4000 chars | PRESENT |

---

## Dimension Score

**correctness_score: 0.62**

Calibration rationale:
- 2 HIGH findings (run_id state.json mismatch across fix-ticket/implement-feature; schema.md RUN-ID table stale) — each HIGH is a functional contract violation visible to consumers
- 2 MEDIUM findings (version bump missing → test failure; outcome=failed never fired) — version is a process failure, outcome=failed is a missing code path in an explicitly documented enum
- 1 MEDIUM (stale lock threshold 121–125 min spec vs implementation divergence)
- 3 LOW findings (duration_ms formula inconsistency; harness exit 0 on failure; reproduction webhook ambiguity)
- Core pipeline correctness (bug-wins-overlap, max-issues-1-total, fixer_reviewer cumulative, pipeline-completed on both success + block paths, step-completed cardinality per stage) is sound
- Deduction: -0.08 per HIGH (×2 = -0.16), -0.05 per MEDIUM (×3 = -0.15), -0.02 per LOW (×3 = -0.06)
- Starting from 0.99 (near-perfect baseline): 0.99 - 0.16 - 0.15 - 0.06 = 0.62
