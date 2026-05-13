# Persona B (Innovative Architect): I/O Contracts as First-Class Foundation for v10 Runtime

**Recommendation:** YES — full formalization. Every agent gets `## Inputs` and `## Outputs` typed-table sections (per-mode-split where polymorphic, mirroring existing `## Process — Phase: X` convention), declared output section names backtick-quoted, and a sidecar registry `agents/contracts/registry.json` generated from those tables. Mandatory across all 18 agents in v9.0.0 with section-level SKIP-guard during the rollout PR sequence (not as a permanent escape hatch).

**Schema language:** Typed markdown table (primary, in-file) with the column contract `| Field | Type | Required | Mode | Description |` — Type values constrained to a fixed vocabulary (`string`, `markdown-section`, `enum:{...}`, `list<...>`, `flag`). Plus a generated **JSON Schema draft 2020-12** sidecar at `agents/contracts/{agent-name}.schema.json` derived from the table by a future `tests/harness/extract-contracts.sh`. The markdown is the source of truth; the JSON Schema is a build artifact for downstream tooling.

**Contract location:** Dedicated `## Inputs` and `## Outputs` sections in agent body, positioned between `## Expertise` and `## Process` (so they read as the API surface before behavior). Polymorphic agents use `## Inputs — Phase: triage` / `## Outputs — Phase: triage` mirroring analyst's existing process split. Sidecar JSON at `agents/contracts/` is generated, not hand-edited.

**Validation mechanism:** Three layers. (1) **Static lint** in `tests/scenarios/` — `v9-agent-contract-shape.sh` (per-agent table well-formedness), `v9-agent-contract-completeness.sh` (all 18 agents declared), `v9-xref-output-sections.sh` (every declared output section name appears in at least one dispatching skill). (2) **Dispatcher xref** — skills that dispatch each agent grep-verify they reference at least one declared output section before parsing. (3) **Generated JSON Schema** as build artifact for v10 Node.js runtime, dashboard contract-linter, and future LSP autocomplete.

**Backward-compat strategy:** Additive mandatory across plugin internals, zero-touch for consuming projects. The override injector is structure-blind (Q6, C4) so customization/ files keep working unmodified. Reserved heading `## Project-Specific Instructions` is untouched; `## Inputs`/`## Outputs` are confirmed unused by any override example. v8.0.0→v9.0.0 migration guide section on contracts is two sentences. SKIP-guard scenarios stay in the harness for one minor cycle (v9.1.0) then are deleted — they are *transition* infrastructure, not a permanent compromise.

**Versioning verdict:** **MAJOR (v9.0.0 as planned in MEMORY).** Mandatory enforcement = MAJOR per Q8 resolution + CLAUDE.md amendment. The `description` field is already parsed by Claude Code's Task tool UI and skills already grep agent output section names by exact heading — `## Outputs` becomes external-tooling-parsed the moment v10 ships, and Hyrum's Law guarantees someone will rely on it before then. Calling this MINOR is a semver lie that v10 will retroactively expose.

**Test strategy:** Five new bash scenarios:
1. `v9-agent-contract-shape.sh` — per-agent: `## Inputs` and `## Outputs` exist, table column header matches the canonical 5-column contract, every row has 5 pipes.
2. `v9-agent-contract-completeness.sh` — enumerates all 18 agents, fails if any lacks both sections (no SKIP after rollout PR closes).
3. `v9-agent-contract-output-names.sh` — extracts backtick-quoted `` `## X` `` section names from Outputs tables, verifies each declared name is referenced by at least one `skills/**/SKILL.md`.
4. `v9-agent-contract-polymorphic-split.sh` — analyst, test-engineer: asserts per-mode `## Inputs — Phase: X` / `## Outputs — Phase: X` headings exist for each declared mode in `## Phase Dispatch`.
5. `v9-agent-contract-registry-generated.sh` — runs `tests/harness/extract-contracts.sh`, asserts `agents/contracts/registry.json` matches generated output (drift detector).

