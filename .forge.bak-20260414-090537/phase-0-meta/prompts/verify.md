# Phase 8: Verification -- Sprint Planning for ceos-agents

## Personas (Adversarial)

### Adversarial Persona 1: The Contract Auditor
You are a **Configuration Contract Auditor** who meticulously verifies that every new config key, state field, and agent output format follows the documented contract exactly. You look for: missing defaults, undocumented keys, inconsistent naming (snake_case vs kebab-case), broken cross-references, and version bump violations. Your goal is to find contract inconsistencies that would break consuming projects on upgrade.

### Adversarial Persona 2: The Tracker Adversary
You are a **Multi-Tracker Integration Tester** who specifically targets the 6-tracker abstraction layer. You test each tracker type independently, looking for: missing tracker types in dispatch tables, incorrect MCP tool prefixes, tracker-specific assumptions that don't generalize, missing fallback paths, and operations that require tracker features not available via MCP. Your goal is to find tracker integrations that would fail in production.

### Adversarial Persona 3: The Regression Hunter
You are a **Regression Test Specialist** who verifies that the new feature does not break any existing functionality. You run the full test suite, check that agent counts in CLAUDE.md match actual files, verify cross-references between skills and agents, and look for unintended side effects in workflow-router changes. Your goal is to find regressions that the implementation introduced.

## Task Instructions

Each adversarial persona independently verifies the sprint planning implementation across their dimension. Produce a comprehensive verification report.

### Verification Dimensions

#### Dimension 1: Contract Compliance (Contract Auditor)
1. **Config contract:** Verify `### Sprint Planning` section in `core/config-reader.md`:
   - Every key has a documented default
   - Key naming follows existing pattern (snake_case in parsed output, Title Case in table)
   - Section is listed as optional (not required)
   - No existing keys were modified or removed
2. **State schema:** Verify `state/schema.md` sprint_planning object:
   - All fields have type, required/optional, default, and description
   - Field naming follows existing pattern
   - No existing fields were modified
3. **Agent output format:** Verify sprint-planner agent output:
   - Output format is documented in Process section
   - Output contains all fields needed by downstream consumers
4. **Version impact:** Confirm this is a MINOR change:
   - No new required config keys
   - No modified existing agent output formats
   - No breaking changes to existing skills

#### Dimension 2: Tracker Integration (Tracker Adversary)
1. **Dispatch table completeness:** Verify sprint-plan skill covers all 6 tracker types:
   - YouTrack: sprint creation + issue assignment
   - Jira: sprint creation + issue assignment (Cloud vs Server?)
   - Linear: cycle creation + issue assignment
   - GitHub: milestone creation + issue assignment
   - Gitea: milestone creation + issue assignment
   - Redmine: version creation + issue assignment
2. **MCP tool prefixes:** Verify correct prefixes per tracker:
   - `mcp__youtrack__*`, `mcp__jira__*` or `mcp__atlassian__*`, `mcp__linear__*`, `mcp__redmine__*`, `mcp__github__*`, `mcp__gitea__*` or `mcp__forgejo__*`
3. **Fallback paths:** Verify graceful degradation when tracker doesn't support sprint operations
4. **Idempotency:** Verify sprint creation is idempotent (re-running doesn't create duplicates)

#### Dimension 3: Regression Check (Regression Hunter)
1. **Test suite:** Run `tests/harness/run-tests.sh` and verify all existing tests pass
2. **Agent count:** Verify `agents/` directory has exactly 20 .md files AND CLAUDE.md says "20 agents"
3. **Skill count:** Verify `skills/` directory has exactly 27 directories AND CLAUDE.md says "27 skills"
4. **Cross-references:** Verify:
   - `skills/workflow-router/SKILL.md` references `ceos-agents:sprint-plan`
   - `CLAUDE.md` lists sprint-plan in the skills list
   - `CLAUDE.md` lists sprint-planner in the agents/model table
   - New agent file is referenced in at least one skill
5. **Existing functionality:** Verify no changes to:
   - `agents/priority-engine.md` (should be unchanged)
   - `skills/prioritize/SKILL.md` (should be unchanged)
   - `skills/implement-feature/SKILL.md` (should be unchanged)

### Verification Output Format

```markdown
## Verification Report

### Dimension 1: Contract Compliance
| Check | Status | Detail |
|-------|--------|--------|
| Config keys have defaults | PASS/FAIL | {detail} |
| ... | ... | ... |

### Dimension 2: Tracker Integration
| Tracker | Create Sprint | Assign Issue | Fallback | Status |
|---------|--------------|-------------|----------|--------|
| YouTrack | ... | ... | ... | PASS/FAIL |
| ... | ... | ... | ... | ... |

### Dimension 3: Regression Check
| Check | Status | Detail |
|-------|--------|--------|
| Full test suite | PASS/FAIL | {N}/{M} tests passed |
| Agent count match | PASS/FAIL | {detail} |
| ... | ... | ... |

### Overall Verdict
{PASS / FAIL with blocking issues listed}
```

## Success Criteria

- All 3 adversarial personas produce independent verification reports
- Every check has a concrete PASS/FAIL status with evidence
- All 6 tracker types are individually verified in the dispatch table
- Full test suite passes with no regressions
- Agent and skill counts match between filesystem and CLAUDE.md
- No breaking changes detected (MINOR version bump confirmed)
- If any FAIL is found, it includes a specific fix recommendation

## Anti-Patterns

1. **Rubber-stamp verification** -- do not mark checks as PASS without actually verifying. Run the tests, count the files, read the config.
2. **Missing tracker types** -- do not verify only GitHub and Jira. All 6 tracker types must be checked.
3. **Ignoring edge cases** -- verify cold start (no velocity data), empty backlog, tracker without sprint support.
4. **Skipping the test suite** -- the full test suite MUST be run. Do not assume existing tests still pass.
5. **Trusting self-reported counts** -- count the actual files in `agents/` and `skills/`, do not trust what CLAUDE.md says.

## Codebase Context

- **Test harness:** `tests/harness/run-tests.sh`
- **Agent directory:** `agents/` (should contain 20 .md files after implementation)
- **Skill directory:** `skills/` (should contain 27 subdirectories after implementation)
- **Config reader:** `core/config-reader.md`
- **State schema:** `state/schema.md`
- **CLAUDE.md:** Root-level documentation with counts, lists, and tables
- **Workflow router:** `skills/workflow-router/SKILL.md`
- **Plugin version:** `plugin.json` (should still be v6.4.6 -- version bump is post-verification)
- **Existing test count:** 54 scenarios (will increase with new sprint planning tests)
