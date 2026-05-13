# Design: E2E Test Engineer Deployment Guard (v6.2.0)

## Overview

Two-level guard preventing E2E tests from running against a dead application:
1. **Agent-level** -- pre-flight check inside `e2e-test-engineer.md` (safety net)
2. **Pipeline-level** -- deployment-verifier dispatch before e2e-test-engineer in 4 skill files (proactive start)

## File Changes

### 1. `agents/e2e-test-engineer.md`

**Change type:** Modify existing agent definition.

#### 1a. Insert new step 3 (Deployment Pre-Flight)

**Insertion point:** After current step 2 (line 22-23, ends with `Block with message "No E2E test configuration in Automation Config"`), before current step 3 (line 23, starts with `3. Check if E2E test infrastructure is available`).

**New step 3 text:**

```markdown
3. Deployment pre-flight — verify application is running:
   a. Check if `### Local Deployment` section exists in the Automation Config context provided by the dispatching skill
   b. If Local Deployment IS configured:
      - Dispatch `ceos-agents:deployment-verifier` (Task tool, model: sonnet)
        Context: `Action: start. Local Deployment config: Type = {Type}, Start command = {Start command}, Stop command = {Stop command}, Health check URL = {Health check URL}, Health check timeout = {Health check timeout}, Ports = {Ports}.`
      - On verdict `HEALTHY` → proceed to step 4
      - On verdict `UNHEALTHY` → Block with: "Deployment verification failed (UNHEALTHY). Application started but health check failed. Check the Health check URL in Local Deployment config. Run /ceos-agents:check-deploy for diagnostics."
      - On verdict `PORT_CONFLICT` → Block with: "Deployment verification failed (PORT_CONFLICT). Required ports are occupied by another process. Free the ports or stop the conflicting process. Run /ceos-agents:check-deploy for port details."
      - On verdict `START_FAILED` → Block with: "Deployment verification failed (START_FAILED). Application failed to start. Check the Start command in Local Deployment config. Run /ceos-agents:check-deploy --start for diagnostics."
   c. If Local Deployment IS NOT configured:
      - Emit warning: "[WARN] Local Deployment not configured. E2E tests require a running application. If the app is not running externally, tests will fail with connection errors. Configure Local Deployment via /ceos-agents:onboard --update or start the app manually."
      - Do NOT block — proceed to step 4
```

#### 1b. Renumber existing steps

| Old step | New step | Content (first words) |
|----------|----------|-----------------------|
| 3 | 4 | Check if E2E test infrastructure is available |
| 4 | 5 | Review existing E2E tests for the affected area |
| 5 | 6 | Plan test scope — write 1-2 focused E2E tests |
| 6 | 7 | Write new E2E tests |
| 7 | 8 | Run the tests |
| 8 | 9 | Output |

#### 1c. Update Constraints section

Add a new constraint after "NEVER run without a live application":

```markdown
- Deployment pre-flight (step 3) MUST run before any test infrastructure check — if deployment-verifier returns a non-HEALTHY verdict, Block immediately without attempting to run tests
```

### 2. `skills/fix-ticket/SKILL.md`

**Change type:** Add config reading + deployment guard step.

#### 2a. Configuration section (line ~48-52)

**Insertion point:** After the `Agent Overrides` bullet (line 48-49), before the `Browser Verification` bullet (line 50).

**New bullet:**

```markdown
- **Local Deployment** from Local Deployment section (if it exists):
  - Type (default: `docker`), Start command (default: `docker compose up -d`), Stop command (default: `docker compose down`), Health check URL (default: `http://localhost:3000/health`), Health check timeout (default: 60), Ports (default: none)
  - If section absent → `local_deployment_configured = false`
```

#### 2b. New step 8a-deploy (Deployment guard before E2E)

**Insertion point:** After step 8 (Test-engineer, ends at line ~297 with state.json update), before step 8a (E2E test-engineer, starts at line ~298).

**New step heading and text:**

```markdown
### 8a-deploy. Deployment guard (pre-E2E)

If `local_deployment_configured = false` → skip.
If stage `e2e-test-engineer` is in the profile's Skip stages → skip (no E2E = no deployment needed).
If the E2E Test section is absent AND `e2e-test-engineer` is NOT in the profile's `Extra stages` → skip.

