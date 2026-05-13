# v8.0.0 Phase 6 Implementation Plan

**Phase:** 6 (Planning) — output for Phase 7 Parallel Execution
**Datum:** 2026-04-27
**Authoritative inputs:**
- `.forge/phase-4-spec/final/requirements.md` (75 REQs incl. NF; 18 sub-sections)
- `.forge/phase-4-spec/final/formal-criteria.md` (94 ACs)
- `.forge/phase-4-spec/final/design.md` (TOML schema, agent rename mapping, mode-flag parsing pattern, doc map)
- `.forge/phase-5-tdd/tests/` (80 visible) + `.forge/phase-5-tdd/tests-hidden/` (12 hidden)
- `.forge/phase-5-tdd/coverage-report.md` (94/94 AC coverage map)

**Phase 6 Planning Architect:** Opus (this run)
**Worktree convention (Phase 7):** `.fw/task-{id}/`; revision cycles `.fw/task-{id}-r{cycle}/`

---

## 0. Executive Summary

- **Total tasks:** 33 (T-001 .. T-033)
- **Parallelization ratio:** 26 / 33 = **78.8 %** parallelizable (well above 50 % SUCCESS_CRITERIA threshold; 23/33 = 69.7 % if folded tasks T-012/T-013/T-014 excluded)
- **AC coverage:** 100 % (94 / 94 ACs mapped to ≥ 1 task; bidirectional traceability in Section 5 task-to-AC matrix)
- **Migration ordering decision:** **TOML overlay first, agent renames second** (rationale Section 2; resolves OQ-INT.1)
- **Critical-path estimate (sequential bottleneck):** ~6.0 h wall-clock
  - 7A infra (T-001 + T-002) sequential ≈ 1.5 h
  - 7H docs sequential (T-027 + T-028 + T-029) ≈ 2.0 h
  - 7I cross-file invariant (T-030) ≈ 0.5 h
  - 7J test integration (T-031..T-033) ≈ 1.0 h
  - Margin / wave-handoff overhead ≈ 1.0 h
- **Phase 7 wall-clock projection (parallel):** ~7-9 h (max 6 worktrees concurrent in waves 7B..7G)

**Wave layout:**

| Wave | Tasks | Max parallel | Wall-clock budget |
|------|-------|--------------|-------------------|
| 7A — Infrastructure (TOML parser + syntax doc) | T-001, T-002 | 2 | 0:45 (M) + 0:45 (M) sequential within wave: T-001 → T-002 |
| 7B — Agent consolidation | T-003, T-004, T-005, T-006 | 4 | 0:45 (M) max |
| 7C — SKILL.md decomposition | T-007, T-008, T-009 | 3 | 1:30 (L) max |
| 7D — `/setup-agents` skill + examples | T-010, T-011 | 2 | 0:45 (M) + 0:30 (S) |
| 7E — Mode-flag parsing in 3 entry SKILL.md | T-012, T-013, T-014 | 3 | 0:45 (M) max |
| 7F — State + status reader | T-015, T-016 | 2 | 0:45 (M) max |
| 7G — Documentation guides + reference + templates | T-017..T-026 | 10 | 1:30 (L) max |
| 7H — README/CLAUDE.md/CHANGELOG (sequential) | T-027 → T-028 → T-029 | 1 | 2:00 cumulative |
| 7I — Cross-File Invariant atomic | T-030 | 1 | 0:30 |
| 7J — Test integration | T-031, T-032, T-033 | 3 | 1:00 max |

---

## 1. Task Graph (DAG)

Each task is atomic (1–8 files). `parallelizable_with` lists tasks that touch DISJOINT `files_modified` sets. `depends_on` is the upstream blocker(s); empty = root. Format = YAML.

### Wave 7A — Infrastructure (sequential prerequisites)

```yaml
- task_id: T-001
  description: "Implement TOML overlay parser + 3-tier merge utility (skill-orchestrated, pure-bash with python3 tomllib fallback)"
  files_modified:
    - core/toml-overlay.md (NEW — contract + reference impl pseudocode)
    - skills/setup-agents/lib/toml-merge.sh (NEW — pure-bash + python3 fallback parser)
  files_read_only:
    - .forge/phase-4-spec/final/design.md
    - .forge/phase-4-spec/final/requirements.md
  depends_on: []
  acceptance_criteria_refs:
    - AC-OVR-001
    - AC-OVR-002
    - AC-OVR-003
    - AC-OVR-004
    - AC-OVR-005
    - AC-OVR-006
    - AC-OVR-007
    - AC-OVR-008
    - AC-NF-001
    - AC-NF-006
  test_files_pass:
    - tests/scenarios/v8-overlay-scalar-override.sh
    - tests/scenarios/v8-overlay-array-append.sh
    - tests/scenarios/v8-overlay-table-deepmerge.sh
    - tests/scenarios/v8-overlay-syntax-error.sh
    - tests/scenarios/v8-overlay-unknown-key.sh
    - tests/scenarios/v8-overlay-md-toml-coexist.sh
    - tests/scenarios/v8-overlay-md-legacy-only.sh
    - tests/scenarios/v8-overlay-provenance-log.sh
    - tests/scenarios-hidden/v8-hidden-toml-malformed-recovery.sh
    - tests/scenarios-hidden/v8-hidden-toml-quote-escape-edge.sh
    - tests/scenarios-hidden/v8-hidden-customization-md-and-toml-coexist.sh
  estimated_complexity: M
  parallelizable_with: []
  rollback_strategy: "Revert single commit; core/toml-overlay.md DELETE + skills/setup-agents/lib/toml-merge.sh DELETE. Legacy .md overlay path unaffected (REQ-OVR-006 fallback survives)."
  notes:
    - "REQ-NF-006 mandates parser-tooling neutrality. Implementation choice: pure-bash + python3 tomllib fallback (because plugin already targets POSIX bash + Python is available on GH Actions / dev hosts; avoids new external dep like taplo)."
    - "Implementation MUST follow design.md §5.1 explicit-boolean pattern parity (no last-wins parsing) — referenced by lint check T-030."
    - "REQ-OVR-007 provenance-log line MUST appear once per dispatch for ALL three branches (toml/md/none)."

- task_id: T-002
  description: "Author TOML overlay syntax guide (docs/guides/toml-overlay-syntax.md) — full per-agent overrideable key reference, 5+ TOML examples, [meta] free-form table semantics"
  files_modified:
    - docs/guides/toml-overlay-syntax.md (NEW)
  files_read_only:
    - .forge/phase-4-spec/final/design.md (Section 2 — per-agent reference table)
    - .forge/phase-4-spec/final/requirements.md (REQ-OVR-003)
    - core/toml-overlay.md (T-001 output)
  depends_on:
    - T-001
  acceptance_criteria_refs:
    - AC-DOC-002
    - AC-OVR-003 (documentation reference)
  test_files_pass:
    - tests/scenarios/v8-doc-toml-syntax-content.sh
  estimated_complexity: M
  parallelizable_with: []
  rollback_strategy: "Revert single commit; doc-only change."
  notes:
    - "Must enumerate ALL 18 agents in per-agent reference table per AC-DOC-002."
    - "Must explicitly document [meta] table EXEMPT from unknown-key validation (REQ-OVR-003)."
```

### Wave 7B — Agent consolidation (4-way parallel)

