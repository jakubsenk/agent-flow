# Phase 3 Brainstorm — Agent 1: Conservative DX Architect

**Perspective:** Minimal changes, backward compatibility, proven patterns. Prefer inline fixes.
Favor Approach A unless a strong reason exists otherwise.

---

## Issue 1: TLS Diagnostic (Block 3, Step 9)

### Problem Summary

Step 9 has only two failure buckets. TLS errors (self-signed certs, corporate CA, private PKI)
fall into "timeout/connection refused" and produce a misleading recommendation about server
reachability. The server IS reachable; Node.js rejects the TLS handshake.

### Approach A — Pattern-first inline expansion (RECOMMENDED)

Add TLS pattern matching before the "unreachable" bucket. When a TLS pattern is detected,
run a curl probe to confirm network reachability, then emit the right message.

The curl probe is:
```
curl -s -o /dev/null -w "%{http_code}" --max-time 5 {Instance}
```
- curl exit 0 and HTTP code != 000 → server is reachable, TLS is the problem
- curl exit non-zero or HTTP code 000 → server is genuinely unreachable, fall back to generic

Pros:
- `Bash` is already in `allowed-tools` — no frontmatter change
- One targeted replacement in Step 9, ~10 added lines
- Pattern list is exhaustive for known Node.js TLS error codes
- Curl probe prevents false positives (avoids blaming TLS when server is truly down)
- Backward compatible: existing success/auth paths unchanged

Cons:
- Adds a Bash dependency; if curl is missing the probe fails silently
- Must handle curl-not-available case explicitly

**curl availability handling:** The skill should instruct: if curl exits with "command not found"
(exit code 127) or the tool call itself fails, skip the probe and emit:
`[FAIL] "Issue tracker — MCP connection failed (possible TLS issue) — verify server URL and
certificate. Run curl manually: curl -v {Instance}"`
This degrades gracefully without breaking the diagnostic.

### Approach B — Pattern match only, no curl probe

Add TLS pattern matching but skip the curl probe. If a TLS pattern is detected, always emit
the TLS recommendation regardless of whether the server is network-reachable.

Pros:
- No curl dependency
- Simpler logic

Cons:
- Can produce a misleading TLS recommendation when the server is genuinely down (the TLS error
  patterns could appear in timeout messages from certain Node.js versions/configurations)
- Slightly less actionable: user follows TLS advice on a down server

### Approach C — Add a dedicated TLS troubleshooting step (new Step 9b)

Keep Step 9 as-is and insert a new Step 9b that runs the curl probe unconditionally and reports
TLS status separately.

Pros:
- Does not modify the existing logic at all

Cons:
- Adds an always-running curl step even for healthy setups — unnecessary noise
- Two-step split makes the diagnostic harder to follow
- Over-engineering for what is a classification improvement

### Recommendation: Approach A

The curl probe is a proven one-liner that eliminates false TLS blame. The graceful degradation
on curl-not-available makes it safe. The fix is contained to Step 9, adds ~10 lines, and
requires no frontmatter changes. Backward compatibility is preserved: existing success/auth
paths are untouched; the new TLS branch only activates on TLS error patterns.

---

## Issue 2: read:user Scope Check (Step 10)

### Problem Summary

Step 10 says "list repositories via MCP", implying `list_my_repositories`. That tool does not
exist in Gitea's MCP. The check is also framed around GitHub-style `read:user` scope, which
Gitea does not use. The correct behavior: verify that the single declared remote from
`Source Control → Remote` is accessible, which only requires `repository:read` scope.

### Approach A — Replace "list" with "fetch the configured remote" (RECOMMENDED)

Rewrite Step 10 to use MCP to fetch repository metadata for the specific `owner/repo` from
Automation Config. This is a single targeted read, not an enumeration. Failure messages
distinguish 401/403 (auth), 404 (wrong repo name), and unreachable (network/MCP).

Pros:
- Works for all trackers (Gitea, GitHub, GitLab, Bitbucket) — all have a "get repo" endpoint
- Checks the exact resource the pipeline will use, not a user-level listing
- Scope message changed from `read:user` to `repository:read` — correct for Gitea
- Success message includes the confirmed `owner/repo` — more useful than a bare [OK]
- ~4 lines net expansion, no frontmatter changes

Cons:
- Slightly more output verbosity (success line now includes owner/repo), but that is a
  strict improvement

### Approach B — Keep "list repositories" but with a fallback

Keep the list-repositories intent but add a fallback: if `list_my_repositories` fails with a
tool-not-found error, fall back to fetching the configured remote directly.

Pros:
- Preserves original intent of broader connectivity validation

Cons:
- `list_my_repositories` does not exist in Gitea MCP — fallback would always trigger for Gitea
  users, making the fallback the actual behavior and the primary path dead code
- More complex logic for no benefit
- Does not fix the wrong scope message

### Approach C — Remove Step 10 entirely and fold into Step 7 MCP presence check

Instead of testing connectivity, declare that if Step 7 confirmed a source control MCP server
is present, Step 10 is [SKIP] "SC MCP present (connectivity assumed from server presence)".

Pros:
- Simplest change; no new MCP calls

Cons:
- Reduces the value of check-setup — presence of a server config does not mean the token works
- A wrong token would only be detected at first pipeline run, not during setup validation
- Goes against the goal of Block 3 (connectivity verification)

