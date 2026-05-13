# Research Question 2: Pipeline Engine Extraction

## Refined Question

What orchestration logic is shared across `fix-ticket.md`, `fix-bugs.md`, `implement-feature.md`, and `scaffold.md` such that it could be factored into a reusable pipeline engine, and what is genuinely mode-specific logic that must remain per-command? Specifically: can the fixer↔reviewer loop, block/rollback handler, hook execution, agent-override injection, pipeline-profile skip logic, MCP pre-flight check, and post-publish webhook be expressed once and reused — and what would that engine look like compared to the forge pipeline engine's Phase Execution Loop?

---

## Shared Patterns (found in 3+ commands)

### 1. Configuration Reading Block

All four pipeline commands open with an identical config-reading section that reads the same set of keys from `## Automation Config` in CLAUDE.md. The pattern is:

- `fix-ticket.md` lines 25–48: reads Type, Retry Limits (Fixer iterations/Test attempts/Build retries), Hooks, Custom Agents, Notifications, Decomposition (Max subtasks/Fail strategy/Commit strategy), Error Handling (On block), Extra labels, Agent Overrides (Path), Browser Verification (Base URL, Start command, On events, Timeout, Max pages, Screenshot storage, Exploration, Exploration max clicks)
- `fix-bugs.md` lines 16–41: identical set plus Worktrees (Batch size, Base path, Cleanup) and Max blocked per run
- `implement-feature.md` lines 12–31: identical set minus Browser Verification, plus Feature Workflow (Feature query, On start set)
- `scaffold.md` lines 487–490 (Rules section): Agent Overrides only (scaffold is config-light; it generates CLAUDE.md rather than reading a mature one)

The config-reading block is copy-pasted verbatim across the three issue-tracker commands. Every key has the same default value in each command.

### 2. MCP Pre-flight Check

All four commands include an identical MCP availability check before any pipeline operation:

- `fix-ticket.md` lines 73–78 (Step 0)
- `fix-bugs.md` lines 66–71 (Step 0)
- `implement-feature.md` lines 58–63 (Step 0)
- `scaffold.md` lines 473–483 (conditional: only when `--issue` flag or Step 9 tracker integration)

The check text is word-for-word identical in fix-ticket, fix-bugs, and implement-feature: read Type, check `mcp__*` tool, STOP with the same error message pointing to `check-setup` or `init`.

### 3. Pipeline Profile Parsing

All three issue-tracker commands parse `--profile <name>` identically:

- `fix-ticket.md` lines 50–71
- `fix-bugs.md` lines 43–64
- `implement-feature.md` lines 41–56

The parsing algorithm is identical (read Pipeline Profiles section, find matching row, extract Skip stages + Extra stages, error if not found). The stage names and step numbers differ per pipeline but the algorithm is the same. The restriction "NEVER skip fixer, reviewer, publisher" appears verbatim in all three.

### 4. Flag Parsing (decompose / dry-run / yolo / profile)

All three issue-tracker commands parse the same flag set:

- `fix-ticket.md` lines 10–13 (introductory block) + lines 117–122 (Step 4a)
- `fix-bugs.md` lines 10–12 (introductory block) + lines 105–110 (Step 3a)
- `implement-feature.md` lines 8, 34–39 (Flag parsing section)

The mapping is identical: `--decompose` → `FORCE`, `--no-decompose` → `DISABLED`, neither → `AUTO`. The `--yolo` auto-approve behavior is described in the same terms in fix-ticket and implement-feature (scaffold has its own mode selection).

### 5. Fixer↔Reviewer Loop

The loop structure is identical across all three issue-tracker commands and appears in scaffold's feature implementation loop (Step 7):

- `fix-ticket.md` lines 203–212 (Fixer, Step 5) + lines 233–238 (Reviewer, Step 7)
- `fix-bugs.md` lines 194–203 (Fixer, Step 4) + lines 223–228 (Reviewer, Step 6)
- `implement-feature.md` lines 168–188 (Steps 6b + 6d)
- `scaffold.md` lines 343–355 (Steps 7a + 7b)

