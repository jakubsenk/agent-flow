# E2E Test Strategy: The Skeptical QA Strategist

**Author:** Claude Opus 4.6 (1M context) -- The Skeptical QA Strategist
**Date:** 2026-03-31
**Status:** PROPOSAL
**Guiding Principle:** Test what can break, not what looks neat on a coverage report.

---

## Strategy Overview

The existing 25 tests do two things well: agent frontmatter validation (model, sections, fields) and scaffold pipeline structural checks. They do one thing poorly: they treat the plugin as a bag of files rather than a system with contracts between those files. The six confirmed bugs all share a root cause -- information in file A drifted out of sync with file B, and no test forced the two to agree. The 12 coverage gaps are not uniformly worth closing. Some (feature pipeline coverage, deployment verifier coverage) represent genuine risk because those pipelines ship to users without a single structural assertion. Others (state.json field-level validation) are test-theater -- they simulate thoroughness against a schema that only matters at runtime, where our bash tests cannot observe actual behavior anyway.

The strategy I propose is organized around one economic question per test: "What class of real bug does this catch, and how likely is that bug to occur during normal development?" Tests that catch copy-paste drift between commands (high frequency) get priority. Tests that catch a missing optional field in a schema document (near-zero frequency, zero runtime impact from our tests) get deprioritized or excluded. I propose 12 new scenarios, grouped into 4 tiers by bug-catching ROI. The top tier (cross-reference integrity, agent dispatch consistency) catches the exact class of bugs already found. The bottom tier is explicitly listed as "tests I would NOT add" with rationale.

A critical design decision: every new test must derive its expected values from authoritative source files, never from hardcoded lists. The existing tests hardcode `AGENTS=(triage-analyst code-analyst fixer ...)` with 18 entries while 19 agents exist. This is the most insidious anti-pattern in structural tests -- the test itself becomes a stale artifact. My scenarios use `ls agents/*.md` and `grep` against CLAUDE.md as the source of truth, so when the 20th agent is added, the tests catch drift automatically instead of silently passing with an outdated assertion.

---

## Test Taxonomy (Point 1)

I propose 4 tiers, not directories. Tests remain as flat `.sh` files in `tests/scenarios/` -- subdirectories add navigation cost without benefit at 37 files. Instead, naming convention signals tier:

| Tier | Prefix | What it catches | Existing count | Proposed additions |
|------|--------|-----------------|----------------|--------------------|
| T1: Cross-reference integrity | `xref-` | File A says X, file B says Y | 0 | 3 |
| T2: Pipeline contract | `pipeline-` | Step ordering, agent dispatch, state writes | 3 (pipeline-consistency, state-schema, verify-fail) | 4 |
| T3: Agent invariant | (none -- existing names) | Per-agent structural properties | 10 (model-assignment, frontmatter, section-order, read-only, etc.) | 2 |
| T4: Config contract | `config-` | Automation Config keys match what commands actually read | 0 | 3 |

The naming convention is descriptive, not prescriptive. Existing tests keep their names. New tests use the tier prefix so a developer scanning the directory knows immediately what class of bug the test targets.

---

## Scenario Granularity (Point 2)

**Principle: One scenario = one failure mode.** Not one property, not one pipeline. A scenario should fail for exactly one class of reason. If it can fail because either (a) an agent is missing from a list or (b) a pipeline step is misordered, it should be two scenarios.

The existing `pipeline-consistency.sh` violates this -- it checks block comment format, `git add -A` usage, retry limit references, temp directory safety, AND rollback context in a single file. That is five orthogonal failure modes. I would not refactor it (constraint: existing tests stay unchanged), but new scenarios follow the one-failure-mode rule.

**Exception:** Cross-reference integrity tests naturally span multiple files but test a single invariant (file A and file B agree on a specific fact). These are one scenario per cross-reference axis, not one scenario per file pair.

---

## Specific Scenario Designs

