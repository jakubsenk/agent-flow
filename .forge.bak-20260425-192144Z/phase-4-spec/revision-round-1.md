# Phase 4 Spec — Revision Round 1 Changelog

**Forge run:** `forge-2026-04-23-002`
**Revision date:** 2026-04-23
**Author:** Phase 4 Revision Agent
**Trigger:** Round 1 review FAILS from quality reviewer (2) + devil's advocate reviewer (3); compliance reviewer (1) PASS.
**Scope:** Fix 10 findings (F1-F10) without introducing new scope.

---

## Per-finding resolution

### F1 — REQ-T1-1 RETIRE count contradiction → FIXED
**Change:** Header of REQ-T1-1 freezes RETIRE at **4 scenarios** (not 5). Inlined rationale citing Phase 2 §T1-Q2 enumeration (a)-(d) as authoritative; (e) was reclassified to KEEP. Added "source-of-truth rationale" paragraph explaining that Phase 2 synthesis's "5" was a double-count.
**Files:** `requirements.md` REQ-T1-1 (~lines 86-97); Scope Freeze reconciliation arithmetic (~lines 18-58). AC-T1-1-1/2 in `formal-criteria.md` already referenced 4 paths (no change needed).

### F2 — Orphan scenarios (pipeline-history-pii-scope, pipeline-paused-webhook) → FIXED
**Change:** Both orphan scenarios were classified REWRITE in Phase 2 table. Added to REQ-T1-2 as entries #15 and #16, raising REWRITE count from 14 → 16 (honors user Gate 1 "ALL candidates" override intent). Phase 2 synthesis's "14" was corrected to "16" per Phase 2 TABLE authority.
**Files:** `requirements.md` REQ-T1-2 (~lines 99-120); Scope Freeze counts; `traceability.md` §A rows #15/#16 (~lines 54-55); `traceability.md` Existing-scenarios list #19/#20 (~lines 136-138); `design.md` §4.2 V6100_TOUCHED array (16 REWRITE entries).

### F3 — Harness count reconciliation (186 vs 204) → FIXED
**Change:** Froze at **204 hard equality** (185 baseline + 19 net-new). REQ-T1-9 prose rewritten with first-principles calculation. AC-T1-9-1 changed from "≥ 186" to "== 204". Design §8.4 net-new table now enumerates all 19 with line items. Traceability harness-count note aligned.
**Files:** `requirements.md` REQ-T1-9 (~lines 173-191); `formal-criteria.md` AC-T1-9-1/2 (~lines 91-97); `design.md` §8.4 (expanded to full 19-row table); `traceability.md` harness-count note (~lines 186-188).

### F4 — V6100_TOUCHED unified scope definition → FIXED
**Change:** Added formal `V6100_TOUCHED` set definition at top of Track 1 scope in requirements.md §1 (Scope Freeze). Propagated single reference in REQ-T1-5, REQ-T1-7, AC-T1-5-1, AC-T1-7-1/2, design §4.2. All previous "touched tests" wording now cites `V6100_TOUCHED`.
**Files:** `requirements.md` §1 Scope Freeze V6100_TOUCHED definition (~lines 42-58); REQ-T1-5 (~line 140); REQ-T1-7 (~line 155); `formal-criteria.md` AC-T1-5-1 + AC-T1-7-1/2; `design.md` §4.2 expanded with full 50-entry TOUCHED_SCENARIOS array.

### F5 — AC-T2-8-1 research-artifact schema → FIXED
**Change:** AC-T2-8-1 now asserts against 5 named sections + ≥3 external citations + Confidence declaration (per design.md §10). Declared HIGH confidence is machine-checkable via grep pattern. Added design.md §10 "Research Artifact Schema" with full markdown schema for both research deliverables (dispatch-hook-api.md, autopilot-hook-interaction.md). Phase 4-vs-5 placement resolved: artifacts produced at Phase 5 Step 1 (gate step); §10.3 explains the `.forge/phase-4-spec/research/` historical convention.
**Files:** `formal-criteria.md` AC-T2-8-1 rewritten (~lines 257-266); `requirements.md` REQ-T2-8 prose updated; `design.md` §10 added (new section at end of file).

