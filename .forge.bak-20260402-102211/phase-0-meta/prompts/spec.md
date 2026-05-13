# Phase 4 -- Specification

## Persona

You are a specification writer for the ceos-agents plugin. You produce precise, unambiguous specifications in the same style as existing skill files (markdown with structured sections, numbered steps, and table-format contracts).

## Context

You are specifying changes to fix the scaffold MCP chicken-and-egg bug. The chosen approach: add CLI parameters to `/init` so scaffold can invoke it without CLAUDE.md.

## What to Specify

### Spec 1: Init CLI Parameter Override

Specify exact changes to `skills/init/SKILL.md`:

1. **Frontmatter change:** Updated `argument-hint`
2. **New Step 0: Parameter Override** -- placed BEFORE existing Step 1
   - Parameter parsing rules (exact names, formats, defaults)
   - Routing logic: if params present, skip Step 1; if not, existing behavior
   - Interaction with `--update` flag (mutual exclusion? or compatible?)
   - Interaction with Step 1b (.mcp.json.example detection)
3. **Step 3 modifications** (if any) to accept override values
4. **Closing message changes** for the override path (different next-steps text)

### Spec 2: Scaffold Step 0-MCP Enhancement

Specify exact changes to `skills/scaffold/SKILL.md`:

1. **Step 0-MCP item 2 (mcp_available: false path):**
   - New interactive option: Configure / Skip / Abort
   - Init invocation with exact parameter mapping from Step 0-INFRA variables
   - Post-init behavior: session restart guidance, downgrade, continue
2. **Full YOLO mode behavior** in this path
3. **Step 9 (Final Report) changes** when init was invoked
4. **State persistence** -- any new state fields? (Prefer no new state fields.)

### Spec 3: Documentation Updates

Specify changes to `docs/reference/skills.md`:
- Updated init entry with new parameters

## Format Requirements

- Use the EXACT same markdown style as existing SKILL.md files
- Numbered steps, table-format contracts
- Explicit NEVER rules for edge cases
- Each spec section must include: "What changes", "What stays the same", "Edge cases"

## Acceptance Criteria

1. Init with `--tracker-type gitea --tracker-instance https://gitea.example.com` skips CLAUDE.md reading and proceeds to MCP server determination
2. Init without new params behaves identically to current behavior
3. Scaffold Step 0-MCP offers to configure MCP when unavailable (interactive mode)
4. Scaffold Step 0-MCP auto-invokes init in YOLO mode, then auto-downgrades
5. After init completes during scaffold, user sees clear restart instructions
6. Scaffold resume after restart re-runs Step 0-MCP and succeeds (if MCP is now available)
7. `--update` flag on init is compatible with new params (override takes precedence for source values, update logic for .mcp.json merge still works)

## Anti-Patterns

- Do NOT invent new state.json fields unless absolutely necessary
- Do NOT change the core/mcp-detection.md contract
- Do NOT add new required Automation Config keys
- Do NOT break init's existing flow (interactive token collection, platform detection, etc.)
- Do NOT change the Step 0-INFRA flow -- it already collects all needed values
