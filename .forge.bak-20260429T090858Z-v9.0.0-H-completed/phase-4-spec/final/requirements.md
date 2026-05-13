# Phase 4 — Requirements (EARS format)
# v9.0.0 sub-projekt H — Agent I/O Contracts

**Status:** SPEC AUTHORITATIVE — locks Gate 1 final decision (PARTIAL_CONVENTION, ALL 18 agents, mandatory, MAJOR/v9.0.0)
**Source authority:** `.forge/phase-3-brainstorm/gate-decision.json` `phase_4_spec_mandate` array (binding)
**Evidence basis:** `.forge/phase-2-research-answers/peer-deep-dive.md` (22 frameworks); `.forge/phase-2-research-answers/final.md` (Q1–Q11 cross-lens)

---

## 1. Scope and Goals

Sub-projekt H formalizes the de-facto agent I/O contracts — the exact section headings, signal sentinels, and structured templates each agent emits — that skills already grep against today (e.g., `## Fix Report`, `## NEEDS_DECOMPOSITION`, `## Triage Analysis`). Every one of the 18 v8.0.0 agent definition files under `agents/*.md` SHALL gain a mandatory `## Output Contract` markdown section between `## Process` and `## Constraints`, declaring its inputs (skill-passed prompt fields) and outputs (markdown sections + signals). The contract is enforced exclusively at author-time by the bash test harness — no runtime schema validation, no JSON Schema sidecar, no LLM self-validation. Polymorphic agents (analyst, test-engineer, browser-agent, spec-reviewer) declare per-phase output blocks. The change ships as v9.0.0 MAJOR alongside two pre-existing pre-announced breaking changes (`.md` overlay hard removal, deprecated agent name hard errors).

