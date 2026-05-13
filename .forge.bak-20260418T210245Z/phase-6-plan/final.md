# Phase 6 Plan — ceos-agents v6.8.0

**Generated:** 2026-04-17
**Persona:** Delivery-Focused Release Manager
**Source of truth:** `.forge/phase-4-spec/final/{design.md, requirements.md, formal-criteria.md}` (Revision 2)
**Test suite:** `.forge/phase-5-tdd/tests/` (36 files) + `.forge/phase-5-tdd/tests-hidden/` (5 files)
**Target:** v6.7.2 → v6.8.0 MINOR release — Autopilot skill + Observability Hooks + Real-Time Cost Visibility

---

## Summary

- **Total tasks:** 24 (T01..T24)
- **Critical path length:** 8 serial steps (T01 → T03 → T05 → T06 → T20 → T21 → T22 → T23)
- **Parallelization waves:** 6 (Wave 0..Wave 5)
- **Wall-clock estimate:**
  - Purely sequential: ~24h (sum of estimated_minutes ≈ 1 425 min)
  - With parallelization (3 workers): ~8–9h (dominated by critical path + tests)
- **Parallelization ratio:** 17 of 24 tasks (≈ 71 %) have at least one concurrent sibling within their wave.
- **AC coverage:** all 38 ACs and all 33 EARS requirements mapped to ≥1 task (verified by `maps_to` audit).
- **Hard-to-size tasks:** T05 (autopilot SKILL.md) sized at the 90 min upper bound; if the lock snippet from design §4.8 needs inline review the task may split into T05a/T05b — noted under *Known Limitations*.

---

## Dependency Graph

```
Wave 0 — Contract Foundations (serial within wave; all downstream waves blocked)
  T01 state/schema.md ─┐
  T02 core/state-manager.md ─┐
  T03 core/post-publish-hook.md ─┼──────────────┐
  T04 core/config-reader.md ─────┘              │
                                                │
Wave 1 — New Autopilot skill                    │
  T05 skills/autopilot/SKILL.md ◀── depends on T03, T04
                                                │
Wave 2 — Pipeline dispatcher updates (parallel) │
  T06 skills/fix-ticket/SKILL.md ◀── T01, T02, T03
  T07 skills/fix-bugs/SKILL.md ◀── T01, T02, T03
  T08 skills/implement-feature/SKILL.md ◀── T01, T02, T03
  T09 skills/scaffold/SKILL.md ◀── T01, T02, T03
                                                │
Wave 3 — Utility skills (parallel with Wave 2)  │
  T10 skills/metrics/SKILL.md ◀── T01
  T11 skills/dashboard/SKILL.md ◀── T01
  T12 skills/workflow-router/SKILL.md ◀── T05
                                                │
Wave 4 — Documentation (parallel, after T05)    │
  T13 CLAUDE.md ◀── T04, T05
  T14 docs/reference/skills.md ◀── T05
  T15 docs/reference/config.md ◀── T04, T05
  T16 docs/reference/pipelines.md ◀── T05
  T17 docs/guides/autopilot.md (NEW) ◀── T05
  T18 Repo-wide stale-count audit ◀── T13, T14
                                                │
Wave 5 — Tests + Release (serial)               │
  T19 Mirror phase-5 tests → tests/scenarios/ ◀── Wave 0–4 complete
  T20 Run ./tests/harness/run-tests.sh ◀── T19
  T21 CHANGELOG.md v6.8.0 entry ◀── T20
  T22 Content + CHANGELOG commit ◀── T21
  T23 /ceos-agents:version-bump skill (separate commit) ◀── T22
  T24 Git tag v6.8.0 (emitted by T23) ◀── T23
```

---

## Task Detail

### T01: Update state/schema.md with per-stage usage fields + pipeline accumulator
- **Files:** `state/schema.md`
- **Depends on:** []
- **Parallelizable with:** [T02, T03, T04]
- **Estimated minutes:** 60
- **Verification:** `.forge/phase-5-tdd/tests/ac-v68-cost-per-stage-fields-in-schema.sh`, `.forge/phase-5-tdd/tests/ac-v68-cost-schema-version-stays-1.0.sh`, `.forge/phase-5-tdd/tests/ac-v68-cost-pipeline-accumulator.sh`
- **Maps to:** COST-R1, COST-R2, COST-R4, COST-R6, COST-R10; AC-14, AC-15, AC-18, AC-37
- **Rollback:** `git checkout -- state/schema.md`
- **Notes:** Append six usage fields (`tokens_used`, `duration_ms`, `tool_uses`, `model`, `started_at`, `completed_at`) to each of the 15 canonical stages; add top-level `pipeline` object (`total_tokens`, `total_duration_ms`, `total_tool_uses`, `summary_table`); preserve `schema_version: "1.0"` verbatim; add `run_id` canonical definition referencing §4.3; add subsection "summary_table: markdown-in-JSON convenience".

