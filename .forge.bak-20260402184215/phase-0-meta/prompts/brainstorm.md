# Phase 3 — Brainstorm

You are brainstorming approaches for fixing two bugs in `skills/scaffold/SKILL.md`. Use the research findings from Phase 1 to inform your analysis.

## Bug 1: Stories not created as sub-issues

### Approach A: Expand Step 4e inline with detailed sub-steps

Add explicit sub-steps to Step 4e:
- 4e.1c.i: Parse each `### Story N.M:` heading in the epic markdown
- 4e.1c.ii: Extract story title (text after the `### Story N.M:` prefix)
- 4e.1c.iii: Extract story description (everything from the heading to the next `---` or next `### Story` heading)
- 4e.1c.iv: Create sub-issue via MCP with parent = epic issue ID
- 4e.1c.v: Write back-reference comment into spec file at the story heading level

**Pros:** All logic in one place, easy to follow sequentially.
**Cons:** Step 4e becomes very long. May be hard for the LLM to follow all sub-steps.

### Approach B: Create a separate "story extraction" helper section

Add a new section (e.g., `## Story Extraction Protocol`) that Step 4e references, similar to how other steps reference `core/*.md` files.

**Pros:** Keeps Step 4e concise, reusable pattern.
**Cons:** Adds indirection. May not be worth it for a single-use protocol.

### Approach C: Inline expansion with tracker-specific sub-issue guidance

Same as Approach A, but add a sub-table showing sub-issue creation patterns per tracker type (YouTrack subtask, GitHub linked issue, Jira sub-task, etc.).

**Pros:** Handles tracker diversity explicitly. Most robust.
**Cons:** Adds tracker-specific details that may become stale.

**Recommendation:** Approach A with minimal tracker-specific guidance. The LLM already knows how to use MCP tools per tracker type (from `docs/reference/trackers.md`). The main gap is the *instruction to actually create sub-issues*, not the *how* of using the tracker API. Keep it simple — expand Step 4e with clear, numbered sub-steps for parsing stories and creating sub-issues.

## Bug 2: Epics not closed after implementation

### Approach D: Close issues per-subtask (inline in Step 7d)

After each subtask commit in Step 7d, transition the corresponding story issue to "Done". After all stories in an epic are done, transition the epic to "Done".

**Pros:** Real-time state tracking — tracker reflects implementation progress.
**Cons:** Requires mapping from subtask -> story -> tracker issue ID. Complex state tracking during implementation loop. If a subtask fails and is rolled back, the story issue state is wrong.

### Approach E: Batch close after implementation loop (new Step 7e)

Add a new step after Step 7 (Feature Implementation Loop) completes, before Step 7b (Spec Compliance):
- Iterate over all tracker issues created in Step 4e
- For each successfully implemented story: transition to "Done"
- For each successfully completed epic (all stories done): transition epic to "Done"
- For blocked/skipped stories: leave as-is (or transition to "Blocked" if the tracker supports it)

**Pros:** Simple, single-pass. No complex state tracking during implementation. Rollback-safe — only closes issues after confirmed success.
**Cons:** Tracker issues stay "Open" during the entire implementation loop. Less granular progress tracking.

### Approach F: Close after Step 9 (Final Report) as a cleanup step

Add a new step after Step 9 that closes all successfully implemented issues.

**Pros:** Simplest possible insertion point. All implementation, testing, and compliance checks are done.
**Cons:** Issues stay open even after successful implementation until the very end. If the pipeline crashes between Step 7 and Step 9, issues remain open.

**Recommendation:** Approach E — batch close after the implementation loop. This is the cleanest insertion point because:
1. All code changes are committed and tested
2. Rollback has already happened for any failed subtasks
3. It's before spec compliance and E2E tests (which don't change the implementation)
4. It mirrors how implement-feature closes issues via publisher AFTER reviewer approval

The step should be conditional on `tracker_effective_status == "ready"` (same guard as Step 4e).

## Combined Recommendation

1. **Bug 1 fix:** Expand Step 4e with explicit sub-steps for story parsing and sub-issue creation (Approach A)
2. **Bug 2 fix:** Add new Step 7e for batch tracker issue closure (Approach E)

Both fixes are localized to `skills/scaffold/SKILL.md` with no changes needed to agents or core files.

## Judge Verdict

Evaluate both recommended approaches on:
- **Correctness:** Does it fix the reported bug?
- **Consistency:** Does it match patterns in fix-ticket and implement-feature?
- **Robustness:** Does it handle edge cases (partial failure, tracker unavailable, no stories in epic)?
- **Maintainability:** Is the change minimal and self-contained?
