#!/bin/bash
# PURPOSE: Hard enforcement gate — every agent file under agents/*.md MUST have a ## Output Contract
#          section. No SKIP-guard. This is the mandatory contract assertion (REQ-H-001, REQ-H-033).
# AC-H-N covered: AC-H-001, AC-H-004
# INVOKED BY: tests/harness/run-tests.sh
# EXPECTED ON v8.0.0: FAIL (no agent has ## Output Contract yet)
# EXPECTED ON v9.0.0: PASS (all 17 agents have ## Output Contract)
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
if echo "$REPO_ROOT" | grep -q '\.forge'; then
  echo "ERROR: REPO_ROOT=$REPO_ROOT — tests must be run from tests/scenarios/ after Phase 7 staging" >&2
  exit 1
fi

FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

AGENTS_DIR="$REPO_ROOT/agents"
if [ ! -d "$AGENTS_DIR" ]; then
  fail "agents/ directory not found at $AGENTS_DIR"
  exit 1
fi

agent_count=0
missing_count=0

for agent_file in "$AGENTS_DIR"/*.md; do
  agent_name=$(basename "$agent_file" .md)
  agent_count=$((agent_count + 1))

  # Primary assertion: ## Output Contract heading must exist (REQ-H-001)
  if ! grep -qE '^## Output Contract$' "$agent_file"; then
    fail "$agent_name: missing '## Output Contract' section — mandatory per REQ-H-001"
    missing_count=$((missing_count + 1))
  fi

  # Secondary assertion: no agent may claim ## Project-Specific Instructions (reserved heading REQ-H-022 / AC-H-004)
  if grep -qE '^## Project-Specific Instructions$' "$agent_file"; then
    fail "$agent_name: contains reserved heading '## Project-Specific Instructions' — this heading is reserved for the override injector"
    # Mutation catch: if someone accidentally adds this heading to an agent, it is caught here
  fi
done

if [ "$agent_count" -eq 0 ]; then
  fail "No agent files found in $AGENTS_DIR — harness misconfigured"
  exit 1
fi

# Negative assertion: verify v9.0.0 deletes stack-selector (post-deletion agent count = 17)
# On v8.0.0, stack-selector exists so this assertion FAILS (which is expected v8.0.0 behavior)
if [ -f "$AGENTS_DIR/stack-selector.md" ]; then
  fail "agents/stack-selector.md still exists — must be deleted per REQ-H-080 (AC-H-040)"
  # Mutation catch: forgetting to delete stack-selector.md fails here
fi

if [ "$FAIL" -eq 0 ]; then
  echo "PASS: AC-H-001, AC-H-004 — all $agent_count agents have '## Output Contract' section; no reserved headings found"
fi
exit "$FAIL"
