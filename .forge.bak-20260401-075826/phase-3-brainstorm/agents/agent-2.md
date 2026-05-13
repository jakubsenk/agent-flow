# E2E Test Harness Strategy: The Innovative Coverage Engineer

**Author:** Claude Opus 4.6 (1M context) -- The Innovative Coverage Engineer
**Date:** 2026-03-31
**Status:** PROPOSAL
**Guiding principle:** "Every undocumented invariant is a bug waiting to happen."

---

## Strategy Overview

The current test suite of 25 scenarios is almost entirely focused on the bug-fix pipeline and scaffold pipeline, with zero coverage of the feature pipeline, zero coverage of the deployment verifier, and several structural integrity gaps (hardcoded agent lists missing deployment-verifier, core file list missing mcp-detection, state.json validation limited to field-existence checks). The existing tests are well-structured but fragile to growth -- they enumerate agents and core files as hardcoded arrays rather than deriving them from the source of truth.

This proposal introduces a **cross-reference graph validation** approach: instead of testing individual files in isolation, we build a validation graph where commands reference agents, agents declare models, commands reference core contracts, and the state schema declares sections. Then we walk the graph edges and assert that every reference resolves, every declaration is consistent, and every pipeline step has structural coverage. This eliminates the hardcoded-list problem entirely -- new agents, commands, or core files automatically participate in validation because the graph is built dynamically from the filesystem and file contents.

The taxonomy splits tests into four tiers: **T1-structural** (file existence, frontmatter, section order -- the current 25 tests), **T2-contract** (cross-reference integrity, config contract enforcement, state schema field coverage), **T3-pipeline** (step ordering, agent dispatch consistency, pipeline flow completeness), and **T4-regression** (version-specific guards that catch accidental deletions). New scenarios are designed to be property-based where possible: "every agent referenced by a command must exist as a file" rather than "these 18 specific agents must exist." This means the test suite grows with the codebase automatically.

---

## 1. Test Taxonomy

### Tier 1: Structural (existing 25 tests -- keep unchanged)
File existence, frontmatter fields, section ordering, model assignments. These are the foundation. No changes.

### Tier 2: Contract Validation (new)
Cross-reference integrity between commands, agents, core, and state schema. Config contract enforcement. These catch drift between layers.

### Tier 3: Pipeline Flow (new)
Step ordering within commands, agent dispatch model consistency, pipeline completeness (every declared pipeline has all its steps covered). Feature pipeline and deployment pipeline go here.

### Tier 4: Regression Guards (new)
Version-specific assertions that prevent accidental content removal. The existing scaffold-v561-regression.sh is a T4 test. New guards for known-fragile invariants.

### Naming Convention

```
tests/scenarios/
  # T1 (existing, no rename needed -- grandfathered)
  happy-path.sh
  frontmatter-completeness.sh
  ...

  # T2
  t2-xref-agent-dispatch.sh
  t2-xref-core-completeness.sh
  t2-config-contract-required.sh
  t2-config-contract-optional.sh
  t2-state-schema-field-coverage.sh

  # T3
  t3-bugfix-pipeline-ordering.sh
  t3-feature-pipeline-ordering.sh
  t3-feature-pipeline-completeness.sh
  t3-deploy-pipeline-completeness.sh
  t3-scaffold-pipeline-ordering.sh

  # T4
  t4-deployment-verifier-presence.sh
  t4-agent-model-consistency.sh
```

The `t{N}-` prefix gives immediate sorting and makes the tier visible in `ls` output. Existing tests keep their names (no rename disruption).

---

## 2. Scenario Granularity

**Principle: one scenario = one invariant class, multiple assertions per class.**

Bad: one scenario for "does deployment-verifier exist" (too narrow, will need 19 such tests).
Bad: one scenario for "entire feature pipeline works" (too broad, failure message is useless).
Good: one scenario for "every agent dispatched by implement-feature.md exists, has correct model, and is referenced with the right model in the dispatch call" (one invariant class -- agent dispatch consistency -- with 8-10 assertions).

