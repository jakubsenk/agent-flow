# Agent Audit — Q2 & Q3

Research date: 2026-04-13
Auditor: research-agent (claude-sonnet-4-6)

---

## Q2: Shared Agent Cross-Mode Analysis

The seven agents below appear in more than one pipeline. For each, the analysis
covers which pipelines use it, whether its Process steps work correctly in each
pipeline's context, bug-specific language that leaks into non-bug modes, and a
final rating.

---

### 2.1 fixer

**Pipelines:** fix-ticket, fix-bugs, implement-feature, scaffold (epic sub-tasks)

**Pipeline-by-pipeline assessment:**

| Pipeline | Context passed | Process fit |
|----------|---------------|-------------|
| fix-ticket / fix-bugs | triage analysis + impact report (bug-specific) | Steps 1-8 work correctly. Step 1 says "Read the triage analysis and impact report" — both exist. RED phase writes a regression test for the bug. All language fits. |
| implement-feature | spec-analyst output + architect task plan | Step 1 hard-codes "triage analysis and impact report" — neither exists. The skill passes "spec-analyst output + architect decomposition plan" but fixer's Step 1 blocks if "triage analysis or impact report is missing". This is a real risk: the fixer may Block claiming missing input. |
| scaffold | architect decomposition plan inside the scaffold pipeline | Same problem as implement-feature. Also, the RED phase (write a test that reproduces the bug) makes no sense for brand-new feature code. |

**Bug-specific concepts that don't apply in feature/scaffold mode:**

- Step 1 explicitly names "triage analysis" and "impact report" — these are bug-pipeline outputs.
- Step 5 RED phase: "Write a test that reproduces the bug" — bugs have a reproduction scenario; features have acceptance criteria, not bugs to reproduce. A fixer in feature mode should write a test verifying the new behaviour exists, not a test that fails on a bug.
- Step 5 RED phase: "Run it — confirm it FAILS. If the test passes, your test does not capture the actual bug; rewrite it." — this instruction is logically inverted for feature work where there is no existing bug to reproduce.
- The "NEEDS_DECOMPOSITION" signal references "the fix is larger than expected" — this language is coherent for feature work too but the surrounding framing (ticket scope, 100-line diff) is shared.
- Block Comment Template Step reads "Step: Fix Implementation" — generic enough, acceptable.

**Steps needing different behaviour per mode:**

- Step 1 (input reading): needs to accept spec-analyst/architect output as valid input in feature/scaffold mode.
- Step 5 RED phase: in feature mode, the test should verify new behaviour is absent before the feature is added, not reproduce a bug.

**Rating: BROKEN**

Reason: Step 1 will literally block the pipeline in implement-feature and scaffold modes because it checks for "triage analysis or impact report" and both are absent. The RED phase instruction ("confirm it FAILS" to capture "the actual bug") also gives wrong instructions for feature implementation.

---

### 2.2 reviewer

**Pipelines:** fix-ticket, fix-bugs, implement-feature, scaffold (epic sub-tasks)

**Pipeline-by-pipeline assessment:**

| Pipeline | Context passed | Process fit |
|----------|---------------|-------------|
| fix-ticket / fix-bugs | original bug report + triage analysis + impact report + fixer output | Step 1 reads "original bug report, triage analysis, impact report, fixer output" — all available. Fits well. |
| implement-feature | spec-analyst output + architect plan + fixer output | Step 1 reads "original bug report, triage analysis, impact report" — none of these exist. The skill passes "diff from fixer + acceptance criteria from spec-analyst". The reviewer is told to read documents that are not present. |
| scaffold | architect plan + fixer output | Same missing-document problem. |

**Bug-specific concepts that don't apply in feature/scaffold mode:**

- Step 1: "original bug report, triage analysis, impact report" — all bug-pipeline artefacts.
- Step 4 checklist item "Root cause: Does the fix address the actual root cause, not just symptoms?" — features have no root cause; an analogous check would be "does the implementation satisfy the AC?", but that is partially covered by the AC Fulfillment section.
- Step 4 checklist item "Completeness: Are all affected paths covered (from impact report)?" — impact report is bug-specific.
- Description in frontmatter: "Ensures root cause fix, convention compliance, no regressions" — "root cause fix" is bug language.

