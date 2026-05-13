# Phase 7 — Execute

{{PERSONA}}
You are an implementation agent for the ceos-agents Claude Code plugin. You execute precise edits to markdown files following the approved plan. You never deviate from the plan without explicit approval.

{{TASK_INSTRUCTIONS}}

Execute the 8 tasks from the approved plan in order. For each task:

1. Read the target file to confirm current state
2. Apply the edit using the Edit tool (prefer surgical edits over full rewrites)
3. Verify the edit was applied correctly

### T1: agents/e2e-test-engineer.md — Add deployment pre-flight

**Read** the file. Then:

1. After step 2 (ending with "Block with message..."), insert new step 3:

```markdown
3. Deployment pre-flight check — verify application is running or can be started:
   - Read Automation Config for `### Local Deployment` section
   - **If Local Deployment section exists:**
     - Dispatch `deployment-verifier` agent (Task tool, model: sonnet) with context: `Local Deployment config: {full section}. Action: start.`
     - If verdict is `HEALTHY` → proceed to step 4
     - If verdict is `UNHEALTHY`, `PORT_CONFLICT`, or `START_FAILED` → Block with message "E2E tests cannot run: deployment verification failed ({verdict}). Fix deployment issues first."
   - **If Local Deployment section is absent:**
     - Emit warning in output: "Warning: E2E tests require a running application, but Local Deployment is not configured. Configure it via `/ceos-agents:onboard --update` or start the app manually before running E2E tests."
     - Proceed to step 4 (do not block — application may be started externally)
```

2. Renumber existing steps 3→4, 4→5, 5→6, 6→7, 7→8, 8→9
3. Verify: file has steps 1-9, frontmatter intact, section order preserved

### T2: skills/fix-ticket/SKILL.md — Deployment guard before step 8a

Insert before the `### 8a. E2E test-engineer` heading:

```markdown
### 8a-deploy. Deployment verification (pre-E2E)

If the Local Deployment section exists in Automation Config:
- Run `ceos-agents:deployment-verifier` (Task tool, model: sonnet)
  Context: `Local Deployment config: {full section}. Action: start.`
- Verdict handling:
  - `HEALTHY` → proceed to step 8a (E2E test-engineer)
  - `UNHEALTHY`, `PORT_CONFLICT`, `START_FAILED` → proceed to Block handler (step X)
  - `SKIPPED` → proceed to step 8a

If Local Deployment section is absent → skip, proceed to step 8a.
```

### T3: skills/fix-bugs/SKILL.md — Deployment guard before step 7a

Insert before the `### 7a. E2E test-engineer` heading (same content as T2 but with step 7a references):

```markdown
### 7a-deploy. Deployment verification (pre-E2E)

If the Local Deployment section exists in Automation Config:
- Run `ceos-agents:deployment-verifier` (Task tool, model: sonnet)
  Context: `Local Deployment config: {full section}. Action: start.`
- Verdict handling:
  - `HEALTHY` → proceed to step 7a (E2E test-engineer)
  - `UNHEALTHY`, `PORT_CONFLICT`, `START_FAILED` → proceed to Block handler (step X)
  - `SKIPPED` → proceed to step 7a

If Local Deployment section is absent → skip, proceed to step 7a.
```

### T4: skills/implement-feature/SKILL.md — Deployment guard before step 6f

Insert before the `#### 6f. E2E test (optional)` heading:

```markdown
#### 6f-deploy. Deployment verification (pre-E2E)

If the Local Deployment section exists in Automation Config:
- Run `ceos-agents:deployment-verifier` (Task tool, model: sonnet)
  Context: `Local Deployment config: {full section}. Action: start.`
- Verdict handling:
  - `HEALTHY` → proceed to step 6f (E2E test)
  - `UNHEALTHY`, `PORT_CONFLICT`, `START_FAILED` → proceed to step X (Block handler)
  - `SKIPPED` → proceed to step 6f

If Local Deployment section is absent → skip, proceed to step 6f.

```

### T5: skills/scaffold/SKILL.md — Deployment guard before Step 8

Insert after the `If verdict is PASS or PARTIAL → continue to Step 8.` line and before `### Step 8: E2E Tests`:

Add deployment-verifier dispatch inside Step 8, before the e2e-test-engineer call:

```
If E2E Test section exists in generated CLAUDE.md:

  **Deployment verification (pre-E2E):**
  If the Local Deployment section exists in generated CLAUDE.md:
  - Run `ceos-agents:deployment-verifier` (Task tool, model: sonnet)
    Context: `Local Deployment config: {full section}. Action: start.`
  - If verdict is not `HEALTHY` and not `SKIPPED` → report as warning (do not block — scaffold is best-effort for E2E)

  Run e2e-test-engineer agent...
```

### T6: CHANGELOG.md — Add v6.2.0 entry

Insert after the header block (line 8) and before the `## [6.1.9]` entry.

### T7: Version bump

Edit both files: `"version": "6.1.9"` → `"version": "6.2.0"`

### T8: Roadmap update

1. Update version line at top
2. Move the "E2E Test Engineer: Deployment Guard" item from PLANNED — Next to a new DONE — v6.2.0 section

### Post-execution

Run `./tests/harness/run-tests.sh` and verify all scenarios pass.

{{SUCCESS_CRITERIA}}
- All 8 tasks completed without errors
- e2e-test-engineer.md has 9 numbered steps with deployment pre-flight as step 3
- All 4 skill files have deployment-verifier dispatch before e2e-test-engineer
- CHANGELOG has v6.2.0 entry
- Version is 6.2.0 in both plugin files
- Roadmap updated
- Test suite passes

{{ANTI_PATTERNS}}
- Do not rewrite entire files — use surgical Edit tool operations
- Do not modify deployment-verifier.md
- Do not change existing step logic — only add new steps/sub-steps
- Do not remove the existing "NEVER run without a live application" constraint — it stays as documentation

{{CODEBASE_CONTEXT}}
- e2e-test-engineer.md: 68 lines, steps 1-8
- fix-ticket step 8a starts at line ~298
- fix-bugs step 7a starts at line ~285
- implement-feature step 6f starts at line ~301
- scaffold Step 8 starts at line ~720
- CHANGELOG latest entry is [6.1.9] at line 10
- plugin.json version at line 4
- marketplace.json version at line 10
