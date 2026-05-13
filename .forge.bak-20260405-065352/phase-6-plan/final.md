# Implementation Plan: E2E Test Engineer Deployment Guard (v6.2.0)

## Task List

8 tasks (T1-T8). Each task specifies the exact file, insertion point, and verbatim text.

---

### T1. Agent-level pre-flight: `agents/e2e-test-engineer.md`

**File:** `agents/e2e-test-engineer.md`
**Dependencies:** None

#### T1a. Insert new step 3 (Deployment Pre-Flight)

**Insertion point:** After line 22 (ends with `Block with message "No E2E test configuration in Automation Config"`), before line 23 (currently `3. Check if E2E test infrastructure is available`).

**Replace:**

```
3. Check if E2E test infrastructure is available (running app required):
```

**With:**

```
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
4. Check if E2E test infrastructure is available (running app required):
```

#### T1b. Renumber existing steps 4-8

**Replace** (each occurrence, in order):

| Find (exact) | Replace with |
|---|---|
| `4. Review existing E2E tests for the affected area:` | `5. Review existing E2E tests for the affected area:` |
| `5. Plan test scope — write 1-2 focused E2E tests:` | `6. Plan test scope — write 1-2 focused E2E tests:` |
| `6. Write new E2E tests:` | `7. Write new E2E tests:` |
| `7. Run the tests:` | `8. Run the tests:` |
| `8. Output:` | `9. Output:` |

#### T1c. Add new constraint

**Insertion point:** After line 54 (`- NEVER run without a live application — E2E tests require a running application instance`).

**Replace:**

```
- NEVER run without a live application — E2E tests require a running application instance
- NEVER write flaky tests — no random data, no timing dependencies, no fixed `sleep()` calls
```

**With:**

```
- NEVER run without a live application — E2E tests require a running application instance
- Deployment pre-flight (step 3) MUST run before any test infrastructure check — if deployment-verifier returns a non-HEALTHY verdict, Block immediately without attempting to run tests
- NEVER write flaky tests — no random data, no timing dependencies, no fixed `sleep()` calls
```

---

### T2. Pipeline-level guard: `skills/fix-ticket/SKILL.md`

**File:** `skills/fix-ticket/SKILL.md`
**Dependencies:** None

#### T2a. Add Local Deployment config reading

**Insertion point:** After line 49 (`  - Path (default: \`customization/\`)`), before line 50 (`- **Browser Verification**...`).

**Replace:**

```
- **Agent Overrides** from Agent Overrides section (if it exists):
  - Path (default: `customization/`)
- **Browser Verification** from Browser Verification section (if it exists):
```

**With:**

```
- **Agent Overrides** from Agent Overrides section (if it exists):
  - Path (default: `customization/`)
- **Local Deployment** from Local Deployment section (if it exists):
  - Type (default: `docker`), Start command (default: `docker compose up -d`), Stop command (default: `docker compose down`), Health check URL (default: `http://localhost:3000/health`), Health check timeout (default: 60), Ports (default: none)
  - If section absent → `local_deployment_configured = false`
- **Browser Verification** from Browser Verification section (if it exists):
```

#### T2b. Update stage mapping

**Replace:**

```
- `e2e-test-engineer` = step 8a (E2E test-engineer)
- `reproducer` = step 4e (Browser Reproduction)
- `browser-verifier` = step 8a-browser (Browser Verification)
```

**With:**

```
- `e2e-test-engineer` = step 8b (E2E test-engineer)
- `reproducer` = step 4e (Browser Reproduction)
- `browser-verifier` = step 8b-browser (Browser Verification)
```

#### T2c. Update Extra stages reference

**Replace:**

```
- `Extra stages`: if it contains `e2e-test-engineer` → force step 8a even without the E2E Test config section
```

**With:**

```
- `Extra stages`: if it contains `e2e-test-engineer` → force step 8b even without the E2E Test config section
```

#### T2d. Update subtask loop (step 4c)

**Replace:**

```
8. If E2E Test section exists: run e2e-test-engineer.
9. Commit subtask:
```

**With:**

```
8. If Local Deployment section exists AND E2E Test section exists: run deployment-verifier (Task tool, model: sonnet, action: start). On HEALTHY → continue. On UNHEALTHY/PORT_CONFLICT/START_FAILED → Block handler.
9. If E2E Test section exists: run e2e-test-engineer.
10. Commit subtask:
```

#### T2e. Insert new step 8a-deploy before existing 8a

**Insertion point:** After line 296 (end of step 8 state.json update), before line 298 (`### 8a. E2E test-engineer`).

