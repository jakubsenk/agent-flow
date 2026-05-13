# Phase 1 -- Research Questions

## Persona

You are a senior plugin architect investigating a chicken-and-egg bug in the ceos-agents scaffold pipeline. Your job is to formulate precise research questions that will expose all edge cases and constraints before any code is written.

## Context

The scaffold skill's Step 0-MCP detects missing MCP servers but cannot configure them because the `/init` skill requires CLAUDE.md (which scaffold hasn't created yet). The proposed fix: add CLI parameters to `/init` so it can be called without CLAUDE.md.

## Research Questions

### RQ-1: Init Parameter Design
Read `skills/init/SKILL.md` completely. For each step that reads from CLAUDE.md or Automation Config, document:
- What exact values does it extract?
- Which of those values can be provided via CLI parameters instead?
- Which values MUST come from CLAUDE.md (i.e., cannot be reasonably passed via CLI)?

**Expected output:** A mapping table: `CLAUDE.md key --> CLI parameter name --> default if omitted`

### RQ-2: Session Restart Behavior
Research how Claude Code handles `.mcp.json` changes mid-session:
- Does modifying `.mcp.json` during a session cause MCP tools to reload?
- If not, what is the user's recovery path?
- Check if `skills/scaffold/SKILL.md` Step 0-MCP resume logic handles the "restart and re-run" scenario correctly.

**Expected output:** Confirmation of session restart requirement and verification that scaffold resume (state.json) correctly re-runs Step 0-MCP.

### RQ-3: Shared Server Detection Without CLAUDE.md
Init Step 3 has "Shared server detection" logic that compares tracker Type hostname with Source Control Remote hostname. When called with CLI params:
- Can this logic still work if only `--tracker-type` and `--sc-remote` are provided?
- What about the Instance URL comparison?

**Expected output:** Confirmation that shared server detection works with CLI-provided values.

### RQ-4: Token Collection Flow
Init Steps 4-5 handle interactive token collection and platform-specific binary handling (forgejo-mcp). These steps do NOT depend on CLAUDE.md. Verify:
- Do Steps 4-5 work identically regardless of whether values came from CLAUDE.md or CLI params?
- Are there any implicit dependencies on other CLAUDE.md sections?

**Expected output:** Confirmation that token collection is CLAUDE.md-independent.

### RQ-5: Step 1b (.mcp.json.example) Interaction
Init Step 1b detects `.mcp.json.example` and pre-fills values from it. In the scaffold context:
- Scaffold Step 4b-replaced generates `.mcp.json.example` AFTER Step 0-MCP (later in the pipeline)
- When init is called during Step 0-MCP, `.mcp.json.example` does not exist yet
- Is this a conflict? Does Step 1b's "does not exist -- no action" fallback handle this correctly?

**Expected output:** Confirmation that Step 1b gracefully handles missing `.mcp.json.example`.

### RQ-6: Scaffold YOLO Mode Edge Cases
In Full YOLO mode, Step 0-MCP auto-downgrades without prompting. With the fix:
- Should YOLO mode auto-invoke init (silently) or skip it?
- Init requires interactive token input -- this conflicts with YOLO's "no prompts" principle.
- What if the user runs scaffold with `--infra ready` but MCP is not configured? YOLO auto-downgrades, but should it try init first?

**Expected output:** Decision on YOLO mode behavior with clear rationale.

### RQ-7: Existing Test Coverage
Check `tests/` directory for any tests related to:
- init skill
- scaffold Step 0-MCP or Step 0-INFRA
- MCP detection
- Infrastructure state persistence

**Expected output:** List of existing tests that need updating or new tests needed.

### RQ-8: Version Impact
Review the versioning policy in CLAUDE.md. This fix:
- Adds optional CLI parameters to init (new feature? or behavior fix?)
- Changes scaffold Step 0-MCP behavior (behavior fix)
- Does NOT add new required config keys
- Does NOT change any agent output format

**Expected output:** Correct version bump level with justification.

## Anti-Patterns to Avoid

- Do NOT assume `.mcp.json` changes take effect immediately -- verify session restart behavior
- Do NOT assume all tracker types work identically -- gitea (binary) vs. youtrack (npx) have different setup flows in init Step 5
- Do NOT ignore the `--issue` flag interaction -- scaffold with `--issue` + no MCP is a critical path

## Success Criteria

All 8 research questions answered with specific file references and exact line numbers where relevant. No "I think" or "probably" -- either verified from the codebase or explicitly marked as an assumption requiring validation.
