# Phase 6 Plan Compliance Review — Round 1

**Reviewer:** Claude Sonnet 4.6 (Phase 6 Compliance Reviewer)
**Date:** 2026-04-27
**Artifact:** `.forge/phase-6-plan/plan.md` (1414 lines, 33 tasks T-001..T-033)
**Criteria source:** `.forge/phase-0-meta/prompts/plan.md` (9 SUCCESS_CRITERIA, 7 ANTI_PATTERNS)
**Spec inputs:** `formal-criteria.md` (94 ACs), `requirements.md`, `design.md`, `coverage-report.md`

---

## JSON Verdict

```json
{
  "tier_1": {
    "schema_valid": true,
    "requirements_traced": true,
    "no_regressions": true,
    "lint_clean": true,
    "pass": true
  },
  "tier_2": {
    "fail_to_pass": {"passed": null, "failed": null, "total": null},
    "hidden_test_gap": null,
    "mutation_score": null,
    "mutation_available": false,
    "pass": true,
    "note": "Phase 6 is a planning artifact — Tier 2 behavioral tests not applicable. Tests validated structurally against coverage-report.md."
  },
  "tier_3": {
    "correctness": 3,
    "completeness": 4,
    "security": 5,
    "maintainability": 4,
    "robustness": 3,
    "weighted_aggregate": 3.65,
    "pass": true
  },
  "overall_verdict": "PASS_WITH_FIXES",
  "confidence": 0.82,
  "findings": [
    {
      "id": "f-a1b2c3",
      "severity": "MAJOR",
      "criterion": "correctness",
      "location": "plan.md T-015 files_modified",
      "description": "T-015 lists `core/state-handler.md` in files_modified but the file does not exist. The correct filename is `core/state-manager.md` (verified by filesystem check). Phase 7 implementor will attempt to MODIFY a non-existent file.",
      "recommendation": "Change `core/state-handler.md` to `core/state-manager.md` in T-015 files_modified."
    },
    {
      "id": "f-b3c4d5",
      "severity": "MAJOR",
      "criterion": "correctness",
      "location": "plan.md T-026 files_modified vs notes",
      "description": "T-026 files_modified declares `core/agents-rename-aliases.md (NEW)` at top-level core. However, the task notes contain a CRITICAL warning: the file MUST be placed under `core/aliases/agents-rename-aliases.md` (sub-namespace) to preserve the `find core -maxdepth 1 -name '*.md' -type f | wc -l == 16` invariant (AC-CT-004). The files_modified path and the notes are contradictory. Phase 7 implementor gets conflicting instructions — if they follow files_modified, they break AC-CT-004; if they follow notes, the Phase 8 finding-to-task mapping breaks.",
      "recommendation": "Change files_modified to `core/aliases/agents-rename-aliases.md (NEW)` to match the notes. Also add T-026 to T-030's depends_on so AC-CT-004 verification runs after T-026 completes."
    },
    {
      "id": "f-c5d6e7",
      "severity": "MAJOR",
      "criterion": "correctness",
      "location": "plan.md T-015 parallelizable_with vs T-016 depends_on",
      "description": "T-015 lists `parallelizable_with: [T-016 (different files)]` suggesting these can run concurrently. However, T-016 has `depends_on: [T-015]` and `state/schema.md (T-015 output)` in files_read_only. These tasks are strictly SEQUENTIAL — T-015 cannot be parallel with T-016. Wave 7F section 5.1 also declares `sequential_within_wave: true T-015 → T-016`. The parallelizable_with field is incorrect and misleading.",
      "recommendation": "Change T-015 `parallelizable_with` to `[]`. This maintains the correct sequential relationship shown in Wave 7F."
    },
    {
      "id": "f-d7e8f9",
      "severity": "MINOR",
      "criterion": "completeness",
      "location": "plan.md T-007 acceptance_criteria_refs (and T-008 analogously)",
      "description": "T-007 (fix-bugs decomposition) only lists AC-MODE-001 and AC-MODE-MATRIX-001..003 in its individual acceptance_criteria_refs. Missing: AC-MODE-002 (default mode), AC-MODE-003 (yolo mode), AC-MODE-004 (step-mode prompt format), AC-MODE-005 (step-mode skip escape), AC-MODE-006 (abort state), AC-MODE-007 (resume), AC-MODE-008a (SIGTERM atomicity). These ACs are only mentioned in the aggregate Section 6.1 grouping. T-008 is analogously incomplete for implement-feature mode ACs. Phase 8 finding-to-task oracle uses the task-level acceptance_criteria_refs for attribution — missing refs create attribution gaps.",
      "recommendation": "Add AC-MODE-002..007 and AC-MODE-008a to T-007 acceptance_criteria_refs. Add AC-MODE-002..005 and AC-MODE-008a to T-008 acceptance_criteria_refs."
    },
    {
      "id": "f-e9f0a1",
      "severity": "MINOR",
      "criterion": "correctness",
      "location": "plan.md T-030 depends_on",
      "description": "T-030 (Cross-File Invariant atomic verification) depends_on [T-027, T-028, T-029, T-021, T-022, T-023, T-024] but is missing T-026. T-026 creates a new file under `core/` and is responsible for AC-CT-004 compliance. If T-026 runs AFTER T-030 (the wave-level ordering nominally handles this, but task-level depends_on doesn't enforce it), the AC-CT-004 core count check at T-030 may complete before T-026's file placement is known. The Section 7.6 dispatch ordering recommends completing Wave 7G before Wave 7H, but T-030 has an explicit depends_on list that should be authoritative.",
      "recommendation": "Add T-026 to T-030's depends_on list."
    },
    {
      "id": "f-f1a2b3",
      "severity": "MINOR",
      "criterion": "maintainability",
      "location": "plan.md T-031, T-032, T-033 acceptance_criteria_refs",
      "description": "Wave 7J tasks T-031, T-032, T-033 use prose strings rather than structured AC-NNN IDs in acceptance_criteria_refs. For example: `- All visible AC tests now executable from final location` (T-031), `- Hidden adversarial AC coverage (per coverage-report.md §Hidden Test Topics)` (T-032), `- Mock fixture support for AC-SETUP-002, AC-SETUP-003, AC-OVR-*, AC-MIG-*` (T-033). Phase 8 oracle reads acceptance_criteria_refs for finding-to-task attribution and expects structured AC-NNN identifiers. Wildcard patterns (`AC-OVR-*`) are also not parseable by a structured oracle.",
      "recommendation": "Replace prose entries with explicit AC-NNN lists. T-031: reference AC-NF-005 + any ACs whose tests it moves. T-032: reference the hidden-test-covered ACs explicitly. T-033: expand `AC-OVR-*` to individual AC-OVR-001..008."
    },
    {
      "id": "f-g3h4i5",
      "severity": "MINOR",
      "criterion": "maintainability",
      "location": "plan.md T-033 depends_on vs test_files_pass",
      "description": "T-033 has `depends_on: []` but its `test_files_pass` list references `tests/scenarios/v8-setup-agents-python.sh`, `tests/scenarios/v8-setup-agents-monorepo.sh`, and `tests/scenarios/v8-overlay-*.sh`. These files do not exist until T-031 moves them from `.forge/phase-5-tdd/tests/` to `tests/scenarios/`. Phase 7 will attempt to run these tests before they exist, producing spurious failures during T-033 execution.",
      "recommendation": "Add T-031 to T-033's depends_on list, or remove the test_files_pass entries from T-033 (since T-033 is a fixture creation task, not a test runner task — tests that rely on the fixtures run AFTER the fixtures exist)."
    },
    {
      "id": "f-h5i6j7",
      "severity": "MINOR",
      "criterion": "maintainability",
      "location": "plan.md T-021..T-025 parallelizable_with (range notation)",
      "description": "Several tasks use YAML range notation (`T-017..T-020`, `T-022..T-026`) inside `parallelizable_with` lists. YAML does not define a range scalar syntax — these are plain strings, not valid task ID arrays. A strict YAML parser used by Phase 7 dispatcher will see `T-017..T-020` as a single string, not as an expansion of 4 task IDs. This affects T-021, T-022, T-023, T-024, T-025 parallelizable_with fields.",
      "recommendation": "Expand all range notation to explicit individual task IDs: replace `T-017..T-020` with `T-017`, `T-018`, `T-019`, `T-020` as separate list items."
    },
    {
      "id": "f-i7j8k9",
      "severity": "MINOR",
      "criterion": "maintainability",
      "location": "plan.md T-027 acceptance_criteria_refs, T-009 acceptance_criteria_refs",
      "description": "T-027 lists `REQ-DOC-014 (content update)` in acceptance_criteria_refs (a REQ reference, not an AC reference). T-009 lists `REQ-MODE-009a (vague-heuristic boundaries)` similarly. The field is named `acceptance_criteria_refs` and should contain AC-NNN identifiers only. REQ-DOC-014 maps to AC-INV-DOC-ENUM-001 + AC-DOC-005/006/014b; REQ-MODE-009a maps to AC-MODE-009.",
      "recommendation": "Remove REQ references from acceptance_criteria_refs fields. Replace REQ-DOC-014 with the additional AC-DOC-014 if applicable. REQ-MODE-009a is already covered by AC-MODE-009."
    },
    {
      "id": "f-j9k0l1",
      "severity": "NIT",
      "criterion": "correctness",
      "location": "plan.md Section 0 Executive Summary parallelization ratio",
      "description": "Executive Summary states 23/33 = 69.7% parallelizable. Actual count of tasks with non-empty parallelizable_with is 26/33 = 78.8%. The discrepancy is because the summary excludes the 3 folded tasks (T-012/T-013/T-014) which do have non-empty parallelizable_with arrays. The real value (26/33 = 78.8%) is still well above the 50% threshold.",
      "recommendation": "Update executive summary to state 26/33 = 78.8% OR clarify 23/33 = 69.7% excludes folded tasks."
    },
    {
      "id": "f-k1l2m3",
      "severity": "NIT",
      "criterion": "completeness",
      "location": "plan.md Section 6.2 Task→AC index",
      "description": "Section 6.2 individual task rows do not list AC-NF-001, AC-NF-002, AC-NF-008 anywhere. Section 6.1 aggregate claims all NF-001..010 are covered by the task group, but the individual task-level mapping is incomplete. AC-NF-001 (v7 backward compat) is implemented in T-001 but not listed in T-001's acceptance_criteria_refs. AC-NF-002 (no build step) and AC-NF-008 (webhook backcompat) are verified by tests moved via T-031 but not explicitly in T-001/T-031 refs.",
      "recommendation": "Add AC-NF-001 to T-001's acceptance_criteria_refs (since T-001 implements REQ-OVR-006 which is the backward-compat mechanism). Add AC-NF-008 to T-031's acceptance_criteria_refs."
    }
  ]
}
```

