# Phase 4: Formal Acceptance Criteria — v6.8.1 PATCH

Machine-checkable acceptance criteria, one or more per requirement in `requirements.md`. Every criterion expresses a grep assertion, file-existence check, line-count check, test-harness invocation, or exit-code assertion. Phase 8 can evaluate each AC mechanically with no human judgment.

## Meta
- Format: `AC-<REQ-ID>.<N>` with `Verification:` method + `Expected:` outcome
- Methods: grep, file-exists, line-count, harness-scenario, exit-code
- Total criteria: 31 (was 29 in round 1; round-2 revision added AC-ITEM-2.6 for newline-rejection and tightened Item 6 with a positive counter-form check)
- All criteria traceable to REQ IDs in `requirements.md`

---

## Item 1 — Config-Template Autopilot Rows

### AC-ITEM-1.1 (traces R-ITEM-1.1) — All 8 templates contain `### Autopilot`
  Verification: grep
  Command: `for f in examples/configs/github-nextjs.md examples/configs/github-python-fastapi.md examples/configs/github-dotnet.md examples/configs/gitea-spring-boot.md examples/configs/jira-react.md examples/configs/youtrack-python.md examples/configs/redmine-rails.md examples/configs/redmine-oracle-plsql.md; do grep -qE '^### Autopilot' "$f" || exit 1; done`
  Expected: exit 0 (every file matches)

### AC-ITEM-1.2 (traces R-ITEM-1.2) — Canonical 7 keys present in all 8 templates
  Verification: grep (count per file)
  Command: For each of the 8 template files, assert each of these 7 rows is present:
  - `| Max issues per run | 1 |`
  - `| Lock timeout | 120 |`
  - `| Log file | .ceos-agents/autopilot.log |`
  - `| Bug limit | 0 |`
  - `| Feature limit | 0 |`
  - `| On error | skip |`
  - `| Dry run | false |`
  Expected: `grep -cF "| Max issues per run | 1 |" <file>` returns >= 1 for every file; same for the other 6 rows.

### AC-ITEM-1.3 (traces R-ITEM-1.3) — Table format uses `| Key | Value |` header and alignment row
  Verification: grep
  Command: for each of the 8 files, confirm the Autopilot block is preceded by `| Key | Value |` header and `|-----|-------|` alignment row. Use: `awk '/^### Autopilot/{flag=1;next} flag && /^\|-+\|-+\|/{found=1;exit} END{exit !found}' <file>`
  Expected: exit 0 for every file (alignment row found within the Autopilot section).

### AC-ITEM-1.4 (traces R-ITEM-1.4) — Opt-in commenting preserved
  Verification: grep (presence of divider or active section)
  Command:
  - For the 7 commented-style templates: `grep -qE '^> \*\*Uncomment and customize optional sections as needed.\*\*$' <file>` AND `grep -qE '^<!--$' <file>` AND `grep -qE '^-->$' <file>` all return 0
  - For `redmine-oracle-plsql.md`: either (active section) the literal `^### Autopilot$` appears before the `> **Uncomment...` divider OR (comment block) it appears inside the `<!-- ... -->` comment block.
  Expected: exit 0 for every applicable file.

---

## Item 2 — issue_id Regex Gate

### AC-ITEM-2.1 (traces R-ITEM-2.1) — Regex literal present in all 4 skills
  Verification: grep
  Command: `for f in skills/fix-ticket/SKILL.md skills/fix-bugs/SKILL.md skills/implement-feature/SKILL.md skills/resume-ticket/SKILL.md; do grep -qF '^[A-Za-z0-9#_-]+$' "$f" || exit 1; done`
  Expected: exit 0

### AC-ITEM-2.2 (traces R-ITEM-2.2) — Gate positioned BEFORE first `.ceos-agents/{ISSUE-ID}/` reference in each skill
  Verification: awk (line-number comparison)
  Command: For each of the 4 skill files, compute `gate_line = $(grep -nE 'issue_id validation|\\^\\[A-Za-z0-9#_-\\]\\+\\$' <file> | head -1 | cut -d: -f1)` and `path_line = $(grep -nF '.ceos-agents/{ISSUE-ID}/' <file> | head -1 | cut -d: -f1)`. Assert `gate_line < path_line`.
  Expected: gate_line < path_line for every file. This AC is the operative mechanical check for gate placement across all 4 skills; it is satisfied whether the gate sits at outer Step 0 (single-issue skills) or inside the per-issue loop body (fix-bugs), as long as it textually precedes the first path reference.

