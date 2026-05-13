# Agent 1: Conservative Evaluation

**Perspective:** Minimal changes, proven patterns, backward compatibility.

---

## Bug 1: Step 4e Does Not Create Story Sub-Issues

### Current State

Step 4e (lines 508-538 of SKILL.md) already contains line 523: "c. For each user story within the epic: create a sub-issue under the epic issue." The instruction exists but is a single vague line buried in a lettered sub-step. It gives the LLM no guidance on:

1. How to parse stories from the epic markdown (the `### Story N.M:` / `---` delimiter structure)
2. How to handle trackers that lack native sub-issues (GitHub, Gitea)
3. Where to write back story-level tracker IDs
4. What constitutes success vs. failure for a single story creation

The result: the executing LLM lumps story text into the epic description and moves on. The instruction is technically present but practically unexecutable.

### Approach A: Expand Step 4e Inline

**Correctness:** Yes, if the expansion is detailed enough. The fix adds parsing instructions, per-story iteration, back-reference writeback, and failure handling directly into Step 4e's numbered list.

**Consistency:** Strong. Every other step in SKILL.md follows the same pattern: numbered steps with lettered sub-steps, inline detail, no external contract files for step-specific logic. Step 4d (Push to Remote) is 20 lines of inline detail. Step 7's fixer/reviewer/test-engineer sub-steps are all inline. Expanding Step 4e to a similar level of detail is exactly what the codebase does everywhere else.

**Robustness:** Depends on implementation. If the inline expansion covers: (a) story parsing with `---` delimiters, (b) individual story failure as WARN+continue (matching the existing epic-level accumulator), (c) back-reference writeback per story, (d) partial commit including story-level links, then robustness is good.

**Maintainability:** Moderate. Step 4e grows from ~30 lines to perhaps ~60 lines. This is within the range of other steps (Step 7 is 65 lines). No new files, no new indirection.

**Conservative verdict: PREFERRED for Bug 1.** It follows the existing pattern exactly and avoids new abstractions.

### Approach B: Separate `core/sub-issue-creation.md` Contract

**Correctness:** Yes, if the contract is complete.

**Consistency:** Weak. The 11 existing core contracts are all reusable cross-skill patterns: `block-handler.md`, `fixer-reviewer-loop.md`, `state-manager.md`, `config-reader.md`, etc. Sub-issue creation is used in exactly ONE place (scaffold Step 4e). No other skill creates sub-issues. Extracting a single-use pattern into a core contract is premature abstraction. The core directory's purpose is shared contracts, not step-specific logic.

**Robustness:** Adds indirection. The executing LLM must now follow a reference from SKILL.md into a separate file, which increases the chance of losing context or misinterpreting the contract boundaries.

**Maintainability:** Worse. A new file that only one step references. Future readers must cross-reference two files to understand Step 4e. If `implement-feature` later needs sub-issue creation, extraction would be justified at that point — not now.

**Conservative verdict: REJECTED.** Premature abstraction. One consumer does not justify a core contract.

### Approach C: Approach A + Per-Tracker Sub-Issue Table

**Correctness:** Yes, and more thorough than A alone for multi-tracker support.

**Consistency:** Mixed. The per-tracker table adds documentation-style content into a procedural skill file. Existing steps reference `docs/reference/trackers.md` for tracker-specific details (e.g., Step 0-INFRA references "format example from docs/reference/trackers.md"). Adding a tracker capabilities table inside SKILL.md would break this separation.

**Robustness:** Better than A for non-YouTrack trackers. But the research found that MCP tool signatures for sub-issues are undocumented (RQ-2 critical gap). A table in SKILL.md cannot fix the underlying MCP documentation gap — the LLM still has to guess tool parameters at runtime.

**Maintainability:** Worse than A. The tracker capabilities table must be kept in sync with `docs/reference/trackers.md`. Two sources of truth for tracker capabilities is a maintenance trap.

