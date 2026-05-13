# Implementation Plan: v6.3.0 — Scaffold E2E Test Generation + Application Documentation

**Version:** 6.2.0 -> 6.3.0 (MINOR — new backward-compatible features, no contract changes)
**Date:** 2026-04-05
**Scope:** 2 features in `agents/scaffolder.md`, plus version bump, changelog, roadmap, tests

---

## Task Graph

| ID | Task | File(s) | Dependencies | Size |
|----|------|---------|-------------|------|
| T1 | Add Batch 7 (E2E Test Generation) to scaffolder agent | `agents/scaffolder.md` | none | M |
| T2 | Add Batch 8 (Application Documentation) to scaffolder agent | `agents/scaffolder.md` | none | M |
| T3 | Add scorecard items for Batch 7 + Batch 8 | `agents/scaffolder.md` | T1, T2 | S |
| T4 | Update file count ceiling in constraints | `agents/scaffolder.md` | T1, T2 | XS |
| T5 | Add Module Docs auto-population to CLAUDE.md generation (Step 3) | `agents/scaffolder.md` | T2 | S |
| T6 | Update scaffold SKILL.md for Module Docs awareness | `skills/scaffold/SKILL.md` | T5 | S |
| T7 | Add new test: scaffolder-e2e-batch.sh | `tests/scenarios/scaffolder-e2e-batch.sh` | T1, T2, T3, T4 | M |
| T8 | Update roadmap — mark both items DONE | `docs/plans/roadmap.md` | none | S |
| T9 | Add changelog entry for v6.3.0 | `CHANGELOG.md` | T1-T8 | S |
| T10 | Version bump 6.2.0 -> 6.3.0 | `plugin.json`, `marketplace.json`, `roadmap.md` | T9 | XS |

---

## Execution Phases

### Phase 1: Scaffolder Agent Changes (T1, T2, T3, T4, T5) — all in `agents/scaffolder.md`

All five tasks edit the same file and should be applied sequentially in one pass.

### Phase 2: Skill Update (T6) — `skills/scaffold/SKILL.md`

### Phase 3: Test (T7) — new test file

### Phase 4: Roadmap (T8) — `docs/plans/roadmap.md`

### Phase 5: Changelog (T9) — `CHANGELOG.md`

### Phase 6: Version Bump (T10) — `plugin.json`, `marketplace.json`, `roadmap.md`

---

## Commit Strategy

Following project conventions:

1. **Commit 1:** Content changes + changelog (T1-T9)
   ```
   feat: scaffold E2E test generation + application documentation (v6.3.0)
   ```

2. **Commit 2:** Version bump only (T10)
   ```
   chore: bump version 6.2.0 -> 6.3.0
   ```

---

## Detailed Task Descriptions

### T1: Add Batch 7 (E2E Test Generation) to `agents/scaffolder.md`

**Location:** Insert after Batch 6 (Design) block, before Step 3 (CLAUDE.md generation).

**Exact content to add (after the Batch 6 closing paragraph about `globals.css`):**

```markdown
   **Batch 7 — E2E Tests (conditional — web projects with Playwright only):**
   Skip this batch entirely if:
   - The project is NOT a web project (same detection logic as Batch 6), OR
   - Playwright is NOT in the project's dependencies (check package.json `devDependencies` or `dependencies` for `@playwright/test`)

   If web project with Playwright detected:
   - `playwright.config.ts` (or `.js`): base URL from environment variable (`BASE_URL` or `http://localhost:3000`), `testDir` pointing to e2e test directory, `webServer` section with start command from Build & Test config, reasonable timeout (30s default)
   - `e2e/smoke.spec.ts` (or equivalent): at least 1 smoke test verifying the application loads (navigate to `/`, assert page title or visible heading, check no console errors)
   - Add `"test:e2e": "npx playwright test"` script to `package.json`
   - Add `playwright-report/` and `test-results/` to `.gitignore`
