# Phase 4 — Specification

You are a **Specification Writer** producing a formal specification for two scaffolder features.

## Task Context

Adding two features to `agents/scaffolder.md` in ceos-agents plugin (v6.2.0 → v6.3.0):

1. **E2E Test Generation** — Conditional batch for Playwright e2e test suite
2. **Application Documentation for Agents** — Batch for `docs/ARCHITECTURE.md` + Module Docs population

## Codebase Context

- **File:** `agents/scaffolder.md` — markdown agent definition
- **Existing batches:** 1 (Core), 2 (Config & Data), 3 (Quality), 4 (Ops), 5 (Docs), 6 (Design — conditional on web)
- **Existing scorecard:** 9 items (Build, Tests, Lint, CLAUDE.md, Dockerfile, CI config, Dependencies, Test infrastructure, Design system)
- **Existing constraints:** 12 NEVER/MUST rules
- **File count targets:** 10-15 simple, up to 20 DB+CI+Docker, up to 23 web+design
- **Module Docs config:** Optional section with `Path` key, consumed by code-analyst and architect agents
- **E2E Test config:** Optional section with `Framework` and `Command` keys

## Requirements (EARS Format)

### REQ-1: E2E Test Generation Batch
**When** the tech stack includes a web UI framework (same detection logic as Batch 6) **and** Playwright is present in the project dependencies (or specified in spec),
**the scaffolder shall** generate a new batch (Batch 7) containing:
1. A Playwright configuration file (`playwright.config.ts` or framework-appropriate equivalent)
2. At least one e2e smoke test file that verifies the application loads and basic navigation works
3. A test script entry in the project's package manager configuration (e.g., `"test:e2e"` in `package.json`)

### REQ-2: E2E Test Generation Skip Condition
**When** the tech stack does NOT include a web UI framework **or** Playwright is not in dependencies,
**the scaffolder shall** skip Batch 7 entirely (same pattern as Batch 6 skip).

### REQ-3: E2E Test Scorecard Item
**After** scaffold completion,
**the quality scorecard shall** include an "E2E Test Setup" item that is:
- Checked only when the project is a web project AND E2E Test config section was generated
- Reports: config file present, smoke test exists, test script defined

### REQ-4: Application Documentation Batch
**For all** scaffolded projects (not conditional — every project benefits from architecture docs),
**the scaffolder shall** generate `docs/ARCHITECTURE.md` containing:
1. Stack choices and rationale (why this language, framework, database)
2. Directory structure explanation (what each top-level directory contains)
3. Key patterns used (state management, routing, API layer — as applicable)
4. Configuration approach (environment variables, config files, secrets management)

### REQ-5: Module Docs Population
**When** generating CLAUDE.md Automation Config,
**the scaffolder shall** include a `Module Docs` optional section with `| Path | docs/ARCHITECTURE.md |` pointing at the generated documentation file.

### REQ-6: Application Documentation Scorecard Item
**After** scaffold completion,
**the quality scorecard shall** include an "App Documentation" item verifying `docs/ARCHITECTURE.md` exists and is non-empty.

### REQ-7: File Count Target Update
**The** file count target constraint **shall** be updated to accommodate the new files:
- Up to 25 for web projects with design system + e2e tests (was 23)
- Up to 21 for non-web projects with DB+CI+Docker + docs (was 20)
- 11-16 for simple stacks + docs (was 10-15)

### REQ-8: Constraint Additions
**The scaffolder shall** have these new constraints:
- E2E smoke test MUST verify the application loads (not just that the test runner works)
- docs/ARCHITECTURE.md MUST be project-specific (not generic boilerplate)

## Acceptance Criteria

- [ ] AC-1: Batch 7 (E2E Tests) generates correct files for a web + Playwright project
- [ ] AC-2: Batch 7 is skipped for non-web projects (CLI, API, library)
- [ ] AC-3: Batch 7 is skipped when Playwright is not in dependencies
- [ ] AC-4: Scorecard includes "E2E Test Setup" (conditional) and "App Documentation" (always)
- [ ] AC-5: `docs/ARCHITECTURE.md` is generated for all projects with meaningful, project-specific content
- [ ] AC-6: CLAUDE.md Automation Config includes `Module Docs | Path` pointing at `docs/ARCHITECTURE.md`
- [ ] AC-7: File count targets updated in constraints
- [ ] AC-8: All existing tests pass (no regressions)
- [ ] AC-9: Changelog entry and version bump to 6.3.0

## Output

Produce a structured specification document covering:
1. Exact markdown text for Batch 7 (E2E Tests)
2. Exact markdown text for Batch 8 (Application Documentation) — or wherever it fits in batch ordering
3. Exact scorecard additions (table rows)
4. Exact constraint additions
5. CLAUDE.md config checklist updates
6. File count target updates
7. List of all files to be modified with change descriptions
