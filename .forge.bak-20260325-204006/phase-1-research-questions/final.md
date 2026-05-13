# Phase 1: Research Questions — Synthesis

## Synthesis Notes

All 7 agents produced high-quality, evidence-based research. Scoring:

| Agent | Domain | Specificity | Evidence | Risk ID | Overall |
|-------|--------|-------------|----------|---------|---------|
| Agent 1 | Plugin Architecture Constraints | 5/5 | 5/5 | 5/5 | **Exceptional** |
| Agent 2 | Pipeline Engine Extraction | 5/5 | 5/5 | 5/5 | **Exceptional** |
| Agent 3 | Agent Merge Feasibility | 5/5 | 5/5 | 5/5 | **Exceptional** |
| Agent 4 | State Management Gap | 5/5 | 5/5 | 5/5 | **Exceptional** |
| Agent 5 | Backward Compatibility Surface | 5/5 | 5/5 | 5/5 | **Exceptional** |
| Agent 6 | Non-Code Mode Mapping | 4/5 | 3/5 | 4/5 | **Strong** |
| Agent 7 | Test Migration Strategy | 5/5 | 5/5 | 4/5 | **Excellent** |

**Key contradictions resolved:**

1. **Agent 1 vs Agent 6 on spec-writer reuse**: Agent 1 established that skills have no `allowed-tools` frontmatter; Agent 6 proposed reusing spec-writer across modes. These are compatible — spec-writer is an agent invoked via Task tool, not a skill, so tool permissions do not apply to it.

2. **Agent 3 vs Agent 6 on spec-analyst/spec-writer merge**: Agent 3 concluded that merging spec-analyst and forge's spec-writer is "LOW-MEDIUM feasibility" due to fundamental scope conflicts (the `NEVER design architecture` constraint). Agent 6 independently confirmed that spec-writer (document-generation) and spec-analyst (issue-extraction) are "fundamentally different tasks." Both agents converge on the same conclusion: these should NOT be merged into a single agent.

3. **Agent 2 vs Agent 4 on pipeline state**: Agent 2 identified that context accumulation in the orchestrator thread is a risk; Agent 4 confirmed it from the state management angle — only 4 artifacts survive session boundaries, everything else lives in the LLM conversation. Consistent and mutually reinforcing.

4. **Agent 5 vs Agent 7 on test fragility**: Agent 5 documented the public API surface; Agent 7 independently confirmed that `happy-path.sh` hardcodes all 24 command names and all 18 agent names, meaning any migration that touches file names will produce immediate test failures. These two agents together define the full blast radius of any renaming.

---

## Executive Summary

The research reveals that migrating ceos-agents v5.1.0 into a unified pipeline with forge's capabilities is technically feasible but carries four systemic risks that must be addressed before any file is changed. First, the plugin system's skill registration has no `allowed-tools` frontmatter — all 24 commands declare tool permissions but skills do not, making the permission model for any skill-based migration critically uncertain. Second, ceos-agents has no persistent pipeline state: only 4 artifacts survive LLM session boundaries (issue tracker comments, git branch, decomposition YAML, reproduction JSON), meaning resume-ticket operates on heuristics that can misclassify pipeline position. Third, the two proposed agent merges (spec-analyst + forge spec-writer; architect + forge planner) involve irreconcilable scope conflicts that make true merges architecturally unsound — the agents serve different pipeline positions with incompatible input sources, output formats, and constraint sets. Fourth, the entire test suite is static analysis (grep on markdown files) with no agent execution, and 3 of 14 tests will produce false failures from hardcoded step numbers and filename lists the moment any migration refactoring begins. On the positive side, approximately 10 pipeline patterns are genuinely shared across commands (MCP pre-flight, config reading, fixer-reviewer loop, block handler, agent override injection, webhook calls, post-publish hook, fix verification, decomposition heuristics, pipeline profile parsing), and the forge state model (.forge/ directory with forge.json and forge.log) provides a clear target architecture for ceos-agents' state gap. The non-code modes (analysis, strategy, content) map cleanly onto the 10 forge phases with Phase 5 (TDD), Phase 7 (worktree execution), and Phase 8 (security review) requiring mode-specific adaptation rather than full replacement.

---

## Research Domain 1: Plugin Architecture Constraints

### Key Findings

