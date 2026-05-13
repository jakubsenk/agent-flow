#!/usr/bin/env bash
set -euo pipefail

# REGRESSION: skills/ has exactly 29 subdirectories after autopilot/ is added
# Traces: AUTOPILOT-R1, AC-23
# Description: Verifies filesystem skill count is exactly 29 after Phase 7

# Depends on Phase 7 implementation (autopilot/ is NEW)

cd "$(dirname "$0")/../../.."

SKILL_COUNT=$(find skills -maxdepth 1 -mindepth 1 -type d 2>/dev/null | wc -l || echo 0)

if [ "$SKILL_COUNT" -ne 29 ]; then
  echo "FAIL: skills/ has $SKILL_COUNT subdirectories (expected exactly 29)" >&2
  echo "      Check: find skills -maxdepth 1 -mindepth 1 -type d" >&2
  exit 1
fi

echo "PASS: REGRESSION — skills/ has exactly 29 subdirectories"
exit 0
