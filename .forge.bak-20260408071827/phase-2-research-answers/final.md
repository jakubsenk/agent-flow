# Phase 2 — Research Answers (Synthesized)

## Verified Findings

### 1. `go install` is the viable Windows fallback
- **Command:** `go install codeberg.org/goern/forgejo-mcp/v2@latest`
- **Status:** WORKS. Issue #67 (replace directive) is resolved. go.mod is clean.
- **Latest version:** v2.17.0 (March 28, 2026)
- **Binary location:** `$(go env GOPATH)/bin/forgejo-mcp.exe` on Windows
- **Requirement:** Go toolchain must be installed

### 2. npm/npx alternatives are NOT viable
- `forgejo-mcp` npm package exists (v1.2.0) but has no `bin` field — `npx forgejo-mcp` downloads but doesn't execute
- `@ric_/forgejo-mcp` scoped package seen in community configs but unverified
- Not a reliable fallback path

### 3. raohwork/forgejo-mcp fork is NOT a drop-in replacement
- Different codebase (not a fork of goern), different license (MPL-2.0 vs MIT)
- **Critical:** Different env vars — `FORGEJOMCP_SERVER`/`FORGEJOMCP_TOKEN` vs `FORGEJO_URL`/`FORGEJO_ACCESS_TOKEN`
- Would require separate config branches — too much complexity for a fallback

### 4. Download validation strategy
- **Primary fix:** Add `--fail` flag to curl — prevents saving 404 response bodies
- **Secondary validation:** File size threshold > 100KB (valid binary is ~4 MiB)
- **Tertiary:** `file` command to check magic bytes (PE/MZ header for Windows)

## Recommended Fix Strategy

### For skills/init/SKILL.md:
1. Add `--fail` to the curl download command
2. After download, check file size > 100KB (`stat --format=%s` on Linux, `stat -f%z` on macOS, `wc -c` cross-platform)
3. If curl fails OR file too small → check if `go` is available (`command -v go`)
4. If Go available → `go install codeberg.org/goern/forgejo-mcp/v2@latest`, then locate binary at `$(go env GOPATH)/bin/forgejo-mcp(.exe)`
5. If Go NOT available → clear error message with manual instructions

### For docs:
1. `mcp-configuration.md` line ~48: Replace "Download forgejo-mcp-windows-amd64.exe" with note that official Windows binary is not available, use `go install` instead
2. `installation.md` platform notes: Add Go toolchain requirement for Windows, document the `go install` command
