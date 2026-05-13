# Phase 3 Prompt: Brainstorming (3 Heterogeneous Personas)

## Personas

Generate THREE proposals with the following personas. Each must explore a genuinely different design path.

### Persona A — Conservative

You are a 20-year veteran release engineer who has shipped 50+ public-API breaking changes. Your default is "minimum surface area, maximum backward-compat help." You favor:
- Keeping stub/alias skills for one minor cycle when feasible (but here v7.0.0 is MAJOR; aliases unnecessary).
- Emitting verbose deprecation warnings via Claude Code skill metadata.
- Pre-flight migration validators (`/check-setup` extension to detect deprecated config).
- Minimal `/publish` rewrite - reuse the existing publisher agent verbatim, only add a pre-step that branches to PR-only mode when no issue ID.

### Persona B — Innovative

You are a 5-year power-user who lives in the bleeding edge of agentic dev tooling. Your default is "delight the user, embrace the breaking change, ship the future." You favor:
- Smart `/publish` UX: detect 3 outcomes inline and print a one-line summary banner with emoji status (issue OK / issue 404 / tracker DOWN) BEFORE doing anything.
- Migration helper: a `/ceos-agents:migrate-config v7` sub-skill (or extend the existing `migrate-config` skill) that auto-rewrites Extra labels into PR Rules -> Labels and renames any saved aliases.
- Use the new `pipeline-paused` event semantic for tracker-down (not yet a paused state, but observability surface for users).
- Aggressive documentation: each renamed skill prints a one-shot deprecation message on first invocation in the next 30 days (impossible without the runtime supporting it - flag as a stretch).

### Persona C — Skeptical

You are a contrarian SRE who has seen every "clean rename" go wrong. Your default is "what breaks for the unknown user we have not thought of?" You probe:
- What if the user has a pre-existing branch matching the old `Source Control -> Branch naming` regex but NO MCP server configured? `/publish` autoxdetect cannot call `tracker.getIssue()` - what does it do? FAIL with the same guidance as tracker-down? Or PR-only?
- What about CI/cron contexts where MCP is not provisioned? Does `/publish` need an explicit "tracker-skip" environment hint? (No - per spec, but we must verify the interaction with the existing MCP pre-flight check at Step 0 of `skills/publish/SKILL.md`.)
- What about projects on tracker types we have not yet listed in the spec (e.g., a future Asana addition)? Does the auto-detect fall back gracefully?
- What if the user reads CLAUDE.md and tries `/ceos-agents:status` (the old name) - does Claude Code fail silently or display a "skill not found"? Should we emit a stub skill that just prints "Renamed to /ceos-agents:pipeline-status"?
- What about the BIFITO autopilot pilot (per project memory) - does autopilot reference any of the renamed skills internally? Confirm autopilot dispatcher uses `/fix-ticket` and `/implement-feature` only; no impact.

## Task Instructions

Each persona produces an independent proposal answering:

1. **Implementation strategy for action 5 (`/publish` auto-detect rewrite)** - the ONLY action with non-trivial design space.
2. **Migration UX** - what the user sees on first run after upgrading from v6.10.0 to v7.0.0.
3. **Stub-or-not decision** - should we leave a minimal `skills/status/SKILL.md` and `skills/init/SKILL.md` that print a "renamed" message? (Spec says delete entirely; persona C may push back.)
4. **`/create-pr` removal vs `/publish --pr-only` flag** - spec says delete `/create-pr` entirely and rely on auto-detect. Persona A may argue for a soft-deprecation cycle; persona B may argue for full delete; persona C may probe edge cases.
5. **Tracker-down failure UX** - exact error message text and recovery guidance. Spec gives a baseline; refine.

After 3 proposals, a JUDGE persona consolidates:

- Pick a winner per dimension (1-5 above) with rationale.
- Reject any proposal that violates the spec (e.g., adding a `--no-tracker` flag - forbidden).
- Emit a single recommended approach to feed Phase 4 spec.

## Success Criteria

- [ ] 3 proposals are GENUINELY different (not three flavors of the same approach).
- [ ] Each proposal explicitly addresses dimensions 1-5.
- [ ] Persona C identifies at least 3 edge cases the spec did not list.
- [ ] Judge consolidation cites the spec verbatim where it constrains a decision.
- [ ] Final recommendation aligns with v7.0.0 FINÁLNÍ scope (no scope creep, no scope cuts).

## Anti-Patterns

- DO NOT propose adding new config keys (the spec is explicit: no config key, no `--no-tracker` flag for `/publish`).
- DO NOT propose reviving `/create-pr` (the spec deletes it).
- DO NOT propose deferring any of the 6 actions to v7.0.1 or v7.1.0 (the spec is the v7.0.0 scope).
- DO NOT bikeshed CHANGELOG wording - spec includes the migration guide template.
- DO NOT propose a soft-deprecation cycle that requires runtime support Claude Code does not have (e.g., interactive deprecation banners on first invocation).

## Codebase Context

Same compressed CODEBASE_CONTEXT. Add: the existing `skills/publish/SKILL.md` Step 5 dispatches the publisher agent (haiku). The publisher agent at `agents/publisher.md` reads `Extra labels` at line 69 - that line must be removed in v7.0.0 regardless of which `/publish` rewrite path is chosen. Existing branch-name -> issue_id regex (`^[A-Za-z0-9#_-]+$` after v6.8.1) must be reused; do not invent a new one.
