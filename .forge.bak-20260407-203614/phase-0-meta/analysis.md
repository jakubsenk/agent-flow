# Phase 0: Meta-Agent Analysis

## 1. Task Type Classification

**Type:** `feature`

**Rationale:** This is a new capability (autopilot skill) that does not exist yet. It requires a new skill definition file, a new optional config section, documentation, and integration with existing pipeline skills. This is a full feature implementation, not a bugfix, refactor, or documentation task.

## 2. Complexity Assessment

| Axis | Score | Rationale |
|------|-------|-----------|
| Scope | 3 | Multiple files: new skill SKILL.md, CLAUDE.md config contract update, docs/guides/ setup guide, docs/reference/ update, state schema consideration, tests |
| Ambiguity | 2 | Well-specified by user: skill name, config keys, behavior (poll, dispatch, log, lock). Some design decisions remain (lock file format, log format, state tracking) |
| Risk | 2 | No breaking changes to existing config contract (new optional section). No public API changes. New skill only — existing pipelines unaffected |

**Composite:** max(3, 2, 2) = **3**

### JIT Recommendation
- `jit.enabled: true` (composite >= 3)
- `jit.source: "meta-agent"`

### Replanning Recommendation
- `replanning.enabled: true` (default)
- `replanning.max_cycles: 1` (default — ambiguity is low, no reason to increase)
- `replanning.divergence_threshold: 0.3` (default)

### Verification Weight Recommendation
- Default weights (no override needed — this is a standard new feature with no special security or correctness sensitivity)

## 2b. Fast-Track Eligibility Assessment

**Precondition check:**
- Composite complexity = 3 (> 2) -- FAILS

**Result:** Fast-track ineligible. Composite complexity exceeds threshold. Full pipeline required.

## 3. Domain Identification

- **Language/Runtime:** Markdown (pure plugin, no runtime code)
- **Framework:** Claude Code plugin system (skills as SKILL.md, agents as markdown with YAML frontmatter)
- **Domain:** Developer tooling / CI automation / pipeline orchestration
- **Specialty concerns:** Concurrency (lock file), cross-platform compatibility (Windows Task Scheduler + Unix cron), MCP tool integration, state management

## 4. Codebase Context Assessment

### Existing Patterns and Conventions
- Skills live in `skills/{skill-name}/SKILL.md` with YAML frontmatter (name, description, allowed-tools, disable-model-invocation, argument-hint)
- Pipeline skills use `disable-model-invocation: true`
- All skills read `## Automation Config` via `core/config-reader.md`
- MCP pre-flight checks follow `core/mcp-preflight.md`
- State tracking uses `.ceos-agents/{RUN-ID}/state.json` per `state/schema.md`
- Block handling follows the Block Comment Template pattern
- Existing pipeline skills: fix-bugs, fix-ticket, implement-feature, scaffold
- fix-bugs accepts a count argument and processes N issues from Bug query
- implement-feature accepts an ISSUE-ID or --description
- Both use MCP tools for tracker queries (mcp__youtrack__*, mcp__github__*, etc.)
- Config contract: required sections (Issue Tracker, Source Control, PR Rules, Build & Test) + optional sections
- Optional sections have defaults and are documented in CLAUDE.md config contract table
- Core contracts: 11 shared pattern files in core/
- Tests: manual test suite in tests/ with harness/run-tests.sh
- Version: 6.4.0, 19 agents, 26 skills

### Test Framework
- Shell-based test harness (`tests/harness/run-tests.sh`)
- Test scenarios in `tests/scenarios/`
- No runtime code to unit-test — tests validate markdown structure and content

### Build System
- None (pure markdown plugin)

### Relevant Existing Code
- `skills/fix-bugs/SKILL.md` — closest analog (fetches N bugs, processes each)
- `skills/implement-feature/SKILL.md` — feature pipeline entry point
- `skills/status/SKILL.md` — reads active issue state
- `core/config-reader.md` — config parsing contract
- `core/mcp-preflight.md` — MCP connectivity check
- `core/state-manager.md` — atomic state writes
- `state/schema.md` ��� state.json structure

### Tech Debt
- None directly relevant to this feature

## 5. Confidence Scoring

| Question | Score | Rationale |
|----------|-------|-----------|
| Is the task well-defined enough to execute? | 0.9 | User provided clear scope, behavior spec, and explicit out-of-scope boundaries |
| Does the available context support execution? | 0.95 | All existing patterns (skills, config, MCP, state) are well-documented and consistent |
| Is the task within the pipeline's capabilities? | 1.0 | Pure markdown file creation — the core competency of this pipeline |

**Composite:** min(0.9, 0.95, 1.0) = **0.9**

**Decision:** Proceed immediately (>= 0.9).

## 7. Routing Decision Output

```json
{
  "routing_decision": {
    "task_type": "feature",
    "secondary_types": ["docs"],
    "action": "full_pipeline",
    "target_skill": null,
    "confidence": 0.92,
    "reasoning": "New feature implementation (autopilot skill) requiring skill definition, config contract update, documentation, and tests. Secondary docs component for setup guide. Full pipeline is appropriate.",
    "skip_profile": null
  }
}
```
