#!/usr/bin/env bash
# Hidden test: AC-ITEM-5.1a, AC-ITEM-5.1b, AC-ITEM-5.3 (partial)
# Verifies core/fixer-reviewer-loop.md Step 10 contains:
#   - All three += accumulation expressions (tokens_used, duration_ms, tool_uses)
#   - Crash-recovery semantics sentence
#   - Cross-check: state/schema.md cumulative docs still present (regression guard)
#   - Cross-check: core/state-manager.md running-total write docs present (regression guard)
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../" && pwd)"
LOOP_CONTRACT="$REPO_ROOT/core/fixer-reviewer-loop.md"
STATE_MANAGER="$REPO_ROOT/core/state-manager.md"
SCHEMA="$REPO_ROOT/state/schema.md"

FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

echo "--- h-fixer-reviewer-loop-step-10 (AC-ITEM-5.1a, 5.1b, 5.3): loop contract ---"

for f in "$LOOP_CONTRACT" "$STATE_MANAGER" "$SCHEMA"; do
  if [ ! -f "$f" ]; then
    echo "FAIL: required file not found: $f"
    exit 1
  fi
done

# -----------------------------------------------------------------------
# AC-ITEM-5.1a: All three += accumulation expressions present in Step 10
# -----------------------------------------------------------------------
echo "--- AC-ITEM-5.1a: tokens_used += iteration_tokens_used ---"
if grep -qE 'tokens_used \+= iteration_tokens_used|tokens_used.*\+=.*iteration' "$LOOP_CONTRACT"; then
  echo "OK (AC-ITEM-5.1a): tokens_used accumulation expression present"
else
  fail "AC-ITEM-5.1a: tokens_used += iteration_tokens_used missing from core/fixer-reviewer-loop.md Step 10"
fi

echo "--- AC-ITEM-5.1a: duration_ms += iteration_duration_ms ---"
if grep -qE 'duration_ms \+= iteration_duration_ms|duration_ms.*\+=.*iteration' "$LOOP_CONTRACT"; then
  echo "OK (AC-ITEM-5.1a): duration_ms accumulation expression present"
else
  fail "AC-ITEM-5.1a: duration_ms += iteration_duration_ms missing from core/fixer-reviewer-loop.md Step 10"
fi

echo "--- AC-ITEM-5.1a: tool_uses += iteration_tool_uses ---"
if grep -qE 'tool_uses \+= iteration_tool_uses|tool_uses.*\+=.*iteration' "$LOOP_CONTRACT"; then
  echo "OK (AC-ITEM-5.1a): tool_uses accumulation expression present"
else
  fail "AC-ITEM-5.1a: tool_uses += iteration_tool_uses missing from core/fixer-reviewer-loop.md Step 10"
fi

# -----------------------------------------------------------------------
# AC-ITEM-5.1b: Crash-recovery semantics sentence present
# -----------------------------------------------------------------------
echo "--- AC-ITEM-5.1b: crash-recovery semantics sentence ---"
if grep -qiE 'crashes mid.loop|crash.*mid.loop|preserves.*completed.iteration' "$LOOP_CONTRACT"; then
  echo "OK (AC-ITEM-5.1b): crash-recovery semantics sentence present in core/fixer-reviewer-loop.md"
else
  fail "AC-ITEM-5.1b: crash-recovery semantics sentence missing from core/fixer-reviewer-loop.md Step 10 (expected 'crashes mid-loop' or 'preserves completed-iteration')"
fi

# -----------------------------------------------------------------------
# AC-ITEM-5.3 partial: state/schema.md cumulative docs (regression guard)
# -----------------------------------------------------------------------
echo "--- AC-ITEM-5.3 regression: state/schema.md cumulative semantics ---"
if grep -qiE 'cumulative|cumulat' "$SCHEMA"; then
  echo "OK: state/schema.md cumulative semantics present (regression guard)"
else
  fail "AC-ITEM-5.3 regression: state/schema.md does not document cumulative semantics (must not have been accidentally removed)"
fi

# -----------------------------------------------------------------------
# AC-ITEM-5.3 partial: core/state-manager.md running-total write rule
# -----------------------------------------------------------------------
echo "--- AC-ITEM-5.3 regression: core/state-manager.md running-total write ---"
if grep -qE 'tokens_used.*running total|cumulatively across iterations' "$STATE_MANAGER"; then
  echo "OK: core/state-manager.md running-total write rule present (regression guard)"
else
  fail "AC-ITEM-5.3 regression: core/state-manager.md does not document running-total write for fixer_reviewer"
fi

# -----------------------------------------------------------------------
# Negative regression: no per-iteration breakdown array
# -----------------------------------------------------------------------
echo "--- Negative regression: no per-iteration breakdown array ---"
for f in "$LOOP_CONTRACT" "$SCHEMA"; do
  if grep -qE 'iteration_breakdown|per_iteration|iterations_detail' "$f"; then
    fail "Regression: $(basename "$f") contains per-iteration breakdown array language (must remain absent)"
  else
    echo "OK: no per-iteration breakdown array in $(basename "$f")"
  fi
done

# -----------------------------------------------------------------------
# Final result
# -----------------------------------------------------------------------
if [ "$FAIL" -eq 0 ]; then
  echo "PASS: h-fixer-reviewer-loop-step-10 — Step 10 accumulation (3 fields) + crash-recovery semantics + regression guards"
fi
exit "$FAIL"
