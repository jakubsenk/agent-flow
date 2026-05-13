# Brainstorm: Conservative Architect — Decomposition Subtask Tracker Creation

Persona: Conservative Plugin Architect
Priorities: Safety, consistency with existing patterns, minimal scope, backward compatibility.

---

## Area 1: Step Placement

### Recommended Approach

Insert the new step **immediately after** the decomposition decision step and **before** the subtask execution loop, in each of the three skills:

- `implement-feature`: **Step 5a** (after Step 5 "Decomposition decision", before Step 6 "Subtask execution")
- `fix-ticket`: **Step 4b-tracker** (after Step 4b "Decomposition decision", before Step 4c "Subtask execution")
- `fix-bugs`: **Step 3b-tracker** (after Step 3b "Decomposition decision", before Step 3c "Subtask execution")

The step is guarded by two conditions: `decomposition.decision == "DECOMPOSE"` AND `Create tracker subtasks != disabled`. If either fails, skip silently.

This mirrors the existing pattern: the decomposition decision already commits the YAML task tree to `.claude/decomposition/{ISSUE-ID}.yaml` and updates `state.json`. The new step reads that committed task tree and creates tracker issues from it. No structural changes to the pipeline flow — it is a pure insertion between two existing steps.

**Why not after subtask execution?** The whole point is visibility. Creating issues upfront means a project manager can see the planned work in the tracker before any code is written. This also matches scaffold Step 4e, which creates all tracker issues before implementation begins.

**Why not during the decomposition decision step itself?** Separation of concerns. The decomposition decision is about architect output validation and plan approval. Tracker integration is an infrastructure side-effect. Mixing them would make the step harder to reason about, harder to skip independently, and harder to test.

### Rating

| Dimension | Score | Rationale |
|-----------|-------|-----------|
| Simplicity | 5 | Pure insertion, no restructuring needed |
| Consistency | 5 | Matches research RQ-1 and RQ-12; mirrors scaffold's upfront pattern |
| UX | 4 | User sees all issues before execution; -1 because issues are created even if user later aborts execution |
| Maintainability | 5 | Each skill gets a clearly delimited new step that can be removed without affecting neighbors |

### Key Risk

If the user approves the decomposition plan but then aborts before execution, orphan tracker issues exist. This is acceptable — the same risk exists in scaffold Step 4e. The issues serve as documentation of what was planned. No mitigation needed beyond documenting this behavior.

---

## Area 2: GitHub/Gitea Checklist in Parent Issue Body

### Recommended Approach

For trackers that support native sub-issues (YouTrack, Jira, Linear, Redmine): create actual sub-issues with parent linkage, using the exact parameter table already documented in `docs/reference/trackers.md` Sub-Issue Capabilities section. This is the primary path.

For trackers that do NOT support native sub-issues (GitHub, Gitea): **append a checklist section to the parent issue body**. The implementation:

1. **Read** the current parent issue body via the tracker MCP tool.
2. **Check** if a `## Decomposition Plan` section already exists in the body (idempotency — see Area 4).
3. If not present, **append** the following markdown block to the end of the body:

```markdown

---

## Decomposition Plan

| # | Subtask | Status | Addresses |
|---|---------|--------|-----------|
| 1 | {subtask_title} | Pending | {maps_to AC refs, comma-separated} |
| 2 | {subtask_title} | Pending | {maps_to AC refs} |
```

4. **Update** the parent issue body via the tracker MCP tool (full body replacement — GitHub and Gitea APIs require this).

**Why a table and not a checkbox list?** Two reasons:

First, checkboxes (`- [ ] text`) look tempting but create a maintenance burden. GitHub/Gitea task list checkboxes are editable in the UI — a user could manually check/uncheck them, creating a state mismatch with the pipeline's YAML truth. A table communicates "this is a reference, not an interactive control."

Second, the table can include the `maps_to` column for AC traceability (per RQ-15), which is awkward in a flat checkbox list.

**Why `## Decomposition Plan` as the heading?** It is descriptive, unlikely to collide with user-written content (unlike generic headings like "Tasks" or "Plan"), and machine-parseable for idempotency checks. The `##` level keeps it as a major section — visible in GitHub/Gitea's rendered markdown and table of contents.

**Status updates during execution:** After each subtask completes, the skill updates the table row's Status cell from "Pending" to "Done" (or "Failed"/"Blocked"). This is a simple find-and-replace in the body text. If the update fails, log WARN and continue — the YAML remains authoritative.

**What if the body already has content?** The `---` horizontal rule provides visual separation. Appending to the end is safest — it never corrupts existing content. Even if the body has 10,000 characters of description, this pattern works.

### Rating

