# Implementation Plan

## Summary

Port 4 decomposition persistence fixes from `skills/implement-feature/SKILL.md` (v6.1.8 reference) to `skills/fix-ticket/SKILL.md` and `skills/fix-bugs/SKILL.md`, document subtask object fields in `state/schema.md`, bump version to 6.1.9 with changelog and roadmap update.

## Task Graph

### task-001: Fix fix-ticket step 4b (decomposition decision persistence)
- **File:** `skills/fix-ticket/SKILL.md`
- **Depends on:** (none)
- **Parallel group:** A
- **Description:**

  Four changes to step 4b (lines 154-182):

  **Fix 1a — DISABLED path state.json write:**
  After line 156 (`If 'decompose_mode = DISABLED' → skip to step 4d (pre-fix hook).`), insert a new line:
  ```
  Update `state.json`: set `decomposition.status` to `"completed"`, `decomposition.decision` to `"SINGLE_PASS"`, `decomposition.strategy` to `null`. Follow atomic write protocol from `core/state-manager.md`.
  ```
  This matches implement-feature line 196.

  **Fix 1b — mkdir + runtime fields before YAML write:**
  Replace line 171:
  ```
  **Save task tree to `.claude/decomposition/{ISSUE-ID}.yaml`**
  ```
  with:
  ```
  **Save task tree:** Create `.claude/decomposition/` if it does not exist (`mkdir -p .claude/decomposition/`). Write the full task tree (including all subtask fields and runtime fields `status: "pending"`, `commit_hash: null`, `restore_point: null`) to `.claude/decomposition/{ISSUE-ID}.yaml`.
  ```
  This matches implement-feature line 238.

  **Fix 1c — DECOMPOSE path state.json write:**
  After the expanded "Save task tree" line (fix 1b), insert:
  ```
  Update `state.json`: set `decomposition.status` to `"completed"`, write `decomposition.decision` (`"DECOMPOSE"` or `"SINGLE_PASS"`), `decomposition.strategy`, `decomposition.subtasks` list. Follow atomic write protocol from `core/state-manager.md`.
  ```
  This matches implement-feature line 240. Place it BEFORE the "AC coverage check" block.

  **Fix 1d — AUTO->SINGLE_PASS fallthrough:**
  After the entire "AC coverage check" block (after line 182), add:
  ```
  If `decompose_mode = AUTO` and decomposition is not indicated → skip to step 4d (pre-fix hook).
  Update `state.json`: set `decomposition.status` to `"completed"`, `decomposition.decision` to `"SINGLE_PASS"`, `decomposition.strategy` to `null`. Follow atomic write protocol from `core/state-manager.md`.
  ```
  This matches implement-feature lines 242-243. Note: fix-bugs already has inline heuristics (lines 143-149) with explicit `Otherwise and decompose_mode = AUTO → SINGLE_PASS`, but fix-ticket delegates to `core/decomposition-heuristics.md` and currently has no explicit fallthrough after the DECOMPOSE block. This addition catches the case where the heuristics return SINGLE_PASS for AUTO mode.

---

### task-002: Fix fix-ticket step 4c (subtask commit persistence)
- **File:** `skills/fix-ticket/SKILL.md`
- **Depends on:** (none)
- **Parallel group:** A
- **Description:**

  Replace line 196:
  ```
  9. Commit subtask: `git add -A && git commit -m "fix({subtask-id}): {subtask-title}"`. Save commit_hash and restore_point to the task tree.
  ```
  with the expanded version matching implement-feature step 6h (lines 320-332):
  ```
  9. Commit subtask:
     ```bash
     git add -A
     git commit -m "fix({subtask-id}): {subtask-title}"
     ```
     Update the current subtask entry in `.claude/decomposition/{ISSUE-ID}.yaml`:
     - Set `status` to `"completed"`
     - Set `commit_hash` to the new commit SHA
     - Set `restore_point` to the commit SHA before this subtask (HEAD~1 or branch creation point for first subtask)

     Update `state.json`: find the matching subtask in `decomposition.subtasks` by `id`, set its `status` to `"completed"` and `commit_hash` to the new commit SHA. Follow atomic write protocol from `core/state-manager.md`.
  ```

---

