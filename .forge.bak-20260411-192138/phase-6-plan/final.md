# Phase 6 — Implementation Plan

**Target file:** `skills/check-setup/SKILL.md` (133 lines, current state)
**Fixes:** 3 (TLS diagnostic, SC connectivity, path resolution) + output format update + TDD test copy
**Total tasks:** 6 (T1-T6)
**Estimated net line additions:** ~29 lines (133 -> ~162 lines)

---

## Task Graph

| Task | Description | Dependencies | Parallel? |
|------|------------|-------------|-----------|
| T1 | Path resolution preamble — Step 3a Glob-first resolution | none | yes |
| T2 | Step 7 path resolution update — reuse resolved path from Step 3a | T1 | no |
| T3 | Step 9 TLS diagnostic expansion — three-bucket classification + curl probe | none | yes |
| T4 | Step 10 SC connectivity rewrite — targeted repo fetch with 4 error branches | none | yes |
| T5 | Output format Connectivity block — add TLS example + scope hint | T3, T4 | no |
| T6 | Copy TDD test files to tests/scenarios/ | T1-T5 | no |

---

## Edit Ordering

Edits MUST be applied in **top-to-bottom document order** to avoid content drift between edits. The Edit tool matches by exact string, so top-to-bottom ordering ensures each old_string remains findable in the file even after prior edits have been applied.

| Order | Task | Original Lines | Description |
|-------|------|---------------|-------------|
| 1 | T1 | 32 | Step 3a — replace bare Read with Glob-first resolution |
| 2 | T2 | 59-60 | Step 7 — replace bare trackers.md reference with Step 3a reuse |
| 3 | T3 | 71-74 | Step 9 — replace two-bucket error handling with three-bucket TLS diagnostic |
| 4 | T4 | 75-77 | Step 10 — replace list-repositories with targeted repo fetch |
| 5 | T5 | 103-105 | Output format Connectivity block — add TLS + scope hint examples |
| 6 | T6 | n/a | Copy test files (no SKILL.md edit) |

---

## Per-Task Details

### T1: Path Resolution Preamble (Step 3a)

**File:** `skills/check-setup/SKILL.md`
**Exact lines:** 32 (single line)
**AC coverage:** AC-10, AC-11

**Old text:**
```
Read `docs/reference/trackers.md`. Find the row matching the configured Type in the Validation Rules table.
```

**New text:**
```
> **Path note:** `trackers.md` lives in the plugin installation directory, not in the consuming
> project. Glob is used to handle CWD-context mismatch.

Locate `trackers.md`: Glob with pattern `.claude/plugins/**/docs/reference/trackers.md` first.
If no results, Glob with `**/docs/reference/trackers.md`. If still none, try `docs/reference/trackers.md` relative to CWD.
If multiple results, prefer the path containing `.claude/plugins/` or `ceos-agents/`; if ambiguous → [WARN] "Multiple trackers.md found — using {path}."
If the file cannot be found → [WARN] "trackers.md not found — per-tracker validation skipped. Verify plugin installation." and skip the rest of Step 3a.
Find the row matching the configured Type in the Validation Rules table.
```

**Edit tool instructions:**
```
Edit(
  file_path="skills/check-setup/SKILL.md",
  old_string="Read `docs/reference/trackers.md`. Find the row matching the configured Type in the Validation Rules table.",
  new_string="> **Path note:** `trackers.md` lives in the plugin installation directory, not in the consuming\n> project. Glob is used to handle CWD-context mismatch.\n\nLocate `trackers.md`: Glob with pattern `.claude/plugins/**/docs/reference/trackers.md` first.\nIf no results, Glob with `**/docs/reference/trackers.md`. If still none, try `docs/reference/trackers.md` relative to CWD.\nIf multiple results, prefer the path containing `.claude/plugins/` or `ceos-agents/`; if ambiguous → [WARN] \"Multiple trackers.md found — using {path}.\"\nIf the file cannot be found → [WARN] \"trackers.md not found — per-tracker validation skipped. Verify plugin installation.\" and skip the rest of Step 3a.\nFind the row matching the configured Type in the Validation Rules table."
)
```

