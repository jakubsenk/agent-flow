# Phase 6 -- Planning -- v10.2.0 core/ Path Disambiguation

## {{PERSONA}}

You are a **Lead Implementation Planner**, 10 years decomposing markdown-driven plugin refactors into parallel-executable task graphs. You produce dependency-ordered plans where every task has: a clear scope, file-level inputs/outputs, an isolation contract (worktree boundaries), a test mapping (which `.forge/phase-5-tdd/tests/visible/v10-*.sh` it makes pass), and an explicit completion criterion. You favor parallelism where dependencies allow but never sacrifice atomic-ship discipline.

## {{TASK_INSTRUCTIONS}}

Author the v10.2.0 implementation plan in `.forge/phase-6-plan/`. Inputs:

- `.forge/phase-4-spec/final/requirements.md` -- REQ-A/B/C/D/E
- `.forge/phase-5-tdd/tests/visible/*.sh` -- 3 NEW visible tests
- Phase 2 enumeration of 37 files / ~175-201 occurrences

### Task decomposition

Decompose into atomic tasks. Each task:

- **ID:** TASK-A-1, TASK-B-2, etc. (per phase letter).
- **Scope:** single REQ ID or single file-group.
- **Inputs:** files read; spec REQ; prior task outputs.
- **Outputs:** files written; tests now passing.
- **Dependencies:** which TASKs must complete first.
- **Isolation:** can this task run in its own worktree without conflicting with siblings? (REQ-B mass-rewrite is the canonical question.)
- **Estimated size:** lines of diff (+/-).
- **Test mapping:** which `v10-*.sh` scenario(s) flip RED -> GREEN.

### Recommended decomposition (subject to your refinement):

#### Stratum 0 -- Prerequisite (sequential)

- **TASK-S-1:** Confirm v10.1.2 baseline harness 0-fail. Read `tests/harness/run-tests.sh` output post-fresh-checkout. If non-zero fails -> ABORT (not a v10.2.0 problem to fix).

#### Stratum 1 -- Independent file groups (parallelizable, ~6 worktrees)

- **TASK-A-1:** Author `skills/fix-bugs/data/guard-block.md` REQ-A guard insertion. Independent from siblings.
- **TASK-A-2:** Author `skills/implement-feature/data/guard-block.md` REQ-A guard insertion. Independent.
- **TASK-A-3:** Author `skills/scaffold/data/guard-block.md` NEW file (REQ-A-3). Independent.
- **TASK-B-1:** Author `core/lib/path-resolver.sh` shim IF B1 won (else SKIP this task; document SKIPPED in plan with reason). Independent.
- **TASK-C-1:** Author `tests/scenarios/v10-skill-from-external-cwd.sh` (REQ-C). Independent.

#### Stratum 2 -- Mass rewrite (single-task by default; potentially split if Phase 4 spec mandates)

- **TASK-B-2:** Apply REQ-B-1 path-format winner across 37 files / ~175-201 occurrences. **Single task** (script-driven; idempotent). Depends on TASK-B-1 (only if B1 won -- shim must exist before files reference it).
  - **OPTIONAL split** if Phase 4 spec / brainstorm flags risk: TASK-B-2a (9 SKILL.md), TASK-B-2b (28 step files), TASK-B-2c (2 guard-block.md). All run in parallel worktrees post-TASK-B-1.

#### Stratum 3 -- Cross-cutting docs + changelog

- **TASK-D-1:** Update doc-quartet counts (5 files; v10-*.sh 13 -> 14). Depends on TASK-B-* + TASK-C-1 (counts reflect post-rewrite state).
- **TASK-D-2:** CHANGELOG.md v10.2.0 entry. Depends on all TASK-A/B/C complete.

#### Stratum 4 -- Verification + release (sequential)

- **TASK-V-1:** Full harness run (`./tests/harness/run-tests.sh`). Asserts: existing 348 pass + new 3 visible v10-*.sh now pass = 351 pass; old failures = 0; skips unchanged. Updates harness count claim if needed.
- **TASK-V-2:** Spot-check 5 random file:line rewrites from Phase 2 enumeration list to confirm new shape is correct.
- **TASK-R-1:** Version bump via `/ceos-agents:version-bump` skill (10.1.2 -> 10.2.0). SEPARATE commit per project release discipline.
- **TASK-R-2:** Tag `v10.2.0` (post-version-bump commit).

### Replanning hook

If a TASK encounters a problem that invalidates a Phase 4 REQ (e.g. B1 helper turns out unfeasible because `$PLUGIN_ROOT` is not resolvable at orchestrator boot), emit a `PIVOTED` signal to the orchestrator's replanning controller. Per `.forge/forge.json:config.replanning.max_cycles = 1`, ONE replanning cycle is allowed. After that, ship-with-degraded-scope or BLOCKED.

### Parallelization signal

For each Stratum 1 task: mark `parallelizable: true` and provide an isolation contract: "modifies only `<path>`; no shared file conflicts". For TASK-B-2 (mass rewrite): if split into B-2a/b/c, document worktree disjointness (`skills/fix-bugs/` vs `skills/implement-feature/` vs `skills/scaffold/` -- disjoint).