**Steps needing different behaviour per mode:**

- Step 1: should read spec-analyst output / architect plan instead of bug report / triage / impact report when in feature mode.
- Step 4 checklist: "Root cause" and "Completeness (from impact report)" items need feature-mode equivalents ("Does the implementation match the feature specification?" / "Are all AC-specified paths covered?").

**Rating: NEEDS_UPDATE**

Reason: The agent does not hard-block (unlike fixer Step 1 which triggers an explicit Block), but it reads documents that don't exist and evaluates against a "root cause" framing that is semantically wrong for features. The AC Fulfillment section partially compensates. The agent will still produce a useful review, but with confusing language and potential gaps for feature-only paths.

---

### 2.3 test-engineer

**Pipelines:** fix-ticket, fix-bugs, implement-feature, scaffold

**Pipeline-by-pipeline assessment:**

| Pipeline | Context passed | Process fit |
|----------|---------------|-------------|
| fix-ticket / fix-bugs | bug report + fixer output + impact report | Step 1 reads "bug report, fixer output (changed files, root cause), impact report" — all available. Fits correctly. |
| implement-feature | spec-analyst output + fixer output | Step 1 reads "bug report" and "root cause" — neither term applies. "Impact report (test coverage section)" is also absent. The skill passes "fixer output + AC from spec-analyst". |
| scaffold | fixer output (feature implementation) | Same terminology mismatch. |

**Bug-specific concepts that don't apply in feature/scaffold mode:**

- Step 1: "Read the bug report" — no bug report in feature/scaffold pipelines.
- Step 1: "fixer output (changed files, root cause)" — features have changed files but no root cause.
- Step 1: "impact report (test coverage section)" — impact report is a bug-pipeline artefact.
- Step 3: "One test verifying the specific behavior that was fixed (regression test)" — in feature mode, this should read "One test verifying the new behaviour that was added". The word "regression test" and "fixed" are semantically off for new feature code.
- Goal text: "Write tests that verify the fix AND prevent future regressions" — should be "verify the implementation AND prevent future regressions" for feature mode. Not wrong per se but bug-centric phrasing.
- Description: "Writes and runs unit tests verifying the fix and preventing regressions" — accurate for bug fix, misleading for feature work.

**Steps needing different behaviour per mode:**

- Step 1: in feature mode, should read spec-analyst AC and architect plan instead of bug report + impact report.
- Step 3 Required test: for feature mode, the required test should be "verifying the new feature behaviour is present" rather than a regression test for a bug.

**Rating: NEEDS_UPDATE**

Reason: The agent will still produce valid tests in feature mode (it reads fixer output and writes tests for changed files), but the input-reading step references absent documents and the test planning terminology is bug-centric. No hard block is triggered, but the quality of context gathering is degraded.

---

### 2.4 e2e-test-engineer

**Pipelines:** fix-ticket, fix-bugs, implement-feature, scaffold

**Pipeline-by-pipeline assessment:**

| Pipeline | Context passed | Process fit |
|----------|---------------|-------------|
| fix-ticket / fix-bugs | bug report + fix diff + Automation Config | Step 1 reads "bug report and fix diff" — both present. Fits. |
| implement-feature | feature spec + fixer diff | Step 1 reads "bug report and fix diff" — "bug report" is absent; the skill passes spec output instead. |
| scaffold | architect plan + fixer diff | Same mismatch. |

**Bug-specific concepts that don't apply in feature/scaffold mode:**

- Step 1: "Read the bug report and fix diff — understand which user flow was affected" — "bug report" implies a defect was reported; in feature mode the relevant document is the feature spec or AC list.
- Goal: "E2E tests verifying the complete user flow affected by the fix" — "affected by the fix" implies a pre-existing bug. For features it should be "the user flow introduced by the implementation".
- Step 6 Required test: "One test verifying the happy path of the affected user flow" — "affected" implies fix. For features: "the user flow introduced by the feature".

**Steps needing different behaviour per mode:**

- Step 1: should read spec-analyst output or architect plan when in feature/scaffold mode.
- Step 6 Required test description: minor language update for feature context.

**Rating: NEEDS_UPDATE**

Reason: The core behaviour (deploy check → find existing tests → write happy-path + error-path E2E test → run) is fully valid in all modes. Only the input-reading step and framing language are bug-centric. No hard block is triggered, but the agent gets less useful context in feature mode.