---

## Tier 1 Assessment

### Schema/format (PASS)

All 33 tasks T-001..T-033 are present and sequential. Every task contains all required fields:
- `task_id` ✓ (T-001..T-033, verified by grep)
- `description` ✓ (one-line per task)
- `files_modified` ✓ (explicit list per task; T-012/T-013/T-014 reference parent files with "already in T-XXX" annotation)
- `files_read_only` ✓ (present in all tasks)
- `depends_on` ✓ (array, including empty arrays)
- `acceptance_criteria_refs` ✓ (present in all tasks; format issues flagged as MINOR)
- `test_files_pass` ✓ (present in all tasks)
- `estimated_complexity` ✓ (S/M/L used consistently)
- `parallelizable_with` ✓ (present in all tasks)
- `rollback_strategy` ✓ (present in all tasks, non-trivial in all cases)

**Notes on T-012/T-013/T-014 (folded tasks):** These are explicitly flagged as "OPTIONAL — folded into T-007/T-008/T-009" and Wave 7E is labeled as absorbed. The plan notes Phase 7 should mark `status=folded`. This is acceptable as a traceability mechanism; the task count of 33 includes these 3 folded handles.

### Requirements traced (PASS)

Section 6.1 and 6.2 claim 94/94 ACs mapped. Spot-check of 15 ACs (including all polish-patch ACs per review instructions):

