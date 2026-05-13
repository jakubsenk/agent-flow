# Agent 2 — Research Findings: RQ3 + RQ4

## RQ3: Minimum Viable Design System an LLM Can Reliably Configure

### Findings

#### The Three-Tier Analysis

**Tier 1: Framework installation only (zero aesthetic decisions)**

Installing a CSS framework with its default theme is the lowest-risk, highest-reliability operation an LLM can perform. The LLM writes deterministic shell commands (`npm install tailwindcss`, `npx tailwindcss init`) and boilerplate config. No color choices, no font choices, no spacing decisions. The result is Tailwind's default palette (slate, gray, zinc, red, orange, etc. at fixed 50-900 shades), default type scale (text-sm, text-base, text-lg, etc.), and default spacing scale (p-1=4px, p-4=16px, etc.). This is visually coherent because it obeys a mathematical scale — it just looks "generic Tailwind."

For Bootstrap, Tier 1 means CDN link or `npm install bootstrap` + one import line. Default Bootstrap ships with a complete visual language: 8 semantic colors (primary, secondary, success, danger, warning, info, light, dark), 6 heading sizes, grid system, and 30+ pre-styled components. The LLM doesn't pick any of these — they exist by default.

For Pico CSS, Tier 1 is a single CSS import. Pico styles semantic HTML directly — `<button>`, `<article>`, `<nav>`, `<input>` all get reasonable default styles with no class application at all. An LLM writing clean semantic HTML automatically gets styled output.

**Visual quality floor at Tier 1:**
- Tailwind alone: low. Without classes applied, unstyled HTML. Tailwind requires class application to produce visual output — the framework is not decorative.
- Bootstrap: medium-high. Import Bootstrap and write `<button class="btn btn-primary">` — already looks professional. The component vocabulary is narrow but well-executed.
- Pico CSS: medium. Zero class application needed. Clean semantic HTML looks polished. Limited customization without moving to Tier 2.

**Tier 2: Framework + preset theme**

DaisyUI adds a named theme layer on top of Tailwind: `data-theme="cupcake"`, `data-theme="business"`, `data-theme="corporate"`, etc. The LLM selects a theme name (a string from a fixed list), and the framework generates a complete color system, button variants, form styles, and component library. Crucially, the LLM does not generate colors — it references a semantic color token (`bg-primary`, `text-base-content`) and the theme resolves the actual hex value.

This is a significant upgrade over Tier 1 because:
1. Named themes carry domain intent. "business" reads as professional/corporate. "synthwave" reads as developer tool. "pastel" reads as consumer/friendly.
2. The LLM can match theme names to project domain using label-matching, not visual reasoning.
3. Color contrast and accessibility are baked into the theme — DaisyUI themes are WCAG-compliant by design.

Bootstrap has its own Tier 2 equivalent: Bootswatch themes (Cerulean, Flatly, Darkly, Superhero, etc.). These are drop-in CSS overrides — replace one file, entire appearance changes. Same label-matching approach.

**Can an LLM reliably pick a DaisyUI theme that matches a project's domain?**

Yes, with high confidence, because this is a categorization problem, not an aesthetic judgment. The LLM maps:
- "admin dashboard / SaaS / B2B tool" → `corporate`, `business`, `nord`
- "developer tool / CLI companion / technical UI" → `dracula`, `night`, `synthwave`
- "consumer app / e-commerce / marketing" → `light`, `cupcake`, `pastel`
- "data visualization / analytics" → `corporate`, `lofi`
- "dark mode default" → `dark`, `dracula`, `black`

This works because the theme names have semantic content. An LLM can read "this is a task management dashboard for enterprise teams" and match it to `corporate` or `business` without any visual reasoning. The match is linguistic, not visual.

Failure mode: generic projects that don't map cleanly to any theme category. But the fallback is always `light` (default) — the worst case is Tier 1 quality, not broken output.

**Tier 3: Framework + custom design tokens**

This requires the LLM to choose specific hex colors, font families, spacing scales, and border radii. This is where variance explodes. An LLM can plausibly choose `#4F46E5` (indigo) as a primary color, but it cannot reliably:
- Ensure sufficient contrast ratio between chosen colors (WCAG 4.5:1 for normal text)
- Select a harmonious palette (complementary, analogous, triadic relationships)
- Match brand expectations without brand guidelines
- Maintain internal consistency across a design token set

The output quality distribution is bimodal: when the LLM happens to pick coherent defaults (e.g., a standard blue + white + gray palette), the result looks decent. When it makes unusual choices or fails to maintain consistency, the result looks amateurish. This variance is unacceptable for a scaffold pipeline that must produce reliable baselines.

