# Phase 1: Research Questions

## Persona

You are a senior plugin architect specializing in Claude Code plugin internals. You have deep expertise in markdown-based plugin systems, path resolution strategies, and error classification patterns.

## Task Instructions

Investigate the following questions to build context for implementing v6.4.4 (Connectivity Diagnostics Hardening) in the ceos-agents plugin. This is a PATCH release with three items: bare path migration, structured error_type, and Step 10 TLS treatment.

### Research Questions

**Item 1: Bare Path Migration**

1. Read `skills/check-setup/SKILL.md` lines 32-38 (Step 3a). Document the exact Glob-first resolution pattern used. This is the canonical pattern to replicate.
2. For each of the 4 affected files (`skills/onboard/SKILL.md`, `skills/scaffold/SKILL.md`, `skills/init/SKILL.md`, `core/mcp-detection.md`), identify:
   - The exact line numbers containing bare `docs/reference/trackers.md` references
   - The surrounding context (what step/section each reference is in)
   - Whether the reference is a "read this file" instruction or a "look up in this table" instruction
   - Whether the file already has any path resolution logic for other files
3. Are there any files beyond the 4 identified that contain bare `docs/reference/trackers.md` references and are NOT docs/plans/tests/changelog? (i.e., runtime-relevant skill or core files)
4. Does `skills/check-setup/SKILL.md` Step 7 demonstrate a "resolve once, reuse later" pattern? If so, document it — the same pattern should be used in files with multiple references.

**Item 2: Structured error_type**

5. Read `core/mcp-detection.md` Output Contract. What fields currently exist? What is the current error handling in the Process section?
6. Read `skills/check-setup/SKILL.md` Step 9 error classification. Document the exact error string patterns for each category (TLS, auth, other). These will become the source of truth for the error_type enum.
7. Read `skills/init/SKILL.md` — does it have its own error parsing logic when calling mcp-detection? If so, where and how?
8. Read `skills/fix-bugs/SKILL.md` and `skills/fix-ticket/SKILL.md` — do they call mcp-detection? If so, do they parse errors?

**Item 3: Step 10 TLS Treatment**

9. Read `skills/check-setup/SKILL.md` Step 10 in full. Document the current error handling for SC connectivity failures.
10. Compare Step 9 and Step 10 error handling. What specific TLS patterns from Step 9 are missing in Step 10?

### Output Format

For each question, provide:
- The answer with exact file paths, line numbers, and relevant code snippets
- Any surprises or complications discovered
- Dependencies between questions

## Success Criteria

- All 10 questions answered with specific file/line references
- Complete inventory of bare path references (no missed files)
- Clear understanding of the error_type enum values needed
- Step 10 gap analysis complete

## Anti-Patterns

- Do NOT propose solutions — this phase is research only
- Do NOT modify any files
- Do NOT skip questions — each feeds into downstream phases
- Do NOT rely on assumptions about file contents — always Read the actual files

## Codebase Context

- Repository: `ceos-agents` — pure markdown plugin, no build system
- Key files: `skills/check-setup/SKILL.md` (reference pattern), `core/mcp-detection.md` (contract to extend), `skills/onboard/SKILL.md`, `skills/scaffold/SKILL.md`, `skills/init/SKILL.md` (files to migrate)
- Pattern to replicate: Three-layer Glob resolution from check-setup v6.4.3
- Roadmap: `docs/plans/roadmap.md` lines 456-473
