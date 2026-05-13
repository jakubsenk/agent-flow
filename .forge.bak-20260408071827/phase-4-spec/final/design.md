# Design: Windows forgejo-mcp Acquisition Fix

## Overview

Three files are modified. The core change is in `skills/init/SKILL.md` Step 5, which gains a three-tier acquisition flow. Two documentation files receive corresponding updates.

---

## File 1: `skills/init/SKILL.md`

### Section: Step 5 — Auto-download (lines 166-181)

The current auto-download flow is a two-tier system: curl download, then manual fallback. The new flow introduces a validated curl download (tier 1), a Go install fallback for Windows (tier 2), and the existing manual fallback (tier 3).

#### Current flow (to be replaced)

```
1. Check if already installed → reuse
2. mkdir -p ~/.claude/bin
3. Fetch latest release tag
4. curl -sL download
5. chmod +x (Linux/macOS)
6. Verify: test -f && test -s
   - Success → done
   - Failure → manual fallback
```

#### New flow

```
1. Check if already installed → reuse  (UNCHANGED)
2. mkdir -p ~/.claude/bin  (UNCHANGED)
3. Fetch latest release tag  (UNCHANGED)
4. Download with curl --fail:
     curl -sfL -o ~/.claude/bin/{binary_name} "{url}"
5. Validate downloaded file size:
     FILESIZE=$(wc -c < ~/.claude/bin/{binary_name} 2>/dev/null || echo 0)
     If FILESIZE < 102400 → download failed, remove file
6. Set permissions (Linux/macOS only): chmod +x  (UNCHANGED)
7. If download succeeded (file exists AND size >= 102400) → done
8. If download failed AND platform is Windows:
     a. Check: command -v go
     b. If Go available:
          GOBIN=~/.claude/bin go install codeberg.org/goern/forgejo-mcp/v2@latest
          If binary exists at ~/.claude/bin/forgejo-mcp.exe → done
          If go install fails → display error → manual fallback
     c. If Go NOT available:
          Display: "forgejo-mcp download failed (no Windows binary published upstream).
          Install Go (https://go.dev/dl/) and re-run /ceos-agents:init, or download manually."
          → manual fallback
9. If download failed AND platform is NOT Windows:
     → manual fallback  (existing behavior)
```

#### Exact text replacement in SKILL.md

Replace the content of the **Auto-download (default behavior)** subsection (lines 166-181) with:

```markdown
**Auto-download (default behavior):**

1. **Check if already installed:** Run `test -f ~/.claude/bin/{binary_name}`. If exists → reuse, skip download. Display: `"forgejo-mcp already installed at ~/.claude/bin/{binary_name}"`
2. **Create bin directory:** `mkdir -p ~/.claude/bin`
3. **Fetch latest release tag:**
   ```bash
   curl -sL https://codeberg.org/api/v1/repos/goern/forgejo-mcp/releases/latest | grep -o '"tag_name":"[^"]*"' | head -1 | cut -d'"' -f4
   ```
4. **Download binary (with failure detection):**
   ```bash
   curl -sfL -o ~/.claude/bin/{binary_name} "https://codeberg.org/goern/forgejo-mcp/releases/download/{tag}/{asset_name}"
   ```
   Note: `-f` (`--fail`) causes curl to exit non-zero on HTTP errors (404, 500) instead of saving the error page.
5. **Validate file size** (guards against truncated downloads or empty files):
   ```bash
   FILESIZE=$(wc -c < ~/.claude/bin/{binary_name} 2>/dev/null || echo 0)
   ```
   If `FILESIZE` < 102400 (100 KB) → remove the file (`rm -f ~/.claude/bin/{binary_name}`), treat download as failed.
   Valid forgejo-mcp binaries are ~4 MiB; anything under 100 KB is corrupt or an error page.
6. **Set permissions** (Linux/macOS only): `chmod +x ~/.claude/bin/{binary_name}`
7. **Verify download:** If `~/.claude/bin/{binary_name}` exists and passed size validation:
   - Success → Display: `"Downloaded forgejo-mcp {tag} to ~/.claude/bin/{binary_name}"`
   - Failure → continue to step 8
8. **Go install fallback (Windows only):** If download failed AND platform is Windows (`MINGW*`/`MSYS*`):
   a. Check if Go is available: `command -v go`
   b. **If Go is available:**
      ```bash
      GOBIN=~/.claude/bin go install codeberg.org/goern/forgejo-mcp/v2@latest
      ```
      - If `~/.claude/bin/forgejo-mcp.exe` exists after install → Display: `"Installed forgejo-mcp via go install to ~/.claude/bin/forgejo-mcp.exe"` → Success
      - If `go install` fails → Display the error output, then fall back to **manual path collection**
   c. **If Go is NOT available:**
      Display: `"forgejo-mcp download failed (no Windows binary published upstream). Install Go (https://go.dev/dl/) and re-run /ceos-agents:init, or download manually."`
      → fall back to **manual path collection**
9. **Non-Windows download failure:** If download failed AND platform is NOT Windows → fall back to **manual path collection** (see below)
```

