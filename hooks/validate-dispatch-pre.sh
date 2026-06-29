#!/usr/bin/env bash
# hooks/validate-dispatch-pre.sh
# PreToolUse gate (gate-as-signer) for the dispatch witness (PR #15).
#
# Matches tool_name == "Task". This is the ONLY component that holds the
# per-run key and the ONLY one that can BLOCK a dispatch (deny-JSON + exit 2,
# which blocks Task on Claude Code >= 2.1.90 — issue #26923). The orchestrator
# writes only the CLAIM; the gate observes the real tool_input, resolves the
# in-flight dispatch from the top-level marker (.agent-flow/pending-dispatch.json,
# NEVER glob[-1]), applies match-or-pass-through, runs the forge-resistant key
# bootstrap, observes-and-signs head128(tool_input.prompt) as ground truth,
# compares the deterministically-reproducible CLAIM fields, signs the HMAC tag
# into the gate-owned ledger, and ALLOWs (clearing the marker) — or DENYs.
#
# Pipeline (design.md §2 / §3.3):
#   STRICT_DISPATCH_OFF (top-level flag) FIRST  ->  marker read  ->
#   match-or-pass-through  ->  bootstrap (REQ-047)  ->  observe-and-sign head ->
#   compare COMPARED fields  ->  tag  ->  ledger append  ->  ALLOW + clear marker
#   (or DENY deny-JSON + exit 2; fail-closed on the gate's OWN error).
#
# Keyed compute/verify lives ONLY in Python (hooks/lib/witness_core.py +
# hooks/lib/witness_key.py) — bash holds NO keyed path (REQ-010 / REQ-030).
#
# EXIT: 0 = ALLOW / pass-through. 2 = DENY (true block). Fail-closed: any
#       internal error under strict -> DENY + exit 2 (never exit 0/1 silently).
#
# Env vars (clean-break AGENT_FLOW_ prefix):
#   AGENT_FLOW_STRICT_DISPATCH    strict ON unless == "0" (advisory)
#   AGENT_FLOW_DISPATCH_KEY_FILE  key-file PATH override (never the value)
#   AGENT_FLOW_LEDGER             gate ledger path override
#   AGENT_FLOW_AUDIT_LOG          audit-log path override (best-effort WARN line)
#   AGENT_FLOW_MARKER_TTL         marker freshness window (seconds, default 120)
# Flag files (not env): top-level .agent-flow/STRICT_DISPATCH_OFF (checked FIRST,
#   before any marker/run resolution) and per-run <run_dir>/STRICT_DISPATCH_OFF.
set -uo pipefail

# Deny envelope used on the no-runnable-Python fail-closed path (must be the
# byte-identical no-space shape Claude Code parses; matches the Python emitter).
DENY_NO_PYTHON='{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"GATE_ERROR: no runnable Python interpreter (agent-flow requires Python 3 stdlib)"}}'

# --- strict determination for the no-Python path (env + TOP-LEVEL flag only;
#     the per-run flag needs run resolution, which itself needs Python) --------
strict=1
[ "${AGENT_FLOW_STRICT_DISPATCH:-}" = "0" ] && strict=0
[ -f ".agent-flow/STRICT_DISPATCH_OFF" ] && strict=0

# --- runnability probe (A4 / REQ-018): probe `-c 'import sys'`, NOT command -v.
PYBIN=""
for cand in python3 python; do
  if command -v "$cand" >/dev/null 2>&1 && "$cand" -c 'import sys' >/dev/null 2>&1; then
    PYBIN="$cand"
    break
  fi
done
if [ -z "$PYBIN" ]; then
  if [ "$strict" -eq 1 ]; then
    printf '%s' "$DENY_NO_PYTHON"
    exit 2
  fi
  exit 0   # advisory: never block
fi

# --- resolve the shared Python lib dir (sibling of this hook) ------------------
SELF="${BASH_SOURCE[0]:-$0}"
HOOKDIR="$(cd "$(dirname "$SELF")" 2>/dev/null && pwd)"
[ -n "$HOOKDIR" ] || HOOKDIR="$(dirname "$SELF")"
LIBDIR="$HOOKDIR/lib"

