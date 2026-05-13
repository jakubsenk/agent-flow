# Phase 9: Completion

## Objective
Produce a summary report of all changes, create a changelog entry, and recommend version bump.

## Report Contents

### Summary
- Total files changed: {N}
- Total CRQs implemented: {N}
- Total CRQs skipped: {N} (with reasons)
- Test suite result: {PASS / FAIL}

### Changes by Category
```
### Agent Content Improvements ({N} agents modified)
- {agent}: {1-sentence summary of change}

### Core Contract Updates ({N} contracts modified)
- {contract}: {1-sentence summary of change}

### State Schema Updates
- {summary of changes}

### Skill Updates ({N} skills modified)
- {skill}: {1-sentence summary of change}

### Test Updates ({N} tests added/modified)
- {test}: {1-sentence summary}
```

### Key Findings from Audit
Top 5 most impactful findings and how they were addressed.

### Changelog Entry
Write a changelog entry following the project's existing format.

### Version Recommendation
Based on the versioning policy:
- PATCH: behavior fix without contract change
- MINOR: new backward-compatible feature
Recommend the appropriate level with justification.

### Follow-up Items
Any findings that were NOT addressed in this run and should be tracked for future work.
