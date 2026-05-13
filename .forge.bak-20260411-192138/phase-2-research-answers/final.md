# Phase 2 Synthesized Plan — check-setup SKILL.md Fixes

**Target file:** `skills/check-setup/SKILL.md`
**Total changes:** 3 targeted edits in one file, ~+25 net lines.

---

## Actionable Plan

### Fix 1: TLS Diagnostic Flow (Block 3, Step 9)

**Location:** Lines 71–74 in `skills/check-setup/SKILL.md`

**Problem:** Step 9 has only two failure buckets (auth error, timeout/unreachable). TLS certificate errors (self-signed cert, corporate CA, private PKI) fall into the "timeout/connection refused" bucket and produce the misleading recommendation "verify the server is running and URL is correct" — which is wrong when the server IS network-reachable but Node.js rejects the TLS handshake.

**Pattern matching order:** Check TLS patterns first, then auth patterns, then fall back to unreachable.

- Auth patterns: `401`, `403`, `unauthorized`, `forbidden`, `invalid token`, `authentication`
- TLS patterns: `UNABLE_TO_VERIFY_LEAF_SIGNATURE`, `CERT_UNTRUSTED`, `SELF_SIGNED_CERT`, `self signed certificate`, `certificate verify failed`, `ERR_TLS_`, `DEPTH_ZERO_SELF_SIGNED_CERT`, `unable to get local issuer certificate`
- Unreachable patterns: `ECONNREFUSED`, `ETIMEDOUT`, `ENOTFOUND`, `ECONNRESET`, `timeout`, `connection refused`

**curl probe:** When a TLS pattern is detected, run:
```
curl -s -o /dev/null -w "%{http_code}" --max-time 5 {Instance}
```
- curl exit 0 and HTTP code != `000` → server is network-reachable → TLS diagnosis confirmed
- curl exit non-zero OR HTTP code `000` → server is genuinely unreachable → fall back to unreachable message

**BEFORE (lines 71–74):**
```markdown
9. Run the Bug query from Automation Config via MCP (limit 1 result):
   - Success → [OK] with the number of bugs found
   - Auth error → [FAIL] "MCP server configured but authentication failed — check your token in .mcp.json"
   - Timeout/connection refused → [FAIL] "MCP server configured but not reachable — verify the server is running and URL is correct"
```

**AFTER (replaces lines 71–74; expands to 14 lines):**
```markdown
9. Run the Bug query from Automation Config via MCP (limit 1 result):
   - Success → [OK] with the number of bugs found
   - Auth error (error contains: 401, 403, unauthorized, forbidden, invalid token) →
     [FAIL] "Issue tracker — authentication failed — check your token in .mcp.json"
   - TLS error (error contains: UNABLE_TO_VERIFY_LEAF_SIGNATURE, CERT_UNTRUSTED, SELF_SIGNED_CERT,
     self signed certificate, certificate verify failed, ERR_TLS_, DEPTH_ZERO_SELF_SIGNED_CERT,
     unable to get local issuer certificate) → run curl probe:
     `curl -s -o /dev/null -w "%{http_code}" --max-time 5 {Instance}`
     - curl exit 0 and HTTP code != 000 →
       [FAIL] "Issue tracker — server reachable but MCP connection failed (likely TLS) — add NODE_OPTIONS: --use-system-ca to the env block in .mcp.json"
     - curl exit non-zero or HTTP code 000 →
       [FAIL] "Issue tracker — server not reachable — verify the server is running and URL is correct"
   - Any other error (ECONNREFUSED, ETIMEDOUT, ENOTFOUND, timeout, connection refused) →
     [FAIL] "Issue tracker — server not reachable — verify the server is running and URL is correct"
```

---

### Fix 2: SC Connectivity / Token Scope (Block 3, Step 10)

**Location:** Lines 75–77 in `skills/check-setup/SKILL.md` (shifts to ~85–87 after Fix 1 expands Step 9 by 10 lines)

**Problem:** Step 10 says "list repositories via MCP", which implies a user-level enumeration tool (`list_my_repositories`) that does not exist in Gitea's MCP. It also implies a GitHub-style `read:user` scope that Gitea does not have. The correct approach is to verify that the single declared remote repo from `Source Control → Remote` is accessible — which requires only `repository:read` scope.

**BEFORE (lines 75–77):**
```markdown
10. Verify source control connectivity: list repositories via MCP
    - Success → [OK]
    - Failure → [FAIL] with specific error type (auth vs unreachable)
```

**AFTER (replaces lines 75–77; expands to 7 lines):**
```markdown
10. Verify source control connectivity: confirm the configured remote exists via MCP
    - Use MCP to fetch repository metadata for the Remote value from Automation Config (owner/repo)
    - Success → [OK] "Source control — {owner/repo} reachable"
    - Auth error (401/403) → [FAIL] "Source control — authentication failed. Token needs repository:read scope."
    - Not found (404) → [FAIL] "Source control — repository {owner/repo} not found. Verify Remote in Automation Config."
    - Timeout/connection refused → [FAIL] "Source control — MCP server not reachable. Verify server URL and token in .mcp.json."
```

---

### Fix 3: Path Resolution (Steps 3a and 7)

**Location:** Lines 32 and 59 in `skills/check-setup/SKILL.md`

**Problem:** Both references use a bare relative path `docs/reference/trackers.md`. When the skill runs in a consuming project's working directory, the plugin's `docs/` folder is not at that path. The file is physically located in the plugin installation directory, not the consumer's project root.

