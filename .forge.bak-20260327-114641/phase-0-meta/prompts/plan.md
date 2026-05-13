# Phase 6 — Implementation Plan

## Persona

{{PERSONA}}: You are a **Technical Project Planner** specializing in multi-file markdown refactoring for developer tooling plugins. You excel at decomposing complex changes into ordered, dependency-aware tasks that minimize the risk of inconsistency. You understand that in a pure-markdown codebase, the biggest risk is not broken code but broken cross-references — a diagram that shows the old flow, a table that lists a removed step, a description that references a step that no longer exists.

## Task Instructions

{{TASK_INSTRUCTIONS}}:

Using the specification (Phase 4) and test cases (Phase 5), produce a detailed implementation plan with ordered tasks, dependencies, and verification checkpoints.

### Plan Structure

#### 1. Task Decomposition

Break the implementation into discrete tasks. Each task must:
- Modify exactly ONE file (or a tightly coupled pair)
- Have clear inputs (what information is needed) and outputs (what the file looks like after)
- Have explicit dependencies on other tasks
- Include a verification step (which Phase 5 test cases it satisfies)

#### 2. Recommended Task Order

The recommended order should follow this principle: **modify the source of truth first, then cascade to dependents.**

Suggested ordering:
1. **T1: scaffold.md — Remove Steps 4b, 4c, 9** (clean up first)
2. **T2: scaffold.md — Add Step 0-INFRA** (new infrastructure declaration)
3. **T3: scaffold.md — Add Step 0-MCP** (new MCP verification)
4. **T4: scaffold.md — Modify Step 4** (git init + auto-config)
5. **T5: scaffold.md — Add Steps 4d, 4e** (push + tracker issues)
6. **T6: scaffold.md — Modify Step 10** (report with infrastructure status)
7. **T7: scaffold.md — Update MCP Pre-flight Check, --no-implement flow, Rules** (cleanup)
8. **T8: docs/reference/pipelines.md** — Update scaffold stages table, mermaid diagram
9. **T9: docs/architecture.md** — Update scaffold pipeline section, mermaid diagram
10. **T10: CLAUDE.md** — Update Scaffold Pipeline description
11. **T11: README.md** — Update scaffold pipeline description, mermaid diagram
12. **T12: docs/reference/commands.md** — Update /scaffold command description
13. **T13: CHANGELOG.md** — Add v5.5.0 entry

#### 3. Verification Checkpoints

After each group of tasks, define a checkpoint that runs specific Phase 5 test cases:
- **Checkpoint A (after T7):** All scaffold.md tests pass — removed steps gone, new steps present
- **Checkpoint B (after T12):** All cross-file consistency tests pass — no stale references
- **Checkpoint C (after T13):** CHANGELOG tests pass — version entry is correct

#### 4. Risk Register

For each identified risk, specify:
- **Risk:** What might go wrong
- **Likelihood:** Low/Medium/High
- **Impact:** Low/Medium/High
- **Mitigation:** Specific action to prevent or detect

Key risks:
1. Stale reference to Step 4b/4c/9 in a documentation file (Medium likelihood, Medium impact)
2. Mermaid diagram inconsistency between files (Medium likelihood, Low impact)
3. Step numbering confusion (0-INFRA vs 0a naming) (Low likelihood, Low impact)
4. Missing conditional handling for "later" services in Step 4 (Low likelihood, High impact)

#### 5. Rollback Strategy

If implementation is partially complete and a blocking issue is found:
- scaffold.md changes are self-contained — partial rollback is possible
- Documentation changes depend on scaffold.md — if scaffold.md rollbacks, docs must too
- CHANGELOG entry should be the last task — easy to omit if needed

## Success Criteria

{{SUCCESS_CRITERIA}}:
- Every task modifies exactly one file (except tightly coupled pairs with clear justification)
- Dependencies form a DAG (no cycles)
- Every Phase 5 test case is covered by at least one task's verification step
- The plan is executable in order without backtracking
- Risk mitigations are actionable (not just "be careful")
- Total estimated tasks: 13 or fewer (complexity budget)

## Anti-Patterns

{{ANTI_PATTERNS}}:
- DO NOT create tasks that modify multiple unrelated files — each task should be atomic
- DO NOT plan to modify docs/plans/*.md — those are historical ADRs
- DO NOT plan to modify agent definitions — no agent changes in this version
- DO NOT plan to modify init.md — it was verified as compatible in Phase 2
- DO NOT plan to run the test harness (run-tests.sh) as part of the plan — use grep-based verification instead
- DO NOT defer verification to the end — include checkpoints after each major group
- DO NOT skip the CHANGELOG task — it is required by project conventions
- DO NOT plan version bump as part of this plan — version bump is a separate step per project conventions

## Codebase Context

{{CODEBASE_CONTEXT}}:
- **Files to modify (13 max):**
  1. `commands/scaffold.md` — primary target (7 sub-tasks: remove 3 steps, add 4 steps/sections, modify 3 sections)
  2. `docs/reference/pipelines.md` — stages table, mermaid diagram
  3. `docs/architecture.md` — scaffold pipeline section, mermaid diagram
  4. `CLAUDE.md` — Scaffold Pipeline description
  5. `README.md` — scaffold pipeline section, mermaid diagram
  6. `docs/reference/commands.md` — /scaffold command description
  7. `CHANGELOG.md` — v5.5.0 entry
- **Files NOT modified:** commands/init.md, agents/*.md, skills/*.md, core/*.md, docs/plans/*.md, tests/*.md, examples/*.md
- **Edit tool constraint:** Each edit requires unique `old_string` match in the file. Plan edits with sufficient context for uniqueness.
- **Commit strategy:** Per project conventions, content changes and CHANGELOG go in the same commit. Version bump is a separate commit.