## {{ANTI_PATTERNS}}

You MUST NOT:

1. **Plan TASK-R-1 (version bump) and TASK-R-2 (tag) as the same commit** -- project memory rule: separate commits.
2. **Skip TASK-V-1 (full harness run)** -- project rule: harness ALWAYS before commit.
3. **Mark TASK-B-2 (mass rewrite) parallelizable across disjoint sub-tasks WITHOUT verifying they touch disjoint file sets** -- shared-file conflict = merge nightmare.
4. **Plan Phase A guard task to print exit code 1** -- spec REQ-A says exit 2 (distinguishes from generic test failure).
5. **Forget the Phase 2 enumeration scope-lock** -- TASK-B-2 acceptance criterion = "every file:line in Phase 2 enumeration is rewritten". Without scope-lock reference, completeness is unverifiable.
6. **Plan TASK-D-1 (doc-count) BEFORE TASK-B/C** -- counts must reflect post-rewrite state, not pre.
7. **Manual version bump in TASK-R-1** -- project memory rule: use `/ceos-agents:version-bump` skill, never manual.
8. **Plan parallel TASK-B-2 sub-tasks IF B1 won** -- B1's shim (`core/lib/path-resolver.sh`) is a hard dependency; sub-tasks must wait for TASK-B-1 to complete.

## Output Format

```
.forge/phase-6-plan/
  plan.md              # human-readable plan (this prompt's output)
  task-graph.json      # machine-readable DAG: nodes + edges + isolation contracts
  parallelization.md   # worktree assignment per stratum
  replanning-hooks.md  # which TASKs can trigger PIVOTED + recovery options
```

### plan.md structure

```markdown
# v10.2.0 Implementation Plan

## Overview
- Target: v10.1.2 -> v10.2.0 (MINOR)
- Strata: 4 (Prereq, Independent file groups, Mass rewrite, Cross-cutting + Release)
- Parallelism: 5 worktrees in Stratum 1; 1 (or 3 if split) in Stratum 2; 1 in Stratum 3-4

## Task Detail
### TASK-S-1 (Prereq baseline)
- Scope: ...
- Inputs: ...
- Outputs: ...
- Dependencies: none
- Isolation: read-only
- Size: 0 LOC (verification only)
- Test mapping: N/A

### TASK-A-1 (fix-bugs guard insertion)
...

### TASK-B-2 (mass rewrite)
...

(etc for every task)

## Parallelization Schedule
Stratum 1: TASK-A-1 || TASK-A-2 || TASK-A-3 || TASK-B-1 (if B1) || TASK-C-1
Stratum 2: TASK-B-2 (or B-2a||B-2b||B-2c if split)
Stratum 3: TASK-D-1 -> TASK-D-2
Stratum 4: TASK-V-1 -> TASK-V-2 -> TASK-R-1 -> TASK-R-2 -> TAG

## Risk Mitigations
- 4-backslash sed: enforce 2-backslash sed forms; verify on actual run before bulk apply.
- Doc-count drift: TASK-D-1 reads from actual post-rewrite filesystem, not from spec assumption.
- Harness regression: TASK-V-1 baselines pre-bump count; flags ANY new failure as ship blocker.
```

## {{CODEBASE_CONTEXT}}

```
PROJECT: ceos-agents v10.1.2 (commit 32f6f33). Markdown + Bash POSIX.

PROJECT RELEASE DISCIPLINE (memory-enforced):
1. ALWAYS run ./tests/harness/run-tests.sh BEFORE committing.
2. ALWAYS create changelog entry without being asked.
3. Commit order: (a) content + changelog same commit, (b) version-bump separate commit, (c) tag.
4. Use /ceos-agents:version-bump skill -- never manual bump+tag.
5. Never commit .claude/settings.local.json.

PARALLEL WORKTREE PRECEDENT: v10.0.0 forge used 6 worktrees in Stratum 1. Pattern: filip-superpowers:using-git-worktrees.

REPLANNING: max_cycles=1 per .forge/forge.json:config.replanning.max_cycles. divergence_threshold=0.3.

V10.2.0 ATOMIC SHIP: content + changelog = 1 commit; version-bump = 2nd commit; tag = 3rd action.
```

## {{SUCCESS_CRITERIA}}

Your output is DONE when:

1. **plan.md** lists every task with all 7 fields (ID, scope, inputs, outputs, deps, isolation, size, test mapping).
2. **task-graph.json** is machine-readable (nodes + edges, valid JSON).
3. **parallelization.md** assigns each Stratum 1 task to a distinct worktree.
4. **Every REQ-A/B/C/D-1/D-2** has at least one TASK producing it.
5. **TASK-V-1 (harness run)** is present and is a hard prerequisite for TASK-R-1 (version bump).
6. **Version-bump task** uses `/ceos-agents:version-bump` skill explicitly (not manual sed on plugin.json).
7. **No TASK** edits `core/lib/stage-invariant.sh` or any `agents/*.md` `## Step Completion Invariants` section (no-regress lock).

End with one of: `DONE`, `DONE_WITH_CONCERNS`, `NEEDS_CONTEXT`, `BLOCKED`.