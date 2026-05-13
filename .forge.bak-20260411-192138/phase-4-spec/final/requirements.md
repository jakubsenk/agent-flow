# Requirements — check-setup SKILL.md Fixes

**Target file:** `skills/check-setup/SKILL.md`
**Source:** Phase 3 brainstorm synthesis (`.forge/phase-3-brainstorm/final.md`)
**Fixes:** 3 (TLS diagnostic, SC connectivity, path resolution)

---

## Fix 1: TLS Diagnostic Flow (Block 3, Step 9)

### Current Behavior

Lines 71-74 of `skills/check-setup/SKILL.md`:

```markdown
9. Run the Bug query from Automation Config via MCP (limit 1 result):
   - Success → [OK] with the number of bugs found
   - Auth error → [FAIL] "MCP server configured but authentication failed — check your token in .mcp.json"
   - Timeout/connection refused → [FAIL] "MCP server configured but not reachable — verify the server is running and URL is correct"
```

Step 9 classifies MCP failures into only two buckets: auth error and timeout/connection refused. TLS certificate errors (self-signed certificates, corporate PKI, private CA) are silently misclassified into the "timeout/connection refused" bucket. The user receives the misleading recommendation "verify the server is running and URL is correct" when the actual problem is a TLS handshake failure that can be fixed with `NODE_OPTIONS: --use-system-ca`.

### Required Behavior

Step 9 must classify MCP failures into three buckets, checked in this order:

1. **TLS error** — detected by pattern-matching the MCP error string against known TLS error codes. When matched, a curl probe confirms network reachability.
2. **Auth error** — detected by pattern-matching against HTTP auth error codes/strings.
3. **Unreachable** — fallback for all other connection failures. Includes a soft TLS hint for cases where proxies/gateways may obscure the underlying TLS error.

**TLS detection patterns** (case-insensitive match against MCP error output):
- `UNABLE_TO_VERIFY_LEAF_SIGNATURE`
- `CERT_UNTRUSTED`
- `SELF_SIGNED_CERT`
- `self signed certificate`
- `certificate verify failed`
- `ERR_TLS_`
- `DEPTH_ZERO_SELF_SIGNED_CERT`
- `unable to get local issuer certificate`

**Auth detection patterns:**
- `401`, `403`, `unauthorized`, `forbidden`, `invalid token`, `authentication`

**Curl probe** (runs only when a TLS pattern is matched):
- Guard: check `which curl` (or `where curl` on Windows). If curl is absent, skip probe and emit TLS hint unconditionally with advisory note.
- Command: `curl -s -o /dev/null -w "%{http_code}" --max-time 5 {Instance}`
- Three-tier output:
  1. curl exits 0 and HTTP code != `000` → server is network-reachable, TLS is confirmed problem → `[FAIL]` with `NODE_OPTIONS: --use-system-ca` recommendation
  2. curl exits non-zero AND TLS patterns were matched → ambiguous (curl may use different CA bundle than Node.js) → `[FAIL]` with combined TLS-or-network message, still includes `NODE_OPTIONS` hint
  3. curl not found → skip probe, emit TLS hint unconditionally since patterns were already matched → `[FAIL]` with `NODE_OPTIONS` recommendation and "(curl not available for confirmation probe)" note

**Soft TLS hint on generic unreachable:** When no TLS pattern AND no auth pattern matches, append to the unreachable message: "If using a private CA (self-signed or corporate PKI), also try NODE_OPTIONS: --use-system-ca."

### Acceptance Criteria

- **AC-1:** When MCP error contains any TLS pattern (e.g., `UNABLE_TO_VERIFY_LEAF_SIGNATURE`), the output message includes `NODE_OPTIONS: --use-system-ca` as the recommended fix.
- **AC-2:** When a TLS pattern is matched AND curl confirms reachability (exit 0, HTTP != 000), the message states the server is reachable and identifies TLS as the confirmed problem.
- **AC-3:** When a TLS pattern is matched AND curl fails or is absent, the message still includes the `NODE_OPTIONS: --use-system-ca` hint (never drops to a pure "not reachable" message).
- **AC-4:** When no TLS and no auth patterns match (generic unreachable), the message includes a soft TLS hint mentioning `NODE_OPTIONS: --use-system-ca` as a possibility.
- **AC-5:** TLS patterns are checked BEFORE auth patterns in the classification order.

---

## Fix 2: SC Connectivity — Targeted Repo Check (Block 3, Step 10)

### Current Behavior

Lines 75-77 of `skills/check-setup/SKILL.md`:

```markdown
10. Verify source control connectivity: list repositories via MCP
    - Success → [OK]
    - Failure → [FAIL] with specific error type (auth vs unreachable)
```

Step 10 instructs the agent to "list repositories via MCP", which implies:
- A user-level enumeration tool (e.g., `list_my_repositories`) that does not exist in Gitea's MCP server.
- A broad `read:user`-like scope that Gitea does not support.
- No verification that the specific configured repository is accessible — only that the token can enumerate repos.

