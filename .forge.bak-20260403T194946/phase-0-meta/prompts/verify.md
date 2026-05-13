# Phase 8 — Verify

## Persona (Adversarial)
{{PERSONA}}: Two adversarial verification personas:

**Persona A — State Persistence Skeptic:** Assumes every persistence instruction will be misinterpreted by an LLM executor. Checks: Can the instruction be followed without ambiguity? Is every field name explicit? Is the write target (file path) unambiguous? Is the write ordering correct (create dir before write)?

**Persona B — Autonomous Execution Auditor:** Assumes the skill will be run with --yolo in a CI/CD environment with zero human interaction. Checks: Does every code path terminate without blocking on user input? Are there any implicit confirmations that could hang? Does the skill complete end-to-end?

## Task Instructions
{{TASK_INSTRUCTIONS}}:

Run a comprehensive verification of the changes made to `skills/implement-feature/SKILL.md`.

### Verification Checklist

**A. Persistence Correctness (weight: 0.40)**

1. Read `skills/implement-feature/SKILL.md` Step 5 — verify:
   - [ ] Directory creation instruction exists (`mkdir -p .claude/decomposition/`)
   - [ ] YAML write instruction names ALL subtask fields (id, title, scope, files, estimated_lines, depends_on, maps_to, acceptance_criteria, status, commit_hash, restore_point)
   - [ ] YAML file path uses the correct pattern: `.claude/decomposition/{ISSUE-ID}.yaml`
   - [ ] State.json write specifies "full subtask objects mirroring the YAML"
   - [ ] State.json fields match schema: decomposition.status, decomposition.decision, decomposition.strategy, decomposition.subtasks

2. Read `skills/implement-feature/SKILL.md` Step 6h — verify:
   - [ ] YAML update names exact fields: status, commit_hash, restore_point
   - [ ] State.json update specifies finding subtask by `id`
   - [ ] State.json update sets status and commit_hash
   - [ ] Atomic write protocol referenced

3. Cross-check with `state/schema.md` — verify:
   - [ ] All field names match the schema exactly
   - [ ] No fields written that don't exist in schema
   - [ ] decomposition.subtasks type is object[] (array of full objects, not strings)

**B. Completeness (weight: 0.30)**

4. Compare Step 5 with `skills/fix-ticket/SKILL.md` Step 4b — verify:
   - [ ] Every persistence action in fix-ticket has an equivalent in implement-feature
   - [ ] No persistence step is missing from implement-feature

5. Verify Step 6h covers the same update pattern as fix-ticket Step 4c point 9

6. Verify the full subtask execution loop (Step 6) maintains state consistency:
   - [ ] Each subtask starts with depends_on check
   - [ ] Each subtask ends with YAML + state.json update
   - [ ] Failed subtask triggers block handler

**C. Consistency (weight: 0.20)**

7. Verify terminology consistency:
   - [ ] "task tree" used consistently (not "decomposition tree" or "subtask list")
   - [ ] File path `.claude/decomposition/{ISSUE-ID}.yaml` used consistently throughout
   - [ ] State field names match exactly across all references in the file

8. Verify implement-feature's decomposition flow matches the documented pipeline in CLAUDE.md:
   ```
   SPEC-ANALYST → ARCHITECT → [AC coverage check] → [Decomposition decision]
   → FIXER ↔ REVIEWER → TEST ENGINEER → [Acceptance gate] → PUBLISHER
   ```

**D. Confirmation Flow (weight: 0.10 under maintainability)**

9. Enumerate all confirmation points in the modified file:
   - [ ] Each has explicit --yolo bypass
   - [ ] The Rules section lists all confirmation points
   - [ ] No confirmation exists outside Steps 0c, 5, and 9

10. Verify --yolo behavior at each point:
    - [ ] Step 0c duplicate check: YOLO skips entirely
    - [ ] Step 0c card creation: YOLO auto-confirms
    - [ ] Step 5 AC unmapped: YOLO blocks (correct — unmapped AC is a quality issue)
    - [ ] Step 5 decomposition plan: YOLO auto-approves
    - [ ] Step 9 PR creation: YOLO auto-creates

**E. Test Suite**

11. Run `./tests/harness/run-tests.sh` and verify all tests pass
12. If any test fails, identify whether the failure is related to the changes or pre-existing

### Verdict Format

```
## Verification Verdict

| Dimension | Weight | Score (1-5) | Notes |
|-----------|--------|-------------|-------|
| Correctness | 0.40 | X | ... |
| Completeness | 0.30 | X | ... |
| Consistency | 0.20 | X | ... |
| Maintainability | 0.10 | X | ... |

**Weighted Score:** X.XX / 5.00
**Verdict:** PASS / FAIL / PASS_WITH_NOTES
**Issues found:** (if any)
```

## Success Criteria
{{SUCCESS_CRITERIA}}:
- All checklist items verified
- Weighted score >= 4.0
- No FAIL verdict on any dimension with weight >= 0.20
- Test suite passes

## Anti-Patterns
{{ANTI_PATTERNS}}:
1. Rubber-stamping without actually reading the modified file
2. Only checking the changed lines without verifying context (surrounding instructions may conflict)
3. Skipping the test suite run
4. Not cross-referencing with state/schema.md (the schema is the source of truth for field names)
5. Accepting vague instructions that "seem right" without verifying an LLM executor could follow them unambiguously

## Codebase Context
{{CODEBASE_CONTEXT}}:
Pure markdown plugin. Modified file: `skills/implement-feature/SKILL.md`.
Reference files: `skills/fix-ticket/SKILL.md`, `state/schema.md`, `core/state-manager.md`, `CLAUDE.md`.
Test suite: `tests/harness/run-tests.sh`.
