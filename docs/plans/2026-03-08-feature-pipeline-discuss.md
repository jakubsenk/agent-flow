# Discussion: Feature Pipeline Improvements

**Date:** 2026-03-08
**Agents:** spec-analyst, architect, reviewer
**Status:** PROPOSED

---

## spec-analyst (Requirements-focused, clarity-driven, structured)

The current pipeline has a fundamental gap: I receive a feature ticket, extract acceptance criteria, and move on. But nobody validates whether the AC I produce are actually good. Nobody checks whether the original ticket was complete enough. I am an analyst, not a rubber stamp -- yet the pipeline treats me as one.

**AC extraction and writeback.** Today I extract AC and post a checkpoint comment. But I do not write the AC back to the ticket as a formal contract. This is a mistake. The AC should become the single source of truth on the ticket itself, not buried in my output that gets passed downstream as ephemeral context. If the developer reads the ticket later, they should see the agreed AC right there. I should write them back as a structured comment or update a custom field. And critically, somebody should review what I wrote -- either a second pass by me with a "reviewer hat" or a dedicated AC-reviewer agent. Self-review is weak. I would prefer an explicit AC review step, even if it is another invocation of me with different instructions.

**Spec quality gate.** Right now, if the ticket is vague but I can infer something with >50% confidence, I proceed. This is dangerous for features. Bugs have narrow scope -- features can spiral. I should actively comment on the ticket requesting clarification when I detect ambiguity, rather than guessing. The threshold should be higher for features: if ANY acceptance criterion requires inference rather than extraction, I should flag it. The pipeline should support a "pause and ask" mode where I post questions to the ticket and the pipeline waits for a human response before continuing.

**Decomposition and AC distribution.** When the architect decomposes work, each subtask gets its own acceptance criteria. But nobody checks whether the union of subtask AC covers all of the original feature AC. This is where requirements get lost. I should run a verification pass after decomposition: map each original AC to at least one subtask AC. If any original AC is orphaned, block. This is a natural extension of my role -- I already understand the AC, I should validate their distribution.

**My concern:** The pipeline optimizes for speed but not for specification quality. A 10-minute investment in better AC saves hours of rework in the fixer-reviewer loop. I have seen features where the fixer implements something technically correct but functionally wrong because the AC were ambiguous. The fix is upstream, not downstream.

## architect (Strategic, systems-thinking, trade-off aware)

I want to address something the spec-analyst hinted at but did not fully develop: the relationship between AC and architectural decisions. Today I receive a specification and design an implementation. The AC are in the spec, but they are not driving my design process -- they are a side artifact. This needs to change fundamentally.

**AC-driven architecture.** Every architectural decision should be traceable to at least one AC. If I propose adding a new service layer, I should explain which AC it enables. If I decompose into subtasks, each subtask's acceptance criteria should be a subset of the original AC -- and the mapping should be explicit in my task tree. I already have an `acceptance_criteria` field per subtask in my YAML output. What I lack is a `maps_to` field that links back to the original feature AC by number. This is a simple structural change with high impact: it creates an auditable chain from requirement to implementation to test.

**Decomposition AC coverage.** The spec-analyst's proposal for a post-decomposition verification pass is correct, but I think it should be my responsibility, not theirs. I am the one who created the decomposition -- I should prove it is complete. Adding a validation step at the end of my process (step 8.5 in my current flow) where I produce an AC coverage matrix would be natural. If any original AC is not covered by at least one subtask, I should either add a subtask or flag it.

**Acceptance gate at pipeline end.** The current pipeline ends with test-engineer and publisher. There is no explicit step that says "go through each AC and confirm it is fulfilled." Tests verify behavior, but they do not map 1:1 to AC. A test might cover three AC partially but none completely. I strongly advocate for a post-test "acceptance gate" -- either a new agent or a new invocation of the reviewer with AC-specific instructions. This agent reads the original AC, the implementation, and the test results, and produces a coverage matrix: AC-1: PASS (test_X, line Y of file Z), AC-2: FAIL (no test, no code reference). Any FAIL blocks the pipeline.