Plus updates to `section-order.sh` (insert Inputs+Outputs between Expertise and Process) and retirement of three stale 21-agent scenarios (debt resolved as part of v9.0.0 anyway per C8).

**Defense (300-500 words):**

The "do nothing" baseline (Persona A) wins on yesterday's failure data and loses on tomorrow's leverage. Phase 2 explicitly notes Q1 evidence is *masked* — `read-only-agents.sh` silently skips stale v7 agents, `frontmatter-completeness.sh` and `section-order.sh` actively fail on 5 deleted v7 files. The harness has **zero coverage** for output-shape correctness across the 18 current agents. Citing zero observed failures from a system that cannot observe them is a category error. The v8.0.0 forge ran three cycles to reach FULL_PASS 0.863 — we did not measure how much of that drift was contract-shape regression because nothing was watching.

Now consider where this codebase is going. MEMORY says v9.1.0 ships F dashboard (run-list, run-detail, trends — *which need machine-readable agent output to render anything beyond raw text*), and v10.0.0 ships the Node.js Runtime with "klik=spusť pipeline" interactive F. A runtime that dispatches agents and parses their output without a contract is a runtime with implicit, undocumented, undocumented-because-undocumentable coupling. Hyrum's Law: the moment v10 ships, every output section name across 18 agents becomes a load-bearing public API. The choice is not "contracts now vs contracts later" — it is "contracts declared now vs contracts ossified by accident later, with no migration plan because nobody wrote them down."

Phase 2 C5+C6 establish that optional = MINOR is the *industry default* (MCP, CrewAI, smolagents). I reject this as the correct answer for ceos-agents specifically. MCP's `outputSchema` is optional because MCP is a wire protocol with thousands of independent server implementations — they had no choice. We have 18 agents in one repo with one maintainer. The "optional default" framing imports a constraint we do not have and surrenders the leverage we do have: we can land all 18 simultaneously in a single PR sequence under one MAJOR bump.

The strongest counter-argument is Persona C's "every abstraction is a new failure mode" — and it is correct that contracts can drift from agent behavior. My answer is that the xref scenario (declared output section name → grep in dispatching skill) catches drift in the direction that matters: when an agent's declared contract no longer matches what skills consume. Drift in the reverse direction (agent emits something undeclared) is a real failure mode I accept; it is bounded because skills only parse what they grep for.

The "we can add this later" objection ignores that v10 is 1-2 minors away. Adding contracts after v10 ships means breaking v10 consumers. Adding them now means v10 ships against a stable spec.

**Failure modes I accept:**
1. **Contract-vs-runtime drift in the unmeasured direction** — an agent emits an undeclared output section, no scenario catches it (xref only validates declared→skill reference, not actual-emission→declaration). Bounded by skill-side grep coverage; v10 runtime will close this loop with strict parsing.
2. **Override file collision under future v9.x.y user edits** — a user override file containing `## Inputs` would inject below the wrapper and create heading duplication. Q6 confirms no current example uses these headings; v9.0.0 hard-removes `.md` overlays anyway, so the window closes within the same major.
3. **JSON Schema sidecar staleness if extract-contracts.sh is not run pre-commit** — mitigated by `v9-agent-contract-registry-generated.sh` as a hard CI gate, but a developer working locally without pre-commit hooks will see drift surface only on push.

## Summary

Formalize fully in v9.0.0 MAJOR: typed-table `## Inputs`/`## Outputs` per agent, per-mode split for polymorphic agents, generated JSON Schema sidecar for v10 runtime and dashboard tooling. Five new bash scenarios + section-order update. Override injector backward-compat is preserved by mechanism (append-only, structure-blind). Industry "optional" default does not bind a single-repo plugin one major before its Node.js runtime ships — Hyrum's Law forces the question now.
