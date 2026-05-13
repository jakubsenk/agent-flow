# Phase 3: Brainstorm — Synthesis

## Synthesis Method
Judge-mediated synthesis with Free-MAD anti-conformity

## Proposal Scoring

| Criterion | Conservative (1) | Innovator (2) | Skeptic (3) |
|-----------|:-:|:-:|:-:|
| Backward compatibility | 5 | 2 | 5 |
| Architectural cleanliness | 3 | 5 | 3 |
| Migration safety | 5 | 2 | 4 |
| Non-code mode readiness | 3 | 5 | 3 |
| Implementation feasibility | 4 | 3 | 4 |
| Overall | **4.0** | **3.4** | **3.8** |

**Scoring rationale:**

- **Conservative** scores highest on safety and compatibility but under-delivers on architectural vision. The 12-PR sequence is realistic and every step is reversible.
- **Innovator** has the cleanest target-state design, but the 4-PR plan packs too much into PR 2 (every file in the repo touched), and the aggressive deprecation timeline (2 versions to removal) underestimates external system inertia. The architect-to-planner rename creates real, unmitigated cascading risk.
- **Skeptic** correctly identifies failure modes in both approaches but, having not seen the actual proposals, stress-tests caricatures rather than the specific designs. Its own proposal is solid but conservative-by-default, essentially a more cautious version of Agent 1 with better risk documentation. The convergence analysis is the most valuable section.

---

## Areas of Agreement (High-Confidence Decisions)

All three proposals converge on the following. These are **locked in** for Phase 4:

1. **State management (`.ceos-agents/{ISSUE-ID}/state.json`) must be introduced BEFORE any pipeline restructuring.** All three proposals place this as a top prerequisite. The schema converges on: pipeline position, step statuses, triage AC list, complexity, profile-in-use, iteration counts. Atomic writes (temp + rename). Heuristic fallback for pre-migration tickets.

2. **spec-analyst and forge spec-writer must NOT be merged.** Phase 2 Agents 3 and 6 independently confirmed incompatible constraints. All three proposals agree. Locked.

3. **The `[ceos-agents]` comment prefix is immutable.** 23 Class C templates in external systems. No proposal touches it. Locked.

4. **The `ceos-agents:` namespace is preserved.** All proposals keep the plugin name and namespace unchanged. Locked.

5. **Three fragile tests must be updated before any structural migration.** `happy-path.sh`, `verify-fail.sh`, `pipeline-consistency.sh` — all proposals agree on the fixes (dynamic inventory, label-based checks, discoverable pipeline files). Locked.

6. **The `.claude/reproduction-result.json` and `.claude/verification-result.json` race conditions must be fixed.** All proposals address this with per-issue-ID paths. Locked.

7. **New comment types use the existing `[ceos-agents]` prefix.** No versioned prefix. Additive only. Locked.

8. **Non-code mode verification must use "REVIEWED" (not "PASSED") with a confidence qualifier.** Both the Innovator and Skeptic call this out explicitly. The Conservative is silent but the reasoning is unambiguous. Locked.

9. **The `/build` entry point is the unified pipeline entry point** (added alongside existing commands). All three agree on this concept, differing only on implementation (command vs. skill) and deprecation timeline.

10. **No existing pipeline profile stage name is renamed.** All proposals agree that stage name renames are MAJOR-only and should be avoided.

---

## Topic-by-Topic Resolution

### 1. Directory Structure

**Conservative says:** Keep `agents/` flat and untouched (18 agents). Add `agents/modes/` for 6 new mode-specific agent variants (analysis-reviewer, strategy-reviewer, content-reviewer, analysis-spec-writer, strategy-spec-writer, content-spec-writer). Add `core/` for extracted shared patterns (10 files). Add `skills/build/` for the unified entry point. All existing paths preserved.

**Innovator says:** Keep `agents/` flat but add 4 new agents (planner, intake-agent, domain-analyst, synthesizer). Add `core/` for the pipeline engine (8 files). Add `modes/` as a top-level directory for mode adapters (6 files). Add `skills/build/`, `skills/ops/`, `skills/legacy/`. Deprecate `commands/` to thin redirects.

