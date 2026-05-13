# Phase 6: Implementation Plan — v6.3.1 Patch

**Generated:** 2026-04-05
**Version:** 6.3.0 → 6.3.1 (PATCH)
**Scope:** 3 independent fixes + changelog/roadmap/version-bump

---

## 1. Task Graph Overview (DAG)

```
Group A (parallel):
  Task 1: analyze-bug UNCLEAR handler ─────────┐
  Task 2: fix-bugs UNCLEAR path ───────────────┤
                                                ├──► Group C (sequential)
Group B (parallel):                             │
  Task 3: scaffolder cross-stack Playwright ───┤
  Task 4: test grep fragility ─────────────────┘
                                                │
                                         Task 5: CHANGELOG.md
                                                │
                                         Task 6: roadmap.md
                                                │
                                         Task 7: version-bump (skill)
                                                │
                                         Verification: run-tests.sh
```

**Dependencies:**
- Tasks 1, 2, 3, 4: independent, no dependencies — run in parallel
- Task 5: depends on Tasks 1-4 (needs to describe all changes)
- Task 6: depends on Task 5 (references version)
- Task 7: depends on Task 6 (version-bump via skill)
- Verification: after all tasks

---

## 2. Task Specifications

### Task 1: analyze-bug UNCLEAR handler

**File:** `skills/analyze-bug/SKILL.md`
**Group:** A (parallel)
**Dependencies:** none

Add a new step 3a after step 3 that handles the UNCLEAR triage result by posting a block comment to the tracker.

**Edit 1.1 — Add UNCLEAR handler after triage step:**

```
file_path: skills/analyze-bug/SKILL.md
```

old_string:
```
3. Run `ceos-agents:triage-analyst` on bug $ARGUMENTS
   After successful triage, instruct the agent to post a checkpoint comment to the issue tracker: `[ceos-agents] Triage completed. Severity: {severity}. Area: {area}.`
4. If triage OK, run `ceos-agents:code-analyst`
```

new_string:
```
3. Run `ceos-agents:triage-analyst` on bug $ARGUMENTS
   After successful triage, instruct the agent to post a checkpoint comment to the issue tracker: `[ceos-agents] Triage completed. Severity: {severity}. Area: {area}.`
3a. If triage returns UNCLEAR (issue quality gate fails):
   - Post a block comment to the issue tracker using the Block Comment Template:
     ```
     [ceos-agents] 🔴 Pipeline Block
     Agent: triage-analyst
     Step: triage
     Reason: Issue is unclear — insufficient information to proceed with analysis.
     Detail: {triage-analyst output explaining what is missing}
     Recommendation: {triage-analyst recommendation for what the reporter should clarify}
     ```
   - Display the block result to the user and stop. Do NOT proceed to code-analyst.
4. If triage OK, run `ceos-agents:code-analyst`
```

---

### Task 2: fix-bugs UNCLEAR path explicit block comment

**File:** `skills/fix-bugs/SKILL.md`
**Group:** A (parallel)
**Dependencies:** none

Make the UNCLEAR path in fix-bugs triage step explicit about posting a block comment, matching fix-ticket's pattern.

**Edit 2.1 — Make UNCLEAR path explicit with block comment:**

```
file_path: skills/fix-bugs/SKILL.md
```

old_string:
```
- Duplicates → close, record as DUPLICATE, continue with next
- Unclear → record as UNCLEAR, continue with next (in dry-run do not write to the issue tracker)
- OK → continue
```

new_string:
```
- Duplicates → close, record as DUPLICATE, continue with next
- Unclear → Block: post block comment to the issue tracker using Block Comment Template (Agent: triage-analyst, Step: triage, Reason/Detail/Recommendation from triage output), then continue with next bug. In dry-run mode: record as UNCLEAR only, do NOT write to the issue tracker.
- OK → continue
```

---

### Task 3: scaffolder cross-stack Playwright detection

**File:** `agents/scaffolder.md`
**Group:** B (parallel)
**Dependencies:** none

Expand Batch 7 to detect Playwright across package managers and generate language-appropriate test files.

**Edit 3.1 — Replace Batch 7 Playwright detection and file generation:**

```
file_path: agents/scaffolder.md
```

