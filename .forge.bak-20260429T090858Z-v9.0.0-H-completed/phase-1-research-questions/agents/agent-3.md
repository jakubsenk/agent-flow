# Phase 1 Research Questions — Agent 3

**Focus angles:** (a) "Do nothing / status quo" baseline credibility, (b) bash-harness test strategy for structural contracts, (c) versioning impact and migration strategy.

---

## Questions

### 1. Do nothing baseline: What concrete failure modes exist today from the absence of machine-readable I/O contracts in ceos-agents v8.0.0?

**Question:** In a pure-markdown agent plugin where all I/O is prose-embedded and validated only through human review, what categories of observable runtime failures (e.g., missing required output sections, unexpected mode-flag handling, silent downstream failures from malformed output) have been reported in analogous open-source Claude Code / AutoGen / CrewAI projects, and are any of these failures actually present in the v8.0.0 codebase today?

**Why it matters:** The brainstorm must produce a credible "do nothing" baseline so the recommendation does not default to "formalize because formalization is better." If the failure rate in the current system is near zero (all 297 tests pass, BIFITO/drmax pilots run without contract errors), the cost-benefit of formalizing changes materially. If concrete failures can be identified in the current codebase (e.g., `frontmatter-completeness.sh` still lists 21 pre-v8 agents; `read-only-agents.sh` references pre-v8 agent names), the "do nothing" option carries documented technical debt risk.

**Source hint:** Inspect `tests/scenarios/frontmatter-completeness.sh` and `tests/scenarios/read-only-agents.sh` for stale pre-v8 agent lists (v8.0.1 polish item 6); inspect `tests/scenarios/section-order.sh` for the same issue; check v8 forge run archive at `.forge/` for blocks attributed to contract mismatches; search GitHub/GitLab for issues in analogous projects (LangChain LCEL, CrewAI agent output validation).

---

### 2. Do nothing baseline: Does the Claude Code Task tool itself impose any implicit I/O contract enforcement today, and what gap would explicit contracts fill?

**Question:** When Claude Code's Task tool dispatches an agent, what validation (if any) does the runtime apply to the agent's output before returning it to the calling skill — specifically: does it enforce frontmatter fields, section presence, or output token patterns — or does it return the raw LLM response verbatim, making all contract enforcement the caller's responsibility?

**Why it matters:** If the Task tool already enforces some contract at the runtime boundary (e.g., requiring frontmatter, validating YAML), then the gap filled by explicit I/O contract sections in agent files is narrower than if it returns raw text. This directly determines whether the formalization work buys runtime protection or is purely documentation/lint-time protection. The answer shapes whether the brainstorm should recommend a purely static approach (bash lint) vs. a runtime validation hook in dispatching skills.

**Source hint:** Anthropic Claude Code documentation on the Task tool (tool-use return contract); Claude Code plugin system docs (if public); compare with Anthropic Tool Use API schema — specifically whether tool `output` fields have type enforcement or return raw strings.

---

### 3. Backcompat: What is the exact injection point where a new `## Inputs` / `## Outputs` section in agent body files would interact with `customization/{agent-name}.md` overrides, and what ordering assumption do v8.0.0 overrides currently make?

**Question:** Given that `core/agent-override-injector.md` appends the override file as `## Project-Specific Instructions` verbatim at the end of the agent context, and given that v8.0.0 customization files in `customization/` may reference output section names (e.g., "always include X in ## Code Review"), what specific structural assumption about agent body section order do existing override files make — and would inserting new `## Inputs` / `## Outputs` sections before or after `## Constraints` violate those assumptions?

**Why it matters:** This is the hard backward-compat constraint. If an existing override file says "append X to the ## Fix Report section" and the new contract changes the name or position of that section, the override silently misfires. The question is load-bearing for the design decision of WHERE in the agent file structure new contract sections live (frontmatter vs. between Expertise and Process vs. after Constraints). If the answer is "overrides only reference the prose output block names, not body section names," the risk is lower.