| AC | Location in plan | Status |
|----|-----------------|--------|
| AC-OVR-008 | T-001 line 72 | PASS |
| AC-MODE-008a | Section 6.1 aggregate (not in individual task refs) | PASS (aggregate) |
| AC-MODE-009 | T-009 lines 366-367 | PASS |
| AC-AGT-009 | T-016 (lines in Section 6.2) | PASS |
| AC-DOC-014b | T-027 acceptance_criteria_refs | PASS |
| AC-MIG-007 | T-006 + T-026 | PASS |
| AC-INV-PERM-001 | T-003/004/005/023/030 | PASS |
| AC-STEPS-003a | T-007 | PASS |
| AC-SETUP-007 | T-010 line 411 | PASS |
| AC-CT-004 | T-030 | PASS |
| AC-MODE-MATRIX-006 | T-008 line 329 | PASS |
| AC-NF-005 | T-031 | PASS |
| AC-NF-008 | Section 6.1 aggregate only; T-031 implicitly | PASS (aggregate) |
| AC-AGT-008 | T-015 | PASS |
| AC-INV-EMAIL-001 | T-030 | PASS |

All 15 spot-checked ACs traced. Tier 1 requirements_traced = PASS despite MINOR individual task attribution gaps.

### No regressions (PASS — N/A for planning artifact)