# --- capture the hook stdin JSON to a temp file (the heredoc below is the
#     Python program, so stdin is unavailable to the program itself) -----------
HOOK_IN="$(mktemp 2>/dev/null || echo "${TMPDIR:-/tmp}/afgate_in_$$")"
cat > "$HOOK_IN"

"$PYBIN" - "$HOOK_IN" "$LIBDIR" <<'PY'
import sys, os, json, datetime

HOOK_IN = sys.argv[1]
LIBDIR  = sys.argv[2]
sys.path.insert(0, LIBDIR)

import witness_core as wc      # canon / tag / head128 / dispatch_witness_alg
import witness_key as wk       # generate / read / discover / bootstrap_decision

DENY_CANARY = "agent-flow:__deny_canary__"
MARKER_REL  = os.path.join(".agent-flow", "pending-dispatch.json")


def now_iso():
    return datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def emit_deny(reason):
    # No-space separators so the envelope matches Claude Code's parser exactly.
    sys.stdout.write(json.dumps(
        {"hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "deny",
            "permissionDecisionReason": reason}},
        separators=(",", ":")))


def audit_log_path():
    return os.environ.get("AGENT_FLOW_AUDIT_LOG",
                          os.path.join(".agent-flow", "dispatch-audit.log"))


def best_effort_append(path, text):
    try:
        d = os.path.dirname(path)
        if d:
            os.makedirs(d, exist_ok=True)
        with open(path, "a", encoding="utf-8") as f:
            f.write(text)
    except Exception:
        pass


def maybe_warn_version():
    # REQ-049 item 3: one-time WARN to the audit log while the Claude Code
    # >= 2.1.90 block precondition is unconfirmed (no .version-confirmed marker).
    try:
        if os.path.exists(os.path.join(".agent-flow", ".version-confirmed")):
            return
    except Exception:
        return
    best_effort_append(
        audit_log_path(),
        "%s [WARN] PreToolUse Task block unconfirmed (need Claude Code >= 2.1.90)\n"
        % now_iso())


def strict_in_effect(run_dir):
    # Advisory (REQ-020/REQ-050) when ANY of: env == "0"; TOP-LEVEL flag file;
    # per-run flag file. The top-level flag needs no run resolution.
    if os.environ.get("AGENT_FLOW_STRICT_DISPATCH", "") == "0":
        return False
    if os.path.exists(os.path.join(".agent-flow", "STRICT_DISPATCH_OFF")):
        return False
    if run_dir and os.path.exists(os.path.join(run_dir, "STRICT_DISPATCH_OFF")):
        return False
    return True


def load_json(path):
    try:
        with open(path, encoding="utf-8") as f:
            return json.load(f)
    except Exception:
        return None


def read_claim(state_json, stage):
    doc = load_json(state_json) or {}
    stages = doc.get("stages") or {}
    if not isinstance(stages, dict):
        return None
    s = stages.get(stage)
    return s if isinstance(s, dict) else None


