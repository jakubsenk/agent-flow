#!/usr/bin/env bash
# AC-DEL-CREATE-PR-1, AC-DEL-CREATE-PR-2, AC-DEL-CREATE-PR-3, AC-DEL-CREATE-PR-4,
# AC-DEL-CREATE-PR-5, AC-DEL-CREATE-PR-6, AC-DEL-CREATE-PR-7, AC-DEL-CREATE-PR-8,
# AC-DEL-CREATE-PR-9, AC-DEL-CREATE-PR-10, AC-DEL-CREATE-PR-11
# Asserts skills/create-pr/ is absent and all active references to /create-pr are removed.
# Exception: skills/workflow-router/SKILL.md intentionally keeps the deprecated name
# in its "Did you mean...?" prose (design.md §5.3).
set -euo pipefail

cd "$(dirname "$0")/../.."
FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

# Functional check 1: skills/create-pr/ directory must NOT exist
if [ -d skills/create-pr ]; then
  fail "skills/create-pr/ directory still exists"
fi

# Functional check 2: no stale ceos-agents:create-pr references in active surfaces
# (workflow-router excluded — intentional deprecated-names prose)
stale_create_pr=$(grep -rn 'ceos-agents:create-pr\b' \
  --include='*.md' \
  --exclude-dir=.forge \
  --exclude-dir='.forge.bak-*' \
  --exclude-dir=docs/plans \
  --exclude-dir=docs/superpowers \
  --exclude=CHANGELOG.md \
  --exclude=skills/workflow-router/SKILL.md \
  . 2>/dev/null | wc -l | tr -d ' ')
if [ "$stale_create_pr" != "0" ]; then
  echo "FAIL: Found $stale_create_pr stale 'ceos-agents:create-pr' references in active files:" >&2
  grep -rn 'ceos-agents:create-pr\b' \
    --include='*.md' \
    --exclude-dir=.forge \
    --exclude-dir='.forge.bak-*' \
    --exclude-dir=docs/plans \
    --exclude-dir=docs/superpowers \
    --exclude=CHANGELOG.md \
    --exclude=skills/workflow-router/SKILL.md \
    . 2>/dev/null | head -20 >&2
  FAIL=1
fi

# Functional check 3: README no longer lists /create-pr in skill table
if grep -qE '^\| `/create-pr` \|' README.md 2>/dev/null; then
  fail "README.md: skill table still has /create-pr row"
fi

# Functional check 4: docs/reference/skills.md has no /create-pr section
if grep -qE '^### /create-pr$' docs/reference/skills.md 2>/dev/null; then
  fail "docs/reference/skills.md: ### /create-pr section still exists"
fi

# Functional check 5: PR Rules row in automation-config.md no longer mentions /create-pr
if grep -E '^\| PR Rules \|' docs/reference/automation-config.md 2>/dev/null | grep -q '/create-pr'; then
  fail "docs/reference/automation-config.md: PR Rules row still mentions /create-pr"
fi

# Functional check 6: PR Description Template row no longer mentions /create-pr
if grep -E '^\| PR Description Template \|' docs/reference/automation-config.md 2>/dev/null | grep -q '/create-pr'; then
  fail "docs/reference/automation-config.md: PR Description Template row still mentions /create-pr"
fi

# Functional check 7: workflow-router intent table row for create-pr must be deleted
# (the old "| Create a pull request | `ceos-agents:create-pr` |" row must be gone)
if grep -qE '^\| .*Create a pull request.*\| `ceos-agents:create-pr`' skills/workflow-router/SKILL.md 2>/dev/null; then
  fail "skills/workflow-router/SKILL.md: create-pr intent table row not deleted"
fi

# Functional check 8: workflow-router Step 4 destructive list no longer has create-pr,
if grep -E 'IS destructive.*create-pr,' skills/workflow-router/SKILL.md >/dev/null 2>&1; then
  fail "skills/workflow-router/SKILL.md: Step 4 destructive list still has create-pr,"
fi

# Functional check 9: test scenario no-mcp-jargon-errors.sh no longer references skills/create-pr/SKILL.md
if grep -q 'skills/create-pr/SKILL.md' tests/scenarios/no-mcp-jargon-errors.sh 2>/dev/null; then
  fail "tests/scenarios/no-mcp-jargon-errors.sh: still references skills/create-pr/SKILL.md"
fi

# Functional check 10: skills-directory-structure.sh no longer has create-pr in EXPECTED_SKILLS
if grep -qE '"create-pr"' tests/scenarios/skills-directory-structure.sh 2>/dev/null; then
  fail "tests/scenarios/skills-directory-structure.sh: EXPECTED_SKILLS still has create-pr"
fi

# Functional check 11: skills-frontmatter-check.sh no longer has create-pr in PIPELINE_SKILLS
if grep -qE '"create-pr"' tests/scenarios/skills-frontmatter-check.sh 2>/dev/null; then
  fail "tests/scenarios/skills-frontmatter-check.sh: PIPELINE_SKILLS still has create-pr"
fi

[ "$FAIL" -eq 0 ] && echo "PASS: AC-DEL-CREATE-PR-1..11 — /create-pr skill deleted from all active surfaces"
exit "$FAIL"