### task-003: Fix fix-bugs step 3b (decomposition decision persistence)
- **File:** `skills/fix-bugs/SKILL.md`
- **Depends on:** (none)
- **Parallel group:** A
- **Description:**

  Four changes to step 3b (lines 133-171):

  **Fix 3a — DISABLED path state.json write:**
  After line 139 (`If 'decompose_mode = DISABLED' → skip to step 3d (pre-fix hook).`), insert:
  ```
  Update `state.json`: set `decomposition.status` to `"completed"`, `decomposition.decision` to `"SINGLE_PASS"`, `decomposition.strategy` to `null`. Follow atomic write protocol from `core/state-manager.md`.
  ```

  **Fix 3b — mkdir + runtime fields before YAML write:**
  Replace line 160:
  ```
  **Save task tree to `.claude/decomposition/{ISSUE-ID}.yaml`**
  ```
  with:
  ```
  **Save task tree:** Create `.claude/decomposition/` if it does not exist (`mkdir -p .claude/decomposition/`). Write the full task tree (including all subtask fields and runtime fields `status: "pending"`, `commit_hash: null`, `restore_point: null`) to `.claude/decomposition/{ISSUE-ID}.yaml`.
  ```

  **Fix 3c — DECOMPOSE path state.json write:**
  After the expanded "Save task tree" line (fix 3b), insert:
  ```
  Update `state.json`: set `decomposition.status` to `"completed"`, write `decomposition.decision` (`"DECOMPOSE"` or `"SINGLE_PASS"`), `decomposition.strategy`, `decomposition.subtasks` list. Follow atomic write protocol from `core/state-manager.md`.
  ```
  Place it BEFORE the "AC coverage check" block.

  **Fix 3d — AUTO->SINGLE_PASS fallthrough state.json write:**
  fix-bugs step 3b already has an explicit AUTO->SINGLE_PASS in the heuristics (line 148: `Otherwise and decompose_mode = AUTO → SINGLE_PASS (skip to step 3d)`). Insert the state.json write immediately after this line:
  ```
  Update `state.json`: set `decomposition.status` to `"completed"`, `decomposition.decision` to `"SINGLE_PASS"`, `decomposition.strategy` to `null`. Follow atomic write protocol from `core/state-manager.md`.
  ```
  Note: This means the write goes right after line 148, before line 149. The FORCE fallthrough (line 149) does not need a SINGLE_PASS write because it always goes to DECOMPOSE.

---

### task-004: Fix fix-bugs step 3c (subtask commit persistence)
- **File:** `skills/fix-bugs/SKILL.md`
- **Depends on:** (none)
- **Parallel group:** A
- **Description:**

  Replace line 185:
  ```
  9. Commit subtask: `git add -A && git commit -m "fix({subtask-id}): {subtask-title}"`. Save commit_hash and restore_point to the task tree.
  ```
  with the expanded version matching implement-feature step 6h:
  ```
  9. Commit subtask:
     ```bash
     git add -A
     git commit -m "fix({subtask-id}): {subtask-title}"
     ```
     Update the current subtask entry in `.claude/decomposition/{ISSUE-ID}.yaml`:
     - Set `status` to `"completed"`
     - Set `commit_hash` to the new commit SHA
     - Set `restore_point` to the commit SHA before this subtask (HEAD~1 or branch creation point for first subtask)

     Update `state.json`: find the matching subtask in `decomposition.subtasks` by `id`, set its `status` to `"completed"` and `commit_hash` to the new commit SHA. Follow atomic write protocol from `core/state-manager.md`.
  ```

---

### task-005: Document subtask object fields in state/schema.md
- **File:** `state/schema.md`
- **Depends on:** (none)
- **Parallel group:** A
- **Description:**

  In the Top-Level Field Definitions table, expand the `decomposition.subtasks` row (line 188). Currently it reads:
  ```
  | `decomposition.subtasks` | object[] | No | `[]` | List of subtask objects (mirrors decomposition YAML). |
  ```
  Change the description to:
  ```
  | `decomposition.subtasks` | object[] | No | `[]` | List of subtask objects (mirrors decomposition YAML). See Subtask Object Fields below. |
  ```

  Then, after the `decomposition.strategy` row (line 189) and before the `test` object row (line 190), insert a new subsection:

  ```markdown
  ### Subtask Object Fields

  Each entry in `decomposition.subtasks[]` has the following structure:

  | Field | Type | Required | Default | Description |
  |-------|------|----------|---------|-------------|
  | `id` | string | Yes | — | Subtask identifier from architect task tree (e.g., `"subtask-1"`). |
  | `title` | string | Yes | — | Human-readable subtask title. |
  | `status` | string | Yes | `"pending"` | Subtask execution status: `pending`, `in_progress`, `completed`, `failed`, `blocked`. |
  | `commit_hash` | string or null | No | `null` | Git SHA of the commit created after successful subtask execution. Null while pending. |
  | `restore_point` | string or null | No | `null` | Git SHA before subtask execution started (HEAD~1 or branch creation point for first subtask). Used for per-subtask rollback. |
  | `depends_on` | string[] | No | `[]` | IDs of prerequisite subtasks that must complete before this one starts. |
  | `scope` | string | No | `null` | Description of the subtask's scope from architect output. |
  | `files` | string[] | No | `[]` | List of file paths this subtask will modify. |
  | `estimated_lines` | integer or null | No | `null` | Estimated lines changed by this subtask. |
  | `acceptance_criteria` | string[] | No | `[]` | Per-subtask acceptance criteria from architect decomposition. |
  | `maps_to` | string[] | No | `[]` | Parent AC references in format `AC-{N}: {text}`, linking subtask to parent acceptance criteria by index. |
  ```

  This matches the runtime fields written by implement-feature step 5 (Save task tree) and step 6h (Commit subtask), and now being ported to fix-ticket/fix-bugs.

---