### AC-ITEM-2.3 (traces R-ITEM-2.3) — Valid-path branch documented
  Verification: grep
  Command: for each of the 4 skill files, `grep -qiE 'valid examples?|PROJ-42|#123|AUTH-1' <file>` returns 0.
  Expected: exit 0 for every file.

### AC-ITEM-2.4 (traces R-ITEM-2.4) — Reject branch documented (NEGATIVE) and bash `[[ =~ ]]` form used
  Verification: grep
  Command: for each of the 4 skill files,
  - `grep -qE '\[BLOCK\] Invalid issue_id' <file>` returns 0 (error message matches F-2 mandated text)
  - `grep -qE 'exit 1' <file>` returns 0 within the gate block
  - `grep -qE '\[\[ ! "\$\{ISSUE_ID\}" =~ \^\[A-Za-z0-9#_-\]\+\$ \]\]' <file>` returns 0 (bash built-in regex form, NOT `echo … | grep -qE`)
  - NEGATIVE: `grep -qE 'echo "\$\{ISSUE_ID\}" \| grep -qE' <file>` returns non-zero (bypassable form MUST be absent)
  Expected: exit 0 for every file; all four sub-checks must pass.

### AC-ITEM-2.5 (traces R-ITEM-2.5) — Negative character-set constraint not widened (NEGATIVE)
  Verification: grep-literal
  Command: across all 4 skills, `grep -oE "\^\[[^\]]+\]\+\\\$" <file>` — the captured regex literal must be exactly `^[A-Za-z0-9#_-]+$`. Forbidden substrings inside the character class: `\.` (literal dot), `/`, `\\` (literal backslash), space.
  Expected: the only regex literal in each file is `^[A-Za-z0-9#_-]+$`. No other allowlist regex MAY be defined under the gate heading.

### AC-ITEM-2.6 (traces R-ITEM-2.6) — Multi-line ISSUE_ID rejected (NEGATIVE — security-sensitive)
  Verification: shell-invocation (behavioral)
  Command: Construct a minimal standalone test harness that sources the gate snippet from each of the 4 skill files. For each skill, extract the gate bash block (between the fenced code markers below the "issue_id validation" heading) into a temp script, then run it with `ISSUE_ID=$'good\nbad'` in the environment. Assert exit code is non-zero. Example shell test:
  ```bash
  ISSUE_ID=$'../../etc/passwd\nPROJ-42' bash -c '
    if [[ ! "${ISSUE_ID}" =~ ^[A-Za-z0-9#_-]+$ ]]; then exit 1; fi
    echo "BYPASSED"
    exit 0
  '
  rc=$?
  test "$rc" -eq 1
  ```
  Expected: exit 0 (the gate correctly rejects multi-line ISSUE_ID). The bash `[[ =~ ]]` form anchors to the entire string and MUST NOT allow any payload containing `\n` or `\r` to pass.

---

## Item 3 — JSON-Encode Payload Interpolation Docs

### AC-ITEM-3.1 (traces R-ITEM-3.1) — `core/post-publish-hook.md` Section 4 field-safety note
  Verification: grep
  Command: `grep -qE 'Field value safety' core/post-publish-hook.md && grep -qE 'JSON-encode field values|JSON structural|safe for direct JSON' core/post-publish-hook.md && grep -qE 'issue_id regex gate|\[A-Za-z0-9#_-\]' core/post-publish-hook.md`
  Expected: exit 0 (all three patterns found)

