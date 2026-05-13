# Phase 2 Research Synthesis — Final

Synthesized from: Phase 1 `final.md`, expert prompt `research-answers.md`, and source file verification.
Date: 2026-04-11

---

## 1. Bare Path Migration Inventory

### Definitive Reference Table

| File | Line(s) | Reference type | Context (step/section) | Resolution strategy |
|------|---------|----------------|------------------------|---------------------|
| `skills/onboard/SKILL.md` | 68 | Look-up (Instance & Project Defaults) | Step 2, sub-step 2 | Resolve once at Step 2 start; reuse `trackers_md_path` |
| `skills/onboard/SKILL.md` | 70 | Look-up (Query Syntax) | Step 2, sub-step 4 | Reuse `trackers_md_path` |
| `skills/onboard/SKILL.md` | 72 | Look-up (Query Syntax — Feature column) | Step 2, sub-step 5 | Reuse `trackers_md_path` |
| `skills/onboard/SKILL.md` | 75 | Look-up (State Transition Syntax) | Step 2, sub-step 6 | Reuse `trackers_md_path` |
| `skills/onboard/SKILL.md` | 76 | Look-up (On Start Set Defaults) | Step 2, sub-step 7 | Reuse `trackers_md_path` |
| `skills/onboard/SKILL.md` | 108 | Look-up (PR Description Footer) | Step 4b | Reuse `trackers_md_path` (no second Glob) |
| `skills/scaffold/SKILL.md` | 93 | Look-up (Instance URL format example) | Step 0-INFRA, tracker = ready | Resolve once at Step 0-INFRA start; reuse `trackers_md_path` |
| `skills/scaffold/SKILL.md` | 169 | Look-up (required env vars / package name) | Step 0-MCP, failure guidance | Reuse `trackers_md_path` |
| `skills/scaffold/SKILL.md` | 484 | Look-up (MCP Server Detection table / package name) | Step 4b-replaced, generate .mcp.json.example | Reuse `trackers_md_path` |
| `skills/scaffold/SKILL.md` | 543 | Look-up (Sub-Issue Capabilities cross-reference) | Step 4e, native sub-issue creation | Reuse `trackers_md_path` |
| `skills/init/SKILL.md` | 36 | Look-up (Instance & Project Defaults — default Instance URL) | Step 0, `--tracker-instance` default derivation | Inline resolve at point of use; single reference |
| `core/mcp-detection.md` | 19 | Look-up (MCP Server Detection table) | Process step 1 | Path-note only; inline table at lines 20–29 is static fallback; callers must resolve |

**Total: 12 references across 4 files.**

---

### Resolve-Once vs. Inline Decision

| File | Strategy | Reason |
|------|----------|--------|
| `skills/onboard/SKILL.md` | Resolve once at Step 2 start | 6 references span Steps 2–4b (~40 lines); re-Glob would be redundant and inconsistent with check-setup Step 7 prohibition |
| `skills/scaffold/SKILL.md` | Resolve once at Step 0-INFRA start | 4 references span lines 93–543 (~450 lines); earliest reference is Step 0-INFRA |
| `skills/init/SKILL.md` | Inline at line 36 | Single reference; no Step 3a equivalent exists in init |
| `core/mcp-detection.md` | Path-note only; no Glob added | Not a skill; has no `allowed-tools` frontmatter; cannot execute tools |

---

### Path-Note Blockquote Placement

**`skills/onboard/SKILL.md` — insert before sub-step 2 of Step 2 (before line 68):**

```markdown
> **Path note:** `trackers.md` lives in the plugin installation directory, not in the consuming
> project. Glob is used to handle CWD-context mismatch.

Resolve `trackers_md_path` once:
1. Glob `.claude/plugins/**/docs/reference/trackers.md` — if results, use first (prefer path containing `.claude/plugins/` or `ceos-agents/`; if ambiguous → [WARN] "Multiple trackers.md found — using {path}.")
2. Glob `**/docs/reference/trackers.md` — use first result if step 1 found nothing
3. Use `docs/reference/trackers.md` as last resort
If not found → [WARN] "trackers.md not found — using built-in defaults for this tracker type." and use default values from knowledge.
```

**`skills/scaffold/SKILL.md` — insert at the start of Step 0-INFRA (before line 93, inside "If tracker = ready" block):**

