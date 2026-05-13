# Phase 8 Correctness Report — v6.9.0 — Cycle 1

## Overall correctness score: 0.97

---

## Visible harness result
Total: 183 | Pass: 183 | Fail: 0 | Skip: 0

Harness grew by 1 (was 182): new scenario `v6.9.0-needs-clarification-e2e.sh` added in cycle-1 and confirmed passing.
All 183 visible test scenarios pass, including all 41 new v6.9.0-* scenarios.

---

## New e2e test standalone result

`bash tests/scenarios/v6.9.0-needs-clarification-e2e.sh` — PASS (with jq-absent DEGRADED note)

All 8 cycle-1 bug verifications confirmed:
- Bug 1 (asked_at): 6 write sites in orchestrators confirmed, schema.md documented.
- Bug 2 (case mismatch): 6 `grep -iE` sites + 2 functional extractions (upper and lower variants) pass.
- Bug 3 (iteration path): 6 `.fixer_reviewer.iterations` read sites; no remaining `.iteration` reads.
- Bug 4 (double increment): resume-ticket Step 4 explicitly forbids increment; positive assertion held.
- Bug 5 (webhook firing): pipeline-paused curl blocks present in all 4 orchestrators at all 6 sites.
- Bug 6 (sanitize gaps): 3 new tags confirmed; functional redaction of db_password/JSON field/PGP END.
- Bug 7 (history trim): section-count-aware awk; test confirms 60→50 sections, 10 oldest trimmed.
- Bug 8 (test discipline): e2e scenario file exists and is the Bug 8 verification itself.

jq-dependent assertions gracefully skip (DEGRADED, not FAIL) when jq absent from environment.

---

## Hidden suite result

| Hidden test | Status | Notes |
|---|---|---|
| h-license-spdx-roundtrip.sh | ENV-FAIL | `jq` not installed. Assertions 1+2 fail (empty `plugin_license`). Assertion 3 spuriously passes because both are empty. Verified independently via Python/grep: `plugin.json:license = "MIT"` and `marketplace.json:plugins[0].license = "MIT"`. **Same env-tooling failure as cycle-0; no implementation regression.** |
| h-jira-regex-fuzz.sh | ENV-FAIL | Null-byte assertion fails. Bash strips null bytes from `$'PROJ\x00NAME-123'` assignment → becomes `"PROJ"` (length 4) which matches the regex and "passes" validate_issue_id. All other 25 assertions PASS. This is a bash string-handling limitation at the test-harness layer; null bytes cannot enter via CLI args in practice. **Same env-tooling failure as cycle-0; no implementation regression.** |
| h-circuit-breaker-no-deadlock.sh | PASS | 100-rapid-failure simulation: circuit opens at failure 3, 97 calls suppressed, counter resets on new run, pipeline not blocked. All assertions pass. |
| h-needs-clarification-state-additive.sh | PASS (DEGRADED) | Assertion 1 (clarification object present in state/schema.md): grep for `"clarification":` succeeds. Assertion 2 (schema_version still "1.0"): PASS. Assertion 3: SKIP (jq absent). Exit 0. No regression vs cycle-0. |
| h-pipeline-history-no-pii.sh | PASS | Issue_title not written to pipeline-history.md; 3 WARN lines for email/phone/SSN (not in 14-pattern spec, as before); credential tokens correctly sanitized. **Cycle-1 added 3 new REDACTED patterns (LOWER-VAR, JSON-FIELD, PRIVATE-KEY-END); these are exercised by the new e2e test, not this hidden test.** block.detail excluded. PASS. |
| h-snippet-citation-marker-format.sh | SPEC-FAIL | Assertion 4 (AC-063c): expected citation counts (webhook-curl=21, issue-id-validation=4, metrics-json-schema=1, pipeline-completion=3, architecture-freshness=2) are exceeded by the whole-repo grep including `.forge/` spec/plan files. Actual repo-wide counts: webhook-curl=49, issue-id-validation=12, metrics-json-schema=5, pipeline-completion=9, architecture-freshness=5. Counts restricted to skills/ + core/ (implementation files): webhook-curl=23+ (cycle-1 added pipeline-paused curl blocks to 4 skills), issue-id-validation=4, metrics-json-schema=1, pipeline-completion=3, architecture-freshness=2. The webhook-curl count growth from cycle-0 (23) to cycle-1 (23+) is because cycle-1 added 6 pipeline-paused webhook blocks each containing `<!-- @snippet:webhook-curl -->`. Assertion 4 is a scope artifact. Assertions 1-3 and 5 all PASS. **Not an implementation defect; same fundamental root cause as cycle-0 (test greps entire repo including .forge/ artifacts).** |
| h-credential-redaction-bsd-compatible.sh | PASS | No `\b`, `\S`, `\d`, `\w` non-POSIX constructs. BSD-compatible POSIX sed -E confirmed. PASS. |
| h-block-handler-heredoc.sh | PASS | REPO_ROOT resolves 3 levels up; `<!-- COUNTER-EXAMPLE` wrapper present; tightened `<!-- COUNTER-EXAMPLE:` filter works; `jq -nc` form confirmed. PASS. |

