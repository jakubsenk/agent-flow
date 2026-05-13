#!/usr/bin/env bash
set -euo pipefail

# AC-31: Autopilot WARNs when Feature limit > 0 but no Feature query configured
# Traces: AUTOPILOT-R8
# Description: Verifies SKILL.md documents the Feature-limit WARN message

# Depends on Phase 7 implementation

cd "$(dirname "$0")/../.."

SKILL="skills/autopilot/SKILL.md"

if [ ! -f "$SKILL" ]; then
  echo "FAIL: $SKILL does not exist — create it in Phase 7" >&2
  exit 1
fi

FAIL=0

# WARN message for Feature limit with no Feature query (AUTOPILOT-R8 exact format)
if ! grep -qF '[autopilot][WARN] Feature limit=' "$SKILL"; then
  echo "FAIL: $SKILL missing '[autopilot][WARN] Feature limit=...' message" >&2
  FAIL=1
fi

# The warn condition: Feature limit > 0 but no Feature query
if ! grep -qiE 'no Feature query|feature query.*not.*configured|feature_query.*absent' "$SKILL"; then
  echo "FAIL: $SKILL does not document 'no Feature query' condition for this WARN" >&2
  FAIL=1
fi

[ "$FAIL" -eq 0 ] && echo "PASS: autopilot-feature-limit-no-query — SKILL.md documents Feature limit WARN"
exit "$FAIL"