### T02: Document per-stage usage write pattern in core/state-manager.md
- **Files:** `core/state-manager.md`
- **Depends on:** [T01]
- **Parallelizable with:** [T03, T04] (runs after T01 finishes so references are consistent)
- **Estimated minutes:** 45
- **Verification:** `.forge/phase-5-tdd/tests/ac-v68-cost-defensive-null.sh`, `.forge/phase-5-tdd/tests/ac-v68-cost-resume-backward-compat.sh`
- **Maps to:** COST-R2, COST-R3, COST-R4, COST-R5, COST-R9; AC-16, AC-17, AC-20
- **Rollback:** `git checkout -- core/state-manager.md`
- **Notes:** Add "Per-stage usage write pattern" subsection — pre-dispatch writes (`started_at`, `model`, `status: in_progress`), defensive read of `result.usage.total_tokens|duration_ms|tool_uses` with 0 fallback, cumulative accumulation rule for fixer_reviewer, backward-compat read tolerance for v6.7.x state.json.

### T03: Add Section 4 "Pipeline lifecycle events" to core/post-publish-hook.md
- **Files:** `core/post-publish-hook.md`
- **Depends on:** []
- **Parallelizable with:** [T01, T02, T04]
- **Estimated minutes:** 60
- **Verification:** `.forge/phase-5-tdd/tests/ac-v68-webhook-post-publish-hook-section4.sh`, `.forge/phase-5-tdd/tests/ac-v68-webhook-existing-events-unchanged.sh`, `.forge/phase-5-tdd/tests/ac-v68-webhook-no-step-skipped.sh`
- **Maps to:** WEBHOOK-R1, WEBHOOK-R2, WEBHOOK-R3, WEBHOOK-R4, WEBHOOK-R5, WEBHOOK-R6, WEBHOOK-R7, WEBHOOK-R8; AC-9, AC-13, AC-33
- **Rollback:** `git checkout -- core/post-publish-hook.md`
- **Notes:** Update Purpose line to exact string `Execute pipeline hooks and fire webhooks at stage boundaries.`; append Section 4 documenting the three new event payload shapes (byte-copy from design §4.3–4.5), fire sites (cross-reference to 4 pipeline skills), strict fire-order rule (state.json commit precedes webhook), and inheritance clause referencing Section 3 transport/failure semantics.

### T04: Add Autopilot parse block (7 keys) to core/config-reader.md
- **Files:** `core/config-reader.md`
- **Depends on:** []
- **Parallelizable with:** [T01, T02, T03]
- **Estimated minutes:** 45
- **Verification:** `.forge/phase-5-tdd/tests/ac-v68-autopilot-config-reader-keys.sh`
- **Maps to:** AUTOPILOT-R6, AUTOPILOT-R10, AUTOPILOT-R11; AC-21
- **Rollback:** `git checkout -- core/config-reader.md`
- **Notes:** Add `### Autopilot` parse block with 7 dot-notation keys (`autopilot.max_issues_per_run=1`, `autopilot.lock_timeout=120`, `autopilot.log_file=.ceos-agents/autopilot.log`, `autopilot.bug_limit=0`, `autopilot.feature_limit=0`, `autopilot.on_error=skip`, `autopilot.dry_run=false`). Notifications parser untouched (substring check unchanged — new event tokens simply appear in `On events` string).

