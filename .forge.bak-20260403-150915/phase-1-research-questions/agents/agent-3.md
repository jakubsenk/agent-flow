# Research: RQ5 + RQ6 — Agent Patterns and Versioning Implications

## RQ5: What existing agent patterns could be reused or extended?

---

### 1. `agents/scaffolder.md` — Batch structure and Design batch feasibility

**File:** `agents/scaffolder.md`

**Current batch structure (lines 27–55):**

| Batch | Name | Files |
|-------|------|-------|
| Batch 1 | Core | Build config, entry point, src/ structure |
| Batch 2 | Config & Data | .gitignore, .env.example, database config |
| Batch 3 | Quality | Smoke test, test infra, linter config |
| Batch 4 | Ops | Dockerfile, .dockerignore, CI config |
| Batch 5 | Docs | README.md, CLAUDE.md with Automation Config |

**Key observations:**
- Batches are purely sequential — each batch generates a named set of files into `$SCAFFOLD_TEMP`. No inter-batch dependencies beyond "read the tech stack" from step 1.
- The batch naming follows a logical progression: skeleton → config → quality → ops → docs. A 6th batch fits naturally after Docs.
- The scaffolder reads its input from `spec/README.md` Tech Stack section (scaffold v2 mode) or stack-selector output (--no-implement mode). A design batch would need an additional design system input source.

**What a Batch 6 — Design would look like:**

```markdown
**Batch 6 — Design:**
- CSS framework config (tailwind.config.ts / .storybook/ if Storybook selected)
- Design tokens file (src/styles/tokens.css or src/theme/tokens.ts)
- Component boilerplate (src/components/ui/ — Button, Input, Card stubs)
- Storybook stories (if Storybook in stack) — 1 story per component
```

**Feasibility:** Adding Batch 6 is purely additive — no existing batch or constraint is modified. The constraint at line 128 ("Target file count: 10-15 files for simple stacks, up to 20 for stacks with database + CI + Docker") would need updating to accommodate UI projects, e.g., "up to 25 for stacks with UI components".

The scaffolder step 5 output (Scaffold Report) lists files with purpose — a design batch would add entries to that list. This is not a structured output field that agent overrides or external tooling parses; it's prose.

---

### 2. `agents/stack-selector.md` — Output structure and CSS framework extension

**File:** `agents/stack-selector.md`

**Current output format (lines 43–54):**

```markdown
## Stack Selection
- **Stack summary:** {one-line}
- **Rationale:** {why}
- **Project structure:** {directory layout}
- **Key dependencies:** | Package | Version | Purpose |
```

**What CSS framework extension would look like:**

```markdown
## Stack Selection
- **Stack summary:** {one-line}
- **Rationale:** {why}
- **UI framework:** {CSS framework — e.g., Tailwind CSS 3.4 / shadcn/ui} (new field)
- **Component library:** {e.g., Radix UI / headlessui} (new field, if applicable)
- **Project structure:** {directory layout}
- **Key dependencies:** | Package | Version | Purpose |
```

**Key observations:**
- stack-selector is a read-only agent (line 57: "NEVER modify code — read-only analysis and recommendation"). It produces a structured markdown output that scaffolder consumes.
- The stack-selector output format is what the scaffolder reads at step 1: "read the stack selection from the stack-selector agent output." Adding new fields to Stack Selection changes the output contract that scaffolder parses.
- Current expertise (line 11): "Programming language ecosystems, web frameworks, database selection, CI/CD platforms, testing frameworks, linter/formatter tools, containerization..." — CSS frameworks are not listed.
- The stack-selector only triggers questions about: language/framework, database, deployment target, CI/CD, team size (lines 26–31). A CSS framework question would need to be added to the clarifying questions list.
- The "NEVER ask more than 3 clarifying questions" constraint (line 58) limits how much new questioning surface can be added.

**Feasibility:** Conditionally adding CSS framework fields to the output is possible — the fields would only appear for web frontend projects. But any scaffolder logic that parses "UI framework" from stack-selector output constitutes a new output contract field.

---

### 3. `agents/spec-writer.md` — Section structure and Design & UX section

**File:** `agents/spec-writer.md`

**Current specification structure (lines 38–46):**

