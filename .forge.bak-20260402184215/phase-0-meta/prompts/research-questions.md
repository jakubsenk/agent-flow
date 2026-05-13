# Phase 1 — Research Questions

You are investigating two bugs in `skills/scaffold/SKILL.md`. Answer each research question with evidence from the codebase.

## Questions

### RQ-1: Story extraction from epic markdown

Read `spec/epics/*.md` files in the evidence project (`C:/Users/FSABACKY/claude/licence-ceos-agents-yt/spec/epics/`) and the spec-writer agent (`agents/spec-writer.md`).

1. What is the exact markdown structure of stories within epics? (heading level, naming convention, content sections)
2. Is there a reliable parsing boundary between stories? (e.g., `### Story N.M:` followed by `---` separators)
3. What content should go into a sub-issue title vs description? (story title as title, AC as description?)
4. How does the back-reference comment look for epics? (e.g., `<!-- YouTrack: LIC-3 -->`) — what would be the analogous format for stories?

### RQ-2: Tracker sub-issue creation capabilities

Read `docs/reference/trackers.md` and check MCP tool capabilities.

1. Which trackers support native sub-issues/subtasks? (YouTrack has subtasks, GitHub has task lists, Jira has sub-tasks, etc.)
2. What is the MCP API for creating a sub-issue in each supported tracker?
3. Is there a generic "create issue with parent" pattern that works across trackers, or do we need tracker-specific instructions?
4. If a tracker does NOT support sub-issues natively (e.g., GitHub), what is the fallback? (labels? linked issues? checklist items?)

### RQ-3: Issue state transitions after implementation

Read `skills/implement-feature/SKILL.md` Steps 9-10, `skills/fix-ticket/SKILL.md` Step 9, and `agents/publisher.md` Step 7.

1. How does `implement-feature` transition issue state to "Done" after implementation? (via publisher agent?)
2. What state transition syntax is used? (from `docs/reference/trackers.md` State Transition Syntax table)
3. Does the scaffold pipeline need a "Done" transition, or a different one? (scaffold creates issues at "Open" state — what's the correct final state?)
4. Where in Automation Config are the state transitions defined? (Issue Tracker -> State transitions)

### RQ-4: Scaffold pipeline flow after implementation

Read `skills/scaffold/SKILL.md` Steps 7, 7b, 8, 9.

1. At what point in the pipeline is each epic "done"? (after all its subtasks in Step 7 pass?)
2. Is there a natural insertion point for tracker state updates? (after each batch? after Step 7b spec compliance? before Step 9 report?)
3. Does the scaffold pipeline have access to the mapping from subtasks -> epics -> tracker issue IDs?
4. Where are the tracker issue IDs stored? (in-memory from Step 4e? in spec/epics/*.md back-references?)

### RQ-5: Test coverage for Step 4e

Search `tests/` for any test scenarios covering Step 4e (Create Tracker Issues).

1. Are there existing tests for the scaffold skill's tracker integration?
2. If yes, do they verify sub-issue creation?
3. What test format is used? (from `tests/harness/`)

## Output Format

For each RQ, provide:
- **Finding:** concise answer
- **Evidence:** file path + relevant excerpt
- **Implication:** what this means for the fix
