# Phase 6: Implementation Plan — v6.4.4 Connectivity Diagnostics Hardening

Date: 2026-04-11
Tasks: 10
Files: 5 source + 1 test
AC coverage: AC-1 through AC-19

---

## Execution Groups

| Group | Tasks | Constraint |
|-------|-------|-----------|
| A | Task 1.0 | Template definition (no file writes — reference only) |
| B | Tasks 1.1, 1.2, 1.3, 1.4, 3.1 | Parallel — each edits a different file (or independent section) |
| C | Task 2.1 | Sequential after 1.4 — same file (core/mcp-detection.md) |
| D | Tasks 2.2, 2.3 | Parallel — each edits a different file, depends on 2.1 |
| E | Task 4.1 | Test copy + run — after all implementation tasks |

---

## Task Definitions

### Task 1.0: Define canonical Glob resolution block template
- **File:** (none — reference pattern only)
- **AC coverage:** AC-1, AC-3, AC-4, AC-5
- **Dependencies:** none
- **Parallel group:** A
- **Description:** Establish the canonical text pattern that all downstream tasks (1.1–1.4) will adapt. This is not a file edit — it defines the reusable block for implementors to copy and customize.
- **Canonical pattern:**

```markdown
> **Path note:** `trackers.md` lives in the plugin installation directory, not in the consuming
> project. Glob is used to handle CWD-context mismatch.

Resolve `{trackers_md_path}` once:
1. Glob `.claude/plugins/**/docs/reference/trackers.md` — if results, prefer path containing `.claude/plugins/` or `ceos-agents/`
2. Glob `**/docs/reference/trackers.md` — fallback if step 1 empty
3. `docs/reference/trackers.md` — bare CWD-relative last resort
If not found → [WARN] "{file-specific message}" and {file-specific fallback}.
```

Three invariants: (1) 3-layer order, (2) preference for `.claude/plugins/` or `ceos-agents/`, (3) `[WARN]` + graceful skip on failure.

---

### Task 1.1: Migrate skills/onboard/SKILL.md — bare path resolution
- **File:** `skills/onboard/SKILL.md`
- **AC coverage:** AC-1, AC-2, AC-3, AC-4, AC-5
- **Dependencies:** Task 1.0
- **Parallel group:** B
- **Description:** Add path-note blockquote and resolve-once Glob block before sub-step 2 of Step 2. Replace all 6 bare `docs/reference/trackers.md` references with `{trackers_md_path}`.
- **Edits:**

**Edit 1 — Insert resolution block (between line 67 and line 68):**

Current text at lines 65–68:
```
Ask step by step:

1. Which issue tracker do you use? (youtrack / github / jira / linear / gitea / redmine)
2. Instance URL — read defaults from `docs/reference/trackers.md` Instance & Project Defaults table
```

After line 67 (after sub-step 1), insert before sub-step 2:
```markdown

> **Path note:** `trackers.md` lives in the plugin installation directory, not in the consuming
> project. Glob is used to handle CWD-context mismatch.

Resolve `{trackers_md_path}` once:
1. Glob `.claude/plugins/**/docs/reference/trackers.md` — if results, use first (prefer path containing `.claude/plugins/` or `ceos-agents/`; if ambiguous → [WARN] "Multiple trackers.md found — using {path}.")
2. Glob `**/docs/reference/trackers.md` — use first result if step 1 found nothing
3. Use `docs/reference/trackers.md` as last resort
If not found → [WARN] "trackers.md not found — using built-in defaults for this tracker type." and use default values from knowledge.

```

**Edit 2 — Replace 6 bare references with `{trackers_md_path}`:**

| Line | Old text fragment | New text fragment |
|------|-------------------|-------------------|
| 68 | `` read defaults from `docs/reference/trackers.md` Instance & Project Defaults table `` | `` read defaults from `{trackers_md_path}` Instance & Project Defaults table `` |
| 70 | `` read defaults from `docs/reference/trackers.md` Query Syntax table `` | `` read defaults from `{trackers_md_path}` Query Syntax table `` |
| 72 | `` read defaults from `docs/reference/trackers.md` Query Syntax table `` | `` read defaults from `{trackers_md_path}` Query Syntax table `` |
| 75 | `` read defaults from `docs/reference/trackers.md` State Transition Syntax table `` | `` read defaults from `{trackers_md_path}` State Transition Syntax table `` |
| 76 | `` read defaults from `docs/reference/trackers.md` On Start Set Defaults table `` | `` read defaults from `{trackers_md_path}` On Start Set Defaults table `` |
| 108 | `` read from `docs/reference/trackers.md` PR Description Footer table `` | `` read from `{trackers_md_path}` PR Description Footer table `` |

