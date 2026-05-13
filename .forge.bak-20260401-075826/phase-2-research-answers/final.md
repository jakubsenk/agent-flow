# Phase 2: Research Answers — Synthesized Final

## Executive Summary

31 research questions investigated. **6 confirmed bugs**, **12 confirmed gaps**, **1 needs clarification**, **12 intentional/documented**.

---

## Confirmed Bugs (require code fixes alongside test additions)

| ID | Bug | Severity | Fix |
|----|-----|----------|-----|
| RQ-01 | frontmatter-completeness.sh, model-assignment.sh, section-order.sh hardcode 18 agents — missing deployment-verifier | Medium | Add deployment-verifier to all 3 test arrays |
| RQ-02 | core-include-refs.sh CORE_FILES array has 10 files — missing mcp-detection.md (11th core contract) | Medium | Add mcp-detection to CORE_FILES array |
| RQ-03 | CLAUDE.md says acceptance gate "always" for features; implement-feature.md skips it in single-pass | High | Align documentation — update CLAUDE.md to say "always in decomposition mode" |
| RQ-04 | config-reader.md omits retry.root_cause_iterations despite CLAUDE.md documenting it | Medium | Add root_cause_iterations to config-reader output |
| RQ-06 | fix-bugs.md has no Config Validity Gate (Step 0b) unlike fix-ticket and implement-feature | Medium | Intentional per design (fix-bugs processes N issues, validation per-issue) — document this |
| RQ-23 | implement-feature.md rollback-agent missing ceos-agents: namespace prefix | Low | Add prefix for consistency |

## Confirmed Gaps (tests needed, no code fix required)

| ID | Gap | Test Priority |
|----|-----|---------------|
| RQ-05 | triage.* state field reuse for spec-analyst undocumented in schema | P2 |
| RQ-07 | fixer-reviewer-loop.md reference placement inconsistent in fix-ticket.md | P3 |
| RQ-08 | Block handler no-rollback rule doesn't list spec-analyst/architect as exempt | P2 |
| RQ-09 | Bug pipelines never write decomposition.* state fields | P2 |
| RQ-10 | decomposition-heuristics Input Contract expects code_analyst_output (bug-only) | P3 |
| RQ-11 | Port validation duplicated in check-deploy + deployment-verifier | P3 |
| RQ-12 | Profile-parser doesn't filter stages by pipeline type | P3 |
| RQ-13 | state-schema.sh only does count-based checks, no specific field validation | P1 |
| RQ-14 | Config Validity Gate (Step 0b) zero test coverage | P1 |
| RQ-15 | --yolo flag zero test coverage | P2 |
| RQ-16 | implement-feature zero dedicated tests | P1 |
| RQ-17 | deployment-verifier + check-deploy zero test coverage | P1 |

## Intentional/Documented (no action needed)

RQ-18 (mock project minimal by design), RQ-19 (defaults acceptable), RQ-20 (verify null handled), RQ-22 (fallback documented), RQ-25 (not_applicable reserved), RQ-26 (mode enum correct), RQ-27 (50-char documented), RQ-28 (.claude/decomposition path consistent), RQ-29 (profile warning low priority), RQ-30 (hook order correct), RQ-31 (AC chain traceable).

## Needs Clarification

- RQ-21: PR Description Template backtick handling unspecified in config-reader — not a bug, but ambiguous spec.
- RQ-24: Secret redaction docker-only — may be intentional scope decision.

---

## Test Strategy Implications

### Must-Have Tests (P1)
1. **Agent count and completeness** — dynamic discovery, not hardcoded lists
2. **Core file completeness** — all 11 core files validated
3. **Feature pipeline dedicated tests** — spec-analyst, architect, decomposition, AC flow
4. **Deployment verifier coverage** — frontmatter, model, verdict set, port validation
5. **State field specificity** — validate actual field names, not just reference counts
6. **Config Validity Gate** — TODO detection, required section validation

### Should-Have Tests (P2)
7. **State field reuse documentation** — triage.* dual-use in feature pipeline
8. **Decomposition state writes** — verify presence in all pipelines that decompose
9. **Block handler rollback scope** — verify exempt agent list completeness
10. **--yolo flag** — validate auto-approve and auto-publish behavior markers

### Nice-to-Have Tests (P3)
11. **Cross-reference consistency** — fixer-reviewer-loop placement
12. **Port validation deduplication** — check-deploy vs deployment-verifier
13. **Profile-parser pipeline awareness** — stage filtering by pipeline type
14. **Decomposition-heuristics input contract** — feature vs bug inputs

---

## Bugs to Fix Before Test Implementation

These 6 bugs should be fixed as part of this feature, not separately:
1. Update 3 test files to include deployment-verifier (RQ-01)
2. Update core-include-refs.sh to include mcp-detection.md (RQ-02)
3. Update CLAUDE.md Feature Pipeline description for acceptance gate (RQ-03)
4. Add root_cause_iterations to config-reader.md (RQ-04)
5. Document fix-bugs.md Step 0b absence as intentional (RQ-06)
6. Add ceos-agents: prefix to rollback-agent in implement-feature.md (RQ-23)
