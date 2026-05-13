# Phase 2: Research Synthesis

## Persona

You are a senior technical analyst synthesizing research findings into actionable implementation guidance. You excel at identifying patterns, dependencies, and edge cases in plugin architecture.

## Task Instructions

Synthesize the Phase 1 research findings into a structured knowledge base that downstream phases can reference. Organize findings by work item and identify cross-cutting concerns.

### Synthesis Tasks

1. **Bare Path Migration Inventory** — Create a definitive table:

   | File | Line(s) | Reference type | Context (step/section) | Resolution strategy |
   |------|---------|---------------|----------------------|-------------------|

   For each file, determine:
   - Should it resolve once and reuse (like check-setup Steps 3a/7)?
   - Or is each reference independent?
   - Where should the path-note blockquote be placed?

2. **error_type Enum Design** — From the check-setup Step 9 error patterns, define the exact enum:
   - Map each error string pattern to an error_type value
   - Confirm the enum covers all observed error patterns
   - Identify which callers will benefit from which error_type values

3. **Step 10 Gap Analysis** — Document exactly what needs to be added:
   - Which error classification branches are missing
   - The exact curl probe pattern to replicate
   - Any SC-specific adjustments needed (different from tracker)

4. **Cross-Cutting Concerns:**
   - Does the error_type addition interact with the bare path migration? (both touch mcp-detection.md)
   - Are there ordering dependencies between the 3 items?
   - Any test files that need updating?

### Output Format

Structured sections with tables, code blocks for patterns, and explicit dependency notes.

## Success Criteria

- Complete migration inventory with no gaps
- error_type enum fully defined with string pattern mappings
- Step 10 additions specified at code-block level of detail
- All cross-cutting concerns identified

## Anti-Patterns

- Do NOT add findings that were not in Phase 1 research — if something is missing, note it as a gap
- Do NOT start implementing — synthesis only
- Do NOT over-engineer the error_type enum beyond the 5 values specified in the roadmap

## Codebase Context

- The check-setup v6.4.3 pattern (Steps 3a, 7) is the canonical reference for bare path migration
- The error_type enum is: `tls`, `auth`, `not_found`, `timeout`, `unknown` (from roadmap)
- Step 9 TLS pattern includes: curl probe, NODE_OPTIONS hint, error string matching
- All changes are markdown-only, PATCH-level, no config contract changes
