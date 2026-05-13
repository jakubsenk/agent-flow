# Phase 2 Research Answers — Agent 1

Date: 2026-04-13
Researcher: subagent (claude-sonnet-4-6)

---

## RQ-1: Scaffold Pipeline — Fixer/Reviewer/Test-engineer Dispatch Context

### Exact lines validated

Source file: `skills/scaffold/SKILL.md`

**Line 674 — Fixer dispatch:**
```
**7a. Fixer** (Task tool, model: opus):
    Context: subtask scope + acceptance criteria + architecture design + `Max build retries = {Build retries from CLAUDE.md, default 3}.`
    After completion: run Build command from generated CLAUDE.md
```

**Line 681 — Reviewer dispatch:**
```
**7b. Reviewer** (Task tool, model: opus):
    Context: diff from fixer + acceptance criteria + `Max fixer iterations = {Fixer iterations from CLAUDE.md, default 5}.`
    Follow `core/fixer-reviewer-loop.md`.
```

**Line 691 — Test-engineer dispatch:**
```
**7c. Test-engineer** (Task tool, model: sonnet):
    Context: changed files, acceptance criteria + `Max test attempts = {Test attempts from CLAUDE.md, default 3}.`
    After completion: run Test command from CLAUDE.md
```

### Mode prefix analysis

There is NO `Mode:` prefix in the scaffold context strings. The scaffold contexts pass:
- Fixer: "subtask scope + acceptance criteria + architecture design + Max build retries"
- Reviewer: "diff from fixer + acceptance criteria + Max fixer iterations"
- Test-engineer: "changed files, acceptance criteria + Max test attempts"

Compare with fix-ticket/fix-bugs dispatch (same agents): those pass triage analysis, impact report, bug report.
The scaffold context is structurally different: it substitutes "subtask scope" for "triage analysis" and includes "architecture design" instead of "impact report". No Mode: discriminator is currently injected.

### Can a two-way branch (bug vs non-bug) cover both feature and scaffold?

**No — scaffold is explicitly separate from feature.** Key differences that prevent collapsing scaffold into a "feature" mode:

1. **No issue tracker context in scaffold** — line 708-709 explicitly states rollback-agent gets `"No issue tracker context — skip issue tracker updates."` This is absent in feature pipeline.
2. **Input source differs** — scaffold fixer reads "subtask scope + architecture design + spec/ folder"; feature fixer reads "decomposition plan + spec + CLAUDE.md" from an existing project; bug fixer reads "triage analysis + impact report."
3. **Hooks are explicitly suppressed** — line 662: "Hooks (Pre-fix, Post-fix, Pre-publish, Post-publish) are not executed during scaffold because the project is being created from scratch."
4. **Build command source differs** — scaffold uses "Build command from generated CLAUDE.md" (the project being created), not the consuming project's existing CLAUDE.md.
5. **Commit strategy differs** — line 700-704: scaffold commits per-subtask with `feat({subtask-id}): {subtask-title}` pattern.

**Recommendation:** Three explicit modes are necessary:
- `Mode: bug-fix` — triage analysis + impact report as input
- `Mode: feature` — spec + decomposition plan, issue tracker active
- `Mode: scaffold` — subtask scope + architecture design, no issue tracker, hooks suppressed, generated CLAUDE.md as source

A two-way "bug vs non-bug" branch would force scaffold and feature to share the same conditional path but they differ on 5+ axes. Scaffold must be its own branch.

---

## RQ-2: Test Harness — Exact Constraints

### Test file inventory (52 test scenarios total)

**Structural agent tests:**

1. **`frontmatter-completeness.sh`** (line 24-28)
   - Pattern: `grep -q "^$field:" "$file"` for each of `name`, `description`, `model`, `style`
   - Failure trigger: Any agent missing any of the 4 frontmatter fields
   - Hardcoded agent list of 19 agents

2. **`section-order.sh`** (line 25-55)
   - Pattern: `grep -n "^## Goal"`, `"^## Expertise"`, `"^## Process"`, `"^## Constraints"` — extracts line numbers, asserts Goal < Expertise < Process < Constraints
   - Failure trigger: Any section missing, or sections out of order
   - Checks ALL 19 agents

3. **`model-assignment.sh`** (line 13-53)
   - Pattern: `grep -q "^model: opus$"`, `"^model: sonnet$"`, `"^model: haiku$"`
   - Failure trigger: Any agent with wrong model (exact string match including `$`)
   - **Adding a new agent requires adding it to the correct OPUS/SONNET/HAIKU list in this test or it will silently pass (no "unknown agent" check).**