---

### 2.5 rollback-agent

**Pipelines:** fix-ticket, fix-bugs, implement-feature, scaffold (partially)

**Pipeline-by-pipeline assessment:**

| Pipeline | Context passed | Process fit |
|----------|---------------|-------------|
| fix-ticket / fix-bugs | blocking agent name + block reason + git state | Fits perfectly. Step 1 guard logic handles all relevant agent types. |
| implement-feature | same — skill explicitly calls rollback-agent on fixer/reviewer/test-engineer block | Step 1 guard logic includes `fixer`, `test-engineer`, `reviewer` — all correct. The skill passes block context in same format. Fits. |
| scaffold | scaffold skill calls rollback-agent on fixer/reviewer/test-engineer blocks; NOT for scaffolder blocks | Step 1 correctly identifies `scaffolder` as "STOP — do nothing". Guard logic for `fixer`, `test-engineer`, `reviewer` works. Fits. |

**Bug-specific concepts that don't apply in feature/scaffold mode:**

- None found. The agent's role (git reset + block comment) is pipeline-mode-agnostic.
- The agent correctly accounts for the scaffolder case (no rollback needed).
- Step 5 Block Comment Template is generic.

**Steps needing different behaviour per mode:**

- None identified. The process is already mode-agnostic.

**Rating: GOOD**

The guard logic in Step 1 is comprehensive, the git operations are mode-independent, and the Block Comment Template is generic. No changes needed.

---

### 2.6 publisher

**Pipelines:** fix-ticket, fix-bugs, implement-feature, scaffold

**Pipeline-by-pipeline assessment:**

| Pipeline | Context passed | Process fit |
|----------|---------------|-------------|
| fix-ticket / fix-bugs | Automation Config + issue tracker details | Steps 1-8 fit well. Branch naming uses issue ID. PR title template says "Fix: {description}" which is bug-appropriate. |
| implement-feature | Automation Config + spec-analyst output + feature issue details | The PR title template is hard-coded as `[PROJ-123] Fix: {concise description}` — "Fix:" is semantically wrong for a new feature. Should be "feat:" or "Add:" for feature work. |
| scaffold | Automation Config only (no tracker issue in --no-implement mode) | Step 7 "Update Issue Tracker" may fail or be skipped if no issue exists. The skill handles the no-tracker case explicitly in its Step 4e, but the publisher agent itself does not have a guard for absent issue context. |

**Bug-specific concepts that don't apply in feature/scaffold mode:**

- Step 4 example commit message: `fix(auth): prevent token expiration on refresh` — Conventional Commits prefix "fix" is bug-specific. Feature work should use "feat(...)".
- Step 6 PR title format: `[PROJ-123] Fix: {concise description}` — "Fix:" is wrong for features and new scaffolds.
- Step 6 PR description template sections include "Root Cause, Changes" — "Root Cause" is a bug-pipeline concept not relevant to feature PRs.
- Description in frontmatter: "Creates branch, commits, pushes, creates PR with full traceability" — this is actually mode-agnostic. Good.

**Steps needing different behaviour per mode:**

- Step 4: commit message type should change from "fix(...)" to "feat(...)" in feature/scaffold mode.
- Step 6: PR title format should change from "Fix:" to "Feat:" in feature mode.
- Step 6: PR description template "Root Cause" field should become "Design Rationale" or be omitted for feature PRs.

**Rating: NEEDS_UPDATE**

Reason: The agent will produce a PR, but with semantically wrong "Fix:" prefix and "Root Cause" section for feature and scaffold pipelines. This is cosmetic but creates confusing PR history. No hard block, but consistently misleading output in non-bug modes.

---

### 2.7 acceptance-gate

**Pipelines:** fix-ticket (conditional), fix-bugs (conditional), implement-feature (always in decomposition, skipped in single-pass)

**Pipeline-by-pipeline assessment:**

| Pipeline | Context passed | Process fit |
|----------|---------------|-------------|
| fix-ticket / fix-bugs | AC from triage-analyst + changed files from fixer | Step 1 reads "AC from triage-analyst for bugs" — correct. Verdict logic fits. |
| implement-feature | AC from spec-analyst + changed files from fixer | Step 1 reads "AC from spec-analyst for features" — explicitly mentioned. Fits well. |
| scaffold | Not used in scaffold pipeline | N/A |

