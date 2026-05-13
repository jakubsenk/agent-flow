# Research Agent 1 — CSS Frameworks & Scaffold Tool Design Defaults

## RQ1: What CSS Frameworks Work Best with LLM-Generated Code?

### Findings

**1. Tailwind CSS**

Tailwind is utility-first: every visual property is expressed as an atomic class (`bg-blue-500`, `text-sm`, `px-4`, `rounded-lg`, `flex`, `gap-2`). LLMs have trained on an enormous volume of Tailwind code — it appears in nearly every modern React, Next.js, Vue, and SvelteKit project on GitHub post-2020.

Setup complexity for automation:
- `npm install -D tailwindcss postcss autoprefixer`
- `npx tailwindcss init -p` (generates `tailwind.config.js` + `postcss.config.js`)
- Add `content` paths to config (critical — without this, PurgeCSS removes all classes in production)
- Add `@tailwind base/components/utilities` directives to the main CSS file

This is 4 deterministic steps. Every step is automatable with file writes. The `tailwind.config.js` content is predictable — it's a module.exports with a `content` array and optional `theme.extend` block.

LLM reliability with Tailwind: very high. Class names follow a strict naming convention (`{property}-{value}` or `{property}-{scale}`). The LLM knows: `text-{size}`, `bg-{color}-{shade}`, `p-{size}`, `m-{size}`, `flex`, `grid`, `border-{width}`, `rounded-{size}`, `shadow-{size}`. Mistakes are mostly harmless (wrong scale step, wrong shade) — they degrade appearance but don't break builds. The build-time purge step means unused classes have zero cost.

Risk: class explosion on complex components. A single `<div>` can accumulate 15-20 classes. Readability suffers. But for LLM generation, this is actually an advantage: no CSS files to maintain, all styling is colocated with markup.

**2. Bootstrap**

Bootstrap is component-based: semantic classes like `btn btn-primary`, `card`, `navbar`, `form-control`. It peaked circa 2015-2018 and remains well-represented in LLM training data, but modern LLM training skews toward utility-first patterns.

Setup complexity: `npm install bootstrap` + one CSS import. Zero config required. Simpler than Tailwind.

LLM reliability: moderate. Bootstrap 5 (current) differs from Bootstrap 3/4 in meaningful ways (no jQuery, changed class names, new utilities). LLMs occasionally produce Bootstrap 4 patterns when targeting Bootstrap 5. The component class names are semantic and memorable (`badge`, `alert`, `modal`) but the modifier system (`btn-outline-primary`, `text-muted`, `mb-3`) requires consistent recall. Grid system (`col-md-6`, `row`) is well-known but verbose.

Verdict: Bootstrap is declining. npm download trends show flat/declining growth. Most new projects choose Tailwind. The "outdated look" risk is real — Bootstrap projects look like 2016 unless heavily customized.

**3. Shadcn/ui**

Shadcn/ui is a component registry, not a traditional npm package. The model is: run `npx shadcn@latest add button` and it copies the component source into your project's `components/ui/` directory. Components are Radix UI primitives + Tailwind classes + `class-variance-authority` (CVA) for variant management.

Setup complexity for automation: prohibitive. The `shadcn init` command is interactive — it asks about style (Default/New York), base color (Slate/Gray/Zinc), CSS variables preference. The CLI modifies `tailwind.config.js`, `globals.css`, creates `lib/utils.ts`. Individual component additions require per-component CLI invocations. This is fundamentally incompatible with a markdown-only plugin that cannot execute interactive CLIs during scaffolding.

An LLM can write Shadcn components from scratch (copy the patterns), but this requires accurate knowledge of the exact component structure, which drifts with library versions.

Verdict: not automatable in a markdown-only plugin. Ruled out.

**4. CSS Modules / Vanilla CSS**

CSS Modules: each component gets a `ComponentName.module.css` file with scoped class names. No framework overhead. BEM is a naming convention (`.card__header--active`), not a framework.

LLM reliability: low-to-moderate. Without framework conventions, every project's CSS structure is ad hoc. LLMs produce inconsistent results: sometimes over-specifying (50 CSS rules for a simple card), sometimes under-specifying (no hover states, no mobile styles). There are no class name conventions to anchor the LLM's output. The visual quality floor is the lowest of all options — a bare CSS project from an LLM will look like 1999 unless the LLM is explicitly guided.

Setup complexity: zero. No installation, no config. But zero setup = zero guardrails.

**5. Classless CSS (Pico CSS, Simple.css, Water.css)**

Classless frameworks style semantic HTML elements directly. `<button>` looks like a button. `<table>` looks like a table. `<form>` gets spacing and typography. No classes needed.

Setup: one CSS file import (`<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/@picocss/pico@2/css/pico.min.css">` or npm install). Single line.

LLM reliability: highest among all options, because the LLM only needs to write correct semantic HTML — the framework does the rest. No class mistakes possible. The semantic HTML constraint also improves accessibility automatically.

