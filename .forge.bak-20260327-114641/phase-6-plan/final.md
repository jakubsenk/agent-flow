# Implementation Plan — Scaffold Infrastructure Integration v5.5.0

**Source documents:**
- `.forge/phase-4-spec/final/requirements.md` — File Change Matrix (17 changes across 10 files)
- `.forge/phase-4-spec/final/design.md` — Verbatim replacement content for all sections
- `.forge/phase-5-tdd/tests/test-cases.md` — 34 test cases (T01-T34)

---

## Dependency Graph

```
Task 1 (scaffold.md)
  |
  +---> Task 2 (pipelines.md)
  +---> Task 3 (CLAUDE.md)
  +---> Task 4 (README.md)
  +---> Task 5 (architecture.md)
  +---> Task 6 (commands.md)
  +---> Task 7 (test files)
  |
  +---> Task 8 (CHANGELOG + version bump)
           ^
           |
     Tasks 2-7 all block Task 8
```

## Execution Batches

| Batch | Tasks | Parallel? | Rationale |
|-------|-------|-----------|-----------|
| **Batch 1** | Task 1 | No | Critical path — all downstream tasks depend on final step headings and numbering |
| **Batch 2** | Tasks 2, 3, 4, 5, 6, 7 | Yes | Each modifies a different file; no file overlap; can run in parallel after Task 1 |
| **Batch 3** | Task 8 | No | CHANGELOG references all changes; version bump is always last |

---

## Task 1: scaffold.md — Primary Changes

- **File:** `commands/scaffold.md`
- **Depends on:** nothing
- **Blocks:** Tasks 2, 3, 4, 5, 6, 7
- **Source:** design.md Sections 1.1-1.16
- **Estimated edits:** 15 Edit tool operations (atomic — one task, one file)

### Changes (in execution order)

| # | Op | Design Ref | Description |
|---|------|------------|-------------|
| 1 | INSERT | 1.1 | Add `### Step 0-INFRA: Infrastructure Declaration` after State Detection, before `## Orchestration` |
| 2 | INSERT | 1.2 | Add `### Step 0-MCP: MCP Verification` after Step 0-INFRA, before `## Orchestration` |
| 3 | INSERT | 1.3 | Add step numbering comment at start of `## Orchestration` |
| 4 | REPLACE | 1.4 | Modify `### Step 0: Mode Selection` — update `--no-implement` exit text to include push |
| 5 | REPLACE | 1.5 | Extend `### Step 4: Git Init` to `### Step 4: Git Init + Auto-Config` with auto-fill, .mcp.json.example, .gitignore |
| 6 | DELETE | 1.6 | Remove entire `### Step 4b: Tracker Configuration (Auto-Finalize)` section |
| 7 | DELETE | 1.7 | Remove entire `### Step 4c: MCP Guidance` section |
| 8 | INSERT | 1.8 | Add `### Step 4d: Push to Remote` after modified Step 4 |
| 9 | INSERT | 1.9 | Add `### Step 4e: Create Tracker Issues` after Step 4d |
| 10 | DELETE | 1.10 | Remove entire `### Step 9: Issue Tracker (Optional)` section |
| 11 | REPLACE | 1.11 | Replace `### Step 10: Final Report` with `### Step 9: Final Report` (rename + infrastructure status) |
| 12 | REPLACE | 1.12 | Change two "jump to Step 10" references in Step 7 to "jump to Step 9" |
| 13 | REPLACE | 1.13 | Rewrite entire `## MCP Pre-flight Check` section |
| 14 | INSERT + REPLACE | 1.14-1.15 | Modify `--no-implement` legacy flow: add L5b, replace L6 report |
| 15 | REPLACE | 1.16 | Update `## Rules` scaffolder CLAUDE.md line |

### Ordering constraint

Edits 6 and 7 (DELETE Step 4b, 4c) and edits 8 and 9 (INSERT Step 4d, 4e) interact with adjacent lines. The safest execution order is:

