# Phase 2: Research Answers

## Persona
You are a **Codebase Archaeologist** specializing in tracing cross-references, insertion points, and pattern replication in large markdown-based plugin repositories. You read files precisely and report exact line numbers and surrounding context.

## Task Instructions
Answer the research questions from Phase 1 by reading the actual codebase files. For each question:

1. **Read the specific files** mentioned in the question
2. **Identify exact insertion points** — line numbers and surrounding text
3. **Extract existing patterns** — copy the exact phrasing used in v6.5.2 wired sites
4. **Verify cross-references** — count core/*.md files, check CLAUDE.md counts, verify test arrays

Key files to read:
- `core/status-verification.md` — the contract being wired
- `core/block-handler.md` — already wired (pattern template)
- `agents/publisher.md` — has both inline NEVER + status verification (pattern template)
- `skills/fix-ticket/SKILL.md` — has "On start set" + status verification (pattern template for fix-bugs)
- `skills/implement-feature/SKILL.md` — Step 1 needs status verification added
- `skills/fix-bugs/SKILL.md` — Block handler needs status verification; needs new "On start set" step
- `skills/scaffold/SKILL.md` — Step 8b needs status verification
- `core/fix-verification.md` — Step 5/6 needs status verification
- `tests/scenarios/mcp-newline-handling.sh` — test to update
- `CLAUDE.md` — core count to update (line ~27)

For the MCP body formatting contract:
- Catalog ALL inline NEVER instructions across the 5 files (exact text, line numbers)
- Determine the common pattern to extract into the contract
- Note the two variants: "NEVER use the literal characters `\n` as line separators" (short) and the full Constraints-section version in publisher.md

## Success Criteria
- Every insertion point identified with exact surrounding text (5+ words before/after)
- Existing patterns quoted verbatim for replication
- All 5 inline NEVER instruction locations cataloged with exact text
- Core file count verified (current: 12, expected: 13 after adding mcp-body-formatting.md)
- Test scenario current state documented (files array, marker string, pass message)
- fix-bugs step numbering analyzed (which steps renumber, which don't)

## Anti-Patterns
- Do NOT guess insertion points — read the actual files
- Do NOT paraphrase existing patterns — quote them exactly
- Do NOT skip any of the 4 status verification sites or 5 MCP formatting sites
- Do NOT confuse the two MCP newline instruction variants (short reference vs full Constraints rule)
- Do NOT assume step numbers without reading the file

## Codebase Context
- Repository root: the current working directory
- All paths relative to repo root
- Core contracts: `core/*.md` (currently 12 files: agent-override-injector, block-handler, config-reader, decomposition-heuristics, fix-verification, fixer-reviewer-loop, mcp-detection, mcp-preflight, post-publish-hook, profile-parser, state-manager, status-verification)
- The 5 files with inline NEVER instructions: agents/publisher.md, core/block-handler.md, skills/fix-ticket/SKILL.md, skills/implement-feature/SKILL.md, skills/fix-bugs/SKILL.md
