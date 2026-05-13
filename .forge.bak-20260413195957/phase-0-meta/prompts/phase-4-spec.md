# Phase 4: Specification

## Objective
Produce a precise, file-level specification of ALL changes to be made. Every change must have: file path, what to change, WHY, and expected outcome.

## Specification Format

### Change Registry
For each change, record:
```
### CRQ-{N}: {title}
- **File:** {absolute path}
- **What:** {precise description of what to add/modify/remove}
- **Why:** {which Phase 2 finding this addresses}
- **Expected outcome:** {what will be different after the change}
- **Risk:** {LOW/MEDIUM/HIGH — backward compatibility impact}
- **Priority:** {P0/P1/P2 — implementation order}
- **Dependencies:** {other CRQs that must be done first, or "none"}
```

## Change Categories

### Category A: Agent Content Improvements
Changes to agent markdown files in `agents/`. These are the primary audit outputs.

### Category B: Core Contract Updates
Changes to core contract files in `core/`. Only if Phase 2 found genuine gaps.

### Category C: State Schema Updates
Changes to `state/schema.md`. Only if Phase 2 found overloaded or missing fields.

### Category D: Skill Updates
Changes to pipeline skill files. Only if needed to support agent changes or fix inconsistencies.

### Category E: Test Updates
Changes to test scenarios. Only if existing tests need updating due to changes above.

## Constraints
- Every change must trace back to a Phase 2 finding
- No changes that would require a MAJOR version bump (no breaking config contract changes)
- Agent content changes must preserve the exact frontmatter format
- Agent content changes must preserve Goal -> Expertise -> Process -> Constraints section order
- Process steps must remain numbered
- Constraints must still start with NEVER or define hard limits
- No new agents unless strongly justified by audit findings
- No removing existing agents
- All changes must be backward compatible with existing Automation Config contract

## Acceptance Criteria for the Spec
1. Every HIGH finding from Phase 2 has at least one CRQ addressing it
2. Every CRQ has a clear file path and precise description
3. Dependencies between CRQs are documented
4. Risk assessment is provided for each CRQ
5. Total change scope is manageable (estimated: 15-30 CRQs)
