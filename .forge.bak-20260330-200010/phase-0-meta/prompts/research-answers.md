# Phase 2 — Research Answers

## Context

You are synthesizing research for a v5.6.1 UX Polish release of the ceos-agents plugin. You have access to the target files and should answer each question from Phase 1 with precise file locations and content excerpts.

## Instructions

For each question from Phase 1, provide:
1. **Answer** — direct, factual answer
2. **Evidence** — exact file path, line numbers, and relevant excerpt
3. **Implication** — what this means for implementation

### Key Files to Read

- `commands/scaffold.md` — full file, focus on lines 22, 36-40, 56-67, 146-163, 748-751
- `core/mcp-detection.md` — full file (62 lines), focus on lines 38-43, 55-61
- `commands/resume-ticket.md` — full file (119 lines), focus on pipeline type detection and state restoration
- `state/schema.md` — lines 50-61, 154-161 (infrastructure field)
- `tests/` — search for any tests referencing `--infra`

### Format

Answer each numbered question (Q1-Q13) with the three-part structure above. Be precise about line numbers — downstream phases will use these as edit targets.

### Important Notes

- This is a pure markdown plugin. "Implementation" means editing markdown instruction text, not writing code.
- The `--infra` flag is parsed by Claude Code at runtime from the command's markdown instructions — there is no code parser to update.
- `core/mcp-detection.md` is a shared contract referenced by multiple commands. Changes there propagate to all consumers.
