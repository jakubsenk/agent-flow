# Phase 1 — Research Questions (SKIPPED, sourced from DRAFT spec)

**Run:** 2026-04-26-A-research-run1
**Source:** `docs/superpowers/specs/2026-04-26-A-research-questions-DRAFT.md`
**Scope:** Q1–Q12 (sections C1, C2, C3, C4 + Q12 framework discovery).
Q13–Q22 are explicitly out of scope for Run 1 (separate Run 2 will deep-dive Top 10 from Q12).

## Question inventory (read in full from spec file)

| ID | Cluster | Topic |
|---|---|---|
| Q1 | C1 — Agent prompt engineering | Hloubka agent system promptu (minimalistic vs maximalistic, 2025-2026 best practices) |
| Q2 | C1 | Granularita agenta (BMAD large-role vs ceos narrow-spec) |
| Q3 | C1 | Univerzální vs per-projekt vs hybrid agent (fixer-base + project deltas) |
| Q4 | C1 | Stateful vs stateless agenti (CrewAI threads / LangGraph state / AutoGen GroupChat memory) |
| Q5a | C2 — Pipeline architecture | Pipeline shape diversity v ekosystému |
| Q5b | C2 | Migration ROI evidence (markdown/code → declarative) |
| Q5c | C2 | LLM-as-config-interpreter reliability |
| Q5d | C2 | Public release expectations (Claude Code plugin user expectations) |
| Q6 | C2 | Human-in-the-loop placement (zero/per-stage/strategic/event-driven) |
| Q7 | C2 | Sub-agent dispatch vs in-agent tool-use |
| Q8 | C3 — Configuration philosophy | Generic+overlay vs per-project vs meta-gen (final shape) |
| Q9 | C3 | Pipeline as config DSL expressiveness (YAML / +conditionals / +graph / Turing-complete) |
| Q10 | C4 — Quality measurement | Benchmarking metrics (SWE-bench, HumanEval, GAIA, production tools) |
| Q11 | C4 | Trade-off matrix template (per Q5/Q8 variants × dimensions) |
| Q12 | C5 — Competitive landscape | Framework discovery & shortlist (15–20 ranked, Top 10 auto-selected for Run 2) |

## Phase 2 dispatch plan

5 paralelních agentů s heterogenními personas:
1. **Akademická literatura** — arxiv, SWE-bench, GAIA, prompt engineering papers
2. **Produkční engineering** — Cursor, Cline, Aider, Devin, Replit Agent, postmortems
3. **OSS framework deep-dive** — LangGraph, AutoGen, CrewAI, BMAD, MetaGPT (code-level)
4. **Komunita & adoption signals** — HN, Reddit, X/Twitter, Discord, awesome-lists
5. **Oficiální guidance** — Anthropic, OpenAI, Google docs/blog 2025-2026

Synthesis agent: aggregate, dedupe, rank.
Review loop: Tier 1 (structural completeness) + Tier 3 adapted (source diversity, coverage breadth, confidence calibration). Max 3 rounds.
