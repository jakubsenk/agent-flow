# Cross-Platform Test Checklist

Manual checklist for verifying the pipeline on different platforms.

## Prerequisites

- [ ] Plugin installed (`/plugin install`)
- [ ] `.mcp.json` configured with valid tokens
- [ ] `## Automation Config` in the project's CLAUDE.md
- [ ] Test issue exists in the issue tracker

## Windows

- [ ] `/ceos-agents:check-setup` — all checks OK
- [ ] `/ceos-agents:analyze-bug <TEST-ISSUE>` — triage + analysis completes
- [ ] Gitea MCP server (`gitea-mcp.exe`) responds
- [ ] YouTrack MCP server (npx) responds
- [ ] Worktree paths work (relative path in Automation Config)

## Linux

- [ ] Gitea MCP binary: `chmod +x` set
- [ ] Path to binary in `.mcp.json` follows Linux convention
- [ ] `/ceos-agents:check-setup` — all checks OK
- [ ] `/ceos-agents:analyze-bug <TEST-ISSUE>` — triage + analysis completes
- [ ] Worktree paths: relative format (not `C:\...`)

## macOS

- [ ] Analogous to Linux — not officially supported
- [ ] Gitea MCP binary: darwin-amd64 or darwin-arm64

## Notes

- The plugin itself is platform-agnostic (pure markdown)
- Platform-specific differences are only in `.mcp.json` paths and MCP server binaries
- Worktree paths in Automation Config must be **relative** (e.g. `.worktrees/`)
