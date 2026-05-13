#!/usr/bin/env bash
set -euo pipefail

# REGRESSION: skills/ has exactly 18 subdirectories (v9.5.0: estimate, migrate-config, pipeline-status, scaffold-validate removed)
# Traces: AUTOPILOT-R1, AC-23
# Description: Verifies filesystem skill count is exactly 18 after v9.5.0

# Depends on v9.1.0 + v9.2.0 + v9.3.0 + v9.5.0 deletions

cd "$(dirname "$0")/../.."

SKILL_COUNT=$(find skills -maxdepth 1 -mindepth 1 -type d 2>/dev/null | wc -l | tr -d '[:space:]' || echo 0)

if [ "$SKILL_COUNT" -ne 18 ]; then
  echo "FAIL: skills/ has $SKILL_COUNT subdirectories (expected exactly 18)" >&2
  echo "      Check: find skills -maxdepth 1 -mindepth 1 -type d" >&2
  exit 1
fi

echo "PASS: REGRESSION — skills/ has exactly 18 subdirectories"
exit 0