### T05: Create skills/autopilot/SKILL.md (frontmatter + 6 numbered steps + lock logic)
- **Files:** `skills/autopilot/SKILL.md` (NEW)
- **Depends on:** [T03, T04]
- **Parallelizable with:** []
- **Estimated minutes:** 90
- **Verification:** `.forge/phase-5-tdd/tests/ac-v68-autopilot-skill-exists.sh`, `ac-v68-autopilot-lock-mkdir.sh`, `ac-v68-autopilot-trap-exit.sh`, `ac-v68-autopilot-two-query-classification.sh`, `ac-v68-autopilot-warn-feature-absent.sh`, `ac-v68-autopilot-dry-run-shortcircuit.sh`, `ac-v68-autopilot-stale-lock-120min.sh`, `ac-v68-autopilot-owner-json.sh`, `ac-v68-autopilot-mcp-exit3.sh`, `ac-v68-autopilot-on-error-stop.sh`, `ac-v68-autopilot-info-hostname.sh`, `ac-v68-autopilot-feature-limit-warn.sh`
- **Maps to:** AUTOPILOT-R1 through AUTOPILOT-R13; AC-1, AC-2, AC-3, AC-4, AC-5, AC-6, AC-7, AC-8, AC-30, AC-31, AC-32, AC-34, AC-35, AC-36
- **Rollback:** `rm -rf skills/autopilot/` (new directory — safe removal)
- **Notes:** Frontmatter (`name: autopilot`, `description`, `allowed-tools`, `disable-model-invocation: true`, `argument-hint: "[--dry-run]"`). Six steps: (0) config read + Issue-Tracker validation + MCP ping (exit 3 on fail); (1) lock acquisition via `mkdir` with stale-check at 120 min + BusyBox fallback + trap registered AFTER successful mkdir; (2) two-query classification (bug-priority on overlap) + `[WARN]` on absent Feature Workflow or feature_limit>0 without Feature query; (3) dispatch loop via `Skill()` tool; (4) summary append to `.ceos-agents/autopilot.log`; (5) trap-based lock release with pid-match guard. Dry-run full short-circuit before Step 1. Hostname INFO line on every successful lock acquisition per AUTOPILOT-R13. Reuses lock snippet from design.md §4.8 verbatim (portable bash, pure-bash ISO-8601 arithmetic).

### T06: Update skills/fix-ticket/SKILL.md — events + usage capture + summary table
- **Files:** `skills/fix-ticket/SKILL.md`
- **Depends on:** [T01, T02, T03]
- **Parallelizable with:** [T07, T08, T09, T10, T11, T12, T13, T14, T15, T16, T17]
- **Estimated minutes:** 75
- **Verification:** `.forge/phase-5-tdd/tests/ac-v68-webhook-payload-fields.sh`, `ac-v68-webhook-advisory-failure.sh`, `ac-v68-webhook-no-per-iteration.sh`, `ac-v68-cost-pipeline-accumulator.sh`, `ac-v68-cost-summary-truncation.sh`
- **Maps to:** WEBHOOK-R2, WEBHOOK-R3, WEBHOOK-R4, WEBHOOK-R5, WEBHOOK-R6; COST-R2, COST-R3, COST-R4, COST-R5, COST-R6, COST-R10; AC-10, AC-11, AC-12, AC-17, AC-18, AC-37
- **Rollback:** `git checkout -- skills/fix-ticket/SKILL.md`
- **Notes:** After config validation + state.json init — compute `run_id = "{issue_id}_{YYYYMMDDTHHMMSSZ}"`; fire `pipeline-started` webhook AFTER state init commits. Around every top-level stage (triage, code_analysis, reproduction, fixer_reviewer loop, test, e2e_test, browser_verification, acceptance_gate, publisher): write pre-dispatch fields (model, started_at, status=in_progress); capture `result.usage`; write 6 usage fields; commit state atomically; on successful commit fire `step-completed` webhook. At terminal state: compute `pipeline.*` accumulator (apply COST-R10 truncation), commit, fire `pipeline-completed`. Echo `pipeline.summary_table` to stdout at end.

### T07: Update skills/fix-bugs/SKILL.md — per-issue event + usage pattern
- **Files:** `skills/fix-bugs/SKILL.md`
- **Depends on:** [T01, T02, T03]
- **Parallelizable with:** [T06, T08, T09, T10, T11, T12, T13, T14, T15, T16, T17]
- **Estimated minutes:** 60
- **Verification:** `.forge/phase-5-tdd/tests/ac-v68-webhook-no-per-iteration.sh`, `ac-v68-webhook-no-step-skipped.sh`
- **Maps to:** WEBHOOK-R2, WEBHOOK-R3, WEBHOOK-R4, WEBHOOK-R5, WEBHOOK-R6, WEBHOOK-R7; COST-R2..R6, R10; AC-10, AC-11, AC-12, AC-33
- **Rollback:** `git checkout -- skills/fix-bugs/SKILL.md`
- **Notes:** Each batch issue gets its own three events + state.json + accumulator. Stage enum identical to fix-ticket. No batch-level `autopilot-started`/`autopilot-completed` events (NOT_IN_SCOPE §6.3). Kept separate from T06 to allow parallel worktree execution in Phase 7.

