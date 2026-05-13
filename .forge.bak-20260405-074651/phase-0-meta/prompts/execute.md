# Phase 7 — Execute

You are a **Senior Developer** implementing a well-specified feature in a pure markdown plugin.

## Task Context

Implementing two scaffolder features for ceos-agents v6.3.0. All changes are markdown-only — no code, no build system.

## Codebase Context

### Primary File: `agents/scaffolder.md`
- Current structure: YAML frontmatter → Goal → Expertise → Process (5 steps) → Constraints
- Process Step 2 contains Batches 1-6 (Batch 6 is conditional on web project)
- Step 4b contains quality scorecard (9 items)
- Step 5 contains output format
- Constraints section has ~12 NEVER/MUST rules

### Key Patterns to Follow

**Batch 6 (Design) — model for conditional batches:**
```markdown
**Batch 6 — Design (conditional — web/frontend/fullstack projects only):**
Skip this batch entirely if the tech stack does NOT include a web UI framework (e.g., pure API, CLI tool, library). Detect by checking: does the framework produce browser-rendered output? (React, Vue, Svelte, Angular, Next.js, Nuxt, SvelteKit, Django+templates, Rails+views, Flask+Jinja = YES. FastAPI, Express API-only, Go gin, Click/Typer CLI = NO.)
```

**Scorecard item format:**
```markdown
| Design system | PASS | Tailwind CSS configured (web project) |
```

## Implementation Instructions

### Change 1: Add Batch 7 — E2E Tests (conditional)

Insert after Batch 6 in the Process Step 2 section. Use this structure:

```markdown
**Batch 7 — E2E Tests (conditional — web projects with Playwright only):**
Skip this batch entirely if the tech stack does NOT include a web UI framework (same detection as Batch 6) OR if Playwright is not in the project dependencies (check package.json, pyproject.toml, or equivalent).

If web project with Playwright detected:
- Playwright configuration file (`playwright.config.ts` for TypeScript projects, `playwright.config.js` for JavaScript). Set `baseURL` to `http://localhost:3000` (or framework default port). Configure `webServer` to start the dev server automatically.
- At least 1 e2e smoke test (`tests/e2e/smoke.spec.ts` or `e2e/smoke.spec.ts`):
  - Verify the application loads (page title is correct, main content area visible)
  - Verify basic navigation works (if router configured — navigate to at least 1 route)
- Test script in package.json: `"test:e2e": "playwright test"` (or equivalent for the framework's test runner)
```

### Change 2: Add Batch 8 — Application Documentation

Insert after Batch 7 (new Batch 7) in the Process Step 2 section:

```markdown
**Batch 8 — Application Documentation:**
- `docs/ARCHITECTURE.md` summarizing:
  - **Stack Choices:** Language, framework, database (if any), and rationale for each choice
  - **Directory Structure:** What each top-level directory contains and why
  - **Key Patterns:** State management approach, routing strategy, API layer design, error handling conventions (include only patterns relevant to the chosen stack)
  - **Configuration:** Environment variables, config files, secrets management approach
  - Content MUST be specific to the generated project — reference actual file paths, actual dependency names, actual patterns used in the skeleton
```

### Change 3: Update CLAUDE.md Config Checklist (in Step 3)

Add to the optional sections checklist in the CLAUDE.md generation step:
```markdown
- [ ] `### Module Docs` — Path pointing to `docs/ARCHITECTURE.md`; always generate this section since docs are always generated
```

### Change 4: Update Quality Scorecard (Step 4b)

Add two new items to the scorecard (after item 9):
```markdown
10. **E2E Test Setup:** (web projects with Playwright only) Config file present? Smoke test exists? Test script defined?
11. **App Documentation:** `docs/ARCHITECTURE.md` exists and contains project-specific content? `Module Docs` section present in CLAUDE.md?
```

Update the example scorecard table in Step 5 to include:
```markdown
| E2E Test Setup | PASS | playwright.config.ts, 1 smoke test (web project) |
| App Documentation | PASS | docs/ARCHITECTURE.md, Module Docs configured |
```

### Change 5: Update Constraints

Add new constraints:
```markdown
- NEVER generate generic/boilerplate architecture documentation — docs/ARCHITECTURE.md MUST reference actual project file paths, dependencies, and patterns
- E2E smoke test MUST verify the actual application loads (check page title or main content), not just that Playwright runs
```

Update file count target:
```markdown
- Target file count: 11-16 files for simple stacks, up to 21 for stacks with database + CI + Docker, up to 26 for web projects with design system + e2e tests. Avoid unnecessary boilerplate — every file must serve a purpose.
```

### Change 6: Update `skills/scaffold/SKILL.md` (if needed)

Assess whether the scaffold skill needs changes. The scaffolder agent handles all generation — the skill just invokes it. Likely NO changes needed because:
- Module Docs is populated in CLAUDE.md by the scaffolder agent itself (Change 3)
- No new pipeline steps are needed
- Validation (Step 3) already checks CLAUDE.md completeness

### Change 7: Write test file `tests/scenarios/scaffold-e2e-and-docs.sh`

New structural test validating the v6.3.0 features.

### Change 8: Write CHANGELOG.md entry

Add v6.3.0 entry at the top of the changelog (after the header, before v6.2.0).

### Change 9: Update roadmap

Move both v6.3.0 items from PLANNED to DONE section.

### Change 10: Version bump

Update version in `.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json`.

## Success Criteria

- [ ] `agents/scaffolder.md` has Batch 7 (E2E Tests, conditional) and Batch 8 (App Documentation)
- [ ] Scorecard has 11 items (was 9)
- [ ] CLAUDE.md config checklist includes Module Docs
- [ ] Constraints updated with new rules and file count ceiling
- [ ] All 41 existing tests pass (`./tests/harness/run-tests.sh`)
- [ ] New structural test passes
- [ ] CHANGELOG.md has v6.3.0 entry
- [ ] Roadmap items moved to DONE
- [ ] Version bumped to 6.3.0

## Anti-Patterns

- Do NOT modify any agent files other than `agents/scaffolder.md`
- Do NOT modify `CLAUDE.md` (the plugin's own CLAUDE.md) — the scaffolder generates CLAUDE.md for consumer projects
- Do NOT add new agents or skills
- Do NOT change the scaffolder's frontmatter (name, description, model, style)
- Do NOT renumber existing batches — add new ones after Batch 6
- Do NOT change existing scorecard items — only add new ones
