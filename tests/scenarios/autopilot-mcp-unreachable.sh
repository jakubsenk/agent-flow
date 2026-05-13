#!/usr/bin/env bash
set -euo pipefail

# AC-32: Autopilot exits 3 with [STOP] MCP unreachable, creates no lock
# Traces: AUTOPILOT-R12
# Description: Verifies SKILL.md documents MCP-unreachable behavior: exit 3, no lock

# Depends on Phase 7 implementation

cd "$(dirname "$0")/../.."

SKILL="skills/autopilot/SKILL.md"

if [ ! -f "$SKILL" ]; then
  echo "FAIL: $SKILL does not exist — create it in Phase 7" >&2
  exit 1
fi

FAIL=0

# [STOP] MCP unreachable to stderr
if ! grep -qF '[STOP] MCP unreachable' "$SKILL"; then
  echo "FAIL: $SKILL missing '[STOP] MCP unreachable' message" >&2
  FAIL=1
fi

# exit 3
if ! grep -qE 'exit 3' "$SKILL"; then
  echo "FAIL: $SKILL does not document 'exit 3' for MCP failure" >&2
  FAIL=1
fi

# MCP check BEFORE lock (Step 0)
if ! grep -qiE 'Step 0|step 0|MCP.*ping|mcp.*before.*lock|before.*lock.*MCP' "$SKILL"; then
  echo "FAIL: $SKILL does not document MCP ping at Step 0 (before lock acquisition)" >&2
  FAIL=1
fi

[ "$FAIL" -eq 0 ] && echo "PASS: autopilot-mcp-unreachable — SKILL.md documents exit 3 + no lock on MCP failure"
exit "$FAIL"
