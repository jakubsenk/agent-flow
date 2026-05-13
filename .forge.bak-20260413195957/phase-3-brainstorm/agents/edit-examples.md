# Phase 3 — Agent Edit Examples (BEFORE / AFTER)

Each example shows the **exact current text** and the **proposed replacement**.
Line numbers refer to the current file on disk.

---

## agents/fixer.md

### Change 1: Frontmatter `description` — make mode-neutral

CURRENT (line 3):
> `description: Implements minimal, correct bug fixes targeting root cause. Surgical changes with backwards compatibility.`

PROPOSED:
> `description: Implements minimal, correct code changes targeting the goal. Bug fixes, feature subtasks, or scaffold implementation steps — surgical changes with backwards compatibility.`

WHY: The current description only mentions bug fixes. The fixer is dispatched for feature subtasks and scaffold implementation too.

---

### Change 2: `## Goal` — mode-neutral language

CURRENT (line 12):
> `Minimal correct fix that solves the root cause. Simplest solution that doesn't break anything.`

PROPOSED:
> `Minimal correct change that achieves the objective. In bug-fix mode: solve the root cause. In feature/scaffold mode: implement the assigned subtask. Simplest solution that doesn't break anything.`

WHY: "Solves the root cause" only makes sense for bugs. Feature subtasks have an objective, not a root cause.

---

### Change 3: Step 1 guard — accept spec-analyst / architect output as valid input

CURRENT (line 20):
> `1. Read the triage analysis and impact report thoroughly. If triage analysis or impact report is missing, Block with reason 'Missing input from previous pipeline stage'.`

PROPOSED:
> `1. Read the upstream analysis thoroughly. Depending on pipeline mode:`
> `   - **Bug-fix mode:** Read triage analysis and impact report. If either is missing, Block with reason 'Missing input from previous pipeline stage'.`
> `   - **Feature mode:** Read spec-analyst output (acceptance criteria, scope) and architect task tree (subtask assignment, maps_to). If subtask assignment is missing, Block with reason 'Missing input from previous pipeline stage'.`
> `   - **Scaffold mode:** Read architect task tree and spec (from spec/ folder). If task assignment is missing, Block with reason 'Missing input from previous pipeline stage'.`

WHY: The current guard rejects feature/scaffold invocations because they don't carry a "triage analysis". The fixer needs to accept the correct upstream artifacts for each mode.

---

### Change 4: Step 5 RED phase — mode-aware test framing

CURRENT (line 29):
> `   - **RED:** Write a test that reproduces the bug. Run it — confirm it FAILS. If the test passes, your test does not capture the actual bug; rewrite it.`

PROPOSED:
> `   - **RED:** Write a test that verifies the expected behavior.`
> `     - *Bug-fix mode:* The test reproduces the bug — run it, confirm it FAILS. If the test passes, it does not capture the actual bug; rewrite it.`
> `     - *Feature/scaffold mode:* The test asserts the new behavior that does not exist yet — run it, confirm it FAILS. If the test passes, the behavior already exists; verify your test is correct.`

WHY: "Reproduces the bug" is meaningless for feature implementation. TDD RED means "write a failing test for the desired behavior" — which for features means asserting new behavior.

---

### Change 5: Step 8 output template — mode-aware report

CURRENT (lines 54-61):
> ```markdown
> ## Fix Report
> - **Root cause:** {what was wrong and why}
> - **Approach:** {what was done and why this approach over alternatives}
> - **Files changed:** {list with brief description of each change}
> - **Build:** PASS
> - **Tests:** PASS / {note about pre-existing failures}
> ```

PROPOSED:
> ```markdown
> ## Fix Report
> - **Mode:** {bug-fix | feature | scaffold}
> - **Objective:** {bug-fix: root cause and what was wrong | feature/scaffold: subtask goal and AC addressed}
> - **Approach:** {what was done and why this approach over alternatives}
> - **Files changed:** {list with brief description of each change}
> - **Build:** PASS
> - **Tests:** PASS / {note about pre-existing failures}
> ```

WHY: "Root cause" is bug-specific. Replacing with a generic "Objective" field with mode-specific guidance keeps the report useful for all modes. Adding a "Mode" field makes the report self-describing.

---

## agents/reviewer.md

### Change 1: Step 1 — accept feature/scaffold inputs

CURRENT (line 20):
> `1. Read the original bug report, triage analysis, impact report, and the fixer's output (changed files, approach, reasoning)`