**Replace:**

```
Update `state.json`: set `test.status` to `"completed"` (or `"blocked"` on failure), increment `test.attempts`, set `test.last_result` to `"PASSED"` or `"FAILED"`. Follow atomic write protocol from `core/state-manager.md`.

### 8a. E2E test-engineer
```

**With:**

```
Update `state.json`: set `test.status` to `"completed"` (or `"blocked"` on failure), increment `test.attempts`, set `test.last_result` to `"PASSED"` or `"FAILED"`. Follow atomic write protocol from `core/state-manager.md`.

### 8a-deploy. Deployment guard (pre-E2E)

If `local_deployment_configured = false` → skip.
If stage `e2e-test-engineer` is in the profile's Skip stages → skip (no E2E = no deployment needed).
If the E2E Test section is absent AND `e2e-test-engineer` is NOT in the profile's `Extra stages` → skip.

Run `ceos-agents:deployment-verifier` (Task tool, model: sonnet).
Context: `Action: start. Local Deployment config: Type = {Type}, Start command = {Start command}, Stop command = {Stop command}, Health check URL = {Health check URL}, Health check timeout = {Health check timeout}, Ports = {Ports}. Run directory: .ceos-agents/{ISSUE-ID}/`

Read Agent Overrides path from Automation Config (default: `customization/`). If `{Agent Overrides path}/deployment-verifier.md` exists, append its contents to the agent context as `## Project-Specific Instructions\n{file content}`.

Verdict handling:
- `HEALTHY` or `SKIPPED` → continue to step 8b (E2E test-engineer)
- `UNHEALTHY`, `PORT_CONFLICT`, `START_FAILED` → proceed to Block handler (step X)

Update `state.json`: write `deployment.verdict`, `deployment.type`, `deployment.result_path`. Follow atomic write protocol from `core/state-manager.md`.

### 8b. E2E test-engineer
```

#### T2f. Rename 8a-browser to 8b-browser and update forward references

**Replace:**

```
### 8a-browser. Browser Verification
```

**With:**

```
### 8b-browser. Browser Verification
```

**Replace** (3 occurrences in the Browser Verification verdict handling — lines 314-316):

```
- `VERIFIED` → log "[PASS] browser verification", continue to step 8b.
- `PARTIAL` → log "[WARN] browser verification partial: {observations}", continue to step 8b. Add observations to PR comment context.
- `SKIPPED` → log "[SKIP] browser verification ({reason})", continue to step 8b.
```

**With:**

```
- `VERIFIED` → log "[PASS] browser verification", continue to step 8c.
- `PARTIAL` → log "[WARN] browser verification partial: {observations}", continue to step 8c. Add observations to PR comment context.
- `SKIPPED` → log "[SKIP] browser verification ({reason})", continue to step 8c.
```

#### T2g. Rename 8b to 8c (Acceptance gate)

**Replace:**

```
### 8b. Acceptance gate (conditional)
```

**With:**

```
### 8c. Acceptance gate (conditional)
```

**Also update** the forward reference inside 8c (Acceptance gate):

**Replace:**

```
If condition is not met → skip to step 8c.
```

**With:**

```
If condition is not met → skip to step 8d.
```

#### T2h. Rename 8c and 8d (Pre-publish hook, Pre-publish custom agent)

**Replace:**

```
### 8c. Pre-publish hook
```

**With:**

```
### 8d. Pre-publish hook
```

**Replace:**

```
### 8d. Pre-publish custom agent
```

**With:**

```
### 8e. Pre-publish custom agent
```

#### T2i. Update decomposition skip-forward reference

The current line 222 says:

```
After completing decomposition (including integration step and squash), skip to step 8c (Pre-publish hook).
```

**Replace with:**

```
After completing decomposition (including integration step and squash), skip to step 8d (Pre-publish hook).
```

---

### T3. Pipeline-level guard: `skills/fix-bugs/SKILL.md`

**File:** `skills/fix-bugs/SKILL.md`
**Dependencies:** None

#### T3a. Add Local Deployment config reading

**Replace:**

```
- **Agent Overrides** from Agent Overrides section (if it exists):
  - Path (default: `customization/`)
