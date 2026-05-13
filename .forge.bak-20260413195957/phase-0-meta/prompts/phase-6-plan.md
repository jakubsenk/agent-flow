# Phase 6: Implementation Plan

## Objective
Create an ordered sequence of edits, grouped by priority and dependency, that implements all CRQs from the Phase 4 spec.

## Plan Structure

### Execution Order
Group CRQs into implementation batches. Within each batch, changes are independent (can be done in any order). Between batches, earlier batches must complete before later ones.

```
## Batch 1: {name} (Priority P0)
Dependencies: none
CRQs: CRQ-1, CRQ-2, CRQ-3
Verification: run tests/scenarios/{relevant-tests}.sh

## Batch 2: {name} (Priority P0)
Dependencies: Batch 1
CRQs: CRQ-4, CRQ-5
Verification: run tests/scenarios/{relevant-tests}.sh

...

## Batch N: Final verification
Dependencies: All previous batches
Verification: run full test suite
```

### Per-CRQ Edit Instructions
For each CRQ, specify:
```
### CRQ-{N}: {title}
File: {path}
Action: {EDIT existing content / ADD new section / REMOVE section}
Old text (for EDIT): {exact text to find}
New text (for EDIT): {exact replacement text}
Location (for ADD): {after which section/line}
Rationale: {1 sentence}
```

## Constraints
- Plan must be executable by a single agent in Phase 7
- Each edit must be precise enough to use the Edit tool
- Batch boundaries must be clear
- Verification steps must reference specific test scenarios
- Total edits should be achievable in one session (estimate: 15-30 edits)
