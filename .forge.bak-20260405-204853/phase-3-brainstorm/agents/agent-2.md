# Agent 2 Brainstorm — The Innovator

Perspective: Developer experience, forward-thinking design, opportunities to improve the overall architecture.

---

## Area 1: Step Placement

### Recommended Approach: Merge Into Decomposition Decision Step

The research concluded with a separate step (5a / 4b-tracker / 3b-tracker) inserted "between decision and loop." I challenge this. The tracker creation is logically part of the decomposition decision — it is the *materialization* of the approved plan. Splitting it into a separate step creates artificial seams and makes the pipeline more complex without benefit.

**Proposal:** Extend the existing decomposition decision step to include a "materialize" phase at its tail end, after plan approval and YAML save but before the execution loop begins. The step sequence would be:

```
Step 5 (implement-feature) — Decomposition Decision:
  5.1: Evaluate heuristics → DECOMPOSE / SINGLE_PASS
  5.2: Run architect → produce task tree
  5.3: Validate task tree (cycles, max subtasks, AC coverage)
  5.4: Display plan + user approval
  5.5: Save task tree to YAML
  5.6: [NEW] Materialize tracker sub-issues (if enabled + tracker ready)
  5.7: Commit YAML (with tracker_issue_id fields populated)
```

This is cleaner than creating a standalone step 5a because:
1. The guard conditions are already evaluated in step 5 (decomposition.decision == "DECOMPOSE", tracker_effective_status)
2. The YAML is already being written and committed in step 5 — adding tracker_issue_id to it is a natural extension
3. Resume behavior for DECOMPOSE_PARTIAL already reads the YAML — no new checkpoint type needed
4. Step numbering stays stable (no 5a / 4b-tracker / 3b-tracker naming chaos across three skills)

The risk: step 5 / 4b / 3b becomes longer. But these steps are already substantial (heuristics + architect + validation + display + save). Adding one more phase to a cohesive "plan the decomposition" step is more natural than an orphan "create tracker issues" step floating between plan and execute.

**Alternative considered and rejected:** Embedding tracker creation *inside* the execution loop (lazy/JIT creation per subtask as each starts). This was RQ-1's other option. I agree with the research: upfront is better for visibility, but I propose absorbing it into the existing step rather than creating a new one.

### Rating
| Dimension | Score | Rationale |
|-----------|-------|-----------|
| Simplicity | 4 | One step instead of three new step numbers |
| Consistency | 5 | Follows existing decomposition step's "decide + prepare" pattern |
| UX | 4 | User sees tracker creation as part of plan approval flow |
| Maintainability | 5 | No new step numbering conventions, no cross-skill step ID divergence |

### Key Opportunity
Eliminating three new step IDs (5a, 4b-tracker, 3b-tracker) removes a documentation and testing burden. The step numbering across the three skills is already complex — adding dash-suffixed sub-steps would set a bad precedent.

### Key Risk
If the tracker creation takes long (many subtasks + slow MCP), it elongates the decomposition step's perceived duration. Mitigated by the display output showing progress: "Creating tracker sub-issues... 3/5".

---

## Area 2: GitHub/Gitea Checklist

### Recommended Approach: Progressive Checklist With Links

The research settled on "checklist in parent issue body" for GitHub/Gitea. I want to push this further with a design that creates lasting value.

**Proposal: Rich Checklist With Live Status Updates**

Phase 1 (v6.4.0 — scope of this feature): Create the checklist upfront with all subtask entries as unchecked items.

```markdown
## Subtask Progress
<!-- ceos-agents:decomposition-checklist -->
- [ ] subtask-1: Refactor auth middleware (~15 lines) — Addresses: AC-1
- [ ] subtask-2: Add rate limiting to API endpoints (~25 lines) — Addresses: AC-2, AC-3
- [ ] subtask-3: Update integration tests (~20 lines) — Addresses: AC-1, AC-3
<!-- /ceos-agents:decomposition-checklist -->
```

Phase 2 (future enhancement, not in v6.4.0): After each subtask completes, update the parent issue body to check the box and append the commit SHA or PR reference:

```markdown
- [x] subtask-1: Refactor auth middleware (~15 lines) — Addresses: AC-1 [done: abc1234]
- [ ] subtask-2: Add rate limiting to API endpoints (~25 lines) — Addresses: AC-2, AC-3
```

**Why the HTML comment sentinels?** They serve triple duty:
1. **Idempotency:** On resume, detect existing checklist by scanning for `<!-- ceos-agents:decomposition-checklist -->` — skip recreation
2. **Update targeting:** When checking boxes, find the section between sentinels, parse it, update the specific line, write back
3. **Machine readability:** Other tools (CI, dashboards, the `/status` skill) can parse the checklist without fragile heading detection

**Why include `maps_to` inline?** The `Addresses: AC-N` suffix in each checklist item provides at-a-glance traceability in the tracker without opening the YAML. This is the same information the research recommends for native sub-issue descriptions (RQ-15), applied consistently to the checklist format.

**Append vs overwrite:** The checklist must be *appended* to the parent issue body, not replace it. Read the current body, find the insertion point (end of body or before a specific section), insert the checklist block. If the sentinel markers already exist, replace the block between them (idempotent update).

### Rating
| Dimension | Score | Rationale |
|-----------|-------|-----------|
| Simplicity | 3 | Phase 1 is simple; Phase 2 adds complexity (read-modify-write cycle per subtask) |
| Consistency | 5 | Matches scaffold Step 4e's back-reference pattern (HTML comments in markdown) |
| UX | 5 | Users see subtask progress directly in their GitHub/Gitea issue without leaving the tracker |
| Maintainability | 4 | Sentinel pattern is robust; Phase 2 deferred to keep v6.4.0 lean |

### Key Opportunity
The sentinel-wrapped checklist becomes a protocol. The `/status` skill and `/dashboard` skill could parse it to show decomposition progress from the tracker side, not just from state.json. This creates a tracker-as-truth capability for GitHub/Gitea projects that lack native sub-issue support.

### Key Risk
GitHub/Gitea issue body edits via MCP could be rate-limited or have concurrent edit conflicts (another user edits the issue body while the pipeline updates the checklist). Mitigation: read before write, and accept last-write-wins semantics (same approach as state.json concurrent access).

---

## Area 3: Shared Pattern / Core Contract

### Recommended Approach: Extract `core/subtask-tracker.md` With Extensible Interface

The research notes that scaffold Step 4e and the new decomposition tracker creation share the same fundamental operation: "create issues in tracker from a list, with parent links, idempotency, and accumulator pattern." This screams for extraction.

**Proposal: `core/subtask-tracker.md` — Shared Tracker Issue Creation Contract**

```
# Subtask Tracker Creation

## Purpose
Create tracker issues from a structured subtask list with parent linking,
idempotency, and partial failure handling.

## Input Contract
| Field | Type | Notes |
|-------|------|-------|
| parent_issue_id | string | Parent issue in the tracker |
| subtasks | list | Each: {id, title, description, maps_to} |
| tracker_type | string | youtrack/github/jira/linear/gitea/redmine |
| tracker_id_field | string | Name of the field to write back (e.g., "tracker_issue_id") |
| checklist_mode | boolean | If true, use checklist-in-parent instead of sub-issues |

## Process
1. For each subtask where tracker_id_field is null:
   a. If checklist_mode: append to parent issue body checklist
   b. If native sub-issues: create sub-issue with parent link
   c. Write ID back to subtask data source
   d. On failure: log WARN, increment failure counter, continue

## Output Contract
| Field | Type |
|-------|------|
| created_count | integer |
| total_count | integer |
| failure_count | integer |
| created_ids | map<subtask_id, tracker_issue_id> |
```

**Benefits of extraction:**
1. Scaffold Step 4e can be refactored to use this contract (DRY — currently ~60 lines of inline logic)
2. The new decomposition steps in all three skills reference one contract instead of duplicating logic
3. Future extensibility: if someone builds a Notion MCP or Azure DevOps MCP, adding a new tracker type means updating `docs/reference/trackers.md` + this contract — not touching every skill
4. The `checklist_mode` parameter cleanly encapsulates the GitHub/Gitea fallback decision, derived from the Sub-Issue Capabilities table in `docs/reference/trackers.md`

