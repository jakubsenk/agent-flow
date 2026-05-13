# Expert Evaluation: AC-Driven Pipeline Proposals

**Date:** 2026-03-08
**Evaluator:** Senior AI Pipeline Architect (independent review)
**Scope:** 22 proposals across 3 discussion documents
**Status:** EVALUATION COMPLETE

---

## Table of Contents

1. [Research Findings](#1-research-findings)
2. [Proposal-by-Proposal Verdicts](#2-proposal-by-proposal-verdicts)
3. [Cross-Cutting Analysis](#3-cross-cutting-analysis)
4. [Final Recommendation](#4-final-recommendation)

---

## 1. Research Findings

### 1.1 Acceptance Criteria in CI/CD Pipelines

**Finding: AC-driven pipeline validation is a proven pattern, but with caveats.**

Acceptance Test-Driven Development (ATDD) is well-established in CI/CD. Jez Humble and David Farley's *Continuous Delivery* defines the "acceptance test stage" as a mandatory pipeline gate that validates business requirements, not just code behavior. Semaphore's guide on BDD acceptance testing confirms that integrating BDD tests into CI/CD pipelines ensures "continuous validation of features... meeting user expectations before deployment" ([Semaphore](https://semaphore.io/blog/bdd-acceptance-testing)). The InformIT excerpt from *Continuous Delivery* specifically describes the "Automated Acceptance Test Gate" as a distinct pipeline stage ([InformIT](https://www.informit.com/articles/article.aspx?p=1621865&seqNum=5)).

**Critical caveat:** In all these references, acceptance tests are *human-written* before or during development. No source describes AI-extracted AC flowing through an automated pipeline. The ceos-agents proposal is novel — it asks an LLM to *synthesize* AC from vague tickets, not execute pre-written tests. This is a meaningful distinction: the quality of AI-generated AC is unproven at scale.

Additionally, QAbash describes an end-to-end workflow where "Product Managers create PRDs with BDD-formatted acceptance criteria before development begins. These Gherkin scenarios flow from tickets into test case design" with an 80% reduction in manual test writing ([QAbash](https://www.qabash.com/prd-bdd-ticketing-qa-workflow-transformation/)). This is the closest published pattern to what ceos-agents proposes — but notably, the AC extraction is still done by humans, not AI.

**Sources:**
- [Semaphore: Accelerate CI/CD with BDD and Acceptance Testing](https://semaphore.io/blog/bdd-acceptance-testing)
- [InformIT: The Automated Acceptance Test Gate](https://www.informit.com/articles/article.aspx?p=1621865&seqNum=5)
- [QAbash: PRD-Based Ticketing + BDD](https://www.qabash.com/prd-bdd-ticketing-qa-workflow-transformation/)
- [Aspire Systems: ATDD and Continuous Delivery](https://www.aspiresys.com/articles/atdd-applied-approach-to-continuous-delivery.pdf)

### 1.2 AI Agent Pipeline Orchestration

**Finding: Quality gates between agent stages measurably improve success rates.**

MetaGPT's ICLR 2024 paper demonstrates that adding explicit verifier and reviewer agents to a multi-agent software engineering pipeline produces a +15.6% success rate improvement over pipelines without them ([MetaGPT, ICLR 2024](https://proceedings.iclr.cc/paper_files/paper/2024/file/6507b115562bb0a305f1958ccc87355a-Paper-Conference.pdf)). MetaGPT's approach — SOPs (Standard Operating Procedures) that define intermediate structured outputs between agents — is architecturally similar to ceos-agents' command-driven orchestration.

Current SWE-bench results provide calibration for what's achievable:
- **SWE-bench Verified** (curated, easier): Top agents achieve 70-81% pass@3 ([Verdent](https://www.verdent.ai/blog/swe-bench-verified-technical-report))
- **SWE-bench Pro Public**: ~45% (Claude Opus 4.5) ([Scale AI Leaderboard](https://scale.com/leaderboard/swe_bench_pro_public))
- **SWE-bench Pro Private** (unseen codebases): ~24% ([Scale AI Leaderboard](https://scale.com/leaderboard/swe_bench_pro_private))

The gap between Verified (~75%) and Pro Private (~24%) is instructive: agents perform far worse on novel codebases. This suggests that pipeline improvements that provide better context (AC, domain knowledge, failure history) could have outsized impact on the hardest cases.

The GitHub Engineering Blog identifies three core patterns for reliable multi-agent workflows: (1) **typed schemas and strict contracts** at every agent boundary, (2) **constrained action spaces** so agents cannot take conflicting actions, and (3) **MCP as the enforcement layer**. The key takeaway: "validation gates between stages should be machine-checkable data contracts, not free-form text hand-offs" ([GitHub Blog](https://github.blog/ai-and-ml/generative-ai/multi-agent-workflows-often-fail-heres-how-to-engineer-ones-that-dont/)). This directly supports the AC-as-contract framing.

**Sources:**
- [MetaGPT: Meta Programming for a Multi-Agent Collaborative Framework (ICLR 2024)](https://arxiv.org/html/2308.00352v6)
- [SWE-bench Pro Leaderboard (Scale AI)](https://scale.com/leaderboard/swe_bench_pro_public)
- [Epoch AI: SWE-bench Verified](https://epoch.ai/benchmarks/swe-bench-verified)
- [GitHub Blog: Multi-agent workflows often fail](https://github.blog/ai-and-ml/generative-ai/multi-agent-workflows-often-fail-heres-how-to-engineer-ones-that-dont/)

### 1.3 Requirements Traceability

**Finding: Full traceability is high-overhead; lightweight automation makes it viable.**

Academic research (Springer, ACM) confirms that traceability in agile projects is "often seen as unnecessary and unwanted due to the perceived overhead" ([Springer](https://link.springer.com/chapter/10.1007/978-1-4471-2239-5_12)). Manual RTMs (Requirements Traceability Matrices) are "daunting and error-prone" in agile contexts ([Ketryx](https://www.ketryx.com/blog/best-practices-for-maintaining-a-requirement-traceability-matrix-in-agile)).

However, the consensus is that *automated* traceability is viable. Tools that automatically link features to requirements and update the matrix on change significantly reduce overhead. The ceos-agents approach — where the pipeline itself generates and validates the traceability (AC → subtask → code → test) — is lighter than traditional RTMs because it's ephemeral (generated per pipeline run) rather than persistent.

The seminal Gotel & Finkelstein paper (IEEE ICRE, 1994) — based on empirical study of 100+ practitioners — demonstrates that "an all-encompassing traceability solution is impractical" and that most problems stem from inadequate early-stage tracing ([Gotel & Finkelstein](https://ieeexplore.ieee.org/document/292398/)). Microsoft's Azure DevOps documentation shows the modern practical model: traceability as "an automatic byproduct of linking commits to work items, test results to builds, and PRs to issues — no separate matrix required" ([Microsoft Learn](https://learn.microsoft.com/en-us/azure/devops/cross-service/end-to-end-traceability?view=azure-devops)).

**Key insight for ceos-agents:** The `maps_to` field in the architect's task tree (Feature Proposal #3) is a lightweight traceability approach. It doesn't require a separate tool or database — just a field in an existing YAML structure. This follows the Azure DevOps pattern: traceability as a byproduct of the normal workflow, not a separate maintenance burden.

**Sources:**
- [Springer: Traceability in Agile Projects (Cleland-Huang)](https://link.springer.com/chapter/10.1007/978-1-4471-2239-5_12)
- [Gotel & Finkelstein: Analysis of the Requirements Traceability Problem (IEEE 1994)](https://ieeexplore.ieee.org/document/292398/)
- [Microsoft Learn: End-to-End Traceability in Azure DevOps](https://learn.microsoft.com/en-us/azure/devops/cross-service/end-to-end-traceability?view=azure-devops)
- [Ketryx: Best Practices for RTM in Agile](https://www.ketryx.com/blog/best-practices-for-maintaining-a-requirement-traceability-matrix-in-agile)

### 1.4 Feedback Loops in AI Coding Agents

**Finding: Retrospective learning is an active research area with early positive results, but no production-proven solution exists.**

The trajectory analysis research ([arXiv: 2506.18824](https://arxiv.org/html/2506.18824v1)) studies agents through "thought-action-result trajectories" to understand success/failure patterns. OpenHands stores memory "as code in a Git repository" for cross-session context ([OpenHands paper](https://arxiv.org/abs/2407.16741)). DeepSWE uses reinforcement learning with test-time scaling for retrospective reflections.

No production AI coding tool has a proven "learn from failed attempts" mechanism that demonstrably improves future performance *across sessions*. The closest analogy is OpenHands' "micro agents" — repository-level context files.

However, the **ACE (Agentic Context Engineering) paper** ([arXiv: 2510.04618](https://arxiv.org/abs/2510.04618)) provides the strongest evidence for the ceos-agents fix retrospective approach. ACE treats context as "evolving playbooks" using three roles: Generator (produces reasoning), Reflector (distills insights from successes and errors), and Curator (integrates insights into structured updates). This is explicitly NOT fine-tuning — it is **structured context accumulation**. ACE delivers **+8.6% average performance gains** over baselines while reducing adaptation latency by 86.9%.

The critical finding: naive context accumulation causes "context collapse" (iterative rewriting erodes details). The history must be **curated and structured**, not simply appended. This validates the `.claude/fix-history/` approach but adds a design constraint: the retrospective must produce structured, categorized output — not free-form narrative.

Separately, the **SWE-Effi paper** ([arXiv: 2509.09853](https://arxiv.org/abs/2509.09853)) identifies the "token snowball" effect: agents lacking futility detection enter expensive repetitive loops consuming 4x+ the tokens of successful attempts (8.8M vs 1.8M tokens for SWE-Agent). No mainstream tool has solved stagnation detection — they rely on budget caps as the only termination mechanism. This is relevant to the mid-fix decomposition proposal (B6): detecting "I'm stuck" and escalating is a validated need.

**Sources:**
- [ACE: Agentic Context Engineering — Evolving Contexts for Self-Improving LMs](https://arxiv.org/abs/2510.04618)
- [SWE-Effi: Re-Evaluating SE Agent Effectiveness Under Resource Constraints](https://arxiv.org/abs/2509.09853)
- [Understanding SE Agents: Thought-Action-Result Trajectories](https://arxiv.org/html/2506.18824v1)
- [OpenHands: An Open Platform for AI Software Developers](https://arxiv.org/abs/2407.16741)
- [AI Agentic Programming: Survey of Techniques (arXiv: 2508.11126)](https://arxiv.org/abs/2508.11126)

### 1.5 Manual Verification Gates

**Finding: Manual approval gates are a standard, well-supported CI/CD pattern.**

Every major CI/CD platform supports manual approval gates: JFrog Pipelines, Azure DevOps, GoCD, GitHub Actions (environments). Best practice from JFrog: "configure a manual approval gate for any step... it will suspend execution and set its status to Pending" ([JFrog](https://jfrog.com/blog/proceed-with-care-how-to-use-approval-gates-in-pipelines/)). The InfoQ article on pipeline quality gates recommends manual gates for production deployments while automating lower environments ([InfoQ](https://www.infoq.com/articles/pipeline-quality-gates/)).

**Relevance to ceos-agents:** Manual verification mode (Bugfix #4, Feature #7) is a proven pattern. The implementation question is *where* to put the gate and *how* to resume. The proposals correctly place it after automated verification, before publish — matching the industry pattern of "automated gates first, manual gate before production."

**Sources:**
- [JFrog: How to Use Approval Gates in Pipelines](https://jfrog.com/blog/proceed-with-care-how-to-use-approval-gates-in-pipelines/)
- [InfoQ: Pipeline Quality Gates](https://www.infoq.com/articles/pipeline-quality-gates/)
- [GoCD: Control Deployments Using Manual Gates](https://www.gocd.org/2017/05/23/control-deployments-manual-approvals.html)

### 1.6 Given/When/Then as Universal AC Format

**Finding: GWT is beneficial as a communication tool but has real limitations for system-level and UX criteria.**

Ranorex's analysis confirms: GWT is "challenging to fit... particularly when working with user stories that describe system-level functionality" or "design and user experience constraints" ([Ranorex](https://www.ranorex.com/blog/given-when-then-tests/)). AltexSoft recommends rule-oriented (bulleted list) format as an alternative when GWT doesn't fit ([AltexSoft](https://www.altexsoft.com/blog/acceptance-criteria-purposes-formats-and-best-practices/)). Thoughtworks confirms that GWT "provides value beyond just test automation" as a shared understanding tool ([Thoughtworks](https://www.thoughtworks.com/insights/blog/applying-bdd-acceptance-criteria-user-stories)).

**Assessment for Scaffold #2:** Mandating GWT for *all* AC is too rigid. It works well for behavioral criteria ("Given a logged-in user, When they click Submit, Then the form is saved") but poorly for NFRs ("response time < 200ms"), constraints ("must use PostgreSQL"), or UX requirements ("dashboard shows real-time data"). The proposal should allow GWT as the *preferred* format with rule-oriented as an accepted alternative.

A contrarian perspective from testRigor argues that "every test automation attempt with Gherkin-style syntax (Cucumber, SpecFlow, JBehave) has failed in practice" but distinguishes between "BDD as a communication philosophy (valuable) and Gherkin as a test automation syntax (problematic)" ([testRigor](https://testrigor.com/blog/why-cucumber-and-specflow-died/)). This supports the idea that GWT has value as a *specification* format even when the tooling layer is abandoned.

**Sources:**
- [Ranorex: When to Use Given-When-Then](https://www.ranorex.com/blog/given-when-then-tests/)
- [AltexSoft: Acceptance Criteria Purposes, Types, and Best Practices](https://www.altexsoft.com/blog/acceptance-criteria-purposes-formats-and-best-practices/)
- [Thoughtworks: Applying BDD Acceptance Criteria](https://www.thoughtworks.com/insights/blog/applying-bdd-acceptance-criteria-user-stories)
- [testRigor: Why Cucumber and SpecFlow Died](https://testrigor.com/blog/why-cucumber-and-specflow-died/)

### 1.7 Mid-Process Decomposition

**Finding: Dynamic task decomposition is an active research area with validated frameworks.**

The TDAG framework (published in *Neural Networks*, ScienceDirect) "dynamically decomposes complex tasks into smaller subtasks... dynamically adjusting subsequent subtasks based on the completion status of preceding ones" ([TDAG](https://arxiv.org/abs/2402.10178)). ADaPT (As-Needed Decomposition and Planning) "explicitly plans and decomposes complex sub-tasks only when the LLM is unable to execute them" — a demand-driven approach. UniDebugger uses a three-level hierarchical escalation: Level 1 for simple bugs, Level 2 if Level 1 fails, Level 3 for complex bugs.

**Key risk identified in literature:** "After decomposition, all subtasks become fixed and unalterable, so if an early subtask fails, the error propagates, resulting in the entire task's failure." This is exactly the risk the ceos-agents fixer's "mid-fix decomposition escape hatch" (Bugfix #6) aims to address.

**Sources:**
- [TDAG: Dynamic Task Decomposition and Agent Generation](https://arxiv.org/abs/2402.10178)
- [ADaPT: Advancing Agentic Systems — Dynamic Task Decomposition](https://arxiv.org/html/2410.22457v1)
- [Task Decomposition for Coding Agents: Architectures and Future Directions](https://mgx.dev/insights/task-decomposition-for-coding-agents-architectures-advancements-and-future-directions/a95f933f2c6541fc9e1fb352b429da15)

---

## 2. Proposal-by-Proposal Verdicts

### Bug-Fix Pipeline (7 proposals)

| # | Proposal | Verdict | Confidence | Rationale |
|---|----------|---------|------------|-----------|
| B1 | **AC extraction in triage** | **STRONG YES** | High | ATDD is a proven CI/CD pattern ([InformIT](https://www.informit.com/articles/article.aspx?p=1621865&seqNum=5)). The triage-analyst already outputs structured analysis — adding an AC section is a low-risk, high-leverage extension. The +20-30% estimate is aggressive but directionally correct: MetaGPT saw +15.6% from adding structured intermediate outputs ([ICLR 2024](https://arxiv.org/html/2308.00352v6)). The real risk is AC *quality* from AI synthesis, not the concept itself. |
| B2 | **AC verification step after testing** | **YES** | Medium | The "acceptance test gate" is a Continuous Delivery standard ([InformIT](https://www.informit.com/articles/article.aspx?p=1621865&seqNum=5)). However, implementing this as a *new agent* (ac-verifier) is overkill for bug fixes where AC are typically 2-3 items. Better: extend the test-engineer with an AC mapping section in its output. The +10-15% estimate is plausible only for feature-like bugs; for simple bugs, this step adds cost without value. **Condition: make it conditional on AC count >= 3.** |
| B3 | **Complexity estimation in triage** | **STRONG YES** | High | This is essentially what SWE-bench Pro measures — the gap between easy and hard problems. Adding an XS/S/M/L dimension is trivial (the dry-run report already uses this scale). It feeds directly into decomposition decisions. The +5-10% estimate is conservative and realistic. Zero config changes, minimal agent changes. No-brainer. |
| B4 | **Manual verification mode** | **CONDITIONAL** | Medium | Manual approval gates are well-established ([JFrog](https://jfrog.com/blog/proceed-with-care-how-to-use-approval-gates-in-pipelines/), [InfoQ](https://www.infoq.com/articles/pipeline-quality-gates/)). The pattern is proven. **Condition:** This is only valuable for teams that fix UI/UX bugs via the pipeline. For backend-only projects, it's dead weight. The "High" complexity rating in the proposal is accurate — pipeline pause/resume is architecturally significant. **Defer to v5.1 unless there's user demand.** |
| B5 | **Fix retrospective and history** | **CONDITIONAL** | Medium | The ACE paper ([arXiv: 2510.04618](https://arxiv.org/abs/2510.04618)) validates structured context accumulation with +8.6% improvement — but with a critical caveat: naive accumulation causes "context collapse." **Condition: retrospective output must be structured and categorized (not free-form narrative), and old entries must be pruned when modules are refactored.** The `.claude/fix-history/` approach is architecturally correct but needs a curation mechanism. |
| B6 | **Mid-fix decomposition escape hatch** | **YES** | Medium | ADaPT validates demand-driven decomposition ([arXiv](https://arxiv.org/html/2410.22457v1)). UniDebugger's hierarchical escalation is the closest prior art. The fixer's 100-line limit creates a real failure mode where decomposition is needed but wasn't triggered. **Risk:** fixer may over-trigger NEEDS_DECOMPOSITION to avoid hard problems. **Mitigation:** allow max 1 decomposition escalation per ticket; if the decomposed subtasks also fail, block. |
| B7 | **AC-based reviewer checklist** | **STRONG YES** | High | This is the simplest, cheapest proposal. Adding "AC fulfillment" to the existing reviewer checklist is a one-paragraph change to `reviewer.md`. It makes the reviewer's job *easier* (concrete criteria to check) rather than harder. The +5-10% estimate stacks on B1 — without B1, B7 has nothing to check. **Dependency: requires B1.** |

### Feature Pipeline (8 proposals)

| # | Proposal | Verdict | Confidence | Rationale |
|---|----------|---------|------------|-----------|
| F1 | **AC writeback to ticket** | **STRONG YES** | High | This is standard ATDD practice — AC should live on the ticket, not in ephemeral agent context ([DevOps.com](https://devops.com/how-test-driven-methodologies-reduce-ci-cd-lead-time/)). The spec-analyst already posts a checkpoint comment; extending it to include AC is minimal work. Makes the pipeline's decisions visible to human stakeholders. |
| F2 | **AC quality review step** | **CONDITIONAL** | Medium | Self-review by the same agent with "reviewer-hat" instructions is weak — LLMs exhibit self-consistency bias. A separate spec-reviewer invocation would be better but doubles the cost of the spec analysis phase. **Condition:** Only worth it if spec-analyst produces vague AC frequently. Measure first (track how often the reviewer flags AC quality issues), then add the gate if the data supports it. The "pause-on-questions" sub-feature adds significant complexity. |
| F3 | **AC-driven architecture with `maps_to`** | **STRONG YES** | High | Lightweight traceability — just a field in existing YAML. Costs almost nothing. Enables automated verification of decomposition completeness. Consistent with agile traceability best practices of using automated, inline tools rather than separate RTMs ([Ketryx](https://www.ketryx.com/blog/best-practices-for-maintaining-a-requirement-traceability-matrix-in-agile)). |
| F4 | **Post-decomposition AC coverage verification** | **YES** | Medium | Logical extension of F3. If you have `maps_to`, checking for orphaned AC is a simple set-difference operation. The two-step verification (architect produces, spec-analyst validates) adds a full agent invocation for what could be a 5-line validation in the command itself. **Simplify: make this a validation step in the command, not a separate agent call.** |
| F5 | **AC-aware reviewer checklist** | **STRONG YES** | High | Identical rationale to B7. Adding per-AC verdicts (FULFILLED/PARTIALLY/NOT ADDRESSED) to the reviewer's output is a small change with high signal. The reviewer already reads AC as context — this just formalizes the check. |
| F6 | **Acceptance gate step** | **YES** | Medium | The "acceptance test gate" is a Continuous Delivery pillar. For features (which are larger than bug fixes), a dedicated verification pass has more value. The reviewer's argument is sound: the fixer-reviewer loop focuses on deltas, not the full AC set. A fresh pass on the complete implementation catches drift. **Implementation: invoke the reviewer with "acceptance-gate" instructions rather than creating a new agent — keeps the agent count at 15.** |
| F7 | **Manual testing mode** | **CONDITIONAL** | Medium | Same assessment as B4. Proven pattern, but high complexity for limited audience. **Condition: same as B4 — defer unless user demand.** |
| F8 | **AC feedback loop** | **NO** | Medium | This proposes tracking AC quality issues across runs to "improve spec-analyst behavior." But the spec-analyst is a stateless LLM invocation — it doesn't learn between runs without explicit context injection. The proposal has "High" complexity for speculative "+5% long-term" impact. The simpler version (reviewer flags bad AC in its output) already happens naturally. Building a separate tracking mechanism is over-engineering. |

### Scaffold Pipeline (7 proposals)

| # | Proposal | Verdict | Confidence | Rationale |
|---|----------|---------|------------|-----------|
| S1 | **Spec compliance verification** | **STRONG YES** | High | This is the scaffold equivalent of the acceptance gate (F6). The spec-reviewer already exists and already validates specs — adding a `--verify` mode that checks implementation against spec is a natural extension. The three-layer verification (static → test-based → runtime) proposed by the architect is the right design. +15-20% impact is plausible for scaffold where specs are detailed. |
| S2 | **Given/When/Then AC schema enforcement** | **CONDITIONAL** | Medium | GWT is beneficial but has documented limitations for system-level and UX criteria ([Ranorex](https://www.ranorex.com/blog/given-when-then-tests/), [AltexSoft](https://www.altexsoft.com/blog/acceptance-criteria-purposes-formats-and-best-practices/)). **Condition: allow GWT as preferred format but accept rule-oriented ("MUST: ...", "WHEN: ...") as alternative for NFRs, constraints, and UX requirements.** Mandating GWT-only will cause spec-writer to produce awkward, forced AC for non-behavioral requirements. |
| S3 | **Scaffolder test infrastructure generation** | **STRONG YES** | High | This is a concrete, evidence-based fix for the top 3 E2E failure causes. No new agents, no new config — just better scaffolder output. The scaffolder already generates a smoke test; adding `test/setup.{ext}` with port allocation and health checks is a natural extension. +20-25% E2E reliability improvement is plausible because port conflicts and DB state leaks are deterministic failures. |
| S4 | **Post-implementation checkpoint** | **YES** | Medium | A lightweight pause before E2E tests lets developers catch obvious visual/UX issues. Low complexity, optional, already partially exists (spec checkpoint and feature plan checkpoint). The key is keeping it lightweight — "pause, user looks, thumbs up" — not a new review protocol. |
| S5 | **Scaffolder quality scorecard** | **YES** | Medium | Expanding validation from 3 to 8 checks is low-effort self-improvement. The scorecard format (informational, not blocking) is the right approach — it surfaces issues without adding pipeline latency. Minor concern: "dependency freshness" checks may produce false positives on intentionally pinned versions. |
| S6 | **Batch-level integration AC** | **SKEPTICAL** | Low | The architect defining "integration acceptance criteria" for each batch sounds valuable in theory, but in practice, integration issues are emergent — you can't predict them from the task tree. The current approach (run full test suite after each batch) already catches integration failures. Adding another AC layer for a problem that may not exist in practice is premature. **Revisit if real scaffold runs show integration failures between batches.** |
| S7 | **`/scaffold-iterate` command** | **CONDITIONAL** | Medium | Delta-aware re-processing is genuinely useful but "High" complexity for a new command. **Condition: implement only after scaffold v2 has real-world usage data showing that users actually need iterative refinement.** The simpler alternative — user edits code manually, then runs `/implement-feature` for specific changes — may be sufficient. |

---

## 3. Cross-Cutting Analysis

### 3.1 Is "AC as Red Thread" the Right Framing?

**Verdict: Yes for features and scaffold. Partially for bug fixes.**

For **features and scaffold**, AC are the natural contract between what was promised and what was delivered. The feature pipeline currently has no formal verification that all specified AC were fulfilled — the reviewer checks code quality, and the test-engineer verifies code behavior, but neither systematically maps outcomes to requirements. This is a genuine gap.

For **bug fixes**, the framing is less clear. Most bugs have implicit AC: "the thing that's broken should work again." SWE-agent, Devin, and OpenHands handle this by using the failing test as the implicit AC — if the test passes, the bug is fixed. The ceos-agents proposal to *synthesize* AC from vague bug reports adds value for complex bugs but is overhead for straightforward ones (e.g., "NullPointerException on line 42").

**Recommendation:** Implement AC extraction for all pipelines, but make the verification gate conditional. For bug fixes, the existing test-engineer pass is sufficient AC verification for most cases. The full acceptance gate should trigger only when AC count >= 3 or when the triage flags complexity >= M.

**Comparison with other tools:**
- **SWE-agent/OpenHands:** Use test results as implicit AC. No explicit AC extraction.
- **MetaGPT:** Uses SOPs with structured intermediate outputs — closest to the AC-as-contract pattern. Reports +15.6% from this approach.
- **Devin:** Uses plan-then-execute with verification, but no public documentation of AC traceability.

### 3.2 Token Cost vs. Quality Tradeoff

**Estimate for the full 22-proposal set:**

Current pipeline costs per the existing `/estimate` logic:
- Bug fix: ~119,000 tokens (~$0.50-$1.60)
- Feature: ~200,000 tokens (~$1.00-$3.00, estimated)
- Scaffold: ~400,000 tokens (~$2.00-$6.00, estimated)

Additional costs per proposal category:
- AC extraction in triage/spec-analyst: +~5,000 tokens (minimal — extends existing output)
- AC-based reviewer checklist: +~2,000 tokens (extends existing output)
- Acceptance gate (new agent invocation): +~30,000 tokens (full sonnet invocation)
- AC quality review (separate invocation): +~30,000 tokens
- Spec compliance verification: +~40,000 tokens (reads codebase + spec)
- Fix retrospective: +~10,000 tokens (writes markdown file)
- Manual verification mode: +~5,000 tokens (generates checklist)

**Realistic overhead for the "minimum viable AC pipeline" (B1+B7+F1+F3+F5+F6+S1):**
- Bug fix: +~7,000 tokens (+6%) — just AC extraction and reviewer checklist
- Feature: +~37,000 tokens (+18%) — AC writeback, maps_to, reviewer checklist, acceptance gate
- Scaffold: +~47,000 tokens (+12%) — spec compliance verification is the main cost

**Verdict:** The minimum viable set adds 6-18% token overhead. This is acceptable. The full 22-proposal set would add 40-60% overhead — not worth it. Selective implementation is key.

### 3.3 Are the Impact Estimates Realistic?

**Verdict: The estimates are optimistic but not unreasonable, with important caveats.**

The proposals claim +5-30% improvements. Calibration from published benchmarks:

- **MetaGPT's verifier agent:** +15.6% on collaborative software engineering benchmarks. This is the closest analog to adding an acceptance gate.
- **SWE-bench gap:** Top agents go from ~45% (public) to ~24% (private unseen codebases). The 21-point gap represents the "unknown context" penalty. Better AC and context *could* close part of this gap.
- **Verdent's pass@1 vs pass@3:** 76.1% → 81.2% (+5.1 points from retries). This calibrates the value of retry/feedback mechanisms.

**Assessment per proposal:**
- B1 (+20-30%): **Overestimated.** MetaGPT's entire structured output system gives +15.6%. A single AC extraction step giving +20-30% alone is unlikely. Realistic: +8-15%.
- F6 (+20%): **Plausible** for features where the acceptance gate catches incomplete implementations that would otherwise ship.
- S3 (+20-25% E2E reliability): **Plausible** because the failures are deterministic infrastructure issues, not AI quality problems.
- B5 (+5-10%): **Plausible if structured.** ACE paper shows +8.6% from curated context accumulation. But requires structured output + pruning, not naive file appending. Realistic: +3-8% with proper implementation.
- B3 (+5-10%): **Plausible.** Better decomposition decisions prevent a known failure mode.

### 3.4 What's Missing?

Techniques from AI coding agent literature that none of the three discussions mentioned:

1. **Test-time scaling / best-of-N sampling.** Verdent achieves 76.1% pass@1 → 81.2% pass@3 by generating multiple candidate fixes and selecting the best. ceos-agents currently generates exactly one fix attempt per fixer invocation. Running 2-3 parallel fixer attempts and selecting the one that passes the most AC would be a significant improvement. This is orthogonal to all 22 proposals and potentially higher-impact than most of them.

2. **Hierarchical escalation (UniDebugger pattern).** Instead of one fixer with a 100-line limit, use a tiered approach: Level 1 (sonnet, simple fixes), Level 2 (opus, complex fixes), Level 3 (opus with decomposition). The current pipeline always uses opus for fixing regardless of complexity. Downgrading simple fixes to sonnet would save tokens while reserving opus for cases that need it.

3. **Trajectory analysis.** The research on thought-action-result trajectories ([arXiv: 2506.18824](https://arxiv.org/html/2506.18824v1)) suggests that analyzing *how* agents solve problems (not just whether they succeed) can identify systematic failure patterns. This is more actionable than the proposed fix retrospective because it's analyzed by researchers, not by the agent itself.

4. **Explicit test-as-oracle.** SWE-agent and OpenHands use existing failing tests as the ground truth for "is it fixed?" The ceos-agents pipeline generates *new* tests but doesn't prioritize running existing failing tests first. If a bug has an existing failing test, the fixer should run it first (before writing a new one) as the ultimate AC verification.

5. **Futility detection.** SWE-Effi ([arXiv: 2509.09853](https://arxiv.org/abs/2509.09853)) shows that agents lacking stagnation detection consume 4x+ tokens on failures vs successes. No mainstream tool has solved this. The ceos-agents pipeline uses fixed retry limits (Build retries: 3, Fixer iterations: 5, Test attempts: 3) as implicit budget caps, but has no "progress-aware" detection — if the fixer makes the same mistake 4 times, it burns 4 iterations before blocking. Adding a "same-error detection" heuristic (if fixer output is structurally similar to previous iteration, escalate immediately) would reduce waste.

### 3.5 Consolidation Opportunities

The three documents have significant overlap. Here's how to unify:

**Unified "AC Extraction" step (replaces B1, F1, part of S2):**
- Triage-analyst extracts/synthesizes AC for bugs
- Spec-analyst extracts AC for features (already does this — just needs writeback)
- Spec-writer generates AC for scaffold (already does this)
- All AC use a consistent format: preferred GWT, accepted rule-oriented
- All AC are written back to the issue tracker (if tracker exists)

**Unified "AC-Aware Review" (replaces B7, F5):**
- Single change to `reviewer.md`: add AC fulfillment checklist item
- Works identically for bugs and features
- Reviewer outputs per-AC verdict (FULFILLED/PARTIALLY/NOT ADDRESSED)

**Unified "Acceptance Gate" (replaces B2, F6, S1):**
- Single implementation: invoke reviewer with "acceptance-gate" mode
- For bugs: trigger only when AC count >= 3 or complexity >= M
- For features: always trigger
- For scaffold: use spec-reviewer --verify mode (different agent, same concept)

**Unified "Manual Verification" (replaces B4, F7, S4):**
- Single config key: `Verification` section with `Mode: auto|manual|hybrid`
- Triage/spec-analyst sets the mode per ticket
- Pipeline pauses at the appropriate point (after acceptance gate, before publish)
- Generates structured checklist from AC

This reduces 22 proposals to ~8 unified changes:
1. AC extraction (extends triage-analyst and spec-analyst)
2. AC writeback to issue tracker
3. AC-aware reviewer checklist (extends reviewer)
4. Acceptance gate (new pipeline step, reuses reviewer)
5. Complexity estimation (extends triage-analyst)
6. `maps_to` traceability (extends architect)
7. Spec compliance verification (extends spec-reviewer)
8. Scaffolder test infrastructure (extends scaffolder)

Plus 4 optional/deferred changes:
9. Manual verification mode (new config + pipeline pause)
10. Mid-fix decomposition escape hatch (extends fixer + commands)
11. Fix retrospective history (new file generation)
12. Quality scorecard (extends scaffolder)

### 3.6 Implementation Risk

**Highest risk proposals:**

1. **Manual verification mode (B4/F7):** Pipeline pause/resume is architecturally complex. If the user doesn't respond, the pipeline hangs. If implemented poorly, it breaks `--yolo` mode. Risk: moderate, mitigation: implement as a separate step that's cleanly skippable.

2. **AC quality review (F2):** Adding a review loop *before* the existing spec-writer↔spec-reviewer loop creates nested iteration. Risk: pipeline gets stuck in AC quality → spec quality → AC quality oscillation. Mitigation: don't implement as a separate loop; fold into existing spec-reviewer checks.

3. **Fix retrospective (B5):** Stale or misleading history could make agents perform *worse*. If a module was refactored after a failed fix, the failure analysis is no longer relevant. Risk: low (it's just context), but the expected benefit is also low.

4. **Batch integration AC (S6):** Defining integration criteria upfront requires predicting emergent behavior. Risk: architect generates vague integration AC that add noise without catching real issues.

**Lowest risk proposals:**

1. B3 (complexity estimation), B7/F5 (reviewer checklist), F3 (maps_to), S3 (test infrastructure) — all extend existing agents with minimal structural changes.

---

## 4. Final Recommendation

### Must-Have (v5.0 Core)

These form the minimum viable AC pipeline. They're high-impact, low-to-medium complexity, and well-supported by evidence.

| # | Unified Proposal | Source Proposals | Rationale |
|---|-----------------|------------------|-----------|
| 1 | **AC extraction in triage** | B1 | Proven ATDD pattern. Highest-leverage single change. Every downstream agent benefits. |
| 2 | **AC-aware reviewer checklist** | B7, F5 | Trivial change to reviewer.md. Formalizes what the reviewer should already be doing. Depends on #1. |
| 3 | **AC writeback to issue tracker** | F1 | Makes AC visible to human stakeholders. Extends existing checkpoint comment. Minimal effort. |
| 4 | **`maps_to` traceability in architect** | F3 | One YAML field. Enables automated completeness checking. Lightweight traceability. |
| 5 | **Complexity estimation in triage** | B3 | Zero config, minimal agent change. Feeds decomposition decisions. Already used in dry-run reports. |
| 6 | **Scaffolder test infrastructure** | S3 | Fixes top 3 E2E failure causes. Concrete, evidence-based, no new agents or config. |
| 7 | **Spec compliance verification** | S1 | The scaffold equivalent of the acceptance gate. Uses existing spec-reviewer in verify mode. |

**Dependencies:** #2 depends on #1. #4 enables automated checking in the acceptance gate.

**Estimated total effort:** Medium. Changes to 5 agents (triage-analyst, reviewer, spec-analyst, architect, scaffolder) + 1 agent mode (spec-reviewer --verify) + command updates for the new pipeline steps.

### Should-Have (v5.0 Extended)

High value if time permits. Implement after core is stable.

| # | Proposal | Source | Rationale |
|---|----------|--------|-----------|
| 8 | **Acceptance gate step** | B2, F6 | The "acceptance test gate" from Continuous Delivery. For features: always. For bugs: conditional (AC >= 3 or complexity >= M). Implement as reviewer invocation with "acceptance-gate" instructions, not a new agent. |
| 9 | **Mid-fix decomposition escape hatch** | B6 | Validated by TDAG and ADaPT research. Addresses a real failure mode. Max 1 escalation per ticket to prevent abuse. |
| 10 | **Post-decomposition AC coverage check** | F4 | Simple set-difference validation in the command (not a separate agent call). Depends on #4 (maps_to). |
| 11 | **GWT-preferred AC format** | S2 | Enforce for behavioral criteria, accept rule-oriented for NFRs. Don't mandate GWT-only. |
| 12 | **Quality scorecard** | S5 | Low-effort scaffolder self-improvement. Informational, not blocking. |

### Nice-to-Have (v5.1+)

Defer without regret. Implement when data supports it.

| # | Proposal | Source | Rationale |
|---|----------|--------|-----------|
| 13 | **Manual verification mode** | B4, F7, S4 | Proven CI/CD pattern but high complexity. Only valuable for UI-heavy projects. Wait for user demand. |
| 14 | **Fix retrospective history** | B5 | ACE paper validates +8.6% from structured context. Implement with structured output format + staleness pruning. Worth doing but after core AC pipeline is stable. |
| 15 | **`/scaffold-iterate` command** | S7 | High complexity, uncertain demand. Wait for scaffold v2 usage data. |

### Drop

| # | Proposal | Source | Rationale |
|---|----------|--------|-----------|
| — | **AC quality review step** | F2 | Self-review bias makes same-agent review weak. Separate agent invocation doubles spec analysis cost. The existing spec-reviewer already catches vague AC. Adding a nested loop risks oscillation. |
| — | **AC feedback loop** | F8 | High complexity, speculative long-term benefit. Stateless LLM agents don't improve from cross-run tracking without explicit prompt injection — and the simpler version (reviewer flags bad AC) happens naturally. |
| — | **Batch integration AC** | S6 | Predicting emergent integration issues upfront is unreliable. The existing full test suite after each batch already catches integration failures. |

### Implementation Order

```
Phase 1 (v5.0-alpha): B1 + B3 + B7/F5 → AC extraction, complexity, AC-aware review
Phase 2 (v5.0-beta):  F1 + F3 + F4    → AC writeback, maps_to, coverage check
Phase 3 (v5.0-rc):    S3 + S1          → scaffolder infra, spec compliance verification
Phase 4 (v5.0):       B2/F6 + B6       → acceptance gate, mid-fix decomposition
Phase 5 (v5.0.x):     S2 + S5          → GWT format, quality scorecard
```

Each phase is independently shippable. Phase 1 delivers the highest-impact changes with the lowest risk. Phase 4 is the most architecturally significant and should only ship after Phases 1-3 are validated.

### Addendum: Consider These Unlisted Improvements

Based on the research, two techniques not in any proposal deserve consideration:

1. **Best-of-N fixer sampling:** Run 2 parallel fixer attempts for complex bugs (complexity >= M), select the one that passes more tests. Validated by Verdent's pass@1→pass@3 improvement. Token cost: 2x fixer cost for applicable bugs (~15% of total). Expected improvement: +3-5% on complex bugs.

2. **Existing-test-first oracle:** When the bug has an existing failing test, run it before and after the fix as the primary verification. Skip writing a new regression test if the existing test covers the AC. Saves test-engineer cost for bugs with good existing coverage.

---

## Sources

- [Semaphore: BDD and Acceptance Testing](https://semaphore.io/blog/bdd-acceptance-testing)
- [InformIT: Automated Acceptance Test Gate (Continuous Delivery)](https://www.informit.com/articles/article.aspx?p=1621865&seqNum=5)
- [MetaGPT: Meta Programming for Multi-Agent Framework (ICLR 2024)](https://arxiv.org/html/2308.00352v6)
- [SWE-bench Pro Leaderboard (Scale AI)](https://scale.com/leaderboard/swe_bench_pro_public)
- [Epoch AI: SWE-bench Verified](https://epoch.ai/benchmarks/swe-bench-verified)
- [Verdent: SWE-bench Verified Technical Report](https://www.verdent.ai/blog/swe-bench-verified-technical-report)
- [TDAG: Dynamic Task Decomposition (Neural Networks)](https://arxiv.org/abs/2402.10178)
- [ADaPT: Dynamic Task Decomposition](https://arxiv.org/html/2410.22457v1)
- [OpenHands: AI Software Developers as Generalist Agents](https://arxiv.org/abs/2407.16741)
- [Understanding SE Agents: Thought-Action-Result Trajectories](https://arxiv.org/html/2506.18824v1)
- [Springer: Traceability in Agile Projects](https://link.springer.com/chapter/10.1007/978-1-4471-2239-5_12)
- [Ketryx: RTM Best Practices in Agile](https://www.ketryx.com/blog/best-practices-for-maintaining-a-requirement-traceability-matrix-in-agile)
- [JFrog: Approval Gates in Pipelines](https://jfrog.com/blog/proceed-with-care-how-to-use-approval-gates-in-pipelines/)
- [InfoQ: Pipeline Quality Gates](https://www.infoq.com/articles/pipeline-quality-gates/)
- [Ranorex: When to Use Given-When-Then](https://www.ranorex.com/blog/given-when-then-tests/)
- [AltexSoft: Acceptance Criteria Best Practices](https://www.altexsoft.com/blog/acceptance-criteria-purposes-formats-and-best-practices/)
- [Thoughtworks: BDD Acceptance Criteria](https://www.thoughtworks.com/insights/blog/applying-bdd-acceptance-criteria-user-stories)
- [DeepSWE: Training an Open-sourced Coding Agent](https://www.together.ai/blog/deepswe)
- [ACE: Agentic Context Engineering (arXiv: 2510.04618)](https://arxiv.org/abs/2510.04618)
- [SWE-Effi: Re-Evaluating SE Agent Effectiveness (arXiv: 2509.09853)](https://arxiv.org/abs/2509.09853)
- [AI Agentic Programming: Survey of Techniques (arXiv: 2508.11126)](https://arxiv.org/abs/2508.11126)
- [GitHub Blog: Multi-agent workflows often fail](https://github.blog/ai-and-ml/generative-ai/multi-agent-workflows-often-fail-heres-how-to-engineer-ones-that-dont/)
- [Gotel & Finkelstein: Requirements Traceability Problem (IEEE 1994)](https://ieeexplore.ieee.org/document/292398/)
- [Microsoft Learn: End-to-End Traceability in Azure DevOps](https://learn.microsoft.com/en-us/azure/devops/cross-service/end-to-end-traceability?view=azure-devops)
- [QAbash: PRD-Based Ticketing + BDD](https://www.qabash.com/prd-bdd-ticketing-qa-workflow-transformation/)
- [Aspire Systems: ATDD and Continuous Delivery](https://www.aspiresys.com/articles/atdd-applied-approach-to-continuous-delivery.pdf)
- [testRigor: Why Cucumber and SpecFlow Died](https://testrigor.com/blog/why-cucumber-and-specflow-died/)
