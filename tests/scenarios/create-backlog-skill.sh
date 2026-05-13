#!/usr/bin/env bash
# Test: skills/create-backlog/SKILL.md exists with correct frontmatter and core references
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

FAIL=0
fail() { echo "FAIL: $1"; FAIL=1; }

SKILL_FILE="$REPO_ROOT/skills/create-backlog/SKILL.md"

# 1. File must exist
if [ ! -f "$SKILL_FILE" ]; then
  fail "skills/create-backlog/SKILL.md does not exist"
  exit 1
fi

# 2. Frontmatter: name: create-backlog
if ! grep -q "^name: create-backlog" "$SKILL_FILE"; then
  fail "skills/create-backlog/SKILL.md missing frontmatter 'name: create-backlog'"
fi

# 3. Frontmatter: description field
if ! grep -q "^description:" "$SKILL_FILE"; then
  fail "skills/create-backlog/SKILL.md missing frontmatter 'description:' field"
fi

# 4. Frontmatter: disable-model-invocation: true (pipeline skill)
if ! grep -q "^disable-model-invocation: true" "$SKILL_FILE"; then
  fail "skills/create-backlog/SKILL.md missing 'disable-model-invocation: true' (pipeline skill requirement)"
fi

# 5. Frontmatter: allowed-tools includes mcp__* pattern
if ! grep -qi "allowed-tools" "$SKILL_FILE"; then
  fail "skills/create-backlog/SKILL.md missing 'allowed-tools' frontmatter field"
fi
if ! grep -qi "mcp__" "$SKILL_FILE"; then
  fail "skills/create-backlog/SKILL.md allowed-tools must include mcp__* tools"
fi

# 6. Body references core/mcp-preflight.md
if ! grep -qi "mcp-preflight" "$SKILL_FILE"; then
  fail "skills/create-backlog/SKILL.md must reference core/mcp-preflight.md"
fi

# 7. Body references core/config-reader.md
if ! grep -qi "config-reader" "$SKILL_FILE"; then
  fail "skills/create-backlog/SKILL.md must reference core/config-reader.md"
fi

[ "$FAIL" -eq 0 ] && echo "PASS: skills/create-backlog/SKILL.md exists with correct frontmatter and core references (mcp-preflight, config-reader)"
exit "$FAIL"