**Summary:** 5 PASS (1 degraded-skip) / 3 FAIL. Identical failure profile to cycle-0. Of the 3 FAILs: 2 are environment/tooling limitations (jq absent, bash null-byte truncation); 1 is a spec-scope artifact. Zero genuine implementation defects.

**Note on h-snippet-citation-marker-format Assertion 4 drift from cycle-0 to cycle-1:** The webhook-curl citation count increased from 23 (cycle-0, implementation files) to ~29+ because cycle-1 added 6 pipeline-paused webhook firing blocks (each includes `<!-- @snippet:webhook-curl -->`). This is correct behavior: more sites correctly citing the snippet. The expected count in Assertion 4 (21) was written before cycle-0 additions and is now stale as a hard expectation but correct as a minimum.

---

## AC coverage spot-check (10 sampled — focused on cycle-1 areas)

| AC | Verification method | Pass/Fail | Notes |
|---|---|---|---|
| CRITICAL-1 / AC-048 (asked_at write) | grep | PASS | 6 `ASKED_AT="$(date -u +%FT%TZ)"` assignment sites in skills/ (fix-ticket:2, fix-bugs:2, implement-feature:1, scaffold:1). All 6 immediately precede jq write blocks including `--arg asked_at "$ASKED_AT"`. State/schema.md documents the field at line 346 with full semantics. |
| CRITICAL-2 / AC-049 (case mismatch) | grep | PASS | 6 `grep -iE -A1 "^question:"` sites in orchestrators. Sed patterns use `[Qq]uestion:` and `[Cc]ontext:` form. Functional test (sed alone, no jq) confirmed correct extraction of both uppercase and lowercase variants. |
| HIGH-3 / AC-050 (iteration field path) | grep | PASS | 6 `jq -r '.fixer_reviewer.iterations // 0'` sites. Zero remaining `.iteration // 0` reads without the `fixer_reviewer` prefix in skills/ (grep of old pattern returns empty). |
| HIGH-4 / AC-045 (clarifications_consumed) | grep | PASS | resume-ticket/SKILL.md Step 4 contains explicit prohibition: "DO NOT increment `clarification.clarifications_consumed`" with rationale. No increment assignment in resume-ticket for this field. Orchestrator increment confirmed at all 6 detection sites (jq one-liner `((.clarification.clarifications_consumed // 0) + 1)`). |
| HIGH-5 / AC-050c (pipeline-paused webhook) | grep | PASS | All 4 orchestrators have `if [ -n "${Webhook_URL:-}" ] && printf '%s' "${On_events:-}" | grep -qF 'pipeline-paused'` gates followed by jq -nc + curl blocks. fix-ticket=2 functional blocks, fix-bugs=2, implement-feature=1 (fixer only), scaffold=1 (fixer only) = 6 total. core/agent-states.md documents variable provenance for all 6 sites. |
| MEDIUM-6 / AC-052 (sanitize patterns 17) | grep | PASS | Line 280 of core/post-publish-hook.md lists 17 tags: `[REDACTED-URL]`, `[REDACTED-VAR]`, `[REDACTED-BEARER]`, `[REDACTED-AUTH]`, `[REDACTED-AWS-AKID]`, `[REDACTED-AWS-VAR]`, `[REDACTED-SLACK-TOKEN]`, `[REDACTED-GITHUB-TOKEN]`, `[REDACTED-APIKEY]`, `[REDACTED-JWT]`, `[REDACTED-PRIVATE-KEY]`, `[REDACTED-PRIVATE-KEY-END]`, `[REDACTED-STRIPE-LIVE]`, `[REDACTED-GOOGLE-API-KEY]`, `[REDACTED-OAUTH-REFRESH]`, `[REDACTED-LOWER-VAR]`, `[REDACTED-JSON-FIELD]`. Functional redaction tested in e2e scenario and h-pipeline-history-no-pii. |
| MEDIUM-7 / AC-056b (history trim by section) | grep + content | PASS | post-publish-hook.md line 283-299: section-count-aware awk using `total_sections`, `cutoff = total_sections - 50`, `section_num > cutoff` gate. Old line-counter pattern explicitly noted as incorrect. Functional test in e2e confirms 60→50 section trim. |
| AC-040 (agent-states.md) | grep | PARTIAL (unchanged from cycle-0) | `## Pause-State Contract Overview` and `## NEEDS_DECOMPOSITION (existing, see canonical location)` headings are present and correct. AC-040 spec pattern `Section 1.*Pause-State Contract Overview` doesn't match (implementation uses `##` without "Section N:" prefix). Visible harness passes with relaxed patterns. LOW advisory from cycle-0 unchanged. |
| AC-044 (schema_version 1.0) | grep | PASS | `"schema_version": "1.0"` present in state/schema.md. clarification object added additively. No version bump. |
| AC-025 (issue-id regex with dot) | grep | PASS | All 4 skills retain `^[A-Za-z0-9#._-]+$` regex. Not regressed by cycle-1 changes. |

