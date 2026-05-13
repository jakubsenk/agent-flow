#!/usr/bin/env bash
# AC-RENAME-INIT-1, AC-RENAME-INIT-2, AC-RENAME-INIT-3, AC-RENAME-INIT-4,
# AC-RENAME-INIT-5, AC-RENAME-INIT-6, AC-RENAME-INIT-7
# Asserts skills/init/ is gone, skills/setup-mcp/ exists with correct frontmatter,
# and all active references use the new identifier.
# workflow-router excluded from negative grep (has intentional "Did you mean?" prose).
# Excludes: git init, npm init, forge init (non-skill-name contexts).
set -euo pipefail

cd "$(dirname "$0")/../.."
FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

# Functional check 1: skills/init/ directory must NOT exist
if [ -d skills/init ]; then
  fail "skills/init/ still exists — directory must be removed or renamed"
fi

# Functional check 2: skills/setup-mcp/ directory and SKILL.md must exist
if [ ! -d skills/setup-mcp ]; then
  fail "skills/setup-mcp/ directory does not exist"
fi
if [ ! -f skills/setup-mcp/SKILL.md ]; then
  fail "skills/setup-mcp/SKILL.md does not exist"
fi

# Functional check 3: frontmatter name field must be setup-mcp
if ! head -10 skills/setup-mcp/SKILL.md | grep -qE '^name: setup-mcp$'; then
  fail "skills/setup-mcp/SKILL.md frontmatter: expected 'name: setup-mcp'"
fi

# Functional check 4: no stale ceos-agents:init references in active surfaces
# Excluded: .forge/ and .forge.bak-* (forge artifacts), .forge.v* (versioned forge archives),
# docs/plans/ and docs/superpowers/ (historical planning docs), CHANGELOG.md (migration guide),
# README.md (migration table), installation.md (migration note — intentional rename
# cross-reference for users upgrading), workflow-router/ (intentional deprecated-names
# "Did you mean?" prose per design.md §5.3), scaffold/ (intentional backward-compat
# hint showing old command name in MCP unavailable flow, equivalent to workflow-router prose).
# Note: --exclude-dir takes basename patterns, not paths (grep limitation).
stale_init=0
stale_init=$(grep -rn 'ceos-agents:init\b' \
  --include='*.md' \
  --exclude-dir=.forge \
  --exclude-dir='.forge.bak-*' \
  --exclude-dir='.forge.v*' \
  --exclude-dir=plans \
  --exclude-dir=superpowers \
  --exclude=CHANGELOG.md \
  --exclude=README.md \
  --exclude=installation.md \
  --exclude-dir=workflow-router \
  --exclude-dir=scaffold \
  . 2>/dev/null | wc -l | tr -d ' ') || stale_init=0
if [ "$stale_init" != "0" ]; then
  echo "FAIL: Found $stale_init stale 'ceos-agents:init' references in active files:" >&2
  grep -rn 'ceos-agents:init\b' \
    --include='*.md' \
    --exclude-dir=.forge \
    --exclude-dir='.forge.bak-*' \
    --exclude-dir='.forge.v*' \
    --exclude-dir=plans \
    --exclude-dir=superpowers \
    --exclude=CHANGELOG.md \
    --exclude=README.md \
    --exclude=installation.md \
    --exclude-dir=workflow-router \
    --exclude-dir=scaffold \
    . 2>/dev/null | head -20 >&2 || true
  FAIL=1
fi

# Functional check 5: core/mcp-preflight.md references setup-mcp, not init
if ! grep -q '/ceos-agents:setup-mcp' core/mcp-preflight.md 2>/dev/null; then
  fail "core/mcp-preflight.md: does not reference /ceos-agents:setup-mcp"
fi
if grep -q '/ceos-agents:init' core/mcp-preflight.md 2>/dev/null; then
  fail "core/mcp-preflight.md: still references /ceos-agents:init"
fi

# Functional check 6: core/config-reader.md references setup-mcp, not init
if ! grep -q '/ceos-agents:setup-mcp' core/config-reader.md 2>/dev/null; then
  fail "core/config-reader.md: does not reference /ceos-agents:setup-mcp"
fi
if grep -q '/ceos-agents:init\b' core/config-reader.md 2>/dev/null; then
  fail "core/config-reader.md: still references /ceos-agents:init"
fi

# Functional check 7: README skill table updated
if ! grep -q '`/setup-mcp`' README.md 2>/dev/null; then
  fail "README.md: skill table not updated to /setup-mcp"
fi
if grep -qE '^\| `/init` \|' README.md 2>/dev/null; then
  fail "README.md: skill table still has old /init row"
fi

[ "$FAIL" -eq 0 ] && echo "PASS: AC-RENAME-INIT-1..7 — /init renamed to /setup-mcp in all active surfaces"
exit "$FAIL"
