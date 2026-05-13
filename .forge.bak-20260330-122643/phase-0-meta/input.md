# Phase 0 — User Input (verbatim)

Implement v5.6.0 — Scaffold Infrastructure Polish for the ceos-agents plugin.

Six scaffold/init follow-ups from v5.5.0:

1. **core/mcp-detection.md** — Extract MCP detection logic (tracker type → MCP package lookup + connectivity check) into a shared core/ contract. Currently duplicated between commands/scaffold.md (Step 0-MCP) and commands/init.md (Steps 3+7). Both commands must reference the new core file instead of inline logic. Follow the existing core/ contract format (Purpose/Input/Output/Failure) — see core/config-reader.md for reference.

2. **init.md .mcp.json.example detection** — When /init runs after /scaffold, detect existing .mcp.json.example in CWD and pre-fill configuration (tracker type, instance URL, remote) instead of re-asking. Graceful fallback if file doesn't exist.

3. **state.json infrastructure field** — Add optional `infrastructure` field to state/schema.md to persist Step 0-INFRA declarations (tracker ready/later, SC ready/later). Update core/state-manager.md contract. Update commands/scaffold.md to write this field at Step 0-INFRA and read it on resume.

4. **--infra CLI flag for scaffold** — Allow `--infra ready,later` or `--infra later,later` to pre-answer Step 0-INFRA questions. Consistent with existing flag patterns (--lang, --framework, --db). Update commands/scaffold.md.

5. **Step 0-MCP canary-write check** — After successful READ check in Step 0-MCP, optionally test WRITE access (create+delete a canary item). If write fails, warn early instead of failing at Step 4e (10-30 min later). Must be non-blocking (warn + downgrade to "later", don't halt). Update commands/scaffold.md.

6. **--issue + YOLO + no-MCP UX consolidation** — When --issue is provided in Full YOLO mode but MCP server is missing, block with a clear error instead of silently downgrading. Update commands/scaffold.md and commands/implement-feature.md.
