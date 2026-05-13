#!/usr/bin/env bash
# Hidden scenario: REQ-027a, REQ-027b, REQ-028 — block-handler counter-example HTML-comment filter + REPO_ROOT fix
# Expected v6.9.0 outcome: PASS once Phase 7 implements
# Pre-implementation outcome: FAIL (TDD) — counter-example not yet wrapped in HTML comment
set -uo pipefail

# CRITICAL: 3 levels up from .forge/phase-5-tdd/tests-hidden/ to repo root
# REQ-028 specifically fixes this exact pattern (was ../../ in v6.8.1)
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../" && pwd)"

if [ ! -f "$REPO_ROOT/.claude-plugin/plugin.json" ]; then
  echo "FAIL: REPO_ROOT path resolution bug — .claude-plugin/plugin.json not found at $REPO_ROOT" >&2
  echo "FAIL: Expected pattern is '../../../' (3 levels up from .forge/phase-5-tdd/tests-hidden/)" >&2
  exit 1
fi

FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

BLOCK_HANDLER="$REPO_ROOT/core/block-handler.md"

if [ ! -f "$BLOCK_HANDLER" ]; then
  echo "FAIL: core/block-handler.md not found" >&2; exit 1
fi

# Assertion 1 (REQ-028 / AC-028): REPO_ROOT was computed correctly (3 levels up)
echo "--- Assertion 1 (AC-028): REPO_ROOT resolves correctly (3 levels up) ---"
echo "OK (AC-028): REPO_ROOT = $REPO_ROOT (verified .claude-plugin/plugin.json found)"

# Assertion 2 (AC-027a): counter-example wrapped in HTML comment
echo "--- Assertion 2 (AC-027a): counter-example in HTML comment ---"
if grep -qF '<!-- COUNTER-EXAMPLE' "$BLOCK_HANDLER"; then
  echo "OK (AC-027a): '<!-- COUNTER-EXAMPLE' wrapper present in core/block-handler.md"
else
  fail "AC-027a: core/block-handler.md missing '<!-- COUNTER-EXAMPLE' HTML-comment wrapper"
fi

# Assertion 3 (AC-027b): tightened filter — grep -vE '<!-- COUNTER-EXAMPLE:'
# When we filter out COUNTER-EXAMPLE comment lines, the ${var:1:-1} pattern must NOT appear
echo "--- Assertion 3 (AC-027b): tightened filter '<!-- COUNTER-EXAMPLE:' works ---"
filtered=$(grep -vE '<!-- COUNTER-EXAMPLE:' "$BLOCK_HANDLER" 2>/dev/null)
if echo "$filtered" | grep -q '\${var:1:-1}'; then
  fail "AC-027b: \${var:1:-1} still visible after filtering '<!-- COUNTER-EXAMPLE:' lines — false-positive not suppressed"
else
  echo "OK (AC-027b): \${var:1:-1} absent from non-COUNTER-EXAMPLE lines after tightened filter"
fi

# Assertion 4: The original unfiltered file still contains the counter-example (it's documented, not deleted)
echo "--- Assertion 4: counter-example still present (documented, just wrapped) ---"
if grep -q '\${var:1:-1}' "$BLOCK_HANDLER"; then
  echo "OK: \${var:1:-1} counter-example preserved in HTML comment (not deleted)"
else
  fail "Counter-example \${var:1:-1} completely removed from block-handler.md — should be wrapped in comment, not deleted"
fi

# Assertion 5 (AC-024): jq -nc (compact) also verified here
echo "--- Assertion 5 (AC-024): jq -nc (compact) in block-handler.md ---"
if grep -qE 'jq -nc' "$BLOCK_HANDLER"; then
  echo "OK (AC-024): jq -nc compact form present"
else
  fail "AC-024: jq -nc missing — heredoc patterns should produce compact JSON"
fi

# The test itself must use grep -vE '<!-- COUNTER-EXAMPLE:' (per AC-027b)
# This is the self-referential check: our filter is tighter than bare <!--
echo "--- Assertion 6 (AC-027b self-check): this test uses tightened '<!-- COUNTER-EXAMPLE:' filter ---"
# This assertion verifies that the current script file uses the tightened filter form
THIS_SCRIPT="${BASH_SOURCE[0]}"
if grep -qF "grep -vE '<!-- COUNTER-EXAMPLE:'" "$THIS_SCRIPT"; then
  echo "OK (AC-027b): this test uses the tightened '<!-- COUNTER-EXAMPLE:' filter form (with colon)"
else
  fail "AC-027b: this test script does not use 'grep -vE '<!-- COUNTER-EXAMPLE:'' — tightened filter required per Devil's-Advocate F-15"
fi

if [ "$FAIL" -eq 0 ]; then
  echo "PASS: h-block-handler-heredoc — REPO_ROOT 3-levels-up; counter-example in HTML comment; tightened filter works; jq -nc"
fi
exit "$FAIL"
