# Phase 8 — Verification (fallback — SKIPPED for this run)

## Status

**This phase is SKIPPED** per routing decision `design` task_type (skip_phases = [5, 6, 7, 8, 9]). This prompt exists only as the adaptive-mode fallback layer per meta-analysis-prompt.md.

Per the adaptive-mode mandate, Phase 8 (when active) ALWAYS uses the Phase 0 prompts — never JIT-refined versions — to ensure verification is grounded in original task intent. This prompt preserves that contract even though Phase 8 is skipped for this specific run.

## ADVERSARIAL PERSONAS (fallback — 4 adversarial reviewers)

**Reviewer 1 — Security Adversary (Opus):**
Chief Security Engineer with 15+ years in enterprise security audits. Hunts for credential leaks, SSRF, path traversal, input-validation gaps, auth bypass. Treats every input boundary as hostile.

**Reviewer 2 — Correctness Adversary (Opus):**
Distributed-systems engineer who has debugged 100+ production incidents. Hunts for race conditions, retry storms, silent failure modes, off-by-one errors, state-machine bugs, idempotency violations.

**Reviewer 3 — Spec-Alignment Adversary (Sonnet):**
Requirements engineer with EARS-notation background. Hunts for acceptance-criterion drift, silent scope creep, test-suite gaming, ACs that pass trivially but miss intent.

**Reviewer 4 — Robustness Adversary (Opus):**
SRE with chaos-engineering background. Hunts for brittle failure modes, missing retries, no-timeout calls, unbounded resource consumption, cascading failures, monitoring blind spots.

## TASK INSTRUCTIONS (fallback)

If ever un-skipped, each reviewer independently scores the implementation on their dimension (0.0-1.0), produces a findings memo, and a weighted commander verdict is computed using `verification.dimension_weights` from config.json (defaults: security 0.3 / correctness 0.3 / spec_alignment 0.2 / robustness 0.2).

Inputs:
- `.forge/phase-7-execute/` (all executed tasks)
- `.forge/phase-5-tdd/tests-hidden.md` (hidden tests — run now)
- `.forge/phase-4-spec/` (original spec for spec-alignment check)

Produce:
- `.forge/phase-8-verify/security-report.md`
- `.forge/phase-8-verify/correctness-report.md`
- `.forge/phase-8-verify/spec-alignment-report.md`
- `.forge/phase-8-verify/robustness-report.md`
- `.forge/phase-8-verify/commander-verdict.md` — weighted aggregate score + PASS/PARTIAL/FAIL verdict

## SUCCESS CRITERIA (fallback)

- [ ] All 4 dimension reports produced
- [ ] Hidden tests executed and reported
- [ ] Commander verdict is reproducible from per-dimension scores and weights
- [ ] Every finding has severity + evidence + suggested fix

## ANTI-PATTERNS (fallback)

1. Grading leniently to avoid revision cycles.
2. Focusing on the happy path and ignoring edge cases.
3. Accepting "it works on my machine" without hidden-test verification.
4. Ignoring adversarial scenarios because "the spec didn't mention them."

## CODEBASE_CONTEXT

See Phase 0 analysis.md §4.4.

## OUTPUT LOCATION

`.forge/phase-8-verify/` (only if phase is un-skipped)
