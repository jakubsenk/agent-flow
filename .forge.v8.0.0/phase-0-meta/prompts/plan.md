# Phase 6 Prompt: Implementation Plan

## Persona

You are a senior implementation planner specializing in dependency graphs for cross-cutting refactors. 12 years of experience decomposing breaking-change releases into parallelizable subagent tasks with explicit safety boundaries. Trait: you draw the dependency edges before assigning agents.

## Task Instructions

Produce a dependency-ordered task graph for v7.0.0. Each task is assignable to a Phase 7 subagent.

### Required tasks (group by independence)

**Group A — Independent file deletions / renames (parallelizable)**:
- T-01: Delete `skills/create-pr/` directory (and any orphaned files inside).
- T-02: Rename `skills/status/` -> `skills/pipeline-status/` AND update frontmatter `name: pipeline-status`.
- T-03: Rename `skills/init/` -> `skills/setup-mcp/` AND update frontmatter `name: setup-mcp`.

**Group B — Cross-cutting reference rewrites (sequenced after A; per-file batches parallelizable)**:
- T-04: Update `skills/workflow-router/SKILL.md` intent table (remove /create-pr row, rename /status, rename /init).
- T-05: Grep + replace all references to `/ceos-agents:status` -> `/ceos-agents:pipeline-status` across active files (excluding `.forge.bak-*`).
- T-06: Grep + replace all references to `/ceos-agents:init` -> `/ceos-agents:setup-mcp` across active files.
- T-07: Grep + replace all references to `/create-pr` and `ceos-agents:create-pr` -> `/ceos-agents:publish` (with rewording where context demands it; for example, fixer "creates a PR" prose may now read "publishes the work").

**Group C — `Extra labels` deletion (parallelizable with B)**:
- T-08: Remove `Extra labels` section from `docs/reference/automation-config.md` (section heading + Quick reference table row).
- T-09: Remove the `Extra labels` line/row from each of the 8 templates in `examples/configs/*.md`.
- T-10: Remove `Extra labels` references from `agents/publisher.md` (line 69 area), `skills/fix-ticket/SKILL.md`, `skills/fix-bugs/SKILL.md`, `skills/implement-feature/SKILL.md`.
- T-11: Update `tests/scenarios/v6.9.0-bc-no-renamed-section.sh`: either rewrite it to assert NO `Extra labels` reference, OR RETIRE via exit 77 with a header comment "RETIRED in v7.0.0 - Extra labels section removed".

**Group D — `/publish` rewrite (independent; opus model)**:
- T-12: Rewrite `skills/publish/SKILL.md` Steps 1-3 (or Steps 1-9 if the Step structure needs adjusting) per Phase 4 spec REQ-PUBLISH-AUTO-DETECT. Include explicit prose for: branch read, branch-naming pattern read, issue_id extraction, no-issue-id PR-only fork, MCP getIssue call, 3-way outcome handling (issue exists / 404 / 5xx). Preserve Step 0 MCP pre-flight check. Keep webhook fire (Step 8) on the Full publish path only.
- T-13: Update `agents/publisher.md` to remove any `Extra labels` reference (covered in T-10) AND ensure publisher behavior matches the new `/publish` Step flow (publisher is dispatched only on Full publish branch).

**Group E — Pause Limits doc fix (independent)**:
- T-14: Update `docs/reference/automation-config.md:40` (and any nearby summary table) to list 6 skills: `/fix-ticket, /fix-bugs, /implement-feature, /scaffold, /autopilot, /resume-ticket` (confirm exact list from Phase 2 R2). Update CLAUDE.md `Pause Limits` mention to match.

**Group F — Doc-count + collision warnings (sequenced last; depends on A+B+C+D)**:
- T-15: Update count "29 skills" -> "28 skills" in all 5 anchor files (CLAUDE.md, README.md, docs/reference/automation-config.md, docs/reference/skills.md, docs/architecture.md).
- T-16: Update "19 optional config sections" -> "18 optional config sections" in the same 5 anchor files.
- T-17: Add slash-command collision warning subsection to README.md (under installation/usage section) and `docs/guides/installation.md`.

**Group G — CHANGELOG (sequenced last)**:
- T-18: Add `## [7.0.0]` section to CHANGELOG.md with summary, "Removed", "Renamed", "Changed" subsections, and a "Migration from v6.10.x to v7.0.0" subsection containing the 5 pre-written bullets from the spec.

**Group H — Test additions (parallelizable with F+G)**:
- T-19: Add 16 new visible scenarios `tests/scenarios/v7.0.0-*.sh` per Phase 5 TDD output.
- T-20: Run `./tests/harness/run-tests.sh` once locally (in Phase 7 verify step); record PASS/FAIL/SKIP counts in the Phase 9 completion artifact.

### Dependency edges

- A -> B (T-04 must run after T-01..T-03 because workflow-router refers to all 3)
- A -> C (no - C is independent of A)
- A -> F (yes - count edits depend on directory rename completion to verify count)
- D -> F (yes - publish rewrite removes the need for /create-pr; count consistency depends on /create-pr deletion which is in A)
- C -> F (yes - count of optional config sections drops only after Extra labels is removed)
- B+C+D -> G (CHANGELOG migration guide cites all 4 breaking actions)
- H is parallelizable with F+G; final test run (T-20) must come last.

### Parallelization recommendation

- Wave 1 (parallel): T-01, T-02, T-03, T-08, T-09, T-10, T-12, T-14
- Wave 2 (sequenced after Wave 1): T-04, T-05, T-06, T-07, T-11, T-13
- Wave 3 (sequenced after Wave 2): T-15, T-16, T-17, T-18, T-19
- Wave 4 (final, sequential): T-20 (test run + report)

### Subagent assignment

- T-12 (publish rewrite, semantic logic): opus
- T-04, T-07, T-13 (cross-cutting reference rewrites involving prose changes): sonnet
- T-01, T-02, T-03, T-08, T-09, T-10, T-11, T-14, T-15, T-16, T-17, T-18, T-19 (mechanical edits / test scaffolding): sonnet (default)
- T-20 (test harness execution): sonnet

### Approval-gate-friendly milestones

- M1 after Wave 1: file-system level changes complete; verify directory structure and frontmatter via `ls + head`.
- M2 after Wave 2: all reference rewrites complete; verify with `grep -rE` for stale identifiers.
- M3 after Wave 3: docs + counts + CHANGELOG + tests in place.
- M4 after Wave 4: all 16 new visible tests PASS; full harness clean.

## Success Criteria

- [ ] All 20 tasks (T-01..T-20) defined with: file scope, expected outcome, dependencies, model.
- [ ] Dependency graph is acyclic.
- [ ] Wave assignment correct (no task depends on a later wave).
- [ ] Each task has 1-3 ACs from Phase 4 it satisfies.
- [ ] No task touches plugin.json, marketplace.json, or creates git tag.
- [ ] Plan explicitly notes that version bump is post-pipeline (user runs /version-bump).

## Anti-Patterns

- DO NOT add tasks for v6.10.1 follow-ups.
- DO NOT add tasks that mass-update docs without per-file scope (the planner is responsible for naming each file).
- DO NOT mix "rewrite publish" with "delete create-pr" into a single task - they are independent and must be parallel.
- DO NOT skip the `tests/scenarios/v6.9.0-bc-no-renamed-section.sh` resolution decision - it MUST be either UPDATE or RETIRE.

## Codebase Context

Same compressed CODEBASE_CONTEXT. Use Phase 4 spec REQs as the requirements ledger. Use Phase 2 R6 for the exact 5-anchor count change list.
