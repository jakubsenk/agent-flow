# Agent 3 Research: Step 10 TLS Treatment in check-setup

Source file: `skills/check-setup/SKILL.md`

---

## Q9: Step 10 (SC Connectivity Check) — Full Text and Analysis

### Exact Location

File: `skills/check-setup/SKILL.md`
Lines: **98–104**

### Complete Step 10 Text (lines 98–104)

```markdown
10. Verify source control connectivity: fetch metadata for the configured Remote (owner/repo) via MCP
    - Use MCP to fetch repository metadata for the Remote value from Automation Config
    - Success → [OK] "Source control — {owner/repo} reachable"
    - Auth error (401/403) → [FAIL] "Source control — authentication failed. Token needs repository:read scope (Gitea), repo scope (GitHub), or read_repository scope (GitLab)."
    - Not found (404) → [FAIL] "Source control — repository {owner/repo} not found. Verify Remote in Automation Config."
    - Tool not found (MCP server lacks repository metadata method) → [WARN] "Source control MCP: repository existence check not supported — skipping."
    - Timeout/unreachable → [FAIL] "Source control — MCP server not reachable. Verify server URL and token in .mcp.json."
```

### Current Error Handling for SC Connectivity Failures

Step 10 handles exactly **4 failure cases**:

| Error Case | Trigger | Message |
|------------|---------|---------|
| Auth error | 401/403 HTTP status | "Source control — authentication failed. Token needs repository:read scope (Gitea), repo scope (GitHub), or read_repository scope (GitLab)." |
| Not found | 404 HTTP status | "Source control — repository {owner/repo} not found. Verify Remote in Automation Config." |
| Tool not found | MCP server lacks repository metadata method | [WARN] "Source control MCP: repository existence check not supported — skipping." |
| Timeout/unreachable | Any timeout or general unreachability | "Source control — MCP server not reachable. Verify server URL and token in .mcp.json." |

### What Happens on Connection Failure

When SC connectivity fails:

1. **Auth error** → Single-line [FAIL] message about token scope. No further diagnostics.
2. **Not found** → Single-line [FAIL] message about verifying Remote config. No further diagnostics.
3. **Tool not found** → [WARN] (non-blocking). No further diagnostics.
4. **Timeout/unreachable** → Single-line [FAIL] message. No curl probe, no TLS classification, no NODE_OPTIONS hint.

**TLS errors are entirely unhandled.** If the MCP connection fails due to a TLS certificate issue (e.g., corporate CA, self-signed cert), the error falls into the generic "Timeout/unreachable" catch-all bucket and produces the message: `"Source control — MCP server not reachable. Verify server URL and token in .mcp.json."` — with no TLS guidance whatsoever.

---

## Q10: Side-by-Side Comparison of Step 9 vs Step 10

### Step 9 Full Text (lines 80–97) — Issue Tracker Connectivity

```markdown
9. Run the Bug query from Automation Config via MCP (limit 1 result):
   - Success → [OK] with the number of bugs found
   - On failure, classify the error in this order:
     1. **TLS error** (error contains any of: UNABLE_TO_VERIFY_LEAF_SIGNATURE, CERT_UNTRUSTED,
        SELF_SIGNED_CERT, self signed certificate, certificate verify failed, ERR_TLS_,
        DEPTH_ZERO_SELF_SIGNED_CERT, unable to get local issuer certificate):
        Run a curl probe to confirm network reachability:
        - Check `which curl` — if curl is not available, skip probe and emit:
          [FAIL] "Issue tracker — TLS error detected. Add NODE_OPTIONS: --use-system-ca to .mcp.json env block. (curl not available for confirmation probe)"
        - Run: `curl -s -o /dev/null -w "%{http_code}" --max-time 5 {Instance}`
        - curl exit 0 and HTTP code != 000 →
          [FAIL] "Issue tracker — server reachable but MCP connection failed (likely TLS) — add NODE_OPTIONS: --use-system-ca to the env block in .mcp.json"
        - curl exit non-zero or HTTP code 000 →
          [FAIL] "Issue tracker — connection failed (TLS or network). If using a private CA, try NODE_OPTIONS: --use-system-ca. If server is remote, verify URL."
     2. **Auth error** (error contains: 401, 403, unauthorized, forbidden, invalid token, authentication) →
        [FAIL] "Issue tracker — authentication failed — check your token in .mcp.json"
     3. **Any other error** →
        [FAIL] "Issue tracker — server not reachable — verify the server is running and URL is correct. If using a private CA (self-signed or corporate PKI), also try NODE_OPTIONS: --use-system-ca."
```

### Step 10 Full Text (lines 98–104) — SC Connectivity

