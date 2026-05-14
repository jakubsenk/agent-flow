#!/bin/bash
# Covers: AC-37, AC-38, AC-39 — v8-overlay-*.sh deletion checks
# The legacy .md overlay path was deleted; as a result,
# v8-overlay-md-toml-coexist.sh, v8-overlay-provenance-log.sh, and
# v8-overlay-syntax-error.sh were also deleted (they tested the removed
# .md overlay behavior which no longer exists in production code).
# This meta-test asserts all three files are ABSENT (deletion was intentional).
set -e

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

FAIL=0
fail() { echo "FAIL: v9-5-overlay-tests-updated — $1"; FAIL=1; }

# AC-37: v8-overlay-md-toml-coexist.sh must be absent
FILE37="$REPO_ROOT/tests/scenarios/v8-overlay-md-toml-coexist.sh"
if [ -f "$FILE37" ]; then
  fail "tests/scenarios/v8-overlay-md-toml-coexist.sh unexpectedly exists (should have been deleted in cleanup)"
else
  echo "PASS: v8-overlay-md-toml-coexist.sh correctly absent (deleted — .md overlay path removed)"
fi

# AC-38: v8-overlay-provenance-log.sh must be absent
FILE38="$REPO_ROOT/tests/scenarios/v8-overlay-provenance-log.sh"
if [ -f "$FILE38" ]; then
  fail "tests/scenarios/v8-overlay-provenance-log.sh unexpectedly exists (should have been deleted in cleanup)"
else
  echo "PASS: v8-overlay-provenance-log.sh correctly absent (deleted — .md overlay path removed)"
fi

# AC-39: v8-overlay-syntax-error.sh must be absent
FILE39="$REPO_ROOT/tests/scenarios/v8-overlay-syntax-error.sh"
if [ -f "$FILE39" ]; then
  fail "tests/scenarios/v8-overlay-syntax-error.sh unexpectedly exists (should have been deleted in cleanup)"
else
  echo "PASS: v8-overlay-syntax-error.sh correctly absent (deleted — .md overlay path removed)"
fi

if [ "$FAIL" -eq 0 ]; then
  echo "PASS: v9-5-overlay-tests-updated — all 3 overlay test scenarios correctly absent"
fi
exit "$FAIL"