**What this is NOT:** This is not a runtime library. It is a markdown contract (like all other `core/*.md` files). The LLM reads it and follows the protocol. But having the protocol defined in one place means consistent behavior across scaffold, implement-feature, fix-ticket, and fix-bugs.

### Rating
| Dimension | Score | Rationale |
|-----------|-------|-----------|
| Simplicity | 3 | Extraction adds a new core file, requires scaffold refactor |
| Consistency | 5 | Mirrors the existing core pattern library perfectly |
| UX | 3 | Invisible to end users (internal architecture) |
| Maintainability | 5 | Single source of truth for tracker issue creation logic |

### Key Opportunity
This contract could become the foundation for a "tracker bridge" — a future feature where third-party plugins can register custom tracker types by implementing the subtask-tracker contract. The `checklist_mode` boolean could become a richer strategy enum (`native_sub_issue`, `checklist`, `label_group`, `linked_issues`) as more tracker idioms emerge.

### Key Risk
Premature abstraction. If scaffold Step 4e's epic/story model diverges significantly from decomposition's flat subtask model, the shared contract could become awkward. Mitigation: keep the contract focused on the common operation (create issue, link parent, write back ID) and let callers handle model-specific concerns (epic hierarchy in scaffold, flat list in decomposition).

---

## Area 4: Idempotence

### Recommended Approach: Generalized Checkpoint-Based Idempotence (YAML-first + State Reconciliation)

The research chose YAML-first idempotency: check `tracker_issue_id != null` in YAML to skip already-created issues. This is sound for this specific feature. But I want to propose a broader design that could benefit the entire plugin over time.

**Proposal: Establish a "completed marker" convention across all pipeline steps**

Currently, idempotency is handled ad-hoc:
- Decomposition YAML: `status: "completed"` + `commit_hash` for subtask execution
- Scaffold Step 4e: HTML comment back-references for epic/story creation
- state.json: `{phase}.status == "completed"` for resume
- The new feature: `tracker_issue_id != null` for sub-issue creation

These are all variations of the same pattern: **"if marker exists, skip this operation."** I propose formalizing this as a convention in the state manager.

**Convention: `core/state-manager.md` adds an "Idempotency Protocol" section:**

```
## Idempotency Protocol

For any operation that creates an external side effect (tracker issue,
git commit, PR, webhook), the step MUST:
1. Before execution: check the relevant marker field. If populated, skip.
2. After execution: write the marker field immediately.
3. On resume: the marker field is the authoritative signal, not the
   external system state.

Marker fields by operation type:
| Operation | Marker field | Location |
|-----------|-------------|----------|
| Subtask commit | commit_hash | YAML + state.json |
| Tracker sub-issue | tracker_issue_id | YAML + state.json |
| PR creation | publisher.pr_url | state.json |
| Webhook fire | hooks.{phase} | state.json |
| Back-reference comment | HTML comment in markdown | spec file |
```

**Why this matters beyond v6.4.0:**
- Developers adding new pipeline steps get a clear protocol for making them resumable
- The `/resume-ticket` skill can be simplified to "find the first step without a completed marker" instead of the current heuristic chain (PUBLISHED > DECOMPOSE_PARTIAL > POST_FIX > ...)
- Debugging resume failures becomes systematic: "which marker is missing?" rather than "which heuristic fired?"

**For v6.4.0 specifically:** Apply the YAML-first approach exactly as the research recommends. The broader convention is a documentation exercise that codifies existing patterns. No code changes needed — just making implicit behavior explicit.

### Rating
| Dimension | Score | Rationale |
|-----------|-------|-----------|
| Simplicity | 4 | v6.4.0 work is unchanged; convention is documentation-only |
| Consistency | 5 | Unifies five existing idempotency patterns under one roof |
| UX | 3 | Internal improvement — users benefit indirectly through better resume reliability |
| Maintainability | 5 | Future contributors know exactly how to make a step resumable |

