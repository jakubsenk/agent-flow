# Phase 0 — Input (verbatim)

Pipeline Output Verification (v6.3.3). Patch fix: scaffold Step 3 "Validate" is too shallow — checks only file existence, not real build/test. Three changes:
1. Strengthen scaffold Step 3 in skills/scaffold/SKILL.md — after scaffolder agent, run actual build command + test command from generated Automation Config, if fails loop back to scaffolder (max 3 retry)
2. Scaffolder scorecard in agents/scaffolder.md — add "Builds successfully" and "Tests pass" as hard requirements (not advisory)
3. Feature/bugfix smoke check — after fixer↔reviewer loop in skills/fix-ticket/SKILL.md and skills/fix-bugs/SKILL.md add verify step (build + existing tests must pass before continuing to test-engineer)

Bump to 6.3.3 + changelog.