Pattern: Run fixer (opus) with `Max build retries` context → build → on failure retry up to Build retries → run reviewer (opus) with `Max fixer iterations` context → on REQUEST_CHANGES return to fixer → on iterations exhausted → Block handler. The loop cap "max {Fixer iterations} iterations" is stated identically.

### 6. Block Handler (Step X)

The block handler appears as "Step X" in all three issue-tracker commands:

- `fix-ticket.md` lines 347–377
- `fix-bugs.md` lines 351–387
- `implement-feature.md` lines 285–305
- `scaffold.md` lines 370–384 (inline, simplified variant without issue tracker)

Shared structure across fix-ticket, fix-bugs, implement-feature:
1. Run `rollback-agent` (haiku) — except on triage/code-analyst blocks
2. Set issue state to Blocked
3. Check Error Handling → On block (`comment`/`close`)
4. Add Block comment using the `[ceos-agents] 🔴 Pipeline Block` template
5. Fire `issue-blocked` webhook if configured

The Block comment template text is identical word-for-word. The only difference between fix-ticket and fix-bugs is step 6 (block counter for Max blocked per run, fix-bugs lines 383–387) and step 7 (continue with next bug). Scaffold's block handler is a reduced variant: no issue tracker updates, stdout only, follow Fail strategy.

### 7. Webhook Calls

Three webhook event types appear across commands using the same curl invocation pattern:

**pr-created** (in fix-ticket.md lines 309–313, fix-bugs.md lines 298–303, implement-feature.md lines 261–264):
```bash
curl --max-time 5 --retry 0 -X POST -H "Content-Type: application/json" \
  -d '{"event":"pr-created","issue_id":"{issue}","pr_url":"{url}","timestamp":"{ISO8601}"}' \
  "{Webhook URL}"
```

**issue-blocked** (in fix-ticket.md lines 372–377, fix-bugs.md lines 376–381, implement-feature.md lines 303–305):
Same curl structure, different payload.

**pipeline-complete** (fix-bugs.md lines 344–349 only — batch-specific).

### 8. Post-publish Hook

All three issue-tracker commands have an identical post-publish hook step:

- `fix-ticket.md` lines 303–305 (Step 9a)
- `fix-bugs.md` lines 291–294 (Step 8a)
- `implement-feature.md` lines 262–263 (Step 10a)

Pattern: If Hooks → Post-publish exists, run after publisher. Failure → warning only (cannot rollback, PR already exists).

### 9. Decomposition Logic (task tree + AC coverage check + subtask execution)

The decomposition evaluation heuristics, AC coverage check algorithm, and subtask execution loop are copied across fix-ticket and fix-bugs:

- `fix-ticket.md` lines 117–182 (Steps 4a–4c)
- `fix-bugs.md` lines 105–172 (Steps 3a–3c)
- `implement-feature.md` lines 104–148 (Step 5, decomposition decision)
- `scaffold.md` lines 285–303 (Step 5, AC coverage check per epic)

The heuristics `risk == HIGH`, `affected_files >= 4`, `estimated_diff_lines > 60 AND affected_files >= 3`, `independent_changes >= 2` appear identically in fix-ticket (lines 131–134) and fix-bugs (lines 121–124). The AC matching algorithm note (`maps_to format: AC-{N}: {text} — matching is by index N only`) appears in all four.

### 10. Agent Override Injection

All four commands carry the same instruction:

- `fix-ticket.md` lines 405–407 (Rules section)
- `fix-bugs.md` lines 484–485 (Rules section)
- `implement-feature.md` lines 313–314 (Rules section)
- `scaffold.md` lines 488–490 (Rules section)

Identical text: "Before dispatching any agent via Task tool, check if `{Agent Overrides path}/{agent-name}.md` exists. If yes, append its content to the agent's context as: `## Project-Specific Instructions\n{file content}`."

### 11. Fix Verification (Post-merge)

The post-merge verification flow appears in all three issue-tracker commands:

- `fix-ticket.md` lines 326–345 (Step 9d)
- `fix-bugs.md` lines 308–320 (Step 8c)
- `implement-feature.md` lines 270–282 (Step 10b)

