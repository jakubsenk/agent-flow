# Formal Acceptance Criteria — check-setup SKILL.md Fixes

**Target file:** `skills/check-setup/SKILL.md`
**Total criteria:** 14 (AC-1 through AC-14)

---

## Fix 1: TLS Diagnostic (Step 9)

### AC-1: TLS pattern detection triggers NODE_OPTIONS recommendation

**Description:** When an MCP error in Step 9 contains any recognized TLS pattern (`UNABLE_TO_VERIFY_LEAF_SIGNATURE`, `CERT_UNTRUSTED`, `SELF_SIGNED_CERT`, `self signed certificate`, `certificate verify failed`, `ERR_TLS_`, `DEPTH_ZERO_SELF_SIGNED_CERT`, `unable to get local issuer certificate`), the output `[FAIL]` message includes the string `NODE_OPTIONS: --use-system-ca`.

**Verification:** Grep the Step 9 replacement text. Confirm that every TLS-classified branch (curl success, curl failure, curl absent) produces a message containing `NODE_OPTIONS`.

**PASS:** All three TLS sub-branches in Step 9 include `NODE_OPTIONS: --use-system-ca` in their output message.
**FAIL:** Any TLS sub-branch omits the `NODE_OPTIONS` recommendation.

---

### AC-2: Curl probe confirms reachability when TLS pattern matched

**Description:** When a TLS pattern is matched, Step 9 instructs a curl probe (`curl -s -o /dev/null -w "%{http_code}" --max-time 5 {Instance}`). If curl exits 0 and HTTP code is not `000`, the message explicitly states the server is reachable and identifies TLS as the problem.

**Verification:** Read the curl-success sub-branch text. Confirm it contains language indicating server reachability and TLS as the cause.

**PASS:** The curl-success branch message contains both "reachable" (or equivalent) and "TLS" (or equivalent).
**FAIL:** The curl-success branch lacks either reachability confirmation or TLS identification.

---

### AC-3: TLS hint retained when curl fails or is absent

**Description:** When TLS patterns are matched but curl either fails (non-zero exit / HTTP 000) or is not found (`which curl` returns nothing), the message still includes the `NODE_OPTIONS: --use-system-ca` hint. The message must NOT fall back to a pure "not reachable" message that omits TLS guidance.

**Verification:** Read both the curl-failure and curl-absent sub-branches. Confirm each contains `NODE_OPTIONS`.

**PASS:** Both curl-failure and curl-absent branches include `NODE_OPTIONS: --use-system-ca`.
**FAIL:** Either branch drops to a message without TLS guidance.

---

### AC-4: Soft TLS hint on generic unreachable

**Description:** When Step 9 encounters an error that matches neither TLS patterns nor auth patterns (generic unreachable), the `[FAIL]` message includes a soft hint about `NODE_OPTIONS: --use-system-ca` as a possibility for private CA environments.

**Verification:** Read the "any other error" fallback branch. Confirm it contains `NODE_OPTIONS` or equivalent private-CA hint.

**PASS:** The generic unreachable branch includes a soft TLS/private-CA hint.
**FAIL:** The generic unreachable branch contains only a plain "not reachable" message with no TLS mention.

---

### AC-5: TLS checked before auth in classification order

**Description:** In Step 9's error classification, TLS patterns are evaluated before auth patterns. This ensures that TLS handshake failures (which occur before HTTP-level auth) are not misclassified as auth errors.

**Verification:** Read the Step 9 replacement. Confirm the numbered classification order lists TLS (with its patterns) as item 1 and auth as item 2.

**PASS:** TLS classification appears before auth classification in the ordered list.
**FAIL:** Auth classification appears before or at the same level as TLS classification.

---

## Fix 2: SC Connectivity (Step 10)

### AC-6: Targeted repo fetch replaces list-repositories

**Description:** Step 10 instructs the agent to fetch metadata for the specific repository declared in `Source Control → Remote` (owner/repo), not to list or enumerate all repositories.

**Verification:** Read Step 10 replacement text. Confirm it references "Remote" from Automation Config and uses intent-based language like "fetch repository metadata" for the specific repo. Confirm the text does NOT contain "list repositories".

**PASS:** Step 10 references the configured Remote value and fetches metadata for that specific repo. No mention of listing repositories.
**FAIL:** Step 10 still says "list repositories" or does not reference the specific Remote value.

---

### AC-7: Auth failure includes scope hint

**Description:** The 401/403 auth failure branch in Step 10 includes a scope hint that mentions `repository:read` (Gitea) and is generic enough for other providers.

**Verification:** Read the auth-failure branch. Confirm it contains `repository:read`.

**PASS:** The auth-failure message includes `repository:read` (and optionally provider-specific alternatives like `repo` for GitHub, `read_repository` for GitLab).
**FAIL:** The auth-failure message omits `repository:read` or uses only a single provider-specific scope.

---

### AC-8: 404 produces distinct not-found message

**Description:** A 404 response in Step 10 produces a distinct message directing the user to verify the Remote value in Automation Config, separate from the auth error message.

**Verification:** Read Step 10 replacement. Confirm there is a separate 404/not-found branch with a message that mentions verifying Remote in Automation Config.

