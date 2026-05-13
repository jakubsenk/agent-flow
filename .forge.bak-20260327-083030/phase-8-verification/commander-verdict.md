# Commander Verification Report

**Date:** 2026-03-26
**Scope:** v5.3.0 (Phase 1) + v5.4.0 (Phase 2) scaffold-to-deployment workflow
**Reviewer:** Adversarial code review (Claude Opus 4.6)

---

## Per-File Findings

### 1. `commands/scaffold.md` — Steps 4b, 4c, Step 10

**Verdict: PASS (minor observations)**

- **Step 4b (Tracker Configuration):** Complete. Full YOLO correctly skips. TODO marker scanning, user prompting, and commit flow are all well-specified. Edit tool instruction for replacing markers is explicit.
- **Step 4c (MCP Guidance):** Complete. Correctly conditional on Step 4b outcome. Informational-only, non-blocking. Good.
- **Step 10 (Final Report):** Complete. Includes TODOs-remaining section and conditional next-steps. State update to `"completed"` is present.
- **Observation:** `parent_run_id` is set during fixer-reviewer iteration (line 413) which is an odd place for it -- it should be set during state initialization at Step 0, not mid-loop. Currently, if a scaffold run has no subtasks reaching the fixer-reviewer loop, `parent_run_id` is never set. This is not technically a bug (the field defaults to null) but is inconsistent with the state schema description which says "Set when scaffold creates sub-runs for feature implementation."

### 2. `commands/implement-feature.md` — Steps 0b, 0c

**Verdict: PASS**

- **Step 0b (Config Validity Gate):** Complete. Scans required sections for `<!-- TODO:` and `<...>` placeholders. BLOCK output follows the standard Block Comment Template. Optional section warnings are non-blocking. Flow to Step 0c is explicit.
- **Step 0c (Feature from Description):** Complete. Mutual exclusivity with Issue ID is validated. Card preview in non-YOLO mode. MCP failure has a proper BLOCK path. `$ISSUE_ID` is set from created card. Proceeds to Step 1.
- No missing error handling paths detected.

### 3. `commands/fix-ticket.md` — Step 0b

**Verdict: PASS**

- **Step 0b (Config Validity Gate):** Correctly references "same validation logic as implement-feature.md Step 0b." The inline specification is complete and matches implement-feature.md nearly verbatim. BLOCK message, optional section warning, and flow-through are all present.
- Consistent with implement-feature.md.

### 4. `commands/status.md` — Step 6b

**Verdict: ISSUE**

- **Step 6b (Configuration Readiness):** The table-based readiness output is well-designed. MCP connectivity soft-check and Build tooling check are non-blocking.
- **ISSUE-1: Duplicate step numbering.** Line 85 has a bare `5.` that reads "If configuration is incomplete, the FIRST item in `### Recommended Next Steps` must be..." This is step 5 AGAIN, but the original step 5 (line 27) is "Display table." This creates ambiguity. The "5." on line 85 should be renumbered or merged into Step 6b as a sub-step.
- **ISSUE-2: Step 7 numbering gap.** After Step 6b, the document jumps to step 7 (line 88). There is no step 6c or step 6a. While step 6 (totals) exists at line 37, the progression 5 -> 6 -> 6b -> 5(dup) -> 7 is confusing.
- The actual content of Step 6b (readiness checks) is correct and complete.

### 5. `commands/check-deploy.md`

**Verdict: ISSUE**

- **Completeness as standalone command:** The command is self-contained with configuration reading, flag parsing, all action paths (check/start/stop), port checking, health polling, Docker inspection, and a structured report. Good.
- **ISSUE-3: Orphaned agent.** The `deployment-verifier` agent exists in `agents/deployment-verifier.md` but is NEVER dispatched by `check-deploy.md`. The command handles all logic inline. The `Task` tool is listed in `allowed-tools` but never used. Line 156 in the Rules section even hedges: "if this command uses Task tool for the agent; in this design, the command handles logic directly." This creates a dead agent -- it exists but nothing invokes it. Either:
  (a) The command should dispatch the agent via Task (like every other command-agent pair in the plugin), or
  (b) The agent file should be removed (reducing agent count to 18), or
  (c) The command should use the agent for at least the start/stop actions while handling check-only inline.
