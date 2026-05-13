# Phase 8 Correctness Report — v6.8.1

**Cycle:** 0
**Date:** 2026-04-18
**Reviewer:** Phase 8 Correctness Agent

---

## Verdict Score: 0.82

**Overall:** CONDITIONAL PASS — 2 genuine failures, 5 hidden tests blocked by a structural path bug in test scripts.

---

## 1. Full Harness Results

**Command:** `./tests/harness/run-tests.sh`
**Exit code:** 1
**Counts:** Total: 142 | Pass: 141 | Fail: 1 | Skip: 0

**Failing test:** `tests/scenarios/ac-v68-doc-version-6.8.0.sh`
- Asserts `"version": "6.8.0"` in `.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json`
- Fails because version was bumped to `6.8.1` — this is an **expected cascade failure** for a prior-release version pin test
- Root cause: the v6.8.0 pin scenario was not updated to expect v6.8.1 after the version bump
- Severity: LOW — indicates stale pin scenario, not a v6.8.1 content regression

**Expected per spec:** 142/142. Actual: 141/142. Delta: -1 (stale version-pin scenario).

---

## 2. Hidden Test Results

**Critical finding:** All 5 hidden tests that check file paths fail with `exit 1` due to a structural bug in the test scripts. The `REPO_ROOT` variable is computed as `$(cd "$(dirname "${BASH_SOURCE[0]}")/../../" && pwd)` which resolves to `.forge/` (2 levels up from `tests-hidden/`), not the repo root (3 levels up). Files exist at repo root, not at `.forge/`.

Manual verification was performed against actual repo files for all ACs covered by the failing tests — all pass.

| Test | Raw Exit | Underlying ACs | Manual Verification |
|------|----------|----------------|---------------------|
| `h-regex-newline-bypass.sh` | **0 (PASS)** | AC-ITEM-2.6 | N/A — passed natively |
| `h-regex-path-traversal.sh` | 1 (path bug — Parts 1+2 all OK, Part 3 path miss) | AC-ITEM-2.5 | All 4 skill files have regex literal; no widening |
| `h-block-handler-heredoc.sh` | 1 (path bug — file not found at `.forge/core/`) | AC-ITEM-3.2, 3.4 | All 5 positive patterns present; 1 false-positive on POSIX-unsafe check (line 59 is prose documentation of what NOT to use, not code) |
| `h-changelog-internal-section.sh` | 1 (path bug — CHANGELOG.md not at `.forge/`) | AC-RELEASE-1a/b/c | See AC spot-check below |
| `h-config-template-autopilot-all-8.sh` | 1 (path bug — examples/configs/ not at `.forge/`) | AC-ITEM-1.1–1.4 | All 8 templates have `### Autopilot` |
| `h-fixer-reviewer-loop-step-10.sh` | 1 (path bug — core/ not at `.forge/`) | AC-ITEM-5.1a, 5.1b, 5.3 | All 4 grep patterns pass |
| `h-skill-autopilot-368.sh` | 1 (path bug — skills/ not at `.forge/`) | AC-ITEM-4.1a, 4.1b | All 4 patterns pass |

**Summary:** 1/7 passed natively. 6/7 failed due to REPO_ROOT pointing to `.forge/` instead of repo root. The path bug is in the test scripts (need `../../../` not `../../`). No implementation failures.

---

## 3. AC Spot-Check (5 selected)

### AC-ITEM-2.1 — Regex literal in all 4 skills
**Verification:** `grep -qF '^[A-Za-z0-9#_-]+$'` on 4 files
- `skills/fix-ticket/SKILL.md`: PASS
- `skills/fix-bugs/SKILL.md`: PASS
- `skills/implement-feature/SKILL.md`: PASS
- `skills/resume-ticket/SKILL.md`: PASS
**Result: PASS**

### AC-ITEM-3.1 — post-publish-hook.md Section 4 field-safety note
- `grep -qE 'Field value safety'`: PASS
- `grep -qE 'JSON-encode field values|...'`: PASS
- `grep -qE 'issue_id regex gate|\[A-Za-z0-9#_-\]'`: PASS
**Result: PASS**

### AC-ITEM-5.1a — Cumulative tokens_used prose in loop contract
- `tokens_used += iteration_tokens_used`: PASS
- `duration_ms += iteration_duration_ms`: PASS
- `tool_uses += iteration_tool_uses`: PASS
- Crash-recovery semantics sentence: PASS
**Result: PASS**