#### Accessibility Analysis

This is the strongest argument for Tier 2 over Tier 3. Accessibility in CSS falls into two categories:

**Rule-based (LLM-reliable):**
- Semantic HTML structure (`<nav>`, `<main>`, `<article>`, `<button>` vs `<div>`)
- ARIA roles and labels (`aria-label`, `aria-describedby`, `role="dialog"`)
- Keyboard event handlers on interactive elements
- Tab order via `tabindex` conventions

LLMs are reliable here because these are mechanical rules with known correct/incorrect states, not aesthetic judgments. The LLM can be instructed with a checklist and will follow it.

**Contrast and visual (framework-dependent):**
- Color contrast ratios (WCAG AA: 4.5:1 for text, 3:1 for UI components)
- Focus ring visibility
- State differentiation (hover, active, disabled, focus)

DaisyUI themes are designed to be WCAG-compliant — they pass 4.5:1 contrast by default. Tailwind's default palette is designed with accessible contrast combinations in mind (e.g., `text-slate-900` on `bg-slate-50`). This means choosing a pre-designed theme effectively delegates contrast compliance to the framework maintainers, who have already done the testing.

At Tier 3, the LLM must independently ensure contrast compliance when choosing custom colors — and it cannot do this reliably without running a contrast checker, which is not part of the scaffold pipeline.

**Conclusion: Tier 2 is the right answer**

Tier 1 gives a coherent mathematical scale but requires class application discipline to produce visual output (for Tailwind). Tier 2 gives a complete, intentional visual language where the LLM makes one categorical decision (theme name) and gets correct contrast, consistent components, and domain-appropriate aesthetics. Tier 3 is high-risk with unpredictable output quality.

The 80/20 hypothesis is roughly correct but the split is better framed as:
- Tier 1: 60% of the improvement (from unstyled to "looks like a real app")
- Tier 2: 30% more (from "generic framework" to "looks intentional and domain-appropriate")
- Tier 3: remaining 10% (from "generic theme" to "custom brand") — but with 5x the risk

For a scaffold pipeline, Tier 2 is the correct stopping point.

### Analysis (Plugin Implications)

The stack-selector currently selects frontend frameworks (React, Vue, Svelte) but makes no CSS framework decision. Adding CSS framework selection to stack-selector's output is a natural extension — it already makes opinionated single-choice recommendations.

The scaffolder currently generates files in 5 batches. A "Batch 6 — Design" would contain:
1. CSS framework installation (package.json entry + install command)
2. Framework config file (tailwind.config.js or equivalent)
3. Theme selection (DaisyUI data-theme attribute, or Bootswatch import)
4. Global styles entry point (src/styles/globals.css or app.css)
5. One layout component with proper semantic HTML structure

This is 4-5 files — fits cleanly within the ≤20 file budget.

The key insight is that the LLM writes zero aesthetic decisions in this batch. It:
1. Runs `npm install tailwindcss daisyui` (deterministic)
2. Writes a config file with a template (deterministic)
3. Maps project domain → theme name (categorical, high reliability)
4. Applies global import (deterministic)

### Recommendation

**Use Tier 2 (DaisyUI on Tailwind) as the default for React/Vue/Svelte/Next.js/Nuxt/SvelteKit projects.** For server-rendered projects (Django+templates, Rails+views, Flask+Jinja) where Tailwind adds build complexity, use Bootstrap 5 via CDN (Tier 1 for SSR simplicity, Tier 2 optionally with Bootswatch). For classless alternatives in lightweight projects, Pico CSS (Tier 1) is acceptable.

The decision logic for the stack-selector output:
- React/Next.js/Remix → Tailwind + DaisyUI (theme selected by project domain)
- Vue/Nuxt/SvelteKit → Tailwind + DaisyUI
- Svelte (non-SvelteKit) → Tailwind + DaisyUI
- Django/Rails/Flask templates → Bootstrap 5 CDN
- HTMX-based → Tailwind + DaisyUI or Bootstrap 5

---

## RQ4: How to Detect "Web Project" vs "CLI/API"

### Findings

#### Signal Analysis from Existing Codebase

Reading `agents/stack-selector.md`, the agent currently outputs:
- Framework with version
- Database + driver
- Testing framework
- Linting tools
- CI/CD configuration

It does **not** currently emit a `project_type` field. However, the framework choice is an unambiguous signal for most cases.

**Framework-to-project-type mapping:**

