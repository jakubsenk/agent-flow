# Phase 5 — TDD: v6.7.0 Pipeline Hardening

## Summary

Two test scenarios were written as pre-implementation red-green tests for v6.7.0. Both tests verify markdown file content (not runtime behavior) and follow the exact pattern used by existing scenarios in `tests/scenarios/`.

---

## Test 1: `tests/prompt-injection-protection.sh`

**Covers:** AC-1, AC-2, AC-3, AC-4

### What it checks

| AC | Assertion |
|----|-----------|
| AC-1 | `core/external-input-sanitizer.md` exists; has 5 required sections (`## Purpose`, `## Applies To`, `## Process`, `## Constraints`, `## Failure Mode`); contains both marker strings (`EXTERNAL INPUT START`, `EXTERNAL INPUT END`); has ≥ 3 NEVER constraints |
| AC-2 | Loop over 5 pipeline skills (`fix-ticket`, `fix-bugs`, `implement-feature`, `scaffold`, `analyze-bug`): each must reference `core/external-input-sanitizer` |
| AC-3 | Loop over 5 agents (`triage-analyst`, `code-analyst`, `fixer`, `spec-analyst`, `reviewer`): each must contain both `EXTERNAL INPUT START` and `EXTERNAL INPUT END` markers, and the line referencing `EXTERNAL INPUT START` must use `NEVER` |
| AC-4 | `core/` contains exactly 14 `.md` files; CLAUDE.md declares `14 shared pipeline pattern contracts` |

---

## Test 2: `tests/plugin-version-tracking.sh`

**Covers:** AC-6, AC-7, AC-8, AC-9

### What it checks

| AC | Assertion |
|----|-----------|
| AC-6 | `state/schema.md` contains `plugin_version`; the field is documented with type `string`; `"plugin_version"` appears in the Full Schema Example JSON block |
| AC-7 | `core/state-manager.md` references both `plugin_version` and `plugin.json` |
| AC-8 | `skills/resume-ticket/SKILL.md` contains: `plugin_version` reference, `major version mismatch` warning text, `plugin.json` reference, and the mismatch line uses `WARN` (advisory, not a block) |
| AC-9 | `skills/resume-ticket/SKILL.md` explicitly handles absent/null `plugin_version` with silent skip (backwards compat guard — no WARN emitted for state files created before v6.7.0) |

---

## AC Coverage

| AC | Test file | Status |
|----|-----------|--------|
| AC-1 | prompt-injection-protection.sh | RED (not yet implemented) |
| AC-2 | prompt-injection-protection.sh | RED |
| AC-3 | prompt-injection-protection.sh | RED |
| AC-4 | prompt-injection-protection.sh | RED |
| AC-5 | (self-referential — passes once AC-1–4 are green) | — |
| AC-6 | plugin-version-tracking.sh | RED |
| AC-7 | plugin-version-tracking.sh | RED |
| AC-8 | plugin-version-tracking.sh | RED |
| AC-9 | plugin-version-tracking.sh | RED |
| AC-10 | (full harness regression — passes when all above are green) | — |

---

## Notes

- `REPO_ROOT` computed as `"$(cd "$(dirname "$0")/../.." && pwd)"` — identical to the existing test pattern (phase-5-tdd tests are two levels below the repo root: `.forge/phase-5-tdd/tests/`).
- Tests follow the `fail() / FAIL=1 / exit "$FAIL"` pattern with a single `PASS:` echo on success.
- AC-5 and AC-10 are not independently tested here — AC-5 is self-referential (tests this very test file) and AC-10 is the full regression harness pass; both are satisfied automatically once the implementation makes AC-1–4 and AC-6–9 green.
