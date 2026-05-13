# Q2: Pipeline SC Usage / Gitea Token Scope — Research Findings

**Scope searched:** All 738 markdown files in `C:\gitea_ceos-agents` (agents/, skills/, core/, docs/, checklists/, tests/, examples/)

---

## Q2.1: `list_my_repositories` — Exact match count and locations

**Result: 0 matches across the entire codebase.**

Search: `list_my_repositories` across all files.
- No matches in `agents/` (19 files)
- No matches in `skills/` (26 skill directories)
- No matches in `core/` (11 contract files)
- No matches in `docs/`
- No matches anywhere in the repo

The tool name `list_my_repositories` does not appear in this codebase at all.

---

## Q2.2: `list_repositories`, `search_repos`, `get_repo`, repository listing MCP tools

**Results:**

| Pattern | Match count | Locations |
|---------|-------------|-----------|
| `list_repositories` | 0 | (none) |
| `search_repos` | 0 | (none) |
| `get_repo` | 0 | (none) |
| `list_repos` | 2 | docs only (see below) |

**`list_repos` occurrences (both in docs, not in active skill/agent definitions):**

1. `docs/plans/2026-02-25-v1.2-installation-docs-design.md:140` — a Czech design plan note:
   > `Ověření: mcp__gitea__list_repos v Claude Code`
   This is a 2026-02-25 design document (planning artifact), not a skill or agent definition.

2. `docs/plans/brainstorm/05-fix-bugs-token-discovery.md:92` — a brainstorm table:
   > `check-setup | Connectivity test — query tracker (1 result), list repos | Ano | Ano`
   This is a description of intended behavior in a brainstorm document, not an actual MCP call.

**What tools does the pipeline actually use?**

No specific MCP tool names for repository listing are hardcoded in any skill, agent, or core contract. The pipeline uses **generic tool prefix patterns** (`mcp__gitea__*`, `mcp__forgejo__*`, `mcp__github__*`) and defers specific tool selection to the LLM at runtime.

The only concrete MCP tool names that appear in active definitions are:
- In `docs/plans/brainstorm/05-fix-bugs-token-discovery.md`: `mcp__youtrack__search`, `mcp__gitea__create_pull_request` (brainstorm doc, not normative)
- In `docs/plans/readmine-project/agent-process-separation.md`: `mcp__github__get_issue`, `mcp__github__get_pull_request`, `mcp.gitea/create_pull_request` (project-specific plan doc, not normative)

**Conclusion:** The pipeline does NOT hardcode `list_repositories`, `list_repos`, `get_repo`, or `list_my_repositories` in any operative definition. Repository listing for SC connectivity verification is described only in prose ("list repositories via MCP", "verify the declared remote exists") — the specific tool called is left to runtime model judgment.

---

## Q2.3: `check-setup` SKILL.md — `read:user` scope check / warning

**File:** `skills/check-setup/SKILL.md`

**Finding: There is NO `read:user` scope check or warning anywhere in `check-setup/SKILL.md`.**

Exact text of Step 10 (the SC connectivity step):

```
10. Verify source control connectivity: list repositories via MCP
    - Success → [OK]
    - Failure → [FAIL] with specific error type (auth vs unreachable)
```

There is no explicit check for required token scopes. The skill only checks:
- Whether connectivity succeeds or fails
- Whether the failure is auth-related (401) vs unreachable (timeout/connection refused)

The `read:user` scope is **not mentioned anywhere in the codebase** (0 matches for `read:user`). There is no explicit scope validation — the check is entirely emergent from whether the MCP call succeeds or fails at runtime.

**Token scope documentation** is in `docs/guides/tokens.md` (not in `check-setup`). The documented Gitea scopes are:
- `repository:read`, `repository:write`, `issue:write`
- No mention of `read:user` anywhere in tokens.md

---

## Q2.4: `core/mcp-detection.md` — SC connectivity verification tool

**File:** `core/mcp-detection.md`

**Relevant section (Process step 3):**

```
3. If tool found — verify read connectivity:
   - If service_type is "tracker": attempt to list 1 issue from the declared project
     (or list projects if no project specified)
   - If service_type is "sc": attempt to verify the declared remote exists
```

**The exact MCP tool is NOT specified.** The contract says "attempt to verify the declared remote exists" — a prose description without naming a specific tool.

**Does it need `read:user` scope?**

