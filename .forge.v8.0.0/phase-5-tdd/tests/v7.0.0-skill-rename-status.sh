#!/usr/bin/env bash
# AC-RENAME-STATUS-1, AC-RENAME-STATUS-2, AC-RENAME-STATUS-3, AC-RENAME-STATUS-4,
# AC-RENAME-STATUS-5, AC-RENAME-STATUS-6, AC-RENAME-STATUS-7
# Asserts skills/status/ is gone, skills/pipeline-status/ exists with correct
# frontmatter, and all active references use the new identifier.
# workflow-router is excluded from the negative grep (has intentional "Did you mean?" prose).
set -euo pipefail

cd "$(dirname "$0")/../.."
FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

# Functional check 1: skills/status/ directory must NOT exist
if [ -d skills/status ]; then
  fail "skills/status/ still exists — directory must be removed or renamed"
fi

# Functional check 2: skills/pipeline-status/ directory and SKILL.md must exist
if [ ! -d skills/pipeline-status ]; then
  fail "skills/pipeline-status/ directory does not exist"
fi
if [ ! -f skills/pipeline-status/SKILL.md ]; then
  fail "skills/pipeline-status/SKILL.md does not exist"
fi

# Functional check 3: frontmatter name field must be pipeline-status
if ! head -10 skills/pipeline-status/SKILL.md | grep -qE '^name: pipeline-status$'; then
  fail "skills/pipeline-status/SKILL.md frontmatter: expected 'name: pipeline-status'"
fi

# Functional check 4: no stale ceos-agents:status references in active surfaces
# (workflow-router excluded — intentional deprecated-names prose at design.md §5.3)
stale_status=$(grep -rn 'ceos-agents:status\b' \
  --include='*.md' \
  --exclude-dir=.forge \
  --exclude-dir='.forge.bak-*' \
  --exclude-dir=docs/plans \
  --exclude-dir=docs/superpowers \
  --exclude=CHANGELOG.md \
  --exclude=skills/workflow-router/SKILL.md \
  . 2>/dev/null | wc -l | tr -d ' ')
if [ "$stale_status" != "0" ]; then
  echo "FAIL: Found $stale_status stale 'ceos-agents:status' references in active files:" >&2
  grep -rn 'ceos-agents:status\b' \
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

# Functional check 5: workflow-router intent table updated (pipeline-status present;
# deprecated table row and non-destructive prose NOT using bare "status" as skill name)
if ! grep -q '`ceos-agents:pipeline-status`' skills/workflow-router/SKILL.md 2>/dev/null; then
  fail "skills/workflow-router/SKILL.md: intent table row not updated to ceos-agents:pipeline-status"
fi
if grep -qE '^\| .*Show status.*\| `ceos-agents:status`' skills/workflow-router/SKILL.md 2>/dev/null; then
  fail "skills/workflow-router/SKILL.md: intent table still has old ceos-agents:status row format"
fi

# Functional check 6: workflow-router Step 3 non-destructive list updated to pipeline-status
if ! grep -E 'NOT destructive.*pipeline-status' skills/workflow-router/SKILL.md >/dev/null 2>&1; then
  fail "skills/workflow-router/SKILL.md: Step 3 non-destructive list not updated to pipeline-status"
fi

# Functional check 7: README skill table updated
if ! grep -q '`/pipeline-status`' README.md 2>/dev/null; then
  fail "README.md: skill table not updated to /pipeline-status"
fi
if grep -qE '^\| `/status` \|' README.md 2>/dev/null; then
  fail "README.md: skill table still has old /status row"
fi

[ "$FAIL" -eq 0 ] && echo "PASS: AC-RENAME-STATUS-1..7 — /status renamed to /pipeline-status in all active surfaces"
exit "$FAIL"
