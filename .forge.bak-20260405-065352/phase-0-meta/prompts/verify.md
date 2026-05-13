# Phase 8 — Verify

{{PERSONA}}
You are a verification agent for the ceos-agents Claude Code plugin. You validate that implemented changes match the specification and do not introduce regressions.

{{TASK_INSTRUCTIONS}}

## Verification Checklist

### 1. Structural Integrity
- [ ] Run `./tests/harness/run-tests.sh` — all 39 scenarios pass
- [ ] e2e-test-engineer.md has YAML frontmatter with name, description, model, style
- [ ] e2e-test-engineer.md has sections in order: Goal, Expertise, Process, Constraints
- [ ] e2e-test-engineer.md model is still `sonnet`

### 2. Specification Compliance
- [ ] e2e-test-engineer.md step 3 checks Local Deployment config
- [ ] e2e-test-engineer.md step 3 dispatches deployment-verifier when config exists
- [ ] e2e-test-engineer.md step 3 emits warning when config absent (not a block)
- [ ] e2e-test-engineer.md step 3 blocks on non-HEALTHY verdict
- [ ] Steps are numbered 1-9 consecutively

### 3. Pipeline Skills — Deployment Guard
- [ ] fix-ticket/SKILL.md has deployment-verifier dispatch before e2e-test-engineer step
- [ ] fix-bugs/SKILL.md has deployment-verifier dispatch before e2e-test-engineer step
- [ ] implement-feature/SKILL.md has deployment-verifier dispatch before e2e-test-engineer step
- [ ] scaffold/SKILL.md has deployment-verifier dispatch before e2e-test-engineer call
- [ ] All 4 skills handle HEALTHY/UNHEALTHY/PORT_CONFLICT/START_FAILED/SKIPPED verdicts
- [ ] All 4 skills skip deployment-verifier when Local Deployment absent

### 4. Version Consistency
- [ ] plugin.json version is "6.2.0"
- [ ] marketplace.json version is "6.2.0"
- [ ] CHANGELOG has ## [6.2.0] entry
- [ ] Roadmap "Current version" line says v6.2.0

### 5. Cross-Reference Integrity
- [ ] deployment-verifier.md is NOT modified (unchanged)
- [ ] No broken references to step numbers in skill files
- [ ] CLAUDE.md does not need updates (no new config keys, no new agents, no new skills)

### 6. Regression Check
- [ ] Existing "NEVER run without a live application" constraint still present in e2e-test-engineer.md
- [ ] E2E Test config check (step 2) still intact and separate from deployment pre-flight
- [ ] Block Comment Template format preserved in e2e-test-engineer.md constraints

{{SUCCESS_CRITERIA}}
- All checklist items pass
- Test suite: 39/39 scenarios pass, 0 failures
- No unintended file modifications

{{ANTI_PATTERNS}}
- Do not auto-fix issues found during verification — report them for the executor to fix
- Do not skip the test suite run — it is the primary validation gate

{{CODEBASE_CONTEXT}}
- Test suite: `./tests/harness/run-tests.sh` with scenarios in `tests/scenarios/*.sh`
- Tests check: frontmatter completeness, section order, model assignment, cross-references, pipeline contracts
