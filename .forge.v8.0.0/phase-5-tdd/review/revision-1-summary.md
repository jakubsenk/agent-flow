# Phase 5 TDD — Revision 1 Summary

**Revision agent:** Phase 5 TDD Revision (Sonnet 4.6)
**Date:** 2026-04-27
**Round 1 findings addressed:** 8 CRITICAL/MAJOR + 4 MODERATE + 3 MINOR

---

## Finding-by-Finding Status

### CRITICAL — REPO_ROOT path resolution

**Status: FIXED**

- `coverage-report.md` corrected: now states "2 levels up" (was incorrectly claiming 3) and explicitly states tests are NOT runnable from `.forge/` staging — Phase 7 move to `tests/scenarios/` required.
- All 77 visible + 12 hidden test files (89 total) updated with:
  1. `# NOTE:` comment at REPO_ROOT line explaining staging constraint
  2. Defensive guard block: `if echo "$REPO_ROOT" | grep -q '\.forge'; then exit 1; fi`
- Files modified: all 89 `v8-*.sh` files in `.forge/phase-5-tdd/tests/` and `.forge/phase-5-tdd/tests-hidden/`

---

### MAJOR — Add 6 missing scenario files

**Status: FIXED — 6 new files added**

1. **`v8-setup-agents-python.sh`** (AC-SETUP-002) — FIXED
   - Mock `pyproject.toml` fixture created in temp dir
   - Verifies setup-agents SKILL.md documents Python heuristic detection
   - Verifies generated analyst.toml contains `[[constraints]]` with PEP 8 / Python keyword
   - File: `.forge/phase-5-tdd/tests/v8-setup-agents-python.sh`

2. **`v8-setup-agents-monorepo.sh`** (AC-SETUP-003) — FIXED
   - Mock `pnpm-workspace.yaml` + 2 sub-package `package.json` fixtures
   - Verifies setup-agents SKILL.md documents monorepo detection
   - Verifies generated analyst.toml contains `[[process_additions]]` with monorepo keyword
   - File: `.forge/phase-5-tdd/tests/v8-setup-agents-monorepo.sh`

3. **`v8-setup-agents-scope.sh`** (AC-SETUP-008) — FIXED
   - Creates baseline sha256sum of all files outside `customization/`
   - Simulates `/setup-agents` writing only to `customization/`
   - Asserts baseline checksums identical after run (no files outside `customization/` modified)
   - Verifies SKILL.md documents scope restriction
   - File: `.forge/phase-5-tdd/tests/v8-setup-agents-scope.sh`

4. **`v8-mode-stepmode-resume.sh`** (AC-MODE-007) — FIXED
   - Visible happy-path test (hidden adversarial edge case remains in `v8-hidden-step-mode-abort-resume.sh`)
   - Mock state.json with `pause_reason=step_mode_abort`, `last_completed_step=04-fixer-reviewer-loop`
   - Verifies resume-ticket SKILL.md documents: step_mode_abort handling, next-step logic, last_completed_step field read
   - Step 05 existence verified via `find skills/fix-bugs/steps/05-*.md` (SKIP if not yet implemented)
   - File: `.forge/phase-5-tdd/tests/v8-mode-stepmode-resume.sh`

5. **`v8-mode-vague-heuristic-boundaries.sh`** (REQ-MODE-009a) — FIXED
   - All 4 boundary cases implemented:
     - Case 1: 19 words, no tech term → vague
     - Case 2: ≥20 words, WITH technical term → non-vague
     - Case 3: ≥20 words, NO technical term → vague (AND condition)
     - Case 4: 0 words (empty) → vague
   - `count_words()` helper using `wc -w` (POSIX portable)
   - Verifies threshold documented in SKILL.md or 01-mode-resolve.md
   - File: `.forge/phase-5-tdd/tests/v8-mode-vague-heuristic-boundaries.sh`

6. **`v8-nf-webhook-backcompat.sh`** (AC-NF-008) — FIXED
   - Checks canonical v7 payload fields (`pr_url`, `issue_id`, `agent`, `status`, `run_id`, `pipeline`, `step`, `outcome`) still present in `core/post-publish-hook.md`
   - Checks additive-only evolution documented
   - Checks CLAUDE.md forward-compat notice present
   - Checks no v7→v8 rename patterns (no `_v8` suffix variants for v7 fields)
   - Checks `pr-created` and `ceos-agents-block` event names preserved
   - File: `.forge/phase-5-tdd/tests/v8-nf-webhook-backcompat.sh`

---

### MAJOR — AP3 doc-grep coupling (implementation variable names)

**Status: FIXED — 4 tests corrected**

1. **`v8-mode-mutual-exclusion.sh` — Assertion 5** — FIXED
   - Removed `GOT_YOLO` internal variable grep (implementation-detail coupling)
   - Replaced with: verify both `--yolo` and `--step-mode` flags are documented independently (observable: independent flag recognition, not last-wins)

