# Phase 3 — Brainstorm

You are facilitating a structured brainstorm with 3 heterogeneous personas to explore approaches for adding design awareness to the ceos-agents scaffold pipeline.

## Context

Read the research report at `.forge/phase-1-research/report.md` for full findings.

**Problem:** The scaffold pipeline (spec-writer -> scaffolder -> fixer) produces functional but visually mediocre web projects. Zero CSS framework, zero design system, zero accessibility. Need to add design awareness for frontend/fullstack projects without affecting backend/CLI projects.

**Key constraint:** LLMs cannot make aesthetic choices. The solution must focus on tooling setup (CSS framework installation, configuration, component library), not visual design decisions.

**Current architecture:** 19 agents (markdown definitions), 26 skills, pure markdown plugin. Scaffolder has 5 batches (Core, Config, Quality, Ops, Docs). Spec-writer generates spec/ folder. Stack-selector picks tech stack.

## Personas

### Persona A: The Minimalist Architect
**Background:** 15 years of framework design. Believes the best code is no code. Has maintained projects where adding a single abstraction layer caused years of maintenance burden.
**Stance:** Extend existing agents minimally. No new agents unless absolutely necessary. Conditional logic over new pipeline steps. The scaffolder already has 5 batches — a 6th is the maximum acceptable change.
**Bias to challenge:** May under-deliver by avoiding necessary complexity. May not see that a dedicated agent pays for itself in quality.

### Persona B: The UX Systems Engineer
**Background:** Built design systems for 3 companies. Runs a CSS framework's open-source project. Believes that a design system is infrastructure, not decoration.
**Stance:** A dedicated ui-designer agent is justified because design decisions pervade the entire stack (HTML structure, CSS architecture, component patterns, accessibility). Bolt-on approaches will produce bolt-on results. The spec-writer needs to capture design requirements to flow through the pipeline.
**Bias to challenge:** May over-engineer the solution. A 20th agent is maintenance cost. "Design system" may be overkill for a scaffold — this isn't a production design team.

### Persona C: The Pragmatic DX Engineer
**Background:** Built multiple CLI tools and developer scaffolds (create-next-app, Yeoman generators). Focused on developer experience and time-to-first-pixel.
**Stance:** Users don't care about design systems — they care about not being embarrassed by their scaffold output. The fix should be: pick a CSS framework, install it, configure it, make the skeleton look decent. No design tokens, no component libraries, no accessibility audits at scaffold time. Ship the simplest thing that makes the output not ugly.
**Bias to challenge:** May sacrifice quality for speed. "Not ugly" is a low bar that may not justify the engineering effort. Accessibility is not optional — it's a legal requirement in many jurisdictions.

## Process

For each persona:
1. Present their proposed approach (specific files to change, specific content to add)
2. Identify the strongest argument FOR their approach
3. Identify the strongest argument AGAINST their approach
4. Rate: effort (1-5), quality impact (1-5), maintenance cost (1-5)

Then:
5. **Cross-examination:** Each persona critiques the other two approaches
6. **Synthesis:** A judge persona identifies the best elements from each approach and proposes a unified recommendation
7. **Devil's advocate:** Challenge the synthesis — what's the strongest argument against the recommended approach?

## Output Format

Save the complete brainstorm (all 7 sections) to `.forge/phase-3-brainstorm/brainstorm.md`.

The synthesis MUST include:
- Specific files to create/modify
- Specific sections/batches to add
- Detection strategy for web vs non-web projects
- What the scaffolder generates differently for web projects
- What spec-writer generates differently for web projects
- Whether a new agent is needed (and if not, why the alternatives are sufficient)
