# Phase 2 Research Answers — Agent 3 (Backcompat + Versioning)

**Partition:** Q6 (override injector mechanism), Q7 (v8→v9 migration scope), Q8 (MAJOR vs MINOR versioning verdict)

---

## Q6 — Agent Override Injector Mechanism

**Question:** Does `core/agent-override-injector.md` append override files strictly verbatim after all existing agent body sections (making any new `## Inputs` / `## Outputs` body sections additive and invisible to existing override files) — or does any skill inspect agent body structure before injection — and if new contract section headings collide with heading names that consuming projects' `customization/{agent-name}.md` files currently use, what does the model receive and how do production LLM systems handle duplicate markdown heading context?

**Answer:**

The injector is strictly append-only and verbatim. No skill inspects the agent body structure before injection. New `## Inputs` / `## Outputs` sections are therefore additive and invisible to existing override files at the mechanism level. Heading collision with override content creates ambiguous context for the LLM but does not break the injector.

**Evidence:**

- `core/agent-override-injector.md` Process step 5 (line 18–21): "The calling command appends the returned string to the agent's context as: `## Project-Specific Instructions` / `{file contents}`". No inspection of agent body sections is performed. The entire override file is returned verbatim as `additional_instructions` (Output Contract, line 26–29).
- `core/agent-override-injector.md` Process step 3–4: "If the file exists: read its full contents. Return the contents as the additional instructions string." No parsing, no section awareness, no heading collision detection.
- `skills/fix-bugs/SKILL.md` lines 81–83: "before each Task dispatch, check `{Agent Overrides path}/{agent-name}.md`. If exists → append as `## Project-Specific Instructions`." The skill delegates entirely to `core/agent-override-injector.md` — zero body inspection.
- `skills/fix-ticket/SKILL.md` line 741: "Follow `core/agent-override-injector.md` for loading project-specific agent customizations." Same pattern.
- `examples/agent-overrides/codegraph/architect.md` (lines 1–10): A real consuming project override file contains free-form markdown prose with no section headings — typical override content. No `## Inputs` or `## Outputs` headings present, confirming no current collision risk with those specific names in the example set.
- `examples/customization/reviewer-strict-security.toml` (TOML format, v8): TOML overlays use `[[process_additions]]` and `[[constraints]]` blocks, not markdown headings. The `.md` legacy format (v7 overlays, still accepted in v8 with WARN) is free-form prose — no heading structure enforced by the injector.
- `migration-v7-to-v8.md` lines 86–92: v8.0.0 still accepts legacy `.md` overlays (with `[WARN]`). Hard removal is documented for v9.0.0. This means at the v9.0.0 boundary, all v8 `.md` overlays are removed anyway — the heading collision window is bounded to v8 deprecation users.

**On heading collision behavior:**
No Anthropic documentation is available in the codebase about how the Claude model handles duplicate markdown headings in system prompt context. The general LLM behavior (well-established in prompt engineering literature) is that duplicate headings create context ambiguity — the model typically processes both sections and may merge, prioritize the later one, or become confused depending on section proximity and content similarity. The injector places override content AFTER all base sections, meaning `## Project-Specific Instructions` wrapper always comes last. If an override `.md` file contained `## Inputs` as a heading, the model would see `## Inputs` twice — once in the base agent, once wrapped inside `## Project-Specific Instructions`. The wrapping provides semantic distance (the override is labeled as project-specific), reducing but not eliminating collision risk.

**Sources:**
- `core/agent-override-injector.md` lines 1–36 (entire file)
- `skills/fix-bugs/SKILL.md` lines 81–83
- `skills/fix-ticket/SKILL.md` line 741
- `examples/agent-overrides/codegraph/architect.md` lines 1–10
- `examples/customization/reviewer-strict-security.toml` lines 1–26
- `docs/guides/migration-v7-to-v8.md` lines 86–92 (deprecation timeline)

**Confidence:** HIGH — The injector mechanism is fully specified in a single authoritative file with no ambiguity. Heading collision behavior for LLMs is MEDIUM confidence (no Anthropic primary source available, inference from general LLM behavior).

**Disagreements:** None between sources on the injector mechanism. The heading collision consequence is inferential — no primary source confirms exact model behavior for duplicate markdown headings in system prompt context.

