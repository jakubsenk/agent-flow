# Phase 7: Execute

## Persona
{{PERSONA}}: Senior Plugin Developer specializing in markdown-based workflow definitions, cross-cutting feature implementation, and maintaining consistency across multi-file plugin changes.

## Task Instructions
{{TASK_INSTRUCTIONS}}:

Execute the implementation plan for the Decomposition Subtask Tracker Creation feature (v6.4.0). Follow the plan exactly — do not add, remove, or reorder tasks.

### Execution Protocol

1. **Read the current file** before making any changes
2. **Use Edit tool** for surgical insertions (prefer over full file rewrites)
3. **Verify after each group** — check that changes are correct before proceeding
4. **Maintain consistency** — the 3 skill files must have identical patterns (adapted for step numbering)

### Critical Implementation Details

#### New Step Content Template
The "Create Tracker Subtasks" step in each skill should follow this structure:

```markdown
### Step {N}: Create Tracker Subtasks

**Guard clause — skip this step if ANY of:**
- `decomposition.decision` is `"SINGLE_PASS"` (no decomposition)
- Decomposition config `Create tracker subtasks` is `false`
- MCP tracker tools are not available (tracker_effective_status is not "ready" — scaffold/init context; for fix-ticket/fix-bugs/implement-feature, tracker was already verified at Step 0 MCP preflight)

If none of the guard conditions apply, proceed:

1. Read the parent issue ID from pipeline context (`{ISSUE-ID}`).

2. Iterate over `decomposition.subtasks[]` from state.json (or from the architect task tree if state is not yet written):
   For each subtask:

   a. **Idempotency guard:** If `subtask.tracker_id` is not null in state.json → skip creation for this subtask. Display: `Subtask {id} already has tracker issue {tracker_id} — skipping.`

   b. **Create tracker issue** via MCP:
      - Title: `[{ISSUE-ID}] {subtask.title}`
      - Description: `Subtask of {ISSUE-ID}.\n\nScope: {subtask.scope}\n\nFiles: {subtask.files joined by newline}\n\nAcceptance Criteria:\n{subtask.acceptance_criteria joined by newline}`

      **Tracker-specific parent linking:**

      | Tracker | Action |
      |---------|--------|
      | YouTrack | Create issue with `parent: {ISSUE-ID}` |
      | Jira | Create issue with `parent: {ISSUE-KEY}`, `issuetype: "Sub-task"` |
      | Linear | Create issue with `parentId: {ISSUE-ID}` |
      | Redmine | Create issue with `parent_issue_id: {ISSUE-ID}` |
      | GitHub | Create standalone issue with title `[{ISSUE-ID}] {subtask.title}`, then update parent issue body — append checklist entry: `- [ ] #{created-issue-number} {subtask.title}` |
      | Gitea | Same as GitHub: create standalone issue, then update parent issue body with checklist entry |

      **GitHub/Gitea checklist detail:**
      - Read current parent issue body via MCP
      - If body does not contain `## Subtasks` section: append `\n\n## Subtasks\n`
      - Append `- [ ] #{created-issue-number} {subtask.title}\n` to the Subtasks section
      - Update parent issue body via MCP

   c. **Write tracker_id back:**
      - Update `state.json`: set `decomposition.subtasks[N].tracker_id` to the created issue ID
      - Update `.claude/decomposition/{ISSUE-ID}.yaml`: set `tracker_id` field in the matching subtask entry
      - Follow atomic write protocol from `core/state-manager.md`

   d. **On failure:** Log `WARN: Could not create tracker issue for subtask {id}: {error}`. Continue to next subtask. NEVER block pipeline on tracker issue creation failure.

3. **Summary display:**
   - `Created {N}/{M} tracker subtask issues.`
   - If N < M: `{M-N} subtask(s) could not be created — see warnings above.`

4. **No commit needed** — tracker_ids are written to state.json and YAML only (no source file changes).
```

#### State Schema Addition
Add this row to the Subtask Object Fields table in state/schema.md, after `maps_to`:

```
| `tracker_id` | string or null | No | `null` | Tracker issue ID created for this subtask by the "Create tracker subtasks" step. Format depends on tracker type (e.g., `"PROJ-43"` for YouTrack/Jira, `"#123"` for GitHub/Gitea). Null if subtask issues were not created (config disabled, single-pass, or creation failed). |
```

#### Config Contract Addition
Update the Decomposition row in CLAUDE.md optional sections table:
- Old: `| Decomposition | Max subtasks, Fail strategy, Commit strategy | 7, fail-fast, squash |`
- New: `| Decomposition | Max subtasks, Fail strategy, Commit strategy, Create tracker subtasks | 7, fail-fast, squash, true |`

#### Cross-Skill Consistency Verification
After updating all 3 skills, verify:
1. All 3 have the same guard clause conditions
2. All 3 have the same 6-tracker table
3. All 3 have the same idempotency guard
4. All 3 have the same partial failure handling
5. All 3 have the same state.json update pattern
6. Step numbering is correct for each pipeline

## Success Criteria
{{SUCCESS_CRITERIA}}:
- [ ] State schema has tracker_id field in Subtask Object Fields
- [ ] CLAUDE.md Decomposition section includes Create tracker subtasks key
- [ ] All 3 skill files have the new step at the correct location
- [ ] All 6 tracker types are handled in each skill
- [ ] GitHub/Gitea checklist approach is implemented
- [ ] Idempotence guard is present in all 3 skills
- [ ] Partial failure handling (WARN, never block) in all 3 skills
- [ ] CHANGELOG.md has v6.4.0 entry
- [ ] roadmap.md updated
- [ ] docs/reference files updated
- [ ] Test suite passes

## Anti-Patterns
{{ANTI_PATTERNS}}:
- Do NOT rewrite entire files — use surgical Edit tool insertions
- Do NOT change step numbering of existing steps (insert new step, adjust subsequent references if needed)
- Do NOT modify architect agent definition (architect does not know about tracker_id)
- Do NOT modify fixer, reviewer, or test-engineer agents
- Do NOT change the decomposition decision logic
- Do NOT add tracker_id to the architect's task tree YAML format
- Do NOT block pipeline on tracker issue creation failure

## Codebase Context
{{CODEBASE_CONTEXT}}:
- Edit tool: `old_string` must be unique in the file, `new_string` replaces it
- Skill files are large markdown: implement-feature ~456 lines, fix-ticket ~451 lines, fix-bugs ~588 lines
- State schema: state/schema.md ~304 lines
- CLAUDE.md: config contract table is around line 151
- Pipeline diagrams in CLAUDE.md: Bug-Fix Pipeline ~line 47, Feature Pipeline ~line 53
- CHANGELOG.md: new entries go at the top (after the header, before v6.3.3)
- Roadmap: feature is at ~line 440 in BACKLOG section
