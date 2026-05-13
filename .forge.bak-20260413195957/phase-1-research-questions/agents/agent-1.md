# Agent Dispatch Map Audit — Q1, Q4, Q9

**Date:** 2026-04-13
**Source files read:** skills/fix-ticket/SKILL.md, skills/fix-bugs/SKILL.md, skills/implement-feature/SKILL.md, skills/scaffold/SKILL.md

---

## Q1: Agent Dispatch Maps per Pipeline

### 1a. fix-ticket Pipeline

| Line | Agent | Step | Context Passed | Model | Conditional? |
|------|-------|------|----------------|-------|--------------|
| 129 | `triage-analyst` | Step 3: Triage | Type/MCP server name | sonnet | YES — skippable via profile; skipped in dry-run |
| 151 | `code-analyst` | Step 4: Code-analyst | Root cause iterations, Module Docs path | sonnet | YES — skippable via profile; skipped in dry-run |
| 178 | `architect` | Step 4b: Decomposition decision | Code-analyst impact report, issue details, Module Docs path, max subtasks | opus | YES — only when DECOMPOSE decision (FORCE or AUTO+heuristic) |
| 430 | `reproducer` | Step 4e: Browser Reproduction | Issue ID+title+description, triage output, code-analyst report, Browser Verification config | sonnet | YES — only if `browser_reproduce = true` |
| 444 | `fixer` | Step 5: Fixer | Max build retries, Block Comment Template, AC from triage | opus | NO — always runs |
| 478 | `reviewer` | Step 7: Reviewer | Max fixer iterations, AC from triage | opus | NO — always runs (loop with fixer) |
| 498 | `test-engineer` | Step 8: Test-engineer | Max test attempts | sonnet | YES — skippable via profile |
| 511 | `deployment-verifier` | Step 8a-deploy: Deployment guard | Action=start, Local Deployment config, run directory | sonnet | YES — only if `local_deployment_configured=true` AND E2E stage present |
| 527 | `e2e-test-engineer` | Step 8b: E2E test-engineer | (from E2E Test config) | sonnet | YES — only if E2E Test section exists or in profile Extra stages |
| 534 | `browser-verifier` | Step 8b-browser: Browser Verification | Full Browser Verification config, reproduction result, fixer diff, AC from triage | sonnet | YES — only if `browser_verify = true` |
| 553 | `acceptance-gate` | Step 8c: Acceptance gate | AC from triage, changed files | sonnet | YES — only if AC >= 3 OR complexity >= M |
| 575 | `publisher` | Step 9: Result | Type/MCP, Extra labels | haiku | YES — user decision (or --yolo) |

**Block handler (step X):**
- `rollback-agent` is implicitly invoked via `core/block-handler.md` — not explicitly dispatched in fix-ticket SKILL.md but referenced in fix-bugs and implement-feature block handler definitions.

**Decomposition subtask loop** (step 4c) re-dispatches inline: fixer (opus), reviewer (opus), test-engineer (sonnet), deployment-verifier (sonnet), e2e-test-engineer (sonnet) — same agents, same context.

---

### 1b. fix-bugs Pipeline

