#!/bin/bash
# PURPOSE: Replacement for frontmatter-completeness.sh using the v9.0.0 17-agent roster.
#          Removes stale v7 names (triage-analyst, code-analyst, e2e-test-engineer, reproducer,
#          browser-verifier) and removes stack-selector. Validates 4 required frontmatter fields
#          (name, description, model, style) for all 17 v9 agents (REQ-H-037, AC-H-082).
# AC-H-N covered: AC-H-082
# INVOKED BY: tests/harness/run-tests.sh
# EXPECTED ON v8.0.0: FAIL (stack-selector.md present = 18 agents, not 17)
# EXPECTED ON v9.0.0: PASS (17 agents, all with correct frontmatter)
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
if echo "$REPO_ROOT" | grep -q '\.forge'; then
  echo "ERROR: REPO_ROOT=$REPO_ROOT — tests must be run from tests/scenarios/ after Phase 7 staging" >&2
  exit 1
fi

FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

# Post-v9.0.0 roster: 17 agents (stack-selector deleted per REQ-H-080)
AGENTS=(
  acceptance-gate analyst architect backlog-creator browser-agent
  deployment-verifier fixer priority-engine publisher reviewer
  rollback-agent scaffolder spec-analyst spec-reviewer spec-writer
  sprint-planner test-engineer
)

for agent in "${AGENTS[@]}"; do
  file="$REPO_ROOT/agents/$agent.md"
  if [ ! -f "$file" ]; then
    fail "Missing agent file: agents/$agent.md"
    continue
  fi
  for field in name description model style; do
    if ! grep -qE "^${field}:" "$file"; then
      fail "$agent.md missing frontmatter field: $field"
      # Mutation catch: removing any frontmatter field from any agent fails here
    fi
  done
done

# Assert stack-selector is NOT present (AC-H-040 / REQ-H-080)
if [ -f "$REPO_ROOT/agents/stack-selector.md" ]; then
  fail "agents/stack-selector.md exists — must be deleted per REQ-H-080; v9 roster has 17 agents"
fi

# Assert agent count is exactly 17
actual_count=$(find "$REPO_ROOT/agents" -maxdepth 1 -name "*.md" | wc -l)
if [ "$actual_count" -ne 17 ]; then
  fail "agents/ contains $actual_count .md files, expected exactly 17 for v9.0.0 roster"
  # Mutation catch: adding or forgetting to delete an agent file fails here
fi

# Negative assertions: stale v7 names must NOT be present
for stale in triage-analyst code-analyst e2e-test-engineer reproducer browser-verifier stack-selector; do
  if [ -f "$REPO_ROOT/agents/$stale.md" ]; then
    fail "Stale v7 agent file agents/$stale.md still exists — must be removed for v9.0.0"
  fi
done

[ "$FAIL" -eq 0 ] && echo "PASS: AC-H-082 — all 17 v9.0.0 agents have all 4 required frontmatter fields (name, description, model, style)"
exit "$FAIL"
