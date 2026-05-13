# E2E Test Harness Strategy: The Conservative Test Architect

**Author:** Claude Opus 4.6 (1M context) -- Conservative Test Architect persona
**Date:** 2026-03-31
**Status:** PROPOSAL

---

## Strategy Overview

The existing 25 test scenarios have earned their keep. They are fast, stable, and they catch real contract violations. The proposal here respects that lineage. Rather than introducing framework machinery or clever abstractions, this strategy extends the suite with the same proven patterns -- bash scripts, grep/awk assertions, explicit fail messages, exit codes -- organized into a two-tier taxonomy that separates stable structural invariants from pipeline-specific contract tests. The goal is 12-15 new scenarios that close the confirmed P1 and P2 gaps with zero impact on the existing 25 tests.

The strategy is built on one fundamental observation: in a pure-markdown plugin, the only meaningful "end-to-end" validation is cross-file contract tracing -- verifying that when command A says "dispatch agent X with model Y," agent X actually exists with model Y, and when command A says "write state.json field Z," field Z is documented in the schema. These structural invariants are the backbone of the plugin's correctness, and they can be validated exhaustively and cheaply with grep. The strategy deliberately avoids simulating pipeline execution (there is no runtime to execute against) and instead treats each command's markdown as a specification document whose structural claims can be verified against source-of-truth files.

The false-positive tax is the single biggest risk in any test expansion. Every scenario proposed below includes an explicit "Breaks when..." assessment. If a test would break on a legitimate rename or reordering, the assertion is designed around semantic anchors (section headings, YAML frontmatter keys, state field names) rather than line numbers or exact prose. Where ambiguity exists, the test uses a pattern broad enough to survive cosmetic changes but narrow enough to catch actual contract violations.

---

## Point 1: Test Taxonomy

### Organization Scheme: Two-Tier, Four Categories

**Tier 1 -- Structural Invariants** (should never break on pipeline logic changes):
- `structural-*` -- file existence, counts, frontmatter, section order, model assignments
- Examples: existing `happy-path.sh`, `frontmatter-completeness.sh`, `model-assignment.sh`, `section-order.sh`

**Tier 2 -- Contract Tests** (may need updates when pipeline logic changes):
- `pipeline-*` -- step ordering, agent dispatch, state writes within specific pipelines
- `contract-*` -- cross-file reference integrity, config contract compliance, core contract adherence
- `feature-*` -- pipeline-specific scenarios (feature, deployment, scaffold -- existing scaffold-* stay as-is)

### Naming Convention

```
{tier-prefix}-{scope}.sh
```

Where `tier-prefix` is one of: `structural`, `pipeline`, `contract`, `feature`.
Where `scope` is a kebab-case descriptor: e.g., `agent-completeness`, `bugfix-step-order`, `config-defaults`.

Existing 25 tests keep their current names. No renames. New tests follow the new convention. Over time, this creates a natural partition where `structural-*` tests are the low-maintenance bedrock and `contract-*`/`pipeline-*` tests are the ones engineers expect to update after pipeline changes.

### Why This Taxonomy

The key insight is maintenance cost prediction. A test named `structural-agent-completeness.sh` signals to the developer: "if this fails, you probably forgot to update a list." A test named `pipeline-feature-step-order.sh` signals: "if this fails, you changed the pipeline flow -- verify intentionality." This is not cosmetic; it directly reduces the time spent diagnosing failures.

---

## Point 2: Scenario Granularity

### Recommendation: One Property Per Scenario, With Targeted Exceptions

The existing suite already follows a one-property-per-scenario pattern, and it works well. The `pipeline-consistency.sh` test is the only exception -- it checks 5 properties across all pipeline commands -- and it earns this by testing properties that are genuinely co-dependent (block format + rollback context are always used together).

For new scenarios, the rule is: **one property per scenario unless the properties are so tightly coupled that testing them separately would require duplicating 80%+ of the setup logic.**