Run `ceos-agents:deployment-verifier` (Task tool, model: sonnet).
Context: `Action: start. Local Deployment config: Type = {Type}, Start command = {Start command}, Stop command = {Stop command}, Health check URL = {Health check URL}, Health check timeout = {Health check timeout}, Ports = {Ports}. Run directory: .ceos-agents/{ISSUE-ID}/`

Read Agent Overrides path from Automation Config (default: `customization/`). If `{Agent Overrides path}/deployment-verifier.md` exists, append its contents to the agent context as `## Project-Specific Instructions\n{file content}`.

Verdict handling:
- `HEALTHY` or `SKIPPED` → continue to step 8a (E2E test-engineer)
- `UNHEALTHY`, `PORT_CONFLICT`, `START_FAILED` → proceed to Block handler (step X)

Update `state.json`: write `deployment.verdict`, `deployment.type`, `deployment.result_path`. Follow atomic write protocol from `core/state-manager.md`.
```

#### 2c. Rename existing step 8a to 8b

The existing `### 8a. E2E test-engineer` becomes `### 8b. E2E test-engineer`. Update all internal references to step 8a that refer to the E2E step.

#### 2d. Rename existing step 8a-browser to 8b-browser

The existing `### 8a-browser. Browser Verification` becomes `### 8b-browser. Browser Verification`. Update the reference in the browser verification verdict handling from "continue to step 8b" to "continue to step 8c" (the next step after browser verification).

**Note:** Check all forward references in the file. The browser verification verdict handling currently says "continue to step 8b" -- since step 8b is now E2E, this reference must be re-examined. If 8b referred to the acceptance gate or publisher step, update to the new step number.

#### 2e. Subtask loop (step 4c, line ~201)

**Current text (line 201):**
```
8. If E2E Test section exists: run e2e-test-engineer.
```

**New text:**
```
8. If Local Deployment section exists AND E2E Test section exists: run deployment-verifier (Task tool, model: sonnet, action: start). On HEALTHY → continue. On UNHEALTHY/PORT_CONFLICT/START_FAILED → Block handler.
9. If E2E Test section exists: run e2e-test-engineer.
```

Renumber remaining items in the subtask loop (9. Commit subtask becomes 10. Commit subtask).

### 3. `skills/fix-bugs/SKILL.md`

**Change type:** Add config reading + deployment guard step. Identical pattern to fix-ticket.

#### 3a. Configuration section

**Insertion point:** Same relative position as fix-ticket -- after Agent Overrides, before Browser Verification. Verify the exact line numbers by searching for `Agent Overrides` in the file.

**New bullet:** Same text as fix-ticket section 2a.

#### 3b. New step 7a-deploy (Deployment guard before E2E)

**Insertion point:** After step 7 (Test-engineer, ends at line ~284 with state.json update), before step 7a (E2E test-engineer, starts at line ~285).

**New step text:** Same structure as fix-ticket step 8a-deploy, but with step numbers adjusted:
- Step heading: `### 7a-deploy. Deployment guard (pre-E2E)`
- "continue to step 7a" references become "continue to step 7b"

#### 3c. Rename existing step 7a to 7b

The existing `### 7a. E2E test-engineer` becomes `### 7b. E2E test-engineer`.

#### 3d. Rename existing step 7a-browser to 7b-browser

The existing `### 7a-browser. Browser Verification` becomes `### 7b-browser. Browser Verification`. Update internal references accordingly.

#### 3e. Subtask loop (step 3c, line ~188)

Same change as fix-ticket step 2e. Current line:
```
8. If E2E Test section exists: run e2e-test-engineer.
```
Becomes deployment-verifier + e2e-test-engineer two-step sequence. Renumber subsequent items.

#### 3f. Stage mapping update

Update the stage mapping comment near the top:
- `e2e-test-engineer` = step 7b (was 7a)
- Add: no new stage mapping entry for 7a-deploy (it is not a skippable stage, it is conditional on Local Deployment config)

### 4. `skills/implement-feature/SKILL.md`

**Change type:** Add config reading + deployment guard step.

#### 4a. Configuration section

Search for the config reading section (should be near the top). Add Local Deployment bullet in the same pattern as fix-ticket.

#### 4b. New step 6f-deploy (Deployment guard before E2E)

**Insertion point:** After step 6e (Test-engineer, ends at line ~299 with state.json update), before step 6f (E2E test, starts at line ~301).

**New step text:**

