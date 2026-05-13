# Agent 3 Research Findings: Issue State Transitions & Scaffold Pipeline Flow

---

## RQ-3: Issue state transitions after implementation

### RQ-3.1: How does `implement-feature` transition issue state to "Done" after implementation?

**Finding:** `implement-feature` does NOT directly set the issue to "Done". It delegates publishing to the `publisher` agent (Step 10), which sets the state to "For Review" (or the configured equivalent from `State transitions → For Review`). The actual "Done" transition is expected to happen separately — either manually, via the optional Verify command post-merge step (Step 10b re-opens the issue on failure, implying external closure on success), or by a separate process after PR merge.

**Evidence:** `skills/implement-feature/SKILL.md`, Step 10:
```
Run the publisher agent (Task tool, model: haiku):
- Context: PR Description Template, Labels, Remote, Base branch, changed files, Extra labels
```

`agents/publisher.md`, Step 7:
```
7. Update Issue Tracker
   - Set issue state: "For Review" (or equivalent from Automation Config → State transitions)
   - Add comment to issue with PR link
```

Step 10b of `implement-feature` (Fix Verification):
> "If State transitions contains a key for re-open → set the state back"

This is the only place a post-merge state change is mentioned — and it is for re-opening on failure, not for closing on success.

**Implication:** For the scaffold pipeline, which creates new tracker issues at Step 4e, there is no built-in mechanism to set issues to "Done" after implementation. A "Done" transition would need to be explicitly added to the scaffold pipeline after each epic's subtasks complete (e.g., after each batch in Step 7, or after Step 7b spec compliance check).

---

### RQ-3.2: What state transition syntax is used?

**Finding:** State transitions are tracker-specific strings stored in Automation Config → Issue Tracker → State transitions. The format depends on the tracker type:

**Evidence:** `docs/reference/trackers.md`, State Transition Syntax table:

| Tracker | Format | Example: Done |
|---------|--------|---------------|
| youtrack | `State: {name}` | `State: Done` |
| github | `add label:{name}`, `set state:{name}`, or `close` | `close` |
| jira | `transition:{name}` | `transition:Done` |
| linear | `state:{name}` | `state:Done` |
| gitea | `add label:{name}` or `close` | `close` |
| redmine | `status:{name}` | `status:Closed` |

**Implication:** The scaffold pipeline must use the `State transitions` map from Automation Config to look up the correct "Done" key (analogous to how the block handler uses `State transitions → Blocked`). The exact key name to use for "Done" is what needs to be determined — likely a new config key (e.g., `Done`) would need to be added to the State transitions table, or the pipeline can use an existing transition value if one exists.

---

### RQ-3.3: Does the scaffold pipeline need a "Done" transition, or a different one?

**Finding:** Scaffold creates issues at an implicitly "Open" state (Step 4e explicitly states: "Do NOT apply the `On start set` state transition from Automation Config. Issues represent planned work, not started work."). The correct final state after a scaffold epic is implemented would be "Done" (or tracker-equivalent: "Closed", "Resolved", etc.), since the work is fully committed and tested — not just "For Review" (no PR is created per epic in scaffold).

**Evidence:** `skills/scaffold/SKILL.md`, Step 4e:
> "Do NOT apply the `On start set` state transition from Automation Config. Issues represent planned work, not started work. The `On start set` transition applies when `/implement-feature` begins working on each issue."

`skills/scaffold/SKILL.md`, Block handler in Step 7:
> "Context: `'No issue tracker context — skip issue tracker updates.'`"

This confirms the scaffold pipeline currently makes zero issue tracker state updates during implementation. There is no "For Review" intermediate state because scaffold does not create PRs per epic — it commits directly.

**Implication:** A "Done" transition (not "For Review") is appropriate for scaffold. The scaffold pipeline commits code directly to the branch without a per-epic PR, so "For Review" would be semantically wrong. The fix needs to add a "Done" transition call after each epic's subtasks complete (the rollback-agent in scaffold explicitly skips issue tracker updates — this guard would need to be respected so only successful epics are marked Done).

---

### RQ-3.4: Where in Automation Config are the state transitions defined?

**Finding:** State transitions are defined in the `Issue Tracker` section of `## Automation Config` under the `State transitions` key. This is a required section (all pipelines read it).

**Evidence:** `skills/implement-feature/SKILL.md`, Configuration block:
```
Required:
- Issue Tracker: Type, Instance, Project, State transitions, On start set
```

`agents/publisher.md`, Step 1:
```
- Issue Tracker: Type (determines which MCP server to use, default: youtrack), State transitions
```

`docs/reference/trackers.md` State Transition Syntax table defines the per-tracker format. The CLAUDE.md config contract documents:
```
| Issue Tracker | Type, Instance, Project, Bug query, State transitions, On start set |
```

**Implication:** The `State transitions` key already exists in every properly configured Automation Config. Adding a `Done` entry to the state transitions table is a backward-compatible extension (it would be an optional new key within the existing required section). Any fix that reads a "Done" transition from this key must gracefully handle the case where the key is absent (e.g., skip state update with a warning).

---

## RQ-4: Scaffold pipeline flow after implementation

### RQ-4.1: At what point in the pipeline is each epic "done"?