**AC verification:**
- AC-10: Three-layer Glob resolution (narrow `.claude/plugins/`, broad `**`, CWD fallback) in correct order. PASS.
- AC-11: File-not-found case emits `[WARN]` with "per-tracker validation skipped" + skip instruction. PASS.

---

### T2: Step 7 Path Resolution Update

**File:** `skills/check-setup/SKILL.md`
**Exact lines:** 59-60
**AC coverage:** AC-12

**Old text:**
```
   - Issue tracker MCP: read the MCP Server Detection table from `docs/reference/trackers.md`.
     Find the row matching Type. Search .mcp.json server names/URLs for the listed keywords.
```

**New text:**
```
   - Issue tracker MCP: reuse the trackers.md path resolved in Step 3a (do not Glob again).
     Read the MCP Server Detection table. Find the row matching Type.
     Search .mcp.json server names/URLs for the listed keywords.
     If trackers.md was unavailable in Step 3a → [WARN] "trackers.md not found — MCP server keyword match skipped."
```

**Edit tool instructions:**
```
Edit(
  file_path="skills/check-setup/SKILL.md",
  old_string="   - Issue tracker MCP: read the MCP Server Detection table from `docs/reference/trackers.md`.\n     Find the row matching Type. Search .mcp.json server names/URLs for the listed keywords.",
  new_string="   - Issue tracker MCP: reuse the trackers.md path resolved in Step 3a (do not Glob again).\n     Read the MCP Server Detection table. Find the row matching Type.\n     Search .mcp.json server names/URLs for the listed keywords.\n     If trackers.md was unavailable in Step 3a → [WARN] \"trackers.md not found — MCP server keyword match skipped.\""
)
```

**AC verification:**
- AC-12: References "Step 3a", says "do not Glob again", has `[WARN]` skip branch for unavailable file. PASS.

---

### T3: Step 9 TLS Diagnostic Expansion

**File:** `skills/check-setup/SKILL.md`
**Exact lines:** 71-74 (after T1 and T2 shifts, the content has moved down but the old_string is unique)
**AC coverage:** AC-1, AC-2, AC-3, AC-4, AC-5

**Old text:**
```
9. Run the Bug query from Automation Config via MCP (limit 1 result):
   - Success → [OK] with the number of bugs found
   - Auth error → [FAIL] "MCP server configured but authentication failed — check your token in .mcp.json"
   - Timeout/connection refused → [FAIL] "MCP server configured but not reachable — verify the server is running and URL is correct"
```

