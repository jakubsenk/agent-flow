#!/usr/bin/env bash
# Test: skills/sprint-plan/SKILL.md references priority-engine agent dispatch
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

# 2. References priority-engine agent
if ! grep -qi "priority-engine" "$SKILL_FILE"; then
  fail "skills/sprint-plan/SKILL.md must reference priority-engine agent dispatch"
fi

# 3. References capacity (team capacity / sprint capacity)
if ! grep -qi "capacity" "$SKILL_FILE"; then
  fail "skills/sprint-plan/SKILL.md must reference capacity (team capacity for sprint planning)"
fi

# 4. References priorit* (prioritization / priority / prioritize)
if ! grep -qi "priorit" "$SKILL_FILE"; then
  fail "skills/sprint-plan/SKILL.md must reference prioritization logic"
fi

[ "$FAIL" -eq 0 ] && echo "PASS: skills/sprint-plan/SKILL.md references priority-engine dispatch with capacity and prioritization"
exit "$FAIL"
