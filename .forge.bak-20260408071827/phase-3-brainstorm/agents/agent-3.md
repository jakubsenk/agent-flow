# Agent 3: Skeptical Engineer -- Edge Cases & Failure Modes

## Role

Security-minded engineer questioning assumptions and finding edge cases in the proposed fixes for the Windows forgejo-mcp silent failure.

---

## 1. Edge Cases and Failure Modes per Proposed Fix

### Fix A: `go install codeberg.org/goern/forgejo-mcp/v2@latest`

**Positive:** Confirmed working. Builds from source, so platform availability is a non-issue -- if it compiles on a platform, it works there.

**Failure modes:**

1. **Go not installed.** The user does not have Go on their system. Unlike Node.js (checked in Step 2b), there is currently NO prerequisite check for Go in the init skill. This is a hard failure with a confusing error message (`bash: go: command not found`).

2. **Go version too old.** The `forgejo-mcp` module may require Go 1.21+ or 1.22+ (Go modules declare minimum version in `go.mod`). If the user has Go 1.19 installed, `go install` will fail with a cryptic version mismatch error. The user will not understand why.

3. **`go install` succeeds but binary lands in wrong location.** `go install` puts binaries in `$GOPATH/bin` or `$GOBIN` or `$HOME/go/bin`. The init skill expects the binary at `~/.claude/bin/forgejo-mcp`. These paths are different. The skill would need to either (a) set `GOBIN=~/.claude/bin` before running the command, or (b) copy/move the binary after install, or (c) find it in `$GOPATH/bin`.

4. **`go install` network failure.** Codeberg's Go module proxy may be slow or unreachable. `go install` could hang for minutes before timing out. No progress indicator.

5. **`go install` builds but the binary has a different name.** The module path is `codeberg.org/goern/forgejo-mcp/v2` -- Go will name the binary after the last path segment. With `/v2` suffix this _should_ still produce `forgejo-mcp` (Go strips `/vN` suffixes from binary names), but this assumption needs verification. If the binary is named `v2` instead, the skill breaks.

6. **CGo dependencies.** If forgejo-mcp requires CGo (unlikely for a pure Go MCP server, but not verified), the build would fail on systems without a C compiler. Windows users rarely have gcc in PATH.

7. **Corporate proxy/firewall.** `go install` fetches from module proxies (proxy.golang.org by default, then direct). Corporate environments often block these. The error messages from Go in this case are unhelpful.

8. **Disk space.** Go module cache + compilation artifacts can consume hundreds of MB. Not catastrophic, but worth noting.

### Fix B: `curl --fail` flag on download

**Positive:** Simple, one-character change. Prevents saving error pages as binaries.

**Failure modes:**

1. **Codeberg returns 200 with an error page.** This is unlikely for a direct asset URL but not impossible -- some CDNs/proxies return 200 with an HTML error body. `curl --fail` only catches HTTP 4xx/5xx responses. A 200 with garbage content would still pass.

2. **Does not solve the root cause.** Even with `--fail`, the download still fails on Windows because there IS no Windows binary. The user gets a better error message ("Auto-download failed") instead of a silently corrupt binary, but they are still stuck with no forgejo-mcp. The fallback path (manual download) tells them to go to the releases page, where... there is no Windows binary. Dead end.

3. **Intermittent failures.** Network glitches would cause `curl --fail` to fail on legitimate downloads too. No retry logic exists.

### Fix C: File size validation (valid binary ~4 MiB)

**Positive:** Catches the specific scenario where a 404 error page (few KB) is saved as an executable.

**Failure modes:**

1. **Threshold selection is fragile.** A "minimum 1 MiB" threshold catches error pages but what if upstream releases a stripped/compressed binary at 900 KB? Future versions could be larger or smaller. UPX-compressed Go binaries can be well under 4 MiB.

2. **Threshold becomes stale.** The threshold is baked into skill markdown. When the binary grows from 4 MiB to 20 MiB (or shrinks to 2 MiB), nobody will update the threshold. It becomes a latent bug.

3. **Does not detect all corruption.** A half-downloaded binary (network cut during transfer) could be 2 MiB -- above the threshold but still corrupt. A truncated binary passes the size check but crashes on execution.

4. **Platform-dependent sizes.** The Linux, macOS, and Windows binaries will have different sizes. A single threshold is a crude heuristic.

5. **The existing `test -s` check (line 179 of SKILL.md) already checks non-empty.** The current verify step uses `test -s` which confirms the file is non-empty. A 404 error page IS non-empty (it is a few KB of HTML). So `test -s` passes. A size threshold improves on this, but not by much.

### Fix D: Update only 2 doc files

**Failure modes:**

1. **Incomplete coverage.** The research found 23 files referencing `forgejo-mcp`. Of these, the active (non-archival) files that matter are:
   - `skills/init/SKILL.md` -- THE primary file containing download logic (lines 152-192)
   - `docs/guides/mcp-configuration.md` -- manual install instructions
   - `docs/guides/installation.md` -- platform notes
   - `docs/guides/cross-platform.md` -- Windows/Linux/macOS checklist
   - `docs/guides/tokens.md` -- MCP server table
   - `docs/reference/trackers.md` -- MCP Server Detection table
   - `core/mcp-detection.md` -- MCP detection logic
   - `examples/mcp-configs/gitea.json` -- config template

   If the fix changes the installation method (from curl download to `go install`), then `skills/init/SKILL.md` is the PRIMARY file that needs changing (Step 5, lines 152-192). Updating "only 2 doc files" misses the actual skill definition where the download logic lives.

2. **`examples/mcp-configs/gitea.json` still uses `<path-to-binary>/forgejo-mcp`.** If `go install` puts the binary in a different location, the example template becomes misleading.