**Manual testing mode.** Some features involve UI, visual output, or user interaction that cannot be automated. The pipeline should support an optional "manual verification" step. When configured, the acceptance gate generates a test scenario document (step-by-step instructions for the developer) and pauses the pipeline. The developer confirms each step. This is controlled by a new config key -- not every project needs it, but for frontend-heavy projects, it is essential. I would place this after the automated acceptance gate and before the publisher.

**My trade-off concern:** Every new step adds latency. The pipeline is already 6+ agent invocations. Adding AC review, acceptance gate, and manual testing could double the time. The answer is not to skip them but to make them conditional: AC review only when the spec-analyst's confidence is below a threshold. Manual testing only when configured. The acceptance gate should always run -- it is the cheapest insurance against shipping incomplete features.

## reviewer (Adversarial, evidence-driven, thorough)

Let me be blunt: I am currently reviewing the wrong thing. My entire process is oriented around code quality -- root cause, conventions, regressions, security, performance. For bug fixes, this is correct. For features, I should also be reviewing against the acceptance criteria, and I am not. The pipeline gives me the AC as context, but my checklist does not include "does this implementation fulfill every AC?" That is a gap I can close immediately.

**AC-aware review.** My review output should include an explicit AC checklist section: for each acceptance criterion, a verdict (FULFILLED / PARTIALLY / NOT ADDRESSED) with evidence (specific file, line, function). If any AC is NOT ADDRESSED, the verdict is automatically REQUEST_CHANGES regardless of code quality. If PARTIALLY fulfilled, I should flag it as a HIGH issue. This is not a new agent -- it is an enhancement to my existing process. Add a step between my current steps 4 and 5 that specifically maps code changes to AC.

**The reviewer should not be the acceptance gate.** Despite what I just said, I do not think I should be the final acceptance gate. My review happens in the fixer-reviewer loop, which is iterative. The fixer might address my AC concerns in iteration 3, but by then I am focused on the delta from iteration 2, not the full AC list. The acceptance gate needs to happen after the loop completes, with a fresh perspective on the entire implementation. A separate step -- either a new agent or a distinct invocation of me with different instructions and full context -- is necessary.

**Spec quality and my downstream pain.** When the spec-analyst produces vague AC, I suffer. I cannot review against "the feature should work well" or "users should have a good experience." Every time I get an AC like that, I have to make judgment calls that should have been made upstream. The spec-analyst's proposal for a quality gate is not just nice-to-have -- it directly reduces my error rate. I would go further: if I encounter an untestable or ambiguous AC during review, I should be able to flag it as a pipeline issue, not just a code issue. The pipeline should track "AC quality issues raised by reviewer" as a feedback signal.

**Manual testing integration.** For features that require manual verification, I should be the one generating the test scenario document, not the architect. I am adversarial by design -- I will think of the edge cases the developer would miss. The test scenario should include not just happy path steps but adversarial scenarios: "Now try submitting the form with no data. Now try with 10,000 characters. Now resize the browser to 320px width." This is a natural extension of my edge case analysis expertise.

**My core concern:** The pipeline currently has no formal contract between what was promised (AC) and what was delivered (code + tests). The fixer-reviewer loop ensures code quality but not feature completeness. Adding AC traceability throughout the pipeline -- from spec-analyst through architect through reviewer through a final acceptance gate -- is the single highest-impact change we can make.

## Synthesis

**Key agreements across all three agents:**

1. Acceptance criteria must become a formal, traceable contract that flows through every pipeline stage -- not just context passed between agents.
2. A post-implementation acceptance gate is needed as a distinct step, separate from the reviewer loop.
3. The spec-analyst should actively validate ticket quality and write AC back to the issue tracker.
4. Decomposition must include explicit AC coverage mapping to prevent requirement loss.

**Key disagreement:**