**PASS:** 404 is a separate branch with a message containing "not found" and referencing Remote / Automation Config.
**FAIL:** 404 is merged into the auth-failure branch, or the message does not mention verifying Remote.

---

### AC-9: Tool-not-found degrades to WARN

**Description:** If the MCP server does not support a repository metadata fetch tool, Step 10 emits `[WARN]` (graceful skip), not `[FAIL]`.

**Verification:** Read Step 10 replacement. Confirm there is a "tool not found" branch that produces `[WARN]`, not `[FAIL]`.

**PASS:** The tool-not-found branch uses `[WARN]` severity.
**FAIL:** The tool-not-found branch uses `[FAIL]` severity, or the branch does not exist.

---

## Fix 3: Path Resolution (Steps 3a and 7)

### AC-10: Glob-first resolution with plugin-directory preference

**Description:** Step 3a locates `trackers.md` using Glob with `.claude/plugins/` path preference before falling back to broader patterns or CWD-relative path.

**Verification:** Read Step 3a replacement. Confirm it specifies a Glob with `.claude/plugins/**` pattern as the first attempt, followed by a broader `**/docs/reference/trackers.md` pattern, followed by a CWD fallback.

**PASS:** Step 3a has a three-layer resolution: narrow Glob (`.claude/plugins/`), broad Glob (`**`), CWD fallback — in that order.
**FAIL:** Step 3a uses only a bare relative path, or the resolution order is different.

---

### AC-11: Missing trackers.md produces WARN with skip

**Description:** If `trackers.md` cannot be found by any resolution method, Step 3a emits `[WARN]` and skips per-tracker validation. It does not emit `[FAIL]` and does not crash.

**Verification:** Read Step 3a replacement. Confirm the file-not-found case produces `[WARN]` with "per-tracker validation skipped" and a skip instruction.

**PASS:** File-not-found case emits `[WARN]`, mentions skipping, and instructs to skip the rest of Step 3a.
**FAIL:** File-not-found case emits `[FAIL]`, or does not instruct to skip, or is not handled.

---

### AC-12: Step 7 reuses resolved path without re-globbing

**Description:** Step 7 reuses the `trackers.md` path already resolved in Step 3a. It does not run Glob again. If Step 3a could not find the file, Step 7 also skips with `[WARN]`.

**Verification:** Read Step 7 replacement. Confirm it references Step 3a's resolved path, explicitly says not to Glob again, and has a skip branch for when Step 3a failed.

**PASS:** Step 7 references "Step 3a", does not invoke Glob, and has a `[WARN]` skip branch for unavailable trackers.md.
**FAIL:** Step 7 runs its own Glob, or does not handle the case where Step 3a failed.

---

## Output Format and No Regression

### AC-13: Output format includes TLS failure example

**Description:** The `### Connectivity` block in the `## Output format` section includes at least one TLS-specific `[FAIL]` line that mentions `NODE_OPTIONS: --use-system-ca`.

**Verification:** Read the Output format section. Check the Connectivity block for a TLS failure example line.

**PASS:** Connectivity block contains a `[FAIL]` line with `NODE_OPTIONS: --use-system-ca` or equivalent TLS message.
**FAIL:** Connectivity block has no TLS-specific failure example.

---

### AC-14: No regression in unchanged sections

**Description:** All sections outside the five edit locations (frontmatter, Block 1, Block 2 non-Step-7 lines, Block 4, Block 5, Rules, Output format non-Connectivity lines, Verdict) remain unchanged in content.

**Verification:** Diff the modified file against the original. Confirm that only the five specified edit regions (Step 3a, Step 7 lines 59-60, Step 9, Step 10, Output Connectivity block) have changes.

**PASS:** No unintended modifications outside the five edit regions.
**FAIL:** Any content change detected outside the five edit regions.

---

## Summary Matrix

| AC | Fix | Verification Method | Severity |
|----|-----|-------------------|----------|
| AC-1 | Fix 1 (TLS) | Grep for `NODE_OPTIONS` in all TLS branches | Blocking |
| AC-2 | Fix 1 (TLS) | Read curl-success branch text | Blocking |
| AC-3 | Fix 1 (TLS) | Read curl-failure and curl-absent branches | Blocking |
| AC-4 | Fix 1 (TLS) | Read generic-unreachable branch | Blocking |
| AC-5 | Fix 1 (TLS) | Check classification order in Step 9 | Blocking |
| AC-6 | Fix 2 (SC) | Read Step 10 for targeted fetch, no "list" | Blocking |
| AC-7 | Fix 2 (SC) | Read auth-failure branch for scope hint | Blocking |
| AC-8 | Fix 2 (SC) | Read 404 branch for distinct message | Blocking |
| AC-9 | Fix 2 (SC) | Read tool-not-found branch for WARN level | Blocking |
| AC-10 | Fix 3 (Path) | Read Step 3a for Glob layered resolution | Blocking |
| AC-11 | Fix 3 (Path) | Read Step 3a for WARN on missing file | Blocking |
| AC-12 | Fix 3 (Path) | Read Step 7 for reuse + skip branch | Blocking |
| AC-13 | Output | Read Output format Connectivity block | Blocking |
| AC-14 | No regression | Diff original vs modified file | Blocking |