old_string:
```
   **Batch 7 — E2E Tests (conditional — web projects with Playwright only):**
   Skip this batch entirely if:
   - The project is NOT a web project (same detection logic as Batch 6), OR
   - Playwright is NOT in the project's dependencies (check package.json `devDependencies` or `dependencies` for `@playwright/test`)

   If web project with Playwright detected:
   - Playwright configuration file (`playwright.config.ts` or `.js`): set `baseURL` from environment variable or `http://localhost:3000`, configure `testDir` pointing to e2e test directory, add `webServer` section with start command from Build & Test config, 30s default timeout
   - At least 1 e2e smoke test (`e2e/smoke.spec.ts` or equivalent): verify the application loads (navigate to `/`, assert page title or visible heading, check no console errors), verify basic navigation works (if router configured)
   - Add `"test:e2e": "npx playwright test"` script to `package.json`
   - Add `playwright-report/` and `test-results/` to `.gitignore`
```

new_string:
```
   **Batch 7 — E2E Tests (conditional — web projects with Playwright only):**
   Skip this batch entirely if:
   - The project is NOT a web project (same detection logic as Batch 6), OR
   - Playwright is NOT detected in the project's dependencies (see cross-stack detection below)

   **Cross-stack Playwright detection:** Check for Playwright in the project's package manager:
   - **JS/TS:** `package.json` `devDependencies` or `dependencies` contains `@playwright/test`
   - **Python:** `pyproject.toml` `[project.optional-dependencies]` or `[tool.pytest.ini_options]` or `requirements.txt` contains `pytest-playwright`
   - **Ruby:** `Gemfile` contains `capybara-playwright-driver`
   If none match → skip this batch.

   If web project with Playwright detected, generate language-appropriate files:

   **For JS/TS stacks (detected via `@playwright/test`):**
   - Playwright configuration file (`playwright.config.ts`): set `baseURL` from environment variable or `http://localhost:3000`, configure `testDir` pointing to e2e test directory, add `webServer` section with start command from Build & Test config, 30s default timeout
   - At least 1 e2e smoke test (`e2e/smoke.spec.ts`): verify the application loads (navigate to `/`, assert page title or visible heading, check no console errors), verify basic navigation works (if router configured)
   - Add `"test:e2e": "npx playwright test"` script to `package.json`
   - Add `playwright-report/` and `test-results/` to `.gitignore`

   **For Python stacks (detected via `pytest-playwright`):**
   - Pytest-playwright configuration in `pyproject.toml` (`[tool.pytest.ini_options]` with `--base-url` default) or `conftest.py` fixture for base URL
   - At least 1 e2e smoke test (`e2e/test_smoke.py`): verify the application loads (navigate to `/`, assert page title or visible heading), verify basic navigation works (if router configured)
   - Add `"test:e2e": "pytest e2e/"` or equivalent to the test scripts section of `pyproject.toml`
   - Add `.pytest_cache/` to `.gitignore` (if not already present)

   **For Ruby stacks (detected via `capybara-playwright-driver`):**
   - Capybara-Playwright configuration in `spec/support/capybara.rb` or `test/support/capybara.rb`: configure Capybara driver for Playwright, set `app_host` from environment variable or `http://localhost:3000`
   - At least 1 e2e smoke test (`spec/e2e/smoke_spec.rb` or `test/e2e/smoke_test.rb`): verify the application loads (visit `/`, assert page title or visible heading), verify basic navigation works (if router configured)
   - Add test task to `Rakefile` if not present
   - Add `tmp/capybara/` to `.gitignore`