| File | Contents |
|------|----------|
| `spec/README.md` | Vision, goals, success criteria, users, tech stack, out of scope |
| `spec/architecture.md` | High-level overview, data flow, data model, API, NFR, constraints |
| `spec/verification.md` | Test strategy, definition of done, risks, assumptions |
| `spec/epics/NN-name.md` | User stories with acceptance criteria |

**Key observations:**
- Step 4 (line 43) distinguishes between REQUIRED and IF APPLICABLE sections. New sections would naturally fit the IF APPLICABLE pattern.
- The spec files are written to `spec/` directory and are "the single source of truth for all downstream agents" (CLAUDE.md architecture note). A new `spec/design.md` file would extend the source-of-truth set.
- Spec-reviewer's `--verify` mode (used in Step 7b of scaffold SKILL.md) checks "implementation against spec." If spec/design.md exists, spec-reviewer should check UI component presence and CSS framework configuration.

**What a conditional Design & UX section would look like:**

New file: `spec/design.md` (generated only for web frontend projects):
```markdown
## Design & UX
- Design system: {CSS framework + component library}
- Color tokens: {primary, secondary, neutral, semantic}
- Typography: {font stack, scale}
- Component inventory: {list of components required by epics}
- Accessibility requirements: {WCAG level}
- Responsive breakpoints: {mobile/tablet/desktop thresholds}
```

**What spec-reviewer would check in `--verify` mode:**
- Does `tailwind.config.ts` (or equivalent) exist and match the design system declared in spec/design.md?
- Do component files in `src/components/` cover the component inventory?
- Are accessibility requirements addressed in tests?

**Feasibility:** Adding a conditional `spec/design.md` output is backward-compatible if treated as IF APPLICABLE — specs for non-UI projects never produce this file. The spec-writer output report (step 8) would list it as an additional generated file.

---

### 4. `agents/fixer.md` — Context reception and design guideline injection

**File:** `agents/fixer.md`

**How fixer receives context (lines 19–28):**
1. Step 1: reads triage analysis and impact report
2. Step 2: reads project conventions from CLAUDE.md (coding style, patterns, naming conventions)
3. Steps 4-5: reads affected files, then implements fix

**How context is passed from skills:**

From `skills/scaffold/SKILL.md` lines 654–655:
```
Context: subtask scope + acceptance criteria + architecture design + `Max build retries = {Build retries from CLAUDE.md, default 3}.`
```

From `skills/fix-ticket/SKILL.md` (via `core/fixer-reviewer-loop.md` line 11):
```
Context: Bug report or spec + AC + code-analyst output
```

**Design guideline injection points:**

The fixer receives context as a free-text block passed via the Task tool. Design guidelines can be injected at two points:

1. **Via Agent Override** (existing mechanism): A `customization/fixer.md` override file is appended as `## Project-Specific Instructions` to every fixer invocation (core/fixer-reviewer-loop.md line 19). This already works without any code change.

2. **Via skill context string**: Skills construct the fixer's context string before Task dispatch. Adding design context at this point requires modifying the scaffold skill's Step 7 context builder (lines 648–655) to include `+ spec/design.md contents` when the file exists.

**The fixer's constraint at line 86:** "NEVER change more than necessary — no drive-by refactoring." Design guidelines must be phrased as constraints on implementation style, not as requests for unrelated changes.

---

### 5. `skills/scaffold/SKILL.md` — Context passing in Steps 3 and 7

**File:** `skills/scaffold/SKILL.md`

**Step 3 context (lines 447–450):**
```
Run scaffolder agent (Task tool, model: sonnet):
  Context: spec/README.md Tech Stack section + project description
  Working directory: $SCAFFOLD_TEMP
  Mode indicator: scaffold-v2 (so scaffolder generates E2E Test config + Decomposition defaults)
```

The context is a structured string. Injecting design context here means adding `+ spec/design.md contents` when it exists. This is the natural injection point for the scaffolder to know what CSS framework to use in Batch 6.

**Step 7 context builder (lines 648–655):**
```
Build context for fixer:
  - Full decomposition plan (all batches, all subtasks)
  - Summary of previously completed subtasks (what changed, diff summary)
  - Current subtask scope, files, acceptance_criteria
  - spec/ folder available for reference
```

The "spec/ folder available for reference" bullet means the fixer already has access to spec/ — including a `spec/design.md` if it exists. No structural change is needed for the fixer to consume design guidelines; they just need to be in spec/design.md.

**Design-specific context injection options:**