PROPOSED:
> `1. Read the upstream context and the fixer's output (changed files, approach, reasoning):`
> `   - **Bug-fix mode:** Original bug report, triage analysis, impact report.`
> `   - **Feature mode:** Spec-analyst output (acceptance criteria), architect task tree (subtask assignment, maps_to).`
> `   - **Scaffold mode:** Architect task tree and spec (from spec/ folder).`

WHY: The reviewer currently expects a "bug report" and "triage analysis" which don't exist in feature/scaffold pipelines. It needs to know what upstream artifacts to look for.

---

### Change 2: "Root cause" checklist item — mode-aware

CURRENT (line 31):
> `   - **Root cause:** Does the fix address the actual root cause, not just symptoms?`

PROPOSED:
> `   - **Objective correctness:** Does the change achieve its stated objective?`
> `     - *Bug-fix mode:* Does it address the actual root cause, not just symptoms?`
> `     - *Feature/scaffold mode:* Does it fully implement the assigned subtask per the acceptance criteria?`

WHY: "Root cause" is a bug-fix concept. For features, the equivalent question is "does it implement the requirement correctly?"

---

### Change 3: AC Fulfillment constraint — always applies when AC exist

CURRENT (line 108):
> `- If acceptance criteria were provided in context, MUST include AC Fulfillment section in output. If no AC provided, skip the section.`

PROPOSED:
> `- If acceptance criteria were provided in context (from triage analysis in bug-fix mode, or from spec-analyst/architect in feature/scaffold mode), MUST include AC Fulfillment section in output. If no AC provided, skip the section.`

WHY: The current text implies AC only come from triage. In feature mode they come from spec-analyst; in scaffold mode from the spec. Making the source explicit avoids confusion.

---

## agents/test-engineer.md

### Change 1: Frontmatter `description` — mode-neutral

CURRENT (line 3):
> `description: Writes and runs unit tests verifying the fix and preventing regressions. Follows project test framework conventions.`

PROPOSED:
> `description: Writes and runs unit tests verifying the change and preventing regressions. Follows project test framework conventions.`

WHY: "Verifying the fix" is bug-specific. "Verifying the change" is neutral.

---

### Change 2: Step 1 — accept feature/scaffold inputs

CURRENT (line 20):
> `1. Read the bug report, fixer output (changed files, root cause), and impact report (test coverage section)`

PROPOSED:
> `1. Read upstream context and fixer output (changed files, objective):`
> `   - **Bug-fix mode:** Bug report, fixer output (root cause), impact report (test coverage section).`
> `   - **Feature mode:** Spec-analyst output (AC), architect subtask, fixer output (objective, files changed).`
> `   - **Scaffold mode:** Spec (from spec/ folder), architect subtask, fixer output (objective, files changed).`

WHY: The test-engineer currently expects a "bug report" and "impact report" that don't exist in feature/scaffold pipelines.

---

### Change 3: Step 3 — mode-aware test planning

CURRENT (lines 25-27):
> `   - **Required:** One test verifying the specific behavior that was fixed (regression test)`
> `   - **Recommended:** One test for the most likely edge case from the impact report`
> `   - **Optional:** One test for boundary conditions if the fix involves numeric/string/collection operations`

PROPOSED:
> `   - **Required:** One test verifying the specific behavior that was changed:`
> `     - *Bug-fix mode:* Regression test — ensures the bug does not recur.`
> `     - *Feature/scaffold mode:* Acceptance test — asserts the new behavior matches the AC.`
> `   - **Recommended:** One test for the most likely edge case (from impact report in bug-fix mode, or from AC boundary conditions in feature/scaffold mode)`
> `   - **Optional:** One test for boundary conditions if the change involves numeric/string/collection operations`

WHY: "Regression test" framing is bug-specific. For features, the equivalent is an acceptance test. The recommended/optional bullets also needed minor updates to avoid referencing bug-only artifacts.

---

## agents/publisher.md

### Change 1: PR title format — mode-aware prefix

CURRENT (line 57):
> `   - **Title:** Use issue summary (from issue tracker), NOT the branch name. Format: `[PROJ-123] Fix: {concise description}``

PROPOSED:
> `   - **Title:** Use issue summary (from issue tracker), NOT the branch name. Format depends on pipeline mode:`
> `     - *Bug-fix:* `[PROJ-123] Fix: {concise description}``
> `     - *Feature:* `[PROJ-123] Feat: {concise description}``
> `     - *Scaffold:* `[PROJ-123] Scaffold: {concise description}``

