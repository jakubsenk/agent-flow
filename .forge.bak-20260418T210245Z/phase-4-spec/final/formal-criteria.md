# Phase 4 Spec — ceos-agents v6.8.0 — Formal Acceptance Criteria (Revision 2)

Companion to `requirements.md` and `design.md`. Contains Section 5 only.

Each AC is numbered, traces to ≥1 EARS requirement, includes an exact verification command, and states the expected output. All commands are run from the repo root (`C:/gitea_ceos-agents/`) using forward slashes and bash syntax.

**Revision 1 changes:**
- Fixed `grep -E` alternation: replaced literal `\|` with bare `|` in AC-6, AC-21, AC-22, AC-23, AC-28 (f-quality-1).
- AC-2 now references the real test file `autopilot-lock-acquire.sh` added in design.md §3.7 (f-quality-2).
- AC-5 simplified; new runtime AC-34 for trap behavior (f-quality-8).
- AC-13 rewording + Known-Limitation §8.8 acknowledgment (f-quality-9).
- AC-30 regex simplified (f-quality-18).
- New ACs: AC-31 (AUTOPILOT-R8), AC-32 (AUTOPILOT-R12), AC-33 (WEBHOOK-R7), AC-34 (AUTOPILOT-R5 runtime), AC-35 (AUTOPILOT-R10 stop), AC-36 (AUTOPILOT-R13), AC-37 (COST-R10 truncation), AC-38 (COST-R12 discovery).

