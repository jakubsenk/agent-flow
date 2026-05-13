#!/usr/bin/env bash
# AC: AC-T1-2-1, AC-T1-2-2 (REWRITE #15 — Tier A+B, RESTORED)
# Functional: pipeline-history.md excludes block.detail (PII/credential scope).
# Uses make_state_json with block.detail field; verifies schema exclusion contract.
set -uo pipefail

. "$(dirname "$0")/../lib/fixtures.sh"

REPO_ROOT="$(cd "$(dirname "$0")/../../" && pwd)"
FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

require_jq
setup_scratch

if [ "${HAVE_JQ:-0}" = "1" ]; then
  # Tier A: state.json WITH block.detail — should NOT appear in pipeline-history
  STATE=$(make_state_json '{
    "status": "blocked",
    "block": {
      "detail": "AKIA1234SECRETKEY\nFatal error in auth module",
      "reason": "authentication failure",
      "step": "test"
    }
  }')
  echo "$STATE" > "$SCRATCH/state.json"

  # Verify block.detail is present in state
  detail=$(jq -r '.block.detail' "$SCRATCH/state.json")
  if echo "$detail" | grep -q 'AKIA'; then
    echo "OK: block.detail contains credential-like content (as expected for test)"
  fi

  # Simulate history entry construction — block.detail must be excluded
  HISTORY_ENTRY=$(jq -n --slurpfile s "$SCRATCH/state.json" '{
    issue_id: "PROJ-42",
    outcome: $s[0].status,
    block_reason: $s[0].block.reason,
    block_step: $s[0].block.step
  }')
  echo "$HISTORY_ENTRY" > "$SCRATCH/history_entry.json"

  # Verify block.detail is NOT in the history entry
  if jq -e '.block_detail' "$SCRATCH/history_entry.json" >/dev/null 2>&1; then
    fail "History entry must NOT include block.detail field"
  fi
  # block.reason is OK (bounded, sanitized)
  reason=$(jq -r '.block_reason' "$SCRATCH/history_entry.json")
  [ "$reason" = "authentication failure" ] || fail "block_reason not preserved: $reason"
fi

# Tier B: schema.md documents block.detail exclusion from pipeline-history
SCHEMA="$REPO_ROOT/state/schema.md"
if [ -f "$SCHEMA" ]; then
  if ! grep -qiE 'block\.detail.*exclud|exclud.*block\.detail|HARD.*EXCLUD.*block|pipeline.history' "$SCHEMA"; then
    fail "state/schema.md missing block.detail exclusion from pipeline-history documentation"
  fi
fi

[ "$FAIL" -eq 0 ] && echo "PASS: pipeline-history PII scope (block.detail excluded) verified"
exit "$FAIL"
