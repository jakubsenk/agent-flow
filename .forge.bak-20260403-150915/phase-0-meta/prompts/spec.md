# Phase 4 — Specification

You are writing a formal specification for adding design awareness to the ceos-agents scaffold pipeline. This is a pure markdown plugin — all deliverables are markdown files (agent definitions, skill orchestration, documentation).

## Context

Read:
- `.forge/phase-1-research/report.md` — research findings
- `.forge/phase-3-brainstorm/brainstorm.md` — brainstorm synthesis and recommended approach
- `CLAUDE.md` — plugin architecture, agent definition format, config contract, versioning policy

## Specification Requirements

Write an EARS-format specification with these sections:

### 1. Problem Statement
Concise restatement of the problem with evidence from the research phase.

### 2. Scope

**In scope:**
- Design awareness for web/frontend/fullstack scaffold projects
- CSS framework selection and installation
- Responsive layout scaffolding
- Accessibility baseline (semantic HTML, ARIA)
- Conditional activation (web projects only, no effect on CLI/API projects)

**Out of scope:**
- Visual design decisions (colors, typography, spacing values)
- Design tokens beyond framework defaults
- Component library installation (beyond framework's built-in components)
- Runtime CSS-in-JS solutions
- Design review agent (reviewing visual output)

### 3. Requirements (EARS format)

Write requirements as:
- `REQ-DES-NNN: When [condition], the [system] shall [behavior]`
- Use EARS patterns: ubiquitous, event-driven, state-driven, optional-feature, unwanted-behavior
- Each requirement must be testable (by the test scenarios in the TDD phase)
- Number sequentially: REQ-DES-001 through REQ-DES-NNN

Cover these areas:
1. **Detection** — how the pipeline detects web projects
2. **Stack selection** — CSS framework selection in stack-selector
3. **Specification** — Design & UX section in spec-writer output
4. **Scaffolding** — design batch in scaffolder output
5. **Implementation** — design-aware context for fixer
6. **Validation** — how spec-reviewer and scaffold-validate check design elements
7. **Backward compatibility** — non-web projects are unaffected

### 4. Architecture Design

Based on the brainstorm synthesis, specify:
- Which existing files are modified (with section-level detail)
- Which new files are created (if any)
- Data flow: how design decisions propagate through the pipeline (spec-writer -> scaffolder -> fixer)
- Detection logic: where and how "is this a web project?" is evaluated

### 5. Agent Changes

For each agent that changes, specify the exact sections to add/modify:
- **stack-selector.md** — what changes in Process and Output
- **spec-writer.md** — conditional Design & UX section specification
- **scaffolder.md** — new batch or extended batch specification
- **fixer.md** — context injection specification (if any)
- **spec-reviewer.md** — what to check for the new section
- Any new agent file — full frontmatter and section outline

### 6. Skill Changes

For `skills/scaffold/SKILL.md`:
- Where in the orchestration does design detection happen?
- How is the design flag passed to downstream agents?
- What changes in the scaffolder invocation?

### 7. Config Contract Impact

- Any new optional config sections?
- Any new required config keys? (Would trigger MAJOR version bump)
- Version bump level: PATCH / MINOR / MAJOR with justification

### 8. Acceptance Criteria

Write 5-10 testable acceptance criteria in GWT format:
- Given a web project description, When scaffold runs, Then CSS framework is installed and configured
- Given a CLI tool description, When scaffold runs, Then no design-related files are generated
- etc.

## Output

Save the specification to `.forge/phase-4-spec/spec.md`.
Save acceptance criteria separately to `.forge/phase-4-spec/formal-criteria.md`.
