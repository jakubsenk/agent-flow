# Phase 1 — Research Synthesis: Comprehensive 3-Pipeline Audit

## Executive Summary

19 agents, 4 pipeline skills, 11 core contracts, 1 state schema audited. Overall quality is high (13/19 agents score 5/5). However, the shared agents were designed for bug-fix mode and have significant gaps when serving feature and scaffold pipelines.

## Audit Findings by Severity

### CRITICAL (1 finding)
| # | Agent/File | Issue | Impact |
|---|-----------|-------|--------|
| C1 | agents/fixer.md | Step 1 guard checks for "triage analysis or impact report" — BLOCKS in feature/scaffold mode where these don't exist | Feature/scaffold pipelines cannot use fixer without skill-level workaround |

### HIGH (7 findings)
| # | Agent/File | Issue |
|---|-----------|-------|
| H1 | agents/fixer.md | Step 5 TDD RED phase says "reproduce the bug" — semantically wrong for feature/scaffold |
| H2 | agents/reviewer.md | Step 1 reads "bug report, triage analysis, impact report" — none exist in feature/scaffold |
| H3 | agents/reviewer.md | Step 2 checklist includes "Root cause" — bug-specific concept |
| H4 | agents/test-engineer.md | Step 1 reads "bug report" + Step 3 frames test as "regression test" — wrong for new features |
| H5 | agents/publisher.md | PR title hardcodes "Fix:", commit uses fix() prefix, PR template has "Root Cause" — all bug-specific |
| H6 | core/decomposition-heuristics.md | Designed for code-analyst inputs but invoked in feature mode with different inputs |
| H7 | implement-feature single-pass skips acceptance-gate — less validation than decomposed mode |

### MEDIUM (8 findings)
| # | Agent/File | Issue |
|---|-----------|-------|
| M1 | agents/e2e-test-engineer.md | Step 1 reads "bug report" (minor, one-word fix) |
| M2 | core/block-handler.md | implement-feature inlines the block protocol instead of referencing core contract |
| M3 | state/schema.md | triage.* reused for spec-analyst, code_analysis.* for architect — semantically confusing |
| M4 | state/schema.md | Scaffold has no dedicated state sections (no spec_writer, scaffolder, spec_review) |
| M5 | core/config-reader.md | Missing create_tracker_subtasks key in Decomposition parsing (silent misconfiguration bug) |
| M6 | agents/scaffolder.md | Duplicate step numbering (two "4"s) + stray "(if S3 implemented)" artifact |
| M7 | agents/test-engineer.md | Description says "verifying the fix" — bug-centric |
| M8 | fix-ticket/fix-bugs | ~200 lines duplicated NEEDS_DECOMPOSITION + tracker subtask code |

### LOW (4 findings)
| # | Agent/File | Issue |
|---|-----------|-------|
| L1 | core/profile-parser.md | Vestigial pipeline_name input parameter never used |
| L2 | agents/priority-engine.md | "scores may vary between runs" undercuts auditability |
| L3 | spec-reviewer agent | Used in 3 incompatible roles in scaffold (spec review, iteration, compliance) |
| L4 | No NEEDS_DECOMPOSITION handler in implement-feature — intentional (architect does decomposition upfront) but undocumented |

## Agent Dispatch Cross-Reference Matrix

| Agent | fix-ticket | fix-bugs | implement-feature | scaffold |
|-------|-----------|---------|-------------------|----------|
| triage-analyst | Yes | Yes | — | — |
| code-analyst | Yes | Yes | — | — |
| spec-analyst | — | — | Yes | — |
| architect | Conditional | Conditional | Yes | Yes |
| spec-writer | — | — | — | Yes |
| spec-reviewer | — | — | — | Yes (×3 roles) |
| stack-selector | — | — | — | Conditional |
| scaffolder | — | — | — | Yes |
| **fixer** | **Yes** | **Yes** | **Yes** | **Yes** |
| **reviewer** | **Yes** | **Yes** | **Yes** | **Yes** |
| **test-engineer** | **Yes** | **Yes** | **Yes** | **Yes** |
| **e2e-test-engineer** | **Cond** | **Cond** | **Cond** | **Cond** |
| **rollback-agent** | — | Yes | Yes | Yes |
| **publisher** | **Yes** | **Yes** | **Yes** | — |
| acceptance-gate | Cond | Cond | Cond | — |
| reproducer | Cond | Cond | — | — |
| browser-verifier | Cond | Cond | — | — |
| deployment-verifier | Cond | Cond | Cond | Cond |
| priority-engine | — | — | — | — (standalone) |

