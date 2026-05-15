# Code Analysis MCP — Agent Overrides

TOML overlay files that instruct agents to prefer a **code analysis MCP server** over manual
codebase exploration (Grep/Glob). Copy and adapt to your MCP server's tool names.

## Setup

1. Copy the files you need into your project's Agent Overrides directory
   (configured via `Agent Overrides → Path` in Automation Config, default: `customization/`).

2. Replace `mcp__codegraph__` throughout with your MCP server's tool prefix.
   For example, if your server is named `codenav`, use `mcp__codenav__`.

3. Remove any `[[process_additions]]` blocks for tools your server does not expose.

```
customization/
  architect.toml
  analyst.toml
  spec-analyst.toml
```

## Included Agents

| File | Agent | What the overlay adds |
|------|-------|----------------------|
| `architect.toml` | architect | Prefers MCP tools for dependency/inheritance analysis during design |
| `analyst.toml` | analyst | Prefers MCP tools for call-graph tracing and risk assessment |
| `spec-analyst.toml` | spec-analyst | Prefers MCP tools for architecture overview and scope estimation |

## MCP Config

See [`examples/mcp-configs/codegraph.json`](../../mcp-configs/codegraph.json) for an example
MCP server configuration to add to your `.mcp.json`.
