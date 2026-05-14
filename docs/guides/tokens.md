# Tokens for agent-flow

agent-flow communicates with the issue tracker and source control via MCP servers. Each MCP server requires an API token.

## Overview

| Token | Service | MCP server / endpoint |
|-------|---------|----------------------|
| YouTrack API token | Issue tracker | HTTP: `youtrack.cloud/mcp` (Bearer header) |
| Gitea API token | Source control | stdio: `gitea-mcp` binary |
| GitHub PAT | Issue tracker + Source control | HTTP: `api.githubcopilot.com/mcp/` (Bearer header) |
| Jira API token | Issue tracker | HTTP: `mcp.atlassian.com/v1/mcp` (OAuth via Claude Code) |
| Linear API key | Issue tracker | HTTP: `mcp.linear.app/mcp` (OAuth via Claude Code) |
| Redmine API key | Issue tracker | stdio (uvx): `mcp-redmine==2026.01.13.152335` |

One token = one service. Tokens are stored in `.mcp.json` (never in CLAUDE.md).

## YouTrack API token

1. Open YouTrack → click on your profile (top right)
2. **Hub → Authentication → New token...**
3. Scope: `YouTrack` (or specifically `Issue tracker read/write`)
4. Token name: recommended `agent-flow-<PROJECT>` (e.g. `agent-flow-BIFITO`)
5. Click **Create** — the token is shown **only once**, copy it immediately
6. Expiration: recommended no expiration or 1 year

## Gitea API token

1. Open Gitea → **Settings → Applications**
2. **Generate New Token**
3. Name: `agent-flow-<PROJECT>`
4. Scope: `repository:read`, `repository:write`, `issue:write`
5. Click **Generate Token** — copy immediately

## GitHub Personal Access Token

1. Open GitHub → **Settings → Developer settings → Personal access tokens → Fine-grained tokens**
2. **Generate new token**
3. Name: `agent-flow-<PROJECT>`
4. Scope: `repo` (read/write), `issues` (read/write)
5. Click **Generate token** — copy immediately

The default `examples/mcp-configs/github.json` template uses the official remote endpoint `https://api.githubcopilot.com/mcp/` with the PAT in the `Authorization: Bearer` header. **Non-Copilot users:** if you do not have an active GitHub Copilot subscription and the remote endpoint rejects your PAT, download the standalone Go binary from `https://github.com/github/github-mcp-server/releases` and configure it as a stdio-transport MCP server (see `docs/reference/mcp-server-versions.md` Fallback table for the exact `.mcp.json` snippet).

## Jira API Token

1. Open [id.atlassian.com/manage-profile/security/api-tokens](https://id.atlassian.com/manage-profile/security/api-tokens)
2. **Create API token**
3. Label: `agent-flow-<PROJECT>`
4. Click **Create** — copy immediately
5. The official Atlassian Cloud MCP endpoint (`mcp.atlassian.com/v1/mcp`) uses OAuth via Claude Code — no `ATLASSIAN_EMAIL` or `ATLASSIAN_API_TOKEN` env vars are needed in `.mcp.json` for this transport.

## Linear API Key

1. Open Linear → **Settings → API → Personal API keys**
2. **Create key**
3. Label: `agent-flow`
4. Copy the key immediately

The default `examples/mcp-configs/linear.json` template uses Linear's official remote endpoint with OAuth via Claude Code — no `LINEAR_API_KEY` env var is needed. Bearer token authentication is supported as an alternative; in that case, add `--header "Authorization: Bearer <token>"` to the `claude mcp add` command.

## Redmine API Key

1. Open Redmine → **My account** (top right)
2. In the right sidebar: **API access key → Show**
3. If no key exists, click **Reset** to generate one
4. Copy the key
5. Alternative: Admin can generate keys via Administration → Users → {user} → API access key

Note: Redmine API key provides full access to whatever the user can access in the UI. There are no scoped tokens in Redmine.

## Token Security

- **`.mcp.json` NEVER in git** — add to `.gitignore`
- **Do not put tokens in CLAUDE.md** — CLAUDE.md is tracked in git
- **Token leak:** immediately revoke in the respective service:
  - **YouTrack:** Hub → Authentication → Delete token (or revoke at instance Hub for company SSO)
  - **Gitea:** Settings → Applications → Delete
  - **GitHub:** Settings → Developer settings → Personal access tokens → Revoke (fine-grained tokens have explicit revoke action)
  - **Jira / Atlassian:** id.atlassian.com/manage-profile/security/api-tokens → Revoke (or revoke OAuth grant via Connected apps)
  - **Linear:** Settings → API → Personal API keys → Delete (or revoke OAuth grant via Settings → Connected apps)
  - **Redmine:** My account → API access key → Reset (Reset rotates the key, invalidating the leaked one)
- **`.mcp.json.example`** — tracked in git as a template without actual tokens