Concrete application:
- Pipeline step ordering for fix-ticket, fix-bugs, and implement-feature: **three separate scenarios** (`pipeline-bugfix-step-order.sh`, `pipeline-batchfix-step-order.sh`, `pipeline-feature-step-order.sh`). Each pipeline has different steps, different skip logic, different stage mappings. A combined test would be fragile and opaque.
- Agent dispatch consistency across pipelines: **one combined scenario** (`contract-agent-dispatch.sh`). The property is "same agent, same model, everywhere" -- intrinsically cross-pipeline. Splitting by pipeline would miss the cross-reference dimension.
- State.json write completeness: **per-pipeline scenarios** (`pipeline-bugfix-state-writes.sh`, `pipeline-feature-state-writes.sh`). Each pipeline writes different state fields. A combined test would conflate distinct contracts.

### Why Not Full Pipeline Flow Scenarios?

A "full pipeline flow" scenario for fix-ticket would need to verify: MCP preflight -> config validity gate -> triage -> code-analyst -> reproducer -> fixer -> reviewer -> test-engineer -> e2e -> browser-verifier -> acceptance-gate -> publisher. This is 12+ assertions in sequence. When assertion #8 fails, the developer has to read 100+ lines of test code to find the relevant grep. Worse, any single step rename breaks the entire scenario.

The proposed granularity keeps individual scenarios under 80 lines and under 12 assertions, making failures immediately diagnosable.

---

## Point 3: Pipeline Step Ordering Validation

### Design: Line-Number Comparison of Step Headings

The approach extracts line numbers of step headings from each pipeline command and verifies monotonic ordering. This is the same technique already proven in `scaffold-v2-happy-path.sh` (lines 133-138) where it verifies "Infrastructure Declaration appears before Mode Selection."

**Key insight:** Step headings use a consistent `### Step N:` or `### N.` format in all three pipeline commands. Extract line numbers with `grep -n`, compare numerically.

### Scenario: `pipeline-bugfix-step-order.sh`

Validates fix-ticket.md step ordering:
1. Extract line numbers for: MCP pre-flight, Config Validity Gate, Triage, Code-analyst, Decompose, Pre-fix hook, Browser Reproduction, Fixer, Reviewer, Test-engineer, E2E, Browser Verification, Acceptance gate, Pre-publish hook, Publisher, Fix Verification
2. Assert each line number < next line number
3. Use semantic anchors: grep for "MCP pre-flight", "Config Validity Gate", "Triage", "Code-analyst", etc.

**Breaks when:** Steps are renumbered (harmless -- test uses heading text, not numbers) or step headings are renamed (intentional contract change -- test SHOULD break).

**Does NOT break when:** Step body content is edited, new sub-steps are added between existing steps, or prose around steps changes.

### Scenario: `pipeline-feature-step-order.sh`

Same approach for implement-feature.md. Different step sequence:
MCP pre-flight -> Config Validity Gate -> Feature from Description -> Set issue state -> Create branch -> Spec-analyst -> Architect -> Decomposition decision -> Subtask execution -> Publisher

### Scenario: `pipeline-batchfix-step-order.sh`

For fix-bugs.md. Simpler ordering: MCP pre-flight -> Query bugs -> Per-bug loop (Triage -> Code-analyst -> Fixer -> Reviewer -> Test-engineer -> Publisher).

---

## Point 4: Agent Dispatch Consistency Validation

### Design: Cross-Pipeline Agent-Model-Context Matrix

For each agent dispatched across multiple pipelines, verify:
1. Agent name matches an actual file in `agents/`
2. Model specified in the dispatch matches the agent's frontmatter
3. Agent name uses `ceos-agents:` namespace prefix consistently

### Scenario: `contract-agent-dispatch.sh`

```
Purpose: Verify agent dispatch consistency across all pipeline commands
```

Key assertions:
1. **Agent existence:** For every `ceos-agents:{agent-name}` reference in `commands/*.md`, verify `agents/{agent-name}.md` exists.
2. **Model consistency:** Where commands specify "Task tool, model: {model}", extract agent name and model, verify against frontmatter `model:` field in the agent file.
3. **Namespace prefix:** Every agent dispatch in pipeline commands (`fix-ticket.md`, `fix-bugs.md`, `implement-feature.md`, `scaffold.md`) uses `ceos-agents:` prefix. No bare agent names in Task tool calls.

