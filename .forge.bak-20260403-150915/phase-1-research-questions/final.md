# Phase 1: Research Synthesis

## RQ1: CSS Frameworks for LLM Code Generation

**Winner: Tailwind CSS** — highest LLM reliability (predictable utility classes, massive training data), automatable setup (4 deterministic steps), good visual quality floor.

**Runner-up: Classless CSS (Pico/Simple.css)** — zero class mistakes possible (LLM just writes semantic HTML), one import setup. But limited ceiling — not suitable for complex UIs.

**Recommended dual strategy:** Tailwind for interactive web apps (React/Vue/Svelte/Next.js), classless CSS (Pico) as fallback for simple server-rendered pages.

**Rejected:** Bootstrap (dated), CSS Modules (inconsistent), Shadcn/ui (requires interactive CLI, not automatable).

## RQ2: How Scaffold Tools Handle Design Defaults

- No scaffold tool ships CSS as a non-optional default
- Modern tools (Next.js, SvelteKit, Rails) **offer Tailwind as a choice**
- Bare/no-CSS is associated with deprecated or minimal tools

**Implication:** Follow the Next.js pattern — Tailwind as automated default for web projects. Don't force it for CLI/API projects.

## RQ3: Minimum Viable Design System

**Tier 2 (framework + preset theme) is the sweet spot:**
- Tier 1 (framework only): 60% improvement (unstyled → looks real)
- Tier 2 (framework + preset theme): 90% improvement (generic → intentional)  
- Tier 3 (custom design tokens): risky, LLM can't make aesthetic choices

**Recommended:** Tailwind + DaisyUI theme. LLM picks theme by project domain (categorization, not aesthetics): "enterprise dashboard" → `corporate`, "developer tool" → `dracula`, "consumer app" → `light`.

DaisyUI themes are WCAG-compliant by design → accessibility comes free at Tier 2.

## RQ4: Web Project Detection

**Primary signal: Stack-selector** — add `project_type: web | api | cli | library` to output. Framework type is the strongest indicator:
- WEB: React, Vue, Svelte, Angular, Next.js, Nuxt, SvelteKit, Django+templates, Rails+views
- API: FastAPI, Express (API), Go gin, Flask API, Django REST
- CLI: Click, Typer, Commander, Cobra

**Ambiguous stacks default to `api`** (conservative — easier to add CSS later than remove it).

**Override:** `--web` / `--api` / `--cli` flags on scaffold command.

**Scaffold v2 mode:** Derive from spec/README.md Tech Stack section (no stack-selector).

## RQ5: Reuse Opportunities

1. **Scaffolder Batch 6 "Design"** — fits naturally after Batch 5. Would generate: CSS framework config, design tokens file, global styles.
2. **Stack-selector extension** — add `UI framework` and `Component library` to output. Minimal change but touches agent output format.
3. **Spec-writer conditional section** — `spec/design.md` (IF APPLICABLE). Spec-reviewer `--verify` checks CSS config against spec.
4. **Fixer context** — `spec/design.md` is automatically available to fixer via "spec/ folder available for reference" (zero code change).
5. **Agent Override** — shipped example works with zero code change. Plugin-bundled fallback needs injector modification.

## RQ6: Version Impacts

| Approach | Version | Safe? |
|----------|---------|-------|
| Scaffolder Batch 6 (no new config key) | PATCH | Yes |
| Stack-selector `project_type` field | MINOR | Yes (optional) |
| Spec-writer conditional `spec/design.md` | PATCH | Yes |
| New optional config key | MINOR | Yes |
| New required config key | MAJOR | No |
| New agent (ui-designer) | MINOR | Yes but overkill |

## Emerging Recommendation

**Combination approach (Option 5):**
1. Stack-selector adds `project_type` + `CSS framework` fields → **MINOR**
2. Spec-writer adds conditional `spec/design.md` for web projects → included in same MINOR
3. Scaffolder adds Batch 6 "Design" for web projects → included
4. Fixer gets `spec/design.md` for free (no change needed)

**No new agent.** The work is distributed across 3 existing agents + 1 skill change.
**MINOR version bump** (new optional capability in stack-selector).
