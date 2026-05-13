# Implementation Design: v6.4.4 Connectivity Diagnostics Hardening

Version: v6.4.4 (PATCH)
Date: 2026-04-11

---

## Implementation Order

All changes follow this strict ordering to avoid line-number drift:

| Order | File | Work Items | Notes |
|-------|------|-----------|-------|
| 1 | `core/mcp-detection.md` | Item 2 (error_type) then Item 1 (path-note) | error_type changes first (structural), then path-note (additive prose) |
| 2 | `skills/check-setup/SKILL.md` | Item 3 (Step 10 TLS) | Independent single-file edit |
| 3 | `skills/init/SKILL.md` | Item 1 (single bare ref) | Single inline resolve |
| 4 | `skills/onboard/SKILL.md` | Item 1 (6 bare refs) | Resolve-once at Step 2 |
| 5 | `skills/scaffold/SKILL.md` | Item 1 (4 bare refs, chunked reads) | Resolve-once at Step 0-INFRA |

Post-edit verification: Confirm `core/mcp-preflight.md` is NOT affected (no changes needed).

---

## File 1: core/mcp-detection.md

### Change 1A: Add error_type to Output Contract (after line 52)

**Current text (line 52):**
```markdown
- **error** (string or null): Error message if `mcp_available` is false, null otherwise
```

**Insert AFTER line 52 (new line 53):**
```markdown
- **error_type** (string or null): Classification of the error when `mcp_available` is false.
  Values: `"tls"` (certificate/TLS error), `"auth"` (authentication failure, 401/403),
  `"not_found"` (404 or DNS resolution failure), `"timeout"` (connection timeout or refused),
  `"unknown"` (unclassified error). `null` when `mcp_available` is true.
  See Failure Handling > Classification Reference for classification logic.
```

### Change 1B: Add error_type assignments to Failure Handling scenarios (lines 57-61)

**Current line 57:**
```markdown
- **No matching MCP tool found:** Return `mcp_available: false`, `error: "No MCP tool matching prefix {tool_prefix} found in current session"`. Caller decides whether to block or downgrade.
```

**Replace with:**
```markdown
- **No matching MCP tool found:** Return `mcp_available: false`, `error: "No MCP tool matching prefix {tool_prefix} found in current session"`, `error_type: "unknown"`. Caller decides whether to block or downgrade.
```

**Current line 58:**
```markdown
- **Read connectivity fails:** Return `mcp_available: false`, `error: "{error message from failed test call}"`. Caller decides action.
```

**Replace with:**
```markdown
- **Read connectivity fails:** Return `mcp_available: false`, `error: "{error message from failed test call}"`, `error_type: {classified per Classification Reference below}`. Caller decides action.
```

**Lines 59-60 (write canary scenarios): No change to structure.** Add clarification at end of each:

**Current line 59:**
```markdown
- **Write canary create fails:** Return `mcp_available: true`, `write_available: false`, `write_error: "{error from canary create}"`. Caller decides action (warn, downgrade, or ignore).
```

**Replace with:**
```markdown
- **Write canary create fails:** Return `mcp_available: true`, `write_available: false`, `write_error: "{error from canary create}"`, `error_type: null`. Caller decides action (warn, downgrade, or ignore).
```

**Current line 60:**
```markdown
- **Write canary delete fails (create succeeded):** Return `mcp_available: true`, `write_available: true`, `write_cleanup_failed: true`, `write_error: "Canary item created but not deleted — manual cleanup needed"`. Write access demonstrably works; the cleanup failure is advisory.
```

**Replace with:**
```markdown
- **Write canary delete fails (create succeeded):** Return `mcp_available: true`, `write_available: true`, `write_cleanup_failed: true`, `write_error: "Canary item created but not deleted — manual cleanup needed"`, `error_type: null`. Write access demonstrably works; the cleanup failure is advisory.
```

### Change 1C: Add Classification Reference sub-section (after line 61, at end of Failure Handling)

**Insert after the last Failure Handling bullet (line 61 "Unknown tracker type") and before end of file:**

```markdown

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

### Change 1D: Add path-note blockquote (before line 19, before Process step 1)

**Current text (lines 17-19):**
```markdown
## Process

1. **Look up MCP package and tool prefix** from the MCP Server Detection table in `docs/reference/trackers.md`:
```

**Insert between `## Process` heading and step 1:**
```markdown
## Process

> **Path note:** `trackers.md` (MCP Server Detection table) lives in the plugin installation
> directory, not in the consuming project. The calling skill must resolve the path via Glob before
> invoking this contract. The inline table in Process step 1 below is a static built-in fallback
> for callers that cannot Glob (e.g., callers that flow through `core/mcp-preflight.md`).

1. **Look up MCP package and tool prefix** from the MCP Server Detection table in `docs/reference/trackers.md`:
```

