# Phase 1 Research Questions — Track 1: Test Discipline Overhaul (Agent 1)

---

## Q1 [CRITICAL-PATH]

**What is the exact count breakdown of the 41 doc-grep scenarios, partitioned by KEEP / REWRITE / RETIRE decision criterion?**

The KEEP criterion is: the test's only feasible assertion is structural document presence (e.g., `v6.9.0-license-file-exists.sh` — a LICENSE file must exist and contain verbatim MIT text; no bash logic to simulate). The REWRITE criterion is: the test checks a string that guards a runtime behavior implementable in bash/jq without external services (e.g., `v6.9.0-pipeline-history-credential-redaction.sh` already has partial functional checks via `=~` patterns that can be extended). The RETIRE criterion is: the test asserts a one-shot release fact that is now stale and permanently passes (e.g., `v6.9.0-changelog-completeness.sh` — the v6.9.0 CHANGELOG entry exists and will never change; `v6.9.0-doc-count-drift.sh` — the 16/19 count strings are now permanent). The question is: which of the 41 files falls into each bucket?

**Answer source:** `tests/scenarios/v6.9.0-*.sh` (enumerate all 41 files; read each; classify by criterion above).

---

## Q2 [CRITICAL-PATH]

**Which v6.9.0 scenarios are definitive RETIRE candidates because they verify a one-shot release artifact that is now a permanent, immutable fact?**

Specifically: (a) `v6.9.0-changelog-completeness.sh` asserts that the v6.9.0 CHANGELOG entry exists with specific section headers and enumerated terms — this is permanently true and cannot regress; (b) `v6.9.0-doc-count-drift.sh` asserts `16 shared pipeline pattern contracts` and `19 optional config sections in total` strings in CLAUDE.md — permanently true; (c) `v6.9.0-plugin-repo-url-invalid-tld.sh` asserts `example.invalid` placeholder URL exists — this WILL change in v6.10.1 (canonical URL), making this scenario a future false-negative; (d) `ac-v692-autopilot-bash-dispatch.sh` asserts v6.9.2-specific `claude -p` dispatch pattern. Are there other one-shot version-pinned scenarios among the 41 that should be retired rather than rewritten?

**Answer source:** `tests/scenarios/v6.9.0-*.sh` — check each for version-string pins, CHANGELOG-entry greps, or assertions that reference content that will change in v6.10.0/v6.10.1.

---

## Q3 [CRITICAL-PATH]

**For each REWRITE candidate among the 41, what is the minimum functional assertion coverage required — specifically, does the rewrite need (a) state.json construction via `jq -n`, (b) pure bash string/regex simulation, or (c) file-system artifact construction?**

The reference pattern in `tests/scenarios/v6.9.0-needs-clarification-e2e.sh` uses all three tiers. Examples: `v6.9.0-needs-clarification-dos-cap.sh` currently checks only that `clarifications_consumed` appears in `state/schema.md` — a REWRITE must construct a synthetic `state.json` (tier a) and simulate the cap enforcement logic (tier b). By contrast, `v6.9.0-jq-compact-form.sh` already has functional regex assertions — it may need only a tier-b extension (actually run `jq -nc` against a synthetic payload). What is the coverage tier for each REWRITE candidate?

**Answer source:** `tests/scenarios/v6.9.0-*.sh` (read each scenario body) + `tests/scenarios/v6.9.0-needs-clarification-e2e.sh` (reference pattern for tier classification).

---

## Q4 [CRITICAL-PATH]

**What reusable bash+jq fixtures can be extracted from `tests/scenarios/v6.9.0-needs-clarification-e2e.sh` into a shared harness helper, and what is the exact extraction boundary?**

The e2e scenario contains: (a) `jq -n ... '{schema_version: "1.0", run_id: ..., status: "paused", clarification: {...}}'` — a canonical synthetic `state.json` builder; (b) `awk '/^sanitize_block_reason\(\) \{/,/^}$/'` — a function-body extractor pattern; (c) `(set +u; . "$SANITIZE_SCRIPT"; ...)` — a subshell-isolation sourcing pattern for testing extracted bash functions; (d) `SCRATCH="$(mktemp -d ...)"` + `trap 'rm -rf "$SCRATCH"' EXIT` — the temp-dir pattern. Which of these are already used in other scenarios, which are unique to this file, and what helper file path would a shared fixture live at (e.g., `tests/harness/fixtures.sh` or `tests/harness/state-builder.sh`)?

