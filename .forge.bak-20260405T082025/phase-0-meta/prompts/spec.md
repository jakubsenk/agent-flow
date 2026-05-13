# Phase 4 — Specification

## Persona
{{PERSONA}}: Senior Technical Writer and Plugin Contract Specialist. Expert in writing precise, unambiguous specifications for markdown-based pipeline definitions. Ensures every change is traceable to a requirement and every requirement has acceptance criteria.

## Task Instructions
{{TASK_INSTRUCTIONS}}:

Write a formal specification for ceos-agents v6.3.1 — three patch fixes. The spec must be precise enough that an implementer can execute without asking questions.

### Spec 1: UNCLEAR Handler in analyze-bug and fix-bugs

**Requirement:** When triage-analyst returns UNCLEAR verdict, the pipeline must post a block comment to the issue tracker (not ask clarifying questions in chat).

**Changes to `skills/analyze-bug/SKILL.md`:**
- After step 3 (triage), add step 3a: UNCLEAR handler
- If triage returns UNCLEAR:
  1. Instruct the triage-analyst (via Task context) to post a Block Comment to the issue tracker using the Block Comment Template format:
     ```
     [ceos-agents] 🔴 Pipeline Block
     Agent: triage-analyst
     Step: Triage
     Reason: Bug report is unclear — missing {specific missing information from triage quality gate}
     Detail: {quality gate failures}
     Recommendation: Clarify the bug report and re-run analysis
     ```
  2. Display result to user: "Bug {ISSUE-ID} is UNCLEAR. Block comment posted to tracker."
  3. Stop — do NOT proceed to code-analyst (step 4)
- NOTE: This is an exception to the "no issue tracker state changes" rule — UNCLEAR is the one case where analyze-bug writes to the tracker, because the alternative (asking in chat) loses the information.

**Changes to `skills/fix-bugs/SKILL.md`:**
- Step 2 (Triage), UNCLEAR path (line 108): Make explicit that UNCLEAR posts a block comment
- Change from: "Unclear → record as UNCLEAR, continue with next (in dry-run do not write to the issue tracker)"
- Change to: "Unclear → post Block Comment to tracker (Agent: triage-analyst, Step: Triage, Reason: unclear bug report), record as UNCLEAR, continue with next bug. In dry-run mode: record as UNCLEAR only, do NOT write to tracker."

### Spec 2: Cross-stack Playwright Detection in Scaffolder Batch 7

**Requirement:** Batch 7 must detect Playwright across all supported package managers and generate test files in the project's language.

**Changes to `agents/scaffolder.md` Batch 7 section:**
- Replace the current single-ecosystem check with a multi-ecosystem detection table:

  | Ecosystem | Package File | Dependency Name | Test File Pattern | Test Runner Command |
  |-----------|-------------|----------------|-------------------|-------------------|
  | JS/TS | `package.json` | `@playwright/test` | `e2e/smoke.spec.ts` | `npx playwright test` |
  | Python | `pyproject.toml` or `requirements.txt` | `pytest-playwright` | `e2e/test_smoke.py` | `pytest e2e/` |
  | Ruby | `Gemfile` | `capybara-playwright-driver` | `e2e/smoke_spec.rb` | `bundle exec rspec e2e/` |

- Update the conditional skip logic:
  - Old: "Playwright is NOT in the project's dependencies (check package.json `devDependencies` or `dependencies` for `@playwright/test`)"
  - New: "Playwright is NOT in the project's dependencies — check the relevant package file for the project's language (see detection table above)"

- Update generated artifacts section to be language-aware:
  - Configuration file: `playwright.config.ts` (JS/TS) or `conftest.py` with playwright fixtures (Python) or `spec_helper.rb` with Capybara-Playwright setup (Ruby)
  - Smoke test: language-appropriate file as per detection table
  - Test script: Add to the project's package manager (`package.json` scripts for JS, `pyproject.toml` scripts for Python, `Rakefile` task for Ruby)
  - Gitignore additions: `playwright-report/` and `test-results/` (all ecosystems)

### Spec 3: Test Grep Fragility Fix

**Requirement:** Test assertions must be semantically tied to the section they verify, not match across unrelated sections.

**Changes to `tests/scenarios/scaffolder-e2e-batch.sh`:**

1. **Batch 7 conditional pattern check (line 15-16):**
   - Old: `grep -q "Skip this batch entirely" "$SCAFFOLDER"`
   - New: Use section-aware grep — pipe through `sed -n '/Batch 7/,/Batch 8/p'` to extract only the Batch 7 section, then grep within that range
   - Pattern: `sed -n '/Batch 7/,/Batch 8/p' "$SCAFFOLDER" | grep -q "Skip this batch entirely"`

2. **Playwright detection check (line 18-19):**
   - Old: `grep -q "@playwright/test" "$SCAFFOLDER"`
   - New: Keep as-is BUT also add checks for cross-stack detection:
   - Add: `grep -q "pytest-playwright" "$SCAFFOLDER"` and `grep -q "capybara-playwright-driver" "$SCAFFOLDER"`

3. **File count ceiling check (line 45):**
   - Old: `grep -q "27" "$SCAFFOLDER"`
   - New: `grep -q "up to 27" "$SCAFFOLDER"`

## Success Criteria
{{SUCCESS_CRITERIA}}:
- Each spec change is traceable to the roadmap item
- All acceptance criteria are testable (either by existing tests or the modified test)
- No changes to files outside the 4 specified files
- No breaking changes to the Automation Config contract (this is PATCH)
- Block Comment Template format is exactly as defined in CLAUDE.md

## Anti-Patterns
{{ANTI_PATTERNS}}:
- Do NOT change the triage-analyst agent definition — only the skills that dispatch it
- Do NOT add new required config sections (would be MAJOR version change)
- Do NOT change the Block Comment Template format
- Do NOT make Batch 7 detection overly complex — stick to the three mainstream ecosystems (JS, Python, Ruby)
- Do NOT use line-number-based assertions in tests (fragile to any future edits)

## Codebase Context
{{CODEBASE_CONTEXT}}:
- Version: 6.3.0 → 6.3.1 (PATCH — behavior fix without contract change)
- Block Comment Template: `[ceos-agents] 🔴 Pipeline Block\nAgent: {agent name}\nStep: {pipeline step}\nReason: {max 2 sentences}\nDetail: {technical output}\nRecommendation: {what human should do}`
- analyze-bug is a 29-line skill with 5 steps
- fix-bugs step 2 processes triage results: OK/DUPLICATE/UNCLEAR
- Scaffolder Batch 7 is conditional on web project + Playwright
- Test file has 58 lines with 15 grep-based assertions
