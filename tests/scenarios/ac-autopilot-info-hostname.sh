#!/usr/bin/env bash
set -euo pipefail

# AC-36: Autopilot emits INFO line with hostname on every lock acquisition
# Traces: AUTOPILOT-R13
# Description: Verifies SKILL.md and docs/guides/autopilot.md document the INFO line
#              and single-host-operation / disjoint-query guidance

# Depends on Phase 7 implementation (docs/guides/autopilot.md is NEW)

cd "$(dirname "$0")/../.."

SKILL="skills/autopilot/SKILL.md"
GUIDE="docs/guides/autopilot.md"

if [ ! -f "$SKILL" ]; then
  echo "FAIL: $SKILL does not exist — create it in Phase 7" >&2
  exit 1
fi

# Must document INFO line with Running on host
if ! grep -qF '[autopilot][INFO] Running on host' "$SKILL"; then
  echo "FAIL: $SKILL missing '[autopilot][INFO] Running on host' INFO line" >&2
  exit 1
fi

# single-host-operation must be referenced in SKILL.md
if ! grep -qF 'single-host-operation' "$SKILL"; then
  echo "FAIL: $SKILL missing reference to 'single-host-operation' guide anchor" >&2
  exit 1
fi

# disjoint bug/feature query guidance must exist in SKILL.md
if ! grep -qiE 'disjoint' "$SKILL"; then
  echo "FAIL: $SKILL missing 'disjoint' query guidance (AUTOPILOT-R13)" >&2
  exit 1
fi

# docs/guides/autopilot.md must exist (NEW file)
if [ ! -f "$GUIDE" ]; then
  echo "FAIL: $GUIDE does not exist — create it in Phase 7" >&2
  exit 1
fi

# Guide must have single-host-operation section
if ! grep -qF 'single-host-operation' "$GUIDE"; then
  echo "FAIL: $GUIDE missing 'single-host-operation' anchor" >&2
  exit 1
fi

# Guide must mention disjoint query
if ! grep -qiE 'disjoint' "$GUIDE"; then
  echo "FAIL: $GUIDE missing 'disjoint' query guidance" >&2
  exit 1
fi

echo "PASS: AC-36 — Autopilot documents INFO hostname line + single-host-operation guidance"
exit 0
