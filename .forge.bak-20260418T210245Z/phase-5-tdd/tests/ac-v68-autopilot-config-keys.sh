#!/usr/bin/env bash
set -euo pipefail

# AC-21: ### Autopilot section documented in CLAUDE.md with 7 keys
# Traces: AUTOPILOT-R6, AUTOPILOT-R10, AUTOPILOT-R11
# Description: Verifies CLAUDE.md documents all 7 Autopilot config keys

# Depends on Phase 7 implementation

cd "$(dirname "$0")/../../.."

CLAUDE="CLAUDE.md"

if [ ! -f "$CLAUDE" ]; then
  echo "FAIL: CLAUDE.md not found" >&2
  exit 1
fi

KEYS=(
  "Max issues per run"
  "Lock timeout"
  "Log file"
  "Bug limit"
  "Feature limit"
  "On error"
  "Dry run"
)

FAIL=0
for key in "${KEYS[@]}"; do
  if ! grep -qF "$key" "$CLAUDE"; then
    echo "FAIL: CLAUDE.md missing Autopilot config key: '$key'" >&2
    FAIL=1
  fi
done

# Count match for the verify command in formal-criteria (AC-21)
MATCH_COUNT=$(grep -cE "Max issues per run|Lock timeout|Log file|Bug limit|Feature limit|On error|Dry run" "$CLAUDE" || echo 0)
if [ "$MATCH_COUNT" -lt 7 ]; then
  echo "FAIL: CLAUDE.md has fewer than 7 Autopilot key matches (found $MATCH_COUNT)" >&2
  FAIL=1
fi

[ "$FAIL" -eq 0 ] && echo "PASS: AC-21 — CLAUDE.md documents all 7 Autopilot config keys"
exit "$FAIL"
