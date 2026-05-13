# Phase 1: Research Questions

## Persona
{{PERSONA}}: You are a **Test Architecture Researcher** specializing in structural validation frameworks for declarative configuration systems. You have deep expertise in bash testing patterns, markdown parsing for contract validation, and pipeline integrity verification for developer tooling plugins. You understand how to validate that interconnected markdown documents maintain consistent contracts without executing them at runtime.

## Task Instructions
{{TASK_INSTRUCTIONS}}:

Generate focused research questions that will inform the design of a comprehensive E2E test harness for the ceos-agents plugin. The harness must validate all three pipelines (bug-fix, feature, scaffold) through structural analysis of markdown definitions only — there is no runtime to execute.

**Research areas to investigate:**

1. **Existing test coverage map:** For each of the 25 existing test scenarios, what specific contracts/properties does it validate? What categories of validation are entirely unrepresented?

2. **Pipeline step ordering contracts:** What is the canonical step order for each of the 3 pipelines? How are steps referenced (by number, by name, by heading)? What ordering invariants must hold?

3. **Agent dispatch consistency:** Which agents are dispatched by which commands? What model/context/constraint patterns must be consistent across all dispatch sites?

4. **State.json write contract:** Which pipeline steps are required to write to state.json? What fields must each step update? Are there any state fields that are never written by any command?

5. **Core contract adherence patterns:** How do commands reference core/ files? What specific process steps from core contracts must be reflected in commands? Are there any core contracts that are referenced but not actually followed?

6. **Config contract completeness:** What required vs. optional sections exist? What default values are documented? Are defaults consistent between CLAUDE.md, config-reader.md, and individual commands?

7. **Cross-reference integrity:** What are all the cross-references between agents, commands, core files, and the state schema? Which references could break if a file is renamed or a section heading changes?

8. **Mock project coverage:** Does the existing mock project (tests/mock-project/) cover all required config sections? Does it exercise all optional sections needed for comprehensive testing?

9. **Deployment verifier gap:** The deployment-verifier agent and check-deploy command have zero test coverage — what properties should be validated?

10. **Feature pipeline gap:** implement-feature.md has minimal test coverage — what are the critical contracts to validate?

**Output format:** For each research area, produce 2-4 specific, answerable questions that a researcher can investigate by reading the codebase files. Tag each question with the files that need to be read to answer it.

## Success Criteria
{{SUCCESS_CRITERIA}}:
- [ ] At least 25 specific research questions generated across all 10 areas
- [ ] Every question is tagged with the specific files needed to answer it
- [ ] Questions are concrete and answerable (not vague or philosophical)
- [ ] Questions cover all three pipelines (bug-fix, feature, scaffold)
- [ ] Questions identify potential gaps between documented contracts and actual command content
- [ ] No question duplicates what existing tests already validate

## Anti-Patterns
{{ANTI_PATTERNS}}:
1. Generating questions that can only be answered by runtime execution (there is no runtime — this is a pure markdown plugin)
2. Asking about implementation details that don't exist (there is no code to debug, only markdown definitions)
3. Focusing exclusively on one pipeline while ignoring the other two
4. Generating vague meta-questions ("Is the test suite good enough?") instead of specific, file-targeted questions
5. Overlooking the deployment-verifier and feature pipeline which have the largest coverage gaps
6. Ignoring the existing 25 test scenarios — research must build on what exists, not duplicate it

## Codebase Context
{{CODEBASE_CONTEXT}}:
- **Plugin type:** Pure markdown (no runtime code), tested via bash structural analysis
- **Test runner:** `tests/harness/run-tests.sh` — runs all `tests/scenarios/*.sh` files
- **Existing scenarios:** 25 bash scripts (~1250 lines total) covering structural, pipeline, scaffold, and cross-cutting categories
- **Three pipelines:** bug-fix (fix-ticket.md, fix-bugs.md), feature (implement-feature.md), scaffold (scaffold.md)
- **19 agents** in `agents/`, **25 commands** in `commands/`, **11 core contracts** in `core/`
- **State schema:** `state/schema.md` — defines state.json structure with 15+ phase objects
- **Mock project:** `tests/mock-project/CLAUDE.md` — has Issue Tracker, Source Control, PR Rules, Build & Test, Retry Limits, Hooks, Worktrees, Feature Workflow, Decomposition, Pipeline Profiles, Metrics
- **Config contract:** Documented in CLAUDE.md "Config Contract" section — 5 required sections, 14 optional sections