1. **plugin.json is declarative metadata only.** Neither ceos-agents nor filip-superpowers registers commands, skills, or agents explicitly in plugin.json. Discovery is purely by directory convention: `commands/*.md` → slash commands, `skills/<name>/skill.md` → skills, `agents/*.md` → Task-invokable agents. No changes to plugin.json are required to add skills.

2. **Commands and skills have different frontmatter schemas.** Commands use `description` + `allowed-tools`. Skills use `name` + `description` — with NO `allowed-tools` field. This is confirmed across both plugins. This means skills cannot declare tool permissions in their frontmatter.

3. **Skills CAN contain full orchestration logic.** The filip-superpowers plugin has no `commands/` directory at all — its 10 skills contain complete multi-phase pipeline logic. The plugin runtime does not restrict what goes in a skill vs a command. Commands and skills are architecturally equivalent at the content level.

4. **Namespace coupling is deep.** The `ceos-agents:` prefix flows through: 24 command invocations, the skill router's intent table (23 rows), Task tool agent dispatch calls, the `[ceos-agents]` issue tracker comment prefix, and 3 years of user documentation. Changing the plugin name requires a coordinated update across all surfaces simultaneously.

5. **Current architecture: User → Skill (routing) → Command (orchestration) → Agent (Task tool).** The bug-workflow skill is a routing-only layer. It calls commands via `Skill(skill='ceos-agents:<command>')`. This 3-layer indirection means converting a command to a skill requires both updating the skill router AND preserving the same namespaced invocation name.

6. **Skill file casing ambiguity.** ceos-agents uses `skill.md` (lowercase); filip-superpowers uses `SKILL.md` (uppercase). Both work. On Windows (case-insensitive filesystem), this distinction disappears, but the inconsistency represents an undocumented convention.

7. **`$CLAUDE_SKILL_DIR` environment variable exists.** The forge SKILL.md references `${CLAUDE_SKILL_DIR}` to read sub-prompt files within the skill's own directory. This pattern enables splitting large skill logic across multiple files — relevant for migrating the 400+ line pipeline commands.

### Critical Risk

**The `allowed-tools` gap for skills is the single most critical unknown.** All 24 commands declare `mcp__*, Bash, Read, Write, Edit, Glob, Grep, Task` in their frontmatter. If skills do not support `allowed-tools` and tool access is unrestricted (no declaration needed), then migration is unblocked. If skills inherit tool permissions from their invoking context, behavior depends on how the user invoked the skill. If skills have no tool access at all, then every pipeline operation (MCP calls, file writes, Bash execution) breaks. This must be answered before any command-to-skill migration begins.

---

## Research Domain 2: Pipeline Engine Extraction

### Key Findings

1. **Ten patterns are shared across 3-4 pipeline commands and are extractable:**
   - MCP pre-flight check (word-for-word identical in fix-ticket, fix-bugs, implement-feature)
   - Agent override injection (identical rule text in all 4 commands)
   - Config reading block (same 14+ sections, same defaults)
   - Pipeline profile parsing (same algorithm, different stage maps)
   - Flag parsing (--decompose/--no-decompose/--yolo: identical mapping in all 3 issue-tracker commands)
   - Fixer↔reviewer loop structure (same pattern, same limits, in all 3 + scaffold)
   - Block handler (fix-ticket/fix-bugs/implement-feature: nearly identical; scaffold has reduced variant)
   - Post-publish hook + pr-created webhook (identical in all 3 issue-tracker commands)
   - Fix Verification (post-merge, identical logic in all 3 issue-tracker commands)
   - Decomposition heuristics (identical in fix-ticket and fix-bugs; similar in implement-feature)

2. **Five patterns are mode-specific and cannot be cleanly extracted:**
   - Dry-run behavior (each command defines different steps, different report formats, deeply interleaved)
   - Worktree orchestration (fix-bugs only: batch processing, Variant A/B, cleanup)
   - Scaffold's spec-writer↔spec-reviewer loop (structurally analogous but uses different agents, different signals)
   - Acceptance gate conditionality (fix-ticket/fix-bugs: conditional on AC≥3 or complexity≥M; implement-feature: always runs)
   - Context assembly for fixer (triage AC vs spec-analyst AC, with/without browser result)

3. **forge introduces 10 patterns absent from ceos-agents:** persistent forge.json state machine, structured event log (16 event types), explicit Context Handoff Protocol (per-phase input matrix), 4-tier config system, phase execution loop with skip dependency validation, JIT prompt refinement, two-tier template variable system, explicit crash recovery decision tree, rate limit handling with model fallback, and PASS_TO_PASS regression gate.

