#!/usr/bin/env bash
# Scenario: REQ-024 — core/block-handler.md uses jq -nc (compact) not jq -n (pretty-print)
# Expected v6.9.0 outcome: PASS once Phase 7 implements
# Pre-implementation outcome: FAIL (TDD) — block-handler.md uses jq -n currently
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../" && pwd)"

FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

BLOCK_HANDLER="$REPO_ROOT/core/block-handler.md"

if [ ! -f "$BLOCK_HANDLER" ]; then
  echo "FAIL: core/block-handler.md not found" >&2
  exit 1
fi

# Assertion 1 (AC-024): jq -nc present in block-handler.md
echo "--- Assertion 1 (AC-024): jq -nc present in core/block-handler.md ---"
if grep -qE 'jq -nc' "$BLOCK_HANDLER"; then
  echo "OK (AC-024): jq -nc (compact) form present in core/block-handler.md"
else
  fail "AC-024: core/block-handler.md does not contain 'jq -nc' — heredoc payload patterns must produce compact single-line JSON"
fi

# Assertion 2 (AC-024 NEGATIVE): jq -n (without c) must NOT appear at the heredoc payload line
# The fix changes line 43 from 'jq -n' to 'jq -nc'; we allow 'jq -n ' as a substring in other contexts
# but specifically at the payload-building line it must be -nc
echo "--- Assertion 2 (AC-024 NEGATIVE): 'jq -n[^c]' absent at payload line in block-handler.md ---"
# If any 'jq -n ' (with space, not followed by c) remains: it means the line wasn't fixed
if grep -nE 'jq -n[^c]' "$BLOCK_HANDLER" | grep -v '<!--' | grep -q .; then
  # Report the violating lines
  violating=$(grep -nE 'jq -n[^c]' "$BLOCK_HANDLER" | grep -v '<!--')
  fail "AC-024: core/block-handler.md still has 'jq -n' without 'c' flag at: $violating"
else
  echo "OK (AC-024): no 'jq -n' (without c) outside comments in core/block-handler.md"
fi

if [ "$FAIL" -eq 0 ]; then
  echo "PASS: v6.9.0 core/block-handler.md uses jq -nc compact form for heredoc payloads"
fi
exit "$FAIL"
