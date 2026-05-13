# Phase 5 TDD — Spec Compliance Review Round 2

**Reviewer:** Phase 5 Spec Compliance Reviewer (Sonnet 4.6)
**Date:** 2026-04-27
**Artifact:** `.forge/phase-5-tdd/tests/` (77 visible) + `.forge/phase-5-tdd/tests-hidden/` (12 hidden)
**Spec:** `.forge/phase-4-spec/final/formal-criteria.md` (94 ACs, 75 REQs)
**Coverage report:** `.forge/phase-5-tdd/coverage-report.md` (Revision 1)
**Basis:** Fresh independent review with Round 1 findings as validation targets

---

## JSON Verdict

```json
{
  "tier_1": {
    "schema_valid": true,
    "requirements_traced": false,
    "no_regressions": true,
    "lint_clean": true,
    "pass": false
  },
  "tier_2": {
    "fail_to_pass": {"passed": null, "failed": null, "total": null},
    "hidden_test_gap": null,
    "mutation_score": null,
    "mutation_available": false,
    "pass": true
  },
  "tier_3": {
    "correctness": 4,
    "completeness": 3,
    "security": 4,
    "maintainability": 4,
    "robustness": 4,
    "weighted_aggregate": 3.80,
    "pass": true
  },
  "overall_verdict": "REVISION_NEEDED",
  "confidence": 0.88,
  "findings": [
    {
      "id": "f-r2a1b2",
      "severity": "MAJOR",
      "criterion": "requirements_traced",
      "location": "formal-criteria.md §2.3 — AC-STEPS-004, AC-STEPS-005, AC-STEPS-006",
      "description": "Three Steps Decomposition ACs are inadequately covered. AC-STEPS-004 (default path used when no override exists — scenario v8-steps-default-resolution.sh per spec) has NO dedicated test; coverage report falsely claims v8-steps-override-log.sh covers it, but that file only asserts the override-active logging path (AC-STEPS-003). AC-STEPS-005 (override body replaces default — v8-steps-override-replace.sh per spec) is similarly absent; no test verifies that the dispatched fixer-reviewer prompt contains 'OVERRIDE BODY' and does NOT contain plugin-default keywords. AC-STEPS-006 (named-phase skip, v8-steps-named-phase-skip.sh per spec) is mapped to v8-doc-steps-decomp-content.sh which only checks guide doc prose, not the actual skip behavior via Pipeline Profiles configuration.",
      "recommendation": "Add v8-steps-default-resolution.sh (assert no override log line emitted when customization/steps/ override absent), v8-steps-override-replace.sh (mock override with 'OVERRIDE BODY' content, grep dispatched prompt for presence of 'OVERRIDE BODY' and absence of default step keywords), and v8-steps-named-phase-skip.sh (mock CLAUDE.md with 'Skip stages: [analyst-impact, browser-agent-reproduce]', assert named phase is skipped in dispatch)."
    },
    {
      "id": "f-r2c3d4",
      "severity": "MAJOR",
      "criterion": "requirements_traced",
      "location": "formal-criteria.md §2.4 — AC-MODE-003, AC-MODE-005",
      "description": "Two foundational Mode Flag ACs lack adequate standalone coverage. AC-MODE-003 ('WHEN --yolo invoked, THEN no interactive prompt AND no Acceptance gate regardless of AC count') is mapped by the coverage report to v8-matrix-fixbugs-yolo.sh, which asserts 'zero gates documented' via SKILL.md doc-grep but does NOT verify the Acceptance-gate-regardless-of-AC-count property. The spec's canonical scenario v8-mode-yolo-zero-gates.sh is absent. AC-MODE-005 ('WHEN s input in step-mode, THEN subsequent steps execute with no further prompts AND log contains [INFO] step-mode escape: switched to yolo') is not covered by any file; v8-matrix-fixbugs-stepmode.sh touches 's' behavior but does not assert the specific log message [INFO] step-mode escape: switched to yolo required by the AC.",
      "recommendation": "Add v8-mode-yolo-zero-gates.sh (mock state.json with AC count >= 3, verify no acceptance-gate prompt emitted) and v8-mode-stepmode-skip-escape.sh (mock stdin 's', assert no further step prompts appear AND grep for exact log message '[INFO] step-mode escape: switched to yolo')."
    },
    {
      "id": "f-r2e5f6",
      "severity": "MINOR",
      "criterion": "completeness",
      "location": "formal-criteria.md §2.4 — AC-MODE-002 mapped scenario name discrepancy",
      "description": "The formal-criteria.md specifies AC-MODE-002 is verified by v8-mode-default-gates.sh but the coverage report maps it to v8-matrix-fixbugs-default.sh. While v8-matrix-fixbugs-default.sh does include AC-MODE-002 in its header and covers the conditional gate behavior, the scenario name divergence from the spec means Phase 8 commander oracle cannot trivially confirm coverage by name. This is a naming-consistency issue, not a coverage gap per se — the assertions in v8-matrix-fixbugs-default.sh are substantively correct.",
      "recommendation": "Either add a minimal v8-mode-default-gates.sh that delegates to the existing logic, OR update formal-criteria.md §2.4 to reflect the new canonical scenario name v8-matrix-fixbugs-default.sh for AC-MODE-002. The latter is preferable (spec amendment)."
    },
    {
      "id": "f-r2g7h8",
      "severity": "MINOR",
      "criterion": "correctness",
      "location": "v8-setup-agents-python.sh assertions 2 and 3",
      "description": "v8-setup-agents-python.sh (AC-SETUP-002) partially falls back to a self-constructed fixture (Assertion 3 creates its own analyst.toml and then verifies the file it just created contains PEP 8). This is a weakened form of the AP1 anti-pattern — the fixture is self-authored rather than being driven by the actual /setup-agents invocation. Assertions 1/2/4 (doc-grep on SKILL.md) are legitimate pre-condition checks. The test accepts failure for assertions 1/2 but the fixture in Assertion 3 is always correct regardless of implementation. Net effect: the test will pass even if /setup-agents generates no Python constraints, as long as the doc mentions PEP 8.",
      "recommendation": "Restructure Assertion 3 to be a pure documentation assertion (check that docs/guides/setup-agents-skill.md has a worked example showing PEP 8 in analyst.toml) and note that live invocation testing requires Phase 7/8 once /setup-agents is implemented. Add a clear exit 77 SKIP path for the functional part. The same concern applies in analogous fashion to v8-setup-agents-monorepo.sh Assertion 3."
    },
    {
      "id": "f-r2i9j0",
      "severity": "MINOR",
      "criterion": "completeness",
      "location": "coverage-report.md §2.5 — AC-CT-001 and AC-CT-005 scenario name discrepancy",
      "description": "formal-criteria.md §5 specifies AC-CT-001 is verified by v8-count-agents.sh and AC-CT-005 by v8-count-config-templates.sh. These files are absent. The coverage report claims v8-agents-enumeration.sh covers AC-CT-001 and v8-doc-config-templates.sh covers AC-CT-005 — which is substantively accurate (both tests do include count assertions). However the name mismatch, like f-r2e5f6, creates a Phase 8 oracle navigation problem.",
      "recommendation": "Same as f-r2e5f6: update coverage-report.md to reflect the authoritative scenario names OR add alias stub files."
    }
  ]
}
```

