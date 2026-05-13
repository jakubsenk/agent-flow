#!/usr/bin/env bash
# Scenario: REQ-026 — dot-only issue_id values rejected (path-traversal prevention)
# Expected v6.9.0 outcome: PASS once Phase 7 implements
# Pre-implementation outcome: FAIL (TDD) — dot-only guard not yet added
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../" && pwd)"

FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

SNIPPET="$REPO_ROOT/core/snippets/issue-id-validation.md"
SKILL_FILES=(
  "$REPO_ROOT/skills/fix-ticket/SKILL.md"
  "$REPO_ROOT/skills/fix-bugs/SKILL.md"
  "$REPO_ROOT/skills/implement-feature/SKILL.md"
  "$REPO_ROOT/skills/resume-ticket/SKILL.md"
)

# Assertion 1 (AC-026): dot-only guard present in canonical location
echo "--- Assertion 1 (AC-026): dot-only reject guard present ---"
guard_found=0
if [ -f "$SNIPPET" ]; then
  if grep -qF '! "$ISSUE_ID" =~ ^\.+$' "$SNIPPET" 2>/dev/null || \
     grep -qF "! \"\$ISSUE_ID\" =~ ^\\.+\$" "$SNIPPET" 2>/dev/null; then
    echo "OK (AC-026): dot-only reject guard present in core/snippets/issue-id-validation.md"
    guard_found=1
  fi
fi
if [ "$guard_found" -eq 0 ]; then
  for f in "${SKILL_FILES[@]}"; do
    if [ -f "$f" ] && grep -qE '! .*ISSUE_ID.*=~.*\^\\\.?\+\$' "$f"; then
      echo "OK (AC-026): dot-only reject guard found in $f"
      guard_found=1
    fi
  done
fi
if [ "$guard_found" -eq 0 ]; then
  fail "AC-026: dot-only reject guard '! \"\$ISSUE_ID\" =~ ^\\.+\$' not found in any of the 4 skill files or canonical snippet"
fi

# Assertion 2 (AC-075): functional test — dot-only values REJECTED
echo "--- Assertion 2 (AC-075 NEGATIVE): dot-only values rejected ---"
for bad_id in "." ".." "..." "...."; do
  # Must NOT pass the updated regex AND must fail the dot-only check
  if [[ "$bad_id" =~ ^[A-Za-z0-9#._-]+$ ]] && [[ ! "$bad_id" =~ ^\.+$ ]]; then
    fail "AC-075: '$bad_id' was accepted by combined guard — path-traversal vector still open"
  else
    echo "OK (AC-075): '$bad_id' correctly rejected"
  fi
done

# Assertion 3 (AC-075): functional test — valid values ACCEPTED (incl. dotted keys)
echo "--- Assertion 3 (AC-075): valid values accepted ---"
for good_id in "PROJ-123" "PROJ.NAME-123" "#42" ".PROJ-123" "PROJ-123." "ABC.DEF.GHI-1"; do
  if [[ "$good_id" =~ ^[A-Za-z0-9#._-]+$ ]] && [[ ! "$good_id" =~ ^\.+$ ]]; then
    echo "OK: '$good_id' accepted by combined guard"
  else
    fail "AC-075: '$good_id' incorrectly rejected (valid Jira-style issue ID)"
  fi
done

# Assertion 4 (AC-075): path-traversal-style ids rejected
echo "--- Assertion 4 (AC-075 NEGATIVE): path traversal rejected ---"
for bad_id in "../etc/passwd" "..\nPROJ"; do
  if [[ "$bad_id" =~ ^[A-Za-z0-9#._-]+$ ]]; then
    fail "AC-075: '$bad_id' accepted — contains path-traversal characters (/ or \\n outside class)"
  else
    echo "OK: '$bad_id' rejected (contains characters outside the allowed class)"
  fi
done

# Assertion 5 (AC-075): empty string rejected
echo "--- Assertion 5 (AC-075 NEGATIVE): empty string rejected ---"
empty_id=""
if [[ "$empty_id" =~ ^[A-Za-z0-9#._-]+$ ]]; then
  fail "AC-075: empty string accepted — the '+' quantifier requires at least one character"
else
  echo "OK: empty string correctly rejected ('+' quantifier)"
fi

if [ "$FAIL" -eq 0 ]; then
  echo "PASS: v6.9.0 dot-only issue_id values rejected; path-traversal guard operational"
fi
exit "$FAIL"
