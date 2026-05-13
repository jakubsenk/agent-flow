# Phase 3 Brainstorm Synthesis — Final Direction

Judge-Mediator verdict. All three agents read, conflicts resolved, directions locked.

Date: 2026-04-11

---

## Direction for Q1: Bare Path Resolution Placement

**Decision: Option B (first-reference resolve-once) for all files.**

All three agents unanimously chose Option B. The conservative agent grounded this in the check-setup Step 3a/Step 7 precedent; the innovative agent confirmed the cognitive-salience argument (resolve where the LLM first needs the value); the skeptic validated the inventory completeness and surfaced two edge cases that must be addressed in the spec.

### Exact specification per file

| File | Resolve point | Variable name | Subsequent references |
|------|--------------|---------------|----------------------|
| `skills/onboard/SKILL.md` | Step 2 start, before sub-step 2 (before line 68) | `{trackers_md_path}` | Lines 70, 72, 75, 76, 108 — all become `{trackers_md_path}` |
| `skills/scaffold/SKILL.md` | Step 0-INFRA start, inside "If tracker = ready" block (before line 93) | `{trackers_md_path}` | Lines 169, 484, 543 — all become `{trackers_md_path}` |
| `skills/init/SKILL.md` | Step 0, inline at line 36 (single reference, single resolve) | `{trackers_md_path}` | None — single use |
| `core/mcp-detection.md` | No resolve added (not a skill, cannot Glob) | N/A | Path-note blockquote only, before Process step 1 |

### Resolution algorithm (same for all three skills)

```
1. Glob `.claude/plugins/**/docs/reference/trackers.md`
   — prefer path containing `.claude/plugins/` or `ceos-agents/`
   — if multiple matches: [WARN] "Multiple trackers.md found — using {path}."
2. Glob `**/docs/reference/trackers.md` — fallback if step 1 found nothing
3. `docs/reference/trackers.md` — bare CWD-relative last resort
4. If not found: [WARN] "trackers.md not found — using built-in defaults." and proceed with inline knowledge
```

### Skeptic's edge cases — incorporated

1. **Scaffold tracker = "later" guard.** When the user selects tracker = "later" in Step 0-INFRA, `{trackers_md_path}` is never resolved. Lines 484 (Step 4b) and 543 (Step 4e) already have guard clauses ("if tracker was declared" / "tracker_effective_status is NOT ready" -> skip). The spec must explicitly state: "If `{trackers_md_path}` was not resolved because tracker = later, these references are no-ops — the guarded conditional skips them."

2. **mcp-detection inline table is the operative source for mcp-preflight callers.** The path-note in `core/mcp-detection.md` must include this clarifying sentence: "For callers that flow through `core/mcp-preflight.md` (which cannot perform Glob), the inline table below is the operative source." This prevents the reference to `docs/reference/trackers.md` in Process step 1 from appearing aspirational.

3. **Inline table drift risk.** The skeptic proposed a sync-check test. This is out of scope for this PATCH but should be filed as a follow-up. The spec should note: "FOLLOW-UP: Add a test in `tests/scenarios/` that compares the inline table in `core/mcp-detection.md` against the canonical `docs/reference/trackers.md` MCP Server Detection table."

---

## Direction for Q2: error_type Classification Location

**Decision: Option B (Failure Handling section) with a Classification Reference table.**

All three agents chose Option B. The innovative agent proposed the "twist" of a consolidated Classification Reference table inside Failure Handling. The skeptic validated zero caller breakage and confirmed the 5-value enum is pragmatically correct. Both additions are adopted.

### Exact specification

**1. Output Contract addition** — add after the `error` row in `core/mcp-detection.md`:

```markdown
- **error_type** (string or null): Classification of the error when `mcp_available` is false.
  Values: `"tls"`, `"auth"`, `"not_found"`, `"timeout"`, `"unknown"`. `null` when `mcp_available` is true.
  See Failure Handling for classification logic.
```

