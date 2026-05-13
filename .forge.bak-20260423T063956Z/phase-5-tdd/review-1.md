# Phase 5 Combined Review

**Reviewer:** Phase 5 Spec-Compliance + Quality combined reviewer
**Date:** 2026-04-19
**Artifacts reviewed:**
- `tests/scenarios/v6.9.0-*.sh` — 40 visible scenarios (actual; test-plan header claims 30 — see F-01)
- `.forge/phase-5-tdd/tests-hidden/h-*.sh` — 8 hidden scenarios
- `.forge/phase-5-tdd/test-plan.md` — REQ→scenario mapping
- `.forge/phase-4-spec/final/requirements.md` — 90 REQs (up to REQ-073 + sub-items)
- `.forge/phase-4-spec/final/formal-criteria.md` — 118 ACs

---

## Verdict: CONDITIONAL_PASS

Two findings require Phase 7 attention (not revision-blocking for Phase 5 outputs but must be addressed before Phase 8 verification):

- **F-01** (LOW): test-plan.md header says `"30 visible + 8 hidden = 38"` but the body correctly maps 40 visible; the header count is stale. Requires a 1-line header correction.
- **F-02** (MEDIUM): REQ-068 (version bump to 6.9.0) has a phantom mapping — test-plan.md claims `bc-no-renamed-section.sh` asserts `"version 6.9.0 in plugin.json + marketplace.json"` but that scenario contains no such assertion. AC-068 (`jq -r '.version' .claude-plugin/plugin.json == "6.9.0"`, `git tag -l v6.9.0`) is uncovered by any scenario. This must be added before Phase 8.

---

## Spec compliance

### 100% REQ coverage: CONDITIONAL_PASS

**Method:** Verified unique REQ IDs in test-plan.md vs requirements.md; cross-checked 15 REQs by reading actual scenario files.

All REQs from REQ-001 through REQ-073 (plus all lettered sub-items REQ-027a/b, REQ-050a-f, REQ-055a-d, REQ-060a, REQ-063a-d, REQ-064a) appear in the traceability table and are mapped to scenario files that exist on disk and contain relevant assertions.

**Issue:** REQ-068 is mapped to `v6.9.0-bc-no-renamed-section.sh` with the annotation `"version 6.9.0 in plugin.json + marketplace.json (checked as BC-adjacent count)"`. Reading that scenario file confirms it checks REQ-071 only (Pause Limits as 19th optional section). The version-equality checks required by AC-068 (`jq -r '.version' .claude-plugin/plugin.json == "6.9.0"`, matching marketplace.json, and `git tag -l v6.9.0`) are absent from all 48 scenarios.

**Note on numbering:** The spec says "REQ-001 through REQ-090" (90 total REQs). REQ-090 does not exist as a named requirement — the count of 90 is reached by counting all lettered sub-REQs (050a/b/c/d/e/f, 055a/b/c/d, 063a/b/c/d, etc.) plus the base REQs 001–073. The gap REQ-074 through REQ-089 is confirmed absent from requirements.md. Test-plan correctly covers all existing REQ identifiers.

**15 sampled REQs verified:**
| REQ | Scenario | Key assertion verified |
|-----|----------|----------------------|
| REQ-001 | v6.9.0-license-file-exists.sh | `grep -q '^MIT License$'`, copyright line, permission grant, warranty disclaimer |
| REQ-026 | v6.9.0-jira-regex-dot-only-reject.sh | `.` `..` `...` `....` all rejected via bash `=~` |
| REQ-036 | v6.9.0-outcome-failed-trap.sh | `Step Z: Catastrophic exit handler` in all 3 pipeline skills |
| REQ-040 | v6.9.0-needs-clarification-fixer.sh | `core/agent-states.md` existence + Pause-State Contract heading |
| REQ-043 | v6.9.0-needs-clarification-dos-cap.sh | `clarifications_consumed`, `last_clarification_iteration` in state/schema.md |
| REQ-052 | v6.9.0-pipeline-history-credential-redaction.sh | All 14 redaction tag strings present + POSIX check on function body |
| REQ-055a | v6.9.0-pipeline-history-pii-scope.sh | block.detail bounded to 100 chars in block-handler; sanitize_block_reason() |
| REQ-060a | v6.9.0-arch-freshness-refresh-on-release.sh | NEEDS_CLARIFICATION, pipeline-history, circuit, snippets in architecture.md |
| REQ-063b | h-snippet-citation-marker-format.sh | All 5 snippets have `## Used by:` heading; citation markers present |
| REQ-063d | h-snippet-citation-marker-format.sh | `core/snippets/README.md` rollback + `git show v6.9.0:core/snippets/` recovery |
| REQ-068 | v6.9.0-bc-no-renamed-section.sh | **ABSENT** — no version == "6.9.0" assertion (see F-02) |
| REQ-070 | v6.9.0-bc-no-new-required-key.sh | 5 required sections present; no unexpected new required sections |
| REQ-071 | v6.9.0-bc-no-renamed-section.sh | All 18 existing optional sections + Pause Limits as 19th |
| REQ-072 | v6.9.0-bc-no-removed-webhook-event.sh | All 5 webhook event names preserved |
| REQ-073 | v6.9.0-bc-no-removed-agent-output.sh | Acceptance Criteria in triage-analyst.md; AC Fulfillment in reviewer.md |

