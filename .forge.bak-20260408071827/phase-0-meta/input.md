Bug: /ceos-agents:init — forgejo-mcp download silently fails on Windows.

Location: skills/init/SKILL.md, lines ~161-193

Problem: Init skill downloads forgejo-mcp-windows-amd64.exe from Codeberg releases, but upstream repo (goern/forgejo-mcp) does not publish Windows binaries — .goreleaser.yml targets only linux and darwin. Curl gets HTTP 404 whose body ("Not Found") is saved as .exe. Post-download check (test -f && test -s) passes because file exists and has 10 bytes.

Impact: Gitea MCP server won't start, pipeline cannot work with source control.

Expected fix:
1. After download, validate that file is a real binary (e.g. file command, or size check > 1 MB)
2. If Windows asset doesn't exist → fallback to go install / cross-compile from source (Go is commonly available), or clear error message with instructions
3. Update docs/guides/mcp-configuration.md line ~48 — warn that Windows binary is not officially available
4. Consider adding note to docs/guides/installation.md

Reproduction: Run /ceos-agents:init on Windows with Gitea tracker
