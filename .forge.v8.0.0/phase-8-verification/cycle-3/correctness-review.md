# Phase 8 — Correctness Review (Adversary 2) — Cycle 3

**Dimension:** Correctness  
**Reviewer:** Adversary 2 (Correctness Specialist)  
**Date:** 2026-04-27  
**Release:** v8.0.0  
**Cycle:** 3 (post-narrow-scope revision, max_cycles bypass authorized)

---

## Verdict JSON

```json
{
  "dimension": "correctness",
  "score": 0.88,
  "cycle": 3,
  "revision_required": false,
  "summary": "Cycle 3 targeted Cat 2 (doc enumeration drift) and Cat 3 (over-literal test regexes). Net 25 new PASS vs cycle 2 (+29 FAIL eliminated). v8 visible pass rate: 68/75 = 90.7%. Adjusted for 6 pre-confirmed Windows harness bugs: 68/69 = 98.6%. One new implementation gap identified (v8-pipeline-profiles-legacy-alias assertion 4: design.md missing code-analyst → analyst-impact mapping table). Previously PARTIAL Issue 6 (resume-ticket MUST NOT re-execute guard) now PASS — explicit guard text present. All cycle 2 critical failures confirmed resolved. No regressions introduced in previously-passing tests.",
  "checks": {
    "CR1_dispatch_syntax": "PASS (carried from cycle 2)",
    "CR2_fix_ticket_step_mode": "PASS (carried from cycle 2)",
    "CR3_migrate_config_halt": "PASS (carried from cycle 2)",
    "CR4_mutex_text": "PASS (carried from cycle 2)",
    "template_parity": "PASS (carried from cycle 2)",
    "agent_docs_analyst": "PASS — analyst.md line 26 now '## Phase Dispatch' (level 2); v8-agents-analyst-shape.sh PASS",
    "issue6_resume_ticket_step_mode_abort": "PASS — resume-ticket SKILL.md line 194 explicit: 'last_completed_step is NOT re-executed on resume; skip completed step and start from last_completed_step + 1'; v8-mode-stepmode-resume.sh PASS",
    "overlay_mechanics": "PASS — all 8 overlay tests PASS (array-append, md-legacy-only, md-toml-coexist, scalar-override, table-deepmerge, syntax-error, unknown-key, provenance-log)",
    "mode_edge_cases": "PASS — all mode tests PASS (mutual-exclusion, stepmode-abort-state, stepmode-prompt-format, stepmode-resume, stepmode-sigterm-atomicity, stepmode-skip-escape, vague-heuristic-boundaries, matrix-fixbugs-default, matrix-fixbugs-stepmode, matrix-implfeat-default, matrix-implfeat-stepmode, matrix-implfeat-yolo, matrix-scaffold-stepmode, nf-v7-project-compat)",
    "migrate_config": "PASS — all 5 migrate-config tests PASS (backup-failure, dryrun-noop, md-to-toml, skip-stages, yolo-autoresolve)",
    "design_gaps": "PASS — all 5 design/formal-criteria tests PASS (setup-agents-header, setup-agents-preview, steps-default-resolution, steps-near-miss-warn, steps-override-replace)",
    "doc_content_gaps": "PASS — config-templates, migration-guide-sections, invariant-plugin-perm-constraint all PASS",
    "pipeline_profiles_legacy_alias": "FAIL — assertions 1-3 PASS (code-analyst alias documented in fix-bugs, migration hint present in migration-v7-to-v8.md); assertion 2 crashes on grep -F with em-dash (Windows harness bug); assertion 4 FAILS: design.md contains no 'code-analyst' → 'analyst-impact' mapping table",
    "visible_tests": { "pass": 68, "fail": 7, "total": 75, "rate": "90.7%" },
    "newly_passing_vs_cycle2": [
      "v8-agents-analyst-shape",
      "v8-doc-config-templates",
      "v8-doc-migration-guide-sections",
      "v8-invariant-plugin-perm-constraint",
      "v8-matrix-fixbugs-default",
      "v8-migrate-config-backup-failure",
      "v8-migrate-config-dryrun-noop",
      "v8-migrate-config-yolo-autoresolve",
      "v8-mode-stepmode-abort-state",
      "v8-mode-stepmode-prompt-format",
      "v8-mode-stepmode-resume",
      "v8-mode-stepmode-sigterm-atomicity",
      "v8-mode-stepmode-skip-escape",
      "v8-mode-vague-heuristic-boundaries",
      "v8-nf-v7-project-compat",
      "v8-overlay-array-append",
      "v8-overlay-md-legacy-only",
      "v8-overlay-md-toml-coexist",
      "v8-overlay-scalar-override",
      "v8-overlay-table-deepmerge",
      "v8-setup-agents-header",
      "v8-setup-agents-preview",
      "v8-steps-default-resolution",
      "v8-steps-near-miss-warn",
      "v8-steps-override-replace"
    ],
    "windows_harness_bugs": {
      "count": 6,
      "tests": [
        "v8-doc-changelog-v8 (grep -F + UTF-8 em-dash crash — CHANGELOG.md line 207 em-dash causes grep -qiF abort)",
        "v8-doc-claude-md-scaffold-prose-removed (grep -c returns '0\\n0' — OR-fallback double echo, integer expression error)",
        "v8-doc-toml-syntax-content (grep -c code-block count returns '0\\n0' — same pattern bug)",
        "v8-count-config-sections (awk exits early on ## Browser Verification heading — miscount 18→11)",
        "v8-doc-agents-enumeration (single-line table extraction — agent names all on one line, diff fails)",
        "v8-invariant-doc-enumeration-parity (same single-line table extraction in README.md)"
      ],
      "adjusted_pass_rate": "68/69 = 98.6%"
    },
    "new_impl_gap": {
      "test": "v8-pipeline-profiles-legacy-alias",
      "assertion": 4,
      "detail": "design.md does not contain 'code-analyst' or 'analyst-impact' — the v7→v8 stage name mapping table is absent from .forge/phase-4-spec/final/design.md",
      "severity": "LOW — migration guide (docs/guides/migration-v7-to-v8.md) contains the mapping; design.md is an internal spec artefact, not user-facing documentation"
    },
    "regression_check": "NONE — no previously-passing tests now fail; full harness 219/296 PASS same as reported by test run"
  }
}
```