### Critical security ACs covered by tests: PASS

**AC-026 (Jira regex dot-only reject):** `v6.9.0-jira-regex-dot-only-reject.sh` tests `.` `..` `...` `....` rejection and `PROJ.NAME-123` acceptance via bash `=~` guard. PASS.

**AC-043, AC-045, AC-046 (NEEDS_CLARIFICATION DoS caps):** `v6.9.0-needs-clarification-dos-cap.sh` covers `clarifications_consumed` + `last_clarification_iteration` in schema, per-run cap (>=3 → block) in `core/agent-states.md`, and per-iteration cap (2nd in same iteration → block). PASS.

**AC-052 (14-pattern credential redaction):** `v6.9.0-pipeline-history-credential-redaction.sh` lists all 14 redaction tags and greps for each in `core/post-publish-hook.md`. Also includes functional bash `=~` pattern checks for URL creds, Bearer, AWS AKID, GitHub token, JWT, Stripe live key. PASS with minor caveat (see F-03).

**AC-052a (POSIX-only sed):** Covered in both `v6.9.0-pipeline-history-credential-redaction.sh` (Assertion 3: awk extraction of function body + grep for `\b|\S|\d|\w`) and `h-credential-redaction-bsd-compatible.sh` (hidden). CONDITIONAL_PASS (see F-03 for awk fragility).

**AC-055a/b/c/d (block.detail 4-channel exclusion):** `v6.9.0-pipeline-history-pii-scope.sh` covers all 4 channels:
- 55a: tracker block COMMENT bounded to 100 chars + sanitize_block_reason
- 55b: pipeline-completed payload excludes block.detail
- 55c: pipeline-history.md excludes block.detail
- 55d: INCLUDE/EXCLUDE table with >=6 channel rows in state/schema.md
PASS.

**AC-080a/b/c/d (CHANGELOG completeness):** `v6.9.0-changelog-completeness.sh` checks: v6.9.0 entry heading format with em dash, MINOR sub-header, all 5 section headers, 13 Added terms, 7 Changed terms, 3 Known Issues deferral terms, Sensitive field exclusion contract citation, 15→16 count change. PASS.

### BC NEGATIVE invariants: PASS

All 4 BC invariants (REQ-070..073) have dedicated scenarios:
- `v6.9.0-bc-no-new-required-key.sh` → REQ-070
- `v6.9.0-bc-no-renamed-section.sh` → REQ-071
- `v6.9.0-bc-no-removed-webhook-event.sh` → REQ-072
- `v6.9.0-bc-no-removed-agent-output.sh` → REQ-073
All verified by reading scenario files. PASS.

---

## Quality

### Hidden REPO_ROOT 3-level: PASS

All 8 hidden scenarios verified to use `../../../` (3 levels up from `.forge/phase-5-tdd/tests-hidden/` to repo root):

```
h-block-handler-heredoc.sh:9: REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../" && pwd)"
h-circuit-breaker-no-deadlock.sh:8: REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../" && pwd)"
h-credential-redaction-bsd-compatible.sh:8: REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../" && pwd)"
h-jira-regex-fuzz.sh:8: REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../" && pwd)"
h-license-spdx-roundtrip.sh:8: REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../" && pwd)"
h-needs-clarification-state-additive.sh:8: REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../" && pwd)"
h-pipeline-history-no-pii.sh:8: REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../" && pwd)"
h-snippet-citation-marker-format.sh:8: REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../" && pwd)"
```

All use `${BASH_SOURCE[0]}` (robust under `source` invocation) rather than `$0`. PASS.

Note: canonical visible scenarios use `"$(dirname "$0")/../../"` (2 levels from `tests/scenarios/`). Both are correct for their respective directory depths.

### set -euo pipefail: PASS

All 5 sampled visible scenarios (`v6.9.0-license-file-exists.sh`, `v6.9.0-security-md.sh`, `v6.9.0-outcome-failed-trap.sh`, `v6.9.0-pipeline-paused-webhook.sh`, `v6.9.0-arch-freshness-warning.sh`) use `set -uo pipefail` at line 5. All exit via `exit "$FAIL"` (non-zero on failure). Note: `set -e` is intentionally omitted in most scenarios to allow the `fail()` accumulator pattern; `set -uo pipefail` is the correct harness-compatible form. PASS.

