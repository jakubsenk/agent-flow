# Phase 3 Brainstorm — Agent 3: Skeptical DX Architect
## Risk Analysis: check-setup SKILL.md Fixes

---

## Issue 1: TLS Diagnostic (Block 3 Step 9)

### Proposed solution recap
Detect TLS patterns in MCP error strings, then run a `curl` probe to distinguish "server reachable but TLS rejected" from "server genuinely unreachable". Recommend `NODE_OPTIONS: --use-system-ca` on confirmed TLS failures.

---

### Risk 1.1 — curl is not trustworthy as a TLS oracle

curl uses its own CA bundle (or the system bundle, depending on how it was compiled). Node.js MCP servers use Node's built-in TLS stack. These two stacks can reach different verdicts on the same certificate.

**Failure scenario:** Corporate CA chain is trusted by curl (via system store) but not by Node.js (which has its own embedded CA list and does NOT read the Windows Certificate Store by default). curl exits 0 and returns HTTP 200. The skill concludes "server reachable, TLS problem confirmed" and emits the `NODE_OPTIONS: --use-system-ca` message. So far so good — this is the correct fix.

**Inverted failure scenario:** curl was compiled with a minimal CA bundle (e.g., Alpine-based Docker container, or a custom Windows curl.exe). curl rejects the cert too. Exit code is non-zero. The skill falls back to "server not reachable" — the wrong message. The user checks network connectivity and wastes time, never discovering the actual TLS root cause.

**Verdict:** curl probe gives a useful signal but is not a reliable oracle. It confirms network-layer reachability, not TLS agreement between curl and Node. The probe is better than nothing, but the fallback case ("curl also fails") may still be a TLS problem in disguise.

**Adjusted recommendation:** Keep the curl probe, but change the fallback message in the "curl exit non-zero" branch. Instead of fully reverting to the unreachable message, add a conditional hint:

> If TLS patterns were detected in the MCP error AND curl also fails, emit:
> `[FAIL] "Issue tracker — connection failed (TLS or network). If using a private CA, try NODE_OPTIONS: --use-system-ca. If server is remote, verify URL."`

This preserves the TLS hint even when curl cannot confirm reachability.

---

### Risk 1.2 — curl may not be in PATH on Windows

The Phase 2 plan assumes curl is available. On Windows, curl ships with Windows 10 1803+ (as `curl.exe` in `System32`). However:
- Windows Server environments, CI runners, and locked-down corporate machines may not have it
- PATH may not include System32 in non-interactive shells
- Some environments install Git Bash or Cygwin curl, which may behave differently from native curl

**Failure scenario:** Bash tool runs the curl probe. Shell cannot find `curl`. Command exits with code 127. The skill misinterprets this as "server unreachable" (exit non-zero).

**Adjusted recommendation:** The skill must distinguish curl-not-found from curl-failure. Before interpreting exit codes, check whether curl exists:

```
which curl 2>/dev/null || where curl 2>/dev/null
```

If curl is not found → skip the probe entirely and emit the TLS hint unconditionally (since TLS patterns were already matched):
> `[FAIL] "Issue tracker — TLS error detected. Add NODE_OPTIONS: --use-system-ca to the env block in .mcp.json. (curl not available for confirmation probe)"`

This degrades gracefully without producing a false negative.

---

### Risk 1.3 — MCP error strings are not standardized

The Phase 2 plan gives a list of 8 TLS error string patterns derived from Node.js OpenSSL error codes. This works when the MCP server surfaces raw Node.js errors. But:

- MCP server implementations may wrap errors in their own JSON envelope, stripping or transforming the original error message
- Some MCP transports (stdio, SSE) may truncate long error payloads
- The error that reaches the skill is the Claude Code MCP client's representation of the failure, not necessarily the raw Node.js error text
- A proxy or gateway in front of the MCP server might replace the TLS error with a generic "Bad Gateway" or "502" message

**Failure scenario:** The MCP error contains only `"502 Bad Gateway"`. No TLS pattern matches. The skill falls to the generic unreachable bucket. No TLS hint is given. User is confused.

**Adjusted recommendation:** This is a fundamental limitation that cannot be fully solved at the skill level. Accept it explicitly in the skill's constraints or in a comment. Consider adding a broader pattern: if the error does NOT match any auth pattern and does NOT match any unreachable pattern, add a soft TLS hint to the unreachable message:
> `[FAIL] "Issue tracker — server not reachable. If using a private CA (self-signed or corporate PKI), also try NODE_OPTIONS: --use-system-ca."`

This costs one extra line and prevents silent failures in edge cases.

---

### Overall verdict for Issue 1

