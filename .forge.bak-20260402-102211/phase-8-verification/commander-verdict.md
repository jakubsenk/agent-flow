# Commander Verdict: Commands-to-Skills Migration (v6.0.0)

**Date:** 2026-04-01
**Verifier:** Claude Opus 4.6 (automated verification)
**Scope:** Full structural migration from `commands/` to `skills/` -- 25 command files + workflow-router

---

## Dimension 1: Security (weight: 0.25)

**Score: 1.0**

### Findings

- No credentials or secrets found in any SKILL.md file.
- `disable-model-invocation: true` is correctly applied to all 14 pipeline/destructive skills:
  fix-ticket, fix-bugs, implement-feature, scaffold, publish, create-pr, onboard, init, scaffold-add, check-deploy, resume-ticket, changelog, version-bump, migrate-config.
- All 11 read-only skills correctly omit `disable-model-invocation`:
  analyze-bug, check-setup, status, dashboard, metrics, estimate, prioritize, template, scaffold-validate, version-check, discuss.
- `allowed-tools` fields match spec exactly for all sampled skills (6/6 verified: fix-ticket, analyze-bug, publish, template, check-setup, init). No accidental tool access expansion.
- No new tool access was introduced during migration; allowed-tools are carried over verbatim from the old command frontmatter.

### Issues

None.

---

## Dimension 2: Correctness (weight: 0.25)

**Score: 0.95**

### Findings