```

**Key design decisions:**
- Follows Batch 6 conditional pattern exactly (same web project detection logic + additional Playwright check)
- Uses `@playwright/test` as the detection target (standard Playwright Test package)
- Generates minimal viable e2e setup (config + 1 smoke test + npm script)
- Only applies to JS/TS stacks (Playwright is Node.js-based, so `package.json` is guaranteed)

### T2: Add Batch 8 (Application Documentation) to `agents/scaffolder.md`

**Location:** Insert after the new Batch 7, before Step 3 (CLAUDE.md generation).

**Exact content to add:**

```markdown
   **Batch 8 — Application Documentation (always generated):**
   - `docs/ARCHITECTURE.md` containing:
     - **Stack Choices:** Language, framework, database (if any), testing framework, linter — with one-sentence rationale for each choice
     - **Directory Structure:** Tree-style listing of the generated project structure with purpose annotations for each directory and key file
     - **Key Patterns:** Describe the primary patterns used (e.g., MVC, service layer, repository pattern, component-based UI) — only patterns actually present in the skeleton
     - **Configuration Approach:** How the project handles configuration (environment variables, config files, dotenv) and which files are involved
   - File should be 80-150 lines — concise but useful for downstream agents
```

**Key design decisions:**
- NOT conditional — every scaffolded project gets documentation
- Single file (`docs/ARCHITECTURE.md`) rather than multiple files — keeps it simple
- Content is scaffold-aware (describes what was generated, not what will be built later)
- Size constraint (80-150 lines) prevents over-generation

### T3: Add Scorecard Items for Batch 7 + Batch 8

**Location:** In `agents/scaffolder.md`, Step 4b scorecard (after item 9 "Design system").

**Add two new items to the scorecard checklist (steps 10 and 11):**

```markdown
    10. **E2E test setup:** (web projects with Playwright only) playwright.config present? At least 1 e2e smoke test? Test script in package.json?
    11. **Application documentation:** docs/ARCHITECTURE.md present? Contains all 4 sections (Stack Choices, Directory Structure, Key Patterns, Configuration Approach)?
```

**Also update the Quality Scorecard table in the Output section (Step 5) to add the two new rows:**

```markdown
     | E2E test setup | PASS | playwright.config.ts, 1 smoke test (web+Playwright project) |
     | App documentation | PASS | docs/ARCHITECTURE.md with 4 sections |
```

### T4: Update File Count Ceiling in Constraints

**Location:** In `agents/scaffolder.md`, the Constraints section, the line starting with "Target file count:".

**Current text:**
```
- Target file count: 10-15 files for simple stacks, up to 20 for stacks with database + CI + Docker, up to 23 for web projects with design system. Avoid unnecessary boilerplate — every file must serve a purpose.
```

**New text:**
```
- Target file count: 10-15 files for simple stacks, up to 20 for stacks with database + CI + Docker, up to 23 for web projects with design system, up to 27 for web projects with design system + E2E tests + documentation. Avoid unnecessary boilerplate — every file must serve a purpose.
```

**Rationale:** Batch 7 adds up to 3 files (playwright.config.ts, e2e/smoke.spec.ts, updates to existing package.json and .gitignore don't count as new files — actually 2 new files + updates). Batch 8 adds 1 file (docs/ARCHITECTURE.md). So maximum addition is ~3-4 files. 23 + 4 = 27 is a reasonable ceiling.

### T5: Add Module Docs Auto-Population to CLAUDE.md Generation

**Location:** In `agents/scaffolder.md`, Step 3 (CLAUDE.md generation), in the "Optional sections" checklist.

**Add a new checkbox item after the existing optional items:**

```markdown
   - [ ] `### Module Docs` — Path set to `docs/` (always include when Batch 8 generates docs/ARCHITECTURE.md)
```

**Key point:** This is NOT conditional. Since Batch 8 always generates `docs/ARCHITECTURE.md`, the Module Docs section should always be included in the generated CLAUDE.md with `Path: docs/`. This connects the generated documentation to all downstream agents (code-analyst, architect) that read Module Docs.

### T6: Update scaffold SKILL.md for Module Docs Awareness

**Location:** In `skills/scaffold/SKILL.md`, the Final Report (Step 9) output template.

**Change:** Add Module Docs reference to the Final Report output. In the "### Generated files:" section, the `docs/ARCHITECTURE.md` will naturally appear as a generated file. No structural changes needed to the SKILL.md pipeline steps because:

1. The scaffolder agent (T5) already generates the CLAUDE.md Module Docs section
2. The scaffold SKILL.md Step 3 runs the scaffolder agent which handles everything
3. Step 4a (Auto-fill CLAUDE.md) already handles filling values from in-memory state

**Actual change needed:** In the SKILL.md's Step 3 (Scaffold Skeleton) context passed to the scaffolder agent, add a note:

After the line:
```
  Mode indicator: scaffold-v2 (so scaffolder generates E2E Test config + Decomposition defaults)