Pico CSS (most capable of the classless options): supports dark mode, responsive typography, responsive grid via `<article><aside>` pattern. Pico v2 added utility classes for when semantic isn't enough.

Risk: limited customization. All projects look similar. Complex UIs (dashboards, data tables, multi-panel layouts) hit the ceiling quickly. Visual quality floor is decent but ceiling is low.

### Analysis

Ranking by the four criteria:

| Framework | LLM Reliability | Setup Automation | Visual Quality Floor | Lock-in Risk |
|-----------|-----------------|------------------|----------------------|--------------|
| Tailwind CSS | A (highly structured, predictable) | B (4 steps, fully automatable) | B+ (decent defaults, scales well) | Low (utility classes transferable) |
| Pico/Classless | A+ (no classes needed) | A+ (1 import) | B (decent for simple apps) | Very Low (just HTML) |
| Bootstrap | B (API drift across versions) | A (1 npm install) | C+ (dated aesthetic) | Medium (class names everywhere) |
| CSS Modules/Vanilla | C (inconsistent, no guardrails) | A+ (zero config) | D (poor floor, high variance) | None |
| Shadcn/ui | B (version-sensitive) | F (not automatable) | A (excellent) | High (CVA, Radix dependencies) |

**Key insight:** There is a fundamental tension between LLM reliability and visual ceiling. Classless CSS gives the most reliable LLM output but the lowest ceiling. Tailwind gives a high ceiling but requires accurate class name recall. For a scaffold that produces a starting point (not a finished product), the right question is: what produces a non-embarrassing baseline that a developer can build on?

Tailwind wins on LLM reliability + setup automation + visual quality floor for anything beyond a simple CRUD app. For simple web apps, Pico CSS is a legitimate alternative with near-zero setup cost.

### Recommendation

**Primary recommendation: Tailwind CSS** for frontend/fullstack projects. The setup is 4 automatable steps. LLM class name accuracy is high. The visual quality floor is acceptable. The ecosystem is dominant (every React/Vue/Svelte template uses it).

**Secondary recommendation: Pico CSS** as a fallback for simple web projects or when the scaffolder detects a templating-based stack (Django templates, Rails ERB, Jinja2) where a utility-first framework is awkward.

Bootstrap should be excluded — it's declining and the aesthetic is dated. Shadcn/ui is excluded — not automatable. Vanilla CSS is excluded — quality floor is too low.

---

## RQ2: How Do Other Scaffold Tools Handle Design Defaults?

### Findings

**1. create-next-app**

`npx create-next-app@latest` presents an interactive prompt:
```
Would you like to use Tailwind CSS? No / Yes
```
It defaults to "Yes" in recent versions (since Next.js 13.1, late 2022). When Tailwind is selected, it installs `tailwindcss`, `postcss`, `autoprefixer`, generates `tailwind.config.ts`, `postcss.config.js`, and adds Tailwind directives to `globals.css`. The generated `page.tsx` uses Tailwind classes from the first line.

Verdict: Next.js has normalized Tailwind as the default choice, but it still asks. The prompt is a deliberate UX decision — they don't want to force a CSS framework on developers who have an existing preference.

**2. Vite create**

`npm create vite@latest` offers framework selection (React, Vue, Svelte, Preact, Lit, etc.) but zero CSS framework integration. The generated project has a bare `index.css` with CSS reset rules and a `App.css` with a few demo-style rules. No framework, no suggestion.

Community templates (via `--template`) exist for `react-ts`, `vue-ts`, etc., but CSS frameworks are not part of official templates. The Vite ecosystem leaves CSS entirely to the developer.

Verdict: intentionally bare. Vite is a build tool, not an opinionated project generator.

**3. Create React App (legacy, deprecated 2023)**

CRA generated a bare `src/App.css` and `src/index.css` with minimal reset styles. No CSS framework, no suggestion, no prompt. The philosophy was explicit: CRA provides the minimum, you add what you need.

CRA's decline is partly attributed to its lack of opinions on modern tooling (no TypeScript by default initially, no CSS framework). Developers found it "too bare" compared to Next.js.

Verdict: the "leave it bare" approach contributed to CRA's obsolescence. Lesson: zero design defaults is a negative signal for developer experience.

**4. Rails (`rails new`)**

Rails 7+ (2021+) ships with Hotwire (Turbo + Stimulus) as the default JavaScript approach. CSS story has evolved:
- Rails 5/6: shipped with Webpacker + Bootstrap optionally
- Rails 7: dropped Bootstrap as default, moved to import maps (no bundler), uses vanilla CSS
- Rails 7.1+ offers `--css bootstrap/tailwind/bulma/postcss/sass` flag explicitly

The `--css tailwind` flag for Rails runs a dedicated install script. This was a deliberate design decision: Rails doesn't pick for you, but it provides first-class integrations for the major choices.