### Scenario 1: `xref-agent-registry-sync.sh`
**Tier:** T1 (cross-reference integrity)
**Purpose:** Every agent file in `agents/` must appear in CLAUDE.md's model assignment table, and vice versa. Catches the deployment-verifier gap (19th agent exists in filesystem, absent from test assertions that hardcode 18).
**Key assertions:**
1. List all `agents/*.md` files dynamically (via `ls`), extract basenames.
2. For each agent: verify its name appears in at least one of the three model-tier rows in CLAUDE.md's `### Model Selection` table.
3. For each agent name mentioned in the CLAUDE.md model table: verify `agents/{name}.md` exists.
4. Count mismatch between filesystem and CLAUDE.md = FAIL with diff output.
5. Verify the CLAUDE.md claim "19 agents" matches actual count.
**What this catches:** Any new agent added to `agents/` but not registered in CLAUDE.md (or vice versa). This is the #1 confirmed bug class.

### Scenario 2: `xref-core-registry-sync.sh`
**Tier:** T1 (cross-reference integrity)
**Purpose:** Every core file in `core/` must be referenced by at least one pipeline command, and vice versa. Catches the mcp-detection gap (11th core file exists, absent from test list of 10).
**Key assertions:**
1. List all `core/*.md` files dynamically.
2. For each core file: search all `commands/*.md` for a reference to `core/{name}` or the bare `{name}.md`. At least one command must reference it.
3. Check that every `core/` reference in pipeline commands (fix-ticket, fix-bugs, implement-feature, scaffold, check-deploy) points to an existing file.
4. Verify CLAUDE.md claim "11 shared pipeline pattern contracts" matches actual count.
**What this catches:** Orphaned core files (written but never referenced), dangling references (command references `core/foo.md` that does not exist), count drift in CLAUDE.md.

### Scenario 3: `xref-command-count-sync.sh`
**Tier:** T1 (cross-reference integrity)
**Purpose:** The counts in CLAUDE.md ("19 agents, 25 commands, 1 skill") must match the filesystem.
**Key assertions:**
1. Count `agents/*.md`, `commands/*.md`, `skills/*.md` (or skill directories).
2. Compare against the numbers stated in CLAUDE.md.
3. Cross-check the command list in CLAUDE.md's "Commands (orchestration)" line against actual files.
4. Cross-check the agent list in CLAUDE.md's "Agents (specialists)" line against actual files.
**What this catches:** Adding a command/agent without updating CLAUDE.md documentation. This is a high-frequency edit pattern.

### Scenario 4: `pipeline-feature-step-order.sh`
**Tier:** T2 (pipeline contract)
**Purpose:** The implement-feature command's pipeline steps appear in the correct order. This is the ZERO-coverage gap for the feature pipeline.
**Key assertions:**
1. Extract all `### N.` and `#### Na.` headings from `commands/implement-feature.md` with line numbers.
2. Verify monotonic ordering: 0 < 0b < 0c < 1 < 2 < 3 < 4 < 5 < 6 < 6a < ... < 6h < 7 < 8 < 9 < 10 < 10a < 10b < X.
3. Verify key agents are dispatched in correct relative order: spec-analyst before architect, architect before fixer, fixer before reviewer, reviewer before test-engineer, test-engineer before publisher.
4. Verify Block handler (X) appears after all pipeline steps.
5. Verify acceptance gate (6g) exists and appears between test-engineer (6e) and commit (6h).
**What this catches:** Step reordering during refactoring (e.g., someone moves the architect step after the fixer). This is a real risk because implement-feature.md is 400+ lines and has been edited frequently.

### Scenario 5: `pipeline-deploy-verifier.sh`
**Tier:** T2 (pipeline contract)
**Purpose:** The deployment-verifier agent and check-deploy command are structurally complete. This is the ZERO-coverage gap for deployment.
**Key assertions:**
1. `agents/deployment-verifier.md` exists with all 4 frontmatter fields.
2. Model is sonnet (per CLAUDE.md table).
3. `commands/check-deploy.md` exists and dispatches `deployment-verifier` via Task tool.
4. check-deploy references `state.json` and `state-manager`.
5. check-deploy has `--start`, `--stop` flag parsing.
6. deployment-verifier agent has port validation (digits-only, range 1-65535) in Process section.
7. deployment-verifier has `NEVER delete containers` constraint.
8. CLAUDE.md's Local Deployment config section lists all 6 keys that check-deploy reads.
**What this catches:** Structural regressions in the deployment pipeline, which currently has zero test coverage.

