#!/usr/bin/env bash
# Test: skills/create-backlog/SKILL.md handles all 6 tracker types for issue creation dispatch
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"

FAIL=0
fail() { echo "FAIL: $1"; FAIL=1; }

SKILL_FILE="$REPO_ROOT/skills/create-backlog/SKILL.md"

# 1. File must exist
if [ ! -f "$SKILL_FILE" ]; then
  fail "skills/create-backlog/SKILL.md does not exist"
  exit 1
fi

# 2. All 6 tracker types must be referenced
TRACKERS=("youtrack" "jira" "linear" "redmine" "github" "gitea")

for tracker in "${TRACKERS[@]}"; do
  if ! grep -qi "$tracker" "$SKILL_FILE"; then
    fail "skills/create-backlog/SKILL.md missing tracker type: $tracker"
  fi
done

# 3. Skill references backlog-creator agent dispatch
if ! grep -qi "backlog-creator" "$SKILL_FILE"; then
  fail "skills/create-backlog/SKILL.md must reference backlog-creator agent dispatch"
fi

# 4. Skill references issue creation (creating issues in tracker)
if ! grep -qi "creat.*issue\|issue.*creat\|creat.*task\|task.*creat\|tracker" "$SKILL_FILE"; then
  fail "skills/create-backlog/SKILL.md must reference issue/task creation in tracker"
fi

[ "$FAIL" -eq 0 ] && echo "PASS: skills/create-backlog/SKILL.md handles all 6 tracker types (youtrack, jira, linear, redmine, github, gitea) and references backlog-creator dispatch"
exit "$FAIL"