```markdown
#### 6f-deploy. Deployment guard (pre-E2E)

If `local_deployment_configured = false` → skip.
If stage `e2e-test-engineer` is in the profile's Skip stages → skip.
If the E2E Test section is absent AND `e2e-test-engineer` is NOT in the profile's `Extra stages` → skip.

Run `ceos-agents:deployment-verifier` (Task tool, model: sonnet).
Context: `Action: start. Local Deployment config: Type = {Type}, Start command = {Start command}, Stop command = {Stop command}, Health check URL = {Health check URL}, Health check timeout = {Health check timeout}, Ports = {Ports}. Run directory: .ceos-agents/{ISSUE-ID}/`

Read Agent Overrides path from Automation Config (default: `customization/`). If `{Agent Overrides path}/deployment-verifier.md` exists, append its contents to the agent context as `## Project-Specific Instructions\n{file content}`.

Verdict handling:
- `HEALTHY` or `SKIPPED` → continue to step 6g (E2E test)
- `UNHEALTHY`, `PORT_CONFLICT`, `START_FAILED` → proceed to step X (Block handler)

Update `state.json`: write `deployment.verdict`, `deployment.type`, `deployment.result_path`. Follow atomic write protocol from `core/state-manager.md`.
```

#### 4c. Rename existing step 6f to 6g

The existing `#### 6f. E2E test (optional)` becomes `#### 6g. E2E test (optional)`.

#### 4d. Renumber remaining steps

| Old step | New step |
|----------|----------|
| 6f | 6g (E2E test) |
| 6g | 6h (Acceptance gate) |
| 6h | 6i (Commit subtask) |

Update all internal references (e.g., "continue to step 6h" in acceptance gate becomes "continue to step 6i").

#### 4e. Stage mapping update

Update the stage mapping comment:
- `e2e-test-engineer` = step 6g (was 6f)

### 5. `skills/scaffold/SKILL.md`

**Change type:** Add deployment guard before Step 8 (E2E Tests).

#### 5a. Configuration section

Scaffold may not have a standard config reading section since it generates the CLAUDE.md. The guard must check the **generated** CLAUDE.md for Local Deployment config, not the parent project's config.

**Insertion point:** Step 8 (E2E Tests), line ~720.

#### 5b. New deployment guard within Step 8

**Current text (lines 720-735):**
```markdown
### Step 8: E2E Tests

If E2E Test section exists in generated CLAUDE.md:

  Run e2e-test-engineer agent (Task tool, model: sonnet):
    Context: spec/verification.md test strategy + list of implemented features + acceptance criteria

  If e2e tests fail → fixer repairs → re-run (e2e-test-engineer handles retries internally)
  If still failing → report as warning (do not block — features are already committed)

  ```bash
  git add -A
  git commit -m "test: add E2E tests"
  ```

If no E2E Test section → skip.
```

**New text:**
```markdown
### Step 8: E2E Tests

If E2E Test section exists in generated CLAUDE.md:

  **Deployment guard:**
  If Local Deployment section exists in generated CLAUDE.md:
    Run `ceos-agents:deployment-verifier` (Task tool, model: sonnet).
    Context: `Action: start. Local Deployment config: Type = {Type}, Start command = {Start command}, Stop command = {Stop command}, Health check URL = {Health check URL}, Health check timeout = {Health check timeout}, Ports = {Ports}. Run directory: .ceos-agents/scaffold/`
    Read Agent Overrides path from generated CLAUDE.md (default: `customization/`). If `{Agent Overrides path}/deployment-verifier.md` exists, append its contents to the agent context as `## Project-Specific Instructions\n{file content}`.
    Verdict handling:
    - `HEALTHY` or `SKIPPED` → proceed to e2e-test-engineer
    - `UNHEALTHY`, `PORT_CONFLICT`, `START_FAILED` → report as warning (do not block — scaffold should not fail on deployment issues). Log: "[WARN] Deployment guard failed ({verdict}). E2E tests skipped. Run /ceos-agents:check-deploy after scaffold completes."
    - Skip e2e-test-engineer dispatch if deployment guard failed.
  If Local Deployment section is absent:
    Log: "[WARN] Local Deployment not configured. Skipping deployment guard — e2e-test-engineer will check on its own."

  Run e2e-test-engineer agent (Task tool, model: sonnet):
    Context: spec/verification.md test strategy + list of implemented features + acceptance criteria

  If e2e tests fail → fixer repairs → re-run (e2e-test-engineer handles retries internally)
  If still failing → report as warning (do not block — features are already committed)

  ```bash
  git add -A
  git commit -m "test: add E2E tests"
  ```

