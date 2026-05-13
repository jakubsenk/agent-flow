# Acceptance Criteria: E2E Test Engineer Deployment Guard (v6.2.0)

## AC-1: Agent-level pre-flight step exists

**Given** the file `agents/e2e-test-engineer.md`
**When** inspected
**Then** step 3 is titled "Deployment pre-flight" and contains sub-steps 3a (check Local Deployment config), 3b (dispatch deployment-verifier if configured), 3c (emit warning if not configured).

**Verification:** Read `agents/e2e-test-engineer.md`, confirm step 3 contains all three sub-steps with exact verdict handling for HEALTHY, UNHEALTHY, PORT_CONFLICT, START_FAILED.

## AC-2: Agent step renumbering is correct

**Given** the file `agents/e2e-test-engineer.md`
**When** inspected
**Then** the process section contains exactly 9 numbered steps (was 8), where:
- Step 1: Read the bug report and fix diff
- Step 2: Read E2E test configuration
- Step 3: Deployment pre-flight (NEW)
- Step 4: Check if E2E test infrastructure is available (was step 3)
- Step 5: Review existing E2E tests (was step 4)
- Step 6: Plan test scope (was step 5)
- Step 7: Write new E2E tests (was step 6)
- Step 8: Run the tests (was step 7)
- Step 9: Output (was step 8)

**Verification:** Count numbered steps in Process section. Confirm content of each step matches the renumbering table.

## AC-3: Agent blocks on failed deployment verification

**Given** `e2e-test-engineer` receives context with Local Deployment configured
**When** deployment-verifier returns verdict `UNHEALTHY`
**Then** the agent blocks using the Block Comment Template with Agent: `e2e-test-engineer`, Step: `Deployment Pre-Flight`, and a recommendation mentioning `/ceos-agents:check-deploy`.

**Verification:** Read step 3b in `agents/e2e-test-engineer.md`. Confirm block text for each of the three failure verdicts (UNHEALTHY, PORT_CONFLICT, START_FAILED) includes the specific recommendation text from the requirements.

## AC-4: Agent emits warning when Local Deployment absent

**Given** `e2e-test-engineer` receives context WITHOUT Local Deployment section
**When** step 3 executes
**Then** the agent emits a `[WARN]` message mentioning `/ceos-agents:onboard --update` and does NOT block.

**Verification:** Read step 3c in `agents/e2e-test-engineer.md`. Confirm the warning text contains `[WARN]`, mentions both manual start and `/ceos-agents:onboard --update`, and explicitly states "Do NOT block".

## AC-5: Agent constraint added

**Given** the file `agents/e2e-test-engineer.md`
**When** the Constraints section is inspected
**Then** a new constraint exists stating that deployment pre-flight (step 3) MUST run before any test infrastructure check.

**Verification:** Read the Constraints section. Confirm the new constraint references step 3 and the pre-flight ordering requirement.

## AC-6: fix-ticket deployment guard step exists

**Given** the file `skills/fix-ticket/SKILL.md`
**When** inspected
**Then** a step `8a-deploy. Deployment guard (pre-E2E)` exists between step 8 (Test-engineer) and the E2E test-engineer step, containing:
- Skip conditions: `local_deployment_configured = false`, e2e skipped by profile, no E2E config and not in Extra stages
- deployment-verifier dispatch with action `start` and full Local Deployment config context
- Agent Overrides check for `deployment-verifier.md`
- Verdict handling: HEALTHY/SKIPPED -> continue, UNHEALTHY/PORT_CONFLICT/START_FAILED -> Block handler
- state.json update for deployment fields

**Verification:** Read `skills/fix-ticket/SKILL.md`. Locate the `8a-deploy` heading. Confirm all five elements are present.

## AC-7: fix-ticket E2E step renumbered

**Given** the file `skills/fix-ticket/SKILL.md`
**When** inspected
**Then** the former step `8a. E2E test-engineer` is now `8b. E2E test-engineer`, and the former step `8a-browser. Browser Verification` is now `8b-browser. Browser Verification`.

**Verification:** Search for `### 8a.` and `### 8b.` headings. Confirm 8a-deploy is deployment guard, 8b is E2E, 8b-browser is browser verification. Confirm no orphaned references to old step numbers.

## AC-8: fix-bugs deployment guard step exists

**Given** the file `skills/fix-bugs/SKILL.md`
**When** inspected
**Then** a step `7a-deploy. Deployment guard (pre-E2E)` exists between step 7 (Test-engineer) and the E2E test-engineer step, with the same structure as AC-6 (adjusted step numbers).

**Verification:** Read `skills/fix-bugs/SKILL.md`. Locate the `7a-deploy` heading. Confirm structure matches AC-6 pattern.

## AC-9: fix-bugs E2E step renumbered

**Given** the file `skills/fix-bugs/SKILL.md`
**When** inspected
**Then** the former step `7a. E2E test-engineer` is now `7b. E2E test-engineer`, and the former step `7a-browser. Browser Verification` is now `7b-browser. Browser Verification`.

**Verification:** Same approach as AC-7, applied to fix-bugs.

## AC-10: implement-feature deployment guard step exists

