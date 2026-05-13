# Phase 1 — Research Questions (Synthesized)

## Critical Questions Identified

### Q1: Does upstream goern/forgejo-mcp publish Windows binaries?
**Status:** Answered — NO. All 13 releases publish only Linux (amd64, arm64) and macOS/darwin (amd64, arm64) as .tar.gz archives. No .exe files exist. The .goreleaser.yml targets only linux and darwin.

### Q2: Is `go install codeberg.org/goern/forgejo-mcp@latest` a viable fallback?
**Status:** UNRELIABLE. The module path is `codeberg.org/goern/forgejo-mcp/v2`. Historically blocked by a `replace` directive in go.mod (tracked in issue #67). Latest v2.17.0 may have dropped the replace directive, but it's untested on Windows and undocumented.

### Q3: What is the correct curl invocation to detect HTTP errors?
**Status:** Answered. `curl --fail` exits non-zero on HTTP 4xx/5xx and does not write the error body to disk. Current invocation uses `curl -sL` without `--fail`, which silently saves the 404 response body.

### Q4: What is a typical valid binary size for forgejo-mcp?
**Status:** Answered. Approximately 4 MiB based on .tar.gz archive sizes (3.7-4.1 MiB). A 1 MB threshold is safe for validation.

### Q5: Are there alternative sources for Windows binaries?
**Status:** Answered. Two alternatives found:
- **raohwork/forgejo-mcp** (GitHub) — publishes actual Windows .exe binaries (amd64 + arm64). Latest v0.0.7 (Oct 2025).
- **npm package `forgejo-mcp`** on npmjs.com — potential cross-platform alternative via npx.

## Prioritized Research for Phase 2

1. Validate whether `go install codeberg.org/goern/forgejo-mcp/v2@latest` works now (replace directive status)
2. Evaluate raohwork fork compatibility with goern/forgejo-mcp API
3. Evaluate npm package as npx-based fallback (like other MCP servers in the plugin)
4. Determine the best validation strategy for the download step