### Scenario 6: `pipeline-agent-dispatch-models.sh`
**Tier:** T2 (pipeline contract)
**Purpose:** Every `(Task tool, model: X)` dispatch in every pipeline command uses the correct model for that agent. Catches model mismatch between command dispatch and agent frontmatter.
**Key assertions:**
1. For each pipeline command (fix-ticket, fix-bugs, implement-feature, scaffold, check-deploy): extract all lines matching `(Task tool, model: {model})` with the agent name from context.
2. For each extracted (agent, model) pair: read the agent's frontmatter and verify the model matches.
3. Report any mismatches with file, line number, expected vs actual.
**What this catches:** A command dispatching an agent with the wrong model tier (e.g., `fixer (Task tool, model: sonnet)` when fixer.md says `model: opus`). This is a high-severity bug -- it changes the quality of output silently. The existing model-assignment test only checks agent frontmatter, not the dispatch sites.

### Scenario 7: `pipeline-state-write-completeness.sh`
**Tier:** T2 (pipeline contract)
**Purpose:** Every pipeline command that initializes state.json also writes to each phase section it executes. Validates write-completeness, not field-level content.
**Key assertions:**
1. For fix-ticket.md: verify references to state.json writes for phases: triage, code_analysis, reproduction, fixer_reviewer, test, e2e_test, browser_verification, acceptance_gate, publisher, block.
2. For implement-feature.md: verify references to state.json writes for phases: triage (reused for spec-analyst), code_analysis (reused for architect), decomposition, fixer_reviewer, test, acceptance_gate, publisher, block.
3. For scaffold.md: verify references to infrastructure, state persistence.
4. For check-deploy.md: verify references to deployment object write.
5. Check that each pipeline command references `atomic write protocol` or `state-manager` at least once per major phase.
**What this catches:** A new phase added to a command without corresponding state write. The existing state-schema test only counts total state references (>= 5), which passes even if an entire phase is missing its write.

### Scenario 8: `config-required-keys-consumed.sh`
**Tier:** T4 (config contract)
**Purpose:** Every key listed as "required" in CLAUDE.md's Config Contract table is actually read by at least one command.
**Key assertions:**
1. Parse the CLAUDE.md Config Contract required sections table. Extract all key names (Type, Instance, Project, Bug query, State transitions, On start set, Remote, Base branch, Branch naming, Labels, Build command, Test command).
2. For each required key: verify at least one `commands/*.md` file contains a reference to that key name (case-insensitive grep).
3. Parse the optional sections table. For each optional key: verify at least one command references it.
4. Report any documented-but-unconsumed keys.
**What this catches:** Config contract documentation claiming a key is required when no command actually reads it, or a new required key added to CLAUDE.md without any command consuming it.

### Scenario 9: `config-fixture-completeness.sh`
**Tier:** T4 (config contract)
**Purpose:** The test fixture `tests/harness/fixtures/automation-config.md` contains all required config sections.
**Key assertions:**
1. Check that the fixture has all 5 required sections: Issue Tracker, Source Control, PR Rules, PR Description Template, Build & Test.
2. Check that each required section has the documented required keys.
3. Check that the fixture uses table format (not bullet lists).
**What this catches:** Test fixture drift -- the fixture was written for an earlier config version and no longer represents a valid config. Currently the fixture has no validation test at all.

### Scenario 10: `config-optional-sections-documented.sh`
**Tier:** T4 (config contract)
**Purpose:** Every optional config section mentioned in CLAUDE.md is also listed in the config-reader core contract, and vice versa.
**Key assertions:**
1. Extract optional section names from CLAUDE.md Config Contract table.
2. Extract section names from `core/config-reader.md`.
3. Compute the symmetric difference -- any section in one but not the other is a FAIL.
**What this catches:** Adding a new optional config section to CLAUDE.md without updating config-reader, or vice versa. This is a contract drift bug.