**New text:**
```
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

**Edit tool instructions:**
```
Edit(
  file_path="skills/check-setup/SKILL.md",
  old_string="9. Run the Bug query from Automation Config via MCP (limit 1 result):\n   - Success → [OK] with the number of bugs found\n   - Auth error → [FAIL] \"MCP server configured but authentication failed — check your token in .mcp.json\"\n   - Timeout/connection refused → [FAIL] \"MCP server configured but not reachable — verify the server is running and URL is correct\"",
  new_string="9. Run the Bug query from Automation Config via MCP (limit 1 result):\n   - Success → [OK] with the number of bugs found\n   - On failure, classify the error in this order:\n     1. **TLS error** (error contains any of: UNABLE_TO_VERIFY_LEAF_SIGNATURE, CERT_UNTRUSTED,\n        SELF_SIGNED_CERT, self signed certificate, certificate verify failed, ERR_TLS_,\n        DEPTH_ZERO_SELF_SIGNED_CERT, unable to get local issuer certificate):\n        Run a curl probe to confirm network reachability:\n        - Check `which curl` — if curl is not available, skip probe and emit:\n          [FAIL] \"Issue tracker — TLS error detected. Add NODE_OPTIONS: --use-system-ca to .mcp.json env block. (curl not available for confirmation probe)\"\n        - Run: `curl -s -o /dev/null -w \"%{http_code}\" --max-time 5 {Instance}`\n        - curl exit 0 and HTTP code != 000 →\n          [FAIL] \"Issue tracker — server reachable but MCP connection failed (likely TLS) — add NODE_OPTIONS: --use-system-ca to the env block in .mcp.json\"\n        - curl exit non-zero or HTTP code 000 →\n          [FAIL] \"Issue tracker — connection failed (TLS or network). If using a private CA, try NODE_OPTIONS: --use-system-ca. If server is remote, verify URL.\"\n     2. **Auth error** (error contains: 401, 403, unauthorized, forbidden, invalid token, authentication) →\n        [FAIL] \"Issue tracker — authentication failed — check your token in .mcp.json\"\n     3. **Any other error** →\n        [FAIL] \"Issue tracker — server not reachable — verify the server is running and URL is correct. If using a private CA (self-signed or corporate PKI), also try NODE_OPTIONS: --use-system-ca.\""
)
```

**AC verification:**
- AC-1: All three TLS sub-branches (curl-success, curl-failure, curl-absent) include `NODE_OPTIONS: --use-system-ca`. PASS.
- AC-2: curl-success branch says "server reachable but MCP connection failed (likely TLS)". PASS.
- AC-3: curl-failure branch includes `NODE_OPTIONS: --use-system-ca`; curl-absent branch includes `NODE_OPTIONS: --use-system-ca`. Neither drops to a pure "not reachable" message. PASS.
- AC-4: "Any other error" branch includes "If using a private CA (self-signed or corporate PKI), also try NODE_OPTIONS: --use-system-ca." PASS.
- AC-5: TLS error is item 1, Auth error is item 2 in the numbered list. PASS.

**NODE_OPTIONS count check:** The new text contains `NODE_OPTIONS` 4 times (curl-absent, curl-success, curl-failure, generic-unreachable). The output format block (T5) adds 1 more. Total >= 5, well above the test threshold of 3.

---

### T4: Step 10 SC Connectivity Rewrite

**File:** `skills/check-setup/SKILL.md`
**Exact lines:** 75-77 (after T1-T3 shifts, content has moved but old_string is unique)
**AC coverage:** AC-6, AC-7, AC-8, AC-9

**Old text:**
```
10. Verify source control connectivity: list repositories via MCP
    - Success → [OK]
    - Failure → [FAIL] with specific error type (auth vs unreachable)
```

**New text:**
```
10. Verify source control connectivity: fetch metadata for the configured Remote (owner/repo) via MCP
    - Use MCP to fetch repository metadata for the Remote value from Automation Config
    - Success → [OK] "Source control — {owner/repo} reachable"
    - Auth error (401/403) → [FAIL] "Source control — authentication failed. Token needs repository:read scope (Gitea), repo scope (GitHub), or read_repository scope (GitLab)."
    - Not found (404) → [FAIL] "Source control — repository {owner/repo} not found. Verify Remote in Automation Config."
    - Tool not found (MCP server lacks repository metadata method) → [WARN] "Source control MCP: repository existence check not supported — skipping."
    - Timeout/unreachable → [FAIL] "Source control — MCP server not reachable. Verify server URL and token in .mcp.json."
