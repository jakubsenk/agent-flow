# Phase 2 Research Answers — Agent 2 (RQ-13 through RQ-31)

---

### RQ-13: State.json phase field specific tests
**Verdict:** CONFIRMED GAP
**Evidence:** `tests/scenarios/state-schema.sh` checks only: (1) `state/schema.md` exists and contains `schema_version`, (2) `core/state-manager.md` exists with 4 sections and `.tmp`/rename patterns, (3) the 4 pipeline commands each have ≥5 state references, (4) `resume-ticket.md` references `state.json` with fallback language. It does **not** test any specific field names, phase object structures, or enum values defined in `state/schema.md`. Fields with no test whatsoever include:
- `triage.severity`, `triage.area`, `triage.complexity`, `triage.acceptance_criteria`, `triage.reproduction_steps`
- `code_analysis.risk`, `code_analysis.affected_files`, `code_analysis.estimated_diff_lines`
- `reproduction.script_path`, `reproduction.result_path`, `reproduction.verdict` (REPRODUCED/NOT_REPRODUCED/INCONCLUSIVE)
- `fixer_reviewer.iterations`, `fixer_reviewer.max_iterations`, `fixer_reviewer.last_verdict`, `fixer_reviewer.ac_fulfillment`
- `decomposition.decision`, `decomposition.subtasks`, `decomposition.strategy`
- `test.attempts`, `test.max_attempts`, `test.last_result`
- `e2e_test.status`, `browser_verification.result_path`, `browser_verification.verdict`
- `acceptance_gate.verdict`, `publisher.pr_url`, `publisher.branch`
- `hooks.*` (pre_fix, post_fix, pre_publish, post_publish)
- `deployment.*` (all 9 subfields)
- `block` object fields (agent, step, reason, detail, recommendation)
- Step Status Enum values (`in_progress`, `skipped`, `blocked`, `not_applicable`)
- `config.flags`, `config.profile`, `config.retry_limits.*`
- `infrastructure.*` (all 7 subfields)
- `parent_run_id`
- `mode` enum values (`code-bugfix`, `code-feature`, `code-project`, `analysis`, `strategy`, `content`)
- `status` enum values (`completed`, `blocked`, `failed`)
**Recommendation:** Add a test that validates the schema's documented field names exist in the schema.md table, and that Step Status Enum values are documented. Ideally also validate that field update instructions in commands match schema field names.

---

### RQ-14: Config Validity Gate test coverage
**Verdict:** CONFIRMED GAP
**Evidence:** The gate is defined in `commands/implement-feature.md` Step 0b and `commands/fix-ticket.md` Step 0b (which cross-references implement-feature). The gate performs these checks: (1) reads `## Automation Config` from CLAUDE.md; (2) for each required section (Issue Tracker, Source Control, PR Rules, Build & Test), scans all `| Key | Value |` rows for values containing `<!-- TODO:` markers, `<...>` placeholders, or empty values; (3) collects them into `incomplete_keys[]`; (4) if non-empty → BLOCK with `[ceos-agents]` format listing incomplete keys; (5) for optional sections with `<!-- TODO:` markers → warn but do NOT block; (6) if all complete → proceed. No test in `tests/scenarios/` references "Config Validity Gate", "Step 0b", "incomplete_keys", "TODO", or "placeholder" in the context of gate validation.
**Recommendation:** Add a test that: (a) verifies "Config Validity Gate" language appears in both `implement-feature.md` and `fix-ticket.md`; (b) verifies `fix-ticket.md` Step 0b cross-references `implement-feature.md`; (c) verifies the BLOCK output format matches the standard block comment template.

---

### RQ-15: --yolo flag test coverage
**Verdict:** CONFIRMED GAP
**Evidence:** In `commands/fix-ticket.md`: `--yolo` skips all user confirmations — specifically (a) auto-approves the decomposition plan (Step 4b), (b) auto-publishes after successful pipeline (Step 9, "If `--yolo` → auto-publish"), (c) in AC coverage check if unmapped AC found → Block instead of asking user (Step 4b). In `commands/implement-feature.md`: `--yolo` does (a) auto-approve decomposition plan (Step 5, "If `--yolo` → auto-approve"), (b) auto-create PR without asking (Step 9), (c) in AC coverage check → Block on unmapped AC (Step 5), (d) in Step 0c duplicate check → skip duplicate check entirely, (e) in MCP pre-flight fail with `description_mode=true` → BLOCK instead of interactive fallback. No test scenario in `tests/scenarios/` mentions `--yolo` or validates any of these behaviors.
**Recommendation:** Add tests verifying: (a) `--yolo` appears in both commands' flag descriptions; (b) both commands document auto-approve and auto-publish behavior; (c) implement-feature documents YOLO-mode duplicate check skip; (d) `state/schema.md` documents `--yolo` as a valid `config.flags` entry.