If no E2E Test section → skip.
```

**Design note:** Scaffold's deployment guard uses warning-only (not block) because scaffold already commits features before Step 8. Blocking here would leave the project in a partially-completed state with no benefit.

### 6. `CHANGELOG.md`

**Insertion point:** Before the `## [6.1.9]` entry (line 10).

**New entry:**

```markdown
## [6.2.0] — {DATE}

**MINOR** — E2E Test Engineer deployment guard. Prevents E2E tests from running against a non-running application by dispatching deployment-verifier before e2e-test-engineer.

### Added
- **e2e-test-engineer Step 3 (Deployment Pre-Flight):** New step checks Local Deployment config before E2E test execution. If configured, dispatches deployment-verifier with action: start. On HEALTHY proceeds; on UNHEALTHY/PORT_CONFLICT/START_FAILED blocks with diagnostic message. If not configured, emits warning and proceeds. Existing steps 3-8 renumbered to 4-9.
- **fix-ticket Step 8a-deploy:** Pipeline-level deployment guard before E2E test-engineer dispatch. Dispatches deployment-verifier when Local Deployment is configured. Existing steps 8a/8a-browser renumbered to 8b/8b-browser.
- **fix-bugs Step 7a-deploy:** Same deployment guard for fix-bugs pipeline. Existing steps 7a/7a-browser renumbered to 7b/7b-browser.
- **implement-feature Step 6f-deploy:** Same deployment guard for implement-feature pipeline. Existing steps 6f-6h renumbered to 6g-6i.
- **scaffold Step 8 (Deployment guard):** Pre-E2E deployment guard in scaffold pipeline. Warning-only on failure (no block — features already committed).
- **fix-ticket, fix-bugs, implement-feature Configuration:** Local Deployment config reading added to Configuration section.
- **e2e-test-engineer Constraint:** New constraint requiring deployment pre-flight before test infrastructure check.

```

### 7. `.claude-plugin/plugin.json`

**Change:** `"version": "6.1.9"` -> `"version": "6.2.0"`

### 8. `.claude-plugin/marketplace.json`

**Change:** Version field `"6.1.9"` -> `"6.2.0"`

### 9. `docs/plans/roadmap.md`

**Change:** Move the "E2E Test Engineer: Deployment Guard -- v6.2.0" section from `## PLANNED -- Next` to the appropriate DONE section (e.g., `## DONE -- Recent` or whichever heading convention is used). Update the status marker.

## Deployment-Verifier Dispatch Pattern

All deployment-verifier dispatches in the four skill files MUST follow the exact pattern established in `skills/check-deploy/SKILL.md`:

```
Run `ceos-agents:deployment-verifier` (Task tool, model: sonnet).
Context: `Action: start. Local Deployment config: Type = {Type}, Start command = {Start command}, Stop command = {Stop command}, Health check URL = {Health check URL}, Health check timeout = {Health check timeout}, Ports = {Ports}. Run directory: .ceos-agents/{ISSUE-ID}/`

Read Agent Overrides path from Automation Config (default: `customization/`). If `{Agent Overrides path}/deployment-verifier.md` exists, append its contents to the agent context as `## Project-Specific Instructions\n{file content}`.
```

The only variation is the `Run directory` path (uses `{ISSUE-ID}` in bug/feature pipelines, `scaffold` in scaffold pipeline).

## Interaction Between Levels

```
Pipeline skill                    e2e-test-engineer agent
     |                                    |
     |  (Local Deployment configured?)    |
     |  YES: dispatch deployment-verifier |
     |        verdict HEALTHY ─────────── | ─── step 3: Local Deployment configured?
     |        verdict FAIL ──> Block      |     YES: deployment-verifier (redundant but safe)
     |  NO: skip guard ──────────────── > |     NO: emit warning, proceed
     |                                    |
     |  dispatch e2e-test-engineer ─────> |  step 4: check E2E infrastructure
     |                                    |  step 5-9: normal flow
```

In the normal pipeline flow with Local Deployment configured, deployment-verifier runs twice (pipeline + agent). This is intentional: the agent-level check confirms the app is still healthy at agent execution time (the pipeline guard may have run minutes earlier). The deployment-verifier agent is designed to be idempotent -- if the app is already running, it skips straight to health check.

When invoked outside the pipeline (e.g., manually via Task tool), only the agent-level guard fires.
