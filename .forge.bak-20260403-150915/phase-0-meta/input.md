# Phase 0 — Input (Verbatim)

The ceos-agents scaffold pipeline produces functional but visually mediocre web projects. There are zero design/UI instructions anywhere in the pipeline (spec-writer → scaffolder → fixer). Need to research and decide the best approach to add design awareness for frontend/fullstack projects.

**Key constraint:** LLMs don't have visual taste — the fix must focus on tooling setup (CSS framework installation, configuration), not aesthetic choices like colors or typography.

**Options to explore:**
1. New dedicated "ui-designer" agent (20th agent)
2. Extend scaffolder with a design batch
3. Spec-writer enhancement (conditional "Design & UX" section)
4. Agent Override pattern (default design-advisor override)
5. Combination of approaches

**Context from roadmap** (`docs/plans/roadmap.md` EXPLORING section):
> Scaffold pipeline produces functional but visually mediocre web projects. No CSS framework, no design system, no design tokens, no accessibility standards. The entire pipeline (spec-writer → scaffolder → fixer) has zero design awareness for frontend/fullstack projects.
