# Design Document — check-setup SKILL.md Fixes

**Target file:** `skills/check-setup/SKILL.md` (133 lines, current state)
**Fixes:** 3 (TLS diagnostic, SC connectivity, path resolution)

---

## Edit Locations in SKILL.md

### Fix 3a — Step 3a path resolution (line 32)

**Scope:** Replace line 32 and insert path resolution note above it.

**Current (line 32):**
```markdown
Read `docs/reference/trackers.md`. Find the row matching the configured Type in the Validation Rules table.
```

**Replacement (6 lines, net +5):**
```markdown
> **Path note:** `trackers.md` lives in the plugin installation directory, not in the consuming
> project. Glob is used to handle CWD-context mismatch.

Locate `trackers.md`: Glob with pattern `.claude/plugins/**/docs/reference/trackers.md` first.
If no results, Glob with `**/docs/reference/trackers.md`. If still none, try `docs/reference/trackers.md` relative to CWD.
If multiple results, prefer the path containing `.claude/plugins/` or `ceos-agents/`; if ambiguous → [WARN] "Multiple trackers.md found — using {path}."
If the file cannot be found → [WARN] "trackers.md not found — per-tracker validation skipped. Verify plugin installation." and skip the rest of Step 3a.
Find the row matching the configured Type in the Validation Rules table.
```

**Lines affected:** 32 replaced with 32-38 (net +6 lines).

---

### Fix 3b — Step 7 path reuse (lines 59-60)

**Scope:** Replace lines 59-60 with path-reuse instruction.

**Current (lines 59-60):**
```markdown
   - Issue tracker MCP: read the MCP Server Detection table from `docs/reference/trackers.md`.
     Find the row matching Type. Search .mcp.json server names/URLs for the listed keywords.
```

**Replacement (4 lines, net +2):**
```markdown
   - Issue tracker MCP: reuse the trackers.md path resolved in Step 3a (do not Glob again).
     Read the MCP Server Detection table. Find the row matching Type.
     Search .mcp.json server names/URLs for the listed keywords.
     If trackers.md was unavailable in Step 3a → [WARN] "trackers.md not found — MCP server keyword match skipped."
```

**Lines affected (after Fix 3a shift):** Original 59-60 become 65-66; replaced with 65-68 (net +2 lines).

---

### Fix 1 — Step 9 TLS diagnostic (lines 71-74)

**Scope:** Replace lines 71-74 with expanded three-bucket classification plus curl probe.

**Current (lines 71-74):**
```markdown
9. Run the Bug query from Automation Config via MCP (limit 1 result):
   - Success → [OK] with the number of bugs found
   - Auth error → [FAIL] "MCP server configured but authentication failed — check your token in .mcp.json"
   - Timeout/connection refused → [FAIL] "MCP server configured but not reachable — verify the server is running and URL is correct"
```

**Replacement (19 lines, net +15):**
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

**Lines affected (after Fix 3a/3b shifts):** Original 71-74 become 79-82; replaced with 79-97 (net +15 lines).

---

### Fix 2 — Step 10 SC connectivity (lines 75-77)

**Scope:** Replace lines 75-77 with targeted repo metadata fetch and four error branches.

**Current (lines 75-77):**
```markdown
10. Verify source control connectivity: list repositories via MCP
    - Success → [OK]
    - Failure → [FAIL] with specific error type (auth vs unreachable)
```

**Replacement (8 lines, net +5):**
```markdown
10. Verify source control connectivity: fetch metadata for the configured Remote (owner/repo) via MCP
    - Use MCP to fetch repository metadata for the Remote value from Automation Config
    - Success → [OK] "Source control — {owner/repo} reachable"
    - Auth error (401/403) → [FAIL] "Source control — authentication failed. Token needs repository:read scope (Gitea), repo scope (GitHub), or read_repository scope (GitLab)."
    - Not found (404) → [FAIL] "Source control — repository {owner/repo} not found. Verify Remote in Automation Config."
    - Tool not found (MCP server lacks repository metadata method) → [WARN] "Source control MCP: repository existence check not supported — skipping."
    - Timeout/unreachable → [FAIL] "Source control — MCP server not reachable. Verify server URL and token in .mcp.json."
```

**Lines affected (after all prior shifts):** Original 75-77 become 98-100; replaced with 98-105 (net +5 lines).

---

### Output Format update (lines 103-105)

**Scope:** Replace the Connectivity example block to reflect Fix 1 and Fix 2 message changes.

**Current (lines 103-105):**
```
[OK]   Issue tracker — connection OK, project {PROJECT} found, X bugs
[FAIL] Source control — authentication failed (401 Unauthorized)
```

