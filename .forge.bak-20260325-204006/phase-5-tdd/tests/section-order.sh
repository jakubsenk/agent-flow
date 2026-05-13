#!/usr/bin/env bash
# Test: All 18 agents follow Goal → Expertise → Process → Constraints section order
# Validates: section order per CLAUDE.md agent definition format
# PR 0: Bug fixes — structural correctness
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../../" && pwd)"

FAIL=0
fail() { echo "FAIL: $1"; FAIL=1; }

AGENTS=(
  triage-analyst code-analyst fixer reviewer acceptance-gate
  test-engineer e2e-test-engineer publisher rollback-agent spec-analyst
  architect stack-selector scaffolder priority-engine spec-writer
  spec-reviewer reproducer browser-verifier
)

for agent in "${AGENTS[@]}"; do
  file="$REPO_ROOT/agents/$agent.md"
  if [ ! -f "$file" ]; then
    fail "Missing agent file: agents/$agent.md"
    continue
  fi

  goal_line=$(grep -n "^## Goal" "$file" | head -1 | cut -d: -f1)
  expertise_line=$(grep -n "^## Expertise" "$file" | head -1 | cut -d: -f1)
  process_line=$(grep -n "^## Process" "$file" | head -1 | cut -d: -f1)
  constraints_line=$(grep -n "^## Constraints" "$file" | head -1 | cut -d: -f1)

  if [ -z "$goal_line" ]; then
    fail "$agent.md missing ## Goal section"
    continue
  fi
  if [ -z "$expertise_line" ]; then
    fail "$agent.md missing ## Expertise section"
    continue
  fi
  if [ -z "$process_line" ]; then
    fail "$agent.md missing ## Process section"
    continue
  fi
  if [ -z "$constraints_line" ]; then
    fail "$agent.md missing ## Constraints section"
    continue
  fi

  if [ "$goal_line" -ge "$expertise_line" ]; then
    fail "$agent.md: ## Goal must come before ## Expertise (lines $goal_line vs $expertise_line)"
  fi
  if [ "$expertise_line" -ge "$process_line" ]; then
    fail "$agent.md: ## Expertise must come before ## Process (lines $expertise_line vs $process_line)"
  fi
  if [ "$process_line" -ge "$constraints_line" ]; then
    fail "$agent.md: ## Process must come before ## Constraints (lines $process_line vs $constraints_line)"
  fi
done

[ "$FAIL" -eq 0 ] && echo "PASS: All 18 agents follow Goal → Expertise → Process → Constraints section order"
exit "$FAIL"
