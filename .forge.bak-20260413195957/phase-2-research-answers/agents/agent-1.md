# Phase 2: Agent Audit — Output 2 (Cross-Mode Report) + Output 3 (Quality Scorecard)

---

## Output 2: Shared Agent Cross-Mode Report

---

### Agent: fixer
**File:** agents/fixer.md
**Pipelines:** fix-ticket (YES), fix-bugs (YES), implement-feature (YES), scaffold (YES)

**Bug-fix context:** (what does fix-ticket/fix-bugs pass to this agent?)
- fix-ticket Step 5 (line 444-445): `Context: Max build retries = {Build retries from config}. Block Comment Template: {template from plugin CLAUDE.md}. Acceptance criteria: {AC from triage}.`
- fix-bugs Step 4 (line 431-432): identical context: `Max build retries = {Build retries from config}. Block Comment Template: {template from plugin CLAUDE.md}. Acceptance criteria: {AC from triage}.`
- Both pipelines pass triage analysis + code-analyst impact report as implicit context (agent reads them per its Process step 1)

**Feature context:** (what does implement-feature pass?)
- implement-feature Step 6b (line 447-449): `Context: architectural design + subtask scope + acceptance criteria`
- No triage analysis — gets spec-analyst AC instead. No code-analyst impact report — gets architect design instead.

**Scaffold context:** (what does scaffold pass?)
- scaffold Step 7a (line 674-675): `Context: subtask scope + acceptance criteria + architecture design + Max build retries = {Build retries from CLAUDE.md, default 3}.`
- Also: full decomposition plan + summary of previously completed subtasks + spec/ folder (line 668-672)
- No triage analysis. No code-analyst impact report.

**Mode adequacy per process step:**

| Step | Bug-fix | Feature | Scaffold | Issue |
|------|---------|---------|----------|-------|
| 1. Read triage analysis and impact report. Block if missing. | OK — both exist | BROKEN — no triage analysis exists; agent gets spec-analyst + architect output. "triage analysis" / "impact report" are bug-specific terms that don't map to feature context. Agent may Block claiming "Missing input" when input is actually present under different names. | BROKEN — same as Feature. No triage/impact report exists. Agent may Block on first sentence. | **CRITICAL:** Step 1 hardcodes "triage analysis and impact report" as required inputs. Feature/scaffold pass "architectural design + subtask scope" instead. The Block guard on line 20 ("If triage analysis or impact report is missing, Block") will fire incorrectly. |
| 2. Read CLAUDE.md conventions | OK | OK | OK | None |
| 3. Analyze before coding — reason through root cause | OK | NEEDS_UPDATE — "root cause" framing is bug-specific. For features, the correct framing is "implementation approach" or "design rationale". The fixer will still reason about the problem, but the mental model is wrong. | NEEDS_UPDATE — same | **MEDIUM:** "root cause" language biases agent toward bug-hunting rather than feature construction. |
| 4. Read affected files from impact report | OK | NEEDS_UPDATE — "from impact report" doesn't exist in feature mode. Affected files come from architect subtask. | NEEDS_UPDATE — same | **MEDIUM:** Reference to non-existent artifact. Agent will still read files, but the instruction path is misleading. |
| 5. Red-green-refactor (TDD) | OK for bugs — RED writes test reproducing bug | NEEDS_UPDATE — "Write a test that reproduces the bug" (line 29) is nonsensical for new feature code. Should be "Write a test that verifies the expected behavior". The escape hatch mentioning "the fix requires changes across ≥4 files" is bug-framed. | NEEDS_UPDATE — same | **HIGH:** TDD RED phase literally says "reproduces the bug" and "confirm it FAILS" (line 29). For features, the test should verify new behavior. The fixer might try to write a failing test for something that doesn't exist yet (which would trivially fail for the wrong reason). |
| 6-7. Build and test | OK | OK | OK | None |
| 8. Output "Fix Report" with "Root cause" | OK | NEEDS_UPDATE — "Root cause" field is meaningless for features. Should be "Implementation summary" or similar. | NEEDS_UPDATE — same | **LOW:** Output formatting bias. |
| Reviewer Loop | OK | OK | OK | None — generic enough |

**Verdict:** BROKEN

**Specific changes needed:**
1. **CRITICAL (Step 1, line 20):** Replace "triage analysis and impact report" with mode-aware language: "Read the analysis from previous pipeline stage (triage analysis for bugs, spec-analyst + architect output for features). If no upstream analysis exists, Block with reason 'Missing input from previous pipeline stage'."
2. **HIGH (Step 5, line 29):** Replace "Write a test that reproduces the bug" with "Write a test that verifies the target behavior. For bug fixes: the test should reproduce the bug (fail before fix, pass after). For features: the test should verify the expected new behavior."
3. **MEDIUM (Step 3, line 23):** Replace "reason through the root cause" with "reason through the problem" — works for both modes.
4. **MEDIUM (Step 4, line 27):** Replace "from impact report" with "from the analysis output (impact report for bugs, subtask file list for features)".
5. **LOW (Step 8, line 55):** Rename "Root cause" to "Problem" or make it conditional: "Root cause (bug) / Implementation rationale (feature)".
6. **LOW (frontmatter line 3):** Description says "Implements minimal, correct bug fixes" — should say "Implements minimal, correct code changes" to cover both modes.

