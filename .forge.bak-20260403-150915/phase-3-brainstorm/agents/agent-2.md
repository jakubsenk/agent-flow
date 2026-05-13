# Agent 2: Systems Architect Perspective

## Core Question

The combination approach (stack-selector + spec-writer + scaffolder) correctly identifies the three touch points. But the ARCHITECTURE of how data flows between them determines whether this feature ages well or becomes a maintenance headache. What is the right data contract, detection strategy, and extensibility model?

**Answer: The combination approach is correct, but it needs a formal `project_type` signal, a design context contract, and an opt-out mechanism. The minimalist "scaffolder-only" approach creates hidden coupling that will break when the pipeline evolves.**

## Why Scaffolder-Only Is Architecturally Wrong

Agent 1's proposal has the scaffolder doing its own web detection by pattern-matching framework names against a hardcoded list. This creates three problems:

1. **Duplicated detection logic.** The scaffold skill (Step 3 and Step 7) already needs to know whether this is a web project for E2E test framework selection (`playwright` for web, `supertest` for API). Today this is implicit. Adding a second independent detection in the scaffolder means two lists of "what counts as web" that can diverge. When Astro or HTMX or Leptos gets popular, someone updates one list but not the other.

2. **No signal for downstream agents.** The fixer does not read `tailwind.config.js` to decide how to write CSS. It reads its task context, which comes from the architect's decomposition and the spec. If the fixer is implementing a "user dashboard" subtask and has no design context, it will write raw HTML with inline styles or no styles at all -- exactly the problem we are solving. The scaffolder generating config files is necessary but not sufficient. The fixer needs to KNOW there is a design system and what it is.

3. **No override point.** "If someone doesn't want Tailwind, they delete the generated files" is not a design philosophy; it is the absence of one. The Agent Overrides mechanism already exists for per-project tuning. A user who wants Bootstrap instead of Tailwind should not need to delete files and regenerate -- they should be able to declare it.

## Proposed Architecture: `project_type` as a First-Class Pipeline Signal

### The Signal

Add `project_type` to stack-selector output. This is not just about CSS -- it is an architectural signal that affects:

| Downstream consumer | What `project_type` changes |
|---------------------|---------------------------|
| Scaffolder | Batch 6 (Design) runs or skips |
| Spec-writer | Conditional `spec/design.md` section |
| Scaffolder (E2E config) | `playwright` vs `supertest` vs `pytest` |
| Fixer | Design context in task prompt (via spec/) |
| Test-engineer | Frontend test patterns (component tests, visual regression) |
| Architect | Subtask decomposition includes UI subtasks |
| Future: browser-verifier | Auto-enabled for web projects |

One signal, many consumers. This is the textbook case for making it explicit rather than having each consumer re-derive it independently.

### Data Flow

```
User description + flags
    |
    v
[Stack-selector] ──> project_type: web | api | cli | library
    |                 css_framework: tailwind+daisyui | bootstrap | pico | none
    |                 css_theme: corporate | dracula | light | nord | (null)
    |
    v
[Spec-writer] ──> IF project_type == "web":
    |               generate spec/design.md
    |             ELSE:
    |               skip (note: "No UI -- design section not applicable")
    |
    v
[Scaffolder] ──> IF project_type == "web":
    |              run Batch 6 (Design) using css_framework + css_theme
    |            ELSE:
    |              skip Batch 6
    |
    v
[Architect] ──> reads spec/design.md for UI-aware decomposition
    |
    v
[Fixer] ──> reads spec/design.md from spec/ folder (zero code change)
```

### Stack-Selector Output Extension

Current output:
```markdown
## Stack Selection
- **Stack summary:** ...
- **Rationale:** ...
- **Project structure:** ...
- **Key dependencies:** ...
```

Proposed output:
```markdown
## Stack Selection
- **Stack summary:** ...
- **Project type:** web | api | cli | library
- **CSS framework:** Tailwind CSS + DaisyUI | Bootstrap 5 | Pico CSS | none
- **CSS theme:** corporate | dracula | light | nord | (none)
- **Rationale:** ...
- **Project structure:** ...
- **Key dependencies:** ...
```

Three new fields. The `CSS framework` and `CSS theme` fields are only populated when `Project type` is `web`. For non-web projects they are `none` and `(none)` respectively.

### Detection Logic in Stack-Selector

Add to stack-selector Process step 4, after framework selection:

