# Phase 3: Brainstorm

## Objective
Given the audit findings from Phase 2, brainstorm approaches for improving agent content, core contracts, and state schema across all 3 pipeline modes.

## Method
1. Review all HIGH and MEDIUM findings from Phase 2
2. For each finding, brainstorm 2-3 approaches to address it
3. Evaluate trade-offs: complexity vs benefit, backward compatibility risk, implementation effort
4. Consider cross-cutting patterns that could address multiple findings at once

## Brainstorm Areas

### Area 1: Mode Awareness in Shared Agents
The fixer, reviewer, test-engineer, and other shared agents serve multiple pipeline modes. How should they handle mode differences?

Approaches to consider:
- **A1a: Mode-specific sections in agent content** — Add `## Bug Mode`, `## Feature Mode`, `## Scaffold Mode` sections with mode-specific guidance
- **A1b: Context-driven adaptation** — Keep agent content mode-agnostic; rely on skill dispatch context to communicate mode differences
- **A1c: Mode-aware Process steps** — Add conditional steps: "If this is a feature (AC from spec-analyst), then... If this is a bug (AC from triage), then..."

### Area 2: Agent Content Quality Improvements
Based on quality scorecard findings. What specific content improvements have the highest impact?

### Area 3: Core Contract Gaps
If contracts make single-mode assumptions, how to generalize them?

### Area 4: State Schema Improvements
If fields are overloaded, should they be renamed? Should scaffold get its own section?

### Area 5: Missing Best Practices
What industry best practices are not reflected in agent content?

### Area 6: Structural Improvements
Are there agents that should be split, merged, or added?

## Output Format
For each brainstorm area:
```
### Area N: {title}

**Finding:** {what Phase 2 revealed}
**Impact:** {HIGH/MEDIUM/LOW}

**Approach A:** {description}
- Pros: ...
- Cons: ...
- Effort: {LOW/MEDIUM/HIGH}

**Approach B:** {description}
- Pros: ...
- Cons: ...
- Effort: {LOW/MEDIUM/HIGH}

**Recommendation:** {which approach and why}
```