---

### Agent: reviewer
**File:** agents/reviewer.md
**Pipelines:** fix-ticket (YES), fix-bugs (YES), implement-feature (YES), scaffold (YES)

**Bug-fix context:** (what does fix-ticket/fix-bugs pass to this agent?)
- fix-ticket Step 7 (line 478-479): `Context: Max fixer iterations = {Fixer iterations from config}. Acceptance criteria: {AC from triage}.`
- fix-bugs Step 6 (line 465-466): identical context
- Agent reads "original bug report, triage analysis, impact report, and the fixer's output" per Process step 1 (line 20)

**Feature context:** (what does implement-feature pass?)
- implement-feature Step 6d (line 461-462): `Context: diff from fixer + acceptance criteria from spec-analyst`
- No bug report. No triage analysis. Spec-analyst AC instead.

**Scaffold context:** (what does scaffold pass?)
- scaffold Step 7b (line 681-682): `Context: diff from fixer + acceptance criteria + Max fixer iterations = {Fixer iterations from CLAUDE.md, default 5}.`
- No bug report. No triage. Spec/architect context.

**Mode adequacy per process step:**

| Step | Bug-fix | Feature | Scaffold | Issue |
|------|---------|---------|----------|-------|
| 1. Read "original bug report, triage analysis, impact report, and fixer's output" | OK | NEEDS_UPDATE — "bug report" and "triage analysis" don't exist in feature mode. Agent receives spec-analyst output + architect design. The instruction references artifacts that were never created. | NEEDS_UPDATE — same | **MEDIUM:** References non-existent artifacts. Agent will look for "bug report" and fail silently or skip. |
| 2. Read actual code changes | OK | OK | OK | None |
| 3. Think before judging | OK | OK | OK | None — generic |
| 4. Adversarial review — "Root cause" check | OK | NEEDS_UPDATE — "Root cause: Does the fix address the actual root cause, not just symptoms?" (line 30) is bug-specific framing. For features, the check should be "Completeness: Does the implementation satisfy the specification?" | NEEDS_UPDATE — same | **MEDIUM:** "Root cause" checklist item is irrelevant for features. Agent may flag "root cause not addressed" for feature code that has no root cause. |
| 4. AC fulfillment check | OK | OK | OK | None — works for both triage AC and spec-analyst AC |
| 5. Edge case analysis | OK | OK | OK | None — generic |
| 6. Issue count gate | OK | OK | OK | None |
| 7. Output with "Root Cause" | OK — part of checklist | NEEDS_UPDATE — output still structured around bug-fix review | NEEDS_UPDATE | **LOW:** Minor formatting |

**Verdict:** NEEDS_UPDATE

**Specific changes needed:**
1. **MEDIUM (Step 1, line 20):** Replace "original bug report, triage analysis, impact report" with "the upstream analysis (bug report + triage + impact report for bugs; specification + architecture design for features), and the fixer's output (changed files, approach, reasoning)".
2. **MEDIUM (Step 4, line 30):** Replace "Root cause: Does the fix address the actual root cause, not just symptoms?" with "Correctness: Does the change address the actual problem (root cause for bugs, specification requirements for features)?"
3. **LOW (frontmatter line 3):** Description says "Ensures root cause fix" — add "or feature implementation".

---

### Agent: test-engineer
**File:** agents/test-engineer.md
**Pipelines:** fix-ticket (YES), fix-bugs (YES), implement-feature (YES), scaffold (YES)

**Bug-fix context:**
- fix-ticket Step 8 (line 498-499): `Context: Max test attempts = {Test attempts from config}.`
- fix-bugs Step 7 (line 484-486): identical
- Agent reads "bug report, fixer output, and impact report" per Process step 1 (line 20)

**Feature context:**
- implement-feature Step 6e (line 483-485): `Context: changed files, acceptance criteria`
- No bug report. No impact report.

**Scaffold context:**
- scaffold Step 7c (line 691-692): `Context: changed files, acceptance criteria + Max test attempts = {Test attempts from CLAUDE.md, default 3}.`

**Mode adequacy per process step:**

| Step | Bug-fix | Feature | Scaffold | Issue |
|------|---------|---------|----------|-------|
| 1. Read "bug report, fixer output, and impact report" | OK | NEEDS_UPDATE — "bug report" doesn't exist. Gets spec + fixer output. | NEEDS_UPDATE — same | **MEDIUM:** References non-existent artifact. |
| 2. Run existing tests | OK | OK | OK | None |
| 3. Plan test scope — "regression test" framing | OK — "One test verifying the specific behavior that was fixed (regression test)" | NEEDS_UPDATE — For features, this should be "One test verifying the new behavior specified in AC". The parenthetical "(regression test)" (line 25) is bug-specific terminology. | NEEDS_UPDATE — same | **LOW:** Minor terminology mismatch. The actual test written will still be correct because the fixer's changed files provide context. |
| 4-5. Write and run tests | OK | OK | OK | None |
| 6. Output "Test Report" | OK | OK | OK | None |