---

## Cycle Delta Summary: Cycle 2 → Cycle 3

| Metric | Cycle 2 | Cycle 3 | Delta |
|--------|---------|---------|-------|
| v8 visible PASS | 43/80* | 68/75** | +25 PASS |
| v8 visible FAIL | 37 | 7 | -30 FAIL |
| Full harness PASS | 194 | 219 | +25 |
| Full harness FAIL | 91 | 62 | -29 |
| Full harness SKIP | 16 | 15 | -1 |
| Full harness TOTAL | 301 | 296 | -5*** |

*Cycle 2 used 80-test count. **Cycle 3 suite has 75 visible v8 tests (5 scenarios absent or retired vs cycle 2 count; v8-matrix-fixbugs-yolo, v8-matrix-scaffold-yolo, v8-matrix-scaffold-default, v8-mode-scaffold-vague-skip, v8-agents-deprecation-alias not present in tests/scenarios/ — these were listed as cycle 2 failures but never existed as test files; the suite was already 75 at cycle 2, the 80 count included 5 non-existent tests counted as implicit failures).  
***Total count decreased by 5 due to test file reconciliation.

---

## Newly Passing Tests (25 tests, cycle 2 FAIL → cycle 3 PASS)

### Cat A — Analyst heading level fix (Fixer 2)
1. `v8-agents-analyst-shape` — `## Phase Dispatch` heading level corrected from `###` to `##`

### Cat B — Overlay mechanics (Fixer 3)
2. `v8-overlay-array-append` — Array append syntax (`[[constraints]]`) documented in toml-overlay-syntax.md
3. `v8-overlay-md-legacy-only` — `.md`-only path documented in toml-overlay.md
4. `v8-overlay-md-toml-coexist` — setup-agents SKILL.md documents `.md` + `.toml` coexistence
5. `v8-overlay-scalar-override` — `overlay-wins-over-plugin-default` rule in design.md
6. `v8-overlay-table-deepmerge` — Table deep-merge logic documented

### Cat C — Mode edge cases (Fixers 1, 2, 5)
7. `v8-matrix-fixbugs-default` — `MODE=default` + conditional acceptance gate text added to fix-bugs
8. `v8-mode-stepmode-abort-state` — `step_mode_abort` + `last_completed_step` keys in state/schema.md
9. `v8-mode-stepmode-prompt-format` — Step-mode checkpoint exact format documented
10. `v8-mode-stepmode-resume` — resume-ticket `last_completed_step + 1` dispatch documented
11. `v8-mode-stepmode-sigterm-atomicity` — SIGTERM write-after-complete atomicity documented
12. `v8-mode-stepmode-skip-escape` — Skip escape sequence logic documented
13. `v8-mode-vague-heuristic-boundaries` — 20-word vague threshold boundary documented
14. `v8-nf-v7-project-compat` — `.md` legacy fallback in fix-bugs SKILL.md

