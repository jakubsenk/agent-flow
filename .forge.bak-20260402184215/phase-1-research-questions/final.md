# Phase 1 Research Synthesis: Sub-Issue Creation in Scaffold Pipeline

**Sources:** agent-1 (epic markdown structure), agent-2 (tracker sub-issue APIs), agent-3 (state transitions & pipeline flow)
**Date:** 2026-04-02

---

## RQ-1: How are stories structured in epic markdown, and what maps to a sub-issue?

**Consensus across agents 1 & 3.**

Epic files follow a rigid, machine-parseable structure:

- **Epic heading:** `# Epic NN: Title` at line 1
- **Back-reference comment:** `<!-- YouTrack: {ISSUE-ID} -->` at line 2
- **Story delimiter:** `---` (bare horizontal rule) — reliable in all 6 observed epic files, every story ends with one
- **Story heading:** `### Story N.M: Title` (H3, always `Story` keyword, dot-separated numbering)
- **Story body:** user-story sentence (`**As** ... **I want** ... **so that** ...`) followed by `**Acceptance Criteria:**` bullet list

**Parsing approach:** Split on `\n---\n` to get blocks; match `### Story N.M:` to detect story blocks vs. the epic header block.

**Sub-issue mapping:**
- Title: text after `### Story N.M: ` (stripped of the heading prefix)
- Description: everything from the user-story sentence to the closing `---` (exclusive of the `---` itself)

**Evidence:** agent-1 — observed across all 6 files in `spec/epics/` of a live consuming project; `skills/scaffold/SKILL.md` Step 4e confirms "title from epic heading" pattern by analogy.

---

## RQ-2: Which trackers support native sub-issues, and what are the MCP APIs?

**Source: agent-2 exclusively** (agent-1 and agent-3 did not investigate this RQ).

| Tracker | Native Sub-Issues | Parent Parameter | Fallback Needed |
|---------|-------------------|-----------------|-----------------|
| YouTrack | Yes | `parent: {issue-id}` (inferred) | No |
| Jira | Yes | `issuetype: "Sub-task"` + `parent: {key}` | No |
| Linear | Yes | `parentId: {id}` | No |
| Redmine | Yes | `parent_issue_id: {id}` | No |
| GitHub | No | N/A | Yes |
| Gitea | No | N/A | Yes |

**Critical gap:** `docs/reference/trackers.md` has zero documentation on sub-issue capabilities or MCP tool signatures. The codebase uses a single generic "create a sub-issue under the epic issue" instruction — the LLM must guess tool names and parameters at runtime. This is a reliability risk.

**GitHub/Gitea fallback (agent-2 recommendation):**
1. Create a standalone issue per story (no parent)
2. Name it `[{epic_title}] {story_title}`
3. Apply a label to group by epic
4. Add cross-reference links in both the epic issue body and the story issue description

The current accumulator pattern in Step 4e (WARN + continue) silently swallows failures on GitHub/Gitea — the fallback is effectively "do nothing visible", which leaves incomplete tracker structure.

---

## RQ-3: Issue state transitions — what triggers them, where, and how?

**Source: agent-3 exclusively.**

### How `implement-feature` transitions state

`implement-feature` does NOT set issues to "Done". The `publisher` agent sets state to `"For Review"` (Step 7 of publisher.md). "Done" is expected to happen externally (after PR merge or manually). There is NO post-merge auto-close in the current pipeline.

### State transition syntax

State transitions live in `Automation Config → Issue Tracker → State transitions`. Per-tracker format:

| Tracker | Format | Done example |
|---------|--------|--------------|
| youtrack | `State: {name}` | `State: Done` |
| github | `close` or `add label:{name}` | `close` |
| jira | `transition:{name}` | `transition:Done` |
| linear | `state:{name}` | `state:Done` |
| gitea | `close` or `add label:{name}` | `close` |
| redmine | `status:{name}` | `status:Closed` |

### What transition is appropriate for scaffold?

Scaffold creates issues explicitly at "Open/planned" state (Step 4e: "Do NOT apply `On start set`"). After a scaffold epic is implemented and committed, the appropriate transition is **"Done"** (not "For Review" — scaffold commits directly, no per-epic PR). The scaffold rollback-agent currently skips all tracker state updates; this guard must be respected (only mark Done on success).

### "Done" key in Automation Config

"Done" is not currently a documented key in the `State transitions` table. Adding it would be a backward-compatible optional extension to the existing required section. The fix must gracefully skip the update if the key is absent (log a warning).

---

## RQ-4: Where in the scaffold pipeline should state be transitioned?

**Source: agent-3 exclusively.**

Two viable insertion points:

1. **After each batch completes** (post-batch test suite pass, end of Step 7 loop): Earliest stable point. Epics whose subtasks all reside in the completed batch can be marked Done immediately. Handles partial-failure scenarios: if pipeline stops mid-run, already-completed epics are already marked.