**Verdict:** NEEDS_UPDATE

**Specific changes needed:**
1. **MEDIUM (Step 1, line 20):** Replace "bug report, fixer output (changed files, root cause), and impact report (test coverage section)" with "the upstream analysis (bug report + impact report for bugs; specification + changed files for features), and fixer output (changed files, approach)".
2. **LOW (Step 3, line 25):** Replace "the specific behavior that was fixed (regression test)" with "the specific behavior that was changed or added (regression test for bugs, behavior verification for features)".

---

### Agent: e2e-test-engineer
**File:** agents/e2e-test-engineer.md
**Pipelines:** fix-ticket (YES), fix-bugs (YES), implement-feature (YES), scaffold (YES)

**Bug-fix context:**
- fix-ticket Step 8b (line 526-527): dispatched if E2E Test section exists
- fix-bugs Step 7b (line 513-514): identical
- Agent reads "bug report and fix diff" per Process step 1 (line 20)

**Feature context:**
- implement-feature Step 6g (line 514-515): dispatched if E2E Test section exists

**Scaffold context:**
- scaffold Step 8 (line 756-757): `Context: spec/verification.md test strategy + list of implemented features + acceptance criteria`

**Mode adequacy per process step:**

| Step | Bug-fix | Feature | Scaffold | Issue |
|------|---------|---------|----------|-------|
| 1. Read "bug report and fix diff" | OK | NEEDS_UPDATE — no "bug report". Gets spec + diff. | NEEDS_UPDATE — gets spec/verification.md + feature list | **MEDIUM:** "bug report" reference doesn't exist in feature/scaffold. |
| 2-8. E2E test flow | OK | OK | OK | None — the rest is generic |
| 9. Output | OK | OK | OK | None |

**Verdict:** NEEDS_UPDATE

**Specific changes needed:**
1. **MEDIUM (Step 1, line 20):** Replace "bug report and fix diff" with "the upstream context (bug report for bugs; specification + test strategy for features) and fix diff — understand which user flow was affected".

---

### Agent: publisher
**File:** agents/publisher.md
**Pipelines:** fix-ticket (YES), fix-bugs (YES), implement-feature (YES), scaffold (NO — scaffold does NOT use publisher; it does git init + push directly)

**Bug-fix context:**
- fix-ticket Step 9 (line 575-576): `Context: Type = {Type from config}. Use the MCP server for {Type}. Extra labels: {Labels from Extra labels config, if they exist}.`
- fix-bugs Step 8 (line 561-562): identical

**Feature context:**
- implement-feature Step 10 (line 572-573): `Context: PR Description Template, Labels, Remote, Base branch, changed files, Extra labels`

**Scaffold context:** N/A — not used in scaffold pipeline.

**Mode adequacy per process step:**

| Step | Bug-fix | Feature | Scaffold | Issue |
|------|---------|---------|----------|-------|
| 1. Read Configuration | OK | OK | N/A | None |
| 2. Pre-Publish Safety | OK | OK | N/A | None |
| 3. Branch creation | OK | OK | N/A | None |
| 4. Commit | OK | OK | N/A | None |
| 5. Push | OK | OK | N/A | None |
| 6. Create PR — Title format: `[PROJ-123] Fix: {description}` | OK for bugs | NEEDS_UPDATE — Title hardcodes "Fix:" prefix (line 57). For features this should be "Feat:" or just the issue summary without prefix. | N/A | **MEDIUM:** PR title template always says "Fix:" even for features. |
| 6. PR Description — "Summary, Root Cause, Changes, Testing, Issue link" | OK for bugs | NEEDS_UPDATE — "Root Cause" (line 59) is a bug-specific section. Feature PRs should have "Summary, Changes, Testing, Issue link" without Root Cause. | N/A | **MEDIUM:** PR description template includes "Root Cause" which is nonsensical for features. Note: the actual PR Description Template comes from the project's Automation Config, but the publisher's instruction on line 59 lists "Root Cause" as a section to fill. |
| 7-8. Update tracker + output | OK | OK | N/A | None |

**Verdict:** NEEDS_UPDATE

**Specific changes needed:**
1. **MEDIUM (Step 6, line 57):** Replace `[PROJ-123] Fix: {concise description}` with `[PROJ-123] {type}: {concise description}` where type is inferred from branch naming pattern (fix/ -> Fix, feat/ -> Feat, etc.) or from pipeline context.
2. **MEDIUM (Step 6, line 59):** Replace "Summary, Root Cause, Changes, Testing, Issue link" with "Fill in ALL template sections from the project's PR Description Template". Remove the specific mention of "Root Cause" since not all templates will have it.

---

### Agent: rollback-agent
**File:** agents/rollback-agent.md
**Pipelines:** fix-ticket (YES), fix-bugs (YES), implement-feature (YES), scaffold (YES)

