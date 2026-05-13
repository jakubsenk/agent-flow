# Research Artifact: Claude Code PostToolUse Hook API

**For:** forge-2026-04-23-002 / Phase 5 TDD gate — Track 2 Layer 2
**Retrieved:** 2026-04-23

---

## Hook trigger conditions (verbatim from Claude Code docs)

Source: https://code.claude.com/docs/en/hooks (retrieved 2026-04-23)

PostToolUse fires immediately after a tool completes successfully. It covers ALL tool types:

- Built-in tools: `Bash`, `Edit`, `Write`, `Read`, `Glob`, `Grep`
- Agent tools: `Agent`, `WebFetch`, `WebSearch`, `AskUserQuestion`, `ExitPlanMode`
- MCP tools: matching pattern `mcp__<server>__<tool>`

The hook is matched on tool name via the `matcher` field, which accepts:
- Omitted / `"*"` — fires on all PostToolUse events
- Exact string or `|`-separated list — e.g. `"Bash"`, `"Write|Edit"`
- Regex — any pattern containing non-alphanumeric characters except `_` and `|`

**Key difference from PreToolUse:** PostToolUse cannot block the tool call because the tool has already executed. Exit code 2 has NO special blocking effect here (unlike PreToolUse). The hook provides observation and feedback to Claude after the fact.

---

## JSON input schema on stdin (field list with types)

Source: https://code.claude.com/docs/en/hooks (retrieved 2026-04-23)

The hook receives one line of JSON on stdin with the following fields:

```json
{
  "session_id":        "string  — unique identifier for the Claude Code session",
  "transcript_path":   "string  — absolute path to the JSONL transcript file",
  "cwd":               "string  — current working directory at time of invocation",
  "permission_mode":   "string  — one of: default | plan | acceptEdits | auto | dontAsk | bypassPermissions",
  "hook_event_name":   "string  — literal 'PostToolUse'",
  "tool_name":         "string  — e.g. 'Bash', 'Write', 'mcp__memory__create_entities'",
  "tool_input":        "object  — varies by tool (see examples below)",
  "tool_response":     "object  — varies by tool (the result the tool returned)",
  "tool_use_id":       "string  — e.g. 'toolu_01ABC123...' (Anthropic tool call ID)",
  "agent_id":          "string  — (optional) only present in subagent context",
  "agent_type":        "string  — (optional) e.g. 'Explore' or custom agent name"
}
```

**Tool-specific `tool_input` / `tool_response` examples:**

Bash tool:
```json
{
  "tool_input":    { "command": "npm test", "description": "Run test suite", "timeout": 120000, "run_in_background": false },
  "tool_response": { "stdout": "output text", "stderr": "error text", "exitCode": 0 }
}
```

Write tool:
```json
{
  "tool_input":    { "file_path": "/path/to/file.txt", "content": "file content" },
  "tool_response": { "filePath": "/path/to/file.txt", "success": true }
}
```

Edit tool:
```json
{
  "tool_input": { "file_path": "/path/to/file.txt", "old_string": "original", "new_string": "replacement", "replace_all": false }
}
```

**Relevance to Track 2 Layer 2 `dispatched_at` audit check:**
The `permission_mode` field is present on stdin and will be `"bypassPermissions"` when autopilot dispatches a child subprocess with `--dangerously-skip-permissions`. The `tool_name` field identifies the dispatching call (typically `"Bash"`) and `tool_input.command` contains the full `claude -p "Run /ceos-agents:fix-ticket ..."` command string. The `dispatched_at` timestamp can be derived from the transcript (via `transcript_path`) or from OS-level instrumentation — it is NOT a top-level stdin field. The hook script must either timestamp on receipt or parse the transcript to obtain it. This means the hook has SUFFICIENT schema coverage to perform a dispatch audit, but `dispatched_at` requires one derivation step (read hook invocation time, or parse `transcript_path`).

---

## Exit code semantics (0=allow, 2=block, other=warn)

Source: https://code.claude.com/docs/en/hooks (retrieved 2026-04-23)