```markdown
> **Path note:** `trackers.md` lives in the plugin installation directory, not in the consuming
> project. Glob is used to handle CWD-context mismatch.

Resolve `trackers_md_path` once at the start of Step 0-INFRA:
1. Glob `.claude/plugins/**/docs/reference/trackers.md` — if results, prefer path containing `.claude/plugins/` or `ceos-agents/`
2. Glob `**/docs/reference/trackers.md` — fallback if step 1 empty
3. `docs/reference/trackers.md` — bare CWD-relative last resort
If not found → [WARN] "trackers.md not found — using built-in defaults." and proceed with inline knowledge.
```

**`skills/init/SKILL.md` — insert inline at Step 0, immediately before the Instance default derivation (at/before line 36):**

```markdown
> **Path note:** `trackers.md` lives in the plugin installation directory. Resolve via Glob before reading defaults.

When `--tracker-instance` is not provided: Glob `.claude/plugins/**/docs/reference/trackers.md` (prefer `ceos-agents/` path); fallback to `**/docs/reference/trackers.md`; last resort `docs/reference/trackers.md`. If not found → use hardcoded defaults per tracker type.
```

**`core/mcp-detection.md` — insert after Process heading, before step 1 (before line 19):**

```markdown
> **Path note:** `trackers.md` (MCP Server Detection table) lives in the plugin installation
> directory, not in the consuming project. The calling skill must resolve the path via Glob before
> invoking this contract. The inline table in Process step 1 below is a static built-in fallback
> for callers that cannot Glob.
```

---

### Replacement Text Pattern

For all 6 references in `skills/onboard/SKILL.md` and all 4 in `skills/scaffold/SKILL.md`:
- Replace every occurrence of `` `docs/reference/trackers.md` `` with `` `{trackers_md_path}` `` (backtick-wrapped variable).
- Keep surrounding prose unchanged.

For the single reference in `skills/init/SKILL.md` (line 36):
- Replace `` `docs/reference/trackers.md` `` with `` `{trackers_md_path}` `` where the inline resolution block (inserted just above) defines the variable.

For `core/mcp-detection.md` (line 19):
- Do NOT replace the bare reference in the inline table. The table at lines 20–29 is the static fallback and must remain. Only add the path-note blockquote above Process step 1.

---

### Implementation Note: scaffold/SKILL.md File Size

`skills/scaffold/SKILL.md` exceeds the 10,000-token single-read limit. During implementation, read in at least two chunks:
- Chunk A: lines 1–300 (covers line 93)
- Chunk B: lines 300–600 (covers lines 169, 484, 543)

Edit each chunk independently; apply the resolve-once block only once at the Step 0-INFRA location.

---

## 2. error_type Enum Design

### Canonical Source

The canonical pattern for error classification is `skills/check-setup/SKILL.md` lines 82–97 (Step 9). The enum values come from the roadmap specification: `tls`, `auth`, `not_found`, `timeout`, `unknown`.

### String Pattern → Enum Mapping

| error_type value | Trigger patterns | Source |
|-----------------|-----------------|--------|
| `"tls"` | `UNABLE_TO_VERIFY_LEAF_SIGNATURE`, `CERT_UNTRUSTED`, `SELF_SIGNED_CERT`, `self signed certificate`, `certificate verify failed`, `ERR_TLS_`, `DEPTH_ZERO_SELF_SIGNED_CERT`, `unable to get local issuer certificate` | Step 9 TLS branch (8 patterns) |
| `"auth"` | `401`, `403`, `unauthorized`, `forbidden`, `invalid token`, `authentication` | Step 9 Auth branch (6 patterns) |
| `"not_found"` | `404`, `not_found`, `not found`, DNS-related errors (not observed in codebase; roadmap-specified addition) | Roadmap enum + Step 10 404 case |
| `"timeout"` | `timeout`, `ETIMEDOUT`, `ECONNREFUSED` (not observed as distinct patterns in Step 9; roadmap-specified addition) | Roadmap enum; currently falls into catch-all in Step 9 |
| `"unknown"` | Everything else — any error not matching the four categories above | Step 9 catch-all |
| `null` | No error — `mcp_available: true` | Normal success case |

**Gap note:** `not_found` and `timeout` are roadmap-specified values that do not currently appear as distinct classified branches in the codebase. Step 9 treats DNS, ECONNREFUSED, and timeout all as catch-all ("Any other error"). The `error_type` enum in `core/mcp-detection.md` should define all 5 values; callers (init, scaffold) can use them when present without requiring Step 9 to be refactored.

