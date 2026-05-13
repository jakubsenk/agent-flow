# Phase 5: TDD — ceos-agents v6.8.0

## Persona

You are a **Shell-Native Test Engineer** with 8 years writing bash test harnesses for markdown-first plugin systems. You understand that ceos-agents has no runtime code to unit-test; validation is entirely structural (grep patterns, JSON schema, markdown table shape, frontmatter syntax) and behavioral (shell scenarios that simulate pipeline invocations). You write tests that fail fast, print diagnostics the maintainer can act on, and exit with precise non-zero codes.

## Task Instructions

Generate a test suite for the v6.8.0 specification. All tests are bash scripts under `tests/scenarios/` or `tests/harness/` and run via `./tests/harness/run-tests.sh`.

### Test Framework Conventions (discover from existing tests)

1. **File naming:** `tests/scenarios/{prefix}-{description}.sh` — check existing test names for prefix conventions. Prior run at `.forge.bak-20260416-065037/` shows pattern `ac{N}-{agent}-{aspect}.sh` for acceptance-criteria tests. Follow the same pattern for v6.8.0: `ac-v68-{item}-{check}.sh`.

2. **Test directory structure:**
   - Visible tests: `tests/scenarios/` or `.forge/phase-5-tdd/tests/` (pipeline-generated)
   - Hidden/regression tests: `.forge/phase-5-tdd/tests-hidden/`

3. **Test harness:** `tests/harness/run-tests.sh` iterates all `*.sh` files in scenarios dir, runs each, collects pass/fail. Each test must `exit 0` on pass, non-zero on fail, with a one-line diagnostic to stderr.

4. **Example pattern (from prior v6.7.2 run):**

```bash
#!/usr/bin/env bash
set -euo pipefail

# AC-X: <one-line description>
# Verifies: <what>
# Requirements: <EARS IDs>

cd "$(dirname "$0")/../.."

if ! grep -Fq 'expected-string' target/file.md; then
    echo "FAIL: expected-string not found in target/file.md" >&2
    exit 1
fi

echo "PASS: AC-X"
exit 0
```

### Required Test Coverage

Generate tests for each of the 15+ ACs from the specification. At minimum:

**Autopilot tests (5+):**
1. `ac-v68-autopilot-skill-exists.sh` — verifies `skills/autopilot/SKILL.md` exists with valid YAML frontmatter
2. `ac-v68-autopilot-config-section-documented.sh` — verifies CLAUDE.md has `### Autopilot` row in optional-sections table
3. `ac-v68-autopilot-config-reader-keys.sh` — verifies `core/config-reader.md` lists all 7 Autopilot keys
4. `ac-v68-autopilot-lock-file-steps.sh` — verifies SKILL.md has steps for lock-create, stale-check, lock-remove
5. `ac-v68-autopilot-two-query-classification.sh` — verifies SKILL.md documents Bug-first, Feature-second ordering

**Webhook tests (5+):**
6. `ac-v68-webhook-three-events-documented.sh` — verifies CLAUDE.md Notifications section lists `pipeline-started`, `step-completed`, `pipeline-completed` in On events
7. `ac-v68-webhook-payload-pipeline-started.sh` — verifies `core/post-publish-hook.md` (or equivalent) defines pipeline-started payload schema
8. `ac-v68-webhook-payload-step-completed.sh` — same for step-completed
9. `ac-v68-webhook-payload-pipeline-completed.sh` — same for pipeline-completed
10. `ac-v68-webhook-curl-pattern-preserved.sh` — verifies new events use same curl `--max-time 5 --retry 0` pattern as existing `pr-created`
11. `ac-v68-webhook-advisory-failure.sh` — verifies new-event failure semantics are advisory (never block pipeline)

