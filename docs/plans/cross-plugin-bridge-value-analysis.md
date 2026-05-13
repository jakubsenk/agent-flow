# Cross-Plugin Bridge: Value Analysis

**Date:** 2026-03-31
**Status:** DRAFT — awaiting critical review
**Source:** Brainstorm synthesis from 3 agents + manual correction after user challenge

---

## Thesis

Connecting filip-superpowers and ceos-agents via a bridge has significant value because the plugins have complementary strengths that cannot be replicated within either plugin alone.

## The Two Plugins' Strengths

### forge (filip-superpowers) — Divergent Thinking
- 5 parallel research agents investigating codebase/web
- 3 heterogeneous brainstorm personas + judge-mediated synthesis
- Adversarial spec (EARS format, 3 parallel reviewers, devil's advocate)
- TDD with hidden 20% test reserve (fixer never sees these)
- Dependency-ordered planning with review validation

### ceos-agents — Convergent Execution with Specialized Agents
- 19 domain-specialized agents with Process (numbered steps) + Constraints (NEVER rules)
- Each agent reads project-specific knowledge: Module Docs, Agent Overrides, Automation Config
- Iterative fixer <-> reviewer loop (opus, 5 iterations, AC fulfillment verdicts)
- acceptance-gate verifies EACH AC with code + test evidence
- Block -> rollback -> tracker comment -> next issue (failure handling pipeline)
- Tracker lifecycle: issue creation -> state transitions -> PR -> post-merge verify
- Project scaffolding: spec -> skeleton -> CI -> Docker -> git init -> push -> tracker issues

## Key Comparison: forge Phase 7 vs ceos Execution

| Dimension | forge Phase 7 (execute) | ceos-agents execution |
|---|---|---|
| Agent type | Generic sonnet with Phase 0-generated prompt | 19 specialists with defined processes + constraints |
| Code review | Self-review (PASS_TO_PASS) | Adversarial reviewer (opus, min 3 issues, severity tiers, AC fulfillment) |
| Iteration | None within Phase 7; Phase 8 can send back max 2x | fixer <-> reviewer loop, 5 iterations per subtask |
| Project knowledge | Reads codebase | Reads codebase + Module Docs + Agent Overrides + Automation Config |
| Quality gates | Post-hoc (Phase 8 verification) | In-line (AC fulfillment, acceptance-gate, review severity) |
| Failure handling | BLOCKED status -> human escalation | Block -> rollback-agent reverts -> tracker comment -> continue |
| TDD | Tests from Phase 5 provided as context | Fixer follows red-green-refactor process |
| Diff limits | No explicit limit (200 LOC per task) | <=100 lines per diff (hard constraint) |
| Tracker | None | 6 trackers via MCP (YouTrack, GitHub, Jira, Linear, Gitea, Redmine) |
| Publishing | None | Publisher agent creates PR with template, manages state transitions |
| Customization | config.json (4 levels) | Automation Config + Agent Overrides per agent per project |

## The "Double Adversarial Sandwich" — Emergent Capability

Neither plugin alone can produce this chain:

```
forge-spec (3 adversarial reviewers: compliance + quality + devil's advocate)
  -> forge-tdd (test-first from spec, 80/20 visible/hidden split)
    -> ceos code-analyst (traces call hierarchy, test coverage gaps, module docs)
      -> ceos fixer <-> reviewer (adversarial opus loop, 5 iterations, AC fulfillment)
        -> ceos acceptance-gate (per-AC evidence from code + tests)
          -> ceos test-engineer (project-convention tests)
            -> forge-verify (5-agent adversarial panel WITH hidden test suite)
```

The hidden 20% test reserve from forge-tdd becomes an independent verification dimension that the ceos-agents fixer never sees. This provides structural honesty.

## Proposed Architecture

```
/forge "build task management app"
  Phase 0-6: research -> brainstorm -> spec -> TDD -> plan     [forge]
  Phase 7 replacement:
    Step A: ceos-agents scaffold (from forge spec)              [ceos]
    Step B: ceos-agents implement-feature per subtask           [ceos]
      -> code-analyst -> fixer <-> reviewer -> test-engineer -> publisher
  Phase 8: verify (against hidden tests from Phase 5)           [forge]
```

## Why This Has Value

1. **forge is better at divergent thinking** — 5 research agents, 3 brainstorm personas, adversarial spec, TDD with hidden tests. ceos-agents cannot replicate this (different architecture).

2. **ceos is better at convergent execution** — not because it "writes better code", but because it has 19 specialists with defined processes, constraints, and quality gates. forge-execute is a generic sonnet with a prompt. ceos fixer is opus with TDD, <=100 line diffs, module docs, Agent Overrides, and an adversarial reviewer.

3. **The combination creates something that doesn't exist** — the double adversarial sandwich. No single plugin and no conventional monolithic tool can produce this quality chain.

## Open Questions

- Format translation: forge-plan prose -> ceos architect YAML (maps_to blocker)
- Scope estimate: 3 files (optimistic) vs 600 lines/7 files (pessimistic)
- Build now or after E2E validation?
- Is the "double adversarial sandwich" actually better in practice, or just theoretically appealing?

## Brainstorm Source

Full brainstorm with 3 agent proposals + judge synthesis in `.forge/phase-3-brainstorm/`.