**Bug-fix context:**
- fix-ticket Step X (line 600-604): dispatched on block from fixer/reviewer/test-engineer
- fix-bugs Step X (line 637-639): identical

**Feature context:**
- implement-feature Step X (line 606): dispatched on block

**Scaffold context:**
- scaffold Step 7 block handler (line 707-708): `Context: "No issue tracker context — skip issue tracker updates."`

**Mode adequacy per process step:**

| Step | Bug-fix | Feature | Scaffold | Issue |
|------|---------|---------|----------|-------|
| 1. Check if rollback needed — identifies blocking agent | OK | OK | OK — scaffold passes explicit context to skip tracker | None |
| 2. Determine context (worktree vs CWD) | OK | OK | OK | None |
| 3. Read config | OK | OK | OK (reads generated CLAUDE.md) | None |
| 4. Perform rollback | OK | OK | OK | None |
| 5. Post block comment to tracker | OK | OK for features | OK — scaffold says "skip issue tracker updates" | None |
| 6-7. Update state + output | OK | OK | OK | None |

**Verdict:** GOOD

**Specific changes needed:** None. The rollback-agent is fully mode-agnostic. Its logic depends on which agent triggered the block (step 1, line 25-28), not on the pipeline mode. The scaffold pipeline explicitly handles the no-tracker case by passing special context (line 708).

---

### Agent: acceptance-gate
**File:** agents/acceptance-gate.md
**Pipelines:** fix-ticket (YES, conditional), fix-bugs (YES, conditional), implement-feature (YES, always in decomposition), scaffold (NO — scaffold uses spec-reviewer --verify instead at Step 7b)

**Bug-fix context:**
- fix-ticket Step 8c (line 553-554): `Context: Acceptance criteria: {AC from triage}. Changed files: {list of files modified by fixer}.`
- fix-bugs Step 7c (line 540-541): identical

**Feature context:**
- implement-feature Step 6h (line 521-522): `Context: Acceptance criteria: {AC from spec-analyst — full feature AC, not just per-subtask AC}. Changed files: {list of files modified by fixer}.`

**Scaffold context:** N/A — not used. Scaffold uses spec-reviewer --verify (Step 7b, line 729).

**Mode adequacy per process step:**

| Step | Bug-fix | Feature | Scaffold | Issue |
|------|---------|---------|----------|-------|
| 1. Read AC "from triage-analyst for bugs, spec-analyst for features" | OK | OK — explicitly mode-aware (line 21) | N/A | None — exemplary |
| 2. Read changed files | OK | OK | N/A | None |
| 3. For each AC — verify | OK | OK | N/A | None |
| 4. Output | OK | OK | N/A | None |

**Verdict:** GOOD

**Specific changes needed:** None. The acceptance-gate is exemplary in mode-awareness. Line 21 explicitly states "from triage-analyst for bugs, spec-analyst for features" — it handles both contexts correctly.

---

## Output 3: Quality Scorecard for ALL 19 Agents

Scoring dimensions (1-5):
- **Goal clarity:** Is the goal specific, measurable, and aligned with the agent's role?
- **Process completeness:** Are all necessary steps defined? Are edge cases covered?
- **Constraint coverage:** Are NEVER rules comprehensive? Are failure modes handled?
- **Mode awareness:** Does the agent handle all pipeline modes it participates in?
- **Overall:** Weighted composite (goal 15%, process 35%, constraints 25%, mode 25%)

---

### 1. triage-analyst
**File:** agents/triage-analyst.md (114 lines)
| Dimension | Score | Evidence |
|-----------|-------|----------|
| Goal clarity | 5 | Line 12: "Transform vague bug reports into actionable specs. Block unclear or duplicate bugs early." Precise, measurable. |
| Process completeness | 5 | 10 numbered steps. Quality gate (step 4) with 4-question table. Severity criteria (step 5). AC extraction (step 6). Complexity estimation (step 7). Browser reproduction steps extraction (step 8). Checkpoint comment (step 10). |
| Constraint coverage | 5 | 6 NEVER/MUST rules. Block comment template. Failure handling specified. |
| Mode awareness | 4 | Bug-only agent — correct. But does not participate in feature pipeline at all, so mode awareness is N/A for cross-mode. Deducted 1 for not flagging "this is a bug report" from spec-analyst (which it should never receive). |
| **Overall** | **5** | |
| Top recommendation | Exemplary agent. Could add a constraint: "NEVER run in feature/scaffold pipelines — bug triage only." |

---

### 2. code-analyst
**File:** agents/code-analyst.md (118 lines)
| Dimension | Score | Evidence |
|-----------|-------|----------|
| Goal clarity | 5 | Line 10: "Map the complete impact zone of a bug fix." Clear and specific. |
| Process completeness | 5 | 11 steps including mandatory reproduction walkthrough (step 7), root cause sanity check gate (step 8), partial report handling (step 9), historical analysis (step 10). Iteration limit for root cause search. |
| Constraint coverage | 5 | Named method warning (line 104), max 5 files (line 105), risk criteria (line 106), historical context as supplementary (line 108). Block template included. |
| Mode awareness | 4 | Bug-only agent — correct scope. No cross-mode issues. |
| **Overall** | **5** | |
| Top recommendation | Best-in-class agent. The reproduction walkthrough gate (step 7-8) with iteration limits is sophisticated. |