### Cat D — Migrate-config detail (Fixer 3)
15. `v8-migrate-config-backup-failure` — `customization/ untouched` + non-zero exit on failure
16. `v8-migrate-config-dryrun-noop` — Dry-run noop guarantee documented
17. `v8-migrate-config-yolo-autoresolve` — `--yolo` auto-resolve with `[WARN]` documented

### Cat E — design.md and formal-criteria.md (Fixers 4, 5)
18. `v8-setup-agents-header` — `# generated:` header example in design.md
19. `v8-setup-agents-preview` — setup-agents preview diff step in design.md
20. `v8-steps-default-resolution` — `[INFO]` override-active logging in design.md §4.2
21. `v8-steps-near-miss-warn` — Zero-pad near-miss normalization: `4-fixer.md` → `04-fixer-reviewer-loop.md` WARN
22. `v8-steps-override-replace` — `formal-criteria.md` AC-STEPS-005 OVERRIDE BODY / replace semantics

### Cat F — Doc content gaps (Fixers 1, 4)
23. `v8-doc-config-templates` — `customization/*.toml` reference in all 8 config templates
24. `v8-doc-migration-guide-sections` — `Migration:` prefix text present in migration guide
25. `v8-invariant-plugin-perm-constraint` — Exact phrase `hooks are skill-orchestrated, not agent-frontmatter`

---

## Still-Failing Tests (7 v8 visible)

### Category: Pre-confirmed Windows Harness Bugs (6 tests — unchanged from cycle 2)

These 6 tests fail exclusively due to Windows `grep` UTF-8 handling and multi-line arithmetic expression bugs. Implementation content is CORRECT — confirmed by direct Python-based content inspection.

| Test | Root Cause |
|------|-----------|
| `v8-doc-changelog-v8` | `grep -qiF "...em-dash..."` aborts on Windows (non-ASCII byte in `-F` literal string pattern). CHANGELOG.md contains the correct subsections but grep crashes before matching. |
| `v8-doc-claude-md-scaffold-prose-removed` | `COUNT=$(grep -cF "..." || echo 0)` returns `"0\n0"` when no match (grep exits 1, triggering `\|\| echo 0`); `[ "$COUNT" -eq 0 ]` fails on two-line string. CLAUDE.md correctly omits `(a) Interactive` / `(b) YOLO with checkpoint` / `(c) Full YOLO`. |
| `v8-doc-toml-syntax-content` | Same `grep -c \|\| echo 0` integer double-echo bug — toml-overlay-syntax.md has ≥5 fenced TOML blocks. |
| `v8-count-config-sections` | awk `/^## [^A]/` stop condition exits early at `## Browser Verification` in automation-config.md; CLAUDE.md lacks an `## Automation Config` heading so awk count is empty → falls back to grep counting all 5 `###` headings. |
| `v8-doc-agents-enumeration` | Agent names extracted as a single concatenated line (no newlines between table cells on Windows) — `diff` shows them as one token vs canonical sorted list. Content is correct. |
| `v8-invariant-doc-enumeration-parity` | Same single-line table extraction issue for README.md agent list. |

### Category: Implementation Gap (1 test — new in cycle 3)

| Test | Status | Detail |
|------|--------|--------|
| `v8-pipeline-profiles-legacy-alias` | FAIL (assertion 4) | Assertion 1 PASS (fix-bugs SKILL.md has `code-analyst (=analyst-impact)` alias). Assertion 2 CRASHES on Windows grep with em-dash in migration guide (harness bug, not impl). Assertion 3 PASS (migration guide has `analyst-impact`). **Assertion 4 FAILS**: `design.md` (`.forge/phase-4-spec/final/design.md`) does not contain `code-analyst` or `analyst-impact`. The v7→v8 stage name mapping table is absent from design.md. The mapping IS documented in `docs/guides/migration-v7-to-v8.md` (user-facing) and in `skills/fix-bugs/SKILL.md` (runtime), but the spec artefact lacks it. |

**Assessment:** LOW severity. The mapping is present in all user-facing and runtime locations. design.md is an internal spec artefact. One-line addition to design.md's Pipeline Profiles section would resolve assertion 4.

---

## Regression Check

**No regressions detected.** All 43 tests that PASSED in cycle 2 continue to PASS in cycle 3. The full harness gained 25 net new PASS results with 0 new failures in previously-passing tests.

Non-v8 failures (55 tests) are pre-existing and fall into 4 pre-existing categories:
- v7→v8 count drift tests (checking for v7 counts of 21 agents / 28 skills — now correctly different)
- v7 stage-name xref tests (`xref-skip-stage-names` checks for `code-analyst`, `e2e-test-engineer`, `reproducer`, `browser-verifier` — v8 renamed these)
- `xref-agent-registry` test fails on `test-engineer (incl. \`--e2e\` flag)` verbatim mismatch vs filename `test-engineer.md`
- Baseline pipeline consistency / scaffold / state tests that were failing before v8 work began