**Skeptic says:** Minimal changes. Keep all existing directories. Add `agents/planner.md` and 3 non-code agents as new files. Add `skills/build/` and `skills/pipeline-core/` (with includes). Add `commands/build.md` as a new command first, then migrate to a skill later. No renames, no restructuring.

**Judge's resolution:** The Conservative's structure wins with modifications from the Innovator.

- `agents/` stays flat. No subdirectory `agents/modes/` — the Conservative's 6 mode-variant agents are unnecessary complexity. The Innovator's approach of passing domain context blocks to existing agents (reviewer, spec-writer) via the mode adapter is cleaner and avoids maintaining parallel agent definitions. For the truly new capabilities (intake, domain analysis, synthesis), new agents are added to the flat `agents/` directory.
- `core/` is adopted for shared patterns with input/output/failure contracts (Conservative's design). NOT the Innovator's "engine" abstraction — this is a pure markdown plugin and "pipeline engine" overpromises.
- `modes/` is NOT a top-level directory. Mode adapter files live inside `skills/build/` as `mode-*.md` (Conservative's design using `$CLAUDE_SKILL_DIR`). This keeps mode logic co-located with the entry point that dispatches it.
- `commands/` is preserved. Commands are NOT deprecated to thin redirects in the first release. The Skeptic and Conservative are correct that the wrapper graveyard is worse than coexistence.

**Final directory additions:**
```
core/                          # Shared patterns (Conservative's design)
  config-reader.md
  mcp-preflight.md
  fixer-reviewer-loop.md
  block-handler.md
  agent-override-injector.md
  decomposition-heuristics.md
  profile-parser.md
  post-publish-hook.md
  fix-verification.md
  state-manager.md
agents/                        # Flat — new agents added, none renamed
  intake-agent.md              # NEW (non-code input ingestion)
  domain-analyst.md            # NEW (analytical/strategic reasoning)
  synthesizer.md               # NEW (output assembly for non-code)
skills/build/                  # NEW unified entry point
  SKILL.md
  mode-code-bugfix.md
  mode-code-feature.md
  mode-code-project.md
  mode-analysis.md
  mode-strategy.md
  mode-content.md
state/
  schema.md                    # State file documentation
```

### 2. Pipeline Engine Design

**Conservative says:** Extraction, not abstraction. Extract shared prose patterns into `core/*.md` files that commands reference by name. Commands remain the orchestrators. No "pipeline engine" — this is a pure markdown plugin. Core files have input/output/failure contracts.

**Innovator says:** A proper pipeline engine (`core/engine.md`) that reads mode adapters as declarative phase tables and dispatches phases in sequence. Inversion of control: the engine orchestrates, mode adapters are configuration. A `ReviewLoop` primitive replaces 4 separate fixer-reviewer loop implementations.

**Skeptic says:** Agrees with the Conservative — no engine abstraction. Extract patterns as include files. "A 'pipeline engine' in this context is just organized text." The command remains the orchestration authority.

**Judge's resolution:** The Conservative and Skeptic are correct on architecture, but the Innovator is correct on the review-loop primitive.

The "pipeline engine" concept is seductive but misguided for a pure-markdown plugin. There is no interpreter, no function dispatch, no import mechanism. The engine file would be a large prompt that says "read the mode adapter, then execute phases in order" — but the LLM executing a command already does exactly this. The engine adds an indirection layer without adding capability.

However, the Innovator's `ReviewLoop` concept is valuable. The fixer-reviewer loop IS duplicated across 4 commands with identical logic. Extracting it as `core/fixer-reviewer-loop.md` with a clear contract (Conservative's design) achieves the same deduplication without pretending there's a runtime engine.

**Decision:** Conservative's extraction model with Conservative's contract format. Mode adapters live in `skills/build/mode-*.md` and define phase sequences as documentation that the `/build` skill follows. The `/build` skill reads the appropriate mode file and follows its instructions. Existing commands (`fix-ticket`, `fix-bugs`, `implement-feature`, `scaffold`) continue to work by referencing the same `core/*.md` patterns.

### 3. Agent Merge Strategy

**Conservative says:** NO agent merges. All 18 agents unchanged. Mode dispatch at orchestration level. The architect agent is NOT renamed. For non-code modes, add 6 new agents in `agents/modes/` (variant reviewers and variant spec-writers per domain).

**Innovator says:** Merge architect + forge planner into `planner.md` (rename). Do NOT merge spec-analyst + spec-writer. Add 3 new agents (intake-agent, domain-analyst, synthesizer). Existing agents (reviewer, spec-writer) receive domain context blocks from mode adapters rather than needing per-domain variants.

**Skeptic says:** Do NOT merge agents. Keep `architect` unchanged for ceos pipelines. Add `planner` as a NEW separate agent for forge-style pipelines. Add 4 new agents (intake-agent, domain-analyst, content-reviewer, strategy-analyst).

**Judge's resolution:** NO merges, NO renames. The Conservative and Skeptic win on safety, the Innovator wins on agent economy.

- **architect stays as architect.** The Skeptic's Scenario 1 (silent AC coverage regression from mode bleed in a merged agent) and Scenario 3 (Agent Override silent failure on rename) are real, documented risks. The Innovator's claim that "consuming commands parse structure, not agent identity" is true but ignores the 3 other places where `architect` is hardcoded by name (rollback-agent skip list, discuss default panel, 6+ Task tool references). The rename creates cascading Class A changes with non-zero risk of one being missed.
- **No separate `planner.md` agent is needed either.** The forge planner's functionality (decompose into phases, no AC mapping) is handled by the `/build` skill's mode adapter calling the existing `architect` with forge-appropriate context. When no acceptance criteria are provided, the `maps_to` validation is vacuously satisfied (per Phase 2 Domain 3). This is the Conservative's insight — and it is correct.
- **For non-code modes:** The Innovator's approach of passing domain context blocks to existing agents (reviewer, spec-writer, spec-reviewer) is superior to the Conservative's 6 mode-variant agents. Domain checklists injected by the mode adapter are the same mechanism as Agent Overrides — proven, no new infrastructure. This means we need only 3 genuinely NEW agents: `intake-agent`, `domain-analyst`, `synthesizer`.
- **No `agents/modes/` subdirectory.** New agents go in the flat `agents/` directory.

### 4. Command -> Skill Migration

**Conservative says:** Commands stay permanently. Skills are added alongside. Only `/build` becomes a skill. The 20 utility commands remain commands forever. Deprecation is speculative and far-future (v7 or v8, "maybe never").

**Innovator says:** All commands become 5-line redirects in v6.0.0, routing to `/build` or `/ops` skills. Legacy skill provides backward compat. Commands fully removed in v7.0.0. Resume-ticket absorbed into `build --resume`.

**Skeptic says:** Add `/build` first as a command (not a skill), then migrate it to a skill in the next minor version as a canary. Only after the canary proves safe, migrate existing pipeline commands to skills in v6.0.0. Keep wrappers until v7.0.0.

**Judge's resolution:** The Skeptic's canary approach wins, with the Conservative's preservation of utility commands.

- `/build` is introduced as a NEW skill at `skills/build/SKILL.md`. Not a command first — the Phase 2 research confirms skills have unrestricted tool access and `$CLAUDE_SKILL_DIR` for sub-files, which is exactly what `/build` needs.
- The 4 pipeline commands (`fix-ticket`, `fix-bugs`, `implement-feature`, `scaffold`) are NOT deprecated. They are refactored to reference `core/*.md` patterns but remain fully functional commands. They coexist with `/build`.
- The 20 utility commands remain commands. They do NOT move to an `/ops` skill — there is no benefit. They are small, single-purpose, and the invocation syntax `/ceos-agents:status` works fine.
- `resume-ticket` remains a separate command but is updated to read `state.json` with heuristic fallback. It is NOT absorbed into `build --resume` — this would be a breaking change for users who have `resume-ticket` in scripts or muscle memory.
- Deprecation timeline: NOT specified in this release. After `/build` has shipped for at least 2 minor releases with zero regressions, a deprecation plan can be considered. The Conservative is right: "working code does not need to be removed to make an architecture diagram look cleaner."

### 5. Backward Compatibility

**Conservative says:** Zero breaking changes. The entire migration avoids a MAJOR version bump. Everything is additive MINOR/PATCH. Deprecation is speculative and deferred to v7/v8.

**Innovator says:** Aggressive but honest. v6.0.0 MAJOR for the engine + command deprecation + planner rename. v7.0.0 MAJOR for legacy removal. Two versions, not five.

**Skeptic says:** Iron rules: never change comment prefix, never change namespace, never remove commands in minor versions, never rename agents, never rename stage names. All new functionality is additive.

**Judge's resolution:** The Conservative and Skeptic win. No MAJOR version bump for this migration.

The Innovator underestimates the cost of breaking changes in a plugin ecosystem. The claim "the plugin has a small user base" is an assumption, not a verified fact. The `[CLAUDE-agents]` to `[ceos-agents]` precedent does NOT prove breaking changes are cheap — it proves they are survivable, which is not the same thing.

**Concrete backward compatibility rules:**
- No command removed or renamed
- No agent removed or renamed
- No config section removed or renamed
- No comment format modified
- No pipeline profile stage name modified
- All new features are additive (MINOR version bumps)
- The only MAJOR-worthy change is the eventual state.json schema becoming mandatory (removing heuristic fallback) — and that is deferred to a future version when all in-flight tickets have been completed

**Version plan:**
- v5.1.x PATCH: Race condition fix, test fixes, pre-existing gap fixes
- v5.2.0 MINOR: State infrastructure
- v5.3.0 MINOR: Core pattern extraction + `/build` skill (code modes)
- v5.4.0 MINOR: Non-code modes (analysis first, then strategy + content)

### 6. Non-Code Modes

**Conservative says:** Analysis mode first (in `/build` v1). Strategy and content in the next minor release. For each mode, create separate agent variants in `agents/modes/`. Phase mapping follows the forge 10-phase model adapted per mode.

**Innovator says:** All three non-code modes in scope for v6.1.0. Three new agents (intake-agent, domain-analyst, synthesizer) serve all modes. Mode adapters pass domain context blocks to existing agents.

**Skeptic says:** Add non-code modes as entirely new pipelines. New agents for new capabilities. Reuse existing agents where Phase 2 confirmed compatibility. Verification output clearly distinguished from code verification.

**Judge's resolution:** Analysis mode first (Conservative's phasing), with the Innovator's agent strategy (domain context blocks, not variant agents).

