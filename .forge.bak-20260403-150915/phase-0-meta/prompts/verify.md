# Phase 8 — Verify

You are running a comprehensive verification suite against the implemented design awareness feature.

## Context

Read:
- `.forge/phase-7-execute/execution-log.md` — what was implemented
- `.forge/phase-4-spec/spec.md` — specification
- `.forge/phase-4-spec/formal-criteria.md` — acceptance criteria
- `.forge/phase-5-tdd/test-plan.md` — test plan

## Verification Dimensions

### 1. Test Suite (Automated)

Run the full test suite:
```bash
bash tests/harness/run-tests.sh
```

All tests must pass — both new design-awareness tests and all pre-existing tests.

### 2. Specification Compliance

For each requirement in `.forge/phase-4-spec/spec.md` (REQ-DES-NNN):
- Verify the requirement is implemented
- Point to the specific file and line that implements it
- Verdict: IMPLEMENTED / PARTIALLY / MISSING

For each acceptance criterion in `.forge/phase-4-spec/formal-criteria.md`:
- Verify the criterion is testable and tested
- Point to the test that covers it
- Verdict: COVERED / PARTIALLY / UNCOVERED

### 3. Correctness

Check each modified agent file:
- **Frontmatter integrity:** name, description, model, style fields present and unchanged (except description if intentionally updated)
- **Section order:** Goal -> Expertise -> Process -> Constraints
- **Process step numbering:** sequential, no gaps
- **Constraint format:** starts with NEVER or defines hard limits
- **No orphan references:** if an agent references another agent or a spec section, verify it exists

### 4. Backward Compatibility

Verify non-web projects are unaffected:
- All design additions are conditional (grep for conditional markers in modified files)
- No unconditional design-related content in any agent
- Existing scaffolder batches 1-5 are unchanged
- Existing spec-writer sections are unchanged
- Existing stack-selector categories are unchanged (new ones are additive only)

### 5. Security / Safety

- No hardcoded credentials, tokens, or API keys introduced
- No file system paths that could cause issues cross-platform
- No shell injection vectors in any template content

### 6. Architecture Consistency

- Design awareness follows the same pattern as other conditional features (e.g., E2E Test section, Browser Verification)
- If a new agent was created, it follows the exact agent definition format from CLAUDE.md
- If new config keys were added, they follow the table format convention
- If new test files were created, they follow the existing test pattern

### 7. Documentation

- CLAUDE.md reflects any new agents, skills, or config keys
- Agent count is updated if a new agent was added
- Versioning policy is respected (correct bump level)

## Output Format

Save the verification report to `.forge/phase-8-verify/report.md`:

```markdown
## Verification Report

### Commander Verdict: {PASS | FAIL | PARTIAL}

### Dimension Scores
| Dimension | Score | Notes |
|-----------|-------|-------|
| Test Suite | PASS/FAIL | {N}/{M} tests passing |
| Spec Compliance | PASS/PARTIAL/FAIL | {N}/{M} requirements implemented |
| Correctness | PASS/FAIL | {issues found} |
| Backward Compat | PASS/FAIL | {issues found} |
| Security | PASS/FAIL | {issues found} |
| Architecture | PASS/FAIL | {issues found} |
| Documentation | PASS/FAIL | {issues found} |

### Issues Found
1. [{CRITICAL|WARN}] {description} — {file} — {recommendation}

### Summary
{1-3 sentence overall assessment}
```

If any CRITICAL issues are found, they MUST be fixed before the pipeline can complete. Return to Phase 7 (execute) to fix, then re-verify.