4. **resume-ticket is stage-number coupled.** `resume-ticket.md` references specific step numbers within fix-ticket (step 5, 7, 8) and implement-feature. Any extraction that renumbers steps breaks resume-ticket's checkpoint mapping. This is the hardest constraint on refactoring freedom.

5. **Browser verification creates a second back-edge to fixer.** In fix-ticket and fix-bugs, a FAILED verdict from browser-verifier returns to fixer and counts against the Fixer iterations limit. This creates two return paths into fixer (from reviewer AND from browser-verifier) that must both be accounted for in any loop extraction.

### Critical Risk

**Stage-number coupling in resume-ticket blocks free refactoring.** Any restructuring that renumbers pipeline steps requires simultaneous changes to resume-ticket's checkpoint detection table. Without a machine-readable pipeline state contract (forge-style forge.json), every refactor carries the risk of breaking resume-ticket's heuristics. A pipeline state file must be introduced before or alongside any pipeline restructuring.

---

## Research Domain 3: Agent Merge Feasibility

### Key Findings

1. **Merge 1 (ceos spec-analyst + forge spec-writer → unified spec-writer): NOT recommended.** These agents do not overlap — they operate at different pipeline positions:
   - spec-analyst: reads issue tracker → extracts WHAT to build → outputs inline markdown → sonnet model → no architecture → posts AC to issue tracker
   - forge spec-writer: reads brainstorm output → generates formal 3-file spec (EARS requirements + architecture design + GWT criteria) → opus model → includes architecture design → no issue tracker

   The fundamental blocker: spec-analyst's explicit "NEVER design architecture" constraint (that boundary is the architect's job) is incompatible with forge spec-writer including architecture as Layer 2 of its output.

2. **Merge 2 (ceos architect + forge planner → unified planner): Feasible with mode separation, but high cascading risk.** Both agents decompose work into dependency-ordered tasks. However:
   - ceos architect: designs architecture AND conditionally decomposes. Input: spec-analyst output OR code-analyst impact report. Output: YAML with `maps_to: AC-{N}`, `depends_on[]`, `sub-{N}` IDs, 100-line diff limit.
   - forge planner: decomposes only (architecture already in Phase 4 spec). Input: requirements.md + design.md + tests/. Output: markdown with `Requirements: REQ-{NNN}`, `blocks`/`blockedBy`, `task-{NNN}` IDs, 200-LOC limit.

   If the ceos mode of the unified agent does NOT preserve `maps_to: AC-{N}` and `depends_on[]` exactly, all three consuming commands (implement-feature, fix-ticket, fix-bugs) silently fail AC coverage checks with no error output.

3. **spec-analyst is referenced in 13 locations across 8 files.** These references span agent definitions (architect.md, acceptance-gate.md, rollback-agent.md), commands (implement-feature.md, scaffold.md, resume-ticket.md, dashboard.md), and tests. Any rename cascades through all of them.

4. **architect is referenced in 13 locations across 9 files** including commands that use it for bug decomposition (fix-ticket, fix-bugs) — a use case forge planner has no equivalent for. The bug-fix decomposition path would be broken if architect were replaced with a forge-only planner.

5. **rollback-agent has hardcoded safety lists.** `agents/rollback-agent.md` hardcodes read-only agent names to skip in its "never rollback these agents" constraint. Agent renames silently break this safety guard.

6. **discuss command default agents hardcodes `architect`.** If architect is renamed or merged, the default discussion panel breaks silently (Task tool receives unknown agent name).

### Critical Risk

**AC coverage check breakage from task ID format change.** The commands `implement-feature.md`, `fix-ticket.md`, and `fix-bugs.md` all parse `maps_to: AC-{N}:` prefix by index. If any unified planner emits `REQ-{NNN}` instead of `AC-{N}` in ceos mode, all three commands silently fail to detect unmapped acceptance criteria — a correctness regression that produces no error output and no pipeline block.

---

## Research Domain 4: State Management Gap

### Key Findings

1. **Only 4 artifacts survive session boundaries in ceos-agents:**
   - Issue tracker comments (triage checkpoint, block comment, spec-analysis checkpoint)
   - Git branch and commits
   - `.claude/decomposition/{ISSUE-ID}.yaml` (task tree for decomposition)
   - `.claude/reproduction-result.json` (browser reproduction result)

   Everything else — acceptance criteria values, code-analyst impact report, fixer iteration count, build retry count, reviewer verdict history, test attempt results — exists only within the executing LLM session.