**Chosen approach:** Glob-based discovery (`**/docs/reference/trackers.md`), with a CWD-relative fallback and a [WARN] skip if neither resolves. `Glob` is already in the `allowed-tools` frontmatter (line 4) — no frontmatter change needed.

**Reference 1 — Line 32 (Step 3a):**

BEFORE:
```markdown
Read `docs/reference/trackers.md`. Find the row matching the configured Type in the Validation Rules table.
```

AFTER (replace the line above; add blockquote note immediately before it):
```markdown
> **Path resolution note:** `trackers.md` lives in the plugin installation directory, not in the
> consuming project. Always locate it via Glob (`**/docs/reference/trackers.md`) before reading.
> Fall back to CWD-relative path only if Glob returns no results.

Locate trackers.md: use Glob with pattern `**/docs/reference/trackers.md`. Read the first result.
If Glob returns no matches, read `docs/reference/trackers.md` (relative to CWD) as a fallback.
If the file cannot be found by either method → [WARN] "trackers.md not found — per-tracker validation skipped" and skip the rest of Step 3a.
Find the row matching the configured Type in the Validation Rules table.
```

**Reference 2 — Line 59 (Step 7, Issue tracker MCP sub-bullet):**

BEFORE:
```markdown
   - Issue tracker MCP: read the MCP Server Detection table from `docs/reference/trackers.md`.
     Find the row matching Type. Search .mcp.json server names/URLs for the listed keywords.
```

AFTER:
```markdown
   - Issue tracker MCP: locate trackers.md using the same Glob resolution as Step 3a (reuse the
     already-resolved path; do not Glob again). Read the MCP Server Detection table.
     Find the row matching Type. Search .mcp.json server names/URLs for the listed keywords.
     If trackers.md was unavailable in Step 3a → [WARN] "trackers.md not found — MCP server keyword match skipped."
```

---

### Output Format Updates

**Location:** `## Output format` section, the `### Connectivity` block (currently lines 103–105; shifts down after Fixes 1–3 expand their sections).

Two changes are needed:

**Change A (required — Fix 1):** Add the new TLS failure line to the Connectivity example block.

BEFORE:
```
### Connectivity
[OK]   Issue tracker — connection OK, project {PROJECT} found, X bugs
[FAIL] Source control — authentication failed (401 Unauthorized)
```

AFTER:
```
### Connectivity
[OK]   Issue tracker — connection OK, project {PROJECT} found, X bugs
[FAIL] Issue tracker — server reachable but MCP connection failed (likely TLS) — add NODE_OPTIONS: --use-system-ca to the env block in .mcp.json
[FAIL] Source control — authentication failed (401 Unauthorized). Token needs repository:read scope.
```

**Change B (optional — Fix 2):** The `[FAIL] Source control — authentication failed` line gains a scope hint. This is cosmetic but keeps the output format block consistent with the expanded Step 10 failure messages. If edit budget is tight, skip this — the Step 10 rewrite is the blocking change.

---

### Integration Check

All three fixes are compatible. Verification:

| Concern | Status |
|---------|--------|
| Fix 1 adds `Bash` tool usage (curl probe) | `Bash` is already in `allowed-tools` on line 4 — no frontmatter change needed |
| Fix 3 uses `Glob` tool | `Glob` is already in `allowed-tools` on line 4 — no frontmatter change needed |
| Line number shifts after Fix 1 expansion | Fix 1 replaces lines 71–74 (4 lines) with 14 lines → +10 lines. Fix 2 at original lines 75–77 becomes lines 85–87. Fix 3 at original lines 32 and 59 are both above Fix 1 and are unaffected by its expansion. Apply edits in document order: Fix 3 first (lines 32 and 59), then Fix 1 (lines 71–74), then Fix 2 (lines 75–77). |
| Output format block references | The Connectivity block in `## Output format` must be updated after all three step-level changes are applied. |
| No Automation Config contract change | All changes are internal skill behavior — no new required or optional keys are added. No version bump is triggered by these fixes alone. |
| No other files affected | All three fixes are scoped to `skills/check-setup/SKILL.md`. |

**Recommended edit order to avoid line-number drift:**

1. Fix 3, Reference 1 — line 32 (Step 3a) — no line-count change above this point
2. Fix 3, Reference 2 — line 59 (Step 7) — adjusted by +4 from step above
3. Fix 1 — lines 71–74 (Step 9) — adjusted by +4 from steps above
4. Fix 2 — lines 75–77 (Step 10) — adjusted by +14 from Fix 1
5. Output Format updates — shifted down by total net additions from all fixes above

---

### Out-of-Scope Notes

1. **Bare `docs/reference/trackers.md` path in other files (13+ occurrences):** The Glob-then-fallback pattern applied in Fix 3 to `check-setup` has the same latent failure in every other skill and core contract file that references this path. A separate task should migrate all remaining occurrences. Search scope: `skills/` and `core/` directories, pattern `docs/reference/trackers\.md`. Fix pattern is identical to Fix 3.

2. **TLS diagnosis for source control (Step 10):** Fix 1 adds TLS detection only to Step 9 (issue tracker). Step 10 (source control) does not yet have an equivalent TLS sub-flow. If the SC MCP server also runs behind a private CA, it would exhibit the same silent misclassification. This can be addressed in a follow-up by applying the same curl probe + pattern logic to the Step 10 timeout/unreachable branch.

3. **`NODE_OPTIONS: --use-system-ca` documentation:** The `.mcp.json` example in `docs/guides/` or `docs/reference/` does not show the `env` block pattern. A documentation follow-up could add a "TLS troubleshooting" section showing exactly how to set this flag for affected MCP servers. This is informational only and does not block the fix.
