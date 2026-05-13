# Phase 5 TDD — ceos-agents v6.8.0 Test Suite

Generated: 2026-04-17. All tests follow the `ac-v68-{category}-{aspect}.sh` naming convention.

## Test Categories

### Autopilot Tests (12 tests)

| File | AC | Status | Description |
|---|---|---|---|
| `ac-v68-autopilot-skill-exists.sh` | AC-1 | RED until Phase 7 | Frontmatter: name, disable-model-invocation, argument-hint |
| `ac-v68-autopilot-lock-mkdir.sh` | AC-30 | RED until Phase 7 | Lock is a DIRECTORY (mkdir), not a file |
| `ac-v68-autopilot-trap-exit.sh` | AC-5 | RED until Phase 7 | trap ... EXIT registered after successful mkdir |
| `ac-v68-autopilot-config-keys.sh` | AC-21 | RED until Phase 7 | CLAUDE.md has all 7 Autopilot config keys |
| `ac-v68-autopilot-two-query-classification.sh` | AC-6 | RED until Phase 7 | Bug + Feature Skill-tool dispatch documented |
| `ac-v68-autopilot-warn-feature-absent.sh` | AC-7 | RED until Phase 7 | [WARN] Feature Workflow section absent |
| `ac-v68-autopilot-dry-run-shortcircuit.sh` | AC-8 | RED until Phase 7 | [DRY RUN] full short-circuit |
| `ac-v68-autopilot-stale-lock-120min.sh` | AC-4 | RED until Phase 7 | 120-min stale threshold + re-acquire |
| `ac-v68-autopilot-owner-json.sh` | AC-2 | RED until Phase 7 | owner.json with pid, hostname, acquired_at |
| `ac-v68-autopilot-mcp-exit3.sh` | AC-32 | RED until Phase 7 | MCP fail → exit 3, no lock |
| `ac-v68-autopilot-on-error-stop.sh` | AC-35 | RED until Phase 7 | On error: stop breaks loop |
| `ac-v68-autopilot-info-hostname.sh` | AC-36 | RED until Phase 7 | INFO line + single-host-operation guide |
| `ac-v68-autopilot-feature-limit-warn.sh` | AC-31 | RED until Phase 7 | Feature limit > 0 + no Feature query WARN |
| `ac-v68-autopilot-config-reader-keys.sh` | AC-21 | RED until Phase 7 | core/config-reader.md 7 Autopilot keys |

### Webhook Tests (7 tests)

| File | AC | Status | Description |
|---|---|---|---|
| `ac-v68-webhook-post-publish-hook-section4.sh` | AC-9 | RED until Phase 7 | Section 4 + updated Purpose |
| `ac-v68-webhook-three-events-documented.sh` | AC-25 | RED until Phase 7 | All 3 event tokens in CLAUDE.md/config.md |
| `ac-v68-webhook-payload-fields.sh` | AC-10 | RED until Phase 7 | Payload fields + compact run_id |
| `ac-v68-webhook-advisory-failure.sh` | AC-11/AC-26 | RED until Phase 7 | Advisory + forward-compat paragraph |
| `ac-v68-webhook-no-per-iteration.sh` | AC-12 | GREEN (negative check) | No per-iteration step-completed language |
| `ac-v68-webhook-no-step-skipped.sh` | AC-33 | GREEN (negative check) | No step-skipped in pipeline skills |
| `ac-v68-webhook-existing-events-unchanged.sh` | AC-13 | GREEN (regression guard) | pr-created and issue-blocked fields present |

### Cost Visibility Tests (9 tests)

| File | AC | Status | Description |
|---|---|---|---|
| `ac-v68-cost-schema-version-stays-1.0.sh` | AC-14 | GREEN (exists in v6.7.2) | schema_version = "1.0" not bumped |
| `ac-v68-cost-per-stage-fields-in-schema.sh` | AC-15 | RED until Phase 7 | 6 usage fields in state/schema.md |
| `ac-v68-cost-pipeline-accumulator.sh` | AC-18 | RED until Phase 7 | pipeline.{total_tokens, etc} + summary_table |
| `ac-v68-cost-fixer-reviewer-cumulative.sh` | AC-17 | GREEN (negative check) | No per-iteration breakdown array |
| `ac-v68-cost-defensive-null.sh` | AC-16 | RED until Phase 7 | Defensive 0 fallback in state-manager.md |
| `ac-v68-cost-metrics-dual-mode.sh` | AC-19 | RED until Phase 7 | Measured vs estimated separation |
| `ac-v68-cost-resume-backward-compat.sh` | AC-20 | RED until Phase 7 | resume-ticket tolerates v6.7.x state |
| `ac-v68-cost-summary-truncation.sh` | AC-37 | RED until Phase 7 | ≤20 rows, ≤4000 chars truncation rule |
| `ac-v68-cost-task-tool-usage-field-discovery.sh` | AC-38 | RED until Phase 7 | Discovery file exists + structure |