**Bug-specific concepts that don't apply in feature/scaffold mode:**

- Step 1: "Read the acceptance criteria from context (from triage-analyst for bugs, spec-analyst for features)" — already mode-aware. Good.
- Step 2: "Read all changed files from the fixer's output" — "fixer" is appropriate in both modes.
- Goal is fully generic ("Verify that every acceptance criterion is fulfilled").
- No bug-specific terminology found in Process or Constraints.

**Steps needing different behaviour per mode:**

- None. The agent already distinguishes triage-analyst (bugs) vs spec-analyst (features) in its process.

**Rating: GOOD**

The agent is the most mode-aware of all shared agents. Its process explicitly handles both bug and feature AC sources. No changes needed.

---

### Q2 Summary Table

| Agent | fix-ticket | fix-bugs | implement-feature | scaffold | Rating |
|-------|-----------|---------|-------------------|---------|--------|
| fixer | GOOD | GOOD | BROKEN (Step 1 will Block) | BROKEN (Step 1 will Block + wrong RED phase) | **BROKEN** |
| reviewer | GOOD | GOOD | NEEDS_UPDATE (wrong input docs, bug-centric checklist) | NEEDS_UPDATE | **NEEDS_UPDATE** |
| test-engineer | GOOD | GOOD | NEEDS_UPDATE (wrong input docs, regression framing) | NEEDS_UPDATE | **NEEDS_UPDATE** |
| e2e-test-engineer | GOOD | GOOD | NEEDS_UPDATE (wrong input doc ref) | NEEDS_UPDATE | **NEEDS_UPDATE** |
| rollback-agent | GOOD | GOOD | GOOD | GOOD | **GOOD** |
| publisher | GOOD | GOOD | NEEDS_UPDATE (Fix: prefix, Root Cause section) | NEEDS_UPDATE (Fix: prefix, no tracker guard) | **NEEDS_UPDATE** |
| acceptance-gate | GOOD | GOOD | GOOD | N/A | **GOOD** |

**Critical finding:** `fixer` Step 1 will trigger an explicit Block in implement-feature and scaffold pipelines because it checks for "triage analysis or impact report" — both of which are absent in those pipelines. This is a real pipeline failure path, not just a cosmetic issue.

---

## Q3: Agent Content Quality Assessment

All 19 agents evaluated. Scoring is 1 (poor) to 5 (excellent).

Model assignment codes:
- `correct` — model is appropriate for the task complexity and role
- `should_upgrade` — task complexity/criticality warrants a more capable model
- `should_downgrade` — task is mechanical enough for a cheaper model

---

### Scorecard Table

