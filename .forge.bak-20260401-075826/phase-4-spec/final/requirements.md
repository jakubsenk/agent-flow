# E2E Pipeline Validation — Requirements

## REQ-1: Cross-Reference Integrity Tests
When an agent file is added/removed/renamed in agents/, the test suite SHALL detect mismatch with CLAUDE.md model table and command dispatch sites.

## REQ-2: Core Contract Completeness
When a core contract file is added/removed in core/, the test suite SHALL detect mismatch with core-include-refs validation and command references.

## REQ-3: Count Synchronization
The test suite SHALL verify that numeric claims in CLAUDE.md (agent count, command count, core count) match actual filesystem counts.

## REQ-4: Feature Pipeline Coverage
The test suite SHALL validate implement-feature.md step ordering, agent dispatch chain, and acceptance gate presence.

## REQ-5: Deployment Pipeline Coverage
The test suite SHALL validate deployment-verifier agent and check-deploy command structural properties.

## REQ-6: Agent Dispatch Model Consistency
The test suite SHALL verify that every agent dispatched via Task tool in commands uses the model matching the agent's frontmatter.

## REQ-7: State Write Completeness
The test suite SHALL verify that each pipeline phase references state.json writes.

## REQ-8: Skip Stage Consistency
The test suite SHALL verify skippable/unskippable stage names are consistent between CLAUDE.md and pipeline commands.

## REQ-9: Config Contract Tests
The test suite SHALL verify required config keys are consumed by commands and config-reader sections match CLAUDE.md.

## REQ-10: Hook Order Validation
The test suite SHALL verify hooks appear in correct order in pipeline commands.

## REQ-11: Bug Fixes
The implementation SHALL fix 5 confirmed bugs:
- a) Add deployment-verifier to 3 existing test arrays
- b) Add mcp-detection.md to core-include-refs.sh
- c) Clarify acceptance gate in CLAUDE.md for feature pipeline
- d) Add root_cause_iterations to config-reader.md
- e) Add ceos-agents: prefix to rollback-agent in implement-feature.md

## REQ-12: Dynamic Discovery
All new tests SHALL derive expected values dynamically from filesystem and CLAUDE.md, never from hardcoded lists.

## REQ-13: Backward Compatibility
All 25 existing tests SHALL continue to pass without modification (except the 3 being fixed per REQ-11a).