**Revision 2 changes (surgical polish):**
- AC-1 grep anchored to exact-line matches (prevents false positives on mentions in comments).
- AC-10 regex updated to compact `run_id` form `^[A-Z]+-[0-9]+_[0-9]{8}T[0-9]{6}Z$` (DA round2-3).
- AC-36 reworded to match AUTOPILOT-R13's new always-on INFO line format; uses a literal apostrophe in the `operator's responsibility` phrase instead of a wildcard (Quality round2 nit).
- AC-38 asserts the structured discovery summary line `DISCOVERED_FIELD={name}` is emitted and recognizes one of the known token-field names (DA round2-4).

---

## Section 5: Acceptance Criteria

**AC-1**: Autopilot skill file exists with correct frontmatter. | **Traces**: AUTOPILOT-R1 | **Verify**: `$ grep -cE '^name: autopilot$' skills/autopilot/SKILL.md && grep -cE '^disable-model-invocation: true$' skills/autopilot/SKILL.md && grep -cE '^argument-hint: "\[--dry-run\]"$' skills/autopilot/SKILL.md` | **Expected**: each grep returns `1` (exactly one anchored match per required frontmatter key).

**AC-2**: Autopilot acquires lock as a directory with owner metadata JSON. | **Traces**: AUTOPILOT-R2 | **Verify**: `$ bash tests/scenarios/autopilot-lock-acquire.sh; echo $?` | **Expected**: `0`; the scenario asserts that during its execution the lock directory contained `owner.json` with `pid`, `hostname`, `acquired_at` keys and that the lock was released cleanly afterwards.

**AC-3**: Autopilot exits 2 when a fresh lock is held. | **Traces**: AUTOPILOT-R3 | **Verify**: `$ bash tests/scenarios/autopilot-lock-held.sh; echo $?` | **Expected**: `2`; stderr or stdout contains `[autopilot][ERROR] Another Autopilot run in progress`; pre-existing lock directory remains present (trap-race regression guard).

**AC-4**: Autopilot recovers from stale lock (>120min). | **Traces**: AUTOPILOT-R4 | **Verify**: `$ bash tests/scenarios/autopilot-lock-stale.sh; echo $?` | **Expected**: `0`; test asserts lock was recreated and dispatch proceeded.

**AC-5**: Autopilot SKILL.md registers `trap ... EXIT` for lock release. | **Traces**: AUTOPILOT-R5 | **Verify**: `$ grep -nE 'trap .*EXIT' skills/autopilot/SKILL.md` | **Expected**: ≥1 match referencing the autopilot.lock path and the EXIT signal. (Runtime verification: AC-34.)

**AC-6**: Autopilot dispatches child skills via Skill tool for bugs and features. | **Traces**: AUTOPILOT-R9 | **Verify**: `$ grep -nE "Skill\s*\(.*(fix-ticket|implement-feature)" skills/autopilot/SKILL.md` | **Expected**: ≥2 matches (one for `fix-ticket`, one for `implement-feature`).

**AC-7**: Autopilot WARNs on absent Feature Workflow and continues. | **Traces**: AUTOPILOT-R7 | **Verify**: `$ bash tests/scenarios/autopilot-feature-workflow-absent.sh` | **Expected**: stdout contains `[autopilot][WARN] Feature Workflow section absent`; exit 0.

**AC-8**: Dry-run is full short-circuit. | **Traces**: AUTOPILOT-R11 | **Verify**: `$ bash tests/scenarios/autopilot-dry-run.sh && test ! -d .ceos-agents/autopilot.lock && ! grep -q "pipeline-started" /tmp/webhook-capture.log 2>/dev/null; echo $?` | **Expected**: `0`.

**AC-9**: `core/post-publish-hook.md` Purpose line updated and Section 4 added. | **Traces**: WEBHOOK-R1 | **Verify**: `$ grep -n "Execute pipeline hooks and fire webhooks at stage boundaries" core/post-publish-hook.md && grep -nE "^## (4|Section 4)\b.*Pipeline lifecycle events" core/post-publish-hook.md` | **Expected**: both greps return ≥1 match.

**AC-10**: Three new webhook events fire with correct payloads and `run_id` is compact `{issue_id}_{YYYYMMDDTHHMMSSZ}`. | **Traces**: WEBHOOK-R2, WEBHOOK-R3, WEBHOOK-R4 | **Verify**: `$ bash tests/scenarios/webhook-pipeline-events.sh` | **Expected**: captured payload log contains all of `"event":"pipeline-started"`, `"event":"step-completed"`, `"event":"pipeline-completed"`; each payload's `run_id` matches the regex `^[A-Z]+-[0-9]+_[0-9]{8}T[0-9]{6}Z$` (no colons, NTFS/URL/shell safe); `pipeline-completed` additionally has an `outcome` field.

**AC-11**: Webhook failure is advisory. | **Traces**: WEBHOOK-R5 | **Verify**: `$ bash tests/scenarios/webhook-advisory-failure.sh; echo $?` | **Expected**: `0`; output contains `[WARN] Webhook delivery failed` and state.json shows terminal status.

**AC-12**: No per-iteration `step-completed` event. | **Traces**: WEBHOOK-R6 | **Verify**: `$ grep -nE "step-completed.*per (fixer|iteration)" skills/fix-ticket/SKILL.md skills/fix-bugs/SKILL.md skills/implement-feature/SKILL.md skills/scaffold/SKILL.md` | **Expected**: no matches.

**AC-13**: Existing `pr-created` and `issue-blocked` payloads unchanged at the grep-context level. | **Traces**: WEBHOOK-R8 | **Verify**: `$ grep -A3 '"event":"pr-created"' core/post-publish-hook.md && grep -A3 '"event":"issue-blocked"' core/block-handler.md` | **Expected**: payload field lists around each event include exactly the v6.7.2 key set — `event, issue_id, pr_url, timestamp` (pr-created) and `event, issue_id, agent, reason, timestamp` (issue-blocked). **Known limitation (§8.8):** this is an indicative regression guard via line-context grep, not a byte-diff contract; fixture-based byte-diff is deferred to v6.9.0.

**AC-14**: `schema_version` stays `"1.0"` in schema doc. | **Traces**: COST-R1 | **Verify**: `$ grep -n '"schema_version": "1.0"' state/schema.md && grep -n 'Always `"1.0"`' state/schema.md` | **Expected**: both return ≥1 match; no `"1.1"` string appears.

**AC-15**: state.json carries six usage fields per completed stage. | **Traces**: COST-R2, COST-R4 | **Verify**: `$ bash tests/scenarios/cost-state-fields.sh` | **Expected**: exit 0; test asserts `triage.tokens_used == 100`, `triage.duration_ms == 1000`, `triage.tool_uses == 2`, `triage.model == "sonnet"`, `triage.started_at` non-null, `triage.completed_at` non-null.

**AC-16**: Defensive read writes zeros when Task usage is null. | **Traces**: COST-R3 | **Verify**: `$ bash tests/scenarios/cost-usage-null-defensive.sh` | **Expected**: exit 0; `jq '.triage.tokens_used' state.json` returns `0`; pipeline reached terminal state.

**AC-17**: Fixer-reviewer accumulates cumulatively with no per-iteration array. | **Traces**: COST-R5 | **Verify**: `$ grep -nE "fixer_reviewer.*(iteration_breakdown|per_iteration|iterations_detail)" skills/fix-ticket/SKILL.md state/schema.md` | **Expected**: no matches (array shape absent).

**AC-18**: `pipeline` accumulator and `summary_table` written at pipeline end. | **Traces**: COST-R6 | **Verify**: `$ bash tests/scenarios/cost-pipeline-accumulator.sh` | **Expected**: exit 0; test asserts `pipeline.total_tokens == sum(per-stage tokens_used)` and `pipeline.summary_table` starts with `"| Stage"`.

**AC-19**: `/metrics` dual-mode aggregation with separate line items + footer. | **Traces**: COST-R7, COST-R8, COST-R11 | **Verify**: `$ bash tests/scenarios/metrics-dual-mode.sh` | **Expected**: stdout contains a measured line and an estimated line as separate items, plus footer `Data source: measured=1 issues, estimated=1 issues`. NO single-line grand total crossing the measured/estimated boundary.

**AC-20**: `/resume-ticket` tolerates v6.7.x state.json. | **Traces**: COST-R9 | **Verify**: `$ bash tests/scenarios/cost-resume-v6.7-state.sh; echo $?` | **Expected**: `0`; no `KeyError`/`undefined` error in output.

**AC-21**: `### Autopilot` section documented in CLAUDE.md with 7 keys. | **Traces**: AUTOPILOT-R6, AUTOPILOT-R10, AUTOPILOT-R11 | **Verify**: `$ grep -cE "Max issues per run|Lock timeout|Log file|Bug limit|Feature limit|On error|Dry run" CLAUDE.md` | **Expected**: output integer `>= 7`.

