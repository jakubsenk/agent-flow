# Phase 5 TDD Review — forge-2026-05-13-001 (v10.2.0 core/ Path Disambiguation)

**Reviewer:** Phase 5 Commander  
**Date:** 2026-05-13  
**Artifact set:** 3 visible + 2 hidden = 5 test files  
**Reference spec:** formal-criteria.md (27 FCs across FC-A..FC-E)

---

## JSON Verdict

```json
{
  "review_id": "review-1",
  "forge_run": "forge-2026-05-13-001",
  "tier_1_spec_compliance": "CONDITIONAL_PASS",
  "tier_3_quality_aggregate": "PASS_WITH_FINDINGS",
  "overall_verdict": "CONDITIONAL_PASS",
  "confidence": 0.84,
  "findings_count": {
    "CRITICAL": 0,
    "HIGH": 2,
    "MEDIUM": 3,
    "LOW": 4
  },
  "fc_coverage_gaps": [
    "FC-A-4",
    "FC-B-6",
    "FC-B-8",
    "FC-D-1",
    "FC-D-2",
    "FC-D-3",
    "FC-D-4",
    "FC-E-1",
    "FC-E-2",
    "FC-E-3",
    "FC-E-4",
    "FC-E-5"
  ],
  "fc_coverage_ratio": "15/27 = 55.6%",
  "pre_phase7_graceful": true
}
```

---

## FC Coverage Matrix

| FC ID | Description (abbrev) | Covered by | Status |
|-------|----------------------|-----------|--------|
| FC-A-1 | `<PREFLIGHT>` in 3 guard files | v10-guard-block-fail-loud.sh ASSERT-1, ASSERT-AGG | COVERED |
| FC-A-2 | `[ ! -r "..." ]` probe shape in 3 files | v10-guard-block-fail-loud.sh ASSERT-2 | COVERED |
| FC-A-3 | Canonical abort message + exit 2 | v10-guard-block-fail-loud.sh ASSERT-3, ASSERT-4 | COVERED |
| FC-A-4 | `scaffold/SKILL.md` Read-tool directive at line 11 | **NONE** | **GAP** |
| FC-A-5 | B3 documentary clarifier in 3 guard files | v10-guard-block-fail-loud.sh ASSERT-5 | COVERED |
| FC-A-6 | Depth-3 PROBE assignment verbatim in all 3 | v10-guard-block-fail-loud.sh ASSERT-6 | COVERED |
| FC-B-1 | Zero bare `core/X.md` in skills/ + agents/ | v10-core-path-depth-consistency.sh ASSERT-1 | COVERED |
| FC-B-2 | Depth-1 prefix correct in `agents/*.md` | v10-core-path-depth-consistency.sh ASSERT-2 | COVERED |
| FC-B-3 | Depth-2 prefix correct in `skills/*/SKILL.md` | v10-core-path-depth-consistency.sh ASSERT-3; v10-dual-pattern-line.sh ASSERT-1 | COVERED |
| FC-B-4 | Depth-3 prefix correct in `skills/*/steps/*.md` | v10-core-path-depth-consistency.sh ASSERT-4; v10-dual-pattern-line.sh ASSERT-2 | COVERED |
| FC-B-5 | Depth-3 prefix correct in `skills/*/data/*.md` | v10-core-path-depth-consistency.sh ASSERT-5 | COVERED |
| FC-B-6 | Total 188 dotdot-prefixed occurrences post-rewrite | **NONE** | **GAP** |
| FC-B-7 | Idempotency: second sed pass produces no changes | v10-idempotency-second-pass.sh (all asserts) | COVERED |
| FC-B-8 | No `docs/` or `README`/`CHANGELOG` changes from Phase B sed | **NONE** | **GAP** |
| FC-C-1 | `v10-skill-from-external-cwd.sh` exists and passes | v10-skill-from-external-cwd.sh (self-proving) | COVERED |
| FC-C-2 | `v10-core-path-depth-consistency.sh` exists and passes | v10-core-path-depth-consistency.sh (self-proving) | COVERED |
| FC-C-3 | Counterfactual: depth-lint catches corrupted control | v10-core-path-depth-consistency.sh ASSERT-6 | COVERED |
| FC-C-4 | Both new scenarios are POSIX-portable | v10-skill-from-external-cwd.sh ASSERT-3 (meta comment) | PARTIAL* |
| FC-D-1 | No stale "13" scenario count in doc-quartet | **NONE** | **GAP** |
| FC-D-2 | CHANGELOG entry for v10.2.0 present | **NONE** | **GAP** |
| FC-D-3 | Version bumped to 10.2.0 in plugin.json + marketplace.json | **NONE** | **GAP** |
| FC-D-4 | Git tag `v10.2.0` exists | **NONE** | **GAP** |
| FC-E-1 | All 17 agents retain `## Step Completion Invariants` | **NONE** | **GAP** |
| FC-E-2 | `v10-step-completion-invariants-completeness.sh` passes | **NONE** | **GAP** |
| FC-E-3 | Harness reports 0 failed scenarios | **NONE** | **GAP** |
| FC-E-4 | `core/lib/stage-invariant.sh` byte-identical to v10.1.2 | **NONE** | **GAP** |
| FC-E-5 | All 13 existing v10-*.sh scenarios continue to pass | **NONE** | **GAP** |

