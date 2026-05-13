# Agent 2 Research: init.md Compatibility Analysis

**Research Area:** Area 2 — init.md Compatibility
**Date:** 2026-03-27
**Source files read:** `commands/init.md`, `commands/scaffold.md`, `commands/check-setup.md`, `docs/reference/trackers.md`, `examples/mcp-configs/*.json`

---

## Q6: Full content of init.md — Can it be invoked inline from scaffold?

### Full Content Summary

`commands/init.md` is a 9-step interactive wizard for configuring the developer environment. Its frontmatter:

```
---
description: Configures developer environment — MCP servers, tokens, and permissions
allowed-tools: Read, Glob, Write, Edit, Bash, mcp__*
---
```

**Steps:**
1. Read Automation Config from CLAUDE.md (extract Type, Instance, Remote)
2. Detect existing `.mcp.json`
3. Determine MCP servers needed (read `docs/reference/trackers.md` MCP Server Detection table)
4. Collect tokens interactively from user
5. Platform-specific binary handling (forgejo-mcp / redmine / npx)
6. Generate `.mcp.json` (from `examples/mcp-configs/{type}.json` template)
7. Validate connectivity via MCP calls
8. Permission setup — generate `.claude/settings.json`
9. Closing message

### Can it be invoked inline (as a sub-routine from scaffold)?

**No — not without modification.** There are three blockers:

1. **Hard dependency on CLAUDE.md existing** — Step 1 errors immediately if no Automation Config is found: `"No Automation Config found. Run /ceos-agents:onboard first."` During scaffold, CLAUDE.md is written in Step 3/4b; it does not exist during the scaffold setup phase.

2. **Fully interactive wizard** — Steps 2, 4, and 8 all stop and prompt the user for input (tokens, confirmation, permission level). Inline invocation from scaffold cannot delegate these prompts gracefully unless scaffold orchestrates them explicitly.

3. **Different tool set** — init.md's `allowed-tools` includes `mcp__*` but not `Task` or `Grep`. It cannot self-delegate to sub-agents. Scaffold uses the `Task` tool to dispatch agents; init has no parallel mechanism for orchestration.

---

## Q7: Does init.md assume it runs standalone? Would inline invocation during scaffold cause issues?

### Yes — init.md is designed to run standalone only.

**Evidence from Step 1:**
```
If no Automation Config found → error: "No Automation Config found. Run `/ceos-agents:onboard` first."
```

This is an unconditional hard stop. There is no fallback, no parameter to skip this check, and no way to pass config values externally.

### Issues that would arise from inline invocation before CLAUDE.md exists:

| Issue | Impact |
|-------|--------|
| Step 1 reads CLAUDE.md → CLAUDE.md does not exist | Hard error, pipeline stops |
| Step 2 interactive prompt for existing `.mcp.json` | Blocks unattended YOLO mode |
| Step 4 token collection prompts | Blocks unattended YOLO mode |
| Step 8 permission level prompt | Blocks unattended YOLO mode |
| Step 7 MCP connectivity validation | Makes MCP calls — may fail if tokens not yet set |

### Current scaffold behavior (Step 4c):

Scaffold already recognized this limitation. Instead of invoking init inline, it delegates to the user with an informational message:

```
If Issue Tracker Instance was filled in Step 4b:
- Display: "To connect to {Type} at {Instance}, configure an MCP server. Run `/ceos-agents:init` to set it up."

This is informational only — scaffold does NOT block on MCP availability.
```

This is the correct pattern: **scaffold defers MCP setup to a post-scaffold manual step**, not inline.

---

## Q8: MCP Detection Logic in init.md Steps 3 and 7

### Step 3: Determine MCP servers needed

Step 3 reads the MCP Server Detection table directly from `docs/reference/trackers.md`:

```
| Tracker Type | MCP Package | Token env var | Extra env vars |
|-------------|-------------|---------------|----------------|
| youtrack | `@vitalyostanin/youtrack-mcp` | `YOUTRACK_TOKEN` | `YOUTRACK_URL` |
| github | `@modelcontextprotocol/server-github` | `GITHUB_PERSONAL_ACCESS_TOKEN` | — |
| jira | `@modelcontextprotocol/server-atlassian` | `ATLASSIAN_API_TOKEN` | `ATLASSIAN_URL`, `ATLASSIAN_EMAIL` |
| linear | `@modelcontextprotocol/server-linear` | `LINEAR_API_KEY` | — |
| gitea | `forgejo-mcp` (binary) | `FORGEJO_TOKEN` | `FORGEJO_URL` |
| redmine | `mcp-server-redmine` | `REDMINE_API_KEY` | `REDMINE_HOST` |
```

