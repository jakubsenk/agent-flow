# Phase 4: Specification

## Persona
You are a **technical specification writer** for a Claude Code plugin system. You write precise, testable specifications for markdown skill definitions that guide LLM behavior.

## Task Instructions

Write a formal specification for the three changes to `skills/check-setup/SKILL.md`:

### SPEC-1: TLS Error Diagnostics in Block 3

**Current behavior (step 9):**
- MCP query fails -> two categories: "Auth error" or "Timeout/connection refused"

**Required behavior:**
- When MCP query fails with an error containing "fetch failed" or similar network-level failure:
  1. Run `curl -sS -o /dev/null -w "%{http_code}" --max-time 10 {Instance_URL}` via Bash
  2. If curl returns HTTP 200-499 (server responded): report `[FAIL] Issue tracker -- server reachable via HTTP but MCP connection failed (likely TLS issue -- add "NODE_OPTIONS": "--use-system-ca" to the MCP server's env section in .mcp.json)`
  3. If curl fails or returns no response: report `[FAIL] Issue tracker -- server unreachable (connection refused or DNS failure)`
  4. If error contains "401", "403", or "unauthorized": report `[FAIL] Issue tracker -- authentication failed (check your token in .mcp.json)` (existing behavior, preserved)

**Acceptance criteria:**
- AC-1: TLS failure on Redmine with self-signed cert produces the "likely TLS" message, not generic "unreachable"
- AC-2: Genuinely unreachable server still produces "unreachable" message
- AC-3: Auth errors are still correctly identified (no regression)
- AC-4: The curl diagnostic only runs when MCP fails with network-level error, not on auth errors

### SPEC-2: Remove False-Positive read:user Scope WARN

**Current behavior (step 10):**
- "Verify source control connectivity: list repositories via MCP"
- (LLM may warn about missing read:user scope when listing repos fails)

**Required behavior:**
- Step 10 reworded to: "Verify source control connectivity: confirm the configured remote ({Remote} from Automation Config) exists via MCP"
- No check for `read:user` scope or `list_my_repositories` capability
- The verification should use `get_repo` or equivalent single-repo lookup, not repo listing

**Acceptance criteria:**
- AC-5: No [WARN] about read:user scope is produced
- AC-6: SC connectivity check verifies the specific configured remote, not all repos
- AC-7: Step 10 wording explicitly mentions the configured Remote

### SPEC-3: Robust trackers.md Path Resolution

**Current behavior (steps 3a, 7):**
- `Read docs/reference/trackers.md` (bare relative path)

**Required behavior:**
- Before first reference to trackers.md, resolve the plugin installation path:
  - Use `Glob` with pattern `**/ceos-agents/docs/reference/trackers.md` to locate the file
  - If not found via glob, try reading from the path relative to the skill file's own location: resolve `../../docs/reference/trackers.md` relative to the skill directory
  - Store the resolved path and reuse for subsequent references
- Both references in steps 3a and 7 use the resolved path

**Acceptance criteria:**
- AC-8: trackers.md is found when check-setup runs from a project root (different CWD than plugin root)
- AC-9: trackers.md is found when check-setup runs from the plugin root itself
- AC-10: If trackers.md cannot be found, report `[WARN] Tracker validation skipped -- trackers.md not found. Plugin may not be installed correctly.`

## Output Format Updates

The output format section should add the TLS diagnostic example:
```
### Connectivity
[OK]   Issue tracker -- connection OK, project {PROJECT} found, X bugs
[FAIL] Issue tracker -- server reachable via HTTP but MCP connection failed (likely TLS issue -- add "NODE_OPTIONS": "--use-system-ca" to .mcp.json env)
[FAIL] Issue tracker -- server unreachable (connection refused or DNS failure)
[FAIL] Issue tracker -- authentication failed (401 Unauthorized)
[OK]   Source control -- remote {owner/repo} confirmed
```

## Success Criteria
- All 10 acceptance criteria are testable
- Specification is precise enough for an LLM to implement without ambiguity
- No changes to files other than `skills/check-setup/SKILL.md`
- Backward compatible with existing check-setup output consumers

## Anti-Patterns
- Do NOT specify implementation details beyond what the skill markdown needs
- Do NOT add new dependencies or allowed-tools
- Do NOT change the block numbering or overall skill structure
- Do NOT use `NODE_TLS_REJECT_UNAUTHORIZED=0` anywhere

## Codebase Context
- `skills/check-setup/SKILL.md`: 132 lines, frontmatter + 5 blocks + output format + rules
- Allowed tools: `mcp__*, Read, Glob, Grep, Bash`
- Output uses `[OK]`, `[FAIL]`, `[WARN]`, `[SKIP]` prefixes
- Rules: read-only, read-only MCP queries, placeholder detection, safe for repeated execution
