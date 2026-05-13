# Agent 1 — Core Design Decisions: Research Answers

**Scope:** RQ-1, RQ-2, RQ-3, RQ-4, RQ-12
**Method:** Read source files; all findings cite exact path and line range.

---

## RQ-1: Timing — Upfront vs. Per-Subtask Issue Creation?

**Answer: Upfront, after user approves the decomposition plan, before the execution loop begins.**

### Evidence

**Scaffold Step 4e** (`skills/scaffold/SKILL.md`, lines 518–573):
Scaffold creates ALL tracker issues in a single dedicated step (Step 4e) that runs after git init (Step 4c) and remote push (Step 4d), but before feature implementation (Step 5). The entire iteration over `spec/epics/*.md` happens upfront. The execution loop in Step 7 uses already-created issue IDs without re-querying the tracker.

Key quote (lines 527–529):
> "If none of the guard conditions apply, proceed: 1. Iterate over spec/epics/*.md files…"

The accumulator pattern (line 561–570) confirms: all issues created first, then a single commit of all back-references, then pipeline continues.

**implement-feature Step 6** (`skills/implement-feature/SKILL.md`, lines 246–360):
The execution loop (Step 6a through 6i) has no tracker write operations for subtask issue creation. The loop only reads subtask context, runs agents, and commits git changes. Tracker issue creation is not present at all — it is the gap we are filling.

**Conclusion:**

The upfront pattern is correct for three reasons:

1. **Consistency with scaffold**: scaffold (the reference implementation) always creates all issues before any implementation work starts.
2. **Simpler idempotency**: checking `tracker_issue_id != null` once per subtask at the start of the creation pass is straightforward. Per-subtask creation inside the execution loop would require idempotency checks at the start of every subtask iteration — significantly more complex.
3. **User visibility**: when the user approves the decomposition plan (implement-feature Step 5, `skills/implement-feature/SKILL.md` lines 224–237), they can immediately see the created tracker issues before implementation begins. This is the expected UX pattern from the roadmap description (`docs/plans/roadmap.md`, lines 440–448).

**Insertion point**: After user approves decomposition plan (end of Step 5 in implement-feature, end of Step 4b in fix-ticket, end of Step 3b in fix-bugs) — see RQ-12 for exact numbering.

---

## RQ-2: GitHub/Gitea Fallback — Checklist vs. Standalone?

**Answer: Checklist in parent issue body. This is technically feasible via MCP (edit issue body). It is also what the user explicitly specified in the roadmap.**

### Evidence

**Roadmap entry** (`docs/plans/roadmap.md`, line 444):
> "GitHub/Gitea: create issues with `parent: #{parent-issue-number}` in body (no native subtask support — use checklist in parent issue)"

This is unambiguous: the roadmap explicitly calls for checklist, not standalone issues.

**Scaffold Step 4e fallback** (`skills/scaffold/SKILL.md`, lines 552–554):
> "If tracker does NOT support native sub-issues (GitHub, Gitea): create standalone issue with title `[{epic_title}] {story_title}`, add cross-reference to epic issue in description"

Scaffold uses standalone issues. This approach made sense for scaffold (epics/stories are independent work items) but is not appropriate for decomposition subtasks, which are ephemeral implementation steps.

**Sub-Issue Capabilities table** (`docs/reference/trackers.md`, lines 86–97):
| Tracker | Native sub-issues | Fallback strategy |
|---------|-------------------|-------------------|
| github | No | Standalone issue: `[{epic_title}] {story_title}`, cross-reference in description |
| gitea | No | Standalone issue: `[{epic_title}] {story_title}`, cross-reference in description |

The table documents the scaffold fallback as standalone. For decomposition, we override this with checklist per the roadmap.

**Feasibility analysis:**

The checklist approach requires:
1. Read the current parent issue body via MCP.
2. Append a `## Subtasks` section with `- [ ] Subtask N: {title}` entries.
3. Write the modified body back via MCP update-issue call.

All tracker MCP servers (GitHub, Gitea/Forgejo) support issue body updates. This is a standard MCP operation — no blocking constraint. The skill already uses MCP write operations for state transitions (e.g., `On start set` in Step 1 of implement-feature, line 162).

**Recommended checklist format** (consistent with GitHub conventions):
```
## Subtasks

- [ ] ST-1: {subtask-1-title}
- [ ] ST-2: {subtask-2-title}
- [ ] ST-3: {subtask-3-title}
```

Each subtask completion should update the checkbox: `- [x] ST-N: {title}`. This gives users live progress visibility in the tracker UI.

