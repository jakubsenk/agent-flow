# Phase 0 Meta-Agent Analysis

## 1. Task Type Classification

**Type:** feature

**Rationale:** This is a significant new capability being added to the ceos-agents plugin: 2 new agents, 2 new skills, 1 modified skill (new flag), config contract extensions, state schema extensions, scaffold refactor, workflow-router updates, documentation updates, and tests. The spec is collaboratively designed and already validated through a prior forge run (phases 0-3), with the brainstorm yielding a Conservative Pragmatist winner. This is the SECOND forge run on the same feature -- the first run completed research + brainstorm, and the user then refined the spec significantly (added create-backlog, --decompose-only, --all flag, epic template override, --update flag).

## 2. Complexity Assessment

| Dimension | Score | Rationale |
|-----------|-------|-----------|
| Scope | 5 | Now: 2 new agents (backlog-creator, sprint-planner), 2 new skills (create-backlog, sprint-plan), 1 modified skill flag, scaffold refactor, workflow-router, config, state, CLAUDE.md, docs, roadmap, 15+ tests. |
| Ambiguity | 2 | Detailed spec resolves all major design questions. Remaining: backlog-creator output format, --update matching, scaffold 4e refactor scope. |
| Risk | 3 | New optional config (backward-compatible). Tracker API diversity for sprint_assign. Count updates tested by existing tests. |

**Composite:** max(5, 2, 3) = **5**

### 2b. Fast-Track Eligibility

**Fast-track eligible:** NO (composite 5 exceeds threshold 2)

## 3. Domain Identification

| Dimension | Value |
|-----------|-------|
| Language/Runtime | Markdown (pure plugin, no runtime code) |
| Framework | Claude Code plugin system (agents + skills + core patterns) |
| Domain | DevOps automation, project management, issue tracker integration |
| Specialty | Multi-tracker API abstraction (6 types), human-in-the-loop workflow |

## 4. Codebase Context

### Existing Patterns to Follow

- **Agent definition format:** YAML frontmatter (name, description, model, style) + Goal/Expertise/Process/Constraints sections. See agents/priority-engine.md (78 lines, opus) and agents/spec-analyst.md (97 lines, sonnet).
- **Skill definition format:** YAML frontmatter (name, description, allowed-tools, argument-hint, disable-model-invocation) + Configuration/Orchestration/Rules sections. See skills/prioritize/SKILL.md (52 lines) and skills/implement-feature/SKILL.md (647 lines).
- **Config contract:** Optional sections use | Key | Value | table format under ### Section Name in core/config-reader.md.
- **MCP pre-flight:** Every skill touching tracker must run core/mcp-preflight.md.
- **State management:** Atomic writes via core/state-manager.md, state in .ceos-agents/{RUN-ID}/state.json.
- **Tracker abstraction:** Per-tracker MCP tool patterns -- see skills/implement-feature/SKILL.md Step 5a for canonical dispatch table (all 6 tracker types with MCP tool call patterns).
- **Workflow-router:** Intent mapping table in skills/workflow-router/SKILL.md -- 41 existing rows.
- **Block comment template:** [ceos-agents] prefix format for machine-parseable comments.
- **Priority-engine:** Existing opus backlog prioritization with P0/P1/P2 tiers -- sprint planning CONSUMES its output, does not duplicate it.
- **Decomposition:** Existing subtask creation in Step 5a of implement-feature -- create-backlog can REUSE this tracker creation pattern.
- **Read-only agents:** NEVER use Write/Edit tools. Tested by tests/scenarios/read-only-agents.sh (currently checks 9 agents, will need 11).
- **Count validation:** Agent/skill/core counts in CLAUDE.md are tested by tests/scenarios/xref-command-count.sh.

### Test Framework