---

### 3. fixer
**File:** agents/fixer.md (93 lines)
| Dimension | Score | Evidence |
|-----------|-------|----------|
| Goal clarity | 4 | Line 10: "Minimal correct fix that solves the root cause." Bug-specific framing, but the intent is valid for features too. |
| Process completeness | 4 | 8 steps + reviewer loop. TDD red-green-refactor. NEEDS_DECOMPOSITION escape hatch. Build verification. Good. But Step 1 blocks on "triage analysis" which doesn't exist in feature mode. |
| Constraint coverage | 5 | 100-line diff limit (line 82). NEEDS_DECOMPOSITION limit (line 78). Build must pass (line 83). Block template. Revert on failure (line 84). |
| Mode awareness | 2 | **BROKEN in feature/scaffold mode.** Step 1 (line 20) blocks if "triage analysis or impact report is missing" — these don't exist in feature mode. Step 5 (line 29) says "reproduces the bug" — wrong for features. Description (line 3) says "bug fixes". |
| **Overall** | **3** | |
| Top recommendation | **CRITICAL FIX:** Make Step 1 mode-aware. Replace "triage analysis and impact report" with generic "upstream analysis". Make Step 5 TDD framing work for both bugs and features. |

---

### 4. reviewer
**File:** agents/reviewer.md (118 lines)
| Dimension | Score | Evidence |
|-----------|-------|----------|
| Goal clarity | 4 | Line 10: "Ensure the fix addresses root cause." Bug-framed but intent is valid. |
| Process completeness | 5 | 7 steps + reviewer loop. Adversarial stance. Issue count gate (step 6). AC fulfillment section. Per-checklist-item justification for zero findings. Very thorough. |
| Constraint coverage | 5 | 8 constraints. Never modify code. Never block for style nitpicks (line 105). Zero-findings justification (line 104). Block comment template. |
| Mode awareness | 3 | Step 1 (line 20) references "original bug report, triage analysis, impact report" — none exist in feature mode. Step 4 (line 30) "Root cause" checklist item is bug-specific. |
| **Overall** | **4** | |
| Top recommendation | Update Step 1 and Step 4 to use generic terms. Replace "bug report, triage analysis, impact report" with "upstream analysis" and "Root cause" with "Correctness". |

---

### 5. test-engineer
**File:** agents/test-engineer.md (62 lines)
| Dimension | Score | Evidence |
|-----------|-------|----------|
| Goal clarity | 4 | Line 10: "Write tests that verify the fix AND prevent future regressions." Bug-framed but functionally correct. |
| Process completeness | 4 | 6 steps. Existing test verification. Test scope planning. AAA pattern. Correct placement conventions. |
| Constraint coverage | 4 | No flaky tests. No implementation detail testing. Max 3 attempts. Block template. Missing: no explicit "max test file count" or "test naming convention" constraint. |
| Mode awareness | 3 | Step 1 (line 20) references "bug report" — doesn't exist in feature mode. Step 3 (line 25) "regression test" framing is bug-specific. |
| **Overall** | **4** | |
| Top recommendation | Update Step 1 to use mode-aware language. Minor: Step 3 "regression test" -> "behavior verification test (regression for bugs)". |

---

### 6. e2e-test-engineer
**File:** agents/e2e-test-engineer.md (80 lines)
| Dimension | Score | Evidence |
|-----------|-------|----------|
| Goal clarity | 4 | Line 10: "E2E tests verifying the complete user flow affected by the fix." Bug-framed. |
| Process completeness | 5 | 9 steps. Deployment pre-flight with 4 verdict paths (step 3). Auth handling. Resilient selector priority. Explicit wait requirements. Error path testing. |
| Constraint coverage | 5 | 8 constraints. Deployment pre-flight MUST. No flaky tests. No hardcoded credentials. Max 3 attempts. Block template. |
| Mode awareness | 3 | Step 1 (line 20) references "bug report" — doesn't exist in feature mode. Rest is generic. |
| **Overall** | **4** | |
| Top recommendation | Update Step 1: "bug report and fix diff" -> "upstream context (bug report for bugs, specification for features) and fix diff". |

---

### 7. publisher
**File:** agents/publisher.md (96 lines)
| Dimension | Score | Evidence |
|-----------|-------|----------|
| Goal clarity | 5 | Line 10: "Publish changes: commit → push → PR with full traceability back to the issue." Clear, mode-neutral goal. |
| Process completeness | 5 | 8 exact-order steps. Label ID resolution workaround (line 61). Pre-publish safety checks. Branch handling. |
| Constraint coverage | 5 | 6 constraints. Never push to main. Never force push. Never git add -A. Never include Claude Code footer. PR description in English. Block template. |
| Mode awareness | 3 | Step 6 (line 57): PR title hardcodes "Fix:" prefix. Line 59 lists "Root Cause" as a PR description section — bug-specific. |
| **Overall** | **4** | |
| Top recommendation | Make PR title prefix dynamic (Fix/Feat/Chore based on branch naming or pipeline context). Remove "Root Cause" from the instruction and defer entirely to the project's PR Description Template. |