```

Add:
```
  Note: scaffolder generates docs/ARCHITECTURE.md and populates Module Docs config section automatically
```

This is a small annotation ensuring the scaffolder agent's behavior is documented in the skill that dispatches it.

### T7: Add Test — scaffolder-e2e-batch.sh

**Location:** New file `tests/scenarios/scaffolder-e2e-batch.sh`

**Pattern:** Follow existing test patterns (set -e, REPO_ROOT detection, grep assertions against agents/scaffolder.md).

**Test assertions:**

```bash
#!/usr/bin/env bash
# Test: Scaffolder agent has Batch 7 (E2E) and Batch 8 (Docs) with correct structure
# Validates: Batch 7 conditional pattern, Batch 8 unconditional, scorecard items,
#            file count ceiling, Module Docs in optional sections
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SCAFFOLDER="$REPO_ROOT/agents/scaffolder.md"

FAIL=0
fail() { echo "FAIL: $1"; FAIL=1; }

# --- Batch 7: E2E Tests ---

# Batch 7 heading present
if ! grep -q "Batch 7.*E2E" "$SCAFFOLDER"; then
  fail "scaffolder.md missing Batch 7 (E2E Tests)"
fi

# Batch 7 is conditional (same pattern as Batch 6)
if ! grep -q "Skip this batch entirely" "$SCAFFOLDER"; then
  fail "scaffolder.md Batch 7 missing conditional skip pattern"
fi

# Batch 7 mentions Playwright detection
if ! grep -q "@playwright/test" "$SCAFFOLDER"; then
  fail "scaffolder.md Batch 7 missing Playwright dependency check"
fi

# Batch 7 mentions playwright.config
if ! grep -q "playwright.config" "$SCAFFOLDER"; then
  fail "scaffolder.md Batch 7 missing playwright.config generation"
fi

# Batch 7 mentions smoke test
if ! grep -q "smoke" "$SCAFFOLDER"; then
  fail "scaffolder.md Batch 7 missing smoke test reference"
fi

# --- Batch 8: Application Documentation ---

# Batch 8 heading present
if ! grep -q "Batch 8.*Documentation" "$SCAFFOLDER"; then
  fail "scaffolder.md missing Batch 8 (Application Documentation)"
fi

# Batch 8 is NOT conditional (always generated)
# Check that "always generated" or equivalent appears near Batch 8
if ! grep -q "always generated" "$SCAFFOLDER"; then
  fail "scaffolder.md Batch 8 missing 'always generated' marker"
fi

# Batch 8 mentions docs/ARCHITECTURE.md
if ! grep -q "docs/ARCHITECTURE.md" "$SCAFFOLDER"; then
  fail "scaffolder.md Batch 8 missing docs/ARCHITECTURE.md reference"
fi

# Batch 8 mentions required sections
for section in "Stack Choices" "Directory Structure" "Key Patterns" "Configuration Approach"; do
  if ! grep -q "$section" "$SCAFFOLDER"; then
    fail "scaffolder.md Batch 8 missing required section: $section"
  fi
done

# --- Scorecard ---

# E2E test setup scorecard item
if ! grep -q "E2E test setup" "$SCAFFOLDER"; then
  fail "scaffolder.md scorecard missing 'E2E test setup' item"
fi

# Application documentation scorecard item
if ! grep -qi "App.* documentation\|Application documentation" "$SCAFFOLDER"; then
  fail "scaffolder.md scorecard missing 'Application documentation' item"
fi

# --- File count ceiling ---

# File count mentions 27 (or similar ceiling for full web + e2e + docs)
if ! grep -q "27" "$SCAFFOLDER"; then
  fail "scaffolder.md constraints missing updated file count ceiling (27)"
fi

# --- Module Docs ---

# Module Docs in optional sections
if ! grep -q "Module Docs" "$SCAFFOLDER"; then
  fail "scaffolder.md missing Module Docs in CLAUDE.md optional sections"
fi

