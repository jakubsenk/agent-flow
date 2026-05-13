#!/usr/bin/env bash
set -euo pipefail

# AC-8: Dry-run is full short-circuit (no lock, no state, no webhook, no dispatch)
# Traces: AUTOPILOT-R11
# Description: Verifies SKILL.md documents dry-run as full short-circuit before lock acquisition

# Depends on Phase 7 implementation

cd "$(dirname "$0")/../../.."

SKILL="skills/autopilot/SKILL.md"

if [ ! -f "$SKILL" ]; then
  echo "FAIL: $SKILL does not exist — create it in Phase 7" >&2
  exit 1
fi

# Must document dry-run behavior
if ! grep -qiE 'dry.?run|DRY.?RUN' "$SKILL"; then
  echo "FAIL: $SKILL does not mention dry-run / Dry run" >&2
  exit 1
fi

# Must document that dry-run prevents lock acquisition
if ! grep -qiE 'dry.?run.*no.*lock|no.*lock.*dry.?run|short.?circuit' "$SKILL"; then
  echo "FAIL: $SKILL does not document dry-run short-circuit (no lock created)" >&2
  exit 1
fi

# Must document [DRY RUN] output marker
if ! grep -qF '[DRY RUN]' "$SKILL"; then
  echo "FAIL: $SKILL missing [DRY RUN] marker in dry-run output description" >&2
  exit 1
fi

echo "PASS: AC-8 — Autopilot SKILL.md documents full short-circuit dry-run"
exit 0
