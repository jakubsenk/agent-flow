#!/bin/bash
# PURPOSE: (HIDDEN) Hard assertion that agents/stack-selector.md does NOT exist on v9.0.0 and
#          that skills/scaffold/SKILL.md no longer references stack-selector in prose text.
#          Also checks rollback-agent.md no longer lists stack-selector in its skip list.
# AC-H-N covered: AC-H-040, AC-H-041, AC-H-042, AC-H-043
# INVOKED BY: tests/harness/run-tests.sh (hidden)
# EXPECTED ON v8.0.0: FAIL (stack-selector.md exists; scaffold SKILL.md references it)
# EXPECTED ON v9.0.0: PASS (file deleted; no residual references)
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
if echo "$REPO_ROOT" | grep -q '\.forge'; then
  echo "ERROR: REPO_ROOT=$REPO_ROOT — tests must be run from tests/scenarios/ after Phase 7 staging" >&2
  exit 1
fi

FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

# AC-H-040: agents/stack-selector.md must NOT exist
if [ -f "$REPO_ROOT/agents/stack-selector.md" ]; then
  fail "agents/stack-selector.md still exists — must be deleted per REQ-H-080"
  # Mutation catch: forgetting to delete the file fails here
fi

# AC-H-041: skills/scaffold/SKILL.md must not reference 'stack-selector'
SCAFFOLD_SKILL="$REPO_ROOT/skills/scaffold/SKILL.md"
if [ -f "$SCAFFOLD_SKILL" ]; then
  if grep -qE 'stack-selector' "$SCAFFOLD_SKILL"; then
    fail "skills/scaffold/SKILL.md still contains 'stack-selector' reference — must be removed per REQ-H-080"
    # Mutation catch: leaving the legacy stack-selector prose in scaffold SKILL.md fails here
  fi
else
  fail "skills/scaffold/SKILL.md not found — sanity check"
fi

# AC-H-042: agents/rollback-agent.md must not list 'stack-selector' in its skip list
ROLLBACK_AGENT="$REPO_ROOT/agents/rollback-agent.md"
if [ -f "$ROLLBACK_AGENT" ]; then
  if grep -qE 'stack-selector' "$ROLLBACK_AGENT"; then
    fail "agents/rollback-agent.md still contains 'stack-selector' — must be removed from skip list per REQ-H-083"
    # Mutation catch: leaving stack-selector in the rollback agent's skip list fails here
  fi
else
  fail "agents/rollback-agent.md not found"
fi

# AC-H-043: no skills/**/*.md must contain subagent_type='ceos-agents:stack-selector'
stack_dispatch=$(grep -rnE "ceos-agents:stack-selector" "$REPO_ROOT/skills/" --include="*.md" 2>/dev/null || true)
if [ -n "$stack_dispatch" ]; then
  fail "skills/ still contains 'ceos-agents:stack-selector' dispatch reference: $stack_dispatch"
fi

# Additional: CLAUDE.md agent enumeration must not list stack-selector
if grep -qF 'stack-selector' "$REPO_ROOT/CLAUDE.md"; then
  fail "CLAUDE.md still mentions 'stack-selector' in agents enumeration — must be removed per REQ-H-082"
fi

if [ "$FAIL" -eq 0 ]; then
  echo "PASS: AC-H-040..H-043 — stack-selector.md deleted; no residual references in scaffold SKILL, rollback-agent, skills dispatch, or CLAUDE.md"
fi
exit "$FAIL"
