# Phase 4 Review 2 — Quality (Reviewer 2)

```json
{
  "tier_1": {
    "schema_valid": true,
    "requirements_traced": true,
    "no_regressions": true,
    "lint_clean": false,
    "pass": false,
    "notes": "lint_clean=false: 3 ACs have correctness defects (AC-RENAME-STATUS-4/5 and AC-RENAME-INIT-4 are contradicted by AC-DOCS-COLLISION-WARN-3; design.md Section 8.2 grep commands will false-positive on workflow-router). These are spec-level contradictions, not implementation errors."
  },
  "tier_2": {
    "fail_to_pass": {"passed": null, "failed": null, "total": null},
    "hidden_test_gap": null,
    "mutation_score": null,
    "mutation_available": false,
    "pass": true,
    "notes": "Tier 2 not applicable to spec review phase."
  },
  "tier_3": {
    "correctness": 3,
    "completeness": 4,
    "security": 4,
    "maintainability": 4,
    "robustness": 3,
    "weighted_aggregate": 3.60,
    "pass": true,
    "notes": "weighted = 3*0.30 + 4*0.25 + 4*0.20 + 4*0.15 + 3*0.10 = 0.90+1.00+0.80+0.60+0.30 = 3.60. All criteria meet minimums (correctness min=3, completeness min=3, security min=3, maintainability min=2, robustness min=2)."
  },
  "overall_verdict": "FAIL",
  "confidence": 0.88,
  "findings": [
    {
      "id": "f-a1b2c3",
      "severity": "MAJOR",
      "criterion": "correctness",
      "location": "formal-criteria.md: AC-RENAME-STATUS-4, AC-RENAME-INIT-4, AC-DEL-CREATE-PR-2 vs AC-DOCS-COLLISION-WARN-3",
      "description": "AC-RENAME-STATUS-4, AC-RENAME-INIT-4, and AC-DEL-CREATE-PR-2 each globally ban their respective deprecated identifiers (ceos-agents:status, ceos-agents:init, ceos-agents:create-pr) from all active .md files with no workflow-router exclusion. AC-DOCS-COLLISION-WARN-3 simultaneously requires those same identifiers to be present in skills/workflow-router/SKILL.md as 'Did you mean?' prose (per design.md Section 5.3). These ACs cannot both pass on the same file. The spec acknowledges this tension in the implementation note at formal-criteria.md lines 321-323, but defers the resolution to Phase 7 without fixing the ACs. Phase 7 will need to choose option (a) or (b) from the note, but the ACs as written force a Phase 7 author to guess the intended resolution.",
      "recommendation": "Add --exclude=skills/workflow-router/SKILL.md to the grep commands in AC-RENAME-STATUS-4, AC-RENAME-INIT-4, and AC-DEL-CREATE-PR-2. Alternatively, mandate in design.md Section 5.3 that deprecated names in the workflow-router prose MUST use a specific marker prefix (e.g., 'OLD:') that prevents the \\b word-boundary match, and document this constraint in the relevant ACs."
    },
    {
      "id": "f-d4e5f6",
      "severity": "MAJOR",
      "criterion": "correctness",
      "location": "design.md Section 8.2 (deprecated identifier sanity commands)",
      "description": "The Phase 8 verification commands in design.md Section 8.2 ban ceos-agents:status, ceos-agents:init, and ceos-agents:create-pr globally but do NOT exclude skills/workflow-router/SKILL.md. These commands will produce false FAIL verdicts in Phase 8 if the workflow-router deprecated-names section (required by design.md Section 5.3) is present. This is the same contradiction as finding f-a1b2c3 but at the Phase 8 verification level. Finding f-a1b2c3 covers the formal ACs; this finding covers the non-AC Phase 8 commands which would produce incorrect verdicts during Phase 8 execution.",
      "recommendation": "Add --exclude=skills/workflow-router/SKILL.md to the three ceos-agents:status/init/create-pr grep commands in Section 8.2. Alternatively (consistent with option (b) in the formal-criteria.md note), if design.md Section 5.3 mandates the OLD: marker approach, no exclusion is needed — but the marker requirement must be stated explicitly in Section 5.3."
    },
    {
      "id": "f-g7h8i9",
      "severity": "MAJOR",
      "criterion": "correctness",
      "location": "requirements.md REQ-RENAME-STATUS EARS text",
      "description": "REQ-RENAME-STATUS EARS text states: 'every active reference shall use the new identifier pipeline-status without any residual /ceos-agents:status or bare status skill-name reference.' The EARS text does NOT enumerate workflow-router as an exception for the 'Did you mean?' prose. However, design.md Section 5.3 explicitly adds /ceos-agents:status back into workflow-router. This means the REQ itself is contradicted by the design. The ACs flow from the REQ; the fix must be in the REQ EARS exclusion list OR the design.md 5.3 prose must be acknowledged as a REQ-level exception. Same issue applies to REQ-RENAME-INIT (ceos-agents:init in workflow-router) and REQ-DEL-CREATE-PR (ceos-agents:create-pr in workflow-router).",
      "recommendation": "Add an explicit exclusion to all three EARS texts: append to the exclusion list '...and the workflow-router deprecated-names fallback prose (design.md Section 5.3) which intentionally references deprecated identifiers to support user disambiguation.' This brings the REQ, design, and ACs into alignment."
    },
    {
      "id": "f-j1k2l3",
      "severity": "MINOR",
      "criterion": "correctness",
      "location": "formal-criteria.md: AC-DOCS-COLLISION-WARN-1, AC-DOCS-COLLISION-WARN-2",
      "description": "REQ-DOCS-COLLISION-WARN requires 'a clearly-marked subsection (heading at H2 or H3 level — explicit subsection, not a passing prose mention).' Both ACs only grep for content strings (collide.*Claude Code, /ceos-agents:pipeline-status, etc.) without verifying that a heading at H2 or H3 level is present. A prose mention in a paragraph (not a heading) would satisfy the ACs but violate the REQ. The ACs are weaker than the REQ requires.",
      "recommendation": "Add a grep for the heading pattern to each AC: grep -qE '^#{2,3} .*[Ss]lash.*[Cc]ommand|^#{2,3} .*[Cc]ollision' README.md (and similarly for installation.md). This ensures a heading exists at the correct level, not merely prose content."
    },
    {
      "id": "f-m4n5o6",
      "severity": "MINOR",
      "criterion": "correctness",
      "location": "formal-criteria.md: AC-CHANGELOG-MIGRATION-7 (exit-neutral assertion)",
      "description": "The exit-neutrality assertion uses: ! grep -E '\\[WARN\\].*Extra labels' skills/check-setup/SKILL.md | grep -qE 'exit 1|FAIL|fail\\(\\)|return 1'. This tests only that the [WARN].*Extra labels line itself does not contain exit 1 on the same line. It does NOT catch a multi-line bash if-block structure where: (1) the WARN echo appears on one line, and (2) exit 1 appears on the next line inside the same if-block. A Phase 7 implementation that accidentally adds exit 1 inside the if-block on a separate line from the echo would pass this AC but violate the REQ.",
      "recommendation": "Either (a) add a context-aware check: ! grep -A5 -E '\\[WARN\\].*Extra labels' skills/check-setup/SKILL.md | grep -qE 'exit 1|return 1' (checks the 5 lines after the WARN), or (b) document in design.md Section 4.3 that the check-setup snippet must NOT use a conditional exit structure, making the single-line grep sufficient by construction."
    },
    {
      "id": "f-p7q8r9",
      "severity": "MINOR",
      "criterion": "completeness",
      "location": "formal-criteria.md Summary: AC count claim '60 across all REQs'",
      "description": "The formal-criteria.md Summary section states: 'AC count: 60 across all REQs'. The actual count of ### AC- headings is 69 (matching the per-REQ breakdown: 5+2+7+7+11+11+3+7+10+3+3=69). The test scenario inventory adds 15 more ACs with #### headings, bringing the total to 84. The stated count of 60 is incorrect. This is a metadata inconsistency; the ACs themselves are all present and correct.",
      "recommendation": "Update the Summary section: 'AC count: 69 functional ACs + 15 test scenario inventory ACs = 84 total.' The per-REQ breakdown already sums correctly to 69; only the top-line summary number needs correction."
    },
    {
      "id": "f-s1t2u3",
      "severity": "MINOR",
      "criterion": "completeness",
      "location": "formal-criteria.md: REQ-PUBLISH-AUTO-DETECT SC-7, SC-8",
      "description": "REQ-PUBLISH-AUTO-DETECT SC-7 specifies an exact WARN text format for the 404 case and SC-8 specifies an exact INFO text format for the no-issue-id case. No AC verifies the exact text of these two messages. AC-PUBLISH-AUTO-DETECT-8 only checks for mode string tokens (full-publish, pr-only-no-id, pr-only-404). AC-PUBLISH-AUTO-DETECT-5 covers the FAIL tier WARN text but neither SC-7 nor SC-8 WARN/INFO text is tested. Phase 7 could implement a different message format for these two cases and all current ACs would still pass.",
      "recommendation": "Add two ACs: AC-PUBLISH-AUTO-DETECT-12 testing grep -qE 'no matching ticket.*not found.*Creating PR without tracker update' skills/publish/SKILL.md (SC-7 WARN), and AC-PUBLISH-AUTO-DETECT-13 testing grep -qE 'does not match.*Branch naming pattern.*Creating PR without tracker contact' skills/publish/SKILL.md (SC-8 INFO). These use partial-pattern matching to allow minor prose variation while anchoring the key semantic tokens."
    },
    {
      "id": "f-v4w5x6",
      "severity": "MINOR",
      "criterion": "robustness",
      "location": "design.md Section 3 (REQ-PUBLISH-AUTO-DETECT) — detached HEAD edge case",
      "description": "Design.md Section 3.1 Step 0a handles detached HEAD (git branch --show-current returns empty) with a STOP INFO message. However, the pseudocode says 'Skip directly to Step 3' for issue_id == null (tracker_needed=false), but Step 3 checks for commits above base_branch. If the repository is in detached HEAD, the git log {base_branch}..HEAD command in Step 3 might behave unexpectedly. The design stops before Step 3 for detached HEAD but the STOP instruction says 'STOP with INFO' and does not say EXIT non-zero vs exit 0. This edge case is underspecified: is detached HEAD a hard error (non-zero) or a graceful no-op (zero)?",
      "recommendation": "Add a one-line clarification to design.md Section 3.1 Step 0a: 'Detached HEAD is treated as a FAIL (EXIT non-zero) because /publish requires an active branch to determine the PR target and source control identity. This is NOT the same as the pr-only-no-id mode.' Add a corresponding AC or note to AC-PUBLISH-AUTO-DETECT-1."
    }
  ]
}
```

