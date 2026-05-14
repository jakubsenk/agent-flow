#!/usr/bin/env bash
# ===========================================================================
# Test:     v10-strict-mode-exit.sh
# Checks: (1) CEOS_STRICT_DISPATCH=1 + WITNESS_MISMATCH => exit 2 + audit entry
#         (2) advisory mode => exit 0  (3) CEOS_STRICT_DISPATCH=0 => exit 0
#         (4) WITNESS_MISSING does NOT trigger strict exit 2
# Line budget: 40-80 lines. Expected GREEN: hook L129-L133 already implements.
# ===========================================================================
set -uo pipefail

REPO_ROOT="${CEOS_REPO_ROOT:-$(cd "$(dirname "$0")/../.." && pwd)}"
cd "$REPO_ROOT" || { echo "FAIL: cannot cd to REPO_ROOT=$REPO_ROOT" >&2; exit 1; }

FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

HOOK="hooks/validate-dispatch.sh"
[ -f "$HOOK" ] || { echo "SKIP: $HOOK not found" >&2; exit 77; }
[ -f "core/lib/stage-invariant.sh" ] || { echo "SKIP: core/lib/stage-invariant.sh not found" >&2; exit 77; }

# Fixture: non-hex witness => WITNESS_MISMATCH (strict-exit trigger)
tmp_state=$(mktemp 2>/dev/null || echo "${TMPDIR:-/tmp}/v10rel3_state_$$")
tmp_audit=$(mktemp 2>/dev/null || echo "${TMPDIR:-/tmp}/v10rel3_audit_$$")
trap 'rm -f "$tmp_state" "$tmp_audit"' EXIT

cat > "$tmp_state" <<'FIXTURE'
{
  "stages": {
    "publisher": {
      "dispatched_at": "2026-05-12T10:00:00Z",
      "dispatch_witness": "not_a_hex_witness"
    }
  }
}
FIXTURE

# ASSERT-1 + ASSERT-2: Strict mode => exit 2 AND audit log has WITNESS_MISMATCH entry
rc_strict=0
CEOS_STRICT_DISPATCH=1 CEOS_STATE_JSON="$tmp_state" CEOS_AUDIT_LOG="$tmp_audit" \
  bash "$HOOK" >/dev/null 2>&1 || rc_strict=$?
[ "$rc_strict" = "2" ] || fail "FC-REL-3.strict-exit: expected exit 2, got $rc_strict"
grep -q 'WITNESS_MISMATCH' "$tmp_audit" 2>/dev/null \
  || fail "FC-REL-3.audit-entry: WITNESS_MISMATCH not in audit log after strict-mode run"

# ASSERT-3: Advisory mode => exit 0
> "$tmp_audit"
rc_advisory=0
CEOS_STATE_JSON="$tmp_state" CEOS_AUDIT_LOG="$tmp_audit" \
  bash "$HOOK" >/dev/null 2>&1 || rc_advisory=$?
[ "$rc_advisory" = "0" ] || fail "FC-REL-3.advisory-exit: expected exit 0 in advisory mode, got $rc_advisory"

# ASSERT-4: CEOS_STRICT_DISPATCH=0 explicitly => exit 0
> "$tmp_audit"
rc_zero=0
CEOS_STRICT_DISPATCH=0 CEOS_STATE_JSON="$tmp_state" CEOS_AUDIT_LOG="$tmp_audit" \
  bash "$HOOK" >/dev/null 2>&1 || rc_zero=$?
[ "$rc_zero" = "0" ] || fail "FC-REL-3.explicit-zero: CEOS_STRICT_DISPATCH=0 exited $rc_zero (expected 0)"

# ASSERT-5: WITNESS_MISSING does NOT trigger exit 2 in strict mode
tmp_missing=$(mktemp 2>/dev/null || echo "${TMPDIR:-/tmp}/v10rel3_missing_$$")
trap 'rm -f "$tmp_state" "$tmp_audit" "$tmp_missing"' EXIT
# Stage has dispatched_at but NO dispatch_witness => MISSING
printf '{\n  "stages": {\n    "publisher": {\n      "dispatched_at": "2026-05-12T10:00:00Z"\n    }\n  }\n}\n' \
  > "$tmp_missing"
> "$tmp_audit"
rc_missing=0
CEOS_STRICT_DISPATCH=1 CEOS_STATE_JSON="$tmp_missing" CEOS_AUDIT_LOG="$tmp_audit" \
  bash "$HOOK" >/dev/null 2>&1 || rc_missing=$?
[ "$rc_missing" = "2" ] \
  && fail "FC-REL-3.missing-no-exit2: WITNESS_MISSING triggered strict exit 2 (MISSING is legitimate skip, only MISMATCH triggers)"

if [ "$FAIL" -eq 0 ]; then
  echo "PASS: v10-strict-mode-exit — CEOS_STRICT_DISPATCH=1 exits 2 on MISMATCH; advisory exits 0; MISSING does not trigger strict exit"
  exit 0
fi
exit 1
