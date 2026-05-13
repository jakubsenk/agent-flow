#!/usr/bin/env bash
# v6.10.0-skill-dispatch-enforcement.REWRITE.sh — REQ-V910-009:
# Layer 4 functional test: validates dispatch enforcement end-to-end.
# Ground-up rewrite: runs unconditionally (no jq guard, no conditional wrapper guard).
# Fixtures are hand-authored bash heredocs (no make_state_json — that helper
# uses jq internally and exits 77 SKIP on jq-free machines, violating REQ-V910-009).
#
# Pre-fix: test was SKIPPED via jq guard + conditional wrapper (dead code path).
# Post-fix: test PASSES unconditionally on jq-present and jq-free machines.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
. "$REPO_ROOT/tests/lib/fixtures.sh"

HOOK="$REPO_ROOT/hooks/validate-dispatch.sh"

FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

# ---------------------------------------------------------------------------
# Pre-flight: hook must exist.
# ---------------------------------------------------------------------------
if [ ! -f "$HOOK" ]; then
  fail "hooks/validate-dispatch.sh not found at $HOOK"
  exit 1
fi

SCRATCH="$(setup_scratch)"

# ---------------------------------------------------------------------------
# Positive case: all 5 stages have ISO-timestamped dispatched_at.
# Hand-authored heredoc — no jq, no make_state_json.
# Expected: each stage emits "OK" verdict in audit log (>= 5 OK lines).
# ---------------------------------------------------------------------------
echo "--- AC-T2-7-1 (positive): all stages dispatched ---"
cat > "$SCRATCH/state-positive.json" <<'EOF'
{
  "schema_version": "1.0",
  "run_id": "TEST-DISPATCH-POS",
  "status": "running",
  "started_at": "2026-04-30T12:00:00Z",
  "updated_at": "2026-04-30T12:05:00Z",
  "triage": {
    "dispatched_at": "2026-04-30T12:00:00Z",
    "status": "done"
  },
  "code_analysis": {
    "dispatched_at": "2026-04-30T12:01:00Z",
    "status": "done"
  },
  "fixer_reviewer": {
    "dispatched_at": "2026-04-30T12:02:00Z",
    "iterations": 1,
    "status": "done"
  },
  "test": {
    "dispatched_at": "2026-04-30T12:03:00Z",
    "status": "done"
  },
  "publisher": {
    "dispatched_at": "2026-04-30T12:04:00Z",
    "status": "done"
  },
  "tokens_used": 0,
  "pipeline": { "stages": [] }
}
EOF

LOG_POS="$SCRATCH/audit-positive.log"
CEOS_STATE_JSON="$SCRATCH/state-positive.json" CEOS_AUDIT_LOG="$LOG_POS" \
  bash "$HOOK" </dev/null >/dev/null 2>&1 \
  || fail "Hook must exit 0 (positive case)"

ok_count=$(grep -c ' OK$' "$LOG_POS" 2>/dev/null || echo 0)
if [ "$ok_count" -ge 5 ]; then
  echo "OK: positive case — $ok_count OK verdict(s) in audit log (>= 5 expected)"
else
  fail "Positive case: expected >= 5 OK verdicts, got $ok_count"
fi

# ---------------------------------------------------------------------------
# Negative case: only triage has dispatched_at; other stages absent from JSON.
# Expected: 4 MISSING verdicts (code_analysis, fixer_reviewer, test, publisher).
# ---------------------------------------------------------------------------
echo "--- AC-T2-7-2 (negative): only triage dispatched ---"
cat > "$SCRATCH/state-sparse.json" <<'EOF'
{
  "schema_version": "1.0",
  "run_id": "TEST-DISPATCH-NEG",
  "status": "running",
  "started_at": "2026-04-30T12:00:00Z",
  "updated_at": "2026-04-30T12:00:30Z",
  "triage": {
    "dispatched_at": "2026-04-30T12:00:00Z",
    "status": "done"
  },
  "tokens_used": 0,
  "pipeline": { "stages": [] }
}
EOF

LOG_SPARSE="$SCRATCH/audit-sparse.log"
CEOS_STATE_JSON="$SCRATCH/state-sparse.json" CEOS_AUDIT_LOG="$LOG_SPARSE" \
  bash "$HOOK" </dev/null >/dev/null 2>&1 \
  || fail "Hook must exit 0 even with missing dispatched_at (negative case)"

missing_count=$(grep -c ' MISSING$' "$LOG_SPARSE" 2>/dev/null || echo 0)
if [ "$missing_count" -ge 4 ]; then
  echo "OK: negative case — $missing_count MISSING verdict(s) for stages without dispatched_at (>= 4 expected)"
else
  fail "Negative case: expected >= 4 MISSING verdicts, got $missing_count"
fi