```yaml
- task_id: T-003
  description: "Merge agents/triage-analyst.md + agents/code-analyst.md → agents/analyst.md (Phase Dispatch section, --phase {triage,impact} flag handling, prompt-injection paragraph)"
  files_modified:
    - agents/analyst.md (NEW)
    - agents/triage-analyst.md (DELETE)
    - agents/code-analyst.md (DELETE)
  files_read_only:
    - agents/triage-analyst.md (PRE-DELETE source)
    - agents/code-analyst.md (PRE-DELETE source)
    - .forge/phase-4-spec/final/design.md (§3.1 + §3.2)
  depends_on:
    - T-001
  acceptance_criteria_refs:
    - AC-AGT-001
    - AC-AGT-002
    - AC-AGT-003
    - AC-NF-004 (prompt-injection paragraph on newly-merged agent)
    - AC-INV-PERM-001 (no hooks/mcpServers/permissionMode in frontmatter)
  test_files_pass:
    - tests/scenarios/v8-agents-enumeration.sh
    - tests/scenarios/v8-agents-deleted-old-names.sh
    - tests/scenarios/v8-agents-analyst-shape.sh
    - tests/scenarios/v8-nf-prompt-injection-coverage.sh
  estimated_complexity: M
  parallelizable_with:
    - T-004
    - T-005
    - T-006
  rollback_strategy: "Revert single commit; restores both deleted source agent files. T-006 deprecation alias still works against new files (or against restored old) so partial rollback safe."

- task_id: T-004
  description: "Extend agents/test-engineer.md with --e2e flag handling + merge agents/e2e-test-engineer.md content (in-place; name preserved)"
  files_modified:
    - agents/test-engineer.md (MODIFY — extend prompt body)
    - agents/e2e-test-engineer.md (DELETE)
  files_read_only:
    - agents/e2e-test-engineer.md (PRE-DELETE source)
    - .forge/phase-4-spec/final/design.md (§3.1 row 2)
  depends_on:
    - T-001
  acceptance_criteria_refs:
    - AC-AGT-001
    - AC-AGT-002
    - AC-AGT-004
    - AC-NF-004
    - AC-INV-PERM-001
  test_files_pass:
    - tests/scenarios/v8-agents-test-engineer-shape.sh
    - tests/scenarios/v8-agents-deleted-old-names.sh
    - tests/scenarios/v8-nf-prompt-injection-coverage.sh
  estimated_complexity: M
  parallelizable_with:
    - T-003
    - T-005
    - T-006
  rollback_strategy: "Revert single commit; restores agents/e2e-test-engineer.md and unwinds test-engineer.md additions."

- task_id: T-005
  description: "Merge agents/reproducer.md + agents/browser-verifier.md → agents/browser-agent.md (--phase {reproduce,verify} flag handling)"
  files_modified:
    - agents/browser-agent.md (NEW)
    - agents/reproducer.md (DELETE)
    - agents/browser-verifier.md (DELETE)
  files_read_only:
    - agents/reproducer.md (PRE-DELETE source)
    - agents/browser-verifier.md (PRE-DELETE source)
    - .forge/phase-4-spec/final/design.md (§3.1 row 3)
  depends_on:
    - T-001
  acceptance_criteria_refs:
    - AC-AGT-001
    - AC-AGT-002
    - AC-AGT-005
    - AC-NF-004
    - AC-INV-PERM-001
  test_files_pass:
    - tests/scenarios/v8-agents-browser-agent-shape.sh
    - tests/scenarios/v8-agents-deleted-old-names.sh
    - tests/scenarios/v8-nf-prompt-injection-coverage.sh
  estimated_complexity: M
  parallelizable_with:
    - T-003
    - T-004
    - T-006

  rollback_strategy: "Revert single commit; restores both deleted source agents."

- task_id: T-006
  description: "Extend /migrate-config skill with --to-v8 mode (.md→.toml conversion, agent rename mapping, REQ-MIG-003a test-engineer non-rename merge, Skip stages rewrite, --dry-run, --yolo auto-resolve, backup atomicity)"
  files_modified:
    - skills/migrate-config/SKILL.md (MODIFY — add --to-v8 mode and dry-run)
  files_read_only:
    - .forge/phase-4-spec/final/requirements.md (REQ-MIG-001..006, REQ-NF-009)
    - .forge/phase-4-spec/final/design.md (§6 migration tooling design)
    - core/toml-overlay.md (T-001 output)
  depends_on:
    - T-001
  acceptance_criteria_refs:
    - AC-MIG-001
    - AC-MIG-002
    - AC-MIG-003
    - AC-MIG-004
    - AC-MIG-005
    - AC-MIG-006
    - AC-MIG-007
    - AC-AGT-006 (deprecation alias parsed)
    - AC-NF-009 (backup safety)
  test_files_pass:
    - tests/scenarios/v8-migrate-config-md-to-toml.sh
    - tests/scenarios/v8-migrate-config-dryrun-noop.sh
    - tests/scenarios/v8-migrate-config-yolo-autoresolve.sh
    - tests/scenarios/v8-migrate-config-skip-stages.sh
    - tests/scenarios/v8-migrate-config-backup-failure.sh
    - tests/scenarios/v8-pipeline-profiles-legacy-alias.sh
    - tests/scenarios/v8-agents-deprecation-alias.sh
    - tests/scenarios-hidden/v8-hidden-agent-rename-collision.sh
    - tests/scenarios-hidden/v8-hidden-pipeline-profiles-mixed-old-new.sh
    - tests/scenarios-hidden/v8-hidden-customization-md-and-toml-coexist.sh
  estimated_complexity: L
  parallelizable_with:
    - T-003
    - T-004
    - T-005
  rollback_strategy: "Revert single commit; --to-v8 mode removed. Skill remains functional in pre-v8 form."
  notes:
    - "Per OQ-INT.1 ordering recommendation: this task does .md→.toml conversion FIRST per file, THEN applies agent rename file-moves (REQ-MIG-002 step 2 before step 3)."
    - "REQ-MIG-003a — `customization/test-engineer.md` (unit-only) + `customization/e2e-test-engineer.md` (e2e-only) merge into single test-engineer.toml with [applies-when --e2e=true] sentinel."
    - "REQ-MIG-002 step 4 — Skip stages comment uses HTML `<!-- migrated v7→v8 by /migrate-config -->` (NOT `//`) ABOVE Pipeline Profiles heading."
```

### Wave 7C — SKILL.md decomposition (3-way parallel)

```yaml
- task_id: T-007
  description: "Decompose skills/fix-bugs/SKILL.md (1006 lines) → entry SKILL.md (≤120 lines, mode flag parsing) + steps/{01..07}-*.md (7 step files)"
  files_modified:
    - skills/fix-bugs/SKILL.md (REWRITE — entry only)
    - skills/fix-bugs/steps/01-triage.md (NEW)
    - skills/fix-bugs/steps/02-impact.md (NEW)
    - skills/fix-bugs/steps/03-reproduce.md (NEW — conditional dispatch)
    - skills/fix-bugs/steps/04-fixer-reviewer-loop.md (NEW)
    - skills/fix-bugs/steps/05-test.md (NEW)
    - skills/fix-bugs/steps/06-acceptance-gate.md (NEW — conditional)
    - skills/fix-bugs/steps/07-publish.md (NEW)
  files_read_only:
    - .forge/phase-4-spec/final/design.md (§4.1 fix-bugs layout)
  depends_on:
    - T-001
    - T-003
    - T-004
    - T-005
  acceptance_criteria_refs:
    - AC-STEPS-001
    - AC-STEPS-002
    - AC-STEPS-003
    - AC-STEPS-003a
    - AC-STEPS-004
    - AC-STEPS-005
    - AC-STEPS-006
    - AC-STEPS-007
    - AC-MODE-001
    - AC-MODE-002
    - AC-MODE-003
    - AC-MODE-004
    - AC-MODE-005
    - AC-MODE-006
    - AC-MODE-007
    - AC-MODE-008a
    - AC-MODE-MATRIX-001
    - AC-MODE-MATRIX-002
    - AC-MODE-MATRIX-003
  test_files_pass:
    - tests/scenarios/v8-steps-entry-thinness.sh (fix-bugs ≤ 120)
    - tests/scenarios/v8-steps-count.sh
    - tests/scenarios/v8-steps-naming-convention.sh
    - tests/scenarios/v8-steps-override-log.sh
    - tests/scenarios/v8-steps-default-resolution.sh
    - tests/scenarios/v8-steps-override-replace.sh
    - tests/scenarios/v8-steps-near-miss-warn.sh
    - tests/scenarios/v8-matrix-fixbugs-yolo.sh
    - tests/scenarios/v8-matrix-fixbugs-default.sh
    - tests/scenarios/v8-matrix-fixbugs-stepmode.sh
    - tests/scenarios-hidden/v8-hidden-step-override-zero-pad-mismatch.sh
  estimated_complexity: L
  parallelizable_with:
    - T-008
    - T-009
  rollback_strategy: "Revert commit. Pre-v8 monolithic SKILL.md restored. NO half-decomposed states are committed (atomic 7-file write)."
  notes:
    - "Each step file matches regex `^[0-9][0-9]-[a-z0-9-]+\\.md$` per REQ-STEPS-006 / AC-STEPS-007."
    - "Step override resolution + near-miss WARN per REQ-STEPS-002/003a implemented in entry SKILL.md dispatch."
    - "Pipeline-default {total}=7 baked into entry SKILL.md as static literal (NOT runtime scan) per REQ-MODE-007."

- task_id: T-008
  description: "Decompose skills/implement-feature/SKILL.md (672 lines) → entry SKILL.md (≤120 lines) + steps/{01..07}-*.md (7 step files)"
  files_modified:
    - skills/implement-feature/SKILL.md (REWRITE — entry only)
    - skills/implement-feature/steps/01-spec.md (NEW)
    - skills/implement-feature/steps/02-architect.md (NEW)
    - skills/implement-feature/steps/03-decomposition.md (NEW)
    - skills/implement-feature/steps/04-fixer-reviewer-loop.md (NEW)
    - skills/implement-feature/steps/05-test.md (NEW)
    - skills/implement-feature/steps/06-acceptance-gate.md (NEW)
    - skills/implement-feature/steps/07-publish.md (NEW)
  files_read_only:
    - .forge/phase-4-spec/final/design.md (§4.1 implement-feature layout)
  depends_on:
    - T-001
    - T-003
    - T-004
  acceptance_criteria_refs:
    - AC-STEPS-001
    - AC-STEPS-002
    - AC-STEPS-007
    - AC-MODE-001
    - AC-MODE-002
    - AC-MODE-003
    - AC-MODE-004
    - AC-MODE-005
    - AC-MODE-008a
    - AC-MODE-MATRIX-004
    - AC-MODE-MATRIX-005
    - AC-MODE-MATRIX-006
  test_files_pass:
    - tests/scenarios/v8-steps-entry-thinness.sh (implement-feature ≤ 120)
    - tests/scenarios/v8-steps-count.sh
    - tests/scenarios/v8-steps-naming-convention.sh
    - tests/scenarios/v8-matrix-implfeat-yolo.sh
    - tests/scenarios/v8-matrix-implfeat-default.sh
    - tests/scenarios/v8-matrix-implfeat-stepmode.sh
  estimated_complexity: L
  parallelizable_with:
    - T-007
    - T-009
  rollback_strategy: "Revert commit. Pre-v8 monolithic SKILL.md restored."

