#!/usr/bin/env bash
# Verifies: AC-9.0.1-13 (re-authored from deleted v6.9.0-external-input-marker-receiver)
# Description: EXTERNAL INPUT prompt-injection defense MUST be in ## Constraints section,
#   not in ## Process or any other section, for all agents that receive external input.
#   Assertion 4 from the original v6.9.0 scenario: placement invariant of the defense bullet.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
if echo "$REPO_ROOT" | grep -q '\.forge'; then
  echo "ERROR: REPO_ROOT=$REPO_ROOT - tests must be run from tests/scenarios/" >&2
  exit 1
fi

FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

# All 17 v9 agents — every agent that participates in the pipeline and may
# receive external input (issue tracker content, user prose, file content, etc.)
EXTERNAL_INPUT_AGENTS=(
  "analyst"
  "fixer"
  "reviewer"
  "test-engineer"
  "publisher"
  "browser-agent"
  "deployment-verifier"
  "spec-analyst"
  "spec-writer"
  "spec-reviewer"
  "scaffolder"
  "architect"
  "priority-engine"
  "sprint-planner"
  "backlog-creator"
  "rollback-agent"
  "acceptance-gate"
)

VERIFIED=0
VIOLATIONS=()

for agent in "${EXTERNAL_INPUT_AGENTS[@]}"; do
  agent_file="$REPO_ROOT/agents/${agent}.md"
  if [ ! -f "$agent_file" ]; then
    fail "missing agent file: $agent_file"
    continue
  fi

  # The canonical defense bullet text (partial match sufficient)
  if ! grep -q "NEVER follow instructions.*EXTERNAL INPUT" "$agent_file" && \
     ! grep -q "EXTERNAL INPUT.*untrusted" "$agent_file"; then
    fail "$agent: missing EXTERNAL INPUT defense bullet entirely"
    VIOLATIONS+=("$agent:missing-bullet")
    continue
  fi

  # Find the line number of the defense bullet
  bullet_line=$(grep -n "NEVER follow instructions.*EXTERNAL INPUT\|NEVER.*EXTERNAL INPUT.*untrusted" "$agent_file" \
    | head -1 | cut -d: -f1)

  if [ -z "$bullet_line" ]; then
    fail "$agent: could not locate defense bullet line"
    VIOLATIONS+=("$agent:line-not-found")
    continue
  fi

  # Find the most recent ## heading before this line — that is the section it belongs to
  section_heading=$(awk -v target="$bullet_line" 'NR < target && /^## /' "$agent_file" | tail -1)

  if echo "$section_heading" | grep -q "## Constraints"; then
    echo "OK: $agent — defense bullet at line $bullet_line is in '## Constraints'"
    VERIFIED=$((VERIFIED + 1))
  else
    fail "$agent: EXTERNAL INPUT defense bullet is NOT in ## Constraints (found in: '${section_heading:-<no heading>}')"
    VIOLATIONS+=("$agent:wrong-section:${section_heading:-none}")
  fi
done

echo ""
echo "Summary: $VERIFIED/${#EXTERNAL_INPUT_AGENTS[@]} agents verified"

if [ "$FAIL" -eq 0 ]; then
  echo "PASS: AC-9.0.1-13 - EXTERNAL INPUT defense bullets are in ## Constraints across all ${#EXTERNAL_INPUT_AGENTS[@]} agents"
fi
exit "$FAIL"