**Replacement (3 lines, net +1):**
```
[OK]   Issue tracker — connection OK, project {PROJECT} found, X bugs
[FAIL] Issue tracker — server reachable but MCP connection failed (likely TLS) — add NODE_OPTIONS: --use-system-ca to the env block in .mcp.json
[FAIL] Source control — authentication failed. Token needs repository:read scope.
```

**Lines affected (after all prior shifts):** Original 103-105 become ~131-133; replaced with ~131-134.

---

## Edit Ordering (to avoid line-number drift)

Edits MUST be applied in top-to-bottom document order:

| Order | Fix | Original Lines | Description | Net Line Change |
|-------|-----|---------------|-------------|-----------------|
| 1 | Fix 3a | 32 | Step 3a path resolution | +6 |
| 2 | Fix 3b | 59-60 | Step 7 path reuse | +2 |
| 3 | Fix 1 | 71-74 | Step 9 TLS diagnostic | +15 |
| 4 | Fix 2 | 75-77 | Step 10 SC connectivity | +5 |
| 5 | Output | 103-105 | Connectivity example block | +1 |

**Total net line additions:** ~+29 lines (133 → ~162 lines).

Each subsequent edit must account for the cumulative line shift from all prior edits. However, since edits proceed top-to-bottom, each edit only needs to target the correct content string, not track shifted line numbers.

---

## Output Format Section — Full Updated Block

After all step-level edits, the `### Connectivity` block inside the Output Format code fence must read:

```
### Connectivity
[OK]   Issue tracker — connection OK, project {PROJECT} found, X bugs
[FAIL] Issue tracker — server reachable but MCP connection failed (likely TLS) — add NODE_OPTIONS: --use-system-ca to the env block in .mcp.json
[FAIL] Source control — authentication failed. Token needs repository:read scope.
```

The remaining Output Format sections (Automation Config, MCP servers, Build & Test, Result line, Verdict) are unchanged.

---

## Integration Check — All 3 Fixes Compatible

| Concern | Status |
|---------|--------|
| Fix 1 uses `Bash` tool (curl probe) | `Bash` already in `allowed-tools` (line 4) — no frontmatter change |
| Fix 3 uses `Glob` tool | `Glob` already in `allowed-tools` (line 4) — no frontmatter change |
| Fix 1 and Fix 2 are adjacent (Steps 9 and 10) | No overlap — Fix 1 replaces lines 71-74, Fix 2 replaces lines 75-77. Edits are disjoint. |
| Fix 3a and Fix 3b reference the same file path | 3a resolves the path, 3b reuses it. No conflict. |
| Output Format block reflects all three fixes | Updated Connectivity block covers both TLS line (Fix 1) and SC scope hint (Fix 2). Path resolution (Fix 3) does not affect output format. |
| No Automation Config contract change | All changes are internal skill logic. No new required or optional keys. No version bump triggered. |
| No other files affected | All edits scoped to `skills/check-setup/SKILL.md` only. |
| Block 5 (Plugin Composability) | Unchanged. Lines 118-126 are below all edits and shift down by the net additions, but content is unaffected. |
| Rules section | Unchanged. Lines 127-133 shift down but content is unaffected. |

---

## Out-of-Scope Items (for later)

These items were identified during brainstorming as valuable follow-ups but are explicitly excluded from this specification:

1. **Bare path references in other files:** 13+ other files (`skills/onboard/SKILL.md`, `skills/scaffold/SKILL.md`, `skills/init/SKILL.md`, `core/mcp-detection.md`) also reference `docs/reference/trackers.md` with bare paths. Same Glob pattern should be applied. Separate task.

2. **TLS diagnostic for Step 10 (SC connectivity):** Fix 1 adds TLS detection only to Step 9 (issue tracker). Step 10 can exhibit the same TLS misclassification. Apply the same curl probe + pattern logic to the Step 10 timeout/unreachable branch in a follow-up.

3. **Consolidate connectivity into `core/mcp-detection.md`:** After TLS fixes land in both Step 9 and Step 10, refactor both steps to delegate error classification to a shared `mcp-detection.md` contract with a structured `error_type` field.

4. **`NODE_OPTIONS: --use-system-ca` documentation:** Add a "TLS troubleshooting" section to `docs/guides/` or `docs/reference/` showing the `.mcp.json` env block pattern. Informational only.

5. **Negative-case test scenarios:** Add manual test scenarios to `tests/scenarios/` for TLS failure, Gitea tool rejection, and missing trackers.md in consumer CWD. Environment-dependent; cannot be mocked in current markdown harness.
