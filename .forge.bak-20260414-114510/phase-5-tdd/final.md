# Phase 5 TDD — Sprint Planning & Backlog Management

## Test Counts

| Location | Count | Purpose |
|----------|-------|---------|
| `.forge/phase-5-tdd/tests/` | 18 | Visible CI tests (80%) |
| `.forge/phase-5-tdd/tests-hidden/` | 4 | Hidden mutation quality gate (20%) |
| **Total** | **22** | |

## Visible Test Files (tests/)

| File | What it validates |
|------|-------------------|
| `backlog-creator-agent.sh` | agents/backlog-creator.md: frontmatter (name, model: sonnet, description, style), Goal/Expertise/Process/Constraints sections, spec+task mode in Process, NEVER in Constraints |
| `sprint-planner-agent.sh` | agents/sprint-planner.md: same structure, section order, model: sonnet, "NEVER re-rank" constraint |
| `backlog-creator-read-only.sh` | No write-tool phrases in backlog-creator Process; listed in CLAUDE.md read-only agents |
| `sprint-planner-read-only.sh` | No write-tool phrases in sprint-planner Process; listed in CLAUDE.md read-only agents |
| `create-backlog-skill.sh` | skills/create-backlog/SKILL.md: name, description, disable-model-invocation: true, allowed-tools with mcp__*, core/mcp-preflight.md + core/config-reader.md references |
| `create-backlog-flags.sh` | --decompose, --update, --dry-run flags documented in create-backlog |
| `create-backlog-tracker-dispatch.sh` | All 6 tracker types (youtrack/jira/linear/redmine/github/gitea) + backlog-creator agent dispatch |
| `sprint-plan-skill.sh` | skills/sprint-plan/SKILL.md: name, description, disable-model-invocation: true, allowed-tools with mcp__* |
| `sprint-plan-flags.sh` | --all, --apply, --dry-run, --yolo flags documented in sprint-plan |
| `sprint-plan-tracker-dispatch.sh` | All 6 tracker types + sprint assignment operation + sprint-planner agent dispatch |
| `sprint-plan-priority-engine.sh` | priority-engine agent dispatch + capacity + prioritization references |
| `sprint-plan-gates.sh` | 3 human gates defined + --yolo as gate-skip mechanism |
| `implement-feature-decompose-only.sh` | --decompose-only flag in implement-feature + backlog-creator integration point |
| `sprint-config-section.sh` | core/config-reader.md has Sprint Planning optional section with Sprint duration, Capacity unit, Team capacity; CLAUDE.md also lists it |
| `sprint-workflow-router.sh` | workflow-router has table intent rows for create-backlog and sprint-plan |
| `sprint-state-schema.sh` | state/schema.md includes sprint and backlog RUN-ID formats |
| `sprint-counts.sh` | CLAUDE.md claims 21 agents, skills/ has 28 SKILL.md files, model table lists backlog-creator + sprint-planner under sonnet |
| `scaffold-4e-backlog-creator.sh` | skills/scaffold/SKILL.md Step 4e references backlog-creator agent dispatch |

## Hidden Mutation Test Files (tests-hidden/)

| File | Mutation applied | Verifies |
|------|-----------------|----------|
| `mutation-remove-backlog-creator.sh` | Renames agents/backlog-creator.md | backlog-creator-agent.sh catches missing file |
| `mutation-remove-sprint-planner.sh` | Renames agents/sprint-planner.md | sprint-planner-agent.sh catches missing file |
| `mutation-remove-create-backlog.sh` | Renames skills/create-backlog/SKILL.md | create-backlog-skill.sh catches missing file |
| `mutation-remove-sprint-plan.sh` | Renames skills/sprint-plan/SKILL.md | sprint-plan-skill.sh catches missing file |

## Test Categories Covered

1. **Agent structure compliance** — frontmatter, section order, model assignment, NEVER rules
2. **Read-only enforcement** — no write-tool phrases in Process sections
3. **Skill frontmatter compliance** — name, description, disable-model-invocation, allowed-tools
4. **CLI flag documentation** — --decompose, --update, --dry-run, --all, --apply, --yolo, --decompose-only
5. **Tracker type coverage** — all 6 types in both new skills
6. **Agent dispatch wiring** — backlog-creator from create-backlog, sprint-planner from sprint-plan, priority-engine from sprint-plan
7. **Human gate design** — 3 gates + --yolo bypass in sprint-plan
8. **Config contract** — Sprint Planning optional section in config-reader.md + CLAUDE.md
9. **State schema** — sprint and backlog RUN-ID formats
10. **Cross-reference counts** — CLAUDE.md agent/skill counts updated to 21/28
11. **Integration points** — implement-feature --decompose-only, scaffold Step 4e
12. **Router coverage** — workflow-router intent rows for both new skills
13. **Mutation quality gate** — file-removal mutations caught by corresponding visible tests

## TDD Red Phase Status

All 18 visible tests FAIL on the pre-implementation codebase (confirmed by dry-run).
All 4 hidden mutation tests PASS (they correctly detect absent components in pre-implementation state).

## Expected Mutation Score

4 mutation tests cover the 4 critical new artifacts (2 agents + 2 skills).
Each mutation test uses file-removal as the mutation operator.
Expected mutation detection rate: **100%** (4/4 mutations caught by visible tests).

After implementation all 18 visible tests must pass; hidden mutation tests will continue to validate
that the detection logic remains effective (rename + test-fails + restore).