---

## Elaboration

### Tier 1 Evaluation

**Schema/format compliance:** All three artifacts (requirements.md, design.md, formal-criteria.md) are structurally well-formed. Every REQ has an EARS-format `**EARS:**` line. Every AC is a bash one-liner inside a code block. The design.md has numbered sections. The formal-criteria.md has a summary table. Format is compliant.

**Requirements traced:** All 11 REQs have at least one AC. The coverage breakdown is:

| REQ | ACs |
|-----|-----|
| REQ-DEL-EXTRA-LABELS | 5 |
| REQ-PAUSE-LIMITS-DOC | 2 |
| REQ-RENAME-STATUS | 7 |
| REQ-RENAME-INIT | 7 |
| REQ-PUBLISH-AUTO-DETECT | 11 |
| REQ-DEL-CREATE-PR | 11 |
| REQ-DOCS-COLLISION-WARN | 3 |
| REQ-CHANGELOG-MIGRATION | 7 |
| REQ-COUNTS | 10 |
| REQ-INVARIANTS | 3 |
| REQ-NO-VERSION-BUMP | 3 |

100% traceability. No orphaned ACs.

**Lint/compile clean:** FAIL — see findings f-a1b2c3, f-d4e5f6, f-g7h8i9. Three ACs (AC-RENAME-STATUS-4/5, AC-RENAME-INIT-4, AC-DEL-CREATE-PR-2) are logically contradicted by AC-DOCS-COLLISION-WARN-3, and the Phase 8 verification commands in design.md Section 8.2 would produce false FAIL verdicts under the as-specified workflow-router edits.