Phase 6 is a planning artifact. No existing test suite is changed. N/A.

### Lint clean (PASS)

Markdown is well-formed. YAML blocks within fenced sections are syntactically consistent (range notation noted as NIT, not a syntax error).

---

## Tier 3 Assessment

### Correctness (3/5)

**Score rationale:** The plan correctly handles all 9 SUCCESS_CRITERIA and 7 ANTI_PATTERNS at a structural level. However, 3 MAJOR correctness issues were found:

1. **T-015 wrong file path** (`core/state-handler.md` vs actual `core/state-manager.md`): verified by filesystem. Phase 7 will try to modify a non-existent file, causing task failure.
2. **T-026 files_modified/notes contradiction**: The `files_modified` path and the notes CRITICAL warning directly contradict each other regarding core/ sub-namespace placement. This will confuse Phase 7 implementor and potentially break AC-CT-004.
3. **T-015 parallelizable_with contains T-016 which depends_on T-015**: A sequential dependency is misclassified as parallel.

These 3 issues are fixable in a single revision pass. None make the plan unimplementable if the fixer reads both files_modified AND notes carefully — but Phase 7 should not require reading notes to discover the correct behavior specified in files_modified.

### Completeness (4/5)

**Score rationale:** All 9 SUCCESS_CRITERIA are addressed:
1. Full AC coverage ✓ (94/94 per Section 6.1)
2. Atomic task scope ✓ (explicit files_modified per task)
3. Migration ordering decided ✓ (Section 2: TOML first with 5-point rationale)
4. Test coverage matrix complete ✓ (Section 3: 39/39 non-n/a cells + 9 mode matrix cells)
5. Cross-File Invariant atomicity ✓ (T-030 as single sequential terminal)
6. Parallelization viability ✓ (26/33 = 78.8% > 50%)
7. Worktree isolation respected ✓ (Section 5.2 explicit verification; Wave 7E folding prevents AP1)
8. Phase 7 timeout viability ✓ (7-9h wall-clock projection)
9. Rollback strategy per task ✓ (all 33 tasks have non-trivial rollback_strategy)

Minor deduction: AC-MODE-008a and AC-NF-001/002/008 not in individual task refs (Section 6.2 gaps). These are present in the aggregate Section 6.1 but Phase 8 oracle reads task-level refs for attribution.

### Security (5/5)

No credentials or secrets in the plan. All file paths use project-relative notation without `..` escapes. Migration tooling backup atomicity (REQ-NF-009, AC-MIG-006) is explicitly covered in T-006 with correct pre-write backup sequencing. T-010 symlink guard (REQ-SETUP-006) is covered. T-030 invariant checks include no SSRF/injection vectors.