| Injection point | What changes | Required modification |
|----------------|--------------|----------------------|
| Step 3 (scaffolder context) | Scaffolder reads design.md for Batch 6 | Add `+ spec/design.md (if exists)` to context string |
| Step 7 (fixer context) | Fixer reads design system constraints | No change needed — "spec/ folder available for reference" already covers it |
| Agent Override for fixer | All fixer invocations get design instructions | No skill change — override file in consuming project |

---

### 6. Agent Override Pattern — Shipped default override feasibility

**Current mechanism** (`core/agent-override-injector.md`):

The override injector reads from `{override_path}/{agent-name}.md` in the **consuming project's directory** (relative to CWD). Override path defaults to `customization/` (configurable via `Agent Overrides → Path` in Automation Config).

**What "shipped default override" means:**

Option A: Ship `examples/agent-overrides/ui-design/fixer.md` and `examples/agent-overrides/ui-design/scaffolder.md` in the plugin repo, with instructions to copy them into the consuming project's customization/ directory.

Option B: Modify the override injector to check a second path (plugin-bundled path) as fallback — e.g., `{plugin_path}/defaults/{agent-name}.md` before the project-level override. This would require changing `core/agent-override-injector.md`.

**Feasibility:**
- Option A (examples only): Zero code change. Pattern already established in `examples/agent-overrides/codegraph/` (README.md instructs users to copy files). No version bump required — it's documentation/examples only.
- Option B (fallback path in injector): Requires modifying `core/agent-override-injector.md` input contract and process. Changes agent context loading behavior — this is a new optional capability, not breaking.

The examples/agent-overrides/codegraph/ pattern demonstrates that shipping example overrides is the established approach. Those files have a README.md explaining the copy-then-use workflow.

---

## RQ6: Versioning and Breaking Change Implications

**CLAUDE.md Versioning Policy** (lines 200–208):

| Level | Trigger |
|-------|---------|
| MAJOR (X.0.0) | Breaking change in Automation Config contract (new required key, renamed section) OR breaking change in agent output format contract (new/modified structured output sections that Agent Overrides or external tooling may parse) |
| MINOR (X.Y.0) | New backward-compatible feature — new optional key, new command/agent |
| PATCH (X.Y.Z) | Behavior fix without contract change |

Key rule from CLAUDE.md line 208: "Adding a **required** key to Automation Config = MAJOR. Adding an **optional** section = MINOR."

---

### Analysis per approach:

**New agent (ui-designer)**

- Version impact: **MINOR**
- Reasoning: Adding a new agent is explicitly listed as a MINOR trigger ("new command/agent"). The new agent is a new backward-compatible feature. No existing config keys change. No existing agent output format changes.
- The CLAUDE.md agent count would go from 19 to 20 — update docs only.

---

**Scaffolder batch extension (adding Batch 6 — Design)**

- Version impact: **PATCH**
- Reasoning: The scaffolder's batch structure is internal implementation logic, not a structured output contract. The Scaffold Report output (lines 95–117 of scaffolder.md) lists generated files in prose form — this is informational, not machine-parsed by agent overrides or external tooling. Adding a conditional Batch 6 that only runs for frontend projects changes behavior without changing the output format contract or Automation Config keys.
- Caveat: If adding Batch 6 requires a new optional Automation Config key (e.g., `Design System → Framework`), that key addition = MINOR.

---

**Spec-writer conditional section (adding spec/design.md)**

- Version impact: **PATCH** (conditional section) or **MINOR** (new optional config key)
- Reasoning: The spec-writer output report (step 8, lines 65–76) lists generated files — adding `spec/design.md` to the file list is an additive change to prose output. The spec/ folder structure is not a machine-parsed contract; it is a source of truth for downstream agents that read it by convention.
- However: if spec-reviewer's `--verify` mode is extended to check design compliance, and spec-reviewer is invoked by the scaffold skill (Step 7b), the verification verdict logic changes. This is a behavior change in an existing pipeline stage — still PATCH if no output format contract changes.
- If a new optional Automation Config key like `Design → Enable: true/false` is added to control the conditional: MINOR.

---

**Stack-selector extension (new output field)**

