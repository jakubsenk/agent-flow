# RQ-5: Design System Patterns in Scaffold — Research Findings

**Researcher:** Agent-3
**Date:** 2026-04-02
**Files examined:**
- `agents/scaffolder.md`
- `agents/spec-writer.md`
- `skills/scaffold/SKILL.md` (Step 3, Step 7)
- `agents/fixer.md`

---

## Summary Verdict

**There is zero design/UI quality instruction anywhere in the scaffold pipeline.** The entire pipeline — spec-writer, scaffolder, fixer, reviewer, and the orchestrating skill — is oriented exclusively toward functional correctness (build passes, tests pass, lint passes). When a web project is scaffolded, the UI appearance is left entirely to whatever the implementation agent (fixer) happens to produce based on general knowledge. No agent is instructed to produce good-looking UI, apply a design system, or ensure visual quality.

---

## Evidence by File

### 1. `agents/scaffolder.md` — Batches 1–5

The scaffolder generates files in five batches:

- **Batch 1 — Core:** `"Build config ... Entry point ... Basic project structure"` — no UI mention.
- **Batch 2 — Config & Data:** `".gitignore ... .env.example ... Database config"` — no UI mention.
- **Batch 3 — Quality:** `"1 smoke test ... Test infrastructure setup file ... Linter config"` — no CSS, no design system.
- **Batch 4 — Ops:** `"Dockerfile ... .dockerignore ... CI config"` — no UI mention.
- **Batch 5 — Docs:** `"README.md ... CLAUDE.md with Automation Config"` — no UI mention.

The **Expertise** field of scaffolder reads: `"Project structure conventions, build systems, CI/CD configuration, Dockerfile best practices, testing setup, linter/formatter configuration, CLAUDE.md Automation Config generation."` No mention of CSS, design systems, or UI frameworks.

The **Quality Scorecard** (Step 4b) checks: Build, Tests, Lint, CLAUDE.md, Dockerfile, CI config, Dependencies, Test infrastructure. **No design quality check exists.**

The **Constraints** section reads: `"NEVER generate business logic — only skeleton/boilerplate code"`. There is no constraint or instruction about UI quality.

**The scaffolder's entire mandate is: build passes + tests pass + lint passes. CSS and visual design are entirely absent.**

### 2. `agents/spec-writer.md`

The spec-writer generates four files: `spec/README.md`, `spec/architecture.md`, `spec/verification.md`, and `spec/epics/NN-name.md`.

The spec-writer's **Expertise** field: `"Requirements engineering, product specification, user story writing, acceptance criteria definition, tech stack evaluation, scope management, YAGNI enforcement."` No UX or visual design expertise.

The **Process** steps focus on: clarifying questions about `"Project purpose and target users"`, `"Core features (must-have vs nice-to-have)"`, `"Technical constraints (deployment, scale, compliance)"`, `"Tech stack preferences"`. No question about UI quality, design system, or visual standards.

The acceptance criteria format guidance:
- `"Given valid credentials, When POST /auth/login is called, Then it returns 200 with JWT token"` — purely behavioral/API.
- `"MUST: Response time < 200ms for all API endpoints"` — NFRs are performance/constraint-oriented.
- No example or instruction for design-related AC like "MUST: Use Tailwind CSS" or "MUST: UI follows accessible color contrast ratios".

**The spec-writer has no section, question, or instruction about visual design, UX patterns, design systems, or UI quality.**

### 3. `skills/scaffold/SKILL.md` — Step 3 and Step 7

**Step 3 (Scaffold Skeleton):**
```
Run scaffolder agent (Task tool, model: sonnet):
  Context: spec/README.md Tech Stack section + project description
  Working directory: $SCAFFOLD_TEMP
  Mode indicator: scaffold-v2
```
The only instruction passed to scaffolder is the tech stack and project description. No design-related context is provided.

**Step 7 (Feature Implementation Loop):**
The fixer receives:
```
Build context for fixer:
  - Full decomposition plan (all batches, all subtasks)
  - Summary of previously completed subtasks
  - Current subtask scope, files, acceptance_criteria
  - spec/ folder available for reference
```
No design system instructions, no CSS framework requirements, no UI quality standards are injected. The fixer is told `"Context: subtask scope + acceptance criteria + architecture design + Max build retries = {N}."` — purely functional.

Step 7 also notes: `"Hooks (Pre-fix, Post-fix, Pre-publish, Post-publish) are not executed during scaffold"`, which means even project-level hooks that might inject design instructions are explicitly skipped.

### 4. `agents/fixer.md`

The fixer's **Goal**: `"Minimal correct fix that solves the root cause. Simplest solution that doesn't break anything."`

The fixer's **Expertise**: `"Root cause analysis, defensive coding, backwards compatibility, minimal diffs."`

The **Constraints** include:
- `"NEVER change more than necessary — no drive-by refactoring"`
- `"Diff MUST NOT exceed 100 lines."`
- `"Build MUST pass before declaring success"`

No instruction about CSS quality, accessibility, design system usage, or visual appearance. The fixer is explicitly told to be minimal and surgical — its design mandate is zero-width.

---

## Conclusion

The scaffold pipeline has **no mechanism** to ensure UI quality for web projects:

1. **spec-writer** does not ask about or generate design-related acceptance criteria.
2. **scaffolder** generates skeleton files for build/test/lint only — no CSS, no UI framework setup, no design tokens.
3. **scaffold/SKILL.md Step 3** passes only tech stack + description to scaffolder — no design instructions.
4. **scaffold/SKILL.md Step 7** passes only functional scope + AC to fixer — no design instructions.
5. **fixer** is explicitly constrained to minimal, functional changes with no design awareness.
6. The **Quality Scorecard** has 8 checks — none involve UI or design quality.

A web app produced by the scaffold pipeline will have whatever HTML/CSS the fixer generates incidentally as part of functional implementation. This is likely unstyled or minimally styled, with no design system, no accessibility considerations, and no visual consistency — unless the spec explicitly includes such requirements, which the spec-writer does not prompt for.

**The pipeline is purely functional. UI quality is a blind spot.**
