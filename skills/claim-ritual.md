# Centralized Claim-Write Ritual (gate-as-signer dispatch witness)

> Single source of truth for the per-dispatch CLAIM + marker write. `fix-bugs`,
> `implement-feature`, AND `scaffold` include this ritual by reference (scaffold
> is **NOT** exempt — this closes the documented 0-witness scaffold gap). It
> replaces the drifted ~21 per-step "Pre-dispatch state write / dispatch_witness"
> producer sites and retires the legacy 4-arg/6-arg `compute_dispatch_witness`
> drift (REQ-015).
>
> **Trust model — GATE-AS-SIGNER.** The orchestrator writes only the **CLAIM**.
> It **never** reads, generates, or references the per-run key, and it **never**
> writes a signed tag. The PreToolUse `Task` gate is the sole key holder and the
> sole signer; the PostToolUse audit re-verifies. (REQ-001, REQ-002.)

## When

Perform this ritual **IMMEDIATELY before every `Task()` dispatch** of a governed
stage (`triage, code_analysis, reproduce_browser, fixer_reviewer, smoke_check,
test, e2e_test, browser_verification, acceptance_gate, publisher`), on **every**
iteration of the fixer↔reviewer loop and every repeated `test`/`e2e`/browser
dispatch. One stage is dispatched at a time per run (sequential-dispatch
precondition, REQ-046).

## Run-init (once per run)

When the run's `state.json` is first created, write the top-level
`schema_version: "2.0"` (the first non-additive schema bump; orchestrator-owned;
a display/audit HINT — the security authority is the gate's `0600 dispatch.key`).
Legacy pre-key runs stay `"1.0"`. (REQ-013, REQ-024.)

## Steps (before each `Task()`)

1. **Resolve the overlay** via the shared parser (`../core/agent-override-injector.md`,
   which uses `skills/setup-agents/lib/toml-merge.sh resolve_overlay`) and record:
   - `overlay_source` — exactly one of `toml | none | md_rejected` (the value is
     never `md`);
   - `overlay_digest` — when `overlay_source == toml`, the **sha256 of the RAW,
     LF-normalized `.toml` file bytes** (NOT the rendered Markdown block); else the
     literal `none` / `md_rejected` (REQ-031);
   - `override_path` — the **resolved** overlay directory (e.g. `customization/`),
     persisted so the gate/audit read it from `state.json` rather than env (REQ-032).
2. **Resolve `model`** by the deterministic precedence (REQ-048), identical to the
   gate so it can never false-DENY: overlay TOML `model =` scalar (via the shared
   parser — never a naive `grep '^model ='`) → else the dispatched agent
   definition's frontmatter `model:` at its real path → else the CLAIM's own value
   (`model_source="claim"`).
3. **Mint anti-replay fields**: `claim_nonce = secrets.token_hex(16)` (a fresh
   32-hex token per dispatch) and increment the per-run monotonic `dispatch_seq`
   (an integer counter). These defeat intra-stage / cross-dispatch replay — every
   iteration of the ≤5× `fixer_reviewer` loop carries a distinct `claim_nonce`
   (REQ-011, REQ-014, REQ-046).
4. **Write the CLAIM atomically** into `state.json.stages.<stage>` (follow the
   atomic write protocol in `../core/state-manager.md`) with **exactly** these
   fields — **claim-only: no key, no signed tag**:
   - `subagent_type` — the full namespace-prefixed identity (e.g.
     `agent-flow:fixer`); `agent_name` is an alias of the same string;
   - `model`
   - `overlay_source`
   - `overlay_digest`
   - `override_path`
   - `claim_nonce`
   - `dispatch_seq`
   - `status` (`in_progress`)
   - `dispatched_at` (ISO-8601 UTC)

   The CLAIM deliberately **omits the prompt head**. The gate OBSERVES
   `head128(tool_input.prompt)` from the real intercepted dispatch and signs that
   observation as ground truth (REQ-003 / REQ-051); the orchestrator does not
   write it, so an LLM's inability to byte-reproduce its own prompt is not a
   false-DENY source. (The legacy `prompt_head_128` claim field is removed as an
   orchestrator-written witness input.)
5. **Write the per-dispatch marker atomically.** Write the single well-known
   top-level pointer file `.agent-flow/pending-dispatch.json` (top-level so the
   gate finds it without first knowing the run dir) via **temp file + `os.replace`**
   (single-writer atomic rename), carrying **exactly**:
   `{ "run_id", "run_dir", "state_json", "stage", "subagent_type", "claim_nonce",
   "dispatch_seq", "written_at" }` (full namespace-prefixed `subagent_type`;
   ISO-8601 `written_at`). The gate resolves the run dir, `state.json`,
   `dispatch.key`, `stage`, and `claim_nonce` **from this marker** — never from
   `sorted(glob('.agent-flow/*/state.json'))[-1]`. The gate consumes (clears) the
   marker after signing. (REQ-046.)

Reference Python for the atomic marker write (stdlib only):

```python
import json, os, tempfile

def write_marker(marker_path, payload):
    d = os.path.dirname(marker_path) or "."
    os.makedirs(d, exist_ok=True)
    fd, tmp = tempfile.mkstemp(dir=d, prefix=".pending-", suffix=".json")
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as f:
            json.dump(payload, f)
        os.replace(tmp, marker_path)   # atomic single-writer rename
    except Exception:
        try:
            os.unlink(tmp)
        except OSError:
            pass
        raise
```

Then append the rendered overlay block to the prompt and issue the `Task()` call.

## What the orchestrator MUST NOT do

- MUST NOT read, generate, receive, or reference the per-run `dispatch.key`.
- MUST NOT write a signed `tag` or `dispatch_witness` into `state.json` on a keyed
  (`schema_version "2.0"`) run — the signed witness lives in the gate-owned ledger
  (gate-written, in the run dir), which the orchestrator never writes or truncates
  (REQ-014).
- MUST NOT write the prompt head as a witness input (gate-observed ground truth).