```
4b. Derive project type from the selected framework:
    - WEB: React, Vue, Svelte, Angular, Next.js, Nuxt, SvelteKit, Remix, Astro,
           Django (with template dirs), Rails (with views), Laravel (with Blade),
           Flask (with Jinja templates), HTMX (with any backend)
    - API: FastAPI, Express (API-only), Go gin, Go fiber, Rust actix-web,
           Django REST Framework, Flask (API mode), gRPC, Hono
    - CLI: Click, Typer, Commander, Cobra, Clap, argparse-based
    - LIBRARY: projects with no runnable entry point (npm package, PyPI package, crate)

    Ambiguous cases default to api (conservative -- missing CSS is less disruptive
    than unwanted CSS in an API project).

    If explicit --web / --api / --cli flag was passed, use the flag value
    regardless of framework detection.

4c. If project_type == "web", select CSS framework:
    - SPA frameworks (React, Vue, Svelte, Next.js, Nuxt, SvelteKit, Remix, Astro):
      → Tailwind CSS + DaisyUI
    - Server-rendered with build pipeline (Rails with Vite/esbuild, Laravel Mix/Vite):
      → Tailwind CSS + DaisyUI
    - Server-rendered without build pipeline (Django templates, Flask+Jinja, Rails Sprockets):
      → Bootstrap 5 (CDN -- no build step needed)
    - Lightweight/minimal (HTMX, vanilla JS, static site):
      → Pico CSS (classless -- zero overhead)

4d. If project_type == "web" AND css_framework includes DaisyUI, select theme:
    Map project domain to theme using categorical matching (not aesthetic judgment):
    - enterprise / dashboard / admin / B2B → corporate
    - developer tool / technical / DevOps → dracula
    - consumer / social / e-commerce / marketing → light
    - content / blog / documentation / portfolio → nord
    - ambiguous / unspecified → light (safe default)
```

### Spec-Writer Conditional Section: `spec/design.md`

When `project_type == "web"` (detected from tech stack flags or description keywords -- spec-writer runs before stack-selector in scaffold v2 mode), spec-writer generates an additional file:

```markdown
# Design & UI

## CSS Framework
- **Framework:** {Tailwind CSS + DaisyUI | Bootstrap 5 | Pico CSS}
- **Theme:** {theme name} — rationale: {domain-category match}
- **Theme alternatives:** {2 other theme names that could work}

## UI Patterns
- **Layout:** {sidebar + content | top-nav + content | landing page}
- **Key components:** {list of 3-5 component types the project needs}
  e.g., data tables, form wizards, card grids, navigation menus
- **Responsive strategy:** mobile-first | desktop-first

## Accessibility Baseline
- Semantic HTML required (nav, main, article, section, aside, button)
- ARIA labels on all interactive elements
- Keyboard navigation for all interactive flows
- Color contrast: delegated to {framework} theme (WCAG AA compliant)

## Design Constraints
- No custom color tokens -- use framework theme colors exclusively
- No custom fonts -- use framework default type scale
- Component styling via framework utility classes only (no custom CSS except layout)
```

This file is SHORT (30-50 lines), prescriptive (not exploratory), and machine-readable. It gives the fixer and architect enough context to write CSS-aware code without making aesthetic decisions.

In scaffold v2 mode (spec-writer runs first, no stack-selector), spec-writer derives `project_type` from its own Tech Stack section. In --no-implement mode (stack-selector runs first), the scaffold skill passes `project_type` from stack-selector output to the scaffolder.

### Scaffolder Batch 6 (Design)

Same as Agent 1's proposal, but driven by the explicit `project_type` and `css_framework` fields rather than re-deriving from framework names:

```markdown
   **Batch 6 -- Design (web projects only):**
   - Guard: skip this batch if project_type != "web" (from stack-selector output
     or spec/README.md Tech Stack section). If project_type is not available in
     context, fall back to framework detection (same list as stack-selector step 4b).
   - Read css_framework and css_theme from:
     (a) stack-selector output (--no-implement mode), OR
     (b) spec/design.md CSS Framework section (scaffold v2 mode)
   - For Tailwind + DaisyUI:
     - Add tailwindcss, postcss, autoprefixer, daisyui to dependencies
     - Generate tailwind.config.js with DaisyUI plugin + selected theme
     - Generate postcss.config.js
     - Generate global stylesheet with @tailwind directives
     - Update entry point/layout to import global stylesheet
     - Set data-theme attribute on root HTML element
   - For Bootstrap 5:
     - Add bootstrap to dependencies (or CDN link for server-rendered)
     - Generate global stylesheet importing Bootstrap
     - Add Bootswatch theme if css_theme is specified
   - For Pico CSS:
     - Add @picocss/pico to dependencies (or CDN link)
     - No additional config needed
```

