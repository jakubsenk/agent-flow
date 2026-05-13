# Agent-3 Research Findings: Q5, Q6, Q7, Q8, Q10

## Q5: Core Contract Coverage

### 1. agent-override-injector.md
- **Purpose:** Load per-agent customization files from the configured override directory and inject them into agent context as `## Project-Specific Instructions`.
- **Pipelines that reference it:** fix-ticket (Rules section), fixer-reviewer-loop.md (steps 1, 5). Referenced generically — all three pipelines (fix-ticket, fix-bugs, implement-feature) use it.
- **Mode assumptions:** Generic — no mode-specific logic. Works for all modes identically.
- **Input/output contracts:** Complete. Inputs: `agent_name`, `override_path`. Output: `additional_instructions` (string or empty). Failure handling covers permissions errors and missing directory.
- **Rating: GOOD**

### 2. block-handler.md
- **Purpose:** Unified block protocol — rollback git state, set issue state, post block comment, fire webhook, update state.json.
- **Pipelines that reference it:** fix-ticket (step X), fix-bugs (step X). Both bug pipelines explicitly delegate to this contract. implement-feature also has a block handler step but does NOT explicitly reference `core/block-handler.md` — it inlines the block logic.
- **Mode assumptions:** Bug-mode centric. The rollback logic lists `fixer`, `reviewer`, `test-engineer` as agents that trigger git rollback, but `spec-writer` and `spec-reviewer` are not listed. In the scaffold pipeline, block handling is explicitly different (noted in rollback-agent and spec-writer — "block comments go to stdout when no tracker is configured").
- **Input/output contracts:** Well-defined input table. Output contract is behavioral (side effects), not a return value — acceptable for a side-effect contract. Failure handling covers all sub-steps.
- **Gap:** implement-feature does not explicitly invoke `core/block-handler.md` — it appears to inline the behavior. This breaks single-source-of-truth for the block protocol.
- **Rating: NEEDS_UPDATE** — implement-feature should explicitly reference this contract.

### 3. config-reader.md
- **Purpose:** Parse `## Automation Config` from CLAUDE.md into a structured config object.
- **Pipelines that reference it:** fix-ticket, fix-bugs, implement-feature all say "Follow `core/config-reader.md`". scaffold is not mentioned explicitly but CLAUDE.md says all skills read from Automation Config.
- **Mode assumptions:** Generic. All required and optional sections documented. No mode-specific parsing.
- **Input/output contracts:** Input is the full CLAUDE.md content. Output is a dot-notation config object. Failure handling: blocks on missing required sections, warns on malformed optional sections.
- **Gap:** `decomposition.create_tracker_subtasks` is used in fix-ticket step 4b-tracker and fix-bugs step 3b-tracker but is NOT listed in config-reader.md's decomposition section parsing. The Decomposition section parsed keys are: `max_subtasks`, `fail_strategy`, `commit_strategy` — `create_tracker_subtasks` is missing.
- **Rating: NEEDS_UPDATE** — missing `create_tracker_subtasks` key in Decomposition section parsing.

### 4. decomposition-heuristics.md
- **Purpose:** Determine whether a ticket should be DECOMPOSE or SINGLE_PASS based on code-analyst output and flags.
- **Pipelines that reference it:** fix-ticket (step 4b), fix-bugs (step 3b), implement-feature (step 5).
- **Mode assumptions:** Designed for bug mode (inputs come from code-analyst). In implement-feature mode, the contract is invoked but the architect agent provides decomposition — the heuristics contract is referenced in implement-feature step 5 for task tree validation, not for decompose/single-pass determination (which the architect decides). This is a mild semantic overload — the contract's primary purpose (code-analyst-driven heuristics) does not apply in feature mode.
- **Input/output contracts:** Input: `decompose_flag` enum + `code_analyst_output` object. Output: `DECOMPOSE` or `SINGLE_PASS`. Failure handling covers missing fields.
- **Gap:** The `code_analyst_output` input assumes a code-analyst agent ran before this contract. In feature mode, this input doesn't exist — the architect output is used instead. The contract does not document feature-mode usage.
- **Rating: NEEDS_UPDATE** — should clarify feature-mode invocation semantics (or the feature pipeline should not claim to follow this contract for its decomposition decision).