### Tier 3 Detailed Scores

#### Correctness — 3/5

The spec is internally consistent except for the workflow-router contradiction cluster (findings f-a1b2c3, f-d4e5f6, f-g7h8i9). This is not a subtle edge case — it is a direct conflict between two explicitly required outputs in the same file. The spec partially acknowledges it (formal-criteria.md lines 321-323 implementation note) but fails to resolve it in the authoritative locations (the ACs and the REQ EARS text). Any Phase 7 author who implements the deprecated-names prose AND runs the global-ban ACs will face irresolvable failures. The detection exit-neutrality AC (finding f-m4n5o6) is also weaker than the REQ.

Three other correctness observations that do NOT affect the score:
- AC-DEL-CREATE-PR-5/6 pipe-negation semantics: `! cmd1 | cmd2` in bash negates the exit status of the LAST command (grep -q), NOT the first grep. Tested empirically. The ACs are CORRECT — they test `NOT (found /create-pr in lines matching PR Rules)`, which is the intended check.
- AC-COUNTS-6 uses `grep -qF 'SKL[28 Skills]'` — the `-F` flag treats `[` as literal, not a bracket expression. Tested empirically: pattern matches correctly.
- AC-DEL-EXTRA-LABELS-5 pattern escaping: `grep -q '\[ "${#OPTIONAL_SECTIONS\[@\]}" -eq 18 \]'` — tested empirically against the literal target string; matches correctly.