**Source hint:** Read `core/agent-override-injector.md` (already in context); examine `examples/` directory for sample override files; check `agents/fixer.md` and `agents/reviewer.md` output blocks (## Fix Report, ## Code Review) for the exact names an override might reference.

---

### 4. Versioning: Under ceos-agents' own Versioning Policy, does adding `## Inputs` and `## Outputs` sections to all 18 agent files trigger MAJOR or MINOR, and what is the correct version number for a purely-additive, optional-field design?

**Question:** Given CLAUDE.md's Versioning Policy — "agent OUTPUT format contract changes that external tooling / Agent Overrides may parse = MAJOR; adding optional config sections = MINOR" — and given that new `## Inputs` / `## Outputs` sections would (a) add structured fields that external override files and downstream skills could parse, but (b) not rename or remove existing output sections, does this additive change trigger a MAJOR increment under the existing policy, or does it qualify as MINOR because existing output formats are preserved?

**Why it matters:** This determines whether the target version is v9.0.0 (MAJOR, per MEMORY allocation) or stays v9.0.0 for other reasons, and — critically — whether the CLAUDE.md Versioning Policy itself needs to be amended to cover a "new structured contract section" category. A misclassification here creates a semver lie that confuses downstream consumers. The brainstorm must produce a defended verdict.

**Source hint:** CLAUDE.md `## Versioning Policy` table (in context); compare with Semantic Versioning 2.0.0 spec (semver.org) for "additive backward-compatible changes = MINOR" rule; look at how AutoGen or LangChain handle schema additions in their agent output contracts.

---

### 5. Versioning: What migration path is required for v8.0.0 consuming projects (BIFITO, drmax-readmine-test) when their `customization/` overrides encounter agent files with new contract sections?

**Question:** If new `## Inputs` / `## Outputs` (or equivalent) sections are added to all 18 agent files in v9.0.0, what is the minimal migration action required by a v8.0.0 consuming project — specifically: do their existing `customization/{agent-name}.md` override files need any modification, or are they passively forward-compatible because the override injector appends them after all existing sections without inspecting section names?

**Why it matters:** If migration is zero-touch (passive forward compatibility), the version bump can confidently be MINOR. If consuming projects must update overrides to reference new section names, it is MAJOR and requires a migration guide. This question also determines whether a `docs/guides/migration-v8-to-v9.md` file is needed (per `feedback_docs_coverage.md` discipline) and what it must contain.

**Source hint:** `core/agent-override-injector.md` injection mechanism (already read); MEMORY entry for `project_bifito_autopilot_test.md` and `project_drmax_readmine_test.md` (check for any custom override files referenced); `docs/guides/` for existing migration guide patterns (e.g., migration-v7-to-v8.md).

---

### 6. Test strategy: What is the minimal bash-harness assertion set that validates a machine-readable I/O contract section — covering presence, field completeness, and naming consistency — without requiring a YAML/JSON parser in the test environment?

**Question:** Given that the existing test harness (`tests/harness/run-tests.sh`) uses only bash builtins + `grep -qE` / `awk` / `wc -l` / `diff -q` (no jq, no yq, no Python), what is the smallest set of grep/awk assertions that can validate a new structured contract section (e.g., `## Inputs` with typed fields) in each of the 18 agent files — and what failure cases would those assertions miss that a full parser would catch?

**Why it matters:** The harness constraint (bash + POSIX tools only) is a hard design input for the test strategy. If the chosen contract format (e.g., YAML block, typed list, table) cannot be validated with grep/awk, either the test strategy must accept lower coverage, the contract format must be simplified to grep-friendly syntax, or a new test dependency (jq/yq) must be introduced. This is load-bearing for the "how to formalize" decision — a YAML schema block may be elegant but untestable without a parser.

**Source hint:** Inspect existing scenarios `v8-agents-analyst-shape.sh`, `frontmatter-completeness.sh`, `section-order.sh` for awk-based section extraction patterns; inspect `read-only-agents.sh` for the `awk '/^## Process/{found=1}...` pattern that could be generalized to new sections; check POSIX awk capabilities for structured field parsing.

---

### 7. Test strategy: What naming convention and SKIP protocol should new I/O contract test scenarios follow to remain non-breaking during the Phase 7 staging window, and how do existing scenarios handle agent files that don't yet have the new sections?

**Question:** Looking at existing scenarios that use `exit 77` (SKIP) when an expected file or feature is absent (e.g., `v8-agents-analyst-shape.sh` guards with `[ ! -f "$ANALYST_FILE" ] && exit 77`), what naming convention and SKIP guard pattern should new contract validation scenarios follow so that: (a) they SKIP cleanly on v8.0.0 agent files that lack the new section, (b) they FAIL on v9.0.0 agent files that have the section but malformed content, and (c) the scenario names are discoverable via the `{prefix}-{topic}-{aspect}` naming convention?

**Why it matters:** The harness runs all 297+ scenarios on every commit. New I/O contract scenarios introduced in the same commit as new agent sections will PASS or FAIL correctly. But during development (before agent files are updated), they must SKIP rather than FAIL to avoid breaking the CI green bar. The SKIP-guard pattern is a concrete test design decision the TDD phase must implement correctly; getting it wrong creates false negatives.

**Source hint:** Read `tests/scenarios/v8-agents-analyst-shape.sh` for the file-existence SKIP guard pattern; read `tests/harness/run-tests.sh` for the `exit_code 77 = SKIP` handling; look at the `{prefix}-{topic}-{aspect}.sh` naming examples in `analysis.md` context (e.g., `v8-agents-enumeration.sh`, `v8-agents-analyst-shape.sh`).

---

### 8. Test strategy: What is the minimum harness coverage to assert cross-agent output-name consistency — ensuring that skills consuming agent output (e.g., fix-bugs reading ## Fix Report) reference the same section names declared in agent contracts?

**Question:** The codebase currently has inconsistent output section naming across agents (noted in `analysis.md`: "Triage Analysis, Fix Report, Code Review — no canonical naming scheme"). What grep-based cross-reference test could assert that every output section name declared in an agent's contract also appears verbatim in the dispatching skill's SKILL.md — and which existing cross-reference scenario (`xref-agent-registry.sh`, `xref-core-registry.sh`) could serve as a structural template for this?

**Why it matters:** The value of formalizing I/O contracts is zero if skills reference output section names that differ from what agents declare. A cross-reference test (agent declares `## Fix Report` → `skills/fix-bugs/SKILL.md` must reference `Fix Report`) closes the contract loop and makes violations detectable at commit time. This question determines whether a new `xref-io-contracts.sh` scenario is needed and how complex it would be to implement with grep.

**Source hint:** Read `tests/scenarios/xref-agent-registry.sh` and `xref-core-registry.sh` for cross-reference pattern; read `skills/fix-bugs/SKILL.md` for current output section references; grep agents/*.md for `## [A-Z]` headings inside Process sections to enumerate current output section names.

---

### 9. How baseline: Do any comparable agent-framework projects (LangChain Expression Language, AutoGen GroupChat, CrewAI) define per-agent I/O contracts as structured sections within the same file as the agent definition, and what tradeoffs emerged from those production deployments?

**Question:** In LangChain LCEL (runnable.input_schema / output_schema as Python class annotations on the same object), AutoGen v0.4 (agent `can_generate_reply` + message types), and CrewAI (task `expected_output` field on Task objects co-located with agent definition) — what is the co-location pattern used, what validation mechanism (runtime vs. lint-time) was chosen, and what pain points drove those choices in production deployments documented in their GitHub issues or migration guides?

**Why it matters:** This is the primary "how" research question for non-YAML approaches. If production frameworks converge on co-located contracts with lightweight type hints rather than full JSON Schema, that is evidence for a simpler design. If they converge on sidecar schema files, that argues for the sidecar approach. The brainstorm needs concrete precedents, not abstract design principles.

**Source hint:** LangChain docs "Runnable interface" (`.input_schema`, `.output_schema` properties); AutoGen v0.4 migration guide on message types; CrewAI docs on Task `expected_output`; GitHub issues for each project searching "contract", "output validation", "schema"; real production case studies in HuggingFace blog or Anthropic cookbook.

---

### 10. Backcompat + how: If new I/O contract sections are defined as optional (absent = uncontracted, present = validated), what enforcement gap does this create for the 18 agents that don't add sections in v9.0.0, and is a "warn-only" validation mode sufficient to preserve backward compatibility while incrementally adopting contracts?

**Question:** If the chosen design marks new contract sections as optional (agents without them are treated as uncontracted and skip validation), what percentage of the runtime protection benefit is achieved if only, say, 6 of 18 agents adopt contracts in v9.0.0 — and do comparable frameworks (e.g., Pydantic BaseModel with optional fields, TypeScript interface with optional properties) provide empirical data on adoption curves when contract adoption is voluntary vs. mandatory?

**Why it matters:** The brainstorm must decide between "all 18 agents get contracts in v9.0.0" (higher effort, cleaner invariant, possibly MAJOR) vs. "contracts are opt-in, added incrementally across minor releases" (lower effort per release, but the cross-reference test in Q8 cannot be comprehensive until all agents comply). The "warn-only" vs. "fail-hard" validation mode is a concrete design decision with backward-compat implications for the test harness (new scenarios must SKIP vs. FAIL on agents without contracts).

**Source hint:** Pydantic v1 vs. v2 migration on optional vs. required fields; TypeScript strict mode adoption case studies; look at how the ceos-agents harness currently handles optional features (e.g., `browser-verification-skip.sh` uses exit 77 for optional config sections) — this pattern may generalize to optional contracts.

---

### 11. Test strategy + versioning: What is the correct order of git operations (test scenario commit, agent file updates, CLAUDE.md version policy update, version bump) to preserve the "all tests green before commit" invariant when introducing both new test scenarios and the new contract sections they test?

**Question:** Given the Version Release Process in MEMORY ("ALWAYS run ./tests/harness/run-tests.sh BEFORE committing") and given that new I/O contract test scenarios will FAIL on agent files lacking the new section until those files are also updated in the same commit — what is the correct atomic commit strategy: (a) add contract sections to all 18 agent files and new test scenarios in ONE commit, (b) add scenarios with exit-77 SKIP guards first, then add contract sections in a second commit that flips them from SKIP to PASS, or (c) some other ordering — and which approach avoids any commit where `run-tests.sh` exits non-zero?

**Why it matters:** This is a concrete process question that determines the implementation plan structure in Phase 6. Getting the commit order wrong means either (a) the CI is red during development (acceptable in a branch, but the MEMORY invariant says "before committing" not "before merging"), or (b) the SKIP-guard pattern from Q7 is mandatory rather than optional. The answer also determines whether the implementation plan needs a "staging" phase for test scenarios separate from the "implementation" phase for agent files.

**Source hint:** MEMORY `## Version Release Process` (always run tests before committing); existing forge run commit logs (`.forge/` archive, `git log --oneline -20`); `feedback_negation_logic_when_wrapping_checks.md` for logic inversion risk in SKIP guards; compare with how v8.0.0 forge cycle 3 handled parallel fixer agents writing to overlapping files.

---

## Summary

These 11 questions cover all five required areas. Questions 1-2 stress-test the "do nothing" baseline with codebase-grounded evidence and runtime boundary analysis. Questions 3 and 10 anchor the backward-compatibility constraint to the concrete override injection mechanism. Questions 4-5 resolve the MAJOR/MINOR versioning ambiguity and the migration scope for live consuming projects. Questions 6-8 and 11 address the bash-harness test strategy at three levels: assertion primitives, SKIP-guard protocol, and commit-order invariant. Question 9 supplies comparative evidence from production agent frameworks to ground the "how" decision without presupposing an answer.
