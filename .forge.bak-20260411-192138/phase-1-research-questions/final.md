# Phase 1 Research: Synthesized Findings

**Synthesized by:** Synthesis Agent
**Date:** 2026-04-11
**Sources:** agent-1.md (Q1 + Q4), agent-2.md (Q2), agent-3.md (Q3)

---

## Research Summary

### Q1: TLS Diagnostic Approach

**Current behavior (HIGH confidence — file read):** `skills/check-setup/SKILL.md` lines 69–77, Block 3 step 9 classifies MCP connectivity failures into exactly 2 buckets:
- Auth error → "authentication failed — check your token"
- Timeout/connection refused → "not reachable — verify the server is running and URL is correct"

There is no third bucket for TLS failures. A TLS error (`UNABLE_TO_VERIFY_LEAF_SIGNATURE`, `self-signed certificate`) falls into the "not reachable" bucket, giving a misleading recommendation. This classification was intentionally introduced per `CHANGELOG.md` line 685 but TLS was not considered at that time.

**Node.js TLS error string (UNCERTAIN — no codebase evidence):** Node.js is expected to surface "fetch failed" / "unable to verify the first certificate" — but the exact format through the MCP layer is unconfirmed. `core/mcp-detection.md` step 3 captures the raw error string and passes it to callers; no caller inspects it for TLS keywords.

**`NODE_OPTIONS: "--use-system-ca"` (UNCERTAIN for npx propagation):** This is the correct, secure solution for Node.js 20+ in internal/corporate CA environments. It is absent from the codebase (grep confirmed 0 matches for `NODE_OPTIONS`, `--use-system-ca`, `NODE_TLS`, `TLS`, `certificate`, `UNABLE_TO_VERIFY`). `NODE_TLS_REJECT_UNAUTHORIZED=0` is the insecure alternative and must NOT be recommended. For npx-launched MCP servers, `NODE_OPTIONS` must be set in the `.mcp.json` `env` block for the specific server — global environment settings do not propagate.

**Curl as diagnostic tool (HIGH confidence):** curl uses the system CA store by default, unlike Node.js which uses its own bundled Mozilla CA list. This means `curl -s -o /dev/null -w "%{http_code}" --max-time 5 {url}` (without `--insecure`) will return a real HTTP status code when Node.js fails with `UNABLE_TO_VERIFY_LEAF_SIGNATURE` against an internal CA. curl is already used across the codebase:
- `skills/init/SKILL.md` lines 172–177 (binary downloads, release tags)
- `core/block-handler.md` line 39, `core/post-publish-hook.md` line 18, `skills/fix-bugs/SKILL.md` lines 578/626/660 (webhook notifications)
- `skills/check-setup/SKILL.md` frontmatter line 4 allows `Bash`, so curl can be used directly

**Proposed diagnostic flow (not yet in codebase):**
1. MCP call fails
2. Run `curl -s -o /dev/null -w "%{http_code}" --max-time 5 {instance_url}` (no `--insecure`)
3. HTTP 2xx/3xx/4xx → server reachable, Node.js TLS verification is the issue → `[FAIL]` with TLS guidance pointing to `NODE_OPTIONS: "--use-system-ca"` in `.mcp.json` env block (requires Node.js 20+)
4. HTTP 000 / exit non-zero → server genuinely unreachable → existing "not reachable" message

**Caveat:** On Windows (current dev platform), curl via Git Bash supports `--max-time`; modern curl versions bundled with Windows 10+ support this flag.

---

### Q2: Pipeline SC Usage / Token Scope

**`list_my_repositories`: 0 matches** across all 738 markdown files — this tool name does not exist anywhere in the codebase.

**No repository listing tool is hardcoded** in any normative definition. `check-setup/SKILL.md` step 10 says only "list repositories via MCP" and `core/mcp-detection.md` says "verify the declared remote exists" — both are prose descriptions leaving specific tool selection to runtime LLM judgment.

The only specific Gitea/Forgejo MCP tool names that appear anywhere in the repository:
- `mcp__gitea__list_repos` — 1 occurrence, `docs/plans/2026-02-25-v1.2-installation-docs-design.md` line 140 (historical design plan, non-normative)
- `mcp__gitea__create_pull_request` — 1 occurrence, `docs/plans/brainstorm/05-fix-bugs-token-discovery.md` line 23 (brainstorm doc, non-normative)

Normative files (skills/, agents/, core/) use only the wildcard prefix `mcp__gitea__*` or `mcp__forgejo__*` at 4 locations:
- `core/mcp-detection.md` line 27 (lookup table)
- `skills/fix-bugs/SKILL.md` line 354, `skills/fix-ticket/SKILL.md` line 367, `skills/implement-feature/SKILL.md` line 410 (PR creation tables)