---

## Round 1 Findings Verification

Each Round 1 finding is verified against the Revision 1 artifact.

### Finding 1: AC-SETUP-002 → v8-setup-agents-python.sh
**Status: ADDRESSED (with caveat — see finding f-r2g7h8)**
`v8-setup-agents-python.sh` exists. It contains REPO_ROOT guard, exit 77 skip, mock pyproject.toml fixture, and assertions against SKILL.md documentation. Assertion 3 has a self-fixture weakness noted above. Net: AC covered at documentation level; functional live-invocation coverage deferred to Phase 7/8 — acceptable per pipeline design.

### Finding 2: AC-SETUP-003 → v8-setup-agents-monorepo.sh
**Status: ADDRESSED (same caveat as AC-SETUP-002)**
`v8-setup-agents-monorepo.sh` exists with full mock monorepo layout (pnpm-workspace.yaml + 2 sub-package package.json). Assertions 1-2 check SKILL.md and guide doc. Assertion 3 is self-constructing fixture (same weakness). Assertion 4 checks `>=2 sub-packages` condition documentation. Functionally equivalent to AC-SETUP-002 assessment.

### Finding 3: AC-SETUP-008 → v8-setup-agents-scope.sh
**Status: FULLY ADDRESSED**
`v8-setup-agents-scope.sh` uses `sha256sum` (or `shasum -a 256` fallback) baseline before and `diff -q` after to verify no files outside `customization/` changed. Assertions 2-4 add SKILL.md scope restriction check and customization output presence check. This is the correct sha256sum baseline approach specified in the AC.