- **Browser Verification** from Browser Verification section (if it exists):
```

(This is in fix-bugs — lines 43-45)

**With:**

```
- **Agent Overrides** from Agent Overrides section (if it exists):
  - Path (default: `customization/`)
- **Local Deployment** from Local Deployment section (if it exists):
  - Type (default: `docker`), Start command (default: `docker compose up -d`), Stop command (default: `docker compose down`), Health check URL (default: `http://localhost:3000/health`), Health check timeout (default: 60), Ports (default: none)
  - If section absent → `local_deployment_configured = false`
- **Browser Verification** from Browser Verification section (if it exists):
```

#### T3b. Update stage mapping

**Replace:**

```
- `e2e-test-engineer` = step 7a (E2E test-engineer)
- `reproducer` = step 3e (Browser Reproduction)
- `browser-verifier` = step 7a-browser (Browser Verification)
```

**With:**

```
- `e2e-test-engineer` = step 7b (E2E test-engineer)
- `reproducer` = step 3e (Browser Reproduction)
- `browser-verifier` = step 7b-browser (Browser Verification)
```

#### T3c. Update Extra stages reference

**Replace:**

```
- `Extra stages`: if it contains `e2e-test-engineer` → force step 7a even without the E2E Test config section
```

**With:**

```
- `Extra stages`: if it contains `e2e-test-engineer` → force step 7b even without the E2E Test config section
```

#### T3d. Update subtask loop (step 3c)

**Replace:**

```
8. If E2E Test section exists: run e2e-test-engineer.
9. Commit subtask:
```

(This is in fix-bugs — lines 188-189)

**With:**

```
8. If Local Deployment section exists AND E2E Test section exists: run deployment-verifier (Task tool, model: sonnet, action: start). On HEALTHY → continue. On UNHEALTHY/PORT_CONFLICT/START_FAILED → Block handler.
9. If E2E Test section exists: run e2e-test-engineer.
10. Commit subtask:
```

#### T3e. Insert new step 7a-deploy before existing 7a

**Replace:**

```
Update `.ceos-agents/{ISSUE-ID}/state.json`: set `test.status` to `"completed"` (or `"blocked"` on failure), increment `test.attempts`, set `test.last_result` to `"PASSED"` or `"FAILED"`. Follow atomic write protocol from `core/state-manager.md`.

### 7a. E2E test-engineer
```

**With:**

```
Update `.ceos-agents/{ISSUE-ID}/state.json`: set `test.status` to `"completed"` (or `"blocked"` on failure), increment `test.attempts`, set `test.last_result` to `"PASSED"` or `"FAILED"`. Follow atomic write protocol from `core/state-manager.md`.

### 7a-deploy. Deployment guard (pre-E2E)

If `local_deployment_configured = false` → skip.
If stage `e2e-test-engineer` is in the profile's Skip stages → skip (no E2E = no deployment needed).
If the E2E Test section is absent AND `e2e-test-engineer` is NOT in the profile's `Extra stages` → skip.

Run `ceos-agents:deployment-verifier` (Task tool, model: sonnet).
Context: `Action: start. Local Deployment config: Type = {Type}, Start command = {Start command}, Stop command = {Stop command}, Health check URL = {Health check URL}, Health check timeout = {Health check timeout}, Ports = {Ports}. Run directory: .ceos-agents/{ISSUE-ID}/`

