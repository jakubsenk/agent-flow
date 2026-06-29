#!/usr/bin/env bash
# ===========================================================================
# Test:     overlay-digest-ground-truth.sh                       [NAMED-4]
# AC:       AC-031 (REQ-031) — the V2 "dropped/mutated overlay" detector.
#   The gate reads override_path/<short>.toml ONCE, recomputes the digest from
#   those exact RAW LF-normalized bytes, and COMPARES to the claimed
#   overlay_digest.  This drives:
#     (a) unmodified .toml whose claim matches  -> ALLOW (toml branch executed)
#     (b) .toml body edited by ONE byte         -> DENY + WITNESS_MISMATCH/exit 2
#     (c) overlay_source=toml but .toml ABSENT  -> WITNESS_MISMATCH (not a crash)
#     (d) forged override_path escaping the allowlist -> DENY (no redirect)
#   Verdict STRING and exit CODE are both asserted (no truthiness).
# ===========================================================================
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$REPO_ROOT" || { echo "FAIL: cannot cd to REPO_ROOT=$REPO_ROOT" >&2; exit 1; }
# shellcheck disable=SC1090
. "$REPO_ROOT/tests/lib/assert.sh"

FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

GATE="${AGENT_FLOW_PRE_GATE:-$REPO_ROOT/hooks/validate-dispatch-pre.sh}"
PYBIN="$(command -v python3 || command -v python || true)"
[ -n "$PYBIN" ] || { echo "SKIP: python not runnable" >&2; exit 77; }
command -v sha256sum >/dev/null 2>&1 || { echo "SKIP: no sha256sum" >&2; exit 77; }
[ -f "$GATE" ] || { fail "PreToolUse gate $GATE missing (REQ-016/REQ-031) — overlay ground-truth cannot be enforced"; echo "FAIL (RED): gate not yet implemented" >&2; exit 1; }

KEYHEX="00112233445566778899aabbccddeeff00112233445566778899aabbccddeeff"
RUN="PROJ-77_20260418T140000Z"
WORK="$(mktemp -d 2>/dev/null || echo "${TMPDIR:-/tmp}/ogt_$$")"
trap 'rm -rf "$WORK"' EXIT
PROJ="$WORK/proj"
RDIR="$PROJ/.agent-flow/$RUN"
mkdir -p "$RDIR" "$PROJ/customization"
printf '%s' "$KEYHEX" > "$RDIR/dispatch.key"; chmod 600 "$RDIR/dispatch.key" 2>/dev/null || true

# Original .toml + its true digest (independent ref).
printf 'model = "sonnet"\nstyle = "Terse"\n' > "$PROJ/customization/fixer.toml"
DIG=$(sha256sum "$PROJ/customization/fixer.toml" | awk '{print $1}')

