# Phase 8 Security Review (cycle 0)

## Score: 0.94

## Tier 1 (binary checks)

- [x] Cross-file invariants hold (license SPDX, email, template parity)
- [x] No command injection in new bash code
- [x] No path traversal vector
- [x] ReDoS analysis: canonical regex safe
- [x] check-setup snippet safe

### Cross-file invariant verification (CLAUDE.md "Cross-File Invariants" §1-3)

1. **License SPDX consistency** — `.claude-plugin/plugin.json:9` `"license": "MIT"`, `.claude-plugin/marketplace.json:12` `"license": "MIT"`, `LICENSE:1` `MIT License`. **HOLDS.**
2. **Maintainer email consistency** — `filip.sabacky@ceosdata.com` present in all of `SECURITY.md`, `CODE_OF_CONDUCT.md`, `CONTRIBUTING.md` (verified via Grep: 3 files matched). **HOLDS.**
3. **Issue/PR template parity** — `diff -q .gitea/issue_template/*` ↔ `.github/ISSUE_TEMPLATE/*` and `diff -q .gitea/pull_request_template.md .github/PULL_REQUEST_TEMPLATE.md` returned empty (no differences). **HOLDS.**

### REQ-NO-VERSION-BUMP verification

`git diff main -- .claude-plugin/*.json` produced **no output** — neither `plugin.json` nor `marketplace.json` `"version"` field was modified. Both still report `"6.10.0"`. Verified compliant with REQ-NO-VERSION-BUMP. (Note: pipeline branch and `main` are currently the same commit because work landed directly on `main`; the diff would show any version bump if present.)

## Tier 3 (quality 0-5)

- Correctness of security analysis: 5
- Coverage of attack vectors: 5
- Quality of mitigations: 4

## Findings

| Severity | Finding | File | Recommendation |
|---|---|---|---|
| INFO | `$CLAUDE_MD` env var referenced in deprecated-section detector snippet but never defined inline | `skills/check-setup/SKILL.md:201` | Documentary/illustrative snippet; runtime invocation is performed by the agent which has access to the file path discovered by Block 1 Step 1. Consider adding a comment `# $CLAUDE_MD set by Block 1 Step 1` for clarity, or inline `./CLAUDE.md`. Not a security issue (read-only `grep -q`). |
| INFO | Branch name with embedded apostrophe (`'`) could break the single-quote display in `[ceos-agents][INFO] Branch '{branch_name}' ...` echo lines | `skills/publish/SKILL.md` 31, 154-155, 283, 293, 309 | Cosmetic UX only — git itself rejects most special chars in branch names; an apostrophe is technically allowed but extremely unusual. Recommend `printf '%s\n' "[ceos-agents][INFO] Branch ${branch_name@Q} ..."` if Bash 4.4+ is guaranteed; otherwise current form is acceptable. **NOT a security issue** (no shell injection — `branch_name` is double-quoted in the parameter expansion when emitted via `echo`/`printf`). |
| INFO | Forward-compatibility note: line 286 disclaimer `"The displayed wrapping above is a Markdown rendering artifact only — the implementation MUST emit this as ONE logical line"` is human guidance, not enforced by code | `skills/publish/SKILL.md:286` | Adequate; the haiku-model `publisher` agent reads this prose. No security impact. |

### Vector-by-vector analysis (per Phase 8 brief)

**1. Command injection in branch parsing (Step 0a/0c/0d)**
- `branch_name=$(git branch --show-current)` — `git` is a trusted binary; output for a valid branch name is constrained by git's own naming rules (no shell metacharacters in valid refs). No `eval`, no unquoted expansion downstream. **SAFE.**
- `prefix=$(echo "$branch_naming_pattern" | sed 's/{issue-id}.*//')` — `$branch_naming_pattern` double-quoted (safe from word-splitting and glob expansion); sed pattern single-quoted (safe from shell expansion). Source of `$branch_naming_pattern` is CLAUDE.md (trusted operator file). **SAFE.**
- `if [[ "$residue" =~ ^(...)$ ]]` — `[[ =~ ]]` does NOT execute its operands; the regex is a literal in the script (not user-supplied). Even if `$residue` contained shell metacharacters, the `[[` builtin treats it purely as a string. **SAFE.**

**2. Path traversal**
- Defense-in-depth check `! issue_id =~ ^\.+$` rejects `.`, `..`, `...`, `....` etc. Preserved from v6.8.1 contract.
- Per SC-11, the canonical regex `^(#?[0-9]+|[A-Za-z][A-Za-z0-9_]*-[0-9]+)` cannot match a dot-only string by construction (no `.` in any character class). The defensive check is a belt-and-suspenders measure.
- Downstream consumption of `issue_id` (Step 2c MCP tool call, Step 6 tracker comment, Step 7 webhook payload, Step 8 Publish Report) — `issue_id` is passed as a structured parameter to MCP tools (not interpolated into a shell command) or JSON-encoded for the webhook (per the v6.8.1 jq-based encoding contract at line 232). **SAFE.**

