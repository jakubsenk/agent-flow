#!/usr/bin/env bash
set -euo pipefail

# AC-7: Autopilot WARNs when Feature Workflow absent and continues in bug-only mode
# Traces: AUTOPILOT-R7
# Description: Verifies SKILL.md documents the WARN message + bug-only continuation

# Depends on Phase 7 implementation

cd "$(dirname "$0")/../.."

SKILL="skills/autopilot/SKILL.md"

if [ ! -f "$SKILL" ]; then
  echo "FAIL: $SKILL does not exist — create it in Phase 7" >&2
  exit 1
fi

FAIL=0

# WARN message for absent Feature Workflow (exact text from AUTOPILOT-R7)
if ! grep -qF '[autopilot][WARN] Feature Workflow section absent' "$SKILL"; then
  echo "FAIL: $SKILL missing '[autopilot][WARN] Feature Workflow section absent' message" >&2
  FAIL=1
fi

# Bug-only mode continuation
if ! grep -qiE 'bug.only|continue.*bug|bug.*mode' "$SKILL"; then
  echo "FAIL: $SKILL does not document bug-only mode on absent Feature Workflow" >&2
  FAIL=1
fi

[ "$FAIL" -eq 0 ] && echo "PASS: autopilot-feature-workflow-absent — SKILL.md documents WARN + bug-only"
exit "$FAIL"
