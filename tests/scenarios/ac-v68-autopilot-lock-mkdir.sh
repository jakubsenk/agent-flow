#!/usr/bin/env bash
set -euo pipefail

# AC-30: Autopilot lock is a DIRECTORY (mkdir-based), not a file
# Traces: AUTOPILOT-R2
# Description: Verifies SKILL.md documents mkdir for lock and not touch/> creation

# Depends on Phase 7 implementation

cd "$(dirname "$0")/../.."

SKILL="skills/autopilot/SKILL.md"

if [ ! -f "$SKILL" ]; then
  echo "FAIL: $SKILL does not exist — create it in Phase 7" >&2
  exit 1
fi

# Must mention mkdir for the lock directory
if ! grep -nE 'mkdir .*\.agent-flow/autopilot\.lock' "$SKILL" | grep -q .; then
  echo "FAIL: $SKILL has no 'mkdir ... .agent-flow/autopilot.lock' pattern — lock must use mkdir" >&2
  exit 1
fi

# Must NOT use touch or file-redirect to create the lock path
if grep -nE 'touch .*autopilot\.lock|> .*autopilot\.lock' "$SKILL" | grep -q .; then
  echo "FAIL: $SKILL uses touch or file-redirect for autopilot.lock — only mkdir is allowed" >&2
  exit 1
fi

echo "PASS: AC-30 — autopilot lock uses mkdir (portable, atomic)"
exit 0
