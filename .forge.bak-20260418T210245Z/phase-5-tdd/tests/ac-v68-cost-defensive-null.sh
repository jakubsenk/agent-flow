#!/usr/bin/env bash
set -euo pipefail

# AC-16: Defensive read writes zeros when Task usage is null
# Traces: COST-R3
# Description: Verifies core/state-manager.md or skill files document defensive fallback to 0

# Depends on Phase 7 implementation (state-manager.md is MODIFIED)

cd "$(dirname "$0")/../../.."

FAIL=0

# core/state-manager.md must document the defensive pattern
STATE_MGR="core/state-manager.md"
if [ ! -f "$STATE_MGR" ]; then
  echo "FAIL: $STATE_MGR does not exist" >&2
  FAIL=1
else
  # Must mention result.usage null/missing fallback
  if ! grep -qiE 'result\.usage|usage.*null|null.*usage' "$STATE_MGR"; then
    echo "FAIL: $STATE_MGR does not document result.usage null check" >&2
    FAIL=1
  fi

  # Must document fallback to 0 for missing fields
  if ! grep -qiE 'fallback.*0|default.*0|0.*fallback|write.*0' "$STATE_MGR"; then
    echo "FAIL: $STATE_MGR does not document writing 0 as defensive fallback" >&2
    FAIL=1
  fi
fi

[ "$FAIL" -eq 0 ] && echo "PASS: AC-16 — state-manager.md documents defensive null -> 0 fallback"
exit "$FAIL"
