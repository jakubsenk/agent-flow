# Research Answers — Agent 2
<!-- Questions: RQ-05, RQ-06, RQ-07, RQ-08 -->

---

## RQ-05: MCP server capability scope — project-level vs issue-level

**Question:** Do any of the six supported MCP servers expose tools for project-level operations (create repository, create project/board, create label set, create milestone)?

### Findings

The plugin's MCP configuration files (`examples/mcp-configs/`) are pure connection wrappers that specify the package, command, and authentication env vars only. No tool-level capability enumeration is present anywhere in the codebase:

| Tracker | MCP Package | Config file |
|---------|-------------|-------------|
| youtrack | `@vitalyostanin/youtrack-mcp` | `examples/mcp-configs/youtrack.json` |
| github | `@modelcontextprotocol/server-github` | `examples/mcp-configs/github.json` |
| jira | `@modelcontextprotocol/server-atlassian` | `examples/mcp-configs/jira.json` |
| linear | `@modelcontextprotocol/server-linear` | `examples/mcp-configs/linear.json` |
| gitea | `forgejo-mcp` (binary) | `examples/mcp-configs/gitea.json` |
| redmine | `mcp-server-redmine` | `examples/mcp-configs/redmine.json` |

The codebase documents only three MCP usage patterns:
1. **Issue tracker read:** query issues via Bug query (used by triage, code-analyst, etc.)
2. **Issue tracker write:** update issue state, post comments (used by publisher, triage-analyst)
3. **Source control read/write:** list repos, create PR, add labels (used by publisher, create-pr)

The connectivity validation in `commands/check-setup.md` Block 3 confirms the scope is read-only issue queries plus repo listing — no project/board/milestone creation is tested or expected. The `commands/init.md` Step 7 also limits the validation test to "query 1 issue" (tracker) and "list repos" (source control).

No command in the codebase performs project-level operations (create repository, create project/board, create label set, create milestone) via MCP. The closest operation is `commands/scaffold.md` Step 9, which creates epic and sub-issue cards in the tracker — but this is **issue-level** (creating tickets under an existing project), not project-level (creating the project/board itself). That step also explicitly gates on an already-configured tracker instance.

**Answer:** The codebase contains no calls to project-level MCP tools and no documentation of such capabilities. The six MCP servers are used exclusively at issue-level (query, state update, comment) and PR-level (create PR, add label) operations. Whether the underlying MCP packages themselves expose project-creation tools is unknown from this codebase alone — no such tools are referenced, invoked, or guarded against.

**Confidence:** HIGH for "the plugin does not use project-level MCP operations." LOW for "the packages don't expose them" — that requires inspecting the external packages, which are not vendored here.

**NEEDS_VALIDATION:** Yes — to determine whether `@modelcontextprotocol/server-github` or `forgejo-mcp` expose `create_repo`, `create_milestone`, etc., inspect those packages directly. If they do, there is a latent risk that a misconfigured agent could inadvertently call them since `mcp__*` wildcard is used in `allowed-tools`.

---

## RQ-06: Scaffold bootstrap sequence and TODO placeholder design

**Question:** What is the intended bootstrap sequence for the TODO placeholders in scaffold-generated CLAUDE.md?

### Findings

**Where TODOs are injected (scaffolder.md, Process step 3):**

The scaffolder generates CLAUDE.md during Batch 5 (Docs). All required Automation Config sections must be present. Sections requiring manual input are marked with HTML comments:
```
<!-- TODO: Replace with your actual YouTrack/Gitea instance -->
```

The scaffolder explicitly uses this pattern only for `Instance` and `Project` fields in the Issue Tracker section and `Remote` in Source Control — fields that cannot be inferred from project description alone.

**Where TODOs are surfaced post-scaffold:**

`commands/scaffold.md` Step 10 (Final Report) explicitly lists remaining TODOs:
```
### Remaining TODOs in CLAUDE.md:
- [ ] Issue Tracker instance
- [ ] Source Control remote
```

The `--no-implement` legacy flow (Step L6) gives the same guidance:
```
1. Review CLAUDE.md — fill in TODO sections (Issue Tracker instance, Source Control remote)
```

**Can `/ceos-agents:onboard` fill them in?**

Yes, with qualifications. `commands/onboard.md` supports `--update` mode. Its Step U0 detects existing config, Step U1 iterates section-by-section showing current values and asking for replacements. The onboard wizard will correctly handle placeholder values — its detection logic explicitly routes to update mode when `## Automation Config` already exists.

