#!/usr/bin/env bash
# Test: skills/implement-feature/SKILL.md contains --decompose-only flag documentation
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"

FAIL=0
fail() { echo "FAIL: $1"; FAIL=1; }

SKILL_FILE="$REPO_ROOT/skills/implement-feature/SKILL.md"

# 1. File must exist
if [ ! -f "$SKILL_FILE" ]; then
  fail "skills/implement-feature/SKILL.md does not exist"
  exit 1
fi

# 2. Documents --decompose-only flag
if ! grep -qi "\-\-decompose-only\|--decompose.only" "$SKILL_FILE"; then
  fail "skills/implement-feature/SKILL.md missing --decompose-only flag documentation"
fi

# 3. --decompose-only stops after decomposition (does not proceed to implementation)
# Look for language indicating it exits/stops/skips after decomposition step
if ! grep -qi "decompose.only\|decompose.*only\|only.*decompos\|stop.*after.*decompos\|decompos.*stop\|skip.*implement\|no.*implement" "$SKILL_FILE"; then
  fail "skills/implement-feature/SKILL.md --decompose-only must describe that implementation is skipped"
fi

# 4. Backlog-creator is referenced (triggered from implement-feature or create-backlog)
# This validates the integration point between decomposition and backlog creation
if ! grep -qi "backlog-creator\|create-backlog\|backlog.*creat\|creat.*backlog" "$SKILL_FILE"; then
  fail "skills/implement-feature/SKILL.md must reference backlog-creator or create-backlog integration"
fi

[ "$FAIL" -eq 0 ] && echo "PASS: skills/implement-feature/SKILL.md documents --decompose-only flag and backlog-creator integration"
exit "$FAIL"