2. **resume-ticket uses a 7-level priority heuristic** (`DECOMPOSE_PARTIAL > PUBLISHED > POST_REVIEW > POST_FIX > POST_ANALYSIS > POST_TRIAGE > FRESH`) based on branch existence, commit count, and comment text patterns. The code itself says: "Detection is best-effort — heuristics may not be 100% accurate. Worst case: re-run one extra step." This is the entire state recovery mechanism.

3. **forge's state model is file-system authoritative:** forge.json tracks `current_phase`, per-phase status enum (5 values), cumulative metrics, and the full merged config with provenance. forge.log is an append-only structured event log with 16 event types. Checkpoint detection is deterministic: `final.md exists → complete; synthesis.md exists → re-enter review loop; partial agents/ → re-dispatch missing agents; nothing → re-run phase`.

4. **Per-step state produced vs. persisted gap is large.** Of 16 pipeline steps in fix-ticket, 11 produce valuable state that is not persisted. The triage step is the most critical gap: acceptance criteria and complexity are NOT written to disk — only a comment with counts is posted to the issue tracker. The full AC list must be re-derived from the comment count if the session is interrupted.

5. **Proposed migration target: `.ceos-agents/{ISSUE-ID}/` per-issue state directory** mirroring forge's `.forge/`. Would contain: `state.json` (pipeline position, step statuses), `triage.json` (full AC list, complexity, severity), `code-analyst.json` (impact report), `iteration-log.md` (fixer↔reviewer history), `metrics.json` (per-step durations, retry counts), `ceos-agents.log` (append-only event log).

6. **Multi-instance conflict risk for fix-bugs.** `fix-bugs` spawns concurrent pipelines for multiple tickets. Two sessions processing the same ticket simultaneously would corrupt `.ceos-agents/{ISSUE-ID}/state.json`. A file-locking or PID-based guard is required.

### Critical Risk

**External state (issue tracker) is authoritative and immutable.** The `[ceos-agents]` comment prefix is written to external systems that ceos-agents does not control. Already-posted comments cannot be retroactively updated. Any format change creates a permanent split: old tickets have old-format comments, new tickets have new-format comments, and resume-ticket/dashboard/metrics must handle both indefinitely. The `[CLAUDE-agents]` legacy prefix (pre-v3.4.0) demonstrates this problem is already known and has no clean resolution.

---

## Research Domain 5: Backward Compatibility Surface

### Key Findings

1. **Complete public API surface:** 24 commands (all `/ceos-agents:<name>`), 1 skill (`ceos-agents:bug-workflow`), 18 agents (invoked via Task tool as `ceos-agents:<agent-name>`), 5 required config sections (Issue Tracker, Source Control, PR Rules, PR Description Template, Build & Test), 13 optional config sections, 6 structured output formats (Block Comment, Triage Checkpoint, Spec Analysis Checkpoint, Reviewer AC Fulfillment, Acceptance Gate Report, Architect Task Tree YAML), and 4 filesystem artifact paths (`.claude/decomposition/`, `.claude/reproduction-result.json`, `.claude/verification-result.json`, `.claude/screenshots/`).

2. **The `ceos-agents:` namespace prefix appears in 4 separate surfaces** that would all break simultaneously if the prefix changed: 24 command invocations, the skill router (23 hardcoded rows), the `[ceos-agents]` issue tracker comment prefix, and user scripts/documentation.

3. **The skill router has a gap:** `discuss` command exists in `commands/` and is listed in CLAUDE.md (making 24 commands) but is NOT in the skill router's intent table. A user asking "let's discuss X" would not be routed to `/ceos-agents:discuss`.

4. **Agent Override file naming is a silent-failure surface.** Projects with `customization/{agent-name}.md` files receive no runtime error if an agent is renamed — customizations silently stop applying. `check-setup` does not validate customization directory contents.

5. **Pipeline profile stage names are stored in consuming projects' CLAUDE.md.** Stage identifiers (`triage`, `code-analyst`, `spec-analyst`, `reproducer`, `browser-verifier`, etc.) are user-configured strings in external repositories. Renaming a stage identifier invalidates all projects that have that stage name in their `Skip stages` config — with no migration path.

6. **Versioning contract is well-defined:** Required config key additions = MAJOR; optional section additions = MINOR; behavior fixes = PATCH. New structured output sections that external tooling may parse also trigger MAJOR (added since v5.0.0). The CHANGELOG shows this policy has been followed consistently.

