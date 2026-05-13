# Overlay Dispatch Regression — v9.0.0 Analysis & Fix

**Date:** 2026-04-29
**Affected version:** v9.0.0
**Fix version:** v9.1.0 (branch `feat/codegraph-integration`, commit `c21953b`)
**Reporter:** empirical detection during codegraph MCP integration testing in `asysta-ai/ceos-cmd`

---

## Executive summary

v9.0.0 shipped a half-migrated overlay system. The TOML pieces existed
(`core/overlay/toml-overlay.md`, `lib/toml-merge.sh::resolve_overlay()`) but
were never connected to the dispatch flow. As a result, `customization/*.toml`
files written by `/ceos-agents:setup-agents` (the format the migration guide
tells projects to use) were silently ignored at agent dispatch — agents ran
with bare default prompts, no Project-Specific Instructions block, no overlay
guidance reaching the LLM.

This caused complete failure of the codegraph MCP integration use case:
overlay told agents to prefer `mcp__codegraph__*` tools over Grep/Glob, but
the overlay never reached the agent, so agents fell back to manual exploration
and codegraph went unused even when the server was reachable and permissions
were correct.

---

## Architectural model

```
[1] WRITE side          [2] PARSE/VALIDATE        [3] DISPATCH side
─────────────────       ──────────────────        ──────────────────
setup-agents       ──→  toml-merge.sh        ←─── (NEVER CALLED)
generates *.toml        resolve_overlay()
                                                   skills/.../steps/
                                                   inline grep .md
```

The system was designed as three layers. Layer 2 was correctly implemented
and tested in isolation. Layer 1 was correctly migrated to write `.toml`.
Layer 3 — the actual dispatch surface that consumes overlays — was left on
the v7 path and never wired to layer 2.

---

## Two independent defects

### Defect A — `core/agent-override-injector.md` hard-codes `.md`

**File:** `core/agent-override-injector.md`
**Symptom:** Process step 1 read literally:

```
1. Construct the candidate file path: `{override_path}/{agent-name}.md`
```

There was no `.toml` branch. No reference to `lib/toml-merge.sh`. No call to
`resolve_overlay()`.

**Consequence:** A project with `customization/analyst.toml` (the format the
migration guide instructs) gets nothing from the injector, because the injector
only looks for `customization/analyst.md`.

`resolve_overlay()` in `lib/toml-merge.sh` was never invoked from any skill
or core file. The TOML loader was orphaned code.

**Why this regression slipped through v9.0.0 release:**

The v9.0.0 migration guide announced "TOML-only is the supported override
format" and "If your customization/ directory still contains `{agent}.md`
files, they are now ignored with `[ERROR]`." The announcement is documentation;
no code change in the injector enforces it. Test scenarios
(`v8-overlay-md-legacy-only.sh`, `v8-overlay-md-toml-coexist.sh`) verified the
documented behavior at the doc level — they grep the spec text for the right
keywords. They never tested whether `.toml` files actually load at runtime
because the runtime path was a documentation contract, not an integration
test.

### Defect B — most dispatch steps never invoke the injector

**Files:** `skills/fix-bugs/steps/*.md`, `skills/implement-feature/steps/*.md`,
`skills/check-deploy/SKILL.md`.

**Symptom:** Out of ~12 `Task(subagent_type=...)` dispatch sites across the
two pipelines, only `04-fixer-reviewer-loop.md` (in both pipelines) mentioned
overlay injection. The remaining 10 sites composed prompts inline and called
`Task()` without checking `customization/` at all.

| Pipeline | Step file | Has Task() | Has injection |
|---|---|---|---|
| fix-bugs | 01-triage | yes | **no** |
| fix-bugs | 02-impact | yes | **no** |
| fix-bugs | 03-reproduce | yes | **no** |
| fix-bugs | 04-fixer-reviewer-loop | yes | yes (but `.md`-only) |
| fix-bugs | 05-test | yes (×4) | **no** |
| fix-bugs | 06-acceptance-gate | yes | **no** |
| fix-bugs | 07-publish | yes | **no** |
| implement-feature | 01-spec | yes (×2) | **no** |
| implement-feature | 02-architect | yes | yes (but `.md`-only, AFTER dispatch) |
| implement-feature | 04-fixer-reviewer-loop | yes | yes (but `.md`-only) |
| implement-feature | 05-test | yes (×3) | yes (but `.md`-only, AFTER dispatch) |
| implement-feature | 06-acceptance-gate | yes | **no** |
| implement-feature | 07-publish | yes | **no** |
| check-deploy | (single) | yes | yes (but `.md`-only, AFTER dispatch) |

**Consequence:** Even if Defect A had been fixed (i.e., the injector accepted
TOML), agents like `analyst` (impact + triage), `test-engineer`, `publisher`,
`acceptance-gate`, `deployment-verifier`, `spec-analyst` would still never
receive an overlay — because the steps that dispatch them don't invoke the
injector at all.

