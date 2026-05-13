# Phase 5: TDD Test Plan — Decomposition Subtask Tracker Creation (v6.4.0)

## Summary

9 test scripts were written covering all 18 formal criteria from `phase-4-spec/final/formal-criteria.md`.
All 9 tests confirm RED phase (fail on pre-implementation codebase) with precise, actionable failure messages.

---

## Test Inventory

### Visible Tests (`tests/`)

| File | FC Coverage | What It Validates |
|------|-------------|-------------------|
| `test-step-placement.sh` | FC-1, FC-2, FC-3 | New step headings (`### 5a.`, `### 4b-tracker`, `### 3b-tracker`) exist in all 3 skills at correct line-number positions between decomposition decision and subtask execution |
| `test-tracker-types.sh` | FC-5, FC-6 | All 6 tracker types documented (YouTrack `parent:`, Jira `issuetype: Sub-task`, Linear `parentId:`, Redmine `parent_issue_id:`, GitHub/Gitea `[PARENT-ISSUE-ID]`); Jira nested sub-task guard present |
| `test-idempotence.sh` | FC-8, FC-11, FC-17, FC-18 | `tracker_issue_id: null` in YAML init; YAML+state.json fallback idempotency algorithm; no bare `tracker_id` field; atomic/immediate state.json write per-subtask |
| `test-state-schema.sh` | FC-7, FC-17 | `tracker_issue_id` row in Subtask Object Fields table in `state/schema.md`; correct type (`string or null`) and default (`null`); no bare `tracker_id` field definition |
| `test-config-contract.sh` | FC-9, FC-10 | `Create tracker subtasks` key in CLAUDE.md Decomposition section with default `enabled`; same key in `docs/reference/automation-config.md` with both `enabled`/`disabled` values documented |
| `test-cross-skill-consistency.sh` | FC-4, FC-14, FC-15, FC-16 | Triple gate condition identical across all 3 skills; single `git commit` for tracker linkage after loop; `maps_to`/`Addresses:` in sub-issue description; `resume-ticket` references `tracker_issue_id` |
| `test-docs-update.sh` | FC-9, FC-10 (docs) | CHANGELOG has v6.4.0 entry mentioning tracker subtasks; roadmap has `## DONE — v6.4.0`; at least one reference doc (`pipelines.md` or `skills.md`) mentions the new step |

### Hidden Tests (`tests-hidden/`)

| File | FC Coverage | What It Validates |
|------|-------------|-------------------|
| `test-github-gitea-checklist.sh` | FC-13 | Sentinel `<!-- ceos-agents:decomposition-checklist:{ID} -->` present; `- [ ]` checkbox format; parent body read-modify-write; sentinel check before append; only successful subtasks in checklist; `[{PARENT-ISSUE-ID}]` title prefix |
| `test-partial-failure.sh` | FC-12 | `NEVER block` / `Pipeline continues` guarantee; `Created {N}/{M} tracker sub-issues` result display; per-subtask `WARN: Could not create tracker sub-issue`; 100% failure MCP connectivity escalation; GitHub/Gitea body update failure WARN |

---

## FC Coverage Matrix

| FC | Test File(s) | Status |
|----|-------------|--------|
| FC-1 | test-step-placement.sh | RED |
| FC-2 | test-step-placement.sh | RED |
| FC-3 | test-step-placement.sh | RED |
| FC-4 | test-cross-skill-consistency.sh | RED |
| FC-5 | test-tracker-types.sh | RED |
| FC-6 | test-tracker-types.sh | RED |
| FC-7 | test-state-schema.sh | RED |
| FC-8 | test-idempotence.sh | RED |
| FC-9 | test-config-contract.sh, test-docs-update.sh | RED |
| FC-10 | test-config-contract.sh, test-docs-update.sh | RED |
| FC-11 | test-idempotence.sh | RED |
| FC-12 | tests-hidden/test-partial-failure.sh | RED |
| FC-13 | tests-hidden/test-github-gitea-checklist.sh | RED |
| FC-14 | test-cross-skill-consistency.sh | RED |
| FC-15 | test-cross-skill-consistency.sh | RED (NOTE: maps_to already present from feature pipeline, so test may pass for FC-15 alone — acceptable, it is pre-existing evidence the pattern is in-place) |
| FC-16 | test-cross-skill-consistency.sh | RED |
| FC-17 | test-idempotence.sh, test-state-schema.sh | RED |
| FC-18 | test-idempotence.sh | RED |

---

## Test Design Decisions

### Why `set -uo pipefail` (not `-euo`)
`set -e` would cause the script to exit immediately on any non-zero exit code, including `grep` returning 1 (no match). Since tests use `|| true` guards on assignment greps and explicit `if ! grep -q` checks, removing `-e` lets all assertions in a test run and accumulate all failures before exiting — giving implementors the full list of missing pieces.

### Structural grep approach
All checks are content-based `grep` on markdown files (no runtime execution). This is consistent with the existing test harness pattern in `tests/scenarios/`. Tests will pass once the implementation adds the required text strings to the correct files.

### FC-15 pre-existing condition
`maps_to` already appears in `implement-feature/SKILL.md` (architect output traceability). The FC-15 check will pass for `implement-feature` even pre-implementation, but will still correctly catch `fix-ticket` and `fix-bugs` which do not have `maps_to` references yet (those pipelines don't currently use architect). The implementor should add `maps_to`/`Addresses:` in the new step's sub-issue description instructions for all 3 skills.

### Hidden vs Visible split
- **Visible (7)**: structural/schema/config checks that implementors need to see immediately to write code
- **Hidden (2)**: behavioral pattern checks (partial failure accumulator, GitHub/Gitea checklist) that require more nuanced implementation — useful for grading but not as first-feedback

---

## Files Modified by Implementation (Expected)

When implementation is complete, these files will be modified and tests will turn GREEN:

- `skills/implement-feature/SKILL.md` — add `### 5a.` step
- `skills/fix-ticket/SKILL.md` — add `### 4b-tracker.` step
- `skills/fix-bugs/SKILL.md` — add `### 3b-tracker.` step
- `skills/resume-ticket/SKILL.md` — reference `tracker_issue_id` in DECOMPOSE_PARTIAL
- `state/schema.md` — add `tracker_issue_id` row to Subtask Object Fields
- `CLAUDE.md` — add `Create tracker subtasks` to Decomposition optional config table
- `docs/reference/automation-config.md` — document new key with enabled/disabled values
- `docs/reference/pipelines.md` or `docs/reference/skills.md` — mention new step
- `CHANGELOG.md` — add v6.4.0 entry
- `docs/plans/roadmap.md` — move feature from PLANNED to `## DONE — v6.4.0`
