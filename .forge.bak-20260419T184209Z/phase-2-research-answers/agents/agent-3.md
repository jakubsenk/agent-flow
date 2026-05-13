# Phase 2 Research Answers — Agent 3
# Focus: Item 5 (fixer-reviewer crash-recovery regression test) + Item 6 (exit-code propagation)

---

## Item 5: Fixer-Reviewer Crash-Recovery Regression Test

### Q5.1: Scenario skeleton conventions

**Evidence — three files read:**

**File 1: `tests/scenarios/ac-v68-cost-fixer-reviewer-cumulative.sh` (full)**

```bash
#!/usr/bin/env bash
set -euo pipefail

# AC-17: Fixer-reviewer accumulates cumulatively with no per-iteration array
# Traces: COST-R5
# Description: Verifies SKILL.md and schema.md do NOT document per-iteration breakdown arrays
#              for fixer_reviewer

cd "$(dirname "$0")/../.."

FAIL=0

for file in skills/fix-ticket/SKILL.md state/schema.md; do
  if [ ! -f "$file" ]; then
    continue
  fi
  if grep -nE 'fixer_reviewer.*(iteration_breakdown|per_iteration|iterations_detail)' "$file" | grep -q .; then
    echo "FAIL: AC-17 — $file contains per-iteration array pattern for fixer_reviewer (must be absent)" >&2
    FAIL=1
  fi
done

if [ -f "state/schema.md" ]; then
  if ! grep -qiE 'cumulat|cumulative' "state/schema.md"; then
    echo "FAIL: state/schema.md does not document cumulative accumulation for fixer_reviewer (add in Phase 7)" >&2
    FAIL=1
  fi
fi

[ "$FAIL" -eq 0 ] && echo "PASS: AC-17 — no per-iteration breakdown array for fixer_reviewer"
exit "$FAIL"
```

Citation: `tests/scenarios/ac-v68-cost-fixer-reviewer-cumulative.sh:1-40`

**File 2: `tests/scenarios/ac5-fixer-reviewer-token-constraints.sh` (selected structure)**

```bash
#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

FAIL=0
fail() { echo "FAIL: $1"; FAIL=1; }

FIXER="$REPO_ROOT/agents/fixer.md"
REVIEWER="$REPO_ROOT/agents/reviewer.md"
...
[ "$FAIL" -eq 0 ] && echo "PASS: ..."
exit "$FAIL"
```

Citation: `tests/scenarios/ac5-fixer-reviewer-token-constraints.sh:1-86`

**File 3: `tests/scenarios/v644-diagnostics-hardening.sh` (PATCH-version prefix precedent)**

Line 1: `#!/usr/bin/env bash`
Line 2: `# Test: v6.4.4 Connectivity Diagnostics Hardening — visible tests T1-T12`
Line 3: comment with AC coverage
Line 4: `set -euo pipefail`
Line 6: `REPO_ROOT="$(cd "$(dirname "$0")/../../" && pwd)"`

Citation: `tests/scenarios/v644-diagnostics-hardening.sh:1-12`

**Skeleton conventions extracted (evidence-grounded):**

| Attribute | Convention | Source |
|-----------|------------|--------|
| Shebang | `#!/usr/bin/env bash` | all three files, line 1 |
| set flags | `set -euo pipefail` | all three files (NOT just `set -uo pipefail`) |
| REPO_ROOT | `REPO_ROOT="$(cd "$(dirname "$0")/../../" && pwd)"` OR `cd "$(dirname "$0")/../.."` | both variants used |
| FAIL counter | `FAIL=0` with `fail()` helper OR inline `FAIL=1` | ac-v68 style: `FAIL=0` + `FAIL=1` direct; ac5 style: `fail()` helper |
| Final exit | `exit "$FAIL"` | both fixer-reviewer-related files |
| Filename prefix | `v644-` for PATCH (v6.4.4) | `v644-diagnostics-hardening.sh` |

**No existing `v681-` prefixed file exists.** Confirmed by grep across all `tests/scenarios/*.sh` — zero matches for `v681`.