---

## 2. Recommended Approach

The right fix is a **layered defense** strategy. No single fix is sufficient.

### Layer 1: Primary -- `go install` with prerequisite checks (SKILL.md Step 5)

Modify `skills/init/SKILL.md` Step 5 to use a **tiered installation strategy**:

```
1. Check: Is `go` available? (`which go` / `where go`)
   - Yes: Check Go version >= minimum (parse `go version` output)
     - Adequate: Run `GOBIN=~/.claude/bin go install codeberg.org/goern/forgejo-mcp/v2@latest`
     - Too old: Display warning with required version, fall through to tier 2
   - No: Fall through to tier 2

2. Attempt curl download with --fail flag:
   curl --fail -sL -o ~/.claude/bin/{binary_name} "{url}"
   (This works on Linux and macOS where binaries ARE published)

3. If both fail: Manual path collection (existing fallback)
```

This keeps backward compatibility for Linux/macOS (where curl download works) while adding Go as the preferred method on all platforms. Windows users with Go get a working binary. Windows users without Go get the `--fail` error immediately instead of a silent corruption, then fall to manual fallback.

### Layer 2: Download validation (regardless of method)

After any download or `go install`, validate the result:

```
1. File exists: test -f {path}
2. File non-empty: test -s {path}
3. Minimum size: stat -c%s (Linux) / stat -f%z (macOS) / wc -c (portable)
   Threshold: 1 MiB (1048576 bytes) -- catches error pages and truncated downloads
4. Binary smoke test: run `{binary_name} --version` or `{binary_name} --help`
   - If exit code 0: binary is functional
   - If exit code non-zero or hangs: binary is corrupt or incompatible
```

The smoke test (item 4) is the most reliable validation. A corrupt file, wrong-architecture binary, or HTML error page will all fail to execute. This catches every corruption scenario that size checks miss.

### Layer 3: `curl --fail` as belt-and-suspenders

Add `--fail` to the curl command regardless. It is zero-cost and prevents the most obvious failure mode. Also add `--fail-early` or at minimum `-f` to catch HTTP errors.

### Layer 4: Documentation updates (complete list)

All active files that reference forgejo-mcp installation must be updated:

| File | What changes |
|------|-------------|
| `skills/init/SKILL.md` | Step 5: add Go install tier, add `--fail`, add smoke test |
| `docs/guides/mcp-configuration.md` | Add `go install` as primary method, curl as alternative |
| `docs/guides/installation.md` | Platform notes: add Go prerequisite, update Windows instructions |
| `docs/guides/cross-platform.md` | Update Windows checklist item |
| `examples/mcp-configs/gitea.json` | Update path comment to reflect `go install` default location |

Files that do NOT need updating: `docs/reference/trackers.md` (package name stays `forgejo-mcp`), `core/mcp-detection.md` (detection logic unchanged), `docs/guides/tokens.md` (env vars unchanged), archival `docs/plans/` files.

---

## 3. What MUST Be Tested

### Critical tests (block the release if failing)

1. **Windows with Go installed:** Run `/ceos-agents:init` with tracker type `gitea`. Verify `go install` is attempted, binary lands at `~/.claude/bin/forgejo-mcp.exe`, binary is functional (responds to `--help` or `--version`).

2. **Windows without Go:** Run `/ceos-agents:init` with tracker type `gitea`. Verify the skill detects Go is missing, attempts curl, curl fails with `--fail` (no Windows binary on Codeberg), falls through to manual path collection with a clear message. Verify NO corrupt file is left at `~/.claude/bin/forgejo-mcp.exe`.

3. **Linux with Go installed:** Verify `go install` path works. Also verify curl download still works as fallback (Linux binaries DO exist on Codeberg).

4. **Linux without Go:** Verify curl download works (the existing happy path must not regress).

5. **Corrupt binary detection:** Manually place a small HTML file at `~/.claude/bin/forgejo-mcp` and re-run init. Verify the smoke test detects it as invalid and re-downloads or asks for manual path.

6. **Already installed (no regression):** Verify that `test -f ~/.claude/bin/{binary_name}` still short-circuits correctly and does not re-download unnecessarily.

### Important tests (should test, non-blocking)

7. **Go version too old:** Mock `go version` returning 1.18. Verify the skill detects inadequate version and falls through.

8. **Network failure during `go install`:** Verify timeout or error is surfaced, not swallowed.

9. **`go install` with custom GOPATH/GOBIN:** Verify `GOBIN=~/.claude/bin` override works and does not pollute the user's Go environment.

10. **macOS ARM:** Verify the asset name mapping for `darwin-arm64` still works in the curl fallback tier.

### Edge case tests (nice to have)

11. **Corporate proxy:** Verify `go install` respects `GOPROXY` and `HTTP_PROXY` environment variables.

12. **Existing .mcp.json with old path:** Verify `--update` mode correctly updates the binary path if the installation location changed from a manual download to `go install` default.

13. **`go install` produces binary with unexpected name:** Verify the skill checks for the expected binary name and handles mismatch.

---

## Summary of Skeptical Verdict

| Fix | Alone sufficient? | Risk if sole fix |
|-----|-------------------|-----------------|
| `go install` only | No | Excludes users without Go (MANY Windows users) |
| `curl --fail` only | No | Fails gracefully on Windows but provides no working path forward |
| File size check only | No | Heuristic, misses truncation, version-fragile |
| Doc updates only | No | Does not fix the actual download logic |
| **All four combined** | **Yes** | Layered defense covers all identified failure modes |

The most dangerous mistake would be implementing `go install` as the ONLY method without fallback. The second most dangerous would be updating docs without updating `skills/init/SKILL.md` -- the skill definition is where the actual download logic is specified.
