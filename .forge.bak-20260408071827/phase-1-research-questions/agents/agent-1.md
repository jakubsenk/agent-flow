# Agent 1: forgejo-mcp Windows Download Research

## Research Questions Answered

### 1. Does upstream forgejo-mcp publish Windows binaries?

**No.** The Codeberg releases page (https://codeberg.org/goern/forgejo-mcp/releases) confirms that **no Windows binaries exist** for any release.

Latest release: **v2.17.0** (2026-03-28) assets:
- `forgejo-mcp_2.17.0_darwin_amd64.tar.gz` (4.1 MiB)
- `forgejo-mcp_2.17.0_darwin_arm64.tar.gz` (3.8 MiB)
- `forgejo-mcp_2.17.0_linux_amd64.tar.gz` (4.1 MiB)
- `forgejo-mcp_2.17.0_linux_arm64.tar.gz` (3.7 MiB)

All releases across all 13 releases follow this same 4-asset pattern: Linux (amd64, arm64) and macOS/darwin (amd64, arm64) only. No `.exe` files, no Windows archives.

### 2. What is the Go module path for `go install`?

Module path: **`codeberg.org/goern/forgejo-mcp/v2`**

**However, remote `go install` does NOT work:**
```
go install codeberg.org/goern/forgejo-mcp/v2@latest  # FAILS
```

The `go.mod` contains a `replace` directive for a forked Forgejo SDK, which prevents remote module installation. This is a known issue tracked in [#67](https://codeberg.org/goern/forgejo-mcp/issues/67).

The only supported build-from-source method is clone-and-build:
```bash
git clone https://codeberg.org/goern/forgejo-mcp.git
cd forgejo-mcp
go install .
```

### 3. Typical binary size

Based on the release assets, the compiled binary is approximately **4 MiB** (the `.tar.gz` archives are 3.7–4.1 MiB, so the raw binary is likely similar or slightly larger after decompression).

## Implications for /init skill

- The current approach of downloading `forgejo-mcp-windows-amd64.exe` from Codeberg will always 404 — the file does not exist and will never exist in the current release pipeline.
- `go install` from remote is also broken upstream (replace directive issue).
- Windows users must either: (a) use the npm package (`forgejo-mcp` on npm), (b) clone and build manually with Go 1.24+, or (c) skip forgejo-mcp on Windows.
- The npm package (`https://www.npmjs.com/package/forgejo-mcp`) may be a cross-platform alternative worth investigating.