**`read:user` scope: 0 matches** anywhere in the codebase. This scope concept does not exist here. `check-setup` step 10 has no explicit scope check — it is entirely emergent from runtime API call success/failure. `docs/guides/tokens.md` documents the required Gitea scopes as `repository:read`, `repository:write`, `issue:write` — no `read:user` mention. The `core/mcp-detection.md` SC check ("verify the declared remote exists") requires `repository:read`, not `read:user` (a GitHub-specific concept for listing the authenticated user's own repos).

**No agent references repository listing tools** — 0 matches in all 19 agent definitions. `agents/publisher.md` references SC MCP only generically.

---

### Q3: Plugin Path Resolution

**Scope of `trackers.md` references:** 14 files total contain `trackers.md` references. 7 source files (skills, core, tests) reference `docs/reference/trackers.md` as a bare relative path:
- `skills/check-setup/SKILL.md` lines 32, 59
- `skills/onboard/SKILL.md` lines 68, 70, 72, 75, 76, 108
- `skills/scaffold/SKILL.md` lines 93, 169, 484, 543
- `skills/init/SKILL.md` line 36
- `core/mcp-detection.md` line 19

All are bare relative paths — no `${CLAUDE_PLUGIN_ROOT}` or `${CLAUDE_SKILL_DIR}` prefix.

**Available path variables (from official Claude Code plugin docs, confirmed in filip-superpowers research):**

| Variable | Resolves to |
|----------|-------------|
| `${CLAUDE_PLUGIN_ROOT}` | Absolute path to plugin's installation directory |
| `${CLAUDE_SKILL_DIR}` | Directory containing the current skill's SKILL.md |
| `${CLAUDE_PLUGIN_DATA}` | Persistent directory for plugin state |
| `${CLAUDE_SESSION_ID}` | Current session ID |

`${CLAUDE_PLUGIN_ROOT}` is used in shell hook commands (settings.json) and documented in `02-real-plugin-comparison.md` Finding 1.9: "All script paths and hook commands MUST use `${CLAUDE_PLUGIN_ROOT}` because plugins are cached at `~/.claude/plugins/cache/`. Hardcoded relative paths will break." The `forge` skill (filip-superpowers) uses `${CLAUDE_SKILL_DIR}/dispatch/phase-0.md` in LLM-executed Read instructions, confirming the LLM can resolve these variables.

**Root cause analysis:** ceos-agents exclusively uses bare relative paths across all 26 skills and 11 core contracts. The `trackers.md` file exists at the plugin cache path (`C:/Users/FSABACKY/.claude/plugins/cache/ceos-agents/ceos-agents/6.1.9/docs/reference/trackers.md`) but NOT in consuming project directories.

**Two possible realities (ambiguity not fully resolved):**
1. **Bug exists:** The LLM executes `Read("docs/reference/trackers.md")` resolving against CWD (consuming project root) — file not present there. Silent fallback to inference.
2. **No bug:** Claude Code resolves bare relative paths in skill content against CLAUDE_PLUGIN_ROOT automatically — evidenced by the fact that `core/*.md` references work in consuming projects (otherwise all pipeline skills would be broken).

**Evidence favoring the bug:** The user's bug report explicitly states "cesta je relativní k ceos-agents root, ne ke skill directory" — the path resolves against the plugin root, not the skill directory. This implies that when the LLM issues a Read tool call, Claude Code uses CWD (consuming project), not the plugin root. The failure is specific to the `Read` tool call filesystem operation, not the SKILL.md loading itself.

**Recommended fix (per agent-3):**
- Option A (safest): Replace bare path references in check-setup/SKILL.md lines 32 and 59 with `${CLAUDE_PLUGIN_ROOT}/docs/reference/trackers.md`
- Option B (eliminates cross-file dependency): Inline the two required tables (Validation Rules + MCP Server Detection) directly into `check-setup/SKILL.md` — small tables (6 rows × 4 columns each), rarely changed
- Option C: Copy tables to `skills/check-setup/tracker-rules.md` and reference as `${CLAUDE_SKILL_DIR}/tracker-rules.md`

**Scope warning:** If bare paths in `core/*.md` references actually fail from consuming projects, the scope is systemic across all pipeline skills — but evidence suggests those work (Q3 agent conclusion: ambiguous).

---

### Q4: Existing Patterns

**`core/mcp-detection.md` (62 lines, fully read):** No TLS-specific logic. Process step 3 captures the raw error string from failed test calls and returns it in the `error` field. All error interpretation is delegated to callers. The contract correctly captures TLS error text but does not parse it for TLS indicators.

**`core/mcp-preflight.md` (48 lines, fully read):** No TLS handling. Failure handling text: "MCP tool found but connectivity test fails (auth error, network error, timeout): BLOCK pipeline with... Recommendation: Check that your API token is valid... Check that the instance is reachable." TLS failures fall into "network error" and produce this generic recommendation.

**`skills/init/SKILL.md` Step 7 (lines 250–263):** Same pattern as check-setup — surfaces raw error message but no TLS-specific diagnostic branches. Recommendation: "Check your token and URL." Same gap.

**Established pattern:** Raw `{error}` is passed through to the user. This is the correct base behavior. The improvement is to add a post-failure curl probe when the error message contains TLS indicator keywords ("unable to verify", "fetch failed", "certificate", "self-signed").

**Curl usage pattern already established:**
- `curl --max-time 5 --retry 0 -X POST` for webhooks — `core/block-handler.md` line 39
- `curl -sL` / `curl -sfL` for binary downloads — `skills/init/SKILL.md` lines 172–177
- `skills/check-setup/SKILL.md` frontmatter: `allowed-tools: mcp__*, Read, Glob, Grep, Bash` — Bash (and curl) are already allowed

**`skills/version-check/SKILL.md` line 46:** Documents "SSL error" as a known failure mode in a version check context, but provides no diagnostic logic — just "skip to next step."

---

### Additional Findings

**AO1 (Agent 1):** `core/mcp-preflight.md` has the same TLS blind spot as `check-setup`. If TLS diagnostic is added to check-setup only, users hitting TLS failures mid-pipeline (fix-bugs, fix-ticket, implement-feature) will still get misleading block comments. Wider fix out of scope for current task but should be noted in the implementation plan.

**AO2 (Agent 1):** `skills/init/SKILL.md` Step 7 has the same TLS gap. Also out of scope for current task.

**AO3 (Agent 1, corroborated by Agent 3):** The bare path pattern for `docs/reference/trackers.md` is used identically across `onboard`, `scaffold`, `init`, and `core/mcp-detection.md` — not just `check-setup`. The path resolution question (Q3) applies to the entire plugin uniformly. Agent 1 confirms: "bare relative paths are the standard pattern and Claude Code is expected to resolve them relative to the plugin root, not the CWD."

**AO4 (Agent 3):** The file `docs/reference/trackers.md` exists at the plugin cache path (`C:/Users/FSABACKY/.claude/plugins/cache/ceos-agents/ceos-agents/6.1.9/docs/reference/trackers.md`) confirming that the content is present in the installed plugin — the question is purely about path resolution in Read tool calls.

**AO5 (Agent 2):** `docs/guides/mcp-configuration.md` line 158 already suggests a manual browser check ("Verify the URL in your browser") as a proxy for reachability — this validates the conceptual approach of using an external probe (curl) to distinguish server reachability from Node.js TLS failure.

---

### Research Confidence

| Question | Confidence | Key gap |
|----------|------------|---------|
| Q1: Block 3/step 9 current behavior | HIGH | File read, unambiguous |
| Q1: Node.js TLS error string format | LOW | No codebase evidence; external knowledge only |
| Q1: NODE_OPTIONS --use-system-ca correctness | MEDIUM | Correct solution confirmed; npx env propagation uncertain |
| Q1: curl as TLS discriminator | HIGH | Standard curl behavior, confirmed codebase usage |
| Q2: list_my_repositories / tool names | HIGH | Exhaustive grep, 0 matches |
| Q2: read:user scope | HIGH | Not present in codebase; repository:read is correct scope |
| Q2: SC connectivity tool selection | HIGH | Confirmed prose-only, runtime LLM decision |
| Q3: trackers.md reference locations | HIGH | All 14 files enumerated |
| Q3: Path variable availability | HIGH | From official docs, confirmed in filip-superpowers |
| Q3: Whether bare paths are currently broken | MEDIUM | Ambiguous — depends on how Claude Code resolves paths in Read tool calls |
| Q4: TLS logic in mcp-detection.md | HIGH | File read, none found |
| Q4: TLS logic across codebase | HIGH | Grep confirmed, zero occurrences |

**Overall assessment:** Research is thorough and internally consistent across all three agents. No conflicts found — agent-1 and agent-3 independently reached the same conclusion on path resolution (bare relative paths are the established convention; agent-3 provides the deeper analysis of why this may or may not be broken). Agent-2 findings are definitive (0 matches). The main remaining uncertainty is the exact TLS error string from Node.js/MCP (no in-codebase evidence) and whether bare relative paths in Read instructions actually fail in consuming project contexts (the systemic vs. local-only failure question).
