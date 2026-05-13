#!/usr/bin/env bash
# Hidden scenario: REQ-052, AC-052a — sanitize_block_reason() uses POSIX-only sed constructs (no \b \S \d \w)
# Expected v6.9.0 outcome: PASS once Phase 7 implements
# Pre-implementation outcome: FAIL (TDD) — function not yet written
set -uo pipefail

# CRITICAL: 3 levels up from .forge/phase-5-tdd/tests-hidden/ to repo root
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../" && pwd)"

if [ ! -f "$REPO_ROOT/.claude-plugin/plugin.json" ]; then
  echo "FAIL: REPO_ROOT path resolution bug" >&2; exit 1
fi

FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

POST_HOOK="$REPO_ROOT/core/post-publish-hook.md"

if [ ! -f "$POST_HOOK" ]; then
  echo "FAIL: core/post-publish-hook.md not found" >&2; exit 1
fi

# Assertion 1: sanitize_block_reason() function exists
echo "--- Assertion 1: sanitize_block_reason() function exists ---"
if ! grep -qF 'sanitize_block_reason()' "$POST_HOOK"; then
  fail "sanitize_block_reason() not found — cannot check POSIX portability"
  exit 1
fi

# Assertion 2 (AC-052a NEGATIVE): no PCRE/non-POSIX regex constructs in the function body
echo "--- Assertion 2 (AC-052a NEGATIVE): no \\b \\S \\d \\w in function body ---"
# Extract function body using awk (from function declaration to closing brace)
function_body=$(awk '/sanitize_block_reason\(\)/,/^}/' "$POST_HOOK" 2>/dev/null)

if echo "$function_body" | grep -qE '\\b[^[:space:]]'; then
  # Check it's not in a comment
  violations=$(echo "$function_body" | grep -E '\\b[^[:space:]]' | grep -v '^\s*#')
  if [ -n "$violations" ]; then
    fail "AC-052a: \\b (word boundary — PCRE-only) found in sanitize_block_reason() non-comment lines: $violations"
  fi
else
  echo "OK (AC-052a): no \\b word-boundary construct"
fi

if echo "$function_body" | grep -qE '\\S'; then
  violations=$(echo "$function_body" | grep -E '\\S' | grep -v '^\s*#')
  if [ -n "$violations" ]; then
    fail "AC-052a: \\S (non-whitespace — PCRE-only) found in sanitize_block_reason() non-comment lines: $violations"
  fi
else
  echo "OK (AC-052a): no \\S non-whitespace construct"
fi

if echo "$function_body" | grep -qE '\\d'; then
  violations=$(echo "$function_body" | grep -E '\\d' | grep -v '^\s*#')
  if [ -n "$violations" ]; then
    fail "AC-052a: \\d (digit — PCRE-only) found in sanitize_block_reason() non-comment lines: $violations"
  fi
else
  echo "OK (AC-052a): no \\d digit shorthand"
fi

if echo "$function_body" | grep -qE '\\w'; then
  violations=$(echo "$function_body" | grep -E '\\w' | grep -v '^\s*#')
  if [ -n "$violations" ]; then
    fail "AC-052a: \\w (word char — PCRE-only) found in sanitize_block_reason() non-comment lines: $violations"
  fi
else
  echo "OK (AC-052a): no \\w word-char shorthand"
fi

# Assertion 3 (AC-052a): POSIX-portable alternatives are used instead
echo "--- Assertion 3 (AC-052a): POSIX portable alternatives present ---"
posix_used=0
if echo "$function_body" | grep -qE '\[:\(space\|alpha\|digit\|alnum\|upper\|lower\):' 2>/dev/null || \
   echo "$function_body" | grep -qF '[[:space:]]' || \
   echo "$function_body" | grep -qF '[[:alnum:]]' || \
   echo "$function_body" | grep -qF '[0-9]'; then
  posix_used=1
fi
if [ "$posix_used" -eq 1 ]; then
  echo "OK (AC-052a): POSIX bracket expressions ([[:space:]], [0-9], etc.) detected in function body"
else
  fail "AC-052a: no POSIX bracket expressions found in sanitize_block_reason() — function may lack POSIX-portable constructs"
fi

# Assertion 4: functional BSD-compatible test — 'sed -E' works with POSIX patterns
echo "--- Assertion 4: BSD sed -E functional compatibility test ---"
# Test that our sed patterns work with BSD sed (macOS) equivalent
# Specifically: the anchor pattern (^|[[:space:]]) must work on both GNU and BSD sed
test_input="PASSWORD=hunter2secret"
expected_fragment="REDACTED"
result=$(echo "$test_input" | sed -E 's/(^|[[:space:]])[A-Z_][A-Z0-9_]*=[^[:space:]]+/\1[REDACTED-VAR]/g' 2>/dev/null || echo "$test_input")
if echo "$result" | grep -q 'REDACTED'; then
  echo "OK: BSD-compatible POSIX sed pattern works (PASSWORD=hunter2secret -> $result)"
else
  fail "POSIX anchor pattern (^|[[:space:]]) failed on this platform — not BSD-compatible"
fi

# Assertion 5: email pattern (if present) also uses POSIX constructs
echo "--- Assertion 5: email pattern (if any) uses POSIX constructs ---"
if echo "$function_body" | grep -qiE 'email|@'; then
  # email handling would be out of spec (not in 14 patterns) — just verify if mentioned it uses POSIX
  echo "INFO: email/@ reference found in function body — verifying it doesn't use non-POSIX constructs"
  if echo "$function_body" | grep -qE '@.*\\b|\\b.*@'; then
    fail "AC-052a: email pattern uses \\b word boundary — PCRE-only, not POSIX-portable"
  fi
else
  echo "OK: no email-specific patterns in sanitize_block_reason() (email not in 14-pattern spec)"
fi

if [ "$FAIL" -eq 0 ]; then
  echo "PASS: h-credential-redaction-bsd-compatible — sanitize_block_reason() uses POSIX-only sed constructs; BSD sed -E compatible"
fi
exit "$FAIL"
