# Agent 1: Conservative (Senior DevOps Engineer)

## Diagnosis

The bug is in `skills/init/SKILL.md`, Step 5 ("Platform-specific handling"). The skill instructs Claude to download a binary from Codeberg release assets using a platform-specific asset name (`forgejo-mcp-windows-amd64.exe`). The upstream repository (goern/forgejo-mcp) does not publish Windows binaries. The `curl -sL` command silently saves the 404 HTML error page as the binary. There is no size or content validation after download.

## Proposed Fix: Two Changes, Minimal Scope

### Change 1: Add `--fail` to the download curl command (SKILL.md Step 5, sub-step 4)

**File:** `skills/init/SKILL.md`

**Current (line ~174):**
```bash
curl -sL -o ~/.claude/bin/{binary_name} "https://codeberg.org/goern/forgejo-mcp/releases/download/{tag}/{asset_name}"
```

**Proposed:**
```bash
curl -sfL -o ~/.claude/bin/{binary_name} "https://codeberg.org/goern/forgejo-mcp/releases/download/{tag}/{asset_name}"
```

The `-f` flag (`--fail`) causes curl to return exit code 22 on HTTP errors (404, 500, etc.) and write nothing to the output file. This is the single most impactful one-character change: it converts a silent corruption into a detectable failure that triggers the existing fallback path ("manual path collection").

### Change 2: Add `go install` fallback for Windows before manual path collection (SKILL.md Step 5)

**File:** `skills/init/SKILL.md`

After the download-and-verify block (sub-step 6) and before the "Manual path collection" fallback, insert a new intermediate fallback specifically for Windows:

**Insert after the verify step (line ~181), before "Manual path collection":**

```markdown
**Go-install fallback (Windows only — if download fails):**

If platform is Windows AND the download step failed (binary does not exist or is empty):
1. Check if Go toolchain is available: `which go` (or `where go` on Windows).
2. If `go` is found:
   - Display: `"No pre-built Windows binary available. Building from source via Go..."`
   - Run: `go install codeberg.org/goern/forgejo-mcp/v2@latest`
   - Determine the installed binary path: `$(go env GOPATH)/bin/forgejo-mcp.exe`
   - Copy to standard location: `cp "$(go env GOPATH)/bin/forgejo-mcp.exe" ~/.claude/bin/forgejo-mcp.exe`
   - Verify: `test -f ~/.claude/bin/forgejo-mcp.exe && test -s ~/.claude/bin/forgejo-mcp.exe`
   - If success: Display `"Built forgejo-mcp from source via go install. Installed to ~/.claude/bin/forgejo-mcp.exe"` → proceed to Step 6.
   - If failure: fall through to manual path collection.
3. If `go` is NOT found: fall through to manual path collection (do NOT error about Go — it is optional).
```

### Change 3: Add binary size sanity check to the verify step (defense in depth)

**File:** `skills/init/SKILL.md`

**Current verify step (line ~179):**
```bash
test -f ~/.claude/bin/{binary_name} && test -s ~/.claude/bin/{binary_name}
```

**Proposed:**
```bash
test -f ~/.claude/bin/{binary_name} && [ "$(wc -c < ~/.claude/bin/{binary_name})" -gt 1048576 ]
```

Rationale: `test -s` only checks "file is not empty" — a 404 HTML page (~10 bytes to ~10 KB) passes this check. A valid forgejo-mcp binary is ~4 MiB. Checking for >1 MiB is a simple heuristic that catches all HTML error pages without risking false negatives on legitimate builds. On Windows (Git Bash/MSYS2), `wc -c` works identically.

---

## Summary of File Changes

| File | Change | Lines affected |
|------|--------|---------------|
| `skills/init/SKILL.md` | Add `-f` flag to curl download command | 1 line (line ~174) |
| `skills/init/SKILL.md` | Add 1 MiB size check replacing `test -s` in verify step | 1 line (line ~179) |
| `skills/init/SKILL.md` | Insert Go-install fallback block for Windows between download-verify and manual-path-collection | ~12 new lines after line ~181 |

Total: 2 lines changed, ~12 lines added. No new files. No structural changes.

---

## Risks and Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| `curl --fail` behaves differently across curl versions | Very low | Low | `--fail` / `-f` has been stable since curl 7.1 (year 2000). Every modern system has it. |
| `go install` takes long or fails on exotic Go setups | Low | None (graceful) | It's a fallback, not the primary path. Failure falls through to manual path collection. User sees clear messaging. |
| 1 MiB threshold is wrong for a future smaller build of forgejo-mcp | Very low | Low | Even a stripped Go binary for a non-trivial MCP server will exceed 1 MiB. If upstream ever ships a sub-1 MiB binary, we simply lower the threshold. |
| Go toolchain not installed on user's Windows machine | Medium | None | Explicitly handled: if `go` not found, skip silently to manual fallback. No new hard dependency introduced. |
| `wc -c` not available on some Windows shells | Very low | Low | The skill already uses `uname`, `curl`, `test`, `chmod` — all POSIX utilities. `wc` is in the same category and available in Git Bash, MSYS2, WSL, and Cygwin. Claude Code on Windows uses bash. |

---

## What I Would NOT Do (and Why)

### 1. Would NOT switch the primary install method to `go install` for all platforms

The current curl-based download is correct for Linux and macOS where binaries ARE published. Replacing a 2-second download with a 30-60 second `go install` that requires a Go toolchain is a strict regression for the majority of users. Go-install is only appropriate as a fallback when the binary download is unavailable.

### 2. Would NOT add npm/npx-based alternatives

Research confirmed npm packages for forgejo-mcp either lack a `bin` field or use incompatible environment variables (raohwork fork). Adding an npm path would introduce a fragile dependency that could break silently in a different way. Not worth the complexity.

### 3. Would NOT add Docker-based fallback

Docker adds enormous complexity (volume mounts, networking, env var passthrough) for an MCP server that needs to run as a local stdio process. The cure is worse than the disease.

### 4. Would NOT file an upstream issue and wait

While filing an issue with goern/forgejo-mcp requesting Windows binaries is reasonable as a parallel action, it does not fix the problem for current users. We need a fix we control.

### 5. Would NOT add platform detection to skip the download entirely on Windows

Skipping the download and going straight to `go install` would work but removes the possibility that upstream adds Windows binaries in the future. The `curl --fail` + size check approach is self-healing: the day upstream publishes Windows binaries, the primary path starts working with zero changes to our code.

### 6. Would NOT add complex retry logic, checksum verification, or GPG signature checking

These are all good ideas in theory but disproportionate to the problem. The fix needs to (a) detect the failure and (b) provide a working alternative. `curl --fail` + size guard + `go install` fallback achieves both with minimal moving parts.

---

## Confidence Assessment

- **Will this fix the bug?** Yes. `curl --fail` prevents saving 404 pages. The size check catches any edge case where `--fail` is somehow bypassed. The `go install` fallback provides a working binary on Windows.
- **Will this break existing behavior?** No. Linux/macOS paths are unchanged (the `-f` flag is a no-op when the download succeeds). The Go fallback only triggers on Windows when the download fails.
- **Is this the minimal fix?** Nearly. The absolute minimum is just adding `-f` to curl (1 character). But without the Go fallback, Windows users would always hit the manual path collection, which is a poor UX. The 3-part fix is the smallest change that actually solves the user's problem end-to-end.
