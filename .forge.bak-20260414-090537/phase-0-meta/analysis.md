# Phase 0 Meta-Agent Analysis

## 1. Task Type Classification

**Type:** feature

**Rationale:** This is a new capability being added to the ceos-agents plugin. It involves creating a new agent, a new skill, new config sections, state schema extensions, and workflow-router updates. The task explicitly asks for research, design, and implementation of sprint planning functionality that does not currently exist.

## 2. Complexity Assessment

| Dimension | Score | Rationale |
|-----------|-------|-----------|
| Scope | 4 | Touches multiple layers: new agent, new skill, config contract extension (MINOR version bump), state schema, workflow-router, tests, docs. Affects 6 tracker types. |
| Ambiguity | 4 | Semi-autonomous mode is undefined -- requires design decisions about human interaction points. Sprint planning semantics vary across trackers (YouTrack sprints, Jira sprints, Linear cycles, GitHub milestones, Gitea milestones, Redmine versions). |
| Risk | 3 | New optional config section (backward-compatible). No existing code is modified destructively. Risk comes from tracker API diversity and ensuring the semi-autonomous UX is right. |

**Composite:** max(4, 4, 3) = **4**

### 2b. Fast-Track Eligibility

| Precondition | Met? | Detail |
|-------------|------|--------|
| Composite <= 2 | NO | Composite = 4 |
| Confidence >= 0.9 | NO | See section 5 |
| No security concerns | YES | Read/write to tracker APIs is existing pattern |
| Single-file change | NO | Multi-file, multi-layer |

**Fast-track eligible:** NO

```json
{
  "fast_track_eligible": false,
  "reason": "Composite complexity 4 exceeds threshold 2; ambiguity in semi-autonomous workflow design"
}
```

## 3. Domain Identification

| Dimension | Value |
|-----------|-------|
| Language/Runtime | Markdown (pure plugin, no runtime code) |
| Framework | Claude Code plugin system (agents + skills + core patterns) |
| Domain | DevOps automation, project management, issue tracker integration |
| Specialty | Multi-tracker API abstraction (6 tracker types), human-in-the-loop workflow design |

## 4. Codebase Context

### Existing Patterns to Follow

- **Agent definition format:** YAML frontmatter (name, description, model, style) + Goal/Expertise/Process/Constraints sections
- **Skill definition format:** YAML frontmatter (name, description, allowed-tools, argument-hint, disable-model-invocation) + Configuration/Orchestration/Rules sections
- **Config contract:** Optional sections use `| Key | Value |` table format under `### Section Name`
- **MCP pre-flight:** Every skill that touches tracker must run `core/mcp-preflight.md`
- **State management:** Atomic writes via `core/state-manager.md`, state in `.ceos-agents/{RUN-ID}/state.json`
- **Tracker abstraction:** Per-tracker MCP tool patterns (youtrack, jira, linear, redmine, github, gitea) -- see `skills/implement-feature/SKILL.md` Step 5a for the canonical tracker dispatch table
- **Workflow-router:** Intent mapping table in `skills/workflow-router/SKILL.md`
- **Block comment template:** `[ceos-agents]` prefix format for machine-parseable comments
- **Priority-engine:** Existing backlog prioritization with impact/risk/effort scoring -- sprint planning should CONSUME its output, not duplicate it
- **Decomposition:** Existing subtask creation in Step 5a of implement-feature -- sprint planning should REUSE this tracker creation pattern

### Test Framework

- Bash-based test scenarios in `tests/scenarios/*.sh`
- Pattern: `set -euo pipefail`, `fail()` function, grep-based structural assertions
- Test harness: `tests/harness/run-tests.sh`
- Currently 54 test scenarios

### Relevant Existing Code

| File | Relevance |
|------|-----------|
| `agents/priority-engine.md` | Sprint planning consumes prioritization output (P0/P1/P2 tiers) |
| `skills/prioritize/SKILL.md` | Backlog fetch + priority-engine dispatch -- sprint planner extends this |
| `skills/implement-feature/SKILL.md` Step 5a | Canonical tracker sub-issue creation pattern (all 6 types) |
| `skills/dashboard/SKILL.md` | Pattern for HTML report generation |
| `skills/metrics/SKILL.md` | Pattern for MCP-based analytics |
| `state/schema.md` | State persistence schema -- needs sprint fields |
| `core/config-reader.md` | Config parsing -- needs Sprint Planning section |
| `skills/workflow-router/SKILL.md` | Intent routing -- needs sprint planning intents |
| `agents/architect.md` | Decomposition + maps_to traceability pattern |
| `agents/spec-analyst.md` | AC extraction pattern |

## 5. Confidence Scoring

| Question | Score | Rationale |
|----------|-------|-----------|
| Q1: Is the task well-defined enough? | 0.65 | The high-level goal is clear but semi-autonomous mode needs definition. Sprint semantics differ across trackers. |
| Q2: Does context support execution? | 0.85 | All building blocks exist (prioritization, tracker APIs, state management). Patterns are well-established. |
| Q3: Within pipeline capabilities? | 0.90 | Pure markdown additions following existing patterns. No runtime code needed. |

**Composite confidence:** min(0.65, 0.85, 0.90) = **0.65**

Note: Confidence is below the 0.7 threshold, which means research and brainstorm phases are critical for resolving ambiguity before spec/implementation.

## 6. Security Evaluation

No security concerns beyond the existing tracker API access patterns. Sprint planning uses the same MCP read/write operations already authorized for implement-feature and prioritize skills.

## 7. Routing Decision

**Route:** FULL PIPELINE (phases 1-9)

**Reasoning:**
- Composite complexity 4 requires thorough design
- Confidence 0.65 below threshold -- research phase needed to resolve tracker API differences and semi-autonomous mode design
- Multi-layer changes (agent + skill + config + state + tests + router) benefit from structured decomposition
- Brainstorm phase valuable for autonomous vs semi-autonomous mode design
- No phases should be skipped given the ambiguity level

See `routing-decision.json` for the machine-readable routing.
