# Phase 0 Meta-Analysis - forge-2026-04-28-001

## 1. Task Type Classification

**Primary task type:** `feature`

**Rationale:** The user is requesting a new capability - formalized machine-readable I/O contracts for the 18 agents in `agents/*.md`. Today, agent inputs and outputs are implicit in prose Process steps; the user wants them made explicit. This is net-new structure introduced into the plugin contract surface, not a bug fix, refactor, or pure documentation task. The deliverable touches 18 agent definition files, the skills that dispatch them, the test harness, and reference documentation. Backward-compatibility is a hard constraint because v8.0.0 already shipped without these contracts.

**Secondary task type signals:**
- `design` - substantive design decisions required (where contracts live: frontmatter vs. dedicated section vs. sidecar; how validation runs; what schema language to use)
- `test` - explicit ask for tests, must integrate with `tests/harness/run-tests.sh`
- `migration` - additive change with backward-compat invariant for `customization/` Agent Overrides

These three signals do NOT escalate the routing decision (the primary remains `feature`), but they inform phase weighting and persona selection downstream.

## 2. Complexity Assessment

| Axis | Score | Justification |
|------|-------|---------------|
| Scope | 5 | Cross-cutting: 18 agent files + 29 dispatching skills (primarily fix-bugs, fix-ticket, implement-feature, scaffold, setup-agents) + core/agent-override-injector.md + core/agent-states.md + tests/scenarios + docs/reference/agents.md + CLAUDE.md sections + plugin version bump. Broadest possible scope. |
| Ambiguity | 4 | Multiple credible designs: frontmatter extension via YAML schema block; dedicated Inputs/Outputs sections in agent body; sidecar agents/contracts/*.json; JSON Schema vs. typed list vs. EBNF. User explicitly asks for best-practice research and a defended recommendation. Versioning question (MAJOR vs MINOR) also open. |
| Risk | 4 | Backward-compat HARD constraint (v8.0.0 customization/ overrides must not break). Output-format contracts are referenced by skills and external tooling. New cross-file invariants likely needed. Mis-design risks: breaking 92 v8 test scenarios, breaking BIFITO/drmax pilots, committing to a contract surface hard to evolve in v10+. Not security-critical, capped at 4. |

**Composite complexity:** `max(5, 4, 4) = 5`

**Implications for pipeline scaling:**
- Maximum agents
- Model tier: opus eligible for fixer/reviewer/architect
- Review rounds: 3-5 per phase
- JIT recommendation: `enabled = true` (composite >= 3)
- Replanning: enabled, `max_cycles = 2` (default 1 insufficient for ambiguity 4)
- Approval gates: 3, 4, 6 (defaults; Phase 6 mandatory)

## 2b. Fast-Track Eligibility

**Result:** INELIGIBLE.

- Composite complexity = 5 > 2 -> fails Eligibility Precondition #1.
- Even if confidence reached 0.9, the complexity gate alone is decisive.
- `fast_track.enabled` = null (auto-detect) does not override the complexity gate.
- task_type = `feature` does not appear in VALID_TARGETS as Phase-6-skip, so routing-compatibility precondition would pass on its own - but the complexity gate fails first.

Per the meta-prompt: "If any precondition fails, skip to Section 3." Tier A and Tier B security evaluations are NOT executed (they only run when fast-track preconditions pass). No `security_evaluation` JSON block emitted. No `fast_spec.json` written. Pipeline proceeds normally through all 9 phases.

## 3. Domain Identification

- **Language/Runtime:** Markdown documentation (agents, skills, docs), bash test harness, no compiled language. Optional: YAML for frontmatter, JSON Schema for contract files (TBD by brainstorm/spec).
- **Framework:** Claude Code plugin system (skills + agents + frontmatter contracts). No build system, no dependencies. Pure markdown plugin.
- **Domain:** Agent orchestration / workflow automation tooling. Specifically: contract design for LLM-driven agents.
- **Specialty concerns:**
  - Backward compatibility (HARD): existing `customization/` Agent Overrides from v8.0.0 must continue to work without modification.
  - Schema design: tradeoff between expressiveness (JSON Schema), simplicity (typed list), human-readability (prose).
  - Validation strategy: static (lint at commit time via tests/harness) vs. dynamic (runtime validation by dispatching skills).
  - Cross-file invariants: new invariants likely needed; must integrate with existing 3 in CLAUDE.md.
  - Versioning: MAJOR vs MINOR is itself a brainstorm question - additive optional contract sections could be MINOR; mandatory schema for all 18 agents is closer to MAJOR.

## 4. Codebase Context Assessment

### Existing Patterns and Conventions

**Agent file structure (`agents/*.md`):**
- YAML frontmatter with exactly 4 fields: `name`, `description`, `model`, `style`.
- Body sections in fixed order: `## Goal` -> `## Expertise` -> `## Process` (numbered steps) -> `## Constraints` (NEVER rules + Block Comment Template).
- Some agents use `## Phase Dispatch` (e.g., analyst.md for `--phase triage` / `--phase impact`; test-engineer.md for `--e2e`). Phase Dispatch sections appear inside the body and split Process into sub-flows.
- Output format is prose-embedded markdown code blocks inside Process step "Output:" - e.g., `## Triage Analysis`, `## Fix Report`, `## Code Review`. These are de-facto contracts but NOT machine-validated.
- Mode-dependent input pattern: agents read context flags like `Mode: feature` / `Mode: scaffold` to switch input expectations. Implicit polymorphism.
- EXTERNAL INPUT defense: every agent has explicit `--- EXTERNAL INPUT START ---` / `--- EXTERNAL INPUT END ---` marker handling for prompt-injection defense.

**Skill dispatch contract (`core/agent-override-injector.md`):**
- Skills resolve `agent_name` + `override_path` -> read `{override_path}/{agent-name}.md` -> append as `## Project-Specific Instructions`.
- This is the SOLE extension point for project-level customization. Any I/O contract design must keep this point unchanged or strictly additive.

**Test harness (`tests/harness/run-tests.sh`):**
- Plain bash: iterates `tests/scenarios/*.sh`, runs each with `bash`, treats exit 0 = PASS, 77 = SKIP, anything else = FAIL.
- Each scenario sets `REPO_ROOT`, defines `fail()` helper, runs assertions via `grep -qE`, `find`, `wc -l`, `diff -q`.
- 297 scenarios today. Examples relevant: `frontmatter-completeness.sh` (still references pre-v8 21-agent list - in v8.0.1 polish queue), `v8-agents-enumeration.sh`, `v8-agents-analyst-shape.sh`, `read-only-agents.sh`.

**Docs reference structure (`docs/reference/`):**
- agents.md, automation-config.md, skills.md, pipeline.md, pipelines.md, hooks.md, trackers.md, config.md, execution-loop.md - all updated when agent shape changes.

### Tech Debt and Known Issues

- `frontmatter-completeness.sh` still lists pre-v8 21-agent set (v8.0.1 polish item 6). Phase 7 should refresh OR explicitly leave for v8.0.1 to avoid scope creep.
- Output formats inconsistent across agents (Triage Analysis, Fix Report, Code Review) - no canonical naming scheme.
- Mode-switching is implicit polymorphism; design must decide per-agent (one shape with mode variants) vs. per-mode (multiple contracts per agent).

### Compressed Codebase Context (for downstream prompts)

ceos-agents Claude Code plugin v8.0.0. Pure markdown - no build, no deps. 18 agents under agents/*.md, each with YAML frontmatter (name, description, model, style) and body sections Goal -> Expertise -> Process (numbered) -> Constraints (NEVER rules). Outputs are prose-embedded markdown code blocks inside Process "Output:" steps - de-facto contracts, NOT machine-validated. 29 skills under skills/, dispatch agents via Claude Code Task tool. core/agent-override-injector.md is the sole extension point for per-project customization (reads customization/{agent-name}.md, appends as Project-Specific Instructions). Tests: bash harness at tests/harness/run-tests.sh, 297 scenarios in tests/scenarios/*.sh, each scenario sets REPO_ROOT, uses grep/find/diff, exit 0/77/N=PASS/SKIP/FAIL. Cross-File Invariants section (CLAUDE.md) currently has 3 invariants - extend with care. Backward-compat hard constraint: customization/ Agent Overrides from v8.0.0 MUST continue to work. Versioning policy: agent output format changes = MAJOR; adding optional config sections = MINOR.

## 5. Domain Expertise Consumption

No domain template loaded for this run (`routing.auto_select_template = false` per pre-merged config). Skipping section 5.

## 6. Template Auto-Selection Protocol

Skipping - `routing.auto_select_template = false`. No template selection performed.

```json
{
  "template_selection": {
    "selected": null,
    "confidence": 0.0,
    "rationale": "routing.auto_select_template is false - protocol skipped per config"
  }
}
```

## 7. Routing Decision

Written to standalone file: `.forge/phase-0-meta/routing-decision.json`

Summary: `task_type = "feature"`, `action = "full_pipeline"`, `target_skill = null`, `skip_profile = null`, `confidence = 0.92`.

## Confidence Scoring (Devin Pattern)

| Question | Score | Reason |
|----------|-------|--------|
| Q1: Is the task well-defined enough to execute? | 0.85 | Intent clear (formalize I/O contracts), backward-compat explicit, scope bound (18 agents). NOT specified: schema language, contract location, validation mechanism, MAJOR vs MINOR - appropriately deferred to brainstorm/spec. |
| Q2: Does the available context support execution? | 0.95 | All 18 agent files readable, test harness pattern well-established (297 prior scenarios), CLAUDE.md referenced sections read, prior v8.0.0 forge run archived. |
| Q3: Is the task within the pipeline capabilities? | 0.95 | Pure markdown work; no infra, no networking, no credentials. Forge has handled v6.x-v8.x agent shape rework runs successfully. |

**Composite confidence:** `min(0.85, 0.95, 0.95) = 0.85`.

Per `meta_agent.confidence_threshold = 0.7`: 0.85 >= 0.7 AND 0.85 < 0.9 -> "proceed with noted assumptions".

**Assumptions noted for downstream phases:**
1. Brainstorm must engage with the "no, current implicit form is fine" skeptical persona, even though user said they want explicit contracts.
2. Brainstorm/spec must produce a defended decision on schema language and location (frontmatter vs. body section vs. sidecar).
3. Spec must produce a defended versioning verdict (MAJOR vs MINOR) and update CLAUDE.md Versioning Policy + plugin.json. MEMORY allocates work to v9.0.0; whether v9.0.0 is MINOR (additive) or v9.0.0 reframed as MAJOR depends on chosen design.
4. Backward-compat is HARD: any scenario that would break a v8.0.0 customization/ override MUST fail.

## Pipeline Configuration Decisions

| Decision | Value | Source | Rationale |
|----------|-------|--------|-----------|
| pipeline_mode | adaptive | meta-agent (kept default) | Complexity 5 + ambiguity 4 benefits from JIT prompt refinement |
| jit.enabled | true | meta-agent | Composite complexity = 5 >= 3 |
| replanning.enabled | true | meta-agent (kept default) | High ambiguity warrants replanning headroom |
| replanning.max_cycles | 2 | meta-agent | Default 1 insufficient for ambiguity 4; cap at 2 to bound runtime |
| replanning.divergence_threshold | 0.3 | meta-agent (kept default) | No risk profile justifying tightening |
| skip_phases | [] | default | Full pipeline required per routing |
| approval_gates | [3, 4, 6] | default | Phase 6 mandatory; 3 (brainstorm) + 4 (spec) needed because user asked to verify best-practice and decide whether to do it |
| verification.dimension_weights | security 0.2, correctness 0.4, spec_alignment 0.3, robustness 0.1 | meta-agent | Correctness-leaning (must not break v8 BC); spec_alignment elevated (deliverable IS a contract spec); security low (no credentials, no public API); robustness low (markdown plugin). Sum = 1.0. |
| review.triage_enabled | false | default | No triage needed for design-heavy work |
| oracle.enabled | true | default | Useful for adversarial verification of contract design |

CLI-pinned values: None this run. All sources are `default` or `meta-agent`.

## Output Files Written

- `.forge/phase-0-meta/input.md` (verbatim user input)
- `.forge/phase-0-meta/analysis.md` (this document)
- `.forge/phase-0-meta/routing-decision.json` (standalone routing JSON, 7 keys)
- `.forge/phase-0-meta/prompts/research-questions.md`
- `.forge/phase-0-meta/prompts/research-answers.md`
- `.forge/phase-0-meta/prompts/brainstorm.md` (3 heterogeneous personas)
- `.forge/phase-0-meta/prompts/spec.md`
- `.forge/phase-0-meta/prompts/tdd.md` (bash harness specifics included)
- `.forge/phase-0-meta/prompts/plan.md`
- `.forge/phase-0-meta/prompts/execute.md`
- `.forge/phase-0-meta/prompts/verify.md` (adversarial personas)
- `.forge/phase-0-meta/prompts/completion.md`
- `.forge/config.json` (final merged config with `_provenance`)

No `fast_spec.json` written (fast-track ineligible).
No `clarifications/` written (confidence 0.85 above threshold 0.7).
