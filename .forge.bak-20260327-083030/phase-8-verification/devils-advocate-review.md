# Devil's Advocate Review

Reviewer: Claude Opus 4.6 (1M context)
Date: 2026-03-26
Scope: Phase 8 implementation — scaffold auto-finalize, --description flag, check-deploy, config validity gate, /status readiness, workflow-router rename, deployment-verifier agent

---

## Scenario 1: Scaffold Auto-Finalize Corrupts CLAUDE.md on Partial User Input (Step 4b)

### Steps

1. User runs `/ceos-agents:scaffold "task management app"` in Interactive mode.
2. Steps 1-4 succeed: spec is written, skeleton is scaffolded, git init commits the skeleton.
3. Step 4b begins: the scaffolder-generated CLAUDE.md contains `<!-- TODO: -->` markers in Issue Tracker (Instance, Project) and Source Control (Remote).
4. The command prompts the user for each incomplete key sequentially.
5. User provides a valid Instance URL (`https://youtrack.example.com`) and Project (`PROJ`) but presses Enter (skip) for Source Control > Remote.
6. Step 4b writes the Instance and Project values into CLAUDE.md via the Edit tool, replacing `<!-- TODO: ... -->` markers.
7. The Source Control > Remote row still has the original `<!-- TODO: set your owner/repo -->` marker.
8. Step 4b commits: `git add CLAUDE.md && git commit -m "chore: configure Automation Config"`.
9. Step 4c fires because Instance was filled: it displays "To connect to youtrack at https://youtrack.example.com, configure an MCP server."
10. Pipeline continues to Step 5 (Architecture & Decomposition). The generated CLAUDE.md has a mix of real and TODO values.
11. Step 7 (Feature Implementation Loop) reads Build & Test config from the generated CLAUDE.md. The scaffolder sets Build and Test commands, so this works.
12. Step 9 (Issue Tracker, optional): checks for TODO markers in Issue Tracker Instance — finds none (it was filled). But Source Control > Remote still has a TODO marker.
13. Step 9 says "tracker configured" (because the Instance and Project are real), and in Interactive mode asks "Create cards in issue tracker for implemented features?"
14. User says "Y". MCP call to create issues succeeds (tracker is configured).
15. **But the PR cannot be created by downstream `/implement-feature` calls** because Source Control > Remote is still a TODO.
16. Later, when user runs `/ceos-agents:implement-feature PROJ-1`, the new Config Validity Gate (Step 0b) catches the incomplete Remote and blocks. But the user is confused: scaffold told them MCP was set up and even created tracker cards.

### What breaks

The scaffold auto-finalize creates a **false sense of completeness**. Step 4c's MCP guidance triggers only when Instance is filled, giving the impression the project is ready. Step 9 creates real tracker cards even though Source Control is incomplete. The Final Report (Step 10) does list "Remaining TODOs in CLAUDE.md", but by that point the user has already created tracker cards against a half-configured project. The next pipeline command (`implement-feature` or `fix-ticket`) will refuse to run due to Step 0b, but the user already has orphaned tracker cards.

This is not a data-loss bug, but it is a **UX consistency failure**: the scaffold pipeline creates real side effects (tracker cards) in a project whose config is known to be incomplete.

### Severity: MEDIUM

The incomplete config is caught by Step 0b before any code damage occurs. But orphaned tracker cards and user confusion are real costs. The fix is straightforward: Step 9 should check ALL required sections (not just Issue Tracker > Instance) for TODO markers before offering to create cards. Alternatively, Step 4b should warn explicitly after the commit: "Source Control > Remote is still incomplete — downstream pipelines will not run until this is filled."

### Recommendation

Add a guard at the top of Step 9: "If ANY required section (Issue Tracker, Source Control, PR Rules, Build & Test) still has TODO markers, skip card creation and note it in the report." This aligns Step 9 with the same completeness standard used by Step 0b in implement-feature/fix-ticket.

---

## Scenario 2: --description Flag Creates a Duplicate or Misaligned Tracker Card

### Steps

1. User has a fully configured project. CLAUDE.md Automation Config is complete.
2. User says naturally: "I want to add CSV export to the reports page" via the workflow-router skill.
3. workflow-router matches the intent to `ceos-agents:implement-feature --description "add CSV export to the reports page"`.
4. workflow-router shows the user: "I will run implement-feature with --description. The extracted description is: 'add CSV export to the reports page'. Confirm?" User confirms.
5. implement-feature Step 0b (Config Validity Gate) passes.
6. Step 0c fires: extracts title as "Add CSV export to the reports page" (first sentence, under 80 chars).
7. In non-YOLO mode, the card preview is shown. User confirms.
8. MCP creates issue `PROJ-42` with title "Add CSV export to the reports page" and description "add CSV export to the reports page".
9. Pipeline proceeds with `PROJ-42` as the Issue ID.
10. **Problem path A — duplicate:** The tracker already has `PROJ-31` titled "Export reports to CSV" that was manually created last week. The --description flow has no duplicate check. Now there are two overlapping features in the tracker.
11. **Problem path B — description too terse:** User says "dark mode". workflow-router extracts `--description "dark mode"`. Step 0c creates a card with title "Dark mode" and description "dark mode". The spec-analyst (Step 3) receives an extremely minimal issue description with no context about which UI components, color schemes, or user preferences are involved. Spec-analyst produces a vague specification, architect produces a vague task tree, and the fixer implements a half-baked dark mode that doesn't match what the user actually wanted.
12. **Problem path C — workflow-router misinterpretation:** User says "Can we make the login page faster?" The workflow-router sees no issue ID and routes to `--description "make the login page faster"`. But this is a performance bug, not a feature. It should have been `fix-ticket` with a new bug card, not `implement-feature` with a feature card. The created tracker card is labeled as "Feature" but the work is a performance optimization on existing code.

