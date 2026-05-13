# Phase 1 — Research Questions

## Persona
{{PERSONA}}: Senior Plugin Architect specializing in markdown-based developer tooling pipelines with expertise in shell testing patterns and cross-platform build system detection.

## Task Instructions
{{TASK_INSTRUCTIONS}}:

You are researching three patch fixes for the ceos-agents plugin (v6.3.0 → v6.3.1). Generate research questions to validate assumptions before implementation.

### Fix 1: UNCLEAR Handler in analyze-bug and fix-bugs

**Questions to answer:**
1. What does the triage-analyst agent output when it determines a bug is UNCLEAR? What exact output format/signal does it produce?
2. How does `skills/fix-bugs/SKILL.md` step 2 currently handle the UNCLEAR case? (Currently: "record as UNCLEAR, continue with next")
3. What is the Block Comment Template format used across the plugin? (verify exact format from CLAUDE.md)
4. Does `skills/analyze-bug/SKILL.md` have any existing error/block handling pattern that the UNCLEAR handler should follow?
5. Does `skills/fix-ticket/SKILL.md` have an UNCLEAR handler that could serve as a reference?

### Fix 2: Cross-stack Playwright Detection in Scaffolder Batch 7

**Questions to answer:**
1. What is the current Batch 7 conditional logic in `agents/scaffolder.md`? (line ~67-76)
2. What are the correct package names for Playwright in non-JS ecosystems?
   - Python: `pytest-playwright` in pyproject.toml or requirements.txt
   - Ruby: `capybara-playwright-driver` in Gemfile
   - Any others? (Go, Rust, .NET — do Playwright bindings exist?)
3. What are the conventional E2E test file naming patterns per language?
   - JS/TS: `e2e/smoke.spec.ts`
   - Python: `e2e/test_smoke.py` (pytest convention)
   - Ruby: `e2e/smoke_spec.rb` (RSpec convention)
4. What test runner commands are used per stack? (npx playwright test vs pytest vs rspec)
5. How does the scaffolder currently reference `package.json` scripts — would a Python/Ruby project need equivalent runner config?

### Fix 3: Test Grep Fragility

**Questions to answer:**
1. On which lines does "Skip this batch entirely" appear in `agents/scaffolder.md`? (Expected: Batch 6 and Batch 7)
2. What other grep patterns in `scaffolder-e2e-batch.sh` might have similar ambiguity?
3. Does the test harness support `grep -A` (context after match) piping? (It's standard bash — should work)
4. What is the exact line for the file count ceiling "27" — could it match elsewhere?

## Success Criteria
{{SUCCESS_CRITERIA}}:
- All 15 questions answered with concrete evidence from the codebase
- Exact line numbers identified for all affected code sections
- Cross-stack Playwright package names validated
- No assumptions left unverified

## Anti-Patterns
{{ANTI_PATTERNS}}:
- Do NOT assume the triage-analyst output format without reading the agent definition
- Do NOT assume Python/Ruby Playwright bindings exist without verification
- Do NOT skip checking fix-ticket for reference UNCLEAR handling patterns

## Codebase Context
{{CODEBASE_CONTEXT}}:
- Pure markdown plugin, no runtime code
- 4 files affected: `skills/analyze-bug/SKILL.md`, `skills/fix-bugs/SKILL.md`, `agents/scaffolder.md`, `tests/scenarios/scaffolder-e2e-batch.sh`
- Block Comment Template defined in root CLAUDE.md
- Test harness uses bash with `set -euo pipefail`, grep-based assertions
- Current version: 6.3.0, target: 6.3.1 (PATCH)
