#!/usr/bin/env bash
set -euo pipefail

# AC-7: Autopilot WARNs on absent Feature Workflow and continues
# Traces: AUTOPILOT-R7
# Description: Verifies SKILL.md documents [WARN] when Feature Workflow section absent

# Depends on Phase 7 implementation

cd "$(dirname "$0")/../../.."

SKILL="skills/autopilot/SKILL.md"

if [ ! -f "$SKILL" ]; then
  echo "FAIL: $SKILL does not exist — create it in Phase 7" >&2
  exit 1
fi

# Must document the WARN message for absent Feature Workflow
if ! grep -qF '[autopilot][WARN] Feature Workflow section absent' "$SKILL"; then
  echo "FAIL: $SKILL missing '[autopilot][WARN] Feature Workflow section absent' message" >&2
  exit 1
fi

# Must document continuing (bug-only mode)
if ! grep -qiE 'bug.only|bug only' "$SKILL"; then
  echo "FAIL: $SKILL does not document 'bug-only mode' fallback after Feature Workflow absent" >&2
  exit 1
fi

echo "PASS: AC-7 — Autopilot SKILL.md documents WARN + continue on absent Feature Workflow"
exit 0
