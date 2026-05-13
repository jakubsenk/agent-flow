#!/usr/bin/env bash
set -euo pipefail

# AC-6: Autopilot dispatches child skills for bugs and features
# Traces: AUTOPILOT-R9, AUTOPILOT-R6
# Description: Verifies SKILL.md documents two-query classification (Bug first, Feature second)
#              and dispatch via Skill tool for both fix-ticket and implement-feature

# Depends on Phase 7 implementation

cd "$(dirname "$0")/../../.."

SKILL="skills/autopilot/SKILL.md"

if [ ! -f "$SKILL" ]; then
  echo "FAIL: $SKILL does not exist — create it in Phase 7" >&2
  exit 1
fi

# Bug query must be referenced (AUTOPILOT-R6)
if ! grep -qiE 'Bug query|bug_query' "$SKILL"; then
  echo "FAIL: $SKILL does not reference 'Bug query' for classification" >&2
  exit 1
fi

# Feature query must be referenced (AUTOPILOT-R6)
if ! grep -qiE 'Feature query|feature_query' "$SKILL"; then
  echo "FAIL: $SKILL does not reference 'Feature query' for classification" >&2
  exit 1
fi

# Skill tool dispatch for fix-ticket and implement-feature (AC-6 verify command)
FIX_TICKET_MATCHES=$(grep -nE "Skill\s*\(.*(fix-ticket)" "$SKILL" | wc -l || echo 0)
FEATURE_MATCHES=$(grep -nE "Skill\s*\(.*(implement-feature)" "$SKILL" | wc -l || echo 0)

if [ "$FIX_TICKET_MATCHES" -lt 1 ]; then
  echo "FAIL: $SKILL has no Skill(...fix-ticket...) dispatch (expected ≥1 match)" >&2
  exit 1
fi

if [ "$FEATURE_MATCHES" -lt 1 ]; then
  echo "FAIL: $SKILL has no Skill(...implement-feature...) dispatch (expected ≥1 match)" >&2
  exit 1
fi

echo "PASS: AC-6 — Autopilot SKILL.md documents two-query classification and Skill tool dispatch"
exit 0
