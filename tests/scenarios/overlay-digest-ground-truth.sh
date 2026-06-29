#!/usr/bin/env bash
# ===========================================================================
# Test:     overlay-digest-ground-truth.sh                       [NAMED-4]
# AC:       AC-031 (REQ-031) — overlay_digest is GATE-COMPUTED-ONLY ground truth
#   (the S2 fix). The orchestrator does NOT commit overlay_digest; the gate reads
#   override_path/<short>.toml ONCE, recomputes the digest from those RAW
#   LF-normalized bytes, and SIGNS it into the ledger. There is NO
#   producer-claim-vs-gate digest compare (that compare was the Windows/CRLF
#   false-DENY surface). This drives:
#     (a) unmodified .toml, claim has NO overlay_digest -> ALLOW; the SIGNED
#         ledger digest == the gate's LF-normalized recompute (== sha256sum LF).
#     (CRLF) a CRLF .toml + a claim carrying a NAIVE CRLF digest -> ALLOW (the
#         Windows S2 regression: the OLD compare would false-DENY here); the
#         signed digest is the LF-normalized one, NOT the CRLF naive digest.
#     (b) forged override_path escaping the allowlist -> DENY (structural).
#     (c) overlay_source=toml but .toml ABSENT -> DENY + WITNESS_MISMATCH
#         (structural, not a crash).
#     (d) GROUND-TRUTH MISMATCH at AUDIT: edit the .toml AFTER the gate signs ->
#         PostToolUse audit re-verifies the SIGNED ledger digest vs the on-disk
#         file -> WITNESS_MISMATCH + exit 2.
#     (e) STRUCTURAL lock: the gate source carries NO producer-claim digest
#         compare (asserts the S2 surface stays removed forever).
#   Verdict STRING and exit CODE are both asserted (no truthiness).
# ===========================================================================
set -uo pipefail

REPO_ROOT="${AGENT_FLOW_REPO_ROOT:-$(cd "$(dirname "$0")/../.." && pwd)}"
cd "$REPO_ROOT" || { echo "FAIL: cannot cd to REPO_ROOT=$REPO_ROOT" >&2; exit 1; }
# shellcheck disable=SC1090
. "$REPO_ROOT/tests/lib/assert.sh"

FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }

GATE="${AGENT_FLOW_PRE_GATE:-$REPO_ROOT/hooks/validate-dispatch-pre.sh}"
AUDIT="$REPO_ROOT/hooks/validate-dispatch.sh"
PYBIN="$(command -v python3 || command -v python || true)"
[ -n "$PYBIN" ] || { echo "SKIP: python not runnable" >&2; exit 77; }
command -v sha256sum >/dev/null 2>&1 || { echo "SKIP: no sha256sum" >&2; exit 77; }
[ -f "$GATE" ]  || { fail "PreToolUse gate $GATE missing (REQ-016/REQ-031)"; echo "FAIL (RED): gate not implemented" >&2; exit 1; }
[ -f "$AUDIT" ] || { fail "PostToolUse audit $AUDIT missing (REQ-031/A5)"; echo "FAIL (RED): audit not implemented" >&2; exit 1; }

KEYHEX="00112233445566778899aabbccddeeff00112233445566778899aabbccddeeff"
RUN="PROJ-77_20260418T140000Z"
WORK="$(mktemp -d 2>/dev/null || echo "${TMPDIR:-/tmp}/ogt_$$")"
trap 'rm -rf "$WORK"' EXIT
PROJ="$WORK/proj"
RDIR="$PROJ/.agent-flow/$RUN"
mkdir -p "$RDIR" "$PROJ/customization"
printf '%s' "$KEYHEX" > "$RDIR/dispatch.key"; chmod 600 "$RDIR/dispatch.key" 2>/dev/null || true

# Byte-exact LF .toml + its LF-normalized digest (== sha256sum of the LF file).
"$PYBIN" - "$PROJ/customization/fixer.toml" <<'PY'
import sys
open(sys.argv[1], "wb").write(b'model = "sonnet"\nstyle = "Terse"\n')
PY
DIG_LF=$(sha256sum "$PROJ/customization/fixer.toml" | awk '{print $1}')

