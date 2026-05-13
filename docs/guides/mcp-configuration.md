# MCP Configuration

`.mcp.json` is the configuration file for MCP servers. Claude Code loads it automatically when starting in a directory where the file exists.

> **Automated setup:** Run `/ceos-agents:setup-mcp` to generate `.mcp.json` automatically from your Automation Config. The manual instructions below are for reference or custom setups.

## Location

- **Per-project** (recommended): `.mcp.json` in the project root
- `.mcp.json.example` tracked in git as a template (without tokens)
- `.mcp.json` in `.gitignore` (contains tokens)

## File Structure

```json
{
  "mcpServers": {
    "youtrack": {
      "command": "npx",
      "args": ["-y", "@vitalyostanin/youtrack-mcp@latest"],
      "env": {
        "YOUTRACK_URL": "https://<instance>.youtrack.cloud",
        "YOUTRACK_TOKEN": "<youtrack-api-token>"
      }
    },
    "gitea": {
      "command": "gitea-mcp",
      "args": [],
      "env": {
        "GITEA_HOST": "https://<gitea-instance>",
        "GITEA_ACCESS_TOKEN": "<gitea-access-token>"
      }
    }
  }
}
```

## YouTrack MCP server

- **Package:** `@vitalyostanin/youtrack-mcp` (npm)
- **Launch:** `npx -y @vitalyostanin/youtrack-mcp@latest` — always the latest version
- **Env variables:** `YOUTRACK_URL`, `YOUTRACK_TOKEN`
- **Verification:** In Claude Code, ask a query about an existing issue. If you see a response with YouTrack data, the MCP server is working.

## Gitea MCP server

- **Source:** [gitea.com/gitea/gitea-mcp/releases](https://gitea.com/gitea/gitea-mcp/releases) (pinned to v1.1.0)
- **Windows install:** Download `gitea-mcp_1.1.0_Windows_x86_64.zip`, extract `gitea-mcp.exe` to `~/.claude/bin/`. Alternatively, run `/ceos-agents:setup-mcp` which handles this automatically.
- **Linux install:** Download `gitea-mcp_1.1.0_Linux_x86_64.tar.gz`, extract with `tar xf`, save binary as `~/.claude/bin/gitea-mcp`, set `chmod +x`
- **Env variables:** `GITEA_HOST`, `GITEA_ACCESS_TOKEN`
- **Verification:** In Claude Code, ask a query about repositories. If you see a list of repositories, the MCP server is working.

## GitHub MCP server

- **Transport:** HTTP (official GitHub Copilot MCP endpoint)
- **URL:** `https://api.githubcopilot.com/mcp/`
- **Auth:** Bearer token via `GITHUB_PERSONAL_ACCESS_TOKEN` header
- **Config:**
```json
{
  "mcpServers": {
    "github": {
      "type": "http",
      "url": "https://api.githubcopilot.com/mcp/",
      "headers": {
        "Authorization": "Bearer <YOUR_GITHUB_TOKEN>"
      }
    }
  }
}
```

## Jira MCP server

- **Transport:** HTTP (official Atlassian Cloud MCP endpoint — Cloud only)
- **URL:** `https://mcp.atlassian.com/v1/mcp`
- **Auth:** OAuth via Claude Code (no env vars required in template)
- **Config:**
```json
{
  "mcpServers": {
    "jira": {
      "type": "http",
      "url": "https://mcp.atlassian.com/v1/mcp"
    }
  }
}
```

## Linear MCP server

- **Transport:** HTTP (official Linear MCP endpoint)
- **URL:** `https://mcp.linear.app/mcp`
- **Auth:** OAuth via Claude Code (no env vars required in template)
- **Config:**
```json
{
  "mcpServers": {
    "linear": {
      "type": "http",
      "url": "https://mcp.linear.app/mcp"
    }
  }
}
```

## Redmine MCP server

- **Transport:** stdio via `uvx` (Python package `mcp-redmine`, pinned version `2026.01.13.152335`)
- **Prerequisites:** Python 3.10+ and `uv` toolchain — see [https://docs.astral.sh/uv/getting-started/installation/](https://docs.astral.sh/uv/getting-started/installation/)
- **Env variables:** `REDMINE_URL`, `REDMINE_API_KEY`
- **Config:**
```json
{
  "mcpServers": {
    "redmine": {
      "command": "uvx",
      "args": ["--from", "mcp-redmine==2026.01.13.152335", "mcp-redmine"],
      "env": {
        "REDMINE_URL": "https://<redmine-instance>",
        "REDMINE_API_KEY": "<redmine-api-key>"
      }
    }
  }
}
```

No local clone or installation path needed — uvx downloads and runs the package automatically.

- **Verification:** In Claude Code, ask about an existing Redmine issue. If you see issue data, the MCP server is working.

## Verifying the Entire Setup

After configuring the MCP servers, run:

```
/ceos-agents:check-setup
```

The command verifies configuration, connectivity, and displays a report. See [skills/check-setup/SKILL.md](../../skills/check-setup/SKILL.md).

### Common Errors

| Error | Cause | Solution |
|-------|-------|----------|
| `YOUTRACK_TOKEN` auth error | Invalid or expired token | Generate a new token in YouTrack |
| `GITEA_HOST` connection refused | Wrong URL or server unreachable | Verify the URL in your browser |
| MCP server not found | Binary does not exist at the specified path | Check the path in `.mcp.json` |