| Dimension | Score | Rationale |
|-----------|-------|-----------|
| Simplicity | 3 | Read-modify-write on issue body is inherently more complex than creating sub-issues; but it is straightforward markdown manipulation |
| Consistency | 4 | Scaffold Step 4e uses standalone issues with cross-references for GitHub/Gitea; this is different (checklist in parent), but the research explicitly calls for it |
| UX | 5 | Users see the entire decomposition plan directly in the parent issue — no need to navigate to separate issues |
| Maintainability | 3 | Body manipulation is fragile if users edit the section manually; but the YAML is authoritative, so the table is best-effort display |

### Key Risk

**Body corruption.** If the MCP update call writes a truncated body (network error mid-write), the parent issue loses content. Mitigation: read the body, store it in a local variable, append the section, write it back. If the write fails, log WARN — the original body is unchanged on the tracker (writes are atomic at the API level for GitHub and Gitea). Do NOT retry the write — one attempt is sufficient.

A secondary risk: if a user manually edits the `## Decomposition Plan` section, subsequent status updates may fail to find the expected table row. Mitigation: if the section heading exists but table parsing fails, log WARN and skip the update. The YAML remains the source of truth.

---

## Area 3: Shared Pattern vs Inline

### Recommended Approach

**Do NOT create `core/subtask-tracker.md`.** Inline the logic in each skill.

Reasoning:

1. **The three skills handle the step identically in structure but differ in context.** The guard clauses reference different step numbers, different state paths, and different resume checkpoints. A shared contract would need to parameterize all of this, creating abstraction overhead that exceeds the duplication cost.

2. **Existing precedent:** The decomposition decision step itself is inlined in all three skills (fix-ticket Step 4b, fix-bugs Step 3b, implement-feature Step 5). It is NOT extracted to a `core/` pattern. The AC coverage check is also inlined. The fixer-reviewer loop is extracted to `core/fixer-reviewer-loop.md` because it has complex multi-agent orchestration with retry logic — the tracker creation step has neither.

3. **The logic is ~30 lines per skill.** That is: guard clause (3 lines), iterate subtasks (loop with MCP call + YAML write-back), commit, display result. Duplicating 30 lines across 3 files is less maintenance burden than maintaining a 4th file with a parameterized contract that all 3 must reference correctly.

4. **Core files have a contract obligation.** Per CLAUDE.md: "11 shared pipeline pattern contracts." Adding a 12th core file for a simple iteration loop would dilute what "core" means. Core files should be reserved for patterns that are (a) complex, (b) used by 3+ consumers, and (c) have non-trivial input/output contracts. This step is none of those.

**However:** I would extract the tracker-specific parameter table (which tracker uses which parent parameter) into a reference in `docs/reference/trackers.md` — and this is already done. The Sub-Issue Capabilities table already exists there. The skill just references it.

If in a future version a 4th consumer needs this logic (e.g., a new `scaffold-extend` skill), then extraction to `core/` becomes warranted. Not before.

### Rating

| Dimension | Score | Rationale |
|-----------|-------|-----------|
| Simplicity | 5 | No new files, no new abstraction layer, no indirection |
| Consistency | 5 | Follows the existing pattern — decomposition-related logic is inlined in skills, not extracted |
| UX | 4 | Developers reading one skill file see the complete step without jumping to a core contract |
| Maintainability | 4 | Three copies of ~30 lines; if the logic changes, 3 files need updating; acceptable given the simplicity |

### Key Risk

If the three copies diverge over time (someone updates one but not the others), behavior becomes inconsistent. Mitigation: the test harness should include a scenario that verifies all three skills produce the same output shape for the tracker creation step. This is a test concern, not an architecture concern.

---

## Area 4: Idempotence and Crash Recovery

### Recommended Approach

**YAML-first idempotency with per-subtask `tracker_issue_id` field.**

The flow:

1. Read `.claude/decomposition/{ISSUE-ID}.yaml`.
2. For each subtask in order:
   a. If `tracker_issue_id` is non-null: skip (already created). Log: `Subtask {id} already linked to {tracker_issue_id}, skipping.`
   b. Create tracker issue via MCP.
   c. On success: write `tracker_issue_id: {returned_id}` to the subtask entry in the YAML file **immediately** (before proceeding to next subtask).
   d. On failure: log WARN, leave `tracker_issue_id: null`, continue.
3. After all subtasks processed: single `git commit` of the updated YAML.
4. Update `state.json` with the tracker_issue_ids.

**Crash recovery scenario:** If the pipeline crashes between step 2c (YAML write) and step 3 (git commit), the YAML on disk has partial tracker_issue_ids but they are uncommitted. On resume:

