# Agent 1 Research: Q1 (TLS Diagnostics) + Q4 (Existing Patterns)

**Researcher:** DevOps tooling specialist
**Date:** 2026-04-11
**Scope:** Q1 (TLS diagnostic approach) and Q4 (existing patterns in codebase)

---

## Q1: TLS Diagnostic Approach

### Q1.1 — How MCP connectivity failures are currently handled in Block 3 / Step 9

**File:** `skills/check-setup/SKILL.md`, lines 69–77

```
### Block 3: Connectivity

9. Run the Bug query from Automation Config via MCP (limit 1 result):
   - Success → [OK] with the number of bugs found
   - Auth error → [FAIL] "MCP server configured but authentication failed — check your token in .mcp.json"
   - Timeout/connection refused → [FAIL] "MCP server configured but not reachable — verify the server is running and URL is correct"
10. Verify source control connectivity: list repositories via MCP
    - Success → [OK]
    - Failure → [FAIL] with specific error type (auth vs unreachable)
```

**Analysis:** Step 9 classifies failures into exactly 2 buckets: auth error and timeout/connection refused. There is no third bucket for TLS failures. A TLS error (`UNABLE_TO_VERIFY_LEAF_SIGNATURE`, `self-signed certificate`, `certificate has expired`) would be swallowed into the "not reachable" bucket, which is misleading — the server IS reachable, but Node.js rejects the TLS handshake. The user gets the wrong recommendation ("verify the server is running and URL is correct") when the real fix is to trust the server's certificate.

### Q1.2 — What error message Node.js surfaces for TLS failures through MCP

**Direct codebase evidence:** There are no TLS-related error strings in any `.md` file in the repository (confirmed by grep for `TLS|tls|NODE_OPTIONS|use-system-ca|UNABLE_TO_VERIFY|NODE_TLS`). The codebase does not document this.

**External knowledge (marked as UNCERTAIN where not codebase-verified):**

- When Node.js `fetch()` or an HTTP client encounters a server with a certificate that cannot be validated (self-signed, internal CA, leaf cert with unknown chain), it throws: `FetchError: request to https://... failed, reason: unable to verify the first certificate` (underlying: `UNABLE_TO_VERIFY_LEAF_SIGNATURE` or `SELF_SIGNED_CERT_IN_CHAIN`).
- This error propagates through the MCP layer and will appear in the MCP tool's error response as part of the error text, since MCP servers are Node.js processes that relay their unhandled errors.
- UNCERTAIN: The exact format in which the MCP client surfaces this to the LLM (it depends on the specific MCP server implementation). However, the error string "unable to verify" or "fetch failed" is expected to appear in the error message that `core/mcp-detection.md` step 3 captures as `error`.

**Evidence from CHANGELOG.md line 685:**
> `check-setup Block 3: distinguishes auth errors from timeout/connection refused for more precise diagnostics`

This confirms the two-bucket classification was an intentional improvement, but TLS was not considered at that time.

### Q1.3 — Is `NODE_OPTIONS: "--use-system-ca"` the correct modern Node.js solution?

**Codebase evidence:** No reference to `NODE_OPTIONS` or `--use-system-ca` exists anywhere in the codebase (grep confirmed zero matches).

**External knowledge:**
- `NODE_OPTIONS="--use-system-ca"` is a Node.js 20+ feature (added in v20.x) that causes Node.js to load the operating system's CA certificate store in addition to its bundled Mozilla CA list. This allows connecting to servers with certificates issued by internal/corporate CAs without disabling TLS verification.
- This is the **correct, secure** solution for internal/corporate CA environments (including self-hosted Redmine with a self-signed or internal-CA cert).
- `NODE_TLS_REJECT_UNAUTHORIZED=0` is the insecure alternative that disables ALL TLS verification and should never be recommended.
- UNCERTAIN: Whether all Node.js MCP servers (npx-launched) would pick up `NODE_OPTIONS` from environment. For `npx`-launched MCP servers, `NODE_OPTIONS` must be set in the `.mcp.json` `env` block for the specific server. It cannot be set globally for the Claude Code session.

**Recommended diagnostic flow (proposed, not yet in codebase):**

