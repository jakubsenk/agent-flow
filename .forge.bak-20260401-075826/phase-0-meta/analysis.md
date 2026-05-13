# Phase 0 Meta-Agent Analysis

## Task Type Classification

**Primary type:** Feature (new E2E test harness)
**Secondary type:** Quality Infrastructure (test framework expansion)
**Domain:** Developer tooling / test engineering for a markdown-definition plugin

This is a feature task that creates a comprehensive end-to-end test harness covering all three ceos-agents pipelines (bug-fix, feature, scaffold). The harness must validate structural contracts, cross-reference integrity, pipeline step ordering, agent dispatch correctness, and configuration contract compliance — all through static analysis of markdown definitions (no runtime execution possible).

## Complexity Assessment

| Dimension | Score (1-5) | Rationale |
|-----------|-------------|-----------|
| Scope | 5 | Cross-cuts all 3 pipelines (bug-fix, feature, scaffold), 19 agents, 25 commands, 11 core contracts, state schema, config contract, mock project |
| Ambiguity | 4 | Test strategy for "E2E validation of markdown definitions" requires design — no runtime to exercise, must define what "end-to-end" means for pure-markdown plugin |
| Risk | 3 | Medium — no production code changes, but false positives could erode trust in the harness; false negatives could miss real contract violations |
| Integration complexity | 4 | Must integrate with existing 25-scenario test harness, maintain bash-only approach, fit existing run-tests.sh runner |
| Domain knowledge | 4 | Requires deep understanding of all 3 pipeline flows, agent contracts, core patterns, config parsing rules, state schema |

**Composite complexity:** HIGH (weighted average: 4.0)

## Fast-Track Eligibility Assessment

### Tier A: Hard Disqualifiers

| Criterion | Result |
|-----------|--------|
| Scope > 3 files touched | YES — new test scenarios + mock project updates + potentially existing test updates |
| Ambiguity score >= 3 | YES (4) — significant design decisions in test strategy |
| Risk score >= 4 | NO (3) |
| Requires architectural decisions | YES — test taxonomy design, coverage strategy, scenario structure |

**Tier A verdict:** NOT ELIGIBLE for fast-track (multiple disqualifiers)

### Tier B: Not evaluated (Tier A already disqualified)

## Domain Identification

**Primary domain:** Test Engineering (bash-based structural validation)
**Secondary domains:** Pipeline Architecture, Configuration Contract Validation, Markdown Static Analysis
**Testing paradigm:** Structural/content validation (not runtime E2E) — the plugin is pure markdown with no executable code to run

## Codebase Context Assessment

### What exists today

The existing test harness (`tests/harness/run-tests.sh`) has 25 scenarios organized as independent bash scripts. Current coverage:

**Structural tests (5):** File existence counts, frontmatter field presence, section order validation, model assignment verification, core file contract sections.

**Pipeline consistency (1):** Block comment format, git add patterns, retry limit mentions, safety checks, rollback context — but only for commands containing fixer/reviewer/test loop.

**Pipeline phase tests (5):** Individual agent property checks (fixer retry awareness, reviewer APPROVE/REQUEST_CHANGES, publisher main protection, test-engineer constraints, triage block template).

**Core/state tests (3):** Core file existence + contract sections, state schema field presence, core reference counts in pipeline commands.

**Scaffold tests (8):** V2 happy path, input conflicts, no-implement compat, spec loop, canary announcement, infra flag format, resume override, v5.6.1 regression guards.

**Cross-cutting (3):** Read-only agent verification, browser verification skip, no-MCP-jargon errors.

**Profile tests (1):** Profile parsing presence in pipeline commands.

### What is missing (gap analysis)

1. **Pipeline step ordering validation:** No test verifies that pipeline steps appear in the correct order within each command (e.g., triage before code-analyst before fixer in fix-ticket).

2. **Cross-pipeline agent dispatch consistency:** No test verifies that the same agent is called with the same model across all pipelines (e.g., fixer is always opus in fix-ticket, fix-bugs, implement-feature, and scaffold).

3. **State.json write completeness:** No test verifies that every pipeline phase mentioned in commands actually has a corresponding state.json update instruction.

4. **Core contract adherence in commands:** Existing test only checks reference counts. No test verifies that commands follow the actual process described in core contracts (e.g., config-reader required sections, block-handler rollback conditions).

5. **Config contract completeness:** No test verifies that the mock project's Automation Config covers all required sections as defined in CLAUDE.md config contract, or that optional section defaults match the documented defaults.

6. **Feature pipeline coverage:** Zero dedicated feature-pipeline tests (implement-feature.md is only tested for Fix Verification presence and core reference counts).

7. **Cross-reference integrity:** No test verifies that agent names referenced in commands match actual agent file names, or that core/ files referenced in commands actually exist.

8. **Pipeline profile stage mapping:** No test verifies that stage mapping tables in fix-ticket, fix-bugs, and implement-feature are consistent and complete.

9. **Block handler invocation patterns:** No test verifies that every "proceed to Block handler (step X)" reference in commands is preceded by a valid failure condition.

10. **Acceptance criteria flow:** No test verifies the AC propagation chain (triage/spec-analyst -> fixer -> reviewer -> acceptance-gate) is documented consistently across pipelines.

11. **Decomposition contract:** No test verifies decomposition heuristics thresholds, task tree validation rules, or AC coverage check consistency across fix-ticket and implement-feature.

12. **Hook execution order:** No test verifies that hooks appear in the correct order (pre-fix before fixer, post-fix after fixer, pre-publish before publisher).

13. **Deployment verifier:** No test validates the deployment-verifier agent or check-deploy command.

## Confidence Scoring

| Dimension | Confidence | Notes |
|-----------|------------|-------|
| Task understanding | 95% | Clear goal: comprehensive E2E validation harness for structural/contract testing |
| Scope estimation | 85% | ~15-20 new test scenarios, but exact count depends on granularity decisions |
| Implementation approach | 90% | Bash structural tests matching existing patterns — well-established paradigm |
| Risk assessment | 85% | Main risk is test maintainability and false positive rate |

**Overall confidence:** 89%

## Routing Decision

```json
{
  "pipeline_mode": "full",
  "fast_track": false,
  "jit": {
    "enabled": false,
    "reason": "Full pipeline needed — test strategy design requires brainstorm + spec phases"
  },
  "replanning": {
    "enabled": true,
    "max_cycles": 1,
    "trigger_conditions": ["test_failure_rate_above_20pct", "coverage_gap_found_during_verify"]
  },
  "agent_scaling": {
    "research_agents": 2,
    "brainstorm_personas": 3,
    "execution_agents": 3,
    "verification_agents": 2
  },
  "model_tiers": {
    "research": "sonnet",
    "brainstorm": "opus",
    "spec": "opus",
    "tdd": "sonnet",
    "plan": "opus",
    "execute": "sonnet",
    "verify": "opus"
  },
  "review_rounds": 2,
  "verification_dimensions": {
    "correctness": 0.30,
    "completeness": 0.25,
    "consistency": 0.20,
    "maintainability": 0.15,
    "performance": 0.10
  }
}
```

## Security Evaluation

```json
{
  "evaluated": false,
  "reason": "Not fast-track eligible — Tier A disqualified"
}
```
