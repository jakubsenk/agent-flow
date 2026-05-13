Comprehensive audit and implementation of improvements for all 3 pipeline modes in the ceos-agents plugin.

PHASE A — AUDIT:
1. For each pipeline skill (fix-ticket, implement-feature, scaffold): map which agents it dispatches, in what order, with what context. Assess whether the RIGHT agents are used (missing any? unnecessary any?).
2. For each shared agent (fixer, reviewer, test-engineer, e2e-test-engineer, rollback-agent): assess content quality for EACH mode it's called from. Best practices — what's good, what's missing, what's wrong.
3. For core contracts (fixer-reviewer-loop, block-handler, decomposition-heuristics): do they reflect the reality of 3 modes?
4. State schema — does it support all 3 modes properly?

PHASE B — IMPLEMENTATION:
Based on audit findings, implement ALL recommended changes: modify agent content, add/remove agents, update skills, update core contracts, update state schema. Every change must have a WHY.

PHASE C — VERIFICATION:
Run test harness, verify backward compatibility of all 3 pipelines.
