# Phase 0 — Task Analysis

## Task Classification

| Dimension | Value | Rationale |
|-----------|-------|-----------|
| **Type** | feature | Adding two new capabilities to the scaffolder agent |
| **Domain** | markdown plugin definitions | Pure markdown agent definition edits — no code, no build system |
| **Primary file** | `agents/scaffolder.md` | Both features modify this file |
| **Secondary files** | `skills/scaffold/SKILL.md`, `CHANGELOG.md`, `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, `docs/plans/roadmap.md` | Skill may need Module Docs path population; version bump + changelog needed |
| **Breaking change** | No | Additive features only — new optional batch + new optional scorecard item |
| **Version bump** | MINOR (6.2.0 → 6.3.0) | New backward-compatible features |

## Complexity Assessment

| Factor | Score (1-5) | Rationale |
|--------|-------------|-----------|
| **Scope** | 2 | 2 features in 1 primary file + minor touches to 4-5 secondary files |
| **Ambiguity** | 2 | Well-specified in roadmap with clear requirements and design |
| **Risk** | 1 | No breaking changes, no side effects, additive markdown-only edits |
| **Composite** | **2** | avg(2, 2, 1) rounded = 2 |

## Confidence

**Overall confidence: 0.95**

Rationale:
- Task is explicitly described in `docs/plans/roadmap.md` with file targets and design details
- Both roadmap items specify the exact agent file (`agents/scaffolder.md`)
- The existing batch pattern (Batch 1-6) provides a clear extension point
- The scorecard pattern (9 existing items) provides a clear extension point
- `Module Docs | Path` config key is already documented in CLAUDE.md
- No ambiguity about what needs to change

## Fast-Track Assessment

### Eligibility Check

| Criterion | Value | Threshold | Met? |
|-----------|-------|-----------|------|
| Composite complexity | 2 | ≤ 2 | YES |
| Confidence | 0.95 | ≥ 0.9 | YES |
| Task type | feature | feature/bugfix/refactor | YES |

**Fast-track eligible: YES**

### Security Evaluation (Tier A — Mandatory)

| Check | Result | Detail |
|-------|--------|--------|
| S-A1: Destructive operations | PASS | No file deletions, no git force operations, no database changes |
| S-A2: Credential / secret exposure | PASS | No secrets, no tokens, no API keys — pure markdown edits |
| S-A3: External side-effects | PASS | No network calls, no API calls, no file system changes outside repo |
| S-A4: Permission escalation | PASS | No permission changes, no sudo, no config file modifications that affect access |

### Security Evaluation (Tier B — Contextual)

| Check | Result | Detail |
|-------|--------|--------|
| S-B1: Supply chain risk | PASS | No dependencies added or modified |
| S-B2: Data exfiltration vectors | PASS | No data read from external sources |
| S-B3: Persistent state changes | PASS | No state files modified (only agent definitions and docs) |
| S-B4: Rollback complexity | PASS | All changes are additive markdown — trivial to revert |

**Security verdict: ALL PASS — no security concerns**

### Fast-Track Decision

**FAST-TRACK APPROVED**

Rationale: Composite complexity 2 (meets ≤2 threshold), confidence 0.95 (meets ≥0.9 threshold), all 8 security checks pass. This is a well-defined, additive-only, markdown-only feature addition with zero risk of side effects.

## Routing Decision

| Criterion | Value |
|-----------|-------|
| **Template match** | None — custom task |
| **Phase subset** | Phases 1, 2, 3, 4, 5 (adapted), 6, 7, 8, 9 |
| **Skippable phases** | Phase 5 (TDD) is adapted — no runtime code to test, but structural tests exist |
| **JIT recommendation** | jit.enabled: false (composite ≤ 2, no phase needs lazy loading) |
| **Replanning likelihood** | Low — well-specified task with clear requirements |

## Key Research Questions for Phase 1

1. What is the exact current structure of `agents/scaffolder.md` — batch numbering, scorecard items, constraints?
2. How does `skills/scaffold/SKILL.md` reference the scaffolder agent — what context does it pass?
3. Where is `Module Docs | Path` consumed — which agents read it and how?
4. What is the exact pattern for conditional batches (Batch 6 is the model)?
5. How do existing tests validate the scaffolder — what test patterns should new tests follow?
6. What is the current file count target — does adding e2e files + docs change it?