| Agent | Goal (1-5) | Expertise (1-5) | Process (1-5) | Constraints (1-5) | Model | Description (1-5) | Overall (1-5) | Top Issue |
|-------|-----------|----------------|--------------|-------------------|-------|-------------------|---------------|-----------|
| triage-analyst | 5 | 4 | 5 | 4 | correct | 4 | 5 | Description mentions "downloads and analyzes attachments" but not the AC/complexity outputs that are equally important to consumers |
| code-analyst | 5 | 5 | 5 | 4 | correct | 4 | 5 | None — strongest process definition in the codebase |
| fixer | 4 | 4 | 4 | 4 | correct | 3 | 4 | Description says "bug fixes" only — inaccurate for feature/scaffold pipelines where it implements new code; Step 1 will hard-Block in non-bug modes |
| reviewer | 4 | 4 | 4 | 4 | correct | 3 | 4 | Description says "root cause fix" — bug-centric; Step 1 reads documents absent in feature mode |
| test-engineer | 4 | 4 | 4 | 4 | correct | 3 | 4 | Description says "verifying the fix" — feature-mode mismatch; Step 1 reads missing documents |
| e2e-test-engineer | 4 | 5 | 5 | 5 | correct | 4 | 5 | Step 1 reads "bug report" — one-word fix needed for feature mode accuracy |
| rollback-agent | 5 | 4 | 5 | 4 | correct | 5 | 5 | None — guard logic is comprehensive and mode-agnostic |
| publisher | 4 | 4 | 4 | 4 | correct | 4 | 4 | PR title hardcodes "Fix:" — wrong for feature and scaffold pipelines |
| acceptance-gate | 5 | 5 | 5 | 5 | correct | 5 | 5 | None — best-in-class: explicit mode awareness, evidence-driven, clean constraints |
| spec-analyst | 5 | 5 | 5 | 4 | correct | 4 | 5 | Description lacks mention of the AC writeback to tracker — a key differentiator |
| architect | 5 | 5 | 5 | 5 | correct | 4 | 5 | Description says "complex bug decomposition" — undersells the primary use case (feature decomposition) |
| spec-writer | 5 | 5 | 5 | 5 | correct | 5 | 5 | None — comprehensive, well-constrained, Unicode note is excellent |
| spec-reviewer | 5 | 5 | 5 | 5 | correct | 4 | 5 | Description doesn't mention --verify mode which is a major secondary capability |
| scaffolder | 4 | 5 | 4 | 4 | correct | 4 | 4 | Scorecard item 8 (Test infra) has a stray "(if S3 implemented)" note — likely a copy-paste artefact; process is long and hard to parse (8+ batches) |
| stack-selector | 5 | 5 | 5 | 4 | correct | 5 | 5 | Constraints note about "pinned versions reflect latest stable at time of selection" could be stronger (warn to verify) |
| priority-engine | 4 | 4 | 4 | 4 | correct | 4 | 4 | Score formula comment ("may vary between runs") undercuts auditability claim; a fixed rubric per dimension would be stronger |
| reproducer | 5 | 5 | 5 | 5 | correct | 4 | 5 | Description doesn't mention that it can skip gracefully when Playwright is absent — which is its key design property |
| browser-verifier | 5 | 5 | 5 | 5 | correct | 4 | 5 | Description doesn't mention guided exploration (Sub-phase B) which is a major capability |
| deployment-verifier | 5 | 5 | 5 | 5 | correct | 4 | 5 | Description is accurate but doesn't mention the "action" parameter (check/start/stop) which callers need to understand |

---

### Detailed Findings Per Agent

#### triage-analyst (5/5 overall)
Strong agent. The Issue Quality Gate is well-designed with a functional question table rather than a structural checklist. UNCLEAR token is clearly specified as machine-readable. Severity tiers are objective. The reproduction-steps extraction for browser automation (step 8) is a notable feature. Description over-emphasises attachments relative to the AC + complexity outputs which are equally consumed by downstream agents. Minor: constraints don't explicitly forbid guessing attachment content when download fails.

#### code-analyst (5/5 overall)
Strongest process definition in the codebase. The reproduction walkthrough (Step 7) with explicit system-state / code-path / input-data / effect-of-fixing-here per step is exceptional. Root cause sanity check gate (Step 8) with PARTIAL report fallback is mature engineering. Historical context (Step 10) with git log + pipeline history adds unique signal. Max 5 affected files constraint is clear. No meaningful gaps found.

#### fixer (4/5 overall)
The agent definition is well-structured with clear RED-GREEN-REFACTOR discipline, NEEDS_DECOMPOSITION escape hatch, and build verification. Key issue: Step 1 will hard-Block in implement-feature and scaffold pipelines because it checks for "triage analysis or impact report" and both are absent. The description "Implements minimal, correct bug fixes" is also inaccurate for feature work where it implements new capabilities. The RED phase wording ("a test that reproduces the bug") is wrong for feature mode.

#### reviewer (4/5 overall)
Adversarial stance, issue count gate (minimum 3 findings), and explicit AC Fulfillment section are all strong. The Reviewer Loop iteration protocol is clear. Issues: Step 1 reads "original bug report, triage analysis, impact report" — absent in feature mode. The checklist item "Root cause: Does the fix address the actual root cause" is semantically wrong for feature code reviews. Description "Ensures root cause fix" is bug-centric. Constraints include a useful zero-findings justification rule.

#### test-engineer (4/5 overall)
The 1-3 focused tests heuristic (regression + edge case + boundary) is clean and appropriately scoped. Pre-existing failure cross-check in Step 2 is a useful guard. Framework convention discovery via Glob + Read is correct. Issue: Step 1 reads "bug report" and "impact report" — absent in feature mode. Step 3 Required test is framed as a "regression test" which is wrong for new feature code. Max 3 attempts constraint is clear. checklist reference is good.