#### Completeness — 4/5

Coverage of the 6 release actions is thorough and the 60 AC claim (actually 69 functional + 15 test-inventory = 84 total) represents genuine breadth. Skew analysis: REQ-PUBLISH-AUTO-DETECT (11 ACs) and REQ-DEL-CREATE-PR (11 ACs) are the heaviest, appropriate given their complexity. REQ-PAUSE-LIMITS-DOC (2 ACs) is light but the REQ is narrow (one table row edit). REQ-INVARIANTS (3 ACs) is appropriate for a cross-cutting preserve-invariant requirement.

Two coverage gaps identified (findings f-s1t2u3): SC-7 WARN text format and SC-8 INFO text format are not verified by any AC. Phase 7 could deviate from the exact message spec on these two secondary tiers without detection.

#### Security — 4/5

All global-ban grep ACs correctly use `--exclude-dir=.forge --exclude-dir=".forge.bak-*" --exclude-dir=docs/plans --exclude-dir=docs/superpowers --exclude=CHANGELOG.md` to avoid false positives from forge artifacts and historical content. The `.forge.bak-*` pattern uses quoted glob, which is correct for `--exclude-dir` on Linux/macOS (tested pattern form matches Phase 2 evidence base). The `\b` word-boundary in `ceos-agents:status\b` is appropriate to avoid matching `ceos-agents:status-extended` hypothetical strings. The security score is reduced one point because of the workflow-router false-positive risk (findings f-a1b2c3, f-d4e5f6) — these grep commands would produce INCORRECT Phase 8 verdicts, which is a security risk in the sense that false FAIL verdicts could block correct implementations.

#### Maintainability — 4/5

ACs use stable patterns: no hardcoded line numbers (which would drift on edits), use `grep -qF` / `grep -qE` with content patterns, use `[ -d path ]` / `[ -f path ]` filesystem checks, and use `find` with depth bounds. The `git diff main --` command in AC-NO-VERSION-BUMP-1/2 assumes the pipeline branch is compared to `main` — this is correct for the forge pipeline context. The `head -10` in AC-RENAME-STATUS-3 and AC-RENAME-INIT-3 is robust since frontmatter is always within the first 10 lines by convention.

One minor note: AC-TEST-INVENTORY-12 uses `grep -cF 'skills/setup-mcp/SKILL.md'` and checks the count equals "6". If the test file is refactored to consolidate lines, the count could change without breaking the test semantics. This is inherently fragile. Count-based ACs are acceptable but noted.

#### Robustness — 3/5

Design.md Section 2.3 (Windows hazard mitigation) and Section 8.3 (empty-skills-dir invariant) appropriately handle the Windows-specific `git mv` edge case. The `tr -d ' '` strips whitespace from `wc -l` output, which is correct for macOS/BSD `wc` that pads with spaces.

The detached HEAD edge case (finding f-v4w5x6) is handled in Step 0a but the exit semantics are ambiguous. More importantly, design.md Section 3 does not address multi-template branch naming (users who configure multiple branch naming patterns, e.g., `fix/{issue-id}` AND `feature/{issue-id}`). The current pseudocode reads the template as a single value and extracts the literal prefix before `{issue-id}`. If Automation Config allows multiple `Branch naming` entries, the prefix-extraction logic needs to iterate. Phase 2 Q6 confirms this is new logic with no existing implementation, so the ambiguity is real. This is a minor robustness gap as it affects an edge case not in the primary use flow.

### Specific Quality Checks Verdict

1. **Bash AC validity:** All ACs are mechanically executable. The `wc -l | tr -d ' '` pattern is correct. The `head -N | grep -qE` pattern is correct. The `git diff main -- | grep -E | wc -l` pattern is correct. No `grep -c` misuse found — all count-comparison ACs use the `"$(grep -c ... | tr -d ' ')" = "N"` form with proper quoting, which is correct.

2. **Anchor file exclusions:** All global-ban ACs consistently use the 5-exclusion pattern. Confirmed: `.forge`, `.forge.bak-*`, `docs/plans`, `docs/superpowers`, `CHANGELOG.md`. The CHANGELOG exclusion is critical because the migration block intentionally mentions all deprecated identifiers.

