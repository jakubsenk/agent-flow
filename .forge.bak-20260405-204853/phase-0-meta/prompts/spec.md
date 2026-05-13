# Phase 4: Specification

## Persona
{{PERSONA}}: Senior Plugin Architect and Technical Writer specializing in workflow orchestration plugin design, configuration contract specification, and cross-platform issue tracker integration patterns.

## Task Instructions
{{TASK_INSTRUCTIONS}}:

Write a formal specification for the Decomposition Subtask Tracker Creation feature (v6.4.0). The spec must be precise enough that any phase can implement from it without ambiguity.

### Specification Structure

#### 1. Feature Overview
- Feature name: Decomposition Subtask Tracker Creation
- Version: 6.4.0 (MINOR)
- Scope: 3 skills (implement-feature, fix-ticket, fix-bugs) + state schema + config contract + docs

#### 2. New Pipeline Step: "Create Tracker Subtasks"

Specify for each of the 3 pipelines:
- **implement-feature:** New Step 5a, after Step 5 (decomposition decision, plan display/approval) and before Step 6 (subtask execution)
- **fix-ticket:** New Step 4b-tracker, after Step 4b (decomposition decision, plan display/approval) and before Step 4c (subtask execution)
- **fix-bugs:** New Step 3b-tracker, after Step 3b (decomposition decision, plan display/approval) and before Step 3c (subtask execution)

For each pipeline, specify:
- Guard clause (when to skip)
- Input (task tree from architect, parent issue ID, tracker config)
- Process (iterate subtasks, create issues, write back tracker_id)
- Output (updated state.json with tracker_ids)
- Partial failure handling
- Idempotence behavior

#### 3. Tracker-Specific Parent Link Mechanisms

Specify for each of the 6 tracker types:
- **YouTrack:** Create issue with `parent: {ISSUE-ID}` parameter
- **Jira:** Create sub-task with `parent: {ISSUE-KEY}`, `issuetype: "Sub-task"`
- **Linear:** Create issue with `parentId: {ISSUE-ID}`
- **Redmine:** Create issue with `parent_issue_id: {ISSUE-ID}`
- **GitHub:** Create standalone issue, then update parent issue body with checklist entry `- [ ] #{subtask-issue-number} {subtask-title}`
- **Gitea:** Same as GitHub (create standalone issue, update parent body with checklist)

#### 4. Idempotence Specification

- Primary check: if `decomposition.subtasks[N].tracker_id` is not null in state.json, skip creation for that subtask
- Secondary check: if tracker_id is null but `.claude/decomposition/{ISSUE-ID}.yaml` has a tracker_id for that subtask, use it
- Tertiary check (crash recovery): search tracker for issue with matching title prefix; if found, store tracker_id and skip creation

#### 5. State Schema Update

- Add `tracker_id` field to Subtask Object Fields in state/schema.md
- Type: string or null
- Default: null
- Description: Tracker issue ID created for this subtask (e.g., "PROJ-43", "#123")
- Also update `.claude/decomposition/{ISSUE-ID}.yaml` with tracker_id per subtask

#### 6. Config Contract Update

- New key in Decomposition section: `Create tracker subtasks`
- Default: `true`
- Type: boolean (true/false)
- When false: skip the "Create tracker subtasks" step entirely
- CLAUDE.md contract table update: add key to Decomposition row

#### 7. Documentation Updates

List every file that needs updating with specific changes:
- `CLAUDE.md`: Decomposition config table, pipeline diagrams
- `docs/reference/skills.md`: implement-feature, fix-ticket, fix-bugs sections
- `docs/reference/pipelines.md`: pipeline diagrams and stage tables
- `docs/reference/automation-config.md`: Decomposition section
- `CHANGELOG.md`: v6.4.0 entry
- `docs/plans/roadmap.md`: move from BACKLOG to DONE

## Success Criteria
{{SUCCESS_CRITERIA}}:
- [ ] Every pipeline has a precisely placed new step with guard clause, input, process, output
- [ ] All 6 tracker types have specific parent-link mechanism documented
- [ ] Idempotence strategy has 3 tiers (state.json, YAML, title search)
- [ ] State schema change is fully specified (field name, type, default)
- [ ] Config key is fully specified (name, default, type, behavior)
- [ ] Documentation change list covers all files with specific changes
- [ ] No ambiguity — any developer can implement from this spec alone

## Anti-Patterns
{{ANTI_PATTERNS}}:
- Do NOT specify changes to agent definitions (architect output format stays the same)
- Do NOT introduce new required config keys (this is MINOR, not MAJOR)
- Do NOT change the existing decomposition decision logic
- Do NOT specify runtime code (this is a markdown plugin)
- Do NOT omit any of the 6 tracker types
- Do NOT skip the GitHub/Gitea checklist specification (these are the tricky cases)

## Codebase Context
{{CODEBASE_CONTEXT}}:
- Reference pattern: `skills/scaffold/SKILL.md` Step 4e (lines 518-573)
- Sub-Issue Capabilities: `docs/reference/trackers.md` (lines 86-97)
- Insertion points: implement-feature Step 5 (after plan approval), fix-ticket Step 4b (after decomposition), fix-bugs Step 3b (after decomposition)
- State schema: `state/schema.md` Subtask Object Fields (lines 192-208)
- Config contract: `CLAUDE.md` line 151 (Decomposition row in optional sections table)
- Current Decomposition keys: Max subtasks, Fail strategy, Commit strategy
- Plugin version: 6.3.3 -> 6.4.0
