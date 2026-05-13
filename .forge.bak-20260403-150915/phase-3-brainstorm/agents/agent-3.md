# Agent 3 — The Skeptic

## Role

Challenge every assumption in the Phase 1 research findings. Identify hidden risks, unexamined failure modes, and overconfident conclusions. Propose concrete mitigations for each identified risk.

---

## Risk 1: "Tailwind is the best choice" ignores server-rendered stacks without JS build pipelines

### The Problem

The research (RQ1) declares Tailwind the winner based on LLM reliability and training data prevalence. But Tailwind requires PostCSS, which requires Node.js. The research silently assumes every web project has a JavaScript build pipeline.

Consider these stacks that the stack-selector can legitimately recommend:

- **Django + templates** (Python, no Node.js in the project)
- **Rails + ERB views** (Ruby, may or may not have Node.js)
- **Flask + Jinja2** (Python, no bundler)
- **Go + html/template** (Go, definitely no Node.js)
- **PHP + Blade** (Laravel, may have Vite but historically no bundler)

For these stacks, "install Tailwind" means one of:
1. **Add Node.js as a dev dependency to a non-JS project** — fundamentally changes the project's dependency story. A Python developer now needs `nvm`, `node`, `npm` in their environment. The Dockerfile needs a multi-runtime build stage. CI config needs Node.js setup.
2. **Use the Tailwind standalone CLI** — a single binary, no Node.js needed. But this is a different installation path, different configuration, different integration pattern. The research does not mention it.
3. **Use the Tailwind CDN** — `<script src="https://cdn.tailwindcss.com">`. Works instantly, zero config. But the CDN build is explicitly "for development only" per Tailwind docs. No purging, no custom config, increased page weight. Production-inappropriate.

The research's "dual strategy" (RQ1: "Tailwind for interactive web apps, classless CSS for simple server-rendered pages") partially addresses this, but the boundary is wrong. Django+templates is "server-rendered" but can host complex interactive UIs. The binary web/non-web distinction masks a spectrum.

### Severity: HIGH

If the scaffolder installs Tailwind for a Django project, it has just added Node.js as a dependency to a Python project. The smoke test might pass, but the developer's first reaction will be "why does my Python project need npm?"

### Mitigation

**Three-tier CSS strategy based on stack, not project type:**

| Stack Category | CSS Strategy | Rationale |
|---------------|-------------|-----------|
| JS-native (React, Vue, Svelte, Next.js, Nuxt, SvelteKit, Angular) | Tailwind via PostCSS | Node.js already present; standard tooling |
| Non-JS with optional JS tooling (Rails, Laravel, Django if Vite configured) | Tailwind via standalone CLI or framework-bundled Tailwind | Avoids Node.js dependency; framework-specific integration |
| Non-JS without JS tooling (Flask, Go, plain Django, plain PHP) | Classless CSS (Pico CSS via CDN or vendored) | Zero build pipeline; semantic HTML only |

The stack-selector already knows the framework. The decision tree is deterministic — no LLM aesthetic judgment required.

Add a decision table to the scaffolder's Batch 6 instructions so the LLM does not have to figure out which tier applies. Make it a lookup, not a judgment call.

---

## Risk 2: DaisyUI theme selection is complexity without value

### The Problem

The research (RQ3) proposes that the LLM picks a DaisyUI theme "by project domain": enterprise dashboard gets `corporate`, developer tool gets `dracula`, consumer app gets `light`. This sounds reasonable in a slide deck. In practice:

1. **The domain-to-theme mapping is arbitrary.** Why does "enterprise dashboard" map to `corporate`? Because someone decided it sounds right. There is no empirical basis. The LLM will pattern-match on vibes, not design principles.

2. **Theme selection is irreversible at scaffold time.** Once the scaffolder picks `dracula` and generates components with dark-background assumptions, switching to `light` later requires re-examining every component. Color contrast assumptions are baked in.

3. **DaisyUI adds a dependency.** It is an npm package (`daisyui`) that must be installed, configured in `tailwind.config.js`, and kept updated. For a "minimal scaffold," this is another moving part. DaisyUI versions can break with Tailwind major versions.

