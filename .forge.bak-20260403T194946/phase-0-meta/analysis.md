# Phase 0 — Task Analysis

## Task Type Classification

**Type:** bugfix

Two bugs in the `implement-feature` skill:
1. **Subtask persistence failure:** Architect decomposes into subtasks, but the task tree is never written to `.claude/decomposition/{ISSUE-ID}.yaml` or persisted to `state.json` `decomposition.subtasks`. The skill text says "Save task tree" at Step 5 but the execution flow may not reach it or the instruction is insufficiently explicit compared to `fix-ticket`.
2. **Confirmation flow disorder:** The skill asks for user confirmations at points that break autonomous execution. When `--yolo` is set, some confirmations may still fire. When `--yolo` is NOT set, confirmations may fire at wrong pipeline stages or be missing where needed.

## Complexity Assessment

| Dimension | Score | Rationale |
|-----------|-------|-----------|
| Scope | 2 | Changes confined to 1 skill file (`skills/implement-feature/SKILL.md`) and potentially `core/decomposition-heuristics.md`. No code, only markdown. |
| Ambiguity | 2 | The "correct" behavior is well-documented in `fix-ticket` and the architecture docs. The expected persistence path (`.claude/decomposition/`) is clear. Confirmation points are specified (Step 0c, Step 5, Step 9). |
| Risk | 2 | Pure markdown plugin — no runtime risk. The fix affects a skill definition used by Claude Code, but breakage is caught by the test suite. |
| **Composite** | **2** | max(2, 2, 2) = 2 |

## Domain Identification

**Primary domain:** Claude Code plugin authoring (markdown-based agent/skill orchestration definitions)
**Secondary domain:** Pipeline orchestration design, state management patterns

## Codebase Context Assessment

This is a pure-markdown Claude Code plugin with no build system or runtime code. The repository contains 19 agent definitions, 26 skills, and 11 core pattern contracts. All files are markdown with optional YAML frontmatter.

Key files for this bug:
- `skills/implement-feature/SKILL.md` (418 lines) — the primary file to fix
- `skills/fix-ticket/SKILL.md` (393 lines) — reference implementation with correct decomposition handling
- `core/decomposition-heuristics.md` — shared decomposition decision logic
- `state/schema.md` — state persistence schema
- `agents/architect.md` — architect agent that produces task trees

The decomposition flow in `fix-ticket` is the canonical reference. It explicitly saves the task tree to `.claude/decomposition/{ISSUE-ID}.yaml` (line 171), updates `state.json` decomposition fields, and has clear YOLO/non-YOLO branching for confirmations.

The `implement-feature` skill's Step 5 mentions "Save task tree" and writing to `.claude/decomposition/{ISSUE-ID}.yaml` (line 235), and Step 6h mentions updating the task tree state on disk (line 322). The issue is likely that:
1. The save instruction at Step 5 may lack sufficient detail compared to fix-ticket
2. The state.json writes for `decomposition.subtasks` may be incomplete
3. The confirmation flow has misplaced user prompts that interrupt autonomous operation

## Confidence Scoring

| Question | Score | Rationale |
|----------|-------|-----------|
| Do I understand the scope of changes? | 5 | Clear: fix SKILL.md to match fix-ticket patterns for persistence and review confirmation points. |
| Do I understand the success criteria? | 5 | Subtasks must be persisted to `.claude/decomposition/` and state.json. Confirmations must only fire where specified (Step 0c card creation, Step 5 decomposition plan, Step 9 PR creation) and respect --yolo. |
| Do I understand the codebase conventions? | 5 | Extensively documented in CLAUDE.md and visible from comparing fix-ticket with implement-feature. |
| **Composite** | **5** | min(5, 5, 5) = 5 |

## Fast-Track Eligibility Assessment

| Criterion | Value | Eligible? |
|-----------|-------|-----------|
| Composite complexity | 2 | Yes (<=2) |
| Composite confidence | 5 | Yes (>=4) |
| Single file change | ~1-2 files | Yes |
| Security implications | None | Yes |

**Security evaluation:** No security implications. This is a markdown definition change in a plugin. No secrets, no authentication, no network access patterns affected.

**Fast-Track Decision:** ELIGIBLE

```json
{
  "routing": {
    "task_type": "bugfix",
    "complexity_composite": 2,
    "confidence_composite": 5,
    "fast_track_eligible": true,
    "fast_track_approved": true,
    "recommended_phases": [1, 6, 7, 8, 9],
    "skip_phases": [2, 3, 4, 5],
    "reasoning": "Low complexity bugfix with clear reference implementation. Research (Phase 1) identifies exact delta between fix-ticket and implement-feature. Phases 2-5 (brainstorm, spec, TDD, plan) unnecessary — the fix is well-scoped comparison and alignment. Execute (Phase 6) applies the fix. Verify (Phase 7-8) confirms correctness. Phase 9 completes."
  }
}
```

## JIT Recommendation

```json
{
  "jit": {
    "enabled": false,
    "reasoning": "Fast-track path with skipped phases. No benefit from JIT gating — all necessary phases will execute."
  }
}
```

## Replanning Recommendation

```json
{
  "replanning": {
    "enabled": false,
    "reasoning": "Scope is fixed and well-understood. No discovery risk that would require mid-pipeline replanning."
  }
}
```

## Verification Weight Recommendation

```json
{
  "verification": {
    "dimension_weights": {
      "correctness": 0.40,
      "completeness": 0.30,
      "consistency": 0.20,
      "security": 0.00,
      "performance": 0.00,
      "maintainability": 0.10
    },
    "reasoning": "Primary concern is correctness (does the persistence work?) and completeness (all confirmation points handled?). Consistency matters because implement-feature should match fix-ticket patterns. No security or performance dimensions apply to markdown definitions."
  }
}
```