*FC-C-4: The two new scenarios ARE written portably (no GNU-only flags found empirically), but no explicit runtime assertion verifies this property — it is asserted only via source inspection. Borderline acceptable for a meta-portability FC.

**Coverage summary:** 15/27 FCs have at least one mapped assertion. 12 FCs uncovered.

**Coverage by group:**

| Group | Covered | Total | % |
|-------|---------|-------|---|
| FC-A | 5 | 6 | 83% |
| FC-B | 5 | 8 | 63% |
| FC-C | 3 (+1 partial) | 4 | 75-100% |
| FC-D | 0 | 4 | 0% |
| FC-E | 0 | 5 | 0% |
| **Total** | **15** | **27** | **56%** |

---

## Spec-Compliance Findings

### SC-HIGH-1 — FC-D/FC-E groups entirely uncovered (12 FCs)

FC-D (cross-cutting: CHANGELOG, version bump, git tag, doc-quartet) and FC-E (reliability invariants: harness, stage-invariant byte-identity, scenario count) have zero test coverage across all 5 files. Combined, these represent 12/27 (44%) of the formal criteria.

**Impact:** Phase 7 can ship FC-D/FC-E violations undetected by Phase 5 tests.

**Mitigation:** FC-D and FC-E are largely integration-level checks (git operations, file presence, harness execution). They are harder to pre-write as pure TDD tests before Phase 7 executes. Some FCs (D-2, D-3, E-1, E-3) are straightforward static checks that could have been included in a 6th visible test. However, given the 5-test constraint and that FC-D/FC-E checks are mechanical release-gate checks typically done by the Phase 8 commander, this gap is **architecturally acceptable** but **should be flagged** for Phase 8 to explicitly verify.

**Severity: HIGH** (scope, not design flaw).

### SC-HIGH-2 — FC-A-4 uncovered (scaffold SKILL.md Read-tool directive)

`v10-guard-block-fail-loud.sh` claims `REQ-A-4` coverage but only verifies that `skills/scaffold/data/guard-block.md` EXISTS (ASSERT-7). It does NOT verify that `skills/scaffold/SKILL.md` contains the Read-tool directive at line 11 per FC-A-4. The `FC mapped` header on line 5 correctly omits FC-A-4, but the `Falsifies: REQ-A-4` line in the header is misleading — REQ-A-4 has two sub-requirements (new file + SKILL.md directive) and only the file-existence part is tested.

**Severity: HIGH** (FC-A-4 has zero test coverage; Phase 7 could omit the SKILL.md directive).

### SC-MED-1 — FC-B-6 (188 occurrence count) uncovered

No test verifies the total post-rewrite occurrence count equals 188. This count validates that Phase B hit the exact scope (not under-rewrote by missing files). The FC-B-1/B-2/B-3/B-4/B-5 depth checks confirm per-file correctness but NOT the aggregate count. A Phase B that silently skipped 5 files would pass all 5 tests.

**Severity: MEDIUM**.

### SC-MED-2 — FC-B-8 (no docs/ collateral damage) uncovered

No test checks that Phase B sed did not accidentally touch `docs/`, `README.md`, or `CHANGELOG.md`. Given Phase B processes 40 files under `skills/` and `agents/`, an overly-broad sed glob could accidentally match doc files if the implementer uses a wrong glob. This is a meaningful guard.

**Severity: MEDIUM**.