---

## File 2: skills/check-setup/SKILL.md

### Change 2A: Replace Step 10 (lines 98-104)

**Current text (lines 98-104):**
```markdown
10. Verify source control connectivity: fetch metadata for the configured Remote (owner/repo) via MCP
    - Use MCP to fetch repository metadata for the Remote value from Automation Config
    - Success → [OK] "Source control — {owner/repo} reachable"
    - Auth error (401/403) → [FAIL] "Source control — authentication failed. Token needs repository:read scope (Gitea), repo scope (GitHub), or read_repository scope (GitLab)."
    - Not found (404) → [FAIL] "Source control — repository {owner/repo} not found. Verify Remote in Automation Config."
    - Tool not found (MCP server lacks repository metadata method) → [WARN] "Source control MCP: repository existence check not supported — skipping."
    - Timeout/unreachable → [FAIL] "Source control — MCP server not reachable. Verify server URL and token in .mcp.json."
```

**Replace with:**
```markdown
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

### Key design decisions for Step 10:

- **TLS branch is position 1** (before auth), matching Step 9's cascade order.
- **{sc_base_url} derivation** uses env-var scan (not Remote string parsing, not nonexistent `.mcp.json` URL fields). Two-tier: env-var first, well-known host fallback second.
- **"likely TLS"** wording preserved in curl-success branch (curl probe is a heuristic, not a definitive TLS diagnosis).
- **4 NODE_OPTIONS occurrences** in TLS sub-branches: curl-absent, curl-success, curl-failure, no-URL-derivable.
- **1 NODE_OPTIONS occurrence** in catch-all (position 5): soft hint for private CA.
- **Auth message** keeps per-platform scope names (repository:read, repo, read_repository) — more actionable than Step 9's generic message.
- **Tool-not-found** remains [WARN] (not [FAIL]) — SC-specific.

---

## File 3: skills/init/SKILL.md

### Change 3A: Add Glob resolution and path-note at Step 0 (before line 36)

**Current text (lines 35-36):**
```markdown
   - **Type** = `cli_tracker_type` (if not provided, infer from `cli_sc_remote` hostname: `github.com` → `github`; otherwise → error: `"--tracker-type is required when CLAUDE.md is not available."`)
   - **Instance** = `cli_tracker_instance` (if not provided, use default from `docs/reference/trackers.md` Instance & Project Defaults table for the given type)
```

**Replace line 36 with:**
```markdown
   - **Instance** = `cli_tracker_instance` (if not provided, derive default:
     > **Path note:** `trackers.md` lives in the plugin installation directory. Resolve via Glob before reading defaults.

     Resolve `{trackers_md_path}`: Glob `.claude/plugins/**/docs/reference/trackers.md` (prefer path containing `.claude/plugins/` or `ceos-agents/`); fallback `**/docs/reference/trackers.md`; last resort `docs/reference/trackers.md`. If not found → use hardcoded defaults per tracker type.
     Read the Instance & Project Defaults table from `{trackers_md_path}` for the given type.)
```

---

## File 4: skills/onboard/SKILL.md

### Change 4A: Add Glob resolution block before sub-step 2 of Step 2 (before line 68)

**Current text (lines 66-68):**
```markdown
Ask step by step:

1. Which issue tracker do you use? (youtrack / github / jira / linear / gitea / redmine)
2. Instance URL — read defaults from `docs/reference/trackers.md` Instance & Project Defaults table
```

**Insert between sub-step 1 and sub-step 2 (after line 67, before line 68):**
```markdown
> **Path note:** `trackers.md` lives in the plugin installation directory, not in the consuming
> project. Glob is used to handle CWD-context mismatch.

