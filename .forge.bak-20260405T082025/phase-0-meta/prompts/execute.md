# Phase 7 — Execute

## Persona
{{PERSONA}}: Senior Plugin Developer specializing in markdown pipeline definitions. Meticulous editor who makes exact, minimal changes. Never changes more than specified. Verifies every edit against the spec before moving to the next file.

## Task Instructions
{{TASK_INSTRUCTIONS}}:

Execute all edits for ceos-agents v6.3.1. Follow the plan exactly. Make changes in the specified order.

### Edit 1: `skills/analyze-bug/SKILL.md` — Add UNCLEAR handler

**After** the existing step 3 (lines 23-24):
```
3. Run `ceos-agents:triage-analyst` on bug $ARGUMENTS
   After successful triage, instruct the agent to post a checkpoint comment to the issue tracker: `[ceos-agents] Triage completed. Severity: {severity}. Area: {area}.`
```

**Insert** step 3a before step 4:
```
3a. If triage returns UNCLEAR:
   - Instruct the triage-analyst to post a Block Comment to the issue tracker:
     ```
     [ceos-agents] 🔴 Pipeline Block
     Agent: triage-analyst
     Step: Triage
     Reason: Bug report is unclear — {specific missing information from triage quality gate}
     Detail: {quality gate failure details}
     Recommendation: Clarify the bug report and re-run /ceos-agents:analyze-bug
     ```
   - Display to user: "Bug $ARGUMENTS is UNCLEAR. Block comment posted to tracker."
   - Stop. Do NOT proceed to step 4.
```

### Edit 2: `skills/fix-bugs/SKILL.md` — Make UNCLEAR path explicit

**Find** in step 2 (Triage section, around line 108):
```
- Unclear → record as UNCLEAR, continue with next (in dry-run do not write to the issue tracker)
```

**Replace with:**
```
- Unclear → post Block Comment to issue tracker (Agent: triage-analyst, Step: Triage, Reason: unclear bug report — {quality gate failures}), record as UNCLEAR, continue with next bug. In dry-run mode: record as UNCLEAR only, do NOT write to tracker.
```

### Edit 3: `agents/scaffolder.md` — Cross-stack Playwright detection

**Find** in Batch 7 (around line 67-69):
```
   Skip this batch entirely if:
   - The project is NOT a web project (same detection logic as Batch 6), OR
   - Playwright is NOT in the project's dependencies (check package.json `devDependencies` or `dependencies` for `@playwright/test`)
```

**Replace with:**
```
   Skip this batch entirely if:
   - The project is NOT a web project (same detection logic as Batch 6), OR
   - Playwright is NOT in the project's dependencies — check the relevant package file for the project's ecosystem:

   | Ecosystem | Package File | Dependency Name |
   |-----------|-------------|----------------|
   | JS/TS | `package.json` (devDependencies or dependencies) | `@playwright/test` |
   | Python | `pyproject.toml` (project.dependencies or project.optional-dependencies) or `requirements.txt` | `pytest-playwright` |
   | Ruby | `Gemfile` | `capybara-playwright-driver` |
```

**Find** in Batch 7 (around lines 71-76):
```
   If web project with Playwright detected:
   - Playwright configuration file (`playwright.config.ts` or `.js`): set `baseURL` from environment variable or `http://localhost:3000`, configure `testDir` pointing to e2e test directory, add `webServer` section with start command from Build & Test config, 30s default timeout
   - At least 1 e2e smoke test (`e2e/smoke.spec.ts` or equivalent): verify the application loads (navigate to `/`, assert page title or visible heading, check no console errors), verify basic navigation works (if router configured)
   - Add `"test:e2e": "npx playwright test"` script to `package.json`
   - Add `playwright-report/` and `test-results/` to `.gitignore`
```

**Replace with:**
```
   If web project with Playwright detected, generate artifacts for the project's ecosystem:

   **JS/TS projects:**
   - Playwright configuration file (`playwright.config.ts`): set `baseURL` from environment variable or `http://localhost:3000`, configure `testDir` pointing to e2e test directory, add `webServer` section with start command from Build & Test config, 30s default timeout
   - E2E smoke test (`e2e/smoke.spec.ts`): verify the application loads (navigate to `/`, assert page title or visible heading, check no console errors), verify basic navigation works (if router configured)
   - Add `"test:e2e": "npx playwright test"` script to `package.json`

   **Python projects:**
   - Playwright test configuration in `conftest.py` (or `e2e/conftest.py`): pytest-playwright fixtures, `base_url` from environment variable or `http://localhost:8000`
   - E2E smoke test (`e2e/test_smoke.py`): verify the application loads (navigate to `/`, assert page title or visible heading), verify basic navigation works (if router configured)
   - Add `test:e2e` script or equivalent command in `pyproject.toml` scripts section: `pytest e2e/`

   **Ruby projects:**
   - Capybara-Playwright configuration in `spec/spec_helper.rb` (or `e2e/spec_helper.rb`): Capybara driver setup, `app_host` from environment variable or `http://localhost:3000`
   - E2E smoke test (`e2e/smoke_spec.rb`): verify the application loads (visit `/`, assert page title or visible heading), verify basic navigation works (if router configured)
   - Add `test:e2e` Rake task in `Rakefile`: `bundle exec rspec e2e/`

   **All ecosystems:**
   - Add `playwright-report/` and `test-results/` to `.gitignore`