Each scenario tests a single property across all relevant files. This is property-based structural testing: the property is stated once, and every file that should satisfy it is checked.

---

## 3. Pipeline Step Ordering Validation

### Approach: Extract step numbers and verify monotonic ordering

For each pipeline command (fix-ticket, fix-bugs, implement-feature, scaffold), extract all step references (e.g., `### Step 0b`, `### 3.`, `#### 6a.`) and verify they appear in the correct order in the file. This catches accidental step reordering during edits.

**Implementation pattern:**
```bash
# Extract step headings in file order, assign numeric sort keys
# Step 0 < Step 0b < Step 1 < Step 2 < ... < Step 6a < Step 6b < ... < Step X
# Verify the extracted sequence is monotonically non-decreasing
```

For the feature pipeline specifically, verify the canonical ordering:
```
0 (MCP) -> 0b (config validity) -> 0c (description) -> 1 (set state) -> 2 (branch)
  -> 3 (spec-analyst) -> 4 (architect) -> 5 (decomposition) -> 6 (execution)
  -> 6a..6h (sub-steps) -> 7 (integration) -> 8 (pre-publish) -> 9 (display)
  -> 10 (publisher) -> 10a (post-publish) -> 10b (verification) -> X (block handler)
```

For the bug-fix pipeline, verify:
```
0 (MCP) -> 0b (config validity) -> 1 (dry-run) -> 2 (set state) -> 3 (triage)
  -> 4 (code-analyst) -> 4e (reproducer) -> 5 (decomposition) -> 6 (fixer-reviewer)
  -> 7 (test) -> 7a (e2e) -> 7a-browser (browser) -> 8 (acceptance gate)
  -> 9 (pre-publish) -> 10 (display) -> 11 (publisher) -> 11a (post-publish)
  -> 11b (verification) -> X (block handler)
```

---

## 4. Agent Dispatch Consistency Validation

### The problem

Commands dispatch agents with `(Task tool, model: {model})`. The model in the dispatch call must match the model declared in the agent's frontmatter. Currently, nothing validates this cross-reference -- a command could dispatch `ceos-agents:fixer` with `model: sonnet` while `agents/fixer.md` declares `model: opus`.

### The solution

For each pipeline command, extract all agent dispatch patterns:
```
grep -oP '(ceos-agents:)?(\w[-\w]+)\s*\(Task tool,\s*model:\s*(\w+)\)' commands/{cmd}.md
```

For each extracted `(agent_name, model)` pair:
1. Verify `agents/{agent_name}.md` exists
2. Verify the frontmatter `model:` field matches the dispatched model
3. Verify the agent is not dispatched with two different models across different commands

This is the single highest-value new test because it catches a class of bug that is invisible during manual review: model mismatch between caller and callee.

### Dynamic agent list derivation

Instead of hardcoding agent lists, derive the canonical list from the filesystem:

```bash
CANONICAL_AGENTS=$(ls "$REPO_ROOT/agents/"*.md | xargs -I{} basename {} .md | sort)
CANONICAL_COUNT=$(echo "$CANONICAL_AGENTS" | wc -l)
```

Then verify that every test referencing "all agents" uses a list that matches `$CANONICAL_AGENTS`. This eliminates the deployment-verifier-missing-from-hardcoded-lists bug permanently.

---

## 5. State.json Write Completeness

### The problem

The current `state-schema.sh` checks that pipeline commands mention `state.json` at least N times, but does not verify that every state section declared in `state/schema.md` is actually written to by at least one command.

### The solution: Schema-driven field coverage

1. Extract all top-level sections from `state/schema.md` schema example (triage, code_analysis, reproduction, fixer_reviewer, decomposition, test, e2e_test, browser_verification, acceptance_gate, publisher, hooks, block, deployment)
2. For each section, verify that at least one pipeline command writes to it (grep for `{section}.status` or `{section}.` in commands/)
3. For the `deployment` section specifically, verify that `check-deploy.md` writes to it

