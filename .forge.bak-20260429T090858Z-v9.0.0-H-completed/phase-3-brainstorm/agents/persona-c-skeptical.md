# Persona C: The Skeptical Operator — "Show Me The Block, Or Stop Adding Surface Area"

**Recommendation:** PARTIAL. Add `## Outputs` ONLY (not `## Inputs`) to exactly 4 high-traffic agents — fixer, reviewer, analyst, test-engineer — as **optional, lint-validated only**. Eighteen-agent rollouts and `## Inputs` sections are speculative work not justified by Q1 evidence. Ship as v8.1.0; reserve v9.0.0 for a real breaking change.

**Schema language:** Typed prose markdown table — three columns (`Section` backtick-quoted, `When emitted`, `Required fields`). No JSON Schema. No TypeScript interfaces. EBNF in an LLM prompt is theater.

**Contract location:** Dedicated `## Outputs` section in agent body, AFTER `## Process` and BEFORE `## Constraints`. No frontmatter extension (Task tool ignores unknown frontmatter — Q2). No sidecar files (operational nightmare: now I have to grep two places when an override misfires).

**Validation mechanism:** Static lint via `tests/scenarios/v9-outputs-section-shape.sh` and `tests/scenarios/xref-outputs-skill-references.sh`, both with `exit 77` SKIP-guard. **NO LLM self-validation** — if the agent prompt says "validate your output matches the schema," that is the fox guarding the henhouse. The whole point of Q2 is that nothing downstream actually parses output structure; pretending otherwise is theater.

**Backward-compat strategy:** Additive optional. SKIP-guard at section level (per C9). Customization/ overrides are unaffected (C4 — injector is structure-blind, append-only). Forbid renaming `## Project-Specific Instructions` heading anywhere in the codebase — add a regression scenario.

**Versioning verdict:** MINOR — v8.1.0. Per CLAUDE.md Versioning Policy strict reading (Q8): no external tooling parses these sections today, override injector ignores them, optional means consuming projects don't break. v9.0.0 should be reserved for `.md` overlay hard-removal + deprecated agent name hard-errors (already pre-announced — those ARE breaking).

**Test strategy:**
- `v9-outputs-section-shape.sh` — for each of {fixer, reviewer, analyst, test-engineer}, SKIP if `## Outputs` absent, else assert table has Section/When/Required columns and at least one row backtick-quotes the existing runtime output heading (`## Fix Report`, `## Code Review`, `## Triage Analysis`/`## Impact Report`, `## Test Report`).
- `xref-outputs-skill-references.sh` — every backtick-quoted section name in any agent's `## Outputs` MUST appear in at least one `skills/**/SKILL.md` (catches drift when reviewer renames `## Code Review` and SKILL.md still greps the old name).
- `outputs-section-position.sh` — if `## Outputs` exists, it sits between `## Process` and `## Constraints`. SKIP otherwise.
- `customization-heading-collision.sh` — assert no file under `examples/customization/` or `examples/agent-overrides/` contains literal `## Outputs` or `## Project-Specific Instructions`.
- Update `section-order.sh` to tolerate optional `## Outputs` insertion point.

**Defense (300-500 words):**

Q1 is the answer. Three full forge cycles, 62 documented failures, **zero** caused by output-section mismatch. Persona B will wave at "Hyrum's Law" and "future tooling"; that is exactly the kind of speculative ROI I have been burned by twice in production. At BIFITO and drmax-readmine-test, every additional structural assertion in an agent prompt is one more thing that drifts when someone adds a column or renames a heading, and one more SKIP that masks regressions because the operator does not understand which guard fired.

The honest counter-argument is the coverage gap: the harness has no scenarios that would *catch* an output-shape violation, so "no observed failures" partly means "no observers." I accept that. My response is targeted lint, not blanket formalization. Four agents — the four that skills/SKILL.md actually grep for output headings (`## Fix Report`, `## Code Review`, `## Triage Analysis`, `## Impact Report`, `## Test Report`) — get a `## Outputs` section that names exactly those headings. The `xref-outputs-skill-references.sh` scenario then fails the moment someone renames a heading without updating the consumer. That is concrete operational ROI: it prevents the drift class that *would* cause a real block, instead of decorating 18 agents to satisfy a contract aesthetic.

I refuse `## Inputs` outright. Q4 says modes are already encoded as `## Process — Phase: triage/impact`. Adding `## Inputs — Phase: triage` duplicates information that lives in the dispatch step and creates a second source of truth. Two sources of truth = two places to forget to update = a guaranteed v8.1.x patch ticket. The smolagents precedent (Q5) is "declaration-mandatory + runtime-advisory"; the LLM cannot enforce its own input shape any more than it can enforce its output shape — a Process step that says "Read the triage analysis" is already the input contract, in prose, and the LLM reads prose just fine.

I refuse mandatory enforcement (the v9.0.0 path). C7 says consuming-project migration is zero-touch either way; the only people who pay for "mandatory" are us, and the cost is rewriting 14 low-traffic agents (publisher, rollback-agent, etc.) for headings their skill consumers do not grep. That is busywork dressed as discipline.

Persona B's strongest counter is that v10 Node.js Runtime will need machine-readable contracts. Fine — when v10 lands, promote the optional table to mandatory and bump MAJOR then. Premature commitment to a contract format we will regret is exactly the Hyrum's Law trap, just with the arrow pointing the other direction.

**Failure modes you accept:**
1. The 14 unmodified agents (publisher, scaffolder, etc.) remain "uncontracted." If a future skill author renames `## Publish Report`, the xref scenario will not catch it — only the 4 covered agents are policed. Acceptable: those 4 are where 90% of the skill-grep traffic lives.
2. Operators who *want* JSON-Schema-grade machine validation for dashboard ingestion are not served by v8.1.0. They wait for v10. Acceptable: today's dashboard plan is FE drag-drop CLI export (per MEMORY v9.1.0=F), not agent-output parsing.
3. SKIP-guard masking: if a `## Outputs` section is *deleted* from an agent that previously had it, the shape scenario silently SKIPs instead of failing. Mitigation: `xref-outputs-skill-references.sh` still fails because the skill grep target disappears from the agent file — the skill-side reference catches the regression even when the shape-side does not.

**Summary (under 80 words):** Q1 evidence demolishes the case for blanket formalization. Add optional `## Outputs` (not `## Inputs`) to the 4 agents whose output headings skills actually grep, lint via two new bash scenarios with `exit 77` SKIP-guards, ship as v8.1.0 MINOR. Reserve v9.0.0 for the already-pre-announced breaking changes (`.md` overlay removal, deprecated agent name hard-errors). Refuse LLM self-validation, refuse `## Inputs`, refuse mandatory rollout. Earn the surface area with evidence, not aesthetics.
