#!/usr/bin/env bash
# Test: skills/sprint-plan/SKILL.md handles all 6 tracker types for sprint_assign dispatch
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

FAIL=0
fail() { echo "FAIL: $1"; FAIL=1; }

SKILL_FILE="$REPO_ROOT/skills/sprint-plan/SKILL.md"

# 1. File must exist
if [ ! -f "$SKILL_FILE" ]; then
  fail "skills/sprint-plan/SKILL.md does not exist"
  exit 1
fi

# 2. All 6 tracker types must be referenced for sprint assignment
TRACKERS=("youtrack" "jira" "linear" "redmine" "github" "gitea")

for tracker in "${TRACKERS[@]}"; do
  if ! grep -qi "$tracker" "$SKILL_FILE"; then
    fail "skills/sprint-plan/SKILL.md missing tracker type coverage: $tracker"
  fi
done

# 3. Skill references sprint assignment operation
if ! grep -qi "sprint.*assign\|assign.*sprint\|sprint_assign\|sprint field\|sprint version\|iteration\|milestone" "$SKILL_FILE"; then
  fail "skills/sprint-plan/SKILL.md must reference sprint assignment operation (sprint_assign/iteration/milestone)"
fi

# 4. Skill references sprint-planner agent dispatch
if ! grep -qi "sprint-planner" "$SKILL_FILE"; then
  fail "skills/sprint-plan/SKILL.md must reference sprint-planner agent dispatch"
fi

[ "$FAIL" -eq 0 ] && echo "PASS: skills/sprint-plan/SKILL.md handles all 6 tracker types for sprint assignment and references sprint-planner dispatch"
exit "$FAIL"
