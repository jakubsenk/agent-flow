#!/usr/bin/env bash
# Test: skills/sprint-plan/SKILL.md exists with correct frontmatter
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

FAIL=0
fail() { echo "FAIL: $1"; FAIL=1; }

SKILL_FILE="$REPO_ROOT/skills/sprint-plan/SKILL.md"

# 1. File must exist
if [ ! -f "$SKILL_FILE" ]; then
  fail "skills/sprint-plan/SKILL.md does not exist"
  exit 1
fi

# 2. Frontmatter: name: sprint-plan
if ! grep -q "^name: sprint-plan" "$SKILL_FILE"; then
  fail "skills/sprint-plan/SKILL.md missing frontmatter 'name: sprint-plan'"
fi

# 3. Frontmatter: description field
if ! grep -q "^description:" "$SKILL_FILE"; then
  fail "skills/sprint-plan/SKILL.md missing frontmatter 'description:' field"
fi

# 4. Frontmatter: disable-model-invocation: true (pipeline skill)
if ! grep -q "^disable-model-invocation: true" "$SKILL_FILE"; then
  fail "skills/sprint-plan/SKILL.md missing 'disable-model-invocation: true' (pipeline skill requirement)"
fi

# 5. Frontmatter: allowed-tools includes mcp__* pattern
if ! grep -qi "allowed-tools" "$SKILL_FILE"; then
  fail "skills/sprint-plan/SKILL.md missing 'allowed-tools' frontmatter field"
fi
if ! grep -qi "mcp__" "$SKILL_FILE"; then
  fail "skills/sprint-plan/SKILL.md allowed-tools must include mcp__* tools"
fi

# 6. References config-reader for Sprint Planning config section
if ! grep -qi "config-reader\|Sprint Planning\|sprint.*config\|config.*sprint" "$SKILL_FILE"; then
  fail "skills/sprint-plan/SKILL.md must reference config-reader or Sprint Planning config section"
fi

[ "$FAIL" -eq 0 ] && echo "PASS: skills/sprint-plan/SKILL.md exists with correct frontmatter (name, description, disable-model-invocation, allowed-tools)"
exit "$FAIL"