1. MCP call fails with an error containing "fetch failed" / "unable to verify" / "certificate" / "self-signed"
2. Run `curl -s -o /dev/null -w "%{http_code}" --max-time 5 {instance_url}` (no `--insecure`)
   - HTTP 2xx/3xx/4xx → server is reachable over TLS; Node.js certificate verification is the issue → [FAIL] with specific TLS guidance
   - HTTP 000 / exit non-zero → server is genuinely unreachable → original "not reachable" message
3. If curl succeeds but Node.js fails: show `[FAIL] "MCP server configured but TLS verification failed — server is reachable but Node.js cannot verify its certificate. Add NODE_OPTIONS: \"--use-system-ca\" to the server's env in .mcp.json (requires Node.js 20+) or import the server certificate into your system CA store."`

### Q1.4 — Can curl reliably detect server reachability when Node.js fails on TLS?

**Codebase evidence for curl usage:** The codebase uses `curl` in multiple skills:

- `skills/init/SKILL.md` line 172–177: uses `curl -sL` for fetching release tags and `curl -sfL` for binary downloads (with `--fail` flag)
- `core/block-handler.md` line 39, `core/post-publish-hook.md` line 18, `skills/fix-bugs/SKILL.md` lines 578/626/660: use `curl --max-time 5 --retry 0 -X POST` for webhook notifications
- `skills/check-setup/SKILL.md` frontmatter line 4: `allowed-tools: mcp__*, Read, Glob, Grep, Bash` — Bash is allowed, so curl can be used

**Curl flag analysis:**