**Proposed new scenario filename:** `tests/scenarios/v681-fixer-reviewer-crash-recovery.sh`

This follows the PATCH convention (`v644-` → `v681-`): version digits only, no `ac-` prefix (which is used for minor-version AC tests).

---

### Q5.2: What core/fixer-reviewer-loop.md and state/schema.md say about cumulative tokens_used, and the crash-recovery gap

**Evidence — `core/fixer-reviewer-loop.md` (full file, 45 lines):**

The file does NOT contain the words `tokens_used`, `cumulative`, or `per-iteration`. The only state-write instruction for token fields is absent from the process steps. Step 10 (line 28) reads:

> "After each iteration, update state.json: increment `fixer_reviewer.iterations`, set `fixer_reviewer.last_verdict`, update `fixer_reviewer.ac_fulfillment` from reviewer AC Fulfillment section, set `fixer_reviewer.status` to `"in_progress"`. Follow atomic write protocol from `core/state-manager.md`."

Citation: `core/fixer-reviewer-loop.md:28`

**CRITICAL GAP CONFIRMED:** Step 10 does NOT instruct the loop to update `fixer_reviewer.tokens_used`, `fixer_reviewer.duration_ms`, or `fixer_reviewer.tool_uses` after each iteration. It only mentions `iterations`, `last_verdict`, `ac_fulfillment`, and `status`.

**Evidence — `state/schema.md` (Fixer-Reviewer Cumulative Semantics section, line 344):**

> "`fixer_reviewer.tokens_used`, `fixer_reviewer.duration_ms`, and `fixer_reviewer.tool_uses` are **cumulative across all iterations**, not per-iteration snapshots. After iteration N completes, these fields hold the running sum of all N iterations combined (e.g., after 3 iterations: `tokens_used = iter1 + iter2 + iter3`). No per-iteration breakdown array is stored in state.json — that granularity is available in `pipeline.log` via `fixer_iteration` events."

Citation: `state/schema.md:344`

**Evidence — `core/state-manager.md` (Fixer-Reviewer Cumulative Write section, lines 138–148):**

Lines 138–148 read:
```
The `fixer_reviewer` stage accumulates token counts cumulatively across iterations (COST-R5). After each fixer or reviewer invocation within the loop:
  fixer_reviewer.tokens_used  += iteration_tokens_used   (running total)
  fixer_reviewer.duration_ms  += iteration_duration_ms
  fixer_reviewer.tool_uses    += iteration_tool_uses
No per-iteration breakdown array is persisted.
```

Citation: `core/state-manager.md:138-148`

**Evidence — Atomic Write on Failure (`state/schema.md` lines 465–466):**

> "On rename failure: retry once after 100 ms. On second failure: log to `pipeline.log` and continue (state loss is non-fatal)."

Citation: `state/schema.md:465-466` (Atomic Write Protocol section)

**Gap analysis:**

1. `core/fixer-reviewer-loop.md` Step 10 does NOT include `tokens_used += iteration_tokens` instruction.
2. `core/fixer-reviewer-loop.md` Step 10 does NOT specify that the atomic write at iteration N preserves cumulative totals so that crash at iteration N+1 does not lose them.
3. The fix must add text to `core/fixer-reviewer-loop.md` Step 10 AND add a test that greps for the newly added text.

**Draft fix for `core/fixer-reviewer-loop.md` Step 10 (verbatim text to replace the current line 28):**

```markdown
10. After each iteration, update state.json atomically (see `core/state-manager.md` atomic write protocol): increment `fixer_reviewer.iterations`, set `fixer_reviewer.last_verdict`, update `fixer_reviewer.ac_fulfillment` from reviewer AC Fulfillment section, set `fixer_reviewer.status` to `"in_progress"`, and accumulate usage fields: `fixer_reviewer.tokens_used += iteration_tokens_used`, `fixer_reviewer.duration_ms += iteration_duration_ms`, `fixer_reviewer.tool_uses += iteration_tool_uses`. These cumulative writes ensure that if the pipeline crashes mid-loop, the state.json reflects the token cost of all completed iterations and can be used for cost reporting on resume.
```