### task-006: Version bump (plugin.json + marketplace.json)
- **Files:** `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`
- **Depends on:** task-001, task-002, task-003, task-004, task-005
- **Parallel group:** B
- **Description:**

  In `.claude-plugin/plugin.json` (line 4): change `"version": "6.1.8"` to `"version": "6.1.9"`.

  In `.claude-plugin/marketplace.json` (line 10): change `"version": "6.1.8"` to `"version": "6.1.9"`.

---

### task-007: Add CHANGELOG.md entry for v6.1.9
- **File:** `CHANGELOG.md`
- **Depends on:** task-001, task-002, task-003, task-004, task-005
- **Parallel group:** B
- **Description:**

  Insert the following block BEFORE the `## [6.1.8]` line (before line 10):

  ```markdown
  ## [6.1.9] — 2026-04-03

  **PATCH** — Port decomposition persistence fixes from implement-feature to fix-ticket and fix-bugs pipelines. Document subtask object schema.

  ### Fixed
  - **fix-ticket Step 4b:** Added missing `state.json` writes for decomposition decision — `--no-decompose` (DISABLED) path, DECOMPOSE path, and AUTO->SINGLE_PASS fallthrough now all persist `decomposition.status`, `decomposition.decision`, and `decomposition.strategy`. Added `mkdir -p .claude/decomposition/` before first YAML write. Expanded "Save task tree" with runtime field initialization (`status: "pending"`, `commit_hash: null`, `restore_point: null`).
  - **fix-ticket Step 4c:** Replaced one-liner subtask commit with explicit per-subtask persistence — sets `status: "completed"`, `commit_hash`, `restore_point` in both `.claude/decomposition/{ISSUE-ID}.yaml` and `state.json` `decomposition.subtasks[N]`.
  - **fix-bugs Step 3b:** Same 4 decomposition decision persistence fixes as fix-ticket Step 4b.
  - **fix-bugs Step 3c:** Same subtask commit persistence fix as fix-ticket Step 4c.

  ### Added
  - **state/schema.md:** New "Subtask Object Fields" subsection documenting all 11 fields within `decomposition.subtasks[]` objects (`id`, `title`, `status`, `commit_hash`, `restore_point`, `depends_on`, `scope`, `files`, `estimated_lines`, `acceptance_criteria`, `maps_to`).

  ```

---

### task-008: Move roadmap item from PLANNED to DONE
- **File:** `docs/plans/roadmap.md`
- **Depends on:** task-001, task-002, task-003, task-004, task-005
- **Parallel group:** B
- **Description:**

  1. Remove the "Decomposition Persistence Parity" block from the "PLANNED -- Next" section (lines 322-334). The block starts with `### Decomposition Persistence Parity — v6.1.9 (fix-ticket + schema)` and ends before the next `---` separator.

  2. Add a new "DONE -- v6.1.9" section BEFORE the "PLANNED -- Next" section (after the `## DONE -- v6.0.0` section's closing `---`). Content:

  ```markdown
  ## DONE — v6.1.9 (Decomposition Persistence Parity)

  ### Decomposition Persistence Parity
  **Source:** forge pipeline analysis (2026-04-03), implement-feature bugfix (v6.1.8)

  Ported 4 persistence fixes from `implement-feature/SKILL.md` to `fix-ticket/SKILL.md` and `fix-bugs/SKILL.md`:
  1. SINGLE_PASS state.json write for `--no-decompose` (DISABLED) path
  2. AUTO->SINGLE_PASS fallthrough state.json write
  3. `mkdir -p .claude/decomposition/` before YAML write + runtime field initialization
  4. Explicit per-subtask `status`, `commit_hash`, `restore_point` in both YAML and state.json

  Also documented all 11 subtask object fields in `state/schema.md`.

  **Files:** `skills/fix-ticket/SKILL.md`, `skills/fix-bugs/SKILL.md`, `state/schema.md`

  ---
  ```

  3. Also update the roadmap header version from `v5.7.0` to `v6.1.9` (line 3) and the "Last updated" date to `2026-04-03` (line 4). These are cosmetic but keep the file accurate.

---

## Parallel Execution Summary

| Group | Tasks | Files | Can run simultaneously |
|-------|-------|-------|----------------------|
| **A** | task-001, task-002, task-003, task-004, task-005 | fix-ticket/SKILL.md, fix-bugs/SKILL.md, state/schema.md | Yes (all independent files) |
| **B** | task-006, task-007, task-008 | plugin.json, marketplace.json, CHANGELOG.md, roadmap.md | Yes (all independent files; depend on group A completing) |

Note: task-001 and task-002 both modify `fix-ticket/SKILL.md` but at different locations (step 4b vs step 4c). They can be handled by a single agent in sequence, or task-002 can depend on task-001 if each agent handles exactly one file. For parallel subagent execution, assign task-001+task-002 to one agent and task-003+task-004 to another.

## Dependency Graph

```
task-001 ──┐
task-002 ──┤
task-003 ──┼──→ task-006 (version bump)
task-004 ──┤    task-007 (changelog)
task-005 ──┘    task-008 (roadmap)
```
