# Testing ceos-agents

Test suite for verifying pipeline logic. Contains a mock MCP server, test runner, and 13 automated scenarios.

## Structure

```
tests/
├── mock-project/          ← Mock project with Automation Config
│   ├── CLAUDE.md          ← Complete Automation Config
│   ├── app.py             ← Python code with two intentional bugs
│   └── tests/test_app.py  ← Tests for mock code
├── scenarios/             ← 13 test scenarios (bash scripts)
│   ├── happy-path.sh      ← Full pipeline end-to-end
│   ├── triage-block.sh    ← Triage-analyst detects duplicate → Block
│   ├── fixer-retry.sh     ← Fixer exhausts retry limit → Block + rollback
│   ├── reviewer-reject.sh ← Reviewer rejects fix → fixer iterates
│   ├── test-fail.sh       ← Test-engineer fails → Block after limit
│   ├── publish-success.sh ← Publisher creates PR and updates tracker
│   ├── profile-skip.sh    ← Pipeline Profiles — skip stages
│   ├── verify-fail.sh     ← Fix Verification fails → issue re-opened
│   ├── scaffold-v2-happy-path.sh    ← Scaffold v2 full pipeline
│   ├── scaffold-v2-no-implement.sh  ← --no-implement backwards compat
│   ├── scaffold-v2-spec-loop.sh     ← Spec-writer/reviewer loop
│   ├── scaffold-v2-input-conflicts.sh ← Flag validation
│   └── pipeline-consistency.sh        ← Cross-command consistency checks
├── harness/               ← Test infrastructure
│   ├── fixtures/          ← Mock data (issues.json, automation-config.md)
│   ├── mock-mcp-server.sh ← Mock MCP server
│   └── run-tests.sh       ← Test runner
└── README.md              ← This file
```

## Mock project

`tests/mock-project/` contains:
- `CLAUDE.md` — complete Automation Config with all sections
- `app.py` — Python code with two intentional bugs
- `tests/test_app.py` — tests that fail on buggy code and pass after fix

## Test scenarios

| Scenario | File | Verifies |
|----------|------|----------|
| Happy path | `happy-path.sh` | Full pipeline: triage → code-analyst → fixer → reviewer → test-engineer → publisher |
| Triage block | `triage-block.sh` | Triage-analyst detects duplicate → Block |
| Fixer retry | `fixer-retry.sh` | Fixer exhausts retry limit → Block + rollback |
| Reviewer reject | `reviewer-reject.sh` | Reviewer rejects fix → fixer iterates |
| Test fail | `test-fail.sh` | Test-engineer fails → Block after limit |
| Publish success | `publish-success.sh` | Publisher creates PR and updates tracker |
| Profile skip | `profile-skip.sh` | Pipeline Profiles — skip stages |
| Verify fail | `verify-fail.sh` | Fix Verification fails → issue re-opened |
| Scaffold v2 happy path | `scaffold-v2-happy-path.sh` | Scaffold v2 full pipeline: spec → skeleton → features → report |
| Scaffold v2 no-implement | `scaffold-v2-no-implement.sh` | --no-implement produces v3.x behavior |
| Scaffold v2 spec loop | `scaffold-v2-spec-loop.sh` | spec-writer/spec-reviewer iteration loop mechanics |
| Scaffold v2 input conflicts | `scaffold-v2-input-conflicts.sh` | Mutually exclusive flag validation |
| Pipeline consistency | `pipeline-consistency.sh` | Cross-command pattern consistency (block format, git add, retries, safety) |

## Running

```bash
# All scenarios
./tests/harness/run-tests.sh

# Single scenario
./tests/harness/run-tests.sh happy-path
```

## Important

- Tests use a mock MCP server — no real instances required
- Mock MCP returns pre-prepared responses for each scenario
- CI: Gitea Actions workflow runs tests on push
