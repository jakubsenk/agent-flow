# Phase 4 Spec — Revision 1 Notes

Applied to `requirements.md`, `design.md`, `formal-criteria.md` on 2026-04-17 by the Phase 4 revision agent (round 1 of max 3).

Gate 1 decisions from `.forge/phase-3-brainstorm/final.md` were NOT reopened. Only tightening / consistency / portability fixes were applied as requested in the orchestrator brief.

---

## Compliance review (review-1-compliance.md) — 1 MINOR

| Finding | Status | Action |
|---|---|---|
| **f-compliance-O** — AUTOPILOT-R8, AUTOPILOT-R12, WEBHOOK-R7 lack AC Traces links | Applied | Added AC-31 (AUTOPILOT-R8 via `autopilot-feature-limit-no-query.sh`), AC-32 (AUTOPILOT-R12 via `autopilot-mcp-unreachable.sh`), AC-33 (WEBHOOK-R7 via `webhook-no-step-skipped.sh`). All three EARS IDs now traced. |

---

## Quality review (review-2-quality.md) — 18 findings, FAIL 3.3

| Finding | Severity | Status | Action |
|---|---|---|---|
| **f-quality-1** — `\|` inside `grep -E` is literal pipe, not alternation (AC-6, AC-21, AC-22, AC-23, AC-28) | MAJOR | Applied | Replaced `\|` with bare `|` in all 5 ACs; AC-21 switched to `grep -cE` returning an integer so the "≥7" semantic is explicit. |
| **f-quality-2** — AC-2 references test file `autopilot-lock-acquire.sh` that design.md doesn't create | MAJOR | Applied | Added `tests/scenarios/autopilot-lock-acquire.sh` to design.md §3.7 (positive acquire-path scenario asserting `owner.json` contents during run). AC-2 rewritten to invoke the scenario directly. |
| **f-quality-3** — Three files from approved brainstorm missing from design.md (`skills/workflow-router/SKILL.md`, `docs/reference/pipelines.md`, `examples/config-templates/*`) | MAJOR | Applied | Added `skills/workflow-router/SKILL.md` row (AUTOPILOT-R1) and `docs/reference/pipelines.md` row (AUTOPILOT-R1, R2) to §3.6. `examples/config-templates/*` explicitly deferred to v6.8.1 with DEFERRED row + rationale + CHANGELOG Known-Issues entry. |
| **f-quality-4** — Stage enum mismatch `reproduction` vs `reproducer` | MAJOR | Applied | Added "Canonical Definitions" preamble to design.md pinning `reproduction` as the STAGE key and `reproducer` as the AGENT file. Updated §3.3 bullet wording to use `reproduction if run`. Added Known-Limitations §8.9 restating the rule. |
| **f-quality-5** — WEBHOOK-R3 fire-order ambiguity | MAJOR | Applied | Requirements.md §1.2 final sentence + WEBHOOK-R2/R3/R4 rewording: `state.json commit precedes webhook fire; failed commit suppresses the webhook`. Design.md §3.2 `core/post-publish-hook.md` change description documents this as the Section-4 rule. |
| **f-quality-6** — Lock-acquisition race window in §4.8 snippet | MAJOR | Applied | §4.8 rewritten with explicit handlers for all three failure paths (empty lock, unparseable `acquired_at`, stale re-acquire race). Each path emits `[autopilot][ERROR]` consistent with AUTOPILOT-R3 messaging. |
| **f-quality-7** — `date -u -d` is GNU-only | MAJOR | Applied | §4.8 now uses pure `awk mktime` for ISO→epoch (no GNU `-d`, no BSD `-j -f`, no Python 3 dependency). Verified `tests/harness/run-tests.sh` has no Python 3 dependency (only one scenario uses Python and is optional). |
| **f-quality-8** — Missing tests for AUTOPILOT-R5/R8/R10/R12 | MAJOR | Applied | Added `autopilot-trap-cleanup.sh` (R5 runtime → AC-34), `autopilot-feature-limit-no-query.sh` (R8 → AC-31), `autopilot-on-error-stop.sh` (R10 stop → AC-35), `autopilot-mcp-unreachable.sh` (R12 → AC-32) to design.md §3.7. |
| **f-quality-9** — AC-13 `grep -A3` does not parse JSON | MAJOR | Partial (judgment call — see Gate 2 note) | AC-13 reworded to state it is a line-context regression guard; added Known-Limitations §8.8 acknowledging that fixture-based byte-diff is deferred. Rationale: introducing fixture files + jq dependency in v6.8.0 expands scope; current grep still catches the realistic regression case (accidental edit of the heredoc). |
| **f-quality-10** — No webhook URL validation (SSRF) | MAJOR | Applied as explicit NOT_IN_SCOPE + operator-trust note | NOT_IN_SCOPE §6.21 added; Known-Limitations §8.4; CLAUDE.md change (3.6 item f) adds an operator-trust note under Notifications; docs/reference/config.md mirrors it. SSRF hardening deferred to v6.9.0. |
| **f-quality-11** — `owner.json` parsing brittle / injection-prone | MAJOR | Applied | §4.8 rewritten with defensive branches: empty file → recover; missing `acquired_at` → recover; unparseable → explicit ERROR. Trap body also defensive-parses `pid` via grep+cut. |
| **f-quality-12** — Clock skew not acknowledged | MAJOR | Applied | §4.8 uses `LOCK_TIMEOUT + 5` minute buffer. docs/guides/autopilot.md description in §3.6 includes single-host-operation guidance. AUTOPILOT-R13 adds cross-host hostname WARN. |
| **f-quality-13** — `webhook-pipeline-events.sh` depends on `nc` availability | MINOR | Applied | §3.7 scenario description now specifies precondition check + exit 77 SKIP fallback. Harness already honors exit 77. |
| **f-quality-14** — AC-28 doesn't verify date or MINOR classification | MINOR | Applied | AC-28 extended to grep for `2026-04-17` and `Migration notes`. |
| **f-quality-15** — `pipeline.summary_table` markdown coupling | MINOR | Applied | design.md §3.2 `state/schema.md` change description (f) adds the "consumers regenerate own table" guidance. Known-Limitations §8.7 makes this explicit. |
| **f-quality-16** — `{stage}.model` derivation unspecified | MINOR | Applied | design.md Canonical Definitions preamble includes full Stage→Agent→Model mapping table. COST-R4 updated to reference the derivation rule. |
| **f-quality-17** — Concurrent autopilot + manual `/fix-ticket` unaddressed | MINOR | Applied | docs/guides/autopilot.md change description (§3.6) includes the advisory note. |
| **f-quality-18** — AC-30 regex unnecessarily complex | MINOR | Applied | AC-30 simplified to `grep -nE 'mkdir .*\.ceos-agents/autopilot\.lock'`. |

