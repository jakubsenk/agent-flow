# Phase 3 Brainstorm: Judge Synthesis

**Date:** 2026-04-02
**Input:** Conservative (Agent 1), Innovative (Agent 2), Skeptical (Agent 3)
**Research basis:** Phase 1 final synthesis (5 RQs)

---

## 1. Consensus Points

All three agents agree on:

1. **Bug 1 root cause is multi-factorial.** Step 4e line 523 says "create a sub-issue" but provides no parsing instructions, no tracker-specific parameters, and no explicit story ID writeback. The instruction is technically present but practically unexecutable by the LLM.

2. **Inline expansion of Step 4e is the right vehicle.** All three support expanding Step 4e directly rather than creating a new core contract file. A `core/sub-issue-creator.md` is premature abstraction with exactly one consumer.

3. **Story back-reference format:** `<!-- {TrackerType}: {STORY-ISSUE-ID} -->` immediately after the `### Story N.M:` heading, mirroring the existing epic-level pattern.

4. **GitHub/Gitea need a fallback branch.** A simple IF/ELSE on tracker type (supports parent linking vs. does not) with a standalone-issue fallback using `[{epic_title}] {story_title}` naming.

5. **Bug 2: "Done" already exists in State transitions.** No new "On complete" config key is needed. Read the existing `State transitions -> Done` mapping. If absent, WARN and skip. This keeps the fix as a PATCH.

6. **Bug 2: Single sweep, not per-batch.** All three reject Approach D (per-subtask close). Agent 1 and Agent 3 reject Approach E (per-batch close) as premature -- closing before spec compliance (Step 7b) and E2E (Step 8) is unsafe. All converge on a single bulk transition after all quality gates pass.

7. **No new "On complete" config key.** All three agents agree this is unnecessary for the current fix. Future roadmap item at best.

8. **PATCH version.** No config contract change, no new required key, no new agent output format. All three agents classify this as PATCH.

---

## 2. Key Disagreements + Resolution

### Disagreement A: Sub-Issue Capabilities Table in trackers.md

| Agent | Position |
|-------|----------|
| Conservative | Do NOT embed table in SKILL.md. Add a one-line reference to trackers.md. Update trackers.md separately (optional, separable). |
| Innovative | YES, add a full Sub-Issue Capabilities table (6 rows) to trackers.md. Step 4e references it. Also consider an Issue Type Support table. |
| Skeptical | NO. Out of scope. Separate ticket. |