- Who owns the AC coverage check after decomposition: spec-analyst (argues it is a requirements concern) vs. architect (argues the decomposer should prove completeness). Resolution: architect produces the mapping, spec-analyst validates it. Two-step verification.

**Concrete proposals:**

| # | What | Why | Impact on success rate | Complexity | New config keys | Agent/pipeline changes |
|---|------|-----|----------------------|------------|-----------------|----------------------|
| 1 | **AC writeback to ticket** -- spec-analyst writes extracted/proposed AC back to the issue tracker as a structured comment or custom field update | AC become the single source of truth visible to all stakeholders, not ephemeral pipeline context | +15% -- eliminates "built the wrong thing" failures | Low | None | spec-analyst: add step after extraction to write AC back to ticket |
| 2 | **AC quality review step** -- after spec-analyst extracts AC, a second pass reviews them for testability, completeness, and ambiguity. If issues found, post questions to ticket and pause pipeline | Prevents vague AC from poisoning downstream agents | +10% -- reduces fixer-reviewer loop iterations caused by ambiguous requirements | Medium | `AC Review` (optional, in Feature Workflow section): `enabled` / `pause-on-questions` | spec-analyst: add self-review pass with reviewer-hat instructions, or new "ac-reviewer" agent invocation |
| 3 | **AC-driven architecture with `maps_to` field** -- architect's task tree subtasks include explicit mapping from subtask AC to original feature AC numbers | Creates auditable requirement-to-implementation traceability, prevents AC loss during decomposition | +10% -- eliminates "requirement lost in decomposition" failures | Low | None | architect: add `maps_to` field to subtask YAML schema, add coverage matrix validation step |
| 4 | **Post-decomposition AC coverage verification** -- architect produces AC coverage matrix, spec-analyst validates no original AC is orphaned | Two-step verification ensures decomposition completeness | +5% (on top of proposal 3) | Medium | None | implement-feature.md: add verification step between architect and fixer stages |
| 5 | **AC-aware reviewer checklist** -- reviewer adds explicit per-AC verdict (FULFILLED/PARTIALLY/NOT ADDRESSED) to review output | Reviewer catches feature incompleteness during the fixer loop, not just code quality issues | +15% -- single biggest quality improvement for feature pipeline | Low | None | reviewer: add AC checklist step between steps 4 and 5, update output format |
| 6 | **Acceptance gate step** -- new pipeline step after test-engineer, before publisher. Fresh evaluation of all AC against final code + tests. Produces coverage matrix with evidence. Any unfulfilled AC blocks | Final safety net ensuring nothing ships incomplete | +20% -- prevents incomplete features from reaching PR | Medium | None | New step in implement-feature.md (step 6h). Can use reviewer agent with distinct "acceptance-gate" instructions, or a new `acceptance-gate` agent |
| 7 | **Manual testing mode** -- optional step after acceptance gate. Generates adversarial test scenario document, pauses pipeline for developer confirmation | Covers UI/UX features that cannot be verified by automated tests | +5% (for applicable projects) | Medium | `Manual Testing` section (optional): `Enabled`, `Trigger` (always / ac-tagged / config) | reviewer generates test scenarios (leverages adversarial expertise), implement-feature.md: add optional pause step |
| 8 | **AC feedback loop** -- when reviewer encounters untestable/ambiguous AC during review, flag it as a pipeline-level issue. Track across runs to improve spec-analyst behavior | Continuous improvement signal for upstream AC quality | +5% long-term | High | `AC Feedback` (optional): `Enabled`, `Output` | reviewer: new issue category, implement-feature.md: feedback tracking mechanism |

**Priority order (by impact/complexity ratio):** 5 > 1 > 6 > 3 > 2 > 7 > 4 > 8

**Minimum viable improvement (proposals 1, 3, 5, 6):** These four changes create the AC traceability chain with the highest impact and lowest total complexity. They require changes to three existing agents (spec-analyst, architect, reviewer) and one new pipeline step (acceptance gate), with zero new config keys.