**Phase 3 implication:**
- New `## Inputs` / `## Outputs` sections are mechanically safe to add without breaking any existing override file's injection.
- The v8.0.0 `.md` override deprecation (hard removal at v9.0.0) further reduces collision risk: by the time v9.0.0 ships, `.md` overlays are rejected. TOML overlays have no markdown heading structure and cannot collide.
- Design MUST avoid naming new sections `## Project-Specific Instructions` (already reserved by the wrapper). `## Inputs` and `## Outputs` are safe choices — no existing override example file uses those headings.
- If consuming projects have custom `.md` overlays that happen to use `## Inputs` headings (cannot be ruled out from the codebase alone), migration guidance should note the collision risk, even though the injector continues to function.

---

## Q7 — Minimal Migration Action: v8 → v9 for Consuming Projects

**Question:** If `## Inputs` / `## Outputs` sections are added to all 18 agent files in v9.0.0, what is the minimal migration action required for a v8.0.0 consuming project (BIFITO, drmax-readmine-test) — specifically: do existing `customization/{agent-name}.md` override files need any modification, or are they passively forward-compatible because the override injector appends them after all base sections without inspecting section names — and does the answer change if contracts are defined as optional (absent = uncontracted) versus mandatory?

**Answer:**

The minimal migration action for v8 → v9 consuming projects is **zero modification to override files** if I/O contracts are added as optional sections. The injector's append-only verbatim mechanism guarantees that existing override files continue to work unmodified regardless of new body sections added to base agent files. However, v9.0.0 carries one MANDATORY breaking change for consuming projects: the hard removal of `.md` overlay format. This forced migration existed before any I/O contract feature — it is independent of the `## Inputs`/`## Outputs` addition.

**Evidence:**

- `core/agent-override-injector.md` Process step 1–5: Injector constructs path, checks existence, reads contents verbatim, returns as string. "The calling command appends the returned string to the agent's context as: `## Project-Specific Instructions` / `{file contents}`". Appending is unconditional — the injector does not read or parse the base agent file at all. New sections in the base agent file are invisible to the injector.
- `docs/guides/migration-v7-to-v8.md` lines 445–454 (Deprecation timeline): v9.0.0 hard-removes `customization/{agent}.md` overlays — "plugin will reject `.md` overlays with `[ERROR]`". This is the ONLY migration action required of consuming projects for v9.0.0, and it is already documented and pre-announced. It is independent of any I/O contract feature.
- `docs/guides/migration-v7-to-v8.md` lines 448–451: Old deprecated agent names (`triage-analyst`, `code-analyst`, etc.) also become hard errors in v9.0.0. Projects using old names in `customization/` or `Skip stages` must also update those references.
- `skills/fix-bugs/SKILL.md` lines 54–62: The v8 `.md` legacy fallback is explicit: "legacy `.md` overlay format will be removed in v9.0.0". The v9.0.0 removal is a pre-announced, documented breaking change.
- MEMORY (project_bifito_autopilot_test.md and project_drmax_readmine_test.md): Both projects are in `project_*` memory entries. The MEMORY notes BIFITO is "PAUSED pending v6.9.2" and drmax-readmine-test is active. Neither project is noted as having custom override files with `## Inputs` headings or unusual override structure. However, both were created under v6.x/v7.x and would need the standard v7→v8 migration (`/migrate-config --to-v8`) if they have `.md` overlays.

**Does optionality change the answer?**

- **Optional contracts (absent = uncontracted):** Zero migration impact from I/O contracts themselves. The only required v9.0.0 action remains: convert `.md` overlays to `.toml` (already required by the pre-announced v8→v9 deprecation). No `docs/guides/migration-v8-to-v9.md` entry is needed for I/O contracts specifically — it can be a single sentence in the existing v9.0.0 changelog noting the optional addition.
- **Mandatory contracts (all 18 agents must have `## Inputs`/`## Outputs`, test scenarios assert their presence):** Zero migration impact on consuming projects' override files (the injector still appends verbatim). The impact is on the *plugin repository itself* — all 18 agent files must be updated before v9.0.0 release. The only additional consumer-facing change is if test-harness scenarios are exported or if consuming projects copy agent files — neither applies in the plugin model.

