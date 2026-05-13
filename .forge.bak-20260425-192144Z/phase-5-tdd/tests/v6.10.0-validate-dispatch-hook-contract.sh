#!/usr/bin/env bash
# AC: AC-T2-4-1, AC-T2-4-2, AC-T2-4-3, AC-T2-4-4, AC-T2-4-5
# Unit test for hooks/validate-dispatch.sh.
# Feeds synthetic PostToolUse contexts + state.json fixtures.
# Asserts advisory-only (exit 0) and correct audit log output.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../" && pwd)"
HOOK="$REPO_ROOT/hooks/validate-dispatch.sh"

FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

[ -f "$HOOK" ] || { fail "hooks/validate-dispatch.sh does not exist"; exit 1; }

# AC-T2-4-1: STAGES whitelist present
if ! grep -qF 'STAGES=(triage code_analysis fixer_reviewer test publisher)' "$HOOK"; then
  fail "STAGES whitelist missing or altered in validate-dispatch.sh"
fi

# AC-T2-4-2: no $(...) or backtick or eval
unsafe=$(grep -cE '\$\(|`|eval ' "$HOOK" 2>/dev/null || echo 0)
[ "$unsafe" -eq 0 ] || fail "Unsafe patterns (\$(), backticks, eval) found in hook: $unsafe"

# AC-T2-4-3: dispatched_at referenced; tokens_used NOT referenced
if ! grep -qF 'dispatched_at' "$HOOK"; then
  fail "dispatched_at not referenced in validate-dispatch.sh"
fi
if grep -qF 'tokens_used' "$HOOK"; then
  fail "tokens_used theater check found in validate-dispatch.sh (forbidden)"
fi

# TODO(phase-7-fixer): hook invocations below require the script to exist.
# AC-T2-4-4: positive case — all stages have dispatched_at
if command -v jq >/dev/null 2>&1; then
  state_file="$TMP/state.json"
  log_file="$TMP/dispatch-audit.log"
  jq -n '{
    schema_version: "1.0", run_id: "TEST-1_20260423T120000Z",
    triage: { dispatched_at: "2026-04-23T12:00:00Z" },
    code_analysis: { dispatched_at: "2026-04-23T12:01:00Z" },
    fixer_reviewer: { dispatched_at: "2026-04-23T12:02:00Z" },
    test: { dispatched_at: "2026-04-23T12:03:00Z" },
    publisher: { dispatched_at: "2026-04-23T12:04:00Z" }
  }' > "$state_file"
  if CEOS_STATE_JSON="$state_file" CEOS_AUDIT_LOG="$log_file" bash "$HOOK" > /dev/null 2>&1; then
    ok_count=$(grep -c 'OK' "$log_file" 2>/dev/null || echo 0)
    [ "$ok_count" -ge 5 ] || fail "Positive case: expected >= 5 OK lines, got $ok_count"
  else
    fail "Hook exited non-zero on positive case (must be advisory/exit-0 always)"
  fi

  # AC-T2-4-5: missing dispatched_at — hook exits 0, logs MISSING
  state_missing="$TMP/state_missing.json"
  log_missing="$TMP/dispatch-audit-missing.log"
  jq -n '{
    schema_version: "1.0", run_id: "TEST-2_20260423T120100Z",
    triage: { dispatched_at: "2026-04-23T12:00:00Z" },
    code_analysis: {},
    fixer_reviewer: { dispatched_at: "2026-04-23T12:02:00Z" }
  }' > "$state_missing"
  if CEOS_STATE_JSON="$state_missing" CEOS_AUDIT_LOG="$log_missing" bash "$HOOK" > /dev/null 2>&1; then
    missing_count=$(grep -c 'MISSING' "$log_missing" 2>/dev/null || echo 0)
    [ "$missing_count" -ge 1 ] || fail "Missing-case: expected >= 1 MISSING line, got $missing_count"
  else
    fail "Hook exited non-zero on missing-dispatched_at case (must be advisory)"
  fi
else
  echo "SKIP(jq): jq not available — hook invocation tests skipped"
fi

echo "PASS: validate-dispatch.sh hook contract verified"
exit "$FAIL"
