# v6.9.1 Phase 8 Robustness Report

**Reviewer:** Phase 8 Devil's Advocate / Robustness Reviewer (v6.9.1 cycle-0, retry after opus overload)
**Baseline:** v6.9.0 cycle-1 robustness 0.88 (PASS)
**Scope:** 6 working-tree commits (A docs, B docs, C docs, D spec amendments + CHANGELOG, E 5 code fixes, F pipeline-resumed event)
**Method:** Source-walk + adversarial bash execution + hidden test run + full harness (184/184 PASS)

## Score: 0.90 (baseline 0.88; FAIL floor 0.70)

---

## Anti-regression scan (8 v6.9.0 cycle-1 fixes)

| # | Fix | Status | Evidence |
|---|-----|--------|---------|
| 1 | `asked_at` written by 6 orchestrators | **HOLDS** | `grep` → 6 `asked_at: "$ASKED_AT"` lines across fix-ticket (×2), fix-bugs (×2), implement-feature (×1), scaffold (×1) |
| 2 | `Question:` case-insensitive grep | **HOLDS** | All 6 detection sites use `grep -iE -A1 "^question:"` form; `grep -iE -A1 "^context:"` also present |
| 3 | `.fixer_reviewer.iterations` field path | **HOLDS** | 6 matches for `.fixer_reviewer.iterations`; zero matches for broken `.iteration` path |
| 4 | resume-ticket no double-increment | **HOLDS** | Step 4 text unchanged: "DO NOT increment `clarification.clarifications_consumed`" with full REQ-045 rationale |
| 5 | `pipeline-paused` webhook fires | **HOLDS** | 6 firing sites still present in fix-ticket (×2), fix-bugs (×2), implement-feature (×1), scaffold (×1) |
| 6 | `sanitize_block_reason()` 17 patterns POSIX | **HOLDS** | All 17 patterns confirmed at `core/post-publish-hook.md:305-327`; POSIX anchor `(^|[[:space:]])` intact |
| 7 | awk section-count trim | **HOLDS** | `core/post-publish-hook.md:341-351` section-aware awk block unchanged |
| 8 | `clarification_timeout` abort_reason | **HOLDS** | `skills/autopilot/SKILL.md:346` writes `abort_reason = "clarification_timeout"` after timeout; guard `[ -n "$asked_epoch" ] && [ "$asked_epoch" -gt 0 ]` prevents spurious abort on empty epoch |

All 8 anti-regression checks PASS. v6.9.1 changes did not regress any v6.9.0 cycle-1 fix.

---

## NEW v6.9.1 failure scenarios

### Scenario 1 (MEDIUM): `_iso_to_epoch_crossplatform()` — python3 missing + no GNU date → silent never-abort

**Trigger:** Host has neither `python3` nor GNU `date -d` (e.g., Alpine + BusyBox).

**Path:** `_iso_to_epoch_crossplatform()` tries `python3` (fails), falls back to `date -d` (BusyBox returns empty). Result: `asked_epoch=""`. Guard `[ -n "$asked_epoch" ]` is false → `pause_age_seconds=0` → timeout never fires → paused issues remain paused FOREVER on such hosts (never auto-aborted).

**Severity:** MEDIUM. Not a premature-abort safety regression (conservatively safe). But violates REQ-050a: "auto-abort after timeout" contract is silently broken on BusyBox hosts without python3. Operator has no visible warning.

**Proposed fix:** Log `[WARN] Cannot compute pause age (no python3 or GNU date); issue ${ISSUE_ID} will not be auto-aborted` when `asked_epoch` is empty and `asked_at` is non-empty.

**Adversarial test:** `.replace('Z', '+00:00')` pattern is safe on Python 3.7+ (fromisoformat added in 3.7; `+00:00` supported since 3.7). Python 3.6 does not have fromisoformat at all — `command -v python3` might still return true (if python3.6 installed), but the code would then exit non-zero and fall to GNU date. Net: Python < 3.7 causes silent fallback to GNU date; if GNU date also absent, same empty-epoch outcome as above. Python injection via `sys.argv[1]` is safe — the timestamp is passed as a data argument, not eval'd.

---

### Scenario 2 (LOW): `parse_pause_timeout()` — no-space and UTF-8 inputs