Implementation approach:
```bash
# Extract dispatch patterns: "ceos-agents:{name}" from commands
# For each match, verify agents/{name}.md exists
# Extract "model: {x}" from dispatch context, verify against frontmatter
```

**Breaks when:** A new agent is added to the pipeline but not to the agents/ directory (real bug -- SHOULD break) or when a dispatch line's model annotation is changed without updating the agent frontmatter (real bug -- SHOULD break).

**Does NOT break when:** Agent prompt content is edited, new agents are added that are not dispatched from commands, or command prose around dispatches changes.

---

## Point 5: State.json Write Completeness

### Design: Schema-Anchored Field Presence Checks

For each pipeline command, verify that every phase documented in `state/schema.md` with status `"pending"` default has a corresponding "Update `state.json`" instruction that references the specific field name.

### Scenario: `pipeline-bugfix-state-writes.sh`

Validates fix-ticket.md writes all required state fields:
1. Extract the list of state sections from schema: `triage`, `code_analysis`, `reproduction`, `fixer_reviewer`, `decomposition`, `test`, `e2e_test`, `browser_verification`, `acceptance_gate`, `publisher`
2. For each section, verify fix-ticket.md contains a `state.json` reference with the section name (e.g., `triage.status`, `code_analysis.status`)
3. Verify `status` field updates include both success and failure paths (look for `"completed"` and `"blocked"` near each section reference)

**Key design decision:** We do NOT validate the exact field names within each section (e.g., `triage.severity`, `triage.area`). That level of specificity would create a brittle 1:1 coupling between the test and the command's prose. Instead, we verify that the section-level status field is written, which is the minimum structural contract.

### Scenario: `pipeline-feature-state-writes.sh`

Same approach for implement-feature.md. Different sections relevant (no `reproduction` in feature pipeline, has `infrastructure` only in scaffold).

---

## Point 6: Cross-Reference Integrity

### Design: Bidirectional Reference Validation

Three categories of cross-references to validate:
1. **Command -> Agent:** Every agent name in a command's Task tool dispatch exists as a file
2. **Command -> Core:** Every `core/{name}.md` reference in a command points to an existing file
3. **Agent <- CLAUDE.md:** Every agent listed in CLAUDE.md's model table exists as a file and vice versa

### Scenario: `contract-cross-references.sh`

Key assertions:
1. Extract all `core/*.md` references from pipeline commands. Verify each referenced file exists.
2. Extract all agent names from `ceos-agents:{name}` patterns in commands. Verify each agent file exists.
3. Extract all agent names from `agents/*.md` files on disk. Verify each appears in CLAUDE.md's model assignment table.
4. Count agents on disk vs CLAUDE.md count claim ("19 agents"). Verify match.

This catches: renamed agents not updated in commands, deleted core files still referenced, new agents not added to CLAUDE.md's documentation.

**Breaks when:** An agent is added/removed without updating CLAUDE.md (real documentation bug -- SHOULD break) or a core file is renamed without updating command references (real broken reference -- SHOULD break).

---

## Point 7: Config Contract Enforcement

### Design: Three-Way Consistency Check

The config contract is defined in three places:
1. CLAUDE.md's "Config Contract" section (the authoritative source)
2. `core/config-reader.md`'s process description
3. `tests/mock-project/CLAUDE.md`'s actual config (the test fixture)

### Scenario: `contract-config-sections.sh`

Key assertions:
1. **Required sections present in mock project:** For each required section listed in CLAUDE.md's config contract (Issue Tracker, Source Control, PR Rules, PR Description Template, Build & Test), verify the mock project's CLAUDE.md contains a matching `### {Section Name}` heading.
2. **Required keys present in mock project:** For each required key in the config contract table, verify the mock project has a `| {Key} |` row in the corresponding section.
3. **Optional section defaults:** For key optional sections with documented defaults (Retry Limits defaults: 5/3/3, Decomposition defaults: 7/fail-fast/squash), verify that CLAUDE.md, config-reader.md, and state/schema.md agree on default values.
4. **config-reader.md covers all required sections:** Verify config-reader.md references every required section name.

**Breaks when:** A new required config key is added to CLAUDE.md without updating the mock project (real gap -- SHOULD break) or when default values diverge between documentation sources (real inconsistency -- SHOULD break).

