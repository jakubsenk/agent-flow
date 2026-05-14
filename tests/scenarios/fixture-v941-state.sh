#!/bin/bash
# Covers: AC-59 (tests/fixtures/v9.4.1-state.json committed),
#         AC-60 (state fixture has schema-correct shape with required fields)
set -e

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

FILE="$REPO_ROOT/tests/fixtures/v9.4.1-state.json"

if [ ! -f "$FILE" ]; then
  echo "FAIL: v9-5-fixture-v941-state — tests/fixtures/v9.4.1-state.json does not exist"
  exit 1
fi

FAIL=0
fail() { echo "FAIL: v9-5-fixture-v941-state — $1"; FAIL=1; }

# AC-60: schema shape checks
if grep -qE '"tokens_used"[[:space:]]*:[[:space:]]*[0-9]+' "$FILE"; then
  echo "PASS: tokens_used field present with integer value"
else
  fail "tokens_used field not found or not an integer in v9.4.1-state.json"
fi

if grep -qE '"duration_ms"[[:space:]]*:[[:space:]]*[0-9]+' "$FILE"; then
  echo "PASS: duration_ms field present with integer value"
else
  fail "duration_ms field not found or not an integer in v9.4.1-state.json"
fi

if grep -qE '"tool_uses"[[:space:]]*:[[:space:]]*[0-9]+' "$FILE"; then
  echo "PASS: tool_uses field present with integer value"
else
  fail "tool_uses field not found or not an integer in v9.4.1-state.json"
fi

if grep -qE '"model"[[:space:]]*:[[:space:]]*"[^"]+"' "$FILE"; then
  echo "PASS: model field present with string value"
else
  fail "model field not found or not a string in v9.4.1-state.json"
fi

if grep -qE '"started_at"[[:space:]]*:[[:space:]]*"[^"]+"' "$FILE"; then
  echo "PASS: started_at field present with string value"
else
  fail "started_at field not found or not a string in v9.4.1-state.json"
fi

if grep -qE '"completed_at"[[:space:]]*:[[:space:]]*"[^"]+"' "$FILE"; then
  echo "PASS: completed_at field present with string value"
else
  fail "completed_at field not found or not a string in v9.4.1-state.json"
fi

if [ "$FAIL" -eq 0 ]; then
  echo "PASS: v9-5-fixture-v941-state — v9.4.1-state.json exists with correct schema shape"
fi
exit "$FAIL"