4. **Most projects will get `light`.** Unless the project description explicitly says "dark theme" or "developer tool," the LLM will default to the safest option. If 90% of projects get `light`, the entire theme selection mechanism adds complexity for negligible differentiation.

5. **DaisyUI only works with Tailwind.** For the non-JS stacks in Risk 1 that get classless CSS, DaisyUI is irrelevant. So the theme selection logic is conditional on another conditional — this is branching complexity.

### Severity: MEDIUM

Not a breaking problem, but a feature that adds maintenance cost (DaisyUI version tracking, Tailwind compatibility, conditional logic) while delivering marginal value ("your scaffold is slightly less generic-looking").

### Mitigation

**Drop DaisyUI theme selection entirely from the initial implementation.** Instead:

1. **Tier 2 = Tailwind + sensible defaults only.** Configure `tailwind.config.js` with a minimal `theme.extend` block: one primary color, one neutral palette, reasonable typography defaults. This is 10 lines of config, not a third-party dependency.

2. **Ship a single default color palette** that works for any project type. Neutral blue-gray primary, standard scale. Not exciting, but professional.

3. **If DaisyUI is desired later**, it can be added via Agent Override (`customization/scaffolder.md` with "include DaisyUI and select theme based on..."). This keeps the core pipeline simple and pushes opinionated choices to the project level.

4. **Document the DaisyUI option** in `examples/agent-overrides/ui-design/scaffolder.md` as a copy-and-use pattern for teams that want it.

This follows the plugin's existing philosophy: the plugin is generic, project-specific choices live in the consuming project's configuration.

---

## Risk 3: Stack-selector `project_type` field changes the output contract

### The Problem

The research (RQ4, RQ6) proposes adding `project_type: web | api | cli | library` to stack-selector output. The research's own RQ6 analysis identified this risk but then waved it away by saying "treat as MINOR by making the field optional."

But "optional" is not the same as "safe." Consider:

1. **The scaffolder parses stack-selector output** (scaffolder.md step 1: "read the stack selection from the stack-selector agent output"). Today, the output has 4 fields: Stack summary, Rationale, Project structure, Key dependencies. Adding `project_type` and `CSS framework` means the scaffolder now expects up to 6 fields. Even if the scaffolder "gracefully degrades" when the field is missing, every future scaffolder invocation in `--no-implement` mode will parse this new format.

2. **Agent Overrides can parse stack-selector output.** Per CLAUDE.md versioning policy: "Breaking change in agent output format contract (new/modified structured output sections that Agent Overrides or external tooling may parse)." If any consuming project has a custom agent that reads stack-selector output, the new field appears unexpectedly. The research classifies this as MINOR; the versioning policy says it could be MAJOR.

3. **`--no-implement` mode is the critical path.** In this mode (L1-L6 in scaffold SKILL.md), stack-selector output goes directly to scaffolder with no spec intermediary. The scaffolder must parse whatever stack-selector emits. If the field is present sometimes (for web projects) and absent sometimes (for CLI projects), the scaffolder must handle both cases. This is conditional parsing logic in a markdown agent definition — fragile.

4. **The `project_type` field creates a classification bottleneck.** What is a "Next.js API routes only" project? Web or API? What about "React admin panel for a Go API"? The LLM must classify before it can proceed, and misclassification silently produces the wrong CSS strategy.

### Severity: HIGH

This is the riskiest single change in the proposal. It touches a cross-agent contract that two agents depend on, introduces conditional output formatting, and the versioning impact may be underestimated.

### Mitigation

**Do not add `project_type` to stack-selector output.** Instead:

1. **Derive the CSS decision inside the scaffolder**, not the stack-selector. The scaffolder already has the full tech stack (framework name, dependencies). It can apply a deterministic lookup:
   - Framework in [React, Vue, Svelte, Angular, Next.js, Nuxt, SvelteKit] → Tailwind via PostCSS
   - Framework in [Django, Rails, Laravel] + has_js_tooling → Tailwind standalone
   - Framework in [Flask, Gin, plain Django] → Classless CSS
   - Framework in [Click, Typer, Commander, Cobra] → No CSS
   - No framework match → No CSS (conservative default)

