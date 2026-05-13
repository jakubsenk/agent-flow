#!/usr/bin/env bash
# Test: v6.8.1 Fixer-reviewer crash-recovery — cumulative tokens_used written per iteration
# Validates: core/fixer-reviewer-loop.md Step 10 documents tokens_used accumulation per-iteration
#            and that crash-mid-loop preserves completed-iteration cost data
# Traces: AC-ITEM-5.1a, AC-ITEM-5.1b, AC-ITEM-5.2, AC-ITEM-5.3, AC-ITEM-5.4
# Covers: R-ITEM-5.1 through R-ITEM-5.4
set -uo pipefail

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

# ---------------------------------------------------------------------------
# Assertion 1 (AC-ITEM-5.1a): core/fixer-reviewer-loop.md Step 10 documents
#   per-iteration tokens_used accumulation (the "+=" expression form)
# ---------------------------------------------------------------------------
echo "--- Assertion 1 (AC-ITEM-5.1a): tokens_used accumulation in loop contract ---"
if grep -qE 'tokens_used.*iteration|iteration.*tokens_used' "$LOOP_CONTRACT"; then
  echo "OK (AC-ITEM-5.1a): tokens_used per-iteration accumulation present in $LOOP_CONTRACT"
else
  fail "AC-ITEM-5.1a: core/fixer-reviewer-loop.md Step 10 does not document per-iteration tokens_used accumulation (expected tokens_used += iteration_tokens_used or similar)"
fi

# Also check duration_ms and tool_uses accumulation (per R-ITEM-5.1 all three fields)
if grep -qE 'duration_ms.*iteration|iteration.*duration_ms' "$LOOP_CONTRACT"; then
  echo "OK (AC-ITEM-5.1a): duration_ms per-iteration accumulation present"
else
  fail "AC-ITEM-5.1a: core/fixer-reviewer-loop.md Step 10 missing duration_ms += iteration accumulation"
fi

if grep -qE 'tool_uses.*iteration|iteration.*tool_uses' "$LOOP_CONTRACT"; then
  echo "OK (AC-ITEM-5.1a): tool_uses per-iteration accumulation present"
else
  fail "AC-ITEM-5.1a: core/fixer-reviewer-loop.md Step 10 missing tool_uses += iteration accumulation"
fi

# ---------------------------------------------------------------------------
# Assertion 2 (AC-ITEM-5.1b): crash-recovery semantics sentence
# ---------------------------------------------------------------------------
echo "--- Assertion 2 (AC-ITEM-5.1b): crash-recovery semantics in loop contract ---"
if grep -qiE 'crash.*mid.loop|crashes.mid.loop|preserves.*completed.iteration|preserv.*partial' "$LOOP_CONTRACT"; then
  echo "OK (AC-ITEM-5.1b): crash-recovery semantics sentence present in core/fixer-reviewer-loop.md"
else
  fail "AC-ITEM-5.1b: core/fixer-reviewer-loop.md does not document crash-recovery semantics (expected: 'crashes mid-loop' or 'preserves completed-iteration cost' or similar)"
fi

# ---------------------------------------------------------------------------
# Assertion 3 (AC-ITEM-5.3 partial): state/schema.md documents cumulative semantics
# ---------------------------------------------------------------------------
echo "--- Assertion 3 (state/schema.md cumulative semantics) ---"
if grep -qiE 'cumulative|cumulat' "$SCHEMA"; then
  echo "OK: state/schema.md documents cumulative accumulation for fixer_reviewer"
else
  fail "state/schema.md does not document cumulative accumulation (AC-ITEM-5.3 regression guard)"
fi

# ---------------------------------------------------------------------------
# Assertion 4 (AC-ITEM-5.3 partial): core/state-manager.md running-total write rule
# ---------------------------------------------------------------------------
echo "--- Assertion 4 (core/state-manager.md running-total write) ---"
if grep -qE 'tokens_used.*running total|cumulatively across iterations' "$STATE_MANAGER"; then
  echo "OK: core/state-manager.md documents cumulative running-total write for fixer_reviewer"
else
  fail "core/state-manager.md does not document cumulative += running-total write for fixer_reviewer (expected 'running total' or 'cumulatively across iterations')"
fi

# ---------------------------------------------------------------------------
# Negative assertion: no per-iteration breakdown array stored (regression guard)
# ---------------------------------------------------------------------------
echo "--- Negative: no per-iteration breakdown array in loop contract or schema ---"
for file in "$LOOP_CONTRACT" "$SCHEMA"; do
  if grep -qE 'iteration_breakdown|per_iteration|iterations_detail' "$file"; then
    fail "$(basename "$file") contains per-iteration breakdown array language (must be absent — cumulative only, no breakdown array)"
  else
    echo "OK (negative): $(basename "$file") — no per-iteration breakdown array language"
  fi
done

# ---------------------------------------------------------------------------
# Final result
# ---------------------------------------------------------------------------
if [ "$FAIL" -eq 0 ]; then
  echo "PASS: v6.8.1 fixer-reviewer crash-recovery — cumulative tokens_used documented per-iteration with crash-recovery semantics"
fi
exit "$FAIL"
