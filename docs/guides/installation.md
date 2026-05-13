# Installing ceos-agents

Step by step: from a clean slate to a working pipeline.

## Prerequisites

| What | How to verify |
|------|---------------|
| Claude Code CLI | `claude --version` |
| Git | `git --version` + `git config --global user.email` |
| Access to internal Gitea | See section below |

## 1. Gitea Access

The plugin is hosted on your Git server (e.g., `<your-git-host>`). You need SSH or HTTPS access.

### Option A: SSH (recommended)

1. Generate an SSH key (if you don't have one):
   ```bash
   ssh-keygen -t ed25519 -C "your@email.com"
   ```
2. Add the public key to Gitea: **Settings → SSH/GPG Keys → Add Key**
3. Configure `~/.ssh/config`:
   ```
   Host <your-git-host>
     HostName <your-git-host>
     User git
     IdentityFile ~/.ssh/id_ed25519
   ```
4. Verify: `git ls-remote git@<your-git-host>:<owner>/<repo>.git`

### Option B: HTTPS

1. Generate a Gitea Personal Access Token (see [tokens.md](tokens.md))
2. Verify: `git ls-remote https://<TOKEN>@<your-git-host>/<owner>/<repo>.git`

## 2. Plugin Installation

```bash
claude plugin marketplace add <path-to-repo>  # e.g. C:/gitea_ceos-agents
claude plugin install ceos-agents@ceos-agents
```

Verify: enter `/ceos-agents:` and check that skills appear (tab-complete).

### Updating the Plugin

The marketplace cache does not update automatically. After a new version is released:

```bash
cd ~/.claude/plugins/marketplaces/ceos-agents && git fetch origin && git pull origin main
rm -rf ~/.claude/plugins/cache/ceos-agents/
```

Then restart your Claude Code session.

## 3. Project Setup

After installing the plugin, you need to configure your specific project:

1. Create `.mcp.json` in the project root — see [mcp-configuration.md](mcp-configuration.md)
2. Add `## Automation Config` to the project's CLAUDE.md — see the example in the plugin README
3. Verify: `/ceos-agents:check-setup`

## 4. Pipeline State and .gitignore

The plugin writes runtime state files to `.ceos-agents/` in your project root. These files are local to each pipeline run and should generally not be committed.

**Recommended `.gitignore` entries:**

```
.ceos-agents/autopilot.lock/
.ceos-agents/state.json
.ceos-agents/pipeline.log
.ceos-agents/autopilot.log
```

**`pipeline-history.md` — operator choice:**

`.ceos-agents/pipeline-history.md` is an append-only run log that accumulates cross-run block patterns and outcomes. Operators have two options:

- **Gitignore it (default):** Add `.ceos-agents/pipeline-history.md` to `.gitignore` to keep it local. Suitable for single-developer or ephemeral CI environments.
- **Commit it (shared learning):** Omit it from `.gitignore` to commit and share cross-pipeline learning across team members. If you commit this file, note that `block_reason` values are redacted via `sanitize_block_reason()` (18-pattern credential scrubbing including bare-keyword variables added in v6.9.1), but you should still review the file for any sensitive operational details before committing.

## Platform Notes

### Windows (primary)

The procedure described above is for Windows. Paths use `~/` notation (Git Bash / WSL).

**gitea-mcp note:** The `/ceos-agents:setup-mcp` skill automatically downloads and installs `gitea-mcp` from [gitea.com/gitea/gitea-mcp](https://gitea.com/gitea/gitea-mcp/releases). If the download fails, it falls back to `go install gitea.com/gitea/gitea-mcp@latest`. Ensure Go is installed (`go version`) as a fallback option. Install Go from [go.dev/dl](https://go.dev/dl/) if needed.

### Linux

- SSH configuration is identical
- Gitea MCP server: download the linux-amd64 archive `gitea-mcp-linux-amd64.tar.gz` from [gitea.com/gitea/gitea-mcp/releases](https://gitea.com/gitea/gitea-mcp/releases), extract with `tar xf`, save binary as `~/.claude/bin/gitea-mcp`, set `chmod +x`
- In `.mcp.json` use the Linux path to the binary
- Details in [cross-platform.md](cross-platform.md)

### macOS

Not explicitly supported, but likely functional (analogous to Linux).

## Known Limitations

### Slash command collision with Claude Code builtins

The short form `/init` collides with Claude Code's built-in slash command. Use the namespaced form instead:

- `/ceos-agents:setup-mcp` (renamed from `/ceos-agents:init` in v7.0.0)

The namespaced form `/ceos-agents:*` is unambiguous. See CHANGELOG.md for full migration notes.
