# Phase 2 Review — Round 1
# forge-2026-05-13-001 — v10.2.0 core/ Path Disambiguation

**Reviewer:** Phase 2 Reviewer (round 1)
**Artifact:** `.forge/phase-2-research-answers/synthesis.md`
**Date:** 2026-05-13

---

## Empirical Re-verification Results

All 7 mandated checks executed against v10.1.2 HEAD (commit 32f6f33):

| Check | Expected | Actual | Match |
|-------|----------|--------|-------|
| `grep -rn 'core/[a-z][a-z-]*\.md' skills/ agents/ --include='*.md' \| wc -l` | 182 | **182** | PASS |
| `grep -roh 'core/[a-z][a-z-]*\.md' skills/ agents/ --include='*.md' \| wc -l` | 185 | **185** | PASS |
| `grep -r 'PLUGIN_ROOT' skills/ agents/ core/ .claude-plugin/` | 0 hits | **0 hits** | PASS |
| `[ -d skills/scaffold/data/ ]` | NOT exist | **NOT_EXISTS** | PASS |
| `[ -f skills/scaffold/data/guard-block.md ]` | NOT exist | **NOT_EXISTS** | PASS |
| `ls core/mcp-preflight.md && wc -l` | exists, ~47L | **exists, 47L** | PASS |
| `grep -rn 'core/mcp-preflight\.md' skills/ --include='*.md' \| wc -l` | 6+ | **6** | PASS |

Additional verifications performed:

- **skills/ vs agents/ breakdown:** 175 + 7 = 182 CONFIRMED (synthesis claim correct)
- **Per-name distribution:** Full uniq-c sort matches synthesis C1 table exactly (71/34/14/13/7/6/5/5/5/4/4/4/4/4/2/2/1)
- **Dual-pattern lines:** 3 confirmed (implement-feature/SKILL.md:130, steps/03-decomposition.md:91, publish/SKILL.md:176) — 6 annotated entries in scope-lock + 179 regular = 185 total, consistent
- **guard-block.md path logic absent:** grep for PLUGIN_ROOT, dirname, `[ -r`, `__FILE__` returns 0 matches in both existing guard-block files — CONFIRMED
- **publisher.md line numbers:** :65, :77, :144 verified accurate against live file
- **depth classes:** agents/ = depth 1 (`../core/`), skills/{name}/SKILL.md = depth 2 (`../../core/`), steps/ and data/ = depth 3 (`../../../core/`) — mathematically correct
- **Non-standard prefix check:** 0 matches for `./core/`, `skills/../core/`, `../../core/` — CONFIRMED

---

## Findings

### F1 — MINOR — Completeness
**ID:** `ff7230`
**Location:** `synthesis.md:I2:header-says-182-but-185-is-correct`
**Description:** I2's section header reads "per-file-name distribution of the **182** occurrences" but the percentages quoted (38%, 18%, 57%) are computed against 185 occurrences, which is correct. The number 182 in the I2 header is the line count, not the occurrence count — it's used inconsistently here, since per-name distribution is inherently an occurrence-count operation. The C1 distinction between 182 (lines) and 185 (occurrences) is well-defined and internally consistent; I2 fails to apply it correctly in the heading.
**Impact:** Minor readability/precision issue. The underlying data is correct; Phase 4 spec writers won't be misled by the actual table numbers.
**Recommendation:** Change I2 header to "per-file-name distribution of the 185 true occurrences." No other changes needed.