### Recommendation: Approach A

Fetching the configured remote is the minimal, correct fix. It validates exactly what the
pipeline needs (access to that specific repo), works across all SC providers, and fixes the
misleading scope hint. The change is surgical — 3 lines replaced with 7 lines.

---

## Issue 3: Path Resolution (trackers.md)

### Problem Summary

`docs/reference/trackers.md` appears as a bare relative path in Steps 3a and 7. When
check-setup runs in a consuming project's working directory, the plugin's `docs/` folder is
not at that relative path. The read silently fails or returns nothing, causing validation to
produce incorrect results.

### Approach A — Glob-first with CWD-relative fallback (RECOMMENDED)

Use `Glob("**/docs/reference/trackers.md")` to locate the file. Read the first result. If
Glob returns no matches, try the bare relative path as a CWD fallback (handles the rare case
where the consuming project has its own copy). If neither resolves, emit [WARN] and skip
per-tracker validation.

`Glob` is already in `allowed-tools` — no frontmatter change needed.

Apply the resolution once in Step 3a. Step 7 reuses the already-resolved path (does not
re-Glob).

Pros:
- Works regardless of where the plugin is installed relative to CWD
- No hardcoded absolute path — no assumption about installation directory structure
- Graceful degradation: [WARN] skip instead of silent wrong behavior
- `Glob` is already available — zero cost change
- Single resolution point (Step 3a), reuse in Step 7 — DRY

Cons:
- Glob could theoretically match a different `trackers.md` in a deep monorepo that has
  coincidentally named files. In practice this is negligible: the path `docs/reference/trackers.md`
  is specific enough. The first Glob result will be the plugin file.

### Approach B — Hardcode absolute path via __dirname equivalent

Ask the LLM to resolve the plugin installation path by reading a known anchor file (e.g.,
`.claude-plugin/plugin.json`) and computing the absolute path from there.

Pros:
- Unambiguous — cannot match a wrong file

Cons:
- Plugin installation path is not stable or standardized across environments
- Requires reading an extra file (plugin.json) at every check-setup run just to derive a path
- More fragile: if plugin metadata structure changes, path resolution breaks
- Significantly more complex for a marginal improvement over Glob

### Approach C — Copy/embed the relevant parts of trackers.md inline in SKILL.md

Move the Validation Rules table and MCP Server Detection table from `trackers.md` directly
into the skill so there is no external file dependency.

Pros:
- No path resolution needed at all — eliminates the class of problem entirely

Cons:
- Duplicates content that is maintained in one canonical place (`trackers.md`)
- Every time a new tracker is added, SKILL.md must also be updated manually — drift risk
- Much larger change surface: modifying the skill file structure, not just adding instructions
- Violates single-source-of-truth principle used throughout the plugin

### Recommendation: Approach A

Glob-first with CWD-relative fallback is the correct minimal fix. It is already consistent
with the `Glob` tool being in `allowed-tools`. The [WARN] skip on failure ensures no silent
wrong behavior. Resolving once in Step 3a and reusing in Step 7 keeps the logic clean.

---

## Overall Integration Check

| Concern | Status |
|---------|--------|
| Issue 1 uses Bash (curl probe) | `Bash` already in `allowed-tools` line 4 — no change |
| Issue 3 uses Glob | `Glob` already in `allowed-tools` line 4 — no change |
| curl not available | Approach A degrades to a manual-curl advisory — no hard failure |
| Line number shifts | Fix 3 first (lines 32, 59), then Fix 1 (lines 71-74), then Fix 2 (lines 75-77) — apply in document order to avoid drift |
| Automation Config contract | No new required or optional keys — no version bump triggered |
| Other files affected | All three fixes scoped to `skills/check-setup/SKILL.md` only |
| Output format block | Must update `### Connectivity` example after all three step edits to add TLS line and scope hint |
| Backward compatibility | Success paths and auth paths in Steps 9/10 unchanged; new branches activate only on new error patterns |

### Recommended Edit Order

1. Fix 3a — Step 3a (line 32): add Glob resolution note and fallback
2. Fix 3b — Step 7 (line 59, adjusted +4): reuse resolved path, add [WARN] on miss
3. Fix 1 — Step 9 (lines 71-74, adjusted +4): expand TLS + curl probe
4. Fix 2 — Step 10 (lines 75-77, adjusted +14): replace list with fetch-configured-remote
5. Output Format — Connectivity block (shifted down by total net additions): add TLS line, update SC scope hint

Net line additions: Fix 3a ~+5, Fix 3b ~+3, Fix 1 ~+10, Fix 2 ~+4, Output Format ~+1 = ~+23 lines total.
All three issues are independent. No fix depends on another being applied first.

### Risks and Mitigations

| Risk | Mitigation |
|------|-----------|
| curl unavailable on Windows/restricted env | Degrade to advisory message with manual curl command |
| Glob matches wrong trackers.md in monorepo | Path `docs/reference/trackers.md` is specific; first match is correct in practice |
| MCP "get repo" tool name varies by SC provider | Step 10 should say "fetch repository metadata" (intent), not a specific tool name |
| TLS patterns miss future Node.js error codes | Existing patterns cover all known variants; new ones can be added as patch fixes |