7. **`--no-implement` flag is a long-term compatibility commitment** (explicitly added as a shim in v4.0.0 to preserve pre-v4 scaffold behavior). Removing it forces all users who relied on skeleton-only workflow to change usage.

### Critical Risk

**Issue tracker comment formats are written to external systems and cannot be updated retroactively.** Once a `[ceos-agents] Triage completed. Severity: {s}. Area: {a}. Complexity: {c}. AC: {n}.` comment is posted to a YouTrack/GitHub/Jira issue, it cannot be changed. Any format change creates a permanent dual-format state: resume-ticket and dashboard must parse both the old and new format indefinitely, as the `[CLAUDE-agents]` legacy already demonstrates.

---

## Research Domain 6: Non-Code Mode Mapping

### Key Findings

1. **All 10 forge phases apply to non-code modes — none are skipped.** The conceptual equivalence holds across all modes: research (Phases 1-2), ideation (Phase 3), specification (Phase 4), quality criteria (Phase 5), planning (Phase 6), execution (Phase 7), verification (Phase 8), delivery (Phase 9). No phase is irrelevant.

2. **Three phases require meaningful adaptation for non-code modes:**
   - Phase 5 (TDD): Produces a quality/completeness checklist rather than executable test files. Verification in Phase 8 becomes qualitative reasoning against the checklist rather than deterministic test execution.
   - Phase 7 (Execution): No git worktree isolation needed — parallel document section writing uses natural file isolation (`.forge/phase-7-execution/sections/section-N.md`).
   - Phase 8 (Verification): Security/OWASP agent is irrelevant; replaced by fact-check agent. Correctness agent verifies against Phase 5 checklist rather than running code tests.

3. **Four ceos-agents agents are reusable with adaptation:** spec-writer (document structuring), spec-reviewer (completeness/consistency review + `--verify` mode), spec-analyst (extracting structured deliverable requirements from vague input), priority-engine (scoring and ranking options for strategy mode). code-analyst is NOT meaningfully reusable — it is deeply wired to codebase tooling.

4. **Four new capabilities are needed (no existing agent covers them):** criteria-author (Phase 5 quality checklist generator per mode), section-writer/content-executor (Phase 7 parallel section drafting without worktrees), fact-check/content-verification agents (Phase 8 non-code verification panel), exporter/delivery agent (Phase 9 non-git delivery: PDF/DOCX/Markdown export).

5. **Analysis and strategy modes are meaningfully different** despite the brief's table treating them together. Analysis produces findings from data; strategy produces recommendations for decisions. Conflating them in a single mode adapter would require Phase 3 brainstorm personas, Phase 4 spec structure, and Phase 8 reviewers to serve both simultaneously.

6. **spec-writer's four-file output schema is software-specific.** The fixed structure (spec/README.md, architecture.md, verification.md, epics/) does not map to non-code deliverables. A mode parameter changing the output schema is preferable to forking the agent.

### Critical Risk

**Phase 8 non-code verification is inherently weaker than code verification.** In code mode, Phase 5 TDD tests are executable — Phase 8 runs them deterministically. For non-code modes, Phase 5 produces a checklist that Phase 8 can only verify by reading and reasoning about the document. This means non-code mode Phase 8 provides high-confidence qualitative verification, not deterministic correctness guarantees. User expectations must be explicitly managed; the unified pipeline's Phase 9 output should document this limitation.

---

## Research Domain 7: Test Migration Strategy

### Key Findings

1. **All 14 test scenarios are static analysis only (grep on markdown files).** None execute agents, none start pipelines, none run commands. The mock-mcp-server and mock-project infrastructure exist in the test harness but are not used by any scenario — they are dead weight.

2. **Three tests will produce false failures on any structural migration:**
   - `happy-path.sh`: Hardcodes all 24 command filenames and all 18 agent filenames. Any rename, merge, or split breaks it.
   - `verify-fail.sh`: Checks for exact step numbers `9d`, `8c`, `10b`. Any renumbering — even one that preserves the feature — produces false failures.
   - `pipeline-consistency.sh`: Hardcodes exactly 4 command files. If unified pipeline reduces these to fewer files or a shared base, the consistency checks will not run against the new file.

3. **One test is effectively meaningless:** `test-fail.sh` passes if `agents/test-engineer.md` contains any of `"NEVER"`, `"Constraint"` — these strings will always be present in any agent file. It provides zero signal.