| Framework | Project Type | Confidence |
|-----------|-------------|------------|
| React, Next.js, Remix | web | HIGH — frontend-first by definition |
| Vue, Nuxt | web | HIGH |
| Svelte, SvelteKit | web | HIGH |
| Angular | web | HIGH |
| Astro | web | HIGH |
| Django + templates | web | HIGH — if using template rendering |
| Rails (views) | web | HIGH — if using view layer |
| Flask + Jinja | web | HIGH — if using template rendering |
| HTMX (+ any backend) | web | HIGH |
| Express + React/Vue/EJS views | web | MEDIUM — depends on whether it renders views |
| FastAPI | api | HIGH — rarely used for server-rendered HTML |
| Django REST Framework | api | HIGH |
| Flask (API mode) | api | MEDIUM — Flask can do either |
| Express (API-only) | api | MEDIUM — ambiguous without more context |
| Go gin | api | HIGH |
| Go fiber | api | HIGH |
| Rust actix-web | api | HIGH |
| gRPC | api | HIGH |
| Click, Typer | cli | HIGH |
| Commander, Clap, Cobra | cli | HIGH |

**The ambiguous cases:**
- Express: can serve templates (Pug, EJS, Handlebars) or be a pure JSON API. The presence of a view engine in dependencies resolves the ambiguity.
- Django: can use templates or DRF. The presence of `djangorestframework` in dependencies = api; template configuration = web.
- Flask: same split as Django — `flask-restx`/`marshmallow` = api; `Jinja2` templates = web (Flask includes Jinja2 by default but usage pattern matters).

#### Signal 1: Stack-Selector Output (Primary Signal)

The stack-selector is the most reliable single signal because it has already made a decisive framework choice, and framework maps almost deterministically to project type. The recommendation is to add `project_type` to stack-selector's output format.

Current output format ends with a Key dependencies table. Adding a `project_type` field to the Stack Selection output:

```markdown
## Stack Selection
- **Stack summary:** {one-line}
- **Project type:** web | api | cli | library
- **Rationale:** ...
```

This is a minimal, non-breaking addition. The field value is derived mechanically from the framework choice — it does not require new analysis.

The `project_type` value enables:
- Scaffold skill: enable/disable design batch
- Spec-writer: conditionally include "UI & Design" section
- Scaffolder: Batch 6 (Design) conditional execution
- Test setup: Playwright vs supertest vs pytest selection (scaffolder already partially does this via E2E Test section detection)

#### Signal 2: Spec/README.md Content (Secondary Signal — Scaffold v2 Mode)

In scaffold v2 mode (when spec-writer runs first), the spec/README.md Tech Stack section contains the chosen framework. The scaffolder already reads this file in step 1. Adding a `project_type` derivation from the spec Tech Stack is straightforward.

Keywords in spec content that indicate web (not framework names — these are domain-level signals):
- "web app", "web application", "webapp"
- "dashboard", "admin panel", "control panel"
- "landing page", "marketing site"
- "SPA", "single-page application"
- "user interface", "UI"
- "pages", "routes" (in frontend router context)
- "browser", "client-side"
- "responsive design", "mobile-first"

Keywords in spec content that indicate API-only:
- "REST API", "RESTful", "HTTP API"
- "JSON endpoints", "microservice"
- "no frontend", "headless", "API-only"
- "SDK", "client library" (unless browser SDK)
- "webhook", "event stream"

Keywords in spec content that indicate CLI:
- "command-line", "CLI", "terminal"
- "script", "automation tool"
- "stdin/stdout", "pipe", "shell"

The spec-writer could also emit a `project_type` field in its output report, derived from the Tech Stack section and description analysis.

#### Signal 3: User Description (Tertiary Signal)

The scaffold command receives a natural language description. Keywords in this description provide early detection before spec-writer or stack-selector runs. This is useful for:
1. Asking more targeted clarifying questions (stack-selector step 3)
2. Influencing spec-writer's UI/UX section inclusion
3. Pre-selecting CSS framework candidates before stack-selector finalizes

High-confidence web indicators in user description:
- "web app", "website", "dashboard", "frontend", "UI", "SPA", "PWA"
- Named frameworks: "React app", "Vue project", "Next.js site"

High-confidence API indicators:
- "API", "REST", "backend service", "microservice", "server", "webhook handler"

High-confidence CLI indicators:
- "CLI tool", "command-line tool", "script", "automation"

#### Signal 4: Explicit Flag (Highest Priority)

An explicit `--web` or `--api` or `--cli` flag overrides all heuristic detection. This is the escape hatch for ambiguous cases. The user knows their project type; flags allow them to assert it directly.