```

### Edit 4: `tests/scenarios/scaffolder-e2e-batch.sh` — Fix fragile greps + add cross-stack assertions

**Find (line 15-16):**
```bash
# Batch 7 conditional pattern
grep -q "Skip this batch entirely" "$SCAFFOLDER" || fail "scaffolder.md Batch 7 missing conditional skip pattern"
```

**Replace with:**
```bash
# Batch 7 conditional pattern (section-aware — must match within Batch 7, not Batch 6)
sed -n '/Batch 7/,/Batch 8/p' "$SCAFFOLDER" | grep -q "Skip this batch entirely" || fail "scaffolder.md Batch 7 missing conditional skip pattern"
```

**Find (line 45):**
```bash
grep -q "27" "$SCAFFOLDER" || fail "scaffolder.md constraints missing updated file count ceiling (27)"
```

**Replace with:**
```bash
grep -q "up to 27" "$SCAFFOLDER" || fail "scaffolder.md constraints missing updated file count ceiling (27)"
```

**After the existing `@playwright/test` check (line 18-19), add new cross-stack assertions:**
```bash
# Batch 7 cross-stack Playwright detection
grep -q "pytest-playwright" "$SCAFFOLDER" || fail "scaffolder.md Batch 7 missing Python Playwright detection (pytest-playwright)"
grep -q "capybara-playwright-driver" "$SCAFFOLDER" || fail "scaffolder.md Batch 7 missing Ruby Playwright detection (capybara-playwright-driver)"

# Batch 7 language-aware test files
sed -n '/Batch 7/,/Batch 8/p' "$SCAFFOLDER" | grep -q "test_smoke.py" || fail "scaffolder.md Batch 7 missing Python test file pattern (test_smoke.py)"
sed -n '/Batch 7/,/Batch 8/p' "$SCAFFOLDER" | grep -q "smoke_spec.rb" || fail "scaffolder.md Batch 7 missing Ruby test file pattern (smoke_spec.rb)"

# Batch 7 multi-ecosystem package file detection
sed -n '/Batch 7/,/Batch 8/p' "$SCAFFOLDER" | grep -q "pyproject.toml" || fail "scaffolder.md Batch 7 missing pyproject.toml detection"
sed -n '/Batch 7/,/Batch 8/p' "$SCAFFOLDER" | grep -q "Gemfile" || fail "scaffolder.md Batch 7 missing Gemfile detection"
```

### Edit 5: `CHANGELOG.md` — Add v6.3.1 entry

Insert after the `## [6.3.0]` header line (before the 6.3.0 content):

```markdown
## [6.3.1] — 2026-04-05

**PATCH** — UNCLEAR handler, cross-stack Playwright detection, test assertion fixes.

### Fixed
- **analyze-bug UNCLEAR handler:** Added step 3a — on UNCLEAR triage verdict, posts Block Comment to issue tracker instead of asking clarifying questions in chat. Stops pipeline after posting.
- **fix-bugs UNCLEAR path:** Made UNCLEAR handling explicit — posts Block Comment to tracker (dry-run: record only, no tracker write).
- **Scaffolder Batch 7 cross-stack Playwright detection:** Detect Playwright across ecosystems — `@playwright/test` (JS/TS), `pytest-playwright` (Python), `capybara-playwright-driver` (Ruby). Generate test files in the project's language (`smoke.spec.ts`, `test_smoke.py`, `smoke_spec.rb`).
- **Scaffold test grep fragility:** Replaced ambiguous `grep "Skip this batch entirely"` with section-aware `sed -n '/Batch 7/,/Batch 8/p' | grep` pattern. Made file count ceiling check specific (`"up to 27"` instead of `"27"`). Added 6 new cross-stack detection assertions.

```

### Post-edit verification:
1. Run `./tests/harness/run-tests.sh`
2. Verify all tests pass
3. Check that `sed -n '/Batch 7/,/Batch 8/p'` correctly isolates Batch 7 content

## Success Criteria
{{SUCCESS_CRITERIA}}:
- All 5 edits applied cleanly
- No unintended changes to surrounding text
- Test suite passes: `./tests/harness/run-tests.sh` returns 0
- Changelog entry present and correctly formatted
- analyze-bug now has 6 steps (1, 2, 3, 3a, 4, 5)
- fix-bugs step 2 UNCLEAR bullet explicitly mentions Block Comment

## Anti-Patterns
{{ANTI_PATTERNS}}:
- Do NOT change step numbers in fix-bugs (only change the UNCLEAR bullet text)
- Do NOT modify any agent definition other than scaffolder.md
- Do NOT add new files
- Do NOT change the Block Comment Template format
- Do NOT edit the triage-analyst agent
- Do NOT commit before running tests
- Do NOT use `git add -A` — add only the specific changed files

## Codebase Context
{{CODEBASE_CONTEXT}}:
- 4 content files + CHANGELOG.md to edit
- Version bump is a separate step (not in this phase)
- Test harness: `./tests/harness/run-tests.sh`
- Commit order: content + changelog first, then version-bump