- Version impact: **MAJOR** (if scaffolder must parse the new field) or **MINOR** (if field is advisory only)
- Reasoning: The versioning policy's MAJOR trigger includes "new/modified structured output sections that Agent Overrides or external tooling may parse." The stack-selector's `## Stack Selection` output block is parsed by the scaffolder agent (step 1 of scaffolder.md). Adding a new field (e.g., `**UI framework:**`) that the scaffolder must read to generate Batch 6 constitutes a change to the agent output format contract.
- If the field is **advisory only** (scaffolder reads it if present, ignores if absent) and existing scaffolder behavior is unchanged for non-UI stacks: MINOR.
- If the field is **required** for frontend scaffolding to work correctly: MAJOR (breaks existing stack-selector outputs that don't include it).
- Recommended: treat as MINOR by making the field optional and the scaffolder gracefully degrade.

---

**Agent Override default (shipping a default override file)**

- Version impact: **MINOR** (new optional capability) or **no bump** (documentation/examples only)
- Reasoning: Shipping `examples/agent-overrides/ui-design/fixer.md` as a copy-and-use example (Option A) = no version bump needed, same as the existing codegraph examples.
- Adding a fallback path lookup to `core/agent-override-injector.md` (Option B) = MINOR — new backward-compatible feature that adds optional behavior without changing the existing contract.
- The override mechanism itself is already established infrastructure (CLAUDE.md Agent Overrides section, core/agent-override-injector.md). No Automation Config contract change is involved.

---

### Summary Table

| Approach | Version Impact | Condition | Rationale |
|----------|---------------|-----------|-----------|
| New agent (ui-designer) | MINOR | Always | "New command/agent" is a listed MINOR trigger |
| Scaffolder Batch 6 | PATCH | No new config key | Internal batch logic, prose output not machine-parsed |
| Scaffolder Batch 6 | MINOR | If new optional Automation Config key added | New optional key = MINOR per policy |
| Spec-writer design section | PATCH | Conditional, no new config key | Additive file in spec/, not a format contract change |
| Spec-writer design section | MINOR | If new optional config key added | Same rule |
| Stack-selector new output field | MINOR | Field is optional/advisory, scaffolder degrades gracefully | New backward-compatible output field |
| Stack-selector new output field | MAJOR | Field required for correct behavior, breaks old outputs | "Breaking change in agent output format contract" |
| Agent Override default (examples) | No bump | Copy-and-use examples only | Pure documentation, same as codegraph examples |
| Agent Override default (injector fallback) | MINOR | New fallback path in injector | New backward-compatible capability |

---

## Key File References

| File | Lines | Relevance |
|------|-------|-----------|
| `agents/scaffolder.md` | 27–55 | Five batch definitions; Batch 6 insertion point |
| `agents/scaffolder.md` | 93–117 | Scaffold Report output format (prose, not machine-parsed) |
| `agents/scaffolder.md` | 128 | File count constraint that would need updating |
| `agents/stack-selector.md` | 43–54 | Stack Selection output format (parsed by scaffolder step 1) |
| `agents/stack-selector.md` | 26–31 | Clarifying question categories (CSS framework absent) |
| `agents/stack-selector.md` | 57–58 | "NEVER modify code" + "NEVER ask more than 3 questions" constraints |
| `agents/spec-writer.md` | 38–46 | Spec folder structure (spec/README.md, architecture.md, verification.md, epics/) |
| `agents/spec-writer.md` | 43 | REQUIRED vs IF APPLICABLE section distinction |
| `agents/fixer.md` | 19–28 | Context reception: reads triage analysis, CLAUDE.md, affected files |
| `agents/fixer.md` | 86 | "NEVER change more than necessary" constraint |
| `skills/scaffold/SKILL.md` | 447–450 | Step 3: scaffolder context = spec/README.md Tech Stack + project description |
| `skills/scaffold/SKILL.md` | 648–655 | Step 7: fixer context builder — "spec/ folder available for reference" |
| `skills/scaffold/SKILL.md` | 870–873 | Agent Overrides rule in scaffold |
| `core/agent-override-injector.md` | 1–35 | Override injector: reads from consuming project CWD, not plugin |
| `core/fixer-reviewer-loop.md` | 19 | Override injection for fixer: `{agent_override_path}/fixer.md` |
| `examples/agent-overrides/codegraph/` | — | Established pattern for shipped example overrides (copy-and-use) |
| `CLAUDE.md` | 159–165 | Agent Overrides config contract |
| `CLAUDE.md` | 200–208 | Full versioning policy |
