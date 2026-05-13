# Phase 4: Requirements — v6.8.1 PATCH

EARS-format requirements for the six `PLANNED — v6.8.1` roadmap items plus release-process requirements. Every requirement is atomic, testable, and traced to a specific file and roadmap item. No requirement introduces a new Automation Config key (PATCH semver preserved).

## Meta
- Source roadmap entry: `docs/plans/roadmap.md:730` — `## PLANNED — v6.8.1 (Post-v6.8.0 follow-ups)`
- Research evidence: `.forge/phase-2-research-answers/final.md`
- Total requirements: 20 (6 items + 1 release block = 7 groups; Item 2 gained R-ITEM-2.6 in round-2 revision)
- Negative requirements: present for Item 2 (R-ITEM-2.4, R-ITEM-2.5, R-ITEM-2.6) and Item 3 (R-ITEM-3.4)
- All requirements reference existing files and paths; no new infrastructure required

---

## Item 1 — Config-Template Autopilot Rows

Traces to roadmap bullet 1: "`examples/config-templates/*` — add `### Autopilot` section row to each template (CHANGELOG Known Issue)". Note: the actual directory is `examples/configs/` (CHANGELOG.md:42 has a wrong path; see R-RELEASE-1).

### R-ITEM-1.1 — Coverage of all 8 templates
WHEN release v6.8.1 is tagged, THE SYSTEM SHALL contain a literal string `### Autopilot` in each of the 8 files under `examples/configs/` (`github-nextjs.md`, `github-python-fastapi.md`, `github-dotnet.md`, `gitea-spring-boot.md`, `jira-react.md`, `youtrack-python.md`, `redmine-rails.md`, `redmine-oracle-plsql.md`).

