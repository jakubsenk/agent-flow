#!/usr/bin/env bash
# Test: workflow-router has intent rows for create-backlog and sprint-plan
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"

FAIL=0
fail() { echo "FAIL: $1"; FAIL=1; }

ROUTER_FILE="$REPO_ROOT/skills/workflow-router/SKILL.md"

# 1. workflow-router skill must exist
if [ ! -f "$ROUTER_FILE" ]; then
  fail "skills/workflow-router/SKILL.md does not exist"
  exit 1
fi

# 2. create-backlog intent row exists
if ! grep -qi "create-backlog\|create backlog\|createbacklog" "$ROUTER_FILE"; then
  fail "skills/workflow-router/SKILL.md missing intent row for create-backlog"
fi

# 3. sprint-plan intent row exists
if ! grep -qi "sprint-plan\|sprint plan\|sprintplan" "$ROUTER_FILE"; then
  fail "skills/workflow-router/SKILL.md missing intent row for sprint-plan"
fi

# 4. Intent rows follow table format (| ... | ... |)
# At least 2 create-backlog / sprint-plan rows must be in a table
backlog_table=$(grep -i "create.backlog\|create-backlog" "$ROUTER_FILE" | grep -c "|" || true)
sprint_table=$(grep -i "sprint.plan\|sprint-plan" "$ROUTER_FILE" | grep -c "|" || true)

if [ "$backlog_table" -lt 1 ]; then
  fail "skills/workflow-router/SKILL.md create-backlog intent does not appear in a table row"
fi
if [ "$sprint_table" -lt 1 ]; then
  fail "skills/workflow-router/SKILL.md sprint-plan intent does not appear in a table row"
fi

[ "$FAIL" -eq 0 ] && echo "PASS: skills/workflow-router/SKILL.md has table intent rows for both create-backlog and sprint-plan"
exit "$FAIL"
