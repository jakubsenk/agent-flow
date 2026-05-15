#!/usr/bin/env bash
# Test: implement-feature.md dispatches all required agents and each has a corresponding file
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

FAIL=0
fail() { echo "FAIL: $1"; FAIL=1; }

IF="$REPO_ROOT/skills/implement-feature/SKILL.md"
IF_STEPS_DIR="$REPO_ROOT/skills/implement-feature/steps"

if [ ! -f "$IF" ]; then
  fail "skills/implement-feature/SKILL.md does not exist"
  exit "$FAIL"
fi

# v10 thin-controller: dispatch detail lives in steps/*.md. Aggregate SKILL.md + steps/*.md.
IF_AGGREGATE=$(cat "$IF" 2>/dev/null; [ -d "$IF_STEPS_DIR" ] && cat "$IF_STEPS_DIR"/*.md 2>/dev/null)

# 1. Verify implement-feature.md contains Task tool dispatches for all required agents
REQUIRED_AGENTS=(
  spec-analyst
  architect
  fixer
  reviewer
  test-engineer
  publisher
  acceptance-gate
)

for agent in "${REQUIRED_AGENTS[@]}"; do
  # Search files directly (avoids large-variable printf issues on Linux)
  if ! grep -rqiE "$agent.*(Task tool|subagent_type)|(Task tool|subagent_type).*$agent" "$IF" "$IF_STEPS_DIR/" 2>/dev/null; then
    if ! grep -rqiE "(agent-flow:$agent|the $agent agent|Run $agent)" "$IF" "$IF_STEPS_DIR/" 2>/dev/null; then
      fail "implement-feature.md does not dispatch agent: $agent"
    fi
  fi
done

# 2. Verify rollback-agent is referenced — either in the skill aggregate or in core/block-handler.md
BLOCK_HANDLER="$REPO_ROOT/core/block-handler.md"
if ! grep -rq "rollback-agent" "$IF" "$IF_STEPS_DIR/" 2>/dev/null; then
  if ! grep -rq "core/block-handler" "$IF" "$IF_STEPS_DIR/" 2>/dev/null; then
    fail "implement-feature.md does not reference rollback-agent or core/block-handler.md"
  elif [ ! -f "$BLOCK_HANDLER" ]; then
    fail "implement-feature.md delegates to core/block-handler.md but that file does not exist"
  elif ! grep -q "rollback-agent" "$BLOCK_HANDLER"; then
    fail "core/block-handler.md does not reference rollback-agent"
  fi
fi

# 3. Verify each agent name references an existing file in agents/
ALL_REFERENCED_AGENTS=(
  spec-analyst
  architect
  fixer
  reviewer
  test-engineer
  publisher
  acceptance-gate
  rollback-agent
)

for agent in "${ALL_REFERENCED_AGENTS[@]}"; do
  agent_file="$REPO_ROOT/agents/$agent.md"
  if [ ! -f "$agent_file" ]; then
    fail "implement-feature.md references $agent but agents/$agent.md does not exist"
  fi
done

[ "$FAIL" -eq 0 ] && echo "PASS: implement-feature.md dispatches all required agents and each has a corresponding agent file"
exit "$FAIL"
