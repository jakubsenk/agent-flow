# Agent 3: raohwork/forgejo-mcp Fork Evaluation

## Repository
https://github.com/raohwork/forgejo-mcp

## 1. Windows Binaries

Yes — every release since v0.0.1 (August 2025) includes Windows binaries:
- `forgejo-mcp.amd64.exe` (~13.8 MB)
- `forgejo-mcp.arm64.exe` (~12.9 MB)

SHA1 checksum files are provided alongside each `.exe`. Latest release: **v0.0.7** (October 28, 2025).

Releases page: https://github.com/raohwork/forgejo-mcp/releases

## 2. Fork Compatibility (vs. goern/forgejo-mcp)

**Not a fork of goern/forgejo-mcp.** This is an independent project.

| Property | raohwork/forgejo-mcp | goern/forgejo-mcp |
|---|---|---|
| License | MPL-2.0 | MIT |
| Stars | 47 | 43 |
| Language | Go | Go |
| Fork source | Independent | Independent |
| README mentions other | No | No |

The two projects appear to be parallel, independent MCP server implementations for Forgejo/Gitea. There is no declared upstream relationship. API surface (tools exposed) is similar in purpose (issues, PRs, releases, wiki) but not guaranteed identical — raohwork adds HTTP/SSE multi-user mode and project logo; goern focuses on stdio/SSE.

## 3. Activity Level

| Release | Date |
|---|---|
| v0.0.1 | August 5, 2025 |
| v0.0.3 | August 7, 2025 |
| v0.0.4 | August 12, 2025 |
| v0.0.5 | August 14, 2025 |
| v0.0.6 | September 12, 2025 |
| v0.0.7 | October 28, 2025 |

6 releases across ~3 months. 71 commits total on master. Activity level: **active but slowing** — last release was October 2025, no releases in the ~5 months since (as of April 2026).

## 4. Environment Variables

raohwork uses **different env var names** than goern:

| Variable | raohwork/forgejo-mcp | goern/forgejo-mcp |
|---|---|---|
| Instance URL | `FORGEJOMCP_SERVER` | `FORGEJO_URL` |
| Token | `FORGEJOMCP_TOKEN` | `FORGEJO_ACCESS_TOKEN` |

CLI flags are `--server` and `--token` (raohwork) vs `--url` and `--token` (goern).

**This is a breaking difference** — ceos-agents config templates that document `FORGEJO_URL`/`FORGEJO_TOKEN` (or `FORGEJO_ACCESS_TOKEN`) would need different instructions for raohwork.

## Summary / Recommendation

raohwork/forgejo-mcp is a viable Windows fallback in that it:
- Reliably publishes Windows `.exe` binaries (both amd64 and arm64)
- Has been actively maintained through late 2025
- Supports stdio mode (required for MCP integration)

However:
- **Env vars are different** (`FORGEJOMCP_SERVER` / `FORGEJOMCP_TOKEN`) — requires separate documentation or detection logic
- It is **not a fork of goern** — it is an independent reimplementation; tool names/capabilities may differ
- Activity has slowed since October 2025; long-term maintenance is uncertain

If ceos-agents wants a Windows path with minimal config divergence, goern/forgejo-mcp building from source (via `go install`) or a Docker-based approach may be cleaner. If a drop-in Windows binary is the hard requirement, raohwork is currently the only option with pre-built `.exe` releases.
