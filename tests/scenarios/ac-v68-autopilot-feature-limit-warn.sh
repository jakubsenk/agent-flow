#!/usr/bin/env bash
set -euo pipefail

# AC-31: Autopilot WARNs when Feature limit > 0 but no Feature query configured
# Traces: AUTOPILOT-R8
# Description: Verifies SKILL.md documents WARN when Feature limit > 0 with no Feature query

# Depends on Phase 7 implementation

cd "$(dirname "$0")/../.."

SKILL="skills/autopilot/SKILL.md"

if [ ! -f "$SKILL" ]; then
  echo "FAIL: $SKILL does not exist — create it in Phase 7" >&2
  exit 1
fi

# Must document the warning message (AUTOPILOT-R8 exact text)
if ! grep -qF '[autopilot][WARN] Feature limit=' "$SKILL"; then
  echo "FAIL: $SKILL missing '[autopilot][WARN] Feature limit=...' WARN message" >&2
  exit 1
fi

# Must mention 'no Feature query' context
if ! grep -qiE 'no Feature query|Feature query.*not configured|no.*feature_query' "$SKILL"; then
  echo "FAIL: $SKILL does not document the 'no Feature query' condition for Feature limit WARN" >&2
  exit 1
fi

echo "PASS: AC-31 — Autopilot SKILL.md documents Feature limit WARN when no Feature query"
exit 0
