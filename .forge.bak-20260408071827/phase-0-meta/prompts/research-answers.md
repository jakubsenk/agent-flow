# Phase 1 — Research Answers

**SKIPPED** — Fast-track eligible. Root cause is provided in bug report.

## Known Facts (from bug description)

1. **No Windows binary exists upstream.** The .goreleaser.yml in goern/forgejo-mcp targets only linux and darwin.
2. **HTTP 404 body is saved as .exe.** curl -sL writes the "Not Found" HTML/text response (approximately 10 bytes) to disk as forgejo-mcp.exe.
3. **Post-download validation is insufficient.** `test -f && test -s` passes because the file exists and has non-zero size (10 bytes of error text).
4. **Go install is a viable fallback.** The project is a Go binary; `go install codeberg.org/goern/forgejo-mcp@latest` should work if Go is installed.
5. **Valid binary size is >> 1 MB.** Any legitimate Go binary will be several megabytes. A 1 MB threshold is safe.