# --- Batch ordering ---

# Batch 7 appears before Batch 8
BATCH7_LINE=$(grep -n "Batch 7" "$SCAFFOLDER" | head -1 | cut -d: -f1)
BATCH8_LINE=$(grep -n "Batch 8" "$SCAFFOLDER" | head -1 | cut -d: -f1)
if [ -z "$BATCH7_LINE" ] || [ -z "$BATCH8_LINE" ] || [ "$BATCH7_LINE" -ge "$BATCH8_LINE" ]; then
  fail "Batch 7 must appear before Batch 8 in scaffolder.md"
fi

# Both batches appear before Step 3 (CLAUDE.md generation)
STEP3_LINE=$(grep -n "CLAUDE.md generation" "$SCAFFOLDER" | head -1 | cut -d: -f1)
if [ -z "$STEP3_LINE" ]; then
  fail "Could not find 'CLAUDE.md generation' step in scaffolder.md"
elif [ "$BATCH8_LINE" -ge "$STEP3_LINE" ]; then
  fail "Batch 8 must appear before CLAUDE.md generation step"
fi

[ "$FAIL" -eq 0 ] && echo "PASS: Scaffolder Batch 7 (E2E) + Batch 8 (Docs) — structure, conditions, scorecard, file count, ordering"
exit "$FAIL"
```

**Total assertions:** 14 checks covering:
- Batch 7 presence, conditional pattern, Playwright detection, config file, smoke test
- Batch 8 presence, unconditional marker, ARCHITECTURE.md, 4 required sections
- Scorecard items (2)
- File count ceiling
- Module Docs in optional sections
- Ordering (Batch 7 before Batch 8, both before CLAUDE.md generation step)

### T8: Update Roadmap

**Location:** `docs/plans/roadmap.md`

**Changes:**

1. Move the "Scaffold: E2E Test Generation" item from `## PLANNED -- Next` to a new `## DONE -- v6.3.0` section.

2. Move the "Scaffold: Application Documentation for Agents" item from `## PLANNED -- Next` to the same `## DONE -- v6.3.0` section.

3. Update `> **Current version:** v6.2.0` to `v6.3.0` in the header (this happens in T10 during version bump, but the DONE section creation happens in T8).

4. The new DONE section should be placed after `## DONE -- v6.2.0` and before `## DONE -- v6.1.9`, following reverse chronological order. Actually, looking at the roadmap structure, DONE sections are in reverse chronological order at the top. The new section should be inserted right after `## DONE -- v6.2.0 (E2E Deployment Guard)` block.

**New section content:**

```markdown
## DONE -- v6.3.0 (Scaffold Quality: E2E + Docs)

### Scaffold: E2E Test Generation (Batch 7)
**Source:** User feedback (2026-04-04)

Scaffolder agent generates a basic Playwright e2e test suite when the tech stack includes a web framework and Playwright is in dependencies. Conditional -- skipped for non-web projects or projects without Playwright. Follows Batch 6 conditional pattern.

Generated files: `playwright.config.ts`, `e2e/smoke.spec.ts`, `test:e2e` script in `package.json`. Scorecard: "E2E Test Setup" item (conditional). File count ceiling raised to 27.

**Files:** `agents/scaffolder.md`

### Scaffold: Application Documentation for Agents (Batch 8)
**Source:** User feedback (2026-04-04)

Scaffolder agent generates `docs/ARCHITECTURE.md` summarizing stack choices, directory structure, key patterns, and configuration approach. NOT conditional -- every project gets documentation. Module Docs config section auto-populated with `Path: docs/`.

Scorecard: "Application Documentation" item (always checked). Downstream agents (code-analyst, architect) automatically consume via Module Docs config.

**Files:** `agents/scaffolder.md`, `skills/scaffold/SKILL.md`
```

5. Remove the two items from `## PLANNED -- Next`. If PLANNED -- Next becomes empty (only the Pipeline Output Verification and Unified Plugin Design System items remain -- check carefully), keep those remaining items.

### T9: Changelog Entry

**Location:** `CHANGELOG.md`, insert new entry at the top (after the header, before `## [6.2.0]`).

**Content:**

