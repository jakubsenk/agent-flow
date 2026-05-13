# Forge brief — overlay TOML dispatch wiring hotfix (v9.0.3)

**Date:** 2026-04-29
**Target version:** v9.0.2 (PATCH — PRIORITY, preempted prior jq cleanup which moves to v9.0.3)
**Type:** Critical hotfix — production regression
**Plugin scope only.** No consuming-project changes required (consumers continue to write `customization/*.toml` per the published migration guide).

---

## Background

The plugin documents `customization/*.toml` as the supported per-project agent override format (since v8.0.0). The migration guide announces "TOML-only is the supported override format" and "if your customization/ directory still contains `{agent}.md` files, they are now ignored with `[ERROR]`." `/ceos-agents:setup-agents` generates `.toml` files. `examples/customization/*.toml` ships three reference files. Helper `skills/setup-agents/lib/toml-merge.sh::resolve_overlay()` parses + merges TOML overlays.

## Problem

The runtime never reads `.toml` overlays. Agents run with their bare default prompts; the `## Project-Specific Instructions` block never appears in dispatched prompts; no overlay guidance reaches the LLM. Symptom is silent: pipelines complete normally, PRs land, but project-specific override behavior (e.g., "prefer codegraph MCP over Grep/Glob") never engages.

Two independent defects in the v9.0.1 main branch (commit `fa44838`):

**Defect A — injector hardcodes `.md`:**
`core/agent-override-injector.md` Process step 1 reads:
> 1. Construct the candidate file path: `{override_path}/{agent-name}.md`

No `.toml` branch. No reference to `lib/toml-merge.sh`. Confirmed: `grep -r resolve_overlay` across the repo returns 0 callers — the helper is orphaned.

**Defect B — most dispatch sites never invoke the injector:**
Audit of `Task(subagent_type=...)` dispatch sites in `skills/fix-bugs/steps/`, `skills/implement-feature/steps/`, `skills/check-deploy/SKILL.md`:

| Pipeline | Step | Has Task() | Has injection |
|---|---|---|---|
| fix-bugs | 01-triage | yes | **no** |
| fix-bugs | 02-impact | yes | **no** |
| fix-bugs | 03-reproduce | yes | **no** |
| fix-bugs | 04-fixer-reviewer-loop | yes | yes (`.md`-only) |
| fix-bugs | 05-test | yes | **no** |
| fix-bugs | 06-acceptance-gate | yes | **no** |
| fix-bugs | 07-publish | yes | **no** |
| implement-feature | 01-spec | yes | **no** |
| implement-feature | 02-architect | yes | yes (`.md`-only) |
| implement-feature | 04-fixer-reviewer-loop | yes | yes (`.md`-only) |
| implement-feature | 05-test | yes | yes (`.md`-only) |
| implement-feature | 06-acceptance-gate | yes | yes (`.md`-only) |
| implement-feature | 07-publish | yes | **no** |
| check-deploy | (single) | yes | yes (`.md`-only) |

**8 of 13 dispatch step files never look at `customization/`.** Even if Defekt A were fixed, the majority of agents would still receive the bare prompt.

## Empirical evidence

Run `/ceos-agents:fix-ticket CMD-6137` in `asysta-ai/ceos-cmd` (2026-04-29 15:38–16:20 UTC, session `9ac6979e-7e2c-4777-8c7e-f91fa4e88d4a`).

Project setup at run time (all correct):
- `.mcp.json` had codegraph entry with valid Bearer token + workspace URL
- `.claude/settings.json` allow-listed `mcp__codegraph__*`
- 5 `customization/*.toml` files on disk (analyst, architect, spec-analyst + others) with correct codegraph + monorepo `[[process_additions]]`
- Plugin v9.0.0 installed

Result (from local topic-graph SQLite DB, ground truth):
- 8 agent dispatches
- **0 prompts contained `## Project-Specific Instructions`**
- **0 prompts contained the word `codegraph`**
- **0 `mcp__codegraph__*` tool calls** out of 100+ total tool calls in the session
- analyst `--phase impact` did manual exploration: 24× Read + 20× Bash

## Reference materials

- **Full prior analysis:** `docs/plans/2026-04-29-overlay-dispatch-regression-evidence.md` (in-repo copy of `C:\Users\FSABACKY\Downloads\2026-04-29-overlay-dispatch-regression.md`) — kolega's writeup from the original debugging session. Includes a reference fix sketch (Part A/B/C/D) under "Fix" heading. **Treat this as evidence + a strong reference, not as a fixed solution.** Forge phase 1 should evaluate whether the proposed dispatch wiring (BEFORE-Task() canonical 3-step protocol) is the right shape, or whether a different approach (e.g., centralized dispatch wrapper) is preferable.
- Affected files in main: `core/agent-override-injector.md`, `core/overlay/toml-overlay.md`, `skills/setup-agents/lib/toml-merge.sh`, `skills/fix-bugs/steps/*.md`, `skills/implement-feature/steps/*.md`, `skills/check-deploy/SKILL.md`, `examples/customization/*.toml`, `docs/guides/migration-v7-to-v8.md` (migration claims), `tests/scenarios/v8-overlay-*.sh` (existing doc-level tests that did NOT catch the regression).