| Line | Agent | Step | Context Passed | Model | Conditional? |
|------|-------|------|----------------|-------|--------------|
| 105 | `triage-analyst` | Step 2: Triage (parallel per bug) | Type/MCP server name | sonnet | YES — skippable via profile |
| 130 | `code-analyst` | Step 3: Code-analyst (parallel per bug) | Root cause iterations, Module Docs path | sonnet | YES — skippable via profile |
| 168 | `architect` | Step 3b: Decomposition decision | Code-analyst impact report, issue details, Module Docs path, max subtasks | opus | YES — only when DECOMPOSE decision |
| 417 | `reproducer` | Step 3e: Browser Reproduction | Issue ID+title+description, triage output, code-analyst report, Browser Verification config | sonnet | YES — only if `browser_reproduce = true` |
| 431 | `fixer` | Step 4: Fixer (per bug) | Max build retries, Block Comment Template, AC from triage | opus | NO — always runs |
| 465 | `reviewer` | Step 6: Reviewer (per bug) | Max fixer iterations, AC from triage | opus | NO — always runs (loop with fixer) |
| 485 | `test-engineer` | Step 7: Test-engineer (per bug) | Max test attempts | sonnet | YES — skippable via profile |
| 498 | `deployment-verifier` | Step 7a-deploy: Deployment guard | Action=start, Local Deployment config, run directory | sonnet | YES — only if `local_deployment_configured=true` AND E2E stage present |
| 514 | `e2e-test-engineer` | Step 7b: E2E test-engineer (per bug) | (from E2E Test config) | sonnet | YES — only if E2E Test section exists or in profile Extra stages |
| 521 | `browser-verifier` | Step 7b-browser: Browser Verification | Full Browser Verification config, reproduction result, fixer diff, AC from triage | sonnet | YES — only if `browser_verify = true` |
| 540 | `acceptance-gate` | Step 7c: Acceptance gate | AC from triage, changed files | sonnet | YES — only if AC >= 3 OR complexity >= M |
| 561 | `publisher` | Step 8: Publisher (per bug) | Type/MCP, Extra labels | haiku | NO — always runs for each bug |

**Block handler (step X):**
- `rollback-agent` (haiku) — invoked per block event via `core/block-handler.md`

---

### 1c. implement-feature Pipeline

| Line | Agent | Step | Context Passed | Model | Conditional? |
|------|-------|------|----------------|-------|--------------|
| 174 | `spec-analyst` | Step 3: Spec-analyst | Issue details from tracker | sonnet | YES — skippable via profile |
| 186 | `architect` | Step 4: Architect — design | Spec-analyst output, codebase access, Module Docs path | opus | NO — always runs |
| (implied) | `architect` | Step 5: Decomposition (if DECOMPOSE) | (same as step 4 output, already in memory) | opus | YES — only when DECOMPOSE indicated; reuses Step 4 output |
| 447 | `fixer` | Step 6b: Fixer | Architectural design, subtask scope, AC | opus | NO — always runs |
| 461 | `reviewer` | Step 6d: Reviewer | Diff from fixer, AC from spec-analyst | opus | NO — always runs (loop with fixer) |
| 484 | `test-engineer` | Step 6e: Test-engineer | Changed files, AC | sonnet | YES — skippable via profile |
| 499 | `deployment-verifier` | Step 6f-deploy: Deployment guard | Action=start, Local Deployment config, run directory | sonnet | YES — only if `local_deployment_configured=true` AND E2E stage present |
| 515 | `e2e-test-engineer` | Step 6g: E2E test (optional) | (from E2E Test config) | sonnet | YES — only if E2E Test section exists or in profile Extra stages |
| 521 | `acceptance-gate` | Step 6h: Acceptance gate | Full feature AC from spec-analyst, changed files | sonnet | YES — only in decomposition mode (skipped in single-pass) |
| 572 | `publisher` | Step 10: Publisher | PR Description Template, Labels, Remote, Base branch, changed files, Extra labels | haiku | YES — user decision (or --yolo) |
| 606 | `rollback-agent` | Step X: Block handler | Git revert + issue state | haiku | YES — only on block |

---

### 1d. scaffold Pipeline