The scaffold skill already parses flags (`--lang`, `--framework`, `--db`, `--ci`). Adding `--web` / `--no-ui` / `--api` / `--cli` follows the same pattern.

Flag semantics:
- `--web`: force design batch to run (even for ambiguous stacks like Express)
- `--api`: suppress design batch (even if React is somehow in the stack for API documentation)
- `--cli`: suppress design batch, use CLI-specific scaffolding patterns

#### Signal Combination and Priority Order

For determining `project_type`, apply in this priority order:

1. **Explicit flag** (`--web` / `--api` / `--cli`) — takes precedence over everything
2. **Stack-selector `project_type` output** — primary derived signal, high confidence
3. **Spec README.md Tech Stack section** (scaffold v2 mode) — explicit tech stack record
4. **Spec/description keyword analysis** — lower confidence, useful for early pipeline stages

In practice, for a standard scaffold flow:
- The explicit flag (if provided) resolves it immediately
- Otherwise, stack-selector resolves it after step 1 of the pipeline
- The user description can be used for early context to inform stack-selector's questions

#### The Ambiguous Cases and How to Resolve Them

**Express.js:** Check for view engine dependency (ejs, pug, handlebars, nunjucks) → web. No view engine → api. Default to api if uncertain (better to miss optional design than add unwanted CSS framework to an API).

**Django:** Check for `djangorestframework` in requirements → api. Check for template dirs in settings → web. Default to web (Django's primary use case is server-rendered apps).

**Flask:** Check for `flask-restx`, `flask-restful`, or schema libraries (marshmallow, pydantic) as primary deps → api. Template usage in description → web. Default to api (Flask is increasingly used as microservice framework).

**Full-stack projects (Next.js API routes, SvelteKit form actions, Nuxt server routes):** These are web — they have a frontend. The presence of a frontend framework always makes it `web`, regardless of backend API capabilities.

#### Current Stack-Selector Output Format Analysis

The current output format in `agents/stack-selector.md` (step 5) is:

```markdown
## Stack Selection
- **Stack summary:** {one-line}
- **Rationale:** {2-3 sentences}
- **Project structure:** {directory layout}
- **Key dependencies:** {table}
```

Adding `project_type` requires a one-line addition:

```markdown
## Stack Selection
- **Stack summary:** {one-line}
- **Project type:** web | api | cli | library
- **Rationale:** ...
```

The scaffold skill (and scaffolder agent) reads the Stack Selection output to determine what to generate. Adding a `project_type` field to the stack-selector output and having the scaffold skill/scaffolder branch on it is a minimal, clean extension.

### Analysis (Plugin Implications)

The detection approach has a clean single-point-of-truth design: stack-selector emits `project_type`, everything downstream reads it. This avoids each agent independently inferring project type from heuristics, which would introduce divergence.

The scaffold skill (skills/scaffold/SKILL.md) orchestrates the pipeline. The design batch decision should live in the skill, not in individual agents:

```
IF project_type == "web":
  → Run Batch 6 (Design) in scaffolder
  → Include "Design & UX" section in spec-writer (scaffold v2)
ELSE:
  → Skip design batch
```

This is a clean conditional that the skill is already structured to handle (it already has conditional steps like Step 4e for tracker issues).

The ambiguous stack cases (Express, Flask, Django) should default conservatively: if uncertain, omit the design batch. An unwanted CSS framework in an API project is more disruptive than a missing design batch in a web project (the developer can add CSS easily; removing an unexpected framework from an API project requires cleanup).

### Recommendation

**Use stack-selector as the primary signal with explicit flag override.**

Specific changes required:
1. Add `project_type: web | api | cli | library` to stack-selector's output format (step 5)
2. Add detection logic to stack-selector for the ambiguous cases (Express, Flask, Django)
3. Add `--web` / `--api` / `--cli` flags to scaffold skill flag parsing
4. In scaffold skill: read `project_type` from stack-selector output and gate Batch 6 on `project_type == "web"`
5. In scaffold v2 mode (spec-writer first): derive `project_type` from spec/README.md Tech Stack section instead of stack-selector output (stack-selector doesn't run in v2 mode)

The conservative default (ambiguous = no design batch) prevents the more disruptive failure mode. The `--web` escape hatch covers the cases where the LLM gets it wrong.

**Key finding: stack-selector is the right place for this determination** because it already makes the framework decision and that decision deterministically implies project type for 80%+ of projects. The ambiguous cases (Express, Flask, Django without strong signals) represent a small fraction of real projects, and the explicit flag provides the escape hatch for those.
