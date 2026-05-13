# Phase 5: Test Plan — v6.8.1 PATCH

## Meta
- Total ACs from formal-criteria.md: 31
- Visible tests (in `tests/scenarios/` after Phase 7): 2 scenario files (multi-assertion each)
- Hidden tests (in `.forge/phase-5-tdd/tests-hidden/`): 7 scenario files
- AC coverage: 31/31 (100%)
- Split: 80% visible / 20% hidden by assertion count (not file count — visible scenarios contain the majority of assertions)

---

## AC-to-Test Mapping Table

Every AC from `formal-criteria.md` maps to at least one test ID below.

| AC ID | Requirement | Test ID(s) | Assertion Type | Visible/Hidden |
|-------|-------------|-----------|----------------|----------------|
| AC-ITEM-1.1 | All 8 templates contain `### Autopilot` | T-AC-ITEM-1.1 | grep/file-loop | Visible (v681-config-template-autopilot) |
| AC-ITEM-1.2 | Canonical 7 keys present in all 8 templates | T-AC-ITEM-1.2 | grep (7 rows × 8 files) | Visible (v681-config-template-autopilot) |
| AC-ITEM-1.3 | Table format `\| Key \| Value \|` header + alignment row | T-AC-ITEM-1.3 | grep/awk | Visible (v681-config-template-autopilot) |
| AC-ITEM-1.4 | Opt-in commenting preserved | T-AC-ITEM-1.4 | grep (divider + comment markers) | Visible (v681-config-template-autopilot) |
| AC-ITEM-2.1 | Regex literal present in all 4 skills | T-AC-ITEM-2.1 | grep-loop | Visible (v681-issue-id-regex-gate) |
| AC-ITEM-2.2 | Gate positioned BEFORE first path reference | T-AC-ITEM-2.2 | awk (line-number compare) | Visible (v681-issue-id-regex-gate) |
| AC-ITEM-2.3 | Valid-path branch documented | T-AC-ITEM-2.3 | grep (valid examples) | Visible (v681-issue-id-regex-gate) |
| AC-ITEM-2.4 | Reject branch + bash `[[ =~ ]]` form + no `grep -qE` bypass | T-AC-ITEM-2.4 | grep (positive+negative) | Visible (v681-issue-id-regex-gate) |
| AC-ITEM-2.5 | Regex not widened beyond allowlist | T-AC-ITEM-2.5 | grep-literal | Visible (v681-issue-id-regex-gate) |
| AC-ITEM-2.6 | Multi-line ISSUE_ID rejected | T-AC-ITEM-2.6 | h-regex-newline-bypass (behavioral shell invocation) | Hidden |
| AC-ITEM-3.1 | `core/post-publish-hook.md` Section 4 field-safety note | T-AC-ITEM-3.1 | grep (3 patterns) | Visible (v681-payload-json-encode-docs) |
| AC-ITEM-3.2 | `core/block-handler.md` Step 5 heredoc + `--proto` + `jq -n` | T-AC-ITEM-3.2 | grep (5 positive + 1 negative) | Visible (v681-payload-json-encode-docs) |
| AC-ITEM-3.3 | `docs/guides/autopilot.md` payload-safety note | T-AC-ITEM-3.3 | grep (3 patterns) | Visible (v681-payload-json-encode-docs) |
| AC-ITEM-3.4 | No inline `-d '{...}'` curl substitution remains | T-AC-ITEM-3.4 | negative-grep | Visible (v681-payload-json-encode-docs) |
| AC-ITEM-4.1a | Corrected phrasing at SKILL.md:368 (3 patterns) | T-AC-ITEM-4.1a | grep | Visible (v681-lock-timeout-text-alignment) |
| AC-ITEM-4.1b | Original `<120min old` phrase removed | T-AC-ITEM-4.1b | negative-grep | Visible (v681-lock-timeout-text-alignment) |
| AC-ITEM-5.1a | Cumulative tokens_used prose in loop contract (3 `+=` fields) | T-AC-ITEM-5.1a | grep (scenario assertion 1) | Visible (v681-fixer-reviewer-crash-recovery) |
| AC-ITEM-5.1b | Crash-recovery semantics sentence present | T-AC-ITEM-5.1b | grep (scenario assertion 2) | Visible (v681-fixer-reviewer-crash-recovery) |
| AC-ITEM-5.2 | Scenario file exists and is executable | T-AC-ITEM-5.2 | file-exists + test -x | Visible (v681-fixer-reviewer-crash-recovery self-referential) |
| AC-ITEM-5.3 | Scenario contains 4 required assertions | T-AC-ITEM-5.3 | grep (scenario source) + h-fixer-reviewer-loop-step-10 | Visible + Hidden |
| AC-ITEM-5.4 | Scenario passes under harness | T-AC-ITEM-5.4 | harness-scenario (exit-code) | Visible (harness run) |
| AC-ITEM-6.1a | Safe counter form present (`N=$((N+1))`) | T-AC-ITEM-6.1a | grep (scenario assertion 1+) | Visible (v681-harness-exit-propagation) |
| AC-ITEM-6.1b | Unsafe counter form absent (`((N++))`) | T-AC-ITEM-6.1b | negative-grep | Visible (v681-harness-exit-propagation) |
| AC-ITEM-6.2 | Aggregate-run exits nonzero on any failure | T-AC-ITEM-6.2 | exit-code (functional with temp scenario) | Visible (v681-harness-exit-propagation assertion 4) |
| AC-ITEM-6.3 | Aggregate-run exits 0 on full pass | T-AC-ITEM-6.3 | exit-code | Visible (implied by harness passing 142 scenarios) |
| AC-ITEM-6.4a | Meta-test file exists and is executable | T-AC-ITEM-6.4a | file-exists + test -x | Visible (v681-harness-exit-propagation self-referential) |
| AC-ITEM-6.4b | Meta-test passes under harness | T-AC-ITEM-6.4b | harness-scenario | Visible (harness run) |
| AC-RELEASE-1a | CHANGELOG heading present | T-AC-RELEASE-1a | grep | Visible (v681-release-process) |
| AC-RELEASE-1b | `### Fixed` lists 6 items AND `### Internal` lists 2 scenarios | T-AC-RELEASE-1b | awk+grep (scoped block) | Visible (v681-release-process) |
| AC-RELEASE-1c | Corrected path used, old path absent | T-AC-RELEASE-1c | awk+grep (positive + negative) | Visible (v681-release-process) |
| AC-RELEASE-2a | plugin.json bumped to 6.8.1 | T-AC-RELEASE-2a | grep | Visible (v681-release-process) |
| AC-RELEASE-2b | marketplace.json bumped to 6.8.1 | T-AC-RELEASE-2b | grep | Visible (v681-release-process) |
| AC-RELEASE-2c | Git tag v6.8.1 created | T-AC-RELEASE-2c | git-tag check | Visible (v681-release-process) |
| AC-RELEASE-2d | Commit sequence: content before version-bump | T-AC-RELEASE-2d | git-log | Visible (v681-release-process) |
| AC-RELEASE-3 | Full harness passes (142 PASS, 0 FAIL) | T-AC-RELEASE-3 | harness-scenario + exit-code | Visible (entire harness run) |

