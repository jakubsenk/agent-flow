# Phase 1 Research Questions — Agent 2 (Test-Engineering Specialist)

Perspective: Test-engineering specialist. Questions are weighted toward item 5 (crash-recovery regression test) and item 6 (exit-code propagation), with at least one question per remaining item.

---

## Questions

### Item 5 — Fixer-Reviewer Crash-Recovery Regression Test (PRIMARY)

**Q1. What is the current test-scenario skeleton format used in tests/scenarios/*.sh?**

Inspect `tests/scenarios/ac-v68-cost-fixer-reviewer-cumulative.sh`, `tests/scenarios/ac5-fixer-reviewer-token-constraints.sh`, and `tests/scenarios/pipeline-state-writes.sh`. Determine: (a) shebang line convention, (b) `set` flags pattern (`set -euo pipefail` vs `set -uo pipefail`), (c) use of `REPO_ROOT` vs `cd "$(dirname "$0")/../.."`, (d) `FAIL=0` / `fail()` helper pattern vs direct `exit 1`, (e) final `[ "$FAIL" -eq 0 ] && echo "PASS: ..."` / `exit "$FAIL"` pattern. All five structural elements must be replicated exactly in the new scenario.

*Target files:* `tests/scenarios/ac-v68-cost-fixer-reviewer-cumulative.sh`, `tests/scenarios/ac5-fixer-reviewer-token-constraints.sh`, `tests/scenarios/pipeline-state-writes.sh`

---

**Q2. What is the existing test coverage for fixer-reviewer mid-iteration state persistence, and what is the gap the new scenario must fill?**

Search `tests/scenarios/` for all files that grep-match `fixer_reviewer` or `tokens_used` or `cumulative`. List them. For each, summarize what assertion it makes and what it does NOT test. Determine: does any existing scenario simulate a mid-iteration crash (i.e., fixer exits before tokens_used is committed) and then assert that the cumulative accumulator is still correct on resume? If not, this is the gap the new scenario addresses.

*Target files:* `tests/scenarios/ac-v68-cost-fixer-reviewer-cumulative.sh`, `tests/scenarios/ac-v68-cost-pipeline-accumulator.sh`, `tests/scenarios/pipeline-state-writes.sh`, `core/fixer-reviewer-loop.md`

---

**Q3. What does core/fixer-reviewer-loop.md say about how tokens_used is written during an iteration, and is there a documented crash-recovery path?**

Read `core/fixer-reviewer-loop.md` in full. Find: (a) which step writes `fixer_reviewer.tokens_used` to state.json, (b) whether the write is atomic/immediate after each iteration or only on loop exit, (c) whether any fallback or recovery path is documented for mid-iteration failures. The answer determines what the crash-recovery scenario can assertively test with static grep (doc-level assertions).

*Target files:* `core/fixer-reviewer-loop.md`, `core/state-manager.md` (Failure Handling section)

---

**Q4. What exact grep assertions can a static scenario make to verify crash-recovery semantics for fixer-reviewer tokens_used?**

Given that scenarios in this repo are static document-checkers (grep against markdown source, not runtime simulators), determine the concrete grep-able strings that would confirm: (a) `fixer_reviewer.tokens_used` is written atomically after EACH iteration (not only at end of loop), (b) the state-manager's "retry once" atomic-write rule is referenced in the fixer-reviewer loop context, (c) the `pipeline.total_tokens` accumulator reads from per-stage fields (so a mid-iteration crash at iteration N preserves tokens from iterations 1..N-1). Check whether any of these strings exist today in `core/fixer-reviewer-loop.md` or `core/state-manager.md`.

*Target files:* `core/fixer-reviewer-loop.md`, `core/state-manager.md`, `state/schema.md`

---

### Item 6 — Test Harness Exit-Code Propagation (PRIMARY)

**Q5. What is the exact current exit-code behavior of tests/harness/run-tests.sh when at least one scenario fails, and where specifically does the correct non-zero propagation already happen?**

Read `tests/harness/run-tests.sh` (already read — 69 lines). Confirm: (a) line 66-68 `if [ $FAIL -gt 0 ]; then exit 1; fi` IS present and IS reached in the full-run path, (b) the single-scenario path (lines 25-31) correctly exits 1 on failure, (c) identify whether `FAIL` counter is incremented for SKIP (exit 77) — answer: no, SKIP never increments FAIL. State the conclusion: does the harness currently exit non-zero when FAIL > 0? If the `exit 1` at line 67 is already present, clarify what the roadmap item means — is there a path where FAIL > 0 but the harness still exits 0?

*Target files:* `tests/harness/run-tests.sh` (lines 35-68)

---

**Q6. What CI integration or calling context consumes the harness exit code, and what would "exits 0 despite failures" look like in practice?**

Search for any CI workflow files (`.gitea/workflows/`, `.github/workflows/`, `Makefile`) that call `run-tests.sh`. If none are found, check `docs/guides/` and `docs/reference/` for any harness invocation documentation. Determine whether there is a documented scenario where the harness exit code is silently swallowed (e.g., `run-tests.sh || true`, `run-tests.sh; echo done` ignoring `$?`). This determines whether the fix scope is the harness itself or calling conventions.

*Target files:* `tests/harness/run-tests.sh`, `.gitea/workflows/*.yml` (if any), `docs/guides/`, `docs/reference/`

---

**Q7. Is there a test scenario that validates the harness exit-code behavior itself, and if so, what does it check?**

Search `tests/scenarios/` for files that grep-match `run-tests|harness|exit.*1|FAIL.*gt.*0`. Candidate: `tests/scenarios/test-fail.sh` (visible in scenario listing). Read it. Determine: does it test that the harness propagates non-zero on failure? This reveals whether a new meta-test scenario is needed as part of the fix, or whether only the harness script itself needs updating.

*Target files:* `tests/scenarios/test-fail.sh`, `tests/scenarios/verify-fail.sh`

---

### Item 1 — Config Templates: Autopilot Section Row

**Q8. What is the exact structure used for optional section rows in each of the 8 config templates, and which templates currently end at Build & Test (no optional sections at all)?**

Read `examples/configs/github-nextjs.md` (already read — shows commented-out block) and `examples/configs/gitea-spring-boot.md` (already read — ends at Build & Test, no optional sections). For all 8 templates: (a) do they include optional sections inline, in a comment block, or not at all? (b) what is the exact markdown heading format for a new section row? (c) should the `### Autopilot` section be added inside the existing comment block (if one exists) or as a new commented-out section at the end? Compare: `youtrack-python.md` ends at Build & Test with no comment block at all. The fix must be consistent across all 8 files.

*Target files:* All 8 files in `examples/configs/` — `github-nextjs.md`, `github-python-fastapi.md`, `github-dotnet.md`, `gitea-spring-boot.md`, `jira-react.md`, `youtrack-python.md`, `redmine-rails.md`, `redmine-oracle-plsql.md`

---

### Item 2 — issue_id Regex Gate

**Q9. Where exactly in skills/autopilot/SKILL.md is the issue_id used to construct the state.json file path, and what characters do real tracker issue IDs contain across the 6 supported tracker types?**

In `skills/autopilot/SKILL.md`, locate every line that interpolates `issue_id` or `ISSUE-ID` into a file path or directory name (e.g., `.ceos-agents/{RUN-ID}/`). Confirm: the log-file line in Step 7 (`{ISO8601}|{run_id}|...`) uses issue IDs from child dispatches, but the path at risk is `.ceos-agents/{ISSUE-ID}/state.json` (from `core/state-manager.md`). Check whether `skills/autopilot/SKILL.md` itself constructs this path or merely passes `issue_id` to child skills. Determine: where should the regex gate be inserted — in autopilot Step 5 (classification loop) before dispatching? Also: in `state/schema.md` or `core/state-manager.md`, what characters appear in issue ID examples (e.g., `PROJ-42`, `AUTH-1`, `#123` for GitHub/Gitea)?

*Target files:* `skills/autopilot/SKILL.md` (Steps 5-6), `core/state-manager.md`, `state/schema.md`

---

### Item 3 — JSON-Encoding Documentation

**Q10. Does any existing note in core/post-publish-hook.md explicitly document JSON-encoding requirements for payload field values, or does the current documentation only cover heredoc usage for shell-quoting safety?**

In `core/post-publish-hook.md`, the Section 3 `pr-created` Note says: "Use a heredoc to pass the JSON body so that special characters (quotes, backslashes) in variable values do not break the shell command." Section 4 says: "Use the same curl --max-time 5 --retry 0 pattern with a heredoc." Determine: (a) is there any mention of JSON-encoding (e.g., `jq --arg`, `printf %s | python -c "import json,sys; print(json.dumps(sys.stdin.read()))"`, or explicit note that values with `"` must be escaped as `\"`), (b) does `core/block-handler.md` have a similar note for its curl invocation (which uses `-d` with inline variable substitution rather than heredoc), (c) what is the exact line range in `core/post-publish-hook.md` where the new JSON-encoding note should be inserted?

*Target files:* `core/post-publish-hook.md` (lines 17-24 Section 3; lines 100-113 Section 4), `core/block-handler.md` (lines 40-44)

---

### Item 4 — Lock-Timeout Text Alignment

**Q11. What are ALL occurrences of "120" and "125" in skills/autopilot/SKILL.md and in docs/guides/autopilot.md, and is there any location where a reader could conclude the stale threshold is 125min (not 120min)?**

Grep `skills/autopilot/SKILL.md` for `120` and `125`. From reading: line 52 (`Lock timeout` default = 120), line 101 (stale detection prose "older than `Lock timeout` minutes (default 120)"), line 128 (`LOCK_TIMEOUT_WITH_BUFFER=$((LOCK_TIMEOUT + 5))`), line 191 (`find -mmin +121`), Invariant 6 ("Stale threshold carries a +5 minute buffer"), Troubleshooting line ("`<120min old`"). Also grep `docs/guides/autopilot.md` for the same. Determine: is there any prose that says the stale threshold is 125, or is the ambiguity that the BusyBox fallback uses `+121` (not `+120`) and the buffer makes the effective threshold 125 without being named? What single sentence would resolve the ambiguity, and which section/line in SKILL.md is the canonical insertion point?

*Target files:* `skills/autopilot/SKILL.md` (all 395 lines), `docs/guides/autopilot.md`

---

### Changelog + Version-Bump Verification

**Q12. What is the exact section structure of the v6.8.0 CHANGELOG entry (Added/Changed/Fixed/Migration notes/Known Issues/Internal), and does the version-bump skill require a CHANGELOG entry for the new version before it will run?**

Read `CHANGELOG.md` lines 1-47 (already read). Confirm: (a) v6.8.0 uses Added / Changed / Migration notes / Known Issues / Internal — no standalone "Fixed" section, (b) the `### Known Issues (deferred to v6.8.1)` subsection explicitly calls out the config-template gap, (c) the version-bump skill (read in full) has a CHANGELOG guard at step 6 that blocks if `## [6.8.1]` heading is absent. A v6.8.1 CHANGELOG entry must be written as part of the PATCH before version-bump can run; confirm the v6.8.0 known-issues subsection is the natural "resolved" counterpart.

*Target files:* `CHANGELOG.md` (lines 1-47), `skills/version-bump/SKILL.md` (steps 6-7)

---

## Summary

### Item Coverage

| Item | Questions |
|------|-----------|
| 1 — Config templates Autopilot row | Q8 |
| 2 — issue_id regex gate | Q9 |
| 3 — JSON-encoding payload docs | Q10 |
| 4 — Lock-timeout text alignment | Q11 |
| 5 — Fixer-reviewer crash-recovery regression test | Q1, Q2, Q3, Q4 (4 questions — heaviest coverage) |
| 6 — Test harness exit-code propagation | Q5, Q6, Q7 (3 questions — second heaviest) |
| CHANGELOG + version-bump | Q12 |

Total: 12 questions.

### Phase 2 Files to Read

Priority order:

1. `core/fixer-reviewer-loop.md` — full read (Q3, Q4)
2. `core/state-manager.md` — Usage Field Capture + Failure Handling sections (Q3, Q4, Q9)
3. `state/schema.md` — fixer_reviewer section + pipeline accumulator (Q4, Q9)
4. `tests/scenarios/test-fail.sh` — full read (Q7)
5. `tests/scenarios/verify-fail.sh` — full read (Q7)
6. `docs/guides/autopilot.md` — grep for "120", "125", "stale" (Q11)
7. `examples/configs/github-python-fastapi.md`, `github-dotnet.md`, `jira-react.md`, `redmine-oracle-plsql.md` — structural audit (Q8, unread templates)
8. `core/block-handler.md` lines 38-46 — curl invocation format (Q10)
9. `tests/harness/run-tests.sh` lines 35-68 — confirmed read; re-confirm exit path (Q5)