# ---------------------------------------------------------------------------
# Log format check: each audit line must have >= 3 space-separated fields.
# Format: <ISO_TS> <stage> <verdict>
# ---------------------------------------------------------------------------
echo "--- Log format: >= 3 fields per line ---"
first_line=$(grep ' OK$\| MISSING$' "$LOG_POS" | head -1 2>/dev/null || echo "")
if [ -n "$first_line" ]; then
  field_count=$(echo "$first_line" | awk '{print NF}')
  if [ "$field_count" -ge 3 ]; then
    echo "OK: audit log line has $field_count fields (>= 3 required): '$first_line'"
  else
    fail "Audit log line has only $field_count fields (< 3): '$first_line'"
  fi
else
  fail "No OK or MISSING lines found in positive audit log — cannot verify format"
fi

# ---------------------------------------------------------------------------
# Adversarial: bypassPermissions stdin path.
# Hook must exit 0 and emit an [INFO] bypassPermissions line in the audit log.
# ---------------------------------------------------------------------------
echo "--- Adversarial: bypassPermissions mode ---"
cat > "$SCRATCH/state-bypass.json" <<'EOF'
{
  "schema_version": "1.0",
  "run_id": "TEST-DISPATCH-BYPASS",
  "status": "running",
  "started_at": "2026-04-30T12:00:00Z",
  "updated_at": "2026-04-30T12:00:30Z",
  "triage": {
    "dispatched_at": "2026-04-30T12:00:00Z",
    "status": "done"
  },
  "tokens_used": 0,
  "pipeline": { "stages": [] }
}
EOF

LOG_BYPASS="$SCRATCH/audit-bypass.log"
BYPASS_JSON='{"permission_mode":"bypassPermissions","tool":"Bash","input":{}}'
CEOS_STATE_JSON="$SCRATCH/state-bypass.json" CEOS_AUDIT_LOG="$LOG_BYPASS" \
  bash "$HOOK" <<< "$BYPASS_JSON" >/dev/null 2>&1 \
  || fail "Hook must exit 0 in bypassPermissions mode"

if grep -qi 'bypass' "$LOG_BYPASS" 2>/dev/null; then
  echo "OK: audit log contains bypassPermissions INFO line"
elif command -v jq >/dev/null 2>&1; then
  # jq is present: hook should have parsed the stdin JSON and emitted the INFO line
  fail "Audit log missing bypassPermissions INFO line (jq is available — hook should have detected bypass mode)"
else
  # jq is absent: hook's L58 stdin-parse is out of scope (Finding 1); bypass detection
  # silently falls through. Hook still exits 0, which is the core requirement.
  echo "INFO: bypassPermissions INFO line not emitted on jq-free machine (L58 stdin-parse requires jq; out of scope per Finding 1)"
fi

# ---------------------------------------------------------------------------
# Stringified-null rejection: dispatched_at: "null" must yield MISSING,
# not OK. DP1 strict regex requires a digit after the opening quote.
# ---------------------------------------------------------------------------
echo "--- Stringified-null rejection: dispatched_at: 'null' must yield MISSING ---"
cat > "$SCRATCH/state-null.json" <<'EOF'
{
  "schema_version": "1.0",
  "run_id": "TEST-DISPATCH-NULL",
  "status": "running",
  "started_at": "2026-04-30T12:00:00Z",
  "updated_at": "2026-04-30T12:00:30Z",
  "triage": {
    "dispatched_at": "null",
    "status": "done"
  },
  "code_analysis": {
    "dispatched_at": "null",
    "status": "done"
  },
  "fixer_reviewer": {
    "dispatched_at": "null",
    "iterations": 0,
    "status": "done"
  },
  "test": {
    "dispatched_at": "null",
    "status": "done"
  },
  "publisher": {
    "dispatched_at": "null",
    "status": "done"
  },
  "tokens_used": 0,
  "pipeline": { "stages": [] }
}
EOF

LOG_NULL="$SCRATCH/audit-null.log"
CEOS_STATE_JSON="$SCRATCH/state-null.json" CEOS_AUDIT_LOG="$LOG_NULL" \
  bash "$HOOK" </dev/null >/dev/null 2>&1 \
  || fail "Hook must exit 0 even with stringified-null dispatched_at"

ok_null=0; ok_null=$(grep -c ' OK$' "$LOG_NULL" 2>/dev/null) || ok_null=0
missing_null=0; missing_null=$(grep -c ' MISSING$' "$LOG_NULL" 2>/dev/null) || missing_null=0
if [ "$ok_null" -eq 0 ] && [ "$missing_null" -ge 5 ]; then
  echo "OK: all 5 stages with dispatched_at:'null' yield MISSING (strict regex rejects string 'null')"
elif [ "$ok_null" -gt 0 ]; then
  fail "Stringified-null case: $ok_null stage(s) incorrectly yielded OK (strict regex not enforced)"
else
  fail "Stringified-null case: unexpected verdict counts (OK=$ok_null MISSING=$missing_null)"
fi

# ---------------------------------------------------------------------------
# Final verdict.
# ---------------------------------------------------------------------------
if [ "$FAIL" -eq 0 ]; then
  echo "PASS: Layer 4 dispatch enforcement functional test (jq-free, runs unconditionally)"
fi
exit "$FAIL"