- **Phased delivery:** Analysis mode ships first because it has the highest overlap with existing agent capabilities (spec-writer, spec-reviewer, priority-engine). Strategy and content ship in the next minor release. The Conservative and Skeptic are right that shipping all three simultaneously is risky for a new capability with no real-world validation.
- **Agent strategy:** The Innovator's approach of passing domain context blocks to existing agents is adopted over the Conservative's per-domain agent variants. Reason: 6 mode-variant agents (3 reviewers + 3 spec-writers) create a maintenance burden — every change to `reviewer.md` must be considered across 4 files (base + 3 variants). Domain context injection through the mode adapter is the same mechanism as Agent Overrides and creates zero new agents for reusable capabilities.
- **Three genuinely new agents:** `intake-agent` (flexible input ingestion), `domain-analyst` (analytical/strategic reasoning), `synthesizer` (output assembly). These fill the 4 true capability gaps that cannot be addressed by adapting existing agents.
- **Verification honesty:** Non-code mode verification uses "REVIEWED" verdict with confidence qualifier (HIGH/MEDIUM/LOW), not "PASSED." Explicit disclaimer about qualitative vs. deterministic verification.

### 7. State Management

**Conservative says:** `.ceos-agents/{RUN-ID}/state.json` with detailed per-step schema. Run-ID is ISSUE-ID for tracker runs, timestamp for non-tracker runs. Browser artifacts move to the state directory. Atomic writes. Heuristic fallback preserved indefinitely. State Manager contract in `core/state-manager.md`.