Verdict: Rails moved from "Bootstrap by default" to "you choose, we make it easy." The `--css` flag pattern is notable — it externalizes the decision to the developer while automating the setup.

**5. Django startproject**

`django-admin startproject myproject` generates: `settings.py`, `urls.py`, `wsgi.py`, `asgi.py`, `manage.py`. Zero frontend files. Zero CSS. Zero HTML templates by default. Django's philosophy is "batteries included" for the backend, but the frontend is explicitly outside scope.

Django's `startapp` command generates a bare app directory. Frontend is entirely the developer's responsibility. The Django ecosystem relies on third-party packages (`django-tailwind`, `crispy-forms`) for CSS framework integration.

Verdict: the strictest "not our concern" approach. Appropriate for a backend-first framework, but not a model to follow for a fullstack scaffold tool.

**6. Angular CLI**

`ng new my-app` asks:
```
Which stylesheet format would you like to use? CSS / SCSS / Sass / Less
```
No CSS framework is offered or installed. The question is about preprocessor syntax only. Angular applications are expected to use Angular Material (separate CLI command: `ng add @angular/material`) or custom styling.

Verdict: Angular separates "stylesheet format" from "CSS framework." The `ng add` command pattern (post-scaffold additions) is interesting — it suggests a two-phase model: scaffold first, then add design.

**7. SvelteKit**

`npm create svelte@latest` offers:
```
Add Tailwind CSS? (using svelte-add) Yes / No
```
(via community integrations). The official `create-svelte` CLI does not include CSS framework questions in the core flow — it's added via `npx svelte-add@latest tailwindcss`.

SvelteKit scoped styles (`.svelte` files with `<style>` blocks) are a native feature. Each component can have component-scoped CSS without any framework. The Svelte community has normalized using either scoped styles or Tailwind — rarely both, rarely Bootstrap.

Verdict: SvelteKit acknowledges Tailwind's dominance via community tooling but keeps the core scaffold framework-agnostic.

### Analysis

**The dominant pattern is: don't pick for the developer, but make the popular choice easy.**

Out of 7 tools analyzed:
- **0** ship with a CSS framework as a non-optional default
- **3** offer Tailwind as an interactive choice (Next.js, Rails --css, SvelteKit via svelte-add)
- **2** leave CSS entirely bare with no suggestion (Vite, Django)
- **1** asks about preprocessor format only (Angular)
- **1** deprecated without ever adding framework support (CRA)

The trend line is clear: Tailwind has become the de facto "if you're going to pick one" choice among scaffolding tools. Next.js defaulting to "Yes" for Tailwind (while still asking) is the strongest signal.

**What this means for ceos-agents:**

The industry consensus validates the "offer a choice, default to Tailwind" approach. However, ceos-agents operates differently from these tools:

1. **These tools are interactive.** A developer runs `create-next-app` and answers prompts. ceos-agents can be run in `yolo` mode — fully automated with no prompts. The CSS framework decision must either be made by the spec-writer/stack-selector agent or hardcoded as a convention.

2. **The "leave it bare" approach (Vite, Django) is not suitable for ceos-agents.** The stated problem is that ceos-agents produces "visually mediocre" projects. Bare CSS is the worst outcome.

3. **The Rails `--css` flag pattern is directly applicable.** A flag like `scaffold --css tailwind` (or `--css pico` for simple projects) maps cleanly onto the existing flag architecture of the scaffold command.

4. **Angular's two-phase pattern (scaffold → add) is interesting.** In ceos-agents terms, this would mean: scaffold generates the skeleton, then a "Design" batch or step adds CSS framework configuration. This maps naturally onto the existing scaffolder batch structure.

5. **The "ask the user" approach from Next.js is valid but only for interactive mode.** In `yolo` or `yolo-checkpoint` mode, the spec-writer and stack-selector must make the decision automatically — likely based on project type signals.

**The key lesson from the survey:** The tools that leave CSS bare (Vite, CRA, Django) are either intentionally minimal tools (Vite = build tool, not app generator), deprecated (CRA), or backend-first (Django). A full-stack project scaffolder that aspires to produce non-mediocre output should not follow the "bare" approach. The tools that produce good developer experience (Next.js, Rails 7.1+ with --css) make CSS framework setup easy and offer Tailwind as the obvious default.

### Recommendation

ceos-agents should follow the **Next.js pattern**: Tailwind CSS as the default for web/frontend/fullstack projects, with the decision automated by the stack-selector agent when the project type is clearly web, or offered as a spec-writer clarifying question in interactive mode. The setup steps (4 automatable file operations) should be added to the scaffolder as a new design batch or embedded in Batch 1 (Core) for web stacks.

The "bare CSS" approach (current state) should be explicitly abandoned for web projects. It is the approach taken by deprecated or intentionally minimal tools — not by opinionated, full-stack scaffolding systems.
