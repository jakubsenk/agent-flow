# Phase 8: Verification -- Sprint Planning & Backlog Management for ceos-agents

## Personas (Adversarial)

### Adversarial Persona 1: The Contract Auditor
You are a **Configuration Contract Auditor** who meticulously verifies that every new config key, state field, and agent output format follows the documented contract exactly. You look for: missing defaults, undocumented keys, inconsistent naming, broken cross-references, and version bump violations. Your goal is to find contract inconsistencies that would break consuming projects on upgrade.

### Adversarial Persona 2: The Tracker Adversary
You are a **Multi-Tracker Integration Tester** who specifically targets the 6-tracker abstraction layer. You test each tracker type independently, looking for: missing tracker types in dispatch tables, incorrect MCP tool prefixes, tracker-specific assumptions, missing fallback paths, and operations that require features not available via MCP. Your goal is to find tracker integrations that would fail in production.

### Adversarial Persona 3: The Regression Hunter
You are a **Regression Test Specialist** who verifies that the new feature does not break any existing functionality. You run the full test suite, check counts, verify cross-references, and look for unintended side effects. Your goal is to find regressions.

## Task Instructions

Each adversarial persona independently verifies the implementation across their dimension.

### Dimension 1: Contract Compliance (Contract Auditor)

1. **Config contract:** Verify Sprint Planning section in core/config-reader.md:
   - Every key has a documented default
   - Key naming follows existing pattern (Title Case in table, snake_case in parsed output)
   - Section is listed as optional (not required)
   - No existing keys modified or removed
   - Epic template key is documented
2. **State schema:** Verify state/schema.md sprint and backlog objects:
   - All fields have documented types and defaults
   - RUN-ID formats (sprint-{timestamp}, backlog-{timestamp}) are documented
   - No existing fields modified
3. **Agent output formats:** Verify both new agents:
   - backlog-creator: output format documented in Process, produces epic card format matching spec section 4
   - sprint-planner: output format documented in Process, produces sprint plan table
4. **Version impact:** Confirm MINOR:
   - No new required config keys
   - No modified existing agent output formats
   - No breaking changes to existing skills
   - implement-feature --decompose-only is additive (existing flags unchanged)
5. **Cross-file consistency:**
   - Config keys in core/config-reader.md match what sprint-plan skill reads
   - State fields in state/schema.md match what skills write
   - Agent names in skills match agent filenames

### Dimension 2: Tracker Integration (Tracker Adversary)

1. **create-backlog dispatch table:** Verify covers all 6 tracker types for issue creation:
   - YouTrack, Jira, Linear, GitHub, Gitea, Redmine
   - MCP tool prefixes correct per core/mcp-detection.md
   - Matches implement-feature Step 5a pattern exactly
2. **sprint-plan sprint_assign dispatch table:** Verify covers all 6 tracker types:
   - 3-tier fallback (MCP -> Bash+REST -> skip+warn) for each tracker
   - Sprint concept matches spec section 6 (Sprint, Sprint, Cycle, Milestone, Milestone, Version)
   - NON-BLOCKING always -- verify language says "warn and continue", never "block"
3. **MCP tool prefixes:** Verify correct prefixes per tracker:
   - mcp__youtrack__*, mcp__jira__* or mcp__atlassian__*, mcp__linear__*, mcp__redmine__*, mcp__github__*, mcp__gitea__* or mcp__forgejo__*
4. **Pre-conditions:**
   - Jira: Scrum vs Kanban board detection present
   - Redmine: always Version, no Agile Plugin
   - Gitea: unverified MCP -> skip to Tier 2
5. **--update tracker matching:** Verify create-backlog --update defines:
   - How existing issues are found (query/search)
   - How they are matched to spec epics (title prefix or other)
   - What happens on mismatch (create new vs skip)

### Dimension 3: Regression Check (Regression Hunter)

1. **Test suite:** Run tests/harness/run-tests.sh and verify ALL tests pass (existing + new)
2. **Agent count:** Verify:
   - agents/ directory has exactly 21 .md files
   - CLAUDE.md says "21 agent" (grep for the count)
3. **Skill count:** Verify:
   - skills/ directory has exactly 28 SKILL.md files
   - CLAUDE.md says "28 skills" (grep for the count)
4. **Cross-references:** Verify:
   - skills/workflow-router/SKILL.md has ceos-agents:create-backlog and ceos-agents:sprint-plan
   - CLAUDE.md lists /create-backlog and /sprint-plan in skills list
   - CLAUDE.md lists backlog-creator and sprint-planner in agents list
   - CLAUDE.md Model Selection table includes both new agents under sonnet
   - CLAUDE.md read-only agents list includes both new agents (now 11 read-only agents)
