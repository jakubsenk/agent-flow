# Phase 3 — Brainstorm Synthesis

## Approach Selection: Conservative + Skeptical Insights

The conservative approach (minimal surgical changes) is the right base, enhanced with key skeptical insights about edge cases.

## Chosen Strategy: Three-Tier Acquisition with Validation

### Tier 1: Direct Binary Download (all platforms)
- Add `--fail` flag to curl → prevents saving HTTP error pages as binaries
- After download, validate file size > 100KB (valid binary is ~4 MiB, error pages < 1 KB)
- If both pass → success, proceed as before

### Tier 2: Go Install Fallback (Windows only — when Tier 1 fails)
- Check if Go toolchain is available: `command -v go`
- If available → run `GOBIN=~/.claude/bin go install codeberg.org/goern/forgejo-mcp/v2@latest`
  - Uses `GOBIN` to place binary directly in expected location (addresses skeptical concern about GOPATH/bin mismatch)
  - Binary name: `forgejo-mcp.exe` on Windows (Go uses the module name)
- After install, verify binary exists and size > 100KB (same validation gate)
- If Go install fails → fall through to Tier 3

### Tier 3: Manual Path Collection (existing fallback — all platforms)
- Enhanced error message explaining why auto-download failed:
  - "Official Windows binaries are not published by upstream. Install Go and re-run, or build manually."
- Existing manual path collection logic remains unchanged

## Files to Modify (3 files, PATCH version bump)

### 1. skills/init/SKILL.md (Step 5, lines ~160-193)
**Changes:**
- Add `--fail` to curl in step 4
- Replace naive `test -f && test -s` validation with size check > 100KB
- Insert Windows-specific Go install fallback between failed download and manual path collection
- Enhanced error messages explaining WHY download failed on Windows

### 2. docs/guides/mcp-configuration.md (line ~48)
**Changes:**
- Replace "Download `forgejo-mcp-windows-amd64.exe`" with note that official Windows binaries are not available
- Document `go install` as the Windows installation method

### 3. docs/guides/installation.md (Platform Notes section)
**Changes:**
- Add note under Windows section: forgejo-mcp requires Go toolchain for Windows (no official binary)
- Add the `go install` command

## Rejected Approaches
- **npm/npx fallback:** Package has no bin field, unreliable
- **raohwork fork:** Different env vars, not a drop-in
- **Binary smoke test (`--help`):** Too heavy for markdown skill instructions — size check is sufficient
- **cross-platform.md update:** Out of scope — the three-tier logic is in SKILL.md, not in user-facing docs
- **All-platform `go install` preference:** Over-engineering — Linux/macOS downloads work fine

## Key Edge Cases to Handle
1. Go not in PATH → skip Go fallback, fall to manual
2. `go install` fails (network, build error) → fall to manual with error message
3. File already exists from prior run → existing "reuse" logic handles this
4. Codeberg returns 200 with error page (unlikely) → size check catches this
