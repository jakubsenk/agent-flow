# Agent 2 Brainstorm — "Fresh Eyes"

Persona: I look for opportunities to improve even within PATCH scope, finding elegant solutions that go slightly beyond the minimum.

Date: 2026-04-11

---

## Q1: Bare Path Resolution Placement

**Options:** A (file-top preamble), B (first-reference), C (every reference)

### Option A — File-top preamble

A preamble at the top of each file (after frontmatter) that resolves `trackers_md_path` once, before any step references it.

- **Pro:** LLM reads top-to-bottom; the variable is defined before it appears anywhere. No ambiguity about scope. One Glob call, one place to maintain.
- **Con:** Creates distance between the resolution logic and its first use (in onboard: ~6 lines gap; in scaffold: ~80+ lines gap). An LLM executing Step 0-INFRA in scaffold might not "remember" a preamble from 80 lines earlier. Also breaks the established pattern in check-setup, which places its path-note at Step 3a (first use), not at file top.

### Option B — First-reference (resolve-once at first use)

Place the resolution block immediately before the first step that needs the path. All subsequent references use the variable.

- **Pro:** Matches the check-setup Step 3a precedent exactly. The resolution logic sits right where the LLM first needs the value, maximizing salience. Subsequent uses of `{trackers_md_path}` are natural variable references — LLMs handle this well.
- **Con:** In scaffold, the first reference (line 93) and last reference (line 543) are ~450 lines apart. An LLM with limited context might lose the variable. However, the research already identified this as acceptable since Claude operates with large context windows.

### Option C — Every reference

Inline the Glob resolution at every single reference to `trackers.md`.

- **Pro:** Each reference is self-contained. Zero risk of the LLM "forgetting" the variable.
- **Con:** 6 Glob calls in onboard, 4 in scaffold = massive redundancy. Violates the check-setup Step 7 prohibition against re-Globbing. The repeated resolution blocks would bloat the files significantly and create a maintenance nightmare (change the Glob pattern? Update 12 places).

### Recommendation: Option B (first-reference)

**Rationale:** Option B is the only choice that maintains consistency with the existing check-setup Step 3a pattern, which is already proven and tested. It places resolution logic exactly where the LLM first needs the value, which is the most cognitively natural position. The "resolve once, use variable thereafter" pattern is well-understood by LLMs and is already the norm in this codebase.

**Risk:** In scaffold/SKILL.md, the 450-line span between first and last use of `{trackers_md_path}` could theoretically cause an LLM to lose track of the variable during a very long execution. However, this is mitigated by the fact that Claude's context window comfortably handles this span, and the variable name is self-documenting.

**If forced to pick differently (Option A):** I would add a one-line reminder comment (not a full re-resolution) before the Step 4b and Step 4e uses in scaffold: `<!-- trackers_md_path resolved in Step 0-INFRA above -->`. This hybrid A+B approach would add memory anchors without redundant Glob calls. However, this over-engineers a PATCH change and I would not recommend it.

---

## Q2: error_type Classification Location

**Options:** A (Process section), B (Failure Handling), C (inline per case)

### Option A — Process section

Add `error_type` classification as a new Process step (e.g., step 3b) that runs after read connectivity fails.

- **Pro:** Makes classification an explicit step in the process flow. Easy to find when reading the contract top-to-bottom.
- **Con:** The Process section describes the happy path with branches. Inserting a classification sub-step after step 3's failure case breaks the linear flow. It would feel like a tangent mid-process. Also, the Process section is about *what to do*, not *how to label outcomes*.

### Option B — Failure Handling section

Add `error_type` as a field assigned within each failure scenario in the existing Failure Handling section. Also add it to the Output Contract.

- **Pro:** The Failure Handling section already enumerates every failure scenario and specifies what to return. Adding `error_type` to each scenario's return specification is the natural place — it is literally *part of the return value*. Callers looking at the Output Contract see `error_type` exists, then look at Failure Handling to see which scenario produces which value. This is the cleanest separation of concerns: Output Contract says "this field exists and here are valid values", Failure Handling says "scenario X produces value Y".
- **Con:** The pattern-matching logic (which string patterns map to which error_type) has to be spelled out somewhere. Failure Handling currently uses prose descriptions, not regex tables. Adding 8 TLS patterns + 6 auth patterns inline in Failure Handling could make it verbose.

### Option C — Inline per case

Scatter `error_type` assignment into the Process section at each branch point where errors occur.

- **Pro:** The classification happens right where the error is detected, so there is zero ambiguity about which code path produces which value.
- **Con:** Duplicates classification logic across multiple places (step 2 tool-not-found, step 3 connectivity failure, etc.). Fragile for maintenance — add a new error_type value? Update every branch. Also, Process steps 2 and 3 are already dense; adding pattern-matching tables inline would make them unreadable.

### Recommendation: Option B (Failure Handling) with a twist

**Rationale:** Failure Handling is architecturally the right home because `error_type` is fundamentally a *classification of what went wrong*, which is exactly what the Failure Handling section describes. The Output Contract defines the field and its valid values; Failure Handling specifies which scenario produces which value. This is the cleanest contract for callers: read Output Contract to know the type exists, read Failure Handling to understand the mapping.

**The twist:** I would add a compact "Classification Reference" sub-section inside Failure Handling (or as a table right after it) that consolidates the string-pattern-to-error_type mapping in one place, rather than repeating the 8 TLS patterns inside each scenario's prose. The research already proposes a priority-ordered enum (tls > auth > not_found > timeout > unknown). This reference table becomes the single source of truth for pattern matching, and each Failure Handling scenario simply says "classify error per Classification Reference below" and assigns the result. This avoids the verbosity concern while keeping everything in Failure Handling.