### Scenario 11: `pipeline-feature-agents-present.sh`
**Tier:** T2 (pipeline contract)
**Purpose:** The implement-feature command dispatches all expected agents in its pipeline.
**Key assertions:**
1. Verify implement-feature.md contains Task tool dispatches for: spec-analyst, architect, fixer, reviewer, test-engineer, publisher, rollback-agent, acceptance-gate.
2. Verify optional agent dispatches are conditional: e2e-test-engineer (guarded by E2E Test config or profile).
3. Verify each dispatched agent file exists in `agents/`.
4. Verify the Block handler references rollback-agent.
**What this catches:** An agent removed from the pipeline during refactoring. Unlike the existing verify-fail test (which only checks for "Feature Verification" string), this verifies the full agent dispatch chain.

### Scenario 12: `xref-skip-stage-names.sh`
**Tier:** T1 (cross-reference integrity)
**Purpose:** The stage names documented in CLAUDE.md as skippable (triage, code-analyst, spec-analyst, test-engineer, e2e-test-engineer, reproducer, browser-verifier) match the actual stage mapping tables in pipeline commands.
**Key assertions:**
1. Extract the skippable stage list from CLAUDE.md's "Stage names for skip:" line.
2. Extract the unskippable stages from CLAUDE.md's "Stages ... CANNOT be skipped" line.
3. For each pipeline command (fix-ticket, fix-bugs, implement-feature): extract its "Stage mapping" section.
4. Verify every stage name in the command's stage mapping appears in CLAUDE.md's combined (skippable + unskippable) list.
5. Verify every command enforces the "NEVER skip" restriction for fixer, reviewer, publisher.
**What this catches:** A stage renamed in a command but not in CLAUDE.md, or a new stage added to a command without documenting its skippability.

---

## Mock Project Strategy (Point 8)

**Recommendation: Do not create a mock project.** Here is why:

The existing fixture (`tests/harness/fixtures/automation-config.md`) is sufficient for config-shape tests. A full mock project (with CLAUDE.md, source code, package.json, etc.) would test whether ceos-agents can *run* against a project -- but our tests cannot run ceos-agents. They are structural/content validators using grep and awk. A mock project would be an expensive artifact that tests nothing additional beyond what config-fixture-completeness already covers.

**What to do instead:**
1. Keep the existing `automation-config.md` fixture.
2. Add a second fixture `automation-config-minimal.md` that contains ONLY the required sections with no optional sections. Use this in config-required-keys-consumed to verify that the minimal config is a valid subset.
3. Add a third fixture `automation-config-invalid.md` with deliberate errors (missing required key, bullet-list format, empty values) for any future negative-testing needs.

The fixture strategy is: validate that the fixture matches the contract, not that the contract works at runtime. Runtime validation requires actually running Claude Code, which is out of scope for bash tests.

---

## Regression Guard Strategy (Point 9)

The regression guard approach has three layers:

**Layer 1: Count guards (cheap, catches additions/removals).**
Every existing test that hardcodes a count ("18 agents", "10 core files") is a latent regression. The `xref-agent-registry-sync` and `xref-core-registry-sync` scenarios replace hardcoded counts with dynamic derivation. For new tests, the rule is: NEVER hardcode a count. Always derive from either the filesystem (`ls | wc -l`) or the documentation (grep CLAUDE.md).

**Layer 2: Name-level guards (medium cost, catches renames).**
The `xref-` scenarios check that every name in the filesystem has a corresponding entry in documentation and vice versa. A renamed agent (e.g., `triage-analyst` to `triage-engine`) will trigger a failure in both the filesystem and documentation checks.

**Layer 3: Content-level guards (higher cost, catches semantic drift).**
The `pipeline-agent-dispatch-models` scenario checks that the model specified at the dispatch site matches the agent's frontmatter. The `xref-skip-stage-names` scenario checks that stage names are consistent between documentation and implementation. These catch the most insidious bugs -- where a value is changed in one place but not another.

**What I explicitly do NOT propose as regression guards:**
- Snapshot tests (recording full file contents and diffing against a baseline). These have near-100% false-positive rate when any intentional change is made and provide zero signal about correctness.
- Line-count guards ("fix-ticket.md should have between 350 and 450 lines"). These are noise generators, not bug detectors.
- Version-specific regression tests (like scaffold-v561-regression.sh). These already exist and are valuable for the version they target. I would not add more of them unless a specific version introduces a known fragile edit.

---

## Pros and Cons Self-Assessment

### Strengths of this proposal