write_claim() {  # $1 = overlay_digest  $2 = override_path
  "$PYBIN" - "$RDIR/state.json" "$1" "$2" <<'PY'
import json, sys
dig, ovp = sys.argv[2], sys.argv[3]
doc = {"schema_version": "2.0", "stages": {"fixer_reviewer": {
    "dispatched_at": "2026-04-18T14:00:00Z", "subagent_type": "agent-flow:fixer",
    "agent_name": "agent-flow:fixer", "model": "opus", "stage_name": "fixer_reviewer",
    "overlay_source": "toml", "overlay_digest": dig, "override_path": ovp,
    "claim_nonce": "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", "dispatch_seq": 1,
    "status": "in_progress"}}}
open(sys.argv[1], "w", encoding="utf-8").write(json.dumps(doc, indent=2))
PY
}
write_marker() {
  WNOW=$(date -u '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || echo "2026-04-18T14:00:00Z")
  "$PYBIN" - "$PROJ/.agent-flow/pending-dispatch.json" "$RUN" "$WNOW" <<'PY'
import json, sys
run, wnow = sys.argv[2], sys.argv[3]
m = {"run_id": run, "run_dir": ".agent-flow/%s" % run,
     "state_json": ".agent-flow/%s/state.json" % run, "stage": "fixer_reviewer",
     "subagent_type": "agent-flow:fixer",
     "claim_nonce": "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", "dispatch_seq": 1, "written_at": wnow}
open(sys.argv[1], "w", encoding="utf-8").write(json.dumps(m, indent=2))
PY
}
run_gate() {  # echoes "rc|stdout"; consumes+rewrites marker each call
  : > "$RDIR/dispatch-ledger.jsonl"
  write_marker
  local stdin_json rc out
  stdin_json=$("$PYBIN" - <<'PY'
import json
print(json.dumps({"hook_event_name":"PreToolUse","tool_name":"Task",
  "tool_input":{"subagent_type":"agent-flow:fixer","prompt":"do the fix","description":"x"}}))
PY
)
  rc=0
  out=$( cd "$PROJ" && printf '%s' "$stdin_json" | \
    env -u AGENT_FLOW_STRICT_DISPATCH \
    AGENT_FLOW_LEDGER="$RDIR/dispatch-ledger.jsonl" \
    AGENT_FLOW_DISPATCH_KEY_FILE="$RDIR/dispatch.key" \
    AGENT_FLOW_AUDIT_LOG="$WORK/audit.log" bash "$GATE" 2>/dev/null ) || rc=$?
  printf '%s|%s' "$rc" "$out"
}

# (a) unmodified .toml, claim matches recomputed digest -> ALLOW.
write_claim "$DIG" "customization/"
R=$(run_gate); rc="${R%%|*}"; out="${R#*|}"
[ "$rc" = "0" ] || fail "(a) allow: gate exited $rc on matching overlay digest (expected ALLOW/0)"
! contains "$out" '"permissionDecision":"deny"' || fail "(a) allow: deny emitted on a matching overlay"

# (b) one-byte edit on disk -> recomputed != claimed -> DENY + WITNESS_MISMATCH + exit 2.
printf 'model = "sonnet"\nstyle = "terse"\n' > "$PROJ/customization/fixer.toml"  # T->t, one byte
write_claim "$DIG" "customization/"   # claim still the ORIGINAL digest
R=$(run_gate); rc="${R%%|*}"; out="${R#*|}"
[ "$rc" = "2" ] || fail "(b) edit: gate exited $rc (expected 2) on one-byte overlay drift"
contains "$out" '"permissionDecision":"deny"' || fail "(b) edit: no deny decision on overlay drift"
contains "$out" 'WITNESS_MISMATCH' || fail "(b) edit: reason not WITNESS_MISMATCH (got: $out)"

# (c) overlay_source=toml but the .toml is ABSENT -> WITNESS_MISMATCH, NOT a crash.
rm -f "$PROJ/customization/fixer.toml"
write_claim "$DIG" "customization/"
R=$(run_gate); rc="${R%%|*}"; out="${R#*|}"
[ "$rc" = "2" ] || fail "(c) absent: gate exited $rc (expected 2) when claimed .toml is missing"
contains "$out" 'WITNESS_MISMATCH' || fail "(c) absent: missing .toml must be WITNESS_MISMATCH, not GATE_ERROR (got: $out)"

# (d) forged override_path escaping the allowlist -> DENY (digest target not redirected).
printf 'model = "sonnet"\nstyle = "Terse"\n' > "$PROJ/customization/fixer.toml"
write_claim "$DIG" "../../../../etc/"
R=$(run_gate); rc="${R%%|*}"; out="${R#*|}"
[ "$rc" = "2" ] || fail "(d) escape: forged override_path outside allowlist exited $rc (expected DENY/2)"
contains "$out" '"permissionDecision":"deny"' || fail "(d) escape: no deny on allowlist escape"

if [ "$FAIL" -eq 0 ]; then
  echo "PASS: overlay-digest-ground-truth — match→ALLOW; 1-byte edit→MISMATCH/2; absent→MISMATCH/2; allowlist escape→DENY/2"
  exit 0
fi
exit 1
