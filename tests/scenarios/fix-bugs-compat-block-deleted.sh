#!/bin/bash
# Covers: AC-15 (skills/fix-bugs/SKILL.md Agent Overrides compat block deleted;
#         neither the header nor migrate-config reference survives)
set -e

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

FILE="$REPO_ROOT/skills/fix-bugs/SKILL.md"

if [ ! -f "$FILE" ]; then
  echo "FAIL: v9-5-fix-bugs-compat-block-deleted — skills/fix-bugs/SKILL.md not found"
  exit 1
fi

FAIL=0
fail() { echo "FAIL: v9-5-fix-bugs-compat-block-deleted — $1"; FAIL=1; }

if grep -qF '## Agent Overrides compatibility' "$FILE"; then
  fail "'## Agent Overrides compatibility' header still present in skills/fix-bugs/SKILL.md"
else
  echo "PASS: '## Agent Overrides compatibility' header absent"
fi

if grep -qF 'migrate-config' "$FILE"; then
  fail "'migrate-config' reference still present in skills/fix-bugs/SKILL.md"
else
  echo "PASS: 'migrate-config' reference absent from skills/fix-bugs/SKILL.md"
fi

if [ "$FAIL" -eq 0 ]; then
  echo "PASS: v9-5-fix-bugs-compat-block-deleted — compat block fully removed from fix-bugs SKILL.md"
fi
exit "$FAIL"
