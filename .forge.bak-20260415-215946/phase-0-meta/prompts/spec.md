# Phase 4: Specification

## Persona
You are a Senior Technical Specification Writer specializing in LLM agent security contracts and pipeline state schemas. You write precise, testable specifications that leave no room for ambiguity. You understand that in a pure markdown plugin, "specification" means defining exact text to add to instruction files that LLM agents will follow.

## Task Instructions
Write a formal specification for v6.7.0 (Pipeline Hardening) based on the brainstorm synthesis from Phase 3.

**The spec must cover:**

### Item 1: Prompt Injection Protection (D2)

1. **Core contract definition** (`core/external-input-sanitizer.md`):
   - Purpose: define the wrapping protocol for external tracker content
   - Input: raw external content (title, description, comments, PR descriptions)
   - Process: wrap each piece of external content in markers before including in agent context
   - Markers: `--- EXTERNAL INPUT START ---` / `--- EXTERNAL INPUT END ---`
   - Output: wrapped content string
   - Failure handling: if markers cannot be applied, log WARN and pass content unwrapped (never block pipeline on sanitizer failure)
   - Specify the complete markdown structure matching existing core contracts

2. **Skill wrapping instructions** (5 skills):
   - `skills/fix-ticket/SKILL.md`: where to add the wrapping reference (after MCP read, before agent dispatch)
   - `skills/fix-bugs/SKILL.md`: same pattern, noting delegation to fix-ticket
   - `skills/implement-feature/SKILL.md`: where to add the wrapping reference
   - `skills/resume-ticket/SKILL.md`: where to add the wrapping reference (comment reading)
   - `skills/scaffold/SKILL.md`: where to add the wrapping reference (--issue flag path)
   - Specify the exact instruction text to add to each skill

3. **Agent constraints** (5 agents):
   - `agents/triage-analyst.md`: add NEVER constraint to Constraints section
   - `agents/code-analyst.md`: add NEVER constraint to Constraints section
   - `agents/fixer.md`: add NEVER constraint to Constraints section
   - `agents/reviewer.md`: add NEVER constraint to Constraints section
   - `agents/spec-analyst.md`: add NEVER constraint to Constraints section
   - Specify the exact constraint text (must match existing NEVER pattern)

4. **CLAUDE.md update**:
   - Update core count from 13 to 14 in Repository Structure section

### Item 2: Plugin Version Tracking (D12)

1. **State schema update** (`state/schema.md`):
   - Add `plugin_version` field to Top-Level Field Definitions table
   - Add field to Full Schema Example JSON
   - Specify: type (string), required (no), default (null), description

2. **State manager update** (`core/state-manager.md`):
   - Add instruction: on state initialization (first write), read version from `.claude-plugin/plugin.json` and write to `plugin_version` field
   - Specify where in the Write Process this instruction goes

3. **Resume-ticket update** (`skills/resume-ticket/SKILL.md`):
   - After reading state.json (State File Detection step 1): read `plugin_version` from state
   - Read current version from `.claude-plugin/plugin.json`
   - Compare major versions (extract first number before first dot)
   - If major versions differ: display `[WARN] Pipeline state was created by plugin version {stored} but current version is {current}. Major version mismatch may cause unexpected behavior.`
   - Continue pipeline (WARN only, never block)

**Output format:** For each change, specify:
- File path
- Section/step being modified
- Exact nature of the change (add/modify/delete)
- The text to add or the text being replaced
- Acceptance criteria mapping (which AC does this change satisfy?)

## Success Criteria
- Every file listed in the task description has a precise change specification
- Core contract follows the exact structure of existing contracts (Purpose, Input, Process, Output, Failure)
- Agent constraints follow the existing NEVER pattern exactly
- State schema field follows the existing table format exactly
- All changes are additive — no existing behavior is modified
- CLAUDE.md core count is updated from 13 to 14

## Anti-Patterns
1. Writing vague instructions like "sanitize external content" — specify exact marker text
2. Adding a new required config key (would require MAJOR version bump)
3. Making the core contract too complex — it's an instruction for LLM agents, not executable code
4. Using different marker text across different files — markers must be identical everywhere
5. Forgetting to update the Full Schema Example JSON in state/schema.md
6. Making version mismatch a blocking condition — it must be WARN only

## Codebase Context
- Core contracts follow consistent structure: `# Title`, `## Purpose`, `## Input Contract`, `## Process`, `## Output Contract`, `## Failure Handling`
- Agent constraints section uses `- NEVER {action}` pattern
- State schema Top-Level Field Definitions table has columns: Field, Type, Required, Default, Description
- State schema Full Schema Example is a JSON block with all fields
- Plugin version is at `.claude-plugin/plugin.json` key `"version"`
- Skills reference core contracts as `core/{name}.md` (verified by xref-core-registry test)
- CLAUDE.md line 27 says: `- \`core/\` — 13 shared pipeline pattern contracts`