### 5. fix-verification.md
- **Purpose:** Run the Verify command after PR merge to confirm the fix on the target branch.
- **Pipelines that reference it:** fix-ticket (step 9d). NOT referenced in fix-bugs or implement-feature skills.
- **Mode assumptions:** Bug-specific name ("Fix Verification") but functionality is generic — just runs a configured command. Could apply to feature pipeline too.
- **Input/output contracts:** Complete. Inputs: config, issue_id, pr_url, base_branch. Output: PASSED / FAILED / SKIPPED. Failure handling: timeout, PR not merged, MCP failure.
- **Gap:** implement-feature has no verify step even though a "Verify command" could logically apply post-feature-merge.
- **Rating: GOOD** (for what it covers; the gap is in the calling skill, not this contract).

### 6. fixer-reviewer-loop.md
- **Purpose:** Iterative fixer↔reviewer loop with configurable limits and AC checking.
- **Pipelines that reference it:** fix-ticket (step 5/7, post-fix section), fix-bugs (step 6, implied). implement-feature uses the same fixer/reviewer agents but the skill text doesn't explicitly say "Follow `core/fixer-reviewer-loop.md`" consistently — fix-bugs step 6 says "Follow `core/fixer-reviewer-loop.md`" but fix-ticket also says this.
- **Mode assumptions:** Uses `acceptance_criteria` generically (from triage OR spec-analyst). The `context` input says "Bug report or spec + AC + code-analyst output" — the "or spec" handles feature mode nominally.
- **Input/output contracts:** Complete. Input table with all required fields. Output: APPROVED / BLOCKED / NEEDS_DECOMPOSITION with payloads.
- **Gap:** The input `context` field documentation says "Bug report or spec + AC + code-analyst output" — this is slightly inaccurate for feature mode (no code-analyst output in feature pipeline). Minor documentation issue.
- **Rating: GOOD**

### 7. mcp-detection.md
- **Purpose:** Single source of truth for MCP package/tool-prefix lookup and connectivity verification.
- **Pipelines that reference it:** scaffold (step 0-MCP), init (steps 3, 7). Documented in the file's header.
- **Mode assumptions:** Generic (tracker type → package/prefix mapping). No pipeline mode assumptions.
- **Input/output contracts:** Comprehensive. Full output contract with all fields (mcp_available, write_available, write_cleanup_failed, package_name, tool_prefix, error, error_type, write_error). Failure handling covers all cases including unknown tracker type. Classification Reference table is detailed and consistent with check-setup.
- **Rating: GOOD**

### 8. mcp-preflight.md
- **Purpose:** Thin wrapper over mcp-detection.md — verify tracker MCP connectivity before pipeline starts. Blocks on failure.
- **Pipelines that reference it:** fix-ticket (step 0), fix-bugs (step 0), implement-feature (step 0). All three bug/feature pipelines use it.
- **Mode assumptions:** Generic.
- **Input/output contracts:** Input: `tracker_type`. Output: `mcp_available` boolean. Failure blocks with standardized template. The contract delegates to mcp-detection.md — correct single-source pattern.
- **Rating: GOOD**

### 9. post-publish-hook.md
- **Purpose:** Execute post-publish hooks and fire webhooks after PR creation.
- **Pipelines that reference it:** fix-ticket (steps 9a/9b), fix-bugs (implied via same steps). implement-feature has post-publish steps but the skill text references this contract explicitly.
- **Mode assumptions:** Generic (operates on config hooks + pr_url + issue_id). No mode-specific assumptions.
- **Input/output contracts:** Input: config, pr_url, issue_id, branch. Output: per-hook status (advisory). Failure handling: all failures are advisory, never block.
- **Gap:** The `branch` input is listed in the input contract but is not used in any documented process step — appears unused.
- **Rating: GOOD** (minor unused input field).

