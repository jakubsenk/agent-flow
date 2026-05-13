# Agent 2 — Innovative Brainstorm: Resilient Binary Acquisition Pattern

**Perspective:** Platform engineer focused on architectural durability and cross-platform reliability.

## Core Insight

The forgejo-mcp Windows failure is a symptom, not the disease. The real problem is that Step 5 of `/init` treats binary acquisition as a single happy-path curl command with a post-hoc existence check. This pattern is fragile for ANY platform — a release URL restructure, a CDN outage, or a new architecture (e.g., Windows ARM) will reproduce the exact same silent failure. The fix should establish a **tiered acquisition strategy** that gracefully degrades across methods and validates the artifact before accepting it.

## Proposed Architecture: Three-Tier Acquisition with Validation Gate

```
Tier 1: Direct download (curl --fail) + validation gate
  |-- fail --v
Tier 2: go install (if Go toolchain present) + validation gate
  |-- fail --v
Tier 3: Manual path collection (existing fallback) + validation gate
```

Every tier feeds its result through the same **validation gate** before the binary is accepted. This is the key architectural addition — validation is not per-tier, it is a shared checkpoint that guarantees a working binary regardless of how it was obtained.

## Concrete Changes

### File 1: `skills/init/SKILL.md` — Step 5 (forgejo-mcp section)

**Change 1a: Add `--fail` to curl (prevents saving error pages)**

Replace the download command in Step 5 substep 4:
```bash
# BEFORE
curl -sL -o ~/.claude/bin/{binary_name} "https://codeberg.org/goern/forgejo-mcp/releases/download/{tag}/{asset_name}"

# AFTER
curl -sfL -o ~/.claude/bin/{binary_name} "https://codeberg.org/goern/forgejo-mcp/releases/download/{tag}/{asset_name}"
```

The `-f` (short for `--fail`) flag makes curl return exit code 22 on HTTP 404/5xx instead of saving the error body. This is the minimal fix that prevents the silent corruption.

**Change 1b: Replace naive `test -f && test -s` validation with a validation gate**

Replace Step 5 substep 6 with a new **Validation gate** subsection that applies to ALL acquisition tiers:

```markdown
### Validation gate (applies after every acquisition tier)

After obtaining a candidate binary at `{candidate_path}`, run these checks IN ORDER. All must pass for the binary to be accepted:

1. **Existence:** `test -f "{candidate_path}"` — file exists
2. **Minimum size:** Verify file is larger than 1 MB (1048576 bytes). A valid forgejo-mcp binary is ~4 MiB; an error page or corrupt download is typically < 10 KB.
   ```bash
   file_size=$(wc -c < "{candidate_path}" | tr -d ' ')
   test "$file_size" -gt 1048576
   ```
   (`wc -c` is POSIX-portable across Linux, macOS, and Windows Git Bash — do NOT use `stat` which has incompatible flags across platforms.)
3. **Executable format** (optional, best-effort): On Linux/macOS, run `file "{candidate_path}"` and verify the output contains `ELF` (Linux) or `Mach-O` (macOS). On Windows, verify the first two bytes are `MZ` (PE header):
   ```bash
   head -c 2 "{candidate_path}" | od -A n -t x1 | tr -d ' ' | grep -qi "4d5a"
   ```
   If `file` or `od` is not available, skip this check (do not fail on missing tools).

If any check fails: delete the candidate (`rm -f "{candidate_path}"`), display which check failed, and fall through to the next acquisition tier.

If all checks pass: accept the binary. Display: `"Validated forgejo-mcp binary: {file_size_human} ({candidate_path})"`
```

**Change 1c: Add Tier 2 — Go install fallback**

Insert a new subsection between auto-download and manual path collection:

```markdown
### Tier 2: Go toolchain fallback (if Tier 1 fails)

If Tier 1 (direct download) fails or the validation gate rejects the downloaded file:

1. **Check Go availability:** `command -v go`
   - If Go is NOT available: display `"Direct download failed and Go toolchain not found. Falling back to manual setup."` → skip to Tier 3.
2. **Build from source:**
   ```bash
   go install codeberg.org/goern/forgejo-mcp/v2@latest
   ```
3. **Locate built binary:**
   ```bash
   go_bin="$(go env GOPATH)/bin/forgejo-mcp"
   # On Windows, the binary has .exe extension
   if [ ! -f "$go_bin" ] && [ -f "${go_bin}.exe" ]; then
     go_bin="${go_bin}.exe"
   fi
   ```
4. **Copy to standard location:** `cp "$go_bin" ~/.claude/bin/{binary_name}`
5. **Run validation gate** on `~/.claude/bin/{binary_name}`.
6. If validation passes: display `"Built forgejo-mcp from source via Go toolchain."`
7. If validation fails (unlikely — `go install` would have errored): fall through to Tier 3.
```

**Change 1d: Update the flow narrative**

Restructure the forgejo-mcp subsection of Step 5 into clearly labeled tiers:

