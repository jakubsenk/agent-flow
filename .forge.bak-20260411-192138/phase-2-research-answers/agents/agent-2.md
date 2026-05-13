# Agent 2: Gitea Token Scope Issue in check-setup

## Findings from skills/check-setup/SKILL.md

### Current Step 10 (verbatim)

```
10. Verify source control connectivity: list repositories via MCP
    - Success → [OK]
    - Failure → [FAIL] with specific error type (auth vs unreachable)
```

### Other references to read:user or list_my_repositories

None. The skill file contains no explicit scope names (`read:user`, `repository:read`, etc.) and no tool call names (`list_my_repositories`). The problem is entirely in Step 10's prose description — "list repositories via MCP" — which implies a tool that does not exist in Gitea MCP and implies a scope (`read:user` from GitHub's model) that Gitea does not have.

The Output Format section (Block 4 in the file, the `## Output format` fenced block) shows this line for source control connectivity:

```
[FAIL] Source control — authentication failed (401 Unauthorized)
```

That line is fine — it describes the failure category, not the mechanism. No scope name appears there.

---

## Decision

**Remove the read:user scope check entirely.** Do not downgrade to INFO. The check is verifying something that:

1. Does not exist as a Gitea concept (it is a GitHub OAuth scope name)
2. Has no corresponding MCP tool (`list_my_repositories` is absent from the entire codebase)
3. Is redundant — the pipeline only needs to confirm the declared remote repo is reachable, which requires `repository:read`, not a user-listing operation

The correct framing: Step 10 should verify that the specific remote repository declared in `Source Control → Remote` is accessible via MCP, not enumerate all repos the token can see.

---

## Step 10 Rewrite

### Before

```
10. Verify source control connectivity: list repositories via MCP
    - Success → [OK]
    - Failure → [FAIL] with specific error type (auth vs unreachable)
```

### After

```
10. Verify source control connectivity: confirm the configured remote exists via MCP
    - Use MCP to fetch repository metadata for the Remote value from Automation Config (owner/repo)
    - Success → [OK] "Source control — {owner/repo} reachable"
    - Auth error (401/403) → [FAIL] "Source control — authentication failed. Token needs repository:read scope."
    - Not found (404) → [FAIL] "Source control — repository {owner/repo} not found. Verify Remote in Automation Config."
    - Timeout/connection refused → [FAIL] "Source control — MCP server not reachable. Verify server URL and token in .mcp.json."
```

### Rationale for each change

| Change | Reason |
|--------|--------|
| "list repositories" → "confirm the configured remote exists" | Matches actual pipeline need: we only care that the one declared repo is accessible |
| Added "Use MCP to fetch repository metadata for Remote" | Makes the mechanism explicit — a single repo-read call, not a user-level listing |
| Split failure into 3 cases (401/403, 404, timeout) | Distinct root causes need distinct remediation instructions |
| Added "repository:read scope" to auth error message | Tells the user exactly which Gitea token scope to grant, using the correct Gitea scope name |
| Removed implicit read:user assumption | Gitea tokens use `repository:read`, `repository:write`, `issue:write` — no `read:user` concept |

---

## Impact on Output Format Section

The existing Output Format example line:

```
[FAIL] Source control — authentication failed (401 Unauthorized)
```

This line is acceptable as-is — it does not mention any scope name or tool. However, to be consistent with the expanded Step 10 failure cases, the example could be updated to show the scope hint:

### Before (in Output Format block)

```
[FAIL] Source control — authentication failed (401 Unauthorized)
```

### After (in Output Format block)

```
[FAIL] Source control — authentication failed (401 Unauthorized). Token needs repository:read scope.
```

This change is low priority — the output format block is illustrative, not normative. If the edit budget is constrained, skip it. The Step 10 rewrite is the blocking fix.

---

## Summary of all changes required in skills/check-setup/SKILL.md

| Location | Change type | Required? |
|----------|-------------|-----------|
| Step 10 body | Rewrite — replace "list repositories via MCP" with repo-metadata-fetch logic + 3-case failure messages | YES (blocking) |
| Output Format → Connectivity → `[FAIL] Source control` example | Add scope hint to auth failure line | OPTIONAL (cosmetic) |
| Nowhere else | No other occurrences of read:user, list_my_repositories, or scope names exist in the file | n/a |

No other files in the check-setup skill need changing based on the Phase 1 research (0 matches for both `read:user` and `list_my_repositories` across the codebase).
