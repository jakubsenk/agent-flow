# Dispatch Enforcement Guide

<!-- check-tags: what it does:validates|audits|tracks|dispatch 3-layer|three.layer|Layer 1|Layer 2 installation|install troubleshoot|debug|diagnose advisory|exit 0|non-blocking Autopilot limitation|limitation Autopilot -->

**Component:** `hooks/validate-dispatch.sh`
**Type:** Operator opt-in (NOT auto-installed)

---

## What it does

The dispatch enforcement hook validates that each agent-flow pipeline stage
populated a `dispatched_at` timestamp in `state.json` before handing off to
its subagent via the Task tool. It audits whether the 3-layer dispatch enforcement
architecture (Layer 1: imperative, Layer 2: hook, Layer 4: scenario gate) is
working end-to-end.

Concretely, the hook:

1. Fires on every PostToolUse event (after any tool completes).
2. Locates the current pipeline's `state.json` under `.agent-flow/`.
3. Runs two audit passes over the hardcoded `STAGES` whitelist —
   `triage`, `code_analysis`, `reproduce_browser`, `fixer_reviewer`,
   `smoke_check`, `test`, `e2e_test`, `browser_verification`,
   `acceptance_gate`, `publisher` (10 stages):
   - **Presence audit** — checks each stage for a `dispatched_at` timestamp and
     emits one `OK` / `MISSING` line per stage.
   - **Dispatch-witness audit** — when `core/lib/stage-invariant.sh` is sourced
     (plugin-relative or repo-relative), runs `check_dispatch_witness` per stage
     and emits one `WITNESS_OK` / `WITNESS_MISSING` / `WITNESS_MISMATCH` line per
     stage. V1 recomputes `sha256(agent_name|model|prompt_head_128|overlay_source|overlay_digest)`
     from the stored stage fields and compares it to the stored `dispatch_witness`;
     V2 checks overlay-presence (an available `<override>/<agent>.toml` that the
     stage did not record as `overlay_source: toml`).
4. Appends those audit lines to `.agent-flow/dispatch-audit.log`.
5. Exit code: the **presence audit is always advisory (exit 0)**. The
   **witness audit is strict by default** — it exits 2 when any stage produces
   `WITNESS_MISMATCH` during the pass, unless `AGENT_FLOW_STRICT_DISPATCH=0`
   makes it advisory too.

Even under strict mode the exit 2 is non-blocking in practice: PostToolUse hooks
fire *after* the tool has already executed, so exit 2 cannot undo it (see
`docs/reference/hooks.md` → Exit code semantics). The strict gate surfaces the
mismatch as a signal in the transcript; it does not roll back the pipeline.
`WITNESS_MISSING` is never strict-fatal — legitimately skipped stages and stages
with absent witness inputs produce `MISSING`, not `MISMATCH`.

---

## Installation

The hook is **not auto-installed**. It is shipped in the plugin at
`hooks/validate-dispatch.sh`. Operators install it manually by adding an entry
to `~/.claude/settings.json`.