- **FC-1 PASS:** `commands/` directory does not exist.
- **FC-2 PASS:** `skills/` contains exactly 26 directories (25 migrated + workflow-router).
- **FC-3 PASS:** Every skill directory contains exactly 1 `SKILL.md` file.
- **FC-4 PASS:** All 26 SKILL.md files have `name:` and `description:` in frontmatter.
- **FC-5 PASS:** All 14 pipeline skills have `disable-model-invocation: true`.
- **FC-6 PASS:** All 11 read-only skills do NOT have `disable-model-invocation`.
- **FC-9 PASS:** `plugin.json` version is `6.0.0`.
- **FC-10 PASS:** `marketplace.json` version is `6.0.0`.
- **FC-8 PASS:** Test harness passes -- 39/39 scenarios (exceeds FC-8's minimum of 38).
- **Content preservation:** Body content (after frontmatter) is identical between old commands and new skills. Verified by line count comparison for 4 files (fix-ticket: 386/386, analyze-bug: 22/22, scaffold: 776/776, discuss: 53/53) and character-by-character comparison of first 20 lines for fix-ticket.
- Core file references updated: `core/fixer-reviewer-loop.md`, `core/decomposition-heuristics.md`, `core/mcp-detection.md` -- all now reference `skills/{name}/SKILL.md` paths.
- `docs/guides/mcp-configuration.md` updated to reference `skills/check-setup/SKILL.md`.

### Issues

1. **CLAUDE.md line 181** -- still reads "commands instruct it to use this format" instead of "skills instruct it to use this format". The spec (SPEC-4, Rule Group C, Section 6e) explicitly requires this change. This is a minor text defect that does not affect runtime behavior.

---

## Dimension 3: Spec Alignment (weight: 0.25)

**Score: 0.95**

### Formal Criteria Checklist

| FC | Description | Result |
|----|-------------|--------|
| FC-1 | `commands/` directory does not exist | PASS |
| FC-2 | `skills/` contains exactly 26 directories | PASS |
| FC-3 | Each skill directory has exactly 1 SKILL.md | PASS |
| FC-4 | Every SKILL.md has `name:` and `description:` | PASS |
| FC-5 | 14 pipeline skills have `disable-model-invocation: true` | PASS |
| FC-6 | 11 read-only skills do NOT have `disable-model-invocation` | PASS |
| FC-7 | No functional `commands/` references | PASS (see note) |
| FC-8 | Test harness passes (38+ scenarios) | PASS (39/39) |
| FC-9 | `plugin.json` version is `6.0.0` | PASS |
| FC-10 | `marketplace.json` version is `6.0.0` | PASS |

### FC-7 Note

The grep for `commands/` in functional files returns two hits:
1. `tests/scenarios/skills-directory-structure.sh` -- references `commands/` in the context of *verifying it does NOT exist* (FC-1 check). This is correct and expected.
2. `REVIEW-REPORT-v3.1.0.md` -- historical review document dated 2026-03-01 (pre-migration). This is comparable to CHANGELOG.md exclusions.

Neither represents a stale functional path reference. FC-7: **PASS**.

### Requirements Alignment

- **SPEC-1 (File Migration Manifest):** All 25 files migrated to correct destinations. Phase ordering (read-only first, pipeline second, cross-refs, CLAUDE.md, docs, delete, version-bump) followed.
- **SPEC-2 (Frontmatter Rules):** All sampled frontmatter matches spec exactly. `name`, `description`, `allowed-tools`, `disable-model-invocation`, and `argument-hint` fields all correct.
- **SPEC-4 (Cross-Reference Rules):** All rule groups (A through E) implemented. Test files, core files, CLAUDE.md, and docs all updated. Exclusions (CHANGELOG.md, docs/plans/, workflow-router) correctly preserved.
- **Design ADR-1 through ADR-5:** All design decisions respected. No file splitting. No content changes to body text. Test migration is mechanical path substitution. Backward compatibility maintained (namespace unchanged, $ARGUMENTS works identically).

### Issues

1. Same as Correctness issue: CLAUDE.md line 181 "commands instruct" not updated per SPEC-4 Section 6e. This is a spec deviation, though minor (one word in one line).

---

## Dimension 4: Robustness (weight: 0.25)

**Score: 1.0**

### Findings

- **No stale `commands/` references in functional files.** All test files, core files, skill files, and docs use `skills/{name}/SKILL.md` paths. The only remaining `commands/` strings are in verification test assertions (correct usage) and a historical review document.
- **Test coverage is adequate.** 39 test scenarios cover:
  - 2 new migration-specific tests (`skills-directory-structure.sh` covering FC-1/FC-2/FC-3, `skills-frontmatter-check.sh` covering FC-4/FC-5/FC-6)
  - 37 existing tests all updated to use new paths and all passing
  - Tests verify: directory structure, frontmatter completeness, pipeline consistency, cross-references, content patterns, feature pipeline, scaffold pipeline, state schema, core registry references, config consumption
- **CLAUDE.md accurately describes the new structure** -- Repository Structure section, Architecture section, Plugin Composability section, and Bug-Fix Pipeline section all updated.
- **Core file cross-references updated** -- all 3 core files (`fixer-reviewer-loop.md`, `decomposition-heuristics.md`, `mcp-detection.md`) now reference `skills/` paths.
- **workflow-router** has no file path references to `commands/` (uses namespace identifiers only).

### Issues

None.

---

## Aggregate Score

| Dimension | Weight | Score | Weighted |
|-----------|--------|-------|----------|
| Security | 0.25 | 1.00 | 0.250 |
| Correctness | 0.25 | 0.95 | 0.238 |
| Spec Alignment | 0.25 | 0.95 | 0.238 |
| Robustness | 0.25 | 1.00 | 0.250 |
| **Aggregate** | | | **0.975** |

---

## Verdict: FULL_PASS

All dimensions score >= 0.7 and aggregate score (0.975) >= 0.8.

### Summary

The commands-to-skills migration is structurally complete and correct. All 25 commands have been migrated to skill directories with proper frontmatter. The `commands/` directory has been deleted. Cross-references in tests (22 scenario files), core files (3), CLAUDE.md, and docs have been updated. Version is 6.0.0. All 39 tests pass. The `disable-model-invocation: true` safety flag is correctly applied to all 14 pipeline skills and correctly absent from all 11 read-only skills.

### Minor Defect (does not block pass)

- **CLAUDE.md line 181:** "commands instruct" should read "skills instruct" per SPEC-4 Section 6e. This is a single-word cosmetic defect in a documentation line with no runtime impact. Recommend fixing in the next patch.