Additionally, verify field-level completeness for critical sections:
- `fixer_reviewer` must write: `iterations`, `max_iterations`, `last_verdict`, `ac_fulfillment`
- `publisher` must write: `pr_url`, `branch`
- `triage` must write: `severity`, `area`, `complexity`, `acceptance_criteria`

This catches the case where a state section exists in the schema but no command ever populates it.

---

## 6. Cross-Reference Integrity

### The cross-reference graph

```
CLAUDE.md (agent table) --> agents/*.md (must exist, model must match)
commands/*.md (dispatch calls) --> agents/*.md (must exist, model must match)
commands/*.md (core/ references) --> core/*.md (must exist)
core/*.md (Referenced by: lines) --> commands/*.md (must reference back)
state/schema.md (sections) --> commands/*.md (must write to them)
skills/workflow-router/SKILL.md (command references) --> commands/*.md (must exist)
CLAUDE.md (command list) --> commands/*.md (must exist)
CLAUDE.md (config contract) --> core/config-reader.md (keys must match)
```

### Implementation: Build and walk the graph

```bash
# 1. Extract all agent names referenced in CLAUDE.md agent table
# 2. For each, verify agents/{name}.md exists
# 3. Extract all command names referenced in CLAUDE.md command list
# 4. For each, verify commands/{name}.md exists
# 5. Extract all agent dispatch calls from all commands
# 6. For each, verify agent exists and model matches
# 7. Extract all core/ references from all commands
# 8. For each, verify core/{name}.md exists
# 9. Extract all "Referenced by:" lines from core files
# 10. For each, verify the referencing command actually references the core file
# 11. Extract all command names from workflow-router intent table
# 12. For each, verify commands/{name}.md exists
```

This is the most comprehensive single test in the suite. It catches:
- Typos in agent names in commands
- Stale references to deleted core files
- Workflow router referencing nonexistent commands
- CLAUDE.md claiming N agents/commands but having M files

---

## 7. Config Contract Enforcement

### The problem

CLAUDE.md declares a config contract with required and optional sections. `core/config-reader.md` parses these sections. But nothing verifies that:
1. Every required section listed in CLAUDE.md is also listed in `core/config-reader.md`
2. Every optional section listed in CLAUDE.md has a default in `core/config-reader.md`
3. The mock project's `CLAUDE.md` exercises all required sections

### The solution

**Test A: Required section coverage**
- Extract required section names from CLAUDE.md config contract table
- Verify each appears in `core/config-reader.md` under "required sections"
- Verify each appears in the mock project's `tests/mock-project/CLAUDE.md`

**Test B: Optional section default coverage**
- Extract optional section names from CLAUDE.md config contract table
- Verify each appears in `core/config-reader.md` under "optional sections"
- Verify each has a `(default: ...)` annotation

**Test C: Key consistency**
- For each required section, extract the key names from CLAUDE.md
- Verify the same key names appear in `core/config-reader.md`'s parsing logic

---

## 8. Mock Project Strategy

### Current mock project

`tests/mock-project/CLAUDE.md` has a valid Automation Config with required sections and some optional ones (Retry Limits, Hooks, Worktrees, Feature Workflow, Decomposition, Pipeline Profiles, Metrics). It is missing: Browser Verification, E2E Test, Local Deployment, Error Handling, Extra labels, Agent Overrides, Custom Agents, Notifications, Module Docs.

### Recommendation: Two mock projects

**Mock Project A: `tests/mock-project/` (keep as-is)**
- Represents a "typical" project with common optional sections
- Used by existing tests and new T2/T3 tests for standard path validation

**Mock Project B: `tests/mock-project-full/`**
- Has ALL optional sections filled in (every optional config section from CLAUDE.md)
- Includes a `customization/` directory with at least one agent override file
- Has `### Local Deployment` section (for deployment tests)
- Has `### Browser Verification` section (for browser-related tests)
- Has `### E2E Test` section
- Used by new T3 deployment and browser tests

