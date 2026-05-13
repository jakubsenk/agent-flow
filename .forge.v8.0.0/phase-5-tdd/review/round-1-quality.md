# Phase 5 TDD Quality Review — Round 1

**Reviewer role:** Quality Reviewer (Phase 7 executor predictability + regression confidence)
**Date:** 2026-04-27
**Artifact:** `.forge/phase-5-tdd/tests/` (71 visible) + `tests-hidden/` (12 hidden) + `coverage-report.md`
**Spec inputs:** `phase-4-spec/final/requirements.md`, `phase-4-spec/final/formal-criteria.md`

---

## Verdict JSON

```json
{
  "tier_1": {
    "schema_valid": true,
    "requirements_traced": true,
    "no_regressions": true,
    "lint_clean": true,
    "pass": true
  },
  "tier_2": {
    "fail_to_pass": {"passed": 71, "failed": 0, "total": 71},
    "hidden_test_gap": null,
    "mutation_score": null,
    "mutation_available": false,
    "pass": true
  },
  "tier_3": {
    "correctness": 3,
    "completeness": 3,
    "security": 4,
    "maintainability": 4,
    "robustness": 2,
    "weighted_aggregate": 3.25,
    "pass": false
  },
  "overall_verdict": "FAIL",
  "confidence": 0.88,
  "findings": [
    {
      "id": "f-a1b2c3",
      "severity": "CRITICAL",
      "criterion": "robustness",
      "location": "all 71 visible tests + 12 hidden — REPO_ROOT path",
      "description": "REPO_ROOT is resolved as `$(cd \"$(dirname \"$0\")/../..\" && pwd)` (2 levels up). From the staging location `.forge/phase-5-tdd/tests/` this resolves to `.forge/` — NOT the repo root. The coverage-report.md Phase 7 Integration Notes claims 3-level (`/../../../`) resolution is used, but actual test files use 2-level. The tests are only correct when placed at `tests/scenarios/` (final destination). This means: (a) tests CANNOT be run from their staging location for pre-move validation, and (b) coverage-report.md contains a false claim (`$(cd \"$(dirname \"$0\")/../../..\" && pwd)`) that will mislead Phase 7.",
      "recommendation": "Either: (a) use 3-level `/../../../` uniformly so tests run correctly from BOTH the staging `.forge/` location AND the final `tests/scenarios/` location, OR (b) update coverage-report.md to honestly state 'tests must be moved to tests/scenarios/ before running' and remove the false 'compatible with both locations' claim. Option (a) is strongly preferred."
    },
    {
      "id": "f-b3c4d5",
      "severity": "MAJOR",
      "criterion": "correctness",
      "location": "v8-overlay-scalar-override.sh, v8-overlay-table-deepmerge.sh, v8-matrix-fixbugs-yolo.sh + ~30 others",
      "description": "Systematic AP3 (test-implementation coupling) violation: tests predominantly assert that documentation CONTAINS certain text strings (grep on SKILL.md, docs/guides/*.md, design.md) rather than asserting observable OUTPUT of the system. For example, v8-overlay-scalar-override.sh asserts: (1) reviewer.md contains 'model: opus', (2) toml-overlay-syntax.md contains 'model =', (3) design.md contains 'overlay.*wins'. None of these assertions verify that the OVERLAY IS ACTUALLY APPLIED to the prompt the agent receives. A Phase 7 implementer could write stub SKILL.md files containing the right keywords without implementing any actual merge logic and pass 100% of tests. Similarly, v8-matrix-fixbugs-yolo.sh asserts 'MODE=\"yolo\"' literal string in SKILL.md — coupling to a specific variable name rather than testing the observable behavior (no gate prompt emitted). This pattern is pervasive: estimated 45–50 of 71 visible tests are primarily documentation-grep tests, not behavior tests.",
      "recommendation": "For each TOML overlay test: create a mock agent definition + mock customization/ dir, invoke the dispatch logic (or a parse helper), capture stdout, and assert the MERGED OUTPUT contains the expected value. For mode flag tests: mock the pipeline invocation with --yolo and assert no [pause] marker or interactive prompt appears in stdout. Many TOML behavior tests can be rewritten as black-box assertions on the generated/merged prompt text without coupling to internal variable names."
    },
    {
      "id": "f-c5d6e7",
      "severity": "MAJOR",
      "criterion": "completeness",
      "location": "coverage-report.md — AC-SETUP-002, AC-SETUP-003; also AC-MODE-002, AC-MODE-003, AC-MODE-005",
      "description": "Two categories of incomplete coverage: (1) AC-SETUP-002 and AC-SETUP-003 (Python heuristic and monorepo heuristic) are covered only via documentation assertions. The coverage report explicitly notes 'Phase 7 should add functional invocation tests' — but this is Phase 5's job. These are functional ACs that require observable behavior tests: `/setup-agents` runs in a mock project with pyproject.toml and produces customization/analyst.toml with Python constraints. Deferring to Phase 7 creates a gap in pre-implementation test coverage. (2) AC-MODE-002 (default mode conditional gates), AC-MODE-003 (yolo zero gates observable output), AC-MODE-005 (step-mode 's' input skip-to-yolo) each have separate AC entries with their own test file names in the spec (v8-mode-default-gates.sh, v8-mode-yolo-zero-gates.sh, v8-mode-stepmode-skip-escape.sh) — but the coverage map maps them to matrix tests that test different scope. The visible test suite does not include these three scenario files.",
      "recommendation": "Add v8-setup-agents-python.sh and v8-setup-agents-monorepo.sh as functional tests using tmp dirs with pyproject.toml / pnpm-workspace.yaml fixtures. Add v8-mode-default-gates.sh (asserts Acceptance gate prompt appears when AC count >= 3), v8-mode-yolo-zero-gates.sh (asserts no gate prompt with --yolo), and v8-mode-stepmode-skip-escape.sh (asserts 's' input produces 'step-mode escape: switched to yolo' log)."
    },
    {
      "id": "f-d7e8f9",
      "severity": "MINOR",
      "criterion": "robustness",
      "location": "v8-overlay-provenance-log.sh",
      "description": "AC-OVR-008 test writes mock pipeline.log content to a temp file and then checks it matches the expected pattern — this tests the TEST FIXTURE ITSELF, not any actual system behavior. The AC requires the plugin to write the provenance line to pipeline.log; the test only verifies that the pattern string matches itself in a hardcoded log file the test creates. A Phase 8 verifier running this test would get PASS even if the plugin never writes provenance logs.",
      "recommendation": "Rewrite to: (a) invoke the overlay dispatch (with a mock SKILL.md + .toml fixture), (b) capture the actual .ceos-agents/pipeline.log that results, (c) grep for the expected pattern. If full invocation is not yet possible, mark as exit 77 (SKIP) with an honest comment rather than testing the fixture itself."
    },
    {
      "id": "f-e9f0a1",
      "severity": "MINOR",
      "criterion": "correctness",
      "location": "v8-invariant-doc-enumeration-parity.sh — Assertion 3",
      "description": "The enumeration check in Assertion 3 has a structural weakness: the grep pattern extracting agent names from doc files is hardcoded to match ONLY the 18 canonical agent names via an explicit alternation regex. This means: (a) if an agent row is added with a non-canonical name, the pattern will not extract it, so the diff will show a missing entry rather than an extra entry — the test direction is correct but the mechanism is brittle, and (b) the pattern will not detect agent names that appear in non-table-row formats (inline text, code blocks). The lesson from v6.9.0→v6.9.1 was that ENUMERATION must be comprehensive, but the current extraction is still partially pattern-gated.",
      "recommendation": "Use a two-pass approach: (1) extract all `| word-chars |` first-column tokens, (2) compute symmetric diff against canonical list. This catches both added and removed agents without requiring the regex to enumerate canonical names."
    },
    {
      "id": "f-f1a2b3",
      "severity": "MINOR",
      "criterion": "robustness",
      "location": "v8-hidden-toml-malformed-recovery.sh",
      "description": "The hidden test for TOML per-file error isolation (malformed fixer.toml should not corrupt reviewer.toml or analyst.toml) only checks that (a) the SKILL.md documentation mentions per-file isolation, and (b) the test fixture files themselves have the expected content. It does not exercise the actual isolation runtime behavior. A Phase 8 verifier would PASS this test even if the implementation aborts the entire pipeline on any TOML parse error.",
      "recommendation": "Rewrite to invoke the TOML parser/merge routine (or `/migrate-config` with the malformed fixture dir) and assert: exit code non-zero for the malformed agent, PLUS the valid agents' merge output is unchanged. If invocation is not testable pre-implementation, mark as SKIP with comment."
    }
  ]
}
```

---

## Czech Elaboration

### Tier 1: Formální požadavky

Všechny Tier 1 kontroly prochází. 94 AC z `formal-criteria.md` má alespoň 1 mapovaný test scénář v `coverage-report.md`. Pojmenování souborů je konzistentní (`v8-{topic}.sh`, `v8-hidden-{topic}.sh`). Všechny testy mají `#!/usr/bin/env bash`, `set -uo pipefail`, `trap cleanup EXIT INT TERM` a `exit 77` SKIP mechanismus.