**Innovator says:** `.ceos-agents/` directory replacing both `.claude/decomposition/` and `.forge/`. Richer schema with per-phase output JSON files (triage.json, analysis.json, plan.json, review-log.json), config-cache.json, and pipeline.log (append-only event log). Heuristic fallback removed in v7.0.0.

**Skeptic says:** `.ceos-agents/{ISSUE-ID}/state.json` as prerequisite before any structural migration. Schema v1 with checkpoint, steps, context (AC list, complexity, profile, iteration counts). Atomic writes. Heuristic fallback. Per-issue event log (events.log).

**Judge's resolution:** The Conservative's schema as the foundation, with selective additions from the Innovator.

- **Directory:** `.ceos-agents/{RUN-ID}/` — all three agree.
- **state.json schema:** The Conservative's detailed schema (step statuses, triage data, fixer-reviewer iteration/verdict history, browser status, acceptance gate status, publisher status) is the most complete and most useful for resume. Adopted as-is.
- **Append-only event log:** Adopted from the Innovator. `.ceos-agents/{RUN-ID}/pipeline.log` with one JSON line per event. This is the forge.log pattern, proven and valuable for debugging and metrics. The Skeptic also recommends this.
- **Per-phase output files:** NOT adopted. The Innovator's triage.json, analysis.json, etc. create too many files. The state.json already captures the essential data (AC list, complexity, risk, iteration counts). Full agent outputs are too large and too variable to store reliably. The state file captures what resume needs; the event log captures what debugging needs.
- **Heuristic fallback:** Preserved indefinitely (Conservative and Skeptic). NOT removed in v7.0.0 (Innovator). The cost of maintaining the fallback is trivial; the cost of breaking resume for a ticket started before state.json was introduced is real.
- **`.claude/decomposition/{ISSUE-ID}.yaml`:** Continue reading (not writing) for backward compatibility. The state.json replaces it for new runs. The YAML path is never deleted from the codebase.

