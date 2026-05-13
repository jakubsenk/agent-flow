# Implementation Plan

Target file: `skills/implement-feature/SKILL.md`

All four gaps address subtask persistence failures in the decomposition path. The fixes are scoped exclusively to `skills/implement-feature/SKILL.md`. Because all tasks edit the same file, they execute sequentially.

## Task List

### Task 1: SINGLE_PASS path — write decomposition state
- **File:** `skills/implement-feature/SKILL.md`
- **Location:** Line 193 (Step 5, first branch)
- **Current text:**
  ```
  If `decompose_mode = DISABLED` → single-pass (step 6 directly).
  ```
- **Change:** After this line, add a `state.json` update that sets `decomposition.status` to `"completed"`, `decomposition.decision` to `"SINGLE_PASS"`, and `decomposition.strategy` to `null`. This mirrors the state update already present at line 237 for the DECOMPOSE path but was entirely missing for the DISABLED/SINGLE_PASS shortcut.
- **New text concept:**
  ```
  If `decompose_mode = DISABLED` → single-pass (step 6 directly).
  Update `state.json`: set `decomposition.status` to `"completed"`, `decomposition.decision` to `"SINGLE_PASS"`, `decomposition.strategy` to `null`. Follow atomic write protocol from `core/state-manager.md`.
  ```
- **Why:** Gap 2. When decomposition is disabled (or AUTO resolves to single-pass), `decomposition.status` stays `"pending"` and `decomposition.decision` stays `null` forever. The `depends_on` check in Step 6 and the `/resume-ticket` state reader have no reliable data source to determine the pipeline took the single-pass path. Additionally, the `state.json` would be inconsistent with the actual pipeline progress.
- **Depends on:** none
- **Risk:** low — additive text, no behavioral change to existing paths

### Task 2: SINGLE_PASS path for AUTO — write decomposition state
- **File:** `skills/implement-feature/SKILL.md`
- **Location:** Line 194 (Step 5, second branch — FORCE/AUTO)
- **Current text:**
  ```
  If `decompose_mode = FORCE` or `decompose_mode = AUTO` and architect indicates decomposition:
  ```
- **Change:** This line only describes the DECOMPOSE outcome. After the entire Step 5 block (line 237), there is no handling for the case where `decompose_mode = AUTO` and the architect does NOT indicate decomposition (i.e., the heuristic returns SINGLE_PASS). Add an explicit else-branch after the `state.json` update at line 237 that handles the AUTO-to-SINGLE_PASS fallthrough.
- **New text concept:** After line 237 (the existing `Update state.json` for DECOMPOSE), add:
  ```
  If `decompose_mode = AUTO` and decomposition is not indicated → single-pass (step 6 directly).
  Update `state.json`: set `decomposition.status` to `"completed"`, `decomposition.decision` to `"SINGLE_PASS"`, `decomposition.strategy` to `null`. Follow atomic write protocol from `core/state-manager.md`.
  ```
- **Why:** Gap 2 (continued). The DISABLED path (Task 1) covers `--no-decompose`. This task covers the AUTO path when heuristics say no decomposition. Without this, the same state gap exists.
- **Depends on:** Task 1
- **Risk:** low — additive text, clarifies an implicit fallthrough

### Task 3: Ensure decomposition directory exists before writing task tree
- **File:** `skills/implement-feature/SKILL.md`
- **Location:** Line 235 (Step 5, "Save task tree" section)
- **Current text:**
  ```
  **Save task tree:** Write to `.claude/decomposition/{ISSUE-ID}.yaml`
  ```
- **Change:** Add an explicit `mkdir -p` instruction before the write to ensure the directory exists on first run.
- **New text concept:**
  ```
  **Save task tree:** Create directory if needed: `mkdir -p .claude/decomposition/`. Write to `.claude/decomposition/{ISSUE-ID}.yaml`.
  ```
- **Why:** Gap 4. No code in the pipeline creates `.claude/decomposition/` before writing. The first decomposition run for a repo would fail with a missing directory error.
- **Depends on:** Task 2 (line numbers may shift after Task 2 insertion)
- **Risk:** low — defensive mkdir, no-op if directory already exists

### Task 4: Per-subtask status update in Step 6h
- **File:** `skills/implement-feature/SKILL.md`
- **Location:** Lines 314-322 (Step 6h, "Commit subtask")
- **Current text:**
  ```markdown
  #### 6h. Commit subtask

  ```bash
  git add -A
  git commit -m "feat({subtask-id}): {subtask-title}"
  ```

  Save commit_hash and restore_point to the task tree.
  Update the task tree state on disk (.claude/decomposition/).
  ```
- **Change:** Replace this entire block with a fully specified version that:
  1. Records the `commit_hash` from the git commit
  2. Sets the subtask's `status` to `"completed"` in the YAML file
  3. Specifies the exact file to update: `.claude/decomposition/{ISSUE-ID}.yaml`
  4. Specifies the fields to write: `status`, `commit_hash`, `restore_point`
  5. Updates `state.json`'s `decomposition.subtasks[N].status` to `"completed"` and `decomposition.subtasks[N].commit_hash` to the hash
  6. References the atomic write protocol
