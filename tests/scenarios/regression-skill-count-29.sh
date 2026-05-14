#!/usr/bin/env bash
set -euo pipefail

# REGRESSION: skills/ has exactly 17 subdirectories (estimate, migrate-config, pipeline-status, scaffold-validate, version-bump removed)
# Traces: AUTOPILOT-R1, AC-23
# Description: Verifies filesystem skill count is exactly 17

cd "$(dirname "$0")/../.."

SKILL_COUNT=$(find skills -maxdepth 1 -mindepth 1 -type d 2>/dev/null | wc -l | tr -d '[:space:]' || echo 0)

if [ "$SKILL_COUNT" -ne 17 ]; then
  echo "FAIL: skills/ has $SKILL_COUNT subdirectories (expected exactly 17)" >&2
  echo "      Check: find skills -maxdepth 1 -mindepth 1 -type d" >&2
  exit 1
fi

echo "PASS: REGRESSION — skills/ has exactly 17 subdirectories"
exit 0
