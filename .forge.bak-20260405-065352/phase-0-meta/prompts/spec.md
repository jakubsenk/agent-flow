# Phase 4 — Specification

{{PERSONA}}
You are a specification writer for the ceos-agents Claude Code plugin. You produce precise, implementable specifications for markdown-only plugin changes.

{{TASK_INSTRUCTIONS}}

## Specification: E2E Test Engineer Deployment Guard (v6.2.0)

### Problem Statement
The `e2e-test-engineer` agent has a constraint "NEVER run without a live application" but no automated mechanism to enforce it. When E2E tests run without a live application, Playwright gets `connection refused` errors that the agent misclassifies as test failures. Users must manually debug that the real issue is no running app.

### Solution — Two-Level Guard

**Level 1: Agent-level pre-flight (e2e-test-engineer.md)**

Replace existing step 3 with a 3-sub-step deployment pre-flight:

1. **Check Local Deployment config** — Read Automation Config for `### Local Deployment` section
2. **If Local Deployment exists** — Dispatch `deployment-verifier` agent (Task tool, model: sonnet) with `action: start`. Evaluate verdict:
   - `HEALTHY` → proceed to E2E test infrastructure check (next step)
   - `SKIPPED` → should not happen (config exists), treat as HEALTHY
   - `UNHEALTHY`, `PORT_CONFLICT`, `START_FAILED` → Block with message: "E2E tests cannot run: deployment verification failed ({verdict}). Fix deployment issues first."
3. **If Local Deployment absent** → Emit warning to output: "Warning: E2E tests require a running application, but Local Deployment is not configured. Configure it via `/ceos-agents:onboard --update` or start the app manually before running E2E tests." Then proceed (do not block — the app might be started externally).

Renumber existing steps 3-8 to 4-9.

**Level 2: Pipeline-level pre-dispatch (4 skill files)**

In each pipeline skill, BEFORE dispatching e2e-test-engineer, add a deployment-verifier call:

- **Condition:** Local Deployment section exists in Automation Config
- **Action:** Run `ceos-agents:deployment-verifier` (Task tool, model: sonnet) with context: `Local Deployment config: {full section}. Action: start.`
- **Verdict handling:**
  - `HEALTHY` → proceed to e2e-test-engineer dispatch
  - `UNHEALTHY`, `PORT_CONFLICT`, `START_FAILED` → Block handler (step X)
  - `SKIPPED` → proceed (no Local Deployment config, agent will handle the warning)
- **If Local Deployment absent:** Skip deployment-verifier, proceed directly to e2e-test-engineer (agent handles the warning)

### Files to Modify

| File | Change |
|------|--------|
| `agents/e2e-test-engineer.md` | New step 3 (deployment pre-flight), renumber 3-8 → 4-9 |
| `skills/fix-ticket/SKILL.md` | Add deployment-verifier before step 8a |
| `skills/fix-bugs/SKILL.md` | Add deployment-verifier before step 7a |
| `skills/implement-feature/SKILL.md` | Add deployment-verifier before step 6f |
| `skills/scaffold/SKILL.md` | Add deployment-verifier before Step 8 |
| `CHANGELOG.md` | New v6.2.0 entry |
| `.claude-plugin/plugin.json` | Version 6.1.9 → 6.2.0 |
| `.claude-plugin/marketplace.json` | Version 6.1.9 → 6.2.0 |
| `docs/plans/roadmap.md` | Move item to DONE section |

### Non-Goals
- No changes to deployment-verifier agent itself (already handles all cases)
- No changes to check-deploy skill (independent entry point)
- No new config keys (uses existing Local Deployment section)
- No new tests required (structural tests already cover agent format and cross-refs)

{{SUCCESS_CRITERIA}}
1. e2e-test-engineer.md has a deployment pre-flight step that checks Local Deployment config before running tests
2. All 4 pipeline skills dispatch deployment-verifier before e2e-test-engineer when Local Deployment is configured
3. Warning message is emitted when Local Deployment is absent (not a block — app might be running externally)
4. Block is issued when deployment-verifier returns non-HEALTHY verdict
5. Existing tests pass without modification
6. Version bumped to 6.2.0 with changelog entry

{{ANTI_PATTERNS}}
- Do NOT block the pipeline when Local Deployment is absent — only warn. The app might be started externally.
- Do NOT modify the deployment-verifier agent — it already handles all verdicts correctly.
- Do NOT change the e2e-test-engineer's existing E2E Test config check (step 2) — that remains separate.
- Do NOT add deployment-verifier to the skip stage list — it is not an independently skippable stage.

{{CODEBASE_CONTEXT}}
- Agent files: `agents/*.md` with YAML frontmatter (name, description, model, style) + Goal/Expertise/Process/Constraints sections
- Skill files: `skills/*/SKILL.md` with orchestration logic
- deployment-verifier verdicts: HEALTHY, UNHEALTHY, PORT_CONFLICT, START_FAILED, SKIPPED
- E2E dispatch pattern: `If the E2E Test section exists in Automation Config OR the profile's Extra stages contains e2e-test-engineer: Run ceos-agents:e2e-test-engineer (Task tool, model: sonnet)`
- Version files: `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`
