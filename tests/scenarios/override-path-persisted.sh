#!/usr/bin/env bash
# ===========================================================================
# Test:     override-path-persisted.sh
# AC:       AC-032 (REQ-032) — the resolved override_path is persisted in
#   state.json and READ FROM THERE by the hook (not from AGENT_FLOW_OVERRIDE_PATH
#   env, which the Claude-Code-spawned hook never inherits). A NON-default path
#   `custom-ovr/` is persisted with a matching .toml while the env var points
#   somewhere empty; V2 must NOT be a no-op for the non-default path.
#     match (read via state.json path) -> ALLOW
#     one-byte edit of THAT .toml      -> DENY (proves it read the persisted path)
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
[ -f "$GATE" ] || { fail "gate $GATE missing (REQ-032)"; echo "FAIL (RED): gate not implemented" >&2; exit 1; }

WORK="$(mktemp -d 2>/dev/null || echo "${TMPDIR:-/tmp}/opp_$$")"
trap 'rm -rf "$WORK"' EXIT
KEYHEX="00112233445566778899aabbccddeeff00112233445566778899aabbccddeeff"
RUN="PROJ-6_20260418T210000Z"
PROJ="$WORK/proj"; RDIR="$PROJ/.agent-flow/$RUN"
mkdir -p "$RDIR" "$PROJ/custom-ovr" "$PROJ/env-empty"
printf '%s' "$KEYHEX" > "$RDIR/dispatch.key"
printf 'model = "sonnet"\nstyle = "Brisk"\n' > "$PROJ/custom-ovr/fixer.toml"
DIG=$(sha256sum "$PROJ/custom-ovr/fixer.toml" | awk '{print $1}')

write_claim() {  # persisted override_path = custom-ovr/
  "$PYBIN" - "$RDIR/state.json" "$1" <<'PY'
import json, sys
dig=sys.argv[2]
doc={"schema_version":"2.0","stages":{"fixer_reviewer":{
  "dispatched_at":"2026-04-18T21:00:00Z","subagent_type":"agent-flow:fixer",
  "agent_name":"agent-flow:fixer","model":"opus","stage_name":"fixer_reviewer",
  "overlay_source":"toml","overlay_digest":dig,"override_path":"custom-ovr/",
  "claim_nonce":"60606060606060606060606060606060","dispatch_seq":1,"status":"in_progress"}}}
open(sys.argv[1],"w",encoding="utf-8").write(json.dumps(doc, indent=2))
PY
}
run_gate() {
  : > "$RDIR/dispatch-ledger.jsonl"
  local wnow; wnow=$(date -u '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || echo "2026-04-18T21:00:00Z")
  "$PYBIN" - "$PROJ/.agent-flow/pending-dispatch.json" "$RUN" "$wnow" <<'PY'
import json, sys
run, wnow = sys.argv[2], sys.argv[3]
open(sys.argv[1],"w",encoding="utf-8").write(json.dumps({
  "run_id":run,"run_dir":".agent-flow/%s"%run,"state_json":".agent-flow/%s/state.json"%run,
  "stage":"fixer_reviewer","subagent_type":"agent-flow:fixer",
  "claim_nonce":"60606060606060606060606060606060","dispatch_seq":1,"written_at":wnow}, indent=2))
PY
  local stdin_json rc out
  stdin_json=$("$PYBIN" - <<'PY'
import json
print(json.dumps({"hook_event_name":"PreToolUse","tool_name":"Task",
  "tool_input":{"subagent_type":"agent-flow:fixer","prompt":"fix","description":"x"}}))
PY
)
  rc=0
  # env var deliberately points at an EMPTY dir; the gate must IGNORE it and use state.json.
  out=$( cd "$PROJ" && printf '%s' "$stdin_json" | \
    env -u AGENT_FLOW_STRICT_DISPATCH \
    AGENT_FLOW_OVERRIDE_PATH="env-empty/" \
    AGENT_FLOW_LEDGER="$RDIR/dispatch-ledger.jsonl" \
    AGENT_FLOW_DISPATCH_KEY_FILE="$RDIR/dispatch.key" \
    AGENT_FLOW_AUDIT_LOG="$WORK/a.log" bash "$GATE" 2>/dev/null ) || rc=$?
  printf '%s|%s' "$rc" "$out"
}

# match: gate reads custom-ovr/fixer.toml via state.json override_path -> ALLOW.
write_claim "$DIG"
R=$(run_gate); rc="${R%%|*}"; out="${R#*|}"
[ "$rc" = "0" ] || fail "match: gate exited $rc (expected ALLOW/0) — V2 is a no-op for the persisted non-default path"
! contains "$out" '"permissionDecision":"deny"' || fail "match: deny despite a matching overlay at the persisted path"

# one-byte edit of THAT file -> DENY (proves the gate read the persisted-path file).
printf 'model = "sonnet"\nstyle = "brisk"\n' > "$PROJ/custom-ovr/fixer.toml"
R=$(run_gate); rc="${R%%|*}"; out="${R#*|}"
[ "$rc" = "2" ] || fail "edit: gate exited $rc (expected DENY/2) — it did not hash the persisted-path .toml"
contains "$out" 'WITNESS_MISMATCH' || fail "edit: reason not WITNESS_MISMATCH (got: $out)"

if [ "$FAIL" -eq 0 ]; then
  echo "PASS: override-path-persisted — gate resolves overlay from state.json override_path (custom-ovr/), ignoring the env var; V2 not a no-op"
  exit 0
fi
exit 1