### What breaks

The `--description` flag bypasses the human curation step that normally happens when someone manually creates a tracker card. Three things go wrong:

1. **No duplicate detection.** Step 0c creates the card blindly. Unlike manual card creation (where a human would search first), the automated path has no dedup mechanism. Over time this pollutes the tracker.
2. **Garbage in, garbage out.** The description quality directly determines spec-analyst output quality. A two-word description produces a two-sentence spec, which produces a shallow task tree. The pipeline happily runs to completion and creates a PR for code that doesn't match the user's mental model.
3. **Misrouted intent.** workflow-router's distinction between "feature to build" and "bug to fix" is a heuristic based on natural language. Performance issues, refactoring requests, and ambiguous asks will frequently be misrouted, creating cards with the wrong type in the tracker.

### Severity: HIGH

Problem path A (duplicates) accumulates silently and creates tracker noise. Problem path B (terse descriptions) wastes pipeline tokens on bad output and produces PRs that need to be reverted. Problem path C (misrouting) creates wrong-type cards that confuse team workflows. The combination of all three means that the `--description` → tracker card path will produce low-quality results for any input that is not already well-specified — which is precisely the input this feature is designed for.

### Recommendation

1. **Duplicate check:** Before creating the card in Step 0c, query the tracker for existing open issues whose title has >60% word overlap with the extracted title. If matches found, display them and ask "Did you mean one of these?" before creating a new card.
2. **Minimum description length:** If the extracted description is fewer than 15 words, prompt the user for more context before creating the card: "Your description is very brief. Can you add more detail about what this feature should do?"
3. **Intent confirmation in workflow-router:** When the distinction between bug-fix and feature is ambiguous, workflow-router should ask: "Is this a new feature or a fix for an existing issue?" rather than guessing based on language patterns.

---

## Scenario 3: check-deploy Leaves an Orphaned Background Process on Native Type Failure

### Steps

1. User has a project with Local Deployment config: `Type = native`, `Start command = node server.js`, `Ports = 3000`, `Health check URL = http://localhost:3000/health`, `Health check timeout = 30`.
2. User runs `/ceos-agents:check-deploy --start`.
3. Step 0: state.json initialized under `.ceos-agents/deploy-YYYYMMDD-HHmmss/`.
4. Step 1: Port check — port 3000 is free.
5. Step 2: action = start, no port conflict, proceeds to Step 3.
6. Step 3: deployment-verifier agent is dispatched.
7. Inside the agent, Process step 4 (Start app, Type = native): runs `node server.js` via Bash with `run_in_background`.
8. Agent waits 3 seconds, then proceeds to health check polling.
9. The `node server.js` process starts but has a startup error that doesn't crash the process — it binds to port 3000 but returns HTTP 500 on `/health` due to a missing database connection.
10. Health check polling runs for 30 seconds (Health check timeout). Every poll gets HTTP 500. Timeout expires.
11. Agent sets `health: UNHEALTHY`, verdict: `UNHEALTHY`.
12. Agent writes `result.json`, outputs the Deployment Verification Report.
13. Step 4: check-deploy displays the report: "Verdict: UNHEALTHY".
14. Step 5: state.json updated with `deployment.verdict = "UNHEALTHY"`.
15. **The node server.js process is still running on port 3000.** The agent never stops it after an UNHEALTHY verdict.
16. User reads the report, sees UNHEALTHY, fixes the database config, and runs `/ceos-agents:check-deploy --start` again.
17. Step 1: Port check — port 3000 is OCCUPIED by the old node process.
18. Step 2: Port is occupied → "Port 3000 is occupied by node (PID: 12345). Free the port first or use --stop to stop the current deployment."
19. Now the user must manually run `--stop` or kill the process. But the Stop command in config is whatever was configured (e.g., `kill $(lsof -t -i:3000)`), and if the user configured something Docker-specific like `docker compose down` for the Stop command (copy-paste error mixing docker and native), the stop will fail silently.

### What breaks

The deployment-verifier agent has a **start-but-never-cleanup** gap for native-type deployments:

1. **No rollback on UNHEALTHY.** The agent's Process step 4 starts the app, step 5 checks health, but if health is UNHEALTHY, the agent proceeds directly to step 8 (verdict) without stopping the process it started. There is no "on failure, stop what you started" logic. Docker deployments are slightly better because `docker compose ps` makes it obvious, but native processes become orphans.

2. **State file claims "completed" despite orphan.** The state.json shows `status: "completed"` and `deployment.verdict: "UNHEALTHY"`. There is no record that a background process was started and left running. The `/status` command's Configuration Readiness section does not check for orphaned deployment processes.

3. **Cross-platform PID tracking gap.** The agent starts native processes with `run_in_background` but never records the PID. On the next `--start` attempt, the port check catches the conflict, but the error message says "Free the port first" without providing the PID or a kill command. On Windows (the actual runtime platform per env info), `lsof` is unavailable, so the port check falls back to `netstat -ano | findstr :{port}` which shows the PID but the agent doesn't extract or surface it helpfully.

4. **check-deploy --stop may not work for native.** The deployment-verifier's Process step 7 (Stop app) runs the configured Stop command and then verifies ports are freed. But for native deployments, there is no standard stop command — the user must configure one explicitly. If they configured `docker compose down` by mistake (or left the default), `--stop` does nothing useful for a native process. The agent reports "Stop command completed but ports are still occupied" but takes no further action. The user is stuck with a zombie process.

### Severity: HIGH

This scenario leaves real OS processes running that consume ports and resources. The failure mode is self-reinforcing: UNHEALTHY verdict → orphaned process → port conflict on retry → user must manually debug process management. On CI servers or shared dev machines, orphaned processes can accumulate across multiple check-deploy attempts, eventually exhausting ports or memory. The lack of PID tracking means there is no automated cleanup path.

### Recommendation

1. **Add cleanup-on-failure to the agent:** After an UNHEALTHY or START_FAILED verdict for native deployments, if the agent started the process (action = start), it MUST attempt to stop it using the configured Stop command. Add a Process step 5b: "If health check fails and action was start, run Stop command before writing verdict."
2. **Record PID:** When starting a native process with `run_in_background`, capture the PID from `$!` and write it to `result.json` as `"pid": {pid}`. This enables `--stop` to `kill {pid}` as a fallback if the Stop command fails.
3. **Validate Stop command at config time:** In check-deploy Step 0 or in `check-setup`, validate that the Stop command is compatible with the Type. If Type = native and Stop command contains `docker`, warn: "Stop command appears to be Docker-specific but Type is native."
4. **Add --stop hint to UNHEALTHY output:** When verdict is UNHEALTHY and action was start, append to the report: "A process was started on port {port}. Run `/ceos-agents:check-deploy --stop` to clean up, or manually kill PID {pid}."

---

## Cross-Cutting Observations

### Config Validity Gate (Step 0b) — Potential False Positive

The `<...>` placeholder detection in Step 0b is underspecified. If a legitimate config value contains angle brackets (e.g., a Branch naming pattern like `<type>/<id>-<slug>` which is a common convention), Step 0b will flag it as an incomplete placeholder and block the pipeline. The pattern `<...>` is too broad. The check should be limited to `<!-- TODO:` HTML comments only, or require that `<...>` appears as the entire cell value (not as part of a larger string).

### Skill Rename — No Backward Compatibility

The skill was renamed from `bug-workflow` to `workflow-router`. If any user's muscle memory, documentation, or external tooling references the old name `bug-workflow`, it will silently fail. There is no alias or deprecation redirect. This is a minor issue since skills are invoked by Claude Code's matching system (not by exact name), but it could affect programmatic callers.

---

## Score: 0.65 / 1.0

The implementation is architecturally sound — the new features (auto-finalize, --description, check-deploy, config validity gate) fill real gaps in the user experience. The config validity gate in particular is a significant improvement that prevents many classes of runtime errors.

However, the three scenarios above reveal that the implementation handles the **happy path well but underspecifies failure and edge-case behavior**:

- Scaffold auto-finalize allows side effects (tracker card creation) in a partially configured state.
- The --description flag has no guardrails against duplicates, terse input, or misrouted intent — all of which are predictable for the natural-language input it is designed to accept.
- check-deploy can start processes it never cleans up, with no PID tracking and no automated recovery path.

Scenario 2 (--description) and Scenario 3 (check-deploy orphan) are both HIGH severity because they create real-world side effects (polluted tracker, orphaned processes) that require manual intervention to resolve. Scenario 1 (scaffold auto-finalize) is MEDIUM because the downstream damage is caught by Step 0b, but the UX confusion is still meaningful.

The score of 0.65 reflects: good architectural choices and correct happy-path behavior (0.8 baseline), minus 0.05 for each HIGH-severity scenario and 0.025 for each MEDIUM scenario, minus 0.05 for the cross-cutting `<...>` false-positive risk and skill rename gap.
