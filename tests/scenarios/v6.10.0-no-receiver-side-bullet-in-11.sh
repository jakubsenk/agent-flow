#!/usr/bin/env bash
# AC: AC-T3-8-1
# Asserts the 11 newly-patched agents do NOT contain the extended
# 'Receiver-side EXTERNAL INPUT defense' bullet (single-line only).
# (The 2 pre-existing agents fixer + triage-analyst may have it — OK.)
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../" && pwd)"

FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

TARGET_AGENTS=(
  "spec-reviewer" "spec-writer" "rollback-agent" "sprint-planner"
  "scaffolder" "stack-selector" "deployment-verifier" "publisher"
  "test-engineer" "e2e-test-engineer" "backlog-creator"
)

for agent in "${TARGET_AGENTS[@]}"; do
  f="$REPO_ROOT/agents/${agent}.md"
  [ -f "$f" ] || { echo "TODO(phase-7-fixer): $agent not yet patched"; continue; }
  if grep -qF 'Receiver-side EXTERNAL INPUT defense' "$f"; then
    fail "$agent: must NOT contain 'Receiver-side EXTERNAL INPUT defense' bullet (single-line NEVER only)"
  fi
done

# Verify the 2 pre-existing extended agents still have it (regression guard)
for agent in "fixer" "triage-analyst"; do
  f="$REPO_ROOT/agents/${agent}.md"
  [ -f "$f" ] || continue
  if ! grep -qiE 'Receiver-side|EXTERNAL INPUT' "$f"; then
    fail "$agent: expected to still have EXTERNAL INPUT defense (regression)"
  fi
done

echo "PASS: no extended receiver-side bullet in 11 new agents"
exit "$FAIL"
