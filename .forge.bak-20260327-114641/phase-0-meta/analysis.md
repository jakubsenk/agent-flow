# Phase 0 — Task Analysis

## Task Type Classification

**Type:** Enhancement / Refactoring
**Sub-type:** Workflow redesign — restructuring the scaffold command's infrastructure setup flow by moving, adding, and removing steps.

This is not a bug fix, not a new command/agent, and not a new config contract key. It is a reorganization of existing scaffold command logic to improve the developer experience when a project is first created.

## Complexity Assessment

### Scope: MEDIUM-HIGH (0.7/1.0)

- **Primary file:** `commands/scaffold.md` — major rewrite of Steps 0, 4, 4b, 4c, 9, 10 and addition of Steps 0-INFRA, 0-MCP, 4d, 4e
- **Secondary files requiring updates:**
  - `CLAUDE.md` — Scaffold Pipeline diagram description
  - `README.md` — Scaffold pipeline section and mermaid diagram
  - `docs/architecture.md` — Scaffold pipeline description and mermaid diagram
  - `docs/reference/pipelines.md` — Scaffold stages table, mermaid diagram, step references
  - `docs/reference/commands.md` — /scaffold command description
  - `docs/getting-started.md` — if it references scaffold steps
  - `CHANGELOG.md` — new version entry
  - `commands/init.md` — ensure inline invocation compatibility (verify, no changes expected)
- **Files NOT changed:** agents/, skills/, core/, checklists/, examples/, state/, tests/

### Ambiguity: LOW (0.2/1.0)

The design document (`docs/plans/2026-03-27-scaffold-infrastructure-design.md`) is detailed and explicit. Step-by-step instructions, behavior tables for all 4 combinations, removal/addition decisions clearly listed, impact table provided. Very little is left to interpretation.

### Risk: LOW-MEDIUM (0.4/1.0)

- No breaking changes to Automation Config contract (MINOR version)
- No new agents or commands
- No changes to agent definitions
- Risk is in **documentation consistency** — ensuring all files that reference scaffold steps are updated, and no stale references to Step 4b, Step 4c, or Step 9 remain
- Risk of missing a reference file in docs/plans/ (but those are historical ADRs and should NOT be updated)

### Coordination: MEDIUM (0.5/1.0)

Multiple files must be updated in a coordinated way. The scaffold.md changes must align with the pipeline diagrams in architecture.md, pipelines.md, README.md, and CLAUDE.md.

**Overall Complexity Score: 0.55/1.0 (MEDIUM)**

## Fast-Track Eligibility

**Eligible: NO**

Rationale:
- Scope exceeds single-file change threshold (8+ files modified)
- Documentation consistency requires cross-file coordination
- Step renumbering has cascading effects on multiple reference documents
- The design is clear but implementation involves significant markdown restructuring

## Domain Identification

**Primary domain:** DevOps tooling / CLI plugin architecture
**Sub-domains:** Markdown document engineering, pipeline orchestration design, MCP integration

**Domain expertise needed:**
- Understanding of ceos-agents' 2-layer architecture (commands orchestrate, agents execute)
- Understanding of MCP server detection and connectivity verification
- Understanding of scaffold pipeline flow and step numbering conventions
- Understanding of the relationship between scaffold.md and documentation files

## Codebase Context Assessment

### Key Files (by importance for this task)

1. `commands/scaffold.md` (567 lines) — **PRIMARY TARGET** — complete scaffold command definition
2. `docs/plans/2026-03-27-scaffold-infrastructure-design.md` — **DESIGN SPEC** — the design to implement
3. `commands/init.md` (219 lines) — **VERIFY COMPATIBILITY** — ensure inline invocation works
4. `CLAUDE.md` (~210 lines) — **UPDATE** — Scaffold Pipeline section
5. `README.md` — **UPDATE** — Scaffold pipeline mermaid diagram and description
6. `docs/architecture.md` (~234 lines) — **UPDATE** — Scaffold pipeline section and diagram
7. `docs/reference/pipelines.md` (~399 lines) — **UPDATE** — Scaffold stages table, diagram, step descriptions
8. `docs/reference/commands.md` (~713 lines) — **UPDATE** — /scaffold command description
9. `CHANGELOG.md` — **ADD** — v5.5.0 entry

### Files to NOT modify

- `docs/plans/*.md` — Historical ADRs, do not update past plans
- `agents/*.md` — No agent changes
- `skills/workflow-router/SKILL.md` — No routing changes needed
- `core/*.md` — No core contract changes
- `tests/` — Test scenarios may need review but scaffold tests are structural

### Current Scaffold Step Map (before changes)

| Step | Name | Status after v5.5.0 |
|------|------|---------------------|
| Step 0 | Mode Selection | KEPT (moves after 0-INFRA, 0-MCP) |
| Step 0b | Brainstorming | KEPT (no change) |
| Step 0-INFRA | Infrastructure Declaration | **NEW** |
| Step 0-MCP | MCP Verification | **NEW** |
| Step 1 | Specification | KEPT (no change) |
| Step 2 | Spec Checkpoint | KEPT (no change) |
| Step 3 | Scaffold Skeleton | KEPT (no change) |
| Step 4 | Git Init | MODIFIED (auto-fill + .mcp.json) |
| Step 4b | Tracker Configuration | **REMOVED** |
| Step 4c | MCP Guidance | **REMOVED** |
| Step 4d | Push to Remote | **NEW** |
| Step 4e | Create Tracker Issues | **NEW** |
| Step 5 | Architecture & Decomposition | KEPT (no change) |
| Step 6 | Feature Plan Checkpoint | KEPT (no change) |
| Step 7 | Feature Implementation Loop | KEPT (no change) |
| Step 7b | Spec Compliance Check | KEPT (no change) |
| Step 8 | E2E Tests | KEPT (no change) |
| Step 9 | Issue Tracker (Optional) | **REMOVED** |
| Step 10 | Final Report | MODIFIED (infrastructure status) |

## Confidence Scoring

| Dimension | Score | Notes |
|-----------|-------|-------|
| Task understanding | 0.95 | Detailed design document with explicit instructions |
| Codebase mapping | 0.90 | All relevant files identified; some docs/plans may reference scaffold tangentially |
| Implementation path clarity | 0.90 | Clear step-by-step: update scaffold.md, then cascade to docs |
| Risk of unintended side effects | 0.15 | Low — pure markdown, no runtime behavior |
| Overall confidence | 0.90 | High confidence in successful implementation |

## Security Evaluation

Not applicable — this change modifies markdown command definitions only. No tokens, no API calls, no credential handling changes. The `.mcp.json` generation in Step 4 uses `<YOUR_*>` placeholders explicitly (security by design — never copy real tokens).