1. **Zero-tolerance for hardcoded lists.** Every dynamic count and name list is derived from an authoritative source. This eliminates the entire class of "test passes but plugin is broken" bugs caused by stale test data.

2. **Cross-reference focus catches the actual bug class.** All 6 confirmed bugs were cross-reference drift. 3 of 12 new tests are pure cross-reference checks; another 4 have cross-reference components. This allocation matches the empirical failure distribution.

3. **Minimal mock infrastructure.** No mock project, no new directories, no test helpers. Every new test is a self-contained bash script following the existing pattern. Integration with run-tests.sh is automatic (it globs `scenarios/*.sh`).

4. **Explicit "not worth testing" list.** Unlike proposals that maximize scenario count, this one explicitly identifies tests that would provide false confidence and explains why they are excluded.

### Weaknesses and honest limitations

1. **Cannot catch runtime bugs.** Every proposed test is structural validation. If an agent's prompt text is wrong but syntactically valid, no grep will catch it. The entire test suite is fundamentally limited to "are the files internally consistent" -- it cannot answer "does the pipeline produce correct output." This is an inherent limitation of bash-based structural tests, not a flaw in the proposal, but it means the test suite should never be mistaken for runtime validation.

2. **Cross-reference tests are fragile to format changes.** If CLAUDE.md's model assignment table changes format (e.g., from markdown table to bullet list), `xref-agent-registry-sync` will break. The test is coupled to the documentation format, not the semantic content. Mitigation: the parsing patterns use generous regex, but format changes will still require test updates.

3. **The agent-dispatch-model test is the most complex.** It requires parsing natural language lines like "Run `ceos-agents:fixer` (Task tool, model: opus)" to extract agent name and model. This regex is fragile -- if a command uses slightly different phrasing (e.g., "Dispatch fixer agent via Task"), the test will miss it. Mitigation: the test should report *coverage* (how many dispatch sites were matched) alongside assertions, so a drop in coverage signals a format change.

4. **No negative tests.** I propose only "happy path structural" tests. There are no tests that deliberately introduce an error and verify that some mechanism catches it -- because there is no mechanism to catch errors in this pure-markdown system. The pipeline runs in Claude Code's runtime, which we cannot invoke from bash.

5. **12 new scenarios may be too many.** If maintenance burden is a concern, the T1 tier (3 xref scenarios) delivers the highest ROI per test. The T4 tier (3 config scenarios) delivers the lowest. If forced to cut, cut T4 first.

---

## Tests I Would Explicitly NOT Add (and Why)

### 1. State.json field-level schema validation
**What it would test:** Parse the state schema and verify every field name, type, and default value appears correctly in state/schema.md.
**Why not:** The schema document is descriptive, not prescriptive. No runtime code reads this schema file. The actual state writes are embedded in command markdown as prose instructions. A test that validates the schema document validates documentation, not behavior. The existing state-schema test (checking that state.json is referenced >= 5 times per command) is already the right granularity. Going deeper is testing documentation quality, not pipeline correctness.

### 2. Agent description length/format validation
**What it would test:** All agent `description` frontmatter fields are under 80 characters, use imperative mood, etc.
**Why not:** This is style policing, not bug detection. A 90-character description has zero runtime impact. The existing frontmatter-completeness test already verifies the field exists.

### 3. CHANGELOG.md consistency tests
**What it would test:** Every version mentioned in CHANGELOG.md has a corresponding git tag.
**Why not:** This is release process validation, which belongs in a CI release workflow, not in the structural test suite. The test suite runs on every commit -- changelog consistency only matters at release time.

### 4. Duplicate content detection between commands
**What it would test:** Flag sections of fix-ticket.md and fix-bugs.md that are copy-pasted (>10 consecutive identical lines).
**Why not:** Duplication between these commands is intentional design (each is a complete pipeline specification). The `core/` extraction already centralizes shared logic. Testing for duplication would produce false positives on every legitimate parallel section.

### 5. Agent Process step numbering validation
**What it would test:** Every agent's ## Process section has consecutively numbered steps (1, 2, 3, ...).
**Why not:** Several agents legitimately use non-consecutive numbering (sub-steps like 2a, 2b) or conditional branches. The regex complexity to handle all variants exceeds the bug-catching value. In 19 agents across 25+ versions, misnumbered steps have caused zero reported bugs.