The proposed solution is directionally correct and covers the most common case well. Three gaps need patching:
1. Change the "curl also fails" fallback to still hint at TLS (not revert to pure unreachable message)
2. Add a curl-not-found guard to avoid false negatives on Windows
3. Add a soft TLS hint to the generic unreachable branch to catch error wrapping cases

---

## Issue 2: read:user Scope Check (Step 10)

### Proposed solution recap
Replace "list repositories via MCP" (which implies `list_my_repositories` and a `read:user` scope) with "fetch metadata for the configured Remote (owner/repo) via MCP". This verifies only the single declared repo and requires only `repository:read`.

---

### Risk 2.1 — Is it safe to remove list_my_repositories entirely?

The Phase 2 plan implicitly removes any broad listing check. The concern is whether a future pipeline update might reintroduce a need for `list_my_repositories`.

**Analysis:** Scanning all pipeline skills, no agent performs cross-repository discovery. Every operation targets the single `Remote` from Automation Config. The publisher creates PRs in that repo. The fixer pushes branches to that repo. There is no multi-repo scatter. The `list_my_repositories` call was, at best, a proxy for "token works" — a poor one because it requires more scope than the pipeline actually needs.

**Verdict:** Safe to remove. Replacing it with a targeted get-repository call is strictly better: it validates the exact permission the pipeline needs (`repository:read` on the declared remote), not a broader permission that the pipeline does not use.

**Caveat:** If a future feature adds multi-repo support (e.g., monorepo with separate frontend/backend repos), the check would need to be updated. But that future change should be driven by the new feature's requirements, not pre-emptively over-scoped today.

---

### Risk 2.2 — Should we remove it or replace it with something more useful?

The Phase 2 plan replaces, not removes. This is the right call. A pure removal would leave a gap in the setup report: users would have no way to know if their SC token is misconfigured until a `fix-ticket` run fails mid-pipeline.

**What the replacement adds that was missing:**
- 404 distinction: "repo not found" vs "auth failure" — different fixes, different messages
- Scope hint: explicitly tells the user which scope is needed (`repository:read`), not just "auth failed"
- Confirmation of the exact configured repo, not just "some repo exists"

**What could still go wrong:** The MCP tool for fetching repository metadata may vary by tracker type. For Gitea it might be `get_repository`. For GitHub it might be `get_repo`. The skill needs to handle the case where the MCP tool name is not predictable or the tool does not exist in the connected MCP server.

**Adjusted recommendation:** Add a fallback: if the get-repository MCP call fails with "tool not found" or "method not found" (as opposed to auth/network failure), emit `[WARN] "Source control MCP: repository existence check not supported — skipping"` rather than `[FAIL]`. This prevents a false failure when the SC MCP server simply lacks that specific tool.

---

### Risk 2.3 — Token scope ambiguity across SC providers

The Phase 2 plan emits "Token needs repository:read scope." This is Gitea-specific terminology. GitHub uses `repo` scope. GitLab uses `read_repository`. The message may confuse users on non-Gitea platforms.

**Adjusted recommendation:** Make the scope hint tracker-aware. If the Source Control type can be inferred from the Remote host or from a separate SC Type config key, emit the provider-appropriate scope name. As a safe fallback: use "read access to repositories" as the generic message, and note the provider-specific scope name in parentheses only when the provider is known.

---

### Overall verdict for Issue 2

The replacement approach is correct. Two refinements:
1. Add a "tool not found" guard that emits [WARN] instead of [FAIL] to handle MCP servers with limited toolsets
2. Make the scope hint generic enough to not confuse non-Gitea users

---

## Issue 3: Path Resolution (trackers.md)

### Proposed solution recap
Replace bare relative `docs/reference/trackers.md` with a Glob-based discovery (`**/docs/reference/trackers.md`), use the first result, fall back to CWD-relative path, emit [WARN] and skip if neither resolves.

---

### Risk 3.1 — Glob may match multiple files

In a monorepo or a project that vendors its plugins into a subdirectory, `**/docs/reference/trackers.md` could match:
- `vendor/ceos-agents/docs/reference/trackers.md`
- `plugins/ceos-agents/docs/reference/trackers.md`
- `docs/reference/trackers.md` (a copy in the consuming project for some reason)
- Multiple plugin versions installed at different paths

The skill says "Read the first result." But Glob results are sorted by modification time (most recently modified first per the tool description). This means the "first result" is not deterministic — it could be a stale vendored copy if the main plugin was recently updated.

**Failure scenario:** A project vendors plugin files and has a slightly older `trackers.md` copy with different tracker rules. Glob returns that copy first. The skill validates against stale rules. No error is surfaced. The user gets a false [OK] for a misconfigured query format.

