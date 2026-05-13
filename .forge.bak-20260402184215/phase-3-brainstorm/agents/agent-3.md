# Agent 3: Skeptical / Adversarial Analysis

**Perspective:** Challenge assumptions, find hidden risks, stress-test edge cases.

---

## 1. Is the Root Cause Correct?

### Bug 1: Sub-issues not created

**The research misdiagnoses this.** Step 4e line 523 already says: "For each user story within the epic: create a sub-issue under the epic issue." The instruction EXISTS. The question is: why doesn't the LLM follow it?

Three competing hypotheses:

**H1 (Research's theory): Instruction is too terse.** Adding parsing details (split on `---`, match `### Story N.M:`) would help the LLM execute reliably. This is plausible but unproven — we have no evidence that the LLM tried and failed vs. skipped entirely.

**H2 (Stronger theory): The LLM doesn't know HOW to create a sub-issue on the specific tracker.** The instruction says "create a sub-issue" but never tells the LLM which MCP tool to call, what parameter links child to parent, or that GitHub/Gitea don't support sub-issues at all. The LLM likely calls `create_issue` (which works for epics) and either (a) doesn't know the parent parameter for sub-issues, or (b) the MCP tool doesn't accept a parent parameter on GitHub/Gitea, so the call silently creates a standalone issue or errors out and gets swallowed by the accumulator pattern on line 528.

**H3 (Simplest theory): Step 4e.1.d says "Write the created issue ID back" (singular).** The LLM reads "the created issue ID" as referring to one ID — the epic. There is no explicit instruction to write back STORY IDs. So the LLM creates the epic, writes back its ID, and considers step 1.d complete, then moves to 1.e. The sub-issue step (1.c) may execute but its output is discarded because 1.d only writes back "the" ID.

**Verdict:** The root cause is likely a COMBINATION of H2 and H3. The fix needs to:
- Make the sub-issue creation instruction tracker-aware (H2)
- Make the ID writeback instruction explicitly cover BOTH epic and story IDs (H3)
- Adding parsing details (H1) is helpful but secondary

### Bug 2: No "Done" transition after implementation

**The research is correct here, but the proposed solution is wrong.** The research suggests adding an "On complete" config key. This is unnecessary and creates a contract change. Here's why:

**"Done" is ALREADY a documented state in State transitions.** Look at every example in `docs/reference/automation-config.md`:
- GitHub: `Done → closed`
- YouTrack: `In Progress, For Review, Blocked, Done`
- Gitea: `Done → closed`
- Redmine: `Done: status:Closed`

The State transitions value already contains a "Done" mapping. No new config key is needed. The fix is simply: read `State transitions → Done` from the existing config value and apply it. If the user's config doesn't include "Done" in their State transitions mapping, skip with a warning. This is a PATCH, not a MINOR.

**However:** The real question is — do we WANT scaffold to transition issues to Done? In the bug-fix/feature pipelines, the publisher sets "For Review" and the human (or post-merge verify) closes the issue. Scaffold is different because it commits directly without per-epic PRs. But consider: the scaffold implementation might be PARTIAL (blocked features). Setting an epic to "Done" when its subtasks were implemented by the scaffold fixer is a strong claim. Who verifies that the implementation actually meets the acceptance criteria? The spec-reviewer (Step 7b) does a compliance check, but it checks the WHOLE spec, not per-epic.

---

## 2. Scope Creep Risk: What's Actually In Scope?

The research proposes ALL of the following:
1. Expanded Step 4e with story parsing details
2. Tracker-specific sub-issue capabilities table
3. GitHub/Gitea fallback strategy (standalone issue + naming convention + label + cross-references)
4. Story ID back-reference format definition
5. State.json persistence of issue ID mapping
6. New "On complete" config key
7. Done transition at two insertion points (post-batch + pre-Step 9)
8. New tests for all of the above
9. Updates to `docs/reference/trackers.md`

**This is NOT a bugfix. This is a feature.** A bugfix for "sub-issues aren't created" should make the existing instruction work, not redesign the tracker integration layer.

### Minimum Viable Fix (Bug 1):

1. Expand Step 4e.1.c with explicit per-story iteration: "Parse stories from epic markdown (split on `---`, match `### Story N.M:` heading). For each story: create an issue with title = story title, description = story body. If tracker supports parent linking (YouTrack, Jira, Linear, Redmine): set parent to the epic issue ID. If tracker does NOT support parent linking (GitHub, Gitea): prefix title with `[{epic_title}]` and add a comment linking to the epic issue."
2. Expand Step 4e.1.d to explicitly say "Write back BOTH the epic issue ID and each story issue ID."
3. Define the story back-reference format inline.

That's it. No capabilities table, no trackers.md update, no state.json change.

### Minimum Viable Fix (Bug 2):

1. Add a Step 7e (or incorporate into the post-batch section of Step 7) that reads `State transitions → Done` from the generated CLAUDE.md and applies it to epic issues whose subtasks are all completed.
2. Guard: skip if "Done" is not present in State transitions value.
3. Guard: skip if `tracker_write_available` is false.

No "On complete" config key. No state.json persistence (read IDs from spec/epics/*.md back-references, which already exist).

### Items explicitly OUT of scope for this bugfix:

- `docs/reference/trackers.md` sub-issue capabilities table (MINOR feature, separate ticket)
- State.json persistence of issue ID mapping (nice-to-have, not required — file parsing works)
- New "On complete" config key (unnecessary — "Done" already exists in State transitions)
- Multiple insertion points for Done transition (one point is sufficient for v1)

---

## 3. Edge Cases Stress-Tested

### 3a. Epic with 0 stories

**Risk: HIGH.** If an epic markdown file contains only an epic-level description and no `### Story` headings, the story parsing loop produces zero iterations. The epic issue still gets created (Step 4e.1.a), which is correct. But the downstream architect (Step 5) formats stories into acceptance criteria — an epic with 0 stories produces 0 AC, which means the AC coverage check will vacuously pass (no AC to cover = 100% coverage). This is existing behavior and NOT caused by this fix, but the fix should not make it worse. The fix MUST handle the zero-story case gracefully: create the epic issue, skip sub-issue creation, continue.

### 3b. Tracker MCP available but sub-issue creation fails (API error)

**Risk: MEDIUM.** The accumulator pattern (lines 527-536) already handles per-epic failures. But the fix introduces per-STORY failures within an epic. What happens if:
- Epic issue created successfully (1.a)
- Story 1 sub-issue created successfully (1.c)
- Story 2 sub-issue creation fails (API error)
- Story 3 sub-issue created successfully (1.c)

The accumulator pattern is epic-level, not story-level. The fix needs to specify: does a single story failure mark the whole epic as failed? Or do we track partial story success within an epic? My recommendation: log the story failure, continue to next story, count the epic as "partial" (not failed). The commit message should reflect partial success.

### 3c. Pipeline resume after Step 4e — are IDs accessible?

**Risk: LOW but real.** If the pipeline crashes after Step 4e but before Step 5, and the user runs `/resume-ticket` or restarts scaffold, the epic/story IDs are available in `spec/epics/*.md` back-reference comments (they were committed in the `chore: link spec epics to tracker issues` commit). So this works. BUT: if the crash happens DURING Step 4e (after some epics but before the commit on line 531), the IDs for already-processed epics are in the working tree but NOT committed. A resume would need to detect which epics already have back-references and skip them. The current fix should add a guard: "If epic file already contains a tracker back-reference comment, skip creating a duplicate issue."

### 3d. "Done" not in State transitions

**Risk: HIGH if not handled.** The research correctly identifies this risk. Many existing config examples DO include "Done" in State transitions, but the mock project (`tests/mock-project/CLAUDE.md`) does NOT:

```
| State transitions | In Progress: `In Progress`, Blocked: `Blocked`, For Review: `For Review` |
```

No "Done" mapping. The fix MUST check for the "Done" key within the State transitions value. If absent: log a warning (`WARN: State transitions does not include a 'Done' mapping. Skipping issue completion.`) and continue. This is the only safe behavior.

**Critically:** 5 out of 7 example configs in `examples/configs/` also LACK a "Done" mapping (only `redmine-rails.md` has it). BUT the reference docs (`docs/reference/automation-config.md`) show "Done" in all 4 tracker examples (GitHub, YouTrack, Gitea, Redmine). This inconsistency means the fix will silently skip the Done transition for most real-world projects unless we also update the example configs. That update is arguably in scope since it's fixing an omission in the examples, not a contract change.

### 3e. Partial implementation — some stories implemented, some blocked

**Risk: HIGH.** This is the thorniest edge case. Consider:
- Epic 1 has 3 stories. Stories 1 and 2 are implemented. Story 3 is blocked (fixer gave up).
- Should Epic 1 be set to "Done"?

**Absolutely not.** The fix must track which subtasks (mapped from stories) were blocked vs. completed. An epic should only transition to "Done" if ALL its subtasks completed successfully. If any subtask was blocked, the epic should remain in its current state (open/planned). The blocked subtasks are already reported in Step 9's Final Report.

But this creates a dependency: the Done-transition step needs to know which subtasks belong to which epic AND which subtasks were blocked. This mapping is available from:
- Architect output (subtask -> epic mapping via `maps_to`)
- State.json (blocked subtask list)
- spec/epics/*.md (back-references for story IDs)

This is more complex than it appears. The minimum viable approach: only transition epics to Done if the pipeline completed with ZERO blocked features. Otherwise, skip all Done transitions and let the human sort it out. This is safe and simple.

---

## 4. Versioning Risk

### Bug 1 fix: PATCH

Expanding Step 4e with more detailed instructions changes no contract. No new config key. No new agent output format. The story back-reference format (`<!-- {TrackerType}: {STORY-ISSUE-ID} -->`) is internal to the scaffold pipeline — it's not parsed by Agent Overrides or external tooling. PATCH.

### Bug 2 fix: Depends on implementation

**If we use the existing "Done" key within State transitions:** PATCH. No new config key, no contract change. We're just reading a value that was always documented but never consumed by scaffold.

**If we add "On complete" as a new config key (as research suggests):** MINOR. New optional key = MINOR per versioning policy. But this is UNNECESSARY — see Section 1 above.

**If we add a sub-issue capabilities table to docs/reference/trackers.md:** Not a version change (docs only), but it's scope creep.

**Recommendation:** Keep this as PATCH by using existing State transitions "Done" mapping. Do NOT introduce "On complete".

---

## 5. What Could Go Wrong With the Fix Itself?

### 5a. Expanded Step 4e overwhelms the LLM

**Risk: MEDIUM.** Step 4e is currently 30 lines (508-537). The research proposes adding:
- Parsing instructions (~10 lines)
- Per-tracker branching logic (~15 lines)
- Sub-issue capabilities table (~10 lines)
- Story back-reference format (~5 lines)
- Fallback strategy for GitHub/Gitea (~10 lines)

That would roughly double the step to ~80 lines. LLMs handling scaffold SKILL.md are already processing a ~800-line document. Adding 50 lines to one step is unlikely to cause confusion IF the instructions are well-structured (numbered, clear conditionals). But if the tracker branching logic uses deeply nested conditionals, the LLM may lose track of which branch it's in.

**Mitigation:** Keep the tracker-specific logic to a single IF/ELSE (supports parent linking vs. doesn't). Don't enumerate per-tracker API parameters inline — that's what the MCP tool signatures are for. The LLM already knows how to call MCP tools; it just needs to know WHAT to ask for (parent link) and WHEN to fall back.

### 5b. Done transition fires prematurely

**Risk: HIGH.** If the Done transition is placed after each batch (as research suggests), an epic could be marked Done after Batch 1 even though Batch 2 hasn't run yet. The epic's subtasks might span multiple batches. The research acknowledges this ("epics whose subtasks all reside in the completed batch") but the implementation would need to track cross-batch dependencies.

**Better approach:** Single Done sweep before Step 9. By that point, all batches have completed (or the pipeline stopped). Check which epics have all subtasks completed. Transition only those. This eliminates the cross-batch timing problem entirely.

The research's "two insertion points" (post-batch + pre-Step 9) adds complexity for marginal benefit (slightly earlier status update). The cost is: duplicate logic, cross-batch state tracking, and risk of marking epics Done prematurely if the post-batch check has a bug in its "all subtasks in this batch" logic.

### 5c. Fallback strategy creates orphan issues on GitHub/Gitea

**Risk: LOW but annoying.** If the fix creates standalone issues with `[{epic_title}]` prefix on GitHub/Gitea, and then the pipeline fails mid-scaffold, those issues remain in the tracker with no implementation. The rollback-agent (which handles git rollback) explicitly does NOT touch tracker state. So you'd have orphan planned issues that never get implemented. This is acceptable for a v1 fix — the user can close them manually — but should be documented as a known limitation.

### 5d. Duplicate issue creation on resume

**Risk: MEDIUM.** If scaffold is interrupted during Step 4e and resumed, the current code would re-iterate all epics and create duplicate issues for epics that were already processed. The fix MUST add idempotency: check if a back-reference comment already exists in the epic file before creating a new issue.

---

## Summary: Recommended Approach

| Item | In Scope | Rationale |
|------|----------|-----------|
| Expand Step 4e.1.c with story parsing + tracker-aware sub-issue creation | YES | Core fix for Bug 1 |
| Expand Step 4e.1.d with explicit story ID writeback | YES | Core fix for Bug 1 |
| Define story back-reference format | YES | Required by writeback |
| Add idempotency guard (skip if back-ref exists) | YES | Resume safety |
| Single IF/ELSE for parent-linking vs. standalone fallback | YES | Minimum tracker awareness |
| Add Step 7e with Done transition using existing State transitions "Done" | YES | Core fix for Bug 2 |
| Single sweep before Step 9 (not post-batch) | YES | Simpler, safer |
| Guard: skip if "Done" not in State transitions | YES | Graceful degradation |
| Guard: only transition if zero blocked features | YES | Prevents premature Done |
| Update example configs to include "Done" mapping | YES | Consistency fix |
| Sub-issue capabilities table in trackers.md | NO | Scope creep, separate ticket |
| State.json persistence of issue IDs | NO | File parsing is sufficient |
| New "On complete" config key | NO | Unnecessary, "Done" already exists |
| Two-point Done insertion (post-batch + pre-Step 9) | NO | Complexity for marginal gain |
| Extensive new test suite | PARTIAL | 2-3 grep tests max, not a test overhaul |

**Version impact:** PATCH (no contract changes if we use existing State transitions "Done" mapping).