---

### Q5.3: Grep assertions for the new crash-recovery scenario

**What `ac-v68-cost-fixer-reviewer-cumulative.sh` asserts (template):**
- Negative: no per-iteration array language in `skills/fix-ticket/SKILL.md` or `state/schema.md`
- Positive: `state/schema.md` contains `cumulat` / `cumulative`

**For the crash-recovery scenario, the greppable strings that must be present after the fix:**

In `core/fixer-reviewer-loop.md`:
- `tokens_used.*iteration` (the new += accumulation instruction)
- `cumulative.*crash\|crash.*cumulative` OR simply `crash` (the crash-recovery sentence)
- `atomic write` (already present at line 28 via "atomic write protocol")

In `state/schema.md`:
- `cumulative` — already present at line 344; passes today

In `core/state-manager.md`:
- `cumulatively across iterations` — already present at line 140; passes today

---

### Q5.4: Draft new scenario — `tests/scenarios/v681-fixer-reviewer-crash-recovery.sh`

```bash
#!/usr/bin/env bash
# Test: v6.8.1 Fixer-reviewer crash-recovery — cumulative tokens_used written per iteration
# Validates: core/fixer-reviewer-loop.md Step 10 documents tokens_used accumulation per-iteration
#            and that crash-mid-loop preserves completed-iteration cost data
# Traces: COST-R5 (cumulative), state-manager atomic write protocol
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../" && pwd)"

LOOP_CONTRACT="$REPO_ROOT/core/fixer-reviewer-loop.md"
STATE_MANAGER="$REPO_ROOT/core/state-manager.md"
SCHEMA="$REPO_ROOT/state/schema.md"

FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

# Guard: required files exist
for f in "$LOOP_CONTRACT" "$STATE_MANAGER" "$SCHEMA"; do
  if [ ! -f "$f" ]; then
    echo "FAIL: required file not found: $f"
    exit 1
  fi
done

# --- Assertion 1: core/fixer-reviewer-loop.md Step 10 documents tokens_used accumulation ---
# After the fix, Step 10 must instruct the loop to accumulate tokens_used per iteration.
if ! grep -qE 'tokens_used.*iteration|iteration.*tokens_used' "$LOOP_CONTRACT"; then
  fail "core/fixer-reviewer-loop.md Step 10 does not document per-iteration tokens_used accumulation (+=)"
fi

# --- Assertion 2: core/fixer-reviewer-loop.md mentions crash-recovery semantics ---
# The fix adds a sentence about partial crash preserving completed-iteration cost data.
if ! grep -qiE 'crash|partial.*failure.*preserv|preserv.*partial' "$LOOP_CONTRACT"; then
  fail "core/fixer-reviewer-loop.md does not document crash-recovery semantics for cumulative tokens_used"
fi

# --- Assertion 3: state/schema.md already documents cumulative semantics ---
if ! grep -qiE 'cumulative|cumulat' "$SCHEMA"; then
  fail "state/schema.md does not document cumulative accumulation for fixer_reviewer (must be present)"
fi

# --- Assertion 4: core/state-manager.md already documents cumulative += write ---
if ! grep -qE 'tokens_used.*running total|cumulatively across iterations' "$STATE_MANAGER"; then
  fail "core/state-manager.md does not document cumulative running-total write for fixer_reviewer"
fi

# --- Negative: no per-iteration breakdown array in loop contract or schema ---
for file in "$LOOP_CONTRACT" "$SCHEMA"; do
  if grep -qE 'iteration_breakdown|per_iteration|iterations_detail' "$file"; then
    fail "$(basename "$file") contains per-iteration breakdown array language (must be absent)"
  fi
done

[ "$FAIL" -eq 0 ] && echo "PASS: v6.8.1 fixer-reviewer crash-recovery — cumulative tokens_used documented per-iteration with crash-recovery semantics"
exit "$FAIL"
```

---

## Item 6: Test Harness Exit-Code Propagation

### Q6.1: Full harness trace — `tests/harness/run-tests.sh` (69 lines)