```markdown
### For forgejo-mcp (Gitea/Forgejo tracker):

Detect platform via Bash:
... (existing platform detection — unchanged)

**Tier 1: Direct download (default):**
1. Check if already installed: `test -f ~/.claude/bin/{binary_name}` → run validation gate on existing file. If valid → reuse, skip download. If invalid → delete and re-download.
2. Create bin directory: `mkdir -p ~/.claude/bin`
3. Fetch latest release tag: (existing curl command — unchanged)
4. Download binary with `curl -sfL ...` (note the `-f` flag)
5. Set permissions (Linux/macOS only): `chmod +x ~/.claude/bin/{binary_name}`
6. **Run validation gate.** If fails → proceed to Tier 2.

**Tier 2: Go toolchain fallback:**
(as described in Change 1c above)

**Tier 3: Manual path collection (last resort):**
(existing manual fallback — unchanged, but also runs validation gate on user-provided path)
```

### File 2: `docs/guides/mcp-configuration.md` — Gitea/Forgejo section

Replace line 48 (`- **Windows install:** Download ...`) with:

```markdown
- **Windows install:** Official pre-built Windows binaries are **not available** from the upstream repository. Use one of these methods:
  - **Recommended:** If Go is installed, run `go install codeberg.org/goern/forgejo-mcp/v2@latest`. The binary will be at `%GOPATH%\bin\forgejo-mcp.exe` (or `$(go env GOPATH)/bin/forgejo-mcp.exe` in Git Bash).
  - **Automated:** `/ceos-agents:init` handles this automatically (downloads where available, falls back to `go install`).
```

### File 3: `docs/guides/installation.md` — Platform Notes > Windows section

Replace the current Windows section (lines 69-71) with:

```markdown
### Windows (primary)

The procedure described above is for Windows. Paths use `~/` notation (Git Bash / WSL).

**forgejo-mcp (for Gitea/Forgejo users):** The upstream project does not publish Windows binaries. `/ceos-agents:init` handles this automatically by falling back to `go install`. If you need to install manually, ensure Go is installed (`go version`) and run:

```bash
go install codeberg.org/goern/forgejo-mcp/v2@latest
```

The binary will be placed in `$(go env GOPATH)/bin/forgejo-mcp.exe`.
```

### File 4: `docs/guides/cross-platform.md` — Add forgejo-mcp acquisition note

Under `## Notes`, add:

```markdown
- **forgejo-mcp binary acquisition:** `/ceos-agents:init` uses a three-tier strategy: (1) direct download from Codeberg releases, (2) `go install` fallback if download fails or platform binary is unavailable, (3) manual path entry. All tiers validate the binary (existence, minimum size 1 MB, executable format) before accepting it.
```

## Future-Proofing Benefits

1. **New platforms handled automatically.** When Windows ARM or Linux ARM binaries start appearing in releases, Tier 1 picks them up via the existing `uname -m` detection. If they don't appear, Tier 2 (`go install`) builds natively for whatever architecture is running. No code change needed.

2. **Release URL changes are non-fatal.** If the Codeberg repo moves, renames tags, or changes asset naming conventions, Tier 1 fails cleanly (curl `--fail` + validation gate) and Tier 2 takes over. The user sees a build-from-source message, not a corrupt binary.

3. **Validation gate is reusable.** The same gate pattern (existence + size + format) can be applied to any future binary-based MCP server. If tomorrow a `jira-mcp` binary server appears, the pattern is already established.

4. **Existing binary re-validation.** Today's "already installed" check (`test -f`) is a simple existence check that would accept a previously-corrupted binary. The new pattern re-validates through the full gate, catching stale or corrupted cached binaries.

5. **`wc -c` portability.** By choosing `wc -c` over `stat` for size checking, we avoid the `stat --format` (GNU) vs `stat -f` (BSD/macOS) incompatibility. This is a subtle but important cross-platform correctness win.

## Tradeoffs

| Added Complexity | Reliability Gain |
|---|---|
| ~30 lines added to Step 5 in SKILL.md (validation gate + Tier 2) | Eliminates silent failure on Windows entirely |
| Go toolchain becomes a soft dependency for Windows+Gitea users | `go install` is deterministic and architecture-agnostic — works on any platform Go supports |
| Validation gate adds 3 checks per acquisition | Catches corrupt downloads, incomplete transfers, moved URLs — prevents hours of debugging |
| Three tiers increase the number of code paths in the skill | Each tier is independent and clearly labeled; failure just falls through to the next |

**What this does NOT add:**
- No runtime dependencies (no npm, no Python, no Docker)
- No new config keys in Automation Config (zero contract change = PATCH version)
- No changes to the agent definitions or core contracts
- No changes to the MCP detection logic (`core/mcp-detection.md`)

## Complexity Budget

The validation gate is ~15 lines of markdown instruction. The Go fallback tier is ~15 lines. The doc updates are ~10 lines across 3 files. Total delta: ~40 lines of instruction, 3 files changed. This is well within the budget for a PATCH-level fix and proportionate to the reliability improvement.

## Comparison with Minimal Fix

A minimal fix would be: add `--fail` to curl, done. That prevents saving 404 bodies but does NOT handle:
- Partial downloads (network interruption mid-transfer)
- Future URL changes (Tier 1 would fail with no fallback)
- Corrupted cached binaries (re-validation on reuse)
- Windows users with no Go (clear error message instead of silent failure)

The tiered approach costs ~25 lines more than the minimal fix and covers all four failure modes. The ROI is strongly positive given that this is a developer onboarding path — a failure here blocks the entire pipeline.

## Version Impact

**PATCH** (e.g., 6.4.1). No new config keys, no changed output contracts, no agent definition changes. The Automation Config contract is untouched. This is a behavior fix in the init skill's download logic.
