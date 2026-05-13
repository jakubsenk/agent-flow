# Phase 1 Research – Agent 2 Findings

## RQ-3: Existing mode-branch patterns in agents

**Answer:** Yes, multiple agents implement mode-aware branching. Three distinct patterns exist:

### Pattern 1: Flag-gated alternative process block (spec-reviewer)
`agents/spec-reviewer.md` has a dedicated `## Verify Mode (--verify)` section (lines 75–127) with its own numbered process that completely replaces the normal process when the flag is present. This is the most structured pattern — a top-level section whose heading announces the mode, followed by a self-contained process list and mode-specific constraints.

### Pattern 2: Context-conditional inline branch (scaffolder)
`agents/scaffolder.md` uses inline `if` clauses inside a single shared process:
- Line 23: `If a spec/README.md file is provided in the context (scaffold v2 mode), read the Tech Stack section from it…`
- Line 24: `If no spec is provided (--no-implement mode or standalone), read the stack selection from the stack-selector agent output.`
- Lines 132–134: `when running in scaffold v2 mode, MUST generate…` repeated in a checklist.
- Line 206 (Constraints): `When running in scaffold v2 mode (spec context provided), MUST generate E2E Test section and Decomposition section in Automation Config`

The mode is inferred from the presence/absence of a context artifact (spec/README.md), not an explicit flag. Branching is scattered at the relevant steps rather than grouped.

### Pattern 3: Named-mode detection with labelled execution paths (rollback-agent)
`agents/rollback-agent.md` lines 37–52 detect a runtime condition (worktree vs CWD) and name the two paths:
- Line 37: `→ Worktree mode`
- Line 38: `→ CWD mode (main working copy)`
- Lines 47–55: Steps are prefixed `In Worktree mode:` / `In CWD mode:` as bold labels inside the same step body.

### Pattern 4: Implicit source-conditional step (acceptance-gate)
`agents/acceptance-gate.md` line 21: `Read the acceptance criteria from context (from triage-analyst for bugs, spec-analyst for features)`. This is a note about input origin, not a true branch — no process steps differ between modes. The agent is mode-aware only in where it reads input from.

**Evidence:**
- `agents/spec-reviewer.md:75–127` — dedicated `## Verify Mode (--verify)` section with full alternate process
- `agents/scaffolder.md:23–24,132–134,206` — inline `if` / `when running in scaffold v2 mode` conditionals
- `agents/rollback-agent.md:37–55` — named Worktree mode / CWD mode with labelled step variants
- `agents/acceptance-gate.md:21` — implicit source hint (not a true process branch)

**Impact on plan:** The spec-reviewer pattern (separate named section `## Verify Mode`) is the strongest precedent for adding a `## Feature Mode` section to an agent like `triage-analyst` or `acceptance-gate`. The scaffolder pattern (inline `if` inside steps) suits lighter divergence where most steps are shared. If the planned change introduces a bug-fix vs feature branching in an existing agent, prefer the spec-reviewer pattern (separate section) when the process diverges significantly, or the scaffolder inline pattern when only 1–2 steps differ. Do NOT invent a new pattern — pick one of these two.

---

## RQ-4: fix-bugs skill NEEDS_DECOMPOSITION handling

**Answer:** `skills/fix-bugs/SKILL.md` has its own NEEDS_DECOMPOSITION handler at line 434. It does NOT delegate to fix-ticket. Both skills have parallel but independently written handlers.

**fix-bugs handler (lines 434–439):**
```
If fixer output contains `## NEEDS_DECOMPOSITION`:
  1. Authoritative revert: git checkout . && git clean -fd
  2. If decompose_mode = DISABLED → Block handler (step X)
  3. If this bug has already been decomposed once → Block handler (step X)
  4. Run architect for decomposition
  5. Continue with subtask execution (step 3c)
```

**fix-ticket handler (lines 447–452) for comparison:**
```
If fixer output contains `## NEEDS_DECOMPOSITION`:
  1. Authoritative revert: git checkout . && git clean -fd
  2. If decompose_mode = DISABLED → Block ("Fixer needs decomposition but --no-decompose was set")
  3. If this ticket has already been decomposed once → Block ("Decomposition limit (1) reached")
  4. Run architect agent for decomposition (same as step 4b with FORCE)
  5. Continue with subtask execution (step 4c)
```

The two handlers are structurally identical (same 5-step flow) but fix-ticket has more explicit Block messages inline, while fix-bugs uses generic `Block handler (step X)` references. Both are self-contained — no cross-skill delegation.

**Evidence:**
- `skills/fix-bugs/SKILL.md:434–439` — NEEDS_DECOMPOSITION handler in fix-bugs
- `skills/fix-ticket/SKILL.md:447–452` — NEEDS_DECOMPOSITION handler in fix-ticket
- `agents/fixer.md:33–45` — fixer's escape hatch that produces the signal

**Impact on plan:** Any change to NEEDS_DECOMPOSITION behavior (e.g., adding a mode-specific variant, changing block messages, or altering the decompose_mode check) must be applied to BOTH `skills/fix-bugs/SKILL.md` AND `skills/fix-ticket/SKILL.md`. They are not DRY — they are maintained in parallel. Missing one will cause inconsistent behavior between the two entry-point skills. There is no shared handler to update; both files must be edited independently.