Note: After Edit 1 inserts ~10 lines, Edit 2 line numbers shift by ~10. Apply Edit 2 using text matching, not absolute line numbers.

---

### Task 1.2: Migrate skills/scaffold/SKILL.md — bare path resolution
- **File:** `skills/scaffold/SKILL.md`
- **AC coverage:** AC-1, AC-2, AC-3, AC-4, AC-5
- **Dependencies:** Task 1.0
- **Parallel group:** B
- **Description:** Add path-note blockquote and resolve-once Glob block at Step 0-INFRA (before the "Collect details" list items). Replace all 4 bare `docs/reference/trackers.md` references with `{trackers_md_path}`.
- **Edits:**

**Edit 1 — Insert resolution block (between line 91 and line 92):**

Current text at lines 91–93:
```
**If tracker = "ready":** Collect details:
- Tracker type: `[youtrack/github/jira/linear/gitea/redmine]`
- Instance URL (show format example from `docs/reference/trackers.md` Instance & Project Defaults table)
```

After line 91 ("Collect details:"), insert before the list items:

```markdown

> **Path note:** `trackers.md` lives in the plugin installation directory, not in the consuming
> project. Glob is used to handle CWD-context mismatch.

Resolve `{trackers_md_path}` once at the start of Step 0-INFRA:
1. Glob `.claude/plugins/**/docs/reference/trackers.md` — if results, prefer path containing `.claude/plugins/` or `ceos-agents/`
2. Glob `**/docs/reference/trackers.md` — fallback if step 1 empty
3. `docs/reference/trackers.md` — bare CWD-relative last resort
If not found → [WARN] "trackers.md not found — using built-in defaults." and proceed with inline knowledge.

```

**Edit 2 — Replace 4 bare references with `{trackers_md_path}`:**

| Line | Old text fragment | New text fragment |
|------|-------------------|-------------------|
| 93 | `` from `docs/reference/trackers.md` Instance & Project Defaults table `` | `` from `{trackers_md_path}` Instance & Project Defaults table `` |
| 169 | `` from `docs/reference/trackers.md` `` | `` from `{trackers_md_path}` `` |
| 484 | `` from `docs/reference/trackers.md` `` | `` from `{trackers_md_path}` `` |
| 543 | `` in `docs/reference/trackers.md` `` | `` in `{trackers_md_path}` `` |

Note: After Edit 1 inserts ~8 lines, the absolute line numbers for Edit 2 shift. Use text matching for all 4 replacements. The replacement on line 169 is inside Step 0-MCP (guidance display). Line 484 is in Step 4b-replaced (`.mcp.json.example` generation). Line 543 is in Step 4e (sub-issue capabilities reference).

---

### Task 1.3: Migrate skills/init/SKILL.md — bare path resolution
- **File:** `skills/init/SKILL.md`
- **AC coverage:** AC-1, AC-2, AC-4, AC-5
- **Dependencies:** Task 1.0
- **Parallel group:** B
- **Description:** Replace the single bare `docs/reference/trackers.md` reference at line 36 (Step 0, Instance default) with a path-note blockquote and inline Glob resolution. Add fallback to hardcoded defaults.
- **Edits:**

**Edit 1 — Replace line 36:**

Current text at line 36:
```
   - **Instance** = `cli_tracker_instance` (if not provided, use default from `docs/reference/trackers.md` Instance & Project Defaults table for the given type)
```

Replace with:
```
   - **Instance** = `cli_tracker_instance` (if not provided, derive default:
     > **Path note:** `trackers.md` lives in the plugin installation directory. Resolve via Glob before reading defaults.

     Resolve `{trackers_md_path}`: Glob `.claude/plugins/**/docs/reference/trackers.md` (prefer path containing `.claude/plugins/` or `ceos-agents/`); fallback `**/docs/reference/trackers.md`; last resort `docs/reference/trackers.md`. If not found → use hardcoded defaults per tracker type.
     Read the Instance & Project Defaults table from `{trackers_md_path}` for the given type.)
```

---

### Task 1.4: Migrate core/mcp-detection.md — bare path note
- **File:** `core/mcp-detection.md`
- **AC coverage:** AC-1, AC-5
- **Dependencies:** Task 1.0
- **Parallel group:** B
- **Description:** Add a path-note blockquote between the `## Process` heading (line 17) and Process step 1 (line 19). This note clarifies that calling skills must resolve the path via Glob and that the inline table is a static built-in fallback.
- **Edits:**

