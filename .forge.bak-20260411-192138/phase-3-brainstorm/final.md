# Phase 3 Brainstorm — Synthesis: Recommended Approach

**Synthesized from:** agent-1 (conservative), agent-2 (innovative), agent-3 (skeptical)
**Scope:** `skills/check-setup/SKILL.md` — three targeted fixes only

---

## Recommended Approach (per issue)

### Issue 1: TLS Diagnostic

**Approach:** Pattern-detect TLS error strings first, then run a curl probe to confirm network reachability. Apply three-tier output based on outcome.

**Detection patterns** (Node.js OpenSSL error codes):
`UNABLE_TO_VERIFY_LEAF_SIGNATURE`, `CERT_UNTRUSTED`, `SELF_SIGNED_CERT`,
`self signed certificate`, `certificate verify failed`, `ERR_TLS_`,
`DEPTH_ZERO_SELF_SIGNED_CERT`, `unable to get local issuer certificate`

**Curl probe** (runs only when a TLS pattern is matched):
```
curl -s -o /dev/null -w "%{http_code}" --max-time 5 {Instance}
```

**Three-tier output logic:**

1. **curl exits 0 and HTTP code != 000** → server is reachable, TLS is the confirmed problem
   → `[FAIL] "Issue tracker — TLS error. Add NODE_OPTIONS: --use-system-ca to the env block in .mcp.json"`

