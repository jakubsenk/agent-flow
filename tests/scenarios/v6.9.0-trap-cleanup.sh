#!/usr/bin/env bash
# Scenario: REQ-023 — trap line in v681-harness-exit-propagation.sh to clean TMPSCEN on EXIT/INT/TERM
# Expected v6.9.0 outcome: PASS once Phase 7 implements
# Pre-implementation outcome: FAIL (TDD) — trap line not yet added
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../" && pwd)"

FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

TARGET="$REPO_ROOT/tests/scenarios/v681-harness-exit-propagation.sh"

if [ ! -f "$TARGET" ]; then
  echo "FAIL: v681-harness-exit-propagation.sh not found at $TARGET" >&2
  exit 1
fi

# Assertion 1 (AC-023): trap line present with EXIT INT TERM signals and removes TMPSCEN
echo "--- Assertion 1 (AC-023): trap 'rm -f \"\$TMPSCEN\"' EXIT INT TERM present ---"
if grep -qF "trap 'rm -f \"\$TMPSCEN\"' EXIT INT TERM" "$TARGET"; then
  echo "OK (AC-023): trap cleanup line present in v681-harness-exit-propagation.sh"
else
  fail "AC-023: v681-harness-exit-propagation.sh missing trap line 'trap '\"'\"'rm -f \"\$TMPSCEN\"'\"'\"' EXIT INT TERM' — SIGTERM-killed CI jobs will leak temp file"
fi

# Assertion 2 (AC-023): trap is near the TMPSCEN declaration (within 5 lines after it)
echo "--- Assertion 2 (AC-023): trap is adjacent to TMPSCEN declaration ---"
tmpscen_line=$(grep -n 'TMPSCEN=' "$TARGET" | head -1 | cut -d: -f1)
trap_line=$(grep -n "trap 'rm -f" "$TARGET" | head -1 | cut -d: -f1)
if [ -z "$tmpscen_line" ]; then
  fail "AC-023: TMPSCEN= declaration not found in $TARGET"
elif [ -z "$trap_line" ]; then
  fail "AC-023: trap line not found (already caught above)"
else
  delta=$((trap_line - tmpscen_line))
  if [ "$delta" -ge 0 ] && [ "$delta" -le 5 ]; then
    echo "OK (AC-023): trap line is $delta lines after TMPSCEN declaration (within 5 lines)"
  else
    fail "AC-023: trap line (line $trap_line) is $delta lines after TMPSCEN declaration (line $tmpscen_line) — should be immediately adjacent (within 5 lines)"
  fi
fi

if [ "$FAIL" -eq 0 ]; then
  echo "PASS: v6.9.0 trap cleanup line present in v681-harness-exit-propagation.sh adjacent to TMPSCEN"
fi
exit "$FAIL"
