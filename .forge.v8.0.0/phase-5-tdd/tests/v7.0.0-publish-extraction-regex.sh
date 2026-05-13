#!/usr/bin/env bash
# AC-PUBLISH-AUTO-DETECT-3, AC-PUBLISH-AUTO-DETECT-EXTRACTION-1,
# AC-PUBLISH-AUTO-DETECT-EXTRACTION-2, AC-PUBLISH-AUTO-DETECT-EXTRACTION-3,
# AC-PUBLISH-AUTO-DETECT-EXTRACTION-4, AC-PUBLISH-AUTO-DETECT-EXTRACTION-5
# Verifies the canonical issue-ID extraction regex is present in skill prose,
# AND performs runtime bash assertions for all 5 extraction example cases.
# The canonical regex: ^(#?[0-9]+|[A-Za-z][A-Za-z0-9_]*-[0-9]+)
# Critical: PROJ-123-fix-crash must yield PROJ-123, NOT PROJ.
set -euo pipefail

cd "$(dirname "$0")/../.."
FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

PUBLISH="skills/publish/SKILL.md"

# Functional check 1: skill file exists
if [ ! -f "$PUBLISH" ]; then
  echo "FAIL: $PUBLISH missing" >&2
  exit 1
fi

# Functional check 2: canonical regex character classes present in skill prose
# The regex [A-Za-z][A-Za-z0-9_]*-[0-9]+ must appear in some form
if ! grep -qE '\[A-Za-z\]\[A-Za-z0-9_\]\*-\[0-9\]\+' "$PUBLISH"; then
  fail "$PUBLISH: canonical regex [A-Za-z][A-Za-z0-9_]*-[0-9]+ not present"
fi
# Numeric branch: #?[0-9]+ must appear
if ! grep -qE '#\?\[0-9\]\+|\[0-9\]\+' "$PUBLISH"; then
  fail "$PUBLISH: canonical regex #?[0-9]+ not present"
fi

# Functional check 3: worked example PROJ-123-fix-crash documented
if ! grep -qE 'PROJ-123-fix-crash' "$PUBLISH"; then
  fail "$PUBLISH: worked example 'PROJ-123-fix-crash' not documented"
fi
if ! grep -qE 'PROJ-123\b' "$PUBLISH"; then
  fail "$PUBLISH: expected extraction 'PROJ-123' not documented"
fi

# Functional check 4: path-traversal defense (dot-only rejection) documented
if ! grep -qE '\^\\\.\+\$|\^\.\+\$' "$PUBLISH"; then
  fail "$PUBLISH: path-traversal defense ^\.+\$ not documented"
fi

# Runtime check A: PROJ-123-fix-crash → PROJ-123 (not PROJ, not PROJ-123-fix-crash)
residue="PROJ-123-fix-crash"
if [[ "$residue" =~ ^(#?[0-9]+|[A-Za-z][A-Za-z0-9_]*-[0-9]+) ]]; then
  extracted="${BASH_REMATCH[1]}"
  if [ "$extracted" != "PROJ-123" ]; then
    fail "Runtime: residue '$residue' extracted '$extracted', expected 'PROJ-123'"
  fi
else
  fail "Runtime: canonical regex did not match residue '$residue'"
fi

# Runtime check B: PROJ-456 (no description segment) → PROJ-456
residue="PROJ-456"
if [[ "$residue" =~ ^(#?[0-9]+|[A-Za-z][A-Za-z0-9_]*-[0-9]+) ]]; then
  extracted="${BASH_REMATCH[1]}"
  if [ "$extracted" != "PROJ-456" ]; then
    fail "Runtime: residue '$residue' extracted '$extracted', expected 'PROJ-456'"
  fi
else
  fail "Runtime: canonical regex did not match residue '$residue'"
fi

# Runtime check C: non-matching prefix → issue_id=null (empty result)
branch="chore/refactor-foo"
prefix="fix/"
residue_c=""
case "$branch" in
  "$prefix"*) residue_c="${branch#$prefix}" ;;
  *) residue_c="" ;;
esac
if [ -n "$residue_c" ]; then
  fail "Runtime: branch '$branch' with prefix '$prefix' should yield empty residue (issue_id=null)"
fi

# Runtime check D: numeric-only branch (github/gitea/redmine) fix/123-numeric-id → 123
residue="123-numeric-id"
if [[ "$residue" =~ ^(#?[0-9]+|[A-Za-z][A-Za-z0-9_]*-[0-9]+) ]]; then
  extracted="${BASH_REMATCH[1]}"
  if [ "$extracted" != "123" ]; then
    fail "Runtime: residue '$residue' extracted '$extracted', expected '123'"
  fi
else
  fail "Runtime: canonical regex did not match numeric residue '$residue'"
fi

# Runtime check E: hash-prefixed ID fix/#42-fix → #42
residue="#42-fix"
if [[ "$residue" =~ ^(#?[0-9]+|[A-Za-z][A-Za-z0-9_]*-[0-9]+) ]]; then
  extracted="${BASH_REMATCH[1]}"
  if [ "$extracted" != "#42" ]; then
    fail "Runtime: residue '$residue' extracted '$extracted', expected '#42'"
  fi
else
  fail "Runtime: canonical regex did not match hash-prefixed residue '$residue'"
fi

# Runtime check F: ABC_DEF-789 (youtrack with underscore in prefix) → ABC_DEF-789
residue="ABC_DEF-789"
if [[ "$residue" =~ ^(#?[0-9]+|[A-Za-z][A-Za-z0-9_]*-[0-9]+) ]]; then
  extracted="${BASH_REMATCH[1]}"
  if [ "$extracted" != "ABC_DEF-789" ]; then
    fail "Runtime: residue '$residue' extracted '$extracted', expected 'ABC_DEF-789'"
  fi
else
  fail "Runtime: canonical regex did not match underscore-prefix residue '$residue'"
fi

[ "$FAIL" -eq 0 ] && echo "PASS: AC-PUBLISH-AUTO-DETECT-3,EXTRACTION-1..5 — canonical regex present and runtime extraction correct for all 6 tracker shapes"
exit "$FAIL"
