# Agent 1: Minimalist Perspective

## Core Question

Is the "combination approach" (stack-selector + spec-writer + scaffolder, 3 agents changed, MINOR bump) overkill? Can we get 80% of the value with ONE change?

**Answer: Yes. One change is enough.**

## The Single Change: Scaffolder Batch 6

Add a "Batch 6 — Design" to `agents/scaffolder.md`. That's it. One file changed, PATCH version.

### What It Does

When the scaffolder detects a web framework in its input (React, Vue, Svelte, Next.js, Nuxt, SvelteKit, Angular, Django+templates, Rails+views — the same list from RQ4), it generates:

1. Tailwind CSS config (`tailwind.config.js` + `postcss.config.js`)
2. Global stylesheet (`src/styles/globals.css` with `@tailwind` directives)
3. DaisyUI dependency + theme selection in `tailwind.config.js`

When the input is an API, CLI, or library — Batch 6 is skipped entirely.

### Why This Is Enough

| Research finding | How this covers it |
|------------------|--------------------|
| RQ1: Tailwind wins for LLM generation | Scaffolder installs Tailwind |
| RQ2: Follow Next.js pattern (Tailwind as default) | Scaffolder adds it automatically for web stacks |
| RQ3: Tier 2 = Tailwind + DaisyUI theme | Scaffolder picks a theme by domain |
| RQ4: Web detection | Scaffolder already reads the tech stack — it can pattern-match framework names. No `project_type` field needed. |
| RQ5: Fixer gets design context for free | If scaffold v2 mode, spec/README.md already lists the tech stack including "Tailwind + DaisyUI". Fixer reads spec/. Zero change. |

### What We Skip (and Why It's Fine)

- **Stack-selector `project_type` field:** Not needed. The scaffolder already knows the framework from stack-selector output or spec/README.md. Checking `framework in WEB_FRAMEWORKS_LIST` is a 2-line conditional, not a new output field. Adding a field to stack-selector changes the agent output contract — that's a MINOR bump for zero practical gain.

- **Spec-writer `spec/design.md`:** Not needed for 80% value. The scaffolder generates the CSS config files directly. There's no design decision to capture in a spec — "use Tailwind + DaisyUI corporate theme" is a scaffolding default, not a specification. If a user wants custom design tokens, they're already past what an LLM should decide (RQ3: Tier 3 is risky).

- **New config key for CSS framework override:** Not needed. If someone doesn't want Tailwind, they delete the generated files. Or they use Agent Overrides to tell the scaffolder "use Pico CSS instead." Existing mechanism, zero new config surface.

## Exact Diff

One file changed: `agents/scaffolder.md`

Lines added: ~15 (Batch 6 block + web framework detection note in Process, one line in Constraints).

### Batch 6 addition (after Batch 5 in Process step 2):

```markdown
   **Batch 6 — Design (web projects only):**
   - Detect web project: framework is one of React, Vue, Svelte, Angular, Next.js, Nuxt,
     SvelteKit, Remix, Django (with templates), Rails (with views), Laravel (with Blade).
     If not a web project, skip this batch entirely.
   - Install Tailwind CSS + PostCSS + Autoprefixer (add to dependencies)
   - Install DaisyUI (add to dependencies)
   - Generate `tailwind.config.js` with DaisyUI plugin and a theme selected by project domain:
     enterprise/dashboard → `corporate`, developer tool → `dracula`,
     consumer/social → `light`, content/blog → `nord`
   - Generate `postcss.config.js` (standard Tailwind PostCSS setup)
   - Generate global stylesheet (e.g., `src/styles/globals.css`) with Tailwind directives
   - Update entry point or layout to import the global stylesheet
```

### Constraint addition:

```markdown
- NEVER add CSS framework setup for non-web projects (APIs, CLIs, libraries) — skip Batch 6 entirely
```

### Scorecard update (add row):

```markdown
     | Design | PASS/SKIP | Tailwind + DaisyUI configured (web) / Skipped (non-web) |
```

## Version Impact

**PATCH (6.1.6)**. No new config keys, no new agents, no changed agent output contracts. Just an internal improvement to what the scaffolder generates.

## Risk Assessment

- **False positive web detection:** Low risk. Framework names are unambiguous. If someone scaffolds "FastAPI" it won't trigger. If someone scaffolds "Next.js" it will. Edge case: Express — defaults to API (skip Batch 6) unless spec explicitly mentions "server-rendered pages" or "frontend."
- **Unwanted CSS files:** Trivially deletable. No downstream agent depends on them existing.
- **DaisyUI theme mismatch:** Cosmetic only. User can change one string in `tailwind.config.js`.

## What the Combination Approach Buys Over This

The remaining 20%:

1. **Explicit `project_type` in stack-selector** — useful for future features (e.g., different CI templates for web vs API), but YAGNI today.
2. **`spec/design.md` in spec-writer** — useful if the fixer needs to know "use DaisyUI btn-primary class" during implementation. But the fixer already has the generated `tailwind.config.js` in the codebase. It can read the config.
3. **Formal design system documentation** — nice for humans, unnecessary for LLM pipeline.

These are real benefits. They're just not worth 3 files changed + MINOR bump + output contract change when the scaffolder-only approach covers the core problem: "scaffolded web projects look like unstyled HTML."

## Recommendation

Ship the scaffolder Batch 6 as a PATCH. If users request design-aware features in the fixer or spec-writer later, add those as separate PATCH/MINOR increments. Don't front-load complexity.
