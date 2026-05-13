# Phase 2: Research Answers — v6.7.2 Pipeline Consistency & Dedup

## Persona
{{PERSONA}}: You are a **meticulous code auditor** specializing in detecting subtle differences between nearly-identical code blocks, format inconsistencies in protocol definitions, and documentation staleness in markdown-based systems.

## Task Instructions
{{TASK_INSTRUCTIONS}}:

Answer the research questions from Phase 1 by reading the actual source files in the repository. For each answer:

1. **Quote the exact text** from the source file (with file path and approximate line numbers)
2. **Identify differences** between copies that are supposed to be identical
3. **Catalog every webhook curl call** in the entire codebase with exact keys, flags, and format
4. **Document the delegation pattern** used by existing core contracts

### Files to read for each work item:

**Work Item 1 (Tracker Subtask Extraction):**
- `skills/fix-ticket/SKILL.md` — find step 4b-tracker, extract the full pseudocode block
- `skills/fix-bugs/SKILL.md` — find step 3b-tracker, extract the full pseudocode block
- `skills/implement-feature/SKILL.md` — find step 5a, extract the full pseudocode block
- Compare all three line-by-line for any differences beyond step numbering
- Read `core/block-handler.md` and `core/post-publish-hook.md` for delegation pattern examples

**Work Item 2 (Webhook Format Alignment):**
- Search ALL files in `skills/` and `core/` for `curl` commands
- For each: extract the full curl command, identify JSON keys, flags, and format (inline vs heredoc)
- Build a complete deviation matrix

**Work Item 3 (Block Handler Inline Removal):**
- Compare implement-feature step X (the inline procedure) with core/block-handler.md
- Check fix-ticket step X and fix-bugs step X for how they handle block delegation

**Work Item 4 (Doc Fixes):**
- Read each of the 5 target files and locate the exact text that needs changing
- For state/schema.md e2e_test section: document what fields exist vs what should exist
- For fixer-reviewer-loop.md: find the NEEDS_DECOMPOSITION reference and its current wording

## Success Criteria
{{SUCCESS_CRITERIA}}:
- Every research question has a concrete answer with file path and quoted text
- The tracker subtask diff between 3 skills identifies ALL differences (even whitespace/comments)
- Complete webhook curl inventory with no missed call-sites
- Clear before/after text for each doc fix
- Answers are factual (from file reading), not speculative

## Anti-Patterns
{{ANTI_PATTERNS}}:
1. Answering from memory without reading the actual files
2. Summarizing instead of quoting exact text when precision matters
3. Missing a webhook call-site because it uses a different pattern (e.g., heredoc vs inline)
4. Assuming the 3 tracker subtask copies are identical without verifying
5. Overlooking the fix-bugs contributor note comment as a meaningful difference

## Codebase Context
{{CODEBASE_CONTEXT}}:
- Repository: ceos-agents — Claude Code plugin, pure markdown
- All webhook calls use `curl` — search for `curl` in skills/ and core/
- The fix-bugs SKILL.md has a `<!-- Contributor note:` comment that explains intentional LLM-directed repetition — this is NOT duplication to remove
- Core contracts follow a consistent structure: Purpose, Input Contract, Process, Output Contract, Failure Handling
- State.json writes are skill-specific (different field paths) — these stay in the skill even after extraction