def ledger_consumed(ledger_path, run_id):
    """Return (set_of_consumed_claim_nonces, max_dispatch_seq_or_None) for run_id."""
    consumed = set()
    last_seq = None
    try:
        with open(ledger_path, encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue
                try:
                    e = json.loads(line)
                except Exception:
                    continue
                if run_id and str(e.get("run_id") or "") != str(run_id):
                    continue
                cn = e.get("claim_nonce")
                if cn is not None:
                    consumed.add(str(cn))
                try:
                    ds = int(e.get("dispatch_seq"))
                    if last_seq is None or ds > last_seq:
                        last_seq = ds
                except (TypeError, ValueError):
                    pass
    except (FileNotFoundError, NotADirectoryError, IsADirectoryError, OSError):
        pass
    return consumed, last_seq


def marker_ttl():
    try:
        v = int(os.environ.get("AGENT_FLOW_MARKER_TTL", "120"))
        return v if v > 0 else 120
    except (TypeError, ValueError):
        return 120


def marker_is_stale(written_at, ttl):
    # Belt-and-suspenders over the load-bearing dispatch_seq/claim_nonce checks:
    # an unparseable or future timestamp NEVER stale-denies.
    if not written_at:
        return False
    try:
        wt = datetime.datetime.strptime(
            written_at, "%Y-%m-%dT%H:%M:%SZ").replace(tzinfo=datetime.timezone.utc)
    except Exception:
        return False
    age = (datetime.datetime.now(datetime.timezone.utc) - wt).total_seconds()
    return age > ttl


def append_ledger(ledger_path, entry):
    d = os.path.dirname(ledger_path)
    if d:
        os.makedirs(d, exist_ok=True)
    with open(ledger_path, "a", encoding="utf-8") as f:
        f.write(json.dumps(entry, separators=(",", ":")) + "\n")


def clear_marker(marker_path):
    try:
        os.unlink(marker_path)
    except OSError:
        pass


def main():
    # 1. Read the intercepted hook payload (own error -> fail closed).
    hook = load_json(HOOK_IN)
    if hook is None:
        # Strict here uses env + top-level flag (no run dir resolved yet).
        if strict_in_effect(None):
            emit_deny("GATE_ERROR: unreadable hook input")
            return 2
        return 0
    ti = hook.get("tool_input") or {}
    observed_subagent = str(ti.get("subagent_type") or "")
    observed_prompt = ti.get("prompt")
    observed_prompt = observed_prompt if isinstance(observed_prompt, str) else ""

    # 2. Deny-canary sentinel (REQ-049): unconditionally DENY (subject only to
    #    the advisory rollback toggle, like every other gate DENY).
    if observed_subagent == DENY_CANARY:
        if strict_in_effect(None):
            emit_deny("WITNESS_UNVERIFIABLE: deny-canary sentinel (version handshake)")
            return 2
        return 0

    # 3. Marker read + match-or-pass-through (REQ-046). NEVER glob[-1].
    marker = load_json(MARKER_REL) if os.path.isfile(MARKER_REL) else None
    if not isinstance(marker, dict) or \
       str(marker.get("subagent_type") or "") != observed_subagent:
        # marker absent OR subagent_type != observed -> PASS THROUGH (no sign).
        maybe_warn_version()
        return 0

    # Matched marker -> resolve the in-flight dispatch deterministically.
    run_id      = str(marker.get("run_id") or "")
    state_json  = str(marker.get("state_json") or "")
    run_dir     = str(marker.get("run_dir") or "")
    if not run_dir and state_json:
        run_dir = os.path.dirname(state_json)
    stage       = str(marker.get("stage") or "")
    claim_nonce = str(marker.get("claim_nonce") or "")
    try:
        marker_seq = int(marker.get("dispatch_seq"))
    except (TypeError, ValueError):
        marker_seq = None
    written_at  = str(marker.get("written_at") or "")

    strict = strict_in_effect(run_dir)

    def deny(reason):
        if strict:
            emit_deny(reason)
            return 2
        return 0   # advisory rollback: downgrade DENY -> allow (no signing)

    ledger_path = os.environ.get("AGENT_FLOW_LEDGER") or \
        os.path.join(run_dir, "dispatch-ledger.jsonl")

    # 3a. Stale / replay (row g1) — the load-bearing anti-replay checks first.
    consumed, last_seq = ledger_consumed(ledger_path, run_id)
    if claim_nonce and claim_nonce in consumed:
        return deny("WITNESS_UNVERIFIABLE: claim_nonce already consumed (replay)")
    if marker_seq is not None and last_seq is not None and marker_seq <= last_seq:
        return deny("WITNESS_UNVERIFIABLE: dispatch_seq <= last consumed (stale marker)")
    if marker_is_stale(written_at, marker_ttl()):
        return deny("WITNESS_UNVERIFIABLE: marker stale (past freshness window)")

    # 3b. Key bootstrap (REQ-047) — forge-resistant; never silent-regenerate.
    key_path = os.environ.get("AGENT_FLOW_DISPATCH_KEY_FILE") or \
        wk.discover_key(state_json)
    decision = wk.bootstrap_decision(key_path, state_json, ledger_path)
    if decision == wk.DECISION_LEGACY:
        # No keyed contract yet (schema 1.0 / unset) -> pass through to the audit.
        return 0
    if decision == wk.DECISION_UNVERIFIABLE:
        return deny("WITNESS_UNVERIFIABLE: key absent on a progressed run "
                    "(>=1 completed stage or non-empty ledger; never regenerate)")
    if decision == wk.DECISION_GENERATE:
        try:
            keyhex = wk.generate_key(key_path)   # genuine first intercept (row i)
        except OSError:
            return deny("GATE_ERROR: key generation failed")   # fail closed
    else:  # DECISION_KEYED
        keyhex = wk.read_key(key_path)
        if keyhex is None:
            return deny("WITNESS_UNVERIFIABLE: per-run key unreadable")

    # 3c. CLAIM + compare the deterministically-reproducible COMPARED fields.
    claim = read_claim(state_json, stage)
    if claim is None:
        return deny("WITNESS_UNVERIFIABLE: no CLAIM for marker-resolved stage")
    claim_subagent = str(claim.get("subagent_type") or claim.get("agent_name") or "")
    claim_model    = str(claim.get("model") or "")
    overlay_source = str(claim.get("overlay_source") or "")
    overlay_digest = str(claim.get("overlay_digest") or "")

    # subagent_type: full namespace-prefixed identity, compared byte-for-byte.
    if observed_subagent != claim_subagent:
        return deny("WITNESS_MISMATCH: subagent_type observed (%s) != claim (%s)"
                    % (observed_subagent, claim_subagent))

    # model: deterministic resolution. (Shared-parser overlay resolution is wired
    # in by task-009; here the resolved value is the CLAIM model, with a
    # tool_input.model cross-check where the runtime supplies it — REQ-048.)
    ti_model = ti.get("model")
    if isinstance(ti_model, str) and ti_model and ti_model != claim_model:
        return deny("WITNESS_MISMATCH: tool_input.model (%s) != claim model (%s)"
                    % (ti_model, claim_model))
    resolved_model = claim_model

    # (overlay_source / overlay_digest are taken from the CLAIM here; the gate's
    #  on-disk RAW .toml recompute + compare is added in task-009.)

    # 3d. Observe-and-sign the prompt head as GROUND TRUTH (REQ-003/REQ-051):
    #     NOT compared against any orchestrator claim.
    observed_head = wc.head128(observed_prompt)

    # 3e. Compute the HMAC tag over the canonical preimage (folds claim_nonce).
    c = wc.canon(observed_subagent, resolved_model, observed_head,
                 overlay_source, overlay_digest, stage, run_id, claim_nonce)
    sig = wc.tag(keyhex, c)

    # 3f. Append the gate-owned ledger line keyed by (run_id, stage, claim_nonce).
    entry = {
        "run_id": run_id, "stage": stage, "claim_nonce": claim_nonce,
        "dispatch_seq": marker_seq,
        "subagent_type": observed_subagent, "model": resolved_model,
        "prompt_head_128": observed_head,
        "overlay_source": overlay_source, "overlay_digest": overlay_digest,
        "dispatch_witness_alg": wc.dispatch_witness_alg,
        "tag": sig, "verdict": "WITNESS_OK", "signed_at": now_iso(),
    }
    try:
        append_ledger(ledger_path, entry)
    except OSError:
        return deny("GATE_ERROR: ledger append failed")   # fail closed

    # 3g. ALLOW: consume the marker (best-effort) and emit no deny JSON.
    maybe_warn_version()
    clear_marker(MARKER_REL)
    return 0


try:
    sys.exit(main())
except SystemExit:
    raise
except Exception:
    # Own internal error -> fail closed under strict (never exit 0/1 silently).
    try:
        st = (os.environ.get("AGENT_FLOW_STRICT_DISPATCH", "") != "0"
              and not os.path.exists(os.path.join(".agent-flow", "STRICT_DISPATCH_OFF")))
    except Exception:
        st = True
    if st:
        emit_deny("GATE_ERROR: gate internal error")
        sys.exit(2)
    sys.exit(0)
PY
rc=$?
rm -f "$HOOK_IN" 2>/dev/null || true
exit $rc