4. **The README count is already stale** (says 13 scenarios; there are 14). `browser-verification-skip.sh` was added after the README was written. This pattern of undocumented additions will compound during migration.

5. **Critical contract gaps in current tests:** No test validates frontmatter completeness for 16 of 18 agents (only reproducer and browser-verifier are checked for all 4 fields). No test validates model assignments for sonnet agents or 4 opus agents. No test validates the canonical `Goal → Expertise → Process → Constraints` section order. No test checks that read-only agents don't contain file-write phrases. No test verifies cross-agent handoff contracts.

6. **13 new tests are needed.** These fall into three categories: structural parity tests (frontmatter completeness, model assignment, section order), contract coherence tests (config contract validation, step-label stability, read-only agent constraint, acceptance-gate conditionality), and pipeline flow tests (agent dispatch order, browser-verifier ordering, rollback placement, decomposition signal, unified-pipeline consistency).

7. **Before migration begins, 3 fragile tests should be updated to prevent migration interference:** Replace `happy-path.sh` filename enumeration with a count check; replace `verify-fail.sh` step-number checks with label-based checks; update `pipeline-consistency.sh` PIPELINE_FILES list to include any new shared pipeline files.

### Critical Risk

**The test suite cannot detect silent regressions in pipeline logic.** Since all tests are grep-based, a command that drops the entire fixer↔reviewer loop, removes the block handler, or changes the acceptance gate condition would pass all tests — as long as certain keyword strings remain present. During migration, behavioral regressions in pipeline orchestration will be invisible until a human runs an actual pipeline. The harness infrastructure for real pipeline execution tests exists but is completely unwired.

---

## Cross-Cutting Themes

**Theme 1: Shared patterns exist but extraction requires prerequisites.** Agents 2, 4, and 7 all converge on the same conclusion: the 10 shared pipeline patterns (fixer-reviewer loop, block handler, MCP pre-flight, etc.) can be extracted, but doing so safely requires (a) a machine-readable pipeline state file to decouple resume-ticket from step numbers, and (b) test updates to prevent false failures during refactoring. The extraction is an outcome of prerequisites, not the starting point.

**Theme 2: The state gap is the central architectural debt.** Agents 2, 4, and 5 all identify ceos-agents' lack of persistent pipeline state as the root cause of multiple downstream problems: brittle resume-ticket heuristics, lost iteration counts, inability to detect regressions across subtasks, and external system dependency at resume time. Introducing a `.ceos-agents/{ISSUE-ID}/state.json` would unblock pipeline restructuring, improve resume reliability, and enable real metrics collection simultaneously.

**Theme 3: Namespace coupling limits migration options.** Agents 1, 5, and 7 all note that the `ceos-agents:` prefix is deeply embedded across commands, skill router, issue tracker comments, tests, and user documentation. The hardest constraint on any migration is that the external-facing namespace cannot change without coordinated updates across all consumers, and issue tracker comments that have already been posted cannot be retroactively updated.

**Theme 4: Agent merges should be mode-separation, not true merges.** Agents 3 and 6 independently converge on the same conclusion: the proposed agent merges (spec-analyst + forge spec-writer; architect + forge planner) involve incompatible behaviors that are better addressed through MODE-BASED dispatch at the orchestration level rather than cramming two code paths into one agent definition. The "merge" should be an orchestration decision, not an agent prompt decision.

**Theme 5: The forge state model is a clear, proven target.** Agents 2, 4, 6, and 7 all reference forge's `.forge/` directory, `forge.json`, and `forge.log` as the target architecture for ceos-agents' state gap. There is no disagreement across agents about what the solution looks like — only about sequencing and backward compatibility.

**Theme 6: Non-code modes extend the pipeline without requiring agent replacement.** Agent 6 confirms that all 10 forge phases apply to non-code modes, and that 4 existing agents (spec-writer, spec-reviewer, spec-analyst, priority-engine) are reusable with adaptation. The new capabilities needed (criteria-author, section-writer, fact-check agent, exporter) are additive, not replacements of existing agents.

---

## Contradictions and Tensions

**Tension 1: Extract now vs. introduce state first.** Agent 2 documents that 10 patterns are extractable, implying they could be extracted now. But Agent 4 notes that resume-ticket's stage-number coupling means any renumbering breaks the only resume mechanism. And Agent 7 notes that happy-path.sh will produce immediate false failures on any structural change. The tension is between the desire to reduce duplication and the prerequisites needed to do so safely. Resolution: introduce `.ceos-agents/state.json` and update the fragile tests BEFORE extracting shared pipeline logic.

