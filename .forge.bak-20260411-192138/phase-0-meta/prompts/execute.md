# Phase 7: Execute

## Persona
You are a **precision editor** for markdown skill definitions. You make exact, surgical edits to `skills/check-setup/SKILL.md` following the implementation plan. You preserve existing structure, indentation, and formatting conventions.

## Task Instructions

Execute the implementation plan by editing `skills/check-setup/SKILL.md`. Apply changes in this order:

### Edit 1: Add Path Resolution Preamble (Issue 3)

Insert a path resolution instruction before the `### 3a. Per-tracker validation` section. This goes between step 3's table and the `### 3a` heading.

Add:
```markdown

**Plugin file resolution:** Before reading plugin reference files, locate the ceos-agents plugin installation directory. Use `Glob` with pattern `**/ceos-agents/docs/reference/trackers.md` to find the file. If Glob returns no results, try the path relative to CWD: `docs/reference/trackers.md`. If neither works, skip per-tracker validation with `[WARN] Tracker-specific validation skipped -- trackers.md not found. Plugin installation may be incomplete.`
```

Then update both references to trackers.md:
- Step 3a: Change `Read \`docs/reference/trackers.md\`` to `Read trackers.md (resolved path from above)`
- Step 7 (MCP detection): Change `read the MCP Server Detection table from \`docs/reference/trackers.md\`` to `read the MCP Server Detection table from trackers.md (resolved path)`

### Edit 2: Expand Block 3 Step 9 with TLS Diagnostics (Issue 1)

Replace the current step 9 failure handling with the expanded version that includes curl-based TLS diagnostics.

Replace:
```markdown
   - Timeout/connection refused -> [FAIL] "MCP server configured but not reachable -- verify the server is running and URL is correct"
```

With:
```markdown
   - Network-level failure (fetch failed, timeout, connection refused):
     1. Run TLS diagnostic: `curl -sS -o /dev/null -w "%{http_code}" --max-time 10 {Instance_URL}` via Bash
     2. If curl returns an HTTP status code (server responded) -> [FAIL] "Issue tracker -- server reachable via HTTP but MCP connection failed (likely TLS issue -- add `\"NODE_OPTIONS\": \"--use-system-ca\"` to the MCP server's env section in .mcp.json)"
     3. If curl fails (no response, connection refused) -> [FAIL] "Issue tracker -- server unreachable (connection refused or DNS failure)"
```

### Edit 3: Fix Step 10 SC Connectivity (Issue 2)

Replace:
```markdown
10. Verify source control connectivity: list repositories via MCP
    - Success -> [OK]
    - Failure -> [FAIL] with specific error type (auth vs unreachable)
```

With:
```markdown
10. Verify source control connectivity: confirm the configured remote ({Remote} from Automation Config) exists via MCP
    - Success -> [OK] "Source control -- remote {owner/repo} confirmed"
    - Failure -> [FAIL] with specific error type (auth vs unreachable). Apply the same TLS diagnostic from step 9 if the failure is network-level.
```

### Edit 4: Update Output Format Section

Update the Connectivity examples in the output format section to reflect the new diagnostic messages.

Replace:
```markdown
### Connectivity
[OK]   Issue tracker -- connection OK, project {PROJECT} found, X bugs
[FAIL] Source control -- authentication failed (401 Unauthorized)
```

With:
```markdown
### Connectivity
[OK]   Issue tracker -- connection OK, project {PROJECT} found, X bugs
[FAIL] Issue tracker -- server reachable via HTTP but MCP connection failed (likely TLS issue -- add NODE_OPTIONS to .mcp.json env)
[FAIL] Issue tracker -- server unreachable (connection refused or DNS failure)
[OK]   Source control -- remote {owner/repo} confirmed
[FAIL] Source control -- authentication failed (401 Unauthorized)
```

### Validation After Edits
1. Read the full file after all edits to verify structure integrity
2. Verify all 5 blocks are present
3. Verify frontmatter is unchanged
4. Verify Rules section is unchanged
5. Count total lines -- should be approximately 145-155 (was 132)

## Success Criteria
- All 4 edits applied cleanly without conflicts
- File structure is preserved (frontmatter, 5 blocks, output format, rules)
- No typos in diagnostic messages
- Indentation and formatting match existing conventions
- The `allowed-tools` frontmatter is unchanged

## Anti-Patterns
- Do NOT rewrite the entire file -- use surgical edits
- Do NOT change any content outside the specified edit locations
- Do NOT modify the frontmatter, Block 1, Block 2, Block 4, Block 5 (except output format), or Rules
- Do NOT introduce markdown formatting that differs from the existing style
- Do NOT use `NODE_TLS_REJECT_UNAUTHORIZED=0` anywhere

## Codebase Context
- File: `skills/check-setup/SKILL.md` at `C:\gitea_ceos-agents\skills\check-setup\SKILL.md`
- Frontmatter: lines 1-6 (name, description, allowed-tools, argument-hint)
- Block 1: lines 16-48 (Automation Config)
- Block 2: lines 50-67 (MCP servers)
- Block 3: lines 69-77 (Connectivity) -- MAIN EDIT TARGET
- Block 4: lines 79-84 (Build & Test)
- Output format: lines 86-117
- Block 5: lines 118-125 (Plugin Composability)
- Rules: lines 127-132
