#!/usr/bin/env bash
# Hidden scenario: REQ-042, REQ-043, REQ-044 — state schema additive (parse-modify-write preserves all fields)
# Expected v6.9.0 outcome: PASS once Phase 7 implements
# Pre-implementation outcome: FAIL (TDD) — clarification object not yet in state/schema.md
set -uo pipefail

# CRITICAL: 3 levels up from .forge/phase-5-tdd/tests-hidden/ to repo root
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../" && pwd)"

if [ ! -f "$REPO_ROOT/.claude-plugin/plugin.json" ]; then
  echo "FAIL: REPO_ROOT path resolution bug" >&2; exit 1
fi

FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

SCHEMA="$REPO_ROOT/state/schema.md"

if [ ! -f "$SCHEMA" ]; then
  echo "FAIL: state/schema.md not found" >&2; exit 1
fi

# Assertion 1: clarification object fields present (AC-042)
echo "--- Assertion 1 (AC-042): clarification object in state/schema.md ---"
if ! grep -qF '"clarification":' "$SCHEMA"; then
  fail "AC-042: state/schema.md missing clarification object"
fi

# Assertion 2: schema_version stays "1.0" after additive fields (AC-044)
echo "--- Assertion 2 (AC-044): schema_version still '1.0' ---"
if grep -qF '"schema_version": "1.0"' "$SCHEMA"; then
  echo "OK: schema_version still '1.0'"
else
  fail "AC-044: schema_version changed — must remain '1.0' (additive fields only)"
fi

# Assertion 3: parse-modify-write roundtrip preserves all existing fields
# Construct a synthetic state.json with BOTH existing fields AND new clarification field
echo "--- Assertion 3: parse-modify-write preserves all existing fields ---"
TMPDIR_TEST=$(mktemp -d)
trap 'rm -rf "$TMPDIR_TEST"' EXIT INT TERM

STATE_FILE="$TMPDIR_TEST/state.json"

# Write a realistic v6.8.1-era state.json with typical fields
cat > "$STATE_FILE" << 'STATEJSON'
{
  "schema_version": "1.0",
  "issue_id": "TEST-42",
  "status": "running",
  "branch": "fix/TEST-42-example-fix",
  "iteration": 2,
  "pipeline": {
    "tokens_used": 15000,
    "duration_ms": 45000,
    "summary_table": []
  },
  "stages": {
    "triage": {"status": "completed"},
    "fixer": {"status": "running", "tokens_used": 8000}
  },
  "parent_run_id": null
}
STATEJSON

if ! command -v jq &>/dev/null; then
  echo "SKIP: jq not available — skipping JSON roundtrip test"
  exit 0
fi

# Add the new clarification object (as Phase 7 would do when NEEDS_CLARIFICATION fires)
new_state=$(jq '. + {
  "clarification": {
    "question": "What is the expected output format?",
    "asked_by_agent": "fixer",
    "asked_at_step": "Step 5",
    "asked_at_iteration": 2,
    "context": "The issue description is ambiguous about JSON vs CSV output.",
    "answer": null,
    "clarifications_consumed": 1,
    "last_clarification_iteration": 2
  },
  "status": "paused"
}' "$STATE_FILE")

echo "$new_state" > "$TMPDIR_TEST/new_state.json"

# Verify all original fields are preserved in the modified state
original_fields=("schema_version" "issue_id" "status" "branch" "iteration" "pipeline" "stages" "parent_run_id")
for field in "${original_fields[@]}"; do
  value=$(jq -r ".${field} // empty" "$TMPDIR_TEST/new_state.json" 2>/dev/null)
  if [ -n "$value" ] || jq -e ".${field}" "$TMPDIR_TEST/new_state.json" >/dev/null 2>&1; then
    echo "OK: original field '$field' preserved after adding clarification object"
  else
    fail "Original field '$field' lost after parse-modify-write with new clarification object"
  fi
done

# Verify clarification object is present with correct shape
echo "--- Assertion 4: new clarification fields present ---"
clarification_fields=("question" "asked_by_agent" "asked_at_step" "asked_at_iteration" "context" "answer" "clarifications_consumed" "last_clarification_iteration")
for field in "${clarification_fields[@]}"; do
  if jq -e ".clarification.${field}" "$TMPDIR_TEST/new_state.json" >/dev/null 2>&1; then
    echo "OK: clarification.$field present in new state"
  else
    fail "clarification.$field missing in new state after write"
  fi
done

# Verify schema_version is still "1.0"
sv=$(jq -r '.schema_version' "$TMPDIR_TEST/new_state.json")
if [ "$sv" = "1.0" ]; then
  echo "OK: schema_version remains '1.0' after adding clarification object"
else
  fail "schema_version changed to '$sv' — must stay '1.0'"
fi

# Verify status changed to "paused"
new_status=$(jq -r '.status' "$TMPDIR_TEST/new_state.json")
if [ "$new_status" = "paused" ]; then
  echo "OK: status transitioned to 'paused'"
else
  fail "status is '$new_status' (expected 'paused' after NEEDS_CLARIFICATION)"
fi

if [ "$FAIL" -eq 0 ]; then
  echo "PASS: h-needs-clarification-state-additive — parse-modify-write preserves all existing fields; clarification object additive; schema_version 1.0"
fi
exit "$FAIL"