Resolve `{trackers_md_path}` once:
1. Glob `.claude/plugins/**/docs/reference/trackers.md` — if results, use first (prefer path containing `.claude/plugins/` or `ceos-agents/`; if ambiguous → [WARN] "Multiple trackers.md found — using {path}.")
2. Glob `**/docs/reference/trackers.md` — use first result if step 1 found nothing
3. Use `docs/reference/trackers.md` as last resort
If not found → [WARN] "trackers.md not found — using built-in defaults for this tracker type." and use default values from knowledge.
```

### Change 4B: Replace all 6 bare references with {trackers_md_path}

Replace each occurrence of `` `docs/reference/trackers.md` `` with `` `{trackers_md_path}` `` on the following lines:

| Line | Current text (relevant portion) | Replacement |
|------|---------------------------------|-------------|
| 68 | `read defaults from \`docs/reference/trackers.md\` Instance & Project Defaults table` | `read defaults from \`{trackers_md_path}\` Instance & Project Defaults table` |
| 70 | `read defaults from \`docs/reference/trackers.md\` Query Syntax table` | `read defaults from \`{trackers_md_path}\` Query Syntax table` |
| 72 | `read defaults from \`docs/reference/trackers.md\` Query Syntax table` | `read defaults from \`{trackers_md_path}\` Query Syntax table` |
| 75 | `read defaults from \`docs/reference/trackers.md\` State Transition Syntax table` | `read defaults from \`{trackers_md_path}\` State Transition Syntax table` |
| 76 | `read defaults from \`docs/reference/trackers.md\` On Start Set Defaults table` | `read defaults from \`{trackers_md_path}\` On Start Set Defaults table` |
| 108 | `read from \`docs/reference/trackers.md\` PR Description Footer table` | `read from \`{trackers_md_path}\` PR Description Footer table` |

---

## File 5: skills/scaffold/SKILL.md

**Implementation note:** This file exceeds the single-read limit. Read in chunks: lines 1-300, lines 300-600.

### Change 5A: Add Glob resolution block at Step 0-INFRA (before line 93, inside "If tracker = ready" block)

**Current text (lines 91-93):**
```markdown
**If tracker = "ready":** Collect details:
- Tracker type: `[youtrack/github/jira/linear/gitea/redmine]`
- Instance URL (show format example from `docs/reference/trackers.md` Instance & Project Defaults table)
```

**Insert between "Collect details:" and the list items (after line 91, before line 92):**
```markdown
> **Path note:** `trackers.md` lives in the plugin installation directory, not in the consuming
> project. Glob is used to handle CWD-context mismatch.

Resolve `{trackers_md_path}` once at the start of Step 0-INFRA:
1. Glob `.claude/plugins/**/docs/reference/trackers.md` — if results, prefer path containing `.claude/plugins/` or `ceos-agents/`
2. Glob `**/docs/reference/trackers.md` — fallback if step 1 empty
3. `docs/reference/trackers.md` — bare CWD-relative last resort
If not found → [WARN] "trackers.md not found — using built-in defaults." and proceed with inline knowledge.
```

### Change 5B: Replace all 4 bare references with {trackers_md_path}

| Line | Current text (relevant portion) | Replacement |
|------|---------------------------------|-------------|
| 93 | `from \`docs/reference/trackers.md\` Instance & Project Defaults table` | `from \`{trackers_md_path}\` Instance & Project Defaults table` |
| 169 | `from \`docs/reference/trackers.md\`` | `from \`{trackers_md_path}\`` |
| 484 | `from \`docs/reference/trackers.md\`` | `from \`{trackers_md_path}\`` |
| 543 | `in \`docs/reference/trackers.md\`` | `in \`{trackers_md_path}\`` |

### Scaffold tracker = "later" guard

When `tracker_effective_status` is `"later"`, the `{trackers_md_path}` variable is never resolved. Lines 484 (Step 4b-replaced) and 543 (Step 4e) are guarded by existing conditionals:

- **Line 484 (Step 4b-replaced):** Inside "Based on `tracker_type` from Step 0-INFRA (if tracker was declared)" — when tracker = later, `tracker_type` is null, so this block is skipped.
- **Line 543 (Step 4e):** Guard clause at line 522-525: "skip this step if `tracker_effective_status` is NOT `ready`" — when tracker = later, Step 4e is skipped entirely.

These are no-ops when `{trackers_md_path}` was not resolved. No additional guard is needed.

---

## Canonical Glob Resolution Block (reference pattern)

This is the exact resolution block from `skills/check-setup/SKILL.md` Step 3a (lines 32-38) that all new resolution blocks must match:

```markdown
> **Path note:** `trackers.md` lives in the plugin installation directory, not in the consuming
> project. Glob is used to handle CWD-context mismatch.

Locate `trackers.md`: Glob with pattern `.claude/plugins/**/docs/reference/trackers.md` first.
If no results, Glob with `**/docs/reference/trackers.md`. If still none, try `docs/reference/trackers.md` relative to CWD.
If multiple results, prefer the path containing `.claude/plugins/` or `ceos-agents/`; if ambiguous → [WARN] "Multiple trackers.md found — using {path}."
If the file cannot be found → [WARN] "{file-specific skip message}" and {file-specific fallback behavior}.
```

**Three-layer order (invariant):**
1. `.claude/plugins/**/docs/reference/trackers.md` — narrow plugin directory first
2. `**/docs/reference/trackers.md` — broad recursive fallback
3. `docs/reference/trackers.md` — bare CWD-relative last resort

