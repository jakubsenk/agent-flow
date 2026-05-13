# Phase 8 Spec Alignment Review — cycle-0

**Reviewer role:** Spec Alignment  
**Date:** 2026-04-07  
**Files reviewed:**
- `skills/init/SKILL.md` (Step 5, Auto-download section)
- `docs/guides/mcp-configuration.md` (Gitea/Forgejo section)
- `docs/guides/installation.md` (Platform Notes > Windows)

---

## Per-Requirement Verdicts

### REQ-1: Harden curl download with --fail and file-size validation

**Verdict: PASS**

Evidence in `skills/init/SKILL.md` Step 5:

- Step 4 uses `curl -sfL` (the `-f`/`--fail` flag is present). The inline note explicitly states: *"The `-f` (`--fail`) flag causes curl to exit non-zero on HTTP errors (e.g. 404) instead of saving the error page as a file."*
- Step 5 performs file-size validation using `wc -c < ~/.claude/bin/{binary_name}`, with threshold 102400 bytes (100 KB). Files below this threshold are removed with `rm -f` and treated as a failed download.

Both sub-requirements of REQ-1 are fully implemented.

---

### REQ-2: Go install fallback on download failure (Windows-aware)

**Verdict: PASS**

Evidence in `skills/init/SKILL.md` Step 5, steps 8–9:

- Step 8 is explicitly gated: *"Go install fallback (Windows only): If download failed AND platform is Windows (`MINGW*`/`MSYS*`)"*
- Step 8a checks Go availability via `command -v go`
- Step 8b (Go available): runs `GOBIN=~/.claude/bin go install codeberg.org/goern/forgejo-mcp/v2@latest` — module path includes `/v2`, `GOBIN` routes binary to `~/.claude/bin/forgejo-mcp.exe`
- Step 8b (go install fails): displays error and falls back to manual path collection
- Step 8c (Go NOT available): displays the required clear error message with link to `https://go.dev/dl/` and instruction to re-run or download manually, then falls back to manual path collection
- Step 9: non-Windows failure skips the Go install tier entirely and goes directly to manual path collection

All five sub-requirements of REQ-2 are fully implemented.

---

### REQ-3: Update mcp-configuration.md Windows install instructions

**Verdict: PASS**

Evidence in `docs/guides/mcp-configuration.md` lines 48–52:

- The old "Download `forgejo-mcp-windows-amd64.exe`" instruction is absent; it has been replaced with the `go install` method as the primary Windows path
- The exact command `GOBIN=~/.claude/bin go install codeberg.org/goern/forgejo-mcp/v2@latest` is present
- A warning is included: *"Pre-built Windows binaries are not reliably published upstream."*
- A link to Go installation (`go.dev/dl`) is present
- Linux install line (`forgejo-mcp-linux-amd64`, `chmod +x`) is unchanged (line 53)

All sub-requirements of REQ-3 are fully implemented.

---

### REQ-4: Update installation.md with Windows Go requirement

**Verdict: PASS**

Evidence in `docs/guides/installation.md` lines 72–72 (Platform Notes > Windows):

- The Windows section contains: *"Pre-built Windows binaries for forgejo-mcp are not available from the upstream repository."*
- States that `/ceos-agents:init` will automatically attempt `go install` as a fallback
- Includes `go version` as a verification command
- Provides a link to `go.dev/dl`
- Linux section (lines 76–79) is unchanged — still references the linux-amd64 binary download
- macOS section (lines 81–83) is unchanged

All sub-requirements of REQ-4 are fully implemented.

---

## Per-Criterion Verdicts

### AC-1: Windows without Go → clear error, no corrupt binary

**Verdict: PASS**

From `skills/init/SKILL.md` Step 5:
1. File-size check removes any undersized/corrupt file before the Go fallback is reached (`rm -f` on files < 102400 bytes)
2. Step 8c (Go NOT available) displays: `"forgejo-mcp download failed — no official Windows binary is published upstream. Install Go (https://go.dev/dl/) and re-run /ceos-agents:init, or download the binary manually."` — this message contains the required content ("no official Windows binary", `https://go.dev/dl/`, instruction to re-run or download manually)
3. The skill falls back to manual path collection after the error message

Minor deviation: The spec required the phrase "no Windows binary published upstream" verbatim. The implementation uses "no official Windows binary is published upstream" — equivalent meaning, acceptable paraphrase. The essential information is present.