Read Agent Overrides path from Automation Config (default: `customization/`). If `{Agent Overrides path}/deployment-verifier.md` exists, append its contents to the agent context as `## Project-Specific Instructions\n{file content}`.

Verdict handling:
- `HEALTHY` or `SKIPPED` → continue to step 7b (E2E test-engineer)
- `UNHEALTHY`, `PORT_CONFLICT`, `START_FAILED` → proceed to Block handler (step X)

Update `.ceos-agents/{ISSUE-ID}/state.json`: write `deployment.verdict`, `deployment.type`, `deployment.result_path`. Follow atomic write protocol from `core/state-manager.md`.

### 7b. E2E test-engineer
```

#### T3f. Rename 7a-browser to 7b-browser and update forward references

**Replace:**

```
### 7a-browser. Browser Verification
```

**With:**

```
### 7b-browser. Browser Verification
```

**Replace** (3 occurrences in the Browser Verification verdict handling — lines 301-303):

```
- `VERIFIED` → log "[PASS] browser verification", continue to step 7b.
- `PARTIAL` → log "[WARN] browser verification partial: {observations}", continue to step 7b. Add observations to PR comment context.
- `SKIPPED` → log "[SKIP] browser verification ({reason})", continue to step 7b.
```

**With:**

```
- `VERIFIED` → log "[PASS] browser verification", continue to step 7c.
- `PARTIAL` → log "[WARN] browser verification partial: {observations}", continue to step 7c. Add observations to PR comment context.
- `SKIPPED` → log "[SKIP] browser verification ({reason})", continue to step 7c.
```

#### T3g. Rename 7b to 7c (Acceptance gate)

**Replace:**

```
### 7b. Acceptance gate (conditional)
```

**With:**

```
### 7c. Acceptance gate (conditional)
```

**Also update** the forward reference inside 7c:

**Replace:**

```
If condition is not met → skip to step 7c.
```

**With:**

```
If condition is not met → skip to step 7d.
```

#### T3h. Rename 7c and 7d (Pre-publish hook, Pre-publish custom agent)

**Replace:**

```
### 7c. Pre-publish hook
```

**With:**

```
### 7d. Pre-publish hook
```

**Replace:**

```
### 7d. Pre-publish custom agent
```

**With:**

```
### 7e. Pre-publish custom agent
```

#### T3i. Update decomposition skip-forward reference

**Replace:**

```
After completing decomposition (including integration step and squash), skip to step 7c (Pre-publish hook).
```

**With:**

```
After completing decomposition (including integration step and squash), skip to step 7d (Pre-publish hook).
```

---

### T4. Pipeline-level guard: `skills/implement-feature/SKILL.md`

**File:** `skills/implement-feature/SKILL.md`
**Dependencies:** None

#### T4a. Add Local Deployment config reading

**Replace:**

```
- Agent Overrides: Path (default: `customization/`)

## Flag parsing
```

**With:**

```
- Agent Overrides: Path (default: `customization/`)
- Local Deployment (if it exists): Type (default: `docker`), Start command (default: `docker compose up -d`), Stop command (default: `docker compose down`), Health check URL (default: `http://localhost:3000/health`), Health check timeout (default: 60), Ports (default: none). If section absent → `local_deployment_configured = false`

## Flag parsing
```

#### T4b. Update stage mapping

**Replace:**

```
- `e2e-test-engineer` = step 6f (E2E test-engineer)
```

**With:**

```
- `e2e-test-engineer` = step 6g (E2E test)
```

#### T4c. Insert new step 6f-deploy and rename 6f to 6g

**Replace:**

```
#### 6f. E2E test (optional)

If stage `e2e-test-engineer` is in the profile's Skip stages → skip, record "[SKIP] e2e-test-engineer (profile: {name})".

If the E2E Test section exists in Automation Config OR the profile's `Extra stages` contains `e2e-test-engineer`:
Run the e2e-test-engineer agent (Task tool, model: sonnet).

