# Phase 1: Research Questions

## Objective
Produce a comprehensive set of research questions that Phase 2 must answer. These questions drive the audit of all 3 pipeline modes.

## Questions to Answer

### Q1: Agent Dispatch Map per Pipeline
For each pipeline skill (fix-ticket, fix-bugs, implement-feature, scaffold):
- List every agent dispatched, in order
- For each dispatch: what context is passed? What model is used?
- Are there conditional dispatches (profile skips, config-dependent)?
- What is the agent's role in this specific pipeline (may differ from its description)?

### Q2: Shared Agent Cross-Mode Analysis
For each shared agent (fixer, reviewer, test-engineer, e2e-test-engineer, rollback-agent, publisher, architect, acceptance-gate, deployment-verifier):
- Which pipelines use it?
- Does the agent receive different context per pipeline?
- Does the agent behave differently per pipeline? (e.g., fixer in bug mode vs feature mode)
- Is the agent's content adequate for ALL modes it serves?
- Does the agent description mention all modes it serves?

### Q3: Agent Content Quality Assessment
For each of the 19 agents:
- Goal: Is it clear, specific, and actionable?
- Process: Are steps numbered, complete, and in logical order?
- Constraints: Are NEVER rules comprehensive? Any missing failure modes?
- Output format: Is it structured enough for downstream consumption?
- Model assignment: Is the right model used (opus for critical, sonnet for analysis, haiku for mechanical)?

### Q4: Mode-Specific Agent Gaps
- Bug pipeline: Is there a gap between triage-analyst output and fixer input? Does code-analyst provide enough context?
- Feature pipeline: Does spec-analyst produce enough for architect? Does architect produce enough for fixer?
- Scaffold pipeline: Does spec-writer produce enough for spec-reviewer loop? Does scaffolder produce enough for fixer?

### Q5: Core Contract Coverage
For each core contract (fixer-reviewer-loop, block-handler, decomposition-heuristics, config-reader, state-manager, agent-override-injector, mcp-preflight, mcp-detection, profile-parser, post-publish-hook, fix-verification):
- Does it make assumptions specific to one pipeline mode?
- Is it referenced by all pipelines that should use it?
- Are input/output contracts complete?

### Q6: State Schema Coverage
- Are there pipeline-specific fields missing?
- Are fields overloaded (same field, different meaning per mode)?
- Does the schema support scaffold's unique needs (infrastructure, spec, batches)?
- Are step status values consistent across modes?

### Q7: Consistency and Duplication
- Is there duplicated logic between fix-ticket and fix-bugs? (They share the same bug pipeline)
- Is there duplicated tracker subtask creation code across skills?
- Are block comment templates consistent across all agents?

### Q8: Best Practices Assessment
For the fixer agent specifically:
- Does it have adequate mode-awareness (bug fix vs feature implementation vs scaffold feature)?
- Is the NEEDS_DECOMPOSITION escape hatch well-documented?
- Is the 100-line diff limit appropriate for all modes?

For the reviewer agent:
- Is the adversarial review appropriate for scaffold mode?
- Is the AC fulfillment check well-integrated for all modes?
- Is the 3-issue minimum gate appropriate for all modes?

For the test-engineer:
- Is "1-3 focused tests" appropriate for feature mode (may need more)?
- Does it handle scaffold mode (where test infrastructure may not exist yet)?

### Q9: Missing Agents
- Should there be a dedicated "feature-analyst" agent separate from spec-analyst?
- Should there be a "integration-test-engineer" for cross-subtask testing after decomposition?
- Should rollback-agent handle scaffold-specific rollback differently?

### Q10: Documentation and Description Quality
- Do all agent descriptions accurately reflect what they do?
- Are frontmatter descriptions concise enough for Claude Code's agent picker?
- Is the style field meaningful and consistent?