### F2 — INFO — Correctness
**ID:** `314de5`
**Location:** `synthesis.md:C2:probe-CWD-note-incomplete`
**Description:** C2 states "the path resolves correctly without any path prefix" when CWD = repo root, but does not explicitly address *how* Claude Code sets CWD when dispatching a skill vs loading a guard-block include. The Phase 1 question explicitly asks this. The synthesis answers "if CWD is repo root" — but does not cite evidence that Claude Code always sets CWD to repo root (not to the skill's directory). The existing guard directives at fix-bugs/SKILL.md:11 and implement-feature/SKILL.md:11 load paths like `skills/fix-bugs/data/guard-block.md` (not `./data/guard-block.md`), which implies CWD = repo root — this is implicit evidence but not stated. For Phase 4, this is low-risk since operational behavior is consistent; however the logic gap is present.
**Impact:** INFO only — no blocking effect on Phase 4. The CWD-is-repo-root conclusion is almost certainly correct given the guard directive evidence; it just isn't argued explicitly.
**Recommendation:** Noted for awareness; does not require revision before Phase 4 proceeds.

---

## Verdict

```json
{
  "tier_1": {
    "schema_valid": true,
    "requirements_traced": true,
    "no_regressions": true,
    "lint_clean": true,
    "pass": true,
    "notes": "All 5 questions (C1, C2, I1, I2, I3) have Answer + Evidence blocks. B1 disposition present with grep evidence. No scope creep into Phase 4 spec writing (B2 depth-split is a mandatory Phase 4 input, not Phase 4 prose). Scope-lock list is present and verifiable."
  },
  "tier_2": {
    "fail_to_pass": null,
    "hidden_test_gap": null,
    "mutation_score": null,
    "mutation_available": false,
    "pass": true,
    "notes": "Tier 2 not applicable to research synthesis phase."
  },
  "tier_3": {
    "correctness": 5,
    "completeness": 4,
    "security": 5,
    "maintainability": 5,
    "robustness": 5,
    "weighted_aggregate": 4.75,
    "pass": true,
    "notes": {
      "correctness": "All 7 empirical checks pass. Per-name distribution matches exactly. Line numbers spot-checked accurate. Dual-pattern line count (3) confirmed. Depth class assignments mathematically verified. No factual errors found.",
      "completeness": "All 5 questions answered with Answer + Evidence. C1 scope-lock list is complete (182 lines / 185 occurrences, both consistent). B1 disposition confirmed VIABLE/NOT-VIABLE with grep evidence. scaffold/data/ 3-action breakdown present. Depth-split per-class (4 classes) enumerated. One minor: I2 header says 182 where 185 is correct (finding F1). Security N/A = 5 justified (research phase, no executable code produced). Maintainability score: Phase 4 spec writer's job is fully mechanical — depth-class table + sed templates are provided, no judgment calls remain. Robustness: synthesis preempts depth-split surprise (elevated to top-level section), dual-pattern line handling, non-standard prefix absence, guard-block write-from-scratch constraint, and scaffold 3-action prerequisite. No downstream surprises remain unaddressed.",
      "completeness_deduction": "−1 for I2 header typo (182 vs 185) — minor but measurable against the synthesis's own precision standard for line vs occurrence count distinction.",
      "security": "N/A — research artifact. No executable code, no injection surface. Set to 5.",
      "maintainability": "The B2 depth-split mandate section is well-structured with a table and explicit sed instruction count. Phase 4 can implement mechanically. The synthesis explicitly calls out the critical risk (depth-split) and elevates it to a dedicated top-level section. Score 5.",
      "robustness": "The synthesis resolves all agent contradictions (line vs occurrence count, agents/ depth, scaffold/data/ existence). Disagreement flags section confirms convergence. The DONE_WITH_CONCERNS flag from Agent 3 was appropriately resolved (depth-split risk addressed in dedicated section). Score 5."
    }
  },
  "overall_verdict": "PASS",
  "confidence": 0.93,
  "findings": [
    {
      "id": "ff7230",
      "severity": "MINOR",
      "criterion": "completeness",
      "location": "synthesis.md:I2:header-says-182-but-185-is-correct",
      "description": "I2 section header says 'distribution of the 182 occurrences' but 182 is the line count; the per-name distribution is an occurrence-count operation and should reference 185. Percentages in the table are correctly computed against 185.",
      "recommendation": "Change I2 header to reference 185 occurrences; no data changes needed."
    },
    {
      "id": "314de5",
      "severity": "INFO",
      "criterion": "correctness",
      "location": "synthesis.md:C2:probe-CWD-note-incomplete",
      "description": "C2 asserts CWD = repo root resolves the guard path correctly but does not cite explicit evidence that Claude Code always sets CWD to repo root for skill dispatch. The implicit evidence (existing guard directives use repo-root-relative paths) supports the conclusion but is not stated.",
      "recommendation": "Noted for Phase 4 awareness; does not block approval. Phase 4 spec should cite fix-bugs/SKILL.md:11 as the CWD evidence."
    }
  ]
}
```

---

## Summary

**Tier 1: PASS** — All 5 questions answered, citation discipline strong, B1 disposition with grep evidence, no scope creep.

**Tier 3 weighted aggregate: 4.75** — correctness 5, completeness 4 (−1 for I2 header typo), security 5, maintainability 5, robustness 5.

**Overall verdict: PASS** with confidence 0.93.

**Findings:** 2 total — 1 MINOR (I2 header label inconsistency), 1 INFO (implicit CWD assumption). Neither blocks Phase 4 progression. The MINOR finding (F1) is a cosmetic fix that can be applied in the final.md without a revision loop.

**Count discrepancies vs synthesis:** None. All 7 mandated empirical checks matched synthesis claims exactly. The scope-lock list is structurally consistent (185 entries = 182 unique file:line pairs + 3 dual-pattern expansions).

**Recommendation:** Approve with F1 fix applied inline when writing final.md. Do not re-enter revision loop — the fix is trivially mechanical (one word: "182" → "185" in I2 header).
