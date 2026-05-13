# Phase 0 Meta-Agent Analysis - forge-2026-04-23-002

## 0. Task Input (Verbatim)

User input (Czech): udelej verzi z roadmapy v6.10.0

Translation (reasoning-only, NOT a rewrite): "Make the v6.10.0 release from the roadmap."

This is a release-engineering task targeting the ceos-agents plugin. The roadmap slot v6.10.0 in docs/plans/roadmap.md lines 815-821 (authoritative source) bundles three work tracks. The user memory summary matches the roadmap exactly.

## 1. Task Type Classification

**Primary task_type:** refactor

**Rationale:** This release is NOT a pure new-feature delivery. The three tracks are:

1. **Test Discipline Overhaul** - audit 41 existing doc-grep "tests" and rewrite them to exercise real bash/jq state-machine logic; add 20-40 new functional scenarios. This is predominantly a test-quality refactor: preserving coverage intent while restructuring the mechanism (doc-grep -> functional). It IS a "test" in a loose sense, but because it changes existing tests in-place under a behaviour-preservation invariant, refactor is the closer fit than test (the latter VALID_TARGETS profile skips Phase 4 which we actively need for specifying new assertion contracts).
2. **Agent Dispatch Enforcement (layers 1+2+4)** - rewrite SKILL.md prose across pipeline skills to remove permissive dispatch language, add PostToolUse hook + validate-dispatch.sh, add functional dispatch-enforcement test scenario. Layers 2+4 are NEW artifacts (hooks + scripts + scenario) - this has feature character. Layer 1 is a mechanical prose rewrite of existing SKILL.md files - refactor character.
3. **Prompt-injection constraint for 8 remaining agents** - mechanical batch edit of 8 agent files to append the same EXTERNAL INPUT Constraint block that the 3 HIGH-risk agents got in v6.9.0 (per Phase 2 section G-3). Pure refactor / hardening - no new capability, just consistency.

Net: two tracks are refactor-dominant (track 1 and track 3) and one track is mixed. The release also includes version bump + CHANGELOG + tag = mechanical release work. refactor is the best single-label fit and is the VALID_TARGETS category with "(none - full pipeline)" so no phase skipping is triggered by routing.

**secondary_types:** ["feature", "test"] - feature from the dispatch-enforcement track (new hook script + new test scenario); test from the test-discipline track (new scenarios + rewritten scenarios). Mixed-type signal is acknowledged; primary here is already refactor (implementation), so action defaults to full_pipeline anyway.

## 2. Complexity Assessment

| Axis | Score | Justification |
|------|-------|---------------|
| Scope | 5 | Cross-cutting: touches 41+ test files (rewrite), 8 agent files (append constraint block), ~15 pipeline SKILL.md files (dispatch prose), new hook script, new test scenario, CHANGELOG, version files, CLAUDE.md count updates, docs/reference updates. Affects every agent, every pipeline skill, the tests harness, and the docs tree simultaneously. |
| Ambiguity | 3 | Tracks 1 and 2 are defined in roadmap at a "5-layer defense" level with specific layer selection (1+2+4) and estimated effort; Track 3 is fully mechanical (copy the v6.9.0 HIGH-risk constraint block verbatim to 8 agents). Ambiguity comes from (a) which of the 41 existing tests are audit-only vs full-rewrite vs retire, (b) the exact PostToolUse hook contract + validate-dispatch.sh semantics (what counts as "real tokens"?), (c) the functional test scenario synthetic issue fixture design. These are decidable during specification but are currently open. |
| Risk | 4 | Public-release blocker. Uneven prompt-injection defense is unacceptable for OSS publication (external-PR attack surface). Test-discipline failure is what allowed 8 functional bugs to slip through v6.9.0 Phase 7 gate - repeating the miss on v6.10.0 work is a real risk. Dispatch enforcement changes the orchestration contract on the plugin critical path; a bad PostToolUse hook could halt legitimate pipelines. Mitigating factor: this is a plugin-internal release, not a public-API change to a dependency surface outside our control. |