```

---

### Task 4: test grep fragility fixes

**File:** `tests/scenarios/scaffolder-e2e-batch.sh`
**Group:** B (parallel)
**Dependencies:** none

Replace fragile grep patterns with context-aware ones that are Batch-specific.

**Edit 4.1 — Replace Batch 7 conditional pattern check (make Batch-specific):**

```
file_path: tests/scenarios/scaffolder-e2e-batch.sh
```

old_string:
```
# Batch 7 conditional pattern
grep -q "Skip this batch entirely" "$SCAFFOLDER" || fail "scaffolder.md Batch 7 missing conditional skip pattern"
```

new_string:
```
# Batch 7 conditional pattern (context-aware: must appear within Batch 7 section, not Batch 6)
grep -A5 "Batch 7" "$SCAFFOLDER" | grep -q "Skip this batch entirely" || fail "scaffolder.md Batch 7 missing conditional skip pattern"
```

**Edit 4.2 — Replace Playwright detection check (cross-stack):**

```
file_path: tests/scenarios/scaffolder-e2e-batch.sh
```

old_string:
```
# Batch 7 Playwright detection
grep -q "@playwright/test" "$SCAFFOLDER" || fail "scaffolder.md Batch 7 missing Playwright dependency check"
```

new_string:
```
# Batch 7 Playwright detection (cross-stack)
grep -q "@playwright/test" "$SCAFFOLDER" || fail "scaffolder.md Batch 7 missing JS Playwright dependency check"
grep -q "pytest-playwright" "$SCAFFOLDER" || fail "scaffolder.md Batch 7 missing Python Playwright dependency check"
grep -q "capybara-playwright-driver" "$SCAFFOLDER" || fail "scaffolder.md Batch 7 missing Ruby Playwright dependency check"
```

**Edit 4.3 — Replace file count ceiling check (make specific):**

```
file_path: tests/scenarios/scaffolder-e2e-batch.sh
```

old_string:
```
# File count ceiling
grep -q "27" "$SCAFFOLDER" || fail "scaffolder.md constraints missing updated file count ceiling (27)"
```

new_string:
```
# File count ceiling (context-aware: match exact phrase, not bare number)
grep -q "up to 27" "$SCAFFOLDER" || fail "scaffolder.md constraints missing updated file count ceiling (up to 27)"
```

**Edit 4.4 — Add cross-stack language-specific test file assertions:**

```
file_path: tests/scenarios/scaffolder-e2e-batch.sh
```

old_string:
```
# Batch ordering
BATCH7_LINE=$(grep -n "Batch 7" "$SCAFFOLDER" | head -1 | cut -d: -f1)
```

new_string:
```
# Batch 7 cross-stack: language-specific test file generation
grep -q "test_smoke.py" "$SCAFFOLDER" || fail "scaffolder.md Batch 7 missing Python e2e test file (test_smoke.py)"
grep -q "smoke_spec.rb" "$SCAFFOLDER" || fail "scaffolder.md Batch 7 missing Ruby e2e test file (smoke_spec.rb)"

# Batch ordering
BATCH7_LINE=$(grep -n "Batch 7" "$SCAFFOLDER" | head -1 | cut -d: -f1)
```

---

### Task 5: CHANGELOG.md entry

**File:** `CHANGELOG.md`
**Group:** C (sequential)
**Dependencies:** Tasks 1-4

Add v6.3.1 entry after the v6.3.0 header.

**Edit 5.1 — Add v6.3.1 changelog entry:**

```
file_path: CHANGELOG.md
```

old_string:
```
## [6.3.0] — 2026-04-05

**MINOR** — Scaffold quality improvements: E2E test generation for web projects with Playwright, application documentation for all projects.
```

new_string:
```
## [6.3.1] — 2026-04-05

**PATCH** — UNCLEAR triage handler for analyze-bug, cross-stack Playwright detection in scaffolder, test grep fragility fixes.

### Fixed
- **analyze-bug Step 3a:** Added UNCLEAR handler — when triage-analyst returns UNCLEAR, the skill now posts a block comment to the issue tracker using Block Comment Template instead of falling through to chat. Stops pipeline after posting.
- **fix-bugs Step 2 (Triage):** Made UNCLEAR path explicit — posts block comment to tracker (matching fix-ticket pattern). In dry-run mode: records only, no tracker writes.
- **Scaffolder Batch 7:** Cross-stack Playwright detection — checks `package.json` for `@playwright/test`, `pyproject.toml`/`requirements.txt` for `pytest-playwright`, `Gemfile` for `capybara-playwright-driver`. Generates language-appropriate test files (`.spec.ts` for JS/TS, `test_smoke.py` for Python, `smoke_spec.rb` for Ruby).
- **Test `scaffolder-e2e-batch.sh`:** Replaced fragile grep patterns with context-aware assertions — Batch 7 conditional check is now Batch-specific (`grep -A5 "Batch 7" | grep`), file count ceiling matches `up to 27` instead of bare `27`. Added cross-stack Playwright assertions (pytest-playwright, capybara-playwright-driver, test_smoke.py, smoke_spec.rb).

## [6.3.0] — 2026-04-05

