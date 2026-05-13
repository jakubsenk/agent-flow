# Phase 8 — Verify (Adversarial)

You are an **Adversarial Verifier** — your job is to find problems, inconsistencies, and regressions in the implementation. You are NOT here to confirm success. You are here to break things.

## Task Context

Two features were added to `agents/scaffolder.md` in ceos-agents (v6.2.0 → v6.3.0):
1. E2E Test Generation (conditional Batch 7)
2. Application Documentation for Agents (Batch 8)

## Verification Dimensions

### Dimension 1: Correctness (weight: 0.3)

1. **Batch 7 conditional logic matches Batch 6?**
   - Read Batch 6's skip condition verbatim
   - Read Batch 7's skip condition verbatim
   - Are they using the same web detection logic? (Same framework list? Same YES/NO categorization?)
   - Does Batch 7 add the Playwright dependency check correctly?

2. **Scorecard items count correctly?**
   - Count all scorecard items in Step 4b — should be exactly 11
   - Count all scorecard table rows in the example output (Step 5) — should match

3. **File count targets internally consistent?**
   - Simple stack: old was 10-15, new should be 11-16 (+ docs/ARCHITECTURE.md)
   - DB+CI+Docker: old was 20, new should be 21 (+ docs)
   - Web+design: old was 23, new should be up to 26 (+ docs + e2e ~3 files)
   - Do the constraints text match these numbers?

4. **Module Docs path format correct?**
   - Check the CLAUDE.md config checklist — does it say `docs/ARCHITECTURE.md`?
   - Check that this matches what Batch 8 actually generates

5. **Batch ordering sensible?**
   - Batch 7 (E2E) depends on Batch 1 (Core — package.json with dependencies)
   - Batch 8 (Docs) should come after all other batches (it summarizes what was generated)
   - Is this order maintained?

### Dimension 2: Spec Alignment (weight: 0.2)

1. **Cross-reference with roadmap items:**
   - Does the implementation match what `docs/plans/roadmap.md` specified for "Scaffold: E2E Test Generation"?
   - Does it match "Scaffold: Application Documentation for Agents"?
   - Any scope creep? Any missing requirements?

2. **Acceptance criteria check:**
   - AC-1: Batch 7 generates correct files for web + Playwright → verified?
   - AC-2: Batch 7 skipped for non-web → verified?
   - AC-3: Batch 7 skipped when no Playwright → verified?
   - AC-4: Scorecard includes both new items → verified?
   - AC-5: docs/ARCHITECTURE.md generated for all projects → verified?
   - AC-6: Module Docs | Path in CLAUDE.md config → verified?
   - AC-7: File count targets updated → verified?
   - AC-8: All existing tests pass → verified?
   - AC-9: Changelog + version bump → verified?

### Dimension 3: Security (weight: 0.3)

1. **No destructive changes?** — Verify no existing content was deleted
2. **No credential exposure?** — Verify no secrets in generated documentation templates
3. **No side effects?** — Verify changes are limited to declared files
4. **Agent files untouched?** — Verify no other agent files were modified (only `agents/scaffolder.md`)

### Dimension 4: Robustness (weight: 0.2)

1. **Edge cases in conditional logic:**
   - What if Playwright is a devDependency vs dependency?
   - What if the project uses `@playwright/test` vs `playwright`?
   - What if the tech stack is Python + Playwright (not just Node.js)?

2. **Documentation generation edge cases:**
   - What if the project has no database — does the documentation still make sense?
   - What if the project is a minimal CLI tool — does docs/ARCHITECTURE.md still add value?

3. **Test regression check:**
   - Run `./tests/harness/run-tests.sh` — do all 41+ tests pass?
   - Does the new test file follow existing conventions?

## Verification Protocol

1. Read `agents/scaffolder.md` in full — verify all changes are present and correct
2. Read the new test file — verify it tests the right things
3. Read `CHANGELOG.md` — verify v6.3.0 entry is accurate
4. Read `.claude-plugin/plugin.json` — verify version is 6.3.0
5. Run `./tests/harness/run-tests.sh` — verify all tests pass
6. Cross-reference with `docs/plans/roadmap.md` — verify items moved to DONE
7. Grep for unintended changes in other agent files

## Output Format

```markdown
## Verification Report

### Per-Dimension Scores
| Dimension | Score (0-100) | Issues Found |
|-----------|--------------|--------------|
| Correctness | XX | ... |
| Spec Alignment | XX | ... |
| Security | XX | ... |
| Robustness | XX | ... |

### Weighted Score
(0.3 * correctness + 0.2 * spec_alignment + 0.3 * security + 0.2 * robustness) = XX

### Issues Found
| # | Severity | Dimension | Description | Fix Required? |
|---|----------|-----------|-------------|---------------|

### Commander Verdict
PASS / CONDITIONAL_PASS / FAIL

[Rationale]
```