---

### 8. rollback-agent
**File:** agents/rollback-agent.md (93 lines)
| Dimension | Score | Evidence |
|-----------|-------|----------|
| Goal clarity | 5 | Line 10: "Safely revert a failed fix attempt: restore git state to base branch and notify the issue tracker." |
| Process completeness | 5 | 7 steps. Agent-specific routing (step 1, line 25-28) — correctly identifies which agents trigger rollback and which don't. Worktree vs CWD detection. Stash preservation. |
| Constraint coverage | 5 | 4 constraints. Never force push. Never delete remote branches. Never rollback read-only agents. No retries. |
| Mode awareness | 5 | Fully mode-agnostic. Logic depends on blocking agent identity, not pipeline mode. Scaffold explicitly passes "No issue tracker context" which the agent handles. |
| **Overall** | **5** | |
| Top recommendation | None needed — exemplary mode-aware agent. |

---

### 9. acceptance-gate
**File:** agents/acceptance-gate.md (59 lines)
| Dimension | Score | Evidence |
|-----------|-------|----------|
| Goal clarity | 5 | Line 10: "Verify that every acceptance criterion is fulfilled by the implementation with specific code and test evidence." |
| Process completeness | 4 | 4 steps. AC verification method selection (behavioral, structural, performance). Evidence-based verdicts. |
| Constraint coverage | 5 | 6 constraints. Never modify code. Never execute tests. Never raise quality issues. Never produce verdict without evidence. Handles missing AC gracefully (line 58). |
| Mode awareness | 5 | Line 21: "from triage-analyst for bugs, spec-analyst for features" — explicit dual-mode support. |
| **Overall** | **5** | |
| Top recommendation | Could add Step 3d: distinction between "no code evidence" vs "code exists but no test" for structural AC (currently handled, but could be more explicit in process). |

---

### 10. spec-analyst
**File:** agents/spec-analyst.md (97 lines)
| Dimension | Score | Evidence |
|-----------|-------|----------|
| Goal clarity | 5 | Line 10: "Transform feature requests into actionable, structured specifications with acceptance criteria." |
| Process completeness | 5 | 6 steps. Feature size assessment (single vs epic, line 28). Quality gate (step 4). Structured output with scope IN/OUT. AC posting to tracker. |
| Constraint coverage | 5 | MUST post AC as separate comment (line 83). Never modify code. Never design architecture. Never guess. Bug report detection (line 87). Block template. |
| Mode awareness | 5 | Feature-only agent — correct scope. Does not participate in bug pipeline. |
| **Overall** | **5** | |
| Top recommendation | Excellent agent. Could add max word count for specification output to prevent token bloat. |

---

### 11. architect
**File:** agents/architect.md (107 lines)
| Dimension | Score | Evidence |
|-----------|-------|----------|
| Goal clarity | 5 | Line 10: "Design minimal, pragmatic architecture for feature implementation. Generate structured task trees." |
| Process completeness | 5 | 10 steps. Think-before-designing gate (step 4). Scope estimation heuristics (step 6). Strategy selection criteria (step 7). Task tree YAML format with maps_to traceability. |
| Constraint coverage | 5 | AC mapping requirement (line 89). maps_to format rule (line 90). 100-line subtask limit. DAG requirement. Max 7 subtasks. Block template. |
| Mode awareness | 4 | Handles both bugs (reads impact report) and features (reads specification) per Step 1 (line 21). But the same step 1 says "or impact report from code-analyst for bugs" which assumes it knows the mode. Could be more explicit. |
| **Overall** | **5** | |
| Top recommendation | Strong agent. Step 1's dual-input handling is good but implicit. |

---

### 12. stack-selector
**File:** agents/stack-selector.md (66 lines)
| Dimension | Score | Evidence |
|-----------|-------|----------|
| Goal clarity | 5 | Line 10: "Analyze project requirements and select the optimal technology stack." |
| Process completeness | 4 | 5 steps. Decisive single-recommendation approach. Flag integration (--lang, --framework, etc.). Version pinning. |
| Constraint coverage | 4 | 7 constraints. Never suggest multiple options. Max 3 questions. Never bleeding-edge. Pin versions. Correctly notes no Block Comment Template (line 65). |
| Mode awareness | 5 | Scaffold-only agent. Correctly scoped. |
| **Overall** | **4** | |
| Top recommendation | Could add deployment target (serverless, container, etc.) as an explicit decision category rather than just asking about it. |

---