**Conclusion:** Use checklist for GitHub/Gitea. Do NOT create standalone sub-issues for decomposition subtasks — they are implementation steps, not independent work items. Scaffold's standalone approach remains correct for scaffold (epics and stories ARE independent work items).

---

## RQ-3: Idempotency Mechanism

**Answer: YAML-first check (`tracker_issue_id != null`), with tracker-query fallback on field absent. Same pattern as scaffold's back-reference comment guard.**

### Evidence

**Scaffold Step 4e idempotency guards** (`skills/scaffold/SKILL.md`, lines 532–543):

Two-level guard:
1. Epic guard (line 532): "Check if the epic file already contains a `<!-- {TrackerType}: ... -->` back-reference comment after the `# Epic NN:` heading. If present: skip epic creation, extract the existing issue ID."
2. Story guard (line 542): "If story heading already has a `<!-- {TrackerType}: ... -->` back-reference comment on the next line, skip creation for this story."

This is a file-based idempotency check. The back-reference IS the idempotency token — if it's present, creation is skipped.

**DECOMPOSE_PARTIAL checkpoint** (`skills/resume-ticket/SKILL.md`, lines 59–68):
> "Detection: Look for file `.claude/decomposition/{ISSUE-ID}.yaml`. If it exists: 1. Read the task tree. 2. Find the last completed subtask. 3. Continue from the next subtask."

Resume already reads the YAML file to determine which subtasks are complete. Adding `tracker_issue_id` to each subtask entry is a natural extension — resume can check `tracker_issue_id != null` to skip re-creation.

**State schema** (`state/schema.md`, lines 193–208):
The subtask object has `status`, `commit_hash`, `restore_point`, `depends_on`, `scope`, `files`, `estimated_lines`, `acceptance_criteria`, `maps_to`. No `tracker_issue_id`. Adding it is a non-breaking extension.

**Recommended idempotency design:**

```
For each subtask in task tree:
  1. If subtask.tracker_issue_id is not null → skip creation (already created)
  2. If subtask.tracker_issue_id is null → create issue via MCP
  3. On success: write tracker_issue_id to YAML immediately (per-subtask atomic write)
     Also update state.json decomposition.subtasks[N].tracker_issue_id
  4. On failure: WARN and continue (advisory, not blocking — mirrors state.json write failure policy)
```

**Why per-subtask YAML write (not batch commit at end):**

Scaffold commits all back-references in a single `git commit` after all issues are created (line 564: `git add spec/ && git commit -m "chore: link spec epics to tracker issues"`). For decomposition, this works too — but there is a crash resilience advantage to writing `tracker_issue_id` into the YAML immediately after each creation. If the process crashes mid-creation-pass, DECOMPOSE_PARTIAL resume can determine which subtasks already have tracker issues from the YAML, without re-querying the tracker. The YAML write is cheap and is the primary idempotency token.

**Fallback (when YAML field is absent due to old YAML without the field):** If the YAML was written by an older version without `tracker_issue_id`, the field will be absent (not null). In this case, skip tracker issue creation for that subtask and log a WARN. Do not attempt a tracker query to find matching issues — this avoids latency and rate-limit concerns.

---

## RQ-4: Field Naming — `tracker_id` vs. `tracker_issue_id`

**Answer: Use `tracker_issue_id`. The name `tracker_id` is already used in a different, conflicting context.**

### Evidence

**Redmine query syntax** (`docs/reference/trackers.md`, line 14):
> `| redmine | project_id={P}&status_id=open&tracker_id={bug_tracker_id} |`

**Redmine note** (line 16):
> "`tracker_id` expects the numeric ID from your Redmine instance (typically 1=Bug, 2=Feature, 3=Support)."

`tracker_id` in the Redmine context refers to the Redmine "tracker" (issue type: Bug, Feature, Support), NOT to a tracker issue ID. It is a configuration parameter in query strings.

**Roadmap proposal** (`docs/plans/roadmap.md`, line 447):
> "State: store tracker issue IDs in `decomposition.subtasks[N].tracker_id`"

The roadmap uses `tracker_id` but the Redmine collision was not considered there.

**Collision risk analysis:**

All occurrences of `tracker_id` in the codebase (confirmed by grep):
- `docs/reference/trackers.md` lines 14, 16 — Redmine query param
- `docs/reference/automation-config.md` line 93 — Redmine bug query example
- `examples/configs/redmine-rails.md` line 13 — Redmine example config
- `docs/plans/2026-03-03-redmine-tracker-support-design.md` lines 32, 177, 254, 331 — Redmine design
- `docs/plans/2026-03-03-redmine-tracker-support-plan.md` lines 38, 264, 387 — Redmine plan
- `docs/plans/roadmap.md` line 447 — the proposed new field (only occurrence of proposed usage)