### 6. PR Description Template validation
**What it would test:** The fixture's PR Description Template has {summary}, {changes}, {testing} placeholders.
**Why not:** Template content is project-specific. The plugin provides a format convention, not a fixed template. Testing placeholder names in a fixture tests the fixture, not the plugin.

### 7. Comprehensive workflow-router intent coverage
**What it would test:** Every command is routable from at least one intent in the workflow-router skill.
**Why not:** The workflow-router is a convenience feature (natural language -> command mapping). A missing intent means the user has to type the command name instead of a natural language phrase. The bug severity is cosmetic. Testing it requires parsing a complex intent table whose format has changed multiple times.

### 8. Hook execution order between pre-fix and post-fix
**What it would test:** Every command that has a pre-fix hook also has a post-fix hook in the correct relative position.
**Why not:** Hooks are optional config. A command may legitimately have pre-fix but no post-fix (or vice versa). The ordering is trivially correct by inspection and has never drifted.

---

## Integration with Existing Harness (Implementation Notes)

All new scenarios follow the existing pattern:
- Shebang: `#!/usr/bin/env bash`
- `set -euo pipefail` (or `set -e` to match simpler existing tests)
- `REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"`
- `FAIL=0` + `fail()` function pattern for multi-assertion scenarios
- Exit code 0 for pass, 1 for fail
- Final line: `echo "PASS: ..."` on success

No changes to `run-tests.sh` are needed -- it globs `scenarios/*.sh` automatically.

**Estimated test execution time impact:** Each new scenario is pure grep/awk against local files. Expected wall-clock time: < 0.5s per scenario. Total addition: < 6s to the full suite.

**Priority order for implementation:**
1. `xref-agent-registry-sync.sh` -- catches the confirmed deployment-verifier gap immediately
2. `xref-core-registry-sync.sh` -- catches the confirmed mcp-detection gap immediately
3. `pipeline-agent-dispatch-models.sh` -- catches the highest-severity silent bug class (wrong model tier)
4. `pipeline-feature-step-order.sh` -- closes the feature pipeline zero-coverage gap
5. `pipeline-deploy-verifier.sh` -- closes the deployment zero-coverage gap
6. `xref-command-count-sync.sh` -- fast to implement, high documentation-drift catch rate
7. `xref-skip-stage-names.sh` -- medium complexity, catches stage rename drift
8. `pipeline-state-write-completeness.sh` -- validates state write coverage per pipeline
9. `pipeline-feature-agents-present.sh` -- validates feature pipeline agent dispatch chain
10. `config-required-keys-consumed.sh` -- validates config contract consumption
11. `config-fixture-completeness.sh` -- validates test fixture
12. `config-optional-sections-documented.sh` -- lowest priority, catches config-reader drift

---

## Summary Table

| # | Scenario | Tier | Bug class | Priority | Estimated LOC |
|---|----------|------|-----------|----------|---------------|
| 1 | xref-agent-registry-sync | T1 | Agent count/name drift | P1 | ~50 |
| 2 | xref-core-registry-sync | T1 | Core file count/name drift | P1 | ~45 |
| 3 | xref-command-count-sync | T1 | Command/agent list drift | P2 | ~40 |
| 4 | pipeline-feature-step-order | T2 | Step reordering | P1 | ~60 |
| 5 | pipeline-deploy-verifier | T2 | Deployment coverage gap | P1 | ~55 |
| 6 | pipeline-agent-dispatch-models | T2 | Model tier mismatch | P1 | ~70 |
| 7 | pipeline-state-write-completeness | T2 | Missing state writes | P2 | ~65 |
| 8 | config-required-keys-consumed | T4 | Documented-but-unconsumed keys | P3 | ~50 |
| 9 | config-fixture-completeness | T4 | Fixture drift | P3 | ~35 |
| 10 | config-optional-sections-documented | T4 | Config-reader drift | P3 | ~45 |
| 11 | pipeline-feature-agents-present | T2 | Missing agent dispatch | P2 | ~45 |
| 12 | xref-skip-stage-names | T1 | Stage name drift | P2 | ~55 |
