# Phase 3: Brainstorm — ceos-agents v6.8.0

Generate 3 proposals from HETEROGENEOUS personas for implementing the v6.8.0 bundle (Autopilot + Observability Hooks D10 + Real-Time Cost Visibility). Each persona must bring a fundamentally different design philosophy — not stylistic variants of the same idea. The judge will synthesize the best elements across all three.

## Persona 1: Forge-Parity Consistency Maximalist (CONSERVATIVE)

You are a **Forge-Parity Consistency Maximalist** — 15 years building declarative orchestration systems, and you believe the only sustainable way to ship cross-plugin cost tracking is byte-identical mirroring of the reference (forge.json). For Real-Time Cost Visibility, you refuse to invent field names; you read an actual `forge.json` from `C:/gitea_filip-superpowers/` and copy the exact schema (`tokens_estimated`, `duration_ms`, `tool_uses`, `started_at`, `completed_at`) into each ceos-agents state.json stage. For webhook payloads, you study `core/post-publish-hook.md`'s existing curl pattern line-by-line and apply it identically to the three new events (same `--max-time 5`, same heredoc, same advisory-on-failure). For Autopilot config, you insist all 7 keys match the roadmap line 634 enumeration verbatim. You challenge: "If the roadmap says `tokens_used`, but forge.json says `tokens_estimated`, WHICH wins? Answer: forge wins, because the user said mirror forge 1:1. Override the roadmap word." You favor renaming state.json fields to align with forge over inventing new names.

**Strengths:** zero drift from reference, predictable external consumption, easy /metrics aggregation across forge + ceos runs.
**Weaknesses:** may import forge design decisions that don't fit ceos (e.g., `tokens_estimated` is a forge-specific euphemism; ceos-agents has REAL token counts from Task tool, not estimates).

## Persona 2: External-Consumer-First Innovator (INNOVATIVE)

You are an **External-Consumer-First Innovator** — you think about v6.8.0 from the perspective of the external monitoring dashboard or Grafana ingester that will consume webhook events and state.json files. For Observability Hooks D10, you propose a richer payload than the roadmap's minimum (`{step_name, duration, iteration_count}`): add `run_id`, `phase`, `iteration_index_of_N`, `blocked: bool`, `previous_stage_duration_ms` — because monitoring teams always want one more field and adding it later is a breaking change for payload parsers. For Autopilot, you propose emitting `autopilot-started` / `autopilot-completed` events distinct from per-issue `pipeline-started` / `pipeline-completed`, so dashboards can distinguish a batch run from a single-issue run. For /metrics, you propose a new `--format json` flag that emits machine-readable aggregates so external ingesters don't parse markdown tables. You challenge: "What does the consumer NEED, not what is minimally easy to emit?"

**Strengths:** future-proof payload, batch-run visibility, machine-readable aggregation.
**Weaknesses:** larger payload footprint, more fields to document, MINOR impact risk if event names conflict with v6.9.0 plans.

## Persona 3: Blast-Radius-Skeptical Pragmatist (SKEPTICAL)

You are a **Blast-Radius-Skeptical Pragmatist** — 12 years maintaining the plugin that everyone depends on, and you have been burned by additive-looking changes that turned out to break downstream consumers. You interrogate every proposal: "What happens when a v6.8.0 plugin writes state.json with new usage fields, and a user on v6.7.2 runs `/resume-ticket` against it?" (Answer: `/resume-ticket` ignores unknown fields — but only if `core/state-manager.md` reads permissively. You grep for this and confirm.) For Autopilot, you challenge whether shipping `--dangerously-skip-permissions` guidance in a skill markdown is safe: what if a user copies the CLI invocation into a cron job without the lock file? You propose the lock file be CREATED BY the skill itself on first step, not left to the user's invocation script, because skills run in a process context that can guarantee cleanup. For Observability Hooks, you ask: "What if the webhook URL is slow and fires 50 `step-completed` events per pipeline — do we debounce? Batch? Fire-and-forget?" You favor minimum viable scope with explicit `NOT_IN_SCOPE` exclusions so the design document itself prevents scope creep in v6.8.1.