2. **Before Step 9 (Final Report)**: Simpler bulk update, but leaves all issues "Open" if fail-fast stops the pipeline early.

**Recommended:** After each batch (option 1) as primary; a catch-all sweep before Step 9 to handle epics whose subtasks span multiple batches.

**Prerequisite:** requires a mapping from `subtask → epic → tracker_issue_id` available at this point. Currently not persisted to disk (see RQ-5).

---

## RQ-5: How are tracker issue IDs persisted and retrieved?

**Agents 1 and 3 agree on this — no contradiction.**

### Current state

Epic tracker IDs are written back into `spec/epics/*.md` as inline HTML reference comments immediately after the `# Epic NN: Title` line:
```
<!-- YouTrack: {ISSUE-ID} -->
```

This is the ONLY canonical store of `{epic_filename → tracker_issue_id}`. They are NOT written to `state.json`, `.claude/decomposition/`, or any structured lookup.

### Story-level IDs: gap

Step 4e currently specifies writing back the **epic-level** ID only. It does not specify where story/sub-issue IDs are written back. By analogy with epic back-references, the natural placement is immediately after `### Story N.M: {title}`:
```
<!-- YouTrack: {STORY-ISSUE-ID} -->
```
This format is not yet formally defined in the skill.

### Retrieval for state transitions

To mark epics Done at batch completion, the pipeline must either:
- **(a) In-memory:** Carry `{epic_id → tracker_issue_id}` from Step 4e through Step 7 (fragile against interruption)
- **(b) File-parsing:** Re-read `spec/epics/*.md` at the completion point and extract back-references (more robust, canonical source)

**Agent-3 addition:** alternatively, persist the mapping into `state.json` during Step 4e. This would make it available for structured reads by later steps without markdown parsing.

### Test coverage gap (agent-1)

Zero tests validate sub-issue creation behavior. The only relevant test (`scaffold-v2-happy-path.sh`) is a structural presence check:
```bash
grep -q "Create Tracker Issues" "$SCAFFOLD_CMD"
```
It does not validate: story iteration, back-reference writeback format, partial failure handling, or the fallback strategy for GitHub/Gitea.

---

## Key Decisions for Fix

### 1. How to parse stories from epic markdown

Use `\n---\n` as the block delimiter. Detect story blocks by matching `### Story N.M:` heading. Extract title from the heading text (after the `: `). Extract description as everything between the heading line and the next `---` delimiter (strip the delimiter itself). This is unambiguous across all 6 observed epic files.

### 2. How to handle sub-issue creation across different trackers

- YouTrack / Jira / Linear / Redmine: use native parent/subtask API (exact MCP tool parameters are not documented — the fix should add a sub-issue capabilities table to `docs/reference/trackers.md` and add inline tracker hints to Step 4e)
- GitHub / Gitea: use the fallback strategy (standalone issue with `[{epic_title}]` prefix, epic-grouping label, cross-reference links). The current silent-fail accumulator is not an acceptable fallback — explicit branching on `tracker_type` is needed in Step 4e

### 3. Where to insert the issue state transition step

Insert at **two points** in the scaffold pipeline:
- End of each batch loop (after post-batch test suite passes) — marks epics whose subtasks are fully covered by that batch
- Before Step 9 (Final Report) — catch-all sweep for any remaining epics

Skip if `State transitions → Done` key is absent from Automation Config (log a warning). Respect the rollback-agent's existing "no tracker updates" guard.

### 4. How to persist/retrieve tracker issue IDs

- **Epic IDs:** already written to `spec/epics/*.md` as `<!-- {TrackerType}: {ID} -->` comments — re-read these files at the Done-transition step (option b, more robust)
- **Story IDs:** define the back-reference format now (`<!-- {TrackerType}: {STORY-ISSUE-ID} -->` immediately after `### Story N.M:` heading) and document it formally in Step 4e
- **Optional:** also write the `{epic_filename → issue_id}` mapping into `state.json` during Step 4e for structured access — reduces need for markdown re-parsing in later steps

### 5. What test coverage is needed

New tests (grep-based, consistent with existing scaffold test style) should verify:
- Step 4e specifies sub-issue creation with per-story iteration (not just the section heading)
- Step 4e specifies the story back-reference writeback format
- Step 4e includes a fallback branch for GitHub/Gitea (standalone issue + naming convention)
- Step 4e includes a sub-issue capabilities table or references `docs/reference/trackers.md` for per-tracker API guidance
- The Done state transition step is present in the scaffold skill (with correct insertion point)

Existing test `scaffold-v2-happy-path.sh` can be extended; a new scenario for the GitHub/Gitea fallback path is also warranted.