```markdown
## [6.3.0] -- 2026-04-05

**MINOR** -- Scaffold quality improvements: E2E test generation for web projects with Playwright, application documentation for all projects.

### Added
- **Scaffolder Batch 7 "E2E Tests":** Conditional batch for web projects with Playwright -- generates `playwright.config.ts`, smoke e2e test (`e2e/smoke.spec.ts`), and `test:e2e` script in `package.json`. Skipped for non-web projects or projects without Playwright dependency. Follows Batch 6 conditional detection pattern.
- **Scaffolder Batch 8 "Application Documentation":** Unconditional batch -- generates `docs/ARCHITECTURE.md` with Stack Choices, Directory Structure, Key Patterns, and Configuration Approach sections. Every scaffolded project gets documentation.
- **Scaffolder scorecard:** Two new checks -- "E2E test setup" (conditional on web+Playwright) and "Application documentation" (always checked).
- **Scaffolder CLAUDE.md generation:** `Module Docs` optional section auto-populated with `Path: docs/` pointing to generated documentation.
- **Test:** New `scaffolder-e2e-batch.sh` scenario (14 assertions) validating Batch 7/8 structure, conditions, scorecard, file count, and ordering.

### Changed
- **Scaffolder file count:** Target ceiling raised from 23 to 27 for web projects with design system + E2E tests + documentation.
- **Roadmap:** "Scaffold: E2E Test Generation" and "Scaffold: Application Documentation for Agents" moved from PLANNED to DONE.
```

### T10: Version Bump

**Files to update:**

1. `.claude-plugin/plugin.json`: change `"version": "6.2.0"` to `"version": "6.3.0"`
2. `.claude-plugin/marketplace.json`: change `"version": "6.2.0"` to `"version": "6.3.0"`
3. `docs/plans/roadmap.md`: change `> **Current version:** v6.2.0` to `> **Current version:** v6.3.0` and `> **Last updated:** 2026-04-04` to `> **Last updated:** 2026-04-05`

---

## Pre-Implementation Checklist

Before starting implementation, verify:

- [ ] `./tests/harness/run-tests.sh` passes on current codebase (39 tests)
- [ ] No uncommitted changes in working directory

## Post-Implementation Checklist

After implementation, before committing:

- [ ] `./tests/harness/run-tests.sh` passes (should be 40 tests now -- 39 existing + 1 new)
- [ ] New test `scaffolder-e2e-batch.sh` passes individually
- [ ] Batch 7 follows exact conditional pattern of Batch 6 (grep for "Skip this batch entirely")
- [ ] Batch 8 has "always generated" marker (not conditional)
- [ ] Scorecard has exactly 11 items (was 9)
- [ ] File count ceiling mentions 27
- [ ] Module Docs appears in optional sections checklist
- [ ] Changelog entry format matches existing entries
- [ ] Both roadmap items moved from PLANNED to DONE
- [ ] Version is 6.3.0 in plugin.json and marketplace.json

---

## Risk Assessment

| Risk | Likelihood | Mitigation |
|------|-----------|------------|
| Existing tests break due to scaffolder.md changes | Low | Changes are additive (new batches, new scorecard items). Existing grep patterns still match. |
| `scaffold-v2-happy-path.sh` breaks | Very Low | That test checks SKILL.md pipeline steps, not scaffolder agent batches. |
| Batch 7 conditional logic conflicts with Batch 6 | Low | Batch 7 uses the same detection logic + additional Playwright check. Independent of Batch 6. |
| Module Docs auto-population misses consuming agents | None | `code-analyst.md` and `architect.md` already read Module Docs (added in v5.4.0). No agent changes needed. |

---

## Files Changed Summary

| File | Action | Lines Changed (approx) |
|------|--------|----------------------|
| `agents/scaffolder.md` | Edit | +40 lines (Batch 7, Batch 8, scorecard, constraints, Module Docs) |
| `skills/scaffold/SKILL.md` | Edit | +1 line (context note) |
| `tests/scenarios/scaffolder-e2e-batch.sh` | New | ~95 lines |
| `docs/plans/roadmap.md` | Edit | ~30 lines moved/added, ~20 lines removed |
| `CHANGELOG.md` | Edit | +15 lines |
| `.claude-plugin/plugin.json` | Edit | 1 line |
| `.claude-plugin/marketplace.json` | Edit | 1 line |
| **Total** | | ~180 lines |