### Documentation / Version Tests (5 tests)

| File | AC | Status | Description |
|---|---|---|---|
| `ac-v68-doc-optional-sections-18.sh` | AC-22 | RED until Phase 7 | 18 optional sections in CLAUDE.md |
| `ac-v68-doc-skill-count-29.sh` | AC-23 | RED until Phase 7 | 29 skills in CLAUDE.md + skills.md |
| `ac-v68-doc-autopilot-in-skills-ref.sh` | AC-24 | RED until Phase 7 | /autopilot row in skills.md |
| `ac-v68-doc-version-6.8.0.sh` | AC-27 | RED until Phase 7 | plugin.json + marketplace.json = 6.8.0 |
| `ac-v68-doc-changelog-entry.sh` | AC-28 | RED until Phase 7 | CHANGELOG.md v6.8.0 entry complete |

## Tests Expected to FAIL Until Phase 7 (TDD Red Phase)

The following tests are INTENTIONALLY FAILING. This is correct TDD behavior — they define the target state that Phase 7 implementation must achieve.

**Autopilot (all 13 + config-reader):** Files that depend on `skills/autopilot/SKILL.md` (NEW), `docs/guides/autopilot.md` (NEW), and updates to `CLAUDE.md`, `core/config-reader.md`.

**Webhook (4):** Files that depend on `core/post-publish-hook.md` being extended with Section 4.

**Cost (8 — except schema_version and negative checks):** Files that depend on `state/schema.md` being extended with 6 usage fields + pipeline accumulator, `core/state-manager.md` being updated, `skills/metrics/SKILL.md` being updated.

**Docs/Version (5):** Files that depend on `CLAUDE.md` being updated, `docs/reference/skills.md` being updated, `CHANGELOG.md` being written, `plugin.json`/`marketplace.json` being bumped.

### Currently Green (pre-Phase 7)

These tests pass TODAY and must remain green after Phase 7:

- `ac-v68-webhook-no-per-iteration.sh` — negative check, passes if no per-iteration language
- `ac-v68-webhook-no-step-skipped.sh` — negative check, passes if step-skipped is absent
- `ac-v68-webhook-existing-events-unchanged.sh` — regression guard, pr-created exists in v6.7.2
- `ac-v68-cost-schema-version-stays-1.0.sh` — schema_version is already "1.0"
- `ac-v68-cost-fixer-reviewer-cumulative.sh` — negative check

## Scenario Files (in tests/scenarios/)

These files are referenced by AC verify commands in `formal-criteria.md`:

| File | AC | Status |
|---|---|---|
| `autopilot-lock-acquire.sh` | AC-2, AC-36 | RED until Phase 7 |
| `autopilot-lock-held.sh` | AC-3 | RED until Phase 7 |
| `autopilot-lock-stale.sh` | AC-4 | RED until Phase 7 |
| `autopilot-lock-stale-awk-missing.sh` | AC-4 | RED until Phase 7 |
| `autopilot-feature-workflow-absent.sh` | AC-7 | RED until Phase 7 |
| `autopilot-feature-limit-no-query.sh` | AC-31 | RED until Phase 7 |
| `autopilot-dry-run.sh` | AC-8 | RED until Phase 7 |
| `autopilot-trap-cleanup.sh` | AC-34 | RED until Phase 7 |
| `autopilot-mcp-unreachable.sh` | AC-32 | RED until Phase 7 |
| `autopilot-on-error-stop.sh` | AC-35 | RED until Phase 7 |
| `webhook-pipeline-events.sh` | AC-10 | RED until Phase 7 |
| `webhook-advisory-failure.sh` | AC-11 | RED until Phase 7 |
| `webhook-no-step-skipped.sh` | AC-33 | GREEN now |
| `cost-state-fields.sh` | AC-15 | RED until Phase 7 |
| `cost-usage-null-defensive.sh` | AC-16 | RED until Phase 7 |
| `cost-pipeline-accumulator.sh` | AC-18 | RED until Phase 7 |
| `cost-summary-truncation.sh` | AC-37 | RED until Phase 7 |
| `cost-resume-v6.7-state.sh` | AC-20 | RED until Phase 7 |
| `metrics-dual-mode.sh` | AC-19 | RED until Phase 7 |
| `cost-task-tool-usage-field-discovery.sh` | AC-38 | RED until Phase 7 |