**Ruling: IN SCOPE, but minimal.** Add a Sub-Issue Capabilities table to `docs/reference/trackers.md` (6 rows: tracker, native sub-issues yes/no, parent parameter, fallback strategy). Step 4e references this table. Rationale: the Skeptical agent correctly identifies scope creep risk, but without this table the LLM must guess MCP tool parameters -- which is the exact reliability gap that caused Bug 1 in the first place. The table is small (10 lines), lives in the canonical tracker reference doc, and directly enables the fix. The Issue Type Support table (Agent 2's second table) is OUT of scope.

### Disagreement B: state.json Persistence of Issue IDs

| Agent | Position |
|-------|----------|
| Conservative | NO. Back-reference comments in spec/epics/*.md are sufficient. Adding state.json creates dual source of truth. |
| Innovative | YES. Add `tracker_issues` object to state.json. Enables structured lookup, resume safety, /status integration. |
| Skeptical | NO. File parsing works. Not required for the fix. |

**Ruling: OUT OF SCOPE.** The Conservative and Skeptical agents are right. The back-reference comments in spec/epics/*.md are the canonical store, are committed to git (survive crashes), and are already the established pattern for epic IDs. Adding a parallel store in state.json introduces synchronization risk and schema bloat for a marginal parsing convenience. The Done-transition step can parse spec files directly -- this is a one-time read of a small number of files. state.json persistence is a valid future enhancement but does not belong in this PATCH.

### Disagreement C: Exact Insertion Point for Done Transition

| Agent | Position |
|-------|----------|
| Conservative | Step 8b (between E2E tests and Final Report) |
| Innovative | Step 8b (same position, same rationale) |
| Skeptical | Step 7e (within the implementation section, but after all batches) OR fold into Step 9 opening |

**Ruling: New Step 8b.** Position: after Step 8 (E2E Tests), before Step 9 (Final Report). This is where all three effectively converge once the Skeptical agent's "after all batches" is rejected (it is before spec compliance and E2E). Using "Step 8b" follows the existing sub-step naming convention (cf. Step 7b: Spec Compliance Check). The Final Report (Step 9) then reflects the transition results.

### Disagreement D: Partial Implementation Guard for Done Transition

| Agent | Position |
|-------|----------|
| Conservative | Only transition epics where ALL subtasks completed (not blocked). |
| Innovative | Same, but with per-epic granularity via state.json lookup. |
| Skeptical | Only transition if ZERO features blocked across entire pipeline. Otherwise skip all. |

**Ruling: Per-epic granularity, no state.json required.** The Skeptical agent's "all-or-nothing" approach is too conservative -- if 9 out of 10 epics are fully implemented and 1 has a blocked story, the 9 completed epics should be transitioned. The per-epic check works as follows: read the Final Report's blocked features list (already computed by Step 7's block handler). For each epic, check if any of its subtasks appear in the blocked list. If none are blocked, transition that epic to Done. If any are blocked, skip that epic. This requires no state.json -- the blocked list and the epic-to-subtask mapping (from architect output, still in memory/context) are already available.

### Disagreement E: Update Example Configs to Include "Done"

| Agent | Position |
|-------|----------|
| Conservative | Not mentioned. |
| Innovative | Not mentioned. |
| Skeptical | YES -- 5 of 7 example configs lack "Done" mapping. Update them for consistency. |

**Ruling: IN SCOPE.** The Skeptical agent is right. If the new Step 8b reads `State transitions -> Done` and most example configs omit it, users following examples will hit the WARN/skip path silently. Adding `Done: {value}` to example configs is a one-line change per file and prevents confusion. This is a documentation consistency fix, not a contract change.

### Disagreement F: Idempotency Guard for Resume

| Agent | Position |
|-------|----------|
| Conservative | Not explicitly addressed. |
| Innovative | YES -- check if back-reference exists before creating duplicate issue. |
| Skeptical | YES -- explicitly called out as risk 3c. |

**Ruling: IN SCOPE.** Add an idempotency guard to Step 4e: "If epic file already contains a tracker back-reference comment (`<!-- {TrackerType}: ... -->`), skip creating a duplicate issue for that epic. Same for story-level: if story heading already has a back-reference, skip." This is a two-line addition that prevents real bugs on resume. Worth including.

---

## 3. Final Recommendation

### Bug 1: Story Sub-Issues (Step 4e Expansion)

Expand Step 4e sub-step 1 with the following changes:

**Step 4e.1 (revised iteration):**

a. **(Existing, unchanged)** Create epic-level issue. Do NOT apply `On start set`.

b. **(NEW: Idempotency guard)** Before creating an epic issue, check if the epic file already contains a `<!-- {TrackerType}: ... -->` back-reference comment. If yes, skip creation for this epic (already linked from a previous run). Extract the existing issue ID for use as parent ID in story creation.

c. **(EXPANDED from single line to full sub-procedure)** Parse stories from the epic markdown file:
   - Split content on `\n---\n` delimiter
   - Identify story blocks by matching `### Story N.M:` headings
   - For each story block:
     - Extract title: text after `### Story N.M: `
     - Extract description: content from user-story sentence to next `---`
     - **If story heading already has a back-reference comment: skip (idempotency)**
     - **If tracker supports native sub-issues** (YouTrack, Jira, Linear, Redmine -- see Sub-Issue Capabilities in `docs/reference/trackers.md`): create sub-issue with parent set to epic issue ID
     - **If tracker does NOT support native sub-issues** (GitHub, Gitea): create standalone issue with title `[{epic_title}] {story_title}`, add cross-reference to epic issue in description
     - Write story issue ID back as `<!-- {TrackerType}: {STORY-ISSUE-ID} -->` immediately after the `### Story N.M:` heading
   - If epic has zero stories: skip story iteration (epic-only issue is sufficient)

d. **(EXPANDED)** Write back the epic issue ID as `<!-- {TrackerType}: {EPIC-ISSUE-ID} -->` after the `# Epic NN:` heading (existing behavior). The commit in sub-step 2 captures BOTH epic and story back-references.

e. **(Existing, unchanged)** Track the result: success or failure for this epic.

**Step 4e.2 (partial failure -- updated):**
- On individual **story** failure: WARN, continue to next story. The epic is considered succeeded if the epic-level issue was created.
- On individual **epic** failure: WARN, continue to next epic (existing behavior).
- Display updated: `Created {N}/{M} tracker issues ({S} stories, {F} story failures).`

**Tracker-specific branching:** Keep it to a single IF/ELSE in Step 4e (supports parent linking vs. does not). Do NOT enumerate per-tracker API parameters inline -- that is the MCP tool's job. Step 4e references `docs/reference/trackers.md` Sub-Issue Capabilities table for the tracker-specific details.

**Story back-reference format:** `<!-- {TrackerType}: {STORY-ISSUE-ID} -->` on the line immediately following `### Story N.M: Title`. Identical structure to epic back-references.

**docs/reference/trackers.md update:** YES, add a Sub-Issue Capabilities section with a 6-row table (YouTrack, Jira, Linear, Redmine, GitHub, Gitea) covering: native sub-issue support, parent parameter name, and fallback strategy. This is in scope because it directly enables the fix.

### Bug 2: Done Transition (New Step 8b)

**Position:** After Step 8 (E2E Tests), before Step 9 (Final Report). Named "Step 8b: Close Tracker Issues".

**Content:**

```
### Step 8b: Close Tracker Issues

**Guard clause -- skip this step if ANY of:**
- `tracker_effective_status` is NOT `"ready"`
- `tracker_write_available` is `false`
- No tracker issues were created at Step 4e (no back-reference comments found in spec/epics/*.md)
- `State transitions` value from Automation Config does not contain a `Done` mapping

If guard triggers for missing Done mapping: display `WARN: State transitions does not include a 'Done' mapping. Skipping issue closure.`

**Transition logic:**
1. Read all `spec/epics/*.md` files. Extract epic issue IDs from back-reference comments (`<!-- {TrackerType}: {ID} -->`).
2. Determine which epics are fully completed: an epic is complete if NONE of its subtasks (from architect decomposition) appear in the blocked features list.
3. For each fully-completed epic:
   a. Transition the epic issue to Done using `State transitions -> Done` syntax from Automation Config.
   b. For GitHub/Gitea (standalone story issues): also close each story issue. Read story IDs from back-reference comments within the epic file.
   c. For trackers with native sub-issues (YouTrack, Jira, Linear, Redmine): closing the parent epic typically cascades to children. Do NOT explicitly close story sub-issues.
   d. On failure: WARN (`Could not transition {issue_id} to Done: {error}`), continue to next.
4. For epics with blocked subtasks: skip. These remain open for manual triage.
5. Display: `Transitioned {N}/{M} tracker issues to Done. {skipped} skipped (blocked subtasks).`
```

**How to retrieve tracker issue IDs:** Parse `spec/epics/*.md` back-reference comments. No state.json lookup. This is a small number of files (bounded by epic count, typically under 10).

**Partial completion handling:** Per-epic granularity. An epic transitions to Done only if ALL its subtasks completed without blocks. Epics with any blocked subtask remain open.

**Example config updates:** Add `Done: {appropriate_value}` to the `State transitions` row in all example configs under `examples/configs/` that currently lack it. Values: `Done` for YouTrack, `close` for GitHub/Gitea, `transition:Done` for Jira, `state:Done` for Linear, `status:Closed` for Redmine.

---

## 4. Scope Boundary

### IN SCOPE (this PATCH)

| Item | Files Affected |
|------|---------------|
| Expand Step 4e with story parsing, per-story sub-issue creation, tracker branching (IF/ELSE), idempotency guard, story back-reference writeback, updated display message | `skills/scaffold/SKILL.md` |
| New Step 8b: Close Tracker Issues (guard clauses, per-epic transition, partial completion handling) | `skills/scaffold/SKILL.md` |
| Update Step 9 Final Report to include closed-issues count | `skills/scaffold/SKILL.md` |
| Add Sub-Issue Capabilities table (6 rows) to trackers.md | `docs/reference/trackers.md` |
| Add "Done" mapping to example configs that lack it | `examples/configs/*.md` |
| Add grep-based test assertions for new content | `tests/harness/scenarios/scaffold-v2-happy-path.sh` |

### OUT OF SCOPE (future work)

| Item | Rationale |
|------|-----------|
| `core/sub-issue-creator.md` contract | Single consumer. Extract when 2+ consumers exist. |
| `tracker_issues` object in state.json | File parsing sufficient. Future enhancement for /status integration. |
| Issue Type Support table in trackers.md | Not needed for this fix. Separate ticket. |
| `On complete` config key in Automation Config | "Done" already in State transitions. Future MINOR if customization needed. |
| Per-batch Done transition (two insertion points) | Complexity for marginal gain. Single sweep is sufficient. |
| Orphan issue cleanup on pipeline failure | Acceptable known limitation. Document if needed. |
| /status integration with tracker issue progress | Requires state.json persistence (out of scope). |

---

## 5. Versioning Decision

**PATCH.**

Justification per CLAUDE.md versioning policy:

- **No new required key in Automation Config.** "Done" is already a documented value within the existing `State transitions` key. We are reading a value that was always part of the contract but never consumed by scaffold.
- **No new optional section in Automation Config.** No "On complete" key added.
- **No new agent.** No new skill.
- **No breaking change in agent output format.** The story back-reference format (`<!-- {TrackerType}: {ID} -->`) is internal to the scaffold pipeline, not parsed by Agent Overrides or external tooling.
- **Behavior fix without contract change.** Step 4e's sub-issue instruction was always there but unexecutable. Step 8b reads an existing config value. Both are fixes to make existing documented behavior actually work.
- **docs/reference/trackers.md table addition** is documentation improvement, not a contract change.

This is squarely PATCH: "Behavior fix without contract change."

---

## 6. Divergence Assessment

```json
{
  "divergence_class": "REFINED",
  "original_keywords": ["scaffold", "sub-issue", "YouTrack", "Done", "Step 4e", "Step 7e"],
  "recommended_keywords": ["scaffold", "sub-issue", "story-parsing", "tracker-branching", "Done", "Step 4e", "Step 8b", "idempotency", "back-reference", "trackers.md", "example-configs"],
  "keyword_overlap_score": 0.55
}
```

**Rationale for REFINED:** The core problem statement (sub-issues not created, Done not set) is preserved from the original. The recommended solution refines the approach in three ways: (1) Step 7e moved to Step 8b (after all quality gates, not mid-implementation), (2) idempotency guards and per-epic partial completion handling added as essential safety mechanisms discovered during brainstorming, (3) trackers.md Sub-Issue Capabilities table added as a minimal-but-necessary enabler. The solution is more precise than the original framing but does not pivot to a different problem space.