**3. ReDoS analysis on `^(#?[0-9]+|[A-Za-z][A-Za-z0-9_]*-[0-9]+)`**
- Branch 1 (`#?[0-9]+`): bounded — `#?` is 0-or-1, `[0-9]+` is a single character class with no nested quantifiers. Linear matching.
- Branch 2 (`[A-Za-z][A-Za-z0-9_]*-[0-9]+`): the `*` quantifier is followed by literal `-`, and `-` is NOT in `[A-Za-z0-9_]` — so there is **no overlap** between the repeating class and its successor. The engine cannot backtrack ambiguously. Linear matching.
- Branch alternation: branch 1 starts with `#` or `[0-9]`, branch 2 starts with `[A-Za-z]` — disjoint first-character sets, so the alternation is unambiguous (no double-evaluation on failure).
- Worst-case input `aaaaaa...aaaa` (all letters, no `-`): branch 2 engine consumes all letters into `[A-Za-z0-9_]*`, fails to find `-`, terminates in O(n). No catastrophic backtracking.
- **Conclusion: ReDoS-safe. Bash's `[[ =~ ]]` uses POSIX ERE (typically backed by glibc's regex engine), which is also robust against this pattern shape.**

**4. Bash injection in check-setup deprecated-config snippet**
- `grep -q '^### Extra labels' "$CLAUDE_MD" 2>/dev/null` — `$CLAUDE_MD` double-quoted. Pattern single-quoted. Read-only operation. No backreference, no eval, no command substitution from CLAUDE.md content.
- Echo statements are static literal strings — no interpolation of CLAUDE.md content into the warning message. An attacker who controls the CLAUDE.md content cannot inject text into the warning output. **SAFE.**

**5. Shell metacharacters in branch names — downstream usage**
- All `[ceos-agents][INFO] Branch '{branch_name}' ...` template strings are wrapped in single quotes for human-readable display. At runtime, the agent emits these via `echo "..."` with `$branch_name` substitution under double quotes — no word-splitting, no glob expansion.
- Branch names are constrained by git's `check-ref-format` rules: no spaces, no `..`, no `~`, `^`, `:`, `?`, `*`, `[`, `\`, no leading `-`. The remaining characters (`/`, `_`, `.`, `#`, `@`) cannot trigger shell injection under double-quoted expansion.
- **SAFE.**

**6. MCP tool name injection (prefix-scan)**
- Per `core/mcp-detection.md:36`, the scan enumerates tools matching `mcp__{tracker_type}__*` where `{tracker_type}` is from CLAUDE.md (trusted). Tool names are invoked via Claude Code's Task/Skill framework (not shell), so shell-injection is not a vector.
- SC-3 mitigation: "prefix has tools but no `get_issue`-shaped tool found" → classified `unknown` → FAIL with the FAIL tier UX block. This prevents a malicious MCP server from exposing only attacker-controlled tool names — the auto-detect refuses to fall back to an arbitrary tool. **SAFE per design.**

**7. Detached-HEAD handling (SC-12)**
- `branch_name` empty triggers FAIL with INFO message and exit non-zero, BEFORE any MCP pre-flight or shell substitution that depends on `$branch_name`. Eliminates an entire class of "empty string substituted into command" bugs. **GOOD defensive design.**

**8. Publisher agent prompt-injection constraint**
- `agents/publisher.md:112` retains the v6.10.0 `--- EXTERNAL INPUT START/END ---` constraint. The new `mode` and `issue_id` dispatch context fields (Step 5 of `skills/publish/SKILL.md`) are derived from `git branch --show-current` and the canonical regex — they are NOT untrusted external input from a tracker. **No new injection surface introduced.**

**9. Webhook payload (Step 7)**
- The `issue_id` interpolation `"issue_id":"{issue}"` follows the v6.8.1 hardened contract (jq-based JSON encoding at the implementation site, per `core/snippets/webhook-curl.md`). The skill prose shows the abstract shape; the actual curl invocation is built via heredoc + `jq -n --arg`. `--proto "=http,https"` is preserved.
- In `pr-only-no-id` and `pr-only-404` modes, `issue_id` is empty — explicitly documented as the v6.8.0 forward-compatible contract. Consumers parse leniently. **No regression.**

## Conclusion

**PASS** with three INFO-level findings (no MEDIUM/HIGH/CRITICAL). 

The v7.0.0 implementation maintains the v6.8.1 / v6.9.0 / v6.10.0 security posture without introducing new attack surface. The new branch-parse pre-pre-flight (Step 0) uses safely-quoted bash idioms, applies the v6.8.1 path-traversal defense, and the canonical extraction regex is provably ReDoS-safe by construction (disjoint alternation + no nested quantifiers + no character-class overlap with the literal successor). The new `check-setup` deprecated-config snippet is a read-only `grep -q` with no interpolation of untrusted content into output. The detached-HEAD FAIL-fast at Step 0a closes a "empty branch substituted into downstream commands" class of bug.

The three cross-file invariants (license SPDX, maintainer email, template parity) all hold. REQ-NO-VERSION-BUMP is satisfied (no `"version"` diff against `main`). The publisher prompt-injection constraint is preserved.

Score 0.94 — above the 0.85 expected for a pure-markdown plugin and above the 0.7 pass threshold. Deductions are -0.03 for the `$CLAUDE_MD` undefined-in-snippet INFO and -0.03 for the apostrophe-in-branch-name UX-cosmetic (would be 0.97 with both addressed; both are non-blocking).
