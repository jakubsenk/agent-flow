# Requirements: E2E Test Engineer Deployment Guard (v6.2.0)

## Problem Statement

The `e2e-test-engineer` agent has a constraint "NEVER run without a live application" but no automated mechanism to enforce it. When E2E tests run against a non-running application, Playwright receives `connection refused` errors. The agent misclassifies these as test failures rather than infrastructure failures, causing the pipeline to waste fixer iterations trying to "fix" tests that cannot possibly pass.

## Scope

**In scope:**
- Agent-level deployment pre-flight check in `e2e-test-engineer`
- Pipeline-level deployment-verifier dispatch before e2e-test-engineer in 4 skill files
- CHANGELOG, version bump, roadmap update

**Out of scope (non-goals):**
- No changes to `deployment-verifier` agent definition
- No changes to `check-deploy` skill
- No new Automation Config keys
- No new agents or skills
- No new tests (existing structural tests cover agent/skill format)

## Functional Requirements

### FR-1: Agent-Level Deployment Pre-Flight (e2e-test-engineer.md)

**FR-1.1:** The `e2e-test-engineer` agent MUST perform a deployment pre-flight check before any E2E test infrastructure check or test execution.

**FR-1.2:** The pre-flight check MUST read the `### Local Deployment` section from Automation Config (via the context provided by the dispatching skill).

**FR-1.3:** When `### Local Deployment` section IS configured:
- The agent MUST dispatch `deployment-verifier` (Task tool, model: sonnet) with action `start` and the full Local Deployment config.
- On verdict `HEALTHY` -> proceed to the next step (E2E infrastructure check).
- On verdict `UNHEALTHY`, `PORT_CONFLICT`, or `START_FAILED` -> Block the pipeline using the Block Comment Template with:
  - Agent: `e2e-test-engineer`
  - Step: `Deployment Pre-Flight`
  - Reason: Deployment verification failed with verdict `{verdict}`
  - Detail: Full deployment-verifier report
  - Recommendation: Based on verdict (see FR-1.5)

**FR-1.4:** When `### Local Deployment` section IS NOT configured:
- The agent MUST emit a warning: `"[WARN] Local Deployment not configured. E2E tests require a running application. If the app is not running externally, tests will fail with connection errors. Configure Local Deployment via /ceos-agents:onboard --update or start the app manually."`
- The agent MUST NOT block. Proceed to the next step.

**FR-1.5:** Block recommendations per verdict:
- `UNHEALTHY`: `"Application started but health check failed. Check the Health check URL in Local Deployment config. Run /ceos-agents:check-deploy for diagnostics."`
- `PORT_CONFLICT`: `"Required ports are occupied by another process. Free the ports or stop the conflicting process. Run /ceos-agents:check-deploy for port details."`
- `START_FAILED`: `"Application failed to start. Check the Start command in Local Deployment config. Run /ceos-agents:check-deploy --start for diagnostics."`

### FR-2: Pipeline-Level Deployment Guard (4 skill files)

**FR-2.1:** Each of the following skills MUST dispatch `deployment-verifier` before dispatching `e2e-test-engineer`, but ONLY when `### Local Deployment` section exists in Automation Config:
- `skills/fix-ticket/SKILL.md`
- `skills/fix-bugs/SKILL.md`
- `skills/implement-feature/SKILL.md`
- `skills/scaffold/SKILL.md`

**FR-2.2:** The pipeline-level guard MUST use the same dispatch pattern as `check-deploy` skill: `ceos-agents:deployment-verifier` (Task tool, model: sonnet) with action `start` and full Local Deployment config context.

**FR-2.3:** The pipeline-level guard MUST respect Agent Overrides: read `{Agent Overrides path}/deployment-verifier.md` and append as `## Project-Specific Instructions` if it exists.

**FR-2.4:** Verdict handling at pipeline level:
- `HEALTHY` or `SKIPPED` -> proceed to e2e-test-engineer dispatch
- `UNHEALTHY`, `PORT_CONFLICT`, `START_FAILED` -> proceed to Block handler (same as other pipeline blocks)

**FR-2.5:** The pipeline-level guard MUST be skipped when:
- The `e2e-test-engineer` stage itself is being skipped (profile Skip stages)
- The `### E2E Test` section is absent AND `e2e-test-engineer` is not in profile's Extra stages
- The `### Local Deployment` section is absent from Automation Config

**FR-2.6:** State update: after deployment-verifier dispatch, update `state.json` with `deployment.verdict`, `deployment.type`, `deployment.result_path`. Follow atomic write protocol from `core/state-manager.md`.

### FR-3: Configuration Reading

**FR-3.1:** The four skill files that gain the deployment guard (`fix-ticket`, `fix-bugs`, `implement-feature`, `scaffold`) MUST read the `### Local Deployment` section from Automation Config in their Configuration section, using the same config-reader output keys: `local_deployment.type`, `local_deployment.start_command`, `local_deployment.stop_command`, `local_deployment.health_check_url`, `local_deployment.health_check_timeout`, `local_deployment.ports`.

**FR-3.2:** If `### Local Deployment` section is absent, the guard step is skipped entirely (no error, no warning at pipeline level -- the agent-level warning in FR-1.4 handles this case).

### FR-4: Step Renumbering (e2e-test-engineer.md)

**FR-4.1:** The new deployment pre-flight MUST be inserted as step 3 in the agent's Process section.

**FR-4.2:** Existing steps 3 through 8 MUST be renumbered to 4 through 9.

### FR-5: Version and Documentation

**FR-5.1:** Version bump from `6.1.9` to `6.2.0` (MINOR -- new backward-compatible feature, no new required config keys).

**FR-5.2:** CHANGELOG entry under `## [6.2.0]` with `### Added` section describing the deployment guard.

**FR-5.3:** Roadmap item "E2E Test Engineer: Deployment Guard" moved from `PLANNED -- Next` to the appropriate DONE section.

## Non-Functional Requirements

**NFR-1:** The deployment guard MUST NOT add latency when Local Deployment is not configured (skip immediately).

**NFR-2:** The deployment guard MUST NOT change behavior for projects that do not use E2E tests (no E2E Test section = no guard runs).

**NFR-3:** The agent-level pre-flight (FR-1) and pipeline-level guard (FR-2) are complementary, not redundant. The pipeline-level guard starts the app proactively; the agent-level pre-flight is a safety net if the agent is invoked outside the pipeline or if the pipeline guard is skipped.