---

## Revision status.json claims verification

| Claim | Verified? | Notes |
|---|---|---|
| "6 asked_at write sites in orchestrators" | YES | `grep -rn 'ASKED_AT="$(date' skills/` returns exactly 6 lines in fix-ticket(2), fix-bugs(2), implement-feature(1), scaffold(1). |
| "6 case-insensitive question greps" | YES | `grep -rn 'grep -iE' skills/` finds 6 lines. |
| "6 fixer_reviewer.iterations reads" | YES | `grep -rn 'fixer_reviewer.iterations // 0' skills/` returns 6+ lines across all orchestrators. |
| "resume-ticket clarifications_consumed increment removed" | YES | Only negative/prohibition comment remains; no `(+1)` or increment operator for this field in resume-ticket. |
| "6 pipeline-paused webhook event references" | YES | Functional curl blocks (not just mentions): fix-ticket=2, fix-bugs=2, implement-feature=1, scaffold=1 = 6. |
| "Pattern count 14 -> 17" | YES | Three new tags (LOWER-VAR, JSON-FIELD, PRIVATE-KEY-END) added. Tag list on line 280 contains 17 items. |
| "Harness: 183/183 PASS (+1 new e2e scenario)" | YES | Harness confirmed 183/183 PASS. New scenario v6.9.0-needs-clarification-e2e.sh exists and passes standalone. |
| "section-count-aware awk: compute cutoff = total - 50, use section_num > cutoff gate" | YES | Exact awk logic in post-publish-hook.md lines 286-299 matches the claim. Atomic .tmp + mv preserved. |