- `DECOMPOSE_PARTIAL` checkpoint detects the YAML file.
- The new tracker creation step runs again.
- Subtasks with `tracker_issue_id` already populated in the **on-disk YAML** (even if uncommitted) are skipped.
- Subtasks without `tracker_issue_id` are created.
- The git commit at the end captures everything.

This works because the resume reads the **on-disk file**, not the last committed version. The YAML file persists through crashes (it is written to disk, not held in memory).

**Edge case:** If the pipeline crashes AFTER the MCP create call returns but BEFORE the YAML write completes, we get an orphan tracker issue. This is acceptable — the same orphan risk exists in scaffold Step 4e. The MCP call is not transactional. Orphan issues are harmless (they sit in the tracker with no code linked to them).

**Why not write-ahead log (WAL)?** Overkill. This is a markdown plugin, not a database. The YAML file IS the log. Per-subtask writes to YAML give us crash recovery granularity of one subtask — that is sufficient.

**Field initialization:** When the decomposition decision step writes the YAML, it already includes all subtask fields with defaults. The new field `tracker_issue_id` should be initialized to `null` in the YAML template, alongside the existing `commit_hash: null` and `restore_point: null`. This means the decomposition decision step needs a one-line addition to include `tracker_issue_id: null` in the subtask schema. Minimal change.

### Rating

| Dimension | Score | Rationale |
|-----------|-------|-----------|
| Simplicity | 5 | One new field, per-subtask write, matches existing `commit_hash` pattern exactly |
| Consistency | 5 | Mirrors `commit_hash` and `restore_point` write-back pattern already used in subtask execution |
| UX | 4 | On resume, user sees "Subtask X already linked, skipping" — clear and predictable |
| Maintainability | 5 | No new files, no new data structures, no new resume logic — leverages existing DECOMPOSE_PARTIAL |

### Key Risk

The per-subtask YAML write means N file writes for N subtasks (before the final git commit). If the YAML file is large and the system is slow, this could be noticeable. In practice, Max subtasks is 7 (default), so this is at most 7 YAML writes — negligible.

A more subtle risk: if `tracker_issue_id` is populated but the corresponding tracker issue was actually NOT created (e.g., MCP returned a success response but the issue was rejected server-side), the idempotency guard will skip re-creation. Mitigation: the lightweight verification from RQ-13 (check MCP return value for a valid issue ID) catches this. If the return value is empty/null, treat it as failure and leave `tracker_issue_id: null`.

---

## Area 5: Config Key Shape

### Recommended Approach

Add one key to the existing **Decomposition** optional section:

| Key | Default | Description |
|-----|---------|-------------|
| Create tracker subtasks | `enabled` | Create tracker issues for decomposition subtasks before execution. Values: `enabled`, `disabled`. |

**Why in the Decomposition section?** The feature is decomposition-specific. It does not apply to single-pass execution. Placing it in the Decomposition section is the natural home — no new section needed.

**Why `enabled`/`disabled` and not `true`/`false`?** Per RQ-7, no existing config key uses booleans. The convention is string enums: `fail-fast`/`continue`, `squash`/`individual`, `comment`/`close`. Following convention.

**Why default `enabled`?** Per RQ-6, the feature is gated by `tracker_effective_status == "ready"`. If a project has no tracker integration configured, the step is skipped regardless of this key. For projects WITH tracker integration, creating subtask issues is the expected behavior — it is why you have a tracker. Making it opt-out (default enabled) means projects get the feature automatically after upgrading. Making it opt-in would require every project to add a config line to get a feature they probably want.

**Why not a separate fallback strategy key?** The research considered whether GitHub/Gitea projects need a separate key to control the checklist-in-body behavior. Answer: no. The skill internally detects the tracker type and applies the appropriate strategy (native sub-issues or checklist). There is no user-facing choice to make — the tracker type determines the strategy. Adding a `Fallback strategy` key would only be useful if we supported multiple fallback options for the same tracker, which we do not.

**Versioning impact:** Adding an optional key to an existing optional section is a MINOR version bump (v6.4.0). Per CLAUDE.md versioning policy: "Adding an optional section = MINOR." An optional key within an existing optional section is even less impactful.

### Rating

| Dimension | Score | Rationale |
|-----------|-------|-----------|
| Simplicity | 5 | One key, two values, one default — minimal surface area |
| Consistency | 5 | Follows existing config conventions exactly (string enum, table format, optional section) |
| UX | 5 | Users who want it get it by default; users who do not want it add one line to disable |
| Maintainability | 5 | One key to document, one key to parse, one guard clause to check |

### Key Risk

Behavioral change on upgrade. A project upgrading from v6.3.x to v6.4.0 with an existing tracker integration and decomposition usage will suddenly see tracker issues being created where none were created before. This could surprise users. Mitigation: CHANGELOG must clearly document this behavioral change. The MINOR version bump signals "new feature" — users should read the changelog before upgrading. Additionally, the step displays a summary (`Created N/M tracker sub-issues`) so the behavior is visible, not silent.

