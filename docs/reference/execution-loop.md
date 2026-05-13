# Execution Loop Reference

The fixer/reviewer/test-engineer execution loop is the core pattern shared across all pipeline skills. This document describes the canonical loop for human editors maintaining skill definitions.

## Canonical Loop

```
FIXER (opus) → BUILD → REVIEWER (opus) → TEST-ENGINEER (sonnet) → COMMIT
  ↑                         |
  └── REQUEST_CHANGES ──────┘
```

### Steps

1. **Fixer** — implements changes based on scope and acceptance criteria
   - Context must include: `Max build retries = {N}.`
   - After completion: run Build command
   - Build failure: fixer retries (up to Build retries limit)
   - Build still failing: Block handler

2. **Reviewer** — reviews diff against acceptance criteria
   - Context must include: `Max fixer iterations = {N}.`
   - APPROVE: continue to test-engineer
   - REQUEST_CHANGES: back to fixer with feedback
   - Max Fixer iterations exhausted: Block handler

3. **Test-engineer** — writes/fixes tests, runs Test command
   - Context must include: `Max test attempts = {N}.`
   - Test failure: test-engineer retries (up to Test attempts limit)
   - Still failing: Block handler

4. **Commit** — `git add -A && git commit -m "{message}"`

## Block Handler

On block from fixer, reviewer, or test-engineer:

1. Run **rollback-agent** (haiku) — revert git state to last successful commit
   - Context must include issue tracker instructions (or skip instruction for scaffold)
2. Set issue state to Blocked (if issue tracker context exists)
3. Add Block comment (issue tracker or stdout):
   ```
   [ceos-agents] 🔴 Pipeline Block
   Agent: {agent name}
   Step: {pipeline step}
   Reason: {max 2 sentences}
   Detail: {error output}
   Recommendation: {what human should do}
   ```
4. Follow Fail strategy (fail-fast or continue)

## Default Retry Limits

| Limit | Default | Config Key |
|-------|---------|------------|
| Fixer iterations | 5 | Retry Limits → Fixer iterations |
| Test attempts | 3 | Retry Limits → Test attempts |
| Build retries | 3 | Retry Limits → Build retries |

## Where the Loop Appears

| Skill | Context | Hooks | Commit prefix |
|-------|---------|-------|---------------|
| fix-bugs.md | Single bug or batch bugs, optional worktrees | Yes (all 4) | `fix` |
| implement-feature.md | Feature subtasks | Yes (all 4) | `feat` |
| scaffold.md | Greenfield project features | No (project being created) | `feat` |

## Consistency Rules

Skills are self-contained (no shared imports). Consistency is enforced by `tests/scenarios/pipeline-consistency.sh`, which checks:

1. Block comment format includes emoji
2. Subtask commits use `git add -A`
3. Retry limits are mentioned for each agent
4. Safety checks include explicit failure actions
5. Rollback-agent context includes issue tracker instructions