**2. Classification Reference table** — add as a new sub-section at the end of the Failure Handling section (not scattered across each scenario):

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
```

**3. Per-scenario error_type assignment** — each existing Failure Handling scenario gets one line added:

| Scenario | error_type |
|----------|-----------|
| No matching MCP tool found | `"unknown"` |
| Read connectivity fails | Classify per Classification Reference above |
| Write canary create fails | `null` (write errors are separate; `mcp_available` may still be true) |
| Write canary delete fails | `null` (same) |

**4. Cross-reference note** — add to end of Failure Handling: "Pattern matching reuses the same string patterns as `skills/check-setup/SKILL.md` Step 9."

### Skeptic's concerns — resolved

1. **ECONNREFUSED vs. timeout grouping.** Adopted. The Classification Reference table explicitly documents the ECONNREFUSED placement under `"timeout"` with rationale. DNS failures (ENOTFOUND, EAI_AGAIN) are placed under `"not_found"` with rationale. This addresses the skeptic's precision concern without adding enum values.

2. **mcp-preflight does not forward error_type.** Confirmed out of scope. The spec must note: "FOLLOW-UP: Update `core/mcp-preflight.md` to forward `error_type` from mcp-detection output. File as roadmap item for v6.5.0."

3. **Exhaustiveness checking.** The skeptic proposed a test that extracts enum values from `core/mcp-detection.md` and verifies caller coverage. Out of scope for this PATCH. The spec should note: "FOLLOW-UP: Add exhaustiveness test for error_type enum values vs. caller handling."

---

## Direction for Q3: Step 10 TLS Treatment

**Decision: Adapted for SC, using env-var URL extraction + well-known host fallback for the curl probe URL.**

All three agents chose the adapted approach over exact mirror or minimal. The critical contribution from the skeptic was identifying that `.mcp.json` uses stdio transport exclusively — there is no `url` or `baseUrl` field in any MCP server config. The research document's derivation rule ("extract the base hostname from the MCP server configuration") references fields that do not exist. This is resolved below.

### Curl probe URL derivation — definitive approach

The research document's `{sc_base_url}` derivation is replaced with the following two-tier approach:

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
   - Otherwise → skip probe. Emit the no-curl-available variant of the TLS message.
```

This approach:
- Does NOT reference nonexistent `url`/`baseUrl` fields in `.mcp.json`
- Does NOT parse the ambiguous Remote string (`owner/repo` vs. `hostname/owner/repo`)
- Reuses the env var mapping already present in `skills/init/SKILL.md` Step 3 table (lines 101-108)
- Gracefully degrades: if URL cannot be derived, the probe is skipped and the TLS hint is still emitted

### Step 10 replacement text — exact specification

Replace lines 98-104 of `skills/check-setup/SKILL.md` with:

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

### Preserved SC-specific branches

- Auth message keeps per-platform scope names (repository:read, repo, read_repository) — more actionable than Step 9's generic message.
- 404/not-found branch is SC-specific (repository not found vs. tracker project not found). Kept at position 3.
- Tool-not-found branch is SC-specific ([WARN] not [FAIL]). Kept at position 4.

### Skeptic's curl probe caveat — incorporated

The word "likely" in the TLS message ("likely TLS") is critical and must be preserved. The curl probe tests network reachability via the system HTTP stack, but the MCP stdio server may use Node.js's own TLS stack with different CA trust behavior. The curl probe is a heuristic, not a definitive TLS diagnosis. The message text must NEVER be strengthened to "confirmed TLS error."

---

## Open Risks

These must be addressed in the spec phase:

| # | Risk | Owner | Mitigation |
|---|------|-------|------------|
| 1 | **Inline table drift in mcp-detection.md.** The inline MCP Server Detection table in `core/mcp-detection.md` Process step 1 can diverge from `docs/reference/trackers.md` when new tracker types are added. No automated guard exists. | Spec | Add a FOLLOW-UP note to file a sync-check test as a future work item. Not in PATCH scope. |
| 2 | **mcp-preflight does not forward error_type.** Fix-ticket/fix-bugs/implement-feature pipelines gain zero benefit from the error_type work until `core/mcp-preflight.md` is updated. | Spec | Note as roadmap item for v6.5.0. Not a blocker for this PATCH. |
| 3 | **Scaffold tracker=later leaves {trackers_md_path} undefined.** The variable is referenced at lines 484 and 543 but never resolved when tracker = "later". | Spec | Spec must explicitly state that these references are guarded by existing conditionals and are no-ops when tracker = later. |
| 4 | **SC Remote format ambiguity.** CLAUDE.md says `owner/repo` but `onboard/SKILL.md` line 81 says `hostname + owner/repo`. The curl probe derivation intentionally avoids parsing the Remote string, but the format inconsistency should be resolved eventually. | Spec | Note for future cleanup. The Q3 derivation avoids this entirely by using .mcp.json env vars. |
| 5 | **Curl probe tests different TLS path than MCP stdio.** The curl probe uses the system HTTP client; MCP servers use Node.js. A corporate proxy MITM cert trusted by curl but not Node.js would produce a misleading "server reachable but MCP failed" message. The message IS actually correct diagnostic advice (the fix is NODE_OPTIONS), but the probe is a heuristic. | Spec | Preserve the word "likely" in all TLS messages. Do not strengthen to "confirmed." |
| 6 | **scaffold/SKILL.md exceeds single-read limit.** Implementation must use chunked reads (lines 1-300, 300-600). | Spec | Specify chunked read boundaries in implementation plan. |

