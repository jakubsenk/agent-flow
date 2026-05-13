# Agent 2 Research Report — Questions 5–8
# Structured error_type Extension — MCP Detection & Error Classification

---

## Q5: `core/mcp-detection.md` — Full Analysis

**File path:** `core/mcp-detection.md`

### Current Structure

The file has four top-level sections:

1. **Purpose** (lines 3–7) — describes the contract and lists referencing files:
   > "Referenced by: `skills/scaffold/SKILL.md` (Step 0-MCP), `skills/init/SKILL.md` (Steps 3, 7)."
   Note: `skills/check-setup/SKILL.md` is NOT listed as a referencing file, even though it runs its own inline connectivity check. This is a documentation gap relevant to the extension.

2. **Input Contract** (lines 9–15) — 5 input fields (see below).

3. **Process** (lines 17–44) — 4 numbered steps.

4. **Output Contract** (lines 46–53) — 7 output fields (see below).

5. **Failure Handling** (lines 55–61) — 4 named failure scenarios.

---

### Current Input Contract

| Field | Type | Required | Default | Notes |
|-------|------|----------|---------|-------|
| `tracker_type` | string | yes | — | `youtrack`, `github`, `jira`, `linear`, `gitea`, `redmine` |
| `tracker_instance` | string | optional | — | Instance URL, connectivity check context |
| `tracker_project` | string | optional | — | Project key for read connectivity test |
| `service_type` | string | yes | — | `"tracker"` or `"sc"` |
| `check_write` | boolean | optional | false | If true, runs canary-write check |

---

### Current Output Contract (complete, verbatim from lines 46–53)

| Field | Type | Description |
|-------|------|-------------|
| `mcp_available` | boolean | `true` if MCP tool is accessible and read connectivity succeeds |
| `write_available` | boolean or null | `true` if canary-write succeeded (create + delete both OK), `false` if create failed, `null` if not tested (`check_write` was false) |
| `write_cleanup_failed` | boolean | `true` if canary was created but deletion failed (write works, but a stale canary item exists). `false` otherwise. |
| `package_name` | string | Expected MCP package name from lookup table |
| `tool_prefix` | string | Expected tool prefix pattern |
| `error` | string or null | Error message if `mcp_available` is false, null otherwise |
| `write_error` | string or null | Error message if `write_available` is false or `write_cleanup_failed` is true, null otherwise |

**CURRENT STATE:** No `error_type` field exists. The `error` field is a plain string or null. There is no structured classification of what kind of error occurred — that classification happens only in `check-setup/SKILL.md` Step 9, inline, by the caller.

---

### Current Error Handling in the Process Section

**Process step 3** (lines 33–37): "If connectivity fails: set `mcp_available = false`, capture error." — No classification, raw error captured.

**Process step 4** (lines 38–44): Canary write failure logic — sets `write_available = false` or `write_cleanup_failed = true`, captures `write_error`. Again no classification.

**Failure Handling section** (lines 55–61) — four scenarios:

1. **No matching MCP tool found:**
   `error: "No MCP tool matching prefix {tool_prefix} found in current session"` — static string, not classified.

2. **Read connectivity fails:**
   `error: "{error message from failed test call}"` — raw pass-through, not classified.

3. **Write canary create fails:**
   `write_error: "{error from canary create}"` — raw pass-through, not classified.

4. **Write canary delete fails (create succeeded):**
   `write_error: "Canary item created but not deleted — manual cleanup needed"` — static string.

5. **Unknown tracker type:**
   Attempt best-effort detection. `mcp_available: false` only if tool is actually missing — never block on unknown type alone.

**Key finding:** The `error` field is always a raw string from the failed test call, never classified. All error interpretation is deferred to callers.

---

## Q6: `skills/check-setup/SKILL.md` — Step 9 Error Classification Logic

**File path:** `skills/check-setup/SKILL.md`
**Relevant section:** Block 3: Connectivity, Step 9 (lines 80–104)