## Open questions for forge phase 1

1. **Dispatch wiring shape:** per-step injection (current `04-fixer-reviewer-loop` pattern, replicated to 13 sites) vs. centralized wrapper (single helper called from every step) vs. agent-side self-load (agent reads its own overlay)? Each has tradeoffs (DRY, traceability, override-path resolution timing). Forge should evaluate.
2. **Legacy `.md` handling:** the v8 migration guide promises `[ERROR]` on legacy `.md` overlays. No enforcement code exists. Options: (a) keep promise, emit `[ERROR]` and ignore `.md` (clean, breaks any project still on `.md`); (b) soft-deprecate — load `.md` with `[WARN]`, prefer `.toml` if both exist (lenient, lets v8-era projects upgrade in their own time); (c) silently support both (drift from migration guide). Forge should pick + justify.
3. **Test coverage shape:** existing `v8-overlay-*.sh` tests grep spec text (doc-level). They passed while the runtime was broken for 8 months. Phase 4/5 should design an integration test that creates a real project with `customization/{agent}.toml`, runs a dispatch (mock or real), and asserts the dispatched prompt contains `## Project-Specific Instructions`. Single test of this shape would have caught both defects.
4. **Provenance logging:** should every dispatch log `agent={name} overlay_source=toml|md|none overlay_path=...` to `.ceos-agents/pipeline.log`? Helps future regression detection.
5. **Failure handling:** what if TOML parse fails? `python3` not on PATH? Permission error on customization dir? Pipeline must NEVER block on overlay failure (overlay is advisory, not load-bearing). Confirm `[ERROR]`/`[WARN]` to stderr + return empty + continue.

## Constraints

- **Backward-compat:** existing `.md` overlay format (v7-era) — see open question 2 above.
- **No new dependencies:** plugin invariant per CLAUDE.md ("pure markdown plugin, no build, no deps"). `python3` for TOML parsing already used by `skills/setup-agents/lib/toml-merge.sh` and is acceptable. `jq` is NOT available (see v9.0.2 polish queue).
- **PATCH classification:** runtime aligns with already-shipped doc contract. No new agent fields, no new config keys, no new skills, no contract changes. If forge research concludes that any of these ARE needed, escalate to user before proceeding (would push to MINOR / v9.1.0 with renumbering of Demo / G / Node.js Runtime).
- **Slot priority:** preempted prior v9.0.2 jq dep cleanup (which moves to v9.0.3) per user decision 2026-04-29 — production regression takes the next slot.
- **Plugin only:** no changes to `asysta-ai/ceos-cmd`, `ceos-agents-web`, or any consumer.

## Success criteria

1. After fix, running `/ceos-agents:fix-ticket {issue}` in any project with `customization/{agent}.toml` files produces dispatched prompts that contain `## Project-Specific Instructions` blocks for **every agent that has a corresponding `.toml` file**.
2. `pipeline.log` (or equivalent) provides per-dispatch provenance: which overlay source was used, which path, or `none`.
3. New integration test scenario in `tests/scenarios/` exercises the full path (overlay file → injector → dispatched prompt). Test PASSes on fixed branch, FAILs on main if applied to current main.
4. All existing `v8-overlay-*.sh` scenarios continue to PASS (no regression in parser / validator / merger).
5. Empirical re-run of the codegraph integration scenario in `asysta-ai/ceos-cmd` (or local equivalent) shows non-zero `mcp__codegraph__*` tool calls when codegraph overlay is configured.
6. CHANGELOG entry under `[9.0.2]` documents the fix + references this brief + the upstream regression analysis.

## Out of scope

- Bigger overlay redesign (single-file vs. multi-file, schema changes, additive vs. replace semantics) — track separately if forge research surfaces it.
- New override formats (YAML, JSON, etc.) — TOML is the contract.
- Removing `.md` legacy support entirely (forge picks the path under question 2).
- Migrating `lib/toml-merge.sh` from `skills/setup-agents/lib/` to a top-level `lib/` (cosmetic; the regression report's path reference was wrong but the file works fine where it is).
- Anything in `ceos-agents-web` or consumer projects.

## Phases recommended

Forge phases 1 (research) → 4 (spec) → 5 (TDD) → 6 (plan) → 7 (execute) → 8 (verify) → 9 (publish). Phase 0/2/3 (brainstorm/research-deep) can be light — the regression analysis already gives strong evidence. Phase 4 spec must answer the 5 open questions above.

## Pre-flight checks for the operator

Before running forge in clean session, verify:
- Working tree clean on `main` at v9.0.1 (`fa44838`).
- `.claude/settings.local.json` not staged.
- Untracked artifacts (`.forge.bak-*`, `grep.exe.stackdump`, etc.) ignored or moved.
- ~~The kolega's regression doc at `C:\Users\FSABACKY\Downloads\2026-04-29-overlay-dispatch-regression.md` is reachable from forge agents (or copy into repo as `docs/plans/2026-04-29-overlay-dispatch-regression-evidence.md` for traceable input).~~ DONE 2026-04-29 — copied to `docs/plans/2026-04-29-overlay-dispatch-regression-evidence.md`.
