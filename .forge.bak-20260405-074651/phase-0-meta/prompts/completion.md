# Phase 9 — Completion

You are a **Release Manager** finalizing a version release for the ceos-agents plugin.

## Task Context

Two features were implemented in `agents/scaffolder.md` for ceos-agents v6.3.0:
1. E2E Test Generation — conditional Batch 7 for Playwright e2e test suite in web projects
2. Application Documentation for Agents — Batch 8 generating `docs/ARCHITECTURE.md` + Module Docs population

## Completion Checklist

### Pre-Commit Verification

- [ ] Run `./tests/harness/run-tests.sh` — ALL tests must pass (41 existing + new tests)
- [ ] Verify no unintended file changes: `git diff --name-only` should show only:
  - `agents/scaffolder.md`
  - `CHANGELOG.md`
  - `.claude-plugin/plugin.json`
  - `.claude-plugin/marketplace.json`
  - `docs/plans/roadmap.md`
  - `tests/scenarios/scaffold-e2e-and-docs.sh` (or similar new test file)
  - Possibly `skills/scaffold/SKILL.md` (if Module Docs changes were needed)
- [ ] Verify `.claude/settings.local.json` is NOT staged (per project convention)

### Commit Strategy (per project convention)

1. **Commit 1 — Feature implementation:**
   All content changes + changelog + tests in one commit:
   ```
   feat: scaffold E2E test generation + application documentation (v6.3.0)
   ```

2. **Commit 2 — Version bump:**
   Separate commit (per project convention):
   ```
   chore: bump version 6.2.0 → 6.3.0
   ```

### Post-Commit

- [ ] Create git tag: `v6.3.0`
- [ ] Verify tag points to version bump commit

### Release Summary

Produce a concise summary for the user:

```markdown
## v6.3.0 Release Summary

### What changed
- **Scaffolder Batch 7 (E2E Tests):** Conditional batch generates Playwright e2e test suite for web projects. Includes config file, smoke test, and test script. Skipped for non-web projects or when Playwright is not in dependencies.
- **Scaffolder Batch 8 (App Documentation):** Generates `docs/ARCHITECTURE.md` for all projects with stack choices, directory structure, key patterns, and configuration approach. Populates `Module Docs | Path` in CLAUDE.md Automation Config.
- **Quality scorecard:** 2 new items (E2E Test Setup, App Documentation) — total now 11.
- **File count targets:** Updated to accommodate new files (up to 26 for web+design+e2e).

### Files changed
| File | Change |
|------|--------|
| `agents/scaffolder.md` | Batch 7, Batch 8, 2 scorecard items, 2 constraints, file count update, Module Docs in config checklist |
| `CHANGELOG.md` | v6.3.0 entry |
| `.claude-plugin/plugin.json` | 6.2.0 → 6.3.0 |
| `.claude-plugin/marketplace.json` | 6.2.0 → 6.3.0 |
| `docs/plans/roadmap.md` | 2 items moved to DONE |
| `tests/scenarios/scaffold-*.sh` | New structural test |

### Test results
- Existing tests: {count} PASS, 0 FAIL
- New tests: {count} PASS, 0 FAIL

### Breaking changes
None — both features are additive and backward-compatible.
```

## Anti-Patterns

- Do NOT push to remote unless explicitly asked
- Do NOT skip running the test suite before committing
- Do NOT amend existing commits — create new ones
- Do NOT forget the changelog — it is part of closing a version (per project convention)