### 8. Migration Sequence

**Conservative says:** 12 PRs across 3 approval gates. Each independently revertible. Approximately 12-19 working days. Strict dependency ordering: race fix -> test fix -> new tests -> state -> core extraction (3 PRs) -> /build skill -> analysis mode -> strategy+content -> pre-existing gaps -> docs.

**Innovator says:** 4 PRs. PR 1 (prerequisites, v5.2.0). PR 2 (engine + code modes + planner rename + command deprecation + test restructure + docs, v6.0.0 MAJOR). PR 3 (non-code modes, v6.1.0). PR 4 (legacy removal, v7.0.0). PR 2 is a massive PR touching every file.

**Skeptic says:** 8 PRs. Canary approach: prerequisites first, state management second, shared includes third, `/build` as command fifth, then skill migration at major version boundary. Each PR under 500 lines.

**Judge's resolution:** The Conservative's 12-PR sequence is too granular; the Innovator's 4-PR sequence is too large. The Skeptic's 8-PR sequence is close to right. The merged plan uses **8 PRs across 3 gates:**

**PR 0: Pre-existing bug and gap fixes (v5.1.x PATCH)**
- Fix `.claude/` race condition (per-issue paths for browser artifacts)
- Fix spec-writer.md missing emoji in block comment
- Fix `discuss` gap in skill router
- Update 3 fragile tests (happy-path, verify-fail, pipeline-consistency)
- Add 4 new structural tests (frontmatter, model, read-only, section-order)
- Rollback: revert. Risk: zero.

**PR 1: State infrastructure (v5.2.0 MINOR)**
- Add `.ceos-agents/{ISSUE-ID}/state.json` schema and write logic to all 3 pipeline commands
- Add `core/state-manager.md` contract
- Add `state/schema.md` documentation
- Update `resume-ticket` to prefer state.json, fall back to heuristic
- Add state-schema test
- Rollback: revert. State.json is additive; heuristic fallback unchanged.

**GATE 1: Validate state infrastructure works with all 3 pipeline commands.**

**PR 2: Core pattern extraction (v5.2.x PATCH)**
- Create `core/` directory with all 9 shared pattern files
- Refactor `fix-ticket` to reference core files (proof of concept)
- Add `core-include-refs` test
- Rollback: revert. fix-ticket returns to inline logic.

**PR 3: Extend core extraction to remaining commands (v5.2.x PATCH)**
- Update `fix-bugs`, `implement-feature`, `scaffold` to use core files
- Rollback: per-command revert possible.

**GATE 2: All 4 pipeline commands refactored. Full test suite green.**

**PR 4: `/build` skill with code modes (v5.3.0 MINOR)**
- Create `skills/build/SKILL.md` with mode detection
- Create `mode-code-bugfix.md`, `mode-code-feature.md`, `mode-code-project.md`
- Update `skills/bug-workflow/skill.md` with build routing row
- Rollback: delete skill files. Existing commands unaffected.