- **ISSUE-4: `Task` in allowed-tools is misleading.** If the command never uses Task, it should be removed from `allowed-tools` to avoid confusion.
- **ISSUE-5: No state.json integration.** The command never initializes or updates `state.json`, despite the state schema defining a `deployment` object. The state schema says "Populated by deployment-verifier agent when /check-deploy runs" but nothing actually writes to it. The command has no `run_id`, no state initialization, and no state updates -- unlike every other pipeline command.
- **Observation:** Port check Bash snippet (lines 36-43) uses Unix-only tools (`lsof`, `ss`, `netstat`). The Rules section (line 154) says "Port check must work on Linux, macOS, and Windows (WSL/Git Bash)" but the snippet has no Windows/PowerShell fallback. The deployment-verifier agent (line 24) does mention Windows (`netstat -ano | findstr`) but the command does not. Inconsistent.

### 6. `agents/deployment-verifier.md`

**Verdict: ISSUE**

- **Frontmatter:** Correct (name, description, model: sonnet, style). Follows convention.
- **Section order:** Goal -> Expertise -> Process (numbered 1-10) -> Constraints. Correct base order.
- **ISSUE-6: Extra `## Output` section.** Lines 105-118 add an `## Output` section that is NOT part of the standard agent format (Goal -> Expertise -> Process -> Constraints). This violates the convention specified in CLAUDE.md's "Agent Definition Format" and "When Editing Agent Definitions" sections.
- **ISSUE-7: Duplicate and contradictory result.json schema.** Process step 9 (lines 69-79) defines a result.json with fields: `verdict`, `type`, `ports`, `health_check`, `containers`, `issues`. The Output section (lines 109-118) defines a DIFFERENT result.json with fields: `verdict`, `type`, `health_url`, `ports`, `started_at`, `verified_at`, `error`. The two schemas are incompatible -- `containers`/`issues` vs `started_at`/`verified_at`/`error`. An implementation would not know which to follow.
- **ISSUE-8: Agent is never invoked.** As noted in ISSUE-3, no command dispatches this agent. It is dead code.
- Constraints section is well-formed: all start with NEVER or define hard limits. Good.

### 7. `skills/workflow-router/SKILL.md`

**Verdict: PASS**

- **Intent table:** Complete. All 25 commands are represented (some via multiple intent rows). `check-deploy` has three intent rows (check, --start, --stop). `implement-feature` has two (with Issue ID, with description).
- **Feature routing logic (step 5):** Correctly distinguishes Issue ID patterns from free-text descriptions. Routes to `--description` flag when no ID pattern detected. Confirmation before `--description` use is specified.
- **Destructive classification:** `check-deploy` without flags is non-destructive (correct). `check-deploy --start/--stop` is destructive (correct).
- **Skill name:** `workflow-router` directory and frontmatter name match. Old "ceos" references are gone.
- No issues found.

### 8. `state/schema.md` — parent_run_id and deployment fields

**Verdict: ISSUE**

- **`parent_run_id`:** Present in both JSON example (line 34) and field definitions table (line 132). Description is clear: "Set when scaffold creates sub-runs for feature implementation." Consistent.
- **Deployment object:** JSON example (lines 112-122) and field definitions table (lines 203-211) are consistent with each other.
- **ISSUE-9: `deployment.status` and `deployment.verdict` are redundant.** Both accept the same values: `healthy`, `unhealthy`, `failed`. There is no documented difference between them. One should be removed, or their distinct semantics should be documented.
- **ISSUE-10: Deployment field values mismatch with deployment-verifier agent.** The agent uses verdicts: `HEALTHY`, `UNHEALTHY`, `PORT_CONFLICT`, `START_FAILED`, `SKIPPED`. The state schema uses: `healthy`, `unhealthy`, `failed`. The casing differs (UPPER vs lower), and the agent has two verdict values (`PORT_CONFLICT`, `START_FAILED`) that do not map to any value in the schema's deployment object. The agent also has `SKIPPED` which is not in the schema.
- **Pre-existing issue (not from this PR but worth noting): `browser_verification.verdict`** in the field definitions table says `PASS`, `FAIL`, `INCONCLUSIVE` but `fix-ticket.md` uses `VERIFIED`, `PARTIAL`, `FAILED`, `SKIPPED`. This is a pre-existing inconsistency but the same pattern appears to be repeating with the deployment fields.

### 9. `core/config-reader.md` — Local Deployment section

**Verdict: PASS**

- Local Deployment section (line 37) is properly defined with all 6 keys matching CLAUDE.md's optional sections table and check-deploy.md's required keys.
- Defaults are reasonable: Type=docker, Start=docker compose up -d, Stop=docker compose down, Health check URL=localhost:3000/health, Timeout=60, Ports=none.
- Local Deployment is correctly placed in the optional sections list (step 3), not required sections (step 4).
- Consistent with check-deploy.md and CLAUDE.md.

### 10. `CLAUDE.md` — Counts and consistency

**Verdict: PASS**

