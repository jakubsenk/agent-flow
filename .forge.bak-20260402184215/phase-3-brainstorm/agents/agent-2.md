# Brainstorm Agent 2: INNOVATIVE Perspective

**Lens:** Thoroughness, future-proofing, robust design patterns
**Date:** 2026-04-02

---

## 1. Evaluation of Proposed Approaches

### Bug 1: Sub-issue creation in Step 4e

#### Approach A: Expand Step 4e inline

**Assessment: Necessary foundation, but insufficient alone.**

Approach A solves the immediate bug by adding story-level iteration with `### Story N.M:` parsing, per-tracker sub-issue creation parameters, and a GitHub/Gitea fallback path. It is the minimum viable fix. However, it embeds tracker-specific knowledge (parent parameters, sub-issue API signatures, fallback strategies) directly into the scaffold skill markdown. This creates a maintenance burden: when a 7th tracker is added, the developer must update Step 4e in addition to `docs/reference/trackers.md`. Every skill that needs sub-issue creation in the future must replicate this logic.

**Verdict:** Required as the implementation vehicle, but should delegate tracker specifics elsewhere.

#### Approach B: Separate core contract (core/sub-issue-creator.md)

**Assessment: The architecturally correct choice, but over-engineered for today's scope.**

Extracting sub-issue creation into `core/sub-issue-creator.md` follows the existing pattern (core/config-reader.md, core/mcp-detection.md, core/fixer-reviewer-loop.md). It future-proofs for `implement-feature` decomposition scenarios where architect subtasks could become tracker sub-issues. However, today only one call-site exists (scaffold Step 4e). Creating a core contract for a single consumer adds indirection without immediate benefit. The YAGNI principle applies.

**Verdict:** Defer. Design Step 4e so extraction to core/ is trivial later (clean input/output boundaries, tracker-type branching centralized in one place), but do not create the core file now.

#### Approach C: A + tracker capability table in trackers.md

**Assessment: The sweet spot -- this is the recommended approach.**

This combines Approach A's inline expansion with a new "Sub-Issue Capabilities" table in `docs/reference/trackers.md`. Step 4e references this table (just as Step 0-MCP references the MCP Server Detection table). The tracker-specific knowledge lives in the reference document (single source of truth), while Step 4e contains the iteration logic and fallback branching.

Key advantages over A alone:
- `docs/reference/trackers.md` already serves as the canonical tracker reference -- sub-issue capabilities are a natural extension
- When a new tracker is added, the developer adds one row to the table (established pattern)
- `implement-feature` or any future skill can reference the same table without duplicating knowledge
- Step 4e stays focused on orchestration logic, not tracker API details

**Verdict: RECOMMENDED for Bug 1.**

---

### Bug 2: Tracker issue state transition to "Done"

#### Approach D: Per-subtask close (mark epic Done after its last subtask completes)

**Assessment: Semantically correct but operationally fragile.**

Marking an epic Done immediately after its last constituent subtask passes tests is the earliest possible moment. It provides incremental feedback: if the pipeline crashes mid-run, completed epics are already marked Done. However, it introduces complexity:
- Requires tracking which subtasks belong to which epic (subtask-to-epic mapping)
- Architect batches are cross-epic -- a single batch may contain subtasks from multiple epics, and an epic's subtasks may span multiple batches
- The "is this the last subtask for this epic?" check requires counting completed vs. total subtasks per epic, which means maintaining a running tally
- If spec-compliance check (Step 7b) FAILS after subtasks are marked Done, the state is inaccurate

The incremental advantage is real but the implementation cost is disproportionate. In scaffold, ALL features are implemented in a single pipeline run -- there is no external observer waiting for per-epic status updates between batches.

**Verdict:** Overly complex for the scaffold use case. The incremental benefit does not justify the bookkeeping.

#### Approach E: Batch close (new Step 7e after each batch)

**Assessment: A compromise -- incremental progress with reasonable complexity.**

