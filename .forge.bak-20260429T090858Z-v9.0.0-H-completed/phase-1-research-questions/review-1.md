# Phase 1 Review — Research Questions for v9.0.0 sub-projekt H

**Reviewer:** Isolated reviewer agent (forge review-loop-prompt.md protocol)
**Artifact:** `.forge/phase-1-research-questions/synthesis.md`
**Round:** 1

---

## Tier 1 Hard Gates

### Count check: 8–12 questions
11 questions produced. **PASS.**

### All 5 concern areas covered (at least 1 per area)
- Whether: Q1, Q2 — **PASS** (2 questions, primary WHETHER gate is well-covered)
- How: Q3, Q4, Q5 — **PASS** (3 questions covering co-location, schema complexity, enforcement posture)
- Backcompat: Q6, Q7 — **PASS** (override injector + heading collision, and migration scope)
- Versioning: Q8 — **PASS** (1 question, directly targets CLAUDE.md Versioning Policy)
- Tests: Q9, Q10, Q11 — **PASS** (3 questions: edit surface, SKIP-guard pattern, cross-ref assertion)

### Each question has Question + Why it matters + Source hint
All 11 questions have all three fields present and non-empty. **PASS.**

### Questions answerable from public sources or codebase inspection
Spot-checked each:
- Q1: Codebase inspection of test files + forge archive. Answerable.
- Q2: Anthropic Claude Code public docs + SKILL.md inspection. Answerable. Note: Claude Code Task tool internal dispatch is partially opaque — the question is appropriately scoped to "what public documentation and observable behavior reveal," which is a valid public-sources constraint. Borderline but acceptable.
- Q3: MCP spec (public) + CrewAI changelog (public). Answerable.
- Q4: JSON Schema spec (public) + agent file inspection (codebase). Answerable.
- Q5: smolagents source (public) + OpenAI structured outputs announcement (public). Answerable.
- Q6: `core/agent-override-injector.md` (codebase) + examples/. Answerable.
- Q7: `core/agent-override-injector.md` + MEMORY-referenced project files (codebase). Answerable.
- Q8: CLAUDE.md Versioning Policy (codebase) + LangChain/LangGraph public changelogs. Answerable.
- Q9: `tests/scenarios/` directory inspection (codebase). Fully answerable.
- Q10: `tests/harness/run-tests.sh` + scenario files (codebase). Answerable.
- Q11: `tests/scenarios/xref-*.sh` + `skills/*.md` (codebase). Answerable.

All 11: **PASS.**

### No question duplicates codebase context already provided in the prompt
The spec prompt gives: frontmatter schema, 18 agents, Task tool dispatch (without internals), agent-override-injector mention, test harness structure (297 scenarios, exit codes, assertion primitives), Versioning Policy text, docs/ reference list. Check each question against this:

- Q1 asks about *specific* stale agent name evidence in named test files + failure attribution in the forge archive — not provided in context. **PASS.**
- Q2 asks about Task tool runtime validation behavior and whether frontmatter is stripped before model invocation — the spec says "Claude Code Task tool" but does not answer what the runtime does to frontmatter or output. **PASS.**
- Q3 asks about MCP/CrewAI — entirely external. **PASS.**
- Q4 asks about JSON Schema 2020-12 expressiveness for polymorphic agents (analyst --phase) — spec notes the pattern exists but does not answer schema language fit. **PASS.**
- Q5 asks about smolagents/OpenAI advisory vs. enforced precedent — entirely external. **PASS.**
- Q6 asks about override injector mechanics (append-only? heading collision?) — spec mentions injector as "SOLE extension point" and the hard compat constraint, but does NOT answer the append-vs-inspect question or heading collision behavior. **PASS.**
- Q7 asks about migration scope for v8 consuming projects — spec says constraint exists but does not answer what migration (if any) is required. **PASS.**
- Q8 asks whether adding new body sections is MAJOR or MINOR — spec gives the Versioning Policy text but explicitly notes "depends on whether mandatory or optional," meaning the answer is not pre-determined. **PASS.**
- Q9 asks which specific existing test scenarios assert body sections vs. frontmatter — spec provides naming convention and exit codes but NOT which scenarios check body content. **PASS.**
- Q10 asks for the minimal grep/awk assertion pattern + SKIP-guard syntax — spec describes harness primitives but does NOT provide the pattern for contract-section validation. **PASS.**
- Q11 asks whether a cross-reference assertion is feasible with grep and which scenario to template — spec describes cross-ref scenarios by name but does not answer this. **PASS.**

All 11: **PASS.**

**Tier 1 verdict: ALL PASS.**

---

## Tier 2 — Behavioral Tests

Not applicable to research-question phase. No test runner or mutation framework applies.

```
tier_2: N/A (research-question generation phase — no executable tests)
```

---

## Tier 3 Quality Rubrics