**Non-goals (explicit):**
- Runtime dispatcher validation of agent output (deferred — Task tool returns raw LLM output verbatim per Q2)
- JSON Schema sidecar generation under `agents/contracts/*.schema.json` (deferred to v10 Node.js Runtime per peer-deep-dive §5 Hyrum's-Law-later)
- Migrating overrides to a new format — `customization/{agent}.md` files keep working byte-for-byte (binding C4/Q6)
- Changes to ceos-agents-web, scaffold-add behavior, MCP server integrations, hook contracts
- Frontmatter changes — `name`, `description`, `model`, `style` shape stays identical
- Renaming any existing agent or moving any file under `agents/`

**Bound — the 18 agent files:**
`acceptance-gate.md`, `analyst.md`, `architect.md`, `backlog-creator.md`, `browser-agent.md`, `deployment-verifier.md`, `fixer.md`, `priority-engine.md`, `publisher.md`, `reviewer.md`, `rollback-agent.md`, `scaffolder.md`, `spec-analyst.md`, `spec-reviewer.md`, `spec-writer.md`, `sprint-planner.md`, `stack-selector.md`, `test-engineer.md` — but `stack-selector.md` is DELETED in this release per REQ-H-080. The post-v9.0.0 set is **17 agents**.

---

## 2. Glossary

- **Output Contract** — a mandatory `## Output Contract` markdown section in an agent definition file declaring (a) the inputs the agent reads and (b) the outputs the agent emits. Located between `## Process` and `## Constraints`.
- **Inputs table** — markdown table inside `## Output Contract` with three columns: `Section` | `Source` | `Required`. Each row describes one input the agent expects from upstream (skill prompt fields, frontmatter values, working-directory file conventions).
- **Outputs table** — markdown table inside `## Output Contract` with three columns: `Section produced` | `When` | `Required fields`. Each row's first cell backtick-quotes a markdown heading (e.g., `` `## Fix Report` ``) so it is grep-extractable via `grep -oE '\`## [A-Za-z][A-Za-z _-]*\`'`.
- **Polymorphic agent** — an agent whose output shape varies by `--phase` flag (analyst, test-engineer, browser-agent, spec-reviewer). Declares one `## Output Contract — Phase: {name}` sub-block per phase, mirroring the existing `## Process — Phase: X` convention in analyst.md.
- **Signal sentinel** — a fixed-string token (e.g., `NEEDS_CLARIFICATION`, `NEEDS_DECOMPOSITION`, `UNCLEAR`, `BLOCK`) that downstream skills detect via exact-string grep. Each sentinel an agent may emit is enumerated in the agent's Outputs table.
- **De-facto contract** — the section heading or sentinel a skill currently grep's for in v8.0.0 (e.g., `skills/fix-ticket/SKILL.md:208` greps `` `## NEEDS_CLARIFICATION` ``). The Output Contract DOCUMENTS these — it does not invent new ones.
- **Override injector** — the structure-blind appender at `core/agent-override-injector.md` that wraps `customization/{agent}.md` content as `## Project-Specific Instructions`. Untouched by this work (binding C4/Q6).
- **SKIP-guard** — `exit 77` early-return when a precondition is absent. Used by lint scenarios during the transition window for forward-compat with v8.0.0 agents that lack `## Output Contract`. After v9.0.0 ships, the SKIP-guard is the LAST defense, not the primary path — every v9.0.0 agent MUST have the section.
- **Author-time lint** — bash scenario under `tests/scenarios/*.sh` invoked by `tests/harness/run-tests.sh`. Exit 0 = PASS, 77 = SKIP, anything else = FAIL.
- **Strict dispatch idiom** — `Task(subagent_type='ceos-agents:X', model='Y')` form, validated by the PostToolUse hook. Used by 14 of 18 dispatching skills today; harmonized to all in v9.0.0 (REQ-H-090).

---

## 3. Functional Requirements

### REQ-H-001..009 — Output Contract section format

**REQ-H-001 (Ubiquitous):** The system SHALL define a mandatory markdown section titled exactly `## Output Contract` in every agent definition file under `agents/*.md`. Trace: gate-decision `phase_4_spec_mandate[0]`; peer-deep-dive.md:194 ("CrewAI made `expected_output` REQUIRED on Task — same logic applies here").

**REQ-H-002 (Ubiquitous):** The `## Output Contract` section SHALL be positioned between `## Process` and `## Constraints` in every agent file. Trace: gate-decision `phase_4_spec_mandate[0]` ("positioned between `## Process` and `## Constraints`").

**REQ-H-003 (Ubiquitous):** The `## Output Contract` section SHALL contain exactly two markdown tables in this order: an **Inputs** table immediately followed by an **Outputs** table. Trace: gate-decision `phase_4_spec_mandate[1]`.

**REQ-H-004 (Ubiquitous):** The Inputs table SHALL have header row `| Section | Source | Required |` (exact column names, case-sensitive). Trace: gate-decision `phase_4_spec_mandate[1]` ("Inputs (Section | Source | Required)").

**REQ-H-005 (Ubiquitous):** The Outputs table SHALL have header row `| Section produced | When | Required fields |` (exact column names, case-sensitive). Trace: gate-decision `phase_4_spec_mandate[1]` ("Outputs (Section produced | When | Required fields)").

**REQ-H-006 (Ubiquitous):** Every Outputs-table row SHALL backtick-quote its `Section produced` cell value when it names a markdown heading (e.g., `` `## Fix Report` ``). Trace: research final.md C2/Q10 ("backtick-quoted section names is the only grep-friendly contract format").

**REQ-H-007 (Ubiquitous):** Every Outputs-table row SHALL specify in its `When` cell one of: `always`, a `--phase X` token, a conditional (e.g., `on UNCLEAR`, `on NEEDS_DECOMPOSITION`, `mode=feature`), or `on Block` — phrasing readable to both LLM and grep. Trace: research final.md Q4 (per-mode separate sections).

**REQ-H-008 (Ubiquitous):** Every Outputs-table row's `Required fields` cell SHALL list the bullet-form sub-fields the agent must populate inside that section (e.g., for `## Fix Report`: `Objective; Approach; Files changed; Build; Tests`). Trace: synthesis of agents/fixer.md:73-82, agents/reviewer.md:77-88, agents/analyst.md:97-108 templates.

**REQ-H-009 (Optional feature):** IF an agent's Outputs table declares a row whose `Section produced` cell does not begin with `## ` (i.e., is not a markdown heading — e.g., a fenced JSON file artifact such as `.ceos-agents/{ISSUE-ID}/reproduction-result.json` for browser-agent), THEN the row SHALL still appear in the Outputs table but the `Section produced` cell SHALL backtick-quote the literal artifact path or signal token. Trace: agents/browser-agent.md:73-92 (JSON file artifact); agents/analyst.md:60-69 (NEEDS_CLARIFICATION sentinel).

### REQ-H-010..019 — Polymorphism for phase-aware agents

**REQ-H-010 (State-driven):** WHILE an agent file declares phase polymorphism via `## Phase Dispatch`, the agent's `## Output Contract` SHALL contain one sub-block per declared phase, titled exactly `## Output Contract — Phase: {phase-name}` (replacing the single Inputs/Outputs table pair). Trace: gate-decision `phase_4_spec_mandate[3]`; peer-deep-dive.md:174 (per-mode split rule).

**REQ-H-011 (Ubiquitous):** The `analyst` agent SHALL declare two phase sub-blocks: `## Output Contract — Phase: triage` and `## Output Contract — Phase: impact`. Trace: agents/analyst.md:32, :130 (existing Process — Phase: split).

**REQ-H-012 (Ubiquitous):** The `test-engineer` agent SHALL declare two phase sub-blocks: `## Output Contract — Default (no flag)` and `## Output Contract — Phase: --e2e`. Trace: agents/test-engineer.md:18-26 ("Mode Flag" section).

**REQ-H-013 (Ubiquitous):** The `browser-agent` agent SHALL declare two phase sub-blocks: `## Output Contract — Phase: reproduce` and `## Output Contract — Phase: verify`. Trace: agents/browser-agent.md:19-25 ("Phase Dispatch" section).

**REQ-H-014 (Ubiquitous):** The `spec-reviewer` agent SHALL declare two phase sub-blocks: `## Output Contract — Default (review mode)` and `## Output Contract — Phase: --verify`. Trace: agents/spec-reviewer.md:75-79 ("Verify Mode (--verify)" section).

**REQ-H-015 (Ubiquitous):** Each phase sub-block SHALL contain its own Inputs table and Outputs table satisfying REQ-H-003 through REQ-H-009. Trace: gate-decision `phase_4_spec_mandate[3]`.

### REQ-H-020..029 — Backward compatibility

**REQ-H-020 (Ubiquitous):** The system SHALL NOT modify `core/agent-override-injector.md`. The override injector remains append-only and structure-blind. Trace: research final.md C4/Q6; gate-decision `preserved_from_synthesis[0]`.

**REQ-H-021 (Ubiquitous):** Existing project-side `customization/{agent}.md` files SHALL continue to be appended verbatim as `## Project-Specific Instructions` to the agent context, after `## Output Contract` and `## Constraints`. Trace: peer-deep-dive.md:175 ("v8.0.0 customization/{agent}.md overrides keep working unmodified"); core/agent-override-injector.md:18-22.

**REQ-H-022 (Ubiquitous):** No new agent file SHALL contain a section titled `## Project-Specific Instructions` — that heading is reserved by the override injector. Trace: research final.md C4/Q6 ("Heading `## Project-Specific Instructions` is reserved and must not be reused").

**REQ-H-023 (Optional feature):** IF a `customization/{agent}.md` override file contains a heading matching `## Output Contract`, THEN the override injector SHALL still append the file content verbatim (no parsing, no rejection). Trace: research final.md Q6 ("injector does not parse or detect heading collisions"). Note: heading collision is a soft semantic concern documented in the migration guide (REQ-H-070) but does not block injection.

### REQ-H-030..039 — Test scenarios

**REQ-H-030 (Ubiquitous):** The system SHALL ship with at least 6 new lint scenarios under `tests/scenarios/` named: `v9-output-contract-shape.sh`, `v9-output-contract-completeness.sh`, `v9-output-contract-position.sh`, `v9-output-contract-polymorphic-split.sh`, `v9-xref-outputs-skill-references.sh`, `v9-agents-must-be-dispatched.sh`. Trace: gate-decision `phase_4_spec_mandate[4]`; design.md Section 3.

**REQ-H-031 (Event-driven):** WHEN the harness invokes `tests/harness/run-tests.sh`, each `v9-output-contract-*.sh` scenario SHALL set `REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"` and SHALL guard against execution from a `.forge/` staging directory by exiting non-zero if `REPO_ROOT` matches `*\.forge*`. Trace: tests/scenarios/v8-agents-analyst-shape.sh:8-13 (canonical REPO_ROOT pattern).

**REQ-H-032 (Optional feature):** IF an agent file under `agents/*.md` lacks a `## Output Contract` heading (transition window only), THEN `v9-output-contract-shape.sh` SHALL exit 77 (SKIP) for that agent rather than fail. Trace: research final.md C9/Q10 (SKIP-guard pattern).

**REQ-H-033 (Ubiquitous):** `v9-output-contract-completeness.sh` SHALL fail if any agent file under `agents/*.md` lacks a `## Output Contract` section. This scenario does NOT use a SKIP-guard — it is the enforcement gate for the mandatory contract. Trace: gate-decision `final_decision.enforcement` ("mandatory documentation, author-time lint only"); peer-deep-dive.md:170-173 (mandatory rationale).

**REQ-H-034 (Ubiquitous):** `v9-xref-outputs-skill-references.sh` SHALL extract every backtick-quoted `## Heading` from every agent's Outputs table and assert each appears literally (modulo backticks) in at least one file under `skills/**/SKILL.md` or `skills/**/steps/*.md`. Trace: gate-decision `phase_4_spec_mandate[5]` ("every backtick-quoted `## Heading` declared in any agent's Output Contract MUST be referenced by at least one skills/**/SKILL.md").

**REQ-H-035 (Ubiquitous):** `v9-agents-must-be-dispatched.sh` SHALL enumerate every agent file under `agents/*.md` and assert each agent's `name:` frontmatter value appears as a `subagent_type='ceos-agents:{name}'` literal in at least one file under `skills/**/*.md`. Agents without any dispatch reference SHALL fail this scenario. Trace: gate-decision `phase_4_spec_mandate[8]` (stack-selector orphan defect prevention).

**REQ-H-036 (Ubiquitous):** The system SHALL update `tests/scenarios/section-order.sh` to (a) replace the v7 21-name `AGENTS=(...)` array with the post-v9 17-name array (after stack-selector deletion per REQ-H-080) and (b) add a position assertion that the optional `## Output Contract` line, when present, sits between `## Process` and `## Constraints`. Trace: research final.md C8/Q9 ("Only `section-order.sh` requires modification for new mandatory body sections"); gate-decision `phase_4_spec_mandate[8]`.

**REQ-H-037 (Ubiquitous):** The system SHALL update `tests/scenarios/frontmatter-completeness.sh` to use the post-v9 17-name agent array (deletes 5 stale v7 names: triage-analyst, code-analyst, e2e-test-engineer, reproducer, browser-verifier; adds the 4 v8 consolidated names: analyst, test-engineer, browser-agent; deletes stack-selector). Trace: research final.md Q1 (stale 21-agent enumeration causing 5 FAILs).

**REQ-H-038 (Ubiquitous):** The system SHALL update `tests/scenarios/read-only-agents.sh` to use the post-v9 read-only agent array (replaces stale v7 names triage-analyst, code-analyst with v8 analyst; deletes stack-selector). Final list: `analyst reviewer spec-analyst architect priority-engine spec-reviewer acceptance-gate backlog-creator sprint-planner`. Trace: research final.md Q1 (stale list silently skipping); gate-decision `phase_4_spec_mandate[8]`.

**REQ-H-039 (Ubiquitous):** Every new v9 scenario SHALL exit 0 (PASS) on the v9.0.0 codebase after Phase 7 implementation completes. SKIP exits during transition are acceptable only for `v9-output-contract-shape.sh` per REQ-H-032; the other 5 scenarios SHALL be hard PASS. Trace: gate-decision `final_decision.enforcement` ("author-time lint only").

### REQ-H-040..049 — Versioning

**REQ-H-040 (Ubiquitous):** The system SHALL ship sub-projekt H as version 9.0.0 (MAJOR). The `version` field in `.claude-plugin/plugin.json` AND `.claude-plugin/marketplace.json` SHALL read `9.0.0`. Trace: gate-decision `final_decision.versioning`; peer-deep-dive.md:194 ("breaking change in agent output format contract = MAJOR").

**REQ-H-041 (Ubiquitous):** A v9.0.0 entry SHALL exist in `CHANGELOG.md` with section `## [9.0.0] — 2026-MM-DD` and at minimum one sub-section heading `### Sub-projekt H: Agent I/O Contracts` enumerating: `## Output Contract` mandatory across 18 agents (deletes to 17 after stack-selector removal); 6 new lint scenarios; CLAUDE.md Versioning Policy + Cross-File Invariants amendments; migration-v8-to-v9.md added. Trace: project Version Release Process MEMORY ("ALWAYS create changelog entry without being asked").

**REQ-H-042 (Ubiquitous):** The v9.0.0 release SHALL bundle the two pre-existing pre-announced breaking changes (`.md` overlay hard removal and deprecated agent name hard errors) per gate-decision `final_decision.v9_pre_announced_changes`. The CHANGELOG entry SHALL list both as separate `### ` sub-sections under v9.0.0. Trace: gate-decision; docs/guides/migration-v7-to-v8.md:445-454.

### REQ-H-050..059 — CLAUDE.md Versioning Policy amendment

**REQ-H-050 (Ubiquitous):** The system SHALL amend the Versioning Policy table in `CLAUDE.md` to add a row classifying static agent body declaration sections (Q8 documented gap). The amended MAJOR row SHALL read verbatim:

> Breaking change in Automation Config contract — new required key, renamed section — OR breaking change in agent output format contract (new/modified structured output sections that Agent Overrides or external tooling may parse) — OR introduction of a mandatory new structured contract section in agent definition files that v8.0.0 agents would fail validation against.

Trace: research final.md Q8 (documented gap); gate-decision `phase_4_spec_mandate[5]`.

**REQ-H-051 (Ubiquitous):** The system SHALL append after the Versioning Policy table in `CLAUDE.md` the following clarification paragraph verbatim:

> Adding new static declaration sections to agent definition files (`## Output Contract`, `## Inputs`, `## Outputs`, or similar metadata blocks) that are not enforced at runtime classifies as MINOR when the section is OPTIONAL (consuming-project agent files without it remain valid against the harness) and MAJOR when the section is MANDATORY (agent files without it fail at least one harness scenario). The override injector at `core/agent-override-injector.md` is structure-blind and is not "external tooling that parses" agent body sections — its append-only behavior does not fire the MAJOR clause on its own.

Trace: research final.md Q8 resolution recommendation (verbatim adoption).

### REQ-H-060..069 — CLAUDE.md Cross-File Invariants amendment

**REQ-H-060 (Ubiquitous):** The system SHALL add a 4th invariant to the `## Cross-File Invariants` subsection in `CLAUDE.md`. The new invariant SHALL read verbatim:

> 4. **Agent Output Contract ↔ skill xref consistency** — every backtick-quoted `## Heading` declared in any agent's `## Output Contract` Outputs table (e.g., `` `## Fix Report` ``, `` `## Code Review` ``, `` `## Triage Analysis` ``) MUST be referenced literally (modulo backticks) in at least one file under `skills/**/SKILL.md` or `skills/**/steps/*.md`. Verify via `tests/scenarios/v9-xref-outputs-skill-references.sh`.

Trace: gate-decision `phase_4_spec_mandate[5]` (new invariant text); research final.md Q11 (xref scenario template).

**REQ-H-061 (Ubiquitous):** The amended Cross-File Invariants subsection SHALL list 4 invariants (was 3). The intro line `Phase 8 verification scenarios assert each:` is preserved unchanged. Trace: spec-prompt §2 Codebase Context ("Cross-File Invariants section in CLAUDE.md currently has 3 invariants").

### REQ-H-070..079 — Migration guide

**REQ-H-070 (Ubiquitous):** The system SHALL create `docs/guides/migration-v8-to-v9.md` with the following 4 required H2 section headings, in this order: `## Overview`, `## Breaking Changes`, `## Migration Steps`, `## Compatibility Check`. Trace: gate-decision `phase_4_spec_mandate[6]`; project MEMORY `feedback_docs_coverage`.

**REQ-H-071 (Ubiquitous):** The `## Overview` section SHALL state the v9.0.0 release scope (sub-projekt H + pre-announced `.md` overlay removal + deprecated agent name hard errors). Trace: REQ-H-042.

**REQ-H-072 (Ubiquitous):** The `## Breaking Changes` section SHALL enumerate at minimum: (a) `## Output Contract` is now mandatory in every agent file (does not affect consuming projects); (b) `.md` agent overlays removed (TOML-only — affects consuming projects with `.md` overlays); (c) deprecated agent names (`triage-analyst`, `code-analyst`, `e2e-test-engineer`, `reproducer`, `browser-verifier`) emit hard errors instead of `[WARN]`; (d) `agents/stack-selector.md` deleted — scaffolder agent now subsumes stack selection per existing scaffold v2 behavior. Trace: gate-decision `final_decision.v9_pre_announced_changes`; REQ-H-080.

**REQ-H-073 (Ubiquitous):** The `## Migration Steps` section SHALL describe: (a) zero-touch action for `customization/{agent}.md` override files — no rename, no move, no edit (per Q7); (b) remove any pinned dispatch of `ceos-agents:stack-selector` from skill-side hooks if a consuming project has one (per REQ-H-080); (c) rename any custom skill that dispatches `triage-analyst|code-analyst|e2e-test-engineer|reproducer|browser-verifier` to the v8 names; (d) optional inspection note for consuming projects that parse agent body content externally — they may now expect a `## Output Contract` section between Process and Constraints. Trace: research final.md Q7 (zero-touch conclusion); gate-decision `final_decision.v9_pre_announced_changes`.

**REQ-H-074 (Ubiquitous):** The `## Compatibility Check` section SHALL provide a copy-pasteable bash command that exits 0 if the consuming project's `customization/` overrides do not collide with reserved headings:
```bash
grep -lE '^## (Output Contract|Project-Specific Instructions)' customization/*.md 2>/dev/null && echo "WARN: heading collision risk" || echo "OK: no collision"
```
Trace: research final.md Q6 ("Avoid naming new sections `## Project-Specific Instructions`"); REQ-H-022.

### REQ-H-080..089 — stack-selector orphan resolution

**REQ-H-080 (Ubiquitous):** The system SHALL delete `agents/stack-selector.md`. The scaffolder agent (`agents/scaffolder.md:22-24`) already subsumes stack selection in scaffold v2 mode (reads `spec/README.md` Tech Stack section); the `--no-implement` legacy flow note in `skills/scaffold/SKILL.md:91` SHALL be edited to remove the stack-selector dispatch reference and describe scaffolder-direct invocation. Trace: gate-decision `phase_4_spec_mandate[8]` default option; research finding (0 actual dispatches across `skills/**/*.md`).

**REQ-H-081 (Ubiquitous):** The new `tests/scenarios/v9-agents-must-be-dispatched.sh` lint scenario (REQ-H-035) SHALL prevent recurrence of orphan agents — every agent file under `agents/*.md` MUST appear as a `subagent_type='ceos-agents:{name}'` literal in at least one skill file. Trace: gate-decision `phase_4_spec_mandate[8]` ("add a 6th lint scenario `v9-agents-must-be-dispatched.sh` to prevent future orphans").

**REQ-H-082 (Ubiquitous):** The CLAUDE.md "Agents (specialists — HOW to do it):" enumeration SHALL be updated to list 17 agents (deletes stack-selector). Trace: REQ-H-080; CLAUDE.md:35.

**REQ-H-083 (Ubiquitous):** The `agents/rollback-agent.md:25` skip list SHALL be updated to remove `stack-selector` from the read-only blocking-agent list (since the file no longer exists). The list still skips read-only agents (`analyst`, `spec-analyst`, `architect`). Trace: agents/rollback-agent.md:25; REQ-H-080.

### REQ-H-090..099 — Dual dispatch idiom harmonization

**REQ-H-090 (Ubiquitous):** The system SHALL harmonize all skill-side agent dispatches to the strict idiom `Task(subagent_type='ceos-agents:{name}', model='{tier}')`. The 4 prose-idiom dispatches identified during Phase 3 (in `skills/check-deploy/SKILL.md`, `skills/create-backlog/SKILL.md`, `skills/prioritize/SKILL.md`, `skills/sprint-plan/SKILL.md`, `skills/scaffold-add/SKILL.md`, `skills/publish/SKILL.md` — wherever the `Run ceos-agents:X (Task tool, model: Y)` form appears) SHALL be rewritten to the strict form. After v9.0.0, zero files under `skills/**/*.md` SHALL contain the legacy prose form. Trace: gate-decision `phase_4_spec_mandate[9]`; PostToolUse hook validation surface.

**REQ-H-091 (Ubiquitous):** Each rewritten dispatch line SHALL include the `model='{tier}'` argument matching the agent's frontmatter `model:` field (e.g., `Task(subagent_type='ceos-agents:priority-engine', model='opus')`). Trace: existing pattern in skills/fix-ticket/SKILL.md.

**REQ-H-092 (Ubiquitous):** Skill-side dispatch harmonization SHALL NOT alter the agents themselves — frontmatter, body, and contract are untouched by REQ-H-090. Trace: peer-deep-dive.md:175 (zero impact on consuming-project overrides).

### REQ-H-100..109 — Bundling with v9.0.0 pre-announced breaking changes

**REQ-H-100 (Ubiquitous):** The v9.0.0 release SHALL include the pre-existing pre-announced `.md` overlay hard removal — the override injector and dispatching skills SHALL emit `[ERROR]` (not `[WARN]`) when a `customization/{agent}.md` file is detected and the configured override format is TOML, then refuse the dispatch path as documented in `docs/guides/migration-v7-to-v8.md:445-454`. This requirement is PRE-EXISTING SCOPE — not introduced by sub-projekt H — but ships in the same v9.0.0 commit per gate-decision `final_decision.v9_pre_announced_changes`.

**REQ-H-101 (Ubiquitous):** The v9.0.0 release SHALL include the pre-existing pre-announced deprecated agent name hard errors — any dispatch invoking `ceos-agents:triage-analyst|code-analyst|e2e-test-engineer|reproducer|browser-verifier` SHALL produce a `[ERROR]` and refuse to proceed (was `[WARN]` in v8). PRE-EXISTING SCOPE per gate-decision `final_decision.v9_pre_announced_changes`.

**REQ-H-102 (Ubiquitous):** The detail of REQ-H-100 and REQ-H-101 implementation behavior is OUT OF SCOPE for sub-projekt H's spec — those are governed by their own pre-existing requirements documents. Sub-projekt H takes no position on whether they ship in this run; it merely acknowledges that the v9.0.0 release vehicle is shared. Trace: gate-decision `final_decision.v9_pre_announced_changes`.

---

## 4. Non-Functional Requirements

- **NFR-COMPAT-001 (Ubiquitous):** All v8.0.0 test scenarios under `tests/scenarios/v8-*.sh` SHALL continue to pass unchanged (excepting the 3 stale-list updates handled by REQ-H-036, -H-037, -H-038 — those are the SAME scenarios, just with v8/v9-corrected agent arrays).
- **NFR-COMPAT-002 (Ubiquitous):** Every `examples/customization/{agent}.md` and `examples/agent-overrides/**/*.md` example file SHALL inject correctly against a v9.0.0 agent file via `core/agent-override-injector.md` without modification. Verify via the injection-flow protocol in design.md Section 8.
- **NFR-DOC-001 (Ubiquitous):** Doc-count drift discipline (CLAUDE.md, README.md, docs/reference/automation-config.md, docs/reference/skills.md, docs/architecture.md count fields) SHALL be preserved. Specifically: agent count moves 18 → 17 in all 5 reference points after stack-selector deletion; skill count remains 29 unchanged. Trace: project MEMORY `feedback_doc_completeness`.
- **NFR-PERF-001 (Ubiquitous):** Total bash harness runtime increase SHALL stay under 10% relative to v8.0.0 baseline. The 6 new scenarios are O(agents × skill files) grep loops on a markdown plugin — empirically <2 seconds combined. Trace: spec-prompt §4 NFR-PERF-001.

---

## 5. Traceability Map (REQ → evidence)

| REQ | Source authority |
|-----|------------------|
| REQ-H-001..H-009 | gate-decision.json `phase_4_spec_mandate[0-1]`; peer-deep-dive.md:170-174 |
| REQ-H-010..H-015 | gate-decision.json `phase_4_spec_mandate[3]`; agents/analyst.md:32,130; agents/test-engineer.md:18-26; agents/browser-agent.md:19-25; agents/spec-reviewer.md:75-79 |
| REQ-H-020..H-023 | gate-decision.json `preserved_from_synthesis[0]`; research final.md C4/Q6; core/agent-override-injector.md:18-22 |
| REQ-H-030..H-039 | gate-decision.json `phase_4_spec_mandate[4,8]`; research final.md C8/C9/Q1/Q9/Q10/Q11 |
| REQ-H-040..H-042 | gate-decision.json `final_decision.versioning`; peer-deep-dive.md:194 |
| REQ-H-050..H-051 | gate-decision.json `phase_4_spec_mandate[5]`; research final.md Q8 (verbatim resolution recommendation) |
| REQ-H-060..H-061 | gate-decision.json `phase_4_spec_mandate[5]`; research final.md Q11 |
| REQ-H-070..H-074 | gate-decision.json `phase_4_spec_mandate[6]`; project MEMORY `feedback_docs_coverage` |
| REQ-H-080..H-083 | gate-decision.json `phase_4_spec_mandate[8]` (default option a+c) |
| REQ-H-090..H-092 | gate-decision.json `phase_4_spec_mandate[9]`; PostToolUse hook surface |
| REQ-H-100..H-102 | gate-decision.json `final_decision.v9_pre_announced_changes` |