**Composite = max(5, 3, 4) = 5**

**Agent scaling implications (composite=5):** maximum agents, model upgrade eligible, 3-5 review rounds.

**JIT recommendation:** jit.enabled: true (composite >= 3).

**Replanning recommendation:** keep enabled. Ambiguity at 3 is mid-range but composite=5 justifies bumping max_cycles from 1 to 3. Do not lower divergence_threshold below 0.3; three tracks of moderately defined scope do not warrant extra early-divergence detection.

**Verification weight recommendation:** { security: 0.3, correctness: 0.35, spec_alignment: 0.2, robustness: 0.15 }. Rationale: track 1 (test-discipline) and track 2 (dispatch-enforcement) are explicitly correctness-focused quality work - the whole point is that doc-grep assertions produced false correctness signals. Security stays at 0.3 because track 3 (prompt-injection constraint) does need real security scrutiny. Robustness drops from 0.2 to 0.15 - this is not a robustness-critical change (no concurrency redesign, no fault-injection surface change). Spec-alignment stays at 0.2 default. Sum: 0.3+0.35+0.2+0.15 = 1.0.

## 2b. Fast-Track Eligibility Assessment

**Eligibility precondition check:**

| Precondition | Required | Actual | Result |
|---|---|---|---|
| Composite complexity <= 2 | yes | 5 | FAIL |
| Confidence >= 0.9 | yes | 0.88 | FAIL |
| fast_track.enabled != false | yes | null (auto-detect) | PASS |
| task_type not statically ineligible | yes | refactor - implementation, full pipeline | PASS |

**Result: INELIGIBLE - composite complexity 5 far exceeds the <=2 ceiling.** Fast-track is not evaluated further. Tier A and Tier B security hard-block are NOT executed (Section 2b instructs: "If any precondition fails, skip to Section 3"). No fast_spec.json is generated. No security_evaluation JSON block is emitted (only required when fast-track eligibility reached Tier B).

Log intent: FAST_TRACK_INELIGIBLE reason="composite_complexity_5_exceeds_ceiling_2"

## 3. Domain Identification

