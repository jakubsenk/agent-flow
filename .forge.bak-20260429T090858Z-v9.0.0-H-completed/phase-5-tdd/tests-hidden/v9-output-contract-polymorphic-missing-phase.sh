#!/bin/bash
# PURPOSE: (HIDDEN) Adversarial test for polymorphic completeness. If analyst.md defines the
#          ## Output Contract — Phase: triage sub-block but is MISSING ## Output Contract — Phase: impact,
#          this scenario must FAIL. Similarly for any partially-implemented polymorphic agent.
#          Complements the visible v9-output-contract-polymorphic-split.sh but focuses on the
#          "only one phase defined" failure mode.
# AC-H-N covered: AC-H-010..AC-H-013 (adversarial completeness variant)
# INVOKED BY: tests/harness/run-tests.sh (hidden)
# EXPECTED ON v8.0.0: SKIP (no agents have ## Output Contract sections)
# EXPECTED ON v9.0.0: PASS (all 4 polymorphic agents have BOTH required sub-blocks)
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
if echo "$REPO_ROOT" | grep -q '\.forge'; then
  echo "ERROR: REPO_ROOT=$REPO_ROOT — tests must be run from tests/scenarios/ after Phase 7 staging" >&2
  exit 1
fi

FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

AGENTS_DIR="$REPO_ROOT/agents"

# Define polymorphic agents and their required sub-block pairs
# Format: "agent_name|block_a_unique_fragment|block_b_unique_fragment"
# We use unique fragments to avoid false positives from grepping
POLY_CHECKS=(
  "analyst|Phase: triage|Phase: impact"
  "test-engineer|Default (no flag)|Phase: --e2e"
  "browser-agent|Phase: reproduce|Phase: verify"
  "spec-reviewer|Default (review mode)|Phase: --verify"
)

all_skipped=1

for check in "${POLY_CHECKS[@]}"; do
  agent_name=$(echo "$check" | cut -d'|' -f1)
  frag_a=$(echo "$check" | cut -d'|' -f2)
  frag_b=$(echo "$check" | cut -d'|' -f3)
  agent_file="$AGENTS_DIR/${agent_name}.md"

  if [ ! -f "$agent_file" ]; then
    continue
  fi

  if ! grep -qE '^## Output Contract$' "$agent_file"; then
    continue
  fi

  all_skipped=0

  # Extract ## Output Contract section
  oc_section=$(awk '/^## Output Contract$/{found=1; next} found && /^## [A-Z][^#]/{exit} found{print}' "$agent_file")

  # Count how many sub-blocks are present
  sub_block_count=$(echo "$oc_section" | grep -cE '^### Output Contract' || true)

  # Assert both expected fragments are present
  has_a=$(echo "$oc_section" | grep -cF "$frag_a" || true)
  has_b=$(echo "$oc_section" | grep -cF "$frag_b" || true)

  if [ "$has_a" -eq 0 ] && [ "$has_b" -gt 0 ]; then
    fail "$agent_name: has sub-block fragment '$frag_b' but MISSING '$frag_a' — half-implemented polymorphic Output Contract"
    # Mutation catch: adding only one phase sub-block fails here
  elif [ "$has_a" -gt 0 ] && [ "$has_b" -eq 0 ]; then
    fail "$agent_name: has sub-block fragment '$frag_a' but MISSING '$frag_b' — half-implemented polymorphic Output Contract"
  elif [ "$has_a" -eq 0 ] && [ "$has_b" -eq 0 ]; then
    fail "$agent_name: both phase sub-block fragments missing ('$frag_a', '$frag_b') — ## Output Contract section is empty or non-polymorphic"
  fi

  # Adversarial check: assert sub_block_count >= 2 (can't have just 1 block for a 2-phase agent)
  if [ "$sub_block_count" -lt 2 ]; then
    fail "$agent_name: ## Output Contract has only $sub_block_count '### Output Contract' sub-block(s), need at least 2 for polymorphic agent"
    # Mutation catch: merging two phase blocks into one fails here
  fi
done

if [ "$all_skipped" -eq 1 ]; then
  echo "SKIP: no polymorphic agents have ## Output Contract sections yet (v8.0.0 baseline)" >&2
  exit 77
fi

if [ "$FAIL" -eq 0 ]; then
  echo "PASS: AC-H-010..H-013 (adversarial) — all 4 polymorphic agents have BOTH required phase sub-blocks in ## Output Contract"
fi
exit "$FAIL"