**Mock Project C: `tests/mock-project-minimal/`**
- Has ONLY required sections (no optional sections at all)
- Used to validate that default fallbacks work correctly
- Tests that commands referencing optional sections do not crash when absent

### Additional fixture: `tests/harness/fixtures/state-examples/`

Create example state.json files for different pipeline states:
- `state-bugfix-completed.json` -- full bugfix pipeline with all sections populated
- `state-feature-completed.json` -- full feature pipeline
- `state-deploy-healthy.json` -- deployment verification result
- `state-blocked.json` -- pipeline blocked by fixer

These fixtures are used by state-schema tests to validate field coverage against real examples.

---

## 9. Regression Guard Strategy

### Approach: Canary assertions + golden file hashes

**Canary assertions** are simple grep checks for critical content that has been accidentally deleted in the past. The existing `scaffold-v561-regression.sh` is an example. Extend this pattern to other commands.

**Regression guards for known-fragile content:**

| Guard | File | What it protects |
|-------|------|-----------------|
| deployment-verifier agent existence | agents/deployment-verifier.md | 19th agent added in v5.3.0, missing from hardcoded lists |
| mcp-detection core file | core/mcp-detection.md | 11th core file, missing from core-include-refs.sh |
| Feature pipeline AC coverage check | commands/implement-feature.md | Step 5 maps_to validation |
| acceptance-gate always-runs-for-features | commands/implement-feature.md | Step 6g has no threshold condition |
| publisher never-push-to-main | agents/publisher.md | Safety-critical constraint |
| rollback-agent invocation after block | commands/fix-ticket.md, fix-bugs.md, implement-feature.md | Must not lose rollback on refactor |
| 19 agent count | agents/ directory | Prevent silent agent deletion |
| 25 command count | commands/ directory | Prevent silent command deletion |
| 11 core file count | core/ directory | Prevent silent core deletion |

**Golden section hashes** (advanced, optional):
For critical file sections (e.g., the Constraints section of fixer.md), compute a checksum. When the section changes, the test fails with a message asking the developer to verify the change was intentional and update the golden hash. This is heavy-handed but protects safety-critical constraints from silent erosion.

---

## 10. Feature Pipeline + Deployment Coverage

### Feature pipeline tests (zero coverage today)

**Scenario: t3-feature-pipeline-completeness.sh**
Verify that `commands/implement-feature.md` contains all required pipeline steps and agent dispatches for the feature flow:

1. spec-analyst dispatch (sonnet)
2. architect dispatch (opus)
3. AC coverage check (maps_to validation)
4. fixer dispatch (opus)
5. reviewer dispatch (opus)
6. test-engineer dispatch (sonnet)
7. acceptance-gate dispatch (sonnet) -- always for features
8. publisher dispatch (haiku)
9. rollback-agent reference
10. Block handler section
11. State.json writes for: triage (reused for spec-analyst), code_analysis (reused for architect), fixer_reviewer, decomposition, test, acceptance_gate, publisher
12. Feature Verification step
13. Post-publish hook reference
14. --description flag support
15. --decompose / --no-decompose support
16. Config Validity Gate (Step 0b)

**Scenario: t3-feature-pipeline-ordering.sh**
Verify step ordering within implement-feature.md (see section 3 above).

**Scenario: t3-feature-config-contract.sh**
Verify that implement-feature.md references all required config sections and the Feature Workflow optional section.

### Deployment tests (zero coverage today)

**Scenario: t3-deploy-pipeline-completeness.sh**
Verify that:
1. `agents/deployment-verifier.md` exists with correct frontmatter (model: sonnet)
2. `commands/check-deploy.md` exists and dispatches deployment-verifier
3. deployment-verifier has all 5 verdicts: HEALTHY, UNHEALTHY, PORT_CONFLICT, START_FAILED, SKIPPED
4. check-deploy.md supports --start, --stop flags
5. check-deploy.md has port validation (1-65535 range check)
6. check-deploy.md writes to state.json deployment section
7. deployment-verifier has cleanup-on-failure logic
8. CLAUDE.md lists Local Deployment as an optional config section