### Scaffold Skill Flag Extension

Add to flag parsing in `skills/scaffold/SKILL.md`:

```
- `--web` → force project_type = "web"
- `--api` → force project_type = "api"
- `--cli` → force project_type = "cli"
- `--css <value>` → css_override (e.g., "bootstrap", "pico", "none")
```

The `--css none` flag explicitly suppresses Batch 6 even for web projects. This is the clean opt-out mechanism.

Flag validation:
- `--web` + `--api` or `--web` + `--cli` → Error: "Only one project type flag allowed."
- `--css` without `--web` (and project is auto-detected as non-web) → Warning: "--css specified but project type is not web. CSS framework will be added anyway."

### The Override Question: New Config Section vs Agent Overrides

There are two ways a consuming project could customize the CSS framework choice:

**Option A: New optional Automation Config section**

```markdown
### Design Defaults
| Key | Value |
| CSS framework | bootstrap |
| CSS theme | flatly |
| Skip design | false |
```

This would be read by config-reader and passed to scaffolder. It is a MINOR version bump (new optional section). It is clean and explicit. But it adds config surface area for a feature that most projects will use the default for.

**Option B: Agent Overrides (existing mechanism)**

Create `customization/scaffolder.md`:
```markdown
For Batch 6 (Design), use Bootstrap 5 with the Flatly Bootswatch theme instead of
Tailwind + DaisyUI. Do not install Tailwind.
```

Or `customization/spec-writer.md`:
```markdown
In spec/design.md, specify Bootstrap 5 as the CSS framework instead of Tailwind.
```

This works today with zero code changes. It is natural language, so it is flexible. But it is imprecise -- the LLM might not follow it perfectly. And it requires the user to know the override mechanism exists.

**Recommendation: Start with Agent Overrides, add the config section later if demand materializes.**

Agent Overrides already exist. The shipped `examples/agent-overrides/` directory could include a `design-override/` example showing how to customize the CSS framework. This is zero new config surface (no version bump for the override part), and it covers the 5% of users who want something other than the default.

If multiple users report that natural-language overrides are unreliable for CSS framework selection, THEN add the `### Design Defaults` config section as a follow-up MINOR bump. This is the YAGNI-compliant path: don't add config for a hypothetical need.

### What About `spec/design.md` in the Fixer Context?

The research findings (RQ5) note that "Fixer gets `spec/design.md` for free" because the fixer already has the spec/ folder available. This is true but incomplete.

The fixer reads its task context, which includes:
1. The subtask scope from architect decomposition
2. The acceptance criteria
3. Access to the spec/ folder

If `spec/design.md` exists, the fixer CAN read it. But will it? The fixer's current Process step 2 says "Read project conventions from CLAUDE.md." It does not say "Read spec/design.md." For the design context to reliably flow to the fixer, one of two things must happen:

**Option 1: Architect includes design context in subtask decomposition.**
When the architect decomposes an epic that has UI components, the subtask descriptions should reference `spec/design.md`: "Implement the dashboard layout using the CSS framework specified in spec/design.md." This happens naturally if `spec/design.md` exists -- the architect reads the full spec/ folder.

**Option 2: Fixer prompt includes explicit design reference.**
Add to fixer Process step 2: "If spec/design.md exists, read it for CSS framework and component pattern guidance."

Option 1 is cleaner because it works through the existing data flow (architect -> fixer context) without modifying the fixer agent definition. The architect already reads the full spec/. If `spec/design.md` says "use DaisyUI btn-primary for buttons," the architect will include that guidance in UI-related subtask descriptions.

However, Option 2 is a safety net -- one line in the fixer that costs nothing and guarantees the design context is read even if the architect's decomposition omits it. I recommend BOTH: Option 1 as the primary path, Option 2 as a belt-and-suspenders addition (one line in `agents/fixer.md`, PATCH version).

## Exact Changes

### Files Modified (4)

