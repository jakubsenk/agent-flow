# Requirements: Windows forgejo-mcp Acquisition Fix

**Issue:** `/ceos-agents:init` silently fails on Windows because the upstream forgejo-mcp repository does not publish Windows binaries. The `curl` download saves a 404 HTML error page as the binary, producing a corrupt `.exe`.

**Strategy:** Three-tier acquisition: curl --fail download, Go install fallback, manual path collection.

---

## REQ-1: Harden curl download with --fail and file-size validation

The existing `curl -sL` download command in `skills/init/SKILL.md` Step 5 MUST be changed to `curl -sfL` (adding `--fail`) so that HTTP error responses (404, 500) cause curl to exit non-zero instead of saving the error page as the binary.

After a successful curl exit, the downloaded file MUST be validated by checking its size is greater than 100 KB (102400 bytes). Use `wc -c < file` for cross-platform byte count (works in Git Bash, Linux, macOS). If the file is smaller, treat the download as failed, remove the file, and proceed to the next tier.

**Rationale:** The upstream repo intermittently publishes or removes platform-specific assets. A 404 error page is typically < 1 KB while a valid forgejo-mcp binary is ~4 MiB.

## REQ-2: Go install fallback on download failure (Windows-aware)

When the curl download fails (non-zero exit OR file-size validation failure), and the platform is Windows (`uname -s` matches `MINGW*` or `MSYS*`), the skill MUST attempt a second acquisition tier:

1. Check if `go` is available: `command -v go`
2. If Go is available, run:
   ```bash
   GOBIN=~/.claude/bin go install codeberg.org/goern/forgejo-mcp/v2@latest
   ```
   This places the compiled binary directly into `~/.claude/bin/forgejo-mcp.exe`.
3. If `go install` succeeds and the binary exists at `~/.claude/bin/forgejo-mcp.exe`, treat as success.
4. If Go is NOT available, display a clear error message:
   ```
   "forgejo-mcp download failed (no Windows binary published upstream).
   Install Go (https://go.dev/dl/) and re-run /ceos-agents:init, or download manually."
   ```
   Then proceed to the manual path collection fallback (existing tier 3).
5. If `go install` fails (non-zero exit), display the error output and proceed to manual path collection.

On Linux/macOS, if the curl download fails, skip the Go install tier and proceed directly to manual path collection (existing behavior preserved).

**Rationale:** `go install codeberg.org/goern/forgejo-mcp/v2@latest` is confirmed working (the `replace` directive was removed in v2.17.0). Using `GOBIN` places the binary exactly where the skill expects it.

## REQ-3: Update mcp-configuration.md Windows install instructions

In `docs/guides/mcp-configuration.md`, the Gitea/Forgejo MCP server section's Windows install line currently reads:

> Download `forgejo-mcp-windows-amd64.exe`, save as `bin/forgejo-mcp.exe`

This MUST be replaced with instructions that reflect the `go install` method as the primary Windows install path, plus a note that pre-built Windows binaries are not reliably available upstream:

- Primary: `GOBIN=~/.claude/bin go install codeberg.org/goern/forgejo-mcp/v2@latest`
- Warning: Pre-built Windows binaries are not reliably published; use `go install` instead.

The Linux install line remains unchanged.

## REQ-4: Update installation.md with Windows Go requirement

In `docs/guides/installation.md`, the "Platform Notes > Windows" section MUST be updated to mention that Go is required (or strongly recommended) for forgejo-mcp acquisition on Windows.

Add a note such as:
- forgejo-mcp (Gitea/Forgejo tracker): Pre-built Windows binaries are not reliably available. Go (`go version`) is required for automatic installation via `go install`. Install Go from https://go.dev/dl/ before running `/ceos-agents:init`.
