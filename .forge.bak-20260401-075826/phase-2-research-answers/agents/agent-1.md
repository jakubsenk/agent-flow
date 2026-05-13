# Phase 2 Research Answers — Agent 1

## RQ-01: 19th agent missing from test hardcoded lists

**Verdict:** CONFIRMED BUG

**Evidence:**
All three test files (`frontmatter-completeness.sh`, `model-assignment.sh`, `section-order.sh`) contain hardcoded arrays listing exactly 18 agents. `deployment-verifier` is absent from every list.

- `frontmatter-completeness.sh` line 11–16: `AGENTS=(triage-analyst code-analyst fixer reviewer acceptance-gate test-engineer e2e-test-engineer publisher rollback-agent spec-analyst architect stack-selector scaffolder priority-engine spec-writer spec-reviewer reproducer browser-verifier)` — 18 agents, no `deployment-verifier`.
- `model-assignment.sh` line 27–30: `SONNET_AGENTS=(triage-analyst code-analyst test-engineer e2e-test-engineer spec-analyst stack-selector scaffolder acceptance-gate reproducer browser-verifier)` — no `deployment-verifier` in sonnet list.
- `section-order.sh` line 11–16: same 18-agent array as frontmatter-completeness.sh.
- All three test files print "All **18** agents …" in their PASS message, confirming the count is wrong.
- `CLAUDE.md` line 33 lists `deployment-verifier` as the 19th agent (sonnet model).

**Recommendation:** E2E test should verify all three scenario scripts include `deployment-verifier` and print "All 19 agents" in their PASS message. Also verify `model-assignment.sh` SONNET_AGENTS array contains `deployment-verifier`.

---

## RQ-02: core/mcp-detection.md excluded from core-include-refs.sh

**Verdict:** CONFIRMED GAP

**Evidence:**
`core-include-refs.sh` line 11–22 defines `CORE_FILES` with exactly 10 entries:
```
config-reader, mcp-preflight, fixer-reviewer-loop, block-handler,
agent-override-injector, decomposition-heuristics, profile-parser,
post-publish-hook, fix-verification, state-manager
```
`mcp-detection.md` is NOT in this array.

However, `core/mcp-detection.md` does exist and has all 4 required contract sections:
- `## Purpose` (line 3)
- `## Input Contract` (line 9) — the test checks for `## Input`, not `## Input Contract`, so this would fail that check anyway
- `## Process` (line 19)
- `## Output Contract` (line 46) — the test checks for `## Output`, not `## Output Contract`
- `## Failure Handling` (line 56) — the test checks for `## Failure`

Note: `mcp-detection.md` uses headings `## Input Contract` and `## Output Contract` while the test checks for `## Input` and `## Output` (substring match via `grep -q` would still pass since the strings contain the substrings). The `## Failure Handling` heading also passes the `## Failure` check.

The file is referenced by `commands/scaffold.md` and `commands/init.md` but it is not in the CORE_FILES array, so its existence and contract sections are never validated by the test harness.

**Recommendation:** E2E test should verify `mcp-detection.md` is present in `CORE_FILES` in `core-include-refs.sh`, and that the script validates its 4 required sections.

---

## RQ-03: Feature pipeline acceptance gate contradicts CLAUDE.md

**Verdict:** CONFIRMED BUG

**Evidence:**
CLAUDE.md Feature Pipeline diagram (line 59):
```
→ TEST ENGINEER (sonnet) → [Acceptance gate (always)]
```
This says the acceptance gate always runs in the feature pipeline.

`commands/implement-feature.md` step 6g (lines 299–309):
```
For features, the acceptance gate always runs within the subtask loop
(no threshold condition — unlike bugs, which require ≥3 AC or complexity ≥M).
In single-pass mode (no decomposition), this step is skipped.
```
The command explicitly states the acceptance gate is **skipped** in single-pass mode. The state.json write confirms: `set acceptance_gate.status to "completed" (or "skipped" for single-pass)`.

**Contradiction:** CLAUDE.md says "always" with no qualification. The implement-feature command says "always runs" but then immediately carves out an exception for single-pass (no-decomposition) mode. The CLAUDE.md pipeline diagram is misleading — `[Acceptance gate (always)]` implies no exceptions.

**Recommendation:** E2E test should verify that implement-feature in single-pass mode sets `acceptance_gate.status = "skipped"` in state.json, confirming the contradiction is real and the command-level logic (skip for single-pass) is what actually executes.