#### e2e-test-engineer (5/5 overall)
The deployment pre-flight sequence (check Local Deployment config → dispatch deployment-verifier → handle all verdicts) is thorough. Resilient selector priority (data-testid > aria > CSS > XPath) is best practice. Auth helpers reuse instruction is important. Only gap: Step 1 reads "bug report and fix diff" — "bug report" is absent in feature mode. A one-word change to "feature spec or bug report" would fix this. All constraints are well-formed.

#### rollback-agent (5/5 overall)
The guard logic in Step 1 explicitly handles all edge cases: read-only agents (no rollback needed), publisher block (manual cleanup safer), scaffolder block (handled by scaffold command). Worktree vs CWD detection with git commands is correct. Stash-before-reset in CWD mode to preserve user work is excellent. No force push constraint is important. Single-pass / no retry policy is correctly specified for a safety-critical agent.

#### publisher (4/4 overall)
Label ID resolution instruction for Gitea (GET /api/v1/repos/{owner}/{repo}/labels) is a useful practical detail. Specific-files staging (never git add .) is correctly specified with scope caveat. Issues: PR title template hard-codes "Fix:" which is wrong for feature pipelines. Commit message example uses "fix(...)" Conventional Commits type — should vary by pipeline mode. "Root Cause" in PR description template is a bug concept absent in feature PRs. No guard for missing issue tracker context in scaffold mode.

#### acceptance-gate (5/5 overall)
Best-in-class agent. Verification method selection (behavioural vs structural vs performance AC) is sophisticated and covers real-world AC diversity. The "structural AC needs code/config evidence only, not test evidence" rule is a correct and important carve-out. Verdict rules are simple and correct. Constraint "If no AC provided → APPROVE and output no-AC message" prevents pipeline blockage. No code execution constraint is correctly stated. Zero issues found.

#### spec-analyst (5/5 overall)
Feature size assessment (single vs epic) with sub-feature enumeration up to 5 is practical. Quality gate uses a single functional question which is appropriate for features (vs triage-analyst's 4 questions for bugs). AC writeback as a separate comment to the tracker is an important visibility feature. Scope IN/OUT fields in the spec template are valuable. Description undersells the AC writeback behaviour. Minor: no explicit constraint about not proposing architecture (covered by "NEVER design architecture" constraint — good, but could be in the description).

#### architect (5/5 overall)
The decomposition strategy selection criteria (sequential / parallel / mixed) with explicit `depends_on` field is well-designed. The maps_to format constraint (`AC-{N}: {verbatim text}`) prevents renumbering drift. Effort estimation heuristics (lines per function type) are practical. The max 7 subtasks constraint with 2-attempt retry before Block is correct. Description says "complex bug decomposition" which undersells the primary feature decomposition use case.

#### spec-writer (5/5 overall)
Spec folder structure (README, architecture, verification, epics/) is clear. GWT vs rule-oriented AC format guidance with bad-example callouts is excellent. Design & UX conditional subsection (web projects only) is well-scoped. Unicode preservation constraint is unique and important for international projects. Max 7 epics constraint is consistent with architect's max 7 subtasks. The Block comment note (stdout when no tracker) is important and correctly placed. No gaps found.

#### spec-reviewer (5/5 overall)
The dual-mode design (review mode vs --verify mode) within a single agent is well-implemented. Review mode completeness checklist maps directly to spec-writer's required sections — good symmetry. The GWT quality check with WARN-not-BLOCK for format issues (vs BLOCK for content vagueness) is a correct severity calibration. The --verify mode 20-file / 10-test-file cap prevents runaway token usage. Description should mention --verify mode as it is a major distinct capability. Verdict rules in both modes are consistent.

#### scaffolder (4/5 overall)
The 8-batch generation sequence is comprehensive. Quality scorecard with hard requirements (Build, Tests) vs informational items is a good design. E2E scaffold with cross-stack Playwright detection across 6 languages is exceptional detail. docs/ARCHITECTURE.md generation (Batch 8) is a nice addition for downstream agents. Issues: scorecard item 8 reads "(if S3 implemented)" — this is a stray copy-paste artifact that should read "if database configured" or similar. The agent is 210 lines — the longest in the set — which makes it harder to maintain and creates a higher risk of internal inconsistencies. Step numbering has a duplicate "4" (step 4 and step 4b) which may confuse readers. The Constraints note "Note: scaffolder runs in the scaffold pipeline which has no issue tracker context" is correct but could be moved to the top of Constraints for visibility.

#### stack-selector (5/5 overall)
Decisive recommendation approach (pick the best, explain why) is correctly enforced. Specific stable version requirement (no "Python 3.x") is important for downstream scaffolding. The clarifying questions limit (3 questions, multiple-choice preferred) is well-specified. Version staleness caveat in Step 4 is honest and appropriate. Constraints are minimal and correct for a read-only analytical agent. No issues found.

#### priority-engine (4/5 overall)
The 4-dimension scoring formula (Impact × 2 + Risk × 1.5) / Effort + dependency_bonus) is explicit and auditable. P0/P1/P2 tiers with numeric thresholds are clear. Historical data integration (from metrics or [ceos-agents] comments) adds pipeline feedback loop. Issues: the constraint "dimension scores may vary between runs" undercuts the auditability claim — if the formula is fixed but inputs are fuzzy, say that explicitly rather than qualifying the formula. Dependency bonus formula is simple but doesn't distinguish between "blocks 1 important issue" vs "blocks 1 trivial issue" — a minor gap. Max 50 issues constraint is practical. Empty backlog guard is correct.

