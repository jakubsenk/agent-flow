# Agent 3: forgejo-mcp Windows Support Research

## Question
Does forgejo-mcp (goern/forgejo-mcp) support Windows? Can `go install` be used as a cross-platform alternative? Are there forks with Windows binaries?

---

## Finding 1: goern/forgejo-mcp does NOT provide Windows binaries

The canonical upstream repo at `codeberg.org/goern/forgejo-mcp` explicitly excludes Windows from its `.goreleaser.yml`:

- `goos` targets: `linux`, `darwin` only
- Every release (13 total as of v2.17.0) ships only:
  - `forgejo-mcp_X.Y.Z_linux_amd64.tar.gz`
  - `forgejo-mcp_X.Y.Z_linux_arm64.tar.gz`
  - `forgejo-mcp_X.Y.Z_darwin_amd64.tar.gz`
  - `forgejo-mcp_X.Y.Z_darwin_arm64.tar.gz`
- No `.exe` or Windows ZIP artifacts exist in any release.

Source: https://codeberg.org/goern/forgejo-mcp/releases

---

## Finding 2: `go install codeberg.org/goern/forgejo-mcp@latest` does NOT work

`go install pkg@version` fails when a module uses `replace` directives in `go.mod`. The goern/forgejo-mcp project historically used a replace directive for a forked Forgejo SDK (`codeberg.org/mvdkleijn/forgejo-sdk`), which broke remote `go install` (tracked as issue #67 in the project).

**Current state (v2.17.0):** The go.mod no longer contains a replace directive — it now uses `codeberg.org/mvdkleijn/forgejo-sdk/forgejo/v3 v3.0.0` directly. This means `go install codeberg.org/goern/forgejo-mcp/v2@latest` *may* now work for users with Go installed. However:

- The project itself recommends a clone-and-build workflow, not `go install`
- This approach requires Go toolchain to be present on the Windows machine
- No documentation confirms Windows build compatibility has been tested

**Verdict: `go install` is unreliable as a cross-platform solution** — it requires Go to be installed, is undocumented for Windows, and historical replace-directive issues may recur.

---

## Finding 3: Alternative forks with Windows binaries

### raohwork/forgejo-mcp (RECOMMENDED for Windows)
- GitHub: https://github.com/raohwork/forgejo-mcp
- Latest release: v0.0.7 (October 2025)
- **Provides Windows binaries:**
  - `forgejo-mcp.amd64.exe` (13.8 MB)
  - `forgejo-mcp.arm64.exe` (12.9 MB)
- Also covers macOS (amd64/arm64) and Linux (amd64)
- SHA1 checksums provided for all artifacts
- Supports stdio (local) and HTTP/SSE (remote) modes
- **Caveat:** Less mature than goern upstream; v0.0.7 implies early-stage project

### Kunde21/forgejo-mcp
- GitHub: https://github.com/Kunde21/forgejo-mcp
- Uses official MCP SDK; supports `go install github.com/Kunde21/forgejo-mcp@latest`
- No pre-built Windows binaries documented
- `go install` works because it avoids the replace-directive problem
- Written in Go, so cross-platform compilation works

### mattdm/forgejo-mcp (Codeberg fork)
- No evidence of Windows-specific work; general maintenance fork

---

## Summary Table

| Option | Windows Binary | `go install` | Notes |
|---|---|---|---|
| goern/forgejo-mcp (upstream) | No | Possibly (no replace now) | Untested on Windows; no docs |
| raohwork/forgejo-mcp | **Yes (.exe)** | Unknown | v0.0.7, early-stage |
| Kunde21/forgejo-mcp | No pre-built | **Yes** | Requires Go toolchain |
| Build from source (any) | DIY | N/A | Requires Go on Windows |

---

## Recommendation for ceos-agents

For Windows support in ceos-agents:

1. **Primary:** `raohwork/forgejo-mcp` Windows binary download — zero-dependency, works without Go installed. Pin to a specific release for reproducibility.
2. **Alternative:** `go install github.com/Kunde21/forgejo-mcp@latest` — cross-platform, but requires Go toolchain.
3. **Avoid:** Directing users to `goern/forgejo-mcp` on Windows without a workaround — no binaries, uncertain `go install` behavior, no Windows docs.

The install guide for ceos-agents should detect the OS and branch: Linux/macOS → goern upstream binary; Windows → raohwork binary or Kunde21 via `go install`.

---

## Sources
- https://codeberg.org/goern/forgejo-mcp/releases
- https://raw.githubusercontent.com/goern/forgejo-mcp/main/.goreleaser.yml
- https://github.com/golang/go/issues/44840 (replace directive blocks go install)
- https://github.com/raohwork/forgejo-mcp/releases
- https://github.com/Kunde21/forgejo-mcp
- https://codeberg.org/mattdm/forgejo-mcp
