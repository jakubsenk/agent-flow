# Phase 1 — Research Questions

You are conducting technical research for the ceos-agents plugin. This is a pure markdown plugin (no runtime code) that orchestrates Claude Code agents for software project scaffolding. The scaffold pipeline (spec-writer -> scaffolder -> fixer) currently has zero design/UI awareness for frontend/fullstack web projects.

## Context

Read these files to understand the current state:
- `agents/scaffolder.md` — current 5-batch structure (Core, Config, Quality, Ops, Docs)
- `agents/spec-writer.md` — specification generation (epics, stories, AC)
- `agents/stack-selector.md` — tech stack selection (no design framework awareness)
- `agents/fixer.md` — implementation agent (100-line diff limit)
- `skills/scaffold/SKILL.md` — full pipeline orchestration
- `agents/architect.md` — architecture design and task decomposition
- `CLAUDE.md` — plugin architecture overview, agent definition format, config contract

## Research Questions

Answer each question thoroughly with evidence from the codebase and your domain knowledge.

### RQ1: What CSS frameworks work best with LLM-generated code?

Evaluate the major CSS frameworks through the lens of LLM code generation reliability:

1. **Tailwind CSS** — utility-first, highly structured class names. How reliably can an LLM apply correct Tailwind classes? What's the setup complexity (PostCSS, config file, content paths)?
2. **Bootstrap** — component-based, semantic class names. Setup complexity? How well do LLMs know Bootstrap's API?
3. **Shadcn/ui** — copy-paste component library built on Tailwind + Radix. Does the copy-paste model work in an automated pipeline?
4. **CSS Modules / vanilla CSS** — zero framework, just conventions. Would structured conventions (BEM naming, CSS custom properties) be more reliable than framework classes?
5. **Pico CSS / Simple.css / classless CSS** — zero-config, semantic HTML only. No classes needed — the LLM just writes good HTML.

Rank these by: (a) LLM generation reliability, (b) setup automation complexity, (c) visual quality floor (worst-case output), (d) framework lock-in risk.

### RQ2: How do other scaffold tools handle design defaults?

Research how existing project scaffolding tools handle design/CSS out of the box:

1. **create-next-app** — what CSS approach does it default to? Does it offer choices?
2. **Vite create** — any CSS framework in the template?
3. **Create React App** (legacy) — what was the CSS story?
4. **Rails** — what CSS framework does `rails new` include?
5. **Django startproject** — any frontend story?
6. **Angular CLI** — CSS preprocessor selection?
7. **SvelteKit** — what does the default template include?

Key question: Do scaffold tools pick a framework for you, or do they leave it bare?

### RQ3: What is the minimum viable design system an LLM can reliably configure?

Given that LLMs cannot make aesthetic judgments (colors, typography, spacing scale), what is the smallest set of design decisions that produces a non-mediocre result?

1. **CSS framework selection + installation** — is this sufficient alone?
2. **Design tokens / CSS custom properties** — a theme file with colors, fonts, spacing. Can an LLM generate a coherent theme? Or should it use framework presets?
3. **Layout system** — responsive grid/flexbox patterns. Can an LLM reliably generate responsive layouts?
4. **Component patterns** — button, card, form, nav. Should the scaffold include pre-built components or just the framework?
5. **Accessibility baseline** — semantic HTML, ARIA labels, focus styles. This is rule-based, not aesthetic — LLMs should be good at this.

What's the 80/20? What gives the most visual quality improvement for the least LLM decision-making?

### RQ4: How to detect "web project" vs "CLI/API" reliably from spec content?

The design awareness must be conditional — only for web/frontend/fullstack projects. Research detection approaches:

1. **From spec-writer output:** What signals in spec/README.md or spec/architecture.md indicate a web frontend? (e.g., mentions of "UI", "pages", "dashboard", "React", "Vue", "browser")
2. **From stack-selector output:** Framework type is a strong signal (FastAPI = API-only, Next.js = web, Django + templates = web, Express = ambiguous).
3. **From user's project description:** Keywords like "web app", "dashboard", "frontend", "SPA", "landing page".
4. **Explicit flag:** `--web` or `--no-ui` flag on scaffold command.
5. **Tech stack heuristics:** presence of a frontend framework (React, Vue, Svelte, Angular) vs. pure backend (FastAPI, Express, Go gin, Flask API).

What's the most reliable detection method? Can multiple signals be combined?

### RQ5: What existing agent patterns could be reused or extended?

Look at the current agent architecture and identify reuse opportunities:

1. **Scaffolder batches** — the 5-batch pattern (Core, Config, Quality, Ops, Docs). Could a 6th batch "Design" fit naturally? What would it contain?
2. **Stack-selector** — already selects framework, testing, linting, CI. Could it also select CSS framework and component library? How would this extend the output format?
3. **Spec-writer sections** — currently generates README.md, architecture.md, verification.md, epics. Could a "Design & UX" section be added conditionally? What would spec-reviewer check?
4. **Agent Override pattern** — the `customization/{agent-name}.md` pattern. Could a shipped default override for scaffolder/fixer add design awareness without changing the core agents?
5. **Fixer context injection** — the fixer receives subtask scope + AC. Could design guidelines be injected as additional context for frontend subtasks without changing fixer.md?

### RQ6: What are the versioning and breaking change implications?

For each of the 5 options:
1. New agent → MINOR bump (new backward-compatible feature)
2. Scaffolder batch extension → PATCH bump (behavior change, no contract change)
3. Spec-writer conditional section → MINOR bump (new optional spec section)
4. Agent Override default → PATCH bump (no contract change)
5. Combination → depends on components

Which options can be delivered as PATCH vs. requiring MINOR?

## Output Format

For each question, provide:
1. **Findings** — factual research results with evidence
2. **Analysis** — interpretation and implications for the ceos-agents plugin
3. **Recommendation** — what the finding suggests about the best approach
