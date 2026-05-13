#!/usr/bin/env bash
set -euo pipefail

# AC-32: Autopilot exits 3 with [STOP] MCP unreachable and creates no lock
# Traces: AUTOPILOT-R12
# Description: Verifies SKILL.md documents MCP ping failure -> exit 3, no lock created

# Depends on Phase 7 implementation

cd "$(dirname "$0")/../../.."

SKILL="skills/autopilot/SKILL.md"

if [ ! -f "$SKILL" ]; then
  echo "FAIL: $SKILL does not exist — create it in Phase 7" >&2
  exit 1
fi

# Must document [STOP] MCP unreachable message
if ! grep -qF '[STOP] MCP unreachable' "$SKILL"; then
  echo "FAIL: $SKILL missing '[STOP] MCP unreachable' error message" >&2
  exit 1
fi

# Must document exit 3 for MCP failure
if ! grep -qE 'exit 3' "$SKILL"; then
  echo "FAIL: $SKILL does not document 'exit 3' for MCP unreachable" >&2
  exit 1
fi

# Must document that MCP ping happens BEFORE lock acquisition (Step 0)
if ! grep -qiE 'Step 0|step 0|MCP ping|mcp.*ping' "$SKILL"; then
  echo "FAIL: $SKILL does not document MCP ping as Step 0 (before lock)" >&2
  exit 1
fi

echo "PASS: AC-32 — Autopilot SKILL.md documents MCP-unreachable -> exit 3, no lock"
exit 0
