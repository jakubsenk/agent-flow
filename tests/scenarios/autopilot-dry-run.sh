#!/usr/bin/env bash
set -euo pipefail

# AC-8: Dry-run is full short-circuit (no lock, no state, no webhook, no dispatch)
# Traces: AUTOPILOT-R11
# Description: Verifies SKILL.md documents dry-run short-circuit behavior

# Depends on Phase 7 implementation

cd "$(dirname "$0")/../.."

SKILL="skills/autopilot/SKILL.md"

if [ ! -f "$SKILL" ]; then
  echo "FAIL: $SKILL does not exist — create it in Phase 7" >&2
  exit 1
fi

FAIL=0

# Dry run short-circuit must be documented
if ! grep -qiE 'dry.?run|DRY.?RUN' "$SKILL"; then
  echo "FAIL: $SKILL does not mention dry-run" >&2
  FAIL=1
fi

# No lock in dry-run
if ! grep -qiE 'dry.?run.*no.*lock|no.*lock.*dry.?run|short.?circuit' "$SKILL"; then
  echo "FAIL: $SKILL does not document dry-run prevents lock acquisition" >&2
  FAIL=1
fi

# [DRY RUN] output tag
if ! grep -qF '[DRY RUN]' "$SKILL"; then
  echo "FAIL: $SKILL missing [DRY RUN] output marker" >&2
  FAIL=1
fi

# No dispatch in dry-run
if ! grep -qiE 'dry.?run.*no.*dispatch|no.*dispatch.*dry.?run' "$SKILL"; then
  echo "FAIL: $SKILL does not document dry-run prevents dispatch" >&2
  FAIL=1
fi

[ "$FAIL" -eq 0 ] && echo "PASS: autopilot-dry-run — SKILL.md documents full short-circuit dry-run"
exit "$FAIL"