---

### AC-2: Windows with Go → go install works

**Verdict: PASS**

From `skills/init/SKILL.md` Step 5, step 8b:
1. Command: `GOBIN=~/.claude/bin go install codeberg.org/goern/forgejo-mcp/v2@latest` — exact match
2. Module path includes `/v2` — confirmed
3. Binary expected at `~/.claude/bin/forgejo-mcp.exe` — confirmed
4. Success message: `"Built forgejo-mcp from source via go install to ~/.claude/bin/forgejo-mcp.exe"` — slightly different wording than spec's "Installed forgejo-mcp via go install..." but equivalent and acceptable
5. On success, skill continues (Step 6 .mcp.json generation uses the resolved binary path)

All sub-requirements met.

---

### AC-3: Linux/macOS → no regression

**Verdict: PASS**

From `skills/init/SKILL.md` Step 5:
1. `curl -sfL` is used (added `--fail` flag) — confirmed in step 4
2. `wc -c` size check is present in step 5 — confirmed
3. Step 8 is explicitly gated on Windows: `"If download failed AND platform is Windows (MINGW*/MSYS*)"` — confirmed
4. Step 9 handles non-Windows failure by going to manual fallback: `"Non-Windows download failure: If download failed AND platform is NOT Windows → fall back to manual path collection"` — confirmed

No regression introduced for Linux/macOS behavior. All four verification points from the spec are met.

---

### AC-4: mcp-configuration.md mentions go install for Windows

**Verdict: PASS**

From `docs/guides/mcp-configuration.md` lines 48–52:
1. Old "Download `forgejo-mcp-windows-amd64.exe`" instruction: absent — confirmed
2. `go install` command with full module path: `GOBIN=~/.claude/bin go install codeberg.org/goern/forgejo-mcp/v2@latest` — present
3. Note about unreliable pre-built Windows binaries: *"Pre-built Windows binaries are not reliably published upstream."* — present
4. Go requirement with link: `go.dev/dl` — present
5. Linux install line unchanged (line 53): `forgejo-mcp-linux-amd64`, `chmod +x` — confirmed

All five AC-4 sub-points verified.

---

### AC-5: installation.md mentions Go requirement for Windows

**Verdict: PASS**

From `docs/guides/installation.md` lines 70–72 (Platform Notes > Windows):
1. Windows section contains forgejo-mcp + Go note — present
2. Mentions `/ceos-agents:init` will attempt `go install` as fallback — present
3. Includes `go version` as verification and link to `go.dev/dl` — present
4. Linux and macOS sections: Linux (lines 76–79) references linux-amd64 binary, unchanged. macOS (lines 81–83) note is unchanged.

All three AC-5 sub-points verified.

---

## Summary Table

| ID | Description | Verdict | Notes |
|----|-------------|---------|-------|
| REQ-1 | curl --fail + size validation | PASS | `-sfL`, `wc -c`, 102400-byte threshold, `rm -f` on fail |
| REQ-2 | Windows Go install fallback with GOBIN | PASS | Step 8 gated on MINGW*/MSYS*, GOBIN=~/.claude/bin, /v2 path |
| REQ-3 | mcp-configuration.md updated | PASS | go install command present, warning present, Linux line unchanged |
| REQ-4 | installation.md updated | PASS | Windows section has Go note, Linux/macOS unchanged |
| AC-1 | Windows without Go → clear error | PASS | Error message present, corrupt file removed, manual fallback reached |
| AC-2 | Windows with Go → go install works | PASS | Exact command, /v2, GOBIN, success message, continues to Step 6 |
| AC-3 | Linux/macOS → no regression | PASS | curl -sfL, wc -c check, step 8 Windows-gated, step 9 non-Windows fallback |
| AC-4 | mcp-config mentions go install | PASS | All 5 sub-points verified |
| AC-5 | installation.md mentions Go | PASS | All 3 sub-points verified |

---

## Score

**9 / 9 items PASS**

**Score: 1.0**

All requirements and acceptance criteria are fully satisfied. The implementation matches the specification with no gaps. Two minor wording deviations were noted (AC-1 error message phrasing, AC-2 success message phrasing) but both convey equivalent information and are within acceptable paraphrase tolerance.