```

**Edit tool instructions:**
```
Edit(
  file_path="skills/check-setup/SKILL.md",
  old_string="10. Verify source control connectivity: list repositories via MCP\n    - Success → [OK]\n    - Failure → [FAIL] with specific error type (auth vs unreachable)",
  new_string="10. Verify source control connectivity: fetch metadata for the configured Remote (owner/repo) via MCP\n    - Use MCP to fetch repository metadata for the Remote value from Automation Config\n    - Success → [OK] \"Source control — {owner/repo} reachable\"\n    - Auth error (401/403) → [FAIL] \"Source control — authentication failed. Token needs repository:read scope (Gitea), repo scope (GitHub), or read_repository scope (GitLab).\"\n    - Not found (404) → [FAIL] \"Source control — repository {owner/repo} not found. Verify Remote in Automation Config.\"\n    - Tool not found (MCP server lacks repository metadata method) → [WARN] \"Source control MCP: repository existence check not supported — skipping.\"\n    - Timeout/unreachable → [FAIL] \"Source control — MCP server not reachable. Verify server URL and token in .mcp.json.\""
)
```

**AC verification:**
- AC-6: Says "fetch metadata for the configured Remote (owner/repo)" — no "list repositories" anywhere. References "Remote value from Automation Config". PASS.
- AC-7: Auth failure message includes `repository:read scope (Gitea), repo scope (GitHub), or read_repository scope (GitLab)`. PASS.
- AC-8: 404 is a separate branch: "repository {owner/repo} not found. Verify Remote in Automation Config." Distinct from auth error. PASS.
- AC-9: Tool not found branch uses `[WARN]`, not `[FAIL]`. PASS.

---

### T5: Output Format Connectivity Block

**File:** `skills/check-setup/SKILL.md`
**Exact lines:** 103-105 (inside the Output format code fence)
**AC coverage:** AC-13, AC-14

**Old text:**
```
### Connectivity
[OK]   Issue tracker — connection OK, project {PROJECT} found, X bugs
[FAIL] Source control — authentication failed (401 Unauthorized)
```

**New text:**
```
### Connectivity
[OK]   Issue tracker — connection OK, project {PROJECT} found, X bugs
[FAIL] Issue tracker — server reachable but MCP connection failed (likely TLS) — add NODE_OPTIONS: --use-system-ca to the env block in .mcp.json
[FAIL] Source control — authentication failed. Token needs repository:read scope.
```

**Edit tool instructions:**
```
Edit(
  file_path="skills/check-setup/SKILL.md",
  old_string="### Connectivity\n[OK]   Issue tracker — connection OK, project {PROJECT} found, X bugs\n[FAIL] Source control — authentication failed (401 Unauthorized)",
  new_string="### Connectivity\n[OK]   Issue tracker — connection OK, project {PROJECT} found, X bugs\n[FAIL] Issue tracker — server reachable but MCP connection failed (likely TLS) — add NODE_OPTIONS: --use-system-ca to the env block in .mcp.json\n[FAIL] Source control — authentication failed. Token needs repository:read scope."
)
```

**AC verification:**
- AC-13: Connectivity block now contains a TLS-specific `[FAIL]` line with `NODE_OPTIONS: --use-system-ca`. PASS.
- AC-14: Only the Connectivity block within the Output format section is changed. All other sections (frontmatter, Block 1, Block 2 non-Step-7 lines, Block 4, Block 5, Rules, Verdict) remain unchanged. PASS.

---

### T6: Copy TDD Test Files to tests/scenarios/

**File:** Not SKILL.md — this task copies test files.
**Dependencies:** T1-T5 (all edits must be complete before running tests)
**AC coverage:** n/a (infrastructure task)

**Actions:**

1. Copy `.forge/phase-5-tdd/tests/check-setup-improvements.sh` to `tests/scenarios/check-setup-improvements.sh`
2. Copy `.forge/phase-5-tdd/tests-hidden/check-setup-edge-cases.sh` to `tests/scenarios/check-setup-edge-cases.sh`

**Bash commands:**
```bash
cp .forge/phase-5-tdd/tests/check-setup-improvements.sh tests/scenarios/check-setup-improvements.sh
cp .forge/phase-5-tdd/tests-hidden/check-setup-edge-cases.sh tests/scenarios/check-setup-edge-cases.sh
```

**Note:** The test scripts use `REPO_ROOT="$(cd "$(dirname "$0")/../../../" && pwd)"` which is correct for `.forge/phase-5-tdd/tests/` but will be wrong from `tests/scenarios/`. The REPO_ROOT line must be updated for the copied files to resolve correctly from `tests/scenarios/`:

```bash
# In copied files, change:
REPO_ROOT="$(cd "$(dirname "$0")/../../../" && pwd)"
# To:
REPO_ROOT="$(cd "$(dirname "$0")/../../" && pwd)"
```

This is because `tests/scenarios/` is 2 levels deep from repo root, while `.forge/phase-5-tdd/tests/` is 3 levels deep.

---

## AC Coverage Matrix

| AC | Task(s) | Description | Verified By |
|----|---------|-------------|-------------|
| AC-1 | T3 | NODE_OPTIONS in all TLS branches | 4 occurrences of NODE_OPTIONS in Step 9 |
| AC-2 | T3 | Curl probe confirms reachability | curl-success branch: "server reachable" + "TLS" |
| AC-3 | T3 | TLS hint when curl fails/absent | curl-failure + curl-absent branches both have NODE_OPTIONS |
| AC-4 | T3 | Soft TLS hint on generic unreachable | "Any other error" branch includes private CA hint |
| AC-5 | T3 | TLS before auth in classification | TLS is item 1, Auth is item 2 |
| AC-6 | T4 | Targeted repo fetch, no "list" | "fetch metadata for the configured Remote (owner/repo)" |
| AC-7 | T4 | Auth failure includes scope hint | "repository:read scope (Gitea), repo scope (GitHub)..." |
| AC-8 | T4 | 404 distinct from auth error | Separate "Not found (404)" branch |
| AC-9 | T4 | Tool-not-found is WARN not FAIL | [WARN] "...not supported — skipping." |
| AC-10 | T1 | Glob-first with .claude/plugins/ | Three-layer: narrow, broad, CWD |
| AC-11 | T1 | Missing trackers.md is WARN+skip | [WARN] "trackers.md not found — per-tracker validation skipped..." |
| AC-12 | T2 | Step 7 reuses Step 3a path | "reuse the trackers.md path resolved in Step 3a (do not Glob again)" |
| AC-13 | T5 | Output format has TLS example | New [FAIL] line with NODE_OPTIONS in Connectivity block |
| AC-14 | T1-T5 | No regression in unchanged sections | Only 5 edit regions touched; all block headers, frontmatter, rules preserved |

---

## Verification

After all edits are applied, run these three test suites in order:

### 1. TDD tests (primary)
```bash
bash .forge/phase-5-tdd/tests/check-setup-improvements.sh
```
**Expected:** PASS on all 14 AC checks.

### 2. Hidden tests (edge cases)
```bash
bash .forge/phase-5-tdd/tests-hidden/check-setup-edge-cases.sh
```
**Expected:** PASS on all 4 edge case checks:
- Edge case 1: No `NODE_TLS_REJECT_UNAUTHORIZED` in the file
- Edge case 2: `which curl` guard present
- Edge case 3: Step 7 references Step 3a
- Edge case 4: Step 7 does not contain its own Glob for trackers.md

### 3. Full test harness (regression)
```bash
./tests/harness/run-tests.sh
```
**Expected:** All existing tests pass. No regressions.

---

## Risk Notes

1. **Edit uniqueness:** Each old_string is unique in the file (verified by reading the full file). The Edit tool will not hit ambiguity errors.
2. **No frontmatter changes:** `Bash` and `Glob` are already in `allowed-tools` (line 4). No modification needed.
3. **No Automation Config contract changes:** All edits are internal skill logic. No version bump triggered.
4. **Em dash characters:** The file uses Unicode em dashes (U+2014: —) not ASCII double dashes. The old_string values preserve these exactly.
5. **Curly quote risk:** The file uses straight ASCII double quotes (`"`), not Unicode curly quotes. The old/new strings use straight quotes throughout.