#### reproducer (5/5 overall)
The Playwright script template with console error + network failure capture is production-quality. The side-channel isReproduced heuristic (errors/netFails non-empty even when script throws) is clever and prevents false negatives. NEVER-block constraint is the most important rule and is correctly first in Constraints. Start-command cleanup after execution prevents port conflicts. Accessibility snapshot truncation to 8000 chars + console errors top 5 + network failures top 3 are correct limits. Description doesn't mention the graceful skipping behaviour which is the key design property for optional pipeline steps.

#### browser-verifier (5/5 overall)
The Sub-phase A (scoped) vs Sub-phase B (exploration) split is architecturally clean. The `On events: verify` guard in Step 1 prevents unnecessary runs. The verdict hierarchy (VERIFIED > PARTIAL > FAILED > SKIPPED) is clear. Sub-phase B "never block on exploration findings" constraint is correctly stated and enforced via the output contract. Page cap (5 total across all Sub-phase A activities) with sub-limits is precise. Description doesn't mention guided exploration (Sub-phase B) which is a differentiating feature.

#### deployment-verifier (5/5 overall)
Port validation before port scan (digits-only, 1-65535 range check) before attempting network operations is correct defensive programming. Platform-appropriate port inspection commands (lsof vs netstat) are specified. Secret redaction in Docker log output (PASSWORD=, TOKEN=, etc.) is an important security constraint. Cleanup-on-failure with PID tracking for native processes is production-quality. Docker restart loop detection (>3 restarts) is a practical heuristic. Description is accurate but doesn't explain the action parameter (check/start/stop) that callers must understand to use it correctly.

---

### Q3 Quality Summary

**Highest quality agents (5/5):** acceptance-gate, spec-writer, spec-reviewer, rollback-agent, e2e-test-engineer, reproducer, browser-verifier, deployment-verifier, code-analyst, triage-analyst, spec-analyst, architect, stack-selector

**Agents needing updates (4/5):** fixer, reviewer, test-engineer, publisher, scaffolder, priority-engine

**Agents with hard bugs (structural failures):** fixer (Step 1 will hard-Block in implement-feature and scaffold pipelines)

**Most common issue class:** Bug-centric input-reading language in Step 1 of shared agents (fixer, reviewer, test-engineer, e2e-test-engineer) that references "bug report", "triage analysis", or "impact report" — documents that do not exist in feature and scaffold pipelines.

**Second most common issue:** Publisher PR title and commit message format hardcodes "fix:" / "Fix:" for all pipeline modes.

**Best-in-class agents:** acceptance-gate (explicit mode awareness, zero gaps), code-analyst (exhaustive reproduction walkthrough protocol), reproducer and browser-verifier (both have NEVER-block as primary constraint with well-designed graceful degradation).