- Bash-based test scenarios in tests/scenarios/*.sh
- Pattern: set -euo pipefail, fail() function, grep-based structural assertions, PASS/FAIL output
- Test harness: tests/harness/run-tests.sh
- Currently 54 test scenarios
- Exit codes: 0 = PASS, 1 = FAIL, 77 = SKIP

### Relevant Existing Code

| File | Relevance |
|------|-----------|
| agents/priority-engine.md | Sprint-planner consumes its P0/P1/P2 output |
| agents/spec-analyst.md | Pattern for read-only sonnet analysis agent |
| agents/architect.md | Decomposition pattern, maps_to traceability |
| skills/prioritize/SKILL.md | Orchestration pattern for priority-engine dispatch |
| skills/implement-feature/SKILL.md | Step 5a tracker creation, decomposition gates, --decompose-only target |
| skills/fix-bugs/SKILL.md | Batch processing, --yolo pattern, flag parsing |
| skills/scaffold/SKILL.md | Step 4e refactor target |
| skills/workflow-router/SKILL.md | Intent routing table -- needs new rows |
| core/mcp-preflight.md | MCP pre-flight check pattern |
| core/config-reader.md | Config parsing -- needs Sprint Planning section |
| state/schema.md | State persistence patterns, RUN-ID formats |
| CLAUDE.md | Config contract, versioning policy, counts |
| docs/plans/roadmap.md | Line 837: Sprint planning in NOT PLANNED |
| tests/scenarios/xref-command-count.sh | Validates agent/skill/core counts |
| tests/scenarios/read-only-agents.sh | Validates read-only agents list (9 agents, must become 11) |

### Changes from Prior Run
1. backlog-creator agent (NEW)
2. /create-backlog skill (NEW)
3. --decompose-only flag on implement-feature (NEW)
4. Epic card template (NEW)
5. Scaffold Step 4e refactor (NEW)
6. --all flag on sprint-plan (EXPANDED)
7. --update flag on create-backlog (NEW)

## 5. Confidence Scoring

| Question | Score | Rationale |
|----------|-------|-----------|
| Q1: Well-defined? | 0.85 | 13-section spec, prior brainstorm resolved |
| Q2: Context? | 0.90 | All building blocks exist |
| Q3: Capabilities? | 0.90 | Pure markdown additions |

**Composite confidence:** 0.85

## 6. Prior Forge Run Leverage

The prior forge run (.forge.bak-20260414-090537/) completed phases 0-3:
- **Phase 1 (Research):** Complete tracker API research -- MCP availability, sprint_assign per tracker, 3-tier fallback strategy, vocabulary mapping across all 6 trackers.
- **Phase 2 (Research Answers):** Per-tracker dispatch tables, semi-autonomous workflow design, cold-start velocity algorithm, config contract draft (12 keys, later reduced to 7).
- **Phase 3 (Brainstorm):** Conservative Pragmatist won 5/10 dimensions. Skeptical Architect won 4/10. Innovative approach won 0. Key decisions: 3 gates (not 5), sprint_assign only, stateless agent, 7-key config, simplified state schema, NON-BLOCKING assignment always.

These findings are INCORPORATED into the current spec. Phases 1-3 do NOT need to be repeated. The spec has EXPANDED scope beyond the prior run (backlog-creator, create-backlog, --decompose-only), so phases 4-9 must account for all new components.

**Recommendation: Skip phases 1-3 (research + brainstorm). Start from phase 4 (spec).**

## 7. Security Evaluation

No security concerns beyond existing tracker API access patterns. Sprint planning and backlog creation use the same MCP read/write operations already authorized for implement-feature and prioritize skills. The --update flag reads existing tracker issues but uses standard MCP read operations. No new credential requirements.

## 8. Routing Decision

**Route:** PARTIAL PIPELINE (phases 4-9, skip 1-3)

**Reasoning:**
- Phases 1-3 already completed in prior forge run; findings embedded in the detailed 13-section spec
- Confidence 0.85 above 0.7 threshold -- no research/brainstorm needed
- Composite complexity 5 requires structured spec, TDD, planning, and verification
- Spec phase needed to formalize the user's spec into EARS requirements and resolve remaining gaps (backlog-creator output format, --update matching, scaffold 4e refactor decision)
- TDD phase needed -- significant new test surface (2 agents, 2 skills, modified skill, config, state, integration)
- Plan phase critical -- 4+ new files, 10+ modified files, dependency ordering, parallelization
- Execute phase is bulk of work -- creating all markdown definitions following established patterns
- Verify phase essential -- 6 tracker types, cross-references, count assertions, existing test suite regression check

See routing-decision.json for the machine-readable routing.