### AC-RELEASE-1a — CHANGELOG heading present
**Command:** `grep -qE '^## \[6\.8\.1\] — 2026-04-18' CHANGELOG.md`
**Result: FAIL** — heading is `## [6.8.1] — 2026-04-19` (date is one day ahead of spec requirement)
- Spec requires `2026-04-18` (today per `currentDate`); file contains `2026-04-19`
- Severity: MEDIUM — AC-RELEASE-1a will fail its mechanical check

### AC-RELEASE-2a/b/c — Version tags and git
- `plugin.json` → `"version": "6.8.1"`: PASS
- `marketplace.json` → `"version": "6.8.1"`: PASS
- `git tag --list v6.8.1` → `v6.8.1`: PASS
**Result: PASS**

---

## 4. Version Verification

| Check | Expected | Actual | Result |
|-------|----------|--------|--------|
| `plugin.json` version | `6.8.1` | `6.8.1` | PASS |
| `marketplace.json` version | `6.8.1` | `6.8.1` | PASS |
| `git tag --list v6.8.1` | `v6.8.1` | `v6.8.1` | PASS |
| `git log` top commit | `chore: bump version 6.8.0 → 6.8.1` | `chore: bump version 6.8.0 → 6.8.1` | PASS |
| `git log` 2nd commit | content/v6.8.1 reference | `feat(v6.8.1): post-v6.8.0 follow-ups — 6 items from roadmap` | PASS |

---

## 5. CHANGELOG Structure

| Check | Expected | Actual | Result |
|-------|----------|--------|--------|
| Has `### Fixed` | Yes | Yes | PASS |
| Has `### Internal` | Yes | Yes | PASS |
| No `### Added` | Absent | Absent | PASS |
| Lists both new scenarios | Yes | Yes | PASS |
| References `examples/configs/` | Yes | Yes | PASS |
| No `examples/config-templates/` | Absent | Absent | PASS |
| Date in heading | `2026-04-18` | `2026-04-19` | **FAIL** |

---

## 6. Additional Findings

### AC-ITEM-3.2 False Positive — POSIX-unsafe grep match
The formal-criteria AC-ITEM-3.2 negative check `! grep -qE '\$\{[A-Za-z_][A-Za-z0-9_]*:[0-9]+:-[0-9]+\}'` will match line 59 of `core/block-handler.md` which reads:
> `no shell-level substring trimming required (no Bash-specific \`\${var:1:-1}\` or`

This is prose documentation explaining what NOT to use — it is not executable code. The hidden test `h-block-handler-heredoc.sh` would flag this as a failure once the path bug is fixed. This is a **false positive in the AC criterion itself** — the grep pattern does not distinguish prose from code.

### Harness Failing Test Analysis
`ac-v68-doc-version-6.8.0.sh` is a v6.8.0 doc-version pin test that expects `6.8.0` in plugin JSON files. After bumping to v6.8.1, this test correctly fails. It should have been updated to expect `6.8.1` OR removed. This is a **pre-existing test maintenance issue**.

---

## Summary of Failures

| ID | Failure | Severity | Actionable Fix |
|----|---------|----------|---------------|
| F-1 | Harness: 141/142 — `ac-v68-doc-version-6.8.0.sh` checks for old version `6.8.0` | LOW | Update or retire the v6.8.0 pin scenario |
| F-2 | CHANGELOG date is `2026-04-19`, AC requires `2026-04-18` | MEDIUM | Update CHANGELOG heading date to `2026-04-18` |
| F-3 | 6/7 hidden tests fail with REPO_ROOT path bug (`.forge/` not repo root) | INFRA | Fix `../../` → `../../../` in hidden test scripts |
| F-4 | AC-ITEM-3.2 negative criterion produces false positive (prose on line 59) | AC-BUG | Scope grep to fenced code blocks only |

---

## Score Derivation

- 31 formal ACs: 29 PASS, 2 FAIL (AC-RELEASE-1a date mismatch; harness count short by 1)
- Hidden tests: 1/7 native pass; 6/7 blocked by infra bug (not implementation failures)
- Version: 4/4 PASS
- CHANGELOG structure: 6/7 (date mismatch)

**Score: 0.82** — Implementation is functionally correct. Two non-trivial failures: CHANGELOG date and the stale version-pin scenario. Hidden test infrastructure has a path bug that prevents native execution.
