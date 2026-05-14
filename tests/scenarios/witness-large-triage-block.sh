#!/usr/bin/env bash
# Regression test for grep -A window in check_dispatch_witness.
# Covers: bug where triage stage block with >=4 acceptance_criteria items
# pushed dispatch_witness beyond the original grep -A 8 context window,
# causing false WITNESS_MISSING verdicts on realistic production state.json.
#
# Real-world trigger: analyst stage with 5 acceptance_criteria items per
# CLAUDE.md (mandates 2-5 items). dispatch_witness may live at line ~13+
# in pretty-printed JSON. The grep window is -A 30 (6x safety margin).
#
# Repo-root resolution works when invoked from tests/scenarios/.
set -uo pipefail

REPO_ROOT="${CEOS_REPO_ROOT:-$(cd "$(dirname "$0")/../.." && pwd)}"
LIB="$REPO_ROOT/core/lib/stage-invariant.sh"
FIXTURE="$REPO_ROOT/tests/fixtures/witness/triage-5ac.json"

fail() { echo "FAIL: witness-large-triage-block — $1"; exit 1; }

[ -f "$LIB" ] || fail "stage-invariant.sh missing at $LIB"
[ -f "$FIXTURE" ] || fail "fixture missing at $FIXTURE"

# Verify fixture shape: dispatch_witness must be beyond line 8 from "triage" key.
TRIAGE_LINE=$(grep -n '"triage"[[:space:]]*:' "$FIXTURE" | head -n 1 | cut -d: -f1)
WITNESS_LINE=$(grep -n '"dispatch_witness"[[:space:]]*:' "$FIXTURE" | head -n 1 | cut -d: -f1)
[ -n "$TRIAGE_LINE" ] || fail "fixture lacks triage key"
[ -n "$WITNESS_LINE" ] || fail "fixture lacks dispatch_witness key"
DELTA=$((WITNESS_LINE - TRIAGE_LINE))
[ "$DELTA" -gt 8 ] || fail "fixture distance (${DELTA}) <= 8 lines — not exercising the bug (need >8 to prove -A 30 is wider than old -A 8)"

# Source the library and invoke check_dispatch_witness.
# shellcheck disable=SC1090
. "$LIB"

EXPECTED_WITNESS="aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
VERDICT=$(check_dispatch_witness "triage" "$FIXTURE" 2>/dev/null)
RC=$?

# Assertion 1: verdict must be WITNESS_OK (witness FOUND despite distance >8)
if [ "$VERDICT" != "WITNESS_OK" ]; then
    fail "ASSERT-1: verdict=${VERDICT} rc=${RC} for fixture with dispatch_witness at line ${WITNESS_LINE} (triage at line ${TRIAGE_LINE}, delta=${DELTA}). Expected WITNESS_OK rc=0. Likely cause: grep -A window too narrow."
fi

# Assertion 2: rc must be 0 (OK)
if [ "$RC" -ne 0 ]; then
    fail "ASSERT-2: rc=${RC} (expected 0) for WITNESS_OK verdict on valid witness"
fi

# Assertion 3 (structural): library must use -A 30 or greater (regression guard
# — prevents future regression to a narrower window).
if ! grep -qE 'grep[[:space:]]+-A[[:space:]]+(3[0-9]|[4-9][0-9]|[1-9][0-9]{2,})' "$LIB"; then
    fail "ASSERT-3: $LIB no longer contains 'grep -A 30' (or wider) — regression risk if window narrows back below realistic stage-block size"
fi

# Assertion 4: window must NOT be the old -A 8 form
if grep -qE 'grep[[:space:]]+-A[[:space:]]+8[^0-9]' "$LIB"; then
    fail "ASSERT-4: $LIB still contains 'grep -A 8' — regression: window narrowed below safe threshold"
fi

echo "PASS: witness-large-triage-block — 5-AC triage block (delta=${DELTA} lines) → WITNESS_OK rc=0; grep -A window >= 30 confirmed structurally"
exit 0