### enum Priority Order (first-match wins)

```
1. tls       ← check 8 string patterns first
2. auth      ← check 6 string patterns
3. not_found ← check 404 / not_found / DNS patterns
4. timeout   ← check timeout / ETIMEDOUT / ECONNREFUSED patterns
5. unknown   ← all remaining errors
```

### Output Contract Addition

Add to `core/mcp-detection.md` Output Contract table (after `error` row):

```markdown
- **error_type** (string or null): Classification of the error when `mcp_available` is false.
  Values: `"tls"` (certificate/TLS error), `"auth"` (authentication failure, 401/403),
  `"not_found"` (404 or DNS resolution failure), `"timeout"` (connection timeout or refused),
  `"unknown"` (unclassified error). `null` when `mcp_available` is true.
```

### Failure Handling Addition

Add `error_type` assignment to each scenario in the Failure Handling section:

| Scenario | error_type to set | Classification logic |
|----------|------------------|---------------------|
| No matching MCP tool found | `"unknown"` | Structural failure, not a network error |
| Read connectivity fails (TLS patterns match) | `"tls"` | Error string matches any of the 8 TLS patterns |
| Read connectivity fails (auth patterns match) | `"auth"` | Error string matches any of the 6 auth patterns |
| Read connectivity fails (404/not_found/DNS) | `"not_found"` | Error string contains 404, not_found, DNS |
| Read connectivity fails (timeout/ETIMEDOUT) | `"timeout"` | Error string contains timeout/ETIMEDOUT/ECONNREFUSED |
| Read connectivity fails (no pattern match) | `"unknown"` | Catch-all |
| Write canary create fails | `null` | Write errors are separate; `mcp_available` is still true |
| Write canary delete fails | `null` | Same — write errors do not affect `mcp_available` |

**Cross-reference note:** Add to the Failure Handling section: "Pattern matching for `error_type` classification reuses the same string patterns as `skills/check-setup/SKILL.md` Step 9."

### Caller Benefit Matrix

| Caller | Current error display | Benefit from error_type |
|--------|----------------------|------------------------|
| `skills/init/SKILL.md` Step 7 | Raw `{error}` string verbatim — no classification | Can display targeted messages: TLS → mention NODE_OPTIONS hint; auth → mention token check; immediately usable without additional logic |
| `skills/scaffold/SKILL.md` Step 0-MCP | Unknown (not fully read in Phase 1) | Same benefit as init — richer error guidance without inline pattern matching |
| `skills/check-setup/SKILL.md` Step 9 | Inline classification (canonical source) | No change needed — check-setup runs its own inline check, does not call mcp-detection directly |
| `core/mcp-preflight.md` → fix-ticket/fix-bugs | Single fixed message, no classification | Out of scope; would require mcp-preflight update (separate work item) |

---

## 3. Step 10 TLS Gap Analysis

### Current Step 10 (verbatim, lines 98–104)

```markdown
10. Verify source control connectivity: fetch metadata for the configured Remote (owner/repo) via MCP
    - Use MCP to fetch repository metadata for the Remote value from Automation Config
    - Success → [OK] "Source control — {owner/repo} reachable"
    - Auth error (401/403) → [FAIL] "Source control — authentication failed. Token needs repository:read scope (Gitea), repo scope (GitHub), or read_repository scope (GitLab)."
    - Not found (404) → [FAIL] "Source control — repository {owner/repo} not found. Verify Remote in Automation Config."
    - Tool not found (MCP server lacks repository metadata method) → [WARN] "Source control MCP: repository existence check not supported — skipping."
    - Timeout/unreachable → [FAIL] "Source control — MCP server not reachable. Verify server URL and token in .mcp.json."
```

### Gap Summary

| Gap | Description | Steps 9 counterpart |
|-----|-------------|---------------------|
| Gap 1 | No TLS error string detection | Step 9 lines 83–85: 8 patterns |
| Gap 2 | No `which curl` availability check | Step 9 line 87 |
| Gap 3 | No curl network reachability probe | Step 9 lines 89–93 |
| Gap 4 | No `NODE_OPTIONS: --use-system-ca` hint in TLS messages | Step 9 lines 88, 91, 93 |
| Gap 5 | No TLS/private CA hint in Timeout/unreachable catch-all | Step 9 line 96–97 |

### SC-Specific Adjustment: Curl Probe URL