### SC-MED-3 — FC-C-4 is only meta-asserted (not runtime-checked)

FC-C-4 requires both new scenarios to use POSIX-portable constructs. The `v10-skill-from-external-cwd.sh` header comment says "ASSERT-3: No GNU-only constructs" but this is a comment, not an executed assertion. No test actually runs the scenarios on BSD or Git-Bash and confirms success. The empirical check (this review) found no GNU-only constructs, but the tests themselves do not self-verify portability at runtime.

**Severity: MEDIUM** (the portability is real, but the FC is not asserted by the test suite itself).

---

## Quality Findings

### QA-LOW-1 — `set -e` absent from all 5 files (uses `set -uo pipefail` not `set -euo pipefail`)

All 5 files use `set -uo pipefail` instead of `set -euo pipefail`. The quality criterion requires `set -euo pipefail`. Without `-e`, a mid-script command failure (e.g., a `cp` or `grep` failing unexpectedly) does NOT abort the script — it silently continues and may produce a false PASS.

**Impact:** Moderate. The scripts use explicit `rc=$?` capture and `|| true` guards in critical paths, partially compensating. But unexpected failures in setup code (e.g., fixture mkdir) could produce misleading results.

**Severity: LOW** (consistent across all 5 files, partial mitigation via explicit rc checks).

### QA-LOW-2 — `v10-guard-block-fail-loud.sh` has no `trap cleanup EXIT`

The three files that use tmpdir (`v10-skill-from-external-cwd.sh`, `v10-core-path-depth-consistency.sh`, both hidden) all correctly implement `trap cleanup EXIT`. However, `v10-guard-block-fail-loud.sh` does not use any tmpdir and has no cleanup needed, so the absence is correct and not a defect.

**Severity: INFORMATIONAL** (not a finding; documented for completeness).

### QA-LOW-3 — `(^|[^./])` broken alternation in `v10-core-path-depth-consistency.sh` ASSERT-1

Line 45 uses `grep -rEn '(^|[^./])core/[a-z][a-z-]*\.md'`. The quality criterion flags `(^|[^./])` as "the broken sed alternation form." However, this usage is in `grep -E`, not `sed`, where ERE alternation `(^|[^./])` IS valid and functional (verified empirically: correctly matches `core/foo.md` at line start AND after space, but NOT after `.` or `/`). The criterion was specifically about the sed pattern form — in grep this is correct.

**However:** The criterion text says "Canonical sed pattern used consistently: `s|([^./])core/...|` NOT the broken `(^|[^./])` alternation form." The spirit of this rule extends to grep patterns since the same logic applies. The `(^|[^./])` grep form matches correct lines but the captured match includes the preceding non-`./` character, which is fine for `grep -l` and `grep -n` usage here (line counting, not extraction).

**Actual behavior:** Verified correct. The `(^|[^./])` in grep-E context matches correctly. This is NOT a bug.

**Verdict:** The criterion as written applies to `sed` patterns. In grep context, the form is functionally correct. **No defect.** The wording of quality criterion 6 is ambiguous.

**Severity: LOW** (ambiguity, no actual defect; the test behavior is correct).

### QA-LOW-4 — Double-backslash `\\.md` in double-quoted sed strings in `v10-dual-pattern-line.sh`

Lines 53 and 149 in `v10-dual-pattern-line.sh` use double-quoted sed strings with `\\.md` (two backslashes in the source file). After shell double-quote expansion, sed receives `\.md` which in ERE means literal `.md`. This is **functionally correct** (matches `.md` suffix as intended) but the project's style preference is `([^./])core/([a-z][a-z-]*\.md)` in single-quoted contexts (as used in `v10-idempotency-second-pass.sh` lines 158/179 which use single quotes).

The `check_idempotent` helper in `v10-idempotency-second-pass.sh` uses double-quoted strings with the same `\\.md` encoding (line 68), which is also correct. The pattern works as specified.

**Verdict:** Functionally correct. Stylistically mixed (some double-quoted, some single-quoted) but both produce identical behavior. The quality criterion (no 4-backslash escapes) is **SATISFIED** — file has 2 actual backslashes, not 4.

**Severity: LOW** (style inconsistency only; no functional defect).

---

## Spec-Compliance Criterion Evaluation

