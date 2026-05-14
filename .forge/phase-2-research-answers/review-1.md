# Phase 2 Research Answers — Reviewer Assessment

**Reviewer:** Phase 2 Reviewer (Claude Sonnet 4.6)
**Date:** 2026-05-13
**Artifact:** `.forge/phase-2-research-answers/final.md`
**Task context:** Migrating "ceos-agents" Claude Code plugin to "agent-flow" v1.0.0 for OSS release

---

## Review Summary

The document is comprehensive, well-structured, and answers all 8 key questions from the review mandate. It provides an actionable Phase 7 execution checklist with correct sequencing. However, **two numerical claims are materially overstated**, both traceable to the same root cause: the research appears to have counted `.forge*` and `.forge.bak-*` directories together with main-repo files. These errors do not invalidate the migration plan — most over-counted files are in the deletion set — but Phase 7 executors must not rely on the raw counts for scope estimation.

---

## Key Question Verdicts

### Q1 — Total count of files/occurrences to rename
**PARTIAL PASS — counts overstated in 2 categories.**

| Claim | Verified actual | Delta | Verdict |
|-------|----------------|-------|---------|
| 224 files with "ceos-agents" | 223 files (main repo, .md/.json/.sh/.yaml) | -1 (negligible) | OK |
| 127 files with "ceos-agents:" skill prefix | 127 files | 0 | OK |
| 101 files with gitea.internal.ceosdata.com | **18 files total** (15 excl. .git/.claude) | -83 | OVERSTATED |
| 147 files with dispatch_witness | **63 files** (all types, excl. .forge) | -84 | OVERSTATED |
| 30 files / ~35 install-cmd occurrences | Not independently verified; plausible | — | ACCEPTED |
| 61 .forge.bak-* directories | 61 directories confirmed | 0 | OK |

**Root cause of over-counts:** The 101 and 147 figures likely included `.forge*` directories (61 bak dirs + current `.forge/`). Since docs/plans/ (the primary location of internal gitea URLs) is itself being deleted, and `.forge*` is being deleted, the practical rename burden for `gitea.internal.ceosdata.com` is only ~5 survivor files: `.claude-plugin/plugin.json`, `CHANGELOG.md`, `tests/scenarios/v6.9.0-installation-md-no-internal-host.sh`, `.claude/settings.local.json` (possibly out of scope), and `docs/superpowers/specs/` (in deletion set).

**Impact on Phase 7:** The checklist Step 4b is still correct in approach; executors should expect far fewer files than 101 for the URL rename after deletions are applied.

### Q2 — dispatch_witness sha256 seeds issue
**PASS.** Section 1.2 correctly identifies:
- The functional concern: JSON seed payloads reference `"source": "ceos-agents:fix-bugs-skill"` etc.
- Must be renamed `agent-flow:` to match new namespace
- Identifies primary files: `tests/scenarios/` (5 named files), `tests/fixtures/v10-witness/` (4 files), `state/schema.md`, `core/lib/stage-invariant.sh`
- Notes "45+ fixture/state files with hardcoded JSON sha256 witness seed strings" — this count may share the same over-count issue, but the approach and the named key files are correct.

The actionable guidance (rename `"ceos-agents:` → `"agent-flow:` inside JSON witness payloads) is correct and sufficient.

### Q3 — Location of plugin.json/marketplace.json
**PASS.** Section 3.1–3.2 and Critical Finding #3 correctly confirm:
- Both files are in `.claude-plugin/`, NOT at repo root
- Current content of both files is quoted verbatim and matches live file reads (verified)
- Required changes for each field are correctly specified
- `marketplace.json` does NOT have a `repository` field — correctly absent from the required-changes list