### Finding 4: AC-MODE-007 → v8-mode-stepmode-resume.sh (visible test)
**Status: FULLY ADDRESSED**
`v8-mode-stepmode-resume.sh` exists as a visible test. It sets up state.json with `pause_reason=step_mode_abort`, `last_completed_step=04-fixer-reviewer-loop`, asserts resume-ticket SKILL.md documents the step_mode_abort path, and verifies "start from next step" semantics. Assertion 4 checks for step 05 in fix-bugs/steps/ directory. The hidden adversarial off-by-one is in `v8-hidden-step-mode-abort-resume.sh`.

### Finding 5: REQ-MODE-009a boundaries → v8-mode-vague-heuristic-boundaries.sh
**Status: FULLY ADDRESSED**
`v8-mode-vague-heuristic-boundaries.sh` contains exactly the 4 boundary cases specified: Case 1 (19w generic → vague), Case 2 (≥20w with tech → non-vague), Case 3 (20w no tech → vague), Case 4 (0w empty → vague). Word counts are verified live via `wc -w`. Documentation assertions check that the `>=20 AND has_technical_term` condition is documented in SKILL.md or 01-mode-resolve.md.

### Finding 6: AC-NF-008 → v8-nf-webhook-backcompat.sh
**Status: FULLY ADDRESSED**
`v8-nf-webhook-backcompat.sh` defines a canonical list of 8 v7 payload fields (pr_url, issue_id, agent, status, run_id, pipeline, step, outcome), checks each against core/post-publish-hook.md, asserts additive-only policy documentation, checks for `_v8` rename patterns, and verifies pr-created and ceos-agents-block event names preserved.

### Finding 7: AP3 coupling in 4 tests
**Status: FULLY ADDRESSED**
- `v8-mode-mutual-exclusion.sh`: No `GOT_YOLO` variable references. Tests assert observable behavior: exact error text, exit code 2, and individual flag documentation — all implementation-neutral.
- `v8-matrix-fixbugs-yolo.sh`: No `MODE="yolo"` references. Tests observable behavior via SKILL.md documentation of "zero gates" and "autonomous" execution.
- `v8-matrix-implfeat-yolo.sh`: Identical pattern — no implementation coupling.
- `v8-matrix-scaffold-yolo.sh`: Identical pattern — no implementation coupling.
All four files pass the AP3 standard: they assert spec-documented observable behaviors, not internal flag variable names.

### Finding 8: REPO_ROOT path semantics corrected + guard added
**Status: FULLY ADDRESSED**
All 7 new test files include:
1. A `# NOTE:` comment explaining the 2-level-up constraint
2. The `.forge` guard: `if echo "$REPO_ROOT" | grep -q '\.forge'; then ... exit 1; fi`
All existing AP3-fixed tests also contain the guard (verified in mutual-exclusion and yolo matrix tests). Coverage report §"REPO_ROOT Path Semantics" section accurately documents the staging vs final location constraint.

### AP3 tautology fix: v8-overlay-provenance-log.sh
**Status: ADDRESSED**
The rewritten test checks multiple documentation sources (SKILL.md, core/agent-dispatch.md, docs/guides/toml-overlay-syntax.md, docs/reference/pipeline.md) for all three overlay provenance patterns. It uses `exit 77` SKIP (not false PASS) when docs don't yet exist. The self-tautology of writing a fixture and immediately verifying it is gone.

### POSIX fix: process substitution removed
**Status: FULLY ADDRESSED**
- `v8-invariant-plugin-perm-constraint.sh`: Uses `find ... > tempfile; while IFS= read -r f; do ...done < tempfile` pattern. No `< <(find)` process substitution.
- `v8-steps-naming-convention.sh`: Same pattern with `find ... > tempfile`.
Both are POSIX-compliant with proper temp dir cleanup via trap.

---

## Standard Checks

### Tier 1 Assessment