Pattern: If Verify exists in config → wait for PR merge (max 5 attempts, 30s interval) → checkout base branch → run Verify command → if OK add success comment → if FAIL add failure comment + re-open issue. The comment templates (`[ceos-agents] ✅ Fix verified` and `[ceos-agents] ❌ Fix verification failed`) are identical.

### 12. Token Usage Estimate Display

Fix-ticket (lines 319–322) and fix-bugs (lines 334–340) both end with a token usage estimate block in the same format. Implement-feature does not have this.

---

## Mode-Specific Logic

### fix-ticket.md (single-ticket, CWD)

- Works exclusively in CWD — no worktrees
- User-interactive publish decision (Step 9): "user decides about publishing" unless `--yolo`
- Dry-run is triage+code-analyst only, exits after Step 4
- Acceptance gate is conditional: only when AC >= 3 OR complexity >= M (lines 271–282)
- Browser Reproduction (Step 4e) and Browser Verification (Step 8a-browser) enabled
- NEEDS_DECOMPOSITION signal from fixer triggers in-place decomposition (lines 208–213)

### fix-bugs.md (batch, parallel worktrees)

- Batch processing: Fetch bugs → parallel triage → parallel code-analyst → per-bug pipeline
- Worktree orchestration (Variant A/B decision, lines 389–434): git worktree per bug, batch_size, cleanup
- Block counter with Max blocked per run limit (lines 383–387)
- Pipeline-complete webhook (`pipeline-complete` event, lines 344–349) — unique to this command
- Dry-run produces a multi-bug table with resource estimates (lines 437–468)
- Summary table at end (lines 324–332): Bug ID / Summary / Status / PR / Worktree / Block reason
- Rollback-agent receives worktree path in context (CWD if sequential)
- Triage step note: "parallel — triage is read-only, parallelism does not depend on worktree configuration" (line 83)

### implement-feature.md (feature pipeline)

- No triage step; starts with spec-analyst (sonnet) instead of triage-analyst
- spec-analyst posts AC to issue tracker as a comment (distinct from triage)
- Architect always runs (step 4) before decomposition decision
- Acceptance gate always runs (step 6g) — no threshold condition, unlike bugs
- Feature Workflow config section (Feature query, On start set) as separate fallback
- No Browser Verification or Reproduction steps
- Dry-run runs spec-analyst + architect + decomposition plan display (deeper than bug dry-run)
- spec-analyst block → Block handler (different trigger than triage block)
- AC coverage check uses spec-analyst output, not triage output

### scaffold.md (new project creation)

- No issue tracker interaction for the primary flow (MCP only for `--issue` and Step 9)
- Block comments go to stdout, not issue tracker
- Rollback-agent called with `"No issue tracker context — skip issue tracker updates."`
- Hooks explicitly NOT executed during scaffold (Step 7 note, lines 331–332)
- Has a legacy `--no-implement` flow (v3.x behavior) that is a completely separate mini-pipeline
- Brainstorming phase (Step 0b) with anti-bias rules — unique to scaffold
- Spec writer↔spec-reviewer loop (Step 1) replacing the fixer↔reviewer loop
- Scaffolder agent (generates skeleton) replacing the fixer agent
- User-facing mode selection (Interactive / YOLO with checkpoint / Full YOLO) replacing `--yolo` flag
- Spec compliance check via spec-reviewer --verify (Step 7b) — no equivalent in other pipelines
- Issue tracker card creation (Step 9) — creates cards rather than updating existing ones
- Git init (Step 4) rather than git checkout -b (no existing repo)
- SCAFFOLD_TEMP temp-directory-then-move pattern (Steps 3/L2–L4)

### resume-ticket.md (pipeline resume)

- Does not define its own pipeline steps — it delegates entirely to fix-ticket or implement-feature
- Checkpoint detection is a purely read-only classification step (git state + issue tracker comments)
- DECOMPOSE_PARTIAL checkpoint has highest priority (reads task tree from `.claude/decomposition/`)
- Pipeline type detection by comment prefix (`[ceos-agents] Spec analysis completed.` → FEATURE)
- Handles legacy `[CLAUDE-agents]` prefix for backward compatibility
- No flags of its own (no --dry-run, no --profile, no --yolo)

