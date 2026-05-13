#!/usr/bin/env bash
# v9.1.0-audit-log-byte-equivalence.sh — REQ-V910-007, REQ-V910-008:
# Audit-log lines (excluding ISO timestamp column 1) are byte-identical
# between the v9.0.2 jq-based hook and the v9.1.0 bash-only replacement.
#
# Hidden oracle test (20% tier). Requires jq on the test runner because
# the v9.0.2 baseline side invokes jq internally.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
. "$REPO_ROOT/tests/lib/fixtures.sh"

# This test inherently requires jq to run the v9.0.2 jq-based baseline hook.
# This is intentionally different from v6.10.0-skill-dispatch-enforcement.sh
# which must NOT require jq (REQ-V910-009).
require_jq

FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

HOOK_NEW="$REPO_ROOT/hooks/validate-dispatch.sh"
TMP="$(setup_scratch)"

# ---------------------------------------------------------------------------
# Retrieve the v9.0.2 jq-based hook via explicit-SHA git-show.
# CRITICAL: NOT HEAD~1 (Round-3 R2-003 fix). The hook was last modified in
# commit 1acd479 (v9.0.2 jq baseline). Intermediate Phase 7 commits do not
# touch the hook, so HEAD~1 would yield the bash-only hook → false-pass.
# git log -2 returns the 2 most-recent commits that modified the file;
# tail -1 selects the older one = the v9.0.2 jq-based hook.
# ---------------------------------------------------------------------------
BASELINE_SHA=""
BASELINE_SHA=$(git -C "$REPO_ROOT" log -2 --format='%H' -- hooks/validate-dispatch.sh | tail -1) || true

if [ -z "$BASELINE_SHA" ]; then
  echo "SKIP: Cannot resolve baseline SHA for hooks/validate-dispatch.sh (shallow clone or no prior commit)" >&2
  exit 77
fi

HOOK_OLD="$TMP/old-hook.sh"
if ! git -C "$REPO_ROOT" show "${BASELINE_SHA}:hooks/validate-dispatch.sh" > "$HOOK_OLD" 2>/dev/null; then
  echo "SKIP: Cannot retrieve baseline hook from git history (SHA $BASELINE_SHA)" >&2
  exit 77
fi
chmod +x "$HOOK_OLD"

# Sanity-check: the old hook should contain jq (that is what we are diffing against)
if ! grep -q '\bjq\b' "$HOOK_OLD" 2>/dev/null; then
  fail "Baseline hook at $BASELINE_SHA does not contain jq — wrong commit resolved; SHA=$BASELINE_SHA"
fi