**Edit 1 — Insert path-note between lines 17 and 19:**

Current text at lines 17–19:
```
## Process

1. **Look up MCP package and tool prefix** from the MCP Server Detection table in `docs/reference/trackers.md`:
```

Replace with:
```
## Process

> **Path note:** `trackers.md` (MCP Server Detection table) lives in the plugin installation
> directory, not in the consuming project. The calling skill must resolve the path via Glob before
> invoking this contract. The inline table in Process step 1 below is a static built-in fallback
> for callers that cannot Glob (e.g., callers that flow through `core/mcp-preflight.md`).

1. **Look up MCP package and tool prefix** from the MCP Server Detection table in `docs/reference/trackers.md`:
```

Note: The bare `docs/reference/trackers.md` reference on the step 1 line is retained intentionally — it is the inline table header, guarded by the path-note above. The test (T1/AC-2) allows exactly 1 such reference in mcp-detection.md.

---

### Task 3.1: Extend check-setup Step 10 with TLS treatment
- **File:** `skills/check-setup/SKILL.md`
- **AC coverage:** AC-12, AC-13, AC-14, AC-15, AC-16
- **Dependencies:** none
- **Parallel group:** B
- **Description:** Replace the current Step 10 (lines 98–104) with an expanded version that adds TLS error classification as the first branch, curl probe logic with env-var URL derivation, NODE_OPTIONS hints (4 TLS variants + 1 catch-all), while preserving existing auth/not-found/tool-not-found branches.
- **Edits:**

**Edit 1 — Replace lines 98–104:**

Current text:
```
10. Verify source control connectivity: fetch metadata for the configured Remote (owner/repo) via MCP
    - Use MCP to fetch repository metadata for the Remote value from Automation Config
    - Success → [OK] "Source control — {owner/repo} reachable"
    - Auth error (401/403) → [FAIL] "Source control — authentication failed. Token needs repository:read scope (Gitea), repo scope (GitHub), or read_repository scope (GitLab)."
    - Not found (404) → [FAIL] "Source control — repository {owner/repo} not found. Verify Remote in Automation Config."
    - Tool not found (MCP server lacks repository metadata method) → [WARN] "Source control MCP: repository existence check not supported — skipping."
    - Timeout/unreachable → [FAIL] "Source control — MCP server not reachable. Verify server URL and token in .mcp.json."
```