**Trigger A (no-space):** Input `"30Days"` (no separator). Regex `^([0-9]+)[[:space:]]+([Hh]…)$` requires at least one space; `30Days` fails → WARN + default 30 days. **Behaviorally safe** (graceful fallback). Not a regression; documented gap.

**Trigger B (UTF-8 unit):** Input `"30 dní"` (Czech "days"). `tr '[:upper:]' '[:lower:]'` is byte-based under `LC_ALL=C` (set in sanitize context but NOT explicitly set before `parse_pause_timeout()`). On UTF-8 terminals: `tr` may pass multi-byte chars through unchanged. The regex character class `[Dd][Aa][Yy][Ss]?` would then not match `dní` → WARN + default. **Behaviorally safe** (fallback). Not a real-world risk since `Pause timeout` is an operator-controlled config key, not user input. Severity: LOW.

**Trigger C (empty string):** Already tested: WARN + default 2592000. Safe.

---

### Scenario 3 (MEDIUM — TEST-ONLY): `h-snippet-citation-marker-format.sh` count stale at commit F boundary

**What happened:** Commit E updated the hidden test `expected_counts["webhook-curl"]=29` (correct post-cycle-1 count). Commit F then added 2 new `<!-- @snippet:webhook-curl -->` citation sites (1 in `skills/resume-ticket/SKILL.md`, 1 in `core/post-publish-hook.md` Section on pipeline-resumed). The test expected 29 but actual count became 31 → **test would have FAILed** between commit E and commit F if run at that point.

**Resolution (self-healing):** The hidden test file was updated (by linter/tool) to `expected_counts["webhook-curl"]=31` and the `core/snippets/README.md` table was updated to `| webhook-curl | 31 |` before this review ran. The `v6.9.1-commit-F-status.json` claimed `test_result: "184/184 PASS"` — this was the status AFTER the count correction. **Current state: PASS confirmed** (184/184 on actual harness run).

**Residual risk:** This pattern — commit adds firing sites without updating test — is the exact snippet-count drift hazard identified in cycle-0 Scenario 10. The count in the test is now a hardcoded literal that will need updating again next time a firing site is added. Recommend adding a comment `# UPDATE THIS when adding new webhook firing sites`.

**Severity of residual risk:** LOW (process gap, not a runtime bug).

---

### Scenario 4 (LOW — SECURITY): `sanitize_block_reason()` LOWER-VAR misses bare keyword variable names

**Finding:** The LOWER-VAR pattern `[A-Za-z_][A-Za-z0-9_]*([Pp][Aa][Ss][Ss]…|…)=…` requires a non-suffix prefix character before the credential keyword. Bare variable names `password=secret`, `secret=foo`, `token=bar` are **NOT redacted** because the regex engine greedily consumes the full variable name in `[A-Za-z_][A-Za-z0-9_]*`, exhausting the input before the suffix alternation can match.

**Adversarial test (executed on Git-Bash, Windows):**
```
echo "password=hunter2" | sed -E 's!...' → password=hunter2  (LEAK)
echo "db_password=hunter2" | sed -E 's!...' → db_password=[REDACTED-LOWER-VAR]  (caught)
```

**Root cause:** The roadmap item description "anchor LOWER-VAR with `^|[[:space:]]`" was misinterpreted by commit E as "already applied" — but the anchor fix prevents re-match after redaction, NOT the bare-name miss. The regex structural issue was never fixed.

**Severity:** LOW. The scenario requires an agent to emit a bare `password=value` in `block.reason` or `block.detail` — unusual in practice. Upper-case `PASSWORD=value` is caught by the existing UPPER-VAR pattern (rule 2). The JSON form `{"password": "value"}` IS caught by the JSON-FIELD rule (rule 17). Residual exposure is lower-case bare assignment without prefix. Recommend fix in v6.9.1 or v6.10.0: add explicit alternation `(^|[[:space:]])(password|secret|token|key|pass)=` as a separate rule, or change the regex to `([A-Za-z_][A-Za-z0-9_]*)?([Pp][Aa][Ss][Ss]…)=`.

**Status:** Pre-existing carry-over from cycle-1, mismarked as ALREADY_APPLIED in commit E status.

---

### Scenario 5 (LOW): `pipeline-resumed` webhook fires BEFORE complete agent re-dispatch (atomic window)