**Conservative verdict: PARTIALLY ACCEPTED.** The inline expansion (A) should include a brief branching instruction for trackers without native sub-issues (GitHub/Gitea fallback), but the full per-tracker table belongs in `docs/reference/trackers.md`, not in SKILL.md. Reference it, don't duplicate it.

### Bug 1 Recommendation: Approach A with a Minimal Fallback Branch

Expand Step 4e inline with:
- Story parsing instructions (split on `---`, match `### Story N.M:`)
- Per-story sub-issue creation with parent link (for YouTrack/Jira/Linear/Redmine)
- Fallback branch for GitHub/Gitea (standalone issue with `[{epic_title}]` prefix + cross-reference)
- Per-story back-reference writeback (`<!-- {TrackerType}: {STORY-ID} -->` after `### Story N.M:`)
- Per-story failure as WARN+continue (extends existing accumulator)
- Updated commit message to include story links

Do NOT create a new core contract. Do NOT embed a tracker capabilities table — add a one-line reference to `docs/reference/trackers.md` if needed, and update that file separately.

---

## Bug 2: Tracker Issues Not Transitioned to Done After Implementation

### Current State

Step 7 implements features and commits directly (no PRs). Step 9 (Final Report) displays completion status. Neither step transitions tracker issues to "Done". The publisher agent (used in `implement-feature` and `fix-ticket`) sets "For Review" because those pipelines create PRs. Scaffold doesn't use publisher because it commits directly — so there is no state transition at all.

"Done" already exists as a documented key in `State transitions` across all tracker examples in `docs/reference/automation-config.md`.

### Approach D: Close Per-Subtask Inline in Step 7d

**Correctness:** Partially. Subtasks map to architect decomposition items, not directly to tracker issues. Tracker issues are created per-epic (and per-story with Bug 1 fix). The mapping is: subtask -> story -> epic tracker issue. Closing at the subtask level requires knowing which tracker issue(s) correspond to which subtask, which is indirect (subtask -> maps_to AC -> story -> tracker issue). This is complex and fragile.

**Consistency:** Weak. Step 7d commits code. Adding tracker state transitions into a git commit step mixes concerns. No other step in SKILL.md mixes git operations with tracker state management.

**Robustness:** Poor. If a subtask is one of several implementing the same story/epic, closing the tracker issue after the first subtask would be premature. Requires tracking which subtask is the "last" one for each tracker issue — significant new complexity.

**Maintainability:** Poor. The mapping logic (subtask -> tracker issue) is non-trivial and error-prone.

**Conservative verdict: REJECTED.** Wrong granularity. Premature closing. Mixes concerns.

### Approach E: Batch Close After Implementation Loop (New Step 7e)

**Correctness:** Partially. "After implementation loop" means after Step 7 completes all batches. At this point, all implemented features are committed. However, Step 7b (Spec Compliance Check) and Step 8 (E2E Tests) haven't run yet. Closing issues before validation passes is premature — what if spec compliance fails and features need rework? The research recommendation for batch-level closing (close epics whose subtasks are all in the completed batch) has a similar problem: post-batch test suites only verify build/test, not spec compliance.

**Consistency:** Moderate. Adding a step between Step 7 and Step 7b follows the existing numbered-step pattern. But it creates an awkward numbering situation (7e between 7 and 7b).

**Robustness:** Risk of closing issues that subsequently fail spec compliance or E2E. Recovery would require re-opening issues — a pattern that exists nowhere in the codebase.

**Maintainability:** Moderate. A new step with clear scope.

**Conservative verdict: REJECTED.** Closing before validation is premature. The existing pipeline validates AFTER implementation (Step 7b spec compliance, Step 8 E2E). Issues should only be marked Done after all validation passes.

### Approach F: Close After Step 9 (Final Report)

**Correctness:** Almost. Step 9 is the very end. By this point, all implementation, spec compliance, E2E tests, and reporting are complete. However, closing AFTER the report means the report would not reflect the "Done" transitions. A better placement is just BEFORE Step 9 (or as the first action within Step 9).