### 13. scaffolder
**File:** agents/scaffolder.md (210 lines)
| Dimension | Score | Evidence |
|-----------|-------|----------|
| Goal clarity | 5 | Line 10: "Generate a minimal, buildable project skeleton that passes build, test, and lint checks." |
| Process completeness | 5 | 5 steps with 8 batches. Scaffold v2 mode detection. E2E test generation (Batch 7) with cross-stack Playwright detection. Quality scorecard (step 4b). CLAUDE.md generation with full config contract checklist. |
| Constraint coverage | 5 | 12 constraints. No hardcoded ports. No unpinned deps. No business logic. Build/Tests as hard gates. File count targets. Language-specific conventions. |
| Mode awareness | 5 | Scaffold-only agent. Correctly handles both --no-implement (uses stack-selector output) and scaffold v2 (uses spec/README.md). |
| **Overall** | **5** | |
| Top recommendation | The longest agent definition (210 lines). Could benefit from extracting Batch 7 (E2E per-language) into a reference doc to reduce cognitive load. |

---

### 14. spec-writer
**File:** agents/spec-writer.md (105 lines)
| Dimension | Score | Evidence |
|-----------|-------|----------|
| Goal clarity | 5 | Line 10: "Generate a complete, implementable project specification from user input." |
| Process completeness | 5 | 8 steps. Mode handling (interactive/yolo-checkpoint/yolo). Input source handling (description, template, issue). GWT format preference with rule-oriented alternative. Design & UX subsection detection. |
| Constraint coverage | 5 | 7 constraints. No vague AC. Max 7 epics. Interactive max 10 questions. Rationale for every stack choice. Unicode preservation (line 104). Block template. |
| Mode awareness | 5 | Scaffold-only agent. Correctly scoped. |
| **Overall** | **5** | |
| Top recommendation | Excellent definition. The GWT format guidance (step 5) is exemplary. |

---

### 15. spec-reviewer
**File:** agents/spec-reviewer.md (128 lines)
| Dimension | Score | Evidence |
|-----------|-------|----------|
| Goal clarity | 5 | Line 10: "Ensure the project specification is complete, consistent, feasible, and specific enough." |
| Process completeness | 5 | 7 steps in review mode. 5 steps in verify mode. Completeness, quality, consistency, feasibility, scope checks. YAGNI enforcement. Dual-mode (review + --verify). |
| Constraint coverage | 5 | 8 constraints. Never modify spec. Never approve missing sections. Never approve vague AC. Handles user-supplied spec (line 123). In verify mode: max 20 source files + 10 test files (line 86). |
| Mode awareness | 5 | Scaffold-only agent. Correctly scoped with two internal modes (review + verify). |
| **Overall** | **5** | |
| Top recommendation | Strong agent with elegant dual-mode design. |

---

### 16. priority-engine
**File:** agents/priority-engine.md (78 lines)
| Dimension | Score | Evidence |
|-----------|-------|----------|
| Goal clarity | 5 | Line 10: "Analyze an entire bug/feature backlog and produce a ranked list with recommended fix order." |
| Process completeness | 4 | 6 steps. 4-dimension assessment. Transparent formula. Tier grouping (P0/P1/P2). Dependency bonus. |
| Constraint coverage | 4 | 5 constraints. Max 50 issues. Formula transparency requirement. Empty backlog handling. Block template. |
| Mode awareness | 5 | Standalone agent (dispatched by /prioritize). Not pipeline-specific. |
| **Overall** | **4** | |
| Top recommendation | Could add historical data integration (read past [ceos-agents] block comments for risk assessment, as mentioned but not formalized). |

---

### 17. reproducer
**File:** agents/reproducer.md (124 lines)
| Dimension | Score | Evidence |
|-----------|-------|----------|
| Goal clarity | 5 | Line 10: "Reproduce the reported bug via browser automation and deliver a structured evidence bundle to the fixer." |
| Process completeness | 5 | 7 steps. Prerequisite checks (Playwright, app running). Fallback step inference. Script generation with console/network capture. Timeout enforcement. Retry on unexpected failure. Cleanup of started servers. |
| Constraint coverage | 5 | 6 constraints. Never block pipeline. Never leave background server running. Never commit artifacts. Never submit data-mutating forms. Truncation limits. |
| Mode awareness | 5 | Bug-only agent (only dispatched when browser_reproduce = true). Correctly scoped. |
| **Overall** | **5** | |
| Top recommendation | Excellent non-blocking design. All failure modes gracefully degrade to "skipped". |

---

### 18. browser-verifier
**File:** agents/browser-verifier.md (106 lines)
| Dimension | Score | Evidence |
|-----------|-------|----------|
| Goal clarity | 5 | Line 10: "Confirm the bug is gone and the fix hasn't broken adjacent UI areas." |
| Process completeness | 5 | 6 steps with 2 sub-phases. Sub-phase A (scoped verification): replay, adjacent pages, visual AC check. Sub-phase B (exploration): only on VERIFIED/PARTIAL. Hard stop limits. |
| Constraint coverage | 5 | 6 constraints. Never block on exploration. Never submit forms. Never run Sub-phase B on FAILED. Max pages limit. Max clicks limit. |
| Mode awareness | 5 | Bug-only agent (browser_verify = true). Correctly scoped. |
| **Overall** | **5** | |
| Top recommendation | Well-designed two-phase approach. Sub-phase A/B split is elegant. |

---