After each batch's test suite passes, scan the completed subtask list, determine which epics are fully implemented, and mark those Done. This is simpler than D because it operates at batch boundaries (a natural checkpoint) rather than per-subtask. However, it still requires the subtask-to-epic mapping and has the same spec-compliance problem: epics could be marked Done before Step 7b discovers missing acceptance criteria.

There is a more fundamental issue: the scaffold pipeline already has a spec-compliance check (Step 7b) and E2E tests (Step 8). Marking epics Done before these quality gates pass is premature. "Done" should mean "implemented, tested, and verified" -- not "subtasks committed."

**Verdict:** Better than D, but still premature in the pipeline.

#### Approach F: Post-report close (bulk transition before or during Step 9)

**Assessment: The simplest and most correct approach.**

A single bulk transition before Step 9 (Final Report) -- after spec-compliance check (Step 7b), after E2E tests (Step 8) -- means "Done" truly means done. The implementation is straightforward:
1. Read all `spec/epics/*.md` files
2. Extract back-reference comments (`<!-- {TrackerType}: {ID} -->`)
3. For each ID: transition to Done using the State transitions syntax from trackers.md
4. Accumulator pattern: WARN on individual failure, continue to next
5. Display summary: `Transitioned {N}/{M} issues to Done.`

This avoids the subtask-to-epic tracking entirely (we transition epic issues, not story sub-issues). Story sub-issues would inherit the parent's Done status in most trackers (YouTrack, Jira, Linear auto-cascade parent close to children) or remain open for manual triage (GitHub/Gitea standalone issues).

**Key design choice:** Insert as Step 8b (after E2E tests, before Step 9 Final Report). This ensures all quality gates have passed.

**Verdict: RECOMMENDED for Bug 2.**

---

## 2. Cross-Pipeline Tracker Integration Improvement

### Should we improve tracker integration for ALL pipelines, not just scaffold?

**Yes -- but surgically, not as a rewrite.**

The research findings expose a systemic gap: `docs/reference/trackers.md` documents query syntax, state transitions, instance defaults, and MCP detection -- but says NOTHING about issue creation capabilities (sub-issues, issue types, labels, linking). This gap is not scaffold-specific.

**Concrete proposal: Add two new tables to `docs/reference/trackers.md`:**

#### Table 1: Sub-Issue Capabilities

| Tracker | Native Sub-Issues | Create Parameter | Parent ID Source | Fallback Strategy |
|---------|-------------------|-----------------|-----------------|-------------------|
| youtrack | Yes | `parent: {issue-id}` | Issue ID from create response | N/A |
| jira | Yes | `parent: {key}`, `issuetype: "Sub-task"` | Issue key from create response | N/A |
| linear | Yes | `parentId: {id}` | ID from create response | N/A |
| redmine | Yes | `parent_issue_id: {id}` | Issue ID from create response | N/A |
| github | No | N/A | N/A | Standalone issue: `[{parent_title}] {child_title}` + label + cross-ref |
| gitea | No | N/A | N/A | Standalone issue: `[{parent_title}] {child_title}` + label + cross-ref |

#### Table 2: Issue Type Support

| Tracker | Epic type | Story/Task type | Bug type |
|---------|-----------|----------------|----------|
| youtrack | `Type: Epic` (or custom) | `Type: User Story` (or custom) | `Type: Bug` |
| jira | `issuetype: Epic` | `issuetype: Story` | `issuetype: Bug` |
| linear | Label-based | Default issue type | Label: `bug` |
| redmine | Custom tracker | Custom tracker | `tracker_id: {bug_id}` |
| github | Label: `epic` | Default issue | Label: `bug` |
| gitea | Label: `epic` | Default issue | Label: `bug` |

**Why this matters beyond scaffold:**
- `implement-feature` with decomposition creates subtasks. Today, these subtasks are internal to the pipeline (stored in `.claude/decomposition/`). A future enhancement could create tracker sub-issues for each subtask, enabling project managers to track progress externally. The sub-issue capabilities table makes this trivial.
- `fix-bugs` processes multiple issues. If a bug fix spawns follow-up issues (e.g., "also fix the related edge case"), the creation parameters table is needed.
- Any new pipeline or skill that touches the tracker for creation (not just state transitions) benefits.