## Hidden Regression Tests (in tests-hidden/)

| File | Description |
|---|---|
| `regression-no-breaking-config-changes.sh` | Autopilot section is optional (all keys have defaults) |
| `regression-existing-events-preserved.sh` | pr-created and issue-blocked events still referenced |
| `regression-skill-count-29.sh` | skills/ has exactly 29 subdirectories after autopilot/ added |
| `regression-no-content-loss.sh` | Sentinel lines from v6.7.2 present in modified files |
| `regression-gate-1-decisions.sh` | tokens_used, schema 1.0, no pipeline-events.md, mkdir lock, no step-skipped |

## EARS Coverage

All 33 EARS requirements have ≥1 test:

- AUTOPILOT-R1: ac-v68-autopilot-skill-exists, ac-v68-doc-skill-count-29, ac-v68-doc-optional-sections-18, ac-v68-doc-autopilot-in-skills-ref
- AUTOPILOT-R2: ac-v68-autopilot-lock-mkdir, ac-v68-autopilot-owner-json, autopilot-lock-acquire
- AUTOPILOT-R3: autopilot-lock-held
- AUTOPILOT-R4: ac-v68-autopilot-stale-lock-120min, autopilot-lock-stale, autopilot-lock-stale-awk-missing
- AUTOPILOT-R5: ac-v68-autopilot-trap-exit, autopilot-trap-cleanup
- AUTOPILOT-R6: ac-v68-autopilot-two-query-classification, ac-v68-autopilot-config-reader-keys
- AUTOPILOT-R7: ac-v68-autopilot-warn-feature-absent, autopilot-feature-workflow-absent
- AUTOPILOT-R8: ac-v68-autopilot-feature-limit-warn, autopilot-feature-limit-no-query
- AUTOPILOT-R9: ac-v68-autopilot-two-query-classification
- AUTOPILOT-R10: ac-v68-autopilot-on-error-stop, autopilot-on-error-stop
- AUTOPILOT-R11: ac-v68-autopilot-dry-run-shortcircuit, autopilot-dry-run
- AUTOPILOT-R12: ac-v68-autopilot-mcp-exit3, autopilot-mcp-unreachable
- AUTOPILOT-R13: ac-v68-autopilot-info-hostname
- WEBHOOK-R1: ac-v68-webhook-post-publish-hook-section4
- WEBHOOK-R2: ac-v68-webhook-three-events-documented, ac-v68-webhook-payload-fields, webhook-pipeline-events
- WEBHOOK-R3: ac-v68-webhook-payload-fields, webhook-pipeline-events
- WEBHOOK-R4: ac-v68-webhook-payload-fields, webhook-pipeline-events
- WEBHOOK-R5: ac-v68-webhook-advisory-failure, webhook-advisory-failure
- WEBHOOK-R6: ac-v68-webhook-no-per-iteration
- WEBHOOK-R7: ac-v68-webhook-no-step-skipped, webhook-no-step-skipped
- WEBHOOK-R8: ac-v68-webhook-existing-events-unchanged, regression-existing-events-preserved
- COST-R1: ac-v68-cost-schema-version-stays-1.0
- COST-R2: ac-v68-cost-per-stage-fields-in-schema, cost-state-fields, ac-v68-cost-task-tool-usage-field-discovery
- COST-R3: ac-v68-cost-defensive-null, cost-usage-null-defensive
- COST-R4: ac-v68-cost-per-stage-fields-in-schema, cost-state-fields
- COST-R5: ac-v68-cost-fixer-reviewer-cumulative
- COST-R6: ac-v68-cost-pipeline-accumulator, cost-pipeline-accumulator
- COST-R7: ac-v68-cost-metrics-dual-mode, metrics-dual-mode
- COST-R8: ac-v68-cost-metrics-dual-mode, metrics-dual-mode
- COST-R9: ac-v68-cost-resume-backward-compat, cost-resume-v6.7-state
- COST-R10: ac-v68-cost-summary-truncation, cost-summary-truncation
- COST-R11: ac-v68-cost-metrics-dual-mode, metrics-dual-mode
- COST-R12: ac-v68-cost-task-tool-usage-field-discovery, cost-task-tool-usage-field-discovery