**PR 5: New agents for non-code modes (v5.3.x PATCH)**
- Add `agents/intake-agent.md`, `agents/domain-analyst.md`, `agents/synthesizer.md`
- Structural tests for new agents
- Rollback: delete new files.

**PR 6: Analysis mode (v5.4.0 MINOR)**
- Create `skills/build/mode-analysis.md`
- Domain context blocks for reviewer, spec-writer, spec-reviewer adaptation
- Rollback: delete mode file. Code modes unaffected.

**PR 7: Strategy + content modes (v5.5.0 MINOR)**
- Create `skills/build/mode-strategy.md`, `skills/build/mode-content.md`
- Rollback: delete mode files. Analysis and code modes unaffected.

**GATE 3: All modes functional. Full test suite green. User acceptance testing.**

**Total: 8 PRs, ~10-15 working days.** Each PR under 500 lines. Each independently revertible. No MAJOR version bump. The system is strictly better at every PR boundary.

---

## Free-MAD Analysis

### Flaws in Conservative Approach

1. **Agent variant proliferation.** The Conservative creates 6 new agents in `agents/modes/` (analysis-reviewer, strategy-reviewer, content-reviewer, analysis-spec-writer, strategy-spec-writer, content-spec-writer) that are essentially copies of existing agents with different checklists. This is the opposite of DRY — every change to `reviewer.md` must be mentally cross-referenced against 3 variant files. The Innovator's domain context injection is the correct pattern: the mode adapter injects domain criteria into the existing agent's context, just like Agent Overrides do.

2. **Core file reference mechanism is unproven.** The Conservative's "Follow the process defined in `core/X.md`" pattern assumes the LLM will read the referenced file. This is not the `$CLAUDE_SKILL_DIR` mechanism (which is confirmed to work within skills). It is a prose instruction to an LLM to read a file by path. The Conservative acknowledges this risk but defers validation to a manual dry-run at PR #5 — 5 PRs into the migration. If it fails, the fallback is "keep duplicated logic in commands," which negates the entire core extraction effort.

3. **12 PRs is too many.** While each PR is small and safe, the 12-PR sequence creates a multi-week migration during which the codebase is in a transitional state. PRs 5-7 (core extraction split into 3 PRs by pattern type) could be a single PR without exceeding review capacity.

### Flaws in Innovator Approach

1. **PR 2 is unreviewable.** The Innovator's PR 2 touches every file in the repository: all commands become redirects, agent renamed, core/ and modes/ and skills/ all created, tests restructured, docs updated. This is a 10,000+ line change. The Innovator acknowledges this ("split into reviewable sections") but a single PR with a "reading order" is not the same as independently reviewable, independently revertible changes. A regression hidden in the command-to-redirect conversion could be masked by the simultaneous test restructure.

2. **The architect-to-planner rename is unnecessary risk for zero user benefit.** Users never see agent names directly — they see command names and skill names. The rename creates 6+ Class A changes (rollback-agent skip list, discuss default panel, Task tool references), requires Agent Override users to rename their customization files, and the `check-setup` warning is a poor substitute for silent continued operation. The Innovator argues "two agents with identical schemas add drift risk" — but the forge planner does not exist as a file in this repo, so there is no second agent to drift against.

3. **Aggressive deprecation timeline underestimates external system inertia.** Two versions from introduction to removal (v6.0.0 wrappers, v7.0.0 removal) assumes all consumers can update within one release cycle. External CI pipelines, team runbooks, and shell aliases update on their own schedule. The Skeptic correctly observes that migration guides are a per-user cost (50 teams = 50x the guide-writing cost).

### Flaws in Skeptic Approach

1. **The stress tests target strawmen, not the actual proposals.** The Skeptic explicitly states it did not have access to the Conservative and Innovator proposals. Its stress tests target "what the Conservative/Innovator would probably propose," not what they actually propose. For example, Skeptic's Scenario 1 (architect mode merge causing AC format bleed) stress-tests a merge that the Conservative explicitly rejects. Scenario 5 (skill migration breaks scripts) stress-tests a migration path that the Conservative does not propose. The stress tests are useful as general risk analysis but should not be read as critiques of specific design decisions.

