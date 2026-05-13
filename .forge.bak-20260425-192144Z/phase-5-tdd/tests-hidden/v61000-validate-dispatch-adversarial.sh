#!/usr/bin/env bash
# AC: AC-T2-4-4, AC-T2-4-5 (adversarial — hidden)
# Adversarial fixtures for hooks/validate-dispatch.sh:
# malformed JSON, very large input, permission_mode=bypassPermissions,
# stage name with shell metacharacters. Assert hook never crashes.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../" && pwd)"
HOOK="$REPO_ROOT/hooks/validate-dispatch.sh"

FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

[ -f "$HOOK" ] || { fail "hooks/validate-dispatch.sh missing"; exit 1; }

if ! command -v jq >/dev/null 2>&1; then
  echo "SKIP: jq not available"
  exit 77
fi

# Adversarial case 1: malformed JSON in state.json
echo 'this is not json }{' > "$TMP/malformed.json"
exit_code=0
CEOS_STATE_JSON="$TMP/malformed.json" CEOS_AUDIT_LOG="$TMP/log1.log" \
  bash "$HOOK" >/dev/null 2>&1 || exit_code=$?
[ "$exit_code" -eq 0 ] || fail "Hook crashed on malformed state.json (exit $exit_code)"

# Adversarial case 2: very large input (state with 100KB+ random field)
big_val=$(python3 -c "print('A'*102400)" 2>/dev/null || printf '%0.s A' {1..1000})
echo "{\"triage\":{\"dispatched_at\":\"2026-04-23T12:00:00Z\",\"big\":\"$big_val\"}}" \
  > "$TMP/large.json"
exit_code=0
CEOS_STATE_JSON="$TMP/large.json" CEOS_AUDIT_LOG="$TMP/log2.log" \
  bash "$HOOK" >/dev/null 2>&1 || exit_code=$?
[ "$exit_code" -eq 0 ] || fail "Hook crashed on large state.json (exit $exit_code)"

# Adversarial case 3: permission_mode=bypassPermissions (autopilot case per research)
# Hook should still write audit log and exit 0
jq -n '{
  triage: {dispatched_at: "2026-04-23T12:00:00Z"},
  permission_mode: "bypassPermissions"
}' > "$TMP/bypassperms.json"
exit_code=0
CEOS_STATE_JSON="$TMP/bypassperms.json" CEOS_AUDIT_LOG="$TMP/log3.log" \
  bash "$HOOK" >/dev/null 2>&1 || exit_code=$?
[ "$exit_code" -eq 0 ] || fail "Hook crashed with permission_mode=bypassPermissions"
ok_count=$(grep -c 'OK\|MISSING' "$TMP/log3.log" 2>/dev/null || echo 0)
[ "$ok_count" -ge 1 ] || fail "Hook did not write audit log with bypassPermissions input"

# Adversarial case 4: stage name with shell metacharacters injected into state field
jq -n '{
  "triage;rm -rf /tmp": {dispatched_at: "2026-04-23T12:00:00Z"},
  triage: {dispatched_at: "2026-04-23T12:00:00Z"}
}' > "$TMP/metachar.json"
exit_code=0
CEOS_STATE_JSON="$TMP/metachar.json" CEOS_AUDIT_LOG="$TMP/log4.log" \
  bash "$HOOK" >/dev/null 2>&1 || exit_code=$?
[ "$exit_code" -eq 0 ] || fail "Hook crashed with metacharacter stage name (exit $exit_code)"
# Verify the metacharacter key did NOT cause shell execution
[ -f "/tmp/injected" ] && fail "Shell injection succeeded (file /tmp/injected exists)" || true

# Adversarial case 5: state.json with null dispatched_at
jq -n '{triage: {dispatched_at: null}, code_analysis: {}}' > "$TMP/nulls.json"
exit_code=0
CEOS_STATE_JSON="$TMP/nulls.json" CEOS_AUDIT_LOG="$TMP/log5.log" \
  bash "$HOOK" >/dev/null 2>&1 || exit_code=$?
[ "$exit_code" -eq 0 ] || fail "Hook crashed on null dispatched_at (exit $exit_code)"
missing=$(grep -c 'MISSING' "$TMP/log5.log" 2>/dev/null || echo 0)
[ "$missing" -ge 1 ] || fail "null dispatched_at should produce MISSING verdict"

echo "PASS: validate-dispatch.sh adversarial fixtures all survived"
exit "$FAIL"