1. Operations at the TOP of the file first (inserts before Orchestration: edits 1, 2, 3)
2. Step 0 modification (edit 4)
3. Step 4 extension (edit 5)
4. Delete 4b + 4c (edits 6, 7) — removes old content
5. Insert 4d + 4e (edits 8, 9) — adds new content in the gap
6. Delete old Step 9 (edit 10)
7. Rename Step 10 to Step 9 (edit 11)
8. Fix jump references (edit 12)
9. Rewrite MCP Pre-flight (edit 13)
10. Legacy flow changes (edit 14)
11. Rules update (edit 15)

**Alternative safe strategy:** Work bottom-up (edits from high line numbers to low) so earlier inserts/deletes don't shift line numbers for later edits. The Edit tool uses string matching (not line numbers), so this is a preference, not a requirement. Either approach works as long as each `old_string` is unique.

### Risk checkpoint after Task 1

After all 15 edits, run the test harness or manually verify:
- T01: `Step 4b` absent from scaffold.md
- T03: `Step 4c` absent from scaffold.md
- T06: `Step 9: Issue Tracker` absent from scaffold.md
- T07: `Step 10` absent from scaffold.md
- T08: `Step 0-INFRA: Infrastructure Declaration` present
- T09: `Step 0-MCP: MCP Verification` present
- T10: `Step 4d: Push to Remote` present
- T11: `Step 4e: Create Tracker Issues` present
- T12: `Step 0-INFRA` line < `Step 0: Mode Selection` line
- T20: `Step 9: Final Report` present
- T21: `jump to Step 9` present AND `jump to Step 10` absent

If any P0 test fails here, STOP. Do not proceed to Batch 2.

---

## Task 2: docs/reference/pipelines.md

- **File:** `docs/reference/pipelines.md`
- **Depends on:** Task 1 (needs final step names confirmed)
- **Blocks:** Task 8
- **Source:** design.md Section 5 (5.1 Mermaid diagram, 5.2 Stages table)
- **Estimated edits:** 2 Edit tool operations

### Changes

| # | Op | Design Ref | Description |
|---|------|------------|-------------|
| 1 | REPLACE | 5.1 | Replace entire Scaffold v2 Mermaid `flowchart TD` diagram: add `INFRA_DECL`, `MCP_CHECK` nodes; replace `GIT_INIT` label; add `PUSH`, `CREATE_ISSUES` nodes; remove `TRACKER` node; add styles for new nodes |
| 2 | REPLACE | 5.2 | Replace Stages table: add rows for 0-INFRA, 0-MCP, 4d, 4e; remove Step 9 (Issue Tracker) row; rename Step 10 to Step 9; update Step 4 description |

### Test coverage

- T14: `0-INFRA` and `0-MCP` present in pipelines.md
- T15: `4d` and `4e` present in pipelines.md
- T16: `INFRA_DECL` node present
- T17: `MCP_CHECK` node present
- T18: `PUSH[Push to Remote` and `CREATE_ISSUES[Create Tracker Issues` present
- T28: `TRACKER` node absent

---

## Task 3: CLAUDE.md

- **File:** `CLAUDE.md`
- **Depends on:** Task 1 (needs final ASCII diagram confirmed)
- **Blocks:** Task 8
- **Source:** design.md Section 2
- **Estimated edits:** 1 Edit tool operation

### Changes

| # | Op | Design Ref | Description |
|---|------|------------|-------------|
| 1 | REPLACE | 2 | Replace entire Scaffold Pipeline ASCII block and `--no-implement` line |

### Content

Replace the existing ASCII art diagram (`User description -> ...`) and the `--no-implement` line with the design.md Section 2 "AFTER" content, which adds `[0-INFRA: infra declaration]`, `[0-MCP: MCP check]`, `[4d: push]`, `[4e: tracker issues]` nodes.

### Test coverage

- T25: `0-INFRA` and `0-MCP` present in CLAUDE.md
- T26: `4d` and `4e` present in CLAUDE.md

---

## Task 4: README.md

- **File:** `README.md`
- **Depends on:** Task 1 (needs confirmation that Step 4d/4e names are final)
- **Blocks:** Task 8
- **Source:** design.md Section 3
- **Estimated edits:** 1 Edit tool operation

### Changes