### Minimal stanza

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "/path/to/agent-flow/hooks/validate-dispatch.sh"
          }
        ]
      }
    ]
  }
}
```

Replace `/path/to/agent-flow/` with the absolute path to your plugin
installation directory.

> **⚠️ The plugin path is version-pinned — do not hardcode it blindly.**
> Installed plugins live under a version-stamped cache directory, e.g.:
>
> ```
> ~/.claude/plugins/cache/agent-flow/agent-flow/<version>/hooks/validate-dispatch.sh
> ```
>
> The `<version>` segment changes on every plugin upgrade, so an absolute path
> pinned to one version **silently stops resolving** after an update — the file
> at the old path no longer exists.
>
> **Find the current path** before pasting it into `settings.json`:
>
> ```bash
> # list every installed version's hook…
> ls -d ~/.claude/plugins/cache/agent-flow/agent-flow/*/hooks/validate-dispatch.sh
> # …or resolve the newest one:
> ls -d ~/.claude/plugins/cache/agent-flow/agent-flow/*/hooks/validate-dispatch.sh | sort | tail -1
> ```
>
> **A wrong path produces no error signal.** The hook fails open: PostToolUse
> hooks are non-blocking, so Claude Code treats an unresolvable hook command as
> a silent no-op — the audit never runs and `.agent-flow/dispatch-audit.log` is
> never written, with nothing reported. Re-check the path after every plugin
> upgrade, and run `/agent-flow:check-setup` to confirm the wiring is still
> detected.

### Recommended scope

Install in `~/.claude/settings.json` (user-global) so the hook fires for
every Claude Code session including autopilot child subprocess invocations.
If you only want it for a single project, use `.claude/settings.json` in that
project root.

---

## Expected output

Each invocation appends two groups of lines. The **presence audit** emits one
`OK` / `MISSING` line per stage:

```
2026-04-25T14:32:07Z triage OK
2026-04-25T14:32:07Z code_analysis OK
2026-04-25T14:32:07Z fixer_reviewer OK
2026-04-25T14:32:07Z test OK
2026-04-25T14:32:07Z publisher OK
```

A `MISSING` line means the stage completed without writing `dispatched_at` to
`state.json` — typically indicating a skill was run with an older agent-flow
version, or the dispatching step was skipped.

```
2026-04-25T14:32:07Z code_analysis MISSING
```

`MISSING` is advisory — pipelines continue normally regardless.

The **witness audit** then emits one `WITNESS_*` line per stage:

```
2026-04-25T14:32:07Z triage WITNESS_OK
2026-04-25T14:32:07Z code_analysis WITNESS_MISSING
2026-04-25T14:32:07Z fixer_reviewer WITNESS_MISMATCH
```

- `WITNESS_OK` — V1 recompute matches the stored `dispatch_witness` **and** V2
  finds no unapplied overlay.
- `WITNESS_MISSING` — a required witness input is absent/null, the stage was
  legitimately skipped (`status: "skipped"`), or no sha256 tool is available.
  Never strict-fatal.
- `WITNESS_MISMATCH` — V1 recompute ≠ stored witness, the stored witness is
  malformed, or V2 detects an available `<override>/<agent>.toml` overlay that
  the stage did not record (`overlay_source != toml`). Under strict mode
  (the default) a single `WITNESS_MISMATCH` makes the hook exit 2.

When `bypassPermissions` mode is detected (autopilot child subprocesses), an
extra informational line is also appended:

```
2026-04-25T14:32:07Z [INFO] bypassPermissions mode detected -- audit proceeds normally
```

---

## Environment variables

The hook reads these (clean-break `AGENT_FLOW_` prefix):

| Variable | Effect |
|----------|--------|
| `AGENT_FLOW_STRICT_DISPATCH` | Witness audit is strict (exit 2 on `WITNESS_MISMATCH`) unless set to `0` (advisory). The presence audit is always advisory regardless. |
| `AGENT_FLOW_AUDIT_LOG` | Override the audit-log path (default `.agent-flow/dispatch-audit.log`). |
| `AGENT_FLOW_STATE_JSON` | Override the `state.json` path (default: newest `.agent-flow/*/state.json`). |
| `AGENT_FLOW_OVERRIDE_PATH` | Overlay override dir used by the V2 overlay-presence check (default `customization/`). The hook reads the default location only — a documented limitation. |

---

## Troubleshooting / diagnosis

**Hook never fires:**
- Verify the entry is in `~/.claude/settings.json` (not a project-level file
  that is overriding user-global config).
- Check `disableAllHooks` is not `true` in any settings file.
- Run `/agent-flow:check-setup` — it reports whether the hook file and
  settings.json entry are detected.

**`state.json` not found:**
- The hook exits silently if no `.agent-flow/*/state.json` is present.
  This is normal for non-pipeline sessions. Check that you are running from
  the project root (the same directory used during pipeline execution).

**Log file not created:**
- The hook creates `.agent-flow/dispatch-audit.log` automatically on first
  write. If the directory doesn't exist, the hook exits 0 without logging
  (advisory failure semantics).

---

## Known limitation: Autopilot subprocess dispatch audit gap

When autopilot dispatches pipeline subprocesses via
`claude -p "Run /agent-flow:fix-bugs ..." --dangerously-skip-permissions`,
PostToolUse hooks DO fire inside those subprocesses. However, each subprocess
writes to its own session's audit log, and **cross-run audit aggregation** (merging
per-subprocess logs into a single autopilot-session report) is on the roadmap
as "Autopilot dispatch audit parity".

The current advisory behavior is:
- Each autopilot-spawned subprocess logs independently.
- The `bypassPermissions` mode is detected and noted in the audit log.
- No cross-run summary is produced automatically.

---

## Schema reference

See `docs/reference/hooks.md` for the full PostToolUse JSON input schema,
exit code semantics, and `dispatched_at` field specification.