**Trigger:** Step 5 of resume-ticket writes state.json (status→running) then immediately fires the webhook. Step 6 re-dispatches the agent. If the operator double-clicks (invokes resume-ticket twice within the ~5-second curl timeout), the second invocation hits Priority 0 check: `status == "paused"` is now FALSE (was set to `running` by first call), so it falls through to Priority 1 (heuristic detection, heuristic resume). The pipeline-resumed event fires only once (from the first call). No duplicate webhook firing. No corruption of clarification state. **Net impact: safe.** The second resume-ticket invocation behaves like a standard resume without the clarification context, which may re-run some pipeline steps. Not a webhook correctness issue but a UX issue.

**Severity:** LOW. Operator double-click during a 5-second window on a manual skill invocation is extremely unlikely.

---

### Scenario 6 (NON-ISSUE): CHANGELOG `core/snippets/webhook-curl.md (cited at 21 sites)` stale count

**Finding:** `CHANGELOG.md:21` for v6.9.0 says "cited at 21 sites" — the actual count is now 31. This is a historical description of the v6.9.0 state at release time (which may have been 21). The count grew through cycle-1 (added 8 pipeline-paused sites → 29) and v6.9.1 commit F (+2 = 31). Historical changelog entries are NOT expected to be updated retrospectively.

**Severity:** NON-ISSUE. CHANGELOG entries are immutable historical records. The `core/snippets/README.md` and the hidden test file (both updated to 31) are the authoritative live counts.

---

## Summary table

| Scenario | Severity | Type | Status |
|----------|----------|------|--------|
| 1: _iso_to_epoch missing python3+gnudate → no auto-abort | MEDIUM | Runtime gap | OPEN (no warning log) |
| 2: parse_pause_timeout UTF-8/no-space inputs | LOW | Graceful fallback | OPEN (acceptable) |
| 3: h-snippet webhook-curl count 29→31 at commit F | MEDIUM | Test accuracy | SELF-HEALED (linter updated to 31; harness 184/184) |
| 4: LOWER-VAR misses bare-name credentials | LOW | Security gap | OPEN (pre-existing, mismarked ALREADY_APPLIED) |
| 5: pipeline-resumed double-click window | LOW | UX edge | ACCEPTABLE |
| 6: CHANGELOG "21 sites" historical description | NON-ISSUE | Historical doc | NON-ISSUE |

---

## Harness result

**184/184 PASS** (run on Git-Bash Windows against working tree). Includes new `tests/scenarios/v6.9.1-pipeline-resumed-webhook.sh` (10 assertions, all PASS). Hidden test `h-snippet-citation-marker-format.sh` PASS (count updated to 31 by linter).

---

## JSON verdict

```json
{
  "dimension": "robustness",
  "score": 0.90,
  "verdict": "PASS",
  "cycle": 0,
  "baseline_score": 0.88,
  "delta": "+0.02",
  "anti_regression_checks": 8,
  "anti_regression_passed": 8,
  "anti_regression_failed": 0,
  "new_scenarios_found": 5,
  "new_critical_findings": 0,
  "new_high_findings": 0,
  "new_medium_findings": 1,
  "new_low_findings": 3,
  "new_non_issues": 1,
  "blocking_for_release": [],
  "fast_follow_v691": [
    "Scenario 1: add [WARN] log when asked_epoch is empty and asked_at is non-empty (BusyBox/no-python3 hosts)",
    "Scenario 4: fix LOWER-VAR regex structural issue to catch bare keyword vars (password=, secret=, token=)",
    "Scenario 3 residual: add comment to hardcoded webhook-curl count in hidden test documenting the update requirement"
  ],
  "harness_result": "184/184 PASS",
  "new_test_scenario": "tests/scenarios/v6.9.1-pipeline-resumed-webhook.sh (10 assertions, PASS)",
  "notes": "v6.9.1 is primarily a docs/polish patch. All 8 v6.9.0 cycle-1 fixes hold. Two new MEDIUM/LOW code-behavior gaps found (no-auto-abort on minimal hosts, bare-name credential leak in sanitize). Neither is a pipeline-break. Score improvement over baseline is conservative (+0.02) because of the mismarked ALREADY_APPLIED item and the test-count drift pattern. Harness 184/184 PASS confirms no regressions."
}
```

DONE
