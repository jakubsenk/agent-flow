# Phase 1 Research Questions — Agent 1 Findings

## RQ-1: Scaffold pipeline agent dispatch overlap

### Answer

Yes. The scaffold pipeline dispatches fixer, reviewer, and test-engineer in Step 7 (Feature Implementation Loop). The dispatch IS affected by mode-aware changes: scaffold passes a structurally different context than bug or feature pipelines. A three-mode branch (bug / feature / scaffold) is required if mode-conditional logic is added to any of these three agents.

### Evidence

**Dispatch points in `skills/scaffold/SKILL.md`:**

- `SKILL.md:674` — `**7a. Fixer** (Task tool, model: opus):`
  Context passed: `subtask scope + acceptance criteria + architecture design + Max build retries`

- `SKILL.md:681` — `**7b. Reviewer** (Task tool, model: opus):`
  Context passed: `diff from fixer + acceptance criteria + Max fixer iterations`
  Follows `core/fixer-reviewer-loop.md`

- `SKILL.md:691` — `**7c. Test-engineer** (Task tool, model: sonnet):`
  Context passed: `changed files, acceptance criteria + Max test attempts`

- `SKILL.md:759` — Second fixer dispatch (post-e2e failure repair): `fixer repairs → re-run`

**Context shape differences vs. other pipelines:**

| Field | Bug pipeline (fix-ticket) | Feature pipeline (implement-feature) | Scaffold pipeline (scaffold) |
|-------|--------------------------|--------------------------------------|------------------------------|
| Issue/ticket reference | Yes — issue ID + bug description | Yes — feature issue + spec-analyst output | None — "No issue tracker context" (SKILL.md:708) |
| Scope source | Code-analyst report, reproduction steps | Architect decomposition subtask | Architect decomposition subtask + spec/ folder |
| Extra context | Reproduction steps | `maps_to` AC traceability | Full decomposition plan + completed subtask summary + spec/ reference (SKILL.md:669-671) |
| Hooks | Pre-fix / Post-fix hooks run | Pre-fix / Post-fix hooks run | Hooks explicitly skipped (SKILL.md:662) |
| Block target | Issue tracker comment | Issue tracker comment | stdout only (SKILL.md:912) |
| Rollback context | Issue tracker updates | Issue tracker updates | "No issue tracker context — skip issue tracker updates." (SKILL.md:708) |

**Additional scaffold-specific rule (SKILL.md:913):**
> "Rollback-agent is called for fixer/reviewer/test-engineer blocks; for scaffolder blocks, command handles cleanup (delete temp dir)"

### Impact on plan

If mode-branch paragraphs are added to the fixer, reviewer, or test-engineer agent definitions (e.g., "In scaffold mode, do X; in bug mode, do Y"), they must handle three modes, not two:

1. **bug** — has issue tracker context, hooks, reproduction steps
2. **feature** — has issue tracker context, hooks, `maps_to` traceability
3. **scaffold** — no issue tracker, no hooks, has spec/ folder, block output to stdout

The scaffold pipeline passes mode implicitly through context content (no explicit `mode:` parameter). Any mode-detection logic in agent definitions must infer mode from the presence/absence of issue tracker context and the presence of spec/ references.

Agents do NOT currently receive an explicit mode tag. If the plan introduces one, scaffold's dispatch points (lines 674, 681, 691, 759) must be updated to pass `mode: scaffold`.

---

## RQ-2: Test harness coverage of agent definitions

### Answer

Four test scenarios directly validate agent file structure. None of them validate the *content* of Process steps beyond checking for forbidden write-tool phrases (read-only agents only). Adding mode-branch paragraphs to Process steps will NOT trigger structural validation failures, as long as:
1. The four required frontmatter fields remain present (`name`, `description`, `model`, `style`)
2. The section order `Goal → Expertise → Process → Constraints` is preserved
3. No write-tool phrases (`Write tool`, `Edit tool`, `write to file`, `create file`, `save file`) appear in the Process section of read-only agents (fixer, reviewer, test-engineer are NOT read-only, so this constraint does not apply to them)
4. Agent model values in frontmatter remain unchanged

### Evidence

**Structural validation tests:**

1. **`tests/scenarios/frontmatter-completeness.sh`** (lines 24-28)
   Checks that each of the 19 agents has all four frontmatter fields: `name`, `description`, `model`, `style`.
   Validation: `grep -q "^$field:" "$file"` — pure field presence check, no content inspection.

2. **`tests/scenarios/section-order.sh`** (lines 25-55)
   Checks `## Goal`, `## Expertise`, `## Process`, `## Constraints` all exist and appear in that order (by line number).
   Validation: line-number ordering check only, no content inspection of the sections.

3. **`tests/scenarios/model-assignment.sh`** (lines 12-53)
   Checks that each agent's frontmatter `model:` field matches the expected model (opus/sonnet/haiku).
   fixer and reviewer must remain `opus`; test-engineer must remain `sonnet`.
   Validation: `grep -q "^model: opus$"` — frontmatter only.

4. **`tests/scenarios/read-only-agents.sh`** (lines 29-45)
   Checks the Process section of 9 read-only agents for forbidden phrases.
   Read-only agents: `triage-analyst`, `code-analyst`, `reviewer`, `spec-analyst`, `architect`, `stack-selector`, `priority-engine`, `spec-reviewer`, `acceptance-gate`.
   **Note: `reviewer` IS in this list.** Adding mode-branch content to `reviewer.md`'s Process section must not include any of: `Write tool`, `Edit tool`, `write to file`, `create file`, `save file`.
   `fixer` and `test-engineer` are NOT in the read-only list — their Process sections have no content restrictions.

**Pipeline-level tests that reference fixer/reviewer/test-engineer:**

5. **`tests/scenarios/pipeline-consistency.sh`** (lines 48-67)
   Checks that any skill file calling fixer mentions "build retries", any calling reviewer mentions "fixer iterations", any calling test-engineer mentions "test attempts".
   This validates SKILL.md files, not agent definition files — no impact.

6. **`tests/scenarios/pipeline-agent-dispatch-models.sh`** (lines 34-93)
   Validates that Task tool dispatch model annotations in SKILL.md files match agent frontmatter.
   No impact unless frontmatter model values are changed.

### Impact on plan

- Editing `fixer.md` or `test-engineer.md` Process sections: no test constraints on content, safe to add mode-branch paragraphs freely.
- Editing `reviewer.md` Process section: forbidden phrases (`Write tool`, `Edit tool`, `write to file`, `create file`, `save file`) must be avoided. All other content is unconstrained.
- Section order (`Goal → Expertise → Process → Constraints`) must be preserved in all three agent files.
- Frontmatter fields (`name`, `description`, `model`, `style`) must remain unchanged.
- Run `./tests/harness/run-tests.sh` after edits to confirm all 4 structural scenarios still pass.