### 10. profile-parser.md
- **Purpose:** Parse a pipeline profile from Automation Config to determine skip/extra stages.
- **Pipelines that reference it:** fix-ticket, fix-bugs, implement-feature all say "Follow `core/profile-parser.md`".
- **Mode assumptions:** The valid stage names list (`triage`, `code-analyst`, `spec-analyst`, `test-engineer`, `e2e-test-engineer`, `reproducer`, `browser-verifier`) covers all three pipeline types, but `spec-analyst` is only valid for feature mode and `triage`, `code-analyst` are only for bug mode. The contract treats them all as valid without documenting which stages apply to which pipeline. This means a bug pipeline could list `spec-analyst` in skip_stages without a warning (it would just have no effect).
- **Input/output contracts:** Input: config, pipeline_name, profile_name. Output: `skip_stages[]`, `extra_stages[]`. Failure handling: missing profile = hard error; attempt to skip mandatory stages = BLOCK; unknown stage = warn + ignore.
- **Gap:** The `pipeline_name` input is received but NOT used in any process step — stages are validated against a flat list, not against which stages are valid for the given pipeline. The input is vestigial.
- **Rating: NEEDS_UPDATE** — `pipeline_name` input is unused; stage-to-pipeline mapping should either be enforced or the input removed.

### 11. state-manager.md
- **Purpose:** Read/write/resume contract for `.ceos-agents/{RUN-ID}/state.json`. Atomic persistence, resume detection, metrics enablement.
- **Pipelines that reference it:** All pipelines — every skill and many agents explicitly say "Follow atomic write protocol from `core/state-manager.md`".
- **Mode assumptions:** Generic. The schema initialization uses `mode` field to distinguish pipelines.
- **Input/output contracts:** Three operation types (write/read/resume) each with explicit contracts. Failure handling: retry once, log on second failure, never block on state loss.
- **Gap:** The Resume Process heuristic fallback is described but the heuristic logic is deferred to "resume-ticket.md existing logic" without specifying what that logic is — incomplete self-documentation.
- **Rating: GOOD** (minor gap in resume heuristic documentation).

---

## Q6: State Schema Coverage

### Pipeline-Specific Fields

The schema is designed primarily for the bug pipeline (`code-bugfix` mode). Pipeline-specific field usage:

| Field | Bug mode | Feature mode | Scaffold mode |
|-------|----------|--------------|---------------|
| `triage.*` | Used (triage-analyst output) | Reused for spec-analyst AC (noted in implement-feature step 3) | Not used |
| `code_analysis.*` | Used (code-analyst output) | Reused for architect output (noted in implement-feature step 4) | Not used |
| `reproduction.*` | Used (browser reproduction) | Not used | Not used |
| `browser_verification.*` | Used | Not used | Not used |
| `infrastructure.*` | Not used | Not used | Used (scaffold Step 0-INFRA) |
| `decomposition.*` | Used (optional) | Used (always in feature) | Not used directly |
| `deployment.*` | Used (E2E pre-flight) | Used (E2E pre-flight) | Not used |

### Overloaded Fields

Two explicit field reuses are documented in implement-feature:

1. **`triage` section** — In feature mode, `implement-feature` step 3 writes `triage.status = "completed"` and `triage.acceptance_criteria` to store spec-analyst output. The field is named `triage` but holds spec-analyst data. This is acknowledged in the skill text: "field reused for spec-analyst AC".

2. **`code_analysis` section** — In feature mode, `implement-feature` step 4 writes `code_analysis.status = "completed"` to store architect output. The field is named after code-analyst but holds architect design data. Acknowledged: "field reused for architect output".

These reuses are pragmatic but create semantic confusion when reading state.json for a feature run — the `triage` object contains spec-analyst data and `code_analysis` contains architect data. The `mode` field in the state allows disambiguation, but downstream tools (metrics, resume-ticket, dashboard) must know to interpret these fields differently per mode.

### Missing Fields for Scaffold Mode

The scaffold pipeline has no dedicated state fields beyond `infrastructure.*`. Missing:
- No `spec_writer` section (tracks spec-writer/spec-reviewer loop state)
- No `scaffolder` section (tracks batch progress, scorecard results)
- No `spec_review` section (tracks spec-reviewer iterations)
- `spec_iterations` in retry_limits is referenced in CLAUDE.md Automation Config but not in `config.retry_limits` in the schema (schema only has `fixer_iterations`, `test_attempts`, `build_retries`)

### Step Status Value Consistency

