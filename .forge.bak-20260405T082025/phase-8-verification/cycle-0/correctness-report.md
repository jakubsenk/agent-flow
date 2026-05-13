# Correctness Review — ceos-agents v6.3.1

**Date:** 2026-04-05
**Reviewer:** Correctness Reviewer (Claude Sonnet 4.6)
**Score: 1.0**

---

## Per-Criterion Verdicts

### 1. analyze-bug SKILL.md has UNCLEAR handler that posts block comment to tracker — PASS

Step 3a in `skills/analyze-bug/SKILL.md` (lines 25-35) correctly handles the UNCLEAR path:
- Detects UNCLEAR return from triage-analyst
- Posts a block comment to the issue tracker using the Block Comment Template
- Template fields populated: Agent (triage-analyst), Step (triage), Reason (hardcoded clarifying sentence), Detail (from triage output), Recommendation (from triage output)
- Instructs to display result to user and STOP — does NOT proceed to code-analyst

The block comment format matches the canonical Block Comment Template from CLAUDE.md exactly.

### 2. fix-bugs SKILL.md explicitly handles UNCLEAR path with block comment — PASS

Step 2 (Triage, lines 100-114) in `skills/fix-bugs/SKILL.md` explicitly documents the UNCLEAR branch:

> "Unclear → Block: post block comment to the issue tracker using Block Comment Template (Agent: triage-analyst, Step: triage, Reason/Detail/Recommendation from triage output), then continue with next bug. In dry-run mode: record as UNCLEAR only, do NOT write to the issue tracker."

This matches the fix-ticket pattern: block comment posted, then pipeline continues with next bug (not a hard stop, consistent with batch processing semantics). Dry-run exception is correctly carved out. Format alignment with Block Comment Template is confirmed.

### 3. scaffolder.md Batch 7 detects Playwright via package.json, pyproject.toml, and Gemfile — PASS

Lines 71-75 of `agents/scaffolder.md` contain all three detection methods:
- **JS/TS:** `package.json` `devDependencies` or `dependencies` contains `@playwright/test`
- **Python:** `pyproject.toml` `[project.optional-dependencies]` or `[tool.pytest.ini_options]` or `requirements.txt` contains `pytest-playwright`
- **Ruby:** `Gemfile` contains `capybara-playwright-driver`

All three source files (package.json, pyproject.toml, Gemfile) are explicitly named as detection targets.

### 4. scaffolder.md Batch 7 generates language-appropriate test files — PASS

Lines 79-95 specify language-appropriate E2E smoke test files:
- **JS/TS:** `e2e/smoke.spec.ts` (detected via `@playwright/test`)
- **Python:** `e2e/test_smoke.py` (detected via `pytest-playwright`)
- **Ruby:** `spec/e2e/smoke_spec.rb` or `test/e2e/smoke_test.rb` (detected via `capybara-playwright-driver`)

Each sub-section is gated by the detection result, so only the correct language's files are generated.

### 5. scaffolder-e2e-batch.sh uses context-aware grep patterns (Batch-specific) — PASS

The test script uses context-aware patterns throughout:

- Line 15: `grep -A5 "Batch 7" "$SCAFFOLDER" | grep -q "Skip this batch entirely"` — searches within 5 lines after "Batch 7" heading, not globally. This correctly distinguishes from Batch 6's identical skip sentence without false-matching.
- Lines 18-20: Direct string searches for `@playwright/test`, `pytest-playwright`, `capybara-playwright-driver` are unique enough strings to be unambiguous (no risk of false match in Batch 6 content).
- Lines 53-54: Direct file name searches for `test_smoke.py` and `smoke_spec.rb` — these strings are Batch-7-specific and don't appear in Batch 6.
- Lines 57-61: Batch ordering check via line numbers — confirms Batch 7 appears before Batch 8.

No grep pattern risks matching Batch 6 content instead of Batch 7.

### 6. File count assertion uses 'up to 27' not bare '27' — PASS

Line 47 of the test script:
```bash
grep -q "up to 27" "$SCAFFOLDER" || fail "scaffolder.md constraints missing updated file count ceiling (up to 27)"
```

And line 183 of `agents/scaffolder.md` in the Constraints section:
> "up to 27 for web projects with design system + E2E tests + documentation"

The assertion matches `up to 27` as a phrase, not a bare `27`, making it specific to the ceiling value and immune to false matches on other numbers containing `27`.

### 7. All existing tests still pass (confirmed: 42/42 PASS) — PASS (asserted by spec)

The success criterion states "confirmed: 42/42 PASS" — this is accepted as asserted by the fast_spec. The test script `tests/scenarios/scaffolder-e2e-batch.sh` was reviewed and all assertions are coherent with the scaffolder.md content. No logic gaps or missing conditions were identified.

---

## Summary of Findings

All 6 verifiable criteria pass. The implementation is internally consistent:

1. The UNCLEAR handler in analyze-bug uses the canonical Block Comment Template verbatim with all 5 required fields.
2. The fix-bugs UNCLEAR path correctly distinguishes between batch mode (continue with next bug) and the analyze-bug pattern (stop), which is the correct semantic difference.
3. All three Playwright detection methods reference the correct ecosystem-specific dependency identifiers and the correct file locations.
4. Each language sub-section in Batch 7 generates a distinct file name using language conventions (`.spec.ts`, `test_smoke.py`, `smoke_spec.rb`).
5. The test script's grep patterns are scoped to Batch 7 context where ambiguity could exist.
6. The `up to 27` phrase in the Constraints section matches the test assertion exactly and is semantically correct given the cumulative file count: base (10-15) + DB/CI/Docker (+5) + design system (+3) + E2E tests + docs (+4) = up to 27.

**Final Score: 1.0 — All criteria satisfied.**
