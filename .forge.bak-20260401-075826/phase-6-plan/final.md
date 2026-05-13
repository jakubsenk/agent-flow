# Implementation Plan

## Task Breakdown

### Group A: Bug Fixes (sequential — must run first, tests depend on fixes)

**Task A1: Fix existing test hardcoded lists**
- Files: tests/scenarios/frontmatter-completeness.sh, tests/scenarios/model-assignment.sh, tests/scenarios/section-order.sh
- Action: Add deployment-verifier to agent arrays, update comments from "18" to "19"
- Covers: REQ-11a

**Task A2: Fix core-include-refs.sh**
- Files: tests/scenarios/core-include-refs.sh
- Action: Add mcp-detection to CORE_FILES array (total: 11)
- Covers: REQ-11b

**Task A3: Fix CLAUDE.md acceptance gate description**
- Files: CLAUDE.md
- Action: Change "Acceptance gate (always)" to "Acceptance gate (always in decomposition, skipped in single-pass)" in Feature Pipeline section
- Covers: REQ-11c

**Task A4: Fix config-reader.md**
- Files: core/config-reader.md
- Action: Add retry.root_cause_iterations to Retry Limits output
- Covers: REQ-11d

**Task A5: Fix implement-feature.md rollback prefix**
- Files: commands/implement-feature.md
- Action: Add ceos-agents: prefix to rollback-agent dispatch
- Covers: REQ-11e

### Group B: New Test Scenarios (parallel — independent of each other)

**Task B1: xref-agent-registry.sh** (P1)
- Dynamically list agents/*.md, compare with CLAUDE.md model table
- Bidirectional check: filesystem ↔ documentation
- ~50 lines

**Task B2: xref-core-registry.sh** (P1)
- Dynamically list core/*.md, verify each referenced by at least one command
- Compare count with CLAUDE.md "11 shared pipeline pattern contracts"
- ~45 lines

**Task B3: xref-command-count.sh** (P1)
- Count agents/*.md, commands/*.md, compare with CLAUDE.md claims
- Verify command names listed in CLAUDE.md match actual files
- ~40 lines

**Task B4: pipeline-feature-step-order.sh** (P1)
- Extract step headings from implement-feature.md with line numbers
- Verify monotonic ordering: 0 < 0b < 0c < 1 < 2 < ... < X
- Verify key agents dispatched in correct relative order
- ~60 lines

**Task B5: pipeline-deploy-verifier.sh** (P1)
- Verify deployment-verifier.md has 4 frontmatter fields + model: sonnet
- Verify check-deploy.md dispatches deployment-verifier, references state.json
- Verify port validation, NEVER constraints
- ~55 lines

**Task B6: pipeline-agent-dispatch-models.sh** (P1)
- For each pipeline command, extract (agent, model) from Task tool dispatch lines
- Cross-reference each against agent frontmatter model field
- Report any mismatches
- ~70 lines

**Task B7: pipeline-feature-agents.sh** (P2)
- Verify implement-feature.md dispatches: spec-analyst, architect, fixer, reviewer, test-engineer, publisher, acceptance-gate
- Verify each dispatched agent file exists
- ~45 lines

**Task B8: pipeline-state-writes.sh** (P2)
- Per pipeline command, verify state.json write references for each phase
- ~65 lines

**Task B9: xref-skip-stage-names.sh** (P2)
- Extract skippable stage names from CLAUDE.md
- Compare with stage mapping in pipeline commands
- Verify NEVER-skip stages (fixer, reviewer, publisher)
- ~55 lines

**Task B10: config-required-keys.sh** (P3)
- Extract required keys from CLAUDE.md Config Contract
- Verify at least one command references each key
- ~50 lines

**Task B11: config-reader-sections.sh** (P3)
- Extract optional section names from CLAUDE.md and config-reader.md
- Compute symmetric difference
- ~45 lines

**Task B12: pipeline-hook-order.sh** (P3)
- Verify pre-fix before fixer, post-fix after fixer, pre-publish before publisher
- ~40 lines

## Execution Order

1. **Group A** (sequential): A1 → A2 → A3 → A4 → A5
2. **Group B** (parallel): B1-B12 all independent
3. **Verify**: Run full test suite

## Acceptance Criteria
- All 37 tests pass (25 existing + 12 new)
- No hardcoded agent/core lists in new tests
- Each new test has PASS message on success, specific FAIL message on failure