# ---------------------------------------------------------------------------
# Build test fixtures.
# All 5 stages have ISO-timestamped dispatched_at (positive / all-OK case).
# ---------------------------------------------------------------------------
FIXTURE_POSITIVE="$TMP/state-positive.json"
cat > "$FIXTURE_POSITIVE" <<'EOF'
{
  "schema_version": "1.0",
  "run_id": "TEST-EQUIV-POS",
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

# ---------------------------------------------------------------------------
# Stringified-null case: dispatched_at is the string "null" — must be REJECTED.
# DP1 strict regex: "dispatched_at"[[:space:]]*:[[:space:]]*"[0-9] requires digit
# after the open-quote, so "null" does not satisfy it. Both hooks should emit MISSING.
# ---------------------------------------------------------------------------
FIXTURE_NULL="$TMP/state-stringified-null.json"
cat > "$FIXTURE_NULL" <<'EOF'
{
  "schema_version": "1.0",
  "run_id": "TEST-EQUIV-NULL",
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

# ---------------------------------------------------------------------------
# Missing-stage case: only triage has dispatched_at; others absent from object.
# ---------------------------------------------------------------------------
FIXTURE_MISSING="$TMP/state-missing-stage.json"
cat > "$FIXTURE_MISSING" <<'EOF'
{
  "schema_version": "1.0",
  "run_id": "TEST-EQUIV-MISS",
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

# ---------------------------------------------------------------------------
# bypassPermissions stdin fixture.
# ---------------------------------------------------------------------------
BYPASS_STDIN='{"permission_mode":"bypassPermissions","tool":"Bash","input":{}}'

# ---------------------------------------------------------------------------
# Helper: run one fixture through both hooks, strip timestamps, diff.
# $1 = label (no spaces)
# $2 = fixture path
# $3 = optional stdin string (empty string = no stdin)
# ---------------------------------------------------------------------------
run_equiv_check() {
  local label="$1"
  local fixture="$2"
  local stdin_data="${3:-}"

  local log_old="$TMP/baseline-jq-${label}.log"
  local log_new="$TMP/replacement-bash-${label}.log"
  local stripped_old="$TMP/stripped-old-${label}.txt"
  local stripped_new="$TMP/stripped-new-${label}.txt"

  # Remove stale log files from prior runs
  rm -f "$log_old" "$log_new" "$stripped_old" "$stripped_new"

  if [ -n "$stdin_data" ]; then
    CEOS_STATE_JSON="$fixture" CEOS_AUDIT_LOG="$log_old" \
      bash "$HOOK_OLD" <<< "$stdin_data" >/dev/null 2>&1 || true
    CEOS_STATE_JSON="$fixture" CEOS_AUDIT_LOG="$log_new" \
      bash "$HOOK_NEW" <<< "$stdin_data" >/dev/null 2>&1 || true
  else
    CEOS_STATE_JSON="$fixture" CEOS_AUDIT_LOG="$log_old" \
      bash "$HOOK_OLD" </dev/null >/dev/null 2>&1 || true
    CEOS_STATE_JSON="$fixture" CEOS_AUDIT_LOG="$log_new" \
      bash "$HOOK_NEW" </dev/null >/dev/null 2>&1 || true
  fi

  # Audit data goes to CEOS_AUDIT_LOG — not stdout (Round-3 R2-004 fix).
  # Verify log files were produced.
  if [ ! -f "$log_old" ]; then
    fail "[$label] Baseline (jq) hook did not produce audit log at $log_old"
    return
  fi
  if [ ! -f "$log_new" ]; then
    fail "[$label] Replacement (bash) hook did not produce audit log at $log_new"
    return
  fi

  # Strip column 1 (ISO timestamp — differs per run by design).
  # awk '{$1=""; print $0}' produces " stage verdict" with leading space.
  # Both sides go through same transform so the leading space cancels out.
  awk '{$1=""; print $0}' "$log_old" > "$stripped_old"
  awk '{$1=""; print $0}' "$log_new" > "$stripped_new"

  # Byte-identical check (timestamp-stripped).
  if diff -q "$stripped_old" "$stripped_new" >/dev/null 2>&1; then
    echo "OK [$label]: audit-log content (excluding timestamp column 1) is byte-identical"
  else
    fail "[$label] Byte-equivalence FAILED — jq baseline vs bash replacement differ (timestamp-stripped)"
    echo "--- jq baseline (stripped) ---" >&2
    cat "$stripped_old" >&2
    echo "--- bash replacement (stripped) ---" >&2
    cat "$stripped_new" >&2
  fi
}

# ---------------------------------------------------------------------------
# REQ-V910-008: Run all 3 fixture cases.
# ---------------------------------------------------------------------------
echo "--- REQ-V910-008: audit-log byte-equivalence ---"

echo "  Case 1: positive (all 5 stages with ISO dispatched_at)"
run_equiv_check "positive" "$FIXTURE_POSITIVE" ""

echo "  Case 2: stringified-null dispatched_at (must REJECT → all MISSING)"
run_equiv_check "null" "$FIXTURE_NULL" ""

echo "  Case 3: missing-stage (only triage present)"
run_equiv_check "missing" "$FIXTURE_MISSING" ""

# ---------------------------------------------------------------------------
# Edge case: bypassPermissions stdin path.
# Both versions must emit the [INFO] bypassPermissions line in the audit log.
# The INFO line content must also be byte-identical (strip timestamp col 1).
# ---------------------------------------------------------------------------
echo "  Case 4: bypassPermissions stdin edge case"
run_equiv_check "bypass" "$FIXTURE_POSITIVE" "$BYPASS_STDIN"

# Additionally assert the [INFO] line is actually present in the baseline log.
BYPASS_LOG_OLD="$TMP/baseline-jq-bypass.log"
if [ -f "$BYPASS_LOG_OLD" ]; then
  if ! grep -qi 'bypasspermissions' "$BYPASS_LOG_OLD" 2>/dev/null; then
    fail "[bypass] Old hook audit log missing bypassPermissions INFO line"
  else
    echo "OK [bypass]: baseline hook emits bypassPermissions INFO line"
  fi
fi

BYPASS_LOG_NEW="$TMP/replacement-bash-bypass.log"
if [ -f "$BYPASS_LOG_NEW" ]; then
  if ! grep -qi 'bypasspermissions' "$BYPASS_LOG_NEW" 2>/dev/null; then
    fail "[bypass] New hook audit log missing bypassPermissions INFO line"
  else
    echo "OK [bypass]: replacement hook emits bypassPermissions INFO line"
  fi
fi

# ---------------------------------------------------------------------------
# REQ-V910-007: Verify loop site is jq-free in the current (new) hook.
# This is a source-level assertion supplementing the behavioral byte-equiv check.
# ---------------------------------------------------------------------------
echo "--- REQ-V910-007: loop site jq-free in new hook ---"
loop_jq_count=$(awk '/^[[:space:]]*for[[:space:]]+stage/,/^[[:space:]]*done/' "$HOOK_NEW" | grep -c '\bjq\b' || true)
if [ "${loop_jq_count:-0}" -eq 0 ]; then
  echo "OK: new hook loop site contains 0 jq invocations"
else
  fail "New hook loop site still contains jq (count=$loop_jq_count)"
fi

total_jq_count=$(grep -cE '^[^#]*\bjq\b' "$HOOK_NEW" || true)
if [ "${total_jq_count:-0}" -le 1 ]; then
  echo "OK: new hook total jq invocations <= 1 (found: $total_jq_count)"
else
  fail "New hook total jq invocations > 1 (found: $total_jq_count); only L58 stdin-parse is permitted"
fi

# ---------------------------------------------------------------------------
# Final verdict.
# ---------------------------------------------------------------------------
if [ "$FAIL" -eq 0 ]; then
  echo "PASS: v9.1.0-audit-log-byte-equivalence — all fixture cases byte-identical, loop site jq-free"
fi
exit "$FAIL"