**MINOR** — Scaffold quality improvements: E2E test generation for web projects with Playwright, application documentation for all projects.
```

---

### Task 6: roadmap.md — mark v6.3.1 as IMPLEMENTED

**File:** `docs/plans/roadmap.md`
**Group:** C (sequential)
**Dependencies:** Task 5

Move the v6.3.1 section from PLANNED to DONE, and update the current version header.

**Edit 6.1 — Update current version in header:**

```
file_path: docs/plans/roadmap.md
```

old_string:
```
> **Current version:** v6.3.0
> **Last updated:** 2026-04-05
```

new_string:
```
> **Current version:** v6.3.1
> **Last updated:** 2026-04-05
```

**Edit 6.2 — Move v6.3.1 from PLANNED to DONE (replace the PLANNED section with DONE section before v6.3.0 DONE):**

```
file_path: docs/plans/roadmap.md
```

old_string:
```
## PLANNED — Next

### Triage UNCLEAR Handler + Scaffold Patch Fixes — v6.3.1

#### fix: analyze-bug missing UNCLEAR handler
**Source:** Bug report (2026-04-05) — analyze-bug skill asked clarifying questions in chat instead of posting a block comment to YouTrack

**Problem:** `skills/analyze-bug/SKILL.md` (lines 23-25) only handles the success path after triage. When triage-analyst returns UNCLEAR (issue quality gate fails), the skill has no handler — the agent falls through to describing the problem in chat instead of posting a `[ceos-agents] 🔴 Pipeline Block` comment to the tracker. `fix-bugs` has a similar ambiguity: UNCLEAR path says "record as UNCLEAR" without explicitly saying "post block comment" (line 108). `fix-ticket` is correct (explicit `Unclear → Block`).

**Fix:**
- `skills/analyze-bug/SKILL.md`: Add UNCLEAR handler after triage step — on UNCLEAR, instruct agent to post block comment to tracker (same Block Comment Template format), then report result to user
- `skills/fix-bugs/SKILL.md`: Make UNCLEAR path explicit — "record as UNCLEAR, post block comment to tracker (in dry-run: record only, do not write to tracker)"

**Files:** `skills/analyze-bug/SKILL.md`, `skills/fix-bugs/SKILL.md`

#### fix: Scaffold Batch 7 cross-stack Playwright detection
**Source:** v6.3.0 Devil's Advocate review (2026-04-05) — Batch 7 only checks `package.json` for `@playwright/test`, misses non-JS web stacks

**Problem:** Batch 6 detects web projects across stacks (Django+templates, Rails+views, Flask+Jinja), but Batch 7's Playwright check only looks at `package.json`. Python web projects using `pytest-playwright` or Ruby projects are silently skipped. The generated `.ts` files also won't run without TypeScript tooling on non-JS stacks.

**Fix:** Batch 7 should detect Playwright across package managers (`package.json` for `@playwright/test`, `pyproject.toml`/`requirements.txt` for `pytest-playwright`, `Gemfile` for `capybara-playwright-driver`). Generate test files in the project's language (`.spec.ts` for JS/TS, `test_smoke.py` for Python, `smoke_spec.rb` for Ruby).

**Files:** `agents/scaffolder.md`, `tests/scenarios/scaffolder-e2e-batch.sh`

#### fix: Scaffold test grep semantic fragility
**Source:** v6.3.0 Devil's Advocate review (2026-04-05) — test uses `grep -q "Skip this batch entirely"` which matches both Batch 6 and Batch 7

**Problem:** `scaffolder-e2e-batch.sh` checks for conditional pattern with `grep "Skip this batch entirely"` — this string appears identically in Batch 6 (line 58) and Batch 7. If Batch 7's conditional logic is removed, the grep still matches Batch 6 (false positive). File count ceiling check (`grep "27"`) would also pass if 27 appears in any other context.

**Fix:** Use context-aware grep patterns: `grep -A2 "Batch 7" | grep -q "Skip this batch"` or check line ranges. Make file count assertion more specific: `grep "up to 27"`.

**Files:** `tests/scenarios/scaffolder-e2e-batch.sh`
```

new_string:
```
## DONE — v6.3.1 (UNCLEAR Handler + Scaffold Patch Fixes)

### fix: analyze-bug missing UNCLEAR handler
**Source:** Bug report (2026-04-05) — analyze-bug skill asked clarifying questions in chat instead of posting a block comment to YouTrack

Added UNCLEAR handler (step 3a) to `skills/analyze-bug/SKILL.md` — posts block comment to tracker when triage returns UNCLEAR. Made UNCLEAR path explicit in `skills/fix-bugs/SKILL.md` — posts block comment matching fix-ticket pattern.

