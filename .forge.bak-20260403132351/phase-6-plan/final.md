# Phase 6: Implementation Plan

## Task Decomposition

All 4 tasks are INDEPENDENT and can be executed in parallel (no dependencies between them). However, Tasks 1-3 all modify `skills/scaffold/SKILL.md` in different sections, so parallel execution with worktrees is recommended to avoid merge conflicts.

### Task 1: Fix Story Sub-Issue Linking (REQ-1)
**File:** `skills/scaffold/SKILL.md`
**Section:** Step 4e, line 533-536
**Action:** Replace the vague "using the tracker's native parent parameter" text with:
1. An inline table of tracker-specific parent parameters (4 rows: YouTrack, Jira, Linear, Redmine)
2. A verification sub-step that reads back the created issue to confirm parent is set
3. A language fidelity instruction (item e) before the "Track the result" item

**Exact replacement:**
- Find: `- **If tracker supports native sub-issues** (YouTrack, Jira, Linear, Redmine — see Sub-Issue Capabilities in \`docs/reference/trackers.md\`): create sub-issue with parent set to epic issue ID using the tracker's native parent parameter`
- Replace with the inline table and verification sub-step from design.md Change 1
- Also add language fidelity item (e) from design.md Change 4b after story iteration

**Estimated lines:** +14

### Task 2: Fix Story Closing (REQ-2)
**File:** `skills/scaffold/SKILL.md`
**Section:** Step 8b, transition logic items 3a-3d and item 5
**Action:** Replace tracker-type branching with unified close-all logic:
1. Remove items 3b (GitHub/Gitea only close) and 3c (cascade assumption)
2. Replace with: close all story issues individually for ALL tracker types
3. Add idempotency guard: if issue already in Done state, treat as success
4. Update display line to include story count

**Exact replacement:**
- Find the 6-line block (items 3a through 5) starting with "For each fully-completed epic:"
- Replace with the unified close logic from design.md Change 2

**Estimated lines:** +6/-6

### Task 3: Add Implementation Comments (REQ-3)
**File:** `skills/scaffold/SKILL.md`
**Section:** Between Step 8 (E2E Tests) and Step 8b (Close Tracker Issues)
**Action:** Insert new Step 8a:
1. Guard clause (same as Step 8b)
2. For each completed epic: post `[ceos-agents]` prefixed comment with feature list, branch, story count
3. WARN on failure, never block
4. Update Step 9 report to include comment count

**Exact insertion point:** After line ending with "If no E2E Test section → skip." and before "### Step 8b:"

**Estimated lines:** +22 (Step 8a) + 1 (Step 9 update)

### Task 4: Add Language Fidelity Constraint (REQ-4)
**File:** `agents/spec-writer.md`
**Section:** Constraints (after last constraint)
**Action:** Add one NEVER constraint about diacritics preservation

**Exact insertion:** After the last constraint bullet in spec-writer.md, add:
```
- NEVER transliterate, remove, or replace diacritics or non-ASCII characters from user-provided content — preserve Czech, Slovak, German, and all other Unicode characters exactly as provided in project descriptions, epic titles, story titles, and acceptance criteria
```

**Estimated lines:** +1

## Execution Strategy

**Recommended:** Execute Tasks 1-3 sequentially (same file, different sections) then Task 4 independently.

| Order | Task | File | Conflict risk |
|-------|------|------|---------------|
| 1 | Task 2 (Story closing) | SKILL.md Step 8b | None |
| 2 | Task 3 (Comments) | SKILL.md new Step 8a | None (insertion) |
| 3 | Task 1 (Story linking) | SKILL.md Step 4e | None (different section) |
| 4 | Task 4 (Diacritics) | spec-writer.md | None (different file) |

Tasks 1-3 are ordered to work from the bottom of SKILL.md upward, avoiding line number shifts affecting later edits.

## Verification

After all tasks complete:
1. Run `./tests/harness/run-tests.sh` to verify no test regressions
2. Manually verify each change matches the design.md specification
3. Grep for removed text to confirm old patterns are gone:
   - `grep "typically cascades" skills/scaffold/SKILL.md` → should return nothing
   - `grep "Do NOT explicitly close story" skills/scaffold/SKILL.md` → should return nothing
   - `grep "using the tracker's native parent parameter" skills/scaffold/SKILL.md` → should return nothing