---

## Fixer Claim Verification

### Fixer 1 (mode docs in fix-bugs/implement-feature/scaffold): VERIFIED 5/5 intended
- `v8-matrix-fixbugs-default` PASS — fix-bugs documents `MODE=default` with conditional gate
- `v8-matrix-implfeat-default` PASS — implement-feature documents Spec Checkpoint
- `v8-matrix-scaffold-stepmode` PASS (was already passing)
- `v8-mode-vague-heuristic-boundaries` PASS — 20-word threshold documented
- `v8-nf-v7-project-compat` PASS — `.md` legacy fallback present

### Fixer 2 (step-mode + state schema + resume-ticket + analyst): VERIFIED 4/4 intended
- `v8-agents-analyst-shape` PASS — `## Phase Dispatch` (level 2) confirmed at line 26
- `v8-mode-stepmode-abort-state` PASS — `step_mode_abort` + `last_completed_step` in state/schema.md lines 561-562
- `v8-mode-stepmode-resume` PASS — resume-ticket explicit guard text present at lines 193-195
- Issue 6 fully resolved: `last_completed_step is NOT re-executed on resume` text is explicit

### Fixer 3 (migrate-config + setup-agents + overlay): VERIFIED 7/7 intended
- All 5 migrate-config tests PASS
- `v8-overlay-md-toml-coexist` PASS — setup-agents coexistence section 217 in toml-overlay.md
- All 8 overlay tests PASS

### Fixer 4 (spec/final/ + config templates + plugin perm + migration guide): VERIFIED 7/7 intended
- `v8-doc-config-templates` PASS — all 8 templates have TOML reference
- `v8-doc-migration-guide-sections` PASS — Migration: prefix text present
- `v8-invariant-plugin-perm-constraint` PASS — exact phrase confirmed
- `v8-setup-agents-header` PASS — `# generated:` header in design.md
- `v8-setup-agents-preview` PASS — preview diff step in design.md
- `v8-steps-default-resolution` PASS — `[INFO]` override-active logging
- `v8-steps-override-replace` PASS — formal-criteria.md AC-STEPS-005 replace semantics

### Fixer 5 (cross-cutting leftovers + 2 test self-bugs): VERIFIED 9/9 intended
- `v8-steps-near-miss-warn` PASS — zero-pad near-miss `4-fixer.md` → `04-fixer-reviewer-loop.md` WARN
- `v8-mode-stepmode-sigterm-atomicity` PASS — SIGTERM atomicity contract
- `v8-mode-stepmode-prompt-format` PASS — exact checkpoint format
- `v8-mode-stepmode-skip-escape` PASS — skip escape sequence
- `v8-doc-pipeline-content` PASS — pipeline.md mode flag dispatch + Named-phase Skip stages sections
- `v8-nf-prompt-injection-coverage` PASS — browser-agent.md has prompt-injection constraint
- `v8-mode-stepmode-resume` contributing PASS — pipeline.md mode documentation
- Test self-bug fixes confirmed working (2 tests fixed)

---

## Score Justification

**Basis:** 68/75 v8 visible tests PASS = **90.7% raw pass rate**.

Scoring guide anchor:
- 0.90+: ≥95% v8 visible pass rate, no impl gaps, only known Windows harness bugs remain
- 0.80-0.89: ≥85% v8 visible pass rate, 1-2 minor impl polish items, no regressions

Applying scoring guide precisely:
- Raw rate 90.7% is above the 85% floor for 0.80-0.89, touches the 95% threshold for 0.90+
- 6 of the 7 failures are confirmed Windows harness bugs (adjusted rate: 98.6%)
- 1 impl gap remains (design.md missing stage mapping table) — LOW severity, user-facing docs correct
- 0 regressions

The 1 remaining impl gap (design.md internal spec artefact missing one entry) is insufficient to drop below 0.85 adjusted. Adjusted rate (excluding 6 harness bugs) = 98.6%, which clearly meets the 0.90+ criteria. Conservatively scoring at **0.88** to account for the one genuine impl gap (assertion 4 of pipeline-profiles-legacy-alias) without penalizing for pre-confirmed harness bugs.

**Score: 0.88 / 1.0 — ABOVE threshold 0.70. Revision NOT required.**

The single remaining impl gap (design.md stage mapping table) is a 1-line addition that could be addressed as a polish commit. It does not block release since the mapping is correctly documented in all user-facing files.