**Files:** `skills/analyze-bug/SKILL.md`, `skills/fix-bugs/SKILL.md`

### fix: Scaffold Batch 7 cross-stack Playwright detection
**Source:** v6.3.0 Devil's Advocate review (2026-04-05)

Expanded Batch 7 Playwright detection to check `package.json` (`@playwright/test`), `pyproject.toml`/`requirements.txt` (`pytest-playwright`), and `Gemfile` (`capybara-playwright-driver`). Generates language-appropriate test files: `.spec.ts` for JS/TS, `test_smoke.py` for Python, `smoke_spec.rb` for Ruby.

**Files:** `agents/scaffolder.md`

### fix: Scaffold test grep semantic fragility
**Source:** v6.3.0 Devil's Advocate review (2026-04-05)

Replaced fragile grep patterns in `scaffolder-e2e-batch.sh` with context-aware assertions. Batch 7 conditional check uses `grep -A5 "Batch 7" | grep`. File count ceiling matches `up to 27`. Added cross-stack Playwright test assertions.

**Files:** `tests/scenarios/scaffolder-e2e-batch.sh`
```

**Edit 6.3 — Add separator and next PLANNED section after v6.3.1 DONE (before v6.4.0):**

```
file_path: docs/plans/roadmap.md
```

old_string:
```
---

### Decomposition Subtask Tracker Creation — v6.4.0 (feature)
```

new_string:
```
---

## PLANNED — Next

### Decomposition Subtask Tracker Creation — v6.4.0 (feature)
```

---

### Task 7: Version bump

**Group:** C (sequential)
**Dependencies:** Task 6

Invoke `/ceos-agents:version-bump` skill to bump 6.3.0 → 6.3.1 in `plugin.json` and `marketplace.json`, create git commit and tag.

**NOTE:** This task is handled by the skill, not by direct edits. The execution agent should invoke:
```
/ceos-agents:version-bump 6.3.1
```

For reference, the expected changes are:
- `.claude-plugin/plugin.json`: `"version": "6.3.0"` → `"version": "6.3.1"`
- `.claude-plugin/marketplace.json`: `"version": "6.3.0"` → `"version": "6.3.1"`

---

## 3. Parallel Group Assignments

| Group | Tasks | Can Start When | Estimated Edits |
|-------|-------|----------------|-----------------|
| A | Task 1, Task 2 | Immediately | 2 edits |
| B | Task 3, Task 4 | Immediately | 5 edits |
| C | Task 5, Task 6, Task 7 | After A + B complete | 4 edits + skill |

**Total edits:** 11 direct Edit tool calls + 1 skill invocation

---

## 4. Verification Steps

### Pre-commit verification
After all edits (Tasks 1-6) are applied, before version bump:

```bash
cd C:/gitea_ceos-agents && ./tests/harness/run-tests.sh
```

Expected: ALL scenarios pass, including `scaffolder-e2e-batch.sh`.

### Post-commit verification
After version bump (Task 7):
- Verify `plugin.json` shows version `6.3.1`
- Verify `marketplace.json` shows version `6.3.1`
- Verify git tag `v6.3.1` exists

### Manual spot checks
1. `skills/analyze-bug/SKILL.md` contains "step 3a" with UNCLEAR handler and Block Comment Template
2. `skills/fix-bugs/SKILL.md` UNCLEAR path says "Block: post block comment"
3. `agents/scaffolder.md` Batch 7 mentions `pytest-playwright`, `capybara-playwright-driver`, `test_smoke.py`, `smoke_spec.rb`
4. `tests/scenarios/scaffolder-e2e-batch.sh` uses `grep -A5 "Batch 7"` pattern and `up to 27`

---

## 5. Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Edit old_string doesn't match exactly | LOW | MEDIUM | All old_strings copied from current file reads |
| Test grep patterns too strict (fail on whitespace) | LOW | LOW | Using `-A5` gives enough context window |
| Cross-stack Playwright section too long for scaffolder | LOW | LOW | Follows existing Batch 6 pattern with per-stack subsections |
| Roadmap edit cuts PLANNED — Next header | MEDIUM | LOW | Explicit re-insertion of "## PLANNED — Next" before v6.4.0 |
| Version-bump skill unavailable | LOW | HIGH | Fallback: manual edit of plugin.json + marketplace.json |

**Overall risk: LOW** — All changes are additive markdown edits in well-understood files. No contract changes, no new files, no behavioral changes in consuming projects.