---

## Area 6: Partial Failure Handling

### Recommended Approach

**Use the exact same accumulator pattern as scaffold Step 4e.** The pattern is proven, well-tested, and handles all edge cases.

Concrete implementation:

```
success_count = 0
failure_count = 0
total = len(subtasks)

for each subtask in decomposition YAML:
    if subtask.tracker_issue_id is not null:
        success_count += 1  // already created (idempotency)
        continue

    try:
        issue_id = create_tracker_issue(subtask)
        if issue_id is valid:
            subtask.tracker_issue_id = issue_id
            write_yaml()  // per-subtask persistence
            success_count += 1
        else:
            log WARN: "Tracker issue creation returned empty ID for subtask {id}"
            failure_count += 1
    catch error:
        log WARN: "Could not create tracker issue for subtask {id}: {error}"
        failure_count += 1

// GitHub/Gitea checklist (if applicable):
if tracker_type in [github, gitea]:
    try:
        append_checklist_to_parent_issue(subtasks)
    catch error:
        log WARN: "Could not update parent issue body with checklist: {error}"
        // Non-fatal — sub-issues (if any) were already created

// Commit and display:
if success_count > 0:
    git add .claude/decomposition/
    git commit -m "chore: link decomposition subtasks to tracker issues"

display: "Created {success_count}/{total} tracker sub-issues ({failure_count} failures)."
if failure_count > 0:
    display: "Failed subtasks can be linked manually or will be retried on /resume-ticket."
```

**Why not block on ANY failure?** The accumulator pattern's core insight is that tracker issue creation is an infrastructure side-effect, not a code-correctness gate. A subtask can execute perfectly fine without a tracker issue. Blocking the entire pipeline because one MCP call timed out would be disproportionate.

**Why not retry individual failures?** Retries add complexity and are unlikely to help. If the MCP call failed due to auth issues, retrying immediately will fail again. If it failed due to a transient network error, the next pipeline resume will pick it up via the idempotency guard. The simplest retry strategy is "try again later" — which `/resume-ticket` already provides for free.

**Commit gating:** The `if success_count > 0` guard prevents an empty commit when all creations fail. If everything fails, the YAML is unchanged (all `tracker_issue_id` remain null), so there is nothing to commit.

**State.json update:** After the commit (or after the loop if no commit), update `state.json` with the tracker_issue_ids for all successful subtasks. This dual-write (YAML + state.json) follows the existing pattern per RQ-5.

### Rating

| Dimension | Score | Rationale |
|-----------|-------|-----------|
| Simplicity | 5 | Direct translation of scaffold Step 4e's accumulator; no new patterns |
| Consistency | 5 | Identical pattern to the existing precedent — same display format, same WARN behavior |
| UX | 5 | User sees clear summary; partial progress is preserved; resume handles the rest |
| Maintainability | 5 | No special error recovery paths, no retry logic, no compensating transactions |

### Key Risk

If ALL creations fail (e.g., MCP server is down), the user sees "Created 0/N tracker sub-issues (N failures)" and the pipeline continues to execute subtasks without tracker visibility. This is acceptable — the code execution does not depend on tracker issues. But the user might not notice the warning in a long pipeline output. Mitigation: if `success_count == 0 AND total > 0`, display the warning with elevated emphasis (e.g., prefix with `WARN:` and suggest running `/ceos-agents:check-setup` to diagnose the tracker connection).

---

## Summary of Recommendations

| Area | Recommendation | Novelty Level |
|------|---------------|---------------|
| 1. Step Placement | Insert between decomposition decision and execution loop (5a / 4b-tracker / 3b-tracker) | Zero — matches research consensus |
| 2. GitHub/Gitea Checklist | Table in parent issue body under `## Decomposition Plan` heading; status updates during execution | Low — body manipulation is standard; table over checkboxes is the opinionated choice |
| 3. Shared vs Inline | Inline in each skill; no new core file | Zero — follows existing decomposition pattern |
| 4. Idempotence | YAML-first with per-subtask `tracker_issue_id` write; crash recovery via on-disk YAML read | Zero — mirrors `commit_hash` write-back pattern |
| 5. Config Key | `Create tracker subtasks \| enabled` in Decomposition section | Zero — follows config conventions exactly |
| 6. Partial Failure | Accumulator pattern identical to scaffold Step 4e | Zero — direct reuse of proven pattern |

**Overall theme:** Every recommendation reuses an existing pattern. No new abstractions, no new files (beyond the skill edits), no new resume logic. The conservative path is also the simplest path — the codebase already has all the building blocks.