**Finding:** An epic is functionally "done" after all its subtasks have passed the fixer → reviewer → test-engineer cycle (Step 7a/7b/7c) AND the full test suite passes at the end of the batch. There is no single explicit "epic complete" marker — the pipeline operates on subtasks and batches, not epics directly. The post-batch test suite run (after each batch at the end of Step 7) is the closest natural completion point for all subtasks belonging to that batch.

**Evidence:** `skills/scaffold/SKILL.md`, Step 7:
```
For each batch in order:
  For each subtask in batch (respecting depends_on):
    7a. Fixer → 7b. Reviewer → 7c. Test-engineer → 7d. Commit subtask

  After each batch completes:
    Run full test suite (Test command from CLAUDE.md)
    If failure → fixer repairs (max Build retries)
    If still failing → STOP and jump to Step 9 (report)
```

Step 7b (Spec Compliance Check) runs AFTER the entire feature implementation loop — it is a post-loop check, not a per-epic check.

**Implication:** The natural insertion point for tracker state updates is "after each batch completes" (i.e., after the post-batch test suite passes). At that point, all subtasks in the batch — and their parent epics (if fully covered by that batch) — are done. This requires maintaining a mapping from subtask → epic to know which epic IDs to mark Done when a batch finishes.

---

### RQ-4.2: Is there a natural insertion point for tracker state updates?

**Finding:** Yes — there are two viable insertion points:

1. **After each batch completes** (post-batch test suite pass in Step 7): This is the earliest point where work is confirmed stable. Epics whose subtasks all reside in the just-completed batch can be marked Done here.

2. **Before Step 9 (Final Report)**: After Step 7b spec compliance check, before generating the report. This is simpler (one bulk update), but delays state updates until the very end — epics completed in early batches stay "Open" until the pipeline finishes.

**Evidence:** `skills/scaffold/SKILL.md`, Step 7 (end of batch block):
```
After each batch completes:
  Run full test suite (Test command from CLAUDE.md)
  If failure → fixer repairs (max Build retries)
  If still failing → STOP and jump to Step 9 (report)
```

Step 9:
```
Update state.json: set top-level status to "completed".
```
No tracker state updates happen in Step 9 currently.

**Implication:** The "after each batch" insertion point is superior for partial-failure scenarios (fail-fast): if the pipeline stops mid-way, already-completed epics would already be marked Done in the tracker. The pre-Step-9 insertion point is simpler to implement but leaves all issues "Open" if the pipeline is stopped by fail-fast. A "before Step 9" update is also needed as a catch-all for any epics whose subtasks span multiple batches.

---

### RQ-4.3: Does the scaffold pipeline have access to the mapping from subtasks -> epics -> tracker issue IDs?

**Finding:** Partially — the mapping exists in the architect output (Step 5) which produces a task tree with subtasks grouped by epic, and in Step 6 where the decomposition plan is displayed with an "Epic" column. However, this mapping is in-memory and is not explicitly persisted to disk in a structured form that later steps can query. The tracker issue IDs are written back into `spec/epics/*.md` files at Step 4e, not into the task tree or state.json.

**Evidence:** `skills/scaffold/SKILL.md`, Step 5 (architect output):
```
For each epic, format user stories into the structured specification format
```

Step 6 (Feature Plan Checkpoint), table format:
```
| # | Subtask | Files | ~Lines | Epic |
|---|---------|-------|--------|------|
| 1 | ... | ... | ~N | 01-auth |
```

Step 4e:
> "d. Write the created issue ID back into the spec file as a reference comment."

Step 4e does NOT write issue IDs to state.json or any structured lookup table — it writes them inline into `spec/epics/*.md` as reference comments.

**Implication:** To mark epics as Done, the pipeline would need to either: (a) maintain in-memory tracking of `{epic_id → tracker_issue_id}` from Step 4e through Step 7, or (b) re-read `spec/epics/*.md` at the completion point to extract the back-references written in Step 4e. Option (b) is more robust against pipeline interruption. The spec files are the canonical store of epic → tracker ID mapping.

---

### RQ-4.4: Where are the tracker issue IDs stored?

**Finding:** Tracker issue IDs are written back into `spec/epics/*.md` files as inline reference comments (Step 4e). They are NOT stored in state.json, `.claude/decomposition/`, or any other structured file. This means the only reliable read-back mechanism is parsing the spec epic files.

**Evidence:** `skills/scaffold/SKILL.md`, Step 4e:
```
For each epic file:
  a. Create an epic-level issue in the tracker project
  c. For each user story within the epic: create a sub-issue under the epic issue.
  d. Write the created issue ID back into the spec file as a reference comment.
  e. Track the result: success or failure for this epic.
```

Step 9 (Final Report) references `tracker_project` and `{N} epics created` counts but does not read back individual issue IDs from spec files — it uses the in-memory `tracker_effective_status` and counts.

**Implication:** Any implementation that needs to mark tracker issues as Done must parse `spec/epics/*.md` to extract the issue ID back-references written at Step 4e. The format of these reference comments is not formally specified in the current SKILL.md — this would need to be standardized (e.g., `<!-- tracker-issue-id: {ID} -->`) to make parsing reliable. Alternatively, the fix could persist the `{epic_filename → issue_id}` mapping into state.json during Step 4e, making it available to later steps without file parsing.