### Key Opportunity
The formalized idempotency protocol could enable a "pipeline replay" feature: re-run a pipeline from scratch while skipping all externally-observable side effects that already exist. This would be valuable for debugging and for "rebase and retry" workflows.

### Key Risk
Over-documentation without enforcement. If the convention exists in `core/state-manager.md` but new steps don't follow it, it becomes misleading. Mitigation: add a note to the agent definition conventions in CLAUDE.md: "Execution agents creating external side effects MUST follow the Idempotency Protocol from `core/state-manager.md`."

---

## Area 5: Config Key

### Recommended Approach: Simple Key With Future Extensibility Path

The research concluded: `Create tracker subtasks` | `enabled` / `disabled` | Default: `enabled`. I agree with this for v6.4.0 but want to map out the extensibility surface.

**v6.4.0 (ship this):**

```
### Decomposition
| Key | Value |
| Max subtasks | 7 |
| Fail strategy | fail-fast |
| Commit strategy | squash |
| Create tracker subtasks | enabled |
```

One key, string enum, default enabled. No additional configuration needed because:
- The fallback strategy (checklist vs native sub-issue) is derived from tracker type (already in `docs/reference/trackers.md`)
- The parent issue ID is always the issue being worked on (no configuration needed)
- The issue description template is generated from the subtask's scope + maps_to + acceptance_criteria (no custom template needed at this point)

**Future extensibility (NOT v6.4.0 — just design notes for the roadmap):**

If users request richer configuration, the path would be:

```
### Decomposition
| Key | Value |
| Max subtasks | 7 |
| Fail strategy | fail-fast |
| Commit strategy | squash |
| Create tracker subtasks | enabled |
| Subtask issue template | .ceos-agents/templates/subtask.md |
| Subtask labels | decomposition, auto-generated |
| Inherit parent labels | enabled |
```

- **Subtask issue template:** A markdown template with `{title}`, `{scope}`, `{maps_to}`, `{acceptance_criteria}` placeholders. Default: inline template from the core contract. This would let teams customize what their decomposition issues look like in the tracker.
- **Subtask labels:** Labels to apply to every created subtask issue. Useful for filtering/searching.
- **Inherit parent labels:** Copy labels from the parent issue to subtask issues. Useful for priority/category propagation.

These are all MINOR additions (optional keys in existing section). Documenting the extensibility path now prevents us from painting into a corner with the v6.4.0 implementation.

**Why not ship templates in v6.4.0?** YAGNI. The default description format (`Title: {title}\nScope: {scope}\nAddresses: {maps_to}`) is sufficient. Templates add configuration surface area that needs testing, documentation, and edge case handling. Ship the simple version, see if anyone asks for more.

### Rating
| Dimension | Score | Rationale |
|-----------|-------|-----------|
| Simplicity | 5 | One key, obvious semantics |
| Consistency | 5 | Follows existing Decomposition section conventions exactly |
| UX | 4 | Enabled by default = zero-config for existing users |
| Maintainability | 4 | Clear extension points documented for future needs |

### Key Opportunity
The "enabled by default" decision means every project that already uses decomposition gets tracker visibility for free on upgrade. This is a significant UX win — the feature just works.

### Key Risk
Users who DON'T want subtask issues cluttering their tracker will need to discover and set `Create tracker subtasks | disabled`. The CHANGELOG must prominently document this behavioral change. Consider: should the first run after upgrade display a one-time notice? "New in v6.4.0: Decomposition subtasks are now created as tracker issues. Disable with `Create tracker subtasks | disabled` in Automation Config."

---

## Area 6: Partial Failure

### Recommended Approach: WARN-and-Continue With Smart Retry on Resume

The research chose WARN-and-continue (accumulator pattern), matching scaffold Step 4e. I agree — blocking the pipeline because a tracker API call failed would be absurd when the code changes are already approved. But I want to add a retry dimension.

**v6.4.0 (ship this):**

