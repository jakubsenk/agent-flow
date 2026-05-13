# Phase 2 — Research Answers

## Persona
{{PERSONA}}: Senior Plugin Architect with deep familiarity with the ceos-agents codebase, markdown pipeline definitions, bash test patterns, and cross-platform package manager conventions.

## Task Instructions
{{TASK_INSTRUCTIONS}}:

Answer each research question from Phase 1 by reading the actual codebase files. Provide concrete evidence (line numbers, exact text) for each answer.

### Files to read:
1. `agents/triage-analyst.md` — full file, find UNCLEAR output format
2. `skills/fix-ticket/SKILL.md` — search for UNCLEAR handling pattern
3. `skills/analyze-bug/SKILL.md` — current step 3 triage handling (already known: lines 23-24)
4. `skills/fix-bugs/SKILL.md` — step 2 UNCLEAR path (already known: line 108)
5. `agents/scaffolder.md` — Batch 7 section (lines 67-76), Batch 6 section (lines 57-64)
6. `tests/scenarios/scaffolder-e2e-batch.sh` — all grep patterns (already read: full file)
7. `CLAUDE.md` — Block Comment Template section

### Required answers:
- For each question in Phase 1, provide:
  - **Answer:** concrete finding
  - **Evidence:** file path, line number(s), exact text snippet
  - **Implication for implementation:** how this affects the fix

### Cross-stack Playwright validation:
- `pytest-playwright` — confirm this is the standard Python Playwright test runner
- `capybara-playwright-driver` — confirm this is the standard Ruby Playwright integration
- Check if Go/Rust/.NET have Playwright test packages (they generally don't have first-class support)

## Success Criteria
{{SUCCESS_CRITERIA}}:
- Every Phase 1 question has a concrete answer with file evidence
- No "I think" or "probably" — only verified facts from the codebase
- Cross-stack package names confirmed or corrected
- Implementation approach validated against existing patterns

## Anti-Patterns
{{ANTI_PATTERNS}}:
- Do NOT provide answers without reading the actual files
- Do NOT guess at line numbers — verify them
- Do NOT skip the cross-stack validation step
- Do NOT conflate Batch 6 and Batch 7 conditional patterns (they are similar but distinct)

## Codebase Context
{{CODEBASE_CONTEXT}}:
- Pure markdown plugin (ceos-agents), 19 agents, 26 skills
- Block Comment Template: `[ceos-agents] 🔴 Pipeline Block\nAgent: {agent name}\nStep: {pipeline step}\nReason: {max 2 sentences}\nDetail: {technical output}\nRecommendation: {what human should do}`
- Triage-analyst outputs: acceptance_criteria, complexity, severity, area, and verdict (OK/DUPLICATE/UNCLEAR)
- fix-bugs step 2 currently handles UNCLEAR as: "record as UNCLEAR, continue with next"
- Scaffolder Batch 6 skip condition: "Skip this batch entirely if the tech stack does NOT include a web UI framework"
- Scaffolder Batch 7 skip condition: "Skip this batch entirely if: The project is NOT a web project, OR Playwright is NOT in the project's dependencies (check package.json)"
