# Phase 6: Implementation Plan

## Task Decomposition

5 independent tasks, all can be executed in parallel (no dependencies between them).

### Task 1: Fix Story Sub-Issue Linking (Issue #2)
**File:** `skills/scaffold/SKILL.md`
**Scope:** Step 4e story creation block (lines ~530-535)
**Changes:**
- Replace the vague "using the tracker's native parent parameter" with explicit per-tracker parameter names
- Add inline table: YouTrack=`parent`, Jira=`parent`+`issuetype: "Sub-task"`, Linear=`parentId`, Redmine=`parent_issue_id`
- Add a post-creation verification note: if story was created but parent link is missing, log a WARN
**Estimated lines changed:** ~15
**Risk:** LOW

### Task 2: Fix Story Closing / Remove Cascade Assumption (Issue #3)
**File:** `skills/scaffold/SKILL.md`
**Scope:** Step 8b transition logic (lines ~740-746)
**Changes:**
- Remove line 743 ("For trackers with native sub-issues... closing the parent epic typically cascades to children. Do NOT explicitly close story sub-issues.")
- Replace with unified logic: "For ALL tracker types: explicitly close each story sub-issue by reading story IDs from back-reference comments and transitioning each to Done"
- Merge the GitHub/Gitea explicit-close logic with the general case
**Estimated lines changed:** ~12
**Risk:** LOW

### Task 3: Add Implementation Comments Step (Issue #4)
**File:** `skills/scaffold/SKILL.md`
**Scope:** Insert new Step 8a between Step 8 (E2E) and Step 8b (Close)
**Changes:**
- Add new section "### Step 8a: Post Implementation Comments"
- Guard clause (same as 8b: tracker ready + writable + issues exist)
- For each story with a back-reference ID: post comment with implementation summary
- For each epic: post comment with overall summary
- Comment format: `[ceos-agents] Implementation completed. Subtask: {title}. Files: {list}. Commit: {hash}.`
- Epic comment format: `[ceos-agents] Epic implementation completed. Stories implemented: {N}/{M}. Blocked: {list if any}.`
**Estimated lines changed:** ~35
**Risk:** LOW

### Task 4: Improve Design Quality Instructions (Issue #1)
**Files:** `agents/spec-writer.md`, `agents/scaffolder.md`
**Scope:** spec-writer Process section, scaffolder Batch list
**Changes in spec-writer.md:**
- Add step in Process (after step 3, before step 4): for web/frontend/fullstack projects, include a "Design & UX" section in `spec/README.md` covering CSS framework, color palette, typography, layout, responsive breakpoints
- Add to Constraints: "For web projects, NEVER skip the Design & UX section"
**Changes in scaffolder.md:**
- Add new "Batch 1b — Design System" (after Batch 1, before Batch 2): CSS framework setup (e.g., Tailwind config), global stylesheet with design tokens, base layout component
- Condition: only when spec includes a Design & UX section OR stack includes a web framework
- Add scorecard check: "Design system: CSS framework configured? Base styles present?"
**Estimated lines changed:** ~30 across both files
**Risk:** LOW

### Task 5: Add Language Fidelity Constraint (Issue #5)
**Files:** `agents/spec-writer.md`, `skills/scaffold/SKILL.md`
**Scope:** spec-writer Constraints section, scaffold Step 4e
**Changes in spec-writer.md:**
- Add constraint: "NEVER strip or simplify diacritics, accents, or non-ASCII characters from user input. Preserve exact characters in all spec content (e.g., Czech 'uzivatel' must remain 'uzivatel', not 'uzivatel')."
**Changes in scaffold SKILL.md:**
- Add instruction in Step 4e before issue creation: "Language fidelity: when creating tracker issues, preserve all diacritics and special characters from the spec content exactly. Never simplify non-ASCII characters."
**Estimated lines changed:** ~8 across both files
**Risk:** LOW

## Dependency Graph

```
Task 1 ──┐
Task 2 ──┤
Task 3 ──┼── All independent, can run in parallel
Task 4 ──┤
Task 5 ──┘
```

## Execution Strategy
- **Parallelization:** All 5 tasks are independent (different sections of different files, or non-overlapping sections of the same file)
- **Commit strategy:** Single commit with all 5 fixes (they form a coherent patch)
- **Verification:** Run `./tests/harness/run-tests.sh` after all edits
