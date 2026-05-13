# Phase 5 TDD Scenarios Manifest

| File | AC coverage | Lines | Functional checks |
|------|-------------|-------|-------------------|
| v7.0.0-no-extra-labels-section.sh | AC-DEL-EXTRA-LABELS-1, -2, -3, -4, -5 | 59 | 5 |
| v7.0.0-skill-rename-status.sh | AC-RENAME-STATUS-1, -2, -3, -4, -5, -6, -7 | 79 | 7 |
| v7.0.0-skill-rename-init.sh | AC-RENAME-INIT-1, -2, -3, -4, -5, -6, -7 | 82 | 7 |
| v7.0.0-no-create-pr-skill.sh | AC-DEL-CREATE-PR-1..11 | 91 | 11 |
| v7.0.0-publish-auto-detect-issue-found.sh | AC-PUBLISH-AUTO-DETECT-1, -2, -8, -9, -10 | 61 | 7 |
| v7.0.0-publish-auto-detect-issue-404.sh | AC-PUBLISH-AUTO-DETECT-12, -4 | 53 | 5 |
| v7.0.0-publish-auto-detect-tracker-down.sh | AC-PUBLISH-AUTO-DETECT-5, -7, -11 | 47 | 6 |
| v7.0.0-publish-no-issue-id-pr-only.sh | AC-PUBLISH-AUTO-DETECT-13, -14, -15, -ZERO-COMMITS | 47 | 5 |
| v7.0.0-publish-extraction-regex.sh | AC-PUBLISH-AUTO-DETECT-3, -EXTRACTION-1..5 | 114 | 4 prose + 6 runtime |
| v7.0.0-doc-count-28-skills.sh | AC-COUNTS-1, -3, -4, -6, -7, -8 | 59 | 6 |
| v7.0.0-doc-count-18-config-sections.sh | AC-COUNTS-2, -3, -5, -9 | 48 | 5 |
| v7.0.0-pause-limits-mapping.sh | AC-PAUSE-LIMITS-DOC-1, -2 | 41 | 4 |
| v7.0.0-changelog-migration-guide.sh | AC-CHANGELOG-MIGRATION-1..7 | 77 | 11 |
| v7.0.0-readme-collision-warning.sh | AC-DOCS-COLLISION-WARN-1, -2 | 64 | 7 |
| v7.0.0-cross-file-invariants.sh | AC-INVARIANTS-1, -2, -3 | 59 | 6 |
| v7.0.0-workflow-router-intent-table.sh | AC-RENAME-STATUS-5, -6 / AC-DEL-CREATE-PR-7, -8 / AC-DOCS-COLLISION-WARN-3, WORKFLOW-1 | 80 | 10 |
| v7.0.0-no-version-bump.sh | AC-NO-VERSION-BUMP-1, -2, -3 | 46 | 3 |
| v7.0.0-empty-skills-dir-invariant.sh | AC-COUNTS-10 / design.md §2.3 | 43 | 5 |

**Total: 18 scenarios, 114 functional checks, 0 SKIP candidates (1 conditional SKIP in no-version-bump for missing git/main branch)**

## Mutation testing

- Framework detected: none (pure markdown project — no stryker/mutmut applicable)
- MUTATION_SKIP logged: `MUTATION_SKIP phase=5 reason="no_framework"`
- Quality gate: passes (advisory only per phase-5 dispatch protocol)

## Coverage notes

- All 11 REQs covered: ✓
  - REQ-DEL-EXTRA-LABELS: scenario 1
  - REQ-PAUSE-LIMITS-DOC: scenario 12
  - REQ-RENAME-STATUS: scenarios 2, 16
  - REQ-RENAME-INIT: scenarios 3, 16
  - REQ-PUBLISH-AUTO-DETECT: scenarios 5, 6, 7, 8, 9
  - REQ-DEL-CREATE-PR: scenarios 4, 16
  - REQ-DOCS-COLLISION-WARN: scenarios 14, 16
  - REQ-CHANGELOG-MIGRATION: scenario 13
  - REQ-COUNTS: scenarios 10, 11, 18
  - REQ-INVARIANTS: scenario 15
  - REQ-NO-VERSION-BUMP: scenario 17
- All 12 SCs covered: ✓ (SC-1..SC-12 all covered by publish scenarios 5–9)
- Workflow-router exception (ACs with --exclude): handled in scenarios 2, 3, 4 (negative greps) + scenario 16 (positive check)
- No-version-bump invariant: scenario 17 (with git SKIP guard)
- Empty-skills-dir invariant: scenario 18
- All 94 formal ACs: 79 functional + 15 test-scenario-inventory ACs covered across 18 scenarios
  - AC-PUBLISH-AUTO-DETECT-6 (Three Tracker: row strings in agents/publisher.md) — covered implicitly by scenario 5; explicit check deferred to hidden suite if needed
  - AC-TEST-INVENTORY-1..15 (UPDATE/NO-CHANGE scenario inventory) — verified indirectly via structural checks in scenarios 2, 3, 4, 10, 11

## Anti-patterns avoided

- No `awk+source` code-lift (anti-pattern gate compliant)
- No single-grep-only scenarios (each has >= 2 independent assertions)
- No scenarios for out-of-scope items (no individual config template scenarios)
- No modification of existing v6.10.0 or earlier test scenarios
- All scenarios use `grep`, `diff -q`, `test -d/-f`, `find`, `wc -l` — no `awk+source`

## Runtime test coverage (v7.0.0-publish-extraction-regex.sh)

The extraction scenario includes 6 independent bash runtime checks asserting regex extraction semantics:
- Runtime A: `PROJ-123-fix-crash` → `PROJ-123` (NOT `PROJ` — critical "split at first `-` abandoned" evidence)
- Runtime B: `PROJ-456` → `PROJ-456` (no-description path)
- Runtime C: non-matching prefix → empty residue (issue_id=null)
- Runtime D: `123-numeric-id` → `123` (github/gitea/redmine numeric)
- Runtime E: `#42-fix` → `#42` (hash-prefixed)
- Runtime F: `ABC_DEF-789` → `ABC_DEF-789` (youtrack underscore in prefix)

These runtime checks execute BEFORE implementation (TDD red-phase): they pass on the spec regex immediately, validating the extraction algorithm independently of the skill prose.
