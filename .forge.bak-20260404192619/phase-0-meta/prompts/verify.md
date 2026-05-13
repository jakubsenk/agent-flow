# Phase 8 — Verify

## Persona
{{PERSONA}}: QA engineer verifying decomposition persistence parity across ceos-agents pipeline skills.

## Task Instructions
{{TASK_INSTRUCTIONS}}:

Run comprehensive verification of the v6.1.9 changes. Focus on correctness and completeness.

### Verification Checklist

#### A. Structural Parity (correctness)

For each of the 4 fixes, verify the EXACT same pattern exists in all 3 files:

| Fix | implement-feature (reference) | fix-ticket (target) | fix-bugs (target) |
|-----|-------------------------------|--------------------|--------------------|
| DISABLED state write | Step 5, line 195-196 | Step 4b | Step 3b |
| mkdir + runtime fields | Step 5, line 238 | Step 4b | Step 3b |
| DECOMPOSE state write | Step 5, line 240 | Step 4b | Step 3b |
| AUTO→SINGLE_PASS | Step 5, lines 242-243 | Step 4b | Step 3b |
| Per-subtask commit | Step 6h, lines 322-332 | Step 4c | Step 3c |

For each cell, verify:
1. The state fields written are identical
2. The atomic write protocol reference is present
3. Step number cross-references are correct for that file

#### B. Completeness

1. [ ] `state/schema.md` has Subtask Object Fields subsection
2. [ ] All runtime fields documented: `id`, `title`, `status`, `commit_hash`, `restore_point`
3. [ ] Additional architect fields documented: `depends_on`, `scope`, `files`, `estimated_lines`, `acceptance_criteria`, `maps_to`
4. [ ] Version = 6.1.9 in plugin.json
5. [ ] Version = 6.1.9 in marketplace.json
6. [ ] CHANGELOG has [6.1.9] entry
7. [ ] CHANGELOG entry lists all changed files

#### C. Regression

1. Run `./tests/harness/run-tests.sh` — all tests must pass
2. Verify no changes to `implement-feature/SKILL.md`
3. Verify no changes to any agent definition
4. Verify no changes to any core contract file

#### D. Cross-Reference Integrity

1. Grep for "state-manager.md" in both target files — every state.json write must reference it
2. Grep for "decomposition-heuristics.md" — must still be referenced in both target files
3. Verify step number references within each file are internally consistent

## Success Criteria
{{SUCCESS_CRITERIA}}:
1. All 5 fixes present in both target files with correct patterns
2. Schema documentation complete
3. Version bump correct
4. Changelog present
5. Test suite passes with 0 failures
6. No unintended file changes

## Anti-Patterns
{{ANTI_PATTERNS}}:
- Accepting superficially similar patterns without checking exact field names
- Skipping the test suite run
- Not checking for accidental changes to the reference file
- Missing atomic write protocol references

## Codebase Context
{{CODEBASE_CONTEXT}}:
- Test suite: `./tests/harness/run-tests.sh` — 39 scenarios across structural, pipeline, and config tests
- Reference file: `skills/implement-feature/SKILL.md` (MUST NOT be modified)
- Target files: `skills/fix-ticket/SKILL.md`, `skills/fix-bugs/SKILL.md`, `state/schema.md`