### T08: Update skills/implement-feature/SKILL.md — events + usage + feature stage enum
- **Files:** `skills/implement-feature/SKILL.md`
- **Depends on:** [T01, T02, T03]
- **Parallelizable with:** [T06, T07, T09, T10, T11, T12, T13, T14, T15, T16, T17]
- **Estimated minutes:** 75
- **Verification:** `.forge/phase-5-tdd/tests/ac-v68-webhook-payload-fields.sh`, `ac-v68-cost-pipeline-accumulator.sh`
- **Maps to:** WEBHOOK-R2..R6; COST-R2..R6, R10; AC-10, AC-18
- **Rollback:** `git checkout -- skills/implement-feature/SKILL.md`
- **Notes:** Same pattern as T06. Feature-specific stage enum adds `spec_analysis`, `architect` before the fixer_reviewer loop. `pipeline` field in payload is `"implement-feature"`.

### T09: Update skills/scaffold/SKILL.md — events + usage + scaffold stage enum
- **Files:** `skills/scaffold/SKILL.md`
- **Depends on:** [T01, T02, T03]
- **Parallelizable with:** [T06, T07, T08, T10, T11, T12, T13, T14, T15, T16, T17]
- **Estimated minutes:** 75
- **Verification:** `.forge/phase-5-tdd/tests/ac-v68-webhook-payload-fields.sh`, `ac-v68-cost-pipeline-accumulator.sh`
- **Maps to:** WEBHOOK-R2..R6; COST-R2..R6, R10; AC-10, AC-18
- **Rollback:** `git checkout -- skills/scaffold/SKILL.md`
- **Notes:** Scaffold stage enum adds `spec_writer`, `spec_reviewer`, `scaffolder` before the feature stages when implementation runs. `pipeline` field is `"scaffold"`.

### T10: Update skills/metrics/SKILL.md — state.json-read mode with dual output
- **Files:** `skills/metrics/SKILL.md`
- **Depends on:** [T01]
- **Parallelizable with:** [T06, T07, T08, T09, T11, T12, T13, T14, T15, T16, T17]
- **Estimated minutes:** 60
- **Verification:** `.forge/phase-5-tdd/tests/ac-v68-cost-metrics-dual-mode.sh`
- **Maps to:** COST-R7, COST-R8, COST-R11; AC-19
- **Rollback:** `git checkout -- skills/metrics/SKILL.md`
- **Notes:** Insert new Step 3b "Read state.json per issue" — glob `.ceos-agents/*/state.json`, classify each issue as MEASURED (if `pipeline.total_tokens` exists) or ESTIMATED (else apply heuristic constants sonnet ~30k / opus ~50k / haiku ~5k). Emit per-pipeline rows with two SEPARATE line items (measured + estimated) + provenance footer `Data source: measured={X} issues, estimated={Y} issues`. Hybrid (partial stages measured) is reported at pipeline level as ESTIMATED with per-stage breakdown. NO `--format json` change.

### T11: Update skills/dashboard/SKILL.md — compact per-issue usage column
- **Files:** `skills/dashboard/SKILL.md`
- **Depends on:** [T01]
- **Parallelizable with:** [T06, T07, T08, T09, T10, T12, T13, T14, T15, T16, T17]
- **Estimated minutes:** 30
- **Verification:** Manual grep `grep -nE "total_tokens" skills/dashboard/SKILL.md`
- **Maps to:** COST-R6 (display projection)
- **Rollback:** `git checkout -- skills/dashboard/SKILL.md`
- **Notes:** If `pipeline.total_tokens` is present in any state.json globbed, render one compact row per issue: `{run_id} | {status} | {total_tokens} tok | {duration_ms/1000}s`. Otherwise no change. Non-structural; presentation only. If trivial change proves non-trivial on inspection, defer per design §3.4 and leave a roadmap note (SKIP-WITH-NOTE).