3. **workflow-router false-positive:** The spec itself acknowledges this in formal-criteria.md lines 321-323 but defers resolution to Phase 7. This is not a deferral that can be accepted at the Phase 4 spec stage — the ACs must be self-consistent before Phase 7 can implement them. The finding is MAJOR because it will cause Phase 8 to emit irresolvable FAIL verdicts.

4. **Test scenario classification:** Spot-checked 5 entries from design.md Section 7:
   - `regression-skill-count-29.sh` → UPDATE (correct: changes `-ne 29` to `-ne 28`)
   - `ac-v68-doc-optional-sections-18.sh` → NO-CHANGE (correct: `(18|19)` regex already accepts 18)
   - `v6.9.0-doc-count-drift.sh` → UPDATE with 6 specific edits (correct: DISAGREEMENT D resolution from Phase 2)
   - `v6.9.0-cross-file-invariants.sh` → NO-CHANGE (correct: tests structural invariants, not counts)
   - `v644-diagnostics-hardening.sh` → UPDATE with 6 path replacements (correct: all 6 occurrences confirmed in Phase 2 Q8)
   All 5 spot-checked classifications are correct.

5. **`/publish` pseudocode completeness:** Design.md Section 3.1 contains all required branching logic: detached HEAD stop, null issue_id flow, tracker_needed gate, 5-bucket error_type classification, three-mode fork (full-publish / pr-only-no-id / pr-only-404), FAIL path with EXIT non-zero, and the Step 3 common pre-publish checks. The pseudocode is copy-pasteable into skills/publish/SKILL.md with minor prose adaptation.

6. **Phase 8 verification commands:** Design.md Section 8 (8.1 through 8.7) covers all required invariants:
   - 8.1: Cross-file invariants (license SPDX, maintainer email, template parity) — correct
   - 8.2: Deprecated identifier sanity — DEFECT (finding f-d4e5f6): missing workflow-router exclusion
   - 8.3: Skill directory sanity + empty-dirs check — correct
   - 8.4: Doc count consistency — correct
   - 8.5: Pause Limits Used-By column — correct
   - 8.6: Frontmatter names — correct
   - 8.7: No-version-bump invariant — correct

---

## Summary of Findings

| ID | Severity | Criterion | Location |
|----|----------|-----------|----------|
| f-a1b2c3 | MAJOR | correctness | formal-criteria.md: AC-RENAME-STATUS-4/5, AC-RENAME-INIT-4, AC-DEL-CREATE-PR-2 vs AC-DOCS-COLLISION-WARN-3 |
| f-d4e5f6 | MAJOR | correctness | design.md Section 8.2 deprecated identifier sanity commands |
| f-g7h8i9 | MAJOR | correctness | requirements.md REQ-RENAME-STATUS/INIT/DEL-CREATE-PR EARS exclusion list |
| f-j1k2l3 | MINOR | correctness | formal-criteria.md AC-DOCS-COLLISION-WARN-1, AC-DOCS-COLLISION-WARN-2 |
| f-m4n5o6 | MINOR | correctness | formal-criteria.md AC-CHANGELOG-MIGRATION-7 exit-neutral assertion |
| f-p7q8r9 | MINOR | completeness | formal-criteria.md Summary AC count claim |
| f-s1t2u3 | MINOR | completeness | formal-criteria.md REQ-PUBLISH-AUTO-DETECT SC-7/SC-8 text format coverage |
| f-v4w5x6 | MINOR | robustness | design.md Section 3 detached HEAD exit semantics |

**Required fixes before Phase 7:**
- f-a1b2c3 + f-d4e5f6 + f-g7h8i9 (the workflow-router contradiction cluster): All three must be resolved together. The fix is the same in all locations: either add `--exclude=skills/workflow-router/SKILL.md` to AC-RENAME-STATUS-4, AC-RENAME-INIT-4, AC-DEL-CREATE-PR-2, and design.md Section 8.2 grep commands, and add workflow-router as an explicit exception in the three EARS texts; or mandate the OLD: marker approach in design.md Section 5.3 and document it in the ACs.

**Can be fixed alongside or deferred to Phase 7 guidance:**
- f-j1k2l3, f-m4n5o6, f-s1t2u3, f-v4w5x6: All are MINOR and could be fixed with small AC additions or clarifications.

---

DONE — verdict=FAIL, findings=8, severity_counts={MAJOR:3,MINOR:5}