**File read verbatim, lines 1–69:**

```bash
#!/bin/bash
# Run all test scenarios for ceos-agents
# Usage: ./tests/harness/run-tests.sh [scenario-name]

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SCENARIOS_DIR="$SCRIPT_DIR/../scenarios"
PASS=0
FAIL=0
SKIP=0
RESULTS=()

echo "=== ceos-agents Test Harness ==="
echo ""

# If specific scenario provided, run only that
if [ -n "${1:-}" ]; then
  scenario="$SCENARIOS_DIR/$1.sh"
  if [ ! -f "$scenario" ]; then
    echo "ERROR: Scenario '$1' not found at $scenario"
    exit 1
  fi
  echo "Running: $1..."
  if bash "$scenario"; then
    echo "PASS: $1"
    exit 0
  else
    echo "FAIL: $1"
    exit 1
  fi
fi

# Run all scenarios
for scenario in "$SCENARIOS_DIR"/*.sh; do
  name=$(basename "$scenario" .sh)
  echo -n "Running: $name... "

  if bash "$scenario" > /dev/null 2>&1; then
    echo "PASS"
    RESULTS+=("PASS: $name")
    ((PASS++))
  else
    exit_code=$?
    if [ $exit_code -eq 77 ]; then
      echo "SKIP"
      RESULTS+=("SKIP: $name")
      ((SKIP++))
    else
      echo "FAIL"
      RESULTS+=("FAIL: $name")
      ((FAIL++))
    fi
  fi
done

# Summary
echo ""
echo "=== Test Results ==="
for result in "${RESULTS[@]}"; do
  echo "  $result"
done
echo ""
echo "Total: $((PASS + FAIL + SKIP)) | Pass: $PASS | Fail: $FAIL | Skip: $SKIP"

if [ $FAIL -gt 0 ]; then
  exit 1
fi
```

Citation: `tests/harness/run-tests.sh:1-69`

---

### Q6.2: Exit-code analysis

**`set` flags (line 5):** `set -uo pipefail` — NO `-e` flag.

**PASS/FAIL/SKIP counting:**
- Line 42: `((PASS++))` — inside `if bash "$scenario"` branch (scenario passed)
- Line 48: `((SKIP++))` — inside `elif exit_code -eq 77` branch
- Line 52: `((FAIL++))` — inside `else` branch (scenario failed)

**`((FAIL++))` arithmetic exit-code behavior (empirically verified):**
- When `FAIL=0`, `((FAIL++))` post-increments (expression value = 0 = false) → returns exit code 1 from the arithmetic expression.
- Under `set -uo pipefail` (no `-e`): this exit code 1 does NOT abort the script. The script continues.
- When `FAIL=1`, `((FAIL++))` expression value = 1 = truthy → returns exit code 0. No problem.
- Same pattern for `((PASS++))` when PASS=0.

**Empirically confirmed:** Running `bash -c 'set -uo pipefail; FAIL=0; ((FAIL++)); echo "Script continues? FAIL=$FAIL"'` outputs `Script continues? FAIL=1` with exit code 0. The script does NOT abort.

**Final exit path (lines 66–68):**

```bash
if [ $FAIL -gt 0 ]; then
  exit 1
fi
```

This IS reached and DOES exit 1 when `FAIL > 0`. The script falls off the end (implicit exit 0) only when FAIL=0.

**Conclusion — is the harness correct?**

The full-run exit-code path IS functionally correct: when any scenario fails, `FAIL` is incremented, and lines 66-68 correctly exit 1. The harness does propagate failures properly under `set -uo pipefail` (no `-e`).

**HOWEVER — there is a latent robustness risk** that the roadmap is correct to flag: `((FAIL++))` when FAIL=0 emits exit code 1 from the arithmetic expression. Under strict CI wrappers that call `bash -e run-tests.sh` or wrap the harness in `set -e`, the first `((FAIL++))` call (when FAIL transitions from 0 to 1) would cause premature script abort — skipping the summary output and the proper `exit 1` at line 67. The harness would exit with code 1 from the arithmetic expression rather than from line 67, which is functionally correct but produces no summary.