| # | Op | Design Ref | Description |
|---|------|------------|-------------|
| 1 | REPLACE | 3 | Replace Scaffold Pipeline Mermaid `flowchart TD` diagram: add `Infra` node between `Desc` and `Mode`; rename `Git` label to "Git Init + Auto-Config"; add `Push` and `Issues` nodes after `Git`; update `--no-implement` description line |

### Test coverage

- T23: `Infrastructure Declaration` present in README.md

---

## Task 5: docs/architecture.md

- **File:** `docs/architecture.md`
- **Depends on:** Task 1 (needs confirmation that step names are final)
- **Blocks:** Task 8
- **Source:** design.md Section 4
- **Estimated edits:** 1 Edit tool operation

### Changes

| # | Op | Design Ref | Description |
|---|------|------------|-------------|
| 1 | REPLACE | 4 | Replace Scaffold Pipeline section: add `A2[Infrastructure Declaration]` node in Mermaid `graph LR`; rename `E` label to "Git init + Auto-Config"; add `E2[Push / Create Issues]` node; update key characteristics bullets; update `--no-implement` line |

### Test coverage

- T24: `Infrastructure Declaration` present in docs/architecture.md

---

## Task 6: docs/reference/commands.md

- **File:** `docs/reference/commands.md`
- **Depends on:** Task 1 (needs knowledge of final `/scaffold` behavior)
- **Blocks:** Task 8
- **Source:** design.md Section 6
- **Estimated edits:** 1 Edit tool operation

### Changes

| # | Op | Design Ref | Description |
|---|------|------------|-------------|
| 1 | REPLACE | 6 | Replace `/scaffold` "What it does" paragraph with updated text mentioning infrastructure declaration, auto-configured CLAUDE.md, Step 4d/4e, `--issue` auto-detect |

### Test coverage

- T27: `infrastructure` keyword present in /scaffold description in commands.md

---

## Task 7: Test Files

- **Files:** `tests/scenarios/scaffold-v2-happy-path.sh`, `tests/scenarios/scaffold-v2-no-implement.sh`
- **Depends on:** Task 1 (needs final step headings to write correct grep patterns)
- **Blocks:** Task 8
- **Source:** design.md Section 8 (8.1 and 8.2)
- **Estimated edits:** 2 Edit tool operations (1 per file)

### Changes

| # | File | Op | Design Ref | Description |
|---|------|------|------------|-------------|
| 1 | scaffold-v2-happy-path.sh | APPEND | 8.1 | Add 11 assertions: 4 addition checks (0-INFRA, 0-MCP, 4d, 4e), 3 removal regression guards (4b, 4c, "Step 9: Issue Tracker"), 1 ordering check (0-INFRA before Mode Selection), 1 rename check (Step 9: Final Report), 1 absence check (Step 10) |
| 2 | scaffold-v2-no-implement.sh | APPEND | 8.2 | Add 2 assertions: Infrastructure Declaration present, L5b present |

### Test coverage

These ARE the tests — they implement T01 (partial), T08, T09, T10, T11, T12, T20, T21 (partial) as executable assertions.

---

## Task 8: CHANGELOG + Version Bump

- **Files:** `CHANGELOG.md`, `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`
- **Depends on:** Tasks 1-7 (all content changes must be finalized before changelog and version bump)
- **Blocks:** nothing (final task)
- **Source:** design.md Section 7, requirements.md Section 10
- **Estimated edits:** 3 Edit tool operations

### Changes

| # | File | Op | Design Ref | Description |
|---|------|------|------------|-------------|
| 1 | CHANGELOG.md | INSERT | 7 | Add v5.5.0 entry before `## [5.4.1]` with Added/Changed/Removed/Known Limitations/Details sections |
| 2 | plugin.json | REPLACE | 10.1 | Bump `"version"` from `"5.4.1"` to `"5.5.0"` |
| 3 | marketplace.json | REPLACE | 10.1 | Bump `"version"` from `"5.4.1"` to `"5.5.0"` |

### Test coverage

- T31: `## [5.5.0]` present in CHANGELOG.md
- T32: `MINOR` label present near `[5.5.0]` heading
- T33: plugin.json version is `5.5.0`
- T34: marketplace.json version is `5.5.0`