### Read-only: PASS

No visible or hidden scenario writes to repository files. Checked:
- All `>>` redirects in 5 sampled visible scenarios: only `>&2` and `> /dev/null` found.
- `h-needs-clarification-state-additive.sh` uses `mktemp -d` + `trap 'rm -rf "$TMPDIR_TEST"' EXIT INT TERM` for write operations (correct: temp dir only).
- `h-pipeline-history-no-pii.sh` uses `mktemp -d` + trap for PII simulation.
- No scenario writes to `tests/scenarios/`, `skills/`, `agents/`, `core/`, `state/`, or `CLAUDE.md`.

PASS.

### Diagnostic precision: PASS

All sampled scenarios use the `fail() { echo "FAIL: $1" >&2; FAIL=1; }` pattern with AC-tagged messages. Examples:
- `fail "AC-026: dot-only reject guard '! \"\$ISSUE_ID\" =~ ^\\.+\$' not found in any of the 4 skill files or canonical snippet"`
- `fail "AC-052: core/post-publish-hook.md missing redaction tag '$tag'"`
- `fail "AC-043: state/schema.md missing 'clarifications_consumed' DoS cap field"`

All failure messages identify the AC, the file, and the specific missing content. PASS.

### Skeleton conformance: PASS

All sampled scenarios follow the canonical `v681-*` patterns:
- `#!/usr/bin/env bash` shebang
- Header comment block with `# Scenario:` / `# Expected` / `# Pre-implementation` / `# Traces:`
- `set -uo pipefail`
- `REPO_ROOT` with `$(dirname "$0")/../../`
- `FAIL=0` + `fail()` accumulator
- Assertion blocks with `echo "--- Assertion N (AC-NNN): description ---"`
- `echo "OK (AC-NNN): ..."` for passing checks
- Final `if [ "$FAIL" -eq 0 ]; then echo "PASS: ..."; fi; exit "$FAIL"`

PASS.

---

## Edge cases

### Count consistency: CONDITIONAL_PASS

**Test-plan.md header claims:** `"30 visible + 8 hidden = 38 scenarios"`
**Actual on filesystem:** 40 visible (`tests/scenarios/v6.9.0-*.sh`) + 8 hidden = 48 scenarios.

The traceability table body correctly references all 40 visible files; the discrepancy is in the test-plan header summary only. Every file in the traceability table exists on disk (verified by diffing extracted filenames against FS listing — match is exact except for the executable `*` suffix shown by `ls`).

The increased count (40 vs 30) is a positive outcome: more coverage, not less. REQ-069 requires ≥161 total harness scenarios. Baseline was 141 (plus 1 modified v681 file = 142); adding 40 new v6.9.0 visible scenarios yields 182 total, comfortably exceeding the 161 target.

**Fix required:** Update test-plan.md header to `"40 visible + 8 hidden = 48 scenarios"` and the Coverage verification section accordingly.

### Scope discipline: PASS

Git status confirms all new/modified files are confined to:
- `tests/scenarios/v6.9.0-*.sh` (40 new visible scenarios)
- `.forge/phase-5-tdd/tests-hidden/h-*.sh` (7 new hidden + 1 modified)
- `.forge/phase-5-tdd/test-plan.md` (modified)
- `.forge/phase-5-tdd/mutation-report.md` (modified)
- `.forge/` pipeline artifacts (expected forge state)

No modifications to `skills/`, `agents/`, `core/`, `state/`, `CLAUDE.md`, `README.md`, or any other implementation file. PASS.

---

## Findings

### F-01 [LOW] — test-plan.md header count stale (30 → 40 visible)

**Location:** `.forge/phase-5-tdd/test-plan.md` lines 3-4 and line 136-137
**Issue:** Header says `"30 visible + 8 hidden = 38 scenarios"` and Coverage verification says `"30 visible + 8 hidden = 38 total"`. Actual count is 40 visible + 8 hidden = 48.
**Impact:** Documentation inconsistency only; all 40 files exist and are correctly traced in the body table. Phase 8 verifier sees 48 scenarios.
**Action:** Update header + coverage footer to read `40 visible + 8 hidden = 48 total`. Fix before Phase 8.

### F-02 [MEDIUM] — REQ-068 (version 6.9.0 bump) has no functional assertion