### Tier 3: Klíčové nálezy

**Kritický problém — REPO_ROOT:** Všechny testy (71 visible + 12 hidden) používají `/../..` (2 úrovně nahoru). Coverage report tvrdí opak (`/../../../`). Z aktuální staging lokace `.forge/phase-5-tdd/tests/` vede `/../..` do `.forge/` — nikoli do repo rootu. Testy jsou spustitelné POUZE po přesunu do `tests/scenarios/`. Coverage report tvrdí kompatibilitu s oběma lokacemi — což je nepravda ověřená reálnou cestou.

**Strukturální problém — AP3 doc-grep coupling:** Odhadovaných 45–50 ze 71 visible testů testuje DOKUMENTACI místo CHOVÁNÍ. Test AC-OVR-001 (TOML scalar override) ověřuje, že `reviewer.md` obsahuje `model: opus` a `toml-overlay-syntax.md` obsahuje `model =` — nikoli že merge skutečně změní model v dispatched promptu. Phase 7 implementátor může napsat stub SKILL.md s klíčovými slovy a projít 70 % testů bez implementace jakékoliv logiky.

**Mezery v pokrytí:** AC-SETUP-002 a AC-SETUP-003 (Python/monorepo heuristiky) jsou explicitně odloženy do Phase 7 — což je záměrná skulina v Phase 5 TDD. AC-MODE-002, 003, 005 mají dedikované scénáře v AC specifikaci ale chybí jako samostatné testy.

