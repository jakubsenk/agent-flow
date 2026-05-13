# Agent 1: forgejo-mcp go install verification

## Question
Does `go install codeberg.org/goern/forgejo-mcp/v2@latest` work?

## Findings

### go.mod — No replace directives
Fetched from `https://codeberg.org/goern/forgejo-mcp/raw/branch/main/go.mod`.

- **Module path:** `codeberg.org/goern/forgejo-mcp/v2`
- **Go version:** 1.25.0
- **Replace directives:** None present. Issue #67 (replace directive blocking go install) is resolved.

### main.go exists at module root
`main.go` is present at the repository root with `package main`. It imports `codeberg.org/goern/forgejo-mcp/v2/cmd`, which means `go install` will find an executable entry point.

### v2 tags exist
Latest release is **v2.17.0** (March 28, 2026). All releases are in the v2.x.x series, confirming the `/v2` major version suffix in the module path is valid.

## Conclusion

`go install codeberg.org/goern/forgejo-mcp/v2@latest` should work correctly:
- Module path matches the `/v2` suffix
- No replace directives block the install
- `main.go` (package main) exists at the module root
- Latest tagged version is v2.17.0

**Correct install command:** `go install codeberg.org/goern/forgejo-mcp/v2@latest`
