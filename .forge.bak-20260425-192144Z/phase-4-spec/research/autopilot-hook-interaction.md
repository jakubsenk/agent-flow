# Research Artifact: --dangerously-skip-permissions × PostToolUse Hook Interaction

**For:** forge-2026-04-23-002 / Phase 5 TDD gate — Track 2 Layer 2
**Retrieved:** 2026-04-23

---

## Hook trigger conditions (verbatim from Claude Code docs)

Source: https://code.claude.com/docs/en/permission-modes (retrieved 2026-04-23), https://code.claude.com/docs/en/headless (retrieved 2026-04-23)

**bypassPermissions mode** (activated by `--dangerously-skip-permissions`) description from official docs:

> "`bypassPermissions` mode disables permission prompts and safety checks so tool calls execute immediately. Writes to protected paths are the only actions that still prompt."

The mode controls the **permission layer** (whether Claude pauses to ask for approval before executing a tool). It does NOT control the **hook layer**. These are separate systems:

- Permission layer: decides whether to allow/deny/prompt before tool execution
- Hook layer: runs registered scripts at lifecycle events (PreToolUse, PostToolUse, etc.)

The `--bare` flag (not `--dangerously-skip-permissions`) is what suppresses hook loading. From the CLI reference:

> "`--bare`: Minimal mode: skip auto-discovery of hooks, skills, plugins, MCP servers, auto memory, and CLAUDE.md so scripted calls start faster."

**The autopilot dispatch command** (from `skills/autopilot/SKILL.md` Step 6) is:
```bash
claude -p "Run ${TARGET_SKILL} ${ISSUE_ID}" \
  --dangerously-skip-permissions \
  > ".ceos-agents/${ISSUE_ID}/dispatch-stdout.log" \
  2> ".ceos-agents/${ISSUE_ID}/dispatch-stderr.log"
```

This invocation does NOT include `--bare`. Therefore:
- The child subprocess loads hooks from settings files (user `~/.claude/settings.json`, project `.claude/settings.json`, local `.claude/settings.local.json`)
- PostToolUse hooks fire for every tool call made by the child subprocess
- The `permission_mode` field on stdin will be `"bypassPermissions"` for all hook invocations in this context

**Conclusion:** PostToolUse hooks DO fire under `--dangerously-skip-permissions`. This means a hook installed in `~/.claude/settings.json` or `.claude/settings.json` has FULL audit coverage of autopilot-dispatched child sessions.

---

## JSON input schema on stdin (field list with types)

Source: https://code.claude.com/docs/en/hooks (retrieved 2026-04-23)

The stdin schema is the same regardless of permission mode. The `permission_mode` field surfaces the active mode to the hook script, enabling mode-aware behavior:

```json
{
  "session_id":        "string  — child session ID (different from parent autopilot session)",
  "transcript_path":   "string  — path to child session transcript JSONL",
  "cwd":               "string  — project root (autopilot dispatches from project root)",
  "permission_mode":   "string  — 'bypassPermissions' when dispatched by autopilot",
  "hook_event_name":   "string  — 'PostToolUse'",
  "tool_name":         "string  — e.g. 'Bash', 'Edit', 'Write'",
  "tool_input":        "object  — tool-specific input",
  "tool_response":     "object  — tool-specific response",
  "tool_use_id":       "string  — Anthropic tool call ID",
  "agent_id":          "string  — (optional) subagent context only",
  "agent_type":        "string  — (optional) subagent type"
}
```

The `permission_mode: "bypassPermissions"` value is the signal that this hook invocation originates from an autopilot child subprocess. A hook script can branch on this field to apply tighter audit rules for unattended runs vs. interactive sessions.

---

## Exit code semantics (0=allow, 2=block, other=warn)

Source: https://code.claude.com/docs/en/hooks (retrieved 2026-04-23)

Exit code semantics are identical regardless of permission mode:

| Exit Code | Behavior |
|-----------|----------|
| **0**     | Success. Claude parses stdout for JSON decision control. |
| **1**     | Non-blocking error logged to transcript. Execution continues. |
| **2**     | Non-blocking error (same as 1 for PostToolUse). Cannot block since tool already ran. |
| **Other** | Non-blocking error, same as exit 1. |