---

## Rejected Alternatives

| Alternative | Why rejected |
|-------------|-------------|
| **Q1 Option A (file-top preamble)** | Creates distance between resolution and first use (80+ lines in scaffold). Breaks the check-setup Step 3a precedent. Adds Glob overhead on early-exit paths (scaffold tracker="later"). All three agents rejected it. |
| **Q1 Option C (every-reference resolve)** | 6 Glob calls in onboard, 4 in scaffold. Violates check-setup Step 7's explicit prohibition: "reuse the trackers.md path resolved in Step 3a (do not Glob again)." Performance degradation with no benefit. Unanimously rejected. |
| **Q2 Option A (Process section)** | Process describes WHAT happens, not error classification logic. Inserting a 5-row enum table and 8+6 pattern-matching rules into Process bloats the procedural flow. Two agents called it "architecturally wrong." |
| **Q2 Option C (inline per case)** | Scatters error_type assignments across Process and Failure Handling, creating duplication drift. In a pure-markdown codebase with no automated consistency checks, duplication is a maintenance antipattern. Unanimously rejected. |
| **Q2 larger enum (dns, connection_refused, rate_limited)** | Skeptic considered splitting not_found and timeout into sub-categories. Rejected because more enum values means more message branches at each call site. The 5-value enum is pragmatically correct — remediation messages can mention both possibilities in one line. The Classification Reference table documents the grouping rationale explicitly. |
| **Q3 exact mirror of Step 9** | Ignores that SC Remote is `owner/repo` (not a URL), so Step 9's `{Instance}` curl target has no SC equivalent. A "mirror" would need immediate adaptation anyway, making it not actually a mirror. Also loses SC-specific branches (per-platform scope names, 404, tool-not-found as WARN). |
| **Q3 minimal (TLS detection + hint, no curl probe)** | Conservative and innovative agents both acknowledged this as acceptable fallback but inferior. The curl probe distinguishes "server reachable but TLS rejected by MCP" from "server completely unreachable" — genuinely different diagnostic situations. Dropping the probe makes Step 10 a second-class citizen compared to Step 9. The adapted approach with graceful degradation (skip probe when URL not derivable) captures the minimal option as a fallback path rather than the primary path. |
| **Q3 parsing Remote string for URL** | The Remote string format is ambiguous (`owner/repo` vs. `hostname/owner/repo`). Parsing it to extract a hostname would be fragile and create coupling to an undocumented format. The env-var scan from .mcp.json is a reliable, already-documented source. |
| **Q3 using `url`/`baseUrl` fields from .mcp.json** | These fields do not exist. All MCP servers in the ceos-agents ecosystem use stdio transport (`"command"` field), not HTTP/SSE transport. The research document incorrectly assumed HTTP transport fields would be available. The env-var scan is the correct alternative. |

---

## Implementation Order (confirmed)

All three agents and the research document agree on this order:

| Order | File | Work items | Notes |
|-------|------|-----------|-------|
| 1 | `core/mcp-detection.md` | Q2 (error_type) then Q1 (path-note) | Both edits in one session. error_type first to avoid line-number drift. |
| 2 | `skills/check-setup/SKILL.md` | Q3 (Step 10 replacement) | Independent. Single-file edit. |
| 3 | `skills/init/SKILL.md` | Q1 (single bare ref) | Can optionally adopt error_type display in Step 7 — spec should decide. |
| 4 | `skills/onboard/SKILL.md` | Q1 (6 bare refs) | First Glob call in this skill. |
| 5 | `skills/scaffold/SKILL.md` | Q1 (4 bare refs, chunked reads) | Requires chunked reads due to file size. |

Post-edit: verify `core/mcp-preflight.md` is NOT affected (30-second confirmation scan, as the innovative agent recommended).