### AC-ITEM-3.2 (traces R-ITEM-3.2) — `core/block-handler.md` Step 5 uses heredoc with `--proto` and `jq -n --arg`
  Verification: grep
  Command: `grep -qE -- '--data-binary @-' core/block-handler.md && grep -qE -- '--proto "=http,https"' core/block-handler.md && grep -qE '<<EOF' core/block-handler.md && grep -qE 'jq -n' core/block-handler.md && grep -qE -- '--arg' core/block-handler.md`
  Expected: exit 0 (all five patterns found). The POSIX-unsafe `${var:1:-1}` Bash 4.2+ substring construct MUST NOT appear; additional negative check: `! grep -qE '\$\{[A-Za-z_][A-Za-z0-9_]*:[0-9]+:-[0-9]+\}' core/block-handler.md`.

### AC-ITEM-3.3 (traces R-ITEM-3.3) — `docs/guides/autopilot.md` payload-safety note
  Verification: grep
  Command: `grep -qE 'Payload field safety' docs/guides/autopilot.md && grep -qE 'jq -n --arg' docs/guides/autopilot.md && grep -qE 'percent-encoded' docs/guides/autopilot.md`
  Expected: exit 0

### AC-ITEM-3.4 (traces R-ITEM-3.4) — No inline `-d` curl substitution remains (NEGATIVE)
  Verification: grep (must NOT match)
  Command: `for f in core/post-publish-hook.md core/block-handler.md docs/guides/autopilot.md; do grep -qE "curl[^\\n]+ -d '\{" "$f" && exit 1; done; exit 0`
  Expected: exit 0 (no file contains the forbidden `-d '{...}'` pattern after rewrite)

---

## Item 4 — Lock-Timeout Text Alignment

### AC-ITEM-4.1a (traces R-ITEM-4.1) — Corrected phrasing present at line 368
  Verification: grep
  Command: `grep -qE 'effective stale threshold' skills/autopilot/SKILL.md && grep -qE '125 min.*primary path|primary path.*125' skills/autopilot/SKILL.md && grep -qE '121 min.*BusyBox|BusyBox.*121' skills/autopilot/SKILL.md`
  Expected: exit 0

### AC-ITEM-4.1b (traces R-ITEM-4.1) — Original incorrect phrasing removed (NEGATIVE)
  Verification: grep (must NOT match)
  Command: `grep -qF '<120min old' skills/autopilot/SKILL.md && exit 1 || exit 0`
  Expected: exit 0 (phrase absent)

---

## Item 5 — Fixer-Reviewer Crash-Recovery Regression Test

### AC-ITEM-5.1a (traces R-ITEM-5.1) — Cumulative tokens_used prose in loop contract
  Verification: grep
  Command: `grep -qE 'tokens_used \+= iteration_tokens_used|tokens_used.*\+=.*iteration' core/fixer-reviewer-loop.md && grep -qE 'duration_ms \+= iteration_duration_ms|duration_ms.*\+=.*iteration' core/fixer-reviewer-loop.md && grep -qE 'tool_uses \+= iteration_tool_uses|tool_uses.*\+=.*iteration' core/fixer-reviewer-loop.md`
  Expected: exit 0 (all three accumulation expressions present)

### AC-ITEM-5.1b (traces R-ITEM-5.1) — Crash-recovery semantics sentence present
  Verification: grep
  Command: `grep -qiE 'crash.*mid-loop|crashes mid-loop|preserves.*completed-iteration' core/fixer-reviewer-loop.md`
  Expected: exit 0

### AC-ITEM-5.2 (traces R-ITEM-5.2) — Scenario file exists and is executable
  Verification: file-exists
  Command: `test -f tests/scenarios/v681-fixer-reviewer-crash-recovery.sh && test -x tests/scenarios/v681-fixer-reviewer-crash-recovery.sh`
  Expected: exit 0

### AC-ITEM-5.3 (traces R-ITEM-5.3) — Scenario contains the 4 required assertions
  Verification: grep (scenario source)
  Command: `grep -qE 'tokens_used.*iteration|iteration.*tokens_used' tests/scenarios/v681-fixer-reviewer-crash-recovery.sh && grep -qiE 'crash|partial' tests/scenarios/v681-fixer-reviewer-crash-recovery.sh && grep -qiE 'cumulative' tests/scenarios/v681-fixer-reviewer-crash-recovery.sh && grep -qE 'running total|cumulatively across iterations' tests/scenarios/v681-fixer-reviewer-crash-recovery.sh`
  Expected: exit 0