**In autopilot context (non-interactive `-p` mode):** hook errors are logged but do NOT abort the child session unless the hook emits `{"continue": false}` on stdout. This means a malfunctioning audit hook will not break pipeline execution — it degrades observability silently. The hook script MUST be defensive (always exit 0 on non-critical failures, use `continue: false` only for hard security violations).

**In non-interactive auto mode** (distinct from bypassPermissions): repeated classifier blocks (3 consecutive / 20 total) abort the session. This does NOT apply to bypassPermissions + hooks — hook exit codes have no such accumulation semantics.

---

## Installation stanza example in ~/.claude/settings.json

Source: https://code.claude.com/docs/en/settings (retrieved 2026-04-23)

For audit coverage of autopilot dispatches, install in `~/.claude/settings.json` (user-global scope). This fires on all `claude -p` child subprocess invocations regardless of which project directory they run from.

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/audit-autopilot-dispatch.sh",
            "timeout": 30,
            "statusMessage": "Auditing dispatch..."
          }
        ]
      }
    ]
  }
}
```

The hook script receives the full stdin JSON including `permission_mode`, `tool_name`, and `tool_input.command`. For autopilot dispatches, `tool_input.command` will contain the `claude -p "Run /ceos-agents:fix-ticket ..."` string, which the script can detect and log.

**Settings merge note:** hooks arrays merge across all settings scopes. A hook in `~/.claude/settings.json` AND a hook in `.claude/settings.json` will BOTH fire — they are not mutually exclusive. The audit hook should be idempotent to handle potential double-invocation if the operator installs it at multiple scopes.

**disableAllHooks caveat:** if the project's `.claude/settings.json` or a managed settings file sets `"disableAllHooks": true`, all hooks including the user-global audit hook are suppressed. This is a known limitation — operators must ensure `disableAllHooks` is not set in the project or managed settings when audit coverage is required.

---

## Confidence: HIGH

The official documentation explicitly and separately defines:
1. `bypassPermissions` / `--dangerously-skip-permissions` as bypassing permission prompts and safety checks (not the hook system)
2. `--bare` as the flag that skips hook auto-discovery
3. The autopilot dispatch command in `skills/autopilot/SKILL.md` uses `--dangerously-skip-permissions` WITHOUT `--bare`

This three-way confirmation leaves no ambiguity: PostToolUse hooks fire in autopilot child subprocess context. The conclusion is HIGH confidence with a positive finding (full audit coverage is achievable), not a gap or deferral.

**Implication for Phase 4 spec T2-ADV-3 deferral note:** The spec deferred cross-run circuit persistence and Webhook URL allowlist to v6.11.0 (REQ-T2-10). This finding does NOT affect that deferral — those are separate hardening features. What this finding DOES confirm is that the Layer 2 hook script CAN see all autopilot dispatches at the PostToolUse level, which means the `dispatched_at` audit mechanism is architecturally sound and test-suite-ready for Phase 5 TDD.

---

## External citations

1. https://code.claude.com/docs/en/permission-modes
   - bypassPermissions mode definition, explicit statement that it disables "permission prompts and safety checks" (not hooks), protected paths behavior, --dangerously-skip-permissions equivalence
   - retrieved: 2026-04-23

2. https://code.claude.com/docs/en/cli-reference
   - `--bare` flag: "skip auto-discovery of hooks, skills, plugins, MCP servers, auto memory, and CLAUDE.md"; `--dangerously-skip-permissions` flag: "Equivalent to `--permission-mode bypassPermissions`"; confirms the two flags have distinct scopes (bare=skip hooks, dangerously-skip=bypass permission prompts)
   - retrieved: 2026-04-23

3. https://code.claude.com/docs/en/headless
   - Headless / non-interactive mode (`-p` flag) documentation; confirms hooks run in headless mode; `--bare` described as the mechanism to skip hook auto-discovery for CI; hooks from `~/.claude` and project `.claude/` still load without `--bare`
   - retrieved: 2026-04-23

4. https://code.claude.com/docs/en/settings
   - Hook settings schema, `disableAllHooks` caveat, `allowManagedHooksOnly` caveat, array merge behavior across settings scopes, settings file precedence order
   - retrieved: 2026-04-23
