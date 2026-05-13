# Phase 3: Brainstorming (3 heterogeneous personas)

**STATUS:** Phase 3 is SKIPPED for this run per routing-decision.json (`skip_profile.skip_phases = [3]`).

This prompt file is retained per the adaptive-mode mandate (all 9 phase prompts must exist to serve as JIT-failure fallback and Phase 8 verification context). If the orchestrator invokes Phase 3 despite the skip profile, use the personas and task guidance below.

## Why Phase 3 is skipped

This is a PATCH release bundling six explicitly enumerated, unambiguous items from docs/plans/roadmap.md. There are no architectural decisions to make:

- Item 1 format: match existing config-template conventions (no design space).
- Item 2 regex: conservative `^[A-Za-z0-9_-]+$` (no design space).
- Item 3: documentation of existing behavior (no design space).
- Item 4: reconcile prose to one consistent phrasing (no design space).
- Item 5: one regression test at a well-understood boundary (no design space).
- Item 6: fix exit-code propagation (one correct answer).

Composite complexity 3, ambiguity 1, risk 2. Brainstorming offers negligible marginal value.

---

## If Phase 3 runs anyway (fallback):

### {{PERSONA}} (three heterogeneous agents to dispatch)

**Agent A -- Conservative Patch-Release Engineer:**
You are a 15-year release engineer who ships PATCH releases weekly. Your bias: minimum surface area, zero feature creep, preserve backward compatibility above all. Propose the smallest edit that satisfies each item.

**Agent B -- Innovative Tooling Architect:**
You are a 10-year plugin architect who notices cross-cutting improvements. Your bias: while fixing these six items, identify 1-2 complementary improvements that are cheap and reduce future burden (e.g., adding the regex-validation pattern to a shared helper in core/). Strictly must not add work outside v6.8.1 scope.

**Agent C -- Skeptical Security Reviewer:**
You are a 12-year security reviewer specializing in Claude Code plugin boundaries. Your bias: focus on item 2 (path-traversal) and item 3 (payload injection). Question whether the proposed `^[A-Za-z0-9_-]+$` regex is strict enough; propose stricter alternatives and document trade-offs.

## {{TASK_INSTRUCTIONS}}

For each of the six roadmap items, each agent produces:

1. A one-paragraph proposed approach.
2. A list of files to edit with anticipated line-range scope.
3. Risk/tradeoff notes specific to the agent's persona bias.
4. At least one "what-if-this-goes-wrong" failure scenario and how to detect it.

Output to `.forge/phase-3-brainstorm/agents/agent-{A,B,C}.md`.

After parallel output, Judge Synthesis (Opus) merges into a single recommendation. Devil's Advocate review is part of the loop.

## {{SUCCESS_CRITERIA}}

- All three personas output complete proposals for all six items (3 x 6 = 18 mini-proposals)
- Proposals preserve backward compatibility (no Automation Config contract change)
- No proposal expands scope beyond the six items
- At least one agent (security) explicitly evaluates the regex strictness
- Conservative agent output is strictly subset-compatible with innovative agent output (no contradictions)

## {{ANTI_PATTERNS}}

1. **Do NOT propose MAJOR-version changes** (e.g., renaming config keys, reshaping webhook event schema).
2. **Do NOT propose v6.9.0+ roadmap items** (multi-host lock, JSON-format metrics flag, etc.) -- out of scope.
3. **Do NOT generate >7 items per agent per bullet section** -- keep proposals compact.
4. **Do NOT use personas to reopen closed design questions** -- the roadmap constrains scope.
5. **Do NOT recommend deferring any item** -- all six must ship in v6.8.1.
6. **Do NOT recommend adding new Automation Config sections** -- would bump to MINOR.
7. **Do NOT introduce new dependencies or runtime code** -- pure markdown.

## {{CODEBASE_CONTEXT}}

(Same as Phase 1 -- pure-markdown ceos-agents plugin. Six items listed in Phase 1 prompt. Rules: /ceos-agents:version-bump atomically updates plugin.json + marketplace.json + CHANGELOG + commit + tag. Tests via tests/harness/run-tests.sh, 140/140 baseline.)
