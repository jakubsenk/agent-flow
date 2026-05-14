# MCP Server Versions

Reference page tracking the recommended MCP server source for each tracker type supported by agent-flow, plus version pins, audit cadence, and known deprecation deadlines.

**Last verified:** 2026-05-09
**Next scheduled audit:** 2026-08-09 (90-day quarterly cadence)
**Hard deadline:** 2026-06-30 — Atlassian `/sse` endpoint EOL (must verify migration to `/mcp` complete before this date)

---

## Per-tracker status table

| Tracker | Source | Status | Endpoint / Package | Auth | Cloud/On-Prem | MCP protocol | Last verified | Next audit |
|---------|--------|--------|---------------------|------|---------------|--------------|---------------|------------|
| **github** | GitHub Inc. | **OFFICIAL** | `https://api.githubcopilot.com/mcp/` | Bearer PAT | Cloud (GitHub.com) | 2025-06-18 | 2026-05-09 | 2026-08-09 |
| **gitea** | Gitea Inc. | **OFFICIAL** | `gitea/gitea-mcp` v1.1.0 binary | env (host+token) | Cloud + On-Prem | 2025-06-18 | 2026-05-09 | 2026-08-09 |
| **jira** | Atlassian Inc. | **OFFICIAL** | `https://mcp.atlassian.com/v1/mcp` (Atlassian Rovo MCP Server) | OAuth 2.1 / API token | Cloud only | 2025-06-18 | 2026-05-09 | 2026-06-30 (SSE EOL) / 2026-08-09 (regular) |
| **linear** | Linear Inc. | **OFFICIAL** | `https://mcp.linear.app/mcp` | OAuth 2.1 / Bearer | Cloud only (SaaS) | 2025-06-18 | 2026-05-09 | 2026-08-09 |
| **youtrack** | JetBrains | **OFFICIAL** | `https://{instance}.youtrack.cloud/mcp` | Bearer token | Cloud + On-Prem 2026.1+ | 2025-06-18 | 2026-05-09 | 2026-08-09 |
| **redmine** | runekaagaard | COMMUNITY | `runekaagaard/mcp-redmine==2026.01.13.152335` via uvx | env (url+key) | On-Prem (no Cloud Redmine exists) | 2025-06-18 | 2026-05-09 | 2026-08-09 (community pin: re-evaluate alternatives) |
| **codegraph** | (user-internal) | N/A | (user-provided URL) | Bearer | (user-provided) | 2025-06-18 | 2026-05-09 | n/a (user-managed) |

## Status definitions

- **OFFICIAL** — vendor-published and vendor-maintained. Vendor accountable for uptime, security, and protocol updates. Lowest operational risk.
- **COMMUNITY** — third-party maintained. Plugin recommends best-available option but cannot guarantee continued maintenance. Pin to specific version.
- **N/A** — user-provided MCP server (e.g., custom internal). Plugin only specifies config schema, not server identity.

---

## Fallback options for on-prem deployments

Some vendor-official endpoints support only Cloud. For on-prem deployments, the following community fallbacks are documented in `skills/setup-mcp/SKILL.md` Step 3 prose:

| Tracker | Cloud (official) | On-prem fallback |
|---------|------------------|------------------|
| github | `https://api.githubcopilot.com/mcp/` | `github/github-mcp-server` Go binary download from GitHub releases (alternative for non-Copilot PAT users) |
| jira | `https://mcp.atlassian.com/v1/mcp` | NOT SHIPPED. If Jira Server / Data Center support is needed, file an issue — `sooperset/mcp-atlassian` (5,133 stars, MIT, Python+uvx) is the candidate. |
| youtrack | `https://{instance}.youtrack.cloud/mcp` | `npx -y @vitalyostanin/youtrack-mcp@latest` for YouTrack Server <2026.1 |
| linear | `https://mcp.linear.app/mcp` | N/A (Linear is cloud-only SaaS; no on-prem version exists) |
| atlassian-confluence-compass | (covered by official Atlassian endpoint) | (same as jira) |

---

## Audit cadence

### Quarterly schedule (90-day intervals)

| Audit # | Due date | Scope |
|---------|----------|-------|
| Q1 (initial) | 2026-05-09 | Initial vendor-official migration (this release) |
| Q2 | 2026-08-09 | Re-verify all 5 vendor-official endpoints + Redmine pin; check for new official MCP servers (Bitbucket, GitLab, etc.) |
| Q3 | 2026-11-09 | Same as Q2 + MCP protocol version status check |
| Q4 | 2027-02-09 | Same as Q3 + annual review of community deps (renumber if better options emerge) |