The Step Status Enum (`pending`, `in_progress`, `completed`, `failed`, `skipped`, `blocked`, `not_applicable`) is defined once in schema.md and referenced consistently. However:
- The `deployment` object's status field is documented as a subset: only `pending`, `in_progress`, `completed`, `failed` — `skipped`, `blocked`, `not_applicable` are not valid for deployment. This subset restriction is documented in the Deployment Object Fields table, which is correct but creates an inconsistency: a different enum for one section without its own named type.
- The `hooks` fields use `completed`, `failed`, `null` — not the full Step Status Enum. This is also a subset, but not documented as such.

---

## Q7: Consistency and Duplication

### fix-ticket vs fix-bugs: Logic Duplication

The two skills are structurally near-identical for the per-bug pipeline. Duplicated sections (verbatim or near-verbatim copy):

1. **Configuration section** — Both have identical Configuration sections listing the same config keys with identical defaults. The only addition in fix-bugs: `Worktrees` section and `Max blocked per run` in Error Handling.

2. **Decompose flag parsing** — fix-ticket step 4a vs fix-bugs step 3a: identical logic.

3. **Decomposition decision** — fix-ticket step 4b vs fix-bugs step 3b: near-identical (both follow `core/decomposition-heuristics.md`, both call architect, both validate task tree). fix-bugs adds per-bug iteration.

4. **Create tracker subtasks** — Steps 4b-tracker (fix-ticket) and 3b-tracker (fix-bugs) contain ~200 lines of identical pseudocode for the tracker subtask creation loop (idempotency check, per-tracker MCP parameters, GitHub/Gitea checklist logic). This is the largest duplication block.

5. **NEEDS_DECOMPOSITION handler** — Both handle fixer's NEEDS_DECOMPOSITION signal with 5 identical steps.

6. **Block handler reference** — Both delegate to "step X" with `core/block-handler.md`.

7. **State.json update patterns** — Identical atomic write instructions throughout.

**Estimated duplication:** ~60% of fix-ticket content is duplicated in fix-bugs. The primary differences are: (a) fix-bugs wraps everything in a per-bug loop, (b) fix-bugs adds worktree support, (c) fix-bugs has parallel triage/code-analyst phases, (d) fix-bugs has `Max blocked per run` logic.

### NEEDS_DECOMPOSITION Handlers Across Skills

**fix-ticket (step 5):**
```
1. Authoritative revert (git checkout . && git clean -fd)
2. If DISABLED → Block
3. If already decomposed once → Block
4. Run architect for decomposition
5. Continue with subtask execution (step 4c)
```

**fix-bugs (step 4, within per-bug loop):**
```
1. Authoritative revert (git checkout . && git clean -fd)
2. If DISABLED → Block handler (step X)
3. If already decomposed once → Block handler (step X)
4. Run architect for decomposition
5. Continue with subtask execution (step 3c)
```

These are functionally identical. fix-bugs correctly says "Block handler (step X)" (delegating to the core contract) while fix-ticket says "Block" without the "step X" reference for item 2 — minor inconsistency in the block delegation language.

**implement-feature:** Does NOT have a NEEDS_DECOMPOSITION handler. The feature pipeline uses the architect agent which decides decomposition upfront — the fixer never signals NEEDS_DECOMPOSITION in feature mode because the decomposition was already done. This is architecturally correct but undocumented (nothing in fixer.md or implement-feature says "fixer will not signal NEEDS_DECOMPOSITION in feature mode because decomposition happens before fix").

### Block Comment Template Consistency

All agents that use the Block Comment Template follow the same format:
```
[ceos-agents] 🔴 Pipeline Block
Agent: {agent name}
Step: {pipeline step}
Reason: {max 2 sentences}
Detail: {technical output}
Recommendation: {what the human should do}
```

Agents that include this template directly in their Constraints section: fixer, reviewer, test-engineer, triage-analyst, code-analyst, spec-analyst, spec-writer, architect, publisher, e2e-test-engineer, priority-engine.