**Strengths:** risk-aware, backward-compatibility-first, explicit exclusions prevent surprise follow-up work.
**Weaknesses:** may under-ship (miss an opportunity where a small additional field would prevent a v6.8.1 breaking change).

## Task Instructions

Each persona proposes a COMPLETE approach covering all three items:

### Item 1: `/ceos-agents:autopilot` skill
- Exact `skills/autopilot/SKILL.md` structure (frontmatter + Steps 0...N)
- Lock file mechanism — where created, when removed, stale detection (120min per roadmap line 634), Windows atomicity
- Two-query classification logic — Bug first, Feature second, overlap resolution
- Error boundaries — MCP/lock failure stops, per-issue errors skip (configurable)
- Exact `### Autopilot` config section — 7 keys in `| Key | Value |` table with defaults
- CLAUDE.md optional-sections table update
- core/config-reader.md keys to add (7 keys with dot-notation)

### Item 2: Observability Hooks (D10)
- Exact payload schemas for `pipeline-started`, `step-completed`, `pipeline-completed`
- Granularity decision — which events fire when (every fixer iteration? only top-level stages?)
- Where to fire each event in pipeline skills (fix-ticket, fix-bugs, implement-feature, scaffold, plus Autopilot)
- `core/post-publish-hook.md` vs new `core/pipeline-events.md` — refactor or extend?
- CLAUDE.md Notifications section — what new `On events` tokens?
- Backward compat with existing `pr-created`, `ceos-agents-block` events

### Item 3: Real-Time Cost Visibility
- Exact state.json field additions — per-stage shape AND top-level `pipeline` accumulator shape
- `state/schema.md` update — field definition table rows + JSON example
- Schema version bump — stay at "1.0", bump to "1.1", or bump to "2.0"
- Where to capture Task-tool usage metadata — exact pseudocode for each skill's dispatch sites
- Fixer-reviewer loop accumulation — cumulative semantics
- Pipeline summary table output — when (end of pipeline? in the PR body? in pipeline.log?)
- `/metrics` aggregation update — new fields the skill must read

## Success Criteria

- 3 distinct complete proposals with explicit trade-offs for EACH item
- Each proposal addresses all 3 items (no per-item-single-proposal mixing)
- Each proposal specifies file paths AND line-level diff direction for at least 5 files
- Forge-parity persona proves byte-identical matching via at least one concrete forge.json citation
- Innovator persona specifies at least 3 non-roadmap payload fields with rationale
- Skeptic persona identifies at least 3 explicit NOT_IN_SCOPE exclusions and at least 2 backward-compat risks
- Exclusive decision points clearly marked: schema version bump choice (which?), event granularity (which?), `core/` refactor vs extend (which?)
- Judge synthesis section at end: recommends best element from each proposal with rationale

## Anti-Patterns

- Do NOT produce 3 proposals that differ only in wording
- Do NOT expand scope beyond the three roadmap items (no `/autopilot-status` new skill, no reporter agent, no dashboard rewrite)
- Do NOT propose breaking changes to Automation Config (roadmap explicitly requires backward compat at line 643, 651)
- Do NOT propose changing forge.json — that is a different repo, out of scope
- Do NOT ignore Windows lock-file behavior (Skeptic must address it)
- Do NOT use token counts as billing numbers — they are informational only (roadmap line 714)
- Do NOT skip the judge synthesis section

## Codebase Context

{{CODEBASE_CONTEXT}}

Pure-markdown Claude Code plugin. Test framework: `./tests/harness/run-tests.sh`. Version via `/ceos-agents:version-bump` (v6.7.2 -> v6.8.0 MINOR). Roadmap ground truth: `docs/plans/roadmap.md` lines 619-716. Existing webhook pattern: `core/post-publish-hook.md` Step 3 (curl --max-time 5, heredoc, advisory on failure). Existing events: `pr-created` (post-publish-hook), `ceos-agents-block` (block-handler). State schema currently v1.0 at `state/schema.md`. Forge reference at `C:/gitea_filip-superpowers/` — read a real forge.json for exact usage-field names before copying. 28 skills today; 29 after Autopilot ships.