### Correctness (0–5, weight 0.30, minimum 3)

Questions correctly target the actual sub-projekt H scope (machine-readable I/O contracts for 18 agents). The WHETHER gate (Q1) is correctly grounded in measurable existing failure evidence rather than theoretical motivation. Q2 correctly identifies the Task tool runtime as the boundary that determines whether contracts are enforceable or advisory-only — this is the single most critical architectural question and it is scoped correctly. Q4 correctly identifies `analyst` multi-phase polymorphism as the hardest case for schema design, which is the right bounding example. Q8 correctly identifies the policy ambiguity (the Versioning Policy text does not explicitly classify "new optional body section") and uses real external precedent (LangChain v0.1→v0.2) for calibration.

One minor correctness concern: Q7's "Source hint" cites MEMORY entries for BIFITO and drmax-readmine-test projects — however, MEMORY is not a "public source or codebase" in the usual sense. The question remains answerable (from `core/agent-override-injector.md` and override file inspection), so this does not disqualify the question, but a Phase 2 researcher who lacks MEMORY access would need to use the codebase path instead. The question itself is still answerable via codebase inspection alone. Minor issue only.

**Score: 4**

### Completeness (0–5, weight 0.25, minimum 3)

All 5 areas are substantively covered:
- WHETHER: Q1 (failure evidence) + Q2 (runtime enforcement boundary) — two distinct angles, neither redundant with the other or with codebase context.
- HOW: Q3 (co-location/sidecar precedent from MCP/CrewAI) + Q4 (schema language fit for polymorphic agents) + Q5 (advisory vs. enforced posture) — three distinct HOW sub-decisions.
- BACKCOMPAT: Q6 (override injector mechanics + heading collision) + Q7 (migration scope for consuming projects) — well decomposed.
- VERSIONING: Q8 — single question, but it covers both the classification question AND the external precedent needed to resolve the policy ambiguity. One question is sufficient here.
- TESTS: Q9 (edit surface of existing harness) + Q10 (assertion primitives for new scenarios) + Q11 (cross-reference feasibility) — comprehensive test strategy grounding.

The "do nothing" baseline is credibly covered: Q1 explicitly states "If the 62 failures are unrelated to output shape and existing tests cover all structural contracts, the cost-benefit of formalization is weak." The spec anti-pattern #3 (skipping the "do nothing" baseline) is avoided.

One gap to note: the spec mentions that `docs/reference/` files must be kept in sync (per feedback_doc_completeness.md), and CLAUDE.md states "new I/O contract invariants must be added here" (Cross-File Invariants). No question asks about the docs impact (which reference docs need updates, what the doc-count discipline requires). This is a small gap — the test questions (Q9–Q11) cover the test harness, but the docs update surface is not researched. This is unlikely to be load-bearing for Phase 3 brainstorm since doc updates are mechanical, but it is a mild completeness gap.

**Score: 4**

### Maintainability (0–5, weight 0.15, minimum 2)

