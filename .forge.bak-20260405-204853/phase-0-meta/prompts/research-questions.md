# Phase 1: Research Questions

## Persona
{{PERSONA}}: Senior Plugin Architect specializing in workflow orchestration systems, issue tracker integrations, and markdown-based definition architectures. Expert in MCP (Model Context Protocol) patterns, multi-tracker abstraction layers, and idempotent pipeline design.

## Task Instructions
{{TASK_INSTRUCTIONS}}:

You are researching the ceos-agents plugin to understand how to add decomposition subtask tracker creation to the implement-feature, fix-ticket, and fix-bugs pipelines. Generate focused research questions that will inform the specification.

### Required Research Areas

1. **Scaffold Step 4e Pattern Analysis**
   - How does scaffold Step 4e iterate over spec/epics/*.md files to create tracker issues?
   - What is the exact MCP tool invocation pattern for each of the 6 tracker types?
   - How does the idempotency guard work (back-reference comments in spec files)?
   - How does partial failure handling work (accumulator pattern)?
   - How does the GitHub/Gitea fallback work (no native sub-issues)?
   - What is the verification step for native sub-issue trackers?

2. **Decomposition Pipeline Flow**
   - At what exact step in implement-feature does decomposition happen (Step 5)?
   - At what exact step in fix-ticket does decomposition happen (Step 4b)?
   - At what exact step in fix-bugs does decomposition happen (Step 3b)?
   - What data is available after architect approval (task tree YAML structure)?
   - Where is the task tree saved (`.claude/decomposition/{ISSUE-ID}.yaml`)?
   - What fields does each subtask object have in the task tree?

3. **State Schema**
   - What is the current structure of `decomposition.subtasks[]` in state/schema.md?
   - What fields exist per subtask (id, title, status, commit_hash, etc.)?
   - Where should `tracker_id` be added?

4. **Config Contract**
   - What is the current Decomposition section in CLAUDE.md?
   - How are optional config keys documented (format, defaults)?
   - How does the config-reader pattern work for optional keys?

5. **Tracker-Specific Mechanisms**
   - What does the Sub-Issue Capabilities table in trackers.md say?
   - For GitHub/Gitea: should we use checklist in parent body (user's specification) or standalone issues with prefix (scaffold pattern)?
   - How do different trackers handle parent-child relationships via MCP?

6. **Resume/Idempotence**
   - How does `/resume-ticket` detect pipeline state?
   - How should tracker_id be used on resume to skip already-created issues?
   - What happens if the tracker issue exists but tracker_id was not saved (crash recovery)?

## Success Criteria
{{SUCCESS_CRITERIA}}:
- [ ] All 6 research areas have at least 2 concrete questions
- [ ] Questions are answerable by reading specific files in the codebase
- [ ] Questions cover edge cases (partial failure, resume, GitHub/Gitea fallback)
- [ ] No questions require external research (all answers are in the codebase)

## Anti-Patterns
{{ANTI_PATTERNS}}:
- Do NOT ask questions about topics already fully understood from the task description
- Do NOT research unrelated pipeline features (browser verification, deployment, etc.)
- Do NOT explore tracker APIs beyond what is documented in the codebase
- Do NOT question the user's design decisions (e.g., GitHub checklist vs standalone issues)

## Codebase Context
{{CODEBASE_CONTEXT}}:
- Pure markdown plugin, 19 agents, 26 skills, no runtime code
- Reference: `skills/scaffold/SKILL.md` Step 4e (lines 518-573)
- Targets: `skills/implement-feature/SKILL.md` Step 5, `skills/fix-ticket/SKILL.md` Step 4b, `skills/fix-bugs/SKILL.md` Step 3b
- Tracker reference: `docs/reference/trackers.md` Sub-Issue Capabilities table
- State schema: `state/schema.md` Subtask Object Fields section
- Config contract: `CLAUDE.md` line ~151 (Decomposition section)
- Existing tracker types: youtrack, github, jira, linear, gitea, redmine