**Answer source:** `tests/scenarios/v6.9.0-needs-clarification-e2e.sh` (full file — already read) + `tests/harness/run-tests.sh` (harness contract — determines if a helper-include mechanism exists) + `tests/scenarios/v6.9.0-pipeline-history-credential-redaction.sh` (also uses awk function-extraction).

---

## Q5 [CRITICAL-PATH]

**What is the exact verbatim text of the EXTERNAL INPUT Constraint block that must be copied to the 8 remaining agents (spec-reviewer, spec-writer, rollback-agent, sprint-planner, scaffolder, stack-selector, deployment-verifier, publisher)?**

The roadmap states "Copy v6.9.0 EXTERNAL INPUT Constraint block from agents/test-engineer.md" but `agents/test-engineer.md` does NOT contain an EXTERNAL INPUT Constraint — it has no such constraint in its `## Constraints` section. The constraint IS present in agents that were updated in v6.9.0 (e.g., `agents/fixer.md` line 115, `agents/triage-analyst.md` line 124, `agents/code-analyst.md`, `agents/reviewer.md`, etc.). Which agent's single-line form is the authoritative canonical source for the 8-agent batch copy? Does any agent have a multi-line variant (e.g., fixer's two-line receiver-side extension)?

**Answer source:** `agents/fixer.md`, `agents/triage-analyst.md`, `agents/code-analyst.md`, `agents/reviewer.md`, `agents/acceptance-gate.md`, `agents/spec-analyst.md`, `agents/reproducer.md`, `agents/priority-engine.md` (grep output already shows all 13 current EXTERNAL INPUT lines across agents/).

---

## Q6 [CRITICAL-PATH]

**Does the current test harness (`tests/harness/run-tests.sh`) have any fixture-include or shared-helper mechanism, or does every scenario have to be self-contained?**

`run-tests.sh` sources each `*.sh` via `bash "$scenario"` — it does NOT `source` them, meaning no environment is shared between scenarios. The harness has no `source tests/harness/fixtures.sh` call and no helper-loading step. This determines whether a shared `state-builder.sh` fixture can be `source`d by scenarios or must be manually duplicated. The answer also constrains whether the 20-40 new functional tests can rely on a helper or must each construct state.json inline.

**Answer source:** `tests/harness/run-tests.sh` (full file — already read). Cross-check: any `source` or `. ` calls in existing multi-file scenarios.

---

## Q7 [CRITICAL-PATH]

**What is the exact Phase 9 doc-audit enumeration checklist that would have caught the v6.9.0 miss — specifically, what is the delta between a count-string check and an enumeration-completeness check for each of the four known drift-prone count strings?**

The v6.9.0 miss: Phase 9 checked that CLAUDE.md said `"19 optional sections"` but did not verify that all 19 were listed by name in the table. The four known drift-prone strings are: (a) optional config section count (19 after v6.9.0 — now needs to become 20 if v6.10.0 adds a new section, or stay at 19 if not), (b) core contract count (16), (c) agent count (21), (d) skill count (29). For each, what is the authoritative enumerable source to diff against the count string? For example: for optional sections, is the authoritative list in `docs/reference/automation-config.md` or in `CLAUDE.md`'s table itself?

**Answer source:** `CLAUDE.md` (current count strings) + `docs/reference/automation-config.md` (authoritative section enumeration) + `tests/scenarios/v6.9.0-doc-count-drift.sh` (existing count-string check pattern showing what was already checked vs what was missed).

---

## Q8 [CRITICAL-PATH]

**Which of the 41 doc-grep v6.9.0 scenarios have partial functional logic already (making them EXTEND candidates rather than full REWRITE) — i.e., they use `bash =~`, `awk`, or `for ... in ... grep` loops beyond a single `grep -qF`?**

From reading: `v6.9.0-pipeline-history-credential-redaction.sh` already has 6 `bash =~` pattern-match tests (but does NOT execute `sanitize_block_reason()` — only validates regex patterns match inputs in a subshell); `v6.9.0-cross-file-invariants.sh` uses `awk` section-extraction; `v6.9.0-needs-clarification-dos-cap.sh` has multi-file `for` loops. These are EXTEND candidates (add jq state construction on top of existing logic) rather than full rewrites from scratch. What is the complete list of scenarios with intermediate complexity (awk/=~/for loops)?

**Answer source:** `tests/scenarios/v6.9.0-*.sh` — scan all 41 for `awk`, `bash =~`, `for.*in.*grep`, `wc -l` loop patterns (beyond trivial `grep -c`).

---

