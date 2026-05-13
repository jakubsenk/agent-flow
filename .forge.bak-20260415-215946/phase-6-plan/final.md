# Implementation Plan — v6.7.0: Pipeline Hardening

## Overview

| Field | Value |
|-------|-------|
| Version | v6.7.0 |
| Theme | Pipeline Hardening — Prompt Injection Protection (D2) + Plugin Version Tracking (D12) |
| Total tasks | 19 |
| Total estimated LOC | ~120 |
| Parallelization groups | 5 layers (0–4) |
| Critical path | T1 → T5 → T15 → T17 (or T2 → T3 → T8 → T15 → T17) |
| Tracks | 2 independent tracks (D2, D12) — no cross-dependencies |

---

## Task Table

| ID | File Path | Change Type | Description | Track | Dependencies | Est. LOC | Layer | Parallel Group |
|----|-----------|-------------|-------------|-------|--------------|----------|-------|----------------|
| T1 | `core/external-input-sanitizer.md` | CREATE | Create 14th core contract — boundary marker format for wrapping MCP-sourced external input (R-001, R-002) | D2 | none | 36 | 0 | A |
| T2 | `state/schema.md` | ADD | Add `plugin_version` field to Top-Level Field Definitions table and Full Schema Example JSON (R-007) | D12 | none | 3 | 0 | A |
| T3 | `core/state-manager.md` | MODIFY | Add version read from `.claude-plugin/plugin.json` during state init (Write Process step 2) (R-008) | D12 | T2 | 1 | 1 | B |
| T4 | `CLAUDE.md` | MODIFY | Update core count 13 → 14 in Repository Structure (R-005) | D2 | T1 | 1 | 1 | B |
| T5 | `skills/fix-ticket/SKILL.md` | ADD | Add sanitizer reference line after triage-analyst dispatch (R-003) | D2 | T1 | 1 | 2 | C |
| T6 | `skills/fix-bugs/SKILL.md` | ADD | Add sanitizer reference line after per-bug triage-analyst dispatch (R-003) | D2 | T1 | 1 | 2 | C |
| T7 | `skills/implement-feature/SKILL.md` | ADD | Add sanitizer reference line after spec-analyst dispatch (R-003) | D2 | T1 | 1 | 2 | C |
| T8 | `skills/resume-ticket/SKILL.md` | ADD | Add version comparison step 3a — major version mismatch WARN, backwards compat for absent/null (R-009, R-010) | D12 | T3 | 7 | 2 | C |
| T9 | `skills/scaffold/SKILL.md` | ADD | Add sanitizer reference after MCP issue read (when `--issue` flag used) (R-003) | D2 | T1 | 1 | 2 | C |
| T10 | `skills/analyze-bug/SKILL.md` | ADD | Add sanitizer reference after triage-analyst dispatch (R-003) | D2 | T1 | 1 | 2 | C |
| T11 | `agents/triage-analyst.md` | ADD | Add NEVER constraint for EXTERNAL INPUT markers to Constraints section (R-004) | D2 | none | 1 | 2 | C |
| T12 | `agents/code-analyst.md` | ADD | Add NEVER constraint for EXTERNAL INPUT markers to Constraints section (R-004) | D2 | none | 1 | 2 | C |
| T13 | `agents/fixer.md` | ADD | Add NEVER constraint for EXTERNAL INPUT markers to Constraints section (R-004) | D2 | none | 1 | 2 | C |
| T14 | `agents/reviewer.md` | ADD | Add NEVER constraint for EXTERNAL INPUT markers to Constraints section (R-004) | D2 | none | 1 | 2 | C |
| T15 | `agents/spec-analyst.md` | ADD | Add NEVER constraint for EXTERNAL INPUT markers to Constraints section (R-004) | D2 | none | 1 | 2 | C |
| T16 | `tests/scenarios/prompt-injection-protection.sh` | COPY | Copy TDD test from `.forge/phase-5-tdd/tests/prompt-injection-protection.sh` to test suite (R-006) | D2 | T1,T4,T5–T10,T11–T15 | 0 | 3 | D |
| T17 | `tests/scenarios/plugin-version-tracking.sh` | COPY | Copy TDD test from `.forge/phase-5-tdd/tests/plugin-version-tracking.sh` to test suite | D12 | T2,T3,T8 | 0 | 3 | D |
| T18 | `docs/plans/roadmap.md` | MODIFY | Move v6.7.0 section from PLANNED to DONE | — | T16,T17 | 5 | 4 | E |
| T19 | — (run tests) | VERIFY | Run `./tests/harness/run-tests.sh` — all tests must pass including new ones | — | T16,T17 | 0 | 4 | E |

---

## Dependency Graph