**Consistency:** Strong. The Final Report step already reads tracker state variables (`tracker_effective_status`, `tracker_type`, etc.). Adding tracker issue closure as a pre-report step keeps all "finalization" activities grouped. This mirrors how `implement-feature` uses publisher as its final active step before completion.

**Robustness:** Best of the three options. All validation has passed. Only successfully implemented features get marked Done. Blocked features (already reported in Step 7 block handler) are naturally excluded. The guard clause pattern ("skip if tracker_effective_status is not ready") is already established in Step 4e and can be reused exactly.

**Maintainability:** Low complexity. One new sub-section with a clear trigger condition and established patterns.

**Conservative verdict: PREFERRED, with minor adjustment.** Place the transition step as "Step 8b" or as the opening section of Step 9, rather than a completely separate step after Step 9.

### Bug 2 Recommendation: New Step Between Step 8 and Step 9

Add a new "Step 8b: Close Tracker Issues" (or fold into Step 9 as its first action) that:
1. Guard clause: skip if `tracker_effective_status` is not `"ready"` or `tracker_write_available` is `false`
2. Read `spec/epics/*.md` to extract epic-level tracker IDs from back-reference comments
3. Read story-level tracker IDs (after Bug 1 fix adds them)
4. For each epic where ALL subtasks completed (not blocked): transition the epic issue + its story sub-issues to "Done" using `State transitions -> Done` from Automation Config
5. If `State transitions -> Done` is not configured: log `WARN: No 'Done' state transition configured. Skipping issue closure.` and skip
6. Per-issue failure: WARN + continue (matching Step 4e's accumulator pattern)
7. Display: `Closed {N}/{M} tracker issues.`

This is the most conservative option because:
- All validation has already passed (spec compliance, E2E)
- Only genuinely completed work gets closed
- No risk of premature closure
- Reuses the exact guard clause and accumulator patterns from Step 4e
- "Done" is already a documented State transitions key (no config contract change)
- Does not require re-opening logic (no new failure recovery pattern)

---

## Combined Recommendation

| Bug | Approach | Rationale |
|-----|----------|-----------|
| Bug 1 | **A (inline expansion) + minimal GitHub/Gitea fallback** | Follows existing inline pattern. No new files. No premature abstraction. |
| Bug 2 | **F (close before Final Report) as Step 8b** | All validation passed. Reuses existing patterns. No premature closure risk. |

### What NOT to Do

1. **Do not create `core/sub-issue-creation.md`** — single-use patterns do not belong in core.
2. **Do not embed a tracker capabilities table in SKILL.md** — that belongs in `docs/reference/trackers.md`.
3. **Do not close issues per-subtask (D)** — wrong granularity, mixes concerns.
4. **Do not close issues before spec compliance and E2E (E)** — premature, would require re-open logic.
5. **Do not add a new "Done" key to Automation Config** — it already exists in all documented examples. No config contract change needed.
6. **Do not persist story tracker IDs in state.json** — the back-reference comments in `spec/epics/*.md` are the canonical store (matching existing epic ID pattern). Adding a second store introduces synchronization risk.

### Estimated Change Size

- **SKILL.md Step 4e:** expand from ~30 lines to ~60 lines (story parsing, sub-issue creation detail, fallback branch, back-reference writeback)
- **SKILL.md new Step 8b:** ~25 lines (guard clause, read back-references, transition loop, accumulator, display)
- **SKILL.md Step 9:** ~2 lines (add closed-issues count to Final Report display)
- **docs/reference/trackers.md:** ~10 lines (add sub-issue capabilities section — optional, separable)
- **tests/:** extend `scaffold-v2-happy-path.sh` with 4-6 grep assertions for new content

Total: ~100 lines changed, 0 new files in the plugin core, 0 config contract changes. This is the minimum viable fix for both bugs.