2. **The canary approach delays skill validation too long.** The Skeptic proposes `/build` as a command first (PR 5), then migrating to a skill in the next minor (PR 8), then bulk-migrating existing commands to skills in v6.0.0. This means the skill system is not tested until PR 5 of an 8-PR sequence. Given that Phase 2 already confirmed skills have unrestricted tool access and `$CLAUDE_SKILL_DIR` works, the canary delay is overcautious. `/build` should be a skill from the start — the risk is known and bounded.

3. **The "pipeline-core" skill for includes is architecturally confused.** The Skeptic places shared patterns under `skills/pipeline-core/includes/` — but these are not a skill. They are not invoked as a skill. They are referenced by commands via file reads. Placing non-skill files in the `skills/` directory creates a misleading discovery path. The Conservative's `core/` top-level directory is the correct location.

### How the Merged Proposal Avoids These

- **No agent variant proliferation.** Domain context blocks (Innovator's approach) injected by mode adapters replace the Conservative's 6 variant agents. Only 3 genuinely new agents are created for capabilities no existing agent covers.
- **Core files in `core/` (not `skills/pipeline-core/`).** Avoids the Skeptic's architectural confusion. Core files are referenced by commands via prose instructions AND by the `/build` skill via `$CLAUDE_SKILL_DIR` reads. If prose references fail, the `/build` skill path still works.
- **`/build` is a skill from day one** (not a command first). Avoids the Skeptic's delayed validation. But existing commands are NOT deprecated, avoiding the Innovator's aggressive timeline.
- **No architect rename.** Avoids the Innovator's cascading Class A risk and the Agent Override silent failure that the Skeptic correctly identifies.
- **8 PRs, not 4 or 12.** Avoids the Innovator's unreviewable mega-PR and the Conservative's over-granularity.
- **Analysis mode first, then strategy + content.** Avoids the Innovator's risk of shipping three untested non-code modes simultaneously, while avoiding the Conservative's over-caution of deferring non-code modes to a distant future version.

---

## Unresolved Disagreements

These are genuine trade-offs where reasonable people disagree. They should be presented to the user at GATE 1:

1. **Core file reference mechanism.** Will the LLM reliably follow "Follow the process defined in `core/X.md`" instructions in commands? The Conservative assumes yes (with manual validation); the Skeptic is uncertain. If this fails, the fallback is: commands keep inline logic, and only the `/build` skill uses `$CLAUDE_SKILL_DIR` for core file reads. This should be validated with a manual test BEFORE committing to the core extraction PRs.

2. **Should `/build` auto-detect mode from natural language, or always require `--mode`?** The Innovator wants auto-detection with confirmation. The Skeptic warns about misclassification. The merged proposal recommends: auto-detection with mandatory confirmation unless `--mode` or `--yolo` is specified. But this is a UX decision that should be tested with real users.

3. **Heuristic fallback lifespan.** The Conservative and Skeptic say "indefinitely." The Innovator says "remove in v7.0.0." The merged proposal says "indefinitely" but this costs ongoing maintenance of two code paths in resume-ticket. If state.json proves reliable over 2+ versions, revisiting this decision is reasonable.

4. **Should the mock-mcp-server and mock-project be wired for integration tests?** The Innovator says yes (in PR 2). The Conservative and Skeptic keep grep-based tests only. The merged proposal defers this: the mock infrastructure wiring is valuable but is a separate project, not a prerequisite for this migration. It should be a follow-up initiative after the migration completes.

5. **Non-code mode scope for first release.** The merged proposal ships analysis first. But the Innovator makes a valid point: the 3 new agents serve all non-code modes, and building them narrowly for analysis and then widening is wasted effort. The compromise: agents are designed generically (domain-analyst handles both analytical and strategic reasoning via context), but only analysis mode ships in the first release. Strategy and content follow in the next minor.

---

## The Merged Proposal — Executive Summary

The migration unifies ceos-agents v5.1.0 with forge capabilities through a series of additive changes that preserve complete backward compatibility with no MAJOR version bump. The organizing principle is **additive composition**: new capabilities are layered on top of the existing system, which continues to function unchanged throughout and after the migration.

State management is the foundational prerequisite. A new `.ceos-agents/{ISSUE-ID}/state.json` file captures pipeline position, step statuses, triage acceptance criteria, complexity, active profile, and iteration counts. Resume-ticket reads this file first and falls back to its existing 7-level heuristic for pre-migration tickets. The heuristic fallback is preserved indefinitely. Browser artifacts move from the shared `.claude/` directory to per-issue state directories, fixing the race condition in fix-bugs parallel mode.

Shared pipeline patterns are extracted into a new `core/` directory containing 9-10 markdown files, each with explicit input/output/failure contracts. The four pipeline commands (fix-ticket, fix-bugs, implement-feature, scaffold) are refactored to reference these core files, reducing duplication while preserving each command's role as its own orchestrator. There is no "pipeline engine" abstraction layer — this is a pure markdown plugin and the extraction is textual deduplication, not runtime architecture.

A new `/build` skill at `skills/build/SKILL.md` provides the unified entry point for all pipeline modes. It detects the appropriate mode (code-bugfix, code-feature, code-project, analysis, strategy, content) from user input and flags, then reads the corresponding mode adapter file within its skill directory. Mode adapters define phase sequences and which agents to dispatch. Code modes delegate to the existing pipeline commands or replicate their logic using core files. The `/build` skill coexists with existing commands — users can use either path.

No agent is merged, renamed, or removed. All 18 existing agents remain at their current paths with their current names. The architect agent is NOT renamed to "planner." For non-code modes, existing agents (reviewer, spec-writer, spec-reviewer, priority-engine) receive domain context blocks from the mode adapter, replacing their software-specific checklists with domain-appropriate criteria. This is the same mechanism as Agent Overrides and requires no changes to the agent definitions. Three genuinely new agents are added: intake-agent (flexible input ingestion from URLs, PDFs, pasted text), domain-analyst (analytical and strategic reasoning), and synthesizer (output assembly and formatting for non-code deliverables).

Non-code modes are delivered in two increments. Analysis mode ships first because it has the highest overlap with existing agent capabilities. Strategy and content modes ship in the next minor release. Non-code verification explicitly uses "REVIEWED" (not "PASSED") verdicts with a confidence qualifier, making clear that LLM-based document review is qualitatively different from deterministic test execution.

All existing commands are preserved. No command is deprecated, renamed, or reduced to a redirect. The 20 utility commands remain unchanged. The 4 pipeline commands are refactored internally but their interfaces are identical. The `[ceos-agents]` comment prefix, `ceos-agents:` namespace, Automation Config format, and `maps_to: AC-{N}: {text}` output format are all unchanged. New comment types use the existing `[ceos-agents]` prefix.

The migration is executed in 8 PRs across 3 approval gates, each independently revertible, each under 500 lines. The version sequence is v5.1.x (patches for pre-existing bugs and test fixes), v5.2.0 (state infrastructure), v5.3.0 (core extraction + `/build` skill for code modes), v5.4.0 (analysis mode), v5.5.0 (strategy + content modes). Estimated timeline: 10-15 working days.

---

## Recommended Direction

Phase 4 specification should formalize the following in order:

1. **State.json schema** — the exact JSON schema with all fields, types, defaults, and validation rules. This is the single highest-value deliverable.
2. **Core file contracts** — input/output/failure for each of the 9-10 core pattern files.
3. **`/build` skill architecture** — mode detection logic, flag mapping, mode adapter contract.
4. **Mode adapter definitions** — phase sequences for code-bugfix, code-feature, code-project, and analysis modes. Strategy and content modes can be specified at a higher level and detailed later.
5. **New agent definitions** — intake-agent, domain-analyst, synthesizer: frontmatter, Goal, Expertise, Process, Constraints.
6. **Domain context block format** — the exact format for domain-specific checklists injected into reviewer, spec-writer, and spec-reviewer by mode adapters.
7. **PR sequence with test plans** — each PR's exact file list, version bump, rollback procedure, and acceptance criteria.

The specification should explicitly EXCLUDE: command deprecation timelines, architect-to-planner rename, runtime engine abstraction, per-phase output JSON files, and mock-mcp-server wiring. These are deferred to future planning, not included in this migration.
