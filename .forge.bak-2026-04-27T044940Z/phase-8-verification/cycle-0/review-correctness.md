# Phase 8 — Correctness Review (Cycle 0)

**Reviewer:** Phase 8 Correctness Agent (Sonnet)
**Date:** 2026-04-25
**Target:** v7.0.0 implementation on `main` (forge pipeline working branch)
**Harness run log:** `/tmp/v8-correctness.log`

---

## 1. Harness PASS/FAIL/SKIP summary

| Run | PASS | FAIL | SKIP | Total | Exit code |
|-----|------|------|------|-------|-----------|
| Phase 8 re-run (cycle-0) | **206** | **0** | **15** | 221 | 0 (SUCCESS) |

Matches Phase 7 fix-up final counts exactly. No regression introduced between Phase 7 and this re-run.

**SKIP breakdown (15):**

| SKIP scenario | Reason |
|---|---|
| `v6.10.0-autopilot-audit-disclosure` | RETIRED in Phase 7: checks v6.10.0 forge artifact (`research/autopilot-hook-interaction.md`) absent in v7.0.0 forge |
| `v6.10.0-layers-3-5-deferred-disclosure` | RETIRED in Phase 7: layer-numbered terminology specific to v6.10.0 spec, absent in v7.0.0 |
| `v6.9.0-autopilot-skip-paused` | Pre-existing skip (exit 77) — MCP-live test |
| `v6.9.0-changelog-completeness` | Pre-existing skip — changelog gating |
| `v6.9.0-circuit-breaker-non-blocking` | Pre-existing skip — MCP-live test |
| `v6.9.0-metrics-format-json` | Pre-existing skip |
| `v6.9.0-needs-clarification-dos-cap` | Pre-existing skip |
| `v6.9.0-needs-clarification-triage` | Pre-existing skip |
| `v6.9.0-pipeline-history-append` | Pre-existing skip |
| `v6.9.0-pipeline-history-pii-scope` | Pre-existing skip |
| `v6.9.0-pipeline-paused-webhook` | Pre-existing skip |
| `v6.9.0-plugin-repo-url-invalid-tld` | Pre-existing skip |
| `v6.9.0-webhook-proto-coverage` | Pre-existing skip |
| `v6.10.0-skill-dispatch-enforcement` | Pre-existing skip |
| `ac-v692-autopilot-bash-dispatch` | Pre-existing skip |

The 2 new SKIPs (v6.10.0 retired tests) are expected and documented. All 13 other SKIPs were pre-existing in v6.10.0 baseline.

---

## 2. All 18 v7.0.0 scenarios PASS

| Scenario | Result | ACs covered |
|----------|--------|-------------|
| `v7.0.0-no-extra-labels-section` | PASS | AC-DEL-EXTRA-LABELS-1..5 |
| `v7.0.0-skill-rename-status` | PASS | AC-RENAME-STATUS-1..7 |
| `v7.0.0-skill-rename-init` | PASS | AC-RENAME-INIT-1..7 |
| `v7.0.0-no-create-pr-skill` | PASS | AC-DEL-CREATE-PR-1..11 |
| `v7.0.0-publish-auto-detect-issue-found` | PASS | AC-PUBLISH-AUTO-DETECT-1,2,8,9,10 |
| `v7.0.0-publish-auto-detect-issue-404` | PASS | AC-PUBLISH-AUTO-DETECT-12,4 |
| `v7.0.0-publish-auto-detect-tracker-down` | PASS | AC-PUBLISH-AUTO-DETECT-5,7,11 |
| `v7.0.0-publish-no-issue-id-pr-only` | PASS | AC-PUBLISH-AUTO-DETECT-13,14,15,ZERO-COMMITS |
| `v7.0.0-publish-extraction-regex` | PASS | AC-PUBLISH-AUTO-DETECT-3,EXTRACTION-1..5 |
| `v7.0.0-doc-count-28-skills` | PASS | AC-COUNTS-1,3,4,6,7,8 |
| `v7.0.0-doc-count-18-config-sections` | PASS | AC-COUNTS-2,3,5,9 |
| `v7.0.0-pause-limits-mapping` | PASS | AC-PAUSE-LIMITS-DOC-1,2 |
| `v7.0.0-changelog-migration-guide` | PASS | AC-CHANGELOG-MIGRATION-1..7 |
| `v7.0.0-readme-collision-warning` | PASS | AC-DOCS-COLLISION-WARN-1,2 |
| `v7.0.0-cross-file-invariants` | PASS | AC-INVARIANTS-1,2,3 |
| `v7.0.0-workflow-router-intent-table` | PASS | AC-RENAME-STATUS-5,6 / AC-DEL-CREATE-PR-7,8 / AC-DOCS-COLLISION-WARN-3 |
| `v7.0.0-no-version-bump` | PASS | AC-NO-VERSION-BUMP-1,2,3 |
| `v7.0.0-empty-skills-dir-invariant` | PASS | AC-COUNTS-10 / design.md §2.3 |

