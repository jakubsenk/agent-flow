# Phase 2: Research Answers

## Persona
{{PERSONA}}: Senior Plugin Architect specializing in workflow orchestration systems, issue tracker integrations, and markdown-based definition architectures. Expert in MCP tool invocation patterns and multi-tracker abstraction.

## Task Instructions
{{TASK_INSTRUCTIONS}}:

Answer each research question from Phase 1 by reading the specific codebase files. For each answer, cite the exact file path and line numbers. Focus on extracting concrete patterns that can be reused.

### Research Protocol

1. **Read each target file** using the Read tool
2. **Extract exact patterns** — quote the relevant markdown sections
3. **Identify reusable elements** that can be adapted for decomposition subtask creation
4. **Note differences** between scaffold Step 4e and the decomposition use case
5. **Resolve open design questions** (especially GitHub/Gitea approach)

### Key Files to Read
- `skills/scaffold/SKILL.md` — Step 4e (lines 518-573): full tracker issue creation pattern
- `skills/implement-feature/SKILL.md` — Step 5 (decomposition decision): insertion point
- `skills/fix-ticket/SKILL.md` — Step 4b (decomposition decision): insertion point
- `skills/fix-bugs/SKILL.md` — Step 3b (decomposition decision): insertion point
- `docs/reference/trackers.md` — Sub-Issue Capabilities table: parent-link mechanisms
- `state/schema.md` — Subtask Object Fields: current schema
- `CLAUDE.md` — Config Contract: Decomposition section
- `core/decomposition-heuristics.md` — when decomposition triggers
- `agents/architect.md` — task tree output format
- `skills/resume-ticket/SKILL.md` — resume detection logic

### Answer Format
For each research area:
```
## Area N: {title}
### Q: {question}
**Answer:** {concrete answer}
**Source:** {file path}, lines {N-M}
**Reusable pattern:** {what can be directly adapted}
**Adaptation needed:** {what needs to change for decomposition context}
```

## Success Criteria
{{SUCCESS_CRITERIA}}:
- [ ] Every research question has a concrete, cited answer
- [ ] GitHub/Gitea approach is resolved (checklist vs standalone — user specified checklist)
- [ ] Insertion points in all 3 skills are precisely identified (step number, line number)
- [ ] State schema extension is designed (tracker_id field definition)
- [ ] Idempotence strategy is designed (title match + stored tracker_id)

## Anti-Patterns
{{ANTI_PATTERNS}}:
- Do NOT speculate — every answer must cite a specific file
- Do NOT propose implementation details yet — this phase is research only
- Do NOT read files that are not relevant to the research questions
- Do NOT conflate scaffold's epic/story model with decomposition's subtask model

## Codebase Context
{{CODEBASE_CONTEXT}}:
- Pure markdown plugin, 19 agents, 26 skills, no runtime code
- Scaffold Step 4e creates epic-level issues + story sub-issues from spec/epics/*.md
- Decomposition creates subtask issues from architect task tree (YAML)
- 6 tracker types: youtrack (native parent), github (no native sub-issues), jira (native Sub-task), linear (native parentId), gitea (no native sub-issues), redmine (native parent_issue_id)
- State schema version: 1.0
- Config contract: table format (`| Key | Value |`)
