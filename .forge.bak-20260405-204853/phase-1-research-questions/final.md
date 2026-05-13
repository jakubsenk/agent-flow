# Phase 1: Research Questions — Consolidated

## Summary

Three research agents investigated 6 areas across the ceos-agents codebase. Below is the consolidated set of research questions organized by design decision priority, plus key findings and identified gaps.

---

## Key Codebase Findings

### Scaffold Step 4e Pattern (Reference Implementation)
- Iterates `spec/epics/*.md` files sorted by numeric prefix
- Uses `<!-- {TrackerType}: {ID} -->` back-reference comments as idempotency guards
- Native sub-issue trackers (YouTrack, Jira, Linear, Redmine) use tracker-specific parent params
- Fallback trackers (GitHub, Gitea) create standalone issues: `[{epic_title}] {story_title}`
- Accumulator pattern: WARN on individual failure, commit all back-references at end
- Post-creation verification (native only): read back and confirm parent linkage

### Decomposition Pipeline Flow
- **implement-feature**: architect at Step 4, decompose decision at Step 5, subtask loop at Step 6a-6i
- **fix-ticket**: decompose flag at Step 4a, architect+decision at Step 4b, subtask loop at Step 4c
- **fix-bugs**: decompose flag at Step 3a, architect+decision at Step 3b (per-bug), subtask loop at Step 3c
- Task tree saved to `.claude/decomposition/{ISSUE-ID}.yaml`
- Subtask fields: id, title, scope, files, estimated_lines, depends_on, maps_to, acceptance_criteria + runtime: status, commit_hash, restore_point
- **No tracker_issue_id field exists** — this is the primary gap

### State Schema (state/schema.md)
- `decomposition.subtasks[]` has 11 fields, no tracker_id
- Schema version pinned at "1.0", no versioning policy for optional additions
- Existing `tracker_id` references in codebase = Redmine query param (unrelated) — naming collision risk

### Config Contract (CLAUDE.md)
- Decomposition section: 3 keys (Max subtasks, Fail strategy, Commit strategy)
- Optional key pattern: `| Key | Default | Description |` (3-column table)
- Skills explicitly list which Decomposition keys they read in their Configuration section
- Adding optional key to existing optional section = MINOR (v6.4.0)

### Tracker Mechanisms (trackers.md)
- Sub-Issue Capabilities table: 4 native (YouTrack, Jira, Linear, Redmine), 2 fallback (GitHub, Gitea)
- MCP tool prefixes: mcp__{tracker}__* (gitea also mcp__forgejo__*)
- Jira requires `issuetype: "Sub-task"` + parent must be standard issue type
- Linear uses `parentId` with UUID (not display ID)

### Resume/Idempotence
- `DECOMPOSE_PARTIAL` checkpoint: detects YAML file, finds last completed subtask
- No tracker state in resume logic — fully decoupled from tracker issue creation
- State.json write failures are advisory (pipeline continues)

---

## Consolidated Research Questions

### Priority 1: Core Design Decisions

**RQ-1. Timing: upfront vs. per-subtask issue creation?**
Should all tracker subtask issues be created in one pass before the execution loop, or one at a time just before each subtask's fixer step? Scaffold Step 4e creates all upfront. Trade-offs: upfront is simpler for idempotency but all-or-nothing; per-subtask is more resilient but needs mid-loop state tracking.

**RQ-2. GitHub/Gitea fallback: checklist vs. standalone issues?**
User specified "checklist in parent issue body" for GitHub/Gitea. Scaffold uses standalone issues with `[{epic_title}] {story_title}` prefix. These are fundamentally different approaches. Which should the decomposition subtask tracker use? The checklist approach requires editing the parent issue body (read + modify + write), while standalone is simpler but lacks visual hierarchy.

**RQ-3. Idempotency mechanism: YAML field vs. tracker query?**
On resume, should the skill check `tracker_issue_id != null` in the YAML (fast, local), query the tracker for matching titles (slow, reliable), or both? The YAML-first approach is simpler but fails if the YAML write was lost after issue creation.

**RQ-4. Field naming: `tracker_id` vs. `tracker_issue_id`?**
The roadmap says `tracker_id` but Redmine already uses `tracker_id` for issue type query params. `tracker_issue_id` avoids ambiguity. What should the canonical field name be?

### Priority 2: Schema & Config

**RQ-5. Should `tracker_issue_id` be added to both YAML and state.json?**
The YAML is the primary source of truth; state.json mirrors a subset. Should state.json's `decomposition.subtasks[]` also carry `tracker_issue_id`?

**RQ-6. Should `Create tracker subtasks` default to `true` or `false`?**
`true` (roadmap proposal) changes behavior for all existing projects on upgrade. `false` is safer but requires explicit opt-in. Which is correct for a MINOR version?

**RQ-7. Should the config key support more than boolean (e.g., fallback strategy)?**
Could there be a separate key like `Subtask tracker fallback` with values `checklist | standalone | none`? Or keep it simple with a single boolean?

### Priority 3: Edge Cases

**RQ-8. Jira sub-task constraint: what if parent is already a sub-task?**
Jira rejects sub-tasks under other sub-tasks. If `/fix-ticket` runs on a Jira sub-task and decomposes, what happens?

**RQ-9. Linear UUID resolution: who handles display ID → UUID?**
Linear's `parentId` needs a UUID, but the pipeline has display IDs. Is the MCP server expected to handle this?

**RQ-10. Failure policy: WARN-and-continue or hard block?**
Should tracker issue creation failure block the pipeline or be advisory (like state.json writes)?

**RQ-11. YAML commit strategy: when to commit tracker_issue_id changes?**
Should the YAML with tracker_issue_id be committed per-subtask-creation, after all issues, or left uncommitted?

**RQ-12. Step numbering: where does the new step go in each skill?**
implement-feature: between Step 5 (decompose decision) and Step 6 (execution loop)?
fix-ticket: between Step 4b (decompose decision) and Step 4c (execution loop)?
fix-bugs: between Step 3b (decompose decision) and Step 3c (execution loop)?

### Priority 4: Verification & Extensibility

**RQ-13. Post-creation verification: read-back pattern or not?**
Scaffold verifies parent linkage by reading back. Is this needed for decomposition or is MCP return sufficient?

**RQ-14. Write capability check: reuse tracker_write_available or add new check?**
Scaffold gates on Step 0-MCP's write canary. Decomposition skills have no equivalent. Should one be added?

**RQ-15. maps_to in sub-issue description: include AC traceability?**
Should created tracker sub-issues include the `maps_to` AC references in their description?

---

## Identified Gaps (Cross-Cutting)

| ID | Gap | Impact |
|----|-----|--------|
| GAP-1 | No `tracker_issue_id` in YAML or state.json schemas | Blocks idempotency, resume, and the feature itself |
| GAP-2 | GitHub/Gitea fallback strategy differs between roadmap (checklist) and scaffold (standalone) | Design decision needed before implementation |
| GAP-3 | `tracker_id` naming collision with Redmine query param | Potential confusion in documentation |
| GAP-4 | No write capability check in decomposition flow | Could fail silently if MCP not configured |
| GAP-5 | DECOMPOSE_PARTIAL resume has no concept of tracker state | Resume may create duplicate issues |
| GAP-6 | Jira sub-task constraint undocumented for decomposition | Could cause silent API failure |
| GAP-7 | Linear UUID resolution not addressed | May need explicit lookup step |
| GAP-8 | Schema version policy for optional field additions | Undocumented — decide: bump or not |