### Step 9: Issue Tracker Connectivity — Error Classification

The classification happens **inline in check-setup** (not in mcp-detection.md). The classification order is strict — checked in sequence, first match wins.

---

#### 1. TLS Error

**Line 83–93** — triggered when error string contains **any** of these patterns:

```
UNABLE_TO_VERIFY_LEAF_SIGNATURE
CERT_UNTRUSTED
SELF_SIGNED_CERT
self signed certificate
certificate verify failed
ERR_TLS_
DEPTH_ZERO_SELF_SIGNED_CERT
unable to get local issuer certificate
```

**Behavior after match:**
- Runs a `curl` probe to distinguish "server reachable but TLS mismatch" from "network unreachable"
- If `curl` unavailable → `[FAIL] "Issue tracker — TLS error detected. Add NODE_OPTIONS: --use-system-ca to .mcp.json env block. (curl not available for confirmation probe)"`
- If `curl` exits 0 and HTTP code != 000 → `[FAIL] "Issue tracker — server reachable but MCP connection failed (likely TLS) — add NODE_OPTIONS: --use-system-ca to the env block in .mcp.json"`
- If `curl` exits non-zero or HTTP code 000 → `[FAIL] "Issue tracker — connection failed (TLS or network). If using a private CA, try NODE_OPTIONS: --use-system-ca. If server is remote, verify URL."`

---

#### 2. Auth Error

**Line 94–95** — triggered when error string contains **any** of these patterns:

```
401
403
unauthorized
forbidden
invalid token
authentication
```

**Message:** `[FAIL] "Issue tracker — authentication failed — check your token in .mcp.json"`

---

#### 3. Timeout / Not Found / DNS — NOT SEPARATELY CLASSIFIED

**Line 96–97** — "Any other error" is a single catch-all category. There is **no separate classification** for:
- Timeout errors (no timeout-specific patterns)
- Not found / DNS errors (no DNS-specific patterns)
- These all fall into the catch-all below.

---

#### 4. Other / Unknown (catch-all)

**Line 96–97:**

```
[FAIL] "Issue tracker — server not reachable — verify the server is running and URL is correct. If using a private CA (self-signed or corporate PKI), also try NODE_OPTIONS: --use-system-ca."
```

No specific patterns — this is triggered by any error not matching TLS or Auth patterns.

---

### Step 10: Source Control Connectivity (lines 99–104)

Source control errors are classified separately with a **different and simpler** scheme (no inline pattern-matching, just HTTP status codes via MCP response structure):

| SC Error Type | Pattern | Message |
|--------------|---------|---------|
| Auth | 401/403 | "Source control — authentication failed. Token needs repository:read scope (Gitea), repo scope (GitHub), or read_repository scope (GitLab)." |
| Not Found | 404 | "Source control — repository {owner/repo} not found. Verify Remote in Automation Config." |
| Tool not found | MCP server lacks method | [WARN] "Source control MCP: repository existence check not supported — skipping." |
| Timeout/unreachable | (catch-all) | "Source control — MCP server not reachable. Verify server URL and token in .mcp.json." |

**Important note:** SC classification uses HTTP status codes (401, 403, 404), not error string pattern matching. This is architecturally different from the tracker classification.

---

### Error Pattern Summary (Source of Truth for error_type Enum Values)

Based on check-setup Step 9 as the canonical source:

| Category | Proposed enum value | Trigger patterns |
|---------|--------------------|--------------------|
| TLS certificate error | `tls` | `UNABLE_TO_VERIFY_LEAF_SIGNATURE`, `CERT_UNTRUSTED`, `SELF_SIGNED_CERT`, `self signed certificate`, `certificate verify failed`, `ERR_TLS_`, `DEPTH_ZERO_SELF_SIGNED_CERT`, `unable to get local issuer certificate` |
| Authentication failure | `auth` | `401`, `403`, `unauthorized`, `forbidden`, `invalid token`, `authentication` |
| Tool/prefix not found | `tool_not_found` | (structural — no MCP tool matches prefix, not a string pattern) |
| Other / unknown | `unknown` | (all remaining errors) |
| No error | `null` | (when `mcp_available: true`) |

