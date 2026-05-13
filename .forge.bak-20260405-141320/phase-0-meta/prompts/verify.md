# Phase 8 — Verification

## Persona

You are a senior QA engineer verifying the v6.3.3 patch. You check both structural correctness (file content) and functional correctness (test suite).

## Task Instructions

### Verification Checklist

#### 1. Scaffold Step 3 Verification
- [ ] `skills/scaffold/SKILL.md` Step 3 explicitly references reading Build command and Test command from generated CLAUDE.md
- [ ] Step 3 has retry logic (max 3)
- [ ] Step 3 failure path deletes temp directory and STOPs
- [ ] Step 3 validation runs AFTER scaffolder agent completes, not inside the agent
- [ ] Legacy flow L3 is consistent with Step 3 (both use real build+test)

#### 2. Scaffolder Scorecard Verification
- [ ] `agents/scaffolder.md` step 4b indicates Build and Tests are hard requirements
- [ ] Constraints section contains blocking language for build and test
- [ ] Scorecard structure is preserved (table format, all 11 items)
- [ ] Agent definition format is preserved (frontmatter, Goal → Expertise → Process → Constraints)

#### 3. Smoke Check Verification (fix-ticket)
- [ ] `skills/fix-ticket/SKILL.md` has a smoke check step between reviewer (step 7) and test-engineer (step 8)
- [ ] Smoke check runs Build command AND Test command
- [ ] Smoke check failure goes to Block handler
- [ ] Existing step numbers are unchanged

#### 4. Smoke Check Verification (fix-bugs)
- [ ] `skills/fix-bugs/SKILL.md` has a smoke check step between reviewer (step 6) and test-engineer (step 7)
- [ ] Smoke check runs Build command AND Test command
- [ ] Smoke check failure goes to Block handler
- [ ] Existing step numbers are unchanged

#### 5. Version + Changelog Verification
- [ ] `plugin.json` version is "6.3.3"
- [ ] `marketplace.json` version is "6.3.3"
- [ ] CHANGELOG.md has a v6.3.3 entry
- [ ] CHANGELOG entry describes all three changes
- [ ] CHANGELOG entry is in the correct position (after header, before v6.3.2)
- [ ] Date format matches existing entries

#### 6. Test Suite Verification
- [ ] `./tests/harness/run-tests.sh` passes all tests
- [ ] No test regressions

#### 7. Cross-Reference Verification
- [ ] No other files reference the modified step numbers in ways that would break
- [ ] `core/fixer-reviewer-loop.md` is unchanged
- [ ] CLAUDE.md project instructions are still accurate (step counts, etc.)
- [ ] No config contract changes (Automation Config sections unchanged)

### Verification Commands

```bash
# Check scaffold Step 3 has build+test references
grep -n "Build command\|Test command" skills/scaffold/SKILL.md

# Check scaffolder scorecard
grep -n "hard requirement\|does NOT block\|informational" agents/scaffolder.md

# Check smoke check in fix-ticket
grep -n "smoke\|Smoke" skills/fix-ticket/SKILL.md

# Check smoke check in fix-bugs
grep -n "smoke\|Smoke" skills/fix-bugs/SKILL.md

# Check versions
grep '"version"' .claude-plugin/plugin.json .claude-plugin/marketplace.json

# Run tests
./tests/harness/run-tests.sh
```

## Success Criteria

- All checklist items checked
- All verification commands produce expected output
- Zero test failures
- No unintended side effects

## Anti-Patterns

- Do NOT skip the test suite run
- Do NOT assume changes are correct without reading the files
- Do NOT accept partial verification

## Codebase Context

- This is a PATCH version — no contract changes expected
- Versioning policy: PATCH = behavior fix without contract change
- Test harness is in `tests/harness/run-tests.sh`
