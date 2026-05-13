# Phase 0 Analysis

## Task Classification

**Type:** migration + refactor (hybrid)
- Item 1 (bare path migration): migration — systematic find-and-replace of a pattern across 12 references in 4 files
- Item 2 (structured error_type): refactor — extending an internal contract with a new output field
- Item 3 (Step 10 TLS): migration — replicating an existing pattern from Step 9 to Step 10

**Primary type for routing:** migration

## Complexity

| Dimension | Score | Rationale |
|-----------|-------|-----------|
| Scope | 3 | 4 skill files + 1 core file + 1 test file. ~12 individual edits across files. |
| Ambiguity | 1 | Fully specified in roadmap. Source pattern exists to replicate. |
| Risk | 2 | PATCH-level. No config contract changes. Markdown-only. |
| **Composite** | **3** | max(3, 1, 2) = 3 |

## Fast-Track Eligibility

**Eligible:** NO (Composite 3 > threshold 2)

## Confidence

| Question | Score |
|----------|-------|
| Q1: Well-defined? | 0.95 |
| Q2: Context supports execution? | 0.95 |
| Q3: Within capabilities? | 1.0 |
| **Composite** | **0.95** |

## Security: NONE

## Codebase Context

### Item 1 Affected Files

| File | Bare refs | Lines |
|------|-----------|-------|
| `skills/onboard/SKILL.md` | 6 | 68, 70, 72, 75, 76, 108 |
| `skills/scaffold/SKILL.md` | 4 | 93, 169, 484, 543 |
| `skills/init/SKILL.md` | 1 | 36 |
| `core/mcp-detection.md` | 1 | 19 |

Reference pattern: `skills/check-setup/SKILL.md` lines 32-38

### Item 2 Affected Files

`core/mcp-detection.md` (contract), `skills/check-setup/SKILL.md` (caller), `skills/init/SKILL.md` (caller)

### Item 3 Affected Files

`skills/check-setup/SKILL.md` Step 10