## Agent Content Quality Scorecard

| Agent | Goal | Process | Constraints | Overall | Mode Status | Top Issue |
|-------|------|---------|-------------|---------|-------------|-----------|
| fixer | 4 | 4 | 5 | 4 | BROKEN | Step 1 blocks in non-bug mode |
| reviewer | 4 | 4 | 5 | 4 | NEEDS_UPDATE | Bug-specific input reading + checklist |
| test-engineer | 4 | 4 | 5 | 4 | NEEDS_UPDATE | Bug-centric Step 1 + Step 3 framing |
| e2e-test-engineer | 5 | 5 | 5 | 5 | NEEDS_UPDATE | Minor: "bug report" in Step 1 |
| publisher | 4 | 4 | 5 | 4 | NEEDS_UPDATE | "Fix:" prefix, "Root Cause" in PR template |
| rollback-agent | 5 | 5 | 5 | 5 | GOOD | — |
| acceptance-gate | 5 | 5 | 5 | 5 | GOOD | Exemplary mode-awareness |
| triage-analyst | 5 | 5 | 5 | 5 | GOOD | — |
| code-analyst | 5 | 5 | 5 | 5 | GOOD | — |
| spec-analyst | 5 | 5 | 5 | 5 | GOOD | — |
| architect | 5 | 5 | 5 | 5 | GOOD | — |
| spec-writer | 5 | 5 | 5 | 5 | GOOD | — |
| spec-reviewer | 4 | 5 | 5 | 4 | GOOD | 3 roles in scaffold (design concern) |
| stack-selector | 5 | 5 | 5 | 5 | GOOD | — |
| scaffolder | 4 | 4 | 5 | 4 | NEEDS_UPDATE | Duplicate step numbering |
| reproducer | 5 | 5 | 5 | 5 | GOOD | — |
| browser-verifier | 5 | 5 | 5 | 5 | GOOD | — |
| deployment-verifier | 5 | 5 | 5 | 5 | GOOD | — |
| priority-engine | 4 | 5 | 4 | 4 | GOOD | Auditability caveat |

## Core Contract Assessment

| Contract | Status | Issue |
|----------|--------|-------|
| fixer-reviewer-loop | NEEDS_UPDATE | Input contract assumes code-analyst output only |
| block-handler | NEEDS_UPDATE | Not referenced by implement-feature (inlined) |
| decomposition-heuristics | NEEDS_UPDATE | Scope annotation missing for feature mode |
| config-reader | NEEDS_UPDATE | Missing create_tracker_subtasks key |
| state-manager | GOOD | — |
| agent-override-injector | GOOD | — |
| mcp-preflight | GOOD | — |
| mcp-detection | GOOD | — |
| profile-parser | GOOD | Vestigial param (minor) |
| post-publish-hook | GOOD | — |
| fix-verification | GOOD | — |

## State Schema Assessment

| Area | Status | Issue |
|------|--------|-------|
| triage.* | NEEDS_UPDATE | Reused for spec-analyst — needs ac_source field |
| code_analysis.* | NEEDS_UPDATE | Reused for architect — semantically confusing |
| scaffold-specific | MISSING | No dedicated sections for spec_writer, scaffolder, spec_review |
| step_status_enum | GOOD | Consistent |
| deployment.* | GOOD | — |

## Recommendations for Phase 3 Brainstorm

1. **Shared agent mode-awareness:** Add mode-detection to Step 1 of fixer, reviewer, test-engineer, e2e-test-engineer, publisher. Use existing acceptance-gate pattern as reference.
2. **Publisher multi-mode:** Change PR title/commit generation to be mode-aware (Fix/Feature/Scaffold).
3. **Core contract alignment:** Update fixer-reviewer-loop input contract, add feature/scaffold scope to decomposition-heuristics, fix config-reader parsing bug.
4. **State schema:** Add ac_source field, consider scaffold-specific sections.
5. **Content quality fixes:** Fix scaffolder duplicate steps, update bug-centric descriptions.
6. **Document design decisions:** NEEDS_DECOMPOSITION absence in implement-feature, spec-reviewer triple-role in scaffold.
