# Phase 1 Research: Bug-Fix-Centric Language Audit (RQ-1, RQ-3)

**Date:** 2026-04-13
**Scope:** fixer, reviewer, test-engineer, e2e-test-engineer, implement-feature/SKILL.md
**Focus:** Identify language, artifacts, and process steps that assume a bug-fix context, rating each finding for impact when the same agent runs in the feature pipeline.

---

## 1. Refined Research Questions

### RQ-1: Fixer — Role Identity Conflict
- Does the fixer's "surgical bug fixes" identity cause it to under-scope feature implementation work (treating every change as a "minimal fix" rather than a full implementation)?
- When the fixer receives a spec/architecture plan instead of a triage/impact report, does Step 1's hard BLOCK on "missing input" trigger unnecessarily?
- Step 5 uses red-green-refactor and explicitly says "write a test that reproduces the bug" and "confirm it FAILS" — what does this mean when the feature does not yet exist? Is there an escape hatch, or does the agent get confused?
- The ESCAPE HATCH in Step 5 references the 100-line diff limit — is this appropriate for feature subtasks that are inherently larger?
- Does the "Fix Report" output label create confusion downstream (reviewer reads "fix report" in a feature context)?

### RQ-2: Reviewer — Bug-Centric Checklist
- Does "root cause vs symptom detection" as an Expertise make sense for a feature review? What does "root cause" mean for new code that didn't exist before?
- Step 1 explicitly lists "bug report, triage analysis, impact report" as expected inputs. If these are missing in feature context, does the reviewer fail gracefully or error?
- The review checklist's "Root cause" item ("Does the fix address the actual root cause, not just symptoms?") is semantically broken for features — is this a BLOCKING confuser?
- The issue gate "NEVER block a correct fix for style nitpicks" uses "fix" language — does this prime the agent to treat feature work as a patch?
- The frontmatter description ("Ensures root cause fix, convention compliance, no regressions") uses "fix" — is this what appears in the Claude Code agent picker?

### RQ-3: Test-Engineer — Verification Semantics
- Step 1 lists "bug report, fixer output (changed files, root cause), and impact report" as required inputs. In the feature pipeline, which of these exist and which are absent?
- Step 3's "Required: One test verifying the specific behavior that was fixed (regression test)" assumes a pre-existing bug. In a feature context, there is no bug to regress against — does "regression test" become semantically wrong or does the agent interpret it correctly?
- The frontmatter description ("Writes and runs unit tests verifying the fix and preventing regressions") is entirely bug-fix framing — does this description mislead the agent's approach when writing tests for new feature code?

### RQ-4: E2E Test Engineer — User Flow Frame
- Step 1 "Read the bug report and fix diff — understand which user flow was affected" assumes there is a bug report and a fix diff. In the feature context, where does the agent look instead?
- "Prevent UI-level regressions" in the Goal — is this a meaningful objective for a user flow that does not yet exist?
- The E2E engineer is the most naturally dual-context agent (user flows are user flows). Are there any remaining confusers after the above are resolved?