1. **`agents/stack-selector.md`** -- add `project_type`, `CSS framework`, `CSS theme` to output format; add steps 4b/4c/4d to Process
2. **`agents/spec-writer.md`** -- add conditional `spec/design.md` generation for web projects (new step between current steps 3 and 4)
3. **`agents/scaffolder.md`** -- add Batch 6 (Design) with css_framework/css_theme input; add Design row to scorecard
4. **`agents/fixer.md`** -- add one line to Process step 2: "If spec/design.md exists, read it."

### Files Modified (1 skill)

5. **`skills/scaffold/SKILL.md`** -- add `--web`/`--api`/`--cli`/`--css` flags to flag parsing; pass `project_type` from stack-selector to scaffolder in --no-implement flow; pass `project_type` derivation note to spec-writer in v2 flow

### Files Added (1 example)

6. **`examples/agent-overrides/design-override/`** -- example scaffolder.md and spec-writer.md overrides showing how to switch CSS framework

### Files NOT Changed

- `core/config-reader.md` -- no new config section (Agent Overrides covers customization)
- `core/agent-override-injector.md` -- mechanism already works, no changes needed
- `agents/architect.md` -- already reads full spec/; spec/design.md flows naturally
- `agents/reviewer.md` -- does not need design awareness (reviews code quality, not design)
- `agents/test-engineer.md` -- does not need design awareness (tests functionality, not appearance)

## Version Impact

**MINOR (6.2.0)** -- stack-selector output format gains new optional fields. No breaking changes. No new required config keys. No new agents.

This is correct per the versioning policy: "new optional capability in stack-selector" = MINOR.

## Addressing Potential Objections

### "This is 5 files changed vs 1. Is the complexity justified?"

Yes, because the 5-file change creates a SYSTEM that flows data correctly. The 1-file change creates an island of logic that other agents cannot reach. The marginal cost of adding `project_type` to stack-selector (15 lines) and a conditional section to spec-writer (20 lines) pays for itself the first time the fixer generates raw HTML in a Tailwind project because it had no design context.

### "YAGNI -- project_type is only used for CSS today."

It is used for E2E framework selection today (scaffolder already picks playwright vs supertest based on implicit project type detection). Making it explicit unifies two existing implicit detection paths into one authoritative signal. It also immediately unlocks: different CI templates (web projects need browser setup in CI), different Dockerfile patterns (web projects need static asset build stage), and future browser-verifier auto-enablement. These are not hypothetical -- they are features that already exist or are on the roadmap.

### "What if someone wants a CSS framework we don't support?"

The `--css` flag accepts any value. If someone passes `--css bulma`, the stack-selector sets `css_framework: bulma` and the scaffolder's Batch 6 receives it. The scaffolder already handles unknown/unsupported stacks by asking for guidance -- it can do the same for CSS frameworks. The common case (Tailwind/Bootstrap/Pico) is handled by templates; the uncommon case is handled by LLM flexibility.

### "What about projects that start as API and grow into web?"

This is a real scenario (e.g., FastAPI backend gets a React frontend later). The answer is: run `/scaffold-add design` (future command) or manually add the CSS config. The scaffold pipeline runs once at project creation. Post-scaffold changes go through `/implement-feature`, where the fixer can add CSS framework setup as part of implementing a "add web frontend" feature. The `project_type` signal does not lock the project permanently.

## Comparison to Agent 1

| Dimension | Agent 1 (Scaffolder only) | This proposal |
|-----------|--------------------------|---------------|
| Files changed | 1 | 5 + 1 example |
| Version bump | PATCH | MINOR |
| Web detection | Inline framework list in scaffolder | Explicit `project_type` in stack-selector |
| Fixer awareness | None (reads tailwind.config.js if lucky) | spec/design.md + one-line fixer hint |
| CSS override | Delete files or natural-language override | `--css` flag + Agent Override example |
| Architect awareness | None | Reads spec/design.md naturally |
| Future-proofing | Must add detection to each new consumer | One signal, all consumers read it |
| Risk of divergent detection | High (each agent has its own list) | Low (single source of truth) |

## Recommendation

Ship the combination approach as MINOR 6.2.0. The `project_type` signal is the architecturally correct abstraction -- it costs 15 lines in stack-selector and pays dividends across the entire pipeline. The `spec/design.md` conditional section ensures design context flows to implementation agents without requiring them to reverse-engineer the scaffolder's output. The `--css` flag and Agent Override example provide clean customization without new config surface area.

Do NOT add a `### Design Defaults` config section yet. Let Agent Overrides handle customization for now. If the natural-language override proves unreliable, add the config section as a follow-up MINOR bump. One step at a time.
