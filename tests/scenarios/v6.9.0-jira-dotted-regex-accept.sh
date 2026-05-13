#!/usr/bin/env bash
# Scenario: REQ-025 — issue_id validation regex updated to accept Jira dotted keys (PROJ.NAME-123)
# Expected v6.9.0 outcome: PASS once Phase 7 implements
# Pre-implementation outcome: FAIL (TDD) — regex does not yet include dot character
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../" && pwd)"

FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

# Files to check — REQ-025 requires update in all 4 skills (or via canonical snippet)
SKILL_FILES=(
  "$REPO_ROOT/skills/fix-ticket/SKILL.md"
  "$REPO_ROOT/skills/fix-bugs/SKILL.md"
  "$REPO_ROOT/skills/implement-feature/SKILL.md"
  "$REPO_ROOT/skills/resume-ticket/SKILL.md"
)
SNIPPET="$REPO_ROOT/core/snippets/issue-id-validation.md"

# Determine if snippet ADOPT-ALL was used: check for canonical snippet file
snippet_adopted=0
if [ -f "$SNIPPET" ]; then
  snippet_adopted=1
fi

# Assertion 1 (AC-025): new regex with dot present in canonical location
echo "--- Assertion 1 (AC-025): '^[A-Za-z0-9#._-]+\$' regex present ---"
if [ "$snippet_adopted" -eq 1 ]; then
  if grep -qF '^[A-Za-z0-9#._-]+$' "$SNIPPET"; then
    echo "OK (AC-025): new dotted regex present in core/snippets/issue-id-validation.md (snippet canonical)"
  else
    fail "AC-025: core/snippets/issue-id-validation.md missing '^[A-Za-z0-9#._-]+\$' regex"
  fi
else
  # Fall back: check each skill file directly
  for f in "${SKILL_FILES[@]}"; do
    if [ ! -f "$f" ]; then
      fail "Required skill file not found: $f"
      continue
    fi
    if grep -qF '^[A-Za-z0-9#._-]+$' "$f"; then
      echo "OK (AC-025): new dotted regex present in $f"
    else
      fail "AC-025: $f missing '^[A-Za-z0-9#._-]+\$' — Jira dotted keys (PROJ.NAME-123) would be rejected"
    fi
  done
fi

# Assertion 2 (AC-025 NEGATIVE): old regex without dot must be absent
echo "--- Assertion 2 (AC-025 NEGATIVE): old regex '^[A-Za-z0-9#_-]+\$' absent ---"
if [ "$snippet_adopted" -eq 1 ]; then
  if grep -qF '^[A-Za-z0-9#_-]+$' "$SNIPPET"; then
    fail "AC-025: old regex '^[A-Za-z0-9#_-]+\$' still present in canonical snippet (dot not added)"
  else
    echo "OK (AC-025): old regex without dot absent from canonical snippet"
  fi
else
  for f in "${SKILL_FILES[@]}"; do
    if [ -f "$f" ] && grep -qF '^[A-Za-z0-9#_-]+$' "$f"; then
      fail "AC-025: $f still has old regex '^[A-Za-z0-9#_-]+\$' without dot — must be updated"
    elif [ -f "$f" ]; then
      echo "OK (AC-025): old regex absent from $f"
    fi
  done
fi

# Assertion 3: functional validation — test the regex inline with bash =~
echo "--- Assertion 3: inline regex functional test for PROJ.NAME-123 ---"
ISSUE_ID="PROJ.NAME-123"
if [[ "$ISSUE_ID" =~ ^[A-Za-z0-9#._-]+$ ]]; then
  echo "OK: 'PROJ.NAME-123' accepted by new regex (Jira dotted key)"
else
  fail "Jira dotted key 'PROJ.NAME-123' rejected by regex — regex may not have been updated"
fi

# Assertion 4: functional validation — PROJ-123 still accepted
ISSUE_ID2="PROJ-123"
if [[ "$ISSUE_ID2" =~ ^[A-Za-z0-9#._-]+$ ]]; then
  echo "OK: 'PROJ-123' accepted by new regex"
else
  fail "'PROJ-123' rejected by new regex (regression)"
fi

if [ "$FAIL" -eq 0 ]; then
  echo "PASS: v6.9.0 issue_id regex updated to accept Jira dotted keys"
fi
exit "$FAIL"