### RQ-5: implement-feature Skill — Context Passed to Agents
- Step 6b dispatches fixer with "architectural design + subtask scope + acceptance criteria" — but fixer Step 1 says to read "triage analysis and impact report" and blocks if missing. Does the skill pass enough context to prevent a false block?
- Step 6e dispatches test-engineer with "changed files, acceptance criteria" — but test-engineer Step 1 also reads "bug report" and "impact report". Same false-block risk?
- Step 6d dispatches reviewer with "diff from fixer + acceptance criteria from spec-analyst" — reviewer Step 1 also reads "bug report, triage analysis, impact report". Same risk.
- Does implement-feature pass a "feature context signal" to the agents so they can switch behavior, or is context injection entirely implicit (i.e., the agent must infer from what's present/absent)?

### RQ-6: Output Label Mismatches
- Fixer outputs "## Fix Report" — does the reviewer or test-engineer look for this exact heading? If yes, does the heading name matter for feature work?
- Are there other output section labels (e.g., test-engineer's "## Test Report", e2e's "## E2E Test Report") that carry bug-fix connotations that would confuse downstream agents?

---

## 2. Detailed Findings Per Agent

### 2.1 fixer.md

| Location | Text | Severity | Reason |
|----------|------|----------|--------|
| Frontmatter `description` | "Implements minimal, correct **bug fixes** targeting root cause. Surgical changes with backwards compatibility." | BLOCKING | This description appears in the Claude Code agent picker and sets the agent's self-understanding. In a feature context the model is primed to minimize scope, treat every change as a "fix", and look for a "root cause" that does not exist. |
| Frontmatter `style` | "Pragmatic, minimal, **surgical**" | WARNING | "Surgical" primes minimalism which is correct for bugs but counterproductive when building new features that require substantial new code. |
| Role statement | "You are a Senior Developer specializing in **surgical bug fixes**." | BLOCKING | Direct role conflict. The agent's identity is anchored to bug fixing. When implementing a feature it will apply bug-fix heuristics (minimal diffs, root cause focus) to a problem that requires constructive, additive work. |
| Goal | "Minimal correct **fix** that solves the root cause. Simplest solution that doesn't break anything." | BLOCKING | "Fix that solves the root cause" has no mapping to feature implementation. "Simplest solution" is correct but the framing anchors it to fixing something broken rather than building something new. |
| Expertise | "**Root cause analysis**, defensive coding, backwards compatibility, minimal diffs." | WARNING | Root cause analysis is irrelevant for feature work. Missing: design pattern application, API design, scaffolding new modules. |
| Process Step 1 | "Read the **triage analysis** and **impact report** thoroughly. If triage analysis or impact report is missing, **Block** with reason 'Missing input from previous pipeline stage'." | BLOCKING | The feature pipeline provides architectural design and spec, NOT triage analysis or impact report. This step will cause a false Block in every feature run unless the skill injects aliased context that maps "architectural design" → "triage analysis" equivalent. **The hard Block is the highest risk item in the entire audit.** |
| Process Step 3, sub-bullet | "What exactly is **wrong** and why?" | WARNING | "What is wrong" assumes a defect. In a feature context, nothing is "wrong" — the question should be "what needs to be built and how?" |
| Process Step 3, sub-bullet | "Which approach is the simplest and lowest-risk?" | OK | Reasonable for both contexts; simplicity is always a virtue. |
| Process Step 4 | "Read affected files (from **impact report**) thoroughly" | BLOCKING | Depends on "impact report" artifact — absent in feature context. If the agent reads this literally it will look for an impact report that was never generated. |
| Process Step 5 | "Write a test that **reproduces the bug**. Run it — confirm it FAILS." | BLOCKING | A feature has no pre-existing bug to reproduce. The TDD framing (write failing test first) can still apply, but the instruction "reproduces the bug" is semantically wrong and may cause the agent to look for a defect that doesn't exist. |
| Process Step 5, RED phase | "If the test passes, your test does not capture the **actual bug**; rewrite it." | WARNING | Again assumes there is a bug to capture. For new feature code, a test that passes on first write is expected and correct — this instruction could cause the agent to incorrectly discard valid new tests. |
| Process Step 5, ESCAPE HATCH | "If during implementation you realize the fix requires changes across ≥4 files…" | WARNING | Uses "fix" language; the 100-line limit may be too restrictive for feature subtasks (which are pre-scoped by architect but may still exceed this legitimately). |
| Output template | "## Fix Report" heading + "**Root cause:** {what was wrong and why}" | WARNING | The "Fix Report" label and "root cause" field are fed to the reviewer. The reviewer's checklist includes "Root cause: Does the **fix** address the actual root cause?" — these two bug-fix artifacts reinforce each other. |
| Constraints | "NEVER change more than necessary — no drive-by refactoring" | OK | Appropriate for both contexts — scope discipline is good in features too. |
| Constraints | "Diff MUST NOT exceed 100 lines." | WARNING | For feature subtasks pre-scoped by architect, a 100-line limit may be hit legitimately. The architect could scope a subtask to ~150 lines and the fixer would be forced to block or decompose unnecessarily. |

**Fixer critical count:** 5 BLOCKING, 6 WARNING, 1 OK

---

### 2.2 reviewer.md

| Location | Text | Severity | Reason |
|----------|------|----------|--------|
| Frontmatter `description` | "Senior code reviewer and quality gate. Ensures **root cause fix**, convention compliance, no regressions." | BLOCKING | "Root cause fix" is the reviewer's stated purpose. In feature context, there is no root cause and no fix — the reviewer's goal becomes undefined unless re-framed. |
| Role statement | "You are a Senior Code Reviewer acting as a quality gate." | OK | Role is neutral — "quality gate" applies to both contexts. |
| Goal | "Ensure the **fix** addresses root cause, follows project conventions, and introduces no regressions." | BLOCKING | Three of the four criteria ("fix", "root cause", "regressions") are bug-fix specific. "Regressions" is debatable — in features, regressions against existing behavior are still possible and worth checking, but new features don't have their own regressions yet. |
| Expertise | "**Root cause vs symptom detection**" | WARNING | Irrelevant to feature review. Not harmful — the agent will simply have dead expertise — but it indicates the agent has not been designed for feature review at all. |
| Process Step 1 | "Read the original **bug report**, **triage analysis**, **impact report**, and the fixer's output" | BLOCKING | Four of the five artifacts are bug-pipeline specific. In feature context, these are absent. Unlike fixer Step 1, there is no explicit Block here — the reviewer will proceed, but with missing context. This creates a silent failure: the reviewer reviews without understanding the original requirement. |
| Review checklist, "Root cause" item | "Does the **fix** address the actual root cause, not just symptoms?" | BLOCKING | Semantically meaningless for feature work. The agent will either skip this check silently, apply it incorrectly (looking for a "root cause" that doesn't exist), or produce noise. |
| Review checklist, "Completeness" item | "Are all affected paths covered (from **impact report**)?" | WARNING | References the impact report artifact. Without it, the completeness check becomes ad hoc — the reviewer will not know which paths were identified as affected. |
| Review checklist, "Regressions" item | "Could this break existing callers (from **impact report**)?" | WARNING | Same impact report dependency. Not a full BLOCK because the agent can infer callers from code — but loses the impact report's structured list of affected callers. |
| Constraints | "NEVER block a correct **fix** for style nitpicks — approve if the fix addresses the root cause correctly" | WARNING | "Fix" and "root cause" framing in the most important constraint. Primes the agent to evaluate feature code as if it were a patch. |
| Constraints | "If fixer produced zero changed files, BLOCK with reason 'No code changes detected — fixer claimed **fix** but no files were modified'." | OK | The behavior (block on zero changes) is correct for features too, though the label "fix" is mildly off. |

**Reviewer critical count:** 4 BLOCKING, 5 WARNING, 2 OK

---

### 2.3 test-engineer.md

| Location | Text | Severity | Reason |
|----------|------|----------|--------|
| Frontmatter `description` | "Writes and runs unit tests verifying **the fix** and preventing regressions." | BLOCKING | The description primes the agent to look for "the fix" (an existing change to a bug) rather than "the implementation" (new feature code). Appears in agent picker. |
| Role statement | "You are a Senior Test Engineer specializing in automated unit tests." | OK | Role is neutral — applicable to both contexts. |
| Goal | "Write tests that verify **the fix** AND prevent future regressions." | BLOCKING | Both objectives anchor to bug-fix framing. For features, the goal should be "verify the feature behaves per spec" and "prevent future breakage of new behavior". |
| Process Step 1 | "Read the **bug report**, fixer output (changed files, **root cause**), and **impact report** (test coverage section)" | BLOCKING | All three named artifacts are bug-pipeline specific. The test-engineer will receive a feature context without a bug report or impact report — if it interprets Step 1 literally, it has no starting point and no documented root cause to test against. |
| Process Step 2 | "check the fixer's output for noted pre-existing failures" | OK | "Pre-existing failures" is neutral framing applicable to features too — existing test suite may have failures unrelated to the feature. |
| Process Step 3, "Required" | "One test verifying the specific behavior that was **fixed** (**regression test**)" | BLOCKING | "Fixed" assumes a defect was corrected. For a feature, there is no regression to guard against — the test should verify the new behavior against the specification. The "regression test" label is misleading. |
| Process Step 3, "Recommended" | "One test for the most likely edge case from the **impact report**" | WARNING | Impact report absent in feature context — the agent must rely on its own judgment for edge cases, losing structured input. |
| Output template | "## Test Report" | OK | Neutral label, applicable to both contexts. |

**Test-engineer critical count:** 4 BLOCKING, 1 WARNING, 3 OK

---

### 2.4 e2e-test-engineer.md

| Location | Text | Severity | Reason |
|----------|------|----------|--------|
| Frontmatter `description` | "Writes and runs E2E tests verifying user flows end-to-end." | OK | Neutral — user flows apply equally to bug fixes and features. |
| Role statement | "You are a Senior QA Automation Engineer specializing in E2E tests." | OK | Neutral role. |
| Goal | "E2E tests verifying the complete user flow **affected by the fix**. **Prevent UI-level regressions**." | WARNING | "Affected by the fix" is bug-fix framing. "UI-level regressions" for new UI flows that didn't exist before is semantically odd (you can't regress behavior that was never there). Not BLOCKING because the agent can infer the correct intent from context, but the framing is suboptimal. |
| Process Step 1 | "Read the **bug report** and fix diff — understand which user flow was **affected**" | WARNING | "Bug report" is absent in feature context. The agent will proceed without it (no hard Block here), but loses the structured problem statement. "Which user flow was affected" should be "which user flow was added/changed". |
| Process Step 6, "Required" | "One test verifying the happy path of the affected user flow" | OK | "Happy path" is universally applicable. "Affected" is slightly bug-centric but benign. |
| Output template | "## E2E Test Report" | OK | Neutral. |

**E2E-test-engineer critical count:** 0 BLOCKING, 2 WARNING, 4 OK

---

### 2.5 implement-feature/SKILL.md — Context Injection Analysis

| Location | Issue | Severity | Reason |
|----------|-------|----------|--------|
| Step 6b (Fixer dispatch) | Context provided: "architectural design + subtask scope + acceptance criteria" | BLOCKING | Fixer Step 1 expects "triage analysis" and "impact report" and will BLOCK if they are absent. The skill does not alias or rename these artifacts in the context. Unless the fixer interprets the architectural design as equivalent, it will false-block. |
| Step 6b (Fixer dispatch) | No "feature mode" signal in context | BLOCKING | The skill dispatches fixer with feature content but does not include any signal like "Mode: feature implementation" to tell the fixer to suppress bug-fix-specific behaviors (e.g., "write a test that reproduces the bug"). |
| Step 6d (Reviewer dispatch) | Context: "diff from fixer + acceptance criteria from spec-analyst" | BLOCKING | Reviewer Step 1 expects bug report, triage analysis, impact report. None of these are in the context. The reviewer will proceed without them (no hard Block) but will review blind — the "root cause" and "completeness from impact report" checklist items will fire without the input they need. |
| Step 6e (Test-engineer dispatch) | Context: "changed files, acceptance criteria" | BLOCKING | Test-engineer Step 1 also reads bug report + impact report. Same silent failure risk. Step 3 "Required: regression test" will be interpreted without a bug to regress against. |
| Step 6g (E2E dispatch) | Context: not specified in SKILL.md (no explicit context bullet) | WARNING | E2E engineer Step 1 reads the "bug report" — if no context is provided about what changed and why, the agent falls back to reading the changed files. This is recoverable but suboptimal. |
| General | No `mode` field in fixer/reviewer/test-engineer dispatch | BLOCKING | The skill has full knowledge that it is in a feature pipeline, but this is never communicated to the agents. Agents must infer mode from what is present/absent — an LLM-unreliable heuristic. |

---

## 3. Severity Summary

### By Agent

| Agent | BLOCKING | WARNING | OK | Risk Level |
|-------|----------|---------|-----|------------|
| fixer | 5 | 6 | 1 | CRITICAL |
| reviewer | 4 | 5 | 2 | CRITICAL |
| test-engineer | 4 | 1 | 3 | HIGH |
| e2e-test-engineer | 0 | 2 | 4 | LOW |
| implement-feature (skill dispatch) | 5 | 1 | 0 | CRITICAL |

### Top 5 Highest-Risk Items (across all agents)

1. **fixer Step 1 hard Block on missing triage analysis / impact report** — the feature pipeline never generates these artifacts, so every feature run risks a false Block before any code is written. (CRITICAL, fixer + skill)

2. **fixer role identity ("specializing in surgical bug fixes")** — the LLM's fundamental self-model will bias toward minimal patches instead of constructive feature implementation throughout the entire fixer↔reviewer loop. (CRITICAL, fixer)

3. **No feature-mode signal injected by implement-feature skill** — agents have no explicit signal that they are in a feature context. All context-switching relies on LLM inference from what artifacts are absent, which is unreliable. (CRITICAL, skill)

4. **reviewer Step 1 reads bug report / triage / impact report (no hard Block but silent context loss)** — the reviewer will apply its "root cause" checklist without knowing the original requirement, leading to superficial or incorrect quality verdicts. (CRITICAL, reviewer)

5. **test-engineer "Required: regression test" for features** — the test-engineer will try to write a regression test for a bug that doesn't exist, either producing a confused test or wasting iterations before writing the right test. (HIGH, test-engineer)

### Recommended Fix Priorities

| Priority | Fix | Agents Affected |
|----------|-----|-----------------|
| P0 | Add `mode` parameter to fixer/reviewer/test-engineer dispatch in implement-feature, with value `feature-implementation` | implement-feature skill |
| P0 | Update fixer Step 1 to conditionally accept architectural design + spec as input (not hard Block if triage/impact absent but mode=feature) | fixer |
| P1 | Update fixer role statement, Goal, and frontmatter description to reflect dual purpose | fixer |
| P1 | Update reviewer Step 1 and checklist "Root cause" item to handle feature context | reviewer |
| P1 | Update test-engineer Step 1 and Step 3 "Required" to distinguish feature tests from regression tests | test-engineer |
| P2 | Update fixer TDD step 5 to use "write a failing test for the expected behavior" instead of "reproduces the bug" | fixer |
| P2 | Update reviewer frontmatter description and Goal to include feature review | reviewer |
| P2 | Update e2e-test-engineer Goal and Step 1 to use neutral "user flow added/changed" language | e2e-test-engineer |
| P3 | Consider whether 100-line diff limit applies unchanged to architect-pre-scoped feature subtasks | fixer |