- **Agent count:** "19 agent definitions" (line 17). Actual file count: 19. MATCH.
- **Command count:** "25 commands" (line 18). Actual file count: 25. MATCH.
- **Command list (line 32):** 25 commands listed including `/check-deploy`. All have corresponding files.
- **Agent list (line 33):** 19 agents listed including `deployment-verifier`. All have corresponding files.
- **Model Selection table:** `deployment-verifier` correctly in sonnet row. `deployment` added to the "Used For" column.
- **Execution agents list (line 110):** `deployment-verifier` correctly included.
- **Optional sections table (line 154):** `Local Deployment` present with correct keys and default `(none)`.
- **Skill description (line 19):** Updated to `workflow-router`. Correct.
- No issues with counts or listings.

---

## Cross-Reference Integrity Summary

| Check | Status |
|-------|--------|
| Commands reference correct agent names | ISSUE -- check-deploy never invokes deployment-verifier |
| Agents reference correct config section names | PASS -- deployment-verifier references Local Deployment correctly |
| CLAUDE.md counts match file counts | PASS -- 19 agents, 25 commands confirmed |
| State schema matches command behavior | ISSUE -- deployment object never written; verdict values mismatched |
| Config reader matches CLAUDE.md optional table | PASS |
| Skill routes to all new commands | PASS |
| Convention compliance (frontmatter, sections) | ISSUE -- deployment-verifier has extra Output section |
| Error handling on all paths | PASS (except check-deploy has no state.json error path) |

---

## Issues That Must Be Fixed Before Release

### Critical (blocks release)

1. **ISSUE-3 + ISSUE-8: Orphaned deployment-verifier agent.** The agent exists but is never invoked by any command. This violates the plugin's 2-layer architecture (commands dispatch agents). Either:
   - Refactor `check-deploy.md` to dispatch the agent via Task tool for the start/stop actions, OR
   - Remove the agent and reduce the count to 18 in CLAUDE.md (simpler, since the command already handles all logic).

2. **ISSUE-5: No state.json integration in check-deploy.** Every other pipeline command initializes and updates state.json. check-deploy has no run_id, no state initialization, and never writes the `deployment` object that the state schema defines. Either add state management or remove the `deployment` object from state/schema.md.

3. **ISSUE-7: Contradictory result.json schemas in deployment-verifier.** Process step 9 and the Output section define incompatible JSON structures. One must be removed or reconciled.

### Non-Critical (should fix, not blocking)

4. **ISSUE-6: Convention violation in deployment-verifier.** Remove the `## Output` section. The result.json format should live only in Process step 9.

5. **ISSUE-1 + ISSUE-2: Step numbering in status.md.** Renumber the duplicate step 5 and clarify the 6->6b->7 progression.

6. **ISSUE-4: Remove `Task` from check-deploy.md allowed-tools** if the command never uses it.

7. **ISSUE-9: Redundant deployment.status/verdict fields** in state schema. Document the difference or remove one.

8. **ISSUE-10: Verdict value casing and enum mismatch** between deployment-verifier agent (UPPER, 5 values) and state schema (lower, 3 values).

9. **Observation: Windows port check missing** in check-deploy.md Bash snippet (agent has it, command does not).

10. **Observation: `parent_run_id` set in wrong place** in scaffold.md (during fixer loop instead of state init).

---

## Dimension Scores

| Dimension | Score | Rationale |
|-----------|-------|-----------|
| **Correctness** | 0.65 | Orphaned agent, contradictory schemas, no state.json integration in check-deploy, verdict enum mismatches |
| **Completeness** | 0.75 | All files exist, counts match, skill routing complete, config reader updated. But check-deploy is missing state management, and the agent-command link is broken |
| **Security** | 0.90 | No credential exposure risks. Port check and Docker commands are safe. NEVER constraints are well-placed. Minor gap: no Windows fallback in command (only in agent) |
| **Spec-Alignment** | 0.70 | Convention violation (extra Output section), 2-layer architecture violated (agent never dispatched), state schema defined but never written |

---

## Overall Verdict: FAIL

Three critical issues prevent release:
1. The deployment-verifier agent is dead code (never invoked by any command)
2. check-deploy has no state.json integration despite state schema defining deployment fields
3. The deployment-verifier agent contains contradictory result.json schemas

The Phase 1 additions (scaffold Steps 4b/4c, config validity gate, status readiness, parent_run_id) are solid and would pass independently. The Phase 2 additions (--description flag, workflow-router updates, config-reader Local Deployment) are also solid. The problem is concentrated in the check-deploy command and deployment-verifier agent pair, where the architectural link between command and agent is broken.