| Line | Agent | Step | Context Passed | Model | Conditional? |
|------|-------|------|----------------|-------|--------------|
| 271 | `stack-selector` | Step L1 (--no-implement legacy) | Project description + tech flags | sonnet | YES — only in --no-implement mode |
| 282 | `scaffolder` | Step L2 (--no-implement legacy) | Stack selection + project description, working dir = temp | sonnet | YES — only in --no-implement mode |
| 405 | `spec-reviewer` | Step 1: Specification Phase (--spec input) | spec_path for validation | opus | YES — only when --spec flag provided |
| 418 | `spec-writer` | Step 1: Specification Phase | Input source + mode + tech stack flags | opus | YES — skipped if --spec provided and no issues |
| 425 | `spec-reviewer` | Step 1: spec-writer ↔ spec-reviewer loop | Review of spec/ folder | opus | YES — loop with spec-writer, max Spec iterations |
| 457 | `scaffolder` | Step 3: Scaffold Skeleton | spec/README.md Tech Stack + project description, temp dir, scaffold-v2 mode | sonnet | NO — always runs in main flow |
| 606 | `architect` | Step 5: Architecture & Decomposition | All formatted epic specs + scaffolded codebase | opus | NO — always runs in main flow |
| 728 | `spec-reviewer` | Step 7b: Spec Compliance Check (verify mode) | --verify mode, spec/ vs codebase | opus | YES — always after implementation loop |
| 674 | `fixer` | Step 7a: Feature Implementation Loop (per subtask) | Subtask scope + AC + architecture design + Max build retries | opus | NO — always in implementation loop |
| 681 | `reviewer` | Step 7b: Reviewer (per subtask) | Diff from fixer + AC + Max fixer iterations | opus | NO — always in implementation loop |
| 691 | `test-engineer` | Step 7c: Test-engineer (per subtask) | Changed files, AC, Max test attempts | sonnet | NO — always in implementation loop |
| 707 | `rollback-agent` | Block handler (7a/7b/7c) | "No issue tracker context — skip issue tracker updates" | haiku | YES — only on block |
| 745 | `deployment-verifier` | Step 8: E2E pre-check | Action=start, Local Deployment config, run dir=.ceos-agents/scaffold/ | sonnet | YES — only if Local Deployment section exists in generated CLAUDE.md |
| 756 | `e2e-test-engineer` | Step 8: E2E Tests | spec/verification.md test strategy, implemented features, AC | sonnet | YES — only if E2E Test section in generated CLAUDE.md |

**Note on --no-implement (legacy v3.x flow):** dispatches only `stack-selector` + `scaffolder`, then validation is done directly by the skill (bash commands), no other agents invoked.

---

### 1e. Cross-Reference: Agents Shared Across Pipelines

| Agent | fix-ticket | fix-bugs | implement-feature | scaffold | Notes |
|-------|-----------|----------|------------------|----------|-------|
| `triage-analyst` | YES (Step 3) | YES (Step 2) | NO | NO | Bug pipelines only |
| `code-analyst` | YES (Step 4) | YES (Step 3) | NO | NO | Bug pipelines only |
| `spec-analyst` | NO | NO | YES (Step 3) | NO | Feature pipeline only |
| `architect` | YES (Step 4b, conditional) | YES (Step 3b, conditional) | YES (Step 4, always) | YES (Step 5, always) | Universal — decomposition in bug, design in feature/scaffold |
| `spec-writer` | NO | NO | NO | YES (Step 1) | Scaffold only |
| `spec-reviewer` | NO | NO | NO | YES (Step 1 x2, Step 7b) | Scaffold only — used in 3 distinct roles |
| `stack-selector` | NO | NO | NO | YES (--no-implement only) | Scaffold legacy only |
| `scaffolder` | NO | NO | NO | YES (Step L2, Step 3) | Scaffold only |
| `reproducer` | YES (Step 4e) | YES (Step 3e) | NO | NO | Bug pipelines only |
| `fixer` | YES (Step 5) | YES (Step 4) | YES (Step 6b) | YES (Step 7a) | Universal |
| `reviewer` | YES (Step 7) | YES (Step 6) | YES (Step 6d) | YES (Step 7b) | Universal |
| `test-engineer` | YES (Step 8) | YES (Step 7) | YES (Step 6e) | YES (Step 7c) | Universal |
| `e2e-test-engineer` | YES (Step 8b) | YES (Step 7b) | YES (Step 6g) | YES (Step 8) | Universal — always conditional |
| `deployment-verifier` | YES (Step 8a-deploy) | YES (Step 7a-deploy) | YES (Step 6f-deploy) | YES (Step 8) | Universal — always conditional |
| `browser-verifier` | YES (Step 8b-browser) | YES (Step 7b-browser) | NO | NO | Bug pipelines only |
| `acceptance-gate` | YES (Step 8c, conditional) | YES (Step 7c, conditional) | YES (Step 6h, conditional) | NO | Bug+feature; scaffold has no acceptance gate |
| `publisher` | YES (Step 9) | YES (Step 8) | YES (Step 10) | NO | Bug+feature only; scaffold has no PR |
| `rollback-agent` | YES (Step X, via core) | YES (Step X) | YES (Step X) | YES (Block 7a-7c) | Universal — all pipelines |

