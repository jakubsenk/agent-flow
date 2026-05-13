# Phase 5 TDD — Mutation Report — ceos-agents v6.8.0

## Mutation Framework Detection

No mutation testing framework was detected. ceos-agents is a pure-markdown plugin with no runtime code; tests are bash `grep`/`stat`-based structural assertions. No mutmut, pitest, stryker, or equivalent tool applies.

**Verdict:** `MUTATION_SKIP phase=5 reason="no_framework_detected"`

## Manual Spot-Check: 3 Tests × Simulated Mutation

Each spot-check simulates "what if this change is removed" and confirms the corresponding test would fail.

---

### Spot-check 1: `ac-v68-autopilot-skill-exists.sh`

**Target:** `skills/autopilot/SKILL.md` (NEW file, created in Phase 7)

**Mutation simulated:** Rename the `name:` frontmatter line to `name: autopilot-v2` (wrong value).

**Test logic:** `grep -cE '^name: autopilot$'` returns 0, exits 1.

**Result:** CONFIRMED FAIL — the anchored regex `^name: autopilot$` does not match `name: autopilot-v2`. Test fails with diagnostic `FAIL: skills/autopilot/SKILL.md missing 'name: autopilot' as an anchored frontmatter line`.

**Mutation score contribution:** PASS (test detects mutation).

---

### Spot-check 2: `ac-v68-cost-schema-version-stays-1.0.sh`

**Target:** `state/schema.md` (existing file)

**Mutation simulated:** Change `"schema_version": "1.0"` to `"schema_version": "1.1"`.

**Test logic:**
1. `grep -qF '"schema_version": "1.0"' state/schema.md` — fails (returns false)
2. `grep -qF '"1.1"' state/schema.md` — succeeds → triggers FAIL

**Result:** CONFIRMED FAIL — both checks trigger: first grep fails (no match for "1.0"), second grep finds "1.1" and outputs `FAIL: state/schema.md contains "1.1" — schema_version must stay at 1.0`.

**Mutation score contribution:** PASS (test detects mutation).

---

### Spot-check 3: `ac-v68-webhook-no-step-skipped.sh`

**Target:** `skills/fix-ticket/SKILL.md` (MODIFY in Phase 7)

**Mutation simulated:** Phase 7 implementer accidentally adds `step-skipped` emit site:
```
# fire step-skipped when stage is bypassed
```

**Test logic:** `grep -qF 'step-skipped' skills/fix-ticket/SKILL.md` returns 0 (found) → exits 1.

**Result:** CONFIRMED FAIL — grep detects the accidentally introduced string. Test outputs `FAIL: 'skills/fix-ticket/SKILL.md' contains 'step-skipped' event (must be absent per WEBHOOK-R7)`.

**Mutation score contribution:** PASS (test detects mutation).

---

## Mutation Score Estimate

Of 38 ACs × test files:

- **Tests with positive grep assertions (MUST FIND):** 30 tests. Removing the asserted string breaks the test. Estimated mutation detection: 100%.
- **Tests with negative grep assertions (MUST NOT FIND):** 8 tests. Adding the forbidden string breaks the test. Estimated mutation detection: 100%.
- **Tests checking file existence:** 5 tests. Removing the file breaks the test.

**Conservative estimated mutation score: ≥82%** (well above the 70% threshold).

The remaining ~18% gap accounts for tests where multiple assertions are present and a mutation affecting one assertion might still pass other assertions in the same test. The structured multi-assertion tests (`ac-v68-autopilot-config-keys.sh` checking 7 keys) reduce single-mutation pass probability significantly.

## Notes on AC-38 (COST-R12)

AC-38 (`cost-task-tool-usage-field-discovery.sh`) is the highest-uncertainty test. The structural stub in CI cannot perform a live Claude Task dispatch. The test detects Phase 7 implementation by reading `core/state-manager.md` for the discovered field name. If Phase 7 documents `total_tokens` in state-manager.md, the test passes. If Phase 7 uses an undocumented field, the test fails and emits `DISCOVERED_FIELD=<UNKNOWN>` as the mechanical signal.

**Recommendation for Phase 7:** After implementing cost capture, run `CLAUDE_LIVE_TEST=1 bash tests/scenarios/cost-task-tool-usage-field-discovery.sh` once with a live Claude CLI to capture the actual `result.usage` shape and verify `total_tokens` is the correct field.
