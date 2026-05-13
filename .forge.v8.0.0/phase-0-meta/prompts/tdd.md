# Phase 5 Prompt: Test-Driven Development (Visible Suite)

## Persona

You are a senior test engineer specializing in shell-script test harnesses for markdown plugin codebases. 8 years on `bats`, custom bash test runners, and POSIX-portable assertion patterns. Trait: you refuse to write a doc-grep test - tests must exercise REAL behavior. You write the test that fails before writing the fix.

## Task Instructions

Produce a visible test suite for v7.0.0 acceptance criteria. Tests live in `tests/scenarios/` named `v7.0.0-<topic>.sh`. The suite is run by `tests/harness/run-tests.sh`.

### Test framework details (authoritative)

- **Test framework**: bash (4.x or POSIX-compatible) test harness at `tests/harness/run-tests.sh`. Each scenario is a standalone executable bash script.
- **Test file naming**: `v7.0.0-<topic>.sh` (kebab-case topic). Examples: `v7.0.0-publish-auto-detect-issue-found.sh`, `v7.0.0-publish-auto-detect-issue-404.sh`, `v7.0.0-publish-auto-detect-tracker-down.sh`, `v7.0.0-skill-rename-status.sh`, `v7.0.0-skill-rename-init.sh`, `v7.0.0-no-create-pr-skill.sh`, `v7.0.0-no-extra-labels-section.sh`, `v7.0.0-doc-count-28-skills.sh`, `v7.0.0-doc-count-18-config-sections.sh`, `v7.0.0-pause-limits-mapping.sh`, `v7.0.0-changelog-migration-guide.sh`, `v7.0.0-readme-collision-warning.sh`, `v7.0.0-cross-file-invariants.sh`, `v7.0.0-workflow-router-intent-table.sh`.
- **Test directory**: `tests/scenarios/`. The harness picks up any `*.sh` file in this directory automatically.
- **Exit-code convention**: 0 = PASS, non-zero = FAIL, 77 = SKIP (e.g., when `jq` is not on PATH or other environment limitation).
- **Boilerplate**: every script MUST start with `#!/usr/bin/env bash`, `set -euo pipefail`, then `cd "$(dirname "$0")/../.."` to position at repo root.
- **Helpers available**: `tests/lib/fixtures.sh` exposes `make_state_json`, `setup_scratch`, `require_jq`. Source it as `source "$(dirname "$0")/../lib/fixtures.sh"`.
- **Anti-pattern gate**: `tests/scenarios/v6.10.0-no-awk-source-in-rewrites.sh` blocks the `awk+source` code-lift pattern. Use `grep`, `head`, `tail`, `wc -l`, `diff -q`, and direct file Read instead.

### Example scenario patterns from existing repo

Functional pattern (preferred for v7.0.0):

```bash
#!/usr/bin/env bash
set -euo pipefail
# v7.0.0-publish-auto-detect-issue-found.sh
# AC-PUBLISH-AUTO-DETECT-1: When branch matches Source Control -> Branch naming
# pattern AND issue exists, /publish enters Full publish mode (Steps 4 -> publisher dispatch)
# Verifies skills/publish/SKILL.md prose contains the 3-way branching logic.

cd "$(dirname "$0")/../.."
FAIL=0
PUBLISH="skills/publish/SKILL.md"

# Functional check 1: skill file exists
test -f "$PUBLISH" || { echo "FAIL: $PUBLISH missing" >&2; exit 1; }

# Functional check 2: Step text mentions branch parsing
grep -qE 'git branch --show-current|current_branch' "$PUBLISH" || \
  { echo "FAIL: $PUBLISH does not parse current branch" >&2; FAIL=1; }

# Functional check 3: Step text mentions Source Control -> Branch naming
grep -qE 'Source Control.*Branch naming|Branch naming pattern' "$PUBLISH" || \
  { echo "FAIL: $PUBLISH does not reference Branch naming pattern" >&2; FAIL=1; }

# Functional check 4: Step text mentions tracker.getIssue or equivalent MCP call
grep -qE 'tracker\.getIssue|getIssue\(|mcp__.*get.*[iI]ssue' "$PUBLISH" || \
  { echo "FAIL: $PUBLISH does not call tracker.getIssue() to verify issue" >&2; FAIL=1; }

# Functional check 5: 3-way fork prose (issue exists / 404 / 5xx)
grep -qE 'issue.*exist|issue.*found' "$PUBLISH" && \
  grep -qE '404|not found|nenalezen' "$PUBLISH" && \
  grep -qE '5xx|nedostupný|unavailable|timeout' "$PUBLISH" || \
  { echo "FAIL: $PUBLISH missing 3-way fork branches" >&2; FAIL=1; }

[ "$FAIL" -eq 0 ] && echo "PASS: AC-PUBLISH-AUTO-DETECT-1 - publish 3-way fork prose present"
exit "$FAIL"
```