**Risk:** A caller might look only at Output Contract and miss the pattern-mapping details in Failure Handling. Mitigation: the Output Contract entry for `error_type` should include a forward-reference: "See Failure Handling for classification logic."

**If forced to pick differently (Option A):** I would add a "Step 3a: Classify error" sub-step after step 3's failure branch. This works but feels architecturally wrong — the Process section should describe actions, not output labeling.

---

## Q3: Step 10 TLS Mirroring Scope

**Options:** exact mirror of Step 9, adapted for SC, minimal

### Option: Exact mirror

Copy Step 9's TLS detection (8 patterns), curl probe, and NODE_OPTIONS hints verbatim into Step 10, only changing "Issue tracker" to "Source control" in messages.

- **Pro:** Consistency. The same error patterns get the same treatment regardless of whether they come from tracker or SC connectivity.
- **Con:** Ignores that SC and tracker connections have different failure modes. The curl probe in Step 9 targets `{Instance}` (a direct URL), but Step 10's Remote is `owner/repo` (not a URL) — so the curl target derivation is fundamentally different. A blind copy would either break or require immediate adaptation anyway.

### Option: Adapted for SC

Mirror Step 9's TLS detection and curl probe, but adapt the curl target derivation for SC's `owner/repo` format. Keep SC-specific branches (404/not-found, tool-not-found, per-platform scope names).

- **Pro:** Gets the TLS coverage that Step 10 currently lacks, while respecting that SC has different error semantics. The research already identified a clean derivation rule: extract the base hostname from the SC MCP server entry in `.mcp.json`. SC-specific patterns preserved: the auth error message mentioning per-platform scopes (`repository:read` for Gitea, `repo` for GitHub, `read_repository` for GitLab) is better than Step 9's generic auth message, and the 404/not-found branch is SC-specific (repository doesn't exist vs. tracker project doesn't exist).
- **Con:** More work than minimal. Adds ~15 lines to Step 10. However, this is a one-time write.

### Option: Minimal

Only add the TLS string pattern detection and the NODE_OPTIONS hint to the existing Timeout/unreachable catch-all. No curl probe.

- **Pro:** Smallest diff. Low risk.
- **Con:** Misses the curl probe that makes Step 9 so useful — the probe distinguishes "server is reachable but TLS handshake fails in MCP" from "server is completely unreachable". Without it, the user gets a generic message and has to debug blind. This is the exact gap that the research identified as worth closing.

### SC-specific error patterns that Step 9 does NOT cover

Yes, there are SC-specific patterns that justify adaptation over exact mirroring:

1. **404 / repository not found:** Step 9 has no 404 branch (trackers don't return 404 for project-not-found in the same way). Step 10 already has this and it should stay at position 3 in the cascade.
2. **Per-platform scope names in auth errors:** Step 9 says "check your token in .mcp.json". Step 10 says "Token needs repository:read scope (Gitea), repo scope (GitHub), or read_repository scope (GitLab)." The SC-specific message is significantly more actionable. This MUST be preserved.
3. **Tool-not-found as [WARN] not [FAIL]:** Step 9 does not have a tool-not-found branch (the MCP server for the tracker is always expected to exist). Step 10 has it as [WARN] because some SC MCP servers lack a repository metadata method. This is SC-specific and correct.
4. **URL derivation:** The curl probe URL for SC cannot be `{Instance}` because SC has no Instance field. It must be derived from `.mcp.json` server config. This is a structural difference, not just a string substitution.

### Recommendation: Adapted for SC

**Rationale:** The adapted approach is the only option that actually closes the TLS gap while respecting SC's distinct error semantics. Exact mirroring would require immediate modification anyway (URL derivation), so "adapted" is effectively the minimum viable implementation. The research's proposed Step 10 replacement text already captures this perfectly — it mirrors the TLS detection and curl probe from Step 9 but adapts the URL derivation and preserves SC-specific branches.

**Risk:** The `{sc_base_url}` derivation adds a dependency on reading `.mcp.json` server config within Step 10. If `.mcp.json` is malformed or the server entry lacks a URL field, the derivation could fail. Mitigation: the research already includes a fallback — "If base URL cannot be derived, skip probe" — which degrades gracefully to the no-curl-available variant of the TLS message.

**If forced to pick differently (minimal):** I would at minimum add the 8 TLS string patterns to Step 10's error classification and append "If using a private CA (self-signed or corporate PKI), try NODE_OPTIONS: --use-system-ca." to both the TLS catch and the existing Timeout/unreachable message. This is ~5 lines of change and captures 80% of the value. But the curl probe is what makes Step 9's TLS diagnostics truly useful, and skipping it would leave Step 10 as a second-class citizen.

---

## Summary of Recommendations

| Question | Recommendation | Key Insight |
|----------|---------------|-------------|
| Q1: Path resolution placement | **B (first-reference)** | Matches check-setup Step 3a precedent; resolve-once is the codebase norm |
| Q2: error_type location | **B (Failure Handling)** with consolidated Classification Reference table | error_type is a failure classification — it belongs where failures are defined |
| Q3: Step 10 TLS scope | **Adapted for SC** | SC has 4 distinct error patterns Step 9 lacks; exact mirror would need adaptation anyway |

### Cross-cutting observation

The research's proposed implementation order (mcp-detection first, then check-setup, then init/onboard/scaffold) is correct. One thing I would add: after all edits are done, a quick scan of `core/mcp-preflight.md` should confirm it does NOT need updating for this PATCH. The research correctly marks it as out-of-scope, but a 30-second verification avoids a surprise in the next version.
