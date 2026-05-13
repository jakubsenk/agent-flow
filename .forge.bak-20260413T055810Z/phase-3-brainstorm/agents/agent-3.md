# Agent 3: Devil's Advocate

Persona: Skeptical reviewer. Questions assumptions, surfaces hidden complexity, identifies breakage vectors.

---

## Q1: Bare Path Resolution Placement

### Challenge: Inventory Completeness

The research identifies 12 references across 4 files. I verified this against a full grep for `docs/reference/trackers.md` across the repository. The count is **correct for skill/core source files** -- the 4 files are `skills/onboard/SKILL.md`, `skills/scaffold/SKILL.md`, `skills/init/SKILL.md`, and `core/mcp-detection.md`. No additional skill or core files reference the bare path.

However, there are references in non-source files that deserve acknowledgment:
- `tests/scenarios/check-setup-improvements.sh` line 189-192 already tests for bare path absence in check-setup -- this is an existing guard, not a new concern.
- `tests/scenarios/scaffold-tracker-integration.sh` line 10 uses `TRACKERS_DOC="$REPO_ROOT/docs/reference/trackers.md"` -- this is a test helper resolving from `$REPO_ROOT`, which is correct (test scripts know their own repo root). Not affected.
- `docs/plans/` files contain historical references -- these are planning artifacts, not executable. Not affected.

The inventory is complete for implementation scope.

### Challenge: mcp-preflight.md and trackers.md