However, onboard does not specifically detect `<!-- TODO:` markers — it simply walks all sections and prompts for each key. It will prompt the user to provide a real Instance/Project/Remote value, effectively replacing any placeholder.

**Intended bootstrap sequence:**

1. `/ceos-agents:scaffold` → generates project + CLAUDE.md with `<!-- TODO: -->` markers for instance-specific values
2. Manual edit **or** `/ceos-agents:onboard --update` → replaces TODO values with real tracker instance, project, and remote
3. `/ceos-agents:init` → configures MCP servers and tokens
4. `/ceos-agents:check-setup` → validates all values are filled (placeholder detection via `<...>` pattern)

Note: `scaffold.md` Step 9 has a conditional that explicitly skips issue tracker card creation if TODO markers are present (`look for <!-- TODO: in Instance or Project values`), confirming TODO markers are a first-class detection mechanism in the pipeline.

**Confidence:** HIGH. The sequence is explicitly documented across scaffold.md Step 10, scaffolder.md Process step 3, and onboard.md Step U1.

**NEEDS_VALIDATION:** The `check-setup` placeholder detection uses `<...>` pattern, but TODO markers use `<!-- TODO: -->`. If a user replaces `<YOUR_*>` with a literal TODO comment instead of a real value, check-setup will not flag it. This is a minor gap — low risk.

---

## RQ-07: Scaffold build/test against missing infrastructure

**Question:** Does the scaffolder generate .env.example/.env.test sufficient for build and test to pass without external services?

### Findings

**What the scaffolder generates for environment isolation (scaffolder.md, Process step 2, Batch 3):**

The scaffolder is required to generate:
- `.env.example` — Batch 2 (Config & Data), conditional: "if database or secrets needed"
- `.env.test` — Batch 3 (Quality), as part of test infrastructure setup: "Environment isolation (.env.test with test-specific values)"
- Test infrastructure setup file (conftest.py / test/setup.{ext}) containing:
  - Dynamic port allocation (OS-assigned port 0, not hardcoded)
  - Database test fixtures (create/teardown test database)
  - Health check helper (wait for service readiness with timeout)
  - `.env.test` with test-specific values

**Constraints that enforce this:**

From `scaffolder.md` Constraints section:
- "NEVER use hardcoded ports in test infrastructure — always use dynamic port allocation"
- "Test setup file MUST be importable/includable by the smoke test — verify the import works"
- "Generated skeleton MUST build, MUST pass tests, MUST pass linter"

The scaffolder runs its own build+test verification (Process step 4) and retries up to 3 times before reporting failure. The quality scorecard (step 4b) checks "Test infra: Setup file present with port allocation?"

**CI service containers (scaffolder.md, Batch 4):**

The CI config must "Include service containers if database needed (with health checks)". This means for database-dependent projects, the CI pipeline itself spins up the DB — but the local test run depends on the test fixtures in Batch 3.

**The gap: external services in local dev:**

The `.env.example` is only generated "if database or secrets needed" — it is conditional and not always present. The `.env.test` is part of the test infrastructure setup but its actual content is LLM-generated at scaffold time. The scaffolder is instructed to use test-specific values but there is no explicit constraint that the smoke test must pass without a running database or external service.

For database-dependent projects, the scaffolder generates DB fixtures (create/teardown test database), which implies a running DB is required for tests locally. The scaffolder's own verification (step 4) runs inside its execution context — if the scaffolder agent happens to have a local DB available in that context, tests pass. But if `scaffold` runs in an environment without the external service, the scaffolder's verification may fail (triggering retries) or the tests may be written to skip/mock when the service is unavailable.

**What is NOT specified:**

The scaffolder definition does not require:
- Mocking strategies for external services
- Test-only in-memory database substitution (e.g., SQLite for PostgreSQL tests)
- Explicit "tests must pass without any running service" constraint

The only hard constraint is dynamic port allocation (no hardcoded ports).

**Answer:** The scaffolder is required to generate `.env.test` with test-specific values and dynamic port allocation, and for DB projects, generate create/teardown test fixtures. This is sufficient to avoid port conflicts and clean up after tests. However, whether the generated artifacts allow tests to pass without a running external service depends entirely on the LLM's implementation choices — no constraint in the scaffolder definition mandates service-free test execution (mocks/in-memory substitutions). For non-DB projects, the smoke test ("app starts and responds") will use dynamic ports and is likely self-contained. For DB-dependent projects, the scaffolder may generate tests that require a live database.

