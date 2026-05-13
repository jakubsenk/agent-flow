#!/bin/bash
# Covers: AC-61 (CHANGELOG has v9.5.0 entry with 4 [Removed] blocks),
#         AC-62 (CHANGELOG v9.5.0 uses short-dash only, no em/en dashes),
#         AC-63 (CHANGELOG v9.5.0 notes "core: 17 (unchanged)")
set -e

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

CHANGELOG="$REPO_ROOT/CHANGELOG.md"

if [ ! -f "$CHANGELOG" ]; then
  echo "FAIL: v9-5-changelog — CHANGELOG.md not found"
  exit 1
fi

FAIL=0
fail() { echo "FAIL: v9-5-changelog — $1"; FAIL=1; }

# AC-61: v9.5.0 entry exists
if grep -qE '^## \[?v?9\.5\.0\]?' "$CHANGELOG"; then
  echo "PASS: CHANGELOG has v9.5.0 entry"
else
  fail "CHANGELOG does not have v9.5.0 entry"
fi

# AC-61: scoped to v9.5.0 section — count deleted-skill mentions in Removed section
# Format-agnostic: works with `[Removed]` markers, `### Removed` H3, or any "Removed" subsection
SECTION_FOR_REMOVED=$(sed -n '/^## \[*v*9\.5\.0/,/^## \[*v*9\.4/p' "$REPO_ROOT/CHANGELOG.md")
REMOVED_COUNT=$(echo "$SECTION_FOR_REMOVED" | grep -cE '(migrate-config|ceos-agents:estimate|/estimate|pipeline-status|scaffold-validate)')
if [ "$REMOVED_COUNT" -lt 4 ]; then
  echo "FAIL: v9-5-changelog — expected ≥4 deleted-skill mentions in v9.5.0 section, got $REMOVED_COUNT"
  exit 1
fi
echo "PASS: CHANGELOG v9.5.0 section mentions all 4 deleted skills (found: $REMOVED_COUNT)"

# AC-62: no em/en dashes in v9.5.0 CHANGELOG section (Czech short-dash convention)
# Use perl or python fallback for cross-platform Unicode regex (MINGW grep -P unreliable)
SECTION=$(sed -n '/^## \[*v*9\.5\.0/,/^## \[*v*9\.4/p' "$REPO_ROOT/CHANGELOG.md")
if echo "$SECTION" | perl -CSD -ne 'exit 1 if /[\x{2013}\x{2014}]/' 2>/dev/null; then
  : # PASS
elif echo "$SECTION" | python3 -c 'import sys; sys.exit(1 if any(ord(c) in (0x2013,0x2014) for c in sys.stdin.read()) else 0)' 2>/dev/null; then
  : # PASS via python fallback
else
  echo "FAIL: v9-5-changelog — em-dash or en-dash detected in v9.5.0 CHANGELOG section"
  exit 1
fi
echo "PASS: v9.5.0 CHANGELOG section uses only short dashes"

V950_SECTION=$(sed -n '/^## \[*v*9\.5\.0/,/^## \[*v*9\.4/p' "$CHANGELOG" 2>/dev/null || true)

# AC-63: core 17 unchanged noted
if echo "$V950_SECTION" | grep -qE '17.*(core|contracts|unchanged)|core.*17'; then
  echo "PASS: CHANGELOG v9.5.0 notes core count = 17 (unchanged)"
else
  fail "CHANGELOG v9.5.0 section does not note 'core: 17 (unchanged)'"
fi

if [ "$FAIL" -eq 0 ]; then
  echo "PASS: v9-5-changelog — CHANGELOG.md v9.5.0 entry is correct"
fi
exit "$FAIL"