**AC-22**: Optional sections table bumped 17 → 18. | **Traces**: AUTOPILOT-R1 | **Verify**: `$ grep -nE "(17 optional|18 optional)" CLAUDE.md` | **Expected**: match for `18 optional` present; `17 optional` absent (or replaced in same row).

**AC-23**: Skill count bumped 28 → 29. | **Traces**: AUTOPILOT-R1 | **Verify**: `$ grep -nE "(28 skills|29 skills)" CLAUDE.md docs/reference/skills.md` | **Expected**: `29 skills` present; `28 skills` absent.

**AC-24**: `### Autopilot` row appears in docs/reference/skills.md. | **Traces**: AUTOPILOT-R1 | **Verify**: `$ grep -n "^| /autopilot " docs/reference/skills.md` | **Expected**: exactly 1 match.

**AC-25**: Notifications `On events` enumeration lists three new tokens. | **Traces**: WEBHOOK-R2, WEBHOOK-R3, WEBHOOK-R4 | **Verify**: `$ grep -nE "pipeline-started.*step-completed.*pipeline-completed" CLAUDE.md docs/reference/config.md` | **Expected**: ≥1 match across the two files.

**AC-26**: Forward-compat guarantee paragraph present in CLAUDE.md. | **Traces**: WEBHOOK-R5 | **Verify**: `$ grep -n "Webhook payloads are forward-compatible" CLAUDE.md` | **Expected**: ≥1 match.

**AC-27**: Version bumped to 6.8.0 in plugin and marketplace manifests. | **Traces**: all | **Verify**: `$ grep -n '"version": "6.8.0"' .claude-plugin/plugin.json .claude-plugin/marketplace.json` | **Expected**: 2 matches (one per file).

**AC-28**: CHANGELOG.md contains v6.8.0 entry with the three items. | **Traces**: all | **Verify**: `$ grep -nE "## \[?6\.8\.0\]?" CHANGELOG.md && grep -nE "(Autopilot|Observability|Cost Visibility)" CHANGELOG.md && grep -n "2026-04-17" CHANGELOG.md && grep -n "Migration notes" CHANGELOG.md` | **Expected**: heading `## 6.8.0` (or `## [6.8.0]`) present; all three feature keywords found; date `2026-04-17` present; `Migration notes` subsection present.

**AC-29**: All tests pass. | **Traces**: all | **Verify**: `$ bash tests/harness/run-tests.sh` | **Expected**: exit 0; `Tests passed` in final line; no `FAIL` lines.

