# Phase 3 — Brainstorm

## Persona

You are a plugin architect evaluating design alternatives for the three pipeline verification changes. Your goal is to identify the best approach for each change, considering consistency with existing patterns and minimal disruption.

## Task Context

Patch v6.3.3: strengthen pipeline output verification in three places.

## Task Instructions

For each of the three changes, evaluate 2-3 approaches and recommend one:

### Change 1: Scaffold Step 3 Validation Strengthening

**Approach A — Inline expansion:** Expand the existing one-liner in Step 3 into a full validation procedure (read Build command and Test command from generated CLAUDE.md, run them, retry on failure).

**Approach B — Delegate to /scaffold-validate:** After scaffolder finishes, invoke the `/scaffold-validate` skill which already has full validation logic.

**Approach C — Hybrid:** Keep the scaffolder's internal validation (step 4) but add a post-scaffolder verification in the skill that independently runs build+test from the generated CLAUDE.md.

**Recommendation criteria:**
- Consistency with legacy flow L3 pattern
- Avoid duplication of validation logic
- Clear retry semantics (who retries — skill or agent?)

### Change 2: Scaffolder Scorecard Hard Requirements

**Approach A — Promote in scorecard:** Change the scorecard header to make Build and Tests blocking, keep other items advisory.

**Approach B — Move to Constraints:** Add "Builds successfully" and "Tests pass" to the Constraints section as NEVER rules.

**Approach C — Both:** Add to Constraints AND mark as blocking in scorecard.

**Recommendation criteria:**
- Consistency with agent definition format (Goal → Expertise → Process → Constraints)
- Clarity for the agent about what blocks vs what's informational

### Change 3: Smoke Check After Fixer-Reviewer Loop

**Approach A — New step in skills:** Add a new numbered step in fix-ticket and fix-bugs between reviewer and test-engineer.

**Approach B — Extend fixer-reviewer-loop.md:** Add post-loop verification to the core contract so all consumers get it.

**Approach C — Extend Build step:** Move the existing Build step to after the reviewer loop.

**Recommendation criteria:**
- The Build step already runs BEFORE reviewer — should it also run AFTER?
- Does the core contract change affect other consumers (implement-feature)?
- Step numbering impact

## Success Criteria

- One recommended approach per change with clear rationale
- Trade-offs named for each rejected approach
- No over-engineering — this is a patch, not a redesign

## Anti-Patterns

- Do NOT propose new agents or skills
- Do NOT change the config contract
- Do NOT restructure the pipeline — minimal insertion only

## Codebase Context

- The legacy scaffold flow (L3) already has explicit build+test+lint+CLAUDE.md checks
- The fixer-reviewer-loop.md core contract runs Build after each fixer iteration
- implement-feature also uses fixer-reviewer-loop.md — any changes there affect it too
- Agent Constraints section uses NEVER rules and hard limits