**All 18 v7.0.0 scenarios PASS.**

---

## 3. REQ spot-checks (3 manual verifications)

### REQ-PUBLISH-AUTO-DETECT — AC-PUBLISH-AUTO-DETECT-3 (canonical regex present)

**Check:** `skills/publish/SKILL.md` must contain the canonical extraction regex `^(#?[0-9]+|[A-Za-z][A-Za-z0-9_]*-[0-9]+)`.

**Result:** PASS.
- Line 79: `^(#?[0-9]+|[A-Za-z][A-Za-z0-9_]*-[0-9]+)` (spec form)
- Line 90: `if [[ "$residue" =~ ^(#?[0-9]+|[A-Za-z][A-Za-z0-9_]*-[0-9]+) ]]; then` (bash idiom)

Both the canonical reference and the Bash idiom implementation are present. SC-11 algorithm contract (REGEX-EXTRACTOR form, not split-at-delimiter) is correctly documented including the rationale for abandoning the split approach.

### REQ-RENAME-STATUS — AC-RENAME-STATUS-1 (skills/status absent, skills/pipeline-status exists)

**Check:** `skills/status/` must not exist; `skills/pipeline-status/` must exist with frontmatter `name: pipeline-status`.

**Result:** PASS.
- `skills/status/`: ABSENT
- `skills/pipeline-status/`: EXISTS, frontmatter confirmed `name: pipeline-status`
- The `ceos-agents:status` reference remaining in `skills/workflow-router/SKILL.md` is in the intentional "Did you mean...?" fallback section (design.md §5.3 exception per REQ-RENAME-STATUS spec), not in the intent table.

### REQ-COUNTS — AC-COUNTS-1 (CLAUDE.md shows 28 skills)

**Check:** `CLAUDE.md` must show `28 skills`, not `29 skills`.

**Result:** PASS.
- `CLAUDE.md:18`: `- \`skills/\` — 28 skills (slash commands, including workflow-router)`
- Corroborating: `README.md:281` shows "All 28 skills", `docs/reference/skills.md:3` shows "All 28 skills", `docs/reference/automation-config.md:9` shows "18 optional sections".

---

## 4. Hidden test gap assessment

**Phase 5 produced 18 visible scenarios, 0 hidden tests** (mutation framework SKIP — pure markdown project, no stryker/mutmut applicable).

### Coverage analysis

The 18 visible scenarios collectively cover 79 functional ACs + 15 test-inventory ACs = 94 total. Review of specific SCs that might lack coverage:

| Sub-clause | Visible test coverage | Gap assessment |
|---|---|---|
| SC-1 (Step 0 pre-pre-flight ordering) | `v7.0.0-publish-auto-detect-issue-found` checks `### Step 0` heading and `tracker_needed` gate | Covered |
| SC-2 (5-bucket error_type enum) | `v7.0.0-publish-auto-detect-tracker-down` checks `unknown→FAIL` prose | Covered (prose check) |
| SC-3 (no get_issue-tool → unknown → FAIL) | `v7.0.0-publish-auto-detect-tracker-down` checks `unknown→FAIL` defensive default | Covered (prose check) |
| SC-4 (3 exact Tracker: row strings) | `v7.0.0-publish-auto-detect-issue-found` implicitly; `agents/publisher.md` lines 91-93 verified | Partially covered — no dedicated AC checks exact publisher.md strings |
| SC-5 (interactive-only note) | `v7.0.0-publish-auto-detect-issue-found` FC-7 checks autopilot note | Covered |
| SC-6 (4-step Recommendation list) | `v7.0.0-publish-auto-detect-tracker-down` checks step 1 (check-setup) + step 2 (rename) | Steps 3+4 not individually tested |
| SC-7 (404 WARN single-line) | `v7.0.0-publish-auto-detect-issue-404` | Covered |
| SC-8 (no-issue-id INFO single-line) | `v7.0.0-publish-no-issue-id-pr-only` | Covered |
| SC-9 (webhook fires in all non-FAIL, not on FAIL) | `v7.0.0-publish-auto-detect-issue-found` checks webhook Step 7 prose; no negative check "no pr-created on FAIL" | **Minor gap** — no test asserts webhook not fired on FAIL |
| SC-10 (missing Branch naming → no FAIL) | `v7.0.0-publish-no-issue-id-pr-only` FC-3 checks SC-10 `[ceos-agents][INFO] No Branch naming pattern configured` | Covered |
| SC-11 (REGEX-EXTRACTOR algorithm, 6 runtime checks) | `v7.0.0-publish-extraction-regex` has 6 runtime bash assertions | Covered |
| SC-12 (detached HEAD → FAIL) | `v7.0.0-publish-no-issue-id-pr-only` FC-4 + FC-5 check detached HEAD message | Covered |

**Key gap: SC-9 negative webhook assertion.** No test verifies that `pr-created` webhook is NOT fired on FAIL mode. The implementation prose is correct (`The \`pr-created\` event fires in all non-FAIL modes`), but this is only testable as a prose check, not a runtime contract check. Risk level: LOW — the prose is clear and consistent, but a hidden test asserting `! grep "fires.*FAIL\|pr-created.*FAIL" skills/publish/SKILL.md` would strengthen this.

**AC-PUBLISH-AUTO-DETECT-6 deferred:** Phase 5 manifest explicitly notes this AC (Three `Tracker:` row strings in `agents/publisher.md`) is "covered implicitly by scenario 5; explicit check deferred to hidden suite if needed". The actual publisher.md content was verified manually (lines 91-93 contain all 3 exact strings).

**Overall hidden test gap severity: LOW.** The visible suite covers all functional paths. The gaps identified are: (a) no runtime execution of publish skill (pure markdown project — expected), (b) SC-9 webhook-on-FAIL negative assertion, (c) SC-6 Recommendation steps 3+4 not checked individually. None are blocking.

---

## 5. Regression assessment

### Pre-existing scenarios

All 188 non-v7.0.0 scenarios that were PASS in v6.10.0 continue to PASS (206 total PASS − 18 v7.0.0 = 188 pre-existing). The 2 newly-SKIPped v6.10.0 tests (`autopilot-audit-disclosure`, `layers-3-5-deferred-disclosure`) are correctly RETIRED because they depend on v6.10.0 forge artifacts that were replaced when the v7.0.0 pipeline started. This is expected and documented in the Phase 7 fix-up report.

**No pre-existing PASSing test has been converted to FAIL. Zero regressions.**

### Count-update regressions

Two count-bearing pre-existing tests were updated in Phase 7:
- `sprint-counts.sh`: `skills_fs / skills_claimed -ne 29` → `28` (correct: v7.0.0 has 28 skills)
- `v6.9.0-arch-freshness-refresh-on-release.sh`: expects `SKL[28 Skills]` (was `SKL[29 Skills]`) — the `docs/architecture.md` was already corrected by a prior wave

These are not regressions; they are legitimate count maintenance. Both now PASS.

---

## 6. Findings table

| ID | Tier | Severity | File | Finding | Verdict |
|----|------|----------|------|---------|---------|
| F-1 | 3 (quality) | MEDIUM | `CHANGELOG.md:22-26` | REQ-CHANGELOG-MIGRATION requires bullets "(in English; Czech variants from the spec are translated)" but bullets 1–5 contain Czech text: "sekce smazána", "přesuň labely", "krátká forma kolidovala", "smazán → použij", "opraven — sekce platí". The changelog test passes because it only checks English key phrases. This is a spec violation: the migration guide bullets are partially in Czech. | SHOULD-FIX |
| F-2 | 3 (quality) | LOW | `tests/scenarios/v7.0.0-publish-auto-detect-tracker-down.sh` | No test asserts that `pr-created` webhook is NOT emitted on FAIL mode (SC-9 negative clause). Implementation prose is correct but unverified by test. | ADVISORY |
| F-3 | 3 (quality) | LOW | `tests/scenarios/v7.0.0-publish-auto-detect-tracker-down.sh` | SC-6 Recommendation steps 3 and 4 ("create PR manually: git push -u…" and "Once tracker reachable, re-run /publish") are not individually checked by any test. Implementation contains both steps but they are untested. | ADVISORY |