---

## RQ-04: Root cause iterations in config-reader.md

**Verdict:** CONFIRMED GAP

**Evidence:**
`CLAUDE.md` Retry Limits row states: "Root cause iterations | 3" as a default for the optional Retry Limits section.

`commands/fix-ticket.md` line 29 and `commands/fix-bugs.md` line 24 both reference "Root cause iterations (default: 3)" when reading Automation Config.

`core/config-reader.md` line 23, the `### Retry Limits` parsing definition:
```
→ retry.fixer_iterations (default: 5), retry.test_attempts (default: 3),
  retry.build_retries (default: 3), retry.spec_iterations (default: 5)
```
`retry.root_cause_iterations` is entirely absent from `config-reader.md`'s output contract.

`state/schema.md` line 153: `config.retry_limits` only has `fixer_iterations`, `test_attempts`, `build_retries` — no `root_cause_iterations`.

The config-reader does not parse or expose this value, yet both bug pipeline commands reference it. Commands that use it must parse it themselves, bypassing the shared contract.

**Recommendation:** E2E test should verify `core/config-reader.md` includes `retry.root_cause_iterations` in the Retry Limits output contract, and `state/schema.md` includes `config.retry_limits.root_cause_iterations`.

---

## RQ-05: State field reuse for spec-analyst

**Verdict:** CONFIRMED GAP

**Evidence:**
`commands/implement-feature.md` line 176:
```
Update state.json: set triage.status to "completed" (field reused for spec-analyst AC),
write spec-analyst AC list to triage.acceptance_criteria.
```
The comment explicitly acknowledges this is a field reuse — the `triage.*` fields store spec-analyst output in the feature pipeline.