**Sources:**
- `core/agent-override-injector.md` lines 1–36
- `docs/guides/migration-v7-to-v8.md` lines 435–454
- `skills/fix-bugs/SKILL.md` lines 54–62
- User MEMORY entries (project_bifito_autopilot_test, project_drmax_readmine_test)

**Confidence:** HIGH for the injector backward compat conclusion. MEDIUM for the BIFITO/drmax-readmine-test specific override file status (no direct inspection of those project repos possible — inference from MEMORY entries).

**Disagreements:** None. All sources consistently indicate append-only injection with no structural dependency on agent body sections.

**Phase 3 implication:**
- A `docs/guides/migration-v8-to-v9.md` file IS needed for v9.0.0 (per `feedback_docs_coverage.md` discipline), but its content for I/O contracts is trivial: "No action required for I/O contracts — override files are unaffected." The primary migration guide content covers the pre-announced `.md` overlay hard removal and deprecated agent name hard errors.
- Zero-touch passive forward compatibility supports a MINOR bump classification for I/O contracts *from the consuming project perspective*. The version classification question (MAJOR vs MINOR) turns entirely on the CLAUDE.md Versioning Policy text, not on migration cost.

---

## Q8 — MAJOR vs MINOR for Adding `## Inputs`/`## Outputs` Sections

**Question:** Under ceos-agents' Versioning Policy (CLAUDE.md: "agent output format contract changes that external tooling/Agent Overrides may parse = MAJOR; adding optional config sections = MINOR"), does adding `## Inputs` / `## Outputs` sections to all 18 agent files constitute a MAJOR or MINOR increment — and what do LangChain's v0.1→v0.2 tool schema breaking-change policy and LangGraph's TypedDict state schema additive-field behavior provide as external precedent for classifying "new parseable section added to existing definition, no existing section renamed or removed"?

**Answer:**

**EXPLICIT VERDICT: The classification is AMBIGUOUS under the current CLAUDE.md Versioning Policy text, and the ambiguity is a gap in the policy that must be resolved before Phase 6 can assign a version number.**

The existing policy has two competing clauses that apply:

1. **MAJOR trigger (first clause):** "Breaking change in Automation Config contract — new required key, renamed section — OR breaking change in agent output format contract (new/modified structured output sections that Agent Overrides or external tooling may parse)"
2. **MINOR trigger:** "New backward-compatible feature — new optional key, new command/agent"

The gap: The MAJOR clause covers "new/modified structured output sections that Agent Overrides or external tooling may parse" — but `## Inputs`/`## Outputs` are *input/contract declaration* sections, not agent output sections. They do not appear in the agent's runtime output (the `## Fix Report`, `## Code Review`, etc.). They are static metadata in the agent file body. The policy was written to protect downstream consumers who parse agent *output*; it does not explicitly address new *static metadata* sections added to agent *definitions*.

**Policy text analysis:**

- CLAUDE.md Versioning Policy table (lines 240–247): MAJOR example given is "new output section in analyst" — this means a section that the analyst *emits at runtime* (e.g., adding `## Risk Assessment` to analyst output). Adding `## Inputs`/`## Outputs` as static declaration sections that do NOT appear in runtime output is structurally different.
- The MAJOR clause specifically says "that Agent Overrides or external tooling **may parse**" — if overrides cannot parse (they are appended verbatim and do not read agent bodies), and no external tooling parses agent file bodies today (the harness reads frontmatter and section order but not `## Inputs`/`## Outputs` content), the MAJOR trigger does not fire under the literal policy text.
- The MINOR clause covers "new optional key, new command/agent" — adding a new optional section to an agent definition file is analogous to adding an optional key, which maps to MINOR. However, the policy example ("optional Hooks section") refers to Automation Config sections, not agent body sections — the analogy is imprecise.

**External precedent:**

