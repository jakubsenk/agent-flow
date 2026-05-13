#!/usr/bin/env bash
# Test: v6.8.1 — Harness exit-code propagation
# Validates: run-tests.sh uses $((N + 1)) form for PASS/FAIL/SKIP increments
#            (safe under bash -e wrappers; ((N++)) returns exit 1 when N=0)
# Functional: single-scenario mode exits nonzero on failure
# Traces: AC-ITEM-6.1a, AC-ITEM-6.1b, AC-ITEM-6.2, AC-ITEM-6.4a
# Covers: R-ITEM-6.1 through R-ITEM-6.4
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../" && pwd)"
HARNESS="$REPO_ROOT/tests/harness/run-tests.sh"

FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

# Guard: harness file must exist
if [ ! -f "$HARNESS" ]; then
  echo "FAIL: run-tests.sh not found at $HARNESS"
  exit 1
fi

# ---------------------------------------------------------------------------
# Assertion 1 (AC-ITEM-6.1a positive + AC-ITEM-6.1b negative): FAIL counter
#   MUST use FAIL=$((FAIL + 1)) form
#   MUST NOT use ((FAIL++)) form
# ---------------------------------------------------------------------------
echo "--- Assertion 1 (AC-ITEM-6.1a/b): FAIL counter safe form ---"
if grep -qE '\(\(FAIL\+\+\)\)' "$HARNESS"; then
  fail "AC-ITEM-6.1b: run-tests.sh still contains ((FAIL++)) — replace with FAIL=\$((FAIL + 1)) to avoid exit-code 1 leak under bash -e wrappers"
else
  echo "OK (AC-ITEM-6.1b): ((FAIL++)) is absent from run-tests.sh"
fi
if grep -qE 'FAIL=\$\(\(FAIL \+ 1\)\)' "$HARNESS"; then
  echo "OK (AC-ITEM-6.1a): FAIL=\$((FAIL + 1)) safe counter form present in run-tests.sh"
else
  fail "AC-ITEM-6.1a: run-tests.sh does not contain FAIL=\$((FAIL + 1)) — safe counter form missing"
fi

# ---------------------------------------------------------------------------
# Assertion 2 (AC-ITEM-6.1a positive + AC-ITEM-6.1b negative): PASS counter
# ---------------------------------------------------------------------------
echo "--- Assertion 2 (AC-ITEM-6.1a/b): PASS counter safe form ---"
if grep -qE '\(\(PASS\+\+\)\)' "$HARNESS"; then
  fail "AC-ITEM-6.1b: run-tests.sh still contains ((PASS++)) — replace with PASS=\$((PASS + 1))"
else
  echo "OK (AC-ITEM-6.1b): ((PASS++)) is absent from run-tests.sh"
fi
if grep -qE 'PASS=\$\(\(PASS \+ 1\)\)' "$HARNESS"; then
  echo "OK (AC-ITEM-6.1a): PASS=\$((PASS + 1)) safe counter form present in run-tests.sh"
else
  fail "AC-ITEM-6.1a: run-tests.sh does not contain PASS=\$((PASS + 1)) — safe counter form missing"
fi

# ---------------------------------------------------------------------------
# Assertion 3 (AC-ITEM-6.1a positive + AC-ITEM-6.1b negative): SKIP counter
# ---------------------------------------------------------------------------
echo "--- Assertion 3 (AC-ITEM-6.1a/b): SKIP counter safe form ---"
if grep -qE '\(\(SKIP\+\+\)\)' "$HARNESS"; then
  fail "AC-ITEM-6.1b: run-tests.sh still contains ((SKIP++)) — replace with SKIP=\$((SKIP + 1))"
else
  echo "OK (AC-ITEM-6.1b): ((SKIP++)) is absent from run-tests.sh"
fi
if grep -qE 'SKIP=\$\(\(SKIP \+ 1\)\)' "$HARNESS"; then
  echo "OK (AC-ITEM-6.1a): SKIP=\$((SKIP + 1)) safe counter form present in run-tests.sh"
else
  fail "AC-ITEM-6.1a: run-tests.sh does not contain SKIP=\$((SKIP + 1)) — safe counter form missing"
fi

# ---------------------------------------------------------------------------
# Assertion 4 (AC-ITEM-6.2): Functional — single-scenario mode exits nonzero on failure
#
# Write a temporary always-fail scenario to tests/scenarios/, run the harness
# against it in single-scenario mode, assert nonzero exit, then clean up.
# The PID suffix prevents collision with any existing scenario.
# Note: single-scenario mode (harness lines 25-31) was correct pre-fix; this is
# a regression guard confirming the N=$((N+1)) refactor did not break that path.
# ---------------------------------------------------------------------------
echo "--- Assertion 4 (AC-ITEM-6.2): functional single-scenario exit-code propagation ---"
TMPNAME="v681-meta-test-always-fail-$$"
TMPSCEN="$REPO_ROOT/tests/scenarios/$TMPNAME.sh"
printf '#!/usr/bin/env bash\nexit 1\n' > "$TMPSCEN"
chmod +x "$TMPSCEN"

# Run harness against failing scenario; capture exit code WITHOUT aborting this script
bash "$HARNESS" "$TMPNAME" > /dev/null 2>&1 && harness_exit=0 || harness_exit=$?
rm -f "$TMPSCEN"

if [ "$harness_exit" -eq 0 ]; then
  fail "AC-ITEM-6.2: run-tests.sh single-scenario mode exited 0 for a failing scenario (exit-code propagation broken)"
else
  echo "OK (AC-ITEM-6.2): single-scenario mode correctly exited $harness_exit (nonzero) for a failing scenario"
fi

# ---------------------------------------------------------------------------
# Final result
# ---------------------------------------------------------------------------
if [ "$FAIL" -eq 0 ]; then
  echo "PASS: v6.8.1 harness exit-code propagation — safe increments and nonzero exit on failure"
fi
exit "$FAIL"