`state/schema.md` does not document this reuse anywhere. The schema describes `triage` as "Triage-analyst phase state" (line 162) with no mention that these fields double as spec-analyst storage in feature pipelines. The field descriptions reference only the bug pipeline semantics (severity, area, complexity — which don't apply for features).

**Recommendation:** E2E test should verify `state/schema.md` documents the `triage.*` field reuse for the feature pipeline (spec-analyst), either via a dedicated note in the field definitions or a separate section explaining mode-dependent field semantics.

---

## RQ-06: fix-bugs.md missing Config Validity Gate

**Verdict:** CONFIRMED BUG

**Evidence:**
`commands/fix-ticket.md` lines 80–98: Has explicit "Step 0b: Config Validity Gate" that checks all required sections for TODO placeholders and empty values before pipeline work begins.

`commands/implement-feature.md` lines 89–110: Has identical "Step 0b: Config Validity Gate" with the same logic.

`commands/fix-bugs.md`: No Config Validity Gate exists. Searching the entire file finds no reference to "Config Validity", "Step 0b", or "TODO" placeholder checking. The command proceeds directly from MCP pre-flight check (Step 0) to dry-run check to bug fetching.

`CLAUDE.md` memory notes: "Config validity gate: Step 0b in implement-feature + fix-ticket (blocks on TODOs)" — confirming this gate was intentionally added to both of those commands. fix-bugs was left out.

**Recommendation:** E2E test should verify `fix-bugs.md` contains a Config Validity Gate step (Step 0b or equivalent) and that it checks for `<!-- TODO:` and `<...>` placeholders in required config sections before pipeline execution.

---

## RQ-07: fixer-reviewer-loop reference placement

**Verdict:** CONFIRMED BUG (inconsistent placement)

**Evidence:**

`commands/fix-bugs.md`:
- Line 248: `### 6. Reviewer ⟲` heading
- Line 250: `Follow core/fixer-reviewer-loop.md` — reference is INSIDE the Reviewer section heading, immediately after it.

`commands/fix-ticket.md`:
- Line 257: `Follow core/fixer-reviewer-loop.md` — reference appears as a standalone paragraph BEFORE the `### 7. Reviewer ⟲` heading (line 261). It sits at the end of step 6b (Post-fix custom agent section), detached from the Reviewer heading.

`commands/implement-feature.md`:
- Line 272: `Follow core/fixer-reviewer-loop.md` — reference is INSIDE step 6d (Reviewer section), correctly placed after the Reviewer heading (line 269).

The fix-ticket placement is the outlier: the reference is misplaced in the post-fix custom agent section (step 6b) rather than in the Reviewer section (step 7), creating a structural inconsistency. A reader of fix-ticket.md could miss the loop protocol because it appears under the wrong heading.

**Recommendation:** E2E test should verify that in each pipeline command, the `core/fixer-reviewer-loop.md` reference appears within the Reviewer section (not in a prior step). Check that the line containing the reference comes after the `### {N}. Reviewer` heading line.

---

## RQ-08: Block handler rollback scope documentation

**Verdict:** CONFIRMED GAP

**Evidence:**
`core/block-handler.md` Process step 1 (line 21):
```
If the blocking agent is fixer, reviewer, or test-engineer → dispatch rollback-agent.
Do NOT rollback on block from triage-analyst or code-analyst — no git changes to revert.
```
The core contract only explicitly names 3 agents for rollback trigger and 2 for no-rollback. It does not mention the other agents: spec-analyst, architect, acceptance-gate, browser-verifier, reproducer, deployment-verifier, custom agents, hooks.

`commands/fix-ticket.md` Block handler (step X, lines 357–361): Says only `Follow core/block-handler.md` with no extra guidance on rollback scope. The per-agent no-rollback logic from the core contract would apply, but fix-ticket adds no clarification.

`commands/implement-feature.md` Block handler (step X, lines 382–404): Explicitly lists "Run rollback-agent (Task tool, model: haiku) — revert git changes" at step 1 with no qualification about which agents trigger it, relying on block-handler.md. However, it also does not mention spec-analyst or architect (the feature pipeline's analysis agents that have no git changes).

`commands/fix-bugs.md` Block handler (step X, lines 394–430): Line 397–399 explicitly states: "DO NOT rollback on block from triage/code-analyst — no git changes to revert" — this is the most explicit of the three commands.

**Gap:** The no-rollback rule is fully documented in `core/block-handler.md` for triage-analyst/code-analyst, but for the feature pipeline the equivalent agents (spec-analyst, architect) are not mentioned in either the core contract or in implement-feature.md's block handler section.

**Recommendation:** E2E test should verify `core/block-handler.md` explicitly lists all read-only/no-git-change agents (including spec-analyst, architect, acceptance-gate) as no-rollback agents. Also verify implement-feature.md's block handler mentions the no-rollback rule for spec-analyst and architect.

---

## RQ-09: Decomposition state writes in bug pipelines

**Verdict:** CONFIRMED GAP

**Evidence:**
`state/schema.md` lines 185–189: `decomposition` object is defined with fields `status`, `decision`, `subtasks`, `strategy` — listed as "Yes" for required in the top-level schema.

`commands/implement-feature.md` line 234: Explicitly writes `decomposition.status`, `decomposition.decision`, `decomposition.strategy`, `decomposition.subtasks` to state.json after the decomposition step.

`commands/fix-ticket.md`: Searching the entire file finds NO state.json write for `decomposition.*` fields. The decomposition decision (steps 4b–4c) never writes to state.json. The fixer-reviewer state write (line 259) only covers `fixer_reviewer.*` fields.

`commands/fix-bugs.md`: Searching the entire file finds NO state.json write for `decomposition.*` fields. The per-bug decomposition (steps 3b–3c) processes decomposition but never writes to state.json.

Both bug pipeline commands use decomposition logic but neither writes the `decomposition.*` state fields, making the schema's required `decomposition` object permanently `{ status: "pending", decision: null, subtasks: [], strategy: null }` for all bug runs — even when decomposition actually happened.

**Recommendation:** E2E test should verify that both `fix-ticket.md` and `fix-bugs.md` contain explicit state.json write instructions for `decomposition.status`, `decomposition.decision`, `decomposition.strategy`, and `decomposition.subtasks` after the decomposition decision step.

---

## RQ-10: decomposition-heuristics Input Contract vs feature pipeline

**Verdict:** CONFIRMED GAP

**Evidence:**
`core/decomposition-heuristics.md` Input Contract (lines 6–13):
```
| decompose_flag | enum | FORCE / DISABLED / AUTO |
| code_analyst_output | object | risk, affected_files, estimated_diff_lines, independent_changes |
```
The contract requires `code_analyst_output` as input — specifically the output from code-analyst.

`commands/implement-feature.md` step 5 (lines 193–215): Invokes `core/decomposition-heuristics.md` via "Follow `core/decomposition-heuristics.md`:" but the feature pipeline has NO code-analyst step. The feature pipeline runs spec-analyst (step 3) and architect (step 4) instead. There is no `code_analyst_output` object available at step 5 in the feature pipeline.

The feature pipeline's decomposition decision is based on the architect output (task tree), not code-analyst output. Yet the contract references `code_analyst_output` as if it were always available. The feature pipeline provides architect output to the heuristics step but this is not reflected in the contract.

The `decomposition-heuristics.md` Failure Handling says "Missing or incomplete code_analyst_output fields → treat missing numeric fields as 0" — meaning the feature pipeline would silently fall through to `SINGLE_PASS` on AUTO mode unless the architect output is explicitly mapped to the required fields.

**Recommendation:** E2E test should verify `core/decomposition-heuristics.md` Input Contract documents a second input variant for the feature pipeline (architect output), or that `commands/implement-feature.md` explicitly maps architect output fields to the `code_analyst_output` contract before invoking decomposition-heuristics.

---

## RQ-11: Port validation duplication

**Verdict:** CONFIRMED BUG (logic duplication with diverging detail)

**Evidence:**
`commands/check-deploy.md` Step 1 (lines 37–39):
```
Validate port value first: confirm the value contains digits only and is in the range 1–65535.
If any port fails validation → output "Invalid port value: {port}. Ports must be numeric (1-65535)." and STOP immediately
```
Then runs the port scan shell command only after validation passes.

`agents/deployment-verifier.md` Process step 2 (lines 23–25):
```
Validate port value first: confirm it matches digits-only and is in range 1–65535.
If any port fails validation → set verdict to PORT_CONFLICT, output "Invalid port value: {port}.
Ports must be numeric (1-65535).", and STOP
```

Both perform identical port validation with nearly identical error messages. Key differences:
1. The command stops with a plain output message; the agent sets `verdict = PORT_CONFLICT` before stopping.
2. The command validates before any Bash execution; the agent validates within its port scan step.
3. The command checks `action = start` before blocking on occupied ports (Step 2 line 71–73); the agent checks in pre-start validation (step 3) but also handles the `stop` action.

The duplication creates a risk of the two diverging — e.g., if the valid port range or error message is updated in one place but not the other.

**Recommendation:** E2E test should verify the port validation rule (range 1–65535, digits-only, same error message text) is consistent between `check-deploy.md` and `deployment-verifier.md`. Longer term, the validation should live only in one place (ideally the agent, since the command delegates to the agent for all lifecycle actions).

---

## RQ-12: Profile-parser stage set vs pipeline applicability

**Verdict:** CONFIRMED GAP

**Evidence:**
`core/profile-parser.md` step 6 (line 18):
```
Validate each stage name against valid set: triage, code-analyst, spec-analyst,
test-engineer, e2e-test-engineer, reproducer, browser-verifier.
Invalid names → log warning "[WARN] Unknown stage '{name}' in profile — ignored"
```
This is a single global valid stage set with no differentiation by pipeline type.

`commands/implement-feature.md` Stage mapping (lines 51–57):
```
spec-analyst = step 3
code-analyst = (N/A — feature pipeline does not have code-analyst)
triage = (N/A — feature pipeline does not have triage)
test-engineer = step 6e
e2e-test-engineer = step 6f
```
The feature pipeline explicitly marks `code-analyst` and `triage` as N/A.

`commands/fix-bugs.md` Stage mapping (lines 58–65):
```
triage = step 2, code-analyst = step 3, test-engineer = step 7,
e2e-test-engineer = step 7a, reproducer = step 3e, browser-verifier = step 7a-browser
```
Bug pipeline has no `spec-analyst`.

**Gap:** `profile-parser.md` accepts `triage` and `code-analyst` as valid skip targets even when running for a feature pipeline (where they don't exist), and accepts `spec-analyst` even when running for a bug pipeline. Profile validation in the core does not know which pipeline it is being applied to. This means a profile could silently skip `triage` on a feature pipeline or `spec-analyst` on a bug pipeline — both are no-ops but generate no warning.

The `pipeline_name` field is present in the Input Contract but the Process steps never use it for stage name validation.

**Recommendation:** E2E test should verify that `profile-parser.md` uses `pipeline_name` to validate stage names against the pipeline-specific valid set, or that the commands emit a warning when a skip-stage is N/A for the current pipeline type.