**AC-30**: Autopilot lock is a DIRECTORY, not a file (portable `mkdir` semantics). | **Traces**: AUTOPILOT-R2 | **Verify**: `$ grep -nE 'mkdir .*\.ceos-agents/autopilot\.lock' skills/autopilot/SKILL.md` | **Expected**: ≥1 match; no `touch`/`>file` creation of the same path.

**AC-31**: Autopilot WARNs when `Feature limit > 0` but no `Feature query` configured. | **Traces**: AUTOPILOT-R8 | **Verify**: `$ bash tests/scenarios/autopilot-feature-limit-no-query.sh` | **Expected**: exit 0; stdout contains `[autopilot][WARN] Feature limit=5 configured but no Feature query`.

**AC-32**: Autopilot exits 3 with `[STOP] MCP unreachable` to stderr and creates no lock when MCP ping fails. | **Traces**: AUTOPILOT-R12 | **Verify**: `$ bash tests/scenarios/autopilot-mcp-unreachable.sh; echo $?` | **Expected**: `3`; stderr contains `[STOP] MCP unreachable`; `.ceos-agents/autopilot.lock/` does NOT exist after run.

**AC-33**: No `step-skipped` webhook emission site exists in pipeline skills or core. | **Traces**: WEBHOOK-R7 | **Verify**: `$ bash tests/scenarios/webhook-no-step-skipped.sh; echo $?` | **Expected**: `0`; grep for `step-skipped` across 4 pipeline SKILL.md files and `core/post-publish-hook.md` returns zero matches.

**AC-34**: Autopilot lock is released on exit via trap (runtime). | **Traces**: AUTOPILOT-R5 | **Verify**: `$ bash tests/scenarios/autopilot-trap-cleanup.sh; echo $?` | **Expected**: non-zero exit from the skill under test; post-exit `.ceos-agents/autopilot.lock/` is absent.

**AC-35**: Autopilot `On error: stop` breaks dispatch loop after first failure. | **Traces**: AUTOPILOT-R10 | **Verify**: `$ bash tests/scenarios/autopilot-on-error-stop.sh; echo $?` | **Expected**: `0`; scenario asserts dispatch count is exactly 1 when the first issue errored and `On error: stop` is configured.

**AC-36**: Autopilot emits an informational INFO line with the hostname on every successful lock acquisition, pointing operators to the single-host-operation guide. | **Traces**: AUTOPILOT-R13 | **Verify**: `$ bash tests/scenarios/autopilot-lock-acquire.sh 2>&1 | grep -cF "[autopilot][INFO] Running on host"` and `$ grep -nF "single-host-operation" skills/autopilot/SKILL.md docs/guides/autopilot.md` and `$ grep -nF "disjoint bug/feature query" skills/autopilot/SKILL.md docs/guides/autopilot.md` | **Expected**: first grep ≥ 1 (INFO line emitted at runtime); second and third each return ≥1 match per file (documentation pointer + disjoint-query guidance).

**AC-37**: `pipeline.summary_table` truncation rule applied when stage count > 20. | **Traces**: COST-R10 | **Verify**: `$ bash tests/scenarios/cost-summary-truncation.sh; echo $?` | **Expected**: `0`; scenario asserts summary_table has ≤20 stage rows (excluding header and Total) AND the truncation notice row `(truncated, N more stages in pipeline.log)` is present.

**AC-38**: Task-tool usage-field discovery test exists, emits a structured summary, and asserts a known field-name set. | **Traces**: COST-R12 | **Verify**: `$ test -f tests/scenarios/cost-task-tool-usage-field-discovery.sh && grep -n 'result.usage' tests/scenarios/cost-task-tool-usage-field-discovery.sh && grep -nE 'DISCOVERED_FIELD=' tests/scenarios/cost-task-tool-usage-field-discovery.sh && grep -nE '(total_tokens|input_tokens\+output_tokens|tokens_estimated)' tests/scenarios/cost-task-tool-usage-field-discovery.sh` | **Expected**: file exists; grep for `result.usage` returns ≥1 match; grep for `DISCOVERED_FIELD=` returns ≥1 match (structured summary emission); grep for the known field-name set returns ≥1 match (explicit allowlist). The test exits non-zero on empty/absent/unknown field names (validated by running the test against a stub returning `{}` — covered by the test's internal negative case).