5. **Existing functionality unchanged:** Verify NO modifications to:
   - agents/priority-engine.md (unchanged)
   - skills/prioritize/SKILL.md (unchanged)
   - agents/spec-analyst.md (unchanged)
   - agents/architect.md (unchanged)
6. **implement-feature regression:** Verify:
   - --decompose-only added to argument-hint
   - --decompose-only added to flag parsing
   - All existing flags still documented (--decompose, --no-decompose, --dry-run, --profile, --yolo, --description)
   - No existing behavior changed (only additive)
7. **Read-only agent contract:** Verify:
   - agents/backlog-creator.md has no Write/Edit tool references in Process
   - agents/sprint-planner.md has no Write/Edit tool references in Process
   - tests/scenarios/read-only-agents.sh list updated to include both new agents (11 total)
8. **Roadmap:** Verify docs/plans/roadmap.md:
   - "Sprint planning / tracking" removed from NOT PLANNED table
   - Sprint planning appears in an implemented/completed section

### Verification Output Format

```markdown
## Verification Report

### Dimension 1: Contract Compliance
| Check | Status | Detail |
|-------|--------|--------|
| Config keys have defaults | PASS/FAIL | {detail} |
| Config section is optional | PASS/FAIL | {detail} |
| State schema documented | PASS/FAIL | {detail} |
| Agent output formats documented | PASS/FAIL | {detail} |
| Version impact is MINOR | PASS/FAIL | {detail} |
| Cross-file consistency | PASS/FAIL | {detail} |

### Dimension 2: Tracker Integration
| Tracker | Issue Create | Sprint Assign | Fallback | NON-BLOCKING | Status |
|---------|-------------|---------------|----------|--------------|--------|
| YouTrack | ... | ... | ... | ... | PASS/FAIL |
| Jira | ... | ... | ... | ... | PASS/FAIL |
| Linear | ... | ... | ... | ... | PASS/FAIL |
| GitHub | ... | ... | ... | ... | PASS/FAIL |
| Gitea | ... | ... | ... | ... | PASS/FAIL |
| Redmine | ... | ... | ... | ... | PASS/FAIL |

### Dimension 3: Regression Check
| Check | Status | Detail |
|-------|--------|--------|
| Full test suite | PASS/FAIL | {N}/{M} tests passed |
| Agent count match (21) | PASS/FAIL | {detail} |
| Skill count match (28) | PASS/FAIL | {detail} |
| Cross-references | PASS/FAIL | {detail} |
| Existing agents unchanged | PASS/FAIL | {detail} |
| implement-feature additive | PASS/FAIL | {detail} |
| Read-only agent contract | PASS/FAIL | {detail} |
| Roadmap updated | PASS/FAIL | {detail} |

### Overall Verdict
{PASS / FAIL with blocking issues listed}
```

## Success Criteria

- All 3 adversarial personas produce independent verification reports
- Every check has concrete PASS/FAIL with evidence
- All 6 tracker types individually verified in both dispatch tables
- Full test suite passes with no regressions
- Agent and skill counts match between filesystem and CLAUDE.md
- No breaking changes detected (MINOR version bump confirmed)
- Both new agents verified as read-only (no Write/Edit in Process)
- sprint-planner verified to NEVER re-rank
- Sprint assignment verified as NON-BLOCKING for all trackers
- If any FAIL found, it includes a specific fix recommendation

## Anti-Patterns

1. **Rubber-stamp verification** -- actually verify, do not assume
2. **Missing tracker types** -- verify ALL 6 tracker types in BOTH dispatch tables
3. **Ignoring edge cases** -- verify cold start, empty backlog, tracker without sprint support
4. **Skipping the test suite** -- full test suite MUST be run
5. **Trusting self-reported counts** -- count actual files, do not trust CLAUDE.md
6. **Forgetting read-only-agents.sh update** -- this test file has a hardcoded list of 9 agents that must become 11

## Codebase Context

- **Test harness:** tests/harness/run-tests.sh
- **Agent directory:** agents/ (should contain 21 .md files after implementation)
- **Skill directory:** skills/ (should contain 28 SKILL.md files after implementation)
- **Config reader:** core/config-reader.md
- **State schema:** state/schema.md
- **CLAUDE.md:** Root-level with counts, lists, tables
- **Workflow router:** skills/workflow-router/SKILL.md
- **Read-only agents test:** tests/scenarios/read-only-agents.sh (must be updated to include 11 agents)
- **Count test:** tests/scenarios/xref-command-count.sh (validates counts automatically)
- **Plugin version:** plugin.json (should still be v6.4.6 -- version bump is post-verification)
- **Existing test count:** 54 scenarios (will increase by ~15-20 with new tests)