---

## Q4: Mode-Specific Agent Gaps

### Bug Pipeline (fix-ticket / fix-bugs)

**Chain:** `triage-analyst → code-analyst → [reproducer] → fixer ↔ reviewer → [test-engineer] → [deployment-verifier] → [e2e-test-engineer] → [browser-verifier] → [acceptance-gate] → publisher`

**Analysis:**

1. **Handoff chain is structurally complete.** All major roles are present: intake (triage), analysis (code-analyst), implementation (fixer), quality (reviewer, test-engineer), publication (publisher).

2. **Gaps identified:**

   - **Gap: No smoke check between triage and fixer in fix-bugs.** fix-ticket has a smoke check step (7a) after reviewer, and fix-bugs has the same (step 6a). But in decomposition mode (steps 4c / 3c), the per-subtask loop within both bug skills does NOT include the post-review smoke check. The subtask loop does run Build+Test after fixer, but there is no explicit post-reviewer smoke check between reviewer and test-engineer in the decomposition path. This means a regression introduced during the fixer-reviewer loop inside decomposition could go undetected until test-engineer.

   - **Gap: acceptance-gate is absent from decomposition subtask loops.** The per-subtask execution (step 4c in fix-ticket, step 3c in fix-bugs) runs fixer → reviewer → test-engineer but does NOT include acceptance-gate after test-engineer. Acceptance-gate is only in the post-decomposition main path (step 8c/7c). This means AC fulfillment is checked after all subtasks complete, not after each subtask — so a subtask that regresses AC compliance is only caught late.

   - **Gap: Context discontinuity between triage-analyst output and reproducer.** The reproducer receives "triage output including reproduction_steps if present" — but the triage-analyst is responsible for inferring reproduction steps from the raw issue text. If triage-analyst outputs generic steps (not machine-parseable), the reproducer has weak structured input. No agent normalizes or validates the reproduction_steps format before passing it downstream.

   - **Gap: No integration with rollback-agent in fix-ticket block handler section.** fix-ticket's Step X says "Follow `core/block-handler.md`" without explicitly mentioning rollback-agent, while fix-bugs and implement-feature explicitly list "Run rollback-agent (Task tool, model: haiku)". This is an inconsistency — fix-ticket relies entirely on the core file.

3. **Chain completeness verdict:** MOSTLY COMPLETE. The core flow (triage → code-analyst → fixer → reviewer → test-engineer → publisher) has no missing links. Optional stages (reproducer, browser-verifier, acceptance-gate, e2e-test-engineer) are gated correctly.

---

### Feature Pipeline (implement-feature)

**Chain:** `spec-analyst → architect → fixer ↔ reviewer → [test-engineer] → [deployment-verifier] → [e2e-test-engineer] → [acceptance-gate] → publisher`

**Analysis:**

1. **Notable design difference vs. bug pipeline:** There is no `code-analyst` in implement-feature — architect takes on both design and code understanding. This is intentional (new feature = no existing bug root cause to find). Spec-analyst feeds architect directly.