Agents that reference the template but receive it from context (don't embed it): rollback-agent (uses template passed in context), acceptance-gate (explicitly says "do not Block").

**Inconsistency found:** `spec-reviewer` does NOT include the Block Comment Template in its Constraints — it says "output review with REVISE verdict — do not Block the pipeline". This is correct behavior but creates an implicit rule: spec-reviewer is the only review-type agent that cannot block. This is not documented as a design decision.

**Inconsistency found:** `browser-verifier` Constraints say "NEVER block the pipeline based on Sub-phase B (exploration) findings" but does not say NEVER block overall — Sub-phase A FAILED verdict returns control to fixer (which is not technically a block, it's a loop). This is architecturally correct but the language is inconsistent with other agents that use "NEVER block".

**Inconsistency found:** `stack-selector` and `scaffolder` Constraints say "On failure: report what's unclear and ask the user" / "report which verification step failed and why" without the Block Comment Template — because scaffold has no issue tracker context. The deviation is documented inline but not in a consistent pattern across agents.

---

## Q8: Best Practices Assessment

### Fixer Agent (`agents/fixer.md`)

**NEEDS_DECOMPOSITION documentation:**
- The signal is well-documented in the Process section (step 5, ESCAPE HATCH subsection).
- The format (`## NEEDS_DECOMPOSITION` with reason, scope, split, work done) is specific.
- The constraint "NEEDS_DECOMPOSITION may be signaled at most ONCE per ticket" is correct and matches the calling skills.
- **Gap:** The agent says "revert any partial changes before outputting this signal (best-effort)" — the calling skill provides an "authoritative revert" as a safety net. This layered approach is sensible but the agent documentation doesn't explain WHY its own revert is "best-effort" (because the LLM may have already applied partial edits that are hard to self-detect). Minor documentation gap.

**100-line limit:**
- Appropriate for bug mode. For feature mode (where fixer handles individual subtasks of an architect-decomposed plan), the 100-line limit per subtask is also correct — the architect is supposed to design subtasks small enough to fit.
- For scaffold mode: the fixer is not called by the scaffold pipeline for the skeleton generation (scaffolder agent does this). The fixer IS called for feature implementation within scaffold v2. In this context, the 100-line limit is appropriate since each feature subtask should be bounded.
- **Assessment:** Limit is appropriate across all modes.

**TDD RED phase in feature/scaffold mode:**
- The agent says: "If the project has no test infrastructure (no test framework, no test directory), skip the RED phase and implement the fix directly."
- In scaffold mode, test infrastructure is always generated by the scaffolder (smoke test, setup file). So TDD should apply.
- In feature mode, test infrastructure exists (it was set up during scaffold or exists in the project). TDD RED phase is appropriate — you'd write a failing test for the feature behavior, then implement.
- **Issue:** The fixer's Process step 5 says "Implement the fix using red-green-refactor" and describes TDD in bug terms ("Write a test that REPRODUCES THE BUG. Run it — confirm it FAILS"). For feature mode, writing a test that "reproduces the bug" is semantically wrong — you want a test that demonstrates the MISSING FEATURE behavior. The language is bug-centric and should be generalized for feature mode.
- **Rating: NEEDS_UPDATE** — TDD language is bug-centric; should cover feature mode (test for missing capability, not for bug reproduction).

### Reviewer Agent (`agents/reviewer.md`)

**Adversarial review for scaffold:**
- The reviewer is not called in the scaffold pipeline directly (spec-reviewer handles spec review). The fixer↔reviewer loop is called in scaffold v2 for feature implementation subtasks.
- In this context, "adversarial review" for feature subtasks is appropriate — you want the reviewer to be thorough.
- However, the reviewer's checklist includes "Root cause" ("Does the fix address the actual root cause, not just symptoms?") — this is bug-specific language. In feature mode, there is no "root cause"; the question should be "Does the implementation satisfy the acceptance criterion?".
- **Assessment:** The adversarial stance is correct and appropriate for all modes. The checklist language is bug-centric.

**AC fulfillment integration:**
- Well-integrated. Step 4 explicitly maps each AC to FULFILLED/PARTIALLY/NOT ADDRESSED.
- The AC Fulfillment section in the output template is clearly specified.
- Constraint: "If acceptance criteria were provided in context, MUST include AC Fulfillment section in output. If no AC provided, skip the section." — this is correct and handles both modes.
- **Gap:** The "issue count gate" (step 6, "MUST identify at least 3 specific issues per review") creates tension in feature mode. For a clean, small feature subtask, forcing 3 issues may cause the reviewer to manufacture issues. The escape hatch ("If you genuinely cannot find 3 issues... you may approve with fewer — but you MUST include a detailed explanation") is present but the 3-issue minimum is a bug-mode heuristic that may not transfer well to small, isolated feature subtasks.
- **Rating: NEEDS_UPDATE** — checklist language should be mode-aware; 3-issue minimum may need a lower bar for scaffold/feature mode.

### Test-Engineer Agent (`agents/test-engineer.md`)

**"1-3 focused tests" scope:**
- Appropriate for bug mode (regression test + edge case + boundary).
- In feature mode, 1-3 tests per subtask is reasonable — each subtask is small.
- **Issue:** In scaffold mode (scaffold v2 feature implementation), the test-engineer writes 1-3 tests per feature subtask. But the scaffolder already generated a smoke test and test infrastructure. The test-engineer's step 2 says "Run existing tests first" — this handles the scaffold case correctly (the smoke test will already pass).
- **Assessment:** 1-3 tests per invocation is appropriate. No change needed.

**Scaffold with no test infra:**
- The agent's step 4 handles missing test infrastructure: "If no existing tests exist: create the test file following language conventions."
- The constraint says: "If no test command is configured in Automation Config → Block with message 'No test command configured'."
- In scaffold mode, the scaffolder ALWAYS generates a test command in Automation Config (it's a required section). So the Block case should not occur in scaffold.
- **Subtle issue:** The test-engineer says "Follow Arrange-Act-Assert pattern" and "Follow project test conventions." In early scaffold v2 (immediately after scaffolding), there is only a smoke test. The test-engineer must infer conventions from 1 smoke test. This may lead to inconsistent test style.
- **Rating: GOOD** for scaffold mode (infrastructure always exists), but the single-smoke-test convention inference is a practical concern worth noting.

---

## Q10: Documentation Quality — All 19 Agents

### Frontmatter Completeness Check

| Agent | Description Accuracy | Style Meaningfulness | Model Rationale |
|-------|---------------------|---------------------|-----------------|
| `triage-analyst` | Accurate — "Analyzes and triages bug reports. Validates clarity, detects duplicates, downloads and analyzes attachments." | "Analytical, systematic, concise" — meaningful | sonnet: analysis/classification task, not critical code change |
| `code-analyst` | Accurate — "Maps complete impact zone of a bug." | "Methodical, detail-oriented, risk-aware" — meaningful | sonnet: analysis only, read-only |
| `fixer` | Accurate — "Implements minimal, correct bug fixes targeting root cause. Surgical changes with backwards compatibility." | "Pragmatic, minimal, surgical" — meaningful and distinctive | opus: critical code changes |
| `reviewer` | Accurate — "Senior code reviewer and quality gate." | "Adversarial, evidence-driven, thorough" — meaningful | opus: quality gate for critical changes |
| `test-engineer` | Partially accurate — says "verifying the fix" but in feature mode it verifies the implementation of a subtask, not a fix. | "Defensive, coverage-focused, precise" — meaningful | sonnet: testing/verification, not architecture |
| `acceptance-gate` | Accurate — "Verifies acceptance criteria are fulfilled by implementation." | "Evidence-driven, requirements-focused, systematic" — meaningful | sonnet: verification, read-only |
| `architect` | Accurate — "Designs architecture and generates task trees for feature implementation and complex bug decomposition." | "Strategic, systems-thinking, trade-off aware" — meaningful | opus: critical architecture decisions |
| `spec-analyst` | Accurate — "Analyzes feature requests and extracts structured specifications with acceptance criteria." | "Requirements-focused, clarity-driven, structured" — meaningful | sonnet: requirements analysis, not implementation |
| `spec-writer` | Accurate — "Generates complete project specification from user input." | "Visionary, comprehensive, user-centric" — meaningful | opus: critical specification that drives entire project |
| `spec-reviewer` | Accurate — "Reviews project specification quality, completeness, consistency, and feasibility." | "Critical, feasibility-focused, consistency-checking" — meaningful | opus: quality gate for specification |
| `scaffolder` | Accurate — "Generates minimal buildable project skeleton with tests, CI/CD, Docker, and CLAUDE.md." | "Efficient, convention-following, minimal" — meaningful | sonnet: generation task following conventions |
| `stack-selector` | Accurate — "Analyzes project requirements and selects optimal technology stack for scaffolding." | "Decisive, opinionated, rationale-driven" — meaningful | sonnet: analysis/recommendation, not critical code |
| `publisher` | Accurate — "Creates branch, commits, pushes, creates PR with full traceability." | "Mechanical, checklist-driven, cautious" — meaningful and accurate | haiku: mechanical/template task |
| `rollback-agent` | Accurate — "Reverts failed fix attempts. Resets git state and posts block comment to issue tracker." | "Swift, safety-first, minimal" — meaningful | haiku: mechanical git operations |
| `reproducer` | Accurate — "Generates and runs a Playwright script to reproduce a reported bug." | "Evidence-focused, precise, non-blocking" — meaningful; "non-blocking" is a behavioral hint, unusual but informative | sonnet: analysis/automation |
| `browser-verifier` | Accurate — "Verifies a bug fix via browser automation. Replays reproduction steps, checks adjacent pages, and optionally runs guided exploration. Never blocks on exploration findings." | "Verdict-driven, bounded, evidence-attaching" — meaningful | sonnet: verification, not critical code |
| `e2e-test-engineer` | Partially accurate — description says "Writes and runs E2E tests verifying user flows end-to-end. Requires running application." Missing: it also does deployment pre-flight via deployment-verifier. | "User-journey focused, resilient, thorough" — meaningful | sonnet: test writing/running |
| `priority-engine` | Accurate — "Analyzes backlog and recommends fix order based on impact, risk, effort, and dependencies." | "Data-driven, impact-focused, objective" — meaningful | opus: strategic prioritization (note: CLAUDE.md lists priority-engine under opus agents; this is a heavy-weight analysis task) |
| `deployment-verifier` | Accurate — "Verifies local deployment health — checks ports, starts app, polls health endpoint, inspects Docker containers." | "Diagnostic, port-aware, non-destructive" — meaningful; "non-destructive" is a behavioral hint, informative | sonnet: verification/diagnostics |

### Identified Issues

1. **`test-engineer` description** — Says "verifying the fix" which is bug-centric language. In feature mode it verifies implementation of a subtask. Minor inaccuracy.

2. **`e2e-test-engineer` description** — Does not mention the deployment pre-flight step (dispatching deployment-verifier). The description reads as if it only writes and runs tests. Users consulting the agent picker would not know it also handles deployment lifecycle. Should add "with deployment pre-flight" or similar.

3. **Model rationale gaps** — The `style` field documents communication style well. However, there is no `rationale` field in the frontmatter — the model assignment rationale exists in CLAUDE.md's Model Selection table but NOT in the individual agent files. If someone reads an agent file in isolation, they cannot see why a particular model was chosen. This is a documentation gap (not a structural requirement — the current format has no `rationale` field).

4. **`priority-engine` model** — Uses opus. This is the only "analysis/recommendation" agent on opus; all others are on sonnet. The justification (strategic cross-issue prioritization requires deep reasoning) is in CLAUDE.md but not in the agent file. Reasonable choice but could benefit from inline documentation.

---

## Summary of Key Findings

### Critical Issues
- **config-reader.md** missing `create_tracker_subtasks` key in Decomposition section parsing — causes silent mismatch when this config key is set.
- **implement-feature** does not explicitly reference `core/block-handler.md` — block protocol is inlined, breaking single-source-of-truth.

### Significant Issues
- **State schema field reuse** (`triage.*` for spec-analyst, `code_analysis.*` for architect) is functional but creates semantic confusion for downstream tooling (metrics, dashboard, resume).
- **Fixer TDD language** is bug-centric — "test that reproduces the bug" doesn't map to feature/scaffold mode.
- **profile-parser.md** `pipeline_name` input is received but never used.
- **Tracker subtask creation pseudocode** is duplicated verbatim (~200 lines) between fix-ticket and fix-bugs — a shared core contract or skill include would reduce maintenance burden.

### Minor Issues
- `e2e-test-engineer` description missing deployment pre-flight mention.
- `test-engineer` description says "verifying the fix" (bug-centric).
- `reviewer` checklist "Root cause" language is bug-centric.
- 3-issue minimum in reviewer may be too high for small feature subtasks.
- `post-publish-hook.md` has a `branch` input that is unused in the process steps.
- Scaffold mode lacks dedicated state.json sections for spec-writer/spec-reviewer/scaffolder phases.
- `spec_iterations` retry limit is in the config contract but absent from the state schema's `config.retry_limits` object.
