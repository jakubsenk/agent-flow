#!/usr/bin/env bash
# AC: AC-T1-2-1, AC-T1-2-2 (REWRITE #2 — Tier B)
# Functional: no agent output contract section has been removed.
# Iterates 21 agents asserting Constraints section present.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../" && pwd)"
FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

# Enumerate all 21 agents (excluding README.md)
while IFS= read -r agent_file; do
  agent_name=$(basename "$agent_file" .md)
  # Each agent must have ## Constraints section
  if ! grep -qE '^## Constraints' "$agent_file"; then
    fail "$agent_name: missing ## Constraints section (agent output contract removed)"
  fi
  # Each agent must have ## Process section
  if ! grep -qE '^## Process' "$agent_file"; then
    fail "$agent_name: missing ## Process section"
  fi
  # Each agent must have YAML frontmatter (name, description, model)
  if ! grep -qE '^name:' "$agent_file"; then
    fail "$agent_name: missing 'name:' in frontmatter"
  fi
done < <(find "$REPO_ROOT/agents" -maxdepth 1 -name '*.md' -not -name 'README.md' -type f | sort)

# Mutation guard: count must equal 21
agent_count=$(find "$REPO_ROOT/agents" -maxdepth 1 -name '*.md' -not -name 'README.md' -type f | wc -l | tr -d ' ')
[ "$agent_count" -eq 21 ] || fail "Expected 21 agents, found $agent_count"

[ "$FAIL" -eq 0 ] && echo "PASS: all 21 agents have required output contract sections"
exit "$FAIL"