**Problem:** Step 9 uses `{Instance}` — the full tracker URL from Automation Config. Step 10's Remote is `owner/repo` format (not a URL).

**Resolution:** The curl probe for Step 10 must target the SC MCP server's base URL, not `owner/repo` directly.

**Derivation rule (to add to Step 10):**

```
Derive {sc_base_url} for the curl probe:
- Read the MCP server entry for source control from .mcp.json (already verified in Step 6/7).
- Extract the base hostname from the MCP server configuration (the "url" or "baseUrl" field, or the server name that contains a hostname).
- If the SC remote contains a non-github.com / non-gitea.io hostname (self-hosted), that hostname is the probe target.
- If SC remote is github.com → probe target is "https://github.com"
- If SC remote is gitea.example.com (self-hosted) → probe target is "https://gitea.example.com"
- If base URL cannot be derived → skip probe (emit no-curl-available variant of TLS message).
```

**Alternative simpler rule:** Extract the hostname from the first component of the Remote (`owner/repo` → hostname of the git server from the SC MCP server config entry in `.mcp.json`). This is the most reliable source and avoids parsing ambiguous Remote strings.

### Step 10 — Complete Replacement Text

The following is the exact replacement for lines 98–104 of `skills/check-setup/SKILL.md`:

```markdown
10. Verify source control connectivity: fetch metadata for the configured Remote (owner/repo) via MCP
    - Use MCP to fetch repository metadata for the Remote value from Automation Config
    - Success → [OK] "Source control — {owner/repo} reachable"
    - On failure, classify the error in this order:
      1. **TLS error** (error contains any of: UNABLE_TO_VERIFY_LEAF_SIGNATURE, CERT_UNTRUSTED,
         SELF_SIGNED_CERT, self signed certificate, certificate verify failed, ERR_TLS_,
         DEPTH_ZERO_SELF_SIGNED_CERT, unable to get local issuer certificate):
         Derive {sc_base_url}: extract the base hostname from the SC MCP server entry in .mcp.json
         (e.g., `https://gitea.example.com` from a self-hosted remote, or `https://github.com`).
         Run a curl probe to confirm network reachability:
         - Check `which curl` — if curl is not available, skip probe and emit:
           [FAIL] "Source control — TLS error detected. Add NODE_OPTIONS: --use-system-ca to .mcp.json env block. (curl not available for confirmation probe)"
         - Run: `curl -s -o /dev/null -w "%{http_code}" --max-time 5 {sc_base_url}`
         - curl exit 0 and HTTP code != 000 →
           [FAIL] "Source control — server reachable but MCP connection failed (likely TLS) — add NODE_OPTIONS: --use-system-ca to the env block in .mcp.json"
         - curl exit non-zero or HTTP code 000 →
           [FAIL] "Source control — connection failed (TLS or network). If using a private CA, try NODE_OPTIONS: --use-system-ca. If server is remote, verify URL."
      2. **Auth error** (401/403) →
         [FAIL] "Source control — authentication failed. Token needs repository:read scope (Gitea), repo scope (GitHub), or read_repository scope (GitLab)."
      3. **Not found** (404) →
         [FAIL] "Source control — repository {owner/repo} not found. Verify Remote in Automation Config."
      4. **Tool not found** (MCP server lacks repository metadata method) →
         [WARN] "Source control MCP: repository existence check not supported — skipping."
      5. **Any other error** →
         [FAIL] "Source control — MCP server not reachable. Verify server URL and token in .mcp.json. If using a private CA (self-signed or corporate PKI), also try NODE_OPTIONS: --use-system-ca."
