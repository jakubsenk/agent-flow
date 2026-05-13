#!/usr/bin/env bash
# Hidden mutation test: Temporarily rename skills/sprint-plan/SKILL.md and verify that
# sprint-plan-skill.sh FAILS, then restore the file.
# This validates that sprint-plan-skill.sh correctly catches a missing skill.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"

FAIL=0
fail() { echo "FAIL: $1"; FAIL=1; }

SKILL_FILE="$REPO_ROOT/skills/sprint-plan/SKILL.md"
SKILL_BACKUP="$REPO_ROOT/skills/sprint-plan/SKILL.md.mutation_bak"
TEST_SCRIPT="$REPO_ROOT/.forge/phase-5-tdd/tests/sprint-plan-skill.sh"

# Prerequisite: test script must exist
if [ ! -f "$TEST_SCRIPT" ]; then
  fail "Visible test sprint-plan-skill.sh not found at $TEST_SCRIPT"
  exit 1
fi

# If the skill file doesn't exist yet (pre-implementation), just confirm the visible test fails
if [ ! -f "$SKILL_FILE" ]; then
  if bash "$TEST_SCRIPT" > /dev/null 2>&1; then
    fail "MUTATION: sprint-plan-skill.sh PASSED even though skills/sprint-plan/SKILL.md does not exist — test is not detecting missing file"
  else
    echo "OK: sprint-plan-skill.sh correctly fails when skills/sprint-plan/SKILL.md is absent"
  fi
  [ "$FAIL" -eq 0 ] && echo "PASS: mutation-remove-sprint-plan — test correctly detects absent skill"
  exit "$FAIL"
fi

# Skill exists — perform rename mutation
mv "$SKILL_FILE" "$SKILL_BACKUP"

# Run the visible test — it MUST fail
if bash "$TEST_SCRIPT" > /dev/null 2>&1; then
  mv "$SKILL_BACKUP" "$SKILL_FILE"
  fail "MUTATION ESCAPED: sprint-plan-skill.sh passed even with skills/sprint-plan/SKILL.md removed"
else
  echo "OK: sprint-plan-skill.sh correctly fails when skills/sprint-plan/SKILL.md is removed"
fi

# Restore
mv "$SKILL_BACKUP" "$SKILL_FILE"

[ "$FAIL" -eq 0 ] && echo "PASS: mutation-remove-sprint-plan — removal of skills/sprint-plan/SKILL.md is correctly caught by sprint-plan-skill.sh"
exit "$FAIL"