---

## Forge Pipeline Patterns

The forge SKILL.md introduces several patterns absent from ceos-agents:

### 1. Persistent State Machine (forge.json)

Forge maintains a machine-readable `forge.json` at `.forge/forge.json` tracking: `current_phase`, per-phase status (`pending`/`in_progress`/`completed`/`skipped_by_user`/`invalidated`), metrics (`total_tokens_estimated`, `total_duration_ms`, `review_rounds_used`, `escalations_to_human`), and a typed revision object. ceos-agents has no equivalent — pipeline state lives only in git history, issue tracker comments, and `.claude/decomposition/*.yaml` (for decomposition only).

### 2. Structured Event Log (forge.log)

Forge emits 15 typed log events (`FORGE_START`, `PHASE_START`, `AGENT_START`, `REVIEW_START`, `APPROVAL_GATE`, `REVISION_CYCLE`, `TIMEOUT_ADJUSTED`, etc.) to a durable log file. ceos-agents produces human-readable output and inline comments to the issue tracker, but no structured machine-parseable event stream.

### 3. Context Handoff Protocol (explicit input matrix)

Forge's Phase Input Matrix (SKILL.md lines 226–241) defines exactly which files each phase reads. No phase accumulates prior context beyond what the matrix lists. ceos-agents passes context inline as string interpolation in Task tool calls — there is no formalized handoff protocol, and context accumulates in the orchestrator's conversation thread.

### 4. Tiered Config System (Levels 1–4)

Forge has 4 config levels: defaults → project config → CLI flags → meta-agent recommendations. CLI-pinned values cannot be overridden by meta-agent. ceos-agents has a flat config in CLAUDE.md — no levels, no CLI-pinning, no meta-agent config recommendation phase.

### 5. Phase Execution Loop with Skip Dependency Validation

Forge's phase loop (SKILL.md lines 175–222) validates skip dependencies before allowing a phase to be skipped: "Skip Phase 4 → breaks Phases 5, 6, 7, 8." ceos-agents pipeline profiles allow arbitrary skipping with no dependency validation — skipping `code-analyst` before the decomposition decision (which reads code-analyst output) can silently corrupt the pipeline.

### 6. JIT Prompt Refinement (Phase 5+)

Forge optionally refines expert prompts at dispatch time using actual prior-phase outputs (SKILL.md lines 206–213). ceos-agents uses static string interpolation only.

### 7. Two-Tier Template Variable System

Forge separates Tier 1 (meta-agent fills `{{PERSONA}}`, `{{TASK_INSTRUCTIONS}}`, etc. during Phase 0) from Tier 2 (orchestrator fills `{{RESEARCH_FINDINGS}}`, `{{REQUIREMENTS}}`, etc. at dispatch time). ceos-agents mixes both concerns: context is assembled inline by the command with no separation of meta-configuration from runtime data.

### 8. Explicit Crash Recovery Decision Tree

Forge's resume logic follows a decision tree based on artifact existence: `final.md` → mark complete; `synthesis.md` → re-enter review loop; partial `agents/` → re-dispatch missing agents; nothing → re-run phase. ceos-agents resume-ticket uses issue tracker comment patterns and git state — less reliable and not machine-readable.

### 9. Rate Limit Handling with Model Fallback

Forge defines backoff (30s→60s→120s→240s→300s), model fallback (Opus→Sonnet per dispatch), and parallel throttling (reduce batch size). ceos-agents has no rate limit handling — agents either succeed or block.

### 10. PASS_TO_PASS Gate (Regression Detection)

In Phase 7, forge detects test regressions across worktrees and triggers immediate rollback. ceos-agents test-engineer retries on failure but does not detect regressions across subtasks.

---

## Extraction Strategy Implications

### Cleanly Extractable (pure boilerplate, no branching)

1. **MCP pre-flight check** — identical across all 3 issue-tracker commands. Extractable as a sub-routine called at the start of each command. Zero mode-specific branching.

2. **Agent Override injection** — identical across all 4 commands (same rule text). Could be a single rule inherited by all commands via a shared base instruction.

