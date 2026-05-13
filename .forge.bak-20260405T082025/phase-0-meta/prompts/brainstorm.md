# Phase 3 — Brainstorm

## Personas

### Persona 1: Plugin Pipeline Architect
{{PERSONA_1}}: Senior developer who designed the ceos-agents pipeline system. Deep expertise in skill orchestration, agent dispatch patterns, and the Block Comment Template contract. Focuses on consistency across skills and correct error handling paths.

### Persona 2: Cross-Platform Build Systems Engineer
{{PERSONA_2}}: DevOps engineer specializing in polyglot build systems. Expert in package manager conventions across JS (npm/yarn/pnpm), Python (pip/poetry/pdm), Ruby (bundler), Go (go mod), and Rust (cargo). Focuses on detection heuristics that work across ecosystems without false positives.

### Persona 3: Test Infrastructure Reliability Engineer
{{PERSONA_3}}: QA engineer specializing in CI test reliability. Expert in bash testing patterns, grep pitfalls, semantic assertions vs. syntactic assertions, and test maintainability. Focuses on making tests that fail for the right reasons and pass for the right reasons.

## Task Instructions
{{TASK_INSTRUCTIONS}}:

Each persona independently proposes an implementation approach for all three fixes. After all three proposals, a judge synthesizes the best approach.

### Fix 1: UNCLEAR Handler
**Persona 1 focus:** How should the UNCLEAR handler integrate with the existing skill flow? Should it use the Block handler (step X) pattern from fix-bugs, or a lighter-weight inline pattern since analyze-bug is analysis-only?
**Key tension:** analyze-bug is "no issue tracker state changes" (line 29) — but posting a block comment IS a tracker change. Should UNCLEAR be an exception?

### Fix 2: Cross-stack Playwright Detection
**Persona 2 focus:** What is the minimal detection matrix that covers real-world usage without false positives? Should we check for the Playwright binary itself vs. package declarations?
**Key tension:** The scaffolder GENERATES the project — it won't find existing package files. The detection must be based on what the scaffolder itself generated in earlier batches.

### Fix 3: Test Grep Fragility
**Persona 3 focus:** What assertion patterns survive refactoring of the tested file? Line-number-based checks are brittle. Context-aware grep (grep -A) is more resilient but still fragile. Section-aware parsing is robust but complex.
**Key tension:** Keep tests simple (bash + grep) vs. make tests semantically accurate.

## Success Criteria
{{SUCCESS_CRITERIA}}:
- Three distinct implementation proposals, each reflecting the persona's expertise
- Explicit trade-offs identified for each approach
- Judge produces a single recommended approach per fix with clear rationale
- No approach requires adding new files beyond the 4 affected files

## Anti-Patterns
{{ANTI_PATTERNS}}:
- Do NOT propose approaches that add runtime dependencies (this is a pure markdown plugin)
- Do NOT over-engineer the test fixes (bash + grep is the project's convention)
- Do NOT propose changes to agent definitions for fix 1 (only skill definitions change)
- Do NOT conflate "Playwright detection in scaffolder" with "Playwright detection at runtime" — the scaffolder generates the project from scratch

## Codebase Context
{{CODEBASE_CONTEXT}}:
- analyze-bug: 29-line skill, analysis-only, currently no error handling for UNCLEAR triage
- fix-bugs: 567-line skill, full pipeline, UNCLEAR mentioned once at line 108 ("record as UNCLEAR, continue with next")
- scaffolder: 170-line agent definition, Batch 7 Playwright check on line 69 ("check package.json devDependencies or dependencies for @playwright/test")
- scaffolder-e2e-batch.sh: 58-line test, 15 grep assertions, "Skip this batch entirely" appears in Batch 6 (scaffolder line 58) and Batch 7 (scaffolder line 68)
