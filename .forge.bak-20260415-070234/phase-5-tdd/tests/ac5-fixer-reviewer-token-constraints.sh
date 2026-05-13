#!/usr/bin/env bash
# Test: fixer.md has NEEDS_DECOMPOSITION constraint; reviewer.md has Verdict and AC fulfillment constraints
# AC-5: fixer and reviewer have explicit token-spelling constraints
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"

FAIL=0
fail() { echo "FAIL: $1"; FAIL=1; }

FIXER="$REPO_ROOT/agents/fixer.md"
REVIEWER="$REPO_ROOT/agents/reviewer.md"

if [ ! -f "$FIXER" ]; then
  fail "Missing file: agents/fixer.md"
  exit 1
fi
if [ ! -f "$REVIEWER" ]; then
  fail "Missing file: agents/reviewer.md"
  exit 1
fi

# --- fixer.md checks ---

FIXER_CONSTRAINTS=$(awk '/^## Constraints/{found=1} found{print}' "$FIXER")

if [ -z "$FIXER_CONSTRAINTS" ]; then
  fail "agents/fixer.md has no ## Constraints section"
fi

# Must have a MUST rule explicitly enforcing exact string NEEDS_DECOMPOSITION
if ! echo "$FIXER_CONSTRAINTS" | grep "MUST" | grep -q "NEEDS_DECOMPOSITION"; then
  fail "agents/fixer.md Constraints section does not have a MUST rule enforcing exact spelling of 'NEEDS_DECOMPOSITION'"
fi

# The MUST rule should say "exact string" or be clearly about spelling (not just the existing NEVER rules)
# Accept any MUST line that references NEEDS_DECOMPOSITION
FIXER_MUST_LINE=$(echo "$FIXER_CONSTRAINTS" | grep "MUST" | grep "NEEDS_DECOMPOSITION" | head -1)
if [ -z "$FIXER_MUST_LINE" ]; then
  fail "agents/fixer.md Constraints: no MUST line found referencing NEEDS_DECOMPOSITION"
fi

# --- reviewer.md checks ---

REVIEWER_CONSTRAINTS=$(awk '/^## Constraints/{found=1} found{print}' "$REVIEWER")

if [ -z "$REVIEWER_CONSTRAINTS" ]; then
  fail "agents/reviewer.md has no ## Constraints section"
fi

# Rule 1: Verdict token — must have MUST rule with APPROVE, REQUEST_CHANGES, BLOCK
if ! echo "$REVIEWER_CONSTRAINTS" | grep "MUST" | grep -q "Verdict\|APPROVE\|REQUEST_CHANGES"; then
  fail "agents/reviewer.md Constraints section does not have a MUST rule for Verdict token spelling"
fi

VERDICT_MUST_LINE=$(echo "$REVIEWER_CONSTRAINTS" | grep "MUST" | grep -i "verdict\|APPROVE" | head -1)

if ! echo "$VERDICT_MUST_LINE" | grep -q "APPROVE"; then
  fail "agents/reviewer.md Constraints MUST rule for Verdict does not mention 'APPROVE'"
fi
if ! echo "$VERDICT_MUST_LINE" | grep -q "REQUEST_CHANGES"; then
  fail "agents/reviewer.md Constraints MUST rule for Verdict does not mention 'REQUEST_CHANGES'"
fi
if ! echo "$VERDICT_MUST_LINE" | grep -q "BLOCK"; then
  fail "agents/reviewer.md Constraints MUST rule for Verdict does not mention 'BLOCK'"
fi

# Rule 2: AC fulfillment token — must have MUST rule with FULFILLED, PARTIALLY, NOT ADDRESSED
if ! echo "$REVIEWER_CONSTRAINTS" | grep "MUST" | grep -qi "fulfilled\|partially\|not addressed"; then
  fail "agents/reviewer.md Constraints section does not have a MUST rule for AC fulfillment token spelling"
fi

AC_MUST_LINE=$(echo "$REVIEWER_CONSTRAINTS" | grep "MUST" | grep -i "fulfilled\|PARTIALLY\|NOT ADDRESSED" | head -1)

if ! echo "$AC_MUST_LINE" | grep -q "FULFILLED"; then
  fail "agents/reviewer.md Constraints MUST rule for AC fulfillment does not mention 'FULFILLED'"
fi
if ! echo "$AC_MUST_LINE" | grep -q "PARTIALLY"; then
  fail "agents/reviewer.md Constraints MUST rule for AC fulfillment does not mention 'PARTIALLY'"
fi
if ! echo "$AC_MUST_LINE" | grep -q "NOT ADDRESSED"; then
  fail "agents/reviewer.md Constraints MUST rule for AC fulfillment does not mention 'NOT ADDRESSED'"
fi

[ "$FAIL" -eq 0 ] && echo "PASS: agents/fixer.md has MUST rule for NEEDS_DECOMPOSITION spelling; agents/reviewer.md has MUST rules for Verdict (APPROVE/REQUEST_CHANGES/BLOCK) and AC fulfillment (FULFILLED/PARTIALLY/NOT ADDRESSED) spelling"
exit "$FAIL"