**Location:** test-plan.md line 97 → `v6.9.0-bc-no-renamed-section.sh`
**Issue:** AC-068 requires:
```
[[ "$(jq -r '.version' .claude-plugin/plugin.json)" == "6.9.0" ]]
[[ "$(jq -r '.plugins[0].version' .claude-plugin/marketplace.json)" == "6.9.0" ]]
git tag -l v6.9.0
```
The mapped scenario (`bc-no-renamed-section.sh`) covers REQ-071 (optional section names) and makes no version assertions. The test-plan annotation `"version 6.9.0 in plugin.json + marketplace.json (checked as BC-adjacent count)"` is factually incorrect about what the scenario actually checks.
**Severity:** MEDIUM — a release-gate REQ with no test means Phase 8 verification will have no automated harness check for version correctness.
**Action:** Add assertions to either `v6.9.0-bc-no-renamed-section.sh` or a new dedicated scenario. Recommend adding to existing scenario as Assertion 5, or creating `v6.9.0-version-bump.sh`. Fix before Phase 8.

### F-03 [LOW] — AC-052a POSIX check uses awk range pattern fragile in markdown

**Location:** `v6.9.0-pipeline-history-credential-redaction.sh` lines 56-67
**Issue:** `awk '/sanitize_block_reason\(\)/,/^}/' "$POST_HOOK"` extracts the function body from a markdown (prose) file. Markdown code blocks use fenced ` ``` ` delimiters; the function body may not end with `^}` at line start in a markdown prose file. If the function is documented as a code fence block, `^}` won't match and the extraction will return the entire remainder of the file, producing false negatives.
**Impact:** The POSIX portability check (AC-052a) may not actually examine the function body correctly if Phase 7 documents `sanitize_block_reason()` as a markdown code block without a `^}` at line start.
**Action:** Phase 7 implementer should ensure `sanitize_block_reason()` is in a code block whose closing `}` is on its own line at column 0, OR Phase 5 should augment with `grep -A100 'sanitize_block_reason' | head -100` as a fallback. Advisory.

### F-04 [LOW] — h-snippet-citation-marker-format.sh uses non-deterministic associative array iteration

**Location:** `.forge/phase-5-tdd/tests-hidden/h-snippet-citation-marker-format.sh` Assertion 4
**Issue:** Bash associative arrays (`declare -A`) have non-deterministic iteration order (`for name in "${!expected_counts[@]}"`). This is functionally correct (all 5 keys are checked) but the output order varies across runs, making log comparison harder.
**Impact:** No correctness impact; purely cosmetic. Assertion 4's `if [ "$actual_count" -eq "$expected" ]` logic is correct.
**Action:** Optional — replace with explicit ordered list if log determinism is required for Phase 8 comparison. Not blocking.

---

## JSON verdict

```json
{
  "phase": "5-tdd",
  "verdict": "CONDITIONAL_PASS",
  "revision_required": false,
  "conditions": [
    {
      "id": "F-02",
      "severity": "MEDIUM",
      "description": "REQ-068 (version 6.9.0 bump) has no functional assertion in any scenario",
      "action": "Add version == 6.9.0 assertion to v6.9.0-bc-no-renamed-section.sh or new v6.9.0-version-bump.sh before Phase 8",
      "blocking_for": "phase-8"
    },
    {
      "id": "F-01",
      "severity": "LOW",
      "description": "test-plan.md header count says 30+8=38 but actual is 40+8=48",
      "action": "Update test-plan.md header and coverage footer counts",
      "blocking_for": "phase-8"
    }
  ],
  "spec_compliance": {
    "req_coverage": "CONDITIONAL_PASS",
    "missing_reqs": ["REQ-068 functional assertion absent from all 48 scenarios"],
    "critical_security_acs": "PASS",
    "bc_negative_invariants": "PASS"
  },
  "quality": {
    "hidden_repo_root_3_level": "PASS",
    "set_euo_pipefail": "PASS",
    "read_only": "PASS",
    "diagnostic_precision": "PASS",
    "skeleton_conformance": "PASS"
  },
  "edge_cases": {
    "count_consistency": "CONDITIONAL_PASS",
    "scope_discipline": "PASS"
  },
  "scenario_counts": {
    "visible_actual": 40,
    "visible_claimed_in_header": 30,
    "hidden_actual": 8,
    "hidden_claimed": 8,
    "total_actual": 48,
    "harness_baseline": 141,
    "harness_with_new": 182,
    "req_069_target": 161,
    "req_069_met": true
  },
  "req_coverage": {
    "total_reqs_in_spec": 90,
    "highest_base_req": "REQ-073",
    "sub_items_covered": ["REQ-027a/b", "REQ-050a-f", "REQ-055a-d", "REQ-060a", "REQ-063a-d", "REQ-064a"],
    "all_covered_in_table": true,
    "functional_gap": "REQ-068"
  }
}
```

---

DONE
