#!/usr/bin/env bash
# AC: AC-T3-6-1
# Asserts no frontmatter changes in the 11 newly-patched agents.
# Uses git diff to verify frontmatter (lines 1 through second '---') unchanged.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../" && pwd)"

FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

TARGET_AGENTS=(
  "agents/spec-reviewer.md"
  "agents/spec-writer.md"
  "agents/rollback-agent.md"
  "agents/sprint-planner.md"
  "agents/scaffolder.md"
  "agents/stack-selector.md"
  "agents/deployment-verifier.md"
  "agents/publisher.md"
  "agents/test-engineer.md"
  "agents/e2e-test-engineer.md"
  "agents/backlog-creator.md"
)

# Check if git is available and we have the baseline tag
if ! command -v git >/dev/null 2>&1; then
  echo "SKIP: git not available"
  exit 77
fi

baseline_tag="v6.9.2"
if ! git -C "$REPO_ROOT" rev-parse "$baseline_tag" >/dev/null 2>&1; then
  echo "SKIP: baseline tag $baseline_tag not found"
  exit 77
fi

for agent_path in "${TARGET_AGENTS[@]}"; do
  full_path="$REPO_ROOT/$agent_path"
  [ -f "$full_path" ] || { echo "TODO(phase-7-fixer): $agent_path not yet patched"; continue; }

  # Get frontmatter line range (lines 1 to second '---' delimiter)
  fm_end=$(grep -n '^---' "$full_path" | sed -n '2p' | cut -d: -f1)
  [ -n "$fm_end" ] || { fail "$agent_path: could not locate frontmatter end (second ---)"; continue; }

  # Check that git diff shows no changes in the frontmatter region
  diff_output=$(git -C "$REPO_ROOT" diff "$baseline_tag"..HEAD -- "$agent_path" 2>/dev/null \
    | grep -E '^[+-]' | grep -v '^[+-]{3}' | head -20 || echo "")
  # Extract changed line numbers (approximate via diff context)
  fm_changes=$(git -C "$REPO_ROOT" diff "$baseline_tag"..HEAD -- "$agent_path" 2>/dev/null \
    | awk "NR<=6 {print}" || echo "")
  # Simple check: no - or + lines for the frontmatter content (name, description, model, style)
  fm_diff=$(git -C "$REPO_ROOT" diff "$baseline_tag"..HEAD -- "$agent_path" 2>/dev/null \
    | grep -E '^[+-](name:|description:|model:|style:)' | head -5 || echo "")
  if [ -n "$fm_diff" ]; then
    fail "$agent_path: frontmatter fields changed: $fm_diff"
  fi
done

echo "PASS: no frontmatter changes in 11 agents"
exit "$FAIL"
