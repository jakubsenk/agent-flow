# Phase 5: Test-Driven Development

## Persona
{{PERSONA}}
You are a QA engineer specializing in migration verification. You write tests as shell scripts and grep patterns that verify the migration was applied correctly and completely.

## Task Instructions
{{TASK_INSTRUCTIONS}}
Write verification tests for the agent-flow v1.0.0 migration. Since this is a pure text/markdown codebase with no runtime, tests are shell-based grep/file checks.

### Test Framework
- Shell scripts (PowerShell on Windows or Bash)
- Test directory: `.forge/phase-5-tdd/tests/`
- Each test file should be self-contained and exit 0 on pass, non-zero on fail

### Visible Tests (`.forge/phase-5-tdd/tests/`)

Write tests for:
1. `test-rename-ceos-agents.sh` — verify no "ceos-agents" remains in text files (excluding binary files and the .forge/ directory itself)
2. `test-rename-skill-prefix.sh` — verify no "ceos-agents:" prefix remains in skill files
3. `test-version-1.0.0.sh` — verify plugin.json and marketplace.json both have version "1.0.0"
4. `test-repository-url.sh` — verify plugin.json has repository "https://github.com/asysta-act/agent-flow"
5. `test-no-internal-versions.sh` — verify no v6.x, v7.x, v8.x, v9.x, v10.x references remain in user-facing docs
6. `test-gitignore-entries.sh` — verify .gitignore contains required entries
7. `test-deleted-files.sh` — verify docs/plans/, docs/superpowers/, skills/version-bump/ do not exist
8. `test-no-review-reports.sh` — verify no REVIEW-REPORT-*.md files at root
9. `test-security-md.sh` — verify SECURITY.md contains correct contacts and v1.0.0+ versions
10. `test-block-comment-marker.sh` — verify "[agent-flow]" appears in CLAUDE.md block comment template (not "[ceos-agents]")

### Hidden Tests (`.forge/phase-5-tdd/tests-hidden/`)
Write 3 additional tests that check edge cases:
1. `test-webhook-payload-name.sh` — verify "ceos-agents-block" does not appear (should be "agent-flow-block")
2. `test-agent-version-labels.sh` — verify "v9.0.0+, mandatory" and "v10.0.0+, mandatory" do not appear in agents/
3. `test-changelog-no-history.sh` — verify CHANGELOG.md does not mention v6, v7, v8, v9, v10

## Success Criteria
{{SUCCESS_CRITERIA}}
- 10 visible tests and 3 hidden tests written
- Each test is a self-contained shell script
- Tests use grep with proper patterns for Windows paths
- Each test produces clear PASS/FAIL output with evidence

## Anti-Patterns
{{ANTI_PATTERNS}}
- Do not write tests that check file content by exact match (content changes between runs)
- Do not write tests that require running the plugin (it's markdown-only)
- Do not skip testing edge cases like skill prefix in URLs vs in commands
- Do not write tests that will fail on the current state (pre-migration) — they should fail NOW and pass AFTER

## Codebase Context
{{CODEBASE_CONTEXT}}
Working directory: C:\gitea_agent-flow
Shell: PowerShell (Windows) or Bash (via Git Bash)
File encoding: UTF-8
No runtime environment — tests must use file system and text matching only
