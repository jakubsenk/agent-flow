#!/usr/bin/env bash
# hooks/validate-dispatch.sh
# PostToolUse hook: dispatched_at presence audit + dispatch-witness audit
# (V1 recompute-and-compare + V2 overlay-presence).
#
# Invoked automatically by Claude Code after a tool use. Reads state.json once,
# audits every pipeline stage, and appends one audit line per stage per audit to
# .agent-flow/dispatch-audit.log.
#
# Implemented as a single Python process. Python 3 is a hard requirement of
# agent-flow, so there is no bash fallback: the legacy grep/sed/sha256sum loops
# spawned ~400 subprocesses per invocation (~36s on Git-Bash/Windows) AND the
# field reader truncated prompt_head_128 at the first `}` / `,` / `"`, which made
# V1 falsely mismatch any prompt template containing a `{placeholder}` in its
# first 128 bytes. json.load reads the field exactly (and un-escapes it), fixing
# both problems in one pass.
#
# EXIT: 0 normally. STRICT-BY-DEFAULT for the witness audit: exit 2 when any
#       stage produces WITNESS_MISMATCH, unless AGENT_FLOW_STRICT_DISPATCH="0".
#       The dispatched_at presence audit is always advisory.
# LOG:  .agent-flow/dispatch-audit.log (append-only, plain text).
#
# Env vars (clean-break AGENT_FLOW_ prefix):
#   - AGENT_FLOW_STRICT_DISPATCH : strict ON unless == "0" (advisory)
#   - AGENT_FLOW_AUDIT_LOG       : audit-log path override
#   - AGENT_FLOW_STATE_JSON      : state.json path override
#   - AGENT_FLOW_OVERRIDE_PATH   : overlay override dir for V2 (default customization/)
#
# Security contracts:
#   - STAGES are hardcoded; never derived from state.json field names.
#   - state.json is parsed, never eval'd.
set -uo pipefail

PYBIN="$(command -v python3 || command -v python || true)"
if [ -z "$PYBIN" ]; then
  echo "validate-dispatch: python3 not found (required by agent-flow); skipping audit" >&2
  exit 0
fi

exec "$PYBIN" - <<'PY'
import sys, os, json, glob, hashlib, datetime

# Hardcoded stage whitelist (no dynamic discovery from state.json).
STAGES = ["triage", "code_analysis", "reproduce_browser", "fixer_reviewer",
          "smoke_check", "test", "e2e_test", "browser_verification",
          "acceptance_gate", "publisher"]
WITNESS_FIELDS = ("agent_name", "model", "prompt_head_128", "overlay_source", "overlay_digest")
HEX = set("0123456789abcdef")

# --- resolve state.json (explicit override, else latest .agent-flow/*/state.json) ---
state_json = os.environ.get("AGENT_FLOW_STATE_JSON") or ""
if not state_json:
    cands = sorted(glob.glob(os.path.join(".agent-flow", "*", "state.json")))
    state_json = cands[-1] if cands else ""
if not state_json or not os.path.isfile(state_json):
    sys.exit(0)  # not a pipeline run

try:
    with open(state_json, encoding="utf-8") as f:
        stages = (json.load(f) or {}).get("stages", {}) or {}
except Exception:
    sys.exit(0)  # unreadable / invalid JSON -> behave like "no run", never block

audit_log     = os.environ.get("AGENT_FLOW_AUDIT_LOG", os.path.join(".agent-flow", "dispatch-audit.log"))
override_path = os.environ.get("AGENT_FLOW_OVERRIDE_PATH", "customization/")
strict        = os.environ.get("AGENT_FLOW_STRICT_DISPATCH", "") != "0"
ts            = datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
lines         = []

# --- Sweep 1: dispatched_at presence (value must start with a digit = ISO ts) ---
for st in STAGES:
    da = str((stages.get(st) or {}).get("dispatched_at") or "")
    lines.append(f"{ts} {st} {'OK' if da[:1].isdigit() else 'MISSING'}")

# --- Sweep 2: dispatch-witness audit (V1 recompute + V2 overlay-presence) ---
# Precedence mirrors core/lib/stage-invariant.sh::check_dispatch_witness:
#   skipped stage / missing required input -> WITNESS_MISSING (never a mismatch)
#   malformed stored witness, V1 mismatch, or V2 overlay-not-applied -> WITNESS_MISMATCH
saw_mismatch = False
for st in STAGES:
    s = stages.get(st) or {}
    verdict = "WITNESS_MISSING"
    if s.get("status") != "skipped":
        vals = {k: s.get(k) for k in ("dispatch_witness",) + WITNESS_FIELDS}
        if all(vals[k] not in (None, "") for k in vals):
            stored = str(vals["dispatch_witness"])
            if len(stored) == 64 and set(stored) <= HEX:
                # V1: recompute sha256 over the stored 5-tuple and compare.
                canon = "|".join(str(vals[k]) for k in WITNESS_FIELDS)
                if hashlib.sha256(canon.encode("utf-8")).hexdigest() == stored:
                    # V2: an available overlay must have been applied/recorded.
                    short = str(vals["agent_name"]).rsplit(":", 1)[-1]
                    toml  = os.path.join(override_path, short + ".toml")
                    if os.path.isfile(toml) and vals["overlay_source"] != "toml":
                        verdict = "WITNESS_MISMATCH"
                    else:
                        verdict = "WITNESS_OK"
                else:
                    verdict = "WITNESS_MISMATCH"
            else:
                verdict = "WITNESS_MISMATCH"  # malformed stored witness
    if verdict == "WITNESS_MISMATCH":
        saw_mismatch = True
    lines.append(f"{ts} {st} {verdict}")

# --- append audit lines (best-effort; never fail the tool on a log write error) ---
try:
    d = os.path.dirname(audit_log)
    if d:
        os.makedirs(d, exist_ok=True)
    with open(audit_log, "a", encoding="utf-8") as f:
        f.write("\n".join(lines) + "\n")
except Exception:
    pass

sys.exit(2 if (strict and saw_mismatch) else 0)
PY