---

### RQ-16: implement-feature dedicated tests
**Verdict:** CONFIRMED GAP
**Evidence:** Searching all test scenario files for "implement-feature" returns exactly 5 files: `core-include-refs.sh` (checks ≥6 core/ references in the file), `no-mcp-jargon-errors.sh` (checks friendly error message pattern), `profile-skip.sh` (checks `--profile` and `NEVER.*skip` language), `state-schema.sh` (checks ≥5 state.json references), `verify-fail.sh` (checks "Feature Verification" text exists). Zero dedicated scenario files test implement-feature-specific logic: spec-analyst dispatch, architect dispatch, decomposition decision, AC coverage check, `--description` flag, Step 0c duplicate check, single-pass vs decomposed execution, acceptance gate (always-on for features), or the feature pipeline's unique state field reuse (`triage.status` for spec-analyst output).
**Recommendation:** Create `tests/scenarios/implement-feature-structure.sh` that validates implement-feature-specific sections: Step 0c (--description), acceptance gate always-on rule, Feature Workflow fallback, spec-analyst AC writeback, `--yolo` behaviors.

---

### RQ-17: deployment-verifier test coverage
**Verdict:** CONFIRMED GAP
**Evidence:** `agents/deployment-verifier.md` frontmatter: `name: deployment-verifier`, `model: sonnet`, `style: Diagnostic, port-aware, non-destructive`. Key properties: 11-step process including port validation (digits-only, range 1–65535), pre-start validation, docker vs native start, health check polling (every 2s, max `timeout/2` attempts), cleanup-on-failure, docker inspection with restart loop detection, secret redaction in logs (PASSWORD=, TOKEN=, SECRET=, API_KEY=, PRIVATE_KEY=, Authorization:), 5 verdict values (HEALTHY/UNHEALTHY/PORT_CONFLICT/START_FAILED/SKIPPED), result.json output path `.ceos-agents/deploy/{timestamp}/result.json`. `commands/check-deploy.md` dispatches it via Task tool with action context. No test scenario references `deployment-verifier`, `check-deploy`, `PORT_CONFLICT`, `START_FAILED`, `HEALTHY`, or `local_deployment`.
**Recommendation:** Add `tests/scenarios/deployment-verifier-structure.sh` verifying: (a) agent frontmatter (name, model=sonnet, style); (b) all 5 verdict values documented; (c) secret redaction patterns present; (d) port validation rule (digits-only, 1–65535) in both agent and command; (e) check-deploy dispatches via Task tool with correct agent name.

---

### RQ-18: Mock project missing optional sections
**Verdict:** CONFIRMED GAP
**Evidence:** `tests/mock-project/CLAUDE.md` contains these optional sections: Retry Limits, Hooks, Worktrees, Feature Workflow, Decomposition, Pipeline Profiles, Metrics. The CLAUDE.md optional sections table lists these **absent** from mock-project: Custom Agents, E2E Test, Browser Verification, Error Handling, Extra labels, Notifications, Agent Overrides, Local Deployment, Module Docs.
**Recommendation:** This is intentional for minimal viable config, but tests using the mock project cannot exercise optional section parsing for the missing sections. Consider adding a second extended mock project or separate section tests.

---

### RQ-19: Mock project Retry Limits completeness
**Verdict:** CONFIRMED GAP
**Evidence:** `tests/mock-project/CLAUDE.md` Retry Limits section contains: `Fixer iterations: 3`, `Test attempts: 2`, `Build retries: 2`. The `core/config-reader.md` defines 4 keys for Retry Limits: `retry.fixer_iterations`, `retry.test_attempts`, `retry.build_retries`, and `retry.spec_iterations` (default: 5). The mock-project **omits `Spec iterations`**. Commands (`fix-ticket.md`, `fix-bugs.md`) also reference `Root cause iterations` (default: 3) but config-reader maps only `spec_iterations`, not root cause iterations as a separate key.
**Recommendation:** Add `Spec iterations` to the mock project's Retry Limits section; also clarify in config-reader whether "Root cause iterations" is a distinct config key or an alias for something else.