**Gaps vs. check-setup Step 10 (SC):**
- Timeout errors: check-setup Step 10 has a "Timeout/unreachable" category for SC, but Step 9 does not distinguish timeouts for the tracker. Any timeout falls into "Other/unknown".
- Not found / DNS: check-setup Step 10 has a "Not found (404)" category for SC. No DNS-specific category exists in either step.

---

## Q7: `skills/init/SKILL.md` — Does It Call mcp-detection?

**File path:** `skills/init/SKILL.md`

### Where mcp-detection Is Referenced

**Step 3** (line 93, comment block):
```
<!-- MCP detection logic: see core/mcp-detection.md -->
```
This is informational only — it tells the reader where the lookup table lives. Step 3 uses the table from `core/mcp-detection.md` Process step 1 to look up package names and tool prefixes, but does NOT call mcp-detection as a subprocess and does NOT do error classification. It is a static lookup (tracker_type → package_name + tool_prefix).

**Step 0** (lines 33–34):
```
Validate `--tracker-type` (if provided) against the lookup table in `core/mcp-detection.md` Process step 1.
```
Again a static lookup — validates the user-provided tracker type against the known enum. No error classification.

**Step 1b** (lines 59–61):
```
Tracker type: Identify from MCP server package name using the reverse mapping from `core/mcp-detection.md` lookup table
```
Reverse lookup only (package_name → tracker_type). No error classification.

**Step 7** (lines 251–263, comment and connectivity check):
```
<!-- MCP connectivity: see core/mcp-detection.md -->
```
This is the only place where init actively invokes the mcp-detection logic (connectivity check, with `check_write: false`):

```
Follow `core/mcp-detection.md` (with `check_write: false`):
  - If `mcp_available: true` → "[OK] {server_name} connected successfully"
  - If `mcp_available: false` → "[FAIL] {server_name}: {error}. Check your token and URL."
```

### Error Parsing in init Step 7

**init does NOT classify errors.** It passes the raw `error` field directly from mcp-detection to the user:

- Line 262: `"[FAIL] {server_name}: {error}. Check your token and URL."`

No TLS/auth/timeout pattern matching. The `error` string from mcp-detection is displayed verbatim. The user sees the raw error message from the failed connectivity test.

**Contrast with check-setup:** check-setup has a full inline classification engine (Step 9) before displaying any message. init simply passes through the raw error.

### Summary

- init calls mcp-detection: **YES** — in Step 7 for connectivity validation after generating `.mcp.json`
- init has its own error parsing logic: **NO** — raw `{error}` passthrough only
- init references mcp-detection lookup table: **YES** — in Steps 0, 3, 1b for static lookups
- init classifies errors: **NO**

---

## Q8: `skills/fix-bugs/SKILL.md` and `skills/fix-ticket/SKILL.md` — MCP Detection Calls

### fix-ticket/SKILL.md

**File path:** `skills/fix-ticket/SKILL.md`

**MCP-detection reference:** Step 0 (line 83):
```
Follow `core/mcp-preflight.md` to verify MCP server availability.
```

fix-ticket does **NOT** reference `core/mcp-detection.md` directly. It delegates to `core/mcp-preflight.md` (a different core file). This is a level of indirection — mcp-preflight.md presumably wraps or calls mcp-detection, but fix-ticket itself has no direct mcp-detection reference.

**Error classification in fix-ticket:** None. If MCP is not available, the pre-flight check blocks the pipeline via the standard block handler mechanism (step X). There is no inline error pattern matching.