2. **Gaps identified:**

   - **Gap: No code-analyst before architect.** The architect receives the spec-analyst output + "access to code" but no dedicated code impact analysis. For features touching large existing codebases, architect may miss conflicts or pre-existing technical debt. A dedicated analysis step between spec-analyst and architect would surface this.

   - **Gap: Acceptance-gate is skipped in single-pass mode.** Step 6h explicitly states: "In single-pass mode (no decomposition), this step is skipped." This means simple features (which don't decompose) receive NO acceptance-gate verification. Only decomposed features get AC gate coverage. This creates an asymmetry: the more complex the feature, the more validation; the simpler the feature, the less.

   - **Gap: spec-analyst AC writeback to tracker.** The CLAUDE.md architecture overview mentions "spec-analyst posts acceptance criteria as a separate comment to the issue tracker" as a known behavior, but this is NOT explicitly orchestrated in implement-feature SKILL.md — it relies on the spec-analyst agent definition itself. If the agent definition omits this, the skill does not verify or retry it.

   - **Gap: No browser-verifier equivalent.** Bug pipelines have browser-verifier to confirm visual/UX acceptance. Feature pipelines have no equivalent — new features implementing UI changes have no visual verification step. The e2e-test-engineer covers functional tests but not visual regression.

3. **Chain completeness verdict:** COMPLETE for core logic. Gaps exist at the edges (no code-analyst pre-check, acceptance-gate skip in single-pass, no visual verification for UI features).

---

### Scaffold Pipeline (scaffold)

**Chain:** `[spec-writer ↔ spec-reviewer] → scaffolder → architect → fixer ↔ reviewer → test-engineer → [spec-reviewer --verify] → [e2e-test-engineer] → publisher (ABSENT)`

**Analysis:**

1. **Significant structural difference: No publisher.** Scaffold does not create a PR. It commits directly to the initialized repository. This is intentional (fresh project, no base branch to PR into) but means the "publication" of the scaffold output is just git init + push.

2. **Gaps identified:**

   - **Gap: No acceptance-gate in scaffold.** After the implementation loop (Step 7), there is a spec compliance check (Step 7b, spec-reviewer --verify), which is the closest analog to acceptance-gate. However, spec-reviewer in verify mode checks specification coverage — it is a read-only comparison, not an agent that signals REQUEST_CHANGES to send back to fixer. If the compliance check fails, it only warns (in Interactive/YOLO-checkpoint mode) or blocks (in Full YOLO). There is no fixer-iteration loop driven by spec compliance results.

   - **Gap: spec-reviewer is used in three distinct roles.** In Step 1, spec-reviewer validates the incoming spec (--spec flag). In Step 1 loop, spec-reviewer reviews spec-writer output. In Step 7b, spec-reviewer runs in --verify mode against the implemented codebase. These are three different behavioral modes of the same agent. The agent's `--verify` mode is a second persona with different inputs, outputs, and integration expectations. This creates cognitive load and possible agent confusion without a dedicated verify agent.

   - **Gap: No per-subtask post-test AC gate.** Scaffold's implementation loop (Step 7) runs fixer → reviewer → test-engineer per subtask, but has no acceptance-gate. This matches implement-feature decomposition mode, but in scaffold ALL features go through this loop (there is no single-pass alternative). Deferred to Step 7b spec-reviewer --verify, which is post-loop.

   - **Gap: Hooks explicitly excluded from scaffold.** Step 7 explicitly states: "Hooks (Pre-fix, Post-fix, Pre-publish, Post-publish) are not executed during scaffold." This is intentional (no CI yet), but it means the pipeline is not extensible at scaffold time for projects that do have external services to call during creation.

   - **Gap: No rollback-agent cleanup for infrastructure operations.** The scaffold block handler (Step 7 block handler) calls rollback-agent with "No issue tracker context — skip issue tracker updates." However, if Step 4e (tracker issue creation) has already run and created issues before the block, no agent cleans up those created tracker issues. The rollback is code-only.

3. **Chain completeness verdict:** COMPLETE for code generation loop. Gaps exist in post-implementation validation (no AC gate), publisher absence is by design, and the three-role spec-reviewer conflates too many responsibilities.

---

## Q9: Missing Agents

### Agents That Should Be Added

**1. `code-reviewer` (separate from `reviewer`)**

Currently, `reviewer` serves as both AC fulfillment checker and code quality reviewer. The AC Fulfillment section in reviewer output mixes domain concerns (is the feature done?) with engineering concerns (is the code correct?). A dedicated `code-quality-reviewer` (read-only, sonnet) that runs in parallel with the existing AC-focused reviewer would allow the two concerns to be separated. However, this doubles model calls. Low priority.

**2. `scaffold-verifier` or `spec-compliance-agent` (dedicated verify-mode agent)**

Currently spec-reviewer is used in three distinct behavioral roles (spec validation, spec review loop, implementation compliance check). The --verify mode behavior of spec-reviewer is sufficiently different from its primary spec-review role that it warrants a dedicated agent (`spec-compliance-agent`). This agent would:
- Be read-only (like spec-reviewer)
- Take implemented codebase + spec/ as input
- Emit structured PASS/PARTIAL/FAIL with per-AC evidence
- Have a clearer contract (no confusion with spec iteration review role)

**Priority: Medium.** The current spec-reviewer --verify mode works, but the dual-role causes agent prompt ambiguity.

**3. `visual-verifier` (new, UI regression detection)**

Bug pipelines have `browser-verifier` for confirming bug fixes visually. Feature pipelines have no visual verification step. A `visual-verifier` agent (sonnet, analogous to browser-verifier) could:
- Run after test-engineer in implement-feature
- Use browser automation to verify new UI elements/flows meet spec
- Emit VERIFIED/PARTIAL/FAILED similar to browser-verifier

**Priority: Low.** Only relevant for UI-heavy projects. E2E tests partially cover this.

**4. `context-bridge` (inter-subtask summary agent)**

In decomposition mode, each subtask receives "summary of previous subtasks (what changed, diff summary)" as context. This summary is currently constructed by the skill itself (in-memory). A dedicated `context-bridge` agent (haiku, fast/cheap) could produce structured handoff summaries between subtasks — reducing context window pressure and improving the relevance of what fixer receives.

**Priority: Low.** The current skill-constructed summary works. This is an optimization, not a gap.

### Agents That Should Be Reconsidered

**1. `spec-reviewer` — split into two agents**

Recommendation: Split into `spec-reviewer` (spec iteration review, opus) and `spec-verifier` (implementation compliance check, sonnet). The current dual role mixes two contracts:
- Iteration review: evaluate draft spec, emit REVISE/APPROVE
- Compliance check: evaluate implementation against final spec, emit PASS/PARTIAL/FAIL with evidence

Keeping both in one agent means the agent definition must handle two very different inputs and output formats. A split would make each agent's contract clean and independently evolvable.

**2. `rollback-agent` — add explicit dispatch to fix-ticket block handler**

fix-ticket Step X defers entirely to `core/block-handler.md` without mentioning rollback-agent explicitly. fix-bugs and implement-feature explicitly list "Run rollback-agent (Task tool, model: haiku)". This inconsistency should be resolved by either:
- Adding explicit rollback-agent dispatch to fix-ticket Step X (preferred — makes all three skills consistent)
- Or confirming that `core/block-handler.md` always dispatches rollback-agent (and documenting this explicitly)

### Agents That Could Be Merged

**1. `triage-analyst` + `code-analyst` — considered and rejected**

These could theoretically merge (both are read-only, sonnet, run sequentially). However, keeping them separate is correct:
- triage-analyst reads the issue tracker (external, MCP-dependent)
- code-analyst reads the codebase (local filesystem)
- They produce orthogonal outputs (AC/severity/area vs. risk/affected_files/root_cause)
- Separation allows independent skipping via pipeline profiles
- Context window discipline: each agent stays focused

**2. `acceptance-gate` + `reviewer` — considered and rejected**

Reviewer checks AC fulfillment via the "AC Fulfillment section" in its output. Acceptance-gate checks AC with code + test evidence. Merging would overload reviewer's role (it already runs in a tight loop with fixer). Keeping them separate allows the reviewer to iterate quickly and the acceptance-gate to run once with full evidence.

---

## Summary Table

| Finding | Category | Priority |
|---------|----------|----------|
| No post-reviewer smoke check inside decomposition subtask loops (bug pipelines) | Q4 Gap | Medium |
| No acceptance-gate inside decomposition subtask loops | Q4 Gap | Low |
| Acceptance-gate skipped in single-pass implement-feature | Q4 Gap | Medium |
| spec-reviewer plays 3 distinct roles — split recommended | Q9 Missing/Merge | Medium |
| rollback-agent not explicitly dispatched in fix-ticket Step X | Q4 Gap | Low |
| No code-analyst pre-check before architect in implement-feature | Q4 Gap | Low |
| No visual-verifier for UI features in implement-feature | Q9 Missing | Low |
| No cleanup agent for tracker issues created before a scaffold block | Q4 Gap | Low |
| `spec-compliance-agent` as dedicated verify-mode agent | Q9 Missing | Medium |
| Scaffold hooks intentionally excluded — not a gap, by design | Note | — |
| Acceptance-gate absent from scaffold — spec-reviewer --verify is the substitute | Q4 Gap | Low |
