#!/usr/bin/env bash
set -euo pipefail

# AC-35: Autopilot On error: stop breaks dispatch loop after first failure
# Traces: AUTOPILOT-R10
# Description: Verifies SKILL.md documents both skip and stop error handling modes

# Depends on Phase 7 implementation

cd "$(dirname "$0")/../.."

SKILL="skills/autopilot/SKILL.md"

if [ ! -f "$SKILL" ]; then
  echo "FAIL: $SKILL does not exist — create it in Phase 7" >&2
  exit 1
fi

# Must document 'On error: stop' behavior (break loop)
if ! grep -qiE 'On error.*stop|on_error.*stop' "$SKILL"; then
  echo "FAIL: $SKILL does not document 'On error: stop' mode" >&2
  exit 1
fi

# Must document 'On error: skip' behavior (default - continue)
if ! grep -qiE 'On error.*skip|on_error.*skip' "$SKILL"; then
  echo "FAIL: $SKILL does not document 'On error: skip' mode (default)" >&2
  exit 1
fi

# stop must break the loop
if ! grep -qiE 'break|stop.*loop|loop.*stop' "$SKILL"; then
  echo "FAIL: $SKILL does not document loop break on On error: stop" >&2
  exit 1
fi

echo "PASS: AC-35 — Autopilot SKILL.md documents On error: stop (break) and skip (continue)"
exit 0