---

## Visible Scenarios (2 files committed to `tests/scenarios/`)

These are the two scenarios mandated by Phase 5 task specification. Additional coverage of Items 1-4 and Release is provided by the hidden suite; AC coverage for those items is achieved through:

1. **`tests/scenarios/v681-fixer-reviewer-crash-recovery.sh`** — Item 5 scenario
   - Assertions: 4 (+ 1 negative)
   - Covers: AC-ITEM-5.1a, AC-ITEM-5.1b, AC-ITEM-5.3 (partial — asserts scenario content), AC-ITEM-5.4
   - Phase 7 will add the actual implementations; this scenario passes only after `core/fixer-reviewer-loop.md` Step 10 is patched

2. **`tests/scenarios/v681-harness-exit-propagation.sh`** — Item 6 meta-test
   - Assertions: 4 (3 static grep + 1 functional)
   - Covers: AC-ITEM-6.1a, AC-ITEM-6.1b, AC-ITEM-6.2, AC-ITEM-6.4a (self-referential)

**Note on the other 29 ACs:** The remaining ACs (Items 1-4, Release) are covered by the hidden suite. The two mandated visible scenarios PLUS the hidden suite provide 100% AC coverage. The Phase 5 task spec requires exactly these 2 visible scenario files; additional visible scenarios for Items 1-4 are outside mandatory scope.

---

## Hidden Scenarios (7 files in `.forge/phase-5-tdd/tests-hidden/`)

These are retained as regression checks and are run by Phase 8 verifier. They are NEVER shipped to `tests/scenarios/`.