**Adjusted recommendation:** Do not blindly take "first result". Instead, prefer the result whose path contains the deepest match to `.claude/plugins/ceos-agents/` or similar installation path patterns. If no such path is identifiable, take the path with the highest depth (most nested) as a proxy for "inside a plugin directory rather than in the project root". Add a [WARN] if multiple results are found: `"Multiple trackers.md found — using {path}. If wrong, verify plugin installation."` This makes the ambiguity visible.

---

### Risk 3.2 — Performance impact of Glob on large repos

Glob with `**` prefix scans the entire directory tree from CWD. On a large monorepo with hundreds of thousands of files (e.g., a full Next.js + Node.js + mobile repo with node_modules), this Glob could be slow or time out.

**Key question:** Does the Glob tool respect `.gitignore`? The tool description does not say. If it descends into `node_modules/`, the scan on a large project could take several seconds or exhaust a timeout.

**Risk severity:** Moderate. `check-setup` is an interactive diagnostic command, not a hot-code path. A few seconds of delay is tolerable. A timeout or hang is not.

**Adjusted recommendation:** Scope the Glob to a narrower prefix if possible. Since plugin installations typically live under `.claude/plugins/` or a similar directory, try that path first:

1. Try Glob on `.claude/plugins/**/docs/reference/trackers.md` (narrow scope)
2. If no results, try Glob on `**/docs/reference/trackers.md` (broad fallback)
3. If still no results, try CWD-relative `docs/reference/trackers.md`
4. If none → [WARN] and skip

This layered approach avoids the full-tree scan in the common case.

---

### Risk 3.3 — Is this actually broken in practice?

The Phase 2 plan asserts that "when the skill runs in a consuming project's working directory, the plugin's `docs/` folder is not at that path." This needs verification — it is a claim about how Claude Code resolves plugin skill working directories.

**What we know:** Claude Code skills run with the CWD set to the consuming project root. The plugin files themselves live in the Claude Code plugin registry (some path under `~/.claude/plugins/` or equivalent). A bare relative path `docs/reference/trackers.md` resolves relative to CWD — which is the consumer project, not the plugin installation directory.

**Is it broken in the current version?** Possibly not yet, if users are running check-setup from the ceos-agents repo directory itself (i.e., during development/testing of the plugin). The `tests/` harness may be running from the plugin's own root, where `docs/reference/trackers.md` exists. This would explain why no bug report has surfaced.

**The risk of fixing something that "works":** If the path is currently resolving correctly in real deployments (because Claude Code exposes the plugin directory as CWD, or because the path is somehow resolved relative to the skill file), then the Glob change would add complexity without fixing an actual bug. Worse, the Glob might match an unexpected file in the consumer project.

**Adjusted recommendation:** Before writing the fix, the plan should include a one-line empirical validation step: run `check-setup` on a real consumer project (e.g., the drmax-readmine-test project mentioned in MEMORY.md) and observe whether Step 3a produces an error or silently skips. If no error occurs, the path may already be resolving correctly by some mechanism not captured in the Phase 2 analysis. Only proceed with the Glob fix after confirming the bug manifests in production.

If the fix proceeds without validation, add a comment in the skill: `# Path note: if trackers.md is unexpectedly missing, verify plugin installation path.` This makes the assumption explicit and aids future debugging.

---

### Overall verdict for Issue 3

The proposed Glob approach addresses a real architectural concern (CWD vs plugin directory) but has three risks:
1. Multiple-match ambiguity — add a [WARN] and a path preference heuristic (prefer plugin directory paths over project root paths)
2. Performance on large repos — use a narrow Glob scope first (`.claude/plugins/`) before broad `**`
3. Unknown whether bug manifests in production — validate empirically before implementing, to avoid adding complexity for a theoretical problem

---

## Cross-cutting Observations

### Silent degradation vs. loud failure
All three fixes favor [WARN] + skip over [FAIL] when resources cannot be found. This is the right call for a diagnostic tool — a setup check that cannot check something should say so rather than crash. However, the [WARN] should always include enough context for the user to understand what was skipped and why.

### Error message quality
The proposed messages are already significantly better than the originals. The remaining gap is provider-specificity for SC token scopes (Issue 2) and the ambiguous "curl also failed" TLS message (Issue 1).

### Dependency on external tools (curl)
Introducing `curl` as a diagnostic dependency adds a fragility vector. Any skill that depends on external binaries should have an explicit "binary not found" code path. This principle applies to any future probes added to check-setup.

### Testing coverage
None of the three fixes are covered by the existing test harness (per `tests/` directory). The scenarios that would test these paths (TLS failure, Gitea `list_my_repositories` rejection, missing trackers.md) are environment-dependent and difficult to mock in a pure-markdown test suite. Acknowledge this gap and consider adding negative-case scenarios to `tests/scenarios/` that can be run manually against a real environment.