| Exit Code | Behavior for PostToolUse |
|-----------|--------------------------|
| **0**     | Success. Claude Code parses stdout for JSON decision control output. Execution continues normally. |
| **1**     | Non-blocking error. First line of stderr shown in transcript as `<hook name> hook error`. Full stderr in debug log. Execution continues. |
| **2**     | Non-blocking error. Same handling as exit 1 for PostToolUse. **CANNOT block** — tool already executed. Exit 2 has no special blocking semantics here (contrast with PreToolUse where exit 2 = block). |
| **Other** | Non-blocking error. Same handling as exit 1. |

**PostToolUse decision control via stdout (exit 0):**
The hook may emit a JSON object on stdout to influence Claude's next turn:
```json
{
  "decision": "block",
  "reason": "Explanation shown to Claude",
  "hookSpecificOutput": {
    "hookEventName": "PostToolUse",
    "additionalContext": "Extra context for Claude to consider",
    "updatedMCPToolOutput": "replacement value — MCP tools only"
  },
  "continue": true,
  "stopReason": "Message if continue is false",
  "suppressOutput": false,
  "systemMessage": "Warning message shown to user"
}
```

Setting `"continue": false` stops Claude entirely. Setting `"decision": "block"` with a reason prompts Claude with that reason but cannot undo the tool execution.

---

## Installation stanza example in ~/.claude/settings.json

Source: https://code.claude.com/docs/en/settings (retrieved 2026-04-23)

Settings files are loaded from these locations in precedence order (highest first):
1. Managed settings (IT/MDM deployed)
2. Command-line arguments
3. `.claude/settings.local.json` (project-local, git-ignored)
4. `.claude/settings.json` (project-shared, committed)
5. `~/.claude/settings.json` (user-global)

Array settings (including `hooks`) **merge across all scopes** rather than replace.

Minimal PostToolUse hook entry:
```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "/path/to/audit-dispatch.sh"
          }
        ]
      }
    ]
  }
}
```

Full stanza with all optional fields for a command-type hook:
```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Bash|Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "/path/to/hook-script.sh",
            "timeout": 600,
            "statusMessage": "Running dispatch audit...",
            "async": false,
            "asyncRewake": false,
            "shell": "bash",
            "once": false
          }
        ]
      }
    ]
  }
}
```

Additional hook top-level settings:
```json
{
  "disableAllHooks": false,
  "allowedHttpHookUrls": ["https://hooks.example.com/*"],
  "httpHookAllowedEnvVars": ["MY_TOKEN"]
}
```

**For Track 2 Layer 2 audit hook**, the recommended installation scope is `~/.claude/settings.json` (user-global) so it applies to all autopilot child subprocess invocations regardless of project `.claude/` configuration. Alternatively, `.claude/settings.json` in the project root works if the autopilot runs from that directory (which it does — Step 6 in `skills/autopilot/SKILL.md` uses a relative `.ceos-agents/` path, implying CWD = project root).

---

## Confidence: HIGH

The official Claude Code documentation at `code.claude.com/docs/en/hooks` provides a complete and detailed specification of PostToolUse semantics, the stdin JSON schema including all fields, exit code behavior, and settings.json stanza format. No inference or guessing was required for the core API schema. The one partial gap is that `dispatched_at` is not a direct stdin field — it must be derived from hook invocation time or the transcript file — but this is a design observation, not a documentation gap.

---

## External citations

1. https://code.claude.com/docs/en/hooks
   - PostToolUse trigger conditions, stdin JSON schema, exit code table, settings.json stanza format, decision control output schema
   - retrieved: 2026-04-23

2. https://code.claude.com/docs/en/settings
   - Settings file locations and precedence order, hooks array merge behavior, `disableAllHooks` and `allowManagedHooksOnly` settings, `allowedHttpHookUrls` and `httpHookAllowedEnvVars` settings
   - retrieved: 2026-04-23

3. https://code.claude.com/docs/en/cli-reference
   - `--bare` flag documentation (skips hooks), `--dangerously-skip-permissions` flag (equivalent to `--permission-mode bypassPermissions`), `--include-hook-events` flag (PostToolUse events in stream-json output)
   - retrieved: 2026-04-23

4. https://code.claude.com/docs/en/permission-modes
   - bypassPermissions mode definition: disables permission prompts and safety checks; hooks are a separate mechanism not bypassed by this mode; protected paths still prompt; hooks listed as a distinct control layer
   - retrieved: 2026-04-23
