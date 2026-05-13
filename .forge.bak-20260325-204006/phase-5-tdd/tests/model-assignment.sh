#!/usr/bin/env bash
# Test: Agent model assignments match the CLAUDE.md table
# Validates: opus agents use opus, sonnet agents use sonnet, haiku agents use haiku
# PR 0: Bug fixes — model assignment correctness
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../../" && pwd)"

FAIL=0
fail() { echo "FAIL: $1"; FAIL=1; }

# opus agents: fixer, reviewer, architect, priority-engine, spec-writer, spec-reviewer
OPUS_AGENTS=(fixer reviewer architect priority-engine spec-writer spec-reviewer)
for agent in "${OPUS_AGENTS[@]}"; do
  file="$REPO_ROOT/agents/$agent.md"
  if [ ! -f "$file" ]; then
    fail "Missing agent file: agents/$agent.md"
    continue
  fi
  if ! grep -q "^model: opus$" "$file"; then
    fail "$agent.md must use model: opus (CLAUDE.md table)"
  fi
done

# sonnet agents: triage-analyst, code-analyst, test-engineer, e2e-test-engineer, spec-analyst,
#                stack-selector, scaffolder, acceptance-gate, reproducer, browser-verifier
SONNET_AGENTS=(
  triage-analyst code-analyst test-engineer e2e-test-engineer spec-analyst
  stack-selector scaffolder acceptance-gate reproducer browser-verifier
)
for agent in "${SONNET_AGENTS[@]}"; do
  file="$REPO_ROOT/agents/$agent.md"
  if [ ! -f "$file" ]; then
    fail "Missing agent file: agents/$agent.md"
    continue
  fi
  if ! grep -q "^model: sonnet$" "$file"; then
    fail "$agent.md must use model: sonnet (CLAUDE.md table)"
  fi
done

# haiku agents: publisher, rollback-agent
HAIKU_AGENTS=(publisher rollback-agent)
for agent in "${HAIKU_AGENTS[@]}"; do
  file="$REPO_ROOT/agents/$agent.md"
  if [ ! -f "$file" ]; then
    fail "Missing agent file: agents/$agent.md"
    continue
  fi
  if ! grep -q "^model: haiku$" "$file"; then
    fail "$agent.md must use model: haiku (CLAUDE.md table)"
  fi
done

[ "$FAIL" -eq 0 ] && echo "PASS: All 18 agents have correct model assignments (opus/sonnet/haiku)"
exit "$FAIL"
