#!/usr/bin/env bash
# AC: AC-T1-9-1, AC-T1-9-2 (hidden — harness count = 204)
# Verifies harness counts exactly 204 total scenarios after v6.10.0.
# Run under release commit only.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../" && pwd)"
FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

HARNESS="$REPO_ROOT/tests/harness/run-tests.sh"
[ -f "$HARNESS" ] || { fail "harness not found at $HARNESS"; exit 1; }

# AC-T1-9-1: count sh files in tests/scenarios/
scenario_count=$(find "$REPO_ROOT/tests/scenarios" -maxdepth 1 -name '*.sh' -type f | wc -l | tr -d ' ')
[ "$scenario_count" -eq 204 ] || \
  fail "Scenario file count: expected 204, got $scenario_count (baseline 185 + 19 net-new)"

# AC-T1-9-2: 4 SKIP files (exit 77)
skip_count=$(find "$REPO_ROOT/tests/scenarios" -maxdepth 1 -name '*.sh' -type f \
  -exec grep -l '^exit 77' {} \; | wc -l | tr -d ' ')
[ "$skip_count" -eq 4 ] || fail "Expected exactly 4 SKIP (exit 77) scenarios, got $skip_count"

echo "PASS: scenario count = 204 (hard equality), SKIP = 4"
exit "$FAIL"
