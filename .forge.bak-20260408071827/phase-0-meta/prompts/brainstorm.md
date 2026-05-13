# Phase 2 — Brainstorm

**SKIPPED** — Fast-track eligible. Fix approach is well-defined.

## Approach Summary (from bug description)

The fix has three parts:

### Part 1: Robust download validation (skills/init/SKILL.md)
Replace the naive `test -f && test -s` check with a size-based validation. A valid forgejo-mcp binary is several MB; an HTTP error page is < 1 KB. Check that the downloaded file is > 1 MB.

### Part 2: Windows-specific fallback (skills/init/SKILL.md)
When download fails validation on Windows:
- **Option A (preferred):** Try `go install codeberg.org/goern/forgejo-mcp@latest` if Go is available
- **Option B (fallback):** Clear error message explaining that Windows binaries are not published upstream, with manual build instructions

### Part 3: Documentation updates
- `docs/guides/mcp-configuration.md` line ~48: Add warning that Windows binary is not officially available upstream
- `docs/guides/installation.md`: Add Windows-specific note about forgejo-mcp requiring Go build
