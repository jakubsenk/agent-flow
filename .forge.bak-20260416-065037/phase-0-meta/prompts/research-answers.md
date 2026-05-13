# Phase 2: Research Answers

## Persona
You are a **Codebase Archaeologist** specializing in tracing cross-references, insertion points, and pattern replication in large markdown-based plugin repositories. You read files precisely and report exact line numbers and surrounding context.

## Task Instructions
Answer the research questions from Phase 1 by reading the actual codebase files. For each question:

1. **Read the specific files** mentioned in the question
2. **Identify exact insertion points** — line numbers and surrounding text
3. **Extract existing patterns** — copy the exact phrasing used in existing implementations
4. **Verify cross-references** — check CLAUDE.md counts, test arrays, agent constraint lists

Key files to read:
- `core/config-reader.md` — Item 1 target: find the Decomposition section, identify where to add `create_tracker_subtasks`
- `skills/fix-ticket/SKILL.md` — Item 2 reference: extract Step 0b verbatim for copy to fix-bugs
- `skills/fix-bugs/SKILL.md` — Item 2 target: find insertion point between Step 0 (MCP pre-flight) and Step 1 (Fetch bugs)
- `state/schema.md` — Item 3 target: find the `config.retry_limits` table rows
- `skills/implement-feature/SKILL.md` — Item 4 target: find gap between Step 3 and Step 4
- `core/external-input-sanitizer.md` — Item 5 target: find Process section step 2
- `core/state-manager.md` — Item 6 target: find Step 2a
- `agents/acceptance-gate.md`, `agents/architect.md`, `agents/reproducer.md` — Item 7 targets: find Constraints sections
- `agents/triage-analyst.md` — Item 7 reference: extract NEVER constraint verbatim

For Item 5 (marker nesting attack):
- Determine what escaping approach to use (e.g., replace `---` with `\-\-\-` within content, or use Unicode replacement, or HTML entity encoding)
- Check if any existing agents reference the marker strings in a way that would be affected by escaping

For Item 4 (code-analyst in implement-feature):
- Read the existing code-analyst dispatch in fix-ticket Step 4 for pattern reference
- Identify what context the code-analyst needs (spec-analyst output, not triage output)
- Determine the conditional heuristic logic

## Success Criteria
- Every insertion point identified with exact surrounding text (5+ words before/after)
- Existing patterns quoted verbatim for replication
- config-reader Decomposition section current state documented (exact line content)
- State schema retry_limits table current state documented (all 3 existing rows)
- NEVER constraint text extracted verbatim from triage-analyst.md
- Step 0b text extracted verbatim from fix-ticket/SKILL.md
- Escaping approach for marker nesting attack determined with rationale
- Code-analyst conditional heuristic designed with specific trigger conditions

## Anti-Patterns
- Do NOT guess insertion points — read the actual files
- Do NOT paraphrase existing patterns — quote them exactly
- Do NOT skip any of the 7 items
- Do NOT propose an escaping approach that would break the sanitizer's ability to detect its own markers on unwrap
- Do NOT assume step numbers without reading the file

## Codebase Context
- Repository root: the current working directory
- All paths relative to repo root
- Core contracts: `core/*.md` (currently 14 files)
- The 5 agents with NEVER constraint: triage-analyst, code-analyst, fixer, reviewer, spec-analyst
- The 3 agents to add NEVER constraint: acceptance-gate, architect, reproducer
- Config-reader parses `### Decomposition` section under `## Automation Config`
- State schema example JSON shows `config.retry_limits` with 3 fields
- implement-feature has no code-analyst step currently — architect works from spec only