### T12: Update skills/workflow-router/SKILL.md — Autopilot intent rows
- **Files:** `skills/workflow-router/SKILL.md`
- **Depends on:** [T05]
- **Parallelizable with:** [T06..T11, T13..T17]
- **Estimated minutes:** 30
- **Verification:** Manual grep `grep -nE "autopilot|headless|batch fix|nightly run|cron dispatch|automate tracker" skills/workflow-router/SKILL.md`
- **Maps to:** AUTOPILOT-R1 (discoverability)
- **Rollback:** `git checkout -- skills/workflow-router/SKILL.md`
- **Notes:** Add intent-matching rows mapping "run all bugs", "headless mode", "batch fix", "nightly run", "cron dispatch", "automate tracker" → `/ceos-agents:autopilot`. Bump intent row count in the header stat line if tracked (31 rows → 37 rows).

### T13: Update CLAUDE.md — Autopilot optional section + skill count + events enum
- **Files:** `CLAUDE.md`
- **Depends on:** [T04, T05]
- **Parallelizable with:** [T06..T12, T14, T15, T16, T17]
- **Estimated minutes:** 60
- **Verification:** `.forge/phase-5-tdd/tests/ac-v68-autopilot-config-keys.sh`, `ac-v68-doc-optional-sections-18.sh`, `ac-v68-doc-skill-count-29.sh`, `ac-v68-webhook-three-events-documented.sh`, `ac-v68-webhook-advisory-failure.sh` (forward-compat paragraph check)
- **Maps to:** AUTOPILOT-R1, AUTOPILOT-R6, AUTOPILOT-R10, AUTOPILOT-R11; WEBHOOK-R2, WEBHOOK-R3, WEBHOOK-R4, WEBHOOK-R5; AC-21, AC-22, AC-23, AC-25, AC-26
- **Rollback:** `git checkout -- CLAUDE.md`
- **Notes:** (a) Skill count 28 → 29 in architecture section + summary table. (b) Add `/autopilot` to skills list. (c) Optional-sections count 17 → 18 + new row verbatim per design §4.7. (d) Extend Notifications `On events` enumeration with `pipeline-started, step-completed, pipeline-completed`. (e) Add forward-compat paragraph. (f) Add operator-trust note for Webhook URL.

### T14: Update docs/reference/skills.md — /autopilot row + count bump
- **Files:** `docs/reference/skills.md`
- **Depends on:** [T05]
- **Parallelizable with:** [T06..T13, T15, T16, T17]
- **Estimated minutes:** 30
- **Verification:** `.forge/phase-5-tdd/tests/ac-v68-doc-autopilot-in-skills-ref.sh`, `ac-v68-doc-skill-count-29.sh`
- **Maps to:** AUTOPILOT-R1; AC-23, AC-24
- **Rollback:** `git checkout -- docs/reference/skills.md`
- **Notes:** Add `| /autopilot | <description> | N/A (dispatcher) | [--dry-run] |` row. Bump skill count in summary table 28 → 29.

### T15: Update docs/reference/config.md — Autopilot section + Notifications tokens
- **Files:** `docs/reference/config.md`
- **Depends on:** [T04, T05]
- **Parallelizable with:** [T06..T14, T16, T17]
- **Estimated minutes:** 45
- **Verification:** `.forge/phase-5-tdd/tests/ac-v68-webhook-three-events-documented.sh`; manual `grep -nE "Max issues per run|Lock timeout|Log file|Bug limit|Feature limit|On error|Dry run" docs/reference/config.md`
- **Maps to:** AUTOPILOT-R6, AUTOPILOT-R10, AUTOPILOT-R11; WEBHOOK-R2..R5; AC-21, AC-25
- **Rollback:** `git checkout -- docs/reference/config.md`
- **Notes:** Document `### Autopilot` with 7-key types/defaults/semantics table (mirrors design §4.7). Update Notifications `On events` enum. Add operator-trust note for Webhook URL.

### T16: Update docs/reference/pipelines.md — Autopilot dispatcher subsection
- **Files:** `docs/reference/pipelines.md`
- **Depends on:** [T05]
- **Parallelizable with:** [T06..T15, T17]
- **Estimated minutes:** 45
- **Verification:** Manual `grep -nE "Autopilot" docs/reference/pipelines.md`; cross-link to docs/guides/autopilot.md
- **Maps to:** AUTOPILOT-R1, AUTOPILOT-R2
- **Rollback:** `git checkout -- docs/reference/pipelines.md`
- **Notes:** New subsection "Autopilot pipeline dispatcher" — describe the query → classify → per-issue dispatch pattern, cite mkdir lock mechanism, link to operator guide.

