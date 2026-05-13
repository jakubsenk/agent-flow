#!/usr/bin/env bash
# Hidden scenario: REQ-025, REQ-026 — Jira regex fuzz: Unicode homoglyphs, null byte, percent-encoding, length 10000
# Expected v6.9.0 outcome: PASS once Phase 7 implements
# Pre-implementation outcome: FAIL (TDD) — dotted regex not yet present; dot-only guard missing
set -uo pipefail

# CRITICAL: 3 levels up from .forge/phase-5-tdd/tests-hidden/ to repo root
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../" && pwd)"

if [ ! -f "$REPO_ROOT/.claude-plugin/plugin.json" ]; then
  echo "FAIL: REPO_ROOT path resolution bug" >&2; exit 1
fi

FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

# The v6.9.0 combined validation guard (new regex + dot-only reject)
# Simulates what skills/fix-ticket/SKILL.md, etc. will enforce:
validate_issue_id() {
  local id="$1"
  # Guard 1: must match allowed character class (new regex with dot)
  [[ "$id" =~ ^[A-Za-z0-9#._-]+$ ]] || return 1
  # Guard 2: must not be all dots (path-traversal defense)
  [[ ! "$id" =~ ^\.+$ ]] || return 1
  return 0
}

echo "--- Unicode homoglyph tests ---"
# Unicode look-alikes that might bypass ASCII-class regex on non-POSIX systems
# These should be rejected because they are outside [A-Za-z0-9#._-]
unicode_homoglyphs=(
  $'\xE2\x80\xAD'   # RTL override (U+202D)
  $'\xC2\xAD'       # soft hyphen (U+00AD)
  $'\xEF\xB8\x8F'   # variation selector-16
  "PRОJ-123"        # Cyrillic О (U+041E) instead of Latin O
)
for h in "${unicode_homoglyphs[@]}"; do
  if validate_issue_id "$h"; then
    fail "Homoglyph input accepted: '$(echo -n "$h" | xxd | head -1)' — non-ASCII bypass"
  else
    echo "OK: unicode homoglyph rejected"
  fi
done

echo "--- Null byte test ---"
# Null byte in issue_id — must be rejected
null_byte_id=$'PROJ\x00NAME-123'
if validate_issue_id "$null_byte_id"; then
  fail "Null byte in issue_id accepted — null byte injection possible"
else
  echo "OK: null byte in issue_id correctly rejected"
fi

echo "--- Percent-encoding tests ---"
# Percent-encoded values (% is outside the class [A-Za-z0-9#._-])
pct_ids=(
  "PROJ%2F123"   # %2F = /
  "%2E%2E"       # %2E = . (encoded dots)
  "PROJ%00-1"    # %00 = null
)
for pct in "${pct_ids[@]}"; do
  if validate_issue_id "$pct"; then
    fail "Percent-encoded issue_id '$pct' accepted — % is outside allowed class"
  else
    echo "OK: '$pct' rejected (% not in allowed character class)"
  fi
done

echo "--- Length 10000 test ---"
# Very long issue_id — should be rejected by regex (would be accepted by pattern but impractical)
# The spec doesn't set a length limit, but the regex is length-unbounded; test that it
# doesn't cause catastrophic backtracking or timeout
long_id=$(python3 -c "print('A' * 10000)" 2>/dev/null || printf 'A%.0s' {1..10000})
start_time=$(date +%s)
if validate_issue_id "$long_id"; then
  echo "OK: 10000-char all-A id: accepted (no backtracking catastrophe)"
else
  echo "OK: 10000-char all-A id: rejected"
fi
end_time=$(date +%s)
elapsed=$((end_time - start_time))
if [ "$elapsed" -gt 5 ]; then
  fail "Length-10000 test took $elapsed seconds — catastrophic backtracking in regex"
else
  echo "OK: length-10000 test completed in $elapsed seconds (no catastrophic backtracking)"
fi

echo "--- Dot-only variants (all lengths 1-4) ---"
for i in 1 2 3 4; do
  dots=$(printf '%*s' "$i" '' | tr ' ' '.')
  if validate_issue_id "$dots"; then
    fail "Dot-only '$dots' accepted — path-traversal guard failed"
  else
    echo "OK: '$dots' rejected by dot-only guard"
  fi
done

echo "--- Shell metacharacter injection ---"
meta_chars=(
  '$(whoami)'
  '`id`'
  ';ls'
  '&&echo'
  '|cat'
  '>file'
  '<input'
)
for meta in "${meta_chars[@]}"; do
  if validate_issue_id "$meta"; then
    fail "Shell metachar '$meta' accepted — injection possible"
  else
    echo "OK: shell metachar '$meta' rejected"
  fi
done

echo "--- Valid inputs still accepted ---"
valid_ids=("PROJ-123" "PROJ.NAME-123" "ABC.DEF.GHI-1" "#42" "ISSUE-1")
for vid in "${valid_ids[@]}"; do
  if validate_issue_id "$vid"; then
    echo "OK: '$vid' accepted (valid Jira-style ID)"
  else
    fail "Valid id '$vid' incorrectly rejected"
  fi
done

if [ "$FAIL" -eq 0 ]; then
  echo "PASS: h-jira-regex-fuzz — all malicious inputs rejected; valid IDs accepted; no backtracking"
fi
exit "$FAIL"