| Criterion | Result | Notes |
|-----------|--------|-------|
| 1. FC coverage (all 27 FCs) | PARTIAL — 15/27 | FC-D/E groups (12 FCs) uncovered |
| 2. No real-file modifications | PASS | All modifications use mktemp fixtures; REPO_ROOT files read-only |
| 3. Pre-Phase-7 graceful failure | PASS | All 5 files exit cleanly (1 or 0); no parse errors; no unbound vars |
| 4. Visible/hidden split 3+2 | PASS | Hidden tests cover FC-B-7 (idempotency) and FC-B-3/B-4 dual-pattern — genuinely different from visible tests |

---

## Quality Criterion Evaluation

| Criterion | Result | Notes |
|-----------|--------|-------|
| 1. Shebang + `set -euo pipefail` + trap cleanup | PARTIAL | Shebang ✓, trap ✓ (where needed), but ALL 5 use `set -uo pipefail` (missing `-e`) |
| 2. `[PASS]`/`[FAIL]`/`[SKIP]`/`[INFO]` prefix discipline | PASS | All files use prefix discipline consistently |
| 3. Cross-platform `mktemp` portable form | PASS | Two-attempt pattern: `mktemp -d` then `mktemp -d -t X.XXXXXX` |
| 4. No GNU-only flags | PASS | No `grep -P`, `realpath`, `mktemp --suffix` found |
| 5. No 4-backslash sed escapes | PASS | Verified via Python byte analysis: 2 backslashes in source file (double-quoted = sed sees `\.`) |
| 6. Canonical `([^./])` sed pattern (not `(^|[^./])`) | PARTIAL | sed patterns use `([^./])` correctly; grep ASSERT-1 uses `(^|[^./])` which is functionally correct in grep-E context |

---

## Hidden Test Differentiation Audit

The 2 hidden tests cover:
- `v10-idempotency-second-pass.sh` → FC-B-7 (idempotency of the rewrite sed). The 3 visible tests do NOT test second-pass idempotency — they only check current state correctness. **Distinct.**
- `v10-dual-pattern-line.sh` → FC-B-3/B-4 dual-pattern (two `core/X.md` tokens on one line). The visible tests do not synthesize or test multi-token lines. **Distinct.**

Visible/hidden split is well-designed. 60/40 ratio (vs 80/20 target) is acceptable for a 5-test suite.

---

## Pre-Phase-7 Graceful Failure Audit

Empirical run results:

| File | Exit code | Behavior |
|------|-----------|---------|
| `v10-skill-from-external-cwd.sh` | 0 (PASS) | Uses synthetic fixture; passes pre-Phase-7 (correct) |
| `v10-guard-block-fail-loud.sh` | 1 (FAIL) | Fails loudly on missing scaffold/guard-block.md; clean exit (correct) |
| `v10-core-path-depth-consistency.sh` | 0 (PASS) | Pre-Phase-7 tree has no bare refs + no steps files to corrupt; advisory PASS (correct) |
| `v10-idempotency-second-pass.sh` | 1 (FAIL) | Correctly detects pre-Phase-7 bare refs as non-idempotent (correct) |
| `v10-dual-pattern-line.sh` | 1 (FAIL) | Synthetic asserts pass; ASSERT-5 real-file checks fail clean (correct) |

All 5 exit via `exit 0` / `exit 1` / `exit 77`. No parse errors, no unbound-variable crashes. **PASS.**

---

## Recommendations for Phase 7 / Phase 8

1. **Phase 7 implementer:** Verify FC-A-4 manually (scaffold/SKILL.md line 11 Read directive).
2. **Phase 8 commander:** Explicitly verify FC-D-2 (CHANGELOG), FC-D-3 (version bump), FC-D-4 (git tag), FC-E-1/E-2/E-3/E-4/E-5 (reliability invariants) — these are not covered by Phase 5 TDD tests.
3. **Phase 8:** Run FC-B-6 manually: `grep -roE '(\.\./){1,}core/[a-z][a-z-]*\.md' skills/ agents/ --include='*.md' | wc -l` and verify = 188.
4. **Phase 8:** Run FC-B-8 manually: `git diff v10.1.2 -- docs/ README.md CHANGELOG.md` should show only CHANGELOG.md changes.
5. Consider adding a 6th Phase-C visible test covering FC-D-2/D-3 (CHANGELOG + version) for v10.3.0 discipline.

---

**STATUS: PHASE-5-REVIEW-COMPLETE**