```
For each subtask:
  1. Check tracker_issue_id in YAML — if populated, skip (idempotent)
  2. Attempt MCP create-issue call
  3. On success: write tracker_issue_id to YAML + state.json
  4. On failure: log WARN, increment failure_count, continue

After all subtasks:
  - Commit YAML (with whatever tracker_issue_ids were successfully written)
  - Display: "Created {N}/{M} tracker sub-issues ({F} failures)"
  - If F > 0: display failed subtask IDs and suggest: "Run /resume-ticket to retry failed issue creation"
  - Continue to execution loop — code changes are NOT blocked by tracker failures
```

**The resume-retry mechanism:** This is the innovative part. When `/resume-ticket` detects `DECOMPOSE_PARTIAL` checkpoint:
1. Read the YAML task tree
2. For each subtask: check if `tracker_issue_id` is null AND `status` is still `pending`
3. If any subtask has `tracker_issue_id == null`: attempt creation again before continuing to the execution loop
4. This is zero-cost: the check is already part of the YAML read that `DECOMPOSE_PARTIAL` performs

The beauty of this design is that retry is **free**. The idempotency markers (tracker_issue_id) are already in the YAML. The resume flow already reads the YAML. Adding "also retry null tracker_issue_id entries" is a one-paragraph addition to the resume-ticket skill, not a new retry mechanism.

**What about immediate retry (within the same run)?** I considered adding a retry-with-backoff per subtask (e.g., 1 retry after 2 seconds). The problem: MCP failures are usually systemic (auth expired, rate limit, network), not transient per-request. If subtask-1 fails, subtask-2 will likely fail too. Immediate retry wastes time. Better to fail fast, create what we can, and let the user fix the underlying issue before resume.

**What about a dedicated "repair" mode?** I also considered a `/fix-tracker-sync` command that would reconcile YAML vs tracker state. Premature for v6.4.0 — if the need emerges, it can be built on top of the `core/subtask-tracker.md` contract later.

### Rating
| Dimension | Score | Rationale |
|-----------|-------|-----------|
| Simplicity | 5 | Accumulator pattern is proven; retry-on-resume is ~5 lines of spec |
| Consistency | 5 | Exact match with scaffold Step 4e behavior |
| UX | 5 | Non-blocking + automatic retry on resume = best of both worlds |
| Maintainability | 4 | Retry logic is implicit in existing resume flow, not a separate mechanism |

### Key Opportunity
The retry-on-resume pattern could be generalized to ANY pipeline step that creates external side effects. Failed webhook fires, failed PR descriptions, failed state transitions — all could retry on resume instead of requiring manual intervention. This connects to the idempotency protocol from Area 4.

### Key Risk
Silent failure accumulation. If a user runs the pipeline, gets "Created 0/5 tracker sub-issues (5 failures)" but doesn't notice, the subtasks execute without tracker visibility. Mitigation: the display message is explicit, and the final pipeline summary (implement-feature step 9) should include tracker creation status.

---

## Cross-Cutting Innovation: The Decomposition Lifecycle View

One theme emerged across all six areas: decomposition subtasks have a lifecycle that spans multiple systems (YAML, state.json, tracker, git). Today, each system sees a fragment. I propose that the v6.4.0 implementation should set the foundation for a unified decomposition lifecycle:

```
PLAN (architect) -> MATERIALIZE (tracker) -> EXECUTE (fixer) -> VERIFY (reviewer/test) -> COMPLETE (commit)
     [YAML]           [tracker_issue_id]      [status]          [commit_hash]           [close issue?]
```

For v6.4.0, we implement PLAN + MATERIALIZE. The EXECUTE/VERIFY/COMPLETE stages already exist. What is missing (and could come in v6.5.0) is the last mile: when a subtask completes, update its tracker issue to reflect completion — check the checkbox (GitHub/Gitea) or transition the sub-issue state (YouTrack/Jira). This closes the loop and makes the tracker a true mirror of execution progress.

The key architectural decision for v6.4.0: **design the tracker_issue_id storage and the core/subtask-tracker.md contract to support both creation AND update operations.** Even if we only ship creation in v6.4.0, the contract should have a placeholder for `update_status` so that v6.5.0 is a natural extension, not a redesign.