**Given** the file `skills/implement-feature/SKILL.md`
**When** inspected
**Then** a step `6f-deploy. Deployment guard (pre-E2E)` exists between step 6e (Test-engineer) and the E2E test step, with the same structure as AC-6 (adjusted step numbers, uses `####` heading level).

**Verification:** Read `skills/implement-feature/SKILL.md`. Locate the `6f-deploy` heading. Confirm structure matches AC-6 pattern.

## AC-11: implement-feature steps renumbered

**Given** the file `skills/implement-feature/SKILL.md`
**When** inspected
**Then** the steps are renumbered as follows:
- `6f-deploy` — Deployment guard (NEW)
- `6g` — E2E test (was 6f)
- `6h` — Acceptance gate (was 6g)
- `6i` — Commit subtask (was 6h)

**Verification:** List all `####` headings in the step 6 section. Confirm the sequence and content.

## AC-12: scaffold deployment guard exists

**Given** the file `skills/scaffold/SKILL.md`
**When** Step 8 (E2E Tests) is inspected
**Then** a "Deployment guard" sub-section exists before the e2e-test-engineer dispatch, containing:
- Check for Local Deployment in generated CLAUDE.md
- deployment-verifier dispatch with action `start`
- Warning-only verdict handling (no block -- scaffold uses warnings)
- Skip e2e-test-engineer if deployment guard failed

**Verification:** Read Step 8 in `skills/scaffold/SKILL.md`. Confirm the deployment guard sub-section is present with warning-only behavior.

## AC-13: Local Deployment config reading added to skills

**Given** the files `skills/fix-ticket/SKILL.md`, `skills/fix-bugs/SKILL.md`, `skills/implement-feature/SKILL.md`
**When** the Configuration section of each is inspected
**Then** each contains a `Local Deployment` bullet with keys: Type, Start command, Stop command, Health check URL, Health check timeout, Ports, and the `local_deployment_configured = false` default when absent.

**Verification:** Search each file's Configuration section for "Local Deployment". Confirm all 6 config keys are listed.

## AC-14: Subtask loops updated (fix-ticket, fix-bugs)

**Given** the subtask execution loops in `skills/fix-ticket/SKILL.md` (step 4c) and `skills/fix-bugs/SKILL.md` (step 3c)
**When** inspected
**Then** each loop contains a deployment-verifier dispatch before the e2e-test-engineer dispatch (conditional on Local Deployment section existing), and the subsequent items are renumbered correctly.

**Verification:** Read the subtask loop in each file. Confirm the deployment-verifier call appears before e2e-test-engineer in the numbered list.

## AC-15: Stage mapping comments updated

**Given** the stage mapping sections in `skills/fix-ticket/SKILL.md`, `skills/fix-bugs/SKILL.md`, `skills/implement-feature/SKILL.md`
**When** inspected
**Then** the `e2e-test-engineer` stage mapping references the new step number (8b, 7b, 6g respectively).

**Verification:** Search for "Stage mapping" in each file. Confirm step numbers match the new numbering.

## AC-16: Version bumped to 6.2.0

**Given** the files `.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json`
**When** inspected
**Then** both contain version `"6.2.0"`.

**Verification:** Read both files. Confirm the version field.

## AC-17: CHANGELOG entry exists

**Given** the file `CHANGELOG.md`
**When** inspected
**Then** a `## [6.2.0]` entry exists with:
- `**MINOR**` label
- `### Added` section with entries for e2e-test-engineer step 3, fix-ticket 8a-deploy, fix-bugs 7a-deploy, implement-feature 6f-deploy, scaffold Step 8 guard, config reading additions, and the new constraint.

**Verification:** Read the `## [6.2.0]` section. Confirm the Added subsection lists all 7 changes.

## AC-18: Roadmap item moved to DONE

**Given** the file `docs/plans/roadmap.md`
**When** inspected
**Then** the "E2E Test Engineer: Deployment Guard" item is no longer under `## PLANNED -- Next` and has been moved to the appropriate completed section.

**Verification:** Search for "Deployment Guard" in the file. Confirm it is in a DONE section, not PLANNED.

## AC-19: No changes to deployment-verifier agent

**Given** the file `agents/deployment-verifier.md`
**When** compared to the pre-implementation version
**Then** the file is unchanged (zero diff).

**Verification:** `git diff agents/deployment-verifier.md` returns empty output.

## AC-20: No changes to check-deploy skill

**Given** the file `skills/check-deploy/SKILL.md`
**When** compared to the pre-implementation version
**Then** the file is unchanged (zero diff).

**Verification:** `git diff skills/check-deploy/SKILL.md` returns empty output.

## AC-21: No new Automation Config keys

**Given** the file `core/config-reader.md`
**When** compared to the pre-implementation version
**Then** the file is unchanged. No new keys are added to the config contract.

**Verification:** `git diff core/config-reader.md` returns empty output.

## AC-22: Structural tests pass

**Given** the test harness in `tests/`
**When** `./tests/harness/run-tests.sh` is executed
**Then** all tests pass (exit code 0).

**Verification:** Run the test harness. Confirm zero failures.
