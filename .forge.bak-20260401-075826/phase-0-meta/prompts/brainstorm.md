# Phase 3: Brainstorm

## Personas

### Persona A: The Conservative Test Architect
{{PERSONA_A}}: You are a **Conservative Test Architect** who prioritizes stability, maintainability, and low false-positive rates. You favor incremental expansion of the existing test suite using proven patterns. You are skeptical of complex test frameworks and prefer simple, readable bash assertions. Your guiding principle: "A test that breaks on unrelated changes is worse than no test."

### Persona B: The Innovative Coverage Engineer
{{PERSONA_B}}: You are an **Innovative Coverage Engineer** who pushes for maximum contract coverage through creative structural analysis techniques. You propose novel approaches like automated cross-reference graph validation, property-based structural testing, and self-documenting test matrices. Your guiding principle: "Every undocumented invariant is a bug waiting to happen."

### Persona C: The Skeptical QA Strategist
{{PERSONA_C}}: You are a **Skeptical QA Strategist** who challenges assumptions about what can actually be validated structurally. You focus on test economics — cost of writing/maintaining each test vs. probability of catching a real bug. You actively identify tests that provide false confidence. Your guiding principle: "Test what can break, not what looks neat on a coverage report."

## Task Instructions
{{TASK_INSTRUCTIONS}}:

Using the research findings from Phase 2, each persona independently designs a comprehensive E2E test harness strategy. Then a structured debate identifies the strongest approach.

**Each persona must address:**

1. **Test taxonomy:** How to organize new scenarios — by pipeline? by contract type? by risk? What naming convention?

2. **Scenario granularity:** Should each scenario test one property (like existing tests) or should E2E scenarios validate entire pipeline flows end-to-end?

3. **Pipeline step ordering:** How to validate that steps appear in correct order across all 3 pipelines.

4. **Agent dispatch validation:** How to verify agent names, models, and context patterns are consistent across dispatch sites.

5. **State.json write completeness:** How to verify every pipeline phase updates state correctly.

6. **Cross-reference integrity:** How to validate that references between files (command -> agent, command -> core, etc.) are intact.

7. **Config contract enforcement:** How to verify that config defaults, required sections, and optional sections are consistent across all documents.

8. **Mock project strategy:** Should the mock project be expanded, or should new mock variants be created for edge cases?

9. **Regression guard strategy:** How to make tests resilient to legitimate refactoring while catching actual contract violations.

10. **Feature pipeline and deployment coverage:** Specific approach for the two largest coverage gaps.

**Debate format:** After individual proposals, structured comparison on: coverage breadth, false positive risk, maintenance cost, execution speed, ability to catch real bugs.

## Success Criteria
{{SUCCESS_CRITERIA}}:
- [ ] Three distinct, non-overlapping strategies proposed
- [ ] Each strategy provides specific scenario designs (not just categories)
- [ ] Structured comparison table with at least 5 evaluation dimensions
- [ ] Final recommendation with clear rationale for chosen approach
- [ ] At least 2 specific test designs from each persona that could be implemented directly
- [ ] Mock project strategy defined
- [ ] Regression guard approach specified

## Anti-Patterns
{{ANTI_PATTERNS}}:
1. All three personas converging on the same approach (they should genuinely disagree)
2. Proposing tests that require runtime execution in a pure-markdown plugin
3. Designing tests so tightly coupled to current content that any legitimate refactoring breaks them
4. Creating a complex test framework that is harder to maintain than the plugin itself
5. Ignoring the existing 25 tests and proposing to rewrite them from scratch
6. Proposing hundreds of micro-tests when 15-20 well-designed scenarios would provide better coverage
7. Conflating "more tests" with "better coverage" — quality over quantity

## Codebase Context
{{CODEBASE_CONTEXT}}:
- **Existing test patterns:** Simple bash scripts with `set -e`, `fail()` function, grep/awk-based assertions, exit codes (0=pass, 1=fail, 77=skip)
- **Test runner:** `run-tests.sh` runs all `tests/scenarios/*.sh` — no dependency management, no fixtures, no setup/teardown
- **Current coverage:** 25 scenarios, ~1250 lines total. Heavy scaffold coverage (8 scenarios), light feature/deployment coverage (0-1 scenarios)
- **Mock project:** `tests/mock-project/CLAUDE.md` with 11 config sections. Has `app.py` and `tests/` directory for build/test simulation
- **Three pipelines:** bug-fix (~20 steps), feature (~15 steps), scaffold (~25 steps including legacy flow)
- **Contract sources:** CLAUDE.md config contract, 11 core/ contracts, state/schema.md, agent frontmatter format
- **Agent count:** 19 agents with specific model assignments (opus/sonnet/haiku) documented in CLAUDE.md table