---

## Point 8: Mock Project Strategy

### Recommendation: Expand the Existing Mock, Do Not Create Variants

**Rationale:** The existing `tests/mock-project/CLAUDE.md` already has 11 config sections. Creating mock variants (minimal config, broken config, feature-only config) would multiply the maintenance surface. Instead, the existing mock project should be expanded to cover:

1. **Local Deployment section** (currently absent -- needed for deployment tests)
2. **Browser Verification section** (currently absent -- needed for browser test validation)
3. **E2E Test section** (currently absent -- needed for scaffold/feature pipeline tests)
4. **Agent Overrides section** (currently absent)
5. **Extra labels section** (currently absent)

All additions are optional sections with valid values. This gives config contract tests a complete fixture to validate against.

**What NOT to do:** Do not create a second mock project with intentionally broken config. Testing error paths (missing sections, TODO placeholders) should be done with inline assertions against the pipeline command files themselves, not against fixture variants. The command files already contain the error messages -- grep for them.

### Specific Additions to `tests/mock-project/CLAUDE.md`

```markdown
### Local Deployment (optional)
| Key | Value |
|-----|-------|
| Type | docker |
| Start command | `docker compose up -d` |
| Stop command | `docker compose down` |
| Health check URL | `http://localhost:3000/health` |
| Health check timeout | 30 |
| Ports | 3000, 5432 |

### Browser Verification (optional)
| Key | Value |
|-----|-------|
| Base URL | `http://localhost:3000` |
| Start command | `docker compose up -d` |
| On events | reproduce, verify |
| Timeout | 60 |
| Max pages | 5 |
| Screenshot storage | `.ceos-agents/{ISSUE-ID}/screenshots` |
| Exploration | disabled |
| Exploration max clicks | 20 |

### E2E Test (optional)
| Key | Value |
|-----|-------|
| Framework | playwright |
| Command | `npx playwright test` |

### Agent Overrides (optional)
| Key | Value |
|-----|-------|
| Path | `customization/` |