### Required Behavior

Step 10 must:
1. Fetch metadata for the specific repository declared in `Source Control → Remote` (owner/repo format).
2. Use intent-based language ("fetch repository metadata") not a specific MCP tool name, since tool names vary by provider (Gitea vs GitHub vs GitLab).
3. Remove any implication of `read:user` scope. Reference `repository:read` scope for Gitea, `repo` for GitHub, `read_repository` for GitLab.
4. Handle four distinct error cases with specific messages:
   - **401/403 (auth failure):** Scope hint listing provider-specific scope names.
   - **404 (not found):** Suggest verifying Remote value in Automation Config.
   - **Tool not found (MCP server lacks repository-fetch method):** `[WARN]` not `[FAIL]` — degrade gracefully.
   - **Timeout/unreachable:** Network-level failure message.

### Acceptance Criteria

- **AC-6:** Step 10 instructs the agent to fetch metadata for the specific `Remote` repository (owner/repo), not to list all repositories.
- **AC-7:** Auth failure (401/403) message includes scope hint mentioning at minimum `repository:read` (Gitea-aware, but also generic enough for other providers).
- **AC-8:** 404 response produces a distinct message directing the user to verify the Remote value, not a generic auth error.
- **AC-9:** If the MCP server does not support a repository metadata tool, the result is `[WARN]` (graceful skip), not `[FAIL]`.

---

## Fix 3: Path Resolution for trackers.md (Steps 3a and 7)

### Current Behavior

**Line 32 (Step 3a):**
```markdown
Read `docs/reference/trackers.md`. Find the row matching the configured Type in the Validation Rules table.
```

**Lines 59-60 (Step 7):**
```markdown
   - Issue tracker MCP: read the MCP Server Detection table from `docs/reference/trackers.md`.
     Find the row matching Type. Search .mcp.json server names/URLs for the listed keywords.
```

Both references use a bare relative path `docs/reference/trackers.md`. When check-setup runs in a consuming project's working directory, the plugin's `docs/` folder is not at that CWD-relative path. The file physically resides in the plugin installation directory (e.g., `.claude/plugins/ceos-agents/docs/reference/trackers.md`).

### Required Behavior

**Step 3a — resolve once:**
1. Locate `trackers.md` using a layered Glob strategy:
   - **Narrow first:** Glob pattern `.claude/plugins/**/docs/reference/trackers.md` (targets plugin installation directory; fast, avoids scanning entire repo)
   - **Broad fallback:** Glob pattern `**/docs/reference/trackers.md` (handles non-standard installation paths)
   - **CWD fallback:** Direct read of `docs/reference/trackers.md` (works when running from plugin repo itself)
2. **Multiple-match disambiguation:** If Glob returns multiple results, prefer the path containing `.claude/plugins/` or `ceos-agents/`. If no path matches that heuristic, emit `[WARN] "Multiple trackers.md found — using {path}. If wrong, verify plugin installation."` and use the first result.
3. **Failure:** If no method finds the file → `[WARN] "trackers.md not found — per-tracker validation skipped. Verify plugin installation."` and skip the rest of Step 3a.

**Step 7 — reuse resolved path:**
1. Reuse the path resolved in Step 3a. Do NOT re-run Glob.
2. If Step 3a emitted `[WARN]` (file not found), Step 7 also skips with `[WARN] "trackers.md not found — MCP server keyword match skipped."`.

**Inline documentation:** Add a path resolution note explaining that `trackers.md` lives in the plugin installation directory, not in the consuming project, and that Glob is used to handle the CWD-context mismatch.

### Acceptance Criteria

- **AC-10:** Step 3a uses Glob with `.claude/plugins/` preference to locate `trackers.md`, not a bare relative path.
- **AC-11:** If `trackers.md` cannot be found by any method, the result is `[WARN]` with skip (not `[FAIL]`, not a crash), and per-tracker validation is skipped.
- **AC-12:** Step 7 reuses the path from Step 3a (no redundant Glob) and skips with `[WARN]` if Step 3a failed to locate the file.

---

## Output Format Requirements

The `## Output format` section (lines 86-117) must be updated to reflect the new messages from all three fixes.

### Current Connectivity example (lines 103-105):

```
### Connectivity
[OK]   Issue tracker — connection OK, project {PROJECT} found, X bugs
[FAIL] Source control — authentication failed (401 Unauthorized)
```

### Required Connectivity example:

```
### Connectivity
[OK]   Issue tracker — connection OK, project {PROJECT} found, X bugs
[FAIL] Issue tracker — server reachable but MCP connection failed (likely TLS) — add NODE_OPTIONS: --use-system-ca to the env block in .mcp.json
[FAIL] Source control — authentication failed. Token needs repository:read scope.
```

### Acceptance Criteria

- **AC-13:** Output format Connectivity block includes at least one TLS-specific failure example line.
- **AC-14:** Output format Connectivity block SC failure line includes the scope hint, consistent with the expanded Step 10.
