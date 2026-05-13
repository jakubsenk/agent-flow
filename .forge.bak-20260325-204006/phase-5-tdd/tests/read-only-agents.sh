#!/usr/bin/env bash
# Test: Read-only agents do not contain write-tool phrases in their Process sections
# Validates: triage-analyst, code-analyst, reviewer, spec-analyst, architect, stack-selector,
#            priority-engine, spec-reviewer, acceptance-gate do not use Write tool / Edit tool /
#            create file in their Process sections
# PR 0: Bug fixes — read-only agent purity
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../../" && pwd)"

FAIL=0
fail() { echo "FAIL: $1"; FAIL=1; }

# Read-only agents per CLAUDE.md: triage-analyst, code-analyst, reviewer, spec-analyst,
# architect, stack-selector, priority-engine, spec-reviewer, acceptance-gate
READ_ONLY_AGENTS=(
  triage-analyst code-analyst reviewer spec-analyst architect
  stack-selector priority-engine spec-reviewer acceptance-gate
)

for agent in "${READ_ONLY_AGENTS[@]}"; do
  file="$REPO_ROOT/agents/$agent.md"
  if [ ! -f "$file" ]; then
    fail "Missing agent file: agents/$agent.md"
    continue
  fi

  # Extract content from ## Process section onward (up to ## Constraints)
  # Use awk to get the Process section only
  process_section=$(awk '/^## Process/{found=1} found && /^## Constraints/{found=0} found{print}' "$file")

  if echo "$process_section" | grep -qi "Write tool"; then
    fail "$agent.md Process section contains 'Write tool' — read-only agent must not write files"
  fi
  if echo "$process_section" | grep -qi "Edit tool"; then
    fail "$agent.md Process section contains 'Edit tool' — read-only agent must not edit files"
  fi
  if echo "$process_section" | grep -qi "create file"; then
    fail "$agent.md Process section contains 'create file' — read-only agent must not create files"
  fi
done

[ "$FAIL" -eq 0 ] && echo "PASS: All 9 read-only agents have no write-tool phrases in Process sections"
exit "$FAIL"