```
Layer 0 (foundational — no dependencies, all parallel):
  T1: CREATE core/external-input-sanitizer.md
  T2: ADD plugin_version to state/schema.md

Layer 1 (depends on Layer 0):
  T3: MODIFY core/state-manager.md ──────────── depends on T2
  T4: MODIFY CLAUDE.md core count ───────────── depends on T1

Layer 2 (skill + agent changes — all parallel within layer):
  T5:  skills/fix-ticket/SKILL.md ───────────── depends on T1
  T6:  skills/fix-bugs/SKILL.md ─────────────── depends on T1
  T7:  skills/implement-feature/SKILL.md ────── depends on T1
  T8:  skills/resume-ticket/SKILL.md ────────── depends on T3
  T9:  skills/scaffold/SKILL.md ─────────────── depends on T1
  T10: skills/analyze-bug/SKILL.md ──────────── depends on T1
  T11: agents/triage-analyst.md ─────────────── no dependency (markers are self-contained)
  T12: agents/code-analyst.md ───────────────── no dependency
  T13: agents/fixer.md ──────────────────────── no dependency
  T14: agents/reviewer.md ──────────────────── no dependency
  T15: agents/spec-analyst.md ───────────────── no dependency

Layer 3 (test deployment — depends on all implementation):
  T16: COPY prompt-injection-protection.sh ──── depends on T1,T4,T5–T10,T11–T15
  T17: COPY plugin-version-tracking.sh ──────── depends on T2,T3,T8

Layer 4 (post-implementation):
  T18: MODIFY roadmap.md ───────────────────── depends on T16,T17
  T19: RUN test suite ──────────────────────── depends on T16,T17
```

### Visual DAG

```
        T1 ─────────┬──────────┬──────────────────────────────────┐
        │           │          │                                  │
        T4          T5    T6   T7   T9   T10                     │
        │           │     │    │    │    │                        │
        │           └─────┴────┴────┴────┘                       │
        │                  │                                      │
        │           T11  T12  T13  T14  T15  (no dep on T1)      │
        │            │    │    │    │    │                        │
        │            └────┴────┴────┴────┘                       │
        │                  │                                      │
        └──────────────────┼──────────────────────── T16 ────────┘
                           │
        T2 ──── T3 ──── T8 ──────────────────────── T17
                                                      │
                                              T18 ── T19
```

---

## Parallelization Groups

### Group A — Layer 0 (2 tasks, parallel)
Execute simultaneously — no dependencies, disjoint files.

| Task | File | Track |
|------|------|-------|
| T1 | `core/external-input-sanitizer.md` | D2 |
| T2 | `state/schema.md` | D12 |

### Group B — Layer 1 (2 tasks, parallel)
Both depend on Layer 0 but on different tasks, so they are parallel with each other.

| Task | File | Track | Waits for |
|------|------|-------|-----------|
| T3 | `core/state-manager.md` | D12 | T2 |
| T4 | `CLAUDE.md` | D2 | T1 |

### Group C — Layer 2 (11 tasks, all parallel)
All skill modifications (T5–T10) depend on T1 (core contract must exist for reference to be valid). T8 additionally depends on T3. Agent modifications (T11–T15) have no Layer 0 dependency — marker text is self-contained in each constraint. All 11 tasks touch disjoint files and execute in parallel.

| Task | File | Track | Waits for |
|------|------|-------|-----------|
| T5 | `skills/fix-ticket/SKILL.md` | D2 | T1 |
| T6 | `skills/fix-bugs/SKILL.md` | D2 | T1 |
| T7 | `skills/implement-feature/SKILL.md` | D2 | T1 |
| T8 | `skills/resume-ticket/SKILL.md` | D12 | T3 |
| T9 | `skills/scaffold/SKILL.md` | D2 | T1 |
| T10 | `skills/analyze-bug/SKILL.md` | D2 | T1 |
| T11 | `agents/triage-analyst.md` | D2 | — |
| T12 | `agents/code-analyst.md` | D2 | — |
| T13 | `agents/fixer.md` | D2 | — |
| T14 | `agents/reviewer.md` | D2 | — |
| T15 | `agents/spec-analyst.md` | D2 | — |

### Group D — Layer 3 (2 tasks, parallel)
Copy TDD tests to the test suite. Both can run in parallel.

| Task | File | Track | Waits for |
|------|------|-------|-----------|
| T16 | `tests/scenarios/prompt-injection-protection.sh` | D2 | T1,T4,T5–T10,T11–T15 |
| T17 | `tests/scenarios/plugin-version-tracking.sh` | D12 | T2,T3,T8 |

### Group E — Layer 4 (2 tasks, sequential)
Roadmap update and test run. T19 (test suite) should run after T18 to include roadmap state, but both depend on all implementation being complete.

| Task | File | Track | Waits for |
|------|------|-------|-----------|
| T18 | `docs/plans/roadmap.md` | — | T16,T17 |
| T19 | `./tests/harness/run-tests.sh` | — | T16,T17 |

---

## Estimated Total LOC