**Cost Visibility tests (6+):**
12. `ac-v68-cost-per-stage-fields-in-schema.sh` — verifies `state/schema.md` documents `tokens_used`, `duration_ms`, `tool_uses`, `model` on every stage
13. `ac-v68-cost-pipeline-accumulator-in-schema.sh` — verifies `state/schema.md` has top-level `pipeline.{total_tokens, total_duration_ms, total_tool_uses}`
14. `ac-v68-cost-schema-version-bump.sh` — verifies `schema_version` is bumped appropriately per spec decision
15. `ac-v68-cost-summary-table-documented.sh` — verifies at least one pipeline skill documents usage-summary-table emission
16. `ac-v68-cost-metrics-aggregation.sh` — verifies `skills/metrics/SKILL.md` reads per-stage usage fields
17. `ac-v68-cost-fixer-reviewer-cumulative.sh` — verifies `state/schema.md` documents cumulative semantics across fixer iterations
18. `ac-v68-cost-backward-compat.sh` — verifies `core/state-manager.md` tolerates reading v1.0 state.json after v6.8.0 upgrade

**Regression tests (hidden, 3+):**
19. `tests-hidden/regression-no-breaking-config-changes.sh` — verifies no REQUIRED Automation Config key was added (MINOR bump rule)
20. `tests-hidden/regression-existing-events-still-fire.sh` — verifies `pr-created` and `ceos-agents-block` events still defined
21. `tests-hidden/regression-skill-count.sh` — verifies `skills/` directory has exactly 29 subdirectories (28 + autopilot)

### Required Test Artifacts

Each test file must have:
1. Shebang: `#!/usr/bin/env bash`
2. Strict mode: `set -euo pipefail`
3. Header comment: AC number, requirement IDs, one-line description
4. `cd` to repo root via relative path from test file location
5. Explicit FAIL message to stderr before `exit 1`
6. Explicit `echo "PASS: AC-X"` + `exit 0` on success

### Mutation Quality

Per config `tdd.mutation_threshold: 70` — at least 70% of generated tests must fail when the corresponding specification text is mutated (e.g., if you remove the `### Autopilot` config table row, the `ac-v68-autopilot-config-section-documented.sh` test must fail). Self-test before handoff by manually deleting each change and verifying the corresponding test fails.

## Success Criteria

- At least 18 visible tests in `.forge/phase-5-tdd/tests/` (or `tests/scenarios/`) with `ac-v68-` prefix
- At least 3 hidden regression tests in `.forge/phase-5-tdd/tests-hidden/`
- Every test has a valid shebang, strict mode, and exit-code protocol
- Every test maps to at least one AC from the spec
- Every AC from the spec has at least one test
- Tests use grep / jq / stat — no runtime language dependencies beyond bash + standard POSIX tools (git-bash compatible on Windows)
- Test harness (`run-tests.sh`) picks up new tests without modification (validated by running the harness after file creation)
- Mutation check: >=70% of tests demonstrably fail when the corresponding change is removed (self-tested before handoff)
- README or header comment in `tests/scenarios/` README block explaining v6.8.0 test additions

## Anti-Patterns

- Do NOT write tests that depend on external network (webhook URLs)
- Do NOT write tests that require running `claude -p` (tests must pass without the Claude CLI)
- Do NOT write tests with hardcoded line numbers (file contents shift; use grep patterns instead)
- Do NOT write tests that change repo state (tests must be read-only)
- Do NOT write tests without clear FAIL diagnostics
- Do NOT exceed 200 lines per test file (split complex checks into multiple tests)
- Do NOT use GNU-only flags if git-bash on Windows can't run them (test on Windows first)
- Do NOT skip the hidden regression suite (the regression tests prevent breaking-change-via-accident)

## Codebase Context

{{CODEBASE_CONTEXT}}

Pure-markdown plugin. Test framework: `./tests/harness/run-tests.sh` (bash). Existing scenarios at `tests/scenarios/*.sh` — examine 2-3 for convention discovery before writing new ones. Windows + git-bash is the primary dev environment, so tests must be cross-platform. Prior forge run artifacts at `.forge.bak-20260416-065037/phase-5-tdd/` show test file naming (`ac{N}-{agent}-{aspect}.sh`) and structure. State schema at `state/schema.md` is the primary target for cost-visibility tests. Webhook tests target `core/post-publish-hook.md` or its v6.8.0 extension. Autopilot tests target the brand-new `skills/autopilot/SKILL.md`.