**No Tier 1 (binary pass/fail security or correctness blockers) findings.**

---

## 7. Spec alignment spot-checks

### REQ-DEL-EXTRA-LABELS
- `core/config-reader.md:31`: Extra labels parse rule ABSENT — confirmed
- `agents/publisher.md:69`: "Add labels from PR Rules section only." — confirmed (spec target)
- `skills/check-setup/SKILL.md:201`: deprecation-warn bash block present (intentional, per SHOULD-FIX note in Phase 7)

### REQ-RENAME-STATUS / REQ-RENAME-INIT
- Both `skills/status/` and `skills/init/` directories: ABSENT
- Both `skills/pipeline-status/` and `skills/setup-mcp/`: EXIST with correct frontmatter
- No stubs at old paths (design decision D4)
- Workflow-router "Did you mean?" fallback references old names — correct per spec exception

### REQ-PUBLISH-AUTO-DETECT
- Step 0 pre-pre-flight ordering: CORRECT (Step 0 = branch parse, Step 1 = MCP preflight gated on tracker_needed)
- Canonical regex: PRESENT and matches spec exactly
- Three modes: full-publish, pr-only-no-id, pr-only-404 all documented
- FAIL tier block format: CORRECT (`[ceos-agents] 🔴 Pipeline Block`, `Skill:` field)
- 5-bucket error_type: PRESENT
- Detached HEAD handling: CORRECT (FAIL, not pr-only-no-id)

### REQ-COUNTS
- `CLAUDE.md`: 28 skills, 18 optional sections — confirmed
- `README.md`: 28 skills, 18 optional sections — confirmed
- `docs/reference/skills.md`: 28 skills — confirmed
- `docs/reference/automation-config.md`: 18 optional sections — confirmed

### REQ-INVARIANTS
- License SPDX "MIT" consistent: PASS (verified by `v7.0.0-cross-file-invariants`)
- Maintainer email consistent: PASS (verified by same)
- Issue/PR template parity: PASS (byte-identical pairs verified)

---

## 8. Conclusion

| Dimension | Score | Assessment |
|-----------|-------|------------|
| Harness pass rate | 206/206 non-SKIP (100%) | All passing tests pass |
| v7.0.0 scenarios (18/18) | 18/18 PASS (100%) | Full coverage |
| REQ spot-checks | 3/3 PASS | Canonical regex, rename-status, counts all verified |
| Regression | 0 new failures | No regressions vs v6.10.0 baseline |
| Spec alignment | High | All 6 release actions implemented correctly |
| Hidden test gap | Low severity | SC-9 webhook negative, SC-6 steps 3+4 unverified |
| Quality findings | 1 SHOULD-FIX (F-1: Czech text in CHANGELOG), 2 ADVISORY | No blockers |

**SHOULD-FIX note (F-1):** REQ-CHANGELOG-MIGRATION explicitly requires English. Bullets 1–5 are partially in Czech. This is a documentation quality issue, not a functional bug. The test passes because it only checks key English phrases within the bullets. A Phase 9 fix is recommended but does NOT block PASS verdict (CHANGELOG is user-facing only, no runtime behavior affected, all 5 required English key phrases are present).

**Correctness score: 0.88 / 1.0**

- Base: 1.0
- Deduction (F-1 CHANGELOG Czech/English spec violation, SHOULD-FIX): −0.08
- Deduction (F-2 SC-9 webhook negative unverified, ADVISORY): −0.02
- Deduction (F-3 SC-6 Recommendation steps 3+4 unverified, ADVISORY): −0.02

**Verdict: PASS** (threshold: 0.7)

---

*Phase 8 Correctness Review complete. Harness: PASS=206, FAIL=0, SKIP=15. Score: 0.88/1.0. 1 SHOULD-FIX, 2 ADVISORY. Recommend Phase 9 apply F-1 CHANGELOG English fix.*
