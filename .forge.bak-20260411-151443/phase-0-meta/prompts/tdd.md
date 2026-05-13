# Phase 5 — TDD (Test-Driven Development)

> **Fast-track note:** This phase is skipped. This is a markdown template addition — no runtime code to test. Validation is done by the existing test harness.

## Test Strategy

### Existing Test Coverage
- `tests/scenarios/scaffold-tracker-integration.sh` validates existing template files (e.g., G-32 checks redmine-rails.md for "Done: status:Closed")
- The new template should include `Done: status:Closed` in State transitions to be consistent

### Manual Verification Points
1. File exists at `examples/configs/redmine-oracle-plsql.md`
2. File starts with `# Oracle PL/SQL + Redmine — Automation Config Template`
3. File contains all 5 required sections
4. File contains `Done:` state transition mapping with `status:Closed`
5. `skills/template/SKILL.md` contains `redmine-oracle-plsql` in the template table
6. `./tests/harness/run-tests.sh` passes all scenarios

### No New Tests Required
Adding a template file does not warrant new test scenarios. The existing test harness validates plugin structure and existing templates. If a future test is added for this specific template, it should follow the G-32 pattern in `tests/scenarios/scaffold-tracker-integration.sh`.