The contract does NOT mention `read:user`. The SC connectivity check is described as "verify the declared remote exists" — which for Gitea would require `repository:read` scope (sufficient to fetch a specific repo by owner/name), NOT `read:user` (which is a GitHub concept for listing the authenticated user's own repositories).

`core/mcp-detection.md` references the lookup table:
- Gitea → `forgejo-mcp` → `mcp__gitea__*` or `mcp__forgejo__*`

The specific tool called to verify a remote's existence is not named in this contract.

---

## Q2.5: Agent definitions — repository listing tool references

**Search: `list_my_repositories`, `list_repos`, `search_repos` in `agents/`**

**Result: 0 matches across all 19 agent files.**

No agent in `agents/` references any repository listing tool by name. The publisher agent (`agents/publisher.md`) references SC MCP generically:

> "Use the source control MCP server corresponding to the Remote format (e.g., Gitea API for gitea instances, GitHub API for github.com) for PR creation."

No agent specifies `list_my_repositories`, `list_repos`, `list_repositories`, `search_repos`, or `get_repo`.

---

## Q2.6: Gitea MCP tool references across the entire pipeline

**Search: `mcp__gitea__`, `mcp__forgejo__`, `forgejo-mcp`**

| Location | Content | Type |
|----------|---------|------|
| `core/mcp-detection.md:27` | Lookup table: `gitea → forgejo-mcp → mcp__gitea__* or mcp__forgejo__*` | Normative contract |
| `skills/fix-bugs/SKILL.md:354` | PR creation table: `Gitea → mcp__gitea__* or mcp__forgejo__*` | Normative skill |
| `skills/fix-ticket/SKILL.md:367` | PR creation table: `Gitea → mcp__gitea__* or mcp__forgejo__*` | Normative skill |
| `skills/implement-feature/SKILL.md:410` | PR creation table: `Gitea → mcp__gitea__* or mcp__forgejo__*` | Normative skill |
| `docs/guides/mcp-configuration.md:55` | Verification hint: "ask a query about repositories" | User doc |
| `docs/guides/tokens.md:32` | Token scope: `repository:read`, `repository:write`, `issue:write` | User doc |
| `docs/plans/2026-02-25-v1.2-installation-docs-design.md:140` | Design note: `mcp__gitea__list_repos` as verification step | Plan doc (historical) |
| `docs/plans/brainstorm/05-fix-bugs-token-discovery.md:23` | `mcp__gitea__create_pull_request` | Brainstorm doc |
| Various `docs/plans/brainstorm/` files | Discussion of MCP prefix specificity (security) | Brainstorm docs |

**Specific Gitea MCP tool names that appear (across all docs, not just normative):**

| Tool name | Occurrences | Context |
|-----------|-------------|---------|
| `mcp__gitea__list_repos` | 1 | 2026-02-25 design plan (historical) |
| `mcp__gitea__create_pull_request` | 1 | Brainstorm doc |

**Conclusion:** The normative pipeline (skills/ + agents/ + core/) uses only the wildcard prefix `mcp__gitea__*` or `mcp__forgejo__*` — no specific tool names are hardcoded. The only specific tool name that appears anywhere is `mcp__gitea__list_repos` in a single historical design plan from 2026-02-25, and `mcp__gitea__create_pull_request` in a brainstorm document — neither is in any active skill, agent, or core contract.

---

## Summary: Key Findings

1. **`list_my_repositories`: 0 matches** — this tool name does not exist anywhere in the codebase.

2. **No repository listing tool is hardcoded** in any normative definition. The SC connectivity check in `check-setup` Step 10 says "list repositories via MCP" and `core/mcp-detection.md` says "verify the declared remote exists" — both are prose descriptions leaving tool selection to runtime.

3. **`read:user` scope: 0 matches** — this scope concept does not exist anywhere in the codebase. The `check-setup` Step 10 has no explicit scope check; it is entirely emergent from runtime API call success/failure.

4. **`core/mcp-detection.md` SC check**: Uses `service_type = "sc"` to "verify the declared remote exists" — no specific tool named. No `read:user` requirement documented.

5. **No agent references repository listing tools** — 0 matches in all 19 agent definitions.

6. **The only normative Gitea MCP references** in active skill/agent/core files are:
   - `mcp__gitea__*` or `mcp__forgejo__*` wildcard prefix (for PR creation, tool prefix detection)
   - `forgejo-mcp` package name (in mcp-detection.md and init/SKILL.md)