```markdown
10. Verify source control connectivity: fetch metadata for the configured Remote (owner/repo) via MCP
    - Use MCP to fetch repository metadata for the Remote value from Automation Config
    - Success → [OK] "Source control — {owner/repo} reachable"
    - Auth error (401/403) → [FAIL] "Source control — authentication failed. Token needs repository:read scope (Gitea), repo scope (GitHub), or read_repository scope (GitLab)."
    - Not found (404) → [FAIL] "Source control — repository {owner/repo} not found. Verify Remote in Automation Config."
    - Tool not found (MCP server lacks repository metadata method) → [WARN] "Source control MCP: repository existence check not supported — skipping."
    - Timeout/unreachable → [FAIL] "Source control — MCP server not reachable. Verify server URL and token in .mcp.json."
```

### Side-by-Side Feature Comparison

| Feature | Step 9 (Issue Tracker) | Step 10 (Source Control) |
|---------|----------------------|------------------------|
| TLS error classification | YES — checks for 8 specific TLS error strings | NO — no TLS detection at all |
| curl availability probe (`which curl`) | YES | NO |
| curl network reachability probe | YES — `curl -s -o /dev/null -w "%{http_code}" --max-time 5 {Instance}` | NO |
| Differentiated curl result (reachable vs not) | YES — two separate [FAIL] messages based on curl exit code | NO |
| NODE_OPTIONS hint in TLS branch | YES — explicit `--use-system-ca` instruction | NO |
| NODE_OPTIONS hint in generic error fallback | YES — "also try NODE_OPTIONS: --use-system-ca" | NO |
| Auth error handling | YES (generic: 401, 403, unauthorized, forbidden, invalid token, authentication) | YES (specific 401/403, includes scope names per platform) |
| Not found (404) handling | NO explicit 404 case | YES |
| Tool not found handling | NO | YES ([WARN]) |
| Error classification order | Ordered: TLS first → Auth → catch-all | Flat list (no priority order) |
| Catch-all message includes TLS hint | YES | NO |

### Gap Analysis: TLS Patterns from Step 9 MISSING in Step 10

#### Gap 1: No TLS Error Detection

Step 9 checks for 8 specific TLS-related error strings before any other classification:
- `UNABLE_TO_VERIFY_LEAF_SIGNATURE`
- `CERT_UNTRUSTED`
- `SELF_SIGNED_CERT`
- `self signed certificate`
- `certificate verify failed`
- `ERR_TLS_`
- `DEPTH_ZERO_SELF_SIGNED_CERT`
- `unable to get local issuer certificate`

Step 10 has **zero** TLS string matching. Any TLS error silently falls into "Timeout/unreachable."

#### Gap 2: No curl Availability Check

Step 9 runs `which curl` before attempting the network probe, and gracefully handles the case where curl is not available with a specific [FAIL] message that still includes the NODE_OPTIONS hint.

Step 10 has no curl check at all.

#### Gap 3: No curl Network Reachability Probe

Step 9 runs:
```bash
curl -s -o /dev/null -w "%{http_code}" --max-time 5 {Instance}
```
to distinguish between "TLS handshake fails but server is reachable" and "server is completely unreachable." This enables two actionable, differentiated messages.

Step 10 has no such probe. The `Remote` value (owner/repo) would need to be resolved to a base URL (e.g., `https://github.com`, `https://gitea.example.com`) for this probe to be applicable — but the logic doesn't exist.

#### Gap 4: No NODE_OPTIONS Hint

Step 9 provides the `NODE_OPTIONS: --use-system-ca` fix in **three** places:
1. curl-not-available TLS branch
2. curl-reachable TLS branch
3. The generic catch-all error (as "also try")

Step 10 provides the `NODE_OPTIONS` hint in **zero** places. A user hitting a TLS failure on SC connectivity gets only: `"Source control — MCP server not reachable. Verify server URL and token in .mcp.json."` — which is actively misleading (the token is fine; the TLS cert is the problem).

#### Gap 5: No TLS Hint in Catch-All

Even Step 9's generic fallback (`Any other error`) includes: `"If using a private CA (self-signed or corporate PKI), also try NODE_OPTIONS: --use-system-ca."` — serving as a safety net for TLS errors that don't match the known strings.

Step 10's catch-all (`Timeout/unreachable`) contains no such safety net.

### Summary of What Needs to Be Added to Step 10

To achieve parity with Step 9, Step 10 needs:

1. **TLS error classification** — add the same 8-string TLS detection check as the first branch in the failure handling
2. **curl probe logic** — same `which curl` check + `curl -s -o /dev/null -w "%{http_code}" --max-time 5 {base_url}` probe (where `{base_url}` is derived from the Remote/Instance, e.g., `https://gitea.example.com`)
3. **Differentiated TLS messages** — two messages based on curl result (server reachable vs unreachable), both including `NODE_OPTIONS: --use-system-ca`
4. **NODE_OPTIONS hint in catch-all** — add TLS/private CA hint to the generic "Timeout/unreachable" branch

The auth error handling in Step 10 is actually *better* than Step 9's (it names the required scope per platform: repository:read, repo, read_repository), so that does not need to change. The 404/not-found and tool-not-found cases are SC-specific and correct as-is.
