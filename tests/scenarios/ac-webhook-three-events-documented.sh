#!/usr/bin/env bash
set -euo pipefail

# Notifications On events enumeration lists three new tokens
# Description: Verifies CLAUDE.md and docs/reference/config.md enumerate the 3 new webhook events

# Depends on Phase 7 implementation

cd "$(dirname "$0")/../.."

FAIL=0

# Check CLAUDE.md
if ! grep -qF 'pipeline-started' CLAUDE.md; then
  echo "FAIL: CLAUDE.md missing 'pipeline-started' in On events enumeration" >&2
  FAIL=1
fi
if ! grep -qF 'step-completed' CLAUDE.md; then
  echo "FAIL: CLAUDE.md missing 'step-completed' in On events enumeration" >&2
  FAIL=1
fi
if ! grep -qF 'pipeline-completed' CLAUDE.md; then
  echo "FAIL: CLAUDE.md missing 'pipeline-completed' in On events enumeration" >&2
  FAIL=1
fi

# Check docs/reference/config.md
CONFIG_REF="docs/reference/config.md"
if [ -f "$CONFIG_REF" ]; then
  for event in pipeline-started step-completed pipeline-completed; do
    if ! grep -qF "$event" "$CONFIG_REF"; then
      echo "FAIL: $CONFIG_REF missing '$event' event token" >&2
      FAIL=1
    fi
  done
fi

# Verify all 3 tokens on one line in either file
if ! grep -nE 'pipeline-started.*step-completed.*pipeline-completed' CLAUDE.md "$CONFIG_REF" 2>/dev/null | grep -q .; then
  echo "FAIL: Neither CLAUDE.md nor config.md has all 3 event tokens on a single line" >&2
  FAIL=1
fi

[ "$FAIL" -eq 0 ] && echo "PASS: CLAUDE.md and config.md enumerate pipeline-started, step-completed, pipeline-completed"
exit "$FAIL"