### Maintainability (4/5)

Task IDs are strictly sequential T-001..T-033. Descriptions are one-line per task. Wave groupings (7A-7J) are coherent and well-labeled. Phase 7 dispatch configuration in Section 5.1 is complete and well-formatted.

Minor deductions: Range notation in parallelizable_with (`T-017..T-020`) is non-standard YAML and could confuse a YAML parser. T-031/T-032/T-033 acceptance_criteria_refs use prose strings. These degrade machine-readability.

### Robustness (3/5)

**Score rationale:** The plan has strong risk mitigation in Section 4 (8 risk scenarios, each with mitigation + rollback). Anti-patterns AP1-AP7 are addressed. Cross-task entanglement is minimal with clear DAG structure.

However:
- The T-015 wrong file path is a robustness failure: Phase 7 will error on a missing file modify.
- T-033 depends_on: [] but test_files_pass references files that don't exist until T-031: Phase 7 will fail T-033 tests if run before T-031.
- T-026 files_modified/notes contradiction creates an ambiguous Phase 7 execution path.

These 3 issues would cause Phase 7 to struggle or produce spurious failures. With the recommended fixes applied, Robustness would score 4/5.

---

## Specific Compliance Checks

### 1. files_modified real-path spot check (10 paths)

| Path | Exists? | Notes |
|------|---------|-------|
| `skills/fix-bugs/SKILL.md` | YES | T-007 MODIFY |
| `skills/implement-feature/SKILL.md` | YES | T-008 MODIFY |
| `skills/scaffold/SKILL.md` | YES | T-009 MODIFY |
| `docs/reference/agents.md` | YES | T-021 MODIFY |
| `docs/reference/automation-config.md` | YES | T-023 MODIFY |
| `docs/architecture.md` | YES | T-024 MODIFY |
| `state/schema.md` | YES | T-015 MODIFY |
| **`core/state-handler.md`** | **NO** | **T-015 WRONG PATH — MAJOR** |
| `skills/migrate-config/SKILL.md` | YES | T-006 MODIFY |
| `skills/pipeline-status/SKILL.md` | YES | T-016 MODIFY |

**Result: 9/10 correct. 1 MAJOR wrong-path finding confirmed.**

### 2. AC coverage 100% claim — 15 AC spot-check

All 15 sampled ACs traced (see Tier 1 table above). Aggregate claim of 94/94 = 100% is supported.

### 3. Parallelization conflict check — 5 parallel pairs

