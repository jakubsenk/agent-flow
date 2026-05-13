# Formal Acceptance Criteria: Windows forgejo-mcp Acquisition Fix

Each criterion is independently verifiable. Test scenarios describe the expected observable behavior.

---

## AC-1: Windows init with no Go produces clear error, no corrupt binary

**Condition:** Platform is Windows (`uname -s` matches `MINGW*`/`MSYS*`), the upstream curl download fails (404 or file < 100 KB), and `go` is not available on PATH.

**Expected behavior:**
1. The corrupt/undersized file is removed from `~/.claude/bin/` (no `forgejo-mcp.exe` left behind from the failed download).
2. A clear error message is displayed containing:
   - The phrase "no Windows binary published upstream" (or equivalent)
   - A link to https://go.dev/dl/
   - Instruction to re-run `/ceos-agents:init` or download manually
3. The skill proceeds to the manual path collection fallback (prompts user for binary path).

**Verification:** Read the modified Step 5 in `skills/init/SKILL.md` and confirm steps 5, 8c match this behavior. No code path saves a < 100 KB file as a valid binary.

---

## AC-2: Windows init with Go performs successful go install

**Condition:** Platform is Windows, curl download fails, and `go` is available on PATH.

**Expected behavior:**
1. The skill runs `GOBIN=~/.claude/bin go install codeberg.org/goern/forgejo-mcp/v2@latest`.
2. The module path includes `/v2` (required for v2.x semantic import versioning).
3. On success, the binary is located at `~/.claude/bin/forgejo-mcp.exe`.
4. A success message is displayed: `"Installed forgejo-mcp via go install to ~/.claude/bin/forgejo-mcp.exe"` (or equivalent).
5. The skill continues to Step 6 (.mcp.json generation) using this binary path.

**Verification:** Read the modified Step 5 in `skills/init/SKILL.md` and confirm step 8a-8b uses the exact `go install` command with `/v2` module path and `GOBIN=~/.claude/bin`.

---

## AC-3: Linux/macOS init has no regression

**Condition:** Platform is Linux or macOS, upstream binary is available.

**Expected behavior:**
1. The curl command now uses `-sfL` (added `--fail` flag) instead of `-sL`.
2. After download, file size is validated (>= 102400 bytes).
3. On successful download and validation, behavior is identical to the previous version (display success message, proceed to Step 6).
4. On download failure, the skill proceeds directly to manual path collection (no Go install fallback on non-Windows platforms).
5. The Go install tier (step 8) is explicitly gated on Windows platform detection.

**Verification:** Read the modified Step 5 and confirm: (a) `curl -sfL` is used, (b) `wc -c` size check is present, (c) step 8 is explicitly conditional on Windows, (d) step 9 handles non-Windows failure by going to manual fallback.

---

## AC-4: mcp-configuration.md mentions go install for Windows

**Condition:** The file `docs/guides/mcp-configuration.md` has been updated.

**Expected behavior:**
1. The "Gitea/Forgejo MCP server" section no longer instructs Windows users to "Download `forgejo-mcp-windows-amd64.exe`".
2. Instead, it provides the `go install` command: `GOBIN=~/.claude/bin go install codeberg.org/goern/forgejo-mcp/v2@latest`.
3. It includes a note that pre-built Windows binaries are not reliably published.
4. It mentions Go as a requirement with a link to https://go.dev/dl/.
5. The Linux install line remains unchanged.

**Verification:** Read `docs/guides/mcp-configuration.md` lines 46-55 and confirm all five points above.

---

## AC-5: installation.md mentions Go requirement for Windows

**Condition:** The file `docs/guides/installation.md` has been updated.

**Expected behavior:**
1. The "Platform Notes > Windows" section contains a note about forgejo-mcp requiring Go on Windows.
2. The note mentions that `/ceos-agents:init` will attempt `go install` as a fallback.
3. The note includes `go version` as a verification command or links to https://go.dev/dl/.
4. The Linux and macOS sections remain unchanged.

**Verification:** Read `docs/guides/installation.md` lines 68-82 and confirm the Windows section has the Go note while Linux/macOS sections are unmodified.