### R-ITEM-1.2 — Canonical 7-key row content
THE SYSTEM SHALL, in each of the 8 template files, include all 7 canonical Autopilot keys with default values matching the 7-key Autopilot table under the `### Example` block of `docs/reference/config.md` verbatim: `Max issues per run | 1`, `Lock timeout | 120`, `Log file | .ceos-agents/autopilot.log`, `Bug limit | 0`, `Feature limit | 0`, `On error | skip`, `Dry run | false`. (Defaults are also normatively defined in the `### Keys` table of `docs/reference/config.md` and in the `### Autopilot` row of `CLAUDE.md`'s Automation Config table; all three must agree.)

### R-ITEM-1.3 — Table format parity with sibling optional sections
THE SYSTEM SHALL render the Autopilot block with a `| Key | Value |` header row and Markdown alignment row (`|-----|-------|`), matching the table-format convention declared in `CLAUDE.md` Automation Config section ("All sections use table format (`| Key | Value |`). No bullet-point lists in config sections.").

### R-ITEM-1.4 — Commented-by-default placement for opt-in semantics
WHEN the 7 commented-style templates (i.e., the 8 templates MINUS `redmine-oracle-plsql.md`) embed the Autopilot block, THE SYSTEM SHALL place the block inside a `<!-- ... -->` HTML comment block preceded by the literal divider line `> **Uncomment and customize optional sections as needed.**` (pattern established at `examples/configs/github-nextjs.md:50-134`, where an existing `<!-- ... -->` comment block already contains other optional sections — for that file, the Autopilot block is inserted inside the existing comment block; for the other 6 templates, a new divider + comment block is appended at the end of the file). For `redmine-oracle-plsql.md`, the Autopilot block MAY alternatively appear as an active section (no `(optional)` suffix) in the active-sections region before the comment-block divider at line 113.

---

## Item 2 — issue_id Regex Gate (Path-Traversal Defense)

Traces to roadmap bullet 2: "`issue_id` regex gate in state.json path derivation (path-traversal defense-in-depth)". Scope expanded by research: 4 skills, not autopilot.

### R-ITEM-2.1 — Regex identity and character set
THE SYSTEM SHALL define the issue_id allowlist regex as the literal POSIX ERE pattern `^[A-Za-z0-9#_-]+$` in every skill that performs filesystem path construction from `{ISSUE-ID}`.

### R-ITEM-2.2 — Gate presence in all 4 affected skills
THE SYSTEM SHALL place an `issue_id validation` gate in each of the following skills, positioned BEFORE any textual reference to `.ceos-agents/{ISSUE-ID}/` AND AFTER the point at which `ISSUE_ID` is first bound:
- `skills/fix-ticket/SKILL.md` — single-issue entry point; gate is placed in Step 0 IMMEDIATELY AFTER `ISSUE_ID` is read from the skill argument and BEFORE any path-construction (before the reference near line 87).
- `skills/fix-bugs/SKILL.md` — batch entry point; `ISSUE_ID` is only bound INSIDE the per-issue loop body (after the tracker batch query). The gate is therefore placed at the TOP of the per-issue loop body, immediately after `ISSUE_ID` is assigned and BEFORE the directory-creation line near line 90. The gate is NOT placed in outer Step 0 (where `ISSUE_ID` does not yet exist).
- `skills/implement-feature/SKILL.md` — single-issue entry point; gate in Step 0 IMMEDIATELY AFTER `ISSUE_ID` is read and BEFORE any path-construction (before the reference near line 89).
- `skills/resume-ticket/SKILL.md` — single-issue entry point; gate in Step 0 IMMEDIATELY AFTER `ISSUE_ID` is read and BEFORE any path-construction (before the reference near line 17).

For all 4 files, the operative AC check is `gate_line < path_line` (AC-ITEM-2.2); the natural-language "Step 0" wording resolves to "as early as possible AFTER `ISSUE_ID` is bound and BEFORE any path use," which for `fix-bugs` is the top of the loop body, not outer Step 0.

### R-ITEM-2.3 — Behavior on valid input
WHEN `${ISSUE_ID}` matches `^[A-Za-z0-9#_-]+$`, THE SYSTEM SHALL proceed to the subsequent Step-0 actions (directory creation, state.json write) without additional error output.

### R-ITEM-2.4 — Behavior on invalid input (NEGATIVE — security-sensitive)
IF `${ISSUE_ID}` does NOT match `^[A-Za-z0-9#_-]+$`, THEN THE SYSTEM SHALL print a `[BLOCK]` line naming the disallowed value to stderr AND exit with status 1 AND SHALL NOT create any filesystem entry under `.ceos-agents/` for that invocation. The match MUST be performed with the bash built-in regex operator `[[ "${ISSUE_ID}" =~ ^[A-Za-z0-9#_-]+$ ]]` (which anchors against the ENTIRE string), NOT with `echo "${ISSUE_ID}" | grep -qE` (which evaluates per-line and is bypassable by embedded newlines).

### R-ITEM-2.5 — Negative character-set constraint (NEGATIVE — security-sensitive)
THE SYSTEM SHALL NOT permit any of the following characters in `${ISSUE_ID}` to pass the gate: `/`, `\`, `.` (therefore also `..`), space, null byte, `` ` ``, `$`, `"`, `'`, `(`, `)`, `<`, `>`, `|`, `~`, `;`, `&`, `*`, `?`, `[`, `]`, `{`, `}`, newline (LF), carriage return (CR). The regex `^[A-Za-z0-9#_-]+$` is the sole permitted allowlist; no additional branch MAY widen it.

### R-ITEM-2.6 — Newline-injection rejection (NEGATIVE — security-sensitive)
IF `${ISSUE_ID}` contains an embedded newline (`\n`) or carriage return (`\r`), THEN the gate SHALL reject it — even if one of the lines in the multi-line value would otherwise match the allowlist. This is the operative reason R-ITEM-2.4 mandates the bash `[[ =~ ]]` form over `echo … | grep -qE …` (the latter matches ANY line of piped multi-line input and is therefore bypassable; `[[ =~ ]]` anchors against the entire string). Example reject input: `$'../../etc/passwd\nPROJ-42'` — must exit 1.

---

## Item 3 — JSON-Encode Payload Interpolation Documentation

Traces to roadmap bullet 3: "JSON-encode payload field interpolation documentation (structured-data injection note)". Scope expanded by research: 3 files affected.

### R-ITEM-3.1 — Field-safety note in `core/post-publish-hook.md` Section 4
WHEN a consumer reads `core/post-publish-hook.md` Section 4, THE SYSTEM SHALL present a "Field value safety" note that (a) warns the heredoc prevents shell-word-splitting but does NOT JSON-encode field values, (b) states that externally-sourced fields (e.g., `issue_id`, `pr_url`) MUST be free of `"`, `\`, and control characters before interpolation, and (c) cross-references the issue_id regex gate from Item 2 as the primary defense for `issue_id`/`run_id` safety.

### R-ITEM-3.2 — `core/block-handler.md` Step 5 heredoc rewrite
WHEN `core/block-handler.md` Step 5 is rendered, THE SYSTEM SHALL use a `curl --data-binary @- ... <<EOF ... EOF` heredoc pattern with the `--proto "=http,https"` flag, replacing the previous inline `-d '...'` pattern.

### R-ITEM-3.3 — User-facing encoding note in `docs/guides/autopilot.md`
WHEN a consumer reads the webhook-payload section of `docs/guides/autopilot.md` (after line 286), THE SYSTEM SHALL present a "Payload field safety" note explaining that `issue_id`/`run_id` safety is guaranteed by the allowlist, that `pr_url` must be percent-encoded by the SCM MCP tool, and that custom post-publish hooks embedding free-form agent output (e.g., `reason`) MUST construct the payload via `jq -n --arg <name> "${value}" '{<field>:$<name>, ...}'` (structural JSON construction that delegates all string escaping to `jq`). The note MUST explicitly disallow interpolating variables directly into a quoted JSON literal for free-form text fields.

### R-ITEM-3.4 — Negative constraint on inline `-d` substitution (NEGATIVE — security-sensitive)
THE SYSTEM SHALL NOT, in any of `core/post-publish-hook.md`, `core/block-handler.md`, or `docs/guides/autopilot.md`, retain a `curl ... -d '{...}'` pattern that performs inline variable substitution into a single-quoted JSON string literal. All curl webhook invocations documented in these files MUST use the heredoc (`--data-binary @-` + `<<EOF`) pattern.

---

## Item 4 — Lock-Timeout Text Alignment

Traces to roadmap bullet 4: "Lock-timeout text alignment — spec says 120min, impl uses +5min clock-skew buffer (125min) — document the buffer explicitly in `skills/autopilot/SKILL.md`". Scope: 1 prose line (SKILL.md:368). No numeric implementation changes (120/121/125 are all intentional).

### R-ITEM-4.1 — Single-line prose alignment at `skills/autopilot/SKILL.md:368`
WHEN an operator reads the troubleshooting entry for `[autopilot][ERROR] Another Autopilot run in progress` at `skills/autopilot/SKILL.md:368`, THE SYSTEM SHALL state the effective stale threshold as the configured `Lock timeout` value plus a 5-minute NFS/CIFS clock-skew buffer AND SHALL name the default primary-path threshold (125 min) AND the BusyBox fallback threshold (121 min). The substring `<120min old` SHALL NOT appear in that line.

---

## Item 5 — Fixer-Reviewer Crash-Recovery Regression Test

Traces to roadmap bullet 5: "Fixer-reviewer crash-recovery regression test (mid-iteration crash → cumulative tokens_used integrity)". Dependency: loop contract text must exist before the test can assert it.

### R-ITEM-5.1 — Cumulative-tokens prose in `core/fixer-reviewer-loop.md` Step 10
WHEN an agent reads Step 10 of `core/fixer-reviewer-loop.md`, THE SYSTEM SHALL instruct that after each iteration the fields `fixer_reviewer.tokens_used`, `fixer_reviewer.duration_ms`, and `fixer_reviewer.tool_uses` are accumulated via `+=` against per-iteration measurements AND SHALL state that this per-iteration write preserves cost data on mid-loop pipeline crash.

### R-ITEM-5.2 — Regression scenario existence
WHEN the harness is run, THE SYSTEM SHALL discover an executable file at `tests/scenarios/v681-fixer-reviewer-crash-recovery.sh` whose filename prefix follows the PATCH-version convention (`v681-`, precedent: `tests/scenarios/v644-diagnostics-hardening.sh`).

### R-ITEM-5.3 — Scenario assertions cover tokens_used and crash-recovery
WHEN `v681-fixer-reviewer-crash-recovery.sh` executes, THE SYSTEM SHALL grep-assert (a) that `core/fixer-reviewer-loop.md` contains per-iteration tokens_used accumulation language, (b) that `core/fixer-reviewer-loop.md` mentions crash-recovery semantics (literal token `crash` or `preserv...partial`), (c) that `state/schema.md` documents cumulative semantics, and (d) that `core/state-manager.md` documents the running-total write rule for `fixer_reviewer`.

### R-ITEM-5.4 — Scenario exit-code contract
WHEN all four assertions pass, THE SYSTEM SHALL exit 0 and print a `PASS:` line; WHEN any assertion fails, THE SYSTEM SHALL exit non-zero and print one or more `FAIL:` lines.

---

## Item 6 — Test Harness Exit-Code Propagation

Traces to roadmap bullet 6: "Test harness exit-code propagation — harness currently exits 0 even when test failures exist; fix to propagate non-zero on any FAIL". Research note: harness is functionally correct today under `bash run-tests.sh`; the bug is latent `bash -e` wrapper robustness. Fix still warranted for all three `((N++))` sites.

### R-ITEM-6.1 — POSIX-safe counter increments in `tests/harness/run-tests.sh`
THE SYSTEM SHALL, in `tests/harness/run-tests.sh`, increment the PASS, SKIP, and FAIL counters using the assignment form `N=$((N+1))` (where `N` is one of `PASS`, `SKIP`, `FAIL`) AND SHALL NOT use the arithmetic-command post-increment form `((N++))` for any of these three counters.

### R-ITEM-6.2 — Aggregate-run exit code on any failure
WHEN `tests/harness/run-tests.sh` is invoked with no arguments (full-run mode) AND at least one scenario exits non-zero, THE SYSTEM SHALL exit with a non-zero status (specifically: `exit 1` at the end-of-run branch on line 67 or equivalent, consistent with the current branch `if [ "$FAIL" -gt 0 ]; then exit 1; fi`).

### R-ITEM-6.3 — Aggregate-run exit code on full pass
WHEN `tests/harness/run-tests.sh` is invoked with no arguments AND every scenario exits zero (no FAIL), THE SYSTEM SHALL exit with status 0.

### R-ITEM-6.4 — Meta-test scenario existence
WHEN the harness is run, THE SYSTEM SHALL discover an executable file at `tests/scenarios/v681-harness-exit-propagation.sh` (naming per user phase input) that greps `tests/harness/run-tests.sh` to confirm R-ITEM-6.1 AND executes a single-scenario functional check that confirms R-ITEM-6.2.

---

## Release Process

### R-RELEASE-1 — CHANGELOG entry for [6.8.1]
WHEN the release commit is created, THE SYSTEM SHALL include in `CHANGELOG.md` a top-of-file entry with heading `## [6.8.1] — 2026-04-18` containing a `### Fixed` subsection that enumerates all six items (R-ITEM-1 through R-ITEM-6) AND an `### Internal` subsection that lists the two new test scenarios (`v681-fixer-reviewer-crash-recovery.sh`, `v681-harness-exit-propagation.sh`). The Fixed subsection MUST reference the corrected path `examples/configs/*` (not the erroneous `examples/config-templates/*` used in the v6.8.0 Known Issues entry at `CHANGELOG.md:42`). The `### Internal` subsection name (NOT `### Added`) matches the v6.8.0 precedent at `CHANGELOG.md:44-46` which uses `### Internal` for test-infrastructure artifacts.

### R-RELEASE-2 — Version-bump via skill as separate commit
WHEN the version is bumped from `6.8.0` to `6.8.1`, THE SYSTEM SHALL perform the bump via `/ceos-agents:version-bump` (producing a separate commit that modifies only `.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json`) AND SHALL create a git tag `v6.8.1`. The content commit (R-RELEASE-1) MUST be created and pushed to the working tree before the version-bump skill is invoked (per `skills/version-bump/SKILL.md` Step 6 CHANGELOG guard and Step 7 uncommitted-changes guard).

### R-RELEASE-3 — Full harness passes before commit
WHEN the content commit is created, THE SYSTEM SHALL have previously run `./tests/harness/run-tests.sh` end-to-end with a non-error exit and a PASS tally no lower than the pre-change baseline (140) plus the two new v6.8.1 scenarios (expected: 142 passing; one scenario may be marked SKIP, resulting in 142 total + adjustments).
