# Phase 3: Brainstorm Synthesis — Recommended Design

## Approach Summary

The three brainstorm agents (Conservative, Innovative, Skeptical) converged on most decisions with important nuances. Below is the synthesized recommendation.

---

## 1. Step Placement → Separate dedicated step (Conservative wins)

**Decision**: Insert a new step between decomposition decision and execution loop:
- **implement-feature**: Step 5a "Create tracker subtasks"
- **fix-ticket**: Step 4b-tracker "Create tracker subtasks"  
- **fix-bugs**: Step 3b-tracker "Create tracker subtasks"

**Rationale**: Matches existing step structure. Each step is clearly isolated, skippable, and resumable. The Innovative proposal to merge into the decomposition decision step adds unnecessary coupling — the decomposition decision is about planning, not tracker integration.

**Gate conditions**: Step executes only when:
1. `decomposition.decision == "DECOMPOSE"` (task was decomposed)
2. `Create tracker subtasks` config == `enabled`
3. `tracker_effective_status == "ready"` (MCP tracker available)

If any condition is false, skip the step entirely (no WARN, expected behavior).

---

## 2. GitHub/Gitea Checklist → Checklist in parent issue body with sentinel

**Decision**: For GitHub/Gitea (no native sub-issues), edit the parent issue body to append a decomposition checklist section.

**Format**:
```markdown

---
## Decomposition Subtasks
<!-- ceos-agents:decomposition-checklist:{ISSUE-ID} -->
- [ ] {subtask-title} (#{subtask-issue-number})
- [ ] {subtask-title} (#{subtask-issue-number})
...
```

**Implementation**:
1. Create standalone issue for each subtask (titled: `[{PARENT-ID}] {subtask-title}`)
2. After all subtask issues created, read parent issue body via MCP
3. Check for sentinel comment `<!-- ceos-agents:decomposition-checklist:{ISSUE-ID} -->` — if present, skip (idempotency)
4. Append the checklist section to the body
5. Update parent issue body via MCP

**Why hybrid (standalone issues + checklist)**: Creating standalone issues gives each subtask its own tracker ID (needed for `tracker_issue_id` in YAML/state). The checklist provides the visual hierarchy the user requested. This combines the best of both approaches.

**Risk mitigation (Skeptic)**: Read-modify-write race on parent body is accepted as low-risk (decomposition is rare, and the sentinel comment provides idempotency on retry).

---

## 3. Shared Pattern → Inline (Conservative wins)

**Decision**: Inline the tracker subtask creation logic in each of the 3 skills. Do NOT create `core/subtask-tracker.md`.

**Rationale**: 
- The logic is ~30-40 lines per skill
- Scaffold Step 4e is already inlined (~55 lines) and works fine
- Extraction to a core contract adds indirection for minimal payoff
- If a fourth consumer appears, extraction can happen then

**Consistency mechanism**: The 3 skill implementations must be kept in sync. The spec will define a canonical step template that all 3 skills copy. Any divergence is a review finding.

---

## 4. Idempotence → Dual-store (YAML + state.json), YAML authoritative for resume

**Decision**: Write `tracker_issue_id` to BOTH the decomposition YAML and state.json immediately after each successful MCP creation call.

**Primary check (resume)**: Read `.claude/decomposition/{ISSUE-ID}.yaml` — if `tracker_issue_id` is non-null for a subtask, skip creation.

**Fallback check (crash recovery)**: If YAML has null but state.json has a value (YAML write failed after state.json write), use state.json's value.

**Skeptic's insight applied**: If user runs `git checkout .` destroying YAML, state.json (outside git, in `.ceos-agents/`) preserves the tracker_issue_id. Resume reads state.json as fallback.

**No tracker-side query**: Don't query the tracker for existing issues — too slow, unreliable, and unnecessary given dual-store.

---

## 5. Config Key → `Create tracker subtasks` | `enabled` (default)

**Decision**: Add to existing Decomposition section:

| Key | Default | Description |
|-----|---------|-------------|
| Create tracker subtasks | `enabled` | Create sub-issues in the tracker for each decomposition subtask. Values: `enabled`, `disabled` |

**Default `enabled` rationale**: 
- Feature is gated by `tracker_effective_status == "ready"` — projects without tracker integration see zero change
- Existing optional keys default to active behavior (consistency)
- Behavioral change is documented in CHANGELOG
- Skeptic's concern about write operations is valid but the triple-gate (config + tracker status + decomposition decision) prevents unintended execution

**Versioning**: MINOR (v6.4.0) — adding optional key to existing optional section.

---

## 6. Partial Failure → Accumulator pattern with 100% failure escalation

**Decision**: Reuse scaffold Step 4e's accumulator pattern:

1. Iterate subtasks, attempt MCP creation for each
2. On individual failure: log WARN, store `tracker_issue_id: null`, continue
3. After loop: commit YAML with all successfully-populated tracker_issue_ids
4. Display: `"Created {N}/{M} tracker sub-issues ({F} failures)."`
5. **If N == 0 (100% failure)**: elevated WARN with message: `"All tracker sub-issue creation failed. Check MCP tracker connectivity. Pipeline continues without tracker integration for this decomposition."`
6. Pipeline NEVER blocks on tracker creation failure

**GitHub/Gitea special case**: The checklist update to parent body is a single operation (not per-subtask). If it fails, log WARN and continue — subtask issues may still exist as standalone.

---

## Field Naming Decision

**`tracker_issue_id`** (not `tracker_id`)

Rationale: `tracker_id` appears 11 times in codebase as Redmine's issue TYPE parameter. `tracker_issue_id` is unambiguous and self-documenting.

Note: The roadmap says `tracker_id` but this was written before the naming collision was discovered. The spec will use `tracker_issue_id` and the roadmap entry will be updated in the docs phase.

---

## State Schema Addition

Add to `decomposition.subtasks[]` in `state/schema.md`:

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `tracker_issue_id` | string or null | No | `null` | Tracker issue ID for this subtask (e.g., `PROJ-45`). Set after creation via MCP. Used as idempotency guard on resume. |

Same field added to `.claude/decomposition/{ISSUE-ID}.yaml` subtask objects (runtime field, alongside `status`, `commit_hash`, `restore_point`).

---

## Native Sub-Issue Trackers Summary

| Tracker | Create Method | Parent Parameter |
|---------|--------------|-----------------|
| YouTrack | Create issue with parent | `parent: {PARENT-ISSUE-ID}` |
| Jira | Create sub-task | `parent: {PARENT-ISSUE-KEY}`, `issuetype: "Sub-task"` |
| Linear | Create issue with parent | `parentId: {PARENT-ISSUE-ID}` |
| Redmine | Create issue with parent | `parent_issue_id: {PARENT-ISSUE-ID}` |
| GitHub | Create standalone + checklist | N/A (standalone issue, checklist in parent body) |
| Gitea | Create standalone + checklist | N/A (standalone issue, checklist in parent body) |

**Jira edge case**: If parent is already a Sub-task type, create flat issue without parent link, log WARN.

---

## Cross-Agent Agreement Matrix

| Area | Conservative | Innovative | Skeptical | Final |
|------|-------------|-----------|-----------|-------|
| Step placement | Separate step | Merge into decision | Separate + resume field | Separate step |
| GitHub/Gitea | Table format | Rich checklist | Plain checklist + sentinel | Checklist + sentinel (hybrid) |
| Shared pattern | Inline | Core contract | Separate core (not merged w/ scaffold) | Inline |
| Idempotence | YAML-first | YAML-first + protocol | State.json authoritative | Dual-store, YAML primary |
| Config default | enabled | enabled | disabled | enabled (triple-gated) |
| Partial failure | Accumulator | Retry-on-resume | 100% failure escalation | Accumulator + escalation |