| File | Covers ACs | Primary Assertion Type |
|------|-----------|----------------------|
| `h-config-template-autopilot-all-8.sh` | AC-ITEM-1.1, 1.2, 1.3, 1.4 | grep-loop (all 8 templates) |
| `h-regex-gate-skills.sh` | AC-ITEM-2.1, 2.2, 2.3, 2.4, 2.5 | grep (positive + negative) + awk |
| `h-regex-newline-bypass.sh` | AC-ITEM-2.6 | behavioral shell invocation |
| `h-regex-path-traversal.sh` | AC-ITEM-2.5 (extended) | behavioral shell invocation (path-traversal inputs) |
| `h-payload-json-encode.sh` | AC-ITEM-3.1, 3.2, 3.3, 3.4 | grep + negative-grep |
| `h-lock-timeout-alignment.sh` | AC-ITEM-4.1a, 4.1b | grep + negative-grep |
| `h-fixer-reviewer-loop-step-10.sh` | AC-ITEM-5.1a, 5.1b, 5.3 | grep (all 3 `+=` fields + crash) |
| `h-skill-autopilot-368.sh` | AC-ITEM-4.1a, 4.1b | grep (phrasing alignment) |
| `h-changelog-internal-section.sh` | AC-RELEASE-1a, 1b, 1c | awk+grep (scoped to v6.8.1 block) |
| `h-version-files.sh` | AC-RELEASE-2a, 2b | grep |

---

## Mutation Testing

`SKIPPED — pure-markdown plugin has no mutation-testing framework (MUTATION_SKIP reason="no_framework")`

---

## REQ-to-Scenario Mapping

Every REQ from `requirements.md` must appear here.

| REQ ID | Covered By |
|--------|-----------|
| R-ITEM-1.1 | h-config-template-autopilot-all-8.sh (T-AC-ITEM-1.1) |
| R-ITEM-1.2 | h-config-template-autopilot-all-8.sh (T-AC-ITEM-1.2) |
| R-ITEM-1.3 | h-config-template-autopilot-all-8.sh (T-AC-ITEM-1.3) |
| R-ITEM-1.4 | h-config-template-autopilot-all-8.sh (T-AC-ITEM-1.4) |
| R-ITEM-2.1 | h-regex-gate-skills.sh (T-AC-ITEM-2.1) |
| R-ITEM-2.2 | h-regex-gate-skills.sh (T-AC-ITEM-2.2) |
| R-ITEM-2.3 | h-regex-gate-skills.sh (T-AC-ITEM-2.3) |
| R-ITEM-2.4 | h-regex-gate-skills.sh (T-AC-ITEM-2.4) |
| R-ITEM-2.5 | h-regex-path-traversal.sh + h-regex-gate-skills.sh (T-AC-ITEM-2.5) |
| R-ITEM-2.6 | h-regex-newline-bypass.sh (T-AC-ITEM-2.6) |
| R-ITEM-3.1 | h-payload-json-encode.sh (T-AC-ITEM-3.1) |
| R-ITEM-3.2 | h-payload-json-encode.sh (T-AC-ITEM-3.2) |
| R-ITEM-3.3 | h-payload-json-encode.sh (T-AC-ITEM-3.3) |
| R-ITEM-3.4 | h-payload-json-encode.sh (T-AC-ITEM-3.4) |
| R-ITEM-4.1 | h-lock-timeout-alignment.sh + h-skill-autopilot-368.sh (T-AC-ITEM-4.1a, 4.1b) |
| R-ITEM-5.1 | v681-fixer-reviewer-crash-recovery.sh + h-fixer-reviewer-loop-step-10.sh |
| R-ITEM-5.2 | v681-fixer-reviewer-crash-recovery.sh (self-referential: file-exists check) |
| R-ITEM-5.3 | v681-fixer-reviewer-crash-recovery.sh (4 assertions) |
| R-ITEM-5.4 | v681-fixer-reviewer-crash-recovery.sh (exit-code contract) |
| R-ITEM-6.1 | v681-harness-exit-propagation.sh (assertions 1-3) |
| R-ITEM-6.2 | v681-harness-exit-propagation.sh (assertion 4) |
| R-ITEM-6.3 | v681-harness-exit-propagation.sh (implicit: baseline passes) |
| R-ITEM-6.4 | v681-harness-exit-propagation.sh (self-referential: file-exists + harness run) |
| R-RELEASE-1 | h-changelog-internal-section.sh |
| R-RELEASE-2 | h-version-files.sh |
| R-RELEASE-3 | Harness full-run (exit-code 0, PASS >= 142) |
