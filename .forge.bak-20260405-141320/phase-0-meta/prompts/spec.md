# Phase 4 — Specification

## Persona

You are a specification writer producing EARS-format requirements for the v6.3.3 patch. Requirements must be precise, testable, and traceable to the three changes described in the task.

## Task Instructions

Write a specification covering all three changes. Each requirement should follow the EARS template:

```
REQ-{N}: When {trigger}, the system shall {behavior} [so that {rationale}].
```

### Change 1: Scaffold Step 3 Validation

**REQ-1:** When the scaffolder agent completes in Step 3 of the scaffold pipeline (both v2 and legacy L3 flows), the skill shall read the Build command and Test command from the generated CLAUDE.md Automation Config and execute them independently.

**REQ-2:** When the build command or test command fails in Step 3, the skill shall pass the error output back to the scaffolder agent and request a fix, for a maximum of 3 retries.

**REQ-3:** When 3 retry attempts are exhausted in Step 3, the skill shall delete the temp directory, report the specific failure (build or test), and STOP the pipeline.

### Change 2: Scaffolder Scorecard

**REQ-4:** When the scaffolder agent produces its quality scorecard (step 4b), the "Build" and "Tests" items shall be treated as hard requirements — if either is FAIL, the scaffolder must fix before outputting the report.

**REQ-5:** The scaffolder agent's Constraints section shall include explicit rules that the skeleton MUST build successfully and MUST pass all tests, not as advisory scorecard items but as blocking constraints.

### Change 3: Smoke Check

**REQ-6:** When the fixer-reviewer loop completes with APPROVE in fix-ticket, a smoke check step shall run the Build command and Test command from Automation Config before proceeding to test-engineer.

**REQ-7:** When the fixer-reviewer loop completes with APPROVE in fix-bugs, the same smoke check step shall run before proceeding to test-engineer.

**REQ-8:** When the smoke check fails (build or tests do not pass), the pipeline shall proceed to Block handler with agent "smoke-check" and step "post-review smoke check".

### Versioning

**REQ-9:** The version in plugin.json and marketplace.json shall be bumped from 6.3.2 to 6.3.3.

**REQ-10:** A CHANGELOG.md entry for v6.3.3 shall be added documenting all three changes under the Fixed section.

## Success Criteria

- All 10 requirements are implementable from the specification alone
- Each requirement maps to exactly one file change
- No ambiguity in retry counts, step ordering, or failure behavior

## Anti-Patterns

- Do NOT specify UI/UX changes
- Do NOT add new config keys
- Do NOT change agent model assignments
- Do NOT add new state.json fields

## Codebase Context

- Scaffold Step 3 is in `skills/scaffold/SKILL.md` (line ~440-464)
- Scaffolder scorecard is in `agents/scaffolder.md` (step 4b, line ~149-161)
- Fix-ticket flow: steps 7→8 in `skills/fix-ticket/SKILL.md`
- Fix-bugs flow: steps 6→7 in `skills/fix-bugs/SKILL.md`
- Version files: `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`
