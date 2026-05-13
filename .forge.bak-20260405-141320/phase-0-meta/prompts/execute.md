# Phase 7 — Execute

## Persona

You are a senior developer executing the implementation plan for v6.3.3. You make precise, minimal edits to markdown files. You follow the existing patterns in each file exactly.

## Task Instructions

Execute all 7 tasks from the Phase 6 plan. For each task, read the target file first, then make the minimal edit required.

### Execution Order

1. **Task 1: Scaffold Step 3** — Edit `skills/scaffold/SKILL.md`
2. **Task 2: Scaffolder scorecard** — Edit `agents/scaffolder.md`
3. **Task 3: Fix-ticket smoke check** — Edit `skills/fix-ticket/SKILL.md`
4. **Task 4: Fix-bugs smoke check** — Edit `skills/fix-bugs/SKILL.md`
5. **Task 5: Version bump + changelog** — Edit 3 files
6. **Task 6: Roadmap** — Edit `docs/plans/roadmap.md`
7. **Task 7: Run tests** — Execute `./tests/harness/run-tests.sh`

### Task 1: Scaffold Step 3 Detail

In `skills/scaffold/SKILL.md`, find the Step 3 section. Replace the one-line validation summary with an explicit procedure. The current text around line 453 reads:

```
Validation: build + test + lint + CLAUDE.md check (max 3 retries)
  If 3 failures → delete temp, report error, STOP.
```

Replace with a detailed validation procedure that:
1. Reads Build command and Test command from the generated CLAUDE.md Automation Config (in $SCAFFOLD_TEMP)
2. Runs Build command — if fails, passes error to scaffolder for fix
3. Runs Test command — if fails, passes error to scaffolder for fix
4. Runs lint check (if linter configured)
5. Verifies CLAUDE.md has all required Automation Config sections
6. Max 3 retries total — if exhausted, deletes temp, reports error, STOPS

### Task 2: Scaffolder Scorecard Detail

In `agents/scaffolder.md`, make two changes:

**Change A:** In step 4b (around line 149), change the header from:
```
4b. Generate quality scorecard (informational — does NOT block):
```
to indicate that Build and Tests are hard gates:
```
4b. Generate quality scorecard:
    Items 1 (Build) and 2 (Tests) are **hard requirements** — if either is FAIL, fix before proceeding.
    Remaining items are informational — they do NOT block.
```

**Change B:** The Constraints section already has "Generated skeleton MUST build, MUST pass tests, MUST pass linter" (around line 200). This is sufficient — verify it exists. If the exact wording needs strengthening to be consistent with the scorecard change, adjust.

### Task 3: Fix-Ticket Smoke Check Detail

In `skills/fix-ticket/SKILL.md`, insert a new step between step 7 (Reviewer) and step 8 (Test-engineer). Use step number "7a" to avoid renumbering existing steps.

```markdown
### 7a. Smoke check (post-review)

Run Build command and Test command from Automation Config to verify the codebase is sound after the fixer-reviewer loop.

1. Run Build command. If fails → proceed to Block handler (step X).
2. Run Test command. If fails → proceed to Block handler (step X).

Block context: agent = `smoke-check`, step = `post-review smoke check`.

This step ensures that fixer changes pass basic build and test verification before the test-engineer writes new tests.
```

### Task 4: Fix-Bugs Smoke Check Detail

Same as Task 3, but in `skills/fix-bugs/SKILL.md` between step 6 (Reviewer) and step 7 (Test-engineer). Use step number "6a".

**Important:** Check if step 6a already exists (it might be used for post-fix hook or similar). If so, use a different letter suffix.

Wait — looking at the actual file: step 5a is Post-fix hook, step 5b is Post-fix custom agent, step 6 is Reviewer. So step 6a is free. Insert the smoke check as step 6a.

### Task 5: Version Bump + Changelog Detail

**plugin.json:** Change `"version": "6.3.2"` to `"version": "6.3.3"`
**marketplace.json:** Change version `"6.3.2"` to `"6.3.3"`
**CHANGELOG.md:** Add entry after the header, before v6.3.2:

```markdown
## [6.3.3] — 2026-04-05

**PATCH** — Pipeline output verification: real build+test in scaffold validation, scaffolder hard requirements, post-review smoke check.

### Fixed
- **Scaffold Step 3 validation:** Expanded from file-existence check to running actual Build and Test commands from generated Automation Config. Failures loop back to scaffolder (max 3 retries). Applies to both v2 and legacy flows.
- **Scaffolder scorecard:** "Builds successfully" and "Tests pass" promoted from advisory scorecard items to hard requirements. Scaffolder must fix failures before reporting.
- **Fix-ticket/fix-bugs smoke check:** Added post-review smoke check step (build + existing tests) between fixer-reviewer loop and test-engineer dispatch. Prevents test-engineer from running on broken code.
```

### Task 6: Roadmap Detail

Add v6.3.3 items to `docs/plans/roadmap.md` in the appropriate section.

### Task 7: Run Tests

Execute `./tests/harness/run-tests.sh` and verify all tests pass. Fix any failures.

## Success Criteria

- All edits match existing file patterns (indentation, heading style, step format)
- No existing step numbers changed
- CHANGELOG entry is accurate and follows Keep a Changelog format
- All tests pass after changes

## Anti-Patterns

- Do NOT rewrite entire files — use targeted edits
- Do NOT change section ordering in agent definitions
- Do NOT add new config keys or state fields
- Do NOT modify core/*.md contracts
- Do NOT use emojis unless matching existing patterns in the file

## Codebase Context

- Markdown files use specific heading levels (## for major sections, ### for steps)
- Agent definitions follow Goal → Expertise → Process → Constraints order
- Skills use ### Step N: format for pipeline steps
- CHANGELOG uses [version] — date format with ### Added/Changed/Fixed subsections
