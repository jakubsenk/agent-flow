#!/usr/bin/env bash
# Test: All 18 agents have all 4 required frontmatter fields
# Validates: name, description, model, style are present in every agent's frontmatter
# PR 0: Bug fixes — structural completeness
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
  for field in name description model style; do
    if ! grep -q "^$field:" "$file"; then
      fail "$agent.md missing frontmatter field: $field"
    fi
  done
done

[ "$FAIL" -eq 0 ] && echo "PASS: All 18 agents have all 4 required frontmatter fields (name, description, model, style)"
exit "$FAIL"