# write_claim OVERRIDE_PATH [BOGUS_DIGEST]
#   Corrected model: the CLAIM omits overlay_digest. When BOGUS_DIGEST is given,
#   it is committed anyway to PROVE the gate ignores it (no producer compare).
write_claim() {
  "$PYBIN" - "$RDIR/state.json" "$1" "${2:-}" <<'PY'
import json, sys
ovp, bogus = sys.argv[2], sys.argv[3]
stage = {"dispatched_at": "2026-04-18T14:00:00Z", "subagent_type": "agent-flow:fixer",
         "agent_name": "agent-flow:fixer", "model": "opus", "stage_name": "fixer_reviewer",
         "overlay_source": "toml", "override_path": ovp,
         "claim_nonce": "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", "dispatch_seq": 1,
         "status": "in_progress"}
if bogus:
    stage["overlay_digest"] = bogus   # deliberately wrong; the gate must ignore it
doc = {"schema_version": "2.0", "stages": {"fixer_reviewer": stage}}
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
run_gate() {  # echoes "rc|stdout"; resets+rewrites the ledger+marker each call
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
ledger_digest() {  # echoes the SIGNED overlay_digest of the last ledger entry
  "$PYBIN" - "$RDIR/dispatch-ledger.jsonl" <<'PY'
import json, sys
last = None
try:
    for ln in open(sys.argv[1], encoding="utf-8"):
        ln = ln.strip()
        if ln:
            last = json.loads(ln)
except OSError:
    pass
print((last or {}).get("overlay_digest", ""))
PY
}
run_audit() {  # echoes rc; re-verifies the ledger that the gate just signed
  local rc=0
  : > "$WORK/postaudit.log"
  ( cd "$PROJ" && \
    env -u AGENT_FLOW_STRICT_DISPATCH \
    AGENT_FLOW_STATE_JSON="$RDIR/state.json" \
    AGENT_FLOW_LEDGER="$RDIR/dispatch-ledger.jsonl" \
    AGENT_FLOW_DISPATCH_KEY_FILE="$RDIR/dispatch.key" \
    AGENT_FLOW_AUDIT_LOG="$WORK/postaudit.log" bash "$AUDIT" >/dev/null 2>&1 ) || rc=$?
  printf '%s' "$rc"
}

# (a) unmodified LF .toml, claim WITHOUT overlay_digest -> ALLOW; signed == LF.
write_claim "customization/"
R=$(run_gate); rc="${R%%|*}"; out="${R#*|}"
[ "$rc" = "0" ] || fail "(a) allow: gate exited $rc on a present overlay with no claim digest (expected ALLOW/0)"
! contains "$out" '"permissionDecision":"deny"' || fail "(a) allow: deny emitted on a clean overlay dispatch"
SIGNED=$(ledger_digest)
[ "$SIGNED" = "$DIG_LF" ] || fail "(a) signed: ledger overlay_digest ($SIGNED) != gate LF recompute ($DIG_LF)"

# (CRLF / S2 regression) CRLF .toml + a NAIVE CRLF digest in the claim -> ALLOW.
#   The OLD code compared the claim digest to the gate recompute and DENIED here
#   on Windows. The corrected gate signs its own LF-normalized digest and ignores
#   the claim, so the dispatch ALLOWs and the SIGNED value is the LF digest.
"$PYBIN" - "$PROJ/customization/fixer.toml" <<'PY'
import sys
open(sys.argv[1], "wb").write(b'model = "sonnet"\r\nstyle = "Terse"\r\n')
PY
DIG_CRLF=$(sha256sum "$PROJ/customization/fixer.toml" | awk '{print $1}')
[ "$DIG_CRLF" != "$DIG_LF" ] || fail "(CRLF) precondition: naive CRLF digest must differ from LF digest"
write_claim "customization/" "$DIG_CRLF"   # commit the WRONG (CRLF-naive) digest
R=$(run_gate); rc="${R%%|*}"; out="${R#*|}"
[ "$rc" = "0" ] || fail "(CRLF) S2-regression: gate exited $rc on a CRLF overlay (false-DENY — the S2 bug). Expected ALLOW/0"
! contains "$out" '"permissionDecision":"deny"' || fail "(CRLF) S2-regression: gate DENIED a CRLF overlay (producer-vs-gate compare reintroduced)"
SIGNED=$(ledger_digest)
[ "$SIGNED" = "$DIG_LF" ] || fail "(CRLF) signed: ledger digest ($SIGNED) != LF-normalized ($DIG_LF) — gate did not normalize"
[ "$SIGNED" != "$DIG_CRLF" ] || fail "(CRLF) signed: gate signed the NAIVE CRLF claim digest (must sign its own LF recompute)"

# (b) forged override_path escaping the allowlist -> DENY (structural).
"$PYBIN" - "$PROJ/customization/fixer.toml" <<'PY'
import sys
open(sys.argv[1], "wb").write(b'model = "sonnet"\nstyle = "Terse"\n')
PY
write_claim "../../../../etc/"
R=$(run_gate); rc="${R%%|*}"; out="${R#*|}"
[ "$rc" = "2" ] || fail "(b) escape: forged override_path outside allowlist exited $rc (expected DENY/2)"
contains "$out" '"permissionDecision":"deny"' || fail "(b) escape: no deny on allowlist escape"

# (c) overlay_source=toml but the .toml is ABSENT -> WITNESS_MISMATCH, NOT a crash.
rm -f "$PROJ/customization/fixer.toml"
write_claim "customization/"
R=$(run_gate); rc="${R%%|*}"; out="${R#*|}"
[ "$rc" = "2" ] || fail "(c) absent: gate exited $rc (expected 2) when claimed .toml is missing"
contains "$out" 'WITNESS_MISMATCH' || fail "(c) absent: missing .toml must be WITNESS_MISMATCH, not GATE_ERROR (got: $out)"

# (d) AUDIT ground-truth MISMATCH: sign a clean overlay, then edit the .toml on
#     disk; the audit re-verifies the SIGNED ledger digest vs the live file.
"$PYBIN" - "$PROJ/customization/fixer.toml" <<'PY'
import sys
open(sys.argv[1], "wb").write(b'model = "sonnet"\nstyle = "Terse"\n')
PY
write_claim "customization/"
R=$(run_gate); rc="${R%%|*}"
[ "$rc" = "0" ] || fail "(d) seed: gate did not ALLOW the clean overlay (rc=$rc) — cannot seed the audit"
arc=$(run_audit)
[ "$arc" = "0" ] || fail "(d) pre-edit audit: re-verify exited $arc on an unedited overlay (expected 0)"
matches_re "$(cat "$WORK/postaudit.log")" 'fixer_reviewer WITNESS_OK' || fail "(d) pre-edit: expected WITNESS_OK"
# Edit the .toml AFTER the gate signed -> the signed digest no longer matches disk.
"$PYBIN" - "$PROJ/customization/fixer.toml" <<'PY'
import sys
open(sys.argv[1], "wb").write(b'model = "sonnet"\nstyle = "terse"\n')   # T->t, one byte
PY
arc=$(run_audit)
[ "$arc" = "2" ] || fail "(d) post-edit audit: exited $arc (expected MISMATCH/2 — the .toml changed after the gate signed)"
matches_re "$(cat "$WORK/postaudit.log")" 'fixer_reviewer WITNESS_MISMATCH' \
  || fail "(d) post-edit: audit must record WITNESS_MISMATCH (signed ledger digest != on-disk .toml)"

# (e) STRUCTURAL lock: the gate carries NO producer-claim-vs-gate digest compare.
if grep -qE 'overlay_digest recomputed|ov_val[[:space:]]*!=[[:space:]]*overlay_digest' "$GATE"; then
  fail "(e) S2-lock: the gate still compares a producer-claim overlay_digest (false-DENY surface reintroduced)"
fi

if [ "$FAIL" -eq 0 ]; then
  echo "PASS: overlay-digest-ground-truth — gate-computed-only digest; CRLF overlay ALLOWs (S2 fixed); escape/absent DENY; post-sign edit -> audit MISMATCH/2; no producer compare"
  exit 0
fi
exit 1
