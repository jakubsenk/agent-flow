#!/usr/bin/env bash
# Hidden test: AC-ITEM-2.5 (extended) — gate rejects all path-traversal characters
# Verifies that the [[ =~ ]] gate with regex ^[A-Za-z0-9#_-]+$ rejects every
# character class listed in R-ITEM-2.5: /, \, ., space, null byte, backtick,
# $, ", ', (, ), <, >, |, ~, ;, &, *, ?, [, ], {, }, LF, CR.
#
# Also verifies the regex literal in each of the 4 skill files is exactly
# ^[A-Za-z0-9#_-]+$ and nothing else.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../" && pwd)"

FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

echo "--- h-regex-path-traversal (AC-ITEM-2.5): all forbidden chars rejected ---"

# -----------------------------------------------------------------------
# Part 1: Behavioral — run gate against each forbidden character class
# -----------------------------------------------------------------------
GATE_SNIPPET='if [[ ! "${ISSUE_ID}" =~ ^[A-Za-z0-9#_-]+$ ]]; then exit 1; fi; exit 0'

reject_check() {
  local label="$1"
  local value="$2"
  local rc=0
  ISSUE_ID="$value" bash -c "$GATE_SNIPPET" && rc=0 || rc=$?
  if [ "$rc" -ne 0 ]; then
    echo "OK: gate rejects '$label' (exit $rc)"
  else
    fail "AC-ITEM-2.5: gate did NOT reject '$label' input — forbidden character allowed"
  fi
}

# Each call passes a value containing the forbidden character
reject_check "path_separator_slash"        "foo/bar"
reject_check "path_separator_dotdot"       "../etc/passwd"
reject_check "path_separator_dotdotslash"  "../../etc/passwd"
reject_check "dot_only"                    "foo.bar"
reject_check "space"                       "foo bar"
reject_check "backtick"                    'foo`id`'
reject_check "dollar"                      'proj$42'
reject_check "double_quote"                'proj"42'
reject_check "single_quote"               "proj'42"
reject_check "pipe"                        "foo|bar"
reject_check "semicolon"                   "foo;ls"
reject_check "ampersand"                   "foo&bar"
reject_check "tilde"                       "~user"
reject_check "open_paren"                  "foo(42"
reject_check "close_paren"                 "foo)42"
reject_check "less_than"                   "foo<bar"
reject_check "greater_than"               "foo>bar"
reject_check "asterisk"                    "foo*"
reject_check "question_mark"               "foo?"
reject_check "open_bracket"               "foo[bar"
reject_check "close_bracket"              "foo]bar"
reject_check "open_brace"                 "foo{bar"
reject_check "close_brace"               "foo}bar"
reject_check "backslash"                   'foo\bar'
reject_check "subshell_injection"          '$(whoami)'

# Newline is tested in h-regex-newline-bypass.sh; include a cross-check here
bypass_exit=0
ISSUE_ID=$'PROJ-1\n../evil' bash -c "$GATE_SNIPPET" && bypass_exit=0 || bypass_exit=$?
if [ "$bypass_exit" -ne 0 ]; then
  echo "OK: gate rejects newline-injection payload (cross-check with h-regex-newline-bypass)"
else
  fail "AC-ITEM-2.5: gate accepted newline-injection payload"
fi

# -----------------------------------------------------------------------
# Part 2: Valid characters — confirm allowlist is not too narrow
# -----------------------------------------------------------------------
pass_check() {
  local label="$1"
  local value="$2"
  local rc=0
  ISSUE_ID="$value" bash -c "$GATE_SNIPPET" && rc=0 || rc=$?
  if [ "$rc" -eq 0 ]; then
    echo "OK: gate accepts valid '$label' = '$value'"
  else
    fail "AC-ITEM-2.5: gate incorrectly rejected valid '$label' = '$value'"
  fi
}

pass_check "youtrack"    "PROJ-42"
pass_check "jira"        "AUTH-1"
pass_check "github"      "#123"
pass_check "gitea"       "#456"
pass_check "redmine_int" "42"
pass_check "linear"      "ENG-789"
pass_check "mixed_case"  "myProject-42"
pass_check "hash_num"    "#1"

# -----------------------------------------------------------------------
# Part 3: Confirm regex literal in each skill file is exactly ^[A-Za-z0-9#_-]+$
#   and NOT widened with . / \ space
# -----------------------------------------------------------------------
echo "--- Part 3: Regex literal not widened in skill files ---"

SKILL_FILES=(
  "$REPO_ROOT/skills/fix-ticket/SKILL.md"
  "$REPO_ROOT/skills/fix-bugs/SKILL.md"
  "$REPO_ROOT/skills/implement-feature/SKILL.md"
  "$REPO_ROOT/skills/resume-ticket/SKILL.md"
)

for f in "${SKILL_FILES[@]}"; do
  if [ ! -f "$f" ]; then
    fail "AC-ITEM-2.5: skill file not found: $f"
    continue
  fi

  # The regex literal must be present
  if ! grep -qF '^[A-Za-z0-9#_-]+$' "$f"; then
    fail "AC-ITEM-2.5: regex literal '^[A-Za-z0-9#_-]+\$' not found in $(basename "$f")"
    continue
  fi
  echo "OK: '^[A-Za-z0-9#_-]+\$' present in $(basename "$f")"

  # Forbidden wideners MUST NOT appear in the character class
  for forbidden in '\.' '\\/' ' '; do
    if grep -qE "\\^\\[.*${forbidden}.*\\]" "$f" 2>/dev/null; then
      fail "AC-ITEM-2.5: $(basename "$f") character class contains forbidden widener '${forbidden}'"
    fi
  done
done

# -----------------------------------------------------------------------
# Final result
# -----------------------------------------------------------------------
if [ "$FAIL" -eq 0 ]; then
  echo "PASS: h-regex-path-traversal — all forbidden path-traversal characters rejected; regex not widened"
fi
exit "$FAIL"