**Versioning impact:** Adding optional reference tables to `docs/reference/trackers.md` is a PATCH (documentation improvement, no contract change). The tables are informational guidance for LLM agents, not a formal API contract.

---

## 3. Should state.json carry the epic-to-issue mapping?

**Yes -- with a specific, bounded design.**

### The case FOR state.json persistence

Currently, epic tracker IDs live only in `spec/epics/*.md` as inline HTML comments. This has two weaknesses:

1. **Fragility:** If the spec files are modified (e.g., fixer touches a file in spec/ during implementation), the back-reference comment could be accidentally deleted or corrupted. Markdown files are not structured data stores.

2. **Parse overhead:** Every downstream step that needs the mapping must re-read and regex-parse all epic files. This is a repeated operation with no caching.

3. **Incompleteness:** Only epic-level IDs are stored. Story sub-issue IDs are not stored anywhere (the bug we are fixing). If we add story IDs to spec files AND to state.json, we have a reliable structured lookup.

### Proposed state.json extension

Add a new optional field to the schema:

```json
{
  "tracker_issues": {
    "epics": {
      "01-authentication.md": {
        "issue_id": "PROJ-10",
        "title": "Authentication & Authorization",
        "stories": {
          "1.1": { "issue_id": "PROJ-11", "title": "User registration" },
          "1.2": { "issue_id": "PROJ-12", "title": "Login with JWT" }
        },
        "status": "open"
      },
      "02-api-layer.md": {
        "issue_id": "PROJ-13",
        "title": "REST API Layer",
        "stories": {
          "2.1": { "issue_id": "PROJ-14", "title": "CRUD endpoints" }
        },
        "status": "open"
      }
    },
    "created_at": "ISO-8601",
    "total_epics": 2,
    "total_stories": 3,
    "failed_epics": []
  }
}
```

**When written:** Step 4e, after each successful issue creation (incremental -- if pipeline crashes mid-creation, partial state is preserved).

**When read:** Step 8b (the new Done-transition step) reads `tracker_issues.epics` to get all issue IDs for transition. No markdown parsing needed.

**When updated:** Step 8b updates each epic's `status` field to `"done"` after successful transition.

### The case AGAINST (and mitigations)

- **Schema bloat:** The `tracker_issues` object could be large for projects with many epics/stories. Mitigation: it is optional (null for non-scaffold pipelines) and bounded by the Decomposition → Max subtasks limit.
- **Dual source of truth:** Now the mapping exists in both spec files and state.json. Mitigation: spec files are the canonical source (human-readable, version-controlled). state.json is a cache for pipeline use. Document this clearly. On resume, if state.json has the mapping, use it; if not, fall back to parsing spec files.
- **Versioning:** Adding an optional field to state.json is a PATCH (no existing consumer reads this field).

**Verdict: RECOMMENDED.** The structured lookup significantly simplifies the Done-transition step and enables future features (e.g., `/status` showing per-epic progress, `/dashboard` showing tracker issue status).

---

## 4. Should we add `State transitions -> On complete` to Automation Config?

**Not as a new key. Instead, use the existing Done transition from `docs/reference/trackers.md`.**

### Analysis

The research synthesis (RQ-3) already documents that `docs/reference/trackers.md` has a "Done" example in the State Transition Syntax table. The issue is not that the transition syntax is unknown -- it is that NO pipeline step invokes it.

Adding an explicit `On complete` key to Automation Config has these implications:

1. **It is a new optional key in a required section (Issue Tracker).** Per versioning policy, adding an optional key to a required section is MINOR (new backward-compatible feature). This is acceptable.

2. **However, "Done" is already implicitly defined.** The State Transition Syntax table in `docs/reference/trackers.md` already has a "Done" column. Every tracker has a known Done syntax. A separate `On complete` key creates redundancy -- what if the user sets `On complete: State: Fixed` but the trackers.md table says `State: Done`? Which wins?

