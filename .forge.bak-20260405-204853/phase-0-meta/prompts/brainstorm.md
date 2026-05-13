# Phase 3: Brainstorm

## Persona
{{PERSONA}}: Senior Plugin Architect specializing in workflow orchestration systems with deep expertise in issue tracker integration patterns, idempotent pipeline design, and cross-platform abstraction layers.

## Task Instructions
{{TASK_INSTRUCTIONS}}:

Brainstorm design approaches for adding decomposition subtask tracker creation to the implement-feature, fix-ticket, and fix-bugs pipelines. The user has already specified the high-level design — focus on implementation details and edge cases.

### Brainstorm Areas

1. **Step Placement**
   - Where exactly should the "Create tracker subtasks" step go in each pipeline?
   - Option A: Immediately after decomposition decision (before subtask execution)
   - Option B: After decomposition plan display/approval (after user confirms)
   - Option C: As part of the decomposition decision step itself
   - Evaluate: which placement best serves the user (seeing tracker IDs before execution)?

2. **GitHub/Gitea Checklist Approach**
   - User specified: "checklist in parent issue body"
   - How to implement: read parent issue body, append checklist, update issue body via MCP
   - Checklist format: `- [ ] #{subtask-issue-id} {subtask-title}` or `- [ ] {subtask-title} (#{subtask-issue-id})`
   - What if parent issue already has content? Append section with heading?
   - Alternative: scaffold uses standalone issues with `[{parent_title}] {subtask_title}` — should we support both?

3. **Shared Pattern Extraction**
   - Should we create a `core/subtask-tracker.md` shared contract?
   - Or inline the logic in each skill (like scaffold Step 4e is inlined)?
   - Pro shared: consistency across 3 skills, single source of truth
   - Pro inline: scaffold Step 4e is inlined and works fine, less indirection

4. **Idempotence Strategy**
   - Primary: check `tracker_id` in state.json `decomposition.subtasks[N]`
   - Fallback: title match via tracker search (for crash recovery where state was not saved)
   - Should title match be exact or prefix-based?
   - What about tracker_id stored in `.claude/decomposition/{ISSUE-ID}.yaml` too?

5. **Config Key Design**
   - Key name: `Create tracker subtasks` in Decomposition section
   - Default: `true` (user specified)
   - When false: skip the step entirely
   - Should it be a simple boolean, or support values like `true`, `false`, `if-decomposed`?

6. **Partial Failure Handling**
   - Follow scaffold accumulator pattern: continue on individual subtask failure
   - Log WARN per failure, display summary at end
   - Never block pipeline on tracker issue creation failure
   - What if MCP is unavailable at this point? (Should have been caught at Step 0 MCP preflight)

### Evaluation Criteria
Rate each option on: simplicity, consistency with existing patterns, user experience, maintainability.

## Success Criteria
{{SUCCESS_CRITERIA}}:
- [ ] Step placement decision with rationale
- [ ] GitHub/Gitea checklist design with format specification
- [ ] Shared pattern vs inline decision
- [ ] Idempotence strategy with primary + fallback approach
- [ ] Config key design finalized
- [ ] Partial failure handling approach documented

## Anti-Patterns
{{ANTI_PATTERNS}}:
- Do NOT over-engineer — this is a markdown plugin, not a runtime system
- Do NOT propose new agent definitions (no new agents needed)
- Do NOT change the architect's output format (add tracker_id downstream, not in architect)
- Do NOT break the existing decomposition flow — this is an additive step
- Do NOT propose breaking changes to the config contract (this is MINOR, not MAJOR)

## Codebase Context
{{CODEBASE_CONTEXT}}:
- Pure markdown plugin, no runtime code
- Scaffold Step 4e: inlined in skills/scaffold/SKILL.md, ~55 lines, handles all 6 trackers
- Existing core contracts: 11 files in core/ (config-reader, state-manager, decomposition-heuristics, etc.)
- Subtask object fields in state.json: id, title, status, commit_hash, restore_point, depends_on, scope, files, estimated_lines, acceptance_criteria, maps_to
- Decomposition config: Max subtasks (7), Fail strategy (fail-fast), Commit strategy (squash)
- Pipeline step numbering: implement-feature has Step 5 (decomposition), fix-ticket has Step 4b, fix-bugs has Step 3b