---

## Devil's Advocate review (review-3-devilsadvocate.md) — 12 findings

| Finding | Severity | Status | Action |
|---|---|---|---|
| **f-devilsadvocate-1** — `run_id` semantics undefined | MAJOR | Applied | `run_id` redefined as `"{issue_id}_{started_at_ISO8601}"` in design.md Canonical Definitions preamble; all three payload examples updated (§4.3/4.4/4.5); WEBHOOK-R2/R3/R4 retain the field; Known-Limitations §8.1 documents collision caveat. Gate-1 row 5 rationale retained. |
| **f-devilsadvocate-2** — Tracker-level race (lock is project-local) | MAJOR | Applied | NOT_IN_SCOPE §6.19 + Known-Limitations §8.2 + AUTOPILOT-R13 (cross-host WARN) + docs/guides/autopilot.md `## Single-Host Operation` section per brief. |
| **f-devilsadvocate-3** — `pipeline.summary_table` unbounded | MAJOR | Applied | COST-R10 added: ≤20 rows, ≤4000 chars, row-wise truncation with `(truncated, N more stages in pipeline.log)` notice row. AC-37 + `cost-summary-truncation.sh` scenario. design.md §4.2 has a truncated example. |
| **f-devilsadvocate-4** — Webhook blast radius / no circuit breaker | MAJOR | Applied as explicit NOT_IN_SCOPE | NOT_IN_SCOPE §6.20 + Known-Limitations §8.3. Circuit breaker deferred to v6.9.0. Rationale: introduces new state (per-pipeline failure counter) and contradicts "advisory-only" Gate-1 stance. Surfaced for Gate 2. |
| **f-devilsadvocate-5** — `/metrics` mixes measured + estimated silently | MAJOR | Applied | COST-R8 rewritten + COST-R11 added: separate line items per pipeline, never a combined grand total when any pipeline is estimated. Per-pipeline format: `Pipeline PROJ-42: 42,150 tokens measured (8 stages) + 0 tokens estimated (0 stages) = 42,150 total`. AC-19 extended to assert separate lines + absence of cross-boundary grand total. |
| **f-devilsadvocate-6** — No upgrade/migration notes | MINOR | Applied | design.md §3.6 CHANGELOG entry now has `### Migration notes` subsection. AC-28 extended to grep for `Migration notes`. |
| **f-devilsadvocate-7** — No MCP ping retry | MINOR | Applied as explicit NOT_IN_SCOPE | NOT_IN_SCOPE §6.22 + Known-Limitations §8.5. Retry/backoff deferred to v6.9.0. |
| **f-devilsadvocate-8** — Task-tool usage field name unverified (Phase 2 Q1 MEDIUM) | MINOR | Applied | COST-R12 added + AC-38 + `tests/scenarios/cost-task-tool-usage-field-discovery.sh` (runs first in Phase 5, prints raw `result.usage`, non-fatal). |
| **f-devilsadvocate-9** — CHANGELOG v6.8.0 entry not drafted | MINOR | Applied | design.md §3.6 CHANGELOG row now specifies `### Added / ### Changed / ### Known Issues / ### Migration notes` structure. AC-28 checks for date + `Migration notes`. |
| **f-devilsadvocate-10** — Trap path is relative / CWD-dependent | MINOR | Applied | §4.8 resolves `LOCK_DIR="$(pwd)/.ceos-agents/autopilot.lock"` before trap install. |
| **f-devilsadvocate-11** — Trap-ordering race | MINOR | Applied (per brief) | §4.8 rewritten: trap registered via `install_trap` ONLY after successful `mkdir` (or successful stale recovery); trap body verifies `owner.json.pid == $$` before `rm -rf`. AUTOPILOT-R5 updated to specify conditional registration + ownership verification. |
| **f-devilsadvocate-12** — No EARS for missing `### Issue Tracker` | MINOR | Partial (judgment call — see Gate 2 note) | Design.md §3.1 Step 0 description now includes "Issue-Tracker validation"; `/check-setup` already guards misconfigured CLAUDE.md at the skill level. A net-new EARS (AUTOPILOT-R14 with exit 4) would add surface area without a distinct behavior beyond what `core/config-reader.md` already fails-loud on. Declared as an enforced precondition of AUTOPILOT-R6 rather than a net-new requirement. Surfaced for Gate 2 — could be promoted to AUTOPILOT-R14 if user prefers. |