**Additionally:** `((PASS++))`, `((SKIP++))` have the same pattern — `((PASS++))` when PASS=0 also returns exit 1 from the expression. Under strict `-e` wrappers, even a first passing scenario could abort the harness early.

**The fix — canonical safe approach:**

Replace all three arithmetic post-increment expressions with POSIX-safe equivalents that never return nonzero:

```bash
# Current (line 42):
((PASS++))
# Fix:
PASS=$((PASS + 1))

# Current (line 48):
((SKIP++))
# Fix:
SKIP=$((SKIP + 1))

# Current (line 52):
((FAIL++))
# Fix:
FAIL=$((FAIL + 1))
```

`$((PASS + 1))` always evaluates to a non-negative integer; the assignment command returns exit 0 regardless of the arithmetic value. This eliminates the exit-code ambiguity completely.

**Alternative single-line fix (more conservative):** Change only line 52 (the FAIL increment) since that is the critical path:

```bash
FAIL=$((FAIL + 1))
```

**Recommended: fix all three** for consistency and to guard against the `((PASS++))` edge case under strict wrappers.

---

### Q6.3: CI integration — is there a test for the harness itself?

**Evidence:**
- `.gitea/workflows/` — no files exist (Glob returned no results). Confirms project memory: "CI runner not configured, all jobs cancelled at 0s."
- `tests/scenarios/test-fail.sh` — exists but is a test for the test-engineer agent, not for harness exit-code behavior (content: checks `agents/test-engineer.md` has constraints). Uses `set -e`, not harness meta-test.
- `tests/scenarios/verify-fail.sh` — exists but tests Fix Verification step presence in SKILL.md files. Not a harness meta-test.
- No scenario file tests `run-tests.sh` exit-code behavior itself.

**Conclusion:** No existing meta-test. A new scenario is needed.

---

### Q6.4: Draft meta-test scenario — `tests/scenarios/ac-v681-harness-exit-propagation.sh`

Note: Uses `ac-v681-` prefix (not `v681-`) because this is an acceptance-criteria test for the v6.8.1 fix, not a named PATCH hardening scenario. Either prefix is defensible but `ac-v681-` is consistent with the v6.8.0 AC test convention (`ac-v68-*`).

```bash
#!/usr/bin/env bash
# Test: v6.8.1 — Harness exit-code propagation
# Validates: run-tests.sh exits nonzero when at least one scenario fails
# Also validates: PASS/FAIL/SKIP increments use $((N + 1)) form (safe under set -e wrappers)
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../" && pwd)"
HARNESS="$REPO_ROOT/tests/harness/run-tests.sh"

FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

# Guard
if [ ! -f "$HARNESS" ]; then
  echo "FAIL: run-tests.sh not found at $HARNESS"
  exit 1
fi

# --- Assertion 1: FAIL increment uses safe $((FAIL + 1)) form ---
if grep -qE '\(\(FAIL\+\+\)\)' "$HARNESS"; then
  fail "run-tests.sh still uses ((FAIL++)) — replace with FAIL=\$((FAIL + 1)) to avoid exit-code 1 leak under set -e wrappers"
fi

# --- Assertion 2: PASS increment uses safe form ---
if grep -qE '\(\(PASS\+\+\)\)' "$HARNESS"; then
  fail "run-tests.sh still uses ((PASS++)) — replace with PASS=\$((PASS + 1)) to avoid exit-code 1 leak under set -e wrappers"
fi

# --- Assertion 3: SKIP increment uses safe form ---
if grep -qE '\(\(SKIP\+\+\)\)' "$HARNESS"; then
  fail "run-tests.sh still uses ((SKIP++)) — replace with SKIP=\$((SKIP + 1)) to avoid exit-code 1 leak under set -e wrappers"
fi

# --- Assertion 4: Functional exit-1 path — harness exits nonzero when a scenario fails ---
# Create a temporary failing scenario
TMPDIR_SCENARIO=$(mktemp -d)
FAIL_SCENARIO="$TMPDIR_SCENARIO/always-fail.sh"
cat > "$FAIL_SCENARIO" <<'EOF'
#!/usr/bin/env bash
echo "FAIL: intentional failure for harness meta-test" >&2
exit 1
EOF
chmod +x "$FAIL_SCENARIO"

# Point SCENARIOS_DIR at the temp dir and run the harness
SCENARIOS_DIR="$TMPDIR_SCENARIO" bash "$HARNESS" > /dev/null 2>&1
harness_exit=$?

rm -rf "$TMPDIR_SCENARIO"

if [ "$harness_exit" -eq 0 ]; then
  fail "run-tests.sh exited 0 even though a scenario failed (exit-code propagation broken)"
else
  echo "OK: harness correctly exited $harness_exit when a scenario failed"
fi

[ "$FAIL" -eq 0 ] && echo "PASS: v6.8.1 harness exit-code propagation — safe increments and nonzero exit on failure"
exit "$FAIL"
```

