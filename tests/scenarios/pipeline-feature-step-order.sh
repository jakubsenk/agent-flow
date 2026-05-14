#!/usr/bin/env bash
# Test: implement-feature step files exist in numbered order and key agents
# are dispatched in correct sequence across the step files.
# v10 thin-controller layout: SKILL.md sequences via step dispatch table;
# detail lives in skills/implement-feature/steps/0N-*.md.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
CMD_FILE="$REPO_ROOT/skills/implement-feature/SKILL.md"
STEPS_DIR="$REPO_ROOT/skills/implement-feature/steps"

FAIL=0
fail() { echo "FAIL: $1"; FAIL=1; }

if [ ! -f "$CMD_FILE" ]; then
  fail "skills/implement-feature/SKILL.md not found"
  exit 1
fi

if [ ! -d "$STEPS_DIR" ]; then
  fail "skills/implement-feature/steps/ directory not found"
  exit 1
fi

# -----------------------------------------------------------------------
# 1. Step files must exist in numbered order: 01-..., 02-..., ..., 08-...
# -----------------------------------------------------------------------
STEP_FILES=()
for n in 01 02 03 04 05 06 07 08; do
  matches=$(ls "$STEPS_DIR"/${n}-*.md 2>/dev/null | head -1)
  if [ -z "$matches" ]; then
    fail "Step file '${n}-*.md' missing in skills/implement-feature/steps/"
  else
    STEP_FILES+=("$matches")
  fi
done

# -----------------------------------------------------------------------
# 2. Each key agent must be dispatched somewhere in the step files
# -----------------------------------------------------------------------
get_step_for_agent() {
  local agent="$1"
  for sf in "${STEP_FILES[@]}"; do
    if grep -qiE "agent-flow:${agent}\b|Run the ${agent} agent|the ${agent} agent|subagent_type[^a-zA-Z]+${agent}" "$sf"; then
      basename "$sf"
      return
    fi
  done
  echo ""
}

get_step_num() {
  local fname="$1"
  echo "$fname" | sed -E 's/^([0-9]+)-.*/\1/'
}

SPEC_STEP=$(get_step_for_agent "spec-analyst")
ARCHITECT_STEP=$(get_step_for_agent "architect")
FIXER_STEP=$(get_step_for_agent "fixer")
REVIEWER_STEP=$(get_step_for_agent "reviewer")
TEST_STEP=$(get_step_for_agent "test-engineer")
PUBLISHER_STEP=$(get_step_for_agent "publisher")

check_order() {
  local a_name="$1"
  local a_file="$2"
  local b_name="$3"
  local b_file="$4"
  if [ -z "$a_file" ]; then
    fail "Could not find dispatch of '$a_name' in implement-feature steps"
    return
  fi
  if [ -z "$b_file" ]; then
    fail "Could not find dispatch of '$b_name' in implement-feature steps"
    return
  fi
  local a_num
  a_num=$(get_step_num "$a_file")
  local b_num
  b_num=$(get_step_num "$b_file")
  if [ "$a_num" -gt "$b_num" ]; then
    fail "Agent order violated: '$a_name' (step $a_num) must appear before '$b_name' (step $b_num)"
  fi
}

check_order "spec-analyst"  "$SPEC_STEP"      "architect"      "$ARCHITECT_STEP"
check_order "architect"     "$ARCHITECT_STEP" "fixer"          "$FIXER_STEP"
# fixer and reviewer live in the same loop step (04), so they can be in the same file.
if [ "$FIXER_STEP" != "$REVIEWER_STEP" ]; then
  check_order "fixer" "$FIXER_STEP" "reviewer" "$REVIEWER_STEP"
fi
check_order "reviewer"      "$REVIEWER_STEP"  "test-engineer"  "$TEST_STEP"
check_order "test-engineer" "$TEST_STEP"      "publisher"      "$PUBLISHER_STEP"

# -----------------------------------------------------------------------
# 3. SKILL.md must reference the step dispatch table + block handler
# -----------------------------------------------------------------------
if ! grep -qE 'Step dispatch|Step Dispatch' "$CMD_FILE"; then
  fail "SKILL.md does not have a 'Step dispatch' table"
fi

if ! grep -qiE 'Block handler|block-handler' "$CMD_FILE"; then
  fail "SKILL.md does not reference Block handler"
fi

[ "$FAIL" -eq 0 ] && echo "PASS: implement-feature step files are numbered, agent dispatch order is correct (v10 thin-controller layout)"
exit "$FAIL"
