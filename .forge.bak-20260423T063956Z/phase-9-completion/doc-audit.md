# Documentation Consistency Audit — ceos-agents v6.9.0

STRUCTURAL_METRICS_SKIP reason=no_oracle_script

## Audit results

| File | Check | Status | Notes |
|------|-------|--------|-------|
| CLAUDE.md | "16 core contracts" | PASS | Line 27: `core/ — 16 shared pipeline pattern contracts` |
| CLAUDE.md | "19 optional sections" | PASS | Line 160: `There are 19 optional config sections in total.` |
| CLAUDE.md | "29 skills" | PASS | Line 18: `skills/ — 29 skills (slash commands, including workflow-router)` |
| CLAUDE.md | Cross-File Invariants subsection | PASS | Line 245: `## Cross-File Invariants` with 3 invariants + feedback_doc_completeness.md pointer |
| CLAUDE.md | Pause Limits row | PASS | Line 158: `\| Pause Limits \| Pause timeout \| 30 days \|` |
| README.md | "29 skills" (NOT 28) | PASS | Lines 3, 10, 260: all say 29 |
| README.md | LICENSE link | PASS | Line 282: `[MIT License](LICENSE)` |
| README.md | SECURITY.md link | PASS | Line 284: `see [SECURITY.md](SECURITY.md)` |
| CHANGELOG.md | v6.9.0 entry exists | PASS | Line 10: `## [6.9.0] — 2026-04-20` with Added/Changed/Migration notes/Known Issues/Internal sections |
| docs/plans/roadmap.md | v6.9.0 SHIPPED | PASS | Line 744: `## SHIPPED — v6.9.0 (Pipeline Intelligence + OSS Readiness) — 2026-04-20` |
| docs/plans/roadmap.md | v6.9.1 deferrals present | PASS | Lines 793–808: `## PLANNED — v6.9.1` with canonical URL, secondary contact, circuit breaker persistence, multi-host lock |
| docs/architecture.md | 29 skills | PASS | Line 27 (mermaid): `SKL[29 Skills]` |
| docs/architecture.md | 16 core contracts | PASS | Line 73: `**16 core contracts**` and line 284: `**16 shared pipeline pattern contracts**` |
| docs/architecture.md | NEEDS_CLARIFICATION node | PASS | Line 39 (mermaid): `PAUSE["NEEDS_CLARIFICATION<br/>(pause state)"]` and line 74: textual description |
| docs/reference/skills.md | --format json documented | PASS | Line 577: example `--period 14 --format json --output metrics.json` |
| docs/reference/skills.md | pipeline-history pointer | PASS | Lines 572–573: full pipeline-history.md description with cross-link to core/post-publish-hook.md Section 5 |
| docs/reference/automation-config.md | 19 optional sections | PASS | Line 9: `There are 5 required sections and 19 optional sections.` |

## F-DOC-1 — sanitize_block_reason() pattern count (14 → 17)

**Finding:** 4 production docs cited "14-pattern" (the count before cycle-1 expanded it to 17):
- `state/schema.md` line 363
- `docs/guides/installation.md` line 84
- `docs/plans/roadmap.md` line 763
- `docs/reference/skills.md` line 572

**Action taken in Phase 9:** All 4 fixed in-place to "17-pattern". These are small mechanical edits that do not change behavior — they correct a factual doc drift introduced when cycle-1 expanded the pattern count from 14 to 17 but did not propagate the update to all doc sites.

**CHANGELOG.md — NOT fixed (per Phase 9 spec restriction):**
CHANGELOG.md lines 24 and 40 still reference "14 credential patterns" / "14 patterns". These are historical records of the v6.9.0 initial design intent. The CHANGELOG is an append-only record — updating it would misrepresent the sequence of events. Recommendation: add a note to the v6.9.1 CHANGELOG entry that v6.9.0's `sanitize_block_reason()` shipped with 14 patterns at GA and was extended to 17 in the same release cycle (during Phase 8 robustness revision).

## F-DOC-2 — Carry-over LOW findings from cycle-1 (deferred, no action required)

Per commander-verdict.md cycle-1 carry-overs — these are acknowledged v6.9.1 polish items, not Phase 9 doc-audit issues:

- Snippet marker drift: some older `@snippet:` markers may have slight naming drift. Non-blocking.
- AWS_VAR overlap with LOWER-VAR in `sanitize_block_reason()`: no credential leak, cosmetic pattern overlap.
- Missing `pipeline-resumed` event: the resume flow is documented but no webhook event fires on resume. Deferred.
- `Webhook_URL` casing inconsistency in docs: some prose uses `Webhook URL`, some `Webhook_URL`. Deferred.

## Overall verdict

All required audit checks: **PASS** (17/17).
Doc-audit fixes applied: **4** (F-DOC-1 — 14-pattern → 17-pattern in state/schema.md, docs/guides/installation.md, docs/plans/roadmap.md, docs/reference/skills.md).
Recommendations forwarded: 1 (CHANGELOG.md historical note for v6.9.1 entry).

doc-audit ✅