4. **`read-only-agents.sh`** (line 29-45)
   - Extracts ONLY the `## Process` section (awk between `^## Process` and `^## Constraints`)
   - Pattern: case-insensitive grep for:
     - `"Write tool"`
     - `"Edit tool"`
     - `"write to file"`
     - `"create file"`
     - `"save file"`
   - Failure trigger: ANY of these phrases (case-insensitive) in the Process section of a read-only agent
   - **Read-only agents checked: triage-analyst, code-analyst, reviewer, spec-analyst, architect, stack-selector, priority-engine, spec-reviewer, acceptance-gate (9 agents)**
   - **Critical: reviewer IS in this list.** Any mode-branch section added to reviewer's Process must not contain "Write tool", "Edit tool", "write to file", "create file", or "save file" in any case combination.

**Pipeline dispatch tests:**

5. **`pipeline-feature-agents.sh`** (line 32-38)
   - Pattern: `grep -qiE "$agent.*(Task tool)|Task tool.*$agent"` in implement-feature/SKILL.md
   - Checks: spec-analyst, architect, fixer, reviewer, test-engineer, publisher, acceptance-gate
   - Failure trigger: agent name not found near "Task tool" or "the {agent} agent" pattern

6. **`pipeline-agent-dispatch-models.sh`** (line 42-92)
   - Pattern: parses lines containing `"Task tool, model:"` in fix-ticket, fix-bugs, implement-feature, scaffold, check-deploy SKILL.md files
   - Verifies: dispatched model matches expected model, agent file frontmatter matches
   - **Any new dispatch in scaffold SKILL.md with `Task tool, model:` will be parsed and the agent model verified**

7. **`pipeline-feature-step-order.sh`** (line 56-93)
   - Pattern: searches for `"run the ${agent} agent\|ceos-agents:${agent}\b"` in implement-feature/SKILL.md
   - Verifies: spec-analyst < architect < fixer < reviewer < test-engineer < publisher in line order
   - Failure trigger: wrong order of first dispatch line

8. **`pipeline-consistency.sh`** (line 16-87)
   - Checks ALL pipeline skills referencing rollback-agent or fixer
   - **Specific patterns checked:**
     - `[ceos-agents].*Pipeline Block` must contain `🔴` emoji
     - `git add .` (without `-A`) is NOT allowed in non-git-init contexts
     - Files calling fixer must mention `"build retries"`
     - Files calling reviewer must mention `"fixer iterations"`
     - Files calling test-engineer must mention `"test attempts"`
     - Files referencing rollback-agent must contain `"issue tracker"` instruction
   - **scaffold/SKILL.md currently satisfies all these**: lines 675 (Max build retries), 682 (Max fixer iterations), 692 (Max test attempts), and 708-709 (issue tracker context for rollback-agent)

9. **`scaffold-v2-happy-path.sh`** (line 29-150)
   - Checks scaffold/SKILL.md for: "Mode Selection", "spec-writer", "spec-reviewer", "architect agent", "Feature Implementation Loop", "E2E Tests", "Final Report", "Interactive", "YOLO with checkpoint", "Full YOLO", "Infrastructure Declaration", "0-MCP", "Push to Remote", "Create Tracker Issues"
   - Regression guards: must NOT contain "Step 4b", "Step 4c", "Step 9: Issue Tracker", "Step 10"
   - Line order: Infrastructure Declaration before Mode Selection; Step 9 must be "Final Report"

10. **`scaffolder-e2e-batch.sh`** (line 12-68)
    - Checks `agents/scaffolder.md` for specific Batch 7 and Batch 8 content
    - Pattern: grep for "Batch 7.*E2E", "Skip this batch entirely", "@playwright/test", "pytest-playwright", etc.
    - Does NOT check the fixer/reviewer/test-engineer agents

**Other tests that could be affected by mode-branch additions:**

11. **`xref-command-count.sh`** — checks CLAUDE.md numeric claims (agents=19, skills=26, core=11); adding an agent would fail this unless CLAUDE.md is also updated

12. **`pipeline-state-writes.sh`** — checks scaffold/SKILL.md for "state.json" and "state-manager" references; adding mode-branch steps that write state must maintain these references

13. **`test-step-placement.sh`** — currently checks implement-feature, fix-ticket, fix-bugs for tracker subtask creation steps (FC-1, FC-2, FC-3); does NOT check scaffold

### Do any tests check specific Process step CONTENT?

**Yes, one test does: `read-only-agents.sh`** — it explicitly extracts the `## Process` section and checks for write-tool phrases. This is content-based, not just header presence.

All other tests check:
- Section existence (header presence)
- Line ordering (section A before section B)
- Keyword presence in entire file (not section-scoped)
- Frontmatter field presence