**Scenario: t4-deployment-verifier-presence.sh**
Regression guard: deployment-verifier must exist in agents/, be listed in CLAUDE.md agent table, and have model: sonnet.

---

## Specific Scenario Designs (12 scenarios)

### Scenario 1: `t2-xref-agent-dispatch.sh`
**Purpose:** Validate that every agent dispatched by a command exists and has the correct model.
**Key assertions:**
- Extract all `(Task tool, model: {X})` patterns from all commands/*.md
- For each, verify agents/{agent}.md exists
- For each, verify frontmatter `model: {X}` matches the dispatch model
- Verify no agent is dispatched with conflicting models across commands
- Dynamic: no hardcoded agent list -- reads from filesystem + command files
**Estimated lines:** 60-80

### Scenario 2: `t2-xref-core-completeness.sh`
**Purpose:** Validate that every core/*.md file is referenced by at least one command, and every core/ reference in a command resolves to an existing file.
**Key assertions:**
- Build canonical core list from `ls core/*.md`
- For each core file, verify at least one command references `core/{name}.md`
- For each `core/` reference in commands, verify the file exists
- Verify core file count matches CLAUDE.md's "11 core contracts" claim
- Check `mcp-detection.md` is included (the known gap)
**Estimated lines:** 45-55

### Scenario 3: `t2-state-schema-field-coverage.sh`
**Purpose:** Validate that every state.json section declared in the schema is written to by at least one command.
**Key assertions:**
- Extract top-level section names from state/schema.md (triage, code_analysis, reproduction, fixer_reviewer, decomposition, test, e2e_test, browser_verification, acceptance_gate, publisher, hooks, block, deployment)
- For each section, verify at least one file in commands/ references `{section}.status` or `{section}.`
- For `deployment`, verify check-deploy.md writes deployment fields
- For `fixer_reviewer`, verify that `iterations`, `last_verdict`, `ac_fulfillment` are written
- For `publisher`, verify `pr_url` and `branch` are written
**Estimated lines:** 70-90

### Scenario 4: `t3-feature-pipeline-completeness.sh`
**Purpose:** Validate that implement-feature.md contains all required pipeline steps for the feature flow.
**Key assertions:**
- spec-analyst, architect, fixer, reviewer, test-engineer, acceptance-gate, publisher dispatched
- Each dispatch uses the correct model per CLAUDE.md table
- AC coverage check step exists (maps_to validation logic)
- Decomposition step exists with FORCE/DISABLED/AUTO modes
- Feature Verification step exists
- --description flag documented
- Config Validity Gate (Step 0b) present
- Block handler (Step X) present with rollback-agent
- State.json writes for all relevant sections
**Estimated lines:** 80-100

### Scenario 5: `t3-feature-pipeline-ordering.sh`
**Purpose:** Validate step ordering within implement-feature.md.
**Key assertions:**
- Step 0 (MCP) appears before Step 0b (config validity)
- Step 0b appears before Step 0c (description)
- Step 3 (spec-analyst) appears before Step 4 (architect)
- Step 4 (architect) appears before Step 5 (decomposition)
- Step 5 appears before Step 6 (execution)
- Step 6 appears before Step 7 (integration)
- Step 10 (publisher) appears after Step 9 (display)
- Step X (block handler) appears last
**Estimated lines:** 50-65

### Scenario 6: `t3-deploy-pipeline-completeness.sh`
**Purpose:** Validate deployment verification pipeline coverage.
**Key assertions:**
- agents/deployment-verifier.md exists, model: sonnet
- commands/check-deploy.md dispatches deployment-verifier via Task tool
- All 5 verdicts present in deployment-verifier.md (HEALTHY, UNHEALTHY, PORT_CONFLICT, START_FAILED, SKIPPED)
- check-deploy.md supports --start, --stop, neither (check-only)
- Port validation (range 1-65535) present
- State.json deployment section written by check-deploy.md
- Cleanup-on-failure logic present in deployment-verifier.md
- Local Deployment section documented in CLAUDE.md config contract
- check-deploy.md references core/config-reader.md and core/state-manager.md
**Estimated lines:** 70-85

### Scenario 7: `t2-config-contract-required.sh`
**Purpose:** Validate that CLAUDE.md required config sections are enforced by core/config-reader.md.
**Key assertions:**
- Extract required section names from CLAUDE.md: Issue Tracker, Source Control, PR Rules, PR Description Template, Build & Test
- Each appears in core/config-reader.md "required sections" parsing
- Each appears in tests/mock-project/CLAUDE.md
- config-reader.md has a validation step for required sections
- config-reader.md has a BLOCK on missing required section
**Estimated lines:** 45-55

### Scenario 8: `t2-xref-workflow-router.sh`
**Purpose:** Validate that every command referenced in the workflow-router intent table exists.
**Key assertions:**
- Extract all `ceos-agents:{command}` references from skills/workflow-router/SKILL.md
- For each, verify commands/{command}.md exists
- Verify the router covers all 25 commands (or at least all user-facing ones)
- Verify destructive/non-destructive classification matches command behavior
- Count intent rows and verify >= 31 (per CLAUDE.md)
**Estimated lines:** 50-60

### Scenario 9: `t2-agent-canonical-count.sh`
**Purpose:** Dynamic agent count validation that replaces hardcoded lists.
**Key assertions:**
- Count agents from filesystem: `ls agents/*.md | wc -l`
- Verify count matches CLAUDE.md's "19 agents" claim
- Verify every agent file has all 4 frontmatter fields
- Verify every agent has Goal/Expertise/Process/Constraints sections
- Verify CLAUDE.md model assignment table covers every agent file
- This is a single-source-of-truth test: filesystem is truth, CLAUDE.md must match
**Estimated lines:** 55-70

### Scenario 10: `t3-bugfix-pipeline-ordering.sh`
**Purpose:** Validate step ordering within fix-ticket.md (the primary bugfix pipeline).
**Key assertions:**
- MCP pre-flight before Step 0b (config validity gate)
- Triage before code-analyst
- Code-analyst before reproducer (optional)
- Code-analyst before fixer
- Fixer before reviewer
- Test-engineer after reviewer
- Browser-verifier after test-engineer (optional)
- Acceptance gate after test-engineer
- Publisher after acceptance gate
- Block handler (Step X) present
**Estimated lines:** 50-65

### Scenario 11: `t4-safety-constraints.sh`
**Purpose:** Regression guard for safety-critical constraints across agents and commands.
**Key assertions:**
- publisher.md: "NEVER push to main" or equivalent
- fixer.md: diff limit (100 lines)
- code-analyst.md: max 5 affected files
- reviewer.md: APPROVE / REQUEST_CHANGES output
- rollback-agent.md referenced in all 3 pipeline commands (fix-ticket, fix-bugs, implement-feature)
- acceptance-gate.md: "always for features" in implement-feature.md (no threshold)
- fixer.md: NEEDS_DECOMPOSITION signal (max 1 per ticket)
- decomposition-heuristics.md: max_subtasks check
**Estimated lines:** 60-75

### Scenario 12: `t2-state-schema-deployment.sh`
**Purpose:** Validate the deployment section in state schema is complete and consistent.
**Key assertions:**
- state/schema.md contains "deployment" section
- All deployment fields documented: status, verdict, type, health_check, ports, started_at, verified_at, result_path
- Verdict enum values match deployment-verifier.md verdicts
- check-deploy.md references all deployment state fields
- Deployment Object Fields table exists in schema.md
**Estimated lines:** 45-55

---

## Mock Project Recommendation

### Primary recommendation: Add `tests/mock-project-full/`

Create a second mock project that exercises ALL optional config sections. This mock project does not need to be a real project -- it needs a `CLAUDE.md` with every optional section filled in (including Local Deployment, Browser Verification, E2E Test, Error Handling, Extra labels, Agent Overrides, Custom Agents, Notifications, Module Docs).

**Structure:**
```
tests/mock-project-full/
  CLAUDE.md               # All required + all optional sections
  customization/
    reviewer.md           # Sample agent override
  app.py                  # Placeholder
```

**What it enables:**
- T2 config contract tests can verify that the full mock exercises every declared section
- T3 deployment tests can validate against a project with Local Deployment config
- Future tests for Browser Verification, E2E Test, etc.

### Secondary recommendation: Add `tests/mock-project-minimal/`

A bare-minimum project with ONLY required config sections. This validates that optional section defaults work correctly and no command crashes on missing optional config.

**Structure:**
```
tests/mock-project-minimal/
  CLAUDE.md               # Only required sections
```

### Fixture recommendation: `tests/harness/fixtures/state-examples/`

Add 3-4 example state.json files representing different completed pipeline states. These are used by state schema tests to validate field coverage.

---

## Regression Guard Approach

### Three-layer regression defense

**Layer 1: Count guards**
- Assert exact counts for agents (19), commands (25), core files (11), skills (1)
- When a new agent/command is added, the test fails until the count is updated
- This prevents silent deletion -- you cannot remove a file without updating the count

**Layer 2: Name guards (dynamic)**
- Instead of hardcoded name lists, derive canonical names from the filesystem
- Cross-reference against CLAUDE.md declarations
- A deleted agent that is still referenced in CLAUDE.md fails immediately

**Layer 3: Content canaries**
- Grep for specific safety-critical strings that must not be removed
- Examples: "NEVER push to main" in publisher.md, "100 lines" in fixer.md, "NEEDS_DECOMPOSITION" in fixer.md
- When a canary string is accidentally deleted during editing, the test catches it immediately

### Version-bump integration

The existing test harness runs before every commit (per user's release process). The regression guards should run as part of the standard suite -- no special invocation needed. The `run-tests.sh` harness already runs all `*.sh` files in `scenarios/`, so new tests auto-discover.

---

## Integration with Existing Harness

### No changes to run-tests.sh

New scenario files are dropped into `tests/scenarios/` with the `t{N}-` prefix. The harness discovers them automatically.

### Execution order

The harness runs scenarios in alphabetical order. The `t2-*`, `t3-*`, `t4-*` prefixes naturally sort after the existing unprefixed scenarios. This means:
1. Existing 25 tests run first (quick sanity)
2. T2 contract tests run next (cross-references)
3. T3 pipeline tests run next (flow validation)
4. T4 regression guards run last (safety nets)

### Shared helpers

Several scenarios share common logic (extract frontmatter, count agents, find core files). To avoid duplication, create:

```
tests/harness/helpers.sh
```

With functions:
- `get_canonical_agents()` -- lists all agent basenames from filesystem
- `get_canonical_commands()` -- lists all command basenames
- `get_canonical_cores()` -- lists all core file basenames
- `get_agent_model(agent_name)` -- extracts model from frontmatter
- `get_step_line(file, step_pattern)` -- returns line number of a step heading
- `assert_file_exists(path, msg)` -- standard file existence check
- `assert_grep(file, pattern, msg)` -- standard grep assertion

Each scenario sources helpers: `. "$SCRIPT_DIR/../harness/helpers.sh"`

---

## Pros/Cons Self-Assessment

### Strengths

| Strength | Impact |
|----------|--------|
| Dynamic agent/core lists from filesystem | Eliminates the deployment-verifier and mcp-detection hardcoded-list bugs permanently. No more manual list updates when agents are added. |
| Cross-reference graph validation | Catches an entire class of drift bugs (command references nonexistent agent, router references nonexistent command) that no individual file test can detect. |
| Feature pipeline coverage from zero to comprehensive | The feature pipeline is 50% of the plugin's value and currently has zero test coverage. Three new scenarios cover it. |
| Deployment verifier coverage from zero to complete | check-deploy and deployment-verifier are the newest features and have no tests at all. Two new scenarios cover both. |
| Property-based over enumeration-based | Tests describe invariants ("every dispatched agent must have matching model") rather than enumerating instances ("fixer must be opus"). This scales to 50 agents without test changes. |
| State schema field-level validation | Upgrades from "does state.json get referenced 5 times?" to "does every declared schema section get written to by a command?" |
| Mock project strategy with three tiers | Covers full-config, standard-config, and minimal-config paths without modifying existing tests. |

### Weaknesses

| Weakness | Mitigation |
|----------|------------|
| Regex-based extraction is fragile | Agent dispatch patterns follow a consistent format (`Task tool, model: X`). If the format changes, the regex breaks. Mitigation: document the expected format in helpers.sh; a single regex update fixes all scenarios. |
| No runtime validation | These tests cannot verify that an agent actually produces correct output. They can only verify structural consistency. Mitigation: this is by design -- structural tests catch 80% of real bugs (missing files, wrong models, broken references) at 0% runtime cost. |
| Step ordering tests assume heading format | If step headings change format (e.g., from `### Step 3` to `### Phase 3`), ordering tests break. Mitigation: use loose patterns (`Step\s*3\|Phase\s*3\|3\.`) and document the heading convention. |
| 12 new scenarios add ~750 lines | Test suite grows from ~25 files to ~37 files. Mitigation: the t-prefix organization and shared helpers keep it manageable. Each scenario is independent and self-documenting. |
| Mock project maintenance | Three mock projects must be kept in sync with config changes. Mitigation: the `t2-config-contract-required.sh` test itself validates mock project coverage -- if a required section is added and the mock is not updated, the test fails. |
| Does not test the skill routing layer deeply | The workflow-router test checks command existence but not argument extraction or destructive classification accuracy. Mitigation: the routing layer is a thin mapping table -- structural existence checks catch the highest-risk bugs (typos in command names). |

### What this strategy deliberately does NOT do

1. **No runtime mocking.** These tests never execute commands or agents. They validate structure only.
2. **No test output format standardization.** Existing tests use mixed PASS/FAIL output formats. Standardization would require modifying existing tests, which violates the constraint.
3. **No CI-specific changes.** The tests run the same way locally and in CI (if CI is added later).
4. **No coverage percentage tracking.** There is no "coverage tool" for markdown structural testing. Instead, the cross-reference graph implicitly tracks coverage: if every command's every agent dispatch is validated, that is 100% agent-dispatch coverage by construction.

---

## Implementation Priority

| Priority | Scenario | Why first |
|----------|----------|-----------|
| 1 | `t2-xref-agent-dispatch.sh` | Highest value: catches model mismatches and missing agents. Subsumes the hardcoded-list problem. |
| 2 | `t3-feature-pipeline-completeness.sh` | Largest coverage gap: feature pipeline has zero tests today. |
| 3 | `t2-xref-core-completeness.sh` | Catches the mcp-detection gap and prevents future core file drift. |
| 4 | `t3-deploy-pipeline-completeness.sh` | Second largest gap: deployment pipeline has zero tests. |
| 5 | `t2-state-schema-field-coverage.sh` | Upgrades state.json testing from count-based to field-based. |
| 6 | `t3-feature-pipeline-ordering.sh` | Step ordering is a common source of editing bugs. |
| 7 | `t2-xref-workflow-router.sh` | Validates the routing layer that users interact with most. |
| 8-12 | Remaining scenarios | Fill out the matrix: bugfix ordering, config contract, safety constraints, deployment state, agent counts. |

Total estimated effort: ~800 lines of bash across 12 scenarios + ~80 lines of helpers.sh + ~2 mock project CLAUDe.md files (~100 lines each). Approximately 1100 lines total.