Every existing occurrence of `tracker_id` refers to the Redmine issue TYPE parameter, not an issue ID. Using `tracker_id` for the new field would create genuine confusion for anyone reading state.json or the schema and cross-referencing Redmine documentation.

**Recommendation:** Use `tracker_issue_id` in:
- `.claude/decomposition/{ISSUE-ID}.yaml` subtask entries
- `state.json` at `decomposition.subtasks[N].tracker_issue_id`
- `state/schema.md` Subtask Object Fields table
- All skill documentation referring to this field

The name is unambiguous: `tracker` = the issue tracker system, `issue_id` = the ID of the issue in that tracker.

---

## RQ-12: Step Numbering — Insertion Points

**Answer: New step is inserted between the decomposition decision and the execution loop in each skill. Exact step labels below.**

### Evidence

**implement-feature** (`skills/implement-feature/SKILL.md`):
- Step 5: Decomposition decision (line 196) — ends with "Save task tree" and state.json update
- Step 6: Subtask execution loop (line 246) — starts with "Single-pass (without decomposition):"
- **Insert: Step 5a** — "Create Tracker Sub-Issues" — runs after decomposition decision is DECOMPOSE and task tree is saved, but only when `decomposition.decision == "DECOMPOSE"` (single-pass has no subtasks to create)

**fix-ticket** (`skills/fix-ticket/SKILL.md`):
- Step 4b: Decomposition decision (line 168) — ends with state.json update
- Step 4c: Subtask execution loop (line 202) — starts "For each subtask in topological order:"
- **Insert: Step 4b-tracker** — "Create Tracker Sub-Issues" — runs after 4b returns DECOMPOSE, before 4c starts

**fix-bugs** (`skills/fix-bugs/SKILL.md`):
- Step 3b: Decomposition decision per-bug (line 145) — ends with state.json update
- Step 3c: Subtask execution loop per-bug (line 189) — starts "For each subtask in topological order:"
- **Insert: Step 3b-tracker** — "Create Tracker Sub-Issues" — per-bug, inside the bug-processing loop

### Rationale for step label choices

- `implement-feature` already uses decimal steps (5, 6) — `5a` is natural, consistent with `6a/6b/6c` sub-steps already in the file.
- `fix-ticket` uses `4a/4b/4c` pattern — `4b-tracker` extends this without renumbering `4c`.
- `fix-bugs` mirrors `fix-ticket` structure — `3b-tracker` is consistent.

All three new steps are **DECOMPOSE-only** (gated on `decomposition.decision == "DECOMPOSE"`). Single-pass execution does not enter the execution loop and has no subtasks, so issue creation is not applicable.

**Guard conditions for all three new steps** (same as scaffold Step 4e):
- `decomposition.decision != "DECOMPOSE"` → skip
- MCP write not available → WARN and skip (advisory)
- `tracker_effective_status` not available in fix-ticket/fix-bugs (no 0-INFRA step) → infer from Automation Config Issue Tracker → Type being accessible (MCP pre-flight already verified)

**GitHub/Gitea-specific guard**: edit parent issue body to insert checklist — requires reading current body first, then writing modified version.

---

## Summary Table

| RQ | Decision | Key Evidence |
|----|----------|-------------|
| RQ-1 | Upfront, after plan approval, before execution loop | scaffold/SKILL.md lines 518–573; implement-feature/SKILL.md lines 246–360 (no tracker writes in loop) |
| RQ-2 | Checklist in parent body for GitHub/Gitea (not standalone) | roadmap.md line 444; trackers.md lines 86–97 |
| RQ-3 | YAML-first (`tracker_issue_id != null`), per-subtask write, no tracker query fallback | resume-ticket/SKILL.md lines 59–68; scaffold/SKILL.md lines 532–543 |
| RQ-4 | `tracker_issue_id` (not `tracker_id` — collision with Redmine param) | trackers.md lines 14, 16; roadmap.md line 447 |
| RQ-12 | Step 5a (implement-feature), Step 4b-tracker (fix-ticket), Step 3b-tracker (fix-bugs) | implement-feature/SKILL.md lines 196–246; fix-ticket/SKILL.md lines 168–202; fix-bugs/SKILL.md lines 145–189 |