### Section: Manual path collection (lines 185-193)

No changes. The existing manual path collection remains as-is: display download URL, prompt for path, validate with `test -f`, max 3 attempts.

### Section: Platform asset mapping (lines 160-164)

No changes. The asset name mapping (Windows → `forgejo-mcp-windows-amd64.exe`, etc.) remains as-is. The curl download still attempts the platform-specific asset first.

---

## File 2: `docs/guides/mcp-configuration.md`

### Section: Gitea/Forgejo MCP server (lines 46-51)

Replace line 48:
```
- **Windows install:** Download `forgejo-mcp-windows-amd64.exe`, save as `bin/forgejo-mcp.exe`
```

With:
```
- **Windows install:** Pre-built Windows binaries are not reliably published upstream. Use Go to install:
  ```bash
  GOBIN=~/.claude/bin go install codeberg.org/goern/forgejo-mcp/v2@latest
  ```
  Requires Go installed (https://go.dev/dl/). The binary will be placed at `~/.claude/bin/forgejo-mcp.exe`.
```

All other lines in this section remain unchanged.

---

## File 3: `docs/guides/installation.md`

### Section: Platform Notes > Windows (lines 68-70)

Current content:
```markdown
### Windows (primary)

The procedure described above is for Windows. Paths use `~/` notation (Git Bash / WSL).
```

Replace with:
```markdown
### Windows (primary)

The procedure described above is for Windows. Paths use `~/` notation (Git Bash / WSL).

**forgejo-mcp note:** Pre-built Windows binaries for forgejo-mcp are not reliably available from the upstream repository. The `/ceos-agents:init` skill will automatically attempt `go install` as a fallback. Ensure Go is installed (`go version`) before running init. Install Go from https://go.dev/dl/ if needed.
```

### Section: Platform Notes > Linux (lines 72-77)

No changes. The Linux section already has correct instructions for the direct binary download.

---

## Cross-Platform Considerations

- **File size check uses `wc -c < file`:** This works identically in Git Bash (Windows), Linux, and macOS. It outputs only the byte count (no filename), making parsing trivial. This is preferred over `stat` which has different flags on macOS (`-f %z`) vs. Linux (`-c %s`) and may not exist in Git Bash.
- **`command -v go`:** Works in all POSIX-like shells including Git Bash.
- **`GOBIN=~/.claude/bin`:** The `~` expansion works in Git Bash. The `go install` command respects `GOBIN` and places the output binary there.
- **The `/v2` module path** (`codeberg.org/goern/forgejo-mcp/v2@latest`) is required because the module uses Go modules v2 semantic import versioning. Without `/v2`, `go install` would fetch v1.x or fail.

## Non-Goals

- No changes to the macOS flow (macOS binaries are published upstream and work correctly).
- No changes to the `forgejo-mcp` asset naming convention.
- No changes to the `.mcp.json` generation logic in Step 6.
- No introduction of new config keys in Automation Config.
