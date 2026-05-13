#!/usr/bin/env bash
# Hidden test: AC-ITEM-3.2 — core/block-handler.md Step 5 uses heredoc + --proto + jq -n --arg
# Also asserts R-ITEM-3.4 negative: no inline -d '{...}' pattern remains.
# Covers: AC-ITEM-3.2 (5 positive patterns + 1 negative), AC-ITEM-3.4 (negative)
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../" && pwd)"
BLOCK_HANDLER="$REPO_ROOT/core/block-handler.md"

FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

echo "--- h-block-handler-heredoc (AC-ITEM-3.2, 3.4): Step 5 heredoc rewrite ---"

if [ ! -f "$BLOCK_HANDLER" ]; then
  echo "FAIL: core/block-handler.md not found at $BLOCK_HANDLER"
  exit 1
fi

# -----------------------------------------------------------------------
# AC-ITEM-3.2 positive checks (5 patterns per formal-criteria.md)
# -----------------------------------------------------------------------
echo "--- Positive: --data-binary @- present ---"
if grep -qE -- '--data-binary @-' "$BLOCK_HANDLER"; then
  echo "OK (AC-ITEM-3.2): --data-binary @- present in core/block-handler.md"
else
  fail "AC-ITEM-3.2: --data-binary @- missing from core/block-handler.md Step 5"
fi

echo "--- Positive: --proto '=http,https' present ---"
if grep -qE -- '--proto "=http,https"' "$BLOCK_HANDLER"; then
  echo "OK (AC-ITEM-3.2): --proto \"=http,https\" present in core/block-handler.md"
else
  fail "AC-ITEM-3.2: --proto \"=http,https\" missing from core/block-handler.md Step 5"
fi

echo "--- Positive: heredoc <<EOF present ---"
if grep -qE '<<EOF' "$BLOCK_HANDLER"; then
  echo "OK (AC-ITEM-3.2): heredoc <<EOF present in core/block-handler.md"
else
  fail "AC-ITEM-3.2: heredoc <<EOF missing from core/block-handler.md Step 5"
fi

echo "--- Positive: jq -n present ---"
if grep -qE 'jq -n' "$BLOCK_HANDLER"; then
  echo "OK (AC-ITEM-3.2): jq -n present in core/block-handler.md"
else
  fail "AC-ITEM-3.2: jq -n missing from core/block-handler.md Step 5"
fi

echo "--- Positive: --arg present ---"
if grep -qE -- '--arg' "$BLOCK_HANDLER"; then
  echo "OK (AC-ITEM-3.2): --arg flag present in core/block-handler.md"
else
  fail "AC-ITEM-3.2: --arg missing from core/block-handler.md Step 5 (needed for jq -n --arg structural payload)"
fi

# -----------------------------------------------------------------------
# AC-ITEM-3.2 negative: POSIX-unsafe ${var:1:-1} Bash substring trim MUST NOT appear
# -----------------------------------------------------------------------
echo "--- Negative (AC-ITEM-3.2): no POSIX-unsafe \${var:1:-1} substring trim ---"
if grep -qE '\$\{[A-Za-z_][A-Za-z0-9_]*:[0-9]+:-[0-9]+\}' "$BLOCK_HANDLER"; then
  fail "AC-ITEM-3.2: core/block-handler.md contains POSIX-unsafe Bash 4.2+ substring trim \${var:N:-N} — must use jq -n --arg instead"
else
  echo "OK (AC-ITEM-3.2): No POSIX-unsafe \${var:N:-N} substring trim in core/block-handler.md"
fi

# -----------------------------------------------------------------------
# AC-ITEM-3.4 negative: no inline -d '{...}' curl substitution
# -----------------------------------------------------------------------
echo "--- Negative (AC-ITEM-3.4): no inline -d '{...}' curl substitution ---"
# Match: curl on same line as -d followed by '{' (inline JSON payload)
if grep -qE "curl[^'\"]*-d '\\{" "$BLOCK_HANDLER"; then
  fail "AC-ITEM-3.4: core/block-handler.md still contains inline curl -d '\\{...\\}' pattern — must be replaced with heredoc"
else
  echo "OK (AC-ITEM-3.4): No inline curl -d '\\{...\\}' pattern in core/block-handler.md"
fi

# -----------------------------------------------------------------------
# Final result
# -----------------------------------------------------------------------
if [ "$FAIL" -eq 0 ]; then
  echo "PASS: h-block-handler-heredoc — Step 5 uses heredoc + --proto + jq -n --arg; no inline -d substitution"
fi
exit "$FAIL"