2. **curl exits non-zero AND TLS patterns were matched** → TLS or network; do NOT revert to a pure unreachable message
   → `[FAIL] "Issue tracker — connection failed (TLS or network). If using a private CA, try NODE_OPTIONS: --use-system-ca. If server is remote, verify URL."`
   *(Skeptic's correction: curl failing does not disprove TLS — curl may use a different CA bundle than Node.js)*

3. **curl not found** (`which curl`/`where curl` returns nothing, or Bash exits 127) → skip probe, emit TLS hint unconditionally since patterns were already matched
   → `[FAIL] "Issue tracker — TLS error detected. Add NODE_OPTIONS: --use-system-ca to .mcp.json. (curl not available for confirmation probe)"`

**Soft TLS hint on generic unreachable** (skeptic's Risk 1.3 — error wrapping by proxies/gateways): If no auth pattern AND no TLS pattern matches, append to the unreachable message:
→ `"If using a private CA (self-signed or corporate PKI), also try NODE_OPTIONS: --use-system-ca."`

**TLS patterns are checked BEFORE auth patterns** (agent-2 ordering note: TLS errors occur at handshake layer before HTTP is established).

**No frontmatter changes needed** — `Bash` already in `allowed-tools`.

---

### Issue 2: SC Connectivity

**Approach:** Replace "list repositories via MCP" with a targeted fetch of the specific `Remote` (owner/repo) declared in Automation Config. Three error branches with distinct messages.

**Step 10 rewrite logic:**
1. Use MCP to fetch repository metadata for the configured `Remote` value
2. **Success** → `[OK] "Source control MCP — connected (confirmed: {owner/repo})"`
3. **Auth failure (401/403)** → `[FAIL] "Token needs read access to repositories (repository:read for Gitea, repo for GitHub, read_repository for GitLab)"` — generic enough to not confuse non-Gitea users (skeptic's Risk 2.3)
4. **Not found (404)** → `[FAIL] "Repository {owner/repo} not found — verify Remote value in Automation Config"`
5. **Tool not found** (MCP server lacks a get-repository method) → `[WARN] "Source control MCP: repository existence check not supported — skipping"` — not a `[FAIL]` (skeptic's Risk 2.2)
6. **Unreachable** → `[FAIL] "Source control MCP — not reachable (network or MCP server issue)"`

The instruction uses **intent** ("fetch repository metadata"), not a specific tool name, to handle MCP tool name variation across providers (agent-1 integration check; skeptic's Risk 2.2).

**No frontmatter changes needed.**

---

### Issue 3: Path Resolution

**Approach:** Layered Glob resolution with a narrow-first strategy to avoid performance issues on large repos, multiple-match disambiguation, and explicit [WARN] on failure.

**Resolution sequence** (run once in Step 3a; resolved path reused in Step 7):

1. Try narrow Glob: `.claude/plugins/**/docs/reference/trackers.md`
2. If no results, try broad Glob: `**/docs/reference/trackers.md`
3. If no results, try CWD-relative: `docs/reference/trackers.md`
4. If none resolve → `[WARN] "trackers.md not found — per-tracker validation skipped. Verify plugin installation."` and skip tracker-specific validation

**Multiple-match handling** (skeptic's Risk 3.1 — modification-time ordering is non-deterministic): If Glob returns multiple results, prefer the path containing a plugin-directory pattern (`.claude/plugins/`, `ceos-agents/`). If none match that heuristic, emit `[WARN] "Multiple trackers.md found — using {path}. If wrong, verify plugin installation."` before proceeding.

**Step 7 reuse:** Does not re-run the Glob. Uses the path already resolved in Step 3a (stored in a local variable / noted in the step). If Step 3a emitted [WARN], Step 7 also skips and notes [SKIP] "trackers.md unavailable (see Step 3a)".

**Validation note** (skeptic's Risk 3.3): Add a comment in the skill: `# Path note: if trackers.md is unexpectedly missing, verify plugin installation path. Glob is used to handle consuming-project CWD context.` This makes the assumption explicit and aids future debugging without delaying the fix.

**No frontmatter changes needed** — `Glob` already in `allowed-tools`.

---

## Edge Cases to Handle

From agent-3 (skeptical) analysis:

| Edge Case | Issue | Guard |
|-----------|-------|-------|
| curl uses different CA bundle than Node.js — curl succeeds but TLS still failed | 1 | Tier 2 fallback always retains TLS hint even when curl fails |
| curl not in PATH (Windows Server, CI, locked-down corp) | 1 | `which curl`/`where curl` check before probe; degrade to unconditional TLS hint |
| MCP error wrapped by proxy/gateway (e.g., "502 Bad Gateway") — no TLS pattern matches | 1 | Soft TLS hint appended to generic unreachable message |
| SC MCP server lacks a get-repository tool (limited toolset) | 2 | "tool not found" → [WARN] not [FAIL] |
| SC token scope hint is Gitea-specific — confuses GitHub/GitLab users | 2 | Generic message listing provider-specific scope names |
| Glob returns multiple `trackers.md` files (monorepo, vendored plugin) | 3 | Prefer plugin-directory paths; emit [WARN] on ambiguity |
| Large repo with node_modules — broad `**` Glob is slow or times out | 3 | Narrow Glob on `.claude/plugins/` first; broad Glob only as fallback |
| trackers.md bug may not manifest if users only run check-setup from plugin repo | 3 | Add inline comment documenting the CWD assumption |

---

## Out-of-Scope Follow-ups

From agent-2 (innovative) systemic perspective — log to roadmap, do not implement now:

1. **Consolidate Step 9 + Step 10 into `core/mcp-detection.md` delegation** — extend `mcp-detection.md` output contract with a structured `error_type` field (`"tls" | "auth" | "not_found" | "unreachable" | "unknown"`). Steps 9 and 10 become 3-line lookups. Clean v2 of connectivity checks. Trigger: after TLS fixes land in both steps.

2. **Apply Glob convention to all 13+ bare `trackers.md` references** — `skills/onboard/SKILL.md` (5 references), `skills/scaffold/SKILL.md` (3 references), `skills/init/SKILL.md` (1 reference), `core/mcp-detection.md` (1 reference). Add a one-liner to the plugin's CLAUDE.md "When Editing" section: "When referencing files in `docs/reference/`, always use Glob with pattern `**/docs/reference/{file}.md` — never bare relative paths."

3. **Apply TLS diagnostic to Step 10** — Step 10 (SC MCP) will have the same TLS misclassification problem if the SC server runs behind a private CA. Sequencing: Fix 1/2/3 → commit → new task for Step 10 TLS + mcp-detection.md extension.

4. **Negative-case test scenarios** — add manual test scenarios to `tests/scenarios/` for: TLS failure on issue tracker, Gitea `list_my_repositories` rejection, missing trackers.md in consumer project CWD. Environment-dependent; cannot be mocked in current markdown harness.

---

## Decision Summary Table

| Issue | Approach | Key risk | Mitigation |
|-------|----------|----------|------------|
| 1: TLS Diagnostic | Pattern-detect TLS + curl probe + three-tier output | curl uses different CA bundle than Node.js; curl not in PATH | Tier 2 retains TLS hint on curl failure; `which/where curl` guard before probe; soft TLS hint on generic unreachable |
| 2: SC Connectivity | Replace list-repositories with targeted get-repository for configured Remote | MCP tool name varies by provider; scope hint is Gitea-specific | Use intent not tool name; provider-aware scope message with generic fallback; [WARN] not [FAIL] on tool-not-found |
| 3: Path Resolution | Layered Glob (narrow → broad → CWD fallback) + multiple-match disambiguation | Glob matches wrong file in monorepo; broad `**` slow on large repos | Prefer plugin-directory paths on multi-match; narrow `.claude/plugins/` Glob first |

---

## Implementation Notes

- All three fixes are scoped to `skills/check-setup/SKILL.md` only
- No frontmatter changes needed (`Bash` and `Glob` already in `allowed-tools`)
- No Automation Config contract changes — no version bump triggered
- Recommended edit order (avoid line-number drift): Fix 3a (Step 3a) → Fix 3b (Step 7) → Fix 1 (Step 9) → Fix 2 (Step 10) → update Output Format block
- Net additions: ~+28 lines across all fixes
- Output Format `### Connectivity` example block must be updated after edits to reflect new TLS line and corrected SC scope hint
