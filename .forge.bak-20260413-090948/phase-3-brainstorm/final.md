# Phase 3 — Brainstorm Synthesis

## Consensus Points (all 3 personas agree)

### 1. TWO-WAY branch, not three
Both the innovative and skeptical personas independently concluded that scaffold and feature modes are IDENTICAL at the agent level. All 5 differences (no tracker, hooks suppressed, different build source, different commit strategy, different rollback context) are skill-level concerns, not agent-level.

**Decision:** Two-way branch: `bug-fix` (default) vs `guided-implementation` (feature + scaffold).

### 2. Mode name: `guided-implementation`
Innovative persona proposed this name because it describes the input contract (spec-guided subtask implementation) without creating false distinctions. Both feature and scaffold pipelines inject the same mode signal.

### 3. Fixer TDD RED phase needs HARD override
Both conservative and innovative personas flagged that the bug-fix RED phase instruction ("if test passes, rewrite it") will actively sabotage feature mode. Must be a hard override, not a suggestion.

### 4. smoke-check rollback is a genuine gap — add it
All three agree, with skeptical persona noting a pre-existing decomposition-mode side effect (out of scope for this refactoring — track separately).

### 5. Default-first conditional pattern
Conservative persona mandates: each conditional must use exact existing bug-fix text in the default branch. Feature-mode text is the additive branch.

## Divergence Points

### NEEDS_DECOMPOSITION handler approach
- **Conservative:** Model after fix-ticket handler
- **Skeptical:** Always-Block in both modes (simplest, safest)
- **Innovative:** Not specifically addressed

**Resolution:** Always-Block is the safer choice and consistent with the constraint that implement-feature already decomposed via architect. In single-pass mode, signal is informational (Block + comment). In decomposition mode, signal means subtask is too large (Block + comment, move on).

## Final Pattern Recommendation

**Approach A-modified (Two-way Inline Conditional):**

### Mode signal injection
Skills inject `Mode: bug-fix` or `Mode: guided-implementation` as a prefix in the context string. Absence of Mode prefix = bug-fix mode (backward compatibility).

### Agent Step 1 pattern template
```markdown
**Mode detection:** If the provided context includes `Mode: guided-implementation`, this is a feature implementation or scaffold task:
- Read the specification/architectural design as the primary input (instead of triage analysis/bug report)
- Read the subtask scope as the work boundary (instead of impact report)
- Acceptance criteria come from the specification (instead of triage)

If no Mode prefix is present, or Mode is `bug-fix`, proceed with the standard bug-fix workflow below.
```

### Per-agent change scope
| Agent | Steps changed | Nature of change |
|-------|------|------|
| fixer | Step 1 (input), Step 5 (TDD RED phase) | Mode detection + TDD override |
| reviewer | Step 1 (input), Step 2 (checklist) | Mode detection + feature checklist |
| test-engineer | Step 1 (input), Step 3 (test framing) | Mode detection + AC framing |
| e2e-test-engineer | Step 1 (input), Goal | Mode detection + goal broadening |
| rollback-agent | Step 1 (trigger allowlist) | Add smoke-check |

### Core contract changes
| File | Change |
|------|------|
| fixer-reviewer-loop.md | Input Contract → discriminated union |
| block-handler.md | Add smoke-check to rollback trigger list |
| decomposition-heuristics.md | Add scope annotation for feature mode |

### Skill changes
| File | Change |
|------|------|
| implement-feature/SKILL.md | Mode prefix + NEEDS_DECOMPOSITION handler (always-Block) |

### Schema changes
| File | Change |
|------|------|
| state/schema.md | Add ac_source field |

## Risk Register

| # | Risk | Severity | Mitigation |
|---|------|----------|-----------|
| 1 | NEEDS_DECOMPOSITION in decomposition mode — what happens to partial commits? | MEDIUM | Always-Block + document as known limitation |
| 2 | Rollback after smoke-check may destroy prior subtask commits in decomposition mode | LOW | Out of scope — track as separate issue |
| 3 | Conditional complexity creep if 4th mode emerges | LOW | Two-way branch is resilient; sub-mode pattern available |
| 4 | LLM misinterpreting branching in agent definitions | LOW | Default-first pattern minimizes confusion |
