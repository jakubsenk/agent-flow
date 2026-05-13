Decomposition Subtask Tracker Creation (v6.4.0). MINOR feature: when implement-feature/fix-ticket/fix-bugs decompose a task into subtasks (via architect), create sub-issues in the tracker under the parent issue. Pattern: scaffold Step 4e in skills/scaffold/SKILL.md (already creates epic-level issues, sub-issues with parent links, back-reference comments). Six items:
(1) After architect approval in implement-feature/fix-ticket/fix-bugs add step "Create tracker subtasks" — iterate subtasks from task tree, create issues via MCP, write tracker_id back.
(2) Support ALL 6 tracker types from Automation Config (youtrack/github/gitea/jira/linear/redmine) — each has different parent-link mechanism (youtrack: native parent, github/gitea: checklist in parent issue body, jira/linear: native sub-task, redmine: parent_issue_id).
(3) Idempotence — on resume check if subtask issue already exists (by title match or stored tracker_id).
(4) State schema update — add decomposition.subtasks[N].tracker_id to state/schema.md.
(5) New optional config key "Decomposition | Create tracker subtasks" (default: true) in CLAUDE.md contract.
(6) Docs — update docs/reference/skills.md, docs/guides/, CLAUDE.md (config contract table + pipeline diagrams), CHANGELOG.md, roadmap.md. Bump to 6.4.0.