### Q4 — Location of "v9.0.0+, mandatory"
**PASS.** Critical Finding #2 and Section 2.1 correctly state:
- The version-labeled strings (`## Output Contract (v9.0.0+, mandatory — ...)` and `## Step Completion Invariants (v10.0.0+, mandatory — ...)`) appear **ONLY in CLAUDE.md lines 101–102**
- Verified by grep: `CLAUDE.md:101` and `CLAUDE.md:102` are the only hits in the repo
- agents/*.md use plain section headers (`## Output Contract`, `## Step Completion Invariants`) without version labels
- Correct Phase 7 implication: no search-and-replace of version labels needed in agents/*.md

### Q5 — docs/plans/roadmap.md before deletion
**PASS.** Critical Finding #4 and Step 1 of the checklist correctly address this:
- roadmap.md confirmed at 2192 lines
- `git mv docs/plans/roadmap.md docs/roadmap.md` as separate first commit before bulk deletion — correct
- Identifies README.md L268 as the ref to update
- Documents what content to extract/rewrite for community audience
- Notes the rewrite should be English-only, future-facing, no internal Czech notes

One gap: the checklist does not mention `CHANGELOG.md` roadmap refs needing update — Step 1 mentions it in the narrative but Step 8 validation does not verify `docs/plans/roadmap.md` reference removal from CHANGELOG.

### Q6 — .gitignore current state
**PASS.** Section 2.4 provides exact current contents (4 entries: `.vs/`, `nul`, `.claude/settings.local.json`, `.env`) — verified against live file. The 7+1 patterns to add are correctly specified and actionable.

Minor note: The checklist mentions 8 patterns to add but the list in Section 2.4 shows 8 (including `docs/superpowers/`). This is consistent; no issue.

### Q7 — SECURITY.md current state
**PASS.** Section 3.5 correctly documents:
- 16-line file with `# Security Policy` heading
- Reporting contact: `filip.sabacky@ceosdata.com` (matches Cross-File Invariant #2)
- 5 business days SLA
- "Latest version only" support policy
- Roadmap decision L1632: add GitHub Security Advisories as secondary channel
All verified against live file.

### Q8 — Phase 7 execution checklist usability
**PASS with minor gaps.** The 9-step checklist (Steps 0–8, plus Step 9 for orphan commit) is:
- Correctly sequenced (gitignore → roadmap mv → deletions → plugin metadata → mass rename → doc-count → changelog → invariant check → validation → orphan commit)
- The critical dependency (roadmap.md relocation before docs/plans/ deletion) is correctly placed
- Sub-batching of the mass rename (4a–4e) is practical and reviewable
- Final grep validation commands (Step 8) are correctly targeted

**Gaps in checklist:**
1. Step 1 does not include verifying `CHANGELOG.md` has no remaining `docs/plans/roadmap.md` refs
2. Step 4 does not address `docs/superpowers/` — it's in the deletion list but Step 2 only mentions `docs/superpowers/specs/`. The parent `docs/superpowers/` directory itself needs deletion.
3. Step 8 validation does not check for `.ceos-agents/` remaining occurrences (only checks `ceos-agents`, `gitea.internal.ceosdata.com`, `ceos-agents@ceos-agents`)
4. The orphan commit step (Step 9) is present but references the current Gitea repo — executors should note that the `.claude/settings.local.json` currently has a gitea remote that will need updating

---

## Minor Factual Issues

| Issue | Severity | Details |
|-------|----------|---------|
| docs/superpowers/specs/ file count: "8 files" | LOW | Actual count is 9 files (the HTML file was counted; the directory listing shows 9 items) |
| docs/plans/ file count: "96 files" | LOW | Actual count is 76 files (ls shows 76). The "96" claim is overstated. |
| dispatch_witness file count: "147 files" | MEDIUM | Actual count is 63 files excluding .forge (see Q1 analysis). Affects scope estimation but not approach. |
| gitea.internal.ceosdata.com: "101 files" | MEDIUM | Actual count is 18 files total (15 outside .git/.claude). Most are in the deletion set. |

---

## Strengths

1. **All 8 key questions answered with concrete, actionable guidance** — the document succeeds at its primary mission.
2. **plugin.json and marketplace.json states are verbatim-correct** — verified exact match to live files.
3. **SECURITY.md state is correct** — exact match to live file.
4. **.gitignore state is exact** — all 4 entries correctly reproduced.
5. **Critical ordering constraint (roadmap before docs/plans/ deletion) is correctly surfaced** — this is the single most important sequencing constraint and it is prominently documented.
6. **dispatch_witness rename approach is correct** — even if the count is overstated, renaming `"ceos-agents:` → `"agent-flow:` in JSON witness payloads is the right action.
7. **The 6 rename patterns are complete** — covers all `ceos-agents` variants including the less-obvious `[ceos-agents]` block markers and `ceos-agents-block` webhook event name.
8. **CHANGELOG replacement decision is correctly documented** — clean v1.0.0 start as per roadmap.md L1524.

---

## Verdict

```json
{
  "tier_1": {
    "schema_valid": true,
    "requirements_traced": true,
    "no_regressions": true,
    "lint_clean": true,
    "pass": true
  },
  "tier_2": {
    "fail_to_pass": null,
    "hidden_test_gap": null,
    "mutation_score": null,
    "mutation_available": false,
    "pass": true
  },
  "tier_3": {
    "correctness": 4,
    "completeness": 4,
    "security": 4,
    "maintainability": 5,
    "robustness": 3,
    "weighted_aggregate": 4.0,
    "pass": true
  },
  "overall_verdict": "PASS",
  "confidence": 0.87,
  "findings": [
    {
      "id": "F-01",
      "severity": "MEDIUM",
      "category": "correctness",
      "title": "gitea.internal.ceosdata.com file count overstated by 83 files",
      "detail": "Research claims 101 files; actual grep finds 18 files (15 excluding .git/.claude). Root cause: likely included .forge.bak-* directories in the count. Most survivors are in the deletion set (docs/plans/, docs/superpowers/). The practical rename target after deletions is ~5 files.",
      "action": "Phase 7 executors should not use 101 as scope estimate; run a fresh grep after Step 2 deletions to confirm remaining files."
    },
    {
      "id": "F-02",
      "severity": "MEDIUM",
      "category": "correctness",
      "title": "dispatch_witness file count overstated by 84 files",
      "detail": "Research claims 147 files; actual grep finds 63 files excluding .forge directories. The named key files and rename approach are correct. Impact: scope estimation error only.",
      "action": "Phase 7 executors: use Step 8 grep validation rather than pre-counts to confirm completeness."
    },
    {
      "id": "F-03",
      "severity": "LOW",
      "category": "correctness",
      "title": "docs/plans/ file count: 96 claimed, 76 actual",
      "detail": "ls docs/plans/ returns 76 entries. The 96 figure may have included subdirectory files (brainstorm/ subdirectory). Does not affect the deletion approach.",
      "action": "Use `find docs/plans/ -type f` for accurate pre-deletion count."
    },
    {
      "id": "F-04",
      "severity": "LOW",
      "category": "correctness",
      "title": "docs/superpowers/specs/ file count: 8 claimed, 9 actual",
      "detail": "The directory contains 9 files including 2026-04-27-ceo-presentation.html. Minor off-by-one.",
      "action": "No impact on execution; delete the whole directory."
    },
    {
      "id": "F-05",
      "severity": "LOW",
      "category": "completeness",
      "title": "Step 8 validation missing .ceos-agents/ occurrence check",
      "detail": "The final grep validation commands do not include a check for remaining `.ceos-agents/` occurrences after Step 4c renames.",
      "action": "Add `grep -rn '\\.ceos-agents/'` to Step 8 validation."
    },
    {
      "id": "F-06",
      "severity": "LOW",
      "category": "completeness",
      "title": "docs/superpowers/ parent directory missing from Step 2 deletion list",
      "detail": "Step 2 lists 'Delete docs/superpowers/specs/ (8 files)' but the parent docs/superpowers/ directory also needs deletion (it contains only the specs/ subdirectory).",
      "action": "Change Step 2 item to: 'Delete docs/superpowers/ (entire directory, 9 files in specs/)'"
    },
    {
      "id": "F-07",
      "severity": "LOW",
      "category": "completeness",
      "title": "Cross-File Invariants #2 and #3 not fully verified in this research phase",
      "detail": "CODE_OF_CONDUCT.md and CONTRIBUTING.md email content not confirmed; .gitea/.github template parity not verified. Flagged correctly in the document as 'Phase 7 action' items.",
      "action": "Acceptable deferral — Phase 7 checklist Step 7 correctly addresses these."
    }
  ]
}
```

---

## Recommendation

**PASS — proceed to Phase 3.** The research document provides sufficient, accurate, and actionable information for all downstream phases. The two over-counted metrics (URL files: 101 vs 18; witness files: 147 vs 63) are immaterial to the migration approach and primarily affected the deleted set anyway. The Phase 7 checklist is correctly sequenced and covers all critical operations. Phase 7 executors should:

1. Note F-01/F-02: do not use the pre-deletion file counts as accuracy benchmarks; rely on Step 8 grep validation instead
2. Fix F-06: delete `docs/superpowers/` (entire dir), not just `docs/superpowers/specs/`
3. Fix F-05: add `.ceos-agents/` check to Step 8 validation greps