---

## EARS / AC count delta

- **EARS before revision:** 29 (AUTOPILOT 12 + WEBHOOK 8 + COST 9)
- **EARS after revision:** 34 (AUTOPILOT 13 + WEBHOOK 8 + COST 13)
  - AUTOPILOT: +R13 (cross-host WARN)
  - COST: +R10 (truncation), +R11 (dual-mode separation), +R12 (discovery test), and R5 wording tightened; +R8 rewritten as "two separate totals" wording still counts as same ID
- **AC before revision:** 30
- **AC after revision:** 38 (added AC-31..AC-38)

---

## Judgment calls surfaced for Gate 2

1. **f-quality-9 (AC-13)** — Kept as line-context grep with Known-Limitation acknowledgment rather than escalating to fixture+jq byte-diff. Rationale: byte-diff would add fixture maintenance burden and jq runtime dep; current grep catches realistic accidental edit of the heredoc. Flag if reviewer disagrees.
2. **f-devilsadvocate-4 (circuit breaker)** — Deferred to v6.9.0 as NOT_IN_SCOPE §6.20. Rationale: would introduce per-pipeline failure counter state and arguably revisits Gate-1 "advisory-only" stance. Explicit Known-Limitation §8.3 alerts operators. If Gate 2 reviewers want it in v6.8.0, scope grows and "3x more stall time with 10 issues" becomes a ship blocker.
3. **f-devilsadvocate-12 (missing Issue Tracker EARS)** — Not promoted to a net-new EARS; instead documented as enforced precondition of AUTOPILOT-R6. Reviewers may want AUTOPILOT-R14 with exit code 4; I chose to lean on `/check-setup` + `core/config-reader.md` existing error paths.
4. **Deferred `examples/config-templates/*` (f-quality-3 sub-item)** — 8 templates × test = scope. Deferred to v6.8.1 if any operator reports friction. Alternative: add to 2 templates (github-nextjs, gitea-spring-boot) only. Chose full defer + CHANGELOG Known-Issue entry for simplicity. Surfaced for Gate 2.
