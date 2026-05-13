# Phase 0: Task Analysis

## Task Type
**BUGFIX** — composite fix addressing 5 distinct issues in a markdown-only plugin (pure prompt engineering, no runtime code).

## Complexity Assessment

| Dimension | Score | Rationale |
|-----------|-------|-----------|
| Scope | 3 | Multiple files across agents, skills, and docs. At least 3-4 files need edits. |
| Ambiguity | 2 | Issues are well-defined from real-world feedback. Root causes identified during pre-analysis. |
| Risk | 2 | No breaking API changes. All fixes are behavioral/prompt improvements within existing contract. |
| **Composite** | **2.3** | Moderate complexity — straightforward once root causes are confirmed. |

## Confidence
**0.90** — High confidence. All 5 issues have clear root causes identified in pre-analysis. The only uncertainty is Issue 1 (design quality) where the fix is more of an enhancement than a bug.

## Domain
Prompt engineering for LLM agent definitions (markdown). Issue tracker integration logic. Pipeline orchestration.

## Routing Decision
**Standard pipeline** — no phases should be skipped. Research phase is lightweight (mostly confirming pre-analysis). Brainstorm is minimal. Spec is straightforward. Plan decomposes into 5 independent tasks.

## Codebase Context

### Files to Modify

| File | Issue(s) | Change Type |
|------|----------|-------------|
| `skills/scaffold/SKILL.md` | #2, #3, #4 | Fix Step 4e parent parameter enforcement, fix Step 8b cascade assumption, add Step 8a implementation comments |
| `agents/scaffolder.md` | #1 | Add UI/design quality instructions for web project scaffolds |
| `agents/spec-writer.md` | #1, #5 | Add design system requirement for web projects, add language fidelity constraint |
| `docs/reference/trackers.md` | #2 | Clarify parent parameter usage instructions (informational, may not need change) |

### Root Cause Analysis

1. **Design quality**: Scaffolder goal is "minimal, buildable skeleton" with zero design instructions. Spec-writer has no design system or UI quality section. Web projects get no CSS framework or design tokens.
2. **Story linking**: Step 4e instruction says "create sub-issue with parent set to epic issue ID using the tracker's native parent parameter" — but the LLM executing this is not given enough explicit detail about HOW to pass the parent parameter via MCP tool call. The instruction is too implicit.
3. **Story closing**: Step 8b line 743 explicitly says "closing the parent epic typically cascades to children. Do NOT explicitly close story sub-issues." This is factually wrong for YouTrack (and most trackers). YouTrack does NOT auto-cascade close.
4. **No comments**: The scaffold pipeline has no step between 4e (create issues) and 8b (close issues) that posts implementation progress or results as comments on tracker issues.
5. **Czech without diacritics**: No agent or skill has any language fidelity instruction. When user input is in Czech, agents may respond in Czech but LLMs (especially sonnet) sometimes drop diacritics.

### Files NOT to Modify
- `agents/architect.md` — not involved in any of these issues
- `agents/fixer.md` — not involved
- `agents/publisher.md` — not involved
- `core/*.md` — no core contract changes needed