3. **The real gap is operational, not configurational.** No pipeline step transitions to Done. Adding the step (Bug 2 fix) is the actual fix. The transition syntax is known and documented.

### Counter-argument: customization

Some teams use `State: Fixed` or `State: Deployed` instead of `State: Done`. An `On complete` key allows this customization. This is a valid use case.

### Recommended approach: Phased

**Phase 1 (this fix):** Use a hardcoded Done transition derived from `docs/reference/trackers.md` State Transition Syntax table (the "Example: Done" column). If the transition fails (e.g., the state name does not match the tracker's configuration), WARN and continue. This is the scaffold-specific fix.

**Phase 2 (future MINOR version):** Add optional `On complete` key to the `State transitions` sub-table in Issue Tracker config. When present, it overrides the hardcoded Done transition. When absent, fall back to the trackers.md default. This gives teams customization without requiring it.

**Why phased?** Phase 1 fixes the bug with zero config contract changes (PATCH). Phase 2 is a deliberate MINOR feature that can be designed holistically for all pipelines (fix-ticket publisher already sets "For Review" -- should it also have an "On complete" that fires after PR merge + verify?).

**Verdict:** Do NOT add `On complete` in this fix. Document it as a follow-up for the roadmap. The Done transition syntax from trackers.md is sufficient for Phase 1.

---

## 5. Synthesis: Recommended Combination

**Bug 1:** Approach C (expand Step 4e + sub-issue capabilities table in trackers.md)
**Bug 2:** Approach F (new Step 8b: bulk transition to Done after E2E tests, before Final Report)
**State.json:** Yes, add `tracker_issues` mapping at Step 4e, read at Step 8b
**On complete key:** No for this fix. Add to roadmap as future MINOR.

### Implementation sketch

#### trackers.md additions
- New section: `## Sub-Issue Capabilities` with the 6-tracker table (native support, create parameter, fallback strategy)
- Optional: `## Issue Type Support` table (lower priority, not blocking)

#### Step 4e expansion (scaffold SKILL.md)
Current Step 4e says "For each user story within the epic: create a sub-issue under the epic issue" in a single line (523c). Expand to:

1. **Epic iteration** (existing, working):
   - Create epic issue
   - Write back epic ID as `<!-- {TrackerType}: {EPIC-ID} -->`
   - Store in `tracker_issues.epics[filename].issue_id` in state.json

2. **Story iteration** (NEW -- the bug fix):
   - Parse epic file: split on `\n---\n`, match `### Story N.M:` blocks
   - For each story block:
     - Extract title: text after `### Story N.M: `
     - Extract description: from user-story sentence to next `---`
     - **If tracker supports native sub-issues** (reference Sub-Issue Capabilities table):
       - Create sub-issue with parent parameter set to epic issue ID
     - **If tracker does NOT support native sub-issues** (GitHub/Gitea):
       - Create standalone issue with title: `[{epic_title}] {story_title}`
       - Apply a label matching the epic name (e.g., `epic:authentication`)
       - Add cross-reference link in both the epic issue body and the story issue description
     - Write back story ID as `<!-- {TrackerType}: {STORY-ID} -->` immediately after the `### Story N.M:` heading
     - Store in `tracker_issues.epics[filename].stories[N.M]` in state.json

3. **Partial failure handling** (per-story level, not just per-epic):
   - On individual story failure: WARN, continue to next story
   - Epic is considered "succeeded" if the epic-level issue was created (even if some stories failed)
   - Display: `Created {N}/{M} tracker issues ({S} stories, {F} story failures).`

#### New Step 8b: Transition Issues to Done (scaffold SKILL.md)

Insert between Step 8 (E2E Tests) and Step 9 (Final Report):

```
### Step 8b: Close Tracker Issues

**Guard clause -- skip this step if ANY of:**
- `tracker_effective_status` is NOT `"ready"`
- `tracker_write_available` is `false`
- No tracker issues were created at Step 4e (check `tracker_issues` in state.json or absence of back-reference comments in spec/epics/*.md)

**Determine Done transition syntax:**
Read the tracker type from `tracker_type` in-memory variable.
Look up the Done transition from `docs/reference/trackers.md` State Transition Syntax table "Example: Done" column.

**Transition logic:**
1. Read epic issue IDs from state.json `tracker_issues.epics` (preferred) or fall back to parsing `spec/epics/*.md` back-reference comments.
2. For each epic with a valid issue ID:
   a. Transition the issue to Done using the tracker-appropriate syntax.
   b. On success: update `tracker_issues.epics[filename].status` to `"done"` in state.json.
   c. On failure: WARN (`Could not transition {issue_id} to Done: {error}`), continue.
3. Display: `Transitioned {N}/{M} tracker issues to Done.`
4. If N < M: `Some issues could not be transitioned. Check manually.`

**Note on story sub-issues:**
- For trackers with native sub-issues (YouTrack, Jira, Linear, Redmine): closing the parent epic typically cascades to children. Do NOT explicitly close story sub-issues.
- For GitHub/Gitea (standalone issues): explicitly close each story issue as well. Read story IDs from state.json `tracker_issues.epics[filename].stories`.
```

#### state/schema.md addition

Add `tracker_issues` as an optional top-level field (parallel to `infrastructure`, `deployment`):

```
| `tracker_issues` | object or null | No | `null` | Tracker issue mapping from scaffold Step 4e. Maps epic filenames to issue IDs and nested story IDs. Only populated by scaffold pipeline. |
```

#### Versioning assessment

- Sub-issue capabilities table in trackers.md: documentation improvement (PATCH)
- Step 4e expansion: behavior fix -- stories were supposed to be created but were not (PATCH)
- New Step 8b: behavior fix -- issues were supposed to be transitioned but were not (PATCH)
- `tracker_issues` in state.json schema: optional field addition (PATCH -- no consumer reads it yet)
- **Overall: PATCH version bump.**

---

## 6. Additional Innovative Considerations

### 6a. Idempotency for resume

If the scaffold pipeline is interrupted after Step 4e (issues created) but before Step 8b (issues transitioned), resuming should NOT re-create issues. The `tracker_issues` mapping in state.json enables this: on resume, Step 4e checks if `tracker_issues.epics[filename].issue_id` already exists and skips creation for that epic. This is a natural consequence of the state.json design and should be documented in Step 4e.

### 6b. /status integration

The `/ceos-agents:status` skill could read `tracker_issues` from state.json to display per-epic progress:

```
Epic 01-authentication: PROJ-10 [Done] (3/3 stories)
Epic 02-api-layer:      PROJ-13 [Open] (1/2 stories, 1 failed)
```

This is a future enhancement, not part of this fix, but the state.json design enables it for free.

### 6c. Test coverage

New grep-based tests for `tests/harness/scenarios/`:
1. Step 4e references Sub-Issue Capabilities or mentions sub-issue creation with per-story parsing
2. Step 4e includes GitHub/Gitea fallback (standalone issue + naming convention)
3. Step 4e specifies story back-reference writeback format
4. Step 8b exists and references Done transition
5. Step 8b has the guard clause (skip if tracker not ready)
6. `docs/reference/trackers.md` contains Sub-Issue Capabilities section

### 6d. Why NOT a core contract now

I considered whether `core/tracker-issue-manager.md` (combining creation + transition) would be better. It would encapsulate:
- Issue creation (epic + story)
- Sub-issue creation with per-tracker branching
- State transitions (Done, Blocked, For Review)
- Back-reference writeback

This is the right long-term architecture. But today, issue creation only happens in scaffold Step 4e, and state transitions happen in publisher (For Review), block-handler (Blocked), and the new Step 8b (Done). These are different enough in context and error handling that a unified core contract would be forced and awkward. Wait until there are 3+ consumers with shared logic, then extract.
