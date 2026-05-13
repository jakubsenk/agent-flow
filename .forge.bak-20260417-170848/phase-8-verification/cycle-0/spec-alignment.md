# Spec Alignment Review — v6.7.2 Cycle 0

**Reviewer:** spec-alignment-agent
**Date:** 2026-04-16
**Spec source:** `.forge/phase-4-spec/final/formal-criteria.md` (12 ACs)

## Per-AC Verdicts

### AC-1: Core Contract Structure
**PASS**

`core/tracker-subtask-creator.md` exists. Headings in order: `## Purpose` (L3), `## Input Contract` (L7), `## Process` (L21), `## Output Contract` (L196), `## Failure Handling` (L204). All five required headings present and in correct order. Additional headings (`Per-Tracker Issue Creation Parameters`, `Issue Description Template`) appear between Process and Output Contract as sub-sections of the process, which is acceptable.

### AC-2: Input Contract Completeness
**PASS**

Input Contract table (L9-L19) has exactly 9 data rows (excluding header and separator), 3 columns (Field, Type, Notes). All 9 required fields present: `issue_id`, `tracker_type`, `tracker_project`, `tracker_effective_status`, `decomposition_decision`, `create_tracker_subtasks_config`, `subtask_list`, `yaml_path`, `state_json_path`.

### AC-3: Caller Delegation Stubs
**PASS**

All three callers contain the correct delegation pattern:

| Caller | Step | Ref to core contract | 9 values listed | No `FOR EACH subtask` | No `MCP Tool Pattern` | No `{subtask.scope}` |
|--------|------|---------------------|-----------------|----------------------|----------------------|---------------------|
| `skills/fix-ticket/SKILL.md` | 4b-tracker (L207-211) | YES | YES | YES (0 matches) | YES (0 matches) | YES (0 matches) |
| `skills/fix-bugs/SKILL.md` | 3b-tracker (L224-228) | YES | YES | YES (0 matches) | YES (0 matches) | YES (0 matches) |
| `skills/implement-feature/SKILL.md` | 5a (L266-270) | YES | YES | YES (0 matches) | YES (0 matches) | YES (0 matches) |

### AC-4: No Inline curl in implement-feature
**PASS**

`grep -c "curl" skills/implement-feature/SKILL.md` returns 0 matches. Step 10a delegates to `core/post-publish-hook.md` (L441) with no inline curl.

### AC-5: fix-bugs Step 8b Is Pointer Only
**PASS**

Step 8b (L432-434) contains:
- Reference to `core/post-publish-hook.md`: YES (L434)
- Reference to `step 8a`: YES (L434: "invoked in step 8a above")
- No `curl`: PASS (curl only appears at L478 in step 9a, outside step 8b range)
- No `"event"`: PASS (`"event"` only appears at L479 in step 9a, outside step 8b range)

### AC-6: fix-bugs Step X Has Exactly 4 Skill-Specific Items
**PASS**

Step X (L483-493, before `## Worktree processing` at L495):
- Contains `core/block-handler.md`: YES (L485)
- Contains `Skill-specific context`: YES (L487)
- Exactly 4 top-level bullet points:
  1. L488: Rollback execution context (worktree/CWD)
  2. L489: State path
  3. L490: Block counter logic
  4. L493: Continue with next bug
- No numbered steps `1.` through `6.`: PASS
- No `curl`: PASS

### AC-7: implement-feature Step X Is <= 5 Lines
**PASS**

Step X (L460-464, before `## Rules` at L466):
- Non-blank lines: 3 (`### X. Block handler`, `Follow core/block-handler.md...`, `Update state.json...`)
- Contains `core/block-handler.md`: YES (L462)
- Contains `state.json`: YES (L464)
- <= 5 non-blank lines: YES (3 lines)

### AC-8: fix-verification.md Mode-Neutral Language
**FAIL**

