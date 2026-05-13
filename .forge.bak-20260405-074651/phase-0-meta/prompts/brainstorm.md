# Phase 3 — Brainstorm

You are a **Judge** mediating a brainstorming session between three expert personas. Your job is to synthesize their perspectives into a single coherent recommendation.

## Task Context

We are adding two features to `agents/scaffolder.md` in the ceos-agents plugin (v6.2.0 → v6.3.0):

1. **E2E Test Generation** — New conditional batch for Playwright e2e test suite in web projects
2. **Application Documentation for Agents** — New batch for `docs/ARCHITECTURE.md` + `Module Docs | Path` population

## Codebase Context

- **Repository:** `ceos-agents` — pure markdown Claude Code plugin, no build system, no runtime code
- **Primary file:** `agents/scaffolder.md` — agent definition with 5 process steps, 6 batches, 9 scorecard items, constraints section
- **Secondary file:** `skills/scaffold/SKILL.md` — pipeline orchestrator (400+ lines)
- **Pattern:** Batch 6 (Design) is the model for conditional batches — it detects web projects and skips for CLI/API/library projects
- **Scorecard:** 9 items currently, each with Check/Status/Notes columns
- **File count ceiling:** 10-15 simple, up to 20 with DB+CI+Docker, up to 23 for web with design system
- **Module Docs:** Optional config section with `Path` key, consumed by `code-analyst` and `architect` agents

## Personas

### Persona 1: Plugin Architecture Expert
You have deep experience with the ceos-agents plugin architecture. You understand how agents, skills, and core contracts interact. Focus on:
- How the new batches fit into the existing batch numbering system
- Whether the ordering is correct (dependencies between batches)
- Whether the conditional logic (web detection) is consistent with Batch 6
- Whether any constraints need updating

### Persona 2: Developer Experience (DX) Designer
You focus on the experience of developers who use scaffold-generated projects. Focus on:
- What should `docs/ARCHITECTURE.md` contain to be maximally useful for downstream agents?
- What should the e2e smoke test actually test? (page loads? navigates? has title?)
- Should docs be opinionated (prescribe patterns) or descriptive (document what was generated)?
- How does the generated documentation stay useful as the project evolves?

### Persona 3: Quality Assurance Engineer
You focus on testing, validation, and edge cases. Focus on:
- What happens when Playwright is NOT in dependencies but E2E Test config section exists?
- What happens for non-web projects — is the skip clean?
- Should docs/ARCHITECTURE.md be validated (e.g., does it exist, is it non-empty)?
- What structural tests can verify these features without running a scaffold?

## Process

1. Each persona provides their analysis independently (300-500 words each)
2. Judge identifies points of agreement, disagreement, and synthesis opportunities
3. Judge produces a unified recommendation with:
   - Batch structure decision (numbering, ordering, conditional logic)
   - Content specification for each new batch
   - Scorecard additions
   - Constraint updates
   - Test plan
   - Risk assessment

## Output Format

```markdown
## Persona 1: Plugin Architecture Expert
[Analysis]

## Persona 2: DX Designer
[Analysis]

## Persona 3: QA Engineer
[Analysis]

## Judge Synthesis
### Points of Agreement
### Points of Disagreement
### Unified Recommendation
[Structured recommendation covering all areas]

### Risk Assessment
| Risk | Likelihood | Impact | Mitigation |
```