Questions are clear and unambiguous — each has a recognizable answer shape (the spec's success criterion). Q1 asks for a count (how many of 62 failures) and a boolean (do test files contain stale names) — concrete answer shape. Q2 asks for a behavioral description (what the runtime does) — answerable as a characterization. Q3 asks for a format description + migration classification — answerable. Q4 asks for a sufficiency judgment (is typed-list adequate vs. JSON Schema) — answerable with examples. Q5 asks for a factual characterization (smolagents rationale, OpenAI strict mode failures) — answerable from primary sources. Q6–Q8 all have concrete answer shapes. Q9 asks for counts + list of affected files — concrete. Q10 asks for a code pattern — concrete. Q11 asks for a feasibility judgment + template identification — concrete.

The cluster annotations (e.g., "agent-3 Q1 + agent-2 Q11") are valuable metadata for the synthesis lineage but would be confusing to a Phase 2 researcher who does not know the original agent outputs. They are informational only and do not affect answerability.

Coverage map at the top is well-structured and immediately parseable.

**Score: 4**

### Security (0–5, weight 0.20, minimum 3)

Not a primary concern for research questions. No PII, no credential handling, no injection surface in research question text. The questions correctly avoid asking about things that would require access to private/non-public systems. Q7 references MEMORY (project-internal data) in a source hint but does not expose it.

**Score: 4** (security is not the dominant concern for this artifact type; score reflects absence of issues)

### Robustness (0–5, weight 0.10, minimum 2)

Questions are specific enough that a Phase 2 researcher would not get stuck wondering what the question is asking. Q2 has the most risk — the Task tool internal dispatch is partially undocumented — but the question is correctly scoped to observable/documented behavior plus SKILL.md inspection, which keeps it answerable. Q5 references a specific date (August 2024) and specific fields (`strict: true`) which anchors the research concretely.

The one robustness concern is Q1's part (b): "how many of the 62 failures are traceable to output section name mismatch" — this requires the Phase 2 researcher to access the forge-2026-04-25-001 archive and perform failure attribution, which may require subjective judgment. The question acknowledges this implicitly ("traceable to... rather than logic errors") but does not specify the attribution method. A Phase 2 researcher might produce different counts depending on attribution criteria. This is a mild robustness gap, not a blocking one.

**Score: 3**

### Weighted Aggregate

```
Correctness:     4 × 0.30 = 1.20
Completeness:    4 × 0.25 = 1.00
Security:        4 × 0.20 = 0.80
Maintainability: 4 × 0.15 = 0.60
Robustness:      3 × 0.10 = 0.30

Weighted total: 3.90
```

Threshold: 3.5. All criteria at or above minimum (3/3/2/2/2). **Tier 3 PASS.**

---

## Findings

**F-1** (MINOR, completeness, Q7/source-hint): Q7's source hint cites "MEMORY entries for project_bifito_autopilot_test.md and project_drmax_readmine_test.md" — these are session-memory references, not stable codebase paths. A Phase 2 researcher who inspects the codebase directly will not find MEMORY entries as files. The hint should reference the codebase path for override files in consuming projects (or note "inspect MEMORY if available, otherwise skip this sub-check — the injector mechanism alone answers the question"). Low impact; the question remains answerable without MEMORY.

**F-2** (MINOR, completeness, overall): No question covers the docs update surface — specifically, which `docs/reference/` files (agents.md, pipeline.md, automation-config.md) require updates when I/O contract sections are added, and what the doc-count drift discipline (feedback_doc_completeness.md) requires. This is not load-bearing for the Phase 3 brainstorm (doc updates are mechanical), but a Phase 3 brainstorm that produces a recommendation will need to estimate doc effort. A single half-question appended to Q9 or Q11 would close this. Non-blocking.

**F-3** (INFO, robustness, Q1-b): The attribution criterion for "failures traceable to output section mismatch" in Q1 part (b) is left implicit. If the forge archive does not have structured failure classification, a Phase 2 researcher may produce a subjective estimate rather than a count. This is acceptable for research-question phase but should be noted in Phase 2 output as an estimate with explicit confidence level.

---

## Verdict JSON

```json
{
  "tier_1": {
    "schema_valid": true,
    "requirements_traced": true,
    "no_regressions": true,
    "lint_clean": true,
    "pass": true
  },
  "tier_2": {
    "fail_to_pass": null,
    "hidden_test_gap": null,
    "mutation_score": null,
    "mutation_available": false,
    "pass": true,
    "note": "N/A — research-question phase, no executable tests"
  },
  "tier_3": {
    "correctness": 4,
    "completeness": 4,
    "security": 4,
    "maintainability": 4,
    "robustness": 3,
    "weighted_aggregate": 3.90,
    "pass": true
  },
  "overall_verdict": "PASS",
  "confidence": 0.87,
  "findings": [
    {
      "id": "f-a1m7sh",
      "severity": "MINOR",
      "criterion": "completeness",
      "location": "Q7 source-hint",
      "description": "Source hint references MEMORY entries (project_bifito_autopilot_test.md, project_drmax_readmine_test.md) which are session-scoped, not stable codebase paths. Phase 2 researcher without MEMORY access cannot follow this hint.",
      "recommendation": "Rewrite source hint to reference codebase path (core/agent-override-injector.md + examples/ override samples) and note MEMORY as optional supplemental context only."
    },
    {
      "id": "f-b2c4ds",
      "severity": "MINOR",
      "criterion": "completeness",
      "location": "overall — no question covers docs update surface",
      "description": "None of Q1–Q11 ask which docs/reference/ files require updates when I/O contract sections are added, or what the doc-count drift discipline requires. Phase 3 brainstorm will need to estimate doc effort without research grounding.",
      "recommendation": "Non-blocking. Accept as-is or append a sub-question to Q9 or Q11: 'Which docs/reference/ files currently describe agent body section structure and would need amendment?'"
    },
    {
      "id": "f-c3r1qb",
      "severity": "INFO",
      "criterion": "robustness",
      "location": "Q1 part (b)",
      "description": "Failure attribution criterion ('traceable to output section mismatch rather than logic errors') is implicit. If the forge archive lacks structured failure classification, Phase 2 researcher will produce an estimate, not a count.",
      "recommendation": "Phase 2 output for Q1(b) should explicitly label the attribution as an estimate with confidence level. No question text change needed."
    }
  ]
}
```

---

## Summary

11 questions, all 5 concern areas covered, all Tier 1 gates pass, weighted Tier 3 score 3.90. Two MINOR findings: Q7's source hint cites session-memory paths unreachable by a standalone researcher, and no question covers the docs update surface. Neither is blocking — a Phase 2 researcher can answer all 11 questions and produce output sufficient for Phase 3 brainstorm. PASS with minor notes.