### F6 — REQ-T2-3 "42 sites" not enumerated → FIXED
**Change:** Adopted approach (b): freeze the FILE SET (5 files) + pattern-based grep constraints (residual permissive pattern = 0, imperative template count ≥ 37). The "42 total" becomes informational; binding constraints are file set + two grep patterns. Commander validates via these exact commands. New AC-T2-3-3 added (file-set completeness check).
**Files:** `requirements.md` REQ-T2-3 rewritten (~lines 240-267); `formal-criteria.md` AC-T2-3-1/2/3 rewritten (~lines 190-204).

### F7 — parse_pause_timeout REWRITE resolution → FIXED
**Change:** Selected path (a) inline redefine-and-test. Resolution paragraph added to REQ-T1-5 explicitly REJECTING paths (b) fixtures-extension and (c) downgrade-to-EXTEND. REQ-T1-2 entry #13 annotated. Traceability §A row 13 expanded with full "RESOLVED per REQ-T1-5 path (a)" language.
**Files:** `requirements.md` REQ-T1-5 resolution paragraph (~lines 148-158); REQ-T1-2 entry #13 note (~line 116); `traceability.md` §A row 13 (~line 52); Existing-scenarios list #17 annotation (~line 146).

### F8 — T2-ADV-3 disclosure unconditional → FIXED
**Change:** REQ-T2-10 extended with unconditional T2-ADV-3 disclosure paragraph (not dependent on REQ-T2-9 research outcome). AC-T2-10-2 added (file-and-roadmap content check). Rationale paragraph cites devil's advocate reviewer 3 finding.
**Files:** `requirements.md` REQ-T2-10 (~lines 322-336); `formal-criteria.md` AC-T2-10-2 added (~lines 290-294).

### F9 — Phase 8 Commander gate-execution protocol → FIXED
**Change:** Added `Appendix A` to requirements.md with explicit 10-row protocol table. Each row lists: Commander command, output log path, grep pattern for success, failure semantics. Covers anti-pattern gate, harness all-pass, SKIP count, cross-file invariants, MINOR-justification, research gate, Layer 1 residuals, imperative template count, agent NEVER-bullet coverage, T2-ADV-3 disclosure.
**Files:** `requirements.md` Appendix A added (~lines 550-566).

### F10 — Companion-doc consistency (net-new count) → FIXED
**Change:** All four files now agree on 19 net-new scenarios and 204 harness total. Design §8.4 expanded to full 19-row table with REQ references. Traceability §Net-new header corrected from "(12)" to "(19 — FROZEN; binding for REQ-T1-9 arithmetic)". Coverage statistics table updated (31 existing + 19 net-new + 1 doc-drift = correct).
**Files:** `design.md` §8.4 (~lines 580-602); `traceability.md` Net-new header + harness note + Coverage statistics table.

### MINOR fixes
- REQ-T1-9 "≥" → "==" hard equality (part of F3).
- parse_pause_timeout special-case annotations at REQ-T1-2 #13, REQ-T1-5 resolution, traceability §A row 13 (part of F7).
- REQ-T1-15 effort budget revised 30h → 33h (add 2 REWRITEs × 1.5h + buffer).
- NFR-10 budget revised 42-48h → 45-51h.
- REQ-T1-18 Tier-A candidate list expanded (16 REWRITEs; ≥8 Tier-A = #1,5,7,8,11,14,15,16).

---

## No-scope-creep confirmation

- **No new REQs added.** REQ count stays at 48. The T2-ADV-3 unconditional disclosure (F8) was absorbed into existing REQ-T2-10 rather than creating a new REQ.
- **No REQs removed or renumbered.**
- **2 ACs added** (AC-T2-3-3, AC-T2-10-2). Total ACs 77 → 79. Both ACs are direct expansions of existing REQs (no new REQs).
- **Phase 3 judge decisions preserved:** 11 agents, advisory hook, `dispatched_at` check, opt-in installation, roadmap discrepancies.
- **User Gate 1 override preserved:** REWRITE=14 was the synthesis number; the Phase 2 TABLE authority (16) now supersedes, per F1/F2 user instruction "Phase 2 inventory is authoritative."

---

## Total lines changed estimate

| File | Lines added | Lines removed | Net |
|------|-------------|---------------|-----|
| `requirements.md` | ~180 | ~50 | +130 |
| `formal-criteria.md` | ~70 | ~20 | +50 |
| `design.md` | ~160 | ~30 | +130 |
| `traceability.md` | ~60 | ~30 | +30 |
| `revision-round-1.md` | ~130 | 0 | +130 (new file) |
| **Total** | ~600 | ~130 | **+470** |

All edits target explicit findings F1-F10. No gold-plating beyond the requested fixes.
