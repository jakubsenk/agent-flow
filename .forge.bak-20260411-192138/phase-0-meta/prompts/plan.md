# Phase 6: Implementation Plan

## Persona
You are a **senior developer** implementing precise edits to a markdown skill definition file. You plan surgical changes that address exactly the specified issues without collateral modifications.

## Task Instructions

Create an implementation plan for modifying `skills/check-setup/SKILL.md` to address all three issues:

### Task 1: Add TLS Diagnostic to Block 3 Step 9 (Issue 1)

**Location:** Lines 71-74 (Block 3, step 9)
**Action:** Expand the failure handling in step 9 to include a curl-based TLS diagnostic

Current text:
```
9. Run the Bug query from Automation Config via MCP (limit 1 result):
   - Success -> [OK] with the number of bugs found
   - Auth error -> [FAIL] "MCP server configured but authentication failed -- check your token in .mcp.json"
   - Timeout/connection refused -> [FAIL] "MCP server configured but not reachable -- verify the server is running and URL is correct"
```

New text should:
- Keep Success and Auth error cases unchanged
- Replace the generic "Timeout/connection refused" case with a diagnostic sub-flow:
  - On network-level failure (fetch failed, timeout, connection error):
    1. Run `curl -sS -o /dev/null -w "%{http_code}" --max-time 10 {Instance_URL}` via Bash
    2. If curl gets HTTP response (status code > 0): `[FAIL] Issue tracker -- server reachable via HTTP but MCP connection failed (likely TLS issue -- add "NODE_OPTIONS": "--use-system-ca" to the MCP server's env section in .mcp.json)`
    3. If curl fails (no response): `[FAIL] Issue tracker -- server unreachable (connection refused or DNS failure)`

### Task 2: Fix Step 10 SC Connectivity (Issue 2)

**Location:** Lines 75-77 (Block 3, step 10)
**Action:** Reword step 10 to verify specific remote instead of listing repos

Current text:
```
10. Verify source control connectivity: list repositories via MCP
    - Success -> [OK]
    - Failure -> [FAIL] with specific error type (auth vs unreachable)
```

New text:
```
10. Verify source control connectivity: confirm the configured remote ({Remote} from Automation Config) exists via MCP
    - Success -> [OK] "Source control -- remote {owner/repo} confirmed"
    - Failure -> [FAIL] with specific error type (auth vs unreachable)
```

### Task 3: Add Path Resolution Preamble (Issue 3)

**Location:** Before step 3a (around line 30) -- add a preamble
**Action:** Add a path resolution step that locates trackers.md once

Add before the `### 3a. Per-tracker validation` section:
```
**Plugin file resolution:** Before reading plugin reference files, locate the ceos-agents plugin installation directory. Use `Glob` with pattern `**/ceos-agents/docs/reference/trackers.md` to find the file. If Glob returns no results, try the path relative to CWD: `docs/reference/trackers.md`. If neither works, skip per-tracker validation with `[WARN] Tracker-specific validation skipped -- trackers.md not found`.
```

Then update the two references (steps 3a and 7) to say "Read trackers.md (resolved path from above)" instead of "Read `docs/reference/trackers.md`".

### Task 4: Update Output Format Section

**Location:** Lines 88-112 (Output format section)
**Action:** Update the Connectivity section examples

Update the Connectivity output examples to show:
- The new TLS diagnostic output
- The updated SC connectivity output

### Task 5: Write Test File (if TDD phase produced one)

**Location:** `tests/scenarios/check-setup-improvements.sh`
**Action:** Create structural validation test

### Dependency Graph
```
Task 3 (path resolution) -- no dependencies
Task 1 (TLS diagnostic) -- no dependencies
Task 2 (SC connectivity) -- no dependencies
Task 4 (output format) -- depends on Tasks 1 + 2
Task 5 (tests) -- depends on Tasks 1 + 2 + 3 + 4
```

Tasks 1, 2, 3 can be done in parallel. Task 4 after 1+2. Task 5 last.

## Success Criteria
- All edits are confined to `skills/check-setup/SKILL.md` (plus optional new test file)
- Diff is under 50 lines
- No changes to block numbering or overall structure
- All 10 acceptance criteria from spec are addressed

## Anti-Patterns
- Do NOT renumber existing steps
- Do NOT modify Block 1, Block 2, Block 4, or Block 5
- Do NOT change the frontmatter
- Do NOT add new allowed-tools
- Do NOT modify docs/reference/trackers.md or any other file

## Codebase Context
- Target: `skills/check-setup/SKILL.md` (132 lines)
- Blocks: 1=Automation Config, 2=MCP servers, 3=Connectivity, 4=Build & Test, 5=Plugin Composability
- Output format: lines 88-112, uses [OK]/[FAIL]/[WARN]/[SKIP] prefixes
- Rules: lines 127-132, read-only constraints
- Other skills referencing trackers.md: init, onboard, scaffold (8 total references)