---

### RQ-20: Verify command null handling
**Verdict:** INTENTIONAL (documented)
**Evidence:** `core/fix-verification.md` Process Step 1: "If Build & Test → Verify command is not configured → return `SKIPPED`." The config-reader.md parses `build.verify_command` as an optional key within the `### Build & Test` section (listed as "optional key within this section"). When absent, the fix-verification core returns `SKIPPED` without blocking or erroring. Both `fix-ticket.md` (Step 9d) and `fix-bugs.md` (Step 8c) gate on "If Build & Test → Verify exists" before calling fix-verification.
**Recommendation:** Test should verify that `fix-ticket.md` and `fix-bugs.md` both include the conditional "If Build & Test → Verify exists" guard, and that `core/fix-verification.md` documents the SKIPPED return for missing config.

---

### RQ-21: PR Description Template parsing
**Verdict:** CONFIRMED GAP
**Evidence:** `core/config-reader.md` Step 2 defines: `### PR Description Template` → `pr_rules.description_template` (verbatim multi-line text under the subsection heading). It does not specify how backtick fences (``` marks) surrounding the template in CLAUDE.md are handled — whether they are stripped or included in the template value. The mock project wraps the template in triple backticks. No guidance exists on whether the parser strips fence markers, preserving only the content between them.
**Recommendation:** Clarify in config-reader.md whether backtick fences around the PR Description Template are stripped. Add a test that checks the mock project's template section contains backtick fences, and verify config-reader documents fence-stripping behavior.

---

### RQ-22: Feature Workflow fallback chain
**Verdict:** INTENTIONAL (documented)
**Evidence:** The fallback is documented in two places: (1) `commands/implement-feature.md` Configuration section: `Feature Workflow: Feature query, On start set (fallback: Issue Tracker → On start set)` — explicit parenthetical fallback. (2) `commands/implement-feature.md` Step 1: "Set the state per Feature Workflow → On start set (fallback: Issue Tracker → On start set)". `core/config-reader.md` parses `feature.on_start_set` as an optional field with "default: none" — the fallback to Issue Tracker is command-level logic, not config-reader logic.
**Recommendation:** Test should verify that implement-feature.md Step 1 documents the fallback to `Issue Tracker → On start set` when Feature Workflow → On start set is absent. Also verify that `core/config-reader.md` does NOT define the fallback (it is correctly command-level).

---

### RQ-23: Rollback-agent namespace prefix
**Verdict:** CONFIRMED GAP
**Evidence:** In `commands/fix-bugs.md` Block handler Step X, Step 1: `Run \`ceos-agents:rollback-agent\` (Task tool, model: haiku)` — uses full namespace prefix. In `commands/implement-feature.md` Block handler Step X, Step 1: `Run rollback-agent (Task tool, model: haiku) — revert git changes` — **missing the `ceos-agents:` namespace prefix**. The text in implement-feature simply reads "Run rollback-agent" without the qualified name. `commands/fix-ticket.md` Block handler says "Follow `core/block-handler.md` for the block protocol" — no inline rollback call, it delegates fully to the core module.
**Recommendation:** This is a CONFIRMED BUG. Fix `commands/implement-feature.md` Block handler Step X, Step 1 to use `ceos-agents:rollback-agent` (with namespace prefix) for consistency with fix-bugs.md and CLAUDE.md plugin composability conventions. Add a test to `tests/scenarios/pipeline-consistency.sh` verifying that rollback-agent references in commands use the full namespace prefix.

---

### RQ-24: Secret redaction scope
**Verdict:** CONFIRMED GAP (partially documented)
**Evidence:** `agents/deployment-verifier.md` Step 7 (Docker inspection): "Before including log output in the report, redact values matching common secret patterns: lines containing `PASSWORD=`, `TOKEN=`, `SECRET=`, `API_KEY=`, `PRIVATE_KEY=`, or `Authorization:` headers. Replace the matched value portion with `[REDACTED]`". The Constraints section also says "NEVER expose secrets or credentials found in container logs or process output." Step 7 is explicitly "only if Type = docker". Step 4 (native start) captures process output but has **no explicit redaction instruction**. Port scan output (Steps 2, 8) also has no redaction rule. So redaction is documented only for Docker log inspection, not for native process output.
**Recommendation:** Add a redaction requirement to Step 4 (native Type) covering process output and any environment variables printed during start. Add a test verifying that the agent definition mentions secret redaction and lists the specific patterns (PASSWORD=, TOKEN=, etc.).

---

### RQ-25: acceptance_gate.status enum usage
**Verdict:** CONFIRMED GAP
**Evidence:** `state/schema.md` defines `acceptance_gate.status` using the Step Status Enum: `pending`, `in_progress`, `completed`, `failed`, `skipped`, `blocked`, `not_applicable`. In `commands/fix-ticket.md` Step 8b: sets `acceptance_gate.status` to `"completed"` when gate runs, or `"skipped"` when condition not met (< 3 AC and complexity < M). In `commands/implement-feature.md` Step 6g: sets `acceptance_gate.status` to `"completed"` or `"skipped"` (for single-pass mode without decomposition). In `commands/fix-bugs.md` Step 7b: same as fix-ticket — `"completed"` or `"skipped"`. The value `"not_applicable"` is defined in the schema but **never used** in any command. `"blocked"` is also in the enum but no command sets it for acceptance_gate specifically. The schema's Step Status Enum is shared across all phase objects but `not_applicable` has no usage site in any command.
**Recommendation:** Either document when `not_applicable` applies to acceptance_gate (e.g., for pipelines that structurally cannot have an acceptance gate), or remove it from the schema if unused. Add a test verifying that the values set in commands (`completed`, `skipped`) are a subset of the Step Status Enum values in schema.md.

---

### RQ-26: Mode enum initialization
**Verdict:** INTENTIONAL (documented, consistent)
**Evidence:** `state/schema.md` defines `mode` as one of: `code-bugfix`, `code-feature`, `code-project`, `analysis`, `strategy`, `content`. Commands set mode as follows: `fix-ticket.md` Step 0: `mode: "code-bugfix"`. `fix-bugs.md` Step 0: `mode: "code-bugfix"`. `implement-feature.md` Step 0: `mode: "code-feature"`. `commands/check-deploy.md` Step 0: `mode: "analysis"`. `commands/scaffold.md` is not fully read but scaffold pipeline would use `code-project`. The modes `strategy` and `content` are in the schema but no command explicitly sets them (likely for workflow-router / other use cases). `commands/scaffold.md` initializes state.json within its pipeline flow (per `state-schema.sh` test which checks scaffold references state.json ≥5 times).
**Recommendation:** Test should verify each pipeline command sets the correct mode value on state.json initialization. Document which commands own `strategy` and `content` modes, or note they are reserved for future use.

---

### RQ-27: --description 50-char threshold
**Verdict:** INTENTIONAL (documented)
**Evidence:** `commands/implement-feature.md` Step 0c, sub-step 4: "Duplicate check (non-YOLO mode only): Search the tracker for existing issues whose title starts with the same **first 50 characters** as the extracted title." The title itself is extracted as "first sentence or first 80 characters" (sub-step 3). The 50-char match is used only for the duplicate check query — not for the card title (which uses 80 chars). In YOLO mode, the duplicate check is skipped entirely. If a duplicate is found, the user is shown the existing issue and asked to confirm ("Create anyway? [y/N]").
**Recommendation:** Test should verify that implement-feature.md Step 0c documents both the 80-char title extraction and the 50-char duplicate check threshold as distinct values. Verify that the YOLO-mode skip of duplicate check is explicitly documented.

---

### RQ-28: .claude/decomposition/ path
**Verdict:** INTENTIONAL (consistent across commands)
**Evidence:** `commands/implement-feature.md` Step 5: "Save task tree: Write to `.claude/decomposition/{ISSUE-ID}.yaml`". Step 6h also references: "Update the task tree state on disk (.claude/decomposition/)". `commands/fix-ticket.md` Step 4b: "Save task tree to `.claude/decomposition/{ISSUE-ID}.yaml`". `commands/fix-bugs.md` Step 3b: "Save task tree to `.claude/decomposition/{ISSUE-ID}.yaml`". All three commands use the identical path `.claude/decomposition/{ISSUE-ID}.yaml`. Note: this is `.claude/` (Claude Code's local directory), **not** `.ceos-agents/` (the plugin's run directory). This is intentional — task trees are Claude Code workspace artifacts, not pipeline run state.
**Recommendation:** Test should verify all three pipeline commands (fix-ticket, fix-bugs, implement-feature) document the same `.claude/decomposition/{ISSUE-ID}.yaml` path for task tree storage. Consider whether this should be `.ceos-agents/{ISSUE-ID}/decomposition.yaml` for consistency with other run artifacts.

---

### RQ-29: Profile-parser warning test
**Verdict:** CONFIRMED GAP
**Evidence:** `tests/scenarios/profile-skip.sh` checks: (1) each of fix-ticket, fix-bugs, implement-feature contains "Pipeline profile parsing" or "--profile" text; (2) each contains "NEVER.*skip" text. It does **not** test: (a) the warning behavior from `core/profile-parser.md` Step 6 ("Unknown stage name → log warning '[WARN] Unknown stage '{name}' in profile — ignored', skip that entry"); (b) the mandatory stage protection BLOCK behavior (Step 5: if fixer/reviewer/publisher in skip list → BLOCK); (c) that profile-parser.md itself contains the warning message; (d) that the valid stage name set is documented; (e) that `--profile <name>` causes error "Profile '{name}' not found" when missing. The test is structural only (text presence), not behavioral.
**Recommendation:** Add assertions to profile-skip.sh or a new test that: (a) verifies core/profile-parser.md contains the "[WARN] Unknown stage" warning text; (b) verifies the mandatory stage protection BLOCK message is in profile-parser.md; (c) verifies the valid stage name list is documented in profile-parser.md.

---

### RQ-30: Hook execution order
**Verdict:** INTENTIONAL (consistent, documented)
**Evidence:** `commands/fix-ticket.md` documents hooks in this order: Pre-fix (Step 4d, before fixer) → Post-fix (Step 6a, after build) → Post-fix custom agent (Step 6b) → Pre-publish (Step 8c, before publisher) → Pre-publish custom agent (Step 8d) → Post-publish (Step 9a, after publisher, via `core/post-publish-hook.md`). `commands/fix-bugs.md` uses the same order: Pre-fix (Step 3d) → Post-fix (Step 5a) → Post-fix custom agent (Step 5b) → Pre-publish (Step 7c) → Pre-publish custom agent (Step 7d) → Post-publish (Step 8a). `commands/implement-feature.md` documents: Pre-fix (Step 6a) → Post-fix + custom agent (Step 6c, combined) → Pre-publish + custom agent (Step 8, combined) → Post-publish (Step 10a, via `core/post-publish-hook.md`). The Rules section of fix-ticket.md confirms: "Hook before agent, not in the reviewer loop".
**Recommendation:** Test should verify that all three commands document hooks in the same conceptual order (pre-fix → post-fix → pre-publish → post-publish) and that the "Hook before agent, not in the reviewer loop" rule appears in at least fix-ticket.md and fix-bugs.md.

---

### RQ-31: AC propagation chain
**Verdict:** INTENTIONAL (documented, full chain traceable)
**Evidence:** In `commands/fix-ticket.md`: Step 3 (Triage) extracts `acceptance_criteria` and stores to `triage.acceptance_criteria` in state.json. Step 3 says "Pass to all downstream agents." Step 5 (Fixer) context explicitly includes "Acceptance criteria: {AC from triage}". Step 7 (Reviewer) context: "Acceptance criteria: {AC from triage}". Step 8a-browser (Browser Verifier) context: "Acceptance criteria: {AC from triage}". Step 8b (Acceptance gate) context: "Acceptance criteria: {AC from triage}". In `commands/implement-feature.md`: Step 3 (Spec-analyst) produces `acceptance_criteria`, stored to `triage.acceptance_criteria` (field reused). Step 4 (Architect) receives specification. Step 6b (Fixer) context: "acceptance criteria". Step 6d (Reviewer) context: "acceptance criteria from spec-analyst". Step 6g (Acceptance gate) context: "Acceptance criteria: {AC from spec-analyst — full feature AC, not just per-subtask AC}". The AC are always passed as inline context strings to each Task call, not re-read from state.json — state.json is for resume/persistence only.
**Recommendation:** Test should verify that fix-ticket.md documents AC flow from triage → fixer → reviewer → acceptance-gate, and that implement-feature.md documents AC flow from spec-analyst → architect → fixer → reviewer → acceptance-gate. Verify that the acceptance gate context explicitly references the full AC list (not just per-subtask AC) in implement-feature.