| Category | Tasks | LOC |
|----------|-------|-----|
| Core contracts (CREATE) | T1 | 36 |
| State schema (ADD) | T2 | 3 |
| State manager (MODIFY) | T3 | 1 |
| CLAUDE.md (MODIFY) | T4 | 1 |
| Skills — sanitizer refs (ADD x6) | T5–T10 | 6 |
| Skills — version comparison (ADD) | T8 | 7 |
| Agents — NEVER constraints (ADD x5) | T11–T15 | 5 |
| Tests (COPY) | T16–T17 | 0 (existing files) |
| Roadmap (MODIFY) | T18 | ~5 |
| **Total** | **19 tasks** | **~64 new/modified lines** |

Note: The design spec estimates ~120 LOC including the test file contents (~62 lines each). Since the tests are copied from TDD phase rather than authored, the implementation LOC is ~64.

---

## Critical Path Analysis

Two independent tracks mean two critical paths. The overall critical path is whichever track is longer.

### Track D2 (Prompt Injection Protection)
```
T1 (CREATE core contract, 36 LOC)
  → T4 (CLAUDE.md count, 1 LOC)
  → T5–T10 (6 skill refs, 6 LOC) [parallel]
  → T11–T15 (5 agent constraints, 5 LOC) [parallel, no T1 dep — can run with Group C]
  → T16 (copy test)
  → T19 (verify)
```
**Estimated wall-clock steps:** 4 sequential layers (T1 → T4 → T5‖T11 → T16)

### Track D12 (Plugin Version Tracking)
```
T2 (ADD schema field, 3 LOC)
  → T3 (MODIFY state-manager, 1 LOC)
  → T8 (ADD resume-ticket comparison, 7 LOC)
  → T17 (copy test)
  → T19 (verify)
```
**Estimated wall-clock steps:** 4 sequential layers (T2 → T3 → T8 → T17)

### Overall Critical Path
Both tracks have 4 sequential layers and converge at Layer 3 (test copy) and Layer 4 (verify). Since the tracks are independent and all Layer 2 tasks are parallel, the critical path length is:

```
Layer 0 → Layer 1 → Layer 2 → Layer 3 → Layer 4
  (1)       (1)       (1)       (1)       (1)    = 5 sequential steps
```

The bottleneck is T1 (36 LOC — largest single task). All other tasks are 1–7 LOC additions.

---

## Execution Strategy

### Recommended Approach: Single-Agent Sequential

Given the small total LOC (~64 lines of actual changes) and simple additive nature of all modifications (no deletions, no refactors, no logic changes), a single-agent sequential execution is optimal:

1. **Execute Layer 0** (T1 + T2) — create new file, add schema field
2. **Execute Layer 1** (T3 + T4) — modify state-manager, update CLAUDE.md count
3. **Execute Layer 2** (T5–T15) — 11 one-line additions, all from design spec verbatim text
4. **Execute Layer 3** (T16 + T17) — copy 2 test files
5. **Execute Layer 4** (T18 + T19) — update roadmap, run test suite

### Why Not Parallel Agents?

- All changes are 1-line additions to existing files (except T1 which is a new 36-line file)
- No shared state between tasks — but the overhead of spawning 11 agents for 11 one-line edits exceeds the sequential cost
- The design spec provides exact verbatim text for every change — no research or decision-making needed
- Total implementation time estimate: under 10 minutes sequential

---

## Risk Register

| Risk | Likelihood | Impact | Mitigation | Affected Tasks |
|------|-----------|--------|------------|----------------|
| Insertion point line numbers in design spec are stale | Medium | Low | Grep for anchor text (e.g., "Run `ceos-agents:triage-analyst`") instead of relying on line numbers | T5–T10 |
| Existing test `xref-core-registry.sh` fails before T4 completes | Certain | Low | Execute T4 before or alongside T1 in same commit | T4 |
| `plugin.json` path varies across installations | Very Low | Low | Default `plugin_version` to null if unreadable (per design) | T3 |
| Marker text appears in legitimate issue content | Very Low | Very Low | Markers use `---` prefix — unlikely in normal text; worst case is false boundary | T1,T11–T15 |

---

## Validation Criteria

All of the following must pass before the version is considered complete:

1. `tests/scenarios/prompt-injection-protection.sh` — PASS
2. `tests/scenarios/plugin-version-tracking.sh` — PASS
3. `tests/harness/run-tests.sh` — all existing + new tests PASS (0 failures)
4. `core/external-input-sanitizer.md` exists with 5 sections and 4 NEVER constraints
5. 6 skills reference `core/external-input-sanitizer`
6. 5 agents contain EXTERNAL INPUT START/END NEVER constraint
7. `CLAUDE.md` declares 14 core contracts
8. `state/schema.md` documents `plugin_version` field with type, default, and description
9. `core/state-manager.md` references `plugin_version` and `plugin.json`
10. `skills/resume-ticket/SKILL.md` contains major version mismatch WARN and absent/null silent skip