---

## Risk Checkpoints

### Checkpoint 1: After Task 1 (Batch 1 complete)

**Gate:** Run P0 tests against `commands/scaffold.md` only.

| Test | What to check | Severity |
|------|--------------|----------|
| T01 | `Step 4b` absent | P0 |
| T03 | `Step 4c` absent | P0 |
| T06 | `Step 9: Issue Tracker` absent | P0 |
| T07 | `Step 10` absent (including inline "jump to" refs) | P0 |
| T08 | `Step 0-INFRA: Infrastructure Declaration` present | P0 |
| T09 | `Step 0-MCP: MCP Verification` present | P0 |
| T10 | `Step 4d: Push to Remote` present | P0 |
| T11 | `Step 4e: Create Tracker Issues` present | P0 |
| T12 | 0-INFRA line number < Mode Selection line number | P0 |
| T20 | `Step 9: Final Report` present | P0 |
| T21 | `jump to Step 9` present AND `jump to Step 10` absent | P0 |

**Action on failure:** Fix the failing edit in scaffold.md before proceeding to Batch 2. Do NOT start Batch 2 with a broken scaffold.md.

### Checkpoint 2: After Batch 2 complete

**Gate:** Run cross-file consistency tests.

| Test | What to check | Severity |
|------|--------------|----------|
| T02 | `Step 4b` absent from all non-plan/non-changelog files | P0 |
| T04 | `Auto-Finalize` absent from all non-plan files | P1 |
| T05 | `MCP Guidance` absent from all non-plan files | P1 |
| T14 | `0-INFRA` and `0-MCP` in pipelines.md | P0 |
| T16 | `INFRA_DECL` in pipelines.md | P0 |
| T17 | `MCP_CHECK` in pipelines.md | P0 |
| T23 | `Infrastructure Declaration` in README.md | P0 |
| T24 | `Infrastructure Declaration` in architecture.md | P0 |
| T25 | `0-INFRA` and `0-MCP` in CLAUDE.md | P0 |
| T26 | `4d` and `4e` in CLAUDE.md | P0 |
| T28 | `TRACKER` absent from pipelines.md | P0 |

**Action on failure:** Fix the specific doc file that failed. Batch 2 tasks are independent, so fixing one does not invalidate others.

### Checkpoint 3: After Task 8 (Batch 3 complete)

**Gate:** Run full test harness (`./tests/harness/run-tests.sh`) + version checks.

| Test | What to check | Severity |
|------|--------------|----------|
| T31 | `## [5.5.0]` in CHANGELOG.md | P0 |
| T33 | plugin.json version `5.5.0` | P0 |
| T34 | marketplace.json version `5.5.0` | P0 |
| Full | `./tests/harness/run-tests.sh` passes all scenarios | P0 |

**Action on failure:** Fix changelog or version fields. If test harness fails, investigate which scenario broke and trace back to the responsible task.

---

## Commit Strategy

Following project conventions from MEMORY.md:

1. **Single content commit** (after all Batch 1 + Batch 2 + Batch 3 edits pass tests):
   - Stage: `commands/scaffold.md`, `CLAUDE.md`, `README.md`, `docs/architecture.md`, `docs/reference/pipelines.md`, `docs/reference/commands.md`, `tests/scenarios/scaffold-v2-happy-path.sh`, `tests/scenarios/scaffold-v2-no-implement.sh`, `CHANGELOG.md`
   - Message: `feat: scaffold infrastructure redesign (v5.5.0) — front-load infra declaration + MCP verification`

2. **Version bump commit** (separate, after content commit):
   - Stage: `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`
   - Message: `chore: bump version 5.4.1 -> 5.5.0`

3. **Tag:** `v5.5.0`

---

## Total Effort Summary

| Metric | Count |
|--------|-------|
| Files modified | 10 |
| Edit operations | ~24 |
| Test cases covered | 34 (T01-T34) |
| Risk checkpoints | 3 |
| Execution batches | 3 |
| Estimated task parallelism | 6 tasks in Batch 2 |