**Block context** (lines 95–103): The Config Validity Gate uses a structured block comment, but this is for config validation, not MCP errors.

The `[ceos-agents] 🔴 Pipeline Block` format is used for all blocks, but no error_type classification for connectivity failures.

---

### fix-bugs/SKILL.md

**File path:** `skills/fix-bugs/SKILL.md`

**MCP-detection reference:** Step 0 (line 82):
```
Follow `core/mcp-preflight.md` to verify MCP server availability.
```

Identical pattern to fix-ticket — delegates to `core/mcp-preflight.md`, not to `core/mcp-detection.md` directly.

**Lines 83–86** (inline MCP check logic after the core reference):
```
Before any pipeline operation, verify MCP tool availability:
- Read Type from Automation Config (Issue Tracker section)
- Check that at least one `mcp__*` tool matching the tracker type is accessible
- If not accessible → STOP with: "Cannot connect to your {Type} issue tracker. Is the {Type} integration configured? Run `/ceos-agents:check-setup` for diagnostics."
```

**Error classification in fix-bugs:** None. Only a binary accessible/not-accessible check with a single fixed error message. No pattern matching, no error_type categories.

---

### Comparison Table: All Callers of mcp-detection

| Caller | References mcp-detection | Invokes connectivity check | Error classification | Via |
|--------|-------------------------|---------------------------|---------------------|-----|
| `check-setup/SKILL.md` | No direct reference | Yes (inline, Step 9) | Full (TLS / Auth / Other) | Inline (no core delegation) |
| `init/SKILL.md` | Yes (Steps 0, 1b, 3, 7) | Yes (Step 7) | None — raw passthrough | `core/mcp-detection.md` directly |
| `fix-ticket/SKILL.md` | No | Via mcp-preflight | None | `core/mcp-preflight.md` |
| `fix-bugs/SKILL.md` | No | Via mcp-preflight | None — single fixed message | `core/mcp-preflight.md` |
| `scaffold/SKILL.md` | Referenced in mcp-detection Purpose | Yes (Step 0-MCP) | Unknown (not read) | `core/mcp-detection.md` |

---

## Dependencies Between Questions

- **Q5 → Q6:** The `error` field in mcp-detection (Q5) is the raw string that check-setup Step 9 (Q6) pattern-matches to produce error categories. If `error_type` is added to mcp-detection's output contract, it would replace the inline classification in check-setup.

- **Q6 → Q8:** fix-bugs and fix-ticket (Q8) currently bypass classification entirely (single fixed message). If mcp-detection gains `error_type`, these skills could surface richer diagnostics without adding their own classification logic.

- **Q7 → Q5:** init's Step 7 (Q7) uses mcp-detection output but only accesses the `error` field. Adding `error_type` to mcp-detection output contract (Q5) would be immediately usable by init for richer error messages without any init logic change.

- **Q6 defines the enum:** The TLS and Auth pattern lists from check-setup Step 9 are the only existing classification logic in the entire codebase. These are the canonical source of truth for what the `error_type` enum values should be.

---

## Key Findings Summary

1. **mcp-detection has no error_type field today.** The `error` field is always a raw string.

2. **Only one file classifies errors:** `check-setup/SKILL.md` Step 9, with inline pattern matching against 8 TLS patterns and 6 auth patterns. Everything else is a catch-all.

3. **init passes through raw errors** without any classification. It is the most likely beneficiary of an `error_type` field.

4. **fix-bugs and fix-ticket do not call mcp-detection directly.** They go through `core/mcp-preflight.md`. Classification extension for these pipelines would require updating mcp-preflight, not mcp-detection alone.

5. **check-setup is NOT listed as a referencing file in mcp-detection.md's Purpose section.** This is a documentation gap — check-setup runs its own connectivity check inline (Step 9) rather than delegating to mcp-detection.

6. **No timeout-specific or DNS-specific error patterns exist** anywhere in the codebase. These would be new categories if added to `error_type`.