### AC-ITEM-5.4 (traces R-ITEM-5.4) — Scenario passes under harness
  Verification: harness-scenario
  Command: `bash tests/harness/run-tests.sh v681-fixer-reviewer-crash-recovery`
  Expected: exit 0; stdout contains `PASS:` line naming the scenario.

---

## Item 6 — Test Harness Exit-Code Propagation

### AC-ITEM-6.1a (traces R-ITEM-6.1) — Safe counter form present
  Verification: grep
  Command: `grep -qE 'PASS=\$\(\(PASS \+ 1\)\)' tests/harness/run-tests.sh && grep -qE 'SKIP=\$\(\(SKIP \+ 1\)\)' tests/harness/run-tests.sh && grep -qE 'FAIL=\$\(\(FAIL \+ 1\)\)' tests/harness/run-tests.sh`
  Expected: exit 0

### AC-ITEM-6.1b (traces R-ITEM-6.1) — Unsafe counter form absent (NEGATIVE)
  Verification: grep (must NOT match)
  Command: `grep -qE '\(\(PASS\+\+\)\)' tests/harness/run-tests.sh && exit 1; grep -qE '\(\(SKIP\+\+\)\)' tests/harness/run-tests.sh && exit 1; grep -qE '\(\(FAIL\+\+\)\)' tests/harness/run-tests.sh && exit 1; exit 0`
  Expected: exit 0 (none of the three unsafe forms present)

### AC-ITEM-6.2 (traces R-ITEM-6.2) — Aggregate-run exits non-zero when a scenario fails
  Verification: exit-code
  Command:
  ```bash
  TMP="tests/scenarios/v681-tmp-fail-$$.sh"
  printf '#!/usr/bin/env bash\nexit 1\n' > "$TMP"
  chmod +x "$TMP"
  bash tests/harness/run-tests.sh >/dev/null 2>&1
  rc=$?
  rm -f "$TMP"
  test "$rc" -ne 0
  ```
  Expected: exit 0 (harness reported non-zero, test assertion passes)

### AC-ITEM-6.3 (traces R-ITEM-6.3) — Aggregate-run exits 0 when all pass
  Verification: exit-code
  Command: With no failing scenarios present, `bash tests/harness/run-tests.sh; echo $?`
  Expected: value `0`

### AC-ITEM-6.4a (traces R-ITEM-6.4) — Meta-test file exists
  Verification: file-exists
  Command: `test -f tests/scenarios/v681-harness-exit-propagation.sh && test -x tests/scenarios/v681-harness-exit-propagation.sh`
  Expected: exit 0

  **CAUTION — naming:** The canonical filename is `v681-harness-exit-propagation.sh` (PATCH-prefix precedent: `v644-diagnostics-hardening.sh`). Phase-2 research proposed `ac-v681-harness-exit-propagation.sh` — that name was explicitly REJECTED in Phase 4 (the `ac-` prefix is reserved for minor-version AC tests). Implementers MUST NOT create `tests/scenarios/ac-v681-harness-exit-propagation.sh`; doing so will fail this AC. A grep-negative companion check: `test ! -f tests/scenarios/ac-v681-harness-exit-propagation.sh`.

### AC-ITEM-6.4b (traces R-ITEM-6.4) — Meta-test passes under harness
  Verification: harness-scenario
  Command: `bash tests/harness/run-tests.sh v681-harness-exit-propagation`
  Expected: exit 0; stdout contains `PASS:` line.

---

## Release Process

### AC-RELEASE-1a (traces R-RELEASE-1) — CHANGELOG heading present
  Verification: grep
  Command: `grep -qE '^## \[6\.8\.1\] — 2026-04-18' CHANGELOG.md`
  Expected: exit 0