No test currently checks the wording of numbered Process steps in fixer, reviewer, test-engineer, or e2e-test-engineer beyond the write-tool phrase check for read-only agents.

---

## RQ-3: Mode-Branch Patterns — Recommendation

### Pattern 1: spec-reviewer dedicated subsection (lines 75-128)

The `## Verify Mode (--verify)` section in `agents/spec-reviewer.md` is a **full dedicated subsection** within `## Process`. It spans 54 lines (lines 75-128) and contains its own `### Verify Process` with numbered steps 1-5 fully redefined. The standard review process (steps 1-4) is the primary mode; the verify mode is an entirely separate subtree under a `## Verify Mode (--verify)` header.

Key structural observation: the verify mode section sits BEFORE `## Constraints`, so it is technically inside the Process section from a header-hierarchy standpoint, but it uses `##` (not `###`) to clearly separate it. This means it does NOT appear inside the numbered step list — it's a parallel section.

**When to use this pattern:** When the two modes share almost no steps (spec-reviewer review mode and verify mode have completely different inputs, processes, and outputs).

### Pattern 2: scaffolder inline conditionals (lines 22-58, 57-113)

The `agents/scaffolder.md` uses inline conditionals extensively within numbered steps:
- Line 23: `"If a spec/README.md file is provided in the context (scaffold v2 mode), read... otherwise..."`
- Line 57-58: `"**Batch 6 — Design (conditional — web/frontend/fullstack projects only):** Skip this batch entirely if the tech stack does NOT include..."`
- Line 66-78: `"**Batch 7 — E2E Tests (conditional — web projects with Playwright only):** Skip this batch entirely if: [condition list]"`

**When to use this pattern:** When steps are shared but one condition skips or modifies individual steps. The skip is communicated as "Skip this batch entirely if..." inline in the step itself.

### Pattern 3: rollback-agent named paths (observed in scaffold SKILL.md line 708)

Scaffold already passes a custom named context to rollback-agent: `"No issue tracker context — skip issue tracker updates."` This demonstrates a single-agent, context-string-level differentiation without changing the agent definition itself.

### Pattern 4: acceptance-gate implicit hints (from Phase 1 finding)

Acceptance-gate uses `Mode:` labels in context strings to switch behavior without conditional sections in the agent file. The agent reads the context and adapts.

---

### Analysis: How much do fixer/reviewer/test-engineer/e2e-test-engineer need to change per mode?

**Fixer (`agents/fixer.md`):**

Process steps 1-8 are tightly bug-fix oriented:
- Step 1: "Read the triage analysis and impact report" — bug-specific input
- Step 3: "Analyze before coding: What exactly is wrong and why?" — implies bug context
- Step 5: Red-green-refactor with "Write a test that reproduces the bug" — explicitly bug framing
- Step 8: Fix Report output format (Root cause, Approach) — bug-specific labels

For **feature/scaffold mode**, the fixer:
- Does NOT receive a triage analysis or impact report — receives subtask scope + AC instead
- Step 5 RED phase changes: instead of reproducing a bug, it's implementing a new feature (write failing tests for new behavior)
- Step 8 output changes: "Root cause" becomes meaningless; output should be "Feature implemented" or similar
- ESCAPE HATCH (step 5, lines 33-44) would still apply but "≥4 files or 100-line limit" framing is the same

The changes span **3 of 8 steps** (steps 1, 5, 8) in a meaningful way.

**Reviewer (`agents/reviewer.md`):**

Process steps 1-7:
- Step 1: "Read the original bug report, triage analysis, impact report" — bug-specific
- Step 4 checklist: "Root cause: Does the fix address the actual root cause?" — only meaningful for bugs
- Step 4 AC Fulfillment: Already mode-agnostic (works for both bugs and features)
- Step 7 output: "## Code Review" with AC Fulfillment section — works for all modes

For feature/scaffold mode:
- Step 1 input changes: reads spec/decomposition plan + subtask scope instead of bug report + triage
- Step 4 "Root cause" checklist item becomes "Feature scope: Does the implementation cover the full subtask scope?"
- Everything else (security, performance, regressions, over-engineering, edge cases) is mode-agnostic

Changes needed: **Steps 1 and 4 partially** — approximately 1-3 sentences change.

**CRITICAL CONSTRAINT from read-only-agents.sh:** reviewer IS checked by the read-only test. Any addition to reviewer's Process section MUST NOT contain "Write tool", "Edit tool", "write to file", "create file", or "save file" (case-insensitive). A dedicated mode subsection header like `### Bug-Fix Mode` or inline conditionals both satisfy this — neither would introduce write-tool phrases.

**Test-engineer (`agents/test-engineer.md`):**

