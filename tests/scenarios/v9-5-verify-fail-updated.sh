#!/bin/bash
# Covers: AC-36 (verify-fail.sh no longer references fix-ticket, does reference fix-bugs and implement-feature)
set -e

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

FILE="$REPO_ROOT/tests/scenarios/verify-fail.sh"

if [ ! -f "$FILE" ]; then
  echo "FAIL: v9-5-verify-fail-updated — tests/scenarios/verify-fail.sh not found"
  exit 1
fi

FAIL=0
fail() { echo "FAIL: v9-5-verify-fail-updated — $1"; FAIL=1; }

if grep -qF 'fix-ticket' "$FILE"; then
  fail "verify-fail.sh still references 'fix-ticket' (deleted skill)"
else
  echo "PASS: 'fix-ticket' absent from verify-fail.sh"
fi

if grep -qF 'fix-bugs' "$FILE"; then
  echo "PASS: 'fix-bugs' referenced in verify-fail.sh"
else
  fail "verify-fail.sh does not reference 'fix-bugs'"
fi

if grep -qF 'implement-feature' "$FILE"; then
  echo "PASS: 'implement-feature' referenced in verify-fail.sh"
else
  fail "verify-fail.sh does not reference 'implement-feature'"
fi

if [ "$FAIL" -eq 0 ]; then
  echo "PASS: v9-5-verify-fail-updated — verify-fail.sh uses canonical skill names"
fi
exit "$FAIL"
