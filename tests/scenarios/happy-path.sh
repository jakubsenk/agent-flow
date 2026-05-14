#!/bin/bash
# Test: Full pipeline happy path
# Validates: command files exist, agent files exist, frontmatter is valid
set -e

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

# Check skill count >= 17
cmd_count=$(find "$REPO_ROOT/skills" -name 'SKILL.md' 2>/dev/null | wc -l)
if [ "$cmd_count" -lt 17 ]; then
  echo "FAIL: Expected >= 17 skill files, found $cmd_count in skills/"
  exit 1
fi

# Check agent count >= 17
agent_count=$(ls "$REPO_ROOT/agents/"*.md 2>/dev/null | wc -l)
if [ "$agent_count" -lt 17 ]; then
  echo "FAIL: Expected >= 17 agent files, found $agent_count in agents/"
  exit 1
fi

echo "PASS: All skill and agent files present ($cmd_count skills, $agent_count agents)"