**Tension 2: True merge vs. mode dispatch for agents.** The migration brief implies merging agents into unified definitions. Agent 3 argues this is architecturally wrong for spec-analyst/forge spec-writer — they are different agents at different pipeline positions. Agent 6 agrees. The tension is between the conceptual appeal of unified agents and the practical reality that the merges would create multi-mode agents sharing nothing except a name. Resolution: implement mode dispatch at the orchestration command level, not within the agent definitions.

**Tension 3: Skills as first-class citizens vs. commands as the stable layer.** Agent 1 confirms that skills CAN hold full pipeline logic (as filip-superpowers demonstrates). But Agent 5 documents that the command namespace is deeply embedded in external comments and user tooling. Moving pipeline logic from commands to skills would be architecturally cleaner but creates a backward-compatibility burden. Resolution: if skills do not support `allowed-tools` (the critical unknown from Agent 1), the migration to skills is blocked anyway. Answer this question first.

**Tension 4: Test coverage during migration.** Agent 7 says 3 existing tests will produce false failures immediately upon migration. But those same tests currently serve as regression guards. Updating them to be less brittle (count-based rather than name-enumeration) risks making them less protective during migration. Resolution: update the 3 fragile tests first, but simultaneously add the 4 structural parity tests (frontmatter completeness, model assignment, section order, read-only constraint) to maintain protection coverage before weakening the brittle checks.

---

## Top 10 Migration Risks (ranked by severity)

**1. [CRITICAL] `allowed-tools` gap for skills** — If skills do not support `allowed-tools` frontmatter AND do not inherit unrestricted tool access, then no pipeline command (which requires `mcp__*, Bash, Write, Edit`) can be migrated to a skill. This would block the architectural direction entirely. Must be answered before any migration work begins.

**2. [CRITICAL] AC coverage check breakage from architect/planner merge** — The commands implement-feature, fix-ticket, and fix-bugs all parse `maps_to: AC-{N}:` by index. If a unified planner emits different ID formats in ceos mode, all three commands silently fail to detect unmapped acceptance criteria with no error output. No pipeline block, no warning — silent correctness regression.

**3. [HIGH] Issue tracker comment formats are immutable** — Already-posted `[ceos-agents]` comments cannot be retroactively updated. Any format change creates a permanent dual-format state that resume-ticket and dashboard must handle indefinitely. Historical comments in external trackers are outside ceos-agents' control.

**4. [HIGH] Stage-number coupling in resume-ticket** — resume-ticket references specific step numbers (5, 7, 8 in fix-ticket; equivalent numbers in implement-feature). Any pipeline restructuring that renumbers steps breaks the only resume mechanism, affecting in-flight tickets without a migration path.

