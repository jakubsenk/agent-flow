# Phase 6 — Implementation Plan

{{PERSONA}}
You are an implementation planner for the ceos-agents Claude Code plugin. You produce ordered task lists with exact file paths and change descriptions.

{{TASK_INSTRUCTIONS}}

## Implementation Plan: E2E Test Engineer Deployment Guard (v6.2.0)

### Task Dependency Graph

```
T1 (agent) ──┐
T2 (fix-ticket) ──┤
T3 (fix-bugs) ────┤── T6 (changelog) ── T7 (version bump) ── T8 (roadmap)
T4 (implement) ───┤
T5 (scaffold) ────┘
```

T1-T5 are independent (parallel). T6 depends on all content changes. T7 depends on T6. T8 depends on T7.

### Tasks

#### T1: Add deployment pre-flight to e2e-test-engineer agent
**File:** `agents/e2e-test-engineer.md`
**Change:**
1. After existing step 2 (Read E2E test configuration), insert new step 3 "Deployment pre-flight check"
2. Step 3 has 3 sub-conditions:
   - Check if `### Local Deployment` section exists in Automation Config
   - If YES: dispatch deployment-verifier (Task tool, model: sonnet, action: start). On HEALTHY proceed. On UNHEALTHY/PORT_CONFLICT/START_FAILED: Block.
   - If NO: emit warning about missing Local Deployment config. Proceed without blocking.
3. Renumber existing steps 3-8 → 4-9
4. Update the output template step reference (was step 8, now step 9)
5. Preserve all existing constraints (add no new constraints — the deployment check is in Process)

#### T2: Add deployment-verifier dispatch to fix-ticket pipeline
**File:** `skills/fix-ticket/SKILL.md`
**Change:** Before step 8a (E2E test-engineer), add deployment-verifier dispatch:
- Condition: Local Deployment section exists in Automation Config
- Dispatch: `Run ceos-agents:deployment-verifier (Task tool, model: sonnet)` with context including Local Deployment config and action: start
- Verdict handling: HEALTHY → proceed; non-HEALTHY → Block handler
- If Local Deployment absent → skip, proceed to e2e-test-engineer

#### T3: Add deployment-verifier dispatch to fix-bugs pipeline
**File:** `skills/fix-bugs/SKILL.md`
**Change:** Same as T2 but at step 7a. Identical logic, different step numbers.

#### T4: Add deployment-verifier dispatch to implement-feature pipeline
**File:** `skills/implement-feature/SKILL.md`
**Change:** Same as T2 but at step 6f. Identical logic, different step numbers.

#### T5: Add deployment-verifier dispatch to scaffold pipeline
**File:** `skills/scaffold/SKILL.md`
**Change:** Same as T2 but at Step 8 (E2E Tests). Identical logic, different step reference.

#### T6: Add changelog entry
**File:** `CHANGELOG.md`
**Change:** Add v6.2.0 entry at top (below header). Format: MINOR label, Added section with 2 items (agent pre-flight + pipeline deployment guard).

#### T7: Version bump
**Files:** `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`
**Change:** `"version": "6.1.9"` → `"version": "6.2.0"` in both files.

#### T8: Update roadmap
**File:** `docs/plans/roadmap.md`
**Change:**
1. Move "E2E Test Engineer: Deployment Guard" from "PLANNED — Next" to a new "DONE — v6.2.0" section
2. Update "Current version" at top to v6.2.0

### Execution Order
1. Execute T1-T5 (can be parallelized)
2. Execute T6 (changelog)
3. Execute T7 (version bump)
4. Execute T8 (roadmap update)
5. Run test suite: `./tests/harness/run-tests.sh`

{{SUCCESS_CRITERIA}}
- All 9 files modified correctly
- Test suite passes (39 scenarios, 0 failures)
- No broken cross-references
- Version consistently 6.2.0 in plugin.json and marketplace.json

{{ANTI_PATTERNS}}
- Do not modify deployment-verifier.md
- Do not add new test files (existing structural tests cover the changes)
- Do not change the E2E Test config check in e2e-test-engineer (step 2) — that remains separate from deployment pre-flight
- Do not add deployment-verifier as a skippable stage — it runs as part of the e2e-test-engineer step

{{CODEBASE_CONTEXT}}
- Current version: 6.1.9
- Agent format: YAML frontmatter + Goal/Expertise/Process/Constraints
- Skill dispatch format: `Run ceos-agents:{agent} (Task tool, model: {model})`
- Changelog format: Keep a Changelog with PATCH/MINOR/MAJOR labels
- Version locations: `.claude-plugin/plugin.json` line 4, `.claude-plugin/marketplace.json` line 10