#### 6g. Acceptance gate (always for features)
```

**With:**

```
#### 6f-deploy. Deployment guard (pre-E2E)

If `local_deployment_configured = false` → skip.
If stage `e2e-test-engineer` is in the profile's Skip stages → skip (no E2E = no deployment needed).
If the E2E Test section is absent AND `e2e-test-engineer` is NOT in the profile's `Extra stages` → skip.

Run `ceos-agents:deployment-verifier` (Task tool, model: sonnet).
Context: `Action: start. Local Deployment config: Type = {Type}, Start command = {Start command}, Stop command = {Stop command}, Health check URL = {Health check URL}, Health check timeout = {Health check timeout}, Ports = {Ports}. Run directory: .ceos-agents/{ISSUE-ID}/`

Read Agent Overrides path from Automation Config (default: `customization/`). If `{Agent Overrides path}/deployment-verifier.md` exists, append its contents to the agent context as `## Project-Specific Instructions\n{file content}`.

Verdict handling:
- `HEALTHY` or `SKIPPED` → continue to step 6g (E2E test)
- `UNHEALTHY`, `PORT_CONFLICT`, `START_FAILED` → proceed to step X (Block handler)

Update `state.json`: write `deployment.verdict`, `deployment.type`, `deployment.result_path`. Follow atomic write protocol from `core/state-manager.md`.

#### 6g. E2E test (optional)

If stage `e2e-test-engineer` is in the profile's Skip stages → skip, record "[SKIP] e2e-test-engineer (profile: {name})".

If the E2E Test section exists in Automation Config OR the profile's `Extra stages` contains `e2e-test-engineer`:
Run the e2e-test-engineer agent (Task tool, model: sonnet).

#### 6h. Acceptance gate (always for features)
```

#### T4d. Update acceptance gate forward references and rename 6h

**Replace:**

```
If APPROVE → continue to step 6h.
```

**With:**

```
If APPROVE → continue to step 6i.
```

**Replace:**

```
#### 6h. Commit subtask
```

**With:**

```
#### 6i. Commit subtask
```

---

### T5. Pipeline-level guard: `skills/scaffold/SKILL.md`

**File:** `skills/scaffold/SKILL.md`
**Dependencies:** None

#### T5a. Replace Step 8 content with deployment guard

**Replace:**

```
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

**With:**

````
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
````

---

### T6. CHANGELOG entry: `CHANGELOG.md`

**File:** `CHANGELOG.md`
**Dependencies:** None

#### T6a. Insert new entry before 6.1.9

**Replace:**

```
## [6.1.9] — 2026-04-03
```

**With:**

```
## [6.2.0] — 2026-04-04

**MINOR** — E2E Test Engineer deployment guard. Prevents E2E tests from running against a non-running application by dispatching deployment-verifier before e2e-test-engineer.

### Added
- **e2e-test-engineer Step 3 (Deployment Pre-Flight):** New step checks Local Deployment config before E2E test execution. If configured, dispatches deployment-verifier with action: start. On HEALTHY proceeds; on UNHEALTHY/PORT_CONFLICT/START_FAILED blocks with diagnostic message. If not configured, emits warning and proceeds. Existing steps 3-8 renumbered to 4-9.
- **fix-ticket Step 8a-deploy:** Pipeline-level deployment guard before E2E test-engineer dispatch. Dispatches deployment-verifier when Local Deployment is configured. Existing steps 8a/8a-browser renumbered to 8b/8b-browser. Steps 8b/8c/8d renumbered to 8c/8d/8e.
- **fix-bugs Step 7a-deploy:** Same deployment guard for fix-bugs pipeline. Existing steps 7a/7a-browser renumbered to 7b/7b-browser. Steps 7b/7c/7d renumbered to 7c/7d/7e.
- **implement-feature Step 6f-deploy:** Same deployment guard for implement-feature pipeline. Existing steps 6f-6h renumbered to 6g-6i.
- **scaffold Step 8 (Deployment guard):** Pre-E2E deployment guard in scaffold pipeline. Warning-only on failure (no block — features already committed).
- **fix-ticket, fix-bugs, implement-feature Configuration:** Local Deployment config reading added to Configuration section.
- **e2e-test-engineer Constraint:** New constraint requiring deployment pre-flight before test infrastructure check.

## [6.1.9] — 2026-04-03
```