| Check | Expected | Actual | Result |
|-------|----------|--------|--------|
| `grep "Fix verified"` returns 0 | 0 matches | 0 matches | PASS |
| `grep "Fix verification failed"` returns 0 | 0 matches | 1 match (L30) | **FAIL** |
| `grep "confirm the fix works"` returns 0 | 0 matches | 0 matches | PASS |
| `grep "Verified"` returns >= 1 | >= 1 | 1 match (L21) | PASS |
| `grep "Verification failed"` returns >= 1 | >= 1 | 1 match (L26) | PASS |
| `grep "confirm the changes work"` returns >= 1 | >= 1 | 1 match (L5) | PASS |

**Detail:** The comment template on L26 was correctly updated to `"Verification failed"`, but the Display message on L30 still reads `"Fix verification failed. Issue re-opened."`. The AC spec requires zero occurrences of `"Fix verification failed"` anywhere in the file. This is a residual instance that was missed during the mode-neutral language update.

**Fix:** Change L30 from `Display: "Fix verification failed. Issue re-opened."` to `Display: "Verification failed. Issue re-opened."`.

### AC-9: state-manager.md Inline Heuristic
**PASS**

- `grep "resume-ticket" core/state-manager.md` returns 0 matches: PASS
- `grep "PUBLISHED"` returns >= 1: PASS (L46)
- `grep "POST_TRIAGE"` returns >= 1: PASS (L51)
- Heuristic table (L44-51) has exactly 6 data rows: `PUBLISHED`, `DECOMPOSE_PARTIAL`, `POST_REVIEW`, `POST_FIX`, `POST_ANALYSIS`, `POST_TRIAGE`. PASS.
- Contains `(no AC list, no iteration counts)` qualifier (L53): PASS.

### AC-10: e2e_test Schema Parity
**PASS**

JSON example (L104-109) contains `"verdict": null`, `"result_path": null`, `"attempts": 0` inside the `"e2e_test"` block.

Field definition table (L228-232) contains:
- `e2e_test.status` (L229)
- `e2e_test.verdict` (L230)
- `e2e_test.result_path` (L231)
- `e2e_test.attempts` (L232)

All three required fields (`verdict`, `result_path`, `attempts`) present in both locations. PASS.

### AC-11: fixer-reviewer-loop.md Lists All 3 Callers
**PASS**

Line 44 contains all three caller references in the NEEDS_DECOMPOSITION section:
- `skills/fix-ticket/SKILL.md` step 5: YES
- `skills/fix-bugs/SKILL.md` step 4: YES
- `skills/implement-feature/SKILL.md` step 6b: YES

### AC-12: CLAUDE.md Core Contract Count
**PASS**

- `grep "15 shared pipeline pattern contracts" CLAUDE.md` returns 1 match (L27): PASS
- `grep "14 shared pipeline pattern contracts" CLAUDE.md` returns 0 matches: PASS
- Actual count of files in `core/*.md`: 15 (verified via glob). Consistent.

## Summary

| AC | Title | Verdict |
|----|-------|---------|
| AC-1 | Core Contract Structure | PASS |
| AC-2 | Input Contract Completeness | PASS |
| AC-3 | Caller Delegation Stubs | PASS |
| AC-4 | No Inline curl in implement-feature | PASS |
| AC-5 | fix-bugs Step 8b Is Pointer Only | PASS |
| AC-6 | fix-bugs Step X Has Exactly 4 Skill-Specific Items | PASS |
| AC-7 | implement-feature Step X Is <= 5 Lines | PASS |
| AC-8 | fix-verification.md Mode-Neutral Language | **FAIL** |
| AC-9 | state-manager.md Inline Heuristic | PASS |
| AC-10 | e2e_test Schema Parity | PASS |
| AC-11 | fixer-reviewer-loop.md Lists All 3 Callers | PASS |
| AC-12 | CLAUDE.md Core Contract Count | PASS |

**Result: 11/12 PASS, 1/12 FAIL**

## Score

**spec_alignment: 0.92**

Rationale: 11 of 12 acceptance criteria fully satisfied. The single failure (AC-8) is a minor residual — one Display message on L30 of `core/fix-verification.md` still contains "Fix verification failed" when it should read "Verification failed". The fix is a single-word deletion. All structural, delegation, deduplication, and documentation criteria are met.

## Required Fix

1. **`core/fix-verification.md` L30:** Change `Display: "Fix verification failed. Issue re-opened."` to `Display: "Verification failed. Issue re-opened."`
