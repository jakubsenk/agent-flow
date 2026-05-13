# Cross-Plugin Bridge: Summary of Exploration

**Date:** 2026-03-31
**Status:** EXPLORING — no decision made, saved for later
**Participants:** Filip + Claude brainstorm session

---

## The Problem

scaffold produces basic, "doesn't offend, doesn't excite" output. forge produces expert-quality output but has no infrastructure (tracker, SC, git, CI, Docker, tracker cards).

Filip wants: forge-quality thinking + scaffold infrastructure. One command. No duplication.

## What We Validated

1. **Cross-plugin Skill() calls work.** `Skill(skill='filip-superpowers:forge-status')` resolves from ceos-agents context. Confirmed empirically.
2. **Cross-plugin Agent dispatch works.** Claude sees agents from both plugins (e.g., `ceos-agents:fixer`, `ceos-agents:reviewer`) and can dispatch them from any context.
3. **scaffold already has `--spec` and `--issue` flags.** Infrastructure for external input exists.

## What We Learned

### forge strengths (cannot be replicated in ceos-agents without duplication)
- 5 parallel research agents + web search
- 3 heterogeneous brainstorm personas + judge-mediated synthesis
- Adversarial spec (EARS format, 3 parallel reviewers, devil's advocate)
- TDD with 80/20 hidden test reserve
- 5-agent adversarial verification panel (Phase 8) using hidden tests
- Dependency-ordered planning with review validation

### scaffold strengths (cannot be replicated in forge without duplication)
- Tracker integration (6 trackers via MCP) — reads issues, creates cards from epics
- Source control setup (git init, push, remote)
- CI/Docker/CLAUDE.md generation
- Scaffolder agent (project skeleton with tests)
- fixer <-> reviewer loop (opus, adversarial, 5 iterations, AC fulfillment)
- test-engineer, e2e-test-engineer, acceptance-gate
- Block handling with rollback
- Resume capability
- `--issue` flag (start from tracker card)
- `--infra` flag (skip tracker/SC ceremony for quick POCs)

### Where scaffold is shallow (the real problem)
- Step 0b brainstorm: max 5 questions, 1 agent (vs forge's 5 research + 3 brainstorm)
- Step 1 spec: spec-writer + spec-reviewer, 1 opus (vs forge's 3 adversarial reviewers)
- Step 5 architecture: 1 architect pass (vs forge's reviewed dependency graph)

## Options Explored

### Option 1: Don't connect plugins — use sequentially
```
/forge "vykazovani casu"                              → quality app
/scaffold --spec .forge/phase-4-spec/ --no-implement  → add infrastructure
```
**Problem:** scaffold --no-implement doesn't handle existing codebase well. Also loses forge's Phase 8 verify after scaffold implementation.

### Option 2: forge calls scaffold at Phase 7
```
/forge "vykazovani casu" --scaffold
  Phases 0-6: forge thinking
  Phase 7: Skill('ceos-agents:scaffold', args='--spec ...')
  Phase 8: forge verify
```
**Problem:** scaffold expects to be the entry point (Step 0-INFRA, tracker setup). Called mid-forge, infrastructure ceremony is awkward. Also: spec format mismatch (forge EARS vs scaffold epics/*.md).

### Option 3: scaffold calls forge for thinking phases (--deep flag)
```
/scaffold --issue PROJ-42 --deep
  Steps 0-INFRA, 0-MCP: scaffold (tracker, SC — already works)
  Step 0b: Skill('filip-superpowers:forge-research')    ← deep research
  Step 1:  Skill('filip-superpowers:forge-spec')         ← deep spec
  Steps 2-4: scaffold (checkpoint, skeleton, git, tracker cards — already works)
  Step 5:  Skill('filip-superpowers:forge-plan')         ← deep plan
  Steps 6-7: scaffold (fixer/reviewer/test — already works)
  Step 8b: Skill('filip-superpowers:forge-verify')       ← adversarial verify
  Step 9: scaffold report
```
**Pros:** Entry point is scaffold (has tracker). Forge called only where scaffold is weak. No duplication — forge does thinking, scaffold does infrastructure + execution.
**Cons:** Couples the plugins via Skill() calls. Spec format mismatch still exists (forge EARS output needs to map to scaffold epics/*.md).

### Option 4: forge dispatches ceos agents at Phase 7
```
/forge "vykazovani casu"
  Phases 0-6: forge thinking
  Phase 7: dispatch ceos-agents:scaffolder, ceos-agents:fixer, ceos-agents:reviewer, etc.
  Phase 8: forge verify
```
**Pros:** Each agent is a graph node for ASYSTA. forge orchestrates, ceos agents execute.
**Cons:** ceos agents expect Automation Config (scaffolder generates it, so this resolves itself). No tracker integration unless forge also handles that.

### Option 5: Improve scaffold internally (--deep flag, no forge dependency)
Add parallel research agents, multiple reviewers, dependency graphs to scaffold's Steps 0b, 1, 5.
**Problem:** Duplicates forge patterns. Filip explicitly rejected this: "nesedi... duplikuji logiku."

### Option 6: Manual workflow now, ASYSTA orchestration later
```
/forge "vykazovani casu"           → quality app
/scaffold --spec ... --no-implement → infrastructure
/forge-verify                       → verify with hidden tests
```
Three commands, zero coupling. ASYSTA later chains them as graph nodes.
**Problem:** Three commands is friction. --no-implement doesn't handle existing codebase.

## Unresolved Questions

1. **Spec format mismatch:** forge produces EARS requirements (REQ-NNN, formal-criteria.md). scaffold expects epics/*.md with user stories. Any integration needs a translation layer or format alignment.
2. **Entry point:** Should the user start from forge (deeper thinking) or scaffold (tracker integration)? Both are valid depending on use case.
3. **Automation Config:** ceos agents need it. Scaffolder generates it. Timing depends on which option is chosen.
4. **Is connecting plugins worth it at all?** The review found the value is real but smaller than initially thought. forge already has decent code review (Code Constitution + code-quality-reviewer + Phase 8 panel).
5. **ASYSTA as future orchestrator:** If ASYSTA will eventually configure and run the whole pipeline as a graph, should we invest in plugin-level integration now, or just make both plugins work well independently and let ASYSTA connect them?

## Critical Review Findings (from adversarial review)

1. forge's Phase 7 code review is BETTER than initially claimed (Code Constitution + code-quality-reviewer + Phase 8 panel) — document had understated this
2. "Double adversarial sandwich" is theoretical, never tested
3. "Each agent reads Module Docs/Agent Overrides/Config" was exaggerated (2/19 read Module Docs, 0/19 read Agent Overrides directly)
4. Cost-benefit analysis is missing (30-50+ agent dispatches per full run, hours of wall time, significant token cost)
5. Simplest alternative (--forge-context flag, ~50 lines) captures ~80% of value

## Filip's Context

- Both plugins are Filip's, developed by him
- Primary use cases: POC apps (for CEO to try), migrations (SSIS→.NET, manual tests→Playwright, App A→App B in tech X), AI-assisted development workflow
- ASYSTA (gitea.internal.ceosdata.com/cmd/ceos-cmd) will visualize pipeline as graph (nodes, links, groups) — future orchestration layer
- forge is expensive (tokens) but excellent quality
- scaffold is the operational backbone — easy project integration, customizable agents
- Both plugins will serve as foundation for autonomous AI development

## Brainstorm Artifacts

- 3-agent brainstorm + judge synthesis: `.forge/phase-3-brainstorm/`
- Devil's advocate review: returned inline (9 findings, 2 CRITICAL)
- Empirical fact-check: returned inline (8 claims checked)
- Alternatives analysis: `docs/plans/cross-plugin-bridge-alternatives-REVIEW.md`
- Initial value analysis (biased, corrected): `docs/plans/cross-plugin-bridge-value-analysis.md`
