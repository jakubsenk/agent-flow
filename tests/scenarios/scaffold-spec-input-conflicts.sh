#!/bin/bash
# Test: Scaffold mutually exclusive flag validation
# Validates: error messages for conflicting flags are defined in scaffold command
set -e

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

SCAFFOLD_CMD="$REPO_ROOT/skills/scaffold/SKILL.md"

# Verify mutual exclusion error for --spec + --template + --issue
if ! grep -q "Only one input source allowed" "$SCAFFOLD_CMD"; then
  echo "FAIL: scaffold.md missing mutual exclusion error message"
  exit 1
fi

# Verify --no-implement + --spec/--template/--issue conflict error
if ! grep -q "\-\-no-implement skips specification phase" "$SCAFFOLD_CMD"; then
  echo "FAIL: scaffold.md missing --no-implement conflict error message"
  exit 1
fi

# Verify all new flags are documented in flag parsing
for flag in "template" "spec" "issue" "no-implement"; do
  if ! grep -qF -- "--$flag" "$SCAFFOLD_CMD"; then
    echo "FAIL: scaffold.md missing flag: --$flag"
    exit 1
  fi
done

# Verify tech stack flags are still present (compatible with all input sources)
for flag in "lang" "framework" "db" "ci"; do
  if ! grep -qF -- "--$flag" "$SCAFFOLD_CMD"; then
    echo "FAIL: scaffold.md missing tech stack flag: --$flag"
    exit 1
  fi
done

echo "PASS: Scaffold input conflict validation verified"