3. **Post-publish hook + webhook (pr-created)** — structurally identical in all 3 issue-tracker commands. Small enough to extract without controversy.

4. **Block comment template** — the comment format is shared and already defined in the plugin's CLAUDE.md; commands reference it by name. No extraction needed beyond centralizing the reference.

5. **Fix Verification (post-merge)** — identical logic in all 3 issue-tracker commands. Extractable to a shared post-publish phase definition.

### Extractable with Minor Parameterization

6. **Config reading block** — same keys across fix-ticket/fix-bugs/implement-feature, but fix-bugs adds Worktrees and Max blocked per run, implement-feature adds Feature Workflow, and scaffold reads almost nothing. Extractable as a "base config" (14 sections) + per-command extension sections.

7. **Pipeline profile parsing** — same algorithm, different stage name→step number mappings. Extractable as a shared algorithm with an injected stage map per pipeline.

8. **Fixer↔reviewer loop** — same pattern, same limits, but context passed to fixer differs (triage AC vs. spec-analyst AC; with/without browser verification result). Extractable as a parameterized loop with a `context_builder` hook.

9. **Block handler (Step X)** — the issue-tracker variant (fix-ticket/fix-bugs/implement-feature) is nearly identical. Scaffold's variant is a stripped-down version. Extractable as a base block handler + per-mode override for the no-tracker case.

10. **Decomposition heuristics + AC coverage check** — identical in fix-ticket and fix-bugs, similar in implement-feature. The subtask execution loop is also nearly identical. Could be extracted, but the context each subtask receives differs by pipeline.

### Difficult to Extract / Requires Refactoring

11. **Dry-run behavior** — each command defines a different set of steps to run in dry-run mode with different report formats. Dry-run is deeply interleaved with step flow, not a wrapper.

12. **Worktree orchestration** (fix-bugs only) — batch processing, parallel Task dispatch, worktree setup/teardown, and the Variant A/B decision are fundamentally batch-specific. Not extractable to a shared engine without making the engine batch-aware.

13. **Scaffold's spec writer↔spec-reviewer loop** — structurally analogous to the fixer↔reviewer loop but uses different agents, different pass/fail signals (APPROVE/REVISE vs. APPROVE/REQUEST_CHANGES), and different output artifacts. It is a distinct pattern, not a specialization.

14. **Acceptance gate condition** — fix-ticket and fix-bugs use a conditional (AC >= 3 OR complexity >= M) while implement-feature always runs it (within decomposition) and skips it in single-pass. This branching logic is pipeline-specific.

15. **Context assembly** — each command assembles fixer context differently (triage AC vs. spec-analyst AC, with/without browser result, with/without decomposition plan). Extracting the loop without the context assembly would create a hollow shell.

---

## Files Examined

1. `/gitea_ceos-agents/commands/fix-ticket.md` (408 lines) — Single-ticket bug-fix pipeline. Source of the canonical block handler definition. Browser Verification fully integrated. Subtask decomposition (Steps 4a–4c) and NEEDS_DECOMPOSITION signal handling.

2. `/gitea_ceos-agents/commands/fix-bugs.md` (486 lines) — Batch pipeline. Adds Worktrees config, Max blocked per run, block counter, pipeline-complete webhook, dry-run resource table, and summary output table. Stage numbers offset by 1 vs. fix-ticket (e.g., Step 7 vs. Step 8 for test-engineer).

3. `/gitea_ceos-agents/commands/implement-feature.md` (316 lines) — Feature pipeline. Replaces triage→code-analyst with spec-analyst→architect. Acceptance gate always-on (no threshold). Decomposition decision driven by architect output, not code-analyst heuristics. No Browser Verification.

4. `/gitea_ceos-agents/commands/scaffold.md` (499 lines) — Project scaffolding. Has two completely separate flows: legacy `--no-implement` (stack-selector→scaffolder→validate→git init) and v2 full implementation flow (10 steps). Block handler is a reduced stdout-only variant. Hooks explicitly disabled. Introduces spec writer↔spec-reviewer loop.

5. `/gitea_ceos-agents/commands/resume-ticket.md` (98 lines) — Resume helper. No pipeline of its own — maps checkpoints to step numbers in fix-ticket or implement-feature. Checkpoint detection uses git state + issue tracker comment patterns. DECOMPOSE_PARTIAL takes highest priority.