WHY: All PRs currently say "Fix:" even when implementing a feature. The prefix should reflect the type of work.

---

### Change 2: PR description template fields — mode-aware

CURRENT (lines 58-59):
> `   - **Description:** Use PR Description Template from Automation Config (always English). Fill in ALL template sections:`
> `     - Summary, Root Cause, Changes, Testing, Issue link`

PROPOSED:
> `   - **Description:** Use PR Description Template from Automation Config (always English). Fill in ALL template sections:`
> `     - *Bug-fix mode:* Summary, Root Cause, Changes, Testing, Issue link`
> `     - *Feature/scaffold mode:* Summary, Objective (replaces Root Cause), Changes, Testing, Issue link`
> `     - If the template contains a "Root Cause" section and the mode is feature/scaffold, rename it to "Objective" and describe what was implemented and why.`

WHY: "Root Cause" is meaningless for features/scaffold. The publisher should adapt the template section name.

---

### Change 3: Commit message example — mode-aware

CURRENT (line 47):
> `- Example: `fix(auth): prevent token expiration on refresh [PROJ-123]``

PROPOSED:
> `- Examples:`
> `  - *Bug-fix:* `fix(auth): prevent token expiration on refresh [PROJ-123]``
> `  - *Feature:* `feat(auth): add OAuth2 PKCE flow [PROJ-456]``
> `  - *Scaffold:* `scaffold(init): set up project structure and CI [PROJ-789]``

WHY: The commit message prefix should follow conventional commits style and reflect the pipeline mode.

---

## agents/rollback-agent.md

### Change 1: Step 1 trigger allowlist — add smoke-check as rollback trigger

CURRENT (line 26):
> `- If the blocking agent is `fixer`, `test-engineer`, `e2e-test-engineer`, or `reviewer` → proceed with rollback.`

PROPOSED:
> `- If the blocking agent is `fixer`, `test-engineer`, `e2e-test-engineer`, `reviewer`, or the blocking step is `smoke-check` → proceed with rollback.`

WHY: The smoke-check step (build + test between fixer and test-engineer) can fail and leave dirty git state. It needs to be a rollback trigger. Using "blocking step" rather than "blocking agent" because smoke-check is a pipeline step, not an agent.

---

### Change 2: Constraint update — reflect the new trigger

CURRENT (line 91):
> `- NEVER rollback if called after a read-only agent block (triage-analyst, code-analyst, spec-analyst, architect, stack-selector), publisher block, or scaffolder block — handled in Step 1`

PROPOSED:
> `- NEVER rollback if called after a read-only agent block (triage-analyst, code-analyst, spec-analyst, architect, stack-selector), publisher block, or scaffolder block — handled in Step 1. Smoke-check blocks DO trigger rollback.`

WHY: Explicitly documenting that smoke-check is an exception to the "no rollback for non-agent steps" assumption.

---

## core/block-handler.md

### Change 1: Rollback trigger list — add smoke-check, e2e-test-engineer

CURRENT (line 21):
> `1. **Rollback:** If the blocking agent is `fixer`, `reviewer`, or `test-engineer` → dispatch `ceos-agents:rollback-agent` (Task tool, model: haiku). Context: `Agent: {agent_name}. Step: {step_name}. Reason: {reason}. Detail: {detail}. Recommendation: {recommendation}. Execution context: CWD (no worktree).``

PROPOSED:
> `1. **Rollback:** If the blocking agent is `fixer`, `reviewer`, `test-engineer`, or `e2e-test-engineer`, OR the blocking step is `smoke-check` → dispatch `ceos-agents:rollback-agent` (Task tool, model: haiku). Context: `Agent: {agent_name}. Step: {step_name}. Reason: {reason}. Detail: {detail}. Recommendation: {recommendation}. Execution context: CWD (no worktree).``

PROPOSED (line 22 addition after the rollback line):
> `   Do NOT rollback on block from `triage-analyst`, `code-analyst`, `spec-analyst`, `architect`, or `stack-selector` — no git changes to revert.`

WHY: Two issues with the current block-handler:
1. `e2e-test-engineer` is missing from the trigger list (the rollback-agent itself already handles it in Step 1, but block-handler should dispatch rollback for it too).
2. `smoke-check` can block the pipeline after the fixer has made git changes — it needs rollback.
3. The "Do NOT rollback" line currently only mentions `triage-analyst` and `code-analyst` — it should list all read-only agents for consistency with the rollback-agent's own allowlist.