### AC-RELEASE-1b (traces R-RELEASE-1) — `### Fixed` lists all six items AND `### Internal` lists the two new test scenarios
  Verification: grep
  Command 1 — `### Fixed` references each of the 6 items: `for p in 'examples/configs/' 'skills/autopilot/SKILL.md' 'skills/fix-ticket/SKILL.md' 'core/post-publish-hook.md' 'core/fixer-reviewer-loop.md' 'tests/harness/run-tests.sh'; do grep -qF "$p" CHANGELOG.md || exit 1; done`
  Command 2 — `### Internal` subsection exists within the v6.8.1 block AND lists both new scenarios:
  ```bash
  awk '/^## \[6\.8\.1\]/{flag=1} /^## \[6\.8\.0\]/{flag=0} flag' CHANGELOG.md > /tmp/v681_block.$$
  grep -qE '^### Internal$' /tmp/v681_block.$$ || { rm -f /tmp/v681_block.$$; exit 1; }
  grep -qF 'v681-fixer-reviewer-crash-recovery.sh' /tmp/v681_block.$$ || { rm -f /tmp/v681_block.$$; exit 1; }
  grep -qF 'v681-harness-exit-propagation.sh' /tmp/v681_block.$$ || { rm -f /tmp/v681_block.$$; exit 1; }
  # NEGATIVE: no ### Added subsection within v681 block (the two scenarios must be under ### Internal)
  grep -qE '^### Added$' /tmp/v681_block.$$ && { rm -f /tmp/v681_block.$$; exit 1; }
  rm -f /tmp/v681_block.$$
  exit 0
  ```
  Expected: both commands exit 0. The v6.8.1 block MUST contain `### Fixed` (enumerating 6 items) AND `### Internal` (listing 2 test scenarios). `### Added` MUST NOT appear inside the v6.8.1 block — `### Internal` is the canonical subsection for test-infrastructure artifacts per the v6.8.0 precedent at `CHANGELOG.md:44-46`.

### AC-RELEASE-1c (traces R-RELEASE-1) — Corrected path used (NEGATIVE on old path in v6.8.1 entry)
  Verification: awk (scoped to v6.8.1 section)
  Command:
  ```bash
  awk '/^## \[6\.8\.1\]/{flag=1} /^## \[6\.8\.0\]/{flag=0} flag' CHANGELOG.md > /tmp/v681_block.$$
  # POSITIVE: v6.8.1 block references the corrected path examples/configs/
  grep -qF 'examples/configs/' /tmp/v681_block.$$ || { rm -f /tmp/v681_block.$$; exit 1; }
  # NEGATIVE: v6.8.1 block does NOT reference the erroneous path examples/config-templates/
  grep -qF 'examples/config-templates/' /tmp/v681_block.$$ && { rm -f /tmp/v681_block.$$; exit 1; }
  rm -f /tmp/v681_block.$$
  exit 0
  ```
  Expected: exit 0 (the v6.8.1 block references `examples/configs/` AND does not use the erroneous `examples/config-templates/*` path).

### AC-RELEASE-2a (traces R-RELEASE-2) — plugin.json bumped to 6.8.1
  Verification: grep
  Command: `grep -qE '"version"\s*:\s*"6\.8\.1"' .claude-plugin/plugin.json`
  Expected: exit 0

### AC-RELEASE-2b (traces R-RELEASE-2) — marketplace.json bumped to 6.8.1
  Verification: grep
  Command: `grep -qE '"version"\s*:\s*"6\.8\.1"' .claude-plugin/marketplace.json`
  Expected: exit 0

### AC-RELEASE-2c (traces R-RELEASE-2) — Git tag v6.8.1 created
  Verification: exit-code
  Command: `git tag --list 'v6.8.1' | grep -qx 'v6.8.1'`
  Expected: exit 0

### AC-RELEASE-2d (traces R-RELEASE-2) — Commit sequence: content commit precedes version-bump commit
  Verification: git-log
  Command: `git log --format='%s' -n 3 | head -n 2` — the top commit subject must match `^chore: bump version 6\.8\.0 → 6\.8\.1$` and the second-most-recent commit must be the content commit whose subject references CHANGELOG or v6.8.1 content.
  Expected: the version-bump commit is NEWER than the content commit; both are reachable from the v6.8.1 tag.

### AC-RELEASE-3 (traces R-RELEASE-3) — Full harness passes before content commit
  Verification: harness-scenario
  Command: `bash tests/harness/run-tests.sh; echo $?`
  Expected: exit 0; summary line reports PASS count of at least baseline (140) plus 2 new scenarios (nominally 142 PASS, 0 FAIL). SKIP count unchanged from baseline.