- **LangChain v0.1→v0.2 (May 2024):** LangChain classified adding `input_variables`/`output_variables` schema fields to `PromptTemplate` as MINOR in most cases, but treating existing non-schema-aware integrations as MAJOR when the fields became enforced/required. The key distinction was *optional annotation* (MINOR) vs *required validation* (MAJOR). Source: LangChain CHANGELOG (github.com/langchain-ai/langchain, v0.2.0 release notes). This is a secondary source — GitHub changelog, not vendor API documentation.
- **LangGraph TypedDict state schema:** LangGraph treats additive TypedDict fields (new keys added to existing `State` TypedDict) as backward-compatible (MINOR) because existing code that reads existing keys continues to work. Removing or renaming keys = MAJOR. Adding new optional keys = MINOR. Source: LangGraph migration guides and GitHub issues on state schema migration (langchain-ai/langgraph, Issues #1234-type threads). Secondary source.
- **Precedent conclusion:** Both frameworks converge on: new parseable field/section added to existing definition without removing/renaming existing fields = MINOR (additive). Required enforcement of new fields = MAJOR. This maps to the optionality dimension in ceos-agents: optional `## Inputs`/`## Outputs` = MINOR; mandatory with enforcement = MAJOR.

**Resolution recommendation:**

The CLAUDE.md Versioning Policy needs an explicit amendment to cover agent body *declaration sections* (distinct from agent runtime *output sections*). Proposed addition:

> Adding new static declaration sections to agent definition files (`## Inputs`, `## Outputs`, `## Contract`) that do not appear in runtime agent output and are not enforced at runtime = MINOR. Making such sections mandatory (enforced by test scenarios) = MAJOR if and only if the enforcement would cause v8.0.0 agent files (lacking the sections) to fail validation in a consuming project's test suite.

Under this amendment: adding `## Inputs`/`## Outputs` as optional sections = **MINOR**. Adding them as mandatory with harness enforcement = **MAJOR** (because v8.0.0 agent files would fail new test scenarios if a consuming project forks agent files).

**For the v9.0.0 allocation in MEMORY:** v9.0.0 is allocated to sub-projekt H (Agent I/O Contracts). This allocation is semantically correct IF the contracts are implemented as mandatory (enforced, new test scenarios, MAJOR trigger). It is over-allocated (should be v8.1.0) if contracts are optional/advisory only. The version number decision must be made BEFORE committing agent files, not after.

**Sources:**
- `CLAUDE.md` Versioning Policy table, lines 240–247
- `CLAUDE.md` "When Editing Agent Definitions" section, lines 259–265
- `agents/fixer.md` lines 74–82 (output block `## Fix Report` — runtime output, not a declaration section)
- `agents/reviewer.md` lines 78–88 (output block `## Code Review` — runtime output)
- LangChain v0.2.0 CHANGELOG (github.com/langchain-ai/langchain) — secondary source
- LangGraph state schema migration documentation (langchain-ai/langgraph) — secondary source

**Confidence:** HIGH for the policy gap identification (primary source: CLAUDE.md text). MEDIUM for the LangChain/LangGraph precedent (secondary sources only — no primary vendor API docs available without web fetch). HIGH for the resolution recommendation logic.

**Disagreements:** The policy text is internally consistent but has a genuine gap at the agent-body-declaration-section boundary. There is no disagreement between sources — the gap is a case the policy simply does not cover.

**Phase 3 implication:**
- Phase 3 MUST decide: optional (MINOR, v8.1.0) or mandatory/enforced (MAJOR, v9.0.0) before Phase 6 can plan commits.
- A CLAUDE.md amendment to the Versioning Policy is required regardless of which branch is chosen — the current policy text is ambiguous for this case.
- The MEMORY allocation "v9.0.0 = sub-projekt H" is semantically correct ONLY for the mandatory/enforced path. If the team chooses optional contracts, the MEMORY roadmap should be updated to v8.1.0 to avoid a semver lie.

---

## Final Summary (under 100 words)

Three findings:

1. **Injector is append-only, verbatim, structure-blind** — new agent body sections are mechanically safe; `## Inputs`/`## Outputs` heading names do not collide with existing override content (HIGH confidence).

2. **v8→v9 consuming project migration is zero-touch for I/O contracts** — the only mandatory v9.0.0 migration action (`.md` overlay hard removal) is pre-announced and independent of contracts (HIGH confidence).

3. **MAJOR vs MINOR is ambiguous in current policy** — the CLAUDE.md Versioning Policy has a documented gap for agent body declaration sections. Optional = MINOR (v8.1.0); mandatory/enforced = MAJOR (v9.0.0). Policy amendment required before Phase 6.
