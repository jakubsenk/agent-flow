# Phase 3: Brainstorm Synthesis — Final Recommendation

## Comparison Matrix

| Dimension | Conservative (A) | Innovative (B) | Skeptical (C) |
|-----------|-------------------|-----------------|---------------|
| **New scenarios** | 12 | 12 | 12 |
| **Naming** | structural-*, pipeline-*, contract-*, feature-* | t2-*, t3-*, t4-* tier prefix | xref-*, pipeline-*, config-* |
| **Core philosophy** | Incremental, proven patterns | Cross-reference graph, dynamic | ROI-focused, anti-hardcoding |
| **Hardcoded lists** | Replace with dynamic + count guards | Eliminate via graph traversal | Eliminate via source-of-truth derivation |
| **Mock project** | Expand existing mock +5 sections | Keep + add fixtures | No mock expansion, add fixtures |
| **Test helpers** | Shared helpers library | Graph builder abstraction | None — self-contained scripts |
| **False positive risk** | Low (conservative assertions) | Medium (complex parsing) | Low (simple, focused assertions) |
| **Maintenance cost** | Medium (helpers need maintenance) | High (graph builder) | Low (each test independent) |
| **Coverage breadth** | High (all 10 areas) | Very high (automated coverage) | Targeted (skip low-ROI tests) |
| **Execution speed** | < 10s total | < 15s (graph build) | < 6s total |
| **Catches real bugs** | Yes (all 6 confirmed) | Yes (all 6 + future) | Yes (focused on actual bug classes) |
| **"Not worth testing" list** | None | None | 8 tests explicitly excluded |

## Divergence Assessment

```json
{
  "divergence_class": "ALIGNED",
  "original_keywords": ["e2e", "pipeline", "validation", "structural", "bash", "test", "harness"],
  "recommended_keywords": ["e2e", "pipeline", "validation", "structural", "bash", "cross-reference", "dynamic", "contract"],
  "keyword_overlap_score": 0.78
}
```

All three personas converge on the same fundamental insight: **the #1 problem is hardcoded lists**, and the solution is **dynamic derivation from authoritative sources**. They diverge on test infrastructure complexity and what to exclude.

## Synthesized Recommendation

**Take the Skeptical Strategist's (C) philosophy with Conservative Architect's (A) specificity.**

### Design Principles (from C)
1. **Zero hardcoded lists** — derive all counts and names from filesystem + CLAUDE.md
2. **One scenario = one failure mode** — no multi-purpose tests
3. **Self-contained scripts** — no shared helpers, no test framework
4. **Explicit "not worth testing" decisions** — don't test documentation quality as proxy for correctness

### Scenario Selection (12 new tests, synthesized from all 3 proposals)

| # | Name | Source | Priority | What it catches |
|---|------|--------|----------|-----------------|
| 1 | `xref-agent-registry.sh` | C-1, B-T2 | P1 | Agent files ↔ CLAUDE.md model table sync |
| 2 | `xref-core-registry.sh` | C-2, B-T2 | P1 | Core files ↔ CLAUDE.md + commands references |
| 3 | `xref-command-count.sh` | C-3 | P1 | File counts ↔ CLAUDE.md claims |
| 4 | `pipeline-feature-step-order.sh` | C-4, B-T3 | P1 | implement-feature step ordering |
| 5 | `pipeline-deploy-verifier.sh` | C-5, A | P1 | deployment-verifier + check-deploy structural completeness |
| 6 | `pipeline-agent-dispatch-models.sh` | C-6, B-T2 | P1 | Model tier at dispatch site ↔ agent frontmatter |
| 7 | `pipeline-feature-agents.sh` | C-11, A | P2 | implement-feature dispatches all required agents |
| 8 | `pipeline-state-writes.sh` | C-7, A-5 | P2 | Each pipeline phase has state.json write |
| 9 | `xref-skip-stage-names.sh` | C-12, A | P2 | Skippable stage names consistent across docs |
| 10 | `config-required-keys.sh` | C-8 | P3 | Required config keys consumed by commands |
| 11 | `config-reader-sections.sh` | C-10, A-7 | P3 | config-reader ↔ CLAUDE.md optional sections |
| 12 | `pipeline-hook-order.sh` | A-12 | P3 | Hook execution order in pipeline commands |

### Bug Fixes (to include in same delivery)
1. Update frontmatter-completeness.sh, model-assignment.sh, section-order.sh — add deployment-verifier (RQ-01)
2. Update core-include-refs.sh — add mcp-detection.md (RQ-02)
3. Update CLAUDE.md — clarify acceptance gate condition for feature pipeline (RQ-03)
4. Update config-reader.md — add root_cause_iterations (RQ-04)
5. Add ceos-agents: prefix to rollback-agent in implement-feature.md (RQ-23)

### Mock Project Strategy
- **Do NOT expand** the mock project — existing `tests/mock-project/CLAUDE.md` is for illustration, not test fixture
- **Existing fixtures stay** — no new fixtures needed, tests derive expectations from CLAUDE.md
- Tests that validate config contract use CLAUDE.md as source of truth, not mock project

### Tests Explicitly NOT Added (from C, validated by A)
1. State.json field-level schema validation — tests documentation, not behavior
2. Agent description length/format — style policing
3. CHANGELOG consistency — release process concern
4. Duplicate content between commands — intentional by design
5. Agent Process step numbering — too many format variants
6. PR Description Template placeholders — project-specific content
7. Workflow-router intent coverage — cosmetic severity
8. Comprehensive hook validation — hooks are optional, order is trivially correct

### Naming Convention
- `xref-` prefix: cross-reference integrity tests
- `pipeline-` prefix: pipeline flow and dispatch tests
- `config-` prefix: config contract tests
- Existing tests: keep current names (no rename)

### Expected Outcome
- Total scenarios: 25 existing + 12 new = **37 scenarios**
- Estimated new code: ~600 lines of bash
- Execution time: < 15 seconds total suite
- All 6 confirmed bugs caught
- Feature pipeline: 0 → 3 dedicated tests
- Deployment: 0 → 1 dedicated test
- Cross-reference: 0 → 4 dedicated tests