- `curl -s -o /dev/null -w "%{http_code}" --max-time 5 {url}` — silent, discard body, output HTTP status, 5s timeout. Returns `000` on connection failure.
- curl uses the **system CA store** by default (unlike Node.js which uses its own bundled Mozilla CA). This means curl WILL succeed (return an HTTP status code) when Node.js fails with `UNABLE_TO_VERIFY_LEAF_SIGNATURE` against an internal CA.
- Adding `--insecure` / `-k` would bypass TLS entirely (useful only for detecting server liveness, not for verifying cert validity — this could be used as a secondary check to distinguish "bad cert" from "server down").
- **Reliable approach:** `curl -s -o /dev/null -w "%{http_code}" --max-time 5 {url}` (without `--insecure`). If this returns a real HTTP status code (not 000), the server is reachable and TLS is valid from the system CA perspective. Combined with a Node.js MCP failure, this strongly indicates the `NODE_OPTIONS: --use-system-ca` fix is needed.
- UNCERTAIN: On Windows (the project's current dev platform), curl behavior with `--max-time` differs slightly (uses Windows curl via Git Bash). The flag is supported in modern curl versions bundled with Windows 10+.

---

## Q4: Existing Patterns

### Q4.1 — Does `core/mcp-detection.md` have TLS diagnostic logic?

**File:** `core/mcp-detection.md`, read fully (62 lines)

**Answer: No.** There is no TLS-specific logic in `core/mcp-detection.md`. The relevant section is:

```
3. If tool found — verify read connectivity:
   ...
   - If connectivity fails: set `mcp_available = false`, capture error

## Failure Handling
- Read connectivity fails: Return `mcp_available: false`, error: "{error message from failed test call}". Caller decides action.
```

`core/mcp-detection.md` correctly captures the raw error string, but it does not parse the error string for TLS indicators. It delegates all error interpretation to the caller. The error string from a TLS failure would pass through in the `error` field, but neither `mcp-detection.md` nor any caller currently inspects it for TLS-specific keywords.

### Q4.2 — Does `core/mcp-preflight.md` have TLS handling patterns?

**File:** `core/mcp-preflight.md`, read fully (48 lines)

**Answer: No.** The failure handling in `mcp-preflight.md` shows:

```
- MCP tool found but connectivity test fails (auth error, network error, timeout): BLOCK pipeline with:
  Detail: {error message from the failed test call}
  Recommendation: Check that your API token is valid and has the required permissions. Check that the {tracker_type} instance is reachable.
```

TLS failures would fall into "network error" and produce the generic "check your token" recommendation, which is unhelpful when the token is fine but TLS is the issue.

### Q4.3 — How does `skills/init/SKILL.md` handle MCP connectivity failures?

**File:** `skills/init/SKILL.md`, Step 7 (lines 250–263)

```
Step 7: Validate connectivity
For each configured MCP server with non-placeholder tokens:
1. Pre-flight: binary existence check (for non-npx servers only)
2. Connectivity check: Follow core/mcp-detection.md (with check_write: false):
   - If mcp_available: true → "[OK] {server_name} connected successfully"
   - If mcp_available: false → "[FAIL] {server_name}: {error}. Check your token and URL."
```

`skills/init/SKILL.md` uses the same pattern as `check-setup` — it surfaces the raw error message but does not add TLS-specific diagnostic branches. The recommendation "Check your token and URL" is equally unhelpful for TLS failures.

**Pattern established by init:** Pass the raw `{error}` through to the user. This is the correct base behavior to keep; the improvement is to add a post-failure curl probe when the error message indicates a fetch/TLS failure.

### Q4.4 — Any other TLS, certificate, or NODE_OPTIONS references in the codebase?

**Grep results for `TLS|tls|NODE_OPTIONS|use-system-ca|certificate|UNABLE_TO_VERIFY|NODE_TLS|ssl|SSL`:**

Relevant hits only:
- `docs/guides/custom-agents.md` line 183: "Private keys or certificates" — in a list of things NOT to put in custom agents. Not relevant.
- `skills/version-check/SKILL.md` line 46: `"If the command fails (network error, SSL error, auth failure, timeout)"` — documents SSL error as a failure mode but provides no diagnostic logic beyond "skip to next step".
- `docs/plans/readmine-project/orasetup/SETUP.md` lines 419, 514–520: Oracle SSL wallet configuration for Oracle ADB connection. Not relevant to check-setup.
- `docs/guides/mcp-configuration.md` line 158: `FORGEJO_URL connection refused | Wrong URL or server unreachable | Verify the URL in your browser` — suggests manual browser check but no curl-based diagnostic.

**Conclusion:** Zero TLS-specific diagnostic logic exists anywhere in the codebase. The codebase is entirely unaware of the TLS failure mode as a distinct category.

---

## Additional Issues Found During Research

### AO1: `core/mcp-detection.md` and `core/mcp-preflight.md` also have the TLS blind spot

If the TLS diagnostic is added to `check-setup` Block 3 step 9, consider whether `core/mcp-preflight.md` (used by pipeline skills) should also get a TLS hint in its block comment. Currently `mcp-preflight.md` says only "Check that your API token is valid... Check that the instance is reachable." A user hitting TLS failure mid-pipeline would get a misleading block comment. This is a wider fix but out of scope for the current task (check-setup only).

### AO2: `skills/init/SKILL.md` Step 7 has the same gap

The init skill would benefit from the same TLS diagnostic probe pattern, but that is also out of scope for the current task.

### AO3: Path resolution for `docs/reference/trackers.md`

Used by `check-setup` steps 3a and 7 (lines 32 and 59). The same relative path pattern `docs/reference/trackers.md` is used by:
- `skills/onboard/SKILL.md` (6 references)
- `skills/scaffold/SKILL.md` (4 references)
- `skills/init/SKILL.md` (2 references)
- `core/mcp-detection.md` (1 reference)

None of these files use any special path resolution syntax (no `$PLUGIN_ROOT` or equivalent). All use bare relative paths like `docs/reference/trackers.md`. This is the established convention across the entire plugin. The path resolution question (Q3) is consistent — bare relative paths are the standard pattern and Claude Code is expected to resolve them relative to the plugin root, not the CWD.

---

## Summary of Findings

| Question | Finding | Certainty |
|----------|---------|-----------|
| Q1.1 Block 3 step 9 current behavior | 2-bucket: auth vs timeout/connection refused. No TLS bucket. | HIGH (file read) |
| Q1.2 Node.js TLS error string | "fetch failed" / "unable to verify the first certificate" | UNCERTAIN (no codebase evidence) |
| Q1.3 NODE_OPTIONS --use-system-ca | Correct secure solution for Node.js 20+; not yet in codebase | UNCERTAIN for npx env propagation |
| Q1.4 curl reliability for server detection | curl uses system CA; will succeed when Node.js fails on internal CA cert | HIGH (standard curl behavior) |
| Q4.1 mcp-detection.md TLS logic | None — passes raw error to caller | HIGH (file read) |
| Q4.2 mcp-preflight.md TLS logic | None — generic "check token and URL" | HIGH (file read) |
| Q4.3 init skill MCP failure handling | Same pattern as check-setup; no TLS branch | HIGH (file read) |
| Q4.4 TLS references in codebase | Zero TLS-specific diagnostic logic found anywhere | HIGH (grep confirmed) |