```

### What Does NOT Change in Step 10

- Auth messages keep per-platform scope names (`repository:read`, `repo`, `read_repository`) — these are better than Step 9's generic auth message.
- 404/not-found branch: SC-specific, correct as-is, kept in position 3 of the cascade.
- Tool-not-found branch: SC-specific ([WARN] not [FAIL]), correct as-is, kept in position 4.

---

## 4. Cross-Cutting Concerns

### Interaction Between Work Items A and B

Both Work Item A (bare path migration) and Work Item B (error_type) touch `core/mcp-detection.md`. These edits must be coordinated in a single editing session to avoid read-modify-read conflicts.

**Required ordering within `core/mcp-detection.md`:**

1. **First: error_type (Work Item B)** — add `error_type` field to Output Contract (lines 46–53) and `error_type` assignments to Failure Handling (lines 55–61). This is the more structural change.
2. **Second: path-note (Work Item A)** — add the path-note blockquote before Process step 1 (before line 19). This is purely additive prose.

Reason: Doing error_type first avoids accidentally moving the line numbers that the path-note insertion targets.

### Recommended Implementation Order (all files)

| Order | File | Work Item | Notes |
|-------|------|-----------|-------|
| 1 | `core/mcp-detection.md` | B then A | Both items in one session; error_type first, then path-note |
| 2 | `skills/check-setup/SKILL.md` | C (Step 10) | Independent; only Work Item C; single-file edit |
| 3 | `skills/init/SKILL.md` | A | Single bare ref; can optionally adopt error_type display in Step 7 |
| 4 | `skills/onboard/SKILL.md` | A | 6 bare refs; first Glob call in this skill |
| 5 | `skills/scaffold/SKILL.md` | A | 4 bare refs; requires chunked reads |

### Test Files to Update

| Test file | Update required | Reason |
|-----------|----------------|--------|
| `tests/scenarios/check-setup-edge-cases.sh` | Verify Step 10 now has a TLS branch | The file already checks that Glob appears exactly once in check-setup (lines 66–89). The new TLS branch in Step 10 adds no Glob, so the existing Glob-count test is unaffected. A new test case for "SC TLS error produces NODE_OPTIONS hint" should be added. |
| Any test validating Step 10 output messages | Update expected message for `Timeout/unreachable` | The catch-all message now includes the NODE_OPTIONS/private CA hint — any test asserting the old message will break. |
| `tests/scenarios/` (bare path migration) | Potentially add tests for onboard/scaffold/init Glob resolution | Phase 1 noted no existing tests cover the bare path migration pattern in onboard, scaffold, or init. Consider adding scenarios for "trackers.md not found → [WARN] and fallback" if test coverage is desired. |

### Documentation Gap (Non-Blocking)

`core/mcp-detection.md` Purpose section (line 7) lists only `scaffold/SKILL.md` and `init/SKILL.md` as referencing files. `check-setup/SKILL.md` is intentionally absent (it runs an inline connectivity check, not the core contract). This is architecturally correct and does NOT need to be changed. Document it here as a known intentional omission.

### Scope Boundary: mcp-preflight Not In Scope

`core/mcp-preflight.md` is called by `fix-ticket/SKILL.md` and `fix-bugs/SKILL.md`. Extending `error_type` benefits to those pipelines would require updating `mcp-preflight.md` to read and forward the `error_type` field from mcp-detection output. This is explicitly out of scope for this work item — file it as a follow-up roadmap item if desired.

---

## Appendix: Verified Source Locations

| Finding | Source | Verified |
|---------|--------|---------|
| check-setup Step 3a path-note text (lines 32–33) | `skills/check-setup/SKILL.md` | Yes — read directly |
| check-setup Step 7 "reuse resolved path" phrase (line 66) | `skills/check-setup/SKILL.md` | Yes — read directly |
| check-setup Step 9 TLS branch (lines 83–93) | `skills/check-setup/SKILL.md` | Yes — read directly |
| check-setup Step 9 Auth branch (lines 94–95) | `skills/check-setup/SKILL.md` | Yes — read directly |
| check-setup Step 10 full text (lines 98–104) | `skills/check-setup/SKILL.md` | Yes — read directly |
| mcp-detection Output Contract (lines 46–53) | `core/mcp-detection.md` | Yes — read directly |
| mcp-detection Failure Handling (lines 55–61) | `core/mcp-detection.md` | Yes — read directly |
| mcp-detection Process step 1 inline table (lines 20–29) | `core/mcp-detection.md` | Yes — read directly |
| onboard Step 2 bare refs (lines 68–76) | `skills/onboard/SKILL.md` | Yes — read directly |
| onboard Step 4b bare ref (line 108) | `skills/onboard/SKILL.md` | Yes — read directly |
| scaffold Step 0-INFRA bare ref (line 93) | `skills/scaffold/SKILL.md` | Yes — read directly |
| scaffold Step 0-MCP bare ref (line 169) | `skills/scaffold/SKILL.md` | Yes — read directly |
| scaffold Step 4b-replaced bare ref (line 484) | `skills/scaffold/SKILL.md` | Yes — read directly |
| scaffold Step 4e bare ref (line 543) | `skills/scaffold/SKILL.md` | Yes — read directly |
| init Step 0 bare ref (line 36) | `skills/init/SKILL.md` | Yes — read directly |
