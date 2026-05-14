# MCP Pre-flight

## Purpose

Verify MCP server connectivity before pipeline operations that require issue tracker access. Prevents mid-pipeline failures caused by misconfigured or unavailable MCP servers.

## Input Contract

- **tracker_type** (string, required): Issue tracker type from config (e.g., `youtrack`, `github`, `jira`, `linear`, `gitea`, `redmine`)

## Process

Follow `core/mcp-detection.md` with `service_type: "tracker"`, `check_write: false`:

1. Pass `tracker_type` to `core/mcp-detection.md` to determine the expected MCP package and tool prefix (including alternative prefixes for Jira/Gitea).

2. `core/mcp-detection.md` checks tool accessibility and verifies read connectivity.

3. Read the `mcp_available` result from `core/mcp-detection.md` output.

4. If `mcp_available: true` → return success. If `mcp_available: false` → BLOCK (see Failure Handling).

## Output Contract

- **mcp_available** (boolean): `true` if the MCP server is accessible and responsive, `false` otherwise.

## Failure Handling

- **No matching MCP tool found:** BLOCK pipeline with:
  ```
  [agent-flow] 🔴 Pipeline Block
  Agent: mcp-preflight
  Step: MCP pre-flight check
  Reason: Cannot connect to your {tracker_type} issue tracker. No integration found.
  Detail: Expected tool prefix: mcp__{tracker_type}__*. No matching tool is registered in this session.
  Recommendation: Run /agent-flow:check-setup for diagnostics, or /agent-flow:setup-mcp to configure the {tracker_type} integration. Verify that the integration is listed in your Claude Code MCP config and that the server process is running.
  ```
- **MCP tool found but connectivity test fails** (auth error, network error, timeout): BLOCK pipeline with:
  ```
  [agent-flow] 🔴 Pipeline Block
  Agent: mcp-preflight
  Step: MCP pre-flight check
  Reason: Your {tracker_type} issue tracker integration is registered but not responding.
  Detail: {error message from the failed test call}
  Recommendation: Check that your API token is valid and has the required permissions. Check that the {tracker_type} instance is reachable. Run /agent-flow:check-setup for diagnostics.
  ```
- **Never block on an unknown tracker type alone** — attempt the check with the derived prefix and fail only if the tool is actually missing or unresponsive.