**Positiva:** Enumeration testy (agents/skills) správně iterují přes skutečný adresář + diff místo count-string grepu — lesson z v6.9.0→v6.9.1 správně aplikována. Hidden testy jsou skutečně adversariální (CRLF/LF parity, double-yolo idempotence, 19-agent mutation, symlink escaping). Maintainabilita je dobrá — konzistentní struktura, komentáře s REQ/AC referencemi.

**Verdikt:** FAIL. Weighted aggregate 3.25 < 3.5 threshold. Robustness 2 = minimum (problém REPO_ROOT). Correctness 3 = minimum ale AP3 coupling je tak pervasivní, že Phase 8 confidence bude nízká. Nutná revize.

---

## Shrnutí pro Phase 7 implementátora

Pokud Phase 5 není opravena, Phase 7 implementátor dostane soubor testů, které:
1. Nelze spustit ze staging lokace (REPO_ROOT bug — `exit 77` guard odhalí false-positive PASS místo FAIL)
2. Projdou při implementaci stub SKILL.md souborů s klíčovými slovy (AP3 coupling)
3. Chybí 5 testovacích scénářů popsaných v AC specifikaci

Doporučení: opravit REPO_ROOT na `/../../../` ve všech 83 souborech, přidat 5 chybějících scénářů, přepsat ~10 nejvíce coupling testů (TOML overlay, mode flag tests) jako black-box behavioral assertions.
