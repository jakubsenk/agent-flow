#!/usr/bin/env bash
# Test: skills/create-backlog/SKILL.md documents required CLI flags
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

FAIL=0
fail() { echo "FAIL: $1"; FAIL=1; }

SKILL_FILE="$REPO_ROOT/skills/create-backlog/SKILL.md"

# 1. File must exist
if [ ! -f "$SKILL_FILE" ]; then
  fail "skills/create-backlog/SKILL.md does not exist"
  exit 1
fi

# 2. Documents --decompose flag
if ! grep -qi "\-\-decompose" "$SKILL_FILE"; then
  fail "skills/create-backlog/SKILL.md missing --decompose flag documentation"
fi

# 3. Documents --update flag
if ! grep -qi "\-\-update" "$SKILL_FILE"; then
  fail "skills/create-backlog/SKILL.md missing --update flag documentation"
fi

# 4. Documents --dry-run flag
if ! grep -qi "\-\-dry-run\|--dry.run" "$SKILL_FILE"; then
  fail "skills/create-backlog/SKILL.md missing --dry-run flag documentation"
fi

[ "$FAIL" -eq 0 ] && echo "PASS: skills/create-backlog/SKILL.md documents all required flags: --decompose, --update, --dry-run"
exit "$FAIL"