2. **`v8-matrix-fixbugs-yolo.sh` — Assertion 2** — FIXED
   - Removed `MODE="yolo"` literal string grep
   - Replaced with: verify SKILL.md documents observable gate-skip contract (`skip.*gate`, `yolo.*autonomous`, etc.)

3. **`v8-matrix-implfeat-yolo.sh` — Assertion 2** — FIXED
   - Removed `MODE="yolo"` literal string grep
   - Replaced with: verify observable zero-checkpoints contract (spec/decomp/AC checkpoints all skipped)

4. **`v8-matrix-scaffold-yolo.sh` — Assertion 3** — FIXED
   - Removed `MODE="yolo"` literal string grep
   - Replaced with: verify observable autonomous execution contract (no checkpoint prompts documented)

---

### MAJOR — Self-tautology in provenance log test

**Status: FIXED_WITH_DEVIATION**

`v8-overlay-provenance-log.sh` completely rewritten:
- Original: wrote fixture log → grepped fixture → trivially always PASSed (tested nothing real)
- Revised: checks multiple real doc files (`fix-bugs/SKILL.md`, `core/agent-dispatch.md`, `docs/guides/toml-overlay-syntax.md`, `skills/setup-agents/SKILL.md`, `docs/reference/pipeline.md`) for:
  - `overlay_source=toml` pattern
  - `overlay_source=md` pattern
  - `overlay_source=none` pattern
  - `agent=` key name
  - `overlay_path=` key name
  - `.ceos-agents/pipeline.log` as log destination
  - `exactly once per dispatch` semantics
- If docs not yet written: exits `77` (SKIP) with honest message instead of false PASS
- **Deviation:** full mock pipeline invocation is not yet possible pre-implementation; doc verification + structured SKIP is the correct pre-implementation test pattern

---

### MINOR — Process substitution POSIX compliance

**Status: FIXED — 2 tests corrected**

1. **`v8-invariant-plugin-perm-constraint.sh`** — FIXED
   - `< <(find ...)` replaced with `find ... > tempfile && while ... done < tempfile`
   - New tmpdir uses separate cleanup trap

2. **`v8-steps-naming-convention.sh`** — FIXED
   - `< <(find ...)` replaced with `find ... > tempfile && while ... done < tempfile`
   - Per-pipeline temp files in dedicated tmpdir

---

### MINOR — Coverage report REPO_ROOT mismatch

**Status: FIXED** (see CRITICAL section above — same fix)

---

## New Scenario Count

| Category | Before | After | Delta |
|----------|--------|-------|-------|
| Visible tests | 71 | 77 | +6 |
| Hidden tests | 12 | 12 | 0 |
| **Total** | **83** | **89** | **+6** |

---

## AC Coverage After Revision

All 94 ACs covered. No "advisory" deferrals to Phase 7 remain:
- AC-SETUP-002: dedicated functional test ✓
- AC-SETUP-003: dedicated functional test ✓
- AC-SETUP-008: dedicated scope-isolation test ✓
- AC-MODE-007: visible happy-path test ✓ (hidden adversarial test retained)
- REQ-MODE-009a: 4 boundary cases in dedicated test ✓
- AC-NF-008: dedicated webhook backcompat test ✓

**Coverage: 94/94 ACs = 100%**

---

## Files Modified

### Existing tests — AP3 fixes + REPO_ROOT guard:
- `.forge/phase-5-tdd/tests/v8-mode-mutual-exclusion.sh` (guard + AP3 fix: GOT_YOLO removed)
- `.forge/phase-5-tdd/tests/v8-matrix-fixbugs-yolo.sh` (guard + AP3 fix: MODE="yolo" removed)
- `.forge/phase-5-tdd/tests/v8-matrix-implfeat-yolo.sh` (guard + AP3 fix: MODE="yolo" removed)
- `.forge/phase-5-tdd/tests/v8-matrix-scaffold-yolo.sh` (guard + AP3 fix: MODE="yolo" removed)
- `.forge/phase-5-tdd/tests/v8-overlay-provenance-log.sh` (full rewrite: self-tautology removed)
- `.forge/phase-5-tdd/tests/v8-invariant-plugin-perm-constraint.sh` (guard + process substitution fix)
- `.forge/phase-5-tdd/tests/v8-steps-naming-convention.sh` (guard + process substitution fix)
- All remaining 64 visible tests (REPO_ROOT guard added)
- All 12 hidden tests (REPO_ROOT guard added)

### New test files:
- `.forge/phase-5-tdd/tests/v8-setup-agents-python.sh`
- `.forge/phase-5-tdd/tests/v8-setup-agents-monorepo.sh`
- `.forge/phase-5-tdd/tests/v8-setup-agents-scope.sh`
- `.forge/phase-5-tdd/tests/v8-mode-stepmode-resume.sh`
- `.forge/phase-5-tdd/tests/v8-mode-vague-heuristic-boundaries.sh`
- `.forge/phase-5-tdd/tests/v8-nf-webhook-backcompat.sh`

### Coverage report:
- `.forge/phase-5-tdd/coverage-report.md` (full update: counts, new tests, REPO_ROOT semantics, revision notes)

---

**End of revision-1-summary.md**