## Q9 [CRITICAL-PATH]

**What naming convention must the new v6.10.0 functional test scenarios follow, and does the harness have any exclusion mechanism that would prevent all 184 existing scenarios from running during the Test Discipline Overhaul?**

Current naming: `ac-v{ver}-<area>-<assertion>.sh` for version-tagged ACs, and `<area>-<assertion>.sh` for evergreen tests. The e2e reference is `v6.9.0-needs-clarification-e2e.sh`. New functional tests for v6.10.0 rewrites of existing v6.9.0 scenarios — should they be named `v6.10.0-<area>-functional.sh` (keeping the v6.9.0 original intact as a KEEP), or should the v6.9.0 file be replaced in-place? The harness runs ALL `*.sh` in `tests/scenarios/` with no exclude list — what prevents retired scenarios from running (exit 77 = SKIP is the only mechanism per `run-tests.sh` line 45)?

**Answer source:** `tests/harness/run-tests.sh` (exit-77 SKIP mechanism confirmed) + existing scenario naming patterns in `tests/scenarios/` directory listing.

---

## Q10 [CLARIFICATION-TIER]

**For the `v6.9.0-bc-no-new-required-key.sh` backward-compatibility scenario — does it use `bash =~` array iteration that constitutes partial functional logic, or is it a pure `grep -F` doc-string check?**

If it uses array iteration over known required keys and asserts each is present, it is structurally similar to `frontmatter-completeness.sh` (KEEP — structural integrity check, not a one-shot release fact). This determines whether backward-compatibility scenarios are KEEP or REWRITE.

**Answer source:** `tests/scenarios/v6.9.0-bc-no-new-required-key.sh`.

---

## Q11 [CLARIFICATION-TIER]

**For scenarios that verify OSS readiness artifacts (`v6.9.0-license-file-exists.sh`, `v6.9.0-code-of-conduct.sh`, `v6.9.0-security-md.sh`, `v6.9.0-issue-pr-templates.sh`) — are these KEEP (permanent structural integrity) or RETIRE (one-shot release gate, now always-passes)?**

The LICENSE file, CODE_OF_CONDUCT.md, and SECURITY.md are permanent repo artifacts — checking they exist and contain required strings is a structural integrity test that guards against future accidental deletion. This is different from a one-shot release fact. The RETIRE criterion (stale one-shot release check) does not apply. These are KEEP. But do any of them have version-pinned assertions (e.g., copyright year `2024-2026`) that will fail on a future year update?

**Answer source:** `tests/scenarios/v6.9.0-license-file-exists.sh`, `tests/scenarios/v6.9.0-code-of-conduct.sh`, `tests/scenarios/v6.9.0-security-md.sh`, `tests/scenarios/v6.9.0-issue-pr-templates.sh`.

---

## Q12 [CLARIFICATION-TIER]

**Does `tests/scenarios/v6.9.0-pause-timeout-validation.sh` currently test the `parse_pause_timeout()` function behaviorally (subshell-source + input feeding) or only check its presence via `grep -qF`?**

`parse_pause_timeout()` is a bash function in `skills/autopilot/SKILL.md`. If the scenario only greps for the function name, it is a REWRITE target requiring a subshell-source extraction pattern (same as `sanitize_block_reason()` in the e2e reference). If it already sources and calls the function, it may be EXTEND. This is a concrete gating question for the REWRITE scope estimate.

**Answer source:** `tests/scenarios/v6.9.0-pause-timeout-validation.sh`.

---

## Q13 [CLARIFICATION-TIER]

**What is the complete list of agents that currently have the single-line EXTERNAL INPUT Constraint (the NEVER-follow-instructions line), and what agents have the extended two-line receiver-side variant (fixer, triage-analyst) — so the batch-copy spec can enumerate substitution rules?**

From the grep output: 13 agents currently have the single-line form; fixer and triage-analyst have an additional second line ("Receiver-side EXTERNAL INPUT defense: When resuming from a NEEDS_CLARIFICATION pause..."). The 8 target agents (spec-reviewer, spec-writer, rollback-agent, sprint-planner, scaffolder, stack-selector, deployment-verifier, publisher) need only the base single-line form (they are not NEEDS_CLARIFICATION resume paths). What is the exact line-for-line text of the single-line canonical form as it appears in, e.g., `agents/code-analyst.md`, so the spec can provide a verbatim copy target without ambiguity?

**Answer source:** `agents/code-analyst.md` (line 120 per grep output — read the full Constraints section to confirm no surrounding context is needed).