- **Language/Runtime:** Markdown documents + POSIX bash scripts (for tests) + jq. No compiled code.
- **Framework:** Claude Code plugin framework (.claude-plugin/plugin.json + marketplace.json), skills (markdown with YAML frontmatter under skills/*/SKILL.md), agents (markdown with YAML frontmatter under agents/*.md). No web/UI framework, no runtime.
- **Domain:** DevTools / AI agent orchestration / release engineering. This is a meta-tool: ceos-agents itself automates bug-fix / feature-implementation pipelines, and we are shipping a version of it.
- **Specialty concerns:**
  - **Security:** prompt-injection defense (track 3) is a direct security hardening. The EXTERNAL INPUT Constraint teaches agents to treat tracker-sourced text as adversarial, preventing malicious PRs from hijacking pipeline logic via injected instructions in issue descriptions.
  - **Testing discipline / correctness:** the whole release is motivated by the fact that existing tests are documentation-presence greps rather than behavior assertions. Track 1 is pure correctness-quality work.
  - **Release engineering:** version bump (6.9.2 -> 6.10.0 - MINOR per versioning policy, since this adds optional agent-prompt behavior and tests without breaking the Automation Config contract), CHANGELOG, tag, push, Phase 8 verification, Phase 9 doc-completeness audit (the MISS that shipped with v6.9.0 must not repeat).
  - **Agent orchestration integrity:** track 2 (dispatch enforcement) is architecturally load-bearing - it is the defense-in-depth against silent inline-execution of agent roles, which would negate context isolation and cost tracking.

## 4. Codebase Context Assessment

### Patterns / Conventions

- **Plugin composition:** 21 agents + 29 skills + 16 core contracts + 19 optional Automation Config sections. No build system, no dependencies - pure markdown. Tests are POSIX bash scripts under tests/scenarios/ executed by tests/harness/run-tests.sh.
- **Agent definition format:** YAML frontmatter (name, description, model, style) + prose sections Goal -> Expertise -> Process -> Constraints. The 3 HIGH-risk agents updated in v6.9.0 (test-engineer, e2e-test-engineer, backlog-creator) contain an EXTERNAL INPUT Constraint block - its exact format is the canonical template for the 8 remaining agents in Track 3.
- **Skill definition format:** SKILL.md files with YAML frontmatter (name, description, disable-model-invocation: true on the 15 pipeline-invocation skills). Numbered Step 0..N instructions in prose - these are the dispatch-language artefacts Track 2 Layer 1 must rewrite.
- **State machine:** .ceos-agents/state.json records per-stage tokens_used / duration_ms / tool_uses / model - the dispatch-enforcement hook (Track 2 Layer 2) asserts nonzero distinct tokens_used per expected stage. Schema version is 1.0 (additive fields only).
- **Cross-file invariants (CLAUDE.md Cross-File Invariants):** License SPDX consistency (plugin.json, marketplace.json, LICENSE - all MIT); maintainer email consistency (filip.sabacky@ceosdata.com in SECURITY.md / CODE_OF_CONDUCT.md / CONTRIBUTING.md); issue/PR template parity (.gitea/ and .github/ byte-identical via diff -q). Phase 8 verification scenarios assert each. These MUST hold after v6.10.0.
- **Versioning policy (CLAUDE.md Versioning Policy):** MAJOR = breaking Automation Config contract change or breaking agent output format change. MINOR = new optional key / new command/agent. PATCH = behavior fix without contract change. v6.10.0 adds NO new required keys, NO new agents/skills. Adds optional enforcement hook + new test scenarios + tightened agent-prompt language. This is strictly MINOR (6.9.2 -> 6.10.0 is justified by the new test scenarios and hook script adding backward-compatible capability).

### Test Framework

- **Harness:** tests/harness/run-tests.sh - iterates tests/scenarios/*.sh, captures exit codes, reports pass/fail counts. Current total: 185 scenarios after v6.9.2 added ac-v692-autopilot-bash-dispatch.sh.
- **Naming convention:** ac-v{MAJOR}{MINOR}-<area>-<specific-assertion>.sh for acceptance-criteria-driven tests; v{MAJOR}{MINOR}{PATCH}-<description>.sh for hidden regression tests; <area>-<specific-assertion>.sh for utility tests (e.g., autopilot-lock-acquire.sh).
- **Existing patterns (INADEQUATE, per roadmap finding):** grep -F for a doc string against a SKILL.md, assert present. These DO NOT exercise runtime behavior and are the target of Track 1 overhaul.
- **Target patterns (DESIRED, per roadmap cycle-1 stub):** tests/scenarios/v6.9.0-needs-clarification-e2e.sh is the reference template - it constructs a synthetic state.json, invokes sanitize_block_reason() or similar under bash -c "source ...", asserts on real output.
- **Test directory structure:** tests/scenarios/*.sh (flat), tests/harness/run-tests.sh, tests/mock-project/CLAUDE.md (fixture project for integration-style tests), tests/README.md.

### Build System

None. This is a pure-markdown plugin. "Build" = verifying frontmatter validity + running the test harness + running diff -q for cross-file invariants. The Phase 8 verification scenarios encode these.

### Relevant Existing Code

- **Agent dispatch prose to rewrite (Track 2 Layer 1, ~15 files):** skills/fix-bugs/SKILL.md, skills/fix-ticket/SKILL.md, skills/implement-feature/SKILL.md, skills/scaffold/SKILL.md, skills/autopilot/SKILL.md, skills/analyze-bug/SKILL.md, and any other pipeline skill that currently says "Run the X agent (Task tool, ...)" - the Track 2 spec must enumerate these exactly.
- **Agents to update (Track 3, 8 files, in priority order from roadmap):** agents/spec-reviewer.md, agents/spec-writer.md, agents/rollback-agent.md, agents/sprint-planner.md, agents/scaffolder.md, agents/stack-selector.md, agents/deployment-verifier.md, agents/publisher.md. Source template: agents/test-engineer.md (the v6.9.0 template - copy block verbatim, adapt agent-name reference only).
- **Tests to audit (Track 1):** all 41 v6.9.0 visible scenarios - the ac-v68-*, ac-v692-*, and any *-v69* files. Each audit yields one of: KEEP (already functional), REWRITE (doc-grep -> functional), RETIRE (stale one-shot).
- **New artifacts (Track 2):**
  - tests/scenarios/v6.10.0-skill-dispatch-enforcement.sh (functional test - synthetic state.json assertions).
  - A new PostToolUse hook script location (TBD - likely ~/.claude/settings.json hook pointing at a script in the plugin; Phase 4 must specify this).
  - validate-dispatch.sh (location TBD - likely core/scripts/validate-dispatch.sh or similar; Phase 4 decides).

### Tech Debt Relevant to This Release

- **Doc-string test debt** - the 41-scenario backlog IS the tech debt we are paying down in Track 1.
- **Uneven security posture** - v6.9.0 prompt-injection defense is selective; Track 3 closes the gap.
- **Unenforced orchestration contract** - Track 2 converts a markdown-prose promise into a runtime-enforced contract.
- **None of these create cascading debt** - all three tracks land self-contained.

### Compressed CODEBASE_CONTEXT (for downstream prompts)

Plugin: ceos-agents v6.9.2 (next: v6.10.0). Language: Markdown + POSIX bash + jq. No build system, no deps. Layout: 21 agents (agents/*.md), 29 skills (skills/*/SKILL.md), 16 core contracts (core/*.md), 19 optional Automation Config sections, 185 test scenarios (tests/scenarios/*.sh). Test framework: tests/harness/run-tests.sh + POSIX bash scenarios. Naming: ac-v{ver}-<area>-<assertion>.sh. Reference functional-test pattern: tests/scenarios/v6.9.0-needs-clarification-e2e.sh (cycle-1 stub). Current anti-pattern: tests/scenarios/*.sh that only grep -F doc strings (41 such). v6.10.0 three tracks: (1) Test Discipline Overhaul - audit 41 + write 20-40 functional tests. (2) Agent Dispatch Enforcement layers 1+2+4 - imperative SKILL.md prose + PostToolUse validator hook + functional dispatch-enforcement scenario. (3) Prompt-injection constraint batch for 8 agents - copy v6.9.0 EXTERNAL INPUT Constraint block from agents/test-engineer.md to: spec-reviewer, spec-writer, rollback-agent, sprint-planner, scaffolder, stack-selector, deployment-verifier, publisher. Cross-file invariants to preserve: License SPDX MIT across 3 files; maintainer email filip.sabacky@ceosdata.com across 3 files; .gitea/ and .github/ template byte-parity. Versioning: MINOR bump (6.9.2 -> 6.10.0) - no new required Automation Config keys, no new agents/skills. Optional hook + test scenarios + prompt hardening are all additive. State schema: .ceos-agents/state.json schema_version "1.0" stays - fields are additive. Release checklist: ./tests/harness/run-tests.sh BEFORE commit; CHANGELOG entry mandatory; commit order: content -> changelog (same commit) -> version-bump (separate) -> tag; never manual bump - use /ceos-agents:version-bump skill; never commit .claude/settings.local.json. Doc audit discipline: Phase 9 MUST enumerate items, not just check count strings (v6.9.0 miss). Operator language: Czech for user comms, English for all code/file content.

## 5. Domain Expertise Consumption

No template was loaded (routing.auto_select_template: false in config; Section 6 Template Auto-Selection Protocol is NOT executed). Section skipped.

## 6. Template Auto-Selection

**NOT EXECUTED.** Precondition routing.auto_select_template == true is FALSE (config value is false, source: default). No template_selection block emitted.

## 7. Routing Decision

Written as a standalone file: .forge/phase-0-meta/routing-decision.json (NOT embedded here).

Summary:
- task_type: refactor
- secondary_types: ["feature", "test"]
- action: full_pipeline
- target_skill: null
- confidence: 0.90
- skip_profile: null

Rationale: refactor is an implementation type per VALID_TARGETS ("(none - full pipeline)"). The classification-rule defaults action to "full_pipeline" for implementation types. No phase subset, no skill redirect. This is consistent with the user intent - they asked for a version release, which requires the full plan -> execute -> verify -> complete arc.

## Confidence Scoring (Devin Pattern)

| Question | Score | Reasoning |
|---|---|---|
| Q1: Is the task well-defined enough to execute? | 0.90 | The roadmap (lines 815-821) enumerates three tracks with specific scope (41 tests to audit, 8 named agents, dispatch layers 1+2+4). Ambiguity remains for the exact PostToolUse hook interface and the audit-vs-rewrite partition of existing tests - decidable in Phase 4 specification. The user input is terse but the roadmap resolves it unambiguously. |
| Q2: Does the available context support execution? | 0.92 | All context is in-repo: roadmap.md (authoritative scope), CLAUDE.md (cross-file invariants, versioning policy), the v6.9.0 EXTERNAL INPUT template (copy-source for Track 3), the v6.9.0 functional-test cycle-1 stub (reference pattern for Track 1). No external docs, no blocked dependencies - "ready to execute now, no external gates" per roadmap line 817. |
| Q3: Is the task within the pipeline capabilities? | 0.88 | Forge full-pipeline arc (research -> spec -> tdd -> plan -> execute -> verify -> complete) is a direct fit for a release of this shape. The bash + markdown substrate is well-suited. One mild concern: the PostToolUse hook (Track 2 Layer 2) interacts with Claude Code runtime hook system which is out-of-scope for the pipeline to change - the pipeline can WRITE the hook script but CANNOT install it globally in ~/.claude/settings.json; installation is an operator action. This is a documented limitation, not a pipeline gap. |

**Composite confidence = min(0.90, 0.92, 0.88) = 0.88**

Against meta_agent.confidence_threshold = 0.7 (default): 0.88 > 0.7 -> **proceed with noted assumptions**. No clarification protocol triggered. No hard stop.

**Noted assumptions carried forward to downstream phases:**
1. The PostToolUse hook installation is documented as an operator step, not performed by the pipeline.
2. The exact audit outcome for each of the 41 existing scenarios (KEEP / REWRITE / RETIRE) is decided in Phase 4 based on scenario-by-scenario inspection, not upfront.
3. Version bump is MINOR (6.9.2 -> 6.10.0) - no MAJOR-triggering changes are in scope.
4. Phase 9 MUST enumerate doc items, not just grep count strings - the v6.9.0 miss is a specific anti-pattern Phase 9 must defend against.

## 8. Pipeline Configuration Decisions (summary)

Written to .forge/config.json with provenance. Summary:
- pipeline_mode: adaptive (default, source=default)
- jit.enabled: true (meta-agent override - composite >= 3)
- replanning.enabled: true (default retained)
- replanning.max_cycles: 1 -> 3 (meta-agent override - release-scale task warrants more replan headroom; ambiguity=3 mid-range, but composite=5 is the escalation signal)
- replanning.divergence_threshold: 0.3 (default retained - no need for early-divergence bias)
- verification.dimension_weights: overridden to {security: 0.3, correctness: 0.35, spec_alignment: 0.2, robustness: 0.15} (meta-agent - correctness-leaning because Tracks 1+2 are quality work)
- skip_phases: [] (full pipeline)
- approval_gates: [3, 4, 6] (default retained)
- tdd.mutation_threshold: 70 (default retained)
- fast_track.enabled: null - remains auto-detect, but fast-track is ineligible by composite complexity; orchestrator will honor precondition failure

No CLI-pinned values. All overrides are source: "meta-agent".