### 19. deployment-verifier
**File:** agents/deployment-verifier.md (114 lines)
| Dimension | Score | Evidence |
|-----------|-------|----------|
| Goal clarity | 5 | Line 10: "Verify that the project's local deployment is running and healthy." |
| Process completeness | 5 | 11 steps. Port validation (range check, line 24). Platform-aware port scan. Pre-start validation. Docker inspection with restart loop detection. Cleanup on failure with PID tracking. Secret redaction in logs (line 63). |
| Constraint coverage | 5 | 8 constraints. Never alter project files. Never delete Docker resources. Never start on port conflict. Never exceed timeout. Docker availability check. Port conflict as primary gate. |
| Mode awareness | 5 | Infrastructure agent — mode-agnostic. Same behavior regardless of pipeline. |
| **Overall** | **5** | |
| Top recommendation | Excellent agent. Secret redaction (line 63) is a nice security touch. |

---

## Summary Table

| # | Agent | Goal | Process | Constraints | Mode | Overall | Phase 1 | Phase 2 Verdict |
|---|-------|------|---------|-------------|------|---------|---------|-----------------|
| 1 | triage-analyst | 5 | 5 | 5 | 4 | **5** | N/A (bug-only) | GOOD |
| 2 | code-analyst | 5 | 5 | 5 | 4 | **5** | N/A (bug-only) | GOOD |
| 3 | fixer | 4 | 4 | 5 | 2 | **3** | BROKEN | **BROKEN** (confirmed) |
| 4 | reviewer | 4 | 5 | 5 | 3 | **4** | NEEDS_UPDATE | **NEEDS_UPDATE** (confirmed) |
| 5 | test-engineer | 4 | 4 | 4 | 3 | **4** | NEEDS_UPDATE | **NEEDS_UPDATE** (confirmed) |
| 6 | e2e-test-engineer | 4 | 5 | 5 | 3 | **4** | NEEDS_UPDATE | **NEEDS_UPDATE** (confirmed) |
| 7 | publisher | 5 | 5 | 5 | 3 | **4** | NEEDS_UPDATE | **NEEDS_UPDATE** (confirmed) |
| 8 | rollback-agent | 5 | 5 | 5 | 5 | **5** | GOOD | **GOOD** (confirmed) |
| 9 | acceptance-gate | 5 | 4 | 5 | 5 | **5** | GOOD | **GOOD** (confirmed) |
| 10 | spec-analyst | 5 | 5 | 5 | 5 | **5** | N/A (feature-only) | GOOD |
| 11 | architect | 5 | 5 | 5 | 4 | **5** | N/A (shared) | GOOD |
| 12 | stack-selector | 5 | 4 | 4 | 5 | **4** | N/A (scaffold-only) | GOOD |
| 13 | scaffolder | 5 | 5 | 5 | 5 | **5** | N/A (scaffold-only) | GOOD |
| 14 | spec-writer | 5 | 5 | 5 | 5 | **5** | N/A (scaffold-only) | GOOD |
| 15 | spec-reviewer | 5 | 5 | 5 | 5 | **5** | N/A (scaffold-only) | GOOD |
| 16 | priority-engine | 5 | 4 | 4 | 5 | **4** | N/A (standalone) | GOOD |
| 17 | reproducer | 5 | 5 | 5 | 5 | **5** | N/A (bug-only) | GOOD |
| 18 | browser-verifier | 5 | 5 | 5 | 5 | **5** | N/A (bug-only) | GOOD |
| 19 | deployment-verifier | 5 | 5 | 5 | 5 | **5** | N/A (infra) | GOOD |

### Aggregate Statistics
- **GOOD:** 14 agents (triage-analyst, code-analyst, rollback-agent, acceptance-gate, spec-analyst, architect, stack-selector, scaffolder, spec-writer, spec-reviewer, priority-engine, reproducer, browser-verifier, deployment-verifier)
- **NEEDS_UPDATE:** 4 agents (reviewer, test-engineer, e2e-test-engineer, publisher)
- **BROKEN:** 1 agent (fixer)

### Priority-Ordered Fix List

1. **fixer.md — CRITICAL** (blocks feature/scaffold pipelines)
   - Step 1 (line 20): Will incorrectly Block in non-bug modes
   - Step 5 (line 29): TDD framing wrong for features
   - Frontmatter description (line 3): Bug-specific

2. **reviewer.md — MEDIUM** (degrades feature/scaffold review quality)
   - Step 1 (line 20): References non-existent bug artifacts
   - Step 4 (line 30): "Root cause" checklist item irrelevant for features

3. **publisher.md — MEDIUM** (wrong PR titles/descriptions for features)
   - Step 6 (line 57): "Fix:" hardcoded in PR title
   - Step 6 (line 59): "Root Cause" listed as PR section

4. **test-engineer.md — LOW** (minor terminology mismatch)
   - Step 1 (line 20): "bug report" reference
   - Step 3 (line 25): "regression test" framing

5. **e2e-test-engineer.md — LOW** (minor terminology mismatch)
   - Step 1 (line 20): "bug report" reference