**5. [HIGH] Architecture design loss from spec-analyst merge** — If spec-analyst is merged with forge spec-writer and the unified agent always includes architecture (as forge's spec-writer does), the architect agent's role boundary is destroyed. Every feature would receive architectural prescriptions from the spec stage, then potentially conflicting advice from the architect stage, making the architect step meaningless overhead.

**6. [HIGH] Bug-fix decomposition path has no forge equivalent** — ceos architect is called from fix-ticket and fix-bugs with code-analyst impact report input. Forge planner has no concept of bug impact reports — it only receives spec + tests. Replacing architect with forge planner would silently break the bug-fix decomposition path, affecting all bug tickets above complexity threshold.

**7. [HIGH] Agent Override silent failures on rename** — Projects using `customization/{agent-name}.md` files receive no runtime error if an agent is renamed — customizations silently stop applying. `check-setup` does not validate customization directory contents. This affects paying users of the plugin in production.

**8. [MEDIUM] State loss between sessions** — Only 4 artifacts survive session boundaries. If a long pipeline (7+ subtasks with decomposition) is interrupted between non-decomposition steps, resume-ticket must re-derive state from heuristics that are explicitly documented as "best-effort, not 100% accurate." Introducing state.json before migration makes the migration itself more resilient.

**9. [MEDIUM] Pipeline profile stage names stored in external configs** — Stage identifiers (`triage`, `code-analyst`, etc.) used in `Skip stages` configs live in consuming projects' CLAUDE.md files. Any stage rename invalidates existing profile configurations with no in-plugin migration path and no error at config-read time.

**10. [MEDIUM] Test suite false failures block migration velocity** — `happy-path.sh` enumerates all 24+18 filenames; `verify-fail.sh` hardcodes step numbers; `pipeline-consistency.sh` targets exactly 4 files. These 3 tests will fail immediately on any structural change, creating a false signal that the migration "broke something" when it did not. Without updating these tests first, every migration commit produces noisy false failures.

---

## Research Questions for Phase 2

**Domain 1: Plugin Architecture Constraints**

> Do skills in the Claude Code plugin system support `allowed-tools` frontmatter, or do they operate with unrestricted tool access, or with tool access inherited from the invoking context? Provide evidence from: (a) the official plugin system documentation or source code, (b) testing a minimal skill that attempts to use Bash and mcp__* tools in the ceos-agents plugin context, and (c) the filip-superpowers forge skill's actual behavior when invoked with tool-requiring operations.

**Domain 2: Pipeline Engine Extraction**

> Given the 10 extractable shared patterns (MCP pre-flight, config reading, pipeline profile parsing, flag parsing, fixer-reviewer loop, block handler, agent-override injection, post-publish hook, fix verification, decomposition heuristics) and the prerequisite of introducing a `.ceos-agents/{ISSUE-ID}/state.json`, design the concrete extraction architecture: what is the exact structure of the shared state file schema, which patterns become shared sub-documents vs. inline text vs. command-level instructions, and how does resume-ticket transition from step-number heuristics to state-file-based checkpoint detection without breaking currently in-flight tickets?

**Domain 3: Agent Merge Feasibility**

> For the architect agent specifically: is a MODE-BASED unified agent (ceos mode: design+decompose with AC-{N}/depends_on/sub-{N} format; forge mode: decompose-only with REQ-{NNN}/blocks/task-{NNN} format) the right implementation pattern, or should the two modes remain as separate named agents (e.g., `architect` for ceos pipelines, `planner` for forge pipelines)? Define the exact interface contract — including all field names, model assignment, input sources, and output format — that the ceos consuming commands (implement-feature, fix-ticket, fix-bugs) will accept, and confirm that this contract is byte-for-byte compatible with the existing `maps_to: AC-{N}:` parsing logic in all three commands.

**Domain 4: State Management Gap**

> Design the complete `.ceos-agents/{ISSUE-ID}/state.json` schema as a version 1.0 document: define all field names, enum values for step statuses, how the schema handles multi-ticket fix-bugs runs (shared vs. per-issue files), the conflict resolution protocol when local state diverges from issue tracker state, the file-locking mechanism for concurrent fix-bugs sessions, and the backward-compatibility fallback path for tickets that were triaged before state.json existed (no state.json → heuristic detection).

**Domain 5: Backward Compatibility Surface**

> For the proposed migration, identify every file that contains a hardcoded `ceos-agents:` namespace reference and classify each as: (A) internal-only (safe to update in a single PR), (B) user-facing documentation (requires coordinated release note), or (C) externally-written data (issue tracker comments already posted — cannot be updated). Produce a complete change impact matrix: which API surface changes require a MAJOR version bump, which require MINOR, and what is the minimum version number for the unified pipeline release.

**Domain 6: Non-Code Mode Mapping**

> Design the concrete agent definitions and frontmatter for the 4 new agents required for non-code modes (criteria-author, section-writer, fact-check-agent, exporter). For each: specify the model tier (opus/sonnet/haiku), the exact Process steps, the Constraints section, and how each integrates into the Phase 5/7/8/9 positions in the unified pipeline. Also define the `mode` parameter contract for spec-writer: what is the exact frontmatter and prompt change needed to switch between software-spec mode (current) and document-spec mode (analysis/strategy/content), and does this change require a MAJOR version bump under the current versioning policy?

**Domain 7: Test Migration Strategy**

> Before the first migration commit is made, implement the following test changes as a prerequisite PR: (1) update `happy-path.sh` from filename enumeration to count-based checks, (2) update `verify-fail.sh` from step-number checks to label-based checks, (3) add `frontmatter-completeness.sh` for all 18 agents, (4) add `model-assignment.sh` against the CLAUDE.md model table, (5) add `read-only-agents.sh` checking that 9 read-only agents contain no write phrases. For each: provide the exact bash implementation, confirm it passes against the current codebase, and define the exact failure condition that would have caught a regression in the browser-verifier feature (v5.1.0) had these tests existed then.