Process steps 1-6:
- Step 1: "Read the bug report, fixer output, impact report" — bug-specific input
- Step 3: "One test verifying the specific behavior that was fixed (regression test)" — bug framing
- Steps 2, 4, 5, 6: Mode-agnostic (run tests, write tests following conventions, verify pass)

For feature/scaffold mode:
- Step 1 input changes: reads subtask scope + AC instead of bug report
- Step 3: "Required: One test verifying the AC is fulfilled" instead of regression framing
- Changes minimal: **Steps 1 and 3 only** (1-2 sentences each)

**E2e-test-engineer (`agents/e2e-test-engineer.md`):**

Process steps 1-9:
- Step 1: "Read the bug report and fix diff — understand which user flow was affected" — bug-specific
- Steps 2-9: Almost entirely mode-agnostic (E2E framework check, deployment pre-flight, find existing tests, plan scope, write tests, run)

For feature/scaffold mode:
- Step 1: reads "spec verification strategy" instead of bug report + fix diff
- Only **Step 1** needs to change (1 sentence)

---

### Recommendation: Inline Conditional per step (scaffolder pattern), NOT dedicated subsection

**Rationale:**

1. **Change density is low.** Across all 4 agents, only 1-3 steps per agent need mode-specific wording. The majority of each agent's process (quality checks, conventions, build verification, test execution) is identical across modes.

2. **Dedicated subsection pattern (spec-reviewer) is for radical mode divergence** — spec-reviewer verify mode replaces ALL 4 standard steps with 5 entirely different steps. The fixer/reviewer/test-engineer changes are surgical (different input labels + 1 reworded step each).

3. **Test harness compatibility:** The section-order test checks for `^## Goal`, `^## Expertise`, `^## Process`, `^## Constraints` in order. A dedicated `## {Mode} Mode` subsection inserted between `## Process` and `## Constraints` would use `##` level, causing the test to fail (it would detect `## Constraints` line number correctly, but inserting an additional `##` section is fine since the test only checks that each exists and that Process line < Constraints line). However, using `###` subsections within `## Process` is fully safe.

4. **Read-only constraint for reviewer:** The read-only test extracts text between `^## Process` and `^## Constraints`. Adding a `### Bug-Fix Mode` or `### Feature/Scaffold Mode` subsection within Process is safe as long as no write-tool phrases appear.

5. **Inline conditional syntax** used in scaffolder (`"If no spec is provided... If spec provided..."`) is already the established pattern in this codebase and is readable without adding structural complexity.

**Concrete recommendation:**

Use **inline conditionals at the step level** with this pattern:

```markdown
1. Read the context:
   - **Bug-fix mode** (context includes triage analysis + impact report): read triage analysis, impact report, and bug report.
   - **Feature/scaffold mode** (context includes subtask scope + acceptance criteria): read the subtask scope, acceptance criteria, and architecture design. No triage analysis or impact report will be present.
```

This keeps the agent file as a single Process section, avoids new `##` headers that could confuse the section-order test, and mirrors the established inline conditional style from scaffolder.

**Do NOT use a two-way (bug vs non-bug) branch if scaffold is the caller** — scaffold context omits hooks, uses generated CLAUDE.md, and passes no issue tracker context. These differences must be handled either in the skill's context string (preferred — inject `Mode: scaffold` into the context) or via a three-way inline conditional in the agent.

**Preferred approach:** Inject `Mode: {bug-fix|feature|scaffold}` into the context string at the skill dispatch level (already done for acceptance-gate), and add a single inline conditional block at Step 1 of each affected agent. This is the least-invasive change and requires no structural changes to any agent file.

---

## Summary Table

| Agent | Steps needing change | Change size | Inline vs dedicated | Test risk |
|-------|---------------------|-------------|--------------------|-----------| 
| fixer | Steps 1, 5, 8 | 3-5 sentences | Inline conditional | Low — no structural test on content |
| reviewer | Steps 1, 4 | 2-3 sentences | Inline conditional | MUST avoid write-tool phrases (read-only test) |
| test-engineer | Steps 1, 3 | 1-2 sentences | Inline conditional | Low |
| e2e-test-engineer | Step 1 | 1 sentence | Inline conditional | Low |

**Test files that will execute against changed agents:**
- `frontmatter-completeness.sh` — safe (no frontmatter changes)
- `section-order.sh` — safe (no section header changes)
- `model-assignment.sh` — safe (no model changes)
- `read-only-agents.sh` — **MUST VERIFY** reviewer changes contain no write-tool phrases
- `pipeline-consistency.sh` — safe if "build retries", "fixer iterations", "test attempts" remain in scaffold SKILL.md
- `pipeline-agent-dispatch-models.sh` — safe if model annotations stay the same
