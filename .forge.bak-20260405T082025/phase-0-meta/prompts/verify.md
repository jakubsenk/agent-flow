# Phase 8 — Verification

## Adversarial Personas

### Persona 1: Regression Hunter
{{PERSONA_1}}: QA engineer focused on finding regressions. Checks that existing functionality is not broken by the changes. Runs the full test suite and manually inspects each changed file for unintended side effects.

### Persona 2: Contract Compliance Auditor
{{PERSONA_2}}: Plugin contract specialist who verifies that PATCH version changes do not alter any contract. Checks that no required config sections were added, no agent output formats changed, no skill interfaces changed, and the Block Comment Template format is preserved exactly.

### Persona 3: Edge Case Adversary
{{PERSONA_3}}: Devil's advocate who looks for edge cases in the implementation. Checks: What happens if the sed range doesn't match? What if a future Batch 9 is added? What if "Batch 7" appears in a comment? What if the UNCLEAR handler's block comment fails to post?

## Task Instructions
{{TASK_INSTRUCTIONS}}:

Each adversarial persona independently verifies the v6.3.1 changes and produces a verdict.

### Verification Checklist

**Regression checks (Persona 1):**
1. Run `./tests/harness/run-tests.sh` — all tests must pass
2. Read `skills/analyze-bug/SKILL.md` — verify steps 1-5 are intact, step 3a is correctly inserted
3. Read `skills/fix-bugs/SKILL.md` — verify step 2 triage section is intact, only the UNCLEAR bullet changed
4. Read `agents/scaffolder.md` — verify Batches 1-6 and 8 are unmodified
5. Read `tests/scenarios/scaffolder-e2e-batch.sh` — verify existing assertions (Batch 8, scorecard, ordering) still work
6. Verify no other files were modified

**Contract compliance (Persona 2):**
1. No new required config sections added to CLAUDE.md
2. No agent output format changes
3. Block Comment Template matches exactly: `[ceos-agents] 🔴 Pipeline Block\nAgent: ...\nStep: ...\nReason: ...\nDetail: ...\nRecommendation: ...`
4. analyze-bug skill still has `argument-hint: "<ISSUE-ID>"` and `allowed-tools` unchanged
5. fix-bugs skill still has `disable-model-invocation: true`
6. Scaffolder agent frontmatter unchanged (name, description, model, style)
7. Version change is PATCH (no MINOR/MAJOR triggers)

**Edge cases (Persona 3):**
1. `sed -n '/Batch 7/,/Batch 8/p'` — what if Batch 8 heading changes? The sed range would extend to EOF. Mitigation: Batch 8 heading is stable ("Batch 8 — Application Documentation (always generated)").
2. What if a future Batch 9 is added after Batch 8? The `sed -n '/Batch 7/,/Batch 8/p'` pattern still works correctly (stops at Batch 8).
3. What if the UNCLEAR block comment fails to post to the tracker? The skill should handle this gracefully — check if there's error handling for MCP failures.
4. What if `pytest-playwright` or `capybara-playwright-driver` are not the current package names? Verify against package registries.
5. Cross-stack test: does `sed -n '/Batch 7/,/Batch 8/p'` actually exclude Batch 6's "Skip this batch entirely"? Test manually.
6. Does `grep -q "up to 27"` still match the actual text in scaffolder.md? Verify exact phrasing.

### Dimension Weights
| Dimension | Weight | What to check |
|-----------|--------|---------------|
| Security | 0.3 | No credentials, no network access, no file system ops outside repo |
| Correctness | 0.3 | All three bugs fixed, test suite passes, no regressions |
| Spec alignment | 0.2 | Changes match roadmap spec exactly |
| Robustness | 0.2 | Edge cases handled, grep patterns resilient to future changes |

## Success Criteria
{{SUCCESS_CRITERIA}}:
- All three personas produce PASS verdicts
- Test suite: 100% pass rate
- No contract violations
- No regressions in unmodified files
- Edge cases documented with mitigations

## Anti-Patterns
{{ANTI_PATTERNS}}:
- Do NOT rubber-stamp — each persona must find at least one concern (even if minor)
- Do NOT skip the manual `sed` verification — automated tests may miss edge cases
- Do NOT assume the test suite covers everything — it only covers scaffolder structure
- Do NOT forget to check that the UNCLEAR handler in analyze-bug actually stops execution (doesn't fall through to step 4)

## Codebase Context
{{CODEBASE_CONTEXT}}:
- Full test suite: `./tests/harness/run-tests.sh` (39+ scenarios)
- Changed files: `skills/analyze-bug/SKILL.md`, `skills/fix-bugs/SKILL.md`, `agents/scaffolder.md`, `tests/scenarios/scaffolder-e2e-batch.sh`, `CHANGELOG.md`
- Unchanged version files (handled in separate commit): `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`
