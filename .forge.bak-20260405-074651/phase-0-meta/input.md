# Phase 0 — User Task (Verbatim)

feat: Scaffold E2E Test Generation + Application Documentation for Agents (v6.3.0). Two scaffold improvements to agents/scaffolder.md:

1. **Scaffold: E2E Test Generation** — When stack includes a web framework + Playwright is in dependencies, scaffolder should generate a basic e2e test suite (tests/e2e/ or e2e/) with: config file (playwright.config.ts or equivalent), at least 1 smoke test (app loads, basic navigation), test script in package.json (or equivalent). Scorecard: add "E2E Test Setup" item (conditional on web project + E2E config).

2. **Scaffold: Application Documentation for Agents** — Scaffolder should generate `docs/ARCHITECTURE.md` summarizing: stack choices and rationale, directory structure explanation, key patterns (state management, routing, API layer), configuration approach. `Module Docs | Path` config key already exists — scaffolder should populate it pointing at the generated docs. All agents that read Module Docs automatically pick up scaffold-generated documentation.

Both changes go into `agents/scaffolder.md`. Version bump to 6.3.0 + changelog entry needed.
