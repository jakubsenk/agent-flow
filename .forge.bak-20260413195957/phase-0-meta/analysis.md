# Task Analysis

## Classification
- **Type:** feature (comprehensive audit + implementation)
- **Secondary types:** refactoring, quality improvement
- **Complexity:** HIGH
- **Confidence:** 0.90
- **Domain:** pipeline architecture, agent quality, multi-mode consistency

## Scope Assessment

### Files in scope
- Agents (19): All files in agents/
- Pipeline skills (4): fix-ticket, fix-bugs, implement-feature, scaffold
- Core contracts (11): All files in core/
- State schema (1): state/schema.md
- Tests (55): All scenarios in tests/scenarios/

### What this task IS
1. Deep content audit of every agent definition across all 3 pipeline modes
2. Assessment of agent quality, completeness, and mode-appropriateness
3. Assessment of core contract adequacy for 3 modes
4. Assessment of state schema coverage for 3 modes
5. Implementation of concrete improvements based on audit findings

### What this task is NOT
- Not adding new pipeline modes
- Not changing the plugin config contract
- Not rewriting agents from scratch
- Not modifying the test harness itself

## Risk Assessment
- Breaking change risk: MEDIUM
- Test coverage: Good (55 test scenarios)
- Rollback strategy: Git revert

## Key Research Questions
1. Which agents serve multiple modes?
2. Are there mode-specific behaviors only in skill dispatch context?
3. Do core contracts make single-mode assumptions?
4. Is the state schema overloaded across modes?