**Preference logic (invariant):** prefer path containing `.claude/plugins/` or `ceos-agents/`

---

## error_type Classification Reference Table (canonical)

This table is inserted into `core/mcp-detection.md` and serves as the single source of truth for error classification:

| Priority | error_type | Trigger patterns |
|----------|-----------|-----------------|
| 1 | `"tls"` | UNABLE_TO_VERIFY_LEAF_SIGNATURE, CERT_UNTRUSTED, SELF_SIGNED_CERT, self signed certificate, certificate verify failed, ERR_TLS_, DEPTH_ZERO_SELF_SIGNED_CERT, unable to get local issuer certificate |
| 2 | `"auth"` | 401, 403, unauthorized, forbidden, invalid token, authentication |
| 3 | `"not_found"` | 404, not_found, not found, ENOTFOUND, EAI_AGAIN |
| 4 | `"timeout"` | timeout, ETIMEDOUT, ECONNREFUSED, ECONNRESET |
| 5 | `"unknown"` | All remaining errors |

**Semantics:** First match wins. An error containing both TLS and auth patterns is classified as `tls` (priority 1 > priority 2).

**Grouping rationale:**
- ECONNREFUSED → `"timeout"`: server address resolved but connection refused. Remediation: "verify the server is running and the port is correct."
- ENOTFOUND, EAI_AGAIN → `"not_found"`: DNS resolution failure. Remediation: "verify the hostname is correct."

---

## Step 10 TLS Treatment Block (canonical)

This is the exact replacement text for Step 10 in `skills/check-setup/SKILL.md`. The {sc_base_url} derivation uses env-var scan from `.mcp.json`, not Remote string parsing.

### SC Base URL Derivation Logic

```
Derive {sc_base_url} for the curl probe:
1. ENV-VAR SCAN: Read the SC MCP server entry from .mcp.json (already parsed in Step 6/7).
   Scan its `env` block for the first value that starts with `https://` or `http://`.
   Known env var names by tracker/SC type:
   - Gitea/Forgejo: FORGEJO_URL
   - YouTrack: YOUTRACK_URL
   - Jira: ATLASSIAN_URL
   - Redmine: REDMINE_HOST
   - GitHub: (no URL env var)
   - Linear: (no URL env var)
   - GitLab: GITLAB_URL (if/when supported)
   Use the extracted URL as {sc_base_url}.

2. WELL-KNOWN HOST FALLBACK: If no URL-like env value was found (e.g., GitHub, Linear):
   - SC server package/command contains "server-github" or "github" → {sc_base_url} = "https://github.com"
   - SC server package/command contains "server-gitlab" or "gitlab" → {sc_base_url} = "https://gitlab.com"
   - Otherwise → skip probe. Emit the no-URL-derivable variant of the TLS message.
```

### TLS Message Variants in Step 10

| Variant | Condition | Message |
|---------|-----------|---------|
| curl-absent | TLS error + `which curl` fails | `[FAIL] "Source control — TLS error detected. Add NODE_OPTIONS: --use-system-ca to .mcp.json env block. (curl not available for confirmation probe)"` |
| curl-success | TLS error + curl exits 0 + HTTP code != 000 | `[FAIL] "Source control — server reachable but MCP connection failed (likely TLS) — add NODE_OPTIONS: --use-system-ca to the env block in .mcp.json"` |
| curl-failure | TLS error + curl exits non-zero or HTTP 000 | `[FAIL] "Source control — connection failed (TLS or network). If using a private CA, try NODE_OPTIONS: --use-system-ca. If server is remote, verify URL."` |
| no-URL-derivable | TLS error + {sc_base_url} not derived | `[FAIL] "Source control — TLS error detected. If using a private CA (self-signed or corporate PKI), add NODE_OPTIONS: --use-system-ca to the env block in .mcp.json."` |
| catch-all | Any other error (not TLS/auth/404/tool) | `[FAIL] "Source control — MCP server not reachable. Verify server URL and token in .mcp.json. If using a private CA (self-signed or corporate PKI), also try NODE_OPTIONS: --use-system-ca."` |

---

## Files NOT Modified

| File | Reason |
|------|--------|
| `CLAUDE.md` | No config contract changes (PATCH scope) |
| `core/mcp-preflight.md` | error_type forwarding is out of scope (v6.5.0 follow-up) |
| `skills/check-setup/SKILL.md` Steps 3a, 7, 9 | Already correct in v6.4.3; no changes needed |
| `skills/fix-ticket/SKILL.md` | Uses mcp-preflight, not mcp-detection directly |
| `skills/fix-bugs/SKILL.md` | Uses mcp-preflight, not mcp-detection directly |
| `docs/reference/trackers.md` | Source of truth; not modified by this work |