- task_id: T-009
  description: "Decompose skills/scaffold/SKILL.md (1147 lines) → entry SKILL.md (≤120 lines, B6 mode harmonization — drop interactive 3-mode prompt) + steps/{01..08}-*.md (8 step files)"
  files_modified:
    - skills/scaffold/SKILL.md (REWRITE — entry only; remove `(a)/(b)/(c)` interactive prompt)
    - skills/scaffold/steps/01-mode-resolve.md (NEW — replaces interactive prompt)
    - skills/scaffold/steps/02-spec-write-review.md (NEW)
    - skills/scaffold/steps/03-scaffold.md (NEW)
    - skills/scaffold/steps/04-architect.md (NEW)
    - skills/scaffold/steps/05-fixer-reviewer-loop.md (NEW)
    - skills/scaffold/steps/06-test.md (NEW)
    - skills/scaffold/steps/07-spec-verify.md (NEW)
    - skills/scaffold/steps/08-final-report.md (NEW)
  files_read_only:
    - .forge/phase-4-spec/final/design.md (§4.1 scaffold layout + §5.4 B6 harmonization map)
    - .forge/phase-4-spec/final/requirements.md (REQ-MODE-009 + REQ-MODE-009a vague heuristic)
  depends_on:
    - T-001
    - T-003
    - T-004
  acceptance_criteria_refs:
    - AC-STEPS-001
    - AC-STEPS-002
    - AC-STEPS-007
    - AC-MODE-001
    - AC-MODE-002
    - AC-MODE-003
    - AC-MODE-004
    - AC-MODE-005
    - AC-MODE-008
    - AC-MODE-009
    - AC-MODE-008a
    - AC-MODE-MATRIX-007
    - AC-MODE-MATRIX-008
    - AC-MODE-MATRIX-009
  test_files_pass:
    - tests/scenarios/v8-steps-entry-thinness.sh (scaffold ≤ 120)
    - tests/scenarios/v8-steps-count.sh
    - tests/scenarios/v8-mode-scaffold-vague-skip.sh
    - tests/scenarios/v8-mode-vague-heuristic-boundaries.sh
    - tests/scenarios/v8-matrix-scaffold-yolo.sh
    - tests/scenarios/v8-matrix-scaffold-default.sh
    - tests/scenarios/v8-matrix-scaffold-stepmode.sh
    - tests/scenarios-hidden/v8-hidden-mode-vague-heuristic-edge.sh
  estimated_complexity: L
  parallelizable_with:
    - T-007
    - T-008
  rollback_strategy: "Revert commit. Pre-v8 SKILL.md (with interactive 3-mode prompt) restored."
  notes:
    - "REQ-MODE-009a POSIX ERE patterns (framework keywords, version, command syntax, file extensions) embedded in step 01-mode-resolve.md."
    - "Scaffold has 8 steps (one more than fix-bugs/implement-feature) per design.md §4.1; 5 ≤ count ≤ 8 satisfied."
```

### Wave 7D — `/setup-agents` skill (2-way parallel)

```yaml
- task_id: T-010
  description: "Create new skill /ceos-agents:setup-agents (29th skill) — heuristics (Python, monorepo, TypeScript, test framework), preview-diff prompt, # generated: header, --force/--yolo flags, symlink-escape guard"
  files_modified:
    - skills/setup-agents/SKILL.md (NEW)
  files_read_only:
    - .forge/phase-4-spec/final/requirements.md (REQ-SETUP-001..006)
    - .forge/phase-4-spec/final/design.md (§1.4 setup-agents flow)
    - skills/setup-agents/lib/toml-merge.sh (T-001 output)
  depends_on:
    - T-001
  acceptance_criteria_refs:
    - AC-SETUP-001
    - AC-SETUP-002
    - AC-SETUP-003
    - AC-SETUP-004
    - AC-SETUP-005
    - AC-SETUP-006
    - AC-SETUP-007
    - AC-SETUP-008
  test_files_pass:
    - tests/scenarios/v8-setup-agents-skill-exists.sh
    - tests/scenarios/v8-setup-agents-python.sh
    - tests/scenarios/v8-setup-agents-monorepo.sh
    - tests/scenarios/v8-setup-agents-header.sh
    - tests/scenarios/v8-setup-agents-preserve.sh
    - tests/scenarios/v8-setup-agents-force-backup.sh
    - tests/scenarios/v8-setup-agents-preview.sh
    - tests/scenarios/v8-setup-agents-scope.sh
    - tests/scenarios-hidden/v8-hidden-setup-agents-malicious-symlink.sh
  estimated_complexity: M
  parallelizable_with:
    - T-011
  rollback_strategy: "Revert single commit; skills/setup-agents/ DELETE. Skill count returns 28."
  notes:
    - "Symlink resolution per REQ-SETUP-006: prefer python3 os.path.realpath fallback over readlink -f for macOS bash 3.2 portability."

- task_id: T-011
  description: "Create examples/customization/ directory with 4+ example overlay files (reviewer-strict-security.toml, fixer-no-tests.toml, analyst-monorepo.toml, step-override-example.md)"
  files_modified:
    - examples/customization/reviewer-strict-security.toml (NEW)
    - examples/customization/fixer-no-tests.toml (NEW)
    - examples/customization/analyst-monorepo.toml (NEW)
    - examples/customization/step-override-example.md (NEW — inline fenced block, no sibling placeholder)
  files_read_only:
    - .forge/phase-4-spec/final/requirements.md (REQ-DOC-011)
    - .forge/phase-4-spec/final/design.md (§2.3 three concrete examples)
  depends_on: []
  acceptance_criteria_refs:
    - AC-DOC-011
  test_files_pass:
    - tests/scenarios/v8-doc-examples-customization.sh
  estimated_complexity: S
  parallelizable_with:
    - T-010
    - T-002
    - T-003
    - T-004
    - T-005
  rollback_strategy: "Revert single commit; examples/customization/ directory DELETE."
```

### Wave 7E — Mode-flag parsing (3-way parallel; depends on 7C decomposition)

NOTE: T-007/T-008/T-009 already produce the mode-flag parsing block in entry SKILL.md per design.md §5.1. Tasks T-012..T-014 are WAVE 7E only if Phase 7 chooses fine-grained split between "decompose" and "add mode-flag parsing block". Phase 6 RECOMMENDATION: **fold T-012/T-013/T-014 INTO T-007/T-008/T-009 respectively** (single atomic commit per pipeline) to avoid file-conflict in worktree. The IDs are listed below for traceability but flagged as **OPTIONAL EXTRACTION**.

```yaml
- task_id: T-012
  description: "[OPTIONAL — folded into T-007] Mode-flag parsing block (--yolo/default/--step-mode) + mutual-exclusion ERROR check at top of skills/fix-bugs/SKILL.md entry"
  files_modified:
    - skills/fix-bugs/SKILL.md (already in T-007)
  files_read_only: []
  depends_on:
    - T-007
  acceptance_criteria_refs:
    - AC-MODE-001
    - AC-MODE-002
    - AC-MODE-003
  test_files_pass:
    - tests/scenarios/v8-mode-mutual-exclusion.sh
    - tests/scenarios-hidden/v8-hidden-mode-flag-double-yolo.sh
  estimated_complexity: S
  parallelizable_with:
    - T-013
    - T-014
  rollback_strategy: "Folded into T-007 rollback."
  notes:
    - "RECOMMENDATION: do not extract; fold into T-007 atomic commit."

- task_id: T-013
  description: "[OPTIONAL — folded into T-008] Mode-flag parsing block + mutual-exclusion ERROR check at top of skills/implement-feature/SKILL.md entry"
  files_modified:
    - skills/implement-feature/SKILL.md (already in T-008)
  files_read_only: []
  depends_on:
    - T-008
  acceptance_criteria_refs:
    - AC-MODE-001
    - AC-MODE-002
    - AC-MODE-003
  test_files_pass:
    - tests/scenarios/v8-matrix-implfeat-yolo.sh
    - tests/scenarios/v8-matrix-implfeat-default.sh
    - tests/scenarios/v8-matrix-implfeat-stepmode.sh
  estimated_complexity: S
  parallelizable_with:
    - T-012
    - T-014
  rollback_strategy: "Folded into T-008 rollback."
  notes:
    - "RECOMMENDATION: do not extract; fold into T-008 atomic commit."

- task_id: T-014
  description: "[OPTIONAL — folded into T-009] Mode-flag parsing block + mutual-exclusion ERROR check at top of skills/scaffold/SKILL.md entry; B6 mode harmonization (drop interactive 3-mode prompt)"
  files_modified:
    - skills/scaffold/SKILL.md (already in T-009)
  files_read_only: []
  depends_on:
    - T-009
  acceptance_criteria_refs:
    - AC-MODE-001
    - AC-MODE-008
    - AC-MODE-009
  test_files_pass:
    - tests/scenarios/v8-mode-scaffold-vague-skip.sh
    - tests/scenarios/v8-doc-claude-md-scaffold-prose-removed.sh
  estimated_complexity: S
  parallelizable_with:
    - T-012
    - T-013
  rollback_strategy: "Folded into T-009 rollback."
  notes:
    - "RECOMMENDATION: do not extract; fold into T-009 atomic commit."
    - "AC-DOC-014b absence-grep on CLAUDE.md (NOT on SKILL.md) belongs to T-027."
```

**Phase 7 dispatch decision:** Mark T-012/T-013/T-014 as `status=folded` in Phase 7 status.json; treat them as **traceability handles** for the AC mapping rather than separate worktrees. This avoids the AP1 fake-parallel pattern (same `files_modified` as T-007/T-008/T-009).

### Wave 7F — State + status reader (sequential downstream from agent rename)

```yaml
- task_id: T-015
  description: "state.json schema additions (additive analyst_*, browser_agent_*, test_engineer_e2e_invoked keys) — schema_version stays 1.0, v7 transitional alias keys also written"
  files_modified:
    - state/schema.md (MODIFY — document additive keys + alias keys)
    - core/state-manager.md (MODIFY — write both v8 keys + v7 transitional aliases during v8.0.0)
  files_read_only:
    - .forge/phase-4-spec/final/requirements.md (REQ-AGT-007 + REQ-NF-007)
    - .forge/phase-4-spec/final/design.md (§3.3 state schema impact)
  depends_on:
    - T-003
    - T-004
    - T-005
  acceptance_criteria_refs:
    - AC-AGT-007
    - AC-AGT-008
    - AC-NF-007
  test_files_pass:
    - tests/scenarios/v8-agents-state-additive.sh
    - tests/scenarios/v8-nf-state-additive-readable.sh
  estimated_complexity: M
  parallelizable_with: []
  rollback_strategy: "Revert single commit. v7 schema/handler restored. v6.x and v7.x readers unaffected."

- task_id: T-016
  description: "/pipeline-status v8 read logic (dedupe v7+v8 keys, prefer v8 with WARN on differing values)"
  files_modified:
    - skills/pipeline-status/SKILL.md (MODIFY — add dedup logic per REQ-AGT-008)
  files_read_only:
    - .forge/phase-4-spec/final/requirements.md (REQ-AGT-008)
    - state/schema.md (T-015 output)
  depends_on:
    - T-015
  acceptance_criteria_refs:
    - AC-AGT-009
  test_files_pass:
    - tests/scenarios/v8-pipeline-status-dedup.sh
  estimated_complexity: S
  parallelizable_with: []
  rollback_strategy: "Revert single commit; legacy /pipeline-status reader restored."