- **New text concept:**
  ```markdown
  #### 6h. Commit subtask

  ```bash
  git add -A
  git commit -m "feat({subtask-id}): {subtask-title}"
  ```

  Record the commit hash: `commit_hash = $(git rev-parse HEAD)`.
  Record the restore point: `restore_point = $(git rev-parse HEAD~1)`.

  **Update task tree on disk:** In `.claude/decomposition/{ISSUE-ID}.yaml`, find the current subtask entry and set:
  - `status: "completed"`
  - `commit_hash: {commit_hash}`
  - `restore_point: {restore_point}`

  **Update `state.json`:** Set `decomposition.subtasks[N].status` to `"completed"`, `decomposition.subtasks[N].commit_hash` to `{commit_hash}`. Follow atomic write protocol from `core/state-manager.md`.
  ```
- **Why:** Gap 1 (HIGH) + Gap 3 (MEDIUM). The current text never sets subtask `status = "completed"`, never updates `state.json` decomposition subtask entries, and is underspecified about the file and field schema. The `depends_on` check at the top of Step 6 ("Verify that all depends_on have status completed") has no reliable data source because status is never written. This makes decomposed multi-subtask features with inter-subtask dependencies silently broken.
- **Depends on:** Task 3 (directory must exist)
- **Risk:** medium — this is the most complex change and touches the core execution loop. However, it is purely additive specification text.

### Task 5: Add YOLO scope documentation to preamble (minor doc gap)
- **File:** `skills/implement-feature/SKILL.md`
- **Location:** Line 11 (Input description line)
- **Current text:**
  ```
  Input: `$ARGUMENTS` = Issue ID | `--description "feature description"` + optional flags (`--decompose`, `--no-decompose`, `--dry-run`, `--profile <name>`, `--yolo`)
  ```
- **Change:** Add a YOLO mode description paragraph after line 11 (before `## Configuration`), matching the pattern used in `fix-ticket` at line 16. This clarifies what `--yolo` actually does: skip duplicate check, auto-approve decomposition, auto-approve PR display, auto-publish.
- **New text concept:**
  After the Input line, before `## Configuration`, add:
  ```
  If `$ARGUMENTS` contains `--yolo`, activate YOLO mode: skip duplicate check (--description), auto-approve decomposition plan, auto-approve result display, auto-publish after successful pipeline.
  ```
- **Why:** Bug 2 research finding. Not a functional bug, but a documentation gap — fix-ticket explicitly documents YOLO scope at the top, implement-feature does not. Users have to read through the entire file to understand what `--yolo` affects.
- **Depends on:** none (but placed last because it is lowest priority and independent of the state fixes)
- **Risk:** low — documentation only, no behavioral change

## Execution Order

1. **Task 1** — SINGLE_PASS state update for DISABLED path (line 193)
2. **Task 2** — SINGLE_PASS state update for AUTO fallthrough (after line 237)
3. **Task 3** — mkdir -p before task tree write (line 235)
4. **Task 4** — Per-subtask status + state.json update in Step 6h (lines 314-322)
5. **Task 5** — YOLO scope preamble documentation (line 11)

Tasks 1 and 5 are independent and could theoretically be parallelized, but since they edit the same file, they must be applied sequentially. The ordering above minimizes line-number drift: Tasks 1-3 edit earlier sections, Task 4 edits a later section, and Task 5 edits the earliest section but is pure insertion so line drift is trivial.

## Verification Checklist

After all tasks complete, verify:

- [ ] **Step 5 DISABLED path** (line ~193): Has a `state.json` update setting `decomposition.status = "completed"`, `decomposition.decision = "SINGLE_PASS"`
- [ ] **Step 5 AUTO-no-decompose path** (after the DECOMPOSE block): Has a parallel `state.json` update for the SINGLE_PASS outcome
- [ ] **Step 5 "Save task tree"**: Includes `mkdir -p .claude/decomposition/` before file write
- [ ] **Step 6h**: Specifies `commit_hash`, `restore_point`, and `status = "completed"` fields to write to both `.claude/decomposition/{ISSUE-ID}.yaml` and `state.json`'s `decomposition.subtasks[N]`
- [ ] **Step 6h `state.json` update**: References the atomic write protocol from `core/state-manager.md`
- [ ] **Preamble**: Contains a YOLO scope summary matching the pattern from `fix-ticket`
- [ ] **No orphan references**: All line references in the plan correspond to actual content (verify with a final re-read)
- [ ] **Consistency with fix-ticket**: The same gaps exist in `skills/fix-ticket/SKILL.md` (steps 4b, 4c line 196). Note these for a follow-up ticket but do NOT fix them in this PR to keep scope contained
- [ ] **Schema compliance**: All new `state.json` fields (`decomposition.subtasks[N].status`, `decomposition.subtasks[N].commit_hash`) are compatible with the schema in `state/schema.md` (the `decomposition.subtasks` field is typed as `object[]`, so adding fields to subtask objects is non-breaking)
- [ ] **Test harness**: Run `./tests/harness/run-tests.sh` before committing to verify no regressions

## Scope Notes

**In scope:** Only `skills/implement-feature/SKILL.md`.

**Out of scope (follow-up):**
- `skills/fix-ticket/SKILL.md` has the same gaps at steps 4b (no state update for SINGLE_PASS) and 4c line 196 (no per-subtask status update). These should be fixed in a separate PR for consistency.
- `state/schema.md` does not explicitly document subtask-level fields (`status`, `commit_hash`, `restore_point` within `decomposition.subtasks[]` objects). A schema doc update would be ideal but is non-breaking since the field is typed as `object[]`.
