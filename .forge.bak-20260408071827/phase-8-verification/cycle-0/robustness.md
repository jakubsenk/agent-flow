# Phase 8 Robustness Review — Devil's Advocate

**Reviewer role:** Devil's Advocate  
**Cycle:** 0  
**Files reviewed:**
- `skills/init/SKILL.md` lines 160–210 (Auto-download section)
- `docs/guides/mcp-configuration.md` (Gitea section)
- `docs/guides/installation.md` (Windows section)

---

## Scenario 1: curl succeeds but file is corrupt or wrong architecture

### Description
Step 4 uses `curl -sfL` with the `-f` (`--fail`) flag. This correctly rejects HTTP error responses (4xx/5xx) by exiting non-zero. However, `-f` only guards against HTTP-level failures. It does not protect against:
- A valid 200 response that delivers a partial body (network interruption mid-stream)
- A redirect chain ending in a CDN-served file that is corrupted at rest
- A platform asset name collision (e.g., `forgejo-mcp-windows-amd64.exe` resolving to a Linux ELF binary due to an upstream packaging mistake)

Step 5 adds a size guard: anything under 100 KB is rejected. Valid binaries are ~4 MiB, so this threshold has a comfortable margin.

### Assessment
| Dimension | Rating |
|-----------|--------|
| Likelihood | Low — partial transfers are rare with modern TLS; upstream packaging mistakes are very rare |
| Impact | Medium — binary lands in `~/.claude/bin/` but fails silently at runtime when Claude Code tries to spawn the MCP server; no error is surfaced until the user runs `/ceos-agents:check-setup` |
| Covered by fix? | Partially — the 100 KB size guard catches truncated/error-page downloads, but NOT a plausibly-sized wrong-arch binary (e.g., a Linux ELF that is ~4 MiB would pass the size check on Windows) |

### Gap
There is no executable integrity check. After download and `chmod +x`, no step attempts to run `~/.claude/bin/forgejo-mcp --version` or verify the ELF/PE magic bytes. A wrong-architecture binary (Linux ELF on Windows) is 4 MiB, passes the size gate, and only fails when Claude Code tries to spawn it.

On Windows this is mitigated by the `go install` fallback path: if the binary is unexecutable, the user would still need to diagnose the failure themselves. On Linux/macOS there is no fallback at all — the failure is invisible until MCP spawn time.

### Verdict
**Acceptable risk for now.** Adding a post-download smoke check (`./forgejo-mcp --version 2>&1`) would close this gap cleanly and is a 1-line addition to step 7. Not a blocker, but worth a MINOR follow-up.

---

## Scenario 2: `go install` succeeds but binary name differs from `forgejo-mcp.exe`

### Description
Step 8b runs:
```bash
GOBIN=~/.claude/bin go install codeberg.org/goern/forgejo-mcp/v2@latest
```
Then checks: `if ~/.claude/bin/forgejo-mcp.exe exists → success`.

Go derives the binary name from the **module path's last path segment**, specifically from the `main` package directory name inside the module. For `codeberg.org/goern/forgejo-mcp/v2`, Go strips the `/v2` major version suffix per module conventions, yielding a binary named `forgejo-mcp` (no `.exe` on GOPATH, but Git Bash on Windows does append `.exe` automatically in `GOBIN`).

However, if the upstream module author ever:
- Renames the `cmd/` subdirectory (e.g., to `cmd/forgejo-mcp-server`)
- Adds a `v3` with a renamed binary entrypoint
- Uses a non-standard `package main` directory name

…then `go install` succeeds with exit code 0, but the binary lands under a different name in `~/.claude/bin/`, and the existence check at step 8b fails silently. The skill then falls through to manual path collection without explaining that `go install` itself succeeded.

### Assessment
| Dimension | Rating |
|-----------|--------|
| Likelihood | Very low — upstream module renames are rare and would break all existing users |
| Impact | Medium — misleading UX: user sees "go install failed" messaging but the binary actually exists under a different name in `~/.claude/bin/` |
| Covered by fix? | No — the fix hard-codes the expected binary name `forgejo-mcp.exe` in the post-install check |