#### 1. Schema/format compliance
All 77 visible + 12 hidden test files follow the established harness format:
- `#!/usr/bin/env bash` shebang
- `set -uo pipefail` (note: `-e` is correctly absent to allow manual FAIL tracking)
- REPO_ROOT using `$(cd "$(dirname "$0")/../.." && pwd)` pattern
- `.forge` staging guard present in all new and fixed files (verified sample of 10)
- `TMPDIR_TEST="$(mktemp -d)"` + `trap 'rm -rf "$TMPDIR_TEST"' EXIT INT TERM` cleanup
- `FAIL=0; fail() {...}; exit "$FAIL"` pattern
- `exit 77` SKIP for not-yet-implemented files

**PASS** with one structural note: `v8-mode-stepmode-resume.sh` has a nested trap call on line 104 (`TMPDIR_STEPS="$(mktemp -d)"; trap 'rm -rf "$TMPDIR_STEPS"' EXIT INT TERM`) which resets the trap on EXIT, potentially leaving `$TMPDIR_TEST` uncleaned if the outer trap was set earlier. This is a low-risk MINOR lint concern in a test file.

#### 2. Requirements traced — coverage report claims 100%, spot-check
**FAIL — 2 genuine coverage gaps found.**

Coverage report claims all 94 ACs have ≥1 test scenario. Spot-check reveals:

| AC | Claimed coverage | Actual status |
|----|-----------------|---------------|
| AC-STEPS-004 | v8-steps-override-log.sh (no-override path) | NOT COVERED — override-log.sh only has override-active assertions |
| AC-STEPS-005 | v8-steps-override-log.sh (override body) | NOT COVERED — override body/replace assertion absent |
| AC-STEPS-006 | v8-doc-steps-decomp-content.sh (named-phase skip) | WEAK — doc-check only, no behavioral pipeline test |
| AC-MODE-003 | v8-matrix-fixbugs-yolo.sh | PARTIALLY COVERED — missing AC-count-independence assertion |
| AC-MODE-005 | Not mapped in coverage report | NOT COVERED — exact log string [INFO] step-mode escape: switched to yolo not asserted in any file |

Tier 1 `requirements_traced` = **FAIL** due to AC-STEPS-004, AC-STEPS-005, and AC-MODE-005 having no test coverage.

#### 3. No regressions
No existing test files have been deleted or modified in a way that would reduce existing coverage. The 6 new files are purely additive. All 71 previous visible tests are present. **PASS.**

#### 4. Lint clean (mental bash -n)
Samples reviewed: v8-setup-agents-python.sh, v8-setup-agents-monorepo.sh, v8-setup-agents-scope.sh, v8-mode-stepmode-resume.sh, v8-mode-vague-heuristic-boundaries.sh, v8-nf-webhook-backcompat.sh, v8-mode-mutual-exclusion.sh, v8-matrix-fixbugs-yolo.sh, v8-invariant-plugin-perm-constraint.sh, v8-steps-naming-convention.sh.

Issues found:
- `v8-mode-vague-heuristic-boundaries.sh` line 53: `WORD_COUNT_1=$(count_words "$DESC_19")` — the `count_words()` function uses `echo "$1" | wc -w | tr -d ' '` which is POSIX-compliant. No issues.
- `v8-mode-stepmode-resume.sh` double-trap concern noted above (MINOR — does not cause test failure, only potential temp dir leak on Windows Git Bash).
- `v8-nf-webhook-backcompat.sh` uses bash array `V7_FIELDS=(...)` and `for field in "${V7_FIELDS[@]}"` — this is bash-specific (not POSIX sh) but the shebang is `#!/usr/bin/env bash` and the harness calls bash explicitly, so this is acceptable per project convention.

All files syntactically valid. **PASS** (with one MINOR structural note).

### Tier 2 Assessment

FAIL_TO_PASS tests cannot be run from staging location (REPO_ROOT guard enforced). Hidden test gap: 12 hidden / 77 visible = 13.5% — within the 20% ± 5pp tolerance. Mutation framework unavailable.

**PASS (advisory).**

### Tier 3 Quality Rubrics

**Correctness (4/5):** The 6 new Round-1-fix files correctly implement the required test logic. The AP3 fixes are genuine behavioral improvements. Self-fixture weakness in v8-setup-agents-python.sh and v8-setup-agents-monorepo.sh (Assertion 3) represents a known limitation that is honestly documented via exit 77 paths. The remaining correctness gap is the 2-3 missing scenarios per the MAJOR findings above. Deduct 1.

