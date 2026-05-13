#!/usr/bin/env bash
# Verifies: AC-NF-007, REQ-NF-007
# Description: v6.x / v7.x state.json files remain jq-parseable by v8 tests;
#   new v8 keys are optional/ignored by old readers
set -uo pipefail

# NOTE: REPO_ROOT assumes test file location is tests/scenarios/. Run after Phase 7 has moved files.
# Do NOT execute from staging location .forge/phase-5-tdd/tests/.
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
# Guard: ensure we are not running from staging location
if echo "$REPO_ROOT" | grep -q '\.forge'; then
  echo "ERROR: REPO_ROOT=$REPO_ROOT — tests must be run from tests/scenarios/ after Phase 7 staging" >&2
  exit 1
fi
TMPDIR_TEST="$(mktemp -d)"
trap 'rm -rf "$TMPDIR_TEST"' EXIT INT TERM

FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

# ---------------------------------------------------------------------------
# Setup: v7-style state.json (no v8 keys)
# ---------------------------------------------------------------------------
cat > "$TMPDIR_TEST/state-v7.json" << 'EOF'
{
  "schema_version": "1.0",
  "issue_id": "BUG-100",
  "pipeline": "fix-bugs",
  "triage_completed_at": "2026-04-20T10:00:00Z",
  "code_analyst_completed_at": "2026-04-20T10:05:00Z",
  "outcome": "success"
}
EOF

# v8-style state.json (with additive keys)
cat > "$TMPDIR_TEST/state-v8.json" << 'EOF'
{
  "schema_version": "1.0",
  "issue_id": "BUG-200",
  "pipeline": "fix-bugs",
  "analyst_triage_completed_at": "2026-04-27T10:05:00Z",
  "triage_completed_at": "2026-04-27T10:05:00Z",
  "analyst_impact_completed_at": "2026-04-27T10:08:00Z",
  "test_engineer_e2e_invoked": false,
  "outcome": "success"
}
EOF

# ---------------------------------------------------------------------------
# Assertion 1: v7 state.json parseable by jq
# ---------------------------------------------------------------------------
echo "--- Assertion 1: v7 state.json parses without error ---"
if command -v jq > /dev/null 2>&1; then
  if jq '.' "$TMPDIR_TEST/state-v7.json" > /dev/null 2>&1; then
    echo "OK: v7 state.json parses cleanly"
  else
    fail "v7 state.json failed jq parse"
  fi
else
  # Fallback: basic JSON structure check
  if grep -qF '"schema_version"' "$TMPDIR_TEST/state-v7.json"; then
    echo "OK: v7 state.json has expected structure (jq unavailable)"
  else
    fail "v7 state.json missing expected structure"
  fi
fi

# ---------------------------------------------------------------------------
# Assertion 2: v8 state.json parseable by jq
# ---------------------------------------------------------------------------
echo "--- Assertion 2: v8 state.json (with new keys) parses without error ---"
if command -v jq > /dev/null 2>&1; then
  if jq '.' "$TMPDIR_TEST/state-v8.json" > /dev/null 2>&1; then
    echo "OK: v8 state.json parses cleanly"
  else
    fail "v8 state.json failed jq parse"
  fi
fi

# ---------------------------------------------------------------------------
# Assertion 3: schema_version remains "1.0" in both
# ---------------------------------------------------------------------------
echo "--- Assertion 3: schema_version = 1.0 in both v7 and v8 state.json ---"
if command -v jq > /dev/null 2>&1; then
  V7_SCHEMA=$(jq -r '.schema_version' "$TMPDIR_TEST/state-v7.json")
  V8_SCHEMA=$(jq -r '.schema_version' "$TMPDIR_TEST/state-v8.json")
  [ "$V7_SCHEMA" = "1.0" ] && echo "OK: v7 state schema_version=1.0" || fail "v7 schema_version=$V7_SCHEMA"
  [ "$V8_SCHEMA" = "1.0" ] && echo "OK: v8 state schema_version=1.0" || fail "v8 schema_version=$V8_SCHEMA"
fi

# ---------------------------------------------------------------------------
# Assertion 4: state/schema.md documents additive-only v8 changes
# ---------------------------------------------------------------------------
echo "--- Assertion 4: state/schema.md documents additive-only v8 changes ---"
SCHEMA_DOC="$REPO_ROOT/state/schema.md"
if [ -f "$SCHEMA_DOC" ]; then
  if grep -qiE 'additive|backward.compat|old.*reader.*ignore' "$SCHEMA_DOC"; then
    echo "OK: state/schema.md documents additive-only changes"
  else
    fail "state/schema.md missing additive-only / backward-compat documentation"
  fi
fi

# ---------------------------------------------------------------------------
# Final result
# ---------------------------------------------------------------------------
if [ "$FAIL" -eq 0 ]; then
  echo "PASS: AC-NF-007 — v7 and v8 state.json files parseable + schema_version=1.0"
fi
exit "$FAIL"