6. `/Users/FSABACKY/.claude/plugins/cache/filip-superpowers-marketplace/filip-superpowers/0.1.0/skills/forge/SKILL.md` (439 lines) — Forge pipeline engine. Defines a 10-phase checkpointed pipeline with persistent state (forge.json), structured event log (forge.log), Context Handoff Protocol (explicit per-phase input matrix), 4-tier config system, Phase Execution Loop with skip dependency validation, JIT prompt refinement, Two-Tier Template Variable System, and explicit crash recovery decision tree.

---

## Migration Risks

### R1: Stage Number Coupling in resume-ticket

`resume-ticket.md` references specific step numbers in fix-ticket (`start from step 5`, `step 7`, `step 8`) and implement-feature. Any extraction that renumbers or restructures steps would break resume-ticket's checkpoint mapping. The checkpoint detection is already brittle (heuristic, not machine-readable). **Migration requires a machine-readable pipeline state contract first.**

### R2: Context Accumulation in the Orchestrator Thread

ceos-agents commands accumulate all inter-step context in the orchestrator's conversation thread (context passed as inline strings in Task calls). The forge engine explicitly prevents this via the Context Handoff Protocol (each phase reads only listed files). Extracting a pipeline engine without addressing context accumulation risks hitting context limits on long pipelines (7+ subtasks) and degrading agent quality as context grows stale.

### R3: Decomposition YAML as the Only External State

`.claude/decomposition/{ISSUE-ID}.yaml` is the only persistent pipeline state that ceos-agents writes. If a pipeline crashes between two non-decomposition steps (e.g., between test-engineer and publisher), resume-ticket must re-derive state from git history and issue tracker comments — heuristics that can mis-classify. Adding a lightweight `pipeline-state.json` (equivalent to forge.json) would be a prerequisite for reliable extraction.

### R4: Stage Skipping Without Dependency Validation

Pipeline profiles can skip `code-analyst`, but the decomposition decision (Step 4b/3b) reads `code-analyst` output (`risk`, `affected_files`, `estimated_diff_lines`, `independent_changes`). Skipping code-analyst while retaining the decomposition decision silently produces a broken pipeline. Extraction should enforce forge-style dependency validation for skip combinations.

### R5: Two Subtask Execution Loops with Subtle Differences

The subtask execution loop appears in fix-ticket (Step 4c), fix-bugs (Step 3c), implement-feature (Step 6 decomposition mode), and scaffold (Step 7). The loops are nearly identical but differ in: (a) whether E2E test runs inline per-subtask vs. after all subtasks; (b) whether acceptance gate runs per-subtask (implement-feature) or only at the end (fix-ticket/fix-bugs); (c) commit message prefix (`fix(` vs. `feat(`). A single extracted loop would require parameterization for all four variants, which risks adding complexity rather than reducing it.

### R6: Browser Verification Loop Creates a Second Back-Edge to Fixer

In fix-ticket and fix-bugs, a `FAILED` verdict from browser-verifier returns to fixer and counts against the same Fixer iterations limit. This creates a second back-edge to fixer (beyond reviewer → fixer). Any loop extraction must account for two return paths into fixer: one from reviewer, one from browser-verifier. These are currently described separately and could become inconsistent if extracted into a shared loop definition.

### R7: Scaffold Is a Different Pipeline Shape

Scaffold's implementation loop (Step 7) has no hooks, no issue tracker, no browser verification, no acceptance gate, and a simplified block handler. It is related to the fix pipeline but not a specialization of it. Treating scaffold as a pipeline-engine consumer would require extensive optional-section handling that might make the engine harder to understand than the current flat definition.

### R8: No Structured Output Contract Between Steps

ceos-agents agents produce natural-language output. The orchestrator extracts values like `acceptance_criteria`, `complexity`, `risk`, `affected_files` by parsing agent output text (not structured JSON). A pipeline engine that passes typed context between steps would require agents to produce structured output, which is a significant change to the agent definitions and their prompts — not just a command refactoring.
