# Phase 1 - Research Questions

## Context
Audit of ceos-agents plugin agent definitions and the implement-feature skill. Goal: assess whether agents designed for the bug-fix pipeline are properly defined for dual-use in the feature pipeline.

## Research Questions

### RQ-1: Bug-Fix-Centric Language in Shared Agents
For each agent dispatched by implement-feature (fixer, reviewer, test-engineer, e2e-test-engineer, acceptance-gate, publisher, rollback-agent, architect), catalog every instance of bug-fix-specific language in:
- Frontmatter (name, description)
- Opening role statement ("You are a...")
- Goal section
- Expertise section
- Process steps (references to "bug", "fix", "root cause", "triage analysis", "impact report", "bug report")
- Constraints

Rate each finding: BLOCKING (would confuse the model in feature context), WARNING (suboptimal but functional), or OK (acceptable dual-use language).

### RQ-2: Context Passing from implement-feature to Agents
Review how implement-feature passes context to each agent (steps 3, 4, 6b, 6d, 6e, 6g, 6h, 10, X):
- Does the skill explicitly tell the agent it is operating in a feature context (vs bug-fix)?
- What upstream artifacts are passed (spec-analyst output vs triage-analyst output)?
- Are there any places where the skill references bug-fix artifacts that don't exist in the feature pipeline?

### RQ-3: Process Step Applicability
For each shared agent, identify process steps that are inapplicable or harmful in the feature context:
- Fixer step 1: "Read the triage analysis and impact report" - these don't exist in feature pipeline
- Fixer step 5 RED phase: "Write a test that reproduces the bug" - features don't have bugs to reproduce
- Reviewer step 1: "Read the original bug report, triage analysis, impact report"
- Test-engineer step 1: "Read the bug report, fixer output (changed files, root cause)"
- E2E-test-engineer step 1: "Read the bug report and fix diff"

### RQ-4: AC Mechanism Consistency
Compare AC handling between bug-fix and feature pipelines:
- Bug-fix: triage-analyst extracts AC -> passed to fixer/reviewer
- Feature: spec-analyst extracts AC -> passed to fixer/reviewer
- Are the AC formats identical? Does the reviewer's AC Fulfillment section work the same way?
- Does the acceptance-gate agent handle both sources correctly?

### RQ-5: Fixer NEEDS_DECOMPOSITION in Feature Pipeline
The fixer can signal NEEDS_DECOMPOSITION. In the feature pipeline, decomposition is already handled by the architect (step 5). What happens if the fixer signals NEEDS_DECOMPOSITION during a subtask execution? Is this documented? Is there a conflict?

### RQ-6: Missing Feature-Specific Guardrails
Are there any constraints or process steps that should exist for feature work but are missing?
- Feature scope creep prevention
- API design review (new APIs vs fixing existing)
- Migration/backward compatibility for new features
- Documentation requirements for new features

### RQ-7: Core Contract Fitness
Review core/fixer-reviewer-loop.md:
- The input contract says "context = Bug report or spec + AC + code-analyst output"
- Is this consistently dual-purpose, or does it lean toward bug-fix?
- Are there any implicit assumptions about bug-fix-specific inputs?

## Files to Read
- agents/fixer.md (DONE)
- agents/reviewer.md (DONE)
- agents/spec-analyst.md (DONE)
- agents/architect.md (DONE)
- agents/test-engineer.md (DONE)
- agents/e2e-test-engineer.md (DONE)
- agents/acceptance-gate.md (DONE)
- agents/publisher.md (DONE)
- agents/rollback-agent.md (DONE)
- skills/implement-feature/SKILL.md (DONE)
- skills/fix-ticket/SKILL.md (partial)
- core/fixer-reviewer-loop.md (DONE)