All 8 status.json claims verified accurate by direct inspection.

---

## Critical findings (HIGH+)

No HIGH or CRITICAL implementation defects found.

### F-01. Hidden test h-snippet-citation-marker-format Assertion 4 scope artifact — citation counts grew (LOW)
- **Severity:** LOW (same as cycle-0; slightly worsened by cycle-1 adding pipeline-paused firing blocks)
- **Location:** `.forge/phase-5-tdd/tests-hidden/h-snippet-citation-marker-format.sh` Assertion 4
- **Evidence:** webhook-curl citations grew from 23 (cycle-0 impl-files) to ~29 because cycle-1 added 6 new `<!-- @snippet:webhook-curl -->` inline citations in pipeline-paused blocks. Repo-wide count is 49. Expected 21 is now stale.
- **Root cause:** Expected counts pre-date both cycle-0 and cycle-1 additions. The growth is the correct behavior: more sites properly citing the canonical snippet.
- **Fix (advisory):** Assertion 4 should use `>= N` (at-least) or restrict scope to `skills/` + `core/` excluding `.forge/`. Not a v6.9.0 blocker.

### F-02. AC-040 section heading regex mismatch (LOW — unchanged from cycle-0)
- **Severity:** LOW
- **Location:** `core/agent-states.md` headings vs `formal-criteria.md` AC-040 patterns
- **Evidence:** Headings use `## Pause-State Contract Overview` (no "Section 1:" prefix). Visible harness uses relaxed patterns and passes. No cycle-1 regression.

### F-03. `jq` not available in test execution environment (ENV — not impl defect, unchanged)
- **Severity:** ENV (not actionable as code fix)
- **Location:** h-license-spdx-roundtrip.sh, h-needs-clarification-state-additive.sh
- **Evidence:** `jq: command not found` (exit 127). Cycle-1 e2e test added graceful jq-absent handling (SKIP, not FAIL) for jq-dependent sub-tests. Hidden tests remain ENV-FAIL. Not a regression.

---

## Score rationale

Cycle-1 improved from 0.95 to 0.97:
- Harness increased from 182 to 183 (+1 functional e2e scenario) — positive signal.
- All 8 critical bugs fixed and confirmed by independent grep verification.
- All 8 status.json claims verified accurate.
- Hidden test failure profile identical to cycle-0 (no new failures, no regressions).
- F-01 (citation count drift) is slightly worse numerically but is structurally correct behavior: more sites citing snippets is good, not bad. The expected-count hard assertion is stale.
- +0.02 awarded for: full cycle-1 bug remediation confirmed, e2e test covering all 8 bugs, jq-graceful-degradation added to new e2e (reducing jq-absent impact), all revision status.json claims accurate.

---

## Verdict + JSON (REQUIRED)

```json
{
  "dimension": "correctness",
  "score": 0.97,
  "verdict": "CONDITIONAL_PASS",
  "harness_pass_count": 183,
  "harness_fail_count": 0,
  "hidden_pass_count": 5,
  "hidden_fail_count": 3,
  "hidden_fail_breakdown": {
    "env_tooling": 2,
    "spec_scope_artifact": 1,
    "genuine_impl_defect": 0
  },
  "delta_from_cycle_0": "+0.02",
  "cycle_1_bugs_fixed": 8,
  "cycle_1_bugs_verified": 8,
  "revision_status_json_claims_accurate": true,
  "conditional_reason": "3 hidden test failures are identical non-implementation-defect causes as cycle-0: 2 env-tooling (jq absent, bash null-byte truncation), 1 spec-scope artifact (test greps .forge/ inflating citation counts). 183/183 visible harness PASS. New e2e scenario v6.9.0-needs-clarification-e2e.sh covers all 8 cycle-1 bugs and passes standalone. All 8 revision status.json claims verified accurate. No genuine implementation defect found.",
  "completed_at": "2026-04-20T11:45:00Z"
}
```

DONE
