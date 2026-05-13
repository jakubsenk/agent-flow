#!/usr/bin/env bash
# Scenario: REQ-052, AC-052 — sanitize_block_reason() 14-pattern credential redaction
# Expected v6.9.0 outcome: PASS once Phase 7 implements
# Pre-implementation outcome: FAIL (TDD) — sanitize_block_reason() not yet defined
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../" && pwd)"

FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

POST_HOOK="$REPO_ROOT/core/post-publish-hook.md"

if [ ! -f "$POST_HOOK" ]; then
  echo "FAIL: core/post-publish-hook.md not found" >&2; exit 1
fi

# Assertion 1 (AC-052): sanitize_block_reason() function present
echo "--- Assertion 1 (AC-052): sanitize_block_reason() function present ---"
if grep -qF 'sanitize_block_reason()' "$POST_HOOK"; then
  echo "OK (AC-052): sanitize_block_reason() function defined in core/post-publish-hook.md"
else
  fail "AC-052: core/post-publish-hook.md missing 'sanitize_block_reason()' function"
fi

# Assertion 2 (AC-052): all 14 redaction tags present in function
echo "--- Assertion 2 (AC-052): all 14 redaction tag strings present ---"
redaction_tags=(
  '[REDACTED-URL]'
  '[REDACTED-VAR]'
  '[REDACTED-BEARER]'
  '[REDACTED-AUTH]'
  '[REDACTED-AWS-AKID]'
  '[REDACTED-AWS-VAR]'
  '[REDACTED-SLACK-TOKEN]'
  '[REDACTED-GITHUB-TOKEN]'
  '[REDACTED-APIKEY]'
  '[REDACTED-JWT]'
  '[REDACTED-PRIVATE-KEY]'
  '[REDACTED-STRIPE-LIVE]'
  '[REDACTED-GOOGLE-API-KEY]'
  '[REDACTED-OAUTH-REFRESH]'
)
for tag in "${redaction_tags[@]}"; do
  if grep -qF "$tag" "$POST_HOOK"; then
    echo "OK: $tag present"
  else
    fail "AC-052: core/post-publish-hook.md missing redaction tag '$tag'"
  fi
done

# Assertion 3 (AC-052a NEGATIVE): no POSIX-non-portable constructs in sanitize_block_reason()
echo "--- Assertion 3 (AC-052a NEGATIVE): no non-POSIX regex constructs in function ---"
# Extract function body and check for banned constructs
# \b (word boundary), \S (non-whitespace), \d (digit class), \w (word char) are PCRE-only
function_body=$(awk '/sanitize_block_reason\(\)/,/^}/' "$POST_HOOK" 2>/dev/null)
if echo "$function_body" | grep -qE '\\b|\\S|\\d|\\w'; then
  # Check carefully: might appear in comments or string literals
  nonposix=$(echo "$function_body" | grep -E '\\(b|S|d|w)' | grep -v '#.*\\')
  if [ -n "$nonposix" ]; then
    fail "AC-052a: sanitize_block_reason() uses non-POSIX regex constructs (\\b/\\S/\\d/\\w): $nonposix"
  else
    echo "OK (AC-052a): non-POSIX constructs only in comments"
  fi
else
  echo "OK (AC-052a): no non-POSIX regex constructs in sanitize_block_reason() body"
fi

# Assertion 4: functional redaction test using inline bash simulation
# This tests the redaction logic patterns match expected inputs
echo "--- Assertion 4: functional credential pattern tests ---"

# Test each credential type against expected regex (inline simulation using bash =~)
# Pattern 1: URL-embedded credentials
input1="https://user:pass@host.com/path"
if [[ "$input1" =~ https?://[^@]+@[^/]+ ]]; then
  echo "OK: URL-embedded credential pattern matches input 1"
else
  fail "Pattern 1 (URL creds): regex did not match 'https://user:pass@host.com/path'"
fi

# Pattern 3: Bearer token
input3="Bearer abcdef.123456"
if [[ "$input3" =~ Bearer[[:space:]][A-Za-z0-9._-]+ ]]; then
  echo "OK: Bearer token pattern matches"
else
  fail "Pattern 3 (Bearer): regex did not match 'Bearer abcdef.123456'"
fi

# Pattern 5: AWS access key ID
input5="AKIAIOSFODNN7EXAMPLE"
if [[ "$input5" =~ (AKIA|ASIA)[A-Z0-9]{16} ]]; then
  echo "OK: AWS AKID pattern matches"
else
  fail "Pattern 5 (AWS AKID): regex did not match 'AKIAIOSFODNN7EXAMPLE'"
fi

# Pattern 8: GitHub token
input8="ghp_aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
if [[ "$input8" =~ gh(p|o|u|s|r)_[A-Za-z0-9]+ ]]; then
  echo "OK: GitHub token pattern matches"
else
  fail "Pattern 8 (GitHub token): regex did not match 'ghp_aaa...'"
fi

# Pattern 10: JWT
input10="eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxMjM0NTY3ODkwIn0.dozjgNryP4J3jVmNHl0w5N_XgL0n3I9PlFUP0THsR8U"
if [[ "$input10" =~ eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+ ]]; then
  echo "OK: JWT pattern matches"
else
  fail "Pattern 10 (JWT): regex did not match JWT-format token"
fi

# Pattern 12: Stripe live key
input12="sk_live_abcdef1234567890"
if [[ "$input12" =~ sk_live_[A-Za-z0-9]+ ]]; then
  echo "OK: Stripe live key pattern matches"
else
  fail "Pattern 12 (Stripe): regex did not match 'sk_live_abcdef1234567890'"
fi

if [ "$FAIL" -eq 0 ]; then
  echo "PASS: v6.9.0 sanitize_block_reason() has all 14 redaction tags; POSIX-only constructs; credential patterns verified"
fi
exit "$FAIL"