---

### T7. Version bump: `.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json`

**File 1:** `.claude-plugin/plugin.json`
**File 2:** `.claude-plugin/marketplace.json`
**Dependencies:** None

#### T7a. plugin.json

**Replace:**

```
"version": "6.1.9"
```

**With:**

```
"version": "6.2.0"
```

#### T7b. marketplace.json

**Replace:**

```
"version": "6.1.9"
```

**With:**

```
"version": "6.2.0"
```

---

### T8. Roadmap update: `docs/plans/roadmap.md`

**File:** `docs/plans/roadmap.md`
**Dependencies:** None

#### T8a. Move roadmap item from PLANNED to DONE

**Remove** the entire section from `## PLANNED -- Next` (lines 322-336):

```
### E2E Test Engineer: Deployment Guard — v6.2.0 (agent fix)
**Source:** User feedback (2026-04-04) — e2e-test-engineer has "NEVER run without a live application" rule but no automatic check

**Problem:** `e2e-test-engineer` agent blindly runs `pnpm test:e2e` (or configured E2E command). If the app isn't running, Playwright gets `connection refused`, and the agent reports it as a test failure — not as a missing configuration. The user has to debug why "tests fail" when the real issue is no running app.

**Fix — 3-step pre-flight in e2e-test-engineer agent:**
1. Check if `### Local Deployment` section exists in Automation Config
2. If YES → dispatch `deployment-verifier` agent before running tests (start app, verify health)
3. If NO → emit warning: "E2E tests require a running application, but Local Deployment is not configured. Configure it via `/onboard --update` or start the app manually before running E2E tests."

Also update the pipeline skills (`fix-ticket`, `fix-bugs`, `implement-feature`, `scaffold`) to call deployment-verifier before e2e-test-engineer when Local Deployment is configured.

**Files:** `agents/e2e-test-engineer.md`, `skills/fix-ticket/SKILL.md`, `skills/fix-bugs/SKILL.md`, `skills/implement-feature/SKILL.md`, `skills/scaffold/SKILL.md`

---
```

**Insert** new DONE section after `## DONE -- v6.1.9` section (after line 299, before the `---` preceding `## DONE -- v6.0.0`):

```
---

## DONE — v6.2.0 (E2E Deployment Guard)

### E2E Test Engineer: Deployment Guard
**Source:** User feedback (2026-04-04) — e2e-test-engineer has "NEVER run without a live application" rule but no automatic check

Two-level guard preventing E2E tests from running against a dead application:
1. **Agent-level** — pre-flight check inside `e2e-test-engineer.md` step 3 (safety net)
2. **Pipeline-level** — deployment-verifier dispatch before e2e-test-engineer in 4 skill files (proactive start)

**Files:** `agents/e2e-test-engineer.md`, `skills/fix-ticket/SKILL.md`, `skills/fix-bugs/SKILL.md`, `skills/implement-feature/SKILL.md`, `skills/scaffold/SKILL.md`
```

#### T8b. Update version header

**Replace:**

```
> **Current version:** v6.1.9
```

**With:**

```
> **Current version:** v6.2.0
```

---

## Dependency Graph

```
T1 (e2e-test-engineer agent)     ─── independent
T2 (fix-ticket skill)            ─── independent
T3 (fix-bugs skill)              ─── independent
T4 (implement-feature skill)     ─── independent
T5 (scaffold skill)              ─── independent
T6 (CHANGELOG)                   ─── independent
T7 (version bump)                ─── independent
T8 (roadmap)                     ─── independent
```

All 8 tasks are **fully independent** — they modify different files with no cross-file dependencies. They can all run in parallel.

---

## Execution Order

