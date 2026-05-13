#!/usr/bin/env bash
# Hidden mutation test: Temporarily rename skills/create-backlog/SKILL.md and verify that
# create-backlog-skill.sh FAILS, then restore the file.
# This validates that create-backlog-skill.sh correctly catches a missing skill.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"

FAIL=0
fail() { echo "FAIL: $1"; FAIL=1; }

SKILL_FILE="$REPO_ROOT/skills/create-backlog/SKILL.md"
SKILL_BACKUP="$REPO_ROOT/skills/create-backlog/SKILL.md.mutation_bak"
TEST_SCRIPT="$REPO_ROOT/.forge/phase-5-tdd/tests/create-backlog-skill.sh"

# Prerequisite: test script must exist
if [ ! -f "$TEST_SCRIPT" ]; then
  fail "Visible test create-backlog-skill.sh not found at $TEST_SCRIPT"
  exit 1
fi

# If the skill file doesn't exist yet (pre-implementation), just confirm the visible test fails
if [ ! -f "$SKILL_FILE" ]; then
  if bash "$TEST_SCRIPT" > /dev/null 2>&1; then
    fail "MUTATION: create-backlog-skill.sh PASSED even though skills/create-backlog/SKILL.md does not exist — test is not detecting missing file"
  else
    echo "OK: create-backlog-skill.sh correctly fails when skills/create-backlog/SKILL.md is absent"
  fi
  [ "$FAIL" -eq 0 ] && echo "PASS: mutation-remove-create-backlog — test correctly detects absent skill"
  exit "$FAIL"
fi

# Skill exists — perform rename mutation
mv "$SKILL_FILE" "$SKILL_BACKUP"

# Run the visible test — it MUST fail
if bash "$TEST_SCRIPT" > /dev/null 2>&1; then
  mv "$SKILL_BACKUP" "$SKILL_FILE"
  fail "MUTATION ESCAPED: create-backlog-skill.sh passed even with skills/create-backlog/SKILL.md removed"
else
  echo "OK: create-backlog-skill.sh correctly fails when skills/create-backlog/SKILL.md is removed"
fi

# Restore
mv "$SKILL_BACKUP" "$SKILL_FILE"

[ "$FAIL" -eq 0 ] && echo "PASS: mutation-remove-create-backlog — removal of skills/create-backlog/SKILL.md is correctly caught by create-backlog-skill.sh"
exit "$FAIL"
