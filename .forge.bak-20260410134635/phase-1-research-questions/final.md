# Phase 1: Research Findings — Review Report Claim Verification

## Verdicts Summary

| # | Recommendation | Verdict | Severity |
|---|---------------|---------|----------|
| D1 | Context Management | PARTIALLY_CONFIRMED | Overstated |
| D2 | Prompt Injection | CONFIRMED | Valid |
| D3 | Structured Output | PARTIALLY_CONFIRMED | Overstated |
| D4 | Reviewer Differentiation | REFUTED | Inaccurate |
| D5 | Graduated Escalation | PARTIALLY_CONFIRMED | Partially valid |
| D6 | Cost Guardrails | CONFIRMED | Valid |
| D7 | Flaky Test Detection | CONFIRMED | Valid |
| D8 | CI Tests | PARTIALLY_CONFIRMED | Known issue |
| D9 | Context Summarization Agent | REFUTED | Unnecessary |
| D10 | Observability Hooks | PARTIALLY_CONFIRMED | Partially valid |
| D11 | Multi-Reviewer | PARTIALLY_CONFIRMED | Already achievable |
| D12 | Agent Versioning | CONFIRMED | Valid |

## Detailed Findings

### D1: Context Management — PARTIALLY_CONFIRMED
- **What report says:** No context summarization/budgeting, each agent gets full history, quality degrades
- **What code shows:** Agents run as SEPARATE Task tool invocations. Each gets a curated Context: block defined explicitly in the skill, NOT accumulated conversation history. fix-ticket/SKILL.md passes specific variables (triage output, code-analyst report) to each step.
- **What's valid:** No context-budget config key. Fixer-reviewer loop accumulates critique across iterations without compression. Decomposition flows include "summary of previous subtasks" which can grow.
- **What's wrong:** The core claim of "each agent gets context of all previous steps" is architecturally inaccurate. The Task tool provides inherent context isolation.

### D2: Prompt Injection Protection — CONFIRMED
- **What report says:** No sanitization of external content, no [EXTERNAL INPUT] tagging
- **What code shows:** Correct. Issue content from trackers flows directly into agent prompts. config-reader.md has zero sanitization mention. No agent mentions input validation. Reviewer checks for injection in *user code*, not in pipeline inputs themselves.
- **Practical note:** Claude Code itself has built-in safety guardrails that partially mitigate this, but the plugin adds no defense layer.

### D3: Structured Agent Output — PARTIALLY_CONFIRMED
- **What report says:** Free-text output, no JSON schema, no output-validator
- **What code shows:** No output-validator module exists. No JSON schema validation. BUT outputs are NOT "free text" — all agents produce rigidly templated markdown with consistent headings and machine-readable signal tokens (APPROVE, UNCLEAR, NEEDS_DECOMPOSITION, etc.) parsed by string matching in skills.
- **What's wrong:** "Free text" is misleading. The outputs are structured, just validated by convention rather than schema.

### D4: Reviewer Instruction Differentiation — REFUTED
- **What report says:** Reviewer and fixer share similar "senior developer" perspective, same blind spots
- **What code shows:** Completely different personas. Fixer: "Pragmatic, minimal, surgical" — focuses on smallest possible fix. Reviewer: "Adversarial, evidence-driven, thorough" — mandatory cynicism, minimum 3 findings, explicit security checklist (injection, auth bypass, XSS), AC fulfillment audit, edge case analysis. Structural asymmetry by design.
- **Report is wrong here.**

### D5: Graduated Escalation — PARTIALLY_CONFIRMED
- **What report says:** Binary block/success, no NEEDS_CLARIFICATION
- **What code shows:** Fixer has NEEDS_DECOMPOSITION (third state, triggered when scope > 4 files or > 100 lines). Skills have user confirmation checkpoints (decomposition plan approval, AC coverage, PR creation).
- **What's valid:** No general NEEDS_CLARIFICATION state — mid-pipeline agents cannot pause and ask clarifying questions about ambiguous requirements.

### D6: Cost Guardrails — CONFIRMED
- **What report says:** No hard cost ceiling, no automatic stop
- **What code shows:** Correct. No cost/token fields in state schema. No cost config key. estimate skill is pre-run and read-only. fix-ticket has a static hardcoded cost estimate at step 9c (informational only). A 2026-02-27 brainstorm doc noted "configurable token budget" as an idea but never implemented.

### D7: Flaky Test Detection — CONFIRMED
- **What report says:** No flaky test handling, pipeline blocks on failure
- **What code shows:** test-engineer.md constrains agents to never WRITE flaky tests but has no detection mechanism for existing flaky tests. "Max 3 attempts" retry applies to fixing newly-written tests, not re-running to detect intermittent failures. Any unexplained test failure → Block with no retry path.

### D8: Plugin Self-Tests in CI — PARTIALLY_CONFIRMED
- **What report says:** No CI, no regression detection
- **What code shows:** CI workflow exists (.gitea/workflows/test.yaml) but runner not configured — all jobs cancelled at 0s. Local test suite has ~50 scenarios including structural validation (frontmatter-completeness, read-only-agents, xref-agent-registry). Tests exist and catch regressions, but only locally.
- **Already known issue** (documented in project memory).

### D9: Context Summarization Agent — REFUTED
- **What report says:** Need Haiku summarizer between phases
- **What code shows:** Architecture already provides context isolation via Task tool dispatch. Each agent gets minimal, curated context — not a conversation thread. State persistence uses state.json + pipeline.log. A summarizer would add latency/cost with no benefit.

### D10: Observability Hooks — PARTIALLY_CONFIRMED
- **What report says:** Dashboard post-hoc only, no real-time metrics, unstructured notifications
- **What code shows:** Dashboard and metrics ARE post-hoc. Webhooks DO fire structured JSON payloads (core/post-publish-hook.md, core/block-handler.md). pipeline.log IS written in real-time locally but not exposed externally. The gap: only 2 webhook events (block, PR), minimal payload (4-5 fields each).

### D11: Multi-Reviewer Pattern — PARTIALLY_CONFIRMED
- **What report says:** Need two reviewers with different lenses for complex tickets
- **What code shows:** Reviewer already has explicit security checklist. security-analyst custom agent example exists in examples/custom-agents/. Agent Overrides can strengthen focus. What's NOT supported: two reviewers participating interactively in the fixer↔reviewer loop (would need core/fixer-reviewer-loop.md changes).

### D12: Agent Versioning — CONFIRMED
- **What report says:** No version field in frontmatter, resume unstable across changes
- **What code shows:** Correct. Frontmatter has only name, description, model, style. Resume reads state.json step statuses but never checks agent definition versions. Plugin semver in plugin.json exists but is not referenced in run state.