**Shared server detection logic** (also in Step 3):
```
Compare tracker Type hostname with Source Control Remote hostname.
- Gitea tracker + Gitea SC → single `forgejo-mcp` instance (shared)
- GitHub tracker + GitHub SC → single `server-github` instance (shared)
- Mixed (e.g. Jira + GitHub SC) → two separate servers
```

This logic requires both `Type` (tracker) and `Remote` (source control) from Automation Config — both extracted in Step 1.

### Step 7: Validate connectivity

Step 7 uses the same MCP call pattern as `check-setup` Block 3:

```
For each configured MCP server with non-placeholder tokens:
- Attempt a minimal MCP call:
  - Tracker: query 1 issue (same as check-setup Block 3)
  - Source control: list repos (same as check-setup Block 3)
- Success → "[OK] {server_name} connected successfully"
- Failure → "[FAIL] {server_name}: {error}. Check your token and URL."

If any placeholder tokens remain:
- "[SKIP] {server_name}: token not configured. Add it to .mcp.json later."
```

The exact MCP calls are not named in init.md — they are described by reference to check-setup Block 3, which specifies:
- **Tracker:** Run the Bug query from Automation Config via MCP (limit 1 result)
- **Source control:** List repositories via MCP

### What a new Step 0-MCP in scaffold needs to replicate or delegate:

If scaffold were to add an "MCP pre-flight for --issue and Step 9" check (which it already has in its "MCP Pre-flight Check" section), it must:

1. **Read tracker Type** from Automation Config (which may not exist yet)
2. **Check `mcp__*` tool availability** matching the tracker type keyword
3. **Not run Step 7 connectivity validation** — scaffold explicitly says "scaffold does NOT block on MCP availability"

The current scaffold MCP Pre-flight section already codifies this correctly:
```
Before any MCP operation, verify MCP tool availability:
- Read Type from Automation Config (Issue Tracker section)
- Check that at least one `mcp__*` tool matching the tracker type is accessible
- If not accessible → STOP with: "MCP server for {Type} is not available..."
```

This is a lighter check than init.md Step 7 (no actual MCP calls, just tool presence check).

---

## Additional Findings

### Working Directory Dependencies

init.md writes to the **current working directory**:
```
This command writes to the CURRENT WORKING DIRECTORY:
- `.mcp.json` — MCP server configuration
- `.claude/settings.json` — tool auto-approval (optional)
- `.gitignore` — adds `.mcp.json` if not present
```

During scaffold, the "current working directory" is the **target project directory** being scaffolded. This is consistent — init.md would write to the right place — but the CWD must already be set to the target project before init could be invoked.

### Allowed Tools

From init.md frontmatter:
```
allowed-tools: Read, Glob, Write, Edit, Bash, mcp__*
```

Notable omissions compared to scaffold:
- No `Task` tool — cannot dispatch sub-agents
- No `Grep` tool — uses `Read` + `Glob` for file inspection

### MCP Config Template Loading (Step 6)

Step 6 loads templates from `examples/mcp-configs/{type}.json`. All 6 tracker types have templates:
- `examples/mcp-configs/youtrack.json`
- `examples/mcp-configs/github.json`
- `examples/mcp-configs/jira.json`
- `examples/mcp-configs/linear.json`
- `examples/mcp-configs/gitea.json`
- `examples/mcp-configs/redmine.json`

Template structure uses `<YOUR_*>` placeholders for all secrets. The gitea template references the binary path as `<path-to-binary>/forgejo-mcp` — a non-npx server requiring platform detection (Step 5).

### .mcp.json vs .mcp.json.example

Step 6 creates both:
- `.mcp.json` — real tokens, gitignored
- `.mcp.json.example` — all tokens replaced with `<YOUR_*>` placeholders, safe to commit

---

## Summary of Compatibility Verdict

| Question | Answer |
|----------|--------|
| Can init.md be invoked inline from scaffold? | **No** — hard dependency on CLAUDE.md in Step 1 |
| Does init.md assume standalone execution? | **Yes** — interactive wizard, unconditional CLAUDE.md requirement |
| Would inline invocation before CLAUDE.md cause issues? | **Yes** — Step 1 hard-errors; Steps 2, 4, 8 block YOLO modes |
| What Step 3 detection logic must scaffold replicate? | Tracker-type → MCP package mapping (from trackers.md); shared server detection (tracker hostname == SC hostname) |
| What Step 7 validation must scaffold replicate? | Scaffold uses a lighter check (tool presence only), NOT the full MCP connectivity call from init Step 7 |
| Does scaffold correctly defer MCP setup today? | **Yes** — Step 4c already emits "Run /ceos-agents:init" guidance and does not block |
| Does the new Step 0-MCP need to replicate init's logic? | Partially — only the tool-presence check for --issue and Step 9. Full connectivity validation (Step 7) stays in init. |