### T17: NEW docs/guides/autopilot.md — operator guide
- **Files:** `docs/guides/autopilot.md` (NEW)
- **Depends on:** [T05]
- **Parallelizable with:** [T06..T16]
- **Estimated minutes:** 75
- **Verification:** `.forge/phase-5-tdd/tests/ac-v68-autopilot-info-hostname.sh` (asserts `single-host-operation` anchor exists)
- **Maps to:** AUTOPILOT-R2, AUTOPILOT-R3, AUTOPILOT-R4, AUTOPILOT-R11, AUTOPILOT-R12, AUTOPILOT-R13; AC-36
- **Rollback:** `rm -f docs/guides/autopilot.md`
- **Notes:** ≤160 lines. Cron invocation example; lock-file location + stale recovery; `## Single-Host Operation` subsection with WARNING block + disjoint-query guidance; `## Platform Support` subsection (BusyBox ≥ 1.30 / bash ≥ 4.0 / modern awk); log file format; dry-run example; troubleshooting matrix (exit codes 2/3/4); operator-responsibility note for Webhook URL; advisory concurrent-run note.

### T18: Repo-wide stale-count audit
- **Files:** Any file containing `28 skills` or `17 optional` (to be discovered)
- **Depends on:** [T13, T14]
- **Parallelizable with:** [T06..T12, T15, T16, T17] (safe to run after T13/T14 commit content; catches stragglers)
- **Estimated minutes:** 30
- **Verification:** Command: `grep -rn "28 skills\|17 optional\|28 total" . | grep -v "\.git\|\.forge\.bak\|CHANGELOG\.md"` must return zero matches
- **Maps to:** AUTOPILOT-R1; AC-22, AC-23
- **Rollback:** `git checkout -- {any file touched}`
- **Notes:** Per user memory feedback_doc_completeness — audit ALL doc files (README.md, docs/reference/*, docs/guides/*, examples/*, plans/*). CHANGELOG.md retains historical mentions (excluded). Each stale instance replaced with `29 skills` / `18 optional`.

### T19: Mirror Phase 5 tests to tests/scenarios/
- **Files:** `tests/scenarios/*.sh` (20 scenario files) + `tests/harness/*.sh` invocation if needed
- **Depends on:** [T01..T18]
- **Parallelizable with:** []
- **Estimated minutes:** 30
- **Verification:** `ls tests/scenarios/ | wc -l` ≥ existing baseline + 20; `ls tests/scenarios/cost-*.sh tests/scenarios/autopilot-*.sh tests/scenarios/webhook-*.sh metrics-dual-mode.sh`
- **Maps to:** all (tests are the verification contract)
- **Rollback:** `git checkout -- tests/scenarios/`
- **Notes:** Copy `.forge/phase-5-tdd/tests/*.sh` and `.forge/phase-5-tdd/tests-hidden/*.sh` to `tests/scenarios/` (harness auto-discovers). Per-Phase-5-artifact this MAY already be done — re-verify presence. If already present, task is a no-op (≤5 min).

### T20: Run ./tests/harness/run-tests.sh — must pass fully
- **Files:** (no file changes — gate only)
- **Depends on:** [T19]
- **Parallelizable with:** []
- **Estimated minutes:** 30
- **Verification:** `./tests/harness/run-tests.sh` exits 0; final line contains `Tests passed`; zero `FAIL` lines in output.
- **Maps to:** AC-29 (all tests pass)
- **Rollback:** If tests fail, loop back to the failing task (typical: T05, T06–T09, T13, T17) — diagnose with scenario-level output; re-run after fix.
- **Notes:** Per user memory Version-Release-Process — ALWAYS run harness before commit. This is the MINOR-release gate. Any RED test from Phase 5 must now be GREEN; any GREEN test (negative/regression) must remain GREEN.

### T21: Add CHANGELOG.md v6.8.0 entry
- **Files:** `CHANGELOG.md`
- **Depends on:** [T20]
- **Parallelizable with:** []
- **Estimated minutes:** 45
- **Verification:** `.forge/phase-5-tdd/tests/ac-v68-doc-changelog-entry.sh`
- **Maps to:** all; AC-28
- **Rollback:** `git checkout -- CHANGELOG.md`
- **Notes:** Add `## [6.8.0] — 2026-04-17` with four subsections per design §3.6: `### Added`, `### Changed`, `### Known Issues`, `### Migration notes`. Classify MINOR. Mirror style of recent v6.7.2 entry.

### T22: Content + CHANGELOG commit (ONE commit)
- **Files:** (commit only — aggregates T01–T21 file changes)
- **Depends on:** [T21]
- **Parallelizable with:** []
- **Estimated minutes:** 15
- **Verification:** `git log -1 --stat | head -60` shows all changed files including CHANGELOG.md; `git status` clean afterwards.
- **Maps to:** all
- **Rollback:** `git reset --soft HEAD~1` (preserves files) or `git revert HEAD` (creates inverse commit — preferred for shared branches).
- **Notes:** Single commit per user memory "Version Release Process" — content + changelog go together. Commit message follows conventional-commit style: `feat: v6.8.0 — Autopilot + Observability Hooks + Real-Time Cost Visibility`. Explicitly EXCLUDE `.claude/settings.local.json` from staging (user memory constraint). Explicitly EXCLUDE `.forge.bak-*/` backup dirs.

### T23: Invoke /ceos-agents:version-bump skill (SEPARATE commit)
- **Files:** `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json` (both bumped 6.7.2 → 6.8.0 by the skill)
- **Depends on:** [T22]
- **Parallelizable with:** []
- **Estimated minutes:** 15
- **Verification:** `.forge/phase-5-tdd/tests/ac-v68-doc-version-6.8.0.sh`; `grep -n '"version": "6.8.0"' .claude-plugin/plugin.json .claude-plugin/marketplace.json` returns 2 matches; `git log -1 --oneline` shows version-bump commit.
- **Maps to:** all; AC-27
- **Rollback:** `git reset --soft HEAD~1` then manually revert the two JSON files; or `git revert HEAD`.
- **Notes:** Per user memory feedback_version_bump_skill — NEVER do manual version bump + tag. The skill updates both manifests, creates the commit, AND emits the tag (T24). Invoke via `Skill(ceos-agents:version-bump)` with argument `6.8.0`.

### T24: Git tag v6.8.0 (emitted by version-bump skill in T23)
- **Files:** (git ref only)
- **Depends on:** [T23]
- **Parallelizable with:** []
- **Estimated minutes:** 5
- **Verification:** `git tag -l | grep -x "v6.8.0"` returns `v6.8.0`; `git show v6.8.0 --stat` prints commit details.
- **Maps to:** all
- **Rollback:** `git tag -d v6.8.0` (local only); if pushed, `git push origin :refs/tags/v6.8.0` (destructive — requires explicit confirmation).
- **Notes:** Tag is created by the version-bump skill as part of T23; T24 exists as an explicit plan checkpoint so that if the skill's tag step fails, the failure is attributable. If skill succeeded T23 but skipped tagging, run `git tag -a v6.8.0 -m "v6.8.0"` manually. DO NOT push to remote — user controls push.

---

## Critical Path

```
T01  → T03  → T05  → T06  → T20  → T21  → T22  → T23  (→ T24)
60m    60m    90m    75m    30m    45m    15m    15m      5m
```

**Total critical path:** 8 serial tasks (9 with T24 tag step), ≈ 395 minutes (~6.6 h).

Rationale for path selection:
- T01 must precede T02 (schema doc is referenced from state-manager doc).
- T03 gates T05 (autopilot dispatches use Section 4 event documentation).
- T05 gates T06 (fix-ticket imports the autopilot lock snippet conceptually; also it's the heaviest pipeline skill edit).
- T06 gates T20 (pipeline-events tests depend on fix-ticket wiring).
- T20 is the hard gate before CHANGELOG/version commits.
- T21–T24 are serial by release-process convention (memory: feedback_version_bump_skill).

Other long tasks (T02, T07, T08, T09, T11, T13, T14, T15, T16, T17, T18, T19) run in parallel waves and do NOT extend the critical path under a 3-worker execution model.

---

## Parallelization Waves

| Wave | Tasks | Count | Concurrency | Wall-Clock (3 workers) |
|---|---|---|---|---|
| 0 — Contracts | T01, T02, T03, T04 | 4 | T01↔T03↔T04 parallel; T02 after T01 | ~60 min (max of T01/T03, then T02) |
| 1 — Autopilot skill | T05 | 1 | serial | ~90 min |
| 2 — Pipeline dispatchers | T06, T07, T08, T09 | 4 | fully parallel | ~75 min |
| 3 — Utility skills | T10, T11, T12 | 3 | fully parallel | ~60 min (T10 longest) |
| 4 — Documentation | T13, T14, T15, T16, T17, T18 | 6 | parallel; T18 last | ~75 min (T17 longest) |
| 5 — Tests + Release | T19, T20, T21, T22, T23, T24 | 6 | serial | ~140 min |

**Wave overlap:** Waves 2, 3, and 4 all depend on Wave 0/1 and are mutually independent — they can run in the same wall-clock window on three workers, compressing 60 + 60 + 75 min into one 75-min block.

**Effective wall-clock (3-worker pool):**
```
Wave 0  ~ 60 min
Wave 1  ~ 90 min
Waves 2/3/4 concurrent ~ 75 min
Wave 5  ~ 140 min
TOTAL   ~ 365 min ≈ 6 h 5 min
```

---

## Rollback Plan

| Task | Rollback command | Destructive? |
|---|---|---|
| T01 | `git checkout -- state/schema.md` | No |
| T02 | `git checkout -- core/state-manager.md` | No |
| T03 | `git checkout -- core/post-publish-hook.md` | No |
| T04 | `git checkout -- core/config-reader.md` | No |
| T05 | `rm -rf skills/autopilot/` | Only new file |
| T06 | `git checkout -- skills/fix-ticket/SKILL.md` | No |
| T07 | `git checkout -- skills/fix-bugs/SKILL.md` | No |
| T08 | `git checkout -- skills/implement-feature/SKILL.md` | No |
| T09 | `git checkout -- skills/scaffold/SKILL.md` | No |
| T10 | `git checkout -- skills/metrics/SKILL.md` | No |
| T11 | `git checkout -- skills/dashboard/SKILL.md` | No |
| T12 | `git checkout -- skills/workflow-router/SKILL.md` | No |
| T13 | `git checkout -- CLAUDE.md` | No |
| T14 | `git checkout -- docs/reference/skills.md` | No |
| T15 | `git checkout -- docs/reference/config.md` | No |
| T16 | `git checkout -- docs/reference/pipelines.md` | No |
| T17 | `rm -f docs/guides/autopilot.md` | Only new file |
| T18 | `git checkout -- <files discovered by audit>` | No |
| T19 | `git checkout -- tests/scenarios/` | No |
| T20 | Re-run failing task; re-execute harness | No — gate only |
| T21 | `git checkout -- CHANGELOG.md` | No |
| T22 | `git revert HEAD` (preferred) or `git reset --soft HEAD~1` | Only `reset --hard` is destructive; not used |
| T23 | `git revert HEAD` + manual re-edit of plugin.json/marketplace.json | `reset --soft` safe |
| T24 | `git tag -d v6.8.0` (local); push-deletion requires explicit user consent | Destructive only on remote |

**Schema-file note (T01):** state/schema.md is documentation, not live state.json. No state-file migration is required — readers (state-manager, resume-ticket) are additive/permissive per COST-R9. Rollback is a pure `git checkout`.

---

## Known Limitations

1. **T05 at the upper bound (90 min).** If the lock snippet (design §4.8) needs per-line review during implementation, T05 may split into T05a (frontmatter + Steps 0, 2, 3, 4) and T05b (lock acquisition + trap — Steps 1, 5). Phase 7 executor may perform this split without violating the plan.
2. **T11 (dashboard) is marked "trivial else defer".** Design §3.4 allows skipping if the presentation change proves non-trivial. If skipped, T11 becomes a roadmap note; AC coverage is unaffected (no AC depends on dashboard changes).
3. **T18 (stale-count audit) has undefined file count.** Discovered by `grep -rn` at execution time. Typical hit set is ≤6 files (README.md, docs/reference/*, docs/guides/*). If the audit finds >10 files to update, T18 may escalate beyond 30 min — in which case split into T18a (docs/reference/ + docs/guides/) and T18b (README.md + examples/ + remaining).
4. **T19 MAY be a no-op.** If Phase 5 artifacts are already mirrored in `tests/scenarios/`, T19 is a 5-min verification only. Re-check per invocation.
5. **Gate sequence T20→T21→T22→T23→T24 is non-parallelizable.** No optimization available; this is the release-process floor and is sourced from user memory.
6. **No spec AC is orphaned.** All 38 ACs map to ≥1 task via the `verification` and `maps_to` fields. All 33 EARS requirements map to ≥1 task.