2. **This keeps the stack-selector output format unchanged.** Zero contract change. Zero version risk. The CSS decision is an implementation detail of the scaffolder, not an architectural classification in the stack-selector.

3. **For scaffold v2 mode** (where spec/README.md drives everything), the decision is even simpler: the spec-writer's Tech Stack section already names the framework. The scaffolder reads it and applies the same lookup.

4. **If `project_type` is genuinely needed later** (for non-CSS reasons), add it as a separate change with proper MAJOR version consideration. Do not smuggle it in as part of a CSS feature.

---

## Risk 4: "No new agent needed" may be false economy

### The Problem

The research concludes "no new agent" — distribute design work across spec-writer (conditional spec/design.md), stack-selector (project_type field), and scaffolder (Batch 6). This sounds efficient. But consider the scaffolder's current state:

1. **Scaffolder already has 5 batches, 132 lines, and 8 constraints.** Adding Batch 6 (CSS framework config, design tokens, global styles) plus the CSS strategy decision logic (which framework? which tier? DaisyUI theme?) could push the agent definition past its effective prompt length.

2. **The scaffolder's expertise line** (line 8) says: "Project structure conventions, build systems, CI/CD configuration, Dockerfile best practices, testing setup, linter/formatter configuration, CLAUDE.md Automation Config generation." That is already 7 domains of expertise. Adding "CSS framework selection, design system configuration, accessibility defaults" makes it 10. At what point does a generalist agent become worse at everything because it is trying to be good at too many things?

3. **Testing becomes harder.** A single scaffolder agent with design-conditional behavior means every test scenario needs both web and non-web variants. The test matrix doubles.

4. **The spec-writer change is also concerning.** Adding conditional spec/design.md generation means spec-writer must know about CSS frameworks, design tokens, color theory (even at a template level), and accessibility requirements. The spec-writer is a "Senior Product Architect" — not a designer. Its expertise line says "Requirements engineering, product specification, user story writing." Adding design system specification to its responsibilities is scope creep.

### Severity: MEDIUM

The risk is not immediate failure but gradual quality degradation. Each agent does its primary job slightly worse because it is also doing design work. The effect is invisible in testing but visible in production output quality.

### Mitigation

**Acknowledge the agent boundary tension but do NOT create a new agent yet.** Instead:

1. **Keep the scaffolder's Batch 6 minimal.** It should do exactly three things:
   - Install the CSS framework (based on the deterministic lookup from Risk 3 mitigation)
   - Create a minimal config file (tailwind.config.js or a `<link>` tag)
   - Add a `src/styles/globals.css` with framework imports

   That is 3 files, not a design system. No design tokens. No component stubs. No theme selection. The scaffolder stays a scaffolder, not a designer.

2. **Do NOT add spec/design.md to spec-writer.** The spec-writer should not need to know about CSS. Instead, if design requirements are needed, they belong in the relevant epic's acceptance criteria: "MUST: Use responsive layout with mobile breakpoint at 768px." This is already how spec-writer works — acceptance criteria capture requirements, including visual ones.

3. **Set a trigger for reconsidering a new agent.** If in the future the scaffolder's Batch 6 grows beyond 15 lines of instruction, or if spec/design.md becomes a requirement, that is the signal that a `ui-designer` agent is justified. Document this threshold in the decision record.

4. **Use Agent Overrides for project-specific design depth.** Teams that want design tokens, component libraries, and theme selection can add `customization/scaffolder.md` with those instructions. The core plugin stays lean.

---

## Risk 5: "MINOR version" may be wrong

### The Problem

The research (RQ6) concludes the combined approach is MINOR: stack-selector adds optional fields, spec-writer adds conditional file, scaffolder adds conditional batch. Each individual change is arguably MINOR or PATCH. But the combination creates a problem:

1. **Aggregate contract surface change.** Three agents change their output or behavior simultaneously. Even if each change is individually backward-compatible, the combined change represents a significant shift in how the scaffold pipeline behaves for web projects. Users upgrading from v6.1.x to v6.2.0 will see materially different scaffold output for the same input.

2. **The stack-selector output change (if kept) is the borderline case.** The CLAUDE.md versioning policy says MAJOR for "new/modified structured output sections that Agent Overrides or external tooling may parse." The research argues the new fields are "optional/advisory." But the scaffolder MUST parse them for Batch 6 to work. That is not advisory — that is a new required field in the output contract that one specific consumer depends on.

3. **Backward compatibility testing is unclear.** If a consuming project upgrades the plugin but has not updated their Agent Overrides or custom agents, will everything still work? The research does not address this. If the scaffolder now conditionally generates CSS files that were not there before, any post-scaffold validation scripts in consuming projects may be surprised.

### Severity: MEDIUM-HIGH

Getting the version wrong erodes trust. A user who upgrades a MINOR version and finds their scaffold output changed significantly (new files, new dependencies, new build requirements) will feel the version was misleading.

### Mitigation

1. **If Risk 3 mitigation is adopted (no stack-selector output change)**, the version concern drops significantly. The only changes are:
   - Scaffolder generates additional files for web projects (behavioral change, no contract change) → PATCH
   - No new config keys → no MINOR trigger from config
   - No new agents → no MINOR trigger from agents

   This could legitimately be a PATCH version. The scaffolder already generates different files based on tech stack (Python vs Go vs Node.js). Adding CSS files for web stacks is the same category of conditional generation.

2. **If spec/design.md is added to spec-writer**, that is a new file in the spec/ contract. Even though it is conditional, downstream agents (spec-reviewer --verify, fixer) will now encounter it. This pushes toward MINOR.

3. **The safest version strategy:**
   - If implementing only scaffolder Batch 6 (minimal, no spec/design.md, no stack-selector changes): **PATCH**
   - If implementing scaffolder Batch 6 + spec/design.md: **MINOR**
   - If implementing stack-selector output changes: **MINOR at minimum, consider MAJOR**

4. **Add a migration note to CHANGELOG.md** regardless of version level. Describe what changed for web projects and confirm that non-web projects are completely unaffected.

---

## Summary of Mitigations

| Risk | Recommendation | Effect |
|------|---------------|--------|
| R1: Tailwind assumes JS build pipeline | Three-tier CSS strategy based on actual stack, not binary web/non-web | Prevents Node.js pollution of Python/Go/Ruby projects |
| R2: DaisyUI theme selection adds complexity for marginal value | Drop DaisyUI from core; ship as Agent Override example | Keeps core pipeline simple; pushes opinionated choice to project level |
| R3: Stack-selector output contract change | Move CSS decision to scaffolder via deterministic lookup; leave stack-selector unchanged | Zero contract risk; PATCH-safe |
| R4: Scaffolder scope creep | Keep Batch 6 to 3 files max; skip spec/design.md; set threshold for future agent extraction | Prevents quality degradation; documents the trigger for revisiting |
| R5: Version underestimated | PATCH if only scaffolder changes; MINOR if spec-writer changes; avoid stack-selector output changes entirely | Honest versioning; no surprises for consumers |

## Overarching Concern

The research finds the right problem (scaffold output looks mediocre) but may be over-engineering the solution. The minimum viable change is:

> The scaffolder checks if the tech stack includes a web framework. If yes, it installs Tailwind (or Pico for non-JS stacks) and creates a global stylesheet. That is Batch 6. Three files. Done.

Everything beyond that — design tokens, DaisyUI themes, spec/design.md, stack-selector project_type, component stubs — is Tier 3 complexity being dressed up as Tier 2. The research itself says Tier 3 is "risky, LLM can't make aesthetic choices." The mitigations above keep the implementation firmly at Tier 1.5 — framework installed and configured, nothing more — and defer Tier 2 to Agent Overrides where project teams can make those choices with context the LLM lacks.
