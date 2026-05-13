#!/usr/bin/env bash
set -euo pipefail

# AC-1: Autopilot skill file exists with correct frontmatter
# Traces: AUTOPILOT-R1
# Description: Verifies skills/autopilot/SKILL.md exists with anchored frontmatter keys

# Depends on Phase 7 implementation

cd "$(dirname "$0")/../../.."

SKILL="skills/autopilot/SKILL.md"

if [ ! -f "$SKILL" ]; then
  echo "FAIL: $SKILL does not exist — create it in Phase 7" >&2
  exit 1
fi

# Anchored grep: each key must appear as an exact line (prevents false positives in comments)
if ! grep -cE '^name: autopilot$' "$SKILL" | grep -q '^[1-9]'; then
  echo "FAIL: $SKILL missing 'name: autopilot' as an anchored frontmatter line" >&2
  exit 1
fi

if ! grep -cE '^disable-model-invocation: true$' "$SKILL" | grep -q '^[1-9]'; then
  echo "FAIL: $SKILL missing 'disable-model-invocation: true' as an anchored frontmatter line" >&2
  exit 1
fi

if ! grep -cE '^argument-hint: "\[--dry-run\]"$' "$SKILL" | grep -q '^[1-9]'; then
  echo "FAIL: $SKILL missing 'argument-hint: \"[--dry-run]\"' as an anchored frontmatter line" >&2
  exit 1
fi

echo "PASS: AC-1 — skills/autopilot/SKILL.md exists with correct frontmatter"
exit 0
