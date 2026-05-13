# Proposal 3: The Skeptic's Analysis (Alex Okafor)

> **Note:** Neither agent-1.md (Conservative) nor agent-2.md (Innovator) was available within the 5-minute window. This analysis is written as a standalone risk-first proposal grounded in the Phase 2 research findings. Where the Conservative and Innovator would typically propose specific approaches, I construct the most likely versions of their proposals from the brainstorm persona definitions and critique those. When the actual proposals arrive, the failure scenarios and convergence analysis below should be re-validated against their specific design choices.

---

## Failure Scenarios (10 specific scenarios)

### Scenario 1: Silent AC Coverage Regression During Architect Mode Merge

**Trigger:** A unified architect/planner agent is created that, in ceos mode, emits `REQ-{NNN}:` (forge's format) instead of `AC-{N}: {text}` for even one subtask's `maps_to` field — due to prompt bleed between modes, model temperature variance, or an incomplete mode guard.

**Impact:** All three consuming commands (implement-feature, fix-ticket, fix-bugs) parse `maps_to` via regex `AC-(\d+):`. If the format is `REQ-001:` instead of `AC-1:`, the regex returns zero matches. The AC coverage check finds no mappings. No error is raised — the check is vacuously satisfied when no mappings exist. Every subtask proceeds without AC traceability. Acceptance criteria are silently orphaned. The acceptance-gate agent receives no `maps_to` data, so it cannot verify fulfillment. The entire quality chain from architect through acceptance-gate is broken with zero pipeline output indicating a problem.

**Detection:** Only detectable by a human noticing that PR descriptions lack AC fulfillment sections, or that the acceptance gate stopped blocking anything. There is no automated test for `maps_to` format correctness. The structural test suite (all grep-based) does not execute any agent or parse any agent output.

**Mitigation:** (a) Add a runtime format assertion in the pipeline command: after architect output, validate that every `maps_to` entry matches `/^AC-\d+:/` — block if not. (b) Keep architect and planner as separate named agents with separate prompts. Mode dispatch at orchestration level, not inside the agent prompt. (c) Add a structural test that the architect agent prompt contains the exact `AC-{N}:` format specification.

---

### Scenario 2: Resume-Ticket Misclassification After Pipeline Restructuring

**Trigger:** Pipeline commands are refactored to extract shared patterns. Step numbers change (e.g., code-analyst moves from step 4 to step 3, fixer from step 5 to step 4). No one updates resume-ticket's checkpoint detection table simultaneously.

**Impact:** resume-ticket's 7-level priority heuristic relies on correlating issue tracker comment presence and git branch state to infer pipeline position. The heuristic itself does not use step numbers directly (it uses signal patterns like "branch exists + triage comment"), but the *documentation* in resume-ticket references step numbers for humans. More critically, the pipeline profile parsing in fix-ticket and fix-bugs maps stage names to step numbers (e.g., `triage = step 3`, `code-analyst = step 4`). If a pipeline restructure changes these mappings, `--profile skip:code-analyst` could skip the wrong step — or skip nothing at all.

**Detection:** A user running `/ceos-agents:resume-ticket PROJ-42` after a session crash gets the wrong checkpoint. They re-run steps that already completed (wasted time) or skip steps that did not complete (silent quality regression). The pipeline profile mismatch is only detectable when a user explicitly skips a stage and observes the wrong behavior.

**Mitigation:** (a) Introduce `.ceos-agents/{ISSUE-ID}/state.json` BEFORE any pipeline restructuring. Make checkpoint detection file-authoritative, not heuristic. (b) Replace step-number-based stage mapping with label-based mapping in pipeline profiles. (c) Add a structural test that validates stage-name-to-step-number consistency across resume-ticket and all pipeline commands.

---

### Scenario 3: Agent Override Silent Failure on Rename

**Trigger:** An agent is renamed during the merge (e.g., `architect` becomes `planner`, or `spec-analyst` is merged into another agent). A consuming project has `customization/architect.md` with project-specific instructions (e.g., "Always include database migration subtask for schema changes").

**Impact:** The file `customization/architect.md` still exists but no longer matches any agent name. The Agent Override injection logic in all four pipeline commands does a filename lookup: `{override_path}/{agent-name}.md`. Since the agent is now called `planner`, the lookup returns nothing. No error is raised. The customization silently stops being applied. The project's pipeline runs without the architectural guidance the team depends on, producing subtask plans that miss database migrations.

**Detection:** Only detectable when a downstream failure occurs (e.g., a deployment breaks because a schema migration was not included). There is no validation step that checks whether customization files match active agent names. `check-setup` does not validate the customization directory.

**Mitigation:** (a) Never rename agents that have been shipped in a stable release. Use mode dispatch or new agents instead. (b) Add validation to `check-setup` that warns when customization files do not match any known agent name. (c) If a rename is unavoidable, publish a migration guide and maintain an alias map for at least one major version. (d) Add a mapping file (`customization/aliases.json`) that maps old names to new names.

---

### Scenario 4: `.claude/` Race Condition in Parallel fix-bugs Worktree Mode

**Trigger:** `fix-bugs` processes 3 bugs in parallel worktree mode. Bug A and Bug B both have browser verification enabled. The reproducer agent for Bug A writes `.claude/reproduction-result.json`. Before Bug A's browser-verifier reads it, Bug B's reproducer overwrites the same file with Bug B's results.

**Impact:** Bug A's browser-verifier reads Bug B's reproduction result. It verifies Bug B's reproduction steps against Bug A's fix. The verification either (a) passes incorrectly (the wrong test was run), or (b) fails with a confusing error that sends Bug A back to fixer with incorrect context. In either case, the pipeline produces wrong results. This is a data corruption bug.

**Detection:** Very difficult to detect. The only signal is that browser verification results "don't make sense" for a particular bug. If the bugs are in similar areas, the wrong result might even look plausible. The pipeline does not validate that the reproduction result matches the current issue ID.

**Mitigation:** (a) Change `.claude/reproduction-result.json` to `.claude/reproduction-result-{ISSUE-ID}.json` immediately (this is a pre-existing bug, not migration-related). (b) Same for `verification-result.json`. (c) In the state.json migration, use per-issue state directories: `.ceos-agents/{ISSUE-ID}/reproduction-result.json`. (d) Add an issue-ID field to the JSON schema and validate it at read time.

---

### Scenario 5: Skill Migration Breaks Existing User Scripts and Aliases

**Trigger:** Commands are migrated to skills. The user has a shell script or CI pipeline that runs `claude "/ceos-agents:fix-ticket PROJ-42"`. After migration, `fix-ticket` is no longer a command but a skill. The invocation syntax for skills may differ from commands.

**Impact:** The user's automation breaks. If the syntax difference is subtle (e.g., skills are invoked as `ceos-agents:fix-ticket` without the leading `/`), the error may be confusing. If the skill router handles the old syntax, there may be double-dispatch (skill router calls itself). If the old command files are removed, the invocation fails with "unknown command."

**Detection:** Immediate failure for users with automated workflows. Manual users may not notice if the skill router correctly intercepts the old command name. The plugin has no telemetry or usage tracking, so there is no way to know how many users have automated invocations.

**Mitigation:** (a) Keep command files as thin wrappers that delegate to skills during the transition period. The wrapper contains only: frontmatter + "This command has moved. Invoke the skill: ..." + actual delegation. (b) Define a deprecation timeline: wrappers exist for at least 1 major version. (c) Document the syntax change in CHANGELOG with migration instructions. (d) Add deprecation warnings to the wrapper commands that surface in the pipeline output.

---

### Scenario 6: Issue Tracker Dual-Format Comment Hell

**Trigger:** The migration introduces new comment formats (e.g., `[ceos-agents] Build completed.` or changes the triage checkpoint format). Old tickets have old-format comments. New tickets have new-format comments. Some tickets, started before migration and resumed after, have BOTH.

**Impact:** resume-ticket, dashboard, and metrics must parse both old and new formats indefinitely. The `[CLAUDE-agents]` to `[ceos-agents]` precedent already created one layer of dual-format handling. Each migration adds another layer. After 3 migrations, the comment parsing becomes a pile of regex alternatives that no one can confidently modify.

**Detection:** resume-ticket fails to detect the correct checkpoint for a ticket that spans the migration boundary. Dashboard shows incomplete data for tickets with old-format comments. Metrics aggregation silently drops events from old-format tickets.

**Mitigation:** (a) NEVER modify existing comment formats. Only ADD new comment types (this is a MINOR version bump per the versioning policy). (b) If a new pipeline step needs a comment, use a new prefix that does not collide with existing patterns. (c) Document every comment format ever shipped as a permanent contract in a `docs/reference/comment-formats.md` file. (d) Add a test that validates all comment regex patterns in resume-ticket against a corpus of known historical formats.

---

### Scenario 7: Pipeline Profile Stage Name Breakage in External Configs

**Trigger:** During migration, the stage name `code-analyst` is renamed to `analyzer` (or merged into a different stage). A consuming project has `Skip stages: code-analyst, reproducer` in their Automation Config.

**Impact:** The pipeline profile parser reads `code-analyst` from the config. It looks up `code-analyst` in the stage-to-step mapping. The stage name no longer exists. Behavior depends on implementation: (a) if unrecognized stages are silently ignored, the stage is NOT skipped — the user's pipeline now runs a stage they explicitly opted out of, potentially costing tokens and time; (b) if unrecognized stages produce an error, the entire pipeline fails on startup.

**Detection:** Option (a): the user notices an unexpected stage running and wonders why their profile config is being ignored. Option (b): immediate, clear failure.

**Mitigation:** (a) NEVER rename pipeline profile stage names in a minor or patch release. Stage name renames are MAJOR version bumps. (b) Maintain an alias map for deprecated stage names for at least one major version. (c) Add a validation step at pipeline start that warns about unrecognized stage names in Skip stages config. (d) Document all valid stage names in the config reference.

---

### Scenario 8: Non-Code Mode Verification Produces False Confidence

**Trigger:** The unified pipeline adds analysis/strategy/content modes. Phase 8 (verification) is adapted to non-code modes. For code, Phase 8 runs deterministic tests. For non-code, Phase 8 reads the document and reasons about whether it meets the Phase 5 quality checklist.

**Impact:** Users see "Phase 8: Verification PASSED" for a strategy document. They assume this means the document was validated with the same rigor as code tests. It was not. An LLM reading a document and saying "this looks good" is fundamentally different from `pytest` returning exit code 0. The strategy document may contain logical fallacies, unsupported causal claims, or factually incorrect market data. The "PASSED" verdict provides false confidence.

**Detection:** Only when a human reads the strategy document and finds errors that Phase 8 "verified." By then, the document may have been shared with stakeholders.

**Mitigation:** (a) Non-code mode Phase 8 output must explicitly state: "Verification is qualitative, not deterministic. LLM-based review cannot guarantee factual accuracy or logical soundness." (b) Use different verdict language: "REVIEWED" instead of "PASSED" for non-code modes. (c) Include a confidence level in the verdict (HIGH/MEDIUM/LOW) based on how much of the checklist could be mechanically verified vs. subjectively assessed. (d) Require human approval gate for non-code mode before Phase 9 (delivery).

---

### Scenario 9: State File Corruption During Session Crash

**Trigger:** The pipeline writes to `.ceos-agents/{ISSUE-ID}/state.json` at each step transition. The LLM session crashes (OOM, network timeout, user Ctrl+C) mid-write. The JSON file is truncated or contains partial data.

**Impact:** On resume, the pipeline reads `state.json` and gets a JSON parse error. If the error handling says "fall back to heuristic detection," the state file is ignored and the pipeline potentially re-runs completed steps. If the error handling says "abort," the pipeline refuses to proceed until a human fixes the file. Either way, the promise of deterministic checkpoint detection is broken.

**Detection:** Immediate on next resume attempt — JSON parse error is detectable. But the mitigation path depends on implementation.

**Mitigation:** (a) Use atomic writes: write to `state.json.tmp`, then rename to `state.json`. On most filesystems, rename is atomic. (b) On read failure, fall back to heuristic detection (same as pre-state-file behavior) but log a warning: "State file corrupted. Using heuristic detection. Results may be approximate." (c) Keep a `state.json.bak` from the last successful write. (d) Use append-only event log (like forge.log) as the authoritative source, with state.json as a derived cache.

---

### Scenario 10: Command-to-Skill Migration Exceeds Single-PR Blast Radius

**Trigger:** The migration plan calls for moving all 24 commands to skills in a single PR (or a small number of PRs). Each command is 200-800 lines of markdown. The total change is 10,000+ lines across 50+ files.

**Impact:** The PR is unreviewable. No human can meaningfully review a 10K-line change to 50 markdown files and verify behavioral preservation. Bugs introduced during the migration are invisible in the diff. The test suite (all grep-based) provides no behavioral coverage to catch regressions. If the migration introduces a subtle logic change in the fixer-reviewer loop, it will not be caught until a user runs a real pipeline and gets wrong results.

**Detection:** Only when users report pipeline failures post-release. The test suite passes (it only checks string patterns). The review was rubber-stamped because the PR was too large to review.

**Mitigation:** (a) Migrate one command at a time as its own PR. Each PR is small enough to review. (b) For each migrated command, run the test suite AND manually exercise the pipeline against the mock project (which exists but is currently unwired). (c) Keep the old command as a wrapper until the next major version. (d) Define a "migration readiness checklist" for each command: tests pass, wrapper exists, CHANGELOG entry written, deprecation warning added.

---

## Stress Test: Conservative Proposal

*The Conservative (Dr. Heinrich Bauer) would propose incremental migration with strict backward compatibility, keeping old commands alongside new skills, maintaining all existing agent names, and migrating one subsystem at a time over many PRs.*

### Where Incrementalism Creates Hidden Debt

**1. The Wrapper Graveyard.** If every command gets a thin wrapper pointing to a skill, you end up with 24 wrapper files + 24 skill directories (each with a skill.md + potentially sub-prompts). The total file count doubles. Developers working on the plugin must now check two locations for every piece of logic. The wrappers are "temporary" but, per the versioning policy, they must survive for at least one major version cycle. Given that v5.1.0 is current and a MAJOR bump triggers only on breaking config changes, the wrappers could persist for years.

**2. State.json Alongside Heuristic Detection — Double Maintenance.** Introducing state.json while keeping heuristic detection as a fallback means resume-ticket has TWO code paths indefinitely. Every change to checkpoint logic must be made in both paths. The heuristic path is already documented as "best-effort, not 100% accurate." Maintaining it alongside the authoritative path means the fallback is permanently unreliable but permanently required.

**3. Deferred Agent Merges Accumulate Drift.** If the Conservative keeps both `architect` and a separate `planner` agent indefinitely (to avoid breaking Agent Overrides), then the two agents' prompts drift over time. Bug fixes applied to one are not applied to the other. One gets new constraints that the other lacks. After 6 months, they are two divergent agents that do similar things differently, and the eventual merge becomes harder, not easier.

**4. Test Updates Without Test Improvements.** The Conservative would update the 3 fragile tests (happy-path.sh, verify-fail.sh, pipeline-consistency.sh) to be less brittle, but is unlikely to add behavioral tests (actually running the pipeline against the mock project). The test suite remains a structural-pattern checker with higher tolerance — it catches fewer false failures but also catches fewer true failures. The migration proceeds under a test suite that cannot detect behavioral regressions.

**5. Non-Code Modes Are Perpetually Deferred.** In an incremental approach, non-code modes (analysis, strategy, content) are Phase 4 or 5 of the migration — always "next." The infrastructure work (pipeline engine, state management, skill migration) consumes all migration bandwidth. By the time the infrastructure is done, the architecture has ossified around code-mode assumptions. Adding non-code modes requires re-opening decisions that were "settled" in earlier phases.

**6. The `[ceos-agents]` Comment Prefix Becomes a Permanent Albatross.** The Conservative would never change the comment prefix (correctly — it is immutable in external systems). But the unified plugin now serves both forge-style and ceos-style workflows. The `[ceos-agents]` prefix on forge-originated pipeline comments is confusing to users who adopted the plugin for forge capabilities and have no concept of "ceos." The prefix becomes a misleading brand artifact.

---

## Stress Test: Innovator Proposal

*The Innovator (Yuki Tanaka) would propose a clean-slate design: a unified `/build` entry point, skill-first architecture, merged agents where possible, and a migration script that transforms old configs to new format. Backward compatibility via migration tooling, not permanent shims.*

### Where Clean-Slate Design Breaks Existing Users

**1. Migration Scripts Cannot Reach External Systems.** The Innovator's migration script can update local files (CLAUDE.md configs, customization directories, shell aliases). It CANNOT update: issue tracker comments already posted, CI pipeline configurations in other repositories, team documentation that references command names, muscle memory of users who type `/ceos-agents:fix-ticket`. The migration script addresses the easy part and leaves the hard part to humans.

**2. The `/build` Entry Point Conflates Distinct Mental Models.** Current users think in terms of specific workflows: "I want to fix a bug" (`fix-ticket`), "I want to implement a feature" (`implement-feature`), "I want to scaffold a project" (`scaffold`). The `/build` entry point requires users to shift to a generic mental model: "I want to build something" + mode flags. This is a cognitive regression for experienced users who already know which command they want. The Innovator's "pit of success" design is optimized for first-time users at the expense of expert users.

**3. Agent Merges Create Maintenance Nightmares.** A unified `spec-writer` that handles both issue-tracker extraction (current spec-analyst behavior) and formal specification generation (current spec-writer behavior) based on a mode parameter has an enormous prompt. Two completely different processes, two different output formats, two different constraint sets — all in one file. Every edit to one mode risks breaking the other. The Phase 2 research explicitly concluded "these should NOT be merged" (Agents 3 and 6 independently).

**4. Clean-Slate Directory Structure Breaks Every Test Immediately.** If agents move from `agents/` to `agents/core/` and `agents/non-code/`, or if commands disappear entirely in favor of skills, all 14 test scenarios fail simultaneously. The Innovator would say "rewrite the tests." But rewriting 14 tests while also restructuring 50+ files means there is no stable ground to stand on — the tests cannot verify the migration because they are being migrated simultaneously.

**5. Removing Deprecated Commands Before External Systems Catch Up.** The Innovator's deprecation timeline ("one minor version with warnings, then remove") is too aggressive. The `[ceos-agents]` namespace is embedded in external CI pipelines, team runbooks, and issue tracker automation rules. These external systems update on their own schedule, not the plugin's release schedule. A 6-month deprecation window is the minimum; the Innovator's typical approach is 1-2 releases.

**6. The "Migration Guide Is Cheaper Than Legacy Code" Fallacy.** A migration guide is a one-time cost to WRITE but a per-user cost to EXECUTE. If 50 teams use the plugin, 50 teams must each read the guide, update their configs, update their CI pipelines, update their documentation, and re-test. The total cost is 50x the guide-writing cost. Legacy code (shims, wrappers) is a one-time cost borne by the plugin maintainer.

**7. Mode Auto-Detection Is Unreliable.** The Innovator would propose that `/build "task description"` auto-detects whether the task is a bug fix, feature, scaffold, analysis, or strategy. This detection relies on natural language classification by the LLM. Edge cases: "analyze the performance regression in the API" — is this `analysis` mode or `code` mode? "Create a strategy for migrating our database" — `strategy` or `scaffold`? Misclassification sends the task down the wrong pipeline with wrong agents, wasting tokens and time. The explicit command names in the current system are unambiguous.

---

## The Skeptic's Own Proposal (Risk-First Approach)

The organizing principle: **every migration step must be independently reversible, independently testable, and must not change any external-facing contract until a major version boundary.**

### 1. Directory Structure

Keep the current structure as the starting point. Add new directories alongside, do not restructure existing ones.

```
ceos-agents/
  .claude-plugin/            # unchanged
  agents/                    # KEEP all 18 agents in place
    architect.md             # unchanged (ceos mode)
    planner.md               # NEW (forge mode) — separate agent, not a merge
    ...18 existing agents...
    intake-agent.md          # NEW (non-code input ingestion)
    domain-analyst.md        # NEW (non-code analysis expertise)
    content-reviewer.md      # NEW (non-code quality review)
  commands/                  # KEEP all 24 commands — they are the stable API
    fix-ticket.md            # updated to use shared includes
    fix-bugs.md              # updated to use shared includes
    implement-feature.md     # updated to use shared includes
    scaffold.md              # updated to use shared includes
    build.md                 # NEW command (unified entry point alongside existing)
    ...20 utility commands...
  skills/
    bug-workflow/            # KEEP existing skill
    build/                   # NEW skill (unified entry point)
      skill.md               # routes to appropriate pipeline
    pipeline-core/           # NEW skill (shared pipeline infrastructure)
      skill.md               # shared pattern library
      includes/              # extractable shared patterns
        mcp-preflight.md
        config-reader.md
        fixer-reviewer-loop.md
        block-handler.md
        agent-override.md
        pipeline-profile.md
        post-publish.md
        fix-verification.md
        decomposition.md
  state/                     # NEW — state management schemas
    schema-v1.json           # state.json schema definition
  tests/
    scenarios/               # existing + new
    harness/                 # existing
  docs/                      # existing
  checklists/                # existing
  examples/                  # existing
```

**Rationale:** No file moves. No renames. No deletions. Everything new is additive. The `agents/` directory grows but does not reorganize. The `commands/` directory gets one new file (`build.md`). The skill system gets two new skills. This means: every test passes on every commit; every Agent Override continues to work; every pipeline profile stage name remains valid.

### 2. Pipeline Engine Design

Do NOT build a "pipeline engine" as an abstraction layer. Instead, extract the 10 shared patterns as **include files** under `skills/pipeline-core/includes/` and reference them from within the existing commands using `${CLAUDE_SKILL_DIR}` or direct file read instructions.

Each include file is a self-contained markdown section that the command's orchestration instructions tell the LLM to "Read and follow the instructions in `skills/pipeline-core/includes/fixer-reviewer-loop.md`." The command remains the orchestration authority. The includes are reusable text, not a runtime framework.

**Why not a real engine?** Because this is a pure-markdown plugin with no runtime code. There is no function dispatch, no module imports, no dependency injection. A "pipeline engine" in this context is just a large prompt that says "do these phases in order." Extracting shared text into includes achieves the same deduplication without creating an abstraction layer that suggests runtime capabilities that don't exist.

**The fixer-reviewer loop** is the most valuable extraction. It is currently ~80 lines duplicated across 4 commands with only the context-assembly differing. Extract the loop structure; keep context assembly per-command.

**Mode adapters** are not a separate abstraction. They are simply different commands (or different sections within `/build`) that assemble different context and call different agents. The "adapter" is the command file itself.

### 3. Agent Merge Strategy

**Do not merge agents.** The Phase 2 research is unambiguous:
- spec-analyst + forge spec-writer: "NOT recommended" (Agents 3 and 6 independently)
- architect + forge planner: "feasible with mode separation, but high cascading risk"

Instead:
- Keep `architect` unchanged for ceos pipelines (bug-fix, feature, scaffold)
- Add `planner` as a NEW agent for forge-style pipelines
- Keep `spec-analyst` unchanged
- Keep `spec-writer` unchanged
- Add new agents for non-code modes as separate files

The orchestration layer (commands/skills) decides which agent to dispatch based on pipeline mode. This is the recommendation from Phase 2 Cross-Domain Insight 5.

**Agent naming:** No existing agent is renamed. New agents get new names. The rollback-agent's hardcoded skip list remains valid. The discuss command's default panel remains valid. Agent Overrides continue to work.

### 4. Command -> Skill Migration

**Phase 1 (immediate):** Add `/build` as a NEW command (not a skill) in `commands/build.md`. It is a router that parses the mode and delegates to the appropriate existing command. Users who prefer explicit commands continue using them. Users who want the unified entry point use `/build`.

**Phase 2 (next minor version):** Migrate the `/build` command to a skill at `skills/build/skill.md`. Keep the command file as a one-line wrapper: "This command has moved to a skill. Use `/ceos-agents:build` or the natural language skill route." This tests the skill system with a single new entry point before migrating any existing commands.

**Phase 3 (next major version, v6.0.0):** Migrate existing pipeline commands to skills. Keep commands as deprecation wrappers. Remove wrappers in v7.0.0.

**Why this slow?** Because the skill system's behavior under tool access, error handling, and namespace resolution has been confirmed only by file inspection, not by production use. The `/build` skill is the canary. If it works correctly for 1 minor version cycle, then bulk migration is safe. If it reveals edge cases (tool access issues, namespace resolution bugs, etc.), we discover them with one skill, not 24.

### 5. Backward Compatibility

**Iron rules:**
- The `[ceos-agents]` comment prefix is NEVER changed. It is immutable.
- The `ceos-agents:` command namespace is NEVER changed. It is immutable.
- No existing command is removed in any minor version. Removal only at major version boundaries.
- No existing agent is renamed. New agents get new names.
- No pipeline profile stage name is renamed. New stages get new names.
- No existing config section or key is renamed. New keys are additive.

**The dual-format comment problem:** Add new comment types with the same `[ceos-agents]` prefix (MINOR version bump). Never modify existing comment formats. resume-ticket's regex patterns are append-only — new patterns are added, old patterns are never removed.

**Agent Override compatibility:** If a new agent replaces the function of an old one (e.g., `planner` handles what `architect` used to handle in forge mode), and a project has `customization/architect.md`, the customization continues to apply because `architect` still exists and is still used for ceos-mode pipelines.

### 6. Non-Code Modes

**Phase 1:** Add non-code modes as entirely new pipelines, not as adaptations of existing ones. The `/build --mode analysis` flag dispatches to a new command `commands/analyze.md` (or skill), which has its own pipeline phases, its own agent dispatch, and its own state management. It shares the include files from `skills/pipeline-core/includes/` where applicable (config reading, block handler) but does not share code-specific patterns (fixer-reviewer loop, pipeline profiles, acceptance gate).

**Phase 2:** Add new agents for non-code capabilities:
- `intake-agent` (flexible input ingestion from URLs, documents, pasted text)
- `domain-analyst` (analytical expertise for analysis mode)
- `content-reviewer` (quality review for content mode)
- `strategy-analyst` (strategic reasoning for strategy mode)

These are separate agents, not adaptations of existing ones. The existing agents (spec-writer, spec-reviewer, priority-engine) are reused where Phase 2 research confirmed compatibility, with mode parameters where needed.

**Verification honesty:** Non-code mode verification output explicitly states: "Qualitative review (not deterministic test execution). Confidence: {HIGH|MEDIUM|LOW}." Never use "PASSED" for non-code verification. Use "REVIEWED" with a confidence qualifier.

### 7. State Management

**Step 1 (prerequisite, before any structural migration):** Introduce `.ceos-agents/{ISSUE-ID}/state.json` with schema v1.

```json
{
  "schema_version": "1.0",
  "issue_id": "PROJ-42",
  "pipeline": "fix-ticket",
  "checkpoint": "POST_TRIAGE",
  "started_at": "2026-03-22T10:00:00Z",
  "updated_at": "2026-03-22T10:05:00Z",
  "steps": {
    "triage": { "status": "completed", "completed_at": "..." },
    "code-analyst": { "status": "in_progress" },
    "fixer": { "status": "pending" }
  },
  "context": {
    "acceptance_criteria": ["AC-1: ...", "AC-2: ..."],
    "complexity": "M",
    "severity": "normal",
    "active_profile": "default",
    "fixer_iteration": 0,
    "test_attempts": 0,
    "build_retries": 0
  }
}
```

**Atomic writes:** Write to `state.json.tmp`, then rename. On read failure, fall back to heuristic detection with a warning.

**Backward compatibility:** If `state.json` does not exist for a ticket, resume-ticket uses the existing heuristic detection. The heuristic path is maintained but documented as "legacy fallback."

**fix-bugs parallel safety:** Each bug gets its own `.ceos-agents/{ISSUE-ID}/` directory. No shared files. The `.claude/reproduction-result.json` race condition is fixed by moving to per-issue paths.

**Event log:** `.ceos-agents/{ISSUE-ID}/events.log` — append-only, one JSON line per event. Mirrors forge.log's design but scoped per-issue.

### 8. Migration Sequence

**PR 0 (prerequisite): Fix pre-existing bugs and test fragility**
- Fix `.claude/reproduction-result.json` race condition (per-issue paths)
- Fix `.claude/verification-result.json` race condition (per-issue paths)
- Update `happy-path.sh` to count-based checks
- Update `verify-fail.sh` to label-based checks
- Update `pipeline-consistency.sh` to dynamic discovery
- Add 4 new structural tests (frontmatter, model, read-only, section-order)
- Add `discuss` to skill router (pre-existing gap)
- Rollback: revert PR. Risk: zero — only test and bug fixes.

**PR 1: Introduce state management**
- Add `.ceos-agents/{ISSUE-ID}/state.json` schema and write logic to fix-ticket
- Update resume-ticket to prefer state.json when present, fall back to heuristic
- Add tests for state.json schema validation
- Rollback: revert PR. state.json is additive; its absence triggers heuristic fallback.

**PR 2: Extend state management to fix-bugs and implement-feature**
- Same state.json pattern for the other two pipeline commands
- fix-bugs uses per-issue directories (no shared files)
- Rollback: revert PR. Same fallback behavior.

**PR 3: Extract shared pipeline includes**
- Create `skills/pipeline-core/includes/` with the 6 easiest extractions (MCP pre-flight, agent-override, config-reader, post-publish, fix-verification, block-handler)
- Update fix-ticket to use includes (as a proof of concept)
- Rollback: revert PR. fix-ticket still works without includes (the content was just inlined before).

**PR 4: Extend includes to remaining commands**
- Update fix-bugs, implement-feature, scaffold to use shared includes
- Rollback: revert PR per-command if any single command breaks.

**PR 5: Add `/build` command**
- New file `commands/build.md` — router to existing commands
- Tests for build command routing
- Rollback: delete the file. No existing functionality affected.

**PR 6: Add non-code mode agents**
- New agent files only. No changes to existing agents or commands.
- Rollback: delete the new agent files.

**PR 7: Add non-code mode commands/pipelines**
- New command files for analysis, strategy, content modes
- Wire into `/build` routing
- Rollback: delete the new command files. `/build` falls back to code-only routing.

**PR 8 (major version boundary, v6.0.0): Skill migration**
- Migrate `/build` from command to skill
- Keep old command as wrapper
- Includes CHANGELOG, migration guide, version bump
- Rollback: revert PR, re-release as v5.x.

Each PR is independently reviewable (< 500 lines), independently testable, and independently revertable.

---

## Convergence Analysis

### Areas of Agreement (high-confidence decisions)

These decisions are supported by the Phase 2 research and should be adopted regardless of which overall approach is chosen:

1. **State management must be introduced before pipeline restructuring.** All research streams converge on this. The `.ceos-agents/{ISSUE-ID}/state.json` pattern is the clear target. This is the single highest-value prerequisite.

2. **spec-analyst and forge spec-writer must NOT be merged.** Agents 3 and 6 independently confirmed this. The agents operate at different pipeline positions with incompatible constraints.

3. **The `[ceos-agents]` comment prefix is immutable.** It is written to external systems beyond the plugin's control. Any format change creates permanent dual-format state.

4. **The `ceos-agents:` namespace must be preserved.** It is the plugin's identity and is embedded in 4 separate surfaces (commands, skill router, comments, user documentation).

5. **Three fragile tests must be updated before any structural migration.** `happy-path.sh`, `verify-fail.sh`, and `pipeline-consistency.sh` will produce false failures that obscure real regressions.

6. **The `.claude/reproduction-result.json` and `.claude/verification-result.json` race conditions must be fixed.** This is a pre-existing data corruption bug that must be addressed regardless of migration.

7. **Agent renames are unacceptable in minor/patch versions.** Agent Override silent failure, rollback-agent safety list breakage, and discuss command default panel breakage make renames a MAJOR-only operation with mandatory alias support.

8. **Non-code mode verification must be clearly distinguished from code verification.** Different verdict language, explicit confidence levels, and documented limitations.

9. **Pattern extraction should be include-based, not framework-based.** In a pure-markdown plugin with no runtime, a "pipeline engine" is just organized text. Include files achieve deduplication without implying runtime abstraction.

10. **The `/build` entry point should complement, not replace, existing commands.** Existing commands are the expert user path; `/build` is the discovery path for new users.

### Unresolved Disagreements (design choices for Phase 4)

These are genuine trade-offs where reasonable people disagree. Phase 4 (specification) must make explicit choices:

1. **Architect merge vs. separate agents.** The Conservative keeps both `architect` and adds `planner` separately. The Innovator merges them with mode dispatch. The research says mode dispatch is "more compatible" but has "high cascading risk." The Skeptic recommends separate agents but acknowledges the drift risk. **Decision needed:** Is the drift risk (separate agents) worse than the silent-failure risk (merged agent with mode bleed)?

2. **Speed of command-to-skill migration.** Conservative: multi-version, wrapper-heavy. Innovator: single-version, migration-script-heavy. Skeptic: canary-first, then bulk. **Decision needed:** What is the actual deprecation timeline? How many versions must wrappers survive?

3. **Non-code mode agent strategy.** Conservative: reuse existing agents with mode parameters. Innovator: new purpose-built agents. Skeptic: new agents for new capabilities, reuse for compatible capabilities. **Decision needed:** For the 4-6 partially-reusable agents, is mode-parameterization or agent-per-mode the better maintenance strategy?

4. **Include mechanism.** The exact mechanism for extracting shared patterns depends on the Claude Code skill system's file-reading behavior. If `${CLAUDE_SKILL_DIR}` works within commands (not just skills), include files can be referenced directly. If not, includes must be inlined by a pre-processing step or duplicated with a "source of truth" marker. **Decision needed:** Test `${CLAUDE_SKILL_DIR}` cross-boundary behavior before committing to an include architecture.

5. **The `/build` auto-detection question.** Should `/build "fix the login bug"` auto-detect that this is a bug-fix, or should it always require `--mode code-fix`? Auto-detection is user-friendly but error-prone. Explicit modes are unambiguous but verbose. **Decision needed:** Is auto-detection a v6.0.0 feature or a v7.0.0 feature? Should it be opt-in (`--auto`) or opt-out (`--mode explicit`)?

6. **State directory location.** `.ceos-agents/` (new, clean namespace) vs. `.forge/` (existing, forge-compatible) vs. `.claude/` (existing, but has the race condition bug). **Decision needed:** If the goal is eventual unification with forge, should the state directory use `.forge/` from the start? Or does that create confusion when the plugin is still called `ceos-agents`?

---

## Risk Assessment

### What Could Go Wrong Even With the Risk-First Approach

1. **The canary skill (`/build`) reveals a blocking issue in the skill system.** If skills have unexpected behavior (e.g., they cannot dispatch agents via Task tool, or they lose context between sub-invocations), the entire skill migration path is blocked. The risk-first approach delays this discovery to PR 5, which is 4 PRs into the migration. Mitigation: run a minimal skill integration test (not just file inspection) before PR 0.

2. **State.json introduces a new class of bugs.** The state file is a new contract surface. Bugs in state serialization (wrong checkpoint written), state deserialization (wrong checkpoint read), or state-vs-heuristic disagreement (state says POST_FIX but heuristic says POST_TRIAGE) create confusion. The dual-path (state + heuristic fallback) means two potential sources of truth. Mitigation: always prefer state.json when present; log when heuristic disagrees; add a `/ceos-agents:state-check` diagnostic command.

3. **The 8-PR sequence takes too long.** If each PR takes 1-2 weeks of review/test/merge, the migration spans 2-4 months. During that time, regular feature development continues on the existing structure. Merge conflicts accumulate. The migration PRs conflict with feature PRs. Mitigation: freeze non-critical feature development during the core migration (PRs 0-4). Accept that PRs 5-8 can proceed in parallel with feature work.

4. **Non-code modes are underspecified.** The Phase 2 research identifies 6 capability gaps but does not design the agents or their interactions. PRs 6-7 require design work that may reveal the pipeline structure chosen in PRs 3-4 is wrong for non-code modes. Mitigation: design non-code mode agents (at least interface contracts and process steps) in Phase 4 specification, before committing to the pipeline include structure.

5. **The "no renames" policy creates naming confusion.** Having both `architect` and `planner` in the agents directory, doing similar things for different modes, is confusing for contributors. Having both `commands/fix-ticket.md` and `skills/build/skill.md` as entry points is confusing. The risk-first approach trades naming clarity for migration safety. Over time, the naming confusion becomes its own form of technical debt.

6. **External ecosystem changes invalidate assumptions.** If the Claude Code plugin system changes (e.g., skills gain `allowed-tools` support, or command discovery changes from directory convention to explicit registration), the migration plan must be revised. The risk-first approach's incremental nature makes it more adaptable to such changes, but it also means the migration is always in a partial state and vulnerable to platform shifts.