| Pair | Claimed parallel | files_modified overlap? |
|------|-----------------|------------------------|
| T-003 ‖ T-004 | YES | T-003: agents/analyst.md + deletes. T-004: agents/test-engineer.md + deletes. DISJOINT ✓ |
| T-003 ‖ T-005 | YES | T-003: analyst.md, T-005: browser-agent.md. DISJOINT ✓ |
| T-007 ‖ T-008 | YES | T-007: skills/fix-bugs/*, T-008: skills/implement-feature/*. DISJOINT ✓ |
| T-007 ‖ T-009 | YES | T-007: skills/fix-bugs/*, T-009: skills/scaffold/*. DISJOINT ✓ |
| T-017 ‖ T-018 | YES | T-017: docs/guides/migration-v7-to-v8.md (NEW), T-018: docs/guides/setup-agents-skill.md (NEW). DISJOINT ✓ |

**Result: All 5 checked pairs are genuinely disjoint. No AP1 fake-parallel violations among checked pairs.**

### 4. Migration ordering rationale (SC-3)

Section 2 provides an explicit 5-point rationale for TOML overlay first, agent renames second:
1. Pure additive vs file-renaming (TOML adds new files, doesn't touch existing agents)
2. Agent renames depend on overlay infra
3. Deprecation alias matrix needs overlay schema as anchor
4. Phase 5 test ordering assumption
5. DAG enforcement via `depends_on: [T-001]` in T-003/T-004/T-005/T-006

OQ-INT.1 is explicitly resolved. PASS.

### 5. Test coverage matrix (SC-4)

Section 3 provides the 5×9 matrix with scenario names in each cell. Coverage: 39/39 non-n/a cells filled. 9/9 mode matrix cells covered. Gap analysis notes only AC-NF-006 (manual review, legitimate). PASS.

### 6. Cross-File Invariant atomic task (SC-5)

T-030 depends_on: [T-027, T-028, T-029, T-021, T-022, T-023, T-024]. Missing T-026 (MINOR finding f-e9f0a1). All other expected predecessors are present. T-030 structure is correct — single sequential terminal task with atomic verification. PASS WITH CAVEAT.

### 7. CHANGELOG task content (SC-7, AP7)

T-029 description: "Add CHANGELOG.md ## v8.0.0 entry — 5 mandatory breaking-change subsections (Customization (.md → .toml), Agent renames (6 → 3), SKILL.md decomposition, Pipeline Profiles syntax, Scaffold mode harmonization) with Migration: paragraph + before/after code-block per subsection."

This satisfies the HIGH PRIORITY doc requirement (per project_v8_doc_requirements.md): 5 breaking changes enumerated, Migration paragraph required per subsection, before/after code-blocks required. AP7 = PASS.

### 8. Open issues acknowledgment (SC-8)

Section 7 lists 6 open issues/known limitations:
- 7.1 T-012/013/014 fold recommendation ✓
- 7.2 core/ count preservation (T-026) ✓ (though files_modified still has wrong path)
- 7.3 AC-NF-006 manual review ✓
- 7.4 T-033 mock-project CLAUDE.md is fixture ✓
- 7.5 Phase 5 REPO_ROOT staging path guard ✓
- 7.6 Phase 7 dispatch ordering tip ✓

PASS — legitimate transparency.

---

## Summary of Required Fixes for Revision

### MUST FIX (plan-correctness blockers)

1. **T-015 files_modified path**: `core/state-handler.md` → `core/state-manager.md`
2. **T-026 files_modified path**: `core/agents-rename-aliases.md` → `core/aliases/agents-rename-aliases.md` (reconcile with notes)
3. **T-015 parallelizable_with**: Remove T-016 from the list (they are sequential per T-016's depends_on)

### SHOULD FIX (Phase 7 will struggle without these)

4. **T-030 depends_on**: Add T-026 to the list
5. **T-033 depends_on**: Add T-031 (or remove test_files_pass entries that reference non-yet-moved test files)
6. **T-007/T-008 acceptance_criteria_refs**: Add missing AC-MODE-002..007, AC-MODE-008a to T-007; add AC-MODE-002..005, AC-MODE-008a to T-008

### NICE TO FIX (Phase 8 oracle accuracy)

7. **Range notation** in T-021..T-025 parallelizable_with: expand to explicit task IDs
8. **T-031/T-032/T-033 acceptance_criteria_refs**: replace prose with AC-NNN identifiers
9. **T-027/T-009 REQ references**: replace with corresponding AC references
10. **Executive summary ratio**: update to 26/33 = 78.8%
11. **AC-NF-001 in T-001 refs**: add for completeness; AC-NF-008 in T-031 refs

---

## Overall Verdict

**PASS_WITH_FIXES** — Tier 1 all pass. Tier 3 weighted aggregate = **3.65** (above 3.5 threshold). No criterion below minimum (minimum for Correctness = 3, achieved; Robustness minimum = 2, achieved at 3).

The plan is implementable but has 3 MAJOR correctness issues that will cause Phase 7 task failures if not fixed. The issues are surgical fixes (3 field-level corrections), not architectural problems. The plan structure, DAG design, wave ordering, migration rationale, test coverage matrix, and risk register are all strong.

**Recommendation: Revision R1 to fix the 3 MUST FIX items + items 4-6 from SHOULD FIX. Nice-to-fix items can be addressed in the same pass.**

---

*REVIEW_END phase=6 round=1 verdict=PASS_WITH_FIXES weighted_aggregate=3.65 confidence=0.82*