**Wave 1 (parallel):** T1, T2, T3, T4, T5, T6, T7, T8

All tasks modify separate files. No sequential dependencies exist.

Within each task, sub-steps (a, b, c...) MUST be applied in order because later edits depend on earlier edits changing line numbers. Specifically:
- T2: Apply T2a before T2e (config section before new step), and apply T2e before T2f/T2g/T2h (renaming depends on the new step being inserted)
- T3: Same ordering as T2
- T4: Apply T4a before T4c

---

## Verification Steps

After all tasks complete, run these checks:

### V1. Structural tests
```bash
./tests/harness/run-tests.sh
```
All tests must pass (exit code 0).

### V2. Agent step count
Read `agents/e2e-test-engineer.md` — Process section must have exactly 9 numbered steps (1-9). Step 3 must be "Deployment pre-flight".

### V3. fix-ticket step sequence
Search `skills/fix-ticket/SKILL.md` for `### 8` headings. Expected sequence:
- `### 8. Test-engineer`
- `### 8a-deploy. Deployment guard (pre-E2E)`
- `### 8b. E2E test-engineer`
- `### 8b-browser. Browser Verification`
- `### 8c. Acceptance gate (conditional)`
- `### 8d. Pre-publish hook`
- `### 8e. Pre-publish custom agent`

### V4. fix-bugs step sequence
Search `skills/fix-bugs/SKILL.md` for `### 7` headings (after step 7). Expected sequence:
- `### 7. Test-engineer`
- `### 7a-deploy. Deployment guard (pre-E2E)`
- `### 7b. E2E test-engineer`
- `### 7b-browser. Browser Verification`
- `### 7c. Acceptance gate (conditional)`
- `### 7d. Pre-publish hook`
- `### 7e. Pre-publish custom agent`

### V5. implement-feature step sequence
Search `skills/implement-feature/SKILL.md` for `#### 6` headings. Expected sequence:
- `#### 6e. Test-engineer`
- `#### 6f-deploy. Deployment guard (pre-E2E)`
- `#### 6g. E2E test (optional)`
- `#### 6h. Acceptance gate (always for features)`
- `#### 6i. Commit subtask`

### V6. scaffold deployment guard
Read `skills/scaffold/SKILL.md` Step 8. Must contain "Deployment guard:" sub-section with warning-only behavior before the e2e-test-engineer dispatch.

### V7. Version consistency
Verify both `.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json` show `"6.2.0"`.

### V8. CHANGELOG entry
Verify `CHANGELOG.md` has `## [6.2.0]` entry with `### Added` section listing all 7 changes.

### V9. Roadmap
Verify `docs/plans/roadmap.md`: "Deployment Guard" must appear in a DONE section, not in PLANNED.

### V10. No unintended changes
Run `git diff` and verify only these 9 files are modified:
1. `agents/e2e-test-engineer.md`
2. `skills/fix-ticket/SKILL.md`
3. `skills/fix-bugs/SKILL.md`
4. `skills/implement-feature/SKILL.md`
5. `skills/scaffold/SKILL.md`
6. `CHANGELOG.md`
7. `.claude-plugin/plugin.json`
8. `.claude-plugin/marketplace.json`
9. `docs/plans/roadmap.md`

### V11. Forward reference integrity
For each renamed step, grep the entire file for old step number references:
- `skills/fix-ticket/SKILL.md`: no remaining references to "step 8a" (except 8a-deploy), "step 8a-browser", old "step 8b" (should be 8c now), old "step 8c" (should be 8d now), old "step 8d" (should be 8e now)
- `skills/fix-bugs/SKILL.md`: same pattern for 7a/7b/7c/7d series
- `skills/implement-feature/SKILL.md`: no remaining references to old "step 6f" (except 6f-deploy), old "step 6g" (should be 6h), old "step 6h" (should be 6i)

### V12. No changes to protected files
Verify zero diff on:
- `agents/deployment-verifier.md`
- `skills/check-deploy/SKILL.md`
- `core/config-reader.md`