Replace with:
```
10. Verify source control connectivity: fetch metadata for the configured Remote (owner/repo) via MCP
    - Use MCP to fetch repository metadata for the Remote value from Automation Config
    - Success → [OK] "Source control — {owner/repo} reachable"
    - On failure, classify the error in this order:
      1. **TLS error** (error contains any of: UNABLE_TO_VERIFY_LEAF_SIGNATURE, CERT_UNTRUSTED,
         SELF_SIGNED_CERT, self signed certificate, certificate verify failed, ERR_TLS_,
         DEPTH_ZERO_SELF_SIGNED_CERT, unable to get local issuer certificate):
         Derive {sc_base_url}: scan the SC MCP server entry in .mcp.json for a URL-like value
         in the `env` block (first value starting with `https://` or `http://`). If no URL found,
         check if the server command/package matches a well-known host (server-github → https://github.com,
         server-gitlab → https://gitlab.com). If neither yields a URL, skip the curl probe.
         If {sc_base_url} was derived, run a curl probe:
         - Check `which curl` — if curl is not available, skip probe and emit:
           [FAIL] "Source control — TLS error detected. Add NODE_OPTIONS: --use-system-ca to .mcp.json env block. (curl not available for confirmation probe)"
         - Run: `curl -s -o /dev/null -w "%{http_code}" --max-time 5 {sc_base_url}`
         - curl exit 0 and HTTP code != 000 →
           [FAIL] "Source control — server reachable but MCP connection failed (likely TLS) — add NODE_OPTIONS: --use-system-ca to the env block in .mcp.json"
         - curl exit non-zero or HTTP code 000 →
           [FAIL] "Source control — connection failed (TLS or network). If using a private CA, try NODE_OPTIONS: --use-system-ca. If server is remote, verify URL."
         If {sc_base_url} could not be derived (skip probe):
           [FAIL] "Source control — TLS error detected. If using a private CA (self-signed or corporate PKI), add NODE_OPTIONS: --use-system-ca to the env block in .mcp.json."
      2. **Auth error** (401/403) →
         [FAIL] "Source control — authentication failed. Token needs repository:read scope (Gitea), repo scope (GitHub), or read_repository scope (GitLab)."
      3. **Not found** (404) →
         [FAIL] "Source control — repository {owner/repo} not found. Verify Remote in Automation Config."
      4. **Tool not found** (MCP server lacks repository metadata method) →
         [WARN] "Source control MCP: repository existence check not supported — skipping."
      5. **Any other error** →
         [FAIL] "Source control — MCP server not reachable. Verify server URL and token in .mcp.json. If using a private CA (self-signed or corporate PKI), also try NODE_OPTIONS: --use-system-ca."
```

Key properties:
- TLS branch is position 1 (before auth) — satisfies AC-12 ordering requirement
- 4 NODE_OPTIONS occurrences in TLS sub-branches: curl-absent, curl-success, curl-failure, no-URL-derivable — satisfies AC-14
- 1 NODE_OPTIONS in catch-all (position 5) — satisfies AC-15 private CA hint
- All messages say "Source control" — satisfies AC-16
- Auth keeps per-platform scope names (repository:read, repo, read_repository) — satisfies AC-15
- Tool-not-found stays [WARN] — satisfies AC-15

---

### Task 2.1: Add error_type to core/mcp-detection.md Output Contract + Failure Handling
- **File:** `core/mcp-detection.md`
- **AC coverage:** AC-6, AC-7, AC-8, AC-9, AC-10, AC-11, AC-19
- **Dependencies:** Task 1.4 (both edit mcp-detection.md — 1.4 adds path-note near top, 2.1 adds error_type to Output/Failure sections lower down)
- **Parallel group:** C
- **Description:** Three changes: (a) add `error_type` field to Output Contract after line 52, (b) add `error_type` assignments to each Failure Handling bullet on lines 57–60, (c) add Classification Reference sub-section after line 61.

Note on line numbers: After Task 1.4 inserts 4 lines (path-note blockquote) between lines 17–19, all subsequent line numbers shift by +4. The edits below use **text matching** (old_string), not absolute line numbers, so they work regardless of shift.

- **Edits:**

**Edit 2.1a — Insert error_type field in Output Contract (after current line 52):**

Find:
```
- **error** (string or null): Error message if `mcp_available` is false, null otherwise
```

Replace with:
```
- **error** (string or null): Error message if `mcp_available` is false, null otherwise
- **error_type** (string or null): Classification of the error when `mcp_available` is false.
  Values: `"tls"` (certificate/TLS error), `"auth"` (authentication failure, 401/403),
  `"not_found"` (404 or DNS resolution failure), `"timeout"` (connection timeout or refused),
  `"unknown"` (unclassified error). `null` when `mcp_available` is true.
  See Failure Handling > Classification Reference for classification logic.
```

**Edit 2.1b — Update "No matching MCP tool found" bullet (current line 57):**

Find:
```
- **No matching MCP tool found:** Return `mcp_available: false`, `error: "No MCP tool matching prefix {tool_prefix} found in current session"`. Caller decides whether to block or downgrade.
```

Replace with:
```
- **No matching MCP tool found:** Return `mcp_available: false`, `error: "No MCP tool matching prefix {tool_prefix} found in current session"`, `error_type: "unknown"`. Caller decides whether to block or downgrade.
```

**Edit 2.1c — Update "Read connectivity fails" bullet (current line 58):**

Find:
```
- **Read connectivity fails:** Return `mcp_available: false`, `error: "{error message from failed test call}"`. Caller decides action.
```

Replace with:
```
- **Read connectivity fails:** Return `mcp_available: false`, `error: "{error message from failed test call}"`, `error_type: {classified per Classification Reference below}`. Caller decides action.
```

**Edit 2.1d — Update "Write canary create fails" bullet (current line 59):**

Find:
```
- **Write canary create fails:** Return `mcp_available: true`, `write_available: false`, `write_error: "{error from canary create}"`. Caller decides action (warn, downgrade, or ignore).
```

Replace with:
```
- **Write canary create fails:** Return `mcp_available: true`, `write_available: false`, `write_error: "{error from canary create}"`, `error_type: null`. Caller decides action (warn, downgrade, or ignore).
```

**Edit 2.1e — Update "Write canary delete fails" bullet (current line 60):**

Find:
```
- **Write canary delete fails (create succeeded):** Return `mcp_available: true`, `write_available: true`, `write_cleanup_failed: true`, `write_error: "Canary item created but not deleted — manual cleanup needed"`. Write access demonstrably works; the cleanup failure is advisory.
```

Replace with:
```
- **Write canary delete fails (create succeeded):** Return `mcp_available: true`, `write_available: true`, `write_cleanup_failed: true`, `write_error: "Canary item created but not deleted — manual cleanup needed"`, `error_type: null`. Write access demonstrably works; the cleanup failure is advisory.
```

**Edit 2.1f — Insert Classification Reference sub-section (after current line 61, the "Unknown tracker type" bullet):**

Find:
```
- **Unknown tracker type:** Attempt detection with derived prefix `mcp__{tracker_type}__*`. Return `mcp_available: false` only if tool is actually missing — never block on unknown type alone.
```

Replace with:
```
- **Unknown tracker type:** Attempt detection with derived prefix `mcp__{tracker_type}__*`. Return `mcp_available: false` only if tool is actually missing — never block on unknown type alone.

### Classification Reference

Classify the error string in priority order (first match wins):

| Priority | error_type | Trigger patterns |
|----------|-----------|-----------------|
| 1 | `"tls"` | UNABLE_TO_VERIFY_LEAF_SIGNATURE, CERT_UNTRUSTED, SELF_SIGNED_CERT, self signed certificate, certificate verify failed, ERR_TLS_, DEPTH_ZERO_SELF_SIGNED_CERT, unable to get local issuer certificate |
| 2 | `"auth"` | 401, 403, unauthorized, forbidden, invalid token, authentication |
| 3 | `"not_found"` | 404, not_found, not found, ENOTFOUND, EAI_AGAIN |
| 4 | `"timeout"` | timeout, ETIMEDOUT, ECONNREFUSED, ECONNRESET |
| 5 | `"unknown"` | All remaining errors |

Note: `ECONNREFUSED` is classified under `"timeout"` (not `"not_found"`) because the server address resolved but the connection was refused — the remediation is "verify the server is running and the port is correct", which aligns with timeout/unreachable guidance. `ENOTFOUND` and `EAI_AGAIN` are classified under `"not_found"` because these are DNS resolution failures — the hostname does not resolve.

Pattern matching reuses the same string patterns as `skills/check-setup/SKILL.md` Step 9.
```

---

### Task 2.2: Update check-setup Step 9 cross-reference note
- **File:** `skills/check-setup/SKILL.md`
- **AC coverage:** AC-11
- **Dependencies:** Task 2.1 (error_type contract must exist before referencing it), Task 3.1 (both edit check-setup — Task 3.1 edits Step 10, Task 2.2 adds a note after Step 9. Since Step 9 ends at line 97 and Step 10 starts at line 98, these edits are in adjacent but non-overlapping regions. However, Task 3.1 replaces lines 98-104 — to avoid line drift, Task 2.2 should run AFTER Task 3.1.)
- **Parallel group:** D
- **Description:** No structural change to Step 9 (it already has its own inline classification). Add a brief cross-reference note at the end of Step 9's catch-all bullet (line 97) pointing to `core/mcp-detection.md` Classification Reference. This satisfies AC-11's requirement that mcp-detection.md contains a cross-reference to check-setup Step 9 (the reference is bidirectional — mcp-detection references Step 9 via Task 2.1f, and this task is a no-op confirmation).

**Actually:** AC-11 only requires that `core/mcp-detection.md` contains a cross-reference to `check-setup Step 9`. This is already satisfied by Task 2.1f's last line: "Pattern matching reuses the same string patterns as `skills/check-setup/SKILL.md` Step 9." No additional edit to check-setup/SKILL.md is needed for AC-11.

**Edit:** NONE — Task 2.1f already satisfies AC-11. This task is a verification-only step.

**Verification:** After Task 2.1f, confirm `core/mcp-detection.md` contains `check-setup` and `Step 9` on the same line or nearby.

---

### Task 2.3: Update skills/init/SKILL.md to reference error_type from mcp-detection
- **File:** `skills/init/SKILL.md`
- **AC coverage:** AC-11 (caller delegation)
- **Dependencies:** Task 2.1
- **Parallel group:** D
- **Description:** The init skill calls `core/mcp-detection.md` at Step 7 (connectivity validation). The current Step 7 uses the output fields `mcp_available` and `error`. With the new `error_type` field, init can now use it for more specific error messages. Add a brief note to Step 7's failure branch to reference `error_type`.
- **Edits:**

**Edit 1 — Enhance Step 7 failure message (current line 263):**

Find:
```
   - If `mcp_available: false` → `"[FAIL] {server_name}: {error}. Check your token and URL."`
```

Replace with:
```
   - If `mcp_available: false` → `"[FAIL] {server_name}: {error}. Check your token and URL."` (If `error_type` is `"tls"`, append: `" Try adding NODE_OPTIONS: --use-system-ca to the env block in .mcp.json."`)
```

---

### Task 4.1: Copy test file to test scenarios directory + run full suite
- **File:** `tests/scenarios/v644-diagnostics-hardening.sh`
- **AC coverage:** AC-1 through AC-16, AC-18
- **Dependencies:** Tasks 1.1, 1.2, 1.3, 1.4, 2.1, 2.2, 2.3, 3.1
- **Parallel group:** E
- **Description:** Copy the pre-written test file from `.forge/phase-5-tdd/tests/v644-diagnostics-hardening.sh` to `tests/scenarios/v644-diagnostics-hardening.sh`. Then run the full test suite: (1) the new v6.4.4 test, and (2) the existing `tests/scenarios/check-setup-improvements.sh` to verify AC-18 regression safety.
- **Edits:**

```bash
cp .forge/phase-5-tdd/tests/v644-diagnostics-hardening.sh tests/scenarios/v644-diagnostics-hardening.sh
bash tests/scenarios/v644-diagnostics-hardening.sh
bash tests/scenarios/check-setup-improvements.sh
```

If any test fails, the implementor must fix the failing source file before proceeding.

---

## Dependency Graph

```
Task 1.0 (template)
  │
  ├── Task 1.1 (onboard)       ──┐
  ├── Task 1.2 (scaffold)       ──┤
  ├── Task 1.3 (init)           ──┤── Group B (parallel)
  ├── Task 1.4 (mcp-detection)  ──┤
  └── Task 3.1 (check-setup)    ──┘
         │                          │
         │                          │
         └── Task 2.1 (mcp-detection error_type) ── Group C (sequential after 1.4)
                │
                ├── Task 2.2 (check-setup cross-ref — NOOP verification)  ──┐── Group D (parallel)
                └── Task 2.3 (init error_type usage)                       ──┘
                         │
                         └── Task 4.1 (test copy + test run) ── Group E
```

## AC-to-Task Mapping

| AC | Tasks |
|----|-------|
| AC-1 (path-note blockquotes) | 1.1, 1.2, 1.3, 1.4 |
| AC-2 (no bare path as direct Read) | 1.1, 1.2, 1.3 |
| AC-3 (resolve-once reuse) | 1.1, 1.2 |
| AC-4 ([WARN] fallback) | 1.1, 1.2, 1.3 |
| AC-5 (3-layer Glob pattern) | 1.1, 1.2, 1.3 |
| AC-6 (error_type in Output Contract) | 2.1 |
| AC-7 (Classification Reference section) | 2.1 |
| AC-8 (TLS pattern parity) | 2.1 |
| AC-9 (auth pattern parity) | 2.1 |
| AC-10 (not_found + timeout patterns) | 2.1 |
| AC-11 (cross-reference to Step 9) | 2.1, 2.2, 2.3 |
| AC-12 (Step 10 TLS branch) | 3.1 |
| AC-13 (Step 10 curl probe) | 3.1 |
| AC-14 (Step 10 NODE_OPTIONS >= 4) | 3.1 |
| AC-15 (Step 10 retains branches) | 3.1 |
| AC-16 (Step 10 "Source control") | 3.1 |
| AC-17 (no CLAUDE.md changes) | (implicit — no task touches CLAUDE.md) |
| AC-18 (existing tests pass) | 4.1 |
| AC-19 (no new required config keys) | (implicit — no task modifies Input Contract) |

## Execution Summary

| Group | Tasks | Files touched | Estimated edits |
|-------|-------|--------------|-----------------|
| A | 1.0 | 0 | 0 (reference only) |
| B | 1.1, 1.2, 1.3, 1.4, 3.1 | 4 files | 5 insert/replace operations |
| C | 2.1 | 1 file | 6 edits (1 insert + 4 replace + 1 append) |
| D | 2.2, 2.3 | 1 file (2.3 only; 2.2 is NOOP) | 1 replace |
| E | 4.1 | 1 file (copy) | 1 copy + 2 test runs |
| **Total** | **10 tasks** | **5 source + 1 test** | **~13 edits** |
