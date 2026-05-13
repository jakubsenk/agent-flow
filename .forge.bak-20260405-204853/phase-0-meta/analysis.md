# Phase 0 Meta-Agent Analysis

## Task Type Classification

**Type:** Feature implementation (MINOR version bump)
**Category:** Plugin enhancement — extending an existing pattern to new pipeline locations
**Nature:** Cross-cutting change across 3 skill files, 1 state schema, 1 config contract, and documentation

## Complexity Assessment

### Scope
- **Files to modify:** ~12-15 files
  - 3 skill files: `skills/implement-feature/SKILL.md`, `skills/fix-ticket/SKILL.md`, `skills/fix-bugs/SKILL.md`
  - 1 state schema: `state/schema.md`
  - 1 config contract: `CLAUDE.md` (Decomposition section + pipeline diagrams)
  - 1 core contract: potentially new `core/subtask-tracker.md` (shared pattern)
  - 4-5 documentation files: `docs/reference/skills.md`, `docs/reference/pipelines.md`, `docs/reference/automation-config.md`, `CHANGELOG.md`, `docs/plans/roadmap.md`
- **Estimated diff lines:** ~400-600 lines total (mostly markdown)
- **No code changes:** Pure markdown plugin — no runtime code, no build system

### Ambiguity
- **LOW ambiguity:** Task is extremely well-specified by the user with 6 clear items
- Reference implementation exists (scaffold Step 4e) — this is a port/adaptation
- Tracker-specific parent-link mechanisms are already documented in `docs/reference/trackers.md` Sub-Issue Capabilities table
- State schema extension is minimal (one new field: `tracker_id`)

### Risk
- **LOW risk:**
  - No breaking changes (new optional config key, new optional pipeline step)
  - Existing patterns are proven (scaffold Step 4e has been stable since v4.0.0)
  - All 6 tracker types already have documented parent-link mechanisms
  - Idempotence pattern is well-understood (scaffold already implements it)
- **Risk factors:**
  - Cross-skill consistency: must ensure identical behavior across implement-feature, fix-ticket, fix-bugs
  - GitHub/Gitea checklist approach differs from native sub-issue trackers — need careful handling
  - Resume/idempotence must handle partial failures gracefully

## Fast-Track Eligibility Assessment

### Tier A Evaluation
- [x] Task is well-specified with clear acceptance criteria
- [x] Reference implementation exists in codebase
- [x] No security implications (pure markdown, no runtime code)
- [x] No external dependencies
- [x] Scope is bounded (6 enumerated items)
- [x] Pattern reuse (scaffold Step 4e)

### Tier B Security Evaluation
- **Security impact:** NONE — this is a pure markdown plugin with no runtime code
- **Data sensitivity:** NONE — no secrets, no credentials, no user data
- **Authentication/authorization:** N/A
- **Input validation:** N/A (markdown definitions consumed by Claude Code Task tool)

### Fast-Track Decision
**ELIGIBLE for fast-track** — well-specified feature with reference implementation, low risk, no security concerns. However, the cross-cutting nature (3 skills + docs + schema + config) means full pipeline phases are still valuable for ensuring consistency.

**Recommendation:** Standard pipeline (not fast-track) — the cross-cutting nature benefits from structured research, spec, and verification phases to ensure consistency across all 3 skills.

## Domain Identification

**Primary domain:** Plugin architecture / workflow orchestration
**Sub-domains:**
- Issue tracker integration (6 tracker types)
- Pipeline state management (state.json schema)
- Configuration contract design (Automation Config)
- Technical documentation

**Domain expertise required:**
- ceos-agents plugin architecture (skills, agents, core contracts)
- MCP (Model Context Protocol) tool patterns for tracker integration
- Issue tracker APIs (YouTrack, GitHub, Jira, Linear, Gitea, Redmine)
- Markdown-based definition systems

## Codebase Context Assessment

### Key Reference Files
| File | Relevance | Purpose |
|------|-----------|---------|
| `skills/scaffold/SKILL.md` (Step 4e) | PRIMARY reference | Existing tracker issue creation pattern |
| `skills/implement-feature/SKILL.md` (Step 5) | TARGET — decomposition decision | Where to insert new step |
| `skills/fix-ticket/SKILL.md` (Step 4b) | TARGET — decomposition decision | Where to insert new step |
| `skills/fix-bugs/SKILL.md` (Step 3b) | TARGET — decomposition decision | Where to insert new step |
| `docs/reference/trackers.md` | Sub-Issue Capabilities table | Tracker-specific parent-link mechanisms |
| `state/schema.md` | TARGET — Subtask Object Fields | Add `tracker_id` field |
| `CLAUDE.md` | TARGET — Config Contract | Add optional key to Decomposition section |
| `agents/architect.md` | Context | Task tree output format (subtask structure) |
| `core/decomposition-heuristics.md` | Context | When decomposition is triggered |

### Existing Patterns to Reuse
1. **Scaffold Step 4e tracker issue creation:** Epic/story creation, MCP dispatch, back-reference comments, idempotency guards, partial failure handling
2. **Scaffold Step 4e tracker-specific parent linking:** Sub-Issue Capabilities table in trackers.md
3. **Scaffold Step 4e GitHub/Gitea fallback:** Standalone issue with title prefix + cross-reference
4. **State.json subtask object:** Already has `id`, `title`, `status`, `commit_hash`, `restore_point`, `depends_on`, `scope`, `files`, `estimated_lines`, `acceptance_criteria`, `maps_to`

### Key Differences from Scaffold Step 4e
1. **Granularity:** Scaffold creates epic + story issues from spec files. Decomposition creates subtask issues from architect task tree.
2. **Parent issue:** In scaffold, parent is the epic issue (created in same step). In decomposition, parent is the existing ticket (ISSUE-ID from pipeline input).
3. **Back-reference storage:** Scaffold writes `<!-- TrackerType: ID -->` into spec markdown files. Decomposition should write `tracker_id` into state.json and decomposition YAML.
4. **GitHub/Gitea approach:** Scaffold creates standalone issues with `[{epic_title}]` prefix. For decomposition subtasks, a checklist in the parent issue body is more natural (user specified this in task description).

## Confidence Scoring

| Dimension | Score | Rationale |
|-----------|-------|-----------|
| Task understanding | 0.95 | 6 explicit items, reference implementation identified |
| Codebase familiarity | 0.95 | All target files read and understood |
| Implementation clarity | 0.90 | Clear pattern to follow, minor design decisions for GitHub/Gitea approach |
| Risk assessment | 0.95 | Low risk, no breaking changes |
| **Overall confidence** | **0.94** | Well above threshold (0.7) |

## Routing Decision

**Route:** Standard forge pipeline (all phases)
**Justification:** Cross-cutting feature touching 3 skill files, state schema, config contract, and docs. Benefits from structured phases to ensure consistency. Not fast-tracked despite high confidence because:
1. Three skill files must be kept in sync
2. Documentation updates span 5+ files
3. Config contract change requires careful wording
4. Version bump coordination (CHANGELOG + roadmap + plugin.json)

**Template:** None (custom task, not matching a predefined template)
**Pipeline mode:** adaptive (default)
**Skip phases:** None
**Approval gates:** 3 (spec), 4 (TDD), 6 (plan) — standard
