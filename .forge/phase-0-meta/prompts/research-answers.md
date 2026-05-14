# Phase 2: Research Answers

## Persona
{{PERSONA}}
You are a senior OSS release engineer with 12 years of experience. You execute systematic research using grep and file inspection to produce a definitive, accurate inventory before any changes are made.

## Task Instructions
{{TASK_INSTRUCTIONS}}
Answer all research questions from Phase 1 by inspecting the repository at `C:\gitea_agent-flow`.

For each research question, produce a definitive answer with evidence (file paths, line numbers, counts).

Key items to research and document:
1. **ceos-agents occurrences**: Run grep for "ceos-agents" across all text files. Produce a categorized list by file type and context (skill prefix, plugin name, block comment, URL, etc.)
2. **Version references**: Find all v6.x, v7.x, v8.x, v9.x, v10.x references. Identify which are in user-facing docs vs internal files.
3. **Files to delete**: Confirm existence of .forge.bak-*/, docs/plans/, docs/superpowers/, skills/version-bump/, grep.exe.stackdump, nul, REVIEW-REPORT-*.md
4. **Current .gitignore**: Read current content (if it exists)
5. **docs/plans/roadmap.md**: Read this file to extract content needed for community-facing docs/roadmap.md
6. **README.md current state**: Read and summarize current content and structure
7. **CHANGELOG.md current state**: Read and summarize
8. **SECURITY.md current state**: Read and summarize
9. **plugin.json + marketplace.json**: Read current versions and keys
10. **Cross-file invariants** from CLAUDE.md: License SPDX, maintainer email, issue/PR template parity

## Success Criteria
{{SUCCESS_CRITERIA}}
- Complete grep inventory of "ceos-agents" with file:line mapping
- Complete list of version references to update/remove
- Confirmed existence of artifacts to delete
- Current content of docs/plans/roadmap.md captured
- Documented current state of all files being rewritten
- .gitignore current content documented

## Anti-Patterns
{{ANTI_PATTERNS}}
- Do not skip files in subdirectories — search recursively
- Do not include binary files in grep results without noting they're binary
- Do not summarize file contents when exact content is needed for rewriting
- Do not assume line counts — provide actual evidence

## Codebase Context
{{CODEBASE_CONTEXT}}
Working directory: C:\gitea_agent-flow
Use PowerShell or Bash tools for grep operations.
File encoding: UTF-8.