**Confidence:** MEDIUM. The spec is clear about what must be generated structurally; the functional sufficiency for CI without external services is not guaranteed by constraints.

**NEEDS_VALIDATION:** Test a scaffold of a PostgreSQL + Python FastAPI project and verify whether the generated tests pass in a clean environment (no running Postgres). The CI config with service containers will likely pass; local `npm test` / `pytest` without Docker may not.

---

## RQ-08: Scaffold-to-implement-feature handoff — missing finalize step

**Question:** Is there a missing scaffold-finalize step, or is manual editing the only path?

### Findings

**What scaffold produces and leaves incomplete:**

`commands/scaffold.md` explicitly states (Rules section):
> "Scaffolder generates CLAUDE.md — but Issue Tracker instance and Source Control remote require manual completion (marked with TODO comments)"

The Final Report (Step 10) always includes:
```
### Next steps:
1. Review CLAUDE.md — fill in TODO sections
2. Run `/ceos-agents:check-setup` to validate configuration
3. Run `/ceos-agents:scaffold-validate` to verify project state
```

There is no `/scaffold-finalize` command in the plugin. The 24 commands are: `analyze-bug`, `fix-ticket`, `fix-bugs`, `create-pr`, `publish`, `version-bump`, `check-setup`, `resume-ticket`, `status`, `onboard`, `init`, `changelog`, `version-check`, `implement-feature`, `scaffold`, `scaffold-add`, `scaffold-validate`, `dashboard`, `metrics`, `estimate`, `prioritize`, `migrate-config`, `template`, `discuss`.

**Can existing commands bridge the gap?**

Three commands partially cover post-scaffold configuration:

1. **`/ceos-agents:onboard --update`** (`commands/onboard.md`): The closest thing to a finalize step. It walks through all Automation Config sections interactively, including prompting for real values where TODOs or placeholders exist. It can fully replace all TODO values without manual file editing. However, it is not framed as a "scaffold finalize" step — it is a generic config wizard. The scaffold Final Report does not mention it.

2. **`/ceos-agents:init`** (`commands/init.md`): Handles the MCP/token side of the setup (the non-CLAUDE.md part). Required after onboard to make the pipeline runnable.

3. **`/ceos-agents:scaffold-add claude-md`** (`commands/scaffold-add.md`): Regenerates CLAUDE.md for an existing project that lacks one. Not useful post-scaffold (CLAUDE.md already exists).

**The gap analysis:**

The scaffold Final Report (Step 10) mentions onboard is not mentioned as a next step — the steps listed are manual editing, check-setup, and scaffold-validate. The `commands/scaffold.md` Step 9 (Issue Tracker optional) also has a condition: "If TODO markers present → skip (no tracker configured)." This means the entire issue tracker card creation is deferred until after manual TODO resolution.

The intended path from scaffold to `implement-feature` is:
1. `/scaffold` → working code + CLAUDE.md with TODOs
2. Manual edit CLAUDE.md (fill Instance, Remote, Project) **or** `/onboard --update`
3. `/init` → configure MCP + tokens
4. `/check-setup` → validate
5. `/implement-feature <ID>` → start feature pipeline

The "manual editing is the only documented path" statement is not fully accurate — `/onboard --update` is a functional alternative. However, there is no automated finalize command that detects scaffold output and specifically guides the user through only the TODO fields. The gap is a **missing cross-reference in the scaffold Final Report**: it does not mention `/onboard --update` as an option.

**`/scaffold-add` assessment:**

`commands/scaffold-add.md` supports components `claude-md`, `ci`, `docker`, `tests`. It can add a fresh CLAUDE.md to an existing project that has none, but cannot "fill in" an existing CLAUDE.md's TODO values. It delegates to scaffolder, which would overwrite or merge — the command warns "if CLAUDE.md already exists → ask whether to overwrite or merge."

**Confidence:** HIGH. The findings are clear from reading the three relevant command files.

**NEEDS_VALIDATION:** Verify whether `/onboard --update` correctly detects and handles `<!-- TODO: -->` HTML comment placeholders vs. the `<YOUR_*>` angle-bracket placeholders that check-setup detects. If onboard only replaces values when the user types something new (and skips on Enter), a user might press Enter through a `<!-- TODO: -->` value and the TODO would remain unresolved.
