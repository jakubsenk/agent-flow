# Phase 2 — Research Answers

## Persona

You are synthesizing the research findings from Phase 1 into actionable answers. Reference specific files, line numbers, and content from the codebase.

## Task Context

Patch v6.3.2 → v6.3.3: three changes to strengthen pipeline output verification.

## Instructions

For each research question from Phase 1, provide:
1. A direct answer citing specific file content
2. Any constraints or dependencies discovered
3. Impact on the planned changes

## Pre-Loaded Research Findings

Based on the codebase analysis already performed by the meta-agent:

### A1: Scaffold Step 3 Current Validation

**File:** `skills/scaffold/SKILL.md`, lines 440-464

Current Step 3 text:
```
Validation: build + test + lint + CLAUDE.md check (max 3 retries)
  If 3 failures → delete temp, report error, STOP.
```

This is a **one-line summary** inside the scaffolder dispatch. It delegates validation entirely to the scaffolder agent itself (step 4 in `agents/scaffolder.md`). The skill does NOT independently run build/test commands — it trusts the scaffolder's self-report.

The legacy flow (L3, lines 279-298) is more explicit: it lists 4 checks (build, test, lint, CLAUDE.md) and has retry logic. But even L3 says "detect the build system, run build command" which is agent-internal.

**Key finding:** The current Step 3 relies on the scaffolder agent to validate itself. The skill layer does NOT independently verify by running build+test commands from the generated CLAUDE.md's Automation Config.

### A2: Scaffolder Scorecard Current State

**File:** `agents/scaffolder.md`, lines 149-161

Step 4b is explicitly labeled "informational — does NOT block". The scorecard items 1-3 (Build, Tests, Lint) are already checked in step 4, but step 4b re-reports them as a scorecard. The scorecard is purely informational — a failing scorecard item does NOT cause the scaffolder to fail.

Step 4 (lines 143-148) does verify build/test/lint and retries max 3 times. So the scaffolder DOES run real commands internally. But the scorecard in step 4b is presentation-only.

**Key finding:** The scaffolder already runs build+test in step 4 with retries. The scorecard (step 4b) just reports results. The change needed is to make the scorecard items "Builds successfully" and "Tests pass" into hard gate conditions (blocking, not advisory).

### A3: Fix-Ticket Pipeline Flow After Reviewer

**File:** `skills/fix-ticket/SKILL.md`

Current flow:
- Step 5: Fixer
- Step 6: Build (runs Build command, retries)
- Step 6a: Post-fix hook
- Step 6b: Post-fix custom agent
- Step 7: Reviewer (fixer↔reviewer loop)
- Step 8: Test-engineer

Step 6 runs the Build command BEFORE the reviewer. After the reviewer approves (step 7), the pipeline goes directly to test-engineer (step 8) without re-running build or tests.

**Key finding:** There is NO build/test verification between reviewer approval and test-engineer dispatch. If the fixer made changes during the reviewer loop iterations, those changes were reviewed but never build-verified before going to test-engineer. The smoke check should be inserted between step 7 (Reviewer) and step 8 (Test-engineer).

Note: The `core/fixer-reviewer-loop.md` (step 4) does run Build command after each fixer iteration. So builds ARE checked during the loop. But existing tests are NOT run — only the build command.

### A4: Fix-Bugs Pipeline Flow After Reviewer

**File:** `skills/fix-bugs/SKILL.md`

Same pattern:
- Step 4: Fixer
- Step 5: Build
- Step 5a: Post-fix hook
- Step 5b: Post-fix custom agent
- Step 6: Reviewer (fixer↔reviewer loop)
- Step 7: Test-engineer

Same gap — no build+test between reviewer and test-engineer.

### A5: Cross-References

- `core/fixer-reviewer-loop.md` runs Build command at step 4 but does NOT run Test command
- No tests in `tests/` specifically validate the scaffold Step 3 validation depth
- `core/block-handler.md` does not need changes — the new smoke check can use the existing Block handler pattern

### A6: State Management

- No new state.json fields needed — the smoke check is a gate, not a tracked phase
- If it fails, the existing block handler writes the block object
- The smoke check sits between `fixer_reviewer.status = "completed"` and `test.status` update

## Synthesis

All three changes are well-understood and can be implemented without side effects:
1. **Scaffold Step 3:** Expand the one-line validation summary into explicit build+test command execution with retry loop, reading commands from generated CLAUDE.md
2. **Scaffolder scorecard:** Change step 4b header from "informational — does NOT block" to gate conditions for Build and Tests items
3. **Smoke check:** Insert a new step (7a for fix-ticket, 6a for fix-bugs — or renumber to fit) that runs build+test commands between reviewer and test-engineer

## Success Criteria

- Research is complete and sufficient for specification
- No hidden dependencies found that would block implementation
- All insertion points identified with exact step numbers

## Codebase Context

Same as Phase 1.