### Extra labels (optional)
| Key | Value |
|-----|-------|
| Labels | `automated, pipeline` |
```

This brings the mock project to full coverage of all documented optional sections while remaining a valid, parseable Automation Config.

---

## Point 9: Regression Guard Strategy

### Principle: Assert Presence of Semantic Anchors, Not Prose

The biggest regression risk is that a legitimate refactoring (renaming a step, rewording a constraint, reordering prose within a section) breaks tests that grep for exact text. The mitigation is a hierarchy of assertion robustness:

**Level 1 (most robust -- use by default):** Assert heading presence. `grep -q "^## Goal" "$file"`. Survives all content changes within the section.

**Level 2 (robust -- use for contracts):** Assert key-value patterns. `grep -q "^model: opus$" "$file"`. Survives surrounding text changes.

**Level 3 (moderate -- use for cross-references):** Assert structural patterns. `grep -q 'ceos-agents:fixer' "$file"`. Survives context changes but breaks on agent renames (which is a real contract change).

**Level 4 (fragile -- use only for regression guards):** Assert exact text. `grep -q "Step 4b" "$file"`. Used ONLY in negative assertions (things that should NOT exist after removal), as in `scaffold-v561-regression.sh`.

### Guard Against Hardcoded Lists

The research identified RQ-01: three test files hardcode 18 agents instead of 19. The root cause is hardcoded arrays. The proposed fix strategy:

**For tests that must enumerate agents by name** (model-assignment, section-order, read-only-agents): Keep the explicit arrays but add a dynamic count check at the top of each test:

```bash
# Dynamic completeness guard
disk_count=$(ls "$REPO_ROOT/agents/"*.md 2>/dev/null | wc -l)
list_count=${#AGENTS[@]}
if [ "$disk_count" -ne "$list_count" ]; then
  fail "Agent count mismatch: $disk_count files on disk, $list_count in test array. Update the test array."
fi
```

This creates a "canary" that fires whenever an agent is added or removed, prompting the developer to update the array. The array itself remains explicit because model assignments and read-only classification cannot be derived from file listing alone.

**For tests that only need file existence** (happy-path.sh): Use dynamic counts with `>= N` assertions (already done correctly: `>= 24` commands, `>= 18` agents). Update the minimum thresholds to current counts.

### Guard Against Removed Content

For content that was intentionally removed (as in `scaffold-v561-regression.sh`), use negative assertions: `if grep -q "Step 4b" "$file"; then fail "..."; fi`. These are inherently stable -- they only break if the removed content is accidentally re-added.

---

## Point 10: Feature Pipeline + Deployment Coverage

### Feature Pipeline: Three Dedicated Scenarios

#### Scenario: `feature-implement-pipeline.sh`

**Purpose:** Validate implement-feature.md has all required pipeline stages, agent dispatches, and structural elements.

Key assertions (10-12):
1. `spec-analyst` agent dispatch present with model: sonnet
2. `architect` agent dispatch present with model: opus
3. AC coverage check section present (references `maps_to`)
4. Decomposition decision section present with FORCE/DISABLED/AUTO modes
5. Fixer-reviewer loop section present with `Fixer iterations` reference
6. Test-engineer dispatch present with `Test attempts` reference
7. Acceptance gate section present (always for features, per CLAUDE.md)
8. Publisher dispatch present
9. `--description` flag handling section present
10. Config Validity Gate (Step 0b) present
11. `state.json` references >= 5 (already tested, but verify specific fields too)
12. `--yolo` flag auto-approve behavior documented

#### Scenario: `feature-ac-propagation.sh`

**Purpose:** Validate acceptance criteria flow from spec-analyst through the entire feature pipeline.

Key assertions:
1. spec-analyst output mentions `acceptance_criteria` (list)
2. Architect context includes acceptance criteria reference
3. `maps_to` field documented for subtask -> AC traceability
4. Fixer context includes `Acceptance criteria: {AC from spec-analyst}`
5. Reviewer context includes `Acceptance criteria` for AC Fulfillment check
6. Acceptance gate section references AC fulfillment verification
7. CLAUDE.md Feature Pipeline diagram mentions spec-analyst -> architect -> fixer/reviewer -> acceptance gate chain

#### Scenario: `feature-description-flag.sh`

**Purpose:** Validate the `--description` flag workflow in implement-feature.md (feature from description, v5.3.0).

Key assertions:
1. `--description` flag documented in flag parsing
2. Duplicate check section present (search for existing issues)
3. Card preview and confirmation prompt present
4. `--yolo` mode skips duplicate check
5. MCP card creation failure block pattern present
6. Mutual exclusion with Issue ID (`Cannot use --description and Issue ID together`)

### Deployment Coverage: Two Dedicated Scenarios

#### Scenario: `feature-deployment-verifier.sh`

**Purpose:** Validate deployment-verifier agent has correct structure and constraints.

Key assertions:
1. Agent file exists: `agents/deployment-verifier.md`
2. Frontmatter: name, description, model (sonnet), style
3. Section order: Goal -> Expertise -> Process -> Constraints
4. Process includes: port validation, pre-start validation, health check polling, cleanup on failure, docker inspection, verdict determination
5. Constraints include: NEVER alter project files, NEVER delete Docker volumes (without stop), NEVER start if port conflicts, NEVER exceed Health check timeout, NEVER expose secrets
6. Verdict set complete: HEALTHY, UNHEALTHY, PORT_CONFLICT, START_FAILED, SKIPPED
7. Result JSON output structure documented

#### Scenario: `feature-check-deploy.sh`

**Purpose:** Validate check-deploy.md command structure and deployment-verifier dispatch.

Key assertions:
1. Command file exists: `commands/check-deploy.md`
2. Frontmatter has `allowed-tools` including `Task`
3. Flag parsing: `--start`, `--stop`, mutual exclusion
4. Port validation step present (before any start attempt)
5. deployment-verifier dispatch via Task tool with model: sonnet
6. State initialization with `pipeline: "check-deploy"` and `deploy-{timestamp}` run_id format
7. Local Deployment required config section check present
8. Agent Overrides path handling for deployment-verifier
9. State.json deployment object update after agent completion

---

## Complete Scenario Inventory

### New Scenarios (12 total)

| # | File Name | Tier | Coverage Target | Est. Lines | Priority |
|---|-----------|------|-----------------|------------|----------|
| 1 | `structural-agent-completeness.sh` | Structural | RQ-01 fix: all 19 agents in tests, dynamic count guard | ~40 | P1 |
| 2 | `structural-core-completeness.sh` | Structural | RQ-02 fix: all 11 core files validated | ~45 | P1 |
| 3 | `pipeline-bugfix-step-order.sh` | Pipeline | fix-ticket.md step ordering | ~65 | P1 |
| 4 | `pipeline-feature-step-order.sh` | Pipeline | implement-feature.md step ordering | ~60 | P1 |
| 5 | `contract-agent-dispatch.sh` | Contract | Cross-pipeline agent name/model/namespace | ~70 | P1 |
| 6 | `pipeline-bugfix-state-writes.sh` | Pipeline | fix-ticket.md state.json field writes | ~55 | P1 |
| 7 | `pipeline-feature-state-writes.sh` | Pipeline | implement-feature.md state.json field writes | ~55 | P2 |
| 8 | `contract-cross-references.sh` | Contract | Command->agent, command->core, agent<->CLAUDE.md refs | ~65 | P1 |
| 9 | `contract-config-sections.sh` | Contract | Three-way config contract consistency | ~70 | P2 |
| 10 | `feature-implement-pipeline.sh` | Feature | implement-feature.md dedicated pipeline test | ~75 | P1 |
| 11 | `feature-deployment-verifier.sh` | Feature | deployment-verifier agent + check-deploy command | ~65 | P1 |
| 12 | `feature-ac-propagation.sh` | Feature | AC flow through feature pipeline | ~50 | P2 |

### Total After Expansion

- Existing: 25 scenarios
- New: 12 scenarios
- **Total: 37 scenarios** (~2000 lines new, ~3250 total)

### Scenarios Deliberately NOT Proposed

- **pipeline-batchfix-step-order.sh:** fix-bugs.md wraps fix-ticket's steps in a loop. The per-bug ordering is tested via fix-ticket. A separate batch test would duplicate assertions. Deferred to a later iteration if bugs emerge.
- **contract-config-defaults.sh (standalone):** Default value checking is folded into `contract-config-sections.sh` (assertion #3). A standalone defaults test would over-index on values that change during development.
- **feature-description-flag.sh:** The `--description` flag is tested as part of `feature-implement-pipeline.sh` (assertions #9-10). A standalone test would be too narrow for the maintenance cost.
- **contract-hook-order.sh:** Hook ordering (pre-fix before fixer, post-fix after fixer) is implicitly validated by step ordering tests. A dedicated hook test would add ~40 lines for a property already covered.
- **pipeline-scaffold-state-writes.sh:** Scaffold already has 8 tests. The state write pattern for scaffold differs significantly (infrastructure state, spec checkpoints). Deferred until scaffold state writes are stabilized.

---

## Integration With Existing Harness

### Zero Changes to run-tests.sh

The test runner already discovers all `*.sh` files in `tests/scenarios/`. New scenarios are automatically included. No runner modifications needed.

### Execution Order

`run-tests.sh` processes files in alphabetical order. The new naming convention (`contract-*`, `feature-*`, `pipeline-*`, `structural-*`) naturally groups related tests together in output without requiring any runner changes.

### Shared Helper Pattern

Two or three new scenarios will need a shared utility: extracting line numbers for step headings. Rather than creating a helper library (adding framework complexity), each scenario that needs this pattern will include a self-contained `step_line()` function:

```bash
step_line() {
  grep -n "$1" "$2" | head -1 | cut -d: -f1
}
```

This is 3 lines, duplicated in 3-4 scenarios. The duplication is intentional -- it keeps each scenario self-contained and debuggable without chasing imports.

If a future maintainer finds the duplication objectionable, the function can be extracted to `tests/harness/helpers.sh` and sourced. But introducing that indirection today, for 3 lines, would be premature optimization.

---

## Pros/Cons Self-Assessment

### Strengths

1. **Low false-positive rate.** Every scenario is designed around semantic anchors (headings, frontmatter keys, field names) rather than prose content. Legitimate refactoring should not break these tests.

2. **Incremental.** 12 new scenarios, each independent, each testable individually via `run-tests.sh scenario-name`. No big-bang adoption. Can be implemented and merged one at a time.

3. **Zero framework overhead.** No helpers library, no fixture setup/teardown, no test configuration files. Same patterns as existing tests. Any bash developer can read and modify them.

4. **Directly addresses all 6 confirmed bugs.** Scenarios #1 and #2 fix the hardcoded agent/core lists (RQ-01, RQ-02). Scenario #10 would catch RQ-03 (acceptance gate gap). Scenario #9 would catch RQ-04 (config-reader defaults). Scenario #5 would catch RQ-23 (namespace prefix).

5. **Maintenance cost is predictable.** Structural tests (tier 1) should never need updates for pipeline changes. Contract tests (tier 2) need updates only when the contract they validate changes -- which is a MAJOR or MINOR version bump, meaning the developer is already expecting test updates.

### Weaknesses

1. **No step-content validation.** The step ordering tests verify that headings appear in the correct order, but they do not verify what is INSIDE each step. A step could have its body completely emptied and the ordering test would still pass. Mitigation: this is by design -- step content is validated by other targeted tests (agent dispatch, state writes, AC propagation).

2. **Mock project expansion creates coupling.** Adding 5 optional sections to the mock project means those sections must be maintained when the config contract changes. Mitigation: the mock project is a test fixture, not documentation. Its maintenance is expected.

3. **No automated coverage metric.** There is no way to measure "what percentage of the plugin's contracts are covered by tests." The test inventory table above is the coverage map, maintained manually. Mitigation: a future `contract-coverage-report.sh` could automate this, but it would be a complex test and is deferred.

4. **Deployment verifier test is shallow.** The `feature-deployment-verifier.sh` scenario checks structural properties of the agent definition. It cannot verify that the deployment-verifier actually works (no runtime to test against). Mitigation: this is a fundamental limitation of structural testing for a markdown plugin. The test validates that the agent's contract is properly defined, which is the most common failure mode.

5. **Does not address P3 gaps.** Profile-parser pipeline awareness (RQ-12), port validation duplication (RQ-11), and decomposition-heuristics input contract (RQ-10) are all deferred. Mitigation: these are low-priority gaps with low probability of causing real bugs. They can be added in a future iteration if evidence of breakage emerges.

### Risk Assessment

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| New tests have false positives on first run | Medium | Low | Run full suite before merging. Fix false positives immediately. |
| Test maintenance burden exceeds value for contract tests | Low | Medium | Tier separation makes it clear which tests to update on pipeline changes. |
| Mock project expansion causes existing tests to fail | Very Low | Low | Additions are new optional sections -- no existing section is modified. |
| Step ordering tests break on legitimate step renumbering | Low | Low | Tests use heading text, not step numbers. Only heading renames break them. |

---

## Summary Decision Table

| Brainstorm Point | Approach | Key Design Decision |
|-----------------|----------|---------------------|
| 1. Taxonomy | Two-tier, four-prefix naming | Tier 1 = structural (stable), Tier 2 = contract/pipeline/feature (update on contract changes) |
| 2. Granularity | One property per scenario | Exceptions only when properties are tightly coupled (agent dispatch = cross-pipeline) |
| 3. Step ordering | Line-number comparison of semantic anchors | Per-pipeline scenarios, heading text not step numbers |
| 4. Agent dispatch | Cross-pipeline matrix validation | Agent existence + model match + namespace prefix |
| 5. State writes | Section-level status field presence | Per-pipeline, check "completed" + "blocked" paths |
| 6. Cross-references | Bidirectional file reference checks | Command->agent, command->core, agent<->CLAUDE.md |
| 7. Config contract | Three-way consistency (CLAUDE.md + config-reader + mock project) | Required sections + key presence + default value agreement |
| 8. Mock project | Expand existing, no variants | Add 5 optional sections for full coverage |
| 9. Regression guards | Semantic anchor hierarchy (Level 1-4) | Dynamic count guards for agent lists, negative assertions for removals |
| 10. Feature + deployment | 3 feature scenarios + 2 deployment scenarios | Dedicated pipeline test + AC propagation + deployment verifier structure |