**Note on the `02-architect.md` AFTER-dispatch case:** Even where injection
was documented, in two files (`implement-feature/02-architect.md`,
`implement-feature/05-test.md`, `check-deploy/SKILL.md`) the override-loading
paragraph appeared AFTER the `Task()` invocation. By then the agent has
already been dispatched with the bare prompt — too late to inject.

---

## Empirical evidence

A `/ceos-agents:fix-ticket` run on YouTrack issue CMD-6137 in `asysta-ai/ceos-cmd`
(2026-04-29 15:38–16:20 UTC, session `9ac6979e-7e2c-4777-8c7e-f91fa4e88d4a`)
provides the rock-solid trace.

**Project setup at run time** (all correct, none were the cause):
- `.mcp.json` had codegraph entry: `"type": "http"`, valid workspace URL, valid Bearer token
- `.codegraph/config.json` matched (`workspaceId: ws_d8c8bbc77da2482e`)
- `.claude/settings.json` allow-listed `mcp__codegraph__*`
- `customization/analyst.toml` had codegraph + monorepo `[[process_additions]]`
- `customization/architect.toml` had codegraph blocks
- `customization/spec-analyst.toml` had codegraph blocks
- Plugin v9.0.0 installed

**Topic-graph DB readout (`/home/vitek/CEOS/claude-asysta-graph/topic-graph.db`):**

```
Session: 9ac6979e (cwd: /home/vitek/CEOS/asysta-ai/ceos-cmd)
8 agent dispatches:

ceos-agents:analyst         (triage)   | codegraph_in_prompt: NO  | ProjSpec: NO
ceos-agents:analyst         (impact)   | codegraph_in_prompt: NO  | ProjSpec: NO
ceos-agents:fixer                      | codegraph_in_prompt: NO  | ProjSpec: NO
ceos-agents:reviewer                   | codegraph_in_prompt: NO  | ProjSpec: NO
ceos-agents:fixer           (iter 2)   | codegraph_in_prompt: NO  | ProjSpec: NO
ceos-agents:test-engineer              | codegraph_in_prompt: NO  | ProjSpec: NO
ceos-agents:acceptance-gate            | codegraph_in_prompt: NO  | ProjSpec: NO
ceos-agents:publisher                  | codegraph_in_prompt: NO  | ProjSpec: NO

mcp__codegraph__* tool calls in session: 0 (out of 100+ total tool calls)
```

`ProjSpec: NO` = the `## Project-Specific Instructions` marker (which the
injector inserts when an overlay is loaded) is absent from every prompt.
Conclusion: zero overlays were loaded across the entire pipeline run, despite
five `customization/*.toml` files existing on disk with the correct content.

`codegraph_in_prompt: NO` = the word "codegraph" appears nowhere in any
agent's prompt. The agents were never told codegraph was available, never
instructed to prefer it, never instructed how to fall back. Result: pure
Grep/Glob exploration in `analyst --phase impact` (24× Read + 20× Bash).

---

## Fix

Branch: `feat/codegraph-integration`
Commit: `c21953b` ("fix(overlay): wire .toml overlay loading into agent dispatch (v9 regression)")

### Part A — `core/agent-override-injector.md` rewritten

- Resolve order:
  - `.toml` exists, `.md` exists → load `.toml`, `[WARN]` about ignored `.md`
  - `.toml` exists alone → load `.toml`
  - `.md` exists alone → `[ERROR]` per migration guide, return empty
  - Both absent → return empty silently
- TOML path: parse + validate via `lib/toml-merge.sh::parse_toml_overlay` and
  `validate_overlay_keys`
- Renderer: parsed TOML structure converted to readable Markdown:
  ```
  ## Project-Specific Instructions

  <!-- Source: customization/{agent}.toml — rendered by agent-override-injector v9 -->

  ### Process additions
  1. (step: {step_1}) {instruction_1}
  …

  ### Constraints
  - {rule_1}
  …

  ### Limits
  - {key_1}: {value_1}
  …

  ### Meta
  - {meta_key_1}: {meta_value_1}
  …
  ```
  Sections render only if non-empty. `model`/`style` Tier 1 scalars don't
  render (they affect dispatch model selection, not runtime instructions).
- Provenance: every dispatch logs `agent={name} overlay_source=toml|md|none`
  to `.ceos-agents/pipeline.log` via `log_overlay_provenance`
- Failure handling: TOML parse error / validation failure / I/O error / no
  python3 → `[ERROR]` or `[WARN]` to stderr, return empty string. Pipeline
  NEVER blocks on overlay failure.

### Part B — every dispatch step has an `## Agent Override injection` section BEFORE its `Task()` call(s)

