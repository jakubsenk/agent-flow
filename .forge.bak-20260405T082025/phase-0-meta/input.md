# Phase 0 — User Input (Verbatim)

Triage UNCLEAR Handler + Scaffold Patch Fixes (v6.3.1). Three patch fixes:
1. analyze-bug missing UNCLEAR handler — analyze-bug skill asked clarifying questions in chat instead of posting a block comment to YouTrack. Fix: add UNCLEAR handler after triage step in `skills/analyze-bug/SKILL.md` and make UNCLEAR path explicit in `skills/fix-bugs/SKILL.md`.
2. Batch 7 cross-stack Playwright detection — Batch 7 only checks `package.json` for `@playwright/test`, misses non-JS web stacks. Fix: detect Playwright across package managers (pyproject.toml for pytest-playwright, Gemfile for capybara-playwright-driver). Generate test files in the project's language.
3. Scaffold test grep fragility — test uses `grep -q "Skip this batch entirely"` which matches both Batch 6 and Batch 7. Fix: use context-aware grep patterns with line-range or pipe filtering. Make file count assertion more specific.

Files affected:
- `skills/analyze-bug/SKILL.md`
- `skills/fix-bugs/SKILL.md`
- `agents/scaffolder.md`
- `tests/scenarios/scaffolder-e2e-batch.sh`

Plus version bump to 6.3.1 + changelog entry.