### Gap
The skill could do `ls ~/.claude/bin/forgejo-mcp* 2>/dev/null` after `go install` to report what was actually produced, rather than just checking for the exact expected name. This would surface a rename early with an actionable message.

### Verdict
**Acceptable risk.** The upstream module is stable; this is an edge case with very low probability. The current hard-coded name check is a pragmatic choice. No change required now; note in a future robustness ticket.

---

## Scenario 3: Codeberg API is down — tag fetch (step 3) fails silently

### Description
Step 3 fetches the latest release tag:
```bash
curl -sL https://codeberg.org/api/v1/repos/goern/forgejo-mcp/releases/latest \
  | grep -o '"tag_name":"[^"]*"' | head -1 | cut -d'"' -f4
```

The `-s` flag silences errors. The `-L` flag follows redirects. There is **no `-f` flag** on this curl call (unlike step 4). If the Codeberg API:
- Returns a 503 / 429 / 5xx error
- Returns an empty body
- Returns a non-JSON response (e.g., a Cloudflare captcha HTML page)

...then `grep | head | cut` produces an **empty string**. The skill receives an empty `{tag}` variable.

Step 4 then constructs a URL like:
```
https://codeberg.org/goern/forgejo-mcp/releases/download//forgejo-mcp-windows-amd64.exe
```
(double slash, empty tag segment). This URL returns a 404. With `-f`, curl exits non-zero, so the download is treated as failed. The size check at step 5 would catch the empty file. The flow eventually reaches manual path collection.

### Assessment
| Dimension | Rating |
|-----------|--------|
| Likelihood | Low-to-medium — Codeberg has had documented outages; rate limiting is possible during batch installs |
| Impact | Medium — user gets a non-obvious failure path (falls to manual path collection) without being told that the root cause was an API outage, not a missing binary |
| Covered by fix? | No — step 3 has no failure detection, no empty-string guard, and no user-facing message when tag fetch fails |

### Gap
This is a **silent degradation**. The user sees "Auto-download failed. Download forgejo-mcp manually from: ..." but gets no indication that the upstream API was unreachable. A simple guard would be:
```bash
TAG=$(curl -sL ... | grep -o ... | head -1 | cut -d'"' -f4)
if [ -z "$TAG" ]; then
  Display: "Could not fetch latest release tag from Codeberg API. Try again later or download manually."
  → fall back to manual path collection immediately
fi
```
Without this, the skill wastes one curl attempt (step 4) constructing an invalid URL before reaching the same fallback.

### Verdict
**Should be addressed.** This is the highest-probability failure scenario of the three and produces a misleading UX. Adding an empty-string guard after step 3 is a low-effort, high-value fix. Recommend adding to the current patch cycle rather than deferring.

---

## Summary

| Scenario | Likelihood | Impact | Covered? | Priority |
|----------|-----------|--------|----------|----------|
| 1. Corrupt / wrong-arch binary passes size guard | Low | Medium | Partial | MINOR follow-up |
| 2. `go install` succeeds but binary name differs | Very Low | Medium | No | Defer — acceptable risk |
| 3. Codeberg API down → tag fetch empty → silent degradation | Low-Medium | Medium | No | Fix now |

## Robustness Score

**0.72 / 1.0**

The fix makes a solid improvement: the `-f` flag on the download curl and the 100 KB size guard close the most common failure modes (HTTP error pages saved as binaries, Windows binary unavailability). The `go install` fallback adds meaningful resilience on Windows.

The score is capped at 0.72 primarily because Scenario 3 (tag fetch silent failure) is an unguarded code path that produces a confusing user experience, and Scenario 1 has a residual gap (wrong-arch binary that passes size threshold). Neither is catastrophic — both degrade to the manual path collection fallback — but the lack of actionable diagnostics lowers operator confidence.