13 step files patched:

- **fix-bugs/steps/** — `01-triage.md`, `02-impact.md`, `03-reproduce.md`,
  `04-fixer-reviewer-loop.md` (refactored from `.md`-only), `05-test.md`,
  `06-acceptance-gate.md`, `07-publish.md`
- **implement-feature/steps/** — `01-spec.md`, `02-architect.md` (injection
  moved from AFTER to BEFORE dispatch), `04-fixer-reviewer-loop.md`
  (refactored), `05-test.md` (injection moved + leftover `.md` reference
  removed), `06-acceptance-gate.md`, `07-publish.md`
- **check-deploy/SKILL.md** — injection moved from AFTER to BEFORE dispatch

Each section follows the same canonical 3-step protocol:

1. Compute `override_path` from Automation Config (default `customization/`)
2. Load `{override_path}/{agent-name}.toml`, parse + validate, render to
   Markdown, append as `## Project-Specific Instructions` to Task context
3. Write provenance log line

Missing/malformed overlays are advisory; pipeline never blocks. Legacy `.md`
overlays rejected with `[ERROR]` per migration guide.

### Part C — parent SKILL.md files updated

`fix-bugs/SKILL.md`, `implement-feature/SKILL.md`, `check-deploy/SKILL.md` —
removed `.md`-only "check if `{agent-name}.md` exists" language; replaced
with TOML-aware reference pointing at `core/agent-override-injector.md`.

### Part D — test scenario added

`tests/scenarios/v9-overlay-dispatch-wiring.sh` — 9-assertion contract test:

1. injector documents `.toml` primary path
2. injector references `lib/toml-merge.sh` helpers
3. injector documents Markdown render layout
4. every fix-bugs step with `Task()` has injection section
5. every implement-feature step with `Task()` has injection section
6. all injection sections reference `{agent-name}.toml`
7. parent SKILL.md files reference TOML overlays
8. no leftover `.md`-only override resolution language
9. `lib/toml-merge.sh::resolve_overlay()` exists

PASSes. All 8 pre-existing `v8-overlay-*.sh` scenarios continue to PASS — no
regression in the parser / validator / merger.

---

## How to verify the fix in production

After merging and updating in a project:

1. Run `/ceos-agents:fix-ticket {issue-id}` (or any pipeline-driven skill).
2. Open `.ceos-agents/{ISSUE-ID}/pipeline.log`.
3. For each agent dispatch, expect a line:
   ```
   agent={name} overlay_source=toml overlay_path=customization/{name}.toml
   ```
   `overlay_source=none` is acceptable only for agents that have no
   corresponding `customization/{name}.toml` file. `overlay_source=md` should
   never appear in v9.x.
4. Cross-check by querying the topic-graph DB (or any session-replay
   tool): the agent's prompt MUST contain a `## Project-Specific Instructions`
   block when overlay was loaded. If not — overlay loading is still broken.
5. For codegraph-specific verification: in `asysta-ai/ceos-cmd` or any project
   with codegraph configured, the analyst's prompt should mention `codegraph`
   and the session's tool calls should include `mcp__codegraph__*` entries.

---

## Lessons / process notes

1. **Doc-level test scenarios are not enough for runtime contracts.** The v8
   overlay test suite verifies what the spec text says about TOML — not what
   the code path actually does. A single integration test that creates a
   project with `customization/{agent}.toml`, runs a real `/fix-ticket`, and
   asserts the prompt contains `## Project-Specific Instructions` would have
   caught both defects in v8.0.0, eight months before they were noticed.

2. **Migration announcements without enforcement code are aspirational.** The
   v9 migration guide claimed `[ERROR]` on legacy `.md`. No code emits that
   error. The claim is documentation, not behavior. Future migrations should
   pair every behavioral promise with a corresponding code path **and** an
   integration test that exercises the failure mode.

3. **Orphaned helpers are a smell.** `lib/toml-merge.sh::resolve_overlay()`
   was never called from any consumer. A simple grep for `resolve_overlay`
   across the repo at v8 release time would have shown 0 callers and revealed
   the gap.

4. **AFTER-dispatch injection is a structural anti-pattern.** Three of the
   four files that DID document overlay injection put the paragraph after
   the `Task()` call. By the time the orchestrator reads "load the overlay,"
   the agent has already been dispatched with the bare prompt. Visual review
   of step files should treat "injection paragraph below Task()" as a
   reviewable defect.

5. **Topic-graph DB is the verification ground truth.** The only reason the
   regression was caught is because session prompts and tool calls are logged
   verbatim to a local SQLite DB by `/home/vitek/CEOS/claude-asysta-graph`.
   Without that, the failure mode (overlay silently absent) is invisible —
   the pipeline succeeds, the PR gets created, the bug fix lands, and nobody
   knows codegraph was supposed to be involved.