```

### Wave 7G — Documentation (10-way parallel)

```yaml
- task_id: T-017
  description: "Create NEW guide docs/guides/migration-v7-to-v8.md (TOML conversion, agent rename mapping, SKILL decomposition, plugin permission constraint, scaffold mode harmonization, Skip stages syntax migration, deprecation timeline, /migrate-config walk-through)"
  files_modified:
    - docs/guides/migration-v7-to-v8.md (NEW)
  files_read_only:
    - .forge/phase-4-spec/final/requirements.md (REQ-DOC-001)
    - .forge/phase-4-spec/final/design.md (§3 + §5.4 + §6)
  depends_on: []
  acceptance_criteria_refs:
    - AC-DOC-001
  test_files_pass:
    - tests/scenarios/v8-doc-migration-guide-sections.sh
  estimated_complexity: M
  parallelizable_with:
    - T-002
    - T-018
    - T-019
    - T-020
    - T-021
    - T-022
    - T-023
    - T-024
    - T-025
    - T-026
  rollback_strategy: "Revert single commit; doc-only file removal."
  notes:
    - "Must contain ALL 8 H2 headings per AC-DOC-001."

- task_id: T-018
  description: "Create NEW guide docs/guides/setup-agents-skill.md (when to invoke, scan heuristics, preview-diff UX, idempotent regen, --force semantics, 3+ worked examples)"
  files_modified:
    - docs/guides/setup-agents-skill.md (NEW)
  files_read_only:
    - .forge/phase-4-spec/final/requirements.md (REQ-DOC-003)
  depends_on: []
  acceptance_criteria_refs:
    - AC-DOC-003
  test_files_pass:
    - tests/scenarios/v8-doc-setup-agents-examples.sh
  estimated_complexity: M
  parallelizable_with:
    - T-002
    - T-017
    - T-019
    - T-020
    - T-021
    - T-022
    - T-023
    - T-024
    - T-025
    - T-026
  rollback_strategy: "Revert single commit; doc-only."

- task_id: T-019
  description: "Create NEW guide docs/guides/steps-decomposition.md (decomposition rationale, entry-vs-step responsibility split, step override mechanism, Pipeline Profiles named-phase migration, debugging tips, 1+ override example per pipeline = 3 examples)"
  files_modified:
    - docs/guides/steps-decomposition.md (NEW)
  files_read_only:
    - .forge/phase-4-spec/final/requirements.md (REQ-DOC-004)
    - .forge/phase-4-spec/final/design.md (§4)
  depends_on: []
  acceptance_criteria_refs:
    - AC-DOC-004
    - AC-STEPS-006 (named-phase syntax content)
  test_files_pass:
    - tests/scenarios/v8-doc-steps-decomp-content.sh
  estimated_complexity: M
  parallelizable_with:
    - T-002
    - T-017
    - T-018
    - T-020
    - T-021
    - T-022
    - T-023
    - T-024
    - T-025
    - T-026
  rollback_strategy: "Revert single commit; doc-only."

- task_id: T-020
  description: "Create NEW reference docs/reference/pipeline.md (singular; entry SKILL.md responsibilities, step file responsibilities, step override resolution, mode flag dispatch, named-phase Skip stages syntax + code-block example)"
  files_modified:
    - docs/reference/pipeline.md (NEW)
  files_read_only:
    - .forge/phase-4-spec/final/requirements.md (REQ-DOC-009)
    - .forge/phase-4-spec/final/design.md (§4 + §5)
  depends_on: []
  acceptance_criteria_refs:
    - AC-DOC-009
  test_files_pass:
    - tests/scenarios/v8-doc-pipeline-content.sh
  estimated_complexity: M
  parallelizable_with:
    - T-002
    - T-017
    - T-018
    - T-019
    - T-021
    - T-022
    - T-023
    - T-024
    - T-025
    - T-026
  rollback_strategy: "Revert single commit; doc-only. Pre-existing docs/reference/pipelines.md (plural) NOT touched."
  notes:
    - "Singular `pipeline.md` is NEW; plural `pipelines.md` is pre-existing and out-of-scope per REQ-DOC-009."

- task_id: T-021
  description: "Update docs/reference/agents.md to 18 rows in main agents table per AC-DOC-005 ordering (analyst, fixer, reviewer, acceptance-gate, test-engineer, publisher, rollback-agent, spec-analyst, architect, stack-selector, scaffolder, priority-engine, spec-writer, spec-reviewer, browser-agent, deployment-verifier, backlog-creator, sprint-planner)"
  files_modified:
    - docs/reference/agents.md (MODIFY)
  files_read_only:
    - .forge/phase-4-spec/final/requirements.md (REQ-DOC-005)
  depends_on:
    - T-003
    - T-004
    - T-005
  acceptance_criteria_refs:
    - AC-DOC-005
  test_files_pass:
    - tests/scenarios/v8-doc-agents-enumeration.sh
  estimated_complexity: M
  parallelizable_with:
    - T-002
    - T-017
    - T-018
    - T-019
    - T-020
    - T-022
    - T-023
    - T-024
    - T-025
    - T-026
  rollback_strategy: "Revert single commit; doc-only."

- task_id: T-022
  description: "Update docs/reference/skills.md to 29 rows (28 existing + new /setup-agents) per AC-DOC-006 ordering; replace deprecated v7 agent names in row descriptions; update /scaffold row to flag-based modes"
  files_modified:
    - docs/reference/skills.md (MODIFY)
  files_read_only:
    - .forge/phase-4-spec/final/requirements.md (REQ-DOC-006)
  depends_on:
    - T-010
  acceptance_criteria_refs:
    - AC-DOC-006
  test_files_pass:
    - tests/scenarios/v8-doc-skills-enumeration.sh
  estimated_complexity: M
  parallelizable_with:
    - T-002
    - T-017
    - T-018
    - T-019
    - T-020
    - T-021
    - T-023
    - T-024
    - T-025
    - T-026
  rollback_strategy: "Revert single commit; doc-only."