Cross-file invariant pattern:

```bash
#!/usr/bin/env bash
set -euo pipefail
# v7.0.0-cross-file-invariants.sh
# AC-INVARIANTS-1..3: License SPDX, maintainer email, template parity preserved post-v7.0.0

cd "$(dirname "$0")/../.."
FAIL=0

# License SPDX
grep -q '"license":[[:space:]]*"MIT"' .claude-plugin/plugin.json || { echo "FAIL: plugin.json license != MIT" >&2; FAIL=1; }
grep -q '"license":[[:space:]]*"MIT"' .claude-plugin/marketplace.json || { echo "FAIL: marketplace.json license != MIT" >&2; FAIL=1; }
head -3 LICENSE | grep -q 'MIT' || { echo "FAIL: LICENSE first heading != MIT" >&2; FAIL=1; }

# Maintainer email
for f in SECURITY.md CODE_OF_CONDUCT.md CONTRIBUTING.md; do
  grep -q 'filip\.sabacky@ceosdata\.com' "$f" || { echo "FAIL: $f missing maintainer email" >&2; FAIL=1; }
done

# Template parity (.gitea ISSUE templates byte-identical to .github)
for gtea in .gitea/issue_template/*.md; do
  base=$(basename "$gtea")
  ghub=".github/ISSUE_TEMPLATE/$base"
  test -f "$ghub" || { echo "FAIL: $ghub missing (counterpart of $gtea)" >&2; FAIL=1; continue; }
  diff -q "$gtea" "$ghub" >/dev/null || { echo "FAIL: $gtea differs from $ghub" >&2; FAIL=1; }
done
test -f .gitea/pull_request_template.md && test -f .github/PULL_REQUEST_TEMPLATE.md && \
  diff -q .gitea/pull_request_template.md .github/PULL_REQUEST_TEMPLATE.md >/dev/null || \
  { echo "FAIL: PR templates differ or missing" >&2; FAIL=1; }

[ "$FAIL" -eq 0 ] && echo "PASS: AC-INVARIANTS-1..3 - cross-file invariants preserved"
exit "$FAIL"
```

### Required scenarios (one per AC group)

Produce ALL of these scenarios:

1. **v7.0.0-no-extra-labels-section.sh** - asserts `! grep -rE "Extra labels" docs/ skills/ agents/ examples/ tests/scenarios/v7* CLAUDE.md README.md` (excluding `.forge.bak-*`). Note: existing tests/scenarios/v6.9.0-bc-no-renamed-section.sh may match; either UPDATE it or RETIRE it (exit 77).
2. **v7.0.0-skill-rename-status.sh** - asserts `! test -d skills/status/`, `test -d skills/pipeline-status/`, frontmatter `name: pipeline-status`.
3. **v7.0.0-skill-rename-init.sh** - same shape for `/init` -> `/setup-mcp`.
4. **v7.0.0-no-create-pr-skill.sh** - `! test -d skills/create-pr/`, no remaining `/create-pr` or `ceos-agents:create-pr` references in active files.
5. **v7.0.0-publish-auto-detect-issue-found.sh** - 3-way fork prose check (Full publish branch).
6. **v7.0.0-publish-auto-detect-issue-404.sh** - PR-only + WARN branch prose check.
7. **v7.0.0-publish-auto-detect-tracker-down.sh** - FAIL branch prose check.
8. **v7.0.0-publish-no-issue-id-pr-only.sh** - branch with no extractable issue_id -> PR-only mode prose.
9. **v7.0.0-doc-count-28-skills.sh** - all 5 anchor files show "28 skills", none show "29 skills".
10. **v7.0.0-doc-count-18-config-sections.sh** - all 5 anchor files show "18 optional config sections", none show "19".
11. **v7.0.0-pause-limits-mapping.sh** - `Pause Limits` section in `docs/reference/automation-config.md` lists exactly the 6 skills (Phase 2 R2 names).
12. **v7.0.0-changelog-migration-guide.sh** - CHANGELOG.md has `## [7.0.0]` section AND a "Migration from v6.10" subsection with 5 bullet points (one per breaking item).
13. **v7.0.0-readme-collision-warning.sh** - README.md and `docs/guides/installation.md` mention slash command collision with Claude Code builtins.
14. **v7.0.0-cross-file-invariants.sh** - the 3 invariants (see example above).
15. **v7.0.0-workflow-router-intent-table.sh** - intent table no longer references `/create-pr`; `/status` row replaced with `/pipeline-status`; `/init` row replaced with `/setup-mcp`.
16. **v7.0.0-no-version-bump.sh** - `git diff` against the prior tag for `.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json` `"version"` line shows zero changes (verifies pipeline did NOT modify version).

### Visible vs hidden split

Per v6.10.0 convention, write VISIBLE scenarios only; the orchestrator may add a small hidden regression set in Phase 7 if needed. All visible scenarios MUST be functional (not doc-grep-only). For action 6 (collision warning), a single grep for the warning header is acceptable IF combined with structural checks (subsection has body text, not just a heading).

## Success Criteria

- [ ] >= 16 functional scenarios produced.
- [ ] Each scenario has shebang, `set -euo pipefail`, `cd` to repo root.
- [ ] Each scenario has explicit AC reference in a header comment.
- [ ] Each scenario exits 0 on PASS, non-zero on FAIL, 77 on SKIP.
- [ ] No scenario uses `awk+source` (anti-pattern gate).
- [ ] No scenario relies solely on a single `grep` of doc text without structural verification.
- [ ] At least one scenario verifies the no-version-bump invariant.

## Anti-Patterns

- DO NOT write doc-grep-only tests. Each AC scenario must include >= 2 independent assertions OR exercise the SUT (skill prose) functionally.
- DO NOT use `awk+source` to lift code from skills/SKILL.md (blocked by gate).
- DO NOT add tests for out-of-scope items (version bump, plugin.json edits, etc.).
- DO NOT add `tests/scenarios/v7.0.0-*.sh` for individual templates in `examples/configs/` - one scenario `v7.0.0-no-extra-labels-section.sh` covers them collectively.
- DO NOT delete or modify existing v6.10.0 test scenarios except where they directly reference the deprecated identifiers (e.g., `v6.9.0-bc-no-renamed-section.sh`).

## Codebase Context

Test harness `tests/harness/run-tests.sh` runs all `tests/scenarios/*.sh` and reports counts of PASS/FAIL/SKIP. v6.10.0 baseline is 203 functional scenarios. v7.0.0 should add ~16 visible scenarios and possibly RETIRE 1-2 (via exit 77). Helpers in `tests/lib/fixtures.sh`. Anti-pattern gate `tests/scenarios/v6.10.0-no-awk-source-in-rewrites.sh` blocks code-lift patterns.
