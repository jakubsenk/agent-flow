#!/usr/bin/env bash
set -euo pipefail

# AC-35: Autopilot On error: stop breaks dispatch loop after first failure
# Traces: AUTOPILOT-R10
# Description: Verifies SKILL.md documents stop-on-error dispatch loop behavior

# Depends on Phase 7 implementation

cd "$(dirname "$0")/../.."

SKILL="skills/autopilot/SKILL.md"

if [ ! -f "$SKILL" ]; then
  echo "FAIL: $SKILL does not exist — create it in Phase 7" >&2
  exit 1
fi

FAIL=0

# stop mode: break loop
if ! grep -qiE 'On error.*stop|stop.*break|break.*stop' "$SKILL"; then
  echo "FAIL: $SKILL does not document 'On error: stop' loop break behavior" >&2
  FAIL=1
fi

# skip mode: WARN + continue (default)
if ! grep -qiE 'On error.*skip|skip.*continue|WARN.*continue' "$SKILL"; then
  echo "FAIL: $SKILL does not document 'On error: skip' WARN + continue behavior" >&2
  FAIL=1
fi

[ "$FAIL" -eq 0 ] && echo "PASS: autopilot-on-error-stop — SKILL.md documents stop (break) and skip (continue)"
exit "$FAIL"