- task_id: T-023
  description: "Update docs/reference/automation-config.md (TOML overlay format reference, Plugin Permission Constraint subsection with exact phrase 'hooks are skill-orchestrated, not agent-frontmatter', Pipeline Profiles named-phase syntax, 18 sections preserved)"
  files_modified:
    - docs/reference/automation-config.md (MODIFY)
  files_read_only:
    - .forge/phase-4-spec/final/requirements.md (REQ-DOC-007 + REQ-NF-003)
  depends_on: []
  acceptance_criteria_refs:
    - AC-DOC-007
    - AC-CT-003 (18 sections preserved)
    - AC-INV-PERM-001 (documentation pointer)
  test_files_pass:
    - tests/scenarios/v8-invariant-plugin-perm-constraint.sh (doc pointer side; main check is on agents/*.md)
    - tests/scenarios/v8-count-config-sections.sh
  estimated_complexity: M
  parallelizable_with:
    - T-002
    - T-017
    - T-018
    - T-019
    - T-020
    - T-021
    - T-022
    - T-024
    - T-025
    - T-026
  rollback_strategy: "Revert single commit; doc-only."

- task_id: T-024
  description: "Update docs/architecture.md (18 agents, 29 skills, TOML overlay layer, steps decomposition node, mode flag arrows, all 3 pipelines with step counts: fix-bugs 7 / implement-feature 7 / scaffold 8, named-phase identifiers analyst-triage/analyst-impact/browser-agent-reproduce/browser-agent-verify)"
  files_modified:
    - docs/architecture.md (MODIFY)
  files_read_only:
    - .forge/phase-4-spec/final/requirements.md (REQ-DOC-008)
    - .forge/phase-4-spec/final/design.md (§1.1 architecture diagram)
  depends_on:
    - T-003
    - T-004
    - T-005
    - T-007
    - T-008
    - T-009
    - T-010
  acceptance_criteria_refs:
    - AC-DOC-008
  test_files_pass:
    - tests/scenarios/v8-doc-architecture-content.sh
  estimated_complexity: M
  parallelizable_with:
    - T-002
    - T-017
    - T-018
    - T-019
    - T-020
    - T-021
    - T-022
    - T-023
    - T-025
    - T-026
  rollback_strategy: "Revert single commit; doc-only."

- task_id: T-025
  description: "Update 8 config templates in examples/configs/*.md (github-nextjs, github-python-fastapi, github-dotnet, gitea-spring-boot, jira-react, youtrack-python, redmine-rails, redmine-oracle-plsql) — add 'Migration note: v7 → v8' callout at top of ## Automation Config section + reference TOML overlay (NOT .md)"
  files_modified:
    - examples/configs/github-nextjs.md (MODIFY)
    - examples/configs/github-python-fastapi.md (MODIFY)
    - examples/configs/github-dotnet.md (MODIFY)
    - examples/configs/gitea-spring-boot.md (MODIFY)
    - examples/configs/jira-react.md (MODIFY)
    - examples/configs/youtrack-python.md (MODIFY)
    - examples/configs/redmine-rails.md (MODIFY)
    - examples/configs/redmine-oracle-plsql.md (MODIFY)
  files_read_only:
    - .forge/phase-4-spec/final/requirements.md (REQ-DOC-010)
  depends_on: []
  acceptance_criteria_refs:
    - AC-DOC-010
    - AC-CT-005 (8 templates preserved)
  test_files_pass:
    - tests/scenarios/v8-doc-config-templates.sh
  estimated_complexity: M
  parallelizable_with:
    - T-002
    - T-017
    - T-018
    - T-019
    - T-020
    - T-021
    - T-022
    - T-023
    - T-024
    - T-026
  rollback_strategy: "Revert single commit; per-template diff revert."
  notes:
    - "8 files but conceptually one task (per-template parallel-rewrite is fine within single worktree because content pattern is uniform)."

- task_id: T-026
  description: "Author new core/agents-rename-aliases.md contract (mapping table for 6 deprecated v7 names → v8 dispatch + arg) to formalize REQ-AGT-006 / REQ-MIG-006 alias resolution at runtime"
  files_modified:
    - core/aliases/agents-rename-aliases.md (NEW — sub-namespace, preserves maxdepth-1 count at 16)
  files_read_only:
    - .forge/phase-4-spec/final/requirements.md (REQ-AGT-006 + REQ-MIG-006)
  depends_on: []
  acceptance_criteria_refs:
    - AC-AGT-006
    - AC-MIG-007
  test_files_pass:
    - tests/scenarios/v8-agents-deprecation-alias.sh
    - tests/scenarios/v8-pipeline-profiles-legacy-alias.sh
  estimated_complexity: S
  parallelizable_with:
    - T-002
    - T-017
    - T-018
    - T-019
    - T-020
    - T-021
    - T-022
    - T-023
    - T-024
    - T-025
  rollback_strategy: "Revert single commit; DELETE core/aliases/agents-rename-aliases.md (and core/aliases/ directory if empty). Core maxdepth-1 count remains at 16 (sub-namespace file not counted at depth-1)."
  notes:
    - "CRITICAL: top-level `find core -maxdepth 1 -name '*.md' -type f | wc -l` MUST equal 16 per AC-CT-004. This NEW contract is placed under `core/aliases/agents-rename-aliases.md` (sub-namespace, NOT top-level) — identical pattern to v6.9.0 core/snippets/ sub-namespace. The `core/aliases/` directory does NOT yet exist; Phase 7 implementor MUST create it. Verify maxdepth-1 count == 16 BEFORE commit."
```

### Wave 7H — README / CHANGELOG / CLAUDE.md (sequential cross-file invariant chain)

These three are deliberately sequential because each depends on the prior counts/enumerations being settled. Phase 7 dispatches T-027 → T-028 → T-029 in order.

```yaml
- task_id: T-027
  description: "Update CLAUDE.md (Architecture: 18 agents + 29 skills enumeration; Bug-Fix/Feature/Scaffold Pipeline sections: replace 6 deprecated agent names with v8 names + phase args; Scaffold Pipeline section: replace 3-mode interactive prose with 3-flag form; Model Selection table: refresh agent rows; remove (a)/(b)/(c) scaffold mode descriptors per AC-DOC-014b)"
  files_modified:
    - CLAUDE.md (MODIFY)
  files_read_only:
    - .forge/phase-4-spec/final/requirements.md (REQ-DOC-014)
  depends_on:
    - T-003
    - T-004
    - T-005
    - T-009
    - T-010
    - T-021 (agents enumeration source)
    - T-022 (skills enumeration source)
    - T-023 (config sections enumeration source)
  acceptance_criteria_refs:
    - AC-DOC-005
    - AC-DOC-006
    - AC-DOC-014b
    - AC-INV-DOC-ENUM-001
  test_files_pass:
    - tests/scenarios/v8-doc-claude-md-scaffold-prose-removed.sh
    - tests/scenarios/v8-invariant-doc-enumeration-parity.sh (CLAUDE.md side)
    - tests/scenarios/v8-count-config-sections.sh
  estimated_complexity: M
  parallelizable_with: []
  rollback_strategy: "Revert single commit; v7 CLAUDE.md restored. Pipeline section still references old agent names — use only if T-003..T-005 also rolled back to maintain invariant."

- task_id: T-028
  description: "Update README.md (replace 21 → 18 agents, 28 → 29 skills, add 'v8.0.0 Highlights' callout, add migration callout linking docs/guides/migration-v7-to-v8.md, refresh diagram references)"
  files_modified:
    - README.md (MODIFY)
  files_read_only:
    - CLAUDE.md (T-027 output for cross-consistency)
    - .forge/phase-4-spec/final/requirements.md (REQ-DOC-012)
  depends_on:
    - T-027
  acceptance_criteria_refs:
    - AC-DOC-012
    - AC-INV-DOC-ENUM-001 (README.md is one of 5 files)
  test_files_pass:
    - tests/scenarios/v8-doc-readme-v8-content.sh
    - tests/scenarios/v8-invariant-doc-enumeration-parity.sh (README.md side)
    - tests/scenarios-hidden/v8-hidden-doc-enumeration-extra-agent.sh (mutation test must FAIL on extra agent)
  estimated_complexity: M
  parallelizable_with: []
  rollback_strategy: "Revert single commit. v7 README restored."

- task_id: T-029
  description: "Add CHANGELOG.md ## v8.0.0 entry — 5 mandatory breaking-change subsections (Customization (.md → .toml), Agent renames (6 → 3), SKILL.md decomposition, Pipeline Profiles syntax, Scaffold mode harmonization) with Migration: paragraph + before/after code-block per subsection"
  files_modified:
    - CHANGELOG.md (MODIFY)
  files_read_only:
    - .forge/phase-4-spec/final/requirements.md (REQ-DOC-013)
    - All prior task outputs (this is the final consolidation per AP7)
  depends_on:
    - T-028
  acceptance_criteria_refs:
    - AC-DOC-013
  test_files_pass:
    - tests/scenarios/v8-doc-changelog-v8.sh
  estimated_complexity: M
  parallelizable_with: []
  rollback_strategy: "Revert single commit. Pre-v8 CHANGELOG restored. Other files reference v8.0.0 in headings/highlights regardless — partial state acceptable."
```

### Wave 7I — Cross-File Invariant atomic verification (single sequential)

```yaml
- task_id: T-030
  description: "Atomic Cross-File Invariant verification + fix-up (License SPDX, maintainer email, template parity, doc count enumeration parity across 5 files); add explicit-boolean lint check for 3 entry SKILL.md files"
  files_modified:
    - (verification only — no file changes EXPECTED; if any drift found, fix-up commit may touch any of 5 doc files / 3 SKILL.md files / .gitea-.github template pairs)
  files_read_only:
    - CLAUDE.md
    - README.md
    - docs/reference/automation-config.md
    - docs/reference/skills.md
    - docs/architecture.md
    - .claude-plugin/plugin.json
    - .claude-plugin/marketplace.json
    - LICENSE
    - SECURITY.md
    - CODE_OF_CONDUCT.md
    - CONTRIBUTING.md
    - .gitea/issue_template/*.md
    - .github/ISSUE_TEMPLATE/*.md
    - .gitea/pull_request_template.md
    - .github/PULL_REQUEST_TEMPLATE.md
    - skills/fix-bugs/SKILL.md
    - skills/implement-feature/SKILL.md
    - skills/scaffold/SKILL.md
    - agents/*.md (18 files)
  depends_on:
    - T-027
    - T-028
    - T-029
    - T-021
    - T-022
    - T-023
    - T-024
    - T-026
  acceptance_criteria_refs:
    - AC-INV-LICENSE-001
    - AC-INV-EMAIL-001
    - AC-INV-TEMPLATE-001
    - AC-INV-DOC-ENUM-001
    - AC-INV-PERM-001
    - AC-NF-010
  test_files_pass:
    - tests/scenarios/v8-invariant-license-spdx.sh
    - tests/scenarios/v8-invariant-maintainer-email.sh
    - tests/scenarios/v8-invariant-template-parity.sh
    - tests/scenarios/v8-invariant-doc-enumeration-parity.sh
    - tests/scenarios/v8-invariant-plugin-perm-constraint.sh
    - tests/scenarios-hidden/v8-hidden-template-parity-line-ending.sh
  estimated_complexity: S
  parallelizable_with: []
  rollback_strategy: "Verification phase. If a fix-up commit is needed, revert just that commit. ABORT v8.0.0 release if invariants cannot be satisfied (NEVER ship inconsistent state)."
  notes:
    - "Per spec.md AP4: this task closes the doc-count drift window. T-022..T-024 (reference docs) commit BEFORE T-027..T-029 (top-level docs); T-030 confirms set-equality across all 5."
    - "Lint-side check: design.md §5.1 explicit-boolean pattern (`GOT_YOLO=` AND `GOT_STEP_MODE=` substrings) MUST appear in skills/{fix-bugs,implement-feature,scaffold}/SKILL.md. Regex grep with -F over the 3 files."
    - "AC-INV-PERM-001 frontmatter-only grep — extract YAML frontmatter via `awk '/^---$/{c++; next} c==1' agent.md` then grep `^(hooks|mcpServers|permissionMode):`. Zero matches required across 18 files."
```

### Wave 7J — Test integration (parallel, post-implementation)

```yaml
- task_id: T-031
  description: "Move/integrate visible tests .forge/phase-5-tdd/tests/*.sh → tests/scenarios/ (80 files; preserve permissions; resolve REPO_ROOT 2-level-up correctly)"
  files_modified:
    - tests/scenarios/v8-*.sh (NEW × 80 — all visible v8.0.0 scenarios)
  files_read_only:
    - .forge/phase-5-tdd/tests/v8-*.sh
    - .forge/phase-5-tdd/coverage-report.md
  depends_on:
    - T-030
  acceptance_criteria_refs:
    - AC-NF-005
    - AC-NF-008
  test_files_pass:
    - All 80 visible scenarios via tests/harness/run-tests.sh
  estimated_complexity: M
  parallelizable_with:
    - T-032
    - T-033
  rollback_strategy: "Revert commit; tests removed from tests/scenarios/. Source files in .forge/phase-5-tdd/tests/ unaffected."
  notes:
    - "Per coverage-report.md §REPO_ROOT semantics: tests are NOT runnable from staging; ONLY from tests/scenarios/."
    - "Defensive guard `if echo \"$REPO_ROOT\" | grep -q '\\.forge'` already embedded in each test."

- task_id: T-032
  description: "Move/integrate hidden adversarial tests .forge/phase-5-tdd/tests-hidden/*.sh → tests/scenarios-hidden/ (12 files; preserve permissions)"
  files_modified:
    - tests/scenarios-hidden/v8-hidden-*.sh (NEW × 12)
  files_read_only:
    - .forge/phase-5-tdd/tests-hidden/v8-hidden-*.sh
  depends_on:
    - T-030
  acceptance_criteria_refs:
    - AC-NF-005
  test_files_pass:
    - All 12 hidden scenarios
  estimated_complexity: S
  parallelizable_with:
    - T-031
    - T-033
  rollback_strategy: "Revert commit; hidden tests removed."

- task_id: T-033
  description: "Update tests/mock-project/ with TOML overlay fixtures + v8 customization dir (per coverage-report.md §Mock Fixture Additions)"
  files_modified:
    - tests/mock-project/customization/.gitkeep (NEW — directory marker)
    - tests/mock-project/customization/reviewer.toml (NEW)
    - tests/mock-project/customization/steps/fix-bugs/.gitkeep (NEW)
    - tests/mock-project/.ceos-agents/.gitkeep (NEW)
    - tests/mock-project/pyproject.toml (NEW)
    - tests/mock-project/pnpm-workspace.yaml (NEW)
    - tests/mock-project/packages/api/package.json (NEW)
    - tests/mock-project/packages/web/package.json (NEW)
    - tests/mock-project/CLAUDE.md (MODIFY — add ### Pipeline Profiles with v8 syntax)
  files_read_only:
    - .forge/phase-5-tdd/coverage-report.md (Mock Fixture Additions table)
  depends_on:
    - T-031
  acceptance_criteria_refs:
    - AC-SETUP-002
    - AC-SETUP-003
    - AC-OVR-001
    - AC-OVR-002
    - AC-OVR-003
    - AC-OVR-004
    - AC-OVR-005
    - AC-OVR-006
    - AC-OVR-007
    - AC-OVR-008
    - AC-MIG-001
    - AC-MIG-002
    - AC-MIG-003
    - AC-MIG-004
    - AC-MIG-005
    - AC-MIG-006
    - AC-MIG-007
    - AC-NF-005
  test_files_pass:
    - tests/scenarios/v8-setup-agents-python.sh
    - tests/scenarios/v8-setup-agents-monorepo.sh
    - tests/scenarios/v8-overlay-*.sh
  estimated_complexity: S
  parallelizable_with:
    - T-031
    - T-032
  rollback_strategy: "Revert commit; mock-project state restored to pre-v8 layout."
  notes:
    - "Mock files are FIXTURES, not real config — no risk to production project."
```

---

## 2. Migration Ordering Decision (resolves OQ-INT.1)

**Question:** TOML overlay system first OR agent renames first?

**Decision: TOML overlay first (T-001 root → T-002 syntax doc → T-003..T-005 agent renames)**

**Rationale:**

1. **Pure-additive vs file-renaming.** TOML overlay infrastructure (T-001, T-002) is pure additive: introduces new files (`core/toml-overlay.md`, `skills/setup-agents/lib/toml-merge.sh`, `docs/guides/toml-overlay-syntax.md`) without touching any existing agent file. This means the v8 build is **always parseable** after wave 7A completes, even before any agent merges happen.

2. **Agent renames depend on overlay infra.** Each agent rename task (T-003/T-004/T-005) creates a new merged agent that downstream consumers (`/migrate-config --to-v8` per T-006, customization migration logic) will need to apply TOML overlays to. Doing renames first would force `customization/triage-analyst.md` (legacy) to be parsed against an as-yet-undefined TOML schema during a transient window, leaving the working tree in an unverifiable state.

3. **Deprecation alias matrix needs overlay schema as anchor.** REQ-MIG-006 alias matrix requires TOML overlay semantics to be the v8 "primary path" before legacy `.md` can be classified as alias. Doing TOML first makes the alias mapping `(legacy .md) → (v8 .toml)` a pure decoration on a fully-defined target.

4. **Phase 5 test ordering already assumes this.** `v8-overlay-*.sh` tests (8 visible) reference `customization/reviewer.toml` against the merged-but-not-yet-renamed `reviewer.md` (no rename for reviewer). They would still pass under reverse ordering, but `v8-agents-deprecation-alias.sh` and `v8-migrate-config-md-to-toml.sh` REQUIRE the TOML schema to exist BEFORE the rename mapping is exercised.

5. **Phase 6 task DAG enforces it.** T-003/T-004/T-005 declare `depends_on: [T-001]` (TOML parser); T-006 declares `depends_on: [T-001]`. This dependency arrow is the structural enforcement.

**Recommended Phase 7 commit ordering inside `/migrate-config --to-v8` runtime** (REQ-MIG-002 step ordering):
1. Backup `customization/` recursively → `customization.bak-v7-{ISO}/` (REQ-NF-009 atomicity).
2. **Per-file `.md` → `.toml` conversion** (TOML overlay first: every legacy file becomes structured TOML before any rename happens).
3. **Agent rename file moves** (`customization/triage-analyst.toml` → `customization/analyst.toml` with `[applies-when --phase=triage]`-style annotation; `customization/code-analyst.toml` → merge into `customization/analyst.toml`).
4. CLAUDE.md `Skip stages` rewrite (named-phase syntax).
5. Summary report.

**Deprecation alias matrix expressed in this order:**

| User input (v7-shaped) | v8.0.0 runtime behavior | v9.0.0 future |
|------------------------|--------------------------|----------------|
| `customization/reviewer.md` (no rename, only format) | TOML overlay engine parses as raw-append text → WARN | Hard error |
| `customization/triage-analyst.md` (rename + format) | Re-target to merged `analyst` with `--phase triage` mapping → WARN | Hard error |
| `customization/triage-analyst.toml` (rename only) | Re-target to merged `analyst` → WARN | Hard error |
| `customization/reviewer.toml` (v8 native) | Parse + apply (no warn) | Stable |
| `Skip stages: [code-analyst]` | Map to `analyst-impact` → WARN | Hard error |

The alias matrix has full coverage: BOTH formats (`.md` legacy + `.toml` v8) AND BOTH names (deprecated v7 + v8 canonical) for the 6 renamed agents.

---

## 3. Test Coverage Matrix (resolves OQ-INT.2)

Each cell shows the test scenario(s) that verify the row × column combination. Empty cell = no test required (n/a). Source: `.forge/phase-5-tdd/coverage-report.md` + `formal-criteria.md` Section 6.

| Breaking change \ Pipeline × Mode | fix-bugs / yolo | fix-bugs / default | fix-bugs / step-mode | impl-feature / yolo | impl-feature / default | impl-feature / step-mode | scaffold / yolo | scaffold / default | scaffold / step-mode |
|---|---|---|---|---|---|---|---|---|---|
| TOML overlay (.md→.toml dep alias) | v8-matrix-fixbugs-yolo.sh + v8-overlay-* (×8) | v8-matrix-fixbugs-default.sh + v8-overlay-md-toml-coexist.sh | v8-matrix-fixbugs-stepmode.sh + v8-overlay-provenance-log.sh | v8-matrix-implfeat-yolo.sh + v8-overlay-* | v8-matrix-implfeat-default.sh | v8-matrix-implfeat-stepmode.sh | v8-matrix-scaffold-yolo.sh + v8-overlay-* | v8-matrix-scaffold-default.sh | v8-matrix-scaffold-stepmode.sh |
| Agent renames (analyst, test-engineer ext, browser-agent) | v8-matrix-fixbugs-yolo.sh + v8-agents-* (×5) + v8-agents-deprecation-alias.sh | v8-matrix-fixbugs-default.sh + v8-agents-deprecation-alias.sh | v8-matrix-fixbugs-stepmode.sh | v8-matrix-implfeat-yolo.sh | v8-matrix-implfeat-default.sh | v8-matrix-implfeat-stepmode.sh | v8-matrix-scaffold-yolo.sh | v8-matrix-scaffold-default.sh | v8-matrix-scaffold-stepmode.sh |
| SKILL.md decomposition (steps/* path resolution) | v8-matrix-fixbugs-yolo.sh + v8-steps-* (×8) | v8-matrix-fixbugs-default.sh + v8-steps-override-log.sh | v8-matrix-fixbugs-stepmode.sh + v8-steps-default-resolution.sh + v8-steps-override-replace.sh | v8-matrix-implfeat-yolo.sh + v8-steps-* | v8-matrix-implfeat-default.sh | v8-matrix-implfeat-stepmode.sh | v8-matrix-scaffold-yolo.sh + v8-steps-* | v8-matrix-scaffold-default.sh | v8-matrix-scaffold-stepmode.sh |
| Scaffold mode harmonization (B6) | n/a | n/a | n/a | n/a | n/a | n/a | v8-matrix-scaffold-yolo.sh | v8-matrix-scaffold-default.sh + v8-mode-scaffold-vague-skip.sh + v8-mode-vague-heuristic-boundaries.sh + v8-doc-claude-md-scaffold-prose-removed.sh | v8-matrix-scaffold-stepmode.sh |
| Pipeline Profiles named-phase syntax | v8-matrix-fixbugs-yolo.sh + v8-pipeline-profiles-legacy-alias.sh | v8-matrix-fixbugs-default.sh + v8-pipeline-profiles-legacy-alias.sh | v8-matrix-fixbugs-stepmode.sh | v8-matrix-implfeat-yolo.sh | v8-matrix-implfeat-default.sh | v8-matrix-implfeat-stepmode.sh | v8-matrix-scaffold-yolo.sh | v8-matrix-scaffold-default.sh | v8-matrix-scaffold-stepmode.sh |

**Coverage status:** 39 / 39 non-n/a cells covered (100 %). Plus 9-cell mode matrix (AC-MODE-MATRIX-001..009) covered 100 %.

**Hidden adversarial coverage** (12 scenarios; supplemental not-in-matrix):
- TOML overlay edge cases: malformed-recovery (multi-agent isolation), quote-escape, .md/.toml coexist
- Agent rename collisions: triage-analyst + code-analyst → same analyst.toml
- Pipeline Profiles mixed: legacy + new names dedup
- Mode flag idempotency: --yolo --yolo
- Step override edge: zero-pad mismatch ("4-fixer.md")
- Doc enumeration mutation: 19-agent README must FAIL
- Template parity: CRLF vs LF mismatch
- Step-mode resume: off-by-one adversarial guard
- Setup-agents: malicious symlink rejection
- Vague heuristic: 19-word boundary

**Gaps identified (none new):**
- AC-MODE-005 (step-mode 's' escape) had a Round-2 finding (R2 fixed with v8-mode-stepmode-skip-escape.sh).
- AC-NF-006 verified by manual review (no parser name in spec docs) — not testable via bash scenario per coverage-report.md.

The matrix introduces NO new gaps; it preserves the 100 % coverage baseline established in Phase 5.

---

## 4. Risk Register

Per task or task group with rollback strategy if Phase 7 PASS_TO_PASS gate fires (regression in pre-v8 tests during a v8 task's worktree merge).

### 4.1 File deletion risk (T-003, T-004, T-005)

**Risk:** Each agent merge task DELETEs 1–2 source agent files. If the new merged file is malformed or missing required Phase Dispatch section, downstream tasks (T-007/T-008/T-009 SKILL decomposition; T-006 migration helper; T-021 docs/reference/agents.md) would fail to find the expected agent.

**Mitigation:**
- TDD tests (`v8-agents-analyst-shape.sh`, `v8-agents-test-engineer-shape.sh`, `v8-agents-browser-agent-shape.sh`) gate every merge task.
- Phase 7 worktree isolation: each task in its own `.fw/task-{id}/` directory; conflicts surface at merge time (not in-flight).
- `v8-agents-enumeration.sh` set-equality assertion catches missing OR extra agent files.

**Rollback:** Revert the single commit. Git restores all deleted source files (`triage-analyst.md`, `code-analyst.md`, `e2e-test-engineer.md`, `reproducer.md`, `browser-verifier.md`). T-006 deprecation alias logic is unaffected (it accepts both old and new names in v8.0.0).

### 4.2 Schema additivity risk (T-015, T-016)

**Risk:** state.json schema_version stays "1.0" but adds `analyst_*`, `browser_agent_*`, `test_engineer_e2e_invoked` keys. If a v6.x reader accidentally rejects unknown keys (strict-parse), v6.x → v8 backward-read fails.

**Mitigation:**
- AC-NF-007 explicitly tests v6.x and v7.x state.json files are readable by v8 tests (and v8-produced files by v6.x readers).
- `v8-nf-state-additive-readable.sh` exercises this round-trip.
- All v6.x readers are jq-based (lenient); strict-parse risk is theoretical not operational.

**Rollback:** Revert single commit. Schema reverts to 21-agent format. Mid-pipeline state.json files written under v8 with new keys would gain orphan keys, but v8-aware readers ignore unknown keys (jq lenient).

### 4.3 Doc count drift risk (T-021..T-029)

**Risk:** Reference docs (T-021/T-022/T-023/T-024) commit BEFORE top-level docs (T-027/T-028/T-029); during this window, CLAUDE.md may say "21 agents" while docs/reference/agents.md says "18 agents" — invariant temporarily violated.

**Mitigation:**
- Wave 7H is **strictly sequential** (T-027 → T-028 → T-029) — no parallel commits.
- Wave 7G (T-021..T-026) finishes BEFORE Wave 7H begins. CI/Phase 8 gate runs ONLY on the final commit, not on intermediate state.
- T-030 atomic verification at end re-runs `v8-invariant-doc-enumeration-parity.sh` to confirm set-equality across all 5 files. If invariant violated, fix-up commit before release.

**Rollback:** Revert all of T-021..T-029 sequentially; partial rollback is unsafe (would re-introduce drift).

### 4.4 TOML parser failure risk (T-001)

**Risk:** Pure-bash TOML parser (or python3 fallback) has corner cases (triple-quote escape, deeply-nested tables, multi-line strings with embedded `'''`). Failure mode: `customization/{agent}.toml` rejection blocks the entire agent dispatch pipeline.

**Mitigation:**
- REQ-NF-006 mandates parser-tooling neutrality. Phase 6 picks bash + python3 fallback. Phase 7 implementor MAY swap to taplo if bash impl proves brittle (no spec break).
- Hidden test `v8-hidden-toml-malformed-recovery.sh` ensures malformed TOML in ONE agent does NOT corrupt others (per-agent isolation).
- Hidden test `v8-hidden-toml-quote-escape-edge.sh` exercises `"""` round-trip.
- Legacy `.md` overlay path remains FUNCTIONAL as fallback per REQ-OVR-006. If `.toml` parser fails, user can revert to `.md` (with WARN log) without re-running `/migrate-config`.

**Rollback:** Revert T-001 single commit. T-002..T-033 all dependent on T-001 — a T-001 rollback cascades, requiring full v8.0.0 abort (release rollback strategy).

### 4.5 Mode flag exclusivity risk (T-007/T-008/T-009)

**Risk:** `--yolo --step-mode` mutual exclusion check (REQ-MODE-006) is implemented as bash if-then in entry SKILL.md. If implementor uses naive last-wins (`MODE=yolo; MODE=step-mode; … MODE=last`), the explicit error is silently swallowed.

**Mitigation:**
- design.md §5.1 mandates explicit `GOT_YOLO=true; GOT_STEP_MODE=true` boolean tracking AND mutual-exclusion check after the parsing loop.
- T-030 atomic verification includes a lint check: `grep -F 'GOT_YOLO=' skills/{fix-bugs,implement-feature,scaffold}/SKILL.md` returns 3 matches AND same for `GOT_STEP_MODE=`.
- Hidden test `v8-hidden-mode-flag-double-yolo.sh` confirms `--yolo --yolo` is idempotent (NOT mutual-exclusion error) — this catches over-eager checks too.
- Visible test `v8-mode-mutual-exclusion.sh` exercises the canonical conflict.

**Rollback:** Revert one of T-007/T-008/T-009 selectively if only one pipeline broken. T-030 lint catches drift before release.

### 4.6 Plugin permission constraint regression risk (T-003/T-004/T-005)

**Risk:** Newly-merged `agents/analyst.md`, `agents/test-engineer.md`, `agents/browser-agent.md` could accidentally include `hooks:`, `mcpServers:`, or `permissionMode:` keys in YAML frontmatter (copy-paste error from project-level config docs).

**Mitigation:**
- AC-INV-PERM-001 (frontmatter-only grep across all 18 files) gates every commit touching agents/*.md.
- T-030 atomic verification re-runs the full-set check.
- Test scenario `v8-invariant-plugin-perm-constraint.sh` extracts YAML frontmatter via `awk '/^---$/{c++; next} c==1'` (per REQ-NF-003 verification method) and greps; zero matches required.

**Rollback:** Revert offending T-003/T-004/T-005. Pre-v8 source agents (already passing v6.10.0 prompt-injection sweep) are guaranteed compliant.

### 4.7 Migration helper destructive-write risk (T-006)

**Risk:** `/migrate-config --to-v8` could delete original `customization/*.md` files BEFORE backup completes (if backup step fails silently).

**Mitigation:**
- REQ-NF-009 explicit: backup SHALL complete BEFORE any modification.
- AC-MIG-006 (`v8-migrate-config-backup-failure.sh`) simulates `chmod -w customization/` and asserts: zero `.toml` files created AND non-zero exit code.
- AC-NF-009 cross-references AC-MIG-006.

**Rollback:** Revert T-006 single commit. `customization.bak-v7-{ISO}/` directory persists in user projects (small storage cost only); user can manually revert from backup.

### 4.8 Cross-file invariant atomicity risk (T-030)

**Risk:** T-030 re-runs all 5 invariant checks. If any fails (e.g., a stale `21 agents` slipped through CLAUDE.md), Phase 8 gates PASS_TO_PASS at this point.

**Mitigation:**
- T-030 has `depends_on: [T-027, T-028, T-029, T-021, T-022, T-023, T-024]` so all enumerations land FIRST.
- Worktree-isolation: Phase 7 fix-up commit on T-030 worktree is targeted (only the failing file edited).
- Phase 8 verify (commander oracle) blocks release-tag commit if any invariant fails.

**Rollback:** Targeted fix-up commit. NEVER ship inconsistent state — abort v8.0.0 release if invariants are not satisfiable in 1–2 fix-up cycles.

---

## 5. Phase 7 Dispatch Configuration

### 5.1 Recommended Phase 7 parameters

```yaml
total_tasks: 33
mandatory_tasks: 30  # T-012/T-013/T-014 are FOLDED; not separately dispatched
folded_traceability_tasks: [T-012, T-013, T-014]
parallel_groups: 6  # waves 7B, 7C, 7D, 7E (folded), 7F (partial), 7G

worktree_path_template: ".fw/task-{id}/"
revision_cycle_path_template: ".fw/task-{id}-r{cycle}/"

complexity_to_wallclock:
  S: 15min
  M: 45min
  L: 90min

wave_layout:
  - wave: 7A
    tasks: [T-001, T-002]
    sequential_within_wave: true
    estimated_wallclock: 90min  # M + M, T-002 depends on T-001

  - wave: 7B
    tasks: [T-003, T-004, T-005, T-006]
    parallel: 4
    estimated_wallclock: 90min  # max of M, M, M, L = L = 90min

  - wave: 7C
    tasks: [T-007, T-008, T-009]
    parallel: 3
    estimated_wallclock: 90min  # max of L, L, L = 90min

  - wave: 7D
    tasks: [T-010, T-011]
    parallel: 2
    estimated_wallclock: 45min  # max of M, S = M = 45min

  - wave: 7E
    tasks: []  # T-012/T-013/T-014 are folded into 7C
    sequential_within_wave: false
    estimated_wallclock: 0min  # absorbed in 7C

  - wave: 7F
    tasks: [T-015, T-016]
    parallel: 2  # T-016 depends on T-015 logically; in-wave still treats as 2 worktrees
    sequential_within_wave: true  # T-015 → T-016
    estimated_wallclock: 60min  # M + S sequential

  - wave: 7G
    tasks: [T-017, T-018, T-019, T-020, T-021, T-022, T-023, T-024, T-025, T-026]
    parallel: 10
    estimated_wallclock: 90min  # max M = 45min; some L-leaning give buffer

  - wave: 7H
    tasks: [T-027, T-028, T-029]
    parallel: 1  # strictly sequential
    sequential_within_wave: true
    estimated_wallclock: 135min  # M + M + M cumulative

  - wave: 7I
    tasks: [T-030]
    parallel: 1
    estimated_wallclock: 30min  # S, but may include fix-up

  - wave: 7J
    tasks: [T-031, T-032, T-033]
    parallel: 3
    estimated_wallclock: 45min  # max of M, S, S = M

total_estimated_wallclock_critical_path: ~10h  # accounting for revision-cycle margins
```

### 5.2 Worktree isolation guarantees

For every parallel pair `(T-X, T-Y)` listed in `parallelizable_with`, `files_modified(T-X) ∩ files_modified(T-Y) = ∅`. Verified by inspection in Section 1.

Notable cases:
- T-003/T-004/T-005 all touch `agents/` but disjoint files (analyst vs test-engineer vs browser-agent).
- T-021/T-022/T-023/T-024 all touch `docs/reference/` but disjoint files.
- T-007/T-008/T-009 each touches one `skills/{X}/SKILL.md` + new `skills/{X}/steps/*` directory — fully disjoint per pipeline.

### 5.3 Phase 7 status.json contract

Each worktree writes `status.json` at exit with at minimum:
```json
{
  "task_id": "T-007",
  "outcome": "passed | revision_needed | failed",
  "files_modified": ["skills/fix-bugs/SKILL.md", "skills/fix-bugs/steps/01-triage.md", "..."],
  "tests_run": ["tests/scenarios/v8-steps-entry-thinness.sh", "..."],
  "tests_passed": 11,
  "tests_failed": 0,
  "wallclock_seconds": 4523,
  "revision_cycles": 0
}
```
Phase 8 finding-to-task mapping reads `files_modified` to attribute regression findings to the correct worktree.

### 5.4 Test execution gate (per task)

Each Phase 7 worktree MUST run `tests/harness/run-tests.sh --filter v8-` (filtered to v8-* scenarios) AFTER applying its commits. Tasks with empty `test_files_pass` (e.g., T-030 verification) run a SUBSET of tests scoped to the invariant being verified.

### 5.5 Revision cycle policy

If a task fails its `test_files_pass` set:
- Cycle 1 (R1): Phase 7 dispatches `revision-1` agent into `.fw/task-{id}-r1/` worktree with failure log + spec context.
- Cycle 2 (R2): if R1 still fails, escalate to opus model.
- Cycle 3 (R3): if R2 fails, BLOCK at Gate 3 / Gate 4 for user intervention.

---

## 6. Task-to-AC Bidirectional Coverage Index

(Audit aid — every AC mapped to ≥ 1 task; every task references ≥ 1 AC.)

### 6.1 AC → Task index (coverage check)

| AC group (count) | Primary task(s) |
|------------------|-----------------|
| AC-OVR-001..008 (8) | T-001 |
| AC-SETUP-001..008 (8) | T-010 |
| AC-STEPS-001..007 + AC-STEPS-003a (8) | T-007, T-008, T-009 |
| AC-MODE-001..009 + AC-MODE-008a (11) | T-007, T-008, T-009 (folded T-012..T-014); T-016 (state side) |
| AC-AGT-001..009 (9) | T-003, T-004, T-005, T-006, T-015, T-016 |
| AC-MIG-001..007 (7) | T-006 |
| AC-DOC-001..014b (14) | T-002, T-011, T-017, T-018, T-019, T-020, T-021, T-022, T-023, T-024, T-025, T-027, T-028, T-029 |
| AC-INV-LICENSE-001 (1) | T-030 |
| AC-INV-EMAIL-001 (1) | T-030 |
| AC-INV-TEMPLATE-001 (1) | T-030 |
| AC-INV-DOC-ENUM-001 (1) | T-021, T-022, T-023, T-024, T-027, T-028, T-029, T-030 |
| AC-INV-PERM-001 (1) | T-003, T-004, T-005, T-030 |
| AC-CT-001..005 (5) | T-003, T-004, T-005, T-010, T-023, T-025, T-030 |
| AC-MODE-MATRIX-001..009 (9) | T-007, T-008, T-009 |
| AC-NF-001..010 (10) | T-001, T-003..T-005, T-010, T-015, T-029, T-030, T-031 |

**Total ACs: 94. Total ACs with ≥ 1 task mapping: 94. Coverage: 100 %.**

### 6.2 Task → AC index (no orphan tasks)

| Task | Primary ACs |
|------|-------------|
| T-001 | AC-OVR-001..008, AC-NF-001, AC-NF-006 |
| T-002 | AC-DOC-002, AC-OVR-003 |
| T-003 | AC-AGT-001..003, AC-NF-004, AC-INV-PERM-001 |
| T-004 | AC-AGT-001/002/004, AC-NF-004, AC-INV-PERM-001 |
| T-005 | AC-AGT-001/002/005, AC-NF-004, AC-INV-PERM-001 |
| T-006 | AC-MIG-001..007, AC-AGT-006, AC-NF-009 |
| T-007 | AC-STEPS-001..007 + 003a, AC-MODE-001..007 + 008a, AC-MODE-MATRIX-001..003 |
| T-008 | AC-STEPS-001/002/007, AC-MODE-001..005 + 008a, AC-MODE-MATRIX-004..006 |
| T-009 | AC-STEPS-001/002/007, AC-MODE-001..005 + 008/009 + 008a, AC-MODE-MATRIX-007..009 |
| T-010 | AC-SETUP-001..008 |
| T-011 | AC-DOC-011 |
| T-012/13/14 | (folded — traceability to AC-MODE-001..003/008/009) |
| T-015 | AC-AGT-007/008, AC-NF-007 |
| T-016 | AC-AGT-009 |
| T-017 | AC-DOC-001 |
| T-018 | AC-DOC-003 |
| T-019 | AC-DOC-004, AC-STEPS-006 |
| T-020 | AC-DOC-009 |
| T-021 | AC-DOC-005 |
| T-022 | AC-DOC-006 |
| T-023 | AC-DOC-007, AC-CT-003, AC-INV-PERM-001 (doc pointer) |
| T-024 | AC-DOC-008 |
| T-025 | AC-DOC-010, AC-CT-005 |
| T-026 | AC-AGT-006, AC-MIG-007 |
| T-027 | AC-DOC-005, AC-DOC-006, AC-DOC-014b, AC-INV-DOC-ENUM-001 |
| T-028 | AC-DOC-012, AC-INV-DOC-ENUM-001 |
| T-029 | AC-DOC-013 |
| T-030 | AC-INV-LICENSE/EMAIL/TEMPLATE/DOC-ENUM/PERM-001, AC-NF-010 |
| T-031 | AC-NF-005, AC-NF-008 |
| T-032 | AC-NF-005 |
| T-033 | AC-SETUP-002/003, AC-OVR-001..008, AC-MIG-001..007, AC-NF-005 |

No orphan tasks. No orphan ACs.

---

## 7. Open Issues / Known Limitations

### 7.1 Recommended fold of T-012/T-013/T-014

T-012/T-013/T-014 are **traceability handles**, not separate Phase 7 worktrees. Phase 7 dispatcher should mark `status="folded"` for these IDs and treat T-007/T-008/T-009 as the implementing tasks. Plan retains separate IDs for AC-mapping clarity.

### 7.2 core/ count preservation (T-026)

T-026 introduces a new alias-mapping contract. To preserve `find core -maxdepth 1 -name '*.md' -type f | wc -l == 16` (per AC-CT-004), the new contract MUST go under `core/aliases/agents-rename-aliases.md` (sub-namespace, not top-level), OR be folded as a new section into existing `core/agent-states.md`. **Phase 7 implementor SHALL pick one and verify maxdepth-1 count BEFORE commit.**

### 7.3 Manual-review-only AC

AC-NF-006 (no parser name in spec) is verified by manual review during Phase 8 (per coverage-report.md §AC-NF-006). Bash-scenario verification deemed disproportionate.

### 7.4 mock-project CLAUDE.md modification (T-033)

T-033 modifies `tests/mock-project/CLAUDE.md` to add `### Pipeline Profiles` with v8 syntax. This is a fixture, not production config; does not interact with real automation config.

### 7.5 Phase 5 staging path REPO_ROOT issue

Coverage-report.md notes tests CANNOT run from `.forge/phase-5-tdd/tests/` staging (REPO_ROOT resolves to `.forge/`). Defensive guard `exit 1` in every test enforces this. T-031/T-032 move tests to `tests/scenarios/`; ONLY then are tests runnable via the harness.

### 7.6 Phase 7 dispatch ordering tip

Recommended Phase 7 wave dispatch:
1. Wave 7A (T-001 then T-002) — sequential.
2. Wave 7B (T-003, T-004, T-005, T-006) — 4 parallel; T-006 may finish later (L vs M).
3. Wave 7C (T-007, T-008, T-009) — 3 parallel; longest wave.
4. Wave 7D (T-010, T-011) — 2 parallel.
5. Wave 7G (T-017..T-026) — 10 parallel docs; intentionally before Wave 7H sequential top-level docs.
6. Wave 7F (T-015, T-016) — sequential within wave; can run concurrently with Wave 7G.
7. Wave 7H (T-027 → T-028 → T-029) — strictly sequential.
8. Wave 7I (T-030) — atomic invariant verification.
9. Wave 7J (T-031, T-032, T-033) — 3 parallel test integration.

---

**End of plan.md.**
