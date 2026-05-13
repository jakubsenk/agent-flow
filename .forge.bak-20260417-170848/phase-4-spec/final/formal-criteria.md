# Formal Acceptance Criteria — v6.7.2 Pipeline Consistency & Dedup

12 machine-checkable acceptance criteria. Each criterion includes a verification method.

---

## AC-1: Core Contract Structure

**Criterion:** `core/tracker-subtask-creator.md` exists and follows the Purpose / Input Contract / Process / Output Contract / Failure Handling section order.

**Verification:** File exists. Headings in order: `## Purpose`, `## Input Contract`, `## Process`, `## Output Contract`, `## Failure Handling`. All five headings present.

---

## AC-2: Input Contract Completeness

**Criterion:** `core/tracker-subtask-creator.md` Input Contract table contains exactly 9 rows (excluding header) with 3 columns (Field, Type, Notes). Fields: `issue_id`, `tracker_type`, `tracker_project`, `tracker_effective_status`, `decomposition_decision`, `create_tracker_subtasks_config`, `subtask_list`, `yaml_path`, `state_json_path`.

**Verification:** Parse the Input Contract table. Row count == 9. Column count == 3. All 9 field names present.

---

## AC-3: Caller Delegation Stubs

**Criterion:** All three callers' tracker subtask steps contain exactly the delegation pattern: a reference to `core/tracker-subtask-creator.md` and a list of 9 required in-memory values. No inline pseudocode, no Per-Tracker table, no Issue Description Template.

**Verification:**
- `skills/fix-ticket/SKILL.md` step 4b-tracker: contains `core/tracker-subtask-creator.md`, lists 9 values, does NOT contain `FOR EACH subtask`, does NOT contain `MCP Tool Pattern` table header, does NOT contain `{subtask.scope}` template.
- `skills/fix-bugs/SKILL.md` step 3b-tracker: same checks.
- `skills/implement-feature/SKILL.md` step 5a: same checks.

---

## AC-4: No Inline curl in implement-feature

**Criterion:** `skills/implement-feature/SKILL.md` contains zero occurrences of the string `curl`.

**Verification:** `grep -c "curl" skills/implement-feature/SKILL.md` returns 0.

---

## AC-5: fix-bugs Step 8b Is Pointer Only

**Criterion:** `skills/fix-bugs/SKILL.md` step 8b contains a reference to `core/post-publish-hook.md` and step 8a, and does NOT contain a `curl` command or inline webhook JSON payload.

**Verification:** The text between `### 8b.` and the next `###` heading contains `core/post-publish-hook.md` and `step 8a`, does NOT contain `curl`, does NOT contain `"event"`.

---

## AC-6: fix-bugs Step X Has Exactly 4 Skill-Specific Items

**Criterion:** `skills/fix-bugs/SKILL.md` step X contains a delegation to `core/block-handler.md` followed by a `Skill-specific context` section with exactly 4 bullet points: (1) rollback execution context with worktree/CWD, (2) state path, (3) block counter logic, (4) continue with next bug.

**Verification:** The text between `### X.` and the next `##` heading:
- Contains `core/block-handler.md`
- Contains `Skill-specific context`
- Has exactly 4 top-level bullet points (`^- `)
- Does NOT contain numbered steps `1.` through `6.` (the old inline pattern)
- Does NOT contain `curl`

---

## AC-7: implement-feature Step X Is <= 5 Lines

**Criterion:** `skills/implement-feature/SKILL.md` step X (block handler) consists of a delegation to `core/block-handler.md` plus a state.json update reminder, totaling at most 5 non-empty lines.

**Verification:** The text between `### X.` and the next `##` heading contains at most 5 non-blank lines. Contains `core/block-handler.md`. Contains `state.json`.

---

## AC-8: fix-verification.md Mode-Neutral Language

**Criterion:** `core/fix-verification.md` contains "Verified" (not "Fix verified") in the success comment, "Verification failed" (not "Fix verification failed") in the failure comment, and "changes" (not "fix") in the Purpose line.

**Verification:**
- `grep "Fix verified" core/fix-verification.md` returns 0 matches
- `grep "Fix verification failed" core/fix-verification.md` returns 0 matches
- `grep "confirm the fix works" core/fix-verification.md` returns 0 matches
- `grep "Verified" core/fix-verification.md` returns >= 1 match
- `grep "Verification failed" core/fix-verification.md` returns >= 1 match
- `grep "confirm the changes work" core/fix-verification.md` returns >= 1 match

---

## AC-9: state-manager.md Inline Heuristic

**Criterion:** `core/state-manager.md` Resume Process section contains a 6-checkpoint heuristic table (PUBLISHED, DECOMPOSE_PARTIAL, POST_REVIEW, POST_FIX, POST_ANALYSIS, POST_TRIAGE) and does NOT contain a forward reference to `resume-ticket.md`.

**Verification:**
- `grep "resume-ticket" core/state-manager.md` returns 0 matches
- `grep "PUBLISHED" core/state-manager.md` returns >= 1 match
- `grep "POST_TRIAGE" core/state-manager.md` returns >= 1 match
- The heuristic table contains exactly 6 data rows (excluding header and separator)

---

## AC-10: e2e_test Schema Parity

**Criterion:** `state/schema.md` e2e_test section has `verdict`, `result_path`, and `attempts` fields in both the JSON example and the field definition table.

**Verification:**
- JSON example block containing `"e2e_test"` includes keys `"verdict"`, `"result_path"`, `"attempts"`
- Field definition table includes rows `e2e_test.verdict`, `e2e_test.result_path`, `e2e_test.attempts`

---

## AC-11: fixer-reviewer-loop.md Lists All 3 Callers

**Criterion:** `core/fixer-reviewer-loop.md` NEEDS_DECOMPOSITION bullet references all three callers: `skills/fix-ticket/SKILL.md`, `skills/fix-bugs/SKILL.md`, and `skills/implement-feature/SKILL.md`.

**Verification:** The line containing `NEEDS_DECOMPOSITION` also contains all three file paths (or the line + immediately following continuation lines if wrapped).

---

## AC-12: CLAUDE.md Core Contract Count

**Criterion:** `CLAUDE.md` states "15 shared pipeline pattern contracts" (not 14).

**Verification:** `grep "15 shared pipeline pattern contracts" CLAUDE.md` returns 1 match. `grep "14 shared pipeline pattern contracts" CLAUDE.md` returns 0 matches.

---

## Cross-Cutting Verification

**All existing tests pass:** After all changes are applied, `./tests/harness/run-tests.sh` exits with code 0.

**Roadmap entry exists:** `docs/plans/roadmap.md` contains a line referencing the fix-bugs YOLO latent bug.