I read `core/mcp-preflight.md` in full. It does **NOT** reference `trackers.md` directly. Its Process section says "Follow `core/mcp-detection.md` with `service_type: "tracker"`" and delegates everything to mcp-detection. The chain is: mcp-preflight -> mcp-detection -> (mcp-detection's inline table or trackers.md). Since mcp-preflight never reads trackers.md itself, it is correctly excluded from the inventory.

BUT: `core/mcp-detection.md` Process step 1 says "Look up MCP package and tool prefix from the MCP Server Detection table in `docs/reference/trackers.md`" and then provides a static inline fallback table. The research proposal adds a path-note saying callers must resolve the path via Glob. Here is the problem: **mcp-detection.md is a core contract, not a skill**. It has no `allowed-tools` frontmatter. It cannot execute Glob. So who resolves the path? The calling skill. But `core/mcp-preflight.md` -- the intermediary -- also has no `allowed-tools`. The path resolution responsibility falls all the way back to `fix-ticket`, `fix-bugs`, and `implement-feature`, none of which currently do any Glob resolution for trackers.md.

The research paper says "Path-note only; no Glob added" for mcp-detection.md and declares mcp-preflight out of scope. This is architecturally correct but leaves a real gap: the mcp-detection inline table becomes the de facto permanent table for all pipeline callers (fix-ticket, fix-bugs, implement-feature), and the `docs/reference/trackers.md` reference in mcp-detection Process step 1 is purely aspirational documentation that no code path from those pipelines will ever follow.

### Challenge: "Resolve once, reuse later" in non-sequential skills

The proposal says onboard resolves `trackers_md_path` once at Step 2 start and reuses through Step 4b. Scaffold resolves once at Step 0-INFRA and reuses through Step 4e (line 543, ~450 lines later).

This works fine for the current skill execution model where Claude Code runs skills sequentially top-to-bottom. But there is a subtle risk: if a skill is ever interrupted and resumed (e.g., via `/resume-ticket`), the in-memory variable `trackers_md_path` would be lost. The resume logic would need to re-resolve. Currently `/resume-ticket` only applies to fix-ticket/fix-bugs/implement-feature pipelines, not to onboard or scaffold, so this is a theoretical risk, not a practical one today. Still worth documenting.

A more concrete risk: scaffold's Step 0-INFRA resolution happens inside the "If tracker = ready" conditional block. If the user says "later" for tracker, `trackers_md_path` is never resolved. But lines 484 and 543 still reference `{trackers_md_path}`. The research says these 4 references are "Reuse `trackers_md_path`" -- but if tracker was "later", the variable is undefined. Looking at the actual scaffold flow:
- Line 484 (Step 4b-replaced): "Based on `tracker_type` from Step 0-INFRA (if tracker was declared)" -- there IS a guard clause ("if tracker was declared").
- Line 543 (Step 4e): Has a guard clause "tracker_effective_status is NOT ready" -> skip.

So the guards exist but are implicit. The implementation must ensure the `{trackers_md_path}` variable replacement text includes a guard: "If `trackers_md_path` was not resolved (tracker = later), skip this reference."

### Recommendation

Accept the inventory as-is. Add a single sentence to the mcp-detection path-note clarifying that the inline table IS the operative source for callers that flow through mcp-preflight (since neither mcp-preflight nor its upstream callers perform Glob resolution). For scaffold, explicitly document that `{trackers_md_path}` references at lines 484 and 543 are guarded by the existing tracker-status conditionals and should emit no error when tracker = "later".

### Key Risk

The mcp-detection inline table drifts out of sync with the canonical `docs/reference/trackers.md`. When a new tracker type is added (as happened with Redmine in v4.1.0), the inline table in mcp-detection must be updated manually. There is no automated guard for this.

### Mitigation

Add a test scenario in `tests/scenarios/` that compares the inline table in `core/mcp-detection.md` against `docs/reference/trackers.md` MCP Server Detection table and fails if they diverge. This is a 15-line shell script.

---

## Q2: error_type Classification Location

### Challenge: Is 5 values the right number?

The proposed enum is: `tls`, `auth`, `not_found`, `timeout`, `unknown`.

Consider these edge cases:
- **DNS resolution failure** is categorized under `not_found`. But DNS failure and HTTP 404 are completely different problems with completely different remediation. DNS failure means "your server hostname is wrong or DNS is down." HTTP 404 means "your server is reachable but the resource path is wrong." Lumping them into `not_found` loses diagnostic precision.
- **ECONNREFUSED** is categorized under `timeout`. But connection refused means "the server is down or the port is wrong" while timeout means "the server is slow or firewalled." Again, different remediation.
- **Rate limiting (429)** would fall into `unknown`. For high-volume batch operations (fix-bugs with count=10), rate limiting is a real scenario that deserves its own hint ("wait and retry" vs. "check your config").

However, counter-argument: this is a markdown plugin consumed by an LLM. The LLM uses the `error_type` to select which pre-written message to display. More enum values means more message branches in every caller. The current callers (init Step 7, scaffold Step 0-MCP) display simple one-line messages. The 5-value enum is a pragmatic balance. Adding `dns`, `connection_refused`, `rate_limited` would triple the message handling at each call site for edge cases that rarely occur.

### Challenge: Callers that pattern-match on raw error strings

This is the most important breakage vector. Let me trace every caller:

1. **`skills/check-setup/SKILL.md` Step 9**: Does its own inline pattern matching on raw error strings. Does NOT call mcp-detection. Unaffected by the enum -- it IS the canonical source the enum was derived from.

2. **`skills/init/SKILL.md` Step 7**: Calls mcp-detection, receives `{error}` string, displays it verbatim: `"[FAIL] {server_name}: {error}. Check your token and URL."` -- no pattern matching. Adding `error_type` is purely additive; the existing `error` field is preserved. **No breakage.**

3. **`skills/scaffold/SKILL.md` Step 0-MCP**: Calls mcp-detection, displays guidance based on failure. Currently does not pattern-match the error string -- it displays a generic guidance message. **No breakage.**

4. **`core/mcp-preflight.md`**: Calls mcp-detection, receives `mcp_available: false`, and uses the raw `error` in its block comment Detail field. Adding `error_type` to mcp-detection output is purely additive. mcp-preflight does not read `error_type`. **No breakage.** But also no benefit until mcp-preflight is updated to use it.

5. **`skills/fix-bugs/SKILL.md` Step 0**: Calls mcp-preflight (not mcp-detection directly). Has its own inline fallback message. **No breakage.**

So: **zero callers will break** from adding `error_type` because it is a new additive field. The existing `error` string field is preserved. This is a clean extension.

### Challenge: Is mcp-preflight affected?

Read `core/mcp-preflight.md` carefully. Its Output Contract returns only `mcp_available` (boolean). It does NOT forward `error`, `error_type`, or any other field from mcp-detection. Its Failure Handling block-comment uses `{error message from the failed test call}` in the Detail line -- this comes from the raw string.

To benefit from `error_type` in the fix-ticket/fix-bugs pipelines, mcp-preflight would need to:
1. Add `error_type` to its Output Contract
2. Forward it from mcp-detection output
3. Use it to differentiate block messages (e.g., TLS block message with NODE_OPTIONS hint vs. generic block)

This is explicitly declared out of scope. My concern: if we ship `error_type` in mcp-detection but never propagate it through mcp-preflight, the most frequently-hit callers (fix-ticket, fix-bugs, implement-feature -- the core pipeline skills) gain zero benefit from this work item. Only init and scaffold benefit. Is that worth the complexity?

I think yes, because:
- init and scaffold are the setup commands where users are most likely to encounter TLS/auth issues
- fix-ticket/fix-bugs users have presumably already passed init/check-setup successfully
- The mcp-preflight update is a clean follow-up work item, not a prerequisite

### Recommendation

Accept the 5-value enum. Do not split `not_found` or `timeout` into sub-categories -- the remediation messages can include both possibilities in a single line (e.g., "not_found: 404 or DNS resolution failure -- verify the hostname and resource path"). Document the ECONNREFUSED-in-timeout grouping explicitly in the enum definition so future readers are not surprised.

File a roadmap item for mcp-preflight error_type forwarding as a v6.5.0 follow-up.

### Key Risk

The enum is defined in prose (markdown), not in code. There is no type system, no compiler, no schema validator. A future contributor could add a 6th value to mcp-detection without updating all callers' switch/case branches, silently falling through to `unknown` handling in some callers and the new value in others.

### Mitigation

Add a test that extracts the error_type values from `core/mcp-detection.md` and verifies that every caller file (init, scaffold) handles all values or has an explicit `unknown` fallback. This is the markdown equivalent of exhaustiveness checking.

---

## Q3: Step 10 TLS Mirroring Scope

### Challenge: Curl probe URL derivation

This is the hardest problem of the three. The research proposes: "Extract the base hostname from the SC MCP server entry in .mcp.json."

Let me examine the actual `.mcp.json` examples to see if this works:

**GitHub** (`examples/mcp-configs/github.json`):
```json
{
  "mcpServers": {
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": { "GITHUB_PERSONAL_ACCESS_TOKEN": "..." }
    }
  }
}
```
There is **no URL field**. The GitHub MCP server is an npx-launched stdio process. There is no `url`, `baseUrl`, or `endpoint` anywhere in the config. The server communicates via stdin/stdout with Claude Code, and the actual `https://api.github.com` endpoint is hardcoded inside the npm package.

**Gitea** (`examples/mcp-configs/gitea.json`):
```json
{
  "mcpServers": {
    "gitea": {
      "command": "<path-to-binary>/forgejo-mcp",
      "env": { "FORGEJO_URL": "https://<YOUR_GITEA_INSTANCE>", ... }
    }
  }
}
```
Here the URL IS available -- in `FORGEJO_URL` env var. But the key name is tracker-specific. Each tracker type uses a different env var name.

**YouTrack** (`examples/mcp-configs/youtrack.json`):
```json
{
  "mcpServers": {
    "youtrack": {
      "env": { "YOUTRACK_URL": "https://<YOUR_INSTANCE>.youtrack.cloud", ... }
    }
  }
}
```
URL in `YOUTRACK_URL`.

So the research's derivation rule -- "extract the base hostname from the SC MCP server entry in .mcp.json" -- **does not work for GitHub/GitHub-hosted SC**. GitHub's MCP config has no URL at all. For self-hosted Gitea/GitLab, the URL is in an env var with a tracker-specific key name.

### Challenge: What is the SC MCP server?

Step 10 is about SOURCE CONTROL, not the issue tracker. The SC MCP server could be:
- `@modelcontextprotocol/server-github` -- no URL in config, hardcoded to github.com
- `forgejo-mcp` -- URL in FORGEJO_URL env var
- A GitLab MCP server (not yet in the plugin's supported list but plausible)

The research acknowledges this: "If SC remote is github.com -> probe target is `https://github.com`". But this derivation comes from the Remote string in Automation Config (`owner/repo`), not from `.mcp.json`. The Remote string itself does NOT contain a hostname -- it is literally `owner/repo` format per the config contract.

Wait -- let me re-read. The Source Control Remote config value format... Looking at the onboard Step 3: "Remote hostname + owner/repo (e.g. `gitea.internal.ceosdata.com/org/repo`)". So the Remote CAN contain a hostname prefix. But looking at the config contract in CLAUDE.md: "Remote (owner/repo)". There is an inconsistency: CLAUDE.md says `owner/repo` but onboard says `hostname + owner/repo`.

Looking at actual config examples would clarify, but the core question is: **is the Remote always `owner/repo` or sometimes `hostname/owner/repo`?** If it is always `owner/repo`, the hostname must be derived elsewhere. If it sometimes includes the hostname, parsing becomes ambiguous (is `github.com/org/repo` a 3-part or could `org` be a hostname?).

### Challenge: stdio transport = no URL at all

ALL MCP servers in the ceos-agents ecosystem use stdio transport (`"command": "npx"` or `"command": "/path/to/binary"`). None use HTTP/SSE transport. This means there is literally never a `url` or `baseUrl` field in `.mcp.json`. The research's statement "extract the base hostname from the MCP server configuration (the 'url' or 'baseUrl' field)" references fields that DO NOT EXIST in any of the 7 example configs.

The only reliable source for the SC base URL is:
1. The `FORGEJO_URL` / equivalent env var in `.mcp.json` (for self-hosted)
2. Hardcoded knowledge that `server-github` -> `https://github.com` (for GitHub)
3. The Remote value from Automation Config (if it contains a hostname)

### What Step 9 already does (the tracker side)

Step 9 uses `{Instance}` from Automation Config -- the tracker's Instance URL. This is always a full URL. The curl probe works because the Instance IS the URL to probe.

Step 10 has no equivalent. There is no "SC Instance" config key. The SC server's URL must be inferred.

### Recommendation

Simplify the curl probe derivation. Instead of trying to extract a URL from `.mcp.json`, use a two-tier approach:

1. **Env var extraction**: Look up the SC MCP server entry in `.mcp.json`. Scan its `env` block for any value that looks like a URL (starts with `https://` or `http://`). For known server types: `FORGEJO_URL` for Gitea, `YOUTRACK_URL` for YouTrack-as-SC (unlikely), etc. Use the first URL-like env value as the probe target.

2. **Fallback to well-known hosts**: If no URL found in env (e.g., GitHub server), use a static mapping:
   - SC server package contains `server-github` -> `https://github.com`
   - SC server package contains `server-gitlab` -> `https://gitlab.com`
   - Otherwise -> skip probe, emit the no-curl-available variant of the TLS message

This avoids parsing the Remote string (which may or may not contain a hostname) and avoids referencing nonexistent `url`/`baseUrl` fields.

### Key Risk

The curl probe for GitHub (probing `https://github.com`) tests network reachability to github.com but NOT the TLS chain that the MCP stdio server uses internally. The MCP server may use a different HTTP client with different CA trust settings than curl. The curl probe can succeed while the MCP connection fails due to corporate proxy MITM certificates that curl trusts (via system CA) but Node.js does not (missing NODE_OPTIONS). This is the exact scenario where NODE_OPTIONS matters -- and the curl probe would misleadingly show "server reachable but MCP connection failed (likely TLS)". That message IS actually the correct diagnostic, so the risk is contained. But the diagnostic message should not claim "confirmed by curl" or similar -- it should say "network reachability confirmed by curl; MCP TLS handshake may still differ."

### Mitigation

Keep the curl probe as a heuristic, not a definitive test. The message text in the research proposal already handles this correctly: "server reachable but MCP connection failed (likely TLS) -- add NODE_OPTIONS." The word "likely" is important and must be preserved. Do NOT strengthen it to "confirmed TLS error" based on the curl result alone.

Additionally, for the SC case specifically, add a guard: "If {sc_base_url} cannot be derived from the SC MCP server env block or well-known mapping, skip the curl probe entirely and emit the TLS error message without network confirmation." This prevents the implementation from trying to parse ambiguous Remote strings.

---

## Cross-cutting: Implementation Order Risk

The research recommends editing `core/mcp-detection.md` first (error_type then path-note). This is correct. But there is a subtle ordering concern for **tests**: the existing test `tests/scenarios/check-setup-improvements.sh` (lines 189-192) asserts that check-setup does NOT use bare `Read docs/reference/trackers.md`. If the implementation accidentally introduces a bare path in any of the touched files and a test is added to verify this, the test must run AFTER all files are edited. Running tests between file edits could produce false positives. Standard forge execution handles this, but worth noting.

---

## Summary Table

| Question | Recommendation | Key Risk | Mitigation |
|----------|---------------|----------|------------|
| Q1: Bare Path Inventory | Accept as-is; clarify mcp-detection inline table is operative for mcp-preflight callers; guard scaffold `{trackers_md_path}` for tracker=later case | Inline table in mcp-detection drifts from trackers.md | Add sync-check test comparing inline table vs. canonical trackers.md |
| Q2: error_type Enum | Accept 5-value enum; document ECONNREFUSED grouping; file mcp-preflight forwarding as v6.5.0 follow-up | No exhaustiveness checking for prose-defined enum; callers may miss new values | Add test extracting enum values from mcp-detection and verifying caller coverage |
| Q3: Step 10 TLS Probe | Use env-var URL extraction + well-known host fallback; abandon `.mcp.json` url/baseUrl parsing (fields do not exist) | curl probe tests different TLS path than MCP stdio server; false confidence | Keep "likely" qualifier in messages; skip probe when URL is not derivable |