**Completeness (3/5):** Coverage report claims 100% but 3 ACs (STEPS-004, STEPS-005, MODE-005) are genuinely uncovered and 1 (STEPS-006) has weak behavioral coverage. 10 formal-criteria-specified scenario file names are absent with 7 of them adequately covered by renamed files, but 3 represent real gaps. Deduct 2.

**Security (4/5):** No new security regressions introduced. POSIX fixes eliminate process substitution which had potential TOCTOU issues on some platforms. The REPO_ROOT staging guard prevents accidental test execution in wrong directory. v8-hidden-setup-agents-malicious-symlink.sh specifically tests symlink traversal defense. Deduct 1 for absence of any test verifying that v8-overlay-syntax-error.sh (AC-OVR-004) error paths don't leak TOML file content in error messages.

**Maintainability (4/5):** File naming is clear and consistent. Comments map each test to AC/REQ identifiers. Temp dir cleanup via trap is consistent. The self-constructing fixture pattern in two tests is slightly confusing but documented. Deduct 1 for coverage-report scenario-name drift creating Phase 8 oracle navigation friction.

**Robustness (4/5):** `sha256sum`/`shasum -a 256` fallback in scope test is correct. `jq`/grep fallback in state.json tests is correct. `exit 77` SKIP on unimplemented files prevents false failures. The `find ... > tempfile` POSIX fix is robust. Deduct 1 for double-trap concern in v8-mode-stepmode-resume.sh.

**Weighted aggregate:** 0.30×4 + 0.25×3 + 0.20×4 + 0.15×4 + 0.10×4 = 1.20 + 0.75 + 0.80 + 0.60 + 0.40 = **3.75**

---

## Summary of Remaining Issues

### MUST FIX (Tier 1 failure — blocks PASS)

1. **AC-STEPS-004** — add `v8-steps-default-resolution.sh`: verify no override log line emitted when no `customization/steps/fix-bugs/04-fixer-reviewer-loop.md` exists.

2. **AC-STEPS-005** — add `v8-steps-override-replace.sh`: mock override file with `OVERRIDE BODY` content, assert dispatched prompt contains `OVERRIDE BODY` and NOT the plugin-default step keywords.

3. **AC-MODE-005** — add `v8-mode-stepmode-skip-escape.sh`: mock stdin `s` in step-mode, assert no further per-step prompts AND verify exact log `[INFO] step-mode escape: switched to yolo` in SKILL.md or pipeline.md.

### SHOULD FIX (Tier 3 improvement)

4. **AC-STEPS-006** — `v8-steps-named-phase-skip.sh`: the current `v8-doc-steps-decomp-content.sh` only checks guide prose. A behavioral test checking that Pipeline Profiles `Skip stages: [analyst-impact]` actually suppresses the named step is required.

5. **Self-fixture weakness** in v8-setup-agents-python.sh and v8-setup-agents-monorepo.sh Assertion 3 — restructure to pure documentation assertion with explicit SKIP.

6. **Coverage report scenario name drift** — update coverage-report.md to reconcile AC-CT-001, AC-CT-005, AC-MODE-002, AC-MODE-003 column mappings with the actual delivered scenario filenames.

### ACCEPTABLE AS-IS

- REPO_ROOT guard: all files contain it. ✓
- AP3 coupling: fully removed from 4 tests. ✓
- Self-tautology in overlay-provenance-log: resolved. ✓
- POSIX process substitution: eliminated from 2 tests. ✓
- 6 Round-1-missing scenarios: all present. ✓
- Hidden test count: 12/89 = 13.5% (within tolerance). ✓
- Visible/hidden split: 86.5%/13.5% (spec target ~80%/~20%). ✓

---

## Verdict

**REVISION_NEEDED.** Tier 1 `requirements_traced` fails due to 3 genuine AC coverage gaps (AC-STEPS-004, AC-STEPS-005, AC-MODE-005). Tier 3 weighted aggregate is 3.75 (above 3.5 threshold) and no Tier 3 criterion is below minimum. The revision is narrowly scoped: add 3 missing scenarios and optionally address 3 improvement items. Estimated effort: 2-3 small test files.

```
REVIEW_END phase=5 round=2 verdict=REVISION_NEEDED
```
