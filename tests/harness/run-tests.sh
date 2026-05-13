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
    PASS=$((PASS + 1))
  else
    exit_code=$?
    if [ $exit_code -eq 77 ]; then
      echo "SKIP"
      RESULTS+=("SKIP: $name")
      SKIP=$((SKIP + 1))
    else
      echo "FAIL"
      RESULTS+=("FAIL: $name")
      FAIL=$((FAIL + 1))
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
