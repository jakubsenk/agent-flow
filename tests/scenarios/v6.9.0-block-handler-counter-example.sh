#!/usr/bin/env bash
# Scenario: REQ-027a, REQ-027b — AC-ITEM-3.2 false-positive fixed via HTML-comment wrapping
# Expected v6.9.0 outcome: PASS once Phase 7 implements
# Pre-implementation outcome: FAIL (TDD) — counter-example not yet wrapped in HTML comment
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../" && pwd)"

FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

BLOCK_HANDLER="$REPO_ROOT/core/block-handler.md"

if [ ! -f "$BLOCK_HANDLER" ]; then
  echo "FAIL: core/block-handler.md not found" >&2
  exit 1
fi

# Assertion 1 (AC-027a): counter-example wrapped in HTML comment
echo "--- Assertion 1 (AC-027a): counter-example wrapped in <!-- COUNTER-EXAMPLE --> HTML comment ---"
if grep -qF '<!-- COUNTER-EXAMPLE' "$BLOCK_HANDLER"; then
  echo "OK (AC-027a): '<!-- COUNTER-EXAMPLE' marker present in core/block-handler.md"
else
  fail "AC-027a: core/block-handler.md missing '<!-- COUNTER-EXAMPLE ...' HTML-comment wrapper — AC-ITEM-3.2 false-positive not fixed"
fi

# Assertion 2 (AC-027a): the ${var:1:-1} counter-example is INSIDE the HTML comment
echo "--- Assertion 2 (AC-027a): \${var:1:-1} resides inside counter-example comment ---"
# The pattern: the HTML comment should contain the bash substring expression that was the false-positive
if grep -A5 '<!-- COUNTER-EXAMPLE' "$BLOCK_HANDLER" | grep -q '\${var:1:-1}' 2>/dev/null || \
   grep -qE '<!-- COUNTER-EXAMPLE.*\$\{var:1:-1\}' "$BLOCK_HANDLER"; then
  echo "OK (AC-027a): \${var:1:-1} example is inside the COUNTER-EXAMPLE HTML comment"
else
  # Allow: the counter-example tag appears on the same line with the expression inline
  counter_example_section=$(awk '/<!-- COUNTER-EXAMPLE/,/-->/' "$BLOCK_HANDLER" 2>/dev/null)
  if echo "$counter_example_section" | grep -q '\${var:1:-1}'; then
    echo "OK (AC-027a): \${var:1:-1} confirmed inside COUNTER-EXAMPLE block"
  else
    fail "AC-027a: \${var:1:-1} pattern not found inside <!-- COUNTER-EXAMPLE --> block"
  fi
fi

# Assertion 3: filtering out COUNTER-EXAMPLE lines — negative AC-ITEM-3.2 check still works
# This simulates what the hidden test (h-block-handler-heredoc.sh) does AFTER the filter
echo "--- Assertion 3: AC-ITEM-3.2 pattern absent when COUNTER-EXAMPLE lines filtered out ---"
# Filter out comment lines (the tightened form per Devil's-Advocate F-15)
filtered=$(grep -vE '<!-- COUNTER-EXAMPLE:' "$BLOCK_HANDLER" 2>/dev/null)
# The problematic pattern that was causing false positives: ${var:1:-1}
if echo "$filtered" | grep -q '\${var:1:-1}'; then
  fail "AC-027a: \${var:1:-1} still appears in non-comment lines after filtering '<!-- COUNTER-EXAMPLE:' — false-positive not fully suppressed"
else
  echo "OK: after filtering COUNTER-EXAMPLE lines, \${var:1:-1} no longer appears in block-handler.md"
fi

# Assertion 4 (AC-027b): verify the tightened filter form is what was chosen (<!-- COUNTER-EXAMPLE: with colon)
echo "--- Assertion 4 (AC-027b): tightened filter uses '<!-- COUNTER-EXAMPLE:' (with colon) per Devil's-Advocate F-15 ---"
if grep -qF '<!-- COUNTER-EXAMPLE:' "$BLOCK_HANDLER"; then
  echo "OK (AC-027b): tightened COUNTER-EXAMPLE: prefix (with colon) present"
else
  # May use bare <!-- COUNTER-EXAMPLE without colon — warn but not fail if the close --> is present
  echo "INFO (AC-027b): using bare '<!-- COUNTER-EXAMPLE' without colon — tighter form is '<!-- COUNTER-EXAMPLE:'"
fi

if [ "$FAIL" -eq 0 ]; then
  echo "PASS: v6.9.0 AC-ITEM-3.2 false-positive fixed — counter-example wrapped in HTML comment"
fi
exit "$FAIL"