### Hard deadlines

- **2026-06-30 — Atlassian `/sse` EOL.** Atlassian official MCP server's `/sse` endpoint is deprecated and will be removed on this date. Plugin already uses `/mcp` (Streamable HTTP); no action needed unless any user has manually configured `/sse` in their `.mcp.json` (CHANGELOG migration note flags this).

### What "audit" means

A 60-second smoke test executed at each cadence checkpoint:

```bash
# 5 critical probes — exit 0 if all CONFIRMED LIVE
curl -sSI -m 10 https://api.githubcopilot.com/mcp/      # expect HTTP 401 (live, requires auth)
curl -sSI -m 10 https://mcp.atlassian.com/v1/mcp        # expect HTTP 401 (live, requires auth)
curl -sSI -m 10 https://mcp.linear.app/mcp              # expect HTTP 401 (live, requires auth)
curl -sS  -m 10 https://gitea.com/api/v1/repos/gitea/gitea-mcp/releases/latest | head -c 100  # expect JSON with tag_name
curl -sS  -m 10 https://api.github.com/repos/runekaagaard/mcp-redmine/commits?per_page=1 | head -c 100  # expect JSON with sha
```

If any probe fails OR returns unexpected output, file an issue and trigger a forge replanning cycle to update templates before the next plugin release.

### Triggering an unscheduled audit

Audit out-of-cadence if:
- A vendor announces deprecation of an endpoint (e.g., Atlassian's `/sse` deprecation)
- A community package is reported broken in the wild (file/triage issue)
- A new vendor-official MCP server becomes available for a tracker we currently use community for (Redmine)
- MCP protocol version major bump requires SDK upgrades

---

## MCP protocol version notes

Current MCP specification version: `2025-06-18` (Streamable HTTP transport; `/sse` deprecated).

All 5 vendor-official endpoints (`api.githubcopilot.com/mcp/`, `mcp.atlassian.com/v1/mcp`, `mcp.linear.app/mcp`, `<INSTANCE>.youtrack.cloud/mcp`) reference this spec version. Claude Code natively supports Streamable HTTP transport via `--transport http` flag and `"type": "http"` JSON config.

**Forward-looking risk:** A future MCP protocol version bump (e.g., 2026-Q4 release) may require server-side SDK upgrades. Vendors typically maintain backward compatibility for 1+ release cycles, but quarterly audits should monitor for compatibility warnings.

---

## Atlassian SSE deprecation tracking

Atlassian's MCP server originally exposed both `/sse` and `/mcp` endpoints. As of 2026-04-XX (per Atlassian docs), `/sse` is deprecated with EOL on **2026-06-30**.

agent-flow ships templates using `/mcp` (Streamable HTTP). Users who previously configured `.mcp.json` against `/sse` must migrate to `/mcp`. CHANGELOG entry contains migration callout.

---

## Known limitations (acknowledged for future releases)

These are deliberate scope exclusions, tracked here to avoid loss:

1. **uvx hash verification** — `uvx --from mcp-redmine==2026.01.13.152335 mcp-redmine` pins to the version string but does not pin to a SHA256 hash of the package contents. PyPI is generally trusted, but a sophisticated supply-chain attack on PyPI could substitute a malicious package at the same version. Adding hash-pinning support requires choosing a hash mechanism (PEP 458, sigstore, or `pip --require-hashes`) and updating the install pattern. Tracked for future research.

2. **Automated cadence enforcement** — The 90-day audit cadence is documented (above) but not enforced by CI. If the 2026-08-09 next-audit date passes without action, no signal fires. Possible mechanisms: (a) GitHub Action that fails the build if `mcp-server-versions.md`'s "Last verified" field is older than 90 days; (b) scheduled runner that opens an issue. Tracked for future implementation.

3. **MCP protocol auto-detection** — Currently each tracker entry hardcodes `2025-06-18` as the supported protocol. A future enhancement could probe each endpoint's MCP `initialize` handshake to discover actual protocol version, surfacing drift. Tracked for future work if drift becomes operational concern.

These items are not currently shipped because each requires either new infrastructure (CI workflows) or upstream research (hash mechanism choice). They are surfaced here to ensure they are not forgotten.

---

## Change log for this page

- **2026-05-09:** Initial creation. 5 vendor-official endpoints documented + 1 community Redmine pin + codegraph (user-internal). Audit cadence established with per-row Next-Audit dates. Known limitations section added covering uvx hash verification, automated cadence enforcement, and MCP protocol auto-detection (all deferred to future releases).