**Note on Assertion 4:** The harness reads `SCENARIOS_DIR` from a computed path (`$SCRIPT_DIR/../scenarios`), not an environment variable — it cannot be easily overridden by env. The functional test above would need the harness to support `SCENARIOS_DIR` override, OR the test should call `bash "$HARNESS"` with a known-failing scenario name using the single-scenario mode (`bash run-tests.sh <name>` which exits 0 or 1 per single scenario). The simpler approach:

```bash
# Functional test using single-scenario mode (no SCENARIOS_DIR override needed)
# Create a temp scenario in the actual scenarios dir, run it, remove it
TMPNAME="v681-meta-test-always-fail-$$"
TMPSCEN="$REPO_ROOT/tests/scenarios/$TMPNAME.sh"
printf '#!/usr/bin/env bash\nexit 1\n' > "$TMPSCEN"
chmod +x "$TMPSCEN"

bash "$HARNESS" "$TMPNAME" > /dev/null 2>&1
harness_exit=$?
rm -f "$TMPSCEN"

if [ "$harness_exit" -eq 0 ]; then
  fail "run-tests.sh single-scenario mode exited 0 for a failing scenario"
else
  echo "OK: single-scenario mode correctly exits nonzero on failure"
fi
```

---

## Summary (≤200 words)

**Item 5 (crash-recovery regression test):**

The scenario skeleton uses `#!/usr/bin/env bash`, `set -euo pipefail`, `REPO_ROOT="$(cd "$(dirname "$0")/../../" && pwd)"`, `FAIL=0`/`fail()` helper, and `exit "$FAIL"`. The PATCH-version prefix is `v681-` (following `v644-diagnostics-hardening.sh`). The critical gap is confirmed: `core/fixer-reviewer-loop.md` Step 10 (line 28) does NOT mention `tokens_used` accumulation — only `iterations`, `last_verdict`, `ac_fulfillment`, and `status` are listed. The cumulative semantics exist in `state/schema.md:344` and `core/state-manager.md:138-148` but not in the loop contract itself. The fix adds tokens accumulation and crash-recovery language to Step 10, and the new scenario (`v681-fixer-reviewer-crash-recovery.sh`) greps for the newly added text.

**Item 6 (exit-code propagation):**

`run-tests.sh:5` uses `set -uo pipefail` (no `-e`). Lines 66-68 correctly exit 1 when FAIL > 0 — the harness is functionally correct under `bash run-tests.sh`. The latent risk: `((FAIL++))` when FAIL=0 returns exit 1 from the arithmetic expression; under strict CI `-e` wrappers, this causes premature abort before the summary. Fix: replace `((PASS++))`, `((SKIP++))`, `((FAIL++))` (lines 42, 48, 52) with `PASS=$((PASS + 1))`, `SKIP=$((SKIP + 1))`, `FAIL=$((FAIL + 1))` respectively. No CI runner is configured (`.gitea/workflows/` is empty). Neither `test-fail.sh` nor `verify-fail.sh` is a harness meta-test. A new `ac-v681-harness-exit-propagation.sh` scenario using single-scenario-mode invocation is the correct meta-test approach.